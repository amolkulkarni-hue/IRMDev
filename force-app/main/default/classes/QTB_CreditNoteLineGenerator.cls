/**
 * @class       CreditNoteLineGenerator
 * @author      Accenture
 * @purpose     Generates credit note lines for each invoice line for the given invoice under the given credit note
 * @date        03/31/2021
 * @requirement `GitLab # 1731`
 */
public inherited sharing class QTB_CreditNoteLineGenerator implements Database.Batchable<SObject> {
	@TestVisible
	private class QTB_CreditNoteLineGenerationException extends Exception {
	}
	private final Id invoiceId;
	private final Id creditNoteId;
	public QTB_CreditNoteLineGenerator(Id invoiceId, Id creditNoteId) {
		this.creditNoteId = creditNoteId;
		this.invoiceId = invoiceId;
	}
	/**
	 * This batch class will have all the Invoice Lines under the given Invoice with non-zero balance in the scope
	 */
	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(
			'SELECT Id, blng__Invoice__r.blng__Account__c, blng__Quantity__c, blng__Product__c, blng__TotalAmount__c, blng__Subtotal__c FROM blng__InvoiceLine__c WHERE blng__Balance__c > 0 AND blng__Invoice__c = \'' +
			this.invoiceId +
			'\''
		);
	}
	/**
	 * Insert a credit note line under the given credit note, for each Invoice Line in this batch class scope
	 */
	public void execute(
		Database.BatchableContext context,
		List<blng__InvoiceLine__c> scope
	) {
		/**List<blng__CreditNoteLine__c> creditNoteLines = new List<blng__CreditNoteLine__c>();
		for (blng__InvoiceLine__c eachInvoiceLine : scope) {
			creditNoteLines.add(
				new blng__CreditNoteLine__c(
					blng__CreditNote__c = this.creditNoteId,
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
		try {
			insert creditNoteLines;
		} catch (Exception exc) {
			QTB_ExceptionLogger.enable();
			QTB_ExceptionLogger.createLog(exc, 'QTB_CreditNoteLineGenerator');
			QTB_ExceptionLogger.disable();
			throw new QTB_CreditNoteLineGenerationException(
				// 'Failed to insert credit note lines.',
				exc.getMessage()
			);
		}**/
	}
	/**
	 * If this batch class completes without any errors and failures, initiate tax service on the given credit note
	 */
	public void finish(Database.BatchableContext context) {
		/**AsyncApexJob jobDetails = [
			SELECT Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
			FROM AsyncApexJob
			WHERE Id = :context.getJobId()
		];
		// System.debug(LoggingLevel.DEBUG, String.valueOf(jobDetails));
		if (
			jobDetails.Status == 'Completed' &&
			jobDetails.NumberOfErrors == 0 &&
			jobDetails.JobItemsProcessed == jobDetails.TotalJobItems
		) {
			System.enqueueJob(
				new QTB_CreditNoteTaxService(
					this.creditNoteId,
					this.invoiceId,
					'estimate'
				)
			);
		}**/
	}
}