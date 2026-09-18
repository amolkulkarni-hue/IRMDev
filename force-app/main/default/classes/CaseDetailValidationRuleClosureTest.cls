@IsTest
private class CaseDetailValidationRuleClosureTest {
    // All 10 "Require_..._Fields_Before_Closure" validation rules live on Case_Detail__c, not
    // Case, and their errorConditionFormula reads up to the parent (Case__r.Status,
    // Case__r.Type, Case__r.RecordType). That means they only evaluate when a DML statement
    // actually runs against the Case_Detail__c record — a Case.Status update by itself does
    // NOT touch the child record (confirmed: no flow/trigger in this org writes to
    // Case_Detail__c when Case.Status changes; Case_Exit_Document_Validation_Flow gates on
    // Document_Checklist__c, a separate object, and Case_Detail_Readiness_Sync_Flow only
    // writes Case_Detail__c -> Case, never the reverse).
    //
    // GAP (Finding F): every rule's own description says it "Blocks closing a Case as Closed -
    // Approved until..." — but closing the Case directly, with the Case_Detail__c child left
    // completely blank, saves with no error at all. The rule only fires later, if someone
    // happens to re-save the already-closed Case_Detail__c record. This is demonstrated below
    // for Remarketing (a section whose Case.Type string is correctly matched) before also
    // covering Finding A's validation-rule half (Bid Management / InfoSecurity / Legal / MSP
    // never fire even on that later re-save, because their Type literal doesn't match the live
    // picklist value at all).

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'ValidationClosureE2E Account');
        insert acc;
        insert new Contact(LastName = 'ValidationClosureE2E', AccountId = acc.Id);
    }

    private static Id dealSupportRTId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Deal_Support' LIMIT 1].Id;
    }

    private static Case insertCaseOfType(String caseType) {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Case c = new Case(RecordTypeId = dealSupportRTId(), Type = caseType, ContactId = con.Id, Status = 'New');
        insert c;
        return c;
    }

    private static Case_Detail__c childFor(Id caseId) {
        return [SELECT Id, Case__c FROM Case_Detail__c WHERE Case__c = :caseId LIMIT 1];
    }

    @IsTest
    static void testClosingCaseDirectlyWithBlankRequiredFields_doesNotBlock_evenForAWorkingSection() {
        Case c = insertCaseOfType('Remarketing');

        Boolean threw = false;
        Test.startTest();
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(false, threw,
            'GAP: updating Case.Status directly performs no DML on Case_Detail__c, so Require_Remarketing_Before_Closure never evaluates at the moment of closure — the Case saves as Closed - Approved with every Remarketing Requester field still blank, contradicting the rule\'s stated purpose.');
    }

    @IsTest
    static void testReSavingCaseDetailAfterCaseAlreadyClosed_blocksForAWorkingSection() {
        Case c = insertCaseOfType('Remarketing');
        c.Status = 'Closed - Approved';
        update c;
        Case_Detail__c child = childFor(c.Id);

        Boolean threw = false;
        Test.startTest();
        try {
            child.RMKT_Take_Out_Time_Frame__c = null;
            update child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw,
            'Once the Case is already Closed - Approved, re-saving the Case_Detail__c child with required Remarketing fields still blank should be blocked by Require_Remarketing_Before_Closure — confirming the rule logic itself is correct, just wired to the wrong trigering event (see the companion test in this class).');
    }

    @IsTest
    static void testReSavingCaseDetailAfterCaseAlreadyClosed_doesNotBlockForBidManagement() {
        Case c = insertCaseOfType('RFP / Bid Management');
        c.Status = 'Closed - Approved';
        update c;
        Case_Detail__c child = childFor(c.Id);

        Boolean threw = false;
        Test.startTest();
        try {
            child.BM_Submission_Method__c = null;
            update child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(false, threw,
            'GAP: Require_BidMgmt_Fields_Before_Closure checks Case__r.Type = "Bid Management", but the live picklist value is "RFP / Bid Management" — the rule can never fire for a real Bid Management Case, blank fields or not.');
    }

    @IsTest
    static void testReSavingCaseDetailAfterCaseAlreadyClosed_doesNotBlockForInfoSecurity() {
        Case c = insertCaseOfType('InfoSec / Security Questionnaire');
        c.Status = 'Closed - Approved';
        update c;
        Case_Detail__c child = childFor(c.Id);

        Boolean threw = false;
        Test.startTest();
        try {
            update child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(false, threw,
            'GAP: Require_InfoSec_Fields_Before_Closure checks Case__r.Type = "InfoSecurity", but the live picklist value is "InfoSec / Security Questionnaire" — the rule can never fire for a real InfoSecurity Case.');
    }

    @IsTest
    static void testReSavingCaseDetailAfterCaseAlreadyClosed_doesNotBlockForLegal() {
        Case c = insertCaseOfType('Legal Review');
        c.Status = 'Closed - Approved';
        update c;
        Case_Detail__c child = childFor(c.Id);

        Boolean threw = false;
        Test.startTest();
        try {
            update child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(false, threw,
            'GAP: Require_Legal_Fields_Before_Closure checks Case__r.Type = "Legal", but the live picklist value is "Legal Review" — the rule can never fire for a real Legal Case.');
    }

    @IsTest
    static void testReSavingCaseDetailAfterCaseAlreadyClosed_doesNotBlockForMSP() {
        Case c = insertCaseOfType('Managed Services Program');
        c.Status = 'Closed - Approved';
        update c;
        Case_Detail__c child = childFor(c.Id);

        Boolean threw = false;
        Test.startTest();
        try {
            update child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(false, threw,
            'GAP: Require_MSP_Fields_Before_Closure checks Case__r.Type = "Managed Service Program" (singular "Service"), but the live picklist value is "Managed Services Program" (plural "Services") — the rule can never fire for a real MSP Case.');
    }

    @IsTest
    static void testReSavingCaseDetailAfterCaseAlreadyClosed_blocksForGCCS_CONTROL() {
        Case c = insertCaseOfType('GCCS');
        c.Status = 'Closed - Approved';
        update c;
        Case_Detail__c child = childFor(c.Id);

        Boolean threw = false;
        Test.startTest();
        try {
            update child;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw,
            'GCCS\'s Case.Type literal matches the live picklist value exactly, so once the Case is already Closed - Approved, re-saving the still-blank Case_Detail__c child should be blocked by Require_GCCS_Fields_Before_Closure.');
    }

    @IsTest
    static void testClosedRejectedDoesNotTriggerAnyClosureValidation() {
        Case c = insertCaseOfType('Remarketing');

        Boolean threw = false;
        Test.startTest();
        try {
            c.Status = 'Closed - Rejected';
            update c;
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(false, threw,
            'The closure validation rules are intentionally scoped to Status = "Closed - Approved" only — closing a Case as Rejected should never be blocked by them, per design intent.');
    }
}
