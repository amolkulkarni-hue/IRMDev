/**
Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
4/11/2025 - Roopesh Lakshmanan - Enhanced country picker for community site. - GitLab #29391 , #32538


 * A basic controller for fetching NavigationMenuItems.
 */
global with sharing class NF_HeaderController{
    public static String networkId = Test.isRunningTest()
        ? [SELECT NetworkId FROM NetworkMember WHERE Network.Status = 'Live' LIMIT 1][0].NetworkId
        : Network.getNetworkId();

    /**
     * Performs SOQL query to determine all the children NavigationLinkSet based on the provided menu name.
     * Then uses ConnectApi.NavigationMenu.getCommunityNavigationMenu API to retrieve the NavigationMenuItem's for
     * the navigation menu.
     * See https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_navigation_menu_items.htm
     *
     * NOTE: a 'Datasource' type menu item can cause an error for a non-commerce LWR site that does not have an associated storefront.
     *
     * NavigationLinkSet contains both Draft and Live versions of the NavigationMenuItems.
     * Use the publishedState enumeration to filter between them.
     *
     * The (cacheable=true) on the annotation allows this Apex function to be wired in LWC components.
     *
     * @param linkSetId the menu name (NavigationLinkSet.Id)
     * @param linkSetLabel the menu name (NavigationLinkSet.MasterLabel)
     * @param addHomeMenuItem if true, will include the Home menu item in the data
     * @return the navigation menu items
    */
    @AuraEnabled
    public static List<ConnectApi.NavigationMenuItem> getNavigationMenuItems(
        String linkSetId, String linkSetLabel, Boolean addHomeMenuItem
    ){
        List<ConnectApi.NavigationMenuItem> items = new List<ConnectApi.NavigationMenuItem>();

        // Exclude any types that aren't supported for your navigation menu
        List<ConnectApi.NavigationMenuItemType> menuItemsToSkip = new List<ConnectApi.NavigationMenuItemType>{
            ConnectApi.NavigationMenuItemType.Event,  // not supported in custom component nav menus
            ConnectApi.NavigationMenuItemType.SystemLink // not supported in nav menus
        };

        // Connect API: https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_navigation_menu_items.htm
        ConnectApi.NavigationMenuItemCollection menu = ConnectApi.NavigationMenu.getCommunityNavigationMenu(
            networkId,
            String.isBlank(linkSetId) ? null : linkSetId,
            String.isBlank(linkSetLabel) ? null : getNavigationLinkSetDeveloperName(linkSetLabel),
            ConnectApi.PublishStatus.Live,
            false,
            addHomeMenuItem,
            menuItemsToSkip
        );

        if(menu != null && menu.menuItems != null && !menu.menuItems.isEmpty()){
            items = menu.menuItems;
        }

        return items;
    }

    /**
     * Look up the DeveloperName of the NavigationLinkSet based on the provided
     * MasterLabel (aka menu name) and the NetworkId of the current context.
     *
     * @param navigationLinkSetMasterLabel the menu name (NavigationLinkSet.MasterLabel)
     * @return the navigation linkset DeveloperName
     */
    private static String getNavigationLinkSetDeveloperName(String navigationLinkSetMasterLabel){
        String query = 'SELECT DeveloperName, Id, MasterLabel, NetworkId FROM NavigationLinkSet';
        query += ' WHERE MasterLabel =: navigationLinkSetMasterLabel';
        query += ' AND NetworkId =: networkId LIMIT 1';

        return ((NavigationLinkSet)Database.query(query)[0]).DeveloperName;
    }

    @AuraEnabled
    public static Map<String, Object> getNetworkAndUserDetails(String languageCodes){
        Set<String> languages = new Set<String>((List<String>)JSON.deserialize(languageCodes, Type.forName('List<String>')));
        List<Map<String, String>> finalLanguages = new List<Map<String, String>>();

        for(Schema.PicklistEntry eachEntry : User.LanguageLocaleKey.getDescribe().getPicklistValues()){
            if(eachEntry.isActive() && languages.contains(eachEntry.getValue())){
                finalLanguages.add(new Map<String, String>{
                    'code' => eachEntry.getValue().replace('_', '-'), 'label' => eachEntry.getLabel()
                });
            }
        }

        return new Map<String, Object>{
            'selectedLanguage' => UserInfo.getLanguage(),
            'userFirstName' => UserInfo.getFirstName(),
            'isSelfRegistrationEnabled' => Site.isRegistrationEnabled(),
            'finalLanguages' => finalLanguages.isEmpty() ? null : finalLanguages,
            'heroConfigs' => getHeroConfigs()
        };
    }

    @AuraEnabled
    public static Boolean setUserLanguage(String selectedLanguage){
        Boolean isError = true;

        try{
            String currentLanguage = UserInfo.getLanguage();
            Set<String> availableLanguages = new Set<String>();
            String languageToUpdate;

            for(Schema.PicklistEntry eachEntry : User.LanguageLocaleKey.getDescribe().getPicklistValues()){
                if(eachEntry.isActive()){
                    availableLanguages.add(eachEntry.getValue());
                }
            }
            
            // Get field describe
                Schema.DescribeFieldResult localeFieldDescribe = Schema.User.LocaleSidKey.getDescribe();

                // Get all picklist entries
                List<Schema.PicklistEntry> localeValues = localeFieldDescribe.getPicklistValues();

                // Loop and print
                for (Schema.PicklistEntry entry : localeValues) {
                    System.debug('Label: ' + entry.getLabel() + ' | Value: ' + entry.getValue());
                }

            //system.debug('availableLanguages...' + availableLanguages);
            //system.debug('selectedLanguage...' + selectedLanguage);

            if(availableLanguages.contains(selectedLanguage)){
                languageToUpdate = selectedLanguage;
            }
            else if(selectedLanguage.length() == 5){
                String twoCharCode = selectedLanguage.substring(0, 2);

                if(availableLanguages.contains(twoCharCode)){
                    languageToUpdate = selectedLanguage.substring(0, 2);
                }
                else{
                    for(String eachAvailableLanguage : availableLanguages){
                        if(eachAvailableLanguage.startsWith(twoCharCode)){
                            languageToUpdate = twoCharCode;
                            break;
                        }
                    }
                }
            }

            if(String.isNotBlank(languageToUpdate)){
                if(currentLanguage != languageToUpdate){
                    update new User(Id = UserInfo.getUserId(), LanguageLocaleKey = languageToUpdate , LocaleSidKey = languageToUpdate);
                    isError = false;
                }
                else{
                    isError = false;
                }
            }
        }
        catch(Exception ex){
            System.debug(LOGGINGLEVEL.DEBUG, ex.getMessage());
        }

        return isError;
    }
    // Gitlab #29391,32538 - enhanced country picker for community site.
    @AuraEnabled(cacheable=true)
    public static List<Community_Site_Configuration__mdt> getCommunityActiveCountryConfigs(){
        return [SELECT Config_Values__c FROM Community_Site_Configuration__mdt WHERE Functionality_Type__c = 'Country Picker' LIMIT 1];
    }

    private static List<EEC_Custom_Header_Hero_Config__mdt> getHeroConfigs(){
        try{
            String networkName = [SELECT Name FROM Network WHERE Id =: networkId LIMIT 1].Name;

            return [
                SELECT Display_Hero_Section__c, Display_Search__c, Search_Title__c, Search_Subtitle__c,
                Search_Placeholder__c, Page_API_Names__c, Object_List_View_Page_URLs__c,
                Object_Related_List_Page_URLs__c, Record_Detail_Page_URLs__c
                FROM EEC_Custom_Header_Hero_Config__mdt
                WHERE Network_Community_Name__c =: networkName
                AND Is_Active__c = true
            ];
        }
        catch(Exception ex){
            return new List<EEC_Custom_Header_Hero_Config__mdt>();
        }
    }
}