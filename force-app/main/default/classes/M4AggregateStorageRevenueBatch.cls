/* Commenting the entire code as part of Gitlab #24448 */
global class M4AggregateStorageRevenueBatch {
    public M4AggregateStorageRevenueBatch(){
        
    }
}
/*
global class M4AggregateStorageRevenueBatch implements Database.Batchable <sObject>,  Database.stateful
{
    public static final string JOB_NAME = 'M4AggregateStorageRevenueBatch';
    
    public static final string Aggregate_PY_H1 = 'PY YTD Q1 Q2';
    public static final string Aggregate_PY_H2 = 'PY YTD Q3 Q4';
    public static final string Aggregate_CY_H1 = 'CY YTD Q1 Q2';
    public static final string Aggregate_CY_H2 = 'CY YTD Q3 Q4';
    
    public static final string BILLING_CY_H1 = 'M4_CY_YTD_Q1_Q2__c';
    public static final string BILLING_CY_H2 = 'M4_CY_YTD_Q3_Q4__c';
    public static final string BILLING_PY_H1 = 'M4_PY_YTD_Q1_Q2__c';
    public static final string BILLING_PY_H2 = 'M4_PY_YTD_Q3_Q4__c';
        
    
    public Integer startMonth = 1;
    private Integer endingMonth = 12;
    public Integer BATCH_SCOPE_SIZE = 150;
    public       String effectiveYear;
    public String  UseThisCustomSetting = 'Production';
    
    private string aggregateValueToUse = 'CY YTD Q1 Q2';
    private string billingFieldToUse ='M4_CY_YTD_Q1_Q2__c';
    

    global M4AggregateStorageRevenueBatch (String billingFieldToCheck, string aggregateValueToCheck){
        
        
        billingFieldToUse = billingFieldToCheck;
        aggregateValueToUse = aggregateValueToCheck;
        
        
    }
    
    
    global Database.Querylocator start ( Database.BatchableContext BC )
    {
        BillingsToBoBCoverageJoins__c Commonsettings=BillingsToBoBCoverageJoins__c.getInstance(UseThisCustomSetting);
        if(Commonsettings != null)
        return Database.getQueryLocator('Select ID from Billings__c Where ' + billingFieldToUse + ' = true' + ' ' + Commonsettings.RecordTypeId__c);
        else
        return Database.getQueryLocator('Select ID from Billings__c Where ' + billingFieldToUse + ' = true');
    }

    global void execute ( Database.BatchableContext BC , List <Billings__c> scope )
    {
        
      List<Billings__c> billings = [Select Id, IMGA_Name_Formula__c, Parent_Billing_Market__c,Parent_Billing_Market_ID__c, Product_Class__c, billing_period__c,
                                           Country_Coverage__c, Amount__c, Invoice_Date__c,  Customer_Account__c
                                    from Billings__c Where ID IN: scope];
        
        
      Set<String> m4Hashes = M4AggregateStorageRevenueHelper.buildM4Hashes(billings);
      
      Set<Decimal> billingMonths = Pluck.decimals('billing_period__c', billings);
      
      Map<String, List<M4_Revenue_Coverage__c>> m4CoverageMap = new Map<String, List<M4_Revenue_Coverage__c>>();
      
    /*  List<M4_Revenue_Coverage__c> coverages = [Select Aggregate_Storage_Hash__c, id, Product_Coverage__c, 
                                                (Select Product_Class__c, Id, Amount__c, Aggregation_in_Progress__c,Customer_ID__c, Billing_Period__c From Aggregate_Storage_Revenue__r where M4_Batch_Segment__c =: aggregateValueToUse and billing_Period__c IN: billingMonths) 
                                                from M4_Revenue_Coverage__c 
                                                where Aggregate_Storage_Hash__c IN : m4Hashes];  * /
      Map<id,List<Aggregate_Storage_Revenue__c>> AggStorageRevMap = new Map<id,List<Aggregate_Storage_Revenue__c>>();    
   //   for( M4_Revenue_Coverage__c coverage : coverages){
       for(M4_Revenue_Coverage__c coverage : [Select Aggregate_Storage_Hash__c, id, Product_Coverage__c, 
                                                (Select Product_Class__c, Id, Amount__c, Aggregation_in_Progress__c,Customer_ID__c,M4_Revenue_Coverage__c, Billing_Period__c From Aggregate_Storage_Revenue__r where M4_Batch_Segment__c =: aggregateValueToUse and billing_Period__c IN: billingMonths) 
                                                from M4_Revenue_Coverage__c 
                                                where Aggregate_Storage_Hash__c IN : m4Hashes]){
                                                    
       for(Aggregate_Storage_Revenue__c AST : coverage.Aggregate_Storage_Revenue__r){
            if(AggStorageRevMap.containsKey(AST.M4_Revenue_Coverage__c)){
               AggStorageRevMap.get(AST.M4_Revenue_Coverage__c).add(AST);
           }else{
               AggStorageRevMap.put(AST.M4_Revenue_Coverage__c, new List<Aggregate_Storage_Revenue__c>{AST});
           }
        }
          if(coverage.Product_Coverage__c != null) {
              List<String> coverageProducts = coverage.Product_Coverage__c.split(';');
              for(String coverageProductString : coverageProducts) {
                  String hashString = coverage.Aggregate_Storage_Hash__c + coverageProductString;
                  if(m4CoverageMap.containsKey(hashString)){
                      m4CoverageMap.get(hashString).add(coverage);
                  } else {
                      m4CoverageMap.put(hashString, new List<M4_Revenue_Coverage__c>{coverage});
                  }
              }
          }
      }
      
      
      List<Aggregate_Storage_Revenue__c> revenues = new List<Aggregate_Storage_Revenue__c>();
       
      Map<String, Aggregate_Storage_Revenue__c> coverageHashToRevenue = new Map<String, Aggregate_Storage_Revenue__c>();
      List<Aggregate_Storage_Revenue__c> aggregatesToUpsert = new List<Aggregate_Storage_Revenue__c>();
      for(Billings__c bill : billings){
          List<M4_Revenue_Coverage__c> currentCoverages = M4AggregateStorageRevenueHelper.findM4s(bill, m4coverageMap);
          if(currentCoverages != null && (!currentCoverages.isEmpty())) {              
            //  M4AggregateStorageRevenueHelper.findAggregates(bill, currentCoverages, coverageHashToRevenue);
              M4AggregateStorageRevenueHelper.findAggregates(bill, currentCoverages, coverageHashToRevenue,AggStorageRevMap);
          }
      }
      
      List<Database.UpsertResult> results = Database.upsert(coverageHashToRevenue.values(), false);
    }


    global void finish ( Database.BatchableContext BC ) {
            M4AggregateStorageRevenueBatch_Finish job = new M4AggregateStorageRevenueBatch_Finish(aggregateValueToUse);
            Database.executeBatch(job);
        
    }

}*/