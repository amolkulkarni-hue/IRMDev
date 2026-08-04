public with sharing class BusinessUnitLineGridController {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity_Product_Line__c> getActiveLines(Id opportunityId) {
        return [
            SELECT Id, Business_Unit__c, Product_Family__c, Product_Line__c,
                   EAA__c, Is_Primary__c, Is_Active__c
            FROM Opportunity_Product_Line__c
            WHERE Opportunity__c = :opportunityId
              AND Is_Active__c = true
            ORDER BY Business_Unit__c
        ];
    }

    @AuraEnabled
    public static void saveDraftValues(String draftValuesJson) {
        List<Opportunity_Product_Line__c> linesToUpdate = (List<Opportunity_Product_Line__c>) JSON.deserialize(
            draftValuesJson,
            List<Opportunity_Product_Line__c>.class
        );

        for (Opportunity_Product_Line__c line : linesToUpdate) {
            if (line.EAA__c != null && line.EAA__c < 0) {
                throw new AuraHandledException('Eligible Annual Amount cannot be negative.');
            }
        }

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, linesToUpdate);
        if (!decision.getModifiedIndexes().isEmpty() || !decision.getRemovedFields().isEmpty()) {
            throw new AuraHandledException('Insufficient privileges to update one or more fields on this record.');
        }

        update decision.getRecords();
    }
}
