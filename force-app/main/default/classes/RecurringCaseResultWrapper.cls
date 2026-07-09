/********************************************************************************************************
@Description: This Apex Class is created to handle multiple returns for NAS_DataFactory.createRecurringCases method
@Copyright: Iron Mountain
@Author:  Simranjit Kaur
@Created on:  11/19/2025(MM/DD/YYYY)
@TestClass Name: RecurringCaseResultWrapperTest
*
Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
===================================================
*
********************************************************************************************************/
public class RecurringCaseResultWrapper {
    public Set<Id> failedInsertParentIds;
    public Set<Id> failedUpdateCaseIds;

    public RecurringCaseResultWrapper() {
        failedInsertParentIds = new Set<Id>();
        failedUpdateCaseIds = new Set<Id>();
    }
}