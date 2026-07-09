/*****************************************************************************************************
* Class		: DeleteArchievedTasks_Test
* Author	: IRM/TCS
* Purpose	: This is a test class for DeleteArchievedTasks
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* TCS           05/06/2025      Initial draft Gitlab US : #31412
*******************************************************************************************************/
@isTest
public class DeleteArchievedTasks_Test {

    @isTest
    public static void testDeleteAtchivedTaskmethod(){
        SendTaskDeleteEmail__c cs=new SendTaskDeleteEmail__c();
        cs.Name = 'ArchivedTaskFilters';
        cs.Emails__C = 'praneelkumar.patalay.prtnr@ironmountain.com';
        cs.AgeingDays__c = -1;
        cs.includeArchivedRecords__c = true;
        cs.object__c = 'Account';
        cs.batchSize__c = 10;
        cs.numberOfRecords__c = 10;
        
        insert cs;
        
        List<Account> acct=TestingUtils.createAccounts(1,True);
        
        Task t = new Task();
        t.status = 'Not Started';
        t.Due_Date__c=null;
        t.Subject='TestClass1';
        t.Description='Call Next day';
        t.Priority='High';
        t.IsRecurrence=false;
        t.WhatId = acct[0].id;
        //t.IsArchived = true;
        insert t;
        String cronExpr = '0 1 9 * * ? *';
        Test.startTest();
       // DeleteArchievedTasks DAT = new DeleteArchievedTasks(false);
       // database.executeBatch(DAT,10);
       DeleteArchievedTasks abs= new DeleteArchievedTasks(false);
            String jobId = System.schedule('myJobTestJobNameNew', cronExpr, abs);
            abs.execute(null);

        Test.stopTest();
        
    }
    @isTest
    public static void testDeleteAtchivedTaskError(){
        SendTaskDeleteEmail__c cs=new SendTaskDeleteEmail__c();
        cs.Name = 'ArchivedTaskFilters';
        cs.Emails__C = 'praneelkumar.patalay.prtnr@ironmountain.com';
        cs.AgeingDays__c = -1;
        cs.includeArchivedRecords__c = true;
        cs.object__c = 'Account';
        cs.batchSize__c = 10;
        cs.numberOfRecords__c = 10;
        
        insert cs;
        
        List<Account> acct=TestingUtils.createAccounts(1,True);
        
        Task t = new Task();
        t.status = 'Not Started';
        t.Due_Date__c=null;
        t.Subject='TestClass1';
        t.Description='Call Next day';
        t.Priority='High';
        t.IsRecurrence=false;
        t.WhatId = acct[0].id;
        //t.IsArchived = true;
        insert t;
        String cronExpr = '0 1 9 * * ? *';
        Test.startTest();
       // DeleteArchievedTasks DAT = new DeleteArchievedTasks(false);
       // database.executeBatch(DAT,10);
       DeleteArchievedTasks abs= new DeleteArchievedTasks(true);
            String jobId = System.schedule('myJobTestJobNameNew', cronExpr, abs);
            abs.execute(null);

        Test.stopTest();
        
    }
}