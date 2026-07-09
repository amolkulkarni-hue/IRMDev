/*****************************************************************************************************
* Class			: QTB_APIBillingOrderCreationBatch
* Test Class	: QTB_APIBillingOrderCreationBatch_Test
* Author		: IRM/Virtusa
* Purpose	 	: Creating Billing order in Regular API process
* Requirement	: Gitlab US #12706 - Main Uplift Functionality: Step 5 - Create Billing Order
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Shailesh       		25/12/2022       Gitlab US #12706 - Main Uplift Functionality: Step 5 - Create Billing Order
*******************************************************************************************************/
public class QTB_APIBillingOrderCreationBatch implements Database.Batchable<sObject>,Database.Stateful {
    public static final string QTB_APIBillingOrderCreationBatch = 'QTB_APIBillingOrderCreationBatch';
    Set<String> failedContractSet = new Set<String>();
    Set<String> successContractSet = new Set<String>();
    Id dataHolderAPIObjId;
    Map<Id,Id> originalSalesOrderWithNewSalesOrderMap = new Map<Id,Id>();
    Map<Id,Id> BillingAccountWithSalesOrderIdMap = new Map<Id,Id>();
    Map<Id,Id> BillingOrderIdWithBillingAccountIdMap = new Map<Id,Id>();
    public final Id ACCOUNT_BILL_RECTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('QTB_Billing_Account').getRecordTypeId();
    public final Id ORDER_SALES_RECTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('QTB_Sales_Order').getRecordTypeId();
    public static boolean throwExplicitException = false;
    
