/****************************** 
   Developer Name    : Madhu Paladugu
   Date              : 3/14/13
   Company Name      : CloudFountain Inc.
   Purpose           : This Batch Class contain the logic to modify the email fields that are included in custom setting
                       "ChangeEmailToInvalid" to "Invalid@ironmountain.com" on contact,lead and Case. this class will run in only sandboxes
   Method Invocation : Users has to schedule this class using scheduler with name "SchedulerOfChaingEmails" from UI.
   
   Scheduler class   : SchedulerOfChaingEmails
   
   Test Class        : Test_BatchJobToChangeEmails
   
    Dependents       : Class           :Test_BatchJobToChangeEmails,BatchJobToChangeEmails
                       Custom settings : ChangeEmailToInvalid
                                  
 ********************************/  

    /* Comment - This class has been commented out as to not allow updation of emails in custom settings, case, contact
                    and Lead's email address. */

global class BatchJobToChangeEmails implements Database.Batchable<sObject>, Database.Stateful {
   public String QUERY_TO_EXECUTE;
   public Integer REC_PROCESSED=0;
   public Integer REC_UPDATE=0;
   public Integer REC_DELETED=0; 
   String ObjectName='';
 
   public Set<String> fieldsInThisBatch=new Set<String>();
 
   //Constructor for this class
   
 /*  public BatchJobToChangeEmails(String QueryString){
      
      //Getting the email fileds which are mention in custom setting tochange value to "invalid@ironmountain.com".
      
       QUERY_TO_EXECUTE=QueryString;
       ObjectName=QueryString.substringAfter('from ').substringBefore(' ');
       system.debug('++++++++object name++++++'+ObjectName);
        
        List<ChangeEmailToInvalid__c> Cust_List=[select Object__c,Field__c from ChangeEmailToInvalid__c where Object__c=:ObjectName];
        
        for(ChangeEmailToInvalid__c c:Cust_List){
           fieldsInThisBatch.add(c.Field__c);
        }
       system.debug('++++++++++++fields are+++++'+fieldsInThisBatch);
       
   } */
   // start method
   
   global Database.QueryLocator start(Database.BatchableContext BC){
  /*     system.debug('+++++++++QUERY_TO_EXECUTE++++++++'+QUERY_TO_EXECUTE);
        if(Test.isRunningTest()){
            String QueryTest=QUERY_TO_EXECUTE+' limit 20';
            return Database.getQueryLocator(+QueryTest);
        }
        else{
        
            return Database.getQueryLocator(+QUERY_TO_EXECUTE);
        }
       */
       QUERY_TO_EXECUTE='Select Object__c,Field__c from ChangeEmailToInvalid__c limit1';
       return Database.getQueryLocator(+QUERY_TO_EXECUTE); 
    }
    
    //execute method
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
       
        /*List<sObject> OBJ_NEEDS_UPDATE=new List<sObject>();
        List<sObject> List_Needs_To_Del=new List<sObject>();
        
        //block of code to change email field values 
        
        for(SObject sObj:scope){
            Boolean ischanged=false;
                for(String s:fieldsInThisBatch){
                    if(sObj.get(s)!='invalid@ironmountain.com' && sObj.get(s)!=null){
                        sObj.put(s,'invalid@ironmountain.com');
                        ischanged=true;
                    }
                }
                if(ischanged)
                OBJ_NEEDS_UPDATE.add(sObj);
            }
           system.debug('++++++++++update list++++++++'+OBJ_NEEDS_UPDATE); 
          REC_PROCESSED=REC_PROCESSED+Scope.size();
          REC_UPDATE=REC_UPDATE+OBJ_NEEDS_UPDATE.size();
         
         try{
             Database.SaveResult[] sr=DataBase.Update(OBJ_NEEDS_UPDATE,false);
             for(Integer i=0;i<sr.size();i++){
                if(!sr[i].isSuccess()){
                   REC_UPDATE=REC_UPDATE-1; 
                   sobject temp=OBJ_NEEDS_UPDATE.get(i);
                   List_Needs_To_Del.add(temp);
                   
                }
              }
              system.debug('+++++++delete list++++++'+List_Needs_To_Del);
              REC_DELETED+=List_Needs_To_Del.size();
              Database.DeleteResult[] sr1=DataBase.delete(List_Needs_To_Del,false);
              for(Integer i=0;i<sr1.size();i++){
                if(!sr1[i].isSuccess()){
                    REC_DELETED=REC_DELETED-1;
                }
              }
         }
         catch(Exception ex){
             system.debug('++++++++ do nothing++++++++');
         } */
         
         
    }
    // finish methodcontains logic to sena out an email to user who scheduled this class with sucess/failure report.
   
    global void finish(Database.BatchableContext BC){
          //deleting last run batch
        /*ChangeEmailToInvalid__c b=ChangeEmailToInvalid__c.getInstance('LastBatchJobId');        
        try{
        System.abortJob(b.scheduled_id__c);
        }
        catch(exception e){
            system.debug('+++++++++++do nothing+++++++++');
        }
         
         AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :BC.getJobId()];
        
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {job.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Changing the emails Apex Batch Job on '+ObjectName+': ' + job.Status);
        mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
            '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.' +
            '\n\nTotal records processed: ' + REC_PROCESSED +
            '\nTotal records updated: ' + REC_UPDATE+
            '\n Total records deleted: '+ REC_DELETED);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception e){
            system.debug('++++++++do nothing++++++++');
        }*/
       
        
    }

}