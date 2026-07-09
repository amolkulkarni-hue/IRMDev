/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/24/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used as test utility for CDMWebservice class. 
   
   Dependents        : Apex Class  : CDMWebservice  
   
   Case Number       : 01733573
                                  
 ********************************/
 @isTest //(SeeAllData=true)
 public class Test_CDMWebservice{
  /*   
     static testmethod void doTest(){
          
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
                 
         CDMMessage.customers_element customers=new CDMMessage.customers_element();
         String objName='Account';
         String objValue='CDM TEST'; 
         
         //Creating a instance of the calss and calling methods 
         CDMWebservice.CdmCustomerServiceWS TestInstance=new CDMWebservice.CdmCustomerServiceWS();
         TestInstance.retrieveCdmCustomer(objName,objValue);
         TestInstance.validateCustomer(customers);
     }
 */    
 }