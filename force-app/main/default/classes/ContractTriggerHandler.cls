/**
* Class         : ContractTriggerHandler 
*
* Author        : Vidya Sagar Hadpad
*
* Date Created  : 06.10.2020
*
* Purpose       : ContractTriggerHandler is a handler class for all business logic related to Contract object
*
* User Story    : W-000359
*/
public class ContractTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = false;
    public static final String CONTRACT = 'Contract';
    public static boolean throwExplicitException = false;    
    public static final String DELIMITERS = '[;,]';
    
    //Method to disable trigger execution from custom settings - Metadata_Activation_Settings__c
    public Boolean IsDisabled(){ 
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) && 
                                     custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_CONTRACT)
                                     && custSetting.Disable_Trigger__c) ))
          {     
                    return true;
            }else{ 
            return isTriggerDisabled;
        }
    }   
    
    
    public void BeforeInsert(List<SObject> newItems) 
    {
        /* Write business logic to execute before insert here or use helper class. */
        ContractHelper.updateContractDates(newItems,null);
        QTB_ContractHelper.process((List<Contract>)newItems,null,null,Trigger.operationType );
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {
        /* Write business logic to execute before update here or use helper class. */
        ContractHelper.updateContractDates(newItems.values(),(Map<Id, Contract>)oldItems);
        QTB_ContractHelper.process(newItems.values(),(Map<Id, Contract>) newItems,null,Trigger.operationType );
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems) 
    {}
    
    public void AfterInsert(List<SObject> newItems) 
    {}
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) 
    {
        QTB_ContractHelper.process(newItems.values(),(Map<Id, Contract>) newItems,(Map<Id, Contract>) oldItems,Trigger.operationType );
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems) 
    {
        /* Write business logic to execute after delete here or use helper class. */   
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems) 
    {
        /* Write business logic to execute after undelete here or use helper class. */   
    }
    
}