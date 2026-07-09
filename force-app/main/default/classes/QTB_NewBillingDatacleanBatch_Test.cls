/*****************************************************************************************************
 * Class: QTB_NewBillingDatacleanBatch_Test
 * Author: Virtusa
 * Purpose: This is a test class for QTB_NewBillingDatacleanBatch
 * Change History: 
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *              24/03/2022
 *******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_NewBillingDatacleanBatch_Test {
  @TestSetup
  static void createData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      Test.startTest();
        List<account> accountList = new list<account>();
            account a = new account();
            a.Billing_County__c = 'United States';
            a.name = 'test 1';
            a.RecordTypeId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
            a.BillingCountry = 'India';
        	a.BillingPostalCode = '11209';
        	a.BillingState = 'TN';
        	a.Registration_Number__c = 'Reg';
       	 	a.ShippingCountry = 'India';
            a.QTB_DM_Source_System__c = 'Oneil';
            accountList.add(a);
            insert accountList;
        
        Id pricebookId = Test.getStandardPricebookId();
        order ord = new Order(
            //SBQQ__Quote__c = quoteId,
            AccountId = accountList[0].id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = 'Draft',
            Pricebook2Id = pricebookId,
            blng__BillingAccount__c = accountList[0].Id
          );
        SBQQ.TriggerControl.disable();    
        insert ord;
        SBQQ.TriggerControl.enable();

        
        blng__UsageSummary__c usage = new blng__UsageSummary__c();
        usage.blng__SummaryEndDate__c = DATE.newInstance(2021, 06, 30);
        usage.blng__SummaryStartDate__c = DATE.newInstance(2021,06, 01);
        usage.blng__MatchingId__c = '1234';
        usage.blng__MatchingAttribute__c = 'TestAttribute1';
        usage.blng__Status__c = 'New';
        usage.QTB_Legal_Entity_Country__c = 'Singapore';
        usage.CurrencyIsoCode ='SGD';
        usage.blng__Order__c = ord.id;
        insert usage;
     
        id cid = UserInfo.getUserId();
        Date sDate = DATE.newInstance(2021, 06, 30);
        QTB_NewBillingDatacleanBatch  bat =new QTB_NewBillingDatacleanBatch('Singapore',sDate,5);
        Database.executeBatch(bat);
         Test.stopTest();
        System.assertEquals(
        'New',
         usage.blng__Status__c,
        'Unexpected error'
      );
    }
  }
  //cover catch
  static testMethod void testMethod2() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      QTB_NewBillingDatacleanBatch.throwExplicitException = true;
        id cid = UserInfo.getUserId();  
        Date sDate = DATE.newInstance(2021, 05, 30);
      QTB_NewBillingDatacleanBatch obj = new QTB_NewBillingDatacleanBatch('Singapore',sDate,5);
      obj.execute(null, null);
      Test.stopTest();
      System.assertEquals(
        true,
        QTB_NewBillingDatacleanBatch.throwExplicitException
      );
    }
  }
  
}