/*****************************************************************************************************
* Class: QTB_QuoteLineHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Quote line object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*           27/5/2020
*******************************************************************************************************/
public with sharing class QTB_QuoteLineHandler implements ITriggerHandler{

    public static final String DELIMITERS = '[;,]';
    public static boolean throwExplicitException = false;
    
	/*****************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/    
    //Method to disable trigger execution from custom settings - Metadata_Activation_Settings__c
    public Boolean IsDisabled(){ 
        Boolean isTriggerDisabled = false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if((custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                  || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                      && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.TYPE_SBQQ_QUOTELINE)
                                      && custSetting.Disable_Trigger__c) )) 
           || QTB_RenewalBillingBatchHelper.blockCustomTrigger || QTB_CreateBillingRecords.blockCustomTrigger)
        { isTriggerDisabled=true; }
        return isTriggerDisabled;
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Quote Line object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
         QTB_QuoteLineHelper.process((List<SBQQ__QuoteLine__c>)newItems,null,Trigger.operationType);
    }
 
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the Quote Line object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        //no action
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Quote line object.
    ********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
        //no action
    }
  
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Quote line object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        QTB_QuoteLineHelper.process((List<SBQQ__QuoteLine__c>)newItems,null,Trigger.operationType);
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Quote Line object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        QTB_QuoteLineHelper.process((List<SBQQ__QuoteLine__c>) newItems.values(),(Map<Id, SBQQ__QuoteLine__c>) oldItems, Trigger.operationType);
        
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Quote Line object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
        Map<Id, SBQQ__QuoteLine__c> quoteLineOldMap = (Map<Id, SBQQ__QuoteLine__c>) oldItems; 
        QTB_QuoteLineHelper.process(quoteLineOldMap.values(),quoteLineOldMap, Trigger.operationType); 
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Quote line object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        //no action
    }      
}