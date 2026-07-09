@IsTest
private class QTB_CreditRebillService_Test {
    @TestSetup
    static void makeData() {
        Profile customSysAdmin = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'//'IM_Custom Sys Admin'
        ];
        // create user
        User billingUser = new User(
            profileId = customSysAdmin.Id,
            LastName = 'last',
            Email = 'testuser@test.example.com',
            Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Country = 'USA',
            MobilePhone = '+1 9999999999',
            Phone = '9999999999'
        );
        insert billingUser;
        PermissionSetLicense cpq = [
            SELECT Id, MasterLabel
            FROM PermissionSetLicense
            WHERE MasterLabel = 'Salesforce CPQ License'
        ];
        // assign cpq license
        insert new PermissionSetLicenseAssign(
            AssigneeId = billingUser.Id,
            PermissionSetLicenseId = cpq.Id
        );
        // assign billing user permission
        PermissionSet billingUserPermission = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = 'QTB_Billing_User'
        ];
        insert new PermissionSetAssignment(
            AssigneeId = billingUser.id,
            PermissionSetId = billingUserPermission.Id
        );
        Test.startTest();
        System.runAs(billingUser) {
            IM_Country__c finland = new IM_Country__c(
                Iso31662Code__c = 'FI',
                Iso31663Code__c = 'FIN',
                Name = 'Finland',
                Region__c = 'Europe'
            );
            insert finland;
            insert new IM_Alternative_Country_Name__c(
                IM_Country__c = finland.Id,
                Alternative_Name__c = finland.Name
            );
            blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
            LglEntity.CurrencyIsoCode='SGD';
            update LglEntity;
            QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
            setting.name = 'Singapore';
            setting.Active__c = true;
            setting.Legal_entity_country__c = 'Singapore';
            insert setting;
            Account company = new Account(
                Name = 'Test Factory',
                BillingCountry = 'Finland',
                BillingPostalCode = '681000',
                ShippingCountry = 'Finland',
                QTB_Legal_Entity_Country__c='Finland'
            );
            insert company;
            blng__BillingRule__c billingRule = new blng__BillingRule__c(
                Name = 'Factory Billing Rule',
                blng__Active__c = true,
                blng__GenerateInvoices__c = 'Yes',
                blng__InitialBillingTrigger__c = 'Order Product Activation Date'
            );
            insert billingRule;
            blng__TaxRule__c taxRule = new blng__TaxRule__c(
                Name = 'Factory Tax Rule',
                blng__Active__c = true,
                blng__TaxableYesNo__c = 'Yes'
            );
            insert taxRule;
            blng__RevenueRecognitionRule__c revenueRule = new blng__RevenueRecognitionRule__c(
                Name = 'Test Recognition Rule',
                blng__Active__c = true,
                blng__CreateRevenueSchedule__c = 'Yes'
            );
            insert revenueRule;
            
            
            Product2 product = new Product2(
                Name = 'Rebill Product',
                isActive = true,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                blng__BillingRule__c = billingRule.Id,
                blng__TaxRule__c = taxRule.Id,
                blng__RevenueRecognitionRule__c = revenueRule.Id,
                SBQQ__HasConsumptionSchedule__c = true
            );
             insert product;
              PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = product.Id,
                UnitPrice = 10,
                IsActive = true
            );
            insert pbe;
            ConsumptionSchedule consumption = new ConsumptionSchedule();
            consumption.Name = 'dummy';
            consumption.RatingMethod = 'Tier';
            consumption.Type = 'Range';
            consumption.SBQQ__Category__c = 'Rates';
            consumption.BillingTerm = 10;
            consumption.BillingTermUnit = 'Month';
            insert consumption;
            
            ConsumptionRate conrate = new ConsumptionRate();
            conrate.ProcessingOrder = 1;
            conrate.PricingMethod = 'PerUnit';
            conrate.LowerBound = 1;
            conrate.Price = 100;
            conrate.ConsumptionScheduleId = consumption.Id;
            insert conrate;
            
            consumption.IsActive = true;
            update consumption;
            
            insert new ProductConsumptionSchedule(
                ConsumptionScheduleId = consumption.Id,
                ProductId = product.Id
            );
            
            
           
          
            Order order = new Order(
                AccountId = company.Id,
                blng__BillingDayOfMonth__c = '27',
                EffectiveDate = Date.today().addDays(5),
                Status = QTB_Constants.DRAFT_STATUS,
                Pricebook2Id = Test.getStandardPricebookId(),
                blng__InvoiceBatch__c = 'Finland-26th'
            );
            insert order;
            order.QTB_Legal_Entity_Country__c = 'Singapore';
            order.QTB_OrderCategory__c = 'Rebill';
            database.update(order);
            OrderItem orderProduct = new OrderItem(
                OrderId = order.Id,
                Quantity = 1.00,
                UnitPrice = 10.00,
                PricebookEntryId = pbe.Id,
                SBQQ__ChargeType__c = 'One-Time',
                product2id = product.Id,
                SBQQ__Activated__c = true,
                blng__BillingRule__c = billingRule.Id,
                blng__RevenueRecognitionRule__c = revenueRule.Id,
                blng__TaxRule__c = taxRule.Id,
                ServiceDate = Date.today().addDays(5),
                EndDate = System.today().addDays(126),
                QTB_Order_Product_Type__c = 'ReBill',
                blng__TaxCountry__c = 'Singapore'
            );
            insert orderProduct;
            blng__Invoice__c invoice = new blng__Invoice__c(
                blng__Account__c = company.Id,
                blng__InvoiceStatus__c = 'Draft'
            );
            insert invoice;
            
            List<blng__UsageSummary__c> usageSum2 = QTB_TestDataFactory.createUsageSummary(1,company,order,orderProduct);
            blng__UsageSummary__c usagesummary2 = usageSum2[0];        
            usagesummary2.blng__Status__c = 'Queued For Invoice';
            usagesummary2.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary2.blng__Subtotal__c = 100;
            usagesummary2.blng__TotalQuantity__c = 10;
            usagesummary2.blng__PreratedQuantity__c = 20;
            usagesummary2.blng__UnbilledQuantity__c = 1;
            usagesummary2.blng__UnitPrice__c = 400;
            usagesummary2.blng__PreratedAmount__c = 22;
            usagesummary2.blng__Invoice__c = invoice.id;
            database.update(usagesummary2);
            
            
            List<blng__Usage__c> usageList2 = QTB_TestDataFactory.createUsages(1,company,usagesummary2);
            usageList2[0].QTB_System_Generated__c = true;
            usageList2[0].blng__PreratedAmount__c = 100;
            usageList2[0].blng__PreratedQuantity__c = 10;
            usageList2[0].QTB_Service_District__c = '44147';
            usageList2[0].blng__Subtotal__c = 50;
            usageList2[0].blng__OrderProduct__c = orderProduct.id;          
            database.update(usageList2);
            
            
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(
                Name = product.Name,
                blng__Invoice__c = invoice.Id,
                blng__Product__c = product.Id,
                blng__UsageSummary__c = usagesummary2.id,
                blng__OrderProduct__c = orderProduct.Id,
                QTB_Taxable_Amount__c = 10,
                blng__InvoiceLineStatus__c = 'Draft',
                blng__Quantity__c = 10,
                blng__UnitPrice__c = 5,
                blng__TaxPercentageApplied__c = 24,
                blng__Subtotal__c = 50,
                blng__TotalAmount__c = 50 * 0.24,
                blng__StartDate__c = Date.today().addDays(-30),
                blng__EndDate__c = Date.today().addDays(-1)
            );
            insert invoiceLine;
            // SBQQ.TriggerControl.disable();
            invoice.blng__InvoiceStatus__c = 'Posted';
            update invoice;
           
            blng__CreditNote__c credNote = new blng__CreditNote__c(
                blng__Account__c = company.Id,
                blng__RelatedInvoice__c = invoice.Id,
                blng__CreditNoteDate__c = Date.today(),
                blng__EffectiveTaxDate__c = Date.today()
            );
            insert credNote;
        }
        
        Test.stopTest();
    }
    @IsTest
    static void testCreditNoteLineGeneration() {
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];

        System.runAs(contextuser) {
            // SBQQ.TriggerControl.disable();
            blng__Invoice__c invoice = [
                SELECT Id, blng__InvoiceStatus__c, blng__Account__c
                FROM blng__Invoice__c
                LIMIT 1
            ];
            invoice.blng__InvoiceStatus__c = 'Posted';
            update invoice;
            blng__InvoiceLine__c invoiceLine = [
                SELECT Id, blng__InvoiceLineStatus__c, blng__Balance__c
                FROM blng__InvoiceLine__c
                WHERE blng__Invoice__c = :invoice.Id
                LIMIT 1
            ];
            // System.debug(LoggingLevel.DEBUG, String.valueOf(invoiceLine));
            // invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
            // update invoiceLine;
            blng__CreditNote__c creditNote = [
                SELECT Id
                FROM blng__CreditNote__c
                WHERE blng__RelatedInvoice__c = :invoice.Id
                LIMIT 1
            ];
            Test.startTest();
            QTB_QueueableOrderItemCreation.doChainJob = false;
            try{
                QTB_CreditRebillService.credit(invoice.Id, creditNote.Id);
            }
             catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            Test.stopTest();
            // SBQQ.TriggerControl.enable();
        }

        Integer creditNoteLinesCount = [
            SELECT COUNT()
            FROM blng__CreditNoteLine__c
            WHERE blng__CreditNote__r.blng__RelatedInvoice__c != NULL
        ];
        //System.assertNotEquals(0,creditNoteLinesCount,'Expected a credit note line to be created');
    }
    @IsTest
    static void testEstimateTaxCreditNoteTaxService() {
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];

        System.runAs(contextuser) {
            blng__Invoice__c invoice = [
                SELECT Id, blng__InvoiceStatus__c, blng__Account__c
                FROM blng__Invoice__c
                LIMIT 1
            ];
            invoice.blng__InvoiceStatus__c = 'Posted';
            update invoice;
            blng__InvoiceLine__c invoiceLine = [
                SELECT
                    Id,
                    blng__InvoiceLineStatus__c,
                    blng__Balance__c,
                    blng__Product__c,
                    blng__Quantity__c,
                    blng__Subtotal__c
                FROM blng__InvoiceLine__c
                WHERE blng__Invoice__c = :invoice.Id
                LIMIT 1
            ];
            blng__CreditNote__c creditNote = [
                SELECT Id
                FROM blng__CreditNote__c
                WHERE blng__RelatedInvoice__c = :invoice.Id
                LIMIT 1
            ];
            Test.startTest();
            blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c(
                blng__CreditNote__c = creditNote.Id,
                QTB_Account__c = invoice.blng__Account__c,
                QTB_Invoice__c = invoice.Id,
                QTB_InvoiceLine__c = invoiceLine.Id,
                blng__Product__c = invoiceLine.blng__Product__c,
                QTB_Credit_Quantity__c = invoiceLine.blng__Quantity__c,
                blng__CalculateTax__c = true,
                blng__Subtotal__c = invoiceLine.blng__Subtotal__c
            );
            try{
              insert creditNoteLine;  
            }
            catch (Exception e) {
                System.assert('Script-thrown exception' != e.getMessage());
            }
            
            System.enqueueJob(
                new QTB_CreditNoteTaxService(
                    creditNote.Id,
                    invoice.Id,
                    'estimate'
                )
            );
            Test.stopTest();
        }

        List<blng__CreditNoteLine__c> toBeTested = [
            SELECT blng__TaxStatus__c
            FROM blng__CreditNoteLine__c
            WHERE blng__CreditNote__r.blng__RelatedInvoice__c != NULL
        ];
        //System.assertNotEquals('Error',toBeTested[0].blng__TaxStatus__c,'Expected tax status to be not errored');
    }
    @IsTest
    static void testApplyTaxCreditNoteTaxService() {
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];

        System.runAs(contextuser) {
            blng__Invoice__c invoice = [
                SELECT Id, blng__InvoiceStatus__c, blng__Account__c
                FROM blng__Invoice__c
                LIMIT 1
            ];
            invoice.blng__InvoiceStatus__c = 'Posted';
            update invoice;
            blng__InvoiceLine__c invoiceLine = [
                SELECT
                    Id,
                    blng__InvoiceLineStatus__c,
                    blng__Balance__c,
                    blng__Product__c,
                    blng__Quantity__c,
                    blng__Subtotal__c
                FROM blng__InvoiceLine__c
                WHERE blng__Invoice__c = :invoice.Id
                LIMIT 1
            ];
            blng__CreditNote__c creditNote = [
                SELECT Id
                FROM blng__CreditNote__c
                WHERE blng__RelatedInvoice__c = :invoice.Id
                LIMIT 1
            ];
            Test.startTest();
            blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c(
                blng__CreditNote__c = creditNote.Id,
                QTB_Account__c = invoice.blng__Account__c,
                QTB_Invoice__c = invoice.Id,
                QTB_InvoiceLine__c = invoiceLine.Id,
                blng__Product__c = invoiceLine.blng__Product__c,
                QTB_Credit_Quantity__c = invoiceLine.blng__Quantity__c,
                blng__CalculateTax__c = true,
                blng__Subtotal__c = invoiceLine.blng__Subtotal__c
            );
            try{
                insert creditNoteLine; 
            }
             catch (Exception e) {
                System.assert('Script-thrown exception' != e.getMessage());
            }

            System.enqueueJob(
                new QTB_CreditNoteTaxService(creditNote.Id, invoice.Id, 'apply')
            );
            Test.stopTest();
        }

        blng__CreditNote__c toBeTested = [
            SELECT blng__Status__c
            FROM blng__CreditNote__c
            WHERE blng__RelatedInvoice__c != NULL
        ];
        System.assertNotEquals(
            'Cancelled',
            toBeTested.blng__Status__c,
            'Expected tax status not to be cancelled'
        );
    }
    @IsTest
    static void testInvoiceStatusChangeInvoiceRebillProcess() {
        // SBQQ.TriggerControl.disable();
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];

        System.runAs(contextuser) {
            Account company = [
                SELECT Id
                FROM Account
                WHERE Name = 'Test Factory'
            ];
            Product2 product = [
                SELECT Id, Name
                FROM Product2
                WHERE Name = 'Rebill Product'
            ];
            OrderItem orderProduct = [
                SELECT Id
                FROM OrderItem
                WHERE Product2Id = :product.Id
            ];
            blng__Invoice__c invoice = new blng__Invoice__c(
                blng__Account__c = company.Id,
                blng__InvoiceStatus__c = 'Draft'
            );
            insert invoice;
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(
                Name = product.Name,
                blng__Invoice__c = invoice.Id,
                blng__Product__c = product.Id,
                blng__OrderProduct__c = orderProduct.Id,
                blng__InvoiceLineStatus__c = 'Draft',
                blng__Quantity__c = 0,
                blng__UnitPrice__c = 0,
                blng__TaxPercentageApplied__c = 0,
                blng__Subtotal__c = 0,
                blng__TotalAmount__c = 0
            );
            insert invoiceLine;
            // SBQQ.TriggerControl.disable();
            invoice.RecordTypeId = Schema.SObjectType.blng__Invoice__c.getRecordTypeInfosByName()
                .get('Posted Invoice')
                .getRecordTypeId();
            invoice.blng__InvoiceStatus__c = 'Posted';
            update invoice;
            Test.startTest();
            System.enqueueJob(
                new QTB_CreditRebillService(invoice.Id, 'status update')
            );
            Test.stopTest();
        }

        // System.debug(
        //  '#### Invoice ####' +
        //  [SELECT Id, blng__InvoiceStatus__c FROM blng__Invoice__c]
        // );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM blng__Invoice__c WHERE QTB_Rebilled__c = TRUE],
            'Expected irm rebill to be true on invoice'
        );
    }
    @IsTest
    static void testBatchableCreditPositive() {
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];

        System.runAs(contextuser) {
                blng__Invoice__c invoice = [
                SELECT Id, blng__InvoiceStatus__c, blng__Account__c
                FROM blng__Invoice__c
                LIMIT 1
            ];
            blng__InvoiceLine__c ins = [SELECT QTB_Charge_Type__c 
                                        from blng__InvoiceLine__c 
                                        where blng__Invoice__c =: invoice.Id LIMIT 1 ];
            System.debug('***'+ins);
            invoice.blng__InvoiceStatus__c = 'Posted';
            update invoice;
            blng__CreditNote__c creditNote = [
                SELECT Id
                FROM blng__CreditNote__c
                WHERE blng__RelatedInvoice__c = :invoice.Id
                LIMIT 1
            ];
            Test.startTest();
            QTB_QueueableOrderItemCreation.doChainJob = false;
            QTB_CreditRebillService.batchableCredit(invoice.Id, creditNote.Id);
            
        }

        Integer creditNoteLinesCount = [
            SELECT COUNT()
            FROM blng__CreditNoteLine__c
            WHERE blng__CreditNote__r.blng__RelatedInvoice__c != NULL
        ];
        //System.assertNotEquals(0,creditNoteLinesCount,'Expected a credit note line to be created');
    }
    @IsTest
    static void testRebillPositive() {
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];
        Test.startTest();
        System.runAs(contextuser) {
            blng__Invoice__c invoice = [
                SELECT Id, blng__InvoiceStatus__c, blng__Account__c
                FROM blng__Invoice__c
                LIMIT 1
            ];
            QTB_QueueableOrderItemCreation.doChainJob = false;
            QTB_CreditRebillService.rebill(invoice.Id);
        }
        Test.stopTest();
        Integer rebillMarkedInvoicesCount = [
            SELECT COUNT()
            FROM blng__Invoice__c
            WHERE QTB_Rebilled__c = TRUE
        ];
        System.assertNotEquals(
            0,
            rebillMarkedInvoicesCount,
            'Expected an invoice to be marked IRM Rebill'
        );
    }
    @IsTest
    static void testEstimateTaxThrowingException() {
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];
        Test.startTest();
        System.runAs(contextuser) {
            blng__Invoice__c invoice = [
                SELECT Id, blng__InvoiceStatus__c, blng__Account__c
                FROM blng__Invoice__c
                LIMIT 1
            ];
            blng__CreditNote__c creditNote = [
                SELECT Id
                FROM blng__CreditNote__c
                WHERE blng__RelatedInvoice__c = :invoice.Id
                LIMIT 1
            ];
            QTB_CreditNoteTaxService taxService = new QTB_CreditNoteTaxService(
                creditNote.Id,
                invoice.Id,
                'estimate'
            );
            taxService.throwExplicitException = true;
            String error;
            try {
                taxService.estimateTax();
            } catch (Exception unexc) {
                error = unexc.getMessage();
            }
        }
        Test.stopTest();
        Integer creditNoteLinesCount = [
            SELECT COUNT()
            FROM blng__CreditNoteLine__c
            WHERE
                blng__CreditNote__r.blng__RelatedInvoice__c != NULL
                AND blng__TaxStatus__c = 'Completed'
        ];
        System.assertEquals(
            0,
            creditNoteLinesCount,
            'Expected no credit note line to be taxed'
        );
    }
    @IsTest
    static void testApplyTaxThrowingException() {
        User contextuser = [
            SELECT Id
            FROM User
            WHERE Email = 'testuser@test.example.com'
            LIMIT 1
        ];
        Test.startTest();
        System.runAs(contextuser) {
            blng__Invoice__c invoice = [
                SELECT Id, blng__InvoiceStatus__c, blng__Account__c
                FROM blng__Invoice__c
                LIMIT 1
            ];
            blng__CreditNote__c creditNote = [
                SELECT Id
                FROM blng__CreditNote__c
                WHERE blng__RelatedInvoice__c = :invoice.Id
                LIMIT 1
            ];
            QTB_CreditNoteTaxService taxService = new QTB_CreditNoteTaxService(
                creditNote.Id,
                invoice.Id,
                'apply'
            );
            taxService.throwExplicitException = true;
            String error;
            try {
                taxService.applyTax();
            } catch (Exception unexc) {
                error = unexc.getMessage();
            }
            QTB_CreditRebillService.estimateTax(creditNote.id);
        }
        
        Test.stopTest();
        Integer creditNoteLinesCount = [
            SELECT COUNT()
            FROM blng__CreditNote__c
            WHERE blng__RelatedInvoice__c != NULL AND blng__Status__c = 'Posted'
        ];
        System.assertEquals(
            0,
            creditNoteLinesCount,
            'Expected no credit note to be posted'
        );
    }
    
}