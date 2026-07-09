/** 
 *Author: Srinivasa Rao Mandalapu
 *Date: 11/29/12
 *Comments: Test class for LeadController class.
 */
@isTest(SeeAllData=true)
public with sharing class Test_LeadController {
    static testMethod void myUnitTest(){
        //LeadController ldcontlr = new LeadController();
        //Create new test user
        Profile p = [Select id from profile where name = 'IME_In_Country_Admin'];
        User u = new User(alias = 'talias', email='test.user@email.com',
                          emailencodingkey='UTF-8',
                          lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', ProfileId = p.Id,
                          timezonesidkey='America/New_York',
                          username='Srinu.Invalid@IM.com',
                          Country = 'USA');
        
        insert u;
        //Prepare a Contact
        
        IM_Country__c testCountry = new IM_Country__c(Name='Germany');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='Germany');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Germany';
        setting.object_name__c = 'Account';
        insert setting;
        
        Account a = new Account(Name='Account4&;!@%#-UnitTest', BillingCountry = 'Germany',
                            BillingStreet = '745 Atlantic Ave',
                            BillingPostalCode = 'SE1 2TT',
                            BillingCity = 'Boston',
                            BillingState = 'MA',
                            IMGA_Owner__c = u.id);
        insert a;

        Contact c = new Contact(LastName='TestContact',
                            FirstName='Contact',
                            AccountId=a.Id,
                            Email='testemail@email.com',
                            MailingStreet = '745 Atlantic Ave',
                            MailingCity = 'Boston', 
                            MailingCountry = 'Germany', 
                            MailingPostalCode = 'SE1 2TT', 
                            MailingState = 'MA');
        insert c;
        
        //Create a new Lead
        Lead l = new Lead();
        l.FirstName = 'Lead';
        l.LastName = 'TestContact';
        l.Status = 'Open'; 
        l.IM_Lead_Source_Most_Recent__c = 'Email';
        //l.IM_Lead_Source_Most_Recent_Details__c = 'Event';
        l.IM_Lead_Stage__c = '1-Inquiry';
        l.Company = 'Account4&;!@%#-UnitTest';
        l.Email = 'testemail@email.com';
        l.Street = '745 Atlantic Ave';
        l.City = 'London';
        l.State = 'London';
        l.Country = 'Germany';
        l.PostalCode = 'SE1 2TT';
        //l.RecordTypeId = imRecTypeId;
        insert l;
        
        //Convert the Lead
        //Database.LeadConvert lc = new database.LeadConvert();
        //lc.showClientAgreement();
        
        //}
        Apexpages.StandardController stdcontroller = new Apexpages.StandardController(l);
        System.currentPageReference().getParameters().put('cId',c.id);
        LeadController ldcontlr = new LeadController(stdcontroller);
        ldcontlr.setAccname(a.Name);
        ldcontlr.ConvertLead();
        ldcontlr.getConvertStatusList();
        ldcontlr.getTask();
        ldcontlr.getAccname();
        ldcontlr.getOpportunityname();
        //ldcontlr.getProxyObject();
        ldcontlr.getItems();
        //ldcontlr.setAccname(a.Name);
        String optyname = 'Test&#%!@;-^Opty';
        ldcontlr.setOpportunityname(optyname);
        Boolean flagshowClientAgreement=ldcontlr.showClientAgreement;
        Boolean flagshowTaskNotification=ldcontlr.showTaskNotification;
        Boolean flagIsConverted=ldcontlr.IsConverted;
        //ldcontlr.showClientAgreement();
    }
}