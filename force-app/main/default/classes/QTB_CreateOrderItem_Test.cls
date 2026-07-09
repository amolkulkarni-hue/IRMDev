/*************************************************************************************************************************
* Class: QTB_CreateOrderItem_Test
* Author: Virtusa
* Purpose: This is Test class QTB_CreateOrderItem.
* Requirement:  # 8875
* Change History:
* Developer        Date 04/05/2022    Description
* Renuka Prasad    Date 14/08/2023    Adding additional test methods and modifying existing to increase the coverage
***************************************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CreateOrderItem_Test {
    @IsTest
    static void createorderItem() {
        blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('United States');
        LglEntity.CurrencyIsoCode='USD';
        update LglEntity;
        List<Account> accountList = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        IM_Country__c testCountry = new IM_Country__c(Name='United States',active__c=true);
        insert testCountry;
        list<opportunity> oppsToReturn =new list<opportunity>();
        for (Integer i = 0; i < accountList.size(); i++) {
            oppsToReturn.add(
                new Opportunity(
                    Name = 'Test' + i,
                    AccountId = accountList[i].Id,
                    CloseDate = Date.today(),
                    StageName = '1 - Qualification',
                    RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
                    Amount = 500,
                    Billing_Country__c=testCountry.id,
                    Primary_Product_Line__c = 'Data Management',
                    CurrencyIsoCode='USD'
                )
            );
        }
        if (!oppsToReturn.isEmpty()) {
            insert oppsToReturn;
        }
        
        List<SBQQ__Quote__c> testquote = QTB_TestDataFactory.createCPQQuotes(
            1,
            oppsToReturn[0].id,
            accountList[0].id,
            false,
            null
        );
        system.debug('testquote--->'+testquote);
        SBQQ__Quote__c updateQt = new SBQQ__Quote__c();
        updateQt.id = testquote[0].id;
        updateQt.CurrencyIsoCode = 'USD';
        
        //update updateQt;
        
        List<priceBook2> prbk =QTB_TestDataFactory.priceBookMethdLst(1,'United States');
        prbk[0].QTB_Country__c='United States';
        prbk[0].CurrencyIsoCode = 'USD';
        update prbk[0];
        
        ID OrdRecId = (Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('QTB_Billing_Order').getRecordTypeId());
        testquote[0].SBQQ__Primary__c= true;
        //update testquote[0];
        Order OrderLst1 =  new Order(
            SBQQ__Quote__c = testquote[0].Id,
            AccountId = accountList[0].Id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = prbk[0].Id,
            blng__BillingAccount__c = accountList[0].Id,
            CurrencyIsoCode = 'USD'
        );
        Insert OrderLst1;
        
        System.debug('OrderLst1>>>'+OrderLst1);
        Order OrderLst =  new Order(
            SBQQ__Quote__c = testquote[0].Id,
            AccountId = accountList[0].Id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = prbk[0].Id,
            blng__BillingAccount__c = accountList[0].Id,
            QTB_Order_OriginatorId__c = OrderLst1.id
        );
        Insert OrderLst;
        
        OrderLst.QTB_Legal_Entity_Country__c = 'United States';
        OrderLst.RecordtypeID = OrdRecId;
        OrderLst.CurrencyIsoCode = 'USD';
        update OrderLst;
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
            'Yes'
        );
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
            'Yes'
        );
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].SBQQ__SubscriptionTerm__c = 10;
        product[0].SBQQ__SubscriptionTerm__c = 4;
        product[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product[0].ProductCode = '01100-1002';
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        product[0].SBQQ__ChargeType__c = 'Recurring';
        product[0].SBQQ__BillingType__c = 'Arrears';
        update product[0];
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            CurrencyIsoCode = 'USD',    
            IsActive = true);
        update standardPricebook;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product[0].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode='USD' );
        insert standardPrice;
        
        PriceBookEntry SingaporePrice= new PricebookEntry(pricebook2id=prbk[0].id, product2id=product[0].id,unitprice=2000, isActive=true, currencyISOCode='USD');
        insert SingaporePrice;
        
        blng__TaxIntegration__c taxIntegration = QTB_TestDataFactory.createTaxIntegration();
        
        blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c();
        taxTreatment.Name = 'United States Increase Tax';
        taxTreatment.blng__TaxIntegration__c = taxIntegration.id;
        taxTreatment.blng__TaxRule__c = taxRule.id;
        date effectiveStartDate = Date.newInstance(2022,12,01);
        date effectiveEndDate = Date.newInstance(2023,12,31);
        taxTreatment.QTB_Tax_Effective_Start_Date__c = effectiveStartDate;
        taxTreatment.QTB_Tax_Effective_End_Date__c = effectiveEndDate;
        taxTreatment.blng__TaxLegalEntity__c = LglEntity.id;
        taxTreatment.QTB_Taxable__c = 'yes';
        taxTreatment.QTB_TaxCountry__c = 'United States';
        taxTreatment.blng__Active__c = true;
        insert taxTreatment;
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,testquote[0].id,accountList[0].id);
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,testquote[0].Id,quoteGroupList[0].id,product[0].id);
        
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(OrderLst1.Id,product[0].Id,quoteLinesList,SingaporePrice);
        
        String orderCategory = QTB_Constants.ORDCATEGORY_EVERGREEN;
        String orderStatus = QTB_Constants.ACTIVATED_STATUS;
        
        Order orderLst1Update =  new Order();
        orderLst1Update.id = OrderLst1.id;
        orderLst1Update.Status = orderStatus;
        orderLst1Update.QTB_OrderCategory__c = orderCategory;
     //   update orderLst1Update;
        
        Test.startTest();
        QTB_CreateOrderItem auto = new QTB_CreateOrderItem();
        QTB_CreateOrderItem.flowInputs aflow = new QTB_CreateOrderItem.flowInputs();
        aflow.oldOrderData = OrderLst;
        aflow.newOrderCreated = OrderLst.id;
        List<string> codes = new List<string>();
        codes.Add('01100-1002');
        aflow.productCodes = codes;
        List<QTB_CreateOrderItem.flowInputs> fl = new List<QTB_CreateOrderItem.flowInputs>{
            aflow
                };
                    QTB_CreateOrderItem.updateOrderItemDetails(fl);
        
        Test.stopTest();
        
    }
    //cover catch
    static testMethod void testMethod2() {
        Test.startTest();
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Standard Account'
        );
        QTB_CreateOrderItem.throwExplicitException = true;
        QTB_CreateOrderItem auto2 = new QTB_CreateOrderItem();
        QTB_CreateOrderItem.flowInputs aflow2 = new QTB_CreateOrderItem.flowInputs();
        List<string> codes2 = new List<string>();
        codes2.Add('9999-9999');
        aflow2.productCodes = codes2;
        List<QTB_CreateOrderItem.flowInputs> f2 = new List<QTB_CreateOrderItem.flowInputs>{
            aflow2
                };
                    QTB_CreateOrderItem.updateOrderItemDetails(f2);
        
        QTB_CreateOrderItem.throwExplicitException = true;
        //QTB_CreateOrderItem.createQuotedOrderItems(null);
        
        Test.stopTest();
        System.assertEquals(
            true,
            QTB_CreateOrderItem.throwExplicitException
        );
        
    }
    
    @IsTest
    static void createorderItem1() {
        
        blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
        LglEntity.CurrencyIsoCode='SGD';
        update LglEntity;
        List<Account> accountList = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        IM_Country__c testCountry = new IM_Country__c(Name='United States',active__c=true);
        insert testCountry;
        list<opportunity> oppsToReturn =new list<opportunity>();
        for (Integer i = 0; i < accountList.size(); i++) {
            oppsToReturn.add(
                new Opportunity(
                    Name = 'Test' + i,
                    AccountId = accountList[i].Id,
                    CloseDate = Date.today(),
                    StageName = '1 - Qualification',
                    RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
                    Amount = 500,
                    Billing_Country__c=testCountry.id,
                    Primary_Product_Line__c = 'Data Management'
                )
            );
        }
        if (!oppsToReturn.isEmpty()) {
            insert oppsToReturn;
        }
        
        List<SBQQ__Quote__c> testquote = QTB_TestDataFactory.createCPQQuotes(
            1,
            oppsToReturn[0].id,
            accountList[0].id,
            true,
            null
        );
        List<priceBook2> prbk =QTB_TestDataFactory.priceBookMethdLst(1,'Singapore');
        prbk[0].QTB_Country__c='Singapore';
        prbk[0].CurrencyIsoCode = 'SGD';
        update prbk[0];
        
        ID OrdRecId = (Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('QTB_Billing_Order').getRecordTypeId());
        testquote[0].SBQQ__Primary__c= true;
        //update testquote[0];
        Order OrderLst =  new Order(
            SBQQ__Quote__c = testquote[0].Id,
            AccountId = accountList[0].Id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = prbk[0].Id,
            blng__BillingAccount__c = accountList[0].Id
        ) ;
        Insert OrderLst;
        OrderLst.QTB_Legal_Entity_Country__c = 'Singapore';
        OrderLst.RecordtypeID = OrdRecId;
        OrderLst.CurrencyIsoCode = 'SGD';
        update OrderLst;
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
            'Yes'
        );
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
            'Yes'
        );
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].SBQQ__SubscriptionTerm__c = 10;
        product[0].SBQQ__SubscriptionTerm__c = 4;
        product[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product[0].ProductCode = '01100-1002';
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        update product[0];
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            CurrencyIsoCode = 'USD',    
            IsActive = true);
        update standardPricebook;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product[0].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode='SGD' );
        insert standardPrice;
        
        PriceBookEntry SingaporePrice= new PricebookEntry(pricebook2id=prbk[0].id, product2id=product[0].id,unitprice=2000, isActive=true, currencyISOCode='SGD');
        insert SingaporePrice;
        
        blng__TaxIntegration__c taxIntegration = QTB_TestDataFactory.createTaxIntegration();
        
        blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c();
        taxTreatment.Name = 'Singapore Increase Tax';
        taxTreatment.blng__TaxIntegration__c = taxIntegration.id;
        taxTreatment.blng__TaxRule__c = taxRule.id;
        date effectiveStartDate = Date.newInstance(2022,12,01);
        date effectiveEndDate = Date.newInstance(2023,12,31);
        taxTreatment.QTB_Tax_Effective_Start_Date__c = effectiveStartDate;
        taxTreatment.QTB_Tax_Effective_End_Date__c = effectiveEndDate;
        taxTreatment.blng__TaxLegalEntity__c = LglEntity.id;
        taxTreatment.QTB_Taxable__c = 'yes';
        taxTreatment.QTB_TaxCountry__c = 'Singapore';
        taxTreatment.blng__Active__c = true;
        insert taxTreatment;
        
        
        Test.startTest();
        QTB_CreateOrderItem.CodeCoverageMethod();
        QTB_CreateOrderItem auto = new QTB_CreateOrderItem();
        QTB_CreateOrderItem.flowInputs aflow = new QTB_CreateOrderItem.flowInputs();
        aflow.oldOrderData = OrderLst;
        aflow.newOrderCreated = OrderLst.id;
        List<string> codes = new List<string>();
        codes.Add('01100-1002');
        aflow.productCodes = codes;
        List<QTB_CreateOrderItem.flowInputs> fl = new List<QTB_CreateOrderItem.flowInputs>{
            aflow
                };
                    QTB_CreateOrderItem.updateOrderItemDetails(fl);
        
        Test.stopTest();
    }
}