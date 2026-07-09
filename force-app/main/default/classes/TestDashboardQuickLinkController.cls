@isTest
private class TestDashboardQuickLinkController
{
    static final String CANADA_OP_NAME = 'SVP - Canada Operations';
    static final String CANADA_OP_ID = '01ZQ00000008q2P';

    static final String EASTERN_OP_NAME = 'SVP - Eastern Operations';
    static final String EASTERN_OP_ID = '01ZQ00000008q2A';

    static final String MAIN_DASHBOARD_ID = '01ZQ00000008q2F';
    static final String MAIN_DASHBOARD_ID_CS = '01ZQ00000008q2f';
    
    static Dashboard_Quick_Links__c canadaOpQuickLink;
    static Dashboard_Quick_Links__c easternOpQuickLink;

    static void setup()
    {
        canadaOpQuickLink = TestingUtils.createDashboardQuickLink( '1', CANADA_OP_ID, CANADA_OP_NAME, MAIN_DASHBOARD_ID, false );
        easternOpQuickLink = TestingUtils.createDashboardQuickLink( '2', EASTERN_OP_ID, CANADA_OP_NAME, MAIN_DASHBOARD_ID, false );

        System.runAs( TestingUtils.ADMIN_USER )
        {
            insert new List<Dashboard_Quick_Links__c>{ canadaOpQuickLink, easternOpQuickLink };
        }

    }

    static testMethod void testDashboardQuickLinkController_ExistingMainDashboard()
    {
        setup();

        Test.startTest();

            DashboardQuickLinkController controller = new DashboardQuickLinkController();
            controller.currentDashboardId = MAIN_DASHBOARD_ID;
            controller.generateDBLinks();

        Test.stopTest();

        Set<String> expectedDBNames = new Set<String>{ CANADA_OP_NAME, EASTERN_OP_NAME };
        Set<String> expectedDBIds = new Set<String>{ CANADA_OP_ID, EASTERN_OP_ID };

        System.assertEquals( 2, controller.dashboardLinks.size(), 'There should be same number of Dashboard Links as custom setting.' );
        for( DashboardQuickLinkController.DashboardLink dbLink : controller.dashboardLinks )
        {
            System.assert( expectedDBNames.contains( dbLink.dashboardName ), 'The dashboardName should be set to the Name in custom setting' );
            System.assert( expectedDBIds.contains( dbLink.dashboardId ), 'The dashboardId should be set to the Dashboard_ID__c in custom setting' );
        }
    }
    
    static testMethod void testDashboardQuickLinkController_ExistingMainDashboardCaseSensitivity()
    {
        setup();
        
        canadaOpQuickLink.Current_Dashboard_ID__c = MAIN_DASHBOARD_ID_CS;
        update canadaOpQuickLink;

        Test.startTest();

            DashboardQuickLinkController controller = new DashboardQuickLinkController();
            controller.currentDashboardId = MAIN_DASHBOARD_ID;
            controller.generateDBLinks();

        Test.stopTest();

        System.assertEquals( 1, controller.dashboardLinks.size(), 
        					'There should be only one Dashboard Link created based on the case of the main dashoboard ID' );
    }

    static testMethod void testDashboardQuickLinkController_NullMainDashboard()
    {
        setup();

        Test.startTest();

            DashboardQuickLinkController controller = new DashboardQuickLinkController();
            controller.currentDashboardId = null;
            controller.generateDBLinks();

        Test.stopTest();

        System.assert( controller.dashboardLinks.isEmpty(), 'There should be no Dashboard Links' );
    }
}