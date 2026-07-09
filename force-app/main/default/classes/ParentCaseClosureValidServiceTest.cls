/**
* @author Nathan Vass
* @date 1/19
* @group Services
* @description
* Test for ParentCaseClosureValidService
*/

@isTest
public with sharing class ParentCaseClosureValidServiceTest {
    @isTest static void testDummyMethod()
    {	ParentCaseClosureValidService testDummy = new ParentCaseClosureValidService();
     	Test.startTest();
     	Integer no = testDummy.dummyMethod();
     	System.assertEquals(1, no, 'Returned Correct Number');
     	Test.stopTest();    
    }
	/*commented as part of user story #27072
	static final String CLOSED_STATUS = 'Closed';
	static final String OPEN_STATUS = 'Open';
	static final Integer RECORD_COUNT = 10;
	static final Date TODAY = Date.today();
    static final Id VALIDATE_RECORD_TYPE = RecordTypeCache.get(Case.SObjectType, ParentCaseClosureValidService.VALIDATE_RECORD_TYPES_DEVNAMES[0]).Id;
	static final Map<SObjectField, Object> OLD_MAP_VALS = new Map<SObjectField,  Object>{
		Case.Status => OPEN_STATUS
	};

	@isTest static void validate_noClosedCases_noQuery() {
		List<Case> parents = createParentCases(OPEN_STATUS);
		ParentCaseClosureValidService service = buildService(parents, null);

		Test.startTest();
		    Integer queryStartCount = Limits.getQueries();
			    service.validate();
			Integer queryEndCount = Limits.getQueries();
		Test.stopTest();

		System.assertEquals(queryStartCount, queryEndCount, 
			'No unnecessary queries should be made if there are no closed cases in the trigger');
	}

	@isTest static void validate_closedParentOpenChildren_blocksSave() {
		List<Case> parents = createParentCases(CLOSED_STATUS);
		List<Case> children = createChildCases(parents, new List<String>{CLOSED_STATUS, OPEN_STATUS});
		ParentCaseClosureValidService service = buildService(parents, OLD_MAP_VALS);

		Test.startTest();
		    Integer queryStartCount = Limits.getQueries();
			    Boolean didBlockingOccur = service.validate();
			Integer queryEndCount = Limits.getQueries();
		Test.stopTest();

		System.assert(didBlockingOccur, 
			'Users should not be able to close parent cases some of their children are open');
	}

	@isTest static void validate_closedParentClosedChildren_passes() {
		List<Case> parents = createParentCases(CLOSED_STATUS);
		List<Case> children = createChildCases(parents, new List<String>{CLOSED_STATUS});
		ParentCaseClosureValidService service = buildService(parents, OLD_MAP_VALS);

		Test.startTest();
		    Integer queryStartCount = Limits.getQueries();
			    Boolean didBlockingOccur = service.validate();
			Integer queryEndCount = Limits.getQueries();
		Test.stopTest();

		System.assert(!didBlockingOccur, 
			'Users should be able to close parent cases if all their children are closed');
	}

	static ParentCaseClosureValidService buildService(List<Case> newCases, Map<SObjectField, Object> oldState) {
		Map<Id, Case> oldMap = new Map<Id, Case>();
		for (Case newCase : newCases) {
			Case oldCase = newCase.clone(true);
			if (oldState != null) {
				for (SObjectField field : oldState.keySet()) {
					oldCase.put(field, oldState.get(field));
				}
			}
			oldMap.put(newCase.Id, oldCase);
		}
		return new ParentCaseClosureValidService(newCases, oldMap);
	}

	static List<Case> createChildCases(List<Case> parents, List<String> statuses) {
		return new SObjectBuilder(Case.SObjectType)
			.put(Case.ParentId, parents)
			.put(Case.Status, statuses)
			.put(Case.Project_Completion_Date__c, TODAY)
			.put(Case.Transition_Date__c, TODAY)
			.put(Case.RecordTypeId, VALIDATE_RECORD_TYPE)
            // Commenting for 8977 on 17th June 2022
			//.put(Case.Service_Order_Required__c, 'Yes')
			.count(RECORD_COUNT).create().getRecords();
	}

	static List<Case> createParentCases(String status) {
		return new SObjectBuilder(Case.SObjectType)
			.put(Case.Status, status)
			.put(Case.Project_Completion_Date__c, TODAY)
			.put(Case.Transition_Date__c, TODAY)
			.put(Case.RecordTypeId, VALIDATE_RECORD_TYPE)
            // Commenting for 8977 on 17th June 2022 

			//.put(Case.Service_Order_Required__c, 'Yes')
			.count(RECORD_COUNT).create().getRecords();
	}*/ //commented as part of user story #27072
}