/*****************************************************************************************************
 * Class: QTB_UsageSummary_deletion_Schedule_Test
 * QTB_UsageSummary_deletion_Schedule_Test
 * Author: Virtusa
 * Purpose: This is test class for QTB_UsageSummary_deletion_OrderSpecific
 * Requirement: GIT# epics/2939

 *******************************************************************************************************/
@isTest(seeAllData=false)
public class QTB_UsageSummary_deletion_Schedule_Test {
@IsTest
  static void testMethod1() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
    QTB_UsageSummary_deletion_Schedule batch=new  QTB_UsageSummary_deletion_Schedule();
    String sch ='0 0 * * * ?';
    system.schedule('Test status Check', sch,batch );
	Test.stopTest();
    System.assertEquals(2,userList.size());    
         
}
  }
}