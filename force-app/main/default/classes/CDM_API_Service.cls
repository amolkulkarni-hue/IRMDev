/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/2/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used as API service for CDM to submit golden record asynchronously. 
   
   Dependents        :  Apex Class: CDM_Utility
   
   Test Class        : Test_CDM_API_Service
      
   Case Number       : 01733573
                                  
 ********************************/ 

global class CDM_API_Service{
  /*  
     public static List<Account> AccListUpdate=new List<Account>();
     
    global class GoldenRecordObject{
        webservice String cdmId;
        webservice String custName;
        webservice String addrType;
        webservice String addr1;
        webservice String addr2;
        webservice String addr3;
        webservice String addr4;
        webservice String floor;
        webservice String city;
        webservice String state;
        webservice String county;
        webservice String country;
        webservice String postCode;
        webservice String dunsNbr;
        webservice String ddunsNbr;
        webservice String gdunsNbr;
        webservice String dunsNbrParentHq;
        webservice String custType;
        webservice String sysName;
        webservice String sysID1;
        webservice String sysID2;
        webservice String custImga;
        webservice Integer metric1;
        webservice Integer metric2;
        webservice Integer metric3;
        webservice Integer metric4;
        webservice Integer metric5;
        webservice String lastRefreshDate;
        webservice String lastRefreshOwner;
        webservice Long cdmKey;
    }
    
    Webservice static String submitGoldenRecord(List<GoldenRecordObject>  mesgObjectRequest){
           Try{
             
             system.debug('+++++++++++++request recieved was++++++++'+mesgObjectRequest);
             for(GoldenRecordObject temp:mesgObjectRequest){
                     Account a=new Account(
                     Id=temp.sysID1,
                     CDM_Key__c=String.valueOf(temp.cdmKey),
                     CDM_Id__c=temp.cdmId,
                     /* # 01733573 - CodeUpdated by Venkateswarlu Avula to Update the DUNS number on 10122013*/
                /*     CDM_DUNS__c = temp.dunsNbr,
                     CDM_DDuns__c = temp.ddunsNbr,
                     CDM_DunsNbrParentHq__c = temp.dunsNbrParentHq,
                     CDM_GDunsNbr__c = temp.gdunsNbr,
                     /*Update End By Venkateswarlu Avula*/
                     //CDM_CustId__c = temp.,
                 /*    CDM_CustName__c = temp.custName,
                     CDM_CustType__c = temp.custType,
                     CDM_CustImga__c = temp.custImga,
                     CDM_AddrType__c = temp.addrType,
                     //CDM_EntId__c = temp.,
                     CDM_SysName__c = temp.sysName,
                     CDM_SysID1__c = temp.sysID1,
                     CDM_SysID2__c = temp.sysID2,
                     CDM_Metric1__c = temp.metric1,
                     CDM_Metric2__c = temp.metric2,
                     CDM_Metric3__c = temp.metric3,
                     CDM_Metric4__c = temp.metric4,
                     CDM_Metric5__c = temp.metric5,
                     Contract_Address_1__c=temp.addr1,
                     Contract_Address_2__c=temp.addr2,
                     Contract_Address_3__c=temp.addr3,
                     Contract_Address_4__c=temp.addr4,
                     Contract_Floor__c=temp.Floor,
                     Contract_City__c=temp.city,
                     Contract_State__c=temp.state,
                     Contract_County__c=temp.county,
                     Contract_Postal_Code__c=temp.postCode,
                     CDM_Last_Refresh_Date__c=Datetime.Now(),
                     CDM_Last_Refresh_Owner__c=temp.lastRefreshOwner);
                     /*if(temp.country=='US' || temp.country=='USA' || temp.country=='United States of America')
                         a.Contract_Country__c='United States';
                     if(temp.country=='CA' || temp.country=='CAN' || temp.country=='Canada')
                         a.Contract_Country__c='Canada';*/
            /*            a.Contract_Country__c = temp.country;
                    AccListUpdate.add(a);
                 }
                 
                   system.debug('++++++++++Account list before update+++++++'+AccListUpdate);
                   update AccListUpdate;
                   return 'update succeeded';
                   
               }
               Catch(dmlException ex){
                   CDM_Utility.feedCSVfilePost(ex.getDmlMessage(0),AccListUpdate);
                   String error= 'un-retrievable error - '+ex.getDmlMessage(0);
                   return error;
               }
               catch(Exception e){
                   string error='retrievable error - '+e.getMessage();
                   return error;
               }

    } 
*/
}