/********************************************************************************************************
* @Description: This Apex Class is test class for the class "GSCFollowUpDate"
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  04/19/2024(MM/DD/YYYY)
* @MainClass Name: GSCFollowUpDate
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Simranjit Kaur - Initial Development - GitLab #22253
* ===================================================
*
********************************************************************************************************/
@isTest
public class GSCFollowUpDateTest {
	@istest static void test_method_Supervisor(){
		List<GSCFollowUpDate.DataWrapper> dw= new List<GSCFollowUpDate.DataWrapper>();
    	GSCFollowUpDate.DataWrapper testdata = new GSCFollowUpDate.DataWrapper();
        //Creating Test Data
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'PER_EMAIL_CS', IME_SC_Country__C= 'Peru');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        RecordType[] recordTypeList = [select id, name, SobjectType from RecordType where name like 'Global Service Case' and SobjectType = 'Case' Limit 1];
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.LastName = 'Test Contact';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        testCase.AccountId =newAcc.id;
        testCase.Customer_ID__c = cusAcc.id;
        testCase.ContactId = newCon.id;
        testCase.RecordTypeId = recordTypeList[0].id;
        testCase.GSC_Category__c = 'Amendment of Customer Details';
        testCase.GSC_Sub_Category__c = 'Add, Amend, Remove Authorised User';
        testCase.Status = 'In Progress';
        insert testCase;
        testCase.NAS_Pending_Reason__c = 'Supervisor';
        testCase.Status = 'Internal - On Hold';
        update testCase;
        testdata.recordID=(testCase.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        testdata.pendingReason = testCase.NAS_Pending_Reason__c;
        dw.add(testdata);
        System.debug(testdata);
        GSCFollowUpDate.calculateFollowUpDate(dw);
        Test.stopTest();
    }
    @istest static void test_method_Internal_Response(){
		List<GSCFollowUpDate.DataWrapper> dw= new List<GSCFollowUpDate.DataWrapper>();
    	GSCFollowUpDate.DataWrapper testdata = new GSCFollowUpDate.DataWrapper();
        //Creating Test Data
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'PER_EMAIL_CS', IME_SC_Country__C= 'Peru');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        RecordType[] recordTypeList = [select id, name, SobjectType from RecordType where name like 'Global Service Case' and SobjectType = 'Case' Limit 1];
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.LastName = 'Test Contact';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        testCase.AccountId =newAcc.id;
        testCase.Customer_ID__c = cusAcc.id;
        testCase.ContactId = newCon.id;
        testCase.GSC_Category__c = 'Amendment of Customer Details';
        testCase.GSC_Sub_Category__c = 'Add, Amend, Remove Authorised User';
        testCase.RecordTypeId = recordTypeList[0].id;
        testCase.Status = 'In Progress';
        insert testCase;
        testCase.NAS_Pending_Reason__c = 'Internal Response';
        testCase.GSC_Follow_up_Department__c = 'Care';
        testCase.GSC_Follow_up_Owner__c = 'Care';
        testCase.Status = 'Internal - On Hold';
        update testCase;
        testdata.recordID=(testCase.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        testdata.pendingReason = testCase.NAS_Pending_Reason__c;
        dw.add(testdata);
        System.debug(testdata);
        GSCFollowUpDate.calculateFollowUpDate(dw);
        Test.stopTest();
    }
    @istest static void test_method_Customer_Response(){
		List<GSCFollowUpDate.DataWrapper> dw= new List<GSCFollowUpDate.DataWrapper>();
    	GSCFollowUpDate.DataWrapper testdata = new GSCFollowUpDate.DataWrapper();
        //Creating Test Data
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'PER_EMAIL_CS', IME_SC_Country__C= 'Peru');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        RecordType[] recordTypeList = [select id, name, SobjectType from RecordType where name like 'Global Service Case' and SobjectType = 'Case' Limit 1];
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.LastName = 'Test Contact';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        testCase.AccountId =newAcc.id;
        testCase.Customer_ID__c = cusAcc.id;
        testCase.ContactId = newCon.id;
        testCase.RecordTypeId = recordTypeList[0].id;
        testCase.GSC_Category__c = 'Amendment of Customer Details';
        testCase.GSC_Sub_Category__c = 'Add, Amend, Remove Authorised User';
        testCase.Status = 'In Progress';
        insert testCase;
        testCase.NAS_Pending_Reason__c = 'Customer Response';
        testCase.Status = 'Customer - On Hold';
        update testCase;
        testdata.recordID=(testCase.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        testdata.pendingReason = testCase.NAS_Pending_Reason__c;
        dw.add(testdata);
        System.debug(testdata);
        GSCFollowUpDate.calculateFollowUpDate(dw);
        Test.stopTest();
    }
    @istest static void test_method_No_Business_Hours(){
		List<GSCFollowUpDate.DataWrapper> dw= new List<GSCFollowUpDate.DataWrapper>();
    	GSCFollowUpDate.DataWrapper testdata = new GSCFollowUpDate.DataWrapper();
        //Creating Test Data
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'POL_EMAIL_CS', IME_SC_Country__C= 'Poland');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        RecordType[] recordTypeList = [select id, name, SobjectType from RecordType where name like 'Global Service Case' and SobjectType = 'Case' Limit 1];
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.LastName = 'Test Contact';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        testCase.AccountId =newAcc.id;
        testCase.Customer_ID__c = cusAcc.id;
        testCase.ContactId = newCon.id;
        testCase.RecordTypeId = recordTypeList[0].id;
        testCase.GSC_Category__c = 'Amendment of Customer Details';
        testCase.GSC_Sub_Category__c = 'Add, Amend, Remove Authorised User';
        testCase.Status = 'In Progress';
        insert testCase;
        testCase.NAS_Pending_Reason__c = 'Supervisor';
        testCase.Status = 'Internal - On Hold';
        update testCase;
        testdata.recordID=(testCase.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        testdata.pendingReason = testCase.NAS_Pending_Reason__c;
        dw.add(testdata);
        System.debug(testdata);
        GSCFollowUpDate.calculateFollowUpDate(dw);
        Test.stopTest();
    }
    @istest static void test_method_No_Value_In_Metadata(){
		List<GSCFollowUpDate.DataWrapper> dw= new List<GSCFollowUpDate.DataWrapper>();
    	GSCFollowUpDate.DataWrapper testdata = new GSCFollowUpDate.DataWrapper();
        //Creating Test Data
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'POL_EMAIL_CS', IME_SC_Country__C= 'Poland');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        RecordType[] recordTypeList = [select id, name, SobjectType from RecordType where name like 'Global Service Case' and SobjectType = 'Case' Limit 1];
        // Perform test
        Test.startTest();
        insert newAcc;
        newCon.LastName = 'Test Contact';
        newCon.AccountId = newAcc.id;
        insert newCon;
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        testCase.AccountId =newAcc.id;
        testCase.Customer_ID__c = cusAcc.id;
        testCase.ContactId = newCon.id;
        testCase.RecordTypeId = recordTypeList[0].id;
        testCase.GSC_Category__c = 'Amendment of Customer Details';
        testCase.GSC_Sub_Category__c = 'Add, Amend, Remove Authorised User';
        testCase.Status = 'In Progress';
        insert testCase;
        testCase.NAS_Pending_Reason__c = 'Customer Response';
        testCase.Status = 'Customer - On Hold';
        update testCase;
        testdata.recordID=(testCase.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        testdata.pendingReason = testCase.NAS_Pending_Reason__c;
        dw.add(testdata);
        System.debug(testdata);
        GSCFollowUpDate.calculateFollowUpDate(dw);
        testCase.NAS_Pending_Reason__c = 'Internal Response';
        testCase.GSC_Follow_up_Department__c = 'Care';
        testCase.GSC_Follow_up_Owner__c = 'Care';
        testCase.Status = 'Internal - On Hold';
        update testCase;
        testdata.recordID=(testCase.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        testdata.pendingReason = testCase.NAS_Pending_Reason__c;
        dw.add(testdata);
        GSCFollowUpDate.calculateFollowUpDate(dw);
        Test.stopTest();
    }
}