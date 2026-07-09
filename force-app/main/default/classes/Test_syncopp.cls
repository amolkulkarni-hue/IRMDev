/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/9/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : Used as test utility for SyncOpp class. 
   
   Case Number       : 00222919
                                  
 ********************************/
 @isTest(seeAllData=true)
 public class Test_syncopp{
 
     public static testMethod void doTest(){
          
            IM_Country__c country=new IM_Country__c(Name='United States',AlternativeNames__c='USA');
            insert country;
            
            //insert Account
             Account A = new Account(name='Account4TestMethod'+system.now(), BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
             insert A; 
           
             //get record type
             RecordType r=new RecordType();
             r=[select id from RecordType where name='NA Renewal'];
              //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
              //insert opportunity
              Opportunity opp = new Opportunity();
              opp.AccountId = A.Id;
              opp.Name = 'Opportunity4TestMethod';
              opp.IM_Booked_Date__c = System.today().addMonths(3);
              opp.StageName = '1 - Qualification';
              opp.CloseDate = Date.Today();
              opp.Type = 'Renewal';
              opp.recordTypeId=r.id;
              insert opp;
             
              //insert Quote 
              Quote Q=new Quote(Name='Test Quote',opportunityId=opp.id);
              Insert Q;
              //insert Quote 
              Quote Q1=new Quote(Name='Test Quote1',opportunityId=opp.id);
              Insert Q1;
              
              Map<id,id> TestMap=new Map<id,id>();
              TestMap.put(opp.id,Q.id); 
              List<id> oppIds=new List<id>(TestMap.keySet());
              //cal method to get coverage
              syncopp.doSync(TestMap);
              syncopp.doSyncOnDelete(oppIds);
              
              //assign wrong values to get coverage for email method
              delete Q;
              syncopp.doSync(TestMap);
              
          }
          
    }