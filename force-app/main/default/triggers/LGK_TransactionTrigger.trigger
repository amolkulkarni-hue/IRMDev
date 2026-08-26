trigger LGK_TransactionTrigger on LGK__Transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    System.debug('LGK_Transaction Trigger Executing');
    TriggerDispatcher.Run(new LGK_TransactionTriggerHandler());
}