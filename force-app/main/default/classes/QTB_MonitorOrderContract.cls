/*************************************************************************************************************************
* Class: QTB_MonitorOrderContract
* Author: TCS
* Purpose: This is a Schedular class which is used to monitor QTB_ScheduleOrderContractingBatch for Contract generation
* Requirement: Gitlab#9009
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------------------
* Renuka Prasad     30/05/2022
* Renuka Prasad     01/07/2022
**************************************************************************************************************************/
public class QTB_MonitorOrderContract implements Schedulable
{
    Integer batchSize;
    /***********************************************************************************************************
    * Method :  Constructor 
    ************************************************************************************************************/
    public QTB_MonitorOrderContract() {
        batchSize = Integer.valueOf(System.Label.QTB_contract_batch_size);
    }
    
    /***********************************************************************************************************
    * Method :  execute
    * Parameters: Database.SchedulableContext
    * ReturnType: void
    ************************************************************************************************************/
    public void execute(SchedulableContext SC) {
        //Logic to fetch QTB_ContractBatch which is scheduled to run for future date time
        list<CronTrigger> futureCronTrgs = [SELECT Id,CronJobDetail.Name,cronjobdetail.JobType,CreatedBy.name,CronExpression,EndTime,
                                            NextFireTime,PreviousFireTime,StartTime,State,TimesTriggered FROM CronTrigger WHERE
                                            CronJobDetail.Name like '%QTB_ContractBatch%' AND
                                            (cronjobdetail.JobType = '7' or cronjobdetail.JobType = '9') AND
                                            NextFireTime >=: System.Now() limit 100];
        
        System.debug('futureCronTrgs>>'+futureCronTrgs.size());
        
        if (futureCronTrgs.size() <= 0) {
            //If there is no scheduled QTB_ContractBatch job present in the system, schedule it once.
            //Since QTB_OrderContractingBatch will automatically take care of rescheduling it after 5 minutes.
            Database.executeBatch(new QTB_OrderContractingBatch(), batchSize);
        }
    }
}