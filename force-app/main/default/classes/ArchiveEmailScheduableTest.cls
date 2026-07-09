/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Test
 * @description test class for ArchiveEmailSchedulable
 */

@isTest
private class ArchiveEmailScheduableTest {
    @isTest
    static void testExecute() {
        ArchiveEmailSchedulable schedulable = new ArchiveEmailSchedulable();
        ApexJobProxyMock mockApexJobProxy = new ApexJobProxyMock();
        schedulable.apexJobProxy = mockApexJobProxy;
        
        Test.startTest();
            schedulable.execute(null);
        Test.stopTest();
        
        System.assertEquals(1, mockApexJobProxy.executeBatchCalls.size(),
            'Expecting that executing the schedulable will execute a batch');
        List<Object> arguments = mockApexJobProxy.executeBatchCalls[0];
        Object batchable = arguments[0];
        System.assert(batchable instanceof Database.Batchable<Sobject>,
            'Expecting a batchable class taking in sobjects to be executed');
        System.assert(batchable instanceof ArchiveEmailBatchable,
            'Expecting the executed batchable to be ArchiveEmailBatchable');
        ArchiveEmailBatchable castedBatchable = ( ArchiveEmailBatchable) batchable; 
        System.assertEquals(Integer.valueOf(Label.Archived_Email_Batch_Scope_Size), arguments[1],
            'A user should be able to set the batch scope size from the schedulable class');
    }
}