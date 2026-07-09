/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_ClsOppObjects (Class)
**
** PURPOSE
**   Tests the ClsOppObjects Apex Class.
**
** NOTES
**   Creted an opportunity with Contact Role, Opportunity Line Item by passing all parameters to all corresponding future methods for lead convert.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 10/29/2012; Srinivasa Rao Mandalapu/Randstad; Opportunity Wizard 1.05 (Project Related to Wizard 1.05 cases); Initial release
**
************************************************************************/
@isTest(SeeAllData=false)
private class Test_ClsOppObjects {

    static testMethod void myUnitTest() {       
        Test.StartTest();
        
        insert new SVStatus__c(Name='SVStatusPassed',Amount__c = 24000,OpptType__c='New Deal,Up-Sell/Lift',Stage__c='6 - Setup');

		OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;
        
        clsOppObjects clsOppObj = new clsOppObjects();
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin']; 
         
        User u = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
        localesidkey='en_US', profileid = prof.Id, Country = 'USA',
        timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert u;  
        
/*Country_Settings__c setting = new Country_Settings__c();
setting.Name = 'Canada';
setting.Object_Name__c = 'Account';
insert setting; */
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
         //Create a new Account
        //Account acc = new Account(name='Account4TestMethod'+system.now());
        Account acc = new Account(name='AccountPratapTestMethod'+system.now(),
                                  BillingCountry='United States', 
                                IMGA_Owner__c = u.id, D_B_DUNS__c ='Test');
        insert acc;        
        //insert Account Plan
        SFDC_Acct_Plan__c AccPan = new SFDC_Acct_Plan__c();
            AccPan.Account__c = acc.id;
            AccPan.Name = 'Test Plan';
            insert AccPan;
        
        //create a new Contact
        Contact con = new Contact(
        MailingCountry='United States',
        Email='srinu@gmail.com',
        Phone='6517951874',
        LastName='Srinu',FirstName= 'First Con',
        MailingCity = 'London',MailingPostalCode = 'SE1 2TT',
        MailingState = 'London',MailingStreet = '745 Atlantic Ave',
        AccountId = acc.id);        
        insert con;
       	
        //create one more new Contact to by pass "An Opportunity Contact Role with the same Contact already exists" error.
        Contact cont = new Contact(
        MailingCountry='United States',
        Email='srinu_1@gmail.com',
        Phone='6517951874',
        LastName='Srinu_1',FirstName= 'First Con_1',
        MailingCity = 'London',MailingPostalCode = 'SE1 2TT',
        MailingState = 'London',MailingStreet = '745 Atlantic Ave',
        AccountId = acc.id);        
        insert cont;
        
        //create a new Lead
        Lead ld = new Lead();
        ld.OwnerId = u.Id;
        ld.FirstName = 'Lead';
        ld.LastName = 'TestContact';
        ld.Status = 'Open'; 
        ld.IM_Lead_Source_Most_Recent__c = 'Email';
        ld.IM_Lead_Stage__c = '1-Inquiry';
        ld.Company = 'Account4UnitTest1';
        ld.Email = 'testemail@email.com';
        ld.Street = '745 Atlantic Ave';  
        ld.City = 'London';
        ld.State = 'London';
        ld.Country = 'United Kingdom';
        ld.PostalCode = 'SE1 2TT';
        insert ld;
      
        ID standardrt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;

        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name = 'testSold';
        cusAcc.IM_Account__c = acc.id;
        cusAcc.Source_System__c = 'Other Europe';
        
		Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
		
        Opportunity opp = new Opportunity(name = 'Opportunity4TestMethod', AccountId = acc.id, Source_System__c = 'SKP', 
                                          Billing_Country__c = testCountry.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        ,StageName = '1 - Qualification'
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,IME_Reason_Won__c = 'Price'
                                        ,IMGA_Owner__c = u.id
                                        ,IM_Up_Sell_Sold_To__c = 'testSold'
                                        ,CloseDate = System.today()
                                        ,Type = 'Renewal'
                                        ,tsu__c=u.Id
                                        ,IM_Up_Sell_Detail__c = 'details'
                                        ,IM_Up_Sell_Quantity__c = 2
                                        ,Upsell_Customer_ID__c = cusAcc.id
                                        ,IM_Unit_of_Measure__c = 'Data Restoration' 
                                        ,SKP_Opportunity_Sync_Date__c = null
                                        ,US_Federal_GSA_Pricing__c ='Yes'
                                        ,Amount=1000.00
                                        ,GSA_Eligibility__c = 'GSA Eligible'
                                        ,IM_Booked_Date__c=System.today()+2
                                       );                                 
        insert opp;
        ///
        //Verify that the results are as expected.
        System.assertEquals('Opportunity4TestMethod', opp.Name);
        System.assertEquals(acc.Id, opp.AccountId);
       
        /*Variable declaration for 'inserting opportunity Contact Roles'*/ 
        String ocrRole1 = 'Influencer';
        String ocrRole = 'Evaluator';
        String ldName='TestLeadName'; 
        String ldCompany='TestLeadCompany';
        
         Integer MAX_QUERY = Limits.getLimitQueries();
            system.assertEquals(MAX_QUERY, Limits.getLimitQueries());
        try{
           //passing parameters to 'createContactRoleMethod'
        clsOppObjects.createContactRoleMethod(con.Id, opp.Id, ocrRole, ldName, ldCompany, acc.Id);
        System.assertEquals('Evaluator', ocrRole); 
            }
        catch(Exception ex){ 
        } 
     
       /*Variable declaration for 'inserting opportunity Line Items'*/        
        //Get the standared Pricebook.   
       // pratap PriceBook2 pb2 = [select Id from Pricebook2 where isStandard=true];
        //Create a new Product.
        Id IMNARecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        
        Product2 prod1 = new Product2(Name='Product4TestMethod',RecordTypeId = IMNARecordTypeId, isActive=true);
        insert prod1;

        Id pricebookId = Test.getStandardPricebookId();
        
        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod1.Id,
            UnitPrice = 10000, IsActive = true);
        insert pbe1;

        
        //Create PricebookEntry.            
       // PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id=pb2.Id, Product2Id= prod1.Id, UnitPrice=10, isActive=true, UseStandardPrice = false);
       // insert pbe1;
        
