//@isTest(SeeAllData=true)
@isTest
private class Test_IMNA_InsertOpportunityMember

{
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

        insert new Trigger_Activation_Settings__c(name='createcustomeraccounts',Object__c='Opportunity', Trigger__c='createcustomeraccounts', Value__c='True');
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
    
    static testMethod void test1() 
    {    
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        
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
        
        Account a = new Account();
        a.name='TestAcc';
        a.Billingcity='Test';
        a.BillingCountry = 'United Kingdom';
        insert a;
        
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        
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
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
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
                                        ,IM_Booked_Date__c=System.today()
                                       );                                 
        insert o;
        
        
        Pricebook2 pb = new Pricebook2(Name='North America', isActive=true);
        insert pb;
        Id IMNARecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        Product2 prod = new Product2(Secondary_Product_Allowed__c=true, 
                                     Name='test1',
                                     CurrencyIsoCode='USD',
                                     IM_Product_Line__c='Cloud Solutions',
                                     IM_Product_Class__c='Data Backup and Recovery',
                                     // RevenueInstallmentPeriod ='Monthly',
                                     RecordTypeId = IMNARecordTypeId, 
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
        
        OpportunityLineItem oli = new OpportunityLineItem(PricebookEntryId= pbe.id, OpportunityId=o.id, Quantity=1, TotalPrice=1);
        
        insert oli;
        
        
        test.startTest();
        
        Contact cont = new contact(LastName = 'Test', FirstName = 'Test',Email = 'test.test@cgtest.com', AccountId=a.id);
        insert cont;
        
        OpportunityContactRole OCR =  new OpportunityContactRole( OpportunityId = o.Id, ContactId = cont.id, Role ='Business User  ');
        insert OCR;
        
        o.StageName = '5 - Signed/PO in';
        update o;
        
        o.Customer_Account_Number__c = System.now().format();
        o.StageName = '7 - Closed';
        update o;
        
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
    }   
}