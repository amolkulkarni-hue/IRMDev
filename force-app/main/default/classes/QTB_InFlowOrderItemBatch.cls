/*****************************************************************************************************
* Class:   QTB_InFlowOrderItemBatch
* Author: Virtusa
* Purpose: This is a Batch class to Create OrderItem under Billing Account (In flow)
* Requirement: 
* Change History: 
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*             01/10/2022
* Parth       03/20/2024    #22533 code changes related to Malaysia Tax increase
* VIRTUSA     04/04/2024    #22351 code changes related to Creating Order for Warehouse and Logistics
*******************************************************************************************************/
public class QTB_InFlowOrderItemBatch implements Database.Batchable<SObject>,Database.Stateful{
    
    @InvocableMethod(Label='CallQTB_InFlowOrderItemBatch' description='This method will be execute QTB_InFlowOrderItemBatch')
    public static void executeBatchMethod(List<Id> ordidlst) {
        System.debug('ExecutebatchMethod Called : '+ordidlst);
        Database.executeBatch(new QTB_InFlowOrderItemBatch(ordidlst), 1);
    } 
    Public static final string className = QTB_InFlowOrderItemBatch.class.getName();
    Public static boolean throwExplicitException = false;
    Public String query;
    Public date treatmentDate;
    Public List<Id> OrderRecordTypeId = new List<Id>();
    Public Set<Id> orderIdSet = new Set<Id>(); 
    Public Set<String> CountrySet = new Set<String>();
    Public List<ID> OrderListprcID = new List<ID>();
    Public List<pricebookentry> PriceBklst = new List<pricebookentry>(); 
    Public List<Pricebook2> SgPricebook = new List<Pricebook2>();
    Public List<blng__BillingTreatment__c> sgListBillingTreat = new List<blng__BillingTreatment__c>();
    Public List<blng__TaxTreatment__c> sgListTaxTreat = new List<blng__TaxTreatment__c>();
    //Public List<blng__LegalEntity__c> SgLegalEnity = new List<blng__LegalEntity__c>();
    Public List<Order> currntOrder = new List<Order>();
    
    Public QTB_InFlowOrderItemBatch(List<Id> currOrderID) {
        system.debug('order id--->'+currOrderID[0]);
        //21614 Added Account.shipping Country in the query for Bypassing the tax Assignment which is not having Effective dates on Treatment level
        currntOrder = [Select id,bling_Legal_Entity__c,QTB_Legal_Entity_Country__c,currencyISOCode,EffectiveDate,Account.QTB_Contract_Entity__c,Account.ShippingCountry,account.QTB_Special_Tax_Condition__c from order Where id=:currOrderID[0] LIMIT 1];
        treatmentDate = currntOrder[0].EffectiveDate.addMonths(3); //Gitlab 12238
        //QTB_Billing_Countries__c Billcust = QTB_Billing_Countries__c.getInstance(currntOrder[0].QTB_Legal_Entity_Country__c);
        orderIdSet.addAll(currOrderID);
        CountrySet.add(currntOrder[0].QTB_Legal_Entity_Country__c);
        sgListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='No Invoice Billing Treatment' LIMIT 1];
        //SgLegalEnity=[Select id, name from blng__LegalEntity__c Where blng__Country__c =:currntOrder[0].QTB_Legal_Entity_Country__c LIMIT 1];
        //#13074-Single Pricebook for Forex currency - Removal of Currency condition and addition of Active check in the query
        SgPricebook=[Select id, name,currencyISOCode from Pricebook2 Where QTB_Country__c=:currntOrder[0].QTB_Legal_Entity_Country__c and
                      IsActive = true LIMIT 1];
        
