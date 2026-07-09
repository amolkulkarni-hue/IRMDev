@isTest
private class TestNCSPSellLiftWizardCtrExt
{
  public static Opportunity testOpp;
  public static NCSPSellLiftWizardCtrExt ctr;

  static void setup()
  {
    setupCustomSettings();
    Account testAct = TestingUtils.createAccounts(1, true)[0];
    testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, true);
    ApexPages.currentPage().getParameters().put(NCSPSellLiftWizardCtrExt.OPP_ID_PARAM, testOpp.Id);
    ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
    ctr = new NCSPSellLiftWizardCtrExt(sc);
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
    System.assertEquals(testOpp.Id, controllersOpp.Id, 'The controllers opportunity should be the same opportunity as the one passed in from the parameter');
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
     //   System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'Since the opportunties order completed is yes, the user should be taken to the following page');
    }

    static testMethod void testOrderCompletedNextPageNo()
    {
        setup();
        PageReference expectedPage = new PageReference(Page.NCSPWizard_Step1.getUrl() + '?' + NCSPWizardCtrl.OPP_ID_PARAM + '=' + testOpp.Id);
        Test.startTest();
          Opportunity ctrOpp = ctr.opp;
          ctrOpp.Order_Completed__c = 'No';
          PageReference actualPage = ctr.orderCompletedNextPage();
        Test.stopTest();
        System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'Since the opportunties order completed is no, the user should be taken to the following page');
    }

    static testMethod void testUpsellDetailsNextPage()
    {
      setup();
      PageReference previous = ApexPages.currentPage();
      PageReference expectedPage = Page.NCSPUpsellDetailsConfirmation;
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
      Opportunity opp = [Select Id, NCSP_Status__c from Opportunity where id = :testOpp.Id];
      System.assertEquals(NCSPSellLiftWizardCtrExt.CONFIRMATION_OPP_STATUS, opp.NCSP_Status__c, 'The NCSP status should always set to the expected value');
      System.assertEquals(expectedPage.getUrl(), actualPage.getUrl(), 'The user should always be redirected to the expected page');
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
}