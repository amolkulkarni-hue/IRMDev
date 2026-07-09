/**
 * This class is responsible to link a rebill invoice to the credit note
 * that was generated as part of credit rebill process for a rebilled invoice.
 * @author Accenture
 * @since 06/08/2021
 */
public inherited sharing class QTB_CreditRebillLinkerService implements Queueable {
	private final List<Id> rebillInvoiceIds;
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public QTB_CreditRebillLinkerService() {
	}
	public QTB_CreditRebillLinkerService(List<Id> invoiceIds) {
		this.rebillInvoiceIds = invoiceIds;
	}

	public void execute(QueueableContext context) {
		this.linkRebillInvoiceWithRebillCreditNote(this.rebillInvoiceIds);
	}
	/**
	 * Given the list of rebill invoice ids, link those to the rebill credit note.
	 * @param invoiceIds
	 */
	@TestVisible
	private void linkRebillInvoiceWithRebillCreditNote(List<Id> invoiceIds) {
		if (invoiceIds == null || invoiceIds.isEmpty()) {
			return;
		}
		Map<Id, Id> rebilledInvoiceIdByRebillInvoiceId = getRebilledInvoiceIdByRebillingInvoiceId(
			invoiceIds
		);
		if (
			rebilledInvoiceIdByRebillInvoiceId == null ||
			rebilledInvoiceIdByRebillInvoiceId.isEmpty()
		) {
			return;
		}
		Map<Id, Id> rebillCreditNoteByRebilledInvoiceId = getRebillCreditNoteByRebilledInvoiceId(
			rebilledInvoiceIdByRebillInvoiceId.values()
		);
		if (
			rebillCreditNoteByRebilledInvoiceId == null ||
			rebillCreditNoteByRebilledInvoiceId.isEmpty()
		) {
			return;
		}
		List<blng__CreditNote__c> creditNotesToUpdate = new List<blng__CreditNote__c>();
		for (Id invoiceId : invoiceIds) {
			Id rebillCreditNoteId = rebillCreditNoteByRebilledInvoiceId.get(
				rebilledInvoiceIdByRebillInvoiceId.get(invoiceId)
			);
			creditNotesToUpdate.add(
				new blng__CreditNote__c(
					Id = rebillCreditNoteId,
					QTB_Rebill_Invoice__c = invoiceId
				)
			);
		}
		if (!creditNotesToUpdate.isEmpty()) {
			try {
				update creditNotesToUpdate;
			} catch (Exception exc) {
				QTB_ExceptionLogger.createLog(
					exc,
					'QTB_CreditRebillLinkerService'
				);
			}
		}
	}
	/**
	 * Given a list of rebill invoice ids, returns the corresponding rebilled
	 * invoice id.
	 * @param rebillingInvoiceIds
	 * @return  `Map<Id, Id>`
	 */
	public Map<Id, Id> getRebilledInvoiceIdByRebillingInvoiceId(
		List<Id> rebillingInvoiceIds
	) {
		if (rebillingInvoiceIds == null || rebillingInvoiceIds.isEmpty()) {
			return null;
		}
		Map<Id, Id> rebilledInvoiceIdByRebillingInvoiceId = new Map<Id, Id>();
		for (blng__InvoiceLine__c eachInvoiceLine : [
			SELECT
				Id,
				blng__Invoice__c,
				blng__OrderProduct__r.Order.QTB_OriginalRebillInvoice__c
			FROM blng__InvoiceLine__c
			WHERE blng__Invoice__c = :rebillingInvoiceIds
		]) {
			rebilledInvoiceIdByRebillingInvoiceId.put(
				eachInvoiceLine.blng__Invoice__c,
				eachInvoiceLine.blng__OrderProduct__r
					?.Order
					?.QTB_OriginalRebillInvoice__c
			);
		}
		return rebilledInvoiceIdByRebillingInvoiceId;
	}
	/**
	 * Given a list of rebilled invoice ids, returns the corresponding
	 * credit note that was created as part of credit and rebill.
	 * @param invoiceIds
	 * @return  `Map<Id, Id>`
	 */
	public Map<Id, Id> getRebillCreditNoteByRebilledInvoiceId(
		List<Id> invoiceIds
	) {
		if (invoiceIds == null || invoiceIds.isEmpty()) {
			return null;
		}
		Map<Id, Id> rebillCreditNoteByRebilledInvoiceId = new Map<Id, Id>();
		for (blng__CreditNote__c eachCreditNote : [
			SELECT Id, blng__RelatedInvoice__c, blng__Status__c
			FROM blng__CreditNote__c
			WHERE
				blng__RelatedInvoice__c = :invoiceIds
				AND blng__Status__c = 'Draft'
				AND QTB_For_Rebill__c = TRUE
		]) {
			if (eachCreditNote.blng__RelatedInvoice__c <> null) {
				rebillCreditNoteByRebilledInvoiceId.put(
					eachCreditNote.blng__RelatedInvoice__c,
					eachCreditNote.Id
				);
			}
		}
		return rebillCreditNoteByRebilledInvoiceId;
	}
}