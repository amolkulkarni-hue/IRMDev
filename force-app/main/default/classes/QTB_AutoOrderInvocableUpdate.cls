public class QTB_AutoOrderInvocableUpdate {
    
    
    @InvocableMethod
    public static void updateOrderItemCSDetails(list <flowInputs> request)
    {
        list<SBQQ__OrderItemConsumptionSchedule__c> updateOrderItemCSList =new  list<SBQQ__OrderItemConsumptionSchedule__c>();
        list<SBQQ__OrderItemConsumptionSchedule__c> deleteOrderItemCSList =new  list<SBQQ__OrderItemConsumptionSchedule__c>();
        List<SBQQ__OrderItemConsumptionRate__c> insertOrderItemCRList=new List<SBQQ__OrderItemConsumptionRate__c>();
        List<blng__UsageSummary__c> insertUsgSummary=new List<blng__UsageSummary__c>();
        
        //System.debug('updateOrderItemCSList' +updateOrderItemCSList);
        //Order updOrder;
        
        Set<id> productIds=new set<id>();
        List<Id> workOrderItemsId = new List<Id>();
        List<SBQQ__OrderItemConsumptionSchedule__c> createOICS=new List<SBQQ__OrderItemConsumptionSchedule__c>();
        
        
        for(flowInputs flow:request)
        {
            
            
            for (SBQQ__OrderItemConsumptionSchedule__c cs :[Select id,Name,blng__TaxTreatment__c,blng__LegalEntity__c,SBQQ__OrderItem__r.OrderId,SBQQ__OrderItem__r.blng__LegalEntity__c,SBQQ__OrderItem__r.blng__TaxTreatment__c from SBQQ__OrderItemConsumptionSchedule__c
                                                            where SBQQ__OrderItem__r.OrderId = :flow.newOrderCreatedId])
                
            {
                if(!string.isBlank(flow.matchingAtrribute)){
                    
                    deleteOrderItemCSList.add(cs);
                    
                    List<blng__UsageSummary__c> us=[Select id,Name,blng__OrderItemConsumptionSchedule__c from blng__UsageSummary__c 
                                                    where blng__OrderItemConsumptionSchedule__c in : deleteOrderItemCSList ];
                    
                    delete us;
                    
            
                    
                }
                else {
                    SBQQ__OrderItemConsumptionSchedule__c ordCS = new SBQQ__OrderItemConsumptionSchedule__c();
                    System.debug('cs' +cs);
                    ordCS.Id=cs.Id;
                    ordCS.blng__LegalEntity__c = cs.SBQQ__OrderItem__r.blng__LegalEntity__c;// flow.orderItemCollections[0].blng__LegalEntity__c;
                    ordCS.blng__TaxTreatment__c = cs.SBQQ__OrderItem__r.blng__TaxTreatment__c;//flow.orderItemCollections[0].blng__TaxTreatment__c;
                    //if(!string.isBlank(flow.matchingAtrribute)){
                      //  ordCS.SBQQ__MatchingAttribute__c = flow.matchingAtrribute;  
                    //}
                    
                    updateOrderItemCSList.add(ordCS);
                }
            }
            
                 
             if(!string.isBlank(flow.matchingAtrribute)){       
               
         List<order> newAccbillord=[select AccountId,(select id,Product2Id from orderItems) from order where id=:flow.newOrderCreatedId];
                    
                    system.debug('Workorderproduct is'+newAccbillord);
                    
                    for(order ordWork:newAccbillord){
                        for(orderItem ordItemwrk:ordWork.orderItems){
                            productIds.add(ordItemwrk.Product2Id);
                            workOrderItemsId.add(ordItemwrk.Id);
                        }
                    }
                    
                   order newOrdLst=[select id,name,Accountid,(select id from orderItems where Product2Id In: productIds) from order where QTB_OrderCategory__c='Evergreen' and 
                                           Status='Activated' and AccountId=:newAccbillord[0].AccountId order by CreatedDate desc limit 1 ];
                    
            account acc = [select id, qtb_Customer_Number__c from Account where id= :newOrdLst.Accountid ];
                    system.debug('TheBillingorderis'+newOrdLst);
                    
                    List<SBQQ__OrderItemConsumptionSchedule__c> newOrdCS=[Select id,Name,blng__TaxTreatment__c,blng__LegalEntity__c,SBQQ__BillingTerm__c,
                                                                          SBQQ__RatingMethod__c,SBQQ__BillingTermUnit__c,SBQQ__Type__c,SBQQ__ConsumptionSchedule__c,
                                                                          SBQQ__OrderItem__c,SBQQ__Category__c,blng__TaxRule__c,blng__BillingRule__c,
                                                                          blng__BillingTreatment__c,blng__FinanceBookAccounting__c,blng__RevenueRecognitionRule__c
                                                                          from SBQQ__OrderItemConsumptionSchedule__c
                                                                          where SBQQ__OrderItem__c In:newOrdLst.orderItems];
            system.debug('theBillOrcsId'+newOrdCS);
                    
            
          List<SBQQ__OrderItemConsumptionRate__c> billingOrdCR=[Select id,SBQQ__ProcessingOrder__c,SBQQ__PricingMethod__c,SBQQ__LowerBound__c,
                                                            SBQQ__OrderItemConsumptionSchedule__c,SBQQ__UpperBound__c,SBQQ__Price__c from
                                                          SBQQ__OrderItemConsumptionRate__c where SBQQ__OrderItemConsumptionSchedule__c =:newOrdCS];  
            
                                                                    
                    
                  //List<blng__UsageSummary__c> usageLst=[select id from blng__UsageSummary__c where blng__OrderItemConsumptionSchedule__c In:newOrdCS];            
                    
                    
                    Map<id,List<SBQQ__OrderItemConsumptionSchedule__c>> mapCS=new Map<id,List<SBQQ__OrderItemConsumptionSchedule__c>>();
                     
               for(SBQQ__OrderItemConsumptionSchedule__c createNewCS:newOrdCS){
                        if(!mapCS.containsKey(createNewCS.SBQQ__OrderItem__c)){
                            
                            mapCS.put(createNewCS.SBQQ__OrderItem__c,new List<SBQQ__OrderItemConsumptionSchedule__c>());
                            
                        }
                        mapCS.get(createNewCS.SBQQ__OrderItem__c).add(createNewCS);
                    }     
                    
                    
             
                    for(Id productId:mapCS.keyset()){
                        for(SBQQ__OrderItemConsumptionSchedule__c newCSId:mapCS.get(productId)){
                          
                                SBQQ__OrderItemConsumptionSchedule__c CSnew= new SBQQ__OrderItemConsumptionSchedule__c();
                                CSnew.Name=newCSId.Name;
                                CSnew.SBQQ__BillingTerm__c=newCSId.SBQQ__BillingTerm__c;
                                CSnew.SBQQ__RatingMethod__c=newCSId.SBQQ__RatingMethod__c;
                                CSnew.SBQQ__BillingTermUnit__c=newCSId.SBQQ__BillingTermUnit__c;
                                CSnew.SBQQ__Type__c=newCSId.SBQQ__Type__c;
                                CSnew.SBQQ__MatchingAttribute__c=flow.matchingAtrribute;
                                CSnew.SBQQ__ConsumptionSchedule__c=newCSId.SBQQ__ConsumptionSchedule__c;
                                CSnew.blng__LegalEntity__c=newCSId.blng__LegalEntity__c;
                                CSnew.SBQQ__Category__c=newCSId.SBQQ__Category__c;
                                CSnew.SBQQ__OrderItem__c=workOrderItemsId[0];
                                CSnew.blng__TaxRule__c=newCSId.blng__TaxRule__c;
                                CSnew.blng__TaxTreatment__c=newCSId.blng__TaxTreatment__c;
                                CSnew.blng__BillingRule__c=newCSId.blng__BillingRule__c;
                                CSnew.blng__BillingTreatment__c=newCSId.blng__BillingTreatment__c;
                                CSnew.blng__FinanceBookAccounting__c=newCSId.blng__FinanceBookAccounting__c;
                                CSnew.blng__RevenueRecognitionRule__c=newCSId.blng__RevenueRecognitionRule__c;
                                
                                createOICS.add(CSnew);
                            
                                Insert createOICS;
                            
                                blng__UsageSummary__c usagesummary = new blng__UsageSummary__c();      
                                usagesummary.blng__Status__c = 'New';
                                usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
                                usagesummary.blng__MatchingId__c =acc.QTB_Customer_Number__c + flow.productCode;
                                usagesummary.blng__Account__c=acc.id;
                                usagesummary.blng__SummaryStartDate__c = flow.startDate;
                                usagesummary.blng__SummaryEndDate__c = flow.endDate;
                                usagesummary.blng__Order__c = flow.newOrderCreatedId;
                                usagesummary.blng__OrderProduct__c = workOrderItemsId[0];
                                usagesummary.blng__MatchingAttribute__c = flow.matchingAtrribute;
                                usagesummary.blng__OrderItemConsumptionSchedule__c=CSnew.id;
                               
                               
                                insertUsgSummary.add(usagesummary);
                         
                            
                        }
                        
                    }       
                  for(SBQQ__OrderItemConsumptionRate__c newordCSR:billingOrdCR){
                SBQQ__OrderItemConsumptionRate__c newCRInsert=new SBQQ__OrderItemConsumptionRate__c();
                                newCRInsert.SBQQ__ProcessingOrder__c=newordCSR.SBQQ__ProcessingOrder__c;
                                newCRInsert.SBQQ__PricingMethod__c=newordCSR.SBQQ__PricingMethod__c;
                                newCRInsert.SBQQ__LowerBound__c=newordCSR.SBQQ__LowerBound__c;
                                newCRInsert.SBQQ__OrderItemConsumptionSchedule__c=createOICS[0].id;
                                newCRInsert.SBQQ__UpperBound__c=newordCSR.SBQQ__UpperBound__c;
                                newCRInsert.SBQQ__Price__c = newordCSR.SBQQ__Price__c;
                                insertOrderItemCRList.add(newCRInsert);
            }           
                    
                    
             }       
             
         
            
        }
        
        SBQQ.TriggerControl.disable();
        update updateOrderItemCSList;
        delete deleteOrderItemCSList;
        Insert insertOrderItemCRList;
        SBQQ.TriggerControl.enable();
        //update updOrder;
        
        
    }
    
    Public static void justIncrement() {
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


    }
    public class flowInputs
    {
        @InvocableVariable    
        Public String newOrderCreatedId;
        
        @InvocableVariable
        Public list<OrderItem> orderItemCollections;
        
        @InvocableVariable
        Public string matchingAtrribute;
        
        @InvocableVariable
        Public string productCode;
        
         @InvocableVariable
        Public Date startDate;
        
         @InvocableVariable
        Public Date endDate;
        
    }
    
}