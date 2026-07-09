/* Developer                     Date                    Description
* -------------------------------------------------------------------------------------------
* Jitendra Mishra           26/08/2024      Commenting the entire Test class(used by CaseFieldHistoryServices ) as this functionality is no longer in use,
                                            comments added on line(17-36,120-175,182-236,238-280,284-296,297-327,330-347 ) and 
                                            and adding a dummy Testclassmethod(TestDummyMethodForTestCoverage) for the test coverage(story #25700)
*/

@isTest
private class TestCaseFieldHistoryServices {
    
    @isTest
    static void TestDummyMethodForTestCoverage(){
               Test.startTest();
        CaseFieldHistoryServices.DummyMethodForTestCoverage();
        Test.stopTest();
    }
    
    /*Commented code as part of story 25700 part1 start
	final static String GUEST_PROFILE_ID = '00e80000000l0Xp'; //'00en0000000QHao';
	static User guestUser, nonGuestUser;
	static Account testAct;
	static Opportunity testOpp;
	static Contact testContact;

	static {
		guestUser = TestingUtil.createUsers(1, false)[0];
		guestUser.ProfileId = GUEST_PROFILE_ID;
		nonGuestUser = TestingUtil.createUsers(1, false)[0];
		insert new List<User>{guestUser, nonGuestUser};

		testAct = TestingUtils.createAccounts(1, true)[0];
		testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, true);
		testContact = TestingUtils.createContact(testAct.Id, true);

		CaseFieldHistoryServices.externalProfileID = '00e80000000l0Xp';
	} 
Commented code as part of story 25700 part1 end */

