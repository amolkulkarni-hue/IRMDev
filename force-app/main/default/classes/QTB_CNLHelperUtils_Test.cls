/*****************************************************************************************************
* Class: QTB_CNLHelperUtils_Test
* Author: Virtusa
* Purpose: Test Class for QTB_CNLHelperUtils
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Parth   		05/15/2023		to cover calculateIndividualTaxAmountsOnCreditNoteLines, buildTaxRateMap, calculateTax method
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CNLHelperUtils_Test {
    
    @TestSetup
    static void setup() {
        QTB_Tax_Integration_Setting__mdt vertexData = new QTB_Tax_Integration_Setting__mdt();
        vertexData.Label = 'Vertex';
        vertexData.DeveloperName = 'Vertex_Integration';
        vertexData.QTB_Country__c = 'United States;Canada';
        vertexData.QTB_End_System__c = 'Vertex';
        
        
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
        sbqq.TriggerControl.disable();
        insert invoice;
        system.debug('invoice-->'+invoice);
        //List<blng__InvoiceLine__c> invoiceLineListForCredit = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        Product2 prod = productList[0];
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = prod.Name;
        invoiceLine.blng__Invoice__c = invoice.Id;
        invoiceLine.blng__Product__c = prod.Id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__Subtotal__c = 50;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__TaxPercentageApplied__c = 24;
        //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
        invoiceLine.QTB_Tax_Override_Amount__c = 10;
        invoiceLine.blng__TaxCountry__c = 'India';
        insert invoiceLine;
        sbqq.TriggerControl.enable();
        system.debug('invoiceLine--->'+invoiceLine);
        //system.debug('invoiceLineListForCredit->'+invoiceLineListForCredit[0]);
        /*invoiceLineListForCredit[0].QTB_Tax_Override_Amount__c = 10;
List<blng__CreditNote__c> creditNoteWithInvRefList = QTB_TestDataFactory.createCreditNote(accountList);
List<blng__CreditNoteLine__c> cnlWithInvLst = QTB_TestDataFactory.createCreditNoteLine(1,accountList[0],creditNoteWithInvRefList[0],invoiceListForCredit[0],invoiceLineListForCredit[0],productList[0]);
system.debug('cnlWithInvLst->'+cnlWithInvLst[0]);
system.debug('cnlWithInvLst->'+cnlWithInvLst[0].QTB_invoiceline__c);*/
        
        // Create Credit Note
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.QTB_On_Account_Credit__c = true;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'INR';
        creditNotesList.add(creditNote1);
        blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
        creditNote2.blng__Account__c = accountList[1].Id;
        creditNote2.QTB_On_Account_Credit__c = false;
        creditNote2.blng__CreditNoteDate__c = date.today();
        creditNote2.QTB_Reason_Code__c = 'Bankruptcy';
        creditNote2.blng__Status__c = 'Draft';
        creditNote2.CurrencyIsoCode = 'INR';
        creditNotesList.add(creditNote2);
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
        cnl1.blng__TaxPercentageApplied__c = 9;
        creditNoteLineList.add(cnl1);
        
        blng__CreditNoteLine__c cnl2 = new blng__CreditNoteLine__c();
        cnl2.QTB_Account__c = accountList[1].Id;
        cnl2.blng__CreditNote__c = creditNotesList[1].id;
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
        //sbqq.triggerControl.enable();
        System.debug('setup_creditNoteLineList2@@'+creditNoteLineList);
        system.debug('validation check--->'+ creditNoteLineList[0].QTB_country__c+creditNoteLineList[0].CurrencyIsoCode+creditNoteLineList[0].blng__Product__c);
        
        // Inserting Order
        Order tempOrder = new Order();
        tempOrder.AccountId = accountList[0].id;
        tempOrder.CurrencyIsoCode = 'INR'; 
        tempOrder.EffectiveDate = system.today();
        tempOrder.Pricebook2Id = prbk[0].id;
        tempOrder.QTB_Legal_Entity_Country__c = 'India';
        tempOrder.QTB_OrderCategory__c = 'Evergreen';
        tempOrder.SBQQ__PaymentTerm__c = accountList[0].Payment_Terms__c;
        tempOrder.ShippingCity = accountList[0].ShippingCity;      
        tempOrder.ShippingCountry = accountList[0].ShippingCountry; 
        tempOrder.ShippingPostalCode = accountList[0].ShippingPostalCode;
        tempOrder.ShippingState = accountList[0].ShippingState; 
        tempOrder.ShippingStreet = accountList[0].ShippingStreet;
        tempOrder.Status = 'Draft';
        tempOrder.Type = 'New';
        tempOrder.blng__BillingDayOfMonth__c = '1';  
        tempOrder.blng__InvoiceBatch__c ='India-1st';
        insert tempOrder;
        
        // Inserting OrderItem
        OrderItem temporderitem = new OrderItem();
        temporderitem.OrderId = tempOrder.id;
        temporderitem.Product2Id = productList[0].Id;
        temporderitem.Quantity = 1;
        temporderitem.SBQQ__BillingFrequency__c = productList[0].SBQQ__BillingFrequency__c;
        temporderitem.SBQQ__BillingType__c = productList[0].SBQQ__BillingType__c;
        temporderitem.SBQQ__ChargeType__c = productList[0].SBQQ__ChargeType__c;
        temporderitem.SBQQ__ProductSubscriptionType__c = 'Evergreen';
        temporderitem.SBQQ__Status__c = 'Draft';
        temporderitem.SBQQ__SubscriptionTerm__c= productList[0].SBQQ__SubscriptionTerm__c;
        temporderitem.ServiceDate = system.today();
        temporderitem.UnitPrice = 0;
        temporderitem.blng__BillingRule__c = productList[0].blng__BillingRule__c;
        temporderitem.blng__LegalEntity__c = indiaEntity.id;
        temporderitem.PricebookEntryId = IndiaPrice.Id;
        temporderitem.blng__RevenueRecognitionRule__c = productList[0].blng__RevenueRecognitionRule__c;
        temporderitem.SBQQ__DefaultSubscriptionTerm__c = productList[0].SBQQ__SubscriptionTerm__c;
        temporderitem.SBQQ__SubscriptionType__c = 'Evergreen';
        temporderitem.blng__BillableUnitPrice__c= 0;
        temporderitem.blng__TaxCountry__c = 'India';
        temporderitem.blng__TaxRule__c = taxRule.id;
        temporderitem.blng__LegalEntity__c = indiaEntity.Id;
        temporderitem.Product2Id = productList[0].id;
        temporderitem.SBQQ__BillingFrequency__c = 'Monthly';
        temporderitem.QTB_Payment_Term__c = '30';
        SBQQ.TriggerControl.disable();
        insert temporderitem;
        SBQQ.TriggerControl.enable();
    }
    
    static testmethod void testMethod1(){
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Product__c,QTB_Account__c,blng__TaxRule__c,blng__BillingRule__c,blng__TaxCountry__c,
                                                QTB_country__c,currencyisocode,blng__Status__c,blng__LegalEntity__c,blng__TaxTreatment__c,QTB_SITAD__c,blng__creditNote__r.QTB_On_Account_Credit__c,
                                                blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__r.blng__TotalAmount__c,QTB_InvoiceLine__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Product_Name__c,QTB_Billing_Account__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' limit 1];
        Set<id> accountIds = new Set<Id>();
        Set<id> productIds = new Set<Id>();
        Set<String> cnlCurriences = new Set<String>();
        Set<String> cnlCountries = new Set<String>();
        for(blng__CreditNoteLine__c cnl:cnlList1){
            accountIds.add(cnl.QTB_Account__c);
            productIds.add(cnl.blng__Product__c);
            cnlCountries.add(cnl.QTB_country__c);
            cnlCurriences.add(cnl.currencyisocode);   
        }
        test.startTest();
        QTB_CNLHelperUtils.validateProductForBillingCountries(cnlList1,accountIds,cnlCountries,cnlCurriences);
        QTB_CNLHelperUtils.updateTaxInfoForOnAccountCreditNote(cnlList1,accountIds,productIds);
        test.stopTest();
        try {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.updateTaxInfoForOnAccountCreditNote(null,null,null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.validateProductForBillingCountries(null,null,null,null); 
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
    }  
    
    //cover SITAD scenario
    static testmethod void testMethod2(){
        List<Account> acSITAD = [select id,QTB_SITAD__c from Account Limit 1];
        acSITAD[0].QTB_SITAD__c=true;
        update acSITAD[0];
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__creditNote__r.QTB_On_Account_Credit__c,blng__Product__c,QTB_Account__c,blng__TaxRule__c,blng__BillingRule__c,blng__TaxCountry__c,
                                                QTB_country__c,currencyisocode,blng__Status__c,blng__LegalEntity__c,blng__TaxTreatment__c,QTB_SITAD__c,
                                                blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__r.blng__TotalAmount__c,QTB_InvoiceLine__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Product_Name__c,QTB_Billing_Account__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' limit 1];
        Set<id> accountIds = new Set<Id>();
        Set<id> productIds = new Set<Id>();
        Set<String> cnlCurriences = new Set<String>();
        Set<String> cnlCountries = new Set<String>();
        for(blng__CreditNoteLine__c cnl:cnlList1){
            accountIds.add(cnl.QTB_Account__c);
            productIds.add(cnl.blng__Product__c);
        }
        test.startTest();
        QTB_CNLHelperUtils.updateTaxInfoForOnAccountCreditNote(cnlList1,accountIds,productIds);
        test.stopTest();
    }
    static testMethod void testMethod3(){
        set<Id>cnlId = new Set<Id>();
        set<Id>cnlInvSet = new Set<Id>();
        set<string>cnlAddressComparison = new Set<String>();
        list<blng__CreditNoteLine__c> cnlLst = new list<blng__CreditNoteLine__c>();
        for(blng__CreditNoteLine__c cnl :[select id,QTB_Invoice__r.blng__Subtotal__c,blng__CreditNote__c,blng__Product__c,QTB_Account__c,blng__TaxRule__c,blng__BillingRule__c,blng__TaxCountry__c,
                                          blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,blng__TaxTreatment__r.blng__TaxCode__c,QTB_country__c,QTB_InvoiceLine__r.blng__Subtotal__c,QTB_InvoiceLine__r.QTB_Tax_Override_Amount__c,
                                          blng__TaxTreatment__r.blng__TaxLegalEntity__c,currencyisocode,blng__Status__c,blng__LegalEntity__c,blng__TaxTreatment__c,QTB_SITAD__c,QTB_Invoice__r.QTB_Tax_Override_Amount__c,
                                          blng__Subtotal__c,blng__CreditNote__r.QTB_On_Account_Credit__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__r.blng__TotalAmount__c,QTB_InvoiceLine__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Product_Name__c,QTB_Billing_Account__c, 
                                          blng__CreditNote__r.blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c
                                          from blng__CreditNoteLine__c
                                          where blng__Status__c != 'Posted' ])
        {
            if(cnl.QTB_Invoice__c == null){
                system.debug('Invoice null');
                cnlId.add(cnl.blng__CreditNote__r.id);
            }
            else{
                system.debug('Invoice not null');
                cnlInvSet.add(cnl.blng__CreditNote__r.Id);
            }
            if(cnl.blng__TaxCountry__c == null){
                cnl.blng__TaxCountry__c = 'India';
                cnlLst.add(cnl);
            }
            system.debug('method3 ->'+cnl.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c);
            String cnlComparison =
                cnl.blng__TaxCountry__c +'-' +
                cnl.blng__TaxState__c +'-' +
                cnl.blng__TaxCity__c +'-' +
                cnl.blng__TaxZipCode__c +'-' +
                cnl.blng__TaxTreatment__r.blng__TaxCode__c +'-' +
                cnl.blng__LegalEntity__c;
            //remove null from string
            cnlComparison = cnlComparison.replaceAll('null','');
            cnlAddressComparison.add(cnlComparison);
            //cnl.blng__CreditNote__r.QTB_On_Account_Credit__c = true;
        }
        update cnlLst;
        test.startTest();
        QTB_CNLHelperUtils.OnAccountCreditNoteTaxRounding(cnlId,cnlAddressComparison);
        QTB_CNLHelperUtils.taxRoundingOnCreditNote(cnlInvSet);
        blng__LegalEntity__c indenty = [Select id,QTB_Tax_Applicability__c from blng__LegalEntity__c limit 1];//,QTB_Tax_Type__c
        indenty.QTB_Tax_Applicability__c = 'Product Based';
        update indenty;
        
        QTB_CNLHelperUtils.OnAccountCreditNoteTaxRounding(cnlId,cnlAddressComparison);
        QTB_CNLHelperUtils.taxRoundingOnCreditNote(cnlInvSet);
        test.stopTest();
        
        try {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.OnAccountCreditNoteTaxRounding(null,null);
            QTB_CNLHelperUtils.taxRoundingOnCreditNote(null);
        } catch (Exception e) {
            System.debug('testmethod3_Exception1@@'+ e.getMessage());
        }
    }
    static testmethod void testMethod4(){
        List<account>accList = [Select Id,QTB_Language__c from Account Limit 1];
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Product__c,QTB_Price_Schedule_Category__c,QTB_Translated_UOM__c,QTB_AccountLanguage__c, QTB_UOM__c,QTB_Translated_Product_Group__c,QTB_Localized_Product_Name__c,blng__TaxCountry__c from blng__CreditNoteLine__c
                                                where blng__CreditNote__r.blng__Account__c in :accList limit 1];
        system.debug('account language--->'+accList[0].QTB_Language__c);
        system.debug('QTB_UOM__c--->'+cnlList1[0].QTB_UOM__c);
        test.startTest();
        QTB_CNLHelperUtils.setTranslationFieldsOnCNL(cnlList1,null);
        QTB_CNLHelperUtils.setTranslationFieldsOnCNL(null,accList);
        QTB_CNLHelperUtils.setProductNameTranslation(cnlList1,null);
        QTB_CNLHelperUtils.setProductNameTranslation(null,accList);
        test.stopTest();
        
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.setTranslationFieldsOnCNL(null,null);
        }
        catch(Exception e){
            System.debug('testmethod4_Exception--->'+ e.getMessage());
        }
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.updateUOMOnCNL(null);
        }
        catch(Exception e){
            System.debug('testmethod4_updateUOMOnCNLException--->'+ e.getMessage());
        }
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.updateLocalisedProductName(null,null);
        }
        catch(Exception e){
            System.debug('testmethod4_updateLocalisedProductNameException--->'+ e.getMessage());
        }
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.updateTranslatedProductGroup(null,'');
        }
        catch(Exception e){
            System.debug('testmethod4_updateTranslatedProductGroupNameException--->'+ e.getMessage());
        }
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.setProductNameTranslation(null,null);
        }
        catch(Exception e){
            System.debug('testmethod4_setProductNameTranslation_Exception--->'+ e.getMessage());
        }
    }
    static testmethod void testMethod5(){
        //Set<Id> cnlIds = new Set<Id>();
        List<blng__creditNoteLine__c>cnlLst = [Select Id,blng__creditNote__c,QTB_Invoice__c,QTB_Invoice__r.QTB_TaxDate__c from blng__CreditNoteLine__c where QTB_Invoice__c != null limit 1];
        system.debug('test method 5->'+cnlLst);
        if(!cnlLst.isEmpty()){
            /*for(blng__creditNoteLine__c cnl :cnlLst){
                cnlIds.add(cnl.Id);
            }*/
            QTB_cnlHelperUtils.updateTaxDateOnCreditNote(cnlLst);
        }
        try{
           QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelperUtils.updateTaxDateOnCreditNote(null); 
        }catch(exception e){
            System.debug('testmethod5_updateTaxDateOnCreditNote--->'+ e.getMessage());
        }
        
    }
    
}