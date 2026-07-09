/*****************************************************************************************************
* Class         : QTB_ReCalculationQuote
* Test Class    : QTB_RecalculationQuote_Test
* Purpose       : To trigger Quote reCalculation For Amendment Quote
* Requirement   : Defect #8822
* Author        : Virtusa
* Developer     : Shailesh
* Change History: 
* Developer             Date            Description 
* ------------------------------------------------------------------------------------------- 
* Virtusa            05/30/2022        US #8822 - Defect fix -- Quote Line Price is not reflecting on QuoteLine Consumtion Rate
*******************************************************************************************************/
public with sharing class QTB_ReCalculationQuote {
    
    /*********************************************************************************************************
* Method Name: doQuoteReCalculation
* Parameters : List<Id> QuoteIdList
* Return Type: void   
* Author     : Virtusa
* Description: this method is getting called from Process builder "QTB Quote Line Recalculation in Amendment"
only Amendement Quote's Ids sending from process builder to this method
**********************************************************************************************************/
    @InvocableMethod(Label='QTB_RecalculationQuote' description='This method will do quote recalculation')
    public static void doQuoteReCalculation(List<Id> QuoteIdList) {
        System.debug('doQuoteRecalculation@@'+QuoteIdList);
        doQuoteReCalculationFuture(QuoteIdList);
    }
    
    /*********************************************************************************************************
* Method Name: doQuoteReCalculation
* Parameters : List<Id> QuoteIdList
* Return Type: void   
* Author     : Virtusa
* Description: this method is used to update QTB_Trigger_Quote_Calculation__c field from Quote object, which is responsible to trigger the Quote calculation.
**********************************************************************************************************/
    @future
    public static void doQuoteReCalculationFuture(List<Id> QuoteIds){
        try{
            System.debug('doQuoteRecalculationFuture@@');
            List<SBQQ__Quote__c> quoteListFinal = new List<SBQQ__Quote__c>();
            for(SBQQ__Quote__c quote : [Select Id, QTB_Trigger_Quote_Calculation__c From SBQQ__Quote__c where Id IN :QuoteIds ]){//getting amendment quote
                System.debug('quote@@'+quote); 
                //Need to change/update the QTB_Trigger_Quote_Calculation__c value either true or false, to trigger the Quote re-Calculation
                if( quote.QTB_Trigger_Quote_Calculation__c == true){
                    quote.QTB_Trigger_Quote_Calculation__c = false;
                }
                else{
                    quote.QTB_Trigger_Quote_Calculation__c = true;
                }
                quoteListFinal.add(quote);           
            }
            if(!quoteListFinal.isEmpty()){
                System.debug('quoteListFinal@@'+quoteListFinal);
                update quoteListFinal;
            }         
        }
        catch(Exception e){
            System.debug('QTB_ReCalculationQuote.doQuoteReCalculationFuture@@');
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_ReCalculationQuote.doQuoteReCalculationFuture');
        }
    }
}