/* Commenting the entire code as part of Gitlab #24448 */
@isTest
public class TestBatchIBAssignment {
    /*
    public static testMethod void testMethodForBatchAssignment(){
        test.startTest();
        Date testDate = Date.parse('2/2/2014');
        RecordType rt = [SELECT Id FROM RecordType WHERE Name = 'NCSP: SKP New Customer Setup'];
        RecordType inbrt = [SELECT Id FROM RecordType WHERE Name = 'Inbound Storage'];
        System.debug('@@  inbrt'+inbrt.Id);
        List<Account> accts = TestingUtils.createAccounts(1,true);
        Account acct = accts[0];
        System.debug('@@  acct'+acct.Id);
        Contact c1 = TestingUtils.createContact(accts[0].Id,true);
        System.debug('@@  c1'+c1.Id);
        IM_Customer_Account__c customerAcct = new IM_Customer_Account__c(IM_Account__c=accts[0].Id);
        insert customerAcct;
        System.debug('@@  customerAcct'+customerAcct.Id);
        Billing_Territory__c terr = TestingUtils.createBillingTerritory('test territory','test region',true);
        Parent_Billing_Market__c parent_market = TestingUtils.createParentBillingMarket('test parent',terr.Id,true);
        Billing_Market__c bill_market = TestingUtils.createBillingMarket('test market','test market name',parent_market.Id,true);
       
        Opportunity o = new Opportunity(Name = 'test opp ' + String.valueOf(1), 
            CloseDate=testDate.addDays(-1), StageName='0 - Pre-Qualification', 
            AccountId = acct.Id,
            Commissionable_Window__c = 60);
        insert o;

        System.debug('@@  o.CloseDate'+o.CloseDate);
        Case c = new Case(RecordTypeId = rt.Id,NCSP_Opportunity__c = o.Id,
            Customer_ID__c = customerAcct.Id, New_Division_ID__c = 'division 001',
            New_Department_ID__c = 'dept 001');
        insert c;
        System.debug('@@  c'+c.Id);

        List<Inbound_Storage__c> new_inb = new List<Inbound_Storage__c>(); 
        for(Integer i = 0; i < 2; i++){
            new_inb.add(new Inbound_Storage__c(RecordTypeId = inbrt.Id, Cube_District__c = bill_market.Id,Association_to_Opportunity_Status__c = 'Unmatched',
                Customer_Account__c = customerAcct.Id,Div_ID_del__c = 'division 001',
                Dept_ID_del__c = 'dept 001',Storage_Date__c = testDate));
        }
        insert new_inb; 
        System.debug('@@  o'+o.Id);

        List<Id> inbIdLst = new List<Id>();
        for(Inbound_Storage__c inb: new_inb){
            inbIdLst.add(inb.Id);
        }
      
        String currentCommissionYear = System.Label.Current_Commission_Year;

        Batch_Setting__c settings = new Batch_Setting__c(Name = 'Inbound Assignment',Cut_Off_Date__c=testDate.addDays(-80),Batch_Size__c = 200,Email_List__c = 'charlie.xie@bluewolfgroup.com',Query_Condition__c = ' Association_to_Opportunity_Status__c = \'Unmatched\' AND RecordType.Name = \'Inbound Storage\''); 
        insert settings;
        String query = 'SELECT ID,Customer_Account__r.Id,Opportunity__c,Association_to_Opportunity_Status__c,Dept_ID_del__c,Div_ID_del__c,Storage_Date__c FROM Inbound_Storage__c WHERE '+ settings.Query_Condition__c;
        System.debug('@@  query='+query);
        List<sObject> so = Database.query(query);
        System.debug('@@  so size='+so.size());
        
        BatchInboundStorageAssignment batch_job = new BatchInboundStorageAssignment(query);
        Id batch_id = Database.executeBatch(batch_job,Integer.valueOf(settings.Batch_Size__c)); 
        System.debug('@@  batch_id='+batch_id);
        test.stopTest();
       new_inb = [SELECT Id,Association_to_Opportunity_Status__c FROM Inbound_Storage__c WHERE Id IN:inbIdLst];
        for(Inbound_Storage__c inbs : new_inb){
            System.assertEquals('Matched - Approved',inbs.Association_to_Opportunity_Status__c);
        }
        
    }
*/
}