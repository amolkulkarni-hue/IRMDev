/****************************************************************************************************
* Class         : QTB_CreditReBillOrderCreation
* Test Class    : QTB_CreditReBillOrderCreation_Test
* Functionality : ReBill
* Author        : IRM/Virtusa
* Purpose       : This class handle all operation related to Credit & Rebill Process
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Developer            Date           Description
* -----------------------------------------------------------------------------------------------------
* Gopi/Shailesh       06/17/2022      Initial Version - Gitlab US #9256 Credit & Rebill
* Shailesh(Virtusa)   07/11/2023      SplitRebill - Gitlab US#16257
*******************************************************************************************************/
public class QTB_CreditReBillOrderCreation {
    
    public static final String QTB_CreditReBillOrderCreation = 'QTB_CreditReBillOrderCreation';
    //  public static boolean throwExplicitException = false;
    
    /***********************************************************************************************************
* Method      : createRebillOrder
* Parameter   : Id rebillInvoice
* Return Type : String
* Author      : IRM/Virtusa
* Description : based on invoiceId creating Orders, OrderProducts by cloning existing order, OrderProduct associated with that invoice
**************************************************************************************************************/  
    @AuraEnabled
    public Static String createRebillOrder(Id rebillInvoice,String creditReason,String internalNotes, String rebillType, String splitRebillTypeValue )  {
        try {
            ID oldOrderID ;
            Id accId;
            Order newRebillOrder;
            Date minStartDate,minEndDate;
            Map<Id,Date> productIdWithStartDateMap = new Map<Id,Date>();
            Map<Id,Date> productIdWithEndDateMap = new Map<Id,Date>();
            Order orderToClone = new Order();            
            Set<ID> orderProductsIds = new Set<ID>();            
            List<OrderItem> orderItemsListToClone =new List<OrderItem>();
            List<OrderItem> billingOrderItemsToInsert = new List<OrderItem> ();
            Map <ID,Order> insertedBillingOrderMap;
            Map<ID,blng__InvoiceLine__c> mapOfRecurringNonUsageData = new Map<ID,blng__InvoiceLine__c>();
            Map<id,orderitem> mapOfOldOrderItemToNewOrderItem = new Map<id,orderitem>();
            Map<ID,blng__InvoiceLine__c> invoiceLineDataMap;
            List<blng__InvoiceLine__c> invoiceLineList = new List<blng__InvoiceLine__c>();
            Integer splitRebillInvoiceCount = 1;
            String FUEL_SURCHARGE = 'Fuel Surcharge';
            Set<Id> allOrderIdSet = new Set<Id>();
            boolean isSITAD = false; //Gitlab US #22022
            String InvBillingCountry;
            String billingCountry;   
            //SplitRebill
            if(rebillType == System.Label.QTB_SplitRebill && !Test.isRunningTest()){
                splitRebillInvoiceCount = Integer.valueOf(splitRebillTypeValue); //setting the splitRebill value
            }
            
            if(rebillInvoice != null )
            {
                //Query to get the Invoice Details
                invoiceLineDataMap = new Map<ID,blng__InvoiceLine__c>
                    ([SELECT id,blng__Subtotal__c,QTB_HasConsumptionSchedule__c,blng__ChargeType__c,QTB_Charge_Type__c,blng__Product__c,blng__StartDate__c,blng__EndDate__c,blng__Invoice__r.blng__Account__c,
                      blng__OrderProduct__c,blng__Quantity__c,blng__OrderProduct__r.OrderID,blng__Product__r.ProductCode,blng__Product__r.Name 
                      FROM blng__InvoiceLine__c
                      WHERE blng__Invoice__c =:rebillInvoice order by blng__StartDate__c asc]);
                
                if(!invoiceLineDataMap.isEmpty() && invoiceLineDataMap !=null)
                {                   
                    //Iterate all the Invoice Line to get the Order Product Ids
                    for(blng__InvoiceLine__c invLine:invoiceLineDataMap.values()) 
                    {        
                        //Defect fix Gitlab US #20352
                        allOrderIdSet.add(invLine.blng__OrderProduct__r.OrderID);//to cover scenario "Invoice generated from multiple" storing all orderIds
                        //Check if it's Recurring Product
                        if(invLine.QTB_Charge_Type__c == 'Recurring')
                        {
                            orderProductsIds.add(invLine.blng__OrderProduct__c);
                            mapOfRecurringNonUsageData.put(invLine.blng__Product__c,invLine);
                        }
                        else
                        {   //Non Recurring Product excluding QTB_Minimum_Storage and QTB_Invoice_Minimum and FuelSurcharge // Gopi- Only need to check below or anything else
                            //SplitRebill -- allowing to clone default minimum products(Fuel Surcharge/Minimum Invoice/Minimum Storage) if its present at existing source invoice
                            if(rebillType == System.Label.QTB_SplitRebill || 
                               (invLine.blng__Product__r.ProductCode != Label.QTB_Minimum_Storage && 
                                invLine.blng__Product__r.ProductCode !=LABEL.QTB_Invoice_Minimum &&  /*invLine.blng__Product__r.ProductCode != LABEL.QTB_Fuel_Surcharge*/ 
                                invLine.blng__Product__r.Name != FUEL_SURCHARGE))//Comparing with Fuel surcharge name instead of productCode due to multiple Fuel Surcharge products
                            {
                                orderProductsIds.add(invLine.blng__OrderProduct__c);
                            }
                        }
                        if(minStartDate == null){
                            minStartDate = invLine.blng__StartDate__c;  
                        }else{
                            if(invLine.blng__StartDate__c < minStartDate ){
                                minStartDate = invLine.blng__StartDate__c;
                            }
                        }
                        
                        if(minEndDate == null){
                            minEndDate = invLine.blng__EndDate__c; 
                        }else{
                            if(invLine.blng__EndDate__c > minEndDate ){
                                minEndDate = invLine.blng__EndDate__c;
                            }
                        }
                        invoiceLineList.add(invLine);
                        if(productIdWithStartDateMap.containsKey(invLine.blng__Product__c))
                        {
                            if(invLine.blng__StartDate__c < productIdWithStartDateMap.get(invLine.blng__Product__c)){
                                productIdWithStartDateMap.put(invLine.blng__Product__c,invLine.blng__StartDate__c);
                            }
                            if(invLine.blng__EndDate__c > productIdWithEndDateMap.get(invLine.blng__Product__c)){
                                productIdWithEndDateMap.put(invLine.blng__Product__c,invLine.blng__EndDate__c);
                            } 
                        }else{
                            productIdWithStartDateMap.put(invLine.blng__Product__c,invLine.blng__StartDate__c);
                            productIdWithEndDateMap.put(invLine.blng__Product__c,invLine.blng__EndDate__c);
                        }                
                        oldOrderID = invLine.blng__OrderProduct__r.OrderID;
                        accId=invLine.blng__Invoice__r.blng__Account__c;
                    }
                    
                    //Logic for Billing Only Countries -- allowing all order item to clone on OrderProductScreen
                    InvBillingCountry = '';
                    billingCountry = '';
                    Map<Id,blng__Invoice__c> billingCountries = new Map<Id,blng__Invoice__c>([SELECT id,blng__Account__r.QTB_Legal_Entity_Country__c,
                                                                                              blng__Account__r.QTB_SITAD__c  //Gitlab US #22022
                                                                                              FROM blng__Invoice__c  
                                                                                              WHERE id =:rebillInvoice]);
                    InvBillingCountry = billingCountries.get(rebillInvoice).blng__Account__r.QTB_Legal_Entity_Country__c;
                    billingCountry = QTB_Billing_Countries__c.getValues(InvBillingCountry) != null ? QTB_Billing_Countries__c.getValues(InvBillingCountry).Name : '';
                    isSITAD = billingCountries.get(rebillInvoice).blng__Account__r.QTB_SITAD__c; //Gitlab US #22022
                    //Checking if Invoice country and billing country is matched, then adding orderProduct in orderProductsIds
                    //Defect Fix Gitlab US #22022 -- Allowing Default products (Fuel Surcharge) to clone for SITAD accounts
                    if((billingCountry != null && InvBillingCountry == billingCountry ) || isSITAD){                    
                        //QTB_Minimum_Storage -> 01100-0061 // QTB_Invoice_Minimum -> 02100-0003 // FuelSurcharge ->02100-0278  
                        //Add these Product Codes from Order Product    
                        for(orderitem ordI: [SELECT id, Product2.ProductCode,order.Account.QTB_Apply_Minimum_Storage_Charges__c,order.Account.QTB_Apply_Invoice_Minimum_Charges__c
                                             FROM orderitem 
                                             WHERE order.AccountId= :accId AND OrderID IN: allOrderIdSet AND QTB_PrefixMatchingID__c = null AND
                                             (Product2.ProductCode = :LABEL.QTB_Minimum_Storage OR Product2.ProductCode = :LABEL.QTB_Invoice_Minimum OR Product2.Name =:FUEL_SURCHARGE)])
                        {
                            orderProductsIds.add(ordI.Id);

						}
                    }
                }
                //Get all the Order fields from Object
                List<String> orderFieldsList = new List<String>(Order.SObjectType.getDescribe().fields.getMap().keySet());

                //Get all the OrderItem fields from Object
                List<String> ordItemFieldsList = new List<String>(OrderItem.SObjectType.getDescribe().fields.getMap().keySet());
                //Create the Query String for Order and OrderItem
                String queryOrder =' SELECT ' + String.join(orderFieldsList, ',') +' FROM Order WHERE ID= :oldOrderID ';
                String queryOrderItems = ' SELECT Product2.Name,Product2.ProductCode, PricebookEntry.UnitPrice, ' + String.join(ordItemFieldsList, ',') +' FROM Orderitem WHERE ID in:orderProductsIds ';
                String prefixMatchingID;
                
                //Query to get the Original Order
                orderToClone = (order) Database.query(queryOrder).get(0);

                //Query to get the Original OrderItem
                orderItemsListToClone = Database.query(queryOrderItems);
                
                //Change Invoice ReBill Status
                blng__Invoice__c inv = new blng__Invoice__c();
                inv.id = rebillInvoice;
                inv.QTB_ReBill_Status__c = 'Order In Progress';
                inv.QTB_ReBill_Credit_Reason__c = creditReason;
                inv.QTB_ReBill_CreditNote_Internal_Note__c = internalNotes; //For Capturing Internal Notes from Invoice to Credit Note as per #14554
                Update inv;
                
                //Clone the Order and change the Order Field values
                if(orderToClone !=null){
                    newRebillOrder = new Order();
                    newRebillOrder = orderToClone.clone();
                    newRebillOrder.Status = QTB_Constants.DRAFT_STATUS;
                    newRebillOrder.SBQQ__Contracted__c = false;
                    newRebillOrder.Type ='New';
                    newRebillOrder.QTB_OrderCategory__c='Rebill';
                    newRebillOrder.QTB_Order_OriginatorId__c = null;
                    newRebillOrder.QTB_PrevBillingOrder__c = null;
                    newRebillOrder.EffectiveDate = minStartDate; //invoiceLineList[0].blng__StartDate__c; //PROD Exception Fix
                    newRebillOrder.EndDate = null; //19333 US- Updating rebill Order end date as a blank because if Original Order has both Order Start Date and End Date then, there may be a chance that the ReBill Order End Date will be less than the ReBill Order Start Date.
                    newRebillOrder.QTB_OriginalRebillInvoice__c = rebillInvoice;
                    newRebillOrder.blng__InvoiceBatch__c = 'Rebill Run'; // Gitlab US#24173 (Credit/Rebill Billnow)
                    newRebillOrder.OwnerId = System.UserInfo.getUserId();
                    newRebillOrder.RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID;
                    newRebillOrder.QTB_Rebill_Type__c = rebillType; //SplitRebill Functionality
                    newRebillOrder.QTB_SplitRebillValue__c = splitRebillInvoiceCount;
                    
                    System.debug('newRebillOrder@@'+newRebillOrder);
                    //SBQQ.TriggerControl.disable(); //No to trigger any package logic 
                    insert newRebillOrder;
                    //SBQQ.TriggerControl.enable();
                    
                    //Change Invoice ReBill Status
                    inv.QTB_ReBill_Status__c = 'Order Completed';
                    inv.QTB_ReBillOrderId__c = newRebillOrder.Id;
                    Update inv;
                    
                    //Keep the New Order In Map
                    insertedBillingOrderMap = new Map<ID,Order>{newRebillOrder.Id=>newRebillOrder};        
                        
                    //Get the Order Number from newly created Order //// Gopi- Only need to check OrderNumber is the Mtahcing Id?
                    List<Order> newOrdList = [SELECT id, OrderNumber 
                                              FROM Order 
                                              WHERE id= :newRebillOrder.id];
                    prefixMatchingID = (newOrdList !=null && !newOrdList.isEmpty()) ? newOrdList[0].OrderNumber : '';
                    if(!orderItemsListToClone.isEmpty() && newRebillOrder!=null && 
                       !insertedBillingOrderMap.isEmpty() && prefixMatchingID != null &&
                       rebillInvoice!=null && productIdWithStartDateMap!=null && minEndDate!=null && !Test.isRunningTest() )
                    {
                        //SplitRebill -- added splitRebillInvoiceCount & rebillType paramter  
                        //Calling Queueable QTB_QueueableCreditReBillOrderItem class to create OrderItem asynchronously
                        //System.enqueueJob(new QTB_QueueableCreditReBillOrderItem(orderItemsListToClone,newRebillOrder,insertedBillingOrderMap,prefixMatchingID,
                        //                                                        mapOfRecurringNonUsageData,rebillInvoice,productIdWithStartDateMap,productIdWithEndDateMap,minStartDate,minEndDate));
                        
                        System.enqueueJob(new QTB_QueueableCreditReBillOrderItem(orderItemsListToClone,newRebillOrder,insertedBillingOrderMap,prefixMatchingID,
                                                                                 mapOfRecurringNonUsageData,rebillInvoice,productIdWithStartDateMap,productIdWithEndDateMap,minStartDate,minEndDate,splitRebillInvoiceCount,rebillType));
                        
                    }
                }  
            }
            if(newRebillOrder !=null){
                //returning newly created Order i.e. rebillOrder
                return newRebillOrder.id;  
            }
            return null;            
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_CreditReBillOrderCreation);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method      : checkExistingCreditNote
* Parameter   : Id rebillInvoice
* Return Type : String
* Author      : IRM/Virtusa
* Description : based on invoiceId creating Orders, OrderProducts by cloning existing order, OrderProduct associated with that invoice
**************************************************************************************************************/  
    @AuraEnabled
    public Static boolean checkExistingCreditNote(Id rebillInvoice)  {
        List<blng__CreditNoteLine__c> existingCreditNoteLines = [SELECT ID,blng__CreditNote__r.blng__Subtotal__c,blng__Subtotal__c,blng__Status__c 
                                                                 FROM blng__CreditNoteLine__c
                                                                 WHERE QTB_Invoice__c  =: rebillInvoice and blng__Subtotal__c > 0 and blng__Status__c != 'Cancelled'];
        
        //throwing true, if any existin credit note available for invoice.
        if (!existingCreditNoteLines.isEmpty()) {
            return true;
        }
        else{
            return false;
        }
    }
    
    /***********************************************************************************************************
* Method      : checkSubscritionBundleProducts
* Parameter   : Id parentInvoice
* Return Type : String
* Author      : IRM/Virtusa
* Description : Calling this method from this LWC component --qtb_CreditReBillProcess  
: To checking parent invoice is having Subscription Bundle Products or not, if present then returning true to throw validation
: For Split Rebill -- Subscription Bundle Products are out of scope, 
**************************************************************************************************************/  
    @AuraEnabled
    public Static boolean checkSubscritionBundleProducts(Id parentInvoice){
        //Fetching Parent Product from SBQQ__ProductOption__c where the RevenueAllocation greater than 0
        List<SBQQ__ProductOption__c> productOptionList = [SELECT Id,SBQQ__ConfiguredSKU__c, SBQQ__ConfiguredSKU__r.Name,SBQQ__OptionalSKU__c,SBQQ__OptionalSKU__r.Name,SBQQ__OptionalSKU__r.ProductCode, QTB_Revenue_Allocation__c,QTB_Forecastable__c  
                                                          FROM SBQQ__ProductOption__c
                                                          WHERE QTB_Revenue_Allocation__c > 0];
        
        //Fetching invoicelines based on parentInvoiceId
        for(blng__InvoiceLine__c invLine : [SELECT Id, Name, blng__Invoice__c, blng__Product__c, blng__Product__r.Name
                                            FROM blng__InvoiceLine__c
                                            WHERE blng__Invoice__c =:parentInvoice ])
        {
            for(SBQQ__ProductOption__c prdOption : productOptionList){
                //Checking any invoiceLine is subscription bundle product or not
                if(prdOption.SBQQ__ConfiguredSKU__c == invLine.blng__Product__c ){
                    return true;
                }
            }
        }
        return false;
    }
    /***********************************************************************************************************
* Method      : checkProductIdentifier
* Parameter   : Id parentInvoice
* Return Type : Boolean
* Author      : Virtusa
* Description : Calling this method from this LWC component --QTB_CreditReBillProcess
: If existing usage's QTB_Product_Identifier_1__c is NULL then throwing validation at the time of Credit & Rebill 
**************************************************************************************************************/ 
    @AuraEnabled(cacheable=true)
    public Static boolean checkProductIdentifier(Id parentInvoice){
        List<blng__Usage__c> usgList = new List<blng__Usage__c>();
        If(parentInvoice!= null){
        //We have to remove NADM condition while moving Phase 2 deployment
        usgList = [SELECT ID,blng__UsageSummary__r.blng__Invoice__c,QTB_Product_Identifier_1__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Data_Management__c
                                FROM blng__Usage__c 
                                WHERE QTB_Product_Identifier_1__c = null and blng__UsageSummary__r.blng__Invoice__c =:parentInvoice
                                and (blng__Account__r.QTB_Legal_Entity_Country__c NOT IN ('United States','Canada') OR blng__Account__r.QTB_Data_Management__c = FALSE)];
     } 
        if (usgList.isEmpty()) {
            return true;
        }
        else{
            return false;
        }
    }
     @AuraEnabled(cacheable=false)
    public Static String getUsageData(Id parentInvoice){
        Set<ID> usageSummaries = new Set<Id>();
        Integer totalUsageCount = 0;
        String retunString = 'Success' ;
        Map<Id, Integer> usageCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT blng__UsageSummary__c summaryId, COUNT(Id) usageCount FROM blng__Usage__c
                                   WHERE blng__UsageSummary__r.blng__Invoice__c =:parentInvoice GROUP BY blng__UsageSummary__c]) 
        {
            usageCountMap.put((Id)ar.get('summaryId'), (Integer)ar.get('usageCount'));
        }
        for (Id summaryId : usageCountMap.keySet()) {
            Integer count = usageCountMap.get(summaryId);
            totalUsageCount +=count;
            if (count > 3000) {
                retunString =  'Error' ;
            }
        }
        return retunString;
    }
}