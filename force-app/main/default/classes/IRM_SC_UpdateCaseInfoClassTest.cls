/**  
       * Name            : IRM_SC_UpdateCaseInfoClassTest
       * Description     : Test class for IRM_SC_UpdateCaseInfoClass, IRM_SC_SelectRecordType, IRM_SC_AssignCaseToAccManager
       * Copyright       : HCL Technologies
       * Author          : Sejal Shah
       * Modification Log: Created:12-Mar-2012 
**/
@isTest
private class IRM_SC_UpdateCaseInfoClassTest {

    public static List<Case> getListOfCases() {
        ID recTypeId =  DataFactory.getRecordTypeId('Case','IME SC Case');
        List<Case> caseList = new List<Case>();
        
        User currentUser = new User(Id = UserInfo.getUserId());
        System.runAs(currentUser) {
            
            User ManagerUser = DataFactory.createUsersLst(1)[0];
            User manager_Manager = DataFactory.createUsersLst(1)[0];
            manager_Manager.ManagerId = ManagerUser.id;
            update manager_Manager;
            
            User manager = DataFactory.createUsersLst(1)[0];
            User Owner1 = DataFactory.createUsersLst(1)[0];
            Owner1.ManagerId = manager.Id;
            Update owner1;
        }
     Contact caseContact = new Contact(FirstName = 'Dummy1111', LastName = 'Contact1111',Phone='789',email='invalid1111@ironmountain.com');
        insert caseContact;
        
        // Fetch the queue (Group)
        Group queue = [Select g.Name, g.Id From Group g where Name Like 'IME SC %queue%' LIMIT 1];
        
        // Insert Case records
        Case newCase = new Case();
        newCase.Origin = 'AUS_EMAIL_NSW';
        newCase.RecordTypeId = recTypeId;
        newCase.IME_SC_Category__c = 'Order Enquiry';
        newCase.IME_SC_Sub_Category__c = 'Change an order';
        newCase.IME_SC_Request_Type__c = 'Order';
        newCase.IME_SC_Number_of_Line_Items__c = 1;
        newCase.OwnerId = currentUser.id;
        newCase.status='Assigned';
        caseList.add(newCase);
        
        Case newCase1 = new Case();
        newCase1.Origin = 'AUS_EMAIL_NSW';
        newCase1.OwnerId = currentUser.id; 
        newCase1.Status = 'Validated';
        newCase1.IME_SC_Country__c = 'Australia';
        newCase1.RecordTypeId = recTypeId;
        newCase1.IME_SC_Category__c = 'Order Enquiry';
        newCase1.IME_SC_Sub_Category__c = 'Change an order';
        newCase1.IME_SC_Request_Type__c = 'Order';
        newCase1.IME_SC_Number_of_Line_Items__c = 1;
        caseList.add(newCase1);

        Case newCaseQueue = new Case();
        newCaseQueue.Origin = 'AUS_EMAIL_NSW';
        newCaseQueue.OwnerId = queue.Id; // Assign to queue (Group)
        newCaseQueue.Status = 'Validated';
        newCaseQueue.IME_SC_Country__c = 'Australia';
        newCaseQueue.RecordTypeId = recTypeId;
        newCaseQueue.IME_SC_Category__c = 'Order Enquiry';
        newCaseQueue.IME_SC_Sub_Category__c = 'Change an order';
        newCaseQueue.IME_SC_Request_Type__c = 'Order';
        newCaseQueue.IME_SC_Number_of_Line_Items__c = 1;
        caseList.add(newCaseQueue);
        return caseList;
    }

    @isTest
    public static void testPopulateUsers() {
        List<Case> caseList = getListOfCases();
        IRM_SC_UpdateCaseInfoClass updateClass = new IRM_SC_UpdateCaseInfoClass();
        
        Test.startTest();
        updateClass.populateUsers(caseList);
        Test.stopTest();
    }

