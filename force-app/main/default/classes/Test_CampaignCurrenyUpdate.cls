/**
*Author: NAGESH EARANTI
*Company: HCL America
*Date: 10-06-2011
*
*Comments:
*Test Class for CampaignCurrenyUpdate trigger
*
*/

@isTest
private class Test_CampaignCurrenyUpdate {

    static testMethod void myUnitTest() {
        
        
        Profile p = [Select id from profile where name = 'IM_Custom Sys Admin'];
        
        User u = new User(alias = 'hasrole', email='ptkachenko@malkosus.com'
                           ,emailencodingkey='UTF-8'
                           , lastname='Testing', languagelocalekey='en_US'
                           , localesidkey='en_US', profileid = p.id
                           , timezonesidkey='America/Los_Angeles'
                           , username='test@malkosus.com'
                           ,Division = 'IME'
                           , Country = 'United Kingdom');
        insert u;
        
        System.runAs(u)
    	{
    	Campaign  c  = new Campaign (
    	OwnerId=u.id,
    	Name='Test',
    	StartDate=system.today(),
    	BudgetedCost=7895.50,
    	NumberSent=32,
    	ActualCost=200,
    	IM_Budget__c=7895,
    	IM_Estimated_Total_Leads__c=20,
    	IM_Objective__c='Cross Sell',
    	Description='test',
    	IM_Campaign_Service_Categories__c='Data Products',
    	IM_Campaign_List_Source__c='Contact Us',
    	IM_Campaign_Communication_Channel__c='Direct Mail',
    	IM_Campaign_Segment__c='Enterprise',
    	IM_Region__c='Europe',
    	IM_Division__c='Digital',
    	IM_Department__c='ISR',
    	CurrencyIsoCode = 'EUR'	
    	);
    	Insert c;
    }
    }
    static testMethod void myUnitTest1() {
        
        
        Profile p1 = [Select id from profile where name = 'IM_Custom Sys Admin'];
        
        User u1 = new User(alias = 'hasrole', email='ptkachenko@malkosus.com'
                           ,emailencodingkey='UTF-8'
                           , lastname='Testing', languagelocalekey='en_US'
                           , localesidkey='en_US', profileid = p1.id
                           , timezonesidkey='America/Los_Angeles'
                           , username='test@malkosus.com'
                           ,Division = 'Global'
                           , Country = 'United Kingdom');
        insert u1;
        
        System.runAs(u1)
    	{
    	Campaign  c1  = new Campaign (
    	OwnerId=u1.id,
    	Name='Test',
    	StartDate=system.today(),
    	BudgetedCost=7895.50,
    	NumberSent=32,
    	ActualCost=200,
    	IM_Budget__c=7895,
    	IM_Estimated_Total_Leads__c=20,
    	IM_Objective__c='Cross Sell',
    	Description='test',
    	IM_Campaign_Service_Categories__c='Data Products',
    	IM_Campaign_List_Source__c='Contact Us',
    	IM_Campaign_Communication_Channel__c='Direct Mail',
    	IM_Campaign_Segment__c='Enterprise',
    	IM_Region__c='Europe',
    	IM_Division__c='Digital',
    	IM_Department__c='ISR',
    	CurrencyIsoCode = 'EUR'	
    	);
    	Insert c1;
    }
    }
    
}