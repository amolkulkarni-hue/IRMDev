/*COMBINATION OF TWO TRIGGERS ON Opportunity_Competitor__c OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 12/13/2012
*/
/* Developer Name: Madhu Paladugu
   Case number   : 01074173
   Date          : 2/12/2013
   Discription   : Added opportunitycompetitorsCountTrig to updates the IM_Has_Competitors__c field on Opportunity for insert/delete operations.
*/ 
trigger OpportunityCompetitorObject on Opportunity_Competitor__c (before insert,after insert,after delete) {
    
    /****Variable declaration for 'PopulateOpportunityOwnerEmail' Trigger****/
    public String PopulateOpportunityOwnerEmail = null;
    Set<String> optyIds = new Set<String>();
    Set<Id> OPP_IDS_IN_INSERT=new Set<Id>();
    Set<Id> OPP_IDS_IN_DELETE=new Set<Id>();
    public String runOpportunitycompetitorsCountTrig=null;
    /***Retrieving Custom Settings***/
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Opportunity_Competitor__c')
        {
            if(cs.Trigger__c == 'PopulateOpportunityOwnerEmail') {
                PopulateOpportunityOwnerEmail = cs.Value__c;    
            } 
            if(cs.Trigger__c == 'opportunitycompetitorsCountTrig') {
                runOpportunitycompetitorsCountTrig = cs.Value__c;    
            }            
        }
    }
    
    /*****************************************START TRIGGER*************************************************/

    /*****************************************BEFORE INSERT*************************************/
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            System.debug('----------Executing PopulateOpportunityOwnerEmail Trigger:'+PopulateOpportunityOwnerEmail);
            if(PopulateOpportunityOwnerEmail == 'True'){
                for (Opportunity_Competitor__c oc : Trigger.new) {
                    if(oc.Opportunity__c != null)
                        optyIds.add(oc.Opportunity__c);
                }
                
                if(!optyIds.isEmpty()) {
                 /* Case Number:00222919
                        Description  : Added the logic to Exempt "NA Renewal - PO/Mgr" record type Opportunity records.
                     */
                    Map<Id, Opportunity> optMap = new Map<Id, Opportunity>([SELECT Id, OwnerId, Owner.Sales_Division__c , Owner_Email__c FROM Opportunity WHERE Id IN :optyIds and RecordType.Name!='NA Renewal']);    
                    for (Opportunity_Competitor__c oc : Trigger.new) {
                        if(oc.Opportunity__c != null) {
                            Opportunity tempOpp = optMap.get(oc.Opportunity__c);
                            if(tempOpp != null && tempOpp.Owner.Sales_Division__c == 'North America') {
                                oc.Opportunity_Owner_Email__c  = tempOpp.Owner_Email__c;
                                System.debug('+++++++++oc.Opportunity_Owner_Email__c:'+oc.Opportunity_Owner_Email__c);
                            }
                        }
                    }
                }
            }           
        }
       
    }
    /*************************************END OF BEFORE INSERT***************************/
    
    
    /*********************************************AFTER INSERT AND DELETE *********************/
    if(Trigger.isAfter){
        if(runOpportunitycompetitorsCountTrig=='True'){
        system.debug('++++++Executing OpportunitycompetitorsCountTrig trigger+++');
        if(Trigger.isInsert){
          
            for(Opportunity_Competitor__c opc:Trigger.new){
                OPP_IDS_IN_INSERT.add(opc.Opportunity__c);
            }
            
           List<Opportunity> OPP_LIST_WHICH_NEEDS_UPDATE =[select Id,IM_Has_Competitors__c from Opportunity where Id IN:OPP_IDS_IN_INSERT and IM_Has_Competitors__c=false and RecordType.Name='Standard Opportunity'];
           List<Opportunity> OPP_LIST_TO_UPDATE_AFTER_CHANGE=new List<Opportunity>(); 
           
           for(Opportunity op:OPP_LIST_WHICH_NEEDS_UPDATE){
               op.IM_Has_Competitors__c=true;
               OPP_LIST_TO_UPDATE_AFTER_CHANGE.add(op);
           }
           try{
              UPDATE OPP_LIST_TO_UPDATE_AFTER_CHANGE;
           }
           catch(DmlException ex){
              Trigger.new[0].addError(ex.getMessage());
           }
       }
       if( Trigger.isDelete){
       
            for(Opportunity_Competitor__c opc:Trigger.old){
                OPP_IDS_IN_DELETE.add(opc.Opportunity__c);
            }
            
            List<Opportunity_Competitor__c> LIST_COMP_WITH_OPPIDS=[select id,Opportunity__c from Opportunity_Competitor__c where Opportunity__c IN:OPP_IDS_IN_DELETE];
           
            For(Opportunity_Competitor__c opc:LIST_COMP_WITH_OPPIDS){
                if(OPP_IDS_IN_DELETE.contains(opc.Opportunity__c)){
                    OPP_IDS_IN_DELETE.remove(opc.Opportunity__c);
                    
                }
            }
            
            if(OPP_IDS_IN_DELETE.size()>0){
                   List<Opportunity> OPP_LIST_WHICH_NEEDS_UPDATE =[select Id,IM_Has_Competitors__c from Opportunity where Id IN:OPP_IDS_IN_DELETE  and RecordType.Name='Standard Opportunity'];
                   List<Opportunity> OPP_LIST_TO_UPDATE_AFTER_CHANGE=new List<Opportunity>(); 
                       for(Opportunity op:OPP_LIST_WHICH_NEEDS_UPDATE){
                           op.IM_Has_Competitors__c=false;
                           OPP_LIST_TO_UPDATE_AFTER_CHANGE.add(op);
                       }
                       try{
                          UPDATE OPP_LIST_TO_UPDATE_AFTER_CHANGE;
                       }
                       catch(DmlException ex){
                          Trigger.new[0].addError(ex.getMessage());
                       }  
            }
    
       }
     }
    }
    /*************************************END OF AFTER INSERT AND DELETE***************************/
    System.debug('-------queries has been executed by end of OpportunityCompetitorObject trigger:'+Limits.getQueries());
    System.debug('-------DML Used by end of OpportunityCompetitorObject trigger:'+Limits.getDMLStatements());   
}