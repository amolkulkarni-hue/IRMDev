/*
Author       : Vinutha Iyengar
Modified Date: 15-Mar-2019
Case 		 : 09542928
Description  : Test method cannot reside inside non-test classes, so moved test method from BatchJobsManager to BatchJobsManagerTest
*/

@isTest
public class BatchJobsManagerTest {
	
    static testMethod void BatchJobsManagerTest()
    {            
        BatchJobsManager controller = new BatchJobsManager();
        controller.runningTest = false;
        controller.startSynchFieldValuesJob();
        controller.startOppsharedeletebatchclassJob();
        controller.startForecastDateAmountbatchclassJob();
        controller.sampleMethod();
    }
   
    @isTest(SeeAllData=true)
    static void BatchJobsManagerTest1()
    {
        BatchJobsManager controller = new BatchJobsManager();
        controller.runningTest = true;
        controller.startSynchFieldValuesJob();
        controller.startOppsharedeletebatchclassJob();
        controller.startOppshareinsertbatchclassJob();
        controller.startForecastDateAmountbatchclassJob();
    }
    
}