@isTest
private class KimbleProposalContExt_Test {

    static Opportunity testOpportunity;
    @isTest
    static void testConstructor_ProfileWithKimbleAccess() {
        // Setup: Create a test user and assign a profile that will have Kimble access
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        if (testProfile == null) {
            // Fallback if 'Standard User' profile doesn't exist (e.g., in a new dev org)
            testProfile = [SELECT Id, Name FROM Profile WHERE Name LIKE '%System Administrator%' LIMIT 1];
        }

        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@example.com' + System.currentTimeMillis(),
            Country = 'United States'
        );
        System.runAs(testUser) {
            // Create a KimbleAccess__c custom setting for the test profile
            KimbleAccess__c kimbleAccessSetting = new KimbleAccess__c();
            kimbleAccessSetting.Name = testProfile.Name;
            insert kimbleAccessSetting;
            
            IM_Country__c cntry = TestingUtil.createIMCountry();	
            RecordType EUOppType = [select id from RecordType	
                                    where name = 'Standard Opportunity'	
                                    and sObjectType = 'Opportunity'];	
            Id standardPB = Test.getStandardPricebookId();	
            //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
            
            OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
            oppprodsel.Name = 'CloudSolutionsProduct';	
            oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
            oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
            insert oppprodsel; 	
            Country_Settings__c setting = new Country_Settings__c();	
            setting.Name = 'United States';	
            setting.object_name__c = 'Account';	
            insert setting;
            
            Account testAccount = TestingUtils.createAccounts(1, true)[0];
            testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
            insert testOpportunity;

            // Create a dummy Opportunity for the StandardController
            /*Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = '1 - Qualification',
                CloseDate = Date.today().addDays(30)
            );
            insert opp;*/

            Test.startTest();
            ApexPages.StandardController stdController = new ApexPages.StandardController(testOpportunity);
            KimbleProposalContExt controller = new KimbleProposalContExt(stdController);
            Test.stopTest();

            // Assertions
            System.assertEquals('view', controller.mode, 'Mode should be "view" for a profile with Kimble Access.');
            System.assertEquals(true, controller.canEdit, 'canEdit should be true for a profile with Kimble Access.');
            System.assertEquals(testProfile.Name, controller.usrProfile, 'usrProfile should match the test user\'s profile name.');
        }
    }
}