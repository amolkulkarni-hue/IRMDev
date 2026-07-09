@isTest
public class Test_ScheduleIMEScCaseAndRelatedLst {
    static testmethod void test() {
        IMESC_Case_Deletion_Config__c cs=new IMESC_Case_Deletion_Config__c();
         cs.Name = 'IME SC Case';
         cs.Record_types__c = 'IME SC Case Resolved';
        cs.Ageing_Days__c = -1;
        cs.Status__c='Closed';
		cs.Closure_Reason__c='Invalid Case';
		cs.Send_Email_To__c='praneelkumar.patalay.prtnr@ironmountain.com,rajashekar.kampally.prtnr@ironmountain.com';
         insert cs;
        system.debug('the customsettings:'+cs.Name);
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IME SC Case Resolved').getRecordTypeId();
        system.debug('the record type id:'+CaseTypeRId);
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True);
        System.debug('Inside Test-Account Id='+acct[0].id+'ContactId='+cnt.id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        insert ca;
        list<Case> csList = new List<Case>();
        for (Integer i=0;i<10;i++) {
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
        m.Status = 'Closed';
		m.IME_SC_Closure_Reason__c='Invalid Case';
        m.NAS_Service_Line_Associated_to_Ask__c='Data Management';
       // m.Contract_Contact_Email__c='test@gmail.com';
       // m.Contract_Contact_Name__c='testcontact';
        m.subject='Test class case';
        csList.add(m);
        }
       insert csList;
        TestCasesAndRelatedUtil.insertEM(csList);
        TestCasesAndRelatedUtil.insertAttAndContent(csList);
        TestCasesAndRelatedUtil.insertRelatedRecords(csList);
        TestCasesAndRelatedUtil.insertTask(csList);

     String cronExpr = '0 0 18 ? * FRI *';
        test.startTest();
        ScheduleIMEScCaseDelCasesAndRelatedLst abs =new ScheduleIMEScCaseDelCasesAndRelatedLst();
        String jobId = System.schedule('DeleteImeScCasesAndRelatedLst', cronExpr, abs);
        //database.executeBatch(DCR);
        abs.execute(null);
        test.stopTest();
    }
}