/*****************************************************************************************************
* Class: QTB_RenewContractScheduler_Test
* Author: Accenture
* Purpose: This is a test class for QTB_RenewContractScheduler
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture  
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_RenewContractScheduler_Test {
    
    static testmethod void test2() {
        Test.startTest();
        QTB_RenewContractScheduler obj = new QTB_RenewContractScheduler();
        String sch = '0 0 13 * * ?';
        String jobid=System.schedule('Schedule to renew contract', sch,obj);
        Test.stopTest();
        system.assertNotEquals(jobId, null);
    }
    
    static testmethod void coverCatch() {
        Test.startTest();
        QTB_RenewContractScheduler.throwExplicitException = true;
        QTB_RenewContractScheduler obj = new QTB_RenewContractScheduler();
        String sch = '0 0 13 * * ?';
        String jobid=System.schedule('Schedule to renew contract', sch,obj);
        Test.stopTest();
        system.assertNotEquals(jobId, null);
    }
    
}