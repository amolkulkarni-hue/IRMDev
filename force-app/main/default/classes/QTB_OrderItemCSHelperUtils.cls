/*****************************************************************************************************
* Class: QTB_OrderItemCSHelperUtils
* Author: Vrtusa
* Purpose: This is a helper Util class for all business logic related to SBQQ__OrderItemConsumptionSchedule__c object
* Requirement: 
* Change History: 08/25/2024
* Developer     Date           Description
* -------------------------------------------------------------------------------------------*/
public class QTB_OrderItemCSHelperUtils {
    public static final string OrderItemConsumptionScheduleHELPER_Utils = 'QTB_OrderItemCSHelperUtils';
    /*********************************************************************************************************
* Method Name: legalEntityUpdateSITAD
* Parameters: List<SBQQ__OrderItemConsumptionSchedule__c> ordConsList 
* Return Type: void
* Requirement: Gitlab #24893
* Description: This method will update the OrderItemConsumptionSchedule & TaxTreatment for SITAD.
**********************************************************************************************************/ 
    public static void legalEntityUpdateSITAD(List<SBQQ__OrderItemConsumptionSchedule__c> ordConsList){
        set<Id> billingOrderItem = new set<Id>();
        try{
            if (QTB_OrderItemConScheduleTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            for(SBQQ__OrderItemConsumptionSchedule__c ordCon : ordConsList){
                //adding billingorderItemId in billingOrderItem set
                billingOrderItem.add(ordCon.SBQQ__OrderItem__c);
            }
            
            //GitLab #27020 - Fetching QTB_SITAD_Countries CustomLable Values
            List<string> getSITADCountries = system.Label.QTB_SITAD_Countries.split(';');
            //GitLab #27020 - End
            
            //fetching SITAD orderItems
            //Gitlab #27220 - added 'Ad-Hoc' in below query to support Additional
            Map<Id,orderItem> OrderItemIdsMap = new Map<Id,orderItem>([SELECT id,blng__LegalEntity__c,blng__TaxTreatment__c,blng__BillingTreatment__c
                                                                       FROM orderItem WHERE Order.QTB_DM_Source_System_Name__c = 'SITAD' 
                                                                       AND Order.QTB_OrderCategory__c IN('Evergreen','Ad-Hoc') AND Product2.Family = 'DM SITAD'
                                                                       AND Order.Account.QTB_Legal_Entity_Country__c IN:getSITADCountries
                                                                       AND Id IN:billingOrderItem]);
            if(OrderItemIdsMap.size() > 0){
            for (SBQQ__OrderItemConsumptionSchedule__c ordConSch : ordConsList){
                //if condition is checking whether Legal Entity is NULL
                if(ordConSch.blng__LegalEntity__c == NULL && OrderItemIdsMap.containsKey(ordConSch.SBQQ__OrderItem__c)) {
                    //updating OPCS Legal Entity with its OrderProduct Legal Entity
                    ordConSch.blng__LegalEntity__c = OrderItemIdsMap.get(ordConSch.SBQQ__OrderItem__c).blng__LegalEntity__c; 
                    //updating OPCS TaxTreatment with its OrderProduct TaxTreatment
                    ordConSch.blng__TaxTreatment__c = OrderItemIdsMap.get(ordConSch.SBQQ__OrderItem__c).blng__TaxTreatment__c;
                    
                }
            }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                OrderItemConsumptionScheduleHELPER_Utils
            );
            throw e;
        }
    } 
}