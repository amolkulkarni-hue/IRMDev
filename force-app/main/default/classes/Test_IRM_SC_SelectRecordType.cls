/**  
       * Name            : Test_IRM_SC_SelectRecordType
       * Description     : Test class for IRM_SC_SelectRecordType related to case # 01814315
       * Developer       : Apurva Dutta
       * Modification Log: Created:08-OCT-2013 
**/

@istest
private class Test_IRM_SC_SelectRecordType{
    public static TestMethod List<Case> getListOfCases()
    {
        {
        RecordType caseRecordType = [select id from RecordType where name='IME SC Case'];    
        List<Case> caseList = new List<Case>();
        List<IM_Customer_Account__c> custAccList = new List<IM_Customer_Account__c>();
        //insert User List
        Profile sysAdmin = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
        UserRole CSRuser = [Select Name, Id From UserRole where Name LIKE '%CSR%' LIMIT 1];
        User ManagerUser = new User(FirstName = 'Test', LastName = 'User', ProfileId = sysAdmin.Id, ManagerId = null,
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestUser1@support.com', Email = 'testUser@support.com',
                              Alias = 'tUse', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwn1',
                              LocaleSidKey = 'en_US', Country='Australia');
        User manager_Manager = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin.Id,ManagerId=ManagerUser.Id,
                                              Username = 'TestManMan@support.com', Email = 'testManager_Manager@support.com',
                                              Alias = 'tUser', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tman',
                                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                                              LocaleSidKey = 'en_US', Country='Australia');
        User manager = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin.Id,ManagerId = manager_Manager.Id,
                                  LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                                  Username = 'TestMan@support.com', Email = 'testManager@support.com',
                                  Alias = 'tMan', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tman1',
                                      LocaleSidKey = 'en_US', Country='Australia');
        User Owner = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin.Id, ManagerId = manager.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia', UserRoleId = CSRuser.Id);
        /*List<User> userListToInsert = new List<User>();
        userListToInsert.add(manager_Manager);
        userListToInsert.add(manager);
        userListToInsert.add(Owner);
        userListToInsert.add(ManagerUser);*/
        //insert userListToInsert;
        
        //Creation of Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'France');
        insert country;
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount1 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount1);
        
        IM_Customer_Account__c caseCustomerAccount2 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount2);
        
        IM_Customer_Account__c caseCustomerAccount3 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount3);
        
        IM_Customer_Account__c caseCustomerAccount4 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = Owner.Id, 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        custAccList.add(caseCustomerAccount4);
        
        insert custAccList;
        
        Group queue = [Select g.Name, g.Id From Group g where Name Like 'IME SC %queue%' LIMIT 1];
        system.debug('Queue: '+queue);
        
        GroupMember grpMember = new GroupMember (UserOrGroupId = manager.Id, GroupId = queue.Id);
        //insert grpMember;
        
        //insert Case
        Case newCase = new Case();
        newCase.Origin = 'AUS_EMAIL_NSW';
        newCase.RecordTypeId = caseRecordType.id;
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
        newCaseQueue.RecordTypeId = caseRecordType.id;
        newCaseQueue.IME_SC_Category__c= 'Order Enquiry';
        newCaseQueue.IME_SC_Sub_Category__c = 'Change an order';
        newCaseQueue.IME_SC_Request_Type__c = 'Order';
        newCaseQueue.IME_SC_Number_of_Line_Items__c = 1;
        newCaseQueue.IME_SC_Customer_AccountId__c = caseCustomerAccount2.id;
        caseList.add(newCaseQueue);
        
        //insert Case
        Case newCase1 = new Case();
        newCase1.Origin = 'AUS_EMAIL_NSW';
        newCase1.Status = 'Assigned';
        newCase1.RecordTypeId = caseRecordType.id;
        newCase1.IME_SC_Category__c= 'Order Enquiry';
        newCase1.IME_SC_Sub_Category__c = 'Change an order';
        newCase1.IME_SC_Request_Type__c = 'Order';
        newCase1.IME_SC_Number_of_Line_Items__c = 1;
        newCase1.IME_SC_Customer_AccountId__c = caseCustomerAccount3.id;
        caseList.add(newCase1);
      
      //insert Case
        Case newCase2 = new Case();
        newCase2.Origin = 'AUS_EMAIL_NSW';
        newCase2.Status = 'Validated';
        newCase2.IME_SC_Country__c = 'Australia';
        newCase2.OwnerId = queue.Id;
        newCase2.RecordTypeId = caseRecordType.id;
        newCase2.IME_SC_Category__c= 'Order Enquiry';
        newCase2.IME_SC_Sub_Category__c = 'Change an order';
        newCase2.IME_SC_Request_Type__c = 'Order';
        newCase2.IME_SC_Number_of_Line_Items__c = 1;
        newCase2.IME_SC_Customer_AccountId__c = caseCustomerAccount4.id;
        caseList.add(newCase2);
        system.debug('+++++++++++++++++testing+++++++++++++++');
        custAccList.clear();
        return caseList;
        
        
    }
}

static testMethod void testCaseOwnerAsUser() {
        
    Test.startTest();
    Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
    UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
    RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
     
    //User creation    
    User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia', UserRoleId = CSRuser1.Id);
    
    List<Case> caseList;
    System.runAs(Owner1)
    {
        caseList = getListOfCases();
        insert caseList;
        //update caseList;
    }
  /*  
    System.runAs(Owner1)
    {
        update caseList;
    }*/
    Test.stopTest();
          // TO DO: implement unit test
  }
}