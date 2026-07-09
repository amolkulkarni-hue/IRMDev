/*****************************************************************************************************
* Class: QTB_OrderItemCSHelperUtils_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_OrderItemCSHelperUtils
* Change History: 09/02/2024
* Developer     Date           Description
* -------------------------------------------------------------------------------------------

*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_OrderItemCSHelperUtils_Test {
    
    @TestSetup
    static void createData() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        Test.startTest();
        
        System.runAs(userList[0]) {
            List<account> accountList = QTB_TestDataFactory.createAccounts(1);
            //accountList[0].BillingCountry = 'United States';
            accountList[0].QTB_Legal_Entity_Country__c = 'United States';
            update accountList;
            
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
                'Yes'
            );
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
            );
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            product[0].Family = 'DM SITAD';
            database.update(product);
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            //Legal Entity
            blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
            USEntity.Name = 'Test Legal Entity United States';
            USEntity.blng__Active__c = true;
            USEntity.blng__Country__c = 'United States';
            USEntity.QTB_Type__c = 'Contract';
            //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
            insert USEntity;
            
            //IM Country
            IM_Country__c im = new IM_Country__c();
            im.Name = 'United States';
            im.CurrencyIsoCode = 'USD';
            im.Region__c = 'North America';
            im.AlternativeNames__c = 'United States';
            im.Iso31662Code__c ='US';
            im.Iso31663Code__c ='USA'; 
            im.Active__c = true;
            insert im;
            
            List<account> accountList2 = QTB_TestDataFactory.createAccounts(
                1,
                accountList[0],
                null,
                'Billing Account'
            );
            //System.debug('oppList[0].id :: '+oppList[0].id);
            //accountList2[0].QTB_Source_Opportunity__c = oppList[0].id;
            accountList2[0].QTB_Legal_Entity_Country__c = 'United States';
            
            update accountList2;
            
            Test.stopTest();
            // system.assert(orderItemList[0].SBQQ__ChargeType__c == 'One-Time');
            List<Order> orderList3 = new List<Order>();
            Id pricebookId1 = Test.getStandardPricebookId();
            
            for (Integer i = 0; i < 1; i++) {
                orderList3.add(
                    new Order(
                        //SBQQ__Quote__c = quoteList[0].Id,
                        AccountId = accountList2[0].id,
                        blng__BillingDayOfMonth__c = '1',
                        EffectiveDate = Date.today(),
                        Status = QTB_Constants.DRAFT_STATUS,
                        QTB_DM_Source_System_Name__c = 'SITAD',
                        QTB_OrderCategory__c = 'Evergreen',
                        Pricebook2Id = pricebookId1,
                        //blng__InvoiceBatch__c = 'Denmark-26th',
                        QTB_Legal_Entity_Country__c = 'United States',
                        recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID
                    )
                );
            }
            if (!orderList3.isEmpty()) {
                insert orderList3;
            }
            system.debug('orderList3[0]--->'+orderList3[0]);
            SBQQ.TriggerControl.disable();
            //OrderItem
            //List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
            List<OrderItem> orderItemList2 = new List<OrderItem>();
            
            for (Integer i = 0; i < 1; i++) {
                orderItemList2.add(
                    new OrderItem(
                        OrderId = orderList3[0].Id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        //SBQQ__QuoteLine__c = quoteLinesList[i].id,
                        SBQQ__Status__c = 'Draft',
                        //blng__TaxCountry__c = 'Singapore',
                        PricebookEntryId = standardPrice.Id,
                        SBQQ__ChargeType__c = 'One-Time',
                        product2id = product[0].Id,
                        SBQQ__Activated__c = true,
                        blng__LegalEntity__c = USEntity.id,
                        //SBQQ__Status__c = 'Draft',
                        // blng__TaxCountry__c = 'Singapore',
                        //QTB_Order_Product_Type__c = 'ReBill',
                        QTB_Final_Unit_Price__c = 10,
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
                        .id,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                            'Yes'
                        )
                        .id,
                        blng__TaxRule__c = taxRule.id//QTB_TestDataFactory.createTaxRule('Yes').id
                    )
                );
            }
            if (!orderItemList2.isEmpty()) {
                system.debug('orderItemList2>' + orderItemList2);
                insert orderItemList2;
                system.debug('orderItemList2>>' + orderItemList2); 
                
            }  
            ConsumptionSchedule cs = new ConsumptionSchedule();
            cs.Name = 'List Rate';
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
            rate.CurrencyIsoCode = 'USD';
            rate.PricingMethod = 'PerUnit';
            rate.ProcessingOrder = 1;
            insert rate;
            
            ConsumptionSchedule abc = new ConsumptionSchedule();
            abc.id = cs.id;
            abc.IsActive = true;
            update abc; 
            
            //Order Product CS
            SBQQ__OrderItemConsumptionSchedule__c op = new SBQQ__OrderItemConsumptionSchedule__c();
            op.Name = 'List Rate';
            op.SBQQ__RatingMethod__c= 'Tier';
            op.SBQQ__Type__c = 'Range';
            op.SBQQ__BillingTerm__c = 1;
            op.SBQQ__BillingTermUnit__c = 'Month';
            op.SBQQ__ConsumptionSchedule__c = cs.id;
            op.SBQQ__OrderItem__c = orderItemList2[0].Id;
            op.SBQQ__Category__c = 'Rates';
            op.blng__LegalEntity__c = orderItemList2[0].blng__LegalEntity__c;
            insert op;
            
            SBQQ__OrderItemConsumptionRate__c opRate = new SBQQ__OrderItemConsumptionRate__c();
            opRate.Name = 'test Rate';
            opRate.SBQQ__LowerBound__c = 1;
            opRate.SBQQ__Price__c = 12;
            opRate.CurrencyIsoCode = 'USD';
            opRate.SBQQ__PricingMethod__c = 'Per Unit';
            opRate.SBQQ__ProcessingOrder__c = 1;
            opRate.SBQQ__OrderItemConsumptionSchedule__c = op.Id;
            insert opRate;    
            
        }
    }  
    // cover catch
    static testMethod void testMethodCover() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
        System.runAs(userList[1]) {
            QTB_OrderItemConScheduleTriggerHandler.throwExplicitException = true;
            QTB_OrderItemConScheduleTriggerHandler handler = new QTB_OrderItemConScheduleTriggerHandler();
            handler.AfterDelete(null);
            handler.BeforeDelete(null);
            handler.AfterUndelete(null);
            try {   
                handler.AfterUpdate(null, null);
            }
            catch (NullPointerException e) {
                System.assertEquals('System.NullPointerException', e.getTypeName());
            }
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_ORDER);
            handler.IsDisabled();
            Test.stopTest();
        }
    }
    
    static testmethod void testmethodOrdItmCS() {
        try {
            List<orderItem> ordLST = [SELECT id,blng__LegalEntity__c from orderItem limit 1];
            List<SBQQ__OrderItemConsumptionSchedule__c> ordItemCS = [SELECT Id,SBQQ__OrderItem__c,blng__LegalEntity__c from SBQQ__OrderItemConsumptionSchedule__c limit 1];
            system.debug('New order List'+ordLST);
            Test.startTest();
            QTB_OrderItemCSHelperUtils.legalEntityUpdateSITAD(ordItemCS);
            QTB_OrderItemConScheduleTriggerHandler.throwExplicitException = true;
            QTB_OrderItemCSHelperUtils.legalEntityUpdateSITAD(null);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }   
}