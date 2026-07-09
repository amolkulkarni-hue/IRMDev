public class ProjectQuickActionController {
    @AuraEnabled(cacheable=true)
    public static List<Schedule_A_Quote_Item__c> getScheduleAQuoteItems(Id projectId) {
        pse__Proj__c project = [
            SELECT Deal_Review__c, Deal_Review__r.Schedule_A__c
            FROM pse__Proj__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        if (
            project.Deal_Review__c != null &&
            project.Deal_Review__r.Schedule_A__c != null
        ) {
            return [
                SELECT Id,Name,Product_Name__c, Product_Number__c, Unit_of_Measure__c,
                    Cashview_Cost_Line__c, Cashview_Margin_Line__c, XML_Proposed_Volume__c,
                    Proposed_Price__c, Target_Price__c, Floor_Price__c,
                    Current_Price__c, Current_Volume__c, Line_Revenue__c
                FROM Schedule_A_Quote_Item__c
                WHERE XML_Proposed_Volume__c > 0 AND Schedule_A__c = :project.Deal_Review__r.Schedule_A__c
            ];
        }
        return new List<Schedule_A_Quote_Item__c>();
    }
}