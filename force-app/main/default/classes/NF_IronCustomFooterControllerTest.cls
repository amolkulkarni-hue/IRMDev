@isTest
public with sharing class NF_IronCustomFooterControllerTest {
    @isTest
    static void getNavigationMenuItemsTest() {
        Test.startTest();

        String currentUserId = UserInfo.getUserId();
        List<NavigationMenuItem> navs = new List<NavigationMenuItem>();
        NavigationLinkSet defaultLS = [
            SELECT Id
            FROM NavigationLinkSet
            WHERE DeveloperName = 'Default_Navigation'
        ];

        Map<String, Object> nav1Map = new Map<String, Object>{ 'Label' => 'Level 0 Item', 'Type' => 'MenuLabel', 'NavigationLinkSetId' => defaultLS.Id, 'Id' => currentUserId };
        NavigationMenuItem nav1 = (NavigationMenuItem) JSON.deserialize(JSON.serialize(nav1Map), NavigationMenuItem.class);
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

        List<NavigationMenuItem> response = NF_IronCustomFooterController.getNavigationMenuItems(defaultLS.Id);
        System.assert(response.size() != 0, 'Nav has items');

        Test.stopTest();
    }

    @isTest
    static void getDynamicCustomLabelTest() {
        Test.startTest();
        Map<String, String> response = NF_IronCustomFooterController.getDynamicCustomLabel('TESTLABEL', 'en_US');
        Assert.isTrue(String.isBlank(response.get('TESTLABEL')), 'Blank value received');
        Test.stopTest();
    }

    @isTest
    static void getSocialNavigationMenuToDisplayTest() {
        Test.startTest();
        List<EEC_Social_Navigation__mdt> response = NF_IronCustomFooterController.getSocialNavigationMenuToDisplay('Default');
        Assert.isTrue(response.size() != 0, 'Non Blank value received');
        Test.stopTest();
    }
}