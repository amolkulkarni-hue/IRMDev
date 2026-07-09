/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   BillingsToBoBCoverage_Associate (Class)
**
** PURPOSE
**   Examines Billings__c and BoB_Coverage__c records, creating 
**   BoB_Coverage_Join__c records as needed.
**
** NOTES
**   Expected invocation format:
**     BillingsToBoBCoverage_Associate associate = new BillingsToBoBCoverage_Associate(customSetting);
**     associate.runBatch();
**
**   Depending on the Scope size and the maximum number of join records being created
**   per billing record, it is possible to exceed the 10,000 DML Row governor limit.
**   Therefore the execute() method will defer all joins above 10,000, and insert them
**   during a later execute() as soon as there is room. 
**
** BUNDLE SUMMARY
**   See class BillingsToBoBCoverage_Master.
**
** POTENTIAL ENHANCEMENTS
**   1. Currently the coverage mapping is tracked in a variable (coverageMap), which 
**      for maximum performance is being accessed directly by other code in this class.  
**      There would be benefits to encapsulating it within a class, to make managing the
**      size of the map data more effective and efficient.
**   2. Once a regular data partitioning scheme has been adopted, implement easy control
**       of it via BillingsToBoBCoverageJoins__c.
**   3. Automate data partitioning operating by chaining this module end-to-end to take 
**      care of the separate runs.
**        a. That would be a good time to eliminate the _Clean and _Chain modules, which
**           are no longer being used.
**
************************************************************************/

/* Commenting the entire code as part of Gitlab #24446 */

global without sharing class BillingsToBoBCoverage_Associate
{
    public BillingsToBoBCoverage_Associate(){
        
    }
}

