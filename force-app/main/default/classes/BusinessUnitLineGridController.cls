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

    @AuraEnabled
    public static void createLine(Id opportunityId, String newLineJson) {
        Opportunity_Product_Line__c newLine = (Opportunity_Product_Line__c) JSON.deserialize(
            newLineJson,
            Opportunity_Product_Line__c.class
        );

        if (String.isBlank(newLine.Business_Unit__c)) {
            throw new AuraHandledException('Business Unit is required.');
        }
        if (newLine.EAA__c != null && newLine.EAA__c < 0) {
            throw new AuraHandledException('Eligible Annual Amount cannot be negative.');
        }

        List<Opportunity_Product_Line__c> existingActive = [
            SELECT Id
            FROM Opportunity_Product_Line__c
            WHERE Opportunity__c = :opportunityId
              AND Business_Unit__c = :newLine.Business_Unit__c
              AND Is_Active__c = true
            LIMIT 1
        ];
        if (!existingActive.isEmpty()) {
            throw new AuraHandledException('This Business Unit already has an active line on this Opportunity.');
        }

        newLine.Opportunity__c = opportunityId;
        newLine.Is_Active__c = true;

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Opportunity_Product_Line__c>{ newLine });
        if (!decision.getModifiedIndexes().isEmpty() || !decision.getRemovedFields().isEmpty()) {
            throw new AuraHandledException('Insufficient privileges to create this record.');
        }

        insert decision.getRecords();
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistOptions() {
        Map<String, List<String>> options = new Map<String, List<String>>();
        options.put('Business_Unit__c', activeValues(Opportunity_Product_Line__c.Business_Unit__c));
        options.put('Product_Family__c', activeValues(Opportunity_Product_Line__c.Product_Family__c));
        options.put('Product_Line__c', activeValues(Opportunity_Product_Line__c.Product_Line__c));
        return options;
    }

    private static List<String> activeValues(Schema.SObjectField field) {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }
}
