@isTest
public class TestingUtils {

    private static Integer unique_number = 0;
    private static Integer offsetForDummyInsert = 1;
    public static User ADMIN_USER
    {
        get
        {
            if( ADMIN_USER == null )
                ADMIN_USER = [ SELECT Id FROM User WHERE (Profile.Name = 'System Administrator' OR Profile.Name = 'IM_Custom Sys Admin') AND IsActive=true LIMIT 1 ];
            return ADMIN_USER; 
        }
        private set;
    }

    public static RecordType NCSP_DP_NEW_CUSTOMER_SETUP
    {
        get
        {
            if( NCSP_DP_NEW_CUSTOMER_SETUP == null )
                NCSP_DP_NEW_CUSTOMER_SETUP = [ Select Name, Id From RecordType r where Name = 'NCSP: DP New Customer Setup' AND SobjectType = 'Case' ];
            return NCSP_DP_NEW_CUSTOMER_SETUP;
        }
        private set;
    }
    
   
    public static RecordType NCSP_NEW_CUSTOMER_SETUP
    {
        get
        {
            if( NCSP_NEW_CUSTOMER_SETUP == null )
                NCSP_NEW_CUSTOMER_SETUP = [ Select Name, Id From RecordType r where Name = 'NCSP: New Customer Setup' AND SobjectType = 'Case' ];
            return NCSP_NEW_CUSTOMER_SETUP;
        }
        private set;
    }
    
    public static RecordType IMGA_ACCOUNT_RECORD_TYPE
    {
        get
        {
            if( IMGA_ACCOUNT_RECORD_TYPE == NULL )
                IMGA_ACCOUNT_RECORD_TYPE = [ SELECT Id FROM RecordType WHERE (DeveloperName = 'IMGA_Record_Type' 
                                                                              /*28747 or  DeveloperName = 'IMGA_Record_Type_At_Risk'*/) 
                                            AND sObjectType = 'Account' AND IsActive = true LIMIT 1 ];
            return IMGA_ACCOUNT_RECORD_TYPE;
        }
        private set;
    }
    /* Added by: Vijay Andrews
       Case No: 03340776
    */
    //Commenting as part of Gitlab story #25402
/*  
    public static final Id M2_IMGA_ID =
            [ select id from recordtype
               where sobjecttype = 'BoB_Coverage__c' and developername = 'IMGA' ].Id;
*/

    public static List<Country_Settings__c> setupCountryCustomSettings(Boolean doInsert)
    {
        List<Country_Settings__c> settings = new List<Country_Settings__c>();
        settings.add(new Country_Settings__c(Name='Canada', Object_Name__c='Account') );
        settings.add(new Country_Settings__c(Name='United States', Object_Name__c='Account'));
        if(doInsert)
        {
            System.runAs(ADMIN_USER)
            {
                insert settings;
            }
        }
        return settings;
    }

    /**
       * @author Michael Hendy
       * @date 08/21/2013
       * @description Determines if the pagemessages contains a certain string
       * @param String messageNeedle : the string we will search for in the pagemessages
       * @return Boolean : true if found, false otherwise
       */

       public static Boolean pageMessageContains(String messageNeedle)
       {
               if( ApexPages.getMessages().size() > 0 )
               {
                       for (ApexPages.Message message : ApexPages.getMessages() ){

                           if(message.getSummary().contains(messageNeedle))
                                   return true;
                       }
               }

               return false;
       }

