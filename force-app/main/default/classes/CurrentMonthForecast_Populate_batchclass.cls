/*Code written as part of Case 00443373
Author: Raj Gottipolu
     
Author       : Ketan Benegal /Srinu
Company      : CloudFountain Inc.
Modified Date: 10-Aug-2012
Case No.     : 00443373
Description  : Batch Class will only set the Update_New_Revenue_Forecast__c field to true. 
               This will fire the maintainOpportunityForecast trigger.                               

Author       : Srinivasa Rao Mandalapu
Company      : CloudFountain Inc.
Modified     : Modified on 11/06. Removed unnecessary methods and variables in part of optimization.
*/

global Class CurrentMonthForecast_Populate_batchclass implements Database.Batchable<Sobject>,Database.Stateful{
    
    public String query{get;set;}
    public Integer RecordsProcessed{get; private set;}
    public Integer RecordsUpdated{get; private set;}
    global static final String objName = 'Populate Current Month Forecast';
    
    global CurrentMonthForecast_Populate_batchclass(){
        query = 'Select Id, Current_Month_Forecast_Date__c, Current_Month_Forecast_Amount__c, Opportunity.Owner.Sales_Division__c, OpportunityId, Update_New_Revenue_Forecast__c from OpportunityLineItem where Opportunity.Owner.Sales_Division__c=\'North America\''; 
    }
    
    global CurrentMonthForecast_Populate_batchclass(String str){
        query = str;
    }    
    
    //Method to get the data to be proceesed i.e the Start method.  
    global database.Querylocator start(Database.BatchableContext context){                
        System.debug('============== inside START method ========================');
        AsyncApexJob job = [Select CreatedDate from AsyncApexJob where Id = :context.getJobId()];        
        datetime run_time = job.CreatedDate;        
        recordsProcessed = 0;
        recordsUpdated = 0;
        if(Test.isRunningTest()){
            String TestQuery=query+' limit 20';
            return Database.getQueryLocator(TestQuery);
        }
        else{
            return Database.getQueryLocator(query);  
        }  
    }
    
    global void execute(Database.BatchableContext context , Sobject[] scope){
        try {
            System.debug('=============inside execute method============');
            List<OpportunityLineItem> oppitemlist = new List<OpportunityLineItem>();            
            for(sObject s: scope){                                                
                OpportunityLineItem ol = (OpportunityLineItem) s;                
                ol.Update_New_Revenue_Forecast__c = true;                
                oppitemlist.add(ol);
                recordsUpdated++;
            } 
            Database.Saveresult[] lsr =  Database.update(oppitemlist, false);            
            //Iterate through saveResults to check for errors.
            for(Database.Saveresult sr1 : lsr){
                if(!sr1.isSuccess()){
                    Database.Error err = sr1.getErrors()[0];
                }
            }                               
            recordsProcessed = recordsProcessed + scope.size();
        }Catch(Exception e){
            System.debug(e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('============== inside FINISH method ========================');
        AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname from AsyncApexJob where Id = :BC.getJobId()]; 
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {job.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject(objName + ' Apex Batch Job: ' + job.Status);
        mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
        '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.'+
        '\n\nTotal Opportunity Products processed: ' + recordsProcessed +        
        '\n\nTotal records updated: ' + recordsUpdated);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                
    }
}