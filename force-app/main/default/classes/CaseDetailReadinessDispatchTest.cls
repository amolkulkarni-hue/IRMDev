@IsTest
private class CaseDetailReadinessDispatchTest {
    // The Requester_Info_Complete__c dispatch formula on Case_Detail__c matches on
    // TEXT(Case__r.Type) against literal strings written when the design was first drafted
    // ("InfoSecurity", "Bid Management", "Legal"). The live Case.Type picklist values that
    // actually ship for these three sections are different ("InfoSec / Security
    // Questionnaire", "RFP / Bid Management", "Legal Review") — confirmed via
    // `sf sobject describe Case`. Because none of those three IF() branches can ever match,
    // the formula falls through to its `true` default for every Bid Management, InfoSecurity,
    // and Legal Case — reporting "seller info complete" even when the section's required
    // fields are still blank. Remarketing's Case.Type value does match its branch, so it's
    // included here as a working control.
    //
    // Each test below inserts a Case of the given type with its Case_Detail__c child's fields
    // left blank, and asserts Case.Requester_Info_Complete__c is false. Remarketing is
    // expected to pass; Bid Management, InfoSecurity, and Legal are expected to fail until the
    // dispatch formula's literals are corrected to match the live picklist.

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'ReadinessDispatchE2E Account');
        insert acc;
        insert new Contact(LastName = 'ReadinessDispatchE2E', AccountId = acc.Id);
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

    private static Boolean requesterInfoCompleteFor(Id caseId) {
        return [SELECT Requester_Info_Complete__c FROM Case WHERE Id = :caseId].Requester_Info_Complete__c;
    }

    @IsTest
    static void testRemarketing_blankFields_reportsIncomplete_CONTROL() {
        Case c = insertCaseOfType('Remarketing');
        System.assertEquals(false, requesterInfoCompleteFor(c.Id),
            'Remarketing Case.Type matches its dispatch branch, so a Case with blank Requester fields should correctly report incomplete.');
    }

    @IsTest
    static void testBidManagement_blankFields_shouldReportIncomplete() {
        Case c = insertCaseOfType('RFP / Bid Management');
        System.assertEquals(false, requesterInfoCompleteFor(c.Id),
            'GAP: dispatch formula checks Case.Type = "Bid Management", but the live value is "RFP / Bid Management" — the branch never matches, so this always reads true regardless of actual field completion.');
    }

    @IsTest
    static void testInfoSecurity_blankFields_shouldReportIncomplete() {
        Case c = insertCaseOfType('InfoSec / Security Questionnaire');
        System.assertEquals(false, requesterInfoCompleteFor(c.Id),
            'GAP: dispatch formula checks Case.Type = "InfoSecurity", but the live value is "InfoSec / Security Questionnaire" — the branch never matches, so this always reads true regardless of actual field completion.');
    }

    @IsTest
    static void testLegal_blankFields_shouldReportIncomplete() {
        Case c = insertCaseOfType('Legal Review');
        System.assertEquals(false, requesterInfoCompleteFor(c.Id),
            'GAP: dispatch formula checks Case.Type = "Legal", but the live value is "Legal Review" — the branch never matches, so this always reads true regardless of actual field completion.');
    }

    @IsTest
    static void testRemarketing_allRequesterFieldsFilled_reportsComplete() {
        Case c = insertCaseOfType('Remarketing');
        Case_Detail__c child = [SELECT Id FROM Case_Detail__c WHERE Case__c = :c.Id];
        child.RMKT_Asset_Type__c = 'Desktop';
        child.RMKT_Nature_Of_Request__c = 'Bid';
        child.RMKT_Condition_Notes__c = 'Used';
        child.RMKT_Due_Date__c = Date.today().addDays(3);
        child.RMKT_Take_Out_Time_Frame__c = '30';
        update child;

        System.assertEquals(true, requesterInfoCompleteFor(c.Id),
            'Once every Remarketing Requester field the completeness formula checks is filled in, Case.Requester_Info_Complete__c should read true.');
    }
}