        System.debug('The pricebooktwo'+SgPricebook);
        OrderRecordTypeId.add(Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
        //#13074-Single Pricebook for Forex currency - Addition of currency and Active check in the query
        //#27187 - added Product2.IM_Product_Line__c!= 'ALM-Secure ITAD' condition for below query to stop creating SITAD Products under the Atlantic Orders
        //31228 - Added Taxcategory field
        PriceBklst=[select id, name,Product2Id,Product2.SBQQ__ChargeType__c,Product2.SBQQ__BillingFrequency__c,Product2.SBQQ__BillingType__c,Product2.blng__BillingRule__c,Product2.blng__TaxRule__c,Product2.blng__RevenueRecognitionRule__c,Product2.SBQQ__SubscriptionTerm__c,Product2.Family,Product2.ProductCode,Product2.IM_Product_Line__c,QTB_Tax_Category__c 
                    from pricebookentry where pricebook2id =:SgPricebook[0].id and CurrencyIsoCode= :currntOrder[0].CurrencyIsoCode and Product2.IM_Product_Line__c!= 'ALM-Secure ITAD' and IsActive = true];
        System.debug('thepricebookentry'+PriceBklst);
        //#22533 added custom label to check whether country is part of tax increase or not
        if(System.label.QTB_Tax_Increase_Countries.contains(currntOrder[0].QTB_Legal_Entity_Country__c)){
        sgListTaxTreat = [select id,QTB_Tax_Effective_Start_Date__c,QTB_Tax_Effective_End_Date__c,blng__taxRule__r.id from blng__TaxTreatment__c where 
                          QTB_Tax_Effective_Start_Date__c != NULL ANd  QTB_Tax_Effective_End_Date__c != NULL And 
                          QTB_Tax_Effective_Start_Date__c <= :treatmentDate And 
                          QTB_Tax_Effective_End_Date__c >= :treatmentDate And
                          blng__TaxLegalEntity__c = :currntOrder[0].Account.QTB_Contract_Entity__c And
                          QTB_Special_Tax_Condition__c = :currntOrder[0].account.QTB_Special_Tax_Condition__c And
                          blng__TaxLegalEntity__r.blng__Country__c = :currntOrder[0].QTB_Legal_Entity_Country__c LIMIT 1 ]; //Gitlab 12238 for singapore new 8% tax treatment and rule should be picked for year 2023 
        }
        //#31228 Added With Holding Applicable field on the query
        query= ' Select Id,EffectiveDate,Status,Account.W_L__c,Account.QTB_Iron_Cloud__c,Account.QTB_Withholding_Applicable__c,order.QTB_Legal_Entity_Country__c from Order where ID IN :OrderIdSet AND QTB_Legal_Entity_Country__c  IN :CountrySet AND Order.RecordtypeID IN :OrderRecordTypeId'; 
        System.debug('In Start method of QTB_InFlowOrderItemBatch '+ query); 
    }
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Iterable
Requirement: 
Description: Fetch required records
**********************************************************************************************************/
    Public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<Order>
Return Type: void
Requirement: 
Description: Creates/Updates OPCS and OPCR on order product.
**********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Order> scope) {
        String errorIds = '';
        
        try {

             System.debug('In execute method of QTB_InFlowOrderItemBatch batch  try block');
            if (throwExplicitException) {
                System.debug('NullPointer');
                throw new NullPointerException();
            }
            System.debug('pricebook id--->'+ SgPricebook[0].Id);
            List<OrderItem> OrderItemlst = new List<OrderItem>();
            For(Order ord : scope)
            { 
                For(PriceBookEntry pr : PriceBklst)
                { 
                    System.debug('PriceBook Family : '+ pr.product2.Family); 
                    System.debug('IS WL  : ' + ord.Account.W_L__c); 
                    if(!String.isEmpty(pr.Product2.SBQQ__ChargeType__c))
                    {
                        System.debug('INSIDE W&L METHOD'); 
                            System.debug('thechargetype'+pr.Product2.SBQQ__ChargeType__c);
                            OrderItem tempOrderItem = new OrderItem();
                            temporderitem.OrderId = ord.id;
                            temporderitem.Product2Id = pr.Product2.Id;
                            temporderitem.Quantity = 1;
                            temporderitem.SBQQ__BillingFrequency__c = pr.Product2.SBQQ__BillingFrequency__c;
                            temporderitem.SBQQ__BillingType__c = pr.Product2.SBQQ__BillingType__c;
                            temporderitem.SBQQ__ChargeType__c = pr.Product2.SBQQ__ChargeType__c;
                            System.debug('afterchargetype'+temporderitem.SBQQ__ChargeType__c);
                            temporderitem.SBQQ__ProductSubscriptionType__c = 'Evergreen';
                            temporderitem.SBQQ__Status__c = 'Draft';
                            temporderitem.SBQQ__SubscriptionTerm__c= pr.Product2.SBQQ__SubscriptionTerm__c;
                            temporderitem.ServiceDate = ord.EffectiveDate;
                            temporderitem.UnitPrice = 0;
                            temporderitem.blng__BillingRule__c = pr.Product2.blng__BillingRule__c;
                            temporderitem.blng__LegalEntity__c = currntOrder[0].Account.QTB_Contract_Entity__c;
                            //temporderitem.blng__LegalEntity__c = SgLegalEnity[0].id;
                            temporderitem.blng__TaxRule__c = pr.Product2.blng__TaxRule__c;
                            temporderitem.PricebookEntryId = pr.Id;
                            temporderitem.blng__RevenueRecognitionRule__c = pr.Product2.blng__RevenueRecognitionRule__c;
                            temporderitem.SBQQ__DefaultSubscriptionTerm__c = pr.Product2.SBQQ__SubscriptionTerm__c;
                            temporderitem.SBQQ__SubscriptionType__c = 'Evergreen';
                            // TempOrderItem.blng__BillingTreatment__c = sgListBillingTreat[0].id;    -----> #GITLAB/10159
                            temporderitem.blng__BillableUnitPrice__c= 0;

                        //Added by MGSB to add only product whose PPL = W&l
                        // EPIC 2262 StoryNumber 22351
                        if(ord.Account.W_L__c && pr.product2.Family == 'Warehouse and Logistics')
                        {
                            OrderItemlst.add(temporderitem);
                        }
                       else if((!ord.Account.W_L__c && pr.product2.Family !='Warehouse and Logistics') && (!ord.Account.QTB_Iron_Cloud__c && pr.product2.Family !='DM Cloud Solutions'))
                        {
                           	
                            OrderItemlst.add(temporderitem);
                        }
                        //code changes Added by MGSB ends here
                        //Added for EPIC #27091 to add only Ironcloud products
                        else if(ord.Account.QTB_Iron_Cloud__c && pr.product2.Family =='DM Cloud Solutions'){
                            OrderItemlst.add(temporderitem);
                        }
                        //#31228 Added below logic for Updation of invoice group Id and grouping based upon tax category Values for turkey Enhancement based upon 2/5 WHT
                        //For Example : On price Book Entry tax category value = 2/5 WHT then 
                        //OrderItem.blng__InvoiceGrouping__c = 'Invoice Group ID'
                        //OrderItem.blng__InvoiceGroupId__c = 2/5 WHT
                        Map<Id,String> prod2IDTaxCategoryMap = new Map<Id,String>();
                        if(temporderitem.SBQQ__ProductSubscriptionType__c != Null && temporderitem.SBQQ__ProductSubscriptionType__c == 'Evergreen' && ord.Account.QTB_Withholding_Applicable__c
                           && ord.QTB_Legal_Entity_Country__c == 'Turkey' && pr.QTB_Tax_Category__c != Null && pr.QTB_Tax_Category__c.contains('/') && temporderitem.Product2Id != Null){
                             prod2IDTaxCategoryMap.put(temporderitem.Product2Id,pr.QTB_Tax_Category__c);
                               temporderitem.blng__InvoiceGrouping__c = 'Invoice Group ID';
                               if(prod2IDTaxCategoryMap != Null && prod2IDTaxCategoryMap.containsKey(temporderitem.Product2Id)){
                                 temporderitem.blng__InvoiceGroupId__c = prod2IDTaxCategoryMap.get(temporderitem.Product2Id);
                               }
                        }
                    }  
                }
                System.debug('OrderItemlst>>>> '+OrderItemlst);
                OrderListprcID.add(ord.id);// Store all the Id's of the Orders in OrderListprcID
            }
            System.debug('OrderListprcID : '+OrderListprcID);
            if (!OrderItemlst.isEmpty())
            {
                System.debug('theorderitemlist'+OrderItemlst);
                insert OrderItemlst;
                System.debug('in Excute Records Created  OrderItems =========='+ OrderItemlst.size());
            }
            //Gitlab 12238 updating singapore tax treatment and rule
            //21614 Added Legal entity country = Account Shipping country for Bypassing the Export taxation for different countries which is not having the Effective dates on tax Treatment level
            //22533 added custom label check to check if country is part of tax increase or not
            if(!sgListTaxTreat.isEmpty() && System.label.QTB_Tax_Increase_Countries.contains(currntOrder[0].QTB_Legal_Entity_Country__c) && currntOrder[0].QTB_Legal_Entity_Country__c == currntOrder[0].Account.ShippingCountry){
                List<orderItem> taxRuleTreatmentUpdateList = new List<OrderItem>(); 
                for(OrderItem ordItm: [Select Id,QTB_Tax_Category__c from orderitem where Id in :OrderItemlst])
                {
                    //only updating orderitem where tax category is null as where tax cateogry is not null is handled by QTB_OrderProductUtils.updateTaxCategoryBasedTaxTreatments method
                    if(ordItm.QTB_Tax_Category__c == null){
                    	ordItm.blng__TaxTreatment__c = sgListTaxTreat[0].id;
                        ordItm.blng__TaxRule__c = sgListTaxTreat[0].blng__taxRule__r.id;
                        taxRuleTreatmentUpdateList.add(ordItm);
                    }  
                }
                update taxRuleTreatmentUpdateList;
            }

        } catch (exception e) {
            QTB_ExceptionLogger.enable();
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
            if (!OrderListprcID.isEmpty())
            {
                List<Order> OrderToDelete = [Select id from Order where id IN:OrderListprcID]; 
                Delete OrderToDelete;
                
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
    Public void finish(Database.BatchableContext BC) {
        
        system.debug('in finish==========');
        String errorIds = '';
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            } 
            if (!OrderListprcID.isEmpty())
            { 
                Database.executeBatch(new QTB_AddOrderProductCSCRBatch(OrderListprcID), 150);
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