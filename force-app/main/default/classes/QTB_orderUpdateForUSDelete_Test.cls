/*****************************************************************************************************
 * Class: QTB_orderUpdateForUSDelete_Test
 * Author: Virtusa
 * Purpose: This is a test class for QTB_orderUpdateForUSDelete
 *******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_orderUpdateForUSDelete_Test {
  @TestSetup
  static void createData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      //Test.startTest();
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'blng__Invoice__c;Account;AccountContactRelation;blng__UsageSummary__c;OrderItem;blng__InvoiceLine__c;blng__CreditNote__c;Product2;blng__CreditNoteLine__c;blng__Usage__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert custSetting;
        
        Credit_ReBill_InvoiceSchedulerValidation__c invSchCust = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invSchCust.Name = 'Finland';
        invSchCust.isRunning__c = false;
        insert invSchCust;
        
        QTB_Billing_Countries__c BillingCountries = new QTB_Billing_Countries__c();
        BillingCountries.Name = 'Singapore';
        BillingCountries.Legal_entity_country__c = 'Singapore' ;
        insert BillingCountries;
        
        //List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        //Product
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Account
        List<Account> accountList = new List<Account>();
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
            Account a = new Account();
            a.Name = (a.Name == null ? 'Test' : a.Name) + i;
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'Singapore';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'Singapore';
            a.QTB_Legal_Entity_Country__c='Singapore';
            if(i == 0){
                a.QTB_Legal_Entity_Country__c='United States';
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
      

          blng__LegalEntity__c Indiaentity = QTB_TestDataFactory.createLegalEntity(
          'India'
          );
         
        List<Account> standardAccountList = QTB_TestDataFactory.createAccounts(1,'Standard Account');
        accountList[0].QTB_Legal_Entity_Country__c='India';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Standard Account';
        accountList[0].ShippingCountry = 'India';
        accountList[0].QTB_Contract_Entity__c = Indiaentity.Id;
        update accountList;
        update standardAccountList; 
   
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';    
        im.Active__c = true;
        insert im;
        //Account
          Account a = new Account();
            a.Name = 'testdata123';
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'Singapore';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'Singapore';
            a.QTB_Legal_Entity_Country__c='Singapore';
         insert a;
       
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity insOpp = new Opportunity();
        insOpp.name = 'testOpp';
        insOpp.AccountId = standardAccountList[0].id;
        insOpp.CloseDate = Date.today();
        insOpp.StageName = '1 - Qualification';
        insOpp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        insOpp.Amount = 500;
        insOpp.Pricebook2Id=pricebookId;
        oppList.add(insOpp);
        insert oppList;
        SBQQ.TriggerControl.disable();
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList3[0].Usagesummary_deletion_batchRun__c =true;
         update  orderList3;
        List<OrderItem> orderItemList3 = new List<OrderItem>();
            //QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
        try {
      for (Integer i = 0; i < 1; i++) {
        orderItemList3.add(
          new OrderItem(
            OrderId = orderList3[0].Id,
            Quantity = 2.00,
            UnitPrice = 12.00,
            //SBQQ__QuoteLine__c = quoteLines[i].id,
            PricebookEntryId = standardPrice.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = product[0].Id,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .id,
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .id,
            blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id,
              blng__HoldBilling__c = 'Yes'
          )
        );
      }
      if (!orderItemList3.isEmpty()) {
        insert orderItemList3;
      }
    } catch (Exception e) {
    }
             
        blng__UsageSummary__c usage = new blng__UsageSummary__c();
        usage.blng__SummaryEndDate__c = DATE.newInstance(2021, 06, 30);
        usage.blng__SummaryStartDate__c = DATE.newInstance(2021,06, 01);
        usage.blng__MatchingId__c = '1234';
        usage.blng__Status__c = 'New';
        usage.QTB_Legal_Entity_Country__c = 'Singapore';
        usage.blng__UnitOfMeasure__c = '';
        usage.blng__OrderProduct__c = orderItemList3[0].id;
        usage.CurrencyIsoCode ='SGD';
        insert usage;      
        id cid = UserInfo.getUserId();
       
    }
  }
  //cover catch
  static testMethod void testMethod2() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      id cid = UserInfo.getUserId();  
      List<Order> orderList = [select id from Order limit 1];
      QTB_orderUpdateForUSDelete obj = new QTB_orderUpdateForUSDelete(orderList[0].Id);
      obj.throwExplicitException = true;
      database.executeBatch(obj);
      Test.stopTest();
     
    }
    
  } 

  static testMethod void testMethod3() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      id cid = UserInfo.getUserId();  
      List<Order> orderList = [select id from Order limit 1];
      QTB_orderUpdateForUSDelete obj = new QTB_orderUpdateForUSDelete();
      database.executeBatch(obj);
      Test.stopTest();
     
    }
} 
  
    
  

}