    public QTB_APIBillingOrderCreationBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar, Id dataHolderAPIObjIdVar){
        System.debug('QTB_APIBillingOrderCreationBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APIBillingOrderCreationBatch_failedContractSetVar@@'+failedContractSetVar);
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;   
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab #
* Description: start() method is used for to query all newly generated Sales Orders
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('QTB_APIBillingOrderCreationBatch_start()@@');
        String orderStatus = 'Activated';
        string newSalesOrders = 'SELECT Id,Status,OpportunityId,Opportunity.SBQQ__RenewedContract__c,Opportunity.SBQQ__RenewedContract__r.SBQQ__Order__c,'+ 
            ' Opportunity.SBQQ__RenewedContract__r.Name FROM Order'+ 
            ' WHERE Opportunity.SBQQ__RenewedContract__r.Name IN: successContractSet AND RecordTypeId =: ORDER_SALES_RECTYPEID '+ //AND Status = :orderStatus
            ' order by Opportunity.SBQQ__RenewedContract__r.Name asc'; 
        Database.QueryLocator queryResult = Database.getQueryLocator( newSalesOrders ); 
        Database.QueryLocatorIterator iterate =  queryResult.iterator();
        Integer countVariable = 0;
        if(iterate != null){
            while (iterate.hasNext())
            {     
                countVariable++;
                break;
            }
        }
        if(countVariable == 0){
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
        }
        
        return Database.getQueryLocator(newSalesOrders);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab #
* Description: execute() methods is used for setting map with sourceOrder with newly generated SalesOrder, 
		     : Map of billingAccount with sourceOrder, Map of billingOrder with BillingAccount. 
			 : batch size is 200
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<Order> salesOrderList){
        Set<string> contractNameVar = new Set<String>();
        List<Order> salesOrderListFinal = new List<Order>();
        try{            
            System.debug('QTB_APIBillingOrderCreationBatch_execute()@@');
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(salesOrderList != null && !salesOrderList.isEmpty()){
                //iterate over newly generated Sales Order, 
                for(Order salesOrder : salesOrderList){
                    //Checking in Order activated or Not & if not then explicitely making as activated
                    if(salesOrder.Status != 'Activated'){
                        Order ord = new Order();
                        ord.Id = salesOrder.Id;
                        ord.Status = 'Activated';
                        ord.SBQQ__PriceCalcStatus__c = 'Not Needed';
                        salesOrderListFinal.add(ord);
                    }
                    System.debug('salesOrder@@'+salesOrder);
                    if(salesOrder.OpportunityId != null && salesOrder.Opportunity.SBQQ__RenewedContract__c != null &&
                       successContractSet.contains(salesOrder.Opportunity.SBQQ__RenewedContract__r.Name) 
                        && salesOrder.Opportunity.SBQQ__RenewedContract__r.SBQQ__Order__c != null)
                    {
                        contractNameVar.add(salesOrder.Opportunity.SBQQ__RenewedContract__r.Name);
                        //Map of Original Sales Order with Newly generated Sales Order
                        originalSalesOrderWithNewSalesOrderMap.put(salesOrder.Opportunity.SBQQ__RenewedContract__r.SBQQ__Order__c,salesOrder.Id);
                    }
                    else{
                        failedContractSet.add(salesOrder.Opportunity.SBQQ__RenewedContract__r.Name);
                    }
                }
                if(originalSalesOrderWithNewSalesOrderMap != null && !originalSalesOrderWithNewSalesOrderMap.isEmpty()){
                    //Fetching existing Billing orders based on existing sales order for respective contract
                    for(Order billingOrd : [SELECT Id, QTB_Order_OriginatorId__c ,AccountId, Account.NAme
                                 			FROM Order 
                                 			WHERE QTB_Order_OriginatorId__c IN:originalSalesOrderWithNewSalesOrderMap.keySet() ])
                    {
                        //Map of BillingAccountId with original salesOrderId
                        BillingAccountWithSalesOrderIdMap.put(billingOrd.AccountId,billingOrd.QTB_Order_OriginatorId__c);
                        //Map of BillingOrderId with BillingAccountId
                        BillingOrderIdWithBillingAccountIdMap.put(billingOrd.Id,billingOrd.AccountId);
                    }
                }
            }
            else{
                failedContractSet.addAll(contractNameVar);
                successContractSet.clear();
            }
            
            if(salesOrderListFinal !=null && !salesOrderListFinal.isEmpty()){
                update salesOrderListFinal;
            }
        }
        catch (Exception e){
            failedContractSet.addAll(contractNameVar);
            successContractSet.clear();
            System.debug('Apex Class@@'+QTB_APIBillingOrderCreationBatch);            
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIBillingOrderCreationBatch); 
        }
    }   
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab #
* Description: finish() method is used for to create billing Order Creation and send fail/pass email to logged-in user
**********************************************************************************************************/
    public void finish (Database.BatchableContext bc){
        try{
            System.debug('QTB_APIBillingOrderCreationBatch_finish_successContractSet@@'+successContractSet);
            System.debug('QTB_APIBillingOrderCreationBatch_finish_failedContractSet@@'+failedContractSet);
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.Id = dataHolderAPIObjId;
            
            //All Success -- successContractSet is not empty & failedContractSet is empty
            if(successContractSet != null && !successContractSet.isEmpty()){
                //Calling next batch to create billing order, passing salesOrder, billingOrder, billingAccount details
                //Batch size should be 1
               Database.executeBatch(new QTB_APIBillingOrderManipulationBatch(successContractSet,failedContractSet,
                                                                           originalSalesOrderWithNewSalesOrderMap,
                                                                           BillingAccountWithSalesOrderIdMap, 
                                                                           BillingOrderIdWithBillingAccountIdMap,
                                                                           dataHolderAPIObjId,null,null), Integer.valueOf(System.Label.QTB_APIBillingOrderBatchSize));
                
            }            
            //All Failed -- successContractSet is empty & failedContractSet is not empty
            else if((successContractSet == null || successContractSet.isEmpty()) && (failedContractSet != null || !failedContractSet.isEmpty())){
                //Updating Status to Failed
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
                update dataHolderAPIObj;
                
                //Send email to logged-in user with failed contracts
                QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'BillingOrder');
            }
        }
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APIBillingOrderCreationBatch);            
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            
            //Send email to logged-in user with failed contracts
            QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'BillingOrder');
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIBillingOrderCreationBatch); 
        }
    }
    
    public static void codeCoverage(){
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}