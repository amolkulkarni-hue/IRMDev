public class QTB_OrderUsageSummaryMatchingAttribute {
    @InvocableMethod(label = 'updateMatchingAttribute' description='CaseNumberToMatchingAttribute') 
    public static void updateMatchingAttribute(List<Id> orderIds) { // pass in list of order ids 
		boolean flagCaseNumberExist = true;
        System.debug('Order ids passed: ' + orderIds);
        List<Order> orders = [Select Id, QTB_Case_Number__c from Order where id in :orderIds limit 50000]; // grab all orders w/ case number
        List<blng__UsageSummary__c> listOfUsageSummaries = new List<blng__UsageSummary__c>();
        List<OrderItem> orderItems = [SELECT Id, Order.id, QTB_Product_Line__c from OrderItem where Order.id in :orderIds AND QTB_Product_Line__c like 'ALM-Secure ITAD' limit 50000]; //grab all order items related to the orders
        
        Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>();
        Map<Id, Order> orderMap = new Map<Id, Order>();
        
        for (Order o : orders) {
            orderMap.put(o.Id, o);
        }
        
        for (OrderItem oi : orderItems) {
            orderItemsMap.put(oi.id, oi);
        }
        
        System.debug('OrderItems to pass: ' + orderItems);
        List<blng__UsageSummary__c> usgSums = [SELECT Id, blng__OrderProduct__c, blng__MatchingAttribute__c from blng__UsageSummary__c WHERE blng__OrderProduct__c in :orderItems limit 50000];  // grab all usage summaries related to all order items 
        System.debug('usgSums: ' + usgSums.size() + usgSums);

        if (!usgSums.isEmpty() /*&& order[0].QTB_Case_Number__c != null*/) {
            for (blng__UsageSummary__c usgSum : usgSums) {
                //w/ usgsum orderproduct find orderitem with matching id 
                //with orderitem find order with order id 
                OrderItem oIGet = orderItemsMap.get(usgSum.blng__OrderProduct__c); // using the usgSum order product, finds order item w/ same order product id  
                Order oGet = orderMap.get(oIGet.Order.Id); // with order item finds the matching order with order.id on orderitem
                if (oGet.QTB_Case_Number__c != null) {
               		usgSum.blng__MatchingAttribute__c = oGet.QTB_Case_Number__c; // with matching order gets the case number and sets the matching attribute on the usg sum
                } 
                else {
                    flagCaseNumberExist = false;
                }
            }
        }
        try {
            System.debug('Begin update: ' + usgSums);
            if (!usgSums.isEmpty() && flagCaseNumberExist) update usgSums;
        } catch (Exception e) {
            System.debug('Exception: ' + e);
        }
    }
}