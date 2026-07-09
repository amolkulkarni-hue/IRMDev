@istest(seeAllData=true)
public class Test_IME_OpportunityRollUpContract {
 
   static testMethod void runTest() {
       
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c=='Opportunity'){
                cs.Trigger__c = 'customrollupcontract';
                cs.Value__c='True';
            }
            updatesettings.add(cs);
        }
        update updatesettings;
        
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
   
        account a = new Account(name='x');
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
        
  
      Contract parentContract = new Contract(
           AccountId = a.id
        ,RecordTypeId ='01280000000UJX3'
          , Contract_Type__c = 'IM Standard'
           ,IME_Contract_Version__c = 'IMUK-CC-14.01'
           ,IME_Contract_Term_Type__c = 'Evergreen'
           ,ContractTerm = 12
           ,IM_Renewal_Term__c = 12
           ,IME_Expiration_Notice_days__c = 90
           ,IME_Liability_Currency__c = 'GBP'
           ,IM_Liability__c = 1
           ,IM_Max_Liability__c = 1000000
           ,IME_MFP_Clause__c = 'NO'
           ,IME_Non_Standard_Clause__c = 'NO'
        , IME_Price_Increase_Type_Storage__c ='Regular Increase'
       , IME_Fixed_Pricing_Period_months_Storage__c =12
        ,IME_Special_Terms_Other_Storage__c =''
        ,IME_Copy_to_all__c = false
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
       ,Standard_Contract__c = True
         ,IME_Records_Management_RM__c = true
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;      
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
       // parentContract.status = 'activated';
        
        update parentContract;
        /*
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
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
        ,CurrencyIsoCode='GBP'
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
       
       
        
        childContract .IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
       
        update childContract;
        
*/       
         test.startTest();
       
          List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 
            accountList[0].BillingCountry='India';
            update accountList;
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
                        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            cusAcc.Name = 'testSold';
            cusAcc.IM_Account__c = accountList[0].id;
            cusAcc.Source_System__c = 'Other Europe';
        insert cusAcc;
        
        Id testStandardPriceBook = Test.getStandardPricebookId();
       // Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
       
       Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
            insert customPB;
        
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = product.Id, 
                                                                    Pricebook2Id = testStandardPriceBook, 
                                                                    UnitPrice = 1, IsActive = true, 
                                                                    UseStandardPrice = false);
            insert testPriceBookEntry;
         PricebookEntry pbe_01 = new PricebookEntry(
                Pricebook2Id = customPB.Id, Product2Id = product.Id,
                UnitPrice = 12000, IsActive = true);
            insert pbe_01;
        
       // PricebookEntry pbe1 = [select id from PricebookEntry where CurrencyIsoCode='GBP' and IsActive= true   limit 1];
        
        //  Select o.PricebookEntryId, o.OpportunityId From OpportunityLineItem o
          List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
            OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].id, unitPrice = 1,Update_New_Revenue_Forecast__c =false);
            insert oppProd;
        
       /* OpportunityLineItem oli = new OpportunityLineItem(
            PricebookEntryId= pbe_01.Id,
            OpportunityId=o.id,
            Quantity=1,
            TotalPrice=1
        );
        
        insert oli; */
       
      /*  oppList.IME_Contract__c =parentContract.id;
        update oppList;
          
        oppList.IME_Contract__c = null ;
        update oppList; */
        test.stopTest(); 
        
    }
  
