/*****************************************************************************************************
    * Class:   QTB_SubInvoiceLineCreationBatch
* Author: Virtusa
* Purpose: This is a Batch class to Create sub invoice line
* Requirement: Gitlab #30514
* Change History: 
* Developer     	Date           Description
* -------------------------------------------------------------------------------------------
*  Virtusa(Parth)   22/04/2025     created batch class to create sub invoice line and update tax override amount on invoice line 
								   and invoce if sum of tax overide amount of sub invoice line does not match with invoice line tax override amount
* Virtusa(Parth)    10/06/2025     #31399 for sub invoice lines unit price should be same as of usage
*******************************************************************************************************/
public class QTB_SubInvoiceLineCreationBatch implements Database.Batchable<sObject>,Database.Stateful {
    // Variable to get Class Name
    public static final string className = QTB_SubInvoiceLineCreationBatch.class.getName();
    // Boolean to control exception
    public static boolean throwExplicitException = false;
    // String variable to store invoiceLine Query
    public String query;
    // String variable to store draft status
    public static final String DRAFT_STATUS = 'Draft';
    // String variable to store Tax applicability
    public static final String PRODUCT_BASED_Applicability = 'Product Based';
    // String variable to store Price schedule category
    public static final String STORAGE_PRICE_SCHEDULE_CATEGORY = 'Storage';
    public static final String SERVICES_PRICE_SCHEDULE_CATEGORY = 'Services';
    // storing invoice Scheduler Id
    public Id invoiceSchedulerId;
    // storing rebill or adhoc order invoice id
    public Id rebillAdhocInvoiceId;
    // Storing bill flow controller 
    public Id billFlowControllerId;
    public boolean isSuccess = True;
    // Map to store inv Id and its related sub invoice line that need to be inserted
    public Map<Id,List<blng__SubInvoiceLine__c>>invSubLineMap = new Map<Id,List<blng__SubInvoiceLine__c>>();
    public integer leftOverRecords;
    
    /*********************************************************************************************************
Method Name: executeSubInvoiceLineCreationBatch
Parameters: List<flowInputs>
Return Type: void
Requirement: Gitlab #30514
Description: this method will execute the QTB_SubInvoiceLineCreationBatch batch class
**********************************************************************************************************/
    @InvocableMethod(Label='CallQTB_SubInvoiceLineCreationBatch' description='This method will execute QTB_SubInvoiceLineCreationBatch')
    public static void executeSubInvoiceLineCreationBatch(List<flowInputs> request) {
        Integer batchSize = Integer.ValueOf(System.Label.QTB_SubInvoiceLineCreationBatch_Size);
        Database.executeBatch(new QTB_SubInvoiceLineCreationBatch(request), batchSize);
    }
    
