/*****************************************************************************************************
* Class:   QTB_AddOrderProductCSCRBatch
* Author: Virtusa
* Purpose: This is a Batch class to Create/Update ConsumptionSchedule and Rates on Orderproducts when billing account and billing order is created along with Order Products.
* Requirement: 
* Change History: 
* Developer         Date                Description
* -------------------------------------------------------------------------------------------
*                   09/21/2021
* Chandraprakash    03/31/2023      GitLab #14437 - Order should not get activate immediately, after order products inserted only it should get activate.
* Virtusa/Parth     10/04/2023      Gitlab #18748 - For Thailand, Consumption Schedule should be mapped to Product consumption schedule 
where UOM Description value is not blank (not List Rate Thailand) so that the UOM description field is populated

* Virtusa/Kalpana    02/04/2024     GitLab #22351 Getting the consumption Schedule Id from the custom label for order product consumption schedule creation if the primary product line is Warehouse & Logistics and the countries are united States and Canada.
*******************************************************************************************************/
global class QTB_AddOrderProductCSCRBatch implements Database.Batchable<SObject>,Database.Stateful
{
    @InvocableMethod(Label='CallQTB_AddOrderProductCSCRBatch' description='This method will be execute QTB_AddOrderProductCSCRBatch')
    public static void executeBatchMethod(List<Id> ordidlst) {
        Database.executeBatch(new QTB_AddOrderProductCSCRBatch(ordidlst), 200);
    } 
    
    global static final string className = QTB_AddOrderProductCSCRBatch.class.getName();
    global static boolean throwExplicitException = false;
    global String query;
    global Set<Id> orderIdSet = new Set<Id>();
    global Set<Id> RecordTypeIdSet = new Set<Id>(); 
    global Set<String> CountrySet = new Set<String>();
    global List<blng__TaxRule__c> HkListTaxRule = new List<blng__TaxRule__c>();
    global List<blng__BillingTreatment__c> opcsListBillingTreat = new List<blng__BillingTreatment__c>();      
    global QTB_AddOrderProductCSCRBatch(List<Id> currOrderID) {
        Map<String, QTB_Billing_Countries__c> CustnameMap = QTB_Billing_Countries__c.getAll();  
        Map<String, QTB_Warehouse_and_Logistics_Countries__c> warehouseCountry = QTB_Warehouse_and_Logistics_Countries__c.getAll();  //#22351 
        CountrySet.addAll(CustnameMap.keySet());
        orderIdSet.addAll(currOrderID);
        HkListTaxRule=[Select id, name from blng__TaxRule__c Where Name='No Tax Rule' LIMIT 1];
        opcsListBillingTreat=[Select id, name,blng__BillingRule__r.id,blng__BillingFinanceBook__c from blng__BillingTreatment__c Where Name='Generate Invoice Billing Treatment' LIMIT 1];
        RecordTypeIdSet.add(Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
        query=
            ' Select Id,SBQQ__Status__c,orderitemnumber,OrderID,Order.CurrencyIsoCode,blng__BillingTreatment__c,blng__TaxTreatment__c,blng__TaxRule__c,Product2.ProductCode,Product2.blng__BillingRule__c,(Select Id,name,SBQQ__OrderItem__c,blng__LegalEntity__c,blng__TaxTreatment__c from SBQQ__OrderItems__r),Product2.blng__RevenueRecognitionRule__c,Product2.blng__TaxRule__c,' +
            ' blng__LegalEntity__c,blng__LegalEntity__r.blng__Country__c,blng__TaxCountry__c,Order.Account.W_L__c from OrderItem where OrderItem.OrderID' + 
            ' IN :orderIdSet' +
            ' AND Order.RecordtypeID IN :RecordTypeIdSet'; 
        
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
    global void execute(Database.BatchableContext BC, List<orderitem> scope) {
        String errorIds = '';
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            }
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSfetchLst= new List<SBQQ__OrderItemConsumptionSchedule__c>();
            Map<ID, SBQQ__OrderItemConsumptionSchedule__c> OPCSMap  = new Map<ID, SBQQ__OrderItemConsumptionSchedule__c>();
            SBQQ__OrderItemConsumptionSchedule__c OPCSobject;
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSToUpprocess = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSToUpdate = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSToInsert = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            SBQQ__OrderItemConsumptionRate__c OPCRobject;
            List<SBQQ__OrderItemConsumptionRate__c> OPCRToInsert = new List<SBQQ__OrderItemConsumptionRate__c>();
            Integer i = 0, j= 0;
            for (OrderItem ordItem : scope) 
            { 
                if(ordItem.SBQQ__OrderItems__r.size()==0) //Checking where order product do not have already created CSCR.
                {     
                    i++;
                    System.debug('In I loop value = '+ i);
                    System.debug('In I loop ordItem = '+ ordItem);
                    OPCSobject = new SBQQ__OrderItemConsumptionSchedule__c();
                    OPCSobject.SBQQ__OrderItem__c = ordItem.Id;
                    OPCSobject.Name = 'List Rate'+ ordItem.Product2.ProductCode;
                    OPCSobject.SBQQ__BillingTerm__c= 1;
                    OPCSobject.SBQQ__Category__c='Rates';
                    OPCSobject.SBQQ__Type__c='Range';
                    OPCSobject.SBQQ__RatingMethod__c='Tier';
                    OPCSobject.SBQQ__BillingTermUnit__c='Month';
                    
                    //Below condition is checking for the Warehouse and Logistics Products and its billing countries
                    // Added By Kalpana and Modified by MGSB #22351 
                    if(ordItem.Order.Account.W_L__c)
                    {
                        if(QTB_Warehouse_and_Logistics_Countries__c.getValues(ordItem.blng__LegalEntity__r.blng__Country__c)!=NULL)
                        {
                            System.debug('Line QTB_Warehouse_and_Logistics_Countries__c.getValues control');
                            OPCSobject.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Warehouse_and_Logistics_Countries__c.getValues(ordItem.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                            OPCSobject.blng__BillingRule__c=ordItem.Product2.blng__BillingRule__c;
                        }
                    }
                    // As part of code restucturing for 22351 we have put this block for SITAD under else block.
                    else if(!ordItem.Order.Account.W_L__c)
                    {
                        //Below null condition check is added to make this batch class work for SITAD order which not comes under Billing Country >> Gitlab #13598 story
                        if(QTB_Billing_Countries__c.getValues(ordItem.blng__LegalEntity__r.blng__Country__c)!=NULL)
                        {
                            OPCSobject.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Billing_Countries__c.getValues(ordItem.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                            OPCSobject.blng__BillingRule__c=ordItem.Product2.blng__BillingRule__c;
                        }
                    } 
                    
                    
                    //Below condition is checking for the Warehouse and Logistics Products and billing country is United states or Canada
                    // Added By Kalpana #22351
                    /*else if((ordItem.blng__LegalEntity__r.blng__Country__c == 'United States'
|| ordItem.blng__LegalEntity__r.blng__Country__c =='Canada') && ordItem.Order.Account.W_L__c)
{
OPCSobject.SBQQ__ConsumptionSchedule__c = ID.valueOf(System.Label.QTB_Consumption_Schedule_ID_Warehouse_and_Logistics);
OPCSobject.blng__BillingRule__c=ordItem.Product2.blng__BillingRule__c;
}*/
                    // End of  #22351
                    OPCSobject.blng__RevenueRecognitionRule__c=ordItem.Product2.blng__RevenueRecognitionRule__c;
                    OPCSobject.blng__LegalEntity__c=ordItem.blng__LegalEntity__c;
                    OPCSobject.blng__TaxRule__c=ordItem.Product2.blng__TaxRule__c;
                    OPCSobject.blng__TaxTreatment__c = ordItem.blng__TaxTreatment__c;
                    OPCSobject.CurrencyIsoCode =ordItem.order.CurrencyIsoCode;
                system.debug('OPCSobject>>>>>>>>>'+OPCSobject);
                    OPCSToInsert.add(OPCSobject);  
                }
                else
                {
                    j++;
                    System.debug('In J loop value = '+ j);
                    System.debug('In j loop ordItem = '+ ordItem);
                    OPCSToUpprocess.addAll(ordItem.SBQQ__OrderItems__r);
                }
            }
            i = 0; j= 0;
            Integer k = 0;
            if (!OPCSToInsert.isEmpty())
            {
                insert OPCSToInsert;
                
                for (SBQQ__OrderItemConsumptionSchedule__c OPCS : OPCSToInsert) 
                { 
                    k++;
                    System.debug('In K loop value = '+ k);
                    OPCRobject = new SBQQ__OrderItemConsumptionRate__c();
                    OPCRobject.SBQQ__LowerBound__c= 1;
                    OPCRobject.SBQQ__Price__c= 0.00;
                    OPCRobject.SBQQ__PricingMethod__c='Per Unit';
                    OPCRobject.SBQQ__ProcessingOrder__c= 10;
                    OPCRobject.SBQQ__UpperBound__c= NULL;
                    OPCRobject.SBQQ__OrderItemConsumptionSchedule__c = OPCS.id;
                    OPCRobject.CurrencyIsoCode=OPCS.CurrencyIsoCode;
                    system.debug('OPCRobject>>>>>>>'+OPCRobject);
                    OPCRToInsert.add(OPCRobject); 
                    OPCSToUpprocess.add(OPCS);
                    
                }
                
            }
            if (!OPCRToInsert.isEmpty()){
                insert OPCRToInsert;
            }
            if (!OPCSToUpprocess.isEmpty())
            {  
                system.debug('OPCSToUpprocess>>>>>>>'+OPCSToUpprocess);
                for (SBQQ__OrderItemConsumptionSchedule__c OPCSTemp : OPCSToUpprocess) 
                {   
                    OPCSMap.put(OPCSTemp.id,OPCSTemp);
                }  
                OPCSfetchLst = [Select Id,name,blng__TaxRule__c,blng__LegalEntity__c,SBQQ__OrderItem__r.blng__TaxRule__c,
                                SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c,SBQQ__OrderItem__r.Product2.ProductCode,
                                SBQQ__OrderItem__r.blng__LegalEntity__c,SBQQ__OrderItem__r.blng__TaxTreatment__c,QTB_UOM_Description__c,
                                SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c,SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c,SBQQ__OrderItem__r.Order.Account.W_L__c
                                from SBQQ__OrderItemConsumptionSchedule__c WHERE ID IN : OPCSMap.keySet()];
                for (SBQQ__OrderItemConsumptionSchedule__c OPCSfetched : OPCSfetchLst) {
                    if(OPCSfetched.blng__LegalEntity__c == NULL)
                    {
                        
                        OPCSfetched.blng__LegalEntity__c = OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__c;
                        OPCSfetched.blng__TaxTreatment__c = OPCSfetched.SBQQ__OrderItem__r.blng__TaxTreatment__c;
                        //Below null condition check is added to make this batch class work for SITAD order which not comes under Billing Country >> Gitlab #13598 story
                        //Bypass this condition for Storage UoM Applicable Countries as Consumption Schedule should be mapped to Product consumption schedule where 
                        //UOM Description value is not blank Gitlab #18748
                        /*Addition of condition to check the billing country for Warehouse & Logistics Product and for Warehouse & Logistics Product 
Added By Kalpana Gitlab #22351 */
                        if((QTB_Billing_Countries__c.getValues(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c)!=NULL)
                           || (QTB_Warehouse_and_Logistics_Countries__c.getValues(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c)!=NULL
                               && OPCSfetched.SBQQ__OrderItem__r.Order.Account.W_L__c))
                        {
                            if(!System.label.Storage_UoM_Applicable_Countries.contains(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c))
                            {
                                // Below Condition to check the Warehouse and Logistics for assignment of Consumption Schedule Id 
                                // Added By Kalpana >> Gitlab #22351
                                if(OPCSfetched.SBQQ__OrderItem__r.Order.Account.W_L__c){
                                    OPCSfetched.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Warehouse_and_Logistics_Countries__c.getValues(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                                }
                                else{
                                    OPCSfetched.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Billing_Countries__c.getValues(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                                }
                                OPCSfetched.SBQQ__Description__c = 'Consumption Schedule for '+OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c+'\'s Billing Only products';
                                OPCSfetched.blng__BillingRule__c=opcsListBillingTreat[0].blng__BillingRule__r.id;
                                OPCSfetched.name = 'List Rate'+ OPCSfetched.SBQQ__OrderItem__r.Product2.ProductCode;
                                OPCSfetched.blng__FinanceBookAccounting__c=opcsListBillingTreat[0].blng__BillingFinanceBook__c;
                            }
                            //for Storage UoM Applicable Countries, Consumption Schedule should be mapped to Product consumption schedule where UOM Description value is not blank Gitlab #18748
                            else if(System.label.Storage_UoM_Applicable_Countries.contains(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c))
                            {
                                //out of the box opcs are craeted from Product consumption schedule, if UOM description field(formula field value comming from consumption schedule) is null update consumption schedule Id
                                if(OPCSfetched.QTB_UOM_Description__c == null){
                                    OPCSfetched.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Billing_Countries__c.getValues(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                                    OPCSfetched.name = 'List Rate'+ OPCSfetched.SBQQ__OrderItem__r.Product2.ProductCode;
                                }
                                OPCSfetched.SBQQ__Description__c = 'Consumption Schedule for '+OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c+'\'s Billing Only products';
                                OPCSfetched.blng__BillingRule__c=opcsListBillingTreat[0].blng__BillingRule__r.id;
                                
                            }
                        }
                        
                        //Git#11817 Country specific Tax Rule population
                        OPCSfetched.blng__TaxRule__c = OPCSfetched.SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c;
                        
                        //HK is a Tax Free country and so no tax treatment should be assigned
                        if(OPCSfetched.SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c =='Hong Kong'){
                            OPCSfetched.blng__TaxRule__c = HkListTaxRule[0].id;
                            OPCSfetched.blng__TaxTreatment__c = null;
                        }else{}
                        //
                        OPCSToUpdate.add(OPCSfetched);
                        System.debug(OPCSfetched.SBQQ__OrderItem__r.blng__LegalEntity__c+'----'+OPCSfetched.SBQQ__OrderItem__r.blng__TaxTreatment__c);
                    }
                }
            } 
            //     SBQQ.TriggerControl.disable();
            if (!OPCSToUpdate.isEmpty()){
                update OPCSToUpdate;
            } 
            //    SBQQ.TriggerControl.enable();
            
            
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            System.debug('In catch method of QTB_ADDOREDRPRODUCTCSCRBATCH ');
            System.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.enable();
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
Requirement: 
Description: No action to be taken
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        
        String errorIds = '';
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            } 
            
            List<Order> OrdersToProc = new List<Order>();
            List<Order> OrdersToUpdate = new List<Order>();
            List<OrderItem> OrdersItemsToProc = new List<OrderItem>();
            List<OrderItem> OrdersItemsToUpdate = new List<OrderItem>();
            List<blng__BillingTreatment__c> ListBillingTreat = new List<blng__BillingTreatment__c>();
            ListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='No Invoice Billing Treatment'LIMIT 1];
            //GitLab 10883
            //#22448 and #22304 As per Order Product not Activated Automatically getting below Exception  First exception on row 0 with id 802D2000002mHUaIAM; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record: [] from line 279
            //Class.QTB_AddOrderProductCSCRBatch.finish: line 279, column 1 So Added FOR UPDATE in the query to resolve that exception
            OrdersItemsToProc=[Select id,SBQQ__Status__c,blng__TaxRule__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxRule__c,blng__HoldBilling__c,blng__BillingRule__c,blng__BillingTreatment__c,QTB_Product_Name__c,order.accountId,order.QTB_OrderCategory__c,order.QTB_Legal_Entity_Country__c,order.QTB_DM_Source_System_Name__c,Order.id from OrderItem where Order.id IN:orderIdSet FOR UPDATE];
            Set<id> accountIds = new Set<Id>();
            //GitLab 10883
            if (!OrdersItemsToProc.isEmpty())
            {
                for(OrderItem orditemtemp: OrdersItemsToProc)
                { 
                    if(orditemtemp.SBQQ__Status__c =='Draft'){
                        orditemtemp.blng__HoldBilling__c='No'; 
                        orditemtemp.blng__BillingRule__c=ListBillingTreat[0].blng__BillingRule__r.id;
                        //Git#11817 Country specific Tax Rule population
                        orditemtemp.blng__TaxRule__c = orditemtemp.blng__TaxTreatment__r.blng__TaxRule__c;
                        //orditemtemp.blng__BillingTreatment__c=ListBillingTreat[0].id;    -----> #GITLAB/10159
                        //HK
                        if(orditemtemp.order.QTB_Legal_Entity_Country__c =='Hong Kong'){
                            orditemtemp.blng__TaxRule__c = HkListTaxRule[0].id;
                            
                        } else{}
                        //end HK
                        OrdersItemsToUpdate.add(orditemtemp);
                        accountIds.add(orditemtemp.order.accountId);  // //GitLab 10883
                    } 
                } 
            }  
            
            if (!OrdersItemsToUpdate.isEmpty())
            {         
                //    SBQQ.TriggerControl.disable(); //--> fix for order activation
                Update OrdersItemsToUpdate;
                //    SBQQ.TriggerControl.enable();
            }
            //GitLab 10883
            Map<Id,Account> updateTaxExempt = new  Map<Id,Account>([select id,SBQQ__TaxExempt__c from Account where id IN: accountIds ]);
            List<Account> updateAccount = new List<Account>(); 
            List<Account> updateAccountBack = new List<Account>(); 
            OrdersToProc=[Select id,status,QTB_OrderCategory__c,account.SBQQ__TaxExempt__c,AccountId from Order where ID IN:orderIdSet];
            //GitLab 10883
            if (!OrdersToProc.isEmpty())
            {
                for(Order ord: OrdersToProc)
                {
                    if(ord.QTB_OrderCategory__c!='Rebill'){
                        ord.Status='Activated'; 
                        OrdersToUpdate.add(ord);
                    }
                    ////GitLab 10883
                    if(ord.QTB_OrderCategory__c=='Ad-Hoc' && ord.account.SBQQ__TaxExempt__c=='Yes' ){
                        updateTaxExempt.get(ord.AccountId).SBQQ__TaxExempt__c='No';
                        updateAccount.add(updateTaxExempt.get(ord.AccountId));
                    }
                    //GitLab 10883  
                }
            }
            
            if (!OrdersToUpdate.isEmpty())
            {
                Update OrdersToUpdate;
            }
            ////GitLab 10883
            if(!updateAccount.isEmpty()){
                update updateAccount;
                for(Account ac:updateAccount){
                    updateTaxExempt.get(ac.Id).SBQQ__TaxExempt__c='Yes';
                    updateAccountBack.add(updateTaxExempt.get(ac.Id));
                }
            }
            
            if(!updateAccountBack.isEmpty()){
                update updateAccountBack;
            }            
            //GitLab 10883
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