static testMethod void testUserCurrency() {
       
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c=='Opportunity'){
                cs.Trigger__c = 'customrollupcontract';
                cs.Value__c='True';
            }
            updatesettings.add(cs);
        }
        update updatesettings;
        
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
   
        account a = new Account(name='x');
        insert a;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode=UserInfo.getDefaultCurrency(), 
                IsActive=true);
        insert product;

        Contract parentContract = new Contract(
           AccountId = a.id
        ,RecordTypeId ='01280000000UJX3'
          , Contract_Type__c = 'IM Standard'
           ,IME_Contract_Version__c = 'IMUK-CC-14.01'
           ,IME_Contract_Term_Type__c = 'Evergreen'
           ,ContractTerm = 12
           ,IM_Renewal_Term__c = 12
           ,IME_Expiration_Notice_days__c = 90
           ,IME_Liability_Currency__c = 'GBP'
           ,IM_Liability__c = 1
           ,IM_Max_Liability__c = 1000000
           ,IME_MFP_Clause__c = 'NO'
           ,IME_Non_Standard_Clause__c = 'NO'
        , IME_Price_Increase_Type_Storage__c ='Regular Increase'
       , IME_Fixed_Pricing_Period_months_Storage__c =12
        ,IME_Special_Terms_Other_Storage__c =''
        ,IME_Copy_to_all__c = false
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
       ,Standard_Contract__c = True
         ,IME_Records_Management_RM__c = true
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        insert cca;
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        parentContract.status = 'activated';
        
        update parentContract;
        
         test.startTest();
    /*
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
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
        ,CurrencyIsoCode='GBP'
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
   
        Insert childContract;
      
        Contract_Customer_Account__c cca1= ContractHelperClass.CreateContractCustomer(childContract .id,cus.ID);
        insert cca1;
        
        childContract .IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
         
        update childContract;
        */
       
    
    
     List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 	
            accountList[0].BillingCountry='India';	
            update accountList;	
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);	
                        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();	
            cusAcc.Name = 'testSold';	
            cusAcc.IM_Account__c = accountList[0].id;	
            cusAcc.Source_System__c = 'Other Europe';	
        insert cusAcc;
    
      Id testStandardPriceBook = Test.getStandardPricebookId();
     Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);	
            insert customPB;
        
  // Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
      /*  PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = product.Id, 
            UnitPrice = 1, 
            IsActive = true,
            CurrencyIsoCode=UserInfo.getDefaultCurrency(), 
            UseStandardPrice = false);
        
        insert pbe; */
     PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = product.Id, 	
                                                                    Pricebook2Id = testStandardPriceBook, 	
                                                                    UnitPrice = 1, IsActive = true, 	
                                                                    UseStandardPrice = false);	
            insert testPriceBookEntry;	
         PricebookEntry pbe_01 = new PricebookEntry(	
                Pricebook2Id = customPB.Id, Product2Id = product.Id,	
                UnitPrice = 12000, IsActive = true);	
            insert pbe_01;
        
     
        List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     	
            OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].id, unitPrice = 1,Update_New_Revenue_Forecast__c =false);	
            insert oppProd;
    
       /* OpportunityLineItem oli = new OpportunityLineItem(
            PricebookEntryId= pbe.id,
            OpportunityId=o.id,
            Quantity=1,
            TotalPrice=1
        );
        
        insert oli; 
      
        oppProd.IME_Contract__c =parentContract.id;
        update oppProd;
          
        oppProd.IME_Contract__c = null ;
        update oppProd;  */

        test.stopTest(); 
        
    }   

      
