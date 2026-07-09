/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_IRM_SC_SendEmailUtilityClass (Apex Class)
**
** PURPOSE
**   To cover 'IRM_SC_SendEmailUtilityClass' Apex Class. 
**
** NOTES
**   Created test class with dummy data to get code coverage always.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/05/08; Srinivasa Rao/Randstad; Reviewing code coverage for all components/Case#01367998; Initial release
**
************************************************************************/
@isTest(SeeAllData=True)
private class Test_IRM_SC_SendEmailUtilityClass {

    static testMethod void myUnitTest() {
       
       //get a folder
       Folder F = [Select f.Id, f.Type, f.Name, f.DeveloperName, f.AccessType From Folder f Limit 1]; 
       
       //get a Template.
       EmailTemplate templateId =[Select id, IsActive From EmailTemplate where IsActive=true Limit 1];
       
       
       //get Business Hours    
       BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Europe/Paris' LIMIT 1];
       
       //get Profile
       Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
       
       //get Role
       UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
        
       //get Record type
       RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
       
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
       System.runAs(Owner1){
        
       	
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
           
         //Creation of Alternative Country record
         IM_Alternative_Country_Name__c AlternateCountry = new IM_Alternative_Country_Name__c(Alternative_Name__c = 'France',
                                                                                                IM_Country__c = country.id);
         insert AlternateCountry;
           
           //insert Account for Customer Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'France');
        insert testAccount;
           
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123',IM_Account_Manager__c = Owner1.Id,
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        //Case Creation
        testCase = new Case();
        testCase.Origin = 'GBR_EMAIL_CS';
        testCase.Status = 'New';
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
        testCase.IME_SC_Country_Code__c ='GBR';
        testCase.IME_SC_Notification_Name__c='Notify_Queue_For_Level_2_Escalated_Cases';
        insert testCase; 
       }
       
       //Update case as other owner.
       System.runAs(Owner2){ 
       	Test.startTest();
        testCase.Status = 'Closed';
        testCase.IME_SC_Order_Id__c ='1234';
        testCase.OwnerId = Owner2.Id;
        testCase.IME_SC_Case_Email__c='testIMECaseEmail@IME.com';
        update testCase;
        Test.stopTest();            
       }
    }
}