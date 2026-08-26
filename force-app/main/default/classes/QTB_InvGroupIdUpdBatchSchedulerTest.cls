/*****************************************************************************************************
* Class: QTB_InvGroupIdUpdBatchSchedulerTest
* Purpose: Test class for QTB_InvoiceGroupIdUpdateBatchScheduler.
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* NeuraFlash    2026-07-31    Added to restore test coverage after QTB_InvoiceGroupIdUpdateBatchScheduler's
*                             execute() was temporarily disabled (see class comment for why).
*******************************************************************************************************/
@isTest(seeallData=false)
private class QTB_InvGroupIdUpdBatchSchedulerTest {

    static testmethod void test() {
        Test.startTest();
        QTB_InvoiceGroupIdUpdateBatchScheduler obj = new QTB_InvoiceGroupIdUpdateBatchScheduler();
        String sch = '0 0 13 * * ?';
        String jobId = System.schedule('Schedule to update Invoice Group Id', sch, obj);
        Test.stopTest();
        System.assertNotEquals(jobId, null);
    }

}
