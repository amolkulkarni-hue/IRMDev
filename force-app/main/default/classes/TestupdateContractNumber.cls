@isTest(seealldata=false)
private class TestupdateContractNumber {
    static testMethod void runTest() {
        
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Canada';
        setting.Object_Name__c = 'Account';
        insert setting;
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        Profile p = [Select id from profile where name = 'IME_Super_User'];
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
        //list of new country codes to name
        list<String> contractIds = new list<string>();
        
        //list of parent contracts for which addendums must be re-named
        Map<String, String> parentNameMap = new Map<String, String>();
        
        //used to exclude addendums
        RecordType rt = [Select id, name 
                         from RecordType 
                         where SObjectType = 'Contract'
                         and name = 'IME Parent Contract'];
        
        //pw_cc__Country__c cntry =[Select id from pw_cc__Country__c where name = 'United States']; 
        
        account a = new Account(name='x',BillingCountry='United States');
        insert a;
        
        
        AccountShare ash = new AccountShare( UserOrGroupId = u.id
                                            ,AccountId = a.id
                                            ,AccountAccessLevel = 'Read'
                                            ,OpportunityAccessLevel='Read'
                                            ,ContactAccessLevel = 'Read'
                                            ,CaseAccessLevel = 'Read');
        insert ash;
        Contract ca;
        //OpportunityShare os = new OpportunityShare(os.)
        System.runAs(u)
            
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        {
            
            Opportunity o = new Opportunity(name = 'c'
                                            ,Source_System__c = 'SKP Europe'
                                            ,Billing_Country__c = cntry.id 
                                            ,Lead_Source_Most_Recent__c = 'x'
                                            ,CloseDate = date.today()
                                            ,StageName = '1 - Qualification'
                                            ,IM_Servicing_Region__c ='London'
                                            ,IME_Reason_Won__c = 'Benchmarking'
                                            ,IM_Commit_to_Forecast__c = true
                                            ,IM_Stage_5_Entered_Date__c  = System.today()
                                            ,accountId = a.id
                                            ,IM_Booked_Date__c = System.today());
            
            
            insert o;       
            
            Recordtype rectypCont = [Select ID,Name from recordtype where SObjectType = 'Contract' and Name = 'IME Addendum'];
            
            
            updateContractNumber.isTriggered = true;//prevent the trigger from firing
            
            Contract c = new Contract(IM_DRCi_Contract_Number__c = '100-123-'+System.now().format()
                                      ,Name = 'test contract new'
                                      ,RecordTypeId= rectypCont.Id
                                      ,Status = 'Draft'
                                      ,StartDate = Date.today()
                                      ,ContractTerm = 12
                                      ,Contract_Type__c = 'IM Standard'
                                      ,IME_Contract_Version__c = 'NDA'
                                      ,IME_MFP_Clause__c = 'YES'
                                      ,IME_Non_Standard_Clause__c = 'YES'
                                      ,IME_Other__c = True
                                      ,IM_Contract_Category__c= 'Single Product'
                                      ,Billing_Country__c =cntry.id 
                                      //,Status = 'Activated'
                                      ,AccountId = a.id);
            insert c;
            
            contractIds.add(c.Id);     
            parentNameMap.put(c.Id,c.IM_Country_Code__c); 
            
            
            ca = new Contract(IM_DRCi_Contract_Number__c = '101'
                              ,Name = 'test contract new1'
                              ,RecordTypeId = rt.Id
                              ,Status = 'Draft'
                              ,StartDate = Date.today()
                              ,ContractTerm = 12
                              ,Contract_Type__c = 'IM Standard'
                              ,IME_Contract_Version__c = 'NDA'
                              ,IME_MFP_Clause__c = 'YES'
                              ,IME_Non_Standard_Clause__c = 'YES'
                              ,IME_Other__c = True
                              ,IM_Contract_Category__c= 'Single Product'
                              ,Main_Contract__c = c.id
                              ,AccountId = a.id
                              ,IME_Copy_to_all__c = True
                              ,IME_Price_Increase_Type_Storage__c='Regular Increase'
                              ,IME_Fixed_Pricing_Period_months_Storage__c=3
                              ,Billing_Country__c =cntry.id );
            insert ca;
            contractIds.add(ca.Id); 
        }      
        test.startTest();
        updateContractNumber.generateContractNumber(contractIds);
        
        updateContractNumber.updateAddendumNumber(parentNameMap);
        contractIds.clear();
        contractIds.add(ca.Id);    
        updateContractNumber.generateContractNumber(contractIds);
        test.stopTest();
        
    }
}