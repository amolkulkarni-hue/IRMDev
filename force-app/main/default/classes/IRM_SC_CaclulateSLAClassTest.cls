/**  
       * Name            : IRM_SC_CaclulateSLAClassTest
       * Description     : Test class for IRM_SC_CaclulateSLAClass
       * Copyright       : HCL Technologies
       * Author          : Sejal Shah
       * Modification Log: Created: 21-Mar-2012 
                           Modified by Himanshu Jain 30-Aug-2012
                           Modified by Rupesh Pande 12-Dec-2020
                           Against the case no : 00769549 
                           Added code to incorprate the validation rule which is used to make Case email field required for email.
						   Modified by Arjun Sankar 19-Oct-2022, #11278 - added data for custom settings IME_SC_Country_List__c

**/
@isTest
private class IRM_SC_CaclulateSLAClassTest {
    
    static testMethod void createNewCase() {
        
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Europe/Paris' LIMIT 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
    //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France',UserRoleId = CSRuser1.Id);
     
     
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'New';
        testCase.IME_SC_Country__c = 'France';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.BusinessHoursId = BH.id;
        testCase.IME_SC_Category__c= 'Order Enquiry';
        testCase.IME_SC_Sub_Category__c = 'Change an order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        insert testCase;
        
        Test.startTest();
        testCase.Status = 'In Progress';
        update testCase;
        Test.stopTest();
        
    }
      // TO DO: implement unit test
    }
    
    static testMethod void testOnHoldCase(){
        
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Europe/Paris' LIMIT 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'In Progress';
        testCase.IME_SC_Country__c = 'France';
        testCase.BusinessHoursId = BH.Id;
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Category__c= 'Order Enquiry';
        testCase.IME_SC_Sub_Category__c = 'Change an order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Initial_SLA_Start_Time__c = System.now().addHours(-1);
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        insert testCase;
        
        //testCase.Status = 'On Hold - Internal';
        //update testCase;
        Test.startTest(); 
        testCase.Status = 'On Hold - Internal';
        update testCase;
        
        testCase.Status = 'In Progress';
        update testCase;
        Test.stopTest();
        
    }
    
    
        // TO DO: implement unit test
    }
    
    static testMethod void testClosedCase(){
        
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Europe/Paris' LIMIT 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'In Progress';
        testCase.IME_SC_Country__c = 'France';
        testCase.BusinessHoursId = BH.Id;
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Category__c= 'Order Enquiry';
        testCase.IME_SC_Sub_Category__c = 'Change an order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        insert testCase;
        
        CaseComment comment = new CaseComment(ParentId = testCase.Id);
        insert comment;
        
        Test.startTest();
        Contact caseContact = new Contact(FirstName = 'Test', email = 'test@hcl.com',   LastName = 'User',MailingPostalCode='57678',MailingState='Victoria', MailingCity='Australia City',MailingCountry = 'Australia',MailingStreet = 'Austr Street');
        insert caseContact;
        testCase.IME_SC_SLA_Time_Elapsed__c = 20;
        testCase.contactID = caseContact.id;
        testCase.IME_SC_SLA_Hold_Time__c = System.now().addMinutes(-15);
        testCase.IME_SC_SLA_Resume_Time__c = System.now().addMinutes(-5);
        testCase.Status = 'Closed';
        testCase.IME_SC_Closure_Reason__c = 'Cancelled';
        testCase.IME_SC_Case_Cause__c = 'Transport';
        testCase.IME_SC_Order_Id__c = 'Test123';
        //added code Against the case no : 00769549 
        testCase.IME_SC_case_email__c = 'test@hcl.com';
        update testCase;
        Test.stopTest();
 
    }
    
   
        // TO DO: implement unit test
    }
    
    static testMethod void testNoSLA(){
        
    Test.startTest();
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='United Kingdom');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //#11278 starts
     	List<IME_SC_Country_List__c> lstCountrylist = new list <IME_SC_Country_List__c>();
     	IME_SC_Country_List__c CountryUK = new IME_SC_Country_List__c(Is_Indexing_SLA__c=TRUE,Country_Name__c='United Kingdom',Country_3_Letter_Code__c='UK1',Name='UKTest');
     	insert CountryUK;
     	//#11278 ends 
        
        //Case Creation
        Case testCase = new Case();
        testCase.Origin = 'GBR_EMAIL_CS';
        testCase.Status = 'New';
        testCase.IME_SC_Country__c = 'United Kingdom';
        //testCase.IME_SC_Category__c= 'Email';
        //testCase.IME_SC_Sub_Category__c = 'Email';
        //testCase.IME_SC_Request_Type__c = 'NA';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        insert testCase;
        
        update testCase;

        
    }
    
    Test.stopTest();
        // TO DO: implement unit test
    }
    
    static testMethod void createCaseForAustralia() {
        
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Australia/Sydney' AND Name = 'BH_AUS_Victoria' LIMIT 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Australia/Sydney', state = 'Victoria',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        Case testCase = new Case();
        testCase.Origin = 'AUS_FAX_ACT';
        testCase.Status = 'New';
        testCase.BusinessHoursId = BH.Id;
        testCase.IME_SC_Country__c = 'Australia';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        insert testCase;
        
        Test.startTest();
        testCase.IME_SC_Category__c= 'Order Enquiry';
        testCase.IME_SC_Sub_Category__c = 'Change an order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.Status = 'In Progress';
        update testCase;
        Test.stopTest();
        
    }
    
    
        // TO DO: implement unit test
    }
    
    static testMethod void createCaseForOthers() {
        
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Australia/Sydney' AND Name = 'BH_AUS_Victoria' LIMIT 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Australia/Sydney', state = 'Victoria',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        Case testCase = new Case();
        testCase.Origin = 'ESP_EMAIL_CS';
        testCase.Status = 'New';
        testCase.BusinessHoursId = BH.Id;
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        insert testCase;
        
        Test.startTest();
        testCase.IME_SC_Category__c= 'Order Enquiry';
        testCase.IME_SC_Sub_Category__c = 'Change an order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.Status = 'In Progress';
        update testCase;
        Test.stopTest();
        
    }
    
   
        // TO DO: implement unit test
    }
    
    static testMethod void createCaseForInProgress() {
        
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Australia/Sydney' AND Name = 'BH_AUS_Victoria' LIMIT 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Australia/Sydney', state = 'Victoria',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        Case testCase = new Case();
        testCase.Origin = 'ESP_EMAIL_CS';
        testCase.Status = 'In Progress';
        testCase.BusinessHoursId = BH.Id;
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        testCase.IME_SC_Category__c= 'Order Enquiry';
        testCase.IME_SC_Sub_Category__c = 'Change an order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_SLA_Time_Elapsed__c = 20;
        testCase.IME_SC_SLA_Hold_Time__c = System.now().addMinutes(-15);
        testCase.IME_SC_SLA_Resume_Time__c = System.now().addMinutes(-5);
        
        insert testCase;
        
        Test.startTest();
       testCase.Status = 'In Progress';
       update testCase;
       Test.stopTest();
        
    }
    
    
        // TO DO: implement unit test
    }
    
    static testMethod void createListCase() {
    
    List<Case> caseList = new List<Case>(); 
    List<IM_Customer_Account__c> custAccList = new List<IM_Customer_Account__c>();
    Test.startTest();
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Europe/Paris' Limit 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount1 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner1.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount1);
        
        IM_Customer_Account__c caseCustomerAccount2 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner1.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount2);
        
        IM_Customer_Account__c caseCustomerAccount3 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner1.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount3);
        
        IM_Customer_Account__c caseCustomerAccount4 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner1.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount4);
        
        insert custAccList;
        
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'New';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Category__c= 'Create a new Order';
        testCase.IME_SC_Sub_Category__c = 'Quote/Standard Order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount1.id;
        caseList.add(testCase);
        
        Case testCase1 = new Case();
        testCase1.Origin = 'FRA_WEB';
        testCase1.Status = 'New';
        testCase1.RecordTypeId = caseRecordType.id;
        testCase1.IME_SC_Category__c= 'Complaints';
        testCase1.IME_SC_Sub_Category__c = 'Order not received';
        testCase1.IME_SC_Request_Type__c = 'Non-order';
        testCase1.BusinessHoursId = BH.Id;
        testCase1.IME_SC_Customer_AccountId__c = caseCustomerAccount2.id;
        caseList.add(testCase1);
        
        Case testCase2 = new Case();
        testCase2.Origin = 'FRA_WEB';
        testCase2.Status = 'New';
        testCase2.BusinessHoursId = BH.Id;
        testCase2.RecordTypeId = caseRecordType.id;
        testCase2.IME_SC_Category__c= 'General Enquiry';
        testCase2.IME_SC_Sub_Category__c = 'Miscellaneous';
        testCase2.IME_SC_Request_Type__c = 'Non-order';
        testCase2.IME_SC_Customer_AccountId__c = caseCustomerAccount3.id;
        caseList.add(testCase2);
        
        Case testCase3 = new Case();
        testCase3.Origin = 'FRA_WEB';
        testCase3.Status = 'New';
        testCase3.BusinessHoursId = BH.Id;
        testCase3.RecordTypeId = caseRecordType.id;
        testCase3.IME_SC_Category__c= 'Relationship Management';
        testCase3.IME_SC_Sub_Category__c = 'Account Closure';
        testCase3.IME_SC_Request_Type__c = 'Non-order';
        testCase3.IME_SC_Customer_AccountId__c = caseCustomerAccount4.id;
        caseList.add(testCase3);
        
        insert caseList;
    }
    
    Test.stopTest();
        // TO DO: implement unit test
    }
    
     static testMethod void createCaseForCutOffTime() {
    
    List<Case> caseList = new List<Case>(); 
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where Name = 'BH_FRA' Limit 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'In Progress';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_SLA_Time_Elapsed__c = 20;
        //testCase.IME_SC_SLA_Hold_Time__c = System.now().addMinutes(-15);
        //testCase.IME_SC_SLA_Resume_Time__c = System.now().addMinutes(-5);
        testCase.IME_SC_SLA_Trigger_Time__c = System.now().addMinutes(25);
        testCase.IME_SC_Category__c= 'Create a new Order';
        testCase.IME_SC_Sub_Category__c = 'Quote/Standard Order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        insert testCase;
        
        Test.startTest();
        try{
            testCase.IME_SC_Cut_Off_Time__c = '17:00';
            update testCase;
        }
        catch(System.DmlException DE)
        {
            system.debug('In catch block'); 
        }
        Test.stopTest();
    }
        // TO DO: implement unit test
    }
    
    static testMethod void createCaseOnHoldToInProgress() {
    
    List<Case> caseList = new List<Case>();
    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where Name = 'BH_FRA' Limit 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'In Progress';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Category__c= 'Create a new Order';
        testCase.IME_SC_Sub_Category__c = 'Quote/Standard Order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        testCase.IME_SC_SLA_Time_Elapsed__c = 20;
        testCase.IME_SC_SLA_Hold_Time__c = System.now().addMinutes(-15);
        testCase.IME_SC_SLA_Resume_Time__c = System.now().addMinutes(-5);
        insert testCase;
        
        //update testCase;
        
        Test.startTest();
        testCase.Status = 'On Hold - Internal';
        update testCase;
        Test.stopTest();
    }
    
    
        // TO DO: implement unit test
    }
    
    static testMethod void createCaseSLARemaining() {
    
    List<Case> caseList = new List<Case>(); 
    Test.startTest();
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where Name = 'BH_FRA' Limit 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'In Progress';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Category__c= 'Create a new Order';
        testCase.IME_SC_Sub_Category__c = 'Quote/Standard Order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_SLA_Time_Elapsed__c = 20;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        testCase.IME_SC_SLA_Hold_Time__c = System.now().addMinutes(-15);
        testCase.IME_SC_SLA_Resume_Time__c = System.now().addMinutes(-5);
        testCase.IME_SC_SLA_Time_Remaining__c = -15;
        insert testCase;
    }
    
    Test.stopTest();
        // TO DO: implement unit test
    }
    
    static testMethod void updateCaseViewTest() {
    
    List<Case> caseList = new List<Case>(); 
    Test.startTest();
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where Name = 'BH_FRA' Limit 1];
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France');
    
    System.runAs(Owner1)
    {
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        Case testCase = new Case();
        testCase.Origin = 'FRA_WEB';
        testCase.Status = 'In Progress';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.IME_SC_Category__c= 'Create a new Order';
        testCase.IME_SC_Sub_Category__c = 'Quote/Standard Order';
        testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        testCase.OwnerId = Owner1.Id;
        insert testCase;
        
        IME_SC_Case_View_Info__c caseView = new IME_SC_Case_View_Info__c();
        caseView.IME_SC_User__c = Owner1.Id;
        caseView.IME_SC_Case__c = testCase.Id;
        caseView.IME_SC_Counter__c = 4;
        insert caseView;
    }
    
    Test.stopTest();
        // TO DO: implement unit test
    }
}