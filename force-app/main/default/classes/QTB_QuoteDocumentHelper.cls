/*****************************************************************************************************
* Class: QTB_QuoteDocumentHelper
* Author: Accenture
* Purpose: This is a helper class for QTB_QuoteDocumentHelper
* Requirement: 
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture     9/22/2020      Class to concatenate free products
*******************************************************************************************************/
public with sharing class QTB_QuoteDocumentHelper{
    
    /***********************************************************************************************************
* Method :      process
* Parameters:   List<SBQQ__QuoteDocument__c>,System.TriggerOperation
* Return Type : void
* Description:  This method loops over the list of records to be processed 
**************************************************************************************************************/      
    public static void process(List<SBQQ__QuoteDocument__c> newrecords, Map<id,SBQQ__QuoteDocument__c> oldMap ,System.TriggerOperation operationType){
        Map<Id,String> attachmentMap=new Map<Id,String>();
        Map<Id,SBQQ__QuoteTemplate__c> quoteTemplateMap=new Map<Id,SBQQ__QuoteTemplate__c>([select id,Name from SBQQ__QuoteTemplate__c ]);
        
        for(SBQQ__QuoteDocument__c doc : newrecords){   
            switch on operationType {
                when BEFORE_INSERT {
                    if( doc.SBQQ__QuoteTemplate__c <> NULL && quoteTemplateMap.containsKey(doc.SBQQ__QuoteTemplate__c) ){
                        doc.Name=quoteTemplateMap.get(doc.SBQQ__QuoteTemplate__c).Name+'-'+doc.Name+'.'+doc.SBQQ__OutputFormat__c.toLowerCase();
                        system.debug('Name'+doc.Name);
                        if(doc.SBQQ__AttachmentId__c <> NULL){attachmentMap.put(doc.SBQQ__AttachmentId__c,doc.Name);}
                    } 
                }
                when else {}
            }
        }
        if (attachmentMap!=null) { 
            updateAttachment(attachmentMap);
        }
    }
    
    /*****************************************************************************************************************
    * Author:      Accenture
    * Date:        9/22/2020
    * Parameters:  Map<Id, SBQQ__QuoteDocument__c> , Map<Id, SBQQ__QuoteDocument__c>
    * Return:      void
    * Description: Method is used to update attachment name on opportunity.
    *****************************************************************************************************************/  
    public static void updateAttachment(Map<Id,String> attachmentMap) {
        try{
            if(QTB_QuoteDocumentTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            List<Attachment> attToUpdate=new List<Attachment>();
            for(Attachment attRec:[Select Id,Name from Attachment where id in: attachmentMap.keySet() ]){
                if(attachmentMap.containsKey(attRec.id))
                {
                attRec.Name=attachmentMap.get(attRec.id);
                attToUpdate.add(attRec);
                }
            } 
            if(!attToUpdate.isEmpty()){
                update attToUpdate;
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                                          QTB_QuoteLineHelper.class.getname());
            system.debug('The error  is'+e.getMessage());
            throw e;
        }
    }  
}