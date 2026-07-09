/**  
       * Name: IRM_SC_CaseTriggerTestClass
       * Description: Test class for IME_SC_caseTriggerclass and IME_SC_fetchupdateQueue
       * Copyright: HCL Technologies
       * Author: Himanshu Jain
       * Modification Log: Created:6-Mar-2012
**/


@isTest
private class IRM_SC_CaseTriggerTestClass {

static testMethod void myUnitTest() {

        test.startTest();
        ID recTypeId =  DataFactory.getRecordTypeId('Case','IME SC Case');
        ID recTypeIdnew =  DataFactory.getRecordTypeId('Case','IM Employees Support Case');
        //RecordType caseRecordType = [select id from RecordType where name='IME SC Case'];
        //RecordType caseRecordTypeOnBoarding = [select id from RecordType where name='IM Employees Support Case'];

        // List of cases which need to Insert and update
        List<case> testCases = new List<case>();
        List<case> updateCases = new List<case>();
        // To Check Trigger is bulkification
        case testCase4 = new case();
        testCase4.Status = 'New';
        testCase4.RecordTypeId = recTypeId;
        testCase4.End_Time_Cutoff_SLA__c = System.now().addhours(1);
        testCase4.Origin = 'GBR_EMAIL_SC'; 
        testCases.add(testCase4);
        for(integer i=0; i<20; i++)
        {
            case testCase = new case();
            testCase.Status = 'New';
            testCase.RecordTypeId = recTypeId;
            testCase.Origin = 'AUS_EMAIL_ACT'; 
            testCase.IME_SC_Category__c= 'Order Enquiry';
            testCase.IME_SC_Sub_Category__c = 'Change an order';
            //testCase.IME_SC_Add_Cut_Off__c = true;        
            testCase.IME_SC_Request_Type__c = 'Order';
            testCase.IME_SC_Order_Id__c = '1';
            testCase.IME_SC_Number_of_Line_Items__c = 1;
            testCases.add(testCase);
        }
         
        List<Account> listTestAccount = new List<Account>();
         //Creation of Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        listTestAccount.add(testAccount);
        Account testAccount2 = new Account(Name='Test Account', BillingCountry = 'Australia');
        listTestAccount.add(testAccount2);
        insert listTestAccount;
        
        //Creation of Contact
        Contact caseContact = new Contact(FirstName = 'Test', accountid = listTestAccount[1].id,  LastName = 'User', MailingCountry = 'Australia');
        insert caseContact;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'United Kingdom');
        insert country;
        
