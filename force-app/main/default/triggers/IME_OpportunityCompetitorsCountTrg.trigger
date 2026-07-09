/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   IME_OpportunityCompetitorsCountTrg (Trigger)
**
** PURPOSE
**   counts the number of copmpetitors for the parent opportunities and updates the checkbox. 
**
** NOTES
**   Expected invocation format:
**     works specifically on standard SFDC opportunitycompetitor object, and not any custom objects defined for N.A. for competitor.
**     It is associated with 'OpportunityCompetitors' class.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/04/05; Srinivasa Rao/Randstad; IME_OpportunityCompetitorCountTrg (Case # 01074173); Initial release
**	
	Adding multiline comment as this trigger is migrated to Opportuntiy Helper class and this trigger will be deactivated.
    commented by arajendran (BCT)
	Date : 30 Jun 2020
************************************************************************/
trigger IME_OpportunityCompetitorsCountTrg on Opportunity (before update) 
{
     /*Adding multiline comment as this trigger is migrated to Opportuntiy Helper class and this trigger will be deactivated.
      * commented by arajendran (BCT)
      * 
      * system.debug('+++++++++executing the IME_OpportunityCompetitorsCountTrg trigger for update event++++++');
     List<String> opportunityIds = new List<String>();
     Set<Id> recordTypeIds = new Set<Id>();    
     fillRecordTypeIds(); 
     system.debug('++++++++++record type Ids+++++'+recordTypeIds);
     
     for(Opportunity o : Trigger.new){
       if(recordTypeIds.contains(o.RecordTypeId)){
           opportunityIds.add(o.Id);  
       }     
     }
     system.debug('++++++++++opp ids++++++'+opportunityIds);
       
     if(opportunityIds.size()>0){
         system.debug('++++++++++++inside if loop because it as IME opportunities+++++++');
           set<Id> opp_Ids_that_needs_true=new Set<Id>();
           List<OpportunityCompetitor> opp_with_com=[select id,opportunityId from opportunityCompetitor where opportunityId in :opportunityIds and isDeleted = false];
           for(OpportunityCompetitor oc:opp_with_com){
               opp_Ids_that_needs_true.add(oc.opportunityId);
           }
           for(Integer I=0;i<Trigger.new.size();i++){
               if(!opp_Ids_that_needs_true.contains(Trigger.new[i].Id)){
                   Trigger.new[i].IM_Has_Competitors__c=false;
               }
               else if(Trigger.new[i].IM_Has_Competitors__c==false){
                    Trigger.new[i].IM_Has_Competitors__c=true;
               }
           }
                                        
         
     }
     
     //Method to fetch Opportunity Record Type
     private void fillRecordTypeIds(){
        System.debug('---66---inside RT Method-----');
        Schema.DescribeSObjectResult d = Schema.SObjectType.Opportunity; 
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
                 
        if(rtMapByName.containsKey('IMAP Standard Opportunity'))
            recordTypeIds.add(rtMapByName.get('IMAP Standard Opportunity').getRecordTypeId());
        if(rtMapByName.containsKey('IME Standard Opportunity'))
            recordTypeIds.add(rtMapByName.get('IME Standard Opportunity').getRecordTypeId());
        if(rtMapByName.containsKey('IMLA Standard Opportunity'))
            recordTypeIds.add(rtMapByName.get('IMLA Standard Opportunity').getRecordTypeId());
    } */   
     
}