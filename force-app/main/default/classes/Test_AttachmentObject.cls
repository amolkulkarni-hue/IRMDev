/*****************************************************************************************************************************
Name : Test_AttachmentObject 
Created By : Srinivasa Rao Mandalapu
Created Date : 11th Jan, 2013
Usages : Test coverage of CAttachmentObject Trigger with custom settings logic.
Notes: Use seeAllData=true due to custom setting limitation
*****************************************************************************************************************************/
@isTest(SeeAllData=True)
private class Test_AttachmentObject {
	static String NewTaskOnCaseWhenAttachmentAttached=null;
    static final String CLOSED_STATUS = 'Closed';
    static final String OPEN_STATUS = 'Open';
    static final String SUBJECT = 'Subject';
    static final String BODY = 'Body';
    static final Id CASE_RECORDTYPE = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('Issue').getRecordTypeId();
    static final Integer RECORD_COUNT = 10;
    static final Date TODAY = Date.today();
	
	/*NewTaskOnCaseWhenAttachmentAttached code coverage*/
    static testMethod void TestNewTaskOnCaseWhenAttachmentAttached() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Attachment') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
	        
        // TO DO: implement unit test
        // craete user
        User u1;
        ID UserID;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];  
        System.runAs ( thisUser ) {
        	UserID =UserInfo.getUserId();
	        List<UserRole> lstUserRole =[Select  Name, Id From UserRole where  name = 'VP, Customer Implementations' limit 1];
	        Profile p = [select id from profile where name='System Administrator'];
	        Id  roleId= null;
	        if(lstUserRole.size() >0){
	           roleId = lstUserRole[0].ID;
	        }
	        u1 = new User(alias = 'tegst43', username='vinod.kumar44@metacube1.com', email='vinod.kumar@metacube1.com', lastname='test2',
	                 emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, 
	            timezonesidkey='America/Los_Angeles' , UserRoleId=roleId, country='USA' );
	        insert u1;
        }
        
        
        system.runAs(u1){
          
            ID caseRecordType ;            
            Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();        
            if(rtMapByName.containsKey('Issue'))
                caseRecordType = rtMapByName.get('Issue').getRecordTypeId();        
            
            Case newCase = (Case) new SObjectBuilder(Case.SObjectType)
            .put(Case.Status, 'Inactive')
            .put(Case.RecordTypeId, CASE_RECORDTYPE)
            .put(Case.Project_Completion_Date__c, TODAY)
            .put(Case.Transition_Date__c, TODAY)
            // Commenting for 8977 on 17th June 2022
            //.put(Case.Service_Order_Required__c, 'Yes')
            .put(Case.Emails_Archived__c, true)
            .put(Case.OwnerId, UserID)
            .put(Case.Reason__c, 'Test')
            .count(1).create().getRecord();
            
            
            // Attach a attachment to case
            Attachment a1 = (Attachment) new SobjectBuilder(Attachment.SobjectType)
            .put(Attachment.ParentId, newCase.Id)
            .put(Attachment.Name, SUBJECT)
            .put(Attachment.Body, Blob.valueOf('TEST'))
            .count(RECORD_COUNT).build().getRecord();
            /**/
            try{
                insert a1;
            }
            catch(Exception ex){             
                System.assert(ex.getMessage().contains('Case is currently in a closed status -- please reopen case in order to add comments or attachments.'));
            }
            /**/
            newCase.status = 'New';
            update newCase;
            
            insert a1;
           List<Task> lstTask = [select id from Task where WhatId =: newCase.id and Subject = 'Case Notification - case attachment added to your case'];
           system.assertEquals(lstTask.size(),1);
            
        }
    }  
}