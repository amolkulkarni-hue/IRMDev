/********************************************************************************************************
* @Description: This Apex Class is test class for the class "Gamification_ServiceScoutBadgeAssignment"
* @Copyright: Iron Mountain
* @Author: Avanthi Gadamsetty
* @Created on:  04/24/2024(MM/DD/YYYY)
* @MainClass Name: Gamification_ServiceScoutBadgeAssignment
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Avanthi Gadamsetty - Initial Development - GitLab #23241
* ===================================================
*
********************************************************************************************************/
@isTest(SeeAllData=true)
public class Gamification_ServiceScoutAssignmentTest {
    @istest static void test_method(){
        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            ProfileId = p.Id,
            Username = 'testuser3er43@test.com',
            Email = 'testuser@test.com',
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Country = 'United States'
        );
        insert testUser;
        
        // Create test badge
        Badge__c testBadge = new Badge__c(
            Name = 'Service Scout Badge'
        );
        insert testBadge;
        
        //Get Record Type Id
        RecordType[] recordTypeList = [select id, name, SobjectType from RecordType where name like 'Global Service Case' and SobjectType = 'Case' Limit 1];
        
        //Create test Account
        Account newAcc = new Account(Name ='Test');
        insert newAcc;
        
        //Create Customer Account
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test1',
            LastName = 'Contact1',
            AccountId = newAcc.id
        );
        insert testContact;
        
        
        // Create test cases
        // Case 1: Closed within 7 days, no associated articles
        Case testCase1 = new Case(
            Subject = 'Test Case 1',
            Description = 'Test case 1',
            Status = 'Resolved',
            Origin = 'NAS_AR_Enquiries',
            IME_SC_Country__c = 'United States',
            AccountId =newAcc.id,
            Customer_ID__c = cusAcc.id,
            GSC_Category__c = 'Escalation',
            GSC_Sub_Category__c = 'High Level Escalation',
            GSC_Root_Cause__c = 'Non adherence to process by Customer',
            CreatedDate = Date.today().addDays(-8), // Created 8 days ago
            ClosedDate = Date.today().addDays(-6),  // Within the last 7 days
            OwnerId = testUser.Id,
            ContactId = testContact.Id,
            Business_Case_Age__c = 5, // Average age within the threshold
            RecordTypeId =recordTypeList[0].id
        );
        insert testCase1;
        
        // Case 2: Closed within 7 days, with associated articles
        Case testCase2 = new Case(
            Subject = 'Test Case 2',
            Description = 'Test case 2',
            Status = 'Resolved',
            Origin = 'NAS_AR_Enquiries',
            IME_SC_Country__c = 'United States',
            AccountId =newAcc.id,
            Customer_ID__c = cusAcc.id,
            GSC_Category__c = 'Escalation',
            GSC_Sub_Category__c = 'High Level Escalation',
            GSC_Root_Cause__c = 'Non adherence to process by Customer',
            CreatedDate = Date.today().addDays(-8), // Created 8 days ago
            ClosedDate = Date.today().addDays(-6),  // Within the last 7 days
            OwnerId = testUser.Id,
            ContactId = testContact.Id,
            Business_Case_Age__c = 5, // Average age within the threshold
            RecordTypeId =recordTypeList[0].id
        );
        insert testCase2;
        
        //Create test KnowledgeArticle
        KnowledgeArticle[] klgArticle = [Select id from KnowledgeArticle order by ArticleNumber limit 1 ];
        
        //Create CaseArticle Records for testCase2
        CaseArticle article2 = new CaseArticle(
            CaseId = testCase2.id,
            KnowledgeArticleId = klgArticle[0].id
        );
        insert article2;
        
        Test.startTest();
        Gamification_ServiceScoutBadgeAssignment schedulableClass = new Gamification_ServiceScoutBadgeAssignment();
        schedulableClass.execute(null);
        Test.stopTest();
    }
}