    /*********************************************************************************************************
Method Name: QTB_SubInvoiceLineCreationBatch
Parameters: List<FlowInputs> request
Return Type: void
Requirement: Gitlab #30514
Description: constructor of batch class
**********************************************************************************************************/
    public QTB_SubInvoiceLineCreationBatch(List<FlowInputs> request) {
        String errorIds = '';
        If(!request.isEmpty() && request[0].invoiceSchedulerId != null && request[0].billFlowControllerId != null){ 
            // for invoices that are created through invoice scheduler
            this.invoiceSchedulerId = request[0].invoiceSchedulerId;
            this.billFlowControllerId = request[0].billFlowControllerId;
            this.leftOverRecords = request[0].leftOverRecords;
            // updating sub invoice line status to In Progress
            QTB_Bill_Flow_Controller__c billFlowCtrl = new QTB_Bill_Flow_Controller__c(
                Id = billFlowControllerId,
                QTB_SubInvoiceLine_Creation_Status__c = 'In Progress');
            update billFlowCtrl;
            
            // This logic is only applicable where the flag on the  Legal Entity : ‘Storage/Service Period Range’ (QTB_Storage_Service_Period_Range__c) is enabled
            
            query = 'SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c = :invoiceSchedulerId AND '+ 
                'blng__InvoiceStatus__c = :DRAFT_STATUS AND QTB_hasTieredLines__c = True AND QTB_Sublines_Added__c = False ' +
                'AND blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__r.QTB_Storage_Service_Period_Range__c = True ';
        }
        else If(!request.isEmpty() && request[0].billFlowControllerId != null && request[0].rebillAdhocInvoiceId != null){
            // adhoc order invoice and rebill order invoices 
            this.rebillAdhocInvoiceId = request[0].rebillAdhocInvoiceId;
            this.billFlowControllerId = request[0].billFlowControllerId;
            this.leftOverRecords = request[0].leftOverRecords;
            // updating sub invoice line status to In Progress
            QTB_Bill_Flow_Controller__c billFlowCtrl = new QTB_Bill_Flow_Controller__c(
                Id = billFlowControllerId,
                QTB_SubInvoiceLine_Creation_Status__c = 'In Progress'
            );
            update billFlowCtrl;
            
            query = 'SELECT Id FROM blng__Invoice__c WHERE Id = :rebillAdhocInvoiceId  AND '+ 
                'blng__InvoiceStatus__c = :DRAFT_STATUS AND QTB_hasTieredLines__c = True AND QTB_Sublines_Added__c = False ' +
                'AND blng__Account__r.QTB_Legal_Entity__r.QTB_Storage_Service_Period_Range__c = True ';
        }
        
    }
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Description: Query invocie line records in context
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__Invoice__c>
Return Type: void
Requirement: Gitlab #30514
Description: creating Sub Invoice line based on usage grouping, updating tax overide amount on inv line and subLines added to ture on inv 
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoices) {
        String errorIds = '';
        try {
            System.debug('In execute method of QTB_ExchangeRateFieldsUpdate batch  try block');
            if (throwExplicitException) {
                System.debug('NullPointer');
                throw new NullPointerException();
            }
            // Map to store invoice line ID and usage summary Id 
            Map<Id, Id> usageSummaryToInvoiceLine = new Map<Id, Id>();
            // Map of invoice line - fetch  tiered Invoice line ( API name -QTB_Tiered_Flag__c), sub  invoice line should be manufactured based on the usages associated to the invoice line
            Map<Id, blng__InvoiceLine__c> invoiceLineMap = new Map<Id, blng__InvoiceLine__c>([SELECT Id,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__TaxCountry__c,currencyISOCode,blng__UsageSummary__c, blng__Invoice__c,blng__Invoice__r.QTB_Tax_Override_Amount__c, 
                                                                                              blng__Quantity__c, blng__UnitPrice__c,blng__Subtotal__c, blng__TaxAmount__c, QTB_Tax_Override_Amount__c, blng__TotalAmount__c 
                                                                                              FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN :invoices
                                                                                              AND blng__InvoiceLineStatus__c = :DRAFT_STATUS AND QTB_Tiered_Flag__c = TRUE]);
            //To store invoice id and sum of tiered invoice line subtotal
            Map<Id, decimal>tieredInvLineSubTotal = new Map<Id,decimal>();
            //To store invoice id and tax override amount
            Map<Id, decimal> invoiceTaxOverrideAmt = new Map<Id, decimal>();
            // To store the sum of sub-invoice line tax override amounts
            Map<Id, Decimal> invoiceLineSubLinesTaxOverrideAmount = new Map<Id, Decimal>();
            // To store the invocie Id and sum of its related sub-invoice line subtotal
            Map<Id, Decimal> subInvoiceLineSubtotal = new Map<Id, Decimal>();
            // store inv Id and count of inv line having tiered flag true 
            Map<Id,Integer>InvAndInvLineCount = new Map<Id,Integer>();
            // Mapping Invoice line relationships
            If(invoiceLineMap!= null && !invoiceLineMap.isEmpty()){
                for(blng__InvoiceLine__c invLine : invoiceLineMap.values()) {
                    if(invLine.blng__UsageSummary__c != null){
                        usageSummaryToInvoiceLine.put(invLine.blng__UsageSummary__c, invLine.Id);
                    }
                    if(InvAndInvLineCount != null && !InvAndInvLineCount.containsKey(invLine.blng__Invoice__c)){
                        InvAndInvLineCount.put(invLine.blng__Invoice__c,1);
                    }
                    else{
                        InvAndInvLineCount.put(invLine.blng__Invoice__c,InvAndInvLineCount.get(invLine.blng__Invoice__c)+1);
                    }
                    // storing invoice Id and its related invoice line sub total where tiered flag is true
                    If(!tieredInvLineSubTotal.containsKey(invLine.blng__Invoice__c)){
                        tieredInvLineSubTotal.put(invLine.blng__Invoice__c,invLine.blng__Subtotal__c);
                    }
                    else{
                        tieredInvLineSubTotal.put(invLine.blng__Invoice__c,tieredInvLineSubTotal.get(invLine.blng__Invoice__c)+ invLine.blng__Subtotal__c);
                    }
                    // adding invoice id and its tax override amount
                    // 30942 for flat rate countries not to update tax override amount on invoice line and invoice
                    If(invLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != null && invLine.blng__LegalEntity__r.QTB_Tax_Applicability__c.containsIgnoreCase('Product Based') && !invoiceTaxOverrideAmt.containsKey(invLine.blng__Invoice__c)){
                        invoiceTaxOverrideAmt.put(invLine.blng__Invoice__c,invLine.blng__Invoice__r.QTB_Tax_Override_Amount__c);
                    }
                }
                
                // this map will store invoice line Id and data to insert in sub invoice line based on price tier
                Map<Id, Map<String, TierData>> tierMap = new Map<Id, Map<String, TierData>>();
                // Group the usages by Qtb_Price_tier__c on the usages and create Sublines
                // #31399 added min(QTB_PreratedUnitPrice__c), as same price tiere will have same unit price and that unit price needs to be the unit price of sub invoice line
                // QTB_Prerated_Unit_Price__c, blng__PreratedAmount__c is currency field so it is not giving correct value in aggregate result, hence created formula field QTB_PreratedAmount__c and QTB_PreratedUnitPrice__c of data type number
                for(AggregateResult ar : [SELECT blng__UsageSummary__c, QTB_Price_Tier__c tier,SUM(blng__PreratedQuantity__c) totalQty,SUM(QTB_PreratedAmount__c) totalAmt,
                                          SUM(QTB_Box_Count__c)boxCount,min(QTB_PreratedUnitPrice__c)unitPrice,min(QTB_Start_Date_MRC__c)startDate, max(QTB_End_Date_MRC__c)endDate FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usageSummaryToInvoiceLine.keySet()
                                          GROUP BY blng__UsageSummary__c , QTB_Price_Tier__c ])
                {   
                    Id usgSmryId = (Id)ar.get('blng__UsageSummary__c');
                    Id invoiceLineId = usageSummaryToInvoiceLine.get(usgSmryId);
                    String priceTier = (String)ar.get('tier');
                    
                    // if invoice line not present adding to the map
                    if(tierMap != null && !tierMap.containsKey(invoiceLineId)) {
                        tierMap.put(invoiceLineId, new Map<String, TierData>());
                    }
                    // adding sub invoice line data that need to be inserted for an invoice line
                    tierMap.get(invoiceLineId).put(priceTier, new TierData(
                        (Decimal)ar.get('totalQty'),
                        (Decimal)ar.get('totalAmt'),
                        (Date)ar.get('startDate'),
                        (Date)ar.get('endDate'),
                        (Decimal)ar.get('boxCount'),
						(Decimal)ar.get('unitPrice')
                    ));
                }
                usageSummaryToInvoiceLine.clear();
                //Create sub invoice lines and calculate tax override amount sum
                if(tierMap != null && !tierMap.isEmpty()){
                    for(Id invoiceLineId : tierMap.keySet()) {
                        blng__InvoiceLine__c parentInvLine = invoiceLineMap.get(invoiceLineId);
                        
                        Decimal parentSubtotal = parentInvLine.blng__Subtotal__c != null ? parentInvLine.blng__Subtotal__c : 0 ;
                        Decimal taxRatio = parentSubtotal != 0 && parentInvLine.blng__TaxAmount__c != null ? parentInvLine.blng__TaxAmount__c / parentSubtotal : 0;
                        Decimal taxOverrideRatio = parentSubtotal != 0 && parentInvLine.QTB_Tax_Override_Amount__c != null ? parentInvLine.QTB_Tax_Override_Amount__c / parentSubtotal : 0;
                        
                        Decimal currentSubTotalTaxOverrideAmount = 0; // variable to store sum of tax override amount of sub invoice line on an invoice line
                        Decimal currentSubTotal = 0; // variable to store sum of subtotal of sub invoice line on an invoice line
						Decimal currentSubTotalSum = 0; // GITLAB - #34527 variable to store final sum of subtotal to fix round off issue.
                        for(String tier : tierMap.get(invoiceLineId).keySet()) {
                            TierData td = tierMap.get(invoiceLineId).get(tier);
                            //Decimal unitPrice = td.totalQty != 0 && td.totalAmt != null ? (td.totalAmt / td.totalQty).setScale(4, System.RoundingMode.HALF_UP) : 0;
                            Decimal subLineTaxOverrideAmount;
                            // 30942 for flat rate tax override amount will be same as of tax amount 
                            if(parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != null && parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c.containsIgnoreCase('Product Based')){
                                subLineTaxOverrideAmount = (td.totalAmt * taxOverrideRatio).setScale(2, System.RoundingMode.HALF_UP);
                            	currentSubTotalTaxOverrideAmount += subLineTaxOverrideAmount;
                            }else{
                                subLineTaxOverrideAmount = (td.totalAmt * taxRatio).setScale(2, System.RoundingMode.HALF_UP);
                            }
                            
                    
                             // currentSubTotal += (td.totalAmt).setScale(2, System.RoundingMode.HALF_UP);
                             currentSubTotal += (td.totalAmt);
                            currentSubTotalSum = currentSubTotal.setScale(2, RoundingMode.HALF_UP); //GITLAB - #34527
                            string NotesToAdd;
                            if(td.startDateMRC != null && td.endDateMRC != null){
                                // storing start date and end date mrc dates
                                // if day or month is less than 10 then adding 0 to it
                                String startday = td.startDateMRC.day() < 10 ? '0' + String.valueOf(td.startDateMRC.day()) : String.valueOf(td.startDateMRC.day());
                                String Startmonth = td.startDateMRC.month() < 10 ? '0' + String.valueOf(td.startDateMRC.month()) : String.valueOf(td.startDateMRC.month());
                                String Startyear = String.valueOf(td.startDateMRC.year());
                                String endday = td.endDateMRC.day() < 10 ? '0' + String.valueOf(td.endDateMRC.day()) : String.valueOf(td.endDateMRC.day());
                                String endmonth = td.endDateMRC.month() < 10 ? '0' + String.valueOf(td.endDateMRC.month()) : String.valueOf(td.endDateMRC.month());
                                String endyear = String.valueOf(td.endDateMRC.year());
                                // for India / Thailand notes should be in format → 15-03-2025 to 14-04-2025
                                If(parentInvLine.blng__TaxCountry__c.containsIgnoreCase('India') || parentInvLine.blng__TaxCountry__c.containsIgnoreCase('Thailand')){
                                    NotesToAdd = startday + '-' + Startmonth + '-' + Startyear + ' to ' + endday + '-' + endmonth + '-' + endyear;
                                }
                                // for Hungary notes should be in format → 2025.03.15 - 2025.04.14
                                else If(parentInvLine.blng__TaxCountry__c.containsIgnoreCase('Hungary')){
                                    NotesToAdd = startday + '.' + Startmonth + '.' + Startyear + ' - ' + endday + '.' + endmonth + '.' + endyear;
                                }
                                // for ANZ notes should be in format → 2025/03/15 - 2025/04/14
                                else if(parentInvLine.blng__TaxCountry__c.containsIgnoreCase('New Zealand') || parentInvLine.blng__TaxCountry__c.containsIgnoreCase('Australia')){
                                    NotesToAdd = startday + '/' + Startmonth + '/' + Startyear + ' - ' + endday + '/' + endmonth + '/' + endyear;
                                }
                                // Others (default) notes should be in format → 15-03-2025 - 14-04-2025
                                else{
                                    NotesToAdd = startday + '-' + Startmonth + '-' + Startyear + ' - ' + endday + '-' + endmonth + '-' + endyear;  
                                }
                            }
                            // adding sub invoice lines data
                            blng__SubInvoiceLine__c sublines = new blng__SubInvoiceLine__c(
                                blng__InvoiceLine__c = invoiceLineId,
                                blng__Quantity__c = td.totalQty,
                                blng__UnitPrice__c = (td.unitPrice).setScale(4, System.RoundingMode.HALF_UP),
                                blng__Subtotal__c = (td.totalAmt).setScale(2, System.RoundingMode.HALF_UP),
                                blng__TaxAmount__c = (td.totalAmt * taxRatio).setScale(2, System.RoundingMode.HALF_UP),
                                QTB_Tax_Override_Amount__c = subLineTaxOverrideAmount,
                                blng__Notes__c = NotesToAdd,
                                QTB_Box_Count__c = td.boxCount,
                                currencyISOCode = parentInvLine.currencyISOCode,
                                QTB_Price_Tier__c = tier // #31803 - assigning usage level price tier to sub lins which will help to identify usages related to sub invoice line
                            );
                            // adding invoice id and its related subinvoice line list to map
                            if(invSubLineMap != null && !invSubLineMap.containsKey(parentInvLine.blng__Invoice__c)){
                                invSubLineMap.put(parentInvLine.blng__Invoice__c, new List<blng__subInvoiceLine__c>());
                            }
                            invSubLineMap.get(parentInvLine.blng__Invoice__c).add(sublines);
                        }
                        // adding invoice line Id and sub invoice line tax override amount to compare if tax overide amount sum is same as of invoice line
                        // 30942 for flat rate countries not to update tax override amount on invoice line and invoice
                        If(parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != null && parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c.containsIgnoreCase('Product Based')){
                            invoiceLineSubLinesTaxOverrideAmount.put(invoiceLineId, currentSubTotalTaxOverrideAmount);
                        }
                        // adding invoice id and sum of sub invoice line subtotal to check if it is equal to sum of invoice line subtotal where tiered flag is true
                        // from this check will update subLines Added field to true on invoice
                        if(subInvoiceLineSubtotal != null && !subInvoiceLineSubtotal.containsKey(parentInvLine.blng__Invoice__c)){
                            subInvoiceLineSubtotal.put(parentInvLine.blng__Invoice__c,currentSubTotalSum); // GITLAB - #34527
                        }
                        else If(subInvoiceLineSubtotal != null){
                            subInvoiceLineSubtotal.put(parentInvLine.blng__Invoice__c,currentSubTotal + subInvoiceLineSubtotal.get(parentInvLine.blng__Invoice__c));
                        }
                    }
                }
                invoiceLineMap.clear();
                tierMap.clear();
                // in execute method we are inserting sublines and updating invoice line and invoice, total count should not exceed 10k
                List<blng__SubInvoiceLine__c> chunk = new List<blng__SubInvoiceLine__c>();
                integer executeDMLCount = 0;
                
                Set<Id>invoiceLineToCheckTaxAmount = New Set<Id>(); // this will store Id of invoice line on which sublines are created
                Set<Id>invoiceToCheck = new Set<Id>(); // this will store Id of invoice on which sublines are created
                // sublines that we have to insert + invoice line that will update + invoice that will update in a single execute should be <=10K
                Integer maxRecordsPerTransaction = 10000 - Integer.ValueOf(System.Label.QTB_SubInvoiceLineCreationBatch_Size);
                For(Id ids :invSubLineMap.keySet()){
                    if(invSubLineMap.get(Ids).size()+executeDMLCount+InvAndInvLineCount.get(Ids) <= maxRecordsPerTransaction){
                        executeDMLCount = executeDMLCount+invSubLineMap.get(Ids).size()+InvAndInvLineCount.get(Ids);
                        chunk.addAll(invSubLineMap.get(Ids));
                        invoiceToCheck.add(ids);
                        // adding invoce line id only when its related sub lines are created
                        for(blng__SubInvoiceLine__c subInvLn :invSubLineMap.get(ids)){
                            invoiceLineToCheckTaxAmount.add(subInvLn.blng__InvoiceLine__c);
                        }
                    }else{
                        break;
                    }
                }
                invSubLineMap.clear();
                InvAndInvLineCount.clear();
                if(chunk != null && !chunk.isEmpty()) {
                    insert chunk;
                }
                chunk.clear();
                // Update invoice lines if tax override amounts don't match checking only if its related sublines are inserted
                List<blng__InvoiceLine__c> invoiceLinesToUpdate = new List<blng__InvoiceLine__c>();
                for(Id invLineId : invoiceLineToCheckTaxAmount) {
                    blng__InvoiceLine__c parentInvLine = invoiceLineMap.containsKey(invLineId)?invoiceLineMap.get(invLineId):null;
                    if(parentInvLine != null && invoiceLineSubLinesTaxOverrideAmount.containsKey(invLineId) && parentInvLine.QTB_Tax_Override_Amount__c != invoiceLineSubLinesTaxOverrideAmount.get(invLineId)){
                        parentInvLine.QTB_Tax_Override_Amount__c = invoiceLineSubLinesTaxOverrideAmount.get(invLineId);
                        invoiceLinesToUpdate.add(parentInvLine);
                    }
                }
                invoiceLineToCheckTaxAmount.clear();
                invoiceLineSubLinesTaxOverrideAmount.clear();
                Map<Id,blng__Invoice__c>invoiceToUpdate = new Map<Id,blng__Invoice__c>();
                // update invoice header level tax override amount if invoice line tax override amount get updated
                if(!invoiceLinesToUpdate.isEmpty()){
                    update invoiceLinesToUpdate;
                    
                    // if tax override amount on invoice line gets updted then only updating tax override amount on invoice header
                    // 30942 for flat rate countries not to update tax override amount on invoice line and invoice
                    for(aggregateResult ar :[Select blng__Invoice__c,SUM(QTB_Tax_Override_Amount__c)invTaxOverrideAmt from blng__invoiceLine__c 
                                             where blng__Invoice__c in :invoiceToCheck AND blng__LegalEntity__r.QTB_Tax_Applicability__c = 'Product Based' group by blng__Invoice__c])
                    {
                        if(invoiceTaxOverrideAmt.containsKey((Id)ar.get('blng__Invoice__c')) && invoiceTaxOverrideAmt.get((Id)ar.get('blng__Invoice__c')) != (decimal)ar.get('invTaxOverrideAmt'))
                        {
                            blng__Invoice__c inv = new blng__invoice__c(Id =(Id)ar.get('blng__Invoice__c'), QTB_Tax_Override_Amount__c = (decimal)ar.get('invTaxOverrideAmt') );
                            if(invoiceToUpdate != null && !invoiceToUpdate.containsKey(inv.Id)){
                                invoiceToUpdate.put(inv.Id,inv);
                            }
                            else if(invoiceToUpdate != null){
                                invoiceToUpdate.get(inv.Id).put('QTB_Tax_Override_Amount__c', inv.QTB_Tax_Override_Amount__c);
                            }
                        }						
                    }
                    invoiceTaxOverrideAmt.clear();
                }
                invoiceLinesToUpdate.clear();
                
                // update QTB_Sublines_Added__c to true at invoice header if sum of subtotal of tier invoice line equal to sum of subline subtotal
             for(Id invId :invoiceToCheck)
                {
                    // GITLAB #34527 -> below logic added to calculate decimal dfifference and pass it if difference is less than 1
					 Decimal difference = (tieredInvLineSubTotal.get(invId).setScale(2, RoundingMode.HALF_UP) - subInvoiceLineSubtotal.get(invId).setScale(2, RoundingMode.HALF_UP)).abs();
					 if(subInvoiceLineSubtotal != null && subInvoiceLineSubtotal.containsKey(invId) && tieredInvLineSubTotal.containsKey(invId) &&
                       difference < 1) //Gitlab-#34527 
                    {
                        blng__Invoice__c inv = new blng__invoice__c(Id =invId, QTB_Sublines_Added__c = true );
                        if(invoiceToUpdate != null && !invoiceToUpdate.containsKey(invId)){
                            invoiceToUpdate.put(invId,inv);
                        }
                        else if(invoiceToUpdate != null){
                            invoiceToUpdate.get(invId).put('QTB_Sublines_Added__c', inv.QTB_Tax_Override_Amount__c);
                        }
                    }						
                }
                update invoiceToUpdate.values();
                invoiceToCheck.clear();
                invoiceToUpdate.clear();
                subInvoiceLineSubtotal.clear();
                tieredInvLineSubTotal.clear();
            }
            
        }
        catch(exception e){
            System.debug('In execute  catch block of QTB_SubInvoiceLineCreationBatch --->'+ e.getLineNumber());
            isSuccess = false;
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000) errorIds = errorIds.substring(0, 100000);
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),errorIds,e.getTypeName(),className);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        String errorIds = '';
        try{
            if (throwExplicitException) {
                System.debug('NullPointer');
                throw new NullPointerException();
            }
            // Get batch job status
            AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :BC.getJobId()];
            // If any batch chunk failed OR DML limit was exceeded
            if (!isSuccess || job.Status == 'Failed' || job.Status == 'Aborted' || job.NumberOfErrors > 0) {
                QTB_Bill_Flow_Controller__c billFlowCtrl = new QTB_Bill_Flow_Controller__c(Id = billFlowControllerId, QTB_SubInvoiceLine_Creation_Status__c = 'Error');
                update billFlowCtrl;
            }
            // If any sub line creation is pending due 10k records limition of per transaction 
            else{
                string updateStatus;
                List<blng__Invoice__c>invLst = new List<blng__Invoice__c>();
                If(invoiceSchedulerId != null ){// for invoices that are created through invoice scheduler
                    invLst = [SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c = :invoiceSchedulerId AND  
                              blng__InvoiceStatus__c = :DRAFT_STATUS AND QTB_hasTieredLines__c = True AND QTB_Sublines_Added__c = False AND blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__r.QTB_Tax_Applicability__c = :PRODUCT_BASED_Applicability
                              AND blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__r.QTB_Storage_Service_Period_Range__c = True ];
                }
                else If(rebillAdhocInvoiceId != null){ // adhoc order invoice and rebill order invoices 
                    invLst = [SELECT Id FROM blng__Invoice__c WHERE Id = :rebillAdhocInvoiceId  AND 
                              blng__InvoiceStatus__c = :DRAFT_STATUS AND QTB_hasTieredLines__c = True AND QTB_Sublines_Added__c = False AND blng__Account__r.QTB_Legal_Entity__r.QTB_Tax_Applicability__c = :PRODUCT_BASED_Applicability
                              AND blng__Account__r.QTB_Legal_Entity__r.QTB_Storage_Service_Period_Range__c = True ]; 
                }
                if(invlst.size() == 0){
                    updateStatus = 'Completed';
                }
                else if(leftOverRecords == null && invLst.size() != 0){// after first time any records left
                    callBatchAgain(this.invoiceSchedulerId,this.billFlowControllerId,this.rebillAdhocInvoiceId,invLst.size());
                }
                else If(leftOverRecords != null && leftOverRecords != invLst.size()){// second time onwards
                    callBatchAgain(this.invoiceSchedulerId,this.billFlowControllerId,this.rebillAdhocInvoiceId,invLst.size());
                }
                else If(leftOverRecords != null && leftOverRecords == invLst.size()){
                    updateStatus = 'Error';
                }
                
                If(updateStatus == 'Completed'){
                    QTB_Bill_Flow_Controller__c billFlowCtrl = new QTB_Bill_Flow_Controller__c(
                        Id = billFlowControllerId, 
                        QTB_SubInvoiceLine_Creation_Status__c = 'Completed'
                    );
                    update billFlowCtrl;
                }
                else If(updateStatus == 'Error'){
                    QTB_Bill_Flow_Controller__c billFlowCtrl = new QTB_Bill_Flow_Controller__c(
                        Id = billFlowControllerId, 
                        QTB_SubInvoiceLine_Creation_Status__c = 'Error'
                    );
                    update billFlowCtrl;
                }
            }
        }
        catch(exception e){
            QTB_Bill_Flow_Controller__c billFlowCtrl = new QTB_Bill_Flow_Controller__c(
                Id = billFlowControllerId, 
                QTB_SubInvoiceLine_Creation_Status__c = 'Error'
            );
            update billFlowCtrl;
            System.debug('In catch method of QTB_SubInvoiceLineCreationBatch Finish '+ e.getLineNumber());
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            System.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),errorIds,e.getTypeName(),className);
        }
        
    }
    
    public class TierData {
        public Decimal totalQty;
        public Decimal totalAmt;
        public Date startDateMRC;
        public Date endDateMRC;
        public Decimal boxCount;
		public Decimal unitPrice;
        
        public TierData(Decimal qty, Decimal amt, Date startDate, Date endDate, Decimal boxCnt, Decimal unitPrc) {
            totalQty = qty;
            totalAmt = amt;
            startDateMRC = startDate;
            endDateMRC = endDate;
            boxCount = boxCnt;
			unitPrice = unitPrc;
        }
    }
    public class FlowInputs 
    {
        @InvocableVariable public Id invoiceSchedulerId;
        @InvocableVariable public Id billFlowControllerId;
        @invocableVariable public Id rebillAdhocInvoiceId;
        @invocableVariable public Integer leftOverRecords;
    }
    /*********************************************************************************************************
Method Name: callBatchAgain
Parameters: Id schedulerId, Id billFlowId, Id rebillId, Integer leftRecords
Return Type: void
Requirement: Gitlab #30514
Description: calling batch class again if any records are left to insert or update 
**********************************************************************************************************/
    public Static void callBatchAgain(Id schedulerId, Id billFlowId, Id rebillId, Integer leftRecords){
        list<flowInputs> flowInputsLst = new list<flowInputs>();
        flowInputs flw = new flowInputs();
        flw.invoiceSchedulerId = schedulerId;
        flw.billFlowControllerId = billFlowId;
        flw.rebillAdhocInvoiceId = rebillId;
        flw.leftOverRecords = leftRecords;
        flowInputsLst.add(flw);                
        executeSubInvoiceLineCreationBatch(flowInputsLst); // this method is executing the batch class
    }
}