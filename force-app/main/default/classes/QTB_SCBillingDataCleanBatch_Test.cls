/*****************************************************************************************************
 * Class: QTB_SCBillingDataCleanBatch_Test
 * QTB_SCBillingDataCleanBatch_Test
 * Author: Virtusa
 * Purpose: This is test class for QTB_SCBillingDataCleanBatch
 * Requirement: 
 * Developer     Date 06/13/2022          Description

 *******************************************************************************************************/
@isTest(seeAllData=false)
public class QTB_SCBillingDataCleanBatch_Test {
@IsTest
  static void testMethod1() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
    QTB_SCBillingDataCleanBatch batch=new  QTB_SCBillingDataCleanBatch();
    String sch ='0 0 * * * ?';
    system.schedule('Test status Check', sch,batch );
	Test.stopTest();
    System.assertEquals(2,userList.size());    
         
}
  }
}