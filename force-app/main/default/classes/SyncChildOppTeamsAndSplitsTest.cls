@isTest
private class SyncChildOppTeamsAndSplitsTest {
    
    @testSetup
    static void setupData() {
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;
        
        // FIX: Create 5 distinct users to prevent Salesforce's "1 OTM per User per Opp" conflict limit
        List<User> users = TestingUtil.createUsers(5, true);
        
        // 2. Create IM Country (required by Opportunity in your org)
        IM_Country__c cntry = TestingUtil.createIMCountry();
        
        // 3. Create Account with distinct users for each role
        Account acc = new Account(
            Name = 'Test Sync Account',
            BillingCountry = 'United States',
            Solution_Executive__c = users[0].Id,  // User 1
            Enterprise_ISR__c = users[1].Id,      // User 2
            AMD__c = users[2].Id,                 // User 3
            RIM_SDE__c = users[3].Id              // User 4
        );
        insert acc;
        
        // 4. Create Opportunity manually
        Opportunity opp = new Opportunity(
            Name = 'test',
            AccountId = acc.Id,
            Source_System__c = 'test SKP Europe',
            Billing_Country__c = cntry.Id,
            Lead_Source_Most_Recent__c = 'x',
            StageName = '1 - Qualification',
            IM_Servicing_Region__c ='London',
            IME_Reason_Won__c = 'Benchmarking',
            IM_Booked_Date__c = System.today(),
            CloseDate = System.today(),
            Amount = 30000
        );
        insert opp;

        // 5. Create Product & Line Item (RIM BU)
        Product2 prod = new Product2(Name = 'RIM Product', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id, 
            PricebookEntryId = pbe.Id, 
            Quantity = 1, 
            TotalPrice = 100, 
            Product_Business_Unit__c = 'RIM'
        );
        insert oli;
    }

   @isTest
    static void testAccountFlowContext_InsertAndUpdate() {
        Account acc = [
            SELECT Id, Solution_Executive__c, Program_Designation__c, Global_Account__c, 
                   Global_IMGA_Owner__c, AMD__c, Enterprise_ISR__c, Tele_CDE__c, 
                   Global_Account_Director__c, DMS_Owner__c, RIM_SDE__c, 
                   Information_Governance_Rep__c, Primary_Local_Market_Rep_1__c 
            FROM Account LIMIT 1
        ];
        
        // Retrieve a fresh user to act as our replacement
        User userNewGAR = [
            SELECT Id FROM User 
            WHERE Id NOT IN (:acc.Global_Account_Director__c, :acc.Enterprise_ISR__c, :acc.AMD__c, :acc.RIM_SDE__c) 
            AND Alias LIKE 'ztest%' LIMIT 1
        ];
        
        // 1. INITIAL SYNC
        SyncChildOppTeamsAndSplits.SyncRequest req1 = new SyncChildOppTeamsAndSplits.SyncRequest();
        req1.accountRecord = acc;
        
        Test.startTest();
        SyncChildOppTeamsAndSplits.syncTeamsAndSplits(new List<SyncChildOppTeamsAndSplits.SyncRequest>{req1});
        
        // 2. UPDATE SYNC 
        acc.Global_Account_Director__c = userNewGAR.Id; // Change dynamic GAR
        acc.Enterprise_ISR__c = null;                   // Clear dynamic EISR
        acc.AMD__c = userNewGAR.Id;                     // Attempt to change static CP (should be ignored)
        
        SyncChildOppTeamsAndSplits.SyncRequest req2 = new SyncChildOppTeamsAndSplits.SyncRequest();
        req2.accountRecord = acc;
        
        SyncChildOppTeamsAndSplits.syncTeamsAndSplits(new List<SyncChildOppTeamsAndSplits.SyncRequest>{req2});
        Test.stopTest();
        
        // Verify GAR changed, EISR deleted, CP remained original user
        List<OpportunityTeamMember> updatedOtms = [SELECT TeamMemberRole, UserId FROM OpportunityTeamMember];
        Boolean garUpdated = false;
        Boolean cpRemained = false;
        
        for(OpportunityTeamMember otm : updatedOtms) {
            // Check GAR (Global Account Director)
            if(otm.TeamMemberRole == 'GAR' && otm.UserId == userNewGAR.Id) {
                garUpdated = true;
            }
            // Check CP (AMD)
            if(otm.TeamMemberRole == 'AMD' && otm.UserId != userNewGAR.Id) {
                cpRemained = true;
            }
            // Ensure EISR is gone
            if(otm.TeamMemberRole == 'Enterprise ISR') {
                System.assert(false, 'Enterprise ISR should have been deleted');
            }
        }
        
        System.assert(garUpdated, 'GAR should have updated to the new user');
        System.assert(cpRemained, 'Static CP (AMD) should NOT have updated');
    }

    @isTest
    static void testOppProductBeforeDeleteContext() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        
        Account acc = [
            SELECT Id, Solution_Executive__c, Program_Designation__c, Global_Account__c, 
                   Global_IMGA_Owner__c, AMD__c, Enterprise_ISR__c, Tele_CDE__c, 
                   Global_Account_Director__c, DMS_Owner__c, RIM_SDE__c, 
                   Information_Governance_Rep__c, Primary_Local_Market_Rep_1__c 
            FROM Account LIMIT 1
        ];
        
        // Initial sync to create the RIM role
        SyncChildOppTeamsAndSplits.SyncRequest initReq = new SyncChildOppTeamsAndSplits.SyncRequest();
        initReq.accountRecord = acc;
        SyncChildOppTeamsAndSplits.syncTeamsAndSplits(new List<SyncChildOppTeamsAndSplits.SyncRequest>{initReq});

        // SIMULATE PRODUCT DELETION
        SyncChildOppTeamsAndSplits.SyncRequest delReq = new SyncChildOppTeamsAndSplits.SyncRequest();
        delReq.oppId = opp.Id;
        delReq.deletedOliId = oli.Id; // Simulate the Before Delete Flow sending this OLI ID
        
        Test.startTest();
        SyncChildOppTeamsAndSplits.syncTeamsAndSplits(new List<SyncChildOppTeamsAndSplits.SyncRequest>{delReq});
        Test.stopTest();
        
        // Verify RIM role was deleted because the product is ignored in the query
        Integer rimRoles = [SELECT COUNT() FROM OpportunityTeamMember WHERE TeamMemberRole = 'RIM SE/AE'];
        System.assertEquals(0, rimRoles, 'RIM role should be deleted when last RIM product is removed');
    }
}