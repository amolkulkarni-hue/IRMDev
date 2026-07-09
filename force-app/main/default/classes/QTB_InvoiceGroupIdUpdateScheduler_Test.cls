/*****************************************************************************************************
* Class: QTB_InvoiceGroupIdUpdateScheduler_Test
* Author: Accenture
* Purpose: This is a test class for QTB_InvoiceGroupIdUpdateBatchScheduler
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   20/5/2020
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_InvoiceGroupIdUpdateScheduler_Test {
  static testMethod void testmethod1(){
       List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
        Test.startTest();
        QTB_InvoiceGroupIdUpdateBatchScheduler obj = new QTB_InvoiceGroupIdUpdateBatchScheduler();
        String sch = '0 0 13 * * ?';
        String jobId=System.schedule('Schedule to update Invoice', sch,obj);
        Test.stopTest();
        system.assertNotEquals(jobId, null);
    }
}
}