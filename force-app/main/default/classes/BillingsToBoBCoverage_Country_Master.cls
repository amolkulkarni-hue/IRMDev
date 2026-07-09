/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   BillingsToBoBCoverage_Country_Master (Class)
**
** PURPOSE
**   This is the primary entry point, from which the
**   BillingsToBoBCoverage batch job is invoked.
**
** NOTES
**   Expected invocation format:
**     BillingsToBoBCoverage_Country_Master master = new BillingsToBoBCoverage_Country_Master(customSetting);
**     master.runBatch();
**   Also purges older log entry records.
**
** BUNDLE SUMMARY
**   The fundamental purpose of the BillingsToBoBCoverage (BoB is Book of 
**   Business) set of Apex classes is to track the participation of sales 
**   and account management personnel in generating customer billings, 
**   during the time period(s) in which they were assigned some level of 
**   responsibility for the relationship with each customer.  These 
**   classes collectively establish the appropriate relationships between  
**   existing transactional data (in the form of Billings__c records) and 
**   responsibility data (in the form of BoB_Coverage__c records) by 
**   creating and populating BoB_Coverage_Join__c records.  The join 
**   records support analytics concerning who has contributed to what revenue, and 
**   performance vs. quota.
**   
**   The main code components are:
**     1. Class BillingsToBoBCoverage_Country_Master launches the Apex batch job
**        sequence at the appropriate entry point, depending on Custom
**        Settings in BillingsToBoBCoverageJoins__c.  
**     2. Class BillingsToBoBCoverage_Country_Associate is the main engine,
**        which creates the appropriate BoB_Coverage_Join__c records 
**        to join BoB_Coverage__c to Billings__c records in a (typically)
**        many-to-one relationship.
**     3. Class BillingsToBoBCoverage_Helper contains common methods and
**        variables used by these other classes.
**     4. Class BillingsToBoBCoverage_Log provides persistent 
**        storage/logging via custom object BoB_Coverage_Join_Log__c.
**        Logged information concerns execution in general, but in 
**        particular on any exceptions/warning/errors encountered. 
**     5. The BoB_Coverage_Join_Log__c object is used by the 
**        BillingsToBoBCoverage_Log class.
**     6. Class Test_BillingsToBoBCoverage provides unit testing for the
**        other classes.
**     7. The BillingsToBoBCoverageJoins__c Custom Setting which is specified
**        to the constructor contains the controlling parameters for this 
**        batch job sequence.
**
** POTENTIAL ENHANCEMENTS
**   1. Utilize one or more skinny tables to boost preformance, especially
**      to virtaully fields de-normalize where mult-level joins are needed.
**        Example: Would like to use functional equivalent of 
**                 Billings__c.Includes_BoB_Coverage_on_IMGA__c in QueryLocator's
**                 WHERE cluase, but it's a formula field based on:
**                 "Customer_Account__r.IM_Account__r.IMGA_Lookup__r.of_BoB_Coverage_Records__c > 0"
**   2. So far the data sizes being processed by the batch job have been manageable.
**      At some point, however, it may prove necessary to partition the Billings__c data 
**      into multiple, independent runs.  Running them in parallel may also offer performance 
**      improvements, depending of course on exactly how the platform manages allocating 
**      runtime to contending batch jobs.  One potential major issue with this approach could,
**      of course, be the system-wide 5 batch job limit.
**   3. While it is a single narrative flow, the BillingsToBoBCoverage_CountryParent_Associate class is too 
**      large and more of its functionality needs to be offloaded into other classes.
**   4. The initial BillingsToBoBCoverage_Launcher VF page is pretty primitive.  Its usability
**      could be enhanced by:
**        a. Allowing the user to choose from the available BillingsToBoBCoverageJoins__c
**           data sets.  Ideally the choices would be links so the user can view any given
**           data set's details.
**        b. After a successful launch, take the user to the "Apex Jobs" monitoring system page.
**   5. If the number of billing records tops the 50 million limit, we'll need to segment them
**      based on IMGA name and run as two (or more) independent batch jobs. 
**
************************************************************************/

