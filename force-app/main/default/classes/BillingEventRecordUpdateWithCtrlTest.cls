@isTest
public class BillingEventRecordUpdateWithCtrlTest {

    @testSetup
    public static void setupData() {        
        pse__Billing_Event__c billingEvent = new pse__Billing_Event__c();
        Date invoiceDte = Date.newInstance(2008, 10, 5);
        billingEvent.pse__Invoice_Date__c= invoiceDte; 
        billingEvent.pse__Invoice_Number__c ='9MJ3477';
        billingEvent.pse__Invoiced__c=true;
        insert billingEvent;

        // Create and insert a Billing Event Item
        pse__Billing_Event_Item__c billingEventItem = new pse__Billing_Event_Item__c();
        billingEventItem.pse__Object_Id__c = 'testObjectId';
        billingEventItem.pse__Billing_Event__c = billingEvent.Id;
        insert billingEventItem;
    }

    @isTest
    static void testUpdateBillingEventRecords() {
        // Query existing records for the test
        pse__Billing_Event_Item__c billingEventItem = [SELECT Id, pse__Billing_Event__c FROM pse__Billing_Event_Item__c LIMIT 1];
        pse__Billing_Event__c billingEvent = [SELECT Id, pse__Invoice_Date__c, pse__Invoice_Number__c FROM pse__Billing_Event__c WHERE Id = :billingEventItem.pse__Billing_Event__c LIMIT 1];

        // Prepare records for the batch
        List<BillingEventRecordUpdateWithCtrl.BillingEventFields> records = new List<BillingEventRecordUpdateWithCtrl.BillingEventFields>();
        BillingEventRecordUpdateWithCtrl.BillingEventFields record = new BillingEventRecordUpdateWithCtrl.BillingEventFields();
        record.billingEventItemID = billingEventItem.Id;
        record.billingEventItemBillingEventInvoiceNumber = billingEvent.pse__Invoice_Number__c;
        record.billingEventItemBillingEventInvoiceDate = String.valueOf(billingEvent.pse__Invoice_Date__c);  // Ensure the date is formatted correctly
        records.add(record);

        // Execute the method to test
        Test.startTest();
        BillingEventRecordUpdateWithCtrl.updateBillingEventRecords(records);
        Test.stopTest();
    }
    
    @isTest
    static void testBillingEventFieldsReturn() {
        // Execute the method to test
        Test.startTest();
        List<BillingEventRecordUpdateWithCtrl.BillingEventFields> result = BillingEventRecordUpdateWithCtrl.billingEventFieldsReturn();
        Test.stopTest();

        // Perform assertions
        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(1, result.size(), 'The result should contain one BillingEventFields record.');
        
        BillingEventRecordUpdateWithCtrl.BillingEventFields fields = result[0];
        System.assertEquals('', fields.billingEventItemID, 'The billingEventItemID should be an empty string.');
        System.assertEquals('', fields.billingEventItemBillingEventInvoiceNumber, 'The billingEventItemBillingEventInvoiceNumber should be an empty string.');
        System.assertEquals('', fields.billingEventItemBillingEventInvoiceDate, 'The billingEventItemBillingEventInvoiceDate should be an empty string.');
    }
}