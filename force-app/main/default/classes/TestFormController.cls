@isTest 
private class TestFormController {
    static Account testAct;
    static Opportunity testOpp;
    static Contact testContact;
    static User testUser;
    static FormController controller;

    static Set<String> expectedCaseFields = new Set<String>(FormController.initialCaseFields);
    static Set<String> expectedProfileFields = new Set<String>();
    static Set<String> expectedContactFields = new Set<String>();
    static List<FormController.ModifiableField> expectedContactMFields = new List<FormController.ModifiableField>();
    static Map<String, List<FormController.ModifiableField>> tagToExpectedCaseMFields = new Map<String, List<FormController.ModifiableField>>();
    static Map<String, List<FormController.ModifiableField>> tagToExpectedProfileMFields = new Map<String, List<FormController.ModifiableField>>();

    static {
        System.runAs(TestingUtils.ADMIN_USER) {
            OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
            AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
            IM_Country__c cntry = TestingUtil.createIMCountry();
            RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
            Id standardPB = Test.getStandardPricebookId();
            testAct = TestingUtils.createAccounts(1, true)[0];
            testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, false);
                testOpp.Source_System__c = 'test SKP Europe';
                testOpp.Billing_Country__c = cntry.id;
                testOpp.Lead_Source_Most_Recent__c = 'x';
                testOpp.StageName = '1 - Qualification';
                testOpp.IM_Servicing_Region__c ='London';
                testOpp.IME_Reason_Won__c = 'Price';
                testOpp.CloseDate = System.today();
                testOpp.CurrencyIsoCode = 'USD';
                testOpp.Lead_Source_Most_Recent__c = 'x';
                testOpp.IM_Booked_Date__c = System.today();
                testOpp.IM_Commit_to_Forecast__c = true;
                testOpp.IM_Stage_5_Entered_Date__c  = System.today();
                testOpp.RecordTypeId = EUOppType.Id;
                testOpp.pricebook2ID= standardPB;
                testOpp.type = 'Price Change';
            
        	insert testOpp;
            testContact = TestingUtils.createContact(testAct.Id, false);
            testContact.firstName = 'test_FormCont_FirstName';
            insert testContact;
            testUser = TestingUtil.createUsers(1, true)[0];
            controller = new FormController();
        }

