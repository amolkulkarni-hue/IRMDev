@isTest
private class TestDRCiLaunchPageCtl {
    
    static testMethod void runTest() {
         /* 
          Create the Data for the test
        */
        
        
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
                                
           
       
           
        //System.runAs(u)
        //{
           account a = new Account(name='x');
           insert a;
            //Create the opportunity
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
           Opportunity o = new Opportunity(name = 'c'
                                          ,AccountId = a.id
                                          ,Source_System__c = 'SKP'
                                          ,Billing_Country__c = cntry.id 
                                          ,Lead_Source_Most_Recent__c = 'x'
                                         ,CloseDate = date.today()
                                      ,StageName = '1 - Qualification'
                                          , RecordTypeId = EUOppType.Id
                                          ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                          ,IME_Reason_Won__c = 'Price'
                                          ,IM_Booked_Date__c = System.today());
                                          
           insert o;
            
           //create the contract
           Contract c = new Contract(IM_DRCi_Contract_Number__c = '10'
                                    ,AccountId = a.id
                                    ,Opportunity__c = o.id
                                    ,Billing_Country__c =cntry.id,IME_Other__c = True );
           insert c;
           
           PageReference pageRef = Page.DRCiLauncePage;
           //set the Visualforce page for the test  
           Test.setCurrentPage(pageRef);
           
           ApexPages.currentPage().getParameters().put('contractId', c.Id);
            
          
            //Instantiate and construct the controller class.
            DRCiLaunchPageCtl ctl = new DRCiLaunchPageCtl();
            ctl.testBypass = true;
            
            //execute the controller methods
            ctl.getDocs();
            ctl.cancel();
           

         cntry = CountryNameTranslator.getOrCreateTestCountry
                                                    ( (new IM_Country__c(name = 'United States',
                                                                         Region__c = 'North America')));
           c.Billing_Country__c = cntry.id;
           
           update c;
           
           Test.setCurrentPage(pageRef);
           ApexPages.currentPage().getParameters().put('contractId', c.Id);
            
          
            //Instantiate and construct the controller class.
            ctl = new DRCiLaunchPageCtl();
            ctl.testBypass = true;
            //execute the controller methods
            ctl.getDocs();
            ctl.testBypass =true;
            ctl.getDocs();
            ctl.cancel();
            
            
        }
        
    //}

        

}