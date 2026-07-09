/*****************************************************************************************************
 * Class: QTB_sendPONotificationBatch
 * Author: IRM
 * Purpose: This is a Batch class for sending email notifications based on PO balance.
 * Requirement: Gitlab #1669, Refactored for #31454
 * Change History:
 * Developer       Date            Description
 * -------------------------------------------------------------------------------------------
 * Gopinandan      12/06/2021      Initial Version
 * Chetan Kumar    07/07/2025      Refactored to use QTB_PurchaseOrderAccount__c junction object
 *******************************************************************************************************/

public class QTB_sendPONotificationBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    public static Integer emailCounter = 0;
    public static Integer emailCount = 0;
    public static final String ACTIVE = QTB_Constants.ACTIVE;
    public static final String ACTIVATED = QTB_Constants.ACTIVE;
    public static final String STATUS_POSTED = QTB_Constants.INVOICE_STATUS_POSTED;
    public static final String ROLE_PO_CONTACT = 'PO Contact';
    public static Integer messagecount = 0;
    public static Integer messagecounter = 0;
    public List<Id> POIdList = new List<Id>();
    public Map<string,QTB_PO_Email_Notification__mdt> POTemplateNotificationMap = new Map<string,QTB_PO_Email_Notification__mdt>();
    // #20826 Created map of country and Boolean Value
    public Map<string,Boolean> poWithMultipleLegalEntitiesMap = new map<string,Boolean>();
    
    public QTB_sendPONotificationBatch(List<Id> POIds){
        if(POIds != null){
            POIdList.AddAll(POIds);
            //Get all the Metadata records where key is the Country and Account Language
            //Gitlab 20826 Queried QTB_Legal_Entity_Number__c field which is newly created
            for(QTB_PO_Email_Notification__mdt mdt : [SELECT id,
                                                      QTB_100_Utilization_Template__c,
                                                      QTB_50_Utilization_Template__c,
                                                      QTB_75_Utilization_Template__c,
                                                      QTB_90_Utilization_Template__c,
                                                      QTB_After_Expiring_Template__c,
                                                      QTB_Before_Expiring_Template__c,
                                                      QTB_Country__c,
                                                      QTB_Email_Subject__c,
                                                      QTB_From_Address__c,
                                                      QTB_Language__c,
                                                      QTB_Legal_Entity_Number__c
                                                      FROM 
                                                      QTB_PO_Email_Notification__mdt]){
                // #20826 Added if else condition for Legal Entity Number check and adding the respective legal entity Number
                // In else condition Added None for Legal Entity not equals to Null
                if(mdt.QTB_Legal_Entity_Number__c != Null){
                    POTemplateNotificationMap.put(mdt.QTB_Country__c + mdt.QTB_Language__c+ mdt.QTB_Legal_Entity_Number__c, mdt);
                    poWithMultipleLegalEntitiesMap.put(mdt.QTB_Country__c,True);
                }
                else
                {
                    POTemplateNotificationMap.put(mdt.QTB_Country__c + mdt.QTB_Language__c+ 'None', mdt);
                    poWithMultipleLegalEntitiesMap.put(mdt.QTB_Country__c,False);
                }
            }
        }
    }
    /*********************************************************************************************************
     * Method Name: start
     * Parameters: Database.BatchableContext
     * Return Type: Database.QueryLocator
     * Requirement: Gitlab #1669
     * Description: Query PO required records
    ---------------------------------------------------------------------
         * Chetan Kumar 07/07/2025    Updated to remove dependency on QTB_Billing_Account__c and use junction object QTB_PurchaseOrderAccount__c
     * Requirement: Gitlab #31454
     * Description: Query PO records based on expiry/utilization window
     **********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        //Fetching all the eligible Purchase Order's
        //Gitlab 20826 Queried Legal Entity  Number field from Account level
        // String query =
        //     'SELECT id, Name, QTB_Amount__c, QTB_Billing_Account__c,QTB_Billing_Account__r.QTB_Language__c,QTB_Billing_Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,'+
        //     ' QTB_Status__c, QTB_End_Date__c, QTB_Start_Date__c,QTB_Billing_Account__r.Name,' +
        //     ' QTB_PO_Balance_Amount__c,QTB_Legal_Entity_Country__c,QTB_50_Utilization_Email_Sent__c,QTB_75_Utilization_Email_Sent__c,'+
        //     ' QTB_90_Utilization_Email_Sent__c,QTB_100_Utilization_Email_Sent__c,QTB_Customer_PO__c FROM QTB_PurchaseOrder__c ' +
        //     ' WHERE Id IN:POIdList ';
        
        String query =
            'SELECT id, Name, QTB_Amount__c,'+
            ' QTB_Status__c, QTB_End_Date__c, QTB_Start_Date__c,' +
            ' QTB_PO_Balance_Amount__c,QTB_Legal_Entity_Country__c,QTB_50_Utilization_Email_Sent__c,QTB_75_Utilization_Email_Sent__c,'+
            ' QTB_90_Utilization_Email_Sent__c,QTB_100_Utilization_Email_Sent__c,QTB_Customer_PO__c FROM QTB_PurchaseOrder__c ' +
            ' WHERE Id IN:POIdList ';
        
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
     * Method Name: execute
     * Parameters: Database.BatchableContext,List<SObject>
     * Return Type: void
     * Requirement: Gitlab #1669
    --------------------------------------------------------------------
         * Chetan Kumar 07/07/2025    Updated to remove dependency on QTB_Billing_Account__c and use junction object QTB_PurchaseOrderAccount__c
     * Requirement: Gitlab #31454
     **********************************************************************************************************/
    /** public void execute(Database.BatchableContext bc, list<QTB_PurchaseOrder__c> scope)
    {
        //Variables declaration
        // List<id> accId = new List<id>();
        Map<id,List<id>> AccountIdPOContactEmailMap = new Map<id,List<id>>();
        List<Messaging.SingleEmailMessage> utilizationEmailList = new List<Messaging.SingleEmailMessage>();
        List<string> emailTemplateName = new List<string>();
        List<string> orgWideEmailAddressList = new List<string>();
        Map<string,id> emailTemplateNameIdMap = new Map<string,id>();
        Map<string,string> orgWideEmailAddressMap = new Map<string,id>();
        Map<Id,List<QTB_PurchaseOrder__c>> futurePOsMap = new Map<Id,List<QTB_PurchaseOrder__c>>();
        Map<id,QTB_PurchaseOrder__c> MapPOEmailSentUpdate = new Map<id,QTB_PurchaseOrder__c>();
        
        // Variables declaration for Gitlab #31454
        Set<Id> poIds = new Set<Id>();
        Map<Id, List<Id>> poToAccountIdsMap = new Map<Id, List<Id>>();
        Set<Id> accId = new Set<Id>();
        
        //30 days after and 60 days after should send email in other Daily Batch
        //http://amitsalesforce.blogspot.com/2015/11/singleemailmessage-vs-massemailmessage.html
        try {
            for (QTB_PurchaseOrder__c po: scope) {
                system.debug('@#@#11'+POTemplateNotificationMap);
                system.debug('@#@#'+po.QTB_Legal_Entity_Country__c+po.QTB_Billing_Account__r.QTB_Language__c);
                system.debug('#########@@'+POTemplateNotificationMap.containsKey(po.QTB_Legal_Entity_Country__c+po.QTB_Billing_Account__r.QTB_Language__c));
                // #20826 Added the below logic for converting the Legal Entity Number double Data type to Text data type and checking the legal Entity present meta data countries
                // Creating a stringVariable for conversion of double data type to String datatype and remove ".0" combination from that string
                String legalEntitynumber = 'None';
                if(poWithMultipleLegalEntitiesMap.get(po.QTB_Legal_Entity_Country__c) == True){
                    if(po.QTB_Billing_Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c != null){
                        legalEntitynumber = String.valueOf(po.QTB_Billing_Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c);
                        if(legalEntitynumber.contains('.')){
                            legalEntitynumber = legalEntitynumber.replace('.0','');
                        }
                    }
                }
                system.debug('#########@@'+POTemplateNotificationMap.containsKey(po.QTB_Legal_Entity_Country__c+po.QTB_Billing_Account__r.QTB_Language__c+legalEntitynumber));
                //Check if the Account Language and Country wise if the Metadata records got created or not?
                //  #20826 Added Legal Entity Number field in containsKey Function
                if(POTemplateNotificationMap.containsKey(po.QTB_Legal_Entity_Country__c+po.QTB_Billing_Account__r.QTB_Language__c+legalEntitynumber)){
                    system.debug('#########1212');
                    //  #20826 Added Legal Entity Number field in the get function
                    QTB_PO_Email_Notification__mdt POMetaData = POTemplateNotificationMap.get(po.QTB_Legal_Entity_Country__c + po.QTB_Billing_Account__r.QTB_Language__c + legalEntitynumber);
                    //Add all those email Template Name to a List
                    emailTemplateName.add(POMetaData.QTB_100_Utilization_Template__c);
                    emailTemplateName.add(POMetaData.QTB_50_Utilization_Template__c);
                    emailTemplateName.add(POMetaData.QTB_75_Utilization_Template__c);
                    emailTemplateName.add(POMetaData.QTB_90_Utilization_Template__c);
                    //Set Org Wide email address
                    orgWideEmailAddressList.add(POMetaData.QTB_From_Address__c);
                    //Add only those Account for which the templates are available
                    accId.add(po.QTB_Billing_Account__c);
                }
            }
            //Get all the PO related to the current PO's Billing Account to check if any a Future date PO with condition as 'Amount > 0' is present or not?
            for(QTB_PurchaseOrder__c po : [SELECT id,QTB_Billing_Account__c,QTB_Start_Date__c,QTB_End_Date__c from QTB_PurchaseOrder__c WHERE QTB_Billing_Account__c IN: accId AND QTB_Amount__c > 0 AND QTB_Status__c='Active']){
                if(!futurePOsMap.containsKey(po.QTB_Billing_Account__c)){
                    futurePOsMap.put(po.QTB_Billing_Account__c, new List<QTB_PurchaseOrder__c>{po});
                }else{
                    futurePOsMap.get(po.QTB_Billing_Account__c).add(po);
                }
            }
            //Query email related template
            system.debug('&^&^&^&^'+emailTemplateName);
            for (EmailTemplate et: [Select id,name from EmailTemplate where name IN:emailTemplateName]) {
                emailTemplateNameIdMap.put(et.Name, et.Id);
            }
            system.debug('&^&^&^&^22222'+emailTemplateNameIdMap);
            system.debug('$%$%$%$%$%'+accId);
            //Query all the PO Contacts related to Account
            for(AccountContactRelation con : [SELECT AccountId,Contactid,Roles from AccountContactRelation WHERE AccountId IN: accId AND Roles INCLUDES('PO Contact') AND Isactive=true]){
                if(AccountIdPOContactEmailMap.containsKey(con.AccountId)){
                    AccountIdPOContactEmailMap.get(con.AccountId).add(con.Contactid);
                }else{
                    AccountIdPOContactEmailMap.put(con.AccountId, new List<Id>{con.Contactid});
                }
            }
            //Query email related Org wide email Address
            //Gitlab 20826 Queried Address field and comparing the Email Address as we changes the From Addfress to Email Addresss not the OWD Display name
            //Even Added in the Map with Address as key instead Display name
            for (orgwideEmailAddress oe: [select id,displayname,Address from orgwideEmailAddress where Address IN: orgWideEmailAddressList ]) {
                orgWideEmailAddressMap.put(oe.Address, oe.Id);
            }
            //List to FIlter the Final POs
            List<QTB_PurchaseOrder__c> finalPos = new List<QTB_PurchaseOrder__c>();
            //Check if any Future PO Records are present or not? If present then filter it so that we'll not send email
            for (QTB_PurchaseOrder__c po: scope) {
                //Basic Filter Check
                if(AccountIdPOContactEmailMap.containsKey(po.QTB_Billing_Account__c)){
                    //No Other POs for the respective PO's Billing Account
                    if(!futurePOsMap.containsKey(po.QTB_Billing_Account__c)){
                        finalPos.add(po);
                    }else{//Oter POs Present
                        boolean futurePOPresent = false;
                        //Get all the POs for that Billing Account
                        for(QTB_PurchaseOrder__c PoDate : futurePOsMap.get(po.QTB_Billing_Account__c)){
                            System.debug(PoDate.QTB_Start_Date__c+'@@@@@@@@@@1212'+po.QTB_End_Date__c);
                            //Compare the 'Start Date' of any other POs grater than current PO 'End Date'
                            if(PoDate.QTB_Start_Date__c > po.QTB_End_Date__c){
                                system.debug('@@@@@@@@@@1212333');
                                futurePOPresent = true;
                            }
                            //If found anytime then break
                            if(futurePOPresent){
                                break;
                            }
                        }
                        if(!futurePOPresent){
                            system.debug('@@@@@@@@@@1212333444');
                            finalPos.add(po);
                        }
                    }
                }
            }
            for (QTB_PurchaseOrder__c po: finalPos){
                system.debug('#########1'+po.id);
                double percantageVal = 0;
                //Check PO Balance Percentage
                if(po.QTB_Amount__c != null && po.QTB_Amount__c!= 0 && po.QTB_PO_Balance_Amount__c != null){
                    system.debug('#########12');
                    //Check if the balance is -ve(Means already 100% utilized)
                    if(po.QTB_PO_Balance_Amount__c < =0){
                        percantageVal = 100;
                    }else{
                        system.debug(po.QTB_Amount__c+'#$#$**'+po.QTB_PO_Balance_Amount__c);
                        percantageVal = ((po.QTB_Amount__c - po.QTB_PO_Balance_Amount__c)/po.QTB_Amount__c) * 100;
                    }
                }
                system.debug('@#@#$'+percantageVal);
                system.debug('@#@#$232323'+po.QTB_Billing_Account__c);
                system.debug('@@@@@@@333'+AccountIdPOContactEmailMap);
                system.debug('$%$%$%$%$%'+AccountIdPOContactEmailMap.containsKey(po.QTB_Billing_Account__c));
                QTB_PurchaseOrder__c poRec = new QTB_PurchaseOrder__c();
                poRec.id = po.id;
                system.debug('11111$%$%$%$%$%'+AccountIdPOContactEmailMap.get(po.QTB_Billing_Account__c));
                //Get respective PO Notification Metadata Record
                // #20826 Added the below logic for converting the Legal Entity Number double Data type to Text data type and checking the legal Entity present meta data countries
                // Creating a stringVariable for conversion of double data type to String datatype and remove ".0" combination from that string
                string legalEntitynumber = 'None';
                if(poWithMultipleLegalEntitiesMap.get(po.QTB_Legal_Entity_Country__c) == True){
                    if(po.QTB_Billing_Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c != null){
                        legalEntitynumber = String.valueOf(po.QTB_Billing_Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c);
                        if(legalEntitynumber.contains('.')){
                            legalEntitynumber = legalEntitynumber.replace('.0','');
                        }
                    }
                }
                QTB_PO_Email_Notification__mdt POMetaData = POTemplateNotificationMap.get(po.QTB_Legal_Entity_Country__c+po.QTB_Billing_Account__r.QTB_Language__c + legalEntitynumber);
                //Set dynamic Subject from the Metadata record
                List<string> subjectList = new List<string>();
                string subjectDetails = '';
                if(POMetaData.QTB_Email_Subject__c != null){
                    subjectList.addAll(POMetaData.QTB_Email_Subject__c.split('::'));
                    if(subjectList.size() == 2){
                        //Subject in below Format
                        //ACTION REQUIRED CUSTOMER PO# {{{QTB_PurchaseOrder__c.QTB_Customer_PO__c}}}, Customer#: {{{QTB_PurchaseOrder__c.QTB_Billing_Account__c}}}
                        subjectDetails = subjectList[0]+'#: '+po.QTB_Customer_PO__c+','+subjectList[1]+'#:'+po.QTB_Billing_Account__r.Name;
                    }
                }
                system.debug('@#@#@#@#@#@#@#@#@#'+subjectDetails);
                for(id conId : AccountIdPOContactEmailMap.get(po.QTB_Billing_Account__c)){
                    //If Balance is more than 50%
                    System.debug('percantageVal@@'+percantageVal);
                    System.debug('PO@@'+PO);
                    if(50 <= percantageVal && percantageVal < 75 && po.QTB_50_Utilization_Email_Sent__c == false){
                        if(emailTemplateNameIdMap.containsKey(POMetaData.QTB_50_Utilization_Template__c)){
                            //Get Respective Template Id by Template Name
                            //Set PO as What id to get the Merge field in Email template's Subject and Others
                            //This is to use change the custom subject - renderStoredEmailTemplate(TemplateId,WhoId,WhatId)
                            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_50_Utilization_Template__c), conId, po.id);
                            mail.setSubject(subjectDetails);
                            //mail.setsaveAsActivity(false);
                            //set the FROM address by setting the org-wide address to use
                            if(orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)){
                                mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                            }
                            utilizationEmailList.add(mail);
                            poRec.QTB_50_Utilization_Email_Sent__c = true;
                        }
                        //If Balance is more than 75%
                    }
                    else if(75 <= percantageVal && percantageVal < 90 && po.QTB_75_Utilization_Email_Sent__c == false){
                        if(emailTemplateNameIdMap.containsKey(POMetaData.QTB_75_Utilization_Template__c)){
                            //Get Respective Template Id by Template Name
                            //mail.setTemplateId(emailTemplateNameIdMap.get(POMetaData.QTB_75_Utilization_Template__c));
                            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_75_Utilization_Template__c), conId, po.id);
                            mail.setSubject(subjectDetails);
                            //mail.setsaveAsActivity(false);
                            //set the FROM address by setting the org-wide address to use
                            if(orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)){
                                mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                            }
                            utilizationEmailList.add(mail);
                            poRec.QTB_75_Utilization_Email_Sent__c = true;
                        }
                        //If Balance is more than 90%
                    }
                    else if(90 <= percantageVal && percantageVal < 100 && po.QTB_90_Utilization_Email_Sent__c == false){
                        if(emailTemplateNameIdMap.containsKey(POMetaData.QTB_90_Utilization_Template__c)){
                            //Get Respective Template Id by Template Name
                            //mail.setTemplateId(emailTemplateNameIdMap.get(POMetaData.QTB_90_Utilization_Template__c));
                            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_90_Utilization_Template__c), conId, po.id);
                            mail.setSubject(subjectDetails);
                            //mail.setsaveAsActivity(false);
                            //set the FROM address by setting the org-wide address to use
                            if(orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)){
                                mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                            }
                            utilizationEmailList.add(mail);
                            poRec.QTB_90_Utilization_Email_Sent__c = true;
                        }
                        //If Balance is equal to 100%
                    }
                    else if(100 == percantageVal && po.QTB_100_Utilization_Email_Sent__c == false){
                        if(emailTemplateNameIdMap.containsKey(POMetaData.QTB_100_Utilization_Template__c)){
                            //Get Respective Template Id by Template Name
                            //mail.setTemplateId(emailTemplateNameIdMap.get(POMetaData.QTB_100_Utilization_Template__c));
                            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_100_Utilization_Template__c), conId, po.id);
                            mail.setSubject(subjectDetails);
                            //mail.setsaveAsActivity(false);
                            //set the FROM address by setting the org-wide address to use
                            if(orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)){
                                mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                            }
                            utilizationEmailList.add(mail);
                            poRec.QTB_100_Utilization_Email_Sent__c = true;
                        }
                    }
                    if(!MapPOEmailSentUpdate.containsKey(poRec.id)){
                        MapPOEmailSentUpdate.put(poRec.id,poRec);
                    }
                }
            }
            //Check if the Email List is having value
            if(utilizationEmailList.size() > 0){
                Messaging.sendEmail(utilizationEmailList);
            }
            //Update the PO email Sent checkbox
            if(MapPOEmailSentUpdate != null && MapPOEmailSentUpdate.size() > 0){
                system.debug('%%%%%%%%%%%%---&&&'+MapPOEmailSentUpdate);
                Update MapPOEmailSentUpdate.values();
            }
        }
        catch (Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_sendPONotificationBatch');
        }
    }**/
    
    public void execute(Database.BatchableContext bc, list<QTB_PurchaseOrder__c> scope)
    {
        //Variables declaration
        // List<id> accId = new List<id>();
        Map<id,List<id>> AccountIdPOContactEmailMap = new Map<id,List<id>>();
        List<Messaging.SingleEmailMessage> utilizationEmailList = new List<Messaging.SingleEmailMessage>();
        List<string> emailTemplateNames = new List<string>();
        List<string> orgWideEmailAddressList = new List<string>();
        Map<string,id> emailTemplateNameIdMap = new Map<string,id>();
        Map<string,string> orgWideEmailAddressMap = new Map<string,id>();
        Map<Id,List<QTB_PurchaseOrder__c>> futurePOsMap = new Map<Id,List<QTB_PurchaseOrder__c>>();
        Map<id,QTB_PurchaseOrder__c> MapPOEmailSentUpdate = new Map<id,QTB_PurchaseOrder__c>();
        
        //New variables
        List<string> NewTemplateName = new List<string>();
        List<string> orgWideDetailedAddressList = new List<string>();
        Map<string,id> emailDetailedIdMap = new Map<string,id>();
        
        // Variables declaration for Gitlab #31454
        Set<Id> poIds = new Set<Id>();
        Map<Id, List<Id>> poToAccountIdsMap = new Map<Id, List<Id>>();
        Set<Id> accId = new Set<Id>();
        Map<Id, List<Id>> poIdToPoaIdsMap = new Map<Id, List<Id>>();
        
        //30 days after and 60 days after should send email in other Daily Batch
        //http://amitsalesforce.blogspot.com/2015/11/singleemailmessage-vs-massemailmessage.html
        try {
            if(scope !=null && !scope.isEmpty()){
                for (QTB_PurchaseOrder__c po : scope) {
                    poIds.add(po.Id);
                }
                
                // Step 1: Get Junction Object Data
                for (QTB_PurchaseOrderAccount__c junction : [SELECT QTB_Purchase_Order__c, QTB_Account__c
                                                                FROM QTB_PurchaseOrderAccount__c
                                                                WHERE QTB_Purchase_Order__c IN :poIds
                                                            ]) {
                    if (!poToAccountIdsMap.containsKey(junction.QTB_Purchase_Order__c)) {
                        poToAccountIdsMap.put(junction.QTB_Purchase_Order__c, new List<Id>());
                    }
                    poToAccountIdsMap.get(junction.QTB_Purchase_Order__c).add(junction.QTB_Account__c);
                    if (!poIdToPoaIdsMap.containsKey(junction.QTB_Purchase_Order__c)) {
                        poIdToPoaIdsMap.put(junction.QTB_Purchase_Order__c, new List<Id>());
                    }
                    poIdToPoaIdsMap.get(junction.QTB_Purchase_Order__c).add(junction.Id);
                }
                for (List<Id> accs : poToAccountIdsMap.values()) {
                    accId.addAll(accs);
                }
                
                //Query all the PO Contacts related to Account
                for(AccountContactRelation con : [SELECT AccountId,Contactid,Roles from AccountContactRelation WHERE AccountId IN: accId AND Roles INCLUDES (:ROLE_PO_CONTACT) AND Isactive=true]){
                    if(AccountIdPOContactEmailMap.containsKey(con.AccountId)){
                        AccountIdPOContactEmailMap.get(con.AccountId).add(con.Contactid);
                    }else{
                        AccountIdPOContactEmailMap.put(con.AccountId, new List<Id>{con.Contactid});
                    }
                }
                //Query email related Org wide email Address
                //Gitlab 20826 Queried Address field and comparing the Email Address as we changes the From Addfress to Email Addresss not the OWD Display name
                //Even Added in the Map with Address as key instead Display name
            /*    for (orgwideEmailAddress oe: [select id,displayname,Address from orgwideEmailAddress where Address IN: orgWideEmailAddressList ]) {
                    orgWideEmailAddressMap.put(oe.Address, oe.Id);
                } */
                
                // Step 2: Get all the PO related to the current PO's Accounts to check if any a Future date PO with condition as 'Amount > 0' is present or not?
                for (QTB_PurchaseOrderAccount__c junction : [SELECT QTB_Purchase_Order__c, QTB_Account__c,
                                                                QTB_Purchase_Order__r.Id,
                                                                QTB_Purchase_Order__r.QTB_Start_Date__c,
                                                                QTB_Purchase_Order__r.QTB_End_Date__c,
                                                                QTB_Purchase_Order__r.QTB_Amount__c,
                                                                QTB_Purchase_Order__r.QTB_Status__c
                                                                    FROM QTB_PurchaseOrderAccount__c
                                                                    WHERE QTB_Account__c IN :accId
                                                                    AND QTB_Purchase_Order__r.QTB_Status__c = 'Active'
                                                                    AND QTB_Purchase_Order__r.QTB_Amount__c > 0
                                                                ]) {
                    Id accountId = junction.QTB_Account__c;
                    QTB_PurchaseOrder__c po = junction.QTB_Purchase_Order__r;
                    if (!futurePOsMap.containsKey(accountId)) {
                        futurePOsMap.put(accountId, new List<QTB_PurchaseOrder__c>{ po });
                    } else {
                        futurePOsMap.get(accountId).add(po);
                    }
                }
                
                // Step 3: Filter final POs to notify
                List<QTB_PurchaseOrder__c> finalPos = new List<QTB_PurchaseOrder__c>();
                for (QTB_PurchaseOrder__c po : scope) {
                    List<Id> relatedAccounts = poToAccountIdsMap.get(po.Id);
                    if (relatedAccounts == null)
                    {
                        continue;
                    }
                    
                    for (Id acc : relatedAccounts) {
                        if (po.QTB_End_Date__c != null && AccountIdPOContactEmailMap.containsKey(acc)) {
                            Boolean futurePOExists = false;
                            if (futurePOsMap.containsKey(acc)) {
                                for (QTB_PurchaseOrder__c futurePO : futurePOsMap.get(acc)) {
                                    if (futurePO.QTB_Start_Date__c > po.QTB_End_Date__c) {
                                        futurePOExists = true;
                                        break;
                                    }
                                }
                            }
                            if (!futurePOExists) {
                                finalPos.add(po);
                                break;
                            }
                        }
                    }
                }
                
                
                // Step 6: Email notification logic is added here via junction and account-driven model
                // Preload Account metadata used for email templates
                Map<Id, Account> accountDetailsMap = new Map<Id, Account>([SELECT Id, Name, QTB_Language__c, QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c
                                                                        FROM Account
                                                                        WHERE Id IN :accId]
                                                                            );
                
                for (QTB_PurchaseOrder__c po : finalPos) {
                    if (po == null) continue;
                    
                    List<Id> relatedAccounts = poToAccountIdsMap.get(po.Id);
                    if (relatedAccounts == null || relatedAccounts.isEmpty()) continue;
                    
                    List<Id> poaIdsList = poIdToPoaIdsMap.get(po.Id);
                    Set<Id> poaIdsSet = (poaIdsList != null) ? new Set<Id>(poaIdsList) : new Set<Id>();
                    if (poaIdsSet.isEmpty()) continue;
                    
                    for (Id relatedAccId : relatedAccounts) {
                        Account acc = accountDetailsMap.get(relatedAccId);
                        if (acc == null) continue;
                        
                        // Legal Entity Number logic
                        String legalEntitynumber = 'None';
                        if (poWithMultipleLegalEntitiesMap.get(po.QTB_Legal_Entity_Country__c) == true) {
                            if (acc.QTB_Contract_Entity__r != null &&
                            acc.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c != null) {
                                legalEntitynumber = String.valueOf(acc.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c);
                                if (legalEntitynumber.contains('.')) {
                                    legalEntitynumber = legalEntitynumber.replace('.0', '');
                                }
                            }
                        }
                        
                        // Get metadata record
                        QTB_PO_Email_Notification__mdt POMetaData = POTemplateNotificationMap.get(
                            po.QTB_Legal_Entity_Country__c + acc.QTB_Language__c + legalEntitynumber
                            );
                        
                        if (POMetaData != null)
                        {
                        if (POMetaData.QTB_100_Utilization_Template__c != null){
                            emailTemplateNames.add(POMetaData.QTB_100_Utilization_Template__c);
						}
                        if (POMetaData.QTB_50_Utilization_Template__c != null){
                            emailTemplateNames.add(POMetaData.QTB_50_Utilization_Template__c);
						}
                        if (POMetaData.QTB_75_Utilization_Template__c != null){
                            emailTemplateNames.add(POMetaData.QTB_75_Utilization_Template__c);
						}
                        if (POMetaData.QTB_90_Utilization_Template__c != null){
                            emailTemplateNames.add(POMetaData.QTB_90_Utilization_Template__c);
						}
						//Set Org Wide email address  GITLAB - #33195
                         orgWideEmailAddressList.add(POMetaData.QTB_From_Address__c);
						}
                    }
                }
				system.debug('orgWideEmailAddressList-->' +orgWideEmailAddressList);
				// code added as part of prod issue hypercareSupport GITLAB - #33195

				// Query OrgWideEmailAddresses if list not empty
                    if (orgWideEmailAddressList != null && !orgWideEmailAddressList.isEmpty()) {
                        List<orgwideEmailAddress> owdMailLst = [SELECT Id, DisplayName, Address 
                                                                FROM orgwideEmailAddress 
                                                                WHERE Address IN :orgWideEmailAddressList];
                        if (owdMailLst != null && !owdMailLst.isEmpty()) {
                            for (orgwideEmailAddress oe : owdMailLst) {
                                if (oe != null && oe.Address != null) {
                                    orgWideEmailAddressMap.put(oe.Address, oe.Id);
                                }
                            }
                        }
                    }
					 System.debug('Final orgWideEmailAddressMap: ' +orgWideEmailAddressMap);
                 
                // 3. Query all required EmailTemplate records once
                //Map<String, Id> emailTemplateNameIdMap = new Map<String, Id>();
                if (!emailTemplateNames.isEmpty()) {
                    for (EmailTemplate et : [SELECT Id, Name FROM EmailTemplate WHERE Name IN :emailTemplateNames]) {
                        emailTemplateNameIdMap.put(et.Name, et.Id);
                    }
                }
                
                // 4. Now loop again to process emails and send messages
                for (QTB_PurchaseOrder__c po : finalPos) {
                    if (po == null) continue;
                    
                    List<Id> relatedAccounts = poToAccountIdsMap.get(po.Id);
                    if (relatedAccounts == null || relatedAccounts.isEmpty()) continue;
                    
                    List<Id> poaIdsList = poIdToPoaIdsMap.get(po.Id);
                    Set<Id> poaIdsSet = (poaIdsList != null) ? new Set<Id>(poaIdsList) : new Set<Id>();
                    if (poaIdsSet.isEmpty()) continue;
                    
                    for (Id relatedAccId : relatedAccounts) {
                        Account acc = accountDetailsMap.get(relatedAccId);
                        if (acc == null) continue;
                        
                        List<Id> contactIds = AccountIdPOContactEmailMap.get(relatedAccId);
                        if (contactIds == null || contactIds.isEmpty()) continue;
                        
                        String legalEntitynumber = 'None';
                        if (poWithMultipleLegalEntitiesMap.get(po.QTB_Legal_Entity_Country__c) == true) {
                            if (acc.QTB_Contract_Entity__r != null &&
                            acc.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c != null) {
                                legalEntitynumber = String.valueOf(acc.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c);
                                if (legalEntitynumber.contains('.')) {
                                    legalEntitynumber = legalEntitynumber.replace('.0', '');
                                }
                            }
                        }
                        
                        QTB_PO_Email_Notification__mdt POMetaData = POTemplateNotificationMap.get(
                            po.QTB_Legal_Entity_Country__c + acc.QTB_Language__c + legalEntitynumber
                            );
                        
                        if (POMetaData == null) continue;
                        
                        // Build subject line
                        String subjectDetails = '';
                        if (POMetaData.QTB_Email_Subject__c != null) {
                            List<String> subjectList = POMetaData.QTB_Email_Subject__c.split('::');
                            if (subjectList.size() == 2) {
                                subjectDetails = subjectList[0] + '#: ' + po.QTB_Customer_PO__c +
                                    ', ' + subjectList[1] + '#: ' + acc.Name;
                            }
                        }
                        
                        // Calculate utilization percentage
                        Double percentageVal = 0;
                        if (po.QTB_Amount__c != null && po.QTB_Amount__c != 0 && po.QTB_PO_Balance_Amount__c != null) {
                            if (po.QTB_PO_Balance_Amount__c <= 0) {
                                percentageVal = 100;
                            } else {
                                percentageVal = ((po.QTB_Amount__c - po.QTB_PO_Balance_Amount__c) / po.QTB_Amount__c) * 100;
                            }
                        }
                        
                        for (Id poaId : poaIdsSet) {
                            if (poaId == null) continue;
                            
                            for (Id conId : contactIds) {
                                Messaging.SingleEmailMessage mail;
                                
                                // 50% to <75%
                                if (percentageVal >= 50 && percentageVal < 75 && po.QTB_50_Utilization_Email_Sent__c == false) {
                                    if (emailTemplateNameIdMap.containsKey(POMetaData.QTB_50_Utilization_Template__c)) {
                                        mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_50_Utilization_Template__c), conId, poaId);
                                        mail.setSubject(subjectDetails);
                                        if (orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)) {
                                            mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                                        }
                                        utilizationEmailList.add(mail);
                                        po.QTB_50_Utilization_Email_Sent__c = true;
                                    }
                                }
                                // 75% to <90%
                                else if (percentageVal >= 75 && percentageVal < 90 && po.QTB_75_Utilization_Email_Sent__c == false) {
                                    if (emailTemplateNameIdMap.containsKey(POMetaData.QTB_75_Utilization_Template__c)) {
                                        mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_75_Utilization_Template__c), conId, poaId);
                                        mail.setSubject(subjectDetails);
                                        if (orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)) {
                                            mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                                        }
                                        utilizationEmailList.add(mail);
                                        po.QTB_75_Utilization_Email_Sent__c = true;
                                    }
                                }
                                // 90% to <100%
                                else if (percentageVal >= 90 && percentageVal < 100 && po.QTB_90_Utilization_Email_Sent__c == false) {
                                    if (emailTemplateNameIdMap.containsKey(POMetaData.QTB_90_Utilization_Template__c)) {
                                        mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_90_Utilization_Template__c), conId, poaId);
                                        mail.setSubject(subjectDetails);
                                        if (orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)) {
                                            mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                                        }
                                        utilizationEmailList.add(mail);
                                        po.QTB_90_Utilization_Email_Sent__c = true;
                                    }
                                }
                                // Exactly 100%
                                else if (percentageVal == 100 && po.QTB_100_Utilization_Email_Sent__c == false) {
                                    if (emailTemplateNameIdMap.containsKey(POMetaData.QTB_100_Utilization_Template__c)) {
                                        mail = Messaging.renderStoredEmailTemplate(emailTemplateNameIdMap.get(POMetaData.QTB_100_Utilization_Template__c), conId, poaId);
                                        mail.setSubject(subjectDetails);
                                        if (orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)) {
                                            mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                                        }
                                        utilizationEmailList.add(mail);
                                        po.QTB_100_Utilization_Email_Sent__c = true;
                                    }
                                }
                                
                                // Track which POs have emails sent and need updating later
                                if (!MapPOEmailSentUpdate.containsKey(po.Id)) {
                                    MapPOEmailSentUpdate.put(po.Id, po);
                                }
                            } 
                        }
                        
                        // Make sure PO update map has the latest
                        MapPOEmailSentUpdate.put(po.Id, po);
                    } 
                } 
                
                //Check if the Email List is having value
                //Getting Too many SOQL 201 as after sendEmail, Task and contact is updating per record 10+ queries executing in same context Archetect are aware about this issue no solution for now
                if(utilizationEmailList.size() > 0){
                    Messaging.sendEmail(utilizationEmailList);
                    emailCounter = emailCounter + utilizationEmailList.size();
                }
                //Update the PO email Sent checkbox
                if(MapPOEmailSentUpdate != null && MapPOEmailSentUpdate.size() > 0){
                    Update MapPOEmailSentUpdate.values();
                }
            }
        }
        catch (Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_sendPONotificationBatch');
        }
    }
    
    /*********************************************************************************************************
     * Method Name: finish
     * Parameters: Database.BatchableContext
     * Return Type: void
     * Requirement: Gitlab #1669
     * Description: finish method
     **********************************************************************************************************/
    public void finish (Database.BatchableContext bc)
    {
        //Logic for the finish method
        System.debug('Total emails sent: ' + emailCounter);
    }
}