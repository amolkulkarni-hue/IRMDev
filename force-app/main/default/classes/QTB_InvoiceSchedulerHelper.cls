/*****************************************************************************************************
* Class       : QTB_InvoiceSchedulerHelper
* Test Class  : QTB_InvoiceSchedulerHelper_Test
* Author      : IRM/Virtusa
* Purpose     : This is a helper class for all business logic related to Invoice Scheduler object
* Requirement: 
* Change History: 19/09/2025 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Parth  		19/09/2025     #32670 - updating invoice run completed to false 
*******************************************************************************************************/
public class QTB_InvoiceSchedulerHelper {
    private static final String CLASSNAME = QTB_InvoiceSchedulerHelper.class.getName();
/***********************************************************************************************************
* Method : trigController
* Parameters: List<blng__InvoiceScheduler__c>, Map<Id,blng__InvoiceScheduler__c>,System.TriggerOperation
* Requirement : 
* Start Date : 
* Author : IRM
* Description: Generic method to handle all operations on the Invoice Scheduler Records
**************************************************************************************************************/
    public static void process(List<blng__InvoiceScheduler__c> InvSchedulerNewList,Map<Id,blng__InvoiceScheduler__c>invSchedulerOldMap,System.TriggerOperation operationType)
    { 
        for(blng__InvoiceScheduler__c invSch : InvSchedulerNewList){
            SWITCH ON operationType {
                WHEN BEFORE_UPDATE {
                    // #32670 - updating invoice run completed to false
                    if(invSchedulerOldMap.get(invSch.Id).blng__StartDateTime__c != invSch.blng__StartDateTime__c){
                        invSch.QTB_InvoiceRunCompleted__c = false;
                    }
                }
            }
        }
    }
}