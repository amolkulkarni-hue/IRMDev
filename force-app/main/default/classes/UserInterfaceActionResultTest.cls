@isTest
private class UserInterfaceActionResultTest {

    @isTest
    static void testUserInterfaceActionResult(){
        Test.startTest();
        new UserInterfaceActionResult(true, 'Test').setMessage('TEST');
        new UserInterfaceActionResult(true, 'Test').setPayload(null);
        new UserInterfaceActionResult(true, 'Test').hasSucceeded();
        new UserInterfaceActionResult(true, 'Test').hasFailed();

        Test.stopTest();
        Assert.areEqual(true,new UserInterfaceActionResult(true, 'Test', 'Test').actionStatus);
    }
}