static testMethod void testDeifferCurrency() {
       
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c=='Opportunity'){
                cs.Trigger__c = 'customrollupcontract';
                cs.Value__c='True';
            }
            updatesettings.add(cs);
        }
        update updatesettings;
        
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
   
        account a = new Account(name='x');
        insert a;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='CAD', 
                IsActive=true);
        insert product;
        
        
       Contract parentContract = new Contract(
           AccountId = a.id
        ,RecordTypeId ='01280000000UJX3'
          , Contract_Type__c = 'IM Standard'
           ,IME_Contract_Version__c = 'IMUK-CC-14.01'
           ,IME_Contract_Term_Type__c = 'Evergreen'
           ,ContractTerm = 12
           ,IM_Renewal_Term__c = 12
           ,IME_Expiration_Notice_days__c = 90
           ,IME_Liability_Currency__c = 'GBP'
           ,IM_Liability__c = 1
           ,IM_Max_Liability__c = 1000000
           ,IME_MFP_Clause__c = 'NO'
           ,IME_Non_Standard_Clause__c = 'NO'
        , IME_Price_Increase_Type_Storage__c ='Regular Increase'
       , IME_Fixed_Pricing_Period_months_Storage__c =12
        ,IME_Special_Terms_Other_Storage__c =''
        ,IME_Copy_to_all__c = false
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
       ,Standard_Contract__c = True
         ,IME_Records_Management_RM__c = true
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;
        
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
       // parentContract.status = 'activated';
        
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
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
        ,CurrencyIsoCode='GBP'
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
        childContract .IME_Annual_Value_Opportunities__c = 0;        
      // childContract .status = 'activated';        
      update childContract;
        
        
    	test.startTest();
      /*  Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode= 'CAD'
                                      //  ,IME_Contract__c = parentContract.id    
                                       );
        
        insert o; */
    
     List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 	
            accountList[0].BillingCountry='India';	
            update accountList;	
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);	
                        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();	
            cusAcc.Name = 'testSold';	
            cusAcc.IM_Account__c = accountList[0].id;	
            cusAcc.Source_System__c = 'Other Europe';	
        insert cusAcc;	
        	
        Id testStandardPriceBook = Test.getStandardPricebookId();
        
     Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);	
            insert customPB;
       
        
      /*  PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = product.Id, 
            UnitPrice = 1, 
            IsActive = true,
            CurrencyIsoCode='CAD', 
            UseStandardPrice = false);
        
        insert pbe;*/
    
     PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = product.Id, 	
                                                                    Pricebook2Id = testStandardPriceBook, 	
                                                                    UnitPrice = 1, IsActive = true, 	
                                                                    UseStandardPrice = false);	
            insert testPriceBookEntry;	
         PricebookEntry pbe_01 = new PricebookEntry(	
                Pricebook2Id = customPB.Id, Product2Id = product.Id,	
                UnitPrice = 12000, IsActive = true);	
            insert pbe_01;
        

      List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     	
            OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].id, unitPrice = 1,Update_New_Revenue_Forecast__c =false);	
            insert oppProd;    
    
       /* OpportunityLineItem oli = new OpportunityLineItem(
            PricebookEntryId= pbe.id,
            OpportunityId=o.id,
            Quantity=1,
            TotalPrice=1
        );
        
        insert oli;
      
        o.IME_Contract__c =parentContract.id;
        update o;
          
        o.IME_Contract__c = null ;
        update o; */

        test.stopTest(); 
        
    }   

 static testMethod void testContract() {
       
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c=='Opportunity'){
                cs.Trigger__c = 'customrollupcontract';
                cs.Value__c='True';
            }
            updatesettings.add(cs);
        }
        update updatesettings;
        
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
   
        account a = new Account(name='x');
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
        
  Contract parentContract = new Contract(
           AccountId = a.id
        ,RecordTypeId ='01280000000UJX3'
          , Contract_Type__c = 'IM Standard'
           ,IME_Contract_Version__c = 'IMUK-CC-14.01'
           ,IME_Contract_Term_Type__c = 'Evergreen'
           ,ContractTerm = 12
           ,IM_Renewal_Term__c = 12
           ,IME_Expiration_Notice_days__c = 90
           ,IME_Liability_Currency__c = 'GBP'
           ,IM_Liability__c = 1
           ,IM_Max_Liability__c = 1000000
           ,IME_MFP_Clause__c = 'NO'
           ,IME_Non_Standard_Clause__c = 'NO'
        , IME_Price_Increase_Type_Storage__c ='Regular Increase'
       , IME_Fixed_Pricing_Period_months_Storage__c =12
        ,IME_Special_Terms_Other_Storage__c =''
        ,IME_Copy_to_all__c = false
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
       ,Standard_Contract__c = True
         ,IME_Records_Management_RM__c = true
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
        insert cca;
        
        parentContract.IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
       // parentContract.status = 'activated';
        
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
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
        ,CurrencyIsoCode='GBP'
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
        Contract_Customer_Account__c cca1= ContractHelperClass.CreateContractCustomer(childContract .id,cus.ID);
        insert cca1;
        
        childContract .IME_Annual_Value_Opportunities__c = 0;
        //  parentContract.IME_Copy_to_all__c = false;
        childContract .status = 'activated';
        
        update childContract; 
        
         test.startTest();
       /* Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode= UserInfo.getDefaultCurrency()
                                          
                                       );
        
        insert o; */
       List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 
            accountList[0].BillingCountry='India';
            update accountList;
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
                        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            cusAcc.Name = 'testSold';
            cusAcc.IM_Account__c = accountList[0].id;
            cusAcc.Source_System__c = 'Other Europe';
        insert cusAcc;
        
     Id testStandardPriceBook = Test.getStandardPricebookId();
        
       // Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
      /*  PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = product.Id, 
            UnitPrice = 1, 
            IsActive = true,
            CurrencyIsoCode=UserInfo.getDefaultCurrency(), 
            UseStandardPrice = false);
        
        insert pbe;*/
      Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
            insert customPB;
       PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = product.Id, 
                                                                    Pricebook2Id = testStandardPriceBook, 
                                                                    UnitPrice = 1, IsActive = true, 
                                                                    UseStandardPrice = false);
            insert testPriceBookEntry;
         PricebookEntry pbe_01 = new PricebookEntry(
                Pricebook2Id = customPB.Id, Product2Id = product.Id,
                UnitPrice = 12000, IsActive = true);
            insert pbe_01;

        
       /* OpportunityLineItem oli = new OpportunityLineItem(
            PricebookEntryId= pbe.id,
            OpportunityId=o.id,
            Quantity=1,
            TotalPrice=1
        );
        
        insert oli; */
     
       List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
            OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].id, unitPrice = 1,Update_New_Revenue_Forecast__c =false);
            insert oppProd;
      
      // o.IME_Contract__c =parentContract.id;
      //  update o;      
	
        test.stopTest(); 
        
    }   
    
    static testMethod void testSameCurrency() {
       
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c=='Opportunity'){
                cs.Trigger__c = 'customrollupcontract';
                cs.Value__c='True';
            }
            updatesettings.add(cs);
        }
        update updatesettings;
        
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
   
        account a = new Account(name='x');
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
        

       Contract parentContract = new Contract(
           AccountId = a.id
        ,RecordTypeId ='01280000000UJX3'
          , Contract_Type__c = 'IM Standard'
           ,IME_Contract_Version__c = 'IMUK-CC-14.01'
           ,IME_Contract_Term_Type__c = 'Evergreen'
           ,ContractTerm = 12
           ,IM_Renewal_Term__c = 12
           ,IME_Expiration_Notice_days__c = 90
           ,IME_Liability_Currency__c = 'GBP'
           ,IM_Liability__c = 1
           ,IM_Max_Liability__c = 1000000
           ,IME_MFP_Clause__c = 'NO'
           ,IME_Non_Standard_Clause__c = 'NO'
        , IME_Price_Increase_Type_Storage__c ='Regular Increase'
       , IME_Fixed_Pricing_Period_months_Storage__c =12
        ,IME_Special_Terms_Other_Storage__c =''
        ,IME_Copy_to_all__c = false
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
       ,Standard_Contract__c = True
         ,IME_Records_Management_RM__c = true
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert parentContract;
        
        parentContract.IME_Annual_Value_Opportunities__c = 20;
        //  parentContract.IME_Copy_to_all__c = false;
       // parentContract.status = 'activated';
        
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
        ,IME_Price_Increase_Type_Services__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Services__c =12
        ,IME_Price_Increase_Type_Transport__c = 'Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Transp__c =12
        ,CurrencyIsoCode='CAD'
        ,IME_Price_Increase_Type_Product_Sales__c ='Regular Increase'
        ,IME_Fixed_Pricing_Period_months_Prod_S__c =12);
        
        Insert childContract;
        
     
        
        childContract .IME_Annual_Value_Opportunities__c = 10;
        //  parentContract.IME_Copy_to_all__c = false;
       // childContract .status = 'activated';
        
        update childContract;
        
         test.startTest();
      /*  Opportunity o = new Opportunity(name = 'c'
                                        ,AccountId = a.id
                                        ,Source_System__c = 'SKP Europe'
                                        ,Billing_Country__c = cntry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        //,Customer_Account_Number__c = System.now().format()
                                        ,RecordTypeId = EUOppType.Id
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,CloseDate = System.today()+10
                                        ,IME_Reason_Won__c = 'Price'
                                        ,CurrencyIsoCode= 'GBP'
                                        ,IME_Contract__c = parentContract.id    
                                       );
        
        insert o; */
        
        
       // Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
       	
            List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 	
            accountList[0].BillingCountry='India';	
            update accountList;	
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);	
                        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();	
            cusAcc.Name = 'testSold';	
            cusAcc.IM_Account__c = accountList[0].id;	
            cusAcc.Source_System__c = 'Other Europe';	
        insert cusAcc;	
        	
        Id testStandardPriceBook = Test.getStandardPricebookId();	

        	Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);	
            insert customPB;
          PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = product.Id, 	
                                                                    Pricebook2Id = testStandardPriceBook, 	
                                                                    UnitPrice = 1, IsActive = true, 	
                                                                    UseStandardPrice = false);	
            insert testPriceBookEntry;	
         PricebookEntry pbe_01 = new PricebookEntry(	
                Pricebook2Id = customPB.Id, Product2Id = product.Id,	
                UnitPrice = 12000, IsActive = true);	
            insert pbe_01;
        
     /*   PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = product.Id, 
            UnitPrice = 1, 
            IsActive = true,
            CurrencyIsoCode='GBP', 
            UseStandardPrice = false);
        
        insert pbe; */
        
        //PricebookEntry pbe = [select id from PricebookEntry where CurrencyIsoCode='GBP' and IsActive= true   limit 1];
        
        //  Select o.PricebookEntryId, o.OpportunityId From OpportunityLineItem o
        
        	          List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     	
            OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].id, unitPrice = 1,Update_New_Revenue_Forecast__c =false);	
            insert oppProd;	
        
       /* OpportunityLineItem oli = new OpportunityLineItem(
            PricebookEntryId= pbe.id,
            OpportunityId=o.id,
            Quantity=1,
            TotalPrice=1
        );
        
        insert oli;
      
      	o.IME_Contract__c = childContract.id;
        update o;
        
        Delete o; */
        test.stopTest(); 
        
    }   

}