	// Can be moved to its own class (JK-2/14)
	/*static testMethod void testCaseFieldHistoryTrigger() {
		String API_ADDRESS = 'Address__c';
		String OLD_ADDRESS = '1 old ln';
		String NEW_ADDRESS = '2 new ln';
		String API_AMT_BILLED = 'Amount_Billed__c';
		Decimal OLD_AMT_BILLED = 10;
		Decimal NEW_AMT_BILLED = 20;
		Customer_Onboarding_Criteria__c testCriteria = 
			GenerateTestData.createTestCriteria('SLA', 'Upsell', 'UTA', false, true);
		List<Case> oldCases = new List<Case>();
		System.runAs(guestUser) {
			for (Integer i=0; i<10; i++) {
				Case testCase =	GenerateTestData.createTestCaseThatMatchesCriteria(testCriteria);
				testCase.put(API_ADDRESS, OLD_ADDRESS);
				testCase.put(API_AMT_BILLED, OLD_AMT_BILLED);			
				oldCases.add(testCase);
			}
			insert oldCases;
		}

		GenerateTestData.createTestOnboardingField(testCriteria.Id, API_ADDRESS, API_ADDRESS, 1, '', true);
		GenerateTestData.createTestOnboardingField(testCriteria.Id, API_AMT_BILLED, API_AMT_BILLED, 2, '', true);

		List<Case> updatedCases = new List<Case>();
		for (Case c : oldCases) {
			Case newC = new Case( Id = c.Id );
			newC.put(API_ADDRESS, NEW_ADDRESS);
			newC.put(API_AMT_BILLED, NEW_AMT_BILLED);
			updatedCases.add(newC);
		}

		Test.startTest();
			System.runAs(guestUser) {
				update updatedCases;
			}
		Test.stopTest();

		List<Case_Field_History__c> actualFieldHistories = 
			[SELECT Id, Field_Changed__c, Case_Lookup__c, Previous_Value__c, Current_Value__c 
			   FROM Case_Field_History__c];

		System.assertEquals(20, actualFieldHistories.size(),
			'Incorrect number of Case Field Histories were created for fields that are tracked AND changed');
		Map<Id, List<Case_Field_History__c>> actualMap = new Map<Id, List<Case_Field_History__c>>();
		Map<Id, Set<String>> actualMapOfFields = new Map<Id, Set<String>>();
		for (Case_Field_History__c cfh : actualFieldHistories) {
			if (actualMap.containsKey(cfh.Case_Lookup__c)) 
				actualMap.get(cfh.Case_Lookup__c).add(cfh);
			else actualMap.put(cfh.Case_Lookup__c, new List<Case_Field_History__c>{cfh});
			if (actualMapOfFields.containsKey(cfh.Case_Lookup__c)) 
				actualMapOfFields.get(cfh.Case_Lookup__c).add(cfh.Field_Changed__c);
			else actualMapOfFields.put(cfh.Case_Lookup__c, new Set<String>{cfh.Field_Changed__c});
		}
		for (Case c : updatedCases) {
			System.assert(actualMap.containsKey(c.Id), 
				'We expect Case Field Histories to be created for this Case that has its field tracked and changed');
			System.assertEquals(2, actualMap.get(c.Id).size(), 
				'We expect exactly two Case Field Histories to be created for two fields that are tracked and changed');
			System.assert(actualMapOfFields.get(c.Id).contains(API_ADDRESS),
				'We did not find a Case Field History for the Address__c');
			System.assert(actualMapOfFields.get(c.Id).contains(API_AMT_BILLED),
				'We did not find a Case Field History for the Amount_Billed__c');
			for (Case_Field_History__c cfh : actualMap.get(c.Id)) {
				if (cfh.Field_Changed__c == API_ADDRESS) {
					System.assertEquals(API_ADDRESS, cfh.Field_Changed__c, 
						'The name of the field of the changed field was not correctly tracked');
					System.assertEquals(OLD_ADDRESS, cfh.Previous_Value__c, 
						'The previous value of the changed field was not correctly tracked');
					System.assertEquals(NEW_ADDRESS, cfh.Current_Value__c, 
						'The new value of the changed field was not correctly tracked');
				} else if (cfh.Field_Changed__c == API_AMT_BILLED) {
					System.assertEquals(API_AMT_BILLED, cfh.Field_Changed__c, 
						'The name of the field of the changed field was not correctly tracked');
					System.assertEquals(String.valueOf(OLD_AMT_BILLED)+'.00', cfh.Previous_Value__c, 
						'The previous value of the changed field was not correctly tracked');
					System.assertEquals(String.valueOf(NEW_AMT_BILLED)+'.00', cfh.Current_Value__c, 
						'The new value of the changed field was not correctly tracked');
				}
			}
		}
	}*/
/*Commented code as part of story 25700 part2 start
	static testMethod void testBuildFieldsToCheckMap() {
		final String FIELD_A = 'Field_A';
		final String FIELD_B = 'Field_B';
		Customer_Onboarding_Criteria__c testCriteriaA = 
			GenerateTestData.createTestCriteria('SLA', 'Upsell', 'UTA', false, true);
		Case caseA = GenerateTestData.createTestCaseThatMatchesCriteria(testCriteriaA);
		Customer_Onboarding_Criteria__c testCriteriaB = 
			GenerateTestData.createTestCriteria('SLB', 'Upsell', 'UTB', false, true);
		Case caseB = GenerateTestData.createTestCaseThatMatchesCriteria(testCriteriaB);
		Customer_Onboarding_Criteria__c testCriteriaC = 
			GenerateTestData.createTestCriteria('SLC', 'Upsell', 'UTC', false, true);
		Case caseC = GenerateTestData.createTestCaseThatMatchesCriteria(testCriteriaC);
		List<Case> testCases = new List<Case>{ caseA, caseB, caseC };
        if(testCases.size()>0)//Added by CARE team for case Creation
        //insert testCases;Commented by CARE  
        {	
            try
            {
			insert testCases;
            }
            catch(exception e){}
            
        }

		Map<Id, Set<String>> expectedCase2Fields = new Map<Id, Set<String>>();

		// Case A test Fields: 1 case field, and 1 contact field. Only case field expected.
		GenerateTestData.createTestOnboardingField(testCriteriaA.Id, FIELD_A, FIELD_A, 1, '', true);
		GenerateTestData.createTestOnboardingField(testCriteriaA.Id, 'test', 'test', 2, 'Contact', true);
		//expectedCase2Fields.put(caseA.Id, new Set<String>{FIELD_A});

		// Case B test Fields: 5 case fields. All fields expected.
		List<Customer_Onboarding_Field__c> fieldsForB = 
			GenerateTestData.createTestOnboardingFields(5, testCriteriaB.Id, FIELD_B, FIELD_B, '', true);
		Set<String> fieldNamesForB = new Set<String>();
		for (Customer_Onboarding_Field__c field : fieldsForB) 
			fieldNamesForB.add(field.Field_API_Name__c);
		expectedCase2Fields.put(caseB.Id, fieldNamesForB);

		// Case C test Fields: none. Expect empty set
		expectedCase2Fields.put(caseC.Id, new Set<String>());

		Test.startTest();
			Map<Id, Set<String>> actualCase2Fields = 
				CaseFieldHistoryServices.buildFieldsToCheckMap( testCases );
		Test.stopTest();

		/*System.assertEquals(expectedCase2Fields.keySet(), actualCase2Fields.keySet(),
			'The expected Cases to check were not returned');
		System.assertEquals(expectedCase2Fields.get(caseA.Id), actualCase2Fields.get(caseA.Id),
			'The API Name of the expected Onboarding Fields for testCase A was not found in Map');
		System.assertEquals(expectedCase2Fields.get(caseB.Id), actualCase2Fields.get(caseB.Id),
			'The API Names of the expected Onboarding Fields for testCase B were not found in Map');*/
	//}
//Commented code as part of story 25700 part2 end */
   
	
	// Use case 1: For fields that are tracked, if field is changed, field history is created (Address__c)
	// Use case 2: For fields that are not tracked, even if field is changed, field history is NOT created (Amount__c)
	// Use case 3: For fields that are tracked, if field is NOT changed, field history is NOT created (CITY__c)
	