        //List<Case_Link_Template__c> caseLinkTemplate = Test.loadData(Case_Link_Template__c.SObjectType,'CaseLinkTemplate');
    }

    static List<FormController.ModifiableField> convertToMFields(List<Customer_Onboarding_Field__c> cofs) {
        List<FormController.ModifiableField> mfields = new List<FormController.ModifiableField>();
        for (Customer_Onboarding_Field__c cof : cofs) 
            mfields.add(new FormController.ModifiableField(cof.Field_API_Name__c, cof.Field_Display_Label__c, cof.Related_Object__c));
        return mfields;
    }

    static List<FormController.ModifiableField> convertToMFields(List<Customer_Onboarding_Field__c> cofs, String lang) {
        List<FormController.ModifiableField> mfields = new List<FormController.ModifiableField>();
        for (Customer_Onboarding_Field__c cof : cofs) {
            if (lang == 'French')
                mfields.add(new FormController.ModifiableField(cof.Field_API_Name__c, cof.Field_Display_Label_French__c, cof.Related_Object__c));
            else
                mfields.add(new FormController.ModifiableField(cof.Field_API_Name__c, cof.Field_Display_Label__c, cof.Related_Object__c));
        }
        return mfields;
    }

    static Map<Id, List<Customer_Onboarding_Field__c>> setupDummyCase2FieldsMap() {
        List<Case> testCases = TestingUtils.createCases(10, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').divide(5).part('Cases With All Fields').part('Cases With Only Case Fields')
                                                          .part('Cases With Only Profile Fields').part('Cases With Only Contact Fields')
                                                          .part('Cases With No Fields');
        UnitTest.get('Cases').dummyInsert();

        tagToExpectedCaseMFields.put('Cases With All Fields', new List<FormController.ModifiableField>());
        tagToExpectedCaseMFields.put('Cases With Only Case Fields', new List<FormController.ModifiableField>());
        tagToExpectedCaseMFields.put('Cases With Only Profile Fields', new List<FormController.ModifiableField>());
        tagToExpectedCaseMFields.put('Cases With Only Contact Fields', new List<FormController.ModifiableField>());
        tagToExpectedCaseMFields.put('Cases With No Fields', new List<FormController.ModifiableField>());
        tagToExpectedProfileMFields.put('Cases With All Fields', new List<FormController.ModifiableField>());
        tagToExpectedProfileMFields.put('Cases With Only Case Fields', new List<FormController.ModifiableField>());
        tagToExpectedProfileMFields.put('Cases With Only Profile Fields', new List<FormController.ModifiableField>());
        tagToExpectedProfileMFields.put('Cases With Only Contact Fields', new List<FormController.ModifiableField>());
        tagToExpectedProfileMFields.put('Cases With No Fields', new List<FormController.ModifiableField>());

        Boolean expectedListHasBeenSet = false;
        Map<Id, List<Customer_Onboarding_Field__c>> caseToFields = new Map<Id, List<Customer_Onboarding_Field__c>>();
        for (Case c : (List<Case>)UnitTest.get('Cases With All Fields').getList()) {
            List<Customer_Onboarding_Field__c> testCaseFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', '', false);
            List<Customer_Onboarding_Field__c> testProfileFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', 'Customer_Profile__c', false);
            List<Customer_Onboarding_Field__c> testContactFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', 'Contact', false);
            List<Customer_Onboarding_Field__c> allTestFields = new List<Customer_Onboarding_Field__c>(testCaseFields);
            allTestFields.addAll(testProfileFields); allTestFields.addAll(testContactFields);
            TestingUtils.dummyInsert(allTestFields);
            caseToFields.put(c.Id, allTestFields);
            if (!expectedListHasBeenSet) {
                tagToExpectedCaseMFields.get('Cases With All Fields').addAll(convertToMFields(testCaseFields));
                tagToExpectedProfileMFields.get('Cases With All Fields').addAll(convertToMFields(testProfileFields));
                expectedListHasBeenSet = true;
            }
        }
        expectedListHasBeenSet=false;
        for (Case c : (List<Case>)UnitTest.get('Cases With Only Case Fields').getList()) {
            List<Customer_Onboarding_Field__c> testCaseFields = GenerateTestData.createTestOnboardingFields(10, null, 'testName', 'testLabel', '', false);
            TestingUtils.dummyInsert(testCaseFields);
            caseToFields.put(c.Id, testCaseFields);
            if (!expectedListHasBeenSet) {
                expectedCaseFields.addAll(Pluck.strings('Field_API_Name__c', testCaseFields));
                tagToExpectedCaseMFields.get('Cases With Only Case Fields').addAll(convertToMFields(testCaseFields));
                expectedListHasBeenSet=true;
            }
        }
        expectedListHasBeenSet=false;
        for (Case c : (List<Case>)UnitTest.get('Cases With Only Profile Fields').getList()) {
            List<Customer_Onboarding_Field__c> testProfileFields = GenerateTestData.createTestOnboardingFields(10, null, 'testName', 'testLabel', 'Customer_Profile__c', false);
            TestingUtils.dummyInsert(testProfileFields);
            caseToFields.put(c.Id, testProfileFields);
            if (!expectedListHasBeenSet) {
                expectedProfileFields.addAll(Pluck.strings('Field_API_Name__c', testProfileFields));
                tagToExpectedProfileMFields.get('Cases With Only Profile Fields').addAll(convertToMFields(testProfileFields));
                expectedListHasBeenSet=true;
            }   
        }
        expectedListHasBeenSet=false;
        for (Case c : (List<Case>)UnitTest.get('Cases With Only Contact Fields').getList()) {
            List<Customer_Onboarding_Field__c> testContactFields = GenerateTestData.createTestOnboardingFields(10, null, 'testName', 'testLabel', 'Contact', false);
            TestingUtils.dummyInsert(testContactFields);
            caseToFields.put(c.Id, testContactFields);
            if (!expectedListHasBeenSet) {
                expectedContactFields.addAll(Pluck.strings('Field_API_Name__c', testContactFields));
                expectedContactMFields.addAll(convertToMFields(testContactFields));
                expectedListHasBeenSet=true;
            }
        } 
        for (Case c : (List<Case>)UnitTest.get('Cases With No Fields').getList()) {
            caseToFields.put(c.Id, new List<Customer_Onboarding_Field__c>());
        }
        return caseToFields;
    }

    // oldCheckbox and newCheckbox values not asserted for equivalence
    static void assertModifiableFieldsEquivalence(List<FormController.ModifiableField> expected, List<FormController.ModifiableField> actual) {
        for (FormController.ModifiableField mfActual : actual) {
            Boolean found=false;
            for (FormController.ModifiableField mfExpected : expected) {
                if (mfExpected.fieldLabel == mfActual.fieldLabel &&
                    mfExpected.fieldName == mfActual.fieldName &&
                    mfExpected.rObject == mfActual.rObject) {
                    found = true;
                    break;
                }
            }
            if (!found) System.assert(false, 'actual modifiable field was not found in expected modifiable field list. Actual: ' + mfActual +
                                                '\n Expected: '+expected);
        }
    }

    static testMethod void testConstructorWelcomeEmailNotSent() {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4};
        insert testCocs;
        //CREATE CASES WITH CRITERIAS
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1); 
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); 
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3); 
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4); 
        case1.Welcome_Packet_Sent_Date__c = Date.today(); case1.Customer_Info_Form_Submitted_Date__c = Date.today();
        case2.Welcome_Packet_Sent_Date__c = Date.today(); case2.Customer_Info_Form_Submitted_Date__c = Date.today();
        case3.Welcome_Packet_Sent_Date__c = Date.today(); case3.Customer_Info_Form_Submitted_Date__c = Date.today();
        case4.Welcome_Packet_Sent_Date__c = null; case4.Customer_Info_Form_Submitted_Date__c = Date.today();
        Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4};
        insert casesToInsert;

        //CALL THE CONSTURCTOR WITH THE CASES
        Set<Id> expectedCaseIDs = Pluck.ids(casesToInsert);
        PageReference pageRef = Page.CustomerInformationForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.join(new List<Id>(expectedCaseIDs), ','));
        Test.startTest();
            FormController testController = new FormController();
        Test.stopTest();
            boolean englishTest = testController.english;
            boolean frenchTest = testController.french;
            boolean noFieldsTest = testController.noFields;
            boolean displayPageTest = testController.displayPage;
            string radioValueTest = testController.radioValue;
            string dummyInputTest = testController.dummyInput;
            //string getRecordNameTest = testController.getRecordName();
            //testController.submitForm();
            
            
        
        System.assert(TestingUtils.pageMessageContains(FormController.EMAIL_NOT_SENT), 'There should be an error message about welcome email not being sent for at least one of the cases');
        System.assert(TestingUtils.pageMessageContains(FormController.FORM_SUBMITTED), 'There should be an error message about form being submitted for all cases');
    }

    static testMethod void testConstructorFormSubmitted() {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
       	AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4};
        insert testCocs;
        //CREATE CASES WITH CRITERIAS
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1); 
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); 
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3); 
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4); 
        case1.Welcome_Packet_Sent_Date__c = Date.today(); case1.Customer_Info_Form_Submitted_Date__c = Date.today();
        case2.Welcome_Packet_Sent_Date__c = Date.today(); case2.Customer_Info_Form_Submitted_Date__c = Date.today();
        case3.Welcome_Packet_Sent_Date__c = Date.today(); case3.Customer_Info_Form_Submitted_Date__c = Date.today();
        case4.Welcome_Packet_Sent_Date__c = Date.today(); case4.Customer_Info_Form_Submitted_Date__c = Date.today();
        Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4};
        insert casesToInsert;

        //CALL THE CONSTURCTOR WITH THE CASES
        Set<Id> expectedCaseIDs = Pluck.ids(casesToInsert);
        PageReference pageRef = Page.CustomerInformationForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.join(new List<Id>(expectedCaseIDs), ','));
        Test.startTest();
            FormController testController = new FormController();
        Test.stopTest();

        System.assert(TestingUtils.pageMessageContains(FormController.FORM_SUBMITTED), 'There should be an error message about form being submitted for all cases');
    }

    static testMethod void testConstructorSupplyDated() {
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4};
        insert testCocs;
        //CREATE CASES WITH CRITERIAS
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1); 
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); 
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3); 
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4); 
        case1.Welcome_Packet_Sent_Date__c = Date.today(); case1.Initial_Supply_Order_Date__c = Date.today();
        case2.Welcome_Packet_Sent_Date__c = Date.today(); case2.Initial_Supply_Order_Date__c = Date.today();
        case3.Welcome_Packet_Sent_Date__c = Date.today(); case3.Initial_Supply_Order_Date__c = Date.today();
        case4.Welcome_Packet_Sent_Date__c = Date.today(); case4.Initial_Supply_Order_Date__c = Date.today();
        Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4};
        insert casesToInsert;

        //CALL THE CONSTURCTOR WITH THE CASES
        Set<Id> expectedCaseIDs = Pluck.ids(casesToInsert);
        PageReference pageRef = Page.CustomerInformationForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.join(new List<Id>(expectedCaseIDs), ','));
        Test.startTest();
            FormController testController = new FormController();
        Test.stopTest();

        System.assert(TestingUtils.pageMessageContains(FormController.FORM_SUBMITTED), 'There should be an error message about form being submitted for all cases');
    }

    static testMethod void testConstructorMixedDates() {
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4};
        insert testCocs;
        //CREATE CASES WITH CRITERIAS
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1); 
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); 
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3); 
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4); 
        case1.Welcome_Packet_Sent_Date__c = Date.today(); case1.Service_Order_Date__c = Date.today();
        case2.Welcome_Packet_Sent_Date__c = Date.today(); case2.Initial_Supply_Order_Date__c = Date.today();
        case3.Welcome_Packet_Sent_Date__c = Date.today(); case3.Customer_Info_Form_Submitted_Date__c = Date.today();
        case4.Welcome_Packet_Sent_Date__c = Date.today(); case4.Service_Order_Date__c = Date.today();
        Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4};
        insert casesToInsert;

        //CALL THE CONSTURCTOR WITH THE CASES
        Set<Id> expectedCaseIDs = Pluck.ids(casesToInsert);
        PageReference pageRef = Page.CustomerInformationForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.join(new List<Id>(expectedCaseIDs), ','));
        Test.startTest();
            FormController testController = new FormController();
        Test.stopTest();

        System.assert(TestingUtils.pageMessageContains(FormController.FORM_SUBMITTED), 'There should be an error message about form being submitted for all cases');
    }

    static testMethod void testConstructorLanguageIsInvalid() {
        //CREATE CRITERIAS
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
       	AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4};
        insert testCocs;
        //CREATE CASES WITH CRITERIAS
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1); 
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); 
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3); 
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4); 
        case1.Welcome_Packet_Sent_Date__c = Date.today(); case1.Customer_Info_Form_Submitted_Date__c = Date.today();
        case2.Welcome_Packet_Sent_Date__c = Date.today(); case2.Customer_Info_Form_Submitted_Date__c = null;
        case3.Welcome_Packet_Sent_Date__c = Date.today(); case3.Customer_Info_Form_Submitted_Date__c = null;
        case4.Welcome_Packet_Sent_Date__c = Date.today(); case4.Customer_Info_Form_Submitted_Date__c = null;
        Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4};
        for (Case c : casesToInsert) 
            c.Customer_Profile__c = cp.Id;
        insert casesToInsert;

        Map<Id, Id> criteria2CaseID = new Map<Id, Id>();
        criteria2CaseID.put(testCoc1.Id, case1.Id);
        criteria2CaseID.put(testCoc2.Id, case2.Id);
        criteria2CaseID.put(testCoc3.Id, case3.Id);
        criteria2CaseID.put(testCoc4.Id, case4.Id);

        //ADD FIELDS TO THOSE CRITERIAS (AND SAVE THEM IN EXPECTED MAP)
        Map<Id, Customer_Onboarding_Field__c> expectedCaseFieldMap = new Map<Id, Customer_Onboarding_Field__c>();
        Map<Id, Customer_Onboarding_Field__c> expectedProfileFieldMap = new Map<Id, Customer_Onboarding_Field__c>();
        Customer_Onboarding_Field__c expectedContactField = new Customer_Onboarding_Field__c();

        List<Customer_Onboarding_Field__c> fieldsToInsert = new List<Customer_Onboarding_Field__c>();
        Boolean notYetSet = true;
        for (Customer_Onboarding_Criteria__c coc : testCocs) {
            Customer_Onboarding_Field__c caseCof = GenerateTestData.createTestOnboardingField(coc.Id, 'Status', 'displayLabel', 1, '', false);
            expectedCaseFieldMap.put(criteria2CaseID.get(coc.Id), caseCof);
            Customer_Onboarding_Field__c profileCof = GenerateTestData.createTestOnboardingField(coc.Id, 'Billing_City__c', 'displayLabel', 2, 'Customer_Profile__c', false);
            expectedProfileFieldMap.put(criteria2CaseID.get(coc.Id), profileCof);
            Customer_Onboarding_Field__c contactCof = GenerateTestData.createTestOnboardingField(coc.Id, 'MailingCity', 'displayLabel', 3, 'Contact', false);
            if (notYetSet)  {
                expectedContactField = (contactCof);
                notYetSet=false;
            }
            fieldsToInsert.add(caseCof);
            fieldsToInsert.add(profileCof);
            fieldsToInsert.add(contactCof);
        }
        insert fieldsToInsert;
            
        //CALL THE CONSTURCTOR WITH THE CASES
        Set<Id> expectedCaseIDs = Pluck.ids(casesToInsert);
        PageReference pageRef = Page.CustomerInformationForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.join(new List<Id>(expectedCaseIDs), ','));
        ApexPages.currentPage().getParameters().put('lang', 'Jamaican');

        Test.startTest();
            FormController testController = new FormController();
        Test.stopTest();

        //ASSERT THAT THE CASEWRAPPERS CONTAIN THE CASES AND HAVE THE RIGHT MODIFIABLEFIELDLIST
        System.assert(TestingUtils.pageMessageContains(FormController.UNSUPPORTED_LANG), 'There should be an error message about language not being supported');
        System.assert(TestingUtils.pageMessageContains('Jamaican'), 'The unsupported language should be contained in the error message');
    }

    static testMethod void testConstructor() {
        //CREATE CRITERIAS
        system.debug('get rows :::'+Limits.getQueries());
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
       	AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4};
        insert testCocs;
        system.debug('get rows :::'+Limits.getQueries());
        //CREATE CASES WITH CRITERIAS
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1); 
        system.debug('get rows :::'+Limits.getQueries());
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); 
        system.debug('get rows :::'+Limits.getQueries());
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3); 
        system.debug('get rows :::'+Limits.getQueries());
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4); 
        system.debug('get rows :::'+Limits.getQueries());
        case1.Welcome_Packet_Sent_Date__c = Date.today(); case1.Customer_Info_Form_Submitted_Date__c = Date.today();
        case2.Welcome_Packet_Sent_Date__c = Date.today(); case2.Customer_Info_Form_Submitted_Date__c = null;
        case3.Welcome_Packet_Sent_Date__c = Date.today(); case3.Customer_Info_Form_Submitted_Date__c = null;
        case4.Welcome_Packet_Sent_Date__c = Date.today(); case4.Customer_Info_Form_Submitted_Date__c = null;
        Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4};
        for (Case c : casesToInsert) 
            c.Customer_Profile__c = cp.Id;
        insert casesToInsert;
		system.debug('get rows :::'+Limits.getQueries());
        system.debug('casesToInsert '+casesToInsert);
        Map<Id, Id> criteria2CaseID = new Map<Id, Id>();
        criteria2CaseID.put(testCoc1.Id, case1.Id);
        criteria2CaseID.put(testCoc2.Id, case2.Id);
        criteria2CaseID.put(testCoc3.Id, case3.Id);
        criteria2CaseID.put(testCoc4.Id, case4.Id);

        //ADD FIELDS TO THOSE CRITERIAS (AND SAVE THEM IN EXPECTED MAP)
        Map<Id, Customer_Onboarding_Field__c> expectedCaseFieldMap = new Map<Id, Customer_Onboarding_Field__c>();
        Map<Id, Customer_Onboarding_Field__c> expectedProfileFieldMap = new Map<Id, Customer_Onboarding_Field__c>();
        Customer_Onboarding_Field__c expectedContactField = new Customer_Onboarding_Field__c();

        List<Customer_Onboarding_Field__c> fieldsToInsert = new List<Customer_Onboarding_Field__c>();
        Boolean notYetSet = true;
        for (Customer_Onboarding_Criteria__c coc : testCocs) {
            Customer_Onboarding_Field__c caseCof = GenerateTestData.createTestOnboardingField(coc.Id, 'Status', 'displayLabel', 'displayLabelFrench', 1, '', false);
            expectedCaseFieldMap.put(criteria2CaseID.get(coc.Id), caseCof);
            Customer_Onboarding_Field__c profileCof = GenerateTestData.createTestOnboardingField(coc.Id, 'Billing_City__c', 'displayLabel', 'displayLabelFrench', 2, 'Customer_Profile__c', false);
            expectedProfileFieldMap.put(criteria2CaseID.get(coc.Id), profileCof);
            Customer_Onboarding_Field__c contactCof = GenerateTestData.createTestOnboardingField(coc.Id, 'MailingCity', 'displayLabel', 'displayLabelFrench', 3, 'Contact', false);
            if (notYetSet)  {
                expectedContactField = (contactCof);
                notYetSet=false;
            }
            fieldsToInsert.add(caseCof);
            fieldsToInsert.add(profileCof);
            fieldsToInsert.add(contactCof);
        }
        insert fieldsToInsert;
            
        //CALL THE CONSTURCTOR WITH THE CASES
        Set<Id> expectedCaseIDs = Pluck.ids(casesToInsert);
        PageReference pageRef = Page.CustomerInformationForm;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.join(new List<Id>(expectedCaseIDs), ','));
        ApexPages.currentPage().getParameters().put('lang', 'French');
		system.debug('Start Test Before '+Limits.getQueries());
        Test.startTest();
            FormController testController = new FormController();
            //testController.submitForm();
        Test.stopTest();
        system.debug('Start Test after '+Limits.getQueries());
        //testController.getRecordName();
        string dummyInputTest = testController.dummyInput;

        //ASSERT THAT THE CASEWRAPPERS CONTAIN THE CASES AND HAVE THE RIGHT MODIFIABLEFIELDLIST
        System.assertEquals('French', testController.language, 'Language should be set to the value in the parameter');
        assertModifiableFieldsEquivalence(convertToMFields(new List<Customer_Onboarding_Field__c>{expectedContactField}, 'French'), testController.contactFields);
        System.assertEquals(4, testController.caseWrappers.size(), 'There should be exactly 4 Case Wrappers created for the 4 cases specified in the parameter');
        for (FormController.CaseContentWrapper ccw : testController.caseWrappers) {
            System.assert(expectedCaseIDs.contains(ccw.contentCase.Id), 'The Id of a content Case in a returned case wrapper was not in the list of ids passed as parameters');
            assertModifiableFieldsEquivalence(convertToMFields(new List<Customer_Onboarding_Field__c>{expectedProfileFieldMap.get(ccw.contentCase.Id)}, 'French'), ccw.modifiableProfileFields);
            assertModifiableFieldsEquivalence(convertToMFields(new List<Customer_Onboarding_Field__c>{expectedCaseFieldMap.get(ccw.contentCase.Id)}, 'French'), ccw.modifiableCaseFields);
        }
    }

    static testMethod void testGenerateFieldsToQueryLists() { 
        Map<Id, List<Customer_Onboarding_Field__c>> caseToFields = setupDummyCase2FieldsMap();

        // TEST OUT FUNCTION PASSING IN MAP
        Test.startTest();
            controller.generateFieldsToQueryLists(caseToFields);
        Test.stopTest();

        // ASSERT THE CLASS SETS
        System.assertEquals(expectedContactFields, controller.contactFieldApiNames, 'Only the unique Contact Field API Names should be stored in controller');
        System.assertEquals(expectedCaseFields, controller.caseFieldApiNames, 'Only the unique Case Field API Names should be stored in controller');
        System.assertEquals(expectedProfileFields, controller.profileFieldApiNames, 'Only the unique Profile Field API Names should be stored in controller');
        System.assertEquals(expectedContactMFields.size(), controller.contactFields.size(), 'Contact ModifiableFields in controller does not have the expected size');
        assertModifiableFieldsEquivalence(expectedContactMFields, controller.contactFields);
    }

    static testMethod void testQueryForCasesProfilesAndContact() {
        Set<String> testCaseFields = new Set<String>{'Status', 'Service_Order_Number__c', 'Priority', 'Subject'};
        Set<String> testProfileFields = new Set<String>{'Billing_City__c', 'Billing_Address__c'};
        Set<String> testContactFields = new Set<String>{'MailingCity', 'FirstName', 'LastName'};

        List<Case> testCases = TestingUtils.createCases(10, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').property('Status').assign('Closed').property('Service_Order_Number__c').assign('Test Comment')
                                                .property('Priority').assign('High').property('Subject').assign('Test Subject');
        List<Customer_Profile__c> testCPs = new List<Customer_Profile__c>();
        for (Integer i=0; i<4; i++) {
            Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, false);
            cp.Billing_City__c = 'Banglore';
            cp.Billing_Address__c = '1 Main St.';
            testCPs.add(cp);
        }
        UnitTest.addData(testCPs).tag('Profiles');
        UnitTest.get('Profiles').insertAll();

        testContact.MailingCity = 'Boston';
        testContact.FirstName = 'Bart';
        testContact.LastName = 'Simpson';
        update testContact;

        UnitTest.get('Cases').property('Customer_Profile__c').assignFrom('Profiles');
        UnitTest.get('Cases').insertAll();
        
        // CREATE CONTROLLER WITH CASES
        controller.cases = UnitTest.get('Cases').getList();
        controller.caseFieldApiNames = testCaseFields;
        controller.profileFieldApiNames = testProfileFields;
        controller.contactFieldApiNames = testContactFields;

        // TEST OUT FUNCTION PASSING IN MAP
        Test.startTest();
            controller.queryForCasesProfilesAndContact(new List<Id>(Pluck.ids(testCases)));
        Test.stopTest();

        UnitTest.analyze('Cases').assertEquivalence(controller.cases, 'The ids of the cases requeried for in the controller were not equal to the expected value');
        System.assertEquals(Pluck.ids(testCPs), Pluck.ids(controller.profiles), 'The ids of the profiles requeried for in the controller were not equal to the expected value');
        System.assertEquals(testContact.Id, controller.contactForCases.Id, 'The id of the contact requeried for in the controller was not equal to the expected value');
        for (Case actualCase : controller.cases)
            for (String field : controller.caseFieldApiNames)
                System.assertEquals(UnitTest.analyze('Cases').selectByID(actualCase.Id).getPropertyValue(field), actualCase.get(field), 'We expect to have access to the case fields in fieldset');
        for (Customer_Profile__c actualProfile : controller.profiles)
            for (String field : controller.profileFieldApiNames)
                System.assertEquals(UnitTest.analyze('Profiles').selectByID(actualProfile.Id).getPropertyValue(field), actualProfile.get(field), 'We expect to have access to the profile fields in fieldset');
        for (String field : controller.contactFieldApiNames)
            System.assertEquals(testContact.get(field), controller.contactForCases.get(field), 'We expect to have access to the contact fields in fieldset');
    }

    static testMethod void testQueryForCasesProfilesAndContactInvalidFieldError() {
        Set<String> testCaseFields = new Set<String>{'Status', 'Service_Order_Number__c', 'Priority', 'Subject'};
        Set<String> testProfileFields = new Set<String>{'Billing_City__c', 'NOTAREALFIELD'};
        Set<String> testContactFields = new Set<String>{'MailingCity', 'FirstName', 'LastName'};

        List<Case> testCases = TestingUtils.createCases(10, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').property('Status').assign('Closed').property('Service_Order_Number__c').assign('Test Comment')
                                                .property('Priority').assign('High').property('Subject').assign('Test Subject');
        List<Customer_Profile__c> testCPs = new List<Customer_Profile__c>();
        for (Integer i=0; i<4; i++) {
            Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, false);
            cp.Billing_City__c = 'Banglore';
            cp.Billing_Address__c = '1 Main St.';
            testCPs.add(cp);
        }
        UnitTest.addData(testCPs).tag('Profiles');
        UnitTest.get('Profiles').insertAll();

        testContact.MailingCity = 'Boston';
        testContact.FirstName = 'Bart';
        testContact.LastName = 'Simpson';
        update testContact;

        UnitTest.get('Cases').property('Customer_Profile__c').assignFrom('Profiles');
        UnitTest.get('Cases').insertAll();
        
        // CREATE CONTROLLER WITH CASES
        controller.cases = UnitTest.get('Cases').getList();
        controller.caseFieldApiNames = testCaseFields;
        controller.profileFieldApiNames = testProfileFields;
        controller.contactFieldApiNames = testContactFields;

        // TEST OUT FUNCTION PASSING IN MAP
        Test.startTest();
            controller.queryForCasesProfilesAndContact(new List<Id>(Pluck.ids(testCases)));
        Test.stopTest();

        System.assert(TestingUtils.pageMessageContains(FormController.INVALID_FIELD), 'There should be an error message about requeried field being an invalid field');
    }

    static testMethod void testBuildCaseWrappers() {
        Map<Id, List<Customer_Onboarding_Field__c>> caseToFields = setupDummyCase2FieldsMap();

        List<Customer_Profile__c> testCPs = new List<Customer_Profile__c>();
        for (Integer i=0; i<10; i++) {
            Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, false);
            testCPs.add(cp);
        }

        UnitTest.addData(testCPs).tag('Profiles');
        UnitTest.get('Profiles').dummyInsert();

        UnitTest.get('Cases').property('Customer_Profile__c').assignFrom('Profiles')
                             .property('Welcome_Packet_Sent_Date__c').assign(Date.today())
                             .property('Customer_Info_Form_Submitted_Date__c').assign(null)
                             .property('Initial_Supply_Order_Date__c').assign(null)
                             .property('Service_Order_Date__c').assign(null);

        Test.startTest();
            List<FormController.CaseContentWrapper> actualCCWs = controller.buildCaseWrappers((List<Case>)UnitTest.get('Cases').getList(), caseToFields, 
                                                                    new Map<Id, Customer_Profile__c>((List<Customer_Profile__c>)UnitTest.get('Profiles').getList()));
        Test.stopTest();

        System.assertEquals(UnitTest.get('Cases').getList().size(), actualCCWs.size(), 'A case wrapper should be created for every single case passed in');
        for (FormController.CaseContentWrapper ccw : actualCCWs) {
            System.assert(UnitTest.analyze('Cases').hasID(ccw.contentCase.Id), 'The ID of this case wrapper\'s content case was not found in the expected set of Case IDs');
            Id expectedProfileId = (Id) UnitTest.analyze('Cases').selectByID(ccw.contentCase.Id).getPropertyValue('Customer_Profile__c');
            System.assertEquals(expectedProfileId, ccw.contentProfile.Id, 'The expected profile Id for this case wrapper was not copied over correctly');
            List<FormController.ModifiableField> expectedCaseMFields;
            List<FormController.ModifiableField> expectedProfileMFields;
            if (UnitTest.analyze('Cases With All Fields').hasID(ccw.contentCase.Id)) {
                expectedCaseMFields = tagToExpectedCaseMFields.get('Cases With All Fields');
                expectedProfileMFields = tagToExpectedProfileMFields.get('Cases With All Fields');
            } else if (UnitTest.analyze('Cases With Only Case Fields').hasID(ccw.contentCase.Id)) {
                expectedCaseMFields = tagToExpectedCaseMFields.get('Cases With Only Case Fields');
                expectedProfileMFields = tagToExpectedProfileMFields.get('Cases With Only Case Fields');
            } else if (UnitTest.analyze('Cases With Only Profile Fields').hasID(ccw.contentCase.Id)) {
                expectedCaseMFields = tagToExpectedCaseMFields.get('Cases With Only Profile Fields');
                expectedProfileMFields = tagToExpectedProfileMFields.get('Cases With Only Profile Fields');
            } else if (UnitTest.analyze('Cases With Only Contact Fields').hasID(ccw.contentCase.Id)) {
                expectedCaseMFields = tagToExpectedCaseMFields.get('Cases With Only Contact Fields');
                expectedProfileMFields = tagToExpectedProfileMFields.get('Cases With Only Contact Fields');
            } else if (UnitTest.analyze('Cases With No Fields').hasID(ccw.contentCase.Id)) {
                expectedCaseMFields = tagToExpectedCaseMFields.get('Cases With No Fields');
                expectedProfileMFields = tagToExpectedProfileMFields.get('Cases With No Fields');
            } else System.assert(false, 'The wrapper\'s case id should be in one of these test groups');

            assertModifiableFieldsEquivalence(expectedCaseMFields, ccw.modifiableCaseFields);
            assertModifiableFieldsEquivalence(expectedProfileMFields, ccw.modifiableProfileFields);

            System.assertEquals(true, ccw.editAccess, 
                'All cases should have edit access since all the determinig fields are correctly set to null');
        }   
    }

    static testMethod void testBuildCaseWrappersSameProfiles() {
        Customer_Profile__c cp = TestingUtils.createCustomerProfile(testOpp.Id, null, false);
        TestingUtils.dummyInsert(new List<Customer_Profile__c>{cp});
        List<Case> testCases = TestingUtils.createCases(4, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').property('Customer_Profile__c').assign(cp.Id)
                                                .property('Welcome_Packet_Sent_Date__c').assign(Date.today());
        UnitTest.get('Cases').dummyInsert();

        Customer_Onboarding_Field__c caseCof1 = GenerateTestData.createTestOnboardingField(null, 'test1', 'displayLabel1', 1, 'Customer_Profile__c', false);
        Customer_Onboarding_Field__c caseCof2 = GenerateTestData.createTestOnboardingField(null, 'test2', 'displayLabel2', 2, 'Customer_Profile__c', false);
        Customer_Onboarding_Field__c caseCof3 = GenerateTestData.createTestOnboardingField(null, 'test3', 'displayLabel3', 3, 'Customer_Profile__c', false);
        Customer_Onboarding_Field__c caseCof4 = GenerateTestData.createTestOnboardingField(null, 'test1', 'displayLabel1', 1, 'Customer_Profile__c', false);
        List<Customer_Onboarding_Field__c> allCOFs = new List<Customer_Onboarding_Field__c>{caseCof1,caseCof2,caseCof3,caseCof4};
        List<Customer_Onboarding_Field__c> expectedCOFs = new List<Customer_Onboarding_Field__c>{caseCof1,caseCof2,caseCof3};

        Map<Id, List<Customer_Onboarding_Field__c>> caseToFields = 
            new Map<Id, List<Customer_Onboarding_Field__c>>{ testCases[0].Id => new List<Customer_Onboarding_Field__c>{caseCof1},
                                                             testCases[1].Id => new List<Customer_Onboarding_Field__c>{caseCof2},
                                                             testCases[2].Id => new List<Customer_Onboarding_Field__c>{caseCof3},
                                                             testCases[3].Id => new List<Customer_Onboarding_Field__c>{caseCof4} };

        Test.startTest();
            List<FormController.CaseContentWrapper> actualCCWs = controller.buildCaseWrappers((List<Case>)UnitTest.get('Cases').getList(), caseToFields, 
                                                                    new Map<Id, Customer_Profile__c>{cp.Id=>cp});
        Test.stopTest();

        System.assertEquals(UnitTest.get('Cases').getList().size(), actualCCWs.size(), 'A case wrapper should be created for every single case passed in');
        for (FormController.CaseContentWrapper ccw : actualCCWs) {
            if (ccw.contentCase.Id == testCases[0].Id) {
                System.assertEquals(true, ccw.displayCustomerProfile, 'As the first Profile found, the first case wrapper should have this flag set to true');
                System.assertEquals(expectedCOFs.size(), ccw.modifiableProfileFields.size(), 'There should be only 3 modifiableProfileFields combined');
                assertModifiableFieldsEquivalence(convertToMFields(expectedCOFs), ccw.modifiableProfileFields);
            } else {
                System.assertEquals(false, ccw.displayCustomerProfile, 'As not the first Profile found, the subsequent case wrapper should have this flag set to false');
                System.assertEquals(1,ccw.modifiableProfileFields.size(), 'The modifiableProfileFields list should have 1 field for profiles already found');
            }
        }
        /*
            CW1: { display: true, modifiableProfileFields={caseCof1,caseCof2,caseCof3,caseCof4} }
            CW2: { display: false, modifiableProfileFields={caseCof2} }
            CW3: { display: false, modifiableProfileFields={caseCof3} }
            CW4: { display: false, modifiableProfileFields={caseCof4} }
        */
    }

    static testMethod void testUpdateContact() {
        String CONTACT_CITY_FIELD = 'MailingCity';
        String CONTACT_CITY_LABEL = 'City';
        String CONTACT_FNAME_FIELD = 'FirstName';
        String CONTACT_FNAME_LABEL = 'First Name';
        String CONTACT_LNAME_FIELD = 'LastName';
        String CONTACT_LNAME_LABEL = 'Last Name';
        String OLD_CITY = 'Atlanta';
        String NEW_CITY = 'Boston';
        String OLD_FNAME = 'Bart';
        String NEW_FNAME = 'Peter';
        String OLD_LNAME = 'Simpson';
        String NEW_LNAME = 'Griffin';

        Set<String> testContactFields = new Set<String>{CONTACT_CITY_FIELD, CONTACT_FNAME_FIELD, CONTACT_LNAME_FIELD};
        List<FormController.ModifiableField> testContactMFields = new List<FormController.ModifiableField>();
        testContactMFields.add(new FormController.ModifiableField(CONTACT_CITY_FIELD, CONTACT_CITY_LABEL, 'Contact'));
        testContactMFields.add(new FormController.ModifiableField(CONTACT_FNAME_FIELD, CONTACT_FNAME_LABEL, 'Contact'));
        testContactMFields.add(new FormController.ModifiableField(CONTACT_LNAME_FIELD, CONTACT_LNAME_LABEL, 'Contact'));
        testContactMFields[0].newCheckbox = true;
        testContactMFields[1].newCheckbox = true;
        // LAST NAME FIELD NOT CHECKED

        testContact.put(CONTACT_CITY_FIELD, OLD_CITY);
        testContact.put(CONTACT_FNAME_FIELD, OLD_FNAME);
        testContact.put(CONTACT_LNAME_FIELD, OLD_LNAME);

        Contact testPlaceholderContact = TestingUtils.createContact(testAct.Id, false);
        testPlaceholderContact.put(CONTACT_CITY_FIELD, NEW_CITY);
        testPlaceholderContact.put(CONTACT_FNAME_FIELD, NEW_FNAME);
        testPlaceholderContact.put(CONTACT_LNAME_FIELD, NEW_LNAME);

        controller.contactForCases = testContact;
        controller.placeholderContact = testPlaceholderContact;
        controller.contactFields = testContactMFields;
        controller.cases = TestingUtils.createCases(10, testOpp, testContact, true);

        Test.startTest();
            controller.updateContact();
        Test.stopTest();

        Contact actualContact = [SELECT Id, MailingCity, FirstName, LastName FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(NEW_CITY, actualContact.get(CONTACT_CITY_FIELD), 
            'Contact\'s MailingCity field should be updated to the new value because checkbox is checked');
        System.assertEquals(NEW_FNAME, actualContact.get(CONTACT_FNAME_FIELD), 
            'Contact\'s FirstName field should be updated to the new value because checkbox is checked');
        System.assertEquals(OLD_LNAME, actualContact.get(CONTACT_LNAME_FIELD), 
            'Contact\'s LastName field should be updated to the new value because checkbox is NOT checked');
        for (Case c : controller.cases) 
            System.assertNotEquals(null, c.Customer_Onboarding_Contact_Change__c, 
                'Changing a contact field should timestamp the Customer_Onboarding_Contact_Change__c field on all cases');
    }

    static testMethod void testUpdateCases() {
        String STATUS_FIELD = 'Status';
        String PRIORITY_FIELD = 'Priority';
        String SUBJECT_FIELD = 'Subject';
        String OLD_STATUS = 'Closed';
        String NEW_STATUS = 'Open';
        String OLD_PRIORITY = 'High';
        String NEW_PRIORITY = 'Low';
        String OLD_SUBJECT = 'Test Subject';
        String NEW_SUBJECT = 'Test Subject 2';

        List<Case> testCases = TestingUtils.createCases(10, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').property(STATUS_FIELD).assign(OLD_STATUS)
                                                .property(PRIORITY_FIELD).assign(OLD_PRIORITY)
                                                .property(SUBJECT_FIELD).assign(OLD_SUBJECT);
        UnitTest.get('Cases').insertAll();

        List<FormController.ModifiableField> testCaseMFields = new List<FormController.ModifiableField>();
        testCaseMFields.add(new FormController.ModifiableField(STATUS_FIELD, STATUS_FIELD, ''));
        testCaseMFields.add(new FormController.ModifiableField(PRIORITY_FIELD, PRIORITY_FIELD, ''));
        testCaseMFields.add(new FormController.ModifiableField(SUBJECT_FIELD, SUBJECT_FIELD, ''));
        testCaseMFields[0].newCheckbox = true;
        testCaseMFields[1].newCheckbox = true;

        List<FormController.CaseContentWrapper> testCWs = new List<FormController.CaseContentWrapper>();
        Set<Id> casesWithComments = new Set<Id>();
        Integer i = 0;
        for (Case c : (List<Case>)UnitTest.get('Cases').getList()) {
            FormController.CaseContentWrapper testCW = 
                new FormController.CaseContentWrapper(c, new List<Customer_Onboarding_Field__c>(), null, false, '');
            testCW.modifiableCaseFields = testCaseMFields;
            testCW.placeholderCase.put(STATUS_FIELD, NEW_STATUS);
            testCW.placeholderCase.put(PRIORITY_FIELD, NEW_PRIORITY);
            testCW.placeholderCase.put(SUBJECT_FIELD, NEW_SUBJECT);
            testCW.initialStateOfComments = 'Question1?\nQuestion2?\n';
            if (Math.mod(i, 3)==0) {
                testCW.comments = 'Question1? Yes\nQuestion2? No\n';
                casesWithComments.add(c.Id);
            } else if (Math.mod(i, 3)==1) {
                testCW.comments = 'Question1?\nQuestion2?\n';
            } else {
                testCW.comments = '';
            }
            i++;
            testCWs.add(testCW);
        }
        //

        //
        controller.caseWrappers = testCWs;

        Test.startTest();
          //controller.updateCases();
        Test.stopTest();

       /* List<Case> actualCases = [SELECT Id, Status, Priority, Subject, 
                                        Customer_Info_Form_Submitted_Date__c, Customer_Onboarding_Field_Change__c,
                                        (Select CommentBody, ParentId FROM CaseComments) FROM Case WHERE Id in :testCases];

        System.assertEquals(testCases.size(), actualCases.size(), 'Checking size of inserted cases to queried cases');
        for (Case actualCase : actualCases) {
            System.assertNotEquals(null, actualCase.Customer_Info_Form_Submitted_Date__c, 
                'Case\'s Customer_Info_Form_Submitted_Date__c field should be updated to a not null date');
            System.assertNotEquals(null, actualCase.Customer_Onboarding_Field_Change__c, 
                'Case\'s Customer_Onboarding_Field_Change__c field should be updated to a not null date');
            System.assertEquals(NEW_STATUS, actualCase.get(STATUS_FIELD), 
                'Case\'s Status field should be updated to the new value because checkbox is checked');
            System.assertEquals(NEW_PRIORITY, actualCase.get(PRIORITY_FIELD), 
                'Case\'s Priority field should be updated to the new value because checkbox is checked');
            System.assertEquals(OLD_SUBJECT, actualCase.get(SUBJECT_FIELD), 
                'Case\'s Subject field should not be updated to the new value because checkbox is NOT checked');
            if (casesWithComments.contains(actualCase.Id)) {
                System.assert(!actualCase.CaseComments.isEmpty(), 'There should be exactly one case comment for each case');
                System.assertEquals(actualCase.Id, actualCase.CaseComments[0].ParentId, 
                    'There should be a new Case Comment looking up to this case');
                System.assertEquals('Question1? Yes\nQuestion2? No', actualCase.CaseComments[0].CommentBody, 
                    'There should be a new Case Comment looking up to this case');
            } else {
                System.assert(actualCase.CaseComments.isEmpty(), 'There should be no case comment for this case');  
            }
        }*/
    }

    static testMethod void testUpdateProfiles() {
        String DEPARTMENT_FIELD = 'Billing_Department__c';
        String ADDRESS_FIELD = 'Billing_Address__c';
        String CITY_FIELD = 'Billing_City__c';
        String OLD_DEPARTMENT = 'Biology';
        String NEW_DEPARTMENT = 'Chemistry';
        String OLD_ADDRESS = '1 main st';
        String NEW_ADDRESS = '2 elm st';
        String OLD_CITY = 'Atlanta';
        String NEW_CITY = 'Boston';
        List<Case> testCases = TestingUtils.createCases(10, testOpp, testContact, true);
        List<Customer_Profile__c> testProfiles = new List<Customer_Profile__c>();
        for (Integer i=0; i<10; i++) 
            testProfiles.add(TestingUtils.createCustomerProfile(testOpp.Id, null, false));

        UnitTest.addData(testProfiles).tag('Profiles').property(DEPARTMENT_FIELD).assign(OLD_DEPARTMENT)
                                                      .property(ADDRESS_FIELD).assign(OLD_ADDRESS)
                                                      .property(CITY_FIELD).assign(OLD_CITY);
        UnitTest.get('Profiles').insertAll();

        List<FormController.ModifiableField> testProfileMFields = new List<FormController.ModifiableField>();
        testProfileMFields.add(new FormController.ModifiableField(DEPARTMENT_FIELD, DEPARTMENT_FIELD, 'Customer_Profile__c'));
        testProfileMFields.add(new FormController.ModifiableField(ADDRESS_FIELD, ADDRESS_FIELD, 'Customer_Profile__c'));
        testProfileMFields.add(new FormController.ModifiableField(CITY_FIELD, CITY_FIELD, 'Customer_Profile__c'));
        testProfileMFields[0].newCheckbox = true;
        testProfileMFields[1].newCheckbox = true;

        List<FormController.CaseContentWrapper> testCWs = new List<FormController.CaseContentWrapper>();
        Integer i=0;
        for (Customer_Profile__c cp : (List<Customer_Profile__c>)UnitTest.get('Profiles').getList()) {
            FormController.CaseContentWrapper testCW = 
                new FormController.CaseContentWrapper(testCases[i++], new List<Customer_Onboarding_Field__c>(), cp, false, '');
            testCW.modifiableProfileFields = testProfileMFields;
            testCW.placeholderProfile.put(DEPARTMENT_FIELD, NEW_DEPARTMENT);
            testCW.placeholderProfile.put(ADDRESS_FIELD, NEW_ADDRESS);
            testCW.placeholderProfile.put(CITY_FIELD, NEW_CITY);
            testCWs.add(testCW);
        }

        controller.caseWrappers = testCWs;

        Test.startTest();
            controller.updateProfiles();
            controller.updateCases();
        Test.stopTest();

        List<Customer_Profile__c> actualProfiles = [SELECT Id, Billing_Department__c, Billing_Address__c, Billing_City__c FROM Customer_Profile__c WHERE Id in :testProfiles];

        System.assertEquals(testProfiles.size(), actualProfiles.size(), 'Checking size of inserted profiles to queried profiles');
        for (Customer_Profile__c actualProfile : actualProfiles) {
            System.assertEquals(NEW_DEPARTMENT, actualProfile.get(DEPARTMENT_FIELD), 
                'Profile\'s DEPARTMENT field should be updated to the new value because checkbox is checked');
            System.assertEquals(NEW_ADDRESS, actualProfile.get(ADDRESS_FIELD), 
                'Profile\'s ADDRESS field should be updated to the new value because checkbox is checked');
            System.assertEquals(OLD_CITY, actualProfile.get(CITY_FIELD), 
                'Profile\'s CITY field should not be updated to the new value because checkbox is NOT checked');
        }
    }

    static testMethod void testUpdateProfiles2() {
        String DEPARTMENT_FIELD = 'Billing_Department__c';
        String ADDRESS_FIELD = 'Billing_Address__c';
        String CITY_FIELD = 'Billing_City__c';
        String OLD_DEPARTMENT = 'Biology';
        String NEW_DEPARTMENT = 'Chemistry';
        String OLD_ADDRESS = '1 main st';
        String NEW_ADDRESS = '2 elm st';
        String OLD_CITY = 'Atlanta';
        String NEW_CITY = 'Boston';

        List<Customer_Profile__c> testProfiles = new List<Customer_Profile__c>();
        for (Integer i=0; i<10; i++) 
            testProfiles.add(TestingUtils.createCustomerProfile(testOpp.Id, null, false));
        List<Case> testCases = TestingUtils.createCases(10, testOpp, testContact, true);
        UnitTest.addData(testCases).tag('Cases');

        UnitTest.addData(testProfiles).tag('Profiles').property(DEPARTMENT_FIELD).assign(OLD_DEPARTMENT)
                                                      .property(ADDRESS_FIELD).assign(OLD_ADDRESS)
                                                      .property(CITY_FIELD).assign(OLD_CITY);
        UnitTest.get('Profiles').insertAll();
        UnitTest.get('Profiles').divide(2).part('Profiles With Changed Values').part('Profiles Unchanged');

        List<FormController.ModifiableField> testProfileMFields = new List<FormController.ModifiableField>();
        testProfileMFields.add(new FormController.ModifiableField(DEPARTMENT_FIELD, DEPARTMENT_FIELD, 'Customer_Profile__c'));
        testProfileMFields.add(new FormController.ModifiableField(ADDRESS_FIELD, ADDRESS_FIELD, 'Customer_Profile__c'));
        testProfileMFields.add(new FormController.ModifiableField(CITY_FIELD, CITY_FIELD, 'Customer_Profile__c'));
        testProfileMFields[0].newCheckbox = true;
        testProfileMFields[1].newCheckbox = true;
        testProfileMFields[2].newCheckbox = true;

        Set<Id> casesWithProfileChangeStamp = new Set<Id>();
        List<FormController.CaseContentWrapper> testCWs = new List<FormController.CaseContentWrapper>();
        Integer i=0;
        for (Customer_Profile__c cp : (List<Customer_Profile__c>)UnitTest.get('Profiles With Changed Values').getList()) {
            casesWithProfileChangeStamp.add(testCases[i].Id);
            FormController.CaseContentWrapper testCW = 
                new FormController.CaseContentWrapper(testCases[i++], new List<Customer_Onboarding_Field__c>(), cp, false, '');
            testCW.modifiableProfileFields = testProfileMFields;
            testCW.placeholderProfile.put(DEPARTMENT_FIELD, NEW_DEPARTMENT);
            testCW.placeholderProfile.put(ADDRESS_FIELD, NEW_ADDRESS);
            testCW.placeholderProfile.put(CITY_FIELD, NEW_CITY);
            testCWs.add(testCW);
        }

        List<FormController.ModifiableField> testProfileMFields2 = new List<FormController.ModifiableField>();
        testProfileMFields2.add(new FormController.ModifiableField(DEPARTMENT_FIELD, DEPARTMENT_FIELD, 'Customer_Profile__c'));
        testProfileMFields2.add(new FormController.ModifiableField(ADDRESS_FIELD, ADDRESS_FIELD, 'Customer_Profile__c'));
        testProfileMFields2.add(new FormController.ModifiableField(CITY_FIELD, CITY_FIELD, 'Customer_Profile__c'));
        testProfileMFields2[0].newCheckbox = false;
        testProfileMFields2[1].newCheckbox = false;
        testProfileMFields2[2].newCheckbox = false;

        Set<Id> casesWithoutProfileChangeStamp = new Set<Id>();
        for (Customer_Profile__c cp : (List<Customer_Profile__c>)UnitTest.get('Profiles Unchanged').getList()) {
            casesWithoutProfileChangeStamp.add(testCases[i].Id);
            FormController.CaseContentWrapper testCW = 
                new FormController.CaseContentWrapper(testCases[i++], new List<Customer_Onboarding_Field__c>(), cp, false, '');
            testCW.modifiableProfileFields = testProfileMFields2;
            testCW.placeholderProfile.put(DEPARTMENT_FIELD, NEW_DEPARTMENT);
            testCW.placeholderProfile.put(ADDRESS_FIELD, NEW_ADDRESS);
            testCW.placeholderProfile.put(CITY_FIELD, NEW_CITY);
            testCWs.add(testCW);
        }

        controller.caseWrappers = testCWs;

        Test.startTest();
            controller.updateProfiles();
        Test.stopTest();

        List<Customer_Profile__c> actualProfiles = [SELECT Id, Billing_Department__c, Billing_Address__c, Billing_City__c FROM Customer_Profile__c WHERE Id in :testProfiles];

        System.assertEquals(testProfiles.size(), actualProfiles.size(), 'Checking size of inserted profiles to queried profiles');
        for (Customer_Profile__c actualProfile : actualProfiles) {
            if (UnitTest.analyze('Profiles With Changed Values').hasID(actualProfile.Id)) {
                System.assertEquals(NEW_DEPARTMENT, actualProfile.get(DEPARTMENT_FIELD), 
                    'Profile\'s DEPARTMENT field should be updated to the new value because checkbox is checked');
                System.assertEquals(NEW_ADDRESS, actualProfile.get(ADDRESS_FIELD), 
                    'Profile\'s ADDRESS field should be updated to the new value because checkbox is checked');
                System.assertEquals(NEW_CITY, actualProfile.get(CITY_FIELD), 
                    'Profile\'s CITY field should not be updated to the new value because checkbox is NOT checked');
            } else {
                System.assertEquals(OLD_DEPARTMENT, actualProfile.get(DEPARTMENT_FIELD), 
                    'Profile\'s DEPARTMENT field should not be updated to the new value because checkbox is NOT checked');
                System.assertEquals(OLD_ADDRESS, actualProfile.get(ADDRESS_FIELD), 
                    'Profile\'s ADDRESS field should not be updated to the new value because checkbox is NOT checked');
                System.assertEquals(OLD_CITY, actualProfile.get(CITY_FIELD), 
                    'Profile\'s CITY field should not be updated to the new value because checkbox is NOT checked');
            }
        }

        List<Case> actualCases = [SELECT Id, Customer_Onboarding_CP_Field_Change__c FROM Case WHERE Id in :testCases];
        System.assertEquals(10, actualCases.size(), 'no new cases should have been created in this process of updating profiles');
        for (Case c : actualCases) {
            if (casesWithProfileChangeStamp.contains(c.Id)) {
                System.assertNotEquals(null, c.Customer_Onboarding_CP_Field_Change__c, 
                    'Since the fields on this cases related profile were modified, the Customer_Onboarding_CP_Field_Change__c field should be stamped with the current DateTime');
            } else {
                System.assertEquals(null, c.Customer_Onboarding_CP_Field_Change__c, 
                    'Since the fields on this cases related profile were not modified, the Customer_Onboarding_CP_Field_Change__c field should remain null');
            }
        }
    }
    
    static testMethod void testCaseContentWrapperConstructor() {
        Case testCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        Customer_Profile__c testCp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        TestingUtils.dummyInsert(new List<Customer_Profile__c>{testCp});
        testCase.Customer_Profile__c = testCp.Id;
        TestingUtils.dummyInsert(new List<Case>{testCase});
        Boolean DUPLICATE = false;
        String LANGUAGE = 'USEnglish';

        List<Customer_Onboarding_Field__c> testFields = new List<Customer_Onboarding_Field__c>();
        List<Customer_Onboarding_Field__c> expected_caseFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', '', false);
        List<Customer_Onboarding_Field__c> expected_cpFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', 'Customer_Profile__c', false);
        List<Customer_Onboarding_Field__c> expected_commentFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', 'CaseComment', false);
        testFields.addAll(expected_caseFields);
        testFields.addAll(expected_cpFields);
        testFields.addAll(expected_commentFields);
        TestingUtils.dummyInsert(testFields);

        Test.startTest();
            FormController.CaseContentWrapper actual_ccw = 
                new FormController.CaseContentWrapper(testCase, testFields, testCp, DUPLICATE, LANGUAGE);
        Test.stopTest();

        System.assertEquals(testCase, actual_ccw.contentCase, 'Case passed in through constructor should be assigned to Case object of wrapper');
        System.assertEquals(testCp, actual_ccw.contentProfile, 'Profile passed in through constructor should be assigned to Profile object of wrapper');
        String EXPECTED_INITALCOMMENT = 'testLabel0?\ntestLabel1?\ntestLabel2?\ntestLabel3?\ntestLabel4?\n';
        System.assertEquals(EXPECTED_INITALCOMMENT, actual_ccw.initialStateOfComments, 'InitialStateOfComments should be generated by concatenating displayLabels of CaseCOmment fields with question marks');
        System.assertEquals(EXPECTED_INITALCOMMENT, actual_ccw.comments, 'comments should be same as initalComments to begin with');
        assertModifiableFieldsEquivalence(convertToMFields(expected_caseFields), actual_ccw.modifiableCaseFields);
        assertModifiableFieldsEquivalence(convertToMFields(expected_cpFields), actual_ccw.modifiableProfileFields);
    }

    static testMethod void testCaseContentWrapperConstructor_noCommentFields() {
        Case testCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        Customer_Profile__c testCp = TestingUtils.createCustomerProfile(testOpp.Id, null, true);
        TestingUtils.dummyInsert(new List<Customer_Profile__c>{testCp});
        testCase.Customer_Profile__c = testCp.Id;
        TestingUtils.dummyInsert(new List<Case>{testCase});
        Boolean DUPLICATE = false;
        String LANGUAGE = 'USEnglish';

        List<Customer_Onboarding_Field__c> testFields = new List<Customer_Onboarding_Field__c>();
        List<Customer_Onboarding_Field__c> expected_caseFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', '', false);
        List<Customer_Onboarding_Field__c> expected_cpFields = GenerateTestData.createTestOnboardingFields(5, null, 'testName', 'testLabel', 'Customer_Profile__c', false);
        testFields.addAll(expected_caseFields);
        testFields.addAll(expected_cpFields);
        TestingUtils.dummyInsert(testFields);

        Test.startTest();
            FormController.CaseContentWrapper actual_ccw = 
                new FormController.CaseContentWrapper(testCase, testFields, testCp, DUPLICATE, LANGUAGE);
        Test.stopTest();

        System.assertEquals('', actual_ccw.initialStateOfComments, 'InitialStateOfComments should be empty since there are no comment fields');
        System.assertEquals('', actual_ccw.comments, 'comments should be same as initalComments to begin with');
    }
}