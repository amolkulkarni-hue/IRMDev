/**
 * IRM_DocChecklistUploadTest
 * US-DOCUPLOAD: Tests for IRM_AttachFilesAction — the Apex invocable action
 * called by Upload_Document_Checklist_Flow to cross-link uploaded files to
 * the parent Case/Opp after they are uploaded to the Document_Checklist__c.
 *
 * Screen Flow (Upload_Document_Checklist_Flow) must be ACTIVE in Setup → Flows.
 *
 * Test coverage:
 *   AC1 — file linked to target record
 *   AC2 — file linked to both target and additional target (Case → Opp cross-link)
 *   AC3 — dedup: no duplicate ContentDocumentLink created on re-run
 *   AC4 — empty content document ID list → no insert, no exception
 *   AC5 — null content document ID list → no insert, no exception
 *   AC6 — from Opp: file NOT cross-linked to Case
 *   AC7 — multiple files linked in a single call
 */
@IsTest
private class IRM_DocChecklistUploadTest {

    @TestSetup
    static void setup() {
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
            new Opportunity_Security__c(Name = 'Primary CDE',         Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',      Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity',   Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',         Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',      Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new OpportunityProductSelection__c(
            Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions'
        );
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',  Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',   Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',    Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion', Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };
        Account acc = new Account(
            Name = 'IRM DocUpload Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        insert new Contact(LastName = 'DocUploadContact', AccountId = acc.Id);
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Id getContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }

    private static Opportunity makeOpp() {
        Opportunity opp = new Opportunity(
            Name = 'DocUpload Test Opp', AccountId = getAccount().Id,
            Type = 'New Deal', StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = 500000,
            Bypass_Validation__c = true
        );
        insert opp;
        return opp;
    }

    private static Case makeCase(Id accId, Id contactId, Id oppId) {
        Case c = new Case(
            AccountId = accId, ContactId = contactId,
            Subject = 'DocUpload Test Case',
            Status = 'In Progress',
            Opportunity__c = oppId
        );
        insert c;
        return c;
    }

    private static Document_Checklist__c makeDocChecklist(Id caseId, Id oppId) {
        Document_Checklist__c doc = new Document_Checklist__c(
            Case__c = caseId,
            Opportunity__c = oppId,
            Doc_Type__c = 'Technical Scoping Form',
            Doc_Category__c = 'Scoping & Technical',
            Status__c = 'Draft'
        );
        insert doc;
        return doc;
    }

    /** Creates a ContentVersion and returns its ContentDocumentId. */
    private static Id createContentDoc(String title) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.txt',
            VersionData = Blob.valueOf('Test content — ' + title),
            IsMajorVersion = true
        );
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    private static IRM_AttachFilesAction.AttachRequest buildRequest(
            List<String> docIds, String targetId, String additionalId) {
        IRM_AttachFilesAction.AttachRequest req = new IRM_AttachFilesAction.AttachRequest();
        req.contentDocumentIds      = docIds;
        req.targetRecordId          = targetId;
        req.additionalTargetRecordId = additionalId;
        return req;
    }

    private static Integer countLinks(Id contentDocId, Id entityId) {
        return [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocId AND LinkedEntityId = :entityId
        ];
    }

    // ── AC1: File linked to primary target record ──────────────────────────────

