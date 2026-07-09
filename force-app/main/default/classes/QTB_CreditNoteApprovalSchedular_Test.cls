/*****************************************************************************************************
* Class: QTB_CreditNoteApprovalSchedular_Test
* Purpose: This is a test class for apex code coverage
* Developer             Date
* -------------------------------------------------------------------------------------------
* TCS      10/11/2022
* Virtua   04/07/2024  -- Refactored the test class
*******************************************************************************************************/
@isTest
private with sharing class QTB_CreditNoteApprovalSchedular_Test {
    @testSetup
    static void setup(){
        test.startTest();
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        String recordType = 'Billing Account';
        id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        List<Account> accountList = new List<Account>();
        Account a = new Account();
        a.Name = 'TestAcc';
        a.RecordTypeId = recordTypeValue;
        a.QTB_Create_Parent_Billing_Account__c = true;
        a.BillingCountry = 'India';
        a.BillingState = 'Assam';
        a.QTB_Language__c = 'en_US';
        a.QTB_Contract_Entity__c = indiaEntity.ID;
        accountList.add(a);
        insert accountList;
        List<blng__CreditNote__c> ListCN = QTB_TestDataFactory.createCreditNote(accountList);
        test.stopTest();
    }
    
    static testmethod void TestApproval_CreditNote1()
    {
        Credit_ReBill_InvoiceSchedulerValidation__c crdNoteThreshold = new Credit_ReBill_InvoiceSchedulerValidation__c();
        crdNoteThreshold.Name = 'India';
        crdNoteThreshold.QTB_Country__c = 'India';
        crdNoteThreshold.QTB_Threshold_Approval_Amount__c = 500;
        insert crdNoteThreshold;
        
        String CRON_EXP = '0 6 * * * ?';
        List<blng__CreditNote__c> crdList =[Select id from blng__CreditNote__c limit 1];  
        blng__CreditNote__c crd = new blng__CreditNote__c();
        crd.Id = crdList[0].Id;
        crd.QTB_ReBill_Credit_Amount__c = 1000;
        update crd;
        
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new QTB_CreditNoteApprovalSchedular(crd));
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        Test.stoptest();
    }

  	static testmethod void TestApproval_CreditNote2()
    {
        Credit_ReBill_InvoiceSchedulerValidation__c crdNoteThreshold = new Credit_ReBill_InvoiceSchedulerValidation__c();
        crdNoteThreshold.Name = 'India';
        crdNoteThreshold.QTB_Country__c = 'India';
        crdNoteThreshold.QTB_Threshold_Approval_Amount__c = 500;
        insert crdNoteThreshold;
        
        String CRON_EXP = '0 6 * * * ?';
        List<blng__CreditNote__c> crdList =[Select id from blng__CreditNote__c limit 1];  
        blng__CreditNote__c crd = new blng__CreditNote__c();
        crd.Id = crdList[0].Id;
        crd.QTB_ReBill_Credit_Amount__c = 1000;
        update crd;
        
        Test.startTest();
        String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new QTB_CreditNoteApprovalSchedular(crd));
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        QTB_CreditNoteApprovalSchedular.CoverageMethod();
        Test.stoptest();
    }
    
    static testmethod void TestApproval_CreditNote3()
    {
        Test.startTest();
        String CRON_EXP = '0 6 * * * ?';
        String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new QTB_CreditNoteApprovalSchedular(null));
        Test.stoptest();
    }
}