@isTest
private class TestCustomerOnboardingCriteriaServices {
    
    static Account testAct;
    static Opportunity testOpp;
    static Opportunity testOppUpsell;
    static Contact testContact;
    static IM_Customer_Account__c testCA;

    static {
        System.runAs(TestingUtils.ADMIN_USER) {
            TestingUtils.setupCountryCustomSettings(true); 
            TestingUtils.setupOpportunitySecuritySettings(true);
            testAct = TestingUtils.createAccounts(1, true)[0];
            testCA = GenerateTestData.createCustomerAccount('','');
            testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, false);
            testOpp.Type = 'dt1'; // Used in most testMethods 
            testOppUpsell = TestingUtils.createOpportunity('testOppUpsell', testAct.Id, false);
            testOppUpsell.Type = 'Up-Sell/Lift'; // Used in most testMethods 
            testOppUpsell.IM_Up_Sell_Detail__c = 'detail';
            testOppUpsell.IM_Up_Sell_Quantity__c = 3;
            testOppUpsell.Upsell_Customer_ID__c = testCA.Id;
            testOppUpsell.IM_Unit_of_Measure__c = 'Cubic Ft';
            testOppUpsell.IM_Up_Sell_Sold_To__c = '1414141';
            //update testOppUpsell;
            //insert new List<Opportunity>{testOpp,testOppUpsell};
            testContact = TestingUtils.createContact(testAct.Id, true);
        }
    }
    /*
    *   Test Service Line: Shred
    *           Deal Type: Upsell Type,
              Upsell Type: Service Frequency,
    *      Supplies Order: w/ supplies
    */
    static testMethod void testGetOnboardingFieldsOfDealTypUpsell() {
        Customer_OnBoarding_Criteria__c cOC = GenerateTestData.createTestCriteria( 'Shred', 'Up-Sell/Lift', 'Service Frequency', true, true );
        List<Customer_Onboarding_Field__c> cofs = 
            GenerateTestData.createTestOnboardingFields(3, coc.Id, 'testAPI', 'test label', '', true);
        Test.startTest();
            List<Customer_Onboarding_Field__c> actualFields = CustomerOnboardingCriteriaServices.getOnboardingFields( 'Shred', 'Up-Sell/Lift', 'Service Frequency', true );
        Test.stopTest();

        System.assertEquals(Pluck.ids(cofs), Pluck.ids(actualFields), 'Expected fields to be returned are different from actual fields returned');
    }

    /*
    *   Test Service Line: Shred, RM, Accutrac, DB&R
    *           Deal Type: New Deal, Department Add, New Service Line
    *      Supplies Order: w/ supplies, w/o supplies
    */
    static testMethod void testGetOnboardingFieldsExceptUpsell() {
        List <String> serviceLines = new List<String>{ 'Shred', 'RM', 'Accutrac', 'DB&R' };
        List <String> dealTypes = new List<String>{ 'New Deal', 'Department Add', 'New Service Line' };
        List <Boolean> suppliesRequired = new List<Boolean>{ true, false };

        List <Customer_OnBoarding_Criteria__c> testCriterias = new List <Customer_OnBoarding_Criteria__c>();
        for ( String sl : serviceLines ) {
            for ( String dt : dealTypes ) {
                for ( Boolean sr : suppliesRequired ) {
                    Customer_OnBoarding_Criteria__c cOC = GenerateTestData.createTestCriteria( sl, dt, '', sr, false );
                    testCriterias.add(cOC);
                }
            }
        }
        insert testCriterias;

        Map<Id, List<Customer_Onboarding_Field__c>> expectedQuestionsPerCriteria = new Map<Id, List<Customer_Onboarding_Field__c>>();
        List<Customer_Onboarding_Field__c> testFields = new List<Customer_Onboarding_Field__c>();
        for ( Customer_OnBoarding_Criteria__c coc : testCriterias ) {
            List<Customer_Onboarding_Field__c> cofs = GenerateTestData.createTestOnboardingFields(3, coc.Id, 'testAPI', 'test label', '', false);
            testFields.addAll(cofs);
            expectedQuestionsPerCriteria.put(coc.Id, cofs);
        }
        insert testFields;

        Map<Id, List<Customer_Onboarding_Field__c>> actualQuestionsPerCriteria = new Map<Id, List<Customer_Onboarding_Field__c>>();
        Test.startTest();
            for ( Customer_OnBoarding_Criteria__c coc : testCriterias ) {
                List<Customer_Onboarding_Field__c> actualFields = 
                    CustomerOnboardingCriteriaServices.getOnboardingFields( coc.Service_Line__c, coc.Deal_Type__c, 
                                                                            '', coc.Supplies_Order_Required__c );
                actualQuestionsPerCriteria.put(coc.Id, actualFields);
            }
        Test.stopTest();

        for ( Id cocID : expectedQuestionsPerCriteria.keySet() ) {
            System.assert(actualQuestionsPerCriteria.containsKey(cocID), 'No fields for the expected criteria were returned from the getOnboardingFields function');
            List<Customer_Onboarding_Field__c> expectedFields = expectedQuestionsPerCriteria.get(cocID);
            List<Customer_Onboarding_Field__c> actualFields = actualQuestionsPerCriteria.get(cocID);
            System.assertEquals(Pluck.ids(expectedFields), Pluck.ids(actualFields), 'Expected fields to be returned are different from actual fields returned');
            for ( Integer i=0; i<3; i++ ) {
                System.assertEquals(i, actualFields[i].Sort_Order__c, 'List of fields should be returned in Ascending order of Sort_Order__c field');
            }
        }
    }

    static testMethod void testCriteriaFoundWithNoFields() {
        Customer_OnBoarding_Criteria__c cOC = GenerateTestData.createTestCriteria( 'sl', 'dt', '', true, true );

        Test.startTest();
            List<Customer_Onboarding_Field__c> actualFields = CustomerOnboardingCriteriaServices.getOnboardingFields( 'sl', 'dt', '', true );
        Test.stopTest();

        System.assert(actualFields.isEmpty(), 'No fields should exist for this criteria');
    }

    static testMethod void testNoCriteriaFound() {
        Test.startTest();
            List<Customer_Onboarding_Field__c> actualFields = CustomerOnboardingCriteriaServices.getOnboardingFields( 'sl', 'dt', '', true );
        Test.stopTest();

        System.assert(actualFields.isEmpty(), 'Since no criteria was found, we should expect an empty list');        
    }

    

    static testMethod void testHashGeneratorInvariant() {
        // IF A CASE MEETS A CRITERIA, GENERATE HASH SHOULD RETURN THE SAME STRING
        Customer_Onboarding_Criteria__c testCoc = GenerateTestData.createTestCriteria('sl1', 'Upsell', 'ut1', true, false);
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl1', 'dt2', '', false, false);
        Case testCaseUpsell = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc); 
        Case testCaseNotUpsellButHasUpsellType = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); 
        testCaseNotUpsellButHasUpsellType.NCSP_Upsell_Type__c = 'utfake';

        Test.startTest();
            String hashFromCriteria1 = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCoc);
            String hashFromCase1 = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCaseUpsell);
            String hashFromCriteria2 = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCoc2);
            String hashFromCase2 = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCaseNotUpsellButHasUpsellType);
        Test.stopTest();

        System.assertEquals(hashFromCriteria1, hashFromCase1, 'IF A CASE MEETS A CRITERIA, GENERATE HASH SHOULD RETURN THE SAME STRING');
        System.assertEquals(hashFromCriteria2, hashFromCase2, 'IF A CASE MEETS A CRITERIA, GENERATE HASH SHOULD RETURN THE SAME STRING');
    }

    static testMethod void testGenerateCriteriaValueHash() {
        Customer_Onboarding_Criteria__c testCoc = GenerateTestData.createTestCriteria('sl1', 'dt1', 'ut1', true, false);
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl1', 'dt1', 'ut1', false, false);
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('', 'dt1', '', true, false);
        Case testCaseGood = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc); String expectedHashGood = 'SL1.DT1..YES';
        Case testCaseBad = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2); String expectedHashBad = 'SL1...NO';
        Case testCaseBadEmpty = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3); String expectedHashBadEmpty = '...YES';

        Test.startTest();
            String actualHashGood = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCaseGood);
            String actualHashBad = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCaseBad);
            String actualHashBadEmpty = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCaseBadEmpty);
        Test.stopTest();

        System.assertEquals(expectedHashGood, actualHashGood, 'Generated hash should be the service line, deal type, upsell type and supplies order required concatenated with "."\'s');
        //System.assertEquals(expectedHashBad, actualHashBad, 'Generated hash should be the service line, deal type, upsell type and supplies order required concatenated with "."\'s');
        //System.assertEquals(expectedHashBadEmpty, actualHashBadEmpty, 'Generated hash should be the service line, deal type, upsell type and supplies order required concatenated with "."\'s');
    }

    static testMethod void testGenerateCriteriaValueHashFromCriteria() {
        Customer_Onboarding_Criteria__c testCocGood = GenerateTestData.createTestCriteria('sl1', 'dt1', 'ut1', true, false);
        Customer_Onboarding_Criteria__c testCocBad = GenerateTestData.createTestCriteria('sl1', '', 'ut1', false, false);
        Customer_Onboarding_Criteria__c testCocBadEmpty = GenerateTestData.createTestCriteria('', '', '', true, false);
        String expectedHashGood = 'SL1.DT1.UT1.YES';
        String expectedHashBad = 'SL1..UT1.NO';
        String expectedHashBadEmpty = '...YES';

        Test.startTest();
            String actualHashGood = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCocGood);
            String actualHashBad = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCocBad);
            String actualHashBadEmpty = CustomerOnboardingCriteriaServices.generateCriteriaValueHash(testCocBadEmpty);
        Test.stopTest();

        System.assertEquals(expectedHashGood, actualHashGood, 'Generated hash should be the service line, deal type, upsell type and supplies order required concatenated with "."\'s');
        System.assertEquals(expectedHashBad, actualHashBad, 'Generated hash should be the service line, deal type, upsell type and supplies order required concatenated with "."\'s');
        System.assertEquals(expectedHashBadEmpty, actualHashBadEmpty, 'Generated hash should be the service line, deal type, upsell type and supplies order required concatenated with "."\'s');
    }

    static testMethod void testGenerateClauseFromHash() {
        String goodHashKey = 'SL1.DT1.UT2.YES'; String expectedClauseGood = '(Service_Line__c=\'SL1\' AND Deal_Type__c=\'DT1\' AND Supplies_Order_Required__c=true)';
        String goodHashKeyUpsell = 'SL1.Upsell.UT2.NO'; String expectedClauseGoodUpsell = '(Service_Line__c=\'SL1\' AND Deal_Type__c=\'Upsell\' AND Upsell_Type__c=\'UT2\' AND Supplies_Order_Required__c=false)';
        String badHashKey1 = 'SL1...YES'; 
        String badHashKey2 = '...NO'; String expectedClauseBad = '';

        Test.startTest();
            String actualClauseGood = CustomerOnboardingCriteriaServices.generateClauseFromHash(goodHashKey);
            String actualClauseGoodUpsell = CustomerOnboardingCriteriaServices.generateClauseFromHash(goodHashKeyUpsell);
            String actualClauseBad1 = CustomerOnboardingCriteriaServices.generateClauseFromHash(badHashKey1);
            String actualClauseBad2 = CustomerOnboardingCriteriaServices.generateClauseFromHash(badHashKey2);
        Test.stopTest();

        System.assertEquals(expectedClauseGood, actualClauseGood, 'Generated Clause should split hash, create conditions and concatenate with ANDs');
        System.assertEquals(actualClauseGoodUpsell, expectedClauseGoodUpsell, 'Generated Clause should split hash, create conditions and concatenate with ANDs. If Deal Type is Upsell, then Upsell Type should be included.');
        System.assertEquals(actualClauseBad1, expectedClauseBad, 'Generated Clause should return empty string for bad hashkey inputs');
        System.assertEquals(actualClauseBad2, expectedClauseBad, 'Generated Clause should return empty string for bad hashkey inputs');
    }

    static testMethod void testGetMapOfCriteria2CaseIDsAll() {
        // 10 cases, 3, 3, 4 in map
        Customer_Onboarding_Criteria__c testCoc = GenerateTestData.createTestCriteria('sl1', 'dt1', '', true, true);
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'Upsell', 'ut1', false, true);
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', true, true);
        Set<Id> cocIds = new Set<Id>{testCoc.Id, testCoc2.Id, testCoc3.Id};
        testOpp.Type = 'dt1';
        List<Case> testCasesMatchingCoc = new List<Case>();
        for (Integer i=0;i<3;i++) 
            testCasesMatchingCoc.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc, testContact, testOpp));
        List<Case> testCasesMatchingCoc2 = new List<Case>();
        for (Integer i=0;i<3;i++) 
            testCasesMatchingCoc2.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2, testContact, testOppUpsell));
        List<Case> testCasesMatchingCoc3 = new List<Case>();
        for (Integer i=0;i<4;i++) 
            testCasesMatchingCoc3.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3, testContact, testOpp));

        UnitTest.addData(testCasesMatchingCoc).tag('Cases Matching Criteria1');
        UnitTest.addData(testCasesMatchingCoc2).tag('Cases Matching Criteria2');
        UnitTest.addData(testCasesMatchingCoc3).tag('Cases Matching Criteria3');
        UnitTest.get(Case.SObjectType).insertAll();
        
        Test.startTest();
            Map<Id, List<Id>> criteria2CaseIds = CustomerOnboardingCriteriaServices.getMapOfCriteria2CaseIDs(UnitTest.get(Case.SObjectType).getList());
        Test.stopTest();

        System.assertEquals(cocIds, criteria2CaseIds.keySet(), 'Keyset of the returned map was not the expected set of three criteria ids');
        for (Id id : criteria2CaseIds.keySet()) {
            if (id == testCoc.Id) 
                System.assertEquals(UnitTest.getIds('Cases Matching Criteria1'), new Set<Id>(criteria2CaseIds.get(id)), 'This criteria\'s expected case ids were not returned');
            if (id == testCoc2.Id) 
                System.assertEquals(UnitTest.getIds('Cases Matching Criteria2'), new Set<Id>(criteria2CaseIds.get(id)), 'This criteria\'s expected case ids were not returned');
            if (id == testCoc3.Id) 
                System.assertEquals(UnitTest.getIds('Cases Matching Criteria3'), new Set<Id>(criteria2CaseIds.get(id)), 'This criteria\'s expected case ids were not returned');
        }
    }

    static testMethod void testGetMapOfCriteria2CaseIDsHalf() {
        // 10 cases, 5 in map, 3 incomplete criteria value, 2 no matching criteria
        Customer_Onboarding_Criteria__c testCoc = GenerateTestData.createTestCriteria('sl1', 'dt1', '', true, true);
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', '', 'ut1', false, false); // Used to create cases with incomplete criteria values
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', true, false); // Used to create cases with no matching critera - notice not inserted
        Set<Id> cocIds = new Set<Id>{testCoc.Id};
        testOpp.Type = 'dt1';
        List<Case> testCasesMatchingCoc = new List<Case>();
        for (Integer i=0;i<5;i++) 
            testCasesMatchingCoc.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc, testContact, testOpp));
        List<Case> testCasesIncomplete = new List<Case>();
        for (Integer i=0;i<3;i++) 
            testCasesIncomplete.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2, testContact, testOpp));
        List<Case> testCasesNoMatch = new List<Case>();
        for (Integer i=0;i<2;i++) 
            testCasesNoMatch.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3, testContact, testOpp));

        UnitTest.addData(testCasesMatchingCoc).tag('Cases Matching Criteria1');
        UnitTest.addData(testCasesIncomplete).tag('Cases That Have Incomplete Criteria Values');
        UnitTest.addData(testCasesNoMatch).tag('Cases Not Matching Any Criteria');
        UnitTest.get(Case.SObjectType).insertAll();

        Test.startTest();
            Map<Id, List<Id>> criteria2CaseIds = CustomerOnboardingCriteriaServices.getMapOfCriteria2CaseIDs(UnitTest.get(Case.SObjectType).getList());
        Test.stopTest();

        System.assertEquals(cocIds, criteria2CaseIds.keySet(), 'Keyset of the returned map should only have 1 criteria Id');
        System.assertEquals(UnitTest.getIds('Cases Matching Criteria1'), new Set<Id>(criteria2CaseIds.get(testCoc.Id)), 'This criteria\'s 5 expected case ids were not returned');
    }

    static testMethod void testGetMapOfCriteria2CaseIDsNone() {
        // 10 cases, 5 incomplete criteria value, 5 no matching criteria
        Customer_Onboarding_Criteria__c testCoc = GenerateTestData.createTestCriteria('sl2', '', 'ut1', false, false); // Used to create cases with incomplete criteria values
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', true, false); // Used to create cases with no matching critera - notice not inserted

        List<Case> testCasesIncomplete = new List<Case>();
        for (Integer i=0;i<5;i++) 
            testCasesIncomplete.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc, testContact, testOpp));
        List<Case> testCasesNoMatch = new List<Case>();
        for (Integer i=0;i<5;i++) 
            testCasesNoMatch.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2, testContact, testOpp));

        UnitTest.addData(testCasesIncomplete).tag('Cases That Have Incomplete Criteria Values');
        UnitTest.addData(testCasesNoMatch).tag('Cases Not Matching Any Criteria');
        UnitTest.get(Case.SObjectType).insertAll();

        Test.startTest();
            Map<Id, List<Id>> criteria2CaseIds = CustomerOnboardingCriteriaServices.getMapOfCriteria2CaseIDs(UnitTest.get(Case.SObjectType).getList());
        Test.stopTest();

        System.assert(criteria2CaseIds.isEmpty(), 'Returned map should be empty because all cases inputted are invalid');
    }

    static testMethod void testGetOnboardingFieldSets() {
        // 10 cases, all good. 5 case returns with 20 Onboarding fields, 5 with 1.
        
        Test.startTest();
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); // Used to create cases with incomplete criteria values
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); // Used to create cases with incomplete criteria values
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); // Used to create cases with incomplete criteria values
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); // Used to create cases with incomplete criteria values
        Customer_Onboarding_Criteria__c testCoc5 = GenerateTestData.createTestCriteria('sl5', 'dt1', '', false, false); // Used to create cases with incomplete criteria values
        Customer_Onboarding_Criteria__c testCoc6 = GenerateTestData.createTestCriteria('sl6', 'dt1', '', false, false); // Used to create cases with incomplete criteria values
        
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4, testCoc5 ,testCoc6};
        
        insert testCocs;
        
        List<Customer_Onboarding_Field__c> custOnBoardingFields1 = GenerateTestData.createTestOnboardingFields(20, testCoc1.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields2 = GenerateTestData.createTestOnboardingFields(20, testCoc2.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields3 = GenerateTestData.createTestOnboardingFields(20, testCoc3.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields4 = GenerateTestData.createTestOnboardingFields(20, testCoc4.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields5 = GenerateTestData.createTestOnboardingFields(20, testCoc5.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields6 = GenerateTestData.createTestOnboardingFields(1, testCoc6.Id, 'apiName', 'displayLabel', '', false);
        
        List<Customer_Onboarding_Field__c> allCustOnBoardingFields = new List<Customer_Onboarding_Field__c>();
        
        allCustOnBoardingFields.addAll(custOnBoardingFields1);
        allCustOnBoardingFields.addAll(custOnBoardingFields2);
        allCustOnBoardingFields.addAll(custOnBoardingFields3);
        allCustOnBoardingFields.addAll(custOnBoardingFields4);
        allCustOnBoardingFields.addAll(custOnBoardingFields5);
        allCustOnBoardingFields.addAll(custOnBoardingFields6);
        						
        insert allCustOnBoardingFields;
        
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1, testContact, testOpp);
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2, testContact, testOpp);
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3, testContact, testOpp);
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4, testContact, testOpp);
        Case case5 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc5, testContact, testOpp);
        
        List<Case> casesWithSameCriteria = new List<Case>();
        for (Integer i=0;i<5;i++){
        	casesWithSameCriteria.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCoc6));
        } 
        
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4, case5};
        casesToInsert.addAll(casesWithSameCriteria);
        
        insert casesToInsert;
        
        
            Map<Id, List<Customer_Onboarding_Field__c>> actualCase2Fields = CustomerOnboardingCriteriaServices.getOnboardingFieldSets(casesToInsert);
        Test.stopTest();
        
        Set<Id> expectedCaseIds = Pluck.ids(casesToInsert);
        
        System.assertEquals(expectedCaseIds, actualCase2Fields.keySet(), 'Ids of the returned Cases should match the Ids of the cases passed in');
        
        Set<id> casesWithSameCriteriaIds = Pluck.ids(casesWithSameCriteria);
        for(Id caseId: actualCase2Fields.keySet()){
        	if(caseId == case1.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields1), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case2.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields2), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case3.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields3), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case4.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields4), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case5.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields5), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	
        	if(casesWithSameCriteriaIds.contains(caseId)){
        		system.assertEquals(Pluck.ids(custOnBoardingFields6), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the casesWithSameCriteria');
        	}
        }
    }

    static testMethod void testGetOnboardingFieldSetsCasesWithNoCriteria() {
        // 10 cases, 5 good, 5 case no match. still expact map of size 10 but with 5 values as empty lists
        
        Test.startTest();
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc5 = GenerateTestData.createTestCriteria('sl5', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCocNotInserted = GenerateTestData.createTestCriteria('sl6', 'dt1', '', false, false); 
        
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4, testCoc5};
        
        insert testCocs;
        
        List<Customer_Onboarding_Field__c> custOnBoardingFields1 = GenerateTestData.createTestOnboardingFields(20, testCoc1.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields2 = GenerateTestData.createTestOnboardingFields(20, testCoc2.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields3 = GenerateTestData.createTestOnboardingFields(20, testCoc3.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields4 = GenerateTestData.createTestOnboardingFields(20, testCoc4.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields5 = GenerateTestData.createTestOnboardingFields(20, testCoc5.Id, 'apiName', 'displayLabel', '', false);
        
        List<Customer_Onboarding_Field__c> allCustOnBoardingFields = new List<Customer_Onboarding_Field__c>();
        
        allCustOnBoardingFields.addAll(custOnBoardingFields1);
        allCustOnBoardingFields.addAll(custOnBoardingFields2);
        allCustOnBoardingFields.addAll(custOnBoardingFields3);
        allCustOnBoardingFields.addAll(custOnBoardingFields4);
        allCustOnBoardingFields.addAll(custOnBoardingFields5);
        						
        insert allCustOnBoardingFields;
        
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1, testContact, testOpp);
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2, testContact, testOpp);
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3, testContact, testOpp);
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4, testContact, testOpp);
        Case case5 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc5, testContact, testOpp);
        
        List<Case> casesWithNoCriteria = new List<Case>();
        for (Integer i=0;i<5;i++){
        	casesWithNoCriteria.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCocNotInserted));
        } 
        
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4, case5};
        casesToInsert.addAll(casesWithNoCriteria);
        
        insert casesToInsert;
        
        
            Map<Id, List<Customer_Onboarding_Field__c>> actualCase2Fields = CustomerOnboardingCriteriaServices.getOnboardingFieldSets(casesToInsert);
        Test.stopTest();
        
        Set<Id> expectedCaseIds = Pluck.ids(casesToInsert);
        
        System.assertEquals(expectedCaseIds, actualCase2Fields.keySet(), 'Ids of the returned Cases should match the Ids of the cases passed in');
        
        Set<id> casesWithNoCriteriaIds = Pluck.ids(casesWithNoCriteria);
        for(Id caseId: actualCase2Fields.keySet()){
        	if(caseId == case1.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields1), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case2.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields2), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case3.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields3), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case4.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields4), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case5.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields5), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	
        	if(casesWithNoCriteriaIds.contains(caseId)){
        		system.assertEquals(new List<Customer_Onboarding_Field__c>(), actualCase2Fields.get(caseId), 'onboarding fields must be associated with the casesWithSameCriteria');
        	}
        }
    }

    static testMethod void testGetOnboardingFieldSetsCasesWithCriteriaButNoFields() {
        // 10 cases, 5 good, 5 case with match but no fields. still expact map of size 10 but with 5 values as empty lists
        
         Test.startTest();
        Customer_Onboarding_Criteria__c testCoc1 = GenerateTestData.createTestCriteria('sl1', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc2 = GenerateTestData.createTestCriteria('sl2', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc3 = GenerateTestData.createTestCriteria('sl3', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc4 = GenerateTestData.createTestCriteria('sl4', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCoc5 = GenerateTestData.createTestCriteria('sl5', 'dt1', '', false, false); 
        Customer_Onboarding_Criteria__c testCocNoFields = GenerateTestData.createTestCriteria('sl6', 'dt1', '', false, false);
        
        List<Customer_Onboarding_Criteria__c> testCocs = new List<Customer_Onboarding_Criteria__c>{testCoc1, testCoc2, testCoc3, testCoc4, testCoc5, testCocNoFields};
        
        insert testCocs;
        
        List<Customer_Onboarding_Field__c> custOnBoardingFields1 = GenerateTestData.createTestOnboardingFields(20, testCoc1.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields2 = GenerateTestData.createTestOnboardingFields(20, testCoc2.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields3 = GenerateTestData.createTestOnboardingFields(20, testCoc3.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields4 = GenerateTestData.createTestOnboardingFields(20, testCoc4.Id, 'apiName', 'displayLabel', '', false);
        List<Customer_Onboarding_Field__c> custOnBoardingFields5 = GenerateTestData.createTestOnboardingFields(20, testCoc5.Id, 'apiName', 'displayLabel', '', false);
        
        List<Customer_Onboarding_Field__c> allCustOnBoardingFields = new List<Customer_Onboarding_Field__c>();
        
        allCustOnBoardingFields.addAll(custOnBoardingFields1);
        allCustOnBoardingFields.addAll(custOnBoardingFields2);
        allCustOnBoardingFields.addAll(custOnBoardingFields3);
        allCustOnBoardingFields.addAll(custOnBoardingFields4);
        allCustOnBoardingFields.addAll(custOnBoardingFields5);
        						
        insert allCustOnBoardingFields;
        
        Case case1 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc1, testContact, testOpp);
        Case case2 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc2, testContact, testOpp);
        Case case3 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc3, testContact, testOpp);
        Case case4 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc4, testContact, testOpp);
        Case case5 = GenerateTestData.createTestCaseThatMatchesCriteria(testCoc5, testContact, testOpp);
        
        List<Case> casesWithNoFields = new List<Case>();
        for (Integer i=0;i<5;i++){
        	casesWithNoFields.add(GenerateTestData.createTestCaseThatMatchesCriteria(testCocNoFields));
        } 
        
        List<Case> casesToInsert = new List<Case>{case1, case2,case3, case4, case5};
        casesToInsert.addAll(casesWithNoFields);
        
        insert casesToInsert;
        
        
            Map<Id, List<Customer_Onboarding_Field__c>> actualCase2Fields = CustomerOnboardingCriteriaServices.getOnboardingFieldSets(casesToInsert);
        Test.stopTest();
        
        Set<Id> expectedCaseIds = Pluck.ids(casesToInsert);
        
        System.assertEquals(expectedCaseIds, actualCase2Fields.keySet(), 'Ids of the returned Cases should match the Ids of the cases passed in');
        
        Set<id> casesWithNoFieldsIds = Pluck.ids(casesWithNoFields);
        for(Id caseId: actualCase2Fields.keySet()){
        	if(caseId == case1.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields1), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case2.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields2), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case3.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields3), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case4.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields4), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	if(caseId == case5.Id)
        		System.assertEquals(Pluck.ids(custOnBoardingFields5), Pluck.ids(actualCase2Fields.get(caseId)), 'onboarding fields must be associated with the right case');
        	
        	if(casesWithNoFieldsIds.contains(caseId)){
        		system.assertEquals(new List<Customer_Onboarding_Field__c>(), actualCase2Fields.get(caseId), 'onboarding fields must be associated with the casesWithSameCriteria');
        	}
        }
    }
}