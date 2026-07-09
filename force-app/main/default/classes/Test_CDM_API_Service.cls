/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/2/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used as test utility for CDM_API_Service class. 
   
   Dependents        : Apex Class  : CDM_API_Service 
   
   Case Number       : 01733573
                                  
 ********************************/ 

@isTest//(seeAllData=true)
public class Test_CDM_API_Service{
  /*  
    public static TestMethod void doTest(){
        
        IM_Country__c c = new IM_Country__c(name='United States');
        insert c;
        
        //create dummy account
        Account a=new Account(Name='test',type='Customer',BillingCountry='United States',IM_Sales_Segment__c='Channel',BillingStreet='683 c',BillingCity='Boston',BillingState='MA',BillingPostalCode='02120',IM_DUNS_NBR__c='test');
        insert a;
        
          CDM_API_Service.GoldenRecordObject TestObject=new CDM_API_Service.GoldenRecordObject();
          List<CDM_API_Service.GoldenRecordObject> mappingObjectListTest=new List<CDM_API_Service.GoldenRecordObject>();
                    
                    TestObject.cdmKey=123;
                    TestObject.cdmId='123';
                    TestObject.addr1='Test Address';
                    TestObject.addr2='Test Address';
                    TestObject.addr3='Test Address';
                    TestObject.addr4='Test Address';
                    TestObject.Floor='123';
                    TestObject.city='Boston';
                    TestObject.state='MA';
                    TestObject.county='Boston';
                    TestObject.country='United States';
                    TestObject.postCode='02171';
                    TestObject.lastRefreshDate=String.valueOf(system.now());
                    TestObject.lastRefreshOwner='Test User';
                    TestObject.sysID1=a.id;
                    mappingObjectListTest.add(TestObject);
                   
                    //cal API inbound for test coverage
                    CDM_API_Service.submitGoldenRecord(mappingObjectListTest);
    }
*/
}