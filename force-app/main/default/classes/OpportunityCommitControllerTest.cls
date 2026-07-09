/*
Auhtor      : Pratibh Prakash
Company     : Fujitsu America
Created Date: 17 Sep-2009
Modified    : 
Description : Test class for "OpportunityCommitController" Controller.
 */
@isTest(SeeAllData=false)
private class OpportunityCommitControllerTest {
	static Account testAct;
    static testMethod void testOpportunityCommit() {
        //Turn Off PW validation to avoid Governor Limit violations
        //pw_ccpro__Setting__c[] settings = [select pw_ccpro__BooleanValue__c 
                                             //from pw_ccpro__Setting__c 
                                            //where Name = 'CountryValidationEnabled'];
        //settings[0].pw_ccpro__BooleanValue__c = false;
       // update settings;
       Test.StartTest();         
       Profile prof = [select Id from profile where Name='IM_Custom Sys Admin']; 
         
        User u = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
        localesidkey='en_US', profileid = prof.Id, Country = 'USA',
        timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert u;  
                
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
         //Create a new Account
        Account acc = new Account(name='AccountPratapTestMethod'+system.now(),
                                  BillingCountry='United States', 
                                IMGA_Owner__c = u.id, D_B_DUNS__c ='Test');
        insert acc;        
        //insert Account Plan
        SFDC_Acct_Plan__c AccPan = new SFDC_Acct_Plan__c();
            AccPan.Account__c = acc.id;
            AccPan.Name = 'Test Plan';
            insert AccPan;
        
        //create a new Contact
        Contact con = new Contact(
        MailingCountry='United States',
        Email='srinu@gmail.com',
        Phone='6517951874',
        LastName='Srinu',FirstName= 'First Con',
        MailingCity = 'London',MailingPostalCode = 'SE1 2TT',
        MailingState = 'London',MailingStreet = '745 Atlantic Ave',
        AccountId = acc.id);        
        insert con;
        
        ID standardrt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;

        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name = 'testSold';
        cusAcc.IM_Account__c = acc.id;
        cusAcc.Source_System__c = 'Other Europe';
        
		Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
		
        Opportunity opp = new Opportunity(name = 'Opportunity4TestMethod', AccountId = acc.id, Source_System__c = 'SKP', 
                                          Billing_Country__c = testCountry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        ,StageName = '1 - Qualification'
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,IME_Reason_Won__c = 'Price'
                                        ,IMGA_Owner__c = u.id
                                        ,IM_Up_Sell_Sold_To__c = 'testSold'
                                        ,CloseDate = System.today()
                                        ,Type = 'Renewal'
                                        ,tsu__c=u.Id
                                        ,IM_Up_Sell_Detail__c = 'details'
                                        ,IM_Up_Sell_Quantity__c = 2
                                        ,Upsell_Customer_ID__c = cusAcc.id
                                        ,IM_Unit_of_Measure__c = 'Data Restoration' 
                                        ,SKP_Opportunity_Sync_Date__c = null
                                        ,US_Federal_GSA_Pricing__c ='Yes'
                                        ,Amount=1000.00
                                        ,GSA_Eligibility__c = 'GSA Eligible'
                                        ,IM_Booked_Date__c=System.today()+2
                                        ,Forecast_Owner__c = u.id
                                       );                                 
        insert opp;
       //Preparing mock data for test
        /*Account testAccount = new Account(Name='Test'+system.now(), BillingCountry='Canada');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = '1 - Qualification', IM_Booked_Date__c = Date.Today()+2,Lead_Source_Most_Recent__c = 'Email', closedate = Date.Today()+1,IM_Servicing_Region__c = 'Aesch');
        insert testOpp;*/
        //Setting Opportunity in current page URL
        System.currentPageReference().getParameters().put('oppId',opp.Id);
        System.currentPageReference().getParameters().put('type','add');
        OpportunityCommitController_Lightning objCommitController = new OpportunityCommitController_Lightning();
        
        //Commiting Opportunity for forecast
        objCommitController.commit_uncommit_Opportunity();
        
        //Removing Opportunity from forecast
        objCommitController.commit_uncommit_Opportunity();
        
        //Calling remaining setter and getters
        objCommitController.setCustomHelpFlag(true);
        Boolean testFlag = objCommitController.getCustomHelpFlag();
        objCommitController.setSupressPopupFlag(true);
        testFlag = objCommitController.getSupressPopupFlag();
        
        
        //Updating Supress Popup flag on user.
        objCommitController.updateUser();
        
        objCommitController.Cancel();
        objCommitController.GoBack();
        
        //turn the validation back on
        //settings[0].pw_ccpro__BooleanValue__c = true;
        //update settings;
        
       Test.StopTest();
    }
    
