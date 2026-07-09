/*COMBINATION OF TWO TRIGGERS ON Lead_Competitor__c OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 12/13/2012
*/
trigger LeadCompetitorObject on Lead_Competitor__c (before insert) {
	/****Variable declaration for 'PopulateLeadOwnerEmail' Trigger****/
	public String PopulateLeadOwnerEmail = null;
    Set<String> leadIds = new Set<String>();
    
    /***Retrieving Custom Settings***/
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    System.debug('++++++++++++customsettings:'+customsettings);
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Lead_Competitor__c')
        {
            if(cs.Trigger__c == 'PopulateLeadOwnerEmail') {
                PopulateLeadOwnerEmail = cs.Value__c;    
            }            
        }
    }
    
    /*****************************************START TRIGGER*************************************************/

	/*****************************************BEFORE INSERT AND UPDATE*************************************/
	if(Trigger.isBefore){
		if(Trigger.isInsert){
			System.debug('----------Executing PopulateLeadOwnerEmail Trigger:'+PopulateLeadOwnerEmail);
			if(PopulateLeadOwnerEmail == 'True'){
				for (Lead_Competitor__c lc : Trigger.new){
			        if(lc.Lead__c != null)
			            leadIds.add(lc.Lead__c);
			        	System.debug('++++33++++leadIds:'+leadIds);               
			    } 
			    
			    if(!leadIds.isEmpty()) {   
			        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, OwnerId,Owner.Email FROM Lead WHERE Id IN :leadIds]);    
			        System.debug('++++++38++++++++leadMap:'+leadMap );
			        Set<Id> userIdSet = new Set<Id>();
			        Map<Id, User> userMap = new Map<Id, User>();
			        for(Lead ld: leadMap.values()) {
			            if(!String.valueOf(ld.OwnerId).startsWith('00G')) {
			                userIdSet.add(ld.ownerId);
			                System.debug('+++44++++++userIdSet:'+userIdSet);
			            }
			        }
			        
			        if(!userIdSet.isEmpty()) {
			            userMap = new Map<Id, User>([select Id, Name, Sales_Division__c from User where ID IN: userIdSet]);
			            System.debug('+++50++++userMap :'+userMap );
			        }
			        for (Lead_Competitor__c lc : Trigger.new) {
			          if(lc.Lead__c != null) {
			              Lead tempLead = leadMap.get(lc.Lead__c);
			              System.debug('++++55++++++tempLead :'+tempLead );
			                if(tempLead != null) {
			                    User tempUser = userMap.get(tempLead.ownerId);
			                    System.debug('++++58++++++tempUser :'+tempUser );
			                    if(tempUser  != null && tempUser.Sales_Division__c == 'North America') {
			                        lc.Lead_Owner_Email__c  = tempLead.Owner.Email;
			                        System.debug('+++++61++++lc.Lead_Owner_Email__c :'+lc.Lead_Owner_Email__c  );
			                    }
			               }
			          }
			        }
			    }
			}
		}
		if(Trigger.isUpdate){}
	}
	
	/*************************************END OF BEFORE INSERT AND UPDATE***************************/
    
    
	/*********************************************AFTER INSERT AND UPDATE*********************/
	if(Trigger.isAfter){}
	/*************************************END OF AFTER INSERT AND UPDATE***************************/
	System.debug('-------queries has been executed by end of LeadCompetitorObject trigger:'+Limits.getQueries());
  	System.debug('-------DML Used by end of LeadCompetitorObject trigger:'+Limits.getDMLStatements());	
}