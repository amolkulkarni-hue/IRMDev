/********************************************************************************************************
@Description: This Apex Class is created to handle multiple returns for NAS_DataFactory.createRecurringCases method
@Copyright: Iron Mountain
@Author:  Simranjit Kaur
@Created on:  11/19/2025(MM/DD/YYYY)
@MainClass Name: RecurringCaseResultWrapper
*
Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
===================================================
*
********************************************************************************************************/
@IsTest
private class RecurringCaseResultWrapperTest {

    @IsTest
    static void testWrapperInitialization() {
        // Create instance
        RecurringCaseResultWrapper wrapper = new RecurringCaseResultWrapper();

        // Verify the sets are initialized and empty
        System.assertNotEquals(null, wrapper.failedInsertParentIds, 'failedInsertParentIds should not be null');
        System.assertNotEquals(null, wrapper.failedUpdateCaseIds, 'failedUpdateCaseIds should not be null');
        System.assertEquals(0, wrapper.failedInsertParentIds.size(), 'failedInsertParentIds should be empty');
        System.assertEquals(0, wrapper.failedUpdateCaseIds.size(), 'failedUpdateCaseIds should be empty');
    }

    @IsTest
    static void testAddIdsToWrapper() {
        RecurringCaseResultWrapper wrapper = new RecurringCaseResultWrapper();

        // Add some dummy Ids
        Id parentId1 = Id.valueOf('500000000000001AAA'); // Fake 18-char ID
        Id parentId2 = Id.valueOf('500000000000002AAA');

        Id updateId1 = Id.valueOf('500000000000003AAA');

        wrapper.failedInsertParentIds.add(parentId1);
        wrapper.failedInsertParentIds.add(parentId2);
        wrapper.failedUpdateCaseIds.add(updateId1);

        // Assertions
        System.assertEquals(2, wrapper.failedInsertParentIds.size(), 'There should be 2 failed insert parent IDs');
        System.assert(wrapper.failedInsertParentIds.contains(parentId1), 'Set should contain parentId1');
        System.assert(wrapper.failedInsertParentIds.contains(parentId2), 'Set should contain parentId2');

        System.assertEquals(1, wrapper.failedUpdateCaseIds.size(), 'There should be 1 failed update case ID');
        System.assert(wrapper.failedUpdateCaseIds.contains(updateId1), 'Set should contain updateId1');
    }
}