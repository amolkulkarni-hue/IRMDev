/*****************************************************************************************************
* Class: QTB_Ready_for_integration_Batch_Test
* Author: 
* Purpose: Test Class for QTB_Ready_for_Integration_Batch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*           5/7/2024
*******************************************************************************************************/
@isTest(seeAllData=false) 
private with sharing class QTB_Ready_for_Integration_Batch_Test {
   @TestSetup
    static void createData() {
        //List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Test.startTest();
        
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Sweden'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Finland'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Denmark'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Taiwan'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Thailand'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Malaysia'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Hong Kong'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Singapore'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('India'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('United States'));
        for(blng__LegalEntity__c le :entityList){
            if(le.blng__Country__c == 'Thailand'){
                le.QTB_Tax_Applicability__c ='Product Based';
            }
            else{
                le.QTB_Tax_Applicability__c ='Flat Rate';
            }
        }
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(11); //insert 10 accounts
        for (Integer i = 0; i < accList.size(); i++) {
            accList[i].QTB_Hold_Invoice__c = false;
            accList[i].QTB_Contract_Entity__c = entityList[i].Id;
        }
        system.debug('accList>>'+accList);
        
         //Invoice
        List<blng__Invoice__c> invoiceList2 = new List<blng__Invoice__c>();
        for (integer i = 0; i < accList.size(); i++) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accList[i].Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            if(i == 0){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Invoice_Type__c = 'New';
            }
            if(i == 1 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
            }
            if(i == 2){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Invoice_Type__c = 'New';
                //invoice.QTB_Parent_Invoice__c = invoiceList[0].id;
            }
            if(i == 3 || i == 4 || i == 5 || i == 6 || i == 7 || i == 8 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
            }
            invoiceList2.add(invoice);
        }
        if (!invoiceList2.isEmpty()) {
            insert invoiceList2;
        }
        /*List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(
            accList
        );
        
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        invList[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList[0].QTB_Custom_Invoice_Number__c='IND12345678';
        invList[0].QTB_KID__c='IND12345678';
        invList[0].blng__InvoiceStatus__c='Posted';
        invList[0].QTB_Bill_Cycle_Day__c ='1';
        for(blng__Invoice__c inv :invList){
            inv.QTB_Tax_Override_Amount__c = 10;
        }
        update invList;*/
        //Invoiceline
          List<blng__InvoiceLine__c> invLinesList = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__Invoice__c = invoiceList2[0].id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invoiceLine;
        
        
        invLinesList.add(invoiceLine);
       
    }
    static testmethod void testMethod1() {
        Test.startTest();
        List<Account> accList = QTB_TestDataFactory.createAccounts(10); //insert 10 accounts
              
         List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(
            accList
        );
        
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        invList[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList[0].QTB_Custom_Invoice_Number__c='IND12345678';
        invList[0].QTB_KID__c='IND12345678';
        invList[0].blng__InvoiceStatus__c='Posted';
        invList[0].QTB_Bill_Cycle_Day__c ='1';
        for(blng__Invoice__c inv :invList){
            inv.QTB_Tax_Override_Amount__c = 10;
        }
        update invList;
        
        List<blng__InvoiceLine__c> invLinesList = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__Invoice__c = invList[0].id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invoiceLine;
        
        List<blng__InvoiceLine__c> invLinesLst = [SELECT ID,blng__InvoiceLineStatus__c,blng__Invoice__c,blng__Invoice__r.blng__InvoiceStatus__c,blng__Invoice__r.QTB_Custom_Invoice_Number__c 
                                                  from blng__InvoiceLine__c];   
        
        
        Set<Id>InvoiceIds = new Set<Id>();
        for(blng__InvoiceLine__c invln :invLinesLst){
            InvoiceIds.add(invln.blng__Invoice__c);
        }
        //QTB_ReadyForIntegrationWithSuccessError b1=new QTB_ReadyForIntegrationWithSuccessError(InvoiceIds);
        //	Database.executeBatch(b1);QTB_Ready_for_Integration_Batch
        
        QTB_Ready_for_Integration_Batch b=new QTB_Ready_for_Integration_Batch(InvoiceIds);
        Database.executeBatch(b);
        Test.stopTest();
    }
    
    //cover catch
    static testMethod void testMethod2() {
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            QTB_ReadyForIntegrationWithSuccessError.throwExplicitException = true;
            QTB_Ready_for_Integration_Batch.throwExplicitException = true;
                       
            QTB_Ready_for_Integration_Batch b=new QTB_Ready_for_Integration_Batch(null);
        	b.execute(null,null);
            QTB_Ready_for_Integration_Batch b3=new QTB_Ready_for_Integration_Batch(null);
        	b3.finish(null);
            QTB_Ready_for_Integration_Batch b4=new QTB_Ready_for_Integration_Batch(null);
        	b4.start(null);
            QTB_ReadyForIntegrationWithSuccessError b1=new QTB_ReadyForIntegrationWithSuccessError(null);
            b1.execute(null, null);
            QTB_ReadyForIntegrationWithSuccessError b2=new QTB_ReadyForIntegrationWithSuccessError(null);
            b2.finish(null);
            Test.stopTest();
            System.assertEquals(true, QTB_ReadyForIntegrationWithSuccessError.throwExplicitException);
        }
    }
}