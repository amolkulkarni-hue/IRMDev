/*****************************************************************************************************
* Class         : QTB_APIAdvanceStorageBatch
* Test Class    : QTB_APIAdvanceStorageBatch_Test
* Author        : IRM/Virtusa
* Purpose       : Update the order product consumption schedule rate wrt subscription's new prices
* Requirement   : Gitlab US#11114 Advanced Storage - Update the rates and verify
* Developer                Date            Description
* -----------------------------------------------------------------------------------------------------
* Shailesh              12/10/2022       Gitlab US#11114 Advanced Storage - Update the rates and verify
*******************************************************************************************************/
public class QTB_APIAdvanceStorageBatch implements Database.Batchable<sObject>, Database.Stateful {
    public static final string QTB_APIAdvanceStorageBatch = 'QTB_APIAdvanceStorageBatch';
    public boolean isSuccess = false;
    List<String> contractNameList = new List<String>();
    List<String> failedContractNameList = new List<String>();
    Map<String,List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>> contractWithWrapperDataMap = new Map<String,List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>>();
    Map<String,List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>> productIdSCRateIdKeyWithSubCSRatesMap = new Map<String,List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>>();
    Map<String,List<SBQQ__OrderItemConsumptionRate__c>> productIdOPCSRateNameKeyWithOPCSRateIdMap = new Map<String,List<SBQQ__OrderItemConsumptionRate__c>>();
    Map<String,String> contractWithSalesOrderIdMap = new Map<String,String>();
    List<Id> salesOrderIdList = new List<Id>();
    List<Id> billingAccountIdList = new List<Id>();
    string documentId;
    Map<String,Id> dataHolderAPIObjMap = new Map<String,Id>();
    public static final Id ORDER_BILL_RECTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('QTB_Billing_Order').getRecordTypeId();
    
