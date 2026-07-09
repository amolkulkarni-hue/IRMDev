/*****************************************************************************************************
 * Class: QTB_BillOrderActivationBatch
 * Author: Accenture
 * Purpose: This is a Batch class to activate Renewal Billing Orders and terminate respective Billing Orders
 * Requirement: Git#9
 * Change History: 04/03/2021 
 *******************************************************************************************************/
global class QTB_BillOrderActivationBatch implements Database.Batchable<SObject> {
    public String query;
    public static final string ORDER_BATCH = 'QTB_BillOrderActivationBatch';
    public static final Id billOrderRecType = QTB_Utils.ORDER_BILL_RECTYPEID;
    public static final string orderTypeRenewal = QTB_Constants.ORDER_TYPE_RENEWAL;
    public static final string orderTypeAmend = QTB_Constants.ORDER_TYPE_AMENDMENT;

    /***********************************************************************************************************
     * Method :  Constructor
     * Description: Used to initaite query string.
     **************************************************************************************************************/
    global QTB_BillOrderActivationBatch() {

      query =
        ' SELECT  Id,Type, Status,QTB_ReadyActiveOrderitems__c,EffectiveDate,QTB_PrevBillingOrder__c, ' +
        //'QTB_Foreversafe_Flag__c,QTB_Conversion_Generation__c,AccountId, ' +    //GitLab #1418
        ' QTB_No_of_Order_Products__c,QTB_OrderCategory__c,'+
          'blng__InvoiceBatch__c '+  //for sierra26
          'from Order where Status=\''+QTB_Constants.DRAFT_STATUS+'\'  AND RecordTypeId = :billOrderRecType AND'+
        ' EffectiveDate	<= TODAY'; //+
        //' AND id = \'8017X000001J6inQAC\'';
        system.debug('-->query:'+query);
    }
    /***********************************************************************************************************
     * Method : start
     * Parameters: Database.BatchableContext
     * ReturnType: Database.QueryLocator
     * Description: To collect all Renewal Billing Orders
     **************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext bc) {
      return Database.getQueryLocator(query);
    }
    /***********************************************************************************************************
     * Method : execute
     * Description: Used to activate Renewal billing order and terminate billing order
     **************************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<Order> orderList) {
      List<Id> failedOrderIdList = new List<Id>();
      Map<Id,Date> mapOfoldOrderNewStartData=new Map<Id,Date>();
      List<Order> updateOrderList = new List<Order>();
      List<OrderItem> orderItemsToUpdate=new List<OrderItem>();
     // List<Account> accountList = new List<Account>();   //GitLab#1418
      for (Order temp : orderList) {
          //for Sierra26 Order Activation //GitLab#836
          //added Or condition in existing code for Sierra26
          //exclude order activation for Rebill orders as its breaking Credit & Rebill functionality Gitlab US #9256
          if(temp.QTB_OrderCategory__c != 'Rebill' && (temp.QTB_No_of_Order_Products__c == temp.QTB_ReadyActiveOrderitems__c || temp.blng__InvoiceBatch__c == System.Label.QTB_sierra26Label)){
             
            temp.status=QTB_Constants.ACTIVATED_STATUS;
            updateOrderList.add(temp);
              if(temp.QTB_PrevBillingOrder__c != null){               
              mapOfoldOrderNewStartData.put(temp.QTB_PrevBillingOrder__c,temp.EffectiveDate);
              // GitLab #1418 start
        		//if(temp.QTB_Legal_Entity_Country__c != 'United States' && temp.QTB_Legal_Entity_Country__c != 'Canada')
                //{
            	//Account accnt = new Account();
            	//accnt.Id = temp.AccountId;
            	//accnt.QTB_Foreversafe_Flag__c = temp.QTB_Foreversafe_Flag__c;
            	//accnt.QTB_Conversion_Generation__c = temp.QTB_Conversion_Generation__c;
            	//accountList.add(accnt);
        		//}
        	//GitLab #1418 End    
          }
          }
      }
      for(OrderItem item:[SELECt id,SBQQ__TerminatedDate__c,OrderId,SBQQ__SubscriptionType__c,QTB_HasConsumptionSchedule__c from OrderItem where orderid IN :mapOfoldOrderNewStartData.keySet()]){
        if(mapOfoldOrderNewStartData.containsKey(item.OrderId)){
        if((item.SBQQ__SubscriptionType__c ==QTB_Constants.SUBSCRIPTION_TYPE_RENEWABLE || item.SBQQ__SubscriptionType__c==QTB_Constants.SUBSCRIPTION_TYPE_ONETIME) ||
           (item.SBQQ__SubscriptionType__c ==QTB_Constants.SUBSCRIPTION_TYPE_EVERGREEN && item.QTB_HasConsumptionSchedule__c ==TRUE))
           System.debug('****Inside Termination of OI with CS****');
           item.SBQQ__TerminatedDate__c=mapOfoldOrderNewStartData.get(item.OrderId).addDays(-1);
        if(item.SBQQ__SubscriptionType__c ==QTB_Constants.SUBSCRIPTION_TYPE_EVERGREEN && item.QTB_HasConsumptionSchedule__c ==FALSE){
            System.debug('****Inside Termination of OI without CS****');
            item.SBQQ__TerminatedDate__c=mapOfoldOrderNewStartData.get(item.OrderId).addDays(-2);
           // item.blng__BillThroughDateOverride__c=mapOfoldOrderNewStartData.get(item.OrderId).addDays(-1);
        }
        
          orderItemsToUpdate.add(item);
      }
      }        
      //GitLab # 1418 start
      //if(!accountList.isEmpty())
    	//update accountList;
     //GitLab #1418 End  
        try{
        if(!orderItemsToUpdate.isEmpty())
      //  SBQQ.TriggerControl.disable();
        update orderItemsToUpdate;
       // SBQQ.TriggerControl.enable();
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ORDER_BATCH
            );
            throw e;
        }finally {
         // SBQQ.TriggerControl.enable();
          }
      if (updateOrderList.size() > 0) {
        System.debug('updateOrderList>>'+updateOrderList);
        Database.SaveResult[] ordUpdateSR = Database.update(
          updateOrderList,
          false
        );
        
        for (Integer i = 0; i < ordUpdateSR.size(); i++) {
          if (!ordUpdateSR.get(i).isSuccess()) {
          failedOrderIdList.add(updateOrderList[i].id);

          Database.Error error = ordUpdateSR.get(i).getErrors().get(0);
          String failedDML = error.getMessage();
          System.debug('failedDML>>>'+failedDML);

        }
        }
        System.debug('failedOrderIdList>>'+failedOrderIdList);
        }
     
      }


    /***********************************************************************************************************
     * Method : finish
     * Description: NA
     **************************************************************************************************************/
    global void finish(Database.BatchableContext bc) {

    }

  }