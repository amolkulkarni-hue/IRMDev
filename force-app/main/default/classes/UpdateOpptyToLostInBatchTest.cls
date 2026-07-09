@isTest
private class UpdateOpptyToLostInBatchTest {
    
    @testSetup
    static void setup() {

        Date close = Date.today().addDays(-33);

        User user = [SELECT Id FROM User WHERE Profile.Name = 'IM_Custom Sys Admin' 
                     AND UserRole.Name = 'Iron MTN Admin' 
                     AND IsActive = TRUE 
                     LIMIT 1];
        
        UpdateOpptyStageToLost__c closeDateNRole = new UpdateOpptyStageToLost__c();
        closeDateNRole.Name = 'IMNA-US-SMB-RM-Inbound-BDA';
        closeDateNRole.DaysInThePast__c = 30;
        closeDateNRole.RoleId__c = '00E80000001NXJYEA4';  // You should ensure this Role ID is valid for your org
        insert closeDateNRole;

        List<Country_Settings__c> countrySetting = new List<Country_Settings__c>{
            new Country_Settings__c(Name = 'Canada', Object_Name__c = 'Account'),
            new Country_Settings__c(Name = 'United States', Object_Name__c = 'Account')
        };
        insert countrySetting;

        // Insert OpportunityProductSelection__c data
      OpportunityProductSelection__c ps1 = new OpportunityProductSelection__c(
            Name = 'CloudSolutionsProduct', 
            Product_Class_Name__c = 'Data Backup and Recovery', 
            Product_Line_Name__c = 'Cloud Solutions'
        );
        insert ps1; 

        // Insert SVStatus__c data
        SVStatus__c sv1 = new SVStatus__c(
            Name = 'SVStatusPassed', 
            Amount__c = 2400, 
            OpptType__c = 'New Deal,Up-Sell', 
            Stage__c = '6 - Setup'
        );
        insert sv1; 

        Account acc = TestingUtils.createAccounts(1, true).get(0);
        Contact cont = TestingUtils.createContact(acc.Id, true);

        Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        User us = new User(
            Alias = 'test', 
            Email = 'testuser@roletest1.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestingUpdateOppty',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'test@userAk.com', 
            Country = 'United States',
            IsActive = true
        );
        insert us;

        Id StandardOpptyRecordtype = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();


        List<Opportunity> TestOpportunities = TestingUtils.createOpportunities(null, acc.Id, true, 5, StandardOpptyRecordtype);
    }

 @isTest
    static void testBatchUpdateToLost() {
        // Get test opportunities
        List<Opportunity> oppsToUpdate = [SELECT Id, Name, CloseDate, StageName, OwnerId FROM Opportunity];
        System.assertEquals(5, oppsToUpdate.size(), 'Should have 5 test opportunities');
       
        Test.startTest();

        UpdateOpptyToLostInBatch batchJob = new UpdateOpptyToLostInBatch(oppsToUpdate);

        List<Opportunity> scope = batchJob.start(null);
        
        batchJob.execute(null, scope);
        
        Test.stopTest();
        
        // Verify opportunities were updated to Lost
        List<Opportunity> updatedOpps = [SELECT Id, StageName, IM_Reason_Lost__c, IM_Lost_Comments__c 
                                         FROM Opportunity 
                                         WHERE Id IN :oppsToUpdate];
        
        for(Opportunity opp : updatedOpps) {
            System.assertEquals('Lost', opp.StageName, 'Opportunity should be updated to Lost stage');
            System.assertEquals('No Business Need', opp.IM_Reason_Lost__c, 'Reason Lost should be set correctly');
            System.assertEquals('Inbound past due for many days', opp.IM_Lost_Comments__c, 'Lost Comments should be set correctly');
        }
    }
    
 @isTest
    static void testEmptyBatchInput() {
        List<Opportunity> emptyList = new List<Opportunity>();
        Test.startTest();
        UpdateOpptyToLostInBatch batch = new UpdateOpptyToLostInBatch(emptyList);
        Database.executeBatch(batch, 2);
        Test.stopTest();
        System.assert(true, 'Batch should handle empty list without error.');
    } 
    
    @isTest
    static void testSendNotificationFailure() {
        // Create an opportunity
        Opportunity testOppty = [SELECT Id, OwnerId, Name FROM Opportunity LIMIT 1];

        // Create a batch with this opportunity
        List<Opportunity> oppList = new List<Opportunity>{testOppty};
        UpdateOpptyToLostInBatch batchInstance = new UpdateOpptyToLostInBatch(oppList);

        Test.startTest();
        batchInstance.sendNotification(new List<Messaging.CustomNotification>{new Messaging.CustomNotification()}, new List<Opportunity>{testOppty});
        Test.stopTest();

            }
     
}