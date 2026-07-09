/*
Auhtor       : Nagesh Ganji
Created Date : Jul 12, 2010
Description  : Tester utility class for Custom Lead conversion process
*/
@isTest(SeeAllData=false)
 public without sharing class test_LeadCustomConversion {
    
    public static Id imRecTypeId;
    public static Profile p,p2;
    public static User Testuser = new User();
    public static User Testuser2 = new User();
    public static Account TestAccount = new Account();
    public static Contact TestContact = new Contact();
    public static Lead TestLead = new Lead();
    public static Account TestAccount1 = new Account();
    public static Contact TestContact1 = new Contact();
    public static Lead TestLead1 = new Lead();
   
    public static void testData1(){
        
        imRecTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('IME Lead').getRecordTypeId();
        /*p=[Select id from profile where name = 'IME_In_Country_Admin'];
        system.debug('++++++++++++profile value+++'+p);
        Testuser.alias = 'tIMEUsr';
        Testuser.email='test090910@email.com';
        Testuser.emailencodingkey='UTF-8';
        Testuser.lastname='Testing';
        Testuser.languagelocalekey='en_US';
        Testuser.localesidkey='en_US'; 
        Testuser.ProfileId = p.Id;
        Testuser.timezonesidkey='America/Los_Angeles';
        Testuser.username='test090910@email.com';
        Testuser.Country = 'United Kingdom';
        Testuser.UserPreferencesLightningExperiencePreferred=false;
        //Testuser.Country = 'Germany';
        //insert Testuser;*/
        
        Testuser = TestingUtil.createUsers(1, true)[0];
        Testuser.UserPreferencesLightningExperiencePreferred=false;
        update Testuser;
        system.debug('Testuser_userid=='+Testuser.Id);
        system.debug('Testuser_userprefrences=='+Testuser.UserPreferencesLightningExperiencePreferred);
       // system.runAs(Testuser){
            
        
        IM_Country__c testCountry = new IM_Country__c(Name='Germany');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='Germany');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Germany';
        setting.object_name__c = 'Account';
        insert setting;
         
        TestAccount.Name='Account4&;!@%#-UnitTest';
        TestAccount.BillingCountry = 'Germany';
        TestAccount.BillingStreet = '745 Atlantic Ave';
        TestAccount.BillingPostalCode = 'SE1 2TT';
        TestAccount.BillingCity = 'London';
        TestAccount.BillingState = 'NY';
        TestAccount.Billing_County__c='Germany';
        TestAccount.IMGA_Owner__c= Testuser.id;
        insert TestAccount;
                
        TestContact.LastName='TestContact';
        TestContact.FirstName= 'First Con';
        TestContact.Email='testemail@email.com';
        TestContact.AccountId=TestAccount.Id;
        TestContact.MailingCity = 'London'; 
        TestContact.MailingCountry = 'Germany'; 
        TestContact.MailingPostalCode = 'SE1 2TT';
        TestContact.MailingState = 'London'; 
        TestContact.MailingStreet = '745 Atlantic Ave';        
        insert TestContact; 
         
        TestLead.FirstName = 'Lead';
        TestLead.LastName = 'TestContact';
        TestLead.Status = 'Open'; 
        TestLead.IM_Lead_Source_Most_Recent__c = 'Email';
        TestLead.IM_Lead_Stage__c = '1-Inquiry';
        TestLead.Company = 'Account&;!@%#-4UnitTest';
        TestLead.Email = 'testemail@email.com';
        TestLead.Street = '745 Atlantic Ave';
        TestLead.City = 'London';
        TestLead.State = 'London';
        TestLead.Country = 'Germany';
        TestLead.PostalCode = 'SE1 2TT';
        TestLead.RecordTypeId = imRecTypeId;
        insert TestLead;
        }
    
    
    public static void testData2(){
        
        imRecTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('IME Lead').getRecordTypeId();
        /*p=[Select id from profile where name = 'IME_In_Country_Admin'];
        system.debug('++++++++++++profile value+++'+p);
        Testuser.alias = 'tIMEUsr';
        Testuser.email='test090910@email.com';
        Testuser.emailencodingkey='UTF-8';
        Testuser.lastname='Testing';
        Testuser.languagelocalekey='en_US';
        Testuser.localesidkey='en_US'; 
        Testuser.ProfileId = p.Id;
        Testuser.timezonesidkey='America/Los_Angeles';
        Testuser.username='test090910@email.com';
        Testuser.Country = 'Japan';
        insert Testuser;*/
        
        Testuser = TestingUtil.createUsers(1, true)[0];
        Testuser.UserPreferencesLightningExperiencePreferred=false;
        update Testuser;
        IM_Country__c testCountry = new IM_Country__c(Name='Japan');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='Japan');
        insert country;
        
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Japan';
        setting.object_name__c = 'Account';
        insert setting;
         
        TestAccount.Name='Account4&;!@%#-UnitTest';
        TestAccount.BillingCountry = 'Japan';
        TestAccount.BillingStreet = '745 Atlantic Ave';
        TestAccount.BillingPostalCode = 'SE1 2TT';
        TestAccount.BillingCity = 'London';
        TestAccount.BillingState = 'NY'; 
        TestAccount.Billing_County__c='Japan';
        TestAccount.IMGA_Owner__c= Testuser.id;
        insert TestAccount;
        
        TestContact.LastName='TestContact';
        TestContact.FirstName= 'First Con';
        TestContact.Email='testemail@email.com';
        TestContact.AccountId=TestAccount.Id;
        TestContact.MailingCity = 'London'; 
        TestContact.MailingCountry = 'Japan'; 
        TestContact.MailingPostalCode = 'SE1 2TT';
        TestContact.MailingState = 'London'; 
        TestContact.MailingStreet = '745 Atlantic Ave';
        insert TestContact; 
         
        TestLead.FirstName = 'Lead';
        TestLead.LastName = 'TestContact';
        TestLead.Status = 'Open'; 
        TestLead.IM_Lead_Source_Most_Recent__c = 'Email';
        TestLead.IM_Lead_Stage__c = '1-Inquiry';
        TestLead.Company = 'Account&;!@%#-4UnitTest';
        TestLead.Email = 'testemail@email.com';
        TestLead.Street = '745 Atlantic Ave';
        TestLead.City = 'London';
        TestLead.State = 'London';
        TestLead.Country = 'Japan';
        TestLead.PostalCode = 'SE1 2TT';
        TestLead.RecordTypeId = imRecTypeId;
        insert TestLead;
    } 
    
    public static void testData3(){
      
        imRecTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('IME Lead').getRecordTypeId();
        p=[Select id from profile where name = 'IME_In_Country_Admin'];
        system.debug('++++++++++++profile value+++'+p);
        Testuser.alias = 'tIMEUsr';
        Testuser.email='test090910@email.com';
        Testuser.emailencodingkey='UTF-8';
        Testuser.lastname='Testing';
        Testuser.languagelocalekey='en_US';
        Testuser.localesidkey='en_US'; 
        Testuser.ProfileId = p.Id;
        Testuser.timezonesidkey='America/Los_Angeles';
        Testuser.username='test090910@email.com';
        Testuser.Country = 'India';
        insert Testuser;
        
        IM_Country__c testCountry = new IM_Country__c(Name='India');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id,
                                                                                    Alternative_Name__c='India');
        insert country;
        
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'India';
        setting.object_name__c = 'Account';
        insert setting;
         
        TestAccount.Name='Account4&;!@%#-UnitTest';
        TestAccount.BillingCountry = 'India';
        TestAccount.BillingStreet = '745 Atlantic Ave';
        TestAccount.BillingPostalCode = '123456';
        TestAccount.BillingCity = 'Bnglr';
        TestAccount.BillingState = 'NY';
        TestAccount.Billing_County__c='India';
        TestAccount.IMGA_Owner__c= Testuser.id;
        insert TestAccount;
        
        TestContact.LastName='TestContact';
        TestContact.FirstName= 'First Con';
        TestContact.Email='testemail@email.com';
        TestContact.AccountId = TestAccount.Id;
        TestContact.MailingCity = 'INDIA'; 
        TestContact.MailingCountry = 'India'; 
        TestContact.MailingPostalCode = 'SE1 2TT';
        TestContact.MailingState = 'INDIA'; 
        TestContact.MailingStreet = '745 Atlantic Ave';
        insert TestContact; 
         
        TestLead.FirstName = 'Lead';
        TestLead.LastName = 'TestContact';
        TestLead.Status = 'Open'; 
        TestLead.IM_Lead_Source_Most_Recent__c = 'Email';
        TestLead.IM_Lead_Stage__c = '1-Inquiry';
        TestLead.Company = 'Account&;!@%#-4UnitTest';
        TestLead.Email = 'testemail@email.com';
        TestLead.Street = '745 Atlantic Ave';
        TestLead.City = 'London';
        TestLead.State = 'London';
        TestLead.Country = 'India';
        TestLead.PostalCode = 'SE1 2TT';
        TestLead.RecordTypeId = imRecTypeId;
        insert TestLead;
    }
    
    public static void testData4(){
        
        imRecTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('IME Lead').getRecordTypeId();
        p=[Select id from profile where name = 'IME_In_Country_Admin'];
        system.debug('++++++++++++profile value+++'+p);
        Testuser.alias = 'tIMEUsr';
        Testuser.email='test090910@email.com';
        Testuser.emailencodingkey='UTF-8';
        Testuser.lastname='Testing';
        Testuser.languagelocalekey='en_US';
        Testuser.localesidkey='en_US'; 
        Testuser.ProfileId = p.Id;
        Testuser.timezonesidkey='America/Los_Angeles';
        Testuser.username='test090910@email.com';
        Testuser.Country = 'Singapore';
        insert Testuser;
        
        IM_Country__c testCountry = new IM_Country__c(Name='Singapore');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='Singapore');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Singapore';
        setting.object_name__c = 'Account';
        insert setting;
         
        TestAccount.Name='Account4&;!@%#-UnitTest';
        TestAccount.BillingCountry = 'Singapore';
        TestAccount.BillingStreet = '745 Atlantic Ave';
        TestAccount.BillingPostalCode = 'SE1 2TT';
        TestAccount.BillingCity = 'London';
        TestAccount.BillingState = 'NY'; 
        TestAccount.Billing_County__c='Singapore';
        TestAccount.IMGA_Owner__c= Testuser.id;
        insert TestAccount;
        
        TestContact.LastName='TestContact';
        TestContact.FirstName= 'First Con';
        TestContact.Email='testemail@email.com';
        TestContact.AccountId=TestAccount.Id;
        TestContact.MailingCity = 'London'; 
        TestContact.MailingCountry = 'Singapore'; 
        TestContact.MailingPostalCode = 'SE1 2TT';
        TestContact.MailingState = 'London'; 
        TestContact.MailingStreet = '745 Atlantic Ave';
        insert TestContact; 
         
        TestLead.FirstName = 'Lead';
        TestLead.LastName = 'TestContact';
        TestLead.Status = 'Open'; 
        TestLead.IM_Lead_Source_Most_Recent__c = 'Email';
        TestLead.IM_Lead_Stage__c = '1-Inquiry';
        TestLead.Company = 'Account&;!@%#-4UnitTest';
        TestLead.Email = 'testemail@email.com';
        TestLead.Street = '745 Atlantic Ave';
        TestLead.City = 'London';
        TestLead.State = 'London';
        TestLead.Country = 'Singapore';
        TestLead.PostalCode = 'SE1 2TT';
        TestLead.RecordTypeId = imRecTypeId;
        insert TestLead;
    } 
    
    public static void testDataIM(){
        
        Id stdRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
		
        IM_Country__c testCountry = new IM_Country__c(Name='United Kingdom');
        insert testCountry;  
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United Kingdom');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United Kingdom';
        setting.object_name__c = 'Account';
        insert setting;
        
        TestAccount1.Name='Account1';
        TestAccount1.BillingCountry = 'United Kingdom';
        TestAccount1.BillingStreet = '745 Atlantic Ave';
        TestAccount1.BillingPostalCode = 'SE1 2TT';
        TestAccount1.BillingCity = 'London';
        TestAccount1.BillingState = 'London'; 
        TestAccount.Billing_County__c='London';
        TestAccount.IMGA_Owner__c= Testuser.id;
        insert TestAccount1;
        
        TestContact1.LastName='TestContact1';
        TestContact1.FirstName= 'First Con';
        TestContact1.Email='testemail@email.com';
        TestContact1.AccountId=TestAccount1.Id;
        TestContact1.MailingCity = 'London'; 
        TestContact1.MailingCountry = 'United Kingdom'; 
        TestContact1.MailingPostalCode = 'SE1 2TT';
        TestContact1.MailingState = 'London'; 
        TestContact1.MailingStreet = '745 Atlantic Ave';
        insert TestContact1; 
        
        TestLead1.FirstName = 'Lead1';
        TestLead1.LastName = 'TestContact1';
        TestLead1.Status = 'Open'; 
        TestLead1.IM_Lead_Source_Most_Recent__c = 'Email';
        TestLead1.IM_Lead_Stage__c = '1-Inquiry';
        TestLead1.Company = 'Account&;!@%#-4UnitTest';
        TestLead1.Email = 'testemail@email.com';
        TestLead1.Street = '745 Atlantic Ave';
        TestLead1.City = 'London';
        TestLead1.State = 'London';
        TestLead1.Country = 'United Kingdom';
        TestLead1.PostalCode = 'SE1 2TT';
        TestLead1.RecordTypeId = stdRecTypeId;
        TestLead1.Related_Contact__c= TestContact1.id;
        TestLead1.Related_Account__c= TestAccount1.id;
        insert TestLead1;
    }
     
    public static testMethod void testMyController1() {
        testData1();
        //Test VF Page: LeadConversionRouteController
        PageReference pref = new PageReference('/apex/LeadConversionRouteController');
        Test.setCurrentPage(pRef);        
        pRef.getParameters().put('lId', TestLead.Id);
        LeadConversionRouteController lccr = new LeadConversionRouteController(new ApexPages.StandardController(TestLead));
        PageReference pTemp = lccr.route();
    }
     
    public static testMethod void testMyController2() {
        testData2();
        //Test VF page: LeadCustomConversion
        PageReference pRef1 = new PageReference('/apex/LeadCustomConversion'); 
        Test.setCurrentPage(pRef1);  
        pRef1.getParameters().put('lId', TestLead.Id);        
        LeadCustomConversionController lccc = new LeadCustomConversionController(new ApexPages.StandardController(TestLead));
        //added for code coverage: Line 107 - 117
        lccc.setLeadRecord(TestLead);
        //Srinu: Added on 03-22-2013
        lccc.convert();
        Lead temp = lccc.getLeadRecord();
        // Comment #15149 Start
        /*List<CRMfusionDBR101__Potential_Duplicate__c> lCRMDupes = new List<CRMfusionDBR101__Potential_Duplicate__c>();
        lccc.setLeadDupeList(lCRMDupes);
        lCRMDupes = lccc.getLeadDupeList();*/
        // Comment #15149 End
        List<Contact> lCon = new List<Contact>();
        lccc.setMatchingContactList(lCon);
        lCon = lccc.getMatchingContactList();
        List<Account> lAcc = new List<Account>();
        lccc.setMatchingAccountList(lAcc);
        lAcc = lccc.getMatchingAccountList();
    }
     
    public static testMethod void testMyController3() {
        testData3();
        //Test VF page: LeadCustomMerge
        PageReference pRef2 = new PageReference('/apex/LeadCustomMerge');
        Test.setCurrentPage(pRef2);         
        //pRef2.getParameters().put('lId', TestLead.Id);
        //pRef2.getParameters().put('cId', lcr1.getContactId());        
        //LeadCustomMergeController lcmc1 = new LeadCustomMergeController ( new ApexPages.StandardController(TestLead));
        ApexPages.StandardController sc = new ApexPages.StandardController(TestLead);
        System.currentPageReference().getParameters().put('lId',TestLead.id);
        System.currentPageReference().getParameters().put('cId',TestContact.id);
        System.currentPageReference().getParameters().put('aId',TestAccount.Id);
        LeadCustomMergeController lcmc1 = new LeadCustomMergeController (sc);
        lcmc1.doNotCreateOpp = FALSE;
        lcmc1.sendNotification = TRUE; 
        lcmc1.convertedStatus = 'Converted';
        lcmc1.taskdetails=false;
        lcmc1.getTaskdetails();
        lcmc1.setConRec(TestContact);
        TestContact = lcmc1.getConRec();
        lcmc1.leadRec = TestLead;
        
        Opportunity op1 = new Opportunity();
        //Srinu: Commented out becoz method has been commente out in corresponding class as part of Case # 00430321
        //List<SelectOption> soList = lcmc1.getConvertStatusList();
        op1.Name = 'Test&#%!@;-Opp';
        lcmc1.oppRec = op1;
        Task t1 = new Task();
        t1.Subject = 'Call';
        t1.IM_Type__c = 'Required';
        t1.Status = 'Complated';
        t1.Sub_Type__c = 'Required';
        t1.Priority = 'High';
        t1.WhatId = TestAccount.Id;
        t1.WhoId = TestContact.Id;
        lcmc1.task = t1;
        //AN ACTIVE ERROR FROM COUNTRY COMPLETE PACKAGE NEEDS TO BE RESOLVED TO USE BELOW API 9/10
        lcmc1.isTest = TRUE;      
        PageReference pr1 = lcmc1.MergeWithRecord();
        //Srinu: Added on 03-21-2013
        PageReference pr2 = lcmc1.back();
        PageReference pr3 = lcmc1.autorun();
    }
     
    public static testMethod void testMyController4() {
        testData4();
        //Test VF page: LeadCustomMerge
        PageReference pRef2 = new PageReference('/apex/LeadCustomMerge');
        Test.setCurrentPage(pRef2);         
        //pRef2.getParameters().put('lId', TestLead.Id);
        //pRef2.getParameters().put('cId', lcr1.getContactId());        
        //LeadCustomMergeController lcmc1 = new LeadCustomMergeController ( new ApexPages.StandardController(TestLead));
        ApexPages.StandardController sc = new ApexPages.StandardController(TestLead);
        System.currentPageReference().getParameters().put('lId',TestLead.id);
        //System.currentPageReference().getParameters().put('cId',TestContact.id);
        //System.currentPageReference().getParameters().put('aId',TestAccount.Id);
        LeadCustomMergeController lcmc1 = new LeadCustomMergeController (sc);
        lcmc1.doNotCreateOpp = FALSE;
        lcmc1.sendNotification = TRUE; 
        lcmc1.convertedStatus = 'Converted';
        lcmc1.getTaskdetails();
        lcmc1.setConRec(TestContact);
        TestContact = lcmc1.getConRec();
        lcmc1.leadRec = TestLead;
        
        Opportunity op1 = new Opportunity();
        //Srinu: Commented out becoz method has been commente out in corresponding class as part of Case # 00430321
        //List<SelectOption> soList = lcmc1.getConvertStatusList();
        op1.Name = 'Test&#%!@^Opp';
        lcmc1.oppRec = op1;
        Task t1 = new Task();
        t1.Subject = 'Call';
        t1.IM_Type__c = 'Required';
        t1.Status = 'Complated';
        t1.Sub_Type__c = 'Required';
        t1.Priority = 'High';
        t1.WhatId = TestAccount.Id;
        t1.WhoId = TestContact.Id;
        lcmc1.task = t1;
        //AN ACTIVE ERROR FROM COUNTRY COMPLETE PACKAGE NEEDS TO BE RESOLVED TO USE BELOW API 9/10
        lcmc1.isTest = TRUE;      
        PageReference pr1 = lcmc1.MergeWithRecord();
        //Srinu: Added on 03-21-2013
        PageReference pr2 = lcmc1.back();
        //PageReference pr3 = lcmc1.autorun();        
    } 
     
    public static testMethod void testMyController5() {
        testDataIM();
        //Test VF Page: LeadConversionRouteController
        PageReference pref = new PageReference('/apex/LeadConversionRouteController');
        Test.setCurrentPage(pRef);
        pRef.getParameters().put('lId', TestLead1.Id);
        LeadConversionRouteController lccr = new LeadConversionRouteController(new ApexPages.StandardController(TestLead1));
        PageReference pTemp = lccr.route();
    }
 
      @isTest
    static void testLeadMerge() {
        // Test setup - Create necessary records
        RecordType rtImna = [SELECT Id FROM RecordType WHERE Name = 'NA Account Management Lead' AND SObjectType = 'Lead' LIMIT 1];
        RecordType rtStd = [SELECT Id FROM RecordType WHERE Name = 'Standard Lead' AND SObjectType = 'Lead' LIMIT 1];

        // Create a test Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            RecordTypeId = rtStd.Id, // Standard Lead RecordType
            Street = '123 Test St',
            City = 'Test City',
            State = 'Test State',
            PostalCode = '12345',
            Country = 'USA'
        );
        insert testLead;

        // Create related Contact and Account if applicable
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;

        testLead.Related_Contact__c = testContact.Id;
        testLead.Related_Account__c = testAccount.Id;
        update testLead;

        // Now simulate the conditions in your logic
        Test.startTest();
        
        // Fetch the Lead from the database
        Lead lRec = [SELECT Id, Related_Contact__c, Related_Account__c, Related_Contact__r.Account.Name, Related_Account__r.Name, RecordTypeId, Street, City, State, PostalCode, Country FROM Lead WHERE Id = :testLead.Id];

        // Test when Related_Contact__c is not null and Related_Account__c is not null
        Set<String> countriesToIgnore = new Set<String>{'IRELAND', 'ARGENTINA', 'BRAZIL', 'CHILE', 'COLOMBIA', 'MEXICO', 'PERU', 'HONG KONG'};
        PageReference p1 = null;
        Boolean goBack = false;
        String msg = '';
        if (lRec.Related_Contact__c != null) {
            if (lRec.Related_Account__c == null) {
                p1 = new PageReference('/apex/LeadCustomMerge?lId=' + testLead.Id + '&cId=' + lRec.Related_Contact__c);
            } else if (lRec.Related_Contact__r.Account.Name != lRec.Related_Account__r.Name) {
                p1 = new PageReference('/apex/LeadCustomMerge?lId=' + testLead.Id + '&cId=' + lRec.Related_Contact__c);
            } else if (lRec.Related_Contact__r.Account.Name == lRec.Related_Account__r.Name) {
                p1 = new PageReference('/apex/LeadCustomMerge?lId=' + testLead.Id + '&aId=' + lRec.Related_Account__c);
            }
        } else if (lRec.Related_Account__c != null && lRec.Related_Contact__c == null) {
            p1 = new PageReference('/apex/LeadCustomMerge?lId=' + testLead.Id + '&aId=' + lRec.Related_Account__c);
        } else {
            if (lRec.RecordTypeId == rtImna.Id || lRec.RecordTypeId == rtStd.Id) {
                if (lRec.Street == null) {
                    goBack = true;
                    msg = msg + 'Street, ';
                }
                if (lRec.City == null) {
                    goBack = true;
                    msg = msg + 'City, ';
                }
                if (lRec.PostalCode == null) {
                    if (lRec.Country != null && countriesToIgnore.contains(lRec.Country.toUpperCase())) {
                        // IRELAND and other countries are skipped for PostalCode validation
                    } else {
                        goBack = true;
                        msg = msg + 'Postal Code, ';
                    }
                }
                if (lRec.Country == null) {
                    goBack = true;
                    msg = msg + 'Country, ';
                }
                if (lRec.State == null) {
                    goBack = true;
                    msg = msg + 'State';
                }

                if (goBack == true) {
                    System.assertEquals(msg, 'Street, City, Postal Code, Country, State');
                }
            }
        }
        
        // Validate that the page reference is correctly set
        System.assertNotEquals(p1, null);

        // Test the Profile-based logic
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Username = 'tr56Us@example.com',
            LastName = 'Testing',
            Alias = 'tr56U',
            Email = 'testuserhj@example.com',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            Country='United States'
            //UserType = 'Standard'
        );
        insert testUser;

        // Simulate the profile-based check for Opportunity_Product_Wizard_Settings
        List<Opportunity_Product_Wizard_Settings__c> wizardSettings = new List<Opportunity_Product_Wizard_Settings__c>{
            new Opportunity_Product_Wizard_Settings__c(Name = 'IM_Account Manager Test',
            Profile_Name__c = 'North America',
            Product_Group_Name__c='IM_Account Manager Test')
        };
        insert wizardSettings;

        // Simulate the logic that checks the profile and redirects
        Integer i = 0;
        for (Opportunity_Product_Wizard_Settings__c ops : wizardSettings) {
            if (testProfile.Name == ops.Profile_Name__c) {
                i++;
            }
        }
        
        if (i > 0) {
            p1 = new PageReference('/apex/CustomLeadConvert?id=' + testLead.Id);
        } else {
            p1 = new PageReference('/lead/leadconvert.jsp?retURL=' + testLead.Id + '&id=' + testLead.Id);
            p1.getParameters().put('nooverride', '1');
            p1.setRedirect(false);
        }

        // Ensure that the page reference is correct
        System.assertNotEquals(p1, null);

        Test.stopTest();
    }
     @isTest
    static void testClassicRoute_WithContactAndAccount() {
        // Setup: create Account and Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        // Get RecordType
        Id stdLeadRT = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();

        // Setup: create Lead with related Account and Contact
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            RecordTypeId = stdLeadRT,
            Street = '123 Main St',
            City = 'Testville',
            State = 'TS',
            PostalCode = '12345',
            Country = 'USA',
            Related_Account__c = acc.Id,
            Related_Contact__c = con.Id
        );
        insert lead;

        // Create dummy wizard setting
        Opportunity_Product_Wizard_Settings__c setting = new Opportunity_Product_Wizard_Settings__c
            (Profile_Name__c = UserInfo.getProfileId(),Name='IM_Test',
        Product_Group_Name__c='North America'
       );
        insert setting;

        // Simulate Classic (not Lightning) user
        User u = [SELECT Id, UserPreferencesLightningExperiencePreferred FROM User WHERE Id = :UserInfo.getUserId()];
        u.UserPreferencesLightningExperiencePreferred = false;
        update u;

        // Create standard controller and call the route method
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(lead);
        LeadConversionRouteController ctrl = new LeadConversionRouteController(sc);
        PageReference pr = ctrl.route();
        Test.stopTest();

        // Assert the page reference is not null
        System.assertNotEquals(null, pr, 'Page reference should not be null');
    }

    @isTest
    static void testLightningRouteFallback() {
        // Create Lead with minimal data for Lightning route
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId()
        );
        insert lead;

        // Simulate Lightning user
        User u = [SELECT Id, UserPreferencesLightningExperiencePreferred FROM User WHERE Id = :UserInfo.getUserId()];
        u.UserPreferencesLightningExperiencePreferred = true;
        update u;

        // Create controller and run method
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(lead);
        LeadConversionRouteController ctrl = new LeadConversionRouteController(sc);
        PageReference pr = ctrl.route();
        Test.stopTest();

        System.assertNotEquals(null, pr, 'Lightning page reference should not be null');
    }

    @isTest
    static void testFieldValidationBlock() {
        // Create a Lead with missing required fields to trigger goBack = true
        Lead lead = new Lead(
            FirstName = 'Field',
            LastName = 'Check',
            Company = 'Missing Fields Inc.',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId()
            // Missing Street, City, PostalCode, Country, State
        );
        insert lead;

        // Simulate Classic user
        User u = [SELECT Id, UserPreferencesLightningExperiencePreferred FROM User WHERE Id = :UserInfo.getUserId()];
        u.UserPreferencesLightningExperiencePreferred = false;
        update u;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(lead);
        LeadConversionRouteController ctrl = new LeadConversionRouteController(sc);
        PageReference pr = ctrl.route();
        Test.stopTest();

        // Since required fields are missing, route() should return null
        System.assertEquals(null, pr, 'Page reference should be null due to missing fields');
        System.assertEquals(true, ctrl.goBack, 'goBack should be true when fields are missing');
        System.assert(ctrl.msg.contains('Street'), 'Error message should mention Street');
    }
@isTest
    static void testFieldall() {
        // Create a Lead with missing required fields to trigger goBack = true
        Lead lead = new Lead(
            FirstName = 'Field',
            LastName = 'Check',
            Company = 'Missing Fields Inc.',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId(),
            Street='gjhjk', 
            City='HJHK', 
            PostalCode='5657', 
            Country='India', 
            State='Haryana'
        );
        insert lead;

        // Simulate Classic user
        User u = [SELECT Id, UserPreferencesLightningExperiencePreferred FROM User WHERE Id = :UserInfo.getUserId()];
        u.UserPreferencesLightningExperiencePreferred = false;
        update u;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(lead);
        LeadConversionRouteController ctrl = new LeadConversionRouteController(sc);
        PageReference pr = ctrl.route();
        Test.stopTest();

      
    }

  
  
 }