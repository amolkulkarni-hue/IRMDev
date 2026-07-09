/* Commenting the entire code as part of Gitlab #24446 */
public with sharing class InboundStorageToBoBCoverage_Log extends BillingsToBoBCoverage_Log {
    public InboundStorageToBoBCoverage_Log(){
        
    }
/*  
    public M1_CDE_Settings__c M1_settings;
    private final Integer MAX_MESSAGES_TO_HOLD = 10000;
    //-----------------------------------------------------------------------------------
    // constructor     
    public InboundStorageToBoBCoverage_Log (String customSetting) {        
                
        // access the custom settings
        if (customSetting != null) {
            M1_settings = M1_CDE_Settings__c.getInstance(customSetting);
            debugEnabled = M1_settings.Log_Debug_Enabled__c;
        }
        
        
        // keep track of message topic usage, for enforcing limits
        messageLimitCounts = new Map<String, Integer>(); 
        
        // bulkization storage
        holdingPen = new List<BoB_Coverage_Join_Log__c>();
        
        // set up the default Log Immediate settings
        // see also setLogImmediate() below
        logImmediate = new Map<String, Boolean>{ 'Info' => false,'Unusual' => false, 'Warning' => true,'Error'  => true,  'Debug' => false};   
        
    } // InboundStorageToBoBCoverage_Log 
    
    /*
        Populates the Map - This function modifies one tbe emailErrorMap
    * /
    public Map<String, EmailErrorMapping> buildErrorMappingFromResults(Map<String, EmailErrorMapping> emailErrorMap, Database.UpsertResult[] results, List<Aggregate_Volume__c> volumeRecordsUpserted )
    {
        if (results != null  &&  !results.isEmpty()) {   
            // evaluate the outcome for each record
            for (Integer databaseResultIndex = 0; databaseResultIndex < results.size(); databaseResultIndex++) {
                // unsuccessful?
                if (!results[databaseResultIndex].isSuccess()) {
                    
                    for( Database.Error error : results[databaseResultIndex].getErrors())
                    {
                        String statusCode = error.getStatusCode().name();
                        Id recordId = volumeRecordsUpserted[databaseResultIndex].id == null ? volumeRecordsUpserted[databaseResultIndex].BoB_Coverage_Eligible__c : volumeRecordsUpserted[databaseResultIndex].id;
                        
                        if( !emailErrorMap.containsKey( statusCode ))
                            emailErrorMap.put( statusCode, new EmailErrorMapping( recordId ));
                        else
                            emailErrorMap.get( statusCode ).errorCounter++;
                            
                    }
                    
                }
            }
        }
        
        return emailErrorMap;
    }
     
     public void reportDatabaseFailuresToDatabase ( Map<String, EmailErrorMapping> emailErrorMap, String dmlType, string moduleName) {                     
        // are there results from the Database.upsert? 
        if (emailErrorMap != null  &&  !emailErrorMap.isEmpty()) {   
            String summaryErrorMessage = '';
            Integer totalErrorCounter = 0;
             
            // evaluate the outcome for each record
            for (String errorType : emailErrorMap.keySet()) {
                
                EmailErrorMapping errorSummary = emailErrorMap.get( errorType );
                
                if ( errorSummary != null ) {
                    
                    totalErrorCounter += errorSummary.errorCounter;
                    
                    summaryErrorMessage += 'Error Type '   + errorType                          +
                                            ' Occurred '       + errorSummary.errorCounter                  + ' times ' + 
                                            ', Sample RecordId : ' + errorSummary.sampleRecordId + '\n';
                    
                }        
            }
            summaryErrorMessage = 'A total of ' + totalErrorCounter + ' errors occurred : ' + summaryErrorMessage; 
            newEntry(moduleName, 'Error', dmlType + ' Failed', summaryErrorMessage, 2);
        }  
    }
    
    public Messaging.SingleEmailMessage reportInboundStorageCompleted( Integer dmlRecordsLeft)
     {
        //Do we have room to insert our global list of errors
        //reportDatabaseFailuresToDatabase(upsertResult, 'Upsert',  M1_Physical_CDE_Batch.moduleName);
        
        //If yes, insert them
        
        //If no, send email with combined string of errors
        //sendEmailWithSummaryOfErrors();
        return null;
     }
   
    
    
    
    public class EmailErrorMapping{
        
        public Id sampleRecordId;
        public Integer errorCounter;
        
    
        public EmailErrorMapping( Id sampleId )
        {
            sampleRecordId = sampleId;
            errorCounter = 1;
        }
        
    }
    */
}