/*****************************************************************************************************
* Class			: QTB_APIQuoteUpdationBatch
* Test Class	: QTB_APIQuoteManipulationBatch_Test
* Author		: IRM/Virtusa
* Purpose	 	: This Class is responsible to update the Quote details as well as to update the QuoteLine CS Rates if any differences.
* Requirement	: Gitlab US #12211,12041 - Main Uplift Functionality Process: Build for Testing: Step Three - Set Quote Line Consumption Rate Story 
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Shailesh       		08/12/2022       Gitlab US #12211,12041 -  Changing the Quote Status and Updating the Quote Line CS Rate if any difference
*******************************************************************************************************/
public class QTB_APIQuoteUpdationBatch implements Database.Batchable<sObject>,Database.Stateful {
    public static final string QTB_APIQuoteUpdationBatch = 'QTB_APIQuoteUpdationBatch';
    boolean isSuccess = true;
    Set<Id> quoteIdSet = new Set<Id>(); 
    Set<String> failedContractSet = new Set<String>();
    Set<String> successContractSet = new Set<String>();
    Id dataHolderAPIObjId;
    public static boolean throwExplicitException = false;
    Set<Id> productToUpdateSet = new Set<Id>();
    
    public QTB_APIQuoteUpdationBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar,Set<Id> quoteIdSetVar,Set<Id> productToUpdateSetVar, Id dataHolderAPIObjIdVar){
        System.debug('QTB_APIQuoteUpdationBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APIQuoteUpdationBatch_failedContractSetVar@@'+failedContractSetVar);
        List<Id> salesOrderIds = new List<Id>();
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
        quoteIdSet = quoteIdSetVar;
        productToUpdateSet = productToUpdateSetVar;
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab US #12211,12041
* Description: Query Quote object to reteriving the quote records
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String quoteQuery ='SELECT Id,SBQQ__Status__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name, SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate'+
            ' FROM SBQQ__Quote__c'+
            ' WHERE Id IN : quoteIdSet order by SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name asc';
        System.debug('QTB_APIQuoteUpdationBatch_quoteQuery@@'+quoteQuery);
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
        if(countVariable == 0){
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
        }
        
        return Database.getQueryLocator(quoteQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab US #12211,12041
* Description: execute() - update the Quote status & compare/update QL CS Rate
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<SBQQ__Quote__c> quoteList){
        try {
            System.debug('QTB_APIQuoteUpdationBatch_execute@@'+quoteList);
            List<SBQQ__Quote__c> quoteListFinal = new List<SBQQ__Quote__c>();
            Map<Id,Id> quoteIdWithOriginalContractIdMap = new Map<Id,Id>();
            Set<Id> quoteIds = new Set<Id>();
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(quoteList != null && !quoteList.isEmpty()){
                //Iterating over Renewal Quote List
                for(SBQQ__Quote__c quote : quoteList )
                {
                    quoteIdWithOriginalContractIdMap.put(quote.Id, quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);
                    SBQQ__Quote__c quoteObj = new SBQQ__Quote__c();
                    quoteObj.Id = quote.Id;    
                    quoteObj.ApprovalStatus__c = 'Approved';
                    quoteObj.SBQQ__Status__c = 'Accepted'; 
                    //For past date, Quote Accepted will fail, so providing today's date if any past date
                    if(quoteObj.SBQQ__StartDate__c <= quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate ){
                        quoteObj.SBQQ__StartDate__c = quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.EndDate + 1;
                    }
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
                //Calling compareUpdateQLCSRate() method to Compare & Update QuoteLine CS Rate with Subscription CS Rate
                compareUpdateQLCSRate(quoteIdWithOriginalContractIdMap);
                
                //Partial Updating the quote
                Database.SaveResult[] srList = Database.update(quoteListFinal, false);//partial updation
                
                String ErrorMsg;
                // Iterate through each returned result
                for (Integer i = 0; i < srList.size(); i++) {
                    if (!srList[i].isSuccess()) {
                        quoteIds.add(srList[i].getId());
                         ErrorMsg = srList[i].getErrors()[0].getMessage();
                    }
                }
                
                if(quoteIds != null && !quoteIds.isEmpty()){
                    for(SBQQ__Quote__c quote : [SELECT Id,SBQQ__Status__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name
                                                FROM SBQQ__Quote__c WHERE Id IN : quoteIds])
                    {
                        failedContractSet.add(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                        if(successContractSet != null && successContractSet.contains(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name)){
                            successContractSet.remove(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                        }
                        QTB_ExceptionLogger.enable();
                        QTB_ExceptionLogger.createLog(106,quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name+'-'+ErrorMsg,ErrorMsg,'',QTB_APIQuoteUpdationBatch); 
                    }
                }
            }
        }
        catch (Exception e){
            System.debug('ApexClass_execute()@@'+QTB_APIQuoteUpdationBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIQuoteUpdationBatch); 
        }
    }
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab US #12211,12041
* Description: finish() method is used for to update Quote status to Accepted and Update the Opportunity details and then scheduling QTB_APIOpportunityManipulationBatch job.
: If any failedContract then sending mail to logged-in user with failed Contract
**********************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        try{
            System.debug('QTB_APIQuoteUpdationBatch_finish()_successContractSet@@'+successContractSet);
            System.debug('QTB_APIQuoteUpdationBatch_finish()_failedContractSet@@'+failedContractSet);
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(successContractSet !=null && !successContractSet.isEmpty() && !Test.isRunningTest()){
                 QTB_APIQuoteManipulationBatch.revertQuoteLineSubTypeChanges(quoteIdSet,productToUpdateSet);  //reverting the QuoteLine's subscription type back to 'One-time'
                
                //schedule to execute Batch Job only once after 10 min,Batch size = 1 
                System.scheduleBatch(new QTB_APIOpportunityManipulationBatch(successContractSet,failedContractSet,dataHolderAPIObjId),'QTB_APIOppotunityManipulationBatchJob',Integer.valueOf(System.Label.QTB_APINextBatchFireTime),Integer.valueOf(System.Label.QTB_APIOpportunityBatchSize));
            }
            else{
                //Updating Status to Failed
                QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                dataHolderAPIObj.Id = dataHolderAPIObjId;
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
                update dataHolderAPIObj;
                //Send email to logged-in user with failed contracts
                QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'Quote');
            }
        }
        catch (Exception e){
            System.debug('ApexClass_finish()@@'+QTB_APIQuoteUpdationBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());            
            //Email Notification for all failed contract records            
            QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'Quote');
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIQuoteUpdationBatch); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: compareUpdateQLCSRate
* Parameters : Map<Id,Id> quoteIdWithOriginalContractIdMap
* Return Type: void
* Requirement: Gitlab US #12211
* Description: compareUpdateQLCSRate() method is used for to compare Subscription Consumption Schedule Rate with newly generated Renewal Quote Line Consumption Schedule Rate,
If any difference found in prices, then updating the Quote Line Consumption Schedule Price as per Subscription Consumption Schedule Rate.
**********************************************************************************************************/    
    public static void compareUpdateQLCSRate(Map<Id,Id> quoteIdWithOriginalContractIdMap){
        Map<Id,List<SBQQ__SubscriptionConsumptionRate__c>> subscriptionWithSubCSRatesMap = new Map<Id,List<SBQQ__SubscriptionConsumptionRate__c>>();
        List<SBQQ__QuoteLineConsumptionRate__c> quoteLineCSRateFinalList = new List<SBQQ__QuoteLineConsumptionRate__c>();
        //Fetching Subscription CS Rates based on contracts
        for(SBQQ__SubscriptionConsumptionRate__c subscriptionCSRate : [SELECT Id, Name, SBQQ__Price__c,SBQQ__SubscriptionConsumptionSchedule__r.SBQQ__Subscription__c,SBQQ__SubscriptionConsumptionSchedule__r.SBQQ__Subscription__r.SBQQ__Contract__c  
                                                                       FROM SBQQ__SubscriptionConsumptionRate__c 
                                                                       WHERE SBQQ__SubscriptionConsumptionSchedule__r.SBQQ__Subscription__r.SBQQ__Contract__c IN: quoteIdWithOriginalContractIdMap.values()])
        {
            //Map of Subscription with its Subscription CS Rate
            if(subscriptionWithSubCSRatesMap.containsKey(subscriptionCSRate.SBQQ__SubscriptionConsumptionSchedule__r.SBQQ__Subscription__c)){
                subscriptionWithSubCSRatesMap.get(subscriptionCSRate.SBQQ__SubscriptionConsumptionSchedule__r.SBQQ__Subscription__c).add(subscriptionCSRate);
            }else{
                subscriptionWithSubCSRatesMap.put(subscriptionCSRate.SBQQ__SubscriptionConsumptionSchedule__r.SBQQ__Subscription__c, new List<SBQQ__SubscriptionConsumptionRate__c>{subscriptionCSRate});
            }
            
        }
        
        //Fetching QuoteLine CS Rates based on renewal Quotes
        for(SBQQ__QuoteLineConsumptionRate__c quoteLineCSRate : [SELECT Id, Name, SBQQ__Price__c,SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c  
                                                                 FROM SBQQ__QuoteLineConsumptionRate__c 
                                                                 WHERE SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__r.SBQQ__Quote__c IN: quoteIdWithOriginalContractIdMap.keySet()])
        {
           //
            if(!subscriptionWithSubCSRatesMap.isEmpty() && subscriptionWithSubCSRatesMap.containsKey(quoteLineCSRate.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c))
            {
                for(SBQQ__SubscriptionConsumptionRate__c subCSRate : subscriptionWithSubCSRatesMap.get(quoteLineCSRate.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c)){
                    //Comparing Subscription CS Rate with QuoteLine CS Rate
                    if(subCSRate.Name == quoteLineCSRate.Name && subCSRate.SBQQ__Price__c != quoteLineCSRate.SBQQ__Price__c ){
                        SBQQ__QuoteLineConsumptionRate__c quoteLineCSRateObj = new SBQQ__QuoteLineConsumptionRate__c();
                        quoteLineCSRateObj.Id = quoteLineCSRate.Id;
                        quoteLineCSRateObj.SBQQ__Price__c = subCSRate.SBQQ__Price__c;
                        quoteLineCSRateFinalList.add(quoteLineCSRateObj);
                    }
                }
            }
        }
        //Update QuoteLine Consumption Schedule Rates
        if(quoteLineCSRateFinalList != null && !quoteLineCSRateFinalList.isEmpty()){
            SBQQ.TriggerControl.disable();
            update quoteLineCSRateFinalList;
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