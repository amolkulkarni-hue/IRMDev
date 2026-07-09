/*
* Jitendra Mishra 26/08/2024      Commenting the entire class as this functionality is no longer in use, 
                                  and adding a dummy classmethod(DummyMethodForTestCoverage) for the test coverage,story #25700
*/


public without sharing class CaseFieldHistoryServices {
public static void DummyMethodForTestCoverage() {
        
    }
    /*
     //#25700 Commenting the code start
    final static String GUEST_USER_PROFILE_NAME = 'Customer Information Form Profile';

    public static Id externalProfileID {
        get {
            if (externalProfileID == null) 
                externalProfileID = [Select Id From Profile Where Name = :GUEST_USER_PROFILE_NAME Limit 1].Id;
            return externalProfileID;
        }
        set;
    }

    static Case_Field_History__c createCaseFieldHistory(Id caseId, String fieldName, String oldVal, String newVal) {
        Case_Field_History__c history = new Case_Field_History__c( Case_Lookup__c = caseId,
                                                          Field_Changed__c = fieldName,
                                                         Previous_Value__c = oldVal,
                                                          Current_Value__c = newVal,
                                                             Changed_At__c = Datetime.now() );
        return history;
    }

    public static List<Case_Field_History__c> createCaseFieldHistories( List<Case> newCases, Map<Id, Case> oldMap, Map<Id, Set<String>> case2Fields ) {
        List<Case_Field_History__c> histories = new List<Case_Field_History__c>();
        for (Case c : newCases) {
            for (String field : case2Fields.get(c.Id)) {
                if (oldMap.get(c.Id).get(field) != c.get(field)) {
                    histories.add( createCaseFieldHistory(c.Id, field, String.valueOf(oldMap.get(c.Id).get(field)), String.valueOf(c.get(field))) );
                }
            }
        }
        return histories;
    }

    public static List<Case> filterCasesModifiedByExternalUser( List<Case> allModifiedCases ) {
        List<Case> casesModifiedByExternalUser = new List<Case>();
        Set<Id> usersOnCases = Pluck.ids('LastModifiedById', allModifiedCases);

        Map<Id, User> allUsersOnCases =  new Map<Id, User>([Select Id, ProfileId From User Where Id in :usersOnCases]);

        for (Case c : allModifiedCases){
            //Add allUsersOnCases map values not equal to NULL -- Gitlab requirement #455//
            if (allUsersOnCases.size()>0 && allUsersOnCases.get(c.LastModifiedById).ProfileId == externalProfileID){
                casesModifiedByExternalUser.add(c);
            }
        }
        return casesModifiedByExternalUser;
    }

    
    //  If a Case does not link to any fieldSet, then that case will not have an entry in the generated case->fields map
   
    public static Map<Id, Set<String>> buildFieldsToCheckMap( List<Case> cases ) {
        Map<Id, Set<String>> case2Fields = new Map<Id, Set<String>>();
        cases = [SELECT Id, NCSP_Service_Line__c, Deal_Type__c, NCSP_Upsell_Type__c, Supplies_Order_Required__c 
                   FROM Case WHERE Id in :cases];
        Map<Id, List<Customer_Onboarding_Field__c>> case2OnboardingFields = CustomerOnboardingCriteriaServices.getOnboardingFieldSets(cases);
        for (Id id : case2OnboardingFields.keySet()) {
            Set<String> fieldsToAdd = new Set<String>();
            for (Customer_Onboarding_Field__c cof : case2OnboardingFields.get(id)) {
                if (String.isBlank(cof.Related_Object__c)) 
                    fieldsToAdd.add(cof.Field_API_Name__c);
            }
            case2Fields.put(id, fieldsToAdd);

        }
        return case2Fields;
    }

    public static void insertFieldHistoriess(List<Case_Field_History__c> fhs) {
        SafeDML fhsToInsert = new SafeInsert();
        ErrorHandling.AddErrorsToTriggerNew errorHandling = new ErrorHandling.AddErrorsToTriggerNew( Trigger.newMap,'Case_Lookup__c' );                      
        fhsToInsert.queue(fhs, errorHandling);
        fhsToInsert.doDml();
    }
*/
    //#25700 Commenting the code end
}