/****************************** 
   Developer Name    : Venakteswarlu Avula
   
   Date              : 11/13/2013
   
   Company Name      : Iron Mountain India.
   
   Purpose           : Inactive delegated users are causing errors with approval processes. There is no easy way in the UI to resolve this issue so a code solution is necessary.  
         
   Test Class        : Test_removeInactiveUserDlgtedApprvr
   
   Dependents        : Apex Trigger:removeInactiveUserfromDelegatedApprover
   
   Case Number       : 01908242
                                  
 ********************************/  
trigger removeInactiveUserfromDelegatedApprover on User (before Update) {
    public String removeInactiveUsers=null;
    Boolean runremoveInactiveUsers=false;
    
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c == 'User'){
            if(cs.Trigger__c == 'removeInactiveUsers'){
                removeInactiveUsers = cs.Value__c;
            }
        }
    }
    
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            if(removeInactiveUsers == 'True')
            runremoveInactiveUsers = true;
        }
    }
    
    if(runremoveInactiveUsers){
    List<user> newUserLst = Trigger.new;
    List<Id> userIdlst = new List<Id>();
    List<User> objUserList = new List<User>();
    
    
    for(User objNewUser : newUserLst)
    {
        if(objNewUser.IsActive== false)
        {
            userIdlst.add(objNewUser.Id);
        }
    }
    List<User> delAprList = [Select Id, Name, DelegatedApproverId from User where DelegatedApproverId IN:userIdlst];
    for(User objUser: delAprList)
    {
        User updUser = new User();
        updUser.Id = objUser.Id;
        updUser.DelegatedApproverId =  null;
        objUserList.add(updUser);
    }
    
    Update objUserList;
    }
}