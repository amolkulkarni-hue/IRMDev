@isTest(seeAllData=true)
public class Test_IME_OpportunityCompetitorsCountTrg {

// #16281 Commenting out the code as its main class(IME_OpportunityCompetitorsCountTrg) is Inactive  
  
   public static testmethod void runTest()
   {
       
        //Profile p = [Select id from profile where name = 'IME_Contracts'];
        
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
                                                    ( (new IM_Country__c(name = 'United Kingdom',
                                                                         Region__c = 'Europe')));
        
        /*User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
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
                                
        ID EUOppType =  Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId(); 
        System.debug('EUOppType----'+EUOppType );
        
           account a = new Account(name='x');
           insert a;

           Opportunity o = new Opportunity(name = 'c'
                                          ,AccountId = a.id
                                          ,Source_System__c = 'SKP'
                                          ,Billing_Country__c = cntry.id 
                                          ,Lead_Source_Most_Recent__c = 'x'
                                          //,StageName = '7 - Closed'
                                          ,StageName = '1 - Qualification'
                                          ,RecordTypeId = EUOppType
                                          ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                          ,IME_Reason_Won__c = 'Price'
                                          ,CloseDate = System.today());
                                          
           insert o;
           
           
           OpportunityCompetitor oc = new OpportunityCompetitor(  );
           oc.OpportunityId = o.Id;
           oc.Weaknesses = 'x';
           oc.CompetitorName = 'z';
           oc.Strengths = 'a';
           

           insert oc;
           
           
           update o;
           
           delete oc;
          
           update o;
           
       
   }
   
   public static testMethod void ime_rollupTest1()
   {
        RecordType EUOppType = [select id from RecordType
                              where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];
   
       
           
           Account acct = new Account(Name = 'Test Account New');
           insert acct;
            
           IM_Country__c contry = new IM_Country__c();
           contry.Name = 'United States';
           insert contry;
           
           Recordtype rectypCont = [Select ID,Name from recordtype where SObjectType = 'Contract' and Name = 'IME Parent Contract'];
           
           Contract contrct = new Contract();
           contrct.Name = 'testcontractnew';
           contrct.AccountId = acct.id;
           contrct.Billing_Country__c = contry.id;
           contrct.Status = 'Draft';
           contrct.StartDate = Date.today();
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.RecordTypeId = rectypCont.Id;
       	   contrct.IME_Annual_Value_Opportunities__c = 2000;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
           contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
       
           Contract contrct1 = new Contract();
           contrct1.Name = 'testcontractnew111';
           contrct1.AccountId = acct.id;
           contrct1.Billing_Country__c = contry.id;
           contrct1.Status = 'Draft';
           contrct1.StartDate = Date.today();
           contrct1.IME_Contract_Term_Type__c = 'Fixed term';
           contrct1.ContractTerm = 12;
           contrct1.IM_Renewal_Term__c = 24;
           contrct1.IME_Expiration_Notice_days__c = 60;
           contrct1.Contract_Type__c = 'IM Standard';
           contrct1.IM_Contract_Category__c = 'Single Product';
           contrct1.IME_Contract_Version__c = 'NDA';
           contrct1.IME_MFP_Clause__c = 'YES';
           contrct1.IME_Non_Standard_Clause__c = 'YES';
           contrct1.IME_Other__c = True;
           contrct1.RecordTypeId = rectypCont.Id;
           contrct1.IME_Copy_to_all__c = True;
           contrct1.IME_Price_Increase_Type_Storage__c='Regular Increase';
           contrct1.IME_Fixed_Pricing_Period_months_Storage__c=3;
       	   //contrct.IME_Annual_Value_Opportunities__c = 2000;
           insert contrct1;
           Test.startTest(); 
           Opportunity o = new Opportunity(name = 'c'
                                          ,AccountId = acct.id
                                          ,Source_System__c = 'SKP'
                                          ,Billing_Country__c = contry.id 
                                          ,Lead_Source_Most_Recent__c = 'x'
                                          //,StageName = '7 - Closed'
                                          ,StageName = '1 - Qualification'
                                          ,RecordTypeId = EUOppType.id
                                          ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                          ,IME_Reason_Won__c = 'Price'
                                          ,CloseDate = System.today()
                                          ,IME_Contract__c = contrct.id,
                                          //,CurrencyIsoCode='GBP',
                                          Amount = 20000 
                                          );
                                          
           insert o;
           
       	   o.IME_Contract__c = null;
       	   update o;
       
           o.IME_Contract__c = contrct1.id;
		    Test.stopTest(); 
       	   //update o;
       
       		o.CurrencyIsoCode='GBP';
       		update o;
   }
    
       public static testMethod void ime_rollupTest2()
   {
        RecordType EUOppType = [select id from RecordType
                              where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];

       	   Account acct = new Account(Name = 'Test Account New');
           insert acct;
            
           IM_Country__c contry = new IM_Country__c();
           contry.Name = 'United States';
           insert contry;
           
           Recordtype rectypCont = [Select ID,Name from recordtype where SObjectType = 'Contract' and Name = 'IME Parent Contract'];
           
           Contract contrct = new Contract();
           contrct.Name = 'testcontractnew';
           contrct.AccountId = acct.id;
           contrct.Billing_Country__c = contry.id;
           contrct.Status = 'Draft';
           contrct.StartDate = Date.today();
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.RecordTypeId = rectypCont.Id;
       	   contrct.IME_Annual_Value_Opportunities__c = 2000;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
           contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
       
           Contract contrct1 = new Contract();
           contrct1.Name = 'testcontractnew1';
           contrct1.AccountId = acct.id;
           contrct1.Billing_Country__c = contry.id;
           contrct1.Status = 'Draft';
           contrct1.StartDate = Date.today();
           contrct1.IME_Contract_Term_Type__c = 'Fixed term';
           contrct1.ContractTerm = 12;
           contrct1.IM_Renewal_Term__c = 24;
           contrct1.IME_Expiration_Notice_days__c = 60;
           contrct1.Contract_Type__c = 'IM Standard';
           contrct1.IM_Contract_Category__c = 'Single Product';
           contrct1.IME_Contract_Version__c = 'NDA';
           contrct1.IME_MFP_Clause__c = 'YES';
           contrct1.IME_Non_Standard_Clause__c = 'YES';
           contrct1.IME_Other__c = True;
           contrct1.RecordTypeId = rectypCont.Id;
           contrct1.IME_Copy_to_all__c = True;
           contrct1.IME_Price_Increase_Type_Storage__c='Regular Increase';
           contrct1.IME_Fixed_Pricing_Period_months_Storage__c=3;
       	   //contrct.IME_Annual_Value_Opportunities__c = 2000;
           insert contrct1;
           Test.startTest();    
           Opportunity o = new Opportunity(name = 'c'
                                          ,AccountId = acct.id
                                          ,Source_System__c = 'SKP'
                                          ,Billing_Country__c = contry.id 
                                          ,Lead_Source_Most_Recent__c = 'x'
                                          //,StageName = '7 - Closed'
                                          ,StageName = '1 - Qualification'
                                          ,RecordTypeId = EUOppType.id
                                          ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                          ,IME_Reason_Won__c = 'Price'
                                          ,CloseDate = System.today()
                                          ,IME_Contract__c = contrct.id,
                                          //,CurrencyIsoCode='GBP',
                                          Amount = 20000 
                                          );
                                          
           insert o;
       	   Test.stopTest();  
           o.IME_Contract__c = contrct1.id;
       	   update o;
       
       	   delete o;
   }
    
}