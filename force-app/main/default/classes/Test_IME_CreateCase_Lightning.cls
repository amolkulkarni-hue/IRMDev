@isTest
public class Test_IME_CreateCase_Lightning
{
    public static testmethod void TestCreateAccountSetupCase()
    {
        Test.startTest();
        //RecordType rtype = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IM Employees Support Case'];
        
        ID recTypeId =  DataFactory.getRecordTypeId('Case','IM Employees Support Case');
        
        RecordType renewalOppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'IME Standard Opportunity' LIMIT 1];
     
        system.debug('recTypeId----'+recTypeId);
        //Group grp = [select Id,Name from Group where Name = 'IME UK Account Setup' and Type = 'Queue' LIMIT 1];
        
        //Profile p = [Select id from profile where name = 'IME_Custom Sys Admin'];
        
        User userId1 = [SELECT id,name From USER where id =:UserInfo.getUserId()];
        
        /*User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
,emailencodingkey='UTF-8'
, lastname='Testing', languagelocalekey='en_US'
, localesidkey='en_US', profileid = p.id
, timezonesidkey='America/Los_Angeles'
, username='userwithrole@testorg.com'
, Country = 'United Kingdom',
CurrencyIsoCode= 'USD');*/
        
        User u = DataFactory.createUsers(1)[0];
        
        IM_Country__c mainName = new IM_Country__c();
        mainName.Name = 'Europe';
        //mainName.Country_Code__c = 'US'; // Add a country code if required
        insert mainName;
        
        // Alternative Country Name
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        country.IM_Country__c = mainName.Id;
        country.Alternative_Name__c = 'Europe';
        insert country;
        
