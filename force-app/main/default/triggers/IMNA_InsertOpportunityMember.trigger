trigger IMNA_InsertOpportunityMember on Opportunity (before insert, after update,after insert) 
{
    if(Trigger.isInsert && Trigger.isBefore)
    {
        List<String> usrListBeofre = new List<String>();
        List<OpportunityTeamMember> optyTeamBeforLst = [Select Id, UserId from OpportunityTeamMember WHERE UserId in: usrListBeofre];
        
        for(Opportunity oppBeObj : trigger.new)
        {
            if(oppBeObj.tsu__c != null)
            {
                usrListBeofre.add(oppBeObj.tsu__c);
            }
            
            if(optyTeamBeforLst.size()>0)
            {
                oppBeObj.addError('Please select another User as this user is already added to Opportunity Team Member');
            }
        }
       
    }
if(Trigger.isAfter && Trigger.isInsert)
{
    System.Debug('checkingifenteringintoloop------');
    List<OpportunityTeamMember> oppTeamInsert = new List<OpportunityTeamMember>(); 
    List<OpportunityShare> oppShare = new List<OpportunityShare>();   
    for (Opportunity opp : trigger.new) 
    {  
        if(opp.tsu__c != null)
        {
            System.Debug('checkingifenteringintoloop------');
            OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = opp.Id,
                            UserId = opp.tsu__c,   
                            TeamMemberRole = 'NA - Tactical Sales Unit');     
            oppTeamInsert.add(otm);
            system.debug('++adding members++'+otm);
        }
    }
    system.debug('++size++'+oppTeamInsert.size());
    if(oppTeamInsert.size()>0)
    {
        insert oppTeamInsert;
    }
    if (oppTeamInsert.size() > 0) 
    { 
    //system.debug('++size++'oppTeam.size);
        Integer insertRecNum = 0; 
        Database.Saveresult[] dbSave1 = Database.insert(oppTeamInsert, false); 
            for (Database.Saveresult recSave : dbSave1) 
            { 
               if (recSave.isSuccess())
               { 
                 oppShare.add( new OpportunityShare(UserOrGroupID = oppTeamInsert[insertRecNum].UserId, 
                                                    OpportunityId = oppTeamInsert[insertRecNum].OpportunityId, 
                                                    OpportunityAccessLevel = 'Edit')); 
               } else { 
                  Database.Error eMsg = recSave.getErrors()[0]; 
                  System.debug('.............Insert for OpportunityTeamMember failed for: ' + oppTeamInsert[insertRecNum].UserId);  
                  System.debug('.............The DB returned the following error for the above record: ' + eMsg);
               }
               insertRecNum++;
            }
         Database.Saveresult[] dbShrSave1 = Database.insert(oppShare, false); 
    }
}
if(Trigger.isUpdate && Trigger.isAfter)
{
    List<OpportunityShare> oppShare = new List<OpportunityShare>(); 
    List<OpportunityTeamMember> oppTeamUpdate = new List<OpportunityTeamMember>(); 
    List<String> oppTeamDelteStr = new List<String>(); 
    List<OpportunityShare> oppShareUpdate = new List<OpportunityShare>();
    List<String> OpptyIdLst = new List<String>();
    List<OpportunityTeamMember> oppTeamDelte = new List<OpportunityTeamMember>();
    
       
    for (Opportunity oppObj : trigger.new) {

        Opportunity recOldOpp = Trigger.OldMap.get(oppObj.Id);
        
        if(oppObj.tsu__c != recOldOpp.tsu__c && recOldOpp.tsu__c != null && oppObj.tsu__c != null)
        {
         
            OpportunityTeamMember otmUpdate = new OpportunityTeamMember(OpportunityId = oppObj.Id,
                        UserId = oppObj.tsu__c,    
                        TeamMemberRole = 'NA - Tactical Sales Unit'
                        );     
            oppTeamUpdate.add(otmUpdate);
            system.debug('OptyTeamMem------'+recOldOpp.tsu__c);
            if(recOldOpp.tsu__c != null)
            {
                OpptyIdLst.add(oppObj.Id);
                oppTeamDelteStr.add(recOldOpp.tsu__c);
            }
            //system.debug('++adding members++'+otmUpdate);
            system.debug('++adding members++'+oppTeamDelteStr);
        }
        if(oppObj.tsu__c != null && recOldOpp.tsu__c == null)
        {
         
            OpportunityTeamMember otmUpdate = new OpportunityTeamMember(OpportunityId = oppObj.Id,
                        UserId = oppObj.tsu__c,    
                        TeamMemberRole = 'NA - Tactical Sales Unit'
                        );     
            oppTeamUpdate.add(otmUpdate);
            
            //system.debug('++adding members++'+otmUpdate);
        }
        system.debug('++recOldOpp.tsu__c++'+recOldOpp.tsu__c +'----'+oppObj.tsu__c);
        if(recOldOpp.tsu__c != null && oppObj.tsu__c == null )
        {
            OpptyIdLst.add(oppObj.Id);
            oppTeamDelteStr.add(recOldOpp.tsu__c);
        }
                
    }
    system.debug('oppTeamUpdate----'+oppTeamUpdate.size());
    if(oppTeamUpdate.size()>0)
    {
        system.debug('oppTeamUpdate--1--'+oppTeamUpdate.size());
        insert oppTeamUpdate;
    }
    system.debug('oppTeamDelteStr----'+oppTeamDelteStr);
    if(!oppTeamDelteStr.isEmpty() && !OpptyIdLst.isEmpty()){ 
        oppTeamDelte = [Select Id, UserId, OpportunityId from OpportunityTeamMember WHERE UserId IN: oppTeamDelteStr and OpportunityId IN:OpptyIdLst];
        system.debug('oppTeamDelte.isEmpty()----'+oppTeamDelte.size());
    }        
    if(!oppTeamDelte.isEmpty())
    {
        system.debug('oppTeamDelte.isEmpty()--1--'+oppTeamDelte.size());
        delete oppTeamDelte;
    }
    
    if(oppTeamUpdate.size()>0)
    {
        Integer insertRecNum = 0; 
        system.debug('oppTeamUpdate----'+oppTeamUpdate.size());
        Database.Saveresult[] dbSave1 = Database.insert(oppTeamUpdate, false);
        system.debug('dbSave1----'+dbSave1); 
        for (Database.Saveresult recSave : dbSave1) 
        { 
           if (recSave.isSuccess())
           { 
             oppShare.add( new OpportunityShare(UserOrGroupID = oppTeamUpdate[insertRecNum].UserId, 
                                                OpportunityId = oppTeamUpdate[insertRecNum].OpportunityId, 
                                                OpportunityAccessLevel = 'Edit')); 
           } else { 
              Database.Error eMsg = recSave.getErrors()[0]; 
              System.debug('.............Insert for OpportunityTeamMember failed for: ' + oppTeamUpdate[insertRecNum].UserId);  
              System.debug('.............The DB returned the following error for the above record: ' + eMsg);
           }
           insertRecNum++;
        }
         Database.Saveresult[] dbShrSave2 = Database.insert(oppShare, false); 
    }
}

}