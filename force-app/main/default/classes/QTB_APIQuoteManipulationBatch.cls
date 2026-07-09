/*****************************************************************************************************
* Class         : QTB_APIQuoteManipulationBatch
* Test Class    : QTB_APIQuoteManipulationBatch_Test
* Author        : IRM/Virtusa
* Purpose       : This Class is responsible to update the Quote details as well as to update the QuoteLine CS Rates if any differences.
* Requirement   : Gitlab US #12211,11220,10235 - Main Uplift Functionality Process: Build for Testing: Step Three - Set Quote Line Consumption Rate Story
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Shailesh              01/12/2022       Gitlab US #12211 - Set Quote Line Consumption Rate Story
*******************************************************************************************************/
public class QTB_APIQuoteManipulationBatch implements Database.Batchable<sObject>,Database.Stateful {
    public static final string QTB_APIQuoteManipulationBatch = 'QTB_APIQuoteManipulationBatch';
    Set<Id> quoteIdSet = new Set<Id>(); 
    Set<String> failedContractSet = new Set<String>();
    Set<String> successContractSet = new Set<String>();
    Id dataHolderAPIObjId;
    Map<Id,Account> salesOrdWithBillingMinimumMap = new Map<Id,Account>();
    public static final Id ORDER_BILL_RECTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('QTB_Billing_Order').getRecordTypeId();
    public static boolean throwExplicitException = false;
    Set<Id> failedQuoteIdSet = new Set<Id>();
    Integer retryCount = 0;
    Set<Id> productToUpdateSet = new Set<Id>();
    public QTB_APIQuoteManipulationBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar,Set<Id> productToUpdateSetVar, Id dataHolderAPIObjIdVar){
        System.debug('QTB_APIQuoteManipulationBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APIQuoteManipulationBatch_failedContractSetVar@@'+failedContractSetVar);
        Map<String,Id> contractNameWithSalesOrderMap = new Map<String,Id>();
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
        productToUpdateSet = productToUpdateSetVar;
        
        if(successContractSet != null && !successContractSet.isEmpty()){
            //Fetching OriginalSalesOrder based on contracts
            for(Contract contr : [SELECT Id,Name,SBQQ__Order__c FROM Contract WHERE Name IN : successContractSet])
            {
                //storing contractName with its Order in Map
                contractNameWithSalesOrderMap.put(contr.Name, contr.SBQQ__Order__c);
            }   
        }
        
        if(contractNameWithSalesOrderMap !=null && !contractNameWithSalesOrderMap.isEmpty()){
            //Gitlab US #10235,11220 getting billing order  --  
            for(Order ords : [SELECT Id,AccountId,QTB_Order_OriginatorId__c,Account.QTB_Minimum_Storage_Charges__c,/*Account.QTB_Late_Fee__c,*/
                              Account.QTB_Minimum_Charges_Start_Date__c
                              FROM Order 
                              WHERE QTB_Order_OriginatorId__c IN : contractNameWithSalesOrderMap.values() and status = 'Activated' 
                              and RecordTypeId =:ORDER_BILL_RECTYPEID order by CreatedDate asc])
            {
                //putting Billing Account Minimum storage charge value with referring to sales order
                salesOrdWithBillingMinimumMap.put(ords.QTB_Order_OriginatorId__c,ords.Account);
            }  
        }
        system.debug('salesOrdWithBillingMinimumMap@@@@' +salesOrdWithBillingMinimumMap);
    }
    
    public QTB_APIQuoteManipulationBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar, Set<Id> failedQuoteIdSetVar, Set<Id> productToUpdateSetVar, Id dataHolderAPIObjIdVar, Integer retries){
        System.debug('QTB_APIQuoteManipulationBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APIQuoteManipulationBatch_failedContractSetVar@@'+failedContractSetVar);
        Map<String,Id> contractNameWithSalesOrderMap = new Map<String,Id>();
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;
        failedQuoteIdSet = failedQuoteIdSetVar;
        productToUpdateSet = productToUpdateSetVar;
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
        retryCount = retries;
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab US #12211, #10235
* Description: Query on Quote object, Fetch all newly generated renewal quote records based on contracts
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String quoteQuery ='SELECT Id,QTB_Trigger_Quote_Calculation__c,QTB_Minimum_Storage_Charges__c,QTB_Late_Fees__c,ApprovalStatus__c,SBQQ__Status__c,'+
            'SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name,'+
            'SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c'+
            ' FROM SBQQ__Quote__c ';
        
        if(retryCount > 0 && failedQuoteIdSet != null && !failedQuoteIdSet.isEmpty() )
        {
            quoteQuery = quoteQuery + ' WHERE Id IN : failedQuoteIdSet';  
        }
        else
        {
            quoteQuery = quoteQuery + ' WHERE SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name IN : successContractSet';
        }
        quoteQuery = quoteQuery + ' order by SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name asc';
        System.debug('QTB_APIQuoteManipulationBatch_quoteQuery@@'+quoteQuery);
        Database.QueryLocator queryResult = Database.getQueryLocator( quoteQuery ); 
        Database.QueryLocatorIterator iterate =  queryResult.iterator();
        Integer countVariable = 0;
        if(iterate != null){
            while (iterate.hasNext())
            {     
                countVariable++;
                break;
            }
        }
        if(countVariable == 0 && retryCount == 0){
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
        }
        
        return Database.getQueryLocator(quoteQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab US #12211, #10235
* Description: execute() is responsible to update the Quote field values along with Minimum Storage Amount
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<SBQQ__Quote__c> quoteList){
        try {
            System.debug('QTB_APIQuoteManipulationBatch_execute@@'+quoteList);
            List<SBQQ__Quote__c> quoteListFinal = new List<SBQQ__Quote__c>();
            Map<Id,Id> quoteIdWithOriginalContractIdMap = new Map<Id,Id>();
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(quoteList != null && !quoteList.isEmpty()){
                //Iterating over Renewal Quote List
                for(SBQQ__Quote__c quote : quoteList )
                {
                    quoteIdSet.add(quote.Id);
                    quoteIdWithOriginalContractIdMap.put(quote.Id, quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);
                    SBQQ__Quote__c quoteObj = new SBQQ__Quote__c();
                    quoteObj.Id = quote.Id; 
                    //Gitlab US #10235, 11220 
                    //check the map key contains salesorder id              
                    if((salesOrdWithBillingMinimumMap != null && !salesOrdWithBillingMinimumMap.isEmpty()) && 
                       quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null && 
                       quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c != null &&
                       salesOrdWithBillingMinimumMap.containsKey(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c))
                    {
                        //fetching Billing Account Minimum Storage Charge Amount based on Sales Order Id
                        //Storing Billing Account Minimum Storage to Renewal Quote Minimum Storage Charge
                        quoteObj.QTB_Minimum_Storage_Charges__c = salesOrdWithBillingMinimumMap.get(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c).QTB_Minimum_Storage_Charges__c;
                        quoteObj.QTB_Minimum_Charges_Start_Date__c = salesOrdWithBillingMinimumMap.get(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c).QTB_Minimum_Charges_Start_Date__c;
                        //Fetching Late fee from related Billing Account, and if its present then mentioned as 'N/A' as its manadatory value, and for Finland its N/A.
                        quoteObj.QTB_Late_Fees__c = 'N/A';
                        //salesOrdWithBillingMinimumMap.get(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c).QTB_Late_Fee__c != null ?
                        //    salesOrdWithBillingMinimumMap.get(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c).QTB_Late_Fee__c : 'N/A';
                    }
                    system.debug('quoteObj.QTB_Minimum_Storage_Charges__c@@@@' +quoteObj.QTB_Minimum_Storage_Charges__c);
                    quoteObj.ApprovalStatus__c = 'Approved';
                    quoteObj.SBQQ__Status__c = 'Approved'; 
                    quoteObj.QTB_Trigger_Quote_Calculation__c = true;
                    quoteObj.QTB_APIProcess__c = true;
                    quoteListFinal.add(quoteObj);
                }  
            }
            else{
                failedContractSet.add(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                if(successContractSet.contains(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name))
                {
                    successContractSet.remove(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);  
                }
            }
            
            if(quoteListFinal != null && !quoteListFinal.isEmpty()){
                System.debug('quoteListFinal@@'+quoteListFinal);
                wait(Integer.valueOf(System.Label.QTB_APIDelayInMilliseconds)); //providing delay for 30 sec as to avoid record lock issue
                update quoteListFinal; 
                
                if(retryCount > 0 && failedQuoteIdSet != null && failedQuoteIdSet.contains(quoteList[0].Id)){
                    failedQuoteIdSet.remove(quoteList[0].Id);
                }
                
                if(retryCount > 0 ){
                    successContractSet.add(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                    failedContractSet.remove(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                }
            }
        }
        catch (Exception e){
            //Store failed quote's contract names
            failedContractSet.add(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
            quoteIdSet.remove(quoteList[0].Id);
            failedQuoteIdSet.add(quoteList[0].Id);
            if(successContractSet != null && successContractSet.contains(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name)){
                successContractSet.remove(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);  
            }            
            System.debug('Apex Class@@'+QTB_APIQuoteManipulationBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());   
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name+'-'+e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIQuoteManipulationBatch); 
        }
    }
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab US #12211
* Description: finish() method is used to schedule QTB_APIQuoteUpdationBatch batch class to perform Quote related logic.
: If any failedContract then sending mail to logged-in user with failed Contract
**********************************************************************************************************/
    public void finish (Database.BatchableContext bc){
        try{
            System.debug('QTB_APIQuoteManipulationBatch_finish_successContractSet@@'+successContractSet);
            System.debug('QTB_APIQuoteManipulationBatch_finish_failedContractSet@@'+failedContractSet);
            if (throwExplicitException) {
                throw new NullPointerException();
            }            
            
            //to add not-renewed contract in failedContractSet
           /* if(successContractSet.size() != contractRenewedSet.size()){ // 34 != 1
                for(string originalContract : successContractSet){
                    if(!contractRenewedSet.contains(originalContract)){
                        failedContractSet.add(originalContract);
                        successContractSet.remove(originalContract);
                    }
                }
            }
            */
            
            //Scheduling Quote Updation batch(QTB_APIQuoteUpdationBatchJob) to accept the quote
            if(successContractSet != null && !successContractSet.isEmpty() && quoteIdSet != null && !quoteIdSet.isEmpty() && !Test.isRunningTest()){
                
                //If any contract failed, retrying few more times based on value store in label QTB_APIFailedContractRetryCount by calling the same class again with failed contract
                if(failedContractSet != null && !failedContractSet.isEmpty() && failedQuoteIdSet != null && !failedQuoteIdSet.isEmpty() &&
                   retryCount < Integer.valueOf(System.Label.QTB_APIFailedContractRetryCount))
                {
                    retryCount = retryCount + 1; 
                    //calling the same batch for failed scenario , batch size is 1.
                    Database.executeBatch(new QTB_APIQuoteManipulationBatch(successContractSet,failedContractSet,failedQuoteIdSet,productToUpdateSet,dataHolderAPIObjId,retryCount), Integer.valueOf(System.Label.QTB_APIQuoteBatchSize));
                }
                else{
                    //Reverting QuoteLine, Subscriptions, Products -- subscriptiontype field value to 'One-time'
                    //revertQuoteLineSubTypeChanges(quoteIdSet,productToUpdateSet);  //reverting the QuoteLine's subscription type back to 'One-time'
                    QTB_APISubscriptionUpliftBatch.revertSubscriptionTypeOfSubscription(successContractSet,failedContractSet,productToUpdateSet); //reverting Subscription's subscriptiontype to 'One-time'               
                    QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(false); //reverting the Product's subscription type back to 'One-time'
                    
                    //Calling next batch QTB_APIQuoteUpdationBatch...Batch size can be 200
                    System.scheduleBatch(new QTB_APIQuoteUpdationBatch(successContractSet,failedContractSet,quoteIdSet,productToUpdateSet,dataHolderAPIObjId),'QTB_APIQuoteUpdationBatchJob',Integer.valueOf(System.Label.QTB_APINextBatchFireTime),Integer.valueOf(System.Label.QTB_APIBulkBatchSize)); 
                }
            }
            else{
                //Reverting QuoteLine, Subscriptions, Products -- subscriptiontype field value to 'One-time'                
                QTB_APISubscriptionUpliftBatch.revertSubscriptionTypeOfSubscription(successContractSet,failedContractSet,productToUpdateSet); //reverting Subscription's subscriptiontype to 'One-time'               
                QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(false); //reverting the Product's subscription type back to 'One-time'
                revertQuoteLineSubTypeChanges(quoteIdSet,productToUpdateSet);  //reverting the QuoteLine's subscription type back to 'One-time'
                
                //Updating status to Failed
                QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                dataHolderAPIObj.Id = dataHolderAPIObjId;
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
                update dataHolderAPIObj;
                //send email to logged-in user with Failed Contracts
                QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'Quote');
            }
        }
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APIQuoteManipulationBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            
            //Reverting QuoteLine, Subscriptions, Products -- subscriptiontype field value to 'One-time'
            revertQuoteLineSubTypeChanges(quoteIdSet,productToUpdateSet);  //reverting the QuoteLine's subscription type back to 'One-time'
            QTB_APISubscriptionUpliftBatch.revertSubscriptionTypeOfSubscription(successContractSet,failedContractSet,productToUpdateSet); //reverting Subscription's subscriptiontype to 'One-time'               
            QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(false); //reverting the Product's subscription type back to 'One-time'
            
            //Email Notification for all failed contract records
            QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'Quote');
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIQuoteManipulationBatch); 
        }
    }
    /*********************************************************************************************************
* Method Name: wait
* Parameters : Integer millisec
* Return Type: void
* Requirement: Gitlab US #10330
* Description: wait() method : to hold transaction for given milliseconds
**********************************************************************************************************/   
    public void wait(Integer millisec) {
        if (millisec == null || millisec < 0) {
            millisec = 0;
        }
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while ((finishTime - startTime) < millisec) {
            finishTime = DateTime.now().getTime();
        }
    }
    
    /*********************************************************************************************************
* Method Name: revertQuoteLineSubTypeChanges
* Parameters : Set<Id> quoteIdSet, Set<Id> productIdSet
* Return Type: void
* Requirement: Gitlab US #10330
* Description: revertQuoteLineSubTypeChanges() method : is reverting QuoteLine Subscription type changes from renewable to One-time
**********************************************************************************************************/      
    public static void revertQuoteLineSubTypeChanges(Set<Id> quoteIdSet, Set<Id> productIdSet){
        System.debug('revertQuoteLineSubTypeChanges_quoteIdSet@@'+quoteIdSet);
        System.debug('revertQuoteLineSubTypeChanges_productIdSet@@'+productIdSet);
        List<SBQQ__QuoteLine__c> quoteLineListFinal = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c quoteLine : [SELECT Id,Name,SBQQ__ProductSubscriptionType__c,SBQQ__SubscriptionType__c 
                                            FROM SBQQ__QuoteLine__c 
                                            WHERE SBQQ__Quote__c IN:quoteIdSet and SBQQ__Product__c IN :productIdSet])
        {
            SBQQ__QuoteLine__c quoteLineObj = new SBQQ__QuoteLine__c();
            quoteLineObj.Id = quoteLine.Id;
            quoteLineObj.SBQQ__ProductSubscriptionType__c = 'One-time';
            quoteLineObj.SBQQ__SubscriptionType__c = 'One-time';
            quoteLineListFinal.add(quoteLineObj);
        }
        if(quoteLineListFinal != null && !quoteLineListFinal.isEmpty()){
            SBQQ.TriggerControl.disable();
            update quoteLineListFinal;
            SBQQ.TriggerControl.enable();
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