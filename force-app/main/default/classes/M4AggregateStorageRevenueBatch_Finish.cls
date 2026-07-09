/* Commenting the entire code as part of Gitlab #24448 */
global with sharing class M4AggregateStorageRevenueBatch_Finish {
    public M4AggregateStorageRevenueBatch_Finish(){
        
    }
}
/*global with sharing class M4AggregateStorageRevenueBatch_Finish implements Database.Batchable <sObject>{
    public String aggregateValueToUse;
    
    global M4AggregateStorageRevenueBatch_Finish(String yearToFinish){
        this.aggregateValueToUse = yearToFinish ;
    }
    
    global Database.Querylocator start ( Database.BatchableContext BC )
    {
        String queryString ='Select ID from Aggregate_Storage_Revenue__c where Aggregation_In_Progress__c = true';
        if(aggregateValueToUse != null){
            queryString += ' and M4_Batch_Segment__c=\'' + aggregateValueToUse + '\'';
        }
        return Database.getQueryLocator(queryString);
    }

    global void execute ( Database.BatchableContext BC , List <Aggregate_Storage_Revenue__c> revenues ){
        
        for(Aggregate_Storage_Revenue__c rev : revenues){
            rev.Aggregation_In_Progress__c = false;
        }
        
        Database.update(revenues, false);
    }
    
    global void finish ( Database.BatchableContext BC ) {

    }
    
}*/