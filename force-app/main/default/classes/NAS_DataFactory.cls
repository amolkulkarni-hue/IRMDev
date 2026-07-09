/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Data Factory Service Class. Implements all CRED operations in all Custom and Standard objects.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*
*  Modified By: Gouthami Redlapalli
Added code to capture error handling in logger object by gouthami for case#10942249 

Modified By: Srikumar Ramachandran on 10th Feb 2023
Changes: Commented Division_ID__c and Department_ID__C fields to remove the reference.
Gitlab: #13197

Modified By: Simranjit Kaur on 11th Nov 2025
Changes: Updated method "createRecurringCases" failure of updation of NAS Recurring Support cases and Added Method to send email/chatter notification for failure of NAS Recurring Case updating "Next Case Creation Date" field. 
Gitlab: #34480

**/
public without sharing class NAS_DataFactory {    
    /**
* @name getCaseListForServiceMarketUpdate
* @description Retrives the case record for update of Service Market fields.
**/
    public static List<Case> getCaseListForServiceMarketUpdate(Id caseId) {
        return [SELECT Id, NAS_Order_Number__c, Zip__c, NAS_SKP_Country__c FROM Case WHERE Id = :caseId];
    }
    /**
* @name cloneCaseEmailMessages
* @description Retrieves the list of Email Messages related to the supplied caseIdList parameter
* and clones the list under the parentId of the caseIdList.
**/
    @future
    public static void cloneCaseEmailMessages(List<Id> caseIdList)
    {
        Map<Id, Case> caseMap = new Map<Id, Case> ([SELECT Id, ParentId FROM Case WHERE Id IN :caseIdList AND NAS_Reparent_Email_Messages__c = true]);
        List<EmailMessage> emailMessageList2Copy = NAS_DataFactory.getEmailMessageListFromCase(caseIdList);
        List<EmailMessage> emailMessageList2Insert = new List<EmailMessage>();
        List<ContentDocumentLink> contentDocumentLinkList2Insert = new List<ContentDocumentLink>();
        List<List<ContentDocumentLink>> contentDocumentLinkListofList2Insert = new List<List<ContentDocumentLink>>();
        for(EmailMessage em: emailMessageList2Copy)
        {
            EmailMessage emClone = em.clone();
            Case cs = caseMap.get(em.ParentId);
            if(cs != null && cs.ParentId != null)
            {
                emClone.ParentId = cs.ParentId;
                emClone.RelatedToId = cs.ParentId;
                emClone.ValidatedFromAddress = null;
                emailMessageList2Insert.add(emClone);
                List<ContentDocumentLink> contentDocumentLinkListRelated = new List<ContentDocumentLink>();
                contentDocumentLinkListofList2Insert.add(contentDocumentLinkListRelated);
                for(ContentDocumentLink cdl: em.ContentDocumentLinks)
                {
                    ContentDocumentLink cdlCloneEmail = cdl.clone();
                    contentDocumentLinkListRelated.add(cdlCloneEmail);
                    ContentDocumentLink cdlCloneCase = cdl.clone();
                    cdlCloneCase.LinkedEntityId = cs.ParentId;
                    contentDocumentLinkList2Insert.add(cdlCloneCase);
                }
            }
        }
        if(!emailMessageList2Insert.isEmpty())
            Database.insert(emailMessageList2Insert, false);
        for(Integer iCtr = 0; iCtr < emailMessageList2Insert.size(); ++iCtr)
        {
            List<ContentDocumentLink> contentDocumentLinkListRelated = contentDocumentLinkListofList2Insert.get(iCtr);
            for(ContentDocumentLink cdl: contentDocumentLinkListRelated)
                cdl.LinkedEntityId = emailMessageList2Insert[iCtr].Id;
            contentDocumentLinkList2Insert.addAll(contentDocumentLinkListRelated);
        }
        if(!contentDocumentLinkList2Insert.isEmpty())
            Database.insert(contentDocumentLinkList2Insert, false);
    }
    /**
* @name getEmailMessageListFromCase
* @description Retrieves the list of Email Messages related to the supplied caseIdList parameter
**/
    public static List<EmailMessage> getEmailMessageListFromCase(List<Id> caseIdList)
    {
        //Division, EmailTemplateId, FirstOpenedDate, IsBounced, IsClientManaged, IsOpened, IsPrivateDraft, IsTracked,
        //LastOpenedDate, MessageIdentifier, ThreadIdentifier
        return [SELECT ActivityId, BccAddress, CcAddress, CreatedById, CreatedDate, FromAddress, FromName, HasAttachment, 
                Headers, HtmlBody, Id, Incoming, IsDeleted, IsExternallyVisible, LastModifiedById, LastModifiedDate,
                MessageDate, ParentId, RelatedToId, ReplyToEmailMessageId, Status, Subject, SystemModstamp, TextBody, 
                ToAddress, ValidatedFromAddress, (SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, 
                                                  Visibility FROM ContentDocumentLinks) FROM EmailMessage WHERE ParentId IN :caseIdList];
    }
    /**
* @name getUserUniqueIdentifier
* @description Retrieve the unique identifier of an user. 
**/
    public static String getUserUniqueIdentifier(Case cs)
    {
        return cs.LastModifiedBy.NAS_User_Unique_Identifier__c;
    }
    /**
* @name getCasePendingSKPCommunicatorUpdateList
* @description Returns a list of cases with pending SKP Communicator update API call.
**/
    public static List<Case> getCasePendingSKPCommunicatorUpdateList()
    {
        return [SELECT Id, NAS_External_ID__c, NAS_Communicator_Id__c, NAS_Root_Cause_Reason__c, 
                Status, LastModifiedBy.NAS_User_Unique_Identifier__c FROM Case WHERE 
                (NAS_CECOMM_Event_Status__c = :NAS_Constants.CECOMM_NOTIFIED OR 
                 NAS_CECOMM_Event_Status__c = :NAS_Constants.CECOMM_CREATED)
                AND NAS_External_Id__c LIKE :NAS_Constants.CECOMM + '%' AND IsClosed = true 
                LIMIT :NAS_Constants.CECOMM_BULK_NOTIFY_LIMIT];
    }
    /**
* @name getCasePendingSKPEventUpdateList
* @description Returns a list of cases with pending SKP Event update API call.
**/
    public static List<Case> getCasePendingSKPEventUpdateList()
    {
        return [SELECT Id, NAS_External_ID__c, LastModifiedBy.NAS_User_Unique_Identifier__c FROM 
                Case WHERE NAS_CECOMM_Event_Status__c = :NAS_Constants.CECOMM_CREATED AND 
                NAS_External_Id__c LIKE :NAS_Constants.CECOMM + '%' LIMIT 
                :NAS_Constants.CECOMM_BULK_NOTIFY_LIMIT];
    }
    /**
* @name getCECommSKPCustomer
* @description Returns a custom apex type NAS_DataTypeFactory.CECommSKPCustomer record from a SKP Customer ids set.
* The customer apex type consists of a Customer Account, Division, Department and Contact. 
**/
    public static NAS_DataTypeFactory.CECommSKPCustomer getCECommSKPCustomer(NAS_DataTypeFactory.CECommSKPCustomerIdSet skpIdSet)
    {
        NAS_DataTypeFactory.CECommSKPCustomer ceCommSKPCust = new NAS_DataTypeFactory.CECommSKPCustomer();
        ceCommSKPCust.skpCustomerList = new NAS_DataTypeFactory.SKPCustomerList();
        ceCommSKPCust.mapSKPIDToCustomerAccount = NAS_DataFactory.getCustomerAccounts(skpIdSet.customerSKPIdSet, 
                                                                                      ceCommSKPCust.skpCustomerList.customerAccountList);
        ceCommSKPCust.mapCustIdSKPDivIdToDivision = NAS_DataFactory.getCustomerDivisions(skpIdSet.divisionSKPIdSet, 
                                                                                         ceCommSKPCust.skpCustomerList.customerDivisionList,
                                                                                         ceCommSKPCust.skpCustomerList.customerAccountList);
        ceCommSKPCust.mapCustIdDivIdSKPDeptIdToDepartment = NAS_DataFactory.getCustomerDepartments(skpIdSet.departmentSKPIdSet, 
                                                                                                   ceCommSKPCust.skpCustomerList.customerDepartmentList,
                                                                                                   ceCommSKPCust.skpCustomerList.customerDivisionList,
                                                                                                   ceCommSKPCust.skpCustomerList.customerAccountList);
        /*Gitlab:130688-start
ceCommSKPCust.mapCustIdDivIdDeptIdEmailToContact = NAS_DataFactory.getCustomerContacts(skpIdSet.contactEmailSet, 
ceCommSKPCust.skpCustomerList.authorizedList, 
ceCommSKPCust.skpCustomerList.customerDepartmentList, 
ceCommSKPCust.skpCustomerList.customerDivisionList, 
ceCommSKPCust.skpCustomerList.customerAccountList);   Gitlab:130688-Stop*/
        return ceCommSKPCust;
    }
    /**
* @name getCustomerAccounts
* @description Returns a map of SKP Id to Customer Account Record
**/
    public static Map<String, IM_Customer_Account__c> getCustomerAccounts(Set<String> customerSKPIdList,
                                                                          List<IM_Customer_Account__c> customerAccountList)
    {
        customerAccountList.addAll([SELECT Id, IM_Account__c, Name FROM IM_Customer_Account__c 
                                    WHERE Name IN :customerSKPIdList AND Source_System__c = :NAS_Constants.SOURCE_SYSTEM_CODE_SKP_NA
                                    ORDER BY LastModifiedDate DESC]);
        Map<String, IM_Customer_Account__c> mapSKPIDToCustomerAccount = new Map<String, IM_Customer_Account__c>();
        for(IM_Customer_Account__c ca : customerAccountList) {
            if(mapSKPIDToCustomerAccount.get(ca.Name) != null) {
                continue;
            }
            mapSKPIDToCustomerAccount.put(ca.Name, ca);
        }
        return mapSKPIDToCustomerAccount;
    }
    /**
* @name getCustomerDivisions
* @description Returns a map of Customer Id to a map of SKP Division id to Division record.
**/
    public static Map<Id, Map<String, Division__c>> getCustomerDivisions(Set<String> divisionSKPIdList, 
                                                                         List<Division__c> customerDivisionList,
                                                                         List<IM_Customer_Account__c> customerAccountList)
    {
        customerDivisionList.addAll([SELECT Id, Customer_Id__c, Name FROM Division__c 
                                     WHERE Customer_Id__c IN :customerAccountList
                                     AND Name IN :divisionSKPIdList ORDER BY LastModifiedDate DESC]);
        Map<Id, Map<String, Division__c>> mapCustIdSKPDivIdToDivision = new Map<Id, Map<String, Division__c>>();
        for(Division__c div : customerDivisionList)
        {
            Map<String, Division__c> mapSKPIDToDivision = mapCustIdSKPDivIdToDivision.get(div.Customer_Id__c);
            if(mapSKPIDToDivision == null) {
                mapSKPIDToDivision = new Map<String, Division__c>();
            }
            if(mapSKPIDToDivision.get(div.Name) != null) {
                continue;
            }
            mapSKPIDToDivision.put(div.Name, div);
            mapCustIdSKPDivIdToDivision.put(div.Customer_Id__c, mapSKPIDToDivision);
        }
        return mapCustIdSKPDivIdToDivision;
    }
    /**
* @name getCustomerDepartments
* @description Returns a map of Customer Id to a map of Division Id to a map of SKP Department Id to a Department record.
**/
    public static Map<Id, Map<Id, Map<String, Department__c>>> getCustomerDepartments(Set<String> departmentSKPIdList, 
                                                                                      List<Department__c> customerDepartmentList,
                                                                                      List<Division__c> customerDivisionList,
                                                                                      List<IM_Customer_Account__c> customerAccountList)
    {
        customerDepartmentList.addAll([SELECT Id, Name, Division_cd__c, Customer_Id__c FROM Department__c WHERE 
                                       Name IN :departmentSKPIdList AND Division_cd__c IN :customerDivisionList
                                       AND Customer_Id__c IN :customerAccountList]);
        Map<Id, Map<Id, Map<String, Department__c>>> mapCustIdDivIdSKPDeptIdToDepartment = new Map<Id, Map<Id, Map<String, Department__c>>>();
        for(Department__c dept : customerDepartmentList)
        {
            //Department_Unique_ID__c, Division_cd__c, Customer_Id__c
            Map<Id, Map<String, Department__c>> mapDivIdSKPDeptIdToDepartment = mapCustIdDivIdSKPDeptIdToDepartment.get(dept.Customer_Id__c);
            if(mapDivIdSKPDeptIdToDepartment == null) {
                mapDivIdSKPDeptIdToDepartment = new Map<Id, Map<String, Department__c>>();
            }
            Map<String, Department__c> mapSKPIDToDepartment = mapDivIdSKPDeptIdToDepartment.get(dept.Division_cd__c);
            if(mapSKPIDToDepartment == null) {
                mapSKPIDToDepartment = new Map<String, Department__c>();
            }
            if(mapSKPIDToDepartment.get(dept.Name) != null) {
                continue;
            }
            mapSKPIDToDepartment.put(dept.Name, dept);
            mapDivIdSKPDeptIdToDepartment.put(dept.Division_cd__c, mapSKPIDToDepartment);
            mapCustIdDivIdSKPDeptIdToDepartment.put(dept.Customer_Id__c, mapDivIdSKPDeptIdToDepartment);
        }
        return mapCustIdDivIdSKPDeptIdToDepartment;
    }
    /**
* @name getCustomerContacts
* @description Returns a map of Customer Id to a map of Division Id to a map of Department Id to a Map of email to Contact record.
**/
    /*Gitlab:13068-start
* public static Map<Id, Map<String, Map<String, Map<String, Contact>>>> getCustomerContacts(Set<String> contactEmailList, 
List<NAS_Authorized__c> authorizedList,
List<Department__c> customerDepartmentList, 
List<Division__c> customerDivisionList,
List<IM_Customer_Account__c> customerAccountList)
{
authorizedList.addAll([SELECT NAS_Contact__c, NAS_Contact__r.Id, NAS_Contact__r.Email, 
NAS_Customer_Account__c, NAS_Division__c, NAS_Department__c FROM 
NAS_Authorized__c WHERE NAS_Contact__r.Email IN :contactEmailList 
AND NAS_Customer_Account__c IN :customerAccountList 
AND (NAS_Division__c IN :customerDivisionList OR NAS_Division__c = null)
AND (NAS_Department__c IN :customerDepartmentList OR NAS_Department__c = null)
AND NAS_Status__c = :NAS_Constants.AUTHORIZED_ACTIVE_STATUS ORDER BY LastModifiedDate]);
Map<Id, Map<String, Map<String, Map<String, Contact>>>> mapCustIdDivIdDeptIdEmailToContact = 
new Map<Id, Map<String, Map<String, Map<String, Contact>>>>();
for(NAS_Authorized__c auth : authorizedList)
{
//NAS_Contact__c, NAS_Contact__r.Id, NAS_Contact__r.Email, NAS_Customer_Account__c, 
//NAS_Division__c, NAS_Department__c
Map<String, Map<String, Map<String, Contact>>> mapDivIdDeptIdEmailToContact = 
mapCustIdDivIdDeptIdEmailToContact.get(auth.NAS_Customer_Account__c);
if(mapDivIdDeptIdEmailToContact == null)
mapDivIdDeptIdEmailToContact = new Map<String, Map<String, Map<String, Contact>>>();
Map<String, Map<String, Contact>> mapDeptIdEmailToContact = mapDivIdDeptIdEmailToContact.get(auth.NAS_Division__c);
if(auth.NAS_Division__c == null)
mapDeptIdEmailToContact = mapDivIdDeptIdEmailToContact.get('Master');
if(mapDeptIdEmailToContact == null)
mapDeptIdEmailToContact = new Map<String, Map<String, Contact>>();

Map<String, Contact> mapEmailToContact = mapDeptIdEmailToContact.get(auth.NAS_Department__c);
if(auth.NAS_Department__c == null)
mapEmailToContact = mapDeptIdEmailToContact.get('Master');
if(mapEmailToContact == null) {
mapEmailToContact = new Map<String, Contact>();
}
if(mapEmailToContact.get(auth.NAS_Contact__r.Email) != null) {
continue;
}
mapEmailToContact.put(auth.NAS_Contact__r.Email, auth.NAS_Contact__r);
mapDeptIdEmailToContact.put(auth.NAS_Department__c, mapEmailToContact);
mapDivIdDeptIdEmailToContact.put(auth.NAS_Division__c, mapDeptIdEmailToContact);
mapCustIdDivIdDeptIdEmailToContact.put(auth.NAS_Customer_Account__c, mapDivIdDeptIdEmailToContact);
}
return mapCustIdDivIdDeptIdEmailToContact;
} 
Gitlab:13068-Stop*/
    
    /**
* @name createCECommunicatorCases
* @description Creates a list of CE Communicator cases and optionally inserts the list. Returns the list of case.
**/
    
    
    // added code to capture error handling by gouthami for case#10942249
    
    public static List<Case> createCECommunicatorCases(List<NAS_DataTypeFactory.CECommEvent> eventList)
    {
        List<Case> caseList = new List<Case>();
        for(NAS_DataTypeFactory.CECommEvent evt : eventList)
            caseList.add(NAS_DataFactory.createCECommunicatorCase(evt, evt.skpCustomer));
        Database.SaveResult[] srList= null;
        
        if(!caseList.isEmpty())
            srList= Database.Insert(caseList, false);
        for(Integer i=0;i<srList.size();i++)
        {
            if(!srList[i].isSuccess())
            {
                string msg ;
                for(Database.Error err : srList[i].getErrors()) 
                {
                    msg =  err.getMessage() + err.getStatusCode();
                }
                NAS_ErrorLogger.log(NAS_GetReplicationEventsBatchable.class.getName(),msg,JSON.serialize(srList[i]));
            }
        }
        return caseList;
    } 
    
    
    
    
    
    
    /**
* @name createCECommunicatorCase
* @description Constructs a Case record from a replication event data retrieved from SKP API.
* Returns the case record. Does not insert the record.
**/
    public static Case createCECommunicatorCase(NAS_DataTypeFactory.CECommEvent evt, 
                                                NAS_DataTypeFactory.CECommSKPCustomer skpCustomer) {
                                                    //─────────────────────────────────────────────────────────────────────────────────────┐
                                                    //Get Related Master Data Start 
                                                    IM_Customer_Account__c custAccount = skpCustomer.mapSKPIDToCustomerAccount.get(evt.eventFieldData.get('CUSTOMER_ID'));
                                                    if(custAccount == null)
                                                        custAccount = new IM_Customer_Account__c();
                                                    
                                                    Map<String, Division__c> mapSKPIDToDivision = skpCustomer.mapCustIdSKPDivIdToDivision.get(custAccount.Id);
                                                    if(mapSKPIDToDivision == null)
                                                        mapSKPIDToDivision = new Map<String, Division__c>();
                                                    Division__c custDivision = mapSKPIDToDivision.get(evt.eventFieldData.get('DIVISION_ID'));
                                                    if(custDivision == null)
                                                        custDivision = new Division__c();
                                                    if(custDivision == null)
                                                        custDivision = new Division__c();
                                                    
                                                    Map<Id, Map<String, Department__c>> mapDivIdSKPDeptIdToDepartment = skpCustomer.mapCustIdDivIdSKPDeptIdToDepartment.get(custAccount.Id);
                                                    if(mapDivIdSKPDeptIdToDepartment == null)
                                                        mapDivIdSKPDeptIdToDepartment = new Map<Id, Map<String, Department__c>>();
                                                    Map<String, Department__c> mapSKPIDToDepartment = mapDivIdSKPDeptIdToDepartment.get(custDivision.Id);
                                                    if(mapSKPIDToDepartment == null)
                                                        mapSKPIDToDepartment = new Map<String, Department__c>();
                                                    Department__c custDepartment = mapSKPIDToDepartment.get(evt.eventFieldData.get('DEPARTMENT_ID'));
                                                    if(custDepartment == null)
                                                        custDepartment = new Department__c();
                                                    if(custDepartment == null)
                                                        custDepartment = new Department__c();
                                                    
                                                    /*             Map<String, Map<String, Map<String, Contact>>> mapDivIdDeptIdEmailToContact = 
skpCustomer.mapCustIdDivIdDeptIdEmailToContact.get(custAccount.Id);
if(mapDivIdDeptIdEmailToContact == null) 
mapDivIdDeptIdEmailToContact = new Map<String, Map<String, Map<String, Contact>>>();
Map<String, Map<String, Contact>> mapDeptIdEmailToContact = mapDivIdDeptIdEmailToContact.get(custDivision.Id);
if(mapDeptIdEmailToContact == null)
mapDeptIdEmailToContact = new Map<String, Map<String, Contact>>();
Map<String, Contact> mapEmailToContact = mapDeptIdEmailToContact.get(custDepartment.Id);
if(mapEmailToContact == null)
mapEmailToContact = new Map<String, Contact>();
Contact cont = mapEmailToContact.get(evt.eventFieldData.get('CONTACT_EMAIL'));
if(cont == null)*/
                                                    Contact cont = new Contact(); 
                                                    //Get Related Master Data End
                                                    //─────────────────────────────────────────────────────────────────────────────────────┘
                                                    
                                                    Case cs = new Case();
                                                    
                                                    //─────────────────────────────────────────────────────────────────────────────────────┐
                                                    //Case Field Mapping Start
                                                    cs.NAS_CECOMM_Event_Status__c = NAS_Constants.CECOMM_CREATED;
                                                    cs.NAS_External_ID__c = NAS_Constants.CECOMM + evt.eventId;
                                                    cs.Customer_Id__c = custAccount.Id;
                                                    cs.AccountId = custAccount.IM_Account__c;
                                                    cs.ContactId = cont.Id;
                                                    cs.IM_Employee_Contact__c = UserInfo.getUserId();
                                                    //  cs.Division_ID__c = custDivision.Id;
                                                    //  cs.Department_ID__c = custDepartment.Id;
                                                    if(NAS_Constants.CECOMM_CASE_OWNER_QUEUE_ID != null)
                                                        cs.OwnerId = NAS_Constants.CECOMM_CASE_OWNER_QUEUE_ID;
                                                    cs.RecordTypeId = NAS_DataFactory.getRecordTypeId('Case', NAS_Constants.CECOMM_CASE_RECORDTYPE);
                                                    cs.Status = NAS_Constants.NEW_CECOMM_CASE_CASE_STATUS;
                                                    cs.Origin = NAS_Constants.CECOMM_ORIGIN;
                                                    cs.Priority = NAS_Constants.DEFAULT_CASE_PRIOROTY;
                                                    cs.Subject = NAS_Constants.SUBJECT_PREFIX_CECOMM_CASE + ' ' + evt.eventFieldData.get('CUSTOMER_ID');
                                                    cs.NAS_Communicator_Id__c = evt.eventFieldData.get('COMM_ID');
                                                    cs.NAS_Order_Number__c = evt.eventFieldData.get('ORDER_NUMBER');
                                                    String description = 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('COMMENTS', evt.eventFieldData.get('COMMENTS')) + 
                                                        NAS_TransformationFactory.ifNull(cs.Customer_Id__c, NAS_TransformationFactory.getNewLineTerminatedText('CUSTOMER_ID', evt.eventFieldData.get('CUSTOMER_ID'))) +
                                                        // NAS_TransformationFactory.ifNull(cs.Division_ID__c, NAS_TransformationFactory.getNewLineTerminatedText('DIVISION_ID', evt.eventFieldData.get('DIVISION_ID'))) +
                                                        // NAS_TransformationFactory.ifNull(cs.Department_ID__c, NAS_TransformationFactory.getNewLineTerminatedText('DEPARTMENT_ID', evt.eventFieldData.get('DEPARTMENT_ID'))) +
                                                        NAS_TransformationFactory.ifNull(cs.ContactId, NAS_TransformationFactory.getNewLineTerminatedText('CONTACT_EMAIL', evt.eventFieldData.get('CONTACT_EMAIL'))) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('TYPE_CODE', evt.eventFieldData.get('TYPE_CODE')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('TYPE_CODE_DESC', evt.eventFieldData.get('TYPE_CODE_DESC'))  + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('COMM_ID', evt.eventFieldData.get('COMM_ID')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('COMM_STATUS', evt.eventFieldData.get('COMM_STATUS')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('DRIVER_NAME_1', evt.eventFieldData.get('DRIVER_NAME_1')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('ORDER_DATE', evt.eventFieldData.get('ORDER_DATE')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('ORDER_TYPE', evt.eventFieldData.get('ORDER_TYPE')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('ORDER_TYPE_DESC', evt.eventFieldData.get('ORDER_TYPE_DESC')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('PREREQ_EVENT_ID', evt.eventFieldData.get('PREREQ_EVENT_ID')) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('PRIORITY_CODE', evt.eventFieldData.get('PRIORITY_CODE')) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('PRIORITY_DESC', evt.eventFieldData.get('PRIORITY_DESC')) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('CONT_CODE', evt.eventFieldData.get('CONT_CODE')) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('CONT_CODE_DESC', evt.eventFieldData.get('CONT_CODE_DESC')) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('IMRM_CONTACT', evt.eventFieldData.get('IMRM_CONTACT')) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('INVOICE_DATE', evt.eventFieldData.get('INVOICE_DATE')) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('INVOICE_NUMBER', evt.eventFieldData.get('INVOICE_NUMBER'));
                                                    NAS_TransformationFactory.getNewLineTerminatedText('COMM_ENTRY_DATE', evt.eventFieldData.get('COMM_ENTRY_DATE'));
                                                    NAS_TransformationFactory.getNewLineTerminatedText('COMM_ENTRY_TIME', evt.eventFieldData.get('COMM_ENTRY_TIME'));
                                                    NAS_TransformationFactory.getNewLineTerminatedText('createDateTime', evt.eventFieldData.get('createDateTime'));
                                                    NAS_TransformationFactory.getNewLineTerminatedText('createUserId', evt.eventFieldData.get('createUserId'));
                                                    NAS_TransformationFactory.getNewLineTerminatedText('transactionDateTime', evt.eventFieldData.get('transactionDateTime'));
                                                    NAS_TransformationFactory.getNewLineTerminatedText('transactionUserId', evt.eventFieldData.get('transactionUserId'));
                                                    NAS_TransformationFactory.getNewLineTerminatedText('Archive', evt.eventFieldData.get('Archive'));
                                                    
                                                    description = description.left(4000);
                                                    cs.Description = description;
                                                    
                                                    //Case Field Mapping End
                                                    //─────────────────────────────────────────────────────────────────────────────────────┘
                                                    return cs;
                                                }
    /**
* @name createIMCSupportCase
* @description Create a Case from imcFormData and set imcFormResponse accordingly.
**/
    public static void createIMCSupportCase(NAS_DataTypeFactory.NAS_IMCFormData imcFormData, 
                                            NAS_DataTypeFactory.NAS_IMCFormResponse imcFormResponse) {
                                                try
                                                {
                                                    //─────────────────────────────────────────────────────────────────────────────────────┐
                                                    //Get Related Master Data Start
                                                    IM_Customer_Account__c custAccount = NAS_DataFactory.getCustomerAccount(imcFormData.custID);
                                                    Division__c custDivision = NAS_DataFactory.getCustomerDivision(imcFormData.divisionId, 
                                                                                                                   custAccount.Id);
                                                    Department__c custDepartment = NAS_DataFactory.getCustomerDepartment(imcFormData.departmentId, 
                                                                                                                         custDivision.Id, 
                                                                                                                         custAccount.Id);
                                                    /*Gitlab - 12562 - Start
Contact cont = NAS_DataFactory.getCustomerContact(imcFormData.contactEmail, custAccount.Id);

Gitlab - 12562 - Stop*/
                                                    Map<String, Map<String, Map<String, String>>> typeCategoryMapping = NAS_DataFactory.getTypeCategoryMapping();
                                                    
                                                    String typeValue = null;//typeCategoryMapping.get(NAS_Constants.TYPEVALUE).get(imcFormData.issueType);
                                                    String category = null;//typeCategoryMapping.get(NAS_Constants.CATEGORY).get(imcFormData.category);
                                                    Id queueId = null;
                                                    Map<String, Map<String, String>> categoryMap = typeCategoryMapping.get(imcFormData.issueType);
                                                    if(categoryMap != null)
                                                    {
                                                        Map<String, String> valueMap = categoryMap.get(imcFormData.category);
                                                        if(valueMap != null)
                                                        {
                                                            typeValue = valueMap.get(NAS_Constants.TYPEVALUE);
                                                            category = valueMap.get(NAS_Constants.CATEGORY);
                                                            queueId = valueMap.get(NAS_Constants.QUEUE);
                                                        }
                                                    }
                                                    //Get Related Master Data End
                                                    //─────────────────────────────────────────────────────────────────────────────────────┘
                                                    
                                                    Case cs = new Case();
                                                    
                                                    //─────────────────────────────────────────────────────────────────────────────────────┐
                                                    //Case Field Mapping Start
                                                    cs.Customer_Id__c = custAccount.Id;
                                                    cs.AccountId = custAccount.IM_Account__c;
                                                    /*Gitlab - 12562 - Start
cs.ContactId = cont.Id;
Gitlab - 12562 - Stop*/
                                                    cs.IM_Employee_Contact__c = UserInfo.getUserId();
                                                    //  cs.Division_ID__c = custDivision.Id;
                                                    //  cs.Department_ID__c = custDepartment.Id;
                                                    cs.RecordTypeId = NAS_DataFactory.getRecordTypeId('Case', NAS_Constants.IMC_CASE_RECORDTYPE);
                                                    cs.Status = NAS_Constants.NEW_IMC_CASE_STATUS;
                                                    cs.Type = typeValue;
                                                    cs.Case_Category__c = category;
                                                    cs.Origin = NAS_Constants.IMCORIGIN;
                                                    cs.Priority = NAS_Constants.DEFAULT_CASE_PRIOROTY;
                                                    cs.Subject = NAS_Constants.IM_CASE_SUBJECT_PREFIX + ' ' + imcFormData.custID;
                                                    //cs.NAS_External_ID__c = NAS_Constants.IMC + imcFormData.requestID;
                                                    if(queueId != null)
                                                        cs.OwnerId = queueId;
                                                    cs.Description = 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('description', imcFormData.description) +
                                                        NAS_TransformationFactory.ifNull(cs.Type, NAS_TransformationFactory.getNewLineTerminatedText('issueType', imcFormData.issueType)) +
                                                        NAS_TransformationFactory.ifNull(cs.Case_Category__c, NAS_TransformationFactory.getNewLineTerminatedText('category', imcFormData.category)) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('lob', imcFormData.lob) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('orderNo', imcFormData.orderNo) +
                                                        NAS_TransformationFactory.ifNull(cs.Customer_Id__c, NAS_TransformationFactory.getNewLineTerminatedText('custID', imcFormData.custID)) +
                                                        // NAS_TransformationFactory.ifNull(cs.Division_ID__c, NAS_TransformationFactory.getNewLineTerminatedText('divisionId', imcFormData.divisionId)) +
                                                        // NAS_TransformationFactory.ifNull(cs.Department_ID__c, NAS_TransformationFactory.getNewLineTerminatedText('departmentId', imcFormData.departmentId)) +
                                                        NAS_TransformationFactory.ifNull(cs.ContactId, NAS_TransformationFactory.getNewLineTerminatedText('contactName', imcFormData.contactName)) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('contactPhone', imcFormData.contactPhone) +
                                                        NAS_TransformationFactory.ifNull(cs.ContactId, NAS_TransformationFactory.getNewLineTerminatedText('contactEmail', imcFormData.contactEmail)) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('preferredContact', imcFormData.preferredContact) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('invoiceNo', imcFormData.invoiceNo) +
                                                        NAS_TransformationFactory.getNewLineTerminatedText('isNewRequest', imcFormData.isNewRequest) + 
                                                        NAS_TransformationFactory.getNewLineTerminatedText('language', imcFormData.language);
                                                    
                                                    
                                                    //Case Field Mapping End
                                                    //─────────────────────────────────────────────────────────────────────────────────────┘
                                                    INSERT cs;
                                                    imcFormResponse.responseStatus = NAS_Constants.SUCCESS;
                                                    imcFormResponse.caseId = [SELECT CaseNumber, Id FROM Case WHERE Id = :cs.Id].CaseNumber;
                                                    imcFormResponse.httpStatus = 200;
                                                    imcFormResponse.message = NAS_Constants.SUCCESS_MESSAGE;
                                                }
                                                catch(Exception e)
                                                {   
                                                 imcFormResponse.httpStatus = 200;
                                                 imcFormResponse.responseStatus = NAS_Constants.FAILURE;
                                                 imcFormResponse.message = e.getMessage() + '. ' + NAS_Constants.FAILURE_MESSAGE;
                                                 NAS_ErrorLogger.log(NAS_IMCContactUsRestService.class.getName(), 
                                                                     imcFormResponse.message + ' ' + e.getStackTraceString(),
                                                                     JSON.serialize(imcFormData));
                                                }
                                            }
    /**
* @name getCustomerAccount
* @description Return IM_Customer_Account__c record from customer Id
**/
    public static IM_Customer_Account__c getCustomerAccount(String custID) {
        // TO DO : Update Name with external id once confirmed uniqueness.
        List<IM_Customer_Account__c> customerAccountList = [SELECT Id, IM_Account__c FROM 
                                                            IM_Customer_Account__c WHERE Name = :custId AND Source_System__c = 
                                                            :NAS_Constants.SOURCE_SYSTEM_CODE_SKP_NA ORDER BY LastModifiedDate DESC];
        if(customerAccountList.isEmpty())
            return new IM_Customer_Account__c();
        else
            return customerAccountList[0];
    }
    /**
* @name getCustomerDivision
* @description Return Division__c record from divisionId and customerId
**/
    public static Division__c getCustomerDivision(String divisionId, String customerId) {
        List<Division__c> customerDivisionList = [SELECT Id FROM Division__c WHERE Customer_Id__c = :customerId
                                                  AND Name= :divisionId];
        if(customerDivisionList.isEmpty())
            return new Division__c();
        else
            return customerDivisionList[0];
    }
    /**
* @name getCustomerDepartment
* @description Return Department__c record from departmentId, divisionId and customerId
**/
    public static Department__c getCustomerDepartment(String departmentId, Id divisionId, Id customerId) {
        List<Department__c> customerDepartmentList = [SELECT Id FROM Department__c WHERE 
                                                      Name = :departmentId AND Division_cd__c = :divisionId
                                                      AND Customer_Id__c = :customerId];
        if(customerDepartmentList.isEmpty())
            return new Department__c();
        else
            return customerDepartmentList[0];
    }
    /**
* @name recordTypeIds
* @description Singleton method to return record type id for a given SObject Type & Developer Name
**/
    private static Map<String, Map<String, Id>> recordTypeIds {get;set;}
    public static Id getRecordTypeId(String sObjectType, String developerName) {
        if(recordTypeIds == null)
            recordTypeIds = new Map<String, Map<String, Id>>();
        Map<String, Id> recordTypeIds4SObject = recordTypeIds.get(sObjectType);
        Id recordTypeId = null;
        if(recordTypeIds4SObject != null)
        {
            recordTypeId = recordTypeIds4SObject.get(developerName);
        }
        else
        {
            recordTypeIds4SObject = new Map<String, Id>();
            recordTypeIds.put(sObjectType, recordTypeIds4SObject);
        }
        if(recordTypeId == null)
        {
            List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE SobjectType = :sObjectType
                                            AND DeveloperName = :developerName];
            if(!recordTypes.isEmpty())
            {
                recordTypeId = recordTypes[0].Id;
                recordTypeIds4SObject.put(developerName, recordTypeId);
            }
        }
        return recordTypeId;
    }
    /**
* @name getCustomerContact
* @description Return Contact record from customer email
**/
    /* Gitlab - 12562 - Start
public static Contact getCustomerContact(String email, Id customerId) {
List<NAS_Authorized__c> authorizedList = [SELECT NAS_Contact__c FROM NAS_Authorized__c WHERE 
NAS_Contact__r.Email = :email AND NAS_Customer_Account__c = 
:customerId AND NAS_Status__c = 
:NAS_Constants.AUTHORIZED_ACTIVE_STATUS LIMIT 1];
List<Contact> contactList = new List<Contact>();
if(!authorizedList.isEmpty())
contactList = [SELECT Id FROM Contact WHERE Id = :authorizedList[0].NAS_Contact__c];
if(contactList.isEmpty())
return new Contact();
else
return contactList[0]; 

}Gitlab - 12562 - Stop*/
    private static List<Group> getQueueList(List<String> queueDeveloperNameList)
    {
        List<Group> queueList = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :queueDeveloperNameList 
                                 AND Type = 'Queue'];
        return queueList;
    }
    /**
* @name getTypeCategoryMapping
* @description Singleton implementation to return Mapping of IMC and SF Type & Category from 
* custom metadata type NAS_IMC_SF_Type_Category_Mapping__mdt
**/
    private static Map<String, Map<String, Map<String, String>>> typeCategoryMapping {get;set;}
    public static Map<String, Map<String, Map<String, String>>> getTypeCategoryMapping() {
        if(typeCategoryMapping == null)
        {
            typeCategoryMapping = (Map<String, Map<String, Map<String, String>>>) 
                NAS_Utilities.getOrgCache(NAS_Constants.KEY_ORG_CACHE_TYPE_CATEGORY_MAPPING, false);
        }
        return typeCategoryMapping;
    }
    /**
* @name queryTypeCategoryMapping
* @description Query from custom metadata type NAS_IMC_SF_Type_Category_Mapping__mdt, creates a map
* with metadata and queue ids.
**/
    public static Map<String, Map<String, Map<String, String>>> queryTypeCategoryMapping() {
        List<NAS_IMC_SF_Type_Category_Mapping__mdt> typeCategoryMappingMetadataList = [SELECT NAS_IMC_Type__c, 
                                                                                       NAS_SF_Type__c, NAS_IMC_Category__c, NAS_SF_Category__c, NAS_Owner_Queue__c FROM 
                                                                                       NAS_IMC_SF_Type_Category_Mapping__mdt];
        List<String> queueDeveloperNameList = new List<String>();
        for(NAS_IMC_SF_Type_Category_Mapping__mdt  tcmap : typeCategoryMappingMetadataList)
            queueDeveloperNameList.add(tcmap.NAS_Owner_Queue__c);
        
        List<Group> queueList = NAS_DataFactory.getQueueList(queueDeveloperNameList);
        
        Map<String, Id> queueIdMap = new Map<String, Id>();
        for(Group g : queueList)
            queueIdMap.put(g.DeveloperName, g.Id);
        
        typeCategoryMapping = new Map<String, Map<String, Map<String, String>>>();
        for(NAS_IMC_SF_Type_Category_Mapping__mdt  tcmap : typeCategoryMappingMetadataList)
        {
            Map<String, String> valueMap = new Map<String, String>();
            valueMap.put(NAS_Constants.TYPEVALUE, tcmap.NAS_SF_Type__c);
            valueMap.put(NAS_Constants.CATEGORY, tcmap.NAS_SF_Category__c);
            valueMap.put(NAS_Constants.QUEUE, queueIdMap.get(tcmap.NAS_Owner_Queue__c));
            Map<String, Map<String, String>> typeMap = typeCategoryMapping.get(tcmap.NAS_IMC_Type__c);
            if(typeMap == null)
                typeMap = new Map<String, Map<String, String>>();
            typeMap.put(tcmap.NAS_IMC_Category__c, valueMap);
            typeCategoryMapping.put(tcmap.NAS_IMC_Type__c, typeMap);
        }
        return typeCategoryMapping;
    }
    /**
* @name getApplicationConfiguration
* @description Singleton implementation to return NAS Application Configuration from 
* custom metadata type NAS_Application_Configuration__mdt. 
* This method is test visible to test the reschedule functionality of recurring case scheduler. 
**/
    @testVisible
    private static Map<String, String> applicationConfiguration {get;set;}
    public static String getApplicationConfiguration(String configurationName) {
        if(applicationConfiguration == null)
        {
            applicationConfiguration = (Map<String, String>) 
                NAS_Utilities.getOrgCache(NAS_Constants.KEY_ORG_CACHE_APPLICATION_CONFIGURATION, false);
        }
        return applicationConfiguration.get(configurationName);
    }
    /**
* @name queryApplicationConfiguration
* @description Queries the Application Configuraiton metadata, creates a map of key value pair. 
* Puts additional configurations related to queue and base64 encoded WSG username. 
**/
    public static Map<String, String> queryApplicationConfiguration()
    {
        Map<String, String> applicationConfiguration = new Map<String, String>();
        List<String> queueDeveloperNameList = new List<String>();
        List<Id> caseTeamOmniQueuesList = new List<Id>();
        for(NAS_Application_Configuration__mdt  appConfig : [SELECT Id, DeveloperName, Value__c 
                                                             FROM NAS_Application_Configuration__mdt])
        {
            applicationConfiguration.put(appConfig.DeveloperName, appConfig.Value__c);
            if(appConfig.DeveloperName.startswith(NAS_Constants.KEY_CASE_TEAM_OMNI_QUEUE))
                queueDeveloperNameList.add(appConfig.Value__c);
            if(appConfig.DeveloperName == 'CECOMM_CASE_OWNER_QUEUE_NAME')
                queueDeveloperNameList.add(appConfig.Value__c);
        }
        List<Group> queueList = NAS_DataFactory.getQueueList(queueDeveloperNameList);
        for(Group q : queueList)
        {
            if(q.DeveloperName == applicationConfiguration.get('CECOMM_CASE_OWNER_QUEUE_NAME'))
                applicationConfiguration.put('CECOMM_CASE_OWNER_QUEUE_ID', q.Id);
            else
                caseTeamOmniQueuesList.add(q.Id);
        }
        applicationConfiguration.put(NAS_Constants.KEY_CASE_TEAM_OMNI_QUEUE, JSON.serialize(caseTeamOmniQueuesList));
        
        if(applicationConfiguration.get('WSG_USERNAME') != null)
            applicationConfiguration.put('WSG_USERNAME_B64', 
                                         EncodingUtil.base64Encode(
                                             Blob.valueOf(applicationConfiguration.get('WSG_USERNAME'))));
        return applicationConfiguration;
    }
    /**
* @name createRecurringCases
* @description Clones a list of recurring case record and constructs a list of NAS General support cases. 
* Inserts the list of new cases. Updates the recurring case record with future recurrence data.
* Updated return type to return NAS recurring Cases #31329
* Gitlab #34480 - Updated to handle failure of updation of NAS Recurring Support cases.
**/
    public RecurringCaseResultWrapper createRecurringCases(List<sObject> recurringCases){
        System.debug('Inside the method');
        RecurringCaseResultWrapper result = new RecurringCaseResultWrapper();
        List<Case> newGeneralSupportCaseList = new List<Case>();
        List<Case> updateRecurringSupportCaseList = new List<Case>();
        List<Case> updateRecurringSupportCaseListFinal = new List<Case>();        
        Set<Id> parentIds = new Set<Id>();//Added to store the NAS recurring casesids #31329
        List<NAS_Integration_Error__c> errorLogList=new List<NAS_Integration_Error__c>();//To store all exceptions related to NAS Recurring batch functionality:GitLab #31329
        for(sObject sObj : recurringCases)
        {
            Case recurringCase = (Case) sObj;
            //Clone Recurring Case to create new NAS_General_Support_Case
            Case c = recurringCase.clone();
            c.ParentId = sObj.Id;
            c.RecordTypeId = NAS_DataFactory.getRecordTypeId('Case', 
                                                             NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE);
            c.Status = NAS_Constants.NEW_RECURRING_CASE_STATUS;
            c.NAS_NEXT_CASE_CREATION_DATE__C = null;
            c.NAS_RECURRENCE_FREQUENCY__c = null;
            newGeneralSupportCaseList.add(c);            

            recurringCase.NAS_Next_Case_Creation_Date__c = 
                NAS_Utilities.getNextRecurrenceDate(recurringCase.NAS_Recurrence_Frequency__c);
            updateRecurringSupportCaseList.add(recurringCase);
        }
        try{//Added this logic to insert partial sucess records and handle the failure records : GitLab #31329
            if(!newGeneralSupportCaseList.isEmpty()){                
                Database.SaveResult[] results = Database.insert(newGeneralSupportCaseList, false); // false for partial success
                List<Case> failedCases = new List<Case>();				                 
                // Process insert results
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        Case failedCase = newGeneralSupportCaseList[i];
                        failedCases.add(failedCase);                        
                        // Collect parent caseId of failue records
                        if (failedCase.ParentId != null) {
                            result.failedInsertParentIds.add(failedCase.ParentId);
                        }                        
                        // Log errors
                        for (Database.Error err : results[i].getErrors()) {
                            NAS_Integration_Error__c errorLog = new NAS_Integration_Error__c(
                                NAS_Apex_Class_Name__c = ('Child Case Error: '+ NAS_DataFactory.class.getName()),
                                NAS_Error_Message__c = err.getMessage(),
                                NAS_Request_Data__c = failedCase.ParentId
                            );
                            errorLogList.add(errorLog);                            
                        }
                    }
                }                
            }
            for(Case cse : updateRecurringSupportCaseList ){
                if(!parentIds.contains(cse.id) ){                    
                    updateRecurringSupportCaseListFinal.add(cse);
                }
            }
            if(!updateRecurringSupportCaseListFinal.isEmpty()){
                //UPDATE updateRecurringSupportCaseListFinal;
                //Added Logic for Partial update of NAS Recurring Support Cases and log error if there is issue. For reference, check Gitlab #34480
				Database.SaveResult[] updateResults = Database.update(updateRecurringSupportCaseListFinal, false); // false = partial success
                for (Integer i = 0; i < updateResults.size(); i++) {
                    if (!updateResults[i].isSuccess()) {
                        Case failedRecurringCase = updateRecurringSupportCaseListFinal[i];
                        // Capture failed update case id
    					result.failedUpdateCaseIds.add(failedRecurringCase.Id);
                        // Log update errors
                        for (Database.Error err : updateResults[i].getErrors()) {
                            System.debug('Recurring Case Update Failed: ' +
                                          failedRecurringCase.Id + ' - Error: ' + err.getMessage());
            
                            NAS_Integration_Error__c errorLog = new NAS_Integration_Error__c(
                                NAS_Apex_Class_Name__c = NAS_DataFactory.class.getName(),
                                NAS_Error_Message__c = err.getMessage(),
                                NAS_Request_Data__c = failedRecurringCase.Id
                            );
                            errorLogList.add(errorLog);
                        }
                    }
                } 
            }
            if(!errorLogList.isEmpty()){
                //INSERT errorLogList;
                //Added Logic for Partial insert of log error. For reference, check Gitlab #34480
				Database.SaveResult[] logResults = Database.insert(errorLogList, false);  // partial success
            }
        }
        catch(Exception e){        
            NAS_ErrorLogger.log(+NAS_DataFactory.class.getName(), e.getMessage(),e.getStackTraceString());
        }
        return result;
    }
    /**
* @name sendErrorNotification
* @description To send bell notifications to the agents when the creation of child GSC cases for 
* NAS Recurring Support cases fails  
* Gitlab #31329
**/
    public static void sendErrorNotification(Id ownerId, id typeId, string recordId,string caseNumber  ){
        Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
        customNotificationObj.setBody('Please create a child case manually for the NAS recurring case : '+caseNumber+'. Auto-creation failed.');
        customNotificationObj.setTitle('Child Case is not created');
        customNotificationObj.setNotificationTypeId(typeId);
        customNotificationObj.setSenderId(ownerId);
        customNotificationObj.setTargetId(recordId);
        customNotificationObj.send(new Set<String> {ownerId});
     }
    
    /**
    * @name sendEmailNotification
    * @description To send Email notifications to the agents/Managers when the creation of child GSC cases for 
    * NAS Recurring Support cases fails  
    * Gitlab #31329
    **/
    public static Messaging.SingleEmailMessage sendEmailNotification(List<String> toAddress, String subject, String body) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        mail.setsaveAsActivity(false);
        // Set the from address
        mail.setOrgWideEmailAddressId(Id.valueOf(Label.NAS_Recurring_From_Address));
        // Set the to address
        mail.setToAddresses(toAddress);        
        // Set email subject and body
        mail.setSubject(subject);
        mail.setPlainTextBody(body);        
        return mail;        
    }
    /**
    * @name getEmailBody
    * @description To generate email body for the email template 
    * Gitlab #31329
    **/
    public static string getEmailBody(String caseNumber, string cseId){        
        String emailBody = 
            Label.NAS_Recurring_Dear_Team +'\n\n'+
            Label.NAS_Recurring_Body1 +'\n'+
            Label.NAS_Recurring_Body2+caseNumber+' \n\n' +                
            Label.NAS_Recurring_Body3 +EncodingUtil.urlDecode(URL.getSalesforceBaseUrl().toExternalForm() + '/' + cseId, 'UTF-8')+'\n\n'+ 
            Label.NAS_Recurring_regards+'\n'+
            Label.NAS_Recurring_Support_Team;
        return emailBody;
    }
    /**
    * @name getEmailIds
    * @description To get emailids from the NAS App configCustom metadata
    * Gitlab #31329
    **/
    public static List<String> getEmailIds(){        
        List<String> notifyEmails = new List<String>();        
        notifyEmails = NAS_Constants.NAS_RECURRING_EMAIL_RECIPIENTS.split(';');        
        return notifyEmails;
    }
    /**
    * @name sendNotifications
    * @description Send an email and custom notifications to the owner of NAS Recurring Cases if there is a failure 
    * in inserting GS Cases.
    * Gitlab #31329
    **/
    public static void sendNotifications(set<id> parentAllds){
          try{
            Id typeId = Id.valueOf(Label.CustomNotificationId);           
            List<String> cseNumbers = new List<String>();//To store all failure NAS Recurring Cases
            List<String> cseNumbersFew = new List<String>();//To store failure notifications of NAS Recurring Cases
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();            
            for(Case cse : [SELECT id, CaseNumber,ownerId,owner.IsActive,owner.email,IM_Employee_Contact__c,IM_Employee_Contact__r.IsActive,IM_Employee_Contact__r.Email from Case where id IN:parentAllds]){
                   if (String.valueOf(cse.ownerId).startsWith('005') && cse.owner.IsActive) {//Owner is a User
                    String emailBody = getEmailBody(cse.CaseNumber,cse.id);
                    String[] toAddresses = new String[] {cse.owner.email};
                        lstMails.add(sendEmailNotification(
                            toAddresses,
                            Label.NAS_Recurring_Subject_Agents,
                            emailBody
                        	));                
                    sendErrorNotification(cse.ownerid,typeId,cse.id,cse.caseNumber);                
                    
                }if(String.valueOf(cse.ownerId).startsWith('00G') && cse.IM_Employee_Contact__c != null && cse.IM_Employee_Contact__r.IsActive) {//Owner is a Queue
                    String emailBody = getEmailBody(cse.CaseNumber,cse.id);
                    String[] toAddresses = new String[] {cse.IM_Employee_Contact__r.Email};
                        lstMails.add(sendEmailNotification(
                            toAddresses,
                            Label.NAS_Recurring_Subject_Agents,
                            emailBody
                        ));
                    sendErrorNotification(cse.IM_Employee_Contact__c,typeId,cse.id,cse.caseNumber);
                }if((String.valueOf(cse.ownerId).startsWith('00G') && cse.IM_Employee_Contact__c == null) || (cse.IM_Employee_Contact__c != null && !cse.IM_Employee_Contact__r.IsActive)){
                    cseNumbersFew.add(cse.caseNumber);                   
                }
                cseNumbers.add(cse.caseNumber);
            }                            
            List<String> notifyEmails = getEmailIds();
            boolean notifyManagers = shouldSendEmailToManagers();
            if(cseNumbers.size()>0 &&!notifyEmails.isEmpty()&& notifyManagers){//To notify the consolidated failure cases to the managers                
                String emailBody = 
                    Label.NAS_Recurring_Dear_Team +'\n\n'+                   
                    Label.NAS_Recurring_Manager_Body1 + String.join(cseNumbers, ',') + '\n\n' +                    
                    Label.NAS_Recurring_Manager_Body2+'\n\n' +
                    (cseNumbersFew.size() > 0 
                     ? Label.NAS_Recurring_Manager_Body3 + String.join(cseNumbersFew, ',') + '.\n\n' 
                     : ''
                    ) +
                    Label.NAS_Recurring_regards+'\n' +
                    Label.NAS_Recurring_Support_Team;                
                lstMails.add(NAS_DataFactory.sendEmailNotification(
                    notifyEmails,
                   	Label.NAS_Recurring_Subject_Manager,
                    emailBody));                
            }
            if(lstMails.size()>0){
                Messaging.sendEmail(lstMails); 
            }            
        }catch(Exception e){            
            NAS_ErrorLogger.log(NAS_DataFactory.class.getName(), 
                                e.getMessage(),e.getStackTraceString());
        }        
    }
    /**
    * @name shouldSendEmailToManagers
    * @description Method To decide whether to send email notifications to the managers or not
    * 
    * Gitlab #31329
    **/
    public static boolean shouldSendEmailToManagers(){        
       List<NAS_Application_Configuration__mdt> nasAppConfigmdt = [SELECT id,Value__c FROM NAS_Application_Configuration__mdt WHERE DeveloperName =:NAS_Constants.EMAIL_NOTIFICATION_ACTIVATOR LIMIT 1]; 
       boolean notifyManagers;
       return notifyManagers = (nasAppConfigmdt.size()>0 && nasAppConfigmdt[0].Value__c != null &&  nasAppConfigmdt[0].Value__c == '1') ? true : false;
    }
    /**
    * @name sendUpdateFailureNotifications
    * @description Method to send email/chatter notification for failure of NAS Recurring Case updating "Next Case Creation Date" field. 
    * Gitlab #34480
    **/
    public static void sendUpdateFailureNotifications(Set<Id> failedCaseIds) {
		if (failedCaseIds == null || failedCaseIds.isEmpty()) return;
        
        // Query cases and owners defensively
        List<Case> cases = [
            SELECT Id,casenumber, OwnerId, 
                   Owner.Type,
                   Owner.IsActive,         // Only valid for User but safe
                   Owner.Email,            // Only valid for User, null for queue
                   IM_Employee_Contact__c,
                   IM_Employee_Contact__r.Id,
                   IM_Employee_Contact__r.IsActive,
                   IM_Employee_Contact__r.Email
            FROM Case
            WHERE Id IN :failedCaseIds
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    	List<FeedItem> chatterPosts = new List<FeedItem>();
        
        for (Case c : cases) {
            Id targetUserId = null;
        	Boolean sendEmail = false;
            List<String> recipientEmails = new List<String>();
          	if (c.IM_Employee_Contact__c != null && c.IM_Employee_Contact__r.IsActive && String.isNotBlank(c.IM_Employee_Contact__r.Email)) {
                targetUserId = c.IM_Employee_Contact__c;
                sendEmail = true;
                recipientEmails.add(c.IM_Employee_Contact__r.Email);
        	}
            else if (c.Owner.Type =='User' && c.Owner.IsActive && String.isNotBlank(c.Owner.Email)) {
                targetUserId = c.OwnerId;
                sendEmail = true;
                recipientEmails.add(c.Owner.Email);
        	}
            else {
                // Create chatter post to the case
                chatterPosts.add(new FeedItem(
                ParentId = c.Id,
                Body = Label.Recurring_Case_Update_Fail_Notification
            	));
        	}
        	 // Build email
            if (sendEmail && targetUserId != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(targetUserId);
                mail.setSaveAsActivity(false);
                mail.setOrgWideEmailAddressId(Id.valueOf(Label.NAS_Recurring_From_Address));
                mail.setSubject('⚠ Update Failure for Recurring Case ' + c.casenumber);
                mail.setPlainTextBody(
                    'Hello,\n\n' +
                    'The system was unable to update NAS Recurring Support Case: '+ c.casenumber + '.\n\n' + 
                    'Please update the Next Case Creation Date manually.\n\n' +
                    'Thank you.'
                );
                emails.add(mail);
            } 
        }
       	/************************************
         * SEND EMAILS IN CHUNKS OF 100
         ************************************/
        Integer emailBatchSize = 100;
        List<Messaging.SingleEmailMessage> emailChunk = new List<Messaging.SingleEmailMessage>();
    
        for (Integer i = 0; i < emails.size(); i++) {
    
            emailChunk.add(emails[i]);
    
            // When chunk is full OR at the last element → send
            if (emailChunk.size() == emailBatchSize || i == emails.size() - 1) {
                Messaging.sendEmail(emailChunk);
                emailChunk.clear();   // clear the chunk for next batch
            }
        }
    
    
        /************************************
         * INSERT CHATTER POSTS IN CHUNKS OF 10,000
         ************************************/
        Integer chatterBatchSize = 10000;
        List<FeedItem> chatterChunk = new List<FeedItem>();
    
        for (Integer i = 0; i < chatterPosts.size(); i++) {
    
            chatterChunk.add(chatterPosts[i]);
    
            if (chatterChunk.size() == chatterBatchSize || i == chatterPosts.size() - 1) {
                 // Insert chatter with partial success
        		Database.SaveResult[] chatterResults = Database.insert(chatterChunk, false);
                chatterChunk.clear();
            }
        }
    }
}