/*****************************************************************************************************************************
Created By : Vinod Kumar
Created Date : 6th October , 2010
Usages : Test coverage of Issue_TaskConfirmCustAccMatchesParent  Trigger.
*****************************************************************************************************************************/
@isTest
private class Test_Issue_TaskCustAccMatchesParent {

    static testMethod void myUnitTest() {
        ID caseRecordType ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();        
        if(rtMapByName.containsKey('Issue'))
            caseRecordType = rtMapByName.get('Issue').getRecordTypeId();
        IM_Customer_Account__c custAcc = GenerateTestData.createCustomerAccount('101' , 'Test'); 
        Case newCase = GenerateTestData.createCaseObjectWithoutInsert(caseRecordType,custAcc );
        insert  newCase;    
        IM_Customer_Account__c custAcc2 = GenerateTestData.createCustomerAccount('101' , 'Test2');
        newCase.Customer_ID__c = custAcc2.Id;
        try{
            update  newCase;
        }
        catch(Exception ex){
           //System.assert(ex.getMessage().contains('Customer Account seleced on the case does not match the parent account on the case'));
        }
    }
}