/***********************************************************************************************
*  @ Apex Name          : QTB_IRMToVertexCalculateTaxController
*  @ Test Class 		: QTB_IRMToVertex_Test
*  @ Description        : Controller Class to Call Vertex service to get tax for draft invoices or Credit Note
*  @ Author             : Virtusa
*  @Created Date        : 12/06/2021
*  Date Modified       Modified By         Description of the update
************************************************************************************************
* 12/06/2021			Virtusa		  Initital Version -- REQ-6291 -- DM MVP UAT - VERTEX - Reprocess DRAFT Invoices/Credit Note
**************************************************************************************************/
public with sharing class QTB_IRMToVertexCalculateTaxController {    
    public Id InvoiceOrCreditNoteId {get;set;}
    public string successMsg {get;set;}
    public string errorMsg {get;set;}
    public string InvoiceOrCreditNoteButton {get;set;}
    public string POSTED = 'Posted';
    
/***********************************************************************************************************
* Method 	  : callVertexService
* Parameters  : null
* Return Type : void
* Requirement : Git #6291
* Description : This method is used for reprocessing the invoice/credit note taxation.
**************************************************************************************************************/
    public void callVertexService(){
        System.debug('callVertexService@@');
        InvoiceOrCreditNoteId = ApexPages.currentPage().getParameters().get('invOrCreditId');
        boolean isInvoiceorCreditNote = InvoiceOrCreditNoteId.getSobjectType() == blng__Invoice__c.getSObjectType()? true: false;
        List<blng__Invoice__c> invoice;
        List<blng__CreditNote__c> creditNote;
        if(isInvoiceorCreditNote){
            InvoiceOrCreditNoteButton = System.label.QTB_ReturnToInvoice;
              invoice = [Select Id,QTB_resendToVertex__c,blng__InvoiceStatus__c,blng__InvoiceRunCreatedBy__c,blng__Account__r.QTB_Legal_Entity_Country__c From blng__Invoice__c
                       where Id =:InvoiceOrCreditNoteId and blng__InvoiceStatus__c != :POSTED  limit 1 ];
            System.debug('invoice@@'+invoice);
        }else{
            // Referenec to  GITLAB #19804 added  QTB_Credit_Note_Type__c != 'Credit Only' to not call credit only credit note for vertax calculation
            InvoiceOrCreditNoteButton = System.label.QTB_ReturnToCreditNote;
            creditNote = [Select id,blng__Status__c,QTB_Country__c,QTB_Credit_Note_Type__c From blng__CreditNote__c 
                          where Id =:InvoiceOrCreditNoteId and blng__Status__c != :POSTED and QTB_Credit_Note_Type__c != 'Credit Only'  limit 1 ];
            System.debug('creditNote@@'+creditNote);
        }
        
        //#857 -- Fetching value from Tax Integration Metadata, to check vertex tax country
        QTB_Tax_Integration_Setting__mdt countryValForVertex = QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration');
        //#857 -- for NA region-- Tax gets calculated using Vertex service, therefore added Country check
        if(countryValForVertex!=null && countryValForVertex.QTB_End_System__c == 'Vertex' && 
           ( (invoice!=null && !invoice.isEmpty() && countryValForVertex.QTB_Country__c.containsIgnoreCase(invoice[0].blng__Account__r.QTB_Legal_Entity_Country__c)) ||
            (creditNote!=null && !creditNote.isEmpty() && countryValForVertex.QTB_Country__c.containsIgnoreCase(creditNote[0].QTB_Country__c))))
        {   	
            successMsg = System.Label.QTB_VertexTaxSuccessMsg;
            if(isInvoiceorCreditNote){
                Set<id> invId = new Set<id>();
                //Gitlab US#24777 (Credit/Rebill Billnow) instead of blng__InvoiceRunCreatedBy__c passing inv.id and Renamed from invRunId to invId
                invId.add(invoice[0].id);//Keep 'Invoice Run' Id
                invoice[0].QTB_resendToVertex__c = true; //#34196 - updating to true, which will be used in trigger condition to call QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride method.
                update invoice;
                Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,invId,null,null, true),integer.valueOf(system.label.QTB_Vertex_Callout_Batch_Size));   
            }else{
                Set<id> creditNoteSetIDs = new Set<id>();
                creditNoteSetIDs.add(creditNote[0].id);
                Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,creditNoteSetIDs,null,null,false),integer.valueOf(system.label.QTB_Vertex_Callout_Batch_Size));
            }
        }else{
            errorMsg = System.Label.QTB_VertexTaxErrorMsg;
        }
    }
    
/***********************************************************************************************************
* Method 	  : Redirect
* Parameters  : null
* Return Type : pagereference
* Requirement : Git #6291
* Description : This method is used for returning to Invoice or CreditNote page on button click
**************************************************************************************************************/
    public pagereference Redirect() {
        String returnTo = ApexPages.currentPage().getParameters().get('returnTo');
        String rUrl = String.isNotBlank(returnTo) ? returnTo + '/' : '/';
        PageReference pageRef = new PageReference(rUrl + InvoiceOrCreditNoteId);
        return pageRef;
    }
}