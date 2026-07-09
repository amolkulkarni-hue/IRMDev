/** 
 *Author: Srinivasa Rao Mandalapu
 *Date: 11/29/12
 *Comments: Test class for TaskObject Trigger under Task.
 */
@isTest(seeAllData=true)
private class Test_TaskObjectTrigger {
	
    public static String CheckTasksCreatedOnClosedCase=null;
    public static String UpdateCaseOpenTask=null;
	public static String checkOnDelete=null;  
    public static String updateTaskNotification=null;  
    public static String CreateTaskOnCase=null;
  	public static String TaskDueDateValidation=null;
  	
  	//CheckTasksCreatedOnClosedCase trigger
    static testMethod void TestCheckTasksCreatedOnClosedCase() {
    	List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Task') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
        // TO DO: implement unit test
        IM_Customer_Account__c custAcc = GenerateTestData.createCustomerAccount('10431' , 'Test34');
        Case newCase = GenerateTestData.createCase(null ,custAcc.Id);    
        Task_Details__c taskDetail = GenerateTestData.createTaskDetail(); 
        Task task = GenerateTestData.createTask();
        // Add comment for closed case. 
        CaseComment cComment = GenerateTestData.createCaseComment(newCase.id);          
          
        newCase.Status = 'Closed';
        update newCase;
     }
    
    
    //checkOnDelete trigger
    static testMethod void TestcheckOnDelete() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Task') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
        // TO DO: implement unit test
        ID taskRecordType = null;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Task' and Name ='Case Type'];
        if(lstRecordType.size() > 0){            
            taskRecordType = lstRecordType[0].ID;            
        }
        Task task = GenerateTestData.createTaskWithoutInsert(taskRecordType);
        Profile p = [select id from profile where name ='Standard User' limit 1];            
        User u1 = new User(alias = 't2432', username='v32354.kumar6434@metacube.com', email='vinod.kumar@metacube.com', lastname='test2',
                 emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, 
            timezonesidkey='America/Los_Angeles', country ='USA' );          
        insert u1;      
        task.OwnerId = u1.id;
        insert task;
        system.runAs(u1){
            try{
                 delete task; 
             }
             catch(Exception ex){
                System.assert(ex.getMessage().contains('The task you are trying to delete can only be deleted by a System Administrator.'));
             }
         
        }
        Profile p1 = [select id from profile where name ='System Administrator' limit 1];       
        User u2 = new User(alias = 'test2', username='vinod.kumar2@metacube.com', email='vinod2.kumar@metacube.com', lastname='test2',
                 emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p1.Id, 
            timezonesidkey='America/Los_Angeles',country ='USA'  );         
         insert u2;
         system.runAs(u2){          
            delete task;          
        } 
    }
    
    //updateTaskNotification trigger
    static testMethod void TestupdateTaskNotification() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Task') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
        // TO DO: implement unit test
        Account A = new Account(Name='AcTstMet'+system.now(),Phone='1231231231', BillingCountry='United States');
    	insert A;
    	//W-000680
    	Contact C = new Contact(FirstName= 'Test Name', LastName='Contact4TestMethod',Phone='2342342342',
    							email='nagesh.ganji@ironmountain.com');
    	insert C;
    	
    	Lead L = new Lead (LastName='Lead4TestMethod',Company='Account4TestMethod',
    							Status='Open',IM_Lead_Stage__c='1-Inquiry',
    							IM_Functional_Area__c = 'x',
    							LeadSource='Manual');
    	insert L;
    	
        if(A!=NULL && C!=NULL && L!=NULL) {

            Task t1 = new Task();
            t1.Subject = 'TestTask4UnitTest';   t1.WhoId = C.Id;
            t1.Status = 'Not Started';          t1.Priority = 'Low';
            t1.Description = 'Created for Unit Test.  Phone: [1122331122] Check';
            insert t1;
            triggerFlowControl.resetTriggerRunCount('updateTaskNotification');
            Task t2 = new Task();
            t2.Subject = 'TestTask4UnitTest2';  t2.WhoId = L.Id;
            t2.Status = 'Not Started';          t2.Priority = 'Low';
            t2.Description = 'Created for Unit Test2';
            insert t2;     
            triggerFlowControl.resetTriggerRunCount('updateTaskNotification');
            Task t3 = new Task();
            t3.Subject = 'TestTask4UnitTest3';  t3.WhatId = A.Id;
            t3.Status = 'Not Started';          t3.Priority = 'Low';
            t3.Description = '';
            insert t3;
            triggerFlowControl.resetTriggerRunCount('updateTaskNotification');
            Task t4 = new Task();
            t4.Subject = 'TestTask4UnitTest';   t4.WhoId = C.Id;
            t4.Status = 'Not Started';          t4.Priority = 'Low';
            t4.Description = 'Created for Unit Test.';
            insert t4;
            triggerFlowControl.resetTriggerRunCount('updateTaskNotification');
                          
            t1.WhoId = L.Id;
            update t1;
            
            t3.WhatId = NULL;
            t3.WhoId = L.Id;
            update t3;
            
        }
    }
    
    //CreateTaskOnCase trigger
    static testMethod void TestCreateTaskOnCase() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Task') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
        // TO DO: implement unit test
        IM_Customer_Account__c custAcc = GenerateTestData.createCustomerAccount('101' , 'Test');
        Case newCase = GenerateTestData.createCase(null , custAcc.ID);    
        Task_Details__c taskDetail = GenerateTestData.createTaskDetail(); 
        Task task = GenerateTestData.createTask();
        Closure_Action__c curAct = GenerateTestData.createClosureAction(taskDetail.Id , 'Task');   
        Closure_Action__c curAct1  = GenerateTestData.createClosureAction(taskDetail.Id ,'Case field Update');
        
        /*List<Task> tasks = [Select id,Area__c , Sub_Area__c,Unique_Task__c,Subject ,Description,Service_Line__c,Dashboard_Bar_Name__c  ,Include_In_Dashboard__c,
        Instructions__c,Group_Name__c,Mandatory_Task__c from Task where id = : task.Id];*/
        List<Task> tasks = [Select id, Subject ,Description,Dashboard_Bar_Name__c  ,Include_In_Dashboard__c, Mandatory_Task__c from Task where id = : task.Id];
        
        Task t = tasks.get(0);
        //System.AssertEquals(t.Area__c , taskDetail.Business_area__c);
        //System.AssertEquals(t.Sub_Area__c , taskDetail.Sub_Area__c);
        //System.AssertEquals(t.Unique_Task__c , taskDetail.Unique_Task__c);
        System.AssertEquals(t.Subject , taskDetail.Subject__c);
        System.AssertEquals(t.Description , taskDetail.Description__c);
        //System.AssertEquals(t.Service_Line__c , taskDetail.Service_Line__c);
        System.AssertEquals(t.Dashboard_Bar_Name__c , taskDetail.Dashboard_Bar_Name__c);  
        System.AssertEquals(t.Include_In_Dashboard__c , taskDetail.Include_In_Dashboard__c);
        //System.AssertEquals(t.Instructions__c , taskDetail.Instructions__c);
        //System.AssertEquals(t.Group_Name__c , taskDetail.Group_Name__c);
        System.AssertEquals(t.Mandatory_Task__c , taskDetail.Mandatory_Task__c);
        
        task.Status = 'Completed';
        update task;
        String subHeader = '^^$$##';
        
        /*tasks = [Select id,Area__c , Sub_Area__c,Unique_Task__c,Subject ,Description,Service_Line__c,Dashboard_Bar_Name__c  ,Include_In_Dashboard__c,
        Instructions__c,Group_Name__c,Mandatory_Task__c from Task where subject =: subHeader + ' ' + curAct.Task_Action_Id__c];*/
        
        /*tasks = [Select id, Subject ,Description,Dashboard_Bar_Name__c  ,Include_In_Dashboard__c,
        Mandatory_Task__c from Task where subject =: subHeader + ' ' + curAct.Task_Action_Id__c];*/
        
        //Task t1 = tasks.get(0);
        //System.AssertEquals(t1.Include_In_Dashboard__c , taskDetail.Include_In_Dashboard__c);
        //System.AssertEquals(t1.Instructions__c , taskDetail.Instructions__c);
        //System.AssertEquals(t1.Group_Name__c , taskDetail.Group_Name__c);
        //System.AssertEquals(t1.Mandatory_Task__c , taskDetail.Mandatory_Task__c);
    }
    
    //TaskDueDateValidation trigger
    //Srinu: Test Method for Updating a Task with User who had assgned to a Role.
    static testMethod void TestTaskDueDateValidation() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Task') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
	    
        // TO DO: implement unit test
        
        // craete user
        User u1;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];  
        System.runAs ( thisUser ) {
        	Profile p = [select id from profile where name='System Administrator'];
        	List<UserRole> lstUserRole =[Select  Name, Id From UserRole where  name = 'VP, Customer Implementations' limit 1];
        	Id  roleId= null;
	        if(lstUserRole.size() >0){
	           roleId = lstUserRole[0].ID;
	        }
	        u1 = new User(alias = 'twqeet', username='v573gfd.ku1@metacube.com', email='vinod.kumar1@metacube.com', lastname='test2',
                           emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, 
                           timezonesidkey='America/Los_Angeles' , UserRoleId=roleId, country='USA' );
            insert u1;	        
        }
        system.runAs(u1){
	        // TO DO: implement unit test
	        IM_Customer_Account__c custAcc = GenerateTestData.createCustomerAccountWithoutInsert('101' , 'Test');
	        insert custAcc;
	        
	        ID caseRecordType ;	        
	        Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds();
	                
	        if(rtMapByName.containsKey('NCSP_DMS'))
	            caseRecordType = rtMapByName.get('NCSP_DMS').getRecordTypeId();
	                    
	        Case newCase = GenerateTestData.createCaseObjectWithoutInsert(caseRecordType , custAcc); 
	        newCase.OwnerId = u1.ID;  
	        newCase.Date_Contracts_CSA_Assigned__c = DateTime.now().addDays(10);
	        newCase.NCSP_CSA__c = u1.ID; 
	        insert newCase ;
	        
	        // Create a task
	        Id taskRecordType;
	        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Task'];
	        if(lstRecordType.size() > 0){           
	            taskRecordType = lstRecordType[0].ID;           
	        }
	        
	        Task testTask = new Task();
	        testTask.Subject = 'Test';
	        testTask.Status = 'Not started';
	        testTask.Priority = 'Normal';
	        testTask.OwnerId =  u1.ID;  
	        testTask.RecordTypeId = taskRecordType;
	        testTask.WhatId = newCase.Id;
	        testTask.Due_Date__c = DateTime.now().addDays(1);
	        //testTask.Unique_Task__c = 'NCSP - Task Automation- Workflow -2';
	        insert testTask;
	              
	        testTask.Due_Date__c = DateTime.now().addDays(10);
	        update testTask;                        
        }  
    }
    
    //TaskDueDateValidation trigger 2nd test method
    //Srinu: Test Method for Updating a Task with User who doesn't have any Role.
    /*static testMethod void TestTaskDueDateValidation2() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Task') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
	    
        // TO DO: implement unit test
        User u2;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
        	Profile p2 = [select id from profile where name='System Administrator'];
        	u2 = new User(alias = 't34641', username='vinod679.kumar@metacube2.com', email='vinod2.kumar@metacube.com', lastname='test2',
                           emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p2.Id, 
                           timezonesidkey='America/Los_Angeles' , UserRoleId=null, country='USA' );
        	insert u2;        	
        }
        system.runAs(u2){
	        // Test error
	        IM_Customer_Account__c custAcc = GenerateTestData.createCustomerAccountWithoutInsert('101' , 'Test');
	        insert custAcc;
	        
	        ID caseRecordType ;
	        Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds();        
	        if(rtMapByName.containsKey('NCSP_DMS'))
	            caseRecordType = rtMapByName.get('NCSP_DMS').getRecordTypeId();
	                    
	        Case newCase = GenerateTestData.createCaseObjectWithoutInsert(caseRecordType , custAcc); 
	        newCase.OwnerId = u2.ID;  
	        insert newCase ;
	        
	        // Create a task
	        Id taskRecordType;
	        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Task'];
	        if(lstRecordType.size() > 0){           
	            taskRecordType = lstRecordType[0].ID;           
	        }
	        Task testTask = new Task();
	        testTask.Subject = 'Test';
	        testTask.Status = 'Not started';
	        testTask.Priority = 'Normal';
	        testTask.OwnerId =  u2.ID;  
	        testTask.RecordTypeId = taskRecordType;
	        testTask.WhatId = newCase.Id;
	        testTask.Due_Date__c = DateTime.now().addDays(1);
	        //testTask.Unique_Task__c = 'NCSP - Task Automation- Workflow -2';
	        insert testTask;
	              
	        testTask.Due_Date__c = DateTime.now().addDays(10);
	        try{
	            update testTask; 
	        }
	        catch(Exception ex){
	           System.assert(ex.getMessage().contains('For this pre-defined task, you are not allowed to change the due date time.'));
	        }
	        testTask.Due_Date__c = DateTime.now().addDays(12);
	        //testTask.Unique_Task__c = 'Retention-All-All-428';
	        try{
	            update testTask; 
	        }
	        catch(Exception ex){
	           System.assert(ex.getMessage().contains('For this pre-defined task, you are not allowed to change the due date time.'));
	        }
        }
    }*/
    
    
    static testMethod void TestTaskTriggerHelper() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Task') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
        
        Id DIVISION_EUROPE_ID =
            [ select id from division where name = 'Europe' ].Id;  
        // TO DO: implement unit test
        Account A = new Account(Name='AcTstMet'+system.now(),Phone='1231231231', BillingCountry='United Kingdom', Division=DIVISION_EUROPE_ID);
    	insert A;
    	
    	//Contact C = new Contact(LastName='Contact4TestMethod',Phone='2342342342',
    						//	email='nagesh.ganji@ironmountain.com',Division=DIVISION_EUROPE_ID);
    	//insert C;
    	//W-000680
    	List<Contact> C = [Select id, Name From Contact Where Division = '02d8000000000kYAAQ' AND Phone=NULL AND MailingStreet=NULL AND MailingCity=NULL AND MailingPostalCode=NULL AND MailingCountry=NULL LIMIT 1];
    	
    	Lead L = new Lead (LastName='Lead4TestMethod',Company='Account4TestMethod',
    							Status='Open',IM_Lead_Stage__c='1-Inquiry',
    							IM_Functional_Area__c = 'x',
    							LeadSource='Manual', Division=DIVISION_EUROPE_ID);
    	insert L;
    	//W-000680
        if(A!=NULL && C!=NULL && L!=NULL && C.size() > 0) {
            Task t1 = new Task();
            t1.Subject = 'Contact Validated';   t1.WhoId = C[0].Id;
            t1.Status = 'Not Started';          t1.Priority = 'Low';
            t1.WhatId = A.Id;
            t1.Description = 'Created for Unit Test.  Phone: [1122331122] Check';
            insert t1;
        }
    }
}