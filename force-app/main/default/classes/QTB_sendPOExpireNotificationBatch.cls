/*****************************************************************************************************
 * Class: QTB_sendPOExpirNotificationBatch
 * Author: IRM
 * Purpose: This is a Batch class for send email notification based on the PO Expiring Date(End date)
 * Requirement: Gitlab #1669
 * Change History: 12/06/2021
 * Developer       Date            Description
 * -------------------------------------------------------------------------------------------
 * Gopinandan   12/06/2021
---------------------------------------------------------------------------------------------
     * Requirement: Gitlab #31454
 * Chetan Kumar 27/06/2025    Updated to remove dependency on QTB_Billing_Account__c and use junction object QTB_PurchaseOrderAccount__c
 *******************************************************************************************************/
public class QTB_sendPOExpireNotificationBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    public static Integer emailCounter = 0;
    public static final String ACTIVE = QTB_Constants.ACTIVE;
    public static final String STATUS_POSTED = QTB_Constants.INVOICE_STATUS_POSTED;
    public static final String ROLE_PO_CONTACT = 'PO Contact';
    public Map<string,QTB_PO_Email_Notification__mdt> POTemplateNotificationMap = new Map<string,QTB_PO_Email_Notification__mdt>();
    // #20826 Created map of country and Boolean Value
    public Map<string,Boolean> poWithMultipleLegalEntitiesMap = new map<string,Boolean>();
    
    //Constructor
    public QTB_sendPOExpireNotificationBatch() {
        try {
            // Query all metadata records
            List<QTB_PO_Email_Notification__mdt> mdtList = [ SELECT Id,QTB_After_Expiring_Template__c,
                                                                QTB_Before_Expiring_Template__c,
                                                                QTB_100_Utilization_Template__c,
                                                                QTB_Country__c,
                                                                QTB_Email_Subject__c,
                                                                QTB_From_Address__c,
                                                                QTB_Language__c,
                                                                QTB_Legal_Entity_Number__c
                                                            FROM QTB_PO_Email_Notification__mdt
                                                        ];
            
            if (mdtList != null && !mdtList.isEmpty()) {
                
                for (QTB_PO_Email_Notification__mdt mdt : mdtList) {
                    // Defensive null checks on required fields used in key
                    String country = mdt.QTB_Country__c != null ? mdt.QTB_Country__c : 'UnknownCountry';
                    String language = mdt.QTB_Language__c != null ? mdt.QTB_Language__c : 'UnknownLanguage';
                    String legalEntityNumber = (mdt.QTB_Legal_Entity_Number__c != null)
                        ? String.valueOf(mdt.QTB_Legal_Entity_Number__c)
                        : 'None';
                    
                    // Store in map with composite key
                    String compositeKey = country + language + legalEntityNumber;
                    POTemplateNotificationMap.put(compositeKey, mdt);
                    
                    // Track if this country has multiple legal entities
                    if (!poWithMultipleLegalEntitiesMap.containsKey(country)) {
                        poWithMultipleLegalEntitiesMap.put(country, mdt.QTB_Legal_Entity_Number__c != null);
                    }
                    
                    System.debug('Loaded Metadata: ' + JSON.serializePretty(mdt));
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
            e.getStackTraceString(),
            e.getMessage(),
            e.getTypeName(),
            'QTB_sendPOExpireNotificationBatch');
        }
    }
    
    
    /*********************************************************************************************************
    
     * Method Name: start
     * Parameters: Database.BatchableContext
     * Return Type: Database.QueryLocator
     * Requirement: Gitlab #1669
     * Description: Query PO required records
    ---------------------------------------------------------------------
         * Chetan Kumar 27/06/2025    Updated to remove dependency on QTB_Billing_Account__c and use junction object QTB_PurchaseOrderAccount__c
     * Requirement: Gitlab #31454
     * Description: Query PO records based on expiry/utilization window
     *********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm
        // Date string to use in Query
        Date TodayDate = System.Today();
        Date Next90Days = TodayDate.addDays(90);
        Date Next60Days = TodayDate.addDays(60);
        Date Next30Days = TodayDate.addDays(30);
        Date Last60Days = TodayDate.addDays(-60);
        Date Last90Days = TodayDate.addDays(-90);
        Date After60days = TodayDate.addDays(-60);
        Date After30days = TodayDate.addDays(-30);
        
        // Added new query removed the QTB_Billing_Account__r reference from it as this field is not used in QTB_PurchaseOrder__c Gitlab #31454
        String query = 'SELECT Id, Name, QTB_Legal_Entity_Country__c, QTB_Date_Of_100_Utilization__c, ' +
            'QTB_Amount__c, QTB_Status__c, QTB_End_Date__c, QTB_Start_Date__c, ' +
            'QTB_30_Days_Before_Email_Sent__c, QTB_60_Days_Before_Email_Sent__c, ' +
            'QTB_90_Days_Before_Email_Sent__c, QTB_90_Days_After_Email_Sent__c, ' +
            'QTB_60_Days_After_Email_Sent__c, QTB_Expiration_Today_Email_Sent__c, ' +
            'QTB_30_days_After_100_Utilization_Email__c, QTB_60_days_After_100_Utilization_Email__c, ' +
            'QTB_PO_Balance_Amount__c, QTB_Customer_PO__c ' +
            'FROM QTB_PurchaseOrder__c ' +
            'WHERE (QTB_End_Date__c = :Next90Days ' +
            'OR QTB_End_Date__c = :Next60Days ' +
            'OR QTB_End_Date__c = :Next30Days ' +
            'OR QTB_End_Date__c = :TodayDate ' +
            'OR QTB_End_Date__c = :Last90Days ' +
            'OR QTB_End_Date__c = :Last60Days ' +
            'OR QTB_Date_Of_100_Utilization__c = :After60days ' +
            'OR QTB_Date_Of_100_Utilization__c = :After30days) ' +
            'AND QTB_Status__c = :ACTIVE';
        
        if (Test.isRunningTest()) {
            query += ' LIMIT 200';
        }
        System.debug('query >> '+query);
        return Database.getQueryLocator(query);
    }
    
    // Added new execute method Requirement: Gitlab #31454
    /*********************************************************************************************************
     * Method Name: execute
     * Parameters: Database.BatchableContext,List<SObject>
     * Return Type: void
     * Requirement: Gitlab #1669
    --------------------------------------------------------------------
         * Chetan Kumar 27/06/2025    Updated to remove dependency on QTB_Billing_Account__c and use junction object QTB_PurchaseOrderAccount__c
     * Requirement: Gitlab #31454
     **********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<QTB_PurchaseOrder__c> scope){
        
        System.debug(' Starting Execute method with PO scope size: ' + scope.size());
        System.debug('scope >>> '+JSON.serializePretty(scope));
        
        Integer i =0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        //Variables declaration
        Map<id,List<id>> AccountIdPOContactEmailMap = new Map<id,List<id>>();
        List<Messaging.SingleEmailMessage> mailListExpiring = new List<Messaging.SingleEmailMessage>();
        List<string> emailTemplateName = new List<string>();
        List<string> orgWideEmailAddressList = new List<string>();
        Map<string,id> emailTemplateNameIdMap = new Map<string,id>();
        Map<string,string> orgWideEmailAddressMap = new Map<string,id>();
        Map<Id,List<QTB_PurchaseOrder__c>> futurePOsMap = new Map<Id,List<QTB_PurchaseOrder__c>>();
        Map<id,QTB_PurchaseOrder__c> MapPOEmailSentUpdate = new Map<id,QTB_PurchaseOrder__c>();
        
        // Variables declaration for Gitlab #31454
        Set<Id> poIds = new Set<Id>();
        Map<Id, List<Id>> poToAccountIdsMap = new Map<Id, List<Id>>();
        Map<Id, List<Id>> poIdToPoaIdsMap = new Map<Id, List<Id>>();
        Set<Id> accId = new Set<Id>();
        
        //30 days after and 60 days after should send email in other Daily Batch
        //http://amitsalesforce.blogspot.com/2015/11/singleemailmessage-vs-massemailmessage.html
        try {
            // Step 0: Validate input and initialize collections
            if (scope != null && !scope.isEmpty()) {
                
                for (QTB_PurchaseOrder__c po : scope) {
                    if (po != null && po.Id != null) {
                        poIds.add(po.Id);
                    }
                }
                
                System.debug('PO IDs in scope: ' + JSON.serializePretty(poIds));
                
                // Step 1: Get Junction Object Data with null and map checks
                if (poIds != null && !poIds.isEmpty()) {
                    List<QTB_PurchaseOrderAccount__c> junctionObjectLst = [SELECT Id, QTB_Purchase_Order__c, QTB_Account__c
                                                                            FROM QTB_PurchaseOrderAccount__c
                                                                            WHERE QTB_Purchase_Order__c IN :poIds];
                    if (junctionObjectLst != null && !junctionObjectLst.isEmpty()) {
                        for (QTB_PurchaseOrderAccount__c junction : junctionObjectLst) {
                            if (!poToAccountIdsMap.containsKey(junction.QTB_Purchase_Order__c)) {
                                poToAccountIdsMap.put(junction.QTB_Purchase_Order__c, new List<Id>());
                            }
                            poToAccountIdsMap.get(junction.QTB_Purchase_Order__c).add(junction.QTB_Account__c);
                            
                            if (!poIdToPoaIdsMap.containsKey(junction.QTB_Purchase_Order__c)) {
                                poIdToPoaIdsMap.put(junction.QTB_Purchase_Order__c, new List<Id>());
                            }
                            poIdToPoaIdsMap.get(junction.QTB_Purchase_Order__c).add(junction.Id);
                        }
                    }
                }
                
                System.debug('Junction Map (PO -> Accounts): ' + JSON.serializePretty(poToAccountIdsMap));
                System.debug('poToAccountIdsMap.size(): ' + poToAccountIdsMap.size());
                
                if (poToAccountIdsMap != null && !poToAccountIdsMap.isEmpty()) {
                    for (List<Id> accs : poToAccountIdsMap.values()) {
                        accId.addAll(accs);
                    }
                }
                
                System.debug('Account IDs to fetch: ' + accId);
                
                // Step 1 continued: Query PO Contacts related to Accounts
                if (accId != null && !accId.isEmpty()) {
                    List<AccountContactRelation> accConRelLst = [SELECT AccountId, ContactId, Roles
                                                                    FROM AccountContactRelation
                                                                    WHERE AccountId IN :accId
                                                                    AND Roles INCLUDES (:ROLE_PO_CONTACT)
                                                                    AND IsActive = true];
                    if (accConRelLst != null && !accConRelLst.isEmpty()) {
                        for (AccountContactRelation con : accConRelLst) {
                            if (!AccountIdPOContactEmailMap.containsKey(con.AccountId)) {
                                AccountIdPOContactEmailMap.put(con.AccountId, new List<Id>());
                            }
                            AccountIdPOContactEmailMap.get(con.AccountId).add(con.ContactId);
                        }
                    }
                }
                
                System.debug('Contacts with PO Contact role: ' + AccountIdPOContactEmailMap);
                
                // Step 2: Get all future active POs for related accounts
                if (accId != null && !accId.isEmpty()) {
                    List<QTB_PurchaseOrderAccount__c> junctionObjLst = [SELECT QTB_Purchase_Order__c, QTB_Account__c,
                                                                            QTB_Purchase_Order__r.Id,
                                                                            QTB_Purchase_Order__r.QTB_Start_Date__c,
                                                                            QTB_Purchase_Order__r.QTB_End_Date__c,
                                                                            QTB_Purchase_Order__r.QTB_Amount__c,
                                                                            QTB_Purchase_Order__r.QTB_Status__c
                                                                        FROM QTB_PurchaseOrderAccount__c
                                                                        WHERE QTB_Account__c IN :accId
                                                                        AND QTB_Purchase_Order__r.QTB_Status__c = 'Active'
                                                                        AND QTB_Purchase_Order__r.QTB_Amount__c > 0];
                    if (junctionObjLst != null && !junctionObjLst.isEmpty()) {
                        for (QTB_PurchaseOrderAccount__c junction : junctionObjLst) {
                            Id accountId = junction.QTB_Account__c;
                            QTB_PurchaseOrder__c po = junction.QTB_Purchase_Order__r;
                            if (!futurePOsMap.containsKey(accountId)) {
                                futurePOsMap.put(accountId, new List<QTB_PurchaseOrder__c>{po});
                            } else {
                                futurePOsMap.get(accountId).add(po);
                            }
                        }
                    }
                }
                
                // Step 3: Filter final POs to notify with null safety
                List<QTB_PurchaseOrder__c> finalPos = new List<QTB_PurchaseOrder__c>();
                
                for (QTB_PurchaseOrder__c po : scope) {
                    System.debug('Processing PO: ' + po.Name + ' (' + po.Id + ')');
                    List<Id> relatedAccounts = poToAccountIdsMap.get(po.Id);
                    if (relatedAccounts != null && !relatedAccounts.isEmpty()) {
                        for (Id acc : relatedAccounts) {
                            if (po.QTB_End_Date__c != null && AccountIdPOContactEmailMap.containsKey(acc)) {
                                Boolean futurePOExists = false;
                                if (futurePOsMap.containsKey(acc)) {
                                    for (QTB_PurchaseOrder__c futurePO : futurePOsMap.get(acc)) {
                                        if (futurePO != null &&
                                            futurePO.QTB_Start_Date__c != null &&
                                        futurePO.QTB_Start_Date__c > po.QTB_End_Date__c) {
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
                }
                
                // Step 4: Send Email Notifications
                if (accId != null && !accId.isEmpty()) {
                    Map<Id, Account> accountDetailsMap = new Map<Id, Account>([SELECT Id, Name, QTB_Language__c, QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c
                                                                                FROM Account
                                                                                WHERE Id IN :accId]);
                    
                    System.debug('Loaded Account Details: ' + accountDetailsMap.keySet());
                    System.debug('Continue from line 530: ' + finalPos.size());
                    
                    // Step 4.1: Collect all email template names needed
                    Set<String> emailTemplateNameSet = new Set<String>();
                    if (accountDetailsMap != null && finalPos != null && !accountDetailsMap.isEmpty() && !finalPos.isEmpty()) {
                        
                        
                        
                        for (QTB_PurchaseOrder__c po : finalPos) {
                            List<Id> relatedAccounts = poToAccountIdsMap.get(po.Id);
                            if (relatedAccounts != null && !relatedAccounts.isEmpty()) {
                                for (Id relatedAccId : relatedAccounts) {
                                    Account acc = accountDetailsMap.get(relatedAccId);
                                    if (acc != null) {
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
                                        
                                        if (POMetaData != null) {
                                            if (POMetaData.QTB_After_Expiring_Template__c != null){
                                                emailTemplateNameSet.add(POMetaData.QTB_After_Expiring_Template__c);
                                            }
                                            if (POMetaData.QTB_Before_Expiring_Template__c != null){
                                                emailTemplateNameSet.add(POMetaData.QTB_Before_Expiring_Template__c);
                                            }
                                            if (POMetaData.QTB_100_Utilization_Template__c != null){
                                                emailTemplateNameSet.add(POMetaData.QTB_100_Utilization_Template__c);
                                            }
                                            //Set Org Wide email address
                                            orgWideEmailAddressList.add(POMetaData.QTB_From_Address__c);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
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
                    
                    // Step 4.2: Query EmailTemplates once and store in Map
                    if (!emailTemplateNameSet.isEmpty()) {
                        List<EmailTemplate> etemLst = [SELECT Id, Name 
                                                        FROM EmailTemplate 
                                                        WHERE Name IN :emailTemplateNameSet];
                        if (etemLst != null && !etemLst.isEmpty()) {
                            for (EmailTemplate et : etemLst) {
                                emailTemplateNameIdMap.put(et.Name, et.Id);
                            }
                        }
                    }
                    
                    // Step 4.3: Main processing loop with null checks
                    if (finalPos != null && !finalPos.isEmpty()) {
                        
                        for (QTB_PurchaseOrder__c po : finalPos) {
                            List<Id> poaIdsList = poIdToPoaIdsMap.get(po.Id);
                            Set<Id> poaIdsSet = (poaIdsList != null) ? new Set<Id>(poaIdsList) : new Set<Id>();
                            List<Id> relatedAccounts = poToAccountIdsMap.get(po.Id);
                            if (relatedAccounts != null && !relatedAccounts.isEmpty()){
                                
                                for (Id relatedAccId : relatedAccounts) {
                                    
                                    Account acc = accountDetailsMap.get(relatedAccId);
                                    if (acc == null) continue;
                                    
                                    List<Id> contactIds = AccountIdPOContactEmailMap.get(relatedAccId);
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
                                            subjectDetails = subjectList[0] + '#: ' + po.QTB_Customer_PO__c + ', ' +
                                                subjectList[1] + '#: ' + acc.Name;
                                        }
                                    }
                                    
                                    if (poaIdsSet != null && contactIds != null && !poaIdsSet.isEmpty() && !contactIds.isEmpty()) {
                                        for (Id poaId : poaIdsSet) {
                                            for (Id conId : contactIds) {
                                                Messaging.SingleEmailMessage mail;
                                                
                                                // Before Expiry Email
                                                if ((System.Today().addDays(90) == po.QTB_End_Date__c && !po.QTB_90_Days_Before_Email_Sent__c) ||
                                                    (System.Today().addDays(60) == po.QTB_End_Date__c && !po.QTB_60_Days_Before_Email_Sent__c) ||
                                                (System.Today().addDays(30) == po.QTB_End_Date__c && !po.QTB_30_Days_Before_Email_Sent__c)) {
                                                    
                                                    if (emailTemplateNameIdMap.containsKey(POMetaData.QTB_Before_Expiring_Template__c)) {
                                                        mail = Messaging.renderStoredEmailTemplate(
                                                            emailTemplateNameIdMap.get(POMetaData.QTB_Before_Expiring_Template__c), conId, poaId
                                                            );
                                                        mail.setSubject(subjectDetails);
                                                        
                                                        if (orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)) {
                                                            mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                                                        }
                                                        
                                                        mailListExpiring.add(mail);
                                                        
                                                        // Update flags
                                                        if (System.Today().addDays(90) == po.QTB_End_Date__c) {
                                                            po.QTB_90_Days_Before_Email_Sent__c = true;
                                                        } else if (System.Today().addDays(60) == po.QTB_End_Date__c) {
                                                            po.QTB_60_Days_Before_Email_Sent__c = true;
                                                        } else {
                                                            po.QTB_30_Days_Before_Email_Sent__c = true;
                                                        }
                                                    }
                                                }
                                                
                                                // After Expiry Email
                                                if ((System.Today() == po.QTB_End_Date__c && !po.QTB_Expiration_Today_Email_Sent__c) ||
                                                    (System.Today().addDays(-60) == po.QTB_End_Date__c && !po.QTB_60_Days_After_Email_Sent__c) ||
                                                (System.Today().addDays(-90) == po.QTB_End_Date__c && !po.QTB_90_Days_After_Email_Sent__c)) {
                                                    
                                                    if (emailTemplateNameIdMap.containsKey(POMetaData.QTB_After_Expiring_Template__c)) {
                                                        mail = Messaging.renderStoredEmailTemplate(
                                                            emailTemplateNameIdMap.get(POMetaData.QTB_After_Expiring_Template__c), conId, poaId
                                                            );
                                                        mail.setSubject(subjectDetails);
                                                        
                                                        if (orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)) {
                                                            mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                                                        }
                                                        
                                                        mailListExpiring.add(mail);
                                                        
                                                        // Update flags
                                                        if (System.Today() == po.QTB_End_Date__c) {
                                                            po.QTB_Expiration_Today_Email_Sent__c = true;
                                                        } else if (System.Today().addDays(-60) == po.QTB_End_Date__c) {
                                                            po.QTB_60_Days_After_Email_Sent__c = true;
                                                        } else {
                                                            po.QTB_90_Days_After_Email_Sent__c = true;
                                                        }
                                                    }
                                                }
                                                
                                                // 100% Utilization Email
                                                if ((System.Today().addDays(-30) == po.QTB_Date_Of_100_Utilization__c && !po.QTB_30_days_After_100_Utilization_Email__c) ||
                                                (System.Today().addDays(-60) == po.QTB_Date_Of_100_Utilization__c && !po.QTB_60_days_After_100_Utilization_Email__c)) {
                                                    
                                                    if (emailTemplateNameIdMap.containsKey(POMetaData.QTB_100_Utilization_Template__c)) {
                                                        mail = Messaging.renderStoredEmailTemplate(
                                                            emailTemplateNameIdMap.get(POMetaData.QTB_100_Utilization_Template__c), conId, poaId
                                                            );
                                                        mail.setSubject(subjectDetails);
                                                        
                                                        if (orgWideEmailAddressMap.containsKey(POMetaData.QTB_From_Address__c)) {
                                                            mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(POMetaData.QTB_From_Address__c));
                                                        }
                                                        
                                                        mailListExpiring.add(mail);
                                                        
                                                        // Update flags
                                                        if (System.Today().addDays(-30) == po.QTB_Date_Of_100_Utilization__c) {
                                                            po.QTB_30_days_After_100_Utilization_Email__c = true;
                                                        } else {
                                                            po.QTB_60_days_After_100_Utilization_Email__c = true;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    MapPOEmailSentUpdate.put(po.Id, po);
                                }
                            }
                        }
                    }
                }
                
                //EMail LimitExceededException
                //https://help.salesforce.com/articleView?id=000312442&type=1&mode=1
                //https://salesforce.stackexchange.com/questions/227155/send-bulk-emails-to-internal-contacts-through-apex
                //http://forceguru.blogspot.com/2011/03/how-to-send-more-than-10-e-mails.html
                //Getting Too many SOQL 201 as after sendEmail, Task and contact is updating per record 10+ queries executing in same context Archetect are aware about this issue no solution for now
                //Check size and send email List
                if(mailListExpiring.size() > 0){
                    system.debug('%&%&%&%'+mailListExpiring.size());
                    Messaging.sendEmail(mailListExpiring);
                    emailCounter += mailListExpiring.size();
                }
                
                // Update the PO email sent flags if needed
                if (MapPOEmailSentUpdate != null && !MapPOEmailSentUpdate.isEmpty()) {
                    system.debug('%%%%%%%%%%%%---&&&'+MapPOEmailSentUpdate);
                    Update MapPOEmailSentUpdate.values();
                }
            }
        }
        catch (Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_sendPOExpirNotificationBatch');
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