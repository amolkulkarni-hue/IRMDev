// Commented out the code as part of #16286. This test class is merged into OpportunityTrigger_Test
@isTest
public class Test_OpportunityObjectTrigger {
    
    static testMethod void TestpopulateOptyOwnerInfo() {
       /*List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
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
        
        List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        insert opprodsel;
        
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
            
            Opportunity opp = new Opportunity(name = 'c', AccountId = acc.id, Source_System__c = 'SKP', Billing_Country__c = retCountry.id 
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
                                              ,IM_Up_Sell_Detail__c = 'details'
                                              ,IM_Up_Sell_Quantity__c = 2
                                              ,Upsell_Customer_ID__c = cusAcc.id
                                              ,IM_Unit_of_Measure__c = 'Data Restoration'
                                              //,Commissionable_Window_Close_Date__c = null
                                              ,SKP_Opportunity_Sync_Date__c = null
                                              ,GSA_Eligibility__c = 'GSA Eligible'
                                              ,IM_Booked_Date__c=System.today()
                                             );
            
            insert opp;
            
            
            
            
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
            update opp;
            
            opp.GSA_Eligibility__c = 'GSA Eligible';
            update opp;
            
            
        }
        
        
        
    }
    
    static testMethod void IMEOpprtunityMethod()
    {
        IM_Country__c testCountry = new IM_Country__c(Name='United Kingdom');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United Kingdom');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United Kingdom';
        setting.object_name__c = 'Account';
        insert setting;
        Account acc = new Account();
        acc.name='TestAcc';
        acc.Billingcity='Test';
        acc.BillingCountry = 'United Kingdom';
        insert acc;
        
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        
        Opportunity testopp = new Opportunity();
        testopp.name = 'c';
        testopp.AccountId = acc.id; 
        testopp.recordtypeid=IMERecordTypeId;
        testopp.StageName = '1 - Qualification';
        testopp.CloseDate = System.today();
        testopp.IM_Servicing_Region__c ='London';
        testopp.Contracting_Country__c = 'United Kingdom';
        testopp.Contract_Term__c='12';
        insert testopp;
        
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
        }
        catch(Exception ex){       
            
        }
        
        testopp.IME_Contract__c=testContract.id;
        update testopp;     
        
    }
    
    @isTest(SeeAllData=true)
    static void OpprtunityPArtnerMethod()
    {
        List<Trigger_Activation_Settings__c> custSettingList1 = new List<Trigger_Activation_Settings__c>();
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'OpportunityPartner';
        tA1.Object__c = 'Opportunity';
        tA1.Trigger__c = 'ValidateOpportunityPartner';
        tA1.Value__c = 'True';
        custSettingList1.add(tA1);
        
        insert custSettingList1;
        
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United States', BillingState = 'MA');
        insert a;
        
        Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
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
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPB.Id, 
                                                          Product2Id = product.Id, 
                                                          UnitPrice = 1, 
                                                          IsActive = true,
                                                          CurrencyIsoCode='USD', 
                                                          UseStandardPrice = false);
        pricebooks.add(standardPrice);
        
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = standardPB.Id, 
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
            System.assertEquals(expectedExceptionThrown, true);
        }
        
        
        
    }    
    
    
    @isTest(SeeAllData=true)
    static void OpprtunityIGDSMethod()
    {
        List<Trigger_Activation_Settings__c> custSettingList1 = new List<Trigger_Activation_Settings__c>();
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'IGDSMillionDollarPost';
        tA1.Object__c = 'Opportunity';
        tA1.Trigger__c = 'IGDSMillionDollarPost';
        tA1.Value__c = 'True';
        custSettingList1.add(tA1);
        
        // insert custSettingList1;
        List<Account> accountList = new List<Account>();
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United States', BillingState = 'MA');
        accountList.add(a);
        insert accountList;
        
        //Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
		Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
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
       /* List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
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
    
     @isTest(SeeAllData=true)
    static void OpprtunityIGDSMethodIME()
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
       // system.runAs(ImeUsr){
        List<Account> accountList = new List<Account>();
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United Kingdom', BillingState = 'Nottinghill');
        accountList.add(a);
        insert accountList;
        
        //Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
		Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
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
       /* List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
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
    } */
    }
    
}