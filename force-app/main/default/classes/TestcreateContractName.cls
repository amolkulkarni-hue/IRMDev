@isTest
public class TestcreateContractName {
    
    public static Contract contract1;
    public static Account testAccount1 = new Account();
    public static Opportunity opp;
    public static List<Opportunity> lstOp = new List<Opportunity>();
    public static IM_Country__c cntry;
    Database.SaveResult[] srList ;
    
    public static void setupTestContract() {
        // Create the Data for the test
        /*

//Profile p = [Select id from profile where name = 'IME_Contracts'];

IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
( (new IM_Country__c(name = 'United Kingdom',
Region__c = 'Europe')));
IM_Country__c cntry1 = CountryNameTranslator.getOrCreateTestCountry
( (new IM_Country__c(name = 'India')));


RecordType EUOppType = [select id from RecordType where name = 'IME standard opportunity' and sObjectType = 'Opportunity'];
RecordType parentContract = [Select id, name from RecordType where SObjectType = 'Contract' and name = 'IME Parent Contract'];

account a = new Account(name='x');
insert a;  

//Create the opportunity
//CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
Opportunity opp = new Opportunity(name = 'c'
,AccountId = a.id
,Source_System__c = 'SKP'
,Billing_Country__c = cntry.id 
,Lead_Source_Most_Recent__c = 'x'
,CloseDate = date.today()
,StageName = '1 - Qualification'
, RecordTypeId = EUOppType.Id
,IM_Servicing_Region__c ='London'
,IM_Commit_to_Forecast__c = true
,IM_Stage_5_Entered_Date__c  = System.today()
,IME_Reason_Won__c = 'Price'
,IM_Booked_Date__c = System.today());

insert opp; */
        
        //create the contract
        /* Contract c = new Contract(IM_DRCi_Contract_Number__c = '10'
,AccountId = a.id
,Opportunity__c = opp.id
,Billing_Country__c =cntry.id,IME_Other__c = True );
insert c;            

IM_Country__c cntrynew = TestingUtil.createIMCountry();
c.Billing_Country__c =cntrynew.id ;

update c;*/
        setupOppData();
        RecordType parentContract = [Select id, name from RecordType where SObjectType = 'Contract' and name = 'IME Parent Contract'];
        Date conStartDate=System.today();
        contract1 = new Contract(IM_DRCi_Contract_Number__c = '12'
                                 ,AccountId = testAccount1.id
                                 ,RecordTypeId =parentContract.id
                                 ,Opportunity__c = opp.id                                  
                                 ,IME_Price_Increase_Type_Storage__c='Other'
                                 ,IME_Special_Terms_Other_Storage__c='Test' 
                                 ,IME_Fixed_Pricing_Period_months_Storage__c=3 
                                 ,IME_End_of_Fixed_Pricing_Period_Storage__c= System.today()
                                 ,Status = 'Draft'             
                                 ,IME_Copy_to_all__c=true 
                                 ,IME_Index_Storage__c='CPI'
                                 ,IME_Capped_Percentage_Storage__c=2 
                                 ,IME_Original_Contract_Start_Date__c=System.today()
                                 ,StartDate=conStartDate.addmonths(-1)
                                 ,ContractTerm=1
                                 ,Billing_Country__c =cntry.id,IME_Other__c = True );
        insert contract1; 
    }
    
