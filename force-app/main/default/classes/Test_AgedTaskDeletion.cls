@isTest
public class Test_AgedTaskDeletion {
    @isTest static void testDeleteTaskmethod(){
      /*  SendTaskDeleteEmail__c setting=new SendTaskDeleteEmail__c();
         setting.Name = 'Emaillist';
         setting.Emails__C = 'praneelkumar.patalay.prtnr@ironmountain.com';
        setting.AgeingDays__c = -1;
         insert setting;        
        Task tsk = new Task();
        tsk.status = 'Not Started';
        tsk.Due_Date__c=null;
        tsk.Subject='TestClass1';
        tsk.Description='Call Next day';
        insert tsk; 
        Test.startTest();
        AgedTaskDeletion atd = new AgedTaskDeletion();
        database.executeBatch(atd);
        Test.stopTest();*/
        //task error method
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
        t.IsRecurrence=false;
        insert t;
        user u=[select id,Name from user where profile.Name='IM_Sales' and isActive=true limit 1];
        system.runAs(u){
        Test.startTest();
        AgedTaskDeletion atds = new AgedTaskDeletion();
        database.executeBatch(atds);
        Test.stopTest();
    }
    
    }
}