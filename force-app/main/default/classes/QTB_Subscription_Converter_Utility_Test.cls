/*****************************************************************************************************
* Class: QTB_Subscription_Converter_Utility_Test
* Author: TCS 
* Purpose: Test class for QTB_Subscription_Converter_Utility_Test
* Requirement: 
* Change History: 1/19/2021
* Developer      Date           Description
* -------------------------------------------------------------------------------------------
* TCS         1/19/2021         Test class for QTB_Subscription_Converter_Utility_Test
*******************************************************************************************************/
@isTest (seealldata=false)
public class QTB_Subscription_Converter_Utility_Test {
    private static final Id accstandardRecordTypeId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
    //test method 1
       static testMethod void testmethodContract(){
        QTB_TestDataFactory.createLegalEntity('Norway');
            blng__LegalEntity__c finlandentity = QTB_TestDataFactory.createLegalEntity(
                'Finland'
            );
           // Account
         List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
                2,
                'Standard Account'
            );
            Account a = new Account();
            a.Name = 'TestAcc';
            a.RecordTypeId = accstandardRecordTypeId;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.BillingCountry = 'Finland';          
            a.QTB_Hold_Billing__c = true;            
            a.QTB_Billing_Account_Invoice_Name__c = 'Test Trigger';
            a.QTB_shred__c = true;
            a.QTB_scan__c = true;
            a.QTB_Contract_Entity__c = finlandentity.id;
            a.ShippingCountry = 'Finland';
            a.QTB_Records_Management__c = true;
            insert a;
           // Contact
            List<Contact> cons = new List<Contact>();
            for(Integer i=0;i<10;i++){
                cons.add(new Contact(LastName='Test'+i,accountId=testAccounts[0].Id));
			}
            insert cons;
           // Contract
          List<contract> conlist = new List<contract>();
			contract con = new contract();
            con.AccountId =testAccounts[0].Id;
            con.QTB_Converted_to_Consumption_Schedule__c = False;
			conlist.add(con);
            Insert conlist;
            con.QTB_Converted_to_Consumption_Schedule__c = false;
            update con;
        
        List<string> Contractids =  new List<String>();
        Contractids.add(conlist[0].id);
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);    
        
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);                
        
        //Consumption schedule
        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'dummy';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.BillingTerm = 10;
        consumption.BillingTermUnit = 'Month';
        insert consumption;
        
        //Consumption Rate
        ConsumptionRate conrate = new ConsumptionRate();
        conrate.ProcessingOrder = 1;
        conrate.PricingMethod = 'PerUnit';
        conrate.LowerBound = 1;
        conrate.Price = 100;
        conrate.ConsumptionScheduleId = consumption.Id;
        conrate.CurrencyIsoCode = 'EUR';
        insert conrate;
        
        //Activating Consumption schedule after creation of consumption rate
        consumption.IsActive = true;
        update consumption;
        
        //ProductConsumptionSchedule
        ProductConsumptionSchedule CS = new ProductConsumptionSchedule();
          CS.ConsumptionScheduleId = consumption.Id;
          CS.ProductId = productList[0].Id;
          Insert CS;
           
        //Subscription
        SBQQ__Subscription__c  subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Quantity__c = 10;
        subscription.SBQQ__Product__c = productlist[0].id;
        subscription.SBQQ__ChargeType__c = 'usage';
        subscription.SBQQ__Contract__c = Conlist[0].id;
        insert subscription;
      
        Test.startTest();
        QTB_Subscription_Converter_Utility myPSCScontroller =  new QTB_Subscription_Converter_Utility();
        QTB_Subscription_Converter_Utility.convertSubscriptionFromPriceScheduleToConsumptionSchedule(Contractids);
        QTB_Subscription_Batch obj = new QTB_Subscription_Batch();
        Database.QueryLocator ql = obj.start(null);
        obj.execute(null,Conlist);
        obj.Finish(null);
        Test.stopTest();
    }
}