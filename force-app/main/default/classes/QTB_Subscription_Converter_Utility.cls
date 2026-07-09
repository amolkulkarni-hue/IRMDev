/*****************************************************************************************************
* Class: QTB_Subscription_Converter_Utility
* Author: Iron Mountain
* Purpose: Utility Class to convert Price Schedule-based Subscription Records to Consumption Schedule-based records for Finland Renewals/Amends
* Requirement: 
* Change History: 11/10/2021
* Developer      Date           Description
* -------------------------------------------------------------------------------------------
* Iron Moutnain   11/10/2021    Initial release (D.Baumann)
*******************************************************************************************************/

public with sharing class QTB_Subscription_Converter_Utility {

    /***********************************************************************************************************
    * Method : convertSubscriptionFromPriceScheduleToConsumptionSchedule
    * Parameters: List<String> contractIds
    * Requirement :
    * Returns : void
    * Author : Iron Mountain
    * Description: Invocable method called from flow to initiate update of subscription records and creation of related
    *              Subscription Consumption Schedules and Subscription Consumption Rates
    **************************************************************************************************************/

    @InvocableMethod(
            label='Convert From Price Schedule to Consumption Schedule'
            description='For testing out renewal conversion into CS model.'
    )
    public static void convertSubscriptionFromPriceScheduleToConsumptionSchedule(List<String> contractIds){
        //strart v2 of conversion
        //Get the ContractId
        String contractId = contractIds[0];
        List<String> resultsString = new List<String>();
        if(!contractIds.isEmpty()){
            System.debug(contractId);
    
            //Setup Set of products in scope obtained from Subs
            Set<Id> productIds = new Set<Id>();
    
            //Setup Product Consumption Schedules - this is junction between products and conssched
            List<ProductConsumptionSchedule> productConsumptionSchedules = new List<ProductConsumptionSchedule>();
    
            //Map of productID and related ConsSchedule
            Map<Id, ConsumptionSchedule> productConsumptionScheduleMap = new Map<Id, ConsumptionSchedule>();
    
            //List for SubConsSched we'll need to add
            List<SBQQ__SubscriptionConsumptionSchedule__c> subscriptionConsumptionSchedules = new List<SBQQ__SubscriptionConsumptionSchedule__c>();
    
            //List for SubConsRate we'll need to add
            List<SBQQ__SubscriptionConsumptionRate__c> subscriptionConsumptionRates = new List<SBQQ__SubscriptionConsumptionRate__c>();
    
            //only 525 CS, getting all for purposes of this exercise -small amount to store temp
            List<ConsumptionSchedule> consumptionSchedules = [SELECT Id, Name, RatingMethod, Type,MatchingAttribute, SBQQ__Category__c, BillingTerm, CurrencyIsoCode, BillingTermUnit FROM ConsumptionSchedule];
    
            //Create Map of CS to easily extract details
            Map<Id, ConsumptionSchedule> consumptionScheduleMap = new Map<Id, ConsumptionSchedule>(consumptionSchedules);
    
            //only 853 CS, getting all for purposes of this exercise -small amount to store temp
            List<ConsumptionRate> consumptionRates = [SELECT Id, Name, ProcessingOrder, PricingMethod, LowerBound, UpperBound, Price, CurrencyIsoCode, ConsumptionScheduleId FROM ConsumptionRate];
    
            //Create Map Id is CS Id and the rate
            Map<Id, ConsumptionRate> consumptionScheduleRateMap = new Map<Id, ConsumptionRate>();
            
            //List of subscription records from Contract
            List<SBQQ__Subscription__c> subscriptions = [SELECT Id, SBQQ__Product__c, SBQQ__ChargeType__c, SBQQ__BillingType__c, SBQQ__HasConsumptionSchedule__c, SBQQ__RenewalPrice__c,QTB_Final_Unit_Price__c  FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c = :contractId AND SBQQ__ChargeType__c = 'Usage'];
            system.debug('subscriptionproduct'+subscriptions);
            Contract ContractRecord = [SELECT Id, QTB_Converted_to_Consumption_Schedule__c from Contract where id = :contractId];
            
            //Get the Subscriptions update to new model
            //populate productIds
            for(SBQQ__Subscription__c subscription : subscriptions){
                productIds.add(subscription.SBQQ__Product__c);
                
            }
            
            system.debug('productIds'+productIds);
            productConsumptionSchedules = [SELECT Id, ConsumptionScheduleId, ProductId FROM ProductConsumptionSchedule WHERE ProductId IN :productIds];
            system.debug('productConsumptionSchedules'+productConsumptionSchedules);
            for(SBQQ__Subscription__c subscription : subscriptions)
            {
                for(ProductConsumptionSchedule productConsumptionSchedule : productConsumptionSchedules)
                {
                    if(subscription.SBQQ__Product__c == productConsumptionSchedule.ProductId)
                    {
                        //if(consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).CurrencyIsoCode=='EUR')
                        {                
                            // update subscription
                            subscription.SBQQ__ChargeType__c = 'Recurring';
                            subscription.SBQQ__HasConsumptionSchedule__c = TRUE;
                            subscription.SBQQ__BillingType__c = 'Arrears';
                            
                            
                            //create associated consSched, able to do 1:1
                            SBQQ__SubscriptionConsumptionSchedule__c subscriptionConsumptionSchedule = new SBQQ__SubscriptionConsumptionSchedule__c(
                                Name = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).Name,//add name from get
                                SBQQ__RatingMethod__c = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).RatingMethod,
                                SBQQ__Type__c = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).Type,
                                SBQQ__ConsumptionSchedule__c = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).Id,//add id from get
                                SBQQ__Category__c = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).SBQQ__Category__c,
                                SBQQ__Subscription__c = subscription.Id,
                                SBQQ__BillingTerm__c = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).BillingTerm,
                                SBQQ__BillingTermUnit__c = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).BillingTermUnit,
                                SBQQ__MatchingAttribute__c = consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).MatchingAttribute,
                                QTB_External_Id__c = subscription.Id + '-' + productConsumptionSchedule.ConsumptionScheduleId,
                                CurrencyIsoCode = 'EUR'
                            );
                            
                            subscriptionConsumptionSchedules.add(subscriptionConsumptionSchedule);
                            System.debug(subscriptionConsumptionSchedule);
                            
                            
                            for(ConsumptionRate consumptRate : consumptionRates)
                            {
                                if(consumptRate.ConsumptionScheduleId == productConsumptionSchedule.ConsumptionScheduleId)
                                {
                                    if(consumptRate.CurrencyIsoCode=='EUR')
                                    {
                                        try {
                                            
                                            //create tier rate                                           
                                            SBQQ__SubscriptionConsumptionRate__c subscriptionConsumptionRate = new SBQQ__SubscriptionConsumptionRate__c();
                                                subscriptionConsumptionRate.Name = consumptRate.Name;
                                                subscriptionConsumptionRate.SBQQ__ProcessingOrder__c = consumptRate.ProcessingOrder;
                                                subscriptionConsumptionRate.SBQQ__PricingMethod__c = consumptRate.PricingMethod;
                                                subscriptionConsumptionRate.SBQQ__LowerBound__c = consumptRate.LowerBound;
                                                subscriptionConsumptionRate.SBQQ__UpperBound__c = consumptRate.UpperBound;
                                            	subscriptionConsumptionRate.CurrencyIsoCode = consumptRate.CurrencyIsoCode;
                                            //#8744
                                            //If the Consumption Schedule Name contains 'List Rate',
											//SBQQ__Price__c on Subscription Consumption Rates get copied from QTB_Final_Unit_Price__c field from subscription
                                            if(consumptionScheduleMap.get(productConsumptionSchedule.ConsumptionScheduleId).Name.contains('List')){
                                                subscriptionConsumptionRate.SBQQ__Price__c = subscription.QTB_Final_Unit_Price__c;
                                            }else{
                                                subscriptionConsumptionRate.SBQQ__Price__c = consumptRate.Price; 
                                            }
                                            System.debug(subscriptionConsumptionRate);
                                            
                                            //create associated consSched, able to do 1:1
                                            SBQQ__SubscriptionConsumptionSchedule__c subscriptionConsumptionScheduleReference = new SBQQ__SubscriptionConsumptionSchedule__c(
                                                QTB_External_Id__c = subscription.Id + '-' + productConsumptionSchedule.ConsumptionScheduleId 
                                            );
                                            
                                            subscriptionConsumptionRate.SBQQ__SubscriptionConsumptionSchedule__r = subscriptionConsumptionScheduleReference;
                                            
                                            subscriptionConsumptionRates.add(subscriptionConsumptionRate);
                                            
                                        } catch(Exception e) {
                                            System.debug(e);
                                        }
                                    }
                                }				
                            }
                        }
                    }
                }
            }
            
            //update the subscriptions
            update subscriptions;
            //Update the flag on Contract
            ContractRecord.QTB_Converted_to_Consumption_Schedule__c=true;
            update ContractRecord;
            //add the subConsScheds
            SBQQ.TriggerControl.disable();
            try {
                Database.SaveResult[] resultsCs = Database.insert(new List<SBQQ__SubscriptionConsumptionSchedule__c> (subscriptionConsumptionSchedules));
                System.debug(subscriptionConsumptionSchedules);
                Database.SaveResult[] resultsCr = Database.insert(new List<SBQQ__SubscriptionConsumptionRate__c> (subscriptionConsumptionRates));
                System.debug('---Rates---');
                System.debug(subscriptionConsumptionRates);
            } catch (DmlException e) {
                System.debug(e);
            } finally {
                SBQQ.TriggerControl.enable();    
            }
            //resultsString.add(string.valueof(subscriptions.size()) + ' subscription records were updated');
        } else {
           System.debug('No Contract Id provided');
        }
        //return resultsString;
    }    
}