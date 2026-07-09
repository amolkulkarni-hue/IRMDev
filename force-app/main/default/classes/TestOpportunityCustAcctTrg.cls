@isTest(SeeAllData=true)
private class TestOpportunityCustAcctTrg {
     
    static testMethod void runTest() {
      List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
      List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
   //   List<PricebookEntry> pricebooks = new List<PricebookEntry>(); 
      for(Trigger_Activation_Settings__c cs : customsettings){
          cs.Value__c='False';
          updatesettings.add(cs);
      }
        
        /*Profile p = [Select id from profile where name = 'IME_Contracts'];
        
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = p.id
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom');
        
        insert u;
        RecordType EUOppType = [select id from RecordType
                              where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];*/
        
               AccountTriggerHandler.skipTriggerExecutionTestClass  = true;


       IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
                                                    ( (new IM_Country__c(name = 'United Kingdom',
                                                                         Region__c = 'Europe')));
                                

        ID EUOppType = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        
       account a = new Account(name='x');
       insert a;
   
        Id IMNARecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        
        Product2 product = 
        new Product2(
        Secondary_Product_Allowed__c=true, 
        Name='test', 
        RecordTypeId = IMNARecordTypeId,
        CurrencyIsoCode='GBP', 
        IsActive=true);
        insert product;
        
         Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true limit 1];       
       
                      
  PricebookEntry pbe = new PricebookEntry(
  Pricebook2Id = standardPB.Id, 
  Product2Id = product.Id, 
  UnitPrice = 1, 
  IsActive = true,
  CurrencyIsoCode='GBP', 
  UseStandardPrice = false);
  
  insert pbe;  
    
        //PricebookEntry pbe = [select id from PricebookEntry where CurrencyIsoCode='GBP' and IsActive= true   limit 1];
        
      //  Select o.PricebookEntryId, o.OpportunityId From OpportunityLineItem o
        
        //Create the opportunity
       Opportunity o = new Opportunity(name = 'c'
                                      ,AccountId = a.id
                                      ,Source_System__c = 'SKP Europe'
                                      ,Billing_Country__c = cntry.id 
                                      ,Lead_Source_Most_Recent__c = 'x'
                                      //,StageName = '7 - Closed'
                                      ,StageName = '1 - Qualification'
                                      //,Customer_Account_Number__c = System.now().format()
                                      ,RecordTypeId = EUOppType
                                      ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                          ,IME_Reason_Won__c = 'Price'
                                      ,CloseDate = System.today()+10
                                      ,CurrencyIsoCode='GBP'
                                      ,Pricebook2Id = pbe.Pricebook2Id 
                                    //  ,Pricebook2Id = standardPB.Id
                                      );
                                             
        insert o;     
        
        OpportunityLineItem oli = new OpportunityLineItem(
      //  PricebookEntryId= pricebooks[1].Id,
      PricebookEntryId= pbe.Id,
        OpportunityId=o.id,
        Quantity=1,
        TotalPrice=1
        );
        
        insert oli;
        
        o.Customer_Account_Number__c = System.now().format();
        o.StageName = '7 - Closed';
         update o;
        
        test.startTest();
        
       // o.Customer_Account_Number__c = System.now().format()
        o.Customer_Account_Number__c = null;
          
        update o;
           
        o.Customer_Account_Number__c = System.now().format();
        try{
            update o;
        }
        catch(Exception e)
        {
            
        }
           
       test.stopTest(); 
       
    }

}