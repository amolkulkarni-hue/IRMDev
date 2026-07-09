trigger BillCodeTrigger on pse__Milestone__c (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete
) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            BillCodeTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        else if(Trigger.isDelete) {
            BillCodeTriggerHandler.onBeforeDelete(Trigger.old);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
			BillCodeTriggerHandler.onAfterInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            BillCodeTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        else if (Trigger.isDelete) {
            	BillCodeTriggerHandler.onAfterDelete(Trigger.old);
        }
    }
}