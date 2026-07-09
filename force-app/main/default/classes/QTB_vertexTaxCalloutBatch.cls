/*****************************************************************************************************
* Class: QTB_vertexTaxCalloutBatch
* Author: IRM
* Purpose: This is a Batch class for do the callout and update the Tax in Invoice Line and Usage for both 'Invoice' and 'Credit Note'
* Requirement: Gitlab #857
* Change History: 12/07/2021
* Developer                     Date            Description
* ------------------------------------------------------------------------------------------- 
* Gopinandan/Shailesh       07/12/2021        #857 Vertex Tax Integration
* Virtusa    			    12/16/2021       Gitlab #6056 Vertex Tax Integration for Posted Invoice
*******************************************************************************************************/
public class QTB_vertexTaxCalloutBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts {
    public List<Id> InvoiceCreditIds;
    public Map<id,set<id>> processedInvIdWithLinesIdsMap;
    public Map<id,boolean> invIdRequestCompletion;
    public boolean isInvoiceRec;
    public final  string invoiceBatchName;
    public final  Id billFlowRecord;
    public boolean isPosted = false; //initialize with false for posted invoices,
    
    //Contructor
    //Updated constructor with two new parameter, which is deciding its for Draft or Posted vertex tax call
	// Gitlab US#24777 (Credit/Rebill Billnow) To handle Rebill by billnow process and Regular invoice changed reference from invoicRun to Invoice Renamed param invRunId to invoiceId
    public QTB_vertexTaxCalloutBatch(string invoiceBatch, Id billFlow, set<Id> invoiceId, Map<id,set<id>> processedInvLineIdss, Map<id,boolean> invIdRequestCompletions , boolean isInvoice){
        invoiceBatchName = invoiceBatch;
        billFlowRecord = billFlow;
        isPosted = (invoiceBatchName != null) ? true : false; //Setting value is true only, when this call is from QTB_PostBillFlowController class, that while making posted invoice.
        System.debug('QTB_vertexTaxCalloutBatch_invoiceId@@'+invoiceId);
        //Initialize Variables and assign values
        if(invoiceId != null){
            InvoiceCreditIds = new List<Id>();
            InvoiceCreditIds.AddAll(invoiceId);
            processedInvIdWithLinesIdsMap = new Map<id,set<id>>();
            if(processedInvLineIdss != null){
                processedInvIdWithLinesIdsMap = processedInvLineIdss;
            }
            invIdRequestCompletion = new Map<id,boolean>();
            if(invIdRequestCompletions != null){
                invIdRequestCompletion = invIdRequestCompletions;
            }
            isInvoiceRec = isInvoice;
        }
    }
    

