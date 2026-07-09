/****************************** 
   Developer Name    : Madhu Paladugu
   Date              : 3/19/13
   Company Name      : CloudFountain Inc.
   Purpose           : This class is used as flag to stop more than one update event in opportunityObject trigger.
   Test Class        : This class itself as test method.
   Case Number       : 01242621
   Change Log        : Added One Boolean variable to handle system update of close date on opportunity[Madhu Paladugu,4/22/13]
   
 ********************************/ 
global class Validator_OpportunityObjectTrigger{

    public static boolean blnAlreadyDone = false;
    public static boolean blnAlreadyDoneForAfterUpdate = false;
    
    public static boolean CloseDataOnOpportunity=false;
    
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
        Validator_OpportunityObjectTrigger.hasAlreadyDone();
        Validator_OpportunityObjectTrigger.hasAlreadyDoneForAfterUpdate();
        Validator_OpportunityObjectTrigger.setAlreadyDone();
        Validator_OpportunityObjectTrigger.setAlreadyDoneForAfterUpdate();
    }
}