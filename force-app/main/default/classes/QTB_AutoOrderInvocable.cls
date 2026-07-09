public class QTB_AutoOrderInvocable {
    
    @InvocableMethod
    public static list<list<orderitem>> updateOrderItemDetails(list <flowInputs> request)
    {
        list <orderItem> newOrderItemsList= new list<orderItem>();
         list <list<orderItem>> newOrderItemsListToList= new list <list<orderItem>>();

        Map<String,PriceBookEntry> priceBookEntryDetails = new map<String,PriceBookEntry>();
        Map<String,Product2> product2Details = new MAp<String,Product2>();
        
        
        
        For(flowInputs flow:request)
           
        {
            
            for(PriceBookEntry book:[select Id, Name, Pricebook2Id, Product2Id, CurrencyIsoCode,
                                     UnitPrice, IsActive, ProductCode, Product_Name__c  
                                     from PricebookEntry where ProductCode in :flow.productCodes and
                                     Pricebook2Id = :flow.oldOrderData.Pricebook2Id and CurrencyIsoCode = :flow.oldOrderData.CurrencyIsoCode and IsActive=True])
            {
                priceBookEntryDetails.put(book.ProductCode ,book);
            }
            
            
            for(Product2 pro:[Select SBQQ__SubscriptionTerm__c,SBQQ__SubscriptionType__c,SBQQ__SubscriptionPricing__c,ProductCode from Product2 where ProductCode  in :flow.productCodes])
            {
                product2Details.put(pro.ProductCode,pro);
                
            }
            
            for(string code : flow.productCodes)
            {
                
                orderItem item = new orderItem();
                item.PricebookEntryId = priceBookEntryDetails.get(code).Id;
                item.Product2Id = product2Details.get(code).Id;
                item.QTB_Final_Unit_Price__c = priceBookEntryDetails.get(code).UnitPrice;
                item.SBQQ__DefaultSubscriptionTerm__c =product2Details.get(code).SBQQ__SubscriptionTerm__c;
                item.SBQQ__ProductSubscriptionType__c = product2Details.get(code).SBQQ__SubscriptionType__c;
                item.SBQQ__SubscriptionPricing__c = product2Details.get(code).SBQQ__SubscriptionPricing__c;
                item.SBQQ__SubscriptionType__c = product2Details.get(code).SBQQ__SubscriptionType__c;
                item.blng__BillableUnitPrice__c = priceBookEntryDetails.get(code).UnitPrice;
                newOrderItemsList.add(item);
            }
            
        }
        newOrderItemsListToList.add(newOrderItemsList);
        return newOrderItemsListToList;    
    }
    
    Public class flowInputs{
        
        @InvocableVariable
        public Account billingAccount;
        
        @InvocableVariable
        public Order oldOrderData;
        
        @InvocableVariable
        Public orderitem oldOrderItemData;
        
        @InvocableVariable        
        Public	Date orderProductStartDate;
        
        @InvocableVariable    
        Public Date orderProductEndDate;
        
        @InvocableVariable    
        Public String newOrderCreatedId;
        
        @InvocableVariable
        Public list<String> productCodes;
        
        
    }
    
    
}