/*****************************************************************************************************
 * Class: QTB_orderUpdateForUSDeleteSchedule
 * QTB_orderUpdateForUSDelete
 * Author: Virtusa
 * Purpose: This is a Schedular class invoking a batch class to update order based on Unused Usage Summaries (QTB_orderUpdateForUSDelete).
 * Requirement: GIT# epics/2866

 *******************************************************************************************************/
global class QTB_orderUpdateForUSDeleteSchedule implements Schedulable {
    /***********************************************************************************************************
     * Method :  Constructor
     **************************************************************************************************************/
    global QTB_orderUpdateForUSDeleteSchedule() {
     
    }
    /***********************************************************************************************************
     * Method : execute
     * Parameters: Database.SchedulableContext
     * ReturnType: void
     **************************************************************************************************************/
    global void execute(SchedulableContext sc) {
      QTB_orderUpdateForUSDelete batchInstance=new QTB_orderUpdateForUSDelete();
      Integer batchChunkSize;
      String jsonString = System.Label.QTB_orderUpdateBatchParameters;
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