/*****************************************************************************************************
* Class:   QTB_CreateAdditionalOrderBatch
* Author: Virtusa
* Purpose: This is a Batch class to Create Ad-Hoc Order/OrderItem under Billing Account (Data load for Singapore Tax incremnet)
* Requirement: 
* Change History: 
* Developer     	Date           Description
* -------------------------------------------------------------------------------------------
*             		09/12/2022
* Parth(Virtusa)	16/04/2024	   Gitlab #23142 Assigning orderitem Invoice group ID field based on account split invoice flag
*******************************************************************************************************/
global class QTB_CreateAdditionalOrderBatch implements Database.Batchable<SObject>,Database.Stateful{
    global static final string className = QTB_CreateAdditionalOrderBatch.class.getName();
    global static boolean throwExplicitException = false;
    global String query;
    global Set<Id> RecordTypeIdSet = new Set<Id>();
    global List<Id> OrderRecordTypeId = new List<Id>();
    global Set<Id> orderIdSet = new Set<Id>(); 
    global Set<String> ProductCodeSet = new Set<String>(); 
    global Set<String> CountrySet = new Set<String>(); 
    global List<pricebookentry> PriceBklst = new List<pricebookentry>(); 
    global List<Pricebook2> SgPricebook = new List<Pricebook2>();
    global List<blng__TaxTreatment__c> sgListTaxTreat = new List<blng__TaxTreatment__c>();
    global List<blng__BillingTreatment__c> sgListBillingTreat = new List<blng__BillingTreatment__c>();  
    global List<blng__LegalEntity__c> SgLegalEnity = new List<blng__LegalEntity__c>();
    global String SourceSys;
    global Date StartDate;
    global integer RecSize;
    global List<blng__LegalEntity__c> LegEnt = new List<blng__LegalEntity__c>();
    global String AccountCurrency;
    global id legalEntity;
    global set<string>uomSet = new Set<string>();
    global QTB_CreateAdditionalOrderBatch(String accSourceSys,Date OrderStartdate,Integer recds,Set<String> ProductCode,id legalId,String AccountCurrencyCode,Set<string>uoms) {
        //QTB_Billing_Countries__c Billcust = QTB_Billing_Countries__c.getInstance('Singapore');
        uomSet.addAll(uoms); 
        LegEnt=[Select id,CurrencyIsoCode,name,blng__Country__c from blng__LegalEntity__c where id =:legalId];
        SourceSys = accSourceSys;
        StartDate = OrderStartdate;
        RecSize = recds;
        ProductCodeSet.addall(ProductCode);
        AccountCurrency =AccountCurrencyCode;
        legalEntity = legalId;
        CountrySet.add(LegEnt[0].blng__Country__c);
        sgListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='No Invoice Billing Treatment' LIMIT 1];
        //sgListTaxTreat=[Select id, name,blng__TaxRule__r.id from blng__TaxTreatment__c Where Name='Singapore Tax Treatment' LIMIT 1];
        //SgLegalEnity=[Select id, name from blng__LegalEntity__c Where blng__Country__c ='Singapore' and CurrencyIsoCode='SGD' LIMIT 1];
        //#13172 FOREX Single Pricebook implemention
        SgPricebook=[Select id, name from Pricebook2 Where QTB_Country__c=:LegEnt[0].blng__Country__c
                     and IsActive = true LIMIT 1];
        OrderRecordTypeId.add(Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
        //#13172 FOREX Single Pricebook implemention
        PriceBklst=[select id, name,Product2.QTB_Storage_Product__c,Product2Id,Product2.SBQQ__ChargeType__c,Product2.SBQQ__BillingFrequency__c,Product2.SBQQ__BillingType__c,Product2.blng__BillingRule__c,Product2.blng__TaxRule__c,Product2.blng__RevenueRecognitionRule__c,Product2.SBQQ__SubscriptionTerm__c from pricebookentry where pricebook2id =:SgPricebook[0].id and ProductCode IN:ProductCodeSet and CurrencyIsoCode =:AccountCurrency and IsActive = true];
        RecordTypeIdSet.add(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId());
        
        query='Select id,QTB_Bill_Cycle_Day__c,CurrencyIsoCode,(Select id from Orders),QTB_Contract_Entity__c,QTB_Contract_Entity__r.blng__Country__c,ShippingPostalCode,ShippingState,ShippingStreet,ShippingCountry,ShippingCity,Payment_Terms__c' +
            ' from Account' +
            ' Where QTB_Contract_Entity__c  = :legalEntity AND' +
            ' QTB_Is_Parent_Billing_Account__c = False AND ' +
            ' QTB_DM_Source_System__c = :SourceSys AND' +
            ' RecordtypeID IN :RecordTypeIdSet AND CurrencyIsoCode=:AccountCurrency ORDER BY Id DESC LIMIT :RecSize'; 
        
        system.debug('In Start method of batch>>>>>>>>>>1111111111111999999'+ query);
    }
    /*********************************************************************************************************

Method Name: start
Parameters: Database.BatchableContext
Return Type: Iterable
Requirement: 
Description: Fetch required records
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<OrderItem>
Return Type: void
Requirement: 
Description: Creates/Updates OPCS and OPCR on order product.
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        system.debug('In execute method of batch>>>>>>>>>>');
        String errorIds = '';
        List<Order> OrderToInsert = new List<Order>();
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            }
            //
            for (Account acc : scope) 
            {  
                
                Order tempOrder = new Order();
                tempOrder.AccountId = acc.id;
                tempOrder.CurrencyIsoCode = acc.CurrencyIsoCode;
                tempOrder.EffectiveDate = StartDate;
                tempOrder.EndDate = Date.newInstance(StartDate.year(), StartDate.month(), Date.daysInMonth(StartDate.year(), StartDate.month()));//lastDayOfTheMonth
                System.debug('endDate Debug --->'+tempOrder.EndDate);
                tempOrder.Pricebook2Id = SgPricebook[0].id;
                tempOrder.QTB_Legal_Entity_Country__c = acc.QTB_Contract_Entity__r.blng__Country__c;
                tempOrder.QTB_OrderCategory__c = 'Ad-Hoc';
                tempOrder.RecordTypeId = OrderRecordTypeId[0];      
                tempOrder.SBQQ__PaymentTerm__c = acc.Payment_Terms__c;
                tempOrder.ShippingCity = acc.ShippingCity;      
                tempOrder.ShippingCountry = acc.ShippingCountry; 
                tempOrder.ShippingPostalCode = acc.ShippingPostalCode;
                tempOrder.ShippingState = acc.ShippingState; 
                tempOrder.ShippingStreet = acc.ShippingStreet;
                tempOrder.Status = 'Draft';
                tempOrder.Type = 'New';
                tempOrder.blng__BillingDayOfMonth__c = '1';  
                tempOrder.blng__InvoiceBatch__c = acc.QTB_Bill_Cycle_Day__c;
                //tempOrder.bling_Legal_Entity__c = acc.QTB_Contract_Entity__c;
                OrderToInsert.add(tempOrder);
            }
            if (!OrderToInsert.isEmpty())
            {
                insert OrderToInsert;
            }
            
            if (!OrderToInsert.isEmpty())
            {
                List<OrderItem> OrderItemlst = new List<OrderItem>();
                Map<Id,Order> ordersMap = new Map<Id,Order>([select id,Account.QTB_Split_Invoice_Flag__c,OrderNumber from Order where id in:OrderToInsert]);
                For(Order ord : OrderToInsert)
                { 
                    
                    For(pricebookentry pr : PriceBklst)
                    { 
                        OrderItem temporderitem = new OrderItem();
                        temporderitem.OrderId = ord.id;
                        temporderitem.Product2Id = pr.Product2.Id;
                        temporderitem.Quantity = 1;
                        temporderitem.UnitPrice = 0; 
                        temporderitem.blng__HoldBilling__c = 'No';   
                        temporderitem.blng__TaxCountry__c = ord.QTB_Legal_Entity_Country__c;
                        temporderitem.ServiceDate = ord.EffectiveDate;
                        temporderitem.EndDate = ord.EndDate;
                        temporderitem.SBQQ__BillingFrequency__c = 'Monthly';
                        temporderitem.SBQQ__BillingType__c = 'Arrears';
                        temporderitem.SBQQ__ChargeType__c  = 'Recurring';  
                        temporderitem.SBQQ__ContractAction__c  = 'New'; 
                        temporderitem.SBQQ__ContractingMethod__c  = 'Inherit';
                        temporderitem.SBQQ__SubscriptionTerm__c= 1;    
                        temporderitem.SBQQ__DefaultSubscriptionTerm__c= 1;
                        temporderitem.SBQQ__OrderedQuantity__c= 1;
                        temporderitem.SBQQ__PricingMethod__c='List';
                        temporderitem.SBQQ__ProductSubscriptionType__c = 'One-Time'; 
                        temporderitem.SBQQ__SubscriptionType__c = 'One-Time';
                        temporderitem.SBQQ__Status__c = 'Draft';   
                        temporderitem.SBQQ__SubscriptionPricing__c='Fixed Price';
                        temporderitem.PricebookEntryId = pr.Id;
                        temporderitem.blng__BillingRule__c =pr.Product2.blng__BillingRule__c; 
                        // temporderitem.blng__BillingTreatment__c = sgListBillingTreat[0].id;
                        temporderitem.blng__LegalEntity__c = ord.Account.QTB_Contract_Entity__c;
                        temporderitem.blng__RevenueRecognitionRule__c  = pr.Product2.blng__RevenueRecognitionRule__c;
                        temporderitem.blng__TaxRule__c = pr.Product2.blng__TaxRule__c;
                        // Gitlab #23142 assigning orderitem Invoice group ID field based on account split invoice flag
                        if(ordersMap.get(ord.Id).Account.QTB_Split_Invoice_Flag__c == False){
                            temporderitem.blng__InvoiceGrouping__c='Invoice Group ID';
                            temporderitem.blng__InvoiceGroupId__c=ordersMap.get(ord.id).OrderNumber;
                        }
                        else{
                            if(pr.Product2.QTB_Storage_Product__c == true){
                                temporderitem.blng__InvoiceGrouping__c = 'Invoice Group ID';
                                temporderitem.blng__InvoiceGroupId__c = ordersMap.get(ord.id).OrderNumber + '-' +'Storage' ;
                            }
                            else{
                                temporderitem.blng__InvoiceGrouping__c= 'Invoice Group ID';
                                temporderitem.blng__InvoiceGroupId__c= ordersMap.get(ord.id).OrderNumber + '-' +'Non-Storage';
                            }
                        }
                        OrderItemlst.add(temporderitem);    
                    }
                    orderIdSet.add(ord.id);
                }
                
                
                if (!OrderItemlst.isEmpty())
                {
                    insert OrderItemlst;
                    // system.debug('in Excute Records Created  OrderItems =========='+ OrderItemlst.size());
                    }
            }
            //system.debug('in Excute Records Created 11111 orders =========='+ OrderToInsert.size());
            //system.debug('in Excute Records Created 22222 =========='+ orderIdSet.size());
            
        } catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch 147>>>>>>>>>>');
            system.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className
            );
            if (!OrderToInsert.isEmpty())
            {
                Delete OrderToInsert;
                //system.debug('in Catch Records Created 11111 orders =========='+ OrderToInsert.size());
                //system.debug('in catch Records Created 22222 =========='+ orderIdSet.size());
                
            }
        }
    }
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Requirement: 
Description: No action to be taken
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        system.debug('in finish Records Created =========='+ orderIdSet.size());
        String errorIds = '';
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            } 
            if (!orderIdSet.isEmpty())
            { 
                /* //retrieve the orderItems and send it to check for Special Category product's presence (Gitlab #19786)
List<OrderItem> orderItemUpdateList = [SELECT Id,QTB_Tax_Category__c FROM OrderItem WHERE OrderId
IN :orderIdSet AND QTB_Tax_Category__c!=null];
//update special category order items with the tax rule and treatment (Gitlab #19786)
if(!orderItemUpdateList.isEmpty()){
update orderItemUpdateList = QTB_OrderProductUtils.updateMetalPaperScrapTaxTreatments(orderItemUpdateList); 
}*/
                QTB_BillOrderDraftToActBatch  bat =new QTB_BillOrderDraftToActBatch(orderIdSet,uomSet);
                Database.executeBatch(bat,50);
            }
            
            
        }   
        catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch Finish>>>>>>>>>>');
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
}