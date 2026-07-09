/******************************************************************************************************
Class    :  IMGAAccountServices.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :    June 30, 2013
Modified :  August 07, 2013
Objective:  This class provides methods to service IMGA Account collections.

******************************************************************************************************/

public with sharing class IMGAAccountServices
{
    //  static properties declared in alphabetical order
    static Map <Id, List <Id>> riskAssessmentIdMap = new Map <Id, List <Id>> ();

    //  public methods listed in alphabetical order
    public static Boolean bypassNotification ( Account imga ){
        //  variables declared in alphabetical order
        Boolean bypass = false;
        Date overrideDate = null;
        Date overrideExpirationDate = null;
        IMGA_Risk_Assessment__c riskAssessment = null;
        List <IMGA_Risk_Assessment__c> riskAssessments = getRiskAssessmentsByImgaId ( imga.Id );
        String riskStatus = null;
        Date todayDate = Date.today ();

        if ( ! riskAssessments.isEmpty () ){
            riskAssessment = riskAssessments [0];           
			System.debug('riskAssessment.At_Risk_Override_Date__c=='+riskAssessment.At_Risk_Override_Date__c);
            if ( riskAssessment.At_Risk_Override_Date__c != null )
            {
                overrideDate = riskAssessment.At_Risk_Override_Date__c;  
                overrideExpirationDate = overrideDate.addDays (60);

                if ( todayDate <= overrideExpirationDate )
                    bypass = true;

            }
            else
            {
                System.debug('riskAssessment.At_Risk_Status__c=='+riskAssessment.At_Risk_Status__c);
                if ( String.isNotBlank (riskAssessment.At_Risk_Status__c) )
                {
                    riskStatus = riskAssessment.At_Risk_Status__c;

                    if ( ! riskStatus.equals ('Reject Risk') )                    
                        bypass = true;

                }   //  risk assessment status is not null

            }   //  risk assessor overrode risk assessment

        }   //  not initial at-risk notification

        System.debug('bypass value'+bypass+ 'for IMGA Acct='+imga.Id);
        return bypass;

    }   //  bypassNotification ()

    public static IMGA_Risk_Assessment__c createImgaRiskAssessment ( Account imga ){
        System.debug('Inside Creating the IMGARiskAssessment');
        Database.SaveResult result = null;
        IMGA_Risk_Assessment__c riskAssessment = new IMGA_Risk_Assessment__c ();
        Id riskAssessmentId = null;
        List <Id> riskAssessorIds = getImgaRiskAssessorIds ( imga );

        riskAssessment.IMGA_Account__c = imga.Id;

        if ( ! riskAssessorIds.isEmpty () )
            riskAssessment.At_Risk_Assessor__c = riskAssessorIds [0];

        result = Database.insert (riskAssessment);

        if ( result.isSuccess () )
        {
            riskAssessmentId = result.getId ();        

            riskAssessmentIdMap.put (riskAssessmentId, riskAssessorIds);

        }   //  risk assessment is successfully created

        return riskAssessment;

    }   //  createImgaRiskAssessment ()

    public static Set <Id> getAccountIdSetByImga ( String imga ){
        List <Account> accounts = new List <Account> ();
        Set <Id> accountIdSet = new Set <Id> ();
  
        accounts = [ select id from account where im_imga__c = :imga ];
        
        if ( ! accounts.isEmpty () )
            for ( Account account : accounts )
                accountIdSet.add (account.Id);

        return accountIdSet;

    }   //  getAccountIdSetByImga ()

    public static List <Id> getImgaRiskAssessorIds ( Account imga ){
        List <Id> riskAssessorIds = new List <Id> ();       
        Boolean redDbr = false;
        Boolean redRmShred = false;

        if ( imga.DBR_At_Risk_Score__c != null
        &&   imga.DBR_At_Risk_Score__c == 10
           )
            redDbr = true;     

        if ( ( imga.RM_At_Risk_Score__c != null
        &&     imga.RM_At_Risk_Score__c == 10
             )
        ||   ( imga.Shred_At_Risk_Score__c != null
        &&     imga.Shred_At_Risk_Score__c == 10
             )
           )
            redRmShred = true;

        if ( ! redDbr
        &&     redRmShred
           )
        {
            if ( ! String.isBlank (imga.Primary_CDE__c) )       
                riskAssessorIds.add (imga.Primary_CDE__c);

            else if ( ! String.isBlank ( imga.Primary_BDE__c) )
                riskAssessorIds.add (imga.Primary_BDE__c);

        }

        else if (   redDbr
        &&        ! redRmShred
                )
        {
            if ( ! String.isBlank (imga.Primary_CDE_DB_R__c) )       
                riskAssessorIds.add (imga.Primary_CDE_DB_R__c);           

            else if ( ! String.isBlank (imga.Primary_BDE_DB_R__c) )       
                riskAssessorIds.add (imga.Primary_BDE_DB_R__c);

        }

        else if ( redDbr
        &&        redRmShred
                )
        {
            if ( ! String.isBlank (imga.Primary_CDE_DB_R__c) )       
                riskAssessorIds.add (imga.Primary_CDE_DB_R__c);           

            else if ( ! String.isBlank (imga.Primary_BDE_DB_R__c) )       
                riskAssessorIds.add (imga.Primary_BDE_DB_R__c);

            if ( ! String.isBlank (imga.Primary_CDE__c) )       
                riskAssessorIds.add (imga.Primary_CDE__c);

            else if ( ! String.isBlank ( imga.Primary_BDE__c) )
                riskAssessorIds.add (imga.Primary_BDE__c);

        }

        System.debug ('riskAssessorIds:  ' + riskAssessorIds);

        return riskAssessorIds;

    }   //  getImgaRiskAssessorIds ()

    public static List <Report> getReports ( List <String> developerNames ){    
        List <Report> reports = new List <Report> ();

        reports = [ select id, description, name from report where developername in :developerNames ];

        return reports;

    }   //  getReports ()

    public static List <IMGA_Risk_Assessment__c> getRiskAssessmentsByImgaId ( Id ImgaId ){
        List <IMGA_Risk_Assessment__c> riskAssessments = new List <IMGA_Risk_Assessment__c> ();

        riskAssessments = [ select at_risk_assessor__c, at_risk_override_date__c, at_risk_status__c, id, imga_account__c, imga_account__r.name
                            from imga_risk_assessment__c where imga_account__c = :imgaId order by createddate desc ];

        return riskAssessments;

    }   //  getRiskAssessmentsByIdSet ()

    public static List <IMGA_Risk_Assessment__c> getRiskAssessmentsByIdSet ( Set <Id> riskAssessmentIdSet ){
        List <IMGA_Risk_Assessment__c> riskAssessments = new List <IMGA_Risk_Assessment__c> ();

        riskAssessments = [ select at_risk_assessor__c, id, imga_account__c, imga_account__r.name
                            from imga_risk_assessment__c where id in :riskAssessmentIdSet ];

        return riskAssessments;

    }   //  getRiskAssessmentsByIdSet ()

    public static List <ConnectApi.FeedItem> sendImgaRiskNotifications ( List <Account> imgas ) {
        //  variables declared in alphabetical order 
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        List <String> mentionedUserIds = null;
        Set <Id> mentionedUserIdSet = null;
        String message = null;
        ConnectApi.FeedItem notification = null;
        List <ConnectApi.FeedItem> notifications = new List <ConnectApi.FeedItem> ();
        List <Id> riskAssessorIds = new List <Id> ();

        for ( Account imga : imgas )
        {
            mentionedUserIds   = new List <String> ();
            mentionedUserIdSet = new Set <Id> ();
            riskAssessorIds    = getImgaRiskAssessorIds (imga);

            if ( ! riskAssessorIds.isEmpty () )
            {
                for ( Id riskAssessorId : riskAssessorIds )                 
                {
                    if ( ! mentionedUserIdSet.contains (riskAssessorId) )
                    {
                        mentionedUserIds.add (riskAssessorId);

                        mentionedUserIdSet.add (riskAssessorId);

                    }   //  user not already added to list of notification recipients

                }   //  each risk assessor

                System.debug ('mentionedUserIds:  ' + mentionedUserIds);

                message = 'Your IMGA Account \'' + imga.Name
                        + '\' is At-Risk.  Risk has been identified with both Records Management/'
                        + 'Secure Shredding and Data Backup & Recovery.  Please know that the '
                        + 'appropriate individuals supporting these product lines will be notified.  '
                        + 'A risk assessment will not be automatically created.  Given this, it is '
                        + 'necessary that you follow the provided link and indicate risk on the '
                        + 'account by selecting the “Red Alert” button at the top of the page.  '
                        + 'Once complete, then enter in your product line and a risk trigger to '
                        + 'begin the Customer Action Plan Wizard.';

                        notification = ChatterUtilities.postFeedItem ('internal' , feedType
                                     , imga.Id, message , mentionedUserIds,'','','');

                        if ( notification != null )
                            notifications.add (notification);

            }   //  risk assessors exist

        }   //  each risk assessment

        return notifications;

    }   //  sendImgaRiskNotifications ()

    public static List <ConnectApi.FeedItem> sendImgaRiskNotifications ( List <IMGA_Risk_Assessment__c> riskAssessments ) 
    {
        //  variables declared in alphabetical order 
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        List <String> mentionedUserIds = null;
        Set <Id> mentionedUserIdSet = null;
        String message = null;
        ConnectApi.FeedItem notification = null;
        List <ConnectApi.FeedItem> notifications = new List <ConnectApi.FeedItem> ();
        List <Id> riskAssessorIds = new List <Id> ();

        for ( IMGA_Risk_Assessment__c riskAssessment : riskAssessments )
        {
            if ( ! String.isBlank (riskAssessment.At_Risk_Assessor__c) )  
            {
                mentionedUserIds   = new List <String> ();
                mentionedUserIdSet = new Set <Id> ();

                System.debug ('riskAssessmentIdMap:  ' + riskAssessmentIdMap);

                if ( ! riskAssessmentIdMap.isEmpty () )
                {
                    riskAssessorIds  = riskAssessmentIdMap.get (riskAssessment.Id);

                    if ( ! riskAssessorIds.isEmpty () )
                    {
                        for ( Id riskAssessorId : riskAssessorIds )                 
                        {
                            if ( ! mentionedUserIdSet.contains (riskAssessorId) )
                            {
                                mentionedUserIds.add (riskAssessorId);

                                mentionedUserIdSet.add (riskAssessorId);

                            }   //  user not already added to list of notification recipients

                        }   //  each risk assessor

                        System.debug ('mentionedUserIds:  ' + mentionedUserIds);

                        message = 'Your IMGA Account \'' + riskAssessment.IMGA_Account__r.Name
                                  + '\' is At-Risk.'
                                  +'\n\nPlease select the link to the Risk Assessment, review your at-risk information,'
                                  + 'and click the UPDATE button to take action.'
                                  + '\n\n You will have 7 days before the status of your account updates to'
                                  + ' “No Action Taken.';

                        notification = ChatterUtilities.postFeedItem ('internal' , feedType
                                     , riskAssessment.IMGA_Account__c, message 
                                     , mentionedUserIds,riskAssessment.IMGA_Account__r.Name,riskAssessment.Id,'True');

                        if ( notification != null )
                            notifications.add (notification);

                    }   //  risk assessors exist

                }   //  risk assessor map is not empty     

            }   //  at least one notification recipient exists

        }   //  each risk assessment

        return notifications;

    }   //  sendImgaRiskNotifications ()

}