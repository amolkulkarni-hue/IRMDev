/*****************************************************************************************************
 * Class: QTB_MassDeleteExtension_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_MassDeleteExtension
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture    6/1/2020
 *******************************************************************************************************/
@isTest(seeAlldata=false)
private class QTB_MassDeleteExtension_Test {
   @testSetup
  static void setup() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      Test.startTest();
      List<account> accountList = QTB_TestDataFactory.createAccounts(2);
       Test.stopTest();  
      System.Assert(accountList.size() == 2);  
    }
  }
     static testMethod void method1() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
        Test.startTest();
     List<account> accountList = [Select id from account limit 2];  
    ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(
        accountList
      );
      QTB_MassDeleteExtension ext = new QTB_MassDeleteExtension(
        stdSetController
      );
      ext.getMySelectedSize();
      ext.deleteRecords();
      Test.stopTest();
      System.Assert(accountList.size() == 2);
    }
  }
  static testMethod void testDataMethod() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
        
      QTB_MassDeleteExtension.throwExplicitException = true;
       List<account> accountList = [Select id from account limit 2];  
       ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(
        accountList
      );
      QTB_MassDeleteExtension ext = new QTB_MassDeleteExtension(
        stdSetController
      );
      ext.getMySelectedSize();
      ext.deleteRecords();
      Test.stopTest();
      System.assertEquals(true, QTB_MassDeleteExtension.throwExplicitException);
    }
  }
}