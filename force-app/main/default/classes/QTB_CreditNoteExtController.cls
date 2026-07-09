public with sharing class QTB_CreditNoteExtController {
    private Id creditNoteId;
    public static final string SLASH ='/';
    public static boolean throwExplicitException = false;	
    public QTB_CreditNoteExtController(ApexPages.StandardController stdController) {
        creditNoteId = stdController.getId();
    }
    public PageReference onSubmit() {
        try{
            if (creditNoteId != null) {
                SBAA.ApprovalAPI.submit(creditNoteId, SBAA__Approval__c.QTB_Credit_Note__c);
            }
            if(throwExplicitException){
                throw new NullPointerException();
            }
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                                          QTB_CreditNoteExtController.class.getname());
            throw e;
        }
        return new PageReference(SLASH + creditNoteId);
    }
    
    public PageReference onRecall() {
        try{
            if (creditNoteId != null) {
                SBAA.ApprovalAPI.recall(creditNoteId, SBAA__Approval__c.QTB_Credit_Note__c);
            }
            if(throwExplicitException){
                throw new NullPointerException();
            }
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                                          QTB_CreditNoteExtController.class.getname());
            throw e;
        }
        return new PageReference(SLASH + creditNoteId);
    }
}