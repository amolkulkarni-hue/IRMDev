@IsTest
private class CaseCreationEndToEndTest {
    // Mirrors the manual walkthrough performed in IRMNewDev: an Opportunity Stage change
    // drives the real trigger chain (OpportunityTriggerHandler -> CaseCreationRuleEvaluatorAction)
    // through Case creation, Document_Checklist__c creation, Case_Detail__c auto-creation
    // (Case_Detail_Auto_Create_Flow), document completion (Case_Creation_Trigger_Flow's
    // All_Start_Docs_Final__c rollup), Case Detail field completion, and a final attempt to
    // close the Case. The rule/condition/doc-requirement rows below are built fresh in
    // @TestSetup rather than depending on the live org's seed data (Case_Creation_Rule__c
    // config in IRMNewDev has already changed shape once during this engagement), and Apex
    // tests can't see org data by default anyway.

    @TestSetup
    static void setup() {
        // Required by OpportunityHelper.createOpportunityShare, which every Opportunity
        // insert/update triggers: it queries Country_Settings__c.getAll() to build a dynamic
        // SOQL IN() clause. Custom Setting data isn't inherited from the org in test context,
        // so without this the clause renders as "IN ()" (invalid SOQL) and blocks every
        // Opportunity DML in this test with a generic addError. Same fix already used by
        // CaseCreationRuleEvaluatorActionTest.cls.
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        // OppPartnerAction has a class-level static SOQL (no LIMIT) for a row named
        // 'CloudSolutionsProduct' — it runs on class init, which any Opportunity trigger
        // execution forces. With zero rows in test context this throws "List has no rows for
        // assignment to SObject" before any Opportunity DML in this test can even run.
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct', Product_Class_Name__c = 'Cloud Solutions', Product_Line_Name__c = 'Cloud Solutions');
        // SVStatus.updateSVStatus (fires on Opportunity Amount/Type/RecordType/Stage change)
        // does SVStatus__c.getValues('SVStatusPassed') with no null guard — without this row it
        // NPEs on the StageName update this test performs. Only this test class needs it, since
        // it's the only one that updates an Opportunity's Stage after insert.
        insert new SVStatus__c(Name = 'SVStatusPassed', OpptType__c = 'New Deal', Stage__c = 'Solutioning', Amount__c = 0);

        Account acc = new Account(Name = 'CaseCreationE2E Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'CaseCreationE2E Test Opp',
            AccountId = acc.Id,
            StageName = 'Draft', // neutral stage: no Case_Creation_Rule__c is scoped to it
            CloseDate = Date.today().addDays(30),
            Amount = 50000,
            Type = 'New Deal',
            Business_Unit__c = 'ALM',
            Touch_Level__c = 'Low Touch',
            Remarketing_Required__c = 'Yes'
        );
        insert opp;

        Case_Creation_Rule__c rule = new Case_Creation_Rule__c(
            Case_Type__c = 'Remarketing',
            Stage__c = 'Solutioning',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Remarketing_Queue',
            Is_Active__c = true,
            Priority__c = 10,
            Logic_Expression__c = '1 AND 2 AND 3 AND 4 AND 5'
        );
        insert rule;

        insert new List<Case_Creation_Condition__c>{
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 1, Field_API_Name__c = 'Remarketing_Required__c', Operator__c = 'EQUALS', Value__c = 'Yes'),
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 2, Field_API_Name__c = 'Amount', Operator__c = 'LESS_THAN', Value__c = '75000'),
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 3, Field_API_Name__c = 'Business_Unit__c', Operator__c = 'EQUALS', Value__c = 'ALM'),
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 4, Field_API_Name__c = 'Touch_Level__c', Operator__c = 'EQUALS', Value__c = 'Low Touch'),
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 5, Field_API_Name__c = 'Type', Operator__c = 'EQUALS', Value__c = 'New Deal')
        };

        insert new List<Case_Creation_Doc_Requirement__c>{
            new Case_Creation_Doc_Requirement__c(Rule__c = rule.Id, Doc_Type__c = 'Asset Condition Report', Doc_Category__c = 'Scoping & Technical', Is_Required_To_Start__c = true, Is_Required_For_Case__c = true),
            new Case_Creation_Doc_Requirement__c(Rule__c = rule.Id, Doc_Type__c = 'Site Logistics / Floor Plan', Doc_Category__c = 'Scoping & Technical', Is_Required_To_Start__c = true, Is_Required_For_Case__c = true),
            new Case_Creation_Doc_Requirement__c(Rule__c = rule.Id, Doc_Type__c = 'Revenue Share Model', Doc_Category__c = 'Scoping & Technical', Is_Required_To_Start__c = true, Is_Required_For_Case__c = true)
        };
    }

    @IsTest
    static void testOpportunityStageChangeDrivesFullCaseLifecycle() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Step 1: the Opportunity update — real trigger path, not a direct invocable call.
        Test.startTest();
        opp.StageName = 'Solutioning';
        update opp;
        Test.stopTest(); // forces ReassertCaseOwnerJob to run before we assert OwnerId below

        // Step 2: exactly one Case created, owned by the resolved queue, Status still New.
        List<Case> cases = [SELECT Id, Type, Status, OwnerId, RecordType.DeveloperName FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, cases.size(), 'Expected exactly one Case created by the Stage change.');
        Case createdCase = cases[0];
        System.assertEquals('Remarketing', createdCase.Type);
        System.assertEquals('Deal_Support', createdCase.RecordType.DeveloperName);
        System.assertEquals('New', createdCase.Status);
        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'Remarketing_Queue' AND Type = 'Queue' LIMIT 1];
        System.assertEquals(queue.Id, createdCase.OwnerId, 'Case should be owned by the rule-resolved queue at creation (current behavior — see Story 6 gap).');

        // Step 3: all 3 configured Document Checklist rows created and linked to the Case.
        List<Document_Checklist__c> checklists = [
            SELECT Id, Doc_Type__c, Status__c FROM Document_Checklist__c WHERE Case__c = :createdCase.Id
        ];
        System.assertEquals(3, checklists.size(), 'Expected one Document_Checklist__c per configured Doc Requirement.');
        Set<String> docTypes = new Set<String>();
        for (Document_Checklist__c dc : checklists) docTypes.add(dc.Doc_Type__c);
        System.assert(docTypes.contains('Asset Condition Report'));
        System.assert(docTypes.contains('Site Logistics / Floor Plan'));
        System.assert(docTypes.contains('Revenue Share Model'));

        // Step 4: Case_Detail_Auto_Create_Flow creates exactly one Case_Detail__c child.
        Case_Detail__c detail = [SELECT Id, Case__c FROM Case_Detail__c WHERE Case__c = :createdCase.Id];

        // Step 5: mark every checklist item Final — Case_Creation_Trigger_Flow should flip
        // Case.All_Start_Docs_Final__c to true once none remain non-Final.
        for (Document_Checklist__c dc : checklists) dc.Status__c = 'Final';
        update checklists;
        Case afterDocs = [SELECT All_Start_Docs_Final__c FROM Case WHERE Id = :createdCase.Id];
        System.assertEquals(true, afterDocs.All_Start_Docs_Final__c,
            'Marking every linked Document_Checklist__c Final should flip Case.All_Start_Docs_Final__c to true.');

        // Step 6: fill in the Remarketing Case Detail fields via direct update (simulates the
        // seller completing the Related Record component's Quick Action fields).
        detail.RMKT_Asset_Type__c = 'Desktop';
        detail.RMKT_Nature_Of_Request__c = 'Bid';
        detail.RMKT_Condition_Notes__c = 'Used';
        detail.RMKT_Due_Date__c = Date.today().addDays(5);
        detail.RMKT_Request_Type__c = 'Test remarketing request';
        detail.RMKT_Take_Out_Time_Frame__c = '30';
        detail.RMKT_Revenue_Share_Percentage__c = 10;
        detail.RMKT_Data_Destruction_Req__c = 'Wiping (Remarketing-ready)';
        update detail;

        // Step 7: attempt to close the Case as Approved.
        // GAP (#1, already documented in CaseDetailValidationRuleClosureTest): the closure
        // validation rules live on Case_Detail__c and only re-evaluate on DML against that
        // object, so updating Case.Status directly never re-triggers them. This save succeeds
        // today regardless of whether step 6 happened — this assertion documents that current
        // behavior end-to-end. Once the After-Save "touch" Flow fix is built, this method
        // should be revisited: a variant leaving Case Detail fields blank should then throw.
        Case toClose = new Case(Id = createdCase.Id, Status = 'Closed - Approved');
        Boolean threw = false;
        try {
            update toClose;
        } catch (DmlException e) {
            threw = true;
        }
        System.assertEquals(false, threw,
            'Current behavior: closing the Case succeeds even though Case_Detail__c fields were just completed, because nothing forces the child\'s validation rules to re-evaluate at the moment of closure.');

        Case finalCase = [SELECT Status FROM Case WHERE Id = :createdCase.Id];
        System.assertEquals('Closed - Approved', finalCase.Status);
    }
}
