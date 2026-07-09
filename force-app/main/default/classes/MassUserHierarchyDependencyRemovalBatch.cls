/*******************************************************************************************************
* Class: MassUserHierarchyDependencyRemovalBatch
* Purpose: This Batch class containing logic for Removing the Hierarchy field dependency of Users
* Requirement: GitLab : #13838 
* Developer         Date             Description
* -------------------------------------------------------------------------------------------------------
* Praneel           03/Mar/2023      Batch class for In Activating the Mass Users
*********************************************************************************************************/
global without sharing class MassUserHierarchyDependencyRemovalBatch implements Database.Batchable<sObject>, Database.Stateful,Schedulable 
{
    Integer exceptionCount = 0;
    
    boolean errorTest;
    Integer batchSize;
    Set<ID> inactivedUserIds = new Set<ID>();
    
    /*******************************************************************************************************
    * Constructor for MassUserInactivationBatch
    * 
    *********************************************************************************************************/
    global MassUserHierarchyDependencyRemovalBatch()
    {
        //Constructor Logic
        if(errorTest == null)
            errorTest = false;
        batchSize = 5;
    }
    
    global MassUserHierarchyDependencyRemovalBatch(boolean passederrorTest)
    {
        //Constructor Logic
        this();
        this.errorTest = passederrorTest;
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
        
        
        //Logic to fetch the Filter Conditions from Custom Metadata Settings
        list<Mass_User_Deactivation_Settings__mdt> massDeactivationFilter = [Select Exclude_Created_Date__c,
                                  Excluded_First_Names__c, Excluded_Last_Names__c, Excluded_Profiles__c,
                                  Excluded_Usernames__c, User_Inactive_Days__c,PermissionSetsName__c,Send_Email_To__c,batchSize__c,Excluded_User_Licenses__c from Mass_User_Deactivation_Settings__mdt
                                  where DeveloperName =: System.Label.MassUserInActivionSettingName limit 1];  
        
        if (massDeactivationFilter[0].batchSize__c != NULL) {
            batchSize = Integer.valueOf(massDeactivationFilter[0].batchSize__c);
        }
        //system.debug('batchSize '+batchSize);
        
        //Inactive Days filter variable
        String userInactiveDaysCondition = ' AND';
        if (massDeactivationFilter[0].User_Inactive_Days__c != NULL) {
            Date thresholdActiveDate = System.Today() - Integer.valueOf(massDeactivationFilter[0].User_Inactive_Days__c);
            userInactiveDaysCondition = userInactiveDaysCondition + ' (LastLoginDate <: thresholdActiveDate  or LastLoginDate = null) AND';
            System.debug('thresholdActiveDate>>>'+thresholdActiveDate);
        }
        
        
        //Created days filter variable
        String userCreatedDateCondition = '';
        if (massDeactivationFilter[0].Exclude_Created_Date__c != NULL) {
            Date thresholdCreatedDate =  System.Today() - Integer.valueOf(massDeactivationFilter[0].Exclude_Created_Date__c);
            userCreatedDateCondition = userCreatedDateCondition + ' CreatedDate <: thresholdCreatedDate AND';
            System.debug('thresholdCreatedDate>>>'+thresholdCreatedDate);
        }
        
        /*
        //Variable to store the First Names which needs to be excluded from deactivation
        String excludeFirstNameCondition = '';
        if (!String.isBlank(massDeactivationFilter[0].Excluded_First_Names__c)) {
            String excludedFirstNamesString = String.valueOf(massDeactivationFilter[0].Excluded_First_Names__c);
            list<String> excludeFirstNames = excludedFirstNamesString.split(',');
            excludeFirstNameCondition = excludeFirstNameCondition + ' FirstName NOT IN: excludeFirstNames AND';
            System.debug('excludeFirstNames>>>'+excludeFirstNames);
        }

        //Variable to store the Last Names which needs to be excluded from deactivation 
        String excludeLastNameCondition = '';
        if (!String.isBlank(massDeactivationFilter[0].Excluded_Last_Names__c)) {
            String excludeLasttNamesString = String.valueOf(massDeactivationFilter[0].Excluded_Last_Names__c);
            list<String> excludeLastNames = excludeLasttNamesString.split(',');
            excludeFirstNameCondition = excludeLastNameCondition + ' LastName NOT IN: excludeLastNames AND';
            System.debug('excludeLastNames>>>'+excludeLastNames);
        }
        */

        //Variable to store the Profiles which needs to be excluded from deactivation
        String excludedProfilesCondition = '';
        if (!String.isBlank(massDeactivationFilter[0].Excluded_Profiles__c)) {
            String excludedProfilesString = String.valueOf(massDeactivationFilter[0].Excluded_Profiles__c);
            list<String> excludedProfiles = excludedProfilesString.split(',');
            excludedProfilesCondition = excludedProfilesCondition + ' Profile.Name NOT IN: excludedProfiles AND';
            System.debug('excludedProfiles>>>'+excludedProfiles);
        }
		
        //Variable to store the UserNames which needs to be excluded from deactivation
        String excludedUsernamesCondition = '';
        if (!String.isBlank(massDeactivationFilter[0].Excluded_Usernames__c)) {
            String excludedUsernamesString = String.valueOf(massDeactivationFilter[0].Excluded_Usernames__c);
            list<String> excludedUsernames = excludedUsernamesString.split(',');
            excludedUsernamesCondition = excludedUsernamesCondition + ' Username NOT IN: excludedUsernames AND';
            System.debug('excludedUsernames>>>'+excludedUsernames);     
        }
        
        //Variable to store the PermissionSet(Non SSO Users) which needs to be used in deactivation
        String permissionSetsCondition = '';
        if (!String.isBlank(massDeactivationFilter[0].PermissionSetsName__c)) {
            String permissionSetString = String.valueOf(massDeactivationFilter[0].PermissionSetsName__c);
            list<String> permissionSets = permissionSetString.split(',');
            permissionSetsCondition =permissionSetsCondition + ' id not  in (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN: permissionSets) AND';
            System.debug('permissionSetsCondition>>>'+permissionSets);     
        }
        
        //Variable to store the User Licenses which needs to be excluded from deactivation
        String userLicensesCondition = '';
        if (!String.isBlank(massDeactivationFilter[0].Excluded_User_Licenses__c)) {
            String userLicenseString = String.valueOf(massDeactivationFilter[0].Excluded_User_Licenses__c);
            list<String> userLicenses = userLicenseString.split(',');
            userLicensesCondition =userLicensesCondition + ' Profile.UserLicense.name not IN: userLicenses AND';
            System.debug('userLicensesCondition>>>'+userLicenses);     
        }
        
        
        //Query string to fetch the eligible users list to inactive
        String queryString;
        queryString = 'Select ID, IsActive, LastLoginDate,Name,Username,CreatedDate '  
              +'FROM User Where IsActive = true '
              + userInactiveDaysCondition 
              + userCreatedDateCondition
            /*  + excludeFirstNameCondition
              + excludeLastNameCondition */
            
              + excludedProfilesCondition
              + excludedUsernamesCondition
			
              + permissionSetsCondition
              + userLicensesCondition;

        String query = queryString.removeEnd('AND');
        
        if(Test.isRunningTest()){
            query += ' Limit 5';
        }
      // query = 'Select ID, IsActive, LastLoginDate,Name,Username,CreatedDate from user where id in  (\'00580000003SJJoAAO\',\'0052H00000CMbu3\',\'005800000049tcjAAA\',\'0053400000Bql4hAAB\',\'005800000036gwHAAQ\')';
        System.debug('query>>>'+query);
        
        return Database.getQueryLocator(query);
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
        
        try
        {
            Database.SaveResult[] upDateList;
            Integer index = 0;
            
            //variable to store the User List which needs to be Inactivated.
            //list<User> userListToBeInactivated = new list<User>();
          //  Map<id,User> userMapToBeInactivated = new Map<id,User>();
            
            //list<User> userListToBeUpdated = new list<User>();
            Map<id,User> UserMapToBeUpdated = new Map<id,User>();
            
            //variable to store the Inactivated User Id's to remove the package, permission set assignments
            
            List<User> lstUSers;
            
            if(Test.isRunningTest()){
                lstUSers = [SELECT id,IM_RSM__c,Sales_Enablement_Manager__c,Sales_Manager__c,SVP__c,IM_VP__c,QTB_Supervisor__c from User where (IM_RSM__c <> ''  or Sales_Enablement_Manager__c <> '' or Sales_Manager__c <> '' or SVP__c <> ''  or IM_VP__c <> '' or QTB_Supervisor__c <> '' ) ];
            }else{
            	lstUSers = [SELECT id,IM_RSM__c,Sales_Enablement_Manager__c,Sales_Manager__c,SVP__c,IM_VP__c,QTB_Supervisor__c from User where (IM_RSM__c <> '' and IM_RSM__c in : usersList ) or (Sales_Enablement_Manager__c <> '' and Sales_Enablement_Manager__c in : usersList ) or (Sales_Manager__c <> '' and Sales_Manager__c in : usersList ) or (SVP__c <> '' and SVP__c in : usersList ) or (IM_VP__c <> '' and IM_VP__c in : usersList ) or (QTB_Supervisor__c <> '' and QTB_Supervisor__c in : usersList ) ];// and id in ('00580000003u9sG','0052H00000DYUcZ')
            }
            system.debug('lstUSers '+lstUSers.size());
            system.debug('usersList.size() '+usersList.size());
           //List<Id> uc = new List<Id>();
                
                for (User usr: usersList) {
                  //system.debug('usr.Id in loop '+usr.Id);
                    for(User activUsers : lstUSers){
                         //system.debug('rsm '+activUsers.IM_RSM__c);
                        if(activUsers.IM_RSM__c == usr.Id){
                          //  system.debug('rsm '+activUsers.IM_RSM__c);
                            activUsers.IM_RSM__c = null;
                            UserMapToBeUpdated.put(activUsers.id,activUsers);
                            //uc.add(activUsers.id);
                            //userListToBeUpdated.add(activUsers);
                            // add activUsers.id into list
                            // and list into map
                        }
                        if(activUsers.Sales_Enablement_Manager__c == usr.Id){
                            //system.debug('enablement manager '+activUsers.Sales_Enablement_Manager__c);
                            activUsers.Sales_Enablement_Manager__c = null;
                            //userListToBeUpdated.add(activUsers);
                            UserMapToBeUpdated.put(activUsers.id,activUsers);
                            //uc.add(activUsers.id);
                        }
                        // system.debug('sales manager '+activUsers.Sales_Manager__c);
                        if(activUsers.Sales_Manager__c == usr.Id){
                            //system.debug('sales manager '+activUsers.Sales_Manager__c);
                            activUsers.Sales_Manager__c = null;
                            //userListToBeUpdated.add(activUsers);
                            UserMapToBeUpdated.put(activUsers.id,activUsers);
                            //uc.add(activUsers.id);
                        }
                       // system.debug('svp : '+activUsers.SVP__c);
                        if(activUsers.SVP__c == usr.Id){
                            //system.debug('SVP  '+activUsers.SVP__c);
                            activUsers.SVP__c = null;
                            //userListToBeUpdated.add(activUsers);
                            UserMapToBeUpdated.put(activUsers.id,activUsers);
                            //uc.add(activUsers.id);
                        }
                        //system.debug('vp : '+activUsers.IM_VP__c + ' user id '+usr.Id);
                        if(activUsers.IM_VP__c == usr.Id){
                            //system.debug('VP  '+activUsers.IM_VP__c);
                            activUsers.IM_VP__c = null;
                            //userListToBeUpdated.add(activUsers);
                            UserMapToBeUpdated.put(activUsers.id,activUsers);
                            //uc.add(activUsers.id);
                        }
                      /*  if(activUsers.ManagerId == usr.Id){
                            //system.debug('ManagerId  '+activUsers.ManagerId);
                            activUsers.ManagerId = null;
                            //userListToBeUpdated.add(activUsers);
                            UserMapToBeUpdated.put(activUsers.id,activUsers);
                            uc.add(activUsers.id);
                        }
						*/
                        //system.debug('activUsers.QTB_Supervisor__c '+activUsers.QTB_Supervisor__c);
                        if(activUsers.QTB_Supervisor__c == usr.Id){
                            //system.debug('QTB_Supervisor__c  '+activUsers.QTB_Supervisor__c);
                            activUsers.QTB_Supervisor__c = null;
                            //userListToBeUpdated.add(activUsers);
                            UserMapToBeUpdated.put(activUsers.id,activUsers);
                            //uc.add(activUsers.id);
                        }
                        
                    }
                    //system.debug('size in for loop '+UserMapToBeUpdated.size());
                    usr.IsActive = false;
                    //userListToBeInactivated.add(usr);
                    //UserMapToBeUpdated.put(usr.id,usr);
                    inactivedUserIds.add(usr.id);
					
                }
            //system.debug('list size '+uc.size());
            System.debug('UserMapToBeUpdated.values()>>>'+UserMapToBeUpdated.values());
            /*for(Id u: UserMapToBeUpdated.keyset()){
                system.debug('id.... '+u);
            }*/
            
            if(UserMapToBeUpdated.size() > 0 ){
              upDateList = Database.update(UserMapToBeUpdated.values(),false);
            }
            
            //System.debug('size.... '+upDateList.size());
               
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
    * Description: Finish method to have call  MassUserInactivationBatch 
    *********************************************************************************************************/
    global void finish(Database.BatchableContext bc){
        for(Id i :inactivedUserIds){
            system.debug('ids in first batch '+i);
        }
        system.debug('batch size' + batchSize);
        
        MassUserInactivationBatch massInactivateUser = new MassUserInactivationBatch(errorTest,inactivedUserIds);
        database.executeBatch(massInactivateUser,batchSize);
	
    }
    
     /*********************************************************************************************************
    * Method Name: execute
    * Parameters: Database.SchedulableContext
    * Return Type: void
    * Requirement: 
    * Description: execute method to schedule the batch class
    *********************************************************************************************************/
    global void execute(SchedulableContext sc) {
        
        system.debug('batch size while scheduling '+batchSize);
        MassUserHierarchyDependencyRemovalBatch massInactivateUser = new MassUserHierarchyDependencyRemovalBatch(errorTest);
        database.executeBatch(massInactivateUser,batchSize);
    }
    
}