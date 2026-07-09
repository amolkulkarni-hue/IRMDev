/*****************************************************************************************************
* Class: QTB_OrderPlugin
* Author: IRM/Virtusa
* Purpose: This is a orderManagmentPlugin class to set Order Start Date as per business requirment.
* Requirement: Git #6306 / #5837
* Change History: 11/22/2021
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* IRM/Virutsa  11/22/2021    #6306 Order not getting created, for different dates.
                             -> Update 'Order start Date' from the Case 'Billing Start Date'
                             Earlier the Order start Date was set by the Package Level setting CPQ Package -> Tab -> Order -> Default Order Start Date -> Quote STart Date
                             But later as per custom requirement based on the NCSP story we need diff date should be the Order start Date
                             So the below code is written as part of Order Plugin -> Package -> Tab -> Plugin -> Order Management Plugin(QTB_OrderPlugin)
*******************************************************************************************************/
global class QTB_OrderPlugin implements SBQQ.OrderManagementPlugin{
    
    public Date getOrderStartDate(Id quoteId) {
    
        Date orderStart;
       
        //Query for Quote that matches provided record ID and retrieve quote data
        List<SBQQ__Quote__c> theQuoteList = [SELECT Id,SBQQ__Primary__c,SBQQ__StartDate__c,SBQQ__Opportunity2__c 
                                             FROM SBQQ__Quote__c 
                                             WHERE Id = :quoteId LIMIT 1];
        
         if(!theQuoteList.isEmpty() &&  theQuoteList.size() > 0) {
             // This logic is for All Orders
            orderStart = theQuoteList[0].SBQQ__StartDate__c; //assiging QuoteStartDate to OrderStartDate
            // This logic is specific to NCSP Case as per the Git Story #5837
            if(theQuoteList[0].SBQQ__Opportunity2__c !=null){
               List<Case> ncspCaseList = [Select id, QTB_Billing_Start_Date__c,NCSP_Opportunity__c 
                                          From Case
                                          Where NCSP_Opportunity__c =:theQuoteList[0].SBQQ__Opportunity2__c
                                          and QTB_Billing_Start_Date__c != null]; //fetching Case record where BillingStartDate not null 
                
                if(!ncspCaseList.isEmpty() && ncspCaseList.size() > 0){
                    orderStart = ncspCaseList[0].QTB_Billing_Start_Date__c; // assiging Case.BillingStartDate to OrderStartDate
                }
            }
        } 
        
        return(orderStart);
    }
}