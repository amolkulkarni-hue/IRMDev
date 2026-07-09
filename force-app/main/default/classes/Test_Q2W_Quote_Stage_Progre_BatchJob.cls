/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 7/3/2013
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : Test Utility Class. 
   
   Dependents        : Apex Class: Q2W_Quote_Stage_Progre_BatchJob,Q2W_Quote_Stage_Progre_Scheduler
   
   Case Number       : 00222919
   ********
   
   Modifications on 18/09/2014 by Sandhya Ramesh:
    Added Lead_Source_Most_Recent__c to Opp insert, 
    Added Stage__c and Proposed_Service_Discount__c.
   All test methods passed.
                                   
 ********************************/ 
 
 @isTest
 public class Test_Q2W_Quote_Stage_Progre_BatchJob{
     
     static testMethod void doTest(){
         

        
        // Create test Country Data with more robust approach
        IM_Country__c mainName = new IM_Country__c();
        mainName.Name = 'United States';
        //mainName.Country_Code__c = 'US'; // Add a country code if required
        insert mainName;
        
        // Alternative Country Name
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        country.IM_Country__c = mainName.Id;
        country.Alternative_Name__c = 'United States';
        insert country;
        
        // Country Settings
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        // Create Test Account with minimal required fields
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingState = 'NY';
        testAccount.BillingPostalCode = '10001';
        testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert testAccount;
        
          RecordType renewalOppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'NA Renewal' LIMIT 1];
     
        // Custom Setting Preparation
        Quote_Stage_Progression_Dates__c custData = new Quote_Stage_Progression_Dates__c();
        custData.Name = 'Test Custom Setting';
        custData.Next_Progression_Stage__c = 'Test Stage';
        custData.Progression_Date__c = Date.Today();
        insert custData;
        
        // Create Opportunity
        // 
     
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = testAccount.Id;
        opp.CloseDate = System.today().addMonths(3);
        opp.StageName = '1 - Qualification';
        opp.RecordTypeId = renewalOppRT.Id;
        //opp.Type = 'Renewal';
        opp.Lead_Source_Most_Recent__c = 'Email';
        opp.Billing_Country__c = mainName.Id;
        
        // Insert Opportunity
        insert opp;
         
          //insert Quote 
          //Quote Q=new Quote(Name='Test Quote',opportunityId=opp.id,Service_Renewal_Date__c=System.today().addMonths(3));
          Quote Q=new Quote(Name='Test Quote',opportunityId=opp.id,Stage__c='1 - Under Review', Proposed_Service_Discount__c=0);
          Insert Q;
         
          //sync opportunity and quote
          opp.SyncedQuoteId = Q.Id;
          update opp;
          
          Test.startTest();
              Q2W_Quote_Stage_Progre_Scheduler InstanceofClass = new Q2W_Quote_Stage_Progre_Scheduler();
              String sch = '0 0 20 * * ?';
              system.schedule('Stage Progression', sch, InstanceofClass);
              Q2W_Quote_Stage_Progre_BatchJob job=new Q2W_Quote_Stage_Progre_BatchJob('test stage');
              Database.executeBatch(job);
          Test.stopTest(); 
          
     }
 }