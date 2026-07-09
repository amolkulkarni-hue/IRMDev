/*COMBINATION OF ALL TRIGGERS ON LEAD OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 11/29/2012
**
** CHANGE LOG
** [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 04/19/2013; Srinivasa Rao/Randstad; Added a trigger to fire lead assignment rules (Case # 01275808); Initial release
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 07/17/2013; Srinivasa Rao/Randstad; Added a trigger for DUNS Lead Routing (Case # 01275856); Initial release
** 
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 02/13/2014; Apurva Dutta/Iron Mountain India; Added a trigger for Last Non-Queue Owner Field (Case # 02166809); Initial release
*/
/* 
**Modified By: Amarendra Nallamalli  
**Date: 2nd july 2018
**Case: 08393450 : Account ID on Lead functionality to convert Lead to pre identified Salesforce.com Account
*/
/* 
**Modified By: Akhila Veerabommala  
**Date: 11 Dec 2025
**Gitlab story 34592 : Lead Assignment rules rerun when Stage is changed to 2- Marketing Qual
 on Leads with Inactive Owners 
*/

trigger LeadObject on Lead (After insert,after update, before insert, before update) {
    public String StageUpdateAfterConvert=null;
    public String PopulateOriginalLeadOwner=null;
    public String UpdateLeadOwnerEmailTrigger=null;
    public String Update_OwnerDetails_on_Owner_Update=null;
    public String Update_LastNonQueueOnr_on_Owner_Update=null;
    public String  RelatedContactupdate=null;
    public String  RelatedAccountupdate=null;
    public String  LeadCountryLookup=null;
    public String reassignLeads=null;
    public String LeadRouting=null;
    Boolean runStageUpdateAfterConvert=false;
    Boolean runPopulateOriginalLeadOwner=false;
    Boolean runUpdateLeadOwnerEmailTrigger=false;
    Boolean runUpdate_OwnerDetails_on_Owner_Update=false;
    Boolean runUpdate_LastNonQueueOnr_on_Owner_Update=false;
    Boolean runRelatedContactupdate=false;
    Boolean runRelatedAccountupdate=false;
    Boolean runLeadCountryLookup=false;
    Boolean runreassignLeads=false;
    Boolean runLeadRouting=false;
    Public static boolean CalledfromHandlar =false;
   // SObjectType triggerType = trigger.isDelete ? Trigger.old.getSObjectType() : Trigger.new.getSObjectType();
    //testInCountry1.InCountryReplicationTriggerHandler handler = new testInCountry1.InCountryReplicationTriggerHandler(triggerType.getDescribe().getName());
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Lead'){
            if(cs.Trigger__c == 'StageUpdateAfterConvert') {
                StageUpdateAfterConvert = cs.Value__c;
            }
            if(cs.Trigger__c == 'PopulateOriginalLeadOwner') {
                PopulateOriginalLeadOwner = cs.Value__c;    
            }
            if(cs.Trigger__c == 'UpdateLeadOwnerEmailTrigger') {
                UpdateLeadOwnerEmailTrigger = cs.Value__c;  
            }
            if(cs.Trigger__c == 'Update_OwnerDetails_on_Owner_Update') {
                Update_OwnerDetails_on_Owner_Update = cs.Value__c;  
            }
            if(cs.Trigger__c == 'RelatedContactupdate') {
                RelatedContactupdate = cs.Value__c;  
            }
            if(cs.Trigger__c == 'RelatedAccountupdate') {
                RelatedAccountupdate = cs.Value__c;  
            }
            if(cs.Trigger__c == 'LeadCountryLookup') {
                LeadCountryLookup = cs.Value__c;  
            }
            if(cs.Trigger__c == 'reassignLeads') {
                reassignLeads = cs.Value__c;  
            }
            if(cs.Trigger__c == 'LeadRouting') {
                LeadRouting = cs.Value__c;  
            }
            if(cs.Trigger__c == 'Update_LastNonQueueOnr_on_Owner_Update') {
                Update_LastNonQueueOnr_on_Owner_Update = cs.Value__c;  
            }
        }
    }
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            
            if(RelatedContactupdate=='True')
                runRelatedContactupdate=true;
            if(RelatedAccountupdate=='True')
                runRelatedAccountupdate=true;
            if(LeadCountryLookup=='True')
                runLeadCountryLookup=true;
            if(PopulateOriginalLeadOwner=='True')
                runPopulateOriginalLeadOwner=true;
            if(Update_OwnerDetails_on_Owner_Update=='True')
                runUpdate_OwnerDetails_on_Owner_Update=true;
            if(Update_LastNonQueueOnr_on_Owner_Update=='True')
                runUpdate_LastNonQueueOnr_on_Owner_Update=true;
                
              /*    System.debug('..........trigger type.....'+triggerType);
          if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
           System.debug('.......84Beforeinsert.....');
           handler.handleBeforeInsert();
          // AccountHelper.CalledfromHandlar=true;
           System.debug('....87afterhandlar.....');
           
           
        } */
        }

        if(Trigger.isUpdate){
            if(StageUpdateAfterConvert=='True')
                runStageUpdateAfterConvert=true;
            if(LeadCountryLookup=='True')
                runLeadCountryLookup=true;
            if(PopulateOriginalLeadOwner=='True')
                runPopulateOriginalLeadOwner=true;
            if(Update_OwnerDetails_on_Owner_Update=='True')
                runUpdate_OwnerDetails_on_Owner_Update=true;
            if(Update_LastNonQueueOnr_on_Owner_Update=='True')
                runUpdate_LastNonQueueOnr_on_Owner_Update=true;
                
             /*   System.debug('..........trigger type.....'+triggerType);
            if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
           System.debug('.......122Beforeinsert.....');
           handler.handleBeforeInsert();
          // AccountHelper.CalledfromHandlar=true;
           System.debug('....125afterhandlar.....');
           
           
        
            
        } */
        
        
            /* System.debug('..........trigger type.....'+triggerType);
            if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
           System.debug('.......84Beforeinsert.....');
           handler.handleBeforeInsert();
          // AccountHelper.CalledfromHandlar=true;
           System.debug('....87afterhandlar.....');
           
           
        }*/
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            if(UpdateLeadOwnerEmailTrigger=='True')
                runUpdateLeadOwnerEmailTrigger=true;
            if(reassignLeads=='True')
                runreassignLeads=true;
               
            /* System.debug('..........trigger type.....'+triggerType);
           if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
               System.debug('.......145Beforeinsert.....');
               handler.handleAfterInsert();
               testInCountry1.InCountryReplicationTriggerHandler.registerExecution(triggerType);
               // AccountHelper.CalledfromHandlar=true;
               System.debug('....148afterhandlar.....');
            }
            System.debug('\n\n --- LeadObject - 1 ---'
            +'\n - testInCountry1.InCountryReplicationTriggerHandler.disableTrigger: ' + testInCountry1.InCountryReplicationTriggerHandler.disableTrigger
            +'\n - testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType): ' + testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)
            +'\n - Trigger.old: ' + Trigger.old
            +'\n - Trigger.old: ' + Trigger.old != null ? ((Lead)Trigger.old[0]).IM_Lead_Stage__c : ''
            +'\n - Trigger.new: ' + Trigger.new
            +'\n - Trigger.new: ' + Trigger.new != null ? ((Lead)Trigger.new[0]).IM_Lead_Stage__c : ''
            +'\n'); */
        }
        if(Trigger.isInsert){
            if(LeadRouting=='True')
                runLeadRouting=true;
                
            /*System.debug('..........trigger type.....'+triggerType);
            if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
               System.debug('.......153Beforeinsert.....');
               handler.handleAfterInsert();
               testInCountry1.InCountryReplicationTriggerHandler.registerExecution(triggerType);
               // AccountHelper.CalledfromHandlar=true;
               System.debug('....157afterhandlar.....');
            } */
        
        }
    }
    if(runUpdateLeadOwnerEmailTrigger){
        system.debug('+++++++++++++++executing UpdateLeadOwnerEmailTrigger +++');
        Set<Id> validUserIdSet = new Set<Id> ();    
        List<Lead> leadsWithLeadCompetitors = [select id, name,OwnerId,Owner.Email, (select id, Name,Owner_Email__c, Lead_Owner_Email__c from Lead_Competitors1__r) from Lead where Id IN:Trigger.newMap.keySet()];
        system.debug('leadsWithLeadCompetitors:'+ leadsWithLeadCompetitors);
        List<Lead_Competitor__c> leadCompetitorsToUpdate = new List<Lead_Competitor__c>{};
            for(Lead l: Trigger.new) {        
                if(Trigger.oldMap.get(l.Id).OwnerId != l.OwnerId && !String.valueOf(l.OwnerId).startsWith('00G')) {
                    validUserIdSet.add(l.OwnerId);
                }
            }
        // if(!validUserIdSet.isEmpty()) {
        Map<Id, User> userMap = new Map<Id, User>([Select Id, Name, Sales_Division__c FROM User WHERE Id IN: validUserIdSet]); // AND Sales_Division__c =: 'North America']);  
        //if(userMap != null && !userMap.isEmpty()) {
        // For loop to iterate through all the queried Lead records 
        for(Lead l: leadsWithLeadCompetitors){   
            system.debug('l.Lead_Competitors1__r:'+ l.Lead_Competitors1__r);
            system.debug('userMap:'+ userMap);
            
            for(Lead_Competitor__c lc: l.Lead_Competitors1__r){ 
                User tempUser = userMap.get(l.ownerId);
                if(tempUser != Null && tempUser.Sales_Division__c == 'North America' ){
                    lc.Lead_Owner_Email__c = l.Owner.Email;
                }else {
                    lc.Lead_Owner_Email__c = '';
                }
                
                leadCompetitorsToUpdate.add(lc);
            }
        }
        update leadCompetitorsToUpdate;
        // }
        // }
    }
    //Srinu: Trigger to Fire Lead Assignment Rules.
    if(runreassignLeads){
        system.debug('+++++++++++++++executing runreassignLeads +++');
        // system.debug('+++++++++already sharing rules was executed++++'+AssignLeads.assignAlreadyCalled+'-----'+AssignLeads.counter);
        if(AssignLeads.assignAlreadyCalled==false){              
            List<Id> lids = new List<Id>(); 
            List<Id> UserIds = new List<Id>();
            List<RecordType> leadRTList = [Select Id, Name From RecordType Where SObjectType='Lead' and isActive=true];   
            Map<String, String> leadRTMap = new Map<String, String>();
            
            //Loop iterates and holds all record types with their names.
            for(RecordType RT: leadRTList){
                leadRTMap.put(RT.Id, RT.Name);
            } 
            
            Map<Id,Set<String>> MapOfCustSet=new Map<Id,Set<String>>();
            
            Map<String, String> mapLeadOwnerQueues = new Map<String, String>();
            
            List<LeadAssignedQueues__c> leadAssignedQueues = LeadAssignedQueues__c.getall().values();
            
            for(LeadAssignedQueues__c lAssQueue : leadAssignedQueues)
            {
                mapLeadOwnerQueues.put(lAssQueue.Id__c,lAssQueue.Id__c);
            }
            
            //Values from Custom Settings.
            List<Lead_Owner_Eligible_for_Reassignment__c> labelValueTemp = Lead_Owner_Eligible_for_Reassignment__c.getall().values();
            
            //check the comma seperated R.T list and then filter on queues/owner ids for that R.T.
            for(Lead_Owner_Eligible_for_Reassignment__c lc:labelValueTemp){
                if(null!=lc.Lead_RecordType_Name__c && lc.Lead_RecordType_Name__c.containsAny(',')){
                    List<String> templist=lc.Lead_RecordType_Name__c.split(',',-1);
                    Set<String> tempset=new set<String>(templist);
                    MapOfCustSet.put(lc.Lead_OwnerId__c,tempset);
                }
                else{
                    set<String> tempset=new set<String>();
                    tempset.add(lc.Lead_RecordType_Name__c);
                    MapOfCustSet.put(lc.Lead_OwnerId__c,tempset);
                }
            }                         
            
            
            //Retrieving Lead OwnerId's and querying User, Group tables based on that Id.
            for(Lead l: Trigger.New){
                UserIds.add(l.OwnerId);
            }  
            //Querying UserId's
            Map<Id,User> Lead_OwnerDetails=new Map<Id,User>([select id,Sales_Division__c,IsActive from user where id IN: UserIds]);
            //Querying QueueId's
            Map<Id, Group> Lead_Owner_Queues = new Map<Id, Group>([Select Id, OwnerId from Group where type='Queue' AND id IN: UserIds]); 
            //Workflow condtion is Hard Coded and can see on lines 170(for User) and 181(for Queue). 
            for(Integer i = 0; i < Trigger.new.size(); i++){
                if(null!=Lead_OwnerDetails && Lead_OwnerDetails.containsKey(Trigger.new[i].OwnerId)){
                    system.debug('++++++++inside user condition++++');
                    System.debug('Trigger.old[i].Rea;ssign_Lead__c =='+Trigger.old[i].Reassign_Lead__c );
                    System.debug('Trigger.new[i].Reassign_Lead__c =='+Trigger.new[i].Reassign_Lead__c);    
                    System.debug('Trigger.new[i].OwnerId==='+Trigger.new[i].OwnerId);
                    System.debug('Lead_OwnerDetails=='+Lead_OwnerDetails); 
                    System.debug('Trigger.New[i].RecordTypeId=='+Trigger.New[i].RecordTypeId);    
                    system.debug('Lead_OwnerDetails.get(Trigger.new[i].OwnerId).Sales_Division__c=='+Lead_OwnerDetails.get(Trigger.new[i].OwnerId).Sales_Division__c);
                    System.debug('Lead_OwnerDetails.get(Trigger.new[i].OwnerId).IsActive=='+Lead_OwnerDetails.get(Trigger.new[i].OwnerId).IsActive);    
                    system.debug('MapOfCustSet=='+MapOfCustSet);
                    System.debug('leadRTMap=='+leadRTMap);    
                    System.debug('leadRTMap.get(Trigger.New[i].RecordTypeId)=='+leadRTMap.get(Trigger.New[i].RecordTypeId));    
                    if (((Trigger.old[i].Reassign_Lead__c != Trigger.new[i].Reassign_Lead__c 
                          && Trigger.new[i].Reassign_Lead__c == True) 
                         ||(
                            /* Changed the logic as part of Gitlab story 34592
                             *  (Trigger.old[i].Status != Trigger.new[i].Status 
                             * && (Trigger.new[i].Status == 'New'
                             *  || Trigger.new[i].Status == 'Open' 
                             *  || Trigger.new[i].Status == 'New Activity'))*/
                             (Trigger.old[i].IM_Lead_Stage__c!= Trigger.new[i].IM_Lead_Stage__c
                              && (Trigger.new[i].IM_Lead_Stage__c=='2-Marketing Qual'))
                         &&((//Lead_OwnerDetails.get(Trigger.new[i].OwnerId).Sales_Division__c=='North America' 
                             //&&
                             Lead_OwnerDetails.get(Trigger.new[i].OwnerId).IsActive==false)
                            ||(MapOfCustSet.containsKey(Trigger.new[i].OwnerId) 
                               && MapOfCustSet.get(Trigger.new[i].OwnerId).contains(leadRTMap.get(Trigger.New[i].RecordTypeId)))))
                        )||(mapLeadOwnerQueues.containsKey(Trigger.new[i].OwnerId) && Trigger.new[i].IM_Lead_Stage__c == '2-Marketing Qual'
                            && Trigger.new[i].IM_Stage_2_Entered_Date__c == system.today())){
                                system.debug('entering---185----');
                                lids.add(Trigger.new[i].id);
                            }
                }
                else if(null!=Lead_Owner_Queues && Lead_Owner_Queues.containsKey(Trigger.new[i].OwnerId)){
                    system.debug('++++++++++inside queue condition+++++');
                    System.debug('Trigger.new[i].OwnerId==='+Trigger.new[i].OwnerId);
                    System.debug('MapOfCustSet=='+MapOfCustSet);
                    System.debug('leadRTMap=='+leadRTMap);
                    System.debug('Trigger.New[i].RecordTypeId=='+Trigger.New[i].RecordTypeId);
                    System.debug('Trigger.new[i].IM_Lead_Stage__c=='+Trigger.new[i].IM_Lead_Stage__c);
                    System.debug('Trigger.new[i].IM_Stage_2_Entered_Date__c=='+Trigger.new[i].IM_Stage_2_Entered_Date__c);
                    
                    /*   if (((Trigger.old[i].Reassign_Lead__c != Trigger.new[i].Reassign_Lead__c 
&& Trigger.new[i].Reassign_Lead__c == True) 
||(Trigger.old[i].Status != Trigger.new[i].Status 
&& (Trigger.new[i].Status == 'New'
|| Trigger.new[i].Status == 'Open' 
|| Trigger.new[i].Status == 'New Activity'))
&& (MapOfCustSet.containsKey(Trigger.new[i].OwnerId) 
&& MapOfCustSet.get(Trigger.new[i].OwnerId).contains(leadRTMap.get(Trigger.New[i].RecordTypeId))))
||(mapLeadOwnerQueues.containsKey(Trigger.new[i].OwnerId) && Trigger.new[i].IM_Lead_Stage__c == '2-Marketing Qual'
&& Trigger.new[i].IM_Stage_2_Entered_Date__c == system.today()
&& AssignLeads.counter < 1 )
)  */
                    System.debug('mapLeadOwnerQueues=='+mapLeadOwnerQueues); 
                    System.debug('Trigger.new[i].OwnerId=='+Trigger.new[i].OwnerId);
                    System.debug('mapLeadOwnerQueues.containsKey(Trigger.new[i].OwnerId)=='+mapLeadOwnerQueues.containsKey(Trigger.new[i].OwnerId));
                    System.debug('Trigger.new[i].IM_Lead_Stage__c=='+Trigger.new[i].IM_Lead_Stage__c);
                    System.debug('Trigger.new[i].IM_Stage_2_Entered_Date__c=='+Trigger.new[i].IM_Stage_2_Entered_Date__c);
                    System.debug('system.today()=='+system.today());
                    System.debug(Trigger.new[i].IM_Stage_2_Entered_Date__c == system.today());
                    //  System.debug('AssignLeads.counter=='+AssignLeads.counter);
                    
                    
                    
                    if (((Trigger.old[i].Reassign_Lead__c != Trigger.new[i].Reassign_Lead__c && Trigger.new[i].Reassign_Lead__c == True) ||
                         (Trigger.old[i].Status != Trigger.new[i].Status && (Trigger.new[i].Status == 'New'|| Trigger.new[i].Status == 'Open' || Trigger.new[i].Status == 'New Activity'))
                         && (MapOfCustSet.containsKey(Trigger.new[i].OwnerId) && MapOfCustSet.get(Trigger.new[i].OwnerId).contains(leadRTMap.get(Trigger.New[i].RecordTypeId)))
                        ) || 
                        (mapLeadOwnerQueues.containsKey(Trigger.new[i].OwnerId) 
                         //&& Trigger.new[i].OwnerId != null 
                         //&& mapLeadOwnerQueues.containsKey(String.valueOf(Trigger.new[i].OwnerId).substring(0,String.valueOf(Trigger.new[i].OwnerId).length()-3))   
                         && Trigger.new[i].IM_Lead_Stage__c == '2-Marketing Qual'
                         && Trigger.new[i].IM_Stage_2_Entered_Date__c == system.today()
                         // && AssignLeads.counter < 1 
                        )
                       )
                    {
                        system.debug('entering---192----');
                        lids.add(Trigger.new[i].id);
                    }
                }
                
            }
            
            //Passing Lead Id's to class method associated to this trigger to fire LeadAssignment Rules and uncheck checkbox.
            if(lids.Size() > 0){
                AssignLeads.Assign(lids);            
            }
        }
    }
    if(runStageUpdateAfterConvert){
        system.debug('+++++++executing StageUpdateAfterConvert Trigger++++');
        for(Integer i=0; i<Trigger.new.size(); i++) {
            if( Trigger.new[i].IsConverted == TRUE && Trigger.old[i].IsConverted == FALSE && Trigger.new[i].ConvertedOpportunityId != NULL) {
                Trigger.new[i].IM_Lead_Stage__c = '4-Sales Qual';
                Trigger.new[i].IM_X4_Sales_Qual_Reached__c = true;
                Trigger.new[i].IM_Stage_4_Entered_Date__c = system.today();
            }
        }
        //since it need to update any lead 
        /* Set<Id> leadIds = new Set<Id>();
for(Integer i=0; i<Trigger.new.size(); i++) {
if( Trigger.new[i].IsConverted == TRUE && Trigger.old[i].IsConverted == FALSE && Trigger.new[i].ConvertedOpportunityId != NULL) {
leadIds.add(Trigger.new[i].id);
}
}
//Capture all Leads associated to Campaigns
Set<Id> campaignLeadId = new Set<Id>();
for( CampaignMember campMem : [SELECT CampaignId, Id, LeadId FROM CampaignMember WHERE LeadId in :leadIds]) {
campaignLeadId.add(campMem.LeadId);
}
//Update the Stage to '4-Sales Qual'        
for(Integer i=0; i<Trigger.new.size(); i++) {
if(campaignLeadId.contains(Trigger.new[i].Id))
Trigger.new[i].IM_Lead_Stage__c = '4-Sales Qual';
}*/
    }
    if(runRelatedContactupdate){
        system.debug('+++++++++executing RelatedContactupdate+++++');
        for(Lead l:Trigger.new) {
            system.debug('+++++++++l.Contact_id__c+++++'+l.Contact_id__c);
            if(l.Contact_id__c != null) {
                system.debug('+++++++++l.Related_Contact__c+++++'+l.Related_Contact__c);
                l.Related_Contact__c=l.Contact_id__c;      
            }    
        }
    }
    /* Case: 08393450 : Account ID on Lead functionality to convert Lead to pre identified Salesforce.com Account 
    ** If Account ID populates from eloqua on lead record, while saving, corresponding Account name is copying to Related_Account__c field by using below code.
    */
    if(runRelatedAccountupdate){
       for(Lead l:Trigger.new) {
           if(l.Account_id__c != null) {
                l.Related_Account__c=l.Account_id__c;      
            }    
        }
    }
    if(runLeadCountryLookup){
        system.debug('+++++++executing LeadCountryLookup trigger+++++');
        set<string> countries = new set<string>();
        for(Lead l : Trigger.new)
        {
            if(l.Country != null)
                system.debug('...357Contry....'+l.Country);
                countries.add(l.Country);
                system.debug('...383Contry....'+countries);
            System.debug('l.IM_Stage_2_Entered_Date__c in IF =='+l.IM_Stage_2_Entered_Date__c);
            System.debug('l.IM_Lead_Stage__c in IF --'+l.IM_Lead_Stage__c);
            System.debug('l.Country:'+ l.Country);
            if(Trigger.IsInsert){
            
                if((l.IM_Stage_2_Entered_Date__c == null && l.IM_Lead_Stage__c == '2-Marketing Qual')){
                    System.debug('Entering in Correct IF---------');
                    l.IM_Stage_2_Entered_Date__c = system.today();
                }
            }else if(Trigger.isUpdate){
            
                if((l.IM_Stage_2_Entered_Date__c == null && l.IM_Lead_Stage__c == '2-Marketing Qual') 
                   || (l.IM_Lead_Stage__c == '2-Marketing Qual' && Trigger.oldMap.get(l.Id).IM_Lead_Stage__c != Trigger.newMap.get(l.Id).IM_Lead_Stage__c)){
                       System.debug('Entering in Correct Else IF--------');
                       l.IM_Stage_2_Entered_Date__c = system.today();
                   } 
            }    
        }
        system.debug('countries b4 error:'+ countries);
        Map<string,IM_Country__c> matchingCountries = CountryNameTranslator.translateCountryName2(countries);
        for(Lead l : Trigger.new)
        {    
    
           system.debug('......381matchingCountries......'+matchingCountries);
            if(l.Country != null)
            {
                if(matchingCountries.get(l.Country) != null)
                    //system.debug('...383Contry....'+matchingCountries.get(l.Country));
            
                    l.Country= matchingCountries.get(l.Country).Name;
                //system.debug('...383Contry....'+l.Country);
               // system.debug('...383Contry....'+matchingCountries.get(l.Country));
                else
                    l.Country.addError(Label.CountryTranslationErrorMessage);
            }
        }
    }
    if(runPopulateOriginalLeadOwner){
        system.debug('++++++++++++executing PopulateOriginalLeadOwner Trigger+++++++');
        String ownerIdval; 
        String w2lUserID = [SELECT ID FROM User WHERE firstname = 'Iron Mountain' and LastName='Migration'][0].id; 
        String runningUserId = UserInfo.getUserId().substring(0,15); 
        
        System.debug('********* Running UserId: ' + runningUserId); 
        System.debug('********* W2L UserId: ' + w2lUserID); 
        
        Set<string> ids = new Set<string>();
        for(Original_Lead_Owner_Exception_List__c IcrReps: [SELECT UserId__c From Original_Lead_Owner_Exception_List__c])
        {
            ids.add(IcrReps.UserId__c); 
        }
        
        if (!w2lUserID.contains(runningUserId)) { 
            if(Trigger.isBefore && Trigger.isInsert){ 
                
                
                for(Integer i=0; i<Trigger.new.size(); i++){ 
                    ownerIdval = Trigger.new[i].OwnerId; 
                    //If OwnerId is not a Queue and not listed as Exception user then assigning value to Original Lead Owner field. 
                    if(!ownerIdval.startsWith('00G') && !ids.contains(ownerIdval.substring(0,15)))
                    {
                        System.debug('*****User in OwnerId*****'); 
                        Trigger.new[i].IM_Original_Lead_Owner__c = Trigger.new[i].OwnerId;
                        
                    } 
                } 
            } 
            if(Trigger.Isbefore && Trigger.isUpdate){ 
                System.debug('*******In Before Update*****'); 
                
                
                for(Integer i=0; i<Trigger.new.size(); i++){ 
                    ownerIdval = Trigger.new[i].OwnerId; 
                    System.debug('*****User in ownerIdval*****'+ownerIdval.substring(0,15)); 
                    //If OwnerId is not a Queue then assigning value to Original Lead Owner field. 
                    if( Trigger.oldMap.get(Trigger.new[i].Id).IM_Original_Lead_Owner__c == null && !ownerIdval.startsWith('00G') && !ids.contains(ownerIdval.substring(0,15)))
                    { 
                        System.debug('*****User in OwnerId*****'); 
                        Trigger.new[i].IM_Original_Lead_Owner__c = Trigger.new[i].OwnerId; 
                        
                    } 
                } 
            } 
        } 
    }
    if(runUpdate_OwnerDetails_on_Owner_Update){
        if(Trigger.isUpdate){
            // Pratap, Case 07078747 Change curreny on owner chnage 
            if(Trigger.isBefore && Trigger.isUpdate){ 
                String ownerIdval;
                
                Set<string> ids = new Set<string>();
                for(Original_Lead_Owner_Exception_List__c IcrReps: [SELECT UserId__c From Original_Lead_Owner_Exception_List__c])
                {
                    ids.add(IcrReps.UserId__c); 
                }
                SET<ID> leads = new SET<ID>();           
                for(Lead l: trigger.new){
                    leads.add(l.ownerId);
                }           
                
                Map<id,User> LeadsMap = new MAP<id,User>([select id,DefaultCurrencyIsoCode from User where id in : leads]);
                
                for(Integer i=0; i<Trigger.new.size(); i++){ 
                    ownerIdval = Trigger.new[i].OwnerId; 
                    //If OwnerId is not a Queue and not listed as Exception user then assigning value to Original Lead Owner field. 
                    if(!ownerIdval.startsWith('00G') && !ids.contains(ownerIdval.substring(0,15)))
                    {
                        System.debug('*****User in OwnerId*****');                     
                        Trigger.new[i].CurrencyIsoCode = LeadsMap.get(Trigger.new[i].OwnerId).DefaultCurrencyIsoCode;
                    } 
                } 
            } 
            // Pratap,, Case 07078747 Change curreny on owner chnage --> 
            for(Lead l:Trigger.new){
                if(l.IM_Stage_3_Entered_Date__c  != null 
                   && Trigger.oldMap.get(l.Id).IM_Stage_3_Entered_Date__c != Trigger.newMap.get(l.Id).IM_Stage_3_Entered_Date__c
                   || (l.Most_Recent_Sales_Activity__c != null 
                       && Trigger.oldMap.get(l.Id).Most_Recent_Sales_Activity__c != Trigger.newMap.get(l.Id).Most_Recent_Sales_Activity__c)) 
                { 
                    system.debug('entering if-------');
                    system.debug('l.IM_Stage_3_Entered_Date__c-----------'+l.IM_Stage_3_Entered_Date__c);
                    if(l.IM_Stage_3_Entered_Date__c == null && l.Most_Recent_Sales_Activity__c != null){
                        l.StageComparisonDate__c =  l.Most_Recent_Sales_Activity__c.date();
                    } 
                    else if(l.IM_Stage_3_Entered_Date__c != null && l.Most_Recent_Sales_Activity__c == null){
                        l.StageComparisonDate__c =  l.IM_Stage_3_Entered_Date__c;
                    }
                    else if(l.Most_Recent_Sales_Activity__c != null && l.IM_Stage_3_Entered_Date__c > l.Most_Recent_Sales_Activity__c.date() && l.StageComparisonDate__c !=  l.IM_Stage_3_Entered_Date__c)
                    {
                        l.StageComparisonDate__c =  l.IM_Stage_3_Entered_Date__c;
                        system.debug('l.StageComparisonDate__c----------'+l.StageComparisonDate__c);
                    }
                    else if( l.Most_Recent_Sales_Activity__c != null && l.IM_Stage_3_Entered_Date__c < l.Most_Recent_Sales_Activity__c.date() && l.StageComparisonDate__c !=  l.Most_Recent_Sales_Activity__c.date())
                    {
                        l.StageComparisonDate__c =  l.Most_Recent_Sales_Activity__c.date();
                        system.debug('l.StageComparisonDate__c-------'+l.StageComparisonDate__c);
                    }
                    else if(l.Most_Recent_Sales_Activity__c != null && l.IM_Stage_3_Entered_Date__c == l.Most_Recent_Sales_Activity__c.date() ) //&& (l.StageComparisonDate__c !=  l.IM_Stage_3_Entered_Date__c || l.StageComparisonDate__c !=  l.Most_Recent_Sales_Activity__c.date()))
                    {
                        l.StageComparisonDate__c =  l.IM_Stage_3_Entered_Date__c;
                        system.debug('l.StageComparisonDate__c----------'+l.StageComparisonDate__c);
                    }
                    
                    l.Send_Email_Alert__c = false;
                }
                else if(l.IM_Stage_3_Entered_Date__c  != null || l.Most_Recent_Sales_Activity__c != null)
                {
                    if(l.IM_Stage_3_Entered_Date__c  == null && l.StageComparisonDate__c !=  l.Most_Recent_Sales_Activity__c.date())
                    {
                        system.debug('entering --------');
                        l.StageComparisonDate__c = l.Most_Recent_Sales_Activity__c.date();
                        system.debug('l.StageComparisonDate__c--------'+l.StageComparisonDate__c);
                    }
                    else if(l.Most_Recent_Sales_Activity__c == null && l.StageComparisonDate__c !=  l.IM_Stage_3_Entered_Date__c)
                    {
                        system.debug('not entering----------');
                        l.StageComparisonDate__c =  l.IM_Stage_3_Entered_Date__c; 
                        system.debug('l.StageComparisonDate__c---------'+l.StageComparisonDate__c);
                    }
                }
                
                // leadsToUpdate.add(l);
            }
        }       
        /* if(leadsToUpdate != null && leadsToUpdate.size() > 0){
System.debug('leadsToUpdate.size()=='+leadsToUpdate.size());
//update leadsToUpdate;
}*/          
        
        system.debug('++++++++++executing Update_OwnerDetails_on_Owner_Update trigger+++++');
        for (Lead o : Trigger.new) {
            // check that owner is a user (not a queue)
            if( ((String)o.OwnerId).substring(0,3) == '005' ){
                o.Owner_Details__c = o.OwnerId;
                o.Who_Changed_Owner__c = UserInfo.getUserId().substring(0,15);
            }
            else{
                // in case of Queue we clear out our copy field
                o.Owner_Details__c = null;
            }
        }
    } 
    //Apurva Dutta: Trigger to Update Last Non Owner Queue field.
    if(runUpdate_LastNonQueueOnr_on_Owner_Update){
        system.debug('++++++++++executing Update_LastNonQueueOnr_on_Owner_Update trigger+++++');
        for (Lead led : Trigger.new) {
            // check that owner is a user (not a queue)
            if( ((String)led.OwnerId).substring(0,3) == '005' ){
                led.Last_Non_Queue_Owner__c = led.OwnerId;
            }   
        }
    } 
    //Srinu: Trigger to Fire Lead Assignment Rules.
    if(runLeadRouting){
        
        system.debug('+++++++++executing Lead routing trigger+++++++++');
        set<String> dunsNumberSet=new set<string>();
        set<String> NulldunsNumberSet=new set<string>();
        set<Id> DontHaveMatchingDUNSnum=new set<id>();
        set<String> RecordTypeNames=new set<String>();
        set<string> queryfiledsSet=new Set<String>();
        set<String> LeadCountries=new set<String>();
        
        //Custom Settings Data
        List<Lead_Routing_Settings__c> CustomSetData=Lead_Routing_Settings__c.getall().values();
        
        //Dynamic Query
        String Query='select id,D_B_DUNS__c';
        string accountfileds='';
        
        //Iterating Custom Settings Data
        for(Lead_Routing_Settings__c temp :CustomSetData){
            if(temp.Lead_RecordType_Name__c!=null){
                List<String> TempRecList=temp.Lead_RecordType_Name__c.split(',',-1);
                RecordTypeNames.addAll(TempRecList);
            }
            //Srinu : For Lead Country
            if(temp.Lead_Country__c!=null){
                List<String> TempLeadCountryList=temp.Lead_Country__c.split(',',-1);
                LeadCountries.addAll(TempLeadCountryList);
            }
            
            //Checking whether Account fields contains User Lookup Relationship or not in Custom settings
            if(temp.Account_User_Lookup__c!=null){
                string temp1='';
                
                if(temp.Account_User_Lookup__c.contains('__r')){
                    temp1+=temp.Account_User_Lookup__c+'.'+temp.Assigned_Owner_Lookup__c;
                }
                else{
                    temp1+=temp.Account_User_Lookup__c;
                } 
                
                if(!queryfiledsSet.contains(temp1))
                    queryfiledsSet.add(temp1);  
            } 
        }
        System.debug('+++++++++RecordTypeNames:'+RecordTypeNames);  
        system.debug('+++++++++++++++ set of look up fileds++++++++'+queryfiledsSet);
        
        //Map to store Record Type Names from Custom Setting Data 
        Map<id,RecordType> recMap=new Map<id,RecordType>([select id,Name from RecordType where Name IN:RecordTypeNames and sObjectType='Lead']);
        system.debug('++++++++++++recordtype map+++++++++++++'+recMap);
        
        
        //Checking whether Lead contains DUNS Number or Not and Storing it in a set
        for(Lead L:trigger.new){
            system.debug('L.DUNs_Number__c:'+ L.DUNs_Number__c);
            system.debug('L.Country:'+ L.Country);
            system.debug('LeadCountries:'+ LeadCountries);
            System.debug('LeadCountries.Contains(L.Country):'+ LeadCountries.Contains(L.Country));
            if(L.DUNs_Number__c != Null  && LeadCountries.Contains(L.Country)/*&& L.Country =='United States' || L.Country =='Canada'*/){
                
                if(recMap.containsKey(L.recordTypeId)){
                    dunsNumberSet.add(L.DUNs_Number__c);
                }
            }
        }
        
        //Logic won't execute in case Lead with No DUNS #.
        System.debug('++++++++dunsNumberSet:'+dunsNumberSet);
        if(!dunsNumberSet.isEmpty()){
            
            //Map to Store Account Info for corresponding Leads DUNS Number.
            Map<string,Account> AccMap=new Map<string,Account>();
            
            if(!queryfiledsSet.isEmpty()) {
                
                //Iterating Query Fields to make a dynamic SOQL
                for(String temp :queryfiledsSet){           
                    if(accountfileds!='')
                        accountfileds+=',';
                    
                    accountfileds+=temp;
                }
                
                string dunsnumberforquery='';
                
                //Iterating Lead DUNS Number and assiging to SOQL
                for(string s:dunsNumberSet){
                    if(dunsnumberforquery!='')
                        dunsnumberforquery+=',';
                    
                    dunsnumberforquery+='\''+s+'\'';
                }
                
                //Passing DUNS Number to SOQL. If there is no Account Fields executing a dummy query without Account Fields and filter citeria.
                
                
                Query+=','+accountfileds+' from Account where D_B_DUNS__c !=null and D_B_DUNS__c IN ('+dunsnumberforquery+')';
                
                //Querying corresponding account with Lead DUNS Number.
                System.debug('++++++Query:'+Query);
                List<Account> AccList=Database.Query(Query);
                
                for(Account a:AccList){
                    AccMap.put(a.D_B_DUNS__c,a);
                }
            }
            
            system.debug('++++++++++++++++Account map++++++++++++'+AccMap);
            //Map for Duplicate id in list while updating
            Map<Id, Lead> updateList = new Map<Id, Lead>();
            Map<id,Lead> LeadMap=new Map<id,Lead>([select id,ownerid from Lead where id IN: Trigger.newMap.keySet()]);
            
            //Route the Leads based on DUNS# to the ADA covering that corresponding Account. 
            //If no active ADA is found, or if there is no matching DUNS # on an account, then run the standard lead assignment rules.
            for(Lead l: Trigger.new){
                
                if(AccMap.containskey(l.DUNs_Number__c) && LeadCountries.Contains(l.Country) && /*l.Country =='United States' || l.Country =='Canada' &&*/ recMap.containsKey(l.recordTypeId) ){
                    
                    system.debug('+++++++++++++++++this lead has matching account duns number+++++++++++++ ');
                    system.debug('++++++++++++product interest in lead+++++++++++'+l.Product_Interest__c);
                    for(Lead_Routing_Settings__c temp :CustomSetData){
                        
                        if(temp.Product_Interest__c!=null && temp.Lead_RecordType_Name__c!=null && temp.Lead_Source__c !=null && temp.Account_User_Lookup__c!=null ){
                            
                            List<String> ProductIntersetList=temp.Product_Interest__c.split(',',-1);
                            Set<String> ProductInterset=new Set<String>(ProductIntersetList);
                            
                            List<String> LeadSourceSetList=temp.Lead_Source__c.split(',',-1);
                            Set<String> LeadSourceSet=new Set<String>(LeadSourceSetList);
                            
                            List<String> recordTypeNamesTempList=temp.Lead_RecordType_Name__c.split(',',-1);
                            Set<String> recordTypeNamesTemp=new Set<String>(recordTypeNamesTempList);
                            
                            //Srinu: For Lead Country.
                            List<String> LeadCountryTempList=temp.Lead_Country__c.split(',',-1);
                            Set<String> LeadCountryTemp=new Set<String>(LeadCountryTempList);
                            
                            system.debug('+++++++++++product insert set in cus for dbr++++++++'+ProductInterset);
                            system.debug('+++++++++++++++lead source set for dbr+++++++++++++++'+LeadSourceSet);
                            system.debug('+++++++++++++record type set for dbr++++++++'+recordTypeNamesTemp);
                            if(ProductInterset.contains(l.Product_Interest__c) && LeadSourceSet.contains(l.leadsource) && LeadCountryTemp.Contains(l.Country)){
                                Boolean hasRectype=false;
                                for(String s: recordTypeNamesTemp){
                                    
                                    if(recMap.get(l.recordTypeId).Name==s)
                                        hasRectype=true;
                                }
                                //Checking whether Record Type is listed in Custom Settings List or Not.
                                if(hasRectype){
                                    system.debug('+++++++++++executing Lead routning for dbr++++++++++');
                                    if(temp.Account_User_Lookup__c.contains('__r')){
                                        
                                        system.debug('++++++++++inside the acount relationship+++++++');
                                        if(temp.Assigned_Owner_Lookup__c.contains('__r')){
                                            system.debug('++++++++++inside the user relationship+++++++');
                                            List<String> Relationships=temp.Assigned_Owner_Lookup__c.split('\\.',-1);
                                            system.debug('++++++++++list of relationship+++++++++'+Relationships);
                                            Integer sizelist=Relationships.size()-1;
                                            Account a=AccMap.get(l.DUNs_Number__c);                                           
                                            sobject s=a.getSObject(temp.Account_User_Lookup__c);
                                            system.debug('+++++++++++record after first relation extract+++++++++++'+s);
                                            if(s!=null){
                                                for(integer i=0;i<Relationships.size()-1;i++){
                                                    s=s.getSObject(Relationships[i]);
                                                    System.debug('+++468++++s:'+s);
                                                    if(s==Null){
                                                        System.debug('+++470+++when Director is Null+++++');
                                                        DontHaveMatchingDUNSnum.add(l.Id);
                                                        break;
                                                    }                                                   
                                                }
                                                if(!DontHaveMatchingDUNSnum.contains(l.id)){
                                                    id Tempid=(Id)s.get(Relationships[sizelist]);
                                                    System.debug('++++478+++++Tempid:'+Tempid);
                                                    
                                                    if(Tempid!=null) {
                                                        Lead l1=LeadMap.get(l.id);
                                                        l1.ownerid=Tempid;
                                                        //updateList.add(l1);
                                                        updateList.put(l1.Id,l1);
                                                        System.debug('++++++++++updateList:'+updateList);
                                                    }else{
                                                        System.debug('+++486+++when ADA is Null+++++');
                                                        DontHaveMatchingDUNSnum.add(l.Id);
                                                    }
                                                }
                                            }
                                            else{
                                                System.debug('+++492+++when Account User Lookup is Null+++++');
                                                DontHaveMatchingDUNSnum.add(l.Id);
                                            }
                                        }
                                        else{
                                            system.debug('++++++++++there was no user relationship+++++++');
                                            Account a=AccMap.get(l.DUNs_Number__c);
                                            sobject s=a.getSObject(temp.Account_User_Lookup__c);
                                            if(s!=null){
                                                Lead l1=LeadMap.get(l.id);
                                                l1.ownerid=(Id)s.get(temp.Assigned_Owner_Lookup__c);                                
                                                //updateList.add(l1);
                                                updateList.put(l1.Id,l1);
                                            }
                                            else{
                                                DontHaveMatchingDUNSnum.add(l.Id);
                                            }
                                        }
                                    }
                                    else{                                       
                                        system.debug('++++++++++there was no acount relationship+++++++');
                                        
                                        Account a=AccMap.get(l.DUNs_Number__c);
                                        id tempid=(Id)a.get(temp.Account_User_Lookup__c);
                                        
                                        if(tempid!=null){
                                            Lead l1=LeadMap.get(l.id);
                                            l1.ownerid=Tempid;
                                            //updateList.add(l1);
                                            updateList.put(l1.Id,l1);                                       
                                        }
                                        else{
                                            DontHaveMatchingDUNSnum.add(l.Id);
                                        }
                                        
                                    }
                                    break;
                                }
                                
                            }
                        }
                        
                    }
                    //If Product Interest not matches with any of custom settings value, then assign the 'Non DPR' Product.
                    System.debug('++514++++Update List Contains Lead Id:'+updateList.ContainsKey(l.Id) +'\t DontHaveMatchingDUNSnum contains Lead Id:'+DontHaveMatchingDUNSnum.contains(l.Id));             
                    if(!updateList.ContainsKey(l.Id) && !DontHaveMatchingDUNSnum.contains(l.Id)){                   
                        
                        System.debug('++++Inside if loop to assign Non DPR Product++++:');
                        Lead_Routing_Settings__c temp = Lead_Routing_Settings__c.getInstance('For Non DPR Product Interest');
                        
                        if(temp.Product_Interest__c!=null && temp.Lead_RecordType_Name__c!=null && temp.Lead_Source__c !=null && temp.Account_User_Lookup__c!=null ){
                            
                            List<String> LeadSourceSetList=temp.Lead_Source__c.split(',',-1);
                            Set<String> LeadSourceSet=new Set<String>(LeadSourceSetList);
                            
                            List<String> recordTypeNamesTempList=temp.Lead_RecordType_Name__c.split(',',-1);
                            Set<String> recordTypeNamesTemp=new Set<String>(recordTypeNamesTempList);
                            
                            //Srinu: For Lead Country
                            List<String> LeadCountryTempList=temp.Lead_Country__c.split(',',-1);
                            Set<String> LeadCountryTemp=new Set<String>(LeadCountryTempList);
                            
                            if(temp.Product_Interest__c=='Non DPR' && LeadSourceSet.contains(l.leadsource) && LeadCountryTemp.Contains(l.Country)){
                                
                                Boolean hasRectype=false;
                                for(String s: recordTypeNamesTemp){
                                    if(recMap.get(l.recordTypeId).Name==s)
                                        hasRectype=true;
                                }
                                //Checking whether Record Type is listed in Custom Settings List or Not.
                                if(hasRectype){
                                    if(temp.Account_User_Lookup__c.contains('__r')){
                                        system.debug('++++++++++inside the acount relationship+++++++');
                                        if(temp.Assigned_Owner_Lookup__c.contains('__r')){
                                            system.debug('++++++++++inside the user relationship+++++++');
                                            List<String> Relationships=temp.Assigned_Owner_Lookup__c.split('\\.',-1);
                                            system.debug('++++++++++list of relationship+++++++++'+Relationships);
                                            Integer sizelist=Relationships.size()-1;
                                            Account a=AccMap.get(l.DUNs_Number__c);
                                            sobject s=a.getSObject(temp.Account_User_Lookup__c);
                                            system.debug('+++++++++++record after first relation extract+++++++++++'+s);
                                            if(s!=null){
                                                for(integer i=0;i<Relationships.size()-1;i++){
                                                    s=s.getSObject(Relationships[i]);
                                                    if(s==Null){
                                                        System.debug('++577++++when Director is Null+++++');
                                                        DontHaveMatchingDUNSnum.add(l.Id);                                                      
                                                        break;
                                                    }
                                                }
                                                if(!DontHaveMatchingDUNSnum.Contains(l.Id)){
                                                    id Tempid=(Id)s.get(Relationships[sizelist]);
                                                    
                                                    if(Tempid!=null) {
                                                        Lead l1=LeadMap.get(l.id);
                                                        l1.ownerid=Tempid;
                                                        //updateList.add(l1);
                                                        updateList.put(l1.Id,l1);
                                                        System.debug('++++++++++updateList:'+updateList);
                                                    }else{
                                                        DontHaveMatchingDUNSnum.add(l.Id);
                                                        System.debug('+++577++++DontHaveMatchingDUNSnum:'+DontHaveMatchingDUNSnum);                                                 
                                                    }
                                                }
                                                
                                            }else{
                                                System.debug('+++600+++when Account User Lookup is Null+++++');
                                                DontHaveMatchingDUNSnum.add(l.Id);
                                            }
                                        }
                                        else{
                                            system.debug('++++++++++there was no user relationship+++++++');
                                            Account a=AccMap.get(l.DUNs_Number__c);
                                            sobject s=a.getSObject(temp.Account_User_Lookup__c);
                                            if(s!=null){
                                                Lead l1=LeadMap.get(l.id);
                                                l1.ownerid=(Id)s.get(temp.Assigned_Owner_Lookup__c);                                
                                                //updateList.add(l1);
                                                updateList.put(l1.Id,l1);
                                            }else{
                                                DontHaveMatchingDUNSnum.add(l.Id);
                                            }
                                            
                                        }
                                    }else{
                                        system.debug('++++++++++there was no acount relationship+++++++');                                      
                                        Account a=AccMap.get(l.DUNs_Number__c);
                                        id tempid=(Id)a.get(temp.Account_User_Lookup__c);
                                        
                                        if(tempid!=null){
                                            Lead l1=LeadMap.get(l.id);
                                            l1.ownerid=Tempid;
                                            //updateList.add(l1);
                                            updateList.put(l1.Id,l1);
                                        }else{
                                            DontHaveMatchingDUNSnum.add(l.Id);
                                        }
                                    }                           
                                    break;
                                }
                            }
                        }       
                    }
                }
                else{
                    if(l.DUNs_Number__c!=null){
                        System.debug('+++595+++++');
                        DontHaveMatchingDUNSnum.add(l.id);
                    }
                }
                
                
                
            }
            //Update Lead DML.
            update updateList.Values();     
            
            //Passing Lead Id's to class method associated to this trigger to fire LeadAssignment Rules.
            if(DontHaveMatchingDUNSnum.size()>0){
                List<Id> tempIds=new List<Id>(DontHaveMatchingDUNSnum);
                System.debug('+++609 calling Assignment Rules+++++');
                AssignLeads.Assign(tempIds);
            }       
        }
    } 
}