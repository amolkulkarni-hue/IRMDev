/*****************************************************************************************************
* Class         : QTB_OrderProductsForRebill
* Test Class    : QTB_OrderProductsForRebill_Test
* Functionality : ReBill
* Author        : IRM/Virtusa
* Purpose       : This class handle all operation performed of Credit & Rebill Order Product Screen (LWC Comp --> QTB_OrderProductModifyRebillProcess)
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Change History: 06/30/2022
* Developer            Date           Description
* -----------------------------------------------------------------------------------------------------
* Gopi/Shailesh       06/30/2022      Initial Version - Gitlab US #9256 Credit & Rebill
* Shailesh(Virtusa)   06/26/2023      SplitRebill - Gitlab US#16246, US#16247, US#16250, US#16251, US#16253
* Parth(Virtusa)      10/16/2023      Unit Of Measure - Gitlab #18595, Gitlab #19055
* Renuka Prasad(TCS)  05/27/2023      Gitlab US#23353 - Bypass Same Invoice Group is not allowed for the same Product validation for SITAD.
*******************************************************************************************************/
public class QTB_OrderProductsForRebill {
    
    public static final String QTB_OrderProductsForRebill = 'QTB_OrderProductsForRebill';
    public static final String FUEL_SURCHARGE = 'Fuel Surcharge'; 
    public static final String Minimum_Storage_Charges = 'Minimum Storage Charges';
    public static boolean throwExplicitException = false;
    /***********************************************************************************************************
* Method      : getOrderProducts
* Parameter   : string OrderId
* Return Type : List<OrderItem>
* Author      : IRM/Virtusa
* Description : based on rebillOrderId fetching all OrderItem related with that order.
**************************************************************************************************************/    
    @AuraEnabled(cacheable = false)
    public static List<OrderItem> getOrderProducts(string OrderId,boolean isOrderScreen) {
        try{
            //based on rebillOrderId fetching all OrderItem related with that order
            //Added condition for BillingonlyCountrycheck as per story #12287
            boolean billingOnlyCountry = false;
            List<Order> ordList = new List<Order>([SELECT Id,QTB_Legal_Entity_Country__c,QTB_Rebill_Type__c FROM Order WHERE Id =: orderId]);            
            billingOnlyCountry = QTB_Billing_Countries__c.getValues(ordList[0].QTB_Legal_Entity_Country__c) != null ? true : false; 
            List<OrderItem> orderItemFinalList;            
            // SplitRebill -- added blng__InvoiceGroupId__c field in query
            // added opcs child query to fetch Unit of measure #19055
            // Added QTB_Split_Invoice_Flag__c in the query for GITLAB #18778
			//Added Order.CaseNumber and Order.Account.QTB_SITAD__c for the story #23353
			List<OrderItem> orderItemList = [SELECT Id, OrderItemNumber, OrderId, Order.OrderNumber,Order.QTB_Rebill_Type__c, Product2Id, Product2.Name, Product2.ProductCode,Order.Account.QTB_SITAD__c,
                                             Product2.QTB_Storage_Product__c,ServiceDate, EndDate, Quantity, UnitPrice,ListPrice, QTB_Final_Unit_Price__c, SBQQ__Status__c,
                                             blng__InvoiceGroupId__c,QTB_Split_Invoice_Flag__c,Order.QTB_Case_Number__c,QTB_Case_Number__c,
                                             (select SBQQ__UnitOfMeasure__c from sbqq__OrderItems__r)
                                             FROM OrderItem 
                                             WHERE OrderId = : OrderId 
                                             order by OrderItemNumber asc /*blng__InvoiceGroupId__c asc*/]; 
            //Order Product Screen -- where all order product are displaying
            if(isOrderScreen)
            {
                // Added as Part of 12959 to display Minimum storage charges after confirm button for Billing countries                
                if(!billingOnlyCountry){
                    //SplitRebill -- return all product to display
                    if(ordList[0].QTB_Rebill_Type__c == System.Label.QTB_SplitRebill){
                        return orderItemList; 
                    }
                    else{//For Regular Credit & Rebill
                        orderItemFinalList = new List<OrderItem>();
                        for(OrderItem ordItm : orderItemList){
                            //excluding the defaults product to display (Minimum Storage Charges, Minimum Invoice Charges, Fuel Surcharge)
                            if(!(ordItm.Product2.ProductCode == LABEL.QTB_Minimum_Storage ||
                                 ordItm.Product2.ProductCode == LABEL.QTB_Invoice_Minimum ||
                                 ordItm.Product2.Name == FUEL_SURCHARGE)) //due to duplicate fuel surcharge using the name check instead of productcode check
                            {
                                orderItemFinalList.add(ordItm);
                            }
                        }
                        return orderItemFinalList;
                    }
                }
                // Added as Part of 12959 to display default products (Minimum storage charges,Fuel Surcharge, Minimum Invoice Charges) after confirm button for Billing countries
                else{
                    return orderItemList; 
                }
            }
            else //On Usage Screen -- "Add Usage" button showing order products using below logic
            {   
                //Defect Fix Gitlab US#20327 -- To restrict Bundle Header Order Product to display on click of Add Usage button on Usage Screen
                Set<Id> productIdSet = new Set<Id>();
                Set<Id> bundleProductIdsSet = new Set<Id>();
                Set<OrderItem> orderItemSet = new Set<OrderItem>();
                for(OrderItem ordItem : orderItemList){
                    productIdSet.add(ordItem.Product2Id);
                    orderItemSet.add(ordItem);
                }
                //fetching product data from SBQQ__ProductOption__c object to identify bundle header products
                for(SBQQ__ProductOption__c prdOpt :[SELECT Id,Name,SBQQ__ConfiguredSKU__r.Name, SBQQ__OptionalSKU__r.Name  
                                                    FROM SBQQ__ProductOption__c 
                                                    WHERE SBQQ__ConfiguredSKU__c IN : productIdSet])
                {
                    //add bundle products in bundleProductIdsSet, bundle product identified using SBQQ__ConfiguredSKU__c field value
                    bundleProductIdsSet.add(prdOpt.SBQQ__ConfiguredSKU__c);
                } 
               
                productIdSet.clear();
                for(orderItem ordItm : orderItemList){
                    //Checking if any orderItem having bundle header product
                    if(!bundleProductIdsSet.isEmpty() && bundleProductIdsSet.contains(ordItm.Product2Id)){
                        orderItemSet.remove(ordItm);  //remove Bundle header order products
                    }
                }
                
                bundleProductIdsSet.clear();
                orderItemFinalList = new List<OrderItem>();
                orderItemFinalList.addAll(orderItemSet); //adding all orderItem from orderItemSet to orderItemFinalList 
                
                //for billing only countries -- display all products (excluding bundle Header products)
                if(billingOnlyCountry){                   
                    return orderItemFinalList; 
                }
                else{
                    //SplitRebill -- return all product to display  (excluding bundle Header products)
                    if(ordList[0].QTB_Rebill_Type__c == System.Label.QTB_SplitRebill){
                        return orderItemFinalList; 
                    }
                    else{ //For Regular Credit & Rebill -- exclude default products(Minimum Storage Charges, Minimum Invoice Charges, Fuel Surcharge) & Bundle Header products
                        //and display all remaining products
                        orderItemFinalList = new List<OrderItem>();
                        for(OrderItem ordItm : orderItemList){
                            if(ordItm.Product2.ProductCode == LABEL.QTB_Minimum_Storage ||
                               ordItm.Product2.ProductCode == LABEL.QTB_Invoice_Minimum ||
                               ordItm.Product2.Name == FUEL_SURCHARGE) //due to duplicate fuel surcharge using the name check instead of productcode check
                            {
                                orderItemSet.remove(ordItm);
                            }
                        }
                        orderItemFinalList.addAll(orderItemSet);
                        orderItemSet.clear(); //clearing the data from set
                        return orderItemFinalList;
                    }
                }
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);
            return null;
        }
    }
    
    
    /***********************************************************************************************************
* Method      : updateOrderProductList
* Parameter   : List<OrderItem> orderProductlist
* Return Type : List<OrderItem>
* Author      : IRM/Virtusa
* Description : this method is responsible to update the orderProducts, 
return the updated orderProducts to LWC Comp Order Screen of Credit & Rebill
**************************************************************************************************************/ 
    @AuraEnabled
    public static String updateOrderProductList(List<OrderItem> orderProductlist){
        String result ='';
        Integer count = 0;
        try {
            System.debug('updateOrderProductList@@'+orderProductlist);              
            Map<Id,String> orderPrdIdWithOrderPrdInvoiceGroupMap = new Map<Id,String>();
            Map<Id,OrderItem> allOrderProductIdWithOrderProductMap = new Map<Id,OrderItem>();
            Id orderId;
            boolean isForSameProductSameInvoiceGroup = false;
            Map<Id,blng__Usage__c> usageMap = new Map<Id,blng__Usage__c> () ;
            List<blng__UsageSummary__c> usgSummaryListFinal = new List<blng__UsageSummary__c>();
            List<SBQQ__OrderItemConsumptionSchedule__c> orderPrdCSList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            Map<Id,String> orderPrdIdWithInvoiceGroupMap = new Map<Id,String>();
            //SplitRebill 
            for(OrderItem ordItem : orderProductlist){
                //SplitRebill -- checking blng__InvoiceGroupId__c
                if(ordItem.blng__InvoiceGroupId__c != null){
                    orderPrdIdWithInvoiceGroupMap.put(ordItem.Id,ordItem.blng__InvoiceGroupId__c);
                    orderPrdIdWithOrderPrdInvoiceGroupMap.put(ordItem.Id, ordItem.blng__InvoiceGroupId__c );  
                }
            } 
            
            //SplitRebill -- fetching the usageSummary of split rebill type
            for(blng__UsageSummary__c UsageSummVar: [ SELECT Id,blng__MatchingId__c,blng__MatchingAttribute__c,blng__OrderProduct__c,blng__OrderProduct__r.OrderItemNumber,blng__OrderProduct__r.Order.OrderNumber,
                                                     blng__OrderProduct__r.blng__InvoiceGroupId__c,blng__OrderProduct__r.OrderId, blng__OrderProduct__r.Order.QTB_Rebill_Type__c,
                                                     blng__InvoiceRunProcessingStatus__c,blng__InvoiceRunStatusIndex__c
                                                     FROM blng__UsageSummary__c
                                                     WHERE blng__OrderProduct__c IN : orderProductlist 
                                                     AND blng__OrderProduct__r.Order.QTB_Rebill_Type__c =: System.Label.QTB_SplitRebill])
            {
                //SplitRebill -- base on Split Rebill Type, updating the Matching Attribute of Usage Summary
                orderId = UsageSummVar.blng__OrderProduct__r.OrderId;
                if(!orderPrdIdWithOrderPrdInvoiceGroupMap.isEmpty() && orderPrdIdWithOrderPrdInvoiceGroupMap.containsKey(UsageSummVar.blng__OrderProduct__c))
                {
                    blng__UsageSummary__c usgSumm = new blng__UsageSummary__c();
                    usgSumm.Id = UsageSummVar.Id;
                    //MatchingAttribute = OrderNumber+ OrderItemNumber+InvoiceGroupId
                    usgSumm.blng__MatchingAttribute__c = UsageSummVar.blng__OrderProduct__r.Order.OrderNumber +UsageSummVar.blng__OrderProduct__r.OrderItemNumber + 
                        orderPrdIdWithOrderPrdInvoiceGroupMap.get(UsageSummVar.blng__OrderProduct__c);
                    if(UsageSummVar.blng__InvoiceRunProcessingStatus__c == 'Will Not Invoice'){
                        usgSumm.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
                        usgSumm.blng__InvoiceRunStatusIndex__c = 'Pending Billing';
                    }
                    usgSummaryListFinal.add(usgSumm);
                }
            }
            
            if(!orderPrdIdWithInvoiceGroupMap.isEmpty()){
                for (SBQQ__OrderItemConsumptionSchedule__c ordPdtCS : [ SELECT id,Name,SBQQ__OrderItem__c,SBQQ__OrderItem__r.OrderItemNumber,SBQQ__OrderItem__r.blng__InvoiceGroupId__c,
                                                                       SBQQ__OrderItem__r.Order.QTB_Rebill_Type__c,SBQQ__OrderItem__r.QTB_PrefixMatchingID__c
                                                                       FROM SBQQ__OrderItemConsumptionSchedule__c                                                                   
                                                                       WHERE SBQQ__OrderItem__c IN :orderPrdIdWithInvoiceGroupMap.keySet() and SBQQ__OrderItem__r.SBQQ__Status__c = 'Draft']) 
                { 
                    SBQQ__OrderItemConsumptionSchedule__c ordPdtCSVar = new SBQQ__OrderItemConsumptionSchedule__c();
                    ordPdtCSVar.Id = ordPdtCS.Id;
                    ordPdtCSVar.SBQQ__MatchingAttribute__c = ordPdtCS.SBQQ__OrderItem__r.QTB_PrefixMatchingID__c + ordPdtCS.SBQQ__OrderItem__r.OrderItemNumber + orderPrdIdWithInvoiceGroupMap.get(ordPdtCS.SBQQ__OrderItem__c);
                    orderPrdCSList.add(ordPdtCSVar);
                }
            }            
            
            //SplitRebill -- fetching all existing orderProducts based on orderId
            if(orderId != null){
                for(OrderItem OrdItem : [SELECT Id, OrderId, blng__InvoiceGroupId__c, Product2Id, Order.Account.QTB_SITAD__c
                                         FROM OrderItem WHERE OrderId =: orderId])
                {
                    allOrderProductIdWithOrderProductMap.put(OrdItem.Id,OrdItem); 
                }
            }
            
            
            //Fetching usages based on orderproducts
            for(blng__Usage__c usage : [SELECT Id,blng__OrderProduct__c 
                                        FROM blng__Usage__c
                                        WHERE blng__OrderProduct__c IN :orderProductlist])
            {
                usageMap.put(usage.blng__OrderProduct__c,usage);
            }
            
            //SplitRebill 
            for(OrderItem OrdItem : orderProductlist )
            {   
                //SplitRebill -- Iterating on all existing orderProducts'
                if(!allOrderProductIdWithOrderProductMap.isEmpty()){
                    for(OrderItem OrdItemAll :allOrderProductIdWithOrderProductMap.values())
                    {
                        //SplitRebill -- Verifying selected orderProduct InvoiceGroup and Product is same with existing OrderProduct InvoiceGroup & Product
                        //Last condition added for SITAD to Bypass Split Rebill the validation of Same Product, Same Invoice Group. Story #23353
						if(OrdItem.blng__InvoiceGroupId__c != null && 
                           OrdItem.blng__InvoiceGroupId__c == OrdItemAll.blng__InvoiceGroupId__c && 
                           allOrderProductIdWithOrderProductMap.containsKey(OrdItem.Id) &&
                           OrdItem.Id != OrdItemAll.Id &&
                           allOrderProductIdWithOrderProductMap.get(OrdItem.Id).Product2Id == OrdItemAll.Product2Id &&
						   !allOrderProductIdWithOrderProductMap.get(OrdItem.Id).Order.Account.QTB_SITAD__c)
						{
						    isForSameProductSameInvoiceGroup = true;
                            break;
                        }
                    } 
                }
                
                //SplitRebill -- Not allowing to update order product if invoiceGroup is same added 
                if(isForSameProductSameInvoiceGroup){
                    return System.Label.QTB_SplitRebill_SameProductInvoiceGroupErrorMsg;
                }     
                
                //SplitRebill -- Validating the Invoice Group format, if its other than "Split-", then throwing validation message 
                if(OrdItem.blng__InvoiceGroupId__c !=null){
                    if(OrdItem.blng__InvoiceGroupId__c.contains('Split-')){
                        string afterSplitValue = (OrdItem.blng__InvoiceGroupId__c).substringAfter('-');
                        Integer numberFormatValue = Integer.valueOf(afterSplitValue);
                    }
                    else{
                        return System.Label.QTB_SplitRebillInvoiceGroupFormatValidation;
                    }
                }
                
                // Condition as per user story- #10547 to check and does not allow for Order Product Pricing Changes if Usage is already created
                if(!orderProductlist.isEmpty() && orderProductlist.size() > 0 && usageMap.get(OrdItem.id) == null )
                {
                    // no logic required in if condition 
                }
                else{
                    count = count+1;
                }
            }
            
            //if count is greater than 0, means order product is having existing usags, so not allowing to update that order product
            if(count>0){
                return  'Something went wrong OR Order Product is already having usage created!';
            }
            else
            {
                update orderProductlist;
                
                if(!orderPrdCSList.isEmpty()){
                    update orderPrdCSList;
                }
                
                if(!usgSummaryListFinal.isEmpty() && usgSummaryListFinal.size() > 0){
                    update usgSummaryListFinal;
                }
                return 'Success';
            }
        } catch(Exception e) {
            if(e.getMessage().contains('Invalid integer')){
                return System.Label.QTB_SplitRebillInvoiceGroupFormatValidation;
            }
            else if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                result = e.getMessage().substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
            }
            else if(e.getMessage().contains('FIELD_INTEGRITY_EXCEPTION')){
                result = e.getMessage().substringAfter('FIELD_INTEGRITY_EXCEPTION,');
            }
            else{
                result = 'Error'; 
            }
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);            
            return result;
        }
    }    
    
    /***********************************************************************************************************
* Method      : deleteSelectedOrderProducts
* Parameter   : List<OrderItem> orderProductlist
* Return Type : boolean
* Author      : IRM/Virtusa
* Description : this method is responsible to delete the selected orderProducts,
return the true if successfully deleted else false to LWC Comp - "Order Product Screen" of Credit & Rebill Process
**************************************************************************************************************/ 
    @AuraEnabled
    public static String deleteSelectedOrderProducts(List<OrderItem> orderProductlist) {
        try{
            if(orderProductlist !=null && !orderProductlist.isEmpty() && orderProductlist.size() > 0 )
            {
                System.debug('deleteSelectedOrderProducts@@');
                List<blng__Usage__c> usgList = [SELECT Id,blng__UsageSummary__c FROM blng__Usage__c WHERE blng__OrderProduct__c IN: orderProductlist ];
                List<blng__UsageSummary__c> usgSummary = [SELECT Id,blng__MatchingAttribute__c FROM blng__UsageSummary__c WHERE blng__OrderProduct__c IN: orderProductlist];
                //defect fix Gitlab US#19900 -- for bulk usage deletion calling the batch class
                //Note -- logic is pending to check is order product - usages deletion done or not from batch
                Set<Id> orderProdIdSet = new Set<Id>();
                for(OrderItem ordItm : orderProductlist){
                    orderProdIdSet.add(ordItm.Id);
                }
                //if usages count is more than 500, then for deletion redirecting to batch class
                if(!usgList.isEmpty() && usgList.size() > Integer.valueOf(System.label.QTB_CreditRebillUsageBatchSize) ){
                    QTB_CreditRebillUsagesDeleteBatch usgDeletionBatch = new QTB_CreditRebillUsagesDeleteBatch(orderProdIdSet);
                    Id batchJobId = database.executeBatch(usgDeletionBatch, Integer.valueOf(System.label.QTB_CreditRebillUsageBatchSize));
                    return batchJobId;
                }
                else{
                    //Defect fix #22116 -- switching off blng pkg trigger before deleting
                    SBQQ.TriggerControl.disable();
                    //delete usages
                    if(!usgList.isEmpty() && usgList.size() > 0){
                        // delete usgList; 
                        Database.delete(usgList, AccessLevel.SYSTEM_MODE);
                    }
                    SBQQ.TriggerControl.enable();
                    
                    SBQQ.TriggerControl.disable();
                    //delete usage summary
                    if(!usgSummary.isEmpty() && usgSummary.size() > 0){
                        //delete usgSummary;
                        Database.delete(usgSummary, AccessLevel.SYSTEM_MODE);
                    }
                    SBQQ.TriggerControl.enable();
                    
                    SBQQ.TriggerControl.disable();
                    //deleting order product
                    if(orderProductlist !=null &&  !orderProductlist.isEmpty()){
                        //delete orderProductlist;
                        Database.delete(orderProductlist, AccessLevel.SYSTEM_MODE);
                    }                    
                    SBQQ.TriggerControl.enable();
                    return 'true';
                }
            }
            else{
                return 'false';
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);
            return 'false';
        }
    }
    
    /***********************************************************************************************************
* Method      : getProducts
* Parameter   : Id orderId,Id sourceInvoiceId
* Return Type : List<Product2>
* Author      : IRM/Virtusa
* Description : this method is responsible to show the Products based that existing Order Pricebook,
return the list of products to LWC Comp - Product Selection Screen of Credit & Rebill Process
* Passing sourceInvoiceId to fetch originalOrderProduct related details when all rebill order products are not present(all order products deleted)
**************************************************************************************************************/     
    @AuraEnabled(cacheable = false)
    public static List<Product2> getProducts(Id orderId,Id sourceInvoiceId) {
        try{
            System.debug('getProducts_orderId@@'+orderId);
            System.debug('getProducts_sourceInvoiceId@@'+sourceInvoiceId);
            Id originalOrderId ;
            string priceBookId;
            List<id> existingProduct = new List<id>();            
            Set<id> showProductIds = new Set<id>();
            Set<Id> bundleProductIds = new Set<Id>();
            Set<Id> defaultMinimumProducts = new Set<Id>();
            string currencyCode;            
            string country;//Added as per 13608 for new Pricebook Structure
            boolean billingOnlyCountry = false;
            String OrdBillingCountry = '';
            Set<String> oracleProductCodeSet = new Set<String>();
            boolean isApplyMinimumStorageCharge = false;
            boolean isApplyMinimumInvoiceCharge = false;
            Set<Id> subscriptionRevenueProductIdSet = new Set<Id>();
            //Fetching Parent Product from SBQQ__ProductOption__c where the RevenueAllocation greater than 0
            for(SBQQ__ProductOption__c prdOption : [SELECT Id,SBQQ__ConfiguredSKU__c, SBQQ__ConfiguredSKU__r.Name,SBQQ__OptionalSKU__c,SBQQ__OptionalSKU__r.Name,SBQQ__OptionalSKU__r.ProductCode, QTB_Revenue_Allocation__c  
                                                    FROM SBQQ__ProductOption__c
                                                    WHERE QTB_Revenue_Allocation__c > 0])
            {
                subscriptionRevenueProductIdSet.add(prdOption.SBQQ__OptionalSKU__c);
            }
            
            //queries extra fields as per 13608 for new Pricebook Structure            
            List<OrderItem> orderItemList = [SELECT id,PricebookEntry.Pricebook2id,Product2Id,CurrencyIsoCode,Product2.IM_Product_Class__c,
                                             Order.QTB_Legal_Entity_Country__c,PricebookEntry.Pricebook2.QTB_Country__c,Product2.QTB_Oracle_Product_Code__c,Order.AccountId,
                                             PricebookEntry.Pricebook2.IsActive,Order.Account.QTB_Apply_Minimum_Storage_Charges__c,Order.Account.QTB_Apply_Invoice_Minimum_Charges__c,QTB_Case_Number__c
                                             FROM orderItem   
                                             WHERE OrderId=: orderId];
            //Checking rebill OrderItem empty or not 
            if(!orderItemList.isEmpty())
            { 
                isApplyMinimumStorageCharge = orderItemList[0].Order.Account.QTB_Apply_Minimum_Storage_Charges__c;
                isApplyMinimumInvoiceCharge = orderItemList[0].Order.Account.QTB_Apply_Invoice_Minimum_Charges__c;
                currencyCode = orderItemList[0].CurrencyIsoCode;    
                country = orderItemList[0].PricebookEntry.Pricebook2.QTB_Country__c;//Added as per 13608 for new Pricebook Structure
                priceBookId = orderItemList[0].PricebookEntry.Pricebook2id;  
                system.debug('priceBookId@@' +priceBookId); 
                
                //Iterate all the Order Product and keep the Product Id and PriceBook Id
                for(orderItem ordItem : orderItemList)
                { 
                    existingProduct.add(ordItem.Product2Id); //store all existing order product's product
                    system.debug('existingProduct@@' +existingProduct); 
                    oracleProductCodeSet.add(ordItem.Product2.QTB_Oracle_Product_Code__c);
                } 
            }
            else
            {   //if there is no rebill order product exist then fetching invoice line based on sourceInvoice to get originalOrderId
                for(blng__InvoiceLine__c invLine : [SELECT Id, blng__OrderProduct__c, blng__OrderProduct__r.OrderId
                                                    FROM blng__InvoiceLine__c
                                                    WHERE blng__Invoice__c =:sourceInvoiceId LIMIT 1])
                { 
                    originalOrderId = invLine.blng__OrderProduct__r.OrderId; //Setting the originalOrderId from source invoice refernce
                }
                
                if(originalOrderId != null)
                {
                    //Based on orginalOrderId fetching orginal order products to get priceBookId,CurrencyISOCode,Country 
                    for(orderItem ordItem : [Select id,PricebookEntry.Pricebook2id,Product2Id,CurrencyIsoCode,Product2.IM_Product_Class__c,
                                             Order.QTB_Legal_Entity_Country__c,PricebookEntry.Pricebook2.QTB_Country__c,Product2.QTB_Oracle_Product_Code__c,Order.AccountId,
                                             PricebookEntry.Pricebook2.IsActive,Order.Account.QTB_Apply_Minimum_Storage_Charges__c,Order.Account.QTB_Apply_Invoice_Minimum_Charges__c
                                             FROM orderItem   
                                             WHERE OrderId=: originalOrderId LIMIT 1])
                    { 
                        isApplyMinimumStorageCharge = ordItem.Order.Account.QTB_Apply_Minimum_Storage_Charges__c;
                        isApplyMinimumInvoiceCharge = ordItem.Order.Account.QTB_Apply_Invoice_Minimum_Charges__c;
                        priceBookId = ordItem.PricebookEntry.Pricebook2id;  
                        system.debug('priceBookId@@' +priceBookId);                            
                        currencyCode = ordItem.CurrencyIsoCode;                       
                        country = ordItem.PricebookEntry.Pricebook2.QTB_Country__c; //Added as per 13608 for new Pricebook Structure
                        oracleProductCodeSet.add(ordItem.Product2.QTB_Oracle_Product_Code__c);
                    }
                }
            }
            
            //Fetching Rebill Order details based on rebillOrderId
            List<Order> Ords = new List<Order>([SELECT Id,QTB_Legal_Entity_Country__c,QTB_Rebill_Type__c 
                                                FROM Order
                                                WHERE id =:orderId]);
            
            OrdBillingCountry = Ords[0].QTB_Legal_Entity_Country__c;
            billingOnlyCountry = QTB_Billing_Countries__c.getValues(OrdBillingCountry) != null ?true : false; 
            //Other than billing only countries
            if(!billingOnlyCountry)
            {   
                system.debug('Inside_If@@');
                // Added Pricebook2.IsActive = TRUE AND IsActive = true condition for #15735, CurrencyIsoCode is already avaliable.
                //SplitRebill -- commenting conditions from query and handling through if....else conditions to make this logic work for both Regular & Split Credit&Rebill
                for(PricebookEntry pbe : [SELECT id, Product2Id,Pricebook2.QTB_Country__c,Product2.IsActive,CurrencyISOCode,Product2.ProductCode,
                                          Product2.Name,Product2.QTB_Oracle_Product_Code__c,Pricebook2.IsActive,IsActive 
                                          FROM PricebookEntry 
                                          WHERE Pricebook2id =: priceBookId AND Pricebook2.IsActive = TRUE AND IsActive = TRUE 
                                          AND CurrencyISOCode =:currencyCode AND Product2.IsActive = TRUE AND Product2Id NOT IN : subscriptionRevenueProductIdSet
                                          /*AND Product2Id NOT IN: existingProduct */ 
                                          /*AND (Product2.ProductCode !=: Label.QTB_Minimum_Storage AND Product2.ProductCode !=: LABEL.QTB_Invoice_Minimum AND Product2.ProductCode !=:LABEL.QTB_Fuel_Surcharge)*/])
                {
                    //Showing Minimum Storage Charges & Minimum Invoice Charges only when on Billing Account Level Apply Minimum Storage & Apply Minimum Invoice charges are true
                    if(pbe.Product2.ProductCode == Label.QTB_Minimum_Storage ||  pbe.Product2.ProductCode == LABEL.QTB_Invoice_Minimum )
                    {
                        if(!Ords.isEmpty() && Ords[0].QTB_Rebill_Type__c == System.Label.QTB_SplitRebill && isApplyMinimumStorageCharge &&
                           pbe.Product2.ProductCode == Label.QTB_Minimum_Storage )
                        {
                            defaultMinimumProducts.add(pbe.Product2Id);// storing minimum storage charge productIds
                        }
                        else if(!Ords.isEmpty() && Ords[0].QTB_Rebill_Type__c == System.Label.QTB_SplitRebill && isApplyMinimumInvoiceCharge &&
                                pbe.Product2.ProductCode == LABEL.QTB_Invoice_Minimum)
                        {
                            defaultMinimumProducts.add(pbe.Product2Id);// storing minimum invoice charge productIds
                        } 
                    }                    
                    else if(pbe.Product2.Name.equalsIgnoreCase(FUEL_SURCHARGE)){
                        if(!oracleProductCodeSet.isEmpty() && oracleProductCodeSet.contains(pbe.Product2.QTB_Oracle_Product_Code__c)){
                            defaultMinimumProducts.add(pbe.Product2Id); //storing Fuel Surcharge product based on existing order product's oracle product code
                        }
                    }                    
                    else{
                        showProductIds.add(pbe.Product2Id);  //store all products other than default minimums products
                    }
                }           
            }
            else  //billing only countries
            {
                system.debug('Inside_Else@@');
                //Chnaged as per 13608 for new Pricebook Structure
                //SplitRebill -- removing condition from query and handle through if...else condition to make this logic work for both Regular & Split Credit&Rebill scenario
                for(PricebookEntry pbe :  [SELECT id, Product2Id,Pricebook2.QTB_Country__c,Product2.IsActive,CurrencyISOCode,Product2.ProductCode,
                                           Product2.Name,Product2.QTB_Oracle_Product_Code__c,Pricebook2.IsActive,IsActive 
                                           FROM PricebookEntry 
                                           WHERE Pricebook2.QTB_Country__c = :country AND Pricebook2.IsActive = TRUE AND IsActive = TRUE /*AND Product2Id NOT IN: existingProduct*/
                                           AND CurrencyISOCode =:currencyCode AND Product2.IsActive = TRUE AND Product2Id NOT IN : subscriptionRevenueProductIdSet])
                {        
                    //Showing Minimum Storage Charges & Minimum Invoice Charges only when on Billing Account Level Apply Minimum Storage & Apply Minimum Invoice charges are true
                    if(pbe.Product2.ProductCode == Label.QTB_Minimum_Storage ||  pbe.Product2.ProductCode == LABEL.QTB_Invoice_Minimum )
                    {   
                        if(!Ords.isEmpty() && Ords[0].QTB_Rebill_Type__c == System.Label.QTB_SplitRebill /*&&  isApplyMinimumStorageCharge*/ &&
                           pbe.Product2.ProductCode == Label.QTB_Minimum_Storage )
                        {
                            defaultMinimumProducts.add(pbe.Product2Id);// storing minimum storage charge productIds
                        }
                        else if(!Ords.isEmpty() && Ords[0].QTB_Rebill_Type__c == System.Label.QTB_SplitRebill /* && isApplyMinimumInvoiceCharge */ && pbe.Product2.ProductCode == LABEL.QTB_Invoice_Minimum)
                        {
                            defaultMinimumProducts.add(pbe.Product2Id);// storing minimum invoice charge productIds
                        }
                    }
                    else if(pbe.Product2.Name.equalsIgnoreCase(FUEL_SURCHARGE)){
                        if(oracleProductCodeSet.contains(pbe.Product2.QTB_Oracle_Product_Code__c)){
                            defaultMinimumProducts.add(pbe.Product2Id); //storing Fuel Surcharge product based on existing order product's oracle product code
                        }
                    }
                    else{
                        showProductIds.add(pbe.Product2Id);  //store all products other than Fuel Surcharge products
                    }  
                }
            }            
            showProductIds.addAll(defaultMinimumProducts);
            if(!Ords.isEmpty() && Ords[0].QTB_Rebill_Type__c == 'Regular'){
                showProductIds.removeAll(existingProduct); //// show only "not added" product for Regular rebill  
                if(!billingOnlyCountry){
                    showProductIds.removeAll(defaultMinimumProducts);
                }
            }
            //Need to check How to identify Parent Product
            if(!showProductIds.isEmpty() && showProductIds != null && showProductIds.size() > 0){                
                //fetching product data from SBQQ__ProductOption__c object to identify bundle header & child products.
                for(SBQQ__ProductOption__c prdOpt :[SELECT Id,Name,SBQQ__ConfiguredSKU__r.Name, SBQQ__OptionalSKU__r.Name  
                                                    FROM SBQQ__ProductOption__c 
                                                    WHERE SBQQ__ConfiguredSKU__c IN : showProductIds])
                {
                    //adding parent products, as in ProductOption bundle product is stored in SBQQ__ConfiguredSKU__c field.
                    bundleProductIds.add(prdOpt.SBQQ__ConfiguredSKU__c);
                } 
                System.debug('bundleProductIds@@'+bundleProductIds);
                System.debug('bundleProductIds.size()@@'+bundleProductIds.size());
            }
            
            if(!bundleProductIds.isEmpty() && bundleProductIds.size() > 0){
                boolean isRemoved = showProductIds.removeAll(bundleProductIds);
                System.debug('showProductIds_AfterRemovedBundleProduct@@'+showProductIds.size());
            }
            
            if(!showProductIds.isEmpty() && showProductIds.size() > 0){
                    return [SELECT id, Name, ProductCode, IM_Product_Line__c, IM_Product_Class__c, RecordType.Name, QTB_Storage_Product__c 
                    FROM Product2 
                        WHERE id IN : showProductIds and RecordTypeId !=null AND isActive = true ]; //filtering all child products
            }else{
                return null;
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);
            return null;
        }
    }
    
    /***********************************************************************************************************
* Method      : createRetrunOrderProducts
* Parameter   : List<Product2> productList, Id orderId
* Return Type : List<OrderItem> 
* Author      : IRM/Virtusa
* Description : this method is responsible to create order products for selected products,
return the list of newly created order products to LWC Comp - Order Product Screen of Credit & Rebill Process
**************************************************************************************************************/  
    @AuraEnabled
    public static List<OrderItem> createRetrunOrderProducts(List<Product2> productList, Id orderId, Id sourceInvoiceId){
        try {            
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            system.debug('createRetrunOrderProducts_productList@@@@@@' +productList);
            system.debug('orderId@@@@@@' +orderId);
            system.debug('sourceInvoiceId@@@@@@' +sourceInvoiceId);
            List<OrderItem> OrderItemlst = new List<OrderItem>(); 
            Map<string,string> productIdProductNameMap = new Map<string,string>();
            Map<Id,List<Id>> csIdWithPrdIdListMap = new Map<Id,List<Id>>(); //Gitlab US#19381            
            Map<Id,Id> productIdWithCSIdMap = new Map<Id,Id>();
            Map<Id, Decimal> CSIdWithCSRateMap = new Map<Id,Decimal>();
            Map<Id, List<ConsumptionRate>> CSIdWithCSRateListMap = new Map<Id,List<ConsumptionRate>>();
            Map<Id,Id> billingRuleIdWithBillingTreatmentIdMap = new Map<Id,Id>();
            Set<Id> billingRuleIds = new Set<Id>();
            List<Id> billingTreatmentId = new List<Id>();
            String rebillOrderNumber;
            Date StartDate;
            Date EndDate;
            List<Product2> productBillingRuleList = [SELECT id, blng__BillingRule__c 
                                                     FROM Product2
                                                     WHERE ID IN :productList];
            
            //Gitlab US#19381 -- Added Null check
            if(productList != null && !productList.isEmpty())
            {
                for(Product2 pr : [SELECT id, blng__BillingRule__c 
                                   FROM Product2
                                   WHERE ID IN :productList])
                {
                    //storing product related billingRuleIds
                    billingRuleIds.add(pr.blng__BillingRule__c);
                }
            }            
            
            //Fetching BillingRule
            List<blng__BillingRule__c> noInvoiceBillingRuleList = [SELECT Id 
                                                                   FROM blng__BillingRule__c 
                                                                   WHERE NAME = 'No Invoice Rule' limit 1];
            //Gitlab US#19381 -- Added Null check
            if(!billingRuleIds.isEmpty()){
                for(blng__BillingTreatment__c bt : [SELECT id, name,blng__BillingRule__c
                                                    FROM blng__BillingTreatment__c 
                                                    WHERE blng__BillingRule__c  IN :billingRuleIds])
                {   
                    //Map of billingRuleId with BillingTreatmentId
                    billingRuleIdWithBillingTreatmentIdMap.put(bt.blng__BillingRule__c,bt.Id);
                    if(!noInvoiceBillingRuleList.isEmpty() && bt.blng__BillingRule__c == noInvoiceBillingRuleList[0].Id ){
                        billingTreatmentId.add(bt.id);
                    }
                } 
            }

            //fetching OrderItem to get the Order,Pricebook, StartDate & EndDate (bcoz its captured from InvoiceStartDate, InvoiceEndDate while cloning orderItem for Credit & Rebill process)
            //Queried extra fields as per 13076            
            List<OrderItem> OrderItemExisting = [SELECT OrderItemNumber, ServiceDate,EndDate,Order.OrderNumber,Order.QTB_Rebill_Type__c, Order.QTB_Legal_Entity_Country__c,Order.EffectiveDate,Order.EndDate,
                                                 Order.Account.QTB_Contract_Entity__c,Order.CurrencyISOCode,PricebookEntry.Pricebook2id,Product2Id,PricebookEntry.Pricebook2.QTB_Country__c,PricebookEntry.Pricebook2.IsActive,PricebookEntry.Pricebook2.CurrencyIsoCode,blng__TaxCountry__c,blng__TaxRule__c
                                                 FROM OrderItem 
                                                 WHERE orderId =:orderId order by OrderItemNumber asc limit 1]; 
            if(!OrderItemExisting.isEmpty()){
                StartDate = OrderItemExisting[0].ServiceDate; //Setting the StartDate based on rebillOrderItem starteDate
                EndDate = OrderItemExisting[0].EndDate; //Setting the EndDate based on rebillOrderItem EndDate
            }
            else{
                Id originalOrderId;
                //if there is no rebill order product exist then fetching from source invoice refernce
                for(blng__InvoiceLine__c invLine : [SELECT Id, blng__OrderProduct__c, blng__OrderProduct__r.OrderId,blng__StartDate__c,blng__EndDate__c
                                                    FROM blng__InvoiceLine__c
                                                    WHERE blng__Invoice__c =:sourceInvoiceId LIMIT 1])
                { 
                    originalOrderId = invLine.blng__OrderProduct__r.OrderId; //Setting the originalOrderId from source invoice refernce
                    StartDate = invLine.blng__StartDate__c; //Setting the startDate from InvoiceLine
                    EndDate = invLine.blng__EndDate__c;  //Setting the EndDate from InvoiceLine
                }
                
                if(originalOrderId != null)
                {
                    //Fetching the original orderItem from originalOrder to get the pricebook, legalEntityCountry and other details
                    OrderItemExisting = [SELECT OrderItemNumber, ServiceDate,EndDate,Order.OrderNumber,Order.QTB_Rebill_Type__c, Order.QTB_Legal_Entity_Country__c,Order.EffectiveDate,Order.EndDate,
                                         Order.Account.QTB_Contract_Entity__c,Order.CurrencyISOCode,PricebookEntry.Pricebook2id,Product2Id,PricebookEntry.Pricebook2.QTB_Country__c,PricebookEntry.Pricebook2.IsActive,PricebookEntry.Pricebook2.CurrencyIsoCode,blng__TaxCountry__c,blng__TaxRule__c
                                         FROM OrderItem  
                                         WHERE OrderId=: originalOrderId LIMIT 1];
                }
            }
            List<Order> rebillOrder = [Select Id, OrderNumber,QTB_Rebill_Type__c From Order where Id = : orderId];
            rebillOrderNumber = rebillOrder[0].OrderNumber;            
            
            //Gitlab US#19381 -- Defect fix - logic modified from the loop
            //based on productIds fetching ProductConsumptionSchedule records
            //iterating on list of ProductConsumptionSchedules
            for(ProductConsumptionSchedule pcs : [SELECT Id,ProductId,Product.Name,ConsumptionScheduleId,ConsumptionSchedule.Name
                                                  FROM ProductConsumptionSchedule 
                                                  WHERE ProductId IN : productList])
            {
                if(csIdWithPrdIdListMap.containsKey(pcs.ConsumptionScheduleId)){
                    csIdWithPrdIdListMap.get(pcs.ConsumptionScheduleId).add(pcs.ProductId);
                }else{
                    csIdWithPrdIdListMap.put(pcs.ConsumptionScheduleId,new List<Id>{pcs.ProductId}); //Gitlab US#19381
                }
            }            
            System.debug('csIdWithPrdIdListMap@@'+csIdWithPrdIdListMap);
            //Gitlab US#19381
            //fetching ConsumptionRate based on consumptionScheduleIds & with respective currency            
            for(ConsumptionRate csRate : [SELECT Id,Name,LowerBound,UpperBound,Price,ConsumptionScheduleId,ConsumptionSchedule.Name
                                          From ConsumptionRate
                                          Where ConsumptionScheduleId IN : csIdWithPrdIdListMap.keySet()  //Gitlab US#19381
                                          AND CurrencyISOCode =: OrderItemExisting[0].Order.CurrencyISOCode Order by ConsumptionScheduleId])
            {      
                if(CSIdWithCSRateListMap.containsKey(csRate.ConsumptionScheduleId)){
                    CSIdWithCSRateListMap.get(csRate.ConsumptionScheduleId).add(csRate);
                }
                else{
                    CSIdWithCSRateListMap.put(csRate.ConsumptionScheduleId,new List<ConsumptionRate>{csRate});
                }
            }

            //Gitlab US#19381 -
            if(!CSIdWithCSRateListMap.isEmpty()){
                for(Id csId : CSIdWithCSRateListMap.keySet()){
                    for(ConsumptionRate csRate : CSIdWithCSRateListMap.get(csId)){
                        //Storing ConsumptionScheduleId and associated Consumption Schedule Rate in productIdWithCSIdMap
                        if(csRate.ConsumptionSchedule.Name.contains('List') && csRate.LowerBound == 1){
                            CSIdWithCSRateMap.put(csRate.ConsumptionScheduleId, csRate.Price);
                            break;
                        }
                        else{
                            CSIdWithCSRateMap.put(csRate.ConsumptionScheduleId, csRate.Price);
                        } 
                    }   
                } 
            }          
            System.debug('CSIdWithCSRateMap@@'+CSIdWithCSRateMap);
            //Gitlab US#19381
            if(!CSIdWithCSRateMap.isEmpty()){
                for(Id csId : CSIdWithCSRateMap.keySet()){
                    for(Id productId : csIdWithPrdIdListMap.get(csId)){
                        if(!productIdWithCSIdMap.containsKey(productId)){
                             productIdWithCSIdMap.put(productId,csId);
                        }
                    }
                }
            }
            System.debug('productIdWithCSIdMap@@'+productIdWithCSIdMap);
            
            //Get all the product
            // Queried extra fields and added CurrencyISO code condition for 13076
            // Added Pricebook2.IsActive = TRUE AND IsActive = true condition for #15735, CurrencyIsoCode is already avaliable.           
            //Tax category Gitlab 19786 -- Queried QTB_Tax_Category__c from PriceBook Entry and created a Map for storing the ProductId as Key and value as PricebookEntry Tax Category as a value
            Map<Id,String> ProductIdTaxCategoryMap = new Map<Id,String>();
            for(PricebookEntry pr : [SELECT id,Product2Id,IsActive,Product2.Name,Product2.ProductCode,Product2.IsActive,Product2.blng__BillingRule__c,Product2.blng__BillingRule__r.Name,Product2.blng__RevenueRecognitionRule__c,Product2.blng__TaxRule__c,
                                     Product2.SBQQ__BillingFrequency__c,Product2.SBQQ__BillingType__c,Product2.SBQQ__ChargeType__c,Product2.SBQQ__SubscriptionTerm__c,Pricebook2.QTB_Country__c,Pricebook2.IsActive,Pricebook2.CurrencyIsoCode,QTB_Tax_Category__c
                                     FROM PricebookEntry 
                                     WHERE Pricebook2id = :OrderItemExisting[0].PricebookEntry.Pricebook2id 
                                     AND CurrencyIsoCode = :OrderItemExisting[0].order.CurrencyIsoCode AND Pricebook2.IsActive = TRUE AND IsActive = true 
                                     AND Product2Id IN: productList and Product2.IsActive = true])
            {
                ProductIdTaxCategoryMap.put(pr.Product2Id,pr.QTB_Tax_Category__c);
                productIdProductNameMap.put(pr.Product2Id,pr.Product2.Name);   
                //CHeck with Hemnath// How can we get the order product details.// DYnamically for different country// Check with Varun/ / Chandrapraksh
                //create Order Products for provided productList
                OrderItem temporderitem = new OrderItem();
                temporderitem.OrderId = orderId;
                temporderitem.QTB_Order_Product_Type__c = 'ReBill';
                temporderitem.blng__BillableUnitPrice__c= CSIdWithCSRateMap.get(productIdWithCSIdMap.get(pr.Product2Id));
                temporderitem.Product2Id = pr.Product2Id;
                temporderitem.Quantity = 1;
                temporderitem.UnitPrice = CSIdWithCSRateMap.get(productIdWithCSIdMap.get(pr.Product2Id)); 
                temporderitem.QTB_Final_Unit_Price__c = temporderitem.UnitPrice;
                temporderitem.blng__HoldBilling__c = 'No';   
                temporderitem.blng__TaxCountry__c = OrderItemExisting[0].Order.QTB_Legal_Entity_Country__c;
                temporderitem.ServiceDate = StartDate; 
                temporderitem.EndDate = EndDate;
                temporderitem.SBQQ__BillingFrequency__c = pr.Product2.SBQQ__BillingFrequency__c;
                temporderitem.SBQQ__BillingType__c = pr.Product2.SBQQ__BillingType__c;
                temporderitem.SBQQ__ChargeType__c  = pr.Product2.SBQQ__ChargeType__c;  
                temporderitem.SBQQ__ContractAction__c  = 'New'; 
                temporderitem.SBQQ__ContractingMethod__c  = 'Inherit';
                temporderitem.SBQQ__SubscriptionTerm__c = pr.Product2.SBQQ__SubscriptionTerm__c;    
                temporderitem.SBQQ__DefaultSubscriptionTerm__c = 1;//Doubt on this value
                temporderitem.SBQQ__OrderedQuantity__c = 1;//Doubt on this value
                temporderitem.SBQQ__PricingMethod__c = 'List';
                temporderitem.SBQQ__ProductSubscriptionType__c = 'One-Time'; //Check with Varun
                temporderitem.SBQQ__SubscriptionType__c = 'One-Time';//Check with Varun
                temporderitem.SBQQ__Status__c = 'Draft';   
                temporderitem.SBQQ__SubscriptionPricing__c='Fixed Price';
                temporderitem.PricebookEntryId = pr.Id;
                temporderitem.blng__BillingRule__c = pr.Product2.blng__BillingRule__c;
                temporderitem.blng__BillingTreatment__c = billingRuleIdWithBillingTreatmentIdMap.get(pr.Product2.blng__BillingRule__c);
                temporderitem.blng__LegalEntity__c = OrderItemExisting[0].Order.Account.QTB_Contract_Entity__c;
                temporderitem.blng__RevenueRecognitionRule__c  = pr.Product2.blng__RevenueRecognitionRule__c;
                //Tax category Gitlab 19786 -- Checking the below condition for stopping the overriden of Tax rule Assignment for Special Tax category rule Population
                if(pr.QTB_Tax_Category__c == null){
                    temporderitem.blng__TaxRule__c = pr.Product2.blng__TaxRule__c;
                }
                temporderitem.blng__NextBillingDate__c = null;
                temporderitem.blng__InvoiceGrouping__c = 'Invoice Group ID';
                if(rebillOrder[0].QTB_Rebill_Type__c == System.Label.QTB_SplitRebill){ //SplitRebill
                    temporderitem.blng__InvoiceGroupId__c = '';
                }else{
                    temporderitem.blng__InvoiceGroupId__c = rebillOrderNumber;
                }
                temporderitem.QTB_PrefixMatchingID__c = rebillOrderNumber;
                temporderitem.QTB_OriginalConsumptionID__c = 'ReBill';
                if(pr.Product2.ProductCode == Label.QTB_Minimum_Storage || 
                   pr.Product2.ProductCode == LABEL.QTB_Invoice_Minimum ||
                   pr.Product2.Name == FUEL_SURCHARGE)//Due to duplicate Fuel Surcharge product name comparing with Name instead of productCode
                {
                    temporderitem.blng__BillingRule__c = noInvoiceBillingRuleList[0].id;
                    temporderitem.blng__BillingTreatment__c = billingTreatmentId[0];
                }
                else
                {
                    if(pr.Product2.blng__BillingRule__r.Name == 'No Invoice Rule'){
                        temporderitem.blng__InvoiceRunProcessingStatus__c ='Will Not Invoice'; 
                        temporderitem.blng__InvoiceRunStatusIndex__c ='Will Not Invoice'; 
                    }else{
                        temporderitem.blng__InvoiceRunProcessingStatus__c ='Pending Billing';
                        temporderitem.blng__InvoiceRunStatusIndex__c ='Pending Billing';   
                    }
                }
                OrderItemlst.add(temporderitem);   
                System.debug('OrderItemlst@@'+OrderItemlst);
            }
            
            if(!OrderItemlst.isEmpty() && OrderItemlst.size()>0){
                insert OrderItemlst;
                //check for billing countries and assig "No invoice billing treatment" #13076
                if(QTB_Billing_Countries__c.getValues(OrderItemExisting[0].Order.QTB_Legal_Entity_Country__c) != NULL)
                {
                    system.debug('inside billing country');
                    Id noTaxRule = [select id from blng__TaxRule__c where NAME='No Tax Rule' LIMIT 1].id;
                    for(OrderItem orderI : OrderItemlst)
                    {
                        orderI.blng__BillingRule__c = noInvoiceBillingRuleList[0].id;
                        orderI.blng__TaxCountry__c = OrderItemExisting[0].blng__TaxCountry__c;
                        //Tax category Gitlab 19786 -- Added below If Pondition for Overidden of tax rule Assignment for Billing only countries which updates for tax category products as well
                        if(ProductIdTaxCategoryMap.get(orderI.Product2Id) == Null){
                            system.debug('Inside Pricebook enty map');
                            orderI.blng__TaxRule__c = OrderItemExisting[0].blng__TaxRule__c;
                        }
                        //check for "Hong Kong" and assign "No tax rule" for #12022 
                        if (OrderItemExisting[0].Order.QTB_Legal_Entity_Country__c =='Hong Kong'){
                            orderI.blng__TaxRule__c= noTaxRule;
                        }
                        orderI.Description = productIdProductNameMap.get(orderI.Product2Id);
                    }       
                    update OrderItemlst; //updates only in case of billing country
                }
                // Added the else block as per of GITLAB - #15299 - PROD ISSUE -Non Billing Only Country Products Not Showing while adding Products to Rebill
                else 
                {
                    for(OrderItem ordI : OrderItemlst)
                    {
                        ordI.Description = productIdProductNameMap.get(ordI.Product2Id);
                        system.debug('ordI.Description@@' +ordI.Description);
                    }
                } 
                return OrderItemlst;                
            }
            else{
                return null;
            }
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);
            return null;
        }
    }
    
    /***********************************************************************************************************
* Method      : getUpdatedOrderProduct
* Parameter   : List<OrderItem> orderProductlist, Id rebillOrderId
* Return Type : List<OrderItem> 
* Author      : IRM/Virtusa
* Description : this method is responsible to return updated order products to LWC Comp - Order Product Screen of Credit & Rebill
**************************************************************************************************************/     
    @AuraEnabled(cacheable = false)
    public static List<OrderItem> getUpdatedOrderProduct(List<OrderItem> orderProductlist, Id rebillOrderId){
        try{
            System.debug('getUpdatedOrderProduct@@');
            Set<ID> orderProductIds = new Set<Id>();
            boolean isSplitRebill = false;
            for(OrderItem op :orderProductlist ){
                orderProductIds.add(op.Id);
                if(op.Order.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill){
                    isSplitRebill = true;
                }
            }            
            
            //SplitRebill -- based on isSplitRebill flag returning the query with or without blng__InvoiceGroupId__c
            if(isSplitRebill){
                return [SELECT Id, Product2.Name,Quantity,UnitPrice,QTB_Final_Unit_Price__c,blng__InvoiceGroupId__c 
                        FROM OrderItem 
                        WHERE ID IN:orderProductIds and OrderId =:rebillOrderId ];
            }
            else{
                return [SELECT Id, Product2.Name,Quantity,UnitPrice,QTB_Final_Unit_Price__c 
                        FROM OrderItem 
                        WHERE ID IN:orderProductIds and OrderId =:rebillOrderId ]; 
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);
            return null;
        }
    }
    /***********************************************************************************************************
* Method      : validateInvoiceGroupForOrderProduct
* Parameter   : Id rebillOrderId
* Return Type : boolean
* Author      : Virtusa
* Description : SplitRebill - Method to verify all validation related to invoiceGroup before processeding to Usage Screen
: this method written to handle only split credit & rebill, not the regular credit & rebill
**************************************************************************************************************/    
    @AuraEnabled
    public static string validateInvoiceGroupForOrderProduct(Id rebillOrderId) {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            System.debug('validateInvoiceGroupForOrderProduct@@');
            Set<String> checkDuplicate = new Set<String>();
            Set<String> FSInvoiceGroup = new Set<String>();
            Set<String> FSApplicablePrdInvoiceGroup = new Set<String>();
            Set<String> MSCInvoiceGroup = new Set<String>();
            Set<String> MSCApplicablePrdInvoiceGroup = new Set<String>();
            Set<String> totalInvoiceGroupSet = new Set<String>();
            Integer splitRebillCount;
            boolean billingOnlyCountry = false;
            boolean isSITAD  = false; // GITLAB US #22637 - To exclude firing validation for SITAD specific invoices while doing credit & rebill
            
            //Fetching OrderItem data for split
            // GITLAB US #22637 - Added  Order.Account.QTB_SITAD__c in Query
            List<orderItem> orderItemList = [SELECT Id,OrderItemNumber,OrderId,Order.QTB_Rebill_Type__c, Order.QTB_SplitRebillValue__c,Product2Id,blng__InvoiceGroupId__c,
                                             Product2.Name,Product2.QTB_Fuel_Surcharge_Applicable__c,Product2.QTB_Storage_Product__c,Order.QTB_Legal_Entity_Country__c,
                                             Order.Account.QTB_SITAD__c FROM OrderItem 
                                             WHERE OrderId =: rebillOrderId and Order.QTB_Rebill_Type__c =: System.Label.QTB_SplitRebill];
            
            //orderItemList is having data only for Split Rebill Scenario
            if(!orderItemList.isEmpty()){
                billingOnlyCountry = QTB_Billing_Countries__c.getValues(orderItemList[0].Order.QTB_Legal_Entity_Country__c) != null ? true : false;
                system.debug('billingOnlyCountry@@@' +billingOnlyCountry);
                isSITAD = orderItemList[0].Order.Account.QTB_SITAD__c ;
                system.debug('isSITAD' +isSITAD);
                
                //fetching all the OrderItem based on provided rebillOrderId 
                for(OrderItem orderItm : orderItemList)
                {
                    splitRebillCount = Integer.valueOf(orderItm.Order.QTB_SplitRebillValue__c);
                    //throwing error message if Invoice Group is empty
                    if(orderItm.blng__InvoiceGroupId__c == '' || orderItm.blng__InvoiceGroupId__c == null){
                        return System.Label.QTB_SplitRebillInvoiceGroupValidation;
                    }
                    else{
                        totalInvoiceGroupSet.add(orderItm.blng__InvoiceGroupId__c);
                        //throwing error message if productId + InvoiceGroup combination is duplicate
                        if(checkDuplicate.contains(orderItm.Product2Id + orderItm.blng__InvoiceGroupId__c)){
                            return System.Label.QTB_SplitRebill_SameProductInvoiceGroupErrorMsg;
                        }
                        else{
						    //For SITAD Split Rebill Bypass the validation - Same Invoice Group is not allowed for the same Product. Story #23353
							if (!orderItm.Order.Account.QTB_SITAD__c) {
								checkDuplicate.add(orderItm.Product2Id + orderItm.blng__InvoiceGroupId__c);
							}
                        }
                        //Storing Fuel Surcharge order product's invoice group from each group.
                        if(orderItm.Product2.Name == FUEL_SURCHARGE){
                            FSInvoiceGroup.add(orderItm.blng__InvoiceGroupId__c);//eg. split-001, Split-002
                        }
                        //Checking Fuel Surcharge applicable order product's and storing their invoice group in set
                        if(orderItm.Product2.QTB_Fuel_Surcharge_Applicable__c){
                            FSApplicablePrdInvoiceGroup.add(orderItm.blng__InvoiceGroupId__c); //split-001
                        }
                        //Storing Minimum Storage Charges order product's invoice group from each group.
                        if(orderItm.Product2.Name == Minimum_Storage_Charges){
                            MSCInvoiceGroup.add(orderItm.blng__InvoiceGroupId__c);//eg. split-001, Split-002
                        }
                        //CheckingMinimum Storage Charges applicable order product's and storing their invoice group in set
                        if(orderItm.Product2.QTB_Storage_Product__c){
                            MSCApplicablePrdInvoiceGroup.add(orderItm.blng__InvoiceGroupId__c); //split-001
                        }
                    }
                }
                System.debug('FSInvoiceGroup@@'+FSInvoiceGroup);
                System.debug('FSApplicablePrdInvoiceGroup@@'+FSApplicablePrdInvoiceGroup);
                System.debug('MSCInvoiceGroup@@'+MSCInvoiceGroup);
                System.debug('MSCApplicablePrdInvoiceGroup@@'+MSCApplicablePrdInvoiceGroup);
                
                //below logic is used to throw error message if Fuel Surcharge product or Fuel Surcharge applicable products are not from same Invoice Group
                // Added billingOnlyCountry check to exclude Billing only country from validation during split Rebill
                // GITLAB US #22637 -  Added not isSITAD check to exclude firing validation for SITAD specific invoices while doing credit & rebill
                if(!FSInvoiceGroup.isEmpty() && !billingOnlyCountry && !isSITAD)
                {
                    for(string invGrp : FSInvoiceGroup)
                    {   
                        if(!FSApplicablePrdInvoiceGroup.isEmpty()){
                            if(!FSApplicablePrdInvoiceGroup.contains(invGrp)){
                                return System.Label.QTB_SplitRebill_FuelSurchargeValidation +' ' + invGrp;
                            }
                        }else{
                            return System.Label.QTB_SplitRebill_FuelSurchargeValidation +' ' + invGrp;
                        }
                    }               
                }
                //below logic is used to throw error message if Minimum Storage product or Minimum Storage applicable products are not from same Invoice Group
                //Added billingOnlyCountry check to exclude Billing only country from validation during split Rebill
                // GITLAB US #22637 -  Added not isSITAD check to exclude firing validation for SITAD specific invoices while doing credit & rebill
                if(!MSCInvoiceGroup.isEmpty() && !billingOnlyCountry && !isSITAD)
                {
                    for(string invGrp : MSCInvoiceGroup)
                    {   
                        if(!MSCApplicablePrdInvoiceGroup.isEmpty()){
                            if(!MSCApplicablePrdInvoiceGroup.contains(invGrp)){
                                return System.Label.QTB_SplitRebill_MinimumStorageChargesValidation +' '+invGrp;
                            }
                        }else{
                            return System.Label.QTB_SplitRebill_MinimumStorageChargesValidation +' '+invGrp;
                        }
                    }  
                }
                
                //throwing warning message when selected split rebill count value not matched with the distinct Invoice Group count value
                if(!orderItemList.isEmpty() && totalInvoiceGroupSet.size() != splitRebillCount ){
                    return System.Label.QTB_SplitRebillCountValidation;
                }
            }
            return 'true'; //if no validation, then returning the true for sucess
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);
            return 'Something went wrong, please check with admin.';
        }
    }
    
    /***********************************************************************************************************
* Method      : getInvoiceDetails
* Parameter   : string invoiceId
* Return Type : String
* Author      : Virtusa
* Description : Defect fix - US#19738, Invoice's rebill status is sending to LWC comp to identify the usage creation is batch job status
**************************************************************************************************************/ 
    @AuraEnabled(cacheable=false)
    public static string getInvoiceDetails(string invoiceId){
        try{
            List<blng__Invoice__c> invoiceList = [SELECT Id, Name, QTB_ReBill_Status__c 
                                                  FROM blng__Invoice__c
                                                  WHERE Id =: invoiceId ];
            if(!invoiceList.isEmpty()){
                return invoiceList[0].QTB_ReBill_Status__c;
            }
            return null;
        }Catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_OrderProductsForRebill);
            return 'Something went wrong, please check with admin.';
        }
    }
}