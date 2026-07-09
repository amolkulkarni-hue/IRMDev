/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Factory Class for Generating Test Data.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_TestDataFactory {
    /**
     * @name insertEmailMessages
     * @description Inserts email message records with one attachment each for the Case record. 
    **/
    public static List<EmailMessage> insertEmailMessages(Integer count, Case c){
        List<EmailMessage> emailMessageList = new List<EmailMessage>();
        for(Integer iCtr = 0; iCtr < count; ++iCtr)
        {
            emailMessageList.add(new EmailMessage(FromAddress = 'test@abc.org', Incoming = True, ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com', 
                            Subject = 'Test email', TextBody = '23456 ', ParentId = c.Id));
        }
        INSERT emailMessageList;
        List<ContentVersion> conentVersionList = new List<ContentVersion>();
        for(Integer iCtr = 0; iCtr < count; ++iCtr)
        {
            conentVersionList.add(new ContentVersion (
                Title = 'Test' + iCtr,
                PathOnClient = 'Text' + iCtr,
                VersionData = Blob.valueOf('Test Content' + iCtr),
                IsMajorVersion = true));
        }
        INSERT conentVersionList;
    
        List<ContentDocument> contentDocumentList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        for(Integer iCtr = 0; iCtr < contentDocumentList.size(); ++iCtr)
        {
            contentDocumentLinkList.add(new ContentDocumentLink(
                ContentDocumentId = contentDocumentList[iCtr].Id,
                LinkedEntityId = emailMessageList[iCtr].Id,
                ShareType = 'V'));
        }
        INSERT contentDocumentLinkList;
        
        return emailMessageList;
    }
    /**
     * @name constructTestUserIMCIntegration
     * @description Constructs an user with IMC Integration user profile.
    **/
    public static User constructTestUserIMCIntegration(){
        String uniqueUserName = 'NAS_IMCAPIOnly' + DateTime.now().getTime() + '@nasironmountain.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = :NAS_TestConstants.IMC_INTEGRATION_USER_PROFILE_NAME];
        UserRole role = [SELECT Id FROM UserRole WHERE NAME = :NAS_TestConstants.IMC_INTEGRATION_USER_ROLE];
        User u = new User(Alias = 'nasint', Email='imcintegrationuser' + DateTime.now().getTime() 
                          + '@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName, Country = NAS_TestConstants.IMC_INTEGRATION_USER_COUNTRY, 
                          UserRoleId = role.Id);
        return u;
    }
    
    /**
     * @name constructAccounts
     * @description Constructs a list of Account records for unit tests
    **/
    public static List<Account> constructAccounts(Integer cnt){
        List<Account> accountList = new List<Account>();
        for(Integer iCtr = 0; iCtr < cnt; ++iCtr)
        {
            Account a = new Account(Name = 'Account' + iCtr);
            
            accountList.add(a);
        }
        return accountList;
    }
    
    /**
     * @name constructCustomerAccounts
     * @description Constructs a list of Customer Account records for unit tests
    **/
    public static List<IM_Customer_Account__c> constructCustomerAccounts(Integer count, List<Account> accountList){
        List<IM_Customer_Account__c> customerAccountList = new List<IM_Customer_Account__c>();
        Integer counter = 0;
        for(Account ac : accountList)
        {
            for(Integer iCtr = 0; iCtr < count; ++iCtr)
            {
                IM_Customer_Account__c ca = new IM_Customer_Account__c(
                                        Name = 'CustomerAccount' + (counter + iCtr),
                                        RecordTypeId = NAS_DataFactory.getRecordTypeId('IM_Customer_Account__c', 
                                                       NAS_Constants.NA_CUSTOMER_ACCOUNT_RECORDTYPE),
                                        IM_Account__c = ac.Id,
                                        Source_System__c = NAS_Constants.SOURCE_SYSTEM_CODE_SKP_NA);
                
                customerAccountList.add(ca);
            }
            counter += count;
        }
        return customerAccountList;
    }

    /**
     * @name constructContacts
     * @description Constructs a list of Contact records for unit tests
    **/
    public static List<Contact> constructContacts(Integer count, List<Account> accountList){
        List<Contact> contactList = new List<Contact>();
        Integer counter = 0;
        for(Account a : accountList)
        {
            for(Integer iCtr = 0; iCtr < count; ++iCtr)
            {
                //Email = 'email' + (counter + iCtr) + '@email.com',
                Contact c = new Contact(LastName = 'Contact' + (counter + iCtr) + DateTime.now(),firstName = 'ContactFirst' + (counter + iCtr),
                                        Phone = '1234567890',
                                        AccountId = a.Id);
                
                contactList.add(c);
            }
            counter += count;
        }
        return contactList;
    }
    /**
     * @name constructDivisions
     * @description Constructs a list of Division records for each of the customer Accouts for unit tests
    **/
    public static List<Division__c> constructDivisions(Integer count, List<IM_Customer_Account__c> customerAccountList){
        List<Division__c> divisionList = new List<Division__c>();
        Integer counter = 0;
        for(IM_Customer_Account__c ca : customerAccountList)
        {
            for(Integer iCtr = 0; iCtr < count; ++iCtr)
            {
                Division__c div = new Division__c(Name = 'Div' + (counter + iCtr),
                                                  Division_Unique_Id__c = 'Div' + (counter + iCtr),
                                                  Customer_Id__c = ca.Id,
                                                  Source_System_Id__c = NAS_Constants.SOURCE_SYSTEM_CODE_SKP_NA);
                divisionList.add(div);
            }
            counter += count;
        }
        return divisionList;
    }
    /**
     * @name constructDepartments
     * @description Constructs a list of Department records for each of the Division under 
     * customer Accouts for unit tests
    **/
    public static List<Department__c> constructDepartments(Integer count, 
                                                           List<Division__c> divisionList){
        List<Department__c> departmentList = new List<Department__c>();
        Integer counter = 0;
        for(Division__c div : divisionList)
        {
            for(Integer iCtr = 0; iCtr < count; ++iCtr)
            {
                Department__c dept = new Department__c(Name = 'Dept' + (counter + iCtr),
                                                       Department_Unique_ID__c = 'Dept' + (counter + iCtr),
                                                       Division_cd__c = div.Id,
                                                       Customer_Id__c = div.Customer_Id__c,
                                                       Source_System_Id__c = NAS_Constants.SOURCE_SYSTEM_CODE_SKP_NA);
                departmentList.add(dept);
            }
            counter += count;
        }
        return departmentList;
    }
    
    /**
     * @name constructAuthorizedRecords
     * @description Constructs a list of Authorized records for unit tests
    **/
    /*Gitlab:13068-start
    public static List<NAS_Authorized__c> constructAuthorizedRecords(List<Contact> contactList,
                                                                     Integer count,
                                                                     List<Department__c> departmentList){
        List<NAS_Authorized__c> authorizedList = new List<NAS_Authorized__c>();
        Integer counter = 0;
        for(Contact cont : contactList)
        {
            for(Integer iCtr = counter; iCtr < departmentList.size(); ++iCtr)
            {
                NAS_Authorized__c auth = new NAS_Authorized__c(NAS_Contact__c = cont.Id,
                                                               NAS_Customer_Account__c = departmentList[iCtr].Customer_Id__c,
                                                               NAS_Division__c = departmentList[iCtr].Division_cd__c,
                                                               NAS_Department__c = departmentList[iCtr].Id,
                                                               NAS_Status__c = NAS_Constants.AUTHORIZED_ACTIVE_STATUS);
                authorizedList.add(auth);
            }
            
            counter = counter + count;
        }
        return authorizedList;
    } Gitlab:13068-Stop*/

    /**
     * @name setupTestData
     * @description Inserts Accounts, Customer Accounts and Contacts
    **/
    public static void setupTestData(Integer count){
        List<Account> accountList = constructAccounts(count);
        INSERT accountList;
        List<IM_Customer_Account__c> customerAccountList = constructCustomerAccounts(count, accountList);
        INSERT customerAccountList;
        List<Contact> contactList = constructContacts(count, accountList);
        INSERT contactList;
        List<Division__c> divisionList = constructDivisions(1, customerAccountList);
        INSERT divisionList;
        List<Department__c> deptartmentList = constructDepartments(1, divisionList);
        INSERT deptartmentList;
        /*Gitlab:13068-start
        List<NAS_Authorized__c> authorizedList = constructAuthorizedRecords(contactList, count, deptartmentList);
        INSERT authorizedList;
        Gitlab:13068-Stop*/
    }
    
    /**
     * @name createGeneralSupportCase
     * @description Inserts a Case with supplied Contact, Account & Customer Account information.
     * private static Case createGeneralSupportCase(Contact c, Account a, IM_Customer_Account__c ca,
                                               Division__c division, Department__c department)
    **/
    private static Case createGeneralSupportCase( Account a, IM_Customer_Account__c ca)
    {
        List<Account> accList = new List<Account>();
        accList.add(a);
        List<Contact> contactList=constructContacts(1,accList); 
        INSERT contactList;
        Case cs = new Case();
        //Contact c = new Contact();
        cs.Customer_Id__c = ca.Id;
        cs.AccountId = a.Id;
        cs.ContactId = contactList[0].Id;
        cs.RecordTypeId = NAS_DataFactory.getRecordTypeId('Case', NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE);
        cs.Status = NAS_Constants.NEWCASESTATUS;
        cs.Origin = NAS_Constants.IMCORIGIN;
        cs.Priority = NAS_Constants.DEFAULT_CASE_PRIOROTY;
        cs.Subject = 'Test Case Record';
        cs.Description = 'Test Case Record';        
        cs.GSC_Category__c='Amendment of Customer Details';
        cs.GSC_Sub_Category__c='Add, Amend, Remove Authorised User';
      // cs.Division_ID__c = division.Id;
      // cs.Department_ID__c = department.Id;
        return cs;
    }
    /**
     * @name createRecurringCase
     * @description Inserts a Case with supplied Contact, Account & Customer Account information.
     * public static Case createRecurringCase(Contact c, Account a, IM_Customer_Account__c ca, String status, Integer index)
    **/
    public static Case createRecurringCase( Account a, IM_Customer_Account__c ca, String status, Integer index)
    {
        //'DAY + 1', 'DAY + 7', 'DAY + 14', 'MONTH + 1', 'MONTH + 3', 'YEAR + 1'
        String[] recurrenceFrequencies = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.NAS_Recurrence_Frequency__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pe : ple)
        {
            recurrenceFrequencies.add(pe.getValue());
        }
        if(index == null)
            index = Math.mod((Integer)(Math.random() * 10), recurrenceFrequencies.size());
        
        Case cs = new Case();
        Contact c = new Contact();
        cs.Customer_Id__c = ca.Id;
        cs.AccountId = a.Id;
        cs.ContactId = c.Id;
        cs.RecordTypeId = NAS_DataFactory.getRecordTypeId('Case', NAS_Constants.RECURRING_CASE_RECORDTYPE);
        if(status != null)
            cs.Status = status;
        else
            cs.Status = NAS_Constants.NEWCASESTATUS;
        cs.Origin = NAS_Constants.IMCORIGIN;
        cs.Priority = NAS_Constants.DEFAULT_CASE_PRIOROTY;
        cs.Subject = 'Test Case Record';
        cs.Description = 'Test Case Record';
        cs.NAS_Next_Case_Creation_Date__c = Date.today();
        cs.NAS_Recurrence_Frequency__c = recurrenceFrequencies[Math.mod(index, recurrenceFrequencies.size())];
        return cs;
    }
    /**
     * @name createCase
     * @description Creates a number of cases defined by the parameter count with recordType as 
     * defined by the parameter recordType for each of the Customer Accounts in the System.
    **/
    public static List<Case> createCase(Integer count, String recordType, Boolean doInsert, String status)
    {
        List<Case> caseList = new List<Case>();
        List<IM_Customer_Account__c> customerAccountList = [SELECT Id, IM_Account__c FROM IM_Customer_Account__c
                                                            //WHERE Name LIKE 'CustomerAccount%'
                                                            ORDER BY IM_Account__c, Id];
       /*Gitlab:13068-start
        List<NAS_Authorized__c> authorizedList = [SELECT Id, NAS_Contact__c, NAS_Division__c, NAS_Department__c  
                                                  FROM NAS_Authorized__c 
                                                  //WHERE NAS_Customer_Account__c IN (SELECT Id FROM IM_Customer_Account__c
                                                  //WHERE Name LIKE 'CustomerAccount%')
                                                  ORDER BY NAS_Customer_Account__r.IM_Account__c, 
                                                  NAS_Customer_Account__c]; Gitlab:13068-Stop*/
        Integer customerAccountCounter = 0;
        for(Integer iCtr = 0; iCtr < count; ++iCtr)
        {
            if(recordType == NAS_Constants.RECURRING_CASE_RECORDTYPE)
                caseList.add(NAS_TestDataFactory.createRecurringCase(
                        //  Gitlab - 13068 // new Contact(Id = authorizedList[customerAccountCounter].NAS_Contact__c), 
                            new Account(Id = customerAccountList[customerAccountCounter].IM_Account__c),
                            new IM_Customer_Account__c(Id = customerAccountList[customerAccountCounter].Id),
                            status, iCtr));
            else if(recordType == NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE)
                        caseList.add(NAS_TestDataFactory.createGeneralSupportCase(
                          //  Gitlab - 13068 //  new Contact(Id = authorizedList[customerAccountCounter].NAS_Contact__c), 
                            new Account(Id = customerAccountList[customerAccountCounter].IM_Account__c),
                            new IM_Customer_Account__c(Id = customerAccountList[customerAccountCounter].Id)
                          //  Gitlab - 13068 //  new Division__c(Id = authorizedList[customerAccountCounter].NAS_Division__c), 
                           //  Gitlab - 13068 // new Department__c(Id = authorizedList[customerAccountCounter].NAS_Department__c)
                            ));
                       
            customerAccountCounter++;
            if(customerAccountCounter >= customerAccountList.size())
                customerAccountCounter = 0;
        }
        if(doInsert)
            INSERT caseList;
        return caseList;
        
    }
}