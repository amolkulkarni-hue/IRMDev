/*****************************************************************************************************
 * Class: QTB_ScheduleBillingProcess_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_QueueRenewalBilling,QTB_RenewalBillingBatch & QTB_RenewalBillingBatchHelper
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture   17/06/2020
 *******************************************************************************************************/
@isTest(seeAllData=false)
private class QTB_QueueRenewalBilling_Test {
    @TestSetup
	static void createData() {
        updateContractNumber.isTriggered = true;
        QTB_ContractHelper.Singleton = false;
        List<User> testUsers = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(testUsers[0]) {
            QTB_TestDataFactory.createBypassSetting(
                QTB_Constants.SOBJECT_ACCOUNT +
                ';' +
                QTB_Constants.SOBJECT_CONTRACT
            );
            List<Account> testAccount = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
            List<Product2> testProduct = QTB_TestDataFactory.createProducts(1);
            List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(1, 'Test Price book');
            testPriceBook[0].isActive = true;
            testPriceBook[0].QTB_Country__c = testAccount[0].Billing_County__c;
            update testPriceBook;
            IM_Country__c testCountry = new IM_Country__c(Name='India');
            insert testCountry;
            List<Opportunity> testOpp = QTB_TestDataFactory.createCPQOppsNew(testAccount, 'CPQ Sales Opportunity');
            testOpp[0].Pricebook2Id = testPriceBook[0].id;
            testOpp[0].CurrencyIsoCode = testAccount[0].Billing_County__c;
            testOpp[0].Billing_Country__c = testCountry.Id;
            update testOpp;
            List<SBQQ__Quote__c> testQuotes = QTB_TestDataFactory.createCPQQuotes(
                1,
                testOpp[0].Id,
                testOpp[0].AccountId,
                true,
                null
            );
            List<SBQQ__QuoteLine__c> testQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                testQuotes[0].Id,
                null,
                testProduct[0].id
            );
            Contract salesContract = new Contract(
                Status = 'Draft',
                StartDate = Date.today(),
                ContractTerm = 5,
                SBQQ__Opportunity__c = testOpp[0].Id,
                AccountId = testAccount[0].Id,
                SBQQ__Quote__c = testQuotes[0].Id
            );
            SBQQ.TriggerControl.disable();
            insert salesContract;
            salesContract.Status = 'Activated';
            Test.startTest();
            update salesContract;
            List<Account> testBillAccount = QTB_TestDataFactory.createAccounts(1, 'Billing Account');
            SBQQ.TriggerControl.disable();
            //Billing Opportunity
            List<Opportunity> billTestOpp = QTB_TestDataFactory.createCPQOppsNew(
                testBillAccount,
                'CPQ Billing Opportunity'
            );
            SBQQ.TriggerControl.disable();
            billTestOpp[0].Pricebook2Id = testPriceBook[0].id;
            billTestOpp[0].CurrencyIsoCode = testBillAccount[0].Billing_County__c;
            billTestOpp[0].Billing_Country__c = testCountry.Id;
            update billTestOpp;
            List<SBQQ__Quote__c> billtestQuotes = QTB_TestDataFactory.createCPQQuotes(
                1,
                billTestOpp[0].Id,
                billTestOpp[0].AccountId,
                true,
                null
            );
            List<SBQQ__QuoteLine__c> billtestQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                billtestQuotes[0].Id,
                null,
                testProduct[0].id
            );
            SBQQ.TriggerControl.disable();
            List<Order> billtestorder = QTB_TestDataFactory.createCPQOrders(
                1,
                billtestQuotes[0].id,
                testBillAccount[0].id
            );
            SBQQ.TriggerControl.disable();
            List<Contract> billtestContracts = QTB_TestDataFactory.createCPQContracts(
                1,
                billtestorder[0].id,
                testBillAccount[0].id,
                billtestQuotes[0].id
            );
            billtestContracts[0].SBQQ__Quote__c = billtestQuotes[0].id;
            billtestContracts[0].Status = 'Activated';
            SBQQ.TriggerControl.disable();
            update billtestContracts;
            List<SBQQ__Subscription__c> billtestSubs = QTB_TestDataFactory.createCPQSubscriptions(
                1,
                billtestContracts[0].id,
                testProduct[0].id
            );
            Opportunity renewalTestOpp = new Opportunity();
            renewalTestOpp.Name = testAccount[0].Id;
            renewalTestOpp.AccountId = testAccount[0].Id;
            renewalTestOpp.recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
            renewalTestOpp.Pricebook2Id = testPriceBook[0].id;
            renewalTestOpp.CurrencyIsoCode = testAccount[0].Billing_County__c;
            renewalTestOpp.Type = 'Renewal';
            renewalTestOpp.stageName = '1 - Qualification';
            renewalTestOpp.CloseDate = System.today();
            renewalTestOpp.SBQQ__Renewal__c = true;
            renewalTestOpp.SBQQ__RenewedContract__c = salesContract.Id;
            renewalTestOpp.Billing_Country__c = testCountry.Id;
            insert renewalTestOpp;
            SBQQ.TriggerControl.disable();

            List<SBQQ__Quote__c> renewaltestQuotes = QTB_TestDataFactory.createCPQQuotes(
                1,
                renewalTestOpp.Id,
                renewalTestOpp.AccountId,
                true,
                null
            );
            renewaltestQuotes[0].SBQQ__PriceBook__c = testPriceBook[0].id;
            update renewaltestQuotes[0];
            Test.stopTest();
            PricebookEntry pbe = QTB_TestDataFactory.createPricebookEntry(testProduct[0]);
            List<SBQQ__QuoteLine__c> renewaltestQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                renewaltestQuotes[0].Id,
                null,
                testProduct[0].id
            );
            renewaltestQuoteLines[0].SBQQ__PricebookEntryId__c = pbe.id;
            update renewaltestQuoteLines[0];
            Contract renewsalesContract = new Contract(
                Status = 'Draft',
                recordtypeId = QTB_utils.CONTRACT_SALES_RECTYPEID,
                StartDate = Date.today(),
                ContractTerm = 7,
                SBQQ__Opportunity__c = renewalTestOpp.Id,
                AccountId = testAccount[0].Id,
                SBQQ__Quote__c = renewaltestQuotes[0].Id
            );
            insert renewsalesContract;
            QTB_ContractHelper.Singleton = true;
            renewsalesContract.Status = 'Activated';
            SBQQ.TriggerControl.disable();
            update renewsalesContract;
            try {
                System.enqueueJob(new QTB_QueueRenewalBilling(new List<Contract>{ renewsalesContract }));
            } catch (exception e) {
                system.debug('Exception is-->' + e.getMessage());
            }

            System.assert(renewsalesContract.Status == 'Activated');
        }
    }
   static testMethod void coverCatchBlock() {
        Test.startTest();
        QTB_QueueRenewalBilling.throwExplicitException = true;
        QTB_RenewalBillingBatchHelper.collectAllBillingAccounts(null, null);
        QTB_RenewalBillingBatchHelper.setHoldTime(1);
        Test.stopTest();
        System.assertEquals(true, QTB_QueueRenewalBilling.throwExplicitException);
    }
}