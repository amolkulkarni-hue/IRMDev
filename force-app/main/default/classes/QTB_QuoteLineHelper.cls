/************************************************************************************************************
* Class: QTB_QuoteLineHelper
* Author: Accenture
* Purpose: This is a helper class for QTB_QuoteLineHelper
* Requirement: CPQ-38(SPRINT-4)
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture     5/18/2020      Class to concatenate free products
* TCS           4/24/2022      Changes to optimize the recursive SOQL while resetting the DM fields for Amend
*************************************************************************************************************/
public with sharing class QTB_QuoteLineHelper{

    //Static variable used to avoid the recursive SOQL query from resetFields method
    public static Boolean isResetDMFeildsForAmend = false;

    /***********************************************************************************************************
* Method :      process
* Parameters:   List<SBQQ__Quote__c>,Map<Id, SBQQ__Quote__c>,System.TriggerOperation
* Return Type : void
* Description:  This method loops over the list of records to be processed 
**************************************************************************************************************/      
    public static void process(List<SBQQ__QuoteLine__c> newItems, Map<Id, SBQQ__QuoteLine__c> oldMap, System.TriggerOperation operationType) {
        Set<Id> quoteIdSet = new Set<Id>();
        Map<Id,list<SBQQ__QuoteLine__c>> quotelinesMap = new Map<Id,list<SBQQ__QuoteLine__c>>();
        
        for (SBQQ__QuoteLine__c eachLine : newItems) {
            // Add your logic here
            // TODO: get the record from olmap instead of using it all over the place
            switch on operationType {
                when BEFORE_INSERT {
                    if(eachLine.SBQQ__Quote__c <> null){
                        if(quotelinesMap.containsKey(eachLine.SBQQ__Quote__c)){
                            quotelinesMap.get(eachLine.SBQQ__Quote__c).add(eachLine);
                            
                        }else{
                            quotelinesMap.put(eachLine.SBQQ__Quote__c, new list<SBQQ__QuoteLine__c>{eachLine});
                        }  
                    }
                  
                    // GitLab - #11248 start
                    // Only update the clonned Records// No need to add newly added services(SBQQ__Source__c)
                  if(eachLine.SBQQ__Existing__c == true && (eachLine.QTB_Cloned_Quantity__c == 0 || eachLine.QTB_Cloned_Quantity__c == NULL)){
                        eachLine.QTB_Cloned_Quantity__c = eachLine.QTB_Quantity__c;
                   }
                   // Only update the clonned Records// No need to add newly added services(SBQQ__Source__c)
                   if(eachLine.SBQQ__Existing__c == true && eachLine.QTB_Final_Unit_Price__c != 0){
                       eachLine.QTB_Cloned_Unit_Price__c = eachLine.QTB_Final_Unit_Price__c;
                   }
                     // GitLab - #11248 End
                }
                when AFTER_INSERT {
                    if (eachLine.QTB_Offered_for_free__c)
                    {                    
                        quoteIdSet.add(eachLine.SBQQ__Quote__c);
                    }
                }
                when BEFORE_UPDATE 
                {                   
                }
                when AFTER_UPDATE 
                {
                    if(eachLine.QTB_Offered_for_free__c <>oldMap.get(eachLine.Id).QTB_Offered_for_free__c){
                        
                        quoteIdSet.add(eachLine.SBQQ__Quote__c);
                    }
                     
                    
                }
                
                when BEFORE_DELETE {}
                when AFTER_DELETE {
                    if(eachLine.QTB_Offered_for_free__c ){
                        
                        quoteIdSet.add(eachLine.SBQQ__Quote__c);
                    }
                }
                
                
                when else {}
            }            
        }
        if (!quoteIdSet.isEmpty()) { updateProducts(quoteIdSet); }
        //Changes to optimize the recursive SOQL while resetting the DM fields for Amend - Avoid 101 SOQL Exception in Test Class
        if(quotelinesMap != null && !isResetDMFeildsForAmend)
        {
            resetFields(quotelinesMap);
        }
    }  
    
    /*****************************************************************************************************************
* Author:      Accenture
* Date:        5/18/2020
* Parameters:  Map<Id, SBQQ__QuoteLine__c> , Map<Id, SBQQ__QuoteLine__c>
* Return:      void
* Description: Method is used to update free products name on quote when offered for free is checked on quoteline
*****************************************************************************************************************/  
    public static void updateProducts(Set<Id> quoteIdSet) {
        try{
            if(QTB_QuoteLineHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(!quoteIdSet.isEmpty()){
                List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();  
                Map<Id,String> freeProductsMap = new Map<Id, String>();
                for (SBQQ__QuoteLine__c eachQuoteLine :  [SELECT ID, SBQQ__Quote__c, QTB_Offered_for_Free__c, SBQQ__ProductName__c 
                                                          FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN : quoteIdSet AND QTB_Offered_for_Free__c = true ]) 
                {
                    
                    
                    if(freeProductsMap.containsKey(eachQuoteLine.SBQQ__Quote__c)){
                        // if in map the quote id exists it means we have an offered for free quoteline. We need to append the current iteration to existing free products
                        String freeProduct = freeProductsMap.get(eachQuoteLine.SBQQ__Quote__c) + ',' + eachQuoteLine.SBQQ__ProductName__c;
                        freeProductsMap.put(eachQuoteLine.SBQQ__Quote__c, freeProduct);
                        
                    }
                    else{
                        freeProductsMap.put(eachQuoteLine.SBQQ__Quote__c, eachQuoteLine.SBQQ__ProductName__c );
                       
                    }
                } 
                system.debug('freeProductsMap>>>' +freeProductsMap);
                for(Id quoteId :quoteIdSet){
                    SBQQ__Quote__c quote = new SBQQ__Quote__c();
                    quote.id = quoteId;
                    if(freeProductsMap.containsKey(quoteId) ){
                        quote.QTB_Free_Product_Names__c = freeProductsMap.get(quoteId);
                    }
                    else{
                        quote.QTB_Free_Product_Names__c = '';
                    }
                    quotesToUpdate.add(quote);
                }
                
                if (quotesToUpdate.size()>0) {
                    update quotesToUpdate;
                    
                }
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                                          QTB_QuoteLineHelper.class.getname());
            throw e;
        }
    }
      /*****************************************************************************************************************
    * Author:      Accenture
    * Date:        10/09/2020
    * Parameters:  Map<Id,list<SBQQ__QuoteLine__c>>
    * Return:      void
    * Description: Method is used to null the dm source fields at the time creating the amendment quote lines
    *****************************************************************************************************************/
    public static void resetFields( Map<Id,list<SBQQ__QuoteLine__c>> quoteMap){
        try{
            if(QTB_QuoteLineHandler.throwExplicitException){
                throw new NullPointerException();
            }
            //Updating the static variable to avoid the recursive SOQL query
            isResetDMFeildsForAmend = true;
            List<SBQQ__QuoteLine__c> amendQuoteLines = new List<SBQQ__QuoteLine__c>();
            for(SBQQ__Quote__c q : [select id,sbqq__type__c from sbqq__quote__c where id IN: quoteMap.keySet() and sbqq__type__c =: QTB_Constants.QUOTE_TYPE_AMEND]){
                amendQuoteLines.addAll(quoteMap.get(q.id));
            }
            for(SBQQ__QuoteLine__c ql :amendQuoteLines ){
                ql.QTB_DM_Source_ID__c = null;
                ql.QTB_DM_Source_System__c = null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), QTB_QuoteLineHelper.class.getname());
            throw e;
        }
        
    }
}