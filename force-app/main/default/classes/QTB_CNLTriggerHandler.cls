/*****************************************************************************************************
* Class: QTB_CNLTriggerHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Credit Note Line object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              28/5/2020
*******************************************************************************************************/
public with sharing class QTB_CNLTriggerHandler implements ITriggerHandler{
	private static final String CLASSNAME = QTB_CNLTriggerHandler.class.getName();
    private static final String DELIMITERS = '[;,]';
    public static boolean throwExplicitException = false;	
    
    /*****************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/
    public Boolean IsDisabled(){ 
        Boolean isTriggerDisabled=false;
            Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
            if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
              || (String.isNotBlank(custSetting.SObject_API_Name__c) 
              && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_BLNG_CNL)
              && custSetting.Disable_Trigger__c) )){      
                isTriggerDisabled=true;
            }
        return isTriggerDisabled;
    }
    
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Credit Note Line object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        QTB_CNLHelper.process(newItems,null,Trigger.OperationType);
    }
 
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the Credit Note Line object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        QTB_CNLHelper.process((List<blng__CreditNoteLine__c>)newItems.values(),
                                  (Map<Id, blng__CreditNoteLine__c>)oldItems,Trigger.OperationType);
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Credit Note Line object.
    ********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
        Map<Id, blng__CreditNoteLine__c> creditNoteLineOldMap = (Map<Id, blng__CreditNoteLine__c>) oldItems; 
        QTB_CNLHelper.process(creditNoteLineOldMap.values(),creditNoteLineOldMap, Trigger.operationType); 
    }
  
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Credit Note Line object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        //no action
         QTB_CNLHelper.process(newItems,null,Trigger.OperationType);
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Credit Note Line object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        if(newItems != null){ //added null check
            QTB_CNLHelper.process(newItems.values(),(Map<Id,blng__CreditNoteLine__c>)oldItems,Trigger.OperationType);
        }
        
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Credit Note Line object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
        //no action
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Credit Note Line object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        //no action
    }      
}