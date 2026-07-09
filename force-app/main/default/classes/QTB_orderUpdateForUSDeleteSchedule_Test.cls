/*****************************************************************************************************
 * Class: QTB_orderUpdateForUSDeleteSchedule_Test
 * QTB_orderUpdateForUSDeleteSchedule_Test
 * Author: Virtusa
 * Purpose: This is test class for QTB_orderUpdateForUSDeleteSchedule
 * Requirement: GIT# epics/2939

 *******************************************************************************************************/
@isTest(seeAllData=false)
public class QTB_orderUpdateForUSDeleteSchedule_Test {
@IsTest
  static void testMethod1() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
    QTB_orderUpdateForUSDeleteSchedule batch=new  QTB_orderUpdateForUSDeleteSchedule();
    String sch ='0 0 * * * ?';
    system.schedule('Test status Check', sch,batch );
	Test.stopTest();
    System.assertEquals(2,userList.size());    
         
}
  }
}