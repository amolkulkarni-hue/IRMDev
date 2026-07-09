/************************
Developer Name: Venkateswarlu Avula
Case Number   : 01814315
Date          : 10/8/13
purpose       : Test Utility for IRM_SC_AssignCasetoAccManager  class
***********************/

@isTest(seeAllData=true)
private class Test_IRM_SC_AssignCasetoAccManager
{
    static testMethod void testAssignCasetoAccManager()
    {
        Test.startTest();
        ID caseRecordType = DataFactory.getRecordTypeId('Case','IME SC Case');   
        User ManagerUser = DataFactory.createUsersLst(1)[0];
        List<Case> caseList = new List<Case>();
        List<IM_Customer_Account__c> custAccList = new List<IM_Customer_Account__c>();
        Group queue = [Select g.Name, g.Id From Group g where Name Like 'IME SC %queue%' LIMIT 1];
        
        GroupMember grpMember = new GroupMember (UserOrGroupId = ManagerUser.Id, GroupId = queue.Id);
        
        /*Profile sysAdmin = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
        UserRole CSRuser = [Select Name, Id From UserRole where Name LIKE '%CSR%' LIMIT 1];
        User ManagerUser = new User(FirstName = 'Test', LastName = 'User', ProfileId = sysAdmin.Id, ManagerId = null,
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestUser1@support.com', Email = 'testUser@support.com',
                              Alias = 'tUse', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwn1',
                              LocaleSidKey = 'en_US', Country='Australia');
                              
        insert ManagerUser;*/
        User currentUser = new User ( Id = UserInfo.getUserId() );
        System.runAs(currentUser)
        {
            //Creation of Account
            Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
            insert testAccount;
            
            
            //Creation of IM Country record
            IM_Country__c country = new IM_Country__c(Name = 'France');
            insert country;
            
            //Creation of Customer Account
            IM_Customer_Account__c caseCustomerAccount1 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = ManagerUser.Id, 
                                                         Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
            custAccList.add(caseCustomerAccount1);
            
                  
            insert custAccList;
            
            
            
            //insert Case
            Case newCase = new Case();
            newCase.Origin = 'AUS_EMAIL_NSW';
            newCase.OwnerId = queue.Id;
            newCase.RecordTypeId = caseRecordType;
            newCase.IME_SC_Category__c= 'Order Enquiry';
            newCase.IME_SC_Sub_Category__c = 'Change an order';
            newCase.IME_SC_Request_Type__c = 'Order';
            newCase.IME_SC_Number_of_Line_Items__c = 1;
            newCase.IME_SC_Customer_AccountId__c = caseCustomerAccount1.id;
            caseList.add(newCase);
            
            //insert case with Queue;
            Case newCaseQueue = new Case();
            newCaseQueue.Origin = 'AUS_EMAIL_NSW';
            newCaseQueue.OwnerId = queue.Id;
            newCaseQueue.Status = 'Validated';
            newCaseQueue.IME_SC_Country__c = 'Australia';
            newCaseQueue.RecordTypeId = caseRecordType;
            newCaseQueue.IME_SC_Category__c= 'Order Enquiry';
            newCaseQueue.IME_SC_Sub_Category__c = 'Change an order';
            newCaseQueue.IME_SC_Request_Type__c = 'Order';
            newCaseQueue.IME_SC_Number_of_Line_Items__c = 1;
            newCaseQueue.IME_SC_Customer_AccountId__c = caseCustomerAccount1.id;
            
            caseList.add(newCaseQueue);
            
             //insert Case
            Case newCase1 = new Case();
            newCase1.Origin = 'AUS_EMAIL_NSW';
            newCase1.OwnerId = queue.Id;
            newCase1.Status = 'Assigned';
            newCase1.RecordTypeId = caseRecordType;
            newCase1.IME_SC_Category__c= 'Order Enquiry';
            newCase1.IME_SC_Sub_Category__c = 'Change an order';
            newCase1.IME_SC_Request_Type__c = 'Order';
            newCase1.IME_SC_Number_of_Line_Items__c = 1;
            newCase1.IME_SC_Customer_AccountId__c = caseCustomerAccount1.id;
            caseList.add(newCase1);
          
          //insert Case
            Case newCase2 = new Case();
            newCase2.Origin = 'AUS_EMAIL_NSW';
            newCase2.OwnerId = queue.Id;
            newCase2.Status = 'Validated';
            newCase2.IME_SC_Country__c = 'Australia';
            newCase2.OwnerId = queue.Id;
            newCase2.RecordTypeId = caseRecordType;
            newCase2.IME_SC_Category__c= 'Order Enquiry';
            newCase2.IME_SC_Sub_Category__c = 'Change an order';
            newCase2.IME_SC_Request_Type__c = 'Order';
            newCase2.IME_SC_Number_of_Line_Items__c = 1;
            newCase2.IME_SC_Customer_AccountId__c = caseCustomerAccount1.id;
            caseList.add(newCase2);
            
            insert caseList;
            
            List<IME_SC_Toggle_Country_Features__c> toggleFeaturesCustomSetting = IME_SC_Toggle_Country_Features__c.getall().values();
            IRM_SC_AssignCaseToAccManager objAssCaseToAccMngr = new IRM_SC_AssignCaseToAccManager();
            System.runAs(ManagerUser)
            {
                objAssCaseToAccMngr.assignCaseToAccManager(caseList);
            }  
            Test.stopTest();
        }
    }
}