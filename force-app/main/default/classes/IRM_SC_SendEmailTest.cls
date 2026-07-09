/**  
       * Name: IRM_SC_SendEmailTest
       * Description: Test class for IRM_SC_SendEmail.  
       * Copyright: HCL Technologies
       * Author: Sejal Shah
       * Modification Log: Created:20-Apr-2012
                           Modified by Himanshu Jain 30-Aug-2012 
                           Against the case no : 00769549
                           Added code to incorprate the validation rule which is used to make Case email field required for email.
**/
@isTest
private class IRM_SC_SendEmailTest {

    static testMethod void testSendEmail() {
    
    //get Business Hours    
    BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Europe/Paris' LIMIT 1];
    //get Profile
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    //get Role
    UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    //get Record type
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
    //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='France',UserRoleId = CSRuser1.Id);
    User Owner2 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id,
                              Username = 'TestManMan@support.com', Email = 'testManager_Manager@support.com',
                              Alias = 'tUser', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tman',
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                              LocaleSidKey = 'en_US', Country='France');
                            
    Case testCase;
    System.runAs(Owner1)
    {
        Contact caseContact = new Contact(FirstName = 'Test', email = 'test@hcl.com',   LastName = 'User', MailingCountry = 'Australia');
        insert caseContact;
        //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'France');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123',IM_Account_Manager__c = Owner1.Id,
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        testCase = new Case();
        testCase.Origin = 'GBR_EMAIL_CS';
        testCase.Status = 'New';
        testCase.contactId = caseContact.id;
        testCase.IME_SC_Country__c = 'France';
        testCase.RecordTypeId = caseRecordType.id;
        testCase.BusinessHoursId = BH.id;
        testCase.IME_SC_Category__c= 'Order Enquiry';
        testCase.IME_SC_Sub_Category__c = 'Change an order';
        //testCase.IME_SC_Request_Type__c = 'Order';
        testCase.IME_SC_Number_of_Line_Items__c = 1;
        testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
        testCase.IME_SC_To_Address__c = 'test@support.com';
        testCase.IME_SC_Cc_Address__c = 'test@support.com';
        testCase.IME_SC_Bcc_Address__c = 'test@support.com';
        insert testCase;
        
    }
    
    //Update case as other owner.
    System.runAs(Owner2)
    { 
        Test.startTest();
        testCase.Status = 'In Progress';
        testCase.OwnerId = Owner2.Id;
        update testCase;
        Test.stopTest();
        
    }
      // TO DO: implement unit test
    }
}