/***************************************************************************************************
Class    :  IMGAAggregationBatch.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :    June 25, 2013
Modified :  August 06, 2013
Objective:  This Batch Apex class aggregates revenue fields from customer
                                  accounts to their IMGA Account. 

***************************************************************************************************/

global class IMGAAggregationBatch implements Database.Batchable <sObject>,  Schedulable
{
    //  private properties declared in alphabetical order
    final String query = null;

    //  global methods listed in alphabetical order
    global void execute ( Database.BatchableContext BC , List <sObject> scope )
    {
        //  variables declared in alphabetical order
        List <Account> imgas = ( List <Account> ) scope;
        List <Database.SaveResult> results = new List <Database.SaveResult> ();

        for ( Account imga : imgas ) {
        	String IMGAName = String.escapeSingleQuotes(imga.Name);
            imga.Count_of_Red_Cids__c           = CustomerAccountServices.getCountOfRedCids (IMGAName);
            imga.Current_Year_DBR_Revenue__c    = CustomerAccountServices.getTotalRevenue ('Current_Year_DBR_Revenue__c ', IMGAName);
            imga.Current_Year_DMS_Revenue__c    = CustomerAccountServices.getTotalRevenue ('Current_Year_DMS_Revenue__c ', IMGAName);
            imga.Current_Year_Green_Revenue__c  = CustomerAccountServices.getTotalGreenRevenue (IMGAName);
            imga.Current_Year_Other_Revenue__c  = CustomerAccountServices.getTotalRevenue ('Current_Year_Other_Revenue__c ', IMGAName);
            imga.Current_Year_Red_Revenue__c    = CustomerAccountServices.getTotalRedRevenue (IMGAName);
            imga.Current_Year_RM_Revenue__c     = CustomerAccountServices.getTotalRevenue ('Current_Year_RM_Revenue__c ', IMGAName);
            imga.Current_Year_Shred_Revenue__c  = CustomerAccountServices.getTotalRevenue ('Current_Year_Shred_Revenue__c ', IMGAName);
            imga.Current_Year_Yellow_Revenue__c = CustomerAccountServices.getTotalYellowRevenue (IMGAName);
            imga.Last_Aggregation_Batch_Date__c = Date.today ();
            imga.Prior_Year_DBR_Revenue__c      = CustomerAccountServices.getTotalRevenue ('Prior_Year_DBR_Revenue__c ', IMGAName);
            imga.Prior_Year_DMS_Revenue__c      = CustomerAccountServices.getTotalRevenue ('Prior_Year_DMS_Revenue__c ', IMGAName);
            imga.Prior_Year_Other_Revenue__c    = CustomerAccountServices.getTotalRevenue ('Prior_Year_Other_Revenue__c ', IMGAName);
            imga.Prior_Year_RM_Revenue__c       = CustomerAccountServices.getTotalRevenue ('Prior_Year_RM_Revenue__c ', IMGAName);
            imga.Prior_Year_Shred_Revenue__c    = CustomerAccountServices.getTotalRevenue ('Prior_Year_Shred_Revenue__c ', IMGAName); 
            }

            results = Database.update (imgas, false); } 

    global void execute ( SchedulableContext sc ) {
        IMGAAggregationBatch batch = new IMGAAggregationBatch ();
        Id processId = Database.executeBatch (batch, 1); }
    global void finish ( Database.BatchableContext BC ) {
        AsyncApexJob job = [ select createdby.email, id, jobitemsprocessed, numberoferrors, status, totaljobitems from asyncapexjob where id = :BC.getJobId () ];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage ();
        String [] toAddresses = new String [] {job.CreatedBy.Email};
        mail.setToAddresses (toAddresses);
        mail.setSubject ('IMGA Aggregation Batch completed with a status of ' + job.Status + '.');
        mail.setPlainTextBody ('The batch Apex job processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures and executed the following query:  ' + query);
        Messaging.sendEmail (new Messaging.SingleEmailMessage [] { mail }); }
    global IMGAAggregationBatch () {
        if ( Test.isRunningTest () ) query = 'select at_risk_score__c, current_year_dbr_revenue__c, current_year_dms_revenue__c, current_year_other_revenue__c, current_year_rm_revenue__c, current_year_shred_revenue__c, id, last_aggregation_batch_date__c, name, prior_year_dbr_revenue__c, prior_year_dms_revenue__c, prior_year_other_revenue__c, prior_year_rm_revenue__c, prior_year_shred_revenue__c from account where ( last_aggregation_batch_date__c < LAST_N_DAYS:' + 27 + ' or last_aggregation_batch_date__c = ' + null + ' ) and parentid = ' + null + ' limit ' + 1;
        else query = 'select at_risk_score__c, current_year_dbr_revenue__c, current_year_dms_revenue__c, current_year_other_revenue__c, current_year_rm_revenue__c, current_year_shred_revenue__c, id, last_aggregation_batch_date__c, name, prior_year_dbr_revenue__c, prior_year_dms_revenue__c, prior_year_other_revenue__c, prior_year_rm_revenue__c, prior_year_shred_revenue__c from account where ( last_aggregation_batch_date__c < LAST_N_DAYS:' + 27 + ' or last_aggregation_batch_date__c = ' + null + ' ) and imga_account_flag__c = ' + true; }
    global Database.Querylocator start ( Database.BatchableContext BC ) {
        Database.Querylocator queryLocator = null;
        if ( query != null ) queryLocator = Database.getQueryLocator (query);
        return queryLocator; }
}