@isTest
private class TestWelcomeEmailWizardModel {
    static String closedStatusLabel;
    static String openStatusLabel;
    static Account testAct;
    static Opportunity testOpp;
    static Contact testContact;
    static Contact testContact2;
    static User testUser;
    static User testUser2;
    static Group testGroup;

    static {
        System.runAs(TestingUtils.ADMIN_USER) {
            IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();
            Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
            testAct = TestingUtils.createAccounts(1, true)[0];
            testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, false);
            testContact = TestingUtils.createContact(testAct.Id, true);
            testContact2 = TestingUtils.createContact(testAct.Id, true);
            testUser = TestingUtil.createUsers(1, true)[0];
            testUser2 = TestingUtil.createUsers(1, true)[0];
        }

        List<Template_Name_For_Service_Line__c> caseLinkTemplate = Test.loadData(Template_Name_For_Service_Line__c.SObjectType,'TemplateNameForServiceLine');
        List<Customer_Onboarding_Images_And_Links__c> coImagesAndLinks = Test.loadData(Customer_Onboarding_Images_And_Links__c.SObjectType,'CustomerOnboardingImagesAndLinks');
    }
    
    static void setup() {
        List<CaseStatus> closedStatus = [Select Id, MasterLabel From CaseStatus Where IsClosed = true AND MasterLabel='Closed' LIMIT 1];
        System.assertEquals(1, closedStatus.size(), 'We did not get back a CaseStatus that is Closed called "Closed". Change query to look for an existing Closed CaseStatus');
        closedStatusLabel = closedStatus[0].MasterLabel;
        List<CaseStatus> openStatus = [Select Id, MasterLabel From CaseStatus Where IsClosed = false AND MasterLabel='New' LIMIT 1];
        System.assertEquals(1, openStatus.size(), 'We did not get back a CaseStatus that is Open called "New". Change query to look for an existing Open CaseStatus');
        openStatusLabel = openStatus[0].MasterLabel;
    
        List<Group> testGroups = [Select Id from Group where DeveloperName = :WelcomeEmailController.NCSP_QUEUE_NAME and Type = 'Queue' Limit 1];
        
        if( testGroups.isEmpty() )
        {
            testGroup = new Group(Name='NCSP FIFO', DeveloperName = 'NCSP_FIFO_First_in_First_out', Type = 'Queue');
            insert testGroup;
    
            QueueSobject testQueue = new QueueSObject(QueueId = testGroup.Id, SobjectType = 'Case');
            System.runAs(TestingUtils.ADMIN_USER) {
                insert testQueue;
            }
        }
        else{
            testGroup = testGroups[0];
        }
    }

    static testMethod void testConstructor() {
        // Given a case, the model should create an instance of itself that 
    }
    
    static testMethod void testGetFieldsToDisplay() {
        WelcomeEmailWizardModel.fieldsInList = new List<String>{'Field1', 'Field2', 'Field3'};
        String EXPECTED_STRING = ',Field1,Field2,Field3';
        String actualString = WelcomeEmailWizardModel.fieldsToDisplay;

        System.assertEquals(EXPECTED_STRING, actualString, 'The fieldset was not successfully converted into a string');
    }

    static testMethod void testGetFieldsToDisplayWithNoFields() {
        WelcomeEmailWizardModel.fieldsInList = new List<String>();
        String actualString = WelcomeEmailWizardModel.fieldsToDisplay;

        System.assert(TestingUtils.pageMessageContains(WelcomeEmailWizardModel.NO_FIELD_IN_FIELDSET), 'An error message should be shown saying there are no fields in fieldset');
    }

    static testMethod void testFilterAssociatedCases() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.ownerId = testUser.Id;
        //(testUser) {
            insert mainCase;
       // }

        List<Case> cases = TestingUtils.createCases(50, testOpp, testContact2, false);
        UnitTest.addData(cases).tag('Cases').divide(2).part('Open Cases').part('Closed Cases');
        UnitTest.get('Open Cases').divide(2).part('Expected Cases').part('Not Expected Cases');
        UnitTest.get('Expected Cases').divide(2).part('Open Cases With Same Contact and Owner')
                                                .part('Open Cases With Same Contact and In Queue');
        UnitTest.get('Not Expected Cases').divide(4).part('Open Cases With Same Contact Different Owner')
                                                    .part('Open Cases With Different Contact Same Owner')
                                                    .part('Open Cases With Different Contact In Queue')
                                                    .part('Open Cases With Form Submitted');
        UnitTest.get('Closed Cases').divide(2).part('Closed Cases With Same Contact and Owner')
                                              .part('Closed Cases With Same Contact and In Queue');
        UnitTest.get('Open Cases With Same Contact and Owner').tag('Same Contact').tag('Same Owner');
        UnitTest.get('Open Cases With Same Contact and In Queue').tag('Same Contact').tag('In Queue');
        UnitTest.get('Open Cases With Same Contact Different Owner').tag('Same Contact');
        UnitTest.get('Open Cases With Different Contact Same Owner').tag('Same Owner');
        UnitTest.get('Open Cases With Different Contact In Queue').tag('In Queue');
        UnitTest.get('Closed Cases With Same Contact and Owner').tag('Same Contact').tag('Same Owner');
        UnitTest.get('Closed Cases With Same Contact and In Queue').tag('Same Contact').tag('In Queue');

        UnitTest.get('Open Cases With Form Submitted').property('Customer_Info_Form_Submitted_Date__c').assign(Date.today());

        UnitTest.get('Open Cases').property('Status').assign(openStatusLabel);
        UnitTest.get('Closed Cases').property('Status').assign(closedStatusLabel);

        UnitTest.get('Same Contact').property('ContactId').assign(testContact.Id);
        UnitTest.get('Same Owner').property('OwnerId').assign(testUser.Id);
        UnitTest.get('In Queue').property('OwnerId').assign(testGroup.Id);
        UnitTest.get('Cases').minus('Same Contact').property('ContactId').assign(testContact2.Id);
        UnitTest.get('Cases').minus('Same Owner').minus('In Queue').property('OwnerId').assign(testUser2.Id);

        UnitTest.get('Cases').insertAll();

        WelcomeEmailWizardModel modelInstance = new WelcomeEmailWizardModel(mainCase);
        Test.startTest();
            List<Case> filteredCases = modelInstance.filterAssociatedCases();
        Test.stopTest();

        UnitTest.analyze('Expected Cases').assertEquivalence(filteredCases, 'ID of filtered Cases not equivalent to ID of expected Cases');
    }

    static testMethod void testRelatedCasesInfoMessage() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.ownerId = testUser.Id;
        //System.RunAs(testUser) {
            insert mainCase;
        //}

        WelcomeEmailWizardModel modelInstance = new WelcomeEmailWizardModel(mainCase);
        Test.startTest();
            List<WelcomeEmailWizardModel.SelectableCase> relatedCases = modelInstance.relatedCases;
        Test.stopTest();

        System.assert(TestingUtils.pageMessageContains(WelcomeEmailWizardModel.NO_RELATED_CASES_FOUND), 'An info message should be shown saying there are no related Cases');
    }

    static testMethod void testRelatedCases() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.ownerId = testUser.Id;
        //System.RunAs(testUser) {
            insert mainCase;
       // }

        List<Case> cases = TestingUtils.createCases(100, testOpp, testContact2, false);
        UnitTest.addData(cases).tag('Cases').divide(2).part('Related Cases').part('Unrelated Cases');
        UnitTest.get('Related Cases').property('Status').assign(openStatusLabel)
                                     .property('ContactId').assign(testContact.Id)
                                     .property('OwnerId').assign(testUser.Id);
        UnitTest.get('Unrelated Cases').property('ContactId').assign(testContact2.Id);

        UnitTest.get('Cases').insertAll();

        WelcomeEmailWizardModel modelInstance = new WelcomeEmailWizardModel(mainCase);
        Test.startTest();
            List<WelcomeEmailWizardModel.SelectableCase> relatedCases = modelInstance.relatedCases;
        Test.stopTest();

        List<Case> actualCases = new List<Case>();
        for (WelcomeEmailWizardModel.SelectableCase sc : relatedCases) 
            actualCases.add(sc.caseObject);

        UnitTest.analyze('Related Cases').assertEquivalence(actualCases, 'ID of converted SelectableCases not equivalent to ID of related Cases');
    }

    static testMethod void testRelatedCases_WithMatchingCriteria() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.ownerId = testUser.Id;
        
        //System.RunAs(testUser) {
            insert mainCase;
       // }

        List<String> dealTypes = new List<String>{ 'DT1', 'DT2', 'DT3' };
        List<String> serviceLines = new List<String>{ 'SL1', 'SL2', 'SL3' };
        List<String> trueOrFalse = new List<String>{ 'YES', 'NO' };

        List<Case> cases = TestingUtils.createCases(50, testOpp, testContact2, false);
        UnitTest.addData(cases).tag('Cases').divide(2).part('Related Cases').part('Unrelated Cases');
        UnitTest.get('Related Cases').property('Status').assign(openStatusLabel)
                                     .property('ContactId').assign(testContact.Id)
                                     .property('OwnerId').assign(testUser.Id);
        UnitTest.get('Unrelated Cases').property('ContactId').assign(testContact2.Id);

        UnitTest.get('Related Cases').divide(2).part('Related Cases With Matching Criteria')
                                               .part('Related Cases Without Matching Criteria');

        UnitTest.get('Related Cases Without Matching Criteria').property('Deal_Type__c').assign('No Deal Type')
                                                               .property('NCSP_Service_line__c').assign('No Service Line')
                                                               .property('Supplies_Order_Required__c').assign('No SOR');
        UnitTest.get('Related Cases With Matching Criteria').property('Deal_Type__c').assignFrom(dealTypes)
                                                            .property('NCSP_Service_line__c').assignFrom(serviceLines)
                                                            .property('Supplies_Order_Required__c').assignFrom(trueOrFalse);
        List<Customer_Onboarding_Criteria__c> criteriaToInsert = new List<Customer_Onboarding_Criteria__c>();
        Set<String> existingCriteria = new Set<String>();
        for (Case c : (List<Case>)UnitTest.get('Related Cases With Matching Criteria').getList()) {
            String criteriaHash = c.NCSP_Service_line__c+c.Deal_Type__c+c.Supplies_Order_Required__c;
            if (!existingCriteria.contains(criteriaHash)) {
                Boolean sor = (c.Supplies_Order_Required__c=='YES'?true:false);
                criteriaToInsert.add(
                    GenerateTestData.createTestCriteria(c.NCSP_Service_line__c, c.Deal_Type__c, '', sor, false));
                existingCriteria.add(criteriaHash);
            }
        }

        insert criteriaToInsert;

        List<Customer_Onboarding_Field__c> testCofs = new List<Customer_Onboarding_Field__c>();
        Integer i =0;
        for (Customer_Onboarding_Criteria__c coc : criteriaToInsert) {
            testCofs.add(
                GenerateTestData.createTestOnboardingField(coc.Id, 'field1__c', 'field1', i++, '', false));
        }

        insert testCofs;

        UnitTest.get('Cases').insertAll();

        WelcomeEmailWizardModel modelInstance = new WelcomeEmailWizardModel(mainCase);
        Test.startTest();
            List<WelcomeEmailWizardModel.SelectableCase> relatedCases = modelInstance.relatedCases;
        Test.stopTest();

        List<Case> actualCases = new List<Case>();
        for (WelcomeEmailWizardModel.SelectableCase sc : relatedCases) 
            actualCases.add(sc.caseObject);

        UnitTest.analyze('Related Cases').assertEquivalence(actualCases, 'ID of converted SelectableCases not equivalent to ID of related Cases');

        for (WelcomeEmailWizardModel.SelectableCase sc : relatedCases) {
            if (UnitTest.analyze('Related Cases With Matching Criteria').hasId(sc.caseObject.Id)) {
                System.assertEquals(true, sc.hasMatchingCriteria, 
                    'Wrapper object should indicate that the case has a matching criteria');
            } else {
                System.assertEquals(false, sc.hasMatchingCriteria, 
                    'Wrapper object should indicate that the case does not have a matching criteria');
            }
        }
    }

    /*
    *   Template Name of a given case is as follows:
    *       [Service Line]_[Contacted/Not_Contacted]_Template
    */
    static testMethod void testRetrieveParentTemplate() {
        EmailTemplate template_A_Contacted = GenerateTestData.createEmailTemplate('A_Ctd_Template', 'A_Ctd_Template');
        EmailTemplate template_A_Not_Contacted = GenerateTestData.createEmailTemplate('A_NotCtd_Template', 'A_NotCtd_Template');
        EmailTemplate template_B_Contacted = GenerateTestData.createEmailTemplate('B_Ctd_Template', 'B_Ctd_Template');
        EmailTemplate template_B_Not_Contacted = GenerateTestData.createEmailTemplate('B_NotCtd_Template', 'B_NotCtd_Template');
        System.runAs(TestingUtils.ADMIN_USER) {
            insert new List<EmailTemplate>{template_A_Contacted, template_A_Not_Contacted, template_B_Contacted, template_B_Not_Contacted};
        }

        List<Case> testCases = TestingUtils.createCases(4, testOpp, testContact, false);
        Case case_SL1_Contacted = testCases[0];
        Case case_SL1_Not_Contacted = testCases[1];
        Case case_SL2_Contacted = testCases[2];
        Case case_SL2_Not_Contacted = testCases[3];

        case_SL1_Contacted.NCSP_Service_line__c = 'SL1';
        case_SL1_Not_Contacted.NCSP_Service_line__c = 'SL1';
        case_SL1_Contacted.Date_welcome_call_completed__c = Date.today();
        case_SL1_Not_Contacted.Date_welcome_call_completed__c = null;

        case_SL2_Contacted.NCSP_Service_line__c = 'SL2';
        case_SL2_Not_Contacted.NCSP_Service_line__c = 'SL2';
        case_SL2_Contacted.Date_welcome_call_completed__c = Date.today();
        case_SL2_Not_Contacted.Date_welcome_call_completed__c = null;

        insert testCases;

        Test.startTest();
            WelcomeEmailWizardModel model_A_Contacted = new WelcomeEmailWizardModel(case_SL1_Contacted);
            WelcomeEmailWizardModel model_A_Not_Contacted = new WelcomeEmailWizardModel(case_SL1_Not_Contacted);
            WelcomeEmailWizardModel model_B_Contacted = new WelcomeEmailWizardModel(case_SL2_Contacted);
            WelcomeEmailWizardModel model_B_Not_Contacted = new WelcomeEmailWizardModel(case_SL2_Not_Contacted);
        Test.stopTest();

        System.assertEquals(template_A_Contacted.Id, model_A_Contacted.parentTemplate.Id, 'The parent template for this service line / call completed criteria was not retrieved');
        System.assertEquals(template_A_Not_Contacted.Id, model_A_Not_Contacted.parentTemplate.Id, 'The parent template for this service line / call completed criteria was not retrieved');
        System.assertEquals(template_B_Contacted.Id, model_B_Contacted.parentTemplate.Id, 'The parent template for this service line / call completed criteria was not retrieved');
        System.assertEquals(template_B_Not_Contacted.Id, model_B_Not_Contacted.parentTemplate.Id, 'The parent template for this service line / call completed criteria was not retrieved');
    }

    static testMethod void testRetrieveParentTemplateNotFound() {
        Case testCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        testCase.NCSP_Service_line__c = 'NA';
        testCase.Date_welcome_call_completed__c = null;
        insert testCase;

        Test.startTest();
            WelcomeEmailWizardModel model = new WelcomeEmailWizardModel(testCase);
        Test.stopTest();

        System.assertEquals(null, model.parentTemplate, 'Parent template should return null because there are no templates matching case criteria');
        System.assertEquals(true, model.errorRetrievingTemplate, 'Error flag should be on because there are no templates matching case criteria');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailWizardModel.NO_TEMPLATE), 'Info message about having no template should be displayed because the template is not found in the database');
    }

    /*
    *   Text Template Name of a given case is as follows:
    *       [Service Line]_[Contacted/Not_Contacted]_[Language]_Template
    */
    static testMethod void testRetrieveTextTemplate() {
        EmailTemplate template_A_Ctd_English = 
            GenerateTestData.createEmailTemplate('A_Ctd_USEnglish_Text', 'A_Ctd_USEnglish_Text');
        EmailTemplate template_A_Not_Ctd_English = 
            GenerateTestData.createEmailTemplate('A_NotCtd_USEnglish_Text', 'A_NotCtd_USEnglish_Text');
        EmailTemplate template_A_Ctd_Spanish = 
            GenerateTestData.createEmailTemplate('A_Ctd_Spanish_Text', 'A_Ctd_Spanish_Text');
        EmailTemplate template_A_Not_Ctd_Spanish = 
            GenerateTestData.createEmailTemplate('A_NotCtd_Spanish_Text', 'A_NotCtd_Spanish_Text');
        EmailTemplate template_B_Ctd_English = 
            GenerateTestData.createEmailTemplate('B_Ctd_USEnglish_Text', 'B_Ctd_USEnglish_Text');
        EmailTemplate template_B_Not_Ctd_English = 
            GenerateTestData.createEmailTemplate('B_NotCtd_USEnglish_Text', 'B_NotCtd_USEnglish_Text');
        EmailTemplate template_B_Ctd_Spanish = 
            GenerateTestData.createEmailTemplate('B_Ctd_Spanish_Text', 'B_Ctd_Spanish_Text');
        EmailTemplate template_B_Not_Ctd_Spanish = 
            GenerateTestData.createEmailTemplate('B_NotCtd_Spanish_Text', 'B_NotCtd_Spanish_Text');
        System.runAs(TestingUtils.ADMIN_USER) {
            insert new List<EmailTemplate>{template_A_Ctd_English, template_A_Not_Ctd_English, 
                                            template_A_Ctd_Spanish, template_A_Not_Ctd_Spanish, 
                                            template_B_Ctd_English, template_B_Not_Ctd_English,
                                            template_B_Ctd_Spanish, template_B_Not_Ctd_Spanish};
        }

        List<Case> testCases = TestingUtils.createCases(8, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').divide(8).part('Case SL1 Ctd English')
                                                          .part('Case SL1 Not Ctd English')
                                                          .part('Case SL1 Ctd Spanish')
                                                          .part('Case SL1 Not Ctd Spanish')
                                                          .part('Case SL2 Ctd English')
                                                          .part('Case SL2 Not Ctd English')
                                                          .part('Case SL2 Ctd Spanish')
                                                          .part('Case SL2 Not Ctd Spanish');

        UnitTest.get('Case SL1 Ctd English').tag('Case SL1').tag('Ctd').tag('English');
        UnitTest.get('Case SL1 Not Ctd English').tag('Case SL1').tag('Not Ctd').tag('English');
        UnitTest.get('Case SL1 Ctd Spanish').tag('Case SL1').tag('Ctd').tag('Spanish');
        UnitTest.get('Case SL1 Not Ctd Spanish').tag('Case SL1').tag('Not Ctd').tag('Spanish');
        UnitTest.get('Case SL2 Ctd English').tag('Case SL2').tag('Ctd').tag('English');
        UnitTest.get('Case SL2 Not Ctd English').tag('Case SL2').tag('Not Ctd').tag('English');
        UnitTest.get('Case SL2 Ctd Spanish').tag('Case SL2').tag('Ctd').tag('Spanish');
        UnitTest.get('Case SL2 Not Ctd Spanish').tag('Case SL2').tag('Not Ctd').tag('Spanish');


        UnitTest.get('Case SL1').property('NCSP_Service_line__c').assign('SL1');
        UnitTest.get('Case SL2').property('NCSP_Service_line__c').assign('SL2');
        UnitTest.get('Ctd').property('Date_welcome_call_completed__c').assign(Date.today());
        UnitTest.get('Not Ctd').property('Date_welcome_call_completed__c').assign(null);
        UnitTest.get('Cases').insertAll();

        Test.startTest();
            WelcomeEmailWizardModel model_A_Ctd_English = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL1 Ctd English').getList()[0], 'USEnglish');
            WelcomeEmailWizardModel model_A_Not_Ctd_English = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL1 Not Ctd English').getList()[0], 'USEnglish');
            WelcomeEmailWizardModel model_A_Ctd_Spanish = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL1 Ctd Spanish').getList()[0], 'Spanish');
            WelcomeEmailWizardModel model_A_Not_Ctd_Spanish = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL1 Not Ctd Spanish').getList()[0], 'Spanish');
            WelcomeEmailWizardModel model_B_Ctd_English = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL2 Ctd English').getList()[0], 'USEnglish');
            WelcomeEmailWizardModel model_B_Not_Ctd_English = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL2 Not Ctd English').getList()[0], 'USEnglish');
            WelcomeEmailWizardModel model_B_Ctd_Spanish = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL2 Ctd Spanish').getList()[0], 'Spanish');
            WelcomeEmailWizardModel model_B_Not_Ctd_Spanish = new WelcomeEmailWizardModel((Case)UnitTest.get('Case SL2 Not Ctd Spanish').getList()[0], 'Spanish');
        Test.stopTest();

        System.assertEquals(template_A_Ctd_English.DeveloperName, model_A_Ctd_English.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');
        System.assertEquals(template_A_Not_Ctd_English.DeveloperName, model_A_Not_Ctd_English.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');
        System.assertEquals(template_A_Ctd_Spanish.DeveloperName, model_A_Ctd_Spanish.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');
        System.assertEquals(template_A_Not_Ctd_Spanish.DeveloperName, model_A_Not_Ctd_Spanish.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');
        System.assertEquals(template_B_Ctd_English.DeveloperName, model_B_Ctd_English.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');
        System.assertEquals(template_B_Not_Ctd_English.DeveloperName, model_B_Not_Ctd_English.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');
        System.assertEquals(template_B_Ctd_Spanish.DeveloperName, model_B_Ctd_Spanish.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');
        System.assertEquals(template_B_Not_Ctd_Spanish.DeveloperName, model_B_Not_Ctd_Spanish.textTemplate.DeveloperName, 
            'The text template for this service line / call completed / language criteria was not retrieved');

    }

    static testMethod void testRetrieveTextTemplateNotFound() {
        Case testCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        testCase.NCSP_Service_line__c = 'NA';
        testCase.Date_welcome_call_completed__c = null;
        insert testCase;

        Test.startTest();
            WelcomeEmailWizardModel model = new WelcomeEmailWizardModel(testCase, 'English');
        Test.stopTest();

        System.assertEquals(null, model.textTemplate, 'Text template should return null because there are no templates matching case criteria');
        System.assertEquals(true, model.errorRetrievingTemplate, 'Error flag should be on because there are no templates matching case criteria');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailWizardModel.NO_TEMPLATE), 'Info message about having no template should be displayed because the template is not found in the database');
    }

    static testMethod void testGetMapOfImages() {
        Map<String, String> expectedMap = 
            new Map<String, String>{ 'LINK:desc1' => 'French.desc1link.com',
                                     'IMG:desc2' => 'French.desc2link.com',
                                     'IMG:desc3' => 'French.desc3link.com',
                                     'IMG:desc4' => 'French.desc4link.com' };

        Test.startTest();
            Map<String, String> actualMap = WelcomeEmailWizardModel.getMapOfImages('French');
        Test.stopTest();

        System.assertEquals(expectedMap.keySet(), actualMap.keySet(), 'Expected keyset was not returned');
        for (String key : expectedMap.keySet()) {
            System.assertEquals(expectedMap.get(key), actualMap.get(key), 'Value for key is not the same');
        }
    }


    static testMethod void testGetMapOfImagesEmptyMap() {
        Test.startTest();
            Map<String, String> actualMap = WelcomeEmailWizardModel.getMapOfImages('Yugoslavian');
        Test.stopTest();

        System.assert(actualMap.isEmpty(), 'Expected empty map was not returned');
    }

    static testMethod void testDefaultValuesOnPage1() {
        Case testCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        testCase.NCSP_Service_line__c = 'SL1';
        testCase.Date_welcome_call_completed__c = null;
        testCase.Customer_Info_Form_Submitted_Date__c = DateTime.now();
        insert testCase;

        String expectedTemplateName = 'A';
        Boolean expectedHasBeenContacted = true;
        String expectedLanguage = 'USEnglish';

        Test.startTest();
            WelcomeEmailWizardModel wewm = new WelcomeEmailWizardModel(testCase);
        Test.stopTest();

        System.assertEquals(expectedTemplateName, wewm.templateType, 'Template Type Name should be inferred from the Custom Setting called "Template Name For Service Line"');
        System.assertEquals(expectedHasBeenContacted, wewm.hasBeenContacted, 'hasBeenContacted should be true regardless of Date_Welcome_Call_Completed_Date__c because the form has been submitted by the customer');
        System.assertEquals(expectedLanguage, wewm.language, 'language of wizard should defualt to English');
    }
    
    @isTest
    static void testTemplateOrderNum() {
        // Test templateOrderNum getter
        Map<String, Integer> result = WelcomeEmailWizardModel.templateOrderNum;

        // Assert the map has the correct values
        System.assertEquals(0, result.get('DM'), 'DM should be 0.');
        System.assertEquals(1, result.get('SS'), 'SS should be 1.');
        System.assertEquals(2, result.get('RM'), 'RM should be 2.');
        System.assertEquals(3, result.get('RM_SS'), 'RM_SS should be 3.');
    }
 
    @isTest static void testFormCompleted() {
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test67user@example.com',
            Phone = '123-456-7890',
            MailingStreet = '123 Test St',
            MailingCity = 'Test City',
            MailingState = 'CA',
            MailingPostalCode = '12345',
            MailingCountry = 'USA'
        );
        insert testContact;
        // Step 1: Create a test case (main case)
        Case testCase = new Case(
            Status = 'New',
            ContactId = testContact.id,  
            Customer_Info_Form_Submitted_Date__c = null  // Set to null initially
        );
        insert testCase;

        // Step 2: Instantiate the WelcomeEmailWizardModel with the created case
        WelcomeEmailWizardModel model = new WelcomeEmailWizardModel(testCase);
        
        // Step 3: Verify that formCompleted is false (because the form submission date is null)
        System.assertEquals(false, model.formCompleted, 'The formCompleted flag should be false when Customer_Info_Form_Submitted_Date__c is null.');

        // Step 4: Update the test case to set the form submission date
        testCase.Customer_Info_Form_Submitted_Date__c = Date.today();  // Set a value for the form submitted date
        update testCase;

        // Step 5: Re-initialize the model with the updated case
        model = new WelcomeEmailWizardModel(testCase);
        
        // Step 6: Verify that formCompleted is true (because the form submission date is now set)
        System.assertEquals(true, model.formCompleted, 'The formCompleted flag should be true when Customer_Info_Form_Submitted_Date__c is not null.');
    }
}