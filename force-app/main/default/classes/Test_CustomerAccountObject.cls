/*Developer Name: Madhu Paladugu
Company       : TheCloudFountain Inc.
Desrciption   : Test utility for CustomerAccountObject trigger.
Date          : 12/3/12
case number   : 00924109   */
@isTest
private class Test_CustomerAccountObject
{ 
    static TestMethod void doUnitTest()
    {      
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        
        
        
        tA = new Trigger_Activation_Settings__c();
        tA.name = 'AccountCountryLookup';
        tA.Object__c = 'IM_Customer_Account__c';
        tA.Trigger__c = 'AccountCountryLookup';
        tA.Value__c = 'True';
        updatesettings.add(tA);
        
        tA = new Trigger_Activation_Settings__c();
        tA.name = 'numberOfCustomerAccounts';
        tA.Object__c = 'IM_Customer_Account__c';
        tA.Trigger__c = 'numberOfCustomerAccounts';
        tA.Value__c = 'True';
        updatesettings.add(tA);
        
        tA = new Trigger_Activation_Settings__c();
        tA.name = 'FlagRecallCustAccountByCity';
        tA.Object__c = 'IM_Customer_Account__c';
        tA.Trigger__c = 'FlagRecallCustAccountByCity';
        tA.Value__c = 'True';
        updatesettings.add(tA);
        
        insert updatesettings;
        
              
        List<Quote_Indicators_Sync__c> quoteIndList = new List<Quote_Indicators_Sync__c>();
        Quote_Indicators_Sync__c qisc = new Quote_Indicators_Sync__c();
        qisc.Name ='Admin Fee';
        qisc.Customer_Account_API_Name__c ='Admin_Fee_Indicator__c';
        qisc.Pricing_Contract_API_Name__c ='Admin_Fee__c';
        qisc.Quote_API_Name__c ='Admin_Fee__c';
        quoteIndList.add(qisc);   
        
        insert quoteIndList;
        
        List<IM_Customer_Account__c> cus_list;
        List<IM_Customer_Account__c> cus_list_update;
        
        //insert Account
        //Account  A = new Account(name='Account4TestMethod', BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
        Account  A = new Account(name='Account4TestMethod', BillingStreet='test',BillingState='New York',BillingCity='Buffalo',BillingCountry='United States');
        insert A;
        
        
        cus_list=new List<IM_Customer_Account__c>();
        cus_list_update=new List<IM_Customer_Account__c>();
        
        
        //insert customer
        IM_Customer_Account__c cus=new IM_Customer_Account__c(Name='test Cust',IM_Account__c=A.id,Risk_Status__c='At Risk',IM_Oracle_ID__c='123456',Rate_Table_ID__c='test rate table',Source_System__c='SKP NA');
        cus_list.add(cus);
        
        //insert customer1
        IM_Customer_Account__c cus1=new IM_Customer_Account__c(Name='test Cust',IM_Account__c=A.id,Risk_Status__c='At Risk',IM_Oracle_ID__c='123456',Rate_Table_ID__c='test rate table1',Source_System__c='SB NA');
        cus_list.add(cus1);
        
        insert cus_list;           
    }     
        
    }