@istest
public class createNewContractTest{
    
    public static Account testAccount;
    public static Opportunity testOpp;
    public static Contact testcontact;
    public static OpportunityContactRole opptContRole;
    public static Contract testContract;
    public static IME_Contract_Conga_URLs__mdt con;
    
    public static void setup()
    {  
       //to avoid the limit issues
       OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
       Profile prof = [Select Id from profile where Name='System Administrator'];
       User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;    
        
        System.runAs(u){
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country; 
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
                      
        testAccount = new Account(name='Test Acct',Billing_County__c='United States',IMGA_Owner__c= u.id,
								 BillingCountry='United States');
        insert testAccount;
       
        testcontact= new Contact(LastName='TestContact1',
                                 FirstName='TestFirstName',
                                 Email='testemail@email.com',
                                 AccountId=testAccount.Id,
                                 MailingCity = 'Malden',                                 
                                 MailingCountry ='United States',
                                 MailingPostalCode = '02148', 
                                 MailingState = 'MA',  
                                 MailingStreet = '745 Atlantic Ave');        
        insert testcontact;        
        Recordtype r=[Select id from recordtype where name='IME Standard Opportunity' limit 1];
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                                      Billing_Country__c = testCountry.Id, 
                                                                      IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        testContract = new Contract(AccountId =testAccount.Id,Billing_Country__c=testCountry.Id,ContractTerm=3,Status='Draft',
                                    StartDate=System.today(),IM_Contract_Category__c='MSA',
                                    Contract_Type__c='IM Non Standard',Standard_Contract__c = false);
        insert testContract;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.        
        
            Test.startTest();
            List<OpportunityProductSelection__c> PS=new List<OpportunityProductSelection__c>();
            OpportunityProductSelection__c ps1=new OpportunityProductSelection__c();
            ps1.Name='CloudSolutionsProduct';
            ps1.Product_Class_Name__c='Data Backup and Recovery';
            ps1.Product_Line_Name__c='Cloud Solutions';
            PS.add(ps1);
            insert PS;
       
            List<SVStatus__c> sv=new List<SVStatus__c>();
            SVStatus__c sv1=new SVStatus__c();
            sv1.Name='SVStatusPassed';
            sv1.Amount__c=2400;
            sv1.OpptType__c='New Deal,Up-Sell';
            sv1.Stage__c='6 - Setup';
            sv.add(sv1);
            insert sv; 
            
            testOpp= new Opportunity(Name = 'Test Opportunity',
                                     Product__c ='RM', 
                                     Type='New Deal',
                                     AccountId = testAccount.Id, 
                                     StageName = '1 - Qualification', 
                                     CloseDate = Date.Today(), 
                                     IM_Booked_Date__c = Date.Today(),
                                     recordtypeid=r.id,
                                     Billing_Country__c = testCountry.Id,
                                     Group_Purchasing_Organization_GPO__c='HealthTrust',
                                     IME_Vended_Unvended__c='Unknown',
                                     Contracting_Country__c='Netherlands',
                                     IM_Servicing_Region__c='London',
                                     Source_System__c='SKP NA',
									 Initial_Period__c='12',
                                     Contract_Term__c='24',
                                     IME_Contract__c =testContract.Id,
                                     Effective_Date__c=Date.Today(),
                                     Company_Name__c = 'test',
                                     Company_Registered_Address2__c = 'test',
                                     Company_Number__c = '1'
                                    );
            insert testOpp;
        
        IME_Contract_Conga_URLs__mdt con =[Select  CC_Signer__c,Conga_Params__c,Contract_Term_Type__c,Contract_Version__c,Country__c,DeveloperName,Email_message__c,
                                           Email_subject__c,Expiration_Notice_days__c,Fixed_Pricing_Period_months_Prod_S__c,Fixed_Pricing_Period_months_Services__c,
                                           Fixed_Pricing_Period_months_Storage__c,Fixed_Pricing_Period_months_Transp__c,Id,Internal_Signatories__c,Label,Language,
                                           Liability_Currency__c,Liability__c,MasterLabel,Max_Liability__c,NamespacePrefix,Price_Increase_Type_Product_Sales__c,
                                           Price_Increase_Type_Services__c,Price_Increase_Type_Storage__c,Price_Increase_Type_Transport__c,Product__c,QualifiedApiName,
                                           Renewal_Term_months__c FROM IME_Contract_Conga_URLs__mdt Where Country__c=: testOpp.Contracting_Country__c and Product__c=:testOpp.Product__c];
        system.debug('IME_Contract_Conga_URLs__mdt>>>>>>>'+con);
                
        try{
            opptContRole=new OpportunityContactRole(OpportunityId=testOpp.Id, isPrimary= true, 
                                                    ContactId = testcontact.id, Role='Decision Maker');
            insert opptContRole;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }        
        Id testStandardPriceBook = Test.getStandardPricebookId();
        Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        system.debug('LINE No# 112'); 
        
        Product2 testProd = new Product2(Name = '9999',
                                       //recordTypeId='01280000000UIUpAAO',
                                         recordTypeId=rt,
                                             IsActive= true, Bill_Code_Classification__c='Storage');
        insert testProd;
        system.debug('LINE No# 118 inserted testProd'); 
        Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, 
                                                                Pricebook2Id = testStandardPriceBook, 
                                                                UnitPrice = 1, IsActive = true, 
                                                                UseStandardPrice = false);
        insert testPriceBookEntry;
        system.debug('LINE No# 127 inserted testPriceBookEntry'); 
        
        PricebookEntry pbe_01 = new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = testProd.Id,
             							UnitPrice = 12000, IsActive = true);
        insert pbe_01;
        system.debug('LINE No# 132 inserted pbe_01'); 
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, 
                                                                  OpportunityId =testOpp.Id, 
                                                                  unitPrice = 1,Product_Class__c ='Records Management',
                                                                  Product_Line__c='storage');
        insert oppProd;
            Test.stopTest();
        system.debug('LINE No# 139 inserted oppProd'); 
        }
    }
    
    public static void createContractSetup()
    {
        Contract cont = new Contract();
        cont.IME_Contract_Version__c = 'IMIRL-CC-16.01';
        cont.IME_Liability_Currency__c = 'EUR';
        cont.RecordTypeid = '01280000000UJX3';
        cont.AccountId = testOpp.AccountId;
        cont.Billing_Country__c = testOpp.Billing_Country__c;
        cont.StartDate = testOpp.Effective_Date__c;
        cont.Contract_Type__c = 'IM Standard'; 
        cont.IME_Contract_Term_Type__c = 'Evergreen';
        cont.ContractTerm = Integer.valueOf(testOpp.Contract_Term__c);
        cont.IM_Renewal_Term__c = 12;
    cont.Initial_Period__c = Integer.valueOf(testOpp.Initial_Period__c);
        cont.IME_Expiration_Notice_days__c = 90;        
        cont.IM_Liability__c = 1;
        cont.IM_Max_Liability__c = 1000000;
        cont.IME_MFP_Clause__c = 'NO';
        cont.IME_Non_Standard_Clause__c = 'NO';
        cont.IME_Price_Increase_Type_Storage__c = 'Regular Increase';
        cont.IME_Fixed_Pricing_Period_months_Storage__c = 12;
        cont.IME_Price_Increase_Type_Services__c = 'Regular Increase';
        cont.IME_Fixed_Pricing_Period_months_Services__c = 12;
        cont.IME_Price_Increase_Type_Transport__c = 'Regular Increase';
        cont.IME_Fixed_Pricing_Period_months_Transp__c = 12;
        cont.IME_Price_Increase_Type_Product_Sales__c = 'Regular Increase';
        cont.IME_Fixed_Pricing_Period_months_Prod_S__c = 12;
        cont.Standard_Contract__c = True;
        cont.IME_Records_Management_RM__c = True; //after this are new lines
        cont.IME_Data_Protection_DP__c = True;
        cont.IME_Document_Management_Services_DMS__c = True;
       
        cont.Status = 'Draft';
        insert cont;        
    }
    
    static testmethod void createTestContractUpdate()
    {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
        setup(); 
        createContractSetup();
        createNewContract.createStandardContract(testOpp.id,TRUE);
    }
    
    static testmethod void createTestContractUpdate1()
    {  
        //to avoid the limit issues
	   OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;         
       Profile prof = [Select Id from profile where Name='System Administrator'];
       User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;    
        
        System.runAs(u){
        IM_Country__c testCountry = new IM_Country__c(Name='Netherlands');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='Netherlands');
        insert country; 
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Netherlands';
        setting.object_name__c = 'Account';
        insert setting;
                      
        testAccount = new Account(name='Test Acct',Billing_County__c='Netherlands',IMGA_Owner__c= u.id,
								 BillingCountry='Netherlands');
        insert testAccount;
       
        testcontact= new Contact(LastName='TestContact1',
                                 FirstName='TestFirstName',
                                 Email='testemail@email.com',
                                 AccountId=testAccount.Id,
                                 MailingCity = 'Malden',                                 
                                 MailingCountry ='Netherlands',
                                 MailingPostalCode = '02148', 
                                 MailingState = 'MA',  
                                 MailingStreet = '745 Atlantic Ave');        
        insert testcontact;
            
        Recordtype r=[select id from recordtype where name='IME Standard Opportunity' limit 1];
                
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                                                Billing_Country__c = testCountry.Id, 
                                                                                IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        testContract = new Contract(AccountId =testAccount.Id,Billing_Country__c=testCountry.Id,ContractTerm=3,Status='Draft',
                                    StartDate=System.today(),IM_Contract_Category__c='MSA',
                                    Contract_Type__c='IM Non Standard',Standard_Contract__c = false);
        insert testContract;
        
        testContract.Status = 'Activated';
        update testContract;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
           
       testOpp= new Opportunity(Name = 'Test Opportunity',
                                     Product__c ='RM', 
                                     Type='New Deal',
                                     AccountId = testAccount.Id, 
                                     StageName = '1 - Qualification', 
                                     CloseDate = Date.Today(), 
                                     IM_Booked_Date__c = Date.Today(),
                                     recordtypeid=r.id,
                                     Billing_Country__c = testCountry.Id,
                                     Group_Purchasing_Organization_GPO__c='HealthTrust',
                                     IME_Vended_Unvended__c='Unknown',
                                     Contracting_Country__c='Netherlands',
                                     IM_Servicing_Region__c='London',
                                     Source_System__c='SKP NA',
                                     Contract_Term__c='24',
                   Initial_Period__c='12',
                                     IME_Contract__c =testContract.Id,
                                     Effective_Date__c=Date.Today(),
                                     Company_Name__c = 'test',
                                     Company_Registered_Address2__c = 'test',
                                     Company_Number__c = '1');            
       insert testOpp;
        
        Test.startTest();
        createNewContract.createStandardContract(testOpp.id,TRUE);
        PageReference pageRef = Page.createNewContract;
        Test.setCurrentPage(pageRef);
       // System.debug('billing Country>>>>'+testOpp.Billing_Country__r.Name +'Country>>>'+testOpp.Contracting_Country__c);
        pageRef.getParameters().put('id',testOpp.Id);
        
        ApexPages.StandardController Sc = new ApexPages.standardController(testOpp);
        createNewContract createNewCon = new createNewContract(Sc);
         
        createNewCon.cancel();
        createNewCon.renderfn=false;
        createNewCon.product='RM';
        createNewCon.conga_params='test';
        createNewCon.contractCancel();
        createNewCon.createContract();
        createNewCon.createNewContract();
        createNewCon.alertContract();
        createNewCon.editcontract();
        createNewCon.save(); 
        Test.stopTest();
        }
    }
    
    static testmethod void createTestContractUpdate2() 
    {  
        //to avoid the limit issues
       OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
       Profile prof = [Select Id from profile where Name='System Administrator'];
       User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;    
        
        System.runAs(u){
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country; 
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
                      
        testAccount = new Account(name='Test Acct',Billing_County__c='United States',IMGA_Owner__c= u.id,
								 BillingCountry='United States');
        insert testAccount;       
        
        Recordtype r=[select id from recordtype where name='IME Standard Opportunity' limit 1];        
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                                                Billing_Country__c = testCountry.Id,
                                                                                IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        testContract = new Contract(AccountId =testAccount.Id,Billing_Country__c=testCountry.Id,ContractTerm=3,Status='Draft',
                                    StartDate=System.today(),IM_Contract_Category__c='MSA',
                                    Contract_Type__c='IM Non Standard',Standard_Contract__c = true);
        insert testContract;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
       
            testOpp= new Opportunity(Name = 'Test Opportunity',
                                     Product__c ='RM', 
                                     Type='Renewal',
                                     AccountId = testAccount.Id, 
                                     StageName = '1 - Qualification', 
                                     CloseDate = Date.Today(), 
                                     IM_Booked_Date__c = Date.Today(),
                                     recordtypeid=r.id,
                                     Billing_Country__c = testCountry.Id,
                                     Group_Purchasing_Organization_GPO__c='HealthTrust',
                                     IME_Vended_Unvended__c='Unknown',
                                     Contracting_Country__c='Netherlands',
                                     IM_Servicing_Region__c='London',
                                     Source_System__c='SKP NA',
                                     Contract_Term__c='24',
                   Initial_Period__c='12',
                                     IME_Contract__c =testContract.Id,
                                     Effective_Date__c=Date.Today(),
                                     Company_Name__c = 'test',
                                     Company_Registered_Address2__c = 'test',
                                     Company_Number__c = '1'
                                    );
            //,Billing_Country__c='Netherlands'
            insert testOpp;
            
        Test.startTest();
        createNewContract.createStandardContract(testOpp.id,TRUE);
        PageReference pageRef = Page.createNewContract;
        Test.setCurrentPage(pageRef);
        //System.debug('billing Country>>>>'+testOpp.Billing_Country__r.Name +'Country>>>'+testOpp.Contracting_Country__c);
        pageRef.getParameters().put('id',testOpp.Id);
        
        ApexPages.StandardController Sc = new ApexPages.standardController(testOpp);
        createNewContract createNewCon = new createNewContract(Sc);
         
        createNewCon.cancel();
        createNewCon.renderfn=false;
        createNewCon.product='RM';
        createNewCon.conga_params='test';
        createNewCon.contractCancel();
        createNewCon.createContract();
        createNewCon.createNewContract();
        createNewCon.alertContract();
        createNewCon.editcontract();
        createNewCon.save(); 
        Test.stopTest();
        }     
    }
        
    static testmethod void createTestContractUpdate3() 
    {  
        //to avoid the limit issues
       OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
       Profile prof = [Select Id from profile where Name='System Administrator'];
       User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;    
        
        System.runAs(u){
        IM_Country__c testCountry = new IM_Country__c(Name='United Kingdom');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United Kingdom');
        insert country; 
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United Kingdom';
        setting.object_name__c = 'Account';
        insert setting;
                      
        testAccount = new Account(name='Test Acct',Billing_County__c='United Kingdom',IMGA_Owner__c= u.id,
								 BillingCountry='United Kingdom');
        insert testAccount;
        
        
        Recordtype r=[select id from recordtype where name='IME Standard Opportunity' limit 1];      
         
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount = new IM_Customer_Account__c(Name = '123', 
                                                                                Billing_Country__c = testCountry.Id, IM_Account__c = testAccount.id);
        insert caseCustomerAccount;
        
        testContract = new Contract(AccountId =testAccount.Id,Billing_Country__c=testCountry.Id,ContractTerm=3,Status='Draft',
                                    StartDate=System.today(),IM_Contract_Category__c='MSA',
                                    Contract_Type__c='IM Non Standard',Standard_Contract__c = true);
        insert testContract;
        
        testopp= new Opportunity(Name = 'Test Opportunity',
                                     Product__c ='RM', 
                                     Type='New Deal',
                                     AccountId = testAccount.Id, 
                                     StageName = '1 - Qualification', 
                                     CloseDate = Date.Today(), 
                                     IM_Booked_Date__c = Date.Today(),
                                     recordtypeid=r.id,
                                     Billing_Country__c = testCountry.Id,
                                     Group_Purchasing_Organization_GPO__c='HealthTrust',
                                     IME_Vended_Unvended__c='Unknown',
                                     Contracting_Country__c='United Kingdom',
                                     IM_Servicing_Region__c='London',
                                     Source_System__c='SKP NA',
									 Initial_Period__c='12',
                                     Contract_Term__c='24',
                                     IME_Contract__c =testContract.Id,
                                     Effective_Date__c=Date.Today(),
                                     Company_Name__c = 'test',
                                     Company_Registered_Address2__c = 'test',
                                     Company_Number__c = '1'
                                    );            
            insert testOpp;
            
        Test.startTest();
        createNewContract.createStandardContract(testOpp.id,TRUE);
        PageReference pageRef = Page.createNewContract;
        Test.setCurrentPage(pageRef);
        //System.debug('billing Country>>>>'+testOpp.Billing_Country__r.Name +'Country>>>'+testOpp.Contracting_Country__c);
        pageRef.getParameters().put('id',testOpp.Id);
        
        ApexPages.StandardController Sc = new ApexPages.standardController(testOpp);
        createNewContract createNewCon = new createNewContract(Sc);
         
        createNewCon.cancel();
        createNewCon.renderfn=false;
        createNewCon.product='RM';
        createNewCon.conga_params='test';
        createNewCon.contractCancel();
        createNewCon.createContract();
        createNewCon.createNewContract();
        createNewCon.alertContract();
        createNewCon.editcontract();
        createNewCon.save(); 
        Test.stopTest();
    }
    } 
    
    static testmethod void createTestContract()
    {        
        setup();
        
        try{
            testOpp.Product__c = '';
            update testOpp;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        PageReference pageRef = Page.createNewContract;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',testOpp.Id);
        
        ApexPages.StandardController Sc = new ApexPages.standardController(testOpp);
        createNewContract createNewCon = new createNewContract(Sc);
        createNewCon.cancel();
        createNewCon.contractCancel();
        createNewCon.createContract();
        createNewCon.createNewContract();
        createNewCon.alertContract();        
    } 
    
    static testmethod void createTestContract_m1()
    {
        setup();
        
        PageReference pageRef = Page.createNewContract;
        Test.setCurrentPage(pageRef);
        System.debug('billing Country>>>>'+testOpp.Billing_Country__r.Name +'Country>>>'+testOpp.Contracting_Country__c);
        pageRef.getParameters().put('id',testOpp.Id);
        //Test.startTest();
        ApexPages.StandardController Sc = new ApexPages.standardController(testOpp);
        createNewContract createNewCon = new createNewContract(Sc);
         
        createNewCon.cancel();
        createNewCon.renderfn=false;
        createNewCon.product='RM';
        createNewCon.conga_params='test';
        createNewCon.contractCancel();
        createNewCon.createContract();
        createNewCon.createNewContract();
        createNewCon.alertContract();
        createNewCon.editcontract();
        createNewCon.save(); 
        //Test.stopTest();
    } 
    
    /*static testmethod void createTestContract_m2()        
    {        
        setup();
        Test.startTest();
        PageReference pageRef = Page.createNewContract;
        Test.setCurrentPage(pageRef);
        System.debug('billing Country>>>>'+testOpp.Billing_Country__r.Name +'Country>>>'+testOpp.Contracting_Country__c);
        pageRef.getParameters().put('id',testOpp.Id);
        List<Account> acct = TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True);
        //Opportunity op = TestingUtils.createOpportunity('testOpp', acct[0].Id, True);
        ApexPages.StandardController Sc = new ApexPages.standardController(testOpp);
        createNewContract createNewCon = new createNewContract(Sc);
         
        createNewCon.cancel();
        createNewCon.renderfn=false;
        createNewCon.product='RM'; 
        createNewCon.conga_params='test';
        createNewCon.contractCancel();
        createNewCon.createContract();
        createNewCon.createNewContract();
        createNewCon.alertContract();
        createNewCon.editcontract();
        createNewCon.save(); 
        Test.stopTest();
    } */
}