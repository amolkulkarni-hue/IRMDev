// Created By :     Pratap Reddy C
// Created Date:    17th Aug 2016

@isTest (SeeAllData=true)
public class Test_QuoteObject {
 public static testMethod Void doTest(){
     
     List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
     List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
          if(cs.Object__c == 'Quote') {
             cs.Value__c='True';
              if(Cs.Trigger__c=='UpdateApproverComment'){
                cs.Value__c= 'True';
            }
             updatesettings.add(cs);
          }
        }
        update updatesettings;
     
     // String CurrencyofUser=[select id,CurrencyIsoCode from user where id=:userInfo.getUserId()].CurrencyIsoCode;
        User CurrentUser = [Select CurrencyIsoCode from user where id=:userInfo.getUserId()];  
        
        
     //insert Account
       Account A = new Account(name='Account4TestMethod'+system.now(), BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
       insert A;     
      
        IM_Customer_Account__c  ca = TestingUtils.createCustomerAccount(A.id, false);
        //insert rate table
        insert ca;
     
        
     
     //get the bill code
        PriceBookentry pbe=[select id,product2Id,pricebook2Id, product2.Bill_Code_Classification__c from PriceBookentry where Product2.RecordType.Name='Bill Code' and priceBook2.Name='PROS' and product2.Bill_Code_Classification__c ='Storage' and CurrencyIsoCode=:CurrentUser.CurrencyIsoCode AND isActive=true limit 1 ];
        system.debug('+++++++++product id +++++++++++'+pbe.product2id);
       
     
     Id imRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('NA Renewal').getRecordTypeId(); 
  
      Schedule_A__c schA = new Schedule_A__c();
     schA.Account__c = a.id;
     schA.Additional_Terms_1__c = 'Additional Term 1';
     schA.Reference__c='Test xml.xlsm';
     Insert schA;
     //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
     system.debug('CurrentUser.CurrencyIsoCode:'+ CurrentUser.CurrencyIsoCode);
     //insert opportunity
        Opportunity opp = new Opportunity();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.IM_Booked_Date__c = System.today().addMonths(3);
        opp.StageName = '1 - Under Review';
        
        opp.Type = 'Renewal';
        opp.Current_Revenue__c= 300;
        opp.recordTypeId=imRecTypeId;
        opp.pricebook2Id=pbe.pricebook2Id;
        opp.CurrencyIsoCode=CurrentUser.CurrencyIsoCode;
        opp.StageName = '1 - Qualification';
        opp.CloseDate = Date.Today();
        insert opp;
        
     Test.startTest();
     Quote quoteObject=new Quote(Name='Test Quote',opportunityId=opp.id,pricebook2Id=pbe.pricebook2Id);        
          
     quoteObject.Stage__c='0 - Forecast';
     quoteObject.AdditionalCity = 'Bangalore';
     quoteObject.Schedule_A__c = schA.id;
     insert quoteObject;
     
     //insert QuoteLineItem
        QuoteLineItem QL =new QuoteLineItem(QuoteId=quoteObject.Id,UnitPrice=1,Quantity=12,PricebookentryId=pbe.id,Current_Price__c=10);
        QuoteSyncUtil.isRunningTest = true; 
        Insert QL;
        QuoteLineItem QL1 =new QuoteLineItem(QuoteId=quoteObject.Id,UnitPrice=1,Quantity=12,PricebookentryId=pbe.id,Current_Price__c=10);
        QuoteSyncUtil.isRunningTest = true; 
        Insert QL1;
     
        opp.recordTypeId=imRecTypeId;
        opp.SyncedQuoteId = quoteObject.id;
        update opp;
        
     quoteObject.Stage__c='5 - Closed - In Fulfillment';
     update quoteObject;
        Test.stopTest();  
 }
}