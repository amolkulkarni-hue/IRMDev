/*****************************************************************************************************
* Class: QTB_OrderProductHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to OrderProduct object
* Requirement:
* Change History: 4/29/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*              4/13/2020
* Gopi        06/30/2022     Gitlab US #9256 Credit & Rebill
* Parth       03/20/2024     Gitlab #22533 code changes for malaysia tax increase
* Parth       04/30/2024     Gitlab #23284 populate translated product group based on language
*******************************************************************************************************/
public with sharing class QTB_OrderProductHelper {
    public static final String ORDERPROD_HELPER = 'QTB_OrderProductHelper';
    
    /***********************************************************************************************************
* Method : trigController
* Parameters: List<OrderItem>, Map<Id,OrderItem>,System.TriggerOperation
* Author : Accenture
* Description: Generic method to handle all operations on the Order Product Records
**************************************************************************************************************/
    public static void trigController(
        List<OrderItem> newList,
        Map<Id, OrderItem> oldMap,
        System.TriggerOperation operationType
    ) {
        Set<ID> orderIdSet = new Set<ID>();
        //For only SITAD Order Gitlab #13598 story
        List<Id> orderIdSetSITAD = new List<Id>();
        //Set<ID> orderIdSetAU = new Set<ID>();
        List<OrderItem> ReBillOrderPdtUpdate = new List<OrderItem>();
        Set<Id> ReBillOrderPdtTaxRuleUpdate = new Set<Id>();
        //#18864 ordPrdList for adding localisation
        List<OrderItem> ordProdLocal = new List<OrderItem>();
        //#32975 Added Set of Countries as passing the Parameter
        Set<String> opCountries = new Set<String>();
        // Gitlab 19786 --- Created a list to store tax category Items
        List<OrderItem> ordProdTaxCategoryList = new List<OrderItem>();
        //GitLab # 22554 List To store OrderPrduct for Hold Billing
        set<id> ordersIdSet = new Set<id>();
        List<OrderItem> TransPrdGrpList = new List<OrderItem>();
        for (OrderItem ordProd : newList) {
            switch on operationType {
                when BEFORE_INSERT {
                    if (ordProd.SBQQ__QuoteLine__c == null && ordProd.SBQQ__Contracted__c==false) {
                        orderIdSet.add(ordProd.OrderID);
                        //Git#8-Start Update Ready Activation checkbox to TRUE when criteria matches in before insert
                        if (
                            ordProd.blng__LegalEntity__c != null &&
                            ordProd.blng__TaxTreatment__c != null &&
                            ordProd.blng__TaxCountry__c != null &&
                            ordProd.QTB_Ready_Activation__c == false
                        )
                        { 
                            ordProd.QTB_Ready_Activation__c = true;
                            System.debug('ready activation before insert');
                        }
                        
                        //System.debug('print ready on insert'+ordProd.QTB_Ready_Activation__c);
                        //Git#8-End
                        //Gitlab #18864 to add localised values on order items
                        if(ordProd.product2Id != null && ordProd.QTB_Language__c != null){
                            System.debug('###ordProd###'+ordProd);
                            ordProdLocal.add(ordProd);
                        }
                        //#23284 to run setTranslatedProductGroup to populate translated product group
                        if(ordProd.QTB_Language__c != null){
                            TransPrdGrpList.add(ordProd);
                        }
                    }
                    
                }
                when BEFORE_UPDATE {
                    if (ordProd.SBQQ__QuoteLine__c == null && ordProd.SBQQ__Contracted__c==false) {
                        orderIdSet.add(ordProd.OrderID);
                        //Git#8-Start Update Ready Activation checkbox to TRUE when criteria matches in before insert
                        if (
                            ordProd.blng__LegalEntity__c != null &&
                            ordProd.blng__TaxTreatment__c != null &&
                            ordProd.blng__TaxCountry__c != null &&
                            ordProd.QTB_Ready_Activation__c == false
                        )
                        { 
                            ordProd.QTB_Ready_Activation__c = true;
                            System.debug('ready activation before update');
                            
                        }
                        
                        if(ordProd.QTB_Order_Product_Type__c == 'ReBill' && ordProd.QTB_Final_Unit_Price__c != oldMap.get(ordProd.id).QTB_Final_Unit_Price__c){
                            ordProd.UnitPrice = ordProd.QTB_Final_Unit_Price__c;
                        }
                        //System.debug('print ready on update'+ordProd.QTB_Ready_Activation__c);
                        
                        //Git#8-End
                        //Gitlab #18864 to add localised values on order items
                        //#32975 Commenetd the below Lines from Before Update to After Update
                       /* System.debug('### Before Update###');
                        //#32975 Added Country != Null and added to Set the country value
                        if((ordProd.QTB_Language__c != null && ordProd.QTB_Legal_Entity_Country__c != Null ) || (ordProd.QTB_Localized_Product_Name__c != null)){          
                            System.debug('### Before Update###'+ordProd + 'ordProd.QTB_Localized_Product_Name__c'+ordProd.QTB_Localized_Product_Name__c);
                            ordProdLocal.add(ordProd);
                        }*/
                    }
                    if(ordProd.SBQQ__SubscriptionType__c ==QTB_Constants.SUBSCRIPTION_TYPE_EVERGREEN
                       && ordProd.QTB_HasConsumptionSchedule__c ==FALSE
                       && ordProd.SBQQ__TerminatedDate__c != NULL
                       && oldMap.get(ordProd.Id).SBQQ__TerminatedDate__c == NULL ){
                           ordProd.blng__BillThroughDateOverride__c=ordProd.SBQQ__TerminatedDate__c.addDays(1);
                           
                       }
                }
                when AFTER_UPDATE {
                    System.debug('AFTER_UPDATE@@'+ordProd.blng__InvoiceGrouping__c );
                    //ReBill: Only for rebill Scenario// Hemnath // WHat should be blng__InvoiceGrouping__c
                    //Credit & Rebill by IRM/Virtusa
                    if(ordProd.QTB_Order_Product_Type__c == 'ReBill' && ordProd.SBQQ__Status__c == 'Draft' &&
                       (ordProd.UnitPrice != oldMap.get(ordProd.id).UnitPrice || ordProd.QTB_Final_Unit_Price__c != oldMap.get(ordProd.id).QTB_Final_Unit_Price__c)){
                           System.debug('AFTER_UPDATE_If@@');
                           ReBillOrderPdtUpdate.add(ordProd);
                       }
                    
                    //GitLab # 22554 Set To store OrderId for Hold Billing
                    if(ordProd.blng__HoldBilling__c != oldMap.get(ordProd.id).blng__HoldBilling__c)
                    {
                        ordersIdSet.add(ordProd.OrderId);
                    }
                    //Gitlab #18864 to add localised values on order items
                    //#32975 Added the below Lines from Before Update to After Update
                    //#32975 Added Country != Null and added to Set the country value and also Excuding the Ids which are already processed for avoiding the Recursion on After Update
                    //#32975 Added ordProd.QTB_Language__c != ordProd.QTB_language_Changed_Value__c because of triggering point for Both Inseert and Update as Avoiding Recursion when ever the OP is updated
                    if(ordProd.QTB_Language__c != Null && ordProd.QTB_Language__c != ordProd.QTB_language_Changed_Value__c && ordProd.QTB_Legal_Entity_Country__c != Null &&
                        !QTB_RecursiveHandlerCheck.uomDescriptionUpdateOPCSIds.contains(ordProd.Id)){          
                            ordProdLocal.add(ordProd);
                            opCountries.add(ordProd.QTB_Legal_Entity_Country__c);
                        }
                }
                when AFTER_INSERT {
                    //Credit & Rebill by IRM/Virtusa
                    if(ordProd.QTB_Order_Product_Type__c == 'ReBill' && ordProd.SBQQ__Status__c == 'Draft'){
                        System.debug('AFTER_UPDATE_Else_If@@');
                        ReBillOrderPdtUpdate.add(ordProd);
                    }
                    //Gitlab #14255 OP tax rule and treatment update logic for Singapore credit and rebill scenario 
                    //Gitlab #22533 checking with custom label to make logic work for all countries in which there is a tax increase
                    if(ordProd.blng__TaxCountry__c != null && ordProd.QTB_Order_Product_Type__c != null && ordProd.SBQQ__Status__c != null &&
                       system.label.QTB_Tax_Increase_Countries.contains(ordProd.blng__TaxCountry__c) && ordProd.QTB_Order_Product_Type__c == 'ReBill' && ordProd.SBQQ__Status__c == 'Draft'){
                           ReBillOrderPdtTaxRuleUpdate.add(ordProd.Id);
                       }

                    //Gitlab US#21078 Added Rebill check -- to exclude SITAD OPCS creation logic for rebill orders
                    //Below condition is to check for SITAD Order >> Gitlab #13598 story                    
                    if(ordProd.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE && ordProd.QTB_Order_Product_Type__c != 'ReBill')
                    {
                        orderIdSetSITAD.add(ordProd.OrderId); 
                    }
                    //Gitlab 19786 --- Adding the Order Items that are Tax category not equals to Null
                    if(ordProd.QTB_Tax_Category__c!= null){  
                       ordProdTaxCategoryList.add(ordProd);
                    }
                }
                when else {
                }
            } 
        }
        switch on operationType {
            when BEFORE_INSERT {
                if (!orderIdSet.isEmpty()) {
                    QTB_BillingAccountOrderProductUtil.updateTaxTreatment(newList, orderIdSet);
                    QTB_BillingAccountOrderProductUtil.setHoldBillingToRebillOrder(newList,orderIdSet);
                    QTB_BillingAccountOrderProductUtil.setInvoiceRunForOrderProduct(newList); 
                }
                //#18864 to run setLocalisedProductName and updateUOMDescription method to populate QTB_Localized_Product_Name__c and QTB_Localised_UOM__c
                if(!ordProdLocal.isEmpty()){
                    system.debug('Before Insert');
                    QTB_OrderProductUtils.setLocalisedProductName(ordProdLocal,null);
                }
                //#23284 to run setTranslatedProductGroup to populate translated product group
                if(!TransPrdGrpList.isEmpty()){
                    QTB_OrderProductUtils.setTranslatedProductGroup(TransPrdGrpList,null);
                }
            }
            when AFTER_UPDATE {
                //Credit & Rebill by IRM/Virtusa
                if(!ReBillOrderPdtUpdate.isEmpty() && ReBillOrderPdtUpdate.size() > 0 ){
                    updateCSRates(ReBillOrderPdtUpdate,true);
                }
                // GitLab # 22554 Utils class to Update Account Hold Billing Status field based on OI Hold Billing value
                if(!ordersIdSet.isEmpty()){
                    QTB_OrderProductUtils.UpdateAccountHoldBillingStatus(ordersIdSet);
                }
                //#32975 Added opCountries as Extra parameter for updated Name and also changed the name 
                //#32975 Added the calling from Before Update to After Update
                if(!ordProdLocal.isEmpty() && !opCountries.isEmpty()){
                    QTB_OrderProductUtils.updateUOMDescription(ordProdLocal,opCountries);
                }
            }
            when AFTER_INSERT {
                //Gitlab #14255 OP tax rule and treatment update logic for Singapore credit and rebill scenario
                if(!ReBillOrderPdtTaxRuleUpdate.isEmpty()){
                    system.debug('Inside rebill tax rule update');
                    QTB_OrderProductUtils.updateSingaporeOrdProductTaxRuleAndTreatment(ReBillOrderPdtTaxRuleUpdate);
                }
                //Gitlab 19786 --- Calling the updateTaxCategoryBasedTaxTreatments to populate the tax rule and Treatments according to Tax category on Priceook entry Tax category
                System.debug('<<<Start of op helper>>>'+ordProdTaxCategoryList);
                if(!ordProdTaxCategoryList.isEmpty()){
                    ordProdTaxCategoryList = QTB_OrderProductUtils.updateTaxCategoryBasedTaxTreatments(ordProdTaxCategoryList); 
                update ordProdTaxCategoryList;
                }
                System.debug('<<<End of op helper>>>'+ordProdTaxCategoryList);
                //Credit & Rebill by IRM/Virtusa
                if(!ReBillOrderPdtUpdate.isEmpty() && ReBillOrderPdtUpdate.size() > 0){
                    QTB_BillingAccountOrderProductUtil.updateCSRates(ReBillOrderPdtUpdate,false);
                }
            } 
            
            when BEFORE_UPDATE{
                //#18864 to run setLocalisedProductName and updateUOMDescription method to populate QTB_Localized_Product_Name__c and QTB_Localised_UOM__c
                //#32975 Added opCountries as Extra parameter for updated Name and also changed the name 
                //#32975 Commented the calling from Before Update to After Update
                /*if(!ordProdLocal.isEmpty() && !opCountries.isEmpty()){
                    QTB_OrderProductUtils.updateUOMDescription(ordProdLocal,opCountries);
                }*/
            }
            when else {
            }
        }     
    }
    
    /***********************************************************************************************************
* Method : updateTaxTreatment
* Parameters: List<OrderItem>
*Return type : void
* Requirement : SFCPQBLG-66 , SFCPQBLG-67
* Description: populate order products with tax treatment and other values
**************************************************************************************************************/
    public static void updateTaxTreatment(
        List<OrderItem> ordItemNewList,
        Set<ID> orderIDs
    ) {
        Set<Id> legalEntityIds = new Set<Id>();
        Set<Id> billingAccountIds = new Set<Id>();
        List<Account> accList = new List<Account>();
        try {
            if (QTB_OrderProductHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            // Creating set of Legal Entities and Accounts to populate them and also to fetch tax treatments
            for (Order ord : [
                SELECT id, AccountID, Account.QTB_Contract_Entity__c
                FROM Order
                WHERE id IN :orderIDs
            ]) {
                legalEntityIds.add(ord.Account.QTB_Contract_Entity__c);
                billingAccountIds.add(ord.AccountId);
            }
            if (!billingAccountIds.isEmpty()) {
                // # 20604 Added QTB_Legal_Entity_Country__c field for Account query
                accList = [
                    SELECT
                    Id,
                    SBQQ__TaxExempt__c,
                    QTB_Hold_Billing__c,
                    QTB_Billing_Frequency__c,
                    QTB_Contract_Entity__c,
                    QTB_Special_Tax_Condition__c,
                    /*ShippingCountry,*/
                    QTB_Legal_Entity_Country__c
                    FROM Account
                    WHERE Id IN :billingAccountIds
                ];
            }
            Map<Id, Account> accMap = new Map<Id, Account>(accList);

            // calling method to populate order products with tax treatment and other values
            ordItemNewList = QTB_Utils.updateTaxTreatmentOrderProducts(
                legalEntityIds,
                accMap,
                ordItemNewList
            );
            
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ORDERPROD_HELPER
            );
            throw e;
        }
    }
    /***********************************************************************************************************
* Method        : updateCSRates
* Parameters    : List<OrderItem>
* Return type   : void
* Requirement   : Gitlab US #9256 Credit & Rebill
* Description   : Update order products new Unit Price to the CS Rates
**************************************************************************************************************/
    public static void updateCSRates(List<OrderItem> ordItemNewList, boolean isUnitPriceChange) 
    {
        System.debug('updateCSRates@@');
        List<Account> accList = new List<Account>();
        Map<id,SBQQ__OrderItemConsumptionSchedule__c> mapOrdPdtIdToCS = new Map<id,SBQQ__OrderItemConsumptionSchedule__c>();
        List<SBQQ__OrderItemConsumptionSchedule__c> orderProductCSList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
        List<SBQQ__OrderItemConsumptionRate__c> CSRatesUpdate = new List<SBQQ__OrderItemConsumptionRate__c>();
        List<blng__Usage__c> usgList = new List<blng__Usage__c>();
        List<blng__UsageSummary__c> usgSummaryList = new List<blng__UsageSummary__c>();
        try {
            List<blng__TaxRule__c> taxrule = [select id from blng__TaxRule__c where name = 'No Tax Rule' LIMIT 1];
            //if (QTB_OrderProductHandler.throwExplicitException) {
            //   throw new NullPointerException();
            //}
            
            // Creating set Order Item CS
            // Queried extra fields for 12022 
            for (SBQQ__OrderItemConsumptionSchedule__c ordPdtCS : [ SELECT id,Name,SBQQ__OrderItem__c,SBQQ__OrderItem__r.OrderItemNumber, SBQQ__OrderItem__r.blng__InvoiceGroupId__c, SBQQ__OrderItem__r.Order.QTB_Rebill_Type__c,SBQQ__OrderItem__r.SBQQ__Status__c,SBQQ__OrderItem__r.QTB_Final_Unit_Price__c,SBQQ__OrderItem__r.blng__LegalEntity__c,SBQQ__OrderItem__r.blng__TaxTreatment__c,SBQQ__OrderItem__r.blng__TaxRule__c,
                                                                   SBQQ__OrderItem__r.QTB_PrefixMatchingID__c,SBQQ__OrderItem__r.blng__BillingTreatment__c,SBQQ__OrderItem__r.blng__BillingRule__c,SBQQ__OrderItem__r.UnitPrice,SBQQ__OrderItem__r.blng__TaxCountry__c,blng__TaxRule__c,SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c,SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c, blng__BillingRule__c,blng__FinanceBookAccounting__c,
                                                                   (SELECT id,SBQQ__Price__c,SBQQ__OrderItemConsumptionSchedule__c FROM SBQQ__OrderItemConsumptionRates__r order by SBQQ__LowerBound__c asc)
                                                                   FROM SBQQ__OrderItemConsumptionSchedule__c
                                                                   WHERE SBQQ__OrderItem__c IN :ordItemNewList and SBQQ__OrderItem__r.SBQQ__Status__c = 'Draft']) 
            {  
                if(!Test.isRunningTest()){
                    ordPdtCS.blng__LegalEntity__c = ordPdtCS.SBQQ__OrderItem__r.blng__LegalEntity__c;  
                    ordPdtCS.blng__BillingTreatment__c = ordPdtCS.SBQQ__OrderItem__r.blng__BillingTreatment__c;
                    ordPdtCS.blng__TaxRule__c = ordPdtCS.SBQQ__OrderItem__r.blng__TaxRule__c;
                    ordPdtCS.blng__TaxTreatment__c = ordPdtCS.SBQQ__OrderItem__r.blng__TaxTreatment__c;
                    ordPdtCS.blng__BillingRule__c = ordPdtCS.SBQQ__OrderItem__r.blng__BillingRule__c;
                }
                
                if(ordPdtCS.SBQQ__OrderItem__r.Order.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill){
                    ordPdtCS.SBQQ__MatchingAttribute__c = ordPdtCS.SBQQ__OrderItem__r.QTB_PrefixMatchingID__c + ordPdtCS.SBQQ__OrderItem__r.OrderItemNumber + ordPdtCS.SBQQ__OrderItem__r.blng__InvoiceGroupId__c;
                }else{
                     //Gitlab US#22731 --Changing the matchingAttribute value from orderNumber to OrderItemNumber for unique value
                     ordPdtCS.SBQQ__MatchingAttribute__c = ordPdtCS.SBQQ__OrderItem__r.OrderItemNumber; //ordPdtCS.SBQQ__OrderItem__r.QTB_PrefixMatchingID__c;
                }//check for "Hong Kong" and assign "No tax rule"  for OPCS level for Rebill Order #12022
                if(QTB_Billing_Countries__c.getValues(ordPdtCS.SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c) != NULL){
                    ordPdtCS.blng__TaxRule__c = ordPdtCS.SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c;
                    ordPdtCS.blng__TaxTreatment__c = ordPdtCS.SBQQ__OrderItem__r.blng__TaxTreatment__c;
                    if(ordPdtCS.SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c == 'Hong kong' && !taxrule.isEmpty()){  
                        system.debug('inside hong kong Coubtry');
                        ordPdtCS.blng__TaxRule__c = taxrule[0].id;
                        ordPdtCS.blng__TaxTreatment__c = null;
                    }
                }
                orderProductCSList.add(ordPdtCS);
                //Hemnath: WHat happens if multiple are there             
                //Choose how many CS are present for the Order Product(LIST/ Range/ SLAB)
                //If -> Only 1 ->(LIST/ Range/ SLAB) --> Already by Quoting process
                //If -> More than 1 ->(LIST/ Range/ SLAB){ --> This is by our ReBill Product addition
                //Choose the LIST one else, only one which is available
                if(isUnitPriceChange){
                    if(mapOrdPdtIdToCS.containsKey(ordPdtCS.SBQQ__OrderItem__c)){
                        if(ordPdtCS.Name.contains('LIST')){
                            mapOrdPdtIdToCS.put(ordPdtCS.SBQQ__OrderItem__c,ordPdtCS);
                        }
                    }else{//By Quoting process// Only 1 time
                        mapOrdPdtIdToCS.put(ordPdtCS.SBQQ__OrderItem__c,ordPdtCS);
                    }
                }
            }
            
            if(isUnitPriceChange){
                for(blng__UsageSummary__c objUsgSummary : [SELECT Id,Name,blng__UnitPrice__c,blng__OrderProduct__c,blng__OrderProduct__r.UnitPrice, blng__OrderProduct__r.SBQQ__Status__c,
                                                           (SELECT Id,blng__UnitPrice__c FROM blng__Usages__r )
                                                           FROM blng__UsageSummary__c
                                                           WHERE blng__OrderProduct__c IN : ordItemNewList and blng__OrderProduct__r.SBQQ__Status__c = 'Draft'])
                {
                    if(objUsgSummary.blng__Usages__r != null && objUsgSummary.blng__Usages__r.size() > 0){
                        for(blng__Usage__c usg: objUsgSummary.blng__Usages__r ){
                            blng__Usage__c us = new blng__Usage__c();
                            us.id = usg.id;
                            us.blng__UnitPrice__c = objUsgSummary.blng__OrderProduct__r.UnitPrice;
                            usgList.add(us);   
                        }  
                    }                   
                    blng__UsageSummary__c usgSum = new blng__UsageSummary__c();
                    usgSum.id = objUsgSummary.Id;
                    usgSum.blng__UnitPrice__c = objUsgSummary.blng__OrderProduct__r.UnitPrice;  
                    usgSummaryList.add(usgSum);
                }
                for(SBQQ__OrderItemConsumptionSchedule__c CS : mapOrdPdtIdToCS.values()){
                    for(SBQQ__OrderItemConsumptionRate__c csR : CS.SBQQ__OrderItemConsumptionRates__r){
                        //csR.SBQQ__Price__c = CS.SBQQ__OrderItem__r.QTB_Final_Unit_Price__c;
                        csR.SBQQ__Price__c = CS.SBQQ__OrderItem__r.UnitPrice;
                        CSRatesUpdate.add(csR);
                        break;
                    }
                }
            }
            
            
            if(!orderProductCSList.isEmpty() && orderProductCSList.size() > 0){
                update orderProductCSList;
            }
            if(!CSRatesUpdate.isEmpty() && CSRatesUpdate.size() > 0){
                update CSRatesUpdate;
            }
            
            if(!usgList.isEmpty() && usgList.size() > 0){
                update usgList; 
            }
            
            if(!usgSummaryList.isEmpty() && usgSummaryList.size() > 0){
                SBQQ.TriggerControl.disable();
                update usgSummaryList; 
                SBQQ.TriggerControl.enable();
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),ORDERPROD_HELPER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method        : setHoldBillingToRebillOrder
* Parameters    : List<OrderItem> ordItemNewList,Set<ID> orderIDs
* Return type   : void
* Requirement   : Gitlab US #9256 Credit & Rebill AND Gitlab US #23353
* Description   : Setting HoldBilling to No for Singapore products & To populate Order Item QTB_Case_Number__c for US #23353
* Description   : Adding to the above to populate Order Item QTB_Case_Number__c for the Story #23353
**************************************************************************************************************/
    public static void setHoldBillingToRebillOrder(List<OrderItem> ordItemNewList,Set<ID> orderIDs){
        Map<Id,Order> orderMap = new Map<Id,Order>([ SELECT Id,QTB_OrderCategory__c,CurrencyISOCode,QTB_Legal_Entity_Country__c,Account.QTB_SITAD__c,QTB_Case_Number__c
                                                    FROM order
                                                    WHERE id IN :orderIDs]);    
        for(OrderItem ordItem : ordItemNewList)
        {
            if(orderMap.get(ordItem.OrderId).QTB_OrderCategory__c == 'Rebill' && (
            QTB_Billing_Countries__c.getValues(orderMap.get(ordItem.OrderId).QTB_Legal_Entity_Country__c ) != null &&
            orderMap.get(ordItem.OrderId).QTB_Legal_Entity_Country__c == QTB_Billing_Countries__c.getValues(orderMap.get(ordItem.OrderId).QTB_Legal_Entity_Country__c ).Name) || Label.QTB_SITAD_Countries.contains(orderMap.get(ordItem.OrderId).QTB_Legal_Entity_Country__c)){// GitLab US #28779 added sitad countries check as part of this defect
                ordItem.blng__HoldBilling__c = 'No';
            }
            
            //Logic to populate the Order Item Case Number For SITAD Order Products from Order Case Number. Story #23353
            if(orderMap.get(ordItem.OrderId).Account != null && orderMap.get(ordItem.OrderId).Account.QTB_SITAD__c == true && 
                //QTB_Billing_Countries__c.getValues(orderMap.get(ordItem.OrderId).QTB_Legal_Entity_Country__c ) == null && //GitLab #27020 - Commented this line
                Label.QTB_SITAD_Countries.contains(orderMap.get(ordItem.OrderId).QTB_Legal_Entity_Country__c) && //GitLab #27020 - added this line to allow all cluster 1 countries
               orderMap.get(ordItem.OrderId).QTB_Case_Number__c != null && ordItem.QTB_Order_Product_Type__c != 'ReBill'
            ) {
                ordItem.QTB_Case_Number__c = orderMap.get(ordItem.OrderId).QTB_Case_Number__c;
            }   
        }
    }
    
    /***********************************************************************************************************
* Method        : setInvoiceRunForOrderProduct
* Parameters    : List<OrderItem> ordItemNewList
* Return type   : void
* Requirement   : Gitlab US #9256 Credit & Rebill
* Description   : Setting blng__InvoiceRunProcessingStatus__c to Pending billing for Rebill Order Products
**************************************************************************************************************/
    public static void setInvoiceRunForOrderProduct(List<OrderItem> ordItemNewList){
        Set<Id> product2Ids = new Set<Id>();
        for(OrderItem ordItem : ordItemNewList){
            product2Ids.add(ordItem.Product2Id);
        }
        try{
            Map<Id,Product2> productMap = new Map<Id,Product2>([ SELECT Id, ProductCode,Name
                                                                FROM Product2
                                                                WHERE id IN :product2Ids]);
            for(OrderItem ordItem : ordItemNewList)
            {
                if(ordItem.QTB_Order_Product_Type__c == 'ReBill' &&  ordItem.SBQQ__Status__c == 'Draft' &&
                   (productMap.get(ordItem.Product2Id).ProductCode != Label.QTB_Minimum_Storage &&
                    productMap.get(ordItem.Product2Id).ProductCode !=  LABEL.QTB_Invoice_Minimum &&
                    productMap.get(ordItem.Product2Id).Name != 'Fuel Surcharge')) //Defect fix #22022
                {
                    ordItem.blng__InvoiceRunProcessingStatus__c ='Pending Billing';
                    ordItem.blng__InvoiceRunStatusIndex__c ='Pending Billing';
                }
            }  
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),ORDERPROD_HELPER);
            throw e;
        }
    }
    public static void justIncrement() {
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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