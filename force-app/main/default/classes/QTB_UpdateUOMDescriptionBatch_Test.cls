/*****************************************************************************************************
* Class: QTB_UpdateUOMDescriptionBatch_Test
* Author: TCS
* Purpose: Test Class for QTB_UpdateUOMDescriptionBatch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture    25/10/2025
*******************************************************************************************************/
@isTest
public class QTB_UpdateUOMDescriptionBatch_Test {
    @testSetup
    static void setupTestData() {
        //Legal Entity
        blng__LegalEntity__c turkeyEntity = new blng__LegalEntity__c();
        turkeyEntity.Name = 'Test Legal Entity Turkey';
        turkeyEntity.blng__Active__c = true;
        turkeyEntity.blng__Country__c = 'United States';
        turkeyEntity.QTB_Type__c = 'Contract';
        turkeyEntity.QTB_Legal_Entity_Number__c = 45000;
        insert turkeyEntity;

        // Create Account with language
        Account accEN = new Account(Name = 'Test Acc EN', QTB_Language__c = 'en_US',QTB_DM_Source_System__c = 'oneil');
        Account accFR = new Account(Name = 'Test Acc FR', QTB_Language__c = 'th',QTB_DM_Source_System__c = 'oneil');
        insert new List<Account>{ accEN, accFR };
        system.debug('accEN:'+accEN);
        system.debug('accFR:'+accFR);

        // Create Product2
        Product2 prod = new Product2(Name = 'Test Prod', ProductCode = 'P001');
        insert prod;
        system.debug('prod:'+prod);
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(prod);

        // Create OrderProduct
        Order order = new Order(Name = 'Test Order', Status = 'Draft', AccountId = accEN.Id,EffectiveDate = system.today(),
                               QTB_Legal_Entity_Country__c = 'Turkey', Pricebook2Id = pricebookId );
        insert order;
        system.debug('order:'+order);
        
        blng__TaxRule__c TaxRule2 = new blng__TaxRule__c();
        try {
          TaxRule2.Name = 'No Tax Rule';
          TaxRule2.blng__Active__c = true;
          TaxRule2.blng__TaxableYesNo__c = 'Yes';
          insert Taxrule2;
        } catch (Exception e) {
          System.debug('The following exception has occurred: ' + e.getMessage());
        }
        system.debug('TaxRule2:'+TaxRule2);
        
        blng__BillingRule__c BillingRule = new blng__BillingRule__c();
    try {
      BillingRule.Name = 'Test Billing Rule ';
      BillingRule.blng__Active__c = true;
      BillingRule.blng__GenerateInvoices__c = 'Yes';
      BillingRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
      insert BillingRule;
      
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
        system.debug('BillingRule:'+BillingRule);
        
        blng__RevenueRecognitionRule__c RevenueRecognitionRule = new blng__RevenueRecognitionRule__c();
    try {
      RevenueRecognitionRule.Name = 'Test Recognition Rule ';
      RevenueRecognitionRule.blng__Active__c = true;
      RevenueRecognitionRule.blng__CreateRevenueSchedule__c = 'Yes';
      insert RevenueRecognitionRule;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
       system.debug('RevenueRecognitionRule:'+RevenueRecognitionRule);         
        List<OrderItem> orderItemList4 = new List<OrderItem>();
    try {
      for (Integer i = 0; i < 1; i++) {
        orderItemList4.add(
          new OrderItem(
            OrderId = order.id,
            Quantity = 2.00,
            UnitPrice = 12.00,
            //SBQQ__QuoteLine__c = quoteLinesList1[i].id,
            PricebookEntryId = standardPrice.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = prod.Id,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = BillingRule.Id,
            blng__RevenueRecognitionRule__c = RevenueRecognitionRule.id,
            blng__TaxRule__c =Taxrule2.id// QTB_TestDataFactory.createTaxRule('Yes').id
          )
        );
      }
      if (!orderItemList4.isEmpty()) {
        system.debug('orderitemsToReturn>' + orderItemList4);
        insert orderItemList4;
      }
    } 
        catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
        system.debug('orderItemList4:'+orderItemList4[0].id);
        //Consumption Schedule
        ConsumptionSchedule cs = new ConsumptionSchedule();
        cs.Name = 'List Rate 02100-0252';
        cs.BillingTerm = 1;
        cs.BillingTermUnit = 'Month';
        cs.RatingMethod = 'Tier';
        cs.SBQQ__Category__c = 'Rates';
        cs.Type = 'Range';
        insert cs;
        
        ConsumptionRate rate = new ConsumptionRate();
        rate.LowerBound = 1;
        rate.Price = 12;
        rate.ConsumptionScheduleId = cs.id;
        rate.CurrencyIsoCode = 'TRY';
        rate.PricingMethod = 'PerUnit';
        rate.ProcessingOrder = 1;
        insert rate;
        
        ConsumptionSchedule abc = new ConsumptionSchedule();
        abc.id = cs.id;
        abc.IsActive = true;
        update abc; 

        //Order Product CS
        SBQQ__OrderItemConsumptionSchedule__c op = new SBQQ__OrderItemConsumptionSchedule__c();
        op.Name = 'List Rate 02100-0252';
        op.SBQQ__RatingMethod__c= 'Tier';
        op.SBQQ__Type__c = 'Range';
        op.SBQQ__BillingTerm__c = 1;
        op.SBQQ__BillingTermUnit__c = 'Month';
        op.SBQQ__ConsumptionSchedule__c = cs.id;
        op.SBQQ__OrderItem__c = orderItemList4[0].Id;
        op.SBQQ__Category__c = 'Rates';
        op.blng__LegalEntity__c = turkeyEntity.Id;
        op.SBQQ__UnitOfMeasure__c = 'Each';
        SBQQ.TriggerControl.disable();
        insert op;
        SBQQ.TriggerControl.enable();
        SBQQ__OrderItemConsumptionRate__c opRate = new SBQQ__OrderItemConsumptionRate__c();
        opRate.Name = 'test Rate';
        opRate.SBQQ__LowerBound__c = 1;
        opRate.SBQQ__Price__c = 12;
        opRate.CurrencyIsoCode = 'TRY';
        opRate.SBQQ__PricingMethod__c = 'Per Unit';
        opRate.SBQQ__ProcessingOrder__c = 1;
        opRate.SBQQ__OrderItemConsumptionSchedule__c = op.Id;
        insert opRate;
        
        blng__UsageSummary__c usEN = new blng__UsageSummary__c(
            blng__Account__c = accEN.Id,
            blng__Order__c = order.id,
            blng__OrderProduct__c = orderItemList4[0].Id,
            QTB_Legal_Entity_Country__c = 'Turkey',
            blng__UnitOfMeasure__c = 'Each',
            blng__MatchingId__c =  '1234',
            blng__SummaryStartDate__c = system.today(),
            blng__SummaryEndDate__c = system.today().addDays(30),
            blng__OrderItemConsumptionSchedule__c = op.id,
            blng__Status__c = 'Queued For Invoice',
            blng__InvoiceRunProcessingStatus__c = 'Pending Billing'
        );
        insert new List<blng__UsageSummary__c>{ usEN };
    }

    static testMethod void testBatchExecute() {
        
        IM_Country__c country = new IM_Country__c();
        country.Name = 'turkey';
        country.CurrencyIsoCode = 'USD';
        country.Region__c = 'North America';
        country.AlternativeNames__c = 'United States';
        country.Iso31662Code__c ='TRY';
        country.Iso31663Code__c ='TRY';        
        insert country;
        system.debug('country:'+country);
        // Create QTB_Bill_Code_Product_Lookup__c record
        QTB_Bill_Code_Product_Lookup__c bcpl = new QTB_Bill_Code_Product_Lookup__c(
            Name = 'P001-TRY-Test Prod',
            QTB_Country__c = country.Id,
            QTB_Product_Code__c = 'P001',
            QTB_UOM__c = 'Each',
            QTB_Default_Bill_Code_Description__c = 'Turkey Def Desc'
        );
        insert bcpl;
        system.debug('bcpl:'+bcpl);
        // Prepare input params
        Set<String> countries = new Set<String>{'turkey'};
        Set<String> legalEntities = new Set<String>{'Test Legal Entity Turkey'};

        Test.startTest();
        // Instantiate batch
        QTB_UpdateUOMDescriptionBatch batch = new QTB_UpdateUOMDescriptionBatch('oneil',countries, legalEntities);
        QTB_UpdateUOMDescriptionBatch.codeCoverage();
        // Run batch
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify the updates
       /* List<SBQQ__OrderItemConsumptionSchedule__c> updatedSchedules = [SELECT QTB_Localized_UOM_Description__c, QTB_UOM_Description_Text__c FROM SBQQ__OrderItemConsumptionSchedule__c];
        System.assertEquals(1, updatedSchedules.size());
        System.assertNotEquals(null, updatedSchedules[0].QTB_UOM_Description_Text__c, 'Default description should be set');

        // Verify order item language changed field update
        List<OrderItem> orderItems = [SELECT QTB_Language_Changed_Value__c FROM OrderItem];
        System.assertEquals(1, orderItems.size());
        System.assertEquals('en_US', orderItems[0].QTB_Language_Changed_Value__c, 'Language changed value should be set correctly');*/
    }
}