/*****************************************************************************************************
* Class: QTB_RecursiveHandlerCheck
* Author: Virtusa
* Change History: 16/01/2024
* Purpose: This is a generic Class to store Recursive handler variables.
*******************************************************************************************************/
public class QTB_RecursiveHandlerCheck {
    
     public static Map<String, Set<Id>> updateInvcAndInvocLineWithTaxOverrideAmntAfterInsert = new Map<String, Set<Id>>();
    public static boolean  updateInvcAndInvocLineWithTaxOverrideAfterInsert = True;
    // Variable to restrict recurssive calling of method from class QTB_InvoiceHelper for the method calculateIndividualTaxAmountsOnInvoiceLineItems
    public static boolean  updateInvcAndInvocLineWithTaxOverrideAfterUpdate = True;
     // Variable to restrict recurssive calling of method from class QTB_InvoiceHelper for the method calculateIndividualTaxAmountsOnInvoiceLineItems
    public static boolean  afterUpdateCheck = True;
     // Variable to restrict recurssive calling of method from class QTB_InvoiceHelper for the method calculateIndividualTaxAmountsOnInvoiceLineItems
    public static boolean  afterInsertCheck = True;
    // Variable to restrict recurssive calling of method from class QTB_InvoiceHelper for the method calculateIndividualTaxAmountsOnInvoiceLineItems
    public static boolean  calculateIndividualTaxAmountsOnInvoiceLineItems = True;
    // Variable to restrict recurssive calling of method from class QTB_CNLHelper for the method taxRoundingOnCreditNote
    public static boolean taxRoundingOnCreditNote = True;
    // Variable to restrict recurssive calling of method from class QTB_CNLHelper for the method OnAccountCreditNoteTaxRounding
    public static boolean OnAccountCreditNoteTaxRounding = True;
    // Variable to restrict recurssive calling of method from class QTB_CreditNoteHelper for the method calculateIndividualTaxAmountsOnCreditNoteLines
    public static boolean calculateIndividualTaxAmountsOnCreditNoteLines = True;
    // Variable to restrict recurssive calling of method from QTB_AccountHelper for method updateAccountForHoldStatus
    public static boolean updateAccountForHoldStatus = True;
    //To create tax detail and update the tax override amount of credit note
    public static boolean updatePartialCreditNoteCheck = True;
    // Variable to restrict recurssive calling of method from QTB_InvoiceRunUtils for method updateUSmForHoldBilling
    public static boolean cancelInvoicesWithHoldBilling = True;
    // Variable to restrict recurssive calling of method from QTB_OrderProductUtils for method updateUSmForHoldBilling
    public static boolean updateAccountHoldBillingStatus = True;
    // #24886 Variable to restrict recurssive calling of method from QTB_AccountHelperUtils for method updatePaymentTermBasedUponAccountPaymentTermValue
    public static boolean updatePaymentTermBasedUponAccountPaymentTermValue = True;
    // #24886 Variable to restrict recurssive calling of method from QTB_OrderHelper for method updateOpPayTermBasedOnOrdPayTerms
    public static boolean updateOpPayTermBasedOnOrdPayTerms = True;
    // #24991 Variable to restrict recurssive calling of method from QTB_AccountHelperUtils for method updateOperationalAccInfoBasedUponBillCUpdate
    public static boolean updateOperationalAccInfoBasedUponBillCUpdate = True;
    // #26371 Variable to restrict recurssive calling of method from QTB_CreditNoteHelper for method updateDueDate
    public static boolean  updateDueDate = True;
    // #26654 Variable to restrict recurssive calling of method from QTB_InvoiceHelper for method updateExchangeRate
    public static boolean  invUpdateExchangeRate = True;
    // #26654 Variable to restrict recurssive calling of method from QTB_CreditNoteHelper for method updateExchangeRate
    public static boolean  cnUpdateExchangeRate = True;
	// #32975 Variable to restrict recurssive Ids passing while calling updateUOMDescription method from QTB_OrderProductUtils
	public static Set<Id>  uomDescriptionUpdateOPCSIds = New Set<Id>();
	 public static boolean updateCorrectAmount = True; // GITLAB #27320
    //Invoice helper class
    public static boolean  afterupdateCheck_process = True;
    public static boolean  afterupdateCheck_UpdatePO = True;
    public static boolean  afterupdateCheck_UpdatePOInv = True;
    public static boolean  afterupdateCheck_UpdatePOCred = True;
    public static boolean  autoUpdateCred = True;
    public static boolean  calculatingPOBalanceInv = True;
    public static boolean  creditRebill = True;
    public static boolean  afterupdateCheck_updateNotesOnAccountFromUsage = True;
    public static boolean  afterUpdateCallVertex = True;// Gitlab US#24173 (Credit/Rebill Billnow)
    public static boolean  afterUpdateCreateReBillCreditNote = True;// Gitlab US#24173 (Credit/Rebill Billnow)
   //cnl Helper class
   public static boolean checkFieldEditableMethod = true;
    public static boolean afterUpdateAfterInsertCN = True;

    public static boolean invoiceNoteRecursiveCheck = true;
    public static boolean updateNoteOnCreditNote = True;
    public static boolean afterUpdateCheck_createSubInvoiceLines = true; // gitlab #30514
    public static boolean afterUpdateCheck_updateInvoiceMRCDates = true; // US #31275 defect fix
    public static boolean afterUpdateCheck_setUsgSummaryInvStatus = true; 
	public static boolean afterUpdate_calculateIndividualTaxAmountsOnInvoiceLineItems = true; // 2910 fix via US #31275
    
    //# 34559 Variable to update Operational Account Associate on Billing Account to handle ROW LOCK error
    public static boolean afterUpdateCheck_updateOperationalAccAssociateOnBlngAcc = True;
    
    
    
    Public static boolean afterUpdate_calculateStdTaxOverrideAmt = true; //#34408


}