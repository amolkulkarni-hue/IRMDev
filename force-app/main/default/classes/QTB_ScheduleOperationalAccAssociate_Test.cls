@isTest
private class QTB_ScheduleOperationalAccAssociate_Test {
    @testSetup static void setup(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(2,'Billing Account');
        }
    }
    static testmethod void testmethod1(){
        test.startTest();
        list<account>accList = [Select Id from account];
        set<id> blngAcc = new Set<Id>();
        for(account acc:accList){
            blngAcc.add(acc.id);
        }
            QTB_ScheduleOperationalAccountAssociate.scheduleDelayedJob(blngAcc);
        //System.schedule('QTB_ScheduleAccountDMSourceUpdate',System.now().addSeconds(15).format('s m H d M ? yyyy'),new QTB_ScheduleAccountDMSourceUpdate(accList));
        test.stopTest();
    }
}