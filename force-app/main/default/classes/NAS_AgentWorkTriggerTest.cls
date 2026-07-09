/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Agent Work Trigger.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public with sharing class NAS_AgentWorkTriggerTest {
    /**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
	@testSetup
    public static void setupTestData()
    {
    	String caseTeamOmniQueue = String.valueOf(NAS_Constants.CASE_TEAM_OMNI_QUEUE_LIST[0]);
        List<Group> groupList = [SELECT Id FROM Group WHERE (DeveloperName = 
        						 :NAS_TestConstants.NON_CASE_TEAM_OMNI_QUEUE OR Id = 
        						 :caseTeamOmniQueue) AND Type = 'Queue'];
        List<GroupMember> groupMemberList = new List<GroupMember>();
        for(Group g : groupList)
        {
        	GroupMember member = new GroupMember();
			member.UserOrGroupId = UserInfo.getUserId();
			member.GroupId = g.Id;
			groupMemberList.add(member);
        }
		INSERT groupMemberList;
    }
    /**
     * @name testAssignCaseToNonCaseOmniQueue
     * @description .
    **/
    @isTest
    public static void testAssignCaseToNonCaseOmniQueue() {
        NAS_TestDataFactory.setupTestData(1);
        Account a = [SELECT Id FROM Account Limit 1];
        AccountTeamMember t = new AccountTeamMember(
            AccountAccessLevel = 'Edit',
            AccountId = a.Id, 
            CaseAccessLevel = 'Edit',
            ContactAccessLevel = 'Edit',
            TeamMemberRole = NAS_TestConstants.ACCOUNT_TEAM_MEMBER_ROLE,
            UserId = UserInfo.getUserId());
		INSERT t;
    	NAS_TestDataFactory.createCase(1, NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE, 
                                       true, NAS_Constants.PICKLIST_STATUS_CASE_NEW);
    	Group g = [select Id from Group where DeveloperName = :NAS_TestConstants.NON_CASE_TEAM_OMNI_QUEUE AND Type = 'Queue'];
    	ServicePresenceStatus sps = [SELECT Id,MasterLabel FROM ServicePresenceStatus WHERE 
    								 DeveloperName = :NAS_TestConstants.AVAILABLE_SERVICE_PRESENCE_STATUS];
    	Case c = [SELECT Id FROM Case Limit 1];
    	c.OwnerId = g.Id;
    	update c;
        ServiceChannel serviceChannel = [SELECT Id FROM ServiceChannel WHERE DeveloperName = :NAS_TestConstants.SERVICE_CHANNEL_NAME];
        Test.startTest();
        AgentWork aw = new AgentWork(
            UserId = UserInfo.getUserId(),
            WorkItemId = c.Id,
            ServiceChannelId  = serviceChannel.Id
        );
        INSERT aw;
    	Test.stopTest();
    }
    /**
     * @name testAssignCaseToNonCaseOmniQueue
     * @description .
    **/
    @isTest
    public static void testAssignCaseToCaseOmniQueue() {
        NAS_TestDataFactory.setupTestData(1);
        Account a = [SELECT Id FROM Account Limit 1];
        AccountTeamMember t = new AccountTeamMember(
            AccountAccessLevel = 'Edit',
            AccountId = a.Id, 
            CaseAccessLevel = 'Edit',
            ContactAccessLevel = 'Edit',
            TeamMemberRole = NAS_TestConstants.ACCOUNT_TEAM_MEMBER_ROLE,
            UserId = UserInfo.getUserId());
		INSERT t;
    	NAS_TestDataFactory.createCase(1, NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE, 
                                       true, NAS_Constants.PICKLIST_STATUS_CASE_NEW);
		String caseTeamOmniQueue = String.valueOf(NAS_Constants.CASE_TEAM_OMNI_QUEUE_LIST[0]);
    	Group g = [SELECT Id FROM Group WHERE Id = :caseTeamOmniQueue AND Type = 'Queue' LIMIT 1];
    	ServicePresenceStatus sps = [SELECT Id, MasterLabel FROM ServicePresenceStatus WHERE 
    								 DeveloperName = :NAS_TestConstants.AVAILABLE_SERVICE_PRESENCE_STATUS];
    	Case c = [SELECT Id FROM Case Limit 1];
    	c.OwnerId = g.Id;
    	update c;
        ServiceChannel serviceChannel = [SELECT Id FROM ServiceChannel WHERE DeveloperName = :NAS_TestConstants.SERVICE_CHANNEL_NAME];
        Test.startTest();
        AgentWork aw = new AgentWork(
            UserId = UserInfo.getUserId(),
            WorkItemId = c.Id,
            ServiceChannelId  = serviceChannel.Id
        );
        INSERT aw;
    	Test.stopTest();
    }
}