/*****************************************************************************************************
* Class         : QTB_GenerateApixExtractQueueable
* Test Class    : QTB_GenerateApixExtractQueueableTest
* Author        : Virtusa
* Purpose       : This class containing logic to provide code coverage for QTB_GenerateApixExtractQueueable class
* Developer         Date          Description
* ------------------------------------------------------------------------------------------- 
*  Shailesh        18/06/2024      Gitlab US#24329 - Generating the Apix extract Text file for Invoice
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_GenerateApixExtractQueueableTest {
    
    @testSetup
    static void setup() {
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'blng__CreditNote__c;blng__CreditNoteLine__c;blng__Invoice__c;blng__InvoiceLine__c';
        cust.Disable_Trigger__c = true;
        insert cust;
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='Denmark';
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'Denmark';
        accountList[0].QTB_Language__c = 'en_US';
        update accountList;
        
        Test.startTest();
        //Invoice
        List<blng__Invoice__c> invoiceListFinal = new List<blng__Invoice__c>();
        for (Integer i = 0; i<= 1; i++) {
            blng__Invoice__c invoiceTemp = new blng__Invoice__c();
            invoiceTemp.blng__Account__c = accountList[0].Id;
            invoiceTemp.blng__InvoiceStatus__c = 'Posted';
            invoiceTemp.QTB_Custom_Invoice_Number__c = 'INV-123';
            invoiceTemp.blng__InvoiceDate__c = Date.valueOf('2021-07-27');
            invoiceListFinal.add(invoiceTemp);
        }
        if (!invoiceListFinal.isEmpty()) {
            insert invoiceListFinal;
        }
        
        // Create Credit Note
        List<blng__CreditNote__c> creditNoteList = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = accountList[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'EUR';
        creditNote.QTB_Custom_Invoice_Number__c ='CN-123';
        creditNote.QTB_On_Account_Credit__c = true;
        creditNoteList.add(creditNote);
        
        if(!creditNoteList.isEmpty()){
            insert creditNoteList;
            
            //Usage
            List<product2> productList = new List<product2>();
            product2 p = new product2();
            p.Name = 'Test Product';
            p.isActive = true;
            p.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            p.SBQQ__HasConsumptionSchedule__c = true;
            productList.add(p); 
            insert productList;
            
            //Insert -- CreditNoteLine for Bundle Header
            blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
            cnl.QTB_Account__c = accountList[0].Id;
            cnl.blng__CreditNote__c = creditNoteList[0].id;
            cnl.blng__Product__c = productList[0].Id;                        
            cnl.blng__CalculateTax__c=true;
            insert cnl;
            
            creditNoteList[0].blng__Status__c = 'Posted';
            update creditNoteList[0];
        }
        Test.stopTest();
    }
    
    @isTest
    private static void testMethod1(){
        List<blng__Invoice__c> invoiceListFinal = [SELECT ID, Name, blng__InvoiceStatus__c,QTB_Custom_Invoice_Number__c,blng__Account__r.QTB_Language__c
                                                   FROM blng__Invoice__c];
        Test.startTest();
        System.enqueueJob(new QTB_GenerateApixExtractQueueable(invoiceListFinal,true));
        Test.stopTest();
    }
    
    @isTest
    private static void testMethod2(){
        List<blng__CreditNote__c> creditNoteList = [SELECT ID, Name, blng__Status__c,QTB_Custom_Invoice_Number__c,blng__Account__r.QTB_Language__c
                                                    FROM blng__CreditNote__c];
        Test.startTest();
        System.enqueueJob(new QTB_GenerateApixExtractQueueable(creditNoteList,false));
        Test.stopTest();
    }
    
}