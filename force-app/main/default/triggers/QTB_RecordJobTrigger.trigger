/*************************************************************************************************8
* Trigger for SBQQ__RecordJob__c . Calls handler class for logic
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 8/26/2020
* @Modified      : 8/26/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
******************************************************************************************************/
trigger QTB_RecordJobTrigger on SBQQ__RecordJob__c (after insert,after update) {    
            TriggerDispatcher.Run(new QTB_RecordJobHandler()); 
}