/*****************************************************************************************************
 * Class: QTB_RenewalBillingBatchHelper
 * Author: Accenture
 * Purpose: This is a generic class to create billing Opportunity, billing Quote and billing quote lines
 * Requirement: Git#9,Git#15
 * Change History: 01/02/2021
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *             6/5/2020
 *******************************************************************************************************/
public with sharing class QTB_RenewalBillingBatchHelper {
  public static final Id contractSalesRecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID;
  public static final Id contractBillRecordTypeId = QTB_Utils.CONTRACT_BILL_RECTYPEID;
  public static final Id accountBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
  public static final Id oppSalesRecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
  public static Boolean BlockCustomTrigger = false;
  public static Map<String, Id> rbContractDetailMap = new Map<String, Id>();
  public static Map<String, Id> rbOrderDetailMap = new Map<String, Id>();

  /***********************************************************************************************************
   * Method : RenewalBillingClone
   * Parameters: Map<Id,Contract>, Map<Id,Contract>
   * Return type: void
   * Requirement :Git#8
   * Start Date : 01/02/2020
   * Author : Accenture
   * Description: Used to create Billing related records.
   **************************************************************************************************************/
  public static void RenewalBillingClone(
    Map<Id, Contract> rsOrderContractMap,
    List<Contract> contrList
  ) {
    try {
      if (QTB_QueueRenewalBilling.throwExplicitException) {
        throw new NullPointerException();
      }
      Map<Id, Order> rsOrderMap = new Map<Id, Order>();
      Map<Id, List<OrderItem>> rsOrderToOrderItemsMap = new Map<Id, List<OrderItem>>();
      Map<Id, Id> rsOrderwithSalesContractMap = new Map<Id, Id>();
      Map<Id, Id> SalesOrderwithRSOrderMap = new Map<Id, Id>();
      map<Id,Order> insertedBillingOrderMap;
      Map<Id, Set<Id>> sOrderwithBillAccountIdsMap = new Map<Id, Set<Id>>();
      Map<String, Order> newRBOrderMap = new Map<String, Order>();
      Map<String, List<OrderItem>> newRBOrderLineItemMap = new Map<String, List<OrderItem>>();
      Map<String, Set<String>> billAccToCSAutonumberSet = new Map<String, Set<String>>();
      Map<String, Set<Id>> billAccToSalesOrderItemIdSet = new Map<String, Set<Id>>();
      Map<String, Map<String, OrderItem>> MapOfBillAcctoMap = new Map<String, Map<String, OrderItem>>();

        system.debug(rsOrderContractMap);
      if (rsOrderContractMap.size() > 0) {
        for (Order temp : QTB_CreateBillingRecords.collectSalesOrders(rsOrderContractMap.keyset(),QTB_Constants.QUOTE_TYPE_RENEWAL)) {
            if (rsOrderContractMap.containsKey(temp.Id) && temp.type == QTB_Constants.ORDER_TYPE_RENEWAL) {
                if (temp.OrderItems != null) {
                    rsOrderMap.put(temp.Id, temp); //Map of RS Order id with RS Order Record
                    rsOrderToOrderItemsMap.put(temp.Id, temp.OrderItems); //Map of RS Order to respective Order items
                    SalesOrderwithRSOrderMap.put(temp.Opportunity.SBQQ__RenewedContract__r.SBQQ__Order__c,temp.Id);
                }
            }
        }
        if (SalesOrderwithRSOrderMap.size() > 0) {
          sOrderwithBillAccountIdsMap = collectAllBillingAccounts( //Collect all Billing Accounts
            SalesOrderwithRSOrderMap.keyset(),
            rbOrderDetailMap
          );
          for (Id sOrderIDtemp : sOrderwithBillAccountIdsMap.keyset()) {	//iterate over RS Order
              for (
                  Id billAccIDtemp : sOrderwithBillAccountIdsMap.get(sOrderIDtemp)	//iterate over respective BAs
              ) {
                  if (
                      SalesOrderwithRSOrderMap.containsKey(sOrderIDtemp) &&
                      SalesOrderwithRSOrderMap.get(sOrderIDtemp) != null
                  ) {
                      newRBOrderMap.put(				//Map of string(BAid_OSOrderid) to RenewalBilling Order
                          billAccIDtemp +
                          '_' +
                          sOrderIDtemp,
                          QTB_CreateBillingRecords.cloneSaleOrder(
                              rsOrderMap.get(SalesOrderwithRSOrderMap.get(sOrderIDtemp)),
                              billAccIDtemp,
                              rbOrderDetailMap.get(billAccIDtemp + '_' + sOrderIDtemp)
                          )
                      );
                      newRBOrderLineItemMap.put(	//Map of string(BAid_OSOrderid) to respective Order items
                          billAccIDtemp +
                          '_' +
                          sOrderIDtemp,
                          rsOrderToOrderItemsMap.get(
                              SalesOrderwithRSOrderMap.get(sOrderIDtemp)
                          )
                      );
                  }
              }
          }

          Map<String, OrderItem> mapOfRSIdToBillRecord = new Map<String, OrderItem>();

          if (newRBOrderLineItemMap.size() > 0) {
            QTB_CreateBillingRecords.insertBillOrders(newRBOrderMap.values()); //Insert Billing Orders
              
            insertedBillingOrderMap = new map <ID,Order>(newRBOrderMap.values());              
            Map<Id, OrderItem> tempSalesItemIdtoBillMap = new Map<Id, OrderItem>();
            List<OrderItem> billItemsToInsert = new List<OrderItem>();
              
            for (String keyStr : newRBOrderLineItemMap.keySet()) {		//iterate over strings of BAid_OSOrderid
              for (OrderItem orderItm : newRBOrderLineItemMap.get(keyStr)) {   //iterate over RS order items for each BA
                  
                  if (!billAccToCSAutonumberSet.containskey(keyStr))		//Auto number set
                      billAccToCSAutonumberSet.put(keyStr, new Set<String>());
                  billAccToCSAutonumberSet.get(keyStr)
                      .add(orderItm.QTB_OriginalConsumptionID__c);
                  
                  mapOfRSIdToBillRecord.put(				//Map of String(Orderitemid_BillingOrderid) to Bill order item
                      string.valueOf(orderItm.id) +
                      '_' +
                      string.valueOf(newRBOrderMap.get(keyStr).Id),
                      QTB_CreateBillingRecords.cloneSalesItem(
                          orderItm,
                          newRBOrderMap.get(keyStr)
                      )
                  );
                  
                  if (!billAccToSalesOrderItemIdSet.containsKey(keyStr))		//Map of BA string to respective order items
                      billAccToSalesOrderItemIdSet.put(keyStr, new Set<Id>());                 
                  billAccToSalesOrderItemIdSet.get(keyStr).add(orderItm.id);
                  
              }
              MapOfBillAcctoMap.put(keyStr, mapOfRSIdToBillRecord);
            }
            //Remove duplicate records from list
            for (OrderItem item : mapOfRSIdToBillRecord.values()) {
              billItemsToInsert.add(item);
            }
            set<OrderItem> orderitemsSet = new Set<OrderItem>();
            orderitemsSet.addAll(billItemsToInsert);
            billItemsToInsert.clear();
            billItemsToInsert.addAll(orderitemsSet);

            //Dynamic logic to update Order items if list has more then 10k records
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

             //CS and CR cloning and creation for each BA in schedulable context
            for (String keyStr : newRBOrderLineItemMap.keySet()) {
              string billAccId = keyStr.substring(0, 18);
		
              System.schedule(
                'CSProcessing' + System.now(),
                setHoldTime(1),
                new QTB_ScheduleCSCloning(
                  billAccToSalesOrderItemIdSet.get(keyStr),
                  billAccToCSAutonumberSet.get(keyStr),
                  MapOfBillAcctoMap.get(keyStr),
                  newRBOrderMap,
                  billAccId,
                  'Renewal',
                  newRBOrderMap.values()
                    ,
                    null
                )
              );
              wait(1000); //to scheudule CSProcessing class with time difference of one sec
              
            }
            wait(20000);
            List<Order> OrdersTobeActivated=new List<Order>();
            for(Order ord:newRBOrderMap.values()){
                if(ord.RecordTypeId == QTB_Utils.ORDER_BILL_RECTYPEID &&
                    ord.EffectiveDate <= system.today()
                  ){
                     OrdersTobeActivated.add(ord);
                  }
            }
            if(!OrdersTobeActivated.isEmpty()){
              QTB_BillOrderActivationBatch b = new QTB_BillOrderActivationBatch();
              Database.executeBatch(b, 1);
            }
          }
        }
        contrList.remove(0);
        if (contrList.size() > 0)
          system.enqueueJob(new QTB_QueueRenewalBilling(contrList));
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
   * Method : setHoldTime
   * Parameters: NA
   * Return type: String
   * Requirement : SFCPQBLG-295
   * Start Date : 6/5/2020
   * Author : Accenture
   * Description: used to set hold time for 2 min
   * Event: this method is invoked from  scheduleQuoteUpdate
   **************************************************************************************************************/

  public static string setHoldTime(Integer mins) {
    DateTime dt = system.now().addMinutes(mins == null ? 5 : mins);
    String day = string.valueOf(dt.day());
    String month = string.valueOf(dt.month());
    String hour = string.valueOf(dt.hour());
    String minute = string.valueOf(dt.minute());
    String second = string.valueOf(dt.second());
    String year = string.valueOf(dt.year());
    return '0 ' +
      minute +
      ' ' +
      hour +
      ' ' +
      day +
      ' ' +
      month +
      ' ?' +
      ' ' +
      year;
  }

  /***********************************************************************************************************
   * Method : collectAllBillingAccounts
   * Parameters: Set<Id>
   * Return type: Map<Id,Set<Id>>
   * Start Date : 6/5/2020
   * Author : Accenture
   * Description: Method to collect all Billing Account Related with Sales Contract
   * Event: this method is invoked from  QTB_ContractHandler.checkRenewalContract()
   **************************************************************************************************************/
  public static Map<Id, Set<Id>> collectAllBillingAccounts(
    Set<Id> SalesOrderIdList,
    Map<String, Id> rbOrderDetailMap
  ) {
    try {
      if (QTB_QueueRenewalBilling.throwExplicitException) {
        throw new NullPointerException();
      }
      Map<Id, Set<Id>> sOrderwithAccountIdsMap = new Map<Id, Set<Id>>();
      for (
        Order temp : [									//Get Billing Orders connected to old Sales Order
          SELECT Id, QTB_Order_OriginatorId__c, AccountId
          FROM Order
          WHERE
            QTB_Order_OriginatorId__c IN :SalesOrderIdList
            AND AccountId != NULL
            AND Account.RecordtypeId = :accountBillRecordTypeId
        ]
      ) {
        if (
          !sOrderwithAccountIdsMap.containsKey(temp.QTB_Order_OriginatorId__c)
        )
          sOrderwithAccountIdsMap.put(
            temp.QTB_Order_OriginatorId__c,
            new Set<Id>()
          );
        sOrderwithAccountIdsMap.get(temp.QTB_Order_OriginatorId__c)
          .add(temp.AccountId);
          
        rbOrderDetailMap.put(				   //Map of string(BAid_OldSalesOrder) to previous Bill Order
          temp.AccountId +
          '_' +
          temp.QTB_Order_OriginatorId__c,
          temp.Id
        );
      }
      return sOrderwithAccountIdsMap;			//Map of previous sales Order with it's BAs
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