    public static List<Opportunity_Security__c> setupOpportunitySecuritySettings(Boolean doInsert)
    {
        List<Opportunity_Security__c> settings = new List<Opportunity_Security__c>();
        //settings.add(new Opportunity_Security__c(Name='Enterprise Account Executive', Field_Name__c = 'IM_Enterprise_Account_Executive__c', Object_Name__c = 'Account', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Enterprise Account Manager', Field_Name__c = 'IM_Enterprise_Account_Manager__c', Object_Name__c = 'Account', Visibility_Access_Level__c = 'R') );
        settings.add(new Opportunity_Security__c(Name='Inside Sales – RM', Field_Name__c = 'physical_isr__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Physical Hybrid', Field_Name__c = 'physical_hybrid__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Physical RM', Field_Name__c = 'physical_rm__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Physical – DB&R', Field_Name__c = 'physical_dp__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );

        if(doInsert)
        {
            System.runAs(ADMIN_USER)
            {
                insert settings;
            }
        }
        return settings;
    }

    public static Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
    public static User createUser(String uniq, Boolean doDml){
        User u = new User(Alias = 'unt'+uniq, Email='stdunit'+uniq+'@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Test'+uniq, 
            LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = adminProfile.Id, 
            TimeZoneSidKey='America/New_York', Country='United States', UserName='stdunit'+uniq+'@testorg.com');
        if(doDml) insert u;
        return u;
    }

    public static List<Account> createAccounts ( Integer numOfAccounts, Boolean isInsert ){

        List<Account> testAccounts = new List<Account>();
        IM_Country__c mainName = new IM_Country__c(Name='United States');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States');
        insert country;
        for ( Integer i = 0; i < numOfAccounts; i++ ){
             Account testAccount = new Account();
             testAccount.Name = 'TestAccount_' +Math.random()+ i;
             testAccount.BillingCountry = 'United States';
             testAccount.BillingPostalCode = '11209';
             testAccount.BillingState = 'NY';
             testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';    
             testAccounts.add ( testAccount );
        }
        if ( isInsert )
            
            try
            {
                           
            insert testAccounts;
            }
        catch (exception e){}

        return testAccounts;
    }
// Commented out by Bluewolf for deployment on 5/19
     public static List<Account> createCountryParentAccounts ( Integer numOfAccounts, Boolean isInsert ){
        System.debug('I am here');
        List<Account> testAccounts = new List<Account>();
        IM_Country__c mainName = new IM_Country__c(Name='US');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States');
        insert country;
          IM_Alternative_Country_Name__c AlternateCountry = new IM_Alternative_Country_Name__c(Alternative_Name__c = 'United States',
                                                                                                IM_Country__c = country.id);
         insert AlternateCountry;
        for ( Integer i = 0; i < numOfAccounts; i++ ){
             Account testAccount = new Account();
             testAccount.Name = 'TestAccount_' + i;
             testAccount.BillingCountry = 'United States';
             testAccount.BillingPostalCode = '11209';
             testAccount.BillingState = 'NY';
             testAccount.IM_Hierarchy_Level__c = 'Country Parent';
             testAccounts.add ( testAccount );
        }
        if ( isInsert )
            insert testAccounts;
		system.debug('Account.BillingCountry is ' + testAccounts[0].BillingCountry);
        return testAccounts;
    }

    
    public static Contact createContact(Id accountId, Boolean doInsert) {
        system.debug('kkkkkkkkk'+accountId);
        Contact contact = new Contact();
        contact.AccountId = accountId;
        contact.FirstName = 'Peter';
        contact.LastName = 'Cebedo';
        contact.Phone = '415-906-3801';

        if (doInsert)
        {
            insert contact;
        }

        return contact;
    }

    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
    public static Opportunity createOpportunity(String name, Id actId, Boolean doInsert)
    {
        Opportunity testOpportunity = new Opportunity(IM_Servicing_Region__c='Houston',IM_Booked_Date__c=Date.today(), StageName='1 - Qualification', AccountId = actId, CloseDate = System.today());
        testOpportunity.Name = (name == null)? 'testOpp' : name;
        if( doInsert)
            insert testOpportunity;
        system.debug('Opportunity.Account.BillingCountry is ' + testOpportunity.Account.BillingCountry);
        return testOpportunity;

    }
    
public static List<Opportunity> createOpportunities(String name, Id actId, Boolean doInsert,Integer noOfOpps,Id Recordtype)
    {
        List<Opportunity> OppstoInsert=new List<Opportunity>();
        for(Integer i=0;i<noOfOpps;i++)
        {
        Opportunity testOpportunity = new Opportunity(IM_Servicing_Region__c='Houston',IM_Booked_Date__c=Date.today(), StageName='1 - Qualification', AccountId = actId, CloseDate = System.today(),Recordtypeid=Recordtype);
        testOpportunity.Name = (name == null)? 'testOpp'+i : name;
        OppstoInsert.add(testOpportunity); 
        }
        if( doInsert)
            insert OppstoInsert;
        return OppstoInsert;

    }

    
    public static Case createCase(Opportunity opp, Contact testContact, Boolean doInsert)
    {
        Case testCase = new Case(NCSP_Opportunity__c=opp.Id, ContactId=testContact.Id);
        if(doInsert)
            insert testCase;
        return testCase;
    }

    public static List<Case> createCases(Integer howMany, Opportunity opp, Contact testContact, Boolean doInsert)
    {
        List<Case> testCases = new List<Case>();
        for (Integer i=0; i<howMany; i++) 
            testCases.add(new Case(NCSP_Opportunity__c=opp.Id, ContactId=testContact.Id));
        if(doInsert)
            insert testCases;
        return testCases;
    }

    public static Attachment createAttachment (String name, Id parentID, String body, Boolean doInsert)
    {
        Attachment testAttachment = new Attachment();
        testAttachment.Name = (name == null)? 'testAttachment' : name;
        testAttachment.ParentId = parentId;
        testATtachment.Body = Blob.valueOf( body );
        if( doInsert)
            insert testAttachment;
        return testAttachment;

    }


    /*
        @param String - Name
        @param Id     - Opportunity Id
        @param Map<String,Object> - Additional values map
                                    NOTE: It can be null
        @param boolean
        @return Customer_Profile__c

    */
    public static Customer_Profile__c createCustomerProfile (Id oppId, Map<String,Object> additionalValues, Boolean doInsert)
    {
        Customer_Profile__c testProfile = new Customer_Profile__c(Opportunity__c = oppId, Same_as_Service_Address__c = true, Same_as_Service_Address_cor__c= true, Sales_Rep_percent__c=100);
        if( null != additionalValues) mergeValues ( testProfile ,additionalValues) ;
        if( doInsert) insert testProfile;
        return testProfile;
    }

    public static List<Competitor__c> createCompetitors( Integer numToCreate, String name, boolean doInsert )
    {
        List<Competitor__c> testCompetitors = new List<Competitor__c>();
        for( Integer i = 0; i < numToCreate; i++ )
        {
            testCompetitors.add( createCompetitor( name, false ) );
        }
        if( doInsert )
            insert testCompetitors;
        return testCompetitors;
    }

    public static Competitor__c createCompetitor (String name, boolean doInsert) {

        Competitor__c competitor = new Competitor__c(name = name + unique_number++ );

        if(doInsert)
            insert competitor;

        return competitor;
    }
    
    
    public static List<Storage_Profile__c> createStorageProfiles( Integer numToCreate, ID ironMountainStorageProfileID, Id customerAccountId, ID competitorID, decimal tape, decimal dbnr, decimal cubeQuantity, Boolean doInsert )
    {
        List<Storage_Profile__c> testStorageProfiles = new List<Storage_Profile__c>();
        for( Integer i = 0; i < numToCreate; i++ )
        {
            testStorageProfiles.add( createStorageProfile( ironMountainStorageProfileID, customerAccountId, competitorID, tape, dbnr, cubeQuantity, false ) );
        }
        if( doInsert )
            insert testStorageProfiles;
        return testStorageProfiles;
    }

    public static Storage_Profile__c createStorageProfile(ID ironMountainStorageProfileID, Id customerAccountId, ID competitorID, decimal tape, decimal dbnr, decimal cubeQuantity, Boolean doInsert)
    {
        Storage_Profile__c testStorageProfile = new Storage_Profile__c();
        testStorageProfile.Iron_Mountain_Storage_Profile__c = ironMountainStorageProfileID;
        testStorageProfile.Quantity_Tape__c = tape;
        testStorageProfile.Quantity_DB_R_Container__c = dbnr;
        testStorageProfile.Quantity_Cube__c = cubeQuantity;
        testStorageProfile.vendor__c = competitorID;
        testStorageProfile.customer__c = customerAccountId;

        if(doInsert)
            insert testStorageProfile;
        return testStorageProfile;
    }

    
    public static List<Iron_Mountain_Storage_Profile__c> createIronMountainStorageProfiles( Integer numToCreate, ID accountID, decimal tape, decimal dbnr, decimal cubeQuantity, Boolean doInsert )
    {
        List<Iron_Mountain_Storage_Profile__c> imStorageProfiles = new List<Iron_Mountain_Storage_Profile__c>();
        for( Integer i = 0; i < numToCreate; i++ )
        {
            imStorageProfiles.add( createIronMountainStorageProfile( accountID, tape, dbnr, cubeQuantity, false ) );
        }
        if( doInsert )
            insert imStorageProfiles;
        return imStorageProfiles;
    }

    public static Iron_Mountain_Storage_Profile__c createIronMountainStorageProfile(ID accountID, decimal tape, decimal dbnr, decimal cubeQuantity, Boolean doInsert)
    {
        Iron_Mountain_Storage_Profile__c imStorageProfile = new Iron_Mountain_Storage_Profile__c();
        imStorageProfile.account__c = accountID;
        imStorageProfile.IM_Quantity_Tape__c = tape;
        imStorageProfile.IM_Quantity_DB_R_Container__c = dbnr;
        imStorageProfile.IM_Quantity_Cube__c = cubeQuantity;
        imStorageProfile.Profiled_Quantity_Tape__c = tape;
        imStorageProfile.Profiled_Quantity_DB_R_Container__c = dbnr;
        imStorageProfile.Profiled_Quantity_Cube__c = cubeQuantity;

        if(doInsert)
            insert imStorageProfile;

        return imStorageProfile;
}


    /*
        @param SObject - sobject to merge values into. *This object will be modified!
    */
    public static void mergeValues(SObject sobj, Map<String, Object> fieldToValue)
    {
        for ( String fieldName : fieldToValue.keySet()  ){
            sobj.put( fieldName, fieldToValue.get(fieldName) );
        }
    }

    /*Added By: Srinivasa Rao mandalapu
      Case No : 01429420*/
    /*Start*/
    
    //Commenting as part of Gitlab story #25402
    /*
    public static List<BoB_Coverage__c> createBoBCoverages( Integer numToCreate, Id accId, String nameIn, String prodCoverage, String country, Boolean doInsert )
    {
        List<BoB_Coverage__c> testCoverages = new List<BoB_Coverage__c>();
        for( Integer i=0; i<numToCreate; i++ )
        {
            testCoverages.add( new BoB_Coverage__c( Account__c = accId, Country_Coverage__c = country, Product_Coverage__c = prodCoverage, Name = nameIn ,RecordTypeId=M2_IMGA_ID ) );
        }

        if(doInsert)
            insert testCoverages;


       return testCoverages;
    }
*/
    /*End*/
    
    //Commenting as part of Gitlab story #25402
/*    
    public static List<BoB_Coverage_Eligible__c> createBoBCoverageEligibles(List<Account> accounts, Boolean doInsert )
    {
        List<BoB_Coverage_Eligible__c> testEligibles = new List<BoB_Coverage_Eligible__c>();
        for(Account a:  accounts)
        {
            testEligibles.add( new BoB_Coverage_Eligible__c( Account__c = a.id) );
        }

        if(doInsert)
            insert testEligibles;

        return testEligibles;
    }
*/

     public static IM_Customer_Account__c createCustomerAccount( Id accountId, Boolean doInsert )
     {
         
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
 /*account a = new Account(name='x');
        insert a;
       accountId=a.id;*/
         system.debug('kkkkkkkkkkk'+accountId);
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test'+ string.valueOf(Math.random());
        custAcc.Owning_District_Id__c = testMarket.Id;
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = accountId;
         system.debug('+++++++++'+ custAcc.IM_Account__c);
        if( doInsert)
        {
            insert custAcc;
        }
        return custAcc;
    }

    public static NCSP_DBR_Products__c setupNCSP_DBR_ProductsCustomSetting( String itemName, String productName, String caseRecordTypeId, String opportunityType, Boolean doInsert )
    {
        NCSP_DBR_Products__c dbrProduct = new NCSP_DBR_Products__c();
        dbrProduct.Name = itemName;
        dbrProduct.Product_Name__c = productName;
        dbrProduct.Case_RecordTypeId__c = caseRecordTypeId;
        dbrProduct.Opportunity_Type__c = opportunityType;
        if( doInsert)
        {
            System.runAs(ADMIN_USER)
            {
                insert dbrProduct;
            }
        }
        return dbrProduct;
    }

    public static List<IM_Customer_Account__c> createIMCustomerAccounts(Integer numToCreate, Id accountId, Boolean doInsert){

        List<IM_Customer_Account__c> imCustomerAccounts = new List<IM_Customer_Account__c>();
        for (Integer i=0; i<numToCreate; i++){
            imCustomerAccounts.add(new IM_Customer_Account__c(IM_Account__c=accountId));
        }
        if (doInsert)
            insert imCustomerAccounts;
        return imCustomerAccounts;
    }


    public static Product2 createProduct(String name, Boolean doInsert){
        Product2 prod = new Product2(Name = name, IsActive= true);
        if (doInsert) {
            insert prod;
        }
        return prod;
    }
    public static Pricebook2 createPriceBook(String pbName, Boolean doInsert){
        Pricebook2 pricebook = new Pricebook2(Name=pbName);
        if (doInsert){
            insert pricebook;
        }
        return pricebook;
    }

    public static PriceBookEntry createPriceBookEntry(Id prodId, Id pbeId, Boolean doInsert){
        //PriceBookEntry priceBookEntry = new PriceBookEntry(Product2Id = prodId, Pricebook2Id = pbeId, UnitPrice = 1, IsActive = true);
        
        PricebookEntry priceBookEntry = new PricebookEntry(IsActive=true,UnitPrice=1,UseStandardPrice = false, CurrencyIsoCode='USD', Product2Id=prodId,Pricebook2Id=pbeId);
     
        if (doInsert){
            insert priceBookEntry;
        }
        return priceBookEntry;
    }
    
    public static OpportunityLineItem createOLI(Id testPriceBookEntryId, Id testOppId, Boolean doInsert){
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, TotalPrice = 1, PricebookEntryId = testPriceBookEntryId, OpportunityId = testOppId );
        if (doInsert){
            insert oppProd;
        }
        return oppProd;
    }

   public static List<SFDC_Acct_Plan__c> createAccountPlans( Integer numToCreate,  Boolean doInsert )
   {
        List<SFDC_Acct_Plan__c> accountPlans = new List<SFDC_Acct_Plan__c>();
        for (Integer i=0; i<numToCreate; i++){
            accountPlans.add(new SFDC_Acct_Plan__c());
        }
        if (doInsert)
            insert accountPlans;
        return accountPlans;
   }

   public static List<Objective__c> createObjectives( Integer numToCreate, Id accountPlanId, Id assignToId, Boolean doInsert )
   {
        List<Objective__c> testObjectives = new List<Objective__c>();
        for( Integer i = 0; i < numToCreate ; i++ )
        {
            Objective__c anObjective = new Objective__c();
            anObjective.Name = 'testObj3ctive';
            anObjective.Account_Plan__c = accountPlanId;
            anObjective.Assigned_To__c = assignToId;
            testObjectives.add( anObjective );
        }
        if( doInsert )
            insert testObjectives;
        return testObjectives;
   }
   
   public static List<Solution> createSolutions( Integer numToCreate, Boolean doInsert){
        List<Solution> solutions = new List<Solution>();
        for (Integer i=0; i < numToCreate; i++){
            Solution s = new Solution(SolutionName = 'Test '+ i);
            solutions.add(s);
            
        }
        if (doInsert) 
            insert solutions;
        return solutions;
   }
   
   public static List<Schedule_A__c> createPAModels( Integer numToCreate, Boolean doInsert )
   {
        List<Schedule_A__c> testPaModels = new List<Schedule_A__c>();
        
        for (Integer i=0; i < numToCreate; i++){
            Schedule_A__c s = new Schedule_A__c();
            if (doInsert){
                s.Reference__c = 'Testing Files'+i;
                testPaModels.add(s);
            } else {
                testPaModels.add(s);
            }
       }
        if (doInsert) 
            insert testPaModels;
        return testPaModels;
   }
   
   public static List<Schedule_A_Quote_Item__c> createPAModelLineItems( Id paModelId, Integer numToCreate, Boolean doInsert )
   {
        List<Schedule_A_Quote_Item__c> testPaModelLineItems = new List<Schedule_A_Quote_Item__c>();
        
        for (Integer i=0; i < numToCreate; i++){
            Schedule_A_Quote_Item__c s = new Schedule_A_Quote_Item__c( Schedule_A__c = paModelId);
            testPaModelLineItems.add(s);
            
        }
        if (doInsert) 
            insert testPaModelLineItems;
        return testPaModelLineItems;
   }
   

   public static List<Quote> createQuotes( Id oppId, Integer numToCreate, Boolean doInsert )
   {
        List<Quote> testQuotes = new List<Quote>();
        
        for (Integer i=0; i < numToCreate; i++){
            Quote q = new Quote(OpportunityId = oppId, Name = 'Test Quote' + i);
            testQuotes.add(q);
            
        }
        if (doInsert) 
            insert testQuotes;
        return testQuotes;
   }
    
   // 33583 Method modifications done as part of "Test class cleanup to support deployment" story
   public static List<FeedItem> createFeedRecord ( Integer numFeeds, String testTitle, Id parentId, String stringContent, Boolean doInsert)
    {
        List<FeedItem> testPAModelFeeds = new List<FeedItem>();
        List<ContentVersion> contVersions = new List<ContentVersion>();
		List<FeedAttachment> attachments = new List<FeedAttachment>();
        
        for(Integer i = 0; i < numFeeds; i++)
        {
            FeedItem testFeed = new FeedItem();
            testFeed.ParentId = parentId;
            testFeed.Body = stringContent + i;
            // 33583 Test class cleanup to support deployment
            //testFeed.Type = 'ContentPost';
            //testFeed.ContentData = Blob.valueOf( stringContent + i );
            //testFeed.ContentFileName = testTitle;
            //testFeed.Title = testTitle;
            
            // 33583 Test class cleanup to support deployment
            ContentVersion contVersion = new ContentVersion(
                Title='Test'+string.valueOf(i), 
                PathOnClient ='Test'+string.valueOf(i)+'.jpg',
                VersionData = Blob.valueOf( stringContent + i ), 
                origin = 'H'
            );
            
            testPAModelFeeds.add(testFeed);
            // 33583 Test class cleanup to support deployment
            contVersions.add(contVersion);
        }
        
        if(doInsert){
            insert testPAModelFeeds;
            // 33583 Test class cleanup to support deployment
            insert contVersions;
        }    
        // 33583 Test class cleanup to support deployment
        for(Integer i = 0; i < numFeeds; i++){
            FeedAttachment feedAttachment = new FeedAttachment();
            feedAttachment.FeedEntityId = testPAModelFeeds[i].Id;          
            feedAttachment.RecordId = contVersions[i].Id;  
            feedAttachment.Type = 'Content';
			attachments.add(feedAttachment); 
        }
        if(doInsert){
            insert attachments;
        }
        return testPAModelFeeds;            
    }
   
   public static Billing_Territory__c createBillingTerritory(String territoryName, String territoryRegion, Boolean doInsert){

        Billing_Territory__c billingTerritory = new Billing_Territory__c();
        
        billingTerritory.Name = territoryName; 
        billingTerritory.Region__c = territoryRegion; 
        
        if (doInsert) 
            insert billingTerritory;

        return billingTerritory;
        
   }
   
      public static List<Parent_Billing_Market__c> createParentBillingMarketRecords( Integer size, Boolean doInsert )
    {
        List<Parent_Billing_Market__c> testPBillingMarkets = new List<Parent_Billing_Market__c>();
        
        for(Integer i = 0; i < size; i++)
        {
            Parent_Billing_Market__c pbMarket = new Parent_Billing_Market__c();
            pbMarket.Name = 'Test Parent Bill' + i;
            pbMarket.Country_Coverage__c = 'Canada';
            testPBillingMarkets.add( pbMarket );
        }
        
        if(doInsert)
            insert testPBillingMarkets;
            
        return testPBillingMarkets;
    }
    
    public static List<Billing_Market__c> createBillingMarketRecords( String marketName, Integer size, Boolean doInsert )
    {
        List<Billing_Market__c> testBillingMarkets = new List<Billing_Market__c>();
        
        for(Integer i = 0; i < size; i++)
        {
            Billing_Market__c bMarket = new Billing_Market__c();
            bMarket.Name = 'Test Bill' + i;
            bMarket.Market_Name__c = marketName;
            testBillingMarkets.add( bMarket );
        }
        
        if(doInsert)
            insert testBillingMarkets;
            
        return testBillingMarkets;
    }
   
   public static Parent_Billing_Market__c createParentBillingMarket(String parentBillingMarketName, Id territoryId, Boolean doInsert){

        Parent_Billing_Market__c parentBillingMarket = new Parent_Billing_Market__c();
        
        parentBillingMarket.Name = parentBillingMarketName; 
        parentBillingMarket.Territory__c = territoryId; 
        
        if (doInsert) 
            insert parentBillingMarket;

        return parentBillingMarket;
        
   }
   
   public static Billing_Market__c createBillingMarket(String billingMarketName, String marketName, Id parentBillingMarketId, Boolean doInsert){

        Billing_Market__c billingMarket = new Billing_Market__c();
        
        billingMarket.Name = billingMarketName; 
        billingMarket.Market_Name__c = marketName; 
        billingMarket.Parent_Billing_Market__c = parentBillingMarketId; 
        
        if (doInsert) 
            insert billingMarket;

        return billingMarket;
        
   }
   
   public static List<Inbound_Storage__c> createInboundStorageRecordsWithCubeMarket(Integer numToCreate, Id billingMarketId, Id customerAccountId, Boolean doInsert){

        List<Inbound_Storage__c> inboundStorageRecords = createInboundStorageRecords(numToCreate, customerAccountId, false);

        for (Inbound_Storage__c inbound : inboundStorageRecords){
            inbound.Cube_District__c = billingMarketId;
        }

        if (doInsert) 
            insert inboundStorageRecords;

        return inboundStorageRecords;
        
   }
   
   public static List<Inbound_Storage__c> createInboundStorageRecords(Integer numToCreate, Id customerAccountId, Boolean doInsert){

        List<Inbound_Storage__c> inboundStorageRecords = new List<Inbound_Storage__c>();

        for (Integer i=0; i < numToCreate; i++){
            Inbound_Storage__c inbound = new Inbound_Storage__c();
            inbound.Customer_Account__c = customerAccountId;
            inbound.Storage_Date__c = Date.today();
            inboundStorageRecords.add(inbound);
        }

        if (doInsert) 
            insert inboundStorageRecords;

        return inboundStorageRecords;
        
   }
       public static List<Inbound_Storage__c> createInboundStorageRecords( IM_Customer_Account__c customerAccount, Billing_Market__c cubeDistrict,
                                                                        Date storageDate, 
                                                                        Integer size, Boolean doInsert )
    {
        List<Inbound_Storage__c> testInboundStorageRecords = new List<Inbound_Storage__c>();
        
        for(Integer i = 0; i < size; i++)
        {
            Inbound_Storage__c inboundStorage = new Inbound_Storage__c();
            inboundStorage.Customer_Account__c = customerAccount.Id;
            inboundStorage.Cube_District__c = cubeDistrict.Id;
            inboundStorage.Storage_Date__c = storageDate;
            
            testInboundStorageRecords.add( inboundStorage );
        }
        
        if(doInsert)
            insert testInboundStorageRecords;
            
        return testInboundStorageRecords;
    }

    //Commenting as part of Gitlab story #25402
/*      
    public static BoB_Coverage_Eligible__c createBoBCoverageEligible(ID accountID,  boolean isInsert ){
        BoB_Coverage_Eligible__c eligibleToReturn = new BoB_Coverage_Eligible__c ();
        //eligibleToReturn.Account__c = accountID;
        
        if(isInsert){
            insert eligibleToReturn;
        }
        
        return eligibleToReturn;
    }
*/ 

   public static List<Territory_Snapshot__c> createTerritorySnapshots(Integer howMany, Id territoryId, Boolean doInsert){
        List<Territory_Snapshot__c> snapshots = new List<Territory_Snapshot__c>();
        for (Integer i = 0; i < howMany; i++ ){
            Territory_Snapshot__c snapshot = new Territory_Snapshot__c();
            snapshot.Territory__c = territoryId;
            snapshots.add(snapshot);
        }
        if (doInsert)
            insert snapshots;
        return snapshots;
   }
    //**********#30153 At Risk: Decommission Current Ending Balance object**********//
 /*  public static List<Current_Ending_Balance__c> createCurrentEndingBalances(Integer howMany, Boolean doInsert){
        List<Current_Ending_Balance__c> balances = new List<Current_Ending_Balance__c>();
        for (Integer i = 0; i < howMany; i++ ){
            Current_Ending_Balance__c balance = new Current_Ending_Balance__c();
            balances.add(balance);
        }
        if (doInsert)
            insert balances;
        return balances;
   }*/
   
          public static void dummyInsert(List<SObject> objects)
    {
           String Id_Prefix = objects[0].getSObjectType().getDescribe().getKeyPrefix();
           for( Integer i = 0; i < objects.size(); i++ )
           {
                   String idSuffix = String.valueOf( offsetForDummyInsert ).leftPad(12);
                   idSuffix = idSuffix.replace(' ', '0');
                   
                   objects[i].id= Id_Prefix + idSuffix;
                   offsetForDummyInsert+=1;
           }
   }

   public static List<IM_Customer_Account__c> createCustomerAccounts (Integer numOfCustAccounts, Id accountId, Boolean isInsert )
    {
        List<IM_Customer_Account__c> custList = new List<IM_Customer_Account__c>();
        for ( Integer i = 0; i < numOfCustAccounts; i++ )
        {
            IM_Customer_Account__c testCustomerAccount = new IM_Customer_Account__c( IM_Account__c = accountId, IM_Customer_Account_Name__c = 'testacc_' + i );
            custList.add(testCustomerAccount);
        }
        if( isInsert )
        {
            insert custList;
        }
        
        return custList;
    }
    
    public static List<IME_SC_CAc_Responsibility__c> createCacs ( Integer numOfCacs, Id testCustomerAccountId, Id testContactId, Boolean isInsert )
    {
        List<IME_SC_CAc_Responsibility__c> testCacs = new List<IME_SC_CAc_Responsibility__c>();
        
        for ( Integer i = 0; i < numOfCacs; i++ )
        {
             IME_SC_CAc_Responsibility__c testCac = new IME_SC_CAc_Responsibility__c( IME_SC_Customer_Account__c = testCustomerAccountId, 
                                                          IME_SC_Contact__c = testContactId, IME_CAc_Responsibility__c = 'TestCac_' + i );
        
             testCacs.add ( testCac );
        }
        if ( isInsert )
        {
            insert testCacs;
        }

        return testCacs;
    }
    
    
    public static IME_SC_CAc_Responsibility__c createCac ( Id testCustomerAccountId,String responsibility, Id testContactId, Boolean isInsert )
    {
        
        IME_SC_CAc_Responsibility__c testCac = new IME_SC_CAc_Responsibility__c( IME_SC_Customer_Account__c = testCustomerAccountId, 
                                                  IME_SC_Contact__c = testContactId, IME_CAc_Responsibility__c = responsibility );

        if ( isInsert )
        {
            insert testCac;
        }

        return testCac;
    }

    //Commenting as part of Gitlab story #25402
/*  
    public static List<Aggregate_Volume__c> createAggregateVolumes ( Id bobEligibleId, Integer size, Boolean isInsert )
    {
        List<Aggregate_Volume__c> testVolumes = new List<Aggregate_Volume__c>();
        
        for ( integer i = 0; i < size; i++ )
        {
            testVolumes.add( new Aggregate_Volume__c( BoB_Coverage_Eligible__c = bobEligibleId ) );
        }
        
        if ( isInsert )
        {
            insert testVolumes;
        }

        return testVolumes;
    }
*/
    
    public static Dashboard_Quick_Links__c createDashboardQuickLink( String nameIn, String dashboardIdIn, String linkLabelIn, String mainDBId, Boolean doInsert )
    {
        Dashboard_Quick_Links__c dashboardQuickLink = new Dashboard_Quick_Links__c( Name = nameIn, Dashboard_ID__c = dashboardIdIn, Link_Label__c = linkLabelIn, Current_Dashboard_ID__c = mainDBId );
        if( doInsert )
        {
            System.runAs( ADMIN_USER )
            {
                insert dashboardQuickLink;
            }
        }

        return dashboardQuickLink;
    }
	
    //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
    /*public static List<Account_Sub_Segment__c> createAccountSegments ( String name, Integer size, Boolean isInsert )
    {
        List<Account_Sub_Segment__c> testAcctSegments = new List<Account_Sub_Segment__c>();
        
        for ( integer i = 0; i < size; i++ )
        {
            testAcctSegments.add( new Account_Sub_Segment__c( Name  = name + unique_number++) );
        }
        
        if ( isInsert )
        {
            insert testAcctSegments;
        }

        return testAcctSegments;
    }
    */

    public static Prospecting_Entry__c createProspectingEntry(Id ownerId, Boolean submitted, Boolean doDml){
        Prospecting_Entry__c p = new Prospecting_Entry__c(
            OwnerId = ownerId,
            Start_Date__c = ProspectingContExt.static_getThisMonday(),
            End_Date__c = ProspectingContExt.static_getThisMonday()+4,
            Status__c = 'Not Submitted',
            of_hours_spent_prospecting_this_week__c = 10,
            of_initial_meetings_set_up_this_week__c = 10,
            of_prospecting_emails_sent_this_week__c = 10,
            of_prospecting_calls_made_this_week__c  = 10
        );
        if(submitted){
            p.Status__c = 'Submitted';
            p.IsSubmitted__c = true;
        }
        if(doDml) insert p;
        return p;
    }   
    
     
    public static SKP_Contract_Type_Mapping__c createSkpMappingObject(string country, string version, boolean doInsert){
        SKP_Contract_Type_Mapping__c mappingObject = new SKP_Contract_Type_Mapping__c(Country__c =country, Contract_Version__c = version);
        mappingObject.Initial_Term__c = '12';
        mappingObject.Renewal_term__c = '1';
        mappingObject.Effective_Date__c = 'Schedule A';
        mappingObject.Late_Fee_Indicator__c = 'Yes';
        mappingObject.Late_Fee_Percent__c = '10';
        mappingObject.Fuel_Surcharge_Indicator__c  = 'Yes';
        mappingObject.Net_Payment__c = '100';
        mappingObject.Indemnification_Customer__c = 'Yes';
        mappingObject.Indemnification_Iron_Mountain__c = 'Yes';
        mappingObject.Excess_Value_of_Deposit__c = 'Value';
        mappingObject.RM_Admin_Fee__c = 'Yes';
        mappingObject.Insurance_Special__c = 'Yes';
        mappingObject.Rate_Increase_Notice__c = '0';
        mappingObject.Increase_Cap_Quoted__c = '0';
        
        
        if(doInsert){
            insert mappingObject;
        }
        
        return mappingObject;
    }
    
    public static QuoteLineItem createQuoteLineItem (String pbeid, string qid, boolean isInsert){
        QuoteLineItem qli = new QuoteLineItem(PricebookEntryId= pbeid, quoteid = qid, UnitPrice = 1, Quantity = 10);
        
        if(isInsert){
            insert qli;
        }
        
        return qli;
    }
    
    public static SKP_Minimum_Mapping__c createSKPMinMapping (String billCode, boolean isUpsert){
        SKP_Minimum_Mapping__c mapping = new SKP_Minimum_Mapping__c(name = billcode);
        mapping.Minimum_Type__c = 'Test Type';
        mapping.Minimum_Order_Type__c = 'Test Order';
        mapping.Minimum_Storage_Type__c = 'Test Storage';
        mapping.Minimum_Level__c = 'Test level';
        
        if(isUpsert){
            upsert mapping;
            
        }
        
        return mapping;
    }
    
    public static SKP_Bill_Code_UOM__c createBillCodeUOM(string nameParam, string uomParam, boolean isInsert){
        SKP_Bill_Code_UOM__c billCodeUOM = new SKP_Bill_Code_UOM__c(name = nameParam, SKP_UOM__c = uomParam); 
        
        if(isInsert){
            upsert billCodeUOM;
        }
        
        return billCodeUOM;
    }
    
    public static SKP_Sync_Error__c createSKPSyncError (String caseId, String code, String message, string severity, string syncType, boolean doInsert){
        SKP_Sync_Error__c syncError = new SKP_Sync_Error__c(Error_Code__c = code, Error_Description__c= message, Case__c = caseId, Sync_Validate__c = syncType, Severity__c = severity );
      
        if(doInsert){
            insert syncError;
        }
        return syncError;
    } 
    
    public static List<dsfs__DocuSign_Status__c> createDocusignStatus(Opportunity opp, Integer howMany,boolean doInsert)
    {
        List<dsfs__DocuSign_Status__c> docuSignStatusList = new List<dsfs__DocuSign_Status__c>();
        for (Integer i = 0; i < howMany; i++ ){
            dsfs__DocuSign_Status__c aDocuSign = new dsfs__DocuSign_Status__c();
            aDocuSign.dsfs__Opportunity__c = opp.Id;
            docuSignStatusList.add(aDocuSign);
        }
        if (doInsert)
            insert docuSignStatusList;
        return docuSignStatusList;
    }
    
     public static Case_Customer_Account__c createCaseCustomerAccount(Id caseId, Id customerAccountId, Boolean doInsert )
     {
         system.debug('Case__c=='+caseId);
          system.debug('customerAccountId==='+customerAccountId);
        Case_Customer_Account__c testCaseCustomerAccount = new Case_Customer_Account__c();
        testCaseCustomerAccount.Case__c = caseId;
        testCaseCustomerAccount.Customer_Account__c = customerAccountId;
        if( doInsert)
        {
            insert testCaseCustomerAccount;
        }
        return testCaseCustomerAccount;
    }
    
     /**
    *   @description This method simulate the batchable run
    *   @param batch the batchable to simulate
    */
    public static void simulateBatchRun(Database.Batchable<SObject> batch) {
        simulateBatchRun(batch, 200);
    }

    /**
    *   @description This method simulate the batchable run with a specific scope size
    *   @param batch the batchable to simulate
    *   @param scopeSize the size of the scope in each batch
    */
    public static void simulateBatchRun(Database.Batchable<SObject> batch, Integer scopeSize) {
        Iterable<Sobject> canIter = batch.start(null);
        Iterator<Sobject> records;
        if (canIter instanceof Database.QueryLocator) {
            Database.QueryLocator asQueryLoc = (Database.QueryLocator) canIter;
            records = asQueryLoc.iterator();
        } else {
            records = canIter.iterator();
        }
        List<Sobject> recordsList = new List<Sobject>();
        for (Integer i=0; i<scopeSize && records.hasNext(); i++) {
            recordsList.add(records.next());
        }
        batch.execute(null, recordsList);
        batch.finish(null);
    }
}