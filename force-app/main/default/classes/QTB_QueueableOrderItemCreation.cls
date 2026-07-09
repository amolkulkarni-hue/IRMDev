global class QTB_QueueableOrderItemCreation implements Queueable {
    public static Boolean doChainJob = true;
    global list<OrderItem> orderItemsListToClone =new list<OrderItem> ();
    global  Order newRebillOrder = new Order();
    global map <ID,Order> insertedBillingOrderMap =new map <ID,Order>();
    global String prefixMatchingID;
    Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData =new  Map<ID,blng__InvoiceLine__c>();
    ID rebillInvoice;
    Date startDate;  
    Date endDate;
    //set<String> minimumProducts;

    global QTB_QueueableOrderItemCreation(list<OrderItem> orderItemsListToClone, Order newRebillOrder,map <ID,Order> insertedBillingOrderMap,
                                          String prefixMatchingID,map <ID,blng__InvoiceLine__c>mapOfRecurringNonUsageData,
                                          ID rebillInvoice,DAte startDate,DAte endDate)
    {
        this.orderItemsListToClone=orderItemsListToClone;
        this.newRebillOrder=newRebillOrder;
        this.insertedBillingOrderMap=insertedBillingOrderMap;
        this.prefixMatchingID = prefixMatchingID;
        This.mapOfRecurringNonUsageData = mapOfRecurringNonUsageData;
        this.rebillInvoice = rebillInvoice;
        this.startDate = startDate;
        this.endDate = endDate;
        //this.minimumProducts = minimumProducts;
        
    }
       
    /***********************************************************************************************************
* Method : execute
* Parameters:QueueableContext
* Return type: Void
* Requirement : Gitlab#1732
* Start Date : 1/4/2020
* Author : Accenture
* Description: manipulate, insert order item and  to call another queuable class to create consumption schedules
* Event: 
**************************************************************************************************************/
    
    global void execute (QueueableContext qc)
    {
        map<id,orderitem> mapOfOldOrderItemToNewOrderItem = new map<id,orderitem>();
        list<OrderItem> billingOrderItemsToInsert =new list<OrderItem> ();
        
       // List<PricebookEntry> minPriceBookEntryList= [select Id, product2.ProductCode,Product2.SBQQ__SubscriptionTerm__c,Product2Id,
        //                                            CurrencyIsoCode, UnitPrice  from PricebookEntry where product2.ProductCode in: minimumProducts
         //                                            and Pricebook2.QTB_Country__c = :newRebillOrder.QTB_Legal_Entity_Country__c and IsActive =true]; 

        if(!orderItemsListToClone.isEmpty())
        {
            for(orderitem ord : orderItemsListToClone )
            {
                orderItem tempOrdItem =new orderItem();
                tempOrdItem = manipulateOrderItems(ord,newRebillOrder,mapOfRecurringNonUsageData,startDate,endDate,prefixMatchingID);
                if(tempOrdItem != Null)
                {
                    billingOrderItemsToInsert.add(tempOrdItem);
                    mapOfOldOrderItemToNewOrderItem.put(ord.Id,tempOrdItem);
                }
            }        
           // billingOrderItemsToInsert.addAll( createMinimumOrderItems(minimumProducts,minPriceBookEntryList,billingOrderItemsToInsert));
            
            if(!billingOrderItemsToInsert.isEmpty() && !insertedBillingOrderMap.isEmpty())
            {
                insertReBillOrderItems(billingOrderItemsToInsert,insertedBillingOrderMap);
            }
        }
        SYstem.debug(newRebillOrder);
        Order updateOrder = new Order(id=newRebillOrder.id,blng__InvoiceBatch__c ='Rebill Run');
        update updateOrder;
        
        if(!mapOfOldOrderItemToNewOrderItem.isEmpty() && mapOfOldOrderItemToNewOrderItem !=null && doChainJob) 
        {        System.enqueueJob(new QTB_QueuableRebillOrderCS(mapOfOldOrderItemToNewOrderItem,prefixMatchingID,
                                                                 rebillInvoice,newRebillOrder));
        }
    }
    
       /***********************************************************************************************************
* Method : manipulateOrderItems
* Parameters:orderitem,Order, Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData, Date,
  			 Date , String 
* Return type: Void
* Requirement : Gitlab#1732
* Start Date : 1/4/2020
* Author : Accenture
* Description: manipulate, insert order item and  to call another queuable class to create consumption schedules
* Event: 
**************************************************************************************************************/
    
     Public static orderitem manipulateOrderItems(
        orderitem sourceOrderItem, 
        Order newRebillOrder,
        Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData,
        Date startDate, Date endDate, String prefixMatchingID)
    {
        OrderItem billingOrderItem = new OrderItem();
        try {
            billingOrderItem = sourceOrderItem.clone();
            billingOrderItem.SBQQ__Status__c = QTB_Constants.DRAFT_STATUS;
            billingOrderItem.QTB_Ready_Activation__c=false;
            billingOrderItem.SBQQ__Activated__c=false;
            billingOrderItem.SBQQ__Activated__c = false;
            billingOrderItem.SBQQ__Contracted__c = false;
            billingOrderItem.OrderId = newRebillOrder.Id;
            billingOrderItem.QTB_PrefixMatchingID__c = prefixMatchingID;
            billingOrderItem.SBQQ__QuoteLine__c = null;
            billingOrderItem.SBQQ__Contract__c = null;
            billingOrderItem.SBQQ__SubscriptionType__c = 'Renewable';
            billingOrderItem.SBQQ__ProductSubscriptionType__c = 'Renewable';
            billingOrderItem.ServiceDate=startDate;
            billingOrderItem.EndDate =endDate;
            billingOrderItem.SBQQ__SubscriptionTerm__c = null;
            If(mapOfRecurringNonUsageData.containsKey(billingOrderItem.Product2Id))
            {
                billingOrderItem.UnitPrice = mapOfRecurringNonUsageData.get(billingOrderItem.Product2Id).blng__Subtotal__c;
                billingOrderItem.Quantity =1;
                billingOrderItem.SBQQ__OrderedQuantity__c=1;
                
            }         
            billingOrderItem.SBQQ__ProrateMultiplier__c = 1;
            billingOrderItem.SBQQ__Subscription__c = null;
            billingOrderItem.blng__PendingBillings__c = null;
            billingOrderItem.blng__CanceledBillings__c = null;
            billingOrderItem.blng__TerminatedBillings__c = null;
            billingOrderItem.SBQQ__QuotedListPrice__c = null;
            billingOrderItem.SBQQ__QuotedQuantity__c = null;
            billingOrderItem.blng__InvoiceRun__c=null;
            billingOrderItem.blng__InvoiceRunStartDate__c =null;
            if(billingOrderItem.QTB_OriginalConsumptionID__c == null)
            {
                billingOrderItem.blng__InvoiceRunProcessingStatus__c ='Pending Billing';
                billingOrderItem.blng__InvoiceRunStatusIndex__c ='Pending Billing';
            }
            billingOrderItem.SBQQ__TerminatedDate__c=null;
            billingOrderItem.blng__LegalEntity__c =null;
            billingOrderItem.blng__TaxTreatment__c = null;
            billingOrderItem.blng__TaxCountry__c=null;
            billingOrderItem.blng__BilledTax__c =null;
            billingOrderItem.blng__BilledAmountwithouttax__c=null;
            billingOrderItem.SBQQ__BookingsIndicator__c ='Include';
            billingOrderItem.blng__LastChargeToDate__c = null;
            billingOrderItem.blng__LastInvoiceTargetDate__c =null;
            billingOrderItem.blng__NextChargeDate__c =null;
            billingOrderItem.blng__NextBillingDate__c = null;
            
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_QueueableOrderItemCreation'
            );
            throw e;
        }        
        return billingOrderItem;
    }

      
    
    /***********************************************************************************************************
* Method : insertReBillOrderItems
* Parameters: List<OrderItem>,Map<Id,Order>
* Return type: Void
* Requirement : Gitlab#1732
* Start Date : 1/4/2020
* Author : Accenture
* Description: Insert Bill Order Item Records
* Event: 
**************************************************************************************************************/
    public static void insertReBillOrderItems(
        List<OrderItem> billingOrderItemsToInsert, Map<Id,Order> insertedBillingOrderMap
    ) {
        try {
            
            SBQQ.TriggerControl.disable(); //Not to trigger any package logic to create extra consumption scheudles
            
            
            insert billingOrderItemsToInsert;
            SBQQ.TriggerControl.enable();
            list <orderItem> updateRenewableOrderItemList = new List<OrderItem>();
            list <orderItem> updateOldRenewableOrderItemList = new List<OrderItem>();
            
            list <orderItem> updateEvergreenOrderItemList = new List<OrderItem>();
            
            for (orderItem billItem : billingOrderItemsToInsert) {
                // to re-run pacakge validation for the evergreen order products
                if(insertedBillingOrderMap.containsKey(billItem.OrderID ) && insertedBillingOrderMap.get(billItem.OrderID).QTB_OrderCategory__c=='Evergreen')
                {
                    orderitem ordEvItem= new orderitem();
                    ordEvItem.Id = billItem.Id;
                    ordEvItem.EndDate = null;
                    updateEvergreenOrderItemList.add(ordEvItem);                    
                }
                // to re-run pacakge validation for the renewable/one time order products
                else if (insertedBillingOrderMap.containsKey(billItem.OrderID ))
                {
                    System.debug('fixing next billing date');
                    orderitem ordItem= new orderitem();
                    ordItem.Id = billItem.Id;
                    ordItem.SBQQ__BillingFrequency__c=billItem.SBQQ__BillingFrequency__c;
                    updateRenewableOrderItemList.add(ordItem);
                    
                    orderitem oldOrdItem = new Orderitem();
                    oldOrdItem.Id=billItem.Id;
                    oldOrdItem.SBQQ__BillingFrequency__c='Invoice Plan';
                    updateOldRenewableOrderItemList.add(oldOrdItem);
                }
            }
            Database.SaveResult[] ordItemUpdateEvergreenSR;
            Database.SaveResult[] ordItemUpdateRenewalSR;
            Database.SaveResult[] ordItemUpdateRenewalSRBF;
            Set<String> failedOrderIdSet=new Set<String>();
            if(!updateEvergreenOrderItemList.isEmpty() && updateEvergreenOrderItemList!= null)		//For Evergreen items
            { 
                ordItemUpdateEvergreenSR = Database.Update(updateEvergreenOrderItemList,false);
            }
            if(!updateRenewableOrderItemList.isEmpty() && !updateOldRenewableOrderItemList.isEmpty()		//For non evergreen items
               && updateRenewableOrderItemList !=null &&  updateOldRenewableOrderItemList!=null)
            {
                System.debug('fixing next billing date update');

                ordItemUpdateRenewalSR = Database.Update(updateOldRenewableOrderItemList,false);
                ordItemUpdateRenewalSRBF = Database.Update(updateRenewableOrderItemList,false);
                
            }
            if (ordItemUpdateEvergreenSR <> null) {
                for (Integer i = 0; i < ordItemUpdateEvergreenSR.size(); i++) {
                    if (!ordItemUpdateEvergreenSR.get(i).isSuccess()) 
                        {failedOrderIdSet.add(string.valueOf(updateEvergreenOrderItemList[i].id));}
                }
            }
            if (ordItemUpdateRenewalSR <> null) {
                for (Integer i = 0; i < ordItemUpdateRenewalSR.size(); i++) {
                    if (!ordItemUpdateRenewalSR.get(i).isSuccess()) 
                        {failedOrderIdSet.add(string.valueOf(updateOldRenewableOrderItemList[i].id));}
                }
            }
            if (ordItemUpdateRenewalSRBF <> null) {
                for (Integer i = 0; i < ordItemUpdateRenewalSRBF.size(); i++) {
                    if (!ordItemUpdateRenewalSRBF.get(i).isSuccess()) 
                        {failedOrderIdSet.add(string.valueOf(updateRenewableOrderItemList[i].id));}
                }
            }
            if(!failedOrderIdSet.isEmpty()) 
            {
                QTB_Utils.sendErrorLogMail(		//Send out email if any Billing Order Items are failed to process
                    failedOrderIdSet,
                    'Billing Order Item Creation/Update Failed'
                );             
            }      
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_QueueableOrderItemCreation');
            throw e;
        } 
    }     
    
}