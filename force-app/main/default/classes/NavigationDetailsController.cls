/**
 * @description       : Controller class for nfCommunityFooter LWC
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 11-29-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public without sharing class NavigationDetailsController{
    public static List<NavigationMenuItem> testClassNavs = new List<NavigationMenuItem>();
    public static List<MainNavigationItem> topicsAsNavigationalItems =
        getTopicsAsNavigationalItems();
    public static Set<String> restrictedTypes = new  Set<String>{'Event'};

    /**
    * @description Returns the Navigation Items(both main and social) to be displayed
    * @author chayan.batabyal@neuraflash.com | 09-15-2022
    * @param navigationMenuId
    * @param socialNavigationMenuName
    * @return NavigationDetails
    **/
    @AuraEnabled
    public static NavigationDetails getBothNavigationsToDisplay(String navigationMenuId, String socialNavigationMenuName){
        NavigationDetails responseToSend = new NavigationDetails();

        if(String.isNotBlank(navigationMenuId)){
            responseToSend.mainNavigationItems = new List<MainNavigationItem>();
            getMainNavigationMenuToDisplay(navigationMenuId, responseToSend);
        }

        if(String.isNotBlank(socialNavigationMenuName)){
            responseToSend.socialNavigationItems = new List<SocialNavigationItem>();
            getSocialNavigationMenuToDisplay(socialNavigationMenuName, responseToSend);
        }

        return responseToSend;
    }

    /**
    * @description Returns the Navigation Items(main, social and base) to be displayed
    * @author chayan.batabyal@neuraflash.com | 11-17-2022
    * @param navigationMenuId
    * @param socialNavigationMenuName
    * @param baseNavigationMenuId
    * @return NavigationDetails
    **/
    @AuraEnabled
    public static NavigationDetails getFooter3NavigationsToDisplay(
        String navigationMenuId, String socialNavigationMenuName, String baseNavigationMenuId
    ){
        NavigationDetails responseToSend = new NavigationDetails();

        if(String.isNotBlank(navigationMenuId)){
            responseToSend.mainNavigationItems = new List<MainNavigationItem>();
            getMainNavigationMenuToDisplay(navigationMenuId, responseToSend);
        }

        if(String.isNotBlank(socialNavigationMenuName)){
            responseToSend.socialNavigationItems = new List<SocialNavigationItem>();
            getSocialNavigationMenuToDisplay(socialNavigationMenuName, responseToSend);
        }

        if(String.isNotBlank(baseNavigationMenuId)){
            responseToSend.baseNavigationItems = new List<BaseNavigationItem>();
            getBaseNavigationMenuToDisplay(baseNavigationMenuId, responseToSend);
        }

        return responseToSend;
    }

    /**
    * @description Returns the Main Navigation Items to be displayed
    * @author chayan.batabyal@neuraflash.com | 06-09-2022
    * @param navigationMenuId
    * @param responseToSend
    **/
    @AuraEnabled
    public static void getMainNavigationMenuToDisplay(String navigationMenuId, NavigationDetails responseToSend){
        try{
            Map<String, List<MainNavigationItem>> navigationMenuItemMap =
                prepareMapOfLinkSetNameToNavs(navigationMenuId, responseToSend, false);

            for(MainNavigationItem eachDetail : responseToSend.mainNavigationItems){
                if(eachDetail.Type == 'NavigationalTopic'){
                    eachDetail.items = topicsAsNavigationalItems;
                }
                else{
                    eachDetail.items = navigationMenuItemMap.get(eachDetail.id);
                }
            }
        }
        catch(Exception e){
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage() + ' at ' + e.getLineNumber());
        }
    }

    /**
    * @description Returns the Base Navigation Items to be displayed
    * @author chayan.batabyal@neuraflash.com | 11-24-2022
    * @param baseNavigationMenuId
    * @param responseToSend
    **/
    @AuraEnabled
    public static void getBaseNavigationMenuToDisplay(String baseNavigationMenuId, NavigationDetails responseToSend){
        try{
            restrictedTypes.add('MenuLabel');
            Map<String, List<MainNavigationItem>> navigationMenuItemMap =
                prepareMapOfLinkSetNameToNavs(baseNavigationMenuId, responseToSend, true);
        }
        catch(Exception e){
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage() + ' at ' + e.getLineNumber());
        }
    }

    /**
    * @description Prepares a map of LinkSet Name to the list of Navigations
    * @author chayan.batabyal@neuraflash.com | 06-13-2022
    * @param navigationMenuId
    * @param responseToSend
    * @param isBaseNavigation
    * @return Map<String, List<MainNavigationItem>>
    **/
    private static Map<String, List<MainNavigationItem>> prepareMapOfLinkSetNameToNavs(
        String navigationMenuId, NavigationDetails responseToSend, Boolean isBaseNavigation
    ){
        Map<String, List<MainNavigationItem>> navigationMenuItemMap =
            new Map<String, List<MainNavigationItem>>();

        List<NavigationMenuItem> navs = [
            SELECT Id, Label, Type, Target, Position, DefaultListViewId, ParentId, TargetPrefs
            FROM NavigationMenuItem
            WHERE Status = 'Live'
            AND Type !=: restrictedTypes
            AND NavigationLinkSetId =: navigationMenuId
            ORDER BY Position
        ];
        navs = Test.isRunningTest() ? testClassNavs : navs;

        for(NavigationMenuItem eachMenuItem : navs){
            MainNavigationItem eachNavigationDetail = new MainNavigationItem(eachMenuItem);

            if(eachMenuItem.Type == 'SalesforceString' || eachMenuItem.Type == 'SalesforceObject'){
                eachNavigationDetail.type = 'InternalLink';
                eachNavigationDetail.urlToOpen = getRelativeURLForString(eachMenuItem);
            }
            else if(eachMenuItem.Type == 'GlobalAction'){
                eachNavigationDetail.type = 'InternalLink';
                eachNavigationDetail.urlToOpen = '/createrecord/' + eachMenuItem.Target;
            }

            if(isBaseNavigation){
                responseToSend.baseNavigationItems.add((BaseNavigationItem)JSON.deserialize(
                    JSON.serialize(eachNavigationDetail), NavigationDetailsController.BaseNavigationItem.class
                ));
            }
            else if(String.isBlank(eachMenuItem.ParentId)){
                responseToSend.mainNavigationItems.add(eachNavigationDetail);
            }
            else{
                if(!navigationMenuItemMap.containsKey(eachMenuItem.ParentId)){
                    navigationMenuItemMap.put(
                        eachMenuItem.ParentId,
                        new List<MainNavigationItem>{eachNavigationDetail}
                    );
                }
                else{
                    navigationMenuItemMap.get(eachMenuItem.ParentId).add(eachNavigationDetail);
                }
            }
        }

        return navigationMenuItemMap;
    }

    /**
    * @description Creates and returns the relative url for community navigation
    * @author chayan.batabyal@neuraflash.com | 05-20-2022
    * @param eachMenuItem
    * @return String
    **/
    @TestVisible
    private static String getRelativeURLForString(NavigationMenuItem eachMenuItem){
        String url;
        String defaultListViewId = ('/' + eachMenuItem.DefaultListViewId).replace('/null', '');

        if(eachMenuItem.Target.indexOf('__') != -1){
            url = '/recordlist/' + eachMenuItem.Target + defaultListViewId;
        }
        else{
            url = '/' + eachMenuItem.Target.toLowerCase() + '/' +
                eachMenuItem.Target + defaultListViewId;
        }

        return url;
    }

    /**
    * @description Returns the Social Navigation Items to be displayed
    * @author chayan.batabyal@neuraflash.com | 05-20-2022
    * @param socialNavigationMenuName
    * @param responseToSend
    **/
    @AuraEnabled
    public static void getSocialNavigationMenuToDisplay(
        String socialNavigationMenuName, NavigationDetails responseToSend
    ){
        try{
            for(EEC_Social_Navigation__mdt eachSocialMenuItem: [
                SELECT Id, Redirection_URL__c, Icon_URL__c, Order__c
                FROM EEC_Social_Navigation__mdt
                WHERE Footer_Config_Name__c =: socialNavigationMenuName
                AND Active__c = true
                ORDER BY Order__c
            ]){
                responseToSend.socialNavigationItems.add(
                    new SocialNavigationItem(eachSocialMenuItem)
                );
            }
        }
        catch(Exception e){
            System.debug(LOGGINGLEVEL.DEBUG, e.getMessage() + ' at ' + e.getLineNumber());
        }
    }

    /**
    * @description Gets the list of topics for the current site
    * @author chayan.batabyal@neuraflash.com | 11-28-2022
    * @return List<MainNavigationItem>
    **/
    private static List<MainNavigationItem> getTopicsAsNavigationalItems(){
        List<MainNavigationItem> navTopics =
            new List<MainNavigationItem>();

        for(Topic eachTopic : [
            SELECT Id, Name FROM Topic
            WHERE NetworkId =: Network.getNetworkId()
            AND ManagedTopicType LIKE '%Navigational%'
        ]){
            navTopics.add(new MainNavigationItem(eachTopic));
        }

        return navTopics;
    }

    public class NavigationDetails{
        @AuraEnabled public List<MainNavigationItem> mainNavigationItems;
        @AuraEnabled public List<SocialNavigationItem> socialNavigationItems;
        @AuraEnabled public List<BaseNavigationItem> baseNavigationItems;
    }

    public class MainNavigationItem{
        @AuraEnabled public String id;
        @AuraEnabled public String type;
        @AuraEnabled public String urlToOpen;
        @AuraEnabled public String label;
        @AuraEnabled public String targetPrefs;
        @AuraEnabled public List<MainNavigationItem> items;

        public MainNavigationItem(NavigationMenuItem eachMenuItem){
            this.id = eachMenuItem.Id;
            this.type = eachMenuItem.Type;
            this.urlToOpen = eachMenuItem.Type == 'NavigationalTopic' ? '' : eachMenuItem.Target;
            this.targetPrefs = eachMenuItem.TargetPrefs;
            this.label = eachMenuItem.Label.startsWith('$_') ? eachMenuItem.Label.replace('$_', '') : eachMenuItem.Label;
        }

        public MainNavigationItem(Topic eachTopic){
            this.id = eachTopic.Id;
            this.type = 'InternalLink';
            this.urlToOpen = '/topic/'+ eachTopic.Id;
            this.targetPrefs = '';
            this.label = eachTopic.Name;
        }
    }

    public class SocialNavigationItem{
        @AuraEnabled public String id;
        @AuraEnabled public String urlToOpen;
        @AuraEnabled public String iconURL;

        public SocialNavigationItem(EEC_Social_Navigation__mdt eachSocialMenuItem){
            this.id = eachSocialMenuItem.Id;
            this.urlToOpen = eachSocialMenuItem.Redirection_URL__c;
            this.iconURL = eachSocialMenuItem.Icon_URL__c;
        }
    }

    public class BaseNavigationItem{
        @AuraEnabled public String id;
        @AuraEnabled public String type;
        @AuraEnabled public String urlToOpen;
        @AuraEnabled public String label;
    }
}