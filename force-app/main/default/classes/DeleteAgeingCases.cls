/**
* Class: DeleteAgeingCases
*
* Author: TCS
*
* Purpose: This is a Batch class for to delete the cases once the related objects records got deleted.
*		   It is being invoked from DeleteRelatedObjectofAgeingCases.
*
* Requirement: GitLab #5516  
*
* Change History:
*
* Developer                     Date 	             		Description
* -------------------------------------------------------------------------------------------
* TCS                          11/Nov/2022                  Initial code
*/

global class DeleteAgeingCases implements Database.Batchable<sObject>, Database.Stateful{
    String query;
    //String baseURL;
    
    Set<Id> caseIdsToDelete;
    //Map<Id, String> successMap;
    //Map<Id, String> errorMap;
    //Map<Id, SObject> IdToSObjectMap;
    
    integer recordsProcessed = 0;
    integer errCount = 0;
    integer successCount = 0;
    Case_Deletion_Config__c config;
    boolean errorTest;
    String finalstr = 'Id, Subject, Error \n';
    
    global DeleteAgeingCases(Set<Id> caseIdsPassed,boolean passederrorTest){
        //system.debug('caseIdsPassed '+caseIdsPassed);
        caseIdsToDelete = caseIdsPassed;
        system.debug('size passed to class '+caseIdsToDelete.size());
        this.errorTest = passederrorTest;
        //successMap = new Map<Id,String>();
        //errorMap = new Map<Id, String>();
        //IdToSObjectMap = new Map<Id, SObject>();
        config = Case_Deletion_Config__c.getValues('Greater than 3 years');
        //baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        query = 'SELECT id,RecordType.Name,subject from case WHERE Id IN :caseIdsToDelete';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //system.debug('caseIdsToDelete '+caseIdsToDelete);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Integer index = 0;
        Database.DeleteResult[] drList;
        
        // Delete the cases
        if(Test.isRunningTest() && errorTest) { 
            //system.debug('scope[0].Id '+scope[0].Id);
            Id errorId = scope[0].Id;
            Database.DeleteResult dr = (Database.DeleteResult)
                JSON.deserialize('{ "id":"'+errorId+'", "success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.DeleteResult.class);
            drList = new List<Database.DeleteResult>();
            drList.add(dr);
        }else{
            
            drList = Database.delete(scope, false);
        }
        Map<Id, String> recyCleBinMap = new Map<Id,String>(); 
        // Iterate through each returned result
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                //String sucMsg = baseURL + '/' + dr.Id;
                //successMap.put(dr.getId(), dr.Id);
                recyCleBinMap.put(dr.getId(), dr.Id);
                successCount++;
                // Operation was successful, so get the ID of the record that was processed
                //System.debug('Successfully deleted account with ID: ' + dr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : dr.getErrors()) {
                    String recordString = '"'+dr.getId()+'","'+((Case)scope[index]).Subject+'","'+err.getMessage()+'"\n';
                    finalstr = finalstr +recordString;
                    errCount++;
                    //errorMap.put(dr.getId(), err.getMessage());
                    // System.debug('The following error has occurred.');                    
                    System.debug('The following error has occurred. \n'+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
            //IdToSObjectMap.put(scope[index].Id, scope[index]);
            index++;
        }
        recordsProcessed = recordsProcessed + scope.size();
        if(recyCleBinMap != null && recyCleBinMap.size() > 0){
            Database.emptyRecycleBin(new List<Id>(recyCleBinMap.keySet()));
            recyCleBinMap = null;
        }
    }
    
    /***************************************************************************************
* Method : finish
*
* Author : TCS
*
* Description:  Batchable finish method used to send the email to the required stake holder with success and 
*               and error records as attachment 
*
* Parameters: BatchableContext
*
* Return: Void
**************************************************************************************/
    
    global void finish(Database.BatchableContext BC){
       // if(recordsProcessed > 0) {
          /*  AsyncApexJob a = [SELECT id, ApexClassId,
                              JobItemsProcessed, TotalJobItems,
                              NumberOfErrors, CreatedBy.Email
                              FROM AsyncApexJob
                              WHERE id = :BC.getJobId()];
*/
            String body = Label.DeleteClosedCases_3yearsBody;
            body = body.replace('IdToSObjectMap.size()',String.valueOf(recordsProcessed));
            body = body.replace('successMap.size()',String.valueOf(successCount));
            body = body.replace('errorMap.size()',String.valueOf(errCount));
            String subject = Label.DeleteClosedCases_3yearsSubject;
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            // Define email file attachment list
            Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
            try{
                if(errCount > 0){
                    // Creating the CSV file for error
                    /*String finalstr = 'Id, Subject, Error \n';
                    String attName = 'CaseErrors' + system.now().format('YYYYMMDDhhmm') + '.csv';
                    for(Id id  : errorMap.keySet()){
                        if( (Limits.getLimitCpuTime() - Limits.getCpuTime()   < 80000 ) && 
                           (Limits.getLimitHeapSize() - Limits.getHeapSize() < 12000000 ) ){
                               Case csk = (Case)IdToSObjectMap.get(id);
                               string recordString = '"'+id+'","'+csk.Subject+'","'+errorMap.get(id)+'"\n';
                               finalstr = finalstr +recordString;
                               csk = null;
                               recordString = '';
                           }else{
                               body = body + '\n' +  '\n' + '\n' + '\n' + 'Note : Due to error while colleting the records, could not attach the error file';
                               break;
                           }
                    }*/
                    // Create the email attachment    
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName('CaseErrors' + system.now().format('YYYYMMDDhhmm') + '.csv');
                    efa.setBody(Blob.valueOf(finalstr));
                    emailAttList.add(efa);
                    email.setFileAttachments(emailAttList);
                }
            }catch(Exception e){
                system.debug('exception occured while creation of attachnent');
                body = body + '\n' +  '\n' + '\n' + '\n' + '<b>Note</b> : Due to error while colleting the records, could not attach the error file';
            }
            /* Not sending the success records due to performance issue
            try{
                if(! successMap.isEmpty()) {
                    // Creating the CSV file for successful updates
                    String finalstr = 'Id, Subject \n';
                    String attName = 'Case Success' + system.now().format('YYYYMMDDhhmm') + '.csv';
                    for(Id id  : successMap.keySet()){
                        if( (Limits.getLimitCpuTime() - Limits.getCpuTime()   < 80000 ) && 
                           (Limits.getLimitHeapSize() - Limits.getHeapSize() < 12000000 ) ){
                               string suc = successMap.get(id);
                               Case csk = (Case) IdToSObjectMap.get(id);
                               string recordString = '"'+id+'","'+csk.subject+'"\n';
                               finalstr = finalstr + recordString;
                           }else{
                               body = body + '\n' +  '\n' + '\n' + '\n' + 'Note : Due to error while colleting the records, could not attach the either success';
                               break;
                           }
                    }
                    // Create the email attachment    
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(attName);
                    efa.setBody(Blob.valueOf(finalstr));
                    emailAttList.add(efa);
                    email.setFileAttachments(emailAttList);
                }
                
            }catch(Exception e){
                system.debug('exception occured while creation of attachnent');
                body = body + '\n' +  '\n' + '\n' + '\n' + '<b>Note</b> : Due to error while colleting the records, could not attach the error file';
            }*/
            
            String[] toDddr = config.Send_Email_To__c.split(',');
            
            // Sets the paramaters of the email
            email.setSubject( subject );
            email.setToAddresses( toDddr );
            email.setPlainTextBody( body );
            
            // Sends the email
            Messaging.SendEmailResult [] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            system.debug('email sent');
       // }
    } // final method
}