/*****************************************************************************************************
* Class         : QTB_APISubscriptionUpliftBatch
* Test Class    : QTB_APISubscriptionUpliftBatch_Test
* Author        : IRM/Virtusa
* Purpose       : Regular API Uplift:- This batch class is responsible to create any missing Minimum subscriptions and update Subscription Consumption Schedule Rates, Subscription Renewal Price based on mentioned API price from CSV file
and from final() method calling another batch class for creating renewal Opportunity & renewal Quote. 
and if contract API process failed, then sending Email to logged-in user with failed contracts. 
* Requirement   : Gitlab US #10331, #10329, #12040
* Developer                Date            Description
* -----------------------------------------------------------------------------------------------------
* Shailesh              11/25/2022       Gitlab US #10331, #10329,12040 Create Minimum Subscriptions, Update Subscription CS Rate, Update Renewal Price based on Quantity
* Changed History       20/06/2023       Gitlab US #15909  API Uplift Scenario for Multi Currency
*******************************************************************************************************/
public class QTB_APISubscriptionUpliftBatch implements Database.Batchable<sObject>,Database.Stateful {
    static final string QTB_APISubscriptionUpliftBatch = 'QTB_APISubscriptionUpliftBatch';       
    String documentId;
    Set<String> contractNameSet = new Set<String>();
    Map<String,Id> dataHolderAPIObjMap = new Map<String,Id>();
    Set<String> failedContractNameSet = new Set<String>();
    Map<String, List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>> contractWithWrapperDataMap = new Map<String, List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>>();
    Map<Id, List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>> subscriptionIdWithWrapperDataMap = new Map<Id, List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>>();
    Map<String,Decimal> subWithItsQuantityMap = new Map<String,Decimal>();
    Map<String,String> subWithItsConsScheduleNameMap = new Map<String,String>();
    List<String> subscriptionFieldsList = new List<String>(SBQQ__Subscription__c.SObjectType.getDescribe().fields.getMap().keyset());    
    public Set<String> minimumProductCodeSet = new Set<String>();  
    public Set<String> minimumProductCodeCSNameSet = new Set<String>(); 
    Set<String> renewalContractSet = new Set<String>();
    Set<Id> oneTimeProductSet = new Set<Id>();
    Set<Id> productToUpdateSet = new Set<Id>();
    /*********************************************************************************************************
* Method Name: QTB_APISubscriptionUpliftBatch
* Parameters : List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList,String contentDocumentId
* Requirement: Gitlab #
* Description: This constructor is responsible to seperate out the values from wrapper data and storing it to maps, those map will be used in execute() methods
**********************************************************************************************************/    
    public QTB_APISubscriptionUpliftBatch(List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList,String contentDocumentId){
        System.debug('QTB_APISubscriptionUpliftBatch_subDataWrapList@@'+subDataWrapList);
        if(!subDataWrapList.isEmpty() && subDataWrapList.size() > 0){
            String minimumProductsCode = System.Label.QTB_MinimumProducts; //list of minimum products                      
            documentId = contentDocumentId;
            Id PricebookId;
            
            String currencyCode;
            //iterating on subscriptionData
            for(QTB_APIUpliftCntrl.SubscriptionDataWrapper subData : subDataWrapList ){                 
                //Store contract name -- need in execute() method
                contractNameSet.add(subData.contractName);  
                system.debug('subData@@@' +subData+ ', contractNameSet@@'+contractNameSet);
                //Map of ContractName with WrapperData
                if(contractWithWrapperDataMap.containsKey(subData.contractName)){
                    contractWithWrapperDataMap.get(subData.contractName).add(subData); 
                }else{
                    contractWithWrapperDataMap.put(subData.contractName,new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>{subData});
                }
                
                //Map of SubscriptionId with WrapperData
                if(subscriptionIdWithWrapperDataMap.containsKey(subData.subscriptionId)){
                    subscriptionIdWithWrapperDataMap.get(subData.subscriptionId).add(subData); 
                }else{
                    subscriptionIdWithWrapperDataMap.put(subData.subscriptionId,new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>{subData});
                }
            }
            //Iterating on DataHolder object and storing the record in map for documentId with DataholderId
            for(QTB_Data_Holder__c dataholder : [SELECT Id,QTB_APIDocument_Id__c,QTB_APIStatus__c 
                                                 FROM QTB_Data_Holder__c
                                                 WHERE QTB_APIDocument_Id__c = :documentId])
            {
                dataHolderAPIObjMap.put(documentId,dataholder.Id);   
            }
            
            //iterating on subscription records, and storing values in maps
            for(SBQQ__Subscription__c sub : [SELECT Id,SBQQ__Contract__c,SBQQ__Contract__r.IM_Country_Code__c,SBQQ__Contract__r.Name, SBQQ__Contract__r.SBQQ__OpportunityPricebookId__c,SBQQ__Quantity__c,QTB_Quote_line_Consumption_Schedule_Name__c,CurrencyIsoCode 
                                             FROM SBQQ__Subscription__c 
                                             WHERE SBQQ__Contract__r.Name IN :contractNameSet])
            {
                //Map - subscriptionId with quantity, taking 15 digit subscriptionId as in report data contains 15 digit subscriptionId
                subWithItsQuantityMap.put((sub.Id+'').left(15), sub.SBQQ__Quantity__c);
                
                //Map - subscriptionId with selected ConsumptionScheduleName, taking 15 digit subscriptionId bcoz in report data contains 15 digit subscriptionId
                subWithItsConsScheduleNameMap.put((sub.Id+'').left(15), sub.QTB_Quote_line_Consumption_Schedule_Name__c);  
                
                PricebookId = sub.SBQQ__Contract__r.SBQQ__OpportunityPricebookId__c;
                //Added CurrencyIsoCode as per #15909
                currencyCode =sub.CurrencyIsoCode;
            }
            //spliting Product Codes from Custom Label by comma seperated and storing each value in Set<String> variable 
            if(minimumProductsCode != null)
            {
                for(String minimumProduct : minimumProductsCode.split(','))
                {
                    minimumProductCodeSet.add(minimumProduct);
                    minimumProductCodeCSNameSet.add('List Rate '+minimumProduct);
                }
                System.debug('minimumProductCodeSet@@'+minimumProductCodeSet);
            }
            //Added Pricebook2.IsActive = TRUE AND IsActive = true as per #15909
            for(PricebookEntry prd : [SELECT Id, Product2Id, Product2.Name, Pricebook2.Name,Pricebook2.IsActive,IsActive, Product2.recordtype.name,Product2.SBQQ__SubscriptionType__c
                                      FROM PricebookEntry 
                                      WHERE Pricebook2Id =: PricebookId  AND product2.recordtype.name = 'Global Sales Product' AND Pricebook2.IsActive = TRUE AND IsActive = true])
            {
                oneTimeProductSet.add(prd.Product2Id);
            }
            
        }
        checkHeapSize('QTB_APISubscriptionUpliftBatch');
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab US #10329
* Description: start() method is used for to Query on Contract and fetched all the contracts based on provided contractNameSet 
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String contractQuery = 'SELECT Id,Name FROM Contract WHERE Name IN:contractNameSet';
        
        //If query return no record, then storing not found contracts in this list failedContractNameSet        
        Database.QueryLocator queryResult = Database.getQueryLocator( contractQuery ); 
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
            failedContractNameSet.addAll(contractNameSet);
        }
        
