/**
 * @description Integration-style tests for OpportunityTrigger's before-update
 * dispatch to NF_OpportunityFieldLockService (SFS149). Unlike NF_OpportunityFieldLockServiceTest,
 * these tests perform real DML so the trigger actually fires — Database.update with
 * allOrNone=false is used throughout so a Database.SaveResult can be inspected instead
 * of catching a DmlException, since addError() during a real save surfaces as a failed
 * save result, not a thrown exception, when allOrNone is false.
 */
@isTest
private class NF_OpportunityFieldLockServiceTest {

    private static final String GOVERNED_FIELD = 'Amount';
    private static final String LOCK_ERROR_SNIPPET = 'locked from further edits';

    @TestSetup
    static void setupTestData() {
        insert new Metadata_Activation_Settings__c(
            SObject_API_Name__c = 'Opportunity', Disable_VR__c = true, Disable_PB__c = true,
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert new Opp_Naming_Segment__c(
            Order__c = 1, Field_API_Name__c = '__ACCOUNT_NAME__',
            Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'
        );

        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        insert new Country_Settings__c(
            Name = 'United States', Object_Name__c = 'Opportunity',
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',         Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',         Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };

        insert new OpportunityProductSelection__c(
            Name = 'CloudSolutionsProduct', Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions'
        );
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',  Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',   Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',    Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion', Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());

        insert new Account(
            Name = 'Opportunity Trigger Test Account',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
    }

    @isTest
    static void shouldFailUpdate_WhenGovernedFieldChangedAndLocked() {
        Opportunity opp = createOpportunities(1, true)[0];

        givenGovernedFields(new Map<String, String>{ GOVERNED_FIELD => 'Amount' });
        givenLockedRecords(new Set<Id>{ opp.Id });
        givenPermissions(false, false);

        opp.Amount = 500;

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Updating a governed field on a locked record should fail the save');
        Assert.isTrue(
            result.getErrors()[0].getMessage().contains(LOCK_ERROR_SNIPPET),
            'Save error should explain the record is locked'
        );
    }

    @isTest
    static void shouldSucceedUpdate_WhenLockedButNoGovernedFieldChanged() {
        Opportunity opp = createOpportunities(1, true)[0];

        givenGovernedFields(new Map<String, String>{ GOVERNED_FIELD => 'Amount' });
        givenLockedRecords(new Set<Id>{ opp.Id });
        givenPermissions(false, false);

        opp.Description = 'Chatter-requested note about this deal';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Editing a non-governed field on a locked record should succeed');
    }

    @isTest
    static void shouldSucceedUpdate_WhenBypassPermissionGranted() {
        Opportunity opp = createOpportunities(1, true)[0];

        givenGovernedFields(new Map<String, String>{ GOVERNED_FIELD => 'Amount' });
        givenLockedRecords(new Set<Id>{ opp.Id });
        givenPermissions(true, false); // Bypass_Opportunity_Validation granted

        opp.Amount = 500;

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Bypass_Opportunity_Validation should skip the field lock entirely');
    }

    @isTest
    static void shouldSucceedUpdate_WhenNotGatedByFieldLock() {
        Opportunity opp = createOpportunities(1, true)[0];

        givenGovernedFields(new Map<String, String>{ GOVERNED_FIELD => 'Amount' });
        givenLockedRecords(new Set<Id>()); // record is not gated by the lock
        givenPermissions(false, false);

        opp.Amount = 500;

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'A record not gated by the field lock should never be checked');
    }

    @isTest
    static void shouldNotThrow_OnInsertDeleteAndUndelete() {
        Test.startTest();
        Opportunity opp = createOpportunities(1, true)[0];
        delete opp;
        undelete opp;
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity WHERE Id = :opp.Id], 'Record should exist after undelete');
    }

    /**
     * @description Builds `count` Opportunity records with unique names and a
     * deterministic CloseDate/StageName, optionally inserting them.
     */
    private static List<Opportunity> createOpportunities(Integer count, Boolean doInsert) {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opportunities.add(new Opportunity(
                AccountId = accountId,
                Name = 'Test Opportunity ' + i,
                Type = 'New Deal',
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = Test.getStandardPricebookId(),
                Amount = 100000,
                Bypass_Validation__c = true
            ));
        }

        if (doInsert) {
            insert opportunities;
        }

        return opportunities;
    }

    private static void givenGovernedFields(Map<String, String> labelsByFieldName) {
        NF_OpportunityFieldLockService.governedFieldOverrideForTests = labelsByFieldName;
    }

    private static void givenLockedRecords(Set<Id> lockedIds) {
        NF_OpportunityFieldLockService.lockedOverrideIdsForTests = lockedIds;
    }

    private static void givenPermissions(Boolean hasBypassPermission, Boolean hasStageOverridePermission) {
        NF_OpportunityFieldLockService.bypassPermissionOverrideForTests = hasBypassPermission;
        NF_OpportunityFieldLockService.stageOverridePermissionOverrideForTests = hasStageOverridePermission;
    }
}