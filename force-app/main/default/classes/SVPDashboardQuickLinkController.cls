public with sharing class SVPDashboardQuickLinkController
{
    public List<DashboardLink> dashboardLinks
    {
        get
        {
            if( dashboardLinks == null )
            {
                dashboardLinks = new List<DashboardLink>();
                for( SVP_Dashboard_Quicklink__c quickLink : SVP_Dashboard_Quicklink__c.getAll().values() )
                {
                    dashboardLinks.add( new DashboardLink( quickLink.Name, quickLink.Dashboard_ID__c ) );
                }
            }
            return dashboardLinks;
        }
        set;
    }

    public SVPDashboardQuickLinkController(){ }

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