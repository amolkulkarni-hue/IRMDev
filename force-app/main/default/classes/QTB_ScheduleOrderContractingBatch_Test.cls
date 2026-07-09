@isTest(seeAllData=false)
public class QTB_ScheduleOrderContractingBatch_Test {
@IsTest
    static void testMethod2() {
     //List<Credit_ReBill_InvoiceSchedulerValidation__c > cr=new  List<Credit_ReBill_InvoiceSchedulerValidation__c >();
      
    List<user> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
        Test.startTest();
        String sch1 ='0 0 13 * * ?'; 
        insert new QTB_Manage_Contract_Scheduler__c(Name='FirstRecord',QTB_Contract_Schedueler_On__c=true,QTB_Scheduler_Hold_Time_In_Min__c=5);
        insert new Credit_ReBill_InvoiceSchedulerValidation__c(Name='United States',isRunning__c=true,	Date_Time__c=system.now());
        QTB_ScheduleOrderContractingBatch batch=new  QTB_ScheduleOrderContractingBatch();
        system.schedule('Test status1', sch1,batch);
        Test.stopTest(); 
        System.assertEquals(2,userList.size());    
    }
    }
  

 }