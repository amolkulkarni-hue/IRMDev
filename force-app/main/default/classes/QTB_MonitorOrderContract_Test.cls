@isTest(seeAllData=false)
public class QTB_MonitorOrderContract_Test {
    @IsTest
    static void testMethod1()
    {
        Test.startTest();
        insert new QTB_Manage_Contract_Scheduler__c(Name='FirstRecord',QTB_Contract_Schedueler_On__c=true,QTB_Scheduler_Hold_Time_In_Min__c=5);
        QTB_MonitorOrderContract obj = new QTB_MonitorOrderContract();
        String sch = '0 0 13 * * ?';
        String jobid=System.schedule('Schedule test', sch, obj);
        Test.stopTest();  
    }
}