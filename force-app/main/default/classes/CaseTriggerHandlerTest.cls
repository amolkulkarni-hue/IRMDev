@isTest
public with sharing class CaseTriggerHandlerTest {
    @isTest
    static void CreateSupportCaseTest(){
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, False);
        cnt.Email='Testcnt@gmail.com';
        insert cnt;        
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.IM_Account__c = acct[0].Id;
        ca.RecordTypeId = CustomerTypeRId;
        insert ca;
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Global Orders').getRecordTypeId();
        Case testCase;        
        list<Case> csList = new List<Case>();
        for (Integer i=0;i<2;i++) {
        Case m = new Case();
        String usrId = UserInfo.getUserId();
        m.OwnerId = usrId;
        m.RecordTypeId = CaseTypeRId;
        m.AccountId = ca.IM_Account__c;
        m.Customer_ID__c = ca.Id;
        m.Origin = 'NAS_EM_Orders';
        m.Cut_Off__c='Rush';
        m.Order_team__C = 'Honeywell';     
        m.Subject = 'Test ' +i;
        m.Description = 'Test' +i;
        m.Priority = 'Normal';
        m.NAS_Order_Number__c = '8990' + i;
        m.Status = 'New';
        m.ContactId= cnt.Id;  

        csList.add(m);
        }       
        Test.startTest();
        CaseTriggerHandler.isRecordInserted = true;
        insert csList;
        UPDATE csList;
        DELETE csList;
    	Test.stopTest();        
    }
}