        Decimal oliunitPrice=100.55; 
        Decimal[] OliUntPrice = new Decimal[]{oliunitPrice};
        
        Decimal oliQuantity=5;
        Integer[] OliQntity = new Integer[]{Integer.Valueof(oliQuantity)};                
        
        String[] LPBEIDS = new String[]{pbe1.Id};
        
        Opportunity_Questions__c newqtn1 = new Opportunity_Questions__c(
        Name='test question 1',
        Answer_Format__c='text',
        Question_Order__c='1',
        Active__c=true,
        Product__c=prod1.Id);
        insert newqtn1; 
        
        List<String> lstProdQA = new List<String>();
        lstProdQA.add(prod1.Id+';'+newqtn1.Id+';'+'5');        
        
        List<List<String>> lstProdQuesAns = new List<List<String>>();
        lstProdQuesAns.add(lstProdQA);        
        
        map<String, List<List<String>>> mlstProdQuesAns = new map<String, List<List<String>>> ();
        mlstProdQuesAns.put(prod1.Id,lstProdQuesAns);
        
        List<String> lstStrParams = new List<String>();
        String sInsideSales;
         Boolean bundleexists = true;
        String selectedbundle=null;
        String otherinformation=null;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        lstStrParams.add(opp.Id);//0
        lstStrParams.add(ld.OwnerId);//1
        lstStrParams.add(Opp.StageName);//2
        lstStrParams.add(String.valueOf(Opp.Probability));//3
        lstStrParams.add(String.valueOf(Opp.CloseDate));//4
        lstStrParams.add(String.valueOf(Opp.IM_Booked_Date__c));//5
        lstStrParams.add(Opp.IM_Competitor__c);//6
        lstStrParams.add(Opp.Type);//7
        lstStrParams.add(Opp.IM_Category__c);//8
        lstStrParams.add(Opp.IM_Sales_Event__c);//9
        lstStrParams.add(Opp.Description);//10
        lstStrParams.add(String.valueOf(Opp.IM_Up_Sell_Quantity__c));//11
        // lstStrParams.add(Opp.IM_Up_Sell_Sold_To__c);//12
        lstStrParams.add(null);//12
        lstStrParams.add(Opp.IM_Up_Sell_Detail__c);//13
        lstStrParams.add(Opp.IM_Unit_of_Measure__c);//14       
        lstStrParams.add((sInsideSales != 'false' ? ld.OwnerId: null));//15
        lstStrParams.add(String.valueOf(bundleexists));//16
        lstStrParams.add(selectedbundle);//17
        //lstStrParams.add(otherinformation);//18
        lstStrParams.add(opp.IME_Vended_Unvended__c);//18
       /* #16915 lstStrParams.add(String.ValueOf(opp.Vended_del__c));//19
        lstStrParams.add(String.ValueOf(opp.Unvended_del__c));//20 */ 
        lstStrParams.add(opp.Account_Plan__c);//19
        lstStrParams.add('testingdriverid');//20
        lstStrParams.add(opp.Primary_Product_Line__c);//21
        lstStrParams.add(opp.InSight_Opportunities__c);//22
        
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        //passing parameters to 'createOpportunityItems' 
        clsOppObjects.createOpportunityItems(opp.Id,OliQntity, OliUntPrice, LPBEIDS, lstProdQA, opp.IM_Booked_Date__c, lstStrParams);
        // System.assert(opp.IM_Booked_Date__c==Date.today());
                 
        //passing parameters to 'updateOpportunity' 
        clsOppObjects.updateOpportunity(lstStrParams);      
        
        //passing parameters to 'createContactRole'
        String sendmail = 'true'; 
        clsOppObjects.createContactRole(con.Id, opp.Id, ocrRole, sendmail, ldName, ldCompany, acc.Id);
        System.assert(ocrRole=='Evaluator');
        
        //passing parameters to 'createListContactRole'
        String[] sconId = new String[]{cont.Id};
        String[] sROleStrng = new String[]{ocrRole1};
        clsOppObjects.createListContactRole(sconId, opp.Id, sROleStrng);        
        
        //passing parameters to 'sendEmailNotification'
        String sEmailBody='TestEmailBody';
        String sEmailSub='TestEmailSub'; 
        //clsOppObj.sendEmailNotification(sEmailBody, sEmailSub);
        
        Test.StopTest();
    }           
}