@isTest
public class AccountTrigger_Test {
    static testMethod void overallCoverage()
    { 
        Account acc = new Account(Name='Testaccount1'+system.now());
        insert acc;
    }
    
    static testMethod void testAccountCountryLookupTrigger()
    { 
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        
        Account acc = new Account(Name='Testaccount1'+system.now(), BillingPostalCode='11209', BillingCountry = 'United States',BillingState = 'NY');
        insert acc;
    }
    
    static testMethod void testDummyAccount()
    { 
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        
        IM_Country__c testCountry1 = new IM_Country__c(Name='United Kingdom');
        insert testCountry1;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        
        IM_Alternative_Country_Name__c country1 = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry1.Id, Alternative_Name__c='United Kingdom');
        insert country1;
        
        Account acc = new Account(Name='Dummy Account', BillingPostalCode='11209', BillingCountry = 'United States',BillingState = 'NY');
        insert acc;
        
        acc.BillingCountry='United Kingdom';
        try{
            update acc;            
        }
        catch(DmlException e){}
        
        try{
            delete acc;            
        }
        catch(DmlException e){}
    }
    
    static testMethod void testAccount_IME_Contracts()
    { 
        
        Profile p = [SELECT Id FROM Profile WHERE Name='IME_Contracts'];
        
        User u1 = new User(Alias = 'tUsr1',Country='United Kingdom',Email='testUser1@ironmountain.com',EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles', UserName='testUser1@ironmountain.com');
        insert u1;
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        
        Account acc = new Account(Name='Test IME Account', BillingPostalCode='11209', BillingCountry = 'United States',BillingState = 'NY');
        
        System.runAs(u1)
        {
            try{
                insert acc;        
            }
            catch(DmlException e){}
        }  
    }
}