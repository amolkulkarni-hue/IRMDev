trigger CAcResponsibility on IME_SC_CAc_Responsibility__c (before insert, before update) {
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        CAcResponsibilityService.preventDuplicateOnUpdateInsert(Trigger.new);
    }
    
}