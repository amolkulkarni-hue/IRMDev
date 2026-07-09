/*
    @Class : OpportunityLineItemTriggerHandler 
    @Author : Gouthami Redlapalli
    @BuiltDate : 05.05.2020
    @Description : OpportunityLineItemTriggerHandler is a handler class for all business logic related to OpportunityLineItem object
    */
public class OpportunityLineItemTriggerHandler implements ITriggerHandler {
   
    public static Boolean isTriggerDisabled = false;
    public static final String OpportunityProduct = 'OpportunityLineItem';
 
   //Method to disable trigger execution from custom settings - Metadata_Activation_Settings__c
    public Boolean IsDisabled(){ 
        if ((Metadata_Activation_Settings__c.getInstance(UserInfo.getUserId()).SObject_API_Name__c==OpportunityProduct || Metadata_Activation_Settings__c.getInstance(UserInfo.getProfileId()).SObject_API_Name__c==OpportunityProduct) && 
           (Metadata_Activation_Settings__c.getInstance(UserInfo.getUserId()).Disable_Trigger__c || Metadata_Activation_Settings__c.getInstance(UserInfo.getProfileId()).Disable_Trigger__c)){     
            return true;
        }
        else{ 
          return isTriggerDisabled;
        }
    }
        
    public void BeforeInsert(List<SObject> newItems){ 
     }
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
 
    public  void BeforeDelete(Map<Id, SObject> oldItems){
    }
 
    public void AfterInsert(List<SObject> newItems){       
    }
 
    public  void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){          
    }
 
    public  void AfterDelete(Map<Id, SObject> oldItems){
       OpportunitylineitemHelper.OppBundleDelete(oldItems);    
 	}
 
    public  void AfterUndelete(Map<Id, SObject> oldItems){
    }

} // End of OpportunityLineItemTriggerHandler Class