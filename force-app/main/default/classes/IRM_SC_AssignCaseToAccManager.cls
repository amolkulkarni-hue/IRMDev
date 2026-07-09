/**  
       * Name			 : IRM_SC_AssignCaseToAccManager
       * Description	 : 1. Update owner of the case if the Status is Validated and Owner is Queue
               				  and Queue member is Account Manager on Customer Account and Toggle feature is Active in custom Setting.
               			   2. Populate Customer Account Manager Email on Case object by email address of “Account Manager”
               				  on Customer Account if Customer Account on case IS NOT NULL 
       * Copyright	 	 : HCL Technologies
       * Author			 : Sejal Shah
       * Modification Log: Created:9-Mar-2012 
**/

public  with sharing class IRM_SC_AssignCaseToAccManager
{
    Set<Id> caseQueueIdSet = new Set<Id>();
    Set<Id> caseCustAccIdForEmailSet = new Set<Id>();
    Set<Id> caseCustAccIdSet = new Set<Id>();
    List<IME_SC_Toggle_Country_Features__c> toggleFeaturesCustomSetting = IME_SC_Toggle_Country_Features__c.getall().values();
    Set<Id> grpMemberIdSet = new Set<Id>();
    Set<Id> grpIdSet = new Set<Id>();
    List<GroupMember> groupMemberList;
    Map<Id,IM_Customer_Account__c> caseCustomerAccountMap;
    
    public void assignCaseToAccManager(List<Case> newCaseList)
    {
        //to retrieve sets for query purpose
        for(Case newCase: newCaseList)
        {
            if(String.valueOf(newCase.OwnerId).startsWith('00G') && (newCase.Status == 'Validated')
               && (newCase.IME_SC_Country__c != null) && (newCase.IME_SC_Customer_AccountId__c!= null))
            {
                caseQueueIdSet.add(newCase.OwnerId);
                caseCustAccIdSet.add(newCase.IME_SC_Customer_AccountId__c);             
            }
            if((newCase.IME_SC_Customer_AccountId__c != null))
            {
                caseCustAccIdForEmailSet.add(newCase.IME_SC_Customer_AccountId__c);
            }
        }
        try{
        //get all the group members
        if(caseQueueIdSet != null && !caseQueueIdSet.isEmpty())
        {
        	groupMemberList = [SELECT Id,UserOrGroupId,groupId from GroupMember where groupId IN :caseQueueIdSet];
        }
        caseCustomerAccountMap = new Map<Id, IM_Customer_Account__c>([SELECT Id, IM_Account_Manager__c, IM_Account_Manager__r.Email, 
                                                                      IM_Account_Manager__r.Id, IM_Account_Manager__r.Name
                                                                      from IM_Customer_Account__c where (id IN :caseCustAccIdSet) OR (id IN :caseCustAccIdForEmailSet)]);
        }
        catch(system.Queryexception QE)
        {
            system.debug('Exception in catch block is: '+ QE.getMessage());
        }
        //fill grp member set with Id's
        if(groupMemberList != null && !groupMemberList.isEmpty())
        {
	        for(GroupMember grpMember: groupMemberList)
	        {
	            if(String.valueOf(grpMember.UserOrGroupId).startsWith('005'))
	            {
	                grpMemberIdSet.add(grpMember.UserOrGroupId);
	            }
	            //If the queue members are group
	            else
	            {
	                grpIdSet.add(grpMember.UserOrGroupId);
	            }
	        }
        }
        
        //if the Queue has group as members
        if(grpIdSet != null && !grpIdSet.isEmpty())
        {
            try{
                //get all the grp members
                groupMemberList.clear();
                groupMemberList = [SELECT Id,UserOrGroupId,groupId from GroupMember where groupId IN :grpIdSet];
            }
            catch(system.Queryexception QE)
            {
                system.debug('Exception in catch block is: '+ QE.getMessage());
            }
            
            for(GroupMember grpMember: groupMemberList)
            {
                if(String.valueOf(grpMember.UserOrGroupId).startsWith('005'))
                {
                    grpMemberIdSet.add(grpMember.UserOrGroupId);
                }
            }
        }
        for(Case newCase: newCaseList)
        {
            if(String.valueOf(newCase.OwnerId).startsWith('00G') && (newCase.Status == 'Validated') && (newCase.IME_SC_Country__c != null) && (newCase.IME_SC_Customer_AccountId__c != null))
            {
                if(groupMemberList != null && caseCustomerAccountMap != null && !(groupMemberList.isEmpty()) && !(caseCustomerAccountMap.isEmpty()))
                {  
                    //to check whether the country is enabled for Toggle feature and queue has Account Manager as a member and assign the case to Account Manager
                    for(IME_SC_Toggle_Country_Features__c toggleFeature: toggleFeaturesCustomSetting)
                    {
                        if(toggleFeature.Country__c.equalsIgnoreCase(newCase.IME_SC_Country__c) && toggleFeature.Is_Active__c == true && 
                        	(toggleFeature.Feature_Name__c).equalsIgnoreCase('Account Manger Assignment')
                            && grpMemberIdSet.contains(caseCustomerAccountMap.get(newCase.IME_SC_Customer_AccountId__c).IM_Account_Manager__c))
                        {   
                            newCase.Status = 'Assigned';
                            newCase.OwnerId = caseCustomerAccountMap.get(newCase.IME_SC_Customer_AccountId__c).IM_Account_Manager__c;
                        }
                    }
                }
            }
            
            //to populate Customer Account Manager Email on Case object by email address of “Account Manager” on Customer Account if Customer Account on case IS NOT NULL 
            if((newCase.IME_SC_Customer_AccountId__c != null)
                && caseCustomerAccountMap.get(newCase.IME_SC_Customer_AccountId__c) != null)
            {
                newCase.IME_SC_Customer_Account_Manager_Email__c = caseCustomerAccountMap.get(newCase.IME_SC_Customer_AccountId__c).IM_Account_Manager__r.Email;
            }
            else
            {
            	newCase.IME_SC_Customer_Account_Manager_Email__c = null;
            }
        }
    }
}