@IsTest
private class CaseFieldMappingEngineTest {

    // ──────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States', Region__c = 'North America');
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
        // Required by OppPartnerAction (called from OpportunityTriggerHandler.BeforeUpdate via
        // "Update Pricebook On Opportunity" flow — queries this record by name)
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');

        Account parentAcct = new Account(Name = 'IRM Test Parent Account', Industry = 'Technology');
        insert parentAcct;

        Account acc = new Account(
            Name = 'IRM Test Account', ParentId = parentAcct.Id,
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209', BillingCity = 'Boston'
        );
        insert acc;

        // Satisfies the Contact_or_User_Info validation rule (Case requires either ContactId
        // or IM_Employee_Contact__c).
        insert new Contact(LastName = 'CaseFieldMappingTestContact', AccountId = acc.Id);

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            Type = 'New Deal',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = 500000,
            Billing_Country__c = testCountry.Id,
            Bypass_Validation__c = true
        );
        insert opp;
    }

    private static Opportunity getOpp() {
        return [SELECT Id, AccountId, Amount FROM Opportunity LIMIT 1];
    }

    private static Contact getContact() {
        return [SELECT Id FROM Contact LIMIT 1];
    }

    private static Case_Field_Mapping__c makeMapping(
            String recordTypeDevName, String sourceObject, String sourceFieldPath, String targetField) {
        return makeMapping(recordTypeDevName, null, sourceObject, sourceFieldPath, targetField);
    }

    private static Case_Field_Mapping__c makeMapping(
            String recordTypeDevName, String caseType, String sourceObject, String sourceFieldPath, String targetField) {
        Case_Field_Mapping__c m = new Case_Field_Mapping__c(
            Record_Type_Developer_Name__c = recordTypeDevName,
            Case_Type__c = caseType,
            Source_Object__c = sourceObject,
            Source_Field_Path__c = sourceFieldPath,
            Target_Field_API_Name__c = targetField,
            Is_Active__c = true
        );
        insert m;
        return m;
    }

    private static Case makeCase(Id recordTypeId, Id opportunityId, Id accountId, Id contactId) {
        return makeCase(recordTypeId, null, opportunityId, accountId, contactId);
    }

    private static Case makeCase(Id recordTypeId, String caseType, Id opportunityId, Id accountId, Id contactId) {
        Case c = new Case(
            Status = 'New',
            Type = caseType,
            ContactId = contactId,
            RecordTypeId = recordTypeId,
            Opportunity__c = opportunityId,
            AccountId = accountId
        );
        insert c;
        return c;
    }

    private static void applyToCases(List<Id> caseIds) {
        List<CaseFieldMappingEngine.Request> requests = new List<CaseFieldMappingEngine.Request>();
        for (Id caseId : caseIds) {
            CaseFieldMappingEngine.Request req = new CaseFieldMappingEngine.Request();
            req.caseId = caseId;
            requests.add(req);
        }
        CaseFieldMappingEngine.applyMappings(requests);
    }

    // ──────────────────────────────────────────────────────────
    // Tests
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testDirectOpportunityFieldMapping_populatesCase() {
        Opportunity opp = getOpp();
        makeMapping('Deal_Support', 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c');
        Case c = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ c.Id });
        Test.stopTest();

        Case result = [SELECT Account_Closing_Admin_Fee__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(opp.Amount, result.Account_Closing_Admin_Fee__c,
            'Direct Opportunity.Amount mapping should copy onto the Case.');
    }

    @IsTest
    static void testDirectAccountFieldMapping_populatesCase() {
        Opportunity opp = getOpp();
        makeMapping('Deal_Support', 'Account', 'BillingCity', 'Billing_City__c');
        Case c = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ c.Id });
        Test.stopTest();

        Case result = [SELECT Billing_City__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('Boston', result.Billing_City__c,
            'Direct Account.BillingCity mapping should copy onto the Case.');
    }

    @IsTest
    static void testOpportunityRelationshipHopMapping_populatesCase() {
        Opportunity opp = getOpp();
        // One relationship hop off Opportunity via its own lookup (not Account) — the
        // relationship this new engine had to support beyond the existing FieldPath parsers'
        // hardcoded "Account"-only restriction.
        makeMapping('Deal_Support', 'Opportunity', 'Billing_Country__r.Region__c', 'Billing_Division__c');
        Case c = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ c.Id });
        Test.stopTest();

        Case result = [SELECT Billing_Division__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('North America', result.Billing_Division__c,
            'One-hop Opportunity.Billing_Country__r.Region__c mapping should copy onto the Case.');
    }

    @IsTest
    static void testAccountRelationshipHopMapping_populatesCase() {
        Opportunity opp = getOpp();
        // One relationship hop off Account via its standard Parent lookup.
        makeMapping('Deal_Support', 'Account', 'Parent.Industry', 'Billing_Department__c');
        Case c = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ c.Id });
        Test.stopTest();

        Case result = [SELECT Billing_Department__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('Technology', result.Billing_Department__c,
            'One-hop Account.Parent.Industry mapping should copy onto the Case.');
    }

    @IsTest
    static void testUniversalMapping_appliesToBothEligibleRecordTypes() {
        Opportunity opp = getOpp();
        Id contactId = getContact().Id;
        // Blank Record_Type_Developer_Name__c => applies to every eligible Record Type.
        makeMapping(null, 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c');

        Case b2b = makeCase(App_Constants.B2B_IMPLEMENTATION_CASE_RECTYPE_ID, opp.Id, opp.AccountId, contactId);
        Case dealSupport = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, contactId);

        Test.startTest();
        applyToCases(new List<Id>{ b2b.Id, dealSupport.Id });
        Test.stopTest();

        Map<Id, Case> resultsById = new Map<Id, Case>(
            [SELECT Account_Closing_Admin_Fee__c FROM Case WHERE Id IN :new Set<Id>{ b2b.Id, dealSupport.Id }]);
        System.assertEquals(opp.Amount, resultsById.get(b2b.Id).Account_Closing_Admin_Fee__c,
            'Universal mapping should apply to B2B_Implementation Cases.');
        System.assertEquals(opp.Amount, resultsById.get(dealSupport.Id).Account_Closing_Admin_Fee__c,
            'Universal mapping should apply to Deal_Support Cases.');
    }

    @IsTest
    static void testRecordTypeScopedMapping_doesNotApplyToOtherEligibleRecordType() {
        Opportunity opp = getOpp();
        // Scoped only to B2B_Implementation.
        makeMapping('B2B_Implementation', 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c');
        Case dealSupport = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ dealSupport.Id });
        Test.stopTest();

        Case result = [SELECT Account_Closing_Admin_Fee__c FROM Case WHERE Id = :dealSupport.Id];
        System.assertEquals(null, result.Account_Closing_Admin_Fee__c,
            'A mapping scoped to B2B_Implementation should not leak onto a Deal_Support Case.');
    }

    @IsTest
    static void testCaseTypeScopedMapping_appliesOnlyToMatchingCaseType() {
        Opportunity opp = getOpp();
        // Scoped to Deal_Support + Case Type 'Legal' specifically — a Record Type that, per
        // the sheet, spans many unrelated Case Types (Bid Management, Legal, InfoSecurity,
        // etc.), so a Legal-only field must not leak onto an InfoSecurity Case sharing the
        // same Record Type.
        makeMapping('Deal_Support', 'Legal', 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c');

        Case legalCase = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, 'Legal', opp.Id, opp.AccountId, getContact().Id);
        Case infoSecCase = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, 'InfoSecurity', opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ legalCase.Id, infoSecCase.Id });
        Test.stopTest();

        Map<Id, Case> resultsById = new Map<Id, Case>(
            [SELECT Account_Closing_Admin_Fee__c FROM Case WHERE Id IN :new Set<Id>{ legalCase.Id, infoSecCase.Id }]);
        System.assertEquals(opp.Amount, resultsById.get(legalCase.Id).Account_Closing_Admin_Fee__c,
            'A mapping scoped to Case Type Legal should apply to a Legal Case.');
        System.assertEquals(null, resultsById.get(infoSecCase.Id).Account_Closing_Admin_Fee__c,
            'A mapping scoped to Case Type Legal must not leak onto an InfoSecurity Case sharing the same Record Type.');
    }

    @IsTest
    static void testBlankCaseType_appliesToEveryCaseTypeWithinRecordType() {
        Opportunity opp = getOpp();
        // Blank Case_Type__c => applies to every Case Type within Deal_Support.
        makeMapping('Deal_Support', null, 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c');

        Case legalCase = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, 'Legal', opp.Id, opp.AccountId, getContact().Id);
        Case infoSecCase = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, 'InfoSecurity', opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ legalCase.Id, infoSecCase.Id });
        Test.stopTest();

        Map<Id, Case> resultsById = new Map<Id, Case>(
            [SELECT Account_Closing_Admin_Fee__c FROM Case WHERE Id IN :new Set<Id>{ legalCase.Id, infoSecCase.Id }]);
        System.assertEquals(opp.Amount, resultsById.get(legalCase.Id).Account_Closing_Admin_Fee__c,
            'A Case-Type-blank mapping should apply regardless of Case Type.');
        System.assertEquals(opp.Amount, resultsById.get(infoSecCase.Id).Account_Closing_Admin_Fee__c,
            'A Case-Type-blank mapping should apply regardless of Case Type.');
    }

    @IsTest
    static void testIneligibleRecordType_engineIsANoOp() {
        Opportunity opp = getOpp();
        // Universal mapping — would apply to any eligible Record Type if the allow-list gate
        // didn't exist.
        makeMapping(null, 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c');

        Id retentionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Retention').getRecordTypeId();
        Case ineligibleCase = makeCase(retentionRecordTypeId, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ ineligibleCase.Id });
        Test.stopTest();

        Case result = [SELECT Account_Closing_Admin_Fee__c FROM Case WHERE Id = :ineligibleCase.Id];
        System.assertEquals(null, result.Account_Closing_Admin_Fee__c,
            'A Case whose Record Type is not in ELIGIBLE_RECORD_TYPES must never be touched, even with a matching mapping present.');
    }

    @IsTest
    static void testBadTargetField_isSkippedWithoutFailingGoodMappings() {
        Opportunity opp = getOpp();
        makeMapping('Deal_Support', 'Opportunity', 'Amount', 'Not_A_Real_Field__c');
        makeMapping('Deal_Support', 'Account', 'BillingCity', 'Billing_City__c');
        Case c = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ c.Id });
        Test.stopTest();

        Case result = [SELECT Billing_City__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('Boston', result.Billing_City__c,
            'A bad target field on one mapping must not prevent other, valid mappings from applying.');
    }

    @IsTest
    static void testBadSourceFieldPath_isSkippedWithoutFailingGoodMappings() {
        Opportunity opp = getOpp();
        makeMapping('Deal_Support', 'Opportunity', 'Not_A_Real_Opportunity_Field__c', 'Billing_Division__c');
        makeMapping('Deal_Support', 'Account', 'BillingCity', 'Billing_City__c');
        Case c = makeCase(App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID, opp.Id, opp.AccountId, getContact().Id);

        Test.startTest();
        applyToCases(new List<Id>{ c.Id });
        Test.stopTest();

        Case result = [SELECT Billing_Division__c, Billing_City__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, result.Billing_Division__c,
            'A source path that does not resolve against the schema should be dropped, not guessed at.');
        System.assertEquals('Boston', result.Billing_City__c,
            'A bad source path on one mapping must not prevent other, valid mappings from applying.');
    }

    @IsTest
    static void testValidateActiveMappings_flagsUnresolvableRows() {
        makeMapping('Deal_Support', 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c'); // valid
        makeMapping('Deal_Support', 'Opportunity', 'Not_A_Real_Opportunity_Field__c', 'Billing_City__c'); // bad source
        makeMapping('Deal_Support', 'Account', 'BillingCity', 'Not_A_Real_Field__c'); // bad target

        Test.startTest();
        List<String> problems = CaseFieldMappingEngine.validateActiveMappings();
        Test.stopTest();

        System.assertEquals(2, problems.size(),
            'Only the two rows with an unresolvable source path or target field should be flagged.');
    }

    @IsTest
    static void testValidateActiveMappings_noProblemsWithGoodConfig() {
        makeMapping('Deal_Support', 'Opportunity', 'Amount', 'Account_Closing_Admin_Fee__c');
        makeMapping('Deal_Support', 'Account', 'BillingCity', 'Billing_City__c');
        makeMapping(null, 'Opportunity', 'Billing_Country__r.Region__c', 'Billing_Division__c');

        Test.startTest();
        List<String> problems = CaseFieldMappingEngine.validateActiveMappings();
        Test.stopTest();

        System.assertEquals(0, problems.size(), 'Well-formed mappings should report no problems: ' + problems);
    }

    @IsTest
    static void testNoRequests_isNoOp() {
        Test.startTest();
        CaseFieldMappingEngine.applyMappings(new List<CaseFieldMappingEngine.Request>());
        CaseFieldMappingEngine.applyMappings(null);
        Test.stopTest();
        // No exception thrown is the assertion here.
    }
}
