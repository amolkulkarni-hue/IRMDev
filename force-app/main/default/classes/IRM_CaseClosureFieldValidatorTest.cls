/**
 * @description Tests for IRM_CaseClosureFieldValidator. Real DML on Case is used
 * throughout (Database.update with allOrNone=false) so the actual trigger fires — this
 * is the same reasoning as OpportunityTriggerTest earlier in this engagement: a service
 * class unit test alone wouldn't confirm the trigger wiring itself is correct.
 */
@IsTest
private class IRM_CaseClosureFieldValidatorTest {

    private static final String CLOSED_APPROVED_STATUS = 'Closed - Approved';

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        insert new Country_Settings__c(
            Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId()
        );

        Account acc = new Account(
            Name = 'Case Closure Validation Test Account',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;

        // Satisfies the Contact_or_User_Info validation rule (Case requires either
        // ContactId or IM_Employee_Contact__c).
        insert new Contact(LastName = 'CaseClosureValidationTestContact', AccountId = acc.Id);
    }

    private static Id getDealSupportRecordTypeId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Deal_Support').getRecordTypeId();
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Contact getContact() {
        return [SELECT Id FROM Contact LIMIT 1];
    }

    private static Case makeCase(String caseType, String status) {
        Case c = new Case(
            RecordTypeId = getDealSupportRecordTypeId(),
            Type = caseType,
            Status = status,
            AccountId = getAccount().Id,
            ContactId = getContact().Id
        );
        insert c;

        // Case_Detail_Auto_Create_Flow only fires for Cases linked to an Opportunity
        // (RecordType_Name__c = 'Post Sale Support' or 'Deal Support' AND
        // Opportunity__c is not null) — these tests don't set Opportunity__c, so the
        // flow never creates the child. Insert it directly instead; this validator only
        // cares about the Case_Detail__c child's field values, not how it was created.
        insert new Case_Detail__c(Case__c = c.Id);

        return c;
    }

    private static Case_Detail__c getCaseDetail(Id caseId) {
        return [SELECT Id FROM Case_Detail__c WHERE Case__c = :caseId LIMIT 1];
    }

    // ─── GCCS: simplest section, single required field ─────────────────────

    @IsTest
    static void testGCCS_blocksClosure_whenRequiredFieldMissing() {
        // Given
        Case c = makeCase('GCCS', 'New');
        // GCCS_Request_Type__c left blank on the Case_Detail__c child

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isFalse(result.isSuccess(), 'Closing a GCCS Case with no Request Type should fail');

    }

    @IsTest
    static void testGCCS_allowsClosure_whenRequiredFieldPopulated() {
        // Given
        Case c = makeCase('GCCS', 'New');
        Case_Detail__c cd = getCaseDetail(c.Id);
        cd.GCCS_Request_Type__c = 'Account Administration';
        update cd;

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isTrue(result.isSuccess(), 'Closing a GCCS Case with Request Type populated should succeed: '
            + (result.getErrors().isEmpty() ? '' : result.getErrors()[0].getMessage()));
    }

    // ─── Bid Management: multiple required fields, partial completion ──────

    @IsTest
    static void testBidManagement_listsAllMissingFields() {
        // Given
        Case c = makeCase('RFP / Bid Management', 'New');
        Case_Detail__c cd = getCaseDetail(c.Id);
        cd.BM_Request_Type__c = 'RFP/RFT'; // only 1 of 4 required fields populated
        update cd;

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isFalse(result.isSuccess());
        String message = result.getErrors()[0].getMessage();
        Assert.isTrue(message.contains('Due Date'), 'Missing Due Date should be listed: ' + message);
        Assert.isTrue(message.contains('Portal Login Required'), 'Missing Portal Login Required should be listed: ' + message);
        Assert.isTrue(message.contains('Submission Method'), 'Missing Submission Method should be listed: ' + message);
        Assert.isFalse(message.contains('Request Type,'), 'Populated Request Type should not be listed as missing');
    }

    @IsTest
    static void testBidManagement_allowsClosure_whenAllFieldsPopulated() {
        // Given
        Case c = makeCase('RFP / Bid Management', 'New');
        Case_Detail__c cd = getCaseDetail(c.Id);
        cd.BM_Request_Type__c = 'RFP/RFT';
        cd.BM_Due_Date__c = Date.today().addDays(5);
        cd.BM_Portal_Login_Required__c = 'No';
        cd.BM_Submission_Method__c = 'Email';
        update cd;

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isTrue(result.isSuccess(), 'All 4 Bid Management fields populated should allow closure: '
            + (result.getErrors().isEmpty() ? '' : result.getErrors()[0].getMessage()));
    }

