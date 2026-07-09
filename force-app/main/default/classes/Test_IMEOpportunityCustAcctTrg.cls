@isTest(seeAlldata = true)
private class Test_IMEOpportunityCustAcctTrg {
  
// #16283 Commenting out the code as its main class(IME_OpportunityCustAcctTrg) is Inactive 
  
  static testMethod void runTest() 
  { 
       /* List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Trigger__c == 'createcustomeraccounts'){
            	cs.Value__c='True';
            }
            updatesettings.add(cs);
        }
        update updatesettings;
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
                                                    ( (new IM_Country__c(name = 'United Kingdom',
                                                                         Region__c = 'Europe')));
        
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
                                and sObjectType = 'Opportunity'];
                                
           
       account a = new Account(name='x');
       insert a;
   
        Product2 product = 
        new Product2(
        Secondary_Product_Allowed__c=true, 
        Name='test', 
        CurrencyIsoCode='GBP', 
        IsActive=true);
        insert product;
        
      //Create the opportunity
       Opportunity o = new Opportunity(name = 'c'
                                      ,AccountId = a.id
                                      ,Source_System__c = 'SKP Europe'
                                      ,Billing_Country__c = cntry.id 
                                      ,Lead_Source_Most_Recent__c = 'x'
                                      //,StageName = '7 - Closed'
                                      ,StageName = '5 - Signed/PO in'
                                      //,Customer_Account_Number__c = System.now().format()
                                      ,RecordTypeId = EUOppType.Id
                                      ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                      ,CloseDate = System.today()+10
                                      ,IME_Reason_Won__c = 'Price'
                                      ,CurrencyIsoCode='GBP'
                                      );
                                             
        insert o;
        
               
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
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
        
        OpportunityLineItem oli = new OpportunityLineItem(
        PricebookEntryId= pbe.id,
        OpportunityId=o.id,
        Quantity=1,
        TotalPrice=1
        );
        
        insert oli;
         test.startTest();
        o.Customer_Account_Number__c = System.now().format();
        o.StageName = '7 - Closed';
         update o;
        
       
        
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
       
    } */
 
  }
}