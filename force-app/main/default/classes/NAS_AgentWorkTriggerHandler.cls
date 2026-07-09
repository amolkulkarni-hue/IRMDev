/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Agent Work trigger handler. If the Work Item is coming from Case Team Omni Queue and the assigned 
* user is not part of the Case Team, the after insert handler prevents the Agent Work record to be 
* saved. 
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class NAS_AgentWorkTriggerHandler extends NAS_TriggerHandler {
	/**
	 * @name afterInsert
     * @description After insert event handler.
    **/
    public override void afterInsert()
    {
    	super.afterInsert();
    	List<AgentWork> agentWorkList = (List<AgentWork>) super.newList;
    	
    	Map<Id, Boolean> isError = new Map<Id, Boolean>();
        Map<Id, AgentWork> caseId2AgentWorkMap = new Map<Id, AgentWork>();
        List<Id> agentWorkUserIdList = new List<Id>();
        for(AgentWork aw : agentWorkList)
        {
            /*
             * Due to current limitation in Salesforce OriginalQueueId is not 
             * accessible from Agent Work Object. Scheduled to be fixed in Summer '19.
             * https://success.salesforce.com/issues_view?id=a1p3A0000003USLQA2
             * Once this is fixed the line below should be updated to,
             * Id originalQueueId = aw.OriginalQueueId;
            **/
            String originalQueueId = String.valueOf(((Map<String, Object>)
                                            JSON.deserializeUntyped(JSON.serialize(aw))).get('OriginalQueueId'));
            /*
             * Due to current limitation in Salesforce Presence of an user cannot 
             * be set programmatically. Only way to unit test the functionality of 
             * this Class AgentWork record need to be programmatically created, which 
             * Does not allow to set OriginalQueueId. Temporary fix is bypassing this 
             * check for unit test. Once this feature becomes available in future,
             * Test.isRunningTest() condition should be removed.
            **/
        	if(NAS_Constants.CASE_TEAM_OMNI_QUEUE_LIST.contains(originalQueueId) || Test.isRunningTest())
        	{
        		isError.put(aw.Id, true);
        		caseId2AgentWorkMap.put(aw.WorkItemId, aw);
        		agentWorkUserIdList.add(aw.UserId);
        	}
        }
        Set<Id> caseIdSet = caseId2AgentWorkMap.keySet();
        if(!caseIdSet.isEmpty())
        {
        	List<Case> caseList = [SELECT Id, (SELECT Id, MemberId FROM TeamMembers WHERE MemberId 
        					   	   IN :agentWorkUserIdList) FROM Case WHERE Id IN :caseIdSet];
        	for(Case c : caseList)
			{
				AgentWork aw = caseId2AgentWorkMap.get(c.Id);
				for(CaseTeamMember ctm : c.TeamMembers)
				{
					if(ctm.MemberId == aw.UserId)
					{
						isError.put(aw.Id, false);
					}
            	}
        	}
        	for(AgentWork aw : caseId2AgentWorkMap.values())
        	{
            	if(isError.get(aw.Id))
                	aw.addError('Unavailable');
        	}
        }
    }
}