        List<IM_Customer_Account__c> caseCustomerAccountlist = new List<IM_Customer_Account__c>();
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = 'TestCusAccount12389',
                                                     Billing_Country__c = country.Id, IM_Account__c = listTestAccount[1].id);
       caseCustomerAccountlist.add(caseCustomerAccount);
       IM_Customer_Account__c caseCustomerAccount1 = new IM_Customer_Account__c(Name = 'TestCusAccount123456',
                                                     Billing_Country__c = country.Id, IM_Account__c = listTestAccount[0].id);                                              
        caseCustomerAccountlist.add(caseCustomerAccount1);
        insert caseCustomerAccountlist;
        
        case testCase1 = new case();
        testCase1.Status = 'New';
        testCase1.RecordTypeId = recTypeId;
        testCase1.Origin = 'GBR_EMAIL_SC'; 
        testCase1.IME_SC_Category__c= 'Order Enquiry';
        testCase1.IME_SC_Sub_Category__c = 'Change an order';
        testCase1.IME_SC_Customer_ID__c = 'TestCusAccount12389';      
        testCase1.IME_SC_Request_Type__c = 'Order';
        testCase1.IME_SC_Order_Id__c = '1';
        testCase1.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCase1);
        IRM_SC_CaseTriggerClass caseTrigger = new IRM_SC_CaseTriggerClass();
        caseTrigger.customerAccount(testCases);
        case testCase2 = new case();
        testCase2.Status = 'New';
        testCase2.RecordTypeId = recTypeId;
        testCase2.AccountID = listTestAccount[1].id;
        testCase2.Origin = 'Internal-Other'; 
        testCase2.IME_SC_Category__c= 'Order Enquiry';
        testCase2.IME_SC_Sub_Category__c = 'Change an order';
        //testCase2.IME_SC_Customer_ID__c = 'TestCusAccount12389';      
        testCase2.IME_SC_Request_Type__c = 'Order';
        testCase2.IME_SC_Order_Id__c = '1';
        testCase2.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCase2);
        
        case testCase3 = new case();
        testCase3.Status = 'New';
        testCase3.RecordTypeId = recTypeId;
        testCase3.ContactID = caseContact.id; 
        testCase3.Origin = 'Internal-Other'; 
        testCase3.IME_SC_Category__c= 'Order Enquiry';
        testCase3.IME_SC_Sub_Category__c = 'Change an order';
        testCase3.IME_SC_Customer_ID__c = 'TestCusAccount12389';      
        testCase3.IME_SC_Request_Type__c = 'Order';
        testCase3.IME_SC_Order_Id__c = '1';
        testCase3.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCase3);
        
        
        
        // To check when cutOff Time is selected as 'Half Time'
        case testCaseHalfDay = new case();
        testCaseHalfDay.Status = 'New';
        testCaseHalfDay.RecordTypeId = recTypeId;
        testCaseHalfDay.Origin = 'AUS_EMAIL_ACT'; 
        testCaseHalfDay.IME_SC_Category__c= 'Order Enquiry';
        testCaseHalfDay.IME_SC_Sub_Category__c = 'Change an order';    
        testCaseHalfDay.IME_SC_Request_Type__c = 'Order';
        testCaseHalfDay.IME_SC_Customer_ID__c = 'TestCusAccount12389';
        testCaseHalfDay.IME_SC_Order_Id__c = '1';
        testCaseHalfDay.Subject = 'Test Half Day'; 
        //insert testCaseHalfDay;
        testCaseHalfDay.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCaseHalfDay);
        
        case testOnBoarding = new case();
        testOnBoarding.Status = 'New';
        testOnBoarding.RecordTypeId = recTypeIdnew;
        testOnBoarding.AccountID = listTestAccount[1].id;
        testOnBoarding.ContactID = caseContact.id; 
        //testOnBoarding.IM_Employee_Contact__c = caseContact.id;       
        testOnBoarding.IME_SC_Request_Type__c = 'Order';
        testOnBoarding.IME_SC_Country__c = 'France';
       
        testOnBoarding.Subject = 'Test On Boarding 123'; 
        testOnBoarding.Related_To__c = 'Customer Account/Client Code';
        testOnBoarding.Issue__c = 'Account Set Up';
         testOnBoarding.IME_SC_Number_of_Line_Items__c = 1;
        testOnBoarding.IM_Division__c = 'IME';
        //insert testCaseHalfDay;
        testCases.add(testOnBoarding); 
       
        // To check when cutOff Time is selected as 'Standard'
        case testCaseCutOff = new case();
        testCaseCutOff.Status = 'New';
        testCaseCutOff.Origin = 'ROM_EMAIL_ORDERS'; 
        testCaseCutOff.IME_SC_Category__c= 'Order Enquiry';
        testCaseCutOff.IME_SC_Sub_Category__c = 'Change an order';
        //testCaseCutOff.IME_SC_Add_Cut_Off__c = true;
        
        testCaseCutOff.IME_SC_Request_Type__c = 'Order';
        testCaseCutOff.IME_SC_Order_Id__c = '1';
        testCaseCutOff.Subject = 'Test Standard';
        testCaseCutOff.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCaseCutOff);
        //insert testCaseCutOff; 
        
        // To check when cutOff Time is selected as '11:30'
        case testCaseOrigin = new case();
        testCaseOrigin.Status = 'New';
        testCaseOrigin.RecordTypeId = recTypeId;
        testCaseOrigin.Origin = 'ROM_EMAIL';
        testCaseOrigin.AccountID = listTestAccount[0].id;
        testCaseOrigin.IME_SC_Category__c= 'Order Enquiry';
        testCaseOrigin.IME_SC_Sub_Category__c = 'Change an order';
        testCaseOrigin.IME_SC_Order_Id__c = '1';
        testCaseOrigin.IME_SC_Request_Type__c = 'Order';
        testCaseOrigin.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCaseOrigin);
       
        
        
        case testCaseOrigin930 = new case();
        testCaseOrigin930.Status = 'New';
        testCaseOrigin930.RecordTypeId = recTypeId;
        testCaseOrigin930.Origin = 'GBR_EMAIL_SC'; 
        testCaseOrigin930.IME_SC_Category__c= 'Order Enquiry';
        testCaseOrigin930.IME_SC_Sub_Category__c = 'Change an order';
        //testCaseOrigin930.IME_SC_Add_Cut_Off__c = true;
        testCaseOrigin930.IME_SC_Order_Id__c = '1';
        testCaseOrigin930.IME_SC_Request_Type__c = 'Order';
        testCaseOrigin930.IME_SC_Cut_Off_Time__c = '15:30';
            testCaseOrigin930.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCaseOrigin930);  
        
        case testCaseOriginManual = new case();
        testCaseOriginManual.Status = 'New';
        testCaseOriginManual.RecordTypeId = recTypeId;
        testCaseOriginManual.Origin = 'ROM_EMAIL_ORDERS'; 
        testCaseOriginManual.IME_SC_Category__c= 'Order Enquiry';
        testCaseOriginManual.IME_SC_Sub_Category__c = 'Change an order';
        //testCaseOrigin930.IME_SC_Add_Cut_Off__c = true;
        testCaseOriginManual.IME_SC_Order_Id__c = '1';
        testCaseOriginManual.IME_SC_Request_Type__c = 'Order';
        testCaseOriginManual.IME_SC_Cut_Off_Time__c = 'Manual';
            testCaseOriginManual.IME_SC_Number_of_Line_Items__c = 1;
        testCaseOriginManual.End_Time_cutoff_SLA__c = System.now().addhours(24);
        testCases.add(testCaseOriginManual);    
        
        //To check whether country in populatating based on account billingCountry field value
        case testCaseAccount = new case();
        testCaseAccount.Status = 'New';
        testCaseAccount.RecordTypeId = recTypeId;
        testCaseAccount.accountID = listTestAccount[1].id;
        testCaseAccount.IME_SC_Category__c= 'Order Enquiry';
        testCaseAccount.IME_SC_Sub_Category__c = 'Change an order';
        testCaseAccount.ContactId = caseContact.id;
        testCaseAccount.IME_SC_Order_Id__c ='1';
        testCaseAccount.IME_SC_Request_Type__c = 'Order';
        testCaseAccount.IME_SC_Cut_Off_Time__c = 'Standard (8 Hours)';
         testCaseAccount.Closure_Reason__c = 'Value 1';
         testCaseAccount.Subject = 'Test Account';
        
         //testCaseAccount.IME_SC_Customer_ID__c = '123';
         testCaseAccount.IME_SC_Closure_Reason__c = 'Cancelled';
         
        testCaseAccount.IME_SC_Number_of_Line_Items__c = 1;
        
        testCaseAccount.IME_SC_Case_Cause__c = 'Completed';
        //testCaseAccount.Status = 'Closed';
        testCases.add(testCaseAccount);
        
        case testCaseContact = new case();
        testCaseContact.Status = 'New';
        testCaseContact.RecordTypeId = recTypeId;
        testCaseContact.ContactId = caseContact.id;
        testCaseContact.IME_SC_Category__c= 'Order Enquiry';
        testCaseContact.IME_SC_Sub_Category__c = 'Change an order';
        testCaseContact.IME_SC_Order_Id__c = '1';
        testCaseContact.IME_SC_Request_Type__c = 'Order';
        testCaseContact.IME_SC_Cut_Off_Time__c = 'Half Day (4 Hours)';
        testCaseContact.IME_SC_Number_of_Line_Items__c = 1;
        testCases.add(testCaseContact);
        
        
        case testcaseCustomerAccount = new case();
        testcaseCustomerAccount.Status = 'In Progress';
        testcaseCustomerAccount.RecordTypeId = recTypeId;
        testcaseCustomerAccount.IME_SC_Customer_AccountId__c = caseCustomerAccountlist[1].id;
        testCase1.IME_SC_Customer_ID__c = 'TestCusAccount12389';   
        testcaseCustomerAccount.IME_SC_Category__c= 'Complaints';
        testcaseCustomerAccount.IME_SC_Sub_Category__c = 'Order not received';
        testcaseCustomerAccount.IME_SC_Request_Type__c = 'Order';
         testcaseCustomerAccount.IME_SC_Order_Id__c = '1';
        testcaseCustomerAccount.IME_SC_Number_of_Line_Items__c = 1;
        testcaseCustomerAccount.subject = 'Test Onhold';
        testCases.add(testcaseCustomerAccount);
        
        case testcaseCustomerAccount1 = new case();
        testcaseCustomerAccount1.Status = 'In Progress';
        testcaseCustomerAccount1.RecordTypeId = recTypeId;
        testcaseCustomerAccount1.IME_SC_Category__c= 'Complaints';
        testcaseCustomerAccount1.IME_SC_Sub_Category__c = 'Service Delay';
        testcaseCustomerAccount1.IME_SC_Cut_Off_Time__c = '9:30';
        testcaseCustomerAccount1.subject = 'Test Onhold';
        testCases.add(testcaseCustomerAccount1);
        // To check again cutOff Time is selected as 'Half Day' for the case where cutOff Time is already selected as 'Half Day'
       
        try
        {
         insert(testCases);
        
        Case CaseCutOff1;
        Case caseOnhold;
        List<case> CaseCutOff  = [select id, IME_SC_Cut_Off_Time__c, Closure_Reason__c, subject, Status from case where subject In ('Test On Boarding 123', 'Test Onhold') ];
        
        
        for(case caseAssign : CaseCutOff)
        {
            if(caseAssign.subject == 'Test On Boarding 123')
            {
                CaseCutOff1 = caseAssign;
            }
            if(caseAssign.subject == 'Test Onhold')
            {
                caseOnhold = caseAssign;
            }
        }
        caseComment newComment = new caseComment(parentId = CaseCutOff1.id);
        Insert newComment;
        
        
        CaseCutOff1.Status  = 'Closed';
        CaseCutOff1.IME_SC_Cut_Off_Time__c = null;
        CaseCutOff1.Closure_Reason__c = 'Value1';
        CaseCutOff1.IME_SC_Case_Cause__c = 'Completed';
       
        //CaseCutOff1.Comments = 'Value1';
        caseOnhold.Status  = 'On Hold - Internal';
        updateCases.add(caseOnhold);
        updateCases.add(CaseCutOff1);
        
        //update updateCases;
        Test.stopTest();
        update updateCases;            
       }
    
    
        catch(exception exp)
       {
            //update updateCases;
            system.debug('Test');
       }
    }

}