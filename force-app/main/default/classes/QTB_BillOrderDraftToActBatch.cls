/*****************************************************************************************************
* Class:   QTB_BillOrderDraftToActBatch
* Author: Virtusa
* Purpose: This is a Batch class to Activate and update billing order/OrderItems.
*  where status is Draft (For 9 Billing only Countries).
* Requirement: 
* Change History: 
* Developer     	Date           Description
* -------------------------------------------------------------------------------------------
*             		11/12/2021
* Parth(Virtusa)	19/10/2023		Gitlab #19116 - For Thailand, Consumption Schedule should be mapped to Product consumption schedule 
where UOM Description value is not blank (not List Rate Thailand) so that the UOM description field is populated
*******************************************************************************************************/
global class QTB_BillOrderDraftToActBatch implements Database.Batchable<SObject>,Database.Stateful
{
    global static final string className = QTB_BillOrderDraftToActBatch.class.getName();
    global static boolean throwExplicitException = false;
    global String query; 
    global Set<Id> RecordTypeIdSet = new Set<Id>();  
    global Set<Id> orderIdSet = new Set<Id>();
    global Set<Id> orderIdSetAsParam = new Set<Id>();
    global Set<String> CountrySet = new Set<String>();
    global   List<blng__BillingTreatment__c> ListBillingTreat = new List<blng__BillingTreatment__c>();
    global List<Order> currntOrder = new List<Order>();
    global List<blng__TaxRule__c> HkListTaxRule = new List<blng__TaxRule__c>();
    global List<blng__BillingTreatment__c> opcsListBillingTreat = new List<blng__BillingTreatment__c>();
    global set<string> uomSet = new Set<String>();
    global QTB_BillOrderDraftToActBatch(Set<Id> OrderToProcessID,set<string>uom) {
        currntOrder = [Select id,bling_Legal_Entity__c,QTB_Legal_Entity_Country__c from order Where id IN:OrderToProcessID LIMIT 1];
        orderIdSetAsParam.addAll(OrderToProcessID);
        uomSet.addAll(uom);
        ListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='No Invoice Billing Treatment' LIMIT 1];
        opcsListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='Generate Invoice Billing Treatment' LIMIT 1];
        RecordTypeIdSet.add(Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
        //QTB_Billing_Countries__c Billcust = QTB_Billing_Countries__c.getInstance(currntOrder[0].QTB_Legal_Entity_Country__c);
        CountrySet.add(currntOrder[0].QTB_Legal_Entity_Country__c);
        HkListTaxRule=[Select id, name from blng__TaxRule__c Where Name='No Tax Rule' LIMIT 1];    
        query=
            ' Select Id,name,blng__LegalEntity__c,QTB_UOM_Description__c,SBQQ__OrderItem__r.Product2.ProductCode,SBQQ__OrderItem__r.Product2.QTB_Storage_Product__c,SBQQ__UnitOfMeasure__c,' +
            ' SBQQ__OrderItem__r.blng__LegalEntity__c,SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c,SBQQ__OrderItem__r.blng__TaxTreatment__c,SBQQ__OrderItem__r.Order.id,SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c,SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c ' +
            ' FROM SBQQ__OrderItemConsumptionSchedule__c where' +
            ' SBQQ__OrderItem__r.Order.Status=\''+QTB_Constants.DRAFT_STATUS+'\' AND ' + 
            ' SBQQ__OrderItem__r.Order.QTB_Legal_Entity_Country__c IN :CountrySet AND' +
            ' SBQQ__OrderItem__r.Order.id IN : orderIdSetAsParam AND' +
            ' SBQQ__OrderItem__r.Order.RecordTypeID IN :RecordTypeIdSet'; 
        system.debug('In execute method of batch>>>>>>>>>>1111111111111'+ query);
    }    
    /*********************************************************************************************************
//' SBQQ__OrderItem__r.Order.CreatedDate  >= TODAY  AND ' +
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
Parameters: Database.BatchableContext,List<Order>
Return Type: void
Requirement: 
Description: Update the  OPCS on order productAnd To Activate billing order where status is Draft.
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<SBQQ__OrderItemConsumptionSchedule__c> scope) {
        system.debug('In execute method of batch>>>>>>>>>>1111111111111');
        String errorIds = '';
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            }
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSToUpdate = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            Set<Id> orderItemIdSet = new Set<Id>();
            list<SBQQ__OrderItemConsumptionSchedule__c>opcsToDelete = new List<SBQQ__OrderItemConsumptionSchedule__c>();
            for (SBQQ__OrderItemConsumptionSchedule__c OPCSTemp : Scope) 
            {  
                orderIdSet.add(OPCSTemp.SBQQ__OrderItem__r.Order.id);
                orderItemIdSet.add(OPCSTemp.SBQQ__OrderItem__r.id);
                if(OPCSTemp.blng__LegalEntity__c == NULL)
                {
                    if(!uomSet.isEmpty() && OPCSTemp.SBQQ__UnitOfMeasure__c != null && !uomSet.contains(OPCSTemp.SBQQ__UnitOfMeasure__c) && OPCSTemp.SBQQ__OrderItem__r.Product2.QTB_Storage_Product__c ){
                        opcsToDelete.add(OPCSTemp);
                    }
                    else{
                        //OPCSTemp.name = 'List Rate'+ OPCSTemp.SBQQ__OrderItem__r.Product2.ProductCode;
                        OPCSTemp.blng__LegalEntity__c = OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__c;
                        OPCSTemp.blng__TaxTreatment__c = OPCSTemp.SBQQ__OrderItem__r.blng__TaxTreatment__c;
                        OPCSTemp.blng__TaxRule__c = OPCSTemp.SBQQ__OrderItem__r.blng__TaxTreatment__r.blng__TaxRule__c;
                        if(QTB_Billing_Countries__c.getValues(OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c)!=NULL){
                            //Above if condition is added as part of Gitlab #12783 story
                            if(!system.label.Storage_UoM_Applicable_Countries.contains(OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c)){
                                //Bypass this condition for Storage UoM Applicable Countries as Consumption Schedule should be mapped to Product consumption schedule where 
                                //UOM Description value is not blank Gitlab #19116
                                OPCSTemp.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Billing_Countries__c.getValues(OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                                OPCSTemp.SBQQ__Description__c = 'Consumption Schedule for '+OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c+'\'s Billing Only products';
                                OPCSTemp.blng__BillingRule__c=opcsListBillingTreat[0].blng__BillingRule__r.id;
                                OPCSTemp.name = 'List Rate'+ OPCSTemp.SBQQ__OrderItem__r.Product2.ProductCode;
                                //OPCSTemp.blng__FinanceBookAccounting__c=opcsListBillingTreat[0].blng__BillingFinanceBook__c;
                            }
                            //for Storage UoM Applicable Countries, Consumption Schedule should be mapped to Product consumption schedule where UOM Description value is not blank Gitlab #19116
                            else if(system.label.Storage_UoM_Applicable_Countries.contains(OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c))
                            {
                                //out of the box opcs are craeted from Product consumption schedule, if UOM description field(formula field value comming from consumption schedule) is null update consumption schedule Id
                                if(OPCSTemp.QTB_UOM_Description__c == null){
                                    OPCSTemp.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Billing_Countries__c.getValues(OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                                    OPCSTemp.name = 'List Rate'+ OPCSTemp.SBQQ__OrderItem__r.Product2.ProductCode;
                                }
                                OPCSTemp.SBQQ__Description__c = 'Consumption Schedule for '+OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c+'\'s Billing Only products';
                                OPCSTemp.blng__BillingRule__c=opcsListBillingTreat[0].blng__BillingRule__r.id;
                                
                            }
                            //OPCSTemp.SBQQ__ConsumptionSchedule__c = ID.valueOf(QTB_Billing_Countries__c.getValues( OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c).ConsumptionScheduleID__c);
                            //OPCSTemp.SBQQ__Description__c = 'Consumption Schedule for '+ OPCSTemp.SBQQ__OrderItem__r.blng__LegalEntity__r.blng__Country__c+'\'s Billing Only products';
                            //OPCSTemp.blng__BillingRule__c=opcsListBillingTreat[0].blng__BillingRule__r.id;
                        } // if condition ends
                        
                        //HK
                        if( OPCSTemp.SBQQ__OrderItem__r.order.QTB_Legal_Entity_Country__c =='Hong Kong'){
                            OPCSTemp.blng__TaxRule__c = HkListTaxRule[0].id;
                            OPCSTemp.blng__TaxTreatment__c = null;
                        }else{}
                        //
                        OPCSToUpdate.add(OPCSTemp);
                    }
                }
            }
            system.debug('In Exucute batch To update >>>>>>>>>>'+ OPCSToUpdate.size());
            //    SBQQ.TriggerControl.disable();
            delete opcsToDelete;
            if (!OPCSToUpdate.isEmpty())
            {
                Update OPCSToUpdate;
            }
            //     SBQQ.TriggerControl.enable();
            ///
            List<OrderItem> OrdersItemsToProc = new List<OrderItem>(); 
            List<OrderItem> OrdersItemsToUpdate = new List<OrderItem>();  
            OrdersItemsToProc=[Select id,SBQQ__Status__c,blng__HoldBilling__c,blng__BillingRule__c,blng__BillingTreatment__c,order.QTB_Legal_Entity_Country__c,blng__TaxTreatment__r.blng__TaxRule__c from OrderItem where ID IN:orderItemIdSet];
            if (!OrdersItemsToProc.isEmpty())
            {
                for(OrderItem orditemtemp: OrdersItemsToProc)
                { 
                    System.debug('---***'+orditemtemp.SBQQ__Status__c);
                    if(orditemtemp.SBQQ__Status__c =='Draft'){
                        orditemtemp.blng__HoldBilling__c='No'; 
                        orditemtemp.blng__BillingRule__c=ListBillingTreat[0].blng__BillingRule__r.id;
                        orditemtemp.blng__TaxRule__c = orditemtemp.blng__TaxTreatment__r.blng__TaxRule__c;
                        //orditemtemp.blng__BillingTreatment__c=ListBillingTreat[0].id;
                        //HK
                        if(orditemtemp.order.QTB_Legal_Entity_Country__c =='Hong Kong'){
                            orditemtemp.blng__TaxRule__c = HkListTaxRule[0].id;
                            
                        } 
                        //end HK
                        OrdersItemsToUpdate.add(orditemtemp);
                    }
                }  
            }  
            
            if (!OrdersItemsToUpdate.isEmpty())
            {
                Update OrdersItemsToUpdate;
            }
            //
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch 75>>>>>>>>>>');
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
Requirement: 
Description: No action to be taken
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        system.debug('in finish==========');
        String errorIds = '';
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            } 
            if (!orderIdSet.isEmpty())
            { 
                QTB_PostUpBillOrderDraftToActBatch  batchAc =new QTB_PostUpBillOrderDraftToActBatch(orderIdSet);
                Database.executeBatch(batchAc,10); 
            }
            
            
        }   
        catch (exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch Finish>>>>>>>>>>');
            system.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),errorIds,e.getTypeName(),className );
        }         
        
    }
}