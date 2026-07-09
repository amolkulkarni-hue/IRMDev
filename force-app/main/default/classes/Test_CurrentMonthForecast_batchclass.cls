/*Code written as part of Case 00443373
Author: Raj Gottipolu

Author       : Srinivasa Rao Mandalapu
Company      : CloudFountain Inc.
Modified     : Modified on 11/06. Changed SOQL filter which resembles the change in controller class.                                                                                                                                 
*/
@isTest(seeAllData=true)
private class Test_CurrentMonthForecast_batchclass {

    static testMethod void myUnitTest() {     
      //Testing the coverage for execute section.
      Test.startTest();         
      CurrentMonthForecast_Populate_batchclass job = new CurrentMonthForecast_Populate_batchclass();
      
      /*Srinu - Removed "Current_Month_Forecast_Date__c < THIS_MONTH or Current_Month_Forecast_Date__c = null" filter condition, because had made same change in controller SOQL*/
      job.query = 'Select Id, Current_Month_Forecast_Date__c, Current_Month_Forecast_Amount__c from OpportunityLineItem where Opportunity.Owner.Sales_Division__c=\'North America\'';

      Id jobId = Database.executeBatch(job);
      //Scheduler_CurrentForecast_batchclass jobSchd = new Scheduler_CurrentForecast_batchclass();        
      Test.stopTest();   
      
      AsyncApexJob jobActual = [Select Id, Status, CreatedDate,NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                                from AsyncApexJob where Id = :jobId];
      system.debug('\n##############################\n jobActual: ' + jobActual + '\n##############################\n');                                
      datetime run_time = jobActual.CreatedDate;  
      // System.assertEquals(jobActual.TotalJobItems, 1);
      //System.assertEquals(jobActual.JobItemsProcessed, 1);
      // System.assertEquals(jobActual.NumberOfErrors, 0);
      // System.assertEquals(jobActual.Status, 'Completed');         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    }
}