/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 8/1/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used to sync IMGA Formula filed value with IMGA Text filed value. 
   
   Test Class        : Test_BillingsToBoBCoverage_SyncIMGA_Name .
   
   Case Number       : 01347129
                                  
 ********************************/  

 /* Commenting the entire code as part of Gitlab #24446 */
 global class BillingsToBoBCoverage_SyncIMGA_Name
 {
     public BillingsToBoBCoverage_SyncIMGA_Name(){
         
     }
 }

 /*
 global class BillingsToBoBCoverage_SyncIMGA_Name implements Database.Batchable<sObject>,Database.Stateful {
   
    public String QUERY_TO_EXECUTE='select id,IMGA_Name_Formula__c,IMGA_Name_Text__c from Billings__c where  IMGA_Name_Change__c=\'TRUE\'' ;
    Integer ToatalRecords=0;
    Integer TotalErrors=0;
    String UseThisCustomSetting;
    public BillingsToBoBCoverage_Helper helper; 
       
     global BillingsToBoBCoverage_SyncIMGA_Name(String CustomsettingName){
        UseThisCustomSetting=CustomsettingName;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
         BillingsToBoBCoverageJoins__c settings=BillingsToBoBCoverageJoins__c.getInstance(UseThisCustomSetting);
         Date CurrentDate=Date.Today();
         String CurrentYear=string.ValueOf(CurrentDate.Year());
         String PreviousYear=string.ValueOf(CurrentDate.Year()-1);
         QUERY_TO_EXECUTE+=' and  (Billing_Year__c=\''+CurrentYear+'\''+'  or Billing_Year__c=\''+PreviousYear+'\')'+'';
         if(settings!= null)
         QUERY_TO_EXECUTE+=settings.RecordTypeId__c;
         system.debug('+++++++++QUERY_TO_EXECUTE++++++++'+QUERY_TO_EXECUTE);
         return Database.getQueryLocator(+QUERY_TO_EXECUTE);
         
     }
     
     //execute method
     global void execute(Database.BatchableContext BC, List<sObject> scope){
      
         
         //block of code to copy formula value into text filed
         List<sObject> updateList=new List<sObject>();
         for(SObject sObj:scope){
                 sObj.put('IMGA_Name_Text__c',sObj.get('IMGA_Name_Formula__c'));
                       updateList.add(sObj);
          }
          ToatalRecords+=scope.size();
           // are there join records to be inserted? 
           Database.SaveResult[] results=Database.update(updateList, false);  
           if (results != null  &&  !results.isEmpty()) {   
             // evaluate the outcome for each record
             for (Integer lpcnt = 0; lpcnt < results.size(); lpcnt++) {
                 // unsuccessful?
                 if (!results[lpcnt].isSuccess()) {
                     // keep count of all failures as errors
                     TotalErrors++;                            
                 } 
             }
           } 
          
     }
     // finish methodcontains logic to sena out an email to user who scheduled this class with sucess/failure report.
    
     global void finish(Database.BatchableContext BC){
        helper=new BillingsToBoBCoverage_Helper(UseThisCustomSetting);
        BillingsToBoBCoverageJoins__c settings=BillingsToBoBCoverageJoins__c.getInstance(UseThisCustomSetting); 
        String jobSummary=   '\n    Total Batch Size:           ' + ToatalRecords.format().leftPad(7)          +        
                             '\n    Number Of Errors on Update: ' + TotalErrors.format().leftPad(7); 
                             
         // create a Chatter post summarizing the outcome of this run
         helper.postToChatterGroup(settings.Chatter_Group__c, 
             'The BillingsToBoBCoverage_SyncIMGA_NAME batch job has completed.' + jobSummary);        
            
                            
     }
 }
     */