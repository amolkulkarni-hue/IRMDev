/*****************************************************************************************************
* Class			: QTB_SbaaApprovalTriggerHandler
* Test Class  	: QTB_SbaaApprovalTriggerHandler_Test
* Author		: Virtusa
* Purpose		: This is a handler class for business logic to prevent creation of Approval record and throw validation error if credit note tax is not estimated
* Requirement	: GITLAB #20221
* Change History: 11/12/2023
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
Ramesh/Shailesh 11/12/2023   GILAB #20221 - On Account Credit: Tax Calculation Validation when performing On Account Credit
*******************************************************************************************************/
public class QTB_SbaaApprovalTriggerHandler {
    public static void handleBeforeInsert(List<sbaa__Approval__c > newSbaaApprovals) {
        set<Id> creditNoteIds = new set<Id>();
        try{
            for (sbaa__Approval__c  newSbaaApproval : newSbaaApprovals) {
                if(newSbaaApproval.QTB_Credit_Note__c != null){
                    creditNoteIds.add(newSbaaApproval.QTB_Credit_Note__c );
                }
            }
            system.debug('creditNoteIds@@' +creditNoteIds);
            //If CreditNoteIds not empty, then only excuting the below logic to throw error message if Estimate tax button not clicked before sending for approval
            if(!creditNoteIds.isEmpty()){
                Map<Id,blng__CreditNoteLine__c> creditNoteIdWithCreditNoteLineMap = new Map<Id,blng__CreditNoteLine__c>();
                for(blng__CreditNoteLine__c crdLine :  [SELECT Id,Name,QTB_On_Account_Credit_Note_Line__c,blng__TaxStatus__c,blng__TaxErrorMessage__c,QTB_country__c,blng__CreditNote__c,
                                                        blng__CreditNoteLineDate__c,blng__CreditNote__r.blng__CreditNoteDate__c,QTB_Credit_Note_Type__c
                                                        FROM blng__CreditNoteLine__c
                                                        WHERE blng__CreditNote__c IN :creditNoteIds and blng__CalculateTax__c = true  and 
                                                        blng__TaxStatus__c = '' and blng__TaxErrorMessage__c ='' ])
                    
                { 
                    system.debug('crdLine@@' +crdLine);
                    if(!creditNoteIdWithCreditNoteLineMap.containsKey(crdLine.blng__CreditNote__c)){
                        creditNoteIdWithCreditNoteLineMap.put(crdLine.blng__CreditNote__c,crdLine);
                    }
                }                
                
                for (sbaa__Approval__c  newSbaaApproval : newSbaaApprovals) {
                    
                    Date DateObj = Date.today();
					Date finYearStartDate = Date.newInstance(DateObj.year(), 4, 1 );
                    system.debug('finYearStartDate - 1' +finYearStartDate);
                    Date PrevFinYearEndate = finYearStartDate - 1;
                    system.debug('PrevFinYearEndate@@' +PrevFinYearEndate);
					
					Date finYearEndDate = Date.newInstance( DateObj.year()+ 1, 3, 31 );
                    system.debug('finYearEndDate ' +finYearEndDate);
					
					Integer gracemonth = PrevFinYearEndate.Month() + 6 ;
                    system.debug('PrevFinYearEndate.Month()' +PrevFinYearEndate.Month());
				    system.debug ('gracemonth' +gracemonth);
                    String creditNoteCountry;
                    Date creditNoteDate;
					Boolean creditNoteTypeToExclude = false;
					 
                    if( !creditNoteIdWithCreditNoteLineMap.isEmpty() && creditNoteIdWithCreditNoteLineMap.containsKey(newSbaaApproval.QTB_Credit_Note__c))
                    {
                        blng__CreditNoteLine__c crdLineMapVal = creditNoteIdWithCreditNoteLineMap.get(newSbaaApproval.QTB_Credit_Note__c);
                        creditNoteCountry = crdLineMapVal.QTB_country__c != null ? crdLineMapVal.QTB_country__c : null;
                        creditNoteDate = crdLineMapVal.blng__CreditNote__r.blng__CreditNoteDate__c != null
                        				  ? crdLineMapVal.blng__CreditNote__r.blng__CreditNoteDate__c : null;
                      if ( /*crdLineMapVal.QTB_Credit_Note_Type__c !=null GITLAB--30332*/crdLineMapVal.QTB_Credit_Note_Type__c !='Manual Credit' && System.Label.QTB_CreditNoteType_ExcludeForTaxValidation.contains(crdLineMapVal.QTB_Credit_Note_Type__c))
                        {
                            creditNoteTypeToExclude = true ;
                        }
                        system.debug('creditNoteDate.Month()' +creditNoteDate.Month());
                        //QTB_Billing_Only_TAX_Eligible_Countries this custom label does not have India & HongKong country value
                        if( !creditNoteTypeToExclude && creditNoteCountry != null && creditNoteDate != null &&
                           (System.Label.QTB_Billing_Only_TAX_Eligible_Countries.containsIgnoreCase(creditNoteCountry) ||
                           (creditNoteCountry == 'India' && 
                           (creditNoteDate > finYearStartDate || (creditNoteDate < PrevFinYearEndate && creditNoteDate.Month() <= 9)))))
                        {
                             newSbaaApproval.addError(System.label.QTB_EstimateTaxValidation);
                        }
                    }
                }
            }
        }
        Catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_SbaaApprovalTriggerHandler');
        }
    }
}