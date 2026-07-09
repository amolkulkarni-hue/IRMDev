/********************************************************************************************************
@Description: This Apex Class is created to test NAS_DataFactory.sendUpdateFailureNotifications
@Copyright: Iron Mountain
@Author:  Simranjit Kaur
@Created on:  11/19/2025(MM/DD/YYYY)
@MainClass Name: RecurringCaseResultWrapper
*
Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
===================================================
*
********************************************************************************************************/
@isTest
public class NAS_DataFactoryTest {
     /**
* @name setupTestData
* @description Sets up Test data needed for all test cases in this Test Class.
**/
    @testSetup
    public static void setupTestData(){
     //Setup Data for NAS Recurring cases
		Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        // Create active User
        User activeUser = new User(
            FirstName ='Test',
            LastName = 'Active User',
            Alias = 'actu',
            Username = 'activeuser@test.com.invalid',
            Email = 'activeuser@test.com.invalid',
            ProfileId = p.Id,
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            IsActive = true,
            Country ='United States'
        );
        insert activeUser;
	
        // Create IM employee contact (User)
        User imUser = new User(
            FirstName ='Test',
            LastName = 'IM Employee',
            Alias = 'imusr',
            Username = 'imemployee@test.com.invalid',
            Email = 'imemployee@test.com.invalid',
            ProfileId = p.Id,
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            IsActive = true,
            Country ='United States'
        );
        insert imUser;

        // Create inactive user for the queue/Inactive scenario
        User inactiveUser = new User(
            FirstName ='Test',
            LastName='Inactive User',
            Alias='inact',
            Username='inactiveuser@test.com.invalid',
            Email='inactiveuser@test.com.invalid',
            ProfileId = p.Id,
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            IsActive=false,
            Country ='United States'
        );
        insert inactiveUser;
        Group q = new Group();
        
        System.runAs(activeUser) {
             // Queue
            q.Name='TestQueue';
            q.Type='Queue';
            insert q;
            
            // Associate Queue to Case object
            QueueSobject qso = new QueueSobject(
                QueueId = q.Id,
                SObjectType = 'Case'
            );
            insert qso;
        }

        ID recTypeId =  DataFactory.getRecordTypeId('Case','NAS Recurring Support Case');
        
        Account newAcc = new Account(Name ='Test');
        insert newAcc;
        
        Contact newCon = new Contact();
        newCon.FirstName = 'Test Contact';
        newCon.LastName = 'Test Contact';
        newCon.AccountId = newAcc.id;
        insert newCon;
        
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name='Test';
        cusAcc.IM_Account__c= newAcc.id;
        insert cusAcc;

         // Case 1 → IM_Employee_Contact__c (User) → Email expected
        insert new Case(
            Subject='IM Case',
            Description ='Test Data',
            Status='In Progress',
            Origin='NAS_Chat',
            OwnerId = activeUser.Id,
            IM_Employee_Contact__c = imUser.Id,
            recordtypeid = recTypeId,
            NAS_Recurrence_Frequency__c ='DAY + 1',
            NAS_Next_Case_Creation_Date__c = System.Today(),
            NAS_Service_Line_Associated_to_Ask__c = 'Data Management',
            Priority ='Medium',
            Type ='Account Maintenance',
            AccountId = newAcc.id,
            ContactId= newCon.id,
            Customer_ID__c = cusAcc.id
        );

        // Case 2 → Active owner user (no IM employee) → Email expected
        insert new Case(
            Subject='IM Case',
            Description ='Test Data',
            Status='In Progress',
            Origin='NAS_Chat',
            OwnerId = activeUser.Id,
            recordtypeid = recTypeId,
            NAS_Recurrence_Frequency__c ='DAY + 1',
            NAS_Next_Case_Creation_Date__c = System.Today(),
            NAS_Service_Line_Associated_to_Ask__c = 'Data Management',
            Priority ='Medium',
            Type ='Account Maintenance',
            AccountId = newAcc.id,
            ContactId= newCon.id,
            Customer_ID__c = cusAcc.id
        );

        // Case 3 → Inactive owner → Chatter expected
        insert new Case(
            Subject='IM Case',
            Description ='Test Data',
            Status='In Progress',
            Origin='NAS_Chat',
            OwnerId = inactiveUser.Id,
            recordtypeid = recTypeId,
            NAS_Recurrence_Frequency__c ='DAY + 1',
            NAS_Next_Case_Creation_Date__c = System.Today(),
            NAS_Service_Line_Associated_to_Ask__c = 'Data Management',
            Priority ='Medium',
            Type ='Account Maintenance',
            AccountId = newAcc.id,
            ContactId= newCon.id,
            Customer_ID__c = cusAcc.id
        );

        // Case 4 → Queue Owner → Chatter expected
        insert new Case(
            Subject='IM Case',
            Description ='Test Data',
            Status='In Progress',
            Origin='NAS_Chat',
            OwnerId = q.Id,
            recordtypeid = recTypeId,
            NAS_Recurrence_Frequency__c ='DAY + 1',
            NAS_Next_Case_Creation_Date__c = System.Today(),
            NAS_Service_Line_Associated_to_Ask__c = 'Data Management',
            Priority ='Medium',
            Type ='Account Maintenance',
            AccountId = newAcc.id,
            ContactId= newCon.id,
            Customer_ID__c = cusAcc.id
        );
        
    }
	/* @name testSendUpdateFailureNotifications
    * @description Method to send email/chatter notification for failure of NAS Recurring Case updating "Next Case Creation Date" field. 
    **/    
    @IsTest
    static void testSendUpdateFailureNotifications() {

        List<Case> cases = [SELECT Id FROM Case WHERE RecordType.DeveloperName = :NAS_Constants.RECURRING_CASE_RECORDTYPE];
        set<id> idLst=new Set<id>();
        
        for(case cs : cases){
            idLst.add(cs.id); 
        }

        Test.startTest();
            NAS_DataFactory.sendUpdateFailureNotifications(idLst);
        Test.stopTest();
    }  
}