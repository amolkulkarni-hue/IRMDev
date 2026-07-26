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
        // 3 Contacts for the Qualification (Type=All) stage-gate roles, plus 1 for the
        // Negotiation stage-gate role (NF_Enforce_Required_Stakeholder_Roles_by_Opportunity_Stage)
        insert new List<Contact>{
            new Contact(LastName = 'Champion',      AccountId = acc.Id),
            new Contact(LastName = 'EconomicBuyer',  AccountId = acc.Id),
            new Contact(LastName = 'ProblemOwner',   AccountId = acc.Id),
            new Contact(LastName = 'AuthorizedSignatory', AccountId = acc.Id),
            new Contact(LastName = 'CorrespondenceContact', AccountId = acc.Id)
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

    private static Id getContactIdByLastName(String lastName) {
        return [SELECT Id FROM Contact WHERE LastName = :lastName LIMIT 1].Id;
    }

    private static void addOcrRoles(Id oppId) {
        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = oppId, ContactId = getContactIdByLastName('Champion'), Role = 'Champion'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = getContactIdByLastName('EconomicBuyer'), Role = 'Economic Decision Maker / Buyer'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = getContactIdByLastName('ProblemOwner'), Role = 'Problem Owner')
        };
    }

    // Required by NF_Enforce_Required_Stakeholder_Roles_by_Opportunity_Stage before a
    // Framework Parent Opportunity can advance to Negotiation.
    private static void addAuthorizedSignatoryRole(Id oppId) {
        insert new OpportunityContactRole(
            OpportunityId = oppId, ContactId = getContactIdByLastName('AuthorizedSignatory'), Role = 'Authorized Signatory'
        );
    }

    // Required by NF_Enforce_Required_Stakeholder_Roles_by_Opportunity_Stage before a
    // Framework Parent Opportunity can advance to Booking Verification.
    private static void addCorrespondenceContactRole(Id oppId) {
        insert new OpportunityContactRole(
            OpportunityId = oppId, ContactId = getContactIdByLastName('CorrespondenceContact'), Role = 'Correspondence Contact'
        );
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
    // (Framework_Booking_Verification_Gate, Framework_Parent_Must_Be_Active,
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
    static void test_bookingVerificationGate_blocksDirectJumpToClosed() {
        Opportunity opp = buildFrameworkOpp();
        insert opp;
        addOcrRoles(opp.Id);
        opp.StageName = 'Solutioning'; update opp;
        addAuthorizedSignatoryRole(opp.Id);
        opp.StageName = 'Negotiation'; update opp;

        Test.startTest();
        opp.StageName = 'Closed';
        Boolean threw = false;
        try {
            update opp;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('must pass through Booking Verification'),
                'Expected the Framework_Booking_Verification_Gate error, got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(threw, 'Jumping directly from Negotiation to Closed should be blocked.');
    }

    @IsTest
    static void test_bookingVerificationGate_allowsClosedAfterBookingVerification() {
        Opportunity opp = buildFrameworkOpp();
        insert opp;
        addOcrRoles(opp.Id);
        opp.StageName = 'Solutioning'; update opp;
        addAuthorizedSignatoryRole(opp.Id);
        opp.StageName = 'Negotiation'; update opp;
        addCorrespondenceContactRole(opp.Id);
        opp.StageName = 'Booking Verification'; update opp;

        Test.startTest();
        opp.StageName = 'Closed';
        update opp;
        Test.stopTest();

        Opportunity result = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed', result.StageName,
            'Moving to Closed directly from Booking Verification should be allowed.');
    }

    @IsTest
    static void test_bookedStageNoLongerValidForFrameworkParent() {
        Opportunity opp = buildFrameworkOpp();
        insert opp;
        addOcrRoles(opp.Id);
        opp.StageName = 'Solutioning'; update opp;
        addAuthorizedSignatoryRole(opp.Id);
        opp.StageName = 'Negotiation'; update opp;
        addCorrespondenceContactRole(opp.Id);
        opp.StageName = 'Booking Verification'; update opp;

        Test.startTest();
        opp.StageName = 'Booked';
        Boolean threw = false;
        try {
            update opp;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('Booked'),
                'Expected a restricted-picklist-value error naming Booked, got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(threw, 'Booked should no longer be a valid StageName for the Framework_Parent_Opportunity record type — it moves directly from Booking Verification to Closed.');
    }

    // Proves the Framework-Parent branch fixed in VR_Opp_S1_Type (and its S1/S2/S3 siblings) now
    // treats Negotiation -> Booking Verification as the checkpoint for required fields, instead of
    // the old Negotiation -> Booked skip. Asserts loosely on the DmlException containing "Type"
    // rather than one specific rule's exact message: depending on the running user's custom
    // permission assignments, Restrict_Type_Change_after_Negotiation (which also gates on Type
    // changing at/after Negotiation) could plausibly be the rule that surfaces first instead of
    // VR_Opp_S1_Type — either way proves the edge is now enforced, which is what the fix changed.
    @IsTest
    static void test_typeRequired_firesOnNegotiationToBookingVerificationForFrameworkParent() {
        Opportunity opp = buildFrameworkOpp();
        insert opp;
        addOcrRoles(opp.Id);
        opp.StageName = 'Solutioning'; update opp;
        addAuthorizedSignatoryRole(opp.Id);
        opp.StageName = 'Negotiation'; update opp;

        Test.startTest();
        opp.Type = null;
        opp.StageName = 'Booking Verification';
        Boolean threw = false;
        try {
            update opp;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('Type'),
                'Expected a Type-related validation error, got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(threw, 'A Framework Parent moving from Negotiation to Booking Verification without a Type should be blocked (previously this required-field check only fired on the Negotiation-to-Booked edge, which Framework Parent no longer uses).');
    }

    // Calls Test.startTest() itself (can only be invoked once per test method) so the final
    // stage transition — which triggers several org-wide Opportunity automations — gets a fresh
    // governor-limit context. Callers must NOT call Test.startTest() themselves; they should
    // call Test.stopTest() after their own action instead.
    private static Id createClosedActiveFrameworkParent() {
        Opportunity parent = buildFrameworkOpp();
        insert parent;
        addOcrRoles(parent.Id);
        parent.StageName = 'Solutioning'; update parent;
        addAuthorizedSignatoryRole(parent.Id);
        parent.StageName = 'Negotiation'; update parent;
        addCorrespondenceContactRole(parent.Id);
        parent.StageName = 'Booking Verification'; update parent;

        Test.startTest();
        parent.StageName = 'Closed';
        parent.Framework_Status__c = 'Active';
        update parent;
        Test.stopTest();

        return parent.Id;
    }

    @IsTest
    static void test_childLinkage_blocksWhenParentNotClosed() {
        Opportunity parent = buildFrameworkOpp();
        insert parent; // still at Qualification — not Closed

        Opportunity child = buildChildOpp();
        child.IM_Parent_Opportunity__c = parent.Id;

        Test.startTest();
        Boolean threw = false;
        try {
            insert child;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('must be Closed (Closed Won) and have Framework Status = Active'),
                'Expected the Framework_Parent_Must_Be_Active error, got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assert(threw, 'Linking a child to a non-Closed Framework Parent should be blocked.');
    }

    @IsTest
    static void test_childLinkage_blocksWhenParentClosedButNotActive() {
        Opportunity parent = buildFrameworkOpp();
        insert parent;
        addOcrRoles(parent.Id);
        parent.StageName = 'Solutioning'; update parent;
        addAuthorizedSignatoryRole(parent.Id);
        parent.StageName = 'Negotiation'; update parent;
        addCorrespondenceContactRole(parent.Id);
        parent.StageName = 'Booking Verification'; update parent;

        Test.startTest();
        parent.StageName = 'Closed'; update parent; // Closed but Framework_Status__c left blank (not Active)

        Opportunity child = buildChildOpp();
        child.IM_Parent_Opportunity__c = parent.Id;

        Boolean threw = false;
        try {
            insert child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Linking a child to a Closed-but-not-Active Framework Parent should be blocked.');
    }

    @IsTest
    static void test_childLinkage_allowsWhenParentClosedAndActive() {
        Id parentId = createClosedActiveFrameworkParent();

        Opportunity child = buildChildOpp();
        child.IM_Parent_Opportunity__c = parentId;
        insert child;

        Opportunity result = [SELECT IM_Parent_Opportunity__c FROM Opportunity WHERE Id = :child.Id];
        System.assertEquals(parentId, result.IM_Parent_Opportunity__c,
            'Linking a child to a Closed and Active Framework Parent should be allowed.');
    }

    @IsTest
    static void test_childTypeRestriction_blocksRenewalWhenLinkedToParent() {
        Id parentId = createClosedActiveFrameworkParent();

        Opportunity child = buildChildOpp();
        child.Type = 'Renewal';
        child.IM_Parent_Opportunity__c = parentId;

        Boolean threw = false;
        try {
            insert child;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('may not use Deal Type = Renewal'),
                'Expected the Framework_Child_Type_Restriction error, got: ' + e.getMessage());
        }

        System.assert(threw, 'A child linked to a Framework Parent should not be allowed Type = Renewal.');
    }

    @IsTest
    static void test_childTypeRestriction_allowsNewWhenLinkedToParent() {
        Id parentId = createClosedActiveFrameworkParent();

        Opportunity child = buildChildOpp();
        child.Type = 'New'; // default on buildChildOpp(), set explicitly here for clarity
        child.IM_Parent_Opportunity__c = parentId;
        insert child;

        Opportunity result = [SELECT Type FROM Opportunity WHERE Id = :child.Id];
        System.assertEquals('New', result.Type,
            'A child linked to a Framework Parent should be allowed Type = New.');
    }

    // FW-05: Framework_Booked_Amount__c and Open_Pipeline_Amount__c are computed by the same
    // Recalculate_Framework_Booked_Amount subflow in one pass. Children are inserted directly at
    // their target stage (rather than via a multi-step StageName update) since the shared
    // PRIORVALUE(StageName)-based checklist rules only evaluate on stage *changes*, not inserts.
    @IsTest
    static void test_rollup_computesBookedAmountAndOpenPipelineAmountIndependently() {
        Id parentId = createClosedActiveFrameworkParent();

        Opportunity bookedChild = buildChildOpp();
        bookedChild.IM_Parent_Opportunity__c = parentId;
        bookedChild.StageName = 'Booked';
        bookedChild.Amount = 40000;
        insert bookedChild;

        Opportunity openChild = buildChildOpp();
        openChild.IM_Parent_Opportunity__c = parentId;
        openChild.Amount = 25000; // default StageName = 'Qualification', an open stage
        insert openChild;

        Opportunity result = [SELECT Framework_Booked_Amount__c, Open_Pipeline_Amount__c FROM Opportunity WHERE Id = :parentId];
        System.assertEquals(40000, result.Framework_Booked_Amount__c,
            'Framework_Booked_Amount__c should sum only the Booked child.');
        System.assertEquals(25000, result.Open_Pipeline_Amount__c,
            'Open_Pipeline_Amount__c should sum only the open (Qualification) child.');
    }
}