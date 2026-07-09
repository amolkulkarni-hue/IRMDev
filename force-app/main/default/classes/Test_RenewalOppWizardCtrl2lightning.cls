@isTest
public class Test_RenewalOppWizardCtrl2lightning {
    
    private static final String IMGA = 'IM_UCB';
    private static final String  DEAL_TYPE = 'DEAL TYPE';
    private static final String  SERVICE_LINE1 = 'SERVICE LINE1';
    private static final String  SERVICE_LINE2 = 'SERVICE LINE2';
    private static final String  UPSELL_TYPE1 = 'UPSELL TYPE1';
    private static final String  UPSELL_TYPE2 = 'UPSELL TYPE2';
    
    private static final String  TEST_CUSTOMER_ACCOUNT = 'Search String Customer Account';
    private static final String  ACTIVE = 'Active';
    
    private static Opportunity testOpportunity;
    private static Account testAccount;
    private static void setupCustomSettings()
    {
        TestingUtils.setupCountryCustomSettings(true);
        setupOpportunitySecuritySettings();
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        
    }
    
     private static void setupOpportunitySecuritySettings()
    {
       List<Opportunity_Security__c> settings = new List<Opportunity_Security__c>();
        //settings.add(new Opportunity_Security__c(Name='Enterprise Account Executive', Field_Name__c = 'IM_Enterprise_Account_Executive__c', Object_Name__c = 'Account', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Enterprise Account Manager', Field_Name__c = 'IM_Enterprise_Account_Manager__c', Object_Name__c = 'Account', Visibility_Access_Level__c = 'R') );
      //  settings.add(new Opportunity_Security__c(Name='Inside Sales – RM', Field_Name__c = 'physical_isr__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W') );
     /*   settings.add(new Opportunity_Security__c(Name='Physical Hybrid', Field_Name__c = 'physical_hybrid__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Physical RM', Field_Name__c = 'physical_rm__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );
        settings.add(new Opportunity_Security__c(Name='Physical – DB&R', Field_Name__c = 'physical_dp__c', Object_Name__c = 'Postal_Code', Visibility_Access_Level__c = 'W') );
*/
            
                insert settings;
          
    }
    