    @IsTest
    static void test_attachFilesLinksToTargetRecord() {
        Opportunity opp = makeOpp();
        Id docId = createContentDoc('AC1_TargetLink');

        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(new List<String>{ docId }, opp.Id, null)
        });
        Test.stopTest();

        Assert.areEqual(1, countLinks(docId, opp.Id),
            'AC1: Expected one ContentDocumentLink to the Opportunity');
    }

    // ── AC2: File cross-linked to Opportunity when invoked from Case ───────────

    @IsTest
    static void test_attachFilesFromCaseLinksToOpp() {
        Opportunity opp = makeOpp();
        Case c = makeCase(getAccount().Id, getContactId(), opp.Id);
        Document_Checklist__c doc = makeDocChecklist(c.Id, opp.Id);
        Id docId = createContentDoc('AC2_CaseToOpp');

        // Simulate the flow: file upload screen attached file to DocChecklist
        insert new ContentDocumentLink(
            ContentDocumentId = docId, LinkedEntityId = doc.Id,
            ShareType = 'V', Visibility = 'AllUsers'
        );

        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(new List<String>{ docId }, c.Id, opp.Id)
        });
        Test.stopTest();

        Assert.areEqual(1, countLinks(docId, c.Id),
            'AC2: Expected one ContentDocumentLink to the Case');
        Assert.areEqual(1, countLinks(docId, opp.Id),
            'AC2: Expected one ContentDocumentLink to the Opportunity');
    }

    // ── AC3: No duplicate ContentDocumentLink on second invocation ─────────────

    @IsTest
    static void test_attachFilesDedupsPreviousLinks() {
        Opportunity opp = makeOpp();
        Id docId = createContentDoc('AC3_Dedup');

        // Pre-existing link (e.g. from a prior call or existing file on record)
        insert new ContentDocumentLink(
            ContentDocumentId = docId, LinkedEntityId = opp.Id,
            ShareType = 'V', Visibility = 'AllUsers'
        );

        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(new List<String>{ docId }, opp.Id, null)
        });
        Test.stopTest();

        Assert.areEqual(1, countLinks(docId, opp.Id),
            'AC3: Dedup failed — duplicate ContentDocumentLink created');
    }

    // ── AC4: Empty contentDocumentIds list → no insert, no exception ───────────

    @IsTest
    static void test_attachFilesEmptyListIsNoOp() {
        Opportunity opp = makeOpp();

        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(new List<String>(), opp.Id, null)
        });
        Test.stopTest();

        Assert.areEqual(0,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id],
            'AC4: No links should exist for an empty file list');
    }

    // ── AC5: Null contentDocumentIds → no insert, no exception ─────────────────

    @IsTest
    static void test_attachFilesNullListIsNoOp() {
        Opportunity opp = makeOpp();

        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(null, opp.Id, null)
        });
        Test.stopTest();

        Assert.areEqual(0,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id],
            'AC5: No links should exist for a null file list');
    }

    // ── AC6: From Opp — file NOT cross-linked to Case ──────────────────────────

    @IsTest
    static void test_attachFilesFromOppDoesNotLinkToCase() {
        Opportunity opp = makeOpp();
        Case c = makeCase(getAccount().Id, getContactId(), opp.Id);
        Id docId = createContentDoc('AC6_OppOnly');

        // No additionalTargetRecordId → Opp upload should not touch the Case
        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(new List<String>{ docId }, opp.Id, null)
        });
        Test.stopTest();

        Assert.areEqual(0, countLinks(docId, c.Id),
            'AC6: File must NOT be linked to Case when uploaded from Opportunity');
        Assert.areEqual(1, countLinks(docId, opp.Id),
            'AC6: File should be linked to Opportunity');
    }

    // ── AC7: Multiple files linked in a single call ─────────────────────────────

    @IsTest
    static void test_attachFilesMultipleFilesInOneCall() {
        Opportunity opp = makeOpp();
        Id docId1 = createContentDoc('AC7_File1');
        Id docId2 = createContentDoc('AC7_File2');
        Id docId3 = createContentDoc('AC7_File3');

        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(new List<String>{ docId1, docId2, docId3 }, opp.Id, null)
        });
        Test.stopTest();

        Assert.areEqual(3,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id],
            'AC7: All 3 files should be linked to the Opportunity');
    }

    // ── AC8: Multiple files cross-linked Case → Opp ────────────────────────────

    @IsTest
    static void test_attachFilesMultipleFilesFromCase() {
        Opportunity opp = makeOpp();
        Case c = makeCase(getAccount().Id, getContactId(), opp.Id);
        Id docId1 = createContentDoc('AC8_File1');
        Id docId2 = createContentDoc('AC8_File2');

        Test.startTest();
        IRM_AttachFilesAction.attachFiles(new List<IRM_AttachFilesAction.AttachRequest>{
            buildRequest(new List<String>{ docId1, docId2 }, c.Id, opp.Id)
        });
        Test.stopTest();

        Assert.areEqual(2,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id],
            'AC8: Both files should be linked to the Case');
        Assert.areEqual(2,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id],
            'AC8: Both files should be cross-linked to the Opportunity');
    }
}