    // ─── Booking Verification: conditional Rejection Reasons logic ─────────

    @IsTest
    static void testBookingVerification_passRequiresNoRejectionReasons() {
        // Given
        Case c = makeCase('Booking Verification', 'New');
        Case_Detail__c cd = getCaseDetail(c.Id);
        cd.BV_Status__c = 'Pass'; // no rejection reasons needed
        update cd;

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isTrue(result.isSuccess(),
            'A Passed Booking Verification Case should close without any Rejection Reasons: '
            + (result.getErrors().isEmpty() ? '' : result.getErrors()[0].getMessage()));
    }

    @IsTest
    static void testBookingVerification_rejectWithoutReasons_isBlocked() {
        // Given
        Case c = makeCase('Booking Verification', 'New');
        Case_Detail__c cd = getCaseDetail(c.Id);
        cd.BV_Status__c = 'Reject'; // Rejection Reasons left blank
        update cd;

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isFalse(result.isSuccess(), 'A Rejected Case with no Rejection Reasons should be blocked');
        Assert.isTrue(result.getErrors()[0].getMessage().contains('Rejection Reasons'),
            'Error should name Rejection Reasons: ' + result.getErrors()[0].getMessage());
    }

    @IsTest
    static void testBookingVerification_rejectWithReasons_succeeds() {
        // Given
        Case c = makeCase('Booking Verification', 'New');
        Case_Detail__c cd = getCaseDetail(c.Id);
        cd.BV_Status__c = 'Reject';
        cd.BV_Rejection_Reasons__c = '1-Missing Contractual Documents';
        update cd;

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isTrue(result.isSuccess(), 'A Rejected Case with Rejection Reasons populated should close: '
            + (result.getErrors().isEmpty() ? '' : result.getErrors()[0].getMessage()));
    }

    @IsTest
    static void testBookingVerification_blankStatus_isBlocked() {
        // Given
        Case c = makeCase('Booking Verification', 'New');
        // BV_Status__c left blank entirely

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isFalse(result.isSuccess());
        Assert.isTrue(result.getErrors()[0].getMessage().contains('Booking Verification Status'),
            'Error should name BV Status: ' + result.getErrors()[0].getMessage());
    }

    // ─── Cross-cutting behavior ─────────────────────────────────────────────

    @IsTest
    static void testNonClosedStatus_isNeverChecked() {
        // Given
        Case c = makeCase('GCCS', 'New');
        // GCCS_Request_Type__c left blank — would fail if checked

        // When: update something unrelated, staying in a non-closed status
        c.Priority = 'High';
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isTrue(result.isSuccess(), 'Non-closure updates should never trigger this validation');
    }

    @IsTest
    static void testUngovernedCaseType_isNeverChecked() {
        // Given: a Case Type with no entry in TYPE_TO_REQUIRED_FIELDS and not Booking
        // Verification — e.g. B2B Implementation's own Case Type, which has no
        // Case-Owner-populated fields to gate closure on.
        Case c = makeCase('New Deal', 'New'); // arbitrary ungoverned Type value

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isTrue(result.isSuccess(), 'An ungoverned Case Type should never be blocked: '
            + (result.getErrors().isEmpty() ? '' : result.getErrors()[0].getMessage()));
    }

    @IsTest
    static void testMissingCaseDetailChild_blocksClosure() {
        // Given: a Case of a governed Type whose Case_Detail__c child is deleted before closure
        Case c = makeCase('GCCS', 'New');
        delete getCaseDetail(c.Id);

        // When
        c.Status = CLOSED_APPROVED_STATUS;
        Test.startTest();
        Database.SaveResult result = Database.update(c, false);
        Test.stopTest();

        // Then
        Assert.isFalse(result.isSuccess(), 'A governed Case Type with no Case Detail child should be blocked');
        Assert.isTrue(result.getErrors()[0].getMessage().contains('no linked Case Detail record'),
            'Error should explain the missing child: ' + result.getErrors()[0].getMessage());
    }
}