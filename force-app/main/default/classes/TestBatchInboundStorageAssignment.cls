/* Commenting the entire code as part of Gitlab #24448 */
@isTest
    public class TestBatchInboundStorageAssignment {
        /*
       public static testMethod void testBatchInboundStorageAssignment() {
            test.startTest();
            Date testDate = Date.parse('2/2/2014');
            RecordType rt = [SELECT Id FROM RecordType WHERE Name = 'NCSP: SKP New Customer Setup'];
            RecordType inbrt = [SELECT Id FROM RecordType WHERE Name = 'Inbound Storage'];
            System.debug('@@  inbrt'+inbrt.Id);
                    List<Account> accts = TestingUtils.createAccounts(1,true);
            Account acct = accts[0];
            Contact c = TestingUtils.createContact(accts[0].Id,true);
            IM_Customer_Account__c imca= TestingUtils.createCustomerAccount(accts[0].Id,true);
            //IM_Customer_Account__c imca = new IM_Customer_Account__c(IM_Account__c = accts[0].Id); 
            //insert imca;
            Billing_Territory__c terr = TestingUtils.createBillingTerritory('test territory','test region',true);
            Parent_Billing_Market__c parent_market = TestingUtils.createParentBillingMarket('test parent',terr.Id,true);
            Billing_Market__c bill_market = TestingUtils.createBillingMarket('test market','test market name',parent_market.Id,true);
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
            List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
            OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
            ops.Name = 'CloudSolutionsProduct';
            ops.Product_Class_Name__c = 'Data Backup and Recovery';
            ops.Product_Class_Name__c = 'Cloud Solutions';
            opprodsel.add(ops);
            
            insert opprodsel;
             ID rt1 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
            Opportunity o = new Opportunity();
            o.AccountId = accts[0].Id;
            o.StageName = '1 - Qualification';
            o.RecordTypeID=rt1;
            
           List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
            Country_Settings__c cS = new Country_Settings__c();
            cS.Name = 'Canada';
            cS.Object_Name__c = 'Account';
            countrySetting.add(cS);
            
            Country_Settings__c cS1 = new Country_Settings__c();
            cS1.Name = 'United States';
            cS1.Object_Name__c = 'Account';
            countrySetting.add(cS1);
            
            insert countrySetting;
       
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
            o.IM_Booked_Date__c = Date.today();
            o.CloseDate = Date.today();
            o.Type = 'New Deal';
            o.Name='TestInbound';
            
            insert o;
       
    
           
            
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
           
    
            System.debug('@@  o.IM_Booked_Date__c'+o.IM_Booked_Date__c);
            Case c1 = new Case(RecordTypeId = rt.Id,NCSP_Opportunity__c = o.Id,
                Customer_ID__c = imca.Id, New_Division_ID__c = 'division 001',
                New_Department_ID__c = 'dept 001');
            insert c1;
            System.debug('@@  c'+c.Id);
    
            List<Inbound_Storage__c> new_inb = new List<Inbound_Storage__c>(); 
            for(Integer i = 0; i < 2; i++){
                new_inb.add(new Inbound_Storage__c(RecordTypeId = inbrt.Id, Cube_District__c = bill_market.Id,Association_to_Opportunity_Status__c = 'Unmatched',
                    Customer_Account__c = imca.Id,Div_ID_del__c = 'division 001',
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
                System.assertNotEquals('Matched - Approved',inbs.Association_to_Opportunity_Status__c);
            }
            
        } 
    
    
        public static testMethod void TestInboundStorageAssignment(){
        
            Profile prof = [Select id from Profile where Name = 'IM_Custom Sys Admin' limit 1];
    
            User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                                  ,emailencodingkey='UTF-8'
                                  , lastname='Testing', languagelocalekey='en_US'
                                  , localesidkey='en_US', profileid = prof.id
                                  , timezonesidkey='America/Los_Angeles'
                                  , username='userwithrole@testorg.com'
                                  , Country = 'United Kingdom',
                                  CurrencyIsoCode= 'USD'); 
        
            List<Case> cases = new List<Case>(); 
            List<Opportunity> opps = new List<Opportunity>(); 
            List<Account> accts = TestingUtils.createAccounts(1,true);
            Contact c = TestingUtils.createContact(accts[0].Id,true);
            IM_Customer_Account__c imca= TestingUtils.createCustomerAccount(accts[0].Id,true);
            //IM_Customer_Account__c imca = new IM_Customer_Account__c(IM_Account__c = accts[0].Id); 
            //insert imca;
            Billing_Territory__c terr = TestingUtils.createBillingTerritory('test territory','test region',true);
            Parent_Billing_Market__c parent_market = TestingUtils.createParentBillingMarket('test parent',terr.Id,true);
            Billing_Market__c bill_market = TestingUtils.createBillingMarket('test market','test market name',parent_market.Id,true);
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
            List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
            OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
            ops.Name = 'CloudSolutionsProduct';
            ops.Product_Class_Name__c = 'Data Backup and Recovery';
            ops.Product_Class_Name__c = 'Cloud Solutions';
            opprodsel.add(ops);
            
            insert opprodsel;
             ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
            Opportunity opp1 = new Opportunity();
            opp1.AccountId = accts[0].Id;
            opp1.StageName = '1 - Qualification';
            opp1.RecordTypeID=rt;
            
           List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
            Country_Settings__c cS = new Country_Settings__c();
            cS.Name = 'Canada';
            cS.Object_Name__c = 'Account';
            countrySetting.add(cS);
            
            Country_Settings__c cS1 = new Country_Settings__c();
            cS1.Name = 'United States';
            cS1.Object_Name__c = 'Account';
            countrySetting.add(cS1);
            
            insert countrySetting;
       
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
            opp1.IM_Booked_Date__c = Date.today();
            opp1.CloseDate = Date.today();
            opp1.Type = 'New Deal';
            opp1.Name='TestInbound';
            
            insert opp1;
       
    
            Id opp1_Id = opp1.Id;
           
    
            cases.add(new Case(New_Division_ID__c = 'division 0',New_Department_ID__c = 'dept 0', NCSP_Opportunity__c = opp1_Id,ContactId = c.ID));
           // cases.add(new Case(New_Division_ID__c = 'division 1',New_Department_ID__c = 'dept 1', NCSP_Opportunity__c = opp2_Id,ContactId = c.ID));
        
            insert cases; 
            Set<Id> caseIdSet = new Set<Id>();
            for(Integer i=0;i<cases.size();i++){
                caseIdSet.add(cases[i].Id);
            }
    
            cases = [SELECT Id, New_Division_ID__c,NCSP_Opportunity__r.Type, NCSP_Opportunity__r.IM_Booked_Date__c, NCSP_Opportunity__r.Commissionable_Window_Close_Date__c,
                    NCSP_Opportunity__r.StageName,NCSP_Opportunity__r.Commissionable_Window__c,New_Department_ID__c
                    FROM Case WHERE Id IN :caseIdSet];
            System.debug('@@@  oop and cases were inserted');
    
            Inbound_Storage__c inb = new Inbound_Storage__c(Customer_Account__c = imca.Id,Storage_Date__c = Date.today(),Div_ID_del__c = 'division 0',Dept_ID_del__c = 'dept 0',Cube_District__c = bill_market.Id);
            System.runAs(u)
            {
                insert inb; 
            }
            inb = [SELECT id, Customer_Account__c,Storage_Date__c,Div_ID_del__c,Dept_ID_del__c,Cube_District__c FROM Inbound_Storage__c Where Id = :inb.Id limit 1];
            test.startTest();
            InboundStorageAssignment inb_st = new InboundStorageAssignment(cases,inb);
            InboundStorageAssignment.OppStack match = inb_st.getMatch();
         //   BatchInboundStorageAssignment binb_st = new BatchInboundStorageAssignment(cases,inb);
         //   BatchInboundStorageAssignment.OppStack match1 = binb_st.getMatch();        
            test.stopTest();
            System.assertEquals(match.opp, opp1_Id);
        }
*/
    }