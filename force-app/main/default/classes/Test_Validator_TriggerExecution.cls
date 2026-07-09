@isTest
public class Test_Validator_TriggerExecution{

 private static boolean blnAlreadyDone = false;
 private static boolean blnAlreadyDoneForAfterUpdate = false;
 
 static testmethod void dotest(){
        Validator_TriggerExecution.hasAlreadyDone();
        Validator_TriggerExecution.hasAlreadyDoneForAfterUpdate();
        Validator_TriggerExecution.setAlreadyDone();
        Validator_TriggerExecution.setAlreadyDoneForAfterUpdate();
    }


}