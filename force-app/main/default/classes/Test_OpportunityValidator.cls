@isTest
public class Test_OpportunityValidator {

	@testSetup
	private static void OCR_OpportunityRecordSetup() {
		List < Trigger_Activation_Settings__c > custSettingList = new List < Trigger_Activation_Settings__c > ();
		Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
		tA.name = 'OCR_Validation';
		tA.Object__c = 'Opportunity';
		tA.Trigger__c = 'OCR_Validation';
		tA.Value__c = 'True';
		custSettingList.add(tA);
		insert custSettingList; 

		List < OCRValidationRequiredRecordTypes__c > OCRVaildRTypes = new List < OCRValidationRequiredRecordTypes__c > ();
		OCRValidationRequiredRecordTypes__c OCRVaildRType1 = new OCRValidationRequiredRecordTypes__c();
		OCRVaildRType1.name = 'IME Standard Opportunity';
		OCRVaildRTypes.add(OCRVaildRType1);
		OCRValidationRequiredRecordTypes__c OCRVaildRType2 = new OCRValidationRequiredRecordTypes__c();
		OCRVaildRType2.name = 'Standard Opportunity';
		OCRVaildRTypes.add(OCRVaildRType2);
		insert OCRVaildRTypes;

		List < OCRValidationRequiredStages__c > OCRVaildStages = new List < OCRValidationRequiredStages__c > ();
		OCRValidationRequiredStages__c OCRVaildStage1 = new OCRValidationRequiredStages__c();
		OCRVaildStage1.name = '1 - Qualification';
		OCRVaildStages.add(OCRVaildStage1);
		OCRValidationRequiredStages__c OCRVaildStage2 = new OCRValidationRequiredStages__c();
		OCRVaildStage2.name = '2 - Solution Developed';
		OCRVaildStages.add(OCRVaildStage2);
		insert OCRVaildStages; 

		Profile p = [Select id from profile where name = 'System administrator'];
		User us = new User(alias = 'alias', email = 'email@OCR.com', emailencodingkey = 'UTF-8', lastname = 'lastname_OCR', languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = p.id, timezonesidkey = 'America/Los_Angeles', username = 'email@OCR.com', Country = 'United Kingdom', ISACTIVE = true);
		insert us;

		RecordType StdOppRecordType = [select id from RecordType where name = 'Standard Opportunity'];
		RecordType IMERecordType = [select id from RecordType where name = 'IME Standard Opportunity'];
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
		//IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry((new IM_Country__c(name = 'United States', Region__c = 'North America')));

        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
		account acc = new Account(name = 'x', BillingCountry = 'United States', IMGA_Owner__c = us.id);
		insert acc;
        
        //create a primary contact
		List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact(LastName='TestContact1',          Email='testemail@OCR.com',
                                 AccountId=acc.Id,                 MailingCity = 'London', 
                                 MailingCountry = 'United States', MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London',          MailingStreet = '745 Atlantic Ave'
                                );
        contacts.add(c1);
        insert contacts;
        
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
            cusAcc.Name = 'testSold';
            cusAcc.IM_Account__c = acc.id;
            cusAcc.Source_System__c = 'Other Europe';
            
            insert cusAcc;
        
        System.debug('AccountId' +acc.id);
         System.debug('Billing_Country__c' +testCountry.id);
         System.debug('RecordTypeId' +StdOppRecordType.id);
         System.debug('Upsell_Customer_ID__c' +cusAcc.id);
         
        //List<Opportunity> Opportunities = new List<Opportunity>();
        List<Opportunity> Opportunities = new List<Opportunity>();
         Opportunity opp1 = new Opportunity(name = 'OCR_v1', AccountId = acc.id,     Billing_Country__c = testCountry.id 
                                              ,StageName = '1 - Qualification',      RecordTypeId = StdOppRecordType.Id
                                              ,IM_Booked_Date__c = System.today(), CloseDate = System.today()
                                              ,Type = 'New Deal',                    Status__c ='Open'
                                             );
        Opportunity opp2 = opp1.clone(false, true);
        opp2.Name= 'OCR_v2';
        Opportunities.add(opp1);
        Opportunities.add(opp2);
        insert Opportunities;
       
        OpportunityContactRole ocr = new OpportunityContactRole();
		ocr.ContactId = contacts[0].Id;
        ocr.OpportunityId = opp2.Id;
        insert ocr;    
	}// closed DummyOpportunityRecordsetup 
     
    @isTest
    private static void Call_OpportunityValidator_Method() {
    Test.startTest();
        Map < Id, opportunity > mapNewOpps1; 
        Map < Id, opportunity > mapOldOpps1; 
        Opportunity oldopp1,oldopp2,newOpp1,newOpp2;
        oldopp1 =  [SELECT Id, IM_Number_of_Opty_Products__c, Status__c, StageName FROM Opportunity WHERE name = : 'OCR_v1']; 
        oldopp2 =  [SELECT Id, IM_Number_of_Opty_Products__c, Status__c, StageName FROM Opportunity WHERE name = : 'OCR_v2'];          
        newOpp1 = oldopp1.clone(false, true);
        newOpp1.StageName='2 - Solution Developed';
        newOpp1.id= oldopp1.Id;
        
        newOpp2 = oldopp2.clone(false, true);
        newOpp2.StageName='2 - Solution Developed';
        newOpp2.id= oldopp2.Id;
        
        mapOldOpps1 = new Map<ID, opportunity> ([SELECT Id, IM_Number_of_Opty_Products__c, Status__c, StageName, (SELECT Id, Role FROM OpportunityContactRoles), (SELECT Id FROM Opportunitylineitems) from opportunity where name = : 'OCR_v1' OR name = : 'OCR_v2']);
        mapNewOpps1 = new Map<ID, opportunity>();
        
        mapNewOpps1.put(oldopp1.Id,newOpp1);
        mapNewOpps1.put(oldopp2.Id,newOpp2);
        OpportunityValidator.ValidateOCR_OnOppStageChange(mapNewOpps1,mapOldOpps1);
        Test.stopTest();      
    }

} // Clasee closed