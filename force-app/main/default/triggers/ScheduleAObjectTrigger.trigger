/**  
 * Name            : ScheduleAObjectTrigger
 * Description     : Case # 00606204
 * 
 * Copyright       : Bluewolf
 * Author          : Chris Matthews
 **/
trigger ScheduleAObjectTrigger on Schedule_A__c (before update) 
{
    public string runLockScheduleA='false';
   
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Schedule_A__c'){
            if(Cs.Trigger__c=='LockScheduleA'){
                runLockScheduleA=cs.Value__c;
            }
        }
    }
    
    if(runLockScheduleA=='True' && Trigger.isbefore && Trigger.isUpdate){
        system.debug('++++++executing runLockScheduleA  Trigger++++++++');
        
        IRM_ScheduleAService.lockScheduleA( Trigger.new, Trigger.old );
    }
    
}