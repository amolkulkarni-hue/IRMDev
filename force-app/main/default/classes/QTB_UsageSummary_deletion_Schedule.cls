/*****************************************************************************************************
 * Class: QTB_UsageSummary_deletion_Schedule
 * QTB_UsageSummary_deletion_OrderSpecific
 * Author: Virtusa
 * Purpose: This is a Schedular class invoking a batch class to Delete Unused Usage Summaries (QTB_UsageSummary_deletion_OrderSpecific).
 * Requirement: GIT# epics/2939

 *******************************************************************************************************/
global class QTB_UsageSummary_deletion_Schedule implements Schedulable {
    /***********************************************************************************************************
     * Method :  Constructor
     **************************************************************************************************************/
    global QTB_UsageSummary_deletion_Schedule() {
     
    }
    /***********************************************************************************************************
     * Method : execute
     * Parameters: Database.SchedulableContext
     * ReturnType: void
     **************************************************************************************************************/
    global void execute(SchedulableContext sc) {
      QTB_UsageSummary_deletion_OrderSpecific batchInstance=new QTB_UsageSummary_deletion_OrderSpecific();
      Integer batchChunkSize;
      String jsonString = System.Label.QTB_usageSummaryDeleteBatchParameters;
      Map<String, Object> dataMap;
    
             // Check if the custom label is null or empty
             if (String.isNotBlank(jsonString)) {
                 // Deserialize the JSON string into an untyped Map
                 dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
             }
                 
             // Ensure the deserialized map is not null
             if (dataMap != null) {   

               // Process chunksize.
               if (dataMap.containsKey('batchChunkSize') && dataMap.get('batchChunkSize') != null) {
                 String chunkSizeStr = String.valueOf(dataMap.get('batchChunkSize')).trim();
                 if (!String.isBlank(chunkSizeStr)) {
                   batchChunkSize = Integer.valueOf(chunkSizeStr);
                   System.debug('Successfully converted   this.batchChunkSize ' + batchChunkSize);
                   
                  }
                  Database.executeBatch(batchInstance, (batchChunkSize != null) ? batchChunkSize : 1);
                }
              }
    }
  }