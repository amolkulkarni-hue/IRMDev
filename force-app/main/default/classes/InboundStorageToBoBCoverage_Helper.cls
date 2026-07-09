/* Commenting the entire code as part of Gitlab #24446 */
public with sharing class InboundStorageToBoBCoverage_Helper extends BillingsToBoBCoverage_Helper {
    public InboundStorageToBoBCoverage_Helper(){
        
    }
/*    
    
    // constructor  
    public InboundStorageToBoBCoverage_Helper (String customSetting) {
        logger = new InboundStorageToBoBCoverage_Log(customSetting);
        Schema.DescribeSObjectResult r = Billing_Market__c.sObjectType.getDescribe();
    } // InboundStorageToBoBCoverage_Helper

     //-----------------------------------------------------------------------------------   
    // determine the current status of the batch job chain
    public override AsyncApexJob jobStatus () {
        // find the most recent batch job in this family/sequence/chain
        List<AsyncApexJob> latest = [ SELECT Id, JobType, ApexClassId, 
                                             ApexClass.Name, MethodName,
                                             TotalJobItems, JobItemsProcessed, 
                                             LastProcessed, LastProcessedOffset,
                                             Status, ExtendedStatus, NumberOfErrors,
                                             CreatedDate, CompletedDate,
                                             CreatedBy.Name
                                        FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id
                                                               FROM ApexClass
                                                              WHERE NAME LIKE 'M1_Physical_CDE_Batch%' )
                                    ORDER BY CreatedDate Desc
                                       LIMIT 1 ];
        // found it?
        if (latest != null  &&  !latest.isEmpty())
            return latest[0];
        else
            return null;
            
    } // jobStatus    
    
    public List<BoB_Coverage_Eligible__c> findAllCoveragesForCYSettingsRange( String effectiveYearText, Set<String> formulaHashes )
    {
        
        List<String>requiredFieldsForCoverage = new List<String>();
        
        requiredFieldsForCoverage.add('Account__r.IM_IMGA_Indexed__c'); //Used for IMGA match on Inbound Storage
        requiredFieldsForCoverage.add('Parent_Billing_Market__c'); //Used for Cube_District__r.Parent_Billing_Market__c match on Inbound Storage
        
        requiredFieldsForCoverage.add('Effective_Year__c');
        requiredFieldsForCoverage.add('Effective_Start_Period__c');
        requiredFieldsForCoverage.add('Effective_End_Period__c');
        requiredFieldsForCoverage.add('Country_Coverage__c');
        
        String joinedFields = String.join( requiredFieldsForCoverage, ',' );
        
        String fullQuery = '   SELECT '+ joinedFields +
                           '     FROM BoB_Coverage_Eligible__c ';

        fullQuery += ' WHERE (';
        
        fullQuery += 'Effective_Year__c = \'' + effectiveYearText + '\' )'; 
        
        fullQuery += ' And (MatchingStorageFormula__c in :formulaHashes OR PYMatchingStorageFormula__c in :formulaHashes )'; 
        
        System.debug('formulaHashes' + formulaHashes);
        
        
        
        return database.query( fullQuery );
        
    }
    
    private String buildHash( String imga, string marketOrCountry, Integer period, Integer year)
    {
        String hash = imga;
        hash += String.isBlank ( marketOrCountry ) ? '' : marketOrCountry;
        hash += period == null ? '' : String.valueOf( period ); 
        hash += year;
        
        return hash;
    }
    
    public Set<String> buildHashForCoverageRecord ( BoB_Coverage_Eligible__c eligibleCoverage )
    {
        Set<String> hashes = new Set<String>();
        
        Integer year = Integer.valueOf( eligibleCoverage.Effective_Year__c );
        Integer priorYear = year - 1;
        Integer startPeriod = Integer.valueOf( eligibleCoverage.Effective_Start_Period__c );
        Integer endPeriod = Integer.valueOf( eligibleCoverage.Effective_End_Period__c );
        
        String market = eligibleCoverage.Parent_Billing_Market__c;
        String marketOrCountry = market == null ? eligibleCoverage.Country_Coverage__c.toLowerCase()  : market ;
        String imga = eligibleCoverage.Account__r.IM_IMGA_Indexed__c;
        
        
        //Build hashes for previous year
        for( Integer i = 1; i < 13; i++)
        {
            String hash = buildHash( imga, marketOrCountry, i, priorYear); 
            hashes.add( hash );
        }

        //Build hashes for current period
        for( Integer i = startPeriod; i <= endPeriod; i++)
        {
            String hash = buildHash( imga, marketOrCountry, i, year); 
            hashes.add( hash );
        }
        return hashes;
    }
    
    public List<String> buildHashForInboundStorageRecord ( Inbound_Storage__c storageRecord )
    {
        List<String> hashes = new List<String>();
        
        Integer year = Integer.valueOf( storageRecord.Storage_Year__c );
        Integer period = Integer.valueOf( storageRecord.Storage_Month__c );
        
        String market = storageRecord.Cube_District__r.Parent_Billing_Market__c;
        String country = (storageRecord.Country_Coverage__c == null) ? '' : storageRecord.Country_Coverage__c.toLowerCase();
        String imga = storageRecord.IMGA_Name__c;
        
        //Every Inbound storage will get a non-market hash as well 
        //as a market (if one exits) hash because we need to tie 
        //all storage records (regardless to market) to coverages
        //that don't have markets, using the country covered field instead.
        String nonMarketHash = buildHash( imga, country, period, year); 
        hashes.add( nonMarketHash );
        
        if(country == 'united states' || country== 'canada') {
            String northAmericaMarketHash = buildHash( imga, 'north america', period, year); 
            hashes.add( northAmericaMarketHash);
        }
        
        //Build hashes for Market specific storage records
        if( String.isNotBlank ( market ) )
        {
            String marketHash = buildHash( imga, market, period, year); 
            hashes.add( marketHash );
        }
        
        
        return hashes;
    }
    
    public Set<String> buildGeneralHashForInboundStorageRecords ( List<Inbound_Storage__c> storageRecords )
    {
        Set<String> hashes = new Set<String>();

        for( Inbound_Storage__c storageRecord : storageRecords )
        {
            Integer year = Integer.valueOf( storageRecord.Storage_Year__c );
            
            Id market = storageRecord.Cube_District__r.Parent_Billing_Market__c;
            String country = (storageRecord.Country_Coverage__c == null) ? '' : storageRecord.Country_Coverage__c.toLowerCase();
            String imga = storageRecord.IMGA_Name__c;
            
            //Every Inbound storage will get a non-market hash
            //as well as a market (if one exits) hash
            //because we need to tie all storage records (regardless to market)
            //to coverages that don't have markets
            String nonMarketHash = buildHash( imga, country, null, year); 
            hashes.add( nonMarketHash );
            
            if(country == 'united states' || country== 'canada') {
                  String northAmericaMarketHash = buildHash( imga, 'north america', null, year); 
                  hashes.add( northAmericaMarketHash);
            }
            
            //Build hashes for Market specific storage records
            if( String.isNotBlank ( market ) )
            {
                String marketHash = buildHash( imga, market, null, year); 
                hashes.add( marketHash );
            }
        }
        
        return hashes;
    }
    
    public void buildCoverageMap( List<BoB_Coverage_Eligible__c> eligibleCoverages, Map<String, Map<Id, Map<String, Aggregate_Volume__c>>> existingCoverageMap )
    {
        for(BoB_Coverage_Eligible__c coverage : eligibleCoverages )
        {
            for( String coverageHash : buildHashForCoverageRecord ( coverage ))
            {
                if( !existingCoverageMap.containsKey( coverageHash ) )
                {
                    existingCoverageMap.put( coverageHash, new Map<Id, Map<String, Aggregate_Volume__c>>{ coverage.Id => null} );
                }
                else
                {
                    if( !existingCoverageMap.get( coverageHash ).containsKey( coverage.Id ) )
                        existingCoverageMap.get( coverageHash ).put( coverage.Id, null);
                }
            }
        }
    }
    
    public void buildVolumeRecordsAndPopulateCoverageMap( Map<String, Map<Id, Map<String, Aggregate_Volume__c>>> coverageMap, 
                                                          Inbound_Storage__c storageRecord, 
                                                          Map<String, Aggregate_Volume__c> volumesToUpsert,
                                                          Map<String, List<Aggregate_Volume__c>> existingRelevantVolumes,
                                                          List<String> hashesForThisStorageRecord )
    {
        
        
        if( hashesForThisStorageRecord.isEmpty() )
            return;
     
        for (String hash : hashesForThisStorageRecord) {
            
             if (coverageMap.containsKey(hash)){
                String market = storageRecord.Cube_District__r.Parent_Billing_Market__c;
                String marketOrCountry = ( market == null) ? storageRecord.country_coverage__c : market ;
                String marketCustHash =  marketOrCountry +':'+ storageRecord.Customer_Account__c;
                Date recordDateToStartOfMonth = storageRecord.Storage_Date__c.toStartOfMonth();
            
                //Let make this map like so : Map<Id, Map<String, Aggregate_Volume__c>>()
                //Where the String is a hash of Market:CustomerAccountId - this way we can break down these totals by
                //Market and Customer
                Map<Id, Map<String, Aggregate_Volume__c>> eligibleToVolumeMap = coverageMap.get(hash);
                for( ID coverageID : eligibleToVolumeMap.keyset())
                {
                    
                    String upsertHash = coverageID + recordDateToStartOfMonth.format() + marketCustHash;
                    Aggregate_Volume__c volume;
                    if( existingRelevantVolumes.containsKey( upsertHash ) )
                    {
                        for( Aggregate_Volume__c existingVol : existingRelevantVolumes.get( upsertHash )){
                            existingVol.total_volume__c += storageRecord.Total_Volume__c;
                            volumesToUpsert.put( upserthash, existingVol);
                        }
                    }
                    else if (volumesToUpsert.containsKey(upserthash)) {
                        volume = volumesToUpsert.get(upserthash);
                        volume.total_volume__c += storageRecord.Total_Volume__c;
                        volumesToUpsert.put( upserthash, volume);
                    } else {
                    
                        Map<String, Aggregate_Volume__c> marketCustToVolume = eligibleToVolumeMap.get( coverageID );
                        if( marketCustToVolume == null || !marketCustToVolume.containsKey( marketCustHash ) )
                        {
                            volume = new Aggregate_Volume__c(total_volume__c = storageRecord.Total_Volume__c, 
                                                             BoB_Coverage_Eligible__c = coverageID, 
                                                             storage_date__c = recordDateToStartOfMonth,
                                                             Customer_Account__c = storageRecord.Customer_Account__c,
                                                             Parent_Billing_Market__c = storageRecord.Cube_District__r.Parent_Billing_Market__c,
                                                             Inbound_Storage_Matching_Hash__c = upserthash
                                                             );
                                                         
                            if( marketCustToVolume == null )
                                marketCustToVolume = new Map<String, Aggregate_Volume__c>{ marketCustHash => volume };
                            else
                                marketCustToVolume.put( marketCustHash, volume );
                    
                            eligibleToVolumeMap.put( coverageID, marketCustToVolume );
                        }
                        else
                        {
                            volume = marketCustToVolume.get( marketCustHash );
                            volume.total_volume__c += storageRecord.Total_Volume__c;
                            marketCustToVolume.put( marketCustHash, volume );
                            eligibleToVolumeMap.get( coverageID ).putAll( marketCustToVolume );
                        }
                        volumesToUpsert.put( upserthash, volume);
                    }
                } 
            }
        }
    }
    */
}