/*COMBINATION OF ALL TRIGGERS ON TASK OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 11/29/2012
*/

/*
    **Modified By   : Aditya Verma
    **Modified Date : 18-May-2021
    **Case No.     : CHG0035840, 16499251 
    **Description  : Need to add 'Case_DM' record type to a trigger for updating the 'open tasks?' field in the caserecord.  
*/

/*
    **Modified By   : Vinutha Iyengar
    **Modified Date : 28-Mar-2016
    **Case No.     : 03362496 
    **Description  : Switch off Automatic Population of Telephone Number of related Account, Contact, Lead in Task Comments 
*/

trigger TaskObjectTrigger on Task (after insert, after update, before delete, 
before insert, before update) {
    /****Variable declaration for 'CheckTasksCreatedOnClosedCase' Trigger****/
    public String CheckTasksCreatedOnClosedCase = null;
    public Boolean runCheckTasksCreatedOnClosedCase = false;
    Set<Id> recordTypeIds = new Set<Id>();
    Map<ID,Task> mapTaskCreated = new map<Id,Task>();
    
    
    /****Variable declaration for 'GenerateCaseOnTaskCreation' Trigger****/
    public String GenerateCaseOnTaskCreation = null;
    public Boolean runGenerateCaseOnTaskCreation = false;
    List<Task> lstTask = new List<Task>();
     Map<String, String> ContIdMap = new Map<String, String>();
     List<String> strContLst = new List<String>();
     List<Contact> ContList = new List<Contact>();
     list<Division> div = new List<Division>();
     map<string, id> divmap = new Map<string, id>();
    
    
    
    /****Variable declaration for 'UpdateCaseOpenTask' Trigger****/
    public String UpdateCaseOpenTask = null;
    public Boolean runUpdateCaseOpenTask = false;
    Set<Id> recordTypeIds2 = new Set<Id>();
    Map<ID, Task> mapTaskWithCaseID = new map<ID,Task>();    
    
    /****Variable declaration for 'checkOnDelete' Trigger****/
    public String checkOnDelete = null;
    public Boolean runcheckOnDelete = false;
    Schema.DescribeSObjectResult d = Schema.SObjectType.Task;
    Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();
    User user = new User();
    System.debug('---12---user.Profile.Name:'+user.Profile.Name);
    String recordTypeName;
    System.debug('---14------Trigger.old:'+Trigger.old);
    
    /****Variable declaration for 'updateTaskNotification' Trigger****/
    //public String updateTaskNotification = null;
    //public Boolean runupdateTaskNotification = false;
    
    /****Variable declaration for 'CreateTaskOnCase' Trigger****/
    public String CreateTaskOnCase = null;
    public Boolean runCreateTaskOnCase = false;
    public final String subHeader = '^^$$##';
    System.debug('----3----subHeader:'+subHeader);
    Set<String> subjectStrings = new Set<String>();
    String recordTypeIdCase = '';
    
    /****Variable declaration for 'TaskDueDateValidation' Trigger****/
    public String TaskDueDateValidation = null;
    public Boolean runTaskDueDateValidation = false;
    Set<Id> ncspRecordTypeIds = new Set<Id>();
    Set<Id> cacRecordTypeIds = new Set<Id>();
    Map<ID,Task> mapNCSPTaskCreated = new map<Id,Task>();
    Map<ID,Task> mapCACTaskCreated = new map<Id,Task>();
    set<string> setNCSPTaskUniqueNumber = GetUniqueTask();
    System.debug('--19----setNCSPTaskUniqueNumber:'+setNCSPTaskUniqueNumber);
    set<string> setCACTaskUniqueNumber = GetCACRetentionUniqueTask();
    System.debug('---21---setCACTaskUniqueNumber:'+setCACTaskUniqueNumber);
    Set <ID> setNCSPUserRole =  new Set<Id>();
    Set <ID> setCACUserRole =  new Set<Id>();
    // Get recod id
    fillRecordTypeIds3(); 
    String whatId2;    
    Task oldTask2;
    ID userRoleID = userinfo.getUserRoleId();
   List<UserRole> lstUserRole = new List<UserRole>();
   // System.debug('---28-----lstUserRole:'+lstUserRole);
    
    /***Retrieving Custom Settings***/
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Task'){
            if(cs.Trigger__c == 'CheckTasksCreatedOnClosedCase') {
                CheckTasksCreatedOnClosedCase = cs.Value__c;    
            }
            
            if(cs.Trigger__c == 'GenerateCaseOnTaskCreation') {
                GenerateCaseOnTaskCreation = cs.Value__c;   
                system.debug('GenerateCaseOnTaskCreation-----'+GenerateCaseOnTaskCreation); 
            } 
            
            if(cs.Trigger__c == 'UpdateCaseOpenTask') {
                UpdateCaseOpenTask = cs.Value__c;    
            }  
            if(cs.Trigger__c == 'checkOnDelete') {
                checkOnDelete = cs.Value__c;    
            } 
            /*if(cs.Trigger__c == 'updateTaskNotification') {
                updateTaskNotification = cs.Value__c;    
            }*/
            if(cs.Trigger__c == 'CreateTaskOnCase') {
                CreateTaskOnCase = cs.Value__c;    
            }
            if(cs.Trigger__c == 'TaskDueDateValidation') {
                TaskDueDateValidation = cs.Value__c;    
            }            
        }
    }
    
    /*****************************************START TRIGGER*************************************************/

    /*****************************************BEFORE INSERT AND UPDATE*************************************/
    
    if(Trigger.isBefore){
        System.debug('----34-----Trigger.isBefore:'+Trigger.isBefore +'\t Trigger.isInsert:'+Trigger.isInsert);
        if(Trigger.isInsert){
            //runupdateTaskNotification = true;
            runCreateTaskOnCase = true;
            System.debug('+++97+++++making  runCreateTaskOnCase to TRUE in before insert call+++++++:'+runCreateTaskOnCase);
            /****CheckTasksCreatedOnClosedCase****/
            /*---start---*/
             System.debug('---------firing CheckTasksCreatedOnClosedCase trigger----:'+CheckTasksCreatedOnClosedCase);
             if(CheckTasksCreatedOnClosedCase == 'True'){
                // Get recod id
                fillRecordTypeIds(); 
                String whatId;
                for(Task newTask : trigger.new){
                     whatId = newTask.WhatId;
                    if(newTask.WhatId != null && whatId.startsWith('500')){
                        mapTaskCreated.put(newTask.WhatId,newTask);
                    }
                }
                if(mapTaskCreated.size() > 0){
                    List<Case> lstCase = [select id , isclosed,Status from Case where id in:mapTaskCreated.keySet() and RecordTypeId in :recordTypeIds];
                    if(lstCase.size() > 0){
                        for(Case c : lstCase){
                            if(c.isclosed == true && mapTaskCreated.containsKey(c.ID)){
                                Task createdTask = mapTaskCreated.get(c.ID);
                                createdTask.addError('Tasks cannot be created on a closed case');
                            }
                        }
                    }
                }            
             }
            /****CheckTasksCreatedOnClosedCase****/
            /*---end---*/
        }
        
        if(Trigger.isUpdate){
            //runupdateTaskNotification = true;
            runCreateTaskOnCase = true; 
            System.debug('+++129+++++making  runCreateTaskOnCase to TRUE in before update call+++++++:'+runCreateTaskOnCase);
            /****TaskDueDateValidation****/
            /*---start---*/
             System.debug('----------TaskDueDateValidation:'+TaskDueDateValidation);
             if(TaskDueDateValidation == 'True'){
                lstUserRole = [Select  Name, Id From UserRole where name = 'NCSP Supervisor' or name = 'NCSP Coordinator' or name = 'Manager, NCSP' or name = 'VP, Customer Implementations' or name='CAC/Retention Supervisor' or name='CAC/Retention Coordinator' ];
                for(UserRole uRole :lstUserRole){
                    System.debug('----30----uRole.name:'+uRole.name);
                    if( uRole.name == 'NCSP Supervisor' || uRole.name == 'NCSP Coordinator' || uRole.name == 'Manager, NCSP' || uRole.name == 'VP, Customer Implementations'){
                        setNCSPUserRole.add(uRole.ID);
                        System.debug('---33-----setNCSPUserRole:'+setNCSPUserRole);
                    }
                    System.debug('----35----uRole.name:'+uRole.name);
                    if( uRole.name == 'CAC/Retention Supervisor' || uRole.name == 'CAC/Retention Coordinator' ||  uRole.name == 'VP, Customer Implementations'){
                        setCACUserRole.add(uRole.ID);
                        System.debug('---38-----setCACUserRole:'+setCACUserRole);
                    }
                }
                for(Task newTask : trigger.new){
                    whatId2 = newTask.WhatId;
                    System.debug('---42-----whatId2:'+whatId2);        
                    oldTask2 =  trigger.oldMap.get(newTask.id);
                    System.debug('----45----oldTask2:'+oldTask2);
                    //Removed this condition from below && setNCSPTaskUniqueNumber.contains(newTask.Unique_Task__c)
                    if(newTask.WhatId != null && whatId2.startsWith('500') && newTask.Due_Date__c != oldTask2.Due_Date__c ){
                        System.debug('----48---userRoleID:'+userRoleID +'\t setNCSPUserRole.contains(userRoleID):'+setNCSPUserRole.contains(userRoleID));
                        if(userRoleID == null || !setNCSPUserRole.contains(userRoleID)){
                            mapNCSPTaskCreated.put(newTask.WhatId,newTask);
                            System.debug('---51----mapNCSPTaskCreated:'+mapNCSPTaskCreated);
                        }           
                    }
                    //Removed this condition from below && setCACTaskUniqueNumber.contains(newTask.Unique_Task__c)
                    else if(newTask.WhatId != null && whatId2.startsWith('500') && newTask.Due_Date__c != oldTask2.Due_Date__c ){
                        if(userRoleID == null || !setCACUserRole.contains(userRoleID)){
                            mapCACTaskCreated.put(newTask.WhatId,newTask);
                            System.debug('---57----mapCACTaskCreated:'+mapCACTaskCreated);
                        }           
                    }
                }
                // get all case with given record type.
                if(mapNCSPTaskCreated.keySet().size() > 0 || mapCACTaskCreated.keySet().size() > 0){
                    List<Case> lstCase = [select id from Case where (id in:mapNCSPTaskCreated.keySet() or id in:mapCACTaskCreated.keySet()) and (RecordTypeId in :ncspRecordTypeIds or RecordTypeId in :cacRecordTypeIds)];
                    System.debug('---64----lstCase:'+lstCase);
                    if(lstCase.size() > 0){
                        for(Case c : lstCase){
                            System.debug('---67-----mapNCSPTaskCreated.containsKey(c.ID):'+mapNCSPTaskCreated.containsKey(c.ID));
                            if(mapNCSPTaskCreated.containsKey(c.ID)){// add error messages
                                Task createdTask = mapNCSPTaskCreated.get(c.ID);
                                createdTask.addError('For this pre-defined task, you are not allowed to change the due date time.');
                                System.debug('-----71-----createdTask:'+createdTask);
                            }
                            System.debug('---73-----mapCACTaskCreated.containsKey(c.ID):'+mapCACTaskCreated.containsKey(c.ID));
                            if(mapCACTaskCreated.containsKey(c.ID)){// add error messages
                                Task createdTask = mapCACTaskCreated.get(c.ID);
                                createdTask.addError('For this pre-defined task, you are not allowed to change the due date time.');
                                System.debug('---77-------createdTask:'+createdTask);
                            }
                        }
                    }
                }
             }
            /****TaskDueDateValidation****/
            /*---end---*/       
        }
        if(Trigger.isDelete){   
            /****checkOnDelete****/
            /*---start---*/
             System.debug('---------checkOnDelete:'+checkOnDelete);
             if(checkOnDelete == 'True'){
             system.debug('Logged in UserName:'+UserInfo.getName());
             system.debug('Logged in User:'+Userinfo.getUserId());
                 try{
                 user = [select id,Name, Profile.Name from User where id = :Userinfo.getUserId()];
                 }catch(exception e){
                     system.debug('Exception occured for proile is blank:'+e.getMessage());
                 }
               System.debug('Logged in UserName:'+user.Name);
               System.debug('Logged in UserName:'+user.Profile.Name);
                for(Task t : Trigger.old) {
                    System.debug('--------t.RecordTypeId:'+t.RecordTypeId);    
                    if(t.RecordTypeId != null){
                      recordTypeName = rtMapById.get(t.RecordTypeId).getName();
                      System.debug('------recordTypeName:'+recordTypeName);      
                    }else{ 
                      continue;
                      System.debug('----inside else continue-------');
                    }
                    System.debug('--------recordTypeName:'+recordTypeName +'\t user.Profile.Name:'+user.Profile.Name);
                    if((user.Profile.Name != 'System Administrator' && user.Profile.Name != 'IM_Custom Sys Admin' && user.Profile.Name !='' )&& (recordTypeName == 'Case Type' || recordTypeName == 'I and T Cases - Task Layout')) {
                      t.addError('The task you are trying to delete can only be deleted by a System Administrator.');   
                    }
                }
             }
            /****checkOnDelete****/
            /*---end---*/       
        }   

        if(Trigger.isInsert || Trigger.isUpdate){
            ActivityService.getContactLevel(Trigger.new);
        }
    }
    
    /*************************************END OF BEFORE INSERT AND UPDATE***************************/
    
    
    /*********************************************AFTER INSERT AND UPDATE*********************/
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            runUpdateCaseOpenTask = true;
            runGenerateCaseOnTaskCreation = true;
            System.debug('----74------runUpdateCaseOpenTask:'+runUpdateCaseOpenTask);
            System.debug('----248------runGenerateCaseOnTaskCreation:'+runGenerateCaseOnTaskCreation);
        }
        if(Trigger.isUpdate){
            runUpdateCaseOpenTask = true;
            System.debug('-----78-----runUpdateCaseOpenTask:'+runUpdateCaseOpenTask);
        }
        if(Trigger.isInsert || Trigger.isUpdate){
            ActivityService.rollUp(Trigger.new);
        }
    }
    
    /*************************************END OF AFTER INSERT AND UPDATE***************************/
    
    /**************************************************END TRIGGER*********************************************/
    
    /****UpdateCaseOpenTask ****/
    /*---start---*/
     System.debug('---------firing UpdateCaseOpenTask trigger----:'+UpdateCaseOpenTask);
     if(UpdateCaseOpenTask == 'True'){
        System.debug('----------runUpdateCaseOpenTask:'+runUpdateCaseOpenTask);
        if(runUpdateCaseOpenTask==true){
            String whatId;
            for(Task newtask :Trigger.new){
                whatId = newTask.WhatId;
                if(newTask.WhatId != null && whatId.startsWith('500') && newTask.Activity_Type__c == 'Task'){
                    mapTaskWithCaseID.put(newTask.WhatId,newTask);
                }
            }
            if(mapTaskWithCaseID.keySet().size() > 0){
               // Get all opened Task of selected case
              List<Task> lstOpenCaseTask =[Select WhatId from Task where WhatId in:mapTaskWithCaseID.keySet() and Status != 'Completed'];
              Set<Id> caseHasOpenedTaskId = new Set<Id>();
              if(lstOpenCaseTask.size() > 0){
                  for( Task t: lstOpenCaseTask){
                    caseHasOpenedTaskId.add(t.WhatId);
                  }
              }              

              List<Event> lstOpenCaseEvent=[Select e.WhatId, e.EndDateTime, e.Activity_Type__c,e.Due_Date__c From Event e where e.WhatId in:mapTaskWithCaseID.keySet() and e.EndDateTime >: DateTime.now()];
              Set<Id> caseHasOpenedEventId = new Set<Id>();
              if(lstOpenCaseEvent.size() > 0){
                  for( Event e: lstOpenCaseEvent){
                    caseHasOpenedEventId.add(e.WhatId);
                  }
              }
              fillRecordTypeIds2(); 
              // get the selected case and update them
              List <Case> lstCase = [select id ,Open_Tasks__c,RecordTypeId,Status from Case where RecordTypeId in :recordTypeIds2 and id in: mapTaskWithCaseID.keySet() ];
              if(lstCase.size() > 0){
                List<case> updatedcase = new List<Case>();
                for( case c: lstCase){
                    if(c.Status == 'Closed' || c.Status =='Complete'|| c.Status == 'Cancelled' || c.Status =='Duplicate' || c.Status =='Inactive'){
                        Task t= mapTaskWithCaseID.get(c.ID);
                        t.addError('Case is currently in a closed status -- please reopen case in order to make task updates.');
                        continue;
                    }
                    if(caseHasOpenedEventId.contains(c.id) || caseHasOpenedTaskId.contains(c.id)){
                        // case has opned task or event
                          c.Open_Tasks__c = 'Yes';
                    }
                    else{
                        // there is no opned task or event for tha case
                        c.Open_Tasks__c = 'No';
                    }
                    updatedcase.add(c);
                }
                //Developer Name: Madhu Paladugu
                //Case Number   : 00917426
                try{
                    update updatedcase;
                }catch(DmlException ex){
                  if(ex.getMessage().contains('The following error occurred while trying to update the associated opportunity record:')){
                      Trigger.new[0].addError('The following error occurred while trying to update the opportunity record associated to this case: '+ex.getMessage().substringAfterLast('opportunity record:').removeEnd(': []'));
                  }
                  else{
                      Trigger.new[0].addError('The following error occurred while trying to update the associated case record: '+'"'+ex.getMessage().substringAfterLast('FIELD_CUSTOM_VALIDATION_EXCEPTION, ').removeEnd(': []')+'"');
                  }
                }
              }
              
            }       
        }
     }
    /****UpdateCaseOpenTask ****/
    /*---end---*/ 
    
    /****GenerateCaseOnTaskCreation ****/
    /*---start---*/
     System.debug('---------firing GenerateCaseOnTaskCreation trigger----:'+GenerateCaseOnTaskCreation);
     if(GenerateCaseOnTaskCreation == 'True'){
        System.debug('----------runGenerateCaseOnTaskCreation:'+runGenerateCaseOnTaskCreation);
        if(runGenerateCaseOnTaskCreation==true){
            String whatId;
            
            div = [select id, Name from Division];
            for(Division dv : div){
                divmap.put(dv.Name, dv.id);
            }
            
                for(Task newTask :Trigger.new)
                {
                    strContLst.add(newTask.whoId);
                }
                system.debug('strContLst----'+strContLst);
                if(strContLst.size() > 0 ){
                    ContList = [Select id, Division from Contact where id IN: strContLst];
                }
                if(!ContList.isEmpty())
                {
                    for(Contact rt :ContList)
                    {
                        ContIdMap.put(rt.Id, rt.Division);
                    }
                }
               system.debug('ContIdMap----'+ContIdMap);  
            for(Task newTask :Trigger.new){
                system.debug('trigger.new--354--'+trigger.new);
                if(newTask.WhatId != NULL)
                {
                whatId = newTask.WhatId;
                system.debug('whatId--354--'+whatId);
                system.debug('newTask.WhatId--354--'+newTask.WhatId);
                system.debug('whatId.startsWith()--354--'+whatId.startsWith('003'));
                system.debug('newTask.Activity_Type__c--354--'+newTask.Activity_Type__c);
                if(newTask.WhatId != null && whatId.startsWith('001') && newTask.Activity_Type__c == 'Task'){   
                system.debug('entering all ifs---');    
                system.debug('ContIdMap.get(newTask.whoId)--354--'+ContIdMap.get(newTask.whoId));  
                system.debug('divmap.get(Europe)--354--'+divmap.get('Europe'));        
                if(ContIdMap.get(newTask.whoId) == divmap.get('Europe')){
                system.debug('entering if 364');
                lstTask.add(newTask);
                system.debug('lstTask--366--'+lstTask); 
                }
                }
                }
            }
             system.debug('lstTask----'+lstTask); 
            TaskTriggerHelper.createCaseWhenNeeded(lstTask);   
        }
     }
    /****GenerateCaseOnTaskCreation ****/
    /*---end---*/   
    
    
    /****updateTaskNotification****/
    /*---start---*/
    // Commenting this Implementation completly as per case #03362496 
    /* System.debug('------updateTaskNotification:'+updateTaskNotification);
     if(updateTaskNotification == 'True'){
        if(runupdateTaskNotification==true){
            try {
                Task t = Trigger.new[0];
                String sub ='';
                sub = String.valueOf(t.Subject);
                System.debug('---20---sub:'+sub);
                //Update 3/17 - Filter Tasks created from Brainshark, Eloqua and sending Emails
                if (!sub.startsWith('SENT:') && !sub.startsWith('Email:') && !sub.startsWith('VIEWED:') && !sub.startsWith('Website Visit')
                        && !sub.startsWith('Bounceback:') && !sub.startsWith('Email click through:') && !sub.startsWith('Email Viewed:')
                        && !sub.startsWith('Form:') && !sub.startsWith('Subscribed to Eloqua emails') && !sub.startsWith('UNSUBSCRIBED from receiving emails') ) { 
                    String myString  = ' ';
                    String phone    = 'Not Available';
                    Integer canUpdateFlag = 0;
                    System.debug('---28---t.WhoId:'+t.WhoId +'\t t.WhatId:'+t.WhatId +'\t t.AccountId:'+t.AccountId);
                    if (t.WhoId != NULL ) { //Task may be associated to Contact/Lead via 'WhoId'
                        String whoId    = ' ';
                        whoId = String.valueOf(t.WhoId);
                        System.debug('---32---whoId:'+whoId.subString(0,3).equals('003') +'\t ---'+whoId.subString(0,3).equals('00Q'));
                        /*if (whoId.subString(0,3).equals('003')) { 
                            Contact C = [select id, Phone from Contact where id =: t.WhoId];
                            phone = String.valueOf(C.Phone);
                            canUpdateFlag = 1;
                            
                        }
                        else 
                        if (whoId.subString(0,3).equals('00Q')) {
                            Lead L = [select id, Phone from Lead where id =: t.WhoId];
                            phone = String.valueOf(L.Phone);
                            canUpdateFlag = 1;
                        }
                    } else if (t.WhatId != NULL) { //Task may be associated to Opp,Acct,Camp,Case via 'WhatId'
                        String whatId    = ' ';
                        whatId = String.valueOf(t.WhatId);
                        System.debug('---46---whatId.subString(0,3):'+whatId.subString(0,3).equals('001'));
                        if (whatId.subString(0,3).equals('001')) { 
                            Account A = [select id, Phone from Account where id =: t.WhatId];
                            phone = String.valueOf(A.Phone);
                            canUpdateFlag = 1;
                        }
                    } else {
                        if (t.AccountId != NULL) { //Task may also be associated to Account via 'AccountId'
                            Account A = [select id, Phone from Account where id =: t.AccountId];
                            phone = String.valueOf(A.Phone);
                            canUpdateFlag = 1;
                        }   
                    }
                    System.debug('---59---canUpdateFlag:'+canUpdateFlag +'\t phone:'+phone +'\t t.Description:'+t.Description);
                    if (canUpdateFlag == 1 ) {
                         if (phone != NULL) {
                            if (t.Description != NULL) {
                                myString  = t.Description;
                                System.debug('---64---myString:'+myString +'\t ---:'+myString.startsWith('Additional To:'));
                                if (myString.startsWith('Additional To:') == FALSE) {                            
                                    Integer i = myString.indexOf('Phone: [', 0);
                                    System.debug('---67---i:'+i);
                                    If ( i != -1) {
                                        String fString = '';
                                        String lString = '';
                                        Integer k = myString.indexOf(']', i);
                                        fString = myString.substring(0, i).trim();
                                        if ( k+1 < myString.length())
                                            lString = myString.substring(k+1).trim();
                                        myString = fString+ ' '+lString + '\n' +'Phone: [' + phone + ']'; 
                                        
                                    } else
                                        myString = myString+'\n'+'Phone: ['+ phone +']';                        
                                }
                            }
                            else 
                                myString = '-'+'\n'+'Phone: ['+ phone +']';
                            
                        } else {
                            System.debug('---85----t.Description:'+t.Description);
                            if (t.Description != NULL) {
                                myString  = t.Description;
                                System.debug('--88---myString:'+myString +'\t -----:'+myString.startsWith('Additional To:'));
                                if (myString.startsWith('Additional To:') == FALSE) {
                                    System.debug('---90----'+myString.indexOf('Phone: [', 0));
                                    if (myString.indexOf('Phone: [', 0) != -1) {
                                        //DO NOTHING as we might lose the existing Phone number
                                        System.debug('--93---DO NOTHING as we might lose the existing Phone number------');
                                    } else {
                                        myString = myString+'\n'+'Phone: [Not Available]';
                                    }
                                }
                            } else 
                                myString  = '-'+'\n'+'Phone: [Not Available]';
                        }
                        t.Description = myString;
                        System.debug('---102---t.Description:'+t.Description);
                    }
                } 
            }
            catch(Exception ex){
                Trigger.new[0].addError('Internal error to fetch the phone number.');
                System.debug('---108---inside catch-----');
            }
        }
     }
    */
    // Commenting this Implementation completly as per case #03362496 
    /****updateTaskNotification****/
    /*---end---*/
    
    
    /****CreateTaskOnCase****/
    /*---start---*/
     System.debug('-----------CreateTaskOnCase:'+CreateTaskOnCase);
     if(CreateTaskOnCase == 'True'){
        if(runCreateTaskOnCase==true){
            Map<id,id> AssignedCountrymap=new Map<Id,id>();
            System.debug('+++++401++++++firing runCreateTaskOnCase trigger++++++++');
            System.debug('---5----Trigger.isInsert:'+Trigger.isInsert +'\t Trigger.isUpdate:'+Trigger.isUpdate);
              if(Trigger.isInsert) {
                
                for(Task t : Trigger.new) {
                                       
                    //getting all the user id maps to assign correct due dates
                    if(t.ownerId!=null){
                        AssignedCountrymap.put(t.id,t.ownerId);
                    }
                    /*case Number : 01369542
                      Description : added condition to make sure every task has the subject
                    */
                  try{
                      if(t.Subject.length() > 7 && t.Subject.substring(0, 6) == subHeader) { //task on Case whose subject has been modified with a workflow.
                        subjectStrings.add(t.Subject.substring(7));
                        System.debug('----13---subjectStrings:'+subjectStrings);
                      }
                  }
                  catch(Exception e){
                    Trigger.new[0].addError('This record was not added into Salesforce, because the subject line is blank. Please make sure this task record has data shown in the "subject" field, and then try to re-sync.');
                  }
                }
              
               // Fetching Record Type Id to be assigned to Task (If from case)
               Schema.DescribeSObjectResult tskResult = Schema.SObjectType.Task;
               Map<String,Schema.RecordTypeInfo> rtMapByName = tskResult.getRecordTypeInfosByName();
               for(String recordName : rtMapByName.keySet()){
                  System.debug('---20----recordName:'+recordName);
                  if(recordName == 'Case Type'){
                    recordTypeIdCase = rtMapByName.get(recordName).getRecordTypeId();
                    System.debug('---23----recordTypeIdCase:'+recordTypeIdCase);
                  }
               }
                
                /*List<Task_Details__c> taskDetails = [Select t.Name, t.Unique_Task__c, t.Subject__c, t.Sub_Area__c, t.SLA__c, t.SLA_Time_Type__c, t.Id, 
                                                    t.Description__c, t.Business_area__c, t.Service_Line__c, t.Dashboard_Bar_Name__c,  t.Business_Hours__r.Id,
                                                    t.Mandatory_Task__c, t.Instructions__c, t.Group_Name__c, Include_In_Dashboard__c 
                                                    From Task_Details__c t where t.Unique_Task__c in :subjectStrings]; */
                List<Task_Details__c> taskDetails = new List<Task_Details__c>();
                System.debug('---32----subjectStrings:'+subjectStrings);
                if(subjectStrings.size() > 0){
                    // #16914 remove t.Group_Name__c,t.Instructions__c,t.Service_Line__c,t.Sub_Area__c fields from below query
                    taskDetails = [Select t.Name, t.Unique_Task__c, t.Subject__c, t.SLA__c, t.SLA_Time_Type__c, t.Id, 
                                                    t.Description__c, t.Business_area__c, t.Dashboard_Bar_Name__c,  t.Business_Hours__r.Id,
                                                    t.Mandatory_Task__c, Include_In_Dashboard__c 
                                                    From Task_Details__c t where t.Unique_Task__c in :subjectStrings];
                    System.debug('---38----taskDetails:'+taskDetails);
                }
                Map<String, Task_Details__c> nameDetailsMap = new Map<String, Task_Details__c>();
                for(Task_Details__c td : taskDetails) {
                  nameDetailsMap.put(td.Unique_Task__c, td);
                  System.debug('----43---nameDetailsMap:'+nameDetailsMap);
                }
            
                for(Task t : Trigger.new) {
                 //geeting assigned user id and passing it to calculate due value
                 Id uid;
                 if(AssignedCountrymap.ContainsKey(t.id))
                  uid=AssignedCountrymap.get(t.id);
                  
                  if(t.Subject!=null && t.Subject.length() > 7 && nameDetailsMap.containsKey(t.Subject.substring(7))) {
                    Task_Details__c td = nameDetailsMap.get(t.Subject.substring(7));
                    System.debug('----------td:'+td);
                    //Comment out #16914
                    //t.Area__c = td.Business_area__c;
                    //Comment out #16914
                    //t.Sub_Area__c = td.Sub_Area__c;
                    //Comment out #16914
                    //t.Unique_Task__c = td.Unique_Task__c;
                    t.Subject = td.Subject__c;
                    t.Description = td.Description__c;
                    //Comment out #16914
                    //t.Service_Line__c = td.Service_Line__c;
                    // comented by vinod kumar september 16
                    t.Dashboard_Bar_Name__c = td.Dashboard_Bar_Name__c;
                    
                    // Adding Due Date
                   // System.debug('----------td.SLA_Time_Type__c:'+td.SLA_Time_Type__c +'\t td.SLA__c.intValue():'+td.SLA__c.intValue() +'\t td.Business_Hours__r.Id:'+td.Business_Hours__r.Id);
                    t.Due_Date__c = Util.getDueDateTime(td.SLA_Time_Type__c, td.SLA__c.intValue(), td.Business_Hours__r.Id,uid);
                    // Updating Standard Due Date with Calculated Custom Due Date
                    t.ActivityDate = t.Due_Date__c.date();
                    // Setting Case Record Type in Task
                    String whatId = t.WhatId;
                    //System.debug('----65-----whatId:'+whatId +'\t ---:'+whatId.startsWith('500') +'\t recordTypeIdCase:'+recordTypeIdCase);
                    if(whatId != null && whatId.startsWith('500') && recordTypeIdCase != ''){
                        t.RecordTypeId = recordTypeIdCase;
                        System.debug('---68------t.RecordTypeId:'+t.RecordTypeId);
                    }
                    
                    // adding new fields
                    t.Include_In_Dashboard__c = td.Include_In_Dashboard__c;
                    //Comment out #16914
                    //t.Instructions__c = td.Instructions__c;
                    //Comment out #16914
                    //t.Group_Name__c = td.Group_Name__c;
                    t.Mandatory_Task__c = td.Mandatory_Task__c;
                  }
                }                               
              }
              if(Trigger.isUpdate){
                DateTime dt ;
                Set <String> uniqueTask= new Set<String>();
                Map<String, Task> mapTask=new Map<String, Task>();
                
                for(Task t : Trigger.new){
                    if(t.Due_Date__c != Trigger.oldMap.get(t.id).Due_Date__c){
                        dt= dt=t.Due_Date__c;
                        t.ActivityDate=dt.Date();
                    }
                    // Comment Out #16914
                    /*System.debug('-----89-----Trigger.oldMap.get(t.id).Status:'+Trigger.oldMap.get(t.id).Status +'\t t.Status:'+t.Status +'\t t.Unique_Task__c:'+t.Unique_Task__c);
                    if(Trigger.oldMap.get(t.id).Status != 'Completed' && t.Status == 'Completed' &&  t.Unique_Task__c !=''){
                        uniqueTask.add(t.Unique_Task__c);
                        mapTask.put(t.Unique_Task__c,t);
                        System.debug('---93-----uniqueTask:'+uniqueTask +'\t mapTask:'+mapTask);
                    }*/
                }
              
               /* List<Task_Details__c> taskDetails = [Select t.ID, t.Unique_Task__c, t.Subject__c,t.Mandatory_Task__c, t.Instructions__c, t.Group_Name__c, Include_In_Dashboard__c
                                                    From Task_Details__c t where t.Unique_Task__c in :uniqueTask]; */
                List<Task_Details__c> taskDetails = new List<Task_Details__c>();
                System.debug('----100----uniqueTask:'+uniqueTask);
                if(uniqueTask.size() > 0){
                    // #16914 remove t.Group_Name__c,t.Instructions__c fields from below query
                    taskDetails = [Select t.ID, t.Unique_Task__c, t.Subject__c,t.Mandatory_Task__c, Include_In_Dashboard__c
                                                    From Task_Details__c t where t.Unique_Task__c in :uniqueTask];
                    System.debug('---104----taskDetails:'+taskDetails); 
                }                                       
                Map<ID, Task_Details__c> mapTaskDetail= new Map<Id,Task_Details__c>();
                Set<Id> taskUniqueId =new Set<Id>();
                for(Task_Details__c td : taskDetails) {
                  mapTaskDetail.put(td.ID, td);
                  taskUniqueId.add(td.ID);
                  System.debug('---111----taskUniqueId:'+taskUniqueId +'\t mapTaskDetail:'+mapTaskDetail);
                }   
                                                                                        
                /*List <Closure_Action__c> clouserAction=[Select c.Value_To_Assign__c, c.Task_ID__c, c.Id, c.Case_Field_Data_Type__c,
                        c.Case_Field_API_Name__c, c.Action_Type__c , c.Task_Action_Id__c
                        From Closure_Action__c c
                        Where c.Task_ID__c In :taskUniqueId
                        ];*/
                List <Closure_Action__c> clouserAction = new List <Closure_Action__c>();   
                System.debug('---120----taskUniqueId:'+taskUniqueId);
                if(taskUniqueId.size() > 0){
                    clouserAction=[Select c.Value_To_Assign__c, c.Task_ID__c, c.Id, c.Case_Field_Data_Type__c,
                        c.Case_Field_API_Name__c, c.Action_Type__c , c.Task_Action_Id__c
                        From Closure_Action__c c
                        Where c.Task_ID__c In :taskUniqueId
                        ];
                    System.debug('---127---clouserAction:'+clouserAction);
                }                         
                List <Task> newTask= new List<Task>();
                Set<Id>caseToBeUpdated = new Set<id>();
                Map<ID,String> caseFieldToBeUpdated = New Map<Id,String>();
                Map<ID,String> caseFieldDataType = New Map<Id,String>();
                Map<ID,String> caseFieldvalueAssigned = New Map<Id,String>();
                if(clouserAction.size() > 0){
                    for(Closure_Action__c ca : clouserAction){
                        System.debug('---136----ca.Action_Type__c:'+ca.Action_Type__c);
                        if(ca.Action_Type__c == 'Task'){ // creating new task 
                            Task t= new task();
                            Task_Details__c td = mapTaskDetail.get(ca.Task_ID__c);
                            Task oldTask = mapTask.get(td.Unique_Task__c);
                            t.Subject = subHeader + ' ' + ca.Task_Action_Id__c;
                            t.WhatId = oldTask.WhatId;
                            System.debug('----143---recordTypeIdCase:'+recordTypeIdCase);
                            if(recordTypeIdCase != ''){
                               t.RecordTypeId = recordTypeIdCase;
                               System.debug('----146---t.RecordTypeId:'+t.RecordTypeId);
                            }         
                            // adding new fields
                            t.Include_In_Dashboard__c = td.Include_In_Dashboard__c;
                            //Comment out #16914
                            //t.Instructions__c = td.Instructions__c;
                            //Comment out #16914
                            //t.Group_Name__c = td.Group_Name__c;
                            t.Mandatory_Task__c = td.Mandatory_Task__c;    
                            newTask.add(t);
                            System.debug('---154----newTask:'+newTask);
                        }
                        else if(ca.Action_Type__c == 'Case field Update'){
                            Task_Details__c td = mapTaskDetail.get(ca.Task_ID__c);
                            Task oldTask = mapTask.get(td.Unique_Task__c);
                            caseToBeUpdated.add(oldTask.WhatId);
                            caseFieldToBeUpdated.put(oldTask.WhatId,ca.Case_Field_API_Name__c);
                            caseFieldDataType.put(oldTask.WhatId,ca.Case_Field_Data_Type__c);
                            caseFieldvalueAssigned.put(oldTask.WhatId,ca.Value_To_Assign__c);               
                            System.debug('---163----caseToBeUpdated:'+caseToBeUpdated);
                            System.debug('----164---caseFieldToBeUpdated:'+caseFieldToBeUpdated);
                            System.debug('---165----caseFieldDataType:'+caseFieldDataType);
                            System.debug('---166----caseFieldvalueAssigned:'+caseFieldvalueAssigned);                
                        }
                        
                    }
                }
                List<Case> lstCase = new list<case>();
                System.debug('---172----caseToBeUpdated:'+caseToBeUpdated);
                if(caseToBeUpdated.size() > 0){
                 lstCase=[Select Id From case where id in : caseToBeUpdated];
                 System.debug('---175----lstCase:'+lstCase);
                }
                String datatype;
                String fieldValue;
                String fieldApiName;
                List<Case> lstCaseUpdate= new  List<Case>();
                for(Case c : lstCase)
                {
                    datatype = caseFieldDataType.get(c.Id);
                    fieldValue = caseFieldvalueAssigned.get(c.Id);
                    fieldApiName = caseFieldToBeUpdated.get(c.Id);
                    System.debug('---186----datatype.toUpperCase():'+datatype.toUpperCase());
                    if(datatype.toUpperCase() == 'INTEGER')
                          c.put(fieldApiName,Integer.ValueOf(fieldValue));
                    else if(datatype.toUpperCase() == 'BOOLEAN')
                          c.put(fieldApiName,BOOLEAN.ValueOf(fieldValue));
                    else if(datatype.toUpperCase() == 'DATE')            
                          c.put(fieldApiName,DATE.today());
                    else if(datatype.toUpperCase() == 'DATETIME')
                        c.put(fieldApiName,DATETIME.now());     
                    else if(datatype.toUpperCase() == 'DOUBLE')
                          c.put(fieldApiName,DOUBLE.ValueOf(fieldValue));
                    else if(datatype.toUpperCase() == 'PICKLIST' || datatype.toUpperCase() == 'TEXTAREA' || datatype.toUpperCase() == 'TEXT' || datatype.toUpperCase() == 'STRING' || datatype.toUpperCase() == 'PHONE' || datatype.toUpperCase() == 'REFERENCE' || datatype.toUpperCase() == 'MULTIPICKLIST')
                          c.put(fieldApiName,fieldValue);
                    lstCaseUpdate.add(c);
                    System.debug('----200---lstCaseUpdate:'+lstCaseUpdate);
                }
                if(lstCaseUpdate.size() > 0){
                    update lstCaseUpdate;
                    System.debug('---204----lstCaseUpdate:'+lstCaseUpdate);
                }
                System.debug('---206----newTask:'+newTask);
                if(newTask.size() > 0){
                    insert newTask;
                    System.debug('---209----newTask:'+newTask);
                }
              }
        }
     }
    /****CreateTaskOnCase****/
    /*---end---*/
    private void fillRecordTypeIds(){
        Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds();
        if(rtMapByName.containsKey('CAC_DP_Closure'))
            recordTypeIds.add(rtMapByName.get('CAC_DP_Closure').getRecordTypeId());
        if(rtMapByName.containsKey('CAC_SKP_RM'))
            recordTypeIds.add(rtMapByName.get('CAC_SKP_RM').getRecordTypeId());    
        if(rtMapByName.containsKey('CAC_SKP_Shred'))
            recordTypeIds.add(rtMapByName.get('CAC_SKP_Shred').getRecordTypeId());
        // Comment Out #16914
        /*if(rtMapByName.containsKey('Issue'))
            recordTypeIds.add(rtMapByName.get('Issue').getRecordTypeId());
        if(rtMapByName.containsKey('Issues_Question'))
            recordTypeIds.add(rtMapByName.get('Issues_Question').getRecordTypeId());    
        if(rtMapByName.containsKey('Issue_Request'))
            recordTypeIds.add(rtMapByName.get('Issue_Request').getRecordTypeId());*/
        if(rtMapByName.containsKey('NCSP_DMS'))
            recordTypeIds.add(rtMapByName.get('NCSP_DMS').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_DP_Onboarding_team'))
            recordTypeIds.add(rtMapByName.get('NCSP_DP_Onboarding_team').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_SKP_Department_Add_Only'))
            recordTypeIds.add(rtMapByName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_SKP_New_customer_setup'))
            recordTypeIds.add(rtMapByName.get('NCSP_SKP_New_customer_setup').getRecordTypeId());
       /* if(rtMapByName.containsKey('Retention'))
            recordTypeIds.add(rtMapByName.get('Retention').getRecordTypeId()); */                 
        // Comment Out #16914
        /*if(rtMapByName.containsKey('Task'))
            recordTypeIds.add(rtMapByName.get('Task').getRecordTypeId());
        if(rtMapByName.containsKey('Task_Question'))
            recordTypeIds.add(rtMapByName.get('Task_Question').getRecordTypeId());
        if(rtMapByName.containsKey('Task_Request'))
            recordTypeIds.add(rtMapByName.get('Task_Request').getRecordTypeId());*/
        //Changes made for 
        if(rtMapByName.containsKey('NCSP_Tech_Services_New_Customer_Setup'))
            recordTypeIds.add(rtMapByName.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId());
        // # 10469 and #10364 adding record types Retention RM and Retention SH
        if(rtMapByName.containsKey('Retention_RM'))
            recordTypeIds.add(rtMapByName.get('Retention_RM').getRecordTypeId());
        if(rtMapByName.containsKey('Retention_SH'))
            recordTypeIds.add(rtMapByName.get('Retention_SH').getRecordTypeId());
    }
    
    private void fillRecordTypeIds2(){
        Map<String,Schema.RecordTypeInfo> rtMapByName2 = CaseRecordTypeSelection.getRecordTypeIds();
        // Comment Out #16914
        /*if(rtMapByName2.containsKey('Issue'))
            recordTypeIds2.add(rtMapByName2.get('Issue').getRecordTypeId());          
        if(rtMapByName2.containsKey('Task'))
            recordTypeIds2.add(rtMapByName2.get('Task').getRecordTypeId());           
        if(rtMapByName2.containsKey('Issue_Request'))
            recordTypeIds2.add(rtMapByName2.get('Issue_Request').getRecordTypeId());
        if(rtMapByName2.containsKey('Task_Request'))
            recordTypeIds2.add(rtMapByName2.get('Task_Request').getRecordTypeId());*/
       if(rtMapByName2.containsKey('NCSP_DMS'))
           recordTypeIds2.add(rtMapByName2.get('NCSP_DMS').getRecordTypeId());
       if(rtMapByName2.containsKey('NCSP_DP_Onboarding_team'))
          recordTypeIds2.add(rtMapByName2.get('NCSP_DP_Onboarding_team').getRecordTypeId());
       if(rtMapByName2.containsKey('NCSP_SKP_Department_Add_Only'))
           recordTypeIds2.add(rtMapByName2.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
        if(rtMapByName2.containsKey('NCSP_SKP_New_customer_setup'))
           recordTypeIds2.add(rtMapByName2.get('NCSP_SKP_New_customer_setup').getRecordTypeId());
        if(rtMapByName2.containsKey('NCSP_Upsell'))
           recordTypeIds2.add(rtMapByName2.get('NCSP_Upsell').getRecordTypeId()); 
    //   cac and retention
        if(rtMapByName2.containsKey('CAC_DP_Closure'))
         recordTypeIds2.add(rtMapByName2.get('CAC_DP_Closure').getRecordTypeId());
       if(rtMapByName2.containsKey('CAC_SKP_RM'))
        recordTypeIds2.add(rtMapByName2.get('CAC_SKP_RM').getRecordTypeId());
     if(rtMapByName2.containsKey('CAC_SKP_Shred'))
       recordTypeIds2.add(rtMapByName2.get('CAC_SKP_Shred').getRecordTypeId());
       //newly added on 5/18/2021 #16499251
     if(rtMapByName2.containsKey('Case_DM'))
            recordTypeIds2.add(rtMapByName2.get('Case_DM').getRecordTypeId());  
            //only till here 5/18/2021 
   /*   if(rtMapByName2.containsKey('Retention'))
        recordTypeIds2.add(rtMapByName2.get('Retention').getRecordTypeId()); */
      //
      if(rtMapByName2.containsKey('NCSP_Tech_Services_New_Customer_Setup'))
        recordTypeIds2.add(rtMapByName2.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId()); 
        // # 10469 and #10364 adding record types Retention RM and Retention SH
        if(rtMapByName2.containsKey('Retention_RM'))
        recordTypeIds2.add(rtMapByName2.get('Retention_RM').getRecordTypeId());
        if(rtMapByName2.containsKey('Retention_SH'))
        recordTypeIds2.add(rtMapByName2.get('Retention_SH').getRecordTypeId());
    }
    
    private void fillRecordTypeIds3(){
        Map<String,Schema.RecordTypeInfo> rtMapByName3 = CaseRecordTypeSelection.getRecordTypeIds();  
        if(rtMapByName3.containsKey('NCSP_DMS'))
            ncspRecordTypeIds.add(rtMapByName3.get('NCSP_DMS').getRecordTypeId());
        if(rtMapByName3.containsKey('NCSP_DP_Onboarding_team'))
            ncspRecordTypeIds.add(rtMapByName3.get('NCSP_DP_Onboarding_team').getRecordTypeId());
        if(rtMapByName3.containsKey('NCSP_SKP_Department_Add_Only'))
            ncspRecordTypeIds.add(rtMapByName3.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
        if(rtMapByName3.containsKey('NCSP_SKP_New_customer_setup'))
            ncspRecordTypeIds.add(rtMapByName3.get('NCSP_SKP_New_customer_setup').getRecordTypeId()); 
        // cac and retention
        if(rtMapByName3.containsKey('CAC_DP_Closure'))
            cacRecordTypeIds.add(rtMapByName3.get('CAC_DP_Closure').getRecordTypeId());
        if(rtMapByName3.containsKey('CAC_SKP_RM'))
            cacRecordTypeIds.add(rtMapByName3.get('CAC_SKP_RM').getRecordTypeId());
        if(rtMapByName3.containsKey('CAC_SKP_Shred'))
            cacRecordTypeIds.add(rtMapByName3.get('CAC_SKP_Shred').getRecordTypeId());
       /* if(rtMapByName3.containsKey('Retention'))
            cacRecordTypeIds.add(rtMapByName3.get('Retention').getRecordTypeId());   */
        //  
        if(rtMapByName3.containsKey('NCSP_Tech_Services_New_Customer_Setup'))
            cacRecordTypeIds.add(rtMapByName3.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId()); 
        // # 10469 and #10364 adding record types Retention RM and Retention SH	
        if(rtMapByName3.containsKey('Retention_RM'))
            cacRecordTypeIds.add(rtMapByName3.get('Retention_RM').getRecordTypeId());
        if(rtMapByName3.containsKey('Retention_SH'))
            cacRecordTypeIds.add(rtMapByName3.get('Retention_SH').getRecordTypeId());
             
    } 
    
    private set<string> GetUniqueTask(){
        Set<string> TaskUniqueNumber = new set<string>(); 
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -2');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -3');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -4');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -5');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -6');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -7');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -8');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -9');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -10');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -11');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -12');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -13');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -14');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -15');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -16');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -17');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -18');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -19');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -20');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -21');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -23');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -24');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -25');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -26');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -27');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -28');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -29');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -32');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -36');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -25a'); 
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -37'); 
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow –35b'); 
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -38'); 
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -40');
        TaskUniqueNumber.add('NCSP - Task Automation- Workflow -41');  
        TaskUniqueNumber.add('NCSP - Task Automation- Billing Workflow -18');   
        TaskUniqueNumber.add('NCSP - Task Automation- Billing Workflow -19');   
        TaskUniqueNumber.add('NCSP - Task Automation- Billing Workflow -20');           
        return TaskUniqueNumber;
    }
    private set<string> GetCACRetentionUniqueTask(){
        Set<string> TaskUniqueNumber = new set<string>(); 
        TaskUniqueNumber.add('Retention-All-All-401');
        TaskUniqueNumber.add('Retention-All-All-405');
        TaskUniqueNumber.add('Retention-All-All-406');
        TaskUniqueNumber.add('Retention-All-All-407');
        TaskUniqueNumber.add('Retention-All-All-412');
        TaskUniqueNumber.add('Retention-All-All-413');
        TaskUniqueNumber.add('Retention-All-All-414');
        TaskUniqueNumber.add('Retention-All-All-419');
        TaskUniqueNumber.add('Retention-All-All-420');
        TaskUniqueNumber.add('Retention-All-All-421');
        TaskUniqueNumber.add('Retention-All-All-426');
        TaskUniqueNumber.add('Retention-All-All-427');
        TaskUniqueNumber.add('Retention-All-All-428');
        TaskUniqueNumber.add('Retention-All-All-429');
        TaskUniqueNumber.add('Retention-All-All-434');
        TaskUniqueNumber.add('Retention-All-All-435');
        TaskUniqueNumber.add('Retention-All-All-436');

        
        TaskUniqueNumber.add('Closure-SKP-Shred-436');
        TaskUniqueNumber.add('Closure-SKP-Shred-440');
        TaskUniqueNumber.add('Closure-SKP-Shred-444');
        TaskUniqueNumber.add('Closure-SKP-Shred-446');      
        TaskUniqueNumber.add('Closure-SKP-Shred-447');
        TaskUniqueNumber.add('Closure-SKP-Shred-448');
        TaskUniqueNumber.add('Closure-SKP-Shred-449');
        TaskUniqueNumber.add('Closure-SKP-Shred-450');
        TaskUniqueNumber.add('Closure-SKP-Shred-451');
        TaskUniqueNumber.add('Closure-SKP-Shred-452');
        
        TaskUniqueNumber.add('Closure-DP-DP-454');
        TaskUniqueNumber.add('Closure-DP-DP-458');
        TaskUniqueNumber.add('Closure-DP-DP-459');
        TaskUniqueNumber.add('Closure-DP-DP-460');
        TaskUniqueNumber.add('Closure-DP-DP-462');
        TaskUniqueNumber.add('Closure-DP-DP-463');
        TaskUniqueNumber.add('Closure-DP-DP-464');
        TaskUniqueNumber.add('Closure-DP-DP-465');
        TaskUniqueNumber.add('Closure-DP-DP-467');
        TaskUniqueNumber.add('Closure-DP-DP-468');  
   //   TaskUniqueNumber.add('Closure-DP-DP-469');  
        TaskUniqueNumber.add('Closure-DP-DP-470');
        TaskUniqueNumber.add('Closure-DP-DP-472');    
   //   TaskUniqueNumber.add('Closure-DP-DP-473'); 
        TaskUniqueNumber.add('Closure-DP-DP-474');
        
        TaskUniqueNumber.add('Closure-SKP-RM-474');
        TaskUniqueNumber.add('Closure-SKP-RM-475');
        TaskUniqueNumber.add('Closure-SKP-RM-479');
        TaskUniqueNumber.add('Closure-SKP-RM-480');
        TaskUniqueNumber.add('Closure-SKP-RM-481');
        TaskUniqueNumber.add('Closure-SKP-RM-482');
        TaskUniqueNumber.add('Closure-SKP-RM-483');
        TaskUniqueNumber.add('Closure-SKP-RM-484');
        TaskUniqueNumber.add('Closure-SKP-RM-488');
        TaskUniqueNumber.add('Closure-SKP-RM-491');
        TaskUniqueNumber.add('Closure-SKP-RM-493');
        TaskUniqueNumber.add('Closure-SKP-RM-494');
        TaskUniqueNumber.add('Closure-SKP-RM-495');
        TaskUniqueNumber.add('Closure-SKP-RM-496');
        TaskUniqueNumber.add('Closure-SKP-RM-498');
        TaskUniqueNumber.add('Closure-SKP-RM-499');
        TaskUniqueNumber.add('Closure-SKP-RM-500');
        TaskUniqueNumber.add('Closure-SKP-RM-501');
        TaskUniqueNumber.add('Closure-SKP-RM-502');
        TaskUniqueNumber.add('Closure-SKP-RM-504');
        TaskUniqueNumber.add('Closure-SKP-RM-505');
        TaskUniqueNumber.add('Closure-SKP-RM-506');
        TaskUniqueNumber.add('Closure-SKP-RM-509');
        TaskUniqueNumber.add('Closure-SKP-RM-510');
        TaskUniqueNumber.add('Closure-SKP-RM-511');
        TaskUniqueNumber.add('Closure-SKP-RM-512');
        TaskUniqueNumber.add('Closure-SKP-RM-513');
        TaskUniqueNumber.add('Closure-SKP-RM-516');
        TaskUniqueNumber.add('Closure-SKP-RM-517');
        TaskUniqueNumber.add('Closure-SKP-RM-518');
        TaskUniqueNumber.add('Closure-SKP-RM-519');
        TaskUniqueNumber.add('Closure-SKP-RM-520');
        TaskUniqueNumber.add('Closure-SKP-RM-521');
        TaskUniqueNumber.add('Closure-SKP-RM-522');
        TaskUniqueNumber.add('Closure-SKP-RM-523');
        TaskUniqueNumber.add('Closure-SKP-RM-524');
        TaskUniqueNumber.add('Closure-SKP-RM-525');
        TaskUniqueNumber.add('NCSP & CAC/R Case Comment Added');
        
        
        return TaskUniqueNumber;
    }
}