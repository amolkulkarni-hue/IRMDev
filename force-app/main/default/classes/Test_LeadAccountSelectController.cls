/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 08/13/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - GSA Modification (Case # 01622446); Initial release
* Modified By: Abarna Jeyasekaran on 13-Aug-2018
     *        -- Optimized for resolution of case #07318783
              -- Updated to include pagination, to allow state abbreviation and to optimize Search       

 */
@isTest(SeeAllData = true) 
private class Test_LeadAccountSelectController {

    static testMethod void myUnitTest() {
        
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];  
        User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;
        
        IM_Country__c testCountry = new IM_Country__c(Name='Germany');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='Germany');
        insert country;
        
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Germany';
        setting.object_name__c = 'Account';
        insert setting;
        
        Account A = new Account(name='Account4TestLeadAccSelect', BillingStreet= '683 c Parker St',BillingCity= 'Boston',
                                BillingState = 'MA', BillingPostalCode = '02120', BillingCountry = 'Germany',
                               IMGA_Owner__c= u.id);
        insert A;
        List<Account> acc = new List<Account>();
        Lead l = new Lead();
        l.FirstName = 'Lead';
        l.LastName = 'TestContact';
        l.Status = 'Open'; 
        l.IM_Lead_Source_Most_Recent__c = 'Email';
        l.IM_Lead_Stage__c = '1-Inquiry'; 
        l.Company = 'Account4UnitTest';
        l.Email = 'testemail@email.com';
        l.Street = '745 Atlantic Ave';
        l.City = 'London';
        l.State = 'London';
        l.Country = 'Germany';
        l.PostalCode = 'SE1 2TT';
        insert l;
         
         LeadAccountSelectController lc = new LeadAccountSelectController(new ApexPages.StandardController(l));
         lc.accName ='Account4TestLeadAcc';
         lc.city = 'Boston';
         lc.state ='MA';
         lc.postalCode = '02120';         
         lc.country = 'United States';
            
         lc.generateQuery();
         
         lc.getaccName();
         lc.setaccName('Account4TestLeadAcc');
         
         lc.getcity();
         lc.setcity('Boston');
         
         lc.getstate();
         lc.setstate('MA');
         
         lc.getpostalCode();
         lc.setpostalCode('02120');
                 
         lc.getcountry();
         lc.setcountry('United States'); 
         
         lc.getAccounts();
         lc.Next();
         lc.last();
         lc.previous();
         lc.first();
         lc.gotopage();
         lc.con.Previous();
         lc.con.Next();
         lc.con.getPageNumber();                
    }
}