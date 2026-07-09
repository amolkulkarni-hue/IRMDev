/*****************************************************************************************************
* Class: QTB_ScheduleCSCloning
* Author: Accenture
* Purpose: This is a Queuable class calling QTB_ScheduleCSCloning
* Requirement:Git#9
* Change History: 01/02/2021
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              
*******************************************************************************************************/
global class QTB_ScheduleCSCloning implements Schedulable{
    global static boolean throwExplicitException = false;
    global Set<Id> salesOrderItemIdSet;
    global Set<String> CSAutonumberSet;
    global Map<string,OrderItem> mapOfSalesItemIdToBillItem;
    global Map<String,Order> RBMap;
    global string billAccId;
    global string event;
    global List<Order> orderList;
    global Map<Id,Id> mapOfnewASOrdertoOldOrder;
    global QTB_ScheduleCSCloning(Set<Id> salesOrderItemIdSet1,Set<String> CSAutonumberSet1,
                                Map<string,OrderItem> mapOfSalesItemIdToBillItem1,
                                Map<String,Order> RBMap1,
                                string billAccId1,
                                String event1,
								List<Order> orderList1,
                               Map<Id,Id> mapOfnewASOrdertoOldOrder1) {
            salesOrderItemIdSet=salesOrderItemIdSet1;
            CSAutonumberSet=CSAutonumberSet1;
            mapOfSalesItemIdToBillItem=mapOfSalesItemIdToBillItem1;
            RBMap=RBMap1;
            billAccId=billAccId1;
            event=event1;
	    orderList=orderList1;
         mapOfnewASOrdertoOldOrder=mapOfnewASOrdertoOldOrder1;
    }
    global void execute(SchedulableContext qc){
        try{
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSSalesList=new List<SBQQ__OrderItemConsumptionSchedule__c>();
            List<SBQQ__OrderItemConsumptionSchedule__c> OPCSBillList=new List<SBQQ__OrderItemConsumptionSchedule__c>();
            Map<Id,SBQQ__OrderItemConsumptionSchedule__c> mapOfSalesOPCSIdToBillOPCSRecord=new Map<Id,SBQQ__OrderItemConsumptionSchedule__c>();
            List<SBQQ__OrderItemConsumptionRate__c> salesOPCRList=new  List<SBQQ__OrderItemConsumptionRate__c>();
            List<SBQQ__OrderItemConsumptionRate__c> billingOPCRList=new  List<SBQQ__OrderItemConsumptionRate__c>();
            Map<Id,OrderItem> mapOfBillOrderItemIdtoRecord;           
            Set<Id> billOrderItemIdSet=new Set<Id>();
            
            //Collect all billing ids and track tax treatment and legal entity details
            if(mapOfSalesItemIdToBillItem != null){
                for(orderItem billItem:mapOfSalesItemIdToBillItem.values()){
                    billOrderItemIdSet.add(billItem.Id);
                }
                if(!billOrderItemIdSet.isEmpty()){
                    mapOfBillOrderItemIdtoRecord=new Map<Id,OrderItem>([Select id,blng__LegalEntity__c,blng__TaxTreatment__c 
                                                                    FROM OrderItem where id IN :billOrderItemIdSet]);
                }
            }
            String whereClause=' WHERE SBQQ__OrderItem__c IN :salesOrderItemIdSet AND SBQQ__ConsumptionSchedule__r.Id IN :CSAutonumberSet';
            
            //Get Order Item consumption schedule and rate object fields
            List<String> OPCSFieldsList = new List<String>(SBQQ__OrderItemConsumptionSchedule__c.SObjectType.getDescribe().fields.getMap().keySet());
            List<String> OPCRFieldsList = new List<String>(SBQQ__OrderItemConsumptionRate__c.SObjectType.getDescribe().fields.getMap().keySet());
            
            //Query sales Order Item consumption schedule and rate object records
            String qury = ' SELECT SBQQ__OrderItem__r.OrderId,SBQQ__OrderItem__r.Order.AccountId,SBQQ__OrderItem__r.Order.Opportunity.SBQQ__RenewedContract__r.SBQQ__Order__c, ' + 
                String.join( OPCSFieldsList, ',' ) + 
                ' , (SELECT SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__c, '+
                String.join(OPCRFieldsList,',')+
                ' FROM SBQQ__OrderItemConsumptionRates__r ) '+
                ' FROM SBQQ__OrderItemConsumptionSchedule__c ' + whereClause;
               
            OPCSSalesList = Database.query( qury );
            
            //Iterate over sales Order Item consumption schedule, clone and create Bill Sales Item Consumption schedule
            for(SBQQ__OrderItemConsumptionSchedule__c salesOPCS:OPCSSalesList){
                SBQQ__OrderItemConsumptionSchedule__c billOPCS=salesOPCS.clone();
                
                if(event=='Renewal'||event=='Amendment'){
                    order billOrder;
                    if(event=='Renewal')
                    	 billOrder=RBMap.get(billAccId+'_'+string.valueOf(salesOPCS.SBQQ__OrderItem__r.Order.Opportunity.SBQQ__RenewedContract__r.SBQQ__Order__c));
                    else{
                        billOrder=RBMap.get(billAccId+'_'+string.valueOf(mapOfnewASOrdertoOldOrder.get(salesOPCS.SBQQ__OrderItem__r.OrderId)));
                    }
                    if(mapOfSalesItemIdToBillItem.containsKey(string.valueOf(salesOPCS.SBQQ__OrderItem__c)+'_'+string.valueOf(billOrder.Id)))
                    {
                    billOPCS.SBQQ__OrderItem__c=mapOfSalesItemIdToBillItem.get(string.valueOf(salesOPCS.SBQQ__OrderItem__c)+'_'+string.valueOf(billOrder.Id)).Id;
                    if(mapOfBillOrderItemIdtoRecord.containsKey(mapOfSalesItemIdToBillItem.get(string.valueOf(salesOPCS.SBQQ__OrderItem__c)+'_'+string.valueOf(billOrder.Id)).Id))
                    {
                        billOPCS.blng__TaxTreatment__c=mapOfBillOrderItemIdtoRecord.get(mapOfSalesItemIdToBillItem.get(string.valueOf(salesOPCS.SBQQ__OrderItem__c)+'_'+string.valueOf(billOrder.id)).Id).blng__TaxTreatment__c;
                        billOPCS.blng__LegalEntity__c=mapOfBillOrderItemIdtoRecord.get(mapOfSalesItemIdToBillItem.get(string.valueOf(salesOPCS.SBQQ__OrderItem__c)+'_'+string.valueOf(billOrder.id)).Id).blng__LegalEntity__c;
                    }
                    }
                }else if (event=='BAcreate'){
                    if(mapOfSalesItemIdToBillItem.containsKey(string.valueOf(salesOPCS.SBQQ__OrderItem__c)))
                    {
                    billOPCS.SBQQ__OrderItem__c=mapOfSalesItemIdToBillItem.get(string.valueOf(salesOPCS.SBQQ__OrderItem__c)).Id;
                    if(mapOfBillOrderItemIdtoRecord.containsKey(billOPCS.SBQQ__OrderItem__c))
                    {
                        billOPCS.blng__TaxTreatment__c=mapOfBillOrderItemIdtoRecord.get(billOPCS.SBQQ__OrderItem__c).blng__TaxTreatment__c;
                        billOPCS.blng__LegalEntity__c=mapOfBillOrderItemIdtoRecord.get(billOPCS.SBQQ__OrderItem__c).blng__LegalEntity__c;
                    }
                    }

                }
                    billOPCS.SBQQ__UnitOfMeasure__c=null;
                    billOPCS.SBQQ__MatchingAttribute__c=null;
                    OPCSBillList.add(billOPCS); 
                    //Create Map of Sales OPCS Id to Billing OPCS Record
                    mapOfSalesOPCSIdToBillOPCSRecord.put(salesOPCS.Id,billOPCS);
                    //Collect all child Sales OPCR Records
                    if(!salesOPCS.SBQQ__OrderItemConsumptionRates__r.isEmpty())
                        salesOPCRList.addAll(salesOPCS.SBQQ__OrderItemConsumptionRates__r);
                
            }
            Set<String> failedRecordIdSet = new Set<String>();
            //Create OPCS but tax treatment will be overriden here
            if(!OPCSBillList.isEmpty())
            {            
                Database.SaveResult[] OPCSInsertSR = Database.insert(OPCSBillList,false);
                
                for (Integer i = 0; i < OPCSInsertSR.size(); i++) {
                      if (!OPCSInsertSR.get(i).isSuccess()) 
                          failedRecordIdSet.add(string.valueOf(OPCSBillList[i].SBQQ__OrderItem__c));
                    
                }
                if(!failedRecordIdSet.isEmpty()) 
                {
                    QTB_Utils.sendErrorLogMail(		//Send out email if any Billing OPCS are failed to process
                      failedRecordIdSet,
                      'Billing Order Item Consumption Schedule Creation Failed >>> Billing OrderItem Ids'
                    );             
                }
            }
            if(failedRecordIdSet.size() == 0)	//Proceed further only if OPCS failed count is zero
            {
                    //Iterate over Sales OPCR records and create Billing OPCR and connect it with Biling OPCS
                    for(SBQQ__OrderItemConsumptionRate__c salesOPCR : salesOPCRList){
                        SBQQ__OrderItemConsumptionRate__c billOPCR=salesOPCR.clone();
                        if(mapOfSalesOPCSIdToBillOPCSRecord.containsKey(salesOPCR.SBQQ__OrderItemConsumptionSchedule__c))
                            billOPCR.SBQQ__OrderItemConsumptionSchedule__c=mapOfSalesOPCSIdToBillOPCSRecord.get(salesOPCR.SBQQ__OrderItemConsumptionSchedule__c).Id;
                        billingOPCRList.add(billOPCR);               
                    }
                    if(!billingOPCRList.isEmpty())
                    {
                        Database.SaveResult[] OPCSInsertSR = Database.insert(billingOPCRList,false);
                    
                        for (Integer i = 0; i < OPCSInsertSR.size(); i++) {
                              if (!OPCSInsertSR.get(i).isSuccess()) 
                                  failedRecordIdSet.add(string.valueOf(billingOPCRList[i].SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__c));
                        }
                        if(!failedRecordIdSet.isEmpty()) 
                        {
                            QTB_Utils.sendErrorLogMail(		//Send out email if any Billing OPCR are failed to process
                              failedRecordIdSet,
                              'Billing Order Item Consumption Rate Creation Failed >>> Billing OrderItem Ids'
                            );             
                        }
                    }
                    if(failedRecordIdSet.size() == 0)
                    {
                            //Update OPCS with correct tax treatment triggers off
                            for(SBQQ__OrderItemConsumptionSchedule__c opcsBill:OPCSBillList){
                                   opcsBill.blng__TaxTreatment__c=mapOfBillOrderItemIdtoRecord.get(opcsBill.SBQQ__OrderItem__c).blng__TaxTreatment__c;
                            }
                            SBQQ.TriggerControl.disable();
                        
                            if(!OPCSBillList.isEmpty())
                            {
                                    Database.SaveResult[] OPCSUpdateSR = Database.Update(OPCSBillList,false);
                        
                                    for (Integer i = 0; i < OPCSUpdateSR.size(); i++) {
                                          if (!OPCSUpdateSR.get(i).isSuccess()) 
                                              failedRecordIdSet.add(string.valueOf(OPCSBillList[i].id));
                                    }
                                    if(!failedRecordIdSet.isEmpty()) 
                                    {
                                        QTB_Utils.sendErrorLogMail(		//Send out email if any Billing OPCS are failed to process
                                          failedRecordIdSet,
                                          'Billing Order Item Consumption Schedule update Failed >>> Billing OrderItem Ids'
                                        );                                                        
                                    }
                                    SBQQ.TriggerControl.enable();
                            }
                    }
            }
    } catch (Exception ex) {
      QTB_ExceptionLogger.createLog(
        ex.getLineNumber(),
        ex.getStackTraceString(),
        ex.getMessage(),
        ex.getTypeName(),
        'QTB_ScheduleCSCloning'
      );
    }
  }
}