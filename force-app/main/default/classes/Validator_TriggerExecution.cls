/****************************** 
   Developer Name    : Madhu Paladugu
   Date              : 3/19/13
   Company Name      : CloudFountain Inc.
   Purpose           : This class is used as flag to stop more than one update event for triggers.
   Test Class        : This class itself as test method.
   Case Number       : 01242621
   
 ********************************/ 
global class Validator_TriggerExecution{

    private static boolean blnAlreadyDone = false;
    private static boolean blnAlreadyDoneForAfterUpdate = false;
    
    public static boolean hasAlreadyDone(){ 
        return blnAlreadyDone;
    }
 
        public static void setAlreadyDone() {       
            blnAlreadyDone = true;
    }
      public static boolean hasAlreadyDoneForAfterUpdate(){ 
        return blnAlreadyDoneForAfterUpdate;
    }
 
        public static void setAlreadyDoneForAfterUpdate() {       
            blnAlreadyDoneForAfterUpdate = true;
    }
    static testmethod void dotest(){
        Validator_TriggerExecution.hasAlreadyDone();
        Validator_TriggerExecution.hasAlreadyDoneForAfterUpdate();
        Validator_TriggerExecution.setAlreadyDone();
        Validator_TriggerExecution.setAlreadyDoneForAfterUpdate();
    }
}