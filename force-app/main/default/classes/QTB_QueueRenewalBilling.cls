/*****************************************************************************************************
 * Class: QTB_QueueRenewalBilling
 * Author: Accenture
 * Purpose: This is a Queuable class calling QTB_QueueRenewalBilling
 * Requirement:Git#9
 * Change History: 01/02/2021
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *
 *******************************************************************************************************/
global class QTB_QueueRenewalBilling implements Queueable {
  global static boolean throwExplicitException = false;
  global List<Contract> contractList;
    
  global QTB_QueueRenewalBilling(List<Contract> contList) {
    contractList = contList;
  }
  //Queueable Chaining context to invoke QTB_RenewalBillingBatchHelper 
  global void execute(QueueableContext qc) 
  {
    Map<Id, Contract> rsOrderContractMap = new Map<Id, Contract>();
    rsOrderContractMap.put(contractList[0].SBQQ__Order__c, contractList[0]); //Map of Sales Order Id  to Contract Record
      
    if (rsOrderContractMap != null && rsOrderContractMap.size() > 0 && !contractList.isEmpty()) 
    {  
      QTB_RenewalBillingBatchHelper.RenewalBillingClone
      (
        rsOrderContractMap, //Map of RS Order id to RS contract
        contractList        //New Contract Records
      );
    }
  }
}