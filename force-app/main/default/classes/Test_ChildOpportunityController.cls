@isTest
public class Test_ChildOpportunityController {
    
      public static Account testAccount1;
    public static Account testAccount2;
    public static Account testAccountIMGA1;
    public static Account testAccountIMGA2;
    public static Opportunity testOpp1;
    public static Opportunity testOpp2;
    public static Opportunity testOpp3;
	//public static Opportunity testOpp4; //KUldeep
    public static List<Opportunity> lstOp = new List<Opportunity>();
    public static List<Account> lstAcc = new List<Account>();
    public static Database.SaveResult[] srList ;
    
    
    public static void setup() 
    {   
        system.debug('setup called times');
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
            lstAcc.add(testAccount1);
        testAccount2 = new Account();
            testAccount2.Name = 'TestAccount2';
            testAccount2.BillingCountry = 'United States';
            testAccount2.BillingPostalCode = '11209';
            testAccount2.BillingState = 'NY';   
            lstAcc.add(testAccount2);
        testAccount2.ParentId = testAccount1.id;
            
        testAccountIMGA1 = new Account();
            testAccountIMGA1.Name = 'testAccountIMGA1';
            testAccountIMGA1.BillingCountry = 'United States';
            testAccountIMGA1.BillingPostalCode = '11209';
            testAccountIMGA1.BillingState = 'NY';   
            testAccountIMGA1.IM_Hierarchy_Level__c = 'Sales (Site)';
            lstAcc.add(testAccountIMGA1);
        testAccountIMGA2 = new Account();
            testAccountIMGA2.Name = 'testAccountIMGA2';
            testAccountIMGA2.BillingCountry = 'United States';
            testAccountIMGA2.BillingPostalCode = '11209';
            testAccountIMGA2.BillingState = 'NY';   
            lstAcc.add(testAccountIMGA2);
        
        insert lstAcc;
        
      /*  testOpp1=TestingUtils.createOpportunity('TestOpp1',testAccount1.id,true); 
        testOpp2=TestingUtils.createOpportunity('TestOpp2',testAccount1.id,true); 
        testOpp3=TestingUtils.createOpportunity('TestOpp3',testAccount2.id,true); 
*/
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
              oppprodsel.Name = 'CloudSolutionsProduct';
              oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
              oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
              insert oppprodsel; 
         Country_Settings__c setting = new Country_Settings__c();
            setting.Name = 'United States';
            setting.object_name__c = 'Account';
        insert setting;
        
     /*   Opportunity_Security__c opsec = new Opportunity_Security__c();
        opsec.Name = 'lead owner';
            opsec.Field_Name__c = 'IM_Original_Lead_Owner__c0';
            opsec.Object_Name__c = 'Opportunity';
            opsec.Visibility_Access_Level__c = 'W';
        insert opsec;
*/
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
                                        ,CurrencyIsoCode='GBP',pricebook2ID= standardPB
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
                                        ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,IM_Original_Lead_Owner__c = u.id
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
                                        ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,IM_Original_Lead_Owner__c = u.id
                                      );
            lstOp.add(testOpp3);
        
       srList = database.insert(lstOp);
/*	   
	   testOpp4 = new Opportunity(
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
    
    static testMethod void testMethod1()
    {
        setup();
        RecordType IMGAAccType = [select id from RecordType where name = 'IMGA Record Type'
                                and sObjectType = 'Account'];
       
         testOpp2.IM_Parent_Opportunity__c=testOpp1.id;
         testAccount1.RecordTypeId = IMGAAccType.id;
        testAccount1.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
        	testAccount2.recordtypeid = IMGAAccType.id;
        	testAccount2.IM_Hierarchy_Level__c = 'IM Group (IMGA)';       
        
              Test.StartTest();
        update testAccount1;
        update testAccount2;
            ApexPages.StandardController sc = new ApexPages.StandardController(testOpp2);
            ChildOpportunityController controller = new ChildOpportunityController(sc);
            PageReference pageRef = Page.ChildOpportunityPage;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('id', String.valueOf(srList[0].Id));
        
            controller.RemoveParentOppty();
            controller.RemoveChildOppty();     
        Test.StopTest();
        

    }
    
    static testMethod void testMethod2()
    {
        setup();
         Test.StartTest();
        testAccountIMGA2.IM_Hierarchy_Level__c = 'Sales (Site)';
        update testAccountIMGA2;
        testAccount1.ParentId = testAccountIMGA1.id;
        update testAccount1;
        testAccount2.ParentId = testAccountIMGA2.id;
        update testAccount2;
        
        testOpp3.IM_Parent_Opportunity__c=testOpp1.id;
        update testOpp3;
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp3);
        ChildOpportunityController controller = new ChildOpportunityController(sc);
		boolean tempOptions = controller.isoptylist;
		//boolean temp = controller.isparentlist;
        controller.RemoveParentOppty();
            controller.RemoveChildOppty(); 
        Test.StopTest();
    }
	
   
    static testMethod void testMethod4()
    {
        setup();
        Test.StartTest();

        testOpp2.IM_Parent_Opportunity__c=testOpp1.id;
        update testOpp2;
        //ApexPages.StandardController sc = new ApexPages.StandardController(testOpp2);
        PageReference pageRef = Page.CustomOpportunityLookup;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('hiddenId',testOpp2.id);
        ApexPages.currentPage().getParameters().put('opId',testOpp1.id);

        CustomOpportunityLookupController controller1 = new CustomOpportunityLookupController();
        controller1.condition='test';
        
        controller1.first();
        controller1.last();
        controller1.previous();
        controller1.next();
        controller1.updateopportunity();
        controller1.gotoPage();
        controller1.generateOpportunitysQuery();
        if(controller1.totalPageNumber>1)
        {system.debug('1');}
        if(controller1.pageNumber>1)
        {system.debug('1');}
        if(controller1.hasNext==true)
        {system.debug('1');}
        if(controller1.hasPrevious==true)
        {system.debug('1');}
        Test.StopTest();
        
    }
  

}