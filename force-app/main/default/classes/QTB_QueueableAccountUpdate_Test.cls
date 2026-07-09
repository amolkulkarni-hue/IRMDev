/*****************************************************************************************************
 * Class: QTB_QueueableAccountUpdate_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_QueueableAccountUpdate
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_QueueableAccountUpdate_Test {
  @TestSetup
	static void createData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      Test.startTest();
      List<Account> accList = QTB_TestDataFactory.createAccounts(10); //insert 10 accounts
      System.enqueueJob(new QTB_QueueableAccountUpdate(accList));
      Test.stopTest();
      System.Assert(accList.size() == 10);
    }
  }
  //cover catch
  static testMethod void testMethod1() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      QTB_QueueableAccountUpdate.throwExplicitException = true;
      QTB_QueueableAccountUpdate obj = new QTB_QueueableAccountUpdate(null);
      Test.stopTest();
      try {
        obj.execute(null);
      } catch (Exception e) {
        System.assert('Script-thrown exception' == e.getMessage());
      }

      System.assertEquals(
        true,
        QTB_QueueableAccountUpdate.throwExplicitException
      );
    }
  }
}