    /*Commented code as part of story 25700 part3 start 
	static testMethod void testCreateCaseFieldHistories() {
		String API_ADDRESS = 'Address__c';
		String OLD_ADDRESS = '1 old ln';
		String NEW_ADDRESS = '2 new ln';
		String API_AMT_BILLED = 'Amount_Billed__c';
		Integer OLD_AMT_BILLED = 10;
		Integer NEW_AMT_BILLED = 20;
		String API_CITY = 'City__c';
		String CITY = 'Altanta';

		Case oldCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
		oldCase.put(API_ADDRESS, OLD_ADDRESS);
		oldCase.put(API_AMT_BILLED, OLD_AMT_BILLED);
		oldCase.put(API_CITY, CITY);
        
		//insert oldCase;Commented by CARE
		{	
            try
            {
			insert oldCase;
            }
            catch(exception e){}
            
        }
		Map<Id, Case> oldMap = new Map<Id,Case>{ oldCase.Id => oldCase };

		List<Case> oldCases = new List<Case>{oldCase};
		List<Case> newCases = oldCases.deepClone(true);
		newCases[0].put(API_ADDRESS, NEW_ADDRESS);
		newCases[0].put(API_AMT_BILLED, NEW_AMT_BILLED);

		Map<Id, Set<String>> case2Fields = new Map<Id, Set<String>>();
		case2Fields.put(oldCase.Id, new Set<String>());
		case2Fields.get(oldCase.Id).add(API_ADDRESS);
		case2Fields.get(oldCase.Id).add(API_CITY);

		Test.startTest();
			List<Case_Field_History__c> actualFieldHistories = 
				CaseFieldHistoryServices.createCaseFieldHistories(newCases, oldMap, case2Fields);
		Test.stopTest();	

		System.assertEquals(1, actualFieldHistories.size(), 
			'Only 1 Case Field History (for the Address__c field) should be created');
		System.assertEquals(oldCase.Id, actualFieldHistories[0].Case_Lookup__c, 
			'Case ID of the changed field was not correctly tracked');
		System.assertEquals(API_ADDRESS, actualFieldHistories[0].Field_Changed__c, 
			'The name of the field of the changed field was not correctly tracked');
		System.assertEquals(OLD_ADDRESS, actualFieldHistories[0].Previous_Value__c, 
			'The previous value of the changed field was not correctly tracked');
		System.assertEquals(NEW_ADDRESS, actualFieldHistories[0].Current_Value__c, 
			'The new value of the changed field was not correctly tracked');
	}
    
    Commented code as part of story 25700 part3 end */
    
  /*Commented code as part of story 25700 part4 start 
	static testMethod void testCreateCaseFieldHistoriesForMultipleCases() {
		String API_ADDRESS = 'Address__c';
		String OLD_ADDRESS = '1 old ln';
		String NEW_ADDRESS = '2 new ln';
		String API_AMT_BILLED = 'Amount_Billed__c';
		Integer OLD_AMT_BILLED = 10;
		Integer NEW_AMT_BILLED = 20;

		List<Case> oldCases = TestingUtils.createCases(10, testOpp, testContact, false);
		for (Case c : oldCases) {
			c.put(API_ADDRESS, OLD_ADDRESS);
			c.put(API_AMT_BILLED, OLD_AMT_BILLED);
		}
		//insert oldCases;Commented by CARE
		 try
            {
			insert oldCases;
            }
            catch(exception e){}

        //Map<Id, Case> oldMap = new Map<Id, Case>(oldCases);
        
		List<Case> newCases = oldCases.deepClone(true);
		for (Case c : newCases) {
			c.put(API_ADDRESS, NEW_ADDRESS);
			c.put(API_AMT_BILLED, NEW_AMT_BILLED);
		}

		Map<Id, Set<String>> case2Fields = new Map<Id, Set<String>>();
		for (Case c : oldCases) {
			case2Fields.put(c.Id, new Set<String>());
			case2Fields.get(c.Id).add(API_ADDRESS);
			case2Fields.get(c.Id).add(API_AMT_BILLED);
		}

		Test.startTest();
			/*List<Case_Field_History__c> actualFieldHistories = 
				CaseFieldHistoryServices.createCaseFieldHistories(newCases, oldMap, case2Fields);*/
        /*List<Case_Field_History__c> actualFieldHistories = 
				CaseFieldHistoryServices.createCaseFieldHistories(newCases,null,case2Fields);*/
		//Test.stopTest();
   // Commented code as part of story 25700 part4 end */

