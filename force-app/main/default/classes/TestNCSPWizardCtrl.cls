@isTest
private class TestNCSPWizardCtrl {


        private static final String  ADDRESS        = '1234 Fake St';
        private static final String  ADDRESS_LINE_2 = 'Apt 9 3/4';
        private static final String  CITY           = 'New York';
        private static final String  COUNTRY        = 'USA';
        private static final Decimal DP_CONTAINER_QUANTITY = 3;
        private static final String  IMAGING_CENTER      = 'Atlanta' ;
        private static final Boolean LITIGATION_DMS      = true ;
        private static final String  NCSP_SERVICE_LINE   = NCSPWizardCtrl.SERVICE_LINE_RM;
        //SERVICE_LINE_ONE_TIME_SHRED
        private static final String  NCSP_SERVICE_LINE1   = NCSPWizardCtrl.SERVICE_LINE_ONE_TIME_SHRED;
        private static final String  NCSP_UPSELL_TYPE    = 'Storage Increase';
        private static final Decimal OTS_BOX_QUANTITY    = 5;
        private static final String  PO_NUMBER           = '8520';
        private static final String  REASON_NO_SUPPLY    = 'NOT NEED IT';
        private static final String  FREE_UP_IN          = 'No';
        private static final Decimal RM_LABEL_QUANTITIES = 7;
        private static final String  RM_LABEL_TYPE       = '1';
        private static final Decimal RM_SUPPLY_BOX_ORDER_QTY          = 9;
        private static final String  RM_SUPPLY_BOX_ORDER_TYPE         = '1.2';
        private static final String  SECOND_SUPPLIES_ORDER_REQUIRED   = 'No';
        private static final String  SECOND_REASON_NO_SUPPLY          = 'Out Dated';
        private static final String  SECOND_NCSP_SERVICE_LINE         = NCSPWizardCtrl.SERVICE_LINE_SHRED;
        private static final String  SECOND_NCSP_UPSELL_TYPE            = 'Paper Destruction';
        private static final Boolean SEPARATE_DMS_INVOICE_NEEDED      = false;
        private static final Decimal SHRED_QUANTITY_65_GALLON_ORDERED = 11;
        private static final Decimal SHRED_QUANTITY_CONSOLES_ORDERED  = 13;
        private static final String  SHRED_SERVICE_FREQUENCY          = 'Weekly';
        private static final String  SHRED_SERVICE_METHOD             = 'On-Site';
        private static final String  SUPPLIES_ORDER_REQUIRED          = 'Yes';
        private static final Boolean SPECIAL_COMMISSION_APPROVAL_INCLUDED = true;
        private static final String  STATE                            = 'NY';
        private static final String  ZIP                              = '10000';
        private static Account testAccount;



    private static Opportunity testOpportunity;

    /*
        @param  Pagereference - CurrentPage
        @return NCSPWizardCtrl
    */
    @testSetup static void SetupMethod() {
        List<NCSP_DBR_Products__c> DBR_Products = new List<NCSP_DBR_Products__c>();
        NCSP_DBR_Products__c pdt;
        pdt = new NCSP_DBR_Products__c();
            pdt.Name = 'DRA Program - Upsell';
            pdt.Case_RecordTypeId__c = '01280000000UI8Z';
            pdt.Opportunity_Type__c = 'Up-Sell/Lift';
            pdt.Product_Name__c ='Data Restoration Assurance Program';
            DBR_Products.add(pdt);
        pdt = new NCSP_DBR_Products__c();
            pdt.Name = 'DRA Program-New Deal';
            pdt.Case_RecordTypeId__c = '01280000000UI8Z';
            pdt.Opportunity_Type__c = 'New Deal';
            pdt.Product_Name__c ='Data Restoration Assurance Program';
            DBR_Products.add(pdt);
        pdt = new NCSP_DBR_Products__c();
            pdt.Name = 'Tape Vaulting-New Deal';
            pdt.Case_RecordTypeId__c = '01280000000UDqr';
            pdt.Opportunity_Type__c = 'New Deal';
            pdt.Product_Name__c ='Tape Vaulting';
            DBR_Products.add(pdt);
        pdt = new NCSP_DBR_Products__c();
            pdt.Name = 'Tape Vaulting-Upsell';
            pdt.Case_RecordTypeId__c = '01280000000UI8U';
            pdt.Opportunity_Type__c = 'Up-Sell/Lift';
            pdt.Product_Name__c ='Tape Vaulting';
            DBR_Products.add(pdt);
        pdt = new NCSP_DBR_Products__c();
            pdt.Name = 'TCManager-New Deal';
            pdt.Case_RecordTypeId__c = '01280000000UI8Z';
            pdt.Opportunity_Type__c = 'New Deal';
            pdt.Product_Name__c ='Tape Catalog Manager';
            DBR_Products.add(pdt);
        pdt = new NCSP_DBR_Products__c();
            pdt.Name = 'TCManager-Upsell';
            pdt.Case_RecordTypeId__c = '01280000000UI8Z';
            pdt.Opportunity_Type__c = 'Up-Sell/Lift';
            pdt.Product_Name__c ='Tape Catalog Manager';
            DBR_Products.add(pdt);
            
        insert DBR_Products;
        List<NCSP_International_Countries__c> ncspCountry = new List<NCSP_International_Countries__c>();
        NCSP_International_Countries__c contr;
            contr = new NCSP_International_Countries__c();
            contr.Name = 'Ireland';
            contr.Case_Owner_ID__c = '00G80000003HVPpEAO';
            contr.Recordtype_ID_18__c = '01280000000UPEAAA4';
            ncspCountry.add(contr);
            contr = new NCSP_International_Countries__c();
            contr.Name = 'United Kingdom';
            contr.Case_Owner_ID__c = '00G80000003HVPpEAO';
            contr.Recordtype_ID_18__c = '01280000000UPEAAA4';
            ncspCountry.add(contr);
            
            insert ncspCountry;
         List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        
        insert opprodsel;
    }
    
    private static NCSPWizardCtrl setupController ( Pagereference currentPage ){
        Test.setCurrentPage( currentPage );
        Apexpages.currentPage().getParameters().put( NCSPWizardCtrl.OPP_ID_PARAM, testOpportunity.Id );
        return new NCSPWizardCtrl();
    }

    private static void setupCustomSettings()
    {
        TestingUtils.setupCountryCustomSettings(true);
        TestingUtils.setupOpportunitySecuritySettings(true);
    }
    private static Account setupAccount(){
        testAccount = new Account();
        testAccount.Name = 'Test Account New';
        testAccount.BillingPostalCode = '11209';
        testAccount.BillingState = 'NY';
        testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';
        testAccount.IM_Sales_Segment__c = NCSPWizardCtrl_Lightning.HEALTHCARE_TYPE;
        insert testAccount;
        return testAccount;
    }
    
