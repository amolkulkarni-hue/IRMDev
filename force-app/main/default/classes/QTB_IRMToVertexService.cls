/*****************************************************************************************************
* Class         : QTB_IRMToVertexService
* Test Class    : QTB_IRMToVertex_Test
* Purpose       : This is a Integration Class to send request to Vertex for tax calculation
* Requirement   : Gitlab #857, #2002
* Author        : IRM / Virtusa
* Developer     : Gopi / Shailesh
* Change History: 07/07/2021
* Developer                     Date            Description
* ------------------------------------------------------------------------------------------- 
*  Gopinandan/Shailesh       12/07/2021      #857 Vertex Tax Integration
*  Virtusa 			        12/13/2021       Git #6056 DM MVP PROD - VERTEX - Differentiate callouts for 'Posted' invoices & Credit Notes
*  Shailesh/Ramesh			29/08/2023		 GIT #17239 Store Vertex Request Body and Response Body at Invoice and Credit Note Object
*******************************************************************************************************/
public with sharing class QTB_IRMToVertexService {
    
    public static string jwtToken;
    public static List<id> invoiceCreditNoteIds = new List<id>();
    public static List<sObject> invoiceLineOrUsageListForTax = new List<sObject>();
    public static integer lineItemCount = 0;
    public static String invoiceToDistrictCode;
    public static String invoiceToLocationCode  ;
    public static Map<id,string> invoiceLineIdToBillCode = new Map<id,string>();
    public static Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
    public static sObject invoiceOrCreditNote;
    public static Map<Id,set<id>> invoiceIdToUsageSummaryMap = new Map<Id,set<id>>();
    public static Map<Id,List<blng__Usage__c>> invoiceIdToUsageMap = new Map<Id,List<blng__Usage__c>>();
    public static Map<Id,Service_Location__c> accountIdToServiceLocationMap = new Map<Id,Service_Location__c>();
    public static boolean isForPostedInvoiceOrCredit = false; //initializing with false for Posted invoice
    
    //Checking the Environment is Production or SandBox?
    public static Boolean runningInASandbox {
        get{
            if ( runningInASandbox == null) {
                runningInASandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return runningInASandbox;
        } set;
    }
    
    //Getting Value From Custom Setting according to the Env.
    public static QTB_VertexServiceConfigs__c vertexSettings{
        get{
            if(vertexSettings == null){
                string sandboxType = runningInASandbox ? 'SandboxIntegrationDetails' : 'ProductionIntegrationDetails' ;
                vertexSettings = QTB_VertexServiceConfigs__c.getInstance(sandboxType);
            }
            return vertexSettings;
        }
        set;
    }
    
    
    /*********************************************************************************************************
* Method Name: QTB_IRMToVertexService
* Parameters: Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab #857
* Description: Constructor QTB_IRMToVertexService to set values for request-response
**********************************************************************************************************/
    public QTB_IRMToVertexService(sObject invoiceOrCreditNote,List<SObject> recordsForRequest, boolean islastChunk, boolean isInvoiceRec,
                                  string invoiceToDistrictCodeVar, string invoiceToLocationCodeVar,  Map<id,string> invoiceLineIdToBillCodeVar, 
                                  Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMaps, Map<Id,set<id>> invoiceIdToUsageSummaryMaps,
                                  Map<Id,List<blng__Usage__c>> invoiceIdToUsageMaps, boolean isPosted){
                                      isForPostedInvoiceOrCredit = isPosted; //setting value based on Posted or draft invoice sent from vertexTaxBatch class
                                      invoiceToDistrictCode = invoiceToDistrictCodeVar;  //DistrictCode for Flexicode1 in request
                                      invoiceToLocationCode = invoiceToLocationCodeVar;  //Location for Flexicode13 in request
                                      invoiceLineIdToBillCode = invoiceLineIdToBillCodeVar; //Product Bill Code
                                      invoiceIdToInvoiceLineMap = invoiceIdToInvoiceLineMaps;
                                      invoiceIdToUsageSummaryMap = invoiceIdToUsageSummaryMaps;
                                      invoiceIdToUsageMap = invoiceIdToUsageMaps;
                                      
                                      if(recordsForRequest != null){
                                          invoiceLineOrUsageListForTax.addAll(recordsForRequest);
                                      }
                                      if(invoiceOrCreditNote !=null ){
                                          invoiceOrCreditNote = invoiceOrCreditNote;           
                                      }
                                      if( vertexSettings != null ){
                                          getAuthorizedToken(invoiceOrCreditNote,islastChunk, isInvoiceRec);
                                      }
                                  }
    
    
    /*********************************************************************************************************
* Method Name: getAuthorizedToken
* Parameters:  sObject invoiceOrCreditNote, boolean islastChunk, boolean isInvoiceRec
* Return Type: void    
* Company    : IRM/Virtusa
* Developer  : Gopi/Shailesh
* Description: This method will make REST request to vertex to get Authorization Code 
**********************************************************************************************************/
    public void getAuthorizedToken(sObject invoiceOrCreditNote, boolean islastChunk, boolean isInvoiceRec) {
        try {
            Http http = New Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(vertexSettings.QTB_EndpointAuthURL__c);
            request.setHeader('username', vertexSettings.QTB_UserName__c);
            request.setHeader('password', vertexSettings.QTB_Password__c);
            request.setHeader('IRM_APP_ID', vertexSettings.QTB_IRM_APP_ID__c);
            request.setHeader('client_key', vertexSettings.QTB_ClientKey__c);
            request.setHeader('client_secret', vertexSettings.QTB_ClientSecret__c);
            request.setTimeout( Integer.valueOf(vertexSettings.QTB_MAX_REQUEST_TIMEOUT__c));
            request.setmethod('GET');
            HttpResponse response = http.send(request);  
            
            if ( (response.getStatusCode() == 200 &&  response.getStatus() == 'OK') ){
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody()); 
                jwtToken = (String) result.get('JWT');
                System.debug('JWT Token@@'+jwtToken);   
                callCalculateTaxService(invoiceOrCreditNote,jwtToken, islastChunk, isInvoiceRec);//calling main calculateTax method
            } 
            else{
                string ErrorMsg = 'Authentication failed, the user could not be authenticated due to missing or invalid credentials.';
                if(isInvoiceRec){
                    //handling response error for invoice
                    QTB_IRMVertexResponseUtil.updateErrorToInvoiceUsageLevel(ErrorMsg,invoiceOrCreditNote, invoiceLineOrUsageListForTax, invoiceIdToInvoiceLineMap,invoiceIdToUsageSummaryMap,invoiceIdToUsageMap); 
                }
                else{
                    //handling response error for creditNote
                    QTB_IRMVertexResponseUtil.updateErrorToInvoiceUsageLevel(ErrorMsg,invoiceOrCreditNote, invoiceLineOrUsageListForTax,null,null,null); 
                }
                QTB_ExceptionLogger.enable();//Gitlab US#24525
                QTB_ExceptionLogger.createLog(102,'',ErrorMsg,'','QTB_IRMToVertexService.getAuthorizedToken()');
            }
        }catch (Exception e) {  
            string ErrorMsg = e.getMessage();
            if(isInvoiceRec){
                //handling response error for invoice
                QTB_IRMVertexResponseUtil.updateErrorToInvoiceUsageLevel(ErrorMsg,invoiceOrCreditNote, invoiceLineOrUsageListForTax, invoiceIdToInvoiceLineMap,invoiceIdToUsageSummaryMap,invoiceIdToUsageMap); 
            }
            else{
                //handling response error for creditNote
                QTB_IRMVertexResponseUtil.updateErrorToInvoiceUsageLevel(ErrorMsg,invoiceOrCreditNote, invoiceLineOrUsageListForTax,null,null,null); 
            }
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_IRMToVertexService.getAuthorizedToken()');
        }            
    }
    
    /*********************************************************************************************************
* Method Name: calculateTax
* Parameters:  sObject invoiceOrCreditNote,string jwtToken, boolean islastChunk, boolean isInvoiceRec
* Return Type: void   
* Company    : IRM/Virtusa
* Developer  : Gopi/Shailesh
* Description: This method will make REST request to vertex to get tax details for Invoice , Usage, CreditNote
**********************************************************************************************************/
    public static void callCalculateTaxService(sObject invoiceOrCreditNote,string jwtToken, boolean islastChunk, boolean isInvoiceRec){
        try{
            string body ='';  
            string tempRequestBody = '';
            List<sObject> invoiceLineOrUsageListTax = new List<sObject>();
            Http http = New Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(vertexSettings.QTB_EndpointCalculateTaxURL__c);
            request.setHeader('Content-Type', 'text/xml');
            request.setHeader('JWT', jwtToken);
            if(isInvoiceRec){    
                //isForPostedInvoiceOrCredit parameter this request creation is for Draft invoice or PostedInvoice
                tempRequestBody = QTB_IRMVertexRequestUtil.requestStructureForInvoiceLineOrUsage(invoiceOrCreditNote,invoiceLineOrUsageListForTax,invoiceToDistrictCode, invoiceToLocationCode,invoiceLineIdToBillCode, 'InvoiceUsageSummary',isForPostedInvoiceOrCredit);  
            }else{
                //isForPostedInvoiceOrCredit parameter this request creation is for Draft CreditNote or Posted CreditNote
                tempRequestBody = QTB_IRMVertexRequestUtil.requestStructureForInvoiceLineOrUsage(invoiceOrCreditNote,invoiceLineOrUsageListForTax,invoiceToDistrictCode, invoiceToLocationCode,invoiceLineIdToBillCode, 'CreditNoteUsageSummary',isForPostedInvoiceOrCredit);  
            }                        
            System.debug('tempRequestBody@@'+tempRequestBody);  
            body = body +  tempRequestBody;  
            body = body + QTB_IRMVertexServiceConstant.SOAP_REQUEST_HEADER_END; //Closing the request body         
            
            system.debug('Request_body@@'+body);
			request.setTimeout( Integer.valueOf(vertexSettings.QTB_MAX_REQUEST_TIMEOUT__c)); // Gitlab-24183, Gitlab-24525 Added Timeout 
            request.setmethod('POST');
            request.setBody(body);
            HttpResponse response = http.send(request);
            System.debug('CalculateTax() : response@@ '+response);
            System.debug('CalculateTax() : Response_body@@ '+response.getBody());
            
            storeInvoiceCreditNoteRequestResponse(body,response.getBody(),isInvoiceRec);
            if(response.getStatusCode() == 200 &&  response.getStatus() == 'OK'){
                System.debug('success@@');
                //handling success respone for Invoice & CreditNOte
                QTB_IRMVertexResponseUtil.responseMapping(response.getBody(),islastChunk);
            }                
            else{
                System.debug('error@@');
                if(isInvoiceRec){
                    //handling response error for invoice
                    QTB_IRMVertexResponseUtil.handleErrorResponseMapping(response.getBody(),invoiceOrCreditNote, invoiceLineOrUsageListForTax, invoiceIdToInvoiceLineMap,invoiceIdToUsageSummaryMap,invoiceIdToUsageMap); 
                }
                else{
                    //handling response error for creditNote
                    QTB_IRMVertexResponseUtil.handleErrorResponseMapping(response.getBody(),invoiceOrCreditNote, invoiceLineOrUsageListForTax,null,null,null); 
                }
            }
        }
        catch (Exception e) {   
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_IRMToVertexService.callCalculateTaxService()');
        }         
    }
    
    /*********************************************************************************************************
* Method Name: storeInvoiceCreditNoteRequestResponse
* Parameters:  string requestBody, string responseBody, boolean isInvoiceRec
* Return Type: void   
* Company    : Virtusa
* Developer  : Shailesh/Ramesh
* Description: This method will set request and response values on fields in QTB_IRM_to_Vertex_Tax_Request__c &
QTB_IRM_to_Vertex_Tax_Response__c on Invoice and Credit note records
**********************************************************************************************************/
    
    public static void storeInvoiceCreditNoteRequestResponse(string requestBody, string responseBody, boolean isInvoiceRec){
        try{
            string manipulateRequestBody = requestBody.substringAfter('transactionId="');
            Integer requestResponseFieldSize = 131000;  //request, response field size is 131072 char, so setting the field size limit
            System.debug('manipulateRequestBody@@'+manipulateRequestBody);
            Id invoiceOrCreditNoteId = manipulateRequestBody.substringBefore('">');
            // boolean isInvoiceUpdate = invoiceOrCreditNoteId.getSobjectType() == blng__Invoice__c.getSObjectType()? true: false;
            System.debug('invoiceOrCreditNoteId@@'+invoiceOrCreditNoteId); 
            if(isInvoiceRec){
                system.debug('Invoice request@@');
                blng__Invoice__c inv = new blng__Invoice__c();
                inv.Id = invoiceOrCreditNoteId;
                if(requestBody != null && requestBody.length() > requestResponseFieldSize){
                    inv.QTB_IRM_to_Vertex_Tax_Request__c = requestBody.substring(0,requestResponseFieldSize);
                }
                else{
                    inv.QTB_IRM_to_Vertex_Tax_Request__c = requestBody;
                }
                if(responseBody != null && responseBody.length() > requestResponseFieldSize){
                    inv.QTB_IRM_to_Vertex_Tax_Response__c = responseBody.substring(0,requestResponseFieldSize);
                }else{
                    inv.QTB_IRM_to_Vertex_Tax_Response__c = responseBody;
                }
                update inv;                
            }
            else{
                system.debug('Credit note request@@');
                blng__CreditNote__c crd = new blng__CreditNote__c();
                crd.Id = invoiceOrCreditNoteId;
                if(requestBody != null && requestBody.length() > requestResponseFieldSize){
                    crd.QTB_IRM_to_Vertex_Tax_Request__c = requestBody.substring(0,requestResponseFieldSize);
                }
                else{
                    crd.QTB_IRM_to_Vertex_Tax_Request__c = requestBody;
                }
                if(responseBody != null && responseBody.length() > requestResponseFieldSize){
                    crd.QTB_IRM_to_Vertex_Tax_Response__c = responseBody.substring(0,requestResponseFieldSize);
                }else{
                    crd.QTB_IRM_to_Vertex_Tax_Response__c = responseBody;
                }
                update crd;
            }
        }
        catch (Exception e) {   
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_IRMToVertexService.storeInvoiceCreditNoteRequestResponse');
        }   
    }
}