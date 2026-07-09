/** 
 *Author: Srinivasa Rao Mandalapu
 *Date: 12/13/2012
 *Comments: Test class for LeadCompetitorObject Trigger under Lead_Competitor__c.
 */
@isTest(SeeAllData=true)
private class Test_LeadCompetitorObject {
	
	public static String PopulateLeadOwnerEmail=null;
	
    static testMethod void TestPopulateLeadOwnerEmail() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
		List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
		for(Trigger_Activation_Settings__c cs : customsettings){
			if(cs.Object__c == 'Lead_Competitor__c') {
				cs.Value__c='True';
				updatesettings.add(cs);
			}
		}
		update updatesettings;
		
        // TO DO: implement unit test
        //Create a test user who belongs to 'North America' Sales Division.
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];
        
        User u1 = new User();
        u1.FirstName = 'fName';
        u1.LastName = 'lName';
        u1.Email = 'Test@mail.com';
        u1.Username = 'Test9090909@mail.com';
        u1.Alias ='Test909';
        u1.CommunityNickname = 't909';
        u1.TimeZoneSidKey ='America/New_York';
        u1.LocaleSidKey = 'en_US';
        u1.EmailEncodingKey = 'UTF-8';
        u1.ProfileId = p1[0].id;
        u1.LanguageLocaleKey = 'en_US';
        u1.Country = 'United Kingdom';
        u1.Sales_Division__c = 'Europe';
        insert u1;
               
        IM_Country__c testCountry = new IM_Country__c(Name='United Kingdom');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United Kingdom');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United Kingdom';
        setting.object_name__c = 'Account';
        insert setting;
        
        Account A = new Account(name='AccountPratapTestMethod'+system.now(), 
                                  BillingCountry='United Kingdom', 
                                IMGA_Owner__c = u1.id, D_B_DUNS__c ='Test');
        insert A;
               
        //Create a new Lead
        Lead led1 = new Lead();
        led1.FirstName = 'led1fname';
        led1.LastName = 'led1lname';
        led1.Status = 'Open'; 
        led1.IM_Lead_Source_Most_Recent__c = 'Email'; 
        led1.IM_Lead_Stage__c = '1-Inquiry';
        led1.Company = 'Account4UnitTest';
        led1.Email = 'testemail@email.com';
        led1.Street = '745 Atlantic Ave';
        led1.City = 'London';
        led1.State = 'London';
        led1.PostalCode = 'SE1 2TT';
		led1.IM_Functional_Area__c = 'x';
		led1.OwnerId = u1.Id;
        insert led1;
        
        //Create a new Competitor.
        Competitor__c comp = new Competitor__c();
        comp.Name = 'Test Comp';
        insert comp;
        
        //Create a new Lead Competitor.
        Lead_Competitor__c leadComp = new Lead_Competitor__c();
        leadComp.Lead__c = led1.Id;
        leadComp.Competitor__c = comp.Id;
        leadComp.Lead_Owner_Email__c = led1.Owner.Email;
        insert leadComp;
    }    
}