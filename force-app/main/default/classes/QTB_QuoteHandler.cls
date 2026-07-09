/*****************************************************************************************************
* Class: QTB_QuoteHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Quote object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*           29/5/2020
*******************************************************************************************************/
public with sharing class QTB_QuoteHandler implements ITriggerHandler{
    
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
        Boolean isTriggerDisabled=false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if((custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                  || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                      && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_QUOTE)
                                      && custSetting.Disable_Trigger__c) )
            || QTB_RenewalBillingBatchHelper.blockCustomTrigger || QTB_CreateBillingRecords.blockCustomTrigger))
        { isTriggerDisabled=true; }
        return isTriggerDisabled;
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Quote object.
    ********************************************************************************************************************/
    public void beforeInsert(List<SObject> newItems){
        QTB_QuoteHelper.process(newItems,null,trigger.operationType);
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the Quote object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        QTB_QuoteHelper.process(newItems.values(),(Map<Id, SBQQ__Quote__c>)oldItems,trigger.operationType);
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Quote object.
    ********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){/*no action*/}
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Quote object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        QTB_QuoteHelper.process(newItems,null,trigger.operationType);
        List<SBQQ__Quote__c> newItemsList = (List<SBQQ__Quote__c>) newItems; 
        Map<ID,SBQQ__Quote__c> newMap = new Map<ID,SBQQ__Quote__c>();
        newMap.putAll(newItemsList);
        QTB_QuoteHelper.resetPriceDeferredRenewalQuote(newMap);
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Quote object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        system.debug('inside amend handler');
        QTB_QuoteHelper.process(newItems.values(),(Map<Id, SBQQ__Quote__c>)oldItems,trigger.operationType);
       }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Quote object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){/*no action*/}
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        29-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Quote object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){/*no action*/}      
}