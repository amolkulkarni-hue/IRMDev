@istest
public class Test_Sch_updateOppAttrReconciliation {
    static testmethod void doTest(){ 
        test.startTest();
        Schedule_updateOppAttrReconciliation sch = new Schedule_updateOppAttrReconciliation();
        sch.execute(null);
        test.stopTest();
    }
}