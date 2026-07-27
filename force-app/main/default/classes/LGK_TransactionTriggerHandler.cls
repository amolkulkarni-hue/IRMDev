public class LGK_TransactionTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = false;
    public static final String LGK_Transaction = 'LGK__Transaction__c';
    public static boolean skipTriggerExecutionTestClass = false;
    public static boolean throwExplicitException = false;
    public static final String DELIMITERS = '[;,]';

    // Method to disable trigger execution from custom settings
    public Boolean IsDisabled() { 
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting != null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
            || (String.isNotBlank(custSetting.SObject_API_Name__c) && 
                custSetting.SObject_API_Name__c.split(DELIMITERS).contains(LGK_Transaction)
                && custSetting.Disable_Trigger__c) )){     
            return true;
        } else { 
            return isTriggerDisabled;
        }
    }
    
    public void BeforeInsert(List<SObject> newItems) {
        if(!LGK_TransactionTriggerHandler.skipTriggerExecutionTestClass){
            LGK_TransactionHelper.transactionBeforeInsert((List<LGK__Transaction__c>)newItems);     
        }
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {   
        //Check to avoid multiple calls
        if(!LGK_TransactionHelper.isBeforeUpdateTriggerExecuted){
            if(!LGK_TransactionTriggerHandler.skipTriggerExecutionTestClass){
                LGK_TransactionHelper.transactionBeforeUpdate((List<LGK__Transaction__c>)newItems.values(), (Map<Id, LGK__Transaction__c>)oldItems, (Map<Id, LGK__Transaction__c>)newItems);  
            }
            if(!Test.isRunningTest()){
                LGK_TransactionHelper.isBeforeUpdateTriggerExecuted = true;
            } 
       }
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
    public void AfterInsert(List<SObject> newItems) {}
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    public void AfterDelete(Map<Id, SObject> oldItems) {}
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}