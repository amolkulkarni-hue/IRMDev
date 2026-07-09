@istest
public class Test_Sch_updateOpportunityAttribution {
    static testmethod void doTest(){ 
        test.startTest();
        Schedule_updateOpportunityAttribution sch = new Schedule_updateOpportunityAttribution();
        sch.execute(null);
        test.stopTest();
    }
}