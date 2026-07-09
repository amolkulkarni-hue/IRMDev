public with sharing class QTB_AmendBillingHelper {
  public static final Id contractSalesRecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID;
  public static final Id contractBillRecordTypeId = QTB_Utils.CONTRACT_BILL_RECTYPEID;
  public static final Id accountBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
  public static final Id oppSalesRecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
  public static Boolean BlockCustomTrigger = false;
  public static Map<String, Id> abOrderDetailMap = new Map<String, Id>();

  /***********************************************************************************************************l
   * Method : AmendBillingClone
   * Parameters: Map<Id,Contract>, Map<Id,Order>,List<Contract>
   * Return type: void
   * Requirement :Git#8
   * Start Date : 01/02/2020
   * Author : Accenture
   * Description: Used to create Billing related records.
   **************************************************************************************************************/
  public static void AmendBillingClone(
    Map<Id, Contract> ASOrderContractMap,
    Map<Id,id> SalesOrderwithASOrderMap,
    List<Contract> contrList,
    Map<Id,Contract> oldContractMap
  ) {
    try {
      if (QTB_QueueRenewalBilling.throwExplicitException) {
        throw new NullPointerException();
      }
      Map<Id, Order> ASOrderMap = new Map<Id, Order>();
      Map<Id, List<OrderItem>> ASOrderToOrderItemsMap = new Map<Id, List<OrderItem>>();
      Map<Id, Id> ASOrderwithSalesContractMap = new Map<Id, Id>();
      Map<Id, Id> SalesASOrderwithOldOrderMap = new Map<Id, Id>();
      map<Id,Order> insertedBillingOrderMap;
      Map<Id, Set<Id>> sOrderwithBillAccountIdsMap = new Map<Id, Set<Id>>();
        for(Id oldId:SalesOrderwithASOrderMap.keySet()){
            SalesASOrderwithOldOrderMap.put(SalesOrderwithASOrderMap.get(oldId),oldId);
        }
      Map<String, Order> newABOrderMap = new Map<String, Order>();
      Map<String, List<OrderItem>> newABOrderLineItemMap = new Map<String, List<OrderItem>>();
      Map<String, Set<String>> billAccToCSAutonumberSet = new Map<String, Set<String>>();
      Map<String, Set<Id>> billAccToSalesOrderItemIdSet = new Map<String, Set<Id>>();
      Map<String, Map<String, OrderItem>> MapOfBillAcctoMap = new Map<String, Map<String, OrderItem>>();
      system.debug('listoforders>>>>'+QTB_CreateBillingRecords.collectSalesOrders(ASOrderContractMap.keyset(),QTB_Constants.ORDER_TYPE_AMENDMENT));

      if (ASOrderContractMap.size() > 0) {
        for (
          Order temp : QTB_CreateBillingRecords.collectSalesOrders( //collect all Amend Sales Orders
            ASOrderContractMap.keyset(),
            QTB_Constants.ORDER_TYPE_AMENDMENT
          )
        ) {
          if ( ASOrderContractMap.containsKey(temp.Id) && temp.type == QTB_Constants.ORDER_TYPE_AMENDMENT) {
            if (temp.OrderItems != null){
              ASOrderMap.put(temp.Id, temp); //Map of AS Order id to AS Order record
              ASOrderToOrderItemsMap.put(temp.Id, temp.OrderItems);  //Map of AS Order with AS Order items
            }
          }
        }
        if (SalesOrderwithASOrderMap.size() > 0) {
          sOrderwithBillAccountIdsMap = collectAllBillingAccounts(    //Collect All Billing Accounts linked to AS Order in Map<OriginalSales Order,Set<BAs>>
            SalesOrderwithASOrderMap.keyset(), 
            abOrderDetailMap //Map of string(BAid_OriginalSalesOrderid ) to previous Billing Order
          );
          for (Id sOrderIDtemp : sOrderwithBillAccountIdsMap.keyset()) { //Iterate over all Original Sales Orders
            for (
              Id billAccIDtemp : sOrderwithBillAccountIdsMap.get(sOrderIDtemp) //Iterate over respective BAs linked to original Sales Order
            ) {
              if (
                SalesOrderwithASOrderMap.containsKey(sOrderIDtemp) &&
                SalesOrderwithASOrderMap.get(sOrderIDtemp) != null
              ) {

                newABOrderMap.put(       //Create a Map of String(BAid_OSorderId) to Amend Billing Order
                  billAccIDtemp +
                  '_' +
                  sOrderIDtemp,
                  QTB_CreateBillingRecords.cloneSaleOrder(
                    ASOrderMap.get(SalesOrderwithASOrderMap.get(sOrderIDtemp)), //AS order to be cloned
                    billAccIDtemp,
                    abOrderDetailMap.get(billAccIDtemp + '_' + sOrderIDtemp)     //Previous Bill Order
                  )
                );
                newABOrderLineItemMap.put(  //Map of String(BAid_OSorderid) to Amend Sales item
                  billAccIDtemp +
                  '_' +
                  sOrderIDtemp,
                  ASOrderToOrderItemsMap.get(
                    SalesOrderwithASOrderMap.get(sOrderIDtemp)
                  )
                );
              }
            }
          }

          Map<String, OrderItem> mapOfASIdToBillRecord = new Map<String, OrderItem>();

          if (newABOrderLineItemMap.size() > 0) {
            QTB_CreateBillingRecords.insertBillOrders(newABOrderMap.values()); //Insert Billing Orders
            insertedBillingOrderMap = new map <ID,Order>(newABOrderMap.values());              
            Map<Id, OrderItem> tempSalesItemIdtoBillMap = new Map<Id, OrderItem>();
            List<OrderItem> billItemsToInsert = new List<OrderItem>();
              
            for (String keyStr : newABOrderLineItemMap.keySet()) {				//iterate over strings that differentiate each BA
                for (OrderItem orderItm : newABOrderLineItemMap.get(keyStr)) {
                    if(orderItm.SBQQ__OrderedQuantity__c > 0){
                        if (!billAccToCSAutonumberSet.containskey(keyStr))
                            billAccToCSAutonumberSet.put(keyStr, new Set<String>());
                        billAccToCSAutonumberSet.get(keyStr).add(orderItm.QTB_OriginalConsumptionID__c); //Collect all consumption ids
                        
                        mapOfASIdToBillRecord.put(	string.valueOf(orderItm.id) +'_' +string.valueOf(newABOrderMap.get(keyStr).Id), QTB_CreateBillingRecords.cloneSalesItem(orderItm,newABOrderMap.get(keyStr)));
                        if (!billAccToSalesOrderItemIdSet.containsKey(keyStr))
                            billAccToSalesOrderItemIdSet.put(keyStr, new Set<Id>());
                        billAccToSalesOrderItemIdSet.get(keyStr).add(orderItm.id);     //Collect all sales order items ids
                        
                        MapOfBillAcctoMap.put(keyStr, mapOfASIdToBillRecord);			//Map of String to Map of <ASOrderItem_ABOrderid to AB  itemRecord>
                    }
                }
            }
            for (OrderItem item : mapOfASIdToBillRecord.values()) {
              billItemsToInsert.add(item);
            }
              
            //Remove duplicates from list
            set<OrderItem> orderitemsSet = new Set<OrderItem>();
            orderitemsSet.addAll(billItemsToInsert);
            billItemsToInsert.clear();
            billItemsToInsert.addAll(orderitemsSet);
            
             //Dynamic logic to insert Billing order items if list is having more then 10k records
                Decimal count=math.ceil((billItemsToInsert.size()/10000));
                if(count<=1){
                  	QTB_CreateBillingRecords.insertBillOrderItems(billItemsToInsert,insertedBillingOrderMap);
                }else{
                    for(integer j=1;j<=count;j++){
                        List<OrderItem> itemsList1=new List<OrderItem>();
                        integer k=(billItemsToInsert.size()>10000)?10000:billItemsToInsert.size();
                        for(integer i=0;i<k;i++){
                            itemsList1.add(billItemsToInsert[i]);
                            billItemsToInsert.remove(i);
                        }
                        if(!itemsList1.isEmpty()){}
                        QTB_CreateBillingRecords.insertBillOrderItems(itemsList1,insertedBillingOrderMap);
                    }
                }
			
            //CS and CR cloning and creating using Schedulable logic that invokes for each BA
            for (String keyStr : newABOrderLineItemMap.keySet()) {
              string billAccId = keyStr.substring(0, 18);                    
              System.schedule(
                'CSProcessing' + System.now(),
                QTB_RenewalBillingBatchHelper.setHoldTime(1),
                new QTB_ScheduleCSCloning(billAccToSalesOrderItemIdSet.get(keyStr),billAccToCSAutonumberSet.get(keyStr),
             MapOfBillAcctoMap.get(keyStr),newABOrderMap,billAccId,QTB_Constants.ORDER_TYPE_AMENDMENT, newABOrderMap.values(),SalesASOrderwithOldOrderMap));
              wait(1000); //wait time b/w each schedulable context
            }
            wait(20000);
              
            //Invoking BOActivation Batch if Effective date is <= today
            List<Order> OrdersTobeActivated=new List<Order>();
            for(Order ord:newABOrderMap.values()){
                if(ord.RecordTypeId == QTB_Utils.ORDER_BILL_RECTYPEID &&
                    ord.EffectiveDate <= system.today()
                  ){
                     OrdersTobeActivated.add(ord);
                  }
            }
            if(!OrdersTobeActivated.isEmpty()){
              QTB_BillOrderActivationBatch b = new QTB_BillOrderActivationBatch();
              DatabASe.executeBatch(b, 1);
            }
              
          }
        }
        contrList.remove(0);
        if (contrList.size() > 0)
          system.enqueueJob(new QTB_QueueBillingAmend(contrList,oldContractMap));
      }
    } catch (Exception exx) {
      QTB_ExceptionLogger.createLog(
        exx.getLineNumber(),
        exx.getStackTraceString(),
        exx.getMessage(),
        exx.getTypeName(),
        'ContractHelper'
      );
    } finally {
      SBQQ.TriggerControl.enable();
      BlockCustomTrigger = false;
    }
  }

  //Sleep method to hold transaction
  public static void wait(Integer millisec) {
    if (millisec == null || millisec < 0) {
      millisec = 0;
    }
    Long startTime = DateTime.now().getTime();
    Long finishTime = DateTime.now().getTime();
    while ((finishTime - startTime) < millisec) {
      finishTime = DateTime.now().getTime();
    }
  }
   /***********************************************************************************************************
   * Method : collectAllBillingAccounts
   * Parameters: Set<Id>
   * Return type: Map<Id,Set<Id>>
   * Description: Method to collect all Billing Account Related with Sales Contract
   **************************************************************************************************************/
  public static Map<Id, Set<Id>> collectAllBillingAccounts(
    Set<Id> SalesOrderIdList,
    Map<String, Id> abOrderDetailMap
  ) {
    try {
      if (QTB_QueueRenewalBilling.throwExplicitException) {
        throw new NullPointerException();
      }
      Map<Id, Set<Id>> sOrderwithAccountIdsMap = new Map<Id, Set<Id>>();
      //Iterate over all Billing Orders connected to Original Sales Order
      for (
        Order temp : [
          SELECT Id, QTB_Order_OriginatorId__c, AccountId
          FROM Order
          WHERE
            QTB_Order_OriginatorId__c IN :SalesOrderIdList
            AND AccountId != NULL
            AND Account.RecordtypeId = :accountBillRecordTypeId
        ]
      ) {
        //Collect Map of Original Sales Order to Set<BAs>
        if (!sOrderwithAccountIdsMap.containsKey(temp.QTB_Order_OriginatorId__c))
          sOrderwithAccountIdsMap.put(
            				temp.QTB_Order_OriginatorId__c,
            				new Set<Id>()
          );
        sOrderwithAccountIdsMap.get(temp.QTB_Order_OriginatorId__c)
          .add(temp.AccountId);
          
        //Map of BAid_OSorderid to prev Bill Order
        abOrderDetailMap.put(
          temp.AccountId +
          '_' +
          temp.QTB_Order_OriginatorId__c,
          temp.Id
        );
      }
      return sOrderwithAccountIdsMap;
    } catch (Exception exx) {
      QTB_ExceptionLogger.createLog(
        exx.getLineNumber(),
        exx.getStackTraceString(),
        exx.getMessage(),
        exx.getTypeName(),
        'ContractHelper'
      );
    }
    return new Map<Id, Set<Id>>();
  }
}