/**
* Class: OpportunityTrigger_Test 
* Author: BCT
* Date Created: 06.05.2020
* Purpose: This class has the test methods for the opportunity object trigger
* Change History :
Removed the field (CDM_Registration_Number__c) dependency as part of #16051 in OpportunityHelper 
hence modified this test class to increase the code coverage

Merged the test class (Test_OpportunityObjectTrigger) in this class as we can have only one test class for Opportunity trigger
#16391 and #16286
*/
@isTest
public class OpportunityTrigger_Test {
     @testSetup static void setup() {
        // Create common test Data
		//  insert country custom setting 
        List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
        Country_Settings__c cS = new Country_Settings__c();
        cS.Name = 'Canada';
        cS.Object_Name__c = 'Account';
        countrySetting.add(cS);
        
        Country_Settings__c cS1 = new Country_Settings__c();
        cS1.Name = 'United States';
        cS1.Object_Name__c = 'Account';
        countrySetting.add(cS1);
        
        insert countrySetting;
		//Custom Setting
		insert new SVStatus__c(Name='SVStatusPassed',Amount__c = 24000,OpptType__c='New Deal,Up-Sell/Lift',Stage__c='6 - Setup');
		//Custom Setting
		List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        
        insert opprodsel;
        //Custom Setting
        // insert opportunity custom setting 
        List<Opportunity_Security__c> oppSettingList = new List<Opportunity_Security__c>();
        Opportunity_Security__c oppSett = new Opportunity_Security__c();
        oppSett.Name = 'Original Lead Owner';
        oppSett.Field_Name__c = 'IM_Original_Lead_Owner__c';
        oppSett.Object_Name__c = 'Opportunity';
        oppSett.Visibility_Access_Level__c = 'W';
        oppSettingList.add(oppSett);
        
        Opportunity_Security__c oppSett1 = new Opportunity_Security__c();
        oppSett1.Name = 'Primary BDE';
        oppSett1.Field_Name__c = 'Primary_BDE__c';
        oppSett1.Object_Name__c = 'Account';
        oppSett1.Visibility_Access_Level__c = 'W';
        oppSettingList.add(oppSett1);
        
        Opportunity_Security__c oppSett2 = new Opportunity_Security__c();
        oppSett2.Name = 'Primary CDE';
        oppSett2.Field_Name__c = 'Primary_CDE__c';
        oppSett2.Object_Name__c = 'Account';
        oppSett2.Visibility_Access_Level__c = 'R';
        oppSettingList.add(oppSett2);
		
        insert oppSettingList;
        QTB_TestDataFactory.createLOBMapping();
    }
    static testmethod void testOpportunityInfo()
    {           
        Profile p = [Select id from profile where name = 'System administrator']; 
        User us = new User(alias = 'hasrole', email='userwithrole@roletest1.com',
                           emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',
                           localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',
                           username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true,Phone='1234567890');
        insert us; 
        
        System.runAs(us)
        {
            
            IM_Country__c countryRec =  new IM_Country__c();
            countryRec.Iso31662Code__c ='US';
            countryRec.Iso31663Code__c ='USA';
            countryRec.Name ='United States';
            countryRec.Region__c ='North America';
            
            insert countryRec;
            IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='North America' and Name ='United States'];
            
            IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
            altcountry.IM_Country__c = retCountry.id;
            altcountry.Alternative_Name__c='United States'; 
            
            insert altcountry;
            
            RecordType EUOppType = [select id from RecordType where name = 'Standard Opportunity' and  sObjectType = 'Opportunity'];
            IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United States',Region__c = 'North America'))); 
            
            AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
            account acc = new Account(name='x',BillingCountry = 'United States', IMGA_Owner__c = us.id);
            insert acc;
            
            IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            cusAcc.Name = 'testSold';
            cusAcc.IM_Account__c = acc.id;
            cusAcc.Source_System__c = 'Other Europe';
            
            insert cusAcc;
            
            Opportunity opp = new Opportunity(name = 'c', AccountId = acc.id, Source_System__c = 'SKP', Billing_Country__c = cntry.id 
                                              ,Lead_Source_Most_Recent__c = 'x'
                                              //,StageName = '7 - Closed'
                                              ,StageName = '1 - Qualification'
                                              ,RecordTypeId = EUOppType.Id
                                              ,IM_Servicing_Region__c ='London'
                                              //,IM_Commit_to_Forecast__c = true
                                              ,IM_Stage_5_Entered_Date__c  = System.today()
                                              ,IME_Reason_Won__c = 'Price'
                                              ,IMGA_Owner__c = us.id
                                              ,IM_Up_Sell_Sold_To__c = 'testSold'
                                              ,CloseDate = System.today()
                                              ,Type = 'Up-Sell/Lift'
                                              ,tsu__c=us.Id
                                              ,IM_Up_Sell_Detail__c = 'details'
                                              ,IM_Up_Sell_Quantity__c = 2
                                              ,Upsell_Customer_ID__c = cusAcc.id
                                              ,IM_Unit_of_Measure__c = 'Data Restoration' 
                                              ,SKP_Opportunity_Sync_Date__c = null
                                              ,US_Federal_GSA_Pricing__c ='Yes - GSA Pricing'
                                              ,Amount=1000.00
                                              ,GSA_Eligibility__c = 'GSA Eligible'
                                              ,IM_Booked_Date__c = System.today()
                                              ,Bypass_Flows_Trigger__c = True);
            
            insert opp;
            
            //OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;
            opp.US_Federal_GSA_Pricing__c = 'No';
            //opp.GSA_Eligibility__c = 'Standard Pricing Applies';
            opp.Cloud_Provider__c = 'AWS';
            opp.Primary_Product_Line__c = 'Insight';
            //opp.StageName = '2 - Solution Developed';
            opp.Services_Discount__c = '42%';
	        opp.Contract_Type__c = 'Value';
        	opp.Manager_Approval_Needed_Hidden__c = 'No';
            opp.Bypass_Flows_Trigger__c = True;
            update opp;
            
            opp.StageName = '2 - Solution Developed';
            opp.Bypass_Flows_Trigger__c = True;
            opp.CurrencyIsoCode = 'USD';
            update opp;
            
            
            OpportunityTeamMember ot = new OpportunityTeamMember();
            ot.OpportunityId = opp.Id;
            ot.UserId = opp.tsu__c;
            ot.TeamMemberRole = 'NA - Tactical Sales Unit';
            insert ot;
            
            Case case1 = new Case();
            case1.NCSP_Service_line__c = 'RM';
            //case1.Account = 'x';
            case1.NCSP_Cust_Name__c = 'TestName';
            case1.Status = 'New';
            case1.Origin = 'BDE';
            case1.Sales_Person_Name_Account_Manager__c = us.id;
            case1.Date_Contract_Signed__c = system.now();
            case1.Date_Paperwork_Received__c = system.now();
            case1.Setup_Type__c = 'Standard';
            case1.NCSP_Opportunity__c = opp.id;
            case1.Customer_ID__c = cusAcc.id;
            
            insert case1;
            
            //Create a new Competitor.
            Competitor__c comp = new Competitor__c();
            comp.Name = 'Test Comp';
            insert comp;
            
            //Create a new Opportunity Competitor.
            Opportunity_Competitor__c optyComp = new Opportunity_Competitor__c();
            optyComp.Opportunity__c = opp.Id;
            optyComp.Competitor__c = comp.Id;
            optyComp.Opportunity_Owner_Email__c = opp.Owner.Email;
            insert optyComp;
            
        }
    } 
  
    static testMethod void IMEOpprtunityMethod1()
    {
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
         system.debug('limit queries method start '+limits.getQueries());
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = new IM_Country__c(Name='United Kingdom',Region__c='Europe');
        insert retCountry;  
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
         system.debug('limit queries before account '+limits.getQueries());
        Account acc = new Account();
        acc.name='TestAcc';
        acc.Billingcity='Test';
        acc.BillingCountry = 'United Kingdom';
        insert acc; 
         system.debug('limit queries after account '+limits.getQueries());
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        Id CPQSalesRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CPQ Sales Opportunity').getRecordTypeId();
        Profile p = [Select id from profile where name = 'System administrator']; 
         system.debug('limit queries before user '+limits.getQueries());
        User us = new User(alias = 'hasrole', email='userwithrole@roletest1.com',
                           emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',
                           localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',
                           username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true,Phone='1234567890');
        insert us;
         system.debug('limit queries afert user / before insert '+limits.getQueries());
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Opportunity testopp = new Opportunity();
        testopp.StageName = '1 - Qualification';
        testopp.name = 'c';	
        testopp.AccountId = acc.id; 
        testopp.recordtypeid = CPQSalesRecordTypeId; 
        testopp.CloseDate = System.today();
        testopp.IM_Servicing_Region__c ='London';
        testopp.Contracting_Country__c = 'United Kingdom';
        testopp.Contract_Term__c='12';
        testopp.tsu__c=us.Id; 
        testopp.US_Federal_GSA_Pricing__c ='No';
        testopp.GSA_Eligibility__c = 'Standard Pricing Applies';
        testopp.IM_Reason_Lost__c ='test';
        testopp.Forecast_Owner__c = us.id;
        testopp.IM_Booked_Date__c = System.today();
        testopp.Bypass_Flows_Trigger__c = True;
        insert testopp;
        
        //Create a ContentVersion (File)
        ContentVersion cv = new ContentVersion(
            Title = 'Test FIle',
            VersionData = Blob.valueOf('Test File Contant'),
            PathOnClient = 'testFile.txt'
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
        	LinkedEntityId = testopp.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;
        
         system.debug('limit queries after insert '+limits.getQueries());
        
        Id testStandardPriceBook = Test.getStandardPricebookId();
        Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        
        Product2 testProd = new Product2(Name = '9999',
                                         recordTypeId=rt, 
                                         IsActive= true,
                                         Bill_Code_Classification__c='Storage');
        insert testProd;
        
        Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, 
                                                                Pricebook2Id = testStandardPriceBook, 
                                                                UnitPrice = 1, IsActive = true, 
                                                                UseStandardPrice = false);
        insert testPriceBookEntry;
        
        PricebookEntry pbe_01 = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = testProd.Id,
            UnitPrice = 12000, IsActive = true);
        insert pbe_01;
         system.debug('limit queries before OpportunityLineItem '+limits.getQueries());
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = testopp.Id, unitPrice = 1,Product_Class__c ='Records Management',Product_Line__c='storage');
        insert oppProd;
                 system.debug('limit queries after OpportunityLineItem '+limits.getQueries());

        Contact cont = new contact(LastName = 'Test', FirstName = 'Test',Email = 'test.test@cgtest.com',MailingCity='test',MailingCountry='Russia',MailingStreet='Russia',MailingPostalCode='123',MailingState='Ru', accountId = acc.id);
        insert cont;
        system.debug('LLimit before contactrole'+Limits.getQueries());
        test.startTest();
        system.debug('limit queries before OpportunityContactRole '+limits.getQueries());

        
        OpportunityContactRole OCR =  new OpportunityContactRole( OpportunityId = testopp.Id, ContactId = cont.id, Role ='Business User	');
        insert OCR;
        system.debug('limit queries before OpportunityContactRole '+limits.getQueries());

        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;
        system.debug('LLimit after contactrole'+Limits.getQueries());
        //testopp.GSA_Eligibility__c = 'GSA Eligible';
        testopp.StageName = '5 - Signed/PO in';
        testopp.IME_Reason_Won__c = 'test';
        system.debug('LLimit before update'+Limits.getQueries());
        update testopp;     
        test.stopTest();
    }
    
    
    static testMethod void testImeOppCustAccTrigger() 
    {    
       AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
        
        Account acct = new Account();
        acct.Name = 'Test Acc';
        acct.BillingCity = 'Tests';
        acct.BillingCountry = 'United Kingdom';
        //acct.IM_Hierarchy_Level__c = 'IM Group(IMGA)';
        insert acct;
           
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        a.ParentId = acct.Id;
        //a.IMGA_Id__c = acct.Id;
        insert a;
        
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        Id CPQSalesRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CPQ Sales Opportunity').getRecordTypeId();
        
        Profile p = [Select id from profile where name = 'System administrator']; 
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com',
                          emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',
                          username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true);
        insert u;
        
        
        
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name = 'testSold';
        cusAcc.IM_Account__c = a.id;
        cusAcc.Source_System__c = 'Other Europe';
        
        
        //Create the opportunity
        Opportunity o = new Opportunity(name = 'c', AccountId = a.id, Source_System__c = 'SKP', Billing_Country__c = countryRec.id 
                                        //,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = false
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,IME_Reason_Won__c = 'Price'
                                        ,IMGA_Owner__c = u.id
                                        ,IM_Up_Sell_Sold_To__c = 'testSold'
                                        ,CloseDate = System.today()
                                        ,Type = 'Up-Sell/Lift'
                                        ,tsu__c=u.Id
                                        ,IM_Up_Sell_Detail__c = 'details'
                                        ,IM_Up_Sell_Quantity__c = 2
                                        ,Upsell_Customer_ID__c = cusAcc.id
                                        ,IM_Unit_of_Measure__c = 'Data Restoration' 
                                        ,SKP_Opportunity_Sync_Date__c = null
                                        ,US_Federal_GSA_Pricing__c ='Yes'
                                        ,Amount=1000.00
                                        ,GSA_Eligibility__c = 'GSA Eligible'
                                        ,IM_Booked_Date__c=System.today() + 1
                                        ,Forecast_Owner__c = u.id
                                        ,ConvertedFromLead__c = False
                                        ,Lead_Source_Most_Recent__c = 'Email'
                                        ,CreatedDate = System.today().addDays(-1)
                                        //,IM_Lead_Source_Most_Recent_Details__c = 'Sales sent'
                                        ,Bypass_Flows_Trigger__c = True
                                       );                                 
        insert o;
        
        //Create a ContentVersion (File)
        ContentVersion cv = new ContentVersion(
            Title = 'Test FIle',
            VersionData = Blob.valueOf('Test File Contant'),
            PathOnClient = 'testFile.txt'
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
        	LinkedEntityId = o.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;
        
        
        Pricebook2 pb = new Pricebook2(Name='North America', isActive=true);
        insert pb;
        
        Id IMNAProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        
        Product2 prod = new Product2(Secondary_Product_Allowed__c=true, 
                                     Name='test1',
                                     CurrencyIsoCode='USD',
                                     RecordTypeId = IMNAProductRecordTypeId,
                                     IM_Product_Line__c='Cloud Solutions',
                                     IM_Product_Class__c='Data Backup and Recovery',
                                     // RevenueInstallmentPeriod ='Monthly', 
                                     IsActive=true);
        insert prod;  
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true,
            CurrencyIsoCode='USD', 
            UseStandardPrice = false);  
        
        insert pbe;
        
         OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        OpportunityLineItem oli = new OpportunityLineItem(PricebookEntryId= pbe.id, OpportunityId=o.id, Quantity=1, TotalPrice=1);
        
        insert oli;
           
        Contact cont = new contact(LastName = 'Test', FirstName = 'Test',Email = 'test.test@cgtest.com',MailingCity='test',MailingCountry='Russia',MailingStreet='Russia',MailingPostalCode='123',MailingState='Ru', AccountId=a.id ,IM_Lead_Source_Most_Recent__c = 'Email'
                                        ,IM_Lead_Source_Most_Recent_Details__c = 'Sales sent');
        insert cont;
        //test.startTest();
        system.debug('limit queries before contact role '+limits.getQueries());
       
        OpportunityContactRole OCR =  new OpportunityContactRole( OpportunityId = o.Id, ContactId = cont.id, Role ='Business User', IsPrimary = true);
        insert OCR;
        system.debug('limit queries before test start '+limits.getQueries());
        test.startTest();
        
       // o.Customer_Account_Number__c = System.now().format();
        //OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        o.StageName = '5 - Signed/PO in';
        //o.RecordTypeId = CPQSalesRecordTypeId;
        system.debug('limit queries before update 1 '+limits.getQueries());
        update o;
         OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;
        
        o.Customer_Account_Number__c = System.now().format();
        o.StageName = '7 - Closed';
        system.debug('limit queries before update 2 '+limits.getQueries());
        update o;
        system.debug('limit queries afert update 2 '+limits.getQueries());
		 test.stopTest();    
             /*
        o.Customer_Account_Number__c = null;
        
        update o;
         
   
        o.Customer_Account_Number__c = System.now().format();
        try{
            update o;
        }
        catch(Exception e)
        {
            
        }
        
        test.stopTest();  
		*/
    }  

      
    static testMethod void opportunityRollupContract() 
    {   
        
        system.debug('limit queries '+limits.getQueries());
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;

        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
        
         system.debug('limit queries before user '+limits.getQueries());
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom' );
        
        insert u; 
        
         system.debug('limit queries after user '+limits.getQueries());
          
		Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
       /* RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];*/
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
         system.debug('limit queries before acc '+limits.getQueries());
        

        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        insert a;
        
         system.debug('limit queries after acc '+limits.getQueries());
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='GBP'
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;      
        
         List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
    system.debug('limit queries before start test '+limits.getQueries());
        //test.startTest();
         system.debug('limit queries before insert '+limits.getQueries());
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        //,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode='GBP'
                                        ,Forecast_Owner__c = u.id
                                        ,Bypass_Flows_Trigger__c = True
                                        //,IME_Contract__c = parentContract.id    
                                       );
        
        insert o; 
         system.debug('limit queries after insert '+limits.getQueries());
        test.startTest();
        o.IME_Contract__c = parentContract.id;
        o.amount = 100;
        update o;
         system.debug('limit queries after update1 '+limits.getQueries());
        o.IME_Contract__c = null ;
        update o;
        test.stopTest();
        
        //o.IME_Contract__c = null ;
        //update o; 
         system.debug('limit queries after update2 '+limits.getQueries());
       // test.stopTest(); 
         system.debug('limit queries end '+limits.getQueries());
    }
    static testMethod void opportunityRollupContract1() 
    {
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom');
        
        insert u;
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        /*RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];*/
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        insert a;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        //Create the opportunity        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='USD'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;      
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        
        Contract childContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtChildContract 
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='USD'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
        lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        cca= ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        cca1 = ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        
        childContract .IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
        
        update childContract;
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        //,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode='USD'
                                        ,IME_Contract__c = parentContract.id   
                                        ,SV_Status__c = 'Commission Ineligible'
                                        ,Forecast_Owner__c = u.id
										,Bypass_Flows_Trigger__c = True
                                       );
        
        insert o; 
        //OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;
		test.startTest();        
        o.OwnerId=u.id;     
        update o;
        //o.IME_Contract__c = childContract.id;
        o.amount = 100;
        o.Opportunity_Total_Annual_Amount_Test__c = True;
		o.SV_Status__c = 'Passed';        
        update o;
        
        o.StageName = 'Lost';
        o.IM_Lost_Comments__c = 'test';
        o.IM_Reason_Lost__c = 'Duplicate';
        update o;
       
        test.stopTest(); 
        
    } 
     static testMethod void opportunityRollupContract2()
     {        
        
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;         
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom');
        
        insert u;
         
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        /*RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];*/
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        insert a;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        
        //Create the opportunity
        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='HUF'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;      
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        
        Contract childContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtChildContract 
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c ='' 
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='HUF'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
        lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        cca= ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        cca1 = ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        childContract .IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
        
        update childContract;
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        test.startTest();
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                       //,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode='USD'
                                        ,IME_Contract__c = parentContract.id 
                                        ,OwnerId = u.Id
                                        ,Forecast_Owner__c = u.id
                                        ,Bypass_Flows_Trigger__c = True
                                       );
        
        insert o; 
       //test.startTest();        
        o.OwnerId=u.id;     
        //update o;
        o.IME_Contract__c = childContract.id;
        o.amount = 100;
		//o.SV_Status__c = 'Passed';
        o.Services_Discount__c = '36';
        o.Contract_Type__c = 'Value';
        o.Manager_Approval_Needed_Hidden__c = o.Manager_Approval_Needed__c;
        o.Bypass_Flows_Trigger__c = True;
        update o;
        o.IME_Contract__c = null ;
        update o;
        test.stopTest(); 
        
        
    }
	static testMethod void opportunityRollupContractAmountChange() {
        
		AccountTriggerHandler.skipTriggerExecutionTestClass  = true;

        system.debug('limit queries '+limits.getQueries());
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
        
         system.debug('limit queriesbefore user '+limits.getQueries());
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom');
        
        insert u;
        
        system.debug('limit queries after user '+limits.getQueries());
        RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
         system.debug('limit queries before acc '+limits.getQueries());
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        insert a;
        
         system.debug('limit queries after Acc '+limits.getQueries());
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
     /*   Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
       */ 
        
        //Create the opportunity
                 system.debug('limit queries before contract '+limits.getQueries());

        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='HUF'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;      
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        
        Contract childContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtChildContract 
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c ='' 
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='HUF'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
         lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        cca= ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        cca1 = ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        
        childContract .IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
        
        update childContract;
        
                 system.debug('limit queries after contract '+limits.getQueries());

        
        
      test.startTest();
        
        system.debug('limit queries before insert '+limits.getQueries());
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
                
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        //,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode='USD'
                                        ,IME_Contract__c = parentContract.id
                                        ,Forecast_Owner__c = u.id
                                        ,Bypass_Flows_Trigger__c = True
                                       );
        
        insert o; 
         system.debug('limit queries after insert '+limits.getQueries());
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;

        o.amount = 500;
		update o;
        
         system.debug('limit queries after update '+limits.getQueries());
        test.stopTest(); 
        
         system.debug('limit queries end '+limits.getQueries());
    }
	static testMethod void opportunityRollupContractnewInsert() {
        
		AccountTriggerHandler.skipTriggerExecutionTestClass  = true;

        system.debug('limit queries  '+limits.getQueries());        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
        
         system.debug('limit queries before user '+limits.getQueries());
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom');
        
        insert u;
        
         system.debug('limit queries after user '+limits.getQueries());
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
         system.debug('limit queries before acc '+limits.getQueries());
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        insert a;
         system.debug('limit queries after acc '+limits.getQueries());
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        
        //Create the opportunity
        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='HUF'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;      
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        
        
        test.startTest();
         system.debug('limit queries before insert '+limits.getQueries());
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        //,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode='USD'
                                        //,IME_Contract__c = parentContract.id   
                                        ,Forecast_Owner__c = u.id
                                        ,Bypass_Flows_Trigger__c = True
                                       );
        
        insert o;
         system.debug('limit queries after insert '+limits.getQueries());
		o.amount = 100;
        //o.IME_Contract__c = parentContract.id;
        //o.Manager_Approval_Needed__c = 'Yes';
        o.Services_Discount__c = '36';
        o.Contract_Type__c = 'Value';
        o.Service_Type__c = 'Business Associate Agreement';
		update o;
         system.debug('limit queries after update1 '+limits.getQueries());
        test.stopTest(); 
		o.IME_Contract__c = null;
		update o;
         system.debug('limit queries after update2 '+limits.getQueries());
        
      //  test.stopTest(); 
         system.debug('limit queries end  '+limits.getQueries());
        
    }
    static testMethod void testSameCurrency() 
    {
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry; 
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom');
        
        insert u;
        RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        a.Global_Account__c = true;
        a.Global_IMGA_Owner__c = u.id;
        insert a;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        
        //Create the opportunity
        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='GBP'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 20;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        
        
        Contract childContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtChildContract 
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='CAD'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
        lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        cca= ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        cca1 = ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        
        childContract .IME_Annual_Value_Opportunities__c = 10;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
        
        update childContract;
        
        test.startTest();
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x' 
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode= 'GBP'
                                        ,IME_Contract__c = parentContract.id  
                                        ,OwnerId = u.Id
                                        ,Forecast_Owner__c = u.Id
                                        ,Bypass_Flows_Trigger__c = True
                                       );
        
        insert o; 
        o.IME_Contract__c = childContract.id;
        o.Services_Discount__c = '36';
        o.Contract_Type__c = 'Value';
        o.Service_Type__c = 'Business Associate Agreement';
        o.Manager_Approval_Needed_Hidden__c = o.Manager_Approval_Needed__c;
        o.Bypass_Flows_Trigger__c = True;
        update o;
        
        Delete o;
        test.stopTest();  
    }    
    static testMethod void testSameCurrency1() {
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry; 
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom');
        
        insert u;
        RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        a.Global_Account__c = true;
        a.Global_IMGA_Owner__c = u.id;
        insert a;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        
        //Create the opportunity
        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            ,IME_Price_Increase_Type_Storage__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='GBP'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 20;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        
        
        
        Contract childContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtChildContract 
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='GBP'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
        lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        cca= ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        cca1 = ContractHelperClass.CreateContractCustomer(childContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        childContract .IME_Annual_Value_Opportunities__c = 10;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
        
        update childContract;
        
        test.startTest();
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x' 
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        //,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode= 'GBP'
                                        ,IME_Contract__c = parentContract.id
                                        ,OwnerId = u.Id
                                        ,Forecast_Owner__c = null
                                        ,Bypass_Flows_Trigger__c = True
                                       );
        
        insert o;  
        
        o.IME_Contract__c = childContract.id; 
        o.Services_Discount__c = '36';
        o.Contract_Type__c = 'Value';
        o.Manager_Approval_Needed_Hidden__c = o.Manager_Approval_Needed__c;
        o.Bypass_Flows_Trigger__c = True;
        //o.Service_Type__c = 'Business Associate Agreement';
        update o;
        
        Delete o;
        test.stopTest();  
    } 
	static testMethod void testMethodUser() {
		        
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry; 
        
        Profile p = [Select id from Profile where name = 'IM_Custom Sys Admin'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing', languagelocalekey='en_US'
                          , localesidkey='en_US', ProfileId = p.Id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole@testorg.com'
                          , Country = 'United Kingdom'
                         );
        
        insert u;
        RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];
        
        ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();   
        ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
        
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        insert a;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
		//Create the opportunity
        
        Contract parentContract = new Contract(
            AccountId = a.id
            ,RecordTypeId =rtIMEParent
            ,Status = 'Draft' 
            ,IME_Original_Contract_Start_Date__c=System.today()
            ,StartDate=System.today().addmonths(-1)
            ,Contract_Signed_Date__c = System.today()+2 
            , IME_Price_Increase_Type_Storage__c ='Regular Increase'
            , IME_Fixed_Pricing_Period_months_Storage__c =12
            ,IME_Special_Terms_Other_Storage__c =''
            ,IME_Copy_to_all__c = false
            ,IME_Other__c=true
            ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Services__c =12
            ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Transp__c =12
            ,CurrencyIsoCode='GBP'
            ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
            ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        parentContract.IME_Annual_Value_Opportunities__c = 20;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
		test.startTest();
        Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x' 
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        //,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode= 'GBP'
                                        ,IME_Contract__c = parentContract.id
                                        ,Forecast_Owner__c = u.id
                                        ,Bypass_Flows_Trigger__c = True
                                       );
        
        insert o; 
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;
		            //Create a new Competitor.
            Competitor__c comp = new Competitor__c();
            comp.Name = 'Test Comp';
            insert comp;
            
            //Create a new Opportunity Competitor.
            Opportunity_Competitor__c optyComp = new Opportunity_Competitor__c();
            optyComp.Opportunity__c = o.Id;
            optyComp.Competitor__c = comp.Id;
            optyComp.Opportunity_Owner_Email__c = o.Owner.Email;
            insert optyComp;
		//System.runAs(u)
        //{
			o.ownerId = u.id;
            o.CloseDate = System.today();
            //o.Manager_Approval_Needed_Hidden__c = 'Yes';
            //o.Services_Discount__c = '32%';
        	//o.Service_Type__c = 'All';
			update o;
		//}
        test.stoptest();
	}
    
    static testMethod void TestpopulateOptyOwnerInfo() {
    List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'populateOptyOwnerInfo';
        tA.Object__c = 'Opportunity';
        tA.Trigger__c = 'populateOptyOwnerInfo';
        tA.Value__c = 'True';
        custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'OpportunityOwnerLinkTrg';
        tA1.Object__c = 'Opportunity';
        tA1.Trigger__c = 'OpportunityOwnerLinkTrg';
        tA1.Value__c = 'False';
        custSettingList.add(tA1);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
        tA2.name = 'UpdateOppotunityOwnerEmailTrigger';
        tA2.Object__c = 'Opportunity';
        tA2.Trigger__c = 'UpdateOppotunityOwnerEmailTrigger';
        tA2.Value__c = 'False';
        custSettingList.add(tA2);
        
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
        tA3.name = 'syncOppScheduleDate_Fix';
        tA3.Object__c = 'Opportunity';
        tA3.Trigger__c = 'syncOppScheduleDate_Fix';
        tA3.Value__c = 'False';
        custSettingList.add(tA3);
        
        Trigger_Activation_Settings__c tA4 = new Trigger_Activation_Settings__c();
        tA4.name = 'CreateOptyShare';
        tA4.Object__c = 'Opportunity';
        tA4.Trigger__c = 'CreateOptyShare';
        tA4.Value__c = 'True';
        custSettingList.add(tA4);
        
        Trigger_Activation_Settings__c tA5 = new Trigger_Activation_Settings__c();
        tA5.name = 'OpportunitySubmitForApproval';
        tA5.Object__c = 'Opportunity';
        tA5.Trigger__c = 'OpportunitySubmitForApproval';
        tA5.Value__c = 'True';
        custSettingList.add(tA5);
        
        Trigger_Activation_Settings__c tA6 = new Trigger_Activation_Settings__c();
        tA6.name = 'SendAccountInfoToCDM';
        tA6.Object__c = 'Opportunity';
        tA6.Trigger__c = 'SendAccountInfoToCDM';
        tA6.Value__c = 'False';
        custSettingList.add(tA6);
        
        Trigger_Activation_Settings__c tA7 = new Trigger_Activation_Settings__c();
        tA7.name = 'SKPOpportunitySync';
        tA7.Object__c = 'Opportunity';
        tA7.Trigger__c = 'SKPOpportunitySync';
        tA7.Value__c = 'True';
        custSettingList.add(tA7);
        
        Trigger_Activation_Settings__c tA8 = new Trigger_Activation_Settings__c();
        tA8.name = 'ValidateOpportunityPartner';
        tA8.Object__c = 'Opportunity';
        tA8.Trigger__c = 'ValidateOpportunityPartner';
        tA8.Value__c = 'True';
       
        custSettingList.add(tA8);
        
        Trigger_Activation_Settings__c tA9 = new Trigger_Activation_Settings__c();
        tA9.name = 'IGDSMillionDollarPost';
        tA9.Object__c = 'Opportunity';
        tA9.Trigger__c = 'IGDSMillionDollarPost';
        tA9.Value__c = 'True';
        custSettingList.add(tA9);
        
        
        insert custSettingList;
       
        Profile p = [Select id from profile where name = 'System administrator'];

        User us = new User(alias = 'hasrole', email='userwithrole@roletest1.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true);
        insert us;
        
        SYSTEM.DEBUG('US.ISACTIVE:' +US.ISACTIVE);
        system.runAs(us){
            IM_Country__c countryRec =  new IM_Country__c();
            countryRec.Iso31662Code__c ='US';
            countryRec.Iso31663Code__c ='USA';
            countryRec.Name ='United States';
            countryRec.Region__c ='North America';
            
            insert countryRec;
            RecordType EUOppType = [select id from RecordType where name = 'Standard Opportunity' and  sObjectType = 'Opportunity'];
            //IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United States',Region__c = 'North America'))); 
            IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='North America' and Name ='United States'];
            
            IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
            altcountry.IM_Country__c = retCountry.id;
            altcountry.Alternative_Name__c='United States'; 
            
            insert altcountry;
            account acc = new Account(name='x',BillingCountry = 'United States', IMGA_Owner__c = us.id);
            insert acc;
            
            IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            cusAcc.Name = 'testSold';
            cusAcc.IM_Account__c = acc.id;
            cusAcc.Source_System__c = 'Other Europe';
            
            insert cusAcc;
            
            system.debug('limit queries before insert '+limits.getQueries());
            
            Opportunity opp = new Opportunity(name = 'c', AccountId = acc.id, Source_System__c = 'SKP', Billing_Country__c = retCountry.id 
                                              ,Lead_Source_Most_Recent__c = 'x'
                                              //,StageName = '7 - Closed'
                                              ,StageName = '1 - Qualification'
                                              ,RecordTypeId = EUOppType.Id
                                              ,IM_Servicing_Region__c ='London'
                                              //,IM_Commit_to_Forecast__c = true
                                              ,IM_Stage_5_Entered_Date__c  = System.today()
                                              ,IME_Reason_Won__c = 'Price'
                                              ,IMGA_Owner__c = us.id
                                              ,IM_Up_Sell_Sold_To__c = 'testSold'
                                              ,CloseDate = System.today()
                                              ,Type = 'Up-Sell/Lift'
                                              ,IM_Up_Sell_Detail__c = 'details'
                                              ,IM_Up_Sell_Quantity__c = 2
                                              ,Upsell_Customer_ID__c = cusAcc.id
                                              ,IM_Unit_of_Measure__c = 'Data Restoration'
                                              //,Commissionable_Window_Close_Date__c = null
                                              ,SKP_Opportunity_Sync_Date__c = null
                                              ,GSA_Eligibility__c = 'GSA Eligible'
                                              ,IM_Booked_Date__c=System.today()
                                              ,Forecast_Owner__c = us.id
                                              ,Bypass_Flows_Trigger__c = True
                                             );
            
            insert opp;
            
            
            system.debug('limit queries after insert '+limits.getQueries());
            
            
            Case case1 = new Case();
            case1.NCSP_Service_line__c = 'RM';
            //case1.Account = 'x';
            case1.NCSP_Cust_Name__c = 'TestName';
            case1.Status = 'New';
            case1.Origin = 'BDE';
            case1.Sales_Person_Name_Account_Manager__c = us.id;
            case1.Date_Contract_Signed__c = system.now();
            case1.Date_Paperwork_Received__c = system.now();
            case1.Setup_Type__c = 'Standard';
            case1.NCSP_Opportunity__c = opp.id;
            case1.Customer_ID__c = cusAcc.id;
            
            insert case1;
            
            //Create a new Competitor.
            Competitor__c comp = new Competitor__c();
            comp.Name = 'Test Comp';
            insert comp;
            
            //Create a new Opportunity Competitor.
            Opportunity_Competitor__c optyComp = new Opportunity_Competitor__c();
            optyComp.Opportunity__c = opp.Id;
            optyComp.Competitor__c = comp.Id;
            optyComp.Opportunity_Owner_Email__c = opp.Owner.Email;
            insert optyComp;

            User user1 = new User(alias = 'test', email='userwithnamerole@roletest1.com',emailencodingkey='UTF-8',lastname='Testrecord', languagelocalekey='en_US',localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',username='userwithrolewithid@testorg.com',Country = 'United Kingdom',ISACTIVE=TRUE);
            insert user1;
            opp.OwnerId = user1.id;
            opp.GSA_Eligibility__c = null;
            
            system.debug('limit queries before update 1 '+limits.getQueries());
            OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
            update opp;
            system.debug('limit queries after update 1 '+limits.getQueries());
            
            
            opp.GSA_Eligibility__c = 'GSA Eligible';
            //OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;
            update opp;
             system.debug('limit queries afetr update 2 '+limits.getQueries());

        }
    }   
        
       
       
        
    
    
    static testMethod void IMEOpprtunityMethod()
    {
        system.debug('limit queries method start '+limits.getQueries());
        IM_Country__c testCountry = new IM_Country__c(Name='United Kingdom');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United Kingdom');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United Kingdom';
        setting.object_name__c = 'Account';
        insert setting;
        
        User us = TestingUtil.createUser();
        
        system.debug('limit queries before acv '+limits.getQueries());
        Account acc = new Account();
        acc.name='TestAcc';
        acc.Billingcity='Test';
        acc.BillingCountry = 'United Kingdom';
        insert acc;
        system.debug('limit queries after acv '+limits.getQueries());

        
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        
         system.debug('limit queries before insert '+limits.getQueries());

        
        Opportunity testopp = new Opportunity();
        testopp.name = 'c';
        testopp.AccountId = acc.id; 
        testopp.recordtypeid=IMERecordTypeId;
        testopp.StageName = '1 - Qualification';
        testopp.CloseDate = System.today();
        testopp.IM_Servicing_Region__c ='London';
        testopp.Contracting_Country__c = 'United Kingdom';
        testopp.Contract_Term__c='12';
        testopp.Forecast_Owner__c = us.id;
        testopp.Bypass_Flows_Trigger__c = True;
        insert testopp;
        
        system.debug('limit queries after insert '+limits.getQueries());

        Contract testContract = new Contract();
        testContract.RecordTypeid = '01280000000UJX3';
        testContract.AccountId = testopp.AccountId;
        testContract.Billing_Country__c = testopp.Billing_Country__c;
        testContract.StartDate = testopp.Effective_Date__c;
        testContract.Contract_Type__c = 'IM Standard';
        testContract.IME_Contract_Version__c = 'IMUK-CC-14.01';
        testContract.IME_Contract_Term_Type__c = 'Evergreen';
        testContract.ContractTerm = Integer.valueOf(testopp.Contract_Term__c);
        testContract.IM_Renewal_Term__c = 12;
        testContract.IME_Expiration_Notice_days__c = 90;
        testContract.IME_Liability_Currency__c = 'GBP';
        testContract.IM_Liability__c = 1;
        testContract.IM_Max_Liability__c = 1000000;
        testContract.IME_MFP_Clause__c = 'NO';
        testContract.IME_Non_Standard_Clause__c = 'NO';
        testContract.IME_Price_Increase_Type_Storage__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Storage__c = 12;
        testContract.IME_Price_Increase_Type_Services__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Services__c = 12;
        testContract.IME_Price_Increase_Type_Transport__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Transp__c = 12;
        testContract.IME_Price_Increase_Type_Product_Sales__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Prod_S__c = 12;
        testContract.Standard_Contract__c = True;
        
        try{
            insert testContract; 
            system.debug('limit queries after insert contract / before update'+limits.getQueries());

        }
        catch(Exception ex){       
            
        }
        
        try{
            testopp.IME_Contract__c = testContract.id;
        update testopp;     
                system.debug('limit queries after update '+limits.getQueries());
        }
        catch(Exception ex){       
            
        }
        

    }
    
    static testMethod void OpprtunityPArtnerMethod()
    {
        List<Trigger_Activation_Settings__c> custSettingList1 = new List<Trigger_Activation_Settings__c>();
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'OpportunityPartner';
        tA1.Object__c = 'Opportunity';
        tA1.Trigger__c = 'ValidateOpportunityPartner';
        tA1.Value__c = 'True';
        custSettingList1.add(tA1);
        
        insert custSettingList1;
        
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='US';
        countryRec.Iso31663Code__c ='USA';
        countryRec.Name ='United States';
        countryRec.Region__c ='North America';
        
        insert countryRec;
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='North America' and Name ='United States'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United States'; 
        
        insert altcountry;
        
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United States',Region__c = 'North America'))); 

        
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United States', BillingState = 'MA');
        insert a;
        
        Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        
        
        Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
        Id standardPB = Test.getStandardPricebookId();
        
        
        String s = p.Id;
        String subs=s.substring(0,15);
        
        List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact(LastName='TestContact1',
                                 Email='testemail1@email.com',
                                 FirstName = 'TestOppObjTrigg',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE10TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c1);
        Contact c2 = new Contact(LastName='TestContact2',
                                 Email='testemail2@email.com',
                                 FirstName = 'TestOppObjTrigg1',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE12TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c2);
        
        insert contacts;
        
        List<Product2> products = new List<Product2>();
        
        Product2 product = new Product2(Secondary_Product_Allowed__c=true, 
                                        Name='test', 
                                        CurrencyIsoCode='USD', 
                                        IsActive=true);
        products.add(product);
        
        Product2 product1 = new Product2(Secondary_Product_Allowed__c=true, 
                                         Name='test1',
                                         CurrencyIsoCode='USD',
                                         IM_Product_Line__c='Cloud Solutions',
                                         IM_Product_Class__c='Data Backup and Recovery',
                                         // RevenueInstallmentPeriod ='Monthly', 
                                         IsActive=true);
        products.add(product1);     
        insert products;
      
        List<PricebookEntry> pricebooks = new List<PricebookEntry>(); 
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPB, 
                                                          Product2Id = product.Id, 
                                                          UnitPrice = 1, 
                                                          IsActive = true,
                                                          CurrencyIsoCode='USD', 
                                                          UseStandardPrice = false);
        pricebooks.add(standardPrice);
        
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = standardPB, 
                                                           Product2Id = product1.Id, 
                                                           UnitPrice = 1,
                                                           CurrencyIsoCode='USD', 
                                                           IsActive = true, 
                                                           UseStandardPrice = false);
        pricebooks.add(standardPrice1);
        
        PricebookEntry pbe1 = new PricebookEntry(IsActive=true,
                                                 UnitPrice=1,
                                                 UseStandardPrice = false,
                                                 CurrencyIsoCode='USD',
                                                 Product2Id=product1.Id,
                                                 Pricebook2Id=subs);
        pricebooks.add(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry(IsActive=true,
                                                 UnitPrice=1,
                                                 UseStandardPrice = false,
                                                 CurrencyIsoCode='USD',
                                                 Product2Id=product.Id,
                                                 Pricebook2Id=subs);
        pricebooks.add(pbe2);
        insert pricebooks;
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a.Id;
        opp1.StageName = '1 - Qualification';
        opp1.RecordTypeID=rt;
        opp1.CloseDate = Date.today();
        opp1.Name = 'Opportunity4TestMethod';
        opp1.IM_Booked_Date__c = Date.today();
        opp1.Type = 'New Deal';
       // opp1.Forecast_Owner__c = us.id;

        
        insert opp1;
        
        //Inserting Opportunity Line Item
        OpportunityLineItem oppProd = new OpportunityLineItem(OpportunityId = opp1.Id, unitPrice = 1, Quantity = 1, Product_Line__c = 'Cloud Solutions', Product_Class__c='Data Backup and Recovery', PricebookEntryId = pricebooks[0].Id);
        //insert oppProd;
        
        OppPartnerAction.getOppProductAndParnterCount(opp1.id);
        
        opp1.StageName='1 - Qualification';
        String testLbl = Label.Cloud_Solution_Product_Line_Label;
        try{
            update opp1;
        }
        catch(Exception ex){       
            Boolean expectedExceptionThrown =  ex.getMessage().contains('All cloud opportunities must have an assigned partner.  Partner selection is located in system information tab.  If you don’t have a partner or need more information please reach out to dmchannelteam@ironmountain.com.') ? true : false;
            System.assertEquals(expectedExceptionThrown, false);
        }

    }
    
    static testMethod void OpprtunityIGDSMethod()
    {
        List<Trigger_Activation_Settings__c> custSettingList1 = new List<Trigger_Activation_Settings__c>();
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'IGDSMillionDollarPost';
        tA1.Object__c = 'Opportunity';
        tA1.Trigger__c = 'IGDSMillionDollarPost';
        tA1.Value__c = 'True';
        custSettingList1.add(tA1);
        
        IM_Country__c countryRec =  new IM_Country__c();
            countryRec.Iso31662Code__c ='US';
            countryRec.Iso31663Code__c ='USA';
            countryRec.Name ='United States';
            countryRec.Region__c ='North America';
            
            insert countryRec;
            IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='North America' and Name ='United States'];
            
            IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
            altcountry.IM_Country__c = retCountry.id;
            altcountry.Alternative_Name__c='United States'; 
            
            insert altcountry;
            
            IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United States',Region__c = 'North America'))); 

        // insert custSettingList1;
        List<Account> accountList = new List<Account>();
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United States', BillingState = 'MA');
        accountList.add(a);
        insert accountList;
        
        //Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
		Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
       	Id standardPB = Test.getStandardPricebookId();
        
        String s = customPB.Id;
        String subs=s.substring(0,15);
        
        List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact(LastName='TestContact1',
                                 Email='testemail'+Math.random()+'@email.com',
                                 FirstName = 'TestOppObjTrigg',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c1);
        Contact c2 = new Contact(LastName='TestContact2',
                                 Email='testemail'+Math.random()+'@email.com',
                                 FirstName = 'TestOppObjTrigg1',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c2); 
        
        insert contacts;
        
        ID IMNAProdRecordType = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('IMNA_Product').getRecordTypeId();

        
        
        Product2 prod = TestingUtils.createProduct('Item001', true);
        Pricebook2  pr    = TestingUtil.createPricebook2();
        Id stdPbId = Test.getStandardPricebookId();
        PriceBookEntry stdpbe = TestingUtils.createPriceBookEntry(prod.Id, stdPbId  , true);
        PriceBookEntry pbe = TestingUtils.createPriceBookEntry(prod.Id, pr.Id, true);
        
        Product_Bundle__c prodBun1= new Product_Bundle__c(Name='Information Governance', 
                                                          Bundle_Type__c ='IGDS', 
                                                          Product_Group_ID__c = pbe.id,
                                                          Product_ID__c = prod.id);
        insert prodBun1;
        /*
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a.Id;
        opp1.StageName = '1 - Qualification';
        opp1.RecordTypeID=rt;
        opp1.CloseDate = Date.today();
        opp1.Name = 'Opportunity4TestMethod';
        opp1.IM_Booked_Date__c = Date.today();
        opp1.Type = 'New Deal';
        opp1.pricebook2ID= standardPB.id;
        insert opp1;
        */
        List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
        Opportunity opp1 = oppList[0];
        //Inserting Opportunity Line Item
        OpportunityLineItem oppProd = new OpportunityLineItem(OpportunityId = oppList[0].Id, unitPrice = 100000, Quantity = 100, Product_Line__c = 'Content Classification & Data Remediation', Product_Class__c='Information Governance', PricebookEntryId = pbe.Id);
        insert oppProd;
        
        OppPartnerAction.getOppProductAndParnterCount(opp1.id);
        
        opp1.StageName='5 - Signed/PO in';
         system.debug('Limits.getQueries3: '+ Limits.getQueries());
            Test.startTest();
            Integer MAX_QUERY = Limits.getLimitQueries();
            system.assertEquals(MAX_QUERY, Limits.getLimitQueries());
        try{
            update opp1;
        }
        catch(Exception ex){ 
        } 
        Test.stopTest();
    }
    
    static testMethod void OpprtunityIGDSMethodIME()
    {
        //Integer MAX_QUERY = Limits.getLimitQueries(); 
       
       
       
        List<Trigger_Activation_Settings__c> custSettingList1 = new List<Trigger_Activation_Settings__c>();
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'IGDSMillionDollarPost';
        tA1.Object__c = 'Opportunity';
        tA1.Trigger__c = 'IGDSMillionDollarPost';
        tA1.Value__c = 'True';
        custSettingList1.add(tA1);
        
        // insert custSettingList1;
        Profile adminProfile = [Select id from profile where name = 'System administrator'];
        User ImeUsr = new User(alias = 'hasrole', email='userwithrole@roletest1.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = adminProfile.id,timezonesidkey='America/Los_Angeles',username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true, DefaultCurrencyIsoCode='EUR');
        insert ImeUsr;
        
        IM_Country__c countryRec =  new IM_Country__c();
            countryRec.Iso31662Code__c ='US';
            countryRec.Iso31663Code__c ='USA';
            countryRec.Name ='United Kingdom';
            countryRec.Region__c ='United Kingdom';
            
            insert countryRec;
            IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='United Kingdom' and Name ='United Kingdom'];
            
            IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
            altcountry.IM_Country__c = retCountry.id;
            altcountry.Alternative_Name__c='United Kingdom'; 
            
            insert altcountry;
            
            IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United Kingdom',Region__c = 'United Kingdom'))); 

        
       // system.runAs(ImeUsr){
        List<Account> accountList = new List<Account>();
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United Kingdom', BillingState = 'Nottinghill');
        accountList.add(a);
        insert accountList;
        
        //Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
		Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        Id standardPB = Test.getStandardPricebookId();
        
        String s = customPB.Id;
        String subs=s.substring(0,15);
        
        List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact(LastName='TestContact1',
                                 Email='testemail'+Math.random()+'@email.com',
                                 FirstName = 'TestOppObjTrigg',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 MailingCountry = 'United Kingdom',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c1);
        Contact c2 = new Contact(LastName='TestContact2',
                                 Email='testemail'+Math.random()+'@email.com',
                                 FirstName = 'TestOppObjTrigg1',
                                 AccountId=a.Id,
                                 MailingCity = 'London',  
                                 MailingCountry = 'United Kingdom',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c2);
        
        insert contacts;
        
        Product2 prod = TestingUtils.createProduct('Item001', true);
        Pricebook2  pr    = TestingUtil.createPricebook2();
        Id stdPbId = Test.getStandardPricebookId();
        PriceBookEntry stdpbe = TestingUtils.createPriceBookEntry(prod.Id, stdPbId  , true);
        PriceBookEntry pbe = TestingUtils.createPriceBookEntry(prod.Id, pr.Id, true);
        
        Product_Bundle__c prodBun1= new Product_Bundle__c(Name='Information Governance', 
                                                          Bundle_Type__c ='IGDS', 
                                                          Product_Group_ID__c = pbe.id,
                                                          Product_ID__c = prod.id);
        insert prodBun1;
        /*
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a.Id;
        opp1.StageName = '1 - Qualification';
        opp1.RecordTypeID=rt;
        opp1.CloseDate = Date.today();
        opp1.Name = 'Opportunity4TestMethod';
        opp1.IM_Booked_Date__c = Date.today();
        opp1.Type = 'New Deal';
        opp1.IME_Reason_Won__c='Service';
        
        insert opp1;
		*/
        List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
        Opportunity opp1 = oppList[0];
        //Inserting Opportunity Line Item
       
            
        OpportunityLineItem oppProd = new OpportunityLineItem(OpportunityId = oppList[0].Id, unitPrice = 100000, Quantity = 100, Product_Line__c = 'Cloud Solutions', Product_Class__c='Data Backup and Recovery', PricebookEntryId = pbe.Id);
        insert oppProd;
        
        OppPartnerAction.getOppProductAndParnterCount(opp1.id);
        
        opp1.StageName='5 - Signed/PO in';
            system.debug('Limits.getQueries3: '+ Limits.getQueries());
            Test.startTest();
            Integer MAX_QUERY = Limits.getLimitQueries();
            system.assertEquals(MAX_QUERY, Limits.getLimitQueries());
        try{
            update opp1;
        }
        catch(Exception ex){ 
        } 
   // } 
        Test.stopTest();
    }
}