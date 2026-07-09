public with sharing class NF_IronCustomFooterController {
    @AuraEnabled
    public static List<NavigationMenuItem> getNavigationMenuItems(String linkSetId) {
        List<NavigationMenuItem> items = [
            SELECT Id, Label, NavigationLinkSetId, Target, Position, ParentId, Status, Type, DefaultListViewId
            FROM NavigationMenuItem
            WHERE NavigationLinkSetId = :linkSetId AND Status = 'Live'
            ORDER BY Position
        ];
        return items;
    }

    @AuraEnabled
    public static Map<String, String> getDynamicCustomLabel(String labelsToFetch, String language) {
        Map<String, String> customLabelMap = new Map<String, String>();
        language = String.isNotBlank(language) ? language : 'en_US';

        for (String eachLabelToFetch : labelsToFetch.split(';')) {
            try {
                customLabelMap.put(eachLabelToFetch, LABEL.get(null, eachLabelToFetch, language));
            } catch (Exception ex) {
                customLabelMap.put(eachLabelToFetch, '');
                if (!Test.isRunningTest()) {
                    throw new AuraHandledException(ex.getMessage());
                }
            }
        }

        return customLabelMap;
    }

    @AuraEnabled
    public static List<EEC_Social_Navigation__mdt> getSocialNavigationMenuToDisplay(String socialNavigationMenuName) {
        List<EEC_Social_Navigation__mdt> socialNavigationItems = new List<EEC_Social_Navigation__mdt>();
        try {
            socialNavigationItems = [
                SELECT Id, Redirection_URL__c, Icon_URL__c, Order__c
                FROM EEC_Social_Navigation__mdt
                WHERE Footer_Config_Name__c = :socialNavigationMenuName AND Active__c = TRUE
                ORDER BY Order__c
            ];
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return socialNavigationItems;
    }
}