    static testmethod void TestAnnualAmountOpp() {
        /* 
Create the Data for the test
*/
        /*
        //Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        IM_Country__c cntry1 = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'India')));
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        
        RecordType EUOppType = [select id from RecordType where name = 'IME standard opportunity' and sObjectType = 'Opportunity'];
        RecordType parentContract = [Select id, name from RecordType where SObjectType = 'Contract' and name = 'IME Parent Contract'];
        
        account a = new Account(name='x',BillingCountry='United States');
        insert a;  
        
        //Create the opportunity
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        Opportunity opp = new Opportunity(name = 'c'
                                          ,AccountId = a.id
                                          ,Source_System__c = 'SKP'
                                          ,Billing_Country__c = cntry.id 
                                          ,Lead_Source_Most_Recent__c = 'x'
                                          ,StageName = '1 - Qualification'
                                          ,CloseDate = date.today()
                                          , RecordTypeId = EUOppType.Id
                                          ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                          ,IME_Reason_Won__c = 'Price'
                                          ,IM_Booked_Date__c = System.today(),
                                          amount=1000);
        
        insert opp;
        */
        setupOppData();
        RecordType parentContract = [Select id, name from RecordType where SObjectType = 'Contract' and name = 'IME Parent Contract'];
        Date conStartDate=System.today();
        contract1 = new Contract(IM_DRCi_Contract_Number__c = '12'
                                 ,AccountId = testAccount1.id
                                 ,RecordTypeId =parentContract.id
                                 ,Opportunity__c = opp.id                                  
                                 ,IME_Price_Increase_Type_Storage__c='Other'
                                 ,IME_Special_Terms_Other_Storage__c='Test' 
                                 ,IME_Fixed_Pricing_Period_months_Storage__c=3 
                                 ,IME_End_of_Fixed_Pricing_Period_Storage__c= System.today()
                                 ,Status = 'Draft'             
                                 ,IME_Copy_to_all__c=true 
                                 ,IME_Index_Storage__c='CPI'
                                 ,IME_Capped_Percentage_Storage__c=2 
                                 ,IME_Original_Contract_Start_Date__c=System.today()
                                 ,StartDate=conStartDate.addmonths(-1)
                                 ,ContractTerm=1
                                 ,Billing_Country__c =cntry.id,IME_Other__c = True );
        insert contract1; 
        contractTotalAnnualAmount.run = true; 
        opp.IME_Contract__c = contract1.id;          
        update opp; 
        
        
    }
    
    static testMethod void testAddendumExt(){
        test.startTest();
        
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        
        ID parentContract = DataFactory.getRecordTypeId('Contract','IME Addendum Extension');
        account a = new Account(name='x',BillingCountry='United States');
        insert a; 
        contract1 = new Contract(IM_DRCi_Contract_Number__c = '12'
                                 ,AccountId = a.id
                                 ,RecordTypeId =parentContract                                                                   
                                 ,IME_Price_Increase_Type_Storage__c='Other'
                                 ,IME_Special_Terms_Other_Storage__c='Test' 
                                 ,IME_Fixed_Pricing_Period_months_Storage__c=3 
                                 ,IME_End_of_Fixed_Pricing_Period_Storage__c= System.today()
                                 ,Status = 'Draft'           
                                 ,Contract_Signed_Date__c = System.today()+2
                                 ,CurrencyIsoCode='GBP'
                                 ,IME_Index_Storage__c='CPI'
                                 ,IME_Capped_Percentage_Storage__c=2 
                                 ,IME_Original_Contract_Start_Date__c=System.today()
                                 ,StartDate=System.today().addmonths(-1)
                                 ,ContractTerm=1
                                 ,Billing_Country__c =cntry.id,IME_Other__c = True
                                 ,IME_Annual_Value_Opportunities__c = 10,
                                 IME_MFP_Clause__c = 'No');
        insert contract1; 
        
        contract1.Status = 'Activated';
        contract1.IME_MFP_Clause__c ='Yes';
        update contract1;
        
        test.stopTest();
    }
    
    static testMethod void testFixedTermContract() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Contract_Term_Type__c='Fixed term';  
        update contract1;
        
