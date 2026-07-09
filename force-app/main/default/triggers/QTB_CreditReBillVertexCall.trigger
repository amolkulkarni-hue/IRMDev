/*****************************************************************************************************
* Class         : QTB_UsagesForRebill
* Test Class    : QTB_UsagesForRebill_Test
* Author        : IRM/Virtusa
* Developer     : Gopi/Shailesh    
* Purpose       : This trigger is calling vertex system to perform taxation for credit note, and this applicable only on single invoice rebill process
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Change History: 06/30/2022
* Developer           Date           Description
* -----------------------------------------------------------------------------------------------------
*  Gopi/Shailesh     06/30/2022      Initial Version - Gitlab US #9256 Credit & Rebill
*******************************************************************************************************/
trigger QTB_CreditReBillVertexCall on QTB_CreditRebillVertexCall__e (after insert) {
    Set<Id> creditNoteSetIds = new Set<Id>();
	Set<Id> RebillinvoiceSetIds = new Set<Id>(); // Gitlab US#24777 (Credit/Rebill Billnow)
    for(QTB_CreditRebillVertexCall__e  event : Trigger.New){
        if(event.QTB_CreditNoteId__c != null){
            creditNoteSetIds.add(event.QTB_CreditNoteId__c);
        }
        // Gitlab US#24777 (Credit/Rebill Billnow) for Rebill invoice
        if(event.QTB_Rebill_Invoice_Id__c != null){
            system.debug('QTB_CreditReBillVertexCall invoice');
            RebillinvoiceSetIds.add(event.QTB_Rebill_Invoice_Id__c);
        }
    }
    if(!creditNoteSetIds.isEmpty() && creditNoteSetIds.size() > 0){
        Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,creditNoteSetIds,null,null,false),1);
    }
    // Gitlab US#24777 (Credit/Rebill Billnow) for Rebill invoice
    if(!RebillinvoiceSetIds.isEmpty() && RebillinvoiceSetIds.size() > 0){
         system.debug('QTB_CreditReBillVertexCall execute invoice vertex');
        Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,RebillinvoiceSetIds,null,null,true),1);
    }
}