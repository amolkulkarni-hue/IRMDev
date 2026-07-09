/*
Auhtor      : Nagesh Ganji
Created Date: Apr 5,2010
Description : Tester utility class for Opportunity owner info update scheduler class(OpportunityOwnerInfoScheduler)
*/ 

@istest
private class test_OpportunityOwnerInfoScheduler {
    
    public static Account testAccount1;
    public static Opportunity testOpp1;
    public static List<Opportunity> lstOp = new List<Opportunity>();
    public static Database.SaveResult[] srList ;
    static testmethod void myUnitTest() {
        setup();
        /*
IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
( (new IM_Country__c(name = 'United Kingdom',
Region__c = 'Europe')));
Test.startTest();
triggerFlowControl.setControlEnabled(false);

Account A = new Account(name='Account4TestMethod');
insert A;

//Create a new Opportunity
Opportunity opp1 = new Opportunity();
opp1.AccountId = A.Id;
opp1.Name = 'Opportunity4TestMethod';
opp1.CloseDate = Date.today();
opp1.StageName = '1 - Qualification';
opp1.Type = 'Renewal';
opp1.Lead_Source_Most_Recent__c = 'Email';


insert opp1;
*/
        //Create a Lead and convert to create an Opportunity 
        Test.startTest();
        Lead l = new Lead();
        Id imeRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('IME Lead').getRecordTypeId();        
        l.LastName = 'Lead4UnitTest';
        l.Company = 'Account4UnitTest';
        l.FirstName = 'Lead';
        l.IM_Lead_Source_Most_Recent__c = 'Email';
        l.IM_Lead_Stage__c = '1-Inquiry';        
        l.IM_Lead_Stage__c = '1-Inquiry';
        l.Email = 'testemail@email.com';
        l.Phone = '1112223333';
        l.Street = 'TestStreet';
        l.City = 'London';
        l.State = 'MA';
        l.Country = 'United Kingdom';
        l.PostalCode = '02111';
        l.RecordTypeId = imeRecTypeId;     
        l.IM_Functional_Area__c = 'x';
        
        
        triggerFlowControl.setControlEnabled(true);
        insert l;
        
        Campaign c = new Campaign(name='Campaign4UnitTest');
        insert c;
        
        CampaignMember cm = new CampaignMember();
        cm.CampaignId = c.Id;
        cm.LeadId = l.Id;
        insert cm;
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l.id);
        
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        //Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        
        // Schedule the test job  
        String jobId = System.schedule('testOptyOwnerInfoUpdateSchdl','0 15 16 9 5 ? 2025',
                                       new OpportunityOwnerInfoScheduler ());
        
        // Get the information from the CronTrigger API object  
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same  
        System.assertEquals('0 15 16 9 5 ? 2025', ct.CronExpression);
        
        // Verify the job has not run  
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest();
        
        
        
    }
    public static testMethod void testschedule() {
        Test.StartTest();
        OpportunityOwnerInfoScheduler sh1 = new OpportunityOwnerInfoScheduler();
        OpportunityOwnerInfoBatchUpdateTest.setup();
        String sch = '0 0 23 * * ?'; system.schedule('Test OpportunityOwnerInfoScheduler Check', sch, sh1); 
        Test.stopTest(); 
    }
    
    public static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country; 
        triggerFlowControl.setControlEnabled(false);
        testAccount1 = new Account();
        testAccount1.Name = 'TestAccount1';
        testAccount1.BillingCountry = 'United States';
        testAccount1.BillingPostalCode = '11209';
        testAccount1.BillingState = 'NY'; 
        testAccount1.BillingCity = 'Ancaster';
        testAccount1.BillingStreet ='1142 Wilson St W';
        insert testAccount1;
        
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel; 
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        Profile p = [Select id from profile where name = 'IM_Custom Sys Admin'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        IM_Country__c cntry1 = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'Denmark',
                                 Region__c = 'Asia Pacific')));
        
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        Id standardPB = Test.getStandardPricebookId();
        testOpp1 = new Opportunity(
            name = 'Opportunity4TestMethod'
            ,Source_System__c = 'Other Europe'
            ,Billing_Country__c = cntry.id 
            ,Lead_Source_Most_Recent__c = 'Email'
            ,Type = 'Renewal'
            ,StageName = '1 - Qualification'
            ,IM_Servicing_Region__c ='London'
            ,IME_Reason_Won__c = 'Benchmarking'
            ,AccountId = testAccount1.Id   
            ,IM_Booked_Date__c = System.today(),
            CloseDate= system.today()
            ,RecordTypeId = EUOppType.Id,
            IM_Commit_to_Forecast__c = true
            ,IM_Stage_5_Entered_Date__c  = System.today()
            ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,Owner_Email__c='testOpp1@testOpp1.com'
        );
        insert testOpp1;
    }
    
}