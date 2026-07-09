/*****************************************************************************************************
* Class         : QTB_QueueableCreditReBillOrderItem
* Test Class    : QTB_QueueableCreditReBillOrderItem_Test
* Functionality : ReBill
* Author        : IRM/Virtusa
* Purpose       : This class contains methods to support credit & Rebill Process
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Developer        Date           Description
* -----------------------------------------------------------------------------------------------------
* Gopi          06/17/2022      Initial Version - Gitlab US #9256 Credit & Rebill
* Shailesh(virtusa) 07/11/2023  SplitRebill - Gitlab US#16557
*******************************************************************************************************/
global class QTB_QueueableCreditReBillOrderItem implements Queueable {
    public static final String QTB_QueueableCreditReBillOrderItem = 'QTB_QueueableCreditReBillOrderItem';
    public static Boolean doChainJob = true;
    global list<OrderItem> orderItemsListToClone =new list<OrderItem> ();
    global  Order newRebillOrder = new Order();
    global map <ID,Order> insertedBillingOrderMap =new map <ID,Order>();
    global String prefixMatchingID;
    Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData =new  Map<ID,blng__InvoiceLine__c>();
    ID rebillInvoice;
    Date minStartDate;  
    Date minEndDate;
    Map<Id,Date> productIdWithStartDateMap = new Map<Id,Date>();
    Map<Id,Date> productIdWithEndDateMap = new Map<Id,Date>();    
    Integer splitRebillCount = 1;
    public static String Fuel_Surcharge = 'Fuel Surcharge';
    String rebillType='';
    //Constructor 
    global QTB_QueueableCreditReBillOrderItem(list<OrderItem> orderItemsListToClone, Order newRebillOrder,map <ID,Order> insertedBillingOrderMap,
                                              String prefixMatchingID,map <ID,blng__InvoiceLine__c>mapOfRecurringNonUsageData,
                                              ID rebillInvoice,Map<Id,Date> productIdWithStartDateMap,Map<Id,Date> productIdWithEndDateMap,
                                              Date startDate, Date endDate, Integer splitRebillCount,string rebillType)
    {
        this.orderItemsListToClone = orderItemsListToClone;
        this.newRebillOrder = newRebillOrder;
        this.insertedBillingOrderMap = insertedBillingOrderMap;
        this.prefixMatchingID = prefixMatchingID;
        this.mapOfRecurringNonUsageData = mapOfRecurringNonUsageData;
        this.rebillInvoice = rebillInvoice;
        this.productIdWithStartDateMap = productIdWithStartDateMap;
        this.productIdWithEndDateMap = productIdWithEndDateMap;
        this.minStartDate = startDate;
        this.minEndDate = endDate;
        this.splitRebillCount = splitRebillCount; //SplitRebill cound
        this.rebillType = rebillType; //SplitRebill
    }
    
    /***********************************************************************************************************
* Method      : execute
* Parameter   : QueueableContext qc
* Return Type : void
* Author      : IRM/Virtusa
* Description : manipulate, insert order item and  to call another queuable class to create consumption schedules
**************************************************************************************************************/      
    global void execute (QueueableContext qc)
    {
        Map<id,orderitem> mapOfOldOrderItemToNewOrderItem = new Map<id,orderitem>();
        Map<id,List<orderitem>> mapOfOldOrderItemToNewOrderItemList = new Map<id,List<orderitem>>();  //SplitRebill
        List<OrderItem> billingOrderItemsToInsert = new List<OrderItem> ();
        
        if(!orderItemsListToClone.isEmpty() && orderItemsListToClone.size() > 0)
        {
            //SplitRebill -- creating the duplicate orderItems based on splitRebillCount (for Regular credit&Rebill splitCount is 1 and Split credit&Rebill can be 2 or 3)
            for(integer splitCount = 1; splitCount <= splitRebillCount; splitCount++){
               //Iterate all the Original Order Items
                for(orderitem ordItem : orderItemsListToClone )
                {
                    System.debug('ordItem@@'+ordItem);
                    orderItem tempOrdItem = new orderItem();
                    
                    //Change the Order Item Values
                    tempOrdItem = manipulateOrderItems(ordItem,newRebillOrder,mapOfRecurringNonUsageData,productIdWithStartDateMap,productIdWithEndDateMap,
                                                       prefixMatchingID,minStartDate,minEndDate,splitCount);
                    if(tempOrdItem != Null)
                    {
                        billingOrderItemsToInsert.add(tempOrdItem);
                        mapOfOldOrderItemToNewOrderItem.put(ordItem.Id,tempOrdItem);
                        //SplitRebill -- oldOrderItemId with New duplicate orderItems List
                        if(mapOfOldOrderItemToNewOrderItemList.containsKey(ordItem.Id)){
                            mapOfOldOrderItemToNewOrderItemList.get(ordItem.Id).add(tempOrdItem);
                        }else{
                            mapOfOldOrderItemToNewOrderItemList.put(ordItem.Id,new List<OrderItem>{tempOrdItem});
                        }
                    }
                }
            }
            
            if(!billingOrderItemsToInsert.isEmpty() && !insertedBillingOrderMap.isEmpty())
            {
                System.debug('billingOrderItemsToInsert.size()@@'+billingOrderItemsToInsert.size());
                insertReBillOrderItems(billingOrderItemsToInsert,insertedBillingOrderMap, rebillInvoice);
            }
        }
        
        /*Gitlab US#22511 -- Not Required below code
        // in QTB_CreditReBillOrderCreation class iteself we are setting InvoiceBatch value at Order level
        Order updateOrder = new Order(id = newRebillOrder.id, blng__InvoiceBatch__c = 'Rebill Run');
        
        if(updateOrder !=null){
            update updateOrder; 
        }
        */
        
        if(!mapOfOldOrderItemToNewOrderItem.isEmpty() && mapOfOldOrderItemToNewOrderItem !=null && doChainJob) 
        {       
            System.debug('mapOfOldOrderItemToNewOrderItem.size()'+mapOfOldOrderItemToNewOrderItem.values().size());
            //System.enqueueJob(new QTB_QueuableCreateCreditRebillOrderCS(mapOfOldOrderItemToNewOrderItem,prefixMatchingID,
             //                                                           rebillInvoice,newRebillOrder));
            System.enqueueJob(new QTB_QueuableCreateCreditRebillOrderCS(mapOfOldOrderItemToNewOrderItemList,prefixMatchingID));
        }
    }
    
    /***********************************************************************************************************
* Method        : manipulateOrderItems
* Parameters    :orderitem,Order, Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData, Date,Date , String 
* Return type   : Void
* Author        : IRM/Virtusa
* Description   : manipulate, insert order item and  to call another queuable class to create consumption schedules
**************************************************************************************************************/    
    Public static orderitem manipulateOrderItems(
        orderitem sourceOrderItem, 
        Order newRebillOrder,
        Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData,
        Map<Id,Date> productIdWithStartDateMap, Map<Id,Date> productIdWithEndDateMap, String prefixMatchingID, Date minStartDate, Date minEndDate, Integer splitInvoiceGroupValue)
    {
        system.debug('inside Manipulate order items');
        OrderItem billingOrderItem = new OrderItem();
        try {
            //Clone and Update the new Order Item
            billingOrderItem = sourceOrderItem.clone();           
            billingOrderItem.SBQQ__RequiredBy__c = sourceOrderItem.Id; //Defect Fix #20667 storing old order item id
            billingOrderItem.SBQQ__Status__c = QTB_Constants.DRAFT_STATUS;
            billingOrderItem.QTB_Order_Product_Type__c = 'ReBill';
            billingOrderItem.blng__TaxErrorMessage__c = '';
            billingOrderItem.QTB_Ready_Activation__c=false;
            billingOrderItem.SBQQ__Activated__c=false;
            billingOrderItem.SBQQ__Contracted__c = false;
            billingOrderItem.OrderId = newRebillOrder.Id;            
            billingOrderItem.QTB_PrefixMatchingID__c = prefixMatchingID; 
            billingOrderItem.SBQQ__QuoteLine__c = null;
            billingOrderItem.SBQQ__Contract__c = null;
            if(billingOrderItem.Product2.ProductCode == LABEL.QTB_Minimum_Storage ||
               billingOrderItem.Product2.ProductCode == LABEL.QTB_Invoice_Minimum || 
               billingOrderItem.Product2.Name == Fuel_Surcharge)
            {
                billingOrderItem.ServiceDate = minStartDate;
            }
            else{
                billingOrderItem.ServiceDate = productIdWithStartDateMap.get(billingOrderItem.Product2Id); 
            }
            if(billingOrderItem.Product2.ProductCode == LABEL.QTB_Minimum_Storage ||
               billingOrderItem.Product2.ProductCode == LABEL.QTB_Invoice_Minimum || 
               billingOrderItem.Product2.Name == Fuel_Surcharge)
            {
                billingOrderItem.EndDate = minEndDate;
            }
            else{
                billingOrderItem.EndDate = productIdWithEndDateMap.get(billingOrderItem.Product2Id);
            }
            
            billingOrderItem.SBQQ__SubscriptionType__c = 'Renewable';
            billingOrderItem.SBQQ__ProductSubscriptionType__c = 'Renewable';          
            billingOrderItem.SBQQ__SubscriptionTerm__c = 1;
            //when cloned orderproduct ListPrice not equal to pricebookentry unit price, then system not allowing to insert.
            //Looks like data load order product list prices not matching, so it causing the issues for those orders.
            billingOrderItem.ListPrice = (billingOrderItem.ListPrice != billingOrderItem.PricebookEntry.UnitPrice) ? billingOrderItem.PricebookEntry.UnitPrice : billingOrderItem.ListPrice;
            //Check for Recurring and based on that update the field
            if(mapOfRecurringNonUsageData.containsKey(billingOrderItem.Product2Id))
            {
                system.debug('inside recurring not required');
                billingOrderItem.UnitPrice = mapOfRecurringNonUsageData.get(billingOrderItem.Product2Id).blng__Subtotal__c;
                billingOrderItem.blng__BillableUnitPrice__c = null ;
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
            
            if(billingOrderItem.Product2.ProductCode == Label.QTB_Minimum_Storage || 
               billingOrderItem.Product2.ProductCode == LABEL.QTB_Invoice_Minimum ||
               billingOrderItem.Product2.Name == Fuel_Surcharge)
            {
                System.debug('if@@@');
                billingOrderItem.blng__InvoiceRunProcessingStatus__c ='Will Not Invoice'; 
                billingOrderItem.blng__InvoiceRunStatusIndex__c ='Will Not Invoice';                 
            }else{
                System.debug('else@@@');
                billingOrderItem.blng__InvoiceRunProcessingStatus__c ='Pending Billing';
                billingOrderItem.blng__InvoiceRunStatusIndex__c ='Pending Billing';
            }
            
            /*billingOrderItem.SBQQ__TerminatedDate__c=null;
billingOrderItem.blng__LegalEntity__c =null;
billingOrderItem.blng__TaxTreatment__c = null;
billingOrderItem.blng__TaxCountry__c=null;*/
            billingOrderItem.blng__BilledTax__c =null;
            billingOrderItem.blng__BilledAmountwithouttax__c=null;
            //billingOrderItem.SBQQ__BookingsIndicator__c ='Include';
            billingOrderItem.blng__LastChargeToDate__c = null;
            billingOrderItem.blng__LastInvoiceTargetDate__c =null;
            billingOrderItem.blng__NextChargeDate__c =null;
            billingOrderItem.blng__NextBillingDate__c = null;
            
            //SplitRebill -- US#16557 Setting the invoiceGroupId based on no of splitRebill count
            if(newRebillOrder.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill){
                billingOrderItem.blng__InvoiceGrouping__c = 'Invoice Group ID';
                billingOrderItem.blng__InvoiceGroupId__c = 'Split-00'+splitInvoiceGroupValue;
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_QueueableCreditReBillOrderItem);
            throw e;
        }        
        return billingOrderItem;
    }
    
    
    
    /***********************************************************************************************************
* Method        : insertReBillOrderItems
* Parameters    : List<OrderItem>,Map<Id,Order>
* Return type   : Void
* Author        : IRM/Virtusa
* Description   : Insert Bill Order Item Records
**************************************************************************************************************/
    public static void insertReBillOrderItems(List<OrderItem> billingOrderItemsToInsert, Map<Id,Order> insertedBillingOrderMap, Id reBillInvoiceId)
    {
        try {
            SBQQ.TriggerControl.disable(); //Not to trigger any package logic to create extra consumption scheudles
            
            if(!billingOrderItemsToInsert.isEmpty() && billingOrderItemsToInsert.size() > 0){
                system.debug('%%%%%%%%%%%Gopi'+billingOrderItemsToInsert);
                system.debug('billingOrderItemsToInsert.size()@@'+billingOrderItemsToInsert.size());
                insert billingOrderItemsToInsert;
            }
            
            SBQQ.TriggerControl.enable();  //after inser OrderItems, enabling the package trigger
            
            //Change Invoice ReBill Status
            blng__Invoice__c inv = new blng__Invoice__c();
            inv.QTB_ReBillOrderId__c = insertedBillingOrderMap.get(billingOrderItemsToInsert[0].OrderId).Id;
            inv.id = reBillInvoiceId;
            inv.QTB_ReBill_Status__c = 'Order Product In Progress';
            Update inv;            
            
            List<orderItem> updateEvergreenOrderItemList = new List<OrderItem>();
            List<orderItem> updateRenewableOrderItemList = new List<OrderItem>();
            List<orderItem> updateOldRenewableOrderItemList = new List<OrderItem>(); 
            List<orderItem> updateInvoiceGroupOrderItemList = new List<OrderItem>();
            
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
            Id OrderId;
            //Need to change
            for(OrderItem ordItem : [SELECT Id, Order.OrderNumber,Order.QTB_Rebill_Type__c FROM OrderItem WHERE Id IN : billingOrderItemsToInsert]){
                //Invoice Grouping
                // SplitRebill -- other than split rebill keep the blng__InvoiceGroupId__c to ordernumber
                if(ordItem.Order.QTB_Rebill_Type__c != System.Label.QTB_SplitRebill){
                    ordItem.blng__InvoiceGrouping__c= 'Invoice Group ID';
                    ordItem.blng__InvoiceGroupId__c= ordItem.Order.OrderNumber;
                    updateInvoiceGroupOrderItemList.add(ordItem);
                }
            }
            Set<String> failedOrderIdSet = new Set<String>();
            Database.SaveResult[] ordItemInvoiceGroupUpdate;
            
            if(updateInvoiceGroupOrderItemList.size() > 0){
                ordItemInvoiceGroupUpdate = Database.Update(updateInvoiceGroupOrderItemList,false);
            }
            
            if (ordItemInvoiceGroupUpdate <> null) {
                for (Integer i = 0; i < ordItemInvoiceGroupUpdate.size(); i++) {
                    if (!ordItemInvoiceGroupUpdate.get(i).isSuccess()) 
                    {
                        failedOrderIdSet.add(string.valueOf(updateInvoiceGroupOrderItemList[i].id));
                    }
                }
            }
            
            Database.SaveResult[] ordItemUpdateEvergreenSR;
            Database.SaveResult[] ordItemUpdateRenewalSR;
            Database.SaveResult[] ordItemUpdateRenewalSRBF;
            
            if(!updateEvergreenOrderItemList.isEmpty() && updateEvergreenOrderItemList!= null)      //For Evergreen items
            { 
                ordItemUpdateEvergreenSR = Database.Update(updateEvergreenOrderItemList,false);
            }
            if(!updateRenewableOrderItemList.isEmpty() && !updateOldRenewableOrderItemList.isEmpty()        //For non evergreen items
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
                //Send out email if any Billing Order Items are failed to process
                QTB_Utils.sendErrorLogMail(failedOrderIdSet,'Billing Order Item Creation/Update Failed');             
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_QueueableCreditReBillOrderItem);
            throw e;
        } 
    }     
}