public with sharing class BillingsToBoBCoverage_Country_Master{public BillingsToBoBCoverage_Country_Master(){string t='1';}}
   /* private final  String  moduleName  = 'BillingsToBoBCoverage_Country_Master';
    
    // Custom Settings access
    private final  String  customSetting;
    private        BillingsToBoBCoverageJoins__c settings;
    
    // external classes
    private BillingsToBoBCoverage_Log    logger;  
    private BillingsToBoBCoverage_Helper helper;  

    
    //-----------------------------------------------------------------------------------
    // constructor
    public BillingsToBoBCoverage_Country_Master (String customSetting) {
        system.debug('BillingsToBoBCoverage_Country_Master');
        
        // access the custom settings
        this.customSetting = customSetting;
        settings = BillingsToBoBCoverageJoins__c.getInstance(customSetting);
        
        // access the log methods
        logger = new BillingsToBoBCoverage_Log(customSetting);                         
        logger.setJobId('Joins_' + DateTime.now().format('MM/dd_HH:mm:ss'));
        
        // access the helper methods
        helper = new BillingsToBoBCoverage_Helper(customSetting);          
                  
    } // BillingsToBoBCoverage_Country_Master
        
     
    //-----------------------------------------------------------------------------------   
    // launch the batch job
    public void runBatch () {    
        
        // log this invocation in BoB_Coverage_Join_Log__c
        logger.newEntry(moduleName, 'Info', 'runBatch', 'scopeSize=' + settings.Scope_Size__c, -1); 
            
        // delete old BoB_Coverage_Join_Log__c records
        Integer delta = Integer.valueOf(settings.Delete_Log_Entries_Older_Than__c) * -1;        
        Date oldestAllowed = Date.today().addDays(delta); 
        try {   
            BoB_Coverage_Join_Log__c[] oldies = [ SELECT Id
                                                    FROM BoB_Coverage_Join_Log__c
                                                   WHERE CreatedDate < :oldestAllowed
                                                      OR Message__c = 'DELETE THIS TEST MESSAGE' ];                                               
                                                   
            if (!oldies.isEmpty()) {
                logger.newEntry(moduleName, 'Info', 'deleting log records', String.valueOf(oldies.size()) + 
                    ', ' + settings.Delete_Log_Entries_Older_Than__c, -1);              
                delete oldies;
            }
        }
        catch (Exception curse) {
            logger.newException(moduleName, 'log delete failed', curse);
        }
        
        // delete old AsyncApexJobs, re-using log record age limit calculated above
        Integer corpses = System.purgeOldAsyncJobs(oldestAllowed);
        logger.newEntry(moduleName, 'Info', 'deleted old Apex Jobs', String.valueOf(corpses), -1);
        
        
        // is this batch job chain already running?
        List<AsyncApexJob> competition = [ SELECT Id, Status, ApexClass.Name, MethodName, CreatedDate
                                             FROM AsyncApexJob
                                            WHERE Status IN ('Preparing', 'Processing')
                                              AND ApexClassId IN ( SELECT Id
                                                                     FROM ApexClass
                                                                    WHERE NAME = 'BillingsToBoBCoverage_Country_Sync_Name' OR NAME = 'BillingsToBoBCoverage_Country_Associate' )
                                         ORDER BY CreatedDate Desc ];  
        if ((competition != null  &&  !competition.isEmpty())  ||  settings.Test_Mode__c) {
            // supposed to abort any previous instances?
            if (settings.Abort_Previous_Jobs__c) {
                System.debug('aborting competition: ' + competition);
                for (AsyncApexJob job : competition)
                    System.abortJob(job.Id);    // not tested
            }
        }   
                                                    
        // create a Chatter post announcing the start of this run
        helper.postToChatterGroup(settings.Chatter_Group__c, 
            'The BillingsToBoBCoverage batch job chain has started.'); 
        
        String jobId;        
        try {                              
            // run _Associate
            BillingsToBoBCoverage_Country_Associate job = new BillingsToBoBCoverage_Country_Associate(customSetting, 
                logger.getJobId());
            jobId = Database.executeBatch(job, (Integer) settings.Scope_Size__c);                 
            
            // log this run in BoB_Coverage_Join_Log__c
            logger.newEntry(moduleName, 'Info', 'executed CountryParent Associate', 'jobId=' + jobId, -1);        
        }
        catch (Exception curse) {
            system.debug(moduleName + ' executeBatch failed: ' + curse);
            logger.newException(moduleName, 'executeBatch failed', curse);
        }     

    } // runBatch
    
} */ // BillingsToBoBCoverage_Country_Master

/*
BillingsToBoBCoverage_Country_Master master = new BillingsToBoBCoverage_Country_Master('IME Production');
master.runBatch();
*/