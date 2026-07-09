@isTest
public class TestCaseandRelatedObjSchedule {
    static testmethod void test() {
        Case_Deletion_Config__c cs=new Case_Deletion_Config__c();
        cs.Name = 'Greater than 30days';
        cs.Record_types__c = 'IME SC Case,NAS General Support Case';
        cs.Ageing_Days__c = -1;
        cs.Status__c='Cancelled';
        insert cs;
        	
        Case_Deletion_Config__c cs2=new Case_Deletion_Config__c();
        cs2.Name = 'Greater than 7days';
        cs2.Record_types__c = 'Global Orders';
        cs2.Ageing_Days__c = -7;
        cs2.Status__c='Closed';
        insert cs2;
        system.debug('the customsettings:'+cs.Name);
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IME SC Case').getRecordTypeId();
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
        
        system.debug('the record type id:'+CaseTypeRId);
        
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, False);
        cnt.Email='Testcnt@gmail.com';
        insert cnt;
        System.debug('Inside Test-Account Id='+acct[0].id+'ContactId='+cnt.id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        SYSTEM.debug('Value IM account' + acct[0].Id);
        ca.RecordTypeId = CustomerTypeRId;
        ca.IM_Oracle_ID__c = '12345';
        insert ca;
        list<Case> csList = new List<Case>();
        for (Integer i=0;i<2;i++) {
        Case m = new Case();
        String usrId = UserInfo.getUserId();
        m.OwnerId = usrId;
        m.RecordTypeId = CaseTypeRId;
        m.AccountId = ca.IM_Account__c;
        m.Customer_ID__c = ca.Id;
        m.Origin = 'NAS_Phone';
        m.Country__c='USA';
        m.Type = 'Billing';     
        m.Subject = 'Test ' +i;
        m.Description = 'Test' +i;
        m.Priority = 'Normal';
        m.Status = 'Cancelled';
        m.NAS_Service_Line_Associated_to_Ask__c='Data Management';
        m.ContactId= cnt.Id;
        csList.add(m);
        }
       insert csList;
        TestCasesAndRelatedUtil.insertEM(csList);
        TestCasesAndRelatedUtil.insertAttAndContent(csList);
        TestCasesAndRelatedUtil.insertRelatedRecords(csList);
        TestCasesAndRelatedUtil.insertTask(csList);
        String cronExpr = '0 0 18 ? * FRI 2022-2099';
        test.startTest();
        ScheduleDeleteCasesAndRelatedLst abs =new ScheduleDeleteCasesAndRelatedLst();
        String jobId = System.schedule('CaseandRelatedObjDeletion', cronExpr, abs);
        abs.execute(null);
        test.stopTest();
    }
    static testmethod void testGlobalOrders() {
        Case_Deletion_Config__c cs=new Case_Deletion_Config__c();
        cs.Name = 'Greater than 7days';
        cs.Record_types__c = 'Global Orders';
        cs.Ageing_Days__c = -7;
        cs.Status__c='Closed';
        insert cs;
        Case_Deletion_Config__c cs2=new Case_Deletion_Config__c();
        cs2.Name = 'Greater than 30days';
        cs2.Record_types__c = 'IME SC Case,NAS General Support Case';
        cs2.Ageing_Days__c = -1;
        cs2.Status__c='Cancelled';
        insert cs2;
        
        system.debug('the customsettings:'+cs.Name);
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Global Orders').getRecordTypeId();
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
        
        system.debug('the record type id:'+CaseTypeRId);
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, False);
        cnt.Email='Testcnt@gmail.com';
        insert cnt;
        System.debug('Inside Test-Account Id='+acct[0].id+'ContactId='+cnt.id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        ca.RecordTypeId = CustomerTypeRId;
        ca.IM_Oracle_ID__c = '12345';
        insert ca;
        list<Case> csList = new List<Case>();
        for (Integer i=0;i<2;i++) {
        Case m = new Case();
        String usrId = UserInfo.getUserId();
        m.OwnerId = usrId;
        m.RecordTypeId = CaseTypeRId;
        m.AccountId = ca.IM_Account__c;
        m.Customer_ID__c = ca.Id;
        m.Origin = 'NAS_Phone';
        m.Country__c='USA';
        m.Type = 'Billing';     
        m.Subject = 'Test ' +i;
        m.Description = 'Test' +i;
        m.Priority = 'Normal';
        m.Status = 'Cancelled';
        m.NAS_Service_Line_Associated_to_Ask__c='Data Management';
        m.ContactId= cnt.Id;
        csList.add(m);
        }
       insert csList;
        TestCasesAndRelatedUtil.insertEM(csList);
        TestCasesAndRelatedUtil.insertAttAndContent(csList);
        TestCasesAndRelatedUtil.insertRelatedRecords(csList);
        TestCasesAndRelatedUtil.insertTask(csList);
        String cronExpr = '0 0 18 ? * FRI 2022-2099';
        test.startTest();
        ScheduleDeleteCasesAndRelatedLst abs =new ScheduleDeleteCasesAndRelatedLst();
        String jobId = System.schedule('CaseandRelatedObjDeletion', cronExpr, abs);
        abs.execute(null);
        test.stopTest();
    }
}