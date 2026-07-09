/********************************************************************************************************
* @Description: This Apex Class is test class for the class "GSCUpdateAutoFollowUpDates"
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  04/19/2024(MM/DD/YYYY)
* @MainClass Name: GSCUpdateAutoFollowUpDates
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Simranjit Kaur - Initial Development - GitLab #22253
* ===================================================
*
********************************************************************************************************/
@isTest
public class GSCUpdateAutoFollowUpDatesTest {
	@istest static void test_method(){
		List<GSCUpdateAutoFollowUpDates.DataWrapper> dw= new List<GSCUpdateAutoFollowUpDates.DataWrapper>();
    	GSCUpdateAutoFollowUpDates.DataWrapper testdata = new GSCUpdateAutoFollowUpDates.DataWrapper();
        //Creating Test Data
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'PER_EMAIL_CS', IME_SC_Country__C= 'Peru');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
    	EmailMessage emsg = new EmailMessage(FromAddress='simranjit.kaur.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', TextBody='This is test email');
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
    	emsg.Does_this_Case_Require_More_Information__c = 'Yes';
    	emsg.parentId = testCase.id;
        emsg.status = '3';
        emsg.MessageDate =System.now(); 
        emsg.Incoming = false;
    	insert emsg;
        testdata.recordID=(emsg.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        dw.add(testdata);
        System.debug(testdata);
        GSCUpdateAutoFollowUpDates.calculateAutoFollowUpDates(dw);
        Test.stopTest();
    }
    @istest static void test_method_Metadata(){
		List<GSCUpdateAutoFollowUpDates.DataWrapper> dw= new List<GSCUpdateAutoFollowUpDates.DataWrapper>();
    	GSCUpdateAutoFollowUpDates.DataWrapper testdata = new GSCUpdateAutoFollowUpDates.DataWrapper();
        //Creating Test Data
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'POL_EMAIL_CS', IME_SC_Country__C= 'Poland');
        Account newAcc = new Account(Name ='Test');
        Contact newCon = new Contact();
    	EmailMessage emsg = new EmailMessage(FromAddress='simranjit.kaur.prtnr@ironmountain.com', FromName= 'Test Name',Subject='Subject test', TextBody='This is test email');
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
    	emsg.Does_this_Case_Require_More_Information__c = 'Yes';
    	emsg.parentId = testCase.id;
        emsg.status = '3';
        emsg.MessageDate =System.now(); 
        emsg.Incoming = false;
    	insert emsg;
        testdata.recordID=(emsg.Id);
        testdata.country = (testCase.IME_SC_Country__C);
        dw.add(testdata);
        System.debug(testdata);
        GSCUpdateAutoFollowUpDates.calculateAutoFollowUpDates(dw);
        Test.stopTest();
    }
}