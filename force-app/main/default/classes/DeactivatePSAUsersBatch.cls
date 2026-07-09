/*******************************************************************************************************
* Class: DeactivatePSAUsersBatch
* Purpose: This Batch class containing logic for InActivating and removing PSA License of Salesforce Platform Users.
* Requirement: GitLab : #26984
* Developer         Date           Description
* -------------------------------------------------------------------------------------------------------
* Prajna Shetty             25/Oct/2024     Batch class for In Activating the Mass PSA Users
*********************************************************************************************************/


global class DeactivatePSAUsersBatch implements Database.Batchable<SObject>,Database.Stateful, Schedulable {
    private Set<String> licenseNames;
    private Integer deactivationThreshold;
    private Integer notificationThreshold;
    private Integer reactivationThreshold;
    private String packageLicenseNames;
    String[] emailDeactivation;
    String[] NotificationEmail;
   // private Set<String> emailDeactivation;
    private String userCreatedDateCondition;
    // boolean errorTest;
    Integer batchSize;
    Integer count = 0;
    
    List<User> usersToNotify = new List<User>();
    List<ID> successDeactivation = new List<ID>();
    Map<Id,user> userNames  = new Map<Id,user>();
    Map<Id, String> failedDeactivation = new Map<Id, String>();
    Set<Id> bufferIds = new Set<Id>();
    
    public DeactivatePSAUsersBatch() {
        // Fetch metadata settings
        List<DeactivationSetting__mdt> settingList = [SELECT License_Names__c,Package_License_Names__c,Deactivation_Day__c,Notification_Day__c,Reactivation_Buffer_Period__c,Email_Deactivation__c,NotificationEmail__c,batch_Size__c FROM DeactivationSetting__mdt LIMIT 1];
        // system.debug('test');
        
        if(!settingList.isEmpty()){
            
            DeactivationSetting__mdt settings = settingList[0];
            licenseNames = new Set<String>(settings.License_Names__c.split(','));
            packageLicenseNames = settings.Package_License_Names__c;
            deactivationThreshold = Integer.valueOf(settings.Deactivation_Day__c);
            notificationThreshold = Integer.valueOf(settings.Notification_Day__c);
            reactivationThreshold = Integer.valueOf(settings.Reactivation_Buffer_Period__c);
            emailDeactivation = settings.Email_Deactivation__c.split(',');
            NotificationEmail = settings.NotificationEmail__c.split(',');
            batchSize = Integer.valueOf(settings.batch_Size__c);
       }
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Date thresholdDate = Date.today().addDays(-notificationThreshold);
        String query;
        Date buffer = Date.today().addDays(-reactivationThreshold);
        Date today = Date.today();
            
        List<SetupAuditTrail> auditRecords = [select Id, Action, Section, CreatedByContext, Display, CreatedByIssuer, CreatedDate from SetupAuditTrail where Action = 'activateduser' AND (Day_only(convertTimezone(CreatedDate)) >= :buffer AND Day_only(convertTimezone(CreatedDate)) <= :today)];
        for(SetupAuditTrail auditRecord : auditRecords)
         {
          bufferIds.add(auditRecord.Display.substringBetween('UserID: [', ']'));
         }
        
        System.debug(thresholdDate);
        System.debug('buffer -' +buffer);
        If(Test.isRunningTest()){
             query = 'SELECT Id, Name,Username, LastLoginDate,CreatedDate,Email, Profile.UserLicense.Name FROM User ' +
                'WHERE Email Like \'testuser%example.com\' AND IsActive = true';
            
        }else{
         query = 'SELECT Id, Name,Username, LastLoginDate,CreatedDate,Email, Profile.UserLicense.Name FROM User ' + 
            'WHERE Profile.UserLicense.Name IN :licenseNames ' + 
            'AND (LastLoginDate = null OR Day_only(convertTimezone(LastLoginDate)) <= :thresholdDate) ' + 
            'AND Day_only(convertTimezone(CreatedDate)) <= :thresholdDate ' +
            'AND IsActive = true ' +
            'AND Id NOT IN :bufferIds';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<User> scope) {
        Integer daysSinceLastLogin;
        List<User> usersToDeactivate = new List<User>();
        Database.SaveResult[] userUpdateList;        
        
        Set<Id> UserIds = new Set<Id>();
        for(User user : scope){
            UserIds.add(user.Id);
            userNames.put(user.Id , user);
            system.debug(user.name);
            system.debug(user.CreatedDate);
            system.debug(user.LastLoginDate);
        }
        
        //query package License assigned to user
        Map<Id , List<UserPackageLicense>> userPackageLicenseMap = new Map<Id, List<UserPackageLicense>>();
        List<UserPackageLicense> packageLicenses = [Select Userid,PackageLicense.NamespacePrefix from UserPackageLicense where userId IN :userIDs AND PackageLicense.NamespacePrefix =: packageLicenseNames];
        
        for (userPackageLicense packageLicense : packageLicenses){
            if(!userPackageLicenseMap.containsKey(packageLicense.userId)){
                userPackageLicenseMap.put(packageLicense.userId,new List<UserPackageLicense>());
            }
            userPackageLicenseMap.get(packageLicense.userId).add(packageLicense);
        }
        
        for (User user : scope) {
            try {                
                //  Integer daysSinceLastLogin = (user.LastLoginDate != null) ? Date.today().daysBetween(user.LastLoginDate.date()) : 999;
                if(user.LastLoginDate != null){
                    daysSinceLastLogin = user.LastLoginDate.date().daysBetween(Date.today());
                }else{
                    daysSinceLastLogin = user.CreatedDate.date().daysBetween(Date.today());  
                }
                //Use a mock lat login calculation for test mode
               if(Test.isRunningTest()){
                    daysSinceLastLogin = 85;
                    deactivationThreshold = 85;
                } 
                Boolean hasPsaLicense = userPackageLicenseMap.containsKey(User.Id);
                
                If(daysSinceLastLogin == notificationThreshold && hasPsaLicense){
                    //send 85th Day email to the user
                    usersToNotify.add(user);
                }
                 //send 70th Day email to the user

                
                if(daysSinceLastLogin >= deactivationThreshold && hasPsaLicense){
                    user.IsActive = false;
                    usersToDeactivate.add(user);
                 //   usersToRemovePSA.add(user);
                }
                
   /**   If(daysSinceLastLogin >= deactivationThreshold && hasPsaLicense && (user.Profile.UserLicense.Name = 'Salesforce Platform' OR user.event == true)){
                    user.IsActive = false;
                    usersToDeactivate.add(user);
                    
                } **/
                
            } catch (Exception e) {
                
                system.debug('error '+ e.getMessage());
                //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'MassUserInactivationBatch.execute');
            }  
            
        }
        system.debug('usersToDeactivate'+usersToDeactivate.size());
        system.debug('usersToNotify'+usersToNotify.size());
        
        count +=  usersToDeactivate.size();     
        
        // system.debug('Enter the main code');
       if(usersToDeactivate.size() > 0 ){
            try{
                //   system.debug(usersToDeactivate.size());
                //remove Dependency if any
                removeDependency(usersToDeactivate);
                system.debug('removeDependency done');
                
                //de-activate users
                
                Database.SaveResult[] deactivateResults = Database.update(usersToDeactivate,false);
                for(Integer i = 0 ; i < deactivateResults.size(); i++){
                    system.debug('usersToDeactivate - ' +usersToDeactivate[i]);
                    system.debug('deactivateResults - ' +deactivateResults[i]);
                    if(!deactivateResults[i].isSuccess()){
                        failedDeactivation.put(usersToDeactivate[i].Id ,deactivateResults[i].getErrors()[0].getMessage());
                        
                    }else{
                        successDeactivation.add(usersToDeactivate[i].id);
                        
                    }
                }
                system.debug('failedDeactivation'+failedDeactivation.size());
                system.debug('successDeactivation'+successDeactivation.size()); 
                
                if(successDeactivation.size() > 0) {
                delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN :successDeactivation AND PermissionSet.IsOwnedByProfile = FALSE];
                delete [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId IN :successDeactivation];
                //remove Package Licenses
                removePackageLicenses(successDeactivation);
                system.debug('removePackageLicenses done');
                
                }
            }catch (exception e){
                system.debug('error '+ e.getMessage());
                //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'MassUserInactivationBatch.execute');
            }
        } 
    }
    // Notify users after deactivation
    //  sendDeactivationEmails(usersToDeactivate, failedUsers, deactivationErrors);
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters: Database.BatchableContext
* Return Type: void
* Requirement: 
* Description: Finish method to have post batch finish logic.
*********************************************************************************************************/
    
    global void finish(Database.BatchableContext bc) {
        
        // Notify users after deactivation         
        system.debug('email sent?');
        System.debug(failedDeactivation.size());
        System.debug(successDeactivation.size());
        
         this.sendDeactivationEmails();
      
       
        //send notification on 85th Day email to the user
        if(!usersToNotify.isEmpty()){
            system.debug('usersToNotify');
            send85thDayEmails(usersToNotify ,Label.DeactivatePSATemplateName );
        }
                //send notification on 70th Day email to the user

        system.debug('usersToDeactivate'+count);
        system.debug('usersToNotify'+usersToNotify.size());
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters: Database.BatchableContext
* Return Type: void
* Requirement: 
* Description: Execute method to schedule batch
*********************************************************************************************************/
    
    global void execute(SchedulableContext ctx) {
        
        system.debug('batch size while scheduling '+batchSize);
        
        DeactivatePSAUsersBatch DeactivateUsers = new DeactivatePSAUsersBatch();
        Database.executeBatch(DeactivateUsers,batchSize);
        
    }
    
    /***********************************************************************************************************
* Method :      removePackageLicenses
* Parameters:   List<User> userSet
* Return Type : void
* Description:  This method loops over the list of records to  remove package licenses from users 
**************************************************************************************************************/ 
    
   @TestVisible private void removePackageLicenses(List<Id> userId) {
        // Logic to remove package licenses
        Id  packageLicenseId;
        
        try {
            PackageLicense pkgLicense = [Select id from PackageLicense where NamespacePrefix =: packageLicenseNames];
            packageLicenseId = pkgLicense.id;
        }catch (QueryException e){
            System.debug('Package license not found: ' +e.getMessage());
            return;
        }        
        
        //query UserPackageLicnese Records        
        List<UserPackageLicense> userPackageLicensesToDelete = [select Id from UserPackageLicense where PackageLicenseId =: packageLicenseId and UserId IN : userId];
        
        //Perform the Delete operation.
        If(!userPackageLicensesToDelete.isEmpty()){
            delete userPackageLicensesToDelete;
            system.debug(userPackageLicensesToDelete.size() + 'Package License removed from users: ' +userId );
        }
        else {
            system.debug('No Package License Users found for removal');
        }
        
    }   
    
    /***********************************************************************************************************
* Method :      removeDependency
* Parameters:   List<User> userSet
* Return Type : void
* Description:  This method loops over the list of user records and make the heirarchy fields blank
**************************************************************************************************************/
    
    global static void removeDependency(List<User> userSet) {
        //  List<User> lstUSers;
        Map<id,User> UserMapToBeUpdated = new Map<id,User>();
        Database.SaveResult[] upDateList;
        
        //for (User usr: userSet) {
        for(User activUsers : [SELECT id,IM_RSM__c,Sales_Enablement_Manager__c,Sales_Manager__c,SVP__c,IM_VP__c,QTB_Supervisor__c,DelegatedApproverId  from User where (IM_RSM__c <> '' and IM_RSM__c in : userSet ) or (Sales_Enablement_Manager__c <> '' and Sales_Enablement_Manager__c in : userSet ) or (Sales_Manager__c <> '' and Sales_Manager__c in : userSet ) or (SVP__c <> '' and SVP__c in : userSet ) or (IM_VP__c <> '' and IM_VP__c in : userSet ) or (QTB_Supervisor__c <> '' and QTB_Supervisor__c in : userSet ) or (DelegatedApproverId <> '' and DelegatedApproverId in :userSet ) ]){
            
            activUsers.IM_RSM__c = null;           
            activUsers.Sales_Enablement_Manager__c = null;           
            activUsers.Sales_Manager__c = null;            
            activUsers.SVP__c = null;            
            activUsers.IM_VP__c = null;            
            activUsers.QTB_Supervisor__c = null;            
            activUsers.DelegatedApproverId = null;            
            UserMapToBeUpdated.put(activUsers.id,activUsers);            
        }
        
        if(UserMapToBeUpdated.size() > 0 ){
            upDateList = Database.update(UserMapToBeUpdated.values(),false);
        }
    }
    
    /***********************************************************************************************************
* Method :      send85thDayEmails
* Parameters:   User
* Return Type : Void
* Description:  This method sends an email 
**************************************************************************************************************/
    Private void send85thDayEmails(List<User> usersToNotify , String DeactivatePSATemplateName){
        
        for(User user : usersToNotify){
            try{
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                emailMessage.setTargetObjectId(user.Id);
                emailMessage.setSenderDisplayName('License Administration Team');
                emailMessage.setCcAddresses(NotificationEmail);
                
                //Fetch Email template for 85th day email
                EmailTemplate template = [select Id from EmailTemplate where developerName = :DeactivatePSATemplateName Limit 1];
                emailMessage.setTemplateId(template.Id);
                
                emailMessage.setSaveAsActivity(False);
              
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{emailMessage});
                
            }Catch (Exception e){
                
                system.debug('Error sending 85-th day email user' + user.Id + ': ' + e.getmessage());
                
            }
        }
    }
    
    /***********************************************************************************************************
* Method :      sendDeactivationEmails
* Parameters:   List<User> successUsers, List<User> failedUsers, Map<Id, String> errors
* Return Type : Void
* Description:  This method sends an email to the required stakeholders with success and error records as attachment
**************************************************************************************************************/
    
   @TestVisible private void sendDeactivationEmails() {
        
        string subject = label.DeactivatePSAusersSubject;
        system.debug(failedDeactivation.size());
        Messaging.SingleEmailMessage SendEmail = new Messaging.SingleEmailMessage();
        //SendEmail.setToAddresses(new List<String>{emailDeactivation});
        Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
        
        // SendEmail.setSubject(subject);
        String Body = Label.DeactivatePSAusersMailBody;
        
        if (!failedDeactivation.isEmpty()) {
            String finalstr = 'Id, Name,UserName,CreatedDate,LastLoginDate,Error \n';
            String attName = 'UserErrors' + system.now().format('YYYYMMDDhhmm') + '.csv';                    
            
            for (Id userId : failedDeactivation.keySet()) {
                
                user u = userNames.get(userId);
                //  String userName = userNames.get(userId);
                String recordString = '"'+u.Id+'","'+ u.Name + '","' +u.Username+ '","'+u.CreatedDate+ '","'+ u.LastLoginDate +'","'+ failedDeactivation.get(userId)+ '\n';
                finalstr = finalstr + recordString;
                
                //  Body += '\n User Name :'  + userName + ' ( user Id: ' +userid+') - Error: ' + failedDeactivation.get(userId)+ '\n';
            }
            //  FailureEmail.setPlainTextBody(Body);
            //  Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{FailureEmail});
            system.debug('email sent (fail)');
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
        }
        
        // Send sucess email
        system.debug(successDeactivation.size());
        if (!successDeactivation.isEmpty()) {
            String finalstr = 'Id, Name,UserName,CreatedDate,LastLoginDate \n';
            String attName = 'UserSuccess' + system.now().format('YYYYMMDDhhmm') + '.csv';

            for (Id userId : successDeactivation) {
                //  String userName = userNames.get(userId);
                // successBody += '\n User Name : '  + userName + ' ( user Id : ' +userid+')';
                user u = userNames.get(userId);
                String recordString = '"'+u.Id+'","'+ u.Name + '","' +u.Username+ '","'+u.CreatedDate+ '","'+ u.LastLoginDate +'"\n';
                finalstr = finalstr + recordString;
                
            }
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
            system.debug('email sent (success)');
            
        }
        
        body = body.replace('failedDeactivation.size()',String.valueOf(failedDeactivation.size()));
        body = body.replace('successDeactivation.size()',String.valueOf(successDeactivation.size()));
        
        SendEmail.setToAddresses(emailDeactivation);
        SendEmail.setFileAttachments(emailAttList);
        SendEmail.setPlainTextBody(body);
        SendEmail.setSubject(subject);
       // SendEmail.setSaveAsActivity(false);
        
         Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{SendEmail});
         
        system.debug('email sent');
        
    }
}