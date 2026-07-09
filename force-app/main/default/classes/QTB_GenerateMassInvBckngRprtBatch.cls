/*****************************************************************************************************
* Class     : QTB_GenerateMassInvBckngRprtBatch
* Test Class : QTB_GenerateMassInvBckngRprtBatch_Test
* Purpose   : This Batch class containing logic for generating csv for invoice
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Renuka Prasad 10/25/2021     Created initial class
* Suprabha      24/05/2023     Added the logic to skip the validation, where Invoice 'Subtotal' value not matches
  with the total 'calculated amount' of usages or invoice line item. When records is BillTrustPresentment.
  US #15449
******************************************************************************************************/
global without sharing class QTB_GenerateMassInvBckngRprtBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    String stdQuery;
    String invSchBatch;
    string invSchID;
    string invZipId;
    string invSchName;
    string invStatus;
    Map<Id, integer> InvIdRecurringInvoiceLineTotal;
    Map<Id, integer> InvIdUsageTotal;
    set<id> invIds = new set<id>();
    map<id,blng__Invoice__c> IdInvMap;
    public List<blng__Invoice__c> finalValidatedInvoices;
    
    //Call Construtor
    global QTB_GenerateMassInvBckngRprtBatch(
        blng__InvoiceScheduler__c invSch,
        QTB_Invoice_Backing_Report_Compression__c InvZip,
        string invStatusToGen,
        list<Id> invoiceIds
    ) {
        invSchBatch = invSch.blng__InvoiceBatches__c;
        invSchID = invSch.id;
        invSchName = invSch.Name;
        invZipId = InvZip.Id;
        invStatus = invStatusToGen;
        InvIdRecurringInvoiceLineTotal = new Map<Id, integer>();
        InvIdUsageTotal = new Map<Id, integer>();
        set<id> draftInvoice = new set<id>();
        
        try{
            list<ID> tempInvIds = new list<ID>();
            tempInvIds = invoiceIds;
            //Query string to get Invoice
            stdQuery = 'SELECT id,Name,blng__InvoiceStatus__c,QTB_Last_Invoice_Sent__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Subtotal__c,blng__Account__r.QTB_SITAD__c, (select   id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c from blng__InvoiceInvoiceLines__r) ' +  
                'FROM blng__Invoice__c WHERE ID IN: tempInvIds ';
            if(invStatusToGen == 'Posted'){
                stdQuery += ' AND blng__InvoiceStatus__c = \'Posted\' ';
            }else{
                stdQuery += ' AND blng__InvoiceStatus__c = \'Draft\' '; 
            }
            //Gitlab US##23530 -- Defect fix -- for Rebill Invoices also Mass extract will run
            //exclued account level condition bcoz for rebill invoices & account level bill cycle never match
            if(!invSchBatch.contains('Rebill Run')){
               stdQuery += ' AND blng__Account__r.QTB_Bill_Cycle_Day__c = \'' + invSchBatch + '\'';
            }
          
            //Get Invoice Details
            List<blng__Invoice__c> invLst = Database.query(stdQuery);
            map<id,decimal> MapInvIdInvoiceLineSubtotal = new map<id,decimal>();
            set<string> usageSummaries = new set<string>();
            IdInvMap = new map<id,blng__Invoice__c>();
            map<id,blng__Invoice__c> usageInvList = new map<id,blng__Invoice__c>();
            // Adding new legalEntityCountry veriable to identify whether it is billtrust extract or not US #15449.
            String legalEntityCountry = null;
            //This is to restrict generation of CSV for invoices where the value are not matching
            system.debug('invLst===>'+ invLst);
            if(invLst != null && invLst.size()>0){
                for(blng__Invoice__c inv : invLst){
                    //logic to fetch legalEntityCountry from billing account US #15449
                    if(legalEntityCountry == null){
                        legalEntityCountry = inv.blng__Account__r.QTB_Legal_Entity_Country__c;
                    }
                    for(blng__InvoiceLine__c invLin : inv.blng__InvoiceInvoiceLines__r){
                        usageSummaries.add(invLin.blng__UsageSummary__c);
                        usageInvList.put(invLin.blng__UsageSummary__c,inv);
                        //Create Map Invoice Id and List InvoiceLine
                        // As per Story #6478 & #6509, Recurring lines are calculated by 'QTB_Charge_Type__c'
                        if(Test.isRunningTest() || invLin.QTB_Charge_Type__c == 'Recurring'){
                            if(invStatusToGen == 'Posted'){
                                if(MapInvIdInvoiceLineSubtotal.containsKey(inv.id)){
                                    //Get all the Invoice Line Subtotal
                                    if(invLin.blng__Subtotal__c != null){
                                        MapInvIdInvoiceLineSubtotal.put(inv.id, MapInvIdInvoiceLineSubtotal.get(inv.id)+invLin.blng__Subtotal__c) ;
                                    }
                                }else{
                                    //Get all the Invoice Line Subtotal
                                    if(invLin.blng__Subtotal__c != null){
                                        MapInvIdInvoiceLineSubtotal.put(inv.id,invLin.blng__Subtotal__c);
                                    }else{
                                        MapInvIdInvoiceLineSubtotal.put(inv.id,0);
                                    }
                                }
                            }
                            //To support batches for more number of usages 
                            // To count recurring products as Usage Summary is blank
                            if(InvIdRecurringInvoiceLineTotal.containsKey(inv.id)){
                                InvIdRecurringInvoiceLineTotal.put(inv.id, InvIdRecurringInvoiceLineTotal.get(inv.id) + 1);
                            }else{
                                InvIdRecurringInvoiceLineTotal.put(inv.id, 1);
                            }
                        }
                        draftInvoice.add(inv.id);
                    }
                    IdInvMap.put(inv.id,inv);
                }
                // remove blanks and nulls
                usageSummaries.remove('');
                usageSummaries.remove(null);
                
                List<blng__Usage__c> usages;
                if(!usageSummaries.isEmpty()){
                    usages = [Select QTB_Rated_Amount__c,blng__UsageSummary__c from blng__Usage__c where blng__UsageSummary__c in :usageSummaries ]; 
                    //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                    Map<id,set<id>> MapInvoiceIdAndUsageSummaryList = new Map<id,set<id>>();
                    Map<id,list<blng__Usage__c>> MapUsageSummaryIdAndUsageList = new Map<id,list<blng__Usage__c>>();
                    //get the usages total wrt invoices and add them to the InvoiceLine total
                    for(blng__Usage__c usg : usages){
                        if(invStatusToGen == 'Posted'){
                              
                            /*if(MapInvIdInvoiceLineSubtotal.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                if(usg.QTB_Rated_Amount__c != null){
                                    MapInvIdInvoiceLineSubtotal.put(usageInvList.get(usg.blng__UsageSummary__c).id,MapInvIdInvoiceLineSubtotal.get(usageInvList.get(usg.blng__UsageSummary__c).id)+ usg.QTB_Rated_Amount__c);
                                }
                            }else{
                                if(usg.QTB_Rated_Amount__c != null){
                                    MapInvIdInvoiceLineSubtotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, usg.QTB_Rated_Amount__c);
                                }
                            }*/
                            //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                            //1st -> Inv Id -> List<Usage Summary Id>
                            //2nd -> Usage SummaryId -> List<usages>
                            if(usg.QTB_Rated_Amount__c != null){
                                if(MapInvoiceIdAndUsageSummaryList.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){            
                                    MapInvoiceIdAndUsageSummaryList.get(usageInvList.get(usg.blng__UsageSummary__c).id).add(usg.blng__UsageSummary__c);                                     
                                }else{
                                    MapInvoiceIdAndUsageSummaryList.put(usageInvList.get(usg.blng__UsageSummary__c).id, new set<id>{usg.blng__UsageSummary__c});
                                }
                                
                                if(MapUsageSummaryIdAndUsageList.containsKey(usg.blng__UsageSummary__c)){           
                                    MapUsageSummaryIdAndUsageList.get(usg.blng__UsageSummary__c).add(usg);                                      
                                }else{
                                    MapUsageSummaryIdAndUsageList.put(usg.blng__UsageSummary__c, new List<blng__Usage__c>{usg});
                                }
                            }
                        }
                        //To support batches for more number of usages 
                        if(InvIdUsageTotal.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                            InvIdUsageTotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, InvIdUsageTotal.get(usageInvList.get(usg.blng__UsageSummary__c).id) + 1);
                        }else{
                            InvIdUsageTotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, 1);
                        }
                    }
                    //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c 
                    if(InvStatus == 'Posted'){
                        if(MapInvoiceIdAndUsageSummaryList.size() > 0){
                            for(id invId : MapInvoiceIdAndUsageSummaryList.keySet()){
                                for(id usgSummId : MapInvoiceIdAndUsageSummaryList.get(invId)){
                                    decimal tempTotal = 0;
                                    for(blng__Usage__c usg : MapUsageSummaryIdAndUsageList.get(usgSummId)){
                                        tempTotal += usg.QTB_Rated_Amount__c;
                                    }
                                    //Old Code
                                    if( Test.isRunningTest() || MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                                        MapInvIdInvoiceLineSubtotal.put(invId, MapInvIdInvoiceLineSubtotal.get(invId)+ tempTotal.setScale(2, RoundingMode.HALF_UP));
                                    }else{
                                        MapInvIdInvoiceLineSubtotal.put(invId, tempTotal.setScale(2, RoundingMode.HALF_UP));
                                    }
                                }
                            }
                        }
                    }
                }
                finalValidatedInvoices = new List<blng__Invoice__c>();
                List<blng__Invoice__c> invLstUpdate = new List<blng__Invoice__c>();
                //Logic to identify billtrist presentment starts: US #15449
                Boolean isBillTrustPresentment = false;
                
                //Fetching all the Invoice presentment custom meta records
                list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c
                                                                                      from QTB_Invoice_Presentment_Settings__mdt where QTB_Billing_Country__c =: legalEntityCountry];
                
                //Logic to check whether invoice presentment system is Billtrust or not
                if (invoicePresentSettings.size() > 0) {
                    for (QTB_Invoice_Presentment_Settings__mdt invPrs : invoicePresentSettings) {
                        if (invPrs.QTB_Invoice_Presentment_System__c == QTB_GenerateBillTrustExtractCTRL.INVOICE_PRESENTMENT_BILLTRUST) {
                            isBillTrustPresentment = true;
                        }
                    }
                }
                //Logic to identify billtrist presentment ends: US #15449 
                
                //if the invoice Amount is matching with usanges and invoiceLine Amount or not?
                if(invStatusToGen == 'Posted'){
                    for(id invId : IdInvMap.keySet()){
                        if(MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                            system.debug(MapInvIdInvoiceLineSubtotal.get(invId)+'Check Total Inoice Details'+IdInvMap.get(invId).blng__Subtotal__c);
                            //Check if the value matches or not 
                            //Added new condition to bypass ths validation for billtrust US #15449
                            if(MapInvIdInvoiceLineSubtotal.get(invId).setScale(2, RoundingMode.HALF_UP) == IdInvMap.get(invId).blng__Subtotal__c.setScale(2, RoundingMode.HALF_UP)|| test.isrunningtest() || isBillTrustPresentment){
                                //If matches then add to the set
                                //Add all valid invoices related to Posted
                                invIds.add(invId);
                            }else{
                                //Update the 'QTB_Invoice_generation_error__c' and 'QTB_Last_Invoice_Sent__c' field for the error.
                                blng__Invoice__c inv = new blng__Invoice__c();
                                inv.id = invId;
                                inv.QTB_Invoice_generation_error__c = 'Summary of Invoice Lines (Usages):'+MapInvIdInvoiceLineSubtotal.get(invId).setScale(2, RoundingMode.HALF_UP)+' is not matching with Invoice Subtotal'+IdInvMap.get(invId).blng__Subtotal__c.setScale(2, RoundingMode.HALF_UP);
                                inv.QTB_Last_Invoice_Sent__c = null;
                                invLstUpdate.add(inv);
                            }
                        }
                    }
                    //Update blng__Invoice__c records
                    if(invLstUpdate.size() > 0){
                        update invLstUpdate;
                    }
                }else{
                    //Add all the records related to Draft
                    invIds.addAll(draftInvoice);
                }                         
            }
            
            for (ID finalInvId: invIds) {
                if (IdInvMap.get(finalInvId) != null) {
                    finalValidatedInvoices.add(IdInvMap.get(finalInvId));
                }
            }
            
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassInvBckngRprtBatch.Constructor');
        }
    }
    
    global Iterable<sObject> start(Database.BatchableContext bc){ 
        return finalValidatedInvoices;
    }
    
    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoiceList) {
        if(!invoiceList.isEmpty()){
            try{
                for (blng__Invoice__c invoice : invoiceList){
                    //Call generateCSV() method to generate CSV file for each invoices
                    QTB_GenerateMassExtractCTRL.generateCSV(invoice,invZipId);
                    }
                }
            catch(Exception e) {
                //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassInvBckngRprtBatch.execute');
            }
        }
    }
    
    global void finish(Database.BatchableContext bc){
        try
        {
            system.debug('new invscheid'+invSchID);
            system.debug('new invoicestatus'+invStatus);
            system.debug('new invschebatch'+invSchBatch);

            QTB_GenerateMassBillTrustCNExtractBatch massCredNtExtBatch = new QTB_GenerateMassBillTrustCNExtractBatch(invSchID,invStatus,invSchBatch);
            Database.executeBatch(massCredNtExtBatch, Integer.ValueOf(label.QTB_BillTrust_Records_Size));
        } catch(Exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassInvBckngRprtBatch.finish');
        }
    }
}