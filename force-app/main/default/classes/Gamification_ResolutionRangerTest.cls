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
===================================================
*
********************************************************************************************************/

@isTest
public class Gamification_ResolutionRangerTest {

    @isTest
    static void testProcessCases() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; // Replace 'Standard User' with your profile name
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
        Account newAcc = new Account(Name ='Test');
        insert newAcc;
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = newAcc.id
        );
        insert testContact;
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;
        
        // Create test badge
        Badge__c testBadge = new Badge__c(
            Name = 'Resolution Ranger'
        );
        insert testBadge;
        
        // Query for Record Type Id based on Record Type Name
        RecordType[] recordTypeList = [select id, name, SobjectType from RecordType where name like 'Global Service Case' and SobjectType = 'Case' Limit 1];
        
        // Create test case with average age <= 4
        Case testCase1 = new Case(
            Subject = 'Test Case 1',
            Status = 'Resolved',
            CreatedDate = Date.today().addDays(-8), // Created 8 days ago
            ClosedDate = Date.today().addDays(-6),  // Within the last 7 days
            OwnerId = testUser.Id,
            ContactId = testContact.Id,
              AccountId =newAcc.id,
          Customer_ID__c = cusAcc.id,
            Business_Case_Age__c = 3, // Average age within the threshold
            IME_SC_Country__c = 'United States',
            GSC_Category__c = 'Amendment of Customer Details',
            GSC_Sub_Category__c = 'Add, Amend, Remove Authorised User',
            GSC_Root_Cause__C = 'Non adherence to process by Customer',
            
            RecordTypeId = recordTypeList[0].id
        );
        insert testCase1;
        System.debug('test case :'+ testcase1);
        
        // Call the method under test
        Test.startTest();
        Gamification_ResolutionRanger schedulableClass = new Gamification_ResolutionRanger();
        schedulableClass.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void testProcessCases_Exception() {
        // Simulate an exception by setting a flag
        Account newAcc1 = new Account(Name ='Test');
        insert newAcc1;
          IM_Customer_Account__c cusAcc1 = new IM_Customer_Account__c();
        cusAcc1.Name='Test1';
        cusAcc1.IM_Account__c= newAcc1.id;
        insert cusAcc1;
        
        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact1',
             AccountId = newAcc1.id
        );
        insert testContact1;
        // Simulate an exception by creating a case without an owner
        Case testCase2 = new Case(
            Subject = 'Test Case 2',
            Status = 'Resolved',
            CreatedDate = Date.today().addDays(-8), // Created 8 days ago
            ClosedDate = Date.today().addDays(-6),  // Within the last 7 days
            Business_Case_Age__c = 3, // Average age within the threshold
            IME_SC_Country__c = 'United States',
            GSC_Category__c = 'Amendment of Customer Details',
            GSC_Sub_Category__c = 'Add, Amend, Remove Authorised User',
            GSC_Root_Cause__C = 'Non adherence to process by Customer',
            ContactId = testContact1.Id, // Assigning ContactId to satisfy the validation rule
            AccountId = newAcc1.id,
            Customer_ID__c = cusAcc1.id
        );
        insert testCase2;
        
        // Call the method under test
        Test.startTest();
        Gamification_ResolutionRanger schedulableClass = new Gamification_ResolutionRanger();
        schedulableClass.execute(null);
        Test.stopTest();
    }
}