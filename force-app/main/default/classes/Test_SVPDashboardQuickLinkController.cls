@istest(SeeAllData=true)

public class Test_SVPDashboardQuickLinkController {

private static TestMethod void test1(){

    PageReference pageRef = Page.DashboardQuickLink;
   // Test.setCurrentPage(pageRef);
     String name='Test';
     String table='Test1';
    SVPDashboardQuickLinkController controller = new SVPDashboardQuickLinkController();
    SVPDashboardQuickLinkController.DashboardLink  dashboard= new SVPDashboardQuickLinkController.DashboardLink(name,table);

}
}