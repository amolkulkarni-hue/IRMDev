/*****************************************************************************************************
* Class: QTB_CreateBillingRecords
* Author: Accenture
* Purpose: This is a generic class to create billing Opportunity, billing Quote and billing quote lines
* Requirement: SFCPQBLG-49,SFCPBLG-295,Gitlab#8
* Change History: 6/5/2020
* Developer     Date            Description
* -------------------------------------------------------------------------------------------
*               6/5/2020
* Accenutre     7/24/2020       Adding logic to limit characters in name field
*******************************************************************************************************/
public with sharing class QTB_CreateBillingRecords {
    public static final Id orderBillRecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID;
    public static final String className = 'QTB_CreateBillingRecords';
    public static string curentUserId = userinfo.getUserId();
    public static Boolean blockCustomTrigger = false;
    public static final Id oppSalesRecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
    public static final Id ordSalesRecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID;
    
    /***********************************************************************************************************
    * Method : collectSalesOrders
    * Parameters: Set<Id>
    * Return type: List<Order>
    * Requirement : Gitlab#8
    * Start Date : 1/4/2020
    * Author : Accenture
    * Description: Collect source Order and order product records
    * Event: this method is invoked from  QTB_AccountHelper
    **************************************************************************************************************/
    public static List<Order> collectSalesOrders(
        Set<Id> orderIdSet,
        String invokeLogic
    ) {
       try {
            //String whereClause = ' WHERE  Id IN :orderIdSet ';
            //Here Invoke Logic Association supports Creation Logic,and Renewal supports Amend Logc
            String whereClause=(invokeLogic=='Association' || invokeLogic == 'Creation')? ' WHERE  Id IN :orderIdSet ':(invokeLogic=='Renewal' || invokeLogic=='Amendment' )?' WHERE  Id in :orderIdSet    and RecordTypeId=:ordSalesRecordTypeId  and OpportunityId!=null ':'';
            //Get opportunity and Quote fields
            List<String> orderFieldsList = new List<String>(
                Order.SObjectType.getDescribe().fields.getMap().keySet()
            );
            List<String> ordItemFieldsList = new List<String>(
                OrderItem.SObjectType.getDescribe().fields.getMap().keySet()
            );
            
            //Query source Opportunities and primary Quote
            String qury =
                ' SELECT Opportunity.SBQQ__RenewedContract__r.SBQQ__Order__c, ' +
                String.join(orderFieldsList, ',') +
                ' , (SELECT ' +
                String.join(ordItemFieldsList, ',') +
                ' FROM Orderitems ) ' +
                ' FROM Order ' +
                whereClause;
            return Database.query(qury);
      	} catch (Exception ex) {
            QTB_ExceptionLogger.createLog(ex.getLineNumber(), ex.getStackTraceString(), ex.getMessage(),ex.getTypeName(),className );
            return new List<Order>();
        }
    }
    /***********************************************************************************************************
    * Method : cloneSaleOrder
    * Parameters: Order,Id
    * Return type: Order
    * Requirement : SFCPQBLG-49,SFCPBLG-295
    * Start Date : 6/5/2020
    * Author : Accenture
    * Description: Clone source opportunity and return cloned opportunity record
    * Event: this method is invoked from QTB_ContractHelper and QTB_AccountHelper
    **************************************************************************************************************/
    public static Order cloneSaleOrder(
        Order sourceOrd,
        Id billAccId,
        Id prevBillOrderId
    ) {
        Order billingOrder = new Order();
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            system.debug(sourceOrd);
            system.debug(billAccId);
            system.debug(prevBillOrderId);
            
            billingOrder = sourceOrd.clone();
            billingOrder.Status = QTB_Constants.DRAFT_STATUS;
            billingOrder.SBQQ__Contracted__c = false;
            billingOrder.RecordTypeId = orderBillRecordTypeId;
           billingOrder.AccountId = billAccId;
           //billingOrder.AccountId = null;

            billingOrder.SBQQ__Quote__c = null;
            billingOrder.OpportunityId = null;
           // billingOrder.TotalAmount=null;
            billingOrder.QTB_Order_OriginatorId__c = sourceOrd.Id;
            billingOrder.QTB_PrevBillingOrder__c = prevBillOrderId;
        } catch (Exception ex) {            
            QTB_ExceptionLogger.createLog(ex.getLineNumber(),ex.getStackTraceString(),ex.getMessage(),ex.getTypeName(),className);
        }
        return billingOrder;
    }
    /***********************************************************************************************************
    * Method : insertBilOrders
    * Parameters: List<Order>
    * Return type: void
    * Requirement : Gitlab#8
    * Start Date : 1/4/2020
    * Author : Accenture
    * Description: insert billing orders
    * Event: this method is invoked from QTB_AccountHelper
    **************************************************************************************************************/
    public static void insertBillOrders(List<Order> billingOrdersToInsert) {
        try {
             Set<String> failedOrderIdSet = new Set<String>();

            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            SBQQ.TriggerControl.disable(); //No to trigger any package logic
            blockCustomTrigger = true;
            System.debug('insert order location');
            Database.SaveResult[] ordInsertSR = Database.insert(billingOrdersToInsert,false);
            
            for (Integer i = 0; i < ordInsertSR.size(); i++) {
                  if (!ordInsertSR.get(i).isSuccess()) 
                      failedOrderIdSet.add(string.valueOf(billingOrdersToInsert[i].AccountID));
            }
            System.debug('failedOrderIdSet>>'+failedOrderIdSet);
            if(!failedOrderIdSet.isEmpty()) 
            {
                system.debug('inside email ');
                QTB_Utils.sendErrorLogMail(		//Send out email if any Billing orders are failed to process
                  failedOrderIdSet,
                  'Billing Order Creation Failed >>> Billing AccountIDs'
                );             
          	}
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),className);
        } finally {
            SBQQ.TriggerControl.enable();
            blockCustomTrigger = false;
        }
    }
    /***********************************************************************************************************
    * Method : cloneSalesItem
    * Parameters: OrderItem
    * Return type: OrderItem
    * Requirement : Gitlab#8
    * Start Date : 1/4/2020
    * Author : Accenture
    * Description: Clone sales Order Item and return cloned opportunity record
    * Event: this method is invoked from  QTB_AccountHelper
    **************************************************************************************************************/
    public static OrderItem cloneSalesItem(
        OrderItem sourceOrderItem,
        Order BillingOrder
    ) {
        OrderItem billingOrderItem = new OrderItem();
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            billingOrderItem = sourceOrderItem.clone();
            billingOrderItem.SBQQ__Status__c = QTB_Constants.DRAFT_STATUS;
            billingOrderItem.SBQQ__Activated__c = false;
            billingOrderItem.SBQQ__Contracted__c = false;
            billingOrderItem.OrderId = BillingOrder.Id;
            billingOrderItem.SBQQ__QuoteLine__c = null;
            billingOrderItem.SBQQ__Contract__c = null;
            if(BillingOrder.QTB_OrderCategory__c == 'Evergreen'){
                billingOrderItem.SBQQ__SubscriptionType__c = 'Evergreen';
                billingOrderItem.SBQQ__ProductSubscriptionType__c = 'Evergreen';
                billingOrderItem.SBQQ__SubscriptionTerm__c = 1;
                billingOrderItem.UnitPrice = (sourceOrderItem.UnitPrice / sourceOrderItem.SBQQ__ProrateMultiplier__c);
                billingOrderItem.SBQQ__ProrateMultiplier__c = 1;
                billingOrderItem.SBQQ__BookingsIndicator__c = 'Do Not Include';
                billingOrderItem.blng__PendingBillings__c = null;
            	billingOrderItem.blng__CanceledBillings__c = null;
           		billingOrderItem.blng__TerminatedBillings__c = null;
            }
            billingOrderItem.SBQQ__Subscription__c = null;
            //billingOrderItem.blng__PendingBillings__c = null;
           	// billingOrderItem.blng__CanceledBillings__c = null;
            //billingOrderItem.blng__TerminatedBillings__c = null;
            billingOrderItem.SBQQ__QuotedListPrice__c = null;
            billingOrderItem.SBQQ__QuotedQuantity__c = null;
            billingOrderItem.blng__LastChargeToDate__c = null;
        	billingOrderItem.blng__LastInvoiceTargetDate__c =null;
       	    billingOrderItem.blng__NextChargeDate__c =null;
        } catch (Exception ex) {
            QTB_ExceptionLogger.createLog(ex.getLineNumber(),ex.getStackTraceString(),ex.getMessage(),ex.getTypeName(),className);
        }
        return billingOrderItem;
    }
    /***********************************************************************************************************
    * Method : insertBillOrderItems
    * Parameters: List<OrderItem>
    * Return type: Void
    * Requirement : Gitlab#8
    * Start Date : 1/4/2020
    * Author : Accenture
    * Description: Insert Bill Order Item Records
    * Event: this method is invoked from  QTB_AccountHelper
    **************************************************************************************************************/
    public static void insertBillOrderItems(
        List<OrderItem> billingOrderItemsToInsert, Map<Id,Order> insertedBillingOrderMap
    ) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            SBQQ.TriggerControl.disable(); //Not to trigger any package logic to create extra consumption scheudles
            blockCustomTrigger = true;
           
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
                    //System.debug(insertedBillingOrderMap.get(billItem.OrderID).QTB_OrderCategory__c);
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
                ordItemUpdateRenewalSR = Database.Update(updateOldRenewableOrderItemList,false);
            	ordItemUpdateRenewalSRBF = Database.Update(updateRenewableOrderItemList,false);

            }
            if (ordItemUpdateEvergreenSR <> null) {
                for (Integer i = 0; i < ordItemUpdateEvergreenSR.size(); i++) {
                    if (!ordItemUpdateEvergreenSR.get(i).isSuccess()) 
                        failedOrderIdSet.add(string.valueOf(updateEvergreenOrderItemList[i].id));
                }
            }
            if (ordItemUpdateRenewalSR <> null) {
                for (Integer i = 0; i < ordItemUpdateRenewalSR.size(); i++) {
                    if (!ordItemUpdateRenewalSR.get(i).isSuccess()) 
                        failedOrderIdSet.add(string.valueOf(updateOldRenewableOrderItemList[i].id));
                }
            }
            if (ordItemUpdateRenewalSRBF <> null) {
                for (Integer i = 0; i < ordItemUpdateRenewalSRBF.size(); i++) {
                    if (!ordItemUpdateRenewalSRBF.get(i).isSuccess()) 
                        failedOrderIdSet.add(string.valueOf(updateRenewableOrderItemList[i].id));
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
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),className);
            throw e;
        } finally { 
            blockCustomTrigger = false;
        }
    }    
}