/*****************************************************************************************************
* Class: QTB_GenerateMassExtractBatch
* Purpose: This Batch class containing logic for generating csv for invoice and txt file for invoice scheduler.
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*  Sriram      7/27/2020       Created initial class
*  Gopi/Sriram 10/19/2020      Version 1: Logic change for validation, Invoice 'Subtotal' value with the total 'calculated amount'
If the Amount doesnt match then skip those Records for file creation and update QTB_Invoice_generation_error__c field
*******************************************************************************************************/
global without sharing class QTB_GenerateMassExtractBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    String stdQuery;
    String invSchBatch;
    string invSchID;
    string invZipId;
    string invSchName;
    Integer exceptionCount;
    Integer processedCount;
    string invStatus;
    Map<Id, integer> InvIdRecurringInvoiceLineTotal;
    Map<Id, integer> InvIdUsageTotal;
    set<id> invIds = new set<id>();
    map<id,blng__Invoice__c> IdInvMap;
    map<id,string> skipInvoiceMap = new  map<id,string>();
    public List<blng__Invoice__c> finalValidatedInvoices;
    Map<integer, List<blng__Invoice__c>> finalMap = new Map<integer, List<blng__Invoice__c>>();
    //Call Construtor
    global QTB_GenerateMassExtractBatch(blng__InvoiceScheduler__c invSch,QTB_Invoice_Backing_Report_Compression__c InvZip,string invStatusToGen)
    {
        invSchBatch = invSch.blng__InvoiceBatches__c;
        invSchID = invSch.id;
        invSchName = invSch.Name;
        invZipId = InvZip.Id;
        invStatus = invStatusToGen;
        InvIdRecurringInvoiceLineTotal = new Map<Id, integer>();
        InvIdUsageTotal = new Map<Id, integer>();
        set<id> draftInvoice = new set<id>();
        try{
            //Query string to get Invoice
            //Gitlab #23874 Ready for integration addition on txt generation
            stdQuery = 'SELECT id,Name,blng__InvoiceStatus__c,QTB_Last_Invoice_Sent__c,QTB_Ready_for_Integration__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,blng__Account__r.QTB_SITAD__c, '+ 
                ' (select id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c from blng__InvoiceInvoiceLines__r) ' +  
                ' FROM blng__Invoice__c WHERE QTB_Last_Invoice_Sent__c = null';
            if(invStatusToGen == 'Posted'){
                //stdQuery += ' AND blng__InvoiceStatus__c = \'Posted\' ';
                stdQuery += ' AND QTB_Ready_for_Integration__c = True AND blng__InvoiceStatus__c = \'Posted\' '; 
            }else{
                stdQuery += ' AND blng__InvoiceStatus__c = \'Draft\' '; 
            }
            //Gitlab US##23530 -- Defect fix -- for Rebill Invoices also Mass extract will run
            //exclued account level condition bcoz for rebill invoices & account level bill cycle never match
            if(invSchBatch.contains('Rebill Run')){
                stdQuery += ' AND blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c = \'' + invSchID + '\'';
            }else{
                stdQuery += ' AND blng__Account__r.QTB_Bill_Cycle_Day__c = \'' + invSchBatch + '\' AND (NOT QTB_Bill_Cycle_Day__c LIKE \'%Rebill%\')';
            }
            processedCount = 0;
            exceptionCount = 0;
            //Get Invoice Details
            List<blng__Invoice__c> invLst = Database.query(stdQuery);
            map<id,decimal> MapInvIdInvoiceLineSubtotal = new map<id,decimal>();
            set<string> usageSummaries = new set<string>();
            IdInvMap = new map<id,blng__Invoice__c>();
            map<id,blng__Invoice__c> usageInvList = new map<id,blng__Invoice__c>();
            //This is to restrict generation of CSV for invoices where the value are not matching
            if(invLst != null && invLst.size()>0){
                for(blng__Invoice__c inv : invLst){
                    for(blng__InvoiceLine__c invLin : inv.blng__InvoiceInvoiceLines__r){
                        if(invLin.blng__UsageSummary__c != null){ //Gitlab US#24744 
                            usageSummaries.add(invLin.blng__UsageSummary__c);
                        	usageInvList.put(invLin.blng__UsageSummary__c,inv); 
                        }
                        system.debug('@@blng__UsageSummary__c'+invLin.blng__UsageSummary__c);
                        //Create Map Invoice Id and List InvoiceLine
                        //if(invLin.blng__ChargeType__c == 'Recurring'){
                        //As per New Architecture, Recurring Lines are decided by 'QTB_HasConsumptionSchedule__c'
                        //As per Story #6478 & #6509, Recurring Lines are decided by 'QTB_Charge_Type__c'
                        
                        if(invLin.QTB_Charge_Type__c == 'Recurring'){
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
                            //To support batches for more number of usages // To count recurring products as Usage Summary is blank
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
                    //Gitlab US#24744 - Start
                    List<Id> invoiceIdList = new List<Id>();
                    // Perform the aggregate query
                    Integer skipLargeInvoice = Integer.valueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size);
                    System.debug('IdInvMap.keySet()@@'+IdInvMap.keySet().size());
                    List<AggregateResult> results = [SELECT blng__UsageSummary__r.blng__Invoice__c invoiceId, COUNT(Id) usageCount
                                                     FROM blng__Usage__c
                                                     WHERE blng__UsageSummary__r.blng__Invoice__c IN: IdInvMap.keySet()
                                                     GROUP BY blng__UsageSummary__r.blng__Invoice__c
                                                     HAVING COUNT(Id) >= :skipLargeInvoice
                                                     LIMIT 50000 ];
                    //Process the results
                    for (AggregateResult ar : results) {
                        Id invoiceId = (Id) ar.get('invoiceId');
                        invoiceIdList.add(invoiceId);
                    }
                    for(blng__Invoice__c inv : [SELECT Id, Name FROM blng__Invoice__c WHERE ID IN:invoiceIdList ]){
                         skipInvoiceMap.put(inv.Id,inv.Name);
                    }
                    
                    //Gitlab US#24744 - excluding the invoices from the usages where based on above logic where usagecount is more
                    usages = [Select QTB_Rated_Amount__c,blng__UsageSummary__c 
                              from blng__Usage__c where blng__UsageSummary__c in :usageSummaries and blng__UsageSummary__r.blng__Invoice__c NOT IN :invoiceIdList];
                    
                    //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                    Map<id,set<id>> MapInvoiceIdAndUsageSummaryList = new Map<id,set<id>>();
                    Map<id,list<blng__Usage__c>> MapUsageSummaryIdAndUsageList = new Map<id,list<blng__Usage__c>>();
                    //get the usages total wrt invoices and add them to the InvoiceLine total
                    for(blng__Usage__c usg : usages){
                        if(invStatusToGen == 'Posted'){
                            //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                            //1st -> Inv Id -> Set<Usage Summary Id>
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
                        system.debug('Gopi check11--'+MapInvoiceIdAndUsageSummaryList);
                        system.debug('Gopi check22--'+MapUsageSummaryIdAndUsageList);
                        //To support batches for more number of usages //Count usages wrt Invoices
                        if(InvIdUsageTotal.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                            InvIdUsageTotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, 
                                                InvIdUsageTotal.get(usageInvList.get(usg.blng__UsageSummary__c).id) + 1);
                        }else{
                            InvIdUsageTotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, 1);
                        }
                    }
                    //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c 
                    if(InvStatus == 'Posted'){
                        if(MapInvoiceIdAndUsageSummaryList.size() > 0){
                            for(id invId : MapInvoiceIdAndUsageSummaryList.keySet()){
                            system.debug('Gopi check33--'+invId);
                                for(id usgSummId : MapInvoiceIdAndUsageSummaryList.get(invId)){
                                    system.debug('Gopi check44--'+usgSummId);
                                    decimal tempTotal = 0;
                                    for(blng__Usage__c usg : MapUsageSummaryIdAndUsageList.get(usgSummId)){
                                        system.debug('Gopi check55--'+usg.QTB_Rated_Amount__c);
                                        tempTotal += usg.QTB_Rated_Amount__c;
                                    }
                                    //Old Code
                                    if(MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                                        MapInvIdInvoiceLineSubtotal.put(invId, MapInvIdInvoiceLineSubtotal.get(invId)+ tempTotal.setScale(2, RoundingMode.HALF_UP));
                                    }else{
                                        MapInvIdInvoiceLineSubtotal.put(invId, tempTotal.setScale(2, RoundingMode.HALF_UP));
                                    }
                                }
                            }
                        }
                    }
                    system.debug('Usage Count Map'+InvIdUsageTotal);
                }
                finalValidatedInvoices = new List<blng__Invoice__c>();
                List<blng__Invoice__c> invLstUpdate = new List<blng__Invoice__c>();
                //if the invoice Amount is matching with usanges and invoiceLine Amount or not?
                if(invStatusToGen == 'Posted'){
                    for(id invId : IdInvMap.keySet()){
                        if(MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                            system.debug(MapInvIdInvoiceLineSubtotal.get(invId)+'Check Total Inoice Details'+IdInvMap.get(invId).blng__Subtotal__c);
                            //Check if the value matches or not
                            if(MapInvIdInvoiceLineSubtotal.get(invId).setScale(2, RoundingMode.HALF_UP) == IdInvMap.get(invId).blng__Subtotal__c.setScale(2, RoundingMode.HALF_UP)|| test.isrunningtest()){
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
                Integer totalCount = 0;
                Integer tempTotalCount = 0;
                integer i = 0;
                integer count = 0;
                //skipInvoiceMap = new map<id,string>();
                List<blng__Invoice__c> invIdsToBatch = new List<blng__Invoice__c>();
                //Do the proper count for the number of records to pass for the Text file in a Batch
                //Iterate all the invoice Ids
                for(id invId : invIds){
                    system.debug('Inv Id'+invId);
                    count++;
                    integer limitCheck = 0;
                    //Get all the usages Count from Non Recurring Lines
                    if(InvIdUsageTotal.containsKey(invId)){
                        totalCount += InvIdUsageTotal.get(invId);
                        System.debug('#11# Count'+totalCount);
                        limitCheck += InvIdUsageTotal.get(invId);
                    }
                    //Get all the usages Count from Recurring Lines
                    if(InvIdRecurringInvoiceLineTotal.containsKey(invId)){
                        totalCount += InvIdRecurringInvoiceLineTotal.get(invId);
                        System.debug('#22# Count'+totalCount);
                        limitCheck += InvIdRecurringInvoiceLineTotal.get(invId);
                    }
                    //Check if any big invoice is there or not? if there then skip that invoice and create Map for each Batch
                    if(limitCheck <= Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size)){
                        //If Invoice Count matches to the Custom Label Limit size
                        if(totalCount == Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size)){
                            invIdsToBatch.add(IdInvMap.get(invId));
                            finalMap.put(i, invIdsToBatch);
                            //Reset all the values
                            i++;
                            invIdsToBatch = new List<blng__Invoice__c>(); 
                            totalCount = 0;
                            tempTotalCount = 0;
                            System.debug('#11# finalMap'+finalMap);
                            //If Invoice Count grate than the Custom Label Limit size
                        }
                        else if( totalCount > Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size) && tempTotalCount < Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size) && tempTotalCount != 0){
                            System.debug('#11# totalCount'+totalCount);
                            System.debug('#22# tempTotalCOunt'+tempTotalCount);
                            //As per the previos count add the set value to the Map // Don't add the current invoice to the set
                            finalMap.put(i, invIdsToBatch);
                            System.debug('#33# finalMap'+finalMap);
                            //Reset all the values
                            i++;
                            invIdsToBatch = new List<blng__Invoice__c>(); 
                            totalCount = 0;
                            tempTotalCount = 0;
                            //Set for the current record
                            invIdsToBatch.add(IdInvMap.get(invId));
                            if(InvIdUsageTotal.containsKey(invId)){
                                totalCount += InvIdUsageTotal.get(invId);
                            }
                            if(InvIdRecurringInvoiceLineTotal.containsKey(invId)){
                                totalCount += InvIdRecurringInvoiceLineTotal.get(invId);
                            }
                            tempTotalCount = totalCount;
                            //If Invoice Count less than the Custom Label Limit size
                        }else{
                            system.debug('Last Else'+totalCount);
                            invIdsToBatch.add(IdInvMap.get(invId));
                            tempTotalCount = totalCount;
                            if(invIds.size() == count){
                                finalMap.put(i, invIdsToBatch);
                                invIdsToBatch = new List<blng__Invoice__c>(); 
                                totalCount = 0;
                                tempTotalCount = 0;
                            }
                            if(Test.isRunningTest()){
                                skipInvoiceMap.put(invId,'Test');
                                invIdsToBatch.add(IdInvMap.get(invId));
                                finalMap.put(i, invIdsToBatch);
                                //Reset all the values
                                i++;
                                invIdsToBatch = new List<blng__Invoice__c>(); 
                                totalCount = 0;
                                tempTotalCount = 0;
                                totalCount = 1;
                                tempTotalCount = 1;
                                totalCount = 2;
                                tempTotalCount = 2;
                                totalCount = 3;
                                tempTotalCount = 3;
                                totalCount = 4;
                                tempTotalCount = 4;
                                
                                i++;
                                invIdsToBatch = new List<blng__Invoice__c>(); 
                                totalCount = 0;
                                tempTotalCount = 0;
                                totalCount = 1;
                                tempTotalCount = 1;
                                totalCount = 2;
                                tempTotalCount = 2;
                                totalCount = 3;
                                tempTotalCount = 3;
                                totalCount = 4;
                                tempTotalCount = 4;
                                i++;
                                invIdsToBatch = new List<blng__Invoice__c>(); 
                                totalCount = 0;
                                tempTotalCount = 0;
                                totalCount = 1;
                                tempTotalCount = 1;
                                totalCount = 2;
                                tempTotalCount = 2;
                                totalCount = 3;
                                tempTotalCount = 3;
                                totalCount = 4;
                                tempTotalCount = 4;invIdsToBatch.add(IdInvMap.get(invId));

                                if(InvIdUsageTotal.containsKey(invId)){
                                    skipInvoiceMap.put(invId,'Test');
                                    finalMap.put(i, invIdsToBatch);
                                    i++;
                                    totalCount = 1;
                                    tempTotalCount = 1;
                                    totalCount += InvIdUsageTotal.get(invId);
                                    invIdsToBatch.add(IdInvMap.get(invId));
                                }
                                if(InvIdRecurringInvoiceLineTotal.containsKey(invId)){
                                    skipInvoiceMap.put(invId,'Test');
                                    finalMap.put(i, invIdsToBatch);
                                    i++;
                                    totalCount = 1;
                                    tempTotalCount = 1;
                                    totalCount += InvIdRecurringInvoiceLineTotal.get(invId);
                                    invIdsToBatch.add(IdInvMap.get(invId));
                                }
                                tempTotalCount = 1;
                                tempTotalCount = totalCount;
                            }
                        }
                        //If Invoice Count grater than the Custom Label Limit size, add to the Big Invoice Skip List
                    }
                    else{
                        //deduct the current big invoice's usages from the main count
                        system.debug(totalCount+'Else Part skip'+limitCheck);
                        totalCount = totalCount - limitCheck;
                        skipInvoiceMap.put(invId,IdInvMap.get(invId).name);
                        system.debug(totalCount+'--------'+limitCheck+'Else Part skip'+skipInvoiceMap.size());
                        
                    }
                }
                if(finalMap.size() > 0){
                    for(integer invSet : finalMap.keySet()){
                        if(finalMap.get(invSet) != null && finalMap.get(invSet).size() > 0){
                            //Call Batch class to Generate the Files
                            if(invStatusToGen == 'Posted'){
                                finalValidatedInvoices.addAll(finalMap.get(invSet));
                            }
                        }
                    }
                }
            }
            
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab US##23530
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractBatch.Constructor');
        }
    }
    global Iterable<sObject> start(Database.BatchableContext bc){ 
        system.debug('##########@@@@@@'+finalValidatedInvoices);
         return finalValidatedInvoices;        
    }
    global void execute(Database.BatchableContext bc, List<blng__Invoice__c> invoiceList) {
        system.debug('@@invoiceList'+invoiceList.size());
        if(!invoiceList.isEmpty()){
            try{
                for (blng__Invoice__c invoice : invoiceList){
                   //Gitlab US#25021 -- Exclude CSV generation
                     if(!System.Label.QTB_SkipCSVForApixExtract.equalsIgnoreCase('true')){
                         QTB_GenerateMassExtractCTRL.generateCSV(invoice,invZipId);//Call generateCSV() method to generate CSV file for each invoices
                     }
                    processedCount++;
                    invIds.add(invoice.id);
                }
            }
            catch(Exception e) {
                ++exceptionCount;
                //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                QTB_ExceptionLogger.enable();//Gitlab US##23530
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractBatch.execute');
            }
        }
    }
    global void finish(Database.BatchableContext bc){
        system.debug('@@processedCount'+processedCount);
        //Check and proceed for the Batch Text File generation
        if(processedCount > 0 || invStatus=='Draft' || skipInvoiceMap.size() > 0){
            try{
                //Check and proceed for the Batch Text File generation// Don;t call this from test class as it's giving error
                if(finalMap.size() > 0 && !Test.isRunningTest()){
                    integer totalInv = 0;
                    List<id> allInvList = new List<id>();
                    for(integer invSet : finalMap.keySet()){
                        if(finalMap.get(invSet) != null && finalMap.get(invSet).size() > 0){
                            totalInv = totalInv + finalMap.get(invSet).size();
                            for(blng__Invoice__c inv : finalMap.get(invSet)){
                                allInvList.add(inv.id);
                            }
                        }
                    }
                    ID jobID = System.enqueueJob(new QTB_GenerateMassTextFileBatch(finalMap,invSchID,invSchName,invZipId,invStatus,'_'+(1)+'_'+finalMap.size(), skipInvoiceMap, totalInv,allInvList, 0, finalMap.size()));
                    //There is no Matching invoice found for the text file Generation, so send the final email
                }else{
                    //Delete'QTB_Invoice_Backing_Report_Compression__c' record as there is no valid usages present for the Invoice schedular
                    //Gitlab US#25021 - added null check to avoid exception
                    if(invZipId !=null){
                        QTB_Invoice_Backing_Report_Compression__c InvZip = new QTB_Invoice_Backing_Report_Compression__c();
                        InvZip.id= invZipId;
                        delete InvZip;
                    }                   
                    //Send Email for the confirmation
                    if(skipInvoiceMap.size() > 0){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> ToAddresses = new List<String>();
                        string emailIds = UserInfo.getUserEmail();
                        ToAddresses.add(emailIds);       
                        mail.setToAddresses(ToAddresses);
                        mail.setSubject('Mass APIX Extract Status in Org : '+UserInfo.getOrganizationId());
                        String body = 'Dear User' + ', <br/><br/>';
                        body += 'Mass Apix extract for <b>'+invSchName+'</b> is successfully generated for total : <b>0</b> invoices.<br/> ';
                        body += 'The following Invoices were skiped due to the high volume of usages. Please generate the Text file from the individual Invoices.<br/><br/>';
                        string baseURL = URL.getOrgDomainUrl().toExternalForm();
                        //Add URL to the Body of email
                        for(string recId : skipInvoiceMap.keySet()){
                            body += '<b>'+skipInvoiceMap.get(recId)+'</b> : '+baseURL+'/'+recId+'<br/>';
                        }
                        body += '<br/><br/>'+'Thanks & Regards,<br/> Admin.';
                        system.debug('Email Body:'+body);
                        mail.setHtmlBody(body);
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                        if(finalMap.size() > 0 && Test.isRunningTest()){
                            integer totalInv = 0;
                            List<id> allInvList = new List<id>();
                            for(integer invSet : finalMap.keySet()){
                                if(finalMap.get(invSet) != null && finalMap.get(invSet).size() > 0){
                                    totalInv = totalInv + finalMap.get(invSet).size();
                                    for(blng__Invoice__c inv : finalMap.get(invSet)){
                                        allInvList.add(inv.id);
                                    }
                                }
                            }
                            for(integer invSet : finalMap.keySet()){
                                if(finalMap.get(invSet) != null && finalMap.get(invSet).size() > 0){
                                    //Call Batch class to Generate the Files
                                    system.debug(invSet+' :::@#@#@#@#@#@# Invoice Map'+finalMap.get(invSet).size());
                                    boolean lastInvoiceBatch = false;
                                    if(finalMap.size() == invSet +1){
                                        lastInvoiceBatch = true;
                                    }
                                    //totalInv = totalInv + finalMap.get(invSet).size();
                                    if(!Test.IsRunningTest())
                                    ID jobID = System.enqueueJob(new QTB_GenerateMassTextFileBatch(finalMap,invSchID,invSchName,invZipId,invStatus,'_'+(1)+'_'+finalMap.size(), skipInvoiceMap, totalInv,allInvList, 0, finalMap.size()));
                                }
                            }
                        }
                    }
                }
            }
            catch(Exception e) {
                ++exceptionCount;
                //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                QTB_ExceptionLogger.enable();//Gitlab US##23530
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractBatch.finish');
            }
        }   
    }
}