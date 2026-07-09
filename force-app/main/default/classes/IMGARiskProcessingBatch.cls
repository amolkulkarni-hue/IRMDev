/*******************************************************************************************************************
Class    :  IMGARiskProcessingBatch.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :    June 15, 2013
Modified :  August 06, 2013
Objective:  This Batch Apex class processes Red IMGA Accounts. 

*******************************************************************************************************************/

global class IMGARiskProcessingBatch implements Database.Batchable <sObject>,  Schedulable
{
    //  private properties declared in alphabetical order
    final String query = null;

    //  global methods listed in alphabetical order
    global void execute ( Database.BatchableContext BC , List <sObject> scope )
    {
        //  variables declared in alphabetical order
        List <Account> imgas = ( List <Account> ) scope;
        List <Account> tiedImgas = new List <Account> ();
        List <ConnectApi.FeedItem> notifications = new List <ConnectApi.FeedItem> ();
        List <Database.SaveResult> results = new List <Database.SaveResult> ();
        IMGA_Risk_Assessment__c riskAssessment = null;
        Id riskAssessmentId = null;
        Set <Id> riskAssessmentIdSet = new Set <Id> ();
        List <IMGA_Risk_Assessment__c> riskAssessments = new List <IMGA_Risk_Assessment__c> ();

        if ( ! imgas.isEmpty () ) {
            for ( Account imga : imgas )
            {
                System.debug ( 'Batch processing ' + imgas.size () + ' accounts.');

                if ( ! IMGAAccountServices.bypassNotification (imga) )
                {
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

                    if ( redDbr
                    &&   redRmShred
                       )
                        tiedImgas.add (imga);

                    else
                    {
                        riskAssessment = IMGAAccountServices.createImgaRiskAssessment (imga);

                        if ( riskAssessment != null )
                            riskAssessmentIdSet.add (riskAssessment.Id);

                    }   //  no IMGA_Risk_Assessment__c record should be created

                    imga.Last_Risk_Processing_Batch_Date__c = Date.today ();

                }   //  imga-at-risk notification should not be bypassed

            }   //  each account in batch

        }   //  there are accounts to process

        riskAssessments = IMGAAccountServices.getRiskAssessmentsByIdSet (riskAssessmentIdSet);

        notifications = IMGAAccountServices.sendImgaRiskNotifications (riskAssessments);

        notifications = IMGAAccountServices.sendImgaRiskNotifications (tiedImgas);

        results = Database.update (imgas, false); } 

    global void execute ( SchedulableContext sc )
    {
        IMGARiskProcessingBatch batch = new IMGARiskProcessingBatch ();
        Id processId = Database.executeBatch (batch, 50);

    }   //  execute scheuled job

    global void finish ( Database.BatchableContext BC )
    {
        AsyncApexJob job = [
                               select

                                   createdby.email
                                 , id
                                 , jobitemsprocessed
                                 , numberoferrors
                                 , status
                                 , totaljobitems

                               from asyncapexjob 

                               where id = :BC.getJobId ()
                             ];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage ();
        String [] toAddresses = new String [] {job.CreatedBy.Email};
        mail.setToAddresses (toAddresses);
        mail.setSubject ('IMGA Risk Processing Batch completed with a status of ' + job.Status + '.');
        mail.setPlainTextBody ('The batch Apex job processed ' + job.TotalJobItems
                             + ' batches with ' + job.NumberOfErrors + ' failures and executed'
                             + ' the following query:  ' + query);
        Messaging.sendEmail (new Messaging.SingleEmailMessage [] { mail });

    }   //  finish ()

    global IMGARiskProcessingBatch ()
    {
        if ( Test.isRunningTest () )
            query = 'select '
                  + 'dbr_at_risk_score__c, '
                  + 'id, '
                  + 'last_risk_processing_batch_date__c, '
                  + 'name, '
                  + 'primary_bde__c, '
                  + 'primary_bde_db_r__c, '
                  + 'primary_cde__c, '
                  + 'primary_cde_db_r__c, '
                  + 'rm_at_risk_score__c, '
                  + 'shred_at_risk_score__c '
                  + 'from account '
                  + 'where  at_risk_score__c = ' + 10
                  + ' and ( last_risk_processing_batch_date__c < LAST_N_DAYS:' + 27
                  + ' or    last_risk_processing_batch_date__c = ' + null + ' )'
                  + ' and parentid = ' + null
            	  + ' and name like \'%bwtestimga%\' '
                  + ' limit ' + 25;

        else
            query = 'select '
                  + 'dbr_at_risk_score__c, '
                  + 'id, '
                  + 'last_risk_processing_batch_date__c, '
                  + 'name, '
                  + 'primary_bde__c, '
                  + 'primary_bde_db_r__c, '
                  + 'primary_cde__c, '
                  + 'primary_cde_db_r__c, '
                  + 'rm_at_risk_score__c, '
                  + 'shred_at_risk_score__c '
                  + 'from account '
                  + 'where  at_risk_score__c = ' + 10
                  + ' and ( last_risk_processing_batch_date__c < LAST_N_DAYS:' + 27
                  + ' or    last_risk_processing_batch_date__c = ' + null + ' )'
                  + ' and imga_account_flag__c = ' + true;

    }   //  constructor

    global Database.Querylocator start ( Database.BatchableContext BC )
    {
        Database.Querylocator queryLocator = null;

        if ( query != null )
        {
            System.debug (Logginglevel.INFO, 'query:  ' + query);

            queryLocator = Database.getQueryLocator (query);

        }   //  there are schedules to process

        return queryLocator;

    }   //  start ()

}