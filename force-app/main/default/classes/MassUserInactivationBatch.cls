/*******************************************************************************************************
* Class: MassUserInactivationBatch
* Purpose: This Batch class containing logic for In Activating the Mass Users
* Requirement: GitLab : #13838 
* Developer         Date           Description
* -------------------------------------------------------------------------------------------------------
* Praneel             03/Mar/2023      Batch class for In Activating the Mass Users
*********************************************************************************************************/
global without sharing class MassUserInactivationBatch implements Database.Batchable<sObject>,Database.Stateful
{
    Integer exceptionCount = 0;
    Map<Id, String> successMap;
    Map<Id, String> errorMap;
    boolean errorTest;
    Integer batchSize;
    Set<ID> inactivedUserIds = new Set<ID>();
    
    /*******************************************************************************************************
    * Constructor for MassUserInactivationBatch
    * 
    *********************************************************************************************************/
    global MassUserInactivationBatch()
    {
        //Constructor Logic
        if(errorTest == null)
            errorTest = false;
        batchSize = 5;
    }
    
    global MassUserInactivationBatch(boolean passederrorTest,Set<Id> inactivedUserIds)
    {
        //Constructor Logic
        this();
        this.errorTest = passederrorTest;
        this.inactivedUserIds = inactivedUserIds;
    }
    
    /*********************************************************************************************************
    * Method Name: start
    * Parameters: Database.BatchableContext
    * Return Type: Database.QueryLocator
    * Requirement: 
    * Description: Start method to fetch the Users which needs to be deactivated.
    *********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        successMap = new Map<Id, String>();
        errorMap = new Map<Id, String>();
              
        String queryString = 'Select ID, IsActive, LastLoginDate,Name,Username,CreatedDate from user where id in :inactivedUserIds';
        
        if(Test.isRunningTest()){
            queryString += ' Limit '+batchSize;
        }
       //query = 'Select ID, IsActive, LastLoginDate,Name,Username,CreatedDate from user where id in  (\'0052H00000DM5G0QAL\')';
        System.debug('query>>>'+queryString);
        
        return Database.getQueryLocator(queryString);
        //Fetching all the users who haven't logged in for Last N (60/30/etc..) Days
        /*return Database.getQueryLocator([Select ID, IsActive, LastLoginDate from User
            WHERE LastLoginDate <: thresholdActiveDate AND CreatedDate <: thresholdCreatedDate
            AND ID = '005g0000008jn8b'
        ]);*/
    }
    
    /*********************************************************************************************************
    * Method Name: execute
    * Parameters: Database.BatchableContext, List<User> usersList
    * Return Type: void
    * Requirement: 
    * Description: Execute method to inactivate the users who are non sso and not logged in based on configuration days
    *********************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<User> usersList) {
        System.debug('users>>>'+usersList.size());
        Map<Id, User> UserMapToBeUpdated = new Map<Id, User>();
        
        for(User u : usersList ){
            u.IsActive = false;
            UserMapToBeUpdated.put(u.Id,u);
        }

        try
        {
            System.debug('users>>>'+usersList);
            Database.SaveResult[] upDateList;
            Integer index = 0;
            System.debug('size.... '+UserMapToBeUpdated.size());
            
            //Deactivating users
            if (UserMapToBeUpdated.size() > 0) {
                // update userMapToBeInactivated;
                if(Test.isRunningTest() && errorTest) { 
                    //system.debug('scope[0].Id '+scope[0].Id);
                    Id errorId = usersList[0].Id;
                    Database.SaveResult sr = (Database.SaveResult)
                        JSON.deserialize('{ "id":"'+errorId+'", "success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
                    upDateList = new List<Database.SaveResult>();
                    upDateList.add(sr);
                }else{
                    upDateList = Database.update(UserMapToBeUpdated.values(), false);
                }
                
                system.debug('size upDateList '+upDateList.size());
                for (Database.SaveResult sr : upDateList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        //inactivedUserIds.add(sr.getId());
                        System.debug('Successfully inactivated id: ' + sr.getId());
                       // User u = (User)usersList[index];
                        
                            User u = UserMapToBeUpdated.get(sr.getId());
                            String recordString = '"'+sr.getId()+'","'+ u.Name + '","' +u.Username+ '","'+u.CreatedDate+ '","'+ u.LastLoginDate +'"\n';
                            successMap.put(sr.getId(), recordString);
                        
                       
                    } else {
                        Database.Error error = sr.getErrors().get(0);
                        String failedDML = error.getMessage();
                        // Operation failed, so get all errors                
                        System.debug('The following error has occurred.');                    
                        System.debug(error.getStatusCode() + ': ' + error.getMessage());
                        System.debug('User fields that affected this error: ' + error.getFields());
                        //User u = (User)usersList[index];
                       
                        User u = UserMapToBeUpdated.get(sr.getId());
                        String recordString = '"'+sr.getId()+'","'+ u.Name + '","' +u.Username+ '","'+u.CreatedDate+ '","'+ u.LastLoginDate +'","'+failedDML+'"\n';
                        errorMap.put(sr.getId(), recordString);
                       
                    }
                    index++;
                }
            }
            
            //Logic to remove the Package License, Permission Sets for Inactive Users
            if(!inactivedUserIds.isEmpty()) {
                delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN :inactivedUserIds AND PermissionSet.IsOwnedByProfile = FALSE];
                delete [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId IN :inactivedUserIds];
                delete [SELECT Id FROM UserPackageLicense WHERE UserId IN :inactivedUserIds];
            }
    
        } catch(Exception e) {
            system.debug('error '+ e.getMessage());
            ++exceptionCount;
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'MassUserInactivationBatch.execute');
        }
        
    }
    
    /*********************************************************************************************************
    * Method Name: finish
    * Parameters: Database.BatchableContext
    * Return Type: void
    * Requirement: 
    * Description: Finish method to have post batch finish logic.
    *********************************************************************************************************/
    global void finish(Database.BatchableContext bc)
    {
        
        list<Mass_User_Deactivation_Settings__mdt> massDeactivationFilter = [Select Exclude_Created_Date__c,
                                  Excluded_First_Names__c, Excluded_Last_Names__c, Excluded_Profiles__c,
                                  Excluded_Usernames__c, User_Inactive_Days__c,PermissionSetsName__c,Send_Email_To__c,batchSize__c from Mass_User_Deactivation_Settings__mdt
                                  where DeveloperName =: System.Label.MassUserInActivionSettingName limit 1];
		String[] toDddr = massDeactivationFilter[0].Send_Email_To__c.split(','); 
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        // Define email file attachment list
        Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
        //Finish logic
        system.debug('successMap '+successMap);
        if(! successMap.isEmpty()) {
            String finalstr = 'Id, Name,UserName,CreatedDate,LastLoginDate \n';
            String attName = 'UserSuccess' + system.now().format('YYYYMMDDhhmm') + '.csv';
            for(Id id  : successMap.keySet()){
                finalstr = finalstr +successMap.get(id);
            }
            // Create the email attachment    
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
        }
        
        if(!errorMap.isEmpty()){
            // Creating the CSV file for error
            String finalstr = 'Id, Name,UserName,CreatedDate,LastLoginDate,Error \n';
            String attName = 'UserErrors' + system.now().format('YYYYMMDDhhmm') + '.csv';
            for(Id id  : errorMap.keySet()){
                finalstr = finalstr +errorMap.get(id);
            }
            // Create the email attachment    
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
            
        }
        
       /* List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Iron Mountain Customer Service' limit 1];
        if ( owea != null && owea.size() > 0) {
            system.debug('if entered for owd');
			email.setOrgWideEmailAddressId(owea[0].Id);
		} */
       
        String body = Label.MassUserDeactivationEmailBody;
        body = body.replace('success+error',String.valueOf(successMap.size() + errorMap.size()));
        body = body.replace('successMap.size()',String.valueOf(successMap.size()));
        body = body.replace('errorMap.size()',String.valueOf(errorMap.size()));
        String subject = Label.MassUserDeactivationEmailSubject;
        // Sets the paramaters of the email
        email.setSubject( subject);
        email.setToAddresses( toDddr );
        email.setPlainTextBody( body );
        email.setFileAttachments(emailAttList);
        
        // Sends the email
        Messaging.SendEmailResult [] r =
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        system.debug('email sent');
    }
    
   
    
}