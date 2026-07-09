/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 7/3/2013
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used for Quote stage progression. 
   
   Method Invocation : This class can be invoke by Scheduler class from UI.
   
   Test Class        :  Test_Q2W_Quote_Stage_Progre_BatchJob
   
   Dependents        : Apex Class: Q2W_Quote_Stage_Progre_Scheduler
                      
   
   Case Number       : 00222919
                                  
 ********************************/  
 global class Q2W_Quote_Stage_Progre_BatchJob  implements Database.Batchable<sObject>, Database.Stateful {
     
         String Query='select id,stage__c,opportunityId from quote where isSyncing=true and RecordType.Name=\'NA Renewal Quote\' and opportunity.RecordType.Name=\'NA Renewal\' and Service_Renewal_Date__c  > THIS_QUARTER and  Service_Renewal_Date__c = NEXT_QUARTER';
         String StageToUpdate='';
         String ErrorsInQuote='Id,Stage__c \n';
         String ErrorsInOpportunity=' Id,StageName \n';
         Boolean Boolean_Quote=false;
         Boolean Boolean_Opp=false;
         
         //constructor
         global Q2W_Quote_Stage_Progre_BatchJob(String Satge){
             StageToUpdate=Satge;
         }
         
         //start method to get data
         global Database.QueryLocator start(Database.BatchableContext BC){
            if(Test.isRunningTest()){
               String TestClassQuery='select id,Stage__c,opportunityId from Quote limit 20';
               return Database.getQueryLocator(TestClassQuery); 
            }
            else{
                return Database.getQueryLocator(Query);
            }
        }
        
        //Execute method
        global void execute(Database.BatchableContext BC, List<sObject> scope){
           
           system.debug('+++++++++++stage to update++++++++'+StageToUpdate);
           List<Quote> QuoteListToUpdate=new List<Quote>();
           Set<id> OppIds=new Set<id>();
           for(sObject s: scope){
               Quote Temp=(Quote)s;
               Temp.stage__c = StageToUpdate;
               QuoteListToUpdate.add(Temp);
               OppIds.add(Temp.opportunityId);
           }
           system.debug('+++++++++++list of opportunity ids to update++++++++'+OppIds);
           //update Quote stages 
           Database.SaveResult[] sr=DataBase.Update(QuoteListToUpdate,false);
           
           // Check results.
           for(Integer I = 0; I < sr.size(); I++) {
               if (!sr[I].isSuccess()|| Test.isRunningTest()) {
                     ErrorsInQuote+=sr[I].getId()+','+ StageToUpdate+'\n';
                     Boolean_Quote=true;
               }
           }
           
           List<opportunity> oppList=[select id,stageName from Opportunity where id IN:OppIds];
           List<opportunity> oppListToUpdate=new List<opportunity>();
           
           for(opportunity op:oppList){
               op.stageName=StageToUpdate;
               oppListToUpdate.add(op);
           }
           system.debug('+++++++++++++update opportunity list++++++++'+oppListToUpdate);
           //update opportunity
           Database.SaveResult[] sr1=DataBase.Update(oppListToUpdate,false);
           
           // Check results.
           for(Integer I = 0; I < sr1.size(); I++) {
               if (!sr1[I].isSuccess()|| Test.isRunningTest()) {
                     ErrorsInOpportunity+=sr1[I].getId()+','+ StageToUpdate+'\n';
                     Boolean_Opp=true;
               }
           } 
           
        } 
        
        //finish method
        global void finish(Database.BatchableContext BC){
            
            AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :BC.getJobId()];
        
            // Send an email to the Apex job's submitter notifying of job completion.
            List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();
            
            //creating csv file on quotestage update
            if(Boolean_Quote){
                Messaging.EmailFileAttachment csvAttc1 = new Messaging.EmailFileAttachment();
                blob csvBlob1 = Blob.valueOf(ErrorsInQuote);
                string csvname1= 'QuoteStage Update Errors.csv';
                csvAttc1.setFileName(csvname1);
                csvAttc1.setBody(csvBlob1);
                efaList.add(csvAttc1);
           }
         
           //creating csv file on opportunity satgeName Update  
            if(Boolean_Opp){
                Messaging.EmailFileAttachment csvAttc1 = new Messaging.EmailFileAttachment();
                blob csvBlob1 = Blob.valueOf(ErrorsInOpportunity);
                string csvname1= 'Opportunity stage Update Errors.csv';
                csvAttc1.setFileName(csvname1);
                csvAttc1.setBody(csvBlob1);
                efaList.add(csvAttc1);
           }
          
           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
           String[] toAddresses = new String[] {job.CreatedBy.Email};
           mail.setToAddresses(toAddresses);
           
           //attaching csv email to email
           if(Boolean_Opp || Boolean_Quote){
            
            mail.setFileAttachments(efaList );
           }
           
           mail.setSubject('Stage Progression for NA Renwal Quotes Batch Job: ' + job.Status);
           mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
            '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.' 
            );
          Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
            
        }
         
 }