/**
 * @description Blocks a Case from being saved with Status = "Closed - Approved" unless
 * its linked Case_Detail__c child has every field the Case's Type requires populated.
 */
public with sharing class IRM_CaseClosureFieldValidator {

    private static final String DEAL_SUPPORT_RECORD_TYPE_DEV_NAME = 'Deal_Support';
    private static final String CLOSED_APPROVED_STATUS = 'Closed - Approved';
    private static final String BOOKING_VERIFICATION_TYPE = 'Booking Verification';

    
    @TestVisible
    private static final Map<String, List<String>> TYPE_TO_REQUIRED_FIELDS = new Map<String, List<String>>{
        'RFP / Bid Management' => new List<String>{
            'BM_Request_Type__c', 'BM_Due_Date__c', 'BM_Portal_Login_Required__c', 'BM_Submission_Method__c'
        },
        'Remarketing' => new List<String>{
            'RMKT_Asset_Type__c', 'RMKT_Nature_Of_Request__c', 'RMKT_Condition_Notes__c', 'RMKT_Due_Date__c',
            'RMKT_Request_Type__c', 'RMKT_Take_Out_Time_Frame__c', 'RMKT_Revenue_Share_Percentage__c',
            'RMKT_Data_Destruction_Req__c'
        },
        'Solution Architects' => new List<String>{
            'SA_Asset_Type__c', 'SA_SOW_Request_Type__c', 'SA_Recurring_Shred__c', 'SA_Demo_Provided__c',
            'SA_DXP_Demo_Needed__c', 'SA_Target_Start_Date__c', 'SA_Financial_Incentives__c',
            'SA_Customers_Business_Objectives__c', 'SA_Expected_Outcome__c', 'SA_IRMs_Unique_Value__c',
            'SA_RFx__c', 'SA_RFP_Due_Date__c', 'SA_Preferred_Cloud_Provider__c', 'SA_Demo_Support_Type__c',
            'SA_DXP_Areas_Of_Interest__c', 'SA_Document_Types__c', 'SA_AI_Usage__c',
            'SA_Integration_Requirements__c', 'SA_Data_Migration_Needed__c', 'SA_Migration_Platforms__c',
            'SA_Migration_Volume__c', 'SA_Regulated_Processes__c', 'SA_Solution_Processes__c',
            'SA_Technical_Maturity__c', 'SA_IT_Involvement_Level__c', 'SA_Paper_Type__c', 'SA_Site_Details__c',
            'SA_Climate_Control_Required__c', 'SA_Media_Format__c', 'SA_Vault_Requirement__c',
            'SA_Restoration_Needed__c', 'SA_Current_Storage_Environment__c', 'SA_Storage_Type__c',
            'SA_Facility_Capacity_Status__c'
        },
        'Deal Desk' => new List<String>{
            'DD_Request_Type__c', 'DD_Request_Sub_Type__c', 'DD_Request_Reason__c', 'DD_Proposed_Discount_Pct__c',
            'DD_Unit_Price_Override__c', 'DD_Incentives_Included__c', 'DD_Labor_Cost_Override__c',
            'DD_Dedicated_Capital__c', 'DD_Net_New_Revenue__c', 'DD_Revenue_Delta__c',
            'DD_Floor_Revenue_Realization__c'
        },
        'InfoSec / Security Questionnaire' => new List<String>{
            'INFOSEC_Due_Date__c', 'INFOSEC_Customer_Audits__c', 'INFOSEC_Facility_Cert_Required__c',
            'INFOSEC_Data_Risk_Level__c', 'INFOSEC_Security_Risk_Level__c', 'INFOSEC_Data_Residency__c',
            'INFOSEC_Data_Types_In_Scope__c', 'INFOSEC_Compliance_Certs_Required__c',
            'INFOSEC_Mitigation_Required__c', 'INFOSEC_Trust_Center_Access_Granted__c'
        },
        'Revenue Management' => new List<String>{
            'REVMGMT_Request_Type__c', 'REVMGMT_Request_Reason__c', 'REVMGMT_Proposed_Discount_Pct__c',
            'REVMGMT_Unit_Price_Override__c', 'REVMGMT_Incentives_Included__c', 'REVMGMT_Labor_Cost_Override__c',
            'REVMGMT_Dedicated_Capital__c', 'REVMGMT_Net_New_Revenue__c', 'REVMGMT_Revenue_Delta__c',
            'REVMGMT_Floor_Revenue_Realization__c'
        },
        'GCCS' => new List<String>{ 'GCCS_Request_Type__c' },
        'Legal Review' => new List<String>{
            'LEGAL_Request_Type__c', 'LEGAL_Request_Sub_Type__c', 'LEGAL_External_Counsel_Required__c',
            'LEGAL_Revenue_Type__c', 'LEGAL_Date_Needed__c'
        },
        'Managed Services Program' => new List<String>{ 'MSP_Request_Type__c' }
    };

    /**
     * @description Entry point for the Case before-update trigger context.
     * @param newList Trigger.new
     * @param oldMap Trigger.oldMap (unused today — this checks the record's state as it
     * will be saved, matching a validation rule's own semantics of firing on every save
     * where the condition matches, not just the transition into it)
     */
    public static void validateRequiredFieldsBeforeClosure(List<Case> newList, Map<Id, Case> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Id dealSupportRecordTypeId = getDealSupportRecordTypeId();
        if (dealSupportRecordTypeId == null) return; // Record Type not found — nothing to validate against

        Map<Id, Case> casesToCheck = new Map<Id, Case>();
        for (Case c : newList) {
            if (c.RecordTypeId == dealSupportRecordTypeId && c.Status == CLOSED_APPROVED_STATUS) {
                casesToCheck.put(c.Id, c);
            }
        }
        if (casesToCheck.isEmpty()) return;

        Map<Id, Case_Detail__c> detailByCaseId = queryCaseDetails(casesToCheck.keySet());
        Map<String, Schema.SObjectField> detailFieldMap = Schema.SObjectType.Case_Detail__c.fields.getMap();

        for (Case c : casesToCheck.values()) {
            String caseType = c.Type;
            Boolean isGovernedType = TYPE_TO_REQUIRED_FIELDS.containsKey(caseType) || caseType == BOOKING_VERIFICATION_TYPE;
            if (!isGovernedType) continue; // unrecognized/ungoverned Type — no check, matches prior rules' fall-through

            Case_Detail__c detail = detailByCaseId.get(c.Id);
            if (detail == null) {
                // No Case_Detail__c child at all — can't verify completeness, so block
                // rather than silently allow. Should be rare in practice:
                // Case_Detail_Auto_Create_Flow guarantees a child on every Case insert.
                c.addError('This Case has no linked Case Detail record, so required-field completeness cannot be verified. Contact your admin.');
                continue;
            }

            List<String> missingFieldLabels = caseType == BOOKING_VERIFICATION_TYPE
                ? getMissingBookingVerificationFields(detail, detailFieldMap)
                : getMissingFields(detail, detailFieldMap, TYPE_TO_REQUIRED_FIELDS.get(caseType));

            if (!missingFieldLabels.isEmpty()) {
                c.addError(
                    'This Case cannot be closed as Approved until the following ' + caseType +
                    ' field(s) are completed: ' + String.join(missingFieldLabels, ', ')
                );
            }
        }
    }

    private static List<String> getMissingFields(
            Case_Detail__c detail, Map<String, Schema.SObjectField> detailFieldMap, List<String> requiredFields) {
        List<String> missing = new List<String>();
        for (String fieldApiName : requiredFields) {
            // A field not deployed/accessible in this org can't be required — skip it,
            // matching the filter applied in queryCaseDetails (detail.get() on an
            // unqueried field would throw).
            Schema.SObjectField token = detailFieldMap.get(fieldApiName.toLowerCase());
            if (token == null || !token.getDescribe().isAccessible()) continue;
            if (isFieldBlank(detail, fieldApiName)) {
                missing.add(getFieldLabel(detailFieldMap, fieldApiName));
            }
        }
        return missing;
    }

    // Rejection Reasons is only meaningful when BV_Status__c is Reject or Hold Pending
    // Correction — a Passed Case legitimately has neither reasons nor a need for them.
    private static List<String> getMissingBookingVerificationFields(
            Case_Detail__c detail, Map<String, Schema.SObjectField> detailFieldMap) {
        List<String> missing = new List<String>();
        if (isFieldBlank(detail, 'BV_Status__c')) {
            missing.add(getFieldLabel(detailFieldMap, 'BV_Status__c'));
            return missing; // Status itself missing — Rejection Reasons check is moot
        }
        String status = (String) detail.get('BV_Status__c');
        Boolean requiresRejectionReasons = (status == 'Reject' || status == 'Hold Pending Correction');
        if (requiresRejectionReasons && isFieldBlank(detail, 'BV_Rejection_Reasons__c')) {
            missing.add(getFieldLabel(detailFieldMap, 'BV_Rejection_Reasons__c'));
        }
        return missing;
    }

    // Blank check that behaves correctly across every field type used here (Picklist,
    // MultiSelectPicklist, Text/TextArea, Currency, Percent, Date, Lookup) — unlike a
    // formula's ISBLANK(TEXT(...)), Apex needs no per-type wrapping restrictions at all,
    // which is what made several of the retired Case_Detail__c rules fail to compile in
    // the first place (TEXT() rejects TextArea and MultiSelectPicklist fields outright).
    private static Boolean isFieldBlank(Case_Detail__c detail, String fieldApiName) {
        Object value = detail.get(fieldApiName);
        if (value == null) return true;
        if (value instanceof String) return String.isBlank((String) value);
        return false;
    }

    private static String getFieldLabel(Map<String, Schema.SObjectField> fieldMap, String fieldApiName) {
        Schema.SObjectField token = fieldMap.get(fieldApiName.toLowerCase());
        return token == null ? fieldApiName : token.getDescribe().getLabel();
    }

    @TestVisible
    private static Id getDealSupportRecordTypeId() {
        Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName().get(DEAL_SUPPORT_RECORD_TYPE_DEV_NAME);
        return (rtInfo == null || !rtInfo.isActive()) ? null : rtInfo.getRecordTypeId();
    }

    // One bulk query for every Case being checked, selecting only the fields actually
    // referenced across TYPE_TO_REQUIRED_FIELDS plus the two Booking Verification fields
    // — not every field on Case_Detail__c. Because the SOQL is dynamic, fields listed in
    // the map but not yet deployed to this org must be filtered out here: including one
    // throws a QueryException that blocks every Case close in the trigger.
    private static Map<Id, Case_Detail__c> queryCaseDetails(Set<Id> caseIds) {
        Map<String, Schema.SObjectField> detailFieldMap = Schema.SObjectType.Case_Detail__c.fields.getMap();
        Set<String> allFields = new Set<String>{ 'Id', 'Case__c', 'BV_Status__c', 'BV_Rejection_Reasons__c' };
        for (List<String> fields : TYPE_TO_REQUIRED_FIELDS.values()) {
            allFields.addAll(fields);
        }
        List<String> queryableFields = new List<String>();
        for (String fieldApiName : allFields) {
            Schema.SObjectField token = detailFieldMap.get(fieldApiName.toLowerCase());
            // containsKey alone is not enough: fields in a half-deployed/deleted state can
            // still appear in the describe map while the SOQL parser rejects them.
            // isAccessible() matches what the query layer will actually accept.
            if (token != null && token.getDescribe().isAccessible()) {
                queryableFields.add(fieldApiName);
            }
        }

        String soql = 'SELECT ' + String.join(queryableFields, ', ')
            + ' FROM Case_Detail__c WHERE Case__c IN :caseIds';
        Map<Id, Case_Detail__c> result = new Map<Id, Case_Detail__c>();
        for (Case_Detail__c cd : (List<Case_Detail__c>) Database.query(soql)) {
            result.put(cd.Case__c, cd);
        }
        return result;
    }
}