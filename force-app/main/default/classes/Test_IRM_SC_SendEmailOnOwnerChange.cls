/************************
Developer Name: Madhu Paladugu
Case Number   : 01814315
Date          : 10/8/13
purpose       : Test Utility for IRM_SC_SendEmailOnOwnerChange class
***********************/

@isTest(seeAllData=true)
public class Test_IRM_SC_SendEmailOnOwnerChange{
    
    static testMethod void doTest(){
        // Setup data for OrgWideEmailAddress 
        OrgWideEmailAddress owea;
       try {
           owea = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress LIMIT 1];
       } catch (QueryException e) {
           System.debug('No OrgWideEmailAddress found. Please ensure at least one is configured in the org for this test to run.');
       }

        // Create a Contact for the utility class to find 
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'ContactForUtility',
            Email = 'initial@example.com' // This email will be updated by the main class
        );
        insert testContact;

        // Create an EmailTemplate 
        // Match the naming convention from your main class
        EmailTemplate emailTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate where name = 'IME_SC_FRA_Notify_Owner_Modification'];
            RecordType caseRecordTypeOnBoarding = [select id from RecordType where name='IM Employees Support Case'];
        
           //Creation of Account
           Account testAccount = new Account(Name='Test Account');
           insert testAccount;
            
           //Creation of Contact
           Contact caseContact = new Contact(FirstName = 'Dummy', LastName = 'Contact',Phone='789',email='invalid@ironmountain.com');
           insert caseContact;
                            
           case testOnBoarding = new case();
           testOnBoarding.Status = 'New';
           testOnBoarding.RecordTypeId = caseRecordTypeOnBoarding.id;
           testOnBoarding.AccountID = testAccount.id;
           testOnBoarding.ContactID = caseContact.id; 
           testOnBoarding.IM_Employee_Contact__c = userInfo.getUserId();       
           testOnBoarding.IME_SC_Request_Type__c = 'Order';
           testOnBoarding.IME_SC_Country__c = 'France';
           testOnBoarding.IME_SC_Country_Code__c = 'FRA';
           testOnBoarding.Subject = 'Test On Boarding 123'; 
           testOnBoarding.Related_To__c = 'Customer Account/Client Code';
           testOnBoarding.Issue__c = 'Account Set Up';
           testOnBoarding.IME_SC_Case_Owner_Email__c= 'inavalid12@ironmountain.com';
           testOnBoarding.IM_Division__c = 'IME';
           insert testOnBoarding;
           
           Map<id,case> oldMap=new MAp<id,case>();
           oldMap.put(testOnBoarding.id,testOnBoarding);
           
          Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1]; 
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Country = 'France',
            UserName = 'testuser@example.com' + System.currentTimeMillis() // Unique username
        );
        insert u;

           testOnBoarding.ownerId=u.id;
        	testOnBoarding.IME_SC_Case_Owner_Email__c = 'new.owner@example.com';
           update testOnBoarding;
           
           List<case> newcase=new List<case>();
           newcase.add(testOnBoarding);
           
         Test.startTest();
           IRM_SC_SendEmailOnOwnerChange.sendEmail(newcase,oldMap);
        Test.stopTest();
           
           
    }
}