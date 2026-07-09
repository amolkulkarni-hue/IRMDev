/*****************************************************************************************************
* Class         : QTB_RunBillNowQueueable
* Test Class    : QTB_RunBillNowQueueable_Test
* Author        : IRM/Virtusa
* Developer     : abdul  
* Purpose       : This class handle creation of invoice using bill now functionality
* Requirement   : Initial Story - Gitlab US #24706  Simultaneous Credit & Rebill
* Change History: 07/22/2024 
* Developer           Date           Description
* -----------------------------------------------------------------------------------------------------
* Abdul (Virtusa)     07/22/2024      Initial Version - Gitlab US #24588, #24706  Simultaneous Credit & Rebill
*******************************************************************************************************/
public class QTB_RunBillNowQueueable implements Queueable {
    public static  boolean throwExplicitException = false;
    public List<Id> ordId;
    public QTB_RunBillNowQueueable(List<Id> orderIds) {
        this.ordId = orderIds;
    }
    
    public void execute(QueueableContext context) {
        try{
            if( this.ordId != null &&  !this.ordId.isEmpty()){
                //Gitlab US#25326 - Defect fix - Multi month issue resolved.
                List<blng__UsageSummary__c> usgList = new List<blng__UsageSummary__c>();
                List<AggregateResult> usgSummaryAggList = [SELECT blng__Order__c,Min(blng__SummaryEndDate__c) minUSEndDate, Max(blng__SummaryEndDate__c) maxUSEndDate 
                                                       FROM blng__UsageSummary__c
                                                       WHERE blng__Order__c IN : ordId
                                                       GROUP BY blng__Order__c LIMIT 1]; 
                
                if (usgSummaryAggList != null && !usgSummaryAggList.isEmpty()) {
                    Date maxUsageSummaryEndDate = (Date)usgSummaryAggList[0].get('maxUSEndDate');
                    Date minUsageSummaryEndDate = (Date)usgSummaryAggList[0].get('minUSEndDate');
                    //if usageSummaries end date has differences, then only set the nextBillingdate
                    if(maxUsageSummaryEndDate != minUsageSummaryEndDate ){
                        List<blng__UsageSummary__c> usgSummaryList = [SELECT Id, blng__NextBillingDate__c 
                                                                      FROM blng__UsageSummary__c 
                                                                      WHERE blng__Order__c IN : ordId];
                        
                        for (blng__UsageSummary__c usgSummary : usgSummaryList) {
                            usgSummary.blng__NextBillingDate__c = maxUsageSummaryEndDate;
                            usgList.add(usgSummary);
                        }
                        if (!usgList.isEmpty()) {
                            SBQQ.TriggerControl.disable();
                            Database.SaveResult[] srList = Database.update(usgList, false, System.AccessLevel.SYSTEM_MODE);
                            SBQQ.TriggerControl.enable();
                        } 
                    }
                }
                //End
                
                List<Order> ordList = [SELECT id,blng__BillNow__c from Order where id IN :ordId];
                if (ordList !=null && !ordList.isEmpty()) { // Gitlab-24588
                    ordList[0].blng__BillNow__c = true;
                    Database.SaveResult[] srList = Database.update(ordList,false,System.AccessLevel.SYSTEM_MODE);
                } 
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'RunBillNowQueueable');           
        }
    }
    
  
}