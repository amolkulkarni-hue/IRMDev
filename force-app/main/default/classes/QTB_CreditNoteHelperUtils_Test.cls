/*****************************************************************************************************
* Class: QTB_CreditNoteHelperUtils_Test
* Author: Virtusa
* Purpose: Test Class for QTB_CreditNoteHelperUtils
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Parth   		05/15/2023		to cover calculateIndividualTaxAmountsOnCreditNoteLines, buildTaxRateMap, calculateTax method
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CreditNoteHelperUtils_Test {
    @TestSetup
    static void setup() {
         Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert custSetting;
        QTB_Tax_Integration_Setting__mdt vertexData = new QTB_Tax_Integration_Setting__mdt();
        vertexData.Label = 'Vertex';
        vertexData.DeveloperName = 'Vertex_Integration';
        vertexData.QTB_Country__c = 'United States;Canada';
        vertexData.QTB_End_System__c = 'Vertex';
        
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p1);
        insert productList;
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        indiaEntity.QTB_Tax_Applicability__c = 'Product Based';
        indiaEntity.CurrencyIsoCode='EUR';
        indiaEntity.QTB_FX_Tax_Rate_Type__c='HU National Bank Rate';
        update indiaEntity;
        
        //Billing Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='India';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].QTB_Contract_Entity__c=indiaEntity.id;
        accountList[0].ShippingCity = 'TN';
        accountList[0].BillingCountry='India';
        accountList[0].ShippingState = 'Chennai';
        accountList[0].ShippingPostalCode = '500032';
        accountList[0].ShippingCountry = 'India';
        accountList[0].QTB_Records_Management__c = true;
        accountList[0].CurrencyIsoCode = 'EUR';
        update accountList;        
        
        
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        //Tax Integration
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        insert taxIntegration;
        
        //Tax Treatment
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        blngTax.QTB_Invoice_Print_Tax_Name__c = 'GST';
        insert blngTax;
        
        //Tax Rate
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indiaEntity.id;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'India';
       // taxRate.blng__State__c = 'TN';
       // taxRate.blng__City__c = 'Chennai';
       // taxRate.blng__ZipCode__c = '500032';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;        
        taxRate.blng__AddressComparison__c =
            taxRate.blng__Country__c +
            '-' +
            taxRate.blng__State__c +
            '-' +
            taxRate.blng__City__c +
            '-' +
            taxRate.blng__ZipCode__c +
            '-' +
            taxRate.blng__TaxCode__c +
            '-' +
            taxRate.blng__LegalEntity__c;         
         insert taxRate;      
        
        // Create Credit Note
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.QTB_On_Account_Credit__c = true;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.QTB_Exchange_Rate__c=17;
        creditNote1.CurrencyIsoCode = 'INR';
        creditNotesList.add(creditNote1);
        System.debug('setup_creditNotesList@@'+creditNotesList);
        insert creditNotesList;
        
        //Create CreditNoteLine for CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.blng__TaxTreatment__c = blngTax.Id;
        cnl1.blng__TaxCountry__c = 'India';
        cnl1.blng__TaxState__c = 'TN';
        cnl1.blng__TaxCity__c = 'Chennai';
        cnl1.blng__TaxZipCode__c = '500032';
        cnl1.blng__LegalEntity__c = indiaEntity.Id;
        cnl1.blng__CalculateTax__c = true;
        creditNoteLineList.add(cnl1);
        System.debug('setup_creditNoteLineList1@@'+creditNoteLineList);
        insert creditNoteLineList;
        System.debug('setup_creditNoteLineList2@@'+creditNoteLineList);    
        
    }
    @isTest
    static void testMethod1(){
        set<Id> creditNoteId = new set<Id>();
        List<blng__CreditNote__c> creditNotesList = [select id from blng__CreditNote__c];
        for(blng__CreditNote__c cn :creditNotesList){
            creditNoteId.add(cn.Id);
        }
        QTB_CreditNoteHelperUtils.calculateIndividualTaxAmountsOnCreditNoteLines(creditNoteId);
        
    } 
    @isTest
    static void testMethod2(){
        blng__LegalEntity__c legalEnty = [SELECT Id,QTB_Tax_Applicability__c from blng__LegalEntity__c LIMIT 1];//,QTB_Tax_Type__c
        legalEnty.QTB_Tax_Applicability__c = 'FLAT RATE';
        Update legalEnty;
        set<Id> creditNoteId = new set<Id>();
        set<blng__CreditNote__c> commCNId = new set<blng__CreditNote__c>();
        List<blng__CreditNote__c> creditNotesList = [select id from blng__CreditNote__c];
        for(blng__CreditNote__c cn :creditNotesList){
            cn.QTB_Commercial_Credit__c = false;
            creditNoteId.add(cn.Id);
            commCNId.add(cn);
        }
        QTB_CreditNoteHelperUtils.calculateIndividualTaxAmountsOnCreditNoteLines(creditNoteId);
        QTB_CreditNoteHelperUtils.commercialCreditNoteCheck(commCNId);
         try{
            QTB_CreditNoteHelperUtils.updateFieldsForLegacyInvoiceOfPostedCNS(null);
            QTB_CreditNoteHelperUtils.calculateIndividualTaxAmountsOnCreditNoteLines(null);
            QTB_CreditNoteHelperUtils.calculateTax(null,null);
            QTB_CreditNoteHelperUtils.commercialCreditNoteCheck(null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }

    }
    @isTest
    static void testMethod3(){
          //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Fair Market Value';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id;
        p1.blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id;
        p1.blng__RevenueRecognitionRule__c= QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id;
        productList.add(p1);
        insert productList;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            CurrencyIsoCode = 'INR',
            QTB_country__c = 'India',
            IsActive = true);
        update standardPricebook;
        
        List<priceBook2> prbk = QTB_TestDataFactory.priceBookMethdLst(1,'India');
        prbk[0].QTB_Country__c = 'India';
        prbk[0].currencyISOCode = 'INR';
        prbk[0].IsActive = true;
        update prbk[0];
        system.debug('prbk--->'+prbk[0].Id +' country--->'+prbk[0].QTB_Country__c);
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = productList[0].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode = 'INR' );
        insert standardPrice;
        System.debug('**standardPrice'+standardPrice+'Currency >>>'+standardPrice.CurrencyIsoCode);
        PriceBookEntry IndiaPrice= new PricebookEntry(pricebook2id = prbk[0].id, product2Id = productList[0].id, unitPrice=2000, isActive = true, currencyISOCode = 'INR');
        insert IndiaPrice;
        System.debug('**IndiaPrice--->'+IndiaPrice+' Currency--->'+IndiaPrice.CurrencyIsoCode+' pricebookCountry--->'+IndiaPrice.pricebook2.QTB_country__c);
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        indiaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        indiaEntity.CurrencyIsoCode = 'EUR';
        indiaEntity.QTB_FX_Tax_Rate_Type__c = 'HU National Bank Rate';
        update indiaEntity;
        //Billing Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c = 'India';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'TN';
        accountList[0].ShippingState = 'Chennai';
        accountList[0].ShippingPostalCode = '500032';
        accountList[0].ShippingCountry = 'India';
        accountList[0].QTB_Records_Management__c = true;
        accountList[0].Payment_Terms__c = 'Net 30';
        accountList[0].QTB_Legal_Entity__c = indiaEntity.Id;
        accountList[0].QTB_Contract_Entity__c = indiaEntity.Id;
        accountList[1].QTB_Legal_Entity_Country__c = 'India';
        accountList[1].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[1].ShippingCity = 'TN';
        accountList[1].ShippingState = 'Chennai';
        accountList[1].ShippingPostalCode = '500032';
        accountList[1].ShippingCountry = 'India';
        accountList[1].QTB_Records_Management__c = true;
        accountList[1].Payment_Terms__c = 'Net 30';
        accountList[1].QTB_Legal_Entity__c = indiaEntity.Id;
        accountList[1].QTB_Contract_Entity__c = indiaEntity.Id;
        Update accountList;
        
        
        
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        //Tax Integration
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        insert taxIntegration;
        
        //Tax Treatment
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        insert blngTax;
        
        //Tax Rate
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indiaEntity.id;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'India';
        taxRate.blng__State__c = 'TN';
        taxRate.blng__City__c = 'Chennai';
        taxRate.blng__ZipCode__c = '500032';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;        
        taxRate.blng__AddressComparison__c =
            taxRate.blng__Country__c +
            '-' +
            taxRate.blng__State__c +
            '-' +
            taxRate.blng__City__c +
            '-' +
            taxRate.blng__ZipCode__c +
            '-' +
            taxRate.blng__TaxCode__c +
            '-' +
            taxRate.blng__LegalEntity__c;         
        insert taxRate;      
        
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[1].Id;
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_Tax_Override_Amount__c = 10;
        invoice.blng__InvoiceDate__c = System.today();
        //26371
        invoice.blng__DueDate__c = System.today();
        //28078
        invoice.QTB_Exchange_Rate__c = 20;
        sbqq.TriggerControl.disable();
        insert invoice;
        system.debug('invoice-->'+invoice);
        //List<blng__InvoiceLine__c> invoiceLineListForCredit = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        blng__LegalEntity__c indiaEntity1 = QTB_TestDataFactory.createLegalEntity('India');
        indiaEntity1.QTB_Tax_Applicability__c = QTB_Constants.LEGALENTITY_TYPE_FLAT;
        update indiaEntity1;
        Product2 prod = productList[0];
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = prod.Name;
        invoiceLine.blng__Invoice__c = invoice.Id;
        invoiceline.blng__LegalEntity__c = indiaEntity1.id;
        invoiceLine.blng__Product__c = prod.Id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__Subtotal__c = 50;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__TaxPercentageApplied__c = 24;
        //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
        invoiceLine.QTB_Tax_Override_Amount__c = 10;
        SBQQ.TriggerControl.disable();
        insert invoiceLine;
        SBQQ.TriggerControl.enable();        
        system.debug('invoiceLine--->'+invoiceLine);
        //system.debug('invoiceLineListForCredit->'+invoiceLineListForCredit[0]);
        /*invoiceLineListForCredit[0].QTB_Tax_Override_Amount__c = 10;
List<blng__CreditNote__c> creditNoteWithInvRefList = QTB_TestDataFactory.createCreditNote(accountList);
List<blng__CreditNoteLine__c> cnlWithInvLst = QTB_TestDataFactory.createCreditNoteLine(1,accountList[0],creditNoteWithInvRefList[0],invoiceListForCredit[0],invoiceLineListForCredit[0],productList[0]);
system.debug('cnlWithInvLst->'+cnlWithInvLst[0]);
system.debug('cnlWithInvLst->'+cnlWithInvLst[0].QTB_invoiceline__c);*/
        
        Test.startTest();
        // Create Credit Note
        List<blng__CreditNote__c> creditNotesList1 = new List<blng__CreditNote__c>();
        
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.QTB_On_Account_Credit__c = true;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.QTB_Related_Legacy_Invoice__c = invoice.id;
        creditNote1.CurrencyIsoCode = 'INR';
        creditNotesList1.add(creditNote1);
        blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
        creditNote2.blng__Account__c = accountList[1].Id;
        creditNote2.QTB_On_Account_Credit__c = false;
        creditNote2.blng__CreditNoteDate__c = date.today();
        creditNote2.QTB_Reason_Code__c = 'Bankruptcy';
        creditNote2.blng__Status__c = 'Draft';
        creditNote2.CurrencyIsoCode = 'INR';
        creditNotesList1.add(creditNote2);
        System.debug('setup_creditNotesList1@@'+creditNotesList1);
        insert creditNotesList1;
        
        //Create CreditNoteLine for CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList1[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.blng__TaxTreatment__c = blngTax.Id;
        cnl1.blng__TaxCountry__c = 'India';
        cnl1.blng__TaxState__c = 'TN';
        cnl1.blng__TaxCity__c = 'Chennai';
        cnl1.blng__TaxZipCode__c = '500032';
        cnl1.blng__LegalEntity__c = indiaEntity.Id;
        cnl1.blng__CalculateTax__c = true;
        cnl1.blng__TaxPercentageApplied__c = 9;
        creditNoteLineList.add(cnl1);
        
        blng__CreditNoteLine__c cnl2 = new blng__CreditNoteLine__c();
        cnl2.QTB_Account__c = accountList[1].Id;
        cnl2.blng__CreditNote__c = creditNotesList1[1].id;
        cnl2.blng__InvoiceLine__c = invoiceLine.id;
        cnl2.QTB_InvoiceLine__c = invoiceLine.id;
        cnl2.QTB_Invoice__c = invoice.Id;
        cnl2.blng__TaxTreatment__c = blngTax.Id;
        cnl2.blng__TaxCountry__c = 'India';
        cnl2.blng__TaxState__c = 'TN';
        cnl2.blng__TaxCity__c = 'Chennai';
        cnl2.blng__TaxZipCode__c = '500032';
        cnl2.blng__LegalEntity__c = indiaEntity.Id;
        cnl2.blng__CalculateTax__c = true;
        cnl2.blng__TaxPercentageApplied__c = 24;
        cnl2.blng__Subtotal__c = 50;
        cnl2.QTB_Credit_Quantity__c = 10;
        //cnl2.QTB_Credit_Note_Type__c = 'Split ReBill';
        creditNoteLineList.add(cnl2);
        System.debug('setup_creditNoteLineList1@@'+creditNoteLineList);
        //sbqq.TriggerControl.disable();
        insert creditNoteLineList;
        //Update Credit Note
        creditNotesList1[0].ApprovalStatus__c = 'Approved';        
        creditNotesList1[0].blng__Status__c = 'Posted';
        creditNotesList1[0].QTB_Commercial_Credit__c = true;
        
        QTB_Invoice_For_EU__c a = new QTB_Invoice_For_EU__c();
        a.name='india';
        insert a;
    
        QTB_Invoice_Note_Labels__c invNotesLabels = new QTB_Invoice_Note_Labels__c();
        invNotesLabels.Name='india';
        invNotesLabels.Exchange_Rate__c='a';
        invNotesLabels.Sub_Total__c='b';
        invNotesLabels.VAT__c='c';
        invNotesLabels.Total__c='d';
        insert invNotesLabels;
        Map<String, QTB_Invoice_Note_Labels__c> lstInvoiceNotesLabel = QTB_Invoice_Note_Labels__c.getAll();
        Map<Id,blng__CreditNote__c> crdMap = new Map<Id,blng__CreditNote__c>();
        Map<String, QTB_Invoice_For_EU__c> lstEuCountries1 = QTB_Invoice_For_EU__c.getAll();                
        Map<String, QTB_Invoice_Note_Labels__c> lstInvoiceNotesLabel1 = QTB_Invoice_Note_Labels__c.getAll();

        List<blng__CreditNote__c> crdList1 = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Tax_Override_Amt_Local__c,
                                                     QTB_Exchange_Rate__c,blng__Account__r.CurrencyIsoCode,QTB_Total_Amt_Tax_Override_local__c,QTB_Subtotal_local_currency__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__CreditNoteDate__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__Account__r.QTB_Legal_Entity__r.QTB_FX_Tax_Rate_Type__c,
                                                     (select id,blng__TaxCode__c,QTB_Invoice__r.QTB_Exchange_Rate__c,blng__CreditNote__c from blng__CreditNoteCreditLines__r LIMIT 1)
                                                     from blng__CreditNote__c where id=:creditNote1.id];
        for(blng__CreditNote__c crd1 :crdList1){ 
            crdMap.put(crd1.id,crd1);
            system.debug('@@@@@@@@@@@@@@@@@2'   +crd1);
        }
        set<blng__CreditNote__c> commCNId1 = new set<blng__CreditNote__c>();
        List<blng__CreditNote__c> commCreditNotesList = [select id from blng__CreditNote__c];
        for(blng__CreditNote__c cn1 :commCreditNotesList){
            cn1.QTB_Commercial_Credit__c = false;
            commCNId1.add(cn1);
        }
         QTB_CreditNoteHelperUtils.commercialCreditNoteCheck(commCNId1);
        //26371 starts
        Map<Id,blng__CreditNote__c> cnMap = new Map<Id,blng__CreditNote__c>();
        for(blng__CreditNote__c cn : creditNotesList1){
            cnMap.put(cn.id,cn);
        }
        QTB_CreditNoteHelperUtils.updateDueDate(cnMap);
        Set<Id> invoiceIds = new Set<Id>();
        List<blng__Invoice__c> invList = new List<blng__Invoice__c>();
        try {
      for (Account acc : accountList) {
        blng__Invoice__c invoice1 = new blng__Invoice__c();
        invoice1.blng__Account__c = acc.Id;
        invoice1.blng__InvoiceStatus__c = 'Draft';
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        invList.add(invoice1);
      }
            
      if (!invList.isEmpty()) {
        insert invList;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
        invList[0].blng__InvoiceStatus__c = 'Posted';
        invList[0].QTB_Invoice_Type__c = 'Legacy Invoice';
        invList[1].blng__InvoiceStatus__c = 'Posted';
        invList[1].QTB_Invoice_Type__c = 'Legacy Invoice';
        update invList;
        SBQQ.TriggerControl.enable();
        for(blng__Invoice__c inv : invList){
            invoiceIds.add(inv.id);
        }
        QTB_CreditNoteHelperUtils.updateFieldsForLegacyInvoiceOfPostedCNS(invoiceIds);
        //28078
        QTB_CreditNoteHelperUtils.updateExchangeRate(crdMap,true);
        QTB_CreditNoteHelperUtils.updateNoteOnCreditNote(crdMap);
        try {
           QTB_CreditNoteHelperUtils.updateDueDate(null);
           QTB_CreditNoteHelperUtils.updateFieldsForLegacyInvoiceOfPostedCNS(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        //26371 Ends
         test.stopTest();
    }
    //Added #26654
    @isTest
    static void testMethod4(){
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Fair Market Value';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id;
        p1.blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id;
        p1.blng__RevenueRecognitionRule__c= QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id;
        productList.add(p1);
        insert productList;
        
         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            CurrencyIsoCode = 'INR',
            QTB_country__c = 'India',
            IsActive = true);
        update standardPricebook;
        
        List<priceBook2> prbk = QTB_TestDataFactory.priceBookMethdLst(1,'India');
        prbk[0].QTB_Country__c = 'India';
        prbk[0].currencyISOCode = 'INR';
        prbk[0].IsActive = true;
        update prbk[0];
        system.debug('prbk--->'+prbk[0].Id +' country--->'+prbk[0].QTB_Country__c);
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = productList[0].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode = 'INR' );
        insert standardPrice;
        System.debug('**standardPrice'+standardPrice+'Currency >>>'+standardPrice.CurrencyIsoCode);
        PriceBookEntry IndiaPrice= new PricebookEntry(pricebook2id = prbk[0].id, product2Id = productList[0].id, unitPrice=2000, isActive = true, currencyISOCode = 'INR');
        insert IndiaPrice;
        System.debug('**IndiaPrice--->'+IndiaPrice+' Currency--->'+IndiaPrice.CurrencyIsoCode+' pricebookCountry--->'+IndiaPrice.pricebook2.QTB_country__c);
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        indiaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        indiaEntity.CurrencyIsoCode = 'EUR';
        indiaEntity.QTB_FX_Tax_Rate_Type__c = 'HU National Bank Rate';
        update indiaEntity;
        //Billing Account
        List<Account> accountList = new List<Account>();
        Account acc = new Account();
        acc.name = 'test Acc';
        acc.QTB_Legal_Entity_Country__c = 'India';
        acc.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc.ShippingCity = 'TN';
        acc.ShippingState = 'Chennai';
        acc.ShippingPostalCode = '500032';
        acc.ShippingCountry = 'India';
        acc.QTB_Records_Management__c = true;
        acc.Payment_Terms__c = 'Net 30';
        acc.QTB_Legal_Entity__c = indiaEntity.Id;
        acc.QTB_Contract_Entity__c = indiaEntity.Id;
        acc.CurrencyIsoCode = 'INR';
        insert acc;
        accountList.add(acc);
        
        
        QTB_Foreign_Exchange__c fe = new QTB_Foreign_Exchange__c();
        fe.QTB_Start_Date__c = system.today().adddays(-100);
        fe.QTB_End_Date__c = system.today().adddays(100);
        fe.QTB_Currency_From__c = 'INR';
        fe.QTB_Currency_To__c = 'EUR';
        fe.QTB_Rate__c = 10;
        fe.QTB_Tax_Rate_Type__c = 'Corporate';
        insert fe;
        
        Map<Id,blng__CreditNote__c> crdMap = new Map<Id,blng__CreditNote__c>();
        Map<Id,blng__CreditNote__c> crdMap1 = new Map<Id,blng__CreditNote__c>();
        List<blng__CreditNote__c> crdList = new List<blng__CreditNote__c>();
        blng__CreditNote__c crd = new blng__CreditNote__c();
        crd.blng__Account__c = accountList[0].Id;
        crd.QTB_Tax_Override_Amount__c = 10;
        crd.blng__CreditNoteDate__c = System.today();
        crd.QTB_On_Account_Credit__c = true;
        crd.QTB_Reason_Code__c = 'Legacy Credit';
        crd.blng__EffectiveTaxDate__c = system.today();
        //CRD.QTB_Exchange_Rate__c=11;
        
        sbqq.TriggerControl.disable();
        insert crd;
        crdList.add(crd);
        Map<Id, blng__CreditNote__c> crdMapq = new Map<Id, blng__CreditNote__c>();
        QTB_Invoice_For_EU__c a = new QTB_Invoice_For_EU__c();
        a.name='india';
        insert a;
    
        QTB_Invoice_Note_Labels__c invNotesLabels = new QTB_Invoice_Note_Labels__c();
        invNotesLabels.Name='india';
        invNotesLabels.Exchange_Rate__c='a';
        invNotesLabels.Sub_Total__c='b';
        invNotesLabels.VAT__c='c';
        invNotesLabels.Total__c='d';
        insert invNotesLabels;
        Map<String, QTB_Invoice_Note_Labels__c> lstInvoiceNotesLabel = QTB_Invoice_Note_Labels__c.getAll();

        List<blng__CreditNote__c> crdList1 = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Tax_Override_Amt_Local__c,
                                                     QTB_Exchange_Rate__c,blng__Account__r.CurrencyIsoCode,QTB_Total_Amt_Tax_Override_local__c,QTB_Subtotal_local_currency__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__CreditNoteDate__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__Account__r.QTB_Legal_Entity__r.QTB_FX_Tax_Rate_Type__c,
                                                     (select id,blng__TaxCode__c,QTB_Invoice__r.QTB_Exchange_Rate__c,blng__CreditNote__c from blng__CreditNoteCreditLines__r LIMIT 1)
                                                     from blng__CreditNote__c where id=:crd.id];
        for(blng__CreditNote__c crd1 :crdList1){ 
            crd1.QTB_Exchange_Rate__c=11;
            update crd1;
            crdMapq.put(crd1.id,crd1);
            system.debug('@@@@@@@@@@@@@@@@@2'   +crd1);
        }
                //28078
        QTB_CreditNoteHelperUtils.updateExchangeRate(crdMapq,true);
        QTB_CreditNoteHelperUtils.updateNoteOnCreditNote(crdMapq);
        try {
           //28078
           QTB_CreditNoteHelperUtils.updateExchangeRate(null,null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           //28078
           QTB_CreditNoteHelperUtils.updateNoteOnCreditNote(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           //28078
           QTB_CreditNoteHelperUtils.updateDueDate(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           QTB_CreditNoteHelperUtils.calculateTax(null,null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           QTB_CreditNoteHelperUtils.updatePartialCreditNote(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
         try {
           QTB_CreditNoteHelperUtils.commercialCreditNoteCheck(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
         try {
           QTB_CreditNoteHelperUtils.calculateIndividualTaxAmountsOnCreditNoteLines(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
         try {
           QTB_CreditNoteHelperUtils.updateCorrectAmount(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }

    }
}