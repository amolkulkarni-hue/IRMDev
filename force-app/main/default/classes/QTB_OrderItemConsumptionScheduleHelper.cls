/*****************************************************************************************************
* Class: QTB_OrderItemConsumptionScheduleHelper
* Author: Vrtusa
* Purpose: This is a helper class for all business logic related to SBQQ__OrderItemConsumptionSchedule__c object
* Requirement: 
* Change History: 08/25/2024
* Developer     Date           Description
* -------------------------------------------------------------------------------------------*/

public with sharing class QTB_OrderItemConsumptionScheduleHelper {
    public static final string OrderItemConsumptionSchedule_HELPER = 'QTB_OrderItemConsumptionScheduleHelper';
    
    /***********************************************************************************************************   
* Method : trigController
* Parameters: List<Order>, Map<Id,Order>,System.TriggerOperation
* Return Type: void
* Description: Generic method to handle all operations on the SBQQ__OrderItemConsumptionSchedule__c Records
**************************************************************************************************************/
    public static void trigController(
        List<SBQQ__OrderItemConsumptionSchedule__c> ordItemConSchdNewList,
        Map<Id, SBQQ__OrderItemConsumptionSchedule__c> ordItemConSchdOldMap,
        System.TriggerOperation operationType
    ) {
        switch on operationType {
            when BEFORE_INSERT {
                //GitLab #24893 - calling below method to update OrderItemConsumptionSchedule Legal Entity & Tax Treatment
                QTB_OrderItemCSHelperUtils.legalEntityUpdateSITAD(ordItemConSchdNewList);
            }  
        }
        
    }
}