    private static Opportunity createOpportunity(){
        String name = 'testOpp';
        Opportunity testOpportunity = new Opportunity( IM_Booked_Date__c=Date.today(), StageName='1 - Qualification', 
                                                      AccountId = testAccount.Id, 
                                                      CloseDate = System.today()
                                                   
                                                      /* #16915 Bundle__c = 'Total Offsite Records Solution'*/);
        testOpportunity.Name = name;        
        insert testOpportunity;       
        return testOpportunity;
    }

    static void setupOpportunity()
    {
        setupCustomSettings();  
        testAccount = setupAccount();
        testOpportunity = createOpportunity();
        /*testAccount = TestingUtils.createCountryParentAccounts(1, true)[0];
        //testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, true);
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        testOpportunity.Bundle__c = 'Total Offsite Records Solution';
        //testOpportunity.Primary_Product_Line__c = 'Other';
        insert testOpportunity;*/
    }

    static testMethod void testConstructor_noProfile()
    {
        setupOpportunity();
        Test.setCurrentPage(Page.NCSPWizard_Step1);
        Apexpages.currentPage().getParameters().put( NCSPWizardCtrl.OPP_ID_PARAM, testOpportunity.Id );

        test.startTest();
            NCSPWizardCtrl controller =  new NCSPWizardCtrl();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals( null , controller.profile.Id , 'There should be a new profile ' );
        System.assert( controller.showMainFrame , 'The main frame should be visible');
    }


    static testMethod void testConstructor_CaseAlreadyCreated()
    {
        setupOpportunity();
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);
        Apexpages.currentPage().getParameters().put( NCSPWizardCtrl.OPP_ID_PARAM, testOpportunity.Id );

        Case caseThatExists = TestingUtils.createCase(testOpportunity, testContact, false);
        caseThatExists.recordTypeId = NCSPWizardCtrl.recordCreatedInWizard[0].Id;
        insert caseThatExists;

        Test.startTest();
            NCSPWizardCtrl controller = new NCSPWizardCtrl();
        Test.stopTest();

