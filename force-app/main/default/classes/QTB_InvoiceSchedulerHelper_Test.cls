/*****************************************************************************************************
* Class: QTB_InvoiceSchedulerHelper_Test
* Author: Virtusa
* Purpose: This is a Test class for QTB_InvoiceSchedulerHelper
* Requirement:
* Change History: 19/09/2025
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Parth			19/09/2025             
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_InvoiceSchedulerHelper_Test {
    @testSetup static void setup(){
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity United States';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'United States';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		insert usaEntity;
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'test';
        schedule.blng__Type__c = 'Once';
        //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.now().addSeconds(10);
        schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
		schedule.QTB_Legal_Entity__c = usaEntity.id ;
        insert schedule;
    }
    static testMethod void testMethod1(){
        List<blng__InvoiceScheduler__c> invSch = [Select Id,QTB_InvoiceRunCompleted__c,blng__StartDateTime__c from blng__InvoiceScheduler__c];
        invSch[0].blng__StartDateTime__c = System.now().addSeconds(30);
        update invSch;
    }
}