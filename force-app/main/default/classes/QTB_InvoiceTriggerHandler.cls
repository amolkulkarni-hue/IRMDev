/*****************************************************************************************************
* Class: QTB_InvoiceTriggerHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Usage object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              28/5/2020
*******************************************************************************************************/
public with sharing class QTB_InvoiceTriggerHandler implements ITriggerHandler {
    
    public static final String DELIMITERS = '[;,]';
    private static final String CLASSNAME = QTB_InvoiceTriggerHandler.class.getName();
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
        Boolean isTriggerDisabled=false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                     && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_BLNG_INVOICE)
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
    * Description: This method is used to handle business logic for before insert event on the Invoice object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        if(!QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass){
            list<blng__Invoice__c> newInvoices= (list<blng__Invoice__c>) newItems;
            QTB_InvoiceHelper.process(newInvoices,null,Trigger.OperationType);
        }
    }
 
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the Invoice object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        if(!QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass){
            Map<ID,blng__Invoice__c> newInvoices = (Map<ID,blng__Invoice__c>)newItems;
            QTB_InvoiceHelper.process(newInvoices.values(),(Map<ID,blng__Invoice__c>)oldItems,Trigger.OperationType);   
        }
        
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the invoice object.
    ********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
    }
  
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Invoice object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        if(!QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass){
            list<blng__Invoice__c> newInvoices= (list<blng__Invoice__c>) newItems;
            Map<ID,blng__Invoice__c> newInvoicesMap=new Map<ID,blng__Invoice__c>();
            QTB_InvoiceHelper.process(newInvoices,null,Trigger.OperationType);
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Invoice object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        if(!QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass){
        Map<ID,blng__Invoice__c> newInvoices = (Map<ID,blng__Invoice__c>)newItems;
        Map<ID,blng__Invoice__c> oldInvoices = (Map<ID,blng__Invoice__c>)oldItems;
        list<blng__Invoice__c> newInvoiceslist=new list<blng__Invoice__c>();
        
           //QTB_InvoiceHelper.updateNotesOnAccountFromUsage(newInvoices.values());
        
         QTB_InvoiceHelper.process(newInvoices.values(),(Map<ID,blng__Invoice__c>)oldItems,Trigger.OperationType); 
        /*if(QTB_RecursiveHandlerCheck.calculatingPOBalanceInv)
        {
            QTB_InvoiceHelper.calculatingPOBalance(newInvoices.values(),(Map<ID,blng__Invoice__c>) oldItems); 
        }*/
        
        
         if(QTB_RecursiveHandlerCheck.afterupdateCheck_UpdatePO)
         {
               
             QTB_InvoiceHelper.updatePOForCreditAndRebill(newInvoices.values(), (Map<ID,blng__Invoice__c>) oldItems);

         }
       
    }
 
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Invoice object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Invoice object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }      

}