        // Country Settings
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Canada';
        setting.object_name__c = 'Account';
        insert setting;
        
        
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        //System.Runas(u)
        {
            
            Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.BillingCountry = 'Europe';
        testAccount.BillingState = 'NY';
        testAccount.BillingPostalCode = '10001';
       // testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert testAccount;
            
            Opportunity oppty1 = new Opportunity();
            oppty1.Name = 'Test Opportunity';
            oppty1.AccountId = testAccount.id;
            oppty1.Type = 'New Deal';       
            oppty1.StageName = '1 - Qualification';
            oppty1.RecordTypeId = renewalOppRT.id;
           // oppty1.Amount = 1000;
            oppty1.CloseDate = Date.today();
            oppty1.IM_Booked_Date__c = Date.today()+1;
            oppty1.Billing_Country__c = mainName.id;
            oppty1.LeadSource = 'Click to Call';
            //oppty1.CurrencyIsoCode = 'GBP';
            /*Country_Settings__c setting = new Country_Settings__c();
			 setting.Name = 'Canada';
			 setting.Object_Name__c = 'Account';
             insert setting; */
            insert oppty1;
            
            Case cas = new Case();
            cas.OwnerId = userInfo.getUserId();
            cas.Related_To__c  = 'Customer Account/Client Code';
            cas.Issue__c  = 'Account Set Up';
            cas.RecordTypeId = recTypeId;
            cas.Status = 'New';
            cas.Origin = 'Internal';
            cas.IM_Division__c = 'IME';
            cas.Priority = 'Medium';
            cas.Subject = 'Account Setup';
            cas.Description = 'Please Setup Account for the following Opportunity:'+oppty1.Name+System.label.IME_ServerURL+oppty1.id;
            cas.AccountId = oppty1.accountid;
            cas.IM_Employee_Contact__c = userInfo.getUserId();
            cas.URL__c = System.label.IME_ServerURL+oppty1.id;
            
            insert cas;
            PageReference myVfPage = Page.IME_CreateCase_Lightning;
            Test.setCurrentPage(myVfPage);
            ApexPages.currentPage().getParameters().put('oppid',oppty1.Id);
            ApexPages.currentPage().getParameters().put('Type','Request Contract');
            IME_CreateCase_Lightning cs =new IME_CreateCase_Lightning();
            // cs.CreateCase();
            //IME_CreateCase_Lightning.createAccountSetupCase(oppty1.id);
            cs.createAccountSetupCase(oppty1.Id);
            cs.createContractCase(oppty1.Id); 
            cs.CreateCase();
            cs.GoToOppty();
            Test.stopTest();
        }
    }
    
    static testmethod void TestCreateRequestContractCase()
    {
        Test.startTest();
        //RecordType rtyp = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IM Employees Support Case'];
        
        ID recTypeId =  DataFactory.getRecordTypeId('Case','IM Employees Support Case');
        
        RecordType renewalOppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'IME Standard Opportunity' LIMIT 1];
  
        
        //Group grp = [select Id,Name from Group where Name = 'IME UK Account Setup' and Type = 'Queue' LIMIT 1];
        
        //Profile p1 = [Select id from profile where name = 'IME_Custom Sys Admin'];
        
        User userId2 = [SELECT id,name From USER where id =:UserInfo.getUserId()];
        
        /*User u1 = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
,emailencodingkey='UTF-8'
, lastname='Testing', languagelocalekey='en_US'
, localesidkey='en_US', profileid = p1.id
, timezonesidkey='America/Los_Angeles'
, username='userwithrole@testorg.com'
, Country = 'United Kingdom',
CurrencyIsoCode= 'USD');*/
        
        User u1 = DataFactory.createUsers(1)[0];
        
        IM_Country__c contry1 = new IM_Country__c();
        contry1.Name = 'Europe';
        insert contry1;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        //System.Runas(u1)
        {
            
            Account acct1 = new Account(Name = 'Test Account');
            insert acct1;
            
            Opportunity oppty2 = new Opportunity();
            oppty2.Name = 'Test Opportunity';
            oppty2.AccountId = acct1.id;
            oppty2.Type = 'New Deal';       
            oppty2.StageName = '1 - Qualification';
            oppty2.Amount = 1000;
            oppty2.CloseDate = Date.today();
            oppty2.RecordTypeId = renewalOppRT.id;
            oppty2.IM_Booked_Date__c = Date.today()+1;
            oppty2.Billing_Country__c = contry1.id;
            oppty2.LeadSource = 'Click to Call';
            oppty2.CurrencyIsoCode = 'GBP';
            Country_Settings__c setting = new Country_Settings__c();
			 setting.Name = 'Canada';
			 setting.Object_Name__c = 'Account';
             insert setting;
            insert oppty2;
            
            Case cas1 = new Case();
            cas1.OwnerId = userInfo.getUserId();
            cas1.Related_To__c  = 'Contracts';
            cas1.Issue__c  = 'Request Contract';
            cas1.RecordTypeId = recTypeId;
            cas1.Status = 'New';
            cas1.Origin = 'Internal';
            cas1.IM_Division__c = 'IME';
            cas1.Priority = 'Medium';
            cas1.Subject = 'Contract Request';
            cas1.Description = 'Please Create Contract for the following Opportunity:'+oppty2.Name+System.label.IME_ServerURL+oppty2.id;
            cas1.AccountId = oppty2.accountid;
            cas1.IM_Employee_Contact__c = userInfo.getUserId();
            cas1.URL__c = System.label.IME_ServerURL+oppty2.id;
            
            insert cas1; 
               PageReference myVfPage = Page.IME_CreateCase_Lightning;
            Test.setCurrentPage(myVfPage);
            ApexPages.currentPage().getParameters().put('oppid',oppty2.Id);
            ApexPages.currentPage().getParameters().put('Type','AccountSetup');

            IME_CreateCase_Lightning cs =new IME_CreateCase_Lightning();
            cs.createAccountSetupCase(oppty2.Id);
            cs.createContractCase(oppty2.Id);
            cs.CreateCase();
            cs.GoToOppty();
            Test.stopTest();
        }
    }
}