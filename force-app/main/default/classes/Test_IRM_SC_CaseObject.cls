/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_IRM_SC_CaseObject (Test Class)
**
** PURPOSE
**   Code Coverage for 'IRM_SC_CaseObject' Apex Trigger. 
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 06/17/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**   v1.1; 10/08/2013; Apurva Dutta; Added Try ctach block. 
************************************************************************/
@isTest(SeeAllData=true)
private class Test_IRM_SC_CaseObject {
    public static String IRM_SC_updateCaseInfoTrigger=null;
    public static String IRM_SC_RaiseOnBoardingCase=null;
    public static String IRM_SC_updateCaseView=null;
    
    static testMethod void Test_IRM_SC_RaiseOnBoardingCase() {
        Test.startTest();
        
        
        // TO DO: implement unit test
        case sendNotification= new case();
        //RecordType caseRecordTypeOnBoarding = [select id from RecordType where name='IM Employees Support Case' LIMIT 1];
        ID caseRecordTypeOnBoarding =  DataFactory.getRecordTypeId('Case','IM Employees Support Case');
        //RecordType caseRecordType = [select id from RecordType where name='IME SC Case' LIMIT 1]; 
        ID caseRecordType =  DataFactory.getRecordTypeId('Case','IME SC Case');
        
        User ManagerUser = DataFactory.createUsersLst(1)[0];
        ManagerUser.Country='United Kingdom';
        Profile sysAdmin = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
        
     /*   User ManagerUser = new User(FirstName = 'Test', LastName = 'User', ProfileId = sysAdmin.Id, ManagerId = null,
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestUser1@support.com', Email = 'testUser@support.com',
                              Alias = 'tUse', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwn1',
                              LocaleSidKey = 'en_US', Country='FRANCE');
                              
        User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia'); 
                              */                     
        User currentUser = new User ( Id = UserInfo.getUserId() );                     
        System.runAs(currentUser)
        {
            List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
            List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
            for(Trigger_Activation_Settings__c cs : customsettings){
              if(cs.Object__c == 'Case') {
                 cs.Value__c='True';
                 updatesettings.add(cs);
              }
            }
        update updatesettings;
            
         //Creation of Account
           Account testAccount = new Account(Name='Test Account');
           insert testAccount;
            
           //Creation of Contact
           Contact caseContact = new Contact(FirstName = 'Test', LastName = 'User');
           insert caseContact;
           
           //Creation of IME_SC_Toggle_Country_Features
           IME_SC_Toggle_Country_Features__c ToggleCountryFtrs = new IME_SC_Toggle_Country_Features__c();
           ToggleCountryFtrs.Name='TestName';
           ToggleCountryFtrs.Feature_Name__c='On-boarding';
           ToggleCountryFtrs.Country__c='United Kingdom';
           ToggleCountryFtrs.Is_Active__c=True;
           insert ToggleCountryFtrs;
                     
           case testOnBoarding = new case();
           testOnBoarding.Status = 'New';
           testOnBoarding.RecordTypeId = caseRecordTypeOnBoarding;
           //testOnBoarding.RecordTypeId = caseRecordType.id;
           testOnBoarding.AccountID = testAccount.id;
           testOnBoarding.ContactID = caseContact.id; 
           testOnBoarding.IM_Employee_Contact__c = ManagerUser.id;
        //   testOnBoarding.IM_Employee_Contact__c = caseContact.Id;       
           testOnBoarding.IME_SC_Request_Type__c = 'Order';
           testOnBoarding.IME_SC_Country__c = 'United Kingdom';
           testOnBoarding.Subject = 'Test On Boarding 123'; 
           testOnBoarding.Related_To__c = 'Customer Account/Client Code';
           testOnBoarding.Issue__c = 'Account Set Up';
           testOnBoarding.IME_SC_Number_of_Line_Items__c = 1;
           testOnBoarding.IM_Division__c = 'IME';
           //insert testCaseHalfDay;
           //testCases.add(testOnBoarding); 
           insert testOnBoarding;
           
           
           
           testOnBoarding.Subject = 'Test On Boarding 1234';
           testOnBoarding.Description = 'Test Description';
           testOnBoarding.Origin='GBR_EMAIL_ORDERS';
           testOnBoarding.IME_SC_Category__c='Complaints';
           testOnBoarding.IME_SC_Sub_Category__c='Account Closure';
           testOnBoarding.IME_SC_Country__c = 'United Kingdom';
           testOnBoarding.Status = 'Closed';
           testOnBoarding.IM_Division__c = 'IME';
           testOnBoarding.RecordTypeId = caseRecordType;
           testOnBoarding.IME_SC_Order_Id__c='Test123';
            
           testOnBoarding.IME_SC_Closure_Reason__c='Completed';
           update testOnBoarding;
           
        /*   testOnBoarding.RecordTypeId = caseRecordType;
           testOnBoarding.IME_SC_Case_Cause__c = 'IT';
           update testOnBoarding;
           */
           
           case case2 = new case();
           case2.Status = 'New';
           case2.RecordTypeId = caseRecordType;
           case2.AccountID = testAccount.id;
           case2.ContactID = caseContact.id; 
           case2.IM_Employee_Contact__c = ManagerUser.id;      
           case2.IME_SC_Request_Type__c = 'Order';
           case2.IME_SC_Country__c = 'United Kingdom';
           case2.Subject = 'Test Del 123'; 
           case2.Related_To__c = 'Customer Account/Client Code';
           case2.Issue__c = 'Account Set Up';
           case2.IME_SC_Number_of_Line_Items__c = 1;
           case2.IM_Division__c = 'IME';
           insert case2;
           
          
           
           Test.stopTest();   
        }
        
    }
}