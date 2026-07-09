/**  
       * Name       : IRM_SC_RaiseCaseInfoTrigger
       * Description   : Test class for IME_SC_RaiseCaseInfoTrigger
       * Copyright      : HCL Technologies
       * Author       : Sejal Shah
       * Modification Log: Created:12-Mar-2012 
**/
@isTest (SeeAllData=true)
private class IRM_SC_RaiseOnBoardingCaseTest
{
    
    //to test IME_SC_RaiseCaseInfoTrigger
    static testMethod void myUnitTest() 
    {
        case sendNotification= new case();
        ID caseRecordTypeOnBoarding =  DataFactory.getRecordTypeId('Case','IM Employees Support Case');
        ID caseRecordType =  DataFactory.getRecordTypeId('Case','IME SC Case');
        User ManagerUser = DataFactory.createUsersLst(1)[0];
        
        /*RecordType caseRecordTypeOnBoarding = [select id from RecordType where name='IM Employees Support Case'];
        RecordType caseRecordType = [select id from RecordType where name='IME SC Case'];    
        Profile sysAdmin = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
        
        User ManagerUser = new User(FirstName = 'Test', LastName = 'User', ProfileId = sysAdmin.Id, ManagerId = null,
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestUser1@support.com', Email = 'testUser@support.com',
                              Alias = 'tUse', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwn1',
                              LocaleSidKey = 'en_US', Country='FRANCE');*/
                              
        /*  User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia'); 
                              */                     
                              
        System.runAs(ManagerUser)
        {
           //Creation of Account
           Account testAccount = new Account(Name='Test Account');
           insert testAccount;
            
           //Creation of Contact
           Contact caseContact = new Contact(FirstName = 'Test', LastName = 'User');
           insert caseContact;
                            
           case testOnBoarding = new case();
           testOnBoarding.Status = 'New';
           testOnBoarding.RecordTypeId = caseRecordTypeOnBoarding;
           testOnBoarding.AccountID = testAccount.id;
           testOnBoarding.ContactID = caseContact.id; 
           testOnBoarding.IM_Employee_Contact__c = ManagerUser.id;       
           testOnBoarding.IME_SC_Request_Type__c = 'Order';
           testOnBoarding.IME_SC_Country__c = 'France';
           testOnBoarding.Subject = 'Test On Boarding 123'; 
           testOnBoarding.Related_To__c = 'Customer Account/Client Code';
           testOnBoarding.Issue__c = 'Account Set Up';
           testOnBoarding.IME_SC_Number_of_Line_Items__c = 1;
            
           testOnBoarding.IM_Division__c = 'IME';
           //insert testCaseHalfDay;
           //testCases.add(testOnBoarding); 
           Test.startTest();
           insert testOnBoarding;
           testOnBoarding.Status = 'Closed';
           update testOnBoarding;
           
           Test.stopTest();   
           }
           
           
           }

}