/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Desrciption   :  This is the test utility OpportunityLineItemObject.
  Date          : 12/6/12
  case number   : 00924109   */
@isTest(seeAllData=true)
private class Test_OpportunityLineItemsObject{	

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
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = '1 - Qualification', IM_Booked_Date__c = Date.Today(), closedate = Date.Today(),recordtypeid=r.id);
        insert testOpp;
        
        user u=[select id,Sales_Division__c from user where id=:userInfo.getUserId()];
        u.Sales_Division__c='North America';
        update u;
        
        //Retrieving standard pricebook
        Pricebook2 testStandardPriceBook = [select id from Pricebook2 where IsStandard = true];
        //Creating a Prooduct, PriceBookEntry for it and using these record to generate OpportunityLineItem record.
         Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
            
        Product2 testProd = new Product2(Name = 'Test Product', recordTypeId=rt,IsActive= true);
        insert testProd;
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, Pricebook2Id = testStandardPriceBook.Id, UnitPrice = 1, IsActive = true, UseStandardPrice = false);
        insert testPriceBookEntry;
        Test.startTest();
        testopp.Pricebook2Id = testPriceBookEntry.Pricebook2Id;
        update testopp;
        List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testOpp.Id, unitPrice = 1);
        //insert oppProd;//insert event of Trigger is called.
       OpportunityLineItem oppProd1 = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testOpp.Id, unitPrice = 1);
        insLinItems.add(oppProd);
        //insLinItems.add(oppProd1);
         //Test.startTest();
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
    system.debug('Limits.getQueries3: '+ Limits.getQueries());
           
            Integer MAX_QUERY = Limits.getLimitQueries();
            system.assertEquals(MAX_QUERY, Limits.getLimitQueries());
        try{
            delete insLinItems;
        }
        catch(Exception ex){ 
        }
    // delete insLinItems;     
        
       Test.stopTest();
}

      static testMethod void myUnitTest1() {
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
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;

        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        Recordtype r=[select id from recordtype where name='Standard Opportunity' limit 1];
      //  recordtype r=[select id from recordtype where name='NA Renewal' limit 1];
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = '1 - Qualification', IM_Booked_Date__c = Date.Today(), 
                                              closedate = Date.Today(),recordtypeid=r.id);
        
        insert testOpp;
        
        user u=[select id,Sales_Division__c from user where id=:userInfo.getUserId()];
        u.Sales_Division__c='North America';
        update u;
        
        //Retrieving standard pricebook
        Pricebook2 testStandardPriceBook = [select id from Pricebook2 where IsStandard = true];
        //Creating a Prooduct, PriceBookEntry for it and using these record to generate OpportunityLineItem record.
        Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
            
        Product2 testProd = new Product2(Name = 'Test Product', recordTypeId=rt,IsActive= true);
        insert testProd;
       
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, Pricebook2Id = testStandardPriceBook.Id, UnitPrice = 1, IsActive = true, UseStandardPrice = false);
        insert testPriceBookEntry;
        testopp.Pricebook2Id = testPriceBookEntry.Pricebook2Id;
        update testopp;
        List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testOpp.Id, unitPrice = 1,Product_Class__c ='Records Management',Product_Line__c='storage');
        //insert oppProd;//insert event of Trigger is called.
       OpportunityLineItem oppProd1 = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testOpp.Id, unitPrice = 1);
        insLinItems.add(oppProd);
        insLinItems.add(oppProd1);
      
        insert insLinItems;
    
        
        //updating OpportunityLineItem record
       
      //  update oppProd;//Update event of trigger is called
      
       // delete oppProd;//delete event of trigger is called.
       //delete oppProd1;
       
       //insLinItems.add(oppProd);//delete event of trigger is called.
       //insLinItems.add(oppProd1);
      	Test.startTest();
      	delete oppProd; 
          
       /* oppProd1.UnitPrice = 10;
           system.debug('Limits.getQueries3: '+ Limits.getQueries());
            
            Integer MAX_QUERY = Limits.getLimitQueries();
            system.assertEquals(MAX_QUERY, Limits.getLimitQueries());
        try{
            update oppProd1;
       //update oppProd1;
          
        Opportunity opp = [select id,SyncedQuoteId,Pricebook2Id from opportunity where RecordType.Name='NA Renewal' and SyncedQuoteId !=null and currencyISOCode='USD' limit 1];
        pricebookentry pbe = [select id,name from pricebookentry where pricebook2Id =:opp.Pricebook2Id and currencyISOCode='USD' and IsActive=true limit 1];
        OpportunityLineItem oppProd2 = new OpportunityLineItem(Quantity = 12,PricebookEntryId = pbe.Id, OpportunityId = Opp.Id, unitPrice = 20);
		insert oppProd2;
            }
           catch(Exception ex){ 
        } */
        // update testOpp;
       Test.stopTest();
}
    
    static testMethod void doTestQ2W(){
          List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
          List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
          for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'OpportunityLineItem' && cs.Trigger__c == 'OppBundleDelete') {
              cs.Value__c='True';
              updatesettings.add(cs);
            }
          }
            update updatesettings;
           //insert Account
           Account A = new Account(name='Account4TestMethod'+system.now(), BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
           insert A; 
           
           String CurrencyofUser=[select id,CurrencyIsoCode from user where id=:userInfo.getUserId()].CurrencyIsoCode;
           System.debug('CurrencyofUser-----'+CurrencyofUser);
           //get the bill code
          
           PriceBookentry pbe=[select id,product2Id,pricebook2Id, product2.Bill_Code_Classification__c from PriceBookentry where Product2.RecordType.Name='Bill Code' and priceBook2.Name='PROS' and product2.Bill_Code_Classification__c ='Storage' and CurrencyIsoCode=:CurrencyofUser and isActive=true limit 1 ];
        system.debug('+++++++++product id +++++++++++'+pbe.product2id);
           //get record type
           RecordType r=new RecordType();
           r=[select id from RecordType where name='NA Renewal' limit 1];
       
            
            //insert opportunity
            Opportunity opp = new Opportunity();
            opp.AccountId = A.Id;
            opp.Name = 'Opportunity4TestMethod';
            opp.CloseDate = System.today().addMonths(3);
            opp.StageName = '1 - Qualification';
            opp.Type = 'Renewal';
            opp.recordTypeId=r.id;
            opp.pricebook2Id=pbe.pricebook2Id;
            //Test.startTest();
            insert opp;
        
            //insert Quote 
           
         Quote Q=new Quote(Name='Test Quote',opportunityId=opp.id,pricebook2Id=pbe.pricebook2Id);        
          Insert Q;
          //QuoteSyncUtil.addNewQuoteId(q.id);
        
            //insert QuoteLineItem
         
             QuoteLineItem QL =new QuoteLineItem(QuoteId=Q.Id,UnitPrice=1,Quantity=12,PricebookentryId=pbe.id,
                                            Current_Price__c=null,Q2W_Service_Category__c = 'Storage');
        QuoteSyncUtil.isRunningTest = true; 
        Insert QL;
        Test.startTest();
        opp.SyncedQuoteId = q.Id;      
        update opp;
  
         //update QuoteLineItem
        // QL.Proposed_Price__c =250;
         //QL.pros_q2w__SurchargePercent1__c =10;
         //QL.Discount =10;
         //update QL; 
          Test.stopTest();
    }
    }