    /*********************************************************************************************************
* Method Name: QTB_APIAdvanceStorageBatch  constructor
* Parameters : List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList, String contentDocumentId
* Return Type: NA
* Requirement: Gitlab US #11114
* Description: based on wrapper data, setting the variables
**********************************************************************************************************/
    public QTB_APIAdvanceStorageBatch(List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList, String contentDocumentId){
        try{
            if(!subDataWrapList.isEmpty() && subDataWrapList.size() > 0){
                documentId = contentDocumentId;
                //iterating on subscriptionData
                System.debug('subDataWrapList.size@@'+subDataWrapList.size());
                for(QTB_APIUpliftCntrl.SubscriptionDataWrapper subData : subDataWrapList ){                 
                    //Store contract name
                    contractNameList.add(subData.contractName);
                    
                    //Map of contractName with WrapperData
                    if(contractWithWrapperDataMap.containsKey(subData.contractName)){
                        contractWithWrapperDataMap.get(subData.contractName).add(subData); 
                    }else{
                        contractWithWrapperDataMap.put(subData.contractName,new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>{subData});
                    }
                    
                    //Map of ProductIdSubscriptionCSRateId unique key with WrapperData
                    if(productIdSCRateIdKeyWithSubCSRatesMap.containsKey(subData.productId+'_'+subData.subscriptionCSRateId)){
                        productIdSCRateIdKeyWithSubCSRatesMap.get(subData.productId+'_'+subData.subscriptionCSRateId).add(subData); 
                    }else{
                        productIdSCRateIdKeyWithSubCSRatesMap.put(subData.productId+'_'+subData.subscriptionCSRateId,new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>{subData});
                    }
                }
                System.debug('productIdSCRateIdKeyWithSubCSRatesMap@@'+productIdSCRateIdKeyWithSubCSRatesMap);
                
                //From Contract get salesOrders
                for (contract contr : [SELECT Id,Name,SBQQ__Order__c FROM Contract WHERE Name IN:contractNameList])
                {
                    salesOrderIdList.add(contr.SBQQ__Order__c);
                    contractWithSalesOrderIdMap.put(contr.Id,contr.SBQQ__Order__c);
                }
                System.debug('salesOrderIdList@@'+salesOrderIdList);
                
                //fetch billingOrders based on SalesOrderIds
                List<Order> billingOrderList = [SELECT Id,QTB_Order_OriginatorId__c FROM Order WHERE QTB_Order_OriginatorId__c IN: salesOrderIdList AND RecordTypeId =:ORDER_BILL_RECTYPEID ];
                 
                System.debug('billingOrderList@@'+billingOrderList);
                
                for(SBQQ__OrderItemConsumptionRate__c opCSRate : [SELECT Id,Name, SBQQ__Price__c,SBQQ__LowerBound__c,SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__r.Product2Id,
                                                                  SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__r.Product2.ProductCode,
                                                                  SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__r.Order.QTB_Order_OriginatorId__c,
                                                                  SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__r.Order.Status
                                                                  FROM SBQQ__OrderItemConsumptionRate__c 
                                                                  WHERE SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__r.OrderId IN :billingOrderList])
                {
                    //converting productId length from 18 digit to 15 digit as in file its 15 digit productId, so to map need same length productId
                    String productId = String.valueOf((opCSRate.SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__r.Product2Id)).left(15);
                    String salesOrderId = opCSRate.SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__r.Order.QTB_Order_OriginatorId__c;
                    if(productIdOPCSRateNameKeyWithOPCSRateIdMap.containsKey(salesOrderId+'_'+productId+'_'+opCSRate.Name)){
                        productIdOPCSRateNameKeyWithOPCSRateIdMap.get(salesOrderId+'_'+productId+'_'+opCSRate.Name).add(opCSRate);
                    }else{
                        productIdOPCSRateNameKeyWithOPCSRateIdMap.put(salesOrderId+'_'+productId+'_'+opCSRate.Name, new List<SBQQ__OrderItemConsumptionRate__c>{opCSRate});
                    }
                    System.debug('productIdOPCSRateNameKeyWithOPCSRateIdMap@@'+productIdOPCSRateNameKeyWithOPCSRateIdMap);
                }
                
                for(QTB_Data_Holder__c dataholder : [SELECT Id,QTB_APIDocument_Id__c,QTB_APIStatus__c 
                                                     FROM QTB_Data_Holder__c
                                                     WHERE QTB_APIDocument_Id__c = :documentId ] )
                {
                    dataHolderAPIObjMap.put(documentId,dataholder.Id);   
                }
            }
        }
        catch (Exception e){
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIAdvanceStorageBatch); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab US #11114
* Description: Query Contract object, to fetch all contract based on contract names
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String contractQuery = 'SELECT Id,Name FROM Contract WHERE Name IN:contractNameList'; 
        
        //If query return no record, then storing not available contracts in this list failedContractNameList        
        Database.QueryLocator queryResult = Database.getQueryLocator( contractQuery ); 
        Database.QueryLocatorIterator iterate =  queryResult.iterator();
        Integer countVariable = 0;
        while (iterate.hasNext())
        {     
            countVariable++;
            break;
        }
        if(countVariable == 0){
            Set<String> contractSet = new Set<String>();
            contractSet.addAll(contractNameList); //created set to store unique value
            failedContractNameList.addAll(contractSet);
        }
        return Database.getQueryLocator(contractQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab US #11114
* Description: updating the order product consumption schedule rate wrt subscription's new rate
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<Contract> scope){
        try {
            List<SBQQ__OrderItemConsumptionRate__c> orderProductCSRateListFinal = new List<SBQQ__OrderItemConsumptionRate__c>();
            System.debug('scope@@'+scope);
            //Updating DataHolder record as InProgress
            QTB_Data_Holder__c dataHolderAPI = new QTB_Data_Holder__c();
            dataHolderAPI.QTB_APIStatus__c = 'InProgress';
            dataHolderAPI.Id = dataHolderAPIObjMap.get(documentId);
            update dataHolderAPI;
            
            if(scope != null && !scope.isEmpty()){
                //loop on contract -- Sales side
                for(Contract contr : scope){
                    System.debug('contr_for1@@'+contr);                   
                    //loop on Subscription -- Sales side
                    //loop on wrapper data -- based on contract name getting respective subscription wrapper records 
                    for(QTB_APIUpliftCntrl.SubscriptionDataWrapper wrapParent : contractWithWrapperDataMap.get(contr.Name)){ 
                        System.debug('wrapParent_for2@@'+wrapParent);
                        //loop on Subscriptions Consumption Schedule Rates -- Sales side
                        //loop on wrapper data -- based on unique key of product & subscriptionCSRateId getting respective subscription wrapper records 
                        for(QTB_APIUpliftCntrl.SubscriptionDataWrapper wrapChild : productIdSCRateIdKeyWithSubCSRatesMap.get(wrapParent.productId+'_'+wrapParent.subscriptionCSRateId)){// 2 records based on productId
                            System.debug('wrapChild_for3@@'+wrapChild);
                            //Billing side
                            System.debug('productIdOPCSRateNameKeyWithOPCSRateIdMap@@'+productIdOPCSRateNameKeyWithOPCSRateIdMap);
                            System.debug('contractWithSalesOrderIdMap.get(contr.Id)@@'+contractWithSalesOrderIdMap.get(contr.Id));
                            if(productIdOPCSRateNameKeyWithOPCSRateIdMap.containsKey(contractWithSalesOrderIdMap.get(contr.Id)+'_'+wrapChild.productId.left(15)+'_'+wrapChild.subscriptionCSRateName)){
                                System.debug('opCSRate_size()_for4@@'+productIdOPCSRateNameKeyWithOPCSRateIdMap.get(contractWithSalesOrderIdMap.get(contr.Id)+'_'+wrapChild.productId.left(15)+'_'+wrapChild.subscriptionCSRateName).size());
                                //loop on Order Product CS Rates - Billing side
                                //loop on Order Product CS Rate -- based on unique key of product & subscriptionCSRateName getting respective order products cs rate records
                                for(SBQQ__OrderItemConsumptionRate__c opCSRate : productIdOPCSRateNameKeyWithOPCSRateIdMap.get(contractWithSalesOrderIdMap.get(contr.Id)+'_'+wrapChild.productId.left(15)+'_'+wrapChild.subscriptionCSRateName)){// 2 csrate recordds based on productId
                                    System.debug('opCSRate_for4@@'+opCSRate);
                                    SBQQ__OrderItemConsumptionRate__c opcsRateObj = new SBQQ__OrderItemConsumptionRate__c();
                                    opcsRateObj.Id = opCSRate.Id;
                                    if(wrapChild.subscriptionCSRateName == opCSRate.Name && !orderProductCSRateListFinal.contains(opcsRateObj)){
                                        opcsRateObj.SBQQ__Price__c = wrapChild.newPrice;  
                                        System.debug('opcsRateObj_if@@'+opcsRateObj);
                                        orderProductCSRateListFinal.add(opcsRateObj);
                                        //break; //break not needed as multiple billing account can have same orderproduct cs rate name
                                    }                 
                                }  
                            }
                        }
                    }
                }  
            }
            else{
                failedContractNameList.add(scope[0].Name);
            }
            if(orderProductCSRateListFinal != null && !orderProductCSRateListFinal.isEmpty()){
                System.debug('orderProductCSRateListFinal.size()@@'+orderProductCSRateListFinal.size());
                System.debug('orderProductCSRateListFinal@@'+orderProductCSRateListFinal);
                update orderProductCSRateListFinal; 
            }
            else{
                 failedContractNameList.add(scope[0].Name);
            }
        }
        catch (Exception e){
            failedContractNameList.add(scope[0].Name);
            //Updating DataHolder record as Failed
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
            dataHolderAPIObj.Id = dataHolderAPIObjMap.get(documentId);
            update dataHolderAPIObj;
            
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIAdvanceStorageBatch); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab US #11114, #11115
* Description: If order product cs rate updation success, then updating same to DataHolder object,
If any exception, then sending mail to the user with failed contract details.
**********************************************************************************************************/
    public void finish (Database.BatchableContext bc){
        try{
            List<QTB_Data_Holder__c> dataHolderList = new List<QTB_Data_Holder__c>();
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.Id = dataHolderAPIObjMap.get(documentId);
            
            if(failedContractNameList == null || failedContractNameList.isEmpty() ){
                //Updating DataHolder record as Success
                dataHolderAPIObj.QTB_APIStatus__c = 'Success';
                dataHolderList.add(dataHolderAPIObj);
            }else{
                //Updating DataHolder record as Failed
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                dataHolderList.add(dataHolderAPIObj);
                
                //Gitlab US #11115 Advanced Storage - Exception Email
                //Email Notification for failed contracts
                System.debug('failedContractNameList@@'+failedContractNameList);
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.toAddresses = new String[] {UserInfo.getUserEmail()};
                message.subject = 'Advance API process failed';
                message.plainTextBody = 'Dear '+UserInfo.getFirstName() +',\n\n' + 'While doing Advance API process, billing order product consumption schedule rate updation failed.\n' +'Following are the failed contracts : '+failedContractNameList +'\n\nPlease reach to Administrator for more details.' +'\n\nThank You';
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
            }
            if(dataHolderList !=null && !dataHolderList.isEmpty()){
                update dataHolderList;
            }
        }
        catch (Exception e){
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIAdvanceStorageBatch); 
        }
    }
}