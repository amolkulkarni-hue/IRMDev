public class DashboardQuickLinkController
{
    public String currentDashboardId { get; set; }
    public List<DashboardLink> dashboardLinks { get; set; }

    public void generateDBLinks()
    {
        dashboardLinks = new List<DashboardLink>();
        for( Dashboard_Quick_Links__c quickLink : [ SELECT Id, Link_Label__c, Dashboard_ID__c, Current_Dashboard_ID__c FROM Dashboard_Quick_Links__c ORDER BY Name ASC ] )
        {
            if( quickLink.Current_Dashboard_ID__c.equals(currentDashboardId ))
            {
                dashboardLinks.add( new DashboardLink( quickLink.Link_Label__c, quickLink.Dashboard_ID__c ) );
            }
        }
    }

    public DashboardQuickLinkController() { }

    public class DashboardLink
    {
        public String dashboardName { get; set; }
        public String dashboardId { get; set; }

        public DashboardLink( String dbNameIn, String dbIdIn )
        {
            this.dashboardName = dbNameIn;
            this.dashboardId = dbIdIn;
        }
    }
}