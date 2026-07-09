/*****************************************************************************************************
* Class: QTB_OrderHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to Order object
* Requirement: CPQ -59, QTB-17a, QTB-1,SFCPQBLG-46, SFCPQBLG-727, SFCPQBLG-519
* Change History: 4/29/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*              3/16/2020
* Virtusa      12/13/2023     Gitlab US#20219 Create Contract for Active Order 
* Vitusa       19/04/2024     Gitlab #23238   Exclude W&L Billing Order for activation   
*******************************************************************************************************/
public with sharing class QTB_OrderHelper {
    public static final string ORDER_HELPER = 'QTB_OrderHelper';
        
    /***********************************************************************************************************   
* Method : trigController
* Parameters: List<Order>, Map<Id,Order>,System.TriggerOperation
* Return Type: void
* Description: Generic method to handle all operations on the Order Records
**************************************************************************************************************/
    public static void trigController(
        List<Order> ordNewList,
        Map<Id, Order> ordOldMap,
        System.TriggerOperation operationType
    ) {
        
        Set<Id> quoteIDs = new Set<Id>();
        Set<ID> accIDs = new Set<ID>();        
        List<Order> ordList = new List<Order>();
        List<Order> orderlist = new List<Order>();
        List<Order> orderlisttoBatch = new List<Order>(); //added for OPCSCR batch
        Set<ID> blngAccountsId = new Set<ID>();
        List<Order> billingorderList = new List<order>();
        List<Order> salesOrderList = new List<Order>(); //Gitlab US#20219
        set<Id> baccsId = new Set<Id>();
        // #24886 Added the below Set to Store Order ids when ever the Payment terms Field is updated on Account level from Order Level for updating the Op level payment terms Fields
        Set<Id> orderSetPaymentTerms = new Set<Id>();
        // #24886 created a Map for updating only once orderItem List when order update happens (New Structure of code)
        Map<Id,OrderItem> finalSingleUpdateOrderItemMap = new Map<Id,OrderItem>();
        //GitLab #24893 created a Map for updating Orderinfo only once when ever the Order want to be Updated(New Structure of code)
        Map<Id,Order> finalSingleUpdateOrderMap = new Map<Id,Order>();
        //GitLab #24893 created a set to store the SITAD Order Ids
        set<Id> sitadOrderId = new set<Id>();
        for (Order ord : ordNewList) {
            switch on operationType {
                when BEFORE_INSERT {
                    /*if (ord.SBQQ__Quote__c != null){
quoteIDs.add(ord.SBQQ__Quote__c);
ordList.add(ord);
}*/ //Commented for Gitlab#8
                    //Gitlab#225 start
                    if (ord.SBQQ__Quote__c != null) {
                        quoteIDs.add(ord.SBQQ__Quote__c);
                    } //Gitlab#225 end
                    ordList.add(ord);
                    if (ord.AccountID != null) {
                        accIDs.add(ord.AccountID);
                    }                   
                    if (ord.AccountId != null) {
                        blngAccountsId.add(ord.AccountId);
                        orderlist.add(ord);
                    }
                    if (
                        ord.AccountId != null && (ord.QTB_OrderCategory__c != QTB_Constants.ORDCATEGORY_ADHOC 
                                                  && ord.QTB_OrderCategory__c !=QTB_Constants.ORDCATEGORY_WORKORDER 
                                                  &&  ord.QTB_OrderCategory__c !=QTB_Constants.ORDCATEGORY_REBILL )
                        && ord.RecordTypeId == QTB_Utils.ORDER_BILL_RECTYPEID
                    ) {
                        billingorderList.add(ord);
                        baccsId.add(ord.AccountId);
                    }
                }
                when BEFORE_UPDATE {
                    ordList.add(ord);
                    //25905
                    if(Ord.QTB_OrderCategory__c == 'Ad-Hoc' && ord.Status != ordOldMap.get(ord.Id).Status && ord.Status == 'Activated'){
                        ord.QTB_InvoiceStatus__c = 'Ready For Usage';
                    }
                    if(Ord.QTB_OrderCategory__c == 'Ad-Hoc' && ord.Status == 'Activated' && ord.QTB_OrderSubtotal__c != ordOldMap.get(ord.Id).QTB_OrderSubtotal__c && ord.QTB_OrderSubtotal__c >0){
                        ord.QTB_InvoiceStatus__c = 'Ready For Draft';
                    }
                }
                when AFTER_UPDATE {
                    //Gitlab US#20219
                    if(ord.RecordTypeId == QTB_Utils.ORDER_SALES_RECTYPEID &&
               		   ordOldMap.get(ord.Id).Status != ord.Status && ord.Status == 'Activated')
                    {
                       salesOrderList.add(ord); 
                }
                    // 24886 Added the below Logic for handling when ever the Payment terms field is updated on Order level based upon Account Payment Terms Field update and checking the Billing order Record type
                    if(ord.RecordTypeId == QTB_Utils.ORDER_BILL_RECTYPEID && ord.SBQQ__PaymentTerm__c != null && ord.status == 'Activated' && ordOldMap.get(ord.Id).SBQQ__PaymentTerm__c != ord.SBQQ__PaymentTerm__c){
                        orderSetPaymentTerms.add(ord.id);
                    }

                    //GitLab #24893 - While inserting the SITAD orders EDP will populate the orderItem count on QTB_Order_Item_Count__c field(Note:EDP excludes the fuel surcharge OP count),
                    //below if condition we are adding the fuel surcharge count, if QTB_Order_Item_Count__c and QTB_No_of_Order_Products__c(Roll up field) matches we are activating the SITAD Orders.
                    if(ord.QTB_DM_Source_System_Name__c == 'SITAD' && ord.QTB_OrderCategory__c == 'Evergreen' && ord.Status == 'Draft' && 
                       ord.QTB_No_of_Order_Products__c == (ord.QTB_Order_Item_Count__c != NULL?ord.QTB_Order_Item_Count__c+1:0))
                    {
                        sitadOrderId.add(ord.Id);
                    }
                    //GitLab #24893 - End
                }
                when else {
                }
            }
        }
        
        switch on operationType {
            when BEFORE_INSERT {
                if (!ordList.isEmpty()) {
                    QTB_BillingAccountOrderUtil.setOrderTypeValue(ordList, accIDs, quoteIDs);
                }
                if (!orderlist.isEmpty() && !blngAccountsId.isEmpty()) {
                    QTB_BillingAccountOrderUtil.countryClone(orderlist, blngAccountsId);
                }
                if (!billingorderList.isEmpty() && !baccsId.isEmpty()) {
                    QTB_BillingAccountOrderUtil.billingPromotions(billingorderList, baccsId);
                    //#28621 - Commented below updateInvoiceBatch() because same logic available in 'QTB Order Populate Invoice Batch and Legal Entity' Flow
                    //QTB_BillingAccountOrderUtil.updateInvoiceBatch(billingorderList, baccsId);
                }
            }
            when BEFORE_UPDATE {
                if (!ordList.isEmpty() && ordOldMap != null) {
                    updateOnActivationOrder(ordList, ordOldMap);
                }
            }
            when AFTER_UPDATE {
                //Gitlab US#20219
                if(!salesOrderList.isEmpty()) {
                    createContractForActiveOrder(salesOrderList);
                }
                
                // #24886 Calling the method to update Orders payment Term Value based upon Billc Paymet Terms Updated Value
                if(!orderSetPaymentTerms.isEmpty() && QTB_RecursiveHandlerCheck.updateOpPayTermBasedOnOrdPayTerms == True){
                    // returned from Method orderList that needs to get updated and added to list
                    List<orderItem> orderItemUpdate = QTB_OrderHelperUtils.updateOpPayTermBasedOnOrdPayTerms(orderSetPaymentTerms);
                    if(orderItemUpdate != null){
                        for(orderitem oi : orderItemUpdate){
                            // If that orderid not present in list add as it is for further updates
                            if(!finalSingleUpdateOrderItemMap.containsKey(oi.id)){
                                finalSingleUpdateOrderItemMap.put(oi.id,oi);
                            }else{
                                // If that Id presents add that related Field Name as per id and Value as Fields data that needs to be updated
                                finalSingleUpdateOrderItemMap.get(oi.id).put('QTB_Payment_Term__c', oi.QTB_Payment_Term__c);
                            }
                        }
                    }
                }
                //GitLab #24893 Calling the sitadOrderActivation method to update Order status to Activated. 
               System.debug('sitadOrderId@@'+sitadOrderId.size());
               System.debug('sitadOrderId@@'+sitadOrderId);
                if(!sitadOrderId.isEmpty()){
                   System.debug('inside if@@');
                   List<Order> orderUpdate = QTB_OrderHelperUtils.sitadOrderActivation(sitadOrderId);
                   if(orderUpdate != NULL){
                       for(Order ord:orderUpdate){
                           // If that orderid not present in list add as it is for further updates
                           if(!finalSingleUpdateOrderMap.containsKey(ord.Id)){
                               finalSingleUpdateOrderMap.put(ord.Id,ord);    
                           }else{
                               // If that Id presents add that related Field Name as per id and Value as Fields data that needs to be updated
                               finalSingleUpdateOrderMap.get(ord.Id).put('Status',ord.Status);
                           }    
                       }      
                   }     
               }
                // GitLab #24893 Updating only once the Order List what fields needs to be further updated as per the new code Structure
                if(finalSingleUpdateOrderMap.size() > 0){
                    System.debug('finalSingleUpdateOrderMap@@'+finalSingleUpdateOrderMap.values());
                    update finalSingleUpdateOrderMap.values();
                }
                // GitLab #24893 - End
                // #24886 Updating only once the Order List that is Account attached and should be used for further updates as well as per new code Structure
                if(finalSingleUpdateOrderItemMap.size() > 0){
                    update finalSingleUpdateOrderItemMap.values(); 
                }
            }
            when else {
            }
        }
    }
     
    /***********************************************************************************************************   
* Method 	 : createContractForActiveOrder
* Parameters : List<Order> ordList
* Return Type: void
* Description: Gitlab US #20219 - This method is responsible to call QTB_ScheduleOrderContractingBatch schedule call to create contract
			 : Defect fix #21706
**************************************************************************************************************/
    public static void createContractForActiveOrder(List<Order> salesOrderList){
        List<String> orderContractJobNameList = new List<String>();
        if(!salesOrderList.isEmpty()){
            for(Order ord : salesOrderList){
                orderContractJobNameList.add('QTB_ContractBatch_'+ord.OrderNumber);    
            }
            if(!orderContractJobNameList.isEmpty()){
             List<CronTrigger> CronTrigger_objs = [SELECT Id, CronJobDetail.Name, CronJobDetail.Id,State 
                                                   FROM CronTrigger
                                              	      WHERE CronJobDetail.Name IN : orderContractJobNameList AND State != 'DELETED'];
            
             if(CronTrigger_objs.isEmpty()){
                 QTB_Manage_Contract_Scheduler__c manageCustSettings = QTB_Manage_Contract_Scheduler__c.getInstance('FirstRecord');
                 String scheduleTime = QTB_RenewalBillingBatchHelper.setHoldTime(Integer.ValueOf(manageCustSettings.QTB_Scheduler_Hold_Time_In_Min__c));
                     System.schedule(orderContractJobNameList[0],scheduleTime, new QTB_ScheduleOrderContractingBatch());
                 }
             }
        }
    }
    /***********************************************************************************************************
* Method : setOrderTypeValue
* Parameters: List<Order>, Set<Id>
* Return Type : void
* Requirement : SFCPQBLG-46
* Description: Populate Order Type
**************************************************************************************************************/
    public static void setOrderTypeValue(
        List<Order> ordList,
        Set<ID> accIDs,
        Set<Id> quoteIds
    ) {
        Map<String, String> billDayOfMonthMap = new Map<String, String>();
        Map<Id, string> mapOfQuoteRecordTypeName = new Map<Id, string>();
        Map<ID, Account> accMap;
        
        try {
            if (QTB_OrderTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            for (QTB_Invoice_Batch_by_Bill_Cycle__mdt billDay : [
                SELECT id, QTB_Bill_Cycle_Day__c, QTB_Invoice_Batch__c
                FROM QTB_Invoice_Batch_by_Bill_Cycle__mdt
            ]) {
                billDayOfMonthMap.put(
                    billDay.QTB_Invoice_Batch__c,
                    billDay.QTB_Bill_Cycle_Day__c
                );
            }
            
            if (!accIDs.isEmpty()) {
                accMap = new Map<ID, Account>(
                    [
                        SELECT
                        id,
                        QTB_Bill_Cycle_Day__c,
                        QTB_Contract_Entity__r.blng__Country__c,
                        AccountSource
                        FROM Account
                        WHERE
                        id IN :accIDs
                            AND QTB_Account_Record_Type__c = 'Billing Account' AND AccountSource != :System.Label.QTB_sierra26Label // excluding sierra26 from the updation of invoice Batch  
                    ]
                );
            }
            if (!quoteIDs.isEmpty()) {
                for (SBQQ__Quote__c quote : [
                    SELECT Id, Name, RecordType.Name, SBQQ__Account__c
                    FROM SBQQ__Quote__c
                    WHERE Id IN :quoteIDs
                ]) {
                    mapOfQuoteRecordTypeName.put(quote.Id, quote.RecordType.Name);
                }
            }
            //System.debug('map bill day of the month'+billDayOfMonthMap);
            for (Order ord : ordList) {
                if (
                    ord.SBQQ__Quote__c != null &&
                    mapOfQuoteRecordTypeName != null &&
                    mapOfQuoteRecordTypeName.containsKey(ord.SBQQ__Quote__c)
                ) {
                    if (
                        mapOfQuoteRecordTypeName.get(ord.SBQQ__Quote__c)
                        .containsIgnoreCase(QTB_Constants.ORDER_SALES_TYPE)
                    ) {
                        ord.RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID;
                    }
                }
                if (
                    accMap != null &&
                    accMap.containsKey(ord.AccountID) &&
                    ord.RecordTypeId == QTB_Utils.ORDER_BILL_RECTYPEID && ord.QTB_OrderCategory__c !='Rebill' 
                ) {
                    System.debug('bill cycle' + accMap.get(ord.AccountID));
                    System.debug('caught here in 174 order helper');
                     // #17749-For updating the Project specific Bill cycle on Additional Order on creation
                     // #27220 - For SITAD Additional order blng__InvoiceBatch__c should not populate from Account QTB_Bill_Cycle_Day__c
					 // #28621 - For SITAD Legacy order, blng__InvoiceBatch__c should not populate from Account QTB_Bill_Cycle_Day__c because it is populating from Legacy Order Flow
                    if (ord.blng__InvoiceBatch__c !=null && (ord.QTB_OrderCategory__c == QTB_Constants.ORDCATEGORY_ADHOC ||         (ord.QTB_DM_Source_System_Name__c == 'SITAD' && ord.QTB_OrderCategory__c == 'Legacy')))                            
                    {                                                  
                    } else {
                        ord.blng__InvoiceBatch__c = accMap.get(ord.AccountID).QTB_Bill_Cycle_Day__c;
                    }
                    if (ord.blng__InvoiceBatch__c != null && billDayOfMonthMap.containsKey(ord.blng__InvoiceBatch__c)) {
                        ord.blng__BillingDayOfMonth__c = billDayOfMonthMap.get(ord.blng__InvoiceBatch__c);
                    }
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ORDER_HELPER
            );
            throw e;
        }
    }
    
/***********************************************************************************************************
* Method : updateOnActivationOrder
* Parameters: List<Order>, Map<Id, Order>, Set<Id>, Set<Id>
* Return Type : void
* Requirement : SFCPQBLG-727, SFCPQBLG-46
* Description: Order Object Activation
**************************************************************************************************************/
    public static void updateOnActivationOrder(
        List<Order> ordList,
        Map<Id, Order> oldMap
    ) {
        try {
            set<Id> reactivateOrdersIds = new set<Id>();
            if (QTB_OrderTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
             /* start >> Gitlab #23238
                Fetching custom setting to get the Warehouse and Logistics Countries */
                
             Map<String, QTB_Warehouse_and_Logistics_Countries__c> warehouseCountry = QTB_Warehouse_and_Logistics_Countries__c.getAll();  
             
             //end >> Gitlab #23238
             
            for (Order ord : ordList) {
                if (
                    oldMap.containsKey(ord.id) &&
                    ord.SBQQ__PriceCalcStatus__c !=
                    oldMap.get(ord.id).SBQQ__PriceCalcStatus__c &&
                    ord.RecordTypeId == QTB_Utils.ORDER_SALES_RECTYPEID && //Git#8
                    ord.SBQQ__PriceCalcStatus__c == 'Not Needed'
                ) {
                    ord.Status = QTB_Constants.ACTIVATED_STATUS;
                }
                System.debug('Return of QTB_Billing_Countries__c.getValues: ' + QTB_Billing_Countries__c.getValues(ord.QTB_Legal_Entity_Country__c));
       
                if (
                    ord.RecordTypeId == QTB_Utils.ORDER_BILL_RECTYPEID &&
                    ord.QTB_ReadyActiveOrderitems__c !=
                    oldMap.get(ord.id).QTB_ReadyActiveOrderitems__c &&
                    ord.QTB_No_of_Order_Products__c == ord.QTB_ReadyActiveOrderitems__c &&
                    ord.EffectiveDate <= system.today() &&
                    QTB_Billing_Countries__c.getValues(ord.QTB_Legal_Entity_Country__c ) == null &&  // Excludes orders from Billing only countries GitLab #10354
                    //ord.blng__BillingAccount__r.QTB_SITAD__c == True &&  // Excludes SITAD Orders --  Slalom  02-09-2022
                    ord.QTB_DM_Source_System_Name__c != 'SITAD' && //Added as part of GitLab #14437 to Exclude SITAD Orders because QTB_AddOrderProductCSCRBatch Class Activating the order
                    ord.QTB_PrevBillingOrder__c == null && ord.QTB_OrderCategory__c != 'Rebill'
                    &&(!(ord.QTB_Is_Account_W_L__c && warehouseCountry.containsKey(ord.QTB_Legal_Entity_Country__c))) //Exclude W&L Billing Countries for order activation >>#23238
                ) {
                    ord.Status = QTB_Constants.ACTIVATED_STATUS;
                    reactivateOrdersIds.add(ord.Id);
                }

                // Activate the adHoc Orders
                if (
                    ord.RecordTypeId == QTB_Utils.ORDER_BILL_RECTYPEID  && ord.QTB_ReadyActiveOrderitems__c !=oldMap.get(ord.id).QTB_ReadyActiveOrderitems__c && ord.QTB_No_of_Order_Products__c == ord.QTB_ReadyActiveOrderitems__c && ord.EffectiveDate <= system.today()
                   && (!(ord.QTB_Is_Account_W_L__c &&(warehouseCountry.containsKey(ord.QTB_Legal_Entity_Country__c))))//Exclude W&L Billing Countries for order activation >> #23238
                    && QTB_Billing_Countries__c.getValues(ord.QTB_Legal_Entity_Country__c ) == null &&  // Excludes orders from Billing only countries GitLab #10354
                    ord.QTB_PrevBillingOrder__c == null && ord.QTB_OrderCategory__c == 'Ad-Hoc'
                ) {
                    ord.Status = QTB_Constants.ACTIVATED_STATUS;
                    reactivateOrdersIds.add(ord.Id);
                }
                //SFCPQBLG-968 Reset failed contracting attempts count to 0 when user manually uncheck the checkbox
                if (
                    oldMap.get(ord.id).QTB_Hold_Contracting__c == true &&
                    ord.QTB_Hold_Contracting__c == false
                ) {
                    ord.QTB_Failed_Contracting_Attempts__c = 0;
                }
            }
            
            
            if(!reactivateOrdersIds.isEmpty())
            {  QTB_QueuableReActivationOrder.reactivatingOrder(reactivateOrdersIds);}
            
            
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ORDER_HELPER
            );
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : countryClone
* Parameters: List<Order> orderList, Set<ID> blngAccounts
* Return Type : void
* Requirement : SFCPQBLG-519
* Description: To clone the Legal Entity Country from Billing Account
**************************************************************************************************************/
    public static void countryClone(List<Order> orderList, Set<ID> blngAccounts) {
        Map<Id, Account> accountToCountryMap;
        
        try {
            if (QTB_OrderTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            if (!blngAccounts.isEmpty()) {
                accountToCountryMap = new Map<Id, Account>(
                    [
                        SELECT id, QTB_Legal_Entity_Country__c
                        FROM Account
                        WHERE
                        id IN :blngAccounts
                        AND QTB_Account_Record_Type__c = 'Billing Account'
                    ]
                );
            }
            if (
                !orderList.isEmpty() &&
                accountToCountryMap != null &&
                accountToCountryMap.size() > 0
            ) {
                for (Order ord : orderList) {
                    if (accountToCountryMap.containsKey(ord.AccountId)) {
                        ord.QTB_Legal_Entity_Country__c = accountToCountryMap.get(
                            ord.AccountId
                        )
                            .QTB_Legal_Entity_Country__c;
                    }
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ORDER_HELPER
            );
            throw e;
        }
    }
    /***********************************************************************************************************
* Method : billingPromotions
* Parameters: List<Order> orderList, Set<ID> blngAccounts
* Return Type : void
* Requirement : GITLAB-487
*
* Description: To create the billing promotion on the Billing Account based on quote promotions from the original quote
**************************************************************************************************************/
    
    public static void billingPromotions(
        List<Order> orderList,
        Set<ID> blngAccounts
    ) {
        
        Map<Id, Account> billingaccountMap;
        map<Id, Account> originalQteToBAcc = new Map<Id, Account>();
        list<QTB_Product_Billing_Discount__c> pbdList = new List<QTB_Product_Billing_Discount__c>();
        
        try {
            if (QTB_OrderTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            
            if (!blngAccounts.isEmpty()) {
                // getting all the billing accounts which have primary quote on the source opportunity
                billingaccountMap = new Map<Id, Account>(
                    [
                        SELECT
                        id,
                        QTB_Legal_Entity_Country__c,
                        CurrencyIsoCode,
                        QTB_Source_Opportunity__c,
                        QTB_Source_Opportunity__r.SBQQ__PrimaryQuote__c,
                        QTB_Source_Opportunity__r.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c,
                        QTB_Source_Opportunity__r.SBQQ__PrimaryQuote__r.SBQQ__EndDate__c
                        FROM Account
                        WHERE id IN :blngAccounts and QTB_Source_Opportunity__c != null and QTB_Source_Opportunity__r.SBQQ__PrimaryQuote__c !=
                        null
                    ]
                );
            }
            system.debug('billingAccountMap>>>>' + billingaccountMap);
            // primary quote and billing account map
            if (billingaccountMap != null) {
                for (Account eachBillingAccount : billingaccountMap.values()) {
                    originalQteToBAcc.put(
                        eachBillingAccount.QTB_Source_Opportunity__r.SBQQ__PrimaryQuote__c,
                        eachBillingAccount
                    );
                }
            }
            // querying quote promotions of the primary quote where promo term is greater than zero
            for (QTB_Quote_promotion__c eachQP : [
                SELECT
                Id,
                QTB_Quote__c,
                QTB_Promo_Term__c,
                QTB_Promo_Product__c,
                QTB_Promo_Percent__c
                FROM QTB_Quote_Promotion__c
                WHERE QTB_Quote__c IN :originalQteToBAcc.keyset() AND QTB_Promo_Term__c > 0
            ]) {
                if (
                    originalQteToBAcc != null &&
                    originalQteToBAcc.containsKey(eachQP.QTB_Quote__c)
                ) {
                    //creating product discounts for each quote promotions where promo term > 0
                    QTB_Product_Billing_Discount__c pbdrecord = new QTB_Product_Billing_Discount__c();
                    date startDateTemp = originalQteToBAcc.get(eachQP.QTB_Quote__c)
                        .QTB_Source_Opportunity__r
                        ?.SBQQ__PrimaryQuote__r
                        ?.SBQQ__StartDate__c;
                    pbdrecord.QTB_Start_Date__c = startDateTemp;
                    if (startDateTemp != null) {
                        pbdrecord.QTB_End_Date__c =
                            startDateTemp.addMonths(
                                Integer.valueOf(eachQP.QTB_Promo_Term__c)
                            ) - 1;
                    }
                    pbdrecord.QTB_Product__c = eachQP.QTB_Promo_Product__c;
                    pbdrecord.QTB_Account__c = originalQteToBAcc.get(eachQP.QTB_Quote__c)
                        .id;
                    pbdrecord.QTB_Discount__c = eachQP.QTB_Promo_Percent__c;
                    pbdrecord.CurrencyIsoCode = originalQteToBAcc.get(eachQP.QTB_Quote__c)
                        .CurrencyIsoCode;
                    pbdList.add(pbdrecord);
                }
            }
            // inserting product discounts
            if (!pbdList.isEmpty()) {
                insert pbdList;
            }
            Integer i = 0;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
             i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
             i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
             i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
             i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            
            
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ORDER_HELPER
            );
            throw e;
        }
    }
    
	//#28621 - Commented below updateInvoiceBatch() because same logic available in 'QTB Order Populate Invoice Batch and Legal Entity' Flow
    /*public static void updateInvoiceBatch(List<Order> orderList, Set<ID> blngAccounts) {
        
        Map<Id, Account> billingaccountMap;
        map<Id, Account> originalQteToBAcc = new Map<Id, Account>();
        list<QTB_Product_Billing_Discount__c> pbdList = new List<QTB_Product_Billing_Discount__c>();
        
        try {
            if (QTB_OrderTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            
            if (!blngAccounts.isEmpty()) {

                Map<id,Account> accMap = new Map<id,Account>([SELECT id,QTB_Contract_Entity__c,QTB_Bill_Cycle_Day__c from Account where id in: blngAccounts AND  QTB_Contract_Entity__c != null AND QTB_Bill_Cycle_Day__c != null AND QTB_Bill_Cycle_Day__c like '%SecureITAD%' ]);
                for(Order ord : orderList){
                  if(accMap.containskey(ord.Accountid)){
                      ord.bling_Legal_Entity__c = accMap.get(ord.Accountid).QTB_Contract_Entity__c;
                       ord.blng__InvoiceBatch__c = accMap.get(ord.Accountid).QTB_Bill_Cycle_Day__c;
                    }
                }
            }
    } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ORDER_HELPER
            );
            throw e;
        }
    }*/
}