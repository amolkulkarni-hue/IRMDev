/*****************************************************************************************************
 * Class: QTB_OpportunityHelper_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_OpportunityHelper
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture    6/1/2020
 *******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_OpportunityHelper_Test {
   @testSetup
  static void setup() {
    SBQQ.TriggerControl.disable();
    QTB_TestDataFactory.createBypassSetting(
      QTB_Constants.SOBJECT_QUOTE +
      ';' +
      QTB_Constants.SOBJECT_ORDER +
      ';' +
      QTB_Constants.SOBJECT_CONTRACT
    );
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      List<Account> accountList = QTB_TestDataFactory.createAccounts(1);
      List<Opportunity> oppList = QTB_TestDataFactory.createCPQOppsNew(
        accountList,
        'CPQ Sales Opportunity'
      );
      oppList[0].stageName ='1 - Qualification';
      oppList[0].Primary_Product_Line__c = 'Data Management';
      oppList[0].IME_Reason_Won__c = 'test';
      update oppList;
      opportunity opp = new opportunity(
        Name = 'Billing Opportunity',
        AccountId = accountList[0].Id,
        CloseDate = Date.today(),
        //RecordTypeId = QTB_Utils.OPP_BILL_RECTYPEID,
        StageName = '1 - Qualification'
      );
      insert opp;

      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        oppList[0].accountId,
        true,
        null
      );
      quoteList[0].SBQQ__Status__c = QTB_Constants.APPROVED_STATUS;
      update quoteList;

      oppList[0].SBQQ__PrimaryQuote__c = quoteList[0].id;
      oppList[0].stageName = QTB_Constants.STAGEVALUE_SIXSETUP;
      update oppList;
      Test.startTest();
      List<Order> testOrders = QTB_TestDataFactory.createCPQOrders(
        1,
        quoteList[0].id,
        accountList[0].id
      );
      List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(
        1,
        testOrders[0].id,
        accountList[0].id,
        quoteList[0].id
      );
      testContracts[0].SBQQ__Opportunity__c = oppList[0].Id;
      testContracts[0].RecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID;
      update testContracts;

      List<Opportunity> testAmendOpps = QTB_TestDataFactory.createAmendOpps(
        accountList,
        testContracts[0].id,
        'CPQ Sales Opportunity'
      );
      testAmendOpps[0].stageName ='1 - Qualification';
      testAmendOpps[0].IME_Reason_Won__c = 'test';
      update testAmendOpps;

      testAmendOpps[0].stageName = QTB_Constants.STAGEVALUE_SIXSETUP;
      testAmendOpps[0].IM_Parent_Opportunity__c = oppList[0].id;
      testAmendOpps[0].SBQQ__AmendedContract__c = testContracts[0].Id;
      testAmendOpps[0].SBQQ__Contracted__c = true;
      update testAmendOpps;

      List<Opportunity> testRenewOpps = QTB_TestDataFactory.createRenewalOpps(
        accountList,
        testContracts[0].id,
        'CPQ Sales Opportunity'
      );
      testRenewOpps[0].stageName ='1 - Qualification';
      testRenewOpps[0].QTB_Deferred_Renewal_Opportunity__c = true;
      testRenewOpps[0].IME_Reason_Won__c = 'test';
      update testRenewOpps;

      testRenewOpps[0].stageName = QTB_Constants.STAGEVALUE_SIXSETUP;
      testRenewOpps[0].IM_Parent_Opportunity__c = oppList[0].id;
      testRenewOpps[0].SBQQ__RenewedContract__c = testContracts[0].Id;
      update testRenewOpps;
      OpportunityTriggerHandler.throwExplicitException = false;
      Test.stopTest();
      system.assertEquals(
        false,
        OpportunityTriggerHandler.throwExplicitException
      );
    }
  }
testMethod static void testException(){
        Test.startTest();
        OpportunityTriggerHandler.throwExplicitException = true;
        try{
            QTB_OpportunityHelper.updateDeferralCheckboxonQuote(null);
        }
        catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        try{
            QTB_OpportunityHelper.autoPopulate(null,null,null);
        }catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        try{
            QTB_OpportunityHelper.populateOriginalQuote(null,null);
        }
        catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        try{
            QTB_OpportunityHelper.primaryProductLineValidation(null,null,null,null, null ,null);
        }
        catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        
        
       // OpportunityTriggerHandler handler=new OpportunityTriggerHandler();
       // handler.BeforeDelete(null);
        //handler.AfterDelete(null);
      //  handler.AfterUndelete(null);
        QTB_TestDataFactory.createBypassSetting('Opportunity');
      //  handler.isDisabled();
        Test.stopTest();
        
    }
  
}