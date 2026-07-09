/*****************************************************************************************************
* Class: QTB_ScheduleUsageRating
* Author: Baumann   
* Purpose: EXAMPLE - NOT FOR PRODUCTION RELEASE, EXAMPLE ONLY.  Invocable Method to disable Trigger process, and
* schedule job 15 minutes after call
* Change History: 23/06/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              
*******************************************************************************************************/
public with sharing class QTB_ScheduleUsageRating {
    
    public QTB_ScheduleUsageRating() {}

    @InvocableMethod(label='Schedule the Usage Rating Process')
    public static void scheduleUsageRating(List<Integer> minutes){
        try {
            //make sure to turn off the billing trigger rating
            blng__BillingConfig__c billingConfig = blng__BillingConfig__c.getInstance('USAGE_RATING_PROCESS');
            billingConfig.blng__StringValue__c = 'By Process';
            update billingConfig;
            
            //build the String that will be used in CronExp.  Add 15 minutes from when it was called
            datetime nowDateTime = datetime.now();
            datetime futureDateTime = nowDateTime.addMinutes(minutes[0]);
            String cronString = '0 ' + futureDateTime.minute() + ' ' + futureDateTime.hour() + ' ' + futureDateTime.day() + ' ' + futureDateTime.month() + ' ? ' + futureDateTime.year();
            
            blng.UsageSchedulable usageSched = new blng.UsageSchedulable();
            String jobID = System.schedule('Programmatic Schedule ' + futureDateTime, cronString, usageSched);
        } catch (Exception e) {
            System.debug('Error Message: ' + e);
        }
    }
}