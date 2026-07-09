trigger AccountTrigger on Account(before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
    public static final String ACCOUNT_TRIGGER = QTB_Constants.ACCOUNT_TRIGGER;
    TriggerDispatcher.Run(new AccountTriggerHandler());      
    
}