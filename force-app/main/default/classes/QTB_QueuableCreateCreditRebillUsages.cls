/*****************************************************************************************************
* Class         : QTB_QueuableCreateCreditRebillUsages
* Test Class    : QTB_QueuableCrCreditRebillUsg_Test
* Author        : IRM/Virtusa
* Purpose       : This class handle all operation to Copy the existing Usages from the Original Order for Credit & Rebill Process
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Change History: 06/20/2022
* Developer            Date           Description
* -----------------------------------------------------------------------------------------------------
* Gopi/Shailesh       06/20/2022      Initial Version - Gitlab US #9256 Credit & Rebill
* Shailesh(Virtusa)   07/05/2023      SplitRebill - Gitlab US#16253
*******************************************************************************************************/
Global with sharing class QTB_QueuableCreateCreditRebillUsages implements Queueable {
    
    public static final String QTB_QueuableCreateCreditRebillUsages = 'QTB_QueuableCreateCreditRebillUsages';    
    global Id reBillInvoiceId;
    global id newRebillOrder;
    String usgBillingCountry = '';
    String billingCountry = '';
    string rebillType = '';
    String FUEL_SURCHARGE = 'Fuel Surcharge';
    public static boolean throwExplicitException = false;
    global QTB_QueuableCreateCreditRebillUsages(Id rebillInvoice,string newOrder)
    {
        reBillInvoiceId = rebillInvoice;
        newRebillOrder = newOrder;
        //Gitlab US#19307 -- Moved logic of UsageSummary's update logic to QTB_UsagesForRebill.createUsageForRebillOrder() class
        //Setting rebillType, BillingCountry value based on UsageSummary
        for (blng__UsageSummary__c usgSum : [SELECT id, blng__MatchingId__c, blng__MatchingAttribute__c, blng__Order__r.OrderNumber,blng__Order__r.QTB_Rebill_Type__c,
                                             blng__OrderProduct__r.blng__InvoiceGroupId__c,QTB_Legal_Entity_Country__c,blng__OrderProduct__r.OrderItemNumber,
                                             blng__Order__r.Account.QTB_SITAD__c  //Gitlab US #22022 -- added QTB_SITAD__c field in query
                                             FROM blng__UsageSummary__c 
                                             WHERE blng__Order__c =: newOrder])
        {
            rebillType = usgSum.blng__Order__r.QTB_Rebill_Type__c;                     
            usgBillingCountry = usgSum.QTB_Legal_Entity_Country__c;
            billingCountry = QTB_Billing_Countries__c.getValues(usgBillingCountry) != null ? QTB_Billing_Countries__c.getValues(usgBillingCountry).Name : '';
        }        
    }
    
    /***********************************************************************************************************
* Method      : execute
* Parameter   : QueueableContext qc
* Return Type : void
* Author      : IRM/Virtusa
* Description : execute() method is responsible to create usages based on existing invoice associated usages, 
& update the some field values based on newly created order, OrderProduct values
**************************************************************************************************************/  
    global void execute(QueueableContext qc) 
    {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            Set<string> usageSummaries = new Set<string>();
            Map<string, string> usageSummaryIdProductCodeMap = new Map<string, string>();
            Map<string,List<OrderItem>> orderProductIdWithOrderItemListMap = new Map<string,List<OrderItem>>(); //SplitRebill  
            List<blng__Usage__c> OldUsagesToClone = new List<blng__Usage__c>();
            List<blng__Usage__c> usageListToInsert = new List<blng__Usage__c>();
            Set<Id> opCSIdsSet = new Set<Id>();
            List<blng__UsageSummary__c> usgSumList = new List<blng__UsageSummary__c>();
            List<SBQQ__OrderItemConsumptionSchedule__c> ordItemCSList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            Map<String,List<blng__Usage__c>> productIdWithListOfUsagesMap = new Map<String,List<blng__Usage__c>>(); //SplitRebill
            Id userId = System.UserInfo.getUserId(); //fetch the userId
            Set<String> duplicatePrdWithOrderPrdCombination = new Set<String>();//Gitlab US #22731
            system.debug('usgBillingCountry@@' +usgBillingCountry);
            system.debug('billingCountry@@' +billingCountry);
            set<String> ordItemId = new set<String>(); //Gitlab #24640
            //Other than billingOnly country
            if(usgBillingCountry != billingCountry ) 
            {
                system.debug('If@@@@');
                for(blng__InvoiceLine__c oldInvLine : [SELECT id,blng__OrderProduct__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__OrderProduct__r.Product2.ProductCode,blng__UsageSummary__c,
                                                       blng__Invoice__r.blng__Account__r.QTB_SITAD__c
                                                       FROM blng__InvoiceLine__c 
                                                       WHERE blng__Invoice__c =:reBillInvoiceId AND blng__UsageSummary__c != null ]) 
                {
                    //SplitRebill -- allowing to clone usages for default products(Fuel Surcharge/Minimum Storage/Minimum Invoice)
                    //Gitlab US #22022 -- For SITAD copy the fuel surcharge usages from existing order -- added isSITAD check
                    if(rebillType == System.Label.QTB_SplitRebill || oldInvLine.blng__Invoice__r.blng__Account__r.QTB_SITAD__c )
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
            else //BillingOnly country
            {
                system.debug('else@@@@');
                for(blng__InvoiceLine__c oldInvLine : [SELECT id,blng__OrderProduct__c,blng__Product__r.ProductCode,blng__OrderProduct__r.Product2.ProductCode, blng__UsageSummary__c
                                                       FROM blng__InvoiceLine__c 
                                                       WHERE blng__Invoice__c =:reBillInvoiceId and blng__UsageSummary__c != null ])
                {
                    usageSummaries.add(oldInvLine.blng__UsageSummary__c);
                    usageSummaryIdProductCodeMap.put(oldInvLine.blng__UsageSummary__c,oldInvLine.blng__OrderProduct__r.Product2.ProductCode);
                }
            }
            
            //Get all the fields from Usage
            List<String> UsageFieldsList = new List<String>(blng__Usage__c.SObjectType.getDescribe().fields.getMap().keyset());
            
            if(!usageSummaries.isEmpty() && usageSummaries.size() > 0){
              /*  String usgQuery = ' SELECT blng__OrderProduct__r.Product2Id, ' + 
                    String.join( UsageFieldsList, ',' ) + 
                    ' FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usageSummaries'; */
                    String usgQuery = 'SELECT blng__OrderProduct__r.Product2Id, ' +
                        'blng__OrderProduct__r.Product2.QTB_Storage_Product__c, ' +
                        String.join(UsageFieldsList, ',') +
                        ' FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usageSummaries';
                //Get all the old Usage
                OldUsagesToClone =  Database.query( usgQuery );
                System.debug('OldUsagesToClone@@'+OldUsagesToClone.size());
                usageSummaries.clear();
            }            
            
            //Rebill Order .. //Epic: 2894 added Account.QTB_Legal_Entity_Country__c
            Order ord =[SELECT Id, QTB_Rebill_Type__c, Account.QTB_Customer_Number__c,Account.QTB_Legal_Entity_Country__c,OrderNumber 
                        FROM Order 
                        WHERE id =: newRebillOrder];    
            
            if(ord != null){
                //Fetching Rebill OrderProduct based on provided rebillOrderId
                for(OrderItem orderProduct : [SELECT Id,OrderItemNumber,Product2Id, Product2.ProductCode,ServiceDate,EndDate,QTB_Final_Unit_Price__c,
                                              OrderId,Order.OrderNumber,Order.QTB_Rebill_Type__c, Order.Account.QTB_Customer_Number__c,blng__InvoiceGroupId__c,
                                              order.QTB_Legal_Entity_Country__c,SBQQ__RequiredBy__c,
                                              (Select Id,Name From sbqq__OrderItems__r) // we can query opcs as subquery, bcoz 1 orderproduct maximum have 3 to 4 opcs (List,Slab,Range)
                                              FROM OrderItem 
                                              WHERE OrderId =:ord.id order by createdDate desc]) //SpitRebill -- added order by to store existing orderproduct details in map in case of same products
                {
                    //Stroing productId with rebillOrderProduct
                    if(orderProductIdWithOrderItemListMap.containsKey(orderProduct.Product2Id)){
                        orderProductIdWithOrderItemListMap.get(orderProduct.Product2Id).add(orderProduct);
                    }else{
                        orderProductIdWithOrderItemListMap.put(orderProduct.Product2Id,new List<OrderItem>{orderProduct});
                    }
                    //delete duplicate order product cs (delete other than List OPCS)
                    //Bypassed Billing only country for deletion of Usage Sumamries and OPCS for rebill Order GITLAB 19041
                    if(QTB_Billing_Countries__c.getValues(orderProduct.order.QTB_Legal_Entity_Country__c) == null && orderProduct.sbqq__OrderItems__r != null && orderProduct.sbqq__OrderItems__r.size() > 1 ){
                        for(SBQQ__OrderItemConsumptionSchedule__c opcs : orderProduct.sbqq__OrderItems__r ){
                            if(!opcs.Name.contains('List')){
                                ordItemCSList.add(opcs);
                                opCSIdsSet.add(opcs.id);
                            }
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
                ordItemCSList.clear();//clearing the data
            }
            if(!usgSumList.isEmpty()){
                delete usgSumList; 
                usgSumList.clear();//clearing the data
            }
            SBQQ.TriggerControl.enable();
            
            if(!OldUsagesToClone.isEmpty() && OldUsagesToClone.size() > 0)
            {
                //Loop to store productId with List of OldUsages
                for(blng__Usage__c oldUsage : OldUsagesToClone)
                {
                    //SplitRebill -- storing productId with newUsages
                    //Defect Fix #20667 Created key as productID with orderProductId for unique combination
                    if(!productIdWithListOfUsagesMap.isEmpty() && productIdWithListOfUsagesMap.containsKey(oldUsage.blng__OrderProduct__r.Product2Id+'_'+oldUsage.blng__OrderProduct__c)){
                        productIdWithListOfUsagesMap.get(oldUsage.blng__OrderProduct__r.Product2Id+'_'+oldUsage.blng__OrderProduct__c).add(oldUsage);
                    }
                    else{
                        productIdWithListOfUsagesMap.put(oldUsage.blng__OrderProduct__r.Product2Id+'_'+oldUsage.blng__OrderProduct__c, new List<blng__Usage__c>{oldUsage});//abc -- 10 usage
                    }
                }   
                OldUsagesToClone.clear(); //clearing the data                
                if(!orderProductIdWithOrderItemListMap.isEmpty())
                {
                    //Fetching Products
                    for(String productIdWithOrderPrdId : productIdWithListOfUsagesMap.keySet())
                    {
                        string productId = productIdWithOrderPrdId.substringBefore('_');
                        //Checking if orderProductIdWithOrderItemListMap contains the productId
                        if(orderProductIdWithOrderItemListMap.containsKey(productId))
                        {
                            //Fetching OrderProduct based on Product
                            for(OrderItem ordItm : orderProductIdWithOrderItemListMap.get(productId))
                            {
                                //Defect Fix #20667 Checking if productIdWithListOfUsagesMap contains the productId with old orderproductId (ordItm.SBQQ__RequiredBy__c contains old orderproductId)
                                //Gitlab US #22731 -- checking if prd with orderPrd combination not existing then only create the usage, to avoid duplicate usage
                                //duplicate usages gets created when invoice got created frm multiple order and those order have same products
                                //Gitlab #24640 - added !ordItemId.contains(ordItm.Id) in below if condition to stop duplicate usage creation
                                if(!productIdWithListOfUsagesMap.isEmpty() && productIdWithListOfUsagesMap.containsKey(ordItm.Product2Id+'_'+ordItm.SBQQ__RequiredBy__c) &&
                                  !duplicatePrdWithOrderPrdCombination.contains(ordItm.Product2Id+'_'+ordItm.SBQQ__RequiredBy__c)
                                  && !ordItemId.contains(ordItm.Id))
                                {
                                    ////Defect Fix #20667 Fetching old usages based on productId with oldOrderItemId
                                    for(blng__Usage__c oldUsage : productIdWithListOfUsagesMap.get(ordItm.Product2Id+'_'+ordItm.SBQQ__RequiredBy__c))
                                    {
                                        ordItemId.add(ordItm.Id);//stores new orderItem Ids Gitlab #24640
										Date startDate = oldUsage.QTB_Start_Date_MRC__c;
										Date endDate = oldUsage.QTB_End_Date_MRC__c;
										Integer totalMonths = 0;
                                        blng__Usage__c newUsage = oldUsage.clone();
                                        newUsage.blng__Order__c = null;//setting order to null
                                        newUsage.blng__OrderProduct__c = null;//setting orderProduct to null
                                        newUsage.blng__Status__c = 'New';
                                        newUsage.OwnerId = userId ;
                                        newUsage.blng__UnitPrice__c = ordItm.QTB_Final_Unit_Price__c;
                                        //Matching ID -- combination of OrderNumber + CustomerNumber + ProductCode
                                        newUsage.blng__MatchingId__c =  ord.OrderNumber + ord.Account.QTB_Customer_Number__c + usageSummaryIdProductCodeMap.get(oldUsage.blng__UsageSummary__c);
                                        //Epic: 2894 added oldUsage.blng__Subtotal__c > 0 and country check to avoid standard validation error during credit&Rebill                                            
                                        if(oldUsage.blng__PreratedAmount__c !=null && oldUsage.blng__PreratedAmount__c >=0 && oldUsage.blng__Subtotal__c > 0 && ord.Account.QTB_Legal_Entity_Country__c != System.label.QTB_NA_Countries){ // gitlab-24186
                                            newUsage.blng__UnitPrice__c = 0;
                                            newUsage.blng__Subtotal__c = null; 
                                            // newUsage.blng__Quantity__c = null;  commented as per GITLAB #20666
                                        }
                                        if(oldUsage.blng__PreratedQuantity__c !=null && oldUsage.blng__PreratedQuantity__c !=0){
                                            newUsage.blng__Quantity__c = null;
                                        }
										// GITLAB US - #28503
										system.debug('oldUsage.blng__OrderProduct__r.Product2.QTB_Storage_Product__c' +oldUsage.blng__OrderProduct__r.Product2.QTB_Storage_Product__c);
										if(startDate !=null && 	endDate !=null && endDate >= startDate )
										{
                                        Date tempDate = startDate.toStartOfMonth();
										while (tempDate <= endDate) {
										totalMonths++;
										tempDate = tempDate.addMonths(1);
										}
										}
										else 
										{ 
                                            if(oldUsage.QTB_Term__c == null && oldUsage.blng__OrderProduct__r.Product2.QTB_Storage_Product__c == true)
                                            {
                                                totalMonths = 1; // Set default to 1 if term is null
                                            }
										}
										newUsage.QTB_Term__c = String.valueOf(totalMonths);
										
										// GITLAB -> #31563 reset the term to blank for non storage products if MRC dates are blank
										if(oldUsage.blng__OrderProduct__r.Product2.QTB_Storage_Product__c == false &&
										oldUsage.QTB_Start_Date_MRC__c ==null && oldUsage.QTB_End_Date_MRC__c == null)
										{
										newUsage.QTB_Term__c = ''; 
										}
                                        // GITLAB US - #28503 - if the existing usage has blng__PreratedQuantity__c or QTB_Term__c blank, set QTB_Actual_Quantity__c to 0
										if(oldUsage.blng__PreratedQuantity__c ==null || oldUsage.QTB_Term__c ==null )
										{
											newUsage.QTB_Actual_Quantity__c  = 0;
										}
                                        else {
                                            // Set QTB_Actual_Quantity__c 
                                            if ( newUsage.blng__PreratedQuantity__c != 0 && newUsage.QTB_Term__c != null && Integer.valueOf(newUsage.QTB_Term__c) != 0) 
                                            {
                                                newUsage.QTB_Actual_Quantity__c = (newUsage.blng__PreratedQuantity__c / Integer.valueOf(newUsage.QTB_Term__c)).setScale(2, System.RoundingMode.HALF_UP);
                                            }
                                         }
                                        // GITLAB US - #28503 - if the existing usage has blng__PreratedAmount__c or blng__PreratedQuantity__c blank, set QTB_Prerated_Unit_Price__c to 0
										if(oldUsage.blng__PreratedAmount__c ==null || oldUsage.blng__PreratedQuantity__c  ==null )
										{
											newUsage.QTB_Prerated_Unit_Price__c  = 0;
										}
										// GITLAB US - #28503 -> auto calculation of  QTB_Prerated_Unit_Price__c based on blng__PreratedAmount__c/ blng__PreratedQuantity__c
									/*	if(oldUsage.QTB_Prerated_Unit_Price__c == null && (oldUsage.blng__PreratedAmount__c !=null || oldUsage.blng__PreratedAmount__c !=0) && (oldUsage.blng__PreratedQuantity__c  !=null || oldUsage.blng__PreratedQuantity__c  !=0) )
										{
											newUsage.QTB_Prerated_Unit_Price__c  = (oldUsage.blng__PreratedAmount__c / oldUsage.blng__PreratedQuantity__c).setScale(6, RoundingMode.HALF_UP);
										} */
                                        // GITLAB US - #28503 -> auto calculation of  QTB_Prerated_Unit_Price__c based on blng__PreratedAmount__c/ blng__PreratedQuantity__c
                                        if(oldUsage.QTB_Prerated_Unit_Price__c == null &&  oldUsage.blng__PreratedAmount__c !=0 &&  oldUsage.blng__PreratedQuantity__c  !=0 )
										{
											newUsage.QTB_Prerated_Unit_Price__c  = (oldUsage.blng__PreratedAmount__c / oldUsage.blng__PreratedQuantity__c).setScale(6, RoundingMode.HALF_UP);
										}
                                        //SplitRebill -- Setting the Matching Attribute on Usage with combination of "OrderNumber + ORderItemNumber + blng__InvoiceGroupId__c"  
                                        if(ord.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill && orderProductIdWithOrderItemListMap.containsKey(oldUsage.blng__OrderProduct__r.Product2Id))
                                        {
                                            newUsage.blng__MatchingAttribute__c = ordItm.order.OrderNumber + ordItm.OrderItemNumber + ordItm.blng__InvoiceGroupId__c;
                                        }
                                        else{
                                            //Gitlab US#22731 --Changing the matchingAttribute value from orderNumber to OrderItemNumber for unique value
                                            newUsage.blng__MatchingAttribute__c =ordItm.OrderItemNumber; //ord.OrderNumber; 
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
            //Change Invoice ReBill Status
            blng__Invoice__c inv = new blng__Invoice__c();
            inv.id = reBillInvoiceId;
            inv.QTB_ReBill_Status__c = 'Usage In Progress';
            Update inv;
        }
        catch (Exception e) {
            System.debug('QTB_QueuableCreateCreditRebillUsages_Exception@@'+e.getLineNumber()+'-'+e.getMessage());  
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_QueuableCreateCreditRebillUsages);
        }
    }
}