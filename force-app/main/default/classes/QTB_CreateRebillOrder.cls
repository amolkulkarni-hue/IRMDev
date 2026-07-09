public with sharing class QTB_CreateRebillOrder {
    public Static void createRebillOrder(ID rebillInvoice)  {
        try {
            Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData = new Map<ID,blng__InvoiceLine__c>();
            set<ID> orderProductsIds = new set<ID>();
            ID oldOrderID ;
            Id accId;
            list<OrderItem> orderItemsListToClone =new list<OrderItem> ();
            map <ID,Order> insertedBillingOrderMap;
            Order orderToClone = new Order();
            map<id,orderitem> mapOfOldOrderItemToNewOrderItem = new map<id,orderitem>();
            Date startDate,endDate;
            list<OrderItem> billingOrderItemsToInsert =new list<OrderItem> ();
            Map<ID,blng__InvoiceLine__c> invoiceLineDataMap;
            //set<String> minimumProducts= new set<String>{LABEL.QTB_Minimum_Storage, LABEL.QTB_Invoice_Minimum};
                if(rebillInvoice != null){
                    invoiceLineDataMap = new Map<ID,blng__InvoiceLine__c>
                        ([select id,blng__Subtotal__c,QTB_HasConsumptionSchedule__c,blng__ChargeType__c,blng__Product__c,blng__StartDate__c,blng__EndDate__c,blng__Invoice__r.blng__Account__c,
                          blng__OrderProduct__c,blng__Quantity__c,blng__OrderProduct__r.OrderID,blng__Product__r.ProductCode from blng__InvoiceLine__c
                          where blng__Invoice__c =:rebillInvoice]);
                    
                    
                    if(!invoiceLineDataMap.isEmpty() && invoiceLineDataMap !=null) {  
                        for(blng__InvoiceLine__c invLine:invoiceLineDataMap.values()) {
                            if(invLine.QTB_HasConsumptionSchedule__c == true && 
                               (invLine.blng__Product__r.ProductCode != '02100-0003' && invLine.blng__Product__r.ProductCode !='01100-0061')) {
                                   orderProductsIds.add(invLine.blng__OrderProduct__c);                            
                               } else if(invLine.QTB_HasConsumptionSchedule__c == false){
                                   orderProductsIds.add(invLine.blng__OrderProduct__c);
                                   mapOfRecurringNonUsageData.put(invLine.blng__Product__c,invLine);                            
                               }
                            startDate= invLine.blng__StartDate__c;
                            endDate= invLine.blng__EndDate__c;
                            oldOrderID = invLine.blng__OrderProduct__r.OrderID;
                            accId=invLine.blng__Invoice__r.blng__Account__c;
                        }
                        
                        orderProductsIds.addAll((new map<id,orderitem>([select id from orderitem where order.AccountId= :accId and Product2.ProductCode = :LABEL.QTB_Minimum_Storage and QTB_PrefixMatchingID__c = null
                                                                        limit 1 ])).keyset());
                        orderProductsIds.addAll((new map<id,orderitem>([select id from orderitem where order.AccountId= :accId and Product2.ProductCode = :LABEL.QTB_Invoice_Minimum and QTB_PrefixMatchingID__c = null
                                                                        limit 1  ])).keyset());
                   }
                    
                    List<String> orderFieldsList = new List<String>(
                        Order.SObjectType.getDescribe().fields.getMap().keySet()
                    );
                    List<String> ordItemFieldsList = new List<String>(
                        OrderItem.SObjectType.getDescribe().fields.getMap().keySet()
                    );
                    
                    String queryOrder =' SELECT ' + String.join(orderFieldsList, ',') +' from Order where ID= :oldOrderID ';
                    String queryOrderItems = ' SELECT ' + String.join(ordItemFieldsList, ',') +' from Orderitem where ID in:orderProductsIds ';
                    String prefixMatchingID;
                    Order newRebillOrder;
                    orderItemsListToClone = Database.query(queryOrderItems);
                    
                    
                    orderToClone = (order) Database.query(queryOrder).get(0);
                    //System.debug(orderToClone);
                    if(orderToClone !=null){
                        newRebillOrder = new Order();
                        newRebillOrder =orderToClone.clone();
                        newRebillOrder.Status = QTB_Constants.DRAFT_STATUS;
                        newRebillOrder.Type ='New';
                        newRebillOrder.QTB_OrderCategory__c='Rebill';
                        newRebillOrder.QTB_Order_OriginatorId__c = null;
                        newRebillOrder.QTB_PrevBillingOrder__c = null;
                        newRebillOrder.EffectiveDate =startDate;
                        newRebillOrder.QTB_OriginalRebillInvoice__c=rebillInvoice;
                        
                        //SBQQ.TriggerControl.disable(); //No to trigger any package logic
                        insert newRebillOrder;
                        // SBQQ.TriggerControl.enable();
                        insertedBillingOrderMap = new map <ID,Order>{newRebillOrder.Id=>newRebillOrder};        
                            
                            prefixMatchingID= [Select id, OrderNumber from Order where id= :newRebillOrder.id].get(0).OrderNumber;
                        
                        if(!orderItemsListToClone.isEmpty() && newRebillOrder!=null && !insertedBillingOrderMap.isEmpty() && prefixMatchingID != null
                            && rebillInvoice!=null && startDate!=null && endDate!=null )
                        {
                            System.enqueueJob(new QTB_QueueableOrderItemCreation(orderItemsListToClone,newRebillOrder,insertedBillingOrderMap,prefixMatchingID,
                                                                                 mapOfRecurringNonUsageData,rebillInvoice,startDate,endDate));
                        }
                        
                    }  
                }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_CreateRebillOrder'
            );
            throw e;
        }
    }
    
    
}