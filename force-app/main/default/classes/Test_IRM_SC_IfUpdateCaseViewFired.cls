/************************
Developer Name: Madhu Paladugu
Case Number   : 01814315
Date          : 10/8/13
purpose       : Test Utility for IRM_SC_IfUpdateCaseViewFired class
***********************/
@isTest(seeAlldata=true)
public class Test_IRM_SC_IfUpdateCaseViewFired{

    static testMethod void doTest(){
        //cal methods for test coverage
        IRM_SC_IfUpdateCaseViewFired.hasAlreadyUpdatedCaseViewInfo();
        IRM_SC_IfUpdateCaseViewFired.setAlreadyUpdatedCaseViewInfo();
    }
}