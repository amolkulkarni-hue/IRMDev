/*Author             : Abhay Gupta
  Company            : Patni Computer Systems
  Created Date       : 10-May-2011
  Description        : Apex Batch class for deletion of the manual Opportunity share records for all the existing opportunities having Account.BillingCountry as "United States" or 'Canada".
                       This batch class should run nightly to process opportunity share records.
*/
/*
   Developer Name    : Madhu Paladugu
   Case              : 01699566
   Description       : Code optimization 
*/

global class Oppshare_delete_new_batch_class implements Database.Batchable<Sobject>,Database.Stateful 
    {
        public String query;
        public Integer RecordsProcessed{get; private set;}
        public Integer TotalRecords=0;
        Set<string> country = new  Set<string>();
        List <Country_Settings__c> country_list = Country_Settings__c.getall().values();
       // List<Opportunity_Security__c> Opty = Opportunity_Security__c.getall().values();
        string country_query ='';
        
        //Constructor for the batch class.
        global Oppshare_delete_new_batch_class()
        {
              // Creation of string containing list of country names from custom settings.
              for (Country_Settings__c c: country_list)
              {
                if(!country.contains(c.Name))
                 {
                   country.add(c.Name);
                   if(country_query!=''){
                      country_query +=',';
                   }
                   country_query += '\''+c.Name+'\'';
                 }                        
              }                   
                 
              RecordsProcessed = 0;
        }
        
        //Method to get the data to be proceesed i.e the Start method.  
        global database.Querylocator start(Database.BatchableContext context)
            {
                System.debug('============== inside START method ========================');
                
                AsyncApexJob job = [Select CreatedDate from AsyncApexJob where Id = :context.getJobId()]; 
                datetime run_time = job.CreatedDate;
                 
                 //If it's executed by test method, query will take 20 records. Otherwise it will take records satisfied by by query in 'else' condition.
                 if(Test.isRunningTest()){
                    query = 'Select Id from OpportunityShare where opportunity.IsSplit = false limit 10';
                 }else{
                    query = 'Select Id, opportunity.Account.BillingCountry from OpportunityShare where LastModifiedDate <: run_time AND RowCause IN(\'Manual\') AND opportunity.Account.BillingCountry IN ('+country_query +') and opportunity.RecordType.Name!=\'NA Renewal\'';
                 }                 
                
                system.debug('++++++++query+++++++++++++++'+query);
                return Database.getQueryLocator(query);
           }//End of start method.
        
        //Method to execute the batch i.e the Execute method.
        global void execute(Database.BatchableContext context , Sobject[] scope)
            {
               System.debug('============== inside EXECUTE method ========================');
               try
                   {
                      TotalRecords+=scope.size();
                      RecordsProcessed += scope.size();
                      Delete scope;
                      Database.Saveresult[] lsr =  Database.insert(scope, false);
                        //Iterate through saveResults to check for errors.
                        for(Database.Saveresult sr1 : lsr){
                            if(!sr1.isSuccess()){
                              RecordsProcessed -=1;
                            }
                        }                                              
                   }
                  
               catch(Exception e)
                   {
                       RecordsProcessed -= scope.size();
                       system.debug('********' + e.getMessage());
                   }
            } //End of execute method.            
                        
         //Method to be called after the execution i.e the Finish method.
         global void finish(Database.BatchableContext BC)
            {
                System.debug('============== inside FINISH method ========================');
                AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                                    from AsyncApexJob where Id = :BC.getJobId()];        
                // Send an email to the Apex job's submitter notifying of job completion.
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {job.CreatedBy.Email};
                mail.setToAddresses(toAddresses);
                mail.setSubject('Opportunity Share Delete Apex Batch Job: ' + job.Status);
                mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
                '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.'+
                '\nTotal Oppshare records processed: ' + TotalRecords+
                '\nTotal Oppshare records deleted: ' + RecordsProcessed );
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }// End of finish method.
        
         
  }// End of batch class.