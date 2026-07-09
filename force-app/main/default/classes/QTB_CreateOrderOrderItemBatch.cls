/*****************************************************************************************************
* Class:   QTB_CreateOrderOrderItemBatch
* Author: Virtusa
* Purpose: This is a Batch class to Create Order/OrderItem under Billing Account (Data load)
* Requirement: 
* Change History: 
* Developer     	Date           Description
* -------------------------------------------------------------------------------------------
*             		01/10/2022
* Parth(Virtusa)	16/04/2024     Gitlab #22533 code changes related to Malaysia Tax increase
* Parth(Virtusa)	16/04/2024	   Gitlab #23142 updating orderitem Invoice group ID field based on account split invoice flag
*******************************************************************************************************/
global class QTB_CreateOrderOrderItemBatch implements Database.Batchable<SObject>,Database.Stateful{
    global static final string className = QTB_CreateOrderOrderItemBatch.class.getName();
    global static boolean throwExplicitException = false;
    global String query;
    global Set<Id> RecordTypeIdSet = new Set<Id>();
    global List<Id> OrderRecordTypeId = new List<Id>();
    global Set<Id> orderIdSet = new Set<Id>(); 
    global Set<String> CountrySet = new Set<String>(); 
    global List<pricebookentry> PriceBklst = new List<pricebookentry>(); 
    global List<Pricebook2> SgPricebook = new List<Pricebook2>();
    global List<blng__BillingTreatment__c> sgListBillingTreat = new List<blng__BillingTreatment__c>();  
    // global List<blng__LegalEntity__c> SgLegalEnity = new List<blng__LegalEntity__c>();
    global List<blng__TaxTreatment__c> sgListTaxTreat = new List<blng__TaxTreatment__c>();
    global date treatmentDate;
    global String SourceSys;
    global Date StartDate;
    global integer RecSize;
    global List<blng__LegalEntity__c> LegEnt = new List<blng__LegalEntity__c>();
    global String AccountCurrency;
    global id legalEntity;
    global static final String EVERGREEN = 'Evergreen';
    global set<string>uomSet = new Set<string>();
    global QTB_CreateOrderOrderItemBatch(String accSourceSys,Date OrderStartdate,id legalId,String AccountCurrencyCode,Integer recds,set<string>uoms) {
        LegEnt=[Select id,CurrencyIsoCode,name,blng__Country__c from blng__LegalEntity__c where id =:legalId];
        //QTB_Billing_Countries__c Billcust = QTB_Billing_Countries__c.getInstance(LegEnt[0].blng__Country__c);
        uomSet.addAll(uoms); 
        SourceSys = accSourceSys;
        StartDate = OrderStartdate;
        treatmentDate = OrderStartdate.addMonths(3);
        RecSize = recds;
        AccountCurrency =AccountCurrencyCode;
        legalEntity = legalId;
        CountrySet.add(LegEnt[0].blng__Country__c);
        sgListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='No Invoice Billing Treatment' LIMIT 1];
        //SgLegalEnity=[Select id, name from blng__LegalEntity__c Where blng__Country__c ='Singapore' and CurrencyIsoCode='SGD' LIMIT 1];
        SgPricebook=[Select id, name,currencyIsoCode from Pricebook2 Where QTB_Country__c=:LegEnt[0].blng__Country__c
                     and IsActive = true LIMIT 1];
        OrderRecordTypeId.add(Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
        //#27187 - added Product2.IM_Product_Line__c!= 'ALM-Secure ITAD' condition for below query to stop creating SITAD Products under the Atlantic Orders
        //#31228 Added Tax Category flag in the query
        PriceBklst=[select id, name,Product2.QTB_Storage_Product__c,Product2Id,Product2.SBQQ__ChargeType__c,Product2.SBQQ__BillingFrequency__c,Product2.SBQQ__BillingType__c,Product2.blng__BillingRule__c,Product2.blng__TaxRule__c,Product2.blng__RevenueRecognitionRule__c,Product2.SBQQ__SubscriptionTerm__c,Product2.IM_Product_Line__c,QTB_Tax_Category__c from pricebookentry where pricebook2id =:SgPricebook[0].id and CurrencyIsoCode = :AccountCurrency and Product2.IM_Product_Line__c!= 'ALM-Secure ITAD' and  IsActive = true  ];
        RecordTypeIdSet.add(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId());
        //#22533 added custom label to check whether country is part of tax increase or not
        if(System.label.QTB_Tax_Increase_Countries.contains(LegEnt[0].blng__Country__c)){
            sgListTaxTreat = [select id,blng__TaxLegalEntity__c,QTB_Special_Tax_Condition__c,QTB_Tax_Effective_Start_Date__c,QTB_Tax_Effective_End_Date__c,blng__taxRule__r.id from 
                              blng__TaxTreatment__c where QTB_Tax_Effective_Start_Date__c != NULL ANd  QTB_Tax_Effective_End_Date__c != NULL 
                              And QTB_Tax_Effective_Start_Date__c <= :treatmentDate And QTB_Tax_Effective_End_Date__c >= :treatmentDate]; //gitlab 12238 to update tax treatment and rule for singapore
        }
        //#31228 Added With Holding Applicable flag in the query
        query='Select id,QTB_Split_Invoice_Flag__c,QTB_Bill_Cycle_Day__c,CurrencyIsoCode,QTB_Withholding_Applicable__c,(Select id from Orders where QTB_OrderCategory__c=:EVERGREEN and EndDate=NULL),QTB_Contract_Entity__c,QTB_Contract_Entity__r.blng__Country__c,ShippingPostalCode,ShippingState,ShippingStreet,ShippingCountry,ShippingCity,Payment_Terms__c' +
            ' from Account' +
            ' Where QTB_Contract_Entity__c  = :legalEntity AND' +
            ' QTB_Is_Parent_Billing_Account__c = False AND ' +
            ' QTB_DM_Source_System__c = :SourceSys AND' +
            ' RecordtypeID IN :RecordTypeIdSet AND CurrencyIsoCode=:AccountCurrency AND'+
            ' QTB_Source_Opportunity__c=null LIMIT :RecSize'; 
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
        List<OrderItem> OrderItemlst = new List<OrderItem>();
        Map<Id,Account>accountMap = new Map<Id,Account>();
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            }
            //
            for (Account acc : scope) 
            {  
                if(acc.Orders.size()==0) //Checking where order already created.
                {
                    Order tempOrder = new Order();
                    tempOrder.AccountId = acc.id;
                    tempOrder.CurrencyIsoCode = acc.CurrencyIsoCode; 
                    tempOrder.EffectiveDate = StartDate;
                    tempOrder.Pricebook2Id = SgPricebook[0].id;
                    tempOrder.QTB_Legal_Entity_Country__c = acc.QTB_Contract_Entity__r.blng__Country__c;
                    tempOrder.QTB_OrderCategory__c = 'Evergreen';
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
                    tempOrder.bling_Legal_Entity__c = acc.QTB_Contract_Entity__c;
                    OrderToInsert.add(tempOrder);
                    accountMap.put(acc.Id,acc);
                }
                else{
                    //Do not create any Records.
                }
            }
            if (!OrderToInsert.isEmpty())
            {
                insert OrderToInsert;
            }
            
            if (!OrderToInsert.isEmpty())
            {
                //List<OrderItem> OrderItemlst = new List<OrderItem>();
                For(Order ord : OrderToInsert)
                { 
                    
                    For(pricebookentry pr : PriceBklst)
                    { 
                        OrderItem temporderitem = new OrderItem();
                        temporderitem.OrderId = ord.id;
                        temporderitem.Product2Id = pr.Product2.Id;
                        temporderitem.Quantity = 1;
                        temporderitem.SBQQ__BillingFrequency__c = pr.Product2.SBQQ__BillingFrequency__c;
                        temporderitem.SBQQ__BillingType__c = pr.Product2.SBQQ__BillingType__c;
                        temporderitem.SBQQ__ChargeType__c = pr.Product2.SBQQ__ChargeType__c;
                        temporderitem.SBQQ__ProductSubscriptionType__c = 'Evergreen';
                        temporderitem.SBQQ__Status__c = 'Draft';
                        temporderitem.SBQQ__SubscriptionTerm__c= pr.Product2.SBQQ__SubscriptionTerm__c;
                        temporderitem.ServiceDate = StartDate;
                        temporderitem.UnitPrice = 0;
                        temporderitem.blng__BillingRule__c = pr.Product2.blng__BillingRule__c;
                        temporderitem.blng__LegalEntity__c = LegEnt[0].id;
                        //temporderitem.blng__LegalEntity__c = SgLegalEnity[0].id;
                        //temporderitem.blng__TaxRule__c = pr.Product2.blng__TaxRule__c;
                        temporderitem.PricebookEntryId = pr.Id;
                        temporderitem.blng__RevenueRecognitionRule__c = pr.Product2.blng__RevenueRecognitionRule__c;
                        temporderitem.SBQQ__DefaultSubscriptionTerm__c = pr.Product2.SBQQ__SubscriptionTerm__c;
                        temporderitem.SBQQ__SubscriptionType__c = 'Evergreen';
                        //    temporderitem.blng__BillingTreatment__c = sgListBillingTreat[0].id;
                        temporderitem.blng__BillableUnitPrice__c= 0;
                        // 23142 assigning orderitem Invoice group ID field based on account split invoice flag
                        //#31228 Added If loop for Working previous version
                        if(accountMap.get(ord.AccountId).QTB_Withholding_Applicable__c == false){
                            if(accountMap.get(ord.AccountId).QTB_Split_Invoice_Flag__c == true){
                                if(pr.Product2.QTB_Storage_Product__c == true){
                                    temporderitem.blng__InvoiceGrouping__c = 'Invoice Group ID';
                                    temporderitem.blng__InvoiceGroupId__c = 'Storage' ;
                                }
                                else{
                                    temporderitem.blng__InvoiceGrouping__c= 'Invoice Group ID';
                                    temporderitem.blng__InvoiceGroupId__c= 'Non-Storage';
                                }
                            }
                        }
                        else{
                            //#31228 For Example : Account level With Holding true and On price Book Entry tax category value = 2/5 WHT then 
                            //OrderItem.blng__InvoiceGrouping__c = 'Invoice Group ID'
                            //OrderItem.blng__InvoiceGroupId__c = 2/5 WHT
                            //And if Split Invoice flag = True then
                            //OrderItem.blng__InvoiceGrouping__c = 'Invoice Group ID'
                            //OrderItem.blng__InvoiceGroupId__c = 2/5 WHT Storage or 2/5 WHT Service
                            Map<Id,String> prod2IDTaxCategoryMap = new Map<Id,String>();
                            if(temporderitem.SBQQ__ProductSubscriptionType__c != Null && temporderitem.SBQQ__ProductSubscriptionType__c == 'Evergreen' && accountMap.get(ord.AccountId).QTB_Withholding_Applicable__c
                               && ord.QTB_Legal_Entity_Country__c == 'Turkey' && pr.QTB_Tax_Category__c != Null && pr.QTB_Tax_Category__c.contains('/') && temporderitem.Product2Id != Null){
                                   
                                   prod2IDTaxCategoryMap.put(temporderitem.Product2Id,pr.QTB_Tax_Category__c);
                                   temporderitem.blng__InvoiceGrouping__c = 'Invoice Group ID';
                                   if(accountMap.get(ord.AccountId).QTB_Split_Invoice_Flag__c){
                                       if(prod2IDTaxCategoryMap != Null && prod2IDTaxCategoryMap.containsKey(temporderitem.Product2Id)){
                                           if(pr.Product2.QTB_Storage_Product__c ==true){
                                               temporderitem.blng__InvoiceGroupId__c = prod2IDTaxCategoryMap.get(temporderitem.Product2Id) +  ' STORAGE';                                           
                                           }
                                           else {
                                               temporderitem.blng__InvoiceGroupId__c = prod2IDTaxCategoryMap.get(temporderitem.Product2Id) + ' SERVICE';
                                           }
                                           
                                       }  
                                   }
                                   else {
                                       if(prod2IDTaxCategoryMap != Null && prod2IDTaxCategoryMap.containsKey(temporderitem.Product2Id)){
                                           temporderitem.blng__InvoiceGroupId__c = prod2IDTaxCategoryMap.get(temporderitem.Product2Id);
                                       }
                                   }
                               }
                        }
                        OrderItemlst.add(temporderitem);    
                    }
                    orderIdSet.add(ord.id);
                }
                
                
                if (!OrderItemlst.isEmpty())
                {
                    insert OrderItemlst;
                    system.debug('in Excute Records Created  OrderItems =========='+ OrderItemlst.size());
                }
                
            }
            // Gitlab 12238 
            //Gitlab #22533 added custom label check to check if country is part of tax increase or not 
            if(!OrderItemlst.isEmpty() && !sgListTaxTreat.isEmpty() && System.label.QTB_Tax_Increase_Countries.contains(LegEnt[0].blng__Country__c)){
                list<orderItem> orderItemTaxUdpate = new List<orderItem>();
                for(blng__TaxTreatment__c trt :sgListTaxTreat){
                    for(OrderItem ordItm: [Select Id,blng__LegalEntity__c,order.account.QTB_Special_Tax_Condition__c,QTB_Tax_Category__c from OrderItem where id in :OrderItemlst])
                    {
                        if(trt.blng__TaxLegalEntity__c == ordItm.blng__LegalEntity__c && trt.QTB_Special_Tax_Condition__c == ordItm.order.account.QTB_Special_Tax_Condition__c && ordItm.QTB_Tax_Category__c == null){
                            ordItm.blng__TaxTreatment__c = trt.id;
                            ordItm.blng__TaxRule__c = trt.blng__taxRule__r.id;
                            orderItemTaxUdpate.add(ordItm);
                        }
                    } 
                }
                if(!orderItemTaxUdpate.isEmpty()){
                    update orderItemTaxUdpate;
                }
            }
            
            
            system.debug('in Excute Records Created 11111 orders =========='+ OrderToInsert.size());
            system.debug('in Excute Records Created 22222 =========='+ orderIdSet.size());
            
        } catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch 147>>>>>>>>>>');
            system.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.enable();
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
                system.debug('in Catch Records Created 11111 orders =========='+ OrderToInsert.size());
                system.debug('in catch Records Created 22222 =========='+ orderIdSet.size());
                
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
                QTB_BillOrderDraftToActBatch  bat =new QTB_BillOrderDraftToActBatch(orderIdSet,uomSet);
                Database.executeBatch(bat,50);
                
                
            } 
        }  
        catch (exception e) {
            QTB_ExceptionLogger.enable();
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