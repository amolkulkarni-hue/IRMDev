/*****************************************************************************************************
* Class: QTB_TaxDetailTriggerHandler
* Author: Virtusa
* Purpose: This is a handler class for all business logic related to Tax Detail object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* 
*******************************************************************************************************/
public class QTB_TaxDetailTriggerHandler implements ITriggerHandler {
    
    public static final String DELIMITERS = '[;,]';
    private static final String CLASSNAME = QTB_TaxDetailTriggerHandler.class.getName();
    public static boolean throwExplicitException = false;  
    public static boolean skipTriggerExecutionTestClass = false;
    /*****************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/
    public Boolean isDisabled(){ 
        Boolean isTriggerDisabled=false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                     && custSetting.SObject_API_Name__c.split(DELIMITERS).contains('QTB_Tax_Detail__c')
                                     && custSetting.Disable_Trigger__c) )){     
        	isTriggerDisabled=true;
        }
        return isTriggerDisabled;
    }
    
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Tax Detail object.
    ********************************************************************************************************************/
    public void beforeInsert(List<SObject> newItems){
        if(!QTB_TaxDetailTriggerHandler.skipTriggerExecutionTestClass){
            List<QTB_Tax_Detail__c> newTaxDetailList = (List<QTB_Tax_Detail__c>) newItems;
            QTB_TaxDetailHelper.process(newTaxDetailList,null,Trigger.OperationType);
        }
    }
 
    /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the Tax Detail object.
    ********************************************************************************************************************/ 
    public void beforeUpdate(Map<ID, SObject> newItems, Map<ID, SObject> oldItems){
        if(!QTB_TaxDetailTriggerHandler.skipTriggerExecutionTestClass){
            Map<ID,QTB_Tax_Detail__c> newTaxDetailMap = (Map<ID,QTB_Tax_Detail__c>)newItems;
            QTB_TaxDetailHelper.process(newTaxDetailMap.values(),(Map<ID,QTB_Tax_Detail__c>)oldItems,Trigger.OperationType);   
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Tax Detail object.
    ********************************************************************************************************************/
    public void beforeDelete(Map<ID,SObject> oldItems){
    }
  
    /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Tax Detail object.
    ********************************************************************************************************************/
    public void afterInsert(List<SObject> newItems) {
        if(!QTB_TaxDetailTriggerHandler.skipTriggerExecutionTestClass){
            List<QTB_Tax_Detail__c> newTaxDetailList = (List<QTB_Tax_Detail__c>) newItems;
            QTB_TaxDetailHelper.process(newTaxDetailList,null,Trigger.OperationType);
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Tax Detail object.
    ********************************************************************************************************************/
    public void afterUpdate(Map<ID,SObject> newItems, Map<ID,SObject> oldItems) {
        if(!QTB_TaxDetailTriggerHandler.skipTriggerExecutionTestClass){
            Map<ID,QTB_Tax_Detail__c> newTaxDetailMap = (Map<ID,QTB_Tax_Detail__c>)newItems;
            QTB_TaxDetailHelper.process(newTaxDetailMap.values(),(Map<ID,QTB_Tax_Detail__c>)oldItems,Trigger.OperationType); 
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Tax Detail object.
    ********************************************************************************************************************/
    public void afterDelete(Map<ID,SObject> oldItems){
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        07-11-2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Tax Detail object.
    ********************************************************************************************************************/
    public void afterUndelete(Map<ID, SObject> oldItems){
    }      

}