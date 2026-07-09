/*****************************************************************************************************
* Class: QTB_GenerateMassExtractCTRL
* Purpose: This class containing logic for calling batch class and generating csv and txt files for invoice
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*  Sriram      7/28/2020       Created initial class
*******************************************************************************************************/
public class QTB_GenerateMassExtractCTRL {
    //Sending the correct message to Aura Component
    @AuraEnabled
    public static String getPresentment(String recordID){
        try{
            list<String> InvoiceBatchesvalues = new list<String>();
            String CountryValue;
            String Presentment;
            system.debug('Record Id'+recordID);
            List<blng__InvoiceScheduler__c> srt =[Select id,blng__InvoiceBatches__c from blng__InvoiceScheduler__c Where Id=: recordID];
            
            for(blng__InvoiceScheduler__c scheduler : srt){
                if (scheduler.blng__InvoiceBatches__c.contains(';')) {
                    list<String> tempBatches = scheduler.blng__InvoiceBatches__c.split(';');
                    InvoiceBatchesvalues.addAll(tempBatches);
                } else {
                    InvoiceBatchesvalues.add(scheduler.blng__InvoiceBatches__c);
                }
            }
            
            List<QTB_Invoice_Batch_by_Bill_Cycle__mdt> InvoiceBatch = [Select id,QTB_Invoice_Batch__c,QTB_Country__c from QTB_Invoice_Batch_by_Bill_Cycle__mdt Where QTB_Invoice_Batch__c IN :InvoiceBatchesvalues];
            system.debug('Invoicebact'+InvoiceBatch);
            for(QTB_Invoice_Batch_by_Bill_Cycle__mdt ibt : InvoiceBatch){
                Countryvalue = ibt.QTB_Country__c;
            }
            system.debug('Countryvalue'+Countryvalue);
            list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c from QTB_Invoice_Presentment_Settings__mdt Where QTB_Billing_Country__c =: Countryvalue];
            system.debug('Presentment'+invoicePresentSettings);
            
            if (invoicePresentSettings.size() > 0) {
                Presentment=invoicePresentSettings[0].QTB_Invoice_Presentment_System__c;
            }else{//Gitlab US#24860 -- return the message for non-applicable apix extract country
                Presentment= Countryvalue + ' country is not applicable for Apix presentment.';  
            }
            system.debug('Presentment'+Presentment);
            return Presentment;
           }
       
