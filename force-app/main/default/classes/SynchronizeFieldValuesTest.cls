/**
Auhtor       : Andrey Volosevich
Company      : Fujitsu America
Created Date : 21 Dec-2009
Description  : This is a unit test class for SynchronizeFieldValuesTest. The tested class design is in pilot mode and is likely to evolve.
               The unit testing class is kept 'light' intentionally to allow for quicker changes as the tested class design changes as well.

               This class only tests that the batch job executes successfully, but does not test the work performed by the job.
               The next step is to refactor the tested class to have the field copying logic in a separate class with its' own unit test.
*/


@isTest
private class SynchronizeFieldValuesTest {

    static Profile p = [select id from profile where name='Standard User' limit 1];
    static Map<Id, Account> testAccounts = new Map<Id, Account>();  
    
    static User u1 = new User(alias = 'btest1', username='BatchTestUser1@irm.com.test', email='BatchTestUser1@irm.com', lastname='BatchTestUser1', 
                        emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, 
                        timezonesidkey='America/Los_Angeles');
                        
    static User u2 = new User(alias = 'btest2', username='BatchTestUser2@irm.com.test', email='BatchTestUser2@irm.com', lastname='BatchTestUser2', 
                    emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, 
                    timezonesidkey='America/Los_Angeles');
        
    static void setup(){
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
          IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country; 
        for(Integer i=0; i<200; i++){
            Account a = new Account(Name = 'SynchronizeFieldValuesTest ' + i,BillingCountry='United States');
            
            testAccounts.put(a.Id, a);
        }
        insert testAccounts.values();
    }       


    static testMethod void runTest() {
        
        Test.startTest();        
        
        SynchronizeFieldValuesTest.setup();
        String query = SynchronizeFieldValues.initialQuery ;
        SynchronizeFieldValues job = new SynchronizeFieldValues(query);
        Id jobId = Database.executeBatch(job);
        SynchronizeFieldValueScheduler jobSchd = new SynchronizeFieldValueScheduler();
        DateTime objdatetime = datetime.now().addminutes(1);

        string CRON_EXP ='';
        CRON_EXP += objdatetime.Second();
        CRON_EXP += ' ' + objdatetime.minute();
        CRON_EXP += ' ' + objdatetime.hour();
        CRON_EXP += ' ' + objdatetime.day();
        CRON_EXP += ' ' + objdatetime.month();
        CRON_EXP += ' ' +'?';
        CRON_EXP += ' ' + objdatetime.year();
        
        String schJobId = System.schedule('testScheduledApex',CRON_EXP , jobSchd);         
        
        Test.stopTest();
        
	
        AsyncApexJob jobActual = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :jobId];
       System.assertEquals(jobActual.TotalJobItems, 1);
        System.assertEquals(jobActual.JobItemsProcessed, 1);
        System.assertEquals(jobActual.NumberOfErrors, 0);
        System.assertEquals(jobActual.Status, 'Completed');
        

        
    }
}