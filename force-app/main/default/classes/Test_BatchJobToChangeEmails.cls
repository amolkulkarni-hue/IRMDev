/****************************** 
   Developer Name: Madhu Paladugu
   Date          : 3/14/13
   Company Name  : CloudFountain Inc.
   Purpose       : This is test utility for SchedulerOfChaingEmails(Scheduler class) and BatchJobToChangeEmails(Batch Class).
 ********************************/   
@istest(seeAllData=true)
public class Test_BatchJobToChangeEmails {

   static testmethod void test() {
     // Initialization of Corn variable
      
    String CRON_EXP='';
     DateTime n = datetime.now().addminutes(45);
        CRON_EXP+= n.second();
        CRON_EXP+= ' ' + n.minute();
        CRON_EXP+= ' ' + n.hour();
        CRON_EXP+= ' ' + n.day();
        CRON_EXP += ' ' + n.month();
        CRON_EXP+= ' ' + '?';
        CRON_EXP+= ' ' + n.year();
     
     
     Test.startTest();
      // Creating the test data
      
      Contact c = new Contact();
      c.LastName = 'testScheduledApexFromTestMethod';
      c.Email='test@gmail.com';
      insert c;
      Lead L=new Lead();
      L.Company='test';
      L.email='test@gmail.com';
      L.IsConverted=false;
      L.LastName='test';
      L.IM_Lead_Stage__c='1-Inquiry';
      insert L;
      // Scheduling the scheduler class.
      SchedulerOfChaingEmails s=new SchedulerOfChaingEmails();
      BatchJobToChangeEmails bt=new BatchJobToChangeEmails(); 
      String jobId = System.schedule('TestSchedulerOfChaingEmails',CRON_EXP,s);
      Database.Executebatch(bt);
     
     // Get the information from the CronTrigger API object

      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];

     // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);
       
   Test.stopTest();
   
   }
}