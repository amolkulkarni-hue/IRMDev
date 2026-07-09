/*****************************************************************************************************
* Class: QTB_QuoteStatusUpdateScheduler_Test
* Author: Accenture
* Purpose: This is a test class for QTB_QuoteStatusUpdateScheduler
* Change History: 6/1/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   5/13
*******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_QuoteStatusUpdateScheduler_Test{
    
    static testmethod void testScheduler() {
        Test.startTest();
        QTB_QuoteStatusUpdateScheduler obj = new QTB_QuoteStatusUpdateScheduler ();
        String sch = '0 0 13 * * ?';
        String jobID = System.schedule('Schedule to update quote status', sch,obj);
        Test.stopTest();
         system.assertNotEquals(jobId, null);
    }
    
}