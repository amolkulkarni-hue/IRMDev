/*COMBINATION OF ALL TRIGGERS ON CaseComment OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 01/11/2013
*/
trigger CaseCommentObject on CaseComment (after insert) {
    /****Variable declaration for 'NewTaskOnCaseWhenCaseCommentCreated' Trigger****/
    public String NewTaskOnCaseWhenCaseCommentCreated = null;
    public Boolean runNewTaskOnCaseWhenCaseCommentCreated = false;
    Set<ID> commentCreatorID = new set<id>();
    Set<ID> caseID = new set<id>();
    Set<Id> recordTypeIds = new Set<Id>();
    Map<ID, CaseComment> mapCaseCommentWithCaseID = new map<ID,CaseComment>();
    // Get case recodtype id
    fillRecordTypeIds(); 
    String strOwnerID;
    
    /***Retrieving Custom Settings***/
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='CaseComment'){
            if(cs.Trigger__c == 'NewTaskOnCaseWhenCaseCommentCreated') {
                NewTaskOnCaseWhenCaseCommentCreated = cs.Value__c; 
                System.debug('----22------NewTaskOnCaseWhenCaseCommentCreated:'+NewTaskOnCaseWhenCaseCommentCreated);   
            }
        }
    }
    
    /*****************************************START TRIGGER*************************************************/

    /*****************************************BEFORE INSERT AND UPDATE*************************************/
    if(Trigger.isBefore){
        //if(Trigger.isInsert){}
        //if(Trigger.isUpdate){}
        //if(Trigger.isDelete){}
    }
    /*************************************END OF BEFORE INSERT AND UPDATE***************************/
    
    
    /*********************************************AFTER INSERT AND UPDATE*********************/
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            /****NewTaskOnCaseWhenCaseCommentCreated****/
            /*---start---*/
             System.debug('----------Executing NewTaskOnCaseWhenCaseCommentCreated Trigger:'+NewTaskOnCaseWhenCaseCommentCreated);
             if(NewTaskOnCaseWhenCaseCommentCreated == 'True'){
                for(CaseComment c : trigger.new){
                     strOwnerID = c.ParentId;
                    if(strOwnerID != null && strOwnerID.startsWith('500')){
                        caseID.add(c.ParentId);
                        commentCreatorID.add(c.CreatedById);
                        mapCaseCommentWithCaseID.put( c.ParentId ,c);
                    }
                }
                list<case> lstCase = [Select id,OwnerId,status from case where id in: caseID and RecordTypeId In :recordTypeIds and OwnerId not in :commentCreatorID];
                List<Task> lstCreatedTask = new List<Task>();
                // get task record type
                ID taskRecordTypeID = getTaskReportType();
                for( Case c : lstCase){
                    if(c.Status == 'Closed' || c.status == 'Completed'|| c.status == 'Cancelled' || c.status == 'Duplicate' || c.status == 'Inactive'){
                        CaseComment cc = mapCaseCommentWithCaseID.get(c.ID);
                        cc.addError('Case is currently in a closed status -- please reopen case in order to add comments or attachments');
                        continue;
                    }
                    strOwnerID = c.OwnerId;
                    if(!strOwnerID.startsWith('00G')){
                     // create a new task task  
                     Task t = new Task();
                     t.Subject = 'Case Notification - case comment added to your case';
                     t.Description = ' Someone has added a new case comment.  Please view the case for additional details';
                     t.Due_Date__c = DateTime.now();
                     t.WhatId = c.id;
                     t.RecordTypeId = taskRecordTypeID;
                     t.Priority = 'Normal';
                     t.Status = 'Not Started';
                     t.Dashboard_Bar_Name__c = 'Manual Task';
                     t.OwnerId = c.OwnerId;
                     lstCreatedTask.add(t);
                    }
                }
                if(lstCreatedTask.size() > 0){
                    // insert all the created task
                    insert lstCreatedTask;
                }
             }
            /****NewTaskOnCaseWhenCaseCommentCreated****/
            /*---End---*/
        }
    }
    
    /*************************************END OF AFTER INSERT AND UPDATE***************************/
    
    /**************************************************END TRIGGER*********************************************/
    
     private void fillRecordTypeIds(){
        // get case record type ID
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();                         
        if(rtMapByName.containsKey('Task'))
            recordTypeIds.add(rtMapByName.get('Task').getRecordTypeId());       
        if(rtMapByName.containsKey('Task Request'))
            recordTypeIds.add(rtMapByName.get('Task Request').getRecordTypeId());
        //Gitlab user Story #12724 start
         /*if(rtMapByName.containsKey('Issue'))
            recordTypeIds.add(rtMapByName.get('Issue').getRecordTypeId());*/
         //Gitlab user Story #12724 End
        //Gitlab user Story #12722 start
         /*if(rtMapByName.containsKey('Issue Request'))
            recordTypeIds.add(rtMapByName.get('Issue Request').getRecordTypeId());*/
         //Gitlab user Story #12722 End
    }
    private ID getTaskReportType(){
        // get task record type ID
        Schema.DescribeSObjectResult d = Schema.SObjectType.Task;        
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Id recordTypeID = null;
        if(rtMapByName.containsKey('Case Type'))
            recordTypeID = rtMapByName.get('Case Type').getRecordTypeId();
        return  recordTypeID;
    }
}