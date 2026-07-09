/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/28/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used as test utility for CDM_ProcessChatterErrorRecords class. 
   
   Case Number       : 01733573
                                  
 ********************************/
@isTest
public class Test_CDM_ProcessChatterErrorRecords {
/*
    public static testMethod void doTest() {
             
             Test.startTest();
             
                 List<CDM_INTEGRATION_END_POINTS__c> CDMproperties=CDM_INTEGRATION_END_POINTS__c.getAll().values();
                 if(CDMproperties.isempty()){
                     CDM_INTEGRATION_END_POINTS__c temp=new CDM_INTEGRATION_END_POINTS__c();
                     temp.Organization_Id__c=UserInfo.getOrganizationId();
                     temp.name='test';
                     temp.End_Point__c='Test.ironmountain.com';
                     insert temp;
                 }
                 else{
                     CDMproperties[0].Organization_Id__c=UserInfo.getOrganizationId();
                     update CDMproperties;
                 }
                 
                 
                 //create dummy data
                  IM_Country__c c = new IM_Country__c(name='United States');
                  insert c;
                  
                  Account a=new Account();
                  a.Name='CDM test';
                  a.type='Customer';
                  a.BillingCountry='United States';
                  a.IM_Sales_Segment__c='Channel';
                  a.BillingStreet='683 c';
                  a.BillingCity='Boston';
                  a.BillingState='MA';
                  a.BillingPostalCode='02120';
                  a.CDM_Last_Refresh_Date__c=system.now();
                  a.CDM_Last_Refresh_Owner__c='CDM Test Class';
                  insert a;
            
                PageReference pageRef = Page.CDM_ProcessChatterErrorRecords;
                Test.setCurrentPage(pageRef);
            
                // Add parameters to page URL
                ApexPages.currentPage().getParameters().put('accid', a.id);
                
                CDM_ProcessChatterErrorRecords controller = new CDM_ProcessChatterErrorRecords();
          
                controller.CalCDMService();
                
                List<CDM_INTEGRATION_END_POINTS__c> CDMproperties1=CDM_INTEGRATION_END_POINTS__c.getAll().values();
                CDMproperties1[0].Organization_Id__c='1234';
                update CDMproperties1;
                controller.CalCDMService();

                 
            Test.stopTest();
        
    }
*/
}