trigger NBDeleteTrigger on WIP_Units_Complete__c (after delete) {
    BillCodeSelectionController.handleNonBillableDeletion(Trigger.old);
}