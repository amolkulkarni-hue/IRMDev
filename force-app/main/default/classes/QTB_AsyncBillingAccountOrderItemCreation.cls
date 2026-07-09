Public class  QTB_AsyncBillingAccountOrderItemCreation implements Queueable{

    set<id> salesOrderIdSet;
    set<string> CSAutonumberSet;
    List<OrderItem> billingOrderItemsToInsert;
    Map<string, OrderItem> mapOfSalesItemIdToBillItem;
    Map <id,order>insertedBillingOrderMap;

    Public  QTB_AsyncBillingAccountOrderItemCreation(set<id> salesOrderIdSet,set<string> CSAutonumberSet,List<OrderItem> billingOrderItemsToInsert,
                                                        Map<string, OrderItem> mapOfSalesItemIdToBillItem ,Map<id,order> insertedBillingOrderMap)
                                                        {
                                                            this.salesOrderIdSet= salesOrderIdSet;
                                                            this.CSAutonumberSet=CSAutonumberSet;
                                                            this.billingOrderItemsToInsert=billingOrderItemsToInsert;

                                                            this.mapOfSalesItemIdToBillItem=mapOfSalesItemIdToBillItem;
                                                            this.insertedBillingOrderMap =insertedBillingOrderMap;
                                                        }

    Public void execute (QueueableContext qc)
    {

        if (!billingOrderItemsToInsert.isEmpty()) 
            {
              
              QTB_CreateBillingRecords.insertBillOrderItems(
                    billingOrderItemsToInsert,insertedBillingOrderMap
                );
            }            
            

            if (
                !salesOrderIdSet.isEmpty() &&
                !CSAutonumberSet.isEmpty() &&
                mapOfSalesItemIdToBillItem != null
              ) {
                //Schedulable class to create Billing OPCS and OPCR			
                System.schedule(
                  'CSProcessing' + System.now(),
                  QTB_RenewalBillingBatchHelper.setHoldTime(1),
                  new QTB_ScheduleCSCloning(
                    salesOrderIdSet,
                    CSAutonumberSet,
                    mapOfSalesItemIdToBillItem,
                    null,
                    null,
                    'BAcreate',
                    insertedBillingOrderMap.values(),
                    null
                  )
                );
              }
    }

    
}