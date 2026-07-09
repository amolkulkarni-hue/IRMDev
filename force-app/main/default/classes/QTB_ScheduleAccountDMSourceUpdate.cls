/*****************************************************************************************************
* Class: QTB_ScheduleAccountDMSourceUpdate 
* Author: Virtusa(Parth)
* Purpose:  This is a schedule class to update DM source System and Refrence on billing account, as during creation of billing account and operational account 
together, account relation hierarchy flow update the billing account and after that update the operation account which ship to site number, which call this 
updateDMSourceSystemIdReference method which again tries to update the billing account, hence we got the error 'unable to lock row'
* Requirement: When flow is creating billing account and operational account getting error 'unable to lock the record'
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Parth         06/06/2024	   #24127 calling QTB_AccountHelper.updateDMSourceSystemIdReference method which will run after 15 sec 
*******************************************************************************************************/
public class QTB_ScheduleAccountDMSourceUpdate implements schedulable{
    public static boolean throwExplicitException = false;
    List<Account> accountList = new List<Account>();    
    //Constructor to get list of accounts
    public QTB_ScheduleAccountDMSourceUpdate(List<Account> accList){
        accountList =accList ;
    }
    /*********************************************************************************************************
Method Name: execute
Parameters: SchedulableContext  sc
Return Type: void
Requirement: calling the method after 15 sec to bypass the 'unable to lock the record' error
Description: calling QTB_AccountHelper's -> updateDMSourceSystemIdReference method 
**********************************************************************************************************/
    public void execute(SchedulableContext  sc) {
        try {
            if (throwExplicitException) {
                throw new NullpointerException();
            }
            QTB_AccountHelper.updateDMSourceSystemIdReference(accountList);
            
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                QTB_ScheduleAccountDMSourceUpdate.class.getname()
            );
        }
    }
    /*********************************************************************************************************
Method Name: scheduleDelayedJob
Parameters: list<account>accList
Return Type: void
Requirement: 
Description: schedule QTB_ScheduleAccountDMSourceUpdate after 15 sec 
**********************************************************************************************************/
    public static void scheduleDelayedJob(list<account>accList) {
        // Schedule the job to run after 15 seconds
        Datetime scheduledTime = System.now().addSeconds(15);
        Id accId = accList[0].Id;
        String cronExp = scheduledTime.format('s m H d M ? yyyy');
        System.schedule('QTB_ScheduleAccountDMSourceUpt' + scheduledTime + accId, cronExp, new QTB_ScheduleAccountDMSourceUpdate(accList));
    }
}