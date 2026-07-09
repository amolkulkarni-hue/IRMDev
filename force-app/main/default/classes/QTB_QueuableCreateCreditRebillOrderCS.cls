/*****************************************************************************************************
* Class         : QTB_QueuableCreateCreditRebillOrderCS
* Test Class    : QTB_QueuableCreateCreditRebillOrdCS_Test
* Functionality : ReBill
* Author        : IRM/Virtusa
* Purpose       : This class contains methods to support credit & Rebill Process
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Developer        		Date           Description
* -----------------------------------------------------------------------------------------------------
* Gopi              06/17/2022      Initial Version - Gitlab US #9256 Credit & Rebill
* Shailesh(virtusa) 07/11/2023  	SplitRebill - Gitlab US#16557
*******************************************************************************************************/
Global class QTB_QueuableCreateCreditRebillOrderCS implements Queueable {
    
    public static final String QTB_QueuableCreateCreditRebillOrderCS = 'QTB_QueuableCreateCreditRebillOrderCS';    
    global map<Id, orderitem> mapOfOldOrderItemToNewOrderItem = new map<Id, orderitem>();
    global map<Id, List<orderitem>> mapOfOldOrderItemToNewOrderItemList = new map<Id,  List<orderitem>>();
    global String orderNumber;
    global Order newRebillOrder =new Order();
    global Map<Id,String> orderItemIdWithOrderItemNumberMap = new Map<Id,String>();
    global List<OrderItem> newOrderItemList = new List<OrderItem>();
    //global QTB_QueuableCreateCreditRebillOrderCS(map<id,orderitem> mapoldItemToNewItem, String prefixMatchingID ,Id rebillInvoice,order newOrder)
    global QTB_QueuableCreateCreditRebillOrderCS(map<id,List<orderitem>> mapoldItemToNewItemList, String prefixMatchingID )
    {
        //mapOfOldOrderItemToNewOrderItem = mapoldItemToNewItem;
        mapOfOldOrderItemToNewOrderItemList = mapoldItemToNewItemList;
        orderNumber=prefixMatchingID;
        
        if(!mapOfOldOrderItemToNewOrderItemList.isEmpty()){
            for(Id oldOrderItemId : mapOfOldOrderItemToNewOrderItemList.keySet()){
                for(orderitem ordItm : mapOfOldOrderItemToNewOrderItemList.get(oldOrderItemId)){
                    newOrderItemList.add(ordItm);
                }
            }   
        }
        
        System.debug('mapOfOldOrderItemToNewOrderItem@@'+mapOfOldOrderItemToNewOrderItem);
        if(newOrderItemList != null && !newOrderItemList.isEmpty()){
            for(OrderItem ordItm : [Select Id, OrderItemNumber,order.QTB_Legal_Entity_Country__c From OrderItem where Id IN :newOrderItemList])
            {
                orderItemIdWithOrderItemNumberMap.put(ordItm.Id,ordItm.OrderItemNumber);
            } 
        }
        System.debug('orderItemIdWithOrderItemNumberMap@@'+orderItemIdWithOrderItemNumberMap);
    }
    
    global void execute(QueueableContext qc) 
    {
        List<SBQQ__OrderItemConsumptionSchedule__c> oldOrdProdCSList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
        List<SBQQ__OrderItemConsumptionRate__c> oldOrdProdCRatesList = new List<SBQQ__OrderItemConsumptionRate__c>();        
        List<SBQQ__OrderItemConsumptionSchedule__c> newOrdProdCSList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
        List<SBQQ__OrderItemConsumptionRate__c> newOrdProdCRatesList = new List<SBQQ__OrderItemConsumptionRate__c>();
        Set<Id> oldOrderItemIDs= new Set<id>();
        Set<Id> newOrderItemsIds = new Set<Id>();
        String rebillInvoiceNumber;
        Map<Id,List<SBQQ__OrderItemConsumptionSchedule__c>>mapOfOldOPCSIdToNewOPCSListRecord = new Map<Id,List<SBQQ__OrderItemConsumptionSchedule__c>>();
        try
        {
            if(!mapOfOldOrderItemToNewOrderItemList.isEmpty()){
                for(Id oldOrdItem : mapOfOldOrderItemToNewOrderItemList.keySet() ){
                    if(oldOrdItem != null){
                        oldOrderItemIDs.add(oldOrdItem);
                    }
                } 
            }            
            System.debug('oldOrderItemIDs@@'+oldOrderItemIDs);
            
            //Get Order Item consumption schedule and rate object fields
            List<String> OPCSFieldsList = new List<String>(SBQQ__OrderItemConsumptionSchedule__c.SObjectType.getDescribe().fields.getMap().keySet());
            List<String> OPCRFieldsList = new List<String>(SBQQ__OrderItemConsumptionRate__c.SObjectType.getDescribe().fields.getMap().keyset());
            
            //Query old Order Item consumption schedule and rate object records
            String qury = ' SELECT ' + 
                String.join( OPCSFieldsList, ',' ) + 
                ' , (SELECT  '+
                String.join(OPCRFieldsList,',')+
                ' FROM SBQQ__OrderItemConsumptionRates__r ) '+
                ' FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN :oldOrderItemIDs Limit 50000' ;
            
            oldOrdProdCSList =  Database.query( qury );
            System.debug('oldOrdProdCSList.size()@@'+oldOrdProdCSList.size());
            
            if(!oldOrdProdCSList.isEmpty() && oldOrdProdCSList.size() > 0)
            {
                for(SBQQ__OrderItemConsumptionSchedule__c oldOPCS :oldOrdProdCSList)
                {
                    //SplitRebill -- checking old orderItem in mapOfOldOrderItemToNewOrderItemList
                    if(!mapOfOldOrderItemToNewOrderItemList.isEmpty() && mapOfOldOrderItemToNewOrderItemList.containsKey(oldOPCS.SBQQ__OrderItem__c)){
                        //Iterating on based on oldOrderItem its respective newOrderItem
                        for(OrderItem newOrdItem :  mapOfOldOrderItemToNewOrderItemList.get(oldOPCS.SBQQ__OrderItem__c))
                        {
                            SBQQ__OrderItemConsumptionSchedule__c newOPCS = oldOPCS.clone();
                            newOPCS.OwnerId = System.UserInfo.getUserId();//PROD Exception Fix
                            newOPCS.SBQQ__OrderItem__c = newOrdItem.Id; 
                            if(!orderItemIdWithOrderItemNumberMap.isEmpty()){
                                newOPCS.SBQQ__MatchingAttribute__c = orderNumber + orderItemIdWithOrderItemNumberMap.get(newOrdItem.Id) + newOrdItem.blng__InvoiceGroupId__c;
                            }
                            else{
                                //Gitlab US#22731 --Changing the matchingAttribute value from orderNumber to OrderItemNumber for unique value
                                newOPCS.SBQQ__MatchingAttribute__c = orderItemIdWithOrderItemNumberMap.get(newOrdItem.Id);//orderNumber;
                            }
                            newOrdProdCSList.add(newOPCS);  
                            if(mapOfOldOPCSIdToNewOPCSListRecord.containsKey(oldOPCS.Id)){
                                mapOfOldOPCSIdToNewOPCSListRecord.get(oldOPCS.Id).add(newOPCS);
                            }else{
                                mapOfOldOPCSIdToNewOPCSListRecord.put(oldOPCS.Id,new List<SBQQ__OrderItemConsumptionSchedule__c>{newOPCS});  
                            }
                            System.debug('newOPCS@@'+newOPCS);
                        } 
                    }
                    //Collect all child Old OPCR Records
                    if(!oldOPCS.SBQQ__OrderItemConsumptionRates__r.isEmpty())
                    {
                        oldOrdProdCRatesList.addAll(oldOPCS.SBQQ__OrderItemConsumptionRates__r);
                    }
                }
                
                if(!newOrdProdCSList.isEmpty() && newOrdProdCSList.size() > 0)
                {
                    insert newOrdProdCSList;
                    System.debug('insert cs@@'+newOrdProdCSList);
                }
                
                if(!oldOrdProdCRatesList.isEmpty())
                {
                    for(SBQQ__OrderItemConsumptionRate__c oldOPCRate: oldOrdProdCRatesList)
                    {
                        //SplitRebill -- checking oldOPCS in map mapOfOldOPCSIdToNewOPCSListRecord
                        if(!mapOfOldOPCSIdToNewOPCSListRecord.isEmpty() && mapOfOldOPCSIdToNewOPCSListRecord.containsKey(oldOPCRate.SBQQ__OrderItemConsumptionSchedule__c))
                        {	
                            //SplitRebill -- iterating new OrderProduct CS based on old orderProduct CS
                            for(SBQQ__OrderItemConsumptionSchedule__c newOrdPrdCS : mapOfOldOPCSIdToNewOPCSListRecord.get(oldOPCRate.SBQQ__OrderItemConsumptionSchedule__c))
                            {
                                SBQQ__OrderItemConsumptionRate__c newOPCRate = oldOPCRate.clone();
                                newOPCRate.SBQQ__OrderItemConsumptionSchedule__c = newOrdPrdCS.id;
                                newOrdProdCRatesList.add(newOPCRate);
                            }
                        }
                    }
                    if(!newOrdProdCRatesList.isEmpty())
                    {
                        insert newOrdProdCRatesList;
                    }
                }
                //SplitRebill - Defect Gitlab US#17510
                QTB_OrderProductHelper.updateCSRates(newOrderItemList,false); //Update OrderProductCS
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_QueuableCreateCreditRebillOrderCS);
            throw e;
        }
    }
}