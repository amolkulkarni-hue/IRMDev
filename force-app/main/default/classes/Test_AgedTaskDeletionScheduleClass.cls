@isTest
public class Test_AgedTaskDeletionScheduleClass {
	 @isTest 
    	static void testScheduler(){
            SendTaskDeleteEmail__c cs=new SendTaskDeleteEmail__c();
         cs.Name = 'Emaillist';
         cs.Emails__C = 'praneelkumar.patalay.prtnr@ironmountain.com';
        cs.AgeingDays__c = -1;
         insert cs;
        Id CaseTypeRId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
        Task t = new Task();
        t.status = 'Not Started';
        t.Due_Date__c=null;
        t.Subject='TestClass1';
        t.Description='Call Next day';
        t.Priority='High';
        t.RecordtypeId= CaseTypeRId;
        insert t;    
            String cronExpr = '0 0 0 15 3 ?';
         Test.startTest();
            AgedTaskDeletionScheduleClass abs= new AgedTaskDeletionScheduleClass();
            String jobId = System.schedule('myJobTestJobName', cronExpr, abs);
            abs.execute(null);
         Test.stopTest();
     	}
}