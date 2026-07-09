@isTest
public class OpportunityLineItemHelper_Test {
    static testMethod void UnitTest1_Standard_opp()  {
        
        
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
        
        List<LineItemsSync__c> CustomSettingData=LineItemsSync__c.getAll().Values();
        if(CustomSettingData.isEmpty()){
            LineItemsSync__c temp=new LineItemsSync__c();
            temp.name='Test';
            temp.Opportunity_Product_API_Name__c='Name';
            temp.Quote_Line_Item_API_Name__c='Name';
            temp.Pricing_Contract_Entry_API_Name__c='Name';
            insert temp;
        } 
        
        SVStatus__c SVCustom = new SVStatus__c();
        SVCustom.name='SVStatusPassed';
        SVCustom.Amount__c=24000;
        SVCustom.OpptType__c='Up-Sell/Lift';
        SVCustom.Stage__c='6 - Setup';
        insert SVCustom;
        
        Test.startTest();   
        
        List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        
        insert opprodsel;
        
        Opportunity_Product_Wizard_Settings__c profiles= new Opportunity_Product_Wizard_Settings__c();
        profiles.Name='IM_Account Manager';
        profiles.Product_Group_Name__c='IM_Account Manager';
        profiles.Profile_Name__c='North America';
        insert profiles;
        
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
        
        Profile p = [Select id from profile where name = 'System administrator']; 
        User us = new User(alias = 'hasrole', email='userwithrole@roletest1.com',
                           emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',
                           localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',
                           username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true);
        insert us;
        
        System.runAs(us)
        {
            RecordType EUOppType = [select id from RecordType where name = 'Standard Opportunity' and  sObjectType = 'Opportunity'];
            //IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United States',Region__c = 'North America'))); 
            
            List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 
            accountList[0].BillingCountry='India';
            update accountList;
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
            
            //account acc = new Account(name='x',BillingCountry = 'United States', IMGA_Owner__c = us.id);
            //insert acc;
            
            IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            cusAcc.Name = 'testSold';
            cusAcc.IM_Account__c = accountList[0].id;
            cusAcc.Source_System__c = 'Other Europe';
            
            insert cusAcc;
            
           /* Opportunity opp = new Opportunity(name = 'c', AccountId = acc.id, Source_System__c = 'SKP', Billing_Country__c = cntry.id 
                                              ,Lead_Source_Most_Recent__c = 'x'
                                              //,StageName = '7 - Closed'
                                              ,StageName = '1 - Qualification'
                                              ,RecordTypeId = EUOppType.Id
                                              ,IM_Servicing_Region__c ='London'
                                              ,IM_Commit_to_Forecast__c = true
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
                                              ,US_Federal_GSA_Pricing__c ='Yes'
                                              ,Amount=1000.00
                                              ,GSA_Eligibility__c = 'GSA Eligible'
                                              ,IM_Booked_Date__c=System.today()-1
                                             );//Up-Sell/Lift
            
            insert opp;*/
            /*   opp.StageName = '2 - Solution Developed';
update opp;
*/
            
            
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
            
            //insert opportunitylineitem
            List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
            OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].Id, unitPrice = 1,Product_Class__c ='Records Management',Product_Line__c='storage');
            insert oppProd;//insert event of Trigger is called.
            delete oppProd;
            
            //    OpportunityLineItem oppProd1 = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = Opp.Id, unitPrice = 1);
            //       insert oppProd1;
            
            //  insLinItems.add(oppProd);
            //    insLinItems.add(oppProd1);*/
            
