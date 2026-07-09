/*****************************************************************************************************
 * Class: QTB_CreateExtraOrderBatch_Test
 * Author: Virtusa
 * Purpose: This is a test class for QTB_CreateExtraOrderBatch
 * Change History: 
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *              19/01/2022
 *******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_CreateExtraOrderBatch_Test {
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
        product[0].productcode='01100-0456';
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
        currencyIsoCode = 'SGD',
        IsActive = true);
       Insert ShingaporePrice;
       
      blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
          LglEntity.CurrencyIsoCode='SGD';
          update LglEntity;
        
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
                a.QTB_Create_Parent_Billing_Account__c =True;
                accountList.add(a);
                
                if (!accountList.isEmpty()) {
                    insert accountList;
                }
            } catch (Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
       Date sdate= Date.newInstance(2021,10,01);
       set<string>prcode = new set<string>{'01100-0456'};
       set<String>uomSet = new Set<String>();
       QTB_CreateExtraOrderBatch res = new QTB_CreateExtraOrderBatch('oneil',sdate,5,prcode,LglEntity.id,'SGD',uomSet);
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
       
      QTB_CreateExtraOrderBatch.throwExplicitException = true;
        Date s2date= Date.newInstance(2021,11,01);
        set<string>prcode = new set<string>{'01100-0451'};
            blng__LegalEntity__c LglEntity2 = QTB_TestDataFactory.createLegalEntity('Singapore');
          LglEntity2.CurrencyIsoCode='SGD';
          update LglEntity2;
        set<String>uomSet = new Set<String>();
        QTB_CreateExtraOrderBatch obj = new QTB_CreateExtraOrderBatch('oneil',s2date,10,prcode,LglEntity2.id,'SGD',uomSet);
      obj.execute(null, null);
      Test.stopTest();
      System.assertEquals(
        true,
        QTB_CreateExtraOrderBatch.throwExplicitException
      );
    }
  }
  
}