/*****************************************************************************************************************************
Name : Test_CaseCommentObject 
Created By : Srinivasa Rao Mandalapu
Created Date : 11th Jan, 2013
Usages : Test coverage of CaseCommentObject Trigger with custom settings logic.
*****************************************************************************************************************************/
@isTest(SeeAllData=true)
private class Test_CaseCommentObject {
    public static String NewTaskOnCaseWhenCaseCommentCreated=null;
    
    /*NewTaskOnCaseWhenCaseCommentCreated code coverage*/
    static testMethod void TestNewTaskOnCaseWhenCaseCommentCreated() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
          if(cs.Object__c == 'CaseComment') {
            cs.Value__c='True';
            updatesettings.add(cs);
          }
        }
        update updatesettings;
        
        // TO DO: implement unit test
        // craete user
        User u1;
        ID UserID;
        User thisUser = new User ( Id = UserInfo.getUserId() );  
        System.runAs ( thisUser ) {
            UserID =UserInfo.getUserId();
            List<UserRole> lstUserRole =[Select  Name, Id From UserRole where  name = 'VP, Customer Implementations' limit 1];
            Profile p = [select id from profile where name='System Administrator'];
            Id  roleId= null;
            if(lstUserRole.size() >0){
               roleId = lstUserRole[0].ID;
            }
            u1 = new User(alias = 't34345t1', username='test454544@Test.com', email='test.test@Test.com', lastname='test2',
                          emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, 
                          timezonesidkey='America/Los_Angeles' , UserRoleId=roleId, country='USA' );
            insert u1;          
        }  
        system.runAs(u1){ 
            IM_Customer_Account__c custAcc = GenerateTestData.createCustomerAccount('101' , 'Test');
            ID caseRecordType ;
            Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();        
            if(rtMapByName.containsKey('Task'))
                caseRecordType = rtMapByName.get('Task').getRecordTypeId();        
            
            Case newCase = GenerateTestData.createCaseObjectWithoutInsert(caseRecordType , custAcc);           
            insert newCase;
            
            newCase.OwnerId = UserID;
            newCase.status = 'Inactive';
            update newCase;
            
            // Create case comment
            CaseComment testComment = new CaseComment();
            testComment.ParentId = newCase.Id;
            testComment.CommentBody = 'Test Comment';
            testComment.CreatedById = u1.Id;
            /**/
            try{
                insert testComment;
            }
            catch(Exception ex){             
                System.assert(ex.getMessage().contains('Case is currently in a closed status -- please reopen case in order to add comments or attachments'));
            }
            /* */
            newCase.status = 'New';
            update newCase;
            insert testComment;             
            List<Task> lstTask = [select id from Task where WhatId =: newCase.id and Subject = 'Case Notification - case comment added to your case'];
            system.assertEquals(lstTask.size(),1);
        }
    }
}