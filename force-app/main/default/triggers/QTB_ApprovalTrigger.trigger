/***************************************************************************************************
* Author        : Virtusa 
* Purpose      : Trigger for SBQQ_Quote Object. Calls handler class for logic
* Requirement: GITLAB #20221
* Change History: 11/12/2023
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
Ramesh/Shailesh 11/12/2023   GILAB #20221 - On Account Credit: Tax Calculation Validation when performing On Account Credit
****************************************************************************************************/
trigger QTB_ApprovalTrigger on sbaa__Approval__c (before insert) {
    QTB_SbaaApprovalTriggerHandler.handleBeforeInsert(Trigger.new);   
}