    static void setupOpportunity()
    {
        setupCustomSettings();
        testAccount = TestingUtils.createAccounts(1, false)[0];
        testAccount.IM_IMGA_Indexed__c = IMGA;
        insert testAccount;
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, true);
        List<IM_Customer_Account__c> custAccountsToInsert = new List<IM_Customer_Account__c>();
        IM_Customer_Account__c custAcc1 = TestingUtils.createCustomerAccount(testAccount.Id, false);
        custAccountsToInsert.add(custAcc1);
        IM_Customer_Account__c custAcc2 =TestingUtils.createCustomerAccount(testAccount.Id, false);
        custAcc2.IM_Status__c = ACTIVE;
        custAcc2.name = TEST_CUSTOMER_ACCOUNT;
        custAccountsToInsert.add(custAcc2);
        insert custAccountsToInsert;
    }
    
    static void setupCaseInputOnStep1(RenewalOppWizardCtrl2lightning controller)
    {
        controller.ctrlCaseWith1stServLine.Deal_Type__c = DEAL_TYPE;
        controller.ctrlCaseWith1stServLine.Non_Standard__c = 'true'; 
        controller.ctrlCaseWith1stServLine.NCSP_Service_line__c = SERVICE_LINE1; 
        controller.ctrlCaseWith1stServLine.NCSP_Upsell_Type__c = UPSELL_TYPE1; 
        controller.ctrlCaseWith2ndServLine.NCSP_Service_line__c = SERVICE_LINE2; 
        controller.ctrlCaseWith2ndServLine.NCSP_Upsell_Type__c = UPSELL_TYPE2; 
        controller.ctrlCaseWith1stServLine.Date_Contract_Signed__c = System.today();
        controller.ctrlCaseWith1stServLine.Date_Paperwork_Received__c = System.today();
        controller.ctrlCaseWith1stServLine.Contract_Effective_Date__c = System.today();
    }
    
    private static RenewalOppWizardCtrl2lightning setupController ( Pagereference currentPage ){
        Test.setCurrentPage( currentPage );
        Apexpages.currentPage().getParameters().put( RenewalOppWizardCtrl2lightning.OPP_ID_PARAM, testOpportunity.Id );
        return new RenewalOppWizardCtrl2lightning();
    }
    static testMethod void testConstructor()
    {
        setupOpportunity();
        test.startTest();
        RenewalOppWizardCtrl2lightning controller =  setupController ( Page.renewalOppWizard2_step1_Lightning);
        test.stopTest();
        
        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals(testOpportunity.Id ,controller.opportunityId ,'Opportunity Id parameter should have properly retrieved from URL ');
        System.assertEquals(testAccount.Id, controller.accountId ,'Opportunity Id parameter should have properly retrieved from URL ');
        System.assertEquals(IMGA ,controller.imga ,'Opportunity Id parameter should have properly retrieved from URL ');
        System.assert( !controller.showSearchResults , 'The show search Result Flag should be defaulted to false');
        System.assert( !controller.showListOfAttachments , 'The show list of attachment Fag should be defaulted to false');
        
    }
    static testMethod void testPrevious()
    {
        final PageReference EXPECTED_PREVIOUS = Page.Renewaloppwizard2_step2_Lightning;
        setupOpportunity();
        RenewalOppWizardCtrl2lightning ctr = setupController( EXPECTED_PREVIOUS );
        Test.startTest();
        ctr.redirectToStep3();
        PageReference actualPrev = ctr.previous();
        Test.stopTest();
        System.assertEquals(EXPECTED_PREVIOUS , actualPrev, 'The user should be redirected to the previous page');
    }

    static testMethod void testStep3createCases()
    {
        setupOpportunity();
        RenewalOppWizardCtrl2lightning controller = setupController( Page.renewalOppWizard2_step1_Lightning );
        setupCaseInputOnStep1(controller);
        Test.startTest();
        PageReference resultPageRef =  controller.redirectToStep2();
        controller.nextForSetCon();
        controller.previousForSetCon();
        controller.last();
        controller.first();
        controller.cancelForSetCon();
        
        controller.createCase();
        Test.stopTest();
        List<IM_Customer_Account__c> existingImgaCustAccounts = [Select Id, Name,IM_Customer_Account_Name__c,IM_Account__c,IM_Account__r.name,IM_Status__c FROM IM_Customer_Account__c where IM_IMGA__c=:IMGA And IM_Status__c = 'Active' Order By Name limit 1000];
        System.assertEquals(existingImgaCustAccounts.size() ,controller.imgaCustomerAccountWrappers.size(),' IMGA Customer Account Section should show all the Active Customer Accounts with matching IMGA ');
       
        List<Apexpages.Message> msgs = ApexPages.getMessages();
		for(Apexpages.Message msg:msgs){
            system.debug('mmmmmm '+msg.getDetail());
        }

        
        System.assert(!Apexpages.hasMessages(), 'There should be no messages');
       // System.assertEquals(Page.renewalOppWizard2_step2.getUrl(), resultPageRef.getUrl());
        
        List<Case> insertedCases=  [Select id,Deal_Type__c,Setup_Type__c,Non_Standard__c,Date_Contract_Signed__c,Date_Paperwork_Received__c,Contract_Effective_Date__c from Case where NCSP_Opportunity__c=:testOpportunity.id and accountId =:testAccount.id];
        System.assertEquals(2, insertedCases.size(), 'Two cases should have been inserted');
        Case case1 = insertedCases[0];
        Case case2 = insertedCases[1];
        System.assertEquals(case1.Deal_Type__c ,case2.Deal_Type__c ,'Case values not properly cloned');
        System.assertEquals(case1.Setup_Type__c ,case2.Setup_Type__c ,'Case values not properly cloned');
        System.assertEquals(case1.Non_Standard__c ,case2.Non_Standard__c ,'Case values not properly cloned');
        System.assertEquals(case1.Date_Contract_Signed__c ,case2.Date_Contract_Signed__c  ,'Case values not properly cloned');
        System.assertEquals(case1.Date_Paperwork_Received__c ,case2.Date_Paperwork_Received__c ,'Case values not properly cloned');
        System.assertEquals(case1.Contract_Effective_Date__c ,case2.Contract_Effective_Date__c ,'Case values not properly cloned');
  }
    static testMethod void testCancel()
    {
        setupOpportunity();
        RenewalOppWizardCtrl2lightning controller = setupController( Page.renewalOppWizard2_step1_Lightning );
        setupCaseInputOnStep1(controller);
        Test.startTest();
        PageReference cancelPageRef = controller.cancel();
        Test.stopTest();
        System.assertEquals('/' + controller.opportunityId , cancelPageRef.getUrl());
    }
    static testMethod void testStep2SearchCaseCustomerAccount()
    {
        setupOpportunity();
        RenewalOppWizardCtrl2lightning controller = setupController( Page.renewalOppWizard2_step1_Lightning );
        setupCaseInputOnStep1(controller);
        
        controller.redirectToStep2();
        Test.startTest();
        controller.searchText = 'Search';
        controller.search();
        Test.stopTest();
        system.assertEquals(1, controller.searchCustomerAccountWrappers.size(), 'Search should have returned matching customer accounts');
    }
    static testMethod void testStep3uploadAttachment()
    {
        setupOpportunity();
        RenewalOppWizardCtrl2lightning controller = setupController( Page.renewalOppWizard2_step1_Lightning );
        controller.attachment.ParentId = controller.opportunityId; // the record the file is attached to
        controller.attachment.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        controller.attachment.description ='Unit Test Attachment Description';
        controller.attachment.body=bodyBlob;
        test.startTest();
        controller.upload();
        test.stopTest();
        System.assert(true,controller.showListOfAttachments);
        List<Attachment> attachments = [Select id from Attachment];
        System.assertEquals(1,attachments.size());
    }
    
     static testMethod void testStep3createCaseWith2ndServiceLineBlank()
    {
        setupOpportunity();
        RenewalOppWizardCtrl2lightning controller = setupController( Page.renewalOppWizard2_step1_Lightning );
        setupCaseInputOnStep1(controller);
        controller.ctrlCaseWith2ndServLine.NCSP_Service_line__c = '';
        controller.ctrlCaseWith2ndServLine.NCSP_Upsell_Type__c = '';
        controller.redirectToStep2();
        controller.imgaCustomerAccountWrappers[0].checked = true;
        test.startTest();
        Pagereference step2PageRef = controller.redirectToStep3();
        controller.createCase();
        Pagereference step3PageRef = controller.redirectToCase();
        test.stopTest();
      //  System.assertEquals(Page.Renewaloppwizard2_step3_Lightning.getUrl(), step2PageRef.getUrl());
        System.assertEquals('/'+controller.casesToBeInserted[0].id, step3PageRef.getUrl());
        System.assertEquals(1,controller.caseCustomerAccountsToBeInserted.size());
        List<Case_Customer_Account__c> insertedCaseCustAccounts = [Select Id from Case_Customer_Account__c];
        System.assertEquals(1,insertedCaseCustAccounts.size());
    }
    static testMethod void testStep3createCaseWith2ndServiceLinePopulated()
    {
        setupOpportunity();
        RenewalOppWizardCtrl2lightning controller = setupController( Page.renewalOppWizard2_step1_Lightning );
        setupCaseInputOnStep1(controller);
        controller.redirectToStep2();
        controller.imgaCustomerAccountWrappers[0].checked = true;
        test.startTest();
        Pagereference step2PageRef = controller.redirectToStep3();
        controller.createCase();
        Pagereference step3PageRef = controller.redirectToCase();
        test.stopTest();
       // System.assertEquals(Page.Renewaloppwizard2_step3_Lightning.getUrl(), step2PageRef.getUrl());
        System.assertEquals('/'+controller.casesToBeInserted[0].id, step3PageRef.getUrl());
        System.assertEquals(2,controller.caseCustomerAccountsToBeInserted.size());
        List<Case_Customer_Account__c> insertedCaseCustAccounts = [Select Id from Case_Customer_Account__c];
        System.assertEquals(2,insertedCaseCustAccounts.size());
    }

}