@isTest(seeAllData=true)
public class Test_OpportunityCurrentRevenue_Trigger {
   
   static testMethod void myUnitTest() {
      List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
      List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
      for(Trigger_Activation_Settings__c cs : customsettings){
          if(cs.Object__c == 'OpportunityLineItem' && cs.Trigger__c == 'maintainOpportunityForecastObject') {
          cs.Value__c='True';
          updatesettings.add(cs);
        }
      }
      update updatesettings;
      system.debug('enetering maintainOpportunityForecastObject---------');
     
        //Preparing mock data for test
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        Recordtype r=[select id from recordtype where name='Standard Opportunity' limit 1];
      //  recordtype r=[select id from recordtype where name='NA Renewal' limit 1];
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = '1 - Qualification', IM_Booked_Date__c = Date.Today(), closedate = Date.Today()+1,recordtypeid=r.id);
        insert testOpp;
        
        user u=[select id,Sales_Division__c from user where id=:userInfo.getUserId()];
        u.Sales_Division__c='North America';
        update u;
        
        //Retrieving standard pricebook
        Pricebook2 testStandardPriceBook = [select id from Pricebook2 where IsStandard = true];
        //Creating a Prooduct, PriceBookEntry for it and using these record to generate OpportunityLineItem record.
        RecordType rec=[select id from RecordType where name='IMNA Product' limit 1];
        
        Product2 testProd = new Product2(Name = 'Test Product', IsActive= true, recordTypeId =rec.id);
        insert testProd;
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, Pricebook2Id = testStandardPriceBook.Id, UnitPrice = 1, IsActive = true, UseStandardPrice = false);
        insert testPriceBookEntry;
        List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testOpp.Id, unitPrice = 1);
        //insert oppProd;//insert event of Trigger is called.
       OpportunityLineItem oppProd1 = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testOpp.Id, unitPrice = 1);
        insLinItems.add(oppProd);
        //insLinItems.add(oppProd1);
         Test.startTest();
        insert insLinItems;
    
         Product_Bundle__c probun = new Product_Bundle__c(
        Product_ID__c=testProd.id,
        Product_Group_ID__c=testPriceBookEntry.Pricebook2Id);
        insert probun;
        //updating OpportunityLineItem record
       
        update oppProd;//Update event of trigger is called
      
       // delete oppProd;//delete event of trigger is called.
       //delete oppProd1;
       
       //insLinItems.add(oppProd);//delete event of trigger is called.
       //insLinItems.add(oppProd1);
   
      delete insLinItems;     
        
       Test.stopTest();
}

}