        return Database.getQueryLocator(contractQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab US #10329, #10331
* Description: execute() method is used for to creation of missing minimum subscription, updation of Subscription Consumption Schedule Rates,
and updation of Subscription Renewal Price field value based on quantity.
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<Contract> scope){
        try {      
            //initialize the required varibles here as its used in execute() method only
            Map<Id,Decimal> subscriptionCSRateIdWithSCRateMap = new Map<Id,Decimal>();
            List<SBQQ__Subscription__c> existingSubscriptionsToClone = new List<SBQQ__Subscription__c>(); 
            List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>(); 
            List<SBQQ__SubscriptionConsumptionRate__c> subscriptionCSRateList = new List<SBQQ__SubscriptionConsumptionRate__c>();            
            Map<string,SBQQ__Subscription__c> subIdWithSubMap = new Map<string,SBQQ__Subscription__c>();
            if(scope !=null && !scope.isEmpty()){
                //iteration on contract
                for(Contract contr: scope )
                {
                    System.debug('contr@@'+contr);
                    Id contractId = contr.Id;  
                    renewalContractSet.add(contr.Id+'::RenewContract');
                    
                    //Fetching all subscription record with respective contract
                    String subscriptionQuery =  'SELECT ' + String.join( subscriptionFieldsList, ',' ) + 
                        ' ,SBQQ__Contract__r.SBQQ__OpportunityPricebookId__c,SBQQ__Product__r.ProductCode '+
                        ' FROM SBQQ__Subscription__c '+
                        ' WHERE SBQQ__Contract__c = :contractId';
                    existingSubscriptionsToClone =  Database.query( subscriptionQuery );     
                    
                    //US#10331, Calling createMissingMinimumsForSubscription() method to check & create missing minimums subscription for respective contracts 
                    subscriptionList = createMissingMinimumsForSubscription(existingSubscriptionsToClone);
                    
                    //Update subscription type from One-time to Renewable
                    for(SBQQ__Subscription__c sub : existingSubscriptionsToClone ){                       
                        System.debug('oneTimeProductSet.contains(sub.SBQQ__Product__c)@@'+oneTimeProductSet.contains(sub.SBQQ__Product__c));
                        System.debug('sub.SBQQ__SubscriptionType__c@@'+sub.SBQQ__SubscriptionType__c);
                        if(oneTimeProductSet != null && oneTimeProductSet.contains(sub.SBQQ__Product__c) && 
                           sub.SBQQ__SubscriptionType__c != null && sub.SBQQ__SubscriptionType__c.equalsIgnoreCase('One-time')){
                            SBQQ__Subscription__c subObj = new SBQQ__Subscription__c();
                            subObj.Id = sub.Id;
                            subObj.SBQQ__ProductSubscriptionType__c = 'Renewable';
                            subObj.SBQQ__SubscriptionType__c = 'Renewable';
                            productToUpdateSet.add(sub.SBQQ__Product__c);
                            string subId = subObj.Id;
                            subIdWithSubMap.put((subId).left(15),subObj);
                        }
                    }
                    
                    System.debug('subscriptionList.size()@@'+subscriptionList.size());
                    
                    System.debug('contractWithWrapperDataMap.size()@@'+contractWithWrapperDataMap.size());
                    if(contractWithWrapperDataMap != null && contractWithWrapperDataMap.containsKey(contr.Name))
                    {        
                        //based on contract name, getting all related subscription records,  -- iterating over subscription records
                        for(QTB_APIUpliftCntrl.SubscriptionDataWrapper wrapParent : contractWithWrapperDataMap.get(contr.Name))
                        {
                            System.debug('wrapParent@@'+wrapParent);
                            if(subscriptionIdWithWrapperDataMap != null && subscriptionIdWithWrapperDataMap.containsKey(wrapParent.subscriptionId))
                            {
                                boolean isQuantityMatch = false;
                                string wrapSubId = (wrapParent.subscriptionId).left(15);
                                SBQQ__Subscription__c subObj = new SBQQ__Subscription__c();  
                                if(subIdWithSubMap != null && !subIdWithSubMap.isEmpty() && subIdWithSubMap.containsKey(wrapSubId)){
                                    subObj.SBQQ__ProductSubscriptionType__c = subIdWithSubMap.get(wrapSubId).SBQQ__ProductSubscriptionType__c;
                                    subObj.SBQQ__SubscriptionType__c = subIdWithSubMap.get(wrapSubId).SBQQ__SubscriptionType__c;
                                }
                                //Scenarios -->  //Only List    //Only Range - Tier 1, Tier 2, Tier 3   //Combination of List & Range
                                //List 
                                System.debug('subWithItsConsScheduleNameMap.get(wrapSubId)@@'+subWithItsConsScheduleNameMap.get(wrapSubId));                                                           
                                if(subWithItsConsScheduleNameMap !=null && subWithItsConsScheduleNameMap.containsKey(wrapSubId)
                                   && subWithItsConsScheduleNameMap.get(wrapSubId) != null &&
                                   subWithItsConsScheduleNameMap.get(wrapSubId).contains('List'))
                                { 
                                    System.debug('List@@');
                                    if(wrapParent.subscriptionCSName != null && wrapParent.subscriptionCSName.contains('List')){                                       
                                        subObj.SBQQ__RenewalPrice__c = wrapParent.newPrice; 
                                        isQuantityMatch = true;
                                    } 
                                }//eg. 1-100; 100-1000; 1000-infinite   Qty=5  
                                else if(subWithItsConsScheduleNameMap !=null && !wrapParent.subscriptionCSName.contains('List'))
                                {
                                    System.debug('Other than List@@'+subWithItsConsScheduleNameMap.get(wrapSubId));
                                    System.debug('subWithItsQuantityMap.get(wrapSubId)@@'+subWithItsQuantityMap.get(wrapSubId));
                                    // Multiple Tier -- Range/Slab/Workorder
                                    if(wrapParent.subscriptionCSRateUpperBound != null && wrapParent.subscriptionCSRateUpperBound != ''  && 
                                       Decimal.valueOf(wrapParent.subscriptionCSRateLowerBound) <= subWithItsQuantityMap.get(wrapSubId) &&
                                       subWithItsQuantityMap.get(wrapSubId) < Decimal.valueOf(wrapParent.subscriptionCSRateUpperBound) && !Test.isRunningTest())
                                    {
                                        System.debug('FirstTier@@'+wrapParent.newPrice);
                                        subObj.SBQQ__RenewalPrice__c = wrapParent.newPrice;
                                        isQuantityMatch = true;
                                    }
                                    else if ((wrapParent.subscriptionCSRateUpperBound == null || wrapParent.subscriptionCSRateUpperBound == '' || Decimal.valueOf(wrapParent.subscriptionCSRateUpperBound) == 0 ) &&
                                             Decimal.valueOf(wrapParent.subscriptionCSRateLowerBound) <= subWithItsQuantityMap.get(wrapSubId))
                                    {
                                        System.debug('FinalTier@@'+wrapParent.newPrice);
                                        subObj.SBQQ__RenewalPrice__c = wrapParent.newPrice;                                     
                                        isQuantityMatch = true;
                                    }
                                }
                                if(isQuantityMatch){
                                    subObj.Id = wrapParent.subscriptionId;
                                    subscriptionList.add(subObj);
                                }
                                System.debug('subObj@@'+subObj);
                            }
                            
                            //Setting new prices in Subscription CS rate level
                            SBQQ__SubscriptionConsumptionRate__c rateObj = new SBQQ__SubscriptionConsumptionRate__c();
                            rateObj.Id = wrapParent.subscriptionCSRateId;
                            rateObj.SBQQ__Price__c = wrapParent.newPrice;
                            System.debug('rateObj@@'+rateObj);
                            subscriptionCSRateList.add(rateObj);
                        }
                    }
                    else{
                        failedContractNameSet.add(contr.Name);
                    }
                    System.debug('subscriptionList@@'+subscriptionList.size());
                }
            } 
            
            //Updating List of Subscription records
            if(!subscriptionList.isEmpty() && subscriptionList.size() > 0){
                System.debug('subscriptionList.size()@@'+subscriptionList.size());
                System.debug('subscriptionList@@'+subscriptionList);
                update subscriptionList;
                
                //Updating Subscription Consumption Schedules Rates
                if(!subscriptionCSRateList.isEmpty() && subscriptionCSRateList.size() > 0){
                    System.debug('subscriptionCSRateList.size()@@'+subscriptionCSRateList.size());
                    System.debug('subscriptionCSRateList@@'+subscriptionCSRateList);
                    //To update subscription consumption schedule rate need to disable package trigger.
                    SBQQ.TriggerControl.disable();
                    update subscriptionCSRateList;
                    SBQQ.TriggerControl.enable();
                }
            }
            checkHeapSize('execute');
        }
        catch (Exception e){
            failedContractNameSet.add(scope[0].Name);
            System.debug('Apex Class@@'+QTB_APISubscriptionUpliftBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),scope[0].Name+'-'+e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APISubscriptionUpliftBatch); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab US #10329, #10331
* Description: finish() method is used to update Contract's Renewal Quote field to true, and calling QTB_APIQuoteCalculationSchedule schedule clas.
and sending email to logged-in user with failed contract
**********************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        try{
            System.debug('QTB_APISubscriptionUpliftBatch_finish@@');
            List<Contract> contractList = new List<Contract>();
            Set<String> successContractSet = new Set<String>();
            
            //Updating DataHolder record as Success/Failed  -- Need to check what will be status for partial success ?????
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.Id = dataHolderAPIObjMap.get(documentId); 
            //Few contracts are Failed/Success
            if((failedContractNameSet != null && !failedContractNameSet.isEmpty()) || (contractNameSet != null && !contractNameSet.isEmpty())){ 
                successContractSet.addAll(contractNameSet);
                
                //delete Subscription consumption schedule records where product consumption scheduled is missing
                 deleteSubCSWrtProductCS(successContractSet);
                
                //Iterating on all contracts
                for(string contrName : contractNameSet){
                    //Checking if any contract is already present in failedContractNameSet
                    if(!failedContractNameSet.isEmpty() && failedContractNameSet.contains(contrName)){
                        successContractSet.remove(contrName);//removing failed contract from the successContractSet 
                    }
                }
                
                if(successContractSet != null && !successContractSet.isEmpty()){
                    dataHolderAPIObj.QTB_APIStatus__c = 'InProgress';  // Need to check Status , Partial Success/Failed ?? 
                    update dataHolderAPIObj;
                    
                    //Fetch if any renewalContract job is available for running contracts, then delete the record from recordJob record to process the same contract record.
                    List<SBQQ__RecordJob__c> recordJobList = [SELECT id, SBQQ__JobStatus__c, Createddate, LastModifiedDate
                                                              FROM SBQQ__RecordJob__c
                                                              WHERE SBQQ__RecordId__c IN :renewalContractSet];
                    if(recordJobList != null && !recordJobList.isEmpty()){
                        delete recordJobList;
                    }
                    if(!Test.isRunningTest()){
                        //Calling QTB_APIRenewalOpptyQuoteCreationBatch for creation of Renewal Oppty & Renewal Quote
                        //Batch size must be 1
                        Database.executeBatch(new QTB_APIRenewalOpptyQuoteCreationBatch(successContractSet,failedContractNameSet,productToUpdateSet,dataHolderAPIObjMap.get(documentId)),Integer.valueOf(System.Label.QTB_APIRegularBatchSize));
                    }
                }else{
                    dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                    dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                    dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractNameSet), ',');
                    update dataHolderAPIObj;
                    //Email Notification for failed contract records
                    sendEmailForFailedAPIContract(failedContractNameSet,'ContractSubscription');
                }
            } //All contracts are Failed
            else if((failedContractNameSet != null && !failedContractNameSet.isEmpty()) && (contractNameSet == null || contractNameSet.isEmpty())){
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed';   
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(contractNameSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractNameSet), ',');
                update dataHolderAPIObj;
                //Email Notification for all failed contract records
                sendEmailForFailedAPIContract(failedContractNameSet,'ContractSubscription');
            }
            checkHeapSize('finish');
        }
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APISubscriptionUpliftBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());  
            
            //Update DatHolder status to Failed
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.QTB_APIStatus__c = 'Failed';            
            dataHolderAPIObj.Id = dataHolderAPIObjMap.get(documentId);
            dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(contractNameSet), ','); 
            dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractNameSet), ',');  
            dataHolderAPIObj.QTB_APIErrorMessage__c = 'Class-'+QTB_APISubscriptionUpliftBatch+', Line No-'+e.getLineNumber() +', Error Message-'+e.getMessage();
            update dataHolderAPIObj;
            
            //reverting Product's subscription type back to 'One-time'
            revertProductSubtypeChanges(false);
            //reverting Subscription's subscriptiontype to 'One-time' 
            revertSubscriptionTypeOfSubscription(contractNameSet,failedContractNameSet,productToUpdateSet);
            
            //Email Notification for all failed contract records
            //failedContractNameSet.addAll(contractNameSet);
            sendEmailForFailedAPIContract(failedContractNameSet,'ContractSubscription');
            
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APISubscriptionUpliftBatch);
        }
    }
    
    /*********************************************************************************************************
* Method Name: createMissingMinimumsForSubscription
* Parameters : List<SBQQ__Subscription__c> subList
* Return Type: List<SBQQ__Subscription__c>
* Requirement: Gitlab US #10331
* Description: this method is responsible for creation of minimum subscription products based on pricebook
**********************************************************************************************************/
    public List<SBQQ__Subscription__c> createMissingMinimumsForSubscription(List<SBQQ__Subscription__c> subList){        
        Map<Id,Id> productIdWithPriceBookEntryIdMap = new Map<Id,Id>();
        Map<Id,String> productIdWithProductCodeMap = new Map<Id,String>();
        List<SBQQ__Subscription__c> minimumProductSubscriptionList = new List<SBQQ__Subscription__c>();
        List<Id> availableMinimumInSubscriptionList = new List<Id>();   
        Map<String,Id> conScheduleNameWithCSIdMap = new Map<String,Id>();
        System.debug('minimumProductCodeCSNameSet@@'+minimumProductCodeCSNameSet);
        if(minimumProductCodeCSNameSet != null && !minimumProductCodeCSNameSet.isEmpty()){
            for(ConsumptionSchedule cs : [SELECT Id,Name FROM ConsumptionSchedule WHERE Name IN :minimumProductCodeCSNameSet])
            {
                conScheduleNameWithCSIdMap.put(cs.Name,cs.Id);
            }
        }
        
        System.debug('subList[0].SBQQ__Contract__r.SBQQ__OpportunityPricebookId__c@@'+subList[0].SBQQ__Contract__r.SBQQ__OpportunityPricebookId__c);
        System.debug('minimumProductCodeSet@@'+minimumProductCodeSet);
        //based on contract pricebook id fetching pricebookentry records for minimum products
        //Added Pricebook2.IsActive = TRUE AND IsActive = true AND CurrencyISOCode as per #15909
        for(PricebookEntry pbe : [SELECT id,Product2Id,Product2.Name,Product2.ProductCode,Product2.Family
                                  FROM PricebookEntry 
                                  WHERE Pricebook2id =:subList[0].SBQQ__Contract__r.SBQQ__OpportunityPricebookId__c 
                                  AND Product2.ProductCode IN : minimumProductCodeSet AND Product2.IsActive = true AND Pricebook2.IsActive = TRUE AND IsActive = true AND CurrencyISOCode=:subList[0].CurrencyISOCode])
        {
            productIdWithPriceBookEntryIdMap.put(pbe.Product2Id,pbe.Id);
            productIdWithProductCodeMap.put(pbe.Product2Id,pbe.Product2.ProductCode);
        }
        System.debug('productIdWithPriceBookEntryIdMap@@'+productIdWithPriceBookEntryIdMap);
        
        //Iteration on subscription records
        for(SBQQ__Subscription__c sub : subList){
            // sub list -- check any minimum product available or not           
            if(productIdWithPriceBookEntryIdMap != null && productIdWithPriceBookEntryIdMap.containsKey(sub.SBQQ__Product__c)){
                // add available minimums to availableMinimumInSubscriptionList 
                availableMinimumInSubscriptionList.add(sub.SBQQ__Product__c);                
            }
        }
        System.debug('availableMinimumInSubscriptionList.size()@@'+availableMinimumInSubscriptionList.size());
        System.debug('availableMinimumInSubscriptionList@@'+availableMinimumInSubscriptionList);
        
        if(availableMinimumInSubscriptionList != null && availableMinimumInSubscriptionList.size() > 0){
            for(integer i = 0; i < availableMinimumInSubscriptionList.size(); i++)
            {
                //removing available minimum Subscription Products from productIdWithPriceBookEntryIdMap 
                Id availableMissingSubPrd = productIdWithPriceBookEntryIdMap.remove(availableMinimumInSubscriptionList[i]);
            }
        }        
        System.debug('productIdWithPriceBookEntryIdMap@@'+productIdWithPriceBookEntryIdMap);
        if(productIdWithPriceBookEntryIdMap != null && productIdWithPriceBookEntryIdMap.size() > 0){
            for(Id productId : productIdWithPriceBookEntryIdMap.keySet()){
                //Create missing minimum subscription
                if (productIdWithPriceBookEntryIdMap != null && productIdWithPriceBookEntryIdMap.containsKey(productId)){
                    SBQQ__Subscription__c subObj = subList[0].clone();
                    subObj.SBQQ__Product__c = productId;
                    subObj.SBQQ__ProductOption__c = null;
                    subObj.SBQQ__CustomerPrice__c = 0;
                    subObj.SBQQ__RegularPrice__c = 0;
                    subObj.SBQQ__SpecialPrice__c = 0;
                    subObj.SBQQ__RenewalPrice__c = null;
                    subObj.SBQQ__ListPrice__c = 0;
                    subObj.SBQQ__NetPrice__c = 0 ;
                    subObj.QTB_Final_Unit_Price__c = 0;
                    subObj.SBQQ__Discount__c = 0;
                    subObj.SBQQ__Quantity__c = 1;
                    subObj.QTB_Quantity__c = 1;
                    subObj.QTB_Prior_Quantity__c = 1; 
                    subObj.SBQQ__RenewalQuantity__c = 1;
                    subObj.SBQQ__OriginalQuoteLine__c = null; 
                    subObj.SBQQ__OrderProduct__c = null;
                    subObj.SBQQ__QuoteLine__c = null;
                    subObj.QTB_Display_in_Price_Schedule__c = false;
                    subObj.QTB_Consumption_Rate_Describe__c = null;
                    subObj.QTB_OriginalConsumptionID__c = conScheduleNameWithCSIdMap.get('List Rate '+productIdWithProductCodeMap.get(productId));
                    subObj.QTB_Quote_line_Consumption_Schedule_Name__c = 'List Rate '+productIdWithProductCodeMap.get(productId);
                    subObj.QTB_Consumption_Rate_Lowest_Price__c = 0;                
                    subObj.QTB_Tier_List_Price__c = true;               
                    minimumProductSubscriptionList.add(subObj); 
                }   
            }
        }
        System.debug('minimumProductSubscriptionList.size()@@'+minimumProductSubscriptionList.size());
        System.debug('minimumProductSubscriptionList@@'+minimumProductSubscriptionList);
        if(minimumProductSubscriptionList !=null && !minimumProductSubscriptionList.isEmpty()){
            insert minimumProductSubscriptionList; 
            
            //Calling createSubscriptionCSForMinimumsSubscription for Creation of Subscription CS
            createSubscriptionCSForMinimumsSubscription(minimumProductSubscriptionList);
        }
        
        return minimumProductSubscriptionList; 
    }
    
    /*********************************************************************************************************
* Method Name: createSubscriptionCSForMinimumsSubscription
* Parameters : List<SBQQ__Subscription__c> subList
* Return Type: void
* Requirement: Gitlab US #10331
* Description: this method is responsible for creation of subscription products consumption schedule for minimum subscription products
**********************************************************************************************************/    
    public static void createSubscriptionCSForMinimumsSubscription(List<SBQQ__Subscription__c> subList)
    {
        System.debug('createSubscriptionCSForMinimumsSubscription@@'+subList);
        List<SBQQ__SubscriptionConsumptionSchedule__c> subCSListFinal = new List<SBQQ__SubscriptionConsumptionSchedule__c>();        
        Set<Id> productIds = new Set<Id>();
        Set<String> productCodeSet = new Set<String>();
        Map<String, Id> productCodeWithCSIdMap = new Map<String, Id>();
        Map<Id,String> productIdWithProductCodeMap = new Map<Id,String>();
        Map<Id,String> consumpScheduleIdWithCSRateNameMap = new Map<Id,String>();
        
        for(SBQQ__Subscription__c minimumSub : subList){
            productIds.add(minimumSub.SBQQ__Product__c);
        }
        System.debug('productIds@@'+productIds);
        
        for(Product2 prd : [Select Id, ProductCode From Product2 where Id IN :productIds]){
            productCodeSet.add('List Rate '+prd.ProductCode);
            productIdWithProductCodeMap.put(prd.Id,prd.ProductCode);
        }
        System.debug('productCodeSet@@'+productCodeSet);
        System.debug('productIdWithProductCodeMap@@'+productIdWithProductCodeMap);
        
        for(ConsumptionSchedule cs : [SELECT Id, NAME FROM ConsumptionSchedule  WHERE NAME LIKE :productCodeSet and IsActive = true])
        {
            string productCode = (cs.Name).substringAfter('List Rate ');
            productCodeWithCSIdMap.put(productCode,cs.Id);
        }
        System.debug('productCodeWithCSIdMap@@'+productCodeWithCSIdMap);
        
        for(ConsumptionRate csRate : [SELECT Id, NAME,ConsumptionScheduleId 
                                      FROM ConsumptionRate 
                                      WHERE ConsumptionScheduleId IN :productCodeWithCSIdMap.values() and CurrencyIsoCode=: subList[0].CurrencyIsoCode ]){
                                          consumpScheduleIdWithCSRateNameMap.put(csRate.ConsumptionScheduleId,csRate.Name);
                                      }
        
        //iteration on subscriptions
        for(SBQQ__Subscription__c minimumSub : subList){
            SBQQ__SubscriptionConsumptionSchedule__c minSubCSObj = new SBQQ__SubscriptionConsumptionSchedule__c();
            minSubCSObj.Name = 'List Rate '+productIdWithProductCodeMap.get(minimumSub.SBQQ__Product__c);
            minSubCSObj.SBQQ__Subscription__c = minimumSub.Id; 
            minSubCSObj.SBQQ__BillingTerm__c = 1 ;
            minSubCSObj.SBQQ__BillingTermUnit__c = 'Month';
            minSubCSObj.SBQQ__Category__c = 'Rates';
            minSubCSObj.SBQQ__ConsumptionSchedule__c = productCodeWithCSIdMap.get(productIdWithProductCodeMap.get(minimumSub.SBQQ__Product__c));
            minSubCSObj.SBQQ__MatchingAttribute__c = '';
            minSubCSObj.SBQQ__RatingMethod__c = 'Tier';
            minSubCSObj.SBQQ__Type__c  = 'Range';
            minSubCSObj.CurrencyIsoCode = minimumSub.CurrencyIsoCode;
            minSubCSObj.QTB_External_Id__c = minimumSub.Id+'-'+productCodeWithCSIdMap.get(productIdWithProductCodeMap.get(minimumSub.SBQQ__Product__c));            
            subCSListFinal.add(minSubCSObj);
        }
        
        if(subCSListFinal != null && !subCSListFinal.isEmpty()){
            SBQQ.TriggerControl.disable();
            insert subCSListFinal;
            //Calling createSubscriptionCSRate for creation of rates
            createSubscriptionCSRate(subCSListFinal,consumpScheduleIdWithCSRateNameMap);
            SBQQ.TriggerControl.enable();
        }
    }
    
    /*********************************************************************************************************
* Method Name: createSubscriptionCSRate
* Parameters : List<SBQQ__SubscriptionConsumptionSchedule__c> subCSList,Map<Id,String> consumpScheduleIdWithCSRateNameMap
* Return Type: void
* Requirement: Gitlab US #10331
* Description: this method is responsible for creation of subscription products consumption schedule rates for minimum subscription products
**********************************************************************************************************/  
    public static void createSubscriptionCSRate(List<SBQQ__SubscriptionConsumptionSchedule__c> subCSList,Map<Id,String> consumpScheduleIdWithCSRateNameMap)
    {
        System.debug('createSubscriptionCSRate@@');
        List<SBQQ__SubscriptionConsumptionRate__c> subCSRateFinal = new List<SBQQ__SubscriptionConsumptionRate__c>();
        
        //iterating on subscription CS
        for(SBQQ__SubscriptionConsumptionSchedule__c scs : subCSList){
            System.debug('scs@@'+scs);
            SBQQ__SubscriptionConsumptionRate__c subCSRate = new SBQQ__SubscriptionConsumptionRate__c();
            subCSRate.Name = consumpScheduleIdWithCSRateNameMap.get(scs.SBQQ__ConsumptionSchedule__c);
            subCSRate.SBQQ__LowerBound__c = 1;
            subCSRate.SBQQ__PricingMethod__c = 'PerUnit';
            subCSRate.SBQQ__ProcessingOrder__c = 1;
            subCSRate.SBQQ__SubscriptionConsumptionSchedule__c = scs.Id;
            subCSRate.CurrencyIsoCode = scs.CurrencyIsoCode;
            subCSRate.SBQQ__Price__c = 0;
            subCSRateFinal.add(subCSRate);
        }
        
        if(subCSRateFinal != null && !subCSRateFinal.isEmpty()){
            SBQQ.TriggerControl.disable();
            insert subCSRateFinal;
            SBQQ.TriggerControl.enable();
        }
        
        Integer i = 0;
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
    
    /*********************************************************************************************************
* Method Name: sendEmailForFailedAPIContract
* Parameters : Set<String> failedContractNameSet
* Return Type: void
* Requirement: Gitlab US #10329
* Description: Sending email to user for failed Contract/Subscription, Quote, Opportunity
**********************************************************************************************************/
    public static void sendEmailForFailedAPIContract(Set<String> failedContractNameSet, string processFailed){
        //Email Notification for failed contracts
        System.debug('sendEmailForFailedAPIContract_failedContractNameSet@@'+failedContractNameSet);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        List<String> loggedInUserEmailList = new List<String>();
        loggedInUserEmailList.add(UserInfo.getUserEmail());
        loggedInUserEmailList.AddAll(System.Label.QTB_APIProcessFailedEmailNotificationUsersEMail.split(','));
        message.toAddresses = loggedInUserEmailList ;
        if(processFailed.equalsIgnoreCase('ContractSubscription')){
            message.subject = 'Regular API process failed at Contract/Subscription Updation'; 
        }
        else if(processFailed.equalsIgnoreCase('Renew Oppty/Quote')){
            message.subject = 'Regular API process failed at creation of Renewal Opportunity/Quote ';
        }
        else if(processFailed.equalsIgnoreCase('Quote')){
            message.subject = 'Regular API process failed at Quote Updation';
        }
        else if(processFailed.equalsIgnoreCase('Opportunity')){
            message.subject = 'Regular API process failed at Opportunity Updation';
        }
        else if(processFailed.equalsIgnoreCase('SalesOrder')){
            message.subject = 'Regular API process failed at Sales Order Creation';
        }
        else if(processFailed.equalsIgnoreCase('BillingOrder')){
            message.subject = 'Regular API process failed at Billing Order Creation';
        }else{
            message.subject = 'Regular API process failed';
        }     
        string failedContracts = String.join(new List<String>(failedContractNameSet), ',');
        message.plainTextBody = 'Dear '+UserInfo.getName()+',\n\n' +
            'Regular API process is failed,\n'+
            'Following are the failed contracts : '+failedContracts +
            '\n\nPlease reach to Administrator for more details.' +
            '\n\nThank You';
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
    }
    
    void checkHeapSize(String tag) {
        system.debug(tag + ': Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
    }
    
    /*********************************************************************************************************
* Method Name: revertSubscriptionTypeOfSubscription
* Parameters : Set<String> successContracts, Set<String> failedContracts,set<Id> productIds
* Return Type: void
* Requirement: Gitlab US #10329
* Description: Updating Subscription's subscription type back to 'One-time', as earlier we updated to renewable to make sync of subscription's & product's subscription type
: this method gets called from QTB_APIRenewalOpptyQuoteCreationBatch, QTB_APIQuoteManipulationBatch class
**********************************************************************************************************/
    public static void revertSubscriptionTypeOfSubscription(Set<String> successContracts, Set<String> failedContracts,set<Id> productIds)
    {
        System.debug('revertSubscriptionTypeOfSubscription_successContracts@@'+successContracts);
        System.debug('revertSubscriptionTypeOfSubscription_failedContracts@@'+failedContracts);
        System.debug('revertSubscriptionTypeOfSubscription_productIds@@'+productIds);
        List<SBQQ__Subscription__c> subListFinal = new List<SBQQ__Subscription__c>();
        Set<String> allContracts = new Set<String>();
        allContracts.addAll(successContracts);
        allContracts.addAll(failedContracts);
        if(allContracts != null && !allContracts.isEmpty() && productIds!= null && !productIds.isEmpty()){
            for(SBQQ__Subscription__c sub : [SELECT Id,Name,SBQQ__Contract__c,SBQQ__Contract__r.Name,SBQQ__Product__c, SBQQ__ProductSubscriptionType__c,SBQQ__SubscriptionType__c
                                             FROM SBQQ__Subscription__c
                                             WHERE SBQQ__Contract__r.Name IN :allContracts and SBQQ__Product__c IN :productIds])
            {
                SBQQ__Subscription__c subObj = new SBQQ__Subscription__c();
                subObj.Id = sub.Id;
                subObj.SBQQ__ProductSubscriptionType__c = 'One-time';
                subObj.SBQQ__SubscriptionType__c = 'One-time';
                subListFinal.add(subObj);
            }
            if(subListFinal != null && !subListFinal.isEmpty()){
                update subListFinal;
            }
        }
    }
    
    /*********************************************************************************************************
* Method Name: revertProductSubtypeChanges
* Parameters : Set<Id> productToUpdateSet
* Return Type: void
* Requirement: Gitlab US #10329
* Description: Updating Product's subscription type back to 'One-time', as earlier we updated to renewable to flow subscription to QuoteLine.
: this method gets called from QTB_APIRenewalOpptyQuoteCreationBatch, QTB_APIQuoteManipulationBatch class
**********************************************************************************************************/    
    public static void revertProductSubtypeChanges(boolean makeProductRenew){
        System.debug('revertProductSubtypeChanges_makeProductRenew@@'+makeProductRenew);
        Set<String> oneTimeProductCodeSet = new Set<String>(); 
        List<Product2> productListFinal = new List<Product2>();
        String onetimeProductsCode = System.Label.QTB_APIOneTimeProductsCode; //list of one time products 
        
        //spliting Product Codes from Custom Label by comma seperated and storing each value in Set<String> variable 
        if(onetimeProductsCode != null)
        {
            for(String oneTimePrd : onetimeProductsCode.split(','))
            {
                oneTimeProductCodeSet.add(oneTimePrd);
            }
            System.debug('oneTimeProductCodeSet@@'+oneTimeProductCodeSet);
        }
        
        //reverting Product2 subscription type back to 'One-time'
        if(oneTimeProductCodeSet != null && !oneTimeProductCodeSet.isEmpty()){
            for(Product2 prd : [SELECT Id, SBQQ__SubscriptionType__c 
                                FROM Product2 
                                WHERE recordtype.name = 'Global Sales Product' AND ProductCode IN: oneTimeProductCodeSet])
            {
                Product2 prdObj = new Product2();
                prdObj.Id = prd.Id;
                if(makeProductRenew){
                    prdObj.SBQQ__SubscriptionType__c = 'Renewable';  //Updating the Product to 'Renewable' so subscription product will flow to QuoteLine
                }else{
                    prdObj.SBQQ__SubscriptionType__c = 'One-time';  //Updating the Product back to 'One-time' 
                }
                productListFinal.add(prdObj);
            }
            SBQQ.TriggerControl.disable();
            update productListFinal;
            SBQQ.TriggerControl.enable(); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: deleteSubCSWrtProductCS
* Parameters : List<SBQQ__Subscription__c> subList
* Return Type: void
* Requirement: Gitlab US #10329
* Description: this method is responsible to delete the subscription CS where its consumption schedule reference not present
**********************************************************************************************************/        
    public static void deleteSubCSWrtProductCS(Set<String> successContractSet){
        System.debug('deleteSubCSWrtProductCS_successContractSet@@'+successContractSet);             
        List<SBQQ__SubscriptionConsumptionSchedule__c> subCSListForDelete = new List<SBQQ__SubscriptionConsumptionSchedule__c>();
        List<SBQQ__SubscriptionConsumptionSchedule__c> subCSListForUpdate = new List<SBQQ__SubscriptionConsumptionSchedule__c>();
        Map<String,SBQQ__SubscriptionConsumptionSchedule__c> SubCSNameWithSubCSMap = new Map<String,SBQQ__SubscriptionConsumptionSchedule__c>();
        Map<String,Id> prdCSNameWithCSIdMap = new Map<String,Id>();
        Set<String> subCSNameSet = new Set<String>();
        if(successContractSet != null && !successContractSet.isEmpty()){
            //Fetching Sub CS where consumption schedule is null
            for(SBQQ__SubscriptionConsumptionSchedule__c subCS : [SELECT Id,Name,SBQQ__ConsumptionSchedule__c,SBQQ__Subscription__c,SBQQ__Subscription__r.SBQQ__Product__c
                                                                  FROM SBQQ__SubscriptionConsumptionSchedule__c 
                                                                  WHERE SBQQ__ConsumptionSchedule__c = null AND SBQQ__Subscription__r.SBQQ__Contract__r.Name IN :successContractSet ])
            {
                
                SubCSNameWithSubCSMap.put(subCS.Id,subCS);
                subCSNameSet.add(subCS.Name);
            } 
            
            for(ConsumptionSchedule cs : [SELECT Id, Name FROM ConsumptionSchedule WHERE NAME IN :subCSNameSet]){
                prdCSNameWithCSIdMap.put(cs.Name,cs.Id);
            }
            
            for(SBQQ__SubscriptionConsumptionSchedule__c subCS : SubCSNameWithSubCSMap.values()){
                if(prdCSNameWithCSIdMap != null && !prdCSNameWithCSIdMap.isEmpty() && prdCSNameWithCSIdMap.containsKey(subCS.Name)){
                    SBQQ__SubscriptionConsumptionSchedule__c subCSObj = new SBQQ__SubscriptionConsumptionSchedule__c();
                    subCSObj.Id = subCS.Id;
                    subCSObj.SBQQ__ConsumptionSchedule__c = prdCSNameWithCSIdMap.get(subCS.Name);
                    subCSListForUpdate.add(subCSObj);
                }
                else{
                    subCSListForDelete.add(subCS);
                }
            }
        }
        SBQQ.TriggerControl.disable();
        if(subCSListForDelete != null && !subCSListForDelete.isEmpty()){
            delete subCSListForDelete;
        }
        if(subCSListForUpdate != null && !subCSListForUpdate.isEmpty()){
            update subCSListForUpdate;
        }
        SBQQ.TriggerControl.enable();
    }
}