/*****************************************************************************************************
* Class: UsageSuspenseTrigger_Test
* Purpose: This is a test class for apex code coverage
* 	Developer     		Date           
* ------------------------------------------------------------------------------------------- 
*  Vinutha Iyengar      1/Sep/2020
*******************************************************************************************************/
@isTest
public class UsageSuspenseTrigger_Test {
    
    static testmethod void method1()
    {
        Id AccountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();

        QTB_Usage_Suspense__c usageSuspenseRecord = new QTB_Usage_Suspense__c();
        usageSuspenseRecord.name = 'Test Record';
        usageSuspenseRecord.QTB_Mediation_Status__c = 'New';
        insert usageSuspenseRecord;
        
        test.startTest();
        	usageSuspenseRecord.QTB_Mediation_Status__c = 'Processed';
        	update usageSuspenseRecord;
        test.stopTest();
        
    }
}