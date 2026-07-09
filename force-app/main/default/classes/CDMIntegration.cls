/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 9/23/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used to invoke the CDM Service. 
   
   Test Class       : Apex Class  : Test_CDMIntegration 
   
   Case Number       : 01733573
                                  
 ********************************/
 
public class CDMIntegration{
  /*  
    public static List<Account> AccList=new List<Account>();
    
    @future(callout=true)
    public static void calCDMWebservice(List<Id> accIds){
        
        CDMMessage.customers_element mesgObjectRequest=new CDMMessage.customers_element();
        CDMMessage.customers_element mesgObjectResponse=new CDMMessage.customers_element();
        CDMWebservice.CdmCustomerServiceWS CalCDMService=new CDMWebservice.CdmCustomerServiceWS();
        List<CDMCustomer.Customer> mappingObjectList=new List<CDMCustomer.Customer>();
        List<CDMCustomer.Customer> mesgObjectResponseList=new List<CDMCustomer.Customer>();
        List<Account> AccListUpdate=new List<Account>();
        
        //set the timeout
        CalCDMService.timeout_x=120000;
        
        AccList=[select id,CDM_Key__c,CDM_Id__c,Name,BillingStreet,Billing_Address_2__c,Billing_Address_3__c,Billing_Address_4__c,
                               Billing_Floor__c,BillingCity,BillingState,Billing_County__c,BillingCountry,BillingPostalCode,D_B_DUNS__c,
                               D_B_Global_Ultimate_DUNS__c,D_B_Headquarter_DUNS__c,D_B_Domestic_Ultimate_DUNS__c,IM_IMGA_Indexed__c,
                               CDM_Last_Refresh_Date__c,CDM_Last_Refresh_Owner__c,Contract_Address_1__c,Contract_Address_2__c,Contract_County__c,
                               Contract_Address_3__c,Contract_Address_4__c,Contract_Floor__c,Contract_City__c,Contract_State__c,Contract_Country__c,Contract_Postal_Code__c
                                from Account where id IN:accIds ];
       
        system.debug('+++++++++++Account list+++++++++++'+AccList);
        if(AccList!=null){
        
        //Creating the canonical model to send to CDM                       
        for(Account a:AccList){
             
              CDMCustomer.Customer mappingObject=new CDMCustomer.Customer();
             
             
                 if((a.BillingStreet != null || a.BillingStreet !='') && (a.BillingCity != null || a.BillingCity !='') && (a.BillingState!= null ||a.BillingState!='') && (a.BillingPostalCode != null || a.BillingPostalCode != '') && (a.BillingCountry!= null || a.BillingCountry!=''))
                 {
                     system.debug('++++++++++++a.BillingStreet+++++++'+a.BillingState);
                      mappingObject.cdmKey=0;
                      mappingObject.cdmId='0'; 
                      mappingObject.custName=a.Name; 
                      mappingObject.addr1=a.BillingStreet; 
                      mappingObject.city=a.BillingCity; 
                      mappingObject.state=a.BillingState; 
                      if(a.BillingCountry=='United States')
                      mappingObject.country='US';
                      if(a.BillingCountry=='Canada')
                      mappingObject.country='CAN';
                      mappingObject.county=a.Billing_County__c;//'NEW HANOVER';
                      mappingObject.postCode=a.BillingPostalCode; 
                      mappingObject.addr2=a.Billing_Address_2__c; 
                      mappingObject.addr3=a.Billing_Address_3__c; 
                      mappingObject.addr4=a.Billing_Address_4__c; 
                      if(a.Billing_Floor__c==null){
                          mappingObject.Floor='0';
                      }
                      else{
                          mappingObject.Floor=a.Billing_Floor__c;
                      } 
                      mappingObject.dunsNbr=a.D_B_DUNS__c;
                      mappingObject.sysName = 'SFDC';
                      mappingObject.gdunsNbr=a.D_B_Global_Ultimate_DUNS__c; 
                      mappingObject.dunsNbrParentHq=a.D_B_Headquarter_DUNS__c; 
                      mappingObject.sysID1=a.Id;                     
                      mappingObject.custImga=a.IM_IMGA_Indexed__c;
                      mappingObject.metric1=0;
                      mappingObject.metric2=0;
                      mappingObject.metric3=0;
                      mappingObject.metric4=0;
                      mappingObject.metric5=0;
                      mappingObject.custType='CONTRACT';
                      //mappingObject.addrType='CORRESPONDENCE';
                      mappingObject.addrType='CONTRACT CUSTOMER';
                      if(a.CDM_Last_Refresh_Date__c!=null)
                      mappingObject.lastRefreshDate=String.valueOf(a.CDM_Last_Refresh_Date__c);
                      mappingObject.lastRefreshOwner=a.CDM_Last_Refresh_Owner__c;  
                      
                      mappingObjectList.add(mappingObject);
               
           }
           
          
        }
        mesgObjectRequest.customer=mappingObjectList;
        
        try{
                system.debug('++++++++++++Send Request Object+++++++'+mesgObjectRequest); 
            //invoking the CDM Webservice
            if(!Test.isRunningTest()){
                system.debug('++++++++++++Send Request Object+++++++'+mesgObjectRequest);
                mesgObjectResponse=CalCDMService.validateCustomer(mesgObjectRequest);
            }
            else{
                mesgObjectResponse=mesgObjectRequest;
            }
        }
        catch(CalloutException e){
            String Message=e.getMessage();
            if(Message.contains(' WebService returned a SOAP Fault: Failed XSD Validation faultcode'))
                Message = 'The Account was not submitted to CDM, as some mandatory information is missing from Account.';
           else if(Message.contains('Unexpected element. Parser was expecting element'))
                Message='CDM SERVER IS DOWN PLEASE TRY AGAIN LATER';   
            CDM_Utility.feedRegularPost(Message,AccList);
            return;
        }
        
        //parsing the CDM Response
        try{
                 
                 system.debug('++++++++++++message object response++++++++'+mesgObjectResponse);
                 if(mesgObjectResponse!=null){
                       
                        mesgObjectResponseList=mesgObjectResponse.customer;
                        system.debug('+++++++Response list records+++++++'+mesgObjectResponseList);
                        
                        for(CDMCustomer.Customer temp:mesgObjectResponseList){
                             //assigning dummy values while it is running in TestMode
                             if(Test.isRunningTest()){
                                 temp.cdmKey=1234;
                                 temp.cdmId='1234';
                             }
                             system.debug('temp.sysID1+++++++'+temp.sysID1);
                             
                             for(Account a:AccList){
                                 system.debug('a.id+++++++'+a.id);                                 
                                 if(temp.sysID1==a.id && temp.cdmKey!=null && temp.cdmId!=null ){
                                     a.CDM_Key__c=String.valueOf(temp.cdmKey);
                                     a.CDM_Id__c=temp.cdmId;
                                     /* # 01733573 - CodeUpdated by Venkateswarlu Avula to Update the DUNS number on 10122013*/
                                /*     a.CDM_DUNS__c = temp.dunsNbr;
                                     a.CDM_DDuns__c = temp.ddunsNbr;
                                     a.CDM_DunsNbrParentHq__c = temp.dunsNbrParentHq;
                                     a.CDM_GDunsNbr__c = temp.gdunsNbr;  */
                                     /*Update End By Venkateswarlu Avula*/
                                  /*   a.CDM_CustName__c = temp.custName;
                                     a.CDM_CustType__c = temp.custType;
                                     a.CDM_CustImga__c = temp.custImga;
                                     a.CDM_AddrType__c = temp.addrType;
                                     a.CDM_SysName__c = temp.sysName;
                                     a.CDM_SysID1__c = temp.sysID1;
                                     a.CDM_SysID2__c = temp.sysID2;
                                     a.CDM_Metric1__c = temp.metric1;
                                     a.CDM_Metric2__c = temp.metric2;
                                     a.CDM_Metric3__c = temp.metric3;
                                     a.CDM_Metric4__c = temp.metric4;
                                     a.CDM_Metric5__c = temp.metric5;
                                     a.Contract_Address_1__c=temp.addr1;
                                     a.Contract_Address_2__c=temp.addr2;
                                     a.Contract_Address_3__c=temp.addr3;
                                     a.Contract_Address_4__c=temp.addr4;
                                     a.Contract_Floor__c=temp.Floor;
                                     a.Contract_City__c=temp.city;
                                     a.Contract_State__c=temp.state;
                                     a.Contract_County__c=temp.county; */
                                     /*if(temp.country=='US' || temp.country=='USA' || temp.country=='United States of America')
                                     a.Contract_Country__c='United States';
                                     if(temp.country=='CA' || temp.country=='CAN' || temp.country=='Canada')
                                     a.Contract_Country__c='Canada';*/
                             /*        a.Contract_Country__c = temp.country;  */
                                     //a.Contract_Postal_Code__c=temp.postCode.substringBefore('-');
                            /*         a.Contract_Postal_Code__c=temp.postCode;
                                     a.CDM_Last_Refresh_Date__c=system.now();
                                     a.CDM_Last_Refresh_Owner__c=temp.lastRefreshOwner;
                                     system.debug('a-------'+a);
                                     AccListUpdate.add(a);
                                 }
                                 break;
                             }
                             
                        }
                        system.debug('AccListUpdate-------'+AccListUpdate);
                        update AccListUpdate;
                }
                /*else{
                    CDM_Utility.feedRegularPost('NO RESPONSE FROM CDM SERVER:',AccList);
                    return;
                }*/
                 
   /*     }
       
       catch(Exception e){
            CDM_Utility.feedCSVfilePost(e.getMessage(),AccList);
        }
     }
        
    }
 */   
}