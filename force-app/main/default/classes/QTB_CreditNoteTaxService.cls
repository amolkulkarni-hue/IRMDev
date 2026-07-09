/**
 * @class       CreditNoteTaxService
 * @author      Accenture
 * @purpose     Estimates and applies tax on the credit note lines
 * @date        03/31/2021
 * @requirement `GitLab # 1731`
 */
public inherited sharing class QTB_CreditNoteTaxService implements System.Queueable {
	@TestVisible
	private Boolean throwExplicitException = false;
	private final String action;
	private final Id creditNoteId;
	private final Id invoiceId;
	public QTB_CreditNoteTaxService(Id creditNoteId, Id invoiceId, String action) {
		this.creditNoteId = creditNoteId;
		this.invoiceId = invoiceId;
		this.action = action.toUpperCase();
	}
	public void execute(System.QueueableContext context) {
		String result = 'Tax Error';
		if (this.action.equalsIgnoreCase('ESTIMATE')) {
			result = 'Estimate Tax ' + this.estimateTax();
		}
		if (this.action.equalsIgnoreCase('APPLY')) {
			result = 'Apply Tax and Allocate ' + this.applyTax();
		}
	}
	@TestVisible
	private String estimateTax() {
		try {
			if (this.throwExplicitException) {
				throw new System.NoAccessException();
			}
			return blng.CreditNoteLineAPI.estimateTaxForCreditNoteLines(this.creditNoteId);
		} catch (Exception exc) {
			QTB_ExceptionLogger.createLog(exc, 'QTB_CreditNoteTaxService');
			throw exc;
		}
	}
	@TestVisible
	private String applyTax() {
		try {
			if (this.throwExplicitException) {
				throw new System.NoAccessException();
			}
			return blng.CreditNoteAPI.postTaxForCreditNote(this.creditNoteId);
		} catch (Exception exc) {
			QTB_ExceptionLogger.createLog(exc, 'QTB_CreditNoteTaxService');
			throw exc;
		}
	}
}