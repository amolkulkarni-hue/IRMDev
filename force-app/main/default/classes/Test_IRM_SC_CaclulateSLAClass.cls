/************************
Developer Name: Venkateswarlu Avula
Case Number   : 01814315
Date          : 10/8/13
purpose       : Test Utility for IRM_SC_CaclulateSLAClass
***********************/
@isTest
private class Test_IRM_SC_CaclulateSLAClass {
    
    static testMethod void testCaclulateSLAClass() {
        
        List<Case> lstCase = new List<Case>();
        Map<id, Case> mapCase=new  Map<id, Case>();
    
        BusinessHours BH = [Select Name, Id, TimeZoneSidKey From BusinessHours where TimeZoneSidKey = 'Europe/Paris' LIMIT 1];
        Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
        UserRole CSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
        RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //User creation    
        User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
                                  LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/Paris',
                                  Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                                  Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                                  LocaleSidKey = 'en_US', Country='France',UserRoleId = CSRuser1.Id);
        
        System.runAs(Owner1)
        {
            //insert Account for Customer Account
            Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
            insert testAccount;
            
            //Creation of IM Country record
            IM_Country__c country = new IM_Country__c(Name = 'France');
            insert country;
            
            //Creation of Customer Account
            IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                         Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
            insert caseCustomerAccount;
            
            //Case Creation
            Case testCase = new Case();
            testCase.Origin = 'FRA_WEB';
            testCase.Status = 'New';
            testCase.IME_SC_Country__c = 'France';
            testCase.RecordTypeId = caseRecordType.id;
            testCase.BusinessHoursId = BH.id;
            testCase.IME_SC_Category__c= 'Order Enquiry';
            testCase.IME_SC_Sub_Category__c = 'Change an order';
            testCase.IME_SC_Request_Type__c = 'Order';
            testCase.IME_SC_Number_of_Line_Items__c = 1;
            testCase.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
            testCase.IME_SC_SLA_Hold_Time__c= null;
             insert testCase;
            
            Test.startTest();
            testCase.Status = 'In Progress';
            update testCase;
            
            
            
            testCase.Status = 'On Hold - Customer';
            update testCase;
            Test.stopTest();
            
            lstCase.add(testCase);
            
            //Case Creation
            Case testCase1 = new Case();
            testCase1.Origin = 'FRA_WEB';
            testCase1.Status = 'New';
            testCase1.IME_SC_Country__c = 'France';
            testCase1.RecordTypeId = caseRecordType.id;
            testCase1.BusinessHoursId = BH.id;
            testCase1.IME_SC_Category__c= 'Order Enquiry';
            testCase1.IME_SC_Sub_Category__c = 'Change an order';
            testCase1.IME_SC_Request_Type__c = 'Order';
            testCase1.IME_SC_Number_of_Line_Items__c = 1;
            testCase1.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
            lstCase.add(testCase1);
            
            Case testCase2 = new Case();
            testCase2.Origin = 'FRA_WEB';
            testCase2.Status = 'In Progress';
            testCase2.IME_SC_Country__c = 'United Kingdom';
            testCase2.RecordTypeId = caseRecordType.id;
            testCase2.BusinessHoursId = BH.id;
            testCase2.IME_SC_Category__c= 'Order Enquiry';
            testCase2.IME_SC_Sub_Category__c = 'Change an order';
            testCase2.IME_SC_Request_Type__c = 'Order';
            testCase2.IME_SC_Number_of_Line_Items__c = 1;
            testCase2.IME_SC_Customer_AccountId__c = caseCustomerAccount.id;
            lstCase.add(testCase2);
            
            upsert lstCase;
            
            mapCase.put(testCase.Id, testCase);
            mapCase.put(testCase1.Id, testCase1);
            mapCase.put(testCase2.Id, testCase2);
            
            IRM_SC_CaclulateSLAClass objSLAClass = new IRM_SC_CaclulateSLAClass();
            
            objSLAClass.setSLA(lstCase,mapCase);
            //objSLAClass.caseSLASelection(lstCase);
            //objSLAClass.SLACalculation
        }
      // TO DO: implement unit test
    }
 }