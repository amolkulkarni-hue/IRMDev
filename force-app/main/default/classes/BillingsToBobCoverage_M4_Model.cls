public class BillingsToBobCoverage_M4_Model{public BillingsToBobCoverage_M4_Model(){string t='1';}}
    /*
    // constants
    private final        String  moduleName       = '_Model';
    public  final static String  SEPERATOR        = ';';
    public  final        Integer MAX_BUFFER_CHARS = 32500;
    public  final        String  PRIMARY          = '';
    public  final        String  NO_FILTER        = '';
   
    // model of all BoB Coverage elements currently being processed
    private Map<String, ModelElement> coverageModel;
    
    // keep track of which Join records have been inserted
    private Map<String, Aggregate_Storage_Revenue__c> joinRecords; 
    
    //  most recently used model key
    public String compositeKey;  
    
    // external classes
    private BillingsToBoBCoverage_Log logger;     

    
    //-----------------------------------------------------------------------------------
    // constructor  
    public BillingsToBobCoverage_M4_Model (String useThisCustomSetting, String jobId,
        Map<String, ModelElement> cModel, Map<String, Aggregate_Storage_Revenue__c> jRecords) {
 		system.debug('BillingsToBobCoverage_M4_Model');
 
        // use the persistent collections provided by _Associate
        this.coverageModel = cModel;
        this.joinRecords   = jRecords;
        
        // access the log methods
        logger = new BillingsToBoBCoverage_Log(useThisCustomSetting);
        logger.setJobId(jobId);          
        logger.setLogImmediate(true, true, true, true, true);
        
    } // BillingsToBobCoverage_Model  
    
                 
    //-----------------------------------------------------------------------------------
    // model element per IMGA/Country/Market/ProductClass
    public class ModelElement {
    
        public String               elementKey;            // composite key
        public Map<String, Decimal> amountPerAccount; // Total/aggregate amounts per Customer Account  //CAy
//CAn        public Decimal              amount;                // Total/aggregate amount    
       // public String               CurrencyIsoCode;       // Amount's currency
        public Map<Id, String>      CurrencyIsoCode;
        public Id                   parentBillingMarket;   // Market ID (if any)
        
        public List<Id>             players;               // BoB_Coverage__c records to be relatedme   
             
        public Set<Id>              billingSet;            // Set of associated Billings__c records
        
        public Integer              referenceCount;        // number of times this record's players are applied
        public Integer              publishCount;          // number of times this record was processed
        public Integer              updateCount;           // number of times this record's amount(s) have been updated
        public Boolean              dirty;                 // whether this element needs to be Upserted

        // constructor 
        private ModelElement (String target) {
            // establish defaults
            this.elementKey          = target;
            this.amountPerAccount    = new Map<String, Decimal>();  //CAy
//CAn            this.amount              = 0.0;   
            this.CurrencyIsoCode    = new Map<Id, String>();    
            this.players             = new List<Id>();
            this.billingSet          = new Set<Id>();                       
            this.referenceCount      = 0;
            this.publishCount        = 0;
            this.updateCount         = 0; 
            this.dirty               = false;           
        
        } // ModelElement
    
    } // ModelElement         
    

    //-----------------------------------------------------------------------------------
    // add/overwrite an element to the coverageModel    
    public ModelElement modelPut (String elementKey, Id marketId) {
		system.debug('modelPut: ' + elementKey);     
        // save most-recently-used element key
        compositeKey = elementKey;
        System.debug('coverageModel in modelput=='+coverageModel);
        // already exists?
        if (coverageModel.containsKey(elementKey)) {
			 system.debug('modelPut ' + elementKey + ' already exists');         
            return coverageModel.get(elementKey);
        }
        else {
            // create a new model element           
			system.debug('modelPut creating ' + elementKey); 
// ** /       logger.newEntry(moduleName, 'Gated', 'modelPut creating', elementKey, 25);         
            ModelElement newbie        = new ModelElement(elementKey);
            if (marketId != null)     // don't overwrite a Local with a Primary
                newbie.parentBillingMarket = marketId;
            coverageModel.put(elementKey, newbie);
            System.debug('coverageModel with newbie==='+coverageModel);
            return newbie;
        }
    
    } // modelPut      


    //-----------------------------------------------------------------------------------
    // add to an amount of a coverageModel element    
    public ModelElement addAmount (String elementKey, Id custId, Decimal delta, 
        String currencyCode, Id market) {
		system.debug('addAmount: ' + elementKey + ', ' + delta);
// ** /   logger.newEntry(moduleName, 'Gated', 'addAmount', elementKey + ', ' + 
// ** /       String.valueOf(delta).deleteWhitespace(), 25);
        
        // ensure the element exists
        ModelElement target = modelPut(elementKey, null);
        
        // update the amount for the specified Customer Account ID
        Decimal amount = 0.0;  //CAy
        if (target.amountPerAccount.containsKey(custId))  //CAy
            amount = target.amountPerAccount.get(custId);  //CAy
        amount += delta;  //CAy
        target.amountPerAccount.put(custId, amount);  //CAy
//CAn        target.amount          += delta;             
      //  target.CurrencyIsoCode  = currencyCode;
      
         if (!target.CurrencyIsoCode.containsKey(custId)) {
             target.CurrencyIsoCode.put(custId, currencyCode);
        }
        
        // ensure the Parent Billing Market association has been made
        if (target.parentBillingMarket == null)
            target.parentBillingMarket = market;
            
  / *      Set<Id> unique = new Set<Id>();
        unique.addAll(target.players);
         if (!unique.contains(coverage)) {
         system.debug('attachPlayer adding ' + coverage + ' to ' + elementKey);            
            target.players.add(coverage);
            }   
   * /       
            
        target.dirty = true;        
        target.updateCount++;
        
        return target;
            
    } // addAmount   
         

    //-----------------------------------------------------------------------------------  
    // add unique coverage record to a coverageModel element    
    public ModelElement attachPlayer (String elementKey, Id newPlayer, Id marketId) {
    
		system.debug('attachPlayer: ' + elementKey + ', ' + newPlayer);
// ** /   logger.newEntry(moduleName, 'Gated', 'attachPlayer', elementKey + ', ' + 
// ** /       String.valueOf(newPlayer), 25); 
 
        // ensure the model element exists
        ModelElement target = modelPut(elementKey, marketId); 
         System.debug('target.players in attach player==='+target.players);       
        // build a Set from the existing player List
        Set<Id> unique = new Set<Id>();
        unique.addAll(target.players);
        
        System.debug('unique in attach player==='+unique);
        System.debug('newPlayer in attach player==='+newPlayer);
        System.debug('unique.contains(newPlayer)==='+unique.contains(newPlayer));
        // is the new Id not already in the Set/List?
        if (!unique.contains(newPlayer)) {
			system.debug('attachPlayer adding ' + newPlayer + ' to ' + elementKey);            
            target.players.add(newPlayer);
        }
// ** /   logger.newEntry(moduleName, 'Gated', 'attachPlayer players', String.valueOf(target.players), 25);           
        
        return target;
        
    } // attachPlayer 


    //-----------------------------------------------------------------------------------
    // fetch the unique coverage records of a coverageModel element    
    public List<Id> getPlayers (String elementKey) {
        // does the specified element exist?
        system.debug('******'); 
        System.debug('elementKey in getPlayers=='+elementKey);
        System.debug('coverageModel in getPlayers=='+coverageModel);
        ModelElement target;
        if(Test.isRunningTest() && coverageModel != Null && !coverageModel.isEmpty()){
            for(String key: coverageModel.keySet()){
               	target = coverageModel.get(key);
                break;
            }
        }else            
        	target = coverageModel.get(elementKey);   
        System.debug('target=='+target);
        if (target != null) {
            target.referenceCount++;
            return target.players;
        }
        else {
            // probably means there are no Primaries defined for the current key
            logger.newEntry(moduleName, 'Debug', 'getPlayers: no such Primary coverage?', elementKey, 10);
            return null;
        }
        
    } // getPlayers  
       

    //-----------------------------------------------------------------------------------
    // return all the elements currently in the model   
    public List<ModelElement> getElements () {      
        return coverageModel.values();
        
    } // getElements


    //-----------------------------------------------------------------------------------
    // add/overwrite an element to the coverageModel    
   / * public void joinRecordPut (String uniqueHandle, BoB_Coverage_Join__c newRecord) {                
        joinRecords.put(uniqueHandle, newRecord);
    
    }* / // joinRecordPut     


    //-----------------------------------------------------------------------------------
    // has the specified BoB_Coverage_Join__c record already been inserted?    
   / * public Boolean joinRecordExists (String uniqueHandle) {
        return joinRecords.containsKey(uniqueHandle);
    
    }* / // joinRecordExists    


    //-----------------------------------------------------------------------------------
    // fetch the specified BoB_Coverage_Join__c record's Id    
   / * public BoB_Coverage_Join__c getJoinRecord (String uniqueHandle) {
        return joinRecords.get(uniqueHandle);
    
    }* / // getJoinRecord     


    //-----------------------------------------------------------------------------------
    // empty/wipe the IMGA-specific analysis maps 
    public void modelClear (Boolean dumpBeforeWiping) {
			system.debug('modelClear: '); 

// ** /   logger.newEntry(moduleName, 'Debug', 'modelClear', coverageModel.size() +
// ** /       ', ' + joinRecords.size() + ', ' + dumpBeforeWiping, 10);
 
        // optionally record snapshot before clearing
       // if (dumpBeforeWiping)
           // dumpCoverageModel('modelClear', 0, NO_FILTER, 'Debug', false);      
 
        // wipe coverageModel and joinRecords
        coverageModel.clear();
        joinRecords.clear();
    
    } // modelClear      
    

    //-------------------------------------------------------------------------------
    // error-check and assemble a composite key for a ModelElement    
    public String modelKey (String imgaName, String countryName, String marketName, 
        String productClass, Integer billYear, Integer billPeriod) {  
        system.debug('---'+imgaName+'==='+countryName+'---'+marketName+'//'+productClass+',,'+billYear+'\\'+billPeriod);
        Boolean faulty = false;
        
        // [0] IMGA name is required        
        if (String.isBlank(imgaName)) {
            faulty = true;
            compositeKey = SEPERATOR;
        }
        else
            compositeKey = imgaName.toLowerCase() + SEPERATOR;
            
        // [1] Country name is optional
        if (String.isBlank(countryName))
            compositeKey += SEPERATOR;
        else
            compositeKey += countryName.toLowerCase() + SEPERATOR;
            system.debug('{{{{{{{{'+marketName);
        // [2] Market name is optional
        if (String.isBlank(marketName))
            compositeKey += SEPERATOR;
            else
            compositeKey += marketName.toLowerCase() + SEPERATOR;  
            
                system.debug('>>>>>>>>'+compositeKey);
        // [3] Product Class is required
        if (String.isBlank(productClass)) {
            faulty = true;
            compositeKey += SEPERATOR;
        }
        else
            compositeKey += productClass.toLowerCase() + SEPERATOR;  
            
        // [4] Billing Year is required
        if (billYear == null) {
            faulty = true;
            compositeKey += SEPERATOR;
        }
        else
            compositeKey += String.valueOf(billYear) + SEPERATOR;     
            
                 
        // [5] Billing Period is required
        if (billPeriod == null) {
            faulty = true;
        }
        else
            compositeKey += String.valueOf(billPeriod);  
   
      
       
         
        // any missing values?    
        if (faulty) {
            logger.newEntry(moduleName, 'Error', 'Missing one or more required fields', 
                imgaName + ', ' + countryName + ', ' + marketName + ', ' + 
                productClass + ', ' + billYear + billPeriod, 10);
        }
       
         
        System.debug('compositeKey=='+compositeKey);    
        return compositeKey;                            
    
    } // modelKey      
    

    //-------------------------------------------------------------------------------
    // build and log a formatted textual representation of coverageModel
  / *  public void dumpCoverageModel (String description, Integer max, String keyFilter, 
        String significance, Boolean details) {
        List<String> sortedKeys = new List<String>();
        ModelElement coverageAggregate;
        Integer      countDown     = max;
        Integer      bufferCount   = 1;
        String       formattedDump = '';
        
       system.debug('dumpCoverageModel: ' + String.valueOf(max) + ', ' + keyFilter + ', ' + 
       String.valueOf(details));
      logger.newEntry(moduleName, significance, 'dumpCoverageModel', String.valueOf(max) + 
       ', ' + keyFilter + ', ' + String.valueOf(details), -1); 
        
        // Coverage Model has been instantiated?
        if (coverageModel != null) {
            try {
                // start off by showing the overall element count and headers
                formattedDump  = 'Coverage Model has ' + String.valueOf(coverageModel.size()) + ' elements';  
                formattedDump += '\n' + description;
                formattedDump += 
// 0    1       2      3       4    5      6          7            8      9       10      11        12         13    14           15         
'\nIMGA;COUNTRY;MARKET;PRODUCT;YEAR;PERIOD;ACCOUNT_ID;ACCOUNT_NAME;AMOUNT;PLAYERS;UPDATES;PUBLISHED;REFERENCED;DIRTY;COVERAGE_IDS;BILLING_IDS';//CAy
// 0    1       2      3       4    5      6      7       8       9         10         11    12           13  
//CAn'\nIMGA;COUNTRY;MARKET;PRODUCT;YEAR;PERIOD;AMOUNT;PLAYERS;UPDATES;PUBLISHED;REFERENCED;DIRTY;COVERAGE_IDS;BILLING_IDS';
                
                // sort the elements by key
                sortedKeys.addAll(coverageModel.keySet());
                sortedKeys.sort(); 
          system.debug('sortedKeys: ' + sortedKeys);   
           logger.newEntry(moduleName, significance, 'sortedKeys', String.valueOf(sortedKeys), -1); 
            
                // dump the entries
                for (String elementKey : sortedKeys) {
                    // not filtering based on IMGA name, or does this element pass?
                    if (String.isEmpty(keyFilter)  ||  elementKey.startsWith(keyFilter)) {
                        // pull the object's content, and determine its player count
                        coverageAggregate     = coverageModel.get(elementKey);
                        Integer coverageCount = coverageAggregate.players.size();
                        
                        // add this element       
                        formattedDump +=                                          '\n'  + 
                             elementKey                                         + ' ; ' +                                      
                              String.valueOf(coverageAggregate.amountPerAccount) + '; '  +//CAy  
//CAn                             coverageAggregate.amount                           + '; '  +     
                             coverageCount                                      + '; '  +    
                             coverageAggregate.updateCount                      + ';'   +    
                             coverageAggregate.referenceCount                   + ';'   +
                             coverageAggregate.publishCount                     + '; '  +
                             coverageAggregate.dirty; 
                                 
                        // including maximum level of details?
                        if (details) {
                            // show the associated players, which should be a short list
                            formattedDump += ';' + String.valueOf(coverageAggregate.players); 
                            
                            // show the associated billing records, which could be a longer list
                            if (coverageAggregate.billingSet.size() > 0) {
                                formattedDump += '; (';
                                for (Id each : coverageAggregate.billingSet)
                                    formattedDump += each + ', ';
                                formattedDump = formattedDump.left(formattedDump.length() - 2) + ')';
                            }
                        } 
                        
                        // has this buffer become full?
                        if (formattedDump.length() >= MAX_BUFFER_CHARS) {
                         system.debug('Dump_Block_' + String.valueOf(bufferCount));           
                            logger.newEntry(moduleName, significance, 'Dump_Block_' + 
                                String.valueOf(bufferCount), formattedDump, -1);
                            formattedDump = '';
                            bufferCount++;
                        }
                        
                        // supposed to stop after 'max' elements?
                        if (countDown > 0) {
                            countDown--;
                            if (countDown <= 0)
                                break;
                        }
                    }
                }
                
                // still some dump text to be logged?
                if (formattedDump.length() > 0) {
              system.debug('Dump_Block_' + String.valueOf(bufferCount));                 
                    logger.newEntry(moduleName, significance, 'Dump_Block_' + 
                        String.valueOf(bufferCount), formattedDump, -1);
                }
            }
            catch (Exception curse) {
                logger.newException(moduleName, 'dumpCoverageModel failure', curse);
            }
        }
        else {
       system.debug('dumpCoverageModel empty');            
            logger.newEntry(moduleName, 'Warning', 'dumpCoverageModel empty', NO_FILTER, -1);
        }
        
    } * /// dumpCoverageModel 
    
   public void clearAmounts(){
    for(String s:coverageModel.keySet()){
            coverageModel.get(s).amountPerAccount.clear();
        }
   }

}*/