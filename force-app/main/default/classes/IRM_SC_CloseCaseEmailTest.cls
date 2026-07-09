/**  
* Name       : IRM_SC_closeCaseEmailTest
* Description   : Test class for IME_SC_ClosedCaseEmail trigger and IME_SC_SendEmailOwnerChange class
* Copyright      : HCL Technologies
* Author       : Himanshu Jain
* Modification Log: Created:12-Mar-2012
* 
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 06/03/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
* Modified By: Simranjit Kaur on 21-Nov-2024 Refer GitLab #27569
*                   -- Updated for new record type "CAC Executive Escalations" to create new child case when case is closed for more than 14 days and send an email notification - GitLab #27569
* Modified By: Simranjit Kaur on 27-Feb-2025 Refer GitLab #29454
* 					-- Updated code to increase code coverage.
* Modified By: Simranjit Kaur on 03-April-2025 Refer GitLab #29990
* 			-- Removed Case-reopened/child case functionality for Global Service Cases in "Cancelled" Status but create new case.
**/
@IsTest
public class IRM_SC_CloseCaseEmailTest{
    
    @testSetup static void methodName() {
        // Create test data for a user and profile
        //Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        //User adminUser = new User(
            //Alias = 'testuser', Email = 'testmyUnit@example.com', Username = 'testmyUnit@testmyUnit.com', CommunityNickname = 'testmyUnit', ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
            //LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LastName = 'Test', FirstName = 'User', CompanyName = 'Test Company', Phone = '555-555-5555', Country ='test'
        //);
        //insert adminUser;
		
        ID recTypeIdService =  DataFactory.getRecordTypeId('Case','Global Service Case');
        // Create a test Case record
        Trigger_Activation_Settings__c setting = new Trigger_Activation_Settings__c();
        setting.Name = 'IRM_SC_CaseEmailDelete';
        setting.Object__c='Case';
        setting.Value__c = 'TRUE';
        setting.Trigger__c='IRM_SC_ClosedCaseEmail';
        insert setting;
        Case testCase= new Case();
            Account newAcc = new Account(Name ='Test');
            Contact newCon = new Contact();
            IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            insert newAcc;
            newCon.FirstName = 'Test Contact';
            newCon.LastName = 'Test Contact12';
            newCon.AccountId = newAcc.id;
            insert newCon;
            cusAcc.Name='Test';
            cusAcc.IM_Account__c= newAcc.id;
            insert cusAcc;
            testCase.RecordTypeId =recTypeIdService;
            testCase.Subject = 'Test Email Case';
            testCase.Description = 'Test';
            testCase.Origin = 'IND_SOUTH_EMAIL_CS';
            testCase.IME_SC_Country__C = 'India';
            testCase.ContactId = newCon.id;
            testCase.AccountId= newAcc.id;
            testCase.Customer_ID__c = cusAcc.id;
            testCase.GSC_Category__c = 'General Enquiry';
            testCase.GSC_Sub_Category__c = 'Service Advice';
            testCase.GSC_Root_Cause__c = 'Customer education';
            testCase.Status='Resolved';        	
            testCase.CreatedDate = System.Today().addDays(-18);
            testCase.ClosedDate = System.Today().addDays(-15);
            string caseJSON=JSON.serialize(testCase);
            Case case1 = (Case) JSON.deserialize(caseJSON, Case.class );
            insert case1;

        // Create EmailMessage record linked to the Case
        EmailMessage testEmailMessage = new EmailMessage(
            FromAddress='simranjit.kaur.prtnr@ironmountain.com', 
            FromName= 'Test Name',
            Subject='Subject test', 
            TextBody='This is test email',
        	parentId= case1.id);
        insert testEmailMessage;

	}
    @IsTest
    static void TestCase() {
        // Test data setup
        // Create an email message and case
        
        //  Trigger_Activation_Settings__c triggerSetting = new Trigger_Activation_Settings__c(Name ='Global_Orders_ClosedCaseEmail', Object__c='Case', Trigger__c='Global_Orders_ClosedCaseEmail', Value__c= 'TRUE');
        ID recTypeId =  DataFactory.getRecordTypeId('Case','Global Orders');
        EmailMessage emsg = new EmailMessage(FromAddress='simranjit.kaur.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', 
                                             TextBody='This is test email' );
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.FirstName = 'Test Contact';
        newCon.LastName = 'Test Contact13';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        //insert triggerSetting;
        Case testCase= new Case(RecordTypeId= recTypeId, Status = 'Closed', Subject='Test Email Case', Description='Test Email Case',
                                Priority ='Medium', Order_Team__c ='Honeywell', Cut_Off__c= 'Rush', Origin ='MYS_EMAIL_CS', NAS_Order_Number__c ='1234',
                                ContactId = newCon.id, AccountId= newAcc.id, Customer_ID__c = cusAcc.id
                               );
        insert testCase;
        String getCaseId= testCase.Id;        
        System.debug('The case id is:'+ getCaseId +' '+testCase.id);
        System.debug('The case isclosed:'+ testCase.IsClosed);
        System.debug('The case status is:'+ testCase.status);
        emsg.parentId= testCase.id;
        emsg.status = '0';
        emsg.Incoming = true;
        emsg.MessageDate =System.today(); 
        insert emsg;
        Test.stopTest();
    }
    static TestMethod void TestCaseGlobalServiceCase() {
        // Test data setup
        // Create an email message and case
        //  String caseJSON = '{"attributes":{"type":"CasSe","url":"/services/data/v25.0/sobjects/Case/500E0000002nH2fIAE"},"Id":"500E0000002nH2fIAE","Status":"Resolved","CreatedDate":"2023-05-04T17:54:26.000+0000","ClosedDate":"2023-05-04T17:54:26.000+0000"}'; 
        //  Case c = (Case)JSON.deserialize(caseJSON, Case.class); 
        //Trigger_Activation_Settings__c triggerSetting = new Trigger_Activation_Settings__c(Name ='Global_Orders_ClosedCaseEmail', Object__c='Case', Trigger__c='Global_Orders_ClosedCaseEmail', Value__c= 'TRUE');
        Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        User adminUser = new User(
            Alias = 'testuser', Email = 'testmyUnit@example.com', Username = 'testmyUnit@testmyUnit.com', CommunityNickname = 'testmyUnit', ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LastName = 'Test', FirstName = 'User', CompanyName = 'Test Company', Phone = '555-555-5555', Country ='test'
        );
        insert adminUser;
        
            ID recTypeIdService =  DataFactory.getRecordTypeId('Case','Global Service Case');
            EmailMessage emsg = new EmailMessage(FromAddress='simranjit.kaur.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', 
                                                 TextBody='This is test email' );
            Case testCase= new Case();
            Account newAcc = new Account(Name ='Test');
            Contact newCon = new Contact();
            IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            // Perform test
            Test.startTest();
            insert newAcc;
            newCon.FirstName = 'Test Contact';
            newCon.LastName = 'Test Contact14';
            newCon.AccountId = newAcc.id;
            insert newCon;
            cusAcc.Name='Test';
            cusAcc.IM_Account__c= newAcc.id;
            insert cusAcc;
            testCase.RecordTypeId =recTypeIdService;
            testCase.Subject = 'Test Email Case';
            testCase.Description = 'Test';
            testCase.Origin = 'NAS_CAC';
            testCase.ContactId = newCon.id;
            testCase.AccountId= newAcc.id;
            testCase.Customer_ID__c = cusAcc.id;
            testCase.IME_SC_Country__c ='United States';
            testCase.GSC_Category__c = 'General Enquiry';
            testCase.GSC_Sub_Category__c = 'Service Advice';
            testCase.GSC_Root_Cause__c = 'Customer education';
            testCase.Status='Resolved';
            testCase.CreatedDate = System.Today().addDays(-18);
            testCase.ClosedDate = System.Today().addDays(-15);
            string caseJSON=JSON.serialize(testCase);
            Case case1 = (Case) JSON.deserialize(caseJSON, Case.class);
        	insert case1;
        	System.debug('Test case data:'+ case1);
            emsg.parentId= case1.id;
            emsg.status = '0';
            emsg.MessageDate =System.today(); 
            emsg.Incoming = true;
        	insert emsg;
            Test.stopTest();
        
    }
    
