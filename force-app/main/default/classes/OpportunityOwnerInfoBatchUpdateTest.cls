/**
* Class: OpportunityOwnerInfoBatchUpdateTest
*
* Author: TCS
*
* Purpose: Test class for OpportunityOwnerInfoBatchUpdate
*
* Requirement: GitLab * #5164  
*
* Change History:
*
* Developer  : Praneel Patalay                   Date : 13/Feb/2022	             		
* Description : This test class for OpportunityOwnerInfoBatchUpdate
* Modification: 
* Modification Date: 
* Modified By: 
* -------------------------------------------------------------------------------------------
* 
*/


@isTest
public class OpportunityOwnerInfoBatchUpdateTest {
    public static Account testAccount1;
    public static Account testAccount2;
    public static Account testAccountIMGA1;
    public static Account testAccountIMGA2;
    public static Opportunity testOpp1;
    public static Opportunity testOpp2;
    public static Opportunity testOpp3;
    public static Opportunity testOpp4; //KUldeep
    public static List<Opportunity> lstOp = new List<Opportunity>();
    public static Database.SaveResult[] srList ;
    public static void setup() 
    {   
       
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country; 
        testAccount1 = new Account();
        testAccount1.Name = 'TestAccount1';
        testAccount1.BillingCountry = 'United States';
        testAccount1.BillingPostalCode = '11209';
        testAccount1.BillingState = 'NY'; 
        testAccount1.BillingCity = 'Ancaster';
        testAccount1.BillingStreet ='1142 Wilson St W';
        insert testAccount1;
        testAccount2 = new Account();
        testAccount2.Name = 'TestAccount2';
        testAccount2.BillingCountry = 'United States';
        testAccount2.BillingPostalCode = '11209';
        testAccount2.BillingState = 'NY';   
        insert testAccount2;
        testAccount2.ParentId = testAccount1.id;
        
        testAccountIMGA1 = new Account();
        testAccountIMGA1.Name = 'testAccountIMGA1';
        testAccountIMGA1.BillingCountry = 'United States';
        testAccountIMGA1.BillingPostalCode = '11209';
        testAccountIMGA1.BillingState = 'NY';   
        testAccountIMGA1.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
        insert testAccountIMGA1;
        testAccountIMGA2 = new Account();
        testAccountIMGA2.Name = 'testAccountIMGA2';
        testAccountIMGA2.BillingCountry = 'United States';
        testAccountIMGA2.BillingPostalCode = '11209';
        testAccountIMGA2.BillingState = 'NY';   
        insert testAccountIMGA2;
        
        
        
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
        User u = new User(alias = 'hasrole1', email='userwithrolez@roletest1.com'
                          ,emailencodingkey='UTF-8'
                          , lastname='Testing1', languagelocalekey='en_US'
                          , localesidkey='en_US', profileid = p.id
                          , timezonesidkey='America/Los_Angeles'
                          , username='userwithrole1@testorg.com'
                          , Country = 'United Kingdom');
        
        insert u;
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        RecordType EUOppType1 = [select id from RecordType
                                 where name = 'IME Standard Opportunity'
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
            name = 'TestOpp1'
            ,Source_System__c = 'Other Europe'
            ,Billing_Country__c = cntry.id 
            ,Lead_Source_Most_Recent__c = 'x'
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
        lstOp.add(testOpp1);
        //insert testOpp1;
        system.debug('account id'+testOpp1.id);
        system.debug('u id'+u.id);
        system.runAs(u){
            testOpp2 = new Opportunity(
                name = 'TestOpp2'
                ,Source_System__c = 'SKP Europe'
                ,Billing_Country__c = cntry1.id 
                ,Lead_Source_Most_Recent__c = 'x'
                ,StageName = '1 - Qualification'
                ,IM_Servicing_Region__c ='London'
                ,IME_Reason_Won__c = 'Benchmarking'
                ,AccountId = testAccount2.Id   
                ,IM_Booked_Date__c = System.today(),
                CloseDate= system.today()
                ,RecordTypeId = EUOppType1.Id,
                IM_Commit_to_Forecast__c = true
                ,IM_Stage_5_Entered_Date__c  = System.today()
                ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,IM_Original_Lead_Owner__c = u.id,Owner_Email__c='testOpp2@testOpp2.com'
            );
            lstOp.add(testOpp2);
            // insert testOpp2;
        }
        
        testOpp3 = new Opportunity(
            name = 'TestOpp3'
            ,Source_System__c = 'SKP Europe'
            ,Billing_Country__c = cntry1.id 
            ,Lead_Source_Most_Recent__c = 'x'
            ,StageName = '1 - Qualification'
            ,IM_Servicing_Region__c ='London'
            ,IME_Reason_Won__c = 'Benchmarking'
            ,AccountId = testAccount1.Id   
            ,IM_Booked_Date__c = System.today(),
            CloseDate= system.today()
            ,RecordTypeId = EUOppType1.Id,
            IM_Commit_to_Forecast__c = true
            ,IM_Stage_5_Entered_Date__c  = System.today()
            ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,IM_Original_Lead_Owner__c = u.id,Owner_Email__c='testOpp3@testOpp3.com'
        );
        lstOp.add(testOpp3);
        
        srList = database.insert(lstOp);
        
        /* testOpp4 = new Opportunity(
name = 'TestOpp4'
,Source_System__c = 'SKP Europe'
,Billing_Country__c = cntry1.id 
,Lead_Source_Most_Recent__c = 'x'
,StageName = '1 - Qualification'
,IM_Servicing_Region__c ='London'
,IME_Reason_Won__c = 'Benchmarking'
,AccountId = testAccount1.Id   
,IM_Booked_Date__c = System.today(),
CloseDate= system.today()
,RecordTypeId = EUOppType1.Id,
IM_Commit_to_Forecast__c = true
,IM_Stage_5_Entered_Date__c  = System.today()
,CurrencyIsoCode='GBP',pricebook2ID= standardPB,IM_Original_Lead_Owner__c = u.id
);
*/
    }
    
    public static testmethod void unitTest() {
        setup();
        String objName = 'Opportunity';
        Test.StartTest();       
        //OpportunityOwnerInfoBatchUpdate b = new OpportunityOwnerInfoBatchUpdate (initialQuery);
        String Query='SELECT Id FROM ' + objName + ' WHERE CreatedDate >= YESTERDAY LIMIT 20';
        OpportunityOwnerInfoBatchUpdate b = new OpportunityOwnerInfoBatchUpdate (Query);
        ID batchprocessid = Database.executeBatch(b,20);
        Test.StopTest();        
    }
}