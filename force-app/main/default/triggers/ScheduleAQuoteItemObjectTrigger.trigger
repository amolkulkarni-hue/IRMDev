/**  
 * Name            : ScheduleAQuoteItemObjectTrigger
 * Description     : Case # 00606204
 * 
 * Copyright       : Bluewolf
 * Author          : Chris Matthews
 **/
trigger ScheduleAQuoteItemObjectTrigger on Schedule_A_Quote_Item__c (before update) 
{
     public string runlockScheduleAQuoteItemVerification='false';
   
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Schedule_A_Quote_Item__c'){
            if(cs.Trigger__c=='LockScheduleAQuoteItemVerification'){
                runlockScheduleAQuoteItemVerification=cs.Value__c;
            }
        }
    }
    
    if(runlockScheduleAQuoteItemVerification=='True' && Trigger.isbefore && Trigger.isUpdate){
        system.debug('++++++executing lockScheduleAQuoteItemVerification  Trigger++++++++');
        
        IRM_ScheduleAService.lockScheduleAQuoteItemVerification( Trigger.new, Trigger.old );
    }
    
    
    
    
}