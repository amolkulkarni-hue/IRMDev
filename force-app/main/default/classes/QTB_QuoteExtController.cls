/*****************************************************************************************************
* Class: QTB_QuoteExtController 
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Quote object
* Requirement:
* Change History: 
* Developer     Date           	Description
* ------------------------------------------------------------------------------------------- 
*           	29/5/2020
* Accenture		16/7/2020		updated to throw exception back to the user on visualforce page
*******************************************************************************************************/
public with sharing class QTB_QuoteExtController {
    private Id quoteId;
    public static final string SLASH ='/';
    public static boolean throwExplicitException = false;
    public QTB_QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
    }
    public PageReference onSubmit() {
        try {            
            if(throwExplicitException) { throw new NullPointerException(); }
            if (quoteId != null) { SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.QTB_Quote__c); }
        } catch(Exception ex){
        	QTB_ExceptionLogger.createLog(ex.getLineNumber(), ex.getStackTraceString(), ex.getMessage(), 
                                          ex.getTypeName(), QTB_QuoteExtController.class.getname());
            ApexPages.message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getTypeName() + '' + ex.getMessage());
            ApexPages.addMessage(errorMsg);
        }
        return new PageReference(SLASH + quoteId);
    }
    public PageReference onRecall() {
        try{
            if (quoteId != null) {
                SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.QTB_Quote__c);
            }
            if(throwExplicitException){
                throw new NullPointerException();
            }
        }
        catch(Exception ex){
        	QTB_ExceptionLogger.createLog(ex.getLineNumber(), ex.getStackTraceString(), ex.getMessage(), 
                                          ex.getTypeName(), QTB_QuoteExtController.class.getname());
            ApexPages.message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getTypeName() + '' + ex.getMessage());
            ApexPages.addMessage(errorMsg);
        }
        return new PageReference(SLASH + quoteId);
    }
}