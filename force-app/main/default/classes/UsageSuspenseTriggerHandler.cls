/**
 * Class: UsageSuspenseTriggerHandler 
 *
 * Author: Vinutha Iyengar
 *
 * Date Created: 25.08.2020
 *
 * Purpose: UsageSuspenseTriggerHandler is a handler class for all business logic related to QTB_Usage_Suspense__c object
 * 
 */
public class UsageSuspenseTriggerHandler implements ITriggerHandler
{
    public static Boolean isTriggerDisabled = false;
    public static final String objName = 'QTB_Usage_Suspense__c';
    public static final String DELIMITERS = '[;,]';
    
    //Method to disable trigger execution from custom settings - Metadata_Activation_Settings__c
    public Boolean IsDisabled(){ 
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) && 
                                     custSetting.SObject_API_Name__c.split(DELIMITERS).contains(objName)
                                     && custSetting.Disable_Trigger__c) )){     
                                         return true;
                                     }
        else{ 
          return isTriggerDisabled;
        }
    }
     
    public void BeforeInsert(List<SObject> newItems)
    {
    }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {   
    }
 
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {  
    }
  
    public void AfterInsert(List<SObject> newItems) 
    {              
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) 
    {               
        List<QTB_Usage_Suspense__c> newItemsList = newItems.values();
        List<QTB_Usage_Suspense__c> recordsToDelete = new List<QTB_Usage_Suspense__c>();
        for(QTB_Usage_Suspense__c rec : newItemsList) 
        {
            if(rec.QTB_Mediation_Status__c == 'Processed')
            {
            	recordsToDelete.add(rec);      
            }
        }
        if(recordsToDelete.size()>0)
        {
            QTB_Invoice_Utils.deleteUsageSuspenses();
        }
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems)
    {
    }
 
    public void AfterUndelete(Map<Id, SObject> oldItems) 
    {
    }      
}