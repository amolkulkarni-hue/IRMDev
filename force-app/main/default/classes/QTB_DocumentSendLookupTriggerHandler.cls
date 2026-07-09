/*****************************************************************************************************
* Class 		: QTB_DocumentSendLookupTriggerHandler
* Test Class    : QTB_DocumentSendLookupTriggerHelper_Test
* Author		: Virtusa
* Purpose		: This is a helper class for all business logic related to I object
* Requirement	: Gitlab US #20933 -- Stop schedule call and run the logic based on need
* Change History: 01/22/2024
* Developer        Date           Description
* -------------------------------------------------------------------------------------------
*  Virtusa       01/22/2024      This triggerHandler class handle all the events related to QTB_Documents_Send_Lookup_Queue__c obj
*******************************************************************************************************/
public class QTB_DocumentSendLookupTriggerHandler implements ITriggerHandler {
 	public static final String DELIMITERS = '[;,]';
    private static final String CLASSNAME = QTB_DocumentSendLookupTriggerHandler.class.getName();
    public static boolean throwExplicitException = false;    
    
    /*****************************************************************************************************************
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
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
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
    * Description: This method is used to handle business logic for before insert event on the QTB_Documents_Send_Lookup_Queue__c object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
    }
 
    /*******************************************************************************************************************
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
    * Description: This method is used to handle business logic for before update event on the QTB_Documents_Send_Lookup_Queue__c object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
 
     /*******************************************************************************************************************
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
    * Description: This method is used to handle business logic for before delete event on the QTB_Documents_Send_Lookup_Queue__c object.
    ********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
    }
  
    /*******************************************************************************************************************
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
    * Description: This method is used to handle business logic for after insert event on the QTB_Documents_Send_Lookup_Queue__c object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
    }
 
     /*******************************************************************************************************************
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
    * Description: This method is used to handle business logic for after update event on the QTB_Documents_Send_Lookup_Queue__c object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         Map<ID,QTB_Documents_Send_Lookup_Queue__c> newMap = (Map<ID,QTB_Documents_Send_Lookup_Queue__c>)newItems;
         QTB_DocumentSendLookupTriggerHelper.process(newMap.values(),(Map<ID,QTB_Documents_Send_Lookup_Queue__c>)oldItems,Trigger.OperationType);
    }
 
     /*******************************************************************************************************************
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
    * Description: This method is used to handle business logic for after delete event on the QTB_Documents_Send_Lookup_Queue__c object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
       
    }
 
     /*******************************************************************************************************************
    * Author	 : Virtusa
    * Date		 : 01/22/2024
    * Parameters : None
    * Return	 : void
    * Description: This method is used to handle business logic for after undelete event on the Invoice object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }   
}