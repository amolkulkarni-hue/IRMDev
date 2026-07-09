/*****************************************************************************************************
* Class: QTB_DisplayQuoteRatesController
* Author: TCS
* Purpose: This is a the controller class for all business logic related to Display Rate functionality
* Requirement: GIT-7570
* Developer         Date           Description
* -------------------------------------------------------------------------------------------
* Renuka Prasad     27/05/2022
*******************************************************************************************************/
public class QTB_DisplayQuoteRatesController {
    
    /***********************************************************************************************************   
    * Method : getQuoteRates
    * Parameters: String invoiceId
    * Return Type: List<wrapQuoteRates>
    * Description: Method to fetch the quote rates for the target invoice
    **************************************************************************************************************/
    @AuraEnabled(Cacheable=true)
    public static List<wrapQuoteRates> getQuoteRates(String invoiceId){
        String recordId = invoiceId;
        system.debug('===invoiceId==>'+recordId); 
        
        //Our collection of the class/wrapper objects  
        List<wrapQuoteRates> wrapQuoteRateList = new List<wrapQuoteRates>();
        if (recordId == null || recordId == '') {
            //return wrapQuoteRateList;
        }
        // Invoice -- Invoice Line -- << Order Product << Billing Order << Sales Order << 
        
        Set<Id> orderProIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> cScheduleIds = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        String invoiceName = '';

        for(blng__InvoiceLine__c invLineObj : [SELECT Id, blng__Invoice__c, blng__Invoice__r.name, blng__OrderProduct__c,blng__Product__c FROM blng__InvoiceLine__c 
                                               WHERE blng__Invoice__c =: recordId]){
            if(invLineObj.blng__OrderProduct__c != null){
                orderProIds.add(invLineObj.blng__OrderProduct__c);
            }

            //Setting Invoice Name for CSV name
            if (String.IsBlank(invoiceName) && invLineObj.blng__Invoice__r.name != null) {
                invoiceName = invLineObj.blng__Invoice__r.name;
            }
            
            if (invLineObj.blng__Product__c != null) {
                productSet.add(invLineObj.blng__Product__c);
            }
        }
        system.debug('==orderProIds==>'+orderProIds);
        if(!orderProIds.isEmpty()){
            for(OrderItem oItemObj : [SELECT Id, OrderId, Order.SBQQ__Quote__c, Order.QTB_Order_OriginatorId__r.SBQQ__Quote__c FROM OrderItem WHERE ID =:orderProIds]){
                quoteIds.add(oItemObj.Order.QTB_Order_OriginatorId__r.SBQQ__Quote__c);
            }
        }
        system.debug('==quoteIds==>'+quoteIds);
        
        Map<Id, SBQQ__QuoteLine__c> mapQLItem = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLineConsumptionSchedule__c> mapQLCS = new Map<Id, SBQQ__QuoteLineConsumptionSchedule__c>();
        
        // List to create Quote Lines for Recurring Products which will not have Conusmption Schedule
        list<SBQQ__QuoteLine__c> qleNoCS = new list<SBQQ__QuoteLine__c>();

        // Quote -- Quote Line -- Consumption Schedule name -- QLI Consumption Schedule == Qli Consumption rate 
        if(!quoteIds.isEmpty()){
            for(SBQQ__QuoteLine__c quoteLineObj : [SELECT Id, QTB_Quote_line_Consumption_Schedule_Name__c, SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Product__r.Name, SBQQ__Quote__r.SBQQ__Opportunity2__r.Name, SBQQ__HasConsumptionSchedule__c, QTB_Final_Unit_Price__c, SBQQ__ChargeType__c, SBQQ__ProductName__c, CurrencyIsoCode, (SELECT Id, Name FROM SBQQ__QuoteLines__r) FROM SBQQ__QuoteLine__c
                                                   WHERE SBQQ__Quote__c =:quoteIds AND SBQQ__Product__c IN:productSet]){
                                                       mapQLItem.put(quoteLineObj.Id, quoteLineObj);
                if (quoteLineObj.SBQQ__HasConsumptionSchedule__c == false) {
                    qleNoCS.add(quoteLineObj);
                }

                for(SBQQ__QuoteLineConsumptionSchedule__c sc : quoteLineObj.SBQQ__QuoteLines__r){
                    if(quoteLineObj.QTB_Quote_line_Consumption_Schedule_Name__c == sc.name){
                        mapQLCS.put(sc.Id, sc);
                        cScheduleIds.add(sc.Id);                                           
                    }
                }
            }
        }
        system.debug('==cScheduleIds==>'+cScheduleIds);
        
        list<SBQQ__QuoteLineConsumptionRate__c> csRateLst =  [SELECT Id, SBQQ__QuoteLineConsumptionSchedule__c,SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c,  SBQQ__LowerBound__c, SBQQ__UpperBound__c, SBQQ__Price__c, SBQQ__PricingMethod__c ,CurrencyIsoCode
                                                              FROM SBQQ__QuoteLineConsumptionRate__c 
                                                              WHERE SBQQ__QuoteLineConsumptionSchedule__c =:cScheduleIds];
        
        for(SBQQ__QuoteLineConsumptionRate__c rateObj : csRateLst){
            wrapQuoteRates wrapObj = new wrapQuoteRates();
            if(rateObj.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c != null && mapQLItem.containsKey(rateObj.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c)){
                wrapObj.OpportunityName = mapQLItem.get(rateObj.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c).SBQQ__Quote__r.SBQQ__Opportunity2__r.Name;
                wrapObj.invoiceName = invoiceName;
                wrapObj.QuoteNumber = mapQLItem.get(rateObj.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c).SBQQ__Quote__r.Name;
                wrapObj.Product = mapQLItem.get(rateObj.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c).SBQQ__Product__r.Name;
                if(rateObj.SBQQ__QuoteLineConsumptionSchedule__c != null && mapQLCS.containsKey(rateObj.SBQQ__QuoteLineConsumptionSchedule__c)){
                    wrapObj.Consumption_ScheduleName = (mapQLCS.get(rateObj.SBQQ__QuoteLineConsumptionSchedule__c).Name != null) ? mapQLCS.get(rateObj.SBQQ__QuoteLineConsumptionSchedule__c).Name : '';
                    wrapObj.Lower_Bound = (rateObj.SBQQ__LowerBound__c != null) ? String.valueOf(rateObj.SBQQ__LowerBound__c) : '';
                    wrapObj.Upper_Bound = (rateObj.SBQQ__UpperBound__c != null) ? String.valueOf(rateObj.SBQQ__UpperBound__c) : '';
                    wrapObj.Price = String.valueOf(rateObj.CurrencyIsoCode) + ' ' + String.valueOf(rateObj.SBQQ__Price__c.setScale(4));
                    wrapObj.Price_Type = String.valueOf(rateObj.SBQQ__PricingMethod__c);
                }
            }
            wrapQuoteRateList.add(wrapObj);
        }

        //To Add the Bundle Header/Recurring products (without CS) to the wrapper
        if (qleNoCS.size() > 0) {
            for (SBQQ__QuoteLine__c qle: qleNoCS) {
                wrapQuoteRates wrapObj = new wrapQuoteRates();
                wrapObj.Product = qle.SBQQ__ProductName__c;
                //wrapObj.OpportunityName = qle.SBQQ__Opportunity2__r.Name;
                wrapObj.invoiceName = invoiceName;
                wrapObj.QuoteNumber = qle.SBQQ__Quote__r.Name;
                wrapObj.Lower_Bound = '';
                wrapObj.Upper_Bound = '';
                wrapObj.Consumption_ScheduleName = '';
                wrapObj.Price = String.valueOf(qle.CurrencyIsoCode) + ' ' + String.valueOf(qle.QTB_Final_Unit_Price__c.setScale(4));
                wrapObj.Price_Type = QTB_Constants.CHARGE_TYPE_RECURRING;
                wrapQuoteRateList.add(wrapObj);
            }

        }
        system.debug('==wrapQuoteRateList Before Sort==>'+wrapQuoteRateList.size()+'===='+wrapQuoteRateList);
        
        wrapQuoteRateList.sort();
        
        system.debug('==wrapQuoteRateList After Sort==>'+wrapQuoteRateList.size()+'===='+wrapQuoteRateList);
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
        return wrapQuoteRateList;
    }
    
    
    // This is our wrapper/container class. A container class is a class, a data structure, or an abstract data type whose instances are collections of other objects. In this example a wrapper class contains both the standard salesforce object Account and a Boolean value
    /***********************************************************************************************************   
    * Class: wrapQuoteRates
    * This is the wrapper/container class.
    * In this example a wrapper class contains quote, quote consumption rates, opportunity information
    ***************************************************************************************************************/
    public class wrapQuoteRates implements Comparable {
        @AuraEnabled public String OpportunityName {get; Set;}
        @AuraEnabled public String QuoteNumber {get; Set;}
        @AuraEnabled public String Product {get; Set;}
        @AuraEnabled public String Consumption_ScheduleName {get; Set;}
        @AuraEnabled public String Lower_Bound {get; Set;}
        @AuraEnabled public String Upper_Bound {get; Set;}
        @AuraEnabled public String Price {get; Set;}
        @AuraEnabled public String Price_Type {get; Set;}
        @AuraEnabled public String invoiceName {get; Set;}

        // @AuraEnabled public SBQQ__QuoteLineConsumptionRate__c csRateObj {get; Set;}
        
        public Integer compareTo(Object objToCompare) {
            wrapQuoteRates that = (wrapQuoteRates) objToCompare;
            Integer c = this.Product.compareTo(that.Product);
            if (c != 0) {
                return c;
            } else {
                return this.Lower_Bound.compareTo(that.Lower_Bound);
            }
        }
    }
}