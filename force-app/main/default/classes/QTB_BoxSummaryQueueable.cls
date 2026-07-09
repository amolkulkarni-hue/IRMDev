/*****************************************************************************************************
* Class: QTB_BoxSummaryQueueable
* Author: Lokesh Tewari
* Purpose: GitLab #22656 To link Box Summary record with EOM invoices
* Requirement: GitLab #22656 To link Box Summary record with EOM invoices 
* Change History: 05/05/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari      11/06/2024     GitLab #22656 To link Box Summary record with EOM invoices
*******************************************************************************************************/

Global class QTB_BoxSummaryQueueable implements Queueable{
    Private static final String CLASSNAME = QTB_BoxSummaryQueueable.class.getName();
    public static boolean throwExplicitException = false;
    // Map to store Custom Invoice Number and Invoice 
    public Map<String,blng__Invoice__c> mapOfCustmNumberAndInvc = new Map<String,blng__Invoice__c>();
    // List of Invoice 
    List<blng__Invoice__c> lstInvoice = new List<blng__Invoice__c>();
    // Set to store Service period of Usage
    Set<String> servicePeriod = new Set<String>();
    // Map to store Invoice Id and Usage Category
    Map<id,string> invcIdUsgCategory= new Map<id,string>();
    // Map to store Custom Invoice Number and Invoice 
    Map<Id,blng__Invoice__c> mapInvcIdInvoice = new Map<Id,blng__Invoice__c>();            
    // Map to store Invoice Id and Invoice 
    Map<Id,blng__Invoice__c> mapInvcIdAndInvoice = new Map<Id,blng__Invoice__c>();  
    // Map to store Customer Number and Invoice 
    Map<Id,Id> mapOfUSIdAndInvcId = new Map<Id,Id>(); 
    
    
    Global QTB_BoxSummaryQueueable(List<blng__Invoice__c> lstInvc) {
        try{
            if( QTB_BoxSummaryQueueable.throwExplicitException){
                throw new NullPointerException();
            }
            system.debug('36  lstInvc  '+lstInvc);
            // List to store invoice
            lstInvoice.addAll(lstInvc);
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext BC, List<QTB_Box_Summary__c> scope
Return Type: void
**********************************************************************************************************/
    Global void execute(QueueableContext context) {
        try{
            if( QTB_BoxSummaryQueueable.throwExplicitException){
                throw new NullPointerException();
            }

            for(blng__Invoice__c invc: lstInvoice){
                for(blng__InvoiceLine__c invLn :invc.blng__InvoiceInvoiceLines__r){
                    // Map to store usage summary id and invoice id
                    mapOfUSIdAndInvcId.put(invLn.blng__UsageSummary__c,invc.id);
                    // Map to store Invoice id and invoice 
                    mapInvcIdAndInvoice.put(invc.id,invc);
                }                       
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }
}