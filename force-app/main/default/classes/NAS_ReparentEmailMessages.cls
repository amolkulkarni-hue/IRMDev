/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implements the reparent email message functionality. This class contains an invocable method 
* to be called from a visual workflow on save of a case record with appropriate conditions.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class NAS_ReparentEmailMessages {
	/**
     * @name reparentEmailMessages
     * @description Invocable method that clones the email messages under a child case to a parent
     * case if conditions are met.
    **/
    @InvocableMethod(label='Reparent Email Messages' 
                     description='Reparents Email Messages from a child case to a Parent Case.')
    public static void reparentEmailMessages(List<Id> caseIdList) {
        NAS_DataFactory.cloneCaseEmailMessages(caseIdList);
    }
}