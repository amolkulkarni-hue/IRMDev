/**
 * @description       : Test class for NavigationDetailsController
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 11-24-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@isTest(seeAllData = false)
public class NavigationDetailsControllerTest {
    /**
    * @description Tests the retrieval of the navigation menu items
    * @author chayan.batabyal@neuraflash.com | 09-15-2022
    **/
    @Istest
    private static void getNavigationsToDisplayTest(){
        Test.startTest();

        String currentUserId = UserInfo.getUserId();
        List<NavigationMenuItem> navs = new List<NavigationMenuItem>();
        NavigationLinkSet defaultLS = [
            SELECT Id FROM NavigationLinkSet
            WHERE DeveloperName = 'Default_Navigation'
        ];

        Map<String, Object> nav1Map = new Map<String, Object>{
            'Label' => 'Level 0 Item',
            'Type' => 'MenuLabel',
            'NavigationLinkSetId' => defaultLS.Id,
            'Id' => currentUserId
        };
        NavigationMenuItem nav1 = (NavigationMenuItem)JSON.deserialize(
            JSON.serialize(nav1Map), NavigationMenuItem.class
        );
        navs.add(nav1);

        NavigationMenuItem nav11 = new NavigationMenuItem();
        nav11.Label = 'Level 0 Item 1';
        nav11.Target = 'Test__Test';
        nav11.Type = 'SalesforceString';
        nav11.DefaultListViewId = currentUserId;
        nav11.NavigationLinkSetId = defaultLS.Id;
        nav11.ParentId = currentUserId;
        navs.add(nav11);

        NavigationMenuItem nav12 = new NavigationMenuItem();
        nav12.Label = 'Level 0 Item 2';
        nav12.Target = 'Test';
        nav12.Type = 'SalesforceString';
        nav12.DefaultListViewId = currentUserId;
        nav12.NavigationLinkSetId = defaultLS.Id;
        nav12.ParentId = currentUserId;
        navs.add(nav12);

        NavigationMenuItem nav13 = new NavigationMenuItem();
        nav13.Label = 'Level 0 Item 2';
        nav13.Target = 'Test';
        nav13.Type = 'GlobalAction';
        nav13.NavigationLinkSetId = defaultLS.Id;
        nav13.ParentId = currentUserId;
        navs.add(nav13);

        List<EEC_Social_Navigation__mdt> socialMD = [
            SELECT Footer_Config_Name__c
            FROM EEC_Social_Navigation__mdt
            WHERE Active__c = true
            LIMIT 1
        ];

        NavigationDetailsController.testClassNavs = navs;
        NavigationDetailsController.NavigationDetails response =
            NavigationDetailsController.getBothNavigationsToDisplay(
                defaultLS.Id,
                !socialMD.isEmpty() ? socialMD[0].Footer_Config_Name__c : null
            );
        System.assert(response.mainNavigationItems[0].items.size() == 3, '1st item has 3 sub-items');

        response =
            NavigationDetailsController.getFooter3NavigationsToDisplay(
                defaultLS.Id,
                !socialMD.isEmpty() ? socialMD[0].Footer_Config_Name__c : null,
                defaultLS.Id
            );
        System.assert(!response.baseNavigationItems.isEmpty(), 'Base Navigation is not empty');

        Test.stopTest();
    }
}