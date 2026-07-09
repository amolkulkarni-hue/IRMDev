@isTest(seeAllData = TRUE)
public class QuoteTriggerHandlerTest {
    
    static testMethod void handlerTestMethod(){
        
        Skip_Quote_Primary_Validation__c testCustomSetting = new Skip_Quote_Primary_Validation__c();
        Profile imCustomAdminProfile = [Select Id from Profile where Name ='IM_Custom Sys Admin'];
        
        IM_Country__c country=new IM_Country__c(Name='United States',AlternativeNames__c='USA');
         insert country;
        
        Account A = new Account(name='Account4TestMethod'+system.now(), BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
        insert A;
        
        RecordType r=new RecordType();
         r=[select id from RecordType where name='Standard Opportunity'];
        
        Opportunity opp = new Opportunity();
        opp.AccountId = A.Id;
        opp.Name = 'Test Handler Opp';
        opp.IM_Booked_Date__c = System.today().addMonths(3);
        opp.StageName = '1 - Qualification';
        opp.CloseDate = Date.today();
        opp.Type = 'New Deal';
        opp.RecordTypeId = r.Id;
        
        insert opp;
        
        Quote q1 = new Quote();
        q1.Name = 'To1';
        q1.Status = 'Accepted';
        q1.Primary__c = True;
        q1.OpportunityId = opp.Id;
        
        
        Quote q2 = new Quote();
        q2.Name = 'To2';
        q2.Status = 'Draft'; 
        q2.Primary__c = false;
        q2.OpportunityId = opp.Id;
        
        Quote q3 = new Quote();
        q3.Name = 'To3';
        q3.Status = 'Approved';
        q3.Primary__c = false;
        q3.OpportunityId = opp.Id;
        
        List<Quote> cList = new List<Quote>(); 
        cList.add(q1);
        List<Quote> cList2 = new List<Quote>();
        cList2.add(q2);
        cList2.add(q3);
        insert cList;
        insert cList2;
        
        
        test.startTest();
         
        testCustomSetting.ByPass_Validation__c = TRUE;
        testCustomSetting.SetupOwnerId = imCustomAdminProfile.Id;
        //insert testCustomSetting;
        q2.status='Accepted';
        update q2;
        QuoteTriggerHandler.QuoteValidation(cList);
        test.stopTest();
        
    }

}