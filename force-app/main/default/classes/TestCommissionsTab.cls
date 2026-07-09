@isTest
public class TestCommissionsTab {

    public static testMethod void TestCommissionsTab() {
    
        Profile prof = [Select id from Profile where Name = 'IM_Custom Sys Admin' limit 1];

        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = prof.id
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom',
                              CurrencyIsoCode= 'USD'); 
    
        RecordType rt = [SELECT Id FROM RecordType WHERE Name = 'Inbound Storage' Limit 1];
        List<Account> accts = TestingUtils.createAccounts(1,true);

        IM_Customer_Account__c imca = new IM_Customer_Account__c(IM_Account__c = accts[0].Id); 
        insert imca; 
        Billing_Territory__c terr = TestingUtils.createBillingTerritory('test territory','test region',true);
        Parent_Billing_Market__c parent_market = TestingUtils.createParentBillingMarket('test parent',terr.Id,true);
        Billing_Market__c bill_market = TestingUtils.createBillingMarket('test market','test market name',parent_market.Id,true);
        Opportunity o = new Opportunity(Name = 'test opp ',CloseDate=Date.today(), StageName='0 - Pre-Qualification',Commissionable_Window__c = 60,Lead_Source_Most_Recent__c = 'Email');
        insert o;
        List<Inbound_Storage__c> new_inbs = new List<Inbound_Storage__c>();
        Inbound_Storage__c inb = new Inbound_Storage__c(Association_To_Opportunity_Status__c = 'Matched - Approved',Customer_Account__c = imca.Id,Storage_Date__c = Date.today(),Div_ID_del__c = 'division 0',Dept_ID_del__c = 'dept 0',Cube_District__c = bill_market.Id,Opportunity__c = o.Id);
        new_inbs.add(inb);

        Inbound_Storage__c inb2 = new Inbound_Storage__c(RecordType = rt,Association_To_Opportunity_Status__c = 'Unmatched',Customer_Account__c = imca.Id,Storage_Date__c = Date.today(),Div_ID_del__c = 'division 0',Dept_ID_del__c = 'dept 0',Cube_District__c = bill_market.Id);
        new_inbs.add(inb2);

        System.Runas(u)
        {
            insert new_inbs;

            test.startTest();
    
            List<OpportunityContExt.InboundStorageWrapper> init_res = OpportunityContExt.getInboundStorage(o.Id);
            system.assertEquals(1,init_res.size());
    
            List<OpportunityContExt.InboundStorageWrapper> search_res = OpportunityContExt.searchInboundStorage('','','dept 0','',false);
            system.assertEquals(1,search_res.size());
    
            List<String> inb_ids = new List<Id>{search_res[0].id};
            List<OpportunityContExt.InboundStorageWrapper> new_res = OpportunityContExt.addInboundStorage(inb_ids,o.Id,'Matched - Approved');
    
            List<OpportunityContExt.InboundStorageWrapper> inb_res = OpportunityContExt.getInboundStorage(o.Id);
            system.assertEquals(2,inb_res.size());
            
            test.stopTest();
        }
    }
}