@isTest
public class Test_NCSPSellLiftWizardCtrExtlightning {
    public static Opportunity testOpp;
    public static NCSPSellLiftWizardCtrExtlightning ctr;
    
    static void setup()
        
    {
        //setupCustomSettings();
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        Account testAct = TestingUtils.createAccounts(1, true)[0];
        Opportunity testOpp = new Opportunity();
        testOpp.name = 'testOpp';
        testOpp.AccountId = testAct.id;
        testOpp.CloseDate = Date.today();
        testOpp.StageName = '1 - Qualification';
        testOpp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        testOpp.Amount = 500;
        //insOpp.Pricebook2Id=pricebookId;
        insert testOpp;
        //testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, false);
       
        //testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, true);
        System.debug('Opportunity create>>>>>'+testOpp);
        ApexPages.currentPage().getParameters().put(NCSPSellLiftWizardCtrExtlightning.OPP_ID_PARAM, testOpp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        ctr = new NCSPSellLiftWizardCtrExtlightning(sc);
        System.debug('Controller>>>>>'+ctr);
    }
    
    
    private static void setupCustomSettings()
    {
        TestingUtils.setupCountryCustomSettings(true); 
        TestingUtils.setupOpportunitySecuritySettings(true);
    }
    
    static testMethod void testNCSPSellLiftWizardCtrExt()
    {
        Test.startTest(); 
        setup();
        Opportunity controllersOpp = ctr.opp;
        Test.stopTest();
        //System.assertEquals(testOpp.Id, testOpp.Id, 'The controllers opportunity should be the same opportunity as the one passed in from the parameter');
    }
    
    static testMethod void testOrderCompletedNextPageYes()
    {
        setup();
        PageReference expectedPage = Page.NCSPUpsellDetails;
        Test.startTest();
        Opportunity ctrOpp = ctr.opp;
        ctrOpp.Order_Completed__c = 'Yes';
        PageReference actualPage = ctr.orderCompletedNextPage();
        Test.stopTest();

    }
    
    static testMethod void testOrderCompletedNextPageNo()
    {
        setup();
        //PageReference expectedPage = new PageReference(Page.NCSPWizard_Step2_Lightning.getUrl() + '?' + NCSPWizardCtrl_Lightning.OPP_ID_PARAM + '=' + testOpp.Id);
        Test.startTest();
        Opportunity ctrOpp = ctr.opp;
        ctrOpp.Order_Completed__c = 'No';
        PageReference actualPage = ctr.orderCompletedNextPage();
        Test.stopTest();
        //System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'Since the opportunties order completed is no, the user should be taken to the following page');
    }
    
    static testMethod void testUpsellDetailsNextPage()
    {
        setup();
        PageReference previous = ApexPages.currentPage();
        PageReference expectedPage = Page.NCSPUpsellDetailsConfirmation_Lightning;
        Test.startTest();
        PageReference actualPage = ctr.upsellDetailsNextPage();
        Test.stopTest();
        System.assertEquals(previous, ctr.prev.get(ctr.prev.size()-1), 'The prev page should be set the users page prior to the redirect');
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The page should always go to the confirmation page');
    }
    
    static testMethod void testConfirmationNext()
    {
        setup();
        PageReference expectedPage = ctr.ctr.save();
        Test.startTest();
        PageReference actualPage = ctr.confirmationNext();
        Test.stopTest();
        //Opportunity opp = [Select Id, NCSP_Status__c from Opportunity where id = :testOpp.Id];
       // System.assertEquals(NCSPSellLiftWizardCtrExtlightning.CONFIRMATION_OPP_STATUS, opp.NCSP_Status__c, 'The NCSP status should always set to the expected value');
        //System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The user should always be redirected to the expected page');
    }
    
    static testMethod void testPrevious()
    {
        setup();
        PageReference expectedPrevious = new PageReference('/fakeURL');
        Test.startTest();
        ctr.prev.add(expectedPrevious);
        PageReference actualPrev = ctr.previous();
        Test.stopTest();
        System.assertEquals(expectedPrevious, actualPrev, 'The user should be redirected to the previous page');
    }
    
    static testMethod void testPreviousToCancel()
    {
        setup();
        PageReference expectedPage = ctr.ctr.cancel();
        Test.startTest();
        PageReference actualPage = ctr.previous();
        Test.stopTest();
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The user should be redirected to the opportunity standard controllers cancel');
    }
    
    @isTest
    static void testConstructor_OpportunityNotFound() {
        // Simulate scenario where Opportunity Id is not provided
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', null);
        ApexPages.StandardController controller = new ApexPages.StandardController(new Opportunity());
        NCSPSellLiftWizardCtrExtlightning controllerExt = new NCSPSellLiftWizardCtrExtlightning(controller);
        
        // Assert that the error message is added when no Opportunity Id is provided
        System.assertEquals(ApexPages.getMessages()[0].getSummary(), 'Opportunity Not Found');
        Test.stopTest();
    }
    
     @isTest
    static void testConstructor_OpportunityNotFoundInDatabase() {
        // Simulate scenario where Opportunity Id does not exist in the database
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', '001000000000000AAA'); // A non-existing Opportunity ID
        ApexPages.StandardController controller = new ApexPages.StandardController(new Opportunity());
        NCSPSellLiftWizardCtrExtlightning controllerExt = new NCSPSellLiftWizardCtrExtlightning(controller);
        
        // Assert that the error message is added for invalid Opportunity
        System.assertEquals(ApexPages.getMessages()[0].getSummary(), 'Please enter a valid Opportunity into the URL argument Id');
        Test.stopTest();
    }


    
}