/*
global without sharing class BillingsToBoBCoverage_Associate implements Database.Batchable<SObject>, Database.Stateful {

    // constants 
    private final static String   moduleName       = '_Associate';    
    private final        String   customSettingName;    
    private final static String   IMGA_PREFIX      = 'IM_';  
    private final static Integer  MAX_PERIODS      = 12;      // months
    private final static Integer  START_PERIOD     = 1;
    private final static Integer  END_PERIOD       = 12;
    private final static Integer  DML_ROW_LIMIT    = Limits.getLimitDMLRows() - 30;  // leave room for log insertions
    private final        String   SCHAR            = ';';
    private final        String   PRIMARY          = '';
    private final        String   NO_CID           = '';
    private final        DateTime DUMMY_TIME       = DateTime.newInstance(1970, 1, 1);
       
    // external classes
    private BillingsToBoBCoverage_Log    logger;
    private BillingsToBoBCoverage_Helper helper;    
    private BillingsToBoBCoverage_Model  model;
    
    // runtime config parameters
    private BillingsToBoBCoverageJoins__c settings; 
    private Long                          flushAfterExecutes;  // periodic flushing of log entries
    
    // effective timeframe, defaulting to entire year
    private final String  effectiveYearText;
    private final Integer effectiveYear; 
    private final String  priorYearText;
    private final Integer priorYear;
    private       Integer startPeriod = 1;
    private       Integer endPeriod   = 12;  
    
    // stateful variables hosted on behalf on _Model
    private Map<String, BillingsToBobCoverage_Model.ModelElement> coverageModel;
    private Map<String, BoB_Coverage_Join__c>                     joinRecords;     
    
    // categorize the billing records 
    private       Map<Integer, Integer> quantitiesByYear;
    
    // picklist values defined for BoB_Coverage__c.Product_Coverage__c
    private List<String> productClasses; 
    
    // cross-reference from Billings__c.Bill_Code__c to Product2.IM_Product_Class__c
    private Map<Id, Product2> billCodeIdsToProduct;    

    // name of IMGA which has been being processed most recently
    private String imgaInProgress = ''; 
    
    // newly-created join records to be inserted
    private List<BoB_Coverage_Join__c> newJoins;
    private List<BoB_Coverage_Join__c> overflowJoins;  
    private List<Bob_Coverage_Join__c> insertedJoins;
    private List<Bob_Coverage_Join__c> updatedJoins;
    
    // heap size tracking
    private Integer heapSizeMax = 0;       // largest heap size so far
        
    // IMGAs to receive special attention
    private Set<String> spotlight = new Set<String>();       
    
    // record handling counters  
    private Long totalExecutes;            // number of invocations of execute() method
    private Long totalAttempted;           // number of records handled
    private Long totalJoined;              // number of records resulting in one or more joins
    private Long totalSkipped;             // number of records which didn't pass filtering
    private Long totalNonIMGA;             // number of records which have no IMGA name
    private Long totalNoProduct;           // number of records which have no Product Class
    private Long totalExcluded;            // number of records where Bill_Code__r.Exclude_from_BoB__c is TRUE
    private Long totalNonPeriod;           // number of records with out-of-range Invoice_Date__c
    private Long totalInserted;            // number of joins created
    private Long totalUpdated;             // number of joins updated
    private Long totalErrors;              // number of errors encountered
    private Long totalWarnings;            // number of warnings encountered    
    private Long totalCoverageKeyMissing;  // number of coverage records without keys  
    private Long totalNoCoverage;          // number of billing records with no coverage
    
    // when first started processing Billings__c records
    private DateTime startOfRun;
    
    private Integer CalInsert;
    
    
    //-----------------------------------------------------------------------------------
    // constructor  
    global BillingsToBoBCoverage_Associate (String useThisCustomSetting, String jobId) {
        // access the specified custom settings
        customSettingName = useThisCustomSetting;
        settings = BillingsToBoBCoverageJoins__c.getInstance(customSettingName);
        system.debug('settings: ' + settings);
                
        // access and configure the log methods
        logger = new BillingsToBoBCoverage_Log(customSettingName);
        logger.setJobId(jobId);      
        logger.setLogImmediate(true, false, false, true, false); 
        
        // access the helper methods
        helper = new BillingsToBoBCoverage_Helper(customSettingName);
        
        // access the Element Model methods and class
        coverageModel = new Map<String, BillingsToBobCoverage_Model.ModelElement>();
        joinRecords   = new Map<String, BoB_Coverage_Join__c>();          
        model = new BillingsToBoBCoverage_Model(customSettingName, jobId, coverageModel, joinRecords);      
        
        // log this run's settings
        logger.newEntry(moduleName, 'Info', 'settings', String.valueOf(settings) + ', ' + 
            DML_ROW_LIMIT, -1);                 
        
        // set the effective year and month ranges
        effectiveYearText = settings.Focus_Year__c;
        effectiveYear     = Integer.valueOf(effectiveYearText);
        priorYear         = effectiveYear - 1;
        priorYearText     = String.valueOf(priorYear);     
        startPeriod       = Integer.valueOf(settings.Focus_Start_Period__c);
        endPeriod         = Integer.valueOf(settings.Focus_End_Period__c); 
 
        // validate the start/end period values       
        if (this.endPeriod >= this.startPeriod) {
            logger.newEntry(moduleName, 'Info', 'effective period', String.valueOf(this.effectiveYear) + 
                ': ' + String.valueOf(this.startPeriod) + ' -> ' + String.valueOf(this.endPeriod) + ', ' +
                String.valueOf(this.priorYear) + ': 1 -> 12', -1); 
        }
        else {  
            logger.newEntry(moduleName, 'Error', 'end period earlier than start', 'years: ' + 
                String.valueOf(this.startPeriod) + ', ' + String.valueOf(this.endPeriod), -1);  
        }              
        
    } // BillingsToBoBCoverage_Associate


/*======================================================================================================================
                                        START
======================================================================================================================* /    

    //-----------------------------------------------------------------------------------
    // start
    global Database.QueryLocator start (Database.BatchableContext batchContext) {
 /** /   system.debug('start() entry: ' + batchContext);
 
        // log the initial heap size
        heapSizeMax = Limits.getHeapSize();
        logger.newEntry(moduleName, 'Info', 'started, heap size: ', String.valueOf(heapSizeMax), -1);  
        
        // initialize counters for this run
        totalExecutes           = 0;
        totalAttempted          = 0;
        totalJoined             = 0;
        totalSkipped            = 0;
        totalNonIMGA            = 0;
        totalNoProduct          = 0;        
        totalExcluded           = 0;
        totalNonPeriod          = 0;     
        totalInserted           = 0;
        totalUpdated            = 0;
        totalErrors             = 0; 
        totalWarnings           = 0;
        totalCoverageKeyMissing = 0;
        totalNoCoverage         = 0;
        startOfRun              = DUMMY_TIME;
        
        CalInsert=0;
        // determine how often to flush the log
        flushAfterExecutes = Long.valueOf(String.valueOf(settings.Flush_Log_After_Executes__c));  
        
        // are there any IMGAs in the spotlight?
        if (!String.isEmpty(settings.Spotlight__c)) {
            String[] celebrities = settings.Spotlight__c.split(',');
            spotlight.addAll(celebrities);
        }
        
        // create a Chatter post announcing the start of this run
        helper.postToChatterGroup(settings.Chatter_Group__c, 
            'The BillingsToBoBCoverage_Associate batch job has started.');        
                                        
        // determine the Product Class picklist values defined for BoB_Coverage__c.Product_Coverage__c
        productClasses = new List<String>();
        Schema.DescribeFieldResult field = BoB_Coverage__c.Product_Coverage__c.getDescribe();
        for (Schema.PicklistEntry each : field.getPicklistValues())
            productClasses.add(each.getLabel());  
//** /   system.debug('productClasses: ' + productClasses);
//** /   logger.newEntry(moduleName, 'Debug', 'product codes', String.valueOf(productClasses.size()) + 
//** /       ', ' + String.valueOf(productClasses), -1); 

        // instantiate the join record holding pens
        newJoins      = new List<BoB_Coverage_Join__c>();
        overflowJoins = new List<BoB_Coverage_Join__c>();
        insertedJoins = new List<BoB_Coverage_Join__c>();
        updatedJoins  = new List<BoB_Coverage_Join__c>(); 
        
        // instantiate the per-year billings counters
        quantitiesByYear = new Map<Integer, Integer>();

   
        //_______________________________________________________________________
        // build cross-reference from Bill Code to Product Class   
        billCodeIdsToProduct = new Map<Id, Product2>();             
        try {
            // NOTE: "IsActive = TRUE" apparently isn't a requirement
            List<Product2> products = [ SELECT Id, IM_Product_Class__c, Exclude_from_BoB__c
                                          FROM Product2
                                         WHERE IM_Product_Class__c != null ];
//** /       system.debug('products: ' + products.size() + ', ' + products);
//** /       logger.newEntry(moduleName, 'Debug', 'products', String.valueOf(products.size()) + ', ' + 
//** /           String.valueOf(products), -1);

            for (Product2 prod : products)
                billCodeIdsToProduct.put(prod.Id, prod);                                        
        }
        catch (Exception curse) {
            system.debug('Product2 fetch failed: ' + curse);
            logger.newException(moduleName, 'Product2 fetch failed', curse);
        }
//** /   system.debug('billCodeIdsToProduct: ' + billCodeIdsToProduct.size() + ', ' + billCodeIdsToProduct); 
//** /   logger.newEntry(moduleName, 'Debug', 'billCodeIdsToProduct', 
//** /       String.valueOf(billCodeIdsToProduct.size()) + ', ' + String.valueOf(billCodeIdsToProduct), -1);   

        
        //_________________________________
        // assemble the complete main query
        
        // assemble the query pieces    
        String fullQuery = '   SELECT ' + settings.Query_Associate_Select__c   +                                      +  
                           '     FROM ' + settings.Query_Associate_From__c + ' ';

        // append the multi-part additions (if any) to the WHERE clause 
        if (String.isNotEmpty(settings.Query_Associate_Where__c))
            fullQuery += ' WHERE ' + settings.Query_Associate_Where__c + ' ';
        if (String.isNotEmpty(settings.Query_Associate_Where_2__c))
            fullQuery += settings.Query_Associate_Where_2__c + ' ';
        if (String.isNotEmpty(settings.Query_Associate_Where_3__c))
            fullQuery += settings.Query_Associate_Where_3__c + ' ';
                    
        // append the ORDER BY clause (if any)
        // This can negatively impact performance!                  
        if (!Test.isRunningTest()&&String.isNotEmpty(settings.Query_Associate_Order_By__c))
            fullQuery += ' ORDER BY ' + settings.Query_Associate_Order_By__c;
            
        // NOTE: GROUP BY clause is NOT supported, for performance reasons                            
         
        // append the LIMIT clause (if any) - useful for limiting test runtimes                 
        if (String.isNotEmpty(settings.Query_Associate_Limit__c))
            fullQuery += ' ' + settings.Query_Associate_Limit__c; 
         system.debug('fullQuery in BobCoverageAssociate'+fullQuery);                       
        logger.newEntry(moduleName, 'Info', 'query', fullQuery, -1);      

 /** /   system.debug('start() exit');
        return Database.getQueryLocator(fullQuery); 
                  
    } // start


/*======================================================================================================================
                                        EXECUTE
======================================================================================================================* /    
    
    //-----------------------------------------------------------------------------------
    // execute  
    global void execute (Database.BatchableContext batchContext, Billings__c[] scope) { 
                         
        List<BoB_Coverage__c> imgaRelated;
        String                marketName = ''; 
        String                productClass, imgaName, countryName;  
        Integer               billPeriod, billYear;    

        // supposed to cease processing after a certain number of Join records have been inserted?
        // (tpically used together with the Scope_Size__c and Query_Associate_Limit__c settings)
        if (settings.Join_Limit__c > 0  &&  totalInserted >= settings.Join_Limit__c)
            return;
            
 /** /   system.debug('execute() entry, scope: ' + scope);                       
//** /   logger.newEntry(moduleName, 'Debug', 'processing scope', coverageModel.size() + ', ' + 
//** /       String.valueOf(scope.size()) + ', ' + String.valueOf(scope), 25); 
                 
        // track the date/time of execute method's first invocation (after Preparing time)         
        if (startOfRun == DUMMY_TIME)
            startOfRun = DateTime.now();
        
        // keep track of how many times this method is called
        totalExecutes++;
            
        // keep track of how many billing records are being processed 
        if (scope != null)      
            totalAttempted += scope.size();
        
        // ignoring leading records?    
        if (totalAttempted < settings.Restart_Offset__c) {
            system.debug('skipping ' + totalAttempted);
            logger.newEntry(moduleName, 'Info', 'skipping', String.valueOf(totalAttempted), 10);
            return;
        }    

        
        //___________________________________________   
        // scan this scope's worth of billing records        
        for (Billings__c billing : scope) {
//** /       system.debug('billing: ' + billing);
//** /       logger.newTrace(String.valueOf(billing));  

            // have we just transitioned to a different IMGA's billing records?
            if (billing.IMGA_Name_Text__c != imgaInProgress) {
//** /           logger.newTrace('From \'' + imgaInProgress + '\' to \'' + 
//** /               billing.IMGA_Name_Text__c + '\', ' + String.valueOf(totalAttempted));

                // generate the join records (if any) for the previous IMGA
                defineJoins();
                createJoins();
                // clear the Coverage Model for this next IMGA, optionally saving it first
                if (spotlight.contains(imgaInProgress))
                   model.modelClear(true); 
                else
                    model.modelClear(false);

                
                //_________________________
                // advance to the next IMGA 
                imgaInProgress = billing.IMGA_Name_Text__c;                    

                // pull all the coverage records related to this IMGA
                try {
                    imgaRelated = [ SELECT Id, Account__r.IM_IMGA_Indexed__c, Country_Coverage__c,
                                           Effective_Start_Period__c, Effective_Year__c,
                                           Effective_End_Period__c, Name, Parent_Billing_Market__c,
                                           Parent_Billing_Market__r.Name, Product_Coverage__c
                                      FROM BoB_Coverage__c
                                     WHERE Account__r.IM_IMGA_Indexed__c = :imgaInProgress
                                       AND Effective_Year__c = :effectiveYearText ];
                }
                catch (Exception curse) {
                    system.debug('IMGA accounts fetch failed: ' + curse);
                    logger.newException(moduleName, 'IMGA accounts fetch failed', curse);
                }        
//** /           system.debug('imgaRelated coverage records: ' + imgaRelated.size() + ', ' + imgaRelated);
//** /           logger.newEntry(moduleName, 'Gated', 'imgaRelated', String.valueOf(imgaRelated.size()) + 
//** /               ', ' + String.valueOf(imgaRelated), -1);

    
                //__________________________________________
                // set up the model for this IMGA's coverage  
                BillingsToBobCoverage_Model.ModelElement target;          
                for (BoB_Coverage__c coverage : imgaRelated) { 
//** /               system.debug('coverage: ' + coverage);
//** /               logger.gateOpen(false);
//** /               if (helper.idMatches(coverage.Id, 'a2B80000000sf4m'))
//** /                   logger.gateOpen(true); 
//** /               logger.newEntry(moduleName, 'Gated', 'coverage stream', String.valueOf(coverage), 25); 
                    
                    // resolve some text properties
                    imgaName    = helper.strDef(coverage.Account__r.IM_IMGA_Indexed__c, '');                
                    countryName = helper.strDef(coverage.Country_Coverage__c,           '');
                    marketName  = helper.strDef(coverage.Parent_Billing_Market__r.Name, ''); 
                    
                    // does this coverage record reference any Product Classes?    
                    if (coverage.Product_Coverage__c != null) {    
                        // identify the Product Classes associated with this coverage       
                        List<String> productClasses = coverage.Product_Coverage__c.split(SCHAR);
//** /                   system.debug('productClasses: ' + productClasses);
//** /                   logger.newEntry(moduleName, 'Gated', 'product classes', imgaName + ', ' + 
//** /                       countryName + ', ' + marketName + ', ' + String.valueOf(productClasses.size()) + ', ' + 
//** /                       String.valueOf(productClasses), 25);    

                        // determine coverage range
                        Integer coverageYear  = Integer.valueOf(coverage.Effective_Year__c);
                        Integer coverageStart = Integer.valueOf(coverage.Effective_Start_Period__c);
                        Integer coverageEnd   = Integer.valueOf(coverage.Effective_End_Period__c);  
                        
                        // resolve this coverage record's country parameters
                        List<String> footprint = new List<String>{ countryName };
                        if (footprint[0] == 'North America') {
                            footprint = new List<String>{ 'North America', 'United States', 'Canada' };
//** /                       logger.newEntry(moduleName, 'Debug', 'coverage North America', 
//** /                           String.valueOf(coverage), 25);
                        }
//** /                   system.debug('footprint: ' + footprint);
//** /                   logger.newEntry(moduleName, 'Debug', 'footprint', String.valueOf(footprint), 25)                         ;
                        
                        // create elements for this coverage record based on its country, product class
                        // market/Primary and time period - but leaving out Customer ID                      
                        for (String targetCountry : footprint) {
                            for (String product : productClasses) {
                                for (Integer lpcnt = START_PERIOD; lpcnt <= END_PERIOD; lpcnt++) {                                 
                                    // always included in prior year
                                    target = model.attachPlayer(model.modelKey(imgaName, targetCountry, 
                                        marketName, product, priorYear, lpcnt), coverage.Id,
                                        coverage.Parent_Billing_Market__c); 
                                    
                                    // only include effective year if in range    
                                    if (coverageYear == effectiveYear  &&  
                                        lpcnt >= coverageStart  &&  lpcnt <= coverageEnd) {
                                        target = model.attachPlayer(model.modelKey(imgaName, targetCountry, 
                                            marketName, product, effectiveYear, lpcnt), coverage.Id,
                                            coverage.Parent_Billing_Market__c);                                                 
                                    }
                                }
                            }
                        }
                    }                                 
                    else {
 /** /                   logger.newEntry(moduleName, 'Warning', 'coverage with no Product Class', 
 /** /                        String.valueOf(coverage), 25);
                    }
//** /               model.dumpCoverageModel('coverage', 0, '', 'Gated', true); 
//** /               logger.gateOpen(false);                   
                }
            }


            //______________________________
            // filtering the billing records
                       
//** /        logger.gateOpen(false);
//** /        if (helper.idMatches(billing.Id, 'a2G80000004yayf')  ||  
//** /            helper.idMatches(billing.Id, 'a2G80000004yayg')  ||
//** /            billing.Amount__c < 0) 
//** /            logger.gateOpen(true);
            
            // Filter Stage 1 - IMGA name required
            if (String.isEmpty(billing.IMGA_Name_Text__c)) {
 /** /           logger.newEntry(moduleName, 'Debug', 'non-IMGA', String.valueOf(billing), 25);              
                totalNonIMGA++;
                totalSkipped++;
                continue;
            }
            
            // Filter Stage 2 - Product Class required
            productClass = '';
            Product2 billProduct = billCodeIdsToProduct.get(billing.Bill_Code__c);
            if (billProduct != null)
                productClass = billProduct.IM_Product_Class__c;            
            if (String.isEmpty(productClass)) {
//** /           logger.newEntry(moduleName, 'Debug', 'no Product Class', String.valueOf(billing), 10);              
                totalNoProduct++;
                totalSkipped++;
                continue;
            }     
            
            // Filter Stage 3 - billing must not be marked Excluded
            if (billing.Exclude_Bill_Code_from_BoB__c.equalsIgnoreCase('Exclude')) {
//** /           logger.newEntry(moduleName, 'Gated', 'excluded', String.valueOf(billing), 10);              
                totalExcluded++;
                totalSkipped++;
                continue;
            }             
                      
            // Filter Stage 4 - billing must have an Invoice Date
            if (billing.Invoice_Date__c != null) {
                billYear    = billing.Invoice_Date__c.year();
                billPeriod  = billing.Invoice_Date__c.month(); 
            }
            else {
                logger.newEntry(moduleName, 'Unusual', 'empty Invoice Date', String.valueOf(billing), 1); 
                totalWarnings++;   
                totalSkipped++;         
                continue;
            } 
            
            // keep track of the number of billing records per year
            if (quantitiesByYear.containsKey(billYear))
                quantitiesByYear.put(billYear, quantitiesByYear.get(billYear) + 1);
            else
                quantitiesByYear.put(billYear, 1);
            
            // Filter Stage 5 - must have been invoiced within the target time period(s)
            Boolean skippingThisBilling = true;
            if (billYear == priorYear)            
                skippingThisBilling = false;   // it's a keeper
            if (billYear == effectiveYear  &&  billPeriod >= startPeriod  &&  billPeriod <= endPeriod) 
                skippingThisBilling = false;   // it's a keeper
            if (skippingThisBilling == true) {
//** /           logger.newEntry(moduleName, 'Gated', 'invoice date out of range', String.valueOf(billYear) + 
//** /               ', ' + String.valueOf(billPeriod) + ', ' + billing.Invoice_Date__c + ', ' + 
//** /               String.valueOf(skippingThisBilling) + ', ' + String.valueOf(billing), 25); 
                totalNonPeriod++;
                totalSkipped++;
                continue;
            }
                
            // this billing record passes the filters and WILL be processed                   
            totalJoined++;

            
            //_______________________________________________________________
            // include this billing record in the appropriate Amount roll-ups
            String localMarket = helper.strDef(billing.Parent_Billing_Market__c, '');
            String coverageKey = model.modelKey(billing.IMGA_Name_Text__c, 
                                                helper.strDef(billing.Country_Coverage__c, ''), 
                                                localMarket,
                                                productClass,
                                                billYear,
                                                billPeriod);
            BillingsToBobCoverage_Model.ModelElement billingElement; 
            billingElement = model.addAmount(coverageKey, billing.Customer_Account__r.Id, 
                billing.Amount__c, billing.CurrencyIsoCode, billing.Billing_Market__r.Parent_Billing_Market__c);                   
                
            // keeping track of which Billings__c records go with which Bob_Coverage_Join__c records?
            if (settings.Track_Billings__c)
                billingElement.billingSet.add(billing.Id);
                           
//** /       logger.newEntry(moduleName, 'Gated', 'billing - bottom loop', String.valueOf(billingElement) + ', ' + 
//** /           String.valueOf(billing), 25);
        }
 
        // store any unsaved trace entries
//** /   logger.traceFlush(); 

        
        //___________________________________________________
        // keep track of the highest size reached by the heap
        Integer heapUsage = Limits.getHeapSize();
        if (heapUsage > heapSizeMax)
            heapSizeMax = heapUsage;    
        
        // periodically flush the log entries, so progress can be monitored
        if (Math.mod(totalExecutes, flushAfterExecutes) == 0)        
            logger.logFlush();
            
        //cal the insertion for every batch 
        defineJoins();
        createJoins();
        model.clearAmounts();
                
 /** /
 
    } // execute


/*======================================================================================================================
                                        FINISH
======================================================================================================================* /    
    
    //-----------------------------------------------------------------------------------
    // finish   
    global void finish (Database.BatchableContext batchContext) {
 /** /   system.debug('finish() entry');
 /** /   logger.newEntry(moduleName, 'Info', 'finish() entry', imgaInProgress, -1);   
 
        // take care of any unfinished business
//** /   logger.gateOpen(true);         
        defineJoins();
        createJoins();
        
        // take a final snapshot of the Coverage Model  
//** /   model.dumpCoverageModel('finish', 0, '', 'Debug', true);
        
        // store any unsaved trace entries
        logger.traceFlush();
        
        // are there any new join records not yet inserted?
        if (overflowJoins.size() > 0) {
            logger.newEntry(moduleName, 'Error', 'finish: some joins weren\'t inserted', overflowJoins.size() + 
                ', first: ' + String.valueOf(overflowJoins[0]), -1);
        }
         
        // construct an execution summary
        String jobSummary = '\n    Total Execute Calls:        ' + totalExecutes.format().leftPad(7)           +
                            '\n    Total Batch Size:           ' + totalAttempted.format().leftPad(7)          +        
                            '\n    Billing Records Joined:     ' + totalJoined.format().leftPad(7)             +
                            '\n    Billing Records Skipped:    ' + totalSkipped.format().leftPad(7)            +
                            '\n    Billing Records non-IMGA:   ' + totalNonIMGA.format().leftPad(7)            +
                            '\n    Billing Records no Product: ' + totalNoProduct.format().leftPad(7)          +
                            '\n    Billing Records Excluded:   ' + totalExcluded.format().leftPad(7)           +
                            '\n    Billing Records non-Period: ' + totalNonPeriod.format().leftPad(7)          +                          
                            '\n    Join Records Inserted:      ' + totalInserted.format().leftPad(7)           +
                            '\n    Join Records Updated:       ' + totalUpdated.format().leftPad(7)            +
                            '\n    Errors:                     ' + totalErrors.format().leftPad(7)             +                            
                            '\n    Warnings:                   ' + totalWarnings.format().leftPad(7)           +
                            '\n    Coverage Key Missing:       ' + totalCoverageKeyMissing.format().leftPad(7) +
                            '\n    No Coverage:                ' + totalNoCoverage.format().leftPad(7)         +                            
                            '\n\nStart Time: '                   + startOfRun.format('dd/MM/yyyy HH:mm:ss');
                               
        // log this completion in BoB_Coverage_Join_Log__c
        logger.newEntry(moduleName, 'Info', 'finished', jobSummary + '; Max Heap Size: ' + heapSizeMax, -1); 
        
        // create a Chatter post summarizing the outcome of this run
        helper.postToChatterGroup(settings.Chatter_Group__c, 
            'The BillingsToBoBCoverage_Associate batch job has completed.' + jobSummary);        
 
 /** /   logger.newEntry(moduleName, 'Debug', 'billing record counts per year', 
 /** /       String.valueOf(quantitiesByYear), -1);
        
        // store any unsaved log entries
        logger.logFlush();
        
 /** /   system.debug('finish() exit');  
       
    } // finish      


/*======================================================================================================================
                                       COMMON METHODS
======================================================================================================================* /    
    
    //-----------------------------------------------------------------------------------
    // define all pending joins
    global void defineJoins () {
//** /   system.debug('defineJoins');
//** /   logger.newEntry(moduleName, 'Gated', 'defineJoins() entry', Integer.valueOf(newJoins.size()) + ', ' + 
//** /       Integer.valueOf(overflowJoins.size()), 10);       
//** /   model.dumpCoverageModel('defineJoins entry: ' + String.valueOf(totalExecutes) + ', ' + 
//** /       String.valueOf(totalJoined) + ', ' + String.valueOf(newJoins.size()) + ', ' + 
//** /       String.valueOf(overflowJoins.size()), 0, '', 'Debug', true);
 
        // step through the model's elements
        List<String> headers;
        for (BillingsToBobCoverage_Model.ModelElement element : model.getElements()) {
            // parse this element's key
            headers = element.elementKey.split(BillingsToBobCoverage_Model.SEPERATOR);
//** /       system.debug('headers: ' + headers);
//** /       logger.newEntry(moduleName, 'Gated', 'headers', String.valueOf(headers), 25);
            
//** /       if (headers[2] == ''  &&  headers[3] == 'Secure Shredding'  &&  
//** /           headers[4] == '2012')
//** /           logger.gateOpen(true);
//** /       else
//** /           logger.gateOpen(false);
 
            // does this element need to be represented by one or more joins?
            if (element.dirty) {                              
                // is this a prior year billing?
                Boolean priorYearToDate = false;
                if (headers[4] == priorYearText)
                    priorYearToDate = true;          
                     
                // is this period within the effective range?       
                Boolean withinEffectivePeriodRange = false;
                Integer month = Integer.valueOf(headers[5]);
                if (priorYearToDate  ||  
                    (month >= startPeriod  &&  month <= endPeriod))
                    withinEffectivePeriodRange = true; 
                    
        // Locals    := Account Executives, Sales Directors and VPs (headers[2] isn't empty) 
        // Primaries := National Account Managers                   (headers[2] is empty)                    
                    
                // start with any Local coverage records attached to this element
                Set<Id> associated = new Set<Id>();
                associated.addAll(element.players);
                element.referenceCount++;                
                
                // include Primaries for this IMGA, country, product and period                 
                Id[] cousins = model.getPlayers(model.modelKey(headers[0], headers[1], PRIMARY,
                    headers[3], Integer.valueOf(headers[4]), Integer.valueOf(headers[5])));
                if (cousins != null)
                    associated.addAll(cousins);                                  
                    
                // define each new join
                for (Id coverage : associated) {
                   for (Id custID : element.amountPerAccount.keySet()) {//CAy                                                
                        element.publishCount++;
                        
//** /                   system.debug('coverage: ' + coverage);                          
                        BoB_Coverage_Join__c newbie = new BoB_Coverage_Join__c();
                    
                        newbie.BoB_Coverage__c                          = coverage;
                       // newbie.Unique_Handle__c                         = element.elementKey + SCHAR + coverage;
                        newbie.Billings__c                              = null;           // DEPRECATED
                        newbie.Billing_Period_Field_Update__c           = headers[5];
                      newbie.Amount_Total__c                          = element.amountPerAccount.get(custID);//CAy   
//CAn                        newbie.Amount_Total__c                          = element.amount;     
                        newbie.CurrencyIsoCode                          = element.CurrencyIsoCode;
                        newbie.Parent_Billing_Market__c                 = (Id) element.parentBillingMarket;
                       newbie.Customer_Id__c                           = custID;//CAy  
//CAn                        newbie.Customer_Id__c                           = null;     
                        newbie.Product_Class_Text__c                  = headers[3].capitalize();   // restore Sentence Case
                        newbie.Invoice_Date__c                          = Date.newInstance(Integer.valueOf(headers[4]), Integer.valueOf(headers[5]), 1);
                        newbie.Include_in_YTD_Reporting__c              = withinEffectivePeriodRange;
                        newbie.Include_in_Prior_Year_Roll_Up_Summary__c = priorYearToDate;   
                            
//** /                   system.debug('newbie: ' + newbie);   
//** /                   logger.newEntry(moduleName, 'Gated', 'newbie', String.valueOf(newbie), 25);                        
            
                        // is there room for another join under the DML row limit?
                        if (newJoins.size() < DML_ROW_LIMIT) { 
                            // insert this join during this execute() call                    
                            newJoins.add(newbie);
                        }
                        else {
                            // defer inserting this join until a later execute() call
                            overflowJoins.add(newbie); 
                        }     
//** /                   logger.newEntry(moduleName, 'Gated', 'pending', String.valueOf(newJoins.size()) + 
//** /                       ', ' + String.valueOf(overflowJoins.size()), 25); 
                   }//CAy  
                }
                
                // prevent repeat processing of this element
                element.dirty = false;
            }
            else {
                // does this element show other activity?
               if (element.amountPerAccount.size() > 0  &&  element.publishCount == 0) {//CAy   
//CAn                if (element.amount > 0.0  &&  element.publishCount == 0) {     
 /** /               logger.newEntry(moduleName, 'Unusual', 'skipped an active element', 
 /** /                   String.valueOf(element), 10);
                }
            }               
        }
//** /   logger.newEntry(moduleName, 'Gated', 'defineJoins() exit', Integer.valueOf(newJoins.size()) + ', ' + 
//** /       Integer.valueOf(overflowJoins.size()), 10);  

        // record a snapshot of current Coverage Model       
//** /   model.dumpCoverageModel('defineJoins exit: ' + String.valueOf(totalExecutes) + ', ' + 
//** /       String.valueOf(totalJoined) + ', ' + String.valueOf(newJoins.size()) + ', ' + 
//** /       String.valueOf(overflowJoins.size()), 0, '', 'Gated', true);
     
    } // defineJoins  
    
     
    //-----------------------------------------------------------------------------------
    // insert/update all pending joins
    global void createJoins () {        
        // are there any records pending?
        if (!newJoins.isEmpty()  ||  !overflowJoins.isEmpty()) {                                              
            // OK to actually make database changes?   
            if (settings.Enable_Database_Changes__c) {
                // determine how many more DML rows can be processed during this execute()                    
                Integer remainingRows = DML_ROW_LIMIT - Limits.getDMLRows();
                if (remainingRows > DML_ROW_LIMIT  ||  remainingRows < 0)
                    remainingRows = DML_ROW_LIMIT;
                    
                // will the newJoins load of records stay below the DML Rows governor limit?
                Integer currRows = newJoins.size();                    
                if (currRows < remainingRows) { 
                    // are there any deferred records
                    if (overflowJoins.size() > 0) {
                        // include as many deferred records as will fit
                        Integer headroom = remainingRows - currRows;
 /** /                   logger.newEntry(moduleName, 'Unusual', 'including deferred insertions', 
 /** /                       String.valueOf(headroom) + ', ' + String.valueOf(currRows) + ', ' +
 /** /                       String.valueOf(remainingRows), 10);                            
                        for (Integer lpcnt = 0; lpcnt <= headroom; lpcnt++) {
                            // include the oldest deferred record
                            newJoins.add(overflowJoins[0]);
                            overflowJoins.remove(0);
                            currRows++;
                            
                            //madhu added on 7/25/13
                            if(overflowJoins.isEmpty())
                            break;
                        }                           
                    }                       
                }
                // are there more newJoin records than can be accomodated?
                else if (currRows > remainingRows) {
                    Integer reduction = currRows - remainingRows;
 /** /               logger.newEntry(moduleName, 'Unusual', 'deferring some insertions', 
 /** /                   String.valueOf(reduction) + ', ' + String.valueOf(currRows) + ', ' +
 /** /                   String.valueOf(remainingRows), 10);                         
                    for (Integer lpcnt = 0; lpcnt <= reduction; lpcnt++) {
                        // defer the oldest new record
                        overflowJoins.add(newJoins[0]);
                        newJoins.remove(0);
                        currRows--;
                        
                        //madhu added on 7/25/13
                         if(newJoins.isEmpty())
                         break;
                    }                           
                }
                
                // divide the pending joins based on inserted vs. updated
                BoB_Coverage_Join__c oldie;
                for (Integer lpcnt = 0; lpcnt < newJoins.size(); lpcnt++)    {
                  
                        insertedJoins.add(newJoins[lpcnt]); 
                        totalInserted++;                    
                                    
                }                                               
                   
                // are there join records to be inserted? 
                Database.SaveResult[] results;  
                if (insertedJoins.size() > 0) {   
                    try {                                                                                                          
                        // insert the new join records, despite any per-record failures                                          
                        results = Database.insert(insertedJoins, false); 
                        reportDatabaseFailures(results, 'insert');
                    }
                    catch (Exception curse) {
                        system.debug('insert failed: ' + curse);
                        logger.newException(moduleName, 'insert failed', curse);
                    }
                }
                
               
                                        
                // clear the holding pens for subsequent re-use  
                newJoins.clear();
                insertedJoins.clear();
              
            }
        }      
    } // createJoins
    
     
    //-----------------------------------------------------------------------------------
    // report any DML failures
    global void reportDatabaseFailures (Database.SaveResult[] results, String dmlType) {                     
        // are there results from the Database.upsert? 
        if (results != null  &&  !results.isEmpty()) {   
            // evaluate the outcome for each record
            for (Integer lpcnt = 0; lpcnt < results.size(); lpcnt++) {
                // unsuccessful?
                if (!results[lpcnt].isSuccess()) {
                    // keep count of all failures as errors
                    totalErrors++;                            
                    
                    // log only the first and last (if more than one) failures
                    if (lpcnt == 0  ||  lpcnt == (results.size() - 1)) {
                        Database.Error[] recordErrors = results[lpcnt].getErrors();
                        logger.newEntry(moduleName, 'Error', dmlType + ' failed', 
                            'DML row '   + lpcnt                           +
                            ' of '       + results.size()                  +
                            ', Errors: ' + String.valueOf(recordErrors)    +                                     
                            ', Join: '   + String.valueOf(newJoins[lpcnt]),
                            25); 
                    }
                }
               /* else {
                    if (dmlType == 'Insert') {
                        // make an in-memory, partial copy of this record for future updateability                  
                        model.joinRecordPut(newJoins[lpcnt].Unique_Handle__c, 
                            new BoB_Coverage_Join__c(id = results[lpcnt].getId(), 
                            Amount_Total__c = newJoins[lpcnt].Amount_Total__c));     
                    }                               
                } * /              
            }                                   
        }   
    } // reportDatabaseFailures      

} // class BillingsToBoBCoverage_AssociateoBoBCoverage_Associate
*/
/*
List<BoB_Coverage_Join__c> joins = [ SELECT Id FROM BoB_Coverage_Join__c LIMIT 10000 ];
system.debug('count=' + joins.size());
delete joins;
*/