@isTest(seeAllData=false)
private class SVStatusTrigger_Test {
    static testMethod void testInsertOpportunity() {
        
        //insert Account
        Account acc = TestingUtils.createAccounts(1, true)[0];
        
        //insert SV custom setting
        SVStatus__c sv = new SVStatus__c();
            sv.name = 'SVStatusPassed';
            sv.Amount__c = 24000;
            sv.Stage__c = '6 - Setup';
            sv.OpptType__c = 'Up-Sell/Lift,New Deal';
            insert sv;
        
        //insert Trigger Activation Setting
        Trigger_Activation_Settings__c TAS = new Trigger_Activation_Settings__c();
            TAS.Name = 'OpportunitySVStatus';
            TAS.Object__c ='Opportunity';
            TAS.Trigger__c = 'OpportunitySVStatus';
            TAS.Value__c = 'TRUE';
            insert TAS;
        
        //Get record type
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Opportunity; 
        Map<String,Schema.RecordTypeInfo> OppRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 
        Id rtId = OppRecordTypeInfo .get('Standard Opportunity').getRecordTypeId();
        //insert product
        Product2 pdt = TestingUtils.createProduct('TestPdt',true);
        //insert pricebook
        //Pricebook2 priceB = TestingUtils.createPriceBook('TestPriceB',true);
        Id pricebookId = Test.getStandardPricebookId();
        //insert pricebookEntry
        PriceBookEntry pricebEntr = TestingUtils.createPriceBookEntry(pdt.id, pricebookId, true);
        
        //insert Opportunity
        opportunity Opp = TestingUtils.createOpportunity('opp', acc.id, false);
            Opp.Type = 'New Deal';
            Opp.Amount = 22;
            Opp.recordtypeid = rtId;
            Opp.IM_Booked_Date__c = system.today();
            Opp.CloseDate = system.today();  
            Opp.IM_Up_Sell_Quantity__c = 2;
            Opp.IM_Up_Sell_Sold_To__c = '245';
            Opp.IM_Up_Sell_Detail__c = '268';
            Opp.IM_Up_Sell_Detail__c = 'test';
            Opp.IM_Unit_of_Measure__c = 'Backup Care';
        insert Opp;
        //insert Opportunity Line Item
        OpportunityLineItem olItem = TestingUtils.createOLI(pricebEntr.id, Opp.id, true);
        //Update Opportunity            
        Opp.StageName ='6 - Setup';
        update Opp;
    }
}