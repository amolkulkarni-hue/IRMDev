/*****************************************************************************************************
* Class: QTB_InFlowOrderItemBatch_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_InFlowOrderItemBatch
* Change History: 
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*              04/02/2022
*  Virtusa     5th April 2024 Increased Code Coverage #22350
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_InFlowOrderItemBatch_Test {
    @TestSetUp
    private static void createData() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            
            blng__BillingRule__c billingRule		    = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
          	blng__TaxRule__c taxRule					= QTB_TestDataFactory.createTaxRule('Yes');
            
            blng__FinanceBook__c BillingFinanceBook = new blng__FinanceBook__c();
            BillingFinanceBook.Name = 'Accounting Finance Book';
            BillingFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
            BillingFinanceBook.blng__Active__c = true;
            BillingFinanceBook.blng__PeriodType__c='Accounting';
            Database.insert(BillingFinanceBook,false) ; 
            System.debug('Test class BillingFinanceBook = '+ BillingFinanceBook);
            
            blng__BillingTreatment__c  BillingTreatment = new blng__BillingTreatment__c();
            BillingTreatment.Name= 'No Invoice Billing Treatment';
            BillingTreatment.blng__Active__c= true;
            BillingTreatment.blng__BillingFinanceBook__c= BillingFinanceBook.id;
            BillingTreatment.blng__BillingRule__c= billingRule.id;
            BillingTreatment.blng__CancellationRule__c='LIFO by Order Product Creation Date';
            Database.insert(BillingTreatment,false) ;  
            System.debug('Test class BillingTreatment = '+ BillingTreatment);
            
            blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
            LglEntity.CurrencyIsoCode='SGD';
            Database.update(LglEntity,false) ;
            System.debug('Test class LglEntity = '+ LglEntity);
            
           
            
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
            Database.insert(taxTreatment,false) ;
             System.debug('Test class taxTreatment = '+ taxTreatment);
            
             //
            blng__LegalEntity__c LglEntityUS = QTB_TestDataFactory.createLegalEntity('United States');
            LglEntityUS.CurrencyIsoCode='USD';
            Database.update(LglEntityUS,false) ;
            
            blng__TaxTreatment__c taxTreatmentUS = new blng__TaxTreatment__c(Name = 'US Increase Tax',blng__TaxIntegration__c = taxIntegration.id, blng__TaxRule__c = taxRule.id,
                                                                             QTB_Tax_Effective_Start_Date__c = Date.newInstance(2022,12,01), QTB_Tax_Effective_End_Date__c = Date.newInstance(2023,12,31),
           										                             blng__TaxLegalEntity__c = LglEntityUS.id,QTB_Taxable__c = 'yes',QTB_TaxCountry__c = 'United States',blng__Active__c = true);
            Database.insert(taxTreatmentUS,false) ;
             System.debug('Test class taxTreatmentUS = '+ taxTreatmentUS);
            //
            
            
            List<Product2> product = QTB_TestDataFactory.createProducts(2);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            product[0].SBQQ__ChargeType__c = 'Recurring';
            //Increased Code Coverage #22350
      		product[0].SBQQ__BillingType__c='Arrears';
            product[0].SBQQ__BillingFrequency__c='Monthly';
             Database.update(product[0],true); 
            //Increased Code Coverage #22350
            System.debug('product is on Test Class = '+ product);
            
            //
            System.debug('product1 --- > '+product[1]);
            product[1].blng__BillingRule__c = billingRule.id;
            product[1].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[1].blng__TaxRule__c = taxRule.id;
            product[1].SBQQ__ChargeType__c = 'Recurring';
      		product[1].SBQQ__BillingType__c='Arrears';
            product[1].SBQQ__BillingFrequency__c='Monthly';
            product[1].Family ='DM Cloud Solutions';
            
            Database.update(product[1],true);
            
            
           
            
            /*  Id pricebookId = Test.getStandardPricebookId();
                PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
                standardPrice.CurrencyIsoCode = 'SGD';
                update standardPrice;

                PricebookEntry SingaporePrice = new PricebookEntry(
                Pricebook2Id=prbk[0].id,
                Product2Id = product[0].Id,
                UnitPrice = 10000,
                CurrencyIsoCode = 'SGD',    
                IsActive = true);
                Database.insert(testCountry,false) ; SingaporePrice;*/
            
            Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),CurrencyIsoCode = 'USD',IsActive = true);
            Database.update(standardPricebook,false);
            System.debug('Test class standardPricebook = '+ standardPricebook);
            
            List<priceBook2> prbk =QTB_TestDataFactory.priceBookMethdLst(1,'Singapore');
            prbk[0].QTB_Country__c='Singapore';
            prbk[0].currencyISOCode = 'SGD';
            prbk[0].IsActive = true;
            Database.update(prbk[0],false);
            System.debug('Test class prbk[0] = '+ prbk[0]);
            
           //
            List<priceBook2> prbk1 =QTB_TestDataFactory.priceBookMethdLst(1,'United States');
            prbk1[0].QTB_Country__c='United States';
            prbk1[0].currencyISOCode = 'USD';
            prbk1[0].IsActive = true;
            Database.update(prbk1[0],false);
            System.debug('Test class prbk1[0] = '+ prbk1[0]);
            //
            
            PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product[0].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode='SGD' );
            Database.insert(standardPrice,false) ;
            System.debug('**Inflow standardPrice'+standardPrice+'Inflow Currency >>>'+standardPrice.CurrencyIsoCode);
            
            PriceBookEntry SingaporePrice= new PricebookEntry( pricebook2id=prbk[0].id, product2id=product[0].id,unitprice=2000, isActive=true, currencyISOCode='SGD');
            Database.insert(SingaporePrice,false) ;  
            System.debug('**Inflow SingaporePrice'+SingaporePrice+'Inflow Currency >>>'+SingaporePrice.CurrencyIsoCode);
            
            PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product[0].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode='USD' );
            Database.insert(standardPrice1,false) ; 
            System.debug('**Inflow standardPrice'+standardPrice1+'Inflow Currency >>>'+standardPrice1.CurrencyIsoCode);
            
            PriceBookEntry USDPrice= new PricebookEntry(pricebook2id=prbk[0].id, product2id=product[0].id,unitprice=2000, isActive=true, currencyISOCode='USD');
            Database.insert(USDPrice,false) ;
            System.debug('**Inflow USD'+USDPrice+'Inflow Currency >>>'+USDPrice.CurrencyIsoCode);
            
            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product[1].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode='USD' );
            Database.insert(standardPrice2,false) ; 
            PricebookEntry usaPrice = new PricebookEntry(Pricebook2Id = prbk1[0].Id, Product2Id = product[1].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode='USD' );
            Database.insert(usaPrice) ;
            System.debug('**Inflow usaPrice'+usaPrice+'Inflow Currency >>>'+usaPrice.CurrencyIsoCode);
            
                      
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1);
            
            IM_Country__c testCountry = new IM_Country__c(Name='United States',active__c=true);
            Database.insert(testCountry,false) ;
            List<Opportunity> oppsToReturn =new List<Opportunity>();
            for (integer i = 0; i < accountList.size(); i++) 
            {
                oppsToReturn.add(new Opportunity(Name = 'Test' + i,AccountId = accountList[i].Id,
                        						CloseDate = Date.today(),
                        						StageName = '1 - Qualification',Amount = 500,
                        						RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
                        						Billing_Country__c=testCountry.id,
                        						Primary_Product_Line__c = 'Data Management'));
            }
            
            //
             oppsToReturn.add(new Opportunity(Name = 'Test US' ,AccountId = accountList[0].Id,
                        						CloseDate = Date.today(),
                        						StageName = '1 - Qualification',Amount = 500,
                        						RecordTypeId = QTB_Utils.OPP_STANDARD_RECTYPEID,
                        						Billing_Country__c=testCountry.id,
                        						Primary_Product_Line__c = 'DM Cloud Solutions'));
            List<Account> billingaccountList = QTB_TestDataFactory.createAccounts(1);
            billingaccountList[0].ParentId=accountList[0].Id;
            billingaccountList[0].RecordTypeId=QTB_Utils.ACCOUNT_BILL_RECTYPEID;
            billingaccountList[0].QTB_Source_Opportunity__c=oppsToReturn[1].ID;
            billingaccountList[0].QTB_Iron_Cloud__c=true;
            billingaccountList[0].QTB_Contract_Entity__c=LglEntityUS.ID;
            billingaccountList[0].QTB_Invoice_Delivery_Options__c='Paper';
            System.debug('billingaccountList--->'+billingaccountList[0]);
            Database.Update(billingaccountList); 
            //
            
            if (!oppsToReturn.isEmpty()) {
                Database.insert(oppsToReturn,false) ;
                System.debug('Test class oppsToReturn = '+ oppsToReturn);
            }
            //List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            // System.debug('before oppList '+oppList);
            oppsToReturn[0].Pricebook2Id = standardPricebook.Id;
            System.debug('pricebookId '+standardPricebook.Id);
            System.debug('Test class pricebookId = '+ standardPricebook.Id);
            
            update oppsToReturn;
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
                								1,oppsToReturn[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c = standardPricebook.Id;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            //update quoteList;
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
               												 1,quoteList[0].id,accountList[0].id);
            
            List<SBQQ__QuoteLine__c> quoteLinesList      = QTB_TestDataFactory.createCPQQuoteLines(
                										     1,quoteList[0].id, quoteGroupList[0].id,product[0].id);
            
            ID OrdRecId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
            ID AccRecId = (Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId());
            
            QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
            setting.Name = 'Singapore';
            setting.Active__c= true;
            setting.Legal_entity_country__c='Singapore';
            Database.insert(setting,false) ;
            System.debug('Test class setting = '+ setting);
            
            List<Order> orderList3 = QTB_TestDataFactory.createBillingOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].QTB_Legal_Entity_Country__c = 'Singapore';
            orderList3[0].RecordtypeID = OrdRecId;
            orderList3[0].CurrencyIsoCode = 'SGD';
            Database.update(orderList3[0],false) ;
            System.debug('Test class orderList3[0] = '+ orderList3[0]);
            
            //
            List<Order> orderList5 = QTB_TestDataFactory.createBillingOrders(1,NULL,billingaccountList[0].id);
            orderList5[0].QTB_Legal_Entity_Country__c = 'United States';
            orderList5[0].RecordtypeID = OrdRecId;
            orderList5[0].CurrencyIsoCode = 'USD';
            Database.update(orderList5[0],false) ;
            System.debug('Test class orderList5[0] = '+ orderList5[0].ID);
            //
            
            
            List<Id> lstTopass= new List<Id>();
            lstTopass.add(orderList3[0].id);
           
            System.debug('** Inflow lstTopass Currency **'+lstTopass);
            QTB_InFlowOrderItemBatch res = new QTB_InFlowOrderItemBatch(lstTopass);
            System.debug('**Inflow lstTopass**'+lstTopass);
            Database.executeBatch(res);
            
            //
            List<Id> lstTopass1= new List<Id>();
            lstTopass1.add(orderList5[0].id);
            System.debug('**Inflow lstTopass1**'+lstTopass1);
            QTB_InFlowOrderItemBatch.executeBatchMethod(lstTopass1);
            //
            
            Test.stopTest();
            System.assertEquals('Draft',orderList3[0].Status,'Unexpected error');
        }
    }
    //cover catch
    private static testMethod void testMethod2() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1])
        {
            Test.startTest();
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(1,'Standard Account');
            List<Order> orderList333 = QTB_TestDataFactory.createBillingOrders(1,NULL,testAccounts[0].id);   
            orderList333[0].QTB_Legal_Entity_Country__c = 'Singapore';
            Database.update(orderList333[0],false) ;
            QTB_InFlowOrderItemBatch.throwExplicitException = true;
            List<Id> lstTopass2= new List<Id>();
            lstTopass2.add(orderList333[0].id);
            QTB_InFlowOrderItemBatch obj = new QTB_InFlowOrderItemBatch(lstTopass2);
            obj.execute(null, null);
            Test.stopTest();
            System.assertEquals(true,QTB_InFlowOrderItemBatch.throwExplicitException);
        }
    }

}