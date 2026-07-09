/*****************************************************************************************************
* Class         : QTB_CreditRebillUsagesBatch
* Test Class    : QTB_CreditRebillUsagesBatch_Test
* Author        : IRM/Virtusa
* Purpose       : This class handle all operation to Copy the existing Usages from the Original Order for Credit & Rebill Process
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Change History: 
* Developer            Date           Description
* -----------------------------------------------------------------------------------------------------
* Shailesh       11/03/2023        Initial Version - Gitlab US #9256 Credit & Rebill 
-- Defect US#19307 -- change from Queueable apex(QTB_QueuableCreateCreditRebillUsages) to batch apex to handle large usage data
*******************************************************************************************************/
public class QTB_CreditRebillUsagesBatch implements Database.Batchable<sObject>{
    public static final String QTB_CreditRebillUsagesBatch = 'QTB_CreditRebillUsagesBatch';   
    String usgQuery = '';
    String usgBillingCountry = '';
    String billingCountry = '';
    String rebillType = '';
    String reBillInvoiceId = '';
    String newRebillOrderId = '';
    String FUEL_SURCHARGE = 'Fuel Surcharge';
    Id userId ;
    Set<String> usageSummaries = new Set<String>();
    Map<String, String> usageSummaryIdProductCodeMap = new Map<String, String>();
    
