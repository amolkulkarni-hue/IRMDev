@isTest
private class SplitAccountNameActionTest {
    static testMethod void validateSplitString() {
        List<String> ls = new List<String>();
        String billingAccountName = 'BILLC-Slalom Test';
        ls.add(billingAccountName);
        List<String> validateList = SplitAccountNameAction.splitAccountName(ls);
        System.assertEquals('Slalom Test', validateList[0]);
    }
}