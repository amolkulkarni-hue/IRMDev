/******************************************************************************************************
* Class: QTB_InvoiceBatch
* Author: Accenture
* Purpose: This is a Batch class containing logic for pasting Custom Invoice Id while posting Invoices
* Requirement: QTB-44a,QTB-9
* Change History: 5/29/2020
* Developer        Date           Description
* ------------------------------------------------------------------------------------------- 
*                 3/18/2020
* Gopi/Shailesh   04/10/2021    #5226- Unable to convert Draft invoice to Posted through Invoice scheduler
* Virtusa         06/10/2022    Git #9089 -- Getting POBalance Batch Error in Prod, Going forward PO calculation taking care only from QTB_InvoiceBatch class, and commented calling CalculatePO from QTB_InvoiceHelper trigger.
* Virtusa         20/03/2023    Git #14033 -- Only for India invoices;Replacing billingState with District Name field on Market object as per the ask 
* Virtusa         11/01/2024    Git #20298 -- GBP: Analyse the performance of the Usage Update Batch (QTB_UpdateUsageOnInvPost)
* Parth(Virtusa)  23/01/2024    Git #20657 - posting invoices based on tax override amount value
* Parth(Virtusa)  08/11/2024    Git #25905 - adding condition to pick invocies generated from generate draft button on adHoc order 
*******************************************************************************************************/
global class QTB_InvoiceBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    
    private static final String CLASSNAME = QTB_InvoiceBatch.class.getName();
    public static final String DRAFT=QTB_Constants.INVOICE_STATUS_DRAFT;
    public static final String TAXSTATUS_COMPLETED=QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
    public static boolean throwExplicitException = false;
    public set<String>invSchBatch;
    public final  Id billFlowRecord;
    public final  Id InvoiceSchedulerId;
    public final  Id RebillOrderId; // GITLAB #25022 - To fix rebill invoice posting issue (Credit/Rebill Billnow)
    public list<QTB_Bill_Flow_Controller__c> QtbFlowLst = new list<QTB_Bill_Flow_Controller__c>();
    public set<id> PostedInvoiceIds;
    Set<id> billFlowSetId = new Set<id>(); //Epic 2988
    public set<string> RunningCountry=new set<String>();    
    //#30236 Initializing Required Variables
    Map<Id,blng__Invoiceline__c> usageSummryToInvLineMap = new Map<Id,blng__Invoiceline__c>();
    // Map to store invoice id and set of invoice line ids
    public Map<id,Set<id>> mapOfInvcAndInvcLineSet = new Map<id,Set<id>>();
    //constructor
    public QTB_InvoiceBatch(string invoiceBatch, Id billFlow){
        
        String invoiceBatchName = invoiceBatch;
        if(invoiceBatch!=null){
            invSchBatch = new Set<String>(invoiceBatch.split(';'));
        }
        billFlowRecord = billFlow;
        PostedInvoiceIds = new set<id>();
        QtbFlowLst=[Select id,QTB_Rebill_Order__c,Invoice_Scheduler__c from QTB_Bill_Flow_Controller__c where id =:billFlowRecord];
        if(QtbFlowLst.size() > 0 && !invoiceBatchName.containsIgnoreCase('Rebill') && QtbFlowLst[0].QTB_Rebill_Order__c == null) 
        { 
            
            InvoiceSchedulerId=QtbFlowLst[0].Invoice_Scheduler__c;
        }
        
        // GITLAB #25022 - To capture rebillInvoice Id that will be used in Rebill Query (Credit/Rebill Billnow)
        // GITLAB #25905 - adHoc order Generate Draft button functionality, functionality is same as of Credit/Rebill Billnow, except invoice batch will not conatin Rebill
        else if(QtbFlowLst.size() > 0 && (invoiceBatchName.containsIgnoreCase('Rebill') || QtbFlowLst[0].QTB_Rebill_Order__c != null)) 
        { 
            
            RebillOrderId=QtbFlowLst[0].QTB_Rebill_Order__c;
            
        }
    }
    //2988 Epic://constructor
     public QTB_InvoiceBatch(string invoiceBatch, Set<Id> billFlow){
             System.debug('>>insidelistconstructor');
             Set<id> billFlowIdSet = new Set<id>();
             String invoiceBatchName = invoiceBatch;
             if(invoiceBatch!=null){
                 invSchBatch = new Set<String>(invoiceBatch.split(';'));
             }
             System.debug('>>billFlow'+billFlow);
             billFlowSetId = billFlow;
             PostedInvoiceIds = new set<id>();
             QtbFlowLst=[Select id,QTB_Rebill_Order__c,Invoice_Scheduler__c from QTB_Bill_Flow_Controller__c where id IN :billFlowSetId];
             System.debug('??>>QtbFlowLst'+QtbFlowLst);
             if(QtbFlowLst.size() > 0 && !invoiceBatchName.containsIgnoreCase('Rebill') && QtbFlowLst[0].QTB_Rebill_Order__c == null) 
             { 
                 
                 InvoiceSchedulerId=QtbFlowLst[0].Invoice_Scheduler__c;
             }
             
             // GITLAB #25022 - To capture rebillInvoice Id that will be used in Rebill Query (Credit/Rebill Billnow)
             // GITLAB #25905 - adHoc order Generate Draft button functionality, functionality is same as of Credit/Rebill Billnow, except invoice batch will not conatin Rebill
             else if(QtbFlowLst.size() > 0 && (invoiceBatchName.containsIgnoreCase('Rebill') || QtbFlowLst[0].QTB_Rebill_Order__c != null)) 
             { 
                 
                 RebillOrderId=QtbFlowLst[0].QTB_Rebill_Order__c;
                 
             }             
         
              
     }        
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Requirement: SFCPQBLG-55,SFCPQBLG-58
Description: Query Draft invoice records in context
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC){
        String Query = '';
        // For Rebill Invoice Gitlab US#2477 (Credit/Rebill Billnow)
        // #25905, changing condition from invoiceBatchName.containsIgnoreCase('Rebill') to RebillOrderId != null so that it will work for both rebill and adHoc generate Draft functionality
        //#30973 #31259 Cluster 4 Countries Queried blng__Account__r.QTB_Invoice_Delivery_Options__c for Turkey Enhancement
        if(RebillOrderId != null){
            
            Query ='select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Invoice_Delivery_Options__c,'+
                'blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,' +
                'blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,'+ 
                'recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,QTB_Invoice_Posted_Error__c,QTB_Ready_for_Integration__c,QTB_Ready_for_Integration_Status__c FROM blng__Invoice__c ' + 
                'WHERE blng__Order__c =:RebillOrderId and blng__Account__r.QTB_Hold_Invoice__c = false and QTB_HoldOptionForInvoice__c=false and blng__InvoiceStatus__c =:DRAFT '+
                'and blng__TaxStatus__c= :TAXSTATUS_COMPLETED and QTB_Bill_Cycle_Day__c IN :invSchBatch limit 50000';
        }
        // For Regular we have invoiceSchedular
        else{
            Query ='select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Invoice_Delivery_Options__c,'+
                'blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,' +
                'blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,'+ 
                'recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,QTB_Invoice_Posted_Error__c,QTB_Ready_for_Integration__c,QTB_Ready_for_Integration_Status__c FROM blng__Invoice__c ' + 
                'WHERE blng__Account__r.QTB_Hold_Invoice__c = false and QTB_HoldOptionForInvoice__c=false and blng__InvoiceStatus__c =:DRAFT '+
                'and blng__TaxStatus__c= :TAXSTATUS_COMPLETED and QTB_Bill_Cycle_Day__c IN :invSchBatch and blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c =:InvoiceSchedulerId limit 50000';
        }
        //2988 Epic: Start
        if(billFlowRecord != null)
        {
            update new QTB_Bill_Flow_Controller__c(Id = billFlowRecord, QTB_PostBill_Run_status__c = 'In Progress');  
        }
        else
        {
            List<QTB_Bill_Flow_Controller__c> billFlowContr =  new List<QTB_Bill_Flow_Controller__c>();
            for(id billFlowIds :billFlowSetId)
            {
                System.debug('>>>inprogressforloop');
                QTB_Bill_Flow_Controller__c billflow = new QTB_Bill_Flow_Controller__c();
                billflow.QTB_PostBill_Run_status__c = 'In Progress';
                billflow.id = billFlowIds;
                System.debug('>>billFlowIds1'+billFlowIds);
                billFlowContr.add(billflow);
            } 
            if(!billFlowContr.isEmpty())
            {
                update billFlowContr;
            }    
        }
       //2988 Epic:End
       
        return Database.getQueryLocator(Query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__Invoice__c>
Return Type: void
Requirement: SFCPQBLG-55,SFCPQBLG-58
Description: Execute logic to post the draft invoices and update custom invoice number
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<blng__Invoice__c> scope){
        // 24438 Set To store custome setting for Custom Invoice Number
        List<QTB_CustomInvoiceNumber__c> customSettingsToUpdate= new List<QTB_CustomInvoiceNumber__c>();
        // 24438 List of invoice after Custom invoice generation
        List<blng__Invoice__c> lstUpdatedInvcList = new List<blng__Invoice__c>();
        // 24438 List of invoice after Custom invoice generation
        List<blng__Invoice__c> invoicesToUpdate = new List<blng__Invoice__c>();
        //Story #22304 Map to store Invoice id and List of related invoice Line
        Map<Id, List<blng__InvoiceLine__c>> invcAndInvoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
        // #20657 - posted invoices List
        list<blng__invoice__c> updateInvoiceStatus = new List<blng__invoice__c>();
        // #
        list<blng__invoice__c> lstPostInPrgrsInvc = new list<blng__invoice__c>();
        // set to store invoiceLineIds 
		set<id> invoiceLineIds ;
        string errorIds ='';
        try{
            if(throwExplicitException){ 
                throw new NullPointerException();
            }
            System.debug('Outside the scope ->');
            
            // Story #22304 Logic to update below fields for Legacy Invoice
            //30236 Added InvoiceType and usage Summary
            List<blng__InvoiceLine__c> lstInvcLine = [Select id,QTB_Charge_Type__c,blng__Invoice__c,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.QTB_Invoice_Type__c,blng__UsageSummary__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c from blng__InvoiceLine__c where  blng__Invoice__c IN :scope];         
            if(!lstInvcLine.IsEmpty()){
                //#30236 Added if Loop for Seperating he Legacy invoice
                for (blng__InvoiceLine__c invoiceLine : lstInvcLine) {
                    invoiceLineIds = new Set<Id>(); 
                    invoiceLineIds.add(invoiceLine.id);
                    if(invoiceLine.blng__Invoice__r.QTB_Invoice_Type__c == 'Legacy Invoice'){
                        usageSummryToInvLineMap.put(invoiceLine.blng__UsageSummary__c,invoiceLine);
                    }
                    List<blng__InvoiceLine__c> lstInvoiceLine = new List<blng__InvoiceLine__c>();
                    lstInvoiceLine.add(invoiceLine);
                    
                    if (invcAndInvoiceLineMap.containsKey(invoiceLine.blng__Invoice__c)) {    
                        lstInvoiceLine.addAll(invcAndInvoiceLineMap.get(invoiceLine.blng__Invoice__c)) ; 
                    }
                    invcAndInvoiceLineMap.put(invoiceLine.blng__Invoice__c,lstInvoiceLine);  
                    if(invoiceLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c == 'Turkey'){
                        if(mapOfInvcAndInvcLineSet.containsKey(invoiceLine.blng__Invoice__c)){
                            invoiceLineIds.addAll(mapOfInvcAndInvcLineSet.get(invoiceLine.blng__Invoice__c));
                        }
                        mapOfInvcAndInvcLineSet.put(invoiceLine.blng__Invoice__c,invoiceLineIds);
                    }
                }                    
            } 
            
            for(blng__Invoice__c invoice : scope)
            { 
                system.debug('invoice@@' +invoice);
                errorIds +=';;'+invoice.id; 
                RunningCountry.add(invoice.blng__Account__r.QTB_Legal_Entity_Country__c);
                System.debug('Inside loop'+invoice.id);
                //Custom invoice logic for each record based on billing country from Account
                if (invoice.blng__Account__r.QTB_Contract_Entity__c !=null && invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c != NULL &&
                    invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c != null)
                {    
                    if(invoice.QTB_Custom_Invoice_Number__c == null){
                        lstUpdatedInvcList.add(invoice);
                    }else{
                        lstPostInPrgrsInvc.add(invoice);
                    }
                }
            }
            if(!lstUpdatedInvcList.isEmpty()){
                // #30236
                Map<List<blng__Invoice__c>, List<QTB_CustomInvoiceNumber__c>> mapInvcCstmSetngForCustmInvcNo;
                // 24438 Call QTB_Regenerate_Custom_Invc_No class to get the custom invoice number 
                 // #30236 Added If Else condition for passing the Paraameters if the Map is not Null Passing the UssummaryId as Key and Value as InvLine data else List and Null Parameter to work as Is to reduce the SOQL Query count
                if(usageSummryToInvLineMap != Null && !usageSummryToInvLineMap.IsEmpty()){
                    mapInvcCstmSetngForCustmInvcNo = QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(lstUpdatedInvcList,usageSummryToInvLineMap);
                }
                else{
                    mapInvcCstmSetngForCustmInvcNo = QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(lstUpdatedInvcList,null);
                }
                    if(mapInvcCstmSetngForCustmInvcNo != Null && !mapInvcCstmSetngForCustmInvcNo.isEmpty()){
                    // Add Invoice records to update lists without nested loops
                    for (List<blng__Invoice__c> invoiceList : mapInvcCstmSetngForCustmInvcNo.keySet()) {
                        invoicesToUpdate.addAll(invoiceList);  // Add all invoices in the list
                    }
                    for (List<QTB_CustomInvoiceNumber__c> customSettingList : mapInvcCstmSetngForCustmInvcNo.values()) {
                        if(!customSettingList.isEmpty() && customSettingList!= null){
                            customSettingsToUpdate.addAll(customSettingList);  // Add all custom settings in the list
                        }
                    }
                }
            }
            if(!lstPostInPrgrsInvc.isEmpty()){
                invoicesToUpdate.addAll(lstPostInPrgrsInvc);
            }
            
            // #20657 based on map of invoice and doPsoting updating invoice status 
            if(!invoicesToUpdate.isEmpty() && !invcAndInvoiceLineMap.IsEmpty() || Test.isRunningTest()){
                for(blng__Invoice__c invoiceRecord : invoicesToUpdate){
                    blng__invoice__c invoice = new blng__invoice__c();
                    invoice = invoiceRecord;
                    
                    // Changing status from 'Draft' to 'Posted' and update record type to Posted
                    invoice.blng__InvoiceStatus__c = QTB_Constants.INVOICE_STATUS_POSTED;
                    invoice.recordTypeId = QTB_Utils.INVOICE_POSTED_RECTYPEID;
                    invoice.blng__InvoicePostedDate__c = System.today();
                    invoice.QTB_Ready_for_Integration_Status__c = 'Post In Progress'; 
                    if(invcAndInvoiceLineMap.ContainsKey(invoice.Id)){
                        // If Order Category field in Order is Legacy then Terminate the loop for iteration over other Invoice Lines 
                        for (blng__InvoiceLine__c invLine : invcAndInvoiceLineMap.get(invoice.Id)) {                                    
                            if(invLine.blng__OrderProduct__r.Order.QTB_OrderCategory__c == 'Legacy'){
                                invoice.QTB_Invoice_Type__c = 'Legacy Invoice';
                                invoice.QTB_Transferred_To_Oracle__c = True;
                                invoice.QTB_Transferred_to_Invoice_Compliance__c = System.Now().addDays(-90);
                                break;
                            } 
                        }
                    }
                    if(invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == 'Flat Rate'){
                        //for india along with invoice Tax override amount, invoice line HSN value should not be null
                        if(invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c == 'India' && invcAndInvoiceLineMap.containsKey(invoice.Id)){
                            for(blng__InvoiceLine__c invLn :invcAndInvoiceLineMap.get(invoice.Id)){
                                if(invLn.QTB_HSN_Code__c == null){
                                    invoice.blng__InvoiceStatus__c = 'Error';
                                    invoice.QTB_Ready_for_Integration_Status__c = 'HSN Code not Defined';
                                    break;
                                }
                            }
                        }
                    } 
                    updateInvoiceStatus.add(invoice);
                }
            }
            
            // full success or  failure
            Database.saveresult[] invoiceUpdateResult=Database.update(updateInvoiceStatus,false);
            // Added as part of 27329 to allow partial failure so that the entire inv batch doesnt fails.
            for(Integer i=0; i < invoiceUpdateResult.size(); i++) 
            {
                //US #5226, 
                if(invoiceUpdateResult.get(i) != null){
                    PostedInvoiceIds.add(invoiceUpdateResult.get(i).getId());
                }
                //If its the last record and that's also success, then only update custom setting
                if(i==(invoiceUpdateResult.size())-1 && invoiceUpdateResult.get(i).isSuccess() && !customSettingsToUpdate.isEmpty())
                {
                    update customSettingsToUpdate;
                }
            }
            customSettingsToUpdate.clear();
            updateInvoiceStatus.clear();
            lstUpdatedInvcList.clear();
            invoiceUpdateResult.clear();
            invoicesToUpdate.clear();
            lstPostInPrgrsInvc.clear();
        }  
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            e.getLineNumber();
            System.debug('Exception message:'+e.getMessage());
            errorIds = e.getMessage()+errorIds;
            if(errorIds.length()>100000){
                errorIds = errorIds.substring(0,100000);
            }
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),CLASSNAME);
        }
    }
    
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Requirement: SFCPQBLG-55,SFCPQBLG-58
Description: No Action required
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC){
        string errorIds ='';
        try{
            if(throwExplicitException){ 
                throw new NullPointerException();
             }
            //2988 Epic: Start
            if(billFlowRecord != null)
            {
                update new QTB_Bill_Flow_Controller__c(Id = billFlowRecord, QTB_PostBill_Run_status__c = 'Completed');
            }
           else{
               Map<Id,QTB_Bill_Flow_Controller__c> bilflowIdMAP = new Map<Id,QTB_Bill_Flow_Controller__c>();
                List<QTB_Bill_Flow_Controller__c> billFlowContr =  new List<QTB_Bill_Flow_Controller__c>();
                Set<QTB_Bill_Flow_Controller__c> billFlowSet = new  Set<QTB_Bill_Flow_Controller__c>();
                for(id billFlowIds :billFlowSetId)
                {
                    System.debug('>>>completedforloop');
                    if(!bilflowIdMAP.containskey(billFlowIds) || bilflowIdMAP==null){
                    QTB_Bill_Flow_Controller__c billflow = new QTB_Bill_Flow_Controller__c();
                    billflow.QTB_PostBill_Run_status__c = 'Completed';
                    billflow.id = billFlowIds;
                    System.debug('>>billFlowIds'+billFlowIds);
                    billFlowContr.add(billflow);
                    bilflowIdMAP.put(billFlowIds,billflow);
                    }
                    
                   // billFlowSet.add(billflow);
                    //billFlowContr.addAll(billFlowSet);
                    System.debug('>>>billFlowSet'+billFlowSet);
                    System.debug('>>>>>billFlowContr'+billFlowContr);
                }
                if(!billFlowContr.isEmpty())
                {
                    update billFlowContr;
                }   
            }
          //2988 Epic: End       
            system.debug('$$$$===='+RunningCountry);
           
            // post processing, US #5226
            if ((PostedInvoiceIds !=null && !PostedInvoiceIds.isEmpty()) || Test.isRunningTest()) {
                //Calling QTB_CalculatePOBalanceBatch to update the PO Balance for the processed invoices
                Set<ID> creditNoteIds = new Set<ID>();
                Set<ID> processedInvoiceIds = new Set<ID>();
                Set<ID> poIds = new Set<ID>();
                processedInvoiceIds.addAll(PostedInvoiceIds);
                
                //#22115 Draft Invoice lines to be posted
                List<blng__InvoiceLine__c> lstUpdatedInvcLine = new List<blng__InvoiceLine__c>();
                //Set<blng__Invoice__c> setOfInv = new Set<blng__Invoice__c>(); //#22115 Set of Draft Invoice ids to update QTB_Transferred_to_Invoice_Compliance__c
                
                //As part of Gitlab #9011 defect, we found Calculate PO executing 2 times due to below line of code, hence commenting.
                //As Part of Gitlab #9089, going forward PO calculation taking care only from QTB_InvoiceBatch class, and commented calling CalculatePO from QTB_InvoiceHelper trigger.
                /*if(isPOEligibleCountry){
Database.executeBatch(new QTB_CalculatePOBalanceBatch(processedInvoiceIds, creditNoteIds, poIds), Integer.valueOf(System.Label.QTB_CalculatePOBatchSize));   
}*/
                
                //Calling QTB_UpdateUsageOnInvPost to update the usage related to processed invoices
                datetime strt= system.now();
                while(system.now() < strt.addSeconds(15)){}
                //As part of Gitlab #20298, changed the batch size to 2000 and stored the value in a custom label (QTB_UsageUpdate_Batch_size)
                Database.executeBatch(new QTB_UpdateUsageOnInvPost(processedInvoiceIds), Integer.valueOf(System.Label.QTB_UsageUpdate_Batch_size));
                System.debug('Total processed invoice ------'+processedInvoiceIds.size());
                //Gitlab #22115 Calling the Scheduler class for posting the Draft lines
                system.debug('662 @@ processedInvoiceIds  '+processedInvoiceIds);
                
                integer delay = 5;
                Datetime dt1 = Datetime.now();
                Datetime dt = dt1.addminutes(delay);
                Integer seconds = dt.second();
                Integer minutes = dt.minute();
                Integer hours = dt.hour();
                Integer dayOfMonth = dt.day();
                Integer month = dt.month();
                Integer year = dt.year();
                // Constructing the cron expression
                String cronExpression = seconds + ' ' + 
                    minutes + ' ' + 
                    hours + ' ' +
                    dayOfMonth + ' ' +
                    month + ' ? ' + 
                    year;
                system.debug('cronExpression >>> '+cronExpression);
                //Scheduler that calls the new batch for Posting the Draft lines 
                QTB_Ready_for_Int_Invoice_Scheduler b1 = new QTB_Ready_for_Int_Invoice_Scheduler(processedInvoiceIds);
                System.schedule('Ready For Integration '+ cronExpression, cronExpression, b1);
            } 
            
            // To check the bill flow status is Queued or not,  If Queued then Recall Invoice batch class and vertex class
            // # 19408  Start//    
            List<id> invoiceSchdularId = new List<id>();
            List<id> billFlowId = new List<id>();
            Set<Id> rebillinvoiceIds = new Set<Id>();
            // get the country specific Invoice Batch by Bill Cycles
            List<string> billCycleBatch=new List<string>();
            
            
            string InvSch;
            String invSchd;
            Id invRunId;		
            
            for(QTB_Invoice_Batch_by_Bill_Cycle__mdt billCycle:[select id, QTB_Country__c,QTB_Invoice_Batch__c from QTB_Invoice_Batch_by_Bill_Cycle__mdt where QTB_Country__c IN: RunningCountry]){
                billCycleBatch.add(billCycle.QTB_Invoice_Batch__c);				
            } 
            system.debug(RunningCountry+'############'+billCycleBatch);
            Map<String,id> invoiceSchedularBillFlowMap  = new Map<String,id>();
            // Query for Bill flow controller for Queued status
            if(!billCycleBatch.isempty() || Test.isRunningTest()){

                for (QTB_Bill_Flow_Controller__c billFlow_f: [select id, Invoice_Scheduler__c,QTB_Rebill_Invoice__c,QTB_Rebill_Order__c,QTB_Rebill_Order__r.blng__InvoiceBatch__c  from QTB_Bill_Flow_Controller__c where QTB_PostBill_Run_Status__c = 'Queued' 
                                                              and ((QTB_Rebill_Order__c!= null and QTB_Rebill_Order__r.blng__InvoiceBatch__c LIKE '%Rebill Run%' and QTB_Rebill_Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c IN:RunningCountry) 
                                                                   OR  Invoice_Scheduler__r.blng__InvoiceBatches__c IN: billCycleBatch) ]) {
                                                                       if (billflow_f.id != billFlowRecord) {
                                                                           billFlowId.add(billflow_f.id);
                                                                           if(billFlow_f.QTB_Rebill_Invoice__c != null && billFlow_f.QTB_Rebill_Order__c !=null && billFlow_f.QTB_Rebill_Order__r.blng__InvoiceBatch__c != null ){
                                                                               rebillinvoiceIds.add(billFlow_f.QTB_Rebill_Invoice__c);
                                                                               invoiceSchedularBillFlowMap.put(billFlow_f.QTB_Rebill_Order__r.blng__InvoiceBatch__c ,billflow_f.id);
                                                                               invSchd=billFlow_f.QTB_Rebill_Order__r.blng__InvoiceBatch__c;
                                                                               InvSch=billFlow_f.QTB_Rebill_Order__r.blng__InvoiceBatch__c;
                                                                               break;
                                                                           }
                                                                           else{
                                                                               invoiceSchdularId.add(billflow_f.Invoice_Scheduler__c); 
                                                                               invoiceSchedularBillFlowMap.put(billflow_f.Invoice_Scheduler__c,billflow_f.id); 
                                                                           }
                                                                       }
                                                                   }
            }

            if(invoiceSchdularId.size() > 0 || rebillinvoiceIds.size()>0 || Test.isRunningTest()){
                if(invoiceSchdularId.size() > 0){
                    //Get the respective Invoice Scheular
                    
                    List<blng__InvoiceRun__c> InvSchList = [select id, Name, blng__InvoiceScheduler__r.blng__InvoiceBatches__c from blng__InvoiceRun__c where blng__InvoiceScheduler__c IN: invoiceSchdularId];
                    // Add the list of billflows ids into set, we are calling getInvoiceids method for retrive the invoicerundids.
                    // Check invoice Run Country
                    
                    
                    for(blng__Invoice__c inv : [Select id,blng__InvoiceRunCreatedBy__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.blng__InvoiceBatches__c, blng__Account__r.QTB_Legal_Entity_Country__c 
                                                from blng__Invoice__c 
                                                WHERE blng__InvoiceRunCreatedBy__c IN : InvSchList 
                                                and blng__Account__r.QTB_Legal_Entity_Country__c =: RunningCountry limit 1]){
                                                    
                        InvSch = inv.blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.blng__InvoiceBatches__c;
                        invSchd = inv.blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c; 
                        invRunId = inv.blng__InvoiceRunCreatedBy__c;
                        break;
                    } 
                }
                set<Id> billFlows=new set<id>();
                if(invoiceSchedularBillFlowMap.containsKey(invSchd)){
                    billFlows.add(invoiceSchedularBillFlowMap.get(invSchd));
                    // Gitlab US#2477 (Credit/Rebill Billnow) instead of invoicerunids geting invoiceids
                    Set < ID > invoiceIdsFinal = QTB_PostBillFlowController.getInvoiceIds(billFlows);
                    list<id> billFlowIds = new list<id>();
                    billFlowIds.addAll(billFlows);
                    // Run the process for Queued status bill flow controller. 
                    if(InvSch != null || Test.isRunningTest()){
                        if (!invoiceIdsFinal.isEmpty() && invoiceIdsFinal.size() > 0) {
                            QTB_vertexTaxCalloutBatch vertexBatch = new QTB_vertexTaxCalloutBatch(InvSch, billFlowIds[0], invoiceIdsFinal, null, null, true);
                            database.executeBatch(vertexBatch, integer.valueOf(system.label.QTB_Vertex_Callout_Batch_Size));
                        } else {
                            QTB_InvoiceBatch invoiceBatch = new QTB_InvoiceBatch(InvSch, billFlowIds[0]);
                            database.executeBatch(invoiceBatch, 50);
                        }
                    }
                }
            }
            else {
                //Update the custom setting Record IsRunning to False because there is no Queued  records left for the same bill flow controller
                List<QTB_CustomInvoiceNumber__c> CSupdate = new List<QTB_CustomInvoiceNumber__c>();
                
                for(QTB_CustomInvoiceNumber__c CusomInv: [select id, Name,QTB_Is_Running__c,QTB_Date_Time__c from QTB_CustomInvoiceNumber__c where QTB_Country__c IN: RunningCountry and QTB_Is_Running__c = true]) {
                    CusomInv.QTB_Is_Running__c = false;
                    CusomInv.QTB_Date_Time__c = null;
                    
                    CSupdate.add(CusomInv);
                }
                if (CSupdate.size() > 0) {
                    update CSupdate;
                }
            }
            
            if(!mapOfInvcAndInvcLineSet.isEmpty()){
                Integer batchSize=Integer.ValueOf(System.Label.QTB_StandardTaxBatchSize);
                QTB_StandardTaxOverrideCalculationBatch b=new QTB_StandardTaxOverrideCalculationBatch(mapOfInvcAndInvcLineSet);
                Database.executeBatch(b,batchSize);  
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            e.getLineNumber();
            errorIds = e.getMessage()+errorIds;
            if(errorIds.length()>100000){
                errorIds = errorIds.substring(0,100000);
            }
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),CLASSNAME);
        }
    }
        
 
}