    /*********************************************************************************************************
Method Name: QTB_CreditRebillUsagesBatch
Parameters: Database.BatchableContext
Return Type: void
Description: QTB_CreditRebillUsagesBatch() constructor is used to fetch the existing invoiceline and based on that get the related usageSummaryIds
**********************************************************************************************************/
    public QTB_CreditRebillUsagesBatch(String usgBillingCountryTemp, String billingCountryTemp,String rebillTypeTemp,String reBillInvoiceIdTemp,String newRebillOrderIdTemp ){
        usgBillingCountry = usgBillingCountryTemp;
        billingCountry = billingCountryTemp;
        rebillType = rebillTypeTemp;
        reBillInvoiceId = reBillInvoiceIdTemp;
        newRebillOrderId = newRebillOrderIdTemp;
        userId = System.UserInfo.getUserId(); //fetch the userId
        //Other than BillingOnly countries
        if(usgBillingCountry != billingCountry) 
        {
            system.debug('If@@@@');
            for(blng__InvoiceLine__c oldInvLine : [SELECT id,blng__OrderProduct__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__OrderProduct__r.Product2.ProductCode,
                                                   blng__InvoiceLine__c.blng__UsageSummary__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c
                                                   FROM blng__InvoiceLine__c 
                                                   WHERE blng__Invoice__c =:reBillInvoiceId]) 
            {
                //SplitRebill -- allowing to clone usages for default products(Fuel Surcharge/Minimum Storage/Minimum Invoice)
                //Gitlab US#22022 -- Clone all the usages for SITAD including default products
                if(rebillType == System.Label.QTB_SplitRebill || oldInvLine.blng__Invoice__r.blng__Account__r.QTB_SITAD__c)
                {
                    usageSummaries.add(oldInvLine.blng__UsageSummary__c);
                    usageSummaryIdProductCodeMap.put(oldInvLine.blng__UsageSummary__c,oldInvLine.blng__OrderProduct__r.Product2.ProductCode);                      
                }
                //For regular rebill continue the same functionality as exclude the default products (Fuel Surcharge/Minimum Storage/Minimum Invoice)
                else{ 
                    if(!(oldInvLine.blng__Product__r.ProductCode == LABEL.QTB_Minimum_Storage ||
                         oldInvLine.blng__Product__r.ProductCode == LABEL.QTB_Invoice_Minimum  ||
                         oldInvLine.blng__Product__r.Name == FUEL_SURCHARGE))//Comparing with Fuel surcharge name instead of productCode due to multiple Fuel Surcharge products
                    {
                        usageSummaries.add(oldInvLine.blng__UsageSummary__c);
                        usageSummaryIdProductCodeMap.put(oldInvLine.blng__UsageSummary__c,oldInvLine.blng__OrderProduct__r.Product2.ProductCode);  
                    } 
                }
            }
        }
        else //BillingOnly Countries
        {
            system.debug('else@@@@');
            for(blng__InvoiceLine__c oldInvLine : [SELECT id,blng__OrderProduct__c,blng__Product__r.ProductCode,blng__OrderProduct__r.Product2.ProductCode,blng__InvoiceLine__c.blng__UsageSummary__c
                                                   FROM blng__InvoiceLine__c 
                                                   WHERE blng__Invoice__c =:reBillInvoiceId])
            {
                usageSummaries.add(oldInvLine.blng__UsageSummary__c);
                usageSummaryIdProductCodeMap.put(oldInvLine.blng__UsageSummary__c,oldInvLine.blng__OrderProduct__r.Product2.ProductCode);
            }
        }
        
        //Remove blanks and nulls
        if(!usageSummaries.isEmpty() && usageSummaries.size() > 0){
            System.debug('usageSummaries@@'+usageSummaries.size());
            usageSummaries.remove('');
            usageSummaries.remove(null);
        }
    }
    
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: void
Description: start() method is used to fetch the existing usages based on usageSummaryIds
**********************************************************************************************************/    
    public Database.QueryLocator start(Database.BatchableContext bc){        
        if(!usageSummaries.isEmpty() && usageSummaries.size() > 0){
            //Get all the fields from Usage
            List<String> UsageFieldsList = new List<String>(blng__Usage__c.SObjectType.getDescribe().fields.getMap().keyset());
            
            usgQuery = ' SELECT blng__OrderProduct__r.Product2Id, ' + 
                String.join( UsageFieldsList, ',' ) + 
                ' FROM blng__Usage__c WHERE blng__UsageSummary__c IN : usageSummaries';
        }       
        return Database.getQueryLocator(usgQuery); 
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__Usage__c>
Return Type: void
Description: Calculates Fuel Surcharges for each Billing Account
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<blng__Usage__c> OldUsagesToClone){
        try{
            System.debug('QTB_CreditRebillUsagesBatch_execute__OldUsagesToClone@@'+OldUsagesToClone.size());            
            Map<string,List<OrderItem>> orderProductIdWithOrderItemListMap = new Map<string,List<OrderItem>>(); //SplitRebill  
            List<blng__Usage__c> usageListToInsert = new List<blng__Usage__c>();
            Set<Id> opCSIdsSet = new Set<Id>();
            List<blng__UsageSummary__c> usgSumList = new List<blng__UsageSummary__c>();
            List<SBQQ__OrderItemConsumptionSchedule__c> ordItemCSList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            Map<Id,List<blng__Usage__c>> productIdWithListOfUsagesMap = new Map<Id,List<blng__Usage__c>>(); //SplitRebill
            Set<String> duplicatePrdWithOrderPrdCombination = new Set<String>();//Gitlab US #22731
            
            Order rebillOrd =[SELECT Id, QTB_Rebill_Type__c, Account.QTB_Customer_Number__c, OrderNumber 
                              FROM Order 
                              WHERE id =: newRebillOrderId][0];
            System.debug('rebillOrd@@'+rebillOrd);
            
            //Fetching OrderProduct based on provided orderProductIdList
            for(OrderItem orderProduct : [SELECT Id,OrderItemNumber,Product2Id, Product2.ProductCode,ServiceDate,EndDate,QTB_Final_Unit_Price__c,
                                          OrderId,Order.OrderNumber,Order.QTB_Rebill_Type__c, Order.Account.QTB_Customer_Number__c,blng__InvoiceGroupId__c,
                                          order.QTB_Legal_Entity_Country__c,SBQQ__RequiredBy__c,//Gitlab US#22731
                                          (Select Id,Name From sbqq__OrderItems__r) // we can query opcs as subquery, bcoz 1 orderproduct maximum have 3 to 4 opcs (List,Slab,Range)
                                          FROM OrderItem 
                                          WHERE OrderId =:newRebillOrderId order by createdDate desc]) //SpitRebill -- added order by to store existing orderproduct details in map in case of same products
            {
                if(orderProductIdWithOrderItemListMap.containsKey(orderProduct.Product2Id)){
                    orderProductIdWithOrderItemListMap.get(orderProduct.Product2Id).add(orderProduct);
                }else{
                    orderProductIdWithOrderItemListMap.put(orderProduct.Product2Id,new List<OrderItem>{orderProduct});
                }
                //delete duplicate order product cs (delete other than List OPCS)
                //Bypassed Billing only country for deletion of Usage Sumamries and OPCS for rebill Order GITLAB 19041
                if(QTB_Billing_Countries__c.getValues(orderProduct.order.QTB_Legal_Entity_Country__c) == null && orderProduct.sbqq__OrderItems__r != null && orderProduct.sbqq__OrderItems__r.size() > 1){
                    for(SBQQ__OrderItemConsumptionSchedule__c opcs : orderProduct.sbqq__OrderItems__r ){
                        if(!opcs.Name.contains('List')){
                            ordItemCSList.add(opcs);
                            opCSIdsSet.add(opcs.id);
                        }
                    }
                }
            }
            //Added null check for List that stored OPCS which is going for deletion of Usage Summaries of rebill Order GITLAB 19041
            if(opCSIdsSet != null){
                //To delete duplicate usage summary (delete other than List OPCS Usage Summary) fetching usageSummary
                for(blng__UsageSummary__c usgSum : [SELECT Id, Name,blng__OrderItemConsumptionSchedule__c 
                                                    FROM blng__UsageSummary__c 
                                                    WHERE blng__OrderItemConsumptionSchedule__c IN : opCSIdsSet])
                {
                    usgSumList.add(usgSum);
                } 
                opCSIdsSet.clear();//clearing the data
            }
            
            //delete duplicate usage summary (delete other than List OPCS Usage Summary)
            SBQQ.TriggerControl.disable();            
            if(!ordItemCSList.isEmpty()){                 
                delete ordItemCSList; 
            }
            if(!usgSumList.isEmpty()){
                delete usgSumList; 
            }
            SBQQ.TriggerControl.enable();
            
            if(!OldUsagesToClone.isEmpty() && OldUsagesToClone.size() > 0)
            {
                //Loop to store productId with List of OldUsages
                for(blng__Usage__c oldUsage : OldUsagesToClone)
                {
                    //SplitRebill -- storing productId with newUsages
                    if(!productIdWithListOfUsagesMap.isEmpty() && productIdWithListOfUsagesMap.containsKey(oldUsage.blng__OrderProduct__r.Product2Id)){
                        productIdWithListOfUsagesMap.get(oldUsage.blng__OrderProduct__r.Product2Id).add(oldUsage);
                    }
                    else{
                        productIdWithListOfUsagesMap.put(oldUsage.blng__OrderProduct__r.Product2Id, new List<blng__Usage__c>{oldUsage});//abc -- 10 usage
                    }
                }   
                OldUsagesToClone.clear(); //clearing the data
                
                if(!orderProductIdWithOrderItemListMap.isEmpty())
                {
                    //Fetching Products
                    for(Id productId : productIdWithListOfUsagesMap.keySet())
                    {
                        //Checking if orderProductIdWithOrderItemListMap contains the productId
                        if(orderProductIdWithOrderItemListMap.containsKey(productId))
                        {
                            //Fetching OrderProduct based on Product
                            for(OrderItem ordItm : orderProductIdWithOrderItemListMap.get(productId))
                            {
                                //Checking if productIdWithListOfUsagesMap contains the productId
                                //Gitlab US #22731 -- checking if prd with orderPrd combination not existing then only create the usage, to avoid duplicate usage
                                //duplicate usages gets created when invoice got created frm multiple order and those order have same products
                                if(!productIdWithListOfUsagesMap.isEmpty() && productIdWithListOfUsagesMap.containsKey(ordItm.Product2Id) &&
                                  !duplicatePrdWithOrderPrdCombination.contains(ordItm.Product2Id+'_'+ordItm.SBQQ__RequiredBy__c))
                                {
                                    //Fetching old usages based on productId
                                    for(blng__Usage__c oldUsage : productIdWithListOfUsagesMap.get(ordItm.Product2Id))
                                    {
                                        blng__Usage__c newUsage = oldUsage.clone();
                                        newUsage.blng__Order__c = null;//setting order to null
                                        newUsage.blng__OrderProduct__c = null;//setting orderProduct to null
                                        newUsage.blng__Status__c = 'New';
                                        newUsage.OwnerId = userId;
                                        newUsage.blng__UnitPrice__c = ordItm.QTB_Final_Unit_Price__c;
                                        //Matching ID -- combination of OrderNumber + CustomerNumber + ProductCode
                                        newUsage.blng__MatchingId__c =  rebillOrd.OrderNumber + rebillOrd.Account.QTB_Customer_Number__c + usageSummaryIdProductCodeMap.get(oldUsage.blng__UsageSummary__c);
                                        if(oldUsage.blng__PreratedAmount__c !=null && oldUsage.blng__PreratedAmount__c >=0){
                                            newUsage.blng__UnitPrice__c = 0;
                                            newUsage.blng__Subtotal__c = null; 
                                        }
                                        if(oldUsage.blng__PreratedQuantity__c !=null && oldUsage.blng__PreratedQuantity__c !=0){
                                            newUsage.blng__Quantity__c = null;
                                        }
                                        //SplitRebill -- Setting the Matching Attribute on Usage with combination of "OrderNumber + ORderItemNumber + blng__InvoiceGroupId__c"  
                                        if(rebillOrd.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill && orderProductIdWithOrderItemListMap.containsKey(oldUsage.blng__OrderProduct__r.Product2Id))
                                        {
                                            newUsage.blng__MatchingAttribute__c = ordItm.order.OrderNumber + ordItm.OrderItemNumber + ordItm.blng__InvoiceGroupId__c;
                                        }
                                        else{
                                            //Gitlab US#22731 --Changing the matchingAttribute value from orderNumber to OrderItemNumber for unique value
                                            newUsage.blng__MatchingAttribute__c = ordItm.OrderItemNumber;//rebillOrd.OrderNumber; 
                                        }
                                        usageListToInsert.add(newUsage);
                                    }
                                    
                                    //Gitlab US#22731 -- Defect fix 
                                    if(!ordItm.blng__InvoiceGroupId__c.containsIgnoreCase('split')){
                                    	duplicatePrdWithOrderPrdCombination.add(ordItm.Product2Id+'_'+ordItm.SBQQ__RequiredBy__c);
                                	}
                                }
                            } 
                        }
                    }
                }
                usageSummaryIdProductCodeMap.clear(); //clearing the data
                orderProductIdWithOrderItemListMap.clear();  //clearing the data
                productIdWithListOfUsagesMap.clear();  //clearing the data
                
                System.debug('usageListToInsert.size()'+usageListToInsert.size());
                if(!usageListToInsert.isEmpty() && usageListToInsert.size() > 0){
                    insert usageListToInsert; //inserting the newly created usages
                    usageListToInsert.clear(); //clearing the data
                }
            } 
        }
        catch (Exception e) {
            System.debug('QTB_QueuableCreateCreditRebillUsages_Exception@@'+e.getLineNumber()+'-'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_CreditRebillUsagesBatch);
            throw e;
        }
    }
    
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Description: To update the invoice status once the usage creation is completed
**********************************************************************************************************/    
    public void finish(Database.BatchableContext bc){        
        //Change Invoice ReBill Status
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.id = reBillInvoiceId;
        inv.QTB_ReBill_Status__c = 'Usage In Progress';
        Update inv;         
    }
}