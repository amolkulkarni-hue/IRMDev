/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/28/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used to process the account records that are need to send to CDM server from chatter group. 
   
   Dependents        : VF Page: CDM_ProcessChatterErrorRecords
   
   Test Class        : Apex Class  : Test_CDM_ProcessChatterErrorRecords 
   
   Case Number       : 01733573
                                  
 ********************************/

Public class CDM_ProcessChatterErrorRecords{
 /*   
    public Id AccontId;
    public boolean isError{get;set;}
    public CDM_ProcessChatterErrorRecords(){
        AccontId=ApexPages.currentPage().getParameters().get('accId');
    }
    public void CalCDMService(){
        List<Id> Accids=new List<id>();
        Accids.add(AccontId);
        
        //cal the CDM service
        List<CDM_INTEGRATION_END_POINTS__c> CDMproperties=CDM_INTEGRATION_END_POINTS__c.getAll().values();
       
        if(!CDMproperties.isEmpty() &&  CDMproperties[0].Organization_Id__c.length()>=15 && UserInfo.getOrganizationId().subString(0,15) == CDMproperties[0].Organization_Id__c.subString(0,15)){
            CDMIntegration.calCDMWebservice(Accids);
        }
        else{
             ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'There is a problem with The CDM Endpoints Please contact Admin.');
              ApexPages.addMessage(myMsg);
              isError=true; 
        }
    }
*/
}