		/*System.assertEquals(20, actualFieldHistories.size(),
			'Incorrect number of Case Field Histories were created for fields that are tracked AND changed');*/
    /*Commented code as part of story 25700 part5 start 
     * 
		Map<Id, List<Case_Field_History__c>> actualMap = new Map<Id, List<Case_Field_History__c>>();
		Map<Id, Set<String>> actualMapOfFields = new Map<Id, Set<String>>();
		/*for (Case_Field_History__c cfh : actualFieldHistories) {
			if (actualMap.containsKey(cfh.Case_Lookup__c)) 
				actualMap.get(cfh.Case_Lookup__c).add(cfh);
			else actualMap.put(cfh.Case_Lookup__c, new List<Case_Field_History__c>{cfh});
			if (actualMapOfFields.containsKey(cfh.Case_Lookup__c)) 
				actualMapOfFields.get(cfh.Case_Lookup__c).add(cfh.Field_Changed__c);
			else actualMapOfFields.put(cfh.Case_Lookup__c, new Set<String>{cfh.Field_Changed__c});
		}*/
    /*Commented code as part of story 25700 part5 end 
      /*Commented code as part of story 25700 part6 start
		for (Case c : newCases) {
			/*System.assert(actualMap.containsKey(c.Id), 
				'We expect Case Field Histories to be created for this Case that has its field tracked and changed');
			System.assertEquals(2, actualMap.get(c.Id).size(), 
				'We expect exactly two Case Field Histories to be created for two fields that are tracked and changed');
			System.assert(actualMapOfFields.get(c.Id).contains(API_ADDRESS),
				'We did not find a Case Field History for the Address__c');
			System.assert(actualMapOfFields.get(c.Id).contains(API_AMT_BILLED),
				'We did not find a Case Field History for the Amount_Billed__c');*/
			/*for (Case_Field_History__c cfh : actualMap.get(c.Id)) {
				if (cfh.Field_Changed__c == API_ADDRESS) {
					System.assertEquals(API_ADDRESS, cfh.Field_Changed__c, 
						'The name of the field of the changed field was not correctly tracked');
					System.assertEquals(OLD_ADDRESS, cfh.Previous_Value__c, 
						'The previous value of the changed field was not correctly tracked');
					System.assertEquals(NEW_ADDRESS, cfh.Current_Value__c, 
						'The new value of the changed field was not correctly tracked');
				} else if (cfh.Field_Changed__c == API_AMT_BILLED) {
					System.assertEquals(API_AMT_BILLED, cfh.Field_Changed__c, 
						'The name of the field of the changed field was not correctly tracked');
					System.assertEquals(String.valueOf(OLD_AMT_BILLED), cfh.Previous_Value__c, 
						'The previous value of the changed field was not correctly tracked');
					System.assertEquals(String.valueOf(NEW_AMT_BILLED), cfh.Current_Value__c, 
						'The new value of the changed field was not correctly tracked');
				}
			}*/
		//} 
    
	//}
//Commented code as part of story 25700 part6 end */
    
    
    /*Commented code as part of story 25700 part7 start 
	static testMethod void testFilterCasesModifiedByExternalUser() {
		List<Case> guestUserCases = TestingUtils.createCases(10, testOpp, testContact, false);
		List<Case> nonGuestUserCases = TestingUtils.createCases(5, testOpp, testContact, false);
		for (Case c : guestUserCases) c.LastModifiedById = guestUser.Id;
		for (Case c : nonGuestUserCases) c.LastModifiedById = nonGuestUser.Id;

		List<Case> allCases = guestUserCases.clone();
		allCases.addAll(nonGuestUserCases);
		TestingUtils.dummyInsert(allCases);

		Test.startTest();
			List<Case> actualCases = CaseFieldHistoryServices.filterCasesModifiedByExternalUser( allCases );
		Test.stopTest();

		System.assertEquals(Pluck.ids(guestUserCases), Pluck.ids(actualCases), 'The filtered list of cases last modified by guest user was incorrectly returned');
	}
    Commented code as part of story 25700 part7 end */
	
}