    static TestMethod void TestCaseGlobalOrdersSwitch() {
        // Test data setup
        // Create an email message and case
        
        //  Trigger_Activation_Settings__c triggerSetting = new Trigger_Activation_Settings__c(Name ='Global_Orders_ClosedCaseEmail', Object__c='Case', Trigger__c='Global_Orders_ClosedCaseEmail', Value__c= 'TRUE');
        ID recTypeIdService =  DataFactory.getRecordTypeId('Case','Global Service Case');
        ID recTypeIdOrders =  DataFactory.getRecordTypeId('Case','Global Orders');
        EmailMessage emsg = new EmailMessage(FromAddress='simranjit.kaur.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', 
                                             TextBody='This is test email' );
        
        Case testCase= new Case(RecordTypeId= recTypeIdService, Status = 'New', Subject='Test Email Case', Origin ='MYS_Email_CS');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.FirstName = 'Test Contact';
        newCon.LastName = 'Test Contact15';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        testCase.IME_SC_Country__c ='Malaysia';
        testCase.GSC_Category__c = 'General Enquiry';
        testCase.GSC_Sub_Category__c = 'Service Advice';
        testCase.ContactId = newCon.id;
        testCase.AccountId= newAcc.id;
        testCase.Customer_ID__c = cusAcc.id;
        insert testCase;
        testCase.NAS_Order_Number__c='6789';
        testCase.RecordTypeId = recTypeIdOrders;
        update testCase;
        testCase.Status='Closed';
        update testCase;
        String getCaseId= testCase.Id;
        System.debug('The case id is:'+ getCaseId);
        System.debug('The case status is:'+ testCase.status);
        emsg.parentId= getCaseId;
        emsg.status = '0';
        emsg.incoming = true;
        emsg.MessageDate =System.today(); 
        insert emsg;
        Test.stopTest();
        
    }
    static TestMethod void TestNasGeneralSupportCase(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        User adminUser = new User(
            Alias = 'testuser', Email = 'testmyUnit@example.com', Username = 'testmyUnit@testmyUnit.com', CommunityNickname = 'testmyUnit', ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LastName = 'Test', FirstName = 'User', CompanyName = 'Test Company', Phone = '555-555-5555', Country ='test'
        );
        insert adminUser;
            ID recTypeId =  DataFactory.getRecordTypeId('Case','NAS General Support Case');
            EmailMessage emsg = new EmailMessage(FromAddress='muni.yasaswinipapani.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', 
                                                 TextBody='This is test email' );
            Account newAccount=new   Account(Name='Test Account');
            
            User newUser = new User(FirstName='Test123',LastName='User',Email='test@test.com',UserName='TestUser1234abc@test.com',ProfileId='00e80000001BNlj',Country='USA',Alias='tnews',TimeZoneSidKey='Asia/Shanghai',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US');
            
            //Case newCaseParent= new Case(RecordTypeId= recTypeId,Priority='Medium',Status='Closed',Rescheduled_order_number__c='123',Type='Destruction',Subject='New test Case Parent',NAS_Service_Line_Associated_to_Ask__c='DMS',NAS_Order_Number__c='123',NAS_Root_Cause_Reason__c='Termination',IM_Employee_Contact__c=newUser.Id,
            //                      NAS_CECOMM_Event_Status__c='Created');
            //insert newCaseParent;
            Case newCase= new Case(RecordTypeId= recTypeId,Priority='Medium',Status='Closed',Rescheduled_order_number__c='123',Type='Destruction',Subject='New test Case',NAS_Service_Line_Associated_to_Ask__c='Secure Shred',NAS_Order_Number__c='123',NAS_Root_Cause_Reason__c='Termination',
                                   NAS_CECOMM_Event_Status__c='Notified',ParentId=null,NAS_Reparent_Email_Messages__c=True, GSC_Category__c = 'General Enquiry', GSC_Sub_Category__c = 'Service Advice', IME_SC_Country__c = 'India');
            
            Contact newContact = new Contact(AccountId=newAccount.id,Email='muni.yasaswinipapani.prtnr@ironmountain.com',FirstName='Test',LastName='Acc');
            IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            Test.startTest();
            insert newAccount;
            insert newUser;
            insert newContact;
            cusAcc.Name='Test';
            cusAcc.IM_Account__c= newAccount.id;
            insert cusAcc;
            newCase.AccountId = newAccount.id;
            newCase.ContactId=newContact.id;
            newCase.IM_Employee_Contact__c=newUser.Id;
            newCase.Customer_ID__c = cusAcc.id;
            insert newCase;
            String getCaseId= newCase.Id;
            System.debug('The case id is:'+ getCaseId);
            System.debug('The case status is:'+ newCase.status);
            emsg.parentId= getCaseId;
            emsg.status = '0';
            emsg.MessageDate =System.today(); 
            emsg.Incoming = true;
                //System.runAs(adminUser){
            insert emsg;   //}
            Test.stopTest();
    }
    
    static TestMethod void TestCaseGlobalServiceCaseDefault() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        User adminUser = new User(
            Alias = 'testuser', Email = 'testmyUnit@example.com', Username = 'testmyUnit@testmyUnit.com', CommunityNickname = 'testmyUnit', ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LastName = 'Test', FirstName = 'User', CompanyName = 'Test Company', Phone = '555-555-5555', Country ='test'
        );
        insert adminUser;
        
            ID recTypeIdService =  DataFactory.getRecordTypeId('Case','Global Service Case');
            EmailMessage emsg = new EmailMessage(FromAddress='simranjit.kaur.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', 
                                                 TextBody='This is test email' );
            Case testCase= new Case();
            Account newAcc = new Account(Name ='Test');
            Contact newCon = new Contact();
            IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            // Perform test
            Test.startTest();
            insert newAcc;
            newCon.FirstName = 'Test Contact';
            newCon.LastName = 'Test Contact16';
            newCon.AccountId = newAcc.id;
            insert newCon;
            cusAcc.Name='Test';
            cusAcc.IM_Account__c= newAcc.id;
            insert cusAcc;
            testCase.RecordTypeId =recTypeIdService;
            testCase.Subject = 'Test Email Case';
            testCase.Description = 'Test';
            testCase.Origin = 'IND_SOUTH_EMAIL_CS';
            testCase.IME_SC_Country__C = 'India';
            testCase.ContactId = newCon.id;
            testCase.AccountId= newAcc.id;
            testCase.Customer_ID__c = cusAcc.id;
            testCase.GSC_Category__c = 'General Enquiry';
            testCase.GSC_Sub_Category__c = 'Service Advice';
            testCase.GSC_Root_Cause__c = 'Customer education';
            testCase.Status='Resolved';
            testCase.CreatedDate = System.Today().addDays(-18);
            testCase.ClosedDate = System.Today().addDays(-15);
            string caseJSON=JSON.serialize(testCase);
            Case case1 = (Case) JSON.deserialize(caseJSON, Case.class );
            insert case1;
            emsg.parentId= case1.id;
            emsg.status = '0';
            emsg.MessageDate =System.today(); 
            emsg.Incoming = true;
        //System.runAs(adminUser){
            insert emsg; //}
            Test.stopTest();
       
    }
    static TestMethod void TestCaseCACExecutiveEscalations() {
        ID recTypeIdService =  DataFactory.getRecordTypeId('Case','CAC Executive Escalations');
        EmailMessage emsg = new EmailMessage(FromAddress='simranjit.kaur.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', 
                                             TextBody='This is test email' );
        Case testCase= new Case();
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.FirstName = 'Test Contact';
        newCon.LastName = 'Test Contact17';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        testCase.RecordTypeId =recTypeIdService;
        testCase.Subject = 'Test Email Case';
        testCase.Description = 'Test';
        testCase.Origin = 'NAS_CAC';
        testCase.IME_SC_Country__C = 'United States';
        testCase.ContactId = newCon.id;
        testCase.AccountId= newAcc.id;
        testCase.Customer_ID__c = cusAcc.id;
        testCase.GSC_Category__c = 'General Enquiry';
        testCase.GSC_Sub_Category__c = 'Service Advice';
        testCase.GSC_Root_Cause__c = 'Collections';
        testCase.Status='Resolved';
        testCase.CreatedDate = System.Today().addDays(-18);
        testCase.ClosedDate = System.Today().addDays(-15);
        string caseJSON=JSON.serialize(testCase);
        Case case1 = (Case) JSON.deserialize(caseJSON, Case.class );
        insert case1;
        emsg.parentId= case1.id;
        emsg.status = '0';
        emsg.MessageDate =System.today(); 
        emsg.Incoming = true;
        insert emsg;
        Test.stopTest();  
    }    
    @IsTest 
    static void testEmailMessageDeletion() {
        EmailMessage emsg = [SELECT id from EmailMessage limit 1];
		   try{
                delete emsg;
                system.debug('2delete email message'+emsg);
            }catch(Exception E){
                System.debug('---do nothing----'+E.getMessage());
            }
		}
}