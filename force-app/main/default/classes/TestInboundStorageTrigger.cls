/*
 * InboundStorageTrigger
 * Handles updating opportunities to roll up their related inbound storages
 *
 * Ver No.     Resource                           Date         Changes
 * -----------------------------------------------------------------------------
 *   1.0       Charlie Xie(Bluewolf)        01/27/2014         Created
 *
 */ 

/*
 * Used (SeeAllData=true) because IM_Customer_Account__c creation keeps crashing in SIT, UAT and Prod.
 * Error: Internal Salesforce Error: 464140916-98261 (-120363337) (-120363337)
 * Root Cause: Unable to use any safe value for the required restricted picklist field 'Source_System__c' on IM_Customer_Account__c.
*/ 
@isTest(SeeAllData=true)
public class TestInboundStorageTrigger {

    private static List<Inbound_Storage__c> createTestInboundStorageRecords(Integer count) {
        List<Inbound_Storage__c> inboundStorages = new List<Inbound_Storage__c>();
		List<Account> accts = TestingUtils.createAccounts(1, true);
        
        List<OpportunityProductSelection__c> oppprodsels = [SELECT Id FROM OpportunityProductSelection__c where Product_Class_Name__c = 'Data Backup and Recovery' and Product_Line_Name__c = 'Cloud Solutions' LIMIT 1];
        List<Country_Settings__c> settings = [SELECT Id FROM Country_Settings__c where Name = 'United States' and object_name__c = 'Account'  LIMIT 1];
        
        if (!oppprodsels.isEmpty()) {
            OpportunityProductSelection__c oppprodsel = oppprodsels[0];
        } else {
            OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
            oppprodsel.Name = 'CloudSolutionsProduct';
            oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
            oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
            insert oppprodsel; 
        }
        
        if (!settings.isEmpty()) {
            Country_Settings__c setting = settings[0];
        } else {
            Country_Settings__c setting = new Country_Settings__c();
            setting.Name = 'United States';
            setting.object_name__c = 'Account';
            insert setting;  
        }
        Opportunity opps = TestingUtils.createOpportunity('Testopp1',accts[0].Id,true);
        
        IM_Customer_Account__c imca;
        Billing_Market__c billingMarket;
        try {
            imca = [SELECT Id FROM IM_Customer_Account__c LIMIT 1];
            billingMarket = [SELECT Id FROM Billing_Market__c LIMIT 1];
        } catch (QueryException e) {
            System.debug('NO DATA FOUND: At least one IM_Customer_Account__c and Billing_Market__c is required.');
        }
        
        RecordType rt = [SELECT Id FROM RecordType WHERE Name = 'Inbound Storage' LIMIT 1];

        for (Integer i = 0; i < count; i++) {
            inboundStorages.add(new Inbound_Storage__c(
                RecordTypeId = rt.Id,
                Association_To_Opportunity_Status__c = 'Matched - Approved',
                Customer_Account__c = imca.Id,
                Storage_Date__c = Date.today(),
                Div_ID_del__c = 'division ' + i,
                Dept_ID_del__c = 'dept ' + i,
                Cube_District__c = billingMarket.Id
            ));
        }
        return inboundStorages;
    }

    @isTest static void testAfterInsert() {
        List<Inbound_Storage__c> newRecords = createTestInboundStorageRecords(2);

        Test.startTest();
        insert newRecords;
        Test.stopTest();

    }

    @isTest static void testAfterUpdate() {
        List<Inbound_Storage__c> records = createTestInboundStorageRecords(2);
        list<Opportunity> oppid = [Select id from Opportunity where name = 'Testopp1'];
        insert records;

        for (Inbound_Storage__c rec : records) {
            rec.Dept_ID_del__c += ' updated';
            rec.Opportunity__c = oppid[0].id;
            system.debug('This is from test class: ' +rec.Opportunity__c);
        }

        Test.startTest();
        update records;
        Test.stopTest();

    }

    @isTest static void testAfterDelete() {
        List<Inbound_Storage__c> records = createTestInboundStorageRecords(1);
        insert records;

        Test.startTest();
        delete records;
        Test.stopTest();

    }
    
     @isTest static void testAfterUpdate_existinginbound() {
        List<Inbound_Storage__c> records = createTestInboundStorageRecords(2);
        list<Opportunity> oppid = [Select id from Opportunity where name like 'Testopp%'];
        records[0].Opportunity__c = oppid[0].id;
        records[1].Opportunity__c = oppid[0].id;
         
        Test.startTest();
        insert records;
        for (Inbound_Storage__c rec : records) {
            rec.Dept_ID_del__c += ' updated';
        }
         records[0].Opportunity__c = null;
        update records;
        Test.stopTest();

    }

    @isTest static void testBulkOperations() {
        List<Inbound_Storage__c> bulkRecords = createTestInboundStorageRecords(200);

        Test.startTest();
        insert bulkRecords;

        for (Inbound_Storage__c rec : bulkRecords) {
            rec.Dept_ID_del__c += ' bulk update';
        }
        update bulkRecords;

        delete bulkRecords;
        Test.stopTest();
    }
}