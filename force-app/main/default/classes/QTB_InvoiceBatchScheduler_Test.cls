/*****************************************************************************************************
* Class: QTB_InvoiceBatchScheduler_Test
* Author: Accenture
* Purpose: This is a test class for QTB_InvoiceBatchScheduler
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture    6/1/2020
*******************************************************************************************************/
@isTest(seeallData=false)
private with sharing class QTB_InvoiceBatchScheduler_Test {
    
    static testmethod void test2() {
        Test.startTest();
        QTB_InvoiceBatchScheduler obj = new QTB_InvoiceBatchScheduler();
        String sch = '0 0 13 * * ?';
        String jobID = System.schedule('Schedule to update Invoice', sch,obj);
        Test.stopTest();
        system.assertNotEquals(jobId, null);
    }
    
}