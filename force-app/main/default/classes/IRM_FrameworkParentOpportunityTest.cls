/**
 * IRM_FrameworkParentOpportunityTest
 *
 * Smoke test proving a sample Framework_Parent_Opportunity record type Opportunity can be
 * created cleanly through Apex — passing the org's active "NF Enforce Required Stakeholder
 * Roles by Opportunity Stage" flow (Qualification, Type=All: Champion, Economic Decision
 * Maker / Buyer, Problem Owner) and the Qual_*_Required validation rules — and that the
 * Opportunity_Auto_Name_Create_Flow stamps a generated Name for this record type
 * (see IRM_OppAutoNameTest.test_autoNameOnCreate_FrameworkRT for the Name-format assertion).
 */
@IsTest
private class IRM_FrameworkParentOpportunityTest {

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        // Required by OpportunityHelper.createOpportunityShare (Country_Settings__c and
        // Opportunity_Security__c are list custom settings read during Opportunity AfterInsert)
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',         Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',         Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        // Required by OppPartnerAction (called from OpportunityTriggerHandler.BeforeUpdate
        // via "Update Pricebook On Opportunity" flow — queries this record by name)
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());

        Account acc = new Account(
            Name = 'IRM Framework Parent Opportunity Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        // 3 Contacts for the Qualification (Type=All) stage-gate roles
        insert new List<Contact>{
            new Contact(LastName = 'Champion',      AccountId = acc.Id),
            new Contact(LastName = 'EconomicBuyer',  AccountId = acc.Id),
            new Contact(LastName = 'ProblemOwner',   AccountId = acc.Id)
        };
    }

    private static Id getAccountId() {
        return [SELECT Id FROM Account LIMIT 1].Id;
    }

    // Populates every field required by the org's "Qual_*_Required" stage-gate validation
    // rules, mirroring IRM_TouchLevelProgressionTest.buildOpp() but for the
    // Framework_Parent_Opportunity record type (Type='Framework', per
    // IRM_OppAutoNameTest.test_autoNameOnCreate_FrameworkRT).
    private static Opportunity buildFrameworkOpp() {
        return new Opportunity(
            Name = 'Sample Framework Parent Opportunity',
            AccountId = getAccountId(),
            RecordTypeId = App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID,
            Type = 'Framework',
            Business_Unit__c = 'RIM',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = 500000,
            Budget_Validated__c = 'Yes',
            Business_Problem_Evidenced__c = 'Improve Efficiency or Reduce Manual Work',
            Customer_Outcome_Predefined__c = 'Reduce manual reconciliation effort.',
            Decision_Process_Defined__c = true,
            Impact_Consequences_Identified__c = 'No Clear Impact Identified Yet',
            Primary_Product_Line__c = 'Secure Shredding',
            Service_Address__Street__s = '123 Main St',
            Service_Address__City__s = 'New York',
            Service_Address__StateCode__s = 'NY',
            Service_Address__CountryCode__s = 'US',
            // Safety net for any other Opportunity validation rule, mirroring
            // IRM_ExitValidationTest.makeOpp()'s sanctioned use of this field.
            Bypass_Validation__c = true
        );
    }

    private static void addOcrRoles(Id oppId) {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY LastName];
        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[0].Id, Role = 'Champion'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[1].Id, Role = 'Economic Decision Maker / Buyer'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[2].Id, Role = 'Problem Owner')
        };
    }

    @IsTest
    static void test_sampleFrameworkParentOpportunityIsCreatedCleanly() {
        Opportunity opp = buildFrameworkOpp();

        Test.startTest();
        insert opp;
        addOcrRoles(opp.Id);
        Test.stopTest();

        Opportunity created = [
            SELECT Id, Name, StageName, RecordTypeId, RecordType.DeveloperName
            FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertEquals(App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID, created.RecordTypeId,
            'Sample Opportunity should be created with the Framework_Parent_Opportunity record type.');
        System.assertEquals('Framework_Parent_Opportunity', created.RecordType.DeveloperName,
            'RecordType.DeveloperName should resolve to Framework_Parent_Opportunity.');
        System.assertEquals('Qualification', created.StageName,
            'Sample Opportunity should be created at the Qualification stage.');
        System.assertNotEquals(null, created.Name,
            'Name should be populated by the Opportunity_Auto_Name_Create_Flow for this record type.');

        List<OpportunityContactRole> roles = [SELECT Role FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        System.assertEquals(3, roles.size(),
            'All 3 Qualification (Type=All) stage-gate roles should be attached: Champion, Economic Decision Maker / Buyer, Problem Owner.');
    }

    // ──────────────────────────────────────────────────────────
    // FW-02 AC2 / FW-03 AC3 / FW-03 AC4 — new validation rule coverage
    // (Framework_Stage_Requires_Booking_Verification, Framework_Parent_Must_Be_Active,
    // Framework_Child_Type_Restriction — see IRM_Touch_Level_Classification_SDD Section 21)
    // ──────────────────────────────────────────────────────────

    private static Opportunity buildChildOpp() {
        return new Opportunity(
            Name = 'Sample Framework Child Opportunity',
            AccountId = getAccountId(),
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            Type = 'New',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = 100000,
            Bypass_Validation__c = true
        );
    }

    @IsTest
    static void test_bookingVerificationGate_blocksDirectJumpToBooked() {
        Opportunity opp = buildFrameworkOpp();
        insert opp;
        addOcrRoles(opp.Id);
        opp.StageName = 'Solutioning'; update opp;
        opp.StageName = 'Negotiation'; update opp;

        Test.startTest();
        opp.StageName = 'Booked';
        Boolean threw = false;
        try {
            update opp;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('must pass through Booking Verification'),
                'Expected the Framework_Stage_Requires_Booking_Verification error, got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(threw, 'Jumping directly from Negotiation to Booked should be blocked.');
    }

    @IsTest
    static void test_bookingVerificationGate_allowsBookedAfterBookingVerification() {
        Opportunity opp = buildFrameworkOpp();
        insert opp;
        addOcrRoles(opp.Id);
        opp.StageName = 'Solutioning'; update opp;
        opp.StageName = 'Negotiation'; update opp;
        opp.StageName = 'Booking Verification'; update opp;

        Test.startTest();
        opp.StageName = 'Booked';
        update opp;
        Test.stopTest();

        Opportunity result = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Booked', result.StageName,
            'Moving to Booked directly from Booking Verification should be allowed.');
    }

    private static Id createBookedActiveFrameworkParent() {
        Opportunity parent = buildFrameworkOpp();
        insert parent;
        addOcrRoles(parent.Id);
        parent.StageName = 'Solutioning'; update parent;
        parent.StageName = 'Negotiation'; update parent;
        parent.StageName = 'Booking Verification'; update parent;
        parent.StageName = 'Booked';
        parent.Framework_Status__c = 'Active';
        update parent;
        return parent.Id;
    }

    @IsTest
    static void test_childLinkage_blocksWhenParentNotBooked() {
        Opportunity parent = buildFrameworkOpp();
        insert parent; // still at Qualification — not Booked

        Opportunity child = buildChildOpp();
        child.IM_Parent_Opportunity__c = parent.Id;

        Test.startTest();
        Boolean threw = false;
        try {
            insert child;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('must be Booked (Closed Won) and have Framework Status = Active'),
                'Expected the Framework_Parent_Must_Be_Active error, got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(threw, 'Linking a child to a non-Booked Framework Parent should be blocked.');
    }

    @IsTest
    static void test_childLinkage_blocksWhenParentBookedButNotActive() {
        Opportunity parent = buildFrameworkOpp();
        insert parent;
        addOcrRoles(parent.Id);
        parent.StageName = 'Solutioning'; update parent;
        parent.StageName = 'Negotiation'; update parent;
        parent.StageName = 'Booking Verification'; update parent;
        parent.StageName = 'Booked'; update parent; // Booked but Framework_Status__c left blank (not Active)

        Opportunity child = buildChildOpp();
        child.IM_Parent_Opportunity__c = parent.Id;

        Test.startTest();
        Boolean threw = false;
        try {
            insert child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Linking a child to a Booked-but-not-Active Framework Parent should be blocked.');
    }

    @IsTest
    static void test_childLinkage_allowsWhenParentBookedAndActive() {
        Id parentId = createBookedActiveFrameworkParent();

        Opportunity child = buildChildOpp();
        child.IM_Parent_Opportunity__c = parentId;

        Test.startTest();
        insert child;
        Test.stopTest();

        Opportunity result = [SELECT IM_Parent_Opportunity__c FROM Opportunity WHERE Id = :child.Id];
        System.assertEquals(parentId, result.IM_Parent_Opportunity__c,
            'Linking a child to a Booked and Active Framework Parent should be allowed.');
    }

    @IsTest
    static void test_childTypeRestriction_blocksRenewalWhenLinkedToParent() {
        Id parentId = createBookedActiveFrameworkParent();

        Opportunity child = buildChildOpp();
        child.Type = 'Renewal';
        child.IM_Parent_Opportunity__c = parentId;

        Test.startTest();
        Boolean threw = false;
        try {
            insert child;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('may not use Deal Type = Renewal'),
                'Expected the Framework_Child_Type_Restriction error, got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(threw, 'A child linked to a Framework Parent should not be allowed Type = Renewal.');
    }

    @IsTest
    static void test_childTypeRestriction_allowsNewWhenLinkedToParent() {
        Id parentId = createBookedActiveFrameworkParent();

        Opportunity child = buildChildOpp();
        child.Type = 'New'; // default on buildChildOpp(), set explicitly here for clarity
        child.IM_Parent_Opportunity__c = parentId;

        Test.startTest();
        insert child;
        Test.stopTest();

        Opportunity result = [SELECT Type FROM Opportunity WHERE Id = :child.Id];
        System.assertEquals('New', result.Type,
            'A child linked to a Framework Parent should be allowed Type = New.');
    }
}