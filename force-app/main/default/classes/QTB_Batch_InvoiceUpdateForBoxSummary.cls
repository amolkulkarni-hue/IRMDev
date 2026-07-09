/*****************************************************************************************************
* Class: QTB_Invoice_Update_For_BoxSummary
* Author: Lokesh Tewari
* Purpose: GitLab #26362 To link Box Summary record with EOM invoices
* Requirement: GitLab #26362 To link Box Summary record with EOM invoices 
* Change History: 05/05/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari      03/06/2024     GitLab #26362 To link Box Summary record with EOM invoices
*******************************************************************************************************/
Global class QTB_Batch_InvoiceUpdateForBoxSummary implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    
    Private static final String CLASSNAME = QTB_Batch_InvoiceUpdateForBoxSummary.class.getName();
    public static boolean throwExplicitException = false;
    // Map to store Custom Invoice Number and Invoice 
    public Map<String,blng__Invoice__c> mapOfCustmNumberAndInvc = new Map<String,blng__Invoice__c>();
    // Set to store Service period of Usage
    Set<String> servicePeriod = new Set<String>();
    // Map to store invoice id and Service period of Usage
    Map<id,String> mapInvcIdServicePeriod = new Map<id,String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        DateTime yesterdayAt10PM = DateTime.newInstance(Date.today().addDays(-1), Time.newInstance(22, 0, 0, 0));
        system.debug(Date.today());
        system.debug('yesterdayAt10PM  '+yesterdayAt10PM);
        return Database.getQueryLocator(
            'SELECT Id, blng__Account__r.QTB_Legal_Entity_Country__c, ' +
            'QTB_Service_Start_Date__c, QTB_Service_End_Date__c, blng__Account__c, ' +
            'blng__Account__r.QTB_Customer_Number__c, ' +
            '(SELECT Id, blng__Invoice__c, blng__UsageSummary__c ' +
            'FROM blng__InvoiceInvoiceLines__r LIMIT 1) ' +
            'FROM blng__Invoice__c ' +
            'WHERE blng__Account__r.QTB_Legal_Entity_Country__c != \'United States\' ' +
            'AND blng__Account__r.QTB_Legal_Entity_Country__c != \'Canada\' ' +
            'AND QTB_Service_Type__c != \'Service\' ' +
            'AND CreatedDate > :yesterdayAt10PM'
        );
    }
    
    // Process each batch of records. This method will run for each chunk of records.
    global void execute(Database.BatchableContext BC, List<blng__Invoice__c> scope) {
        try{
            if( QTB_Batch_InvoiceUpdateForBoxSummary.throwExplicitException){
                throw new NullPointerException();
            }
            system.debug('scope '+scope.size());
            system.debug('scope '+scope);          
            // Map to store Invoice Id and Invoice 
            Map<Id,blng__Invoice__c> mapInvcIdAndInvoice = new Map<Id,blng__Invoice__c>();  
            // Map to store Customer Number and Invoice 
            Map<Id,Id> mapOfUSIdAndInvcId = new Map<Id,Id>(); 
            // List of Invoice 
            List<blng__Invoice__c> lstInvoice = new List<blng__Invoice__c>();
            // Set to store Service period of Usage
            
            for(blng__Invoice__c invc: scope){
                for(blng__InvoiceLine__c invLn :invc.blng__InvoiceInvoiceLines__r){
                    // Map to store usage summary id and invoice id
                    mapOfUSIdAndInvcId.put(invLn.blng__UsageSummary__c,invc.id);
                    // Map to store Invoice id and invoice 
                    mapInvcIdAndInvoice.put(invc.id,invc);
                }                       
            }
            if(!mapOfUSIdAndInvcId.isEmpty() && !mapInvcIdAndInvoice.isEmpty()){
                // List of Usage summary record to fetch service period of child usage record where Usage Category is EOM
                
                for(blng__UsageSummary__c us: [Select id,name,blng__InvoiceRun__c,blng__InvoiceLine__c,blng__InvoiceLine__r.blng__Invoice__c,(select id,QTB_ServicePeriod__c,QTB_Usage_Category__c from blng__Usages__r where QTB_Usage_Category__c='EOM' and QTB_ServicePeriod__c != null Limit 1) from blng__UsageSummary__c where Id in :mapOfUSIdAndInvcId.keySet()]){
                    system.debug('ususus  '+us);
                    // Check wether Usage summary contains Usage
                    if (!us.blng__Usages__r.isEmpty()) {
                        blng__Usage__c usage = us.blng__Usages__r[0];
                        //Map to store invoice id and usage category from usage to update Invoice with EOM type (End of the Month)
                        if(mapOfUSIdAndInvcId.containsKey(us.id) && mapInvcIdAndInvoice.containsKey(mapOfUSIdAndInvcId.get(us.id))){
                            // Map to store invoice id and service period that need to pass for Box Summary Batch
                            mapInvcIdServicePeriod.put(mapOfUSIdAndInvcId.get(us.id),usage.QTB_ServicePeriod__c);
                            // Map to story Invoice Id and Invoice record with EOM type
                            blng__Invoice__c invoice = new blng__Invoice__c(); 
                            invoice = mapInvcIdAndInvoice.get(mapOfUSIdAndInvcId.get(us.id));invoice.QTB_Usage_Category__c ='EOM';                            
                            lstInvoice.add(invoice);
                            mapOfCustmNumberAndInvc.put(invoice.blng__Account__r.QTB_Customer_Number__c,invoice);
                        }
                    }
                }
            }
            // Update Invoice record 
            if(!mapOfCustmNumberAndInvc.isEmpty() && !lstInvoice.IsEmpty()){
                Update lstInvoice;
            }
            lstInvoice.clear();
        }
        catch(Exception e){
            e.getLineNumber();
            e.getStackTraceString();
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),CLASSNAME);
        }
    }
    
     // Final method to handle post-batch completion tasks.
    global void finish(Database.BatchableContext BC) {
        try{
            if( QTB_Batch_InvoiceUpdateForBoxSummary.throwExplicitException){
                throw new NullPointerException();
            }
            if(!mapOfCustmNumberAndInvc.isEmpty() && !mapInvcIdServicePeriod.isEmpty()){
                Database.executeBatch(new QTB_BatchForBoxSummaryUpdate(mapOfCustmNumberAndInvc, mapInvcIdServicePeriod), Integer.valueOf(System.Label.QTB_BatchForBoxSummaryUpdateSize));
            }
        }
        catch(Exception e){
            e.getLineNumber();
            e.getStackTraceString();
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),CLASSNAME);
        }
    }
}