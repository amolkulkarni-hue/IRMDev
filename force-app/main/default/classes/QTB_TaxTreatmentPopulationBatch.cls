/*****************************************************************************************************
* Class: QTB_TaxTreatmentPopulationBatch
* Author: Accenture
* Purpose: This is a Batch class to modify tax treatment in order products when account is modified
* Requirement: QTB-17a/QTB-45
* Change History: 4/29
* Developer     Date           Description
* Virtusa       05/02/2023     Git #13959, Singapore tax treatment assignment based on the order effective date
* -------------------------------------------------------------------------------------------
* Update : 12/06/2022
* update : 05/04/2024			Gitlab #22533, using custom label to check country having tax increase
*******************************************************************************************************/
global class QTB_TaxTreatmentPopulationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    global static final string className = QTB_TaxTreatmentPopulationBatch.class
        .getName();
    global static boolean throwExplicitException = false;
    global String query;
    global Map<Id, Account> accMap = new Map<Id, Account>();
    global Set<Id> accIdSet = new Set<Id>();
    //Git#11817 Map to fetch the Tax treatment in order to populate Tax rules
    global Map<Id, blng__TaxTreatment__c> TaxTrtMap = new Map<Id,blng__TaxTreatment__c>([
        SELECT id,blng__TaxRule__r.id 
        FROM blng__TaxTreatment__c
        WHERE blng__Active__c = true AND blng__TaxRule__c != null
    ]);
    //Constructor to get list of accounts from queueable class
    global QTB_TaxTreatmentPopulationBatch(List<Account> accList) {
        accMap.PutAll(accList);
        accIdSet.addAll(accMap.keySet());
        //#18814 Addition of Termination date in the query as part of Finland Billing solutions
        //21614 Queried Account.shippingcountry field for  Bypassing the Singapore tax treatment logic those dont have Effective dates
        query =
            ' Select Id,orderitemnumber,OrderId,Order.AccountId,Order.Account.QTB_Contract_Entity__c,blng__TaxTreatment__c,SBQQ__BillingFrequency__c,UnitPrice,SBQQ__TaxAmount__c,SBQQ__ChargeType__c, ' +
            ' blng__TaxStatus__c,blng__BillableUnitPrice__c,blng__LegalEntity__c,blng__TaxCountry__c,QTB_OriginalConsumptionID__c,blng__TaxTreatment__r.blng__TaxRule__c,order.Account.SBQQ__TaxExempt__c,order.Account.QTB_Hold_Billing__c,order.QTB_Legal_Entity_Country__c,blng__TaxRule__c,blng__InvoiceGroupId__c,QTB_Tax_Category__c,order.Account.shippingcountry,order.Account.QTB_Legal_Entity_Country__c from OrderItem where order.AccountID ' +
            ' IN :accIdSet and SBQQ__Activated__c=True and (SBQQ__TerminatedDate__c = null OR SBQQ__TerminatedDate__c >= TODAY )';
    }
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Iterable
Requirement: SFCPQBLG-66 ,SFCPQBLG-67
Description: Fetch required records
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<Account>
Return Type: void
Requirement: SFCPQBLG-66 ,SFCPQBLG-67
Description: Sets tax treatment on order product
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<orderitem> scope) {
        String errorIds = '';
        try {
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            Database.SaveResult[] results;
            list<OrderItem> billingOrderItem = new List<OrderItem>();
            list<orderItem> remaningOrderItem = new List<orderItem>(); //Gitlab #22533
            Set<Id> legalEntityIds = new Set<Id>();
            Map<Id, Account> newAccountMap = new Map<Id, Account>();
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSToInsert = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            Set<Id> sgOrderItemIds = new Set<id>();
            for (OrderItem ordItem : scope) {
                if (accMap.containsKey(ordItem.Order.AccountId)) {
                    newAccountMap.put(
                        ordItem.Order.AccountId,
                        accMap.get(ordItem.Order.AccountId)
                    );
                }
                if (ordItem.Order.Account.QTB_Contract_Entity__c != null) {
                    legalEntityIds.add(ordItem.Order.Account.QTB_Contract_Entity__c);
                }
            }
            
            billingOrderItem = QTB_Utils.updateTaxTreatmentOrderProducts(
                legalEntityIds,
                newAccountMap,
                scope
            );
            //Gitlab #19786 for Meta scrap
            if(!billingOrderItem.isEmpty()){
                billingOrderItem = QTB_OrderProductUtils.updateTaxCategoryBasedTaxTreatments(billingOrderItem);
                system.debug('billingOrderItem after our method:'+billingOrderItem);
                system.debug('Billing orderItem List size:'+billingOrderItem.size());
            }
            
            for (orderitem orditem :billingOrderItem ) {
                errorIds += ';;' + orditem.Id;
                //SG Tax Treatment Issue fix #13959, when account is put on/off hold impacting tax treatments
                //21614 Added tax exempt scenario and Shipping country equals to Legal Entity Country for Bypassing the Tax treatment which is not having Effective dates on Tax Treatment level
                //#22533 using custom label to check country having tax increase and added tax category condition, as malaysia have different tax rule based on tax category and where tax category is not null that is handled above 'QTB_OrderProductUtils.updateTaxCategoryBasedTaxTreatments' 
                if(orditem.order.QTB_Legal_Entity_Country__c != null && orditem.blng__TaxCountry__c != null && System.label.QTB_Tax_Increase_Countries.contains(orditem.order.QTB_Legal_Entity_Country__c) && System.label.QTB_Tax_Increase_Countries.contains(orditem.blng__TaxCountry__c)
                   && orditem.Order.Account.SBQQ__TaxExempt__c == 'No' && orditem.order.Account.shippingcountry == orditem.order.QTB_Legal_Entity_Country__c && orditem.QTB_Tax_Category__c == null ){
                       sgOrderItemIds.add(orditem.id);
                   }
                //start GitLab #10883
                
                else if(QTB_Billing_Countries__c.getValues(orditem.order.QTB_Legal_Entity_Country__c ) != null){
                    orditem.blng__HoldBilling__c = 
                        orditem.order.Account.QTB_Hold_Billing__c == true
                        ? 'Yes'
                        : 'No';
                    //Git#11817 Country specific Tax Rule population
                    if(TaxTrtMap.containsKey(orditem.blng__TaxTreatment__c))
                    {
                        orditem.blng__TaxRule__c =  TaxTrtMap.get(orditem.blng__TaxTreatment__c).blng__TaxRule__r.id;
                    }
                    remaningOrderItem.add(orditem);
                }
                else{
                    remaningOrderItem.add(orditem);
                }
                
                //end
            }
            
            //update order items
            if (!billingOrderItem.isEmpty())
            { 
                //GIT 13959, calling "updateSingaporeOrdProductTaxRuleAndTreatment" to update orderItems based on order Category
                if(!sgOrderItemIds.isEmpty()){
                    QTB_OrderProductUtils.updateSingaporeOrdProductTaxRuleAndTreatment(sgOrderItemIds);
                }
                //Updating the Order items for Billing countries
                //Gitlab #22533 replaced else if condition with if condition as considering malaysia country, under a single order there can be 6% as well as 8% tax 
                if(!remaningOrderItem.isEmpty()){ 
                    SBQQ.TriggerControl.disable();
                    results = Database.update(remaningOrderItem, true);
                    SBQQ.TriggerControl.enable();
                }
                //Git#8 Start update child consumption schedule record's tax treatment when respective field is changed on Order product
                for (SBQQ__OrderItemConsumptionSchedule__c OPCS : [
                    SELECT id, SBQQ__OrderItem__r.blng__TaxTreatment__c,SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c,SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c
                    FROM SBQQ__OrderItemConsumptionSchedule__c
                    WHERE SBQQ__OrderItem__c IN :billingOrderItem
                ]) {
                    OPCS.blng__TaxTreatment__c = OPCS.SBQQ__OrderItem__r.blng__TaxTreatment__c;
                    //Git#11817 Country specific Tax Rule population for Billing countries
                    If(QTB_Billing_Countries__c.getValues(OPCS.SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c) != null)
                    {
                        OPCS.blng__TaxRule__c = OPCS.SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c;
                    }
                    OPCSToInsert.add(OPCS);
                }
                SBQQ.TriggerControl.disable();
                if (!OPCSToInsert.isEmpty())
                    update OPCSToInsert;
                SBQQ.TriggerControl.enable();
                //Git#8 End
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className
            );
        }
    }
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Requirement: SFCPQBLG-66 ,SFCPQBLG-67
Description: No action to be taken
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
    }
}