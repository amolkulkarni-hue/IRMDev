@isTest
public class QTB_ScheduleDocumetSendDeleleteTest {
    public static testMethod void testDocumentTest(){
    Test.startTest();
    QTB_ScheduleDocumentSendDelete testsche=new QTB_ScheduleDocumentSendDelete();
        string sch='0 0 23 ? * * *';
        system.schedule('Test status check', sch, testsche);
    Test.stopTest();
    }

}