trigger SKPOpportunitySync on Case (after update) {
    
    Set<Id> NCSPRecordTypeIds = new Set<Id>();
    String SKPOpportunitySync= null;
    Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds(); 
    System.debug('rtMapByName'+rtMapByName);
    if(rtMapByName.containsKey('NCSP: SKP New Customer Setup')){
        NCSPRecordTypeIds.add(rtMapByName.get('NCSP: SKP New Customer Setup').getRecordTypeId());
    }
    if(rtMapByName.containsKey('NCSP: DMS')){
        NCSPRecordTypeIds.add(rtMapByName.get('NCSP: DMS').getRecordTypeId());
    }
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    System.debug('++++++++++83++++++++customsettings:'+customsettings);
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Opportunity')
        {
          if(cs.Trigger__c == 'SKPOpportunitySync') {
                SKPOpportunitySync = cs.Value__c;    
            }
        }
    }
    /*****B2B WEBSERVICE CALLOUT START for NA Opportunity*******/

     if(SKPOpportunitySync == 'True' && B2B_Integration.firstRun &&  (!system.isFuture()))
     {
         Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
          List<Case> caselist=[Select Id,RecordTypeId,NCSP_Opportunity__c,Customer_ID__c,NCSP_Opportunity__r.RecordTypeId,NCSP_Opportunity__r.Type,
                              NCSP_Opportunity__r.StageName,NCSP_Opportunity__r.Commissionable_Window_Close_Date__c,NCSP_Opportunity__r.SKP_Opportunity_Sync_Date__c
                              from Case where Id IN :Trigger.newMap.keySet()];
         system.debug('+++++++QChe++++++++SKPOpportunitySync1');
         for(Case ca: caselist)
         {   
             if(ca.Customer_ID__c != Null && ca.NCSP_Opportunity__c != Null && NCSPRecordTypeIds.contains(ca.RecordTypeId))
             {
                 String RecordTypeName = rtMap.get(ca.NCSP_Opportunity__r.RecordTypeId).getName();
                 system.debug('+++RecordTypeName++'+ RecordTypeName);
                 system.debug('+++ca.NCSP_Opportunity__c ++'+ca.NCSP_Opportunity__c );
                 system.debug('+++ca.NCSP_Opportunity__r.Type++'+ ca.NCSP_Opportunity__r.Type);
                 system.debug('+++NCSPRecordTypeIds++'+ NCSPRecordTypeIds);
                 if(Trigger.oldMap.get(ca.Id).Customer_ID__c !=Trigger.newMap.get(ca.Id).Customer_ID__c && (ca.NCSP_Opportunity__r.Type=='New Deal' && (ca.NCSP_Opportunity__r.StageName=='6 - Setup' || ca.NCSP_Opportunity__r.StageName=='7 - Closed')) 
                    && (ca.NCSP_Opportunity__r.Commissionable_Window_Close_Date__c >= system.today() || ca.NCSP_Opportunity__r.Commissionable_Window_Close_Date__c == null) && RecordTypeName=='Standard Opportunity')
                  {
                     system.debug('+++checking1++');  
                     if(ca.NCSP_Opportunity__r.SKP_Opportunity_Sync_Date__c== null) 
                       {
                       if(!Test.isRunningTest())
                       B2B_Integration.create_opportunity(ca.NCSP_Opportunity__c,true); 
                       B2B_Integration.firstRun=false;
                       system.debug('+++create opportunity++');    
                       }else{
                       if(!Test.isRunningTest())
                       B2B_Integration.update_opportunity(ca.NCSP_Opportunity__c,false);
                       B2B_Integration.firstRun=false;
                       system.debug('+++update opportunity++');    
                       }
                 }  
             }
           
         }
     }
/*****B2B  WEBSERVICE CALLOUT END for NA Opportunity********/
}