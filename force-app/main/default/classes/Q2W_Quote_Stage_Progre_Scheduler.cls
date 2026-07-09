/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 7/3/2013
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used for Quote stage progression batch job's scheduler. 
   
   Test Class        : Test_Q2W_Quote_Stage_Progre_BatchJob
   
   Dependents        : Apex Class: Q2W_Quote_Stage_Progre_BatchJob
   
   Case Number       : 00222919
                                  
 ********************************/  

global class  Q2W_Quote_Stage_Progre_Scheduler implements Schedulable{
   
    //execute method with each batch size of 200 records
    Global void execute(SchedulableContext sc){
        
        Quote_Stage_Progression_Dates__c custData;
        try{
            custData=[select Next_Progression_Stage__c,Progression_Date__c from Quote_Stage_Progression_Dates__c where Progression_Date__c = TODAY limit 1]; 
        }
        catch(Exception e){
            system.debug('++++++++do nothing++++++++');
        }
        if(custData!=null){
            system.debug('++++++++++Executing stage progression on +++++++++'+Date.today());
            database.executebatch(new Q2W_Quote_Stage_Progre_BatchJob(custData.Next_Progression_Stage__c),200); 
        }
    }
}