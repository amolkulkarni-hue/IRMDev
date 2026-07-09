/*
Auhtor       : Nagesh Ganji
Created Date : Apr 06, 2010
Description  : Wraper schedulable class for OpportunityOwnerInfoBatchUpdate. Need to schedule from web GUI at  
               specified/required time.
*/

global class OpportunityOwnerInfoScheduler implements Schedulable{
   global void execute(SchedulableContext sc) {OpportunityOwnerInfoBatchUpdate b = new OpportunityOwnerInfoBatchUpdate (); 
      database.executebatch(b);
   }
}