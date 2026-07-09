trigger caseSITADIntegration on Case (after update) {
public string sitadTrigger = null;
/***Retrieving Custom Settings***/
List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
      if(cs.Object__c=='Case'){
        if(cs.Trigger__c == 'caseSITADIntegration') {
            sitadTrigger = cs.Value__c;
        }
      }
    }
    if(sitadTrigger == 'TRUE'){
        List<id> casIds = new List<id>();
        for(case ca : trigger.new){
            Case oldCas = Trigger.oldMap.get(ca.Id);
            system.debug('?????????000');
            //if((ca.Status != 'closed'  && ca.SMS_Customer_Sync_Date__c != null && ca.SMS_Order_Sync_Date__c != null) && (ca.Service_Schedule_Date__c != oldCas.Service_Schedule_Date__c ||  ca.ownerid != oldCas.ownerid || ca.Service_Completion_Date__c != oldCas.Service_Completion_Date__c || ca.IM_Market__c != oldCas.IM_Market__c || ca.Market_Name__c != oldCas.Market_Name__c || Ca.Owner.name != oldCas.Owner.name )){
            system.debug('###'+ca.Status + '!=closed'  + ca.SMS_Customer_Sync_Date__c +'!= null'+ ca.SMS_Order_Sync_Date__c +'!= null' + ca.Service_Schedule_Date__c +'!= oldCas.Service_Schedule_Date__c '+ ca.Service_Completion_Date__c + '!= oldCas.Service_Completion_Date__c');
            if((ca.Status != 'closed'  && ca.SMS_Customer_Sync_Date__c != null && ca.SMS_Order_Sync_Date__c != null) && (ca.Service_Schedule_Date__c != oldCas.Service_Schedule_Date__c || ca.Service_Completion_Date__c != oldCas.Service_Completion_Date__c || ca.Service_Order_Date__c != oldCas.Service_Order_Date__c || ca.ownerid != oldCas.ownerid || ca.IM_Market__c != oldCas.IM_Market__c || ca.Market_Name__c != oldCas.Market_Name__c)){            
                casIds.add(ca.id);
                system.debug('?????????111');
            }
        }
        if(casIds.size() > 0){
            if(!system.isfuture())
            system.debug('?????????222');
            callSITADWebServices.callSITADUpdate(casIds);
        }
    }
}