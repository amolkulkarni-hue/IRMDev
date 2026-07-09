Global class QTB_QueuableRebillOrderCS implements Queueable {
    
    global map<Id, orderitem> mapOfOldOrderItemToNewOrderItem = new map<Id, orderitem>();
    global String orderNumber;
    global Id rebilledInvoiceId;
    global Order newRebillOrder =new Order();
    Global  QTB_QueuableRebillOrderCS (map<id,orderitem> mapoldItemToNewItem, String prefixMatchingID ,Id rebillInvoice,order newOrder)
    {
        mapOfOldOrderItemToNewOrderItem=mapoldItemToNewItem;
        orderNumber=prefixMatchingID;
        rebilledInvoiceId=rebillInvoice;
        newRebillOrder=newOrder;
    }
    
    global void execute(QueueableContext qc) 
    {
        
        list<SBQQ__OrderItemConsumptionSchedule__c> oldOrdProdCSList= new list<SBQQ__OrderItemConsumptionSchedule__c>();
        List<SBQQ__OrderItemConsumptionRate__c> oldOrdProdCRatesList=new  List<SBQQ__OrderItemConsumptionRate__c>();
        
        list<SBQQ__OrderItemConsumptionSchedule__c> newOrdProdCSList= new list<SBQQ__OrderItemConsumptionSchedule__c>();
        List<SBQQ__OrderItemConsumptionRate__c> newOrdProdCRatesList=new  List<SBQQ__OrderItemConsumptionRate__c>();
        String rebillInvoiceNumber;
        map<Id,SBQQ__OrderItemConsumptionSchedule__c>mapOfOldOPCSIdToNewOPCSRecord = new map<Id,SBQQ__OrderItemConsumptionSchedule__c>();
        
        set<Id> oldOrderItemIDs= new set<id>(mapOfOldOrderItemToNewOrderItem.keySet());
        Set<Id> newOrderItemsIds = new set<Id>();
        try
        {
            rebillInvoiceNumber = [select id, QTB_Custom_Invoice_Number__c from blng__invoice__c where id = :rebilledInvoiceId].get(0).QTB_Custom_Invoice_Number__c;
            //SYstem.debug(rebillInvoiceNumber);    
            for(orderitem item:mapOfOldOrderItemToNewOrderItem.values())
            {
                newOrderItemsIds.add(item.id);
            }
            map<id,orderitem>mapOfIdToNewOrderItems = new map<id,orderitem>([Select id,blng__TaxTreatment__c from orderitem 
                                                                             where id in:newOrderItemsIds]);
            //Get Order Item consumption schedule and rate object fields
            List<String> OPCSFieldsList = new List<String>(SBQQ__OrderItemConsumptionSchedule__c.SObjectType.getDescribe().fields.getMap().keySet());
            List<String> OPCRFieldsList = new List<String>(SBQQ__OrderItemConsumptionRate__c.SObjectType.getDescribe().fields.getMap().keyset());
            
            //Query old Order Item consumption schedule and rate object records
            String qury = ' SELECT ' + 
                String.join( OPCSFieldsList, ',' ) + 
                ' , (SELECT  '+
                String.join(OPCRFieldsList,',')+
                ' FROM SBQQ__OrderItemConsumptionRates__r ) '+
                ' FROM SBQQ__OrderItemConsumptionSchedule__c  where SBQQ__OrderItem__c IN :oldOrderItemIDs' ;
            
            oldOrdProdCSList =  Database.query( qury );
            if(!oldOrdProdCSList.isEmpty())
            {
                for(SBQQ__OrderItemConsumptionSchedule__c oldOPCS :oldOrdProdCSList)
                {
                    SBQQ__OrderItemConsumptionSchedule__c newOPCS= oldOPCS.clone();
                    newOPCS.SBQQ__OrderItem__c = mapOfOldOrderItemToNewOrderItem.get(oldOPCS.SBQQ__OrderItem__c).Id;
                    newOrdProdCSList.add(newOPCS);
                    
                    
                    //Create Map of old OPCS Id to New OPCS Record
                    mapOfOldOPCSIdToNewOPCSRecord.put(oldOPCS.Id,newOPCS);
                    //Collect all child Old OPCR Records
                    if(!oldOPCS.SBQQ__OrderItemConsumptionRates__r.isEmpty())
                    {oldOrdProdCRatesList.addAll(oldOPCS.SBQQ__OrderItemConsumptionRates__r);}
                }
                
                
                if(!newOrdProdCSList.isEmpty())
                {
                    insert newOrdProdCSList;
                    // System.debug('insert cs+'+newOrdProdCSList);
                }
                
                if(!oldOrdProdCRatesList.isEmpty())
                {
                    for(SBQQ__OrderItemConsumptionRate__c oldOPCRate: oldOrdProdCRatesList)
                    {
                        SBQQ__OrderItemConsumptionRate__c newOPCRate = oldOPCRate.clone();
                        newOPCRate.SBQQ__OrderItemConsumptionSchedule__c = mapOfOldOPCSIdToNewOPCSRecord.get(oldOPCRate.SBQQ__OrderItemConsumptionSchedule__c).id;
                        newOrdProdCRatesList.add(newOPCRate);
                    }
                    
                    if(!newOrdProdCRatesList.isEmpty())
                    {
                        insert newOrdProdCRatesList;
                    }
                }
                
                //Update OPCS with correct tax treatment triggers off
                for(SBQQ__OrderItemConsumptionSchedule__c newOPCS:newOrdProdCSList){
                    newOPCS.blng__TaxTreatment__c=mapOfIdToNewOrderItems.get(newOPCS.SBQQ__OrderItem__c).blng__TaxTreatment__c;
                }
                
                if(!newOrdProdCSList.isEmpty())
                {
                    SBQQ.TriggerControl.disable();
                    update newOrdProdCSList;
                    SBQQ.TriggerControl.enable();            
                    
                }
                
                
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_QueuableRebillOrderCS'
            );
            throw e;
        }
        
        
        list <QTB_RebillEventDetail__e> rebillDataEvent = new list <QTB_RebillEventDetail__e>();
        
        rebillDataEvent.add(new QTB_RebillEventDetail__e(QTB_RebilledInvoiceNo__c=rebillInvoiceNumber, QTB_NewOrderNumber__c=orderNumber));       
        
        
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(rebillDataEvent);
        
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                                 err.getStatusCode() +
                                 ' - ' +
                                 err.getMessage());
                }
            }       
        }
    }
    
}