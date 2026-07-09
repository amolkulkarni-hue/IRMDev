/**
* @author Nathan Vass
* @date 1/19
* @group Services
* @description
* A validation to prevent Parent Cases that still have open child cases from being closed. 

* Modified By: Simranjit Kaur on 4-Nov-2024
---Commenting out the lines as the functionalities are transferred via Flows. For reference, check user story #27072 on Gitlab.
*/

public with sharing class ParentCaseClosureValidService {
    public integer dummyMethod(){
        return 1;
    }
  /* commented as part of user story #27072
  static final String VALIDATION_MESSAGE = 'Parent Cases that still have open child cases cannot be closed';
  @testVisible static final List<String> VALIDATE_RECORD_TYPES_DEVNAMES = new List<String>{
    'NCSP_DP_Onboarding_team',        // NCSP: DP New Customer Setup
    'NCSP_DMS',                       // NCSP: DMS
    'NCSP_SKP_Department_Add_Only',   // NCSP: SKP Department Add Only
    'NCSP_SKP_New_customer_setup',     // NCSP: SKP New Customer Setup
    'NAS_General_Support_Case'
  };
  static final String CLOSED_STATUS = 'Closed';
     List<Case> triggerNew;
    Map<Id, Case> oldMap;
      public ParentCaseClosureValidService(List<Case> triggerNew, Map<Id, Case> oldMap)
     {
     this.triggerNew = triggerNew;
     this.oldMap = oldMap;
     }

  public Boolean validate() {
        
    Set<Id> recordTypesToValidate = getRecordTypesToValidate();
    List<Case> justClosed = filterJustClosed(recordTypesToValidate);
    if (justClosed.isEmpty()) {
    return false;
    }
    List<Case> closedAndOpenChildren  = parentsWithOpenChildren(justClosed);
    for (Case parentToBlockSave :  closedAndOpenChildren) {
       if (Test.isRunningTest()) {
        return true;
      }
      parentToBlockSave.addError(VALIDATION_MESSAGE);
    }
    return false;
  }

  List<Case> parentsWithOpenChildren(List<Case> parents) {
        
    List<Case> result = new List<Case>();
        // System.debug('result@@@@'+result);
    Set<Id> invalidateCaseIds = Pluck.ids(
      Case.ParentId + '',
      [   SELECT ParentId
          FROM Case 
          WHERE ParentId IN :parents 
          AND IsClosed = false 
          AND ParentId != null ]
    ); //modified SOQL By gouthami for case #11124616 on 10.09.2019 for resolving 50001 error
         
    for (Case parent : parents) {
            
        
      if (invalidateCaseIds.contains(parent.Id)) {
        result.add(parent);
        }
    }
    return result;
     // System.debug('@@@@result@@@@'+result);   
  }
   

  List<Case> filterJustClosed(Set<Id> caseRecordTypesToValidate) {
    List<Case> result = new List<Case>();
    for (Case newCase : this.triggerNew) {
            Case oldCase = (this.oldMap == null) ? null : this.oldMap.get(newCase.Id);
            Boolean needsValidation = caseRecordTypesToValidate.contains(newCase.RecordTypeId);
            Boolean justClosed = newCase.Status == CLOSED_STATUS && (oldCase == null || oldCase.Status != CLOSED_STATUS);
         if (needsValidation && justClosed) {
            result.add(newCase);
        }
    }
    return result;
        
     }
  Set<Id> getRecordTypesToValidate() {
    Set<Id> result = new Set<Id>();
    for (String recordTypeNeedingValidation : VALIDATE_RECORD_TYPES_DEVNAMES) {
      RecordType cached = RecordTypeCache.get(Case.SObjectType, recordTypeNeedingValidation);
      if (cached != null) {
        result.add(cached.Id);
      }
    }
    return result;
  }*/ //commented as part of user story #27072
}