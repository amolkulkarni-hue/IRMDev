/*
Auhtor      : Pratibh Prakash
Company     : Fujitsu America
Created Date: 17 Sep-2009
Modified    : 
Description : Test class for "OpportunityLineItemExtensionTest" controller .
*/
@isTest(SeeAllData=true)
private class OpportunityLineItemExtensionTest {

    static testMethod void testOpportunityItemExt() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
          if(cs.Object__c == 'Opportunity') {
              if(cs.Trigger__c == 'createcustomeraccounts') {
              cs.Value__c='False';
              }
              if(cs.Trigger__c == 'populateOptyOwnerInfo') {
                cs.Value__c='False';
            }            
            if(cs.Trigger__c == 'OpportunityOwnerLinkTrg') {
                cs.Value__c='False';
            }
            if(cs.Trigger__c == 'UpdateOppotunityOwnerEmailTrigger') {
                cs.Value__c='False';
            }            
            if(cs.Trigger__c == 'syncOppScheduleDate_Fix') {
                cs.Value__c='False';
            }
            if(cs.Trigger__c == 'CreateOptyShare') {
                cs.Value__c='False';
            }
            if(cs.Trigger__c == 'OpportunitySubmitForApproval') {
                cs.Value__c='False';
            }
            if(cs.Trigger__c == 'SendAccountInfoToCDM') {
                cs.Value__c='False';
            }

          } 
           if(cs.Object__c=='Account'){
                    if(cs.Trigger__c == 'AccountCountryLookup') {
                        cs.Value__c='False';    
                    }
                    if(cs.Trigger__c == 'AccountPostalCode') {
                        cs.Value__c='False';
                    }
                    if(cs.Trigger__c == 'RealignRateTableOwner'){
                        cs.Value__c='False';
                }
            }
   
            updatesettings.add(cs);
          }
        
        
        Test.StartTest();
        //Preparing mock data
      
        RecordType EUOppType = [select id from RecordType where name = 'Standard Opportunity' and  sObjectType = 'Opportunity'];
            
            List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 
            accountList[0].BillingCountry='India';
            update accountList;
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
                        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            cusAcc.Name = 'testSold';
            cusAcc.IM_Account__c = accountList[0].id;
            cusAcc.Source_System__c = 'Other Europe';
        insert cusAcc;
        
       /* 
        Account testAccount = new Account(Name='Test Account'+system.now(), BillingCountry='United States');
        insert testAccount;
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', 
                                              AccountId = testAccount.Id,
                                              Lead_Source_Most_Recent__c = 'Email',
                                              StageName = '1 - Qualification',
                                         RecordTypeId = IMERecordTypeId,
                                        IM_Servicing_Region__c ='London',
                                        //IM_Commit_to_Forecast__c = true,
                                        //IM_Stage_5_Entered_Date__c  = System.today(),
                                        //IME_Reason_Won__c = 'Price',
                                        //IMGA_Owner__c = u.id,
                                        IM_Up_Sell_Sold_To__c = 'testSold',
                                        CloseDate = System.today()
                                        ,IM_Booked_Date__c=System.today());
        insert testOpp; */
            
        Id testStandardPriceBook = Test.getStandardPricebookId();
        Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
            
        Product2 testProd = new Product2(Name = '9999',
                                             recordTypeId=rt, 
                                             IsActive= true,
                                             Bill_Code_Classification__c='Storage');
            insert testProd;
        
        Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
            insert customPB;
        
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, 
                                                                    Pricebook2Id = testStandardPriceBook, 
                                                                    UnitPrice = 1, IsActive = true, 
                                                                    UseStandardPrice = false);
            insert testPriceBookEntry;
        
        PricebookEntry pbe_01 = new PricebookEntry(
                Pricebook2Id = customPB.Id, Product2Id = testProd.Id,
                UnitPrice = 12000, IsActive = true);
            insert pbe_01;

         List<OpportunityLineItem> insLinItems=new  List<OpportunityLineItem>();     
            OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].Id, unitPrice = 1,Update_New_Revenue_Forecast__c =false);
            insert oppProd;
        /*OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testOpp.Id, unitPrice = 1, Update_New_Revenue_Forecast__c =false );
        insert oppProd; */
        OpportunityLineItem oppProd_withoutOppFcst = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = oppList[0].Id, unitPrice = 1, Update_New_Revenue_Forecast__c =false );
        insert oppProd_withoutOppFcst; 
        
        //Creating Opportunity Product Schedule record.
      //  OpportunityLineItemSchedule olis = new OpportunityLineItemSchedule(OpportunityLineItemId = oppProd.Id, Revenue=1, ScheduleDate= Date.Today(), Type='Revenue');
    //    insert olis;
            
        //Creating Opportunity Forecast record.
   /*     IM_Opportunity_Forecast__c oppFcst = new IM_Opportunity_Forecast__c();
        oppFcst.OpportunityLIneItemScheduleId__c = testOpp.id; //olis.Id;
        oppFcst.Name = 'Test';
        oppFcst.Opportunity__c = testOpp.Id;
        oppFcst.Product__c = testProd.Id;
        oppFcst.OpportunityLineItemId__c = oppProd.Id;
        oppFcst.Revenue__c = 10;
        oppFcst.Schedule_Date__c = Date.Today();
        insert oppFcst;
     */   
        ApexPages.StandardController sc = new ApexPages.StandardController(oppProd);
        ApexPages.StandardController sc_withoutOppFcst = new ApexPages.StandardController(oppProd_withoutOppFcst);
        
        OpportunityLineItemExtension objOppLineItemExt = new OpportunityLineItemExtension(sc);
       OpportunityLineItemExtension objOppLineItemExt_withoutOppFcst = new OpportunityLineItemExtension(sc_withoutOppFcst);
        
        List<IM_Opportunity_Forecast__c> testOppFcstList = new List<IM_Opportunity_Forecast__c>();
        testOppFcstList.addAll(objOppLineItemExt.getOpportunityForecasts());
        PageReference testPage = objOppLineItemExt.UpdateForecast();
        
        //Calling setters and getters.
        objOppLineItemExt.setoppForecastFlag(true);
        objOppLineItemExt.setTempOppFcstList(testOppFcstList);
        testOppFcstList.clear();
        Boolean testFlag = objOppLineItemExt.getoppForecastFlag();
        testOppFcstList.addAll(objOppLineItemExt.getTempOppFcstList());
        Test.StopTest();
    }
    
}