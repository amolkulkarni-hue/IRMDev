/*****************************************************************************************************
* Class 		: QTB_DocumentSendLookupTriggerHelper
* Test Class    : QTB_DocumentSendLookupTriggerHelper_Test
* Author		: Virtusa
* Purpose		: This is a helper class for all business logic related to I object
* Requirement	: Gitlab US #20933 -- Stop schedule call and run the logic based on need
* Change History: 01/22/2024
* Developer        Date           Description
* -------------------------------------------------------------------------------------------
*  Virtusa       01/22/2024      Gitlab US #20933 -- Stop schedule call and run the logic based on need
*******************************************************************************************************/
public class QTB_DocumentSendLookupTriggerHelper {
    private static final String CLASSNAME = QTB_DocumentSendLookupTriggerHelper.class.getName();
    
    /***********************************************************************************************************
* Method 	 : process
* Parameters : List<blng__Invoice__c>, Map<Id,blng__Invoice__c>, System.TriggerOperation
* Requirement: this method handle the logic related to Document send lookup object
* Author     : Virtusa
* Description: Generic method to handle all operations on the invoice Records
**************************************************************************************************************/
    public static void process(List<QTB_Documents_Send_Lookup_Queue__c> newItems, Map<Id, QTB_Documents_Send_Lookup_Queue__c> oldMap, System.TriggerOperation operationType)
    {
        try{        
            Set<Id> documentSendLookupQueueIdSet = new Set<Id>();
            if(newItems !=null && !newItems.isEmpty()){
                for(QTB_Documents_Send_Lookup_Queue__c documentSendLookupObj : newItems){
                    if(oldMap !=null && !oldMap.isEmpty() && oldMap.get(documentSendLookupObj.Id).QTB_Status__c != documentSendLookupObj.QTB_Status__c &&
                       documentSendLookupObj.QTB_Status__c == 'Delete')
                    {
                        documentSendLookupQueueIdSet.add(documentSendLookupObj.Id);
                    }
                }
            }            
            if(!documentSendLookupQueueIdSet.isEmpty()){
                Database.executeBatch(new QTB_BatchableDocumentSendDelete());
                //Database.executeBatch(new QTB_BatchableDocumentSendDelete(documentSendLookupQueueIdSet));
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
        }
    }
}