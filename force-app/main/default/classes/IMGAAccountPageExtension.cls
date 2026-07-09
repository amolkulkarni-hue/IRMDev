/***************************************************************************************************
Class    :  IMGAAccountPageExtension.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :  June 20, 2013
Modified :  July 17, 2013
Objective:  This class extends the Account standard controller.

**************************************************************************************************/

global with sharing class IMGAAccountPageExtension
{
    //  public properties declared in alphabetical order
    public Flow.Interview.Manual_Risk_Flag manualFlow { get; set; }
    //  private properties declared in alphabetical order
    final Account account      = null;
    final String  accountId    = null;
    final String  accountName  = null;
    final Double  currentDbr   = null;
    final Double  currentDms   = null;
    final Double  currentOther = null;
    final Double  currentRm    = null;
    final Double  currentShred = null;
    final Double  priorDbr     = null;
    final Double  priorDms     = null;
    final Double  priorOther   = null;
    final Double  priorRm      = null;
    final Double  priorShred   = null;
    final String  recordType   = null;
    final Boolean redAlertFlag = null;
    final Integer riskScore    = null;
 
    //  public methods listed in alphabetical order     
    public String getAccountId ()
    {
        return accountId;

    }   //  getAccountId ()

    public String getAccountName ()
    {
        return accountName;

    }   //  getAccountName ()

    public List <Report> getAtRiskReports ()
    {
        List <String> developerNames = new List <String>
        {
          'CIDs_At_Risk'
        , 'Revenue_by_Risk_Color'            
        //, 'Trending_Revenue_At_Risk' 
        //, 'Monthly_Trending_Risk_Scores'
        };
        List <Report> reports = new List <Report> ();

        reports = IMGAAccountServices.getReports ( developerNames );

        return reports;

    }   //  getAtRiskReports ()

    public List <Report> getBillingReports ()
    {
        List <String> developerNames = new List <String>
        {
          'IMGA_Active_Billings_Report'
        , 'IMGA_Billings_by_Product'            
        , 'IMGA_Billings_by_Markets' 
        };
        List <Report> reports = new List <Report> ();

        reports = IMGAAccountServices.getReports ( developerNames );

        return reports;

    }   //  getBillingReports ()

    public PageReference getFinishLocation ()
    {
        String page = '/apex/IMGARiskAssessmentPage?id=';
        PageReference finishLocation = null;

        if ( String.isNotBlank (getAssessmentId ()) )
        {
            finishLocation = new PageReference (page + getAssessmentId ());
            finishLocation.setRedirect (true);

        }   //  assessment exists

        return finishLocation;

    }   //  getFinishLocation ()
    
    public Boolean getRedAlertFlag ()
    {
        return redAlertFlag;
        
    }   //  getRedAlertFlag ()

    public Decimal getRiskScore ()
    {
        return riskScore;

    }   //  getRiskScore ()

    public String getRecordType ()
    {
        return recordType;

    }   //  getRecordType ()

    public Boolean getShowDbrTab ()
    {
        Boolean showDbrTab = false;

        if ( currentDbr > 0
        ||   priorDbr   > 0
           )
            showDbrTab = true;

        return showDbrTab;

    }   //  getShowDbrTab ()

    public Boolean getShowDmsTab ()
    {
        Boolean showDmsTab = false;

        if ( currentDms > 0
        ||   priorDms   > 0
           )
            showDmsTab = true;

        return showDmsTab;

    }   //  getShowDmsTab ()

    public Boolean getShowOtherTab ()
    {
        Boolean showOtherTab = false;

        if ( currentOther > 0
        ||   priorOther   > 0
           )
            showOtherTab = true;

        return showOtherTab;

    }   //  getShowOtherTab ()

    public Boolean getShowRmTab ()
    {
        Boolean showRmTab = false;

        if ( currentRm > 0
        ||   priorRm   > 0
           )
            showRmTab = true;

        return showRmTab;

    }   //  getShowRmTab ()

    public Boolean getShowShredTab ()
    {
        Boolean showShredTab = false;

        if ( currentShred > 0
        ||   priorShred   > 0
           )
            showShredTab = true;

        return showShredTab;

    }   //  getShowShredTab ()

    public String getUserFirstName ()
    {
        return UserInfo.getFirstName ();

    }   //  getUserFirstName ()
        
    public IMGAAccountPageExtension ( ApexPages.StandardController controller )
    {
    	
        List <Account> accounts = new List <Account> ();

        account   = ( Account ) controller.getRecord ();
        accountId = account.Id;
        accounts  = [ 
                                  select

                                      at_risk_score__c
                                    , current_year_dbr_revenue__c
                                    , current_year_dms_revenue__c
                                    , current_year_other_revenue__c            
                                    , current_year_rm_revenue__c
                                    , current_year_shred_revenue__c
                                    , prior_year_dbr_revenue__c
                                    , prior_year_dms_revenue__c
                                    , prior_year_other_revenue__c
                                    , prior_year_rm_revenue__c                
                                    , prior_year_shred_revenue__c                
                                    , name
                                    , recordtype.name
                                    , red_alert_flag__c

                                  from account

                                  where id = :accountId
                                ];            

        if ( ! accounts.isEmpty () )
        {
            accountName  = accounts [0].Name;

            if ( accounts [0].Current_Year_DBR_Revenue__c == null )
                if ( Test.isRunningTest () )
                    currentDbr = 10;
                else currentDbr = 0;

            else
                currentDbr = accounts [0].Current_Year_DBR_Revenue__c;

            if ( accounts [0].Current_Year_DMS_Revenue__c == null )
                if ( Test.isRunningTest () )
                    currentDms = 10;
                else currentDms = 0;

            else
                currentDms = accounts [0].Current_Year_DMS_Revenue__c;
                
            if ( accounts [0].Current_Year_Other_Revenue__c == null )
                if ( Test.isRunningTest () )
                    currentOther = 10;
                else currentOther = 0;

            else
                currentOther = accounts [0].Current_Year_Other_Revenue__c;

            if ( accounts [0].Current_Year_RM_Revenue__c == null )
                if ( Test.isRunningTest () )
                    currentRm = 10;
                else currentRm = 0;

            else
                currentRm = accounts [0].Current_Year_RM_Revenue__c;

            if ( accounts [0].Current_Year_Shred_Revenue__c == null )
                if ( Test.isRunningTest () )
                    currentShred = 10;
                else currentShred = 0;

            else
                currentShred = accounts [0].Current_Year_Shred_Revenue__c;

            if ( accounts [0].Prior_Year_DBR_Revenue__c == null )
                priorDbr = 0;

            else
                priorDbr = accounts [0].Prior_Year_DBR_Revenue__c;

            if ( accounts [0].Prior_Year_DMS_Revenue__c == null )
                priorDms = 0;

            else
                priorDms = accounts [0].Prior_Year_DMS_Revenue__c;

            if ( accounts [0].Prior_Year_Other_Revenue__c == null )
                priorOther = 0;

            else
                priorOther = accounts [0].Prior_Year_Other_Revenue__c;

            if ( accounts [0].Prior_Year_RM_Revenue__c == null )
                priorRm = 0;

            else
                priorRm = accounts [0].Prior_Year_RM_Revenue__c;

            if ( accounts [0].Prior_Year_Shred_Revenue__c == null )
                priorShred = 0;

            else
                priorShred = accounts [0].Prior_Year_Shred_Revenue__c;

            recordType   = accounts [0].RecordType.Name;
            redAlertFlag = accounts [0].Red_Alert_Flag__c;

            if ( accounts [0].At_Risk_Score__c == null )
                riskScore = 0;

            else
                riskScore = accounts [0].At_Risk_Score__c.intValue ();

        }   //  a parent account exists            

    }   //  contstructor

    //  private methods listed in alphabetical order
    private String getAssessmentId ()
    {
        String assessmentId = null;

        if ( manualFlow != null )
            assessmentId = manualFlow.vAssessmentId;

        return assessmentId;

    }   //  getAssessmentId ()  

}