/**
 * Commenting the code as it is a test class for inactive trigger and reference class QuoteLineItemServices
 * Gitlab Story #29660
 **/
@isTest (SeeAllData=true)
public class Test_QuoteLineItemObject{
    
    static testMethod void testCommented(){
        
        Test.StartTest();
        QuoteLineItemServices qlis = new QuoteLineItemServices();
        system.assertNotEquals(null,qlis);   
        Test.StopTest();
                
    }
 /*   
    public static testMethod Void doTest(){
        
       
        
        //Test.StartTest();        
        List<LineItemsSync__c> CustomSettingData=LineItemsSync__c.getAll().Values();
        if(CustomSettingData.isEmpty()){
            LineItemsSync__c temp=new LineItemsSync__c();
            temp.name='Test';
            temp.Opportunity_Product_API_Name__c='Name';
            temp.Quote_Line_Item_API_Name__c='Name';
            temp.Pricing_Contract_Entry_API_Name__c='Name';
            insert temp;
        } 
        
        
        //insert Account
        Account A = new Account(name='Account4TestMethod'+system.now(), BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
        insert A; 
        
        
        // String CurrencyofUser=[select id,CurrencyIsoCode from user where id=:userInfo.getUserId()].CurrencyIsoCode;
        User CurrentUser = [Select CurrencyIsoCode from user where id=:userInfo.getUserId()];  //Sandhya Ramesh, 9/19/2014
        
        //get the bill code
        PriceBookentry pbe=[select id,product2Id,pricebook2Id, product2.Bill_Code_Classification__c from PriceBookentry where Product2.RecordType.Name='Bill Code' and priceBook2.Name='PROS' and product2.Bill_Code_Classification__c ='Storage' and CurrencyIsoCode=:CurrentUser.CurrencyIsoCode and isActive=true limit 1 ];
        system.debug('+++++++++product id +++++++++++'+pbe.product2id);
        
        
        //get record type
        RecordType r=new RecordType();
        r=[select id from RecordType where name='NA Renewal'];
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        //insert opportunity
        Opportunity opp = new Opportunity();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.IM_Booked_Date__c = System.today().addMonths(3);
        opp.CloseDate = date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Current_Revenue__c= 300;
        opp.recordTypeId=r.id;
        opp.pricebook2Id=pbe.pricebook2Id;
        opp.CurrencyIsoCode=CurrentUser.CurrencyIsoCode;       
        insert opp;
        
         
        //insert Quote 
        Set<Id> qlst = new set<Id>();
        Quote Q=new Quote(Name='Test Quote',Cost_per_action_once_cap_exceeded__c=10,opportunityId=opp.id,pricebook2Id=pbe.pricebook2Id);        
        Insert Q;
        qlst.add(q.Id);
        Quote Q1=new Quote(Name='Test Quote1',opportunityId=opp.id,pricebook2Id=pbe.pricebook2Id); 
        qlst.add(Q1.Id);
        //QuoteSyncUtil.addNewQuoteId(q.id);
        Test.startTest();  
        //insert QuoteLineItem
        QuoteLineItem QL =new QuoteLineItem(QuoteId=Q.Id,UnitPrice=1,Quantity=12,PricebookentryId=pbe.id,
                                            Current_Price__c=null,Q2W_Service_Category__c = 'Storage');
        QuoteSyncUtil.isRunningTest = true; 
        Insert QL;
        
        opp.SyncedQuoteId = q.Id;      
        update opp;
        
        
        
        
        List<QuoteLineItem> followerLineItems = new List<QuoteLineItem>();
        List<QuoteLineItem> leaderLineItems = new List<QuoteLineItem>();
        
        Quote LineItemServices=new Quote(Name='Test Quote QuoteLineItemServices',Cost_per_action_once_cap_exceeded__c=10,opportunityId=opp.id,pricebook2Id=pbe.pricebook2Id);        
        Insert LineItemServices;
        
        followerLineItems.add(QL);
        QuoteLineItemServices.addFollowerLineItems(followerLineItems);
        QuoteLineItemServices.updateLineItems(followerLineItems);
        QuoteLineItemServices.removeFollowerLineItems(followerLineItems);
        Test.stopTest(); 
    }   
    
    /*public static testMethod Void QuoteSyncUtil_Test(){
        List<LineItemsSync__c> CustomSettingData=LineItemsSync__c.getAll().Values();
        if(CustomSettingData.isEmpty()){
            LineItemsSync__c temp=new LineItemsSync__c();
            temp.name='Test';
            temp.Opportunity_Product_API_Name__c='Name';
            temp.Quote_Line_Item_API_Name__c='Name';
            temp.Pricing_Contract_Entry_API_Name__c='Name';
            insert temp;
        } 
        
        
        //insert Account
        Account A = new Account(name='Account4TestMethod'+system.now(), BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
        insert A; 
        
        
        // String CurrencyofUser=[select id,CurrencyIsoCode from user where id=:userInfo.getUserId()].CurrencyIsoCode;
        User CurrentUser = [Select CurrencyIsoCode from user where id=:userInfo.getUserId()];  //Sandhya Ramesh, 9/19/2014
        
        //get the bill code
        PriceBookentry pbe=[select id,product2Id,pricebook2Id, product2.Bill_Code_Classification__c from PriceBookentry where Product2.RecordType.Name='Bill Code' and priceBook2.Name='PROS' and product2.Bill_Code_Classification__c ='Storage' and CurrencyIsoCode=:CurrentUser.CurrencyIsoCode and isActive=true limit 1 ];
        system.debug('+++++++++product id +++++++++++'+pbe.product2id);
        
        
        //get record type
        RecordType r=new RecordType();
        r=[select id from RecordType where name='NA Renewal'];
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        //insert opportunity
        Opportunity opp = new Opportunity();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.IM_Booked_Date__c = System.today().addMonths(3);
        opp.CloseDate = date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Current_Revenue__c= 300;
        opp.recordTypeId=r.id;
        opp.pricebook2Id=pbe.pricebook2Id;
        opp.CurrencyIsoCode=CurrentUser.CurrencyIsoCode;       
        insert opp;
        
         
        //insert Quote 
        Set<Id> qlst = new set<Id>();
        Quote Q=new Quote(Name='Test Quote',Cost_per_action_once_cap_exceeded__c=0,opportunityId=opp.id,pricebook2Id=pbe.pricebook2Id);        
        Insert Q;
        qlst.add(q.Id);
        Quote Q1=new Quote(Name='Test Quote1',opportunityId=opp.id,pricebook2Id=pbe.pricebook2Id); 
        qlst.add(Q1.Id);
        
        Test.startTest(); 
        QuoteSyncUtil.getNewQuoteIds();
        QuoteSyncUtil.removeNewQuoteId(q.id);
        QuoteSyncUtil.removeAllNewQuoteIds(qlst);
        QuoteSyncUtil.clearNewQuoteIds();
        QuoteSyncUtil.isNewQuote(q.id);
        QuoteSyncUtil.getQuoteFieldMapTo('Faxing_pages_included__c');
        QuoteSyncUtil.removeQuoteField('Faxing_pages_included__c');
        QuoteSyncUtil.getQuoteLineFieldMapTo('Faxing_pages_included__c');
        QuoteSyncUtil.removeQuoteLineField('Faxing_pages_included__c');
        QuoteSyncUtil.getOppFieldsString();
        QuoteSyncUtil.getOppLineFieldsString();
        QuoteSyncUtil.getQuoteFieldsString();
        QuoteSyncUtil.getQuoteLineFieldsString();
        QuoteSyncUtil.addQuoteField('Faxing_pages_included__c', 'Expected_CuFt__c');
        QuoteSyncUtil.addQuoteLineField('Faxing_pages_included__c', 'Expected_CuFt__c');
        
        QuoteSyncUtil.getField('Quote','Name');
        QuoteSyncUtil.getField('QuoteLineItem','Schedule_A_Category__c');
        QuoteSyncUtil.getField('Opportunity','Name');
        QuoteSyncUtil.getField('OpportunityLineItem','Product_Class__c');
        
        QuoteSyncUtil.populateRequiredFields(new Quote());
        QuoteSyncUtil.populateRequiredFields(new QuoteLineItem());
        QuoteSyncUtil.populateRequiredFields(new Opportunity());
        QuoteSyncUtil.populateRequiredFields(new OpportunityLineItem());
        

        Test.stopTest();
    }*/
    
}