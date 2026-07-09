/*****************************************************************************************************
* Class: QTB_RenewalUpliftScheduler_Test
* Author: Accenture
* Purpose: This is a test class for QTB_RenewalUpliftScheduler
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   6/17/2020
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_RenewalUpliftScheduler_Test {
    static testmethod void test2() {
        Test.startTest();
        set<ID> contrIDset = new set<ID>();
        QTB_RenewalUpliftScheduler obj = new QTB_RenewalUpliftScheduler(contrIDset);
        String sch = '0 0 13 * * ?';
        String jobId=System.schedule('Schedule Batch', sch,obj);
        Test.stopTest();
        system.assertNotEquals(jobId, null);
    }
}