        Test.stopTest();
    }
    
    static testMethod void testFixedTermContract1() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Expiration_Notice_days__c=30;
        contract1.IM_Renewal_Term__c=3;
        contract1.IME_Contract_Term_Type__c='Fixed term';
        
        update contract1;
        
        Test.stopTest();
    }
    
    static testMethod void testFixedTermContract2() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IM_Renewal_Term__c=null;
        contract1.IME_Expiration_Notice_days__c=30;
        contract1.IME_Contract_Term_Type__c='Fixed term';
        
        update contract1;
        
        Test.stopTest();
    }
    
    static testMethod void testEvergreenContract() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Contract_Term_Type__c='Evergreen';
        contract1.IME_Expiration_Notice_days__c=30;        
        contract1.IM_Renewal_Term__c=3;                
        update contract1;
        
        Test.stopTest();
    }
    
    static testMethod void testEvergreenContract_noRenewal() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Contract_Term_Type__c='Evergreen';
        contract1.IME_Expiration_Notice_days__c=Null;
        contract1.IME_Fixed_Pricing_Period_months__c=3;     
        contract1.IM_Renewal_Term__c=3;                
        update contract1;      
        
        Test.stopTest();
    }
    
    static testMethod void testEvergreenContract1() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Contract_Term_Type__c='Evergreen';
        contract1.IME_Expiration_Notice_days__c=30;
        contract1.IM_Renewal_Term__c=3;        
        
        Date today = System.today();
        contract1.StartDate=today.addmonths(-2);            
        update contract1;
        
        Test.stopTest();
    }
    static testMethod void testEvergreenContract2() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Contract_Term_Type__c='Evergreen';
        contract1.IME_Expiration_Notice_days__c=30;
        contract1.IM_Renewal_Term__c=3;        
        contract1.StartDate=System.today();            
        update contract1;
        
        Test.stopTest();
    }
    
    static testMethod void testEvergreenContract3() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Contract_Term_Type__c='Evergreen';
        contract1.IM_Renewal_Term__c=0;              
        contract1.IME_Expiration_Notice_days__c=null;        
        Date today = System.today();
        contract1.StartDate=today.addmonths(-2);      
        update contract1;
        
        contract1.IME_Expiration_Notice_days__c=30;
        update contract1;
        
        Test.stopTest();
    }
    
    static testMethod void testEvergreenRollingContract3() 
    {
        Test.startTest();
        setupTestContract();
        
        contract1.IME_Copy_to_all__c=false;
        contract1.IME_Contract_Term_Type__c='Evergreen (open rolling)';
        contract1.IME_Expiration_Notice_days__c=30;
        contract1.ContractTerm=null;  
        
        update contract1;        
        Test.stopTest();
    }
    
    static testMethod void testCopyToAllError() 
    {
        Test.startTest();
        setupTestContract();
        
        try
        {            
            contract1.IME_Copy_to_all__c=true;
            contract1.IME_Contract_Term_Type__c='Evergreen (open rolling)';
            contract1.IME_Expiration_Notice_days__c=30;
            contract1.ContractTerm=null;  
            
            update contract1;   
        }
        catch(Exception e) {
            System.Assert(e.getMessage().contains('Please amend manually.'));
        }     
        Test.stopTest();
    }
    
    public static void setupOppData(){
        
        
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country; 
        
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
        cntry = CountryNameTranslator.getOrCreateTestCountry
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
        opp = new Opportunity(
            name = 'testOpName'
            ,Source_System__c = 'SKP'
            ,Billing_Country__c = cntry.id 
            ,Lead_Source_Most_Recent__c = 'Email'
            ,StageName = '1 - Qualification'
            ,IM_Servicing_Region__c ='London'
            ,IME_Reason_Won__c = 'Price'
            ,AccountId = testAccount1.Id   
            ,IM_Booked_Date__c = System.today(),
            CloseDate= system.today()
            ,RecordTypeId = EUOppType.Id,
            IM_Commit_to_Forecast__c = true
            ,IM_Stage_5_Entered_Date__c  = System.today()
            ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,Owner_Email__c='testOpp1@testOpp1.com'
        );
        insert opp;
        
       
    }
}