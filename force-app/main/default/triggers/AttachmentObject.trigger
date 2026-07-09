/*COMBINATION OF ALL TRIGGERS ON Attachment OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 01/11/2013
*/
trigger AttachmentObject on Attachment (after insert) {
    
    /**By pass attachment trigger when archive email service is running**/
    List<String> classIds = Label.Email_Archive_Class.split(';');
    List<AsyncapexJob> emailArchiveJob=[SELECT Id FROM AsyncapexJob WHERE ApexClassID in :classIds and Status = 'Processing'];
    if(emailArchiveJob != null && emailArchiveJob.size() > 0 && System.isBatch()) {
        return;
    }

    /****Variable declaration for 'NewTaskOnCaseWhenAttachmentAttached' Trigger****/
    public String NewTaskOnCaseWhenAttachmentAttached = null;
    public Boolean runNewTaskOnCaseWhenAttachmentAttached = false;
    
    Set<ID> attachmentCreatorID = new set<id>();
    Set<ID> caseID = new set<id>();
    Set<Id> recordTypeIds = new Set<Id>();
    Map<ID, Attachment> mapAttachmentWithCaseID = new map<ID,Attachment>();
    // Get case recodtype id
    fillRecordTypeIds(); 
    String strOwnerID;
    
    /***Retrieving Custom Settings***/
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Attachment'){
            if(cs.Trigger__c == 'NewTaskOnCaseWhenAttachmentAttached') {
                NewTaskOnCaseWhenAttachmentAttached = cs.Value__c; 
                System.debug('----22------NewTaskOnCaseWhenAttachmentAttached:'+NewTaskOnCaseWhenAttachmentAttached);   
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
            /****NewTaskOnCaseWhenAttachmentAttached****/
            /*---start---*/
             System.debug('----------Executing NewTaskOnCaseWhenAttachmentAttached Trigger:'+NewTaskOnCaseWhenAttachmentAttached);
             if(NewTaskOnCaseWhenAttachmentAttached == 'True'){
                for(Attachment a : trigger.new){
                     strOwnerID = a.ParentId;
                    if(strOwnerID != null && strOwnerID.startsWith('500')){
                        caseID.add( a.ParentId);
                        attachmentCreatorID.add(a.CreatedById);
                        mapAttachmentWithCaseID.put( a.ParentId ,a);
                    }
                }
                list<case> lstCase = [Select id,OwnerId,Status  from case where id in: caseID and RecordTypeId In :recordTypeIds and OwnerId not in :attachmentCreatorID];
                List<Task> lstCreatedTask = new List<Task>();
                // get task record type

                ID taskRecordTypeID = getTaskReportType();
                for( Case c : lstCase){
                    if(c.Status == 'Closed' || c.status == 'Completed'|| c.status == 'Cancelled' || c.status == 'Duplicate' || c.status == 'Inactive'){
                        Attachment a = mapAttachmentWithCaseID.get(c.ID);
                        a.addError('Case is currently in a closed status -- please reopen case in order to add comments or attachments.');
                        System.debug('--64---a:'+a);
                        continue;
                    }
                    strOwnerID = c.OwnerId;
                    if(!strOwnerID.startsWith('00G')){
                     // create a new task task  
                     Task t = new Task();
                     t.Subject = 'Case Notification - case attachment added to your case';
                     t.Description = ' Someone has added a new attachment.  Please view the case for additional details';
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
                    System.debug('---85----lstCreatedTask:'+lstCreatedTask);
                }
             } 
            /****NewTaskOnCaseWhenAttachmentAttached****/
            /*---end---*/
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
        if(rtMapByName.containsKey('Issue'))
            recordTypeIds.add(rtMapByName.get('Issue').getRecordTypeId());
        if(rtMapByName.containsKey('Issue Request'))
            recordTypeIds.add(rtMapByName.get('Issue Request').getRecordTypeId());
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