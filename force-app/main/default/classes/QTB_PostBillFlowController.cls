/*****************************************************************************************************
* Class: QTB_PostBillFlowController
* Test Class: QTB_PostBillFlowController_Test
* Author: Accenture
* Purpose:
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   24/05/2021       Initial version
* Virtusa     12/13/2021       Gitlab #6056 Vertex Tax Integration for Posted Invoice
* Virtusa     07/01/2025       Gitlab US#28211 - added existing code into new methods (updateCustomInvoiceNumber, postInvoice) to use the same logic from QTB_ExchangeRateFieldsUpdate class
*******************************************************************************************************/
public class QTB_PostBillFlowController {
    public static boolean throwExplicitException = false;
    public static string invCountry ='';
    //public static string InvState= '';
    public static final String CLASSNAME = QTB_PostBillFlowController.class.getName();
    public static boolean contractRateApplicable = false;
    public static Map<Id,string> postBillRecordWithInvoiceBatch = new Map<Id,string>();
    
    public class flowInputs
    {
        @InvocableVariable    
        Public Id postbillBatchRunRecordId;
        
        @InvocableVariable
        Public String invoiceBatches;
    }    
    
    @InvocableMethod
    public static void runPostBillBatches(list <FlowInputs> request)
    {
        system.debug('inside runPostBillBatches '+request);
        try{
            for(FlowInputs flow:request)
            {
                //Storing billFlowRecordId and invoiceBatch in map.
                postBillRecordWithInvoiceBatch.put(flow.postbillBatchRunRecordId, flow.invoiceBatches);
                System.debug('postbillBatchRunRecordId-->'+flow.postbillBatchRunRecordId);
            }
            //-- START -- Gitlabe #6056  --//  
            //Get invoiceRunIds for vertex callout using billFlowRecordIds 
            // Started changes # 19408 
            // Gitlab US#24777 (Credit/Rebill Billnow) Renamed from finalinvoiceid to finalInvoiceOrRunids
            Set<Id>finalInvoiceOrRunids = getInvoiceIds(postBillRecordWithInvoiceBatch.keySet());
            postInvoice(invCountry,postBillRecordWithInvoiceBatch,finalInvoiceOrRunids);
            // # 19408  End//
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }
    
    /***********************************************************************************************************
* Method : getInvoiceIds
* Parameters: id billFlowRecordId
* Requirement : Gitlab #6056 Vertex Tax Integration for Posted Invoice
* Start Date : 12/13/2021
* Author : Virtusa
* Description: This method is used to fetch invoiceIds based on billFlowcontroller record ids or vertex service only
// Gitlab US#24777 (Credit/Rebill Billnow) renamed method from getInvoiceIds instead of Invoice run id we are passing invoice id to handle Rebill by billnow process
**************************************************************************************************************/
    public static Set<Id> getInvoiceIds(Set<id> billFlowRecordIds){
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            System.debug('getInvoiceIds@@');
            Set<Id> invoiceSchedularIds = new Set<Id>();
            Set<Id> rebillinvoiceIds = new Set<Id>();
            Set<Id> invoiceIdSet = new Set<Id>();
            
            system.debug('--------'+billFlowRecordIds); 
            //Fetching billFlowController object data record
            for(QTB_Bill_Flow_Controller__c bill : [Select Id, Name,Invoice_Scheduler__c, QTB_Rebill_Invoice__c From QTB_Bill_Flow_Controller__c
                                                    where Id IN: billFlowRecordIds])
            {
                if(bill.Invoice_Scheduler__c != null){
                    invoiceSchedularIds.add(bill.Invoice_Scheduler__c);
                }
                else if(bill.QTB_Rebill_Invoice__c != null){
                    rebillinvoiceIds.add(bill.QTB_Rebill_Invoice__c);
                }
            }
            system.debug('--------'+invoiceSchedularIds);
            //Fetching value from Tax Integration Metadata, to check vertex tax country
            QTB_Tax_Integration_Setting__mdt countryValForVertex = QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration');
            if(invoiceSchedularIds!= null){
                for(blng__Invoice__c inv : [SELECT Id, Name, blng__Account__r.QTB_Legal_Entity_Country__c,blng__InvoiceRunCreatedBy__c,blng__Account__r.QTB_Market__r.QTB_State__c
                                            FROM blng__Invoice__c 
                                            WHERE blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c IN: invoiceSchedularIds 
                                            and blng__InvoiceRunCreatedBy__r.blng__Status__c = 'Completed' 
                                            and blng__InvoiceStatus__c = 'Draft'
                                            and blng__Account__r.QTB_Legal_Entity_Country__c !=null])
                {
                    //get the Invoice Country Name.
                    invCountry = inv.blng__Account__r.QTB_Legal_Entity_Country__c;
                    //InvState = inv.blng__Account__r.QTB_Market__r.QTB_State__c;
                    if(countryValForVertex.QTB_End_System__c == 'Vertex' && countryValForVertex.QTB_Country__c.containsIgnoreCase(inv.blng__Account__r.QTB_Legal_Entity_Country__c)){
                        invoiceIdSet.add(inv.Id); // Gitlab US#24777 (Credit/Rebill Billnow) instead of inv.blng__InvoiceRunCreatedBy__c
                    }                        
                }  
            }
            //for Rebill invoice
            if(rebillinvoiceIds!= null){
                for(blng__Invoice__c inv : [SELECT Id, Name,blng__Account__r.QTB_isContractRateApplicable__c, blng__Account__r.QTB_Legal_Entity_Country__c,blng__InvoiceRunCreatedBy__c,blng__Account__r.QTB_Market__r.QTB_State__c
                                            FROM blng__Invoice__c WHERE Id IN:rebillinvoiceIds and blng__Account__r.QTB_Legal_Entity_Country__c !=null /*and QTB_Invoice_Type__c ='ReBill'*/])
                {
                    //get the Invoice Country Name.
                    invCountry = inv.blng__Account__r.QTB_Legal_Entity_Country__c;
                    //InvState = inv.blng__Account__r.QTB_Market__r.QTB_State__c;
                    if(countryValForVertex.QTB_End_System__c == 'Vertex' && countryValForVertex.QTB_Country__c.containsIgnoreCase(inv.blng__Account__r.QTB_Legal_Entity_Country__c)){
                        invoiceIdSet.add(inv.Id); // Gitlab US#24777 (Credit/Rebill Billnow) instead of inv.blng__InvoiceRunCreatedBy__c
                    }                        
                }  
            }
            system.debug('SSSS'+invCountry);
            System.debug('getInvoiceIds_invoiceRunSet@@'+invoiceIdSet);
            return invoiceIdSet; //returning invoiceIdSet of ids for NA regio else returning null
            
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            return null;
        }
    }
/***********************************************************************************************************
* Method : postInvoice
* Parameters: String invCountry,Map<Id,string> postBillRecordWithInvoiceBatch,Set<ID> finalInvoiceOrRunids
* Requirement : 
* Start Date : 08/01/2025
* Author : Virtusa
* Description: moved existing logic to this method as same logic is used in QTB_ExchangeRateFieldsUpdate batch class
**************************************************************************************************************/
    public static void postInvoice(String invCountry,Map<Id,string> postBillRecordWithInvoiceBatch,Set<ID> finalInvoiceOrRunids){
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
        List<QTB_CustomInvoiceNumber__c> customInvoiceNumberListToUpdate = new List<QTB_CustomInvoiceNumber__c>();
        boolean pausePOSTInvoice = false;
            //Check the InvoiceNumber Custom Setting status
            if(!string.IsBlank(invCountry) && invCountry != 'United States' && invCountry != 'Canada'){
                Map<string,QTB_CustomInvoiceNumber__c> customInvoiceNumbers = QTB_CustomInvoiceNumber__c.getAll();
                for(QTB_CustomInvoiceNumber__c cutInv : customInvoiceNumbers.values()){
                    
                    if(cutInv.QTB_Is_Running__c == true && cutInv.QTB_Date_Time__c != null && cutInv.QTB_Country__c.containsIgnoreCase(invCountry)){ 
                        Integer currentHour = system.now().hour();
                        Integer storedHour = cutInv.QTB_Date_Time__c.hour();
                        Integer currentMinute = system.now().minute();
                        Integer storedMinute = cutInv.QTB_Date_Time__c.minute();
                        System.debug('currentHour-->'+currentHour+' storedHour--->'+storedHour+' currentMinute-->'+currentMinute+' storedMinute-->'+storedMinute);
                        if((storedHour - currentHour) == 0 || (storedHour - currentHour) == 1 || (storedHour - currentHour) == -1){
                            Integer minutes = currentMinute - storedMinute;
                            //Minute value coming as -ve when current time is less than stored time in Custom Invoice Number custom setting, 
                            //this happen due to after every 59 min, current time start again from 1 min to 59 min 
                            minutes = minutes < 0 ? (-1) * minutes : minutes ; 
                            if( minutes > Integer.valueOf(System.Label.QTB_CustomInvoiceNumberResetTime)){ 
                                System.debug('pausePOSTInvoice LN62---> '+pausePOSTInvoice);
                                pausePOSTInvoice = false;
                                break;
                            }else{
                                System.debug('pausePOSTInvoice LN66---> '+pausePOSTInvoice);
                                pausePOSTInvoice = true;
                                break;
                            } 
                        }
                        //check if the string country present or not// If present and value id true
                    } else if(cutInv.QTB_Country__c.containsIgnoreCase(invCountry) && cutInv.QTB_Is_Running__c == true ){
                        System.debug('pausePOSTInvoice LN73---> '+pausePOSTInvoice);
                        pausePOSTInvoice = true;
                        break;
                    } else{
                        if(cutInv.QTB_Country__c.equalsIgnoreCase(invCountry)  ){
                            //System.debug('marking QTB Bill controller is running field as true---> '+pausePOSTInvoice+' ' + postBillRecordWithInvoiceBatch.keyset() );
                            cutInv.QTB_Is_Running__c =true;
                            cutInv.QTB_Date_Time__c =system.now();
                            customInvoiceNumberListToUpdate.add(cutInv);
                        }
                    }
                }
            }
            if(customInvoiceNumberListToUpdate.size() > 0){
                Database.update (customInvoiceNumberListToUpdate,false); //MGSB
            }
            List<QTB_Bill_Flow_Controller__c> updateBillFlow = new List<QTB_Bill_Flow_Controller__c>();
                //Don't want to Pause as it's First Time except US and Canada
                system.debug('pausePOSTInvoice==='+pausePOSTInvoice);
                // Gitlab US#24777 (Credit/Rebill Billnow) changes made to reference to finalInvoiceOrRunids variable
                if(!pausePOSTInvoice){
                    for(Id billFlowId : postBillRecordWithInvoiceBatch.keySet()){
                        if(!finalInvoiceOrRunids.isEmpty() && finalInvoiceOrRunids.size() > 0){
                            QTB_vertexTaxCalloutBatch vertexBatch = new QTB_vertexTaxCalloutBatch(postBillRecordWithInvoiceBatch.get(billFlowId), billFlowId, finalInvoiceOrRunids,null,null, true);
                            database.executeBatch(vertexBatch, integer.valueOf(system.label.QTB_Vertex_Callout_Batch_Size));
                        }
                        else{
                            //Other than vertex, calling invoiceBatch logic will execute as same earlier.
                            system.debug('Calling InvoiceBatch---->');
                            
                            Integer batchSize=Integer.ValueOf(System.Label.QTB_InvoiceBatch_Size);
                            QTB_InvoiceBatch invoiceBatch = new QTB_InvoiceBatch(postBillRecordWithInvoiceBatch.get(billFlowId), billFlowId);
                            database.executeBatch(invoiceBatch,batchSize);
                        }
                        
                    }
                    //-- END -- Gitlabe #6056  --// 
                    // # 19408  Start//     
                }
                else{// Make the status to Queued
                    system.debug('pausePOSTInvoice (Queued)==='+pausePOSTInvoice+ ' Invoice-->'+ postBillRecordWithInvoiceBatch.keyset());
                    Set<Id> billFlowIdSet = new Set<Id>(); //2988 Epic:                  
                    String invoiceBatchName;  //2988 Epic:
                    for(Id billFlowId : postBillRecordWithInvoiceBatch.keySet()){
                        QTB_Bill_Flow_Controller__c billF = new QTB_Bill_Flow_Controller__c();
                        billF.QTB_PostBill_Run_Status__c = 'Queued';
                        billF.Id = billFlowId;
                        updateBillFlow.add(billF); 
                        billFlowIdSet.add(billFlowId);
                        invoiceBatchName = postBillRecordWithInvoiceBatch.get(billFlowId);                        
                    }
                    //2988 Epic: Calling the QTB_InvoiceBatch class in else part as the custom setting is not setting up to false:due to this Rebill invoice is in draft status when we approve CN simualtanouesly
                    Integer batchSize=Integer.ValueOf(System.Label.QTB_InvoiceBatch_Size);
                   QTB_InvoiceBatch invoiceBatch = new QTB_InvoiceBatch(invoiceBatchName, billFlowIdSet);
                   database.executeBatch(invoiceBatch,batchSize);
                   System.debug('>>>>callingbatch' + database.executeBatch(invoiceBatch,batchSize));
                }
               //commenting as per the //2988 Epic: As calling batch class in else part.
               /* if(updateBillFlow.size() > 0){
                    update(updateBillFlow);// MGSB
                }*/
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
        }
    }
}