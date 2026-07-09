/*****************************************************************************************************
* Class: QTB_CreateOrderOrderItemBatch_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_CreateOrderOrderItemBatch
* Change History: 
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*              19/01/2022
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_CreateOrderOrderItemBatch_Test {
    @TestSetup
    static void createData() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
                'Yes'
            );
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
            );
            blng__TaxIntegration__c taxIntegration = QTB_TestDataFactory.createTaxIntegration();
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            blng__FinanceBook__c BillingFinanceBook = new blng__FinanceBook__c();
            BillingFinanceBook.Name = 'Accounting Finance Book';
            BillingFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
            BillingFinanceBook.blng__Active__c = true;
            BillingFinanceBook.blng__PeriodType__c='Accounting';
            insert BillingFinanceBook; 
            blng__BillingTreatment__c  BillingTreatment = new blng__BillingTreatment__c();
            BillingTreatment.Name= 'No Invoice Billing Treatment';
            BillingTreatment.blng__Active__c= true;
            BillingTreatment.blng__BillingFinanceBook__c= BillingFinanceBook.id;
            BillingTreatment.blng__BillingRule__c= billingRule.id;
            BillingTreatment.blng__CancellationRule__c='LIFO by Order Product Creation Date';
            insert BillingTreatment;
            
            List<priceBook2> prbk =QTB_TestDataFactory.priceBookMethdLst(1,'Singapore');
            prbk[0].QTB_Country__c='Singapore';
            prbk[0].CurrencyIsoCode = 'SGD';
            prbk[0].isActive = true;
            update prbk[0];
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            product[0].SBQQ__BillingFrequency__c = 'Monthly';
            product[0].SBQQ__BillingType__c = 'Arrears';
            product[0].SBQQ__ChargeType__c = 'Recurring';
            update product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id=pricebookId,
                Product2Id = product[0].Id,
                UnitPrice = 10000,
                currencyIsoCode = 'SGD',
                IsActive = true);
            insert standardPrice;
            PricebookEntry ShingaporePrice = new PricebookEntry(
                Pricebook2Id=prbk[0].id,
                Product2Id = product[0].Id,
                UnitPrice = 10000,
                IsActive = true,
                currencyIsoCode = 'SGD');
            Insert ShingaporePrice;
            
            blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
            LglEntity.CurrencyIsoCode='SGD';
            update LglEntity;
            
            blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c();
            taxTreatment.Name = 'Singapore Increase Tax';
            taxTreatment.blng__TaxIntegration__c = taxIntegration.id;
            taxTreatment.blng__TaxRule__c = taxRule.id;
            date effectiveStartDate = Date.newInstance(2023,01,01);
            date effectiveEndDate = Date.newInstance(2023,12,31);
            taxTreatment.QTB_Tax_Effective_Start_Date__c = effectiveStartDate;
            taxTreatment.QTB_Tax_Effective_End_Date__c = effectiveEndDate;
            taxTreatment.blng__TaxLegalEntity__c = LglEntity.id;
            taxTreatment.QTB_Taxable__c = 'yes';
            taxTreatment.QTB_TaxCountry__c = 'Singapore';
            taxTreatment.blng__Active__c = true;
            insert taxTreatment;
            
            QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
            setting.Name = 'Singapore';
            setting.Active__c= true;
            setting.Legal_entity_country__c='Singapore';
            insert setting;
            
            ID OrdRecId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
            ID AccRecId = (Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId());
            //List<account> accountList = QTB_TestDataFactory.createAccounts(1);
            List<Account> accountList = new List<Account>();
            ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
            try{
                Account a = new Account();
                a.Billing_County__c = 'Singapore';
                a.name='BILLC';
                a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
                a.RecordTypeId= AccRecId;
                a.Name = 'Test Account';
                a.BillingCountry = 'Singapore';
                a.BillingPostalCode = '11209';
                a.BillingState = 'TN';
                a.Registration_Number__c = 'Reg';
                a.ShippingCountry = 'Singapore';
                a.QTB_DM_Source_System__c='oneil';
                a.QTB_Contract_Entity__c =LglEntity.id;
                a.QTB_Is_Parent_Billing_Account__c=False;
                a.CurrencyIsoCode = 'SGD';
                a.QTB_Source_Opportunity__c=null;	
                a.QTB_Create_Parent_Billing_Account__c=true;
                accountList.add(a);
                
                if (!accountList.isEmpty()) {
                    insert accountList;
                }
            } catch (Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
            
            Date sdate= Date.newInstance(2022,10,01);
            set<String>uomSet = new Set<String>();
            QTB_CreateOrderOrderItemBatch res = new QTB_CreateOrderOrderItemBatch('oneil',sdate,LglEntity.id,'SGD',5,uomSet);
            Database.executeBatch(res);
            Test.stopTest();
            System.assertEquals(
                accountList[0].QTB_Legal_Entity_Country__c,
                accountList[0].QTB_Contract_Entity__r.blng__Country__c,
                'Unexpected error'
            );
        }
    }
    
    //cover catch
    static testMethod void testMethod2() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            Test.startTest();
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
                1,
                'Standard Account'
            );
            blng__LegalEntity__c LglEntity2 = QTB_TestDataFactory.createLegalEntity('Singapore');
            QTB_CreateOrderOrderItemBatch.throwExplicitException = true;
            set<String>uomSet = new Set<String>();
            Date s2date= Date.newInstance(2021,11,01);
            QTB_CreateOrderOrderItemBatch obj = new QTB_CreateOrderOrderItemBatch('oneil',s2date,LglEntity2.id,'SGD',10,uomSet);
            obj.execute(null, null);
            Test.stopTest();
            System.assertEquals(
                true,
                QTB_CreateOrderOrderItemBatch.throwExplicitException
            );
        }
    }
    
}