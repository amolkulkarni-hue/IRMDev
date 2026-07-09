/* Commenting the entire code as part of Gitlab #24448 */
public with sharing class M4AggregateStorageRevenueHelper {
    public M4AggregateStorageRevenueHelper(){
        
    }
    /*
    public static final string NORTH_AMERICA = 'North America';
    
    public static Set<String> buildM4Hashes (List<Billings__c> billings){
        Set<String> m4hashes = new Set<String>();
        
        for(Billings__c bill : billings ) {
            if(bill.Parent_Billing_Market__c != null && bill.IMGA_Name_Formula__c != null){
                m4hashes.add(bill.IMGA_Name_Formula__c + bill.Parent_Billing_Market__c);
                m4hashes.add(bill.IMGA_Name_Formula__c + bill.Country_Coverage__c);
                m4hashes.add(bill.IMGA_Name_Formula__c + NORTH_AMERICA);
            }
        }
        
        return m4hashes;
        
    }
    
    public static List<M4_Revenue_Coverage__c> findM4s(Billings__c bill, Map<String, List<M4_Revenue_Coverage__c>> m4coverageMap){
        List<M4_Revenue_Coverage__c> coverageToReturn;
        
        String parentMarketHash = bill.IMGA_Name_Formula__c + bill.Parent_Billing_Market__c + bill.Product_Class__c;
        String countryCoverageHash = bill.IMGA_Name_Formula__c + bill.Country_Coverage__c + bill.Product_Class__c ;
        String northAmericaHash = bill.IMGA_Name_Formula__c + NORTH_AMERICA + bill.Product_Class__c; 
        
        if(m4coverageMap.containsKey( parentMarketHash )){
            coverageToReturn = m4coverageMap.get( parentMarketHash );
        } else if (m4coverageMap.containsKey( countryCoverageHash )){
            coverageToReturn = m4coverageMap.get( countryCoverageHash );
        } else if (m4coverageMap.containsKey( northAmericaHash )){
            coverageToReturn = m4coverageMap.get( northAmericaHash );
        }
        
        return coverageToReturn;
    }
    
 // public static List<Aggregate_Storage_Revenue__c> findAggregates(Billings__c bill, List<M4_Revenue_Coverage__c> coverages, Map<String, Aggregate_Storage_Revenue__c> coverageHashToRevenue){
    public static List<Aggregate_Storage_Revenue__c> findAggregates(Billings__c bill, List<M4_Revenue_Coverage__c> coverages, 
                                                            Map<String, Aggregate_Storage_Revenue__c> coverageHashToRevenue,Map<id, List<Aggregate_Storage_Revenue__c>> AggStorageRevMap){
        List<Aggregate_Storage_Revenue__c> revenuesToReturn = new List<Aggregate_Storage_Revenue__c>();
        
        
        for(M4_Revenue_Coverage__c coverage : coverages){
            String coverageHash = coverage.Aggregate_Storage_Hash__c + bill.Product_Class__c + coverage.id + bill.Customer_Account__c + bill.Billing_Period__c;
            List<Aggregate_Storage_Revenue__c> mainRevList = new List<Aggregate_Storage_Revenue__c>();
            if (coverageHashToRevenue.containsKey(coverageHash)){
                Aggregate_Storage_Revenue__c storedRev = coverageHashToRevenue.get(coverageHash);
                storedRev.Amount__c = (storedRev.Amount__c == null) ? bill.Amount__c : storedRev.Amount__c + bill.Amount__c;
                revenuesToReturn.add(storedRev);                
            } else {
           /*      for(Aggregate_Storage_Revenue__c rev : coverage.Aggregate_Storage_Revenue__r) {
                    if(rev.Product_Class__c == bill.Product_Class__c && (rev.Customer_ID__C ==  bill.Customer_Account__c) && (rev.Billing_Period__c == bill.Billing_Period__c) ){
                        rev.Amount__c = (rev.Aggregation_In_Progress__c) ? rev.Amount__c + bill.Amount__c : bill.Amount__c;
                        coverageHashToRevenue.put(coverageHash, rev);
                        revenuesToReturn.add(rev);
         
                
                   }
                }
           * /
               if(AggStorageRevMap.containsKey(coverage.id)){
                    //system.debug('+++++AggStorageRevMap++++'+AggStorageRevMap.get(coverage.id).size());
                    for(Aggregate_Storage_Revenue__c rev : AggStorageRevMap.get(coverage.id)) {
                        if(rev.Product_Class__c == bill.Product_Class__c && (rev.Customer_ID__C ==  bill.Customer_Account__c) && (rev.Billing_Period__c == bill.Billing_Period__c) ){
                            rev.Amount__c = (rev.Aggregation_In_Progress__c) ? rev.Amount__c + bill.Amount__c : bill.Amount__c;
                            coverageHashToRevenue.put(coverageHash, rev);
                            revenuesToReturn.add(rev);
                       }
                    }
                }  
               
            }
            
            //If the coverageMap still doesn't contain our hash, we need to create our own.
            if(!coverageHashToRevenue.containsKey(coverageHash)) {
                Date billDate = bill.Invoice_Date__c.toStartofMonth();
                Aggregate_Storage_Revenue__c newRev = new Aggregate_Storage_Revenue__c(M4_Revenue_Coverage__c = coverage.id,
                                                                       Invoice_Date__c = billDate,
                                                                       Parent_Billing_Market__c = bill.Parent_Billing_Market_ID__c,
                                                                       Product_Class__c = bill.Product_Class__c,
                                                                       Customer_ID__c = bill.Customer_Account__c,
                                                                       Amount__c = bill.Amount__c);
                coverageHashToRevenue.put(coverageHash, newRev);
                revenuesToReturn.add(newRev);
            }
        }
        
        for(Aggregate_Storage_Revenue__c rev : revenuesToReturn){
            rev.Aggregation_In_Progress__c = true;
        }
        
        return revenuesToReturn;
    }
    
*/
}