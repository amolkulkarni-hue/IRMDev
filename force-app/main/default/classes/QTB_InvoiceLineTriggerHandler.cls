/***********************************************************************************************************
* Class: QTB_InvoiceLineTriggerHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Invoice Line object
* Requirement:
* Change History: 
* Developer      	Date           Description
* ---------------------------------------------------------------------------------------------------------- 
*             	 27/5/2020
* Accenture		 7/29/2020		   added without sharing to allow delete when user has read/edit access
* Virtusa		 27/12/2023		   New parameter (Map<Id,blng__InvoiceLine__c>)oldItems is added in AfterUpdate event related to Tax Rounding issue 
								   for the story #20432 with parameters earlier it was null
************************************************************************************************************/
public without sharing class QTB_InvoiceLineTriggerHandler implements ITriggerHandler{
    
    public static final String DELIMITERS = '[;,]';
     public static boolean throwExplicitException = false;
    /*****************************************************************************************************************
* Author:      Accenture
* Date:        28-05-2020
* Parameters:  None
* Return:      void
* Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
*****************************************************************************************************************/
    public Boolean IsDisabled(){ 
        Boolean isTriggerDisabled = false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                     && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_BLNG_INVOICELINE)
                                     && custSetting.Disable_Trigger__c) )){      
                                         isTriggerDisabled=true;
                                     }
        return isTriggerDisabled;
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for before insert event on the Invoice Line object.
********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        QTB_InvoiceLineHelper.trigController(newItems,null,Trigger.OperationType); 
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for before update event on the Invoice Line object.
********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        QTB_InvoiceLineHelper.trigController(newItems.values(),(Map<Id,blng__InvoiceLine__c>)oldItems,Trigger.OperationType); 
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for before delete event on the Invoice Line object.
********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
        //no action
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after insert event on the Invoice Line object.
********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        QTB_InvoiceLineHelper.trigController(newItems,null,Trigger.OperationType); 
        //no action
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after update event on the Invoice Line object.
********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        QTB_InvoiceLineHelper.trigController(newItems.values(),(Map<Id,blng__InvoiceLine__c>)oldItems,Trigger.OperationType); 
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after delete event on the Invoice Line object.
********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
        //no action
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after undelete event on the Invoice Line object.
********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        //no action
    }      
}