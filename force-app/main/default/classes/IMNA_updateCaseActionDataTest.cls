/***************************************************
    Name       : Test_IMNA_updateCaseActionData
    Description: Test class for IMNA_updateCaseActionData
    Author     : Kavya Somashekar
    Case #     : 02411596
****************************************************/

@isTest(SeeAllData=true)
public class IMNA_updateCaseActionDataTest
{          
    public static testMethod void updateCaseActionDataTest() 
    {
        test.startTest();  
        
        ID recTypeId =  DataFactory.getRecordTypeId('Case','NCSP: New Customer Setup');
        User owner1 = DataFactory.createUsers(1)[0];
        User currentUser = new User ( Id = UserInfo.getUserId() );
        
        //Creation of Account
        Account testAccount = new Account(Name='Test Account9243');
        insert testAccount;
        
        //Creation of Contact
        Contact caseContact = new Contact(FirstName = 'Test958',
                                          accountid = testAccount.id,
                                          LastName = 'User892');
        
        insert caseContact;
        
        //Creation of Case
        case testCase = new case();
            testCase.Status = 'New';
            testCase.RecordTypeId = recTypeId;
            testCase.Origin = 'Inside Sales'; 
            testCase.NCSP_Service_line__c= 'Accutrac';
            testCase.Date_Paperwork_Received__c = system.today();
            testCase.Sales_Person_Name_Account_Manager__c = owner1.id;        
            testCase.Setup_Type__c = 'Standard';
            testCase.Contact = caseContact;
            testCase.Account = testAccount;          
            insert testCase;
                
        Case_Action__c testCaseAction = new Case_Action__c();
            testCaseAction.Status__c = 'Rejected';
            testCaseAction.Case_Action_Assigned_To__c= currentUser.id;
            insert testCaseAction;
          
            testCaseAction.Case_Action_Assigned_To__c= owner1.id;
            testCaseAction.Reassign_Comments__c ='testing';
            update testCaseAction;
            
            Validator_cls obj = new Validator_cls();
            Validator_cls.setAlreadyDoneToFalse();
            
            testCaseAction.Case__c = testCase.id;
            testCaseAction.Status__c = 'Resubmitted';
            testCaseAction.Resubmit_Comments__c = 'testing';
            update testCaseAction;    
        
        Test.stopTest();
    } 
    public static testMethod void updateCaseActionDataTest2() 
    {
        test.startTest();  
        ID recTypeId =  DataFactory.getRecordTypeId('Case','NCSP: New Customer Setup');
        User owner1 = DataFactory.createUsers(1)[0];
        User currentUser = new User ( Id = UserInfo.getUserId() );
        
        //Creation of Account
        Account testAccount = new Account(Name='Test Account8392');
        insert testAccount;
        
        //Creation of Contact
        Contact caseContact = new Contact(FirstName = 'Test123',
                                          accountid = testAccount.id,
                                          LastName = 'User567');
        
        insert caseContact;
        
        //Creation of Case
        case testCase = new case();
            testCase.Status = 'New';
            testCase.RecordTypeId = recTypeId;
            testCase.Origin = 'Inside Sales'; 
            testCase.NCSP_Service_line__c= 'Accutrac';
            testCase.Date_Paperwork_Received__c = system.today();
            testCase.Sales_Person_Name_Account_Manager__c = owner1.id;        
            testCase.Setup_Type__c = 'Standard';
            testCase.Contact = caseContact;
            testCase.Account = testAccount;          
            insert testCase;
            
            Validator_cls obj = new Validator_cls();
            Validator_cls.setAlreadyDoneToFalse();
            
            testCase.Contract_Status__c = 'Rejected';
            testCase.Rejection_Comments__c='testing';
            testCase.Primary_Contract_Rejection_Reason__c='testing';        
            update testCase;
            
            Case_Action__c testCaseAction = new Case_Action__c();
            testCaseAction.Status__c = 'Rejected';
            testCaseAction.Case_Action_Assigned_To__c= currentUser.id;
            testCaseAction.Case_Action_Assigned_To__c= owner1.id;
            testCaseAction.Reassign_Comments__c ='testing';
            insert testCaseAction;
            
            testCaseAction.Case__c = testCase.id;
            testCaseAction.Status__c = 'Resubmitted';
            testCaseAction.Resubmit_Comments__c ='testing';
            update testCaseAction;
            
            testCaseAction.Case__c = testCase.id;
            testCaseAction.Status__c = 'Rejected';
            testCaseAction.Reassign_Comments__c ='testing';
            update testCaseAction;
            
            testCaseAction.Case__c = testCase.id;
            testCaseAction.Status__c = 'Resubmitted';
            testCaseAction.Resubmit_Comments__c ='testing';
            update testCaseAction;
         
         Test.stopTest();
    }
    
    // Gitlab #34121 test method for testing the follow up dates assignment logic
    // in the trigger on Case Action IMNA_updateCaseActionData in the isInsert path
    public static testMethod void testFollowUpDateAssignments()
    {
        Test.startTest();  
        
        ID recTypeId =  DataFactory.getRecordTypeId('Case','NCSP: New Customer Setup');
        User owner1 = DataFactory.createUsers(1)[0];
        User currentUser = new User ( Id = UserInfo.getUserId() );
        
        //Creation of Account
        Account testAccount = new Account(Name='Test Account555');
        insert testAccount;
        
        //Creation of Contact
        Contact caseContact = new Contact(FirstName = 'Test9588',
                                          accountid = testAccount.id,
                                          LastName = 'User8923');
        insert caseContact;
        
        //Creation of Case
        case testCase = new case();
            testCase.Status = 'New';
            testCase.RecordTypeId = recTypeId;
            testCase.Origin = 'Inside Sales'; 
            testCase.NCSP_Service_line__c= 'Accutrac';
            testCase.Date_Paperwork_Received__c = system.today();
            testCase.Setup_Type__c = 'Standard';
            testCase.Contact = caseContact;
            testCase.Account = testAccount;
            testCase.Country__c = 'USA';
            insert testCase;
                
        Case_Action__c testCaseAction = new Case_Action__c();
            testCaseAction.Status__c = 'Rejected';
            testCaseAction.Case__c = testCase.id;
            insert testCaseAction;
          
        Test.stopTest();
    }
}