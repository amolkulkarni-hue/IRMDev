/*****************************************************************************************************
* Class: QTB_ScheduleOperationalAccountAssociate 
* Author: Virtusa(Lokesh)
* Purpose:  This is a schedule class toupdate Operational Account Associate
 method which again tries to update the billing account, hence we got the error 'unable to lock row'
* Requirement: When flow is creating billing account and operational account getting error 'unable to lock the record'
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Lokesh         06/06/2024	               QTB_AccountHelperUtils.updateOperationalAccAssociateOnBlngAcc(accountList);
*******************************************************************************************************/
public class QTB_ScheduleOperationalAccountAssociate implements schedulable{
    public static boolean throwExplicitException = false;
    Set<id> accountList = new Set<id>();    
    //Constructor to get list of accounts
    public QTB_ScheduleOperationalAccountAssociate(Set<id> billingAccId){
        accountList =billingAccId ;
    }
    /*********************************************************************************************************
Method Name: execute
Parameters: SchedulableContext  sc
Return Type: void
Requirement: calling the method after 15 sec to bypass the 'unable to lock the record' error
Description: calling QTB_AccountHelper's -> updateOperationalAccAssociateOnBlngAcc method 
**********************************************************************************************************/
    public void execute(SchedulableContext  sc) {
      
            QTB_AccountHelperUtils.updateOperationalAccAssociateOnBlngAcc(accountList);
            
        } 
    /*********************************************************************************************************
Method Name: scheduleDelayedJob
Parameters: list<account>accList
Return Type: void
Requirement: 
Description: schedule QTB_ScheduleAccountDMSourceUpdate after 15 sec 
**********************************************************************************************************/
    public static void scheduleDelayedJob(Set<id> billingAccId) {
        // Schedule the job to run after 15 seconds
        Datetime scheduledTime = System.now().addSeconds(15);
        String cronExp = scheduledTime.format('s m H d M ? yyyy');
        System.schedule('QTB_ScheduleOperationalAccountAssociate' + scheduledTime, cronExp, new QTB_ScheduleOperationalAccountAssociate(billingAccId));
    }
}