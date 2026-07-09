/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Batchable class NAS_RecurringCaseGeneratorBatchable
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_RecurringCaseGenBatchableTest {
    /**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
	@testSetup
    public static void setupTestData()
    {
        NAS_TestDataFactory.setupTestData(1);
        NAS_TestDataFactory.createCase(1, NAS_Constants.RECURRING_CASE_RECORDTYPE, 
                                       true, NAS_Constants.RECURRING_CASE_ACTIVE);
    }
    /**
     * @name testRecurringCaseGeneratorBatchable
     * @description Test Recurring Case Generator Batchable class.
    **/
	@isTest
    public static void testRecurringCaseGeneratorBatchable() {
        Test.startTest();
        //Execute Batch job for Recurring Case Generation
        Id batchProcessId = NAS_RecurringCaseGeneratorBatchable.executeRecurringCaseGeneratorBatch();
        Test.stopTest();
        String caseFieldListString = NAS_Utilities.getRecurringCaseFieldsToClone();
        List<String> caseFieldList = caseFieldListString.split(',');
        List<Case> caseList = Database.query('SELECT ' + caseFieldListString + ', Status, CaseNumber, ' +
                                       'NAS_Recurrence_Frequency__c, NAS_Next_Case_Creation_Date__c, (SELECT ' + 
                                       caseFieldListString + ', ParentId, Status, RecordTypeId, ' + 
                                       'NAS_Next_Case_Creation_Date__c, NAS_Recurrence_Frequency__c ' +
                                       'FROM Cases WHERE RecordType.DeveloperName = \'' +
                                       NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE + '\') FROM Case ' + 
                                       'WHERE RecordType.DeveloperName = \'' + 
                                       NAS_Constants.RECURRING_CASE_RECORDTYPE + '\'');
        
        Set<String> caseFieldSetExcemptForCheck = new Set<String>{'ID', 'DIVISION', 
            									  'CASENUMBER', 'CREATEDDATE', 'LASTMODIFIEDDATE'};
        for(Case recurringCase: caseList)
        {
            if(recurringCase.Status == NAS_Constants.RECURRING_CASE_ACTIVE)
            {
                System.assertEquals(1, recurringCase.Cases.size(), 
                                    'New Child Case(s) not Created for the Recurring Case: ' + recurringCase.CaseNumber);
                System.assertEquals(NAS_DataFactory.getRecordTypeId('Case', 
                                    NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE), 
                                    recurringCase.Cases[0].RecordTypeId, 'Incorrect Value for Field: RecordTypeId');
                System.assertEquals(null, recurringCase.Cases[0].NAS_Next_Case_Creation_Date__c, 
                                    'Incorrect Value for Field: NAS_Next_Case_Creation_Date__c');
                System.assertEquals(null, recurringCase.Cases[0].NAS_Recurrence_Frequency__c, 
                                    'Incorrect Value for Field: NAS_Recurrence_Frequency__c');
                System.assertEquals(NAS_Constants.NEWCASESTATUS, recurringCase.Cases[0].Status, 
                                    'Incorrect Value for Field: Status');
                System.assertEquals(recurringCase.Id, recurringCase.Cases[0].ParentId, 
                                    'Incorrect Value for Field: ParentId');
                
                for(String caseField : caseFieldList)
                {
                    caseField = caseField.toUpperCase();
                    if(caseFieldSetExcemptForCheck.contains(caseField))
                    	continue;
                    else if(!NAS_Utilities.isCreatable('Case', caseField.toLowerCase()))
                        continue;
                    System.assertEquals(recurringCase.get(caseField), recurringCase.Cases[0].get(caseField), 
                                        'Incorrect Value for Field: ' + caseField + ' for recurring Case: ' + 
                                        recurringCase.CaseNumber + ' ' + NAS_Utilities.isCreatable('Case', caseField.toLowerCase()));
                }
                System.assertEquals(NAS_Utilities.getNextRecurrenceDate(
                    recurringCase.NAS_Recurrence_Frequency__c), 
                                    recurringCase.NAS_Next_Case_Creation_Date__c,
                                    'Incorrect Next Case Creation Date in Case: ' + recurringCase.CaseNumber);
            }
            else
            {
                System.assertEquals(0, recurringCase.Cases.size(), 
                                    'Incorrectly Child case was Created for Inactive Recurring Case: ' 
                                    + recurringCase.CaseNumber);
                System.assertNotEquals(NAS_Utilities.getNextRecurrenceDate(
                    recurringCase.NAS_Recurrence_Frequency__c), 
                                    recurringCase.NAS_Next_Case_Creation_Date__c,
                                    'Incorrectly updated the Next Case Creation Date in Case: ' + recurringCase.CaseNumber);
            }
            
        }
    }
}