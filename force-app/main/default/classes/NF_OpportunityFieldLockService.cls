/**
 * @description:  Enforces field-level locks on Standard/Framework Opportunities once a
 * record reaches a restricted stage, per the Opportunity Stage Governance and Booking
 * Verification Control and active Locked_Opportunity_Field__mdt configuration. 
 */
public with sharing class NF_OpportunityFieldLockService {

    @TestVisible
    private static final String BOOKING_VERIFICATION_STAGE = 'Booking Verification';
    @TestVisible
    private static final String BOOKED_STAGE = 'Booked';
    @TestVisible
    private static final String STAGE_OVERRIDE_PERMISSION = 'Booking_Verification_Access';
    @TestVisible
    private static final String BYPASS_PERMISSION = 'Bypass_Opportunity_Validation';
    private static final String LOCK_ERROR_MESSAGE =
        'This Opportunity is locked from further edits. Please add a Chatter post ' +
        'to request updates or provide information to the Booking Verification team.';

    @TestVisible
    private static Map<String, String> governedFieldOverrideForTests;
    @TestVisible
    private static Boolean bypassPermissionOverrideForTests;
    @TestVisible
    private static Boolean stageOverridePermissionOverrideForTests;
    @TestVisible
    private static Set<Id> lockedOverrideIdsForTests;

    /**
     * @description Field API names configured via Locked_Opportunity_Field__mdt that
     * failed describe validation on the most recent call to enforceFieldLocks (e.g. a
     * field that was deleted or renamed after the metadata record was created).
     * Exposed for logging/monitoring and test assertions.
     */
    @TestVisible
    private static List<String> lastInvalidFieldNames = new List<String>();

    /**
     * @description Entry point for the Opportunity before-update trigger context.
     * @param newList Trigger.new
     * @param oldMap Trigger.oldMap
     */
    public static void enforceFieldLocks(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (newList == null || newList.isEmpty() || oldMap == null) {
            return;
        }

        Map<String, String> governedFieldLabelsByName = resolveGovernedFields();
        if (governedFieldLabelsByName.isEmpty()) {
            return;
        }

        Boolean hasBypassPermission = resolveBypassPermission();
        Boolean hasStageOverridePermission = resolveStageOverridePermission();

        for (Opportunity newOpp : newList) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            if (oldOpp == null || !isSubjectToFieldLock(newOpp)) {
                continue;
            }

            if (hasOverrideAccess(newOpp, hasBypassPermission, hasStageOverridePermission)) {
                continue;
            }

            if (isEnteringBookingVerification(oldOpp, newOpp)) {
                continue;
            }

            List<String> changedFieldLabels = getChangedFieldLabels(oldOpp, newOpp, governedFieldLabelsByName);
            if (!changedFieldLabels.isEmpty()) {
                newOpp.addError(LOCK_ERROR_MESSAGE);
            }
        }
    }

    /**
     * @description Whether this record is currently gated by the field lock. Reads the
     * Opportunity_Fields_Locked__c formula field directly in production; test runs may
     * substitute a deterministic override via lockedOverrideIdsForTests since a formula
     * field's value can't be set directly via DML — a test would otherwise need to
     * insert/update records with the exact RecordType and StageName combination from
     * the Section 6.4 formula just to exercise this branch.
     */
    private static Boolean isSubjectToFieldLock(Opportunity opp) {
        if (Test.isRunningTest() && lockedOverrideIdsForTests != null) {
            return lockedOverrideIdsForTests.contains(opp.Id);
        }
        return opp.Opportunity_Fields_Locked__c == true;
    }

    /**
     * @description Determines whether the running user may bypass the field lock for
     * this specific record.
     */
    private static Boolean hasOverrideAccess(
        Opportunity opp,
        Boolean hasBypassPermission,
        Boolean hasStageOverridePermission
    ) {
        Boolean stageEligibleForOverride =
            opp.StageName == BOOKING_VERIFICATION_STAGE || opp.StageName == BOOKED_STAGE;
        return (hasStageOverridePermission && stageEligibleForOverride) || hasBypassPermission;
    }

    /**
     * @description True when StageName is changing into "Booking Verification" on this
     * transaction, allowing the seller's incoming values to persist unchecked.
     */
    private static Boolean isEnteringBookingVerification(Opportunity oldOpp, Opportunity newOpp) {
        return oldOpp.StageName != BOOKING_VERIFICATION_STAGE
            && newOpp.StageName == BOOKING_VERIFICATION_STAGE;
    }

    /**
     * @description Compares each governed field's old vs. new value and returns the
     * labels of any that changed.
     */
    private static List<String> getChangedFieldLabels(
        Opportunity oldOpp,
        Opportunity newOpp,
        Map<String, String> governedFieldLabelsByName
    ) {
        List<String> changedLabels = new List<String>();
        for (String fieldApiName : governedFieldLabelsByName.keySet()) {
            Object oldValue = oldOpp.get(fieldApiName);
            Object newValue = newOpp.get(fieldApiName);
            if (oldValue != newValue) {
                changedLabels.add(governedFieldLabelsByName.get(fieldApiName));
            }
        }
        return changedLabels;
    }

    /**
     * @description Reads active Locked_Opportunity_Field__mdt records (via getAll() —
     * no SOQL, per platform guidance for Custom Metadata Types) and validates each
     * configured field API name actually exists on Opportunity via describe. A field
     * that was deleted or renamed since the metadata record was created is skipped and
     * recorded in lastInvalidFieldNames rather than throwing an unhandled exception.
     * @return Map of valid, governed field API name -> field label
     */
    private static Map<String, String> resolveGovernedFields() {
        if (Test.isRunningTest() && governedFieldOverrideForTests != null) {
            return governedFieldOverrideForTests;
        }

        Map<String, Schema.SObjectField> oppFieldsByName = Schema.SObjectType.Opportunity.fields.getMap();
        Map<String, String> labelsByFieldName = new Map<String, String>();
        lastInvalidFieldNames = new List<String>();

        for (Locked_Opportunity_Field__mdt config : Locked_Opportunity_Field__mdt.getAll().values()) {
            if (config.Active__c != true || String.isBlank(config.Field_API_Name__c)) {
                continue;
            }

            String fieldApiName = config.Field_API_Name__c.trim();
            Schema.SObjectField fieldToken = oppFieldsByName.get(fieldApiName.toLowerCase());

            if (fieldToken == null) {
                lastInvalidFieldNames.add(fieldApiName);
                continue;
            }

            labelsByFieldName.put(fieldApiName, fieldToken.getDescribe().getLabel());
        }

        return labelsByFieldName;
    }

    private static Boolean resolveBypassPermission() {
        if (Test.isRunningTest() && bypassPermissionOverrideForTests != null) {
            return bypassPermissionOverrideForTests;
        }
        return FeatureManagement.checkPermission(BYPASS_PERMISSION);
    }

    private static Boolean resolveStageOverridePermission() {
        if (Test.isRunningTest() && stageOverridePermissionOverrideForTests != null) {
            return stageOverridePermissionOverrideForTests;
        }
        return FeatureManagement.checkPermission(STAGE_OVERRIDE_PERMISSION);
    }
}