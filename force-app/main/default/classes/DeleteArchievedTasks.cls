/*****************************************************************************************************
* Test Class    : DeleteArchievedTasks
* Author        : TCS / IRM
* Purpose       : This is a Batch Class for deletion of archieved tasks based on the filter conditions
* Requirement   : Gitlab US : #31412; To delete old archived tasks and in order to improve the storage space
* Change History: 05/06/2025
* Developer        Date           Description
* -------------------------------------------------------------------------------------------
*        
*  TCS          05/06/2025      Initial draft Gitlab US : #31412
*******************************************************************************************************/
public class DeleteArchievedTasks implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    
    SendTaskDeleteEmail__c configGSC;
    public boolean errorTest = false;  
    
    public Integer batchSize;   
    Public integer errCount = 0;
    public integer successCount = 0;
    public integer recordsProcessed = 0; 
   // public integer cdCount = 0;    
   // public integer exceptionCount = 0;
   // public integer recordstobeProcessed = 0;
    
    public DeleteArchievedTasks(boolean passederrorTest){
        this.errorTest = passederrorTest;
         
        configGSC = new SendTaskDeleteEmail__c();
        configGSC = SendTaskDeleteEmail__c.getValues('ArchivedTaskFilters');
        batchSize=Integer.valueOf(configGSC.batchSize__c);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT ID FROM TASK WHERE IsDeleted = false ';
        
        Date fromDate = configGSC.fromDate__c;
        Date toDate = configGSC.toDate__c;
        Boolean includeArchivedFlag = configGSC.includeArchivedRecords__c;
        Integer recordLimit = Integer.valueOf(configGSC.numberOfRecords__c);
        String objectApi = configGSC.object__c;

        Date AgeingDateGSC=Date.today().addDays(-Integer.valueOf(configGSC.AgeingDays__c));
        system.debug('AgeingDateGSC '+AgeingDateGSC);
      	
        if(includeArchivedFlag){
            query += ' AND IsArchived = true ';
        }
        
        if(objectApi != null && !objectApi.equals('')){
            query += ' AND what.type =:objectApi';
        }
        system.debug('Query after api '+query);
        
        if((fromDate != null && !fromDate.equals('')) && (toDate != null && !toDate.equals(''))){
            query += (' AND CreatedDate >=:fromDate' );
            query += (' AND CreatedDate <:toDate');
        }
        
        if(Test.isRunningTest()){
        	query = 'SELECT Id FROM Task ';
        }
        
        query += ' LIMIT :recordLimit ';
        query += ' ALL ROWS ';
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Task> taskList){
        if(taskList.size()>0 && !taskList.isEmpty()){
            Database.DeleteResult[] drList;
            if(Test.isRunningTest() && errorTest) { 
                //This is for testing Error Case
                Id errorId = taskList[0].Id;
                
                Database.DeleteResult dr = (Database.DeleteResult)
                    JSON.deserialize('{ "id":"'+errorId+'", "success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.DeleteResult.class);
                drList = new List<Database.DeleteResult>();
                drList.add(dr);
            }else{
                
                drList = Database.delete(taskList, false);
            }
            // Database.emptyRecycleBin(taskList);
            if(drList != null && drList.size() > 0){
                recordsProcessed += drList.size();
                for (Database.DeleteResult sr : drList) {
                    
                    //Capturing the Success and errors for the Case deletion 
                    if (sr.isSuccess()) {
                        successCount++;    
                    }else{
                        errCount++;
                    }
                }
            }
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        if(successCount > 0 || errCount > 0){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toDddr = new String[]{};
            toDddr=configGSC.Emails__c.split(',');
            system.debug('toDddr :::'+toDddr);   
            // Sets the paramaters of the email
            email.setSubject( 'Task Deletion - Batch Apex Result for DeleteArchievedTasks' );
            email.setToAddresses( toDddr );
            email.setPlainTextBody( 'Your batch job DeleteArchievedTasks has finished There were total '+(successCount +errCount )+' records. Success Records: '+successCount+' Error records:'+errCount );
           // email.setFileAttachments(emailAttList);
            // Sends the email
            Messaging.SendEmailResult [] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            system.debug('email sent');
        }
    }
    
    public void execute(SchedulableContext sc) {
        If(Test.isRunningTest()){

      		ID jobID = Database.executeBatch(new DeleteArchievedTasks(errorTest), 10);
      		//System.abortJob(jobID);

        }else{
            ID BatchId = Database.executeBatch(new DeleteArchievedTasks(errorTest), batchSize);
        }
    }
}