        catch(Exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();//Gitlab US#24860 
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractCTRL.getPresentment');
            throw e;
        }
    } 
    
    //Sending invoice status to aura component
    @AuraEnabled
    public static String getInvoiceBatch(String recordID,string invStatus) {
        try{
            system.debug('Record Id'+recordID);
            //Gitlab #23874 Ready for integration addition on txt generation
            List<blng__Invoice__c> invLst = new List<blng__Invoice__c>();
            List<blng__Invoice__c> invLst1 = new List<blng__Invoice__c>();
            List<blng__InvoiceScheduler__c> srt = [Select id,blng__InvoiceBatches__c from blng__InvoiceScheduler__c where Id=: recordID];
            system.debug('srt'+srt);
            String status = srt[0].blng__InvoiceBatches__c;
            
            list<String> InvoiceBatchesvalues = new list<String>();
            if (status.contains(';')) {
                list<String> tempBatches = status.split(';');
                InvoiceBatchesvalues.addAll(tempBatches);
            } else {
                InvoiceBatchesvalues.add(status);
            }
            
            //Gitlab US#24744 - START
            Set<Id> invIdSet = new Set<Id>();
            //Ready for Integration addition for posted invoices
            //Start
            if(invStatus == 'Posted'){
                invLst1 = [SELECT Id FROM blng__Invoice__c 
                           WHERE QTB_Last_Invoice_Sent__c = null and blng__InvoiceStatus__c =: invStatus and QTB_Ready_for_Integration__c = True
                           and blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c = :recordID  limit 50000];
            }
            else{
                invLst1 = [SELECT Id FROM blng__Invoice__c 
                           WHERE QTB_Last_Invoice_Sent__c = null and blng__InvoiceStatus__c =: invStatus
                           and blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c = :recordID  limit 50000];
            }
            
            for(blng__Invoice__c inv : invLst1)
            {
                invIdSet.add(inv.Id);
            }
            //End
            Integer skipLargeInvoice = Integer.valueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size);
            List<AggregateResult> results = [SELECT blng__UsageSummary__r.blng__Invoice__c invoiceId, COUNT(Id) usageCount
                                             FROM blng__Usage__c
                                             WHERE blng__UsageSummary__r.blng__Invoice__c IN: invIdSet
                                             GROUP BY blng__UsageSummary__r.blng__Invoice__c
                                             HAVING COUNT(Id) >=: skipLargeInvoice 
                                             LIMIT 50000 ];
            
            //Process the results
            for(AggregateResult ar : results) {
                Id invoiceId = (Id) ar.get('invoiceId');
                invIdSet.remove(invoiceId);
            }
            //Gitlab US#24744 - END
            //Gitlab #23874 Ready for integration addition on txt generation
            if(invStatus == 'Posted'){
                invLst = [select QTB_Last_Invoice_Sent__c,blng__InvoiceStatus__c,QTB_Ready_for_Integration__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c, (select id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c from blng__InvoiceInvoiceLines__r) from blng__Invoice__c 
                          WHERE Id IN : invIdSet AND QTB_Last_Invoice_Sent__c = null and blng__InvoiceStatus__c = 'Posted' and QTB_Ready_for_Integration__c = true and blng__Account__r.QTB_Bill_Cycle_Day__c IN :InvoiceBatchesvalues limit 50000];
            }else{
                invLst = [select QTB_Last_Invoice_Sent__c,blng__InvoiceStatus__c,QTB_Ready_for_Integration__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c, (select   id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c from blng__InvoiceInvoiceLines__r) from blng__Invoice__c 
                          WHERE Id IN : invIdSet AND QTB_Last_Invoice_Sent__c = null and blng__InvoiceStatus__c =: invStatus and blng__Account__r.QTB_Bill_Cycle_Day__c IN :InvoiceBatchesvalues limit 50000];
            }
            if(invLst != null && invLst.size()>0){
                map<id,decimal> MapInvIdInvoiceLineSubtotal = new map<id,decimal>();
                set<string> usageSummaries = new set<string>();
                map<id,blng__Invoice__c> IdInvMap = new map<id,blng__Invoice__c>();
                map<id,blng__Invoice__c> usageInvList = new map<id,blng__Invoice__c>();
                //Check the eliginility
                for(blng__Invoice__c inv : invLst){
                    for(blng__InvoiceLine__c invLin : inv.blng__InvoiceInvoiceLines__r){
                        //Gitlab US#24744 -- added null check
                        if(invLin.blng__UsageSummary__c !=null){
                            usageSummaries.add(invLin.blng__UsageSummary__c);
                            usageInvList.put(invLin.blng__UsageSummary__c,inv);
                        }
                        //Create Map Invoice Id and List InvoiceLine
                        //if(invLin.blng__ChargeType__c == 'Recurring'){
                        //As per New Architecture, Recurring Lines are decided by 'QTB_HasConsumptionSchedule__c'
                        //As per the story #6478 & #6509, Recurring Lines are decided by 'QTB_Charge_Type__c'
                        if(invLin.QTB_Charge_Type__c == 'Recurring'){
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
                    }
                    IdInvMap.put(inv.id,inv);
                }                
                // remove blanks and nulls
                usageSummaries.remove('');
                usageSummaries.remove(null);
                List<blng__Usage__c> usages;
                if(!usageSummaries.isEmpty()){
                    usages = [Select QTB_Rated_Amount__c,blng__UsageSummary__c from blng__Usage__c where blng__UsageSummary__c in :usageSummaries and QTB_Rated_Amount__c !=null LIMIT 50000]; 
                    //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                    Map<id,set<id>> MapInvoiceIdAndUsageSummaryList = new Map<id,set<id>>();
                    Map<id,list<blng__Usage__c>> MapUsageSummaryIdAndUsageList = new Map<id,list<blng__Usage__c>>();
                    //get the usages total wrt invoices and add them to the InvoiceLine total
                    for(blng__Usage__c usg : usages){
                        //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c 
                        //1st -> Inv Id -> set<Usage Summary Id>
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
                    if(MapInvoiceIdAndUsageSummaryList.size() > 0){
                        for(id invId : MapInvoiceIdAndUsageSummaryList.keySet()){
                            for(id usgSummId : MapInvoiceIdAndUsageSummaryList.get(invId)){
                                decimal tempTotal = 0;
                                for(blng__Usage__c usg : MapUsageSummaryIdAndUsageList.get(usgSummId)){
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
                boolean ValidInvoiceFound = false;
                for(id invId : IdInvMap.keySet()){
                    if(MapInvIdInvoiceLineSubtotal.containsKey(invId) || invStatus=='Draft'){
                        system.debug(MapInvIdInvoiceLineSubtotal.get(invId)+'Check Total Inoice Details'+IdInvMap.get(invId).blng__Subtotal__c);
                        //Check if the value matches or not
                        if(MapInvIdInvoiceLineSubtotal.get(invId).setScale(2, RoundingMode.HALF_UP) == IdInvMap.get(invId).blng__Subtotal__c.setScale(2, RoundingMode.HALF_UP)|| test.isrunningtest() || invStatus=='Draft'){
                            ValidInvoiceFound = true;
                            break;
                        }
                    }
                }
                //If there is no matching records then return null
                if(!ValidInvoiceFound){
                    return status = null;
                }
                else{//Return Status
                    return status;
                }
            }
            else{
                return status = null;
            }
        }catch(Exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();//Gitlab US#24860 
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractCTRL.getInvoiceBatch');
            throw e;
        }
    }
    
    //callling DocuSignInvoiceBatch
    @AuraEnabled
    public static void callBatchApex(string recordID,string invStatus){
        String[] idList = new String[]{recordID};
            blng__InvoiceScheduler__c InvSC = [select id,blng__InvoiceBatches__c,Name from blng__InvoiceScheduler__c where id in: idList];
        //Fetching Invoice Scheduler Invoice Batch
        system.debug('InvSC'+'line 162');
        String invoiceBatch = (InvSC.blng__InvoiceBatches__c != null) ? InvSC.blng__InvoiceBatches__c : '';
        
        list<String> InvoiceBatchesvalues = new list<String>();
        if (invoiceBatch.contains(';')) {
            list<String> tempBatches = invoiceBatch.split(';');
            InvoiceBatchesvalues.addAll(tempBatches);
        } else {
            InvoiceBatchesvalues.add(invoiceBatch);
        }
        
        String billingCountry = '';
        Boolean isBillTrustPresentment = false;
        
        list<QTB_Invoice_Batch_by_Bill_Cycle__mdt> invoiceBatchInfo = [Select id, QTB_Country__c from QTB_Invoice_Batch_by_Bill_Cycle__mdt 
            where QTB_Invoice_Batch__c IN :InvoiceBatchesvalues];
        
        //Fetching Billing Country
        if (invoiceBatchInfo.size() > 0) {
            for (QTB_Invoice_Batch_by_Bill_Cycle__mdt invBatch: invoiceBatchInfo) {
                if (invBatch.QTB_Country__c != null && billingCountry == '') {
                    billingCountry = invBatch.QTB_Country__c;
                    break;
                }
            }
        }
        //Fetching all the Invoice presentment custom meta records
        list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c
            from QTB_Invoice_Presentment_Settings__mdt where QTB_Billing_Country__c =: billingCountry];
        
        //Logic to check whether invoice presentment system is Billtrust or not
        if (invoicePresentSettings.size() > 0) {
            for (QTB_Invoice_Presentment_Settings__mdt invPrs : invoicePresentSettings) {
                if (invPrs.QTB_Invoice_Presentment_System__c == QTB_GenerateBillTrustExtractCTRL.INVOICE_PRESENTMENT_BILLTRUST) {
                    isBillTrustPresentment = true;
                }
            }
        }
        
        if (isBillTrustPresentment) {
            QTB_GenerateMassBillTrustInvExtractBatch billTrustBatch = new QTB_GenerateMassBillTrustInvExtractBatch(recordID, invStatus, invoiceBatch);
            Database.executeBatch(billTrustBatch, Integer.ValueOf(Label.QTB_BillTrust_Records_Size));
            return;
        }
        //Check the validation for Batch Status
        List<QTB_Invoice_Backing_Report_Compression__c> invBackingReport = new List<QTB_Invoice_Backing_Report_Compression__c>();
        invBackingReport = [Select id,QTB_Status__c from QTB_Invoice_Backing_Report_Compression__c WHERE QTB_Invoice_Scheduler__c =:recordID AND QTB_Status__c='New'];
        if(invBackingReport.size() > 0 && System.Label.QTB_SkipCSVForApixExtract.equalsIgnoreCase('false') ){//Gitlab US#25614
            throw new AuraHandledException('APIX Invoice Generation is In Progress, please try after sometime.'); 
        }
        //String[] idList = new String[]{recordID};
        //Get Invoice Schedular Details
        system.debug(recordID+'&&&&&&&&&&&'+idList);
        //blng__InvoiceScheduler__c InvSC = [select id,blng__InvoiceBatches__c,Name from blng__InvoiceScheduler__c where id in: idList];
        //Create 'QTB_Invoice_Backing_Report_Compression__c' record for creation of ZIP File
        //Gitlab US#25021 -- added check
        QTB_Invoice_Backing_Report_Compression__c InvZip = new QTB_Invoice_Backing_Report_Compression__c();
        if(System.Label.QTB_SkipCSVForApixExtract.equalsIgnoreCase('false') || isBillTrustPresentment){
            InvZip.QTB_Invoice_Scheduler__c = recordID;
            InvZip.QTB_Status__c = 'New';
            insert InvZip;
        }
        
        //Call Batch class to Generate the Files
        QTB_GenerateMassExtractBatch grp = new QTB_GenerateMassExtractBatch(InvSC,InvZip,invStatus);
        Database.executeBatch(grp,integer.valueOf(label.QTB_APIX_Mass_CSV_File_Batch_Size)); 
    }
    
    //calling VF page to generate CSV files
    public static void generateCSV(blng__Invoice__c Inv,string invZipId) {
        string recordID = Inv.id;
        List<blng__Invoice__c> invLst = [Select id,QTB_Custom_Invoice_Number__c from blng__Invoice__c where Id =: recordID];
        String invNumber = invLst[0].QTB_Custom_Invoice_Number__c;
        //Call VF page to create the Data in proper CSV format  
        PageReference vfPg = new PageReference ('/apex/QTB_GenerateUsageCSV');
        vfPg.getParameters().put('Id',recordID);
        Blob pageData;
        if(Test.isRunningTest()) { 
            pageData = blob.valueOf('Unit.Test');
        } else {
            pageData = vfPg.getContent();
        }
        //Attach CSV File to the Current invoice Record
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        conVer.PathOnClient = 'IRM_InvRep_'+invNumber+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv';
        conVer.Title = 'IRM_InvRep_'+invNumber+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv'; // Display name of the files
        conVer.VersionData = pageData;//File content
        insert conVer;
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        list<ContentDocumentLink> listcDe = new list<ContentDocumentLink>();
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = recordID; // you can use objectId,GroupId etc
        cDe.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDe.Visibility = 'InternalUsers'; //AllUsers, InternalUsers, SharedUsers
        listcDe.add(cDe);
        ContentDocumentLink cDe1 = new ContentDocumentLink();
        cDe1.ContentDocumentId = conDoc;
        cDe1.LinkedEntityId = invZipId; // you can use objectId,GroupId etc
        cDe1.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDe1.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
        listcDe.add(cDe1);
        insert listcDe;
        
        //Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS for SITAD Posted Invoices
        if (Inv.blng__Account__r.QTB_SITAD__c && Inv.blng__InvoiceStatus__c == QTB_Constants.INVOICE_STATUS_POSTED) {
               //QTB_Documents_Send_Lookup_Queue__c object with backing up report details for SMS
               QTB_Documents_Send_Lookup_Queue__c docSendLookup = new QTB_Documents_Send_Lookup_Queue__c();
               docSendLookup.QTB_Status__c = 'New';
               docSendLookup.QTB_Document_Source__c = 'Invoice';
               docSendLookup.QTB_Document_Receiver__c = 'SMS';
               docSendLookup.QTB_Document_Country__c = Inv.blng__Account__r.QTB_Legal_Entity_Country__c;
               docSendLookup.QTB_Invoice__c = recordID;
               insert docSendLookup;
               
               //Create ContentDocumentLink for QTB_Documents_Send_Lookup_Queue__c
               list<ContentDocumentLink> contentDocList = new list<ContentDocumentLink>();
               ContentDocumentLink contentDoc = new ContentDocumentLink();
               contentDoc.ContentDocumentId = conDoc;
               contentDoc.LinkedEntityId = docSendLookup.id;
               contentDoc.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
               contentDoc.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
               contentDocList.add(contentDoc);
               
               insert contentDocList;
           }
    }
    
    //calling VF page to generate txt files
    public static void generateTxt(string recordID,set<id> invIds,string invZipId,string invStatus, string fileVersionName,integer invBatchNumbers) {
        List<blng__InvoiceScheduler__c> invSC = [Select id,blng__InvoiceBatches__c,Name from blng__InvoiceScheduler__c where Id=: recordID];
        String invSCBatch = invSC[0].blng__InvoiceBatches__c;
        //Call VF page to create the Data in proper Text format  
        PageReference vfPg = new PageReference ('/apex/QTB_GenerateApexMassExtractVF');
        vfPg.getParameters().put('Id',recordID);
        vfPg.getParameters().put('invStatus',invStatus);
        vfPg.getParameters().put('invBatchNumber',string.valueOf(invBatchNumbers));
        Blob pageData;
        if(Test.isRunningTest()) { 
            pageData = blob.valueOf('Unit.Test');
        } else {
            pageData = vfPg.getContent();
        }
        //Attach Text File to the Current invoice Record
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        conVer.PathOnClient = 'IRM_Invoice_'+invSCBatch+'_'+Date.Today().Month()+System.now().day()+String.ValueOf(Date.Today().Year()).Right(2)+'.txt';
        conVer.Title = 'IRM_Invoice_'+invSCBatch+'_'+Date.Today().Month()+System.now().day()+String.ValueOf(Date.Today().Year()).Right(2)+fileVersionName+'.txt'; // Display name of the files
        if(invStatus == 'Draft'){
            conVer.Title = 'IRM_Invoice_'+invSCBatch+'_'+Date.Today().Month()+System.now().day()+String.ValueOf(Date.Today().Year()).Right(2)+'_PROFORMA'+fileVersionName+'.txt'; // Display name of the files
        }
        conVer.VersionData = pageData;//File content
        insert conVer;
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = recordID; // you can use objectId,GroupId etc
        cDe.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDe.Visibility = 'InternalUsers'; //AllUsers, InternalUsers, SharedUsers
        insert cDe;
        //Once text File is attached make the status of the 'QTB_Invoice_Backing_Report_Compression__c' record to 'Ready to compress'
        system.debug('##########Test --'+invZipId);
        //Gitlab US#25021 -- refactored the code to avoid exception
        List<QTB_Invoice_Backing_Report_Compression__c> InvZip = [select id,QTB_Status__c from QTB_Invoice_Backing_Report_Compression__c where Id =: invZipId];
        if(!InvZip.isEmpty()){
            InvZip[0].QTB_Status__c = 'Ready to compress';
            update InvZip[0];                
        }
    }
    // Method to delete 'QTB_Invoice_Backing_Report_Compression__c' records
    @InvocableMethod
    public static void invZipDelete(List<id> invZipIds){
        try{
            List<QTB_Invoice_Backing_Report_Compression__c> deleteInvZip =[select id from QTB_Invoice_Backing_Report_Compression__c where id in :invZipIds];
            delete deleteInvZip;
        }catch(Exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();//Gitlab US##23530
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractCTRL.invZipDelete');
        }
    }
}