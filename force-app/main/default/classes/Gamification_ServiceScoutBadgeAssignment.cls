/********************************************************************************************************
* @Description: This Apex Class is created to assign the Service Scout badge to the agent When percentage of closed cases with internal knowledge articles attached, excluding external FAQs is 90% over a week
* @Copyright: Iron Mountain
* @Author: Avanthi Gadamsetty
* @Created on:  4/24/2024(MM/DD/YYYY)
* @TestClass Name: Gamification_ServiceScoutAssignmentTest
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 4/24/2024 - Avanthi Gadamsetty - Initial Development - GitLab #23241
* 5/20/2024 - Avanthi Gadamsetty - Added the English Speaking Countries - GitLab #23812
* ===================================================
*
********************************************************************************************************/

public class Gamification_ServiceScoutBadgeAssignment implements Schedulable {
    
    public void execute(SchedulableContext sc){
        Map<Id, Integer> closedCasesByOwnerMap = new Map<Id, Integer>();
        Map<Id, Integer> closedCasesWithArtclesMap = new Map<Id, Integer>();     
        List<String> countries = new List<String>{'United States', 'Canada', 'United Kingdom','India','Hong Kong','Malaysia'};
        List<Badge_Assignments__c> ba = new List<Badge_Assignments__c>();
        try{
            id badgeId = [SELECT Id FROM Badge__c WHERE Name like 'Service Scout%' Limit 1].id;
        	// Query for closed cases grouped by owner
            Date sevenDaysAgo = System.today().addDays(-7);
            List<AggregateResult> closedCasesByOwner = [SELECT OwnerId, COUNT(Id) numClosedCases
                                                        FROM Case
                                                        WHERE IsClosed = true 
                                                        AND ClosedDate >= :sevenDaysAgo 
                                                        AND owner.type = 'User' 
                                                        AND RecordType.DeveloperName = 'Global_Service_Case' 
                                                        AND IME_SC_Country__c in :countries
                                                        AND Status ='Resolved' 
                                                        AND Business_Case_Age__c <= 5                                                       
                                                        GROUP BY OwnerId];
            for (AggregateResult aggResult : closedCasesByOwner) {
                Id ownerId = (Id)aggResult.get('OwnerId');
                Integer numClosedCases = (Integer)aggResult.get('numClosedCases');
                closedCasesByOwnerMap.put(ownerId, numClosedCases);
            }
            system.debug('@@closedCasesByOwnerMap-='+closedCasesByOwnerMap);
            
            List<AggregateResult> closedCasesWithArtcles = [SELECT Case.Ownerid ownerId, COUNT_DISTINCT(CaseId) numClosedCases from CaseArticle 
                                                            WHERE Case.IsClosed = true 
                                                            AND Case.ClosedDate >= :sevenDaysAgo 
                                                            AND Case.owner.type = 'User' 
                                                            AND Case.RecordType.DeveloperName = 'Global_Service_Case' 
                                                            AND Case.IME_SC_Country__c IN :countries 
                                                            AND Case.Status = 'Resolved' 
                                                            AND Case.Business_Case_Age__c <= 5                                                           
                                                            GROUP BY Case.Ownerid ];
            
            for (AggregateResult aggResult : closedCasesWithArtcles) {
                Id ownerId = (Id)aggResult.get('ownerId');
                Integer numClosedCases = (Integer)aggResult.get('numClosedCases');
                closedCasesWithArtclesMap.put(ownerId, numClosedCases);
            }
            system.debug('@@closedCasesWithArtclesMap-='+closedCasesWithArtclesMap);            
            // Calculate percentage for each owner
            for (Id ownerId : closedCasesByOwnerMap.keySet()) {
                Integer totalClosedCases = closedCasesByOwnerMap.get(ownerId);
                Integer closedCasesWithArticles = closedCasesWithArtclesMap.get(ownerId);
                if(closedCasesWithArtclesMap.get(ownerId) != null){
                    Decimal percentage = totalClosedCases > 0 ? (Decimal.valueOf(closedCasesWithArticles) / Decimal.valueOf(totalClosedCases)) * 100 : 0;
                    //percentageMap.put(ownerId, percentage);
                    if(percentage >= 90){
                        Badge_Assignments__c badgeAssignment = new Badge_Assignments__c();
                        badgeAssignment.User__c = ownerId;
                        badgeAssignment.Badge__c = badgeId;
                        ba.add(badgeAssignment);
                    }
                }            
            }
            system.debug('@@badges '+ba);
            if(ba.size()>0){
                try{INSERT ba;
                }catch(DMLException e){ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'Gamification_ServiceScoutBadgeAssignment');}
            }            
        }catch(Exception e){ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'Gamification_ServiceScoutBadgeAssignment');}
	}
}