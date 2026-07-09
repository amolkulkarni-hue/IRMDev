/** 
*Author            : Vinutha Iyengar
*Date              : 11/26/2018
*Comments          : Test class for AccountObject Trigger under Account

*/
@isTest
private class Test_AccountObject {
    
    public static void setup()
    {
        List<Trigger_Activation_Settings__c> triggerSettings = new List<Trigger_Activation_Settings__c>();
        
        Trigger_Activation_Settings__c TAS1 = new Trigger_Activation_Settings__c(Object__c ='Account',Name='preventAccountCreateTrigger',Trigger__c='preventAccountCreateTrigger', Value__c='True');
        triggerSettings.add(TAS1);
        Trigger_Activation_Settings__c TAS2 = new Trigger_Activation_Settings__c(Object__c ='Account',Name='AccountCountryLookup',Trigger__c='AccountCountryLookup', Value__c='True');
        triggerSettings.add(TAS2);
        Trigger_Activation_Settings__c TAS3 = new Trigger_Activation_Settings__c(Object__c ='Account',Name='AccountPostalCode',Trigger__c='AccountPostalCode', Value__c='True');
        triggerSettings.add(TAS3);
        Trigger_Activation_Settings__c TAS4 = new Trigger_Activation_Settings__c(Object__c ='Account',Name='FlagRecallAccountByCity',Trigger__c='FlagRecallAccountByCity', Value__c='True');
        triggerSettings.add(TAS4);
        Trigger_Activation_Settings__c TAS5 = new Trigger_Activation_Settings__c(Object__c ='Account',Name='BlockDummyAccountEdit',Trigger__c='BlockDummyAccountEdit', Value__c='True');
        triggerSettings.add(TAS5);
        Trigger_Activation_Settings__c TAS6 = new Trigger_Activation_Settings__c(Object__c ='Account',Name='RealignRateTableOwner',Trigger__c='RealignRateTableOwner', Value__c='True');
        triggerSettings.add(TAS6);
        Trigger_Activation_Settings__c TAS7 = new Trigger_Activation_Settings__c(Object__c ='Account',Name='CopyRegToRelatedObjects',Trigger__c='CopyRegToRelatedObjects', Value__c='True');
        triggerSettings.add(TAS7);
        
        insert triggerSettings;
        
    }
    
    static testMethod void overallCoverage()
    {
        setup();
        Account acc = new Account(Name='Testaccount1'+system.now());
        insert acc;
    }
    
    static testMethod void testAccountCountryLookupTrigger()
    {
        setup();
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        
        Account acc = new Account(Name='Testaccount1'+system.now(), BillingPostalCode='11209', BillingCountry = 'United States',BillingState = 'NY');
        insert acc;
    }
    
    static testMethod void testDummyAccount()
    {
        setup();
        
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
        setup();
        
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