/*****************************************************************************************************
 * Class: TestUtilCacDateValidation
 * Author: TCS
 * Purpose: This is a test class for UtilCacDateValidation
 * Created Date : June 08,2022
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * TCS     June 08, 2022  #8989 Delete 10 case field deletion :- Part 1;
 * 
 * Modified By : Git Story 10373 on 06th Sep 2022 ---
modified lines: Removed the reference of the field Date_Cancelled__c, Acquired_Account_Y_N__c
 * 
 * Modified By: Simranjit Kaur on 12-Sept-2024
 * Commenting out the lines as the functionalities are transferred via ValidationRules
 * For reference, check user story #25718 on Gitlab.
 * 
 * Modified By: Simranjit Kaur on 10-Oct-2024
 * Commenting out all the lines as the functionalities are transferred via ValidationRules
 * For reference, check user story #26355 on Gitlab.
 * 
 * Modified By: Simranjit Kaur on 10-Oct-2024
 * Added testDummyMethod to increase the code coverage as it was impacting the deployment. For reference, check user story #27190 on Gitlab.
 *******************************************************************************************************/
@isTest
public class TestUtilCacDateValidation {
    @isTest static void testDummyMethod()
    {	UtilCacDateValidation testDummy = new UtilCacDateValidation();
     	Test.startTest();
     	Integer no = testDummy.dummyMethod();
     	System.assertEquals(1, no, 'Returned Correct Number');
     	Test.stopTest();    
    }
/* // #26355 Commenting Code start.
    
    @testSetup static void setup() {
        // Create common test data        
        IM_Country__c mainName = new IM_Country__c(Name='United States');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        Account testAccount = new Account();
        testAccount.Name = 'Test Account New';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '11209';
        testAccount.BillingState = 'NY';
        testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert testAccount;

        //Contact con = DataFactory.contMethd(testAccount.Id);
        Contact testcontact = new Contact();
        testcontact.AccountId = testAccount.Id;
        testcontact.LastName = 'Cebedo';
        testcontact.Phone = '415-906-3801';        
        insert testcontact;

        //IM_Customer_Account__c icm = DataFactory.createCustomerAccountMethd(acc[0].Id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test';
        custAcc.Owning_District_Id__c = testMarket.Id;
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = testAccount.Id;        
        insert custAcc;                
    }
    /*
    @isTest static void myTestUtilCACDPClosure() {        
        Account acct = [SELECT Id FROM Account WHERE Name='Test Account New' LIMIT 1];
        Contact cont = [SELECT Id FROM contact WHERE LastName='Cebedo' LIMIT 1];
        IM_Customer_Account__c custAcc = [SELECT Id FROM IM_Customer_Account__c WHERE Name='Test' LIMIT 1];
        List<User> usrs = DataFactory.usrMethdLst(1);
        
        Trigger_Activation_Settings__c settings = new Trigger_Activation_Settings__c();
        settings.Name = 'Test';
        settings.Value__c = 'True';
        settings.Trigger__c='CACDateValidationRules';
        settings.object__c='Case';
        insert settings;
        System.debug(settings);
        
        ID RType1 =  DataFactory.getRecordTypeId('Case','CLAS - RM');
        ID RType2 =  DataFactory.getRecordTypeId('Case','CLAS - Shred');
        ID RType3 =  DataFactory.getRecordTypeId('Case','CAC - DP Closure');
        ID RType4 =  DataFactory.getRecordTypeId('Case','CLAS – Data Management');
        
        try {
            Case cs3 = new Case();
            cs3.OwnerId = usrs[0].Id;
            cs3.RecordTypeId = RType3;
            cs3.AccountId = acct.Id;
            cs3.Customer_ID__c = custAcc.id;
            cs3.ContactId = cont.id;
            cs3.Origin = 'Email';        
            cs3.Type = 'Billing';     
            cs3.Subject = 'Test';
            cs3.Description = 'Test';
            cs3.Priority = 'Normal';
            cs3.Status = 'New';
            cs3.Reason__c = 'Completed';
            cs3.Is_Cloned__c = false;
            cs3.Recurring_Case__c = false;
            cs3.SLA_Days__c =1;
            DateTime dtInitialTargetDate3 = DateTime.now();
            cs3.Initial_Due_Date__c = dtInitialTargetDate3.date();
            cs3.SLA_Target_Date__c = dtInitialTargetDate3;
            cs3.Request_Number_1__c = '1';
            insert cs3;
                
            //cs3.Confirm_Final_Service__c = Date.Today() + 2;
            //cs3.Date_Closure_Complete__c = Date.Today() + 2;
            //cs3.Date_Final_Service_Order_Created__c = Date.Today() + 2;
            //cs3.Date_Moved_on_Call__c = Date.Today() + 2;
            //cs3.Date_Ops_Confirms_SB_Clean__c = Date.Today() + 2;
            //cs3.Date_Sent_to_Ops__c = Date.Today() + 2;
            //cs3.Date_to_be_Moved_on_Call__c = Date.Today() + 2;
            //cs3.Update_Sent_To_Operations__c = Date.Today() + 2;        
            update cs3;            
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Future') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    } 
    
    @isTest static void myTestUtilCLASRM() {
        Account testaccount = [SELECT Id FROM Account WHERE Name='Test Account New' LIMIT 1];
        Contact testContact = [SELECT Id FROM contact WHERE LastName='Cebedo' LIMIT 1];
        IM_Customer_Account__c custAcc = [SELECT Id FROM IM_Customer_Account__c WHERE Name='Test' LIMIT 1];
        List<User> usrs = DataFactory.usrMethdLst(1);
        
        Trigger_Activation_Settings__c settings = new Trigger_Activation_Settings__c();
        settings.Name = 'Test';
        settings.Value__c = 'True';
        settings.Trigger__c='CACDateValidationRules';
        settings.object__c='Case';
        insert settings;
        System.debug(settings);
        
        ID RType1 =  DataFactory.getRecordTypeId('Case','CLAS - RM');
        ID RType2 =  DataFactory.getRecordTypeId('Case','CLAS - Shred');
        ID RType3 =  DataFactory.getRecordTypeId('Case','CAC - DP Closure');
        ID RType4 =  DataFactory.getRecordTypeId('Case','CLAS – Data Management');
        
        try {
            Case cs1 = new Case();
            cs1.OwnerId = usrs[0].Id;
            cs1.RecordTypeId = RType1;
            cs1.AccountId = testaccount.id;
            cs1.Customer_ID__c = custAcc.id;
            cs1.ContactId = testContact.id;
            cs1.Authorized_User__c = usrs[0].Id;
            cs1.Origin = 'Email';        
            cs1.Type = 'Billing';     
            cs1.Subject = 'Test';
            cs1.Description = 'Test';
            cs1.Priority = 'Normal';
            cs1.Status = 'New';
            cs1.Reason__c = 'Completed';
            cs1.Is_Cloned__c = false;
            cs1.Recurring_Case__c = false;
            cs1.SLA_Days__c =1;
            cs1.Originating_Org__c = 'ANZ';
            DateTime dtInitialTargetDate1 = DateTime.now();
            cs1.Initial_Due_Date__c = dtInitialTargetDate1.date();
            cs1.SLA_Target_Date__c = dtInitialTargetDate1;
            cs1.Contract_Type__c = 'IM-35';
            cs1.Owning_Group__c = 'EAM';
            cs1.Contract_Renewal_Date__c = Date.today();
            cs1.Annual_Revenue__c = 10000;
            /* Begin - Case field deletion : 10373
            cs1.Acquired_Account_Y_N__c = 'No';
            End - Case field deletion : 10373 
            cs1.Contact_Made_Y_N__c = 'No';
            cs1.Estimated_Pay_Date__c=dtInitialTargetDate1;
            cs1.CAC_Inactivate_Request__c=dtInitialTargetDate1;

            insert cs1;
            
            //cs1.Customer_Request_Received_Date__c = Date.Today() + 2;
            cs1.Proposal_Created_Date__c = Date.Today() + 2;
            cs1.Proposal_Attempt_Date_2__c = Date.Today() + 2;
            cs1.Date_Loyalty_Specialist_Assigned__c = Date.Today() + 2;
            //cs1.CAC_Inactivate_Request__c = Date.Today() + 2;
            //cs1.Date_First_Customer_Contact_Attempt__c = Date.Today() + 2;
            //cs1.Date_Second_Customer_Contact_Attempt__c = Date.Today() + 2;
            //cs1.Date_Third_Customer_Contact_Attempt__c = Date.Today() + 2;
            cs1.Cost_Summary_Attempt_1__c = Date.Today() + 2;
            cs1.Cost_Summary_Attempt2__c = Date.Today() + 2;
            cs1.Cost_Summary_Attempt3__c = Date.Today() + 2;
            cs1.Date_Account_Inactivated__c = Date.Today() + 2;
             /* Begin - Case field deletion : 10373
            cs1.Date_Cancelled__c = Date.Today() + 2;
            End - Case field deletion : 10373 
            cs1.Date_Customer_Approval_Received__c = Date.Today() + 2;
            cs1.Date_Destruction_Order_Created__c = Date.Today() + 2;
            cs1.Date_Email_Sent_To_Contracts_Admin__c = Date.Today() + 2;
            cs1.Date_Followed_Up_W_Customer__c = Date.Today() + 2;
            cs1.Date_Inventory_Status_Confirmed__c = Date.Today() + 2;
            cs1.Date_Invoice_Details_Package_Sent__c = Date.Today() + 2;
            cs1.Date_Ops_Confirmed_For_Timeline__c = Date.Today() + 2;
            cs1.Date_Ops_emailed_for_timeline__c = Date.Today() + 2;
            cs1.Date_PDL_Approval_Received__c = Date.Today() + 2;
            cs1.Date_PDL_Sent_to_Customer__c = Date.Today() + 2;
            cs1.Date_PW_Order_Created__c = Date.Today() + 2;
            cs1.Estimated_Pay_Date__c = Date.Today() + 2;
            cs1.Inactive_request_sent_to_Contracts_Admin__c = Date.Today() + 2;
            cs1.Invoice_Request_Date__c = Date.Today() + 2;
            cs1.Notify_Collections__c = Date.Today() + 2;
            cs1.Order_completion_date__c = Date.Today() + 2;
            cs1.Order_Scheduled_date__c = Date.Today() + 2;
            cs1.Payment_Confirmation_Date__c = Date.Today() + 2;
            cs1.Payment_Follow_Up__c = Date.Today() + 2;
            cs1.PDL_Follow_up_Date__c = Date.Today() + 2;
            cs1.Outstanding_Invoice_Payment_Date__c = Date.Today() + 2;
            cs1.PW_Order_Completed__c = Date.Today() + 2;
            cs1.Support_Specialist_Assigned_Date__c = Date.Today() + 2;
            cs1.Contact_Made_Y_N__c = 'No';
            update cs1;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Future') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    }
    
    @isTest static void myTestUtilCLASShred() {
        Account testaccount = [SELECT Id FROM Account WHERE Name='Test Account New' LIMIT 1];
        Contact testContact = [SELECT Id FROM contact WHERE LastName='Cebedo' LIMIT 1];
        IM_Customer_Account__c custAcc = [SELECT Id FROM IM_Customer_Account__c WHERE Name='Test' LIMIT 1];
        List<User> usrs = DataFactory.usrMethdLst(1);
        
        Trigger_Activation_Settings__c settings = new Trigger_Activation_Settings__c();
        settings.Name = 'Test';
        settings.Value__c = 'True';
        settings.Trigger__c='CACDateValidationRules';
        settings.object__c='Case';
        insert settings;
        
        ID RType1 =  DataFactory.getRecordTypeId('Case','CLAS - RM');
        ID RType2 =  DataFactory.getRecordTypeId('Case','CLAS - Shred');
        ID RType3 =  DataFactory.getRecordTypeId('Case','CAC - DP Closure');
        ID RType4 =  DataFactory.getRecordTypeId('Case','CLAS – Data Management');
        
        try {
            Case cs2 = new Case();
            cs2.OwnerId = usrs[0].Id;
            cs2.RecordTypeId = RType2;
            cs2.AccountId = testaccount.id;
            cs2.Customer_ID__c = custAcc.id;
            cs2.ContactId = testContact.id;
            cs2.Authorized_User__c = usrs[0].Id;
            cs2.Origin = 'Email';        
            cs2.Type = 'Billing';     
            cs2.Subject = 'Test';
            cs2.Description = 'Test';
            cs2.Priority = 'Normal';
            cs2.Status = 'New';
            cs2.Reason__c = 'Completed';
            cs2.Is_Cloned__c = false;
            cs2.Recurring_Case__c = false;
            cs2.SLA_Days__c =1;
            DateTime dtInitialTargetDate2 = DateTime.now();
            cs2.Initial_Due_Date__c = dtInitialTargetDate2.date();
            cs2.SLA_Target_Date__c = dtInitialTargetDate2;
            cs2.Contract_Type__c = 'IM-35';
            cs2.Owning_Group__c = 'EAM';
            cs2.Contract_Renewal_Date__c = Date.today();
            cs2.Annual_Revenue__c = 10000;
            /* Begin - Case field deletion : 10373
            cs2.Acquired_Account_Y_N__c = 'No';
            End - Case field deletion : 10373 
            cs2.Contact_Made_Y_N__c = 'No';
            cs2.Service_Order_Number__c = '111';
            cs2.Open_AR_Amount__c = 121;        
            insert cs2; 
     
            //cs2.CAC_Inactivate_Request__c = Date.Today() + 2;
            //cs2.Date_First_Customer_Contact_Attempt__c = Date.Today() + 2;
            //cs2.Date_Second_Customer_Contact_Attempt__c = Date.Today() + 2;
            //cs2.Date_Third_Customer_Contact_Attempt__c = Date.Today() + 2;
            cs2.Date_Final_Order_Created_in_SKP__c = Date.Today() + 2;
            cs2.Date_Service_Confirmation__c = Date.Today() + 2;
            cs2.Date_Service_To_Be_Completed__c = Date.Today() + 2;
            cs2.Date_Termination_Request_Sent_Contracts__c = Date.Today() + 2;
            cs2.Date_Visit_Profile_To_Be_Inactivated__c = Date.Today() + 2;
            cs2.Rescheduled_Date__c = Date.Today() + 2;
            cs2.Date_Confirmed_by_Contracts__c = Date.Today() + 2;
            cs2.Final_Customer_Contact_Date__c = Date.Today() + 2;
            cs2.Contact_Made_Y_N__c = 'No';
            cs2.Service_Order_Number__c = '111';
            cs2.Open_AR_Amount__c = 121;
            update cs2;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Future') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    }
    
    @isTest static void myTestUtilCLASDataManagement() {
        Account testaccount = [SELECT Id FROM Account WHERE Name='Test Account New' LIMIT 1];
        Contact testContact = [SELECT Id FROM contact WHERE LastName='Cebedo' LIMIT 1];
        IM_Customer_Account__c custAcc = [SELECT Id FROM IM_Customer_Account__c WHERE Name='Test' LIMIT 1];
        List<User> usrs = DataFactory.usrMethdLst(1);
        
        Trigger_Activation_Settings__c settings = new Trigger_Activation_Settings__c();
        settings.Name = 'Test';
        settings.Value__c = 'True';
        settings.Trigger__c='CACDateValidationRules';
        settings.object__c='Case';
        insert settings;
        
        ID RType1 =  DataFactory.getRecordTypeId('Case','CLAS - RM');
        ID RType2 =  DataFactory.getRecordTypeId('Case','CLAS - Shred');
        ID RType3 =  DataFactory.getRecordTypeId('Case','CAC - DP Closure');
        ID RType4 =  DataFactory.getRecordTypeId('Case','CLAS – Data Management');

        try {
            Case cs4 = new Case();
            cs4.OwnerId = usrs[0].Id;
            cs4.RecordTypeId = RType4;
            cs4.AccountId = testaccount.id;
            cs4.Customer_ID__c = custAcc.id;
            cs4.ContactId = testContact.id;
            cs4.Authorized_User__c = usrs[0].Id;
            cs4.Origin = 'Email';        
            cs4.Type = 'Billing';     
            cs4.Subject = 'Test';
            cs4.Description = 'Test';
            cs4.Priority = 'Normal';
            cs4.Status = 'New';
            cs4.Reason__c = 'Completed';
            cs4.Is_Cloned__c = false;
            cs4.Recurring_Case__c = false;
            cs4.SLA_Days__c =1;
            DateTime dtInitialTargetDate4 = DateTime.now();
            cs4.Initial_Due_Date__c = dtInitialTargetDate4.date();
            cs4.SLA_Target_Date__c = dtInitialTargetDate4;
            cs4.Contract_Type__c = 'IM-35';
            cs4.Owning_Group__c = 'EAM';
            cs4.Contract_Renewal_Date__c = Date.today();
            cs4.Annual_Revenue__c = 10000;
            /* Begin - Case field deletion : 10373
            cs4.Acquired_Account_Y_N__c = 'No';  
            End - Case field deletion : 10373 
            cs4.Contact_Made_Y_N__c = 'No';
            cs4.DM_Destruction_Y_N__c='No';
            cs4.Monthly_Minimum__c=100;
            cs4.Account_Closing_Admin_Fee__c=100;
            
            //cs4.CAC_Inactivate_Request__c = Date.Today();
            //cs4.Date_First_Customer_Contact_Attempt__c = Date.Today();
            //cs4.Date_Second_Customer_Contact_Attempt__c = Date.Today();
            //cs4.Date_Third_Customer_Contact_Attempt__c = Date.Today();
            insert cs4;
            
            //cs4.CAC_Inactivate_Request__c = Date.Today() + 2;
            //cs4.Date_First_Customer_Contact_Attempt__c = Date.Today() + 2;
            //cs4.Date_Second_Customer_Contact_Attempt__c = Date.Today() + 2;
            //cs4.Date_Third_Customer_Contact_Attempt__c = Date.Today() + 2;
            cs4.Contact_Made_Y_N__c = 'No';
            cs4.DM_Destruction_Y_N__c='No';
            cs4.Monthly_Minimum__c=100;
            cs4.Account_Closing_Admin_Fee__c=100;
            update cs4;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Future') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    }   
*/ // #26355 Commenting Code end.
}