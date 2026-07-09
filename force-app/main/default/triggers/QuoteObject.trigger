/*                              
    Update Trigger to remove "runUpdateInSyncQuoteonPC", "runSyncIndicatorsToCustomer","runUpdateCustomerAccountonInsert" functionality as part of Q2W decommission
    Case # 09517433
    Author : Vinutha Iyengar
    Date : 11/02/2019
*/
trigger QuoteObject on Quote (before update,after update,after insert) 
{
    public string updatecomments='false';
    Set<Id> QuoteIdSet=new Set<Id>();
    map<ID, Quote> quoteMapnew = new map<Id, Quote>();    
    List<IM_Customer_Account__c> cusAccountLstnew = new List<IM_Customer_Account__c>();
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    
    for(Trigger_Activation_Settings__c cs : customsettings)
    {
        if(cs.Object__c=='Quote')
        {
            if(Cs.Trigger__c=='UpdateApproverComment'){
                updatecomments= cs.Value__c;
            }
           
        }
    } 
    
    if(Trigger.isUpdate && Trigger.isBefore){
        QuoteTriggerHandler.QuoteValidation(Trigger.new);
        if(updatecomments=='True'){
             Set<Id> scheduleAid = new Set<Id>();
             for(Quote q : trigger.new)
            {
                scheduleAid.add(q.Schedule_A__c);
            }
    
            Map<Id,Schedule_A__c> schedulemap= new Map<Id,Schedule_A__c>([Select Id,(Select Id, IsPending, ProcessInstanceId, TargetObjectId, StepStatus, 
                                                OriginalActorId, ActorId, RemindersSent, Comments, IsDeleted, CreatedDate, CreatedById, SystemModstamp From ProcessSteps) 
                                                from Schedule_A__c where Id =: scheduleAid]);
            
            List<User> opportunitysupport=[SELECT Id, Name FROM User WHERE username like 'opportunitysupport@ironmountain%' limit 1];
            
            if(!schedulemap.isEmpty()){
                for(Quote q : trigger.new){
                    for(ProcessInstanceHistory ps : schedulemap.get(q.Schedule_A__c).ProcessSteps){
                        if(ps.OriginalActorId == opportunitysupport[0].Id){
                             q.Contract_Minimums__c=ps.Comments;
                             system.debug('scheduleAlist4'+q.Contract_Minimums__c);
                           }
                    }
                }
            }
        }
    }       
}