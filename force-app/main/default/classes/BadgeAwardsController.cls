/********************************************************************************************************
* @Description: This Apex Class is for retrieving badges for the user "Badge Visibility and Maintenance for Gamification SFDC"
* @Copyright: Iron Mountain
* @Author: Roopesh Lakshmanan
* @Created on:  04/24/2024(MM/DD/YYYY)
* @MainClass Name: BadgeAwardsController
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Roopesh Lakshmanan - Initial Development - GitLab #23244
* 13/05/2024 - Roopesh Lakshmanan - Celebration Effect with Badge Awards - GitLab #23819
* ===================================================
*
********************************************************************************************************/

public with sharing class BadgeAwardsController {
    @AuraEnabled(cacheable=true)
    public static List<Badge_Assignments__c> getBadgeAwardsForCurrentUser(Id userId) {
		
        return [SELECT Id, Badge__r.Name, Badge__r.Badge_Image_URL__c, Badge__r.Description__c,User__c,Confetti_Show__c 
                FROM Badge_Assignments__c 
                WHERE User__c = :userId
                AND Badge_Expiry__c > TODAY];
       
    }
    @AuraEnabled(cacheable=false)
    public static void updateConfettiShowField(Id userId) {
        System.debug('********** update confetti fired ....'+ userId);
        List<Badge_Assignments__c> badgeAssignments = [SELECT Id, Confetti_Show__c
        FROM Badge_Assignments__c 
        WHERE User__c = :userId
        AND Badge_Expiry__c > TODAY];

    // Prepare records for update
    List<Badge_Assignments__c> recordsToUpdate = new List<Badge_Assignments__c>();
    for (Badge_Assignments__c badgeAssignment : badgeAssignments) {
        if (badgeAssignment.Confetti_Show__c != false) { // Check if update is needed
            badgeAssignment.Confetti_Show__c = false;
            recordsToUpdate.add(badgeAssignment);
        }
    }
System.debug('############# '+recordsToUpdate.size());
    // Perform bulk update operation
    if (!recordsToUpdate.isEmpty()) {
        try {
            update recordsToUpdate;
        } catch (Exception e) {
            // Handle exception
            System.debug('Error updating badge assignments: ' + e.getMessage());
        }
    }
}
    
}