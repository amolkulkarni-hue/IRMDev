/**
 * @class       QTB_CreditRebillService
 * @author      Accenture
 * @purpose     Contains methods to support Credit and Rebill experience
 * @date        03/30/2021
 * @requirement `GitLab # 1731` and `GitLab # 2791`
 */
public inherited sharing class QTB_CreditRebillService implements System.Queueable {
	private final Id invoiceId;
	private final String action;
	public QTB_CreditRebillService(Id invoiceId, String action) {
		this.invoiceId = invoiceId;
		this.action = action.toUpperCase();
	}
	public void execute(System.QueueableContext context) {
		if (this.action.equalsIgnoreCase('STATUS UPDATE')) {
			QTB_CreditRebillService.setInvoiceStatusAsIRMRebill(
				new Set<Id>{ this.invoiceId }
			);
		}
	}
	/**
	 * @description		 Update status of the Invoice to IRM Rebill
	 * @param invoiceIds Set of invoice ids to be updated the status on
	 * @return			 `void`
	 * @author           Accenture
	 */
	@SuppressWarnings('PMD.ApexCRUDViolation')
	public static void setInvoiceStatusAsIRMRebill(Set<Id> invoiceIds) {
		List<blng__Invoice__c> toBeUpdated = new List<blng__Invoice__c>();
		for (blng__Invoice__c eachInvoice : [
			SELECT Id, blng__InvoiceStatus__c, blng__Balance__c
			FROM blng__Invoice__c
			WHERE
				Id IN :invoiceIds
				AND blng__InvoiceStatus__c = 'Posted'
				AND blng__Balance__c = 0
			FOR UPDATE
		]) {
			toBeUpdated.add(
				new blng__Invoice__c(
					Id = eachInvoice.Id,
					QTB_Rebilled__c = true
				)
			);
		}
		if (!toBeUpdated.isEmpty()) {
			update toBeUpdated;
		}
	}
	/**
	 * @description This method is used by qtbRebillInvoice component
	 * to initiate crediting process for a rebill invoice
	 * @param invoiceId Id of the invoice to be credited
	 * @param creditNoteId Id of the credit note which credits the given invoice
	 * @return          `String`
	 * @author          Accenture
	 */
	@SuppressWarnings('PMD.ApexCRUDViolation')
	@AuraEnabled
	public static String credit(Id invoiceId, Id creditNoteId) {
		try {
			List<blng__CreditNoteLine__c> creditNoteLines = new List<blng__CreditNoteLine__c>();
			for (blng__InvoiceLine__c eachInvoiceLine : [
				SELECT
					Id,
					blng__Invoice__r.blng__Account__c,
					blng__Quantity__c,
					blng__Product__c,
					blng__TotalAmount__c,
					blng__Subtotal__c
				FROM blng__InvoiceLine__c
				WHERE blng__Balance__c > 0 AND blng__Invoice__c = :invoiceId
				WITH SECURITY_ENFORCED
			]) {
				creditNoteLines.add(
					new blng__CreditNoteLine__c(
						blng__CreditNote__c = creditNoteId,
						QTB_Account__c = eachInvoiceLine.blng__Invoice__r.blng__Account__c,
						QTB_Invoice__c = eachInvoiceLine.blng__Invoice__c,
						QTB_InvoiceLine__c = eachInvoiceLine.Id,
						blng__Product__c = eachInvoiceLine.blng__Product__c,
						QTB_Credit_Quantity__c = eachInvoiceLine.blng__Quantity__c,
						// blng__TotalAmount__c = eachInvoiceLine.blng__TotalAmount__c,
						blng__CalculateTax__c = true,
						blng__Subtotal__c = eachInvoiceLine.blng__Subtotal__c
					)
				);
			}
			insert creditNoteLines;
			QTB_CreateRebillOrder.createRebillOrder(invoiceId);
			return estimateTax(creditNoteId);
		} catch (Exception e) {
			System.debug(System.LoggingLevel.ERROR, e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @description
	 * @param invoiceId Id of the invoice to be rebilled
	 * @return          `String`
	 * @author          Accenture
	 */
	@SuppressWarnings('PMD.ApexCRUDViolation')
	@AuraEnabled
	public static String rebill(Id invoiceId) {
		try {
			update new blng__Invoice__c(Id = invoiceId, QTB_Rebilled__c = true);
			QTB_CreateRebillOrder.createRebillOrder(invoiceId);
			return 'SUCCESS';
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @description estimates the tax on the credit note lines of the given credit note
	 * @param creditNoteId Id of the credit note to estimate tax on
	 * @return          `String`
	 * @author          Accenture
	 */
	@AuraEnabled
	public static String estimateTax(String creditNoteId) {
		try {
			return blng.CreditNoteLineAPI.estimateTaxForCreditNoteLines(
				Id.valueOf(creditNoteId)
			);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @description create credit note lines using batch apex
	 * @param creditNoteId Id of the credit note which credits the given invoice
	 * @param invoiceId Id of the invoice to be credited
	 * @return          `String`
	 * @author          Accenture
	 */
	@AuraEnabled
	public static String batchableCredit(Id invoiceId, Id creditNoteId) {
		try {
			QTB_CreateRebillOrder.createRebillOrder(invoiceId);
			return Database.executeBatch(
				new QTB_CreditNoteLineGenerator(invoiceId, creditNoteId)
			);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}