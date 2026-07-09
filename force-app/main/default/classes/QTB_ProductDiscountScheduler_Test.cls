/*****************************************************************************************************
* Class: QTB_ProductDiscountScheduler_Test
* Author: Accenture
* Purpose: Test Class for QTB_ProductDiscountScheduler
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_ProductDiscountScheduler_Test{
  /*********************************************************************************************************
    Method Name: testQTB_ProductDiscountScheduler
    Parameters:
    Return Type: Void
    Description: Test class for QTB_ProductDiscountScheduler class
    **********************************************************************************************************/
    static testmethod void testQTB_ProductDiscountScheduler() {
        Test.startTest();
        QTB_ProductDiscountScheduler obj = new QTB_ProductDiscountScheduler();
        String sch = '0 0 13 * * ?';
        String jobId=System.schedule('Schedule Product discount', sch,obj);
        Test.stopTest();
        system.assertNotEquals(jobId, null);
    }
}