/*****************************************************************************************************
* Class: QTB_Ready_for_Integration_Batch
* Author: Lokesh Tewari / Pragathi B V
* Purpose: This is a Batch class containing logic for the invoice lines which are in draft even after Invoices are posted
* Requirement: To iterate on the draft invoice lines which is called after 5mins from the scheduler 
* Change History: 05/05/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari / Pragathi B V      05/05/2024     Creation of new Batch class for posting the draft invoice lines
*******************************************************************************************************/

global class QTB_Ready_for_Integration_Batch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful {
    
    // Variable to get the class name
    private static final String CLASSNAME = QTB_Ready_for_Integration_Batch.class.getName();
    // variable to store Draft recordtype id
    Public static final Id draftInvRecTypeId = QTB_Utils.INVOICE_DRAFT_RECTYPEID;
    // variable to store Draft recordtype id
    Public static final Id PostedInvRecTypeId = QTB_Utils.INVOICE_POSTED_RECTYPEID;
    // Variable to throw exception for catch block
    public static boolean throwExplicitException = false;
    // List of invoice Ids which are passed from QTB_InvoiceBatch class
    public Set<Id> invIdSet = new Set<Id>();//changing the variable from invIdList to invIdSet as part of Epic:2999
    public Set<id> taxDetailIDSet = new Set<id>(); //Epic 2999 Hypercare2
    //Construction for the batch QTB_Ready_for_Integration_Batch
    global QTB_Ready_for_Integration_Batch(Set<Id> processedInvoiceIds){
        try{
            if( QTB_Ready_for_Integration_Batch.throwExplicitException){
                throw new NullPointerException();
            }
            //Check if the Invoices received has values or not
            if(!processedInvoiceIds.isEmpty()){
                invIdSet.addAll(processedInvoiceIds); //Epic:2999
            }           
        }
        catch(Exception e){
            e.getMessage();
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog
                (e.getLineNumber(),
                 e.getStackTraceString(),
                 e.getMessage(),
                 e.getTypeName(),
                 CLASSNAME);
        }
    }
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
**********************************************************************************************************/
    global List<blng__Invoice__c> start(Database.BatchableContext BC){
        //Querying for all the Invoice that are Posted in QTB_InvoiceBatch
        List<blng__Invoice__c> lstInvc = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,blng__TaxAmount__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,
                                          blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,
                                          blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                                          recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,QTB_Invoice_Posted_Error__c,QTB_Ready_for_Integration__c,QTB_Ready_for_Integration_Status__c FROM blng__Invoice__c where id in: invIdSet];//Epic:2999
        
        return lstInvc;
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__Invoice__c>
Return Type: void
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<blng__Invoice__c> scope){
        string errorIds = '';
        try{
            // Map to store Custom Invoice Number and Invoice Id for Duplicate check
            Map<string,id> mapCustmInvcNoInvcId = new Map<string,id>();
            // Set to store invoice ids
            Set<id> invcIds =  new Set<id>();
            // Set to store Invoice id whose invoice lines are in Draft status
            set<id> setInvoiceId = new set<id>();
            // Map to store Invoice Line as  key and Invoice id as a value for Product based 
            map<id,id> mapInvcLineIdAndInvcId = new map<id,id>();
            // Map to store invoice id and Tax Override amount for Flat Rate
            Map<id,Decimal> mapInvcTaxOverAmtForFlat = new Map<id,Decimal>();
            // Map to store invoice id and Tax Override amount for Product
            Map<id,Decimal> mapInvIdTaxOverAmtForProduct = new Map<id,Decimal>();
            // Set to store invoice id for Flat Rate
            Set<Id> setInvoiceIdForFlatRate = new set<id>();
            // List to store invoice for draft update
            List<blng__Invoice__c> invoiceUpdateToDraft = new List<blng__Invoice__c>();
            // List of Tax Detail record that need to be deleted for Draft lines 
            List<QTB_Tax_Detail__c> lstTaxDetailDelete = new List<QTB_Tax_Detail__c>();
            // List to invoice id for duplicate custom invoice number
            set<id> duplicatecustInvcId = new Set<Id>();
            // List to update Custom setting for Custom invoice number
            List<QTB_CustomInvoiceNumber__c> lstCustmStngCustmInvcNo = new List<QTB_CustomInvoiceNumber__c>();
            // List to update Invoice having duplicate custom invoice number
            List<blng__Invoice__c> lstUpdatedInvcList = new List<blng__Invoice__c>();
            // 24438 List of invoice after Custom invoice generation
            List<blng__Invoice__c> invoicesToUpdate = new List<blng__Invoice__c>();
            // 24438 Set To store custome setting for Custom Invoice Number
            List<QTB_CustomInvoiceNumber__c> customSettingsToUpdate= new List<QTB_CustomInvoiceNumber__c>();
            // Set to store country 
            Set<String> setCountry = new Set<string>();
            // 24438 Set To store custome setting for Custom Invoice Number
            Set<QTB_CustomInvoiceNumber__c> customSettToUpdate=new Set<QTB_CustomInvoiceNumber__c>();
            // Map to store invoice Id and List of Invc Lines
            map<id,map<id,blng__InvoiceLine__c>> mapInvcIdAndInvcLineWithId = new map<id,map<id,blng__InvoiceLine__c>>();
            // Map to temporary store invoice Id and List of Invc Lines
            map<id,blng__InvoiceLine__c> mapInvcLineWithId ;     
            // Map to store invoice id and set of address comparison of invoice line
            map<id,Set<String>> mapInvcAndAddressCom = new map<id,Set<String>>();
            // Map to store invoice id and List of Tax Details
            map<id,List<QTB_Tax_Detail__c>> mapInvcAndListTaxDetails = new map<id,List<QTB_Tax_Detail__c>>();
            // Set to store address comparison
            set<string> addressCompare;
            // List to delete Tax Details
            List<QTB_Tax_Detail__c> lstTaxDetailToBeDeteled;
            // Set to store address comparison
            set<string> addressComparison = new set<string>();
            // Map to store invoice id and Invoice Line id
            map<id,blng__InvoiceLine__c> mapInvcLineIdInvcLine = new map<id,blng__InvoiceLine__c>();
            if( QTB_Ready_for_Integration_Batch.throwExplicitException){
                throw new NullPointerException();
            }
            // Map to store Custom Invoice Number and Invoice Id for Duplicate check
            for(blng__Invoice__c invc :scope){
                errorIds +=';;'+invc.id;
                
                if(String.isBlank(invc.QTB_Custom_Invoice_Number__c)){
                    duplicatecustInvcId.add(invc.Id); 
                }else{
                    if(!mapCustmInvcNoInvcId.containsKey(invc.QTB_Custom_Invoice_Number__c)){
                        mapCustmInvcNoInvcId.put(invc.QTB_Custom_Invoice_Number__c,invc.id); 
                    }else{
                        duplicatecustInvcId.add(invc.Id); 
                    }
                }
                setCountry.add(invc.blng__Account__r.QTB_Legal_Entity_Country__c);
                invcIds.add(invc.id);
                
            }
            if(!mapCustmInvcNoInvcId.isEmpty() && !invcIds.isEmpty()){
                // Query all invoice lines FROM the scope
                for(blng__InvoiceLine__c invcLine :[SELECT Id,QTB_Tiered_Flag__c,blng__TaxAmount__c,blng__TaxTreatment__c,blng__InvoiceLineStatus__c,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.Id,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                    blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Invoice__r.QTB_Transferred_to_Invoice_Compliance__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                    blng__Invoice__r.blng__NumberOfInvoiceLines__c,LastModifiedDate,blng__Invoice__r.QTB_Custom_Invoice_Number__c,blng__Invoice__r.QTB_Ready_for_Integration__c,blng__Invoice__r.QTB_Ready_for_Integration_Status__c,
                                                    blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TotalAmount__c,
                                                    blng__Invoice__r.blng__Account__r.QTB_Customer_Number__c,blng__Invoice__r.blng__TaxAmount__c,blng__Invoice__r.QTB_Invoice_Type__c,blng__Invoice__r.QTB_Tax_Override_Amount__c,
                                                    blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,QTB_Tax_Code__c,blng__LegalEntity__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c
                                                    from blng__InvoiceLine__c where blng__Invoice__c in :invcIds and (blng__Invoice__r.blng__InvoiceStatus__c = 'Posted' or blng__Invoice__r.blng__InvoiceStatus__c = 'Error')]){
                                                        
                                                        system.debug('invcLine.QTB_Tiered_Flag__c->'+invcLine.QTB_Tiered_Flag__c);
                                                        // Create set of Address comparison for fetching Tax Rate record based on address Comparison field on Tax Ratecompare address with Tax Rate addressComparison field
                                                        // Commented line 153-155 as part of story 24038 to create address comparison to fetch the tax rate record 
                                                        String invoiceLineComparison =
                                                            invcLine.blng__TaxCountry__c +'----' +
                                                           // invcLine.blng__TaxState__c +'-' +
                                                            //invcLine.blng__TaxCity__c +'-' +
                                                            //invcLine.blng__TaxZipCode__c +'-' +
                                                    invcLine.QTB_Tax_Code__c +'-' +
                                                    invcLine.blng__LegalEntity__c;
                    invoiceLineComparison = invoiceLineComparison.replaceAll('null',''); 
                    
                    // Logic for address comparis
                                                        addressCompare = new set<string>();
                    addressCompare.add(invoiceLineComparison);
                    if(mapInvcAndAddressCom.containsKey(invcLine.blng__Invoice__c)){
                        addressCompare.addAll(mapInvcAndAddressCom.get(invcLine.blng__Invoice__c));
                    }
                    mapInvcAndAddressCom.put(invcLine.blng__Invoice__c,addressCompare);
                
                                                        mapInvcLineWithId = new map<id,blng__InvoiceLine__c>();
                                                        mapInvcLineWithId.put(invcLine.id,invcLine);
                                                        if(mapInvcIdAndInvcLineWithId.containsKey(invcLine.blng__Invoice__c)){
                                                            mapInvcLineWithId.PutAll(mapInvcIdAndInvcLineWithId.get(invcLine.blng__Invoice__c));
                                                        }
                                                        mapInvcIdAndInvcLineWithId.put(invcLine.blng__Invoice__c,mapInvcLineWithId);   
                                                        
                                                        // Condition to check wether Draft Lines present for an invoice
                                                        if(invcLine.blng__InvoiceLineStatus__c == 'Draft' || invcLine.blng__Invoice__r.blng__InvoiceStatus__c == 'Error'){
                                                            if(!setInvoiceId.contains(invcLine.blng__Invoice__c)){
                                                                setInvoiceId.Add(invcLine.blng__Invoice__c);
                                                            }
                                                        }
                                                        
                                                        // Flat Rate and Product based out of Draft condition as some of the lines may be Posted
                                                        //Condition to check account Tax Applicability is Flat Rate 
                                                        //Exclude Hong Kong country as it doesn't have Tax detail 
                                                        if(invcLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong'){
                                                            if(invcLine.blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT && !setInvoiceIdForFlatRate.contains(invcLine.blng__Invoice__c)){
                                                                // Store invoice Ids
                                                                setInvoiceIdForFlatRate.Add(invcLine.blng__Invoice__c);
                                                            }
                                                            //Condition to check account Tax Applicability is Product Based Rate 
                                                            else if(invcLine.blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED ){
                                                                mapInvcLineIdAndInvcId.put(invcLine.Id,invcLine.blng__Invoice__c);
                                                            }
                                                        }
                                                    }
                
                if(!setInvoiceIdForFlatRate.isEmpty() || !mapInvcLineIdAndInvcId.isEmpty() || Test.isRunningTest()){
                    //Fetching all the Tax details related to the invoice and invoice lines for the comparison
                    List<QTB_Tax_Detail__c> lstTaxDetail = [select id,Name, QTB_Invoice__c,QTB_Tax_Override_Amount__c,QTB_Invoice__r.blng__Account__r.QTB_Special_Tax_Condition__c, QTB_Invoice_Line__c 
                                                            from QTB_Tax_Detail__c 
                                                            where QTB_Invoice__c IN: setInvoiceIdForFlatRate OR QTB_Invoice_Line__c IN: mapInvcLineIdAndInvcId.keyset()];
                    if(!lstTaxDetail.isEmpty()){
                        for(QTB_Tax_Detail__c taxDetail : lstTaxDetail){                            
                            Decimal taxAmt = 0;
                            // List of Tax Detail linked with Draft Invoice/Invoice lines
                            // Create map containing Invoice as a Key and List of Tax Details record
                            lstTaxDetailToBeDeteled = new List<QTB_Tax_Detail__c>();
                            //Epic2999 Hypercare2
                            if(!taxDetailIDSet.contains(taxDetail.id))
                            {
                                System.debug('???taxdetailiset');
                                lstTaxDetailToBeDeteled.add(taxDetail);
                                taxDetailIDSet.add(taxDetail.id);
                            }
                            //Epic2999 Hypercare2 Ending                           
                            if(mapInvcAndListTaxDetails.containsKey(taxDetail.QTB_Invoice__c)){
                                lstTaxDetailToBeDeteled.addAll(mapInvcAndListTaxDetails.get(taxDetail.QTB_Invoice__c));
                                mapInvcAndListTaxDetails.put(taxDetail.QTB_Invoice__c,lstTaxDetailToBeDeteled);
                            }
                            else if(mapInvcAndListTaxDetails.containsKey(mapInvcLineIdAndInvcId.get(taxDetail.QTB_Invoice_Line__c))){
                                lstTaxDetailToBeDeteled.addAll(mapInvcAndListTaxDetails.get(mapInvcLineIdAndInvcId.get(taxDetail.QTB_Invoice_Line__c)));
                                mapInvcAndListTaxDetails.put(mapInvcLineIdAndInvcId.get(taxDetail.QTB_Invoice_Line__c),lstTaxDetailToBeDeteled);
                            }
                            else if(!mapInvcAndListTaxDetails.containsKey(taxDetail.QTB_Invoice__c) && setInvoiceIdForFlatRate.contains(taxDetail.QTB_Invoice__c) && taxDetail.QTB_Invoice_Line__c == Null){
                                mapInvcAndListTaxDetails.put(taxDetail.QTB_Invoice__c,lstTaxDetailToBeDeteled);
                            }
                            else{
                                mapInvcAndListTaxDetails.put(mapInvcLineIdAndInvcId.get(taxDetail.QTB_Invoice_Line__c),lstTaxDetailToBeDeteled);
                            }
                            
                            //Checking for Flat Rate Invoice Ids with Tax details -> Tax Override Amount match
                            if((setInvoiceIdForFlatRate.contains(taxDetail.QTB_Invoice__c) && taxDetail.QTB_Invoice_Line__c == Null)){
                                 //Epic 2999 hypercare2                                                                 
                                   taxAmt = taxDetail.QTB_Tax_Override_Amount__c == null ? 0 :taxDetail.QTB_Tax_Override_Amount__c;
                                   System.debug('>>flatrate'+ taxDetail.QTB_Tax_Override_Amount__c);                          
                                
                                if(mapInvcTaxOverAmtForFlat.ContainsKey(taxDetail.QTB_Invoice__c) && mapInvcTaxOverAmtForFlat.get(taxDetail.QTB_Invoice__c) != null){
                                    System.debug('>>flatratetaxcalculation');
                                    taxAmt = taxAmt + mapInvcTaxOverAmtForFlat.get(taxDetail.QTB_Invoice__c);
                                }
                                //closing Epic 2999hypercare2
                                mapInvcTaxOverAmtForFlat.put(taxDetail.QTB_Invoice__c,taxAmt);
                            }
                            //Else for Product based check from Invoice Lines
                            else{
                                if(mapInvcLineIdAndInvcId.ContainsKey(taxDetail.QTB_Invoice_Line__c)){
                                    Id invoiceId = mapInvcLineIdAndInvcId.get(taxDetail.QTB_Invoice_Line__c);  
                                    //Epic 2999 hypercare2                                                                                                        
                                    taxAmt = taxDetail.QTB_Tax_Override_Amount__c == null ? 0 :taxDetail.QTB_Tax_Override_Amount__c;
                                    System.debug('>>productbased' + taxDetail.QTB_Tax_Override_Amount__c);
                                    
                                    if(mapInvIdTaxOverAmtForProduct.containsKey(invoiceId) && mapInvIdTaxOverAmtForProduct.get(invoiceId) != null){
                                        System.debug('>>productbased tax rate');
                                        taxAmt = taxAmt + mapInvIdTaxOverAmtForProduct.get(invoiceId);
                                    }
                                    //Epic 2999 hypercare2
                                    mapInvIdTaxOverAmtForProduct.put(invoiceId,taxAmt);
                                }
                            }
                        }
                    }
                    // If Invoice/ Invoice Lines doesn't have Tax Deatil then store the invoice id in Invoice Reposting set
                    for(blng__Invoice__c invc :scope){
                        Set<string> addressCompre = new Set<String>();                             
                        // Check for the tax amount mismatch
                        if((!mapInvcTaxOverAmtForFlat.containsKey(invc.id) && !mapInvIdTaxOverAmtForProduct.containsKey(invc.id)) || (mapInvcTaxOverAmtForFlat.ContainsKey(invc.Id) && mapInvcTaxOverAmtForFlat.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) || (mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) && mapInvIdTaxOverAmtForProduct.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) || (invc.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong' && invc.QTB_Tax_Override_Amount__c != invc.blng__TaxAmount__c) || setInvoiceId.contains(invc.Id))
                        {
                            if(mapInvcAndListTaxDetails.containsKey(invc.id) && invc.blng__Account__r.QTB_Legal_Entity_Country__c != 'United States' && invc.blng__Account__r.QTB_Legal_Entity_Country__c != 'Canada'){
                                List<QTB_Tax_Detail__c> lstTaxDet = mapInvcAndListTaxDetails.get(invc.id);
                                SYSTEM.DEBUG('249>>>'+lstTaxDet.SIZE());
                                //Epic2999 Hypercare2 
                                if(lstTaxDet != null)
                                {
                                    lstTaxDetailDelete.addAll(lstTaxDet); 
                                }
                               //Epic2999 Hypercare2 Ending                             
                            }
                            setInvoiceId.add(invc.id);
                            if(mapInvcAndAddressCom.containsKey(invc.id)){
                                addressCompre = mapInvcAndAddressCom.get(invc.id);
                                addressComparison.addAll(addressCompre);
                            }
                            if( mapInvcIdAndInvcLineWithId.containsKey(invc.Id)){
                                mapInvcLineIdInvcLine = mapInvcIdAndInvcLineWithId.get(invc.Id);  
                            }
                        }
                        
                    }
                    if(!mapInvcLineIdInvcLine.isEmpty() && !addressComparison.isEmpty()){
                        //#29101 starts as we changed the retrun type of updateInvcAndInvocLineWithTaxOverride
                        List<SObject> recordsToUpdateList =  QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride(mapInvcLineIdInvcLine,addressComparison);
                        
                        // Separate lists for Invoice and Invoice Line
                        List<blng__Invoice__c> invoicesToUpdatedList = new List<blng__Invoice__c>();
                        List<blng__InvoiceLine__c> invoiceLinesToUpdateList = new List<blng__InvoiceLine__c>();
                        if(recordsToUpdateList!=null && !recordsToUpdateList.isEmpty()){
                            // Segregate the records from the List<SObject>
                            for (SObject record : recordsToUpdateList) {
                                if (record instanceof blng__Invoice__c) {
                                    invoicesToUpdatedList.add((blng__Invoice__c) record);  // Cast to Invoice
                                } else if (record instanceof blng__InvoiceLine__c) {
                                    invoiceLinesToUpdateList.add((blng__InvoiceLine__c) record);  // Cast to Invoice Line
                                }
                            }
                        }
                        // Now you have two separate lists: invoicesToUpdatedList and invoiceLinesToUpdateList
                        if (!invoicesToUpdatedList.isEmpty()) {
                            update invoicesToUpdatedList; // updating invoices:
                        }
                        if (!invoiceLinesToUpdateList.isEmpty()) {
                            update invoiceLinesToUpdateList; // updating invoice lines:
                        }
                        // 29101 ends
                    }
                    // Delete Draft Lines related Tax Detail record
                    if(!lstTaxDetailDelete.isEmpty()){
                        Delete lstTaxDetailDelete;
                        lstTaxDetailDelete.clear();
                        lstTaxDetail.clear();
                        mapInvcLineIdAndInvcId.clear();
                    }
                }
            }
            if(!setInvoiceId.isEmpty() || Test.isRunningTest()){
                //Update those Invoice status to Draft which has no Tax Details and Invoice Lines are in Draft, 
                for(Id invoiceId : setInvoiceId){
                    blng__invoice__c invoice = new blng__invoice__c();
                    invoice.id = invoiceId;
                    invoice.blng__InvoiceStatus__c = QTB_Constants.INVOICE_STATUS_DRAFT;
                    invoice.blng__InvoicePostedDate__c = null;
                    invoice.RecordTypeId = draftInvRecTypeId;
                    invoice.QTB_Transferred_to_Invoice_Compliance__c = System.today();
                    invoiceUpdateToDraft.add(invoice);
                }
                
                if(!invoiceUpdateToDraft.isEmpty()){
                    SBQQ.TriggerControl.disable();
                    update invoiceUpdateToDraft ;
                    SBQQ.TriggerControl.enable();
                }
                
                //Updating Drafted invoices back to Posted
                if(!invoiceUpdateToDraft.isEmpty()){
                    for(blng__Invoice__c inv : invoiceUpdateToDraft){
                        inv.blng__InvoiceStatus__c = QTB_Constants.INVOICE_STATUS_POSTED;
                        inv.RecordTypeId = PostedInvRecTypeId;
                        inv.blng__InvoicePostedDate__c = System.today();
                        inv.QTB_Transferred_to_Invoice_Compliance__c = null;
                    }
                    update invoiceUpdateToDraft ;
                    invoiceUpdateToDraft.clear();
                }
            }
            // Check and Add invoice id having duplicate custom invoice number in existing Invoice
            for(blng__invoice__c invc : [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c 
                                         from blng__invoice__c where blng__InvoiceStatus__c = 'Posted' and QTB_Custom_Invoice_Number__c in:mapCustmInvcNoInvcId.KeySet() and id not in :mapCustmInvcNoInvcId.values() and blng__Account__r.QTB_Legal_Entity_Country__c in :setCountry]){
                if(mapCustmInvcNoInvcId.containsKey(invc.QTB_Custom_Invoice_Number__c) && !String.isBlank(invc.QTB_Custom_Invoice_Number__c) ){ // Gitlab #26906 added null and empty check for QTB_Custom_Invoice_Number__c 
                    duplicatecustInvcId.add(mapCustmInvcNoInvcId.get(invc.QTB_Custom_Invoice_Number__c));
                }
            }
            // Check and Add invoice id having duplicate custom invoice number in existing Credit Note
            
            for(blng__CreditNote__c cn : [select id,QTB_Custom_Invoice_Number__c,blng__Status__c from blng__CreditNote__c 
                                          where QTB_Custom_Invoice_Number__c IN :mapCustmInvcNoInvcId.KeySet() and blng__Status__c = 'Posted' and blng__Account__r.QTB_Legal_Entity_Country__c in:setCountry]){
                if(mapCustmInvcNoInvcId.containsKey(cn.QTB_Custom_Invoice_Number__c) && !duplicatecustInvcId.contains(mapCustmInvcNoInvcId.get(cn.QTB_Custom_Invoice_Number__c))  && !String.isBlank(cn.QTB_Custom_Invoice_Number__c)){ // Gitlab #26906 added null and empty check for QTB_Custom_Invoice_Number__c 
                    duplicatecustInvcId.add(mapCustmInvcNoInvcId.get(cn.QTB_Custom_Invoice_Number__c));
                }
            }
            //Fetch the invoice record with required fields to assing new custom invoice number
            if(!duplicatecustInvcId.isEmpty())
            {
                for(blng__Invoice__c invc:[select id,name,blng__Account__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__c,QTB_Invoice_Type__c,
                                           blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,blng__Account__r.QTB_Market__r.QTB_State__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c from blng__Invoice__c where id In :duplicatecustInvcId]){ 
                    lstUpdatedInvcList.add(invc);
                }
                if(!lstUpdatedInvcList.isEmpty()){
                    // Calling QTB_Regenerate_Custom_Invc_No class to assign new custom invoice number to duplicate ones
                    //#30236 Added Null Parameter as there will be no duplicate for Legacy Invocies as the Legacy Custom Inv Number will get stamped from Source Inv Reference from Usage (Which will be given by user)
                    Map<List<blng__Invoice__c>, List<QTB_CustomInvoiceNumber__c>> mapInvcCstmSetngForCustmInvcNo = QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(lstUpdatedInvcList,null);
                    if(!mapInvcCstmSetngForCustmInvcNo.isEmpty()){
                        // Add Invoice records to update lists without nested loops
                        for (List<blng__Invoice__c> invoiceList : mapInvcCstmSetngForCustmInvcNo.keySet()) {
                            invoicesToUpdate.addAll(invoiceList);  // Add all invoices in the list
                        }
                        for (List<QTB_CustomInvoiceNumber__c> customSettingList : mapInvcCstmSetngForCustmInvcNo.values()) {
                            customSettingsToUpdate.addAll(customSettingList);  // Add all custom settings in the list
                        }
                    } 
                }
            }
            // Update invoices having duplicate custom invoice number
            if(!invoicesToUpdate.isEmpty() && !customSettingsToUpdate.isEmpty()){
                update invoicesToUpdate;
                update customSettingsToUpdate;
                invoicesToUpdate.clear();
                customSettingsToUpdate.clear();
            }
            
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            System.debug('Exception message:'+e.getMessage());
            System.debug('Exception message:'+e.getLineNumber());
            errorIds = e.getMessage()+errorIds;
            if(errorIds.length()>100000){
                errorIds = errorIds.substring(0,100000);
            }
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC){
        //Updating the status for those Duplicate Invoices to Error and Ready for integration as False
        try{
            
            if( QTB_Ready_for_Integration_Batch.throwExplicitException){
                throw new NullPointerException();
            }
            //Epic:2999
            if(invIdSet != null && !invIdSet.isEmpty()){
                //Calling of another batch with 5 mins delay
                Datetime dt1 = Datetime.now();
                Datetime dt = dt1.addminutes(5);
                Integer seconds = dt.second();
                Integer minutes = dt.minute();
                Integer hours = dt.hour();
                Integer dayOfMonth = dt.day();
                Integer month = dt.month();
                Integer year = dt.year();
                // Constructing the cron expression
                String cronExpression = seconds + ' ' + minutes + ' ' + hours + ' ' +
                    dayOfMonth + ' ' + month + ' ? ' + year;
                system.debug('cronExpression >>> '+cronExpression);
                //Scheduler that calls the new batch for Posting the Draft lines 
               	List<CronTrigger> jobRecords = new List<CronTrigger>(); //Epic 2999 hypercare2           
                QTB_ReadyForInt_SuccessError_Scheduler b1 = new QTB_ReadyForInt_SuccessError_Scheduler(invIdSet);
                Id primaryRecordId = new list<id>(invIdSet).get(0); //Epic:2999
                String jobName = 'ReadyForSuccessErrorIntgeration_'+ primaryRecordId; //Epic 2999 hypercare2
                //Epic 2999 hypercare2
                //Querying the existing scheduled jobs.
                jobRecords = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, CronExpression, NextFireTime, State
                                                FROM CronTrigger where CronJobDetail.Name  LIKE :jobName + '%' and State IN('WAITING','ACQUIRED','EXECUTING')];
                System.debug('>>>jobRecords'+jobRecords);
                if(jobRecords.isEmpty())
                {
					System.debug('>>insideifffjobrecords');
                    System.schedule(jobName+' '+cronExpression, cronExpression, b1);
                }
                
              //Epic 2999 hypercare2closing              
               
            }
        }
        catch(Exception e){
            e.getMessage();
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }  
}