    static testMethod void testOpportunityCommit1() {
       Test.StartTest();         
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin']; 
         
        User u = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
        localesidkey='en_US', profileid = prof.Id, Country = 'USA',
        timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert u;
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
         //Create a new Account
        Account acc = new Account(name='AccountPratapTestMethod'+system.now(),
                                  BillingCountry='United States', 
                                IMGA_Owner__c = u.id, D_B_DUNS__c ='Test');
        insert acc;        
        //insert Account Plan
        SFDC_Acct_Plan__c AccPan = new SFDC_Acct_Plan__c();
            AccPan.Account__c = acc.id;
            AccPan.Name = 'Test Plan';
            insert AccPan;
        
        //create a new Contact
        Contact con = new Contact(
        MailingCountry='United States',
        Email='srinu@gmail.com',
        Phone='6517951874',
        LastName='Srinu',FirstName= 'First Con',
        MailingCity = 'London',MailingPostalCode = 'SE1 2TT',
        MailingState = 'London',MailingStreet = '745 Atlantic Ave',
        AccountId = acc.id);        
        insert con;
        
        ID standardrt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;

        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name = 'testSold';
        cusAcc.IM_Account__c = acc.id;
        cusAcc.Source_System__c = 'Other Europe';
        
		Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
		
        Opportunity opp = new Opportunity(name = 'Opportunity4TestMethod', AccountId = acc.id, Source_System__c = 'SKP', 
                                          Billing_Country__c = testCountry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        ,StageName = '1 - Qualification'
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,IME_Reason_Won__c = 'Price'
                                        ,IMGA_Owner__c = u.id
                                        ,IM_Up_Sell_Sold_To__c = 'testSold'
                                        ,CloseDate = System.today()
                                        ,Type = 'Renewal'
                                        ,tsu__c=u.Id
                                        ,IM_Up_Sell_Detail__c = 'details'
                                        ,IM_Up_Sell_Quantity__c = 2
                                        ,Upsell_Customer_ID__c = cusAcc.id
                                        ,IM_Unit_of_Measure__c = 'Data Restoration' 
                                        ,SKP_Opportunity_Sync_Date__c = null
                                        ,US_Federal_GSA_Pricing__c ='Yes'
                                        ,Amount=1000.00
                                        ,GSA_Eligibility__c = 'GSA Eligible'
                                        ,IM_Booked_Date__c=System.today()+2
                                       );                                 
        insert opp;
        
        //Setting Opportunity in current page URL
        System.currentPageReference().getParameters().put('oppId',opp.Id);
        System.currentPageReference().getParameters().put('type','remove');
        OpportunityCommitController_Lightning objCommitController = new OpportunityCommitController_Lightning();
        
        //Commiting Opportunity for forecast
        objCommitController.commit_uncommit_Opportunity();
        
        //Removing Opportunity from forecast
        objCommitController.commit_uncommit_Opportunity();
        
        //Calling remaining setter and getters
        objCommitController.setCustomHelpFlag(true);
        Boolean testFlag = objCommitController.getCustomHelpFlag();
        objCommitController.setSupressPopupFlag(true);
        testFlag = objCommitController.getSupressPopupFlag();
        
        //Updating Supress Popup flag on user.
        objCommitController.updateUser();
        
        objCommitController.Cancel();
        objCommitController.GoBack();
        
       Test.StopTest();
    }
    @isTest
    static void testCommitUncommitOpportunity() {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin']; 
         
        User u = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
        localesidkey='en_US', profileid = prof.Id, Country = 'USA',
        timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert u;  
                
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
         //Create a new Account
        Account acc = new Account(name='AccountPratapTestMethod'+system.now(),
                                  BillingCountry='United States', 
                                IMGA_Owner__c = u.id, D_B_DUNS__c ='Test');
        insert acc;        
        //insert Account Plan
        SFDC_Acct_Plan__c AccPan = new SFDC_Acct_Plan__c();
            AccPan.Account__c = acc.id;
            AccPan.Name = 'Test Plan';
            insert AccPan;
        
        //create a new Contact
       Contact con = new Contact(
        MailingCountry='United States',
        Email='srinu@gmail.com',
        Phone='6517951874',
        LastName='Srinu',FirstName= 'First Con',
        MailingCity = 'London',MailingPostalCode = 'SE1 2TT',
        MailingState = 'London',MailingStreet = '745 Atlantic Ave',
        AccountId = acc.id);        
        insert con; 
        
        ID standardrt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;

        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name = 'testSold';
        cusAcc.IM_Account__c = acc.id;
        cusAcc.Source_System__c = 'Other Europe';
        
		Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
		
        Opportunity opp = new Opportunity(name = 'Opportunity4TestMethod', AccountId = acc.id, Source_System__c = 'SKP', 
                                          Billing_Country__c = testCountry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        ,StageName = '1 - Qualification'
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,IME_Reason_Won__c = 'Price'
                                        ,IMGA_Owner__c = u.id
                                        ,IM_Up_Sell_Sold_To__c = 'testSold'
                                        ,CloseDate = System.today()
                                        ,Type = 'Renewal'
                                        ,tsu__c=u.Id
                                        ,IM_Up_Sell_Detail__c = 'details'
                                        ,IM_Up_Sell_Quantity__c = 2
                                        ,Upsell_Customer_ID__c = cusAcc.id
                                        ,IM_Unit_of_Measure__c = 'Data Restoration' 
                                        ,SKP_Opportunity_Sync_Date__c = null
                                        ,US_Federal_GSA_Pricing__c ='Yes'
                                        ,Amount=1000.00
                                        ,GSA_Eligibility__c = 'GSA Eligible'
                                        ,IM_Booked_Date__c=System.today()+2
                                        ,Forecast_Owner__c = u.id
                                       );                                 
        insert opp;
        User testUser = [SELECT Id FROM User WHERE Username = 'srinu.mandalapu@testorg.com' LIMIT 1];
        System.runAs(testUser) {
            Opportunity opp1 = [SELECT Id, IM_Commit_to_Forecast__c FROM Opportunity LIMIT 1];

            // Set page parameters
            Test.setCurrentPageReference(new PageReference('/apex/dummyPage'));
            ApexPages.currentPage().getParameters().put('oppId', opp1.Id);

            // Instantiate controller and test commit/uncommit method
            OpportunityCommitController controller = new OpportunityCommitController();
            PageReference result = controller.commit_uncommit_Opportunity();
             
        }
    }
     @isTest
    static void testUpdateUser() {
         Profile prof = [select Id from profile where Name='IM_Custom Sys Admin']; 
         
        User u = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
        localesidkey='en_US', profileid = prof.Id, Country = 'USA',
        timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert u;  
                
        User testUser = [SELECT Id, Suppress_Custom_Help_Popups__c FROM User WHERE UserName='srinu.mandalapu@testorg.com' LIMIT 1];

        System.runAs(testUser) {
            OpportunityCommitController controller = new OpportunityCommitController();
            controller.setCustomHelpFlag(true);
            controller.setSupressPopupFlag(true);
            controller.updateUser();

            User updatedUser = [SELECT Suppress_Custom_Help_Popups__c FROM User WHERE Id = :testUser.Id];
            System.assertEquals(true, updatedUser.Suppress_Custom_Help_Popups__c, 'User flag should be updated');
        }
    }
}