        System.assert( Apexpages.hasMessages(Apexpages.Severity.Warning) , 'There should be one error messages');
        System.assert( !controller.showMainFrame , 'The main frame should not be visible');
    }

    static testMethod void testConstructor_noExisingCase()
    {
        setupOpportunity();
        Test.setCurrentPage(Page.NCSPWizard_Step1);
        Apexpages.currentPage().getParameters().put( NCSPWizardCtrl.OPP_ID_PARAM, testOpportunity.Id );

        Test.startTest();
            NCSPWizardCtrl controller = new NCSPWizardCtrl();
        Test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assert( controller.showMainFrame , 'The main frame should be visible');
    }

    static testMethod void testConstructor_oneProfile()
    {
        setupOpportunity();
        Customer_Profile__c testProfile = TestingUtils.createCustomerProfile( testOpportunity.Id, null , true);

        Test.setCurrentPage(Page.NCSPWizard_Step1);
        Apexpages.currentPage().getParameters().put( NCSPWizardCtrl.OPP_ID_PARAM, testOpportunity.Id );

        test.startTest();
            NCSPWizardCtrl controller =  new NCSPWizardCtrl();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals( testProfile.Id , controller.profile.Id , 'It should load the existing profile ' );
        System.assert( controller.showMainFrame , 'The main frame should be visible');
        controller.saveAndGoToConfigOrStepFive();
        controller.configNextPage();
        //controller.saveContactAndGoToStepSeven();
    }


    static testMethod void testConstructor_multipleProfiles()
    {
        setupOpportunity();
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id, null , false);
        Customer_Profile__c testProfile2 = TestingUtils.createCustomerProfile( testOpportunity.Id, null , false);
        insert new List<Customer_Profile__c> {testProfile1, testProfile2 };

        Test.setCurrentPage(Page.NCSPWizard_Step1);
        Apexpages.currentPage().getParameters().put( NCSPWizardCtrl.OPP_ID_PARAM, testOpportunity.Id );

        test.startTest();
            NCSPWizardCtrl controller =  new NCSPWizardCtrl();
        test.stopTest();

        System.assert( Apexpages.hasMessages(Apexpages.Severity.Error) , 'There should be one error messages');
        System.assert( !controller.showMainFrame , 'The main frame should not be visible');

    }


    static testMethod void testConstructor_noOppIdParam()
    {
        Test.setCurrentPage(Page.NCSPWizard_Step1);
        test.startTest();
            NCSPWizardCtrl controller =  new NCSPWizardCtrl();
        test.stopTest();
        System.assert( Apexpages.hasMessages(Apexpages.Severity.Error) , 'There should be one error messages');
        System.assert( !controller.showMainFrame , 'The main frame sbe visiblebe visible');
    }

    static testMethod void testCancel()
    {
        setupOpportunity();
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step1 );

        test.startTest();
            PageReference resultPageRef = controller.cancel();
        test.stopTest();
        System.assert( resultPageRef.getURL().contains( testOpportunity.Id));

    }

    static testMethod void testPrevious()
    {
        final PageReference EXPECTED_PREVIOUS = Page.NCSPWizard_Step1;
        setupOpportunity();
        NCSPWizardCtrl ctr = setupController( EXPECTED_PREVIOUS );
        Test.startTest();
            ctr.stepTwo();
            PageReference actualPrev = ctr.previous();
        Test.stopTest();
        System.assertEquals(EXPECTED_PREVIOUS , actualPrev, 'The user should be redirected to the previous page');
    }

    static testMethod void testGetrelatedAttachments()
    {
        setupOpportunity();
        Attachment testAttachment = TestingUtils.createAttachment('testATtachment', testOpportunity.Id, 'test body', true);
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step1 );

        test.startTest();
            List<Attachment> actualAttachments = controller.attachments;
        test.stopTest();
        System.assertEquals( 1, actualAttachments.size() );
        System.assertEquals( testAttachment.Id, actualAttachments[0].Id);

    }

    static testMethod void testAttachDocuments()
    {
        setupOpportunity();
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step1 );

        test.startTest();
            PageReference resultPageRef = controller.attachDocuments();
        test.stopTest();

        System.assert( resultPageRef.getURL().startsWith('/p/attach/NoteAttach'));
        String pid = resultPageRef.getParameters().get('pid');
        System.assertEquals(testOpportunity.Id, pid);
        String retURL = resultPageRef.getParameters().get('retURL');
        System.assert(retURL.contains(testOpportunity.Id));

    }


    static testMethod void testStepTwo()
    {
        setupOpportunity();
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step1 );

        test.startTest();
            PageReference resultPageRef = controller.stepTwo();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals(Page.NCSPWizard_Step2.getUrl(), resultPageRef.getUrl());
        
    }

    static testMethod void testSaveAndGoToStepThree()
    {
        setupOpportunity();
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step2 );

        // Simulating the user typing the require files
        controller.profile.Same_as_Service_Address__c =  true;
        controller.profile.Same_as_Service_Address_cor__c =  true;

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepThree();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages  ' + Apexpages.getMessages() );
        System.assertEquals(Page.NCSPWizard_Step3.getUrl(), resultPageRef.getUrl());

        Customer_Profile__c actualProfile = [SELECT Id, Opportunity__c FROM Customer_Profile__c LIMIT 1 ];

        System.assertEquals(controller.profile.Id,  actualProfile.Id);
        System.assertEquals(testOpportunity.Id,  actualProfile.Opportunity__c);

    }

    static testMethod void testSaveAndGoToStepThree_BillingAddressNotValid()
    {
        setupOpportunity();
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step2 );

        // Simulating the user typing the require files
        controller.profile.Same_as_Service_Address__c =  true;
        controller.profile.Billing_Address__c =  null;

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepThree();
        test.stopTest();

        System.assert( Apexpages.hasMessages( Apexpages.Severity.Error ) , 'There should be one error messages');
        System.assertEquals(null, resultPageRef );

    }

    static testMethod void testSaveAndGoToStepThree_CorrespondenceAddressNotValid()
    {
        setupOpportunity();
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step2 );

        // Simulating the user typing the require files
        controller.profile.Correspondence_Address__c =  null;
        controller.profile.Same_as_Service_Address_cor__c =  true;

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepThree();
        test.stopTest();

        System.assert( Apexpages.hasMessages( Apexpages.Severity.Error ) , 'There should be one error messages');
        System.assertEquals(null, resultPageRef );

    }

    static testMethod void testSaveAndGoToStepFour_StandardSetup()
    {
        setupOpportunity();
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id, null , true);
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step3 );

        // Simulating the user typing the require files
        controller.profile.Non_Standard_Setup__c =  'No';
        controller.profile.HealthcareAccountStoringPatientRecords__c = 'No';
        controller.profile.Group_Purchasing_Organization_GPO__c = 'No';

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepFour();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals(Page.NCSPWizard_Step6.getUrl(), resultPageRef.getUrl());

        Customer_Profile__c actualProfile = [SELECT Id, Non_Standard_Setup__c FROM Customer_Profile__c LIMIT 1 ];

        System.assertEquals( 'No',  actualProfile.Non_Standard_Setup__c );

    }

    static testMethod void testSaveAndGoToStepFour_NonStandardSetup()
    {
        setupOpportunity();
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id, null , true);
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step3 );

        // Simulating the user typing the require files
        controller.profile.Non_Standard_Setup__c = 'No';
        controller.profile.NCSP_Service_Line__c  = NCSPWizardCtrl.SERVICE_LINE_RM;
        //controller.profile.NCSP_Service_Line__c  = 'DB&R';
        controller.profile.Free_Up_In__c  = 'No';
        controller.profile.HealthcareAccountStoringPatientRecords__c = 'No';
        controller.profile.Group_Purchasing_Organization_GPO__c = 'No';

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepFour();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals(Page.NCSPWizard_Step4.getUrl(), resultPageRef.getUrl());

        Customer_Profile__c actualProfile = [SELECT Id, Non_Standard_Setup__c FROM Customer_Profile__c LIMIT 1 ];

        System.assertEquals( 'No',  actualProfile.Non_Standard_Setup__c );
    }

    static testMethod void testSaveAndGoToStepFour_HealthcareSetup()
    {
        setupCustomSettings();
        //testAccount = TestingUtils.createCountryParentAccounts(1, false)[0];
        testAccount = setupAccount();
        testOpportunity = createOpportunity();
        //testAccount.IM_Sales_Segment__c = NCSPWizardCtrl.HEALTHCARE_TYPE;
        //insert testAccount;
        //testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, true);
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id, null , true);
        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step3 );

        // Simulating the user typing the require files
        controller.profile.Non_Standard_Setup__c = 'Yes';
        controller.profile.HealthcareAccountStoringPatientRecords__c = 'Yes';
        controller.profile.NCSP_Service_Line__c  = NCSPWizardCtrl.SERVICE_LINE_RM;
        controller.profile.Free_Up_In__c  = 'No';
        controller.profile.Group_Purchasing_Organization_GPO__c = 'No';

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepFour();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals(Page.NCSPWizard_HealthCare.getUrl(), resultPageRef.getUrl());

        Customer_Profile__c actualProfile = [SELECT Id, Non_Standard_Setup__c, HealthcareAccountStoringPatientRecords__c FROM Customer_Profile__c LIMIT 1 ];

        System.assertEquals( 'Yes',  actualProfile.HealthcareAccountStoringPatientRecords__c );
    }

    static testMethod void testSaveAndGoToStepFive()
    {
        final String DIVISION_ENABLED_YES = 'Yes';

        setupOpportunity();

        // We are setting up the data in such a way it will go to step 5
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{'Non_Standard_Setup__c'=>'Yes', 'Division_Enabled__c' => null,
                'NCSP_Service_Line__c' => NCSPWizardCtrl.SERVICE_LINE_RM , 'Free_Up_In__c' => 'No', 'HealthcareAccountStoringPatientRecords__c' => 'No',
                'Non_Standard_Setup__c' => 'No', 'Group_Purchasing_Organization_GPO__c' => 'No','NCSP_Upsell_Type__c' => 'test',
                'Supplies_Order_Required__c' => NCSPWizardCtrl.YES} , true);

        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step4 );

        // Simulating typing some values in step 4
        controller.profile.Division_Enabled__c = DIVISION_ENABLED_YES ;

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepFive();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals(Page.NCSPWizard_Step5.getUrl(), resultPageRef.getUrl());

        Customer_Profile__c actualProfile = [SELECT Id, Division_Enabled__c FROM Customer_Profile__c LIMIT 1 ];

        System.assertEquals( DIVISION_ENABLED_YES,  actualProfile.Division_Enabled__c );

    }

    static testMethod void testSaveAndGoToStepSix()
    {

        setupOpportunity();

        // We are setting up the data in such a way it will go to step 5
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{'Non_Standard_Setup__c'=>'No', 'HealthcareAccountStoringPatientRecords__c' => 'No',
                'Non_Standard_Setup__c' => 'No', 'Group_Purchasing_Organization_GPO__c' => 'No','RM_Supply_Box_Order_Type__c' => null,
                'NCSP_Service_Line__c' => NCSPWizardCtrl.SERVICE_LINE_RM , 'NCSP_Upsell_Type__c' => 'test'} , true);

        NCSPWizardCtrl controller = setupController( Page.NCSPWizard_Step5 );

        // Simulating typing some values in step 5
        controller.profile.RM_Supply_Box_Order_Type__c = RM_SUPPLY_BOX_ORDER_TYPE ;

        test.startTest();
            PageReference resultPageRef = controller.saveAndGoToStepSix();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        System.assertEquals(Page.NCSPWizard_Step6.getUrl(), resultPageRef.getUrl());

        Customer_Profile__c actualProfile = [SELECT Id, RM_Supply_Box_Order_Type__c FROM Customer_Profile__c LIMIT 1 ];

        System.assertEquals( RM_SUPPLY_BOX_ORDER_TYPE,  actualProfile.RM_Supply_Box_Order_Type__c );

    }

    static testMethod void testSaveAndGoToStepSix_b(){
        setupOpportunity();
        testOpportunity.Type = NCSPWizardCtrl.NEW_DEAL;
        //update testOpportunity;

        Contact testContact = TestingUtils.createContact(testAccount.Id, false);
        testContact.Phone = '415-555-3801';
        //insert testContact;

        // We are setting up the data in such a way it will go to step 6
        Test.startTest();
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{'Non_Standard_Setup__c'=>'No', 'RM_Supply_Box_Order_Type__c' => null,
                'NCSP_Service_Line__c' => NCSPWizardCtrl.SERVICE_LINE_RM , 'NCSP_Upsell_Type__c' => 'test'} , true);

        NCSPWizardCtrl controller =  setupController( Page.NCSPWizard_Step6 );
            Pagereference resultPageRef1 = controller.saveAndGoToStepSix_b();
            controller.profile.Primary_Service_Contact__c = testContact.Id;
            Pagereference resultPageRef = controller.saveAndGoToStepSix_b();
        Test.stopTest();

        //System.assert( !Apexpages.hasMessages() , 'There should be no messages');
        //System.assertEquals(Page.NCSPWizard_Step6b.getUrl(), resultPageRef.getUrl());
        List<SelectOption> pdtOption = controller.DBRProductOptions;
    }

    static testMethod void testCreateCase_OnlyOneServiceLine()
    {
        setupOpportunity();
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);

        // We are setting up the data in such a way we are at step 8
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{ 'Same_as_Service_Address__c' =>  true,'Same_as_Service_Address_cor__c' =>  true,
                'Address__c' => ADDRESS ,
                'Address_Line_2__c' => ADDRESS_LINE_2,
                'City__c' => CITY,
                'Country__c' => COUNTRY,
                'DB_R_Container_Quantity__c' => DP_CONTAINER_QUANTITY,
                'Imaging_Center__c' => IMAGING_CENTER,
                'NCSP_Service_Line__c' => NCSP_SERVICE_LINE1,
                'NCSP_Upsell_Type__c' => NCSP_UPSELL_TYPE,
                'PO_Number__c' => PO_NUMBER,
                // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
               /* 'Reason_No_Supply__c' => REASON_NO_SUPPLY,*/
                'Free_Up_In__c' => FREE_UP_IN,
                'HealthcareAccountStoringPatientRecords__c' => 'No',
                'Non_Standard_Setup__c' => 'No',
                'Group_Purchasing_Organization_GPO__c' => 'No',
                'RM_Label_Quantities__c' => RM_LABEL_QUANTITIES,
                'RM_Label_Type__c' => RM_LABEL_TYPE,
                'RM_Supply_Box_Order_Qty__c' => RM_SUPPLY_BOX_ORDER_QTY,
                'RM_Supply_Box_Order_Type__c' => RM_SUPPLY_BOX_ORDER_TYPE,
                'Supplies_Order_Required__c' => SUPPLIES_ORDER_REQUIRED,
                'State_Province__c' => STATE,
                'Zip_Postal_Code__c' => ZIP}
                , true);

        NCSPWizardCtrl controller =  setupController( Page.NCSPWizard_Step8 );
        controller.selectedContact = testContact;

        test.startTest();
            PageReference resultPageRef = controller.createCase();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages [ '+ + Apexpages.getMessages() +' ]');

        Customer_Profile__c actualProfile = [ SELECT Case_Created__c FROM Customer_Profile__c WHERE Id = :testProfile1.Id  ];

        Case actualCase = [SELECT Id, AccountId, Address__c, Address_Line_2__c,
                                   City__c, Country__c, DP_Container_Quantity__c,
                                   DMS_Type__c, Imaging_Center__c,
                                   NCSP_Service_Line__c, NCSP_Upsell_Type__c,
                                   NCSP_Opportunity__c, OTS_Box_Quantity__c,
                                   PO_Number__c, ContactId, RM_Label_Quantities__c,
                                   RM_Label_Type__c, RM_Supply_Box_Order_Qty__c,
                                   RM_Supply_Box_Order_Type__c, Shred_Quantity_65_Gallon_Ordered__c,
                                   Shred_Quantity_Consoles_Ordered__c, Shred_Service_Frequency__c,Shred_Service_Method__c,
                                   State__c, Zip__c,OwnerId,Date_Paperwork_Received__c,Setup_Type__c,
                                   // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
                                   Status,Customer_Profile__c,Supplies_Order_Required__c,/*Reason_No_Supply__c,*/ Free_Up_In__c
                           FROM Case ];

        /*System.assert( actualProfile.Case_Created__c , 'The "Case_Created__c" should be set to true');

        System.assertEquals( testAccount.Id , actualCase.AccountId );
        System.assertEquals( ADDRESS , actualCase.Address__c );
        System.assertEquals( ADDRESS_LINE_2 , actualCase.Address_Line_2__c );
        System.assertEquals( CITY , actualCase.City__c );
        System.assertEquals( testContact.Id , actualCase.ContactId );
        System.assertEquals( COUNTRY , actualCase.Country__c );
        System.assertEquals( testProfile1.Id , actualCase.Customer_Profile__c );
        System.assertNotEquals( NULL , actualCase.Date_Paperwork_Received__c );
        System.assertEquals( IMAGING_CENTER , actualCase.Imaging_Center__c );
        System.assertEquals( NCSP_SERVICE_LINE1 , actualCase.NCSP_Service_Line__c );
        System.assertEquals( NCSP_UPSELL_TYPE , actualCase.NCSP_Upsell_Type__c );
        System.assertEquals( testOpportunity.Id , actualCase.NCSP_Opportunity__c );
        System.assertEquals( controller.standardCaseQueueIdnew , actualCase.OwnerId );
        System.assertEquals( REASON_NO_SUPPLY , actualCase.Reason_No_Supply__c );
        System.assertEquals( RM_LABEL_QUANTITIES , actualCase.RM_Label_Quantities__c );
        System.assertEquals( RM_LABEL_TYPE , actualCase.RM_Label_Type__c );
        System.assertEquals( RM_SUPPLY_BOX_ORDER_QTY , actualCase.RM_Supply_Box_Order_Qty__c );
        System.assertEquals( RM_SUPPLY_BOX_ORDER_TYPE , actualCase.RM_Supply_Box_Order_Type__c );
        System.assertEquals( NCSPWizardCtrl.STANDARD_SETUP_TYPE , actualCase.Setup_Type__c );
        System.assertEquals( SUPPLIES_ORDER_REQUIRED , actualCase.Supplies_Order_Required__c );
        System.assertEquals( STATE , actualCase.State__c );
        System.assertEquals( NCSPWizardCtrl.STATUS_NEW , actualCase.Status );
        System.assertEquals( ZIP , actualCase.Zip__c );
        System.assertEquals( FREE_UP_IN , actualCase.Free_Up_In__c );*/
    }
    static testMethod void testCreateCase_OnlyOneServiceLine1()
    {
        setupOpportunity();
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);

        // We are setting up the data in such a way we are at step 8
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{ 'Same_as_Service_Address__c' =>  true,'Same_as_Service_Address_cor__c' =>  true,
                'Address__c' => ADDRESS ,
                'Address_Line_2__c' => ADDRESS_LINE_2,
                'City__c' => CITY,
                'Country__c' => COUNTRY,
                'DB_R_Container_Quantity__c' => DP_CONTAINER_QUANTITY,
                'Imaging_Center__c' => IMAGING_CENTER,
                'NCSP_Service_Line__c' => 'DB&R',
                'NCSP_Upsell_Type__c' => NCSP_UPSELL_TYPE,
                'PO_Number__c' => PO_NUMBER,
                // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
               /* 'Reason_No_Supply__c' => REASON_NO_SUPPLY,*/
                'Free_Up_In__c' => FREE_UP_IN,
                'HealthcareAccountStoringPatientRecords__c' => 'No',
                'Non_Standard_Setup__c' => 'No',
                'Group_Purchasing_Organization_GPO__c' => 'No',
                'RM_Label_Quantities__c' => RM_LABEL_QUANTITIES,
                'RM_Label_Type__c' => RM_LABEL_TYPE,
                'RM_Supply_Box_Order_Qty__c' => RM_SUPPLY_BOX_ORDER_QTY,
                'RM_Supply_Box_Order_Type__c' => RM_SUPPLY_BOX_ORDER_TYPE,
                'Supplies_Order_Required__c' => SUPPLIES_ORDER_REQUIRED,
                'State_Province__c' => STATE,
                'Zip_Postal_Code__c' => ZIP}
                , true);

        NCSPWizardCtrl controller =  setupController( Page.NCSPWizard_Step8 );
        controller.selectedContact = testContact;
        controller.selectedDBRProducts = new List<String>();
        controller.selectedDBRProducts.add('DRA Program-New Deal');
        controller.selectedDBRProducts.add('Tape Vaulting-New Deal');
        
        
        test.startTest();
            PageReference resultPageRef = controller.createCase();
        test.stopTest();
        /*// We are setting up the data in such a way we are at step 8
        Customer_Profile__c testProfile2 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{ 'Same_as_Service_Address__c' =>  true,'Same_as_Service_Address_cor__c' =>  true,
                'Address__c' => ADDRESS ,
                'Address_Line_2__c' => ADDRESS_LINE_2,
                'City__c' => CITY,
                'Country__c' => COUNTRY,
                'DB_R_Container_Quantity__c' => DP_CONTAINER_QUANTITY,
                'Imaging_Center__c' => IMAGING_CENTER,
                'NCSP_Service_Line__c' => 'Data Breach',
                'NCSP_Upsell_Type__c' => NCSP_UPSELL_TYPE,
                'PO_Number__c' => PO_NUMBER,
                'Reason_No_Supply__c' => REASON_NO_SUPPLY,
                'Free_Up_In__c' => FREE_UP_IN,
                'HealthcareAccountStoringPatientRecords__c' => 'No',
                'Non_Standard_Setup__c' => 'No',
                'Group_Purchasing_Organization_GPO__c' => 'No',
                'RM_Label_Quantities__c' => RM_LABEL_QUANTITIES,
                'RM_Label_Type__c' => RM_LABEL_TYPE,
                'RM_Supply_Box_Order_Qty__c' => RM_SUPPLY_BOX_ORDER_QTY,
                'RM_Supply_Box_Order_Type__c' => RM_SUPPLY_BOX_ORDER_TYPE,
                'Supplies_Order_Required__c' => SUPPLIES_ORDER_REQUIRED,
                'State_Province__c' => STATE,
                'Zip_Postal_Code__c' => ZIP}
                , true);
        NCSPWizardCtrl controller1 =  setupController( Page.NCSPWizard_Step8 );
        controller1.selectedContact = testContact;

        controller1.selectedDBRProducts = new List<String>();
        controller1.selectedDBRProducts.add('DRA Program-New Deal');
        controller1.selectedDBRProducts.add('Tape Vaulting-New Deal');
            PageReference resultPageRef1 = controller1.createCase();*/
    }

    static testMethod void testCreateCase_OnlyOneServiceLine_rush()
    {
        setupOpportunity();
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);

        // We are setting up the data in such a way we are at step 8
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{ 'Same_as_Service_Address__c' =>  true,'Same_as_Service_Address_cor__c' =>  true,
                'Address__c' => ADDRESS ,
                'Address_Line_2__c' => ADDRESS_LINE_2,
                'City__c' => CITY,
                'Country__c' => COUNTRY,
                'Deal_Type__c' => 'New Deal',
                'NCSP_Service_Line__c' => 'DMS',
                'Supplies_Order_Required__c' => SUPPLIES_ORDER_REQUIRED,
                'DMS_Type__c' => 'Conversion Services',
                'Billing_Division__c' => 'Test Billing Division',
                'Billing_Department__c' => 'Test Billing Department',
                'Imaging_Center__c' => IMAGING_CENTER,
                'Litigation_DMS__c' => LITIGATION_DMS,
                'DMS_Label_Quantities__c' => RM_LABEL_QUANTITIES,
                'DMS_Label_Type__c' => 'T Labels',
                'DMS_Supply_Box_Order_Qty__c' => RM_SUPPLY_BOX_ORDER_QTY,
                'DMS_Supply_Box_Order_Type__c' => RM_SUPPLY_BOX_ORDER_TYPE,
                'PO_Number__c' => PO_NUMBER,
                'State_Province__c' => STATE,
                'Zip_Postal_Code__c' => ZIP}
                , true);

        NCSPWizardCtrl controller =  setupController( Page.NCSPWizard_Step8 );
        controller.selectedContact = testContact;

        test.startTest();
            PageReference resultPageRef = controller.createCase();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages [ '+ + Apexpages.getMessages() +' ]');

        Customer_Profile__c actualProfile = [ SELECT Case_Created__c FROM Customer_Profile__c WHERE Id = :testProfile1.Id  ];

        List<Case> actualCases = [SELECT Id, Rush__c, Rush_Comments__c FROM Case ];
        System.assertEquals( 1, actualCases.size() , 'There should be 1 case created');

        System.assert( actualProfile.Case_Created__c , 'The "Case_Created__c" should be set to true');
        System.assertEquals( true, actualCases[0].Rush__c , 'The "Rush__c" should be set to true');
        System.assertEquals( NCSPWizardCtrl.DMS_LITIGATION_RUSH_COMMENT, actualCases[0].Rush_Comments__c , 'The "Rush_Comments__c" should be set to DMS Litigation');

    }

    static testMethod void testCreateCase_TwoServiceLines()
    {

        setupOpportunity();
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);

        // We are setting up the data in such a way we are at step 8
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{ 'Same_as_Service_Address__c' =>  true,'Same_as_Service_Address_cor__c' =>  true,
                'Address__c' => ADDRESS ,
                'Address_Line_2__c' => ADDRESS_LINE_2,
                'City__c' => CITY,
                'Country__c' => COUNTRY,
                'DB_R_Container_Quantity__c' => DP_CONTAINER_QUANTITY,
                'Imaging_Center__c' => IMAGING_CENTER,
                'NCSP_Service_Line__c' => NCSP_SERVICE_LINE,
                'NCSP_Upsell_Type__c'  => NCSP_UPSELL_TYPE,
                'OTS_Box_Quantity__c' => OTS_BOX_QUANTITY,
                'PO_Number__c' => PO_NUMBER,
                // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
               /* 'Reason_No_Supply__c' => REASON_NO_SUPPLY,*/
                'RM_Label_Quantities__c' => RM_LABEL_QUANTITIES,
                'RM_Label_Type__c' => RM_LABEL_TYPE,
                'RM_Supply_Box_Order_Qty__c' => RM_SUPPLY_BOX_ORDER_QTY,
                'RM_Supply_Box_Order_Type__c' => RM_SUPPLY_BOX_ORDER_TYPE,
                'Free_Up_In__c' => FREE_UP_IN,
                'HealthcareAccountStoringPatientRecords__c' => 'No',
                'Non_Standard_Setup__c' => 'No',
                'Group_Purchasing_Organization_GPO__c' => 'No',
                'Second_NCSP_Upsell_Type__c' => SECOND_NCSP_UPSELL_TYPE,
                'Second_Service_Line__c'     => SECOND_NCSP_SERVICE_LINE,
                'Second_Reason_No_Supply__c' => SECOND_REASON_NO_SUPPLY,
                'Second_Supplies_Order_Required__c' => SECOND_SUPPLIES_ORDER_REQUIRED,
                'Shred_Quantity_65_Gallon_Ordered__c' => SHRED_QUANTITY_65_GALLON_ORDERED,
                'Shred_Quantity_Consoles_Ordered__c' => SHRED_QUANTITY_CONSOLES_ORDERED,
                'Shred_Service_Frequency__c' => SHRED_SERVICE_FREQUENCY,
                'Shred_Service_Method__c' => SHRED_SERVICE_METHOD,
                'Supplies_Order_Required__c' => SUPPLIES_ORDER_REQUIRED,
                'State_Province__c' => STATE,
                'Zip_Postal_Code__c' => ZIP}
                , true);

        NCSPWizardCtrl controller =  setupController( Page.NCSPWizard_Step8 );
        controller.selectedContact = testContact;

        test.startTest();
            PageReference resultPageRef = controller.createCase();
        test.stopTest();
       
    //    System.assert( !Apexpages.hasMessages() , 'There should be no messages [ '+ + Apexpages.getMessages() +' ]');
        
        List<Case> actualCases = [SELECT Id, AccountId ,Address__c, Address_Line_2__c,
                                   City__c, Country__c, DP_Container_Quantity__c,
                                   DMS_Type__c, Imaging_Center__c,
                                   NCSP_Service_Line__c, NCSP_Upsell_Type__c,
                                   NCSP_Opportunity__c, OTS_Box_Quantity__c,
                                   PO_Number__c, ContactId, RM_Label_Quantities__c,
                                   RM_Label_Type__c, RM_Supply_Box_Order_Qty__c,
                                   RM_Supply_Box_Order_Type__c,
                                   Shred_Quantity_65_Gallon_Ordered__c,Shred_Quantity_Consoles_Ordered__c,
                                   Shred_Service_Frequency__c,Shred_Service_Method__c,
                                   State__c, Zip__c,OwnerId,Date_Paperwork_Received__c,Setup_Type__c,
                                  // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
                                   Status,Customer_Profile__c,Supplies_Order_Required__c,/*Reason_No_Supply__c,*/ Free_Up_In__c
                           FROM Case ];

 /*       System.assertEquals( 2, actualCases.size(), 'Two cases should have been created, one for each service line'  );

        for ( Case aCase : actualCases  )
        {

            System.assertEquals( testAccount.Id , aCase.AccountId );
            System.assertEquals( ADDRESS , aCase.Address__c );
            System.assertEquals( ADDRESS_LINE_2 , aCase.Address_Line_2__c );
            System.assertEquals( CITY , aCase.City__c );
            System.assertEquals( testContact.Id , aCase.ContactId );
            System.assertEquals( COUNTRY , aCase.Country__c );
            System.assertEquals( testProfile1.Id , aCase.Customer_Profile__c );
            System.assertNotEquals( NULL , aCase.Date_Paperwork_Received__c );
            System.assertEquals( testOpportunity.Id , aCase.NCSP_Opportunity__c );
            System.assertEquals( controller.standardCaseQueueIdnew , aCase.OwnerId );
            System.assertEquals( NCSPWizardCtrl.STANDARD_SETUP_TYPE , aCase.Setup_Type__c );
            System.assertEquals( STATE , aCase.State__c );
            System.assertEquals( NCSPWizardCtrl.STATUS_NEW , aCase.Status );
            System.assertEquals( ZIP , aCase.Zip__c );

            if ( NCSP_SERVICE_LINE == aCase.NCSP_Service_Line__c )
            {
                System.assertEquals( NCSP_SERVICE_LINE , aCase.NCSP_Service_Line__c );
                System.assertEquals( NCSP_UPSELL_TYPE , aCase.NCSP_Upsell_Type__c );
                System.assertEquals( REASON_NO_SUPPLY , aCase.Reason_No_Supply__c );
                System.assertEquals( RM_LABEL_QUANTITIES , aCase.RM_Label_Quantities__c );
                System.assertEquals( RM_LABEL_TYPE , aCase.RM_Label_Type__c );
                System.assertEquals( RM_SUPPLY_BOX_ORDER_QTY , aCase.RM_Supply_Box_Order_Qty__c );
                System.assertEquals( RM_SUPPLY_BOX_ORDER_TYPE , aCase.RM_Supply_Box_Order_Type__c );
                System.assertEquals( SUPPLIES_ORDER_REQUIRED , aCase.Supplies_Order_Required__c );
                System.assertEquals( FREE_UP_IN , aCase.Free_Up_In__c );
            }
            else if ( SECOND_NCSP_SERVICE_LINE == aCase.NCSP_Service_Line__c )
            {
                System.assertEquals( SECOND_NCSP_SERVICE_LINE , aCase.NCSP_Service_Line__c );
                System.assertEquals( SECOND_NCSP_UPSELL_TYPE , aCase.NCSP_Upsell_Type__c );
                System.assertEquals( SECOND_REASON_NO_SUPPLY , aCase.Reason_No_Supply__c );
                System.assertEquals( SECOND_SUPPLIES_ORDER_REQUIRED , aCase.Supplies_Order_Required__c );
                System.assertEquals( SHRED_QUANTITY_65_GALLON_ORDERED , aCase.Shred_Quantity_65_Gallon_Ordered__c );
                System.assertEquals( SHRED_QUANTITY_CONSOLES_ORDERED , aCase.Shred_Quantity_Consoles_Ordered__c );
                System.assertEquals( SHRED_SERVICE_FREQUENCY , aCase.Shred_Service_Frequency__c );
                System.assertEquals( SHRED_SERVICE_METHOD , aCase.Shred_Service_Method__c );
            }

        } */
    }


    static testMethod void testCreateCase_Heathcare()
    {
        setupCustomSettings();
        //testAccount = TestingUtils.createCountryParentAccounts(1, false)[0];
        testAccount = setupAccount();
        testOpportunity = createOpportunity();
        //testAccount.IM_Sales_Segment__c = NCSPWizardCtrl.HEALTHCARE_TYPE;
        //insert testAccount;
        //testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, true);
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);

        // We are setting up the data in such a way we are at step 8 and the healthcare option was selected
        Customer_Profile__c testProfile1 = TestingUtils.createCustomerProfile( testOpportunity.Id,
            new Map<String,Object>{ 'Same_as_Service_Address__c' =>  true,'Same_as_Service_Address_cor__c' =>  true,
                'Address__c' => ADDRESS ,
                'Address_Line_2__c' => ADDRESS_LINE_2,
                'City__c' => CITY,
                'Country__c' => COUNTRY,
                'DB_R_Container_Quantity__c' => DP_CONTAINER_QUANTITY,
                'Imaging_Center__c' => IMAGING_CENTER,
                'NCSP_Service_Line__c' => NCSP_SERVICE_LINE,
                'NCSP_Upsell_Type__c' => NCSP_UPSELL_TYPE,
                'PO_Number__c' => PO_NUMBER,
                // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
                /*'Reason_No_Supply__c' => REASON_NO_SUPPLY,*/
                'Free_Up_In__c' => FREE_UP_IN,
                'RM_Label_Quantities__c' => RM_LABEL_QUANTITIES,
                'RM_Label_Type__c' => RM_LABEL_TYPE,
                'RM_Supply_Box_Order_Qty__c' => RM_SUPPLY_BOX_ORDER_QTY,
                'RM_Supply_Box_Order_Type__c' => RM_SUPPLY_BOX_ORDER_TYPE,
                'Supplies_Order_Required__c' => SUPPLIES_ORDER_REQUIRED,
                'State_Province__c' => STATE,
                'Zip_Postal_Code__c' => ZIP,
                'HealthcareAccountStoringPatientRecords__c' => 'Yes',
                'Non_Standard_Setup__c' => 'No',
                'Group_Purchasing_Organization_GPO__c' => 'No',
                'How_will_the_customer_store_records__c' => 'Carton' }
                , true);

        NCSPWizardCtrl controller =  setupController( Page.NCSPWizard_Step8 );
        controller.selectedContact = testContact;
   
        test.startTest();
            PageReference resultPageRef = controller.createCase();
        test.stopTest();

        System.assert( !Apexpages.hasMessages() , 'There should be no messages [ '+ + Apexpages.getMessages() +' ]');

        Customer_Profile__c actualProfile = [ SELECT Case_Created__c FROM Customer_Profile__c WHERE Id = :testProfile1.Id  ];

        Case actualCase = [SELECT Id, AccountId, Address__c, Address_Line_2__c,
                                   City__c, Country__c, DP_Container_Quantity__c,
                                   DMS_Type__c, Imaging_Center__c,
                                   NCSP_Service_Line__c, NCSP_Upsell_Type__c,
                                   NCSP_Opportunity__c, OTS_Box_Quantity__c,
                                   PO_Number__c, ContactId, RM_Label_Quantities__c,
                                   RM_Label_Type__c, RM_Supply_Box_Order_Qty__c,
                                   RM_Supply_Box_Order_Type__c, Shred_Quantity_65_Gallon_Ordered__c,
                                   Shred_Quantity_Consoles_Ordered__c, Shred_Service_Frequency__c,Shred_Service_Method__c,
                                   State__c, Zip__c,OwnerId,Date_Paperwork_Received__c,Setup_Type__c,
                                   // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
                                   Status,Customer_Profile__c,Supplies_Order_Required__c,/*Reason_No_Supply__c,*/ Free_Up_In__c
                           FROM Case ];

        System.assert( actualProfile.Case_Created__c , 'The "Case_Created__c" should be set to true');

        System.assertEquals( testAccount.Id , actualCase.AccountId );
        System.assertEquals( ADDRESS , actualCase.Address__c );
        System.assertEquals( ADDRESS_LINE_2 , actualCase.Address_Line_2__c );
        System.assertEquals( CITY , actualCase.City__c );
        System.assertEquals( testContact.Id , actualCase.ContactId );
        System.assertEquals( COUNTRY , actualCase.Country__c );
        System.assertEquals( testProfile1.Id , actualCase.Customer_Profile__c );
        System.assertNotEquals( NULL , actualCase.Date_Paperwork_Received__c );
        System.assertEquals( IMAGING_CENTER , actualCase.Imaging_Center__c );
        System.assertEquals( NCSP_SERVICE_LINE , actualCase.NCSP_Service_Line__c );
        System.assertEquals( NCSP_UPSELL_TYPE , actualCase.NCSP_Upsell_Type__c );
        System.assertEquals( testOpportunity.Id , actualCase.NCSP_Opportunity__c );
        System.assertEquals( controller.standardCaseQueueIdnew , actualCase.OwnerId );
        // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/14/2022
       /* System.assertEquals( REASON_NO_SUPPLY , actualCase.Reason_No_Supply__c );*/
        System.assertEquals( RM_LABEL_QUANTITIES , actualCase.RM_Label_Quantities__c );
        System.assertEquals( RM_LABEL_TYPE , actualCase.RM_Label_Type__c );
        System.assertEquals( RM_SUPPLY_BOX_ORDER_QTY , actualCase.RM_Supply_Box_Order_Qty__c );
        System.assertEquals( RM_SUPPLY_BOX_ORDER_TYPE , actualCase.RM_Supply_Box_Order_Type__c );
        System.assertEquals( NCSPWizardCtrl.HEALTHCARE_ACCOUNT_TYPE , actualCase.Setup_Type__c );
        System.assertEquals( SUPPLIES_ORDER_REQUIRED , actualCase.Supplies_Order_Required__c );
        System.assertEquals( STATE , actualCase.State__c );
        System.assertEquals( NCSPWizardCtrl.STATUS_NEW , actualCase.Status );
        System.assertEquals( ZIP , actualCase.Zip__c );
        System.assertEquals( FREE_UP_IN , actualCase.Free_Up_In__c );

    }
    static testMethod void testCoverage()
    {
        setupOpportunity();
        NCSPWizardCtrl wiz = new NCSPWizardCtrl();
        wiz.contactSearchTerm = 'test';
        List<Contact> conList = new List<Contact>();
        conList = wiz.contacts;
        boolean check = wiz.isHealthcareAccountStoringPatientRecords;
        contact co = wiz.selectedContact;
        contact coo = wiz.BillingContact;
        Id owneIds  = wiz.internationalCaseOwnerID;
        boolean b = wiz.isHealthcare;
        
        Group test2 = new Group();
        test2.Name = 'NCSP FIFO (First in First out)';
        insert test2;
        Id grpId = wiz.standardCaseQueueId;
        
        Group test1 = new Group();
        test1.Name = 'Recall Onboarding Test(FIFO)';
        insert test1;
       //  Id grpId1 = wiz.RecallCaseQueueId; 
        
        List<SelectOption> supplyBox = wiz.rmSupplyBoxOrderTypeOptions;
        List<SelectOption> labelTyp = wiz.rmLabelTypeOptions;
        
        List<String> test3 = wiz.selectedDBRProducts;
        
        List<SelectOption> pdtOption = wiz.splitTypeOptions;
        //Customer_Profile__c testProfile = TestingUtils.createCustomerProfile( testOpportunity.Id, null , true);
        //wiz.saveAndGoToConfigOrStepFive();
        //wiz.configNextPage();
        //setupOpportunity();*/
        Customer_Profile__c testProfile = TestingUtils.createCustomerProfile( testOpportunity.Id, null , true);

        Test.setCurrentPage(Page.NCSPWizard_Step1);
        Apexpages.currentPage().getParameters().put( NCSPWizardCtrl.OPP_ID_PARAM, testOpportunity.Id );
        test.startTest();
        NCSPWizardCtrl wiz1 = new NCSPWizardCtrl();
        wiz1.profile.Deal_Type__c = 'Upsell';
        boolean  editable = wiz1.hasEditableDealTypeOnOverview;
        wiz1.profile.NCSP_Upsell_Type__c = 'Paper Destruction';
        wiz1.profile.NCSP_Service_Line__c = 'One Time Shred';
        wiz1.profile.Second_NCSP_Upsell_Type__c = 'Paper Destruction';
        wiz1.profile.Second_Service_Line__c = 'One Time Shred';
        boolean  Qun = wiz1.isOTSBoxQuantityDisabled;
        wiz1.profile.NCSP_Upsell_Type__c = 'Supply Increase';
        boolean  frD = wiz1.isShredServiceFrequencyDisabled;
        
        testOpportunity.Type = 'New Deal';
        update testOpportunity;
        wiz1.profile.NCSP_Service_Line__c = 'DB&R';
        wiz1.profile.Supplies_Order_Required__c = 'No';
        wiz1.profile.NCSP_Upsell_Type__c = 'Service Frequency';
        wiz1.profile.Second_Service_Line__c = 'DB&R';
        boolean  tDis = wiz1.isContainerTypeDisabled;
        boolean QDis = wiz1.isContainerQuantityDisabled;
        wiz1.profile.NCSP_Upsell_Type__c = 'Supply Increase';
        boolean sfDis = wiz1.isServiceFrequencyDisabled;
        boolean  pSDis = wiz1.isPreferredServiceDaysDisabled;
        boolean  bQu = wiz1.isBoxQuantityDisabled;
        boolean  bQR = wiz1.isBoxQuantityRequired;
        boolean  bQD = wiz1.isTapeQuantityDisabled;
        boolean  bQrr = wiz1.isTapeQuantityRequired;
        boolean  aNDd = wiz1.isAuthorizationNumberDisabled;
        boolean  qCD = wiz1.isQuantityConsolesDisabled;
        boolean  sD = wiz1.isShredServiceDisabled;
        boolean  sDi = wiz1.isShredQuantityConsolesOrderedEnable;
        boolean  qdiss = wiz1.isShredQuantity65GallonOrderedEnable;
        boolean  otBQ = wiz1.isOTSBoxQuantityEnable;
        boolean  qCO = wiz1.isOTSQuantityConsolesOrderedEnable;
        boolean  qunGa = wiz1.isOTSQuantity65GallonOrdered;
        boolean  qdidd = wiz1.isQuantity65GallonDisabled;
        boolean  cbl = wiz1.isCloudBlue;
        boolean  cbl1 = wiz1.isDBnRSO;
        boolean  cbl2 = wiz1.isNonStandardFieldsEnable;
        Contact testContact = TestingUtils.createContact(testAccount.Id, false);
        testContact.email ='test@yrsy.com';
        testContact.phone = '9066376272';
        insert testContact;
        wiz1.profile.Billing_Contact__c = testContact.id;
        wiz1.fetchcontact();
        wiz1.updateOpportunityCustomerID();
        wiz1.attachDocumentsfreeupin();
        wiz1.previousFreeUpIn();
        
        //wiz1.saveContactAndGoToStepSeven();
        wiz1.createNewContact();
        wiz1.stepEight();  
        test.stopTest();  
    }  
}