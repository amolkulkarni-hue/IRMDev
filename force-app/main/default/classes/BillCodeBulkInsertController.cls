public class BillCodeBulkInsertController {
    
    @AuraEnabled
    public static void createMilestones(Id projectId, List<Map<String, Object>> records) {
        Database.executeBatch(new BillCodeBulkBatch(projectId, records), 200);
    }

    @AuraEnabled(cacheable=true)
    public static String getProjectNumber(Id projectId) {
        List<pse__Proj__c> projList = [
            SELECT pse__Project_ID__c
            FROM pse__Proj__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        if (projList.isEmpty()) return null;
        return projList[0].pse__Project_ID__c;
    }

    public class BillCodeInfoWrapper {
        @AuraEnabled public List<String> billCodeIds;
        @AuraEnabled public List<String> billingCodes;
        @AuraEnabled public List<String> validCombinations;
        public BillCodeInfoWrapper(List<String> billCodeIds, List<String> billingCodes, List<String> validCombinations) {
            this.billCodeIds = billCodeIds;
            this.billingCodes = billingCodes;
            this.validCombinations = validCombinations;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getCasesForProject(String projectId) {
        if (String.isBlank(projectId)) return new List<Case>();
        return [
            SELECT Id, CaseNumber, Subject, Status, CreatedDate
            FROM Case
            WHERE Subject LIKE :('%' + projectId + '%')
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static BillCodeInfoWrapper getProjectBillCodeIds(Id projectId) {
        String billingType = [
            SELECT pse__Billing_Type__c
            FROM pse__Proj__c
            WHERE Id = :projectId
            LIMIT 1
        ].pse__Billing_Type__c;

        List<pse__Milestone__c> billCodes;
        if (billingType == 'Bundle') {
            billCodes = [
                SELECT BC_ID__c, Billing_Code__c
                FROM pse__Milestone__c
                WHERE pse__Project__c = :projectId
                    AND Bundle_Bill_Code__c = true
                    AND Bill_Code_District_ID__c = NULL
            ];
        } else {
            billCodes = [
                SELECT BC_ID__c, Billing_Code__c
                FROM pse__Milestone__c
                WHERE pse__Project__c = :projectId
                    AND Bill_Code_District_ID__c = NULL
            ];
        }
        List<String> billCodeIds = new List<String>();
        List<String> billingCodes = new List<String>();
        List<String> validCombinations = new List<String>();
        for (pse__Milestone__c bc : billCodes) {
            if (bc.BC_ID__c != null) billCodeIds.add(bc.BC_ID__c);
            if (bc.Billing_Code__c != null) billingCodes.add(bc.Billing_Code__c);
            if (bc.BC_ID__c != null && bc.Billing_Code__c != null) {
                validCombinations.add(bc.BC_ID__c.trim() + '|' + bc.Billing_Code__c.trim());
            }
        }
        return new BillCodeInfoWrapper(billCodeIds, billingCodes, validCombinations);
    }
}