    @isTest
    public static void testUpdateStatus() {
        List<Case> caseList = getListOfCases();
        Map<Id, Case> oldCaseMap = new Map<Id, Case>();
        
        for (Case c : caseList) {
            oldCaseMap.put(c.Id, c);
        }
        
        IRM_SC_UpdateCaseInfoClass updateClass = new IRM_SC_UpdateCaseInfoClass();
        
        Test.startTest();
        updateClass.updateStatus(caseList, oldCaseMap);
        Test.stopTest();
        
    } 
    // Test queue assignment and status update in the queue
    @isTest
public static void testQueueHandling() {
    List<Case> caseList = getListOfCases();
    insert caseList;
    for (Case c : caseList) {
         if (String.valueOf(c.OwnerId).startsWith('00G')) { // Check if it's assigned to a queue (Group)
            System.assertEquals('Validated', c.Status);
        }
    }
}
    
@isTest
   public static void testPopulateRequestType() {
           IME_SC_RequestType__c requestType = new IME_SC_RequestType__c(
            Name = 'Test Request Type',
            IME_SC_Category__c = 'Hardware',
            IME_SC_SubCategory__c = 'Laptop'
        );
        insert requestType;

        Test.startTest();
        Map<String, IME_SC_RequestType__c> allRequestTypes = new Map<String, IME_SC_RequestType__c>();
        allRequestTypes.put(requestType.Name, requestType);
       
       Contact testContact = new Contact(LastName = 'Test', Email = 'test@example.com');
       insert testContact;

       Case oldCase = new Case(
            Subject = 'Old case',
            IME_SC_Category__c = 'Hardware',
            IME_SC_Sub_Category__c = 'Desktop',
            IME_SC_Request_Type__c = 'Order',
            ContactId = testContact.Id
        );
        insert oldCase;

        // New version of the Case with changed Sub Category
        Case newCase = new Case(
            Id = oldCase.Id,
            Subject = 'Updated Case',
            IME_SC_Category__c = 'Hardware',
            IME_SC_Sub_Category__c = 'Laptop',
            ContactId = testContact.Id
        );

        // Another new Case that has no match in RequestType list
        Case unmatchedCase = new Case(
            Subject = 'Unmatched',
            IME_SC_Category__c = 'Software',
            IME_SC_Sub_Category__c = 'Antivirus',
            ContactId = testContact.Id
        );

        // Case with blank category
        Case blankCase = new Case(
            Subject = 'Blank Category',
            IME_SC_Category__c = '',
            IME_SC_Sub_Category__c = '',
            ContactId = testContact.Id );

        List<Case> newCases = new List<Case>{ newCase, unmatchedCase, blankCase };
        Map<Id, Case> oldMap = new Map<Id, Case>{ oldCase.Id => oldCase };

        new IRM_SC_UpdateCaseInfoClass().populateRequestType(newCases, oldMap);
        Test.stopTest();
 }
    
@isTest
  public  static void testPopulateContactForEmailToCase() {
        
        // Step 1: Create test data for Contacts
        Contact contact1 = new Contact(
            LastName = 'Test1',
            Email = 'test@example.com',
            AccountId = null // assuming no Account related
        );
        insert contact1;
        
        Contact contact2 = new Contact(
            LastName = 'Test2',
            Email = 'test@example.com',
            AccountId = null // assuming no Account related
        );
        insert contact2;
      
      Contact contact3 = new Contact(
            LastName = 'Test3',
            Email = 'unique@example.com',
            AccountId = null // assuming no Account related
        );
        insert contact3;

      User user1 = new User(
            Alias = 'test1',
            Email = 't79879@example.com',
            ProfileId = UserInfo.getProfileId(), // Use a valid profile ID
            Username = '2025060998@example.com',
            LastName = 'Use791',
            FirstName = 'Test1',
            CompanyName = 'Test Company',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
          country='India'
        );
        insert user1;

        User user2 = new User(
            Alias = 'te26',
            Email = 'kjhjkh56r@example.com',
            ProfileId = UserInfo.getProfileId(), // Use a valid profile ID
            Username = 'T15430t798@example.comk',
            LastName = 'U68',
            FirstName = 'Te982',
            CompanyName = 'Test Company',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            country='India'
        );
        insert user2;

       // Step 2: Create test Case records with SuppliedEmail and no ContactId
        Case case1 = new Case(
            Subject = 'Case 1',
            SuppliedEmail = 'test@example.com',
            ContactId = null, 
            IM_Employee_Contact__c = user1.Id 
        );
        
        Case case2 = new Case(
            Subject = 'Case 2',
            SuppliedEmail = 'unique@example.com',
            ContactId = null, 
            IM_Employee_Contact__c = user2.Id 
        );
        
        Case case3 = new Case(
            Subject = 'Case 3 with no match',
            SuppliedEmail = 'no_match@example.com',
            ContactId = null, 
            IM_Employee_Contact__c = user2.Id 
        );

        List<Case> newCaseList = new List<Case>{ case1, case2, case3 };
        insert newCaseList;
 
        Test.startTest();
        new IRM_SC_UpdateCaseInfoClass().populateContactForEmailToCase(newCaseList);
        update newCaseList;
        Test.stopTest();
  } 
 }