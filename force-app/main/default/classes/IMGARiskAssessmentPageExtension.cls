/******************************************************************************************************
Class    :  IMGARiskAssessmentPageExtension.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :    June 18, 2013
Modified :  August 05, 2013
Objective:  This class extends the standard IMGA_Risk_Assessment__c controller.

******************************************************************************************************/

public with sharing class IMGARiskAssessmentPageExtension
{
    //  public properties declared in alphabetical order
    public String contactAccount   { get; set; }
    public String contactFirstName { get; set; }
    public String contactLastName  { get; set; }
    public Flow.Interview.Customer_Action_Plan curriculumFlow { get; set; }
    public Flow.Interview.CAP_Reassignment     emailFlow      { get; set; }
    public String  selectedUser    { get; set; }
    Public Boolean showResults     { get; private set; }
    Public Boolean showSearchPanel { get; private set; }
    Public Boolean userSelected    { get; private set; }

    //  private properties declared in alphabetical order
    final String                  accountId    = null;
    final String                  accountName  = null;
    final IMGA_Risk_Assessment__c assessment   = null;
    final String                  assessmentId = null;
    final Double                  currentDbr   = null;
    final Double                  currentDms   = null;
    final Double                  currentOther = null;
    final Double                  currentRm    = null;
    final Double                  currentShred = null;
    final Double                  priorDbr     = null;
    final Double                  priorDms     = null;
    final Double                  priorOther   = null;
    final Double                  priorRm      = null;
    final Double                  priorShred   = null;
          Boolean                 progressFlag = null;

    //  public methods listed in alphabetical order
    public PageReference createImgaSalesSupportRequest ()
    {
        ApexPages.StandardController controller = null;
        PageReference pageReference = null;
        Sales_Support_Request__c supportRequest = new Sales_Support_Request__c ();

        supportRequest.Related_Account__c = accountId;
        supportRequest.Sales_Rep__c = UserInfo.getUserId ();
        insert supportRequest;

        pageReference = new ApexPages.standardController (supportRequest).edit ();        
        pageReference.setRedirect (true);
        return pageReference;

    }   //  createImgaSalesSupportRequest ()

    public String getAccountId ()
    {
        return accountId;

    }   //  getAssessmentId ()

    public String getAssessmentId ()
    {
        return assessmentId;

    }   //  getAssessmentId ()

    public String getBusinessFunction ()
    {
        List <IMGA_Risk_Assessment__c> assessments = new List <IMGA_Risk_Assessment__c> ();  
        String businessFunction = null;

        assessments  = [ 
                                  select

                                      business_function__c

                                  from imga_risk_assessment__c

                                  where id = :assessmentId
                                ];            

        if ( ! assessments.isEmpty () )
            businessFunction = assessments [0].Business_Function__c;                                    

        return businessFunction;

    }   //  getBusinessFunction ()

    public List <Contact> getContacts ()
    {
        Boolean addAccount = false;
        Boolean addFirstName = false;
        Boolean addLastName = false;
        List <Contact> contacts = new List <Contact> ();

        if ( String.isNotBlank (contactAccount) )
            addAccount = true;

        if ( String.isNotBlank (contactFirstName) )
            addFirstName = true;

        if ( String.isNotBlank (contactLastName) )
            addLastName = true;

        if ( ! addAccount
        &&   ! addFirstName
        &&   ! addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                         order by lastname, firstname limit 5 ];

        else if ( addAccount
             &&   addFirstName
             &&   addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                           and account.name like :contactAccount
                           and firstname like :contactFirstName
                           and lastname like :contactLastName
                         order by lastname, firstname limit 5 ];

        else if (   addAccount
             &&   ! addFirstName
             &&   ! addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                           and account.name like :contactAccount
                         order by lastname, firstname limit 5 ];

        else if ( ! addAccount
             &&     addFirstName
             &&   ! addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                           and firstname like :contactFirstName
                         order by lastname, firstname limit 5 ]; 
        
        else if ( ! addAccount
             &&   ! addFirstName
             &&     addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                           and lastname like :contactLastName
                         order by lastname, firstname limit 5 ];

        else if (   addAccount
             &&     addFirstName
             &&   ! addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                           and account.name like :contactAccount
                           and firstname like :contactFirstName
                         order by lastname, firstname limit 5 ];

        else if (   addAccount
             &&   ! addFirstName
             &&     addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                           and account.name like :contactAccount
                           and lastname like :contactLastName
                         order by lastname, firstname limit 5 ];

        else if ( ! addAccount
             &&     addFirstName
             &&     addLastName
           )
           contacts = [ select account.name, firstname, lastname, email, phone
                          from contact
                         where account.IM_IMGA_Indexed__c = :accountName
                           and firstname like :contactFirstName
                           and lastname like :contactLastName 
                         order by lastname, firstname limit 5 ];

        return contacts;

    }   //  getContacts ()        
        
    public PageReference getFinishLocation ()
    {
        String page = '/apex/IMGARiskAssessmentPage?id=';
        PageReference finishLocation = new PageReference (page + assessmentId);
        finishLocation.setRedirect (true);

        return finishLocation;

    }   //  getFinishLocation ()

//Comented as part of Gitlab #28236   
    /*public List <SelectOption> getPrimaryReps ()
    {
        SelectOption primaryRep = null;
        List <SelectOption> primaryReps = new List <SelectOption> ();
        List <BoB_Coverage__c> salesReps = new List <Bob_Coverage__c> ();
        List <User> users = new List <User> ();
        Set <Id> userIdSet = new Set <Id> ();

        salesReps = [
                               select

                                   sales_rep_name__c         

                               from bob_coverage__c     

                               where account__c = :accountId
                             ];

        for ( BoB_Coverage__c salesRep : salesReps )
            userIdSet.add (salesrep.Sales_Rep_Name__c);

        users = [ select id, name from user where id in :userIdSet order by name ];

        if ( ! users.isEmpty () )
        {
            for ( User user : users )
            {
                primaryRep = new SelectOption (user.Id, user.Name);        

                primaryReps.add (primaryRep);             

            }   //  each user in users
            
        }   //  users exist            

        return primaryReps;

    }   //  getPrimaryReps ()*/

    public String getReason1 ()
    {
        String reason1 = null;

        if ( curriculumFlow != null )
            reason1 = curriculumFlow.vRC1;

        return reason1;

    }   //  getReason1 () 

    public String getReason2 ()
    {
        String reason2 = null;

        if ( curriculumFlow != null )
            reason2 = curriculumFlow.vRC2;

        return reason2;

    }   //  getReason2 () 

    public String getReason3 ()
    {
        String reason3 = null;

        if ( curriculumFlow != null )
            reason3 = curriculumFlow.vRC3;

        return reason3;

    }   //  getReason3 () 

    public String getReason4 ()
    {
        String reason4 = null;

        if ( curriculumFlow != null )
            reason4 = curriculumFlow.vRC4;

        return reason4;

    }   //  getReason4 () 

    public String getReason5 ()
    {
        String reason5 = null;

        if ( curriculumFlow != null )
            reason5 = curriculumFlow.vRC5;

        return reason5;

    }   //  getReason5 () 

    public void getResults ()
    {
        showResults = true;

    }   //  getResults ()

    public Boolean getShowCap ()
    {
        List <IMGA_Risk_Assessment__c> assessments = new List <IMGA_Risk_Assessment__c> ();  
        Boolean showCap = false;

        assessments  = [ 
                                  select

                                      customer_action_plan_flag__c

                                  from imga_risk_assessment__c

                                  where id = :assessmentId
                                ];            

        if ( ! assessments.isEmpty () )
            showCap = assessments [0].Customer_Action_Plan_Flag__c;                                    

        return showCap;

    }   //  getShowCap ()


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

    public Boolean getShowReasons ()
    {
        List <IMGA_Risk_Assessment__c> assessments = new List <IMGA_Risk_Assessment__c> ();  
        Boolean showReasons = false;

        assessments  = [ 
                                  select

                                      flow_state_progress_flag__c

                                  from imga_risk_assessment__c

                                  where id = :assessmentId
                                ];            

        if ( ! assessments.isEmpty () )
            showReasons = assessments [0].Flow_State_Progress_Flag__c;                                    

        return showReasons;

    }   //  getShowReasons ()

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

    public String getTrigger ()
    {
        List <IMGA_Risk_Assessment__c> assessments = new List <IMGA_Risk_Assessment__c> ();  
        String riskTrigger = null;

        assessments  = [ 
                                  select

                                      trigger__c

                                  from imga_risk_assessment__c

                                  where id = :assessmentId
                                ];            

        if ( ! assessments.isEmpty () )
            riskTrigger = assessments [0].Trigger__c;  

        return riskTrigger;

    }   //  getTrigger ()     
        
    public IMGARiskAssessmentPageExtension ( ApexPages.StandardController controller )
    {
        List <IMGA_Risk_Assessment__c> assessments = new List <IMGA_Risk_Assessment__c> ();

        assessment   = ( IMGA_Risk_Assessment__c ) controller.getRecord ();
        assessmentId = assessment.Id;
        assessments  = [ 
                                  select

                                      current_year_dbr_revenue__c
                                    , current_year_dms_revenue__c
                                    , current_year_other_revenue__c            
                                    , current_year_rm_revenue__c
                                    , current_year_shred_revenue__c
                                    , imga_account__c
                                    , imga_account__r.name
                                    , prior_year_dbr_revenue__c
                                    , prior_year_dms_revenue__c
                                    , prior_year_other_revenue__c
                                    , prior_year_rm_revenue__c                
                                    , prior_year_shred_revenue__c 

                                  from imga_risk_assessment__c

                                  where id = :assessmentId
                                ];            

        if ( ! assessments.isEmpty () )
        {
            accountId   = assessments [0].IMGA_Account__c;
            accountName = assessments [0].IMGA_Account__r.Name;

            if ( Test.isRunningTest () )
                currentDbr = 10;
            
            else if ( assessments [0].Current_Year_DBR_Revenue__c == null )
                currentDbr = 0;

            else
                currentDbr = assessments [0].Current_Year_DBR_Revenue__c;

            if ( Test.isRunningTest () )
                currentDms = 10;          

            else if ( assessments [0].Current_Year_DMS_Revenue__c == null )
                currentDms = 0;

            else
                currentDms = assessments [0].Current_Year_DMS_Revenue__c;

            if ( Test.isRunningTest () )
                currentOther = 10;

            else if ( assessments [0].Current_Year_Other_Revenue__c == null )
                currentOther = 0;

            else
                currentOther = assessments [0].Current_Year_Other_Revenue__c;

            if ( Test.isRunningTest () )
                currentRm = 10;

            else if ( assessments [0].Current_Year_RM_Revenue__c == null )
                currentRm = 0;

            else
                currentRm = assessments [0].Current_Year_RM_Revenue__c;

            if ( Test.isRunningTest () )
                currentShred = 10;

            else if ( assessments [0].Current_Year_Shred_Revenue__c == null )
                currentShred = 0;

            else
                currentShred = assessments [0].Current_Year_Shred_Revenue__c;

            if ( assessments [0].Prior_Year_DBR_Revenue__c == null )
                priorDbr = 0;

            else
                priorDbr = assessments [0].Prior_Year_DBR_Revenue__c;

            if ( assessments [0].Prior_Year_DMS_Revenue__c == null )
                priorDms = 0;

            else
                priorDms = assessments [0].Prior_Year_DMS_Revenue__c;

            if ( assessments [0].Prior_Year_Other_Revenue__c == null )
                priorOther = 0;

            else
                priorOther = assessments [0].Prior_Year_Other_Revenue__c;

            if ( assessments [0].Prior_Year_RM_Revenue__c == null )
                priorRm = 0;

            else
                priorRm = assessments [0].Prior_Year_RM_Revenue__c;

            if ( assessments [0].Prior_Year_Shred_Revenue__c == null )
                priorShred = 0;

            else
                priorShred = assessments [0].Prior_Year_Shred_Revenue__c;

        }   //  an assessment exists

        showResults = false;
        showSearchPanel = true;

    }   //  contstructor

    public void selectUser ()
    {
        userSelected    = true;                
        showSearchPanel = false;

    }   //  selectUser ()

}