    /*********************************************************************************************************
* Method Name: start
* Parameters: Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab #857
* Description: Query Ivoice/Credit Note Records for Tax calculation
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc)
    { // Gitlab US#24777 (Credit/Rebill Billnow)  To handle Rebill and Regular invoice removed blng__InvoiceRunCreatedBy__c from where clause
        //Fetching all the Invoice/ Credit Note Records
        String query = 'SELECT id, Name ';
        //Query Invoice
        if(isInvoiceRec){
            query = query + ' FROM blng__Invoice__c ' +
                ' WHERE Id IN:InvoiceCreditIds '+ 
                ' Order By Id';
           
        }else{
            query = query + ' FROM blng__CreditNote__c ' +
                ' WHERE Id IN:InvoiceCreditIds ';
        }
        
       return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters: Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab #857
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<SObject> scope){
        try {
            List<id> processIds = new List<id>();
            List<blng__Invoice__c> invoiceRec = new List<blng__Invoice__c>();
            List<blng__CreditNote__c> creditNoteRec = new List<blng__CreditNote__c>();
            //Typecast invoice
            if(isInvoiceRec){
                invoiceRec = (List<blng__Invoice__c>)scope;
                for (blng__Invoice__c invId : invoiceRec) {
                    processIds.add(invId.id);
                }
            }else{//Typecast Credit Note
                creditNoteRec = (List<blng__CreditNote__c>)scope;
                for (blng__CreditNote__c invId : creditNoteRec) {
                    processIds.add(invId.id);
                }
            }
            //if records are there to process
            if(processIds.size() > 0){
                //if still records are there to process ot first time process for invoice
                if(isInvoiceRec && (invIdRequestCompletion == null ||(invIdRequestCompletion != null && !invIdRequestCompletion.containsKey(processIds[0])) ||(invIdRequestCompletion != null && invIdRequestCompletion.containsKey(processIds[0]) && invIdRequestCompletion.get(processIds[0])== false))){
                    setInvoiceData(processIds,processedInvIdWithLinesIdsMap,invIdRequestCompletion);
                }//if still records are there to process ot first time process for Credit Note
                if(!isInvoiceRec && (invIdRequestCompletion == null ||(invIdRequestCompletion != null && !invIdRequestCompletion.containsKey(processIds[0])) ||(invIdRequestCompletion != null && invIdRequestCompletion.containsKey(processIds[0]) && invIdRequestCompletion.get(processIds[0])== false))){
                    System.debug('processIds@@'+processIds);
                    System.debug('processedInvIdWithLinesIdsMap@@'+processedInvIdWithLinesIdsMap);
                    System.debug('invIdRequestCompletion@@'+invIdRequestCompletion);
                    setCreditNoteData(processIds,processedInvIdWithLinesIdsMap,invIdRequestCompletion);
                }
            }
        }
        catch (Exception e){
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_vertexTaxCalloutBatch'); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters: Database.BatchableContext
* Return Type: void
* Requirement: Gitlab #857
* Description: finish method
**********************************************************************************************************/
    public void finish (Database.BatchableContext bc){
        try{
            //Logic for the finish method
            System.debug('finish@@');
            if(invIdRequestCompletion != null && invIdRequestCompletion.size() > 0){
                boolean runBtachAgain = false;
                for(id checkId : invIdRequestCompletion.keySet()){
                    //Check if any pending records are the there to process
                    if(invIdRequestCompletion.get(checkId) == false){
                        runBtachAgain = true;
                    }
                }
                //If pending records available
                if(runBtachAgain){
                    System.debug('finish_runBtachAgain@@'+runBtachAgain);
                    set<id> idSet = new set<id>();
                    idSet.addAll(InvoiceCreditIds);
                    //Call the same batch class again to process remaining records
                    if(isPosted){ //For Posted calling same vertexTaxCallbatch class with different parametes
                         Database.executeBatch(new QTB_vertexTaxCalloutBatch(invoiceBatchName,billFlowRecord, idSet,processedInvIdWithLinesIdsMap,invIdRequestCompletion,isInvoiceRec), integer.valueOf(system.label.QTB_Vertex_Callout_Batch_Size));
   					}else{
                          Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,idSet,processedInvIdWithLinesIdsMap,invIdRequestCompletion,isInvoiceRec), integer.valueOf(system.label.QTB_Vertex_Callout_Batch_Size));
                    }
               }else{  
                   //Continue the calling QTB_InvoiceBatch class after getting tax from vertex service, means after finishing vertexTaxCallout
                   //If any invoice failed for taxation,  in InvoiceBatch already its handling fail invoice logic in query to check tax status, then only making posted invoice for successful.
                   if(invoiceBatchName!=null && billFlowRecord !=null ){
                        QTB_InvoiceBatch invoiceBatch = new QTB_InvoiceBatch(invoiceBatchName, billFlowRecord);
            			database.executeBatch(invoiceBatch,50);
                   }
                }
            }
        }
        catch(Exception e) {
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_vertexTaxCalloutBatch.finish');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method Name: setInvoiceData
* Parameters : List<id> creditNoteIds,Map<id,set<id>> processedInvIdWithLinesIdsMap,Map<id,boolean> invIdRequestCompletion
* Return Type: void
* Requirement: Gitlab #857
* Description:  setting Invoice, InvoiceLine, Usage data for Tax request-response
**********************************************************************************************************/
    public void setInvoiceData(List<id> invIds,Map<id,set<id>> processedInvIdWithLinesIdsMap,Map<id,boolean> invIdRequestCompletion){
        try{
            sObject invoiceOrCreditNote;
            List<sObject> processLines = new List<sObject>();
            String invoiceToDistrictCode ;
            String invoiceToLocationCode ;
            Map<id,string> invoiceLineIdToBillCode = new Map<id,string>();
            Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
            Map<Id,set<id>> invoiceIdToUsageSummaryMap = new Map<Id,Set<id>>();
            Map<Id,List<blng__Usage__c>> invoiceIdToUsageMap = new Map<Id,List<blng__Usage__c>>();
            
            QTB_IRMToVertexHelper.callMainMethod(invIds);
            QTB_IRMToVertexHelper.getInvoiceLineUsageList(invIds,processedInvIdWithLinesIdsMap,invIdRequestCompletion);
            processedInvIdWithLinesIdsMap = QTB_IRMToVertexHelper.alreadyProcessedIdsMap;
            invIdRequestCompletion = QTB_IRMToVertexHelper.invIdRequestCompletion;
            processLines.addAll(QTB_IRMToVertexHelper.invoiceLineOrUsageListTax);
            
            invoiceOrCreditNote         = QTB_IRMToVertexHelper.getInvoice(invIds); 
            invoiceToDistrictCode       = QTB_IRMToVertexHelper.getDistrict(invIds) != null ? QTB_IRMToVertexHelper.getDistrict(invIds).get(invoiceOrCreditNote.id) : '';
            invoiceToLocationCode       = QTB_IRMToVertexHelper.getLocation(invIds) !=null ? QTB_IRMToVertexHelper.getLocation(invIds).get(invoiceOrCreditNote.id) : '' ;
            invoiceLineIdToBillCode     = QTB_IRMToVertexHelper.getProductBillCode(invIds);
            invoiceIdToInvoiceLineMap   = QTB_IRMToVertexHelper.invoiceIdToInvoiceLineMap;
            invoiceIdToUsageSummaryMap  = QTB_IRMToVertexHelper.invoiceIdToUsageSummaryMap;
            invoiceIdToUsageMap         = QTB_IRMToVertexHelper.invoiceIdToUsageMap; 
            //in QTB_IRMToVertexService -- passed all required parameter for request-reponse
            //isPosted parameter is deciding the call is posted invoice or draft invoice
            QTB_IRMToVertexService verCall = new QTB_IRMToVertexService(invoiceOrCreditNote,processLines,invIdRequestCompletion.get(invIds[0]), 
                                                                        isInvoiceRec,invoiceToDistrictCode, invoiceToLocationCode,invoiceLineIdToBillCode,
                                                                        invoiceIdToInvoiceLineMap, invoiceIdToUsageSummaryMap, invoiceIdToUsageMap,isPosted);
        } 
        catch(Exception e) {
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_vertexTaxCalloutBatch.setInvoiceData');
            throw e;
        }
    }
    
    
    /*********************************************************************************************************
* Method Name: setCreditNoteData
* Parameters : List<id> creditNoteIds,Map<id,set<id>> processedInvIdWithLinesIdsMap,Map<id,boolean> invIdRequestCompletion
* Return Type: void
* Requirement: Gitlab #857
* Description:  setting creditNote,CreditNoteLine data for Tax request
**********************************************************************************************************/
    public void setCreditNoteData(List<id> creditNoteIds,Map<id,set<id>> processedInvIdWithLinesIdsMap,Map<id,boolean> invIdRequestCompletion){
        try{
            sObject invoiceOrCreditNote;
            List<sObject> processLines = new List<sObject>();
            String invoiceToDistrictCode ;
            String invoiceToLocationCode ;
            Map<id,string> invoiceLineIdToBillCode = new Map<id,string>();
            //Call the Vertex Callout class
            QTB_IRMToVertexCreditHelper.callVertexCreditHelper(creditNoteIds);
            QTB_IRMToVertexCreditHelper.getCreditLineUsageList(creditNoteIds,processedInvIdWithLinesIdsMap,invIdRequestCompletion);
            processedInvIdWithLinesIdsMap = QTB_IRMToVertexCreditHelper.alreadyProcessedIdsMap;
            invIdRequestCompletion = QTB_IRMToVertexCreditHelper.invIdRequestCompletion;
            processLines.addAll(QTB_IRMToVertexCreditHelper.invoiceLineOrUsageListTax);
            
            invoiceOrCreditNote         = QTB_IRMToVertexCreditHelper.getCreditNote(creditNoteIds);                
            invoiceToDistrictCode       = QTB_IRMToVertexCreditHelper.getDistrict(creditNoteIds) != null ? QTB_IRMToVertexCreditHelper.getDistrict(creditNoteIds).get(invoiceOrCreditNote.id) : '';
            invoiceToLocationCode       = QTB_IRMToVertexCreditHelper.getLocation(creditNoteIds) !=null ? QTB_IRMToVertexCreditHelper.getLocation(creditNoteIds).get(invoiceOrCreditNote.id) : '' ;
            invoiceLineIdToBillCode     = QTB_IRMToVertexCreditHelper.getProductBillCode(creditNoteIds);
            System.debug('invoiceToDistrictCode@@'+invoiceToDistrictCode);
            System.debug('invoiceToLocationCode@@'+invoiceToLocationCode);
            System.debug('invoiceLineIdToBillCode@@'+invoiceLineIdToBillCode);
            
            //in QTB_IRMToVertexService -- passed all required parameter for request-reponse
            //isPosted parameter is deciding the call is posted invoice or draft invoice
            QTB_IRMToVertexService verCall = new QTB_IRMToVertexService(invoiceOrCreditNote, processLines, invIdRequestCompletion.get(creditNoteIds[0]),
                                                                        isInvoiceRec,invoiceToDistrictCode, 
                                                                        invoiceToLocationCode,invoiceLineIdToBillCode,
                                                                        null, null, null,isPosted);  
        }
        catch(Exception e) {
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_vertexTaxCalloutBatch.setCreditNoteData');
            throw e;
        }
    }
}