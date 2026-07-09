/*****************************************************************************************************
* Class: QTB_CreditNoteTriggerHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Credit Note object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              28/5/2020
*******************************************************************************************************/
public with sharing class QTB_CreditNoteTriggerHandler implements ITriggerHandler{
	private static final String CLASSNAME = QTB_CreditNoteTriggerHandler.class.getName();
    public static final String DELIMITERS = '[;,]';
    private Boolean isTriggerDisabled; 
    public void bypass(){ this.isTriggerDisabled=false; }
    public static boolean throwExplicitException = false; 
    public static boolean skipTriggerExecutionTestClass = false;
    /*****************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/
    public Boolean IsDisabled(){ 
        this.isTriggerDisabled = false;
            Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
            if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                     || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                         && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_BLNG_CREDITNOTE)
                                         && custSetting.Disable_Trigger__c) )){      
                                             this.isTriggerDisabled=true;
                                         }
            
        return this.isTriggerDisabled;
    }
    
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Credit Note object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        if(!QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass){
            QTB_CreditNoteHelper.setApprovers(newItems); 
            QTB_CreditNoteHelper.process(newItems,null,null, Trigger.OperationType);
        }
    }
 
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the Credit Note object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    	if(!QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass){
        	QTB_CreditNoteHelper.process(newItems.values(),(Map<Id,blng__CreditNote__c>) newItems,
                                         (Map<Id,blng__CreditNote__c>) oldItems, Trigger.OperationType);
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Credit Note object.
    ********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
        //no action
    }
  
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Credit Note object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        if(!QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass){
        	QTB_CreditNoteHelper.process(newItems,null,null, Trigger.OperationType); 
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Credit Note object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    	if(!QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass){
            QTB_CreditNoteHelper.process((List<blng__CreditNote__c>) newItems.values(), (Map<Id, blng__CreditNote__c>) newItems, 
                                             (Map<Id,blng__CreditNote__c>) oldItems, Trigger.OperationType);
          
            if(QTB_RecursiveHandlerCheck.autoUpdateCred && !test.isRunningTest())
            {
                
                QTB_CreditNoteHelper.autoUpdatePO((List<blng__CreditNote__c>) newItems.values());    
                
            } 
          
            if(QTB_RecursiveHandlerCheck.afterupdateCheck_UpdatePOCred && !test.isRunningTest())
            {
                
               QTB_CreditNoteHelper.CN_AutoupdatePObalance((List<blng__CreditNote__c>) newItems.values(),(Map<Id,blng__CreditNote__c>) oldItems);
                
            }
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Credit Note object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
        //no action
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        27-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Credit Note object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        //no action
    }      
}