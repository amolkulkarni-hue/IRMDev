/********************************************************************************************************
@Description: This Apex Class is created to assign the Resolution Ranger badge to the Agents who maintain an average case age of 4 days or less in a week
@Copyright: Iron Mountain
@Author:  Mastan Shaik
@Created on:  4/24/2024(MM/DD/YYYY)
@TestClass Name: Gamification_ResolutionRanger
*
Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
4/24/2024 - Mastan Shaik - Initial Development - GitLab #23309
5/20/2024 - Avanthi Gadamsetty - Added the English Speaking Countries - GitLab #23812
===================================================
*
********************************************************************************************************/
public class Gamification_ResolutionRanger implements Schedulable  {
   
     public void execute(SchedulableContext sc){
        // Calculating the date 7 days ago
        Date sevenDaysAgo = Date.today().addDays(-7);
         List<String> countries = new List<String>{'United States', 'Canada', 'United Kingdom','India','Hong Kong','Malaysia'};
         try{
             // Query to retrieve closed cases in the last 7 days with Business Case Age populated
            List<Case> cases = [SELECT Id, OwnerId, Business_Case_Age__c 
                                FROM Case 
                                WHERE IsClosed = true 
                                AND ClosedDate >= :sevenDaysAgo
                                AND OwnerId != null
                                AND Status = 'Resolved'
                                AND Business_Case_Age__c != null 
                                AND Owner.Type = 'User' 
                                AND RecordType.DeveloperName = 'Global_Service_Case' 
                                AND IME_SC_Country__c IN :countries ];
            System.debug('Number of cases retrieved: ' + cases.size());
            // Query to get the Badge id
            List<Badge__c> badges = [SELECT Id FROM Badge__c WHERE  Name LIKE  'Resolution Ranger%' LIMIT 1];
            // Check if any badges are found
            if (badges.isEmpty()) {
                System.debug('No badge found with the name "Resolution Ranger ".');
                return;
            }
            // Get the badge ID
            Id badgeId = badges[0].Id;
            // Map to store closed cases grouped by owner and their total Business Case Age
            Map<Id, List<Decimal>> caseAgeMap = new Map<Id, List<Decimal>>();
            Map<Id, Decimal> ownerAverageAgeMap = new Map<Id, Decimal>();
            // Group cases by owner and calculate total Business Case Age
            for (Case cas : cases) {
                if (cas.OwnerId != null) {
                    if (!caseAgeMap.containsKey(cas.OwnerId)) {
                        caseAgeMap.put(cas.OwnerId, new List<Decimal>{cas.Business_Case_Age__c});
                       
                    } else {
                        caseAgeMap.get(cas.OwnerId).add(cas.Business_Case_Age__c);
                        
                    }
                }
            }
            // Calculating average case age
            for (Id ownerId : caseAgeMap.keySet()) {
                List<Decimal> caseAges = caseAgeMap.get(ownerId);
                Decimal totalAge = 0;
                for (Decimal age : caseAges) {
                    totalAge += age;
                }
                ownerAverageAgeMap.put(ownerId, caseAges.isEmpty() ? 0 : totalAge / caseAges.size());
               }
              system.debug('@@ownerAverageAgeMap'+ ownerAverageAgeMap);
            // List to hold the Badge Assignments 
            List<Badge_Assignments__c> badgeAssignments = new List<Badge_Assignments__c>();
            for (Id ownerId : ownerAverageAgeMap.keySet()) {
                Decimal ownerAverageAge = ownerAverageAgeMap.get(ownerId);
                if (ownerAverageAge <= 4) {
                    // Creating badge assignment
                    Badge_Assignments__c badgeAssignment = new Badge_Assignments__c(
                        User__c = ownerId,
                        Badge__c = badgeId
                    );
                    badgeAssignments.add(badgeAssignment);
                   
                }
            }
              system.debug('badgeAssignment - ' + badgeAssignments);
            if(badgeAssignments.size()>0){
                try{insert badgeAssignments;
                }catch(DMLException e){ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'Gamification_ResolutionRanger');}
            }           
         }catch(Exception e){ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'Gamification_ResolutionRanger');}
    }
}