@isTest
public class TestDataFactory {
 
    private static Account  testAccount = new Account(Name='TestAccount');
    private static Integer soMany=2;	
    
    static testMethod void TestProfileMethod()
    {
       DataFactory dataFactoryCls = new DataFactory();
        
        //This method 
       string profile=dataFactoryCls.profileMethod('IME_Manager');
       system.debug('profile='+profile);
    }
        
    static testMethod void TestImContMethd()
    {      
       DataFactory dataFactoryCls = new DataFactory();
        
          //This method creates and returns country 'INDIA'
       IM_Country__c imCountry=dataFactoryCls.imContMethd('India');
       system.debug('imCountry='+imCountry);
    }
    
    static testMethod void TestRecordTypeMethd()
    {
        DataFactory dataFactoryCls = new DataFactory();  
        
          //This method returns all the RecordTypes for the given object 
        List<String> recTypeLst = dataFactoryCls.recordTypeMethd('Opportunity','dummy');
    }
    
    static testMethod void TestAcctMethd()
    {
        DataFactory dataFactoryCls = new DataFactory();       
       
          //This method creates <soMany> Test IMGA accounts
        List<Account> accounts = dataFactoryCls.acctMethd(soMany,'dummy');
    }
    
    static testMethod void TestContMethd()
    {
        DataFactory dataFactoryCls = new DataFactory();    
        insert testAccount;
          //This method creates a test contact for a given Account
        Contact testCont = dataFactoryCls.contMethd(testAccount.Id);
    }
    
    static testMethod void TestContLstMethd()
    {
        DataFactory dataFactoryCls = new DataFactory();   
        insert testAccount;
          //This method creates <soMany> test contacts for a given Account
        List<Contact> testConts = dataFactoryCls.contLstMethd(soMany,'Dummy',testAccount.Id);
    }
    
    static testMethod void testOpptyMethd()
    {
        DataFactory dataFactoryCls = new DataFactory();  
        insert testAccount;
          //This method creates a testOpportunity for a given Account
        Opportunity testOppt = dataFactoryCls.opptyMethd('Dummy',testAccount.Id);
    }
    
    static testMethod void testOpptyLstMethd()
    {
        DataFactory dataFactoryCls = new DataFactory(); 
        insert testAccount;
          //This method creates <soMany> testOpportunity for a given Account
        List<Opportunity> testOppts = dataFactoryCls.opptyLstMethd('Dummy',testAccount.Id,soMany);
    }
    
    static testMethod void testProductMethd()
    {
        DataFactory dataFactoryCls = new DataFactory(); 
          //This method creates testProduct
        Product2 prod = dataFactoryCls.productMethd('Dummy');
    }
    
     static testMethod void testProductLstMethd()
    {
        DataFactory dataFactoryCls = new DataFactory(); 
          //This method creates <soMany> testProducts
        List<Product2> prods = dataFactoryCls.productLstMethd('Dummy',soMany);
    }
    
    static testMethod void testPriceBookMethd()
    {
        DataFactory dataFactoryCls = new DataFactory(); 
          //This method creates a testPriceBook
        Pricebook2 pricebook = dataFactoryCls.priceBookMethd('Dummy',true);
    }
    
    static testMethod void testPriceBookMethdLst()
    {
        DataFactory dataFactoryCls = new DataFactory(); 
          //This method creates <soMany> testPriceBooks
        List<Pricebook2> pricebook = dataFactoryCls.priceBookMethdLst('Dummy',soMany);
    }
    
    static testMethod void testcreateCustomerAccountMethd()
    {
        DataFactory dataFactoryCls = new DataFactory(); 
        insert testAccount;
          //This method creates an IM_Customer_Account
        IM_Customer_Account__c custAcc = dataFactoryCls.createCustomerAccountMethd(testAccount.id);
    }
    
    static testMethod void testCreateCaseMthd()
    {
        DataFactory dataFactoryCls = new DataFactory(); 
        insert testAccount;
        ID recordTypeId=DataFactory.getRecordTypeId('Case','Issue');
        Contact testCont=TestingUtils.createContact(testAccount.id,true);
        User testUser=TestingUtils.createUser('dummy',true);  
        IM_Customer_Account__c custAcc = dataFactoryCls.createCustomerAccountMethd(testAccount.id);
          //This method creates an IM_Customer_Account
        Case testCase = dataFactoryCls.createCaseMthd(recordTypeId, testCont, testAccount, testUser, custAcc);
    }
}