@IsTest
private without sharing class NF_SetBooleanTest {
	@IsTest
    static void testSuccess() {
        Test.startTest();
        List<NF_SetBoolean.Output> output = NF_SetBoolean.setBoolean();
        Test.stopTest();
        System.Assert.isTrue(output[0].trueValue);
        System.Assert.isFalse(output[0].falseValue);
    }
}