            //   insert insLinItems;
            
        }
        
    }
    static testMethod void UnitTest2_Standard_opp()  {
        
        
        
        //Insert Trigger Execution settings
        List<Trigger_Execution_Settings__c> customsettings = new List<Trigger_Execution_Settings__c>();
        
        
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
        
        List<LineItemsSync__c> CustomSettingData=LineItemsSync__c.getAll().Values();
        if(CustomSettingData.isEmpty()){
            LineItemsSync__c temp=new LineItemsSync__c();
            temp.name='Test';
            temp.Opportunity_Product_API_Name__c='Name';
            temp.Quote_Line_Item_API_Name__c='Name';
            temp.Pricing_Contract_Entry_API_Name__c='Name';
            insert temp;
        } 
        
        SVStatus__c SVCustom = new SVStatus__c();
        SVCustom.name='SVStatusPassed';
        SVCustom.Amount__c=24000;
        SVCustom.OpptType__c='Up-Sell/Lift';
        SVCustom.Stage__c='6 - Setup';
        insert SVCustom;
        
        Test.startTest();   
        
        List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        
        insert opprodsel;
        
        list<Opportunity_Product_Wizard_Settings__c> profilesLST= new list<Opportunity_Product_Wizard_Settings__c>();
        
        Opportunity_Product_Wizard_Settings__c profiles= new Opportunity_Product_Wizard_Settings__c();
        profiles.Name='IM_Custom Sys Admin';
        profiles.Product_Group_Name__c='North America';
        profiles.Profile_Name__c='IM_Custom Sys Admin';
        profilesLST.add(profiles);
        // insert profiles;
        
        Opportunity_Product_Wizard_Settings__c profiles1= new Opportunity_Product_Wizard_Settings__c();
        profiles1.Name='IM_Account Manager';
        profiles1.Product_Group_Name__c='IM_Account Manager';
        profiles1.Profile_Name__c='North America';
        profilesLST.add(profiles1);
        // insert profiles1;
        insert profilesLST;
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
        
        Profile p = [Select id from profile where name = 'IM_Custom Sys Admin']; 
        User us = new User(alias = 'hasrole', email='userwithrole@roletest1.com',
                           emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',
                           localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',
                           username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true);
        insert us;
        
        /*
*    System.runAs(us)
{
*/
        RecordType EUOppType = [select id from RecordType where name = 'Standard Opportunity' and  sObjectType = 'Opportunity'];
        /*IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United States',Region__c = 'North America'))); 
        
        account acc = new Account(name='x',BillingCountry = 'United States', IMGA_Owner__c = us.id);
        insert acc;*/
        
        List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 
            accountList[0].BillingCountry='India';
            update accountList;
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
        
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name = 'testSold';
        cusAcc.IM_Account__c = accountList[0].id;
        cusAcc.Source_System__c = 'Other Europe';
        
        insert cusAcc;
        
        /*Opportunity opp = new Opportunity(name = 'c', AccountId = acc.id, Source_System__c = 'SKP', Billing_Country__c = cntry.id 
                                          ,Lead_Source_Most_Recent__c = 'x'
                                          //,StageName = '7 - Closed'
                                          ,StageName = '1 - Qualification'
                                          ,RecordTypeId = EUOppType.Id
                                          ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
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
                                          ,US_Federal_GSA_Pricing__c ='Yes'
                                          ,Amount=1000.00
                                          ,GSA_Eligibility__c = 'GSA Eligible'
                                          ,IM_Booked_Date__c=System.today()-1
                                         );//Up-Sell/Lift
        
        insert opp;*/
        /*   opp.StageName = '2 - Solution Developed';
update opp;
*/
        
        
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
        
        //insert opportunitylineitem
        
        List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].Id, unitPrice = 1,Product_Class__c ='Records Management',Product_Line__c='storage');
        insert oppProd;//insert event of Trigger is called.
        //oppProd.Quantity=40;
        //  update oppProd;
        //              insert opp;OpportunityLineItem
        
        OpportunityLineItem old= [select id,Product_Line__c,Product_Class__c from OpportunityLineItem where OpportunityId =: oppList[0].Id];
        //system.debug('<<<<<508###OpportunityLineItem>>>>'+old);
        delete old;
        //   }
        
    }
}