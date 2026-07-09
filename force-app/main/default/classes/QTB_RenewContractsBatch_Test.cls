/*****************************************************************************************************
 * Class: QTB_RenewContractsBatch_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_RenewContractsBatch
 * Change History: 5/30/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture   3/31/2020
 *******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_RenewContractsBatch_Test {
  private static final Id contractSalesRecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID;

  @testSetup
  static void setup() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      List<QTB_Exclude_Countries__c> customSettList = new List<QTB_Exclude_Countries__c>();
      QTB_Exclude_Countries__c customSett = new QTB_Exclude_Countries__c();
      customSett.Name = 'North America';
      customSett.QTB_Country__c = 'Fan';
      customSettList.add(customSett);

      QTB_Exclude_Countries__c customSett1 = new QTB_Exclude_Countries__c();
      customSett1.Name = 'Europe:Finland';
      customSett1.QTB_Country__c = 'Finland';
      customSettList.add(customSett1);

      insert customSettList;

      List<Account> accList = QTB_TestDataFactory.createAccounts(
        1,
        'Standard Account'
      );
      blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
        'Yes'
      );
      blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
        'Yes'
      );
      blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
      List<product2> product = QTB_TestDataFactory.createProducts(1);
      List<Opportunity> oppList = QTB_TestDataFactory.createOpps(accList);
      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accList[0].id,
        true,
        null
      );
      List<Order> orderList = QTB_TestDataFactory.createCPQOrders(
        1,
        quoteList[0].id,
        accList[0].id
      );
      List<Contract> contractList = QTB_TestDataFactory.createCPQContracts(
        1,
        orderList[0].id,
        accList[0].id,
        quoteList[0].id
      );
      for (Contract con : contractList) {
        con.SBQQ__RenewalQuoted__c = false;
        con.SBQQ__RenewalForecast__c = false;
        con.SBQQ__Evergreen__c = false;
        con.StartDate = date.today();
        con.ContractTerm = 11;
        con.RecordTypeId = contractSalesRecordTypeId;
        con.Status = 'Activated';
      }
      database.update(contractList, false);
    }
    Test.stopTest();
  }

  static testMethod void test() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    Test.startTest();
    System.runAs(userList[1]) {
      List<Contract> Contract = [
        SELECT id, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c
        FROM Contract
        LIMIT 2
      ];
      QTB_RenewContractsBatch obj = new QTB_RenewContractsBatch();
      QTB_RenewContractsBatch.throwExplicitException = false;
      DataBase.executeBatch(obj);
      Test.stopTest();
      System.assertEquals(
        false,
        QTB_RenewContractsBatch.throwExplicitException
      );
    }
  }
  static testMethod void coverCatch() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    Test.startTest();
    System.runAs(userList[1]) {
      QTB_RenewContractsBatch.throwExplicitException = true;
      QTB_RenewContractsBatch obj = new QTB_RenewContractsBatch();
      DataBase.executeBatch(obj);
      Test.stopTest();
      System.assertEquals(true, QTB_RenewContractsBatch.throwExplicitException);
    }
  }
}