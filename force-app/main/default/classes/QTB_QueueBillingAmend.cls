/*****************************************************************************************************
 * Class: QTB_QueueBillingAmend
 * Author: Accenture
 * Purpose: This is a Queuable class calling QTB_QueueBillingAmend
 * Requirement:Git#15
 * Change History: 16/03/2021
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *
 *******************************************************************************************************/
global class QTB_QueueBillingAmend implements Queueable {
    global static boolean throwExplicitException = false;
    global List<Contract> contractList;
    global Map<Id,Contract> oldContractMap;
    global QTB_QueueBillingAmend(List<Contract> contList,Map<Id,Contract> contractMap) {
      contractList = contList;
      oldContractMap = contractMap;
    }
    global void execute(QueueableContext qc) {
        
      Map<Id, Contract> MapOfNewOrderToContract = new Map<Id, Contract>();
      Map<Id,Id> mapOfOldOrderToNewOrder=new Map<Id,Id>();

      MapOfNewOrderToContract.put(contractList[0].SBQQ__Order__c, contractList[0]); 
      mapOfOldOrderToNewOrder.put(oldContractMap.get(contractList[0].id).SBQQ__Order__c,contractList[0].SBQQ__Order__c);
        
      if (mapOfOldOrderToNewOrder.size() >0 && MapOfNewOrderToContract.size() > 0) {
        QTB_AmendBillingHelper.AmendBillingClone(
            MapOfNewOrderToContract,	//Map of new AS order to Contract
            mapOfOldOrderToNewOrder,	//Map of old Sorder to New AS Order
            contractList,				//New Contract Records
            oldContractMap				//Old Contract Records
        );
      }
    }
  }