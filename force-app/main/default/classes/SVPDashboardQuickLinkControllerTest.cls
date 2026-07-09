@isTest
public class SVPDashboardQuickLinkControllerTest {
    @isTest static void testDashboardLinks() {
        // Setup test data
        List<SVP_Dashboard_Quicklink__c> quickLinks = new List<SVP_Dashboard_Quicklink__c>();
        quickLinks.add(new SVP_Dashboard_Quicklink__c(
            Name = 'Test Dashboard 1',
            Dashboard_ID__c = 'DB001'
        ));
        quickLinks.add(new SVP_Dashboard_Quicklink__c(
            Name = 'Test Dashboard 2',
            Dashboard_ID__c = 'DB002'
        ));
        insert quickLinks;
        
        // Instantiate controller
        SVPDashboardQuickLinkController controller = new SVPDashboardQuickLinkController();
        
        // Access dashboardLinks property
        List<SVPDashboardQuickLinkController.DashboardLink> links = controller.dashboardLinks;
        
        // Verify the size of the list matches inserted records
        System.assertEquals(quickLinks.size(), links.size(), 'Dashboard links count should match inserted records');
        
        // Verify the content of the links
        Map<String, String> expectedMap = new Map<String, String>();
        for (SVP_Dashboard_Quicklink__c ql : quickLinks) {
            expectedMap.put(ql.Name, ql.Dashboard_ID__c);
        }
        
        for (SVPDashboardQuickLinkController.DashboardLink dl : links) {
            System.assertEquals(expectedMap.get(dl.dashboardName), dl.dashboardId, 'Dashboard ID should match for ' + dl.dashboardName);
        }
    }
}