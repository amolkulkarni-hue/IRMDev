public class DRCiDocumentLink {
/* 
  Created Date: July 13,2010
  Auhtor: Nathan Shinn
  Description : Used to Wrap the DRCi Web Service to call from a button/lionk on a Contract record.
*/

/*
    Modified by: Vinutha
    Description: Changes made to support Alfresco case #06299529
    
    */
  
 //Contains a list of document links and information about the results
 public class DRCiDocResponse
 {
   public string errorMsg;
   public Long hitCount;
   public DrciDocument[] documents;
   
 }
 public static Boolean runTest = false; //set by the test client. Can make a WS callout in a test client
 public static Boolean runSearchTest = false;   
 
 //used to provide a link and a display name for document download
 public class DrciDocument
 {
   public string documentName;   
   public string documentLink;
   
 }
 
 public static DRCiDocResponse getContracts(string contractId)
 {
   
   //Cereate the wqeb swervice response object
   boolean updateDc = false;
   DRCiDocResponse contractResponse = new DRCiDocResponse();
   
   //retrieve the contract record for the contract ID passed in.
   Contract contract = [select id
                             , IM_Contract_Number__c
                             , IM_DRCi_Contract_Number__c
                             , RecordType.name
                             , Main_Contract__r.Billing_Country__c
                             , Billing_Country__c
                         from Contract 
                         where id = :contractId  ];
   
   //Look up the connection variables in DRCiWebServiceConfig__c using the country code 
   //on from the parent, Account object.
   DRCiWebServiceConfig__c dc = new DRCiWebServiceConfig__c();
   DRCiWebServiceCountry__c cc = null;//new DRCiWebServiceCountry__c();
   try{
      cc = [select DRCiWebServiceConfig__c
                   , Country__r.Iso31663Code__c
                   //, Country__r.Iso31662Code__c
                from DRCiWebServiceCountry__c
               where Country__c = :contract.Billing_Country__c
                   or Country__c = :contract.Main_Contract__r.Billing_Country__c
                   limit 1];
     
      dc = [Select d.Username__c
                 , d.Password__c
                 , d.Instance__c
                 , d.Folder__c
                 , d.Endpoint__c
                 , d.Alias__c 
                 , d.pooled_session_Cookie__c
                 , d.pooled_session_Id__c
                 , d.Locked_For_Pooled_Session_Update__c
                 , d.Id
              From DRCiWebServiceConfig__c d
             where id = :cc.DRCiWebServiceConfig__c];
   }
   catch(Exception e){
     //Prepare the response for the VF page. There is no configuration for this Contract's context
     contractResponse.hitCount=0;
      contractResponse.errorMsg = 'There is no DRCi instance configured for Country for this Contract. The Country information is used to retrieve the document';
      return contractResponse;
   }
   
    //Call WsDRCiLoginService.login retrieving the Session Key.
   WsDRCiLoginService svc = new WsDRCiLoginService();
   WsDRCiLoginService.LoginServiceSoap login = new WsDRCiLoginService.LoginServiceSoap();
   
   //Set the cookie headers because the login and search requests are separate and could
   //be on separate servers.
   String loginCookie = '';
   login.inputHttpHeaders_x = new Map<String, String>();
   login.inputHttpHeaders_x.put('Cookie', 'name=value');
   login.outputHttpHeaders_x = new Map<String, String>();
    
   
    //Prepare the Web Service Search Query
    WsDRCiSearchService searchSvc = new WsDRCiSearchService();
    WsDRCiSearchService.SearchServiceSoap docSearch = new WsDRCiSearchService.SearchServiceSoap();
    
    
    //Prepare the search parameters for retrieving the document(s).
    WsDRCiSearchService.SearchFieldsType SearchF = new WsDRCiSearchService.SearchFieldsType();
    WsDRCiSearchService.SearchFieldType[] SearchFields  = new  WsDRCiSearchService.SearchFieldType[2];
    WsDRCiSearchService.SearchFieldType searchField = new WsDRCiSearchService.SearchFieldType();
    WsDRCiSearchService.SearchFieldType searchField1 = new WsDRCiSearchService.SearchFieldType();
    WsDRCiSearchService.SearchFieldType searchField2 = new WsDRCiSearchService.SearchFieldType();
    WsDRCiSearchService.SearchFieldType searchField3 = new WsDRCiSearchService.SearchFieldType();
    
    //Set the SearchFields
    searchField.name = 'Country Code';
    searchField.Operator = 'In';
    searchField.Value1 = cc.Country__r.Iso31663Code__c;//+'",",'+ cc.Country__r.pw_cc__Iso31662Code__c+'"';
    SearchFields[0] = searchField;
    
    searchField1.name = 'Contract Number';
    searchField1.Operator = 'Equal';
    searchField1.Value1 = contract.IM_DRCi_Contract_Number__c;
    SearchFields[1] = searchField1;
     
    SearchF.SearchField = SearchFields;
    
    //Instanciate the QueryType object and set the Folder
    WsDRCiSearchService.QueryType query = new WsDRCiSearchService.QueryType();
    query.Folder = dc.Folder__c;
    //add the search fields
    query.SearchFields = SearchF;
    
    //Log In
    WsDRCiLoginService.LoginResponse_element loginRes = new WsDRCiLoginService.LoginResponse_element();
    if( ((dc.pooled_session_Cookie__c) == null
      || (dc.pooled_session_Id__c) == null)
     && !DRCiPooledSessionManager.getInstance().isBusyTransaction())
   { 
      
      system.debug('Making login request');
         //lock the session generation process
         DRCiPooledSessionManager.getInstance().setBusyTransaction();
         if(!runTest)//can't make a call-out in a test class
         {
           loginRes 
           = login.Login(dc.Instance__c
                        ,dc.Username__c
                        ,dc.Password__c
                        ,dc.Alias__c
                        ,'POOL'
                         ,dc.Endpoint__c);
         }
        //Check  for valid login
       // if(loginRes.ErrorMsg !=null && loginRes.ErrorMsg.length() == 0)
         if(String.isNotBlank(loginRes.ErrorMsg))
        {
          DRCiPooledSessionManager.getInstance().releaseBusyTransaction();
          contractResponse.hitCount=0;
          contractResponse.errorMsg = '** Error Logging ointo the DRCi System. Please contact your system Administrator to Check the Salesforce Configuration for the DRCi Username ann Password. ['+loginRes.ErrorMsg+']';
          return contractResponse;
        }
        else
        {
           system.debug('received login response'); 
          updateDc = true;
          dc.pooled_session_Id__c = loginRes.SessionToken;
          system.debug('recived token=='+loginRes.SessionToken);
          dc.pooled_session_Cookie__c = login.outputHttpHeaders_x.get('Set-Cookie');
          dc.Locked_For_Pooled_Session_Update__c = false;
        }
        
      
   }
    
    
    //Set Cookies from the Login request
    docSearch.inputHttpHeaders_x = new Map<String, String>();

    //Setting a basic authentication header
    docSearch.inputHttpHeaders_x.put('Authorization', 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==');

    //Setting a cookie header
    docSearch.inputHttpHeaders_x.put('Cookie', dc.pooled_session_Cookie__c);
     
   
    //Call the IronmountainWebservicesSearchService.SearchServiceSoap passing the session tioken, 
    //the queryType and the endpoint from DRCiWebServiceConfig__c  object.
    WsDRCiSearchService.SearchResponse_element searchRes = new WsDRCiSearchService.SearchResponse_element();
      
     
   if(runSearchTest)
    {
      //can't call-out in a test method so simulate the response
      searchRes.ErrorCode = 4;
      searchRes.ErrorMsg = 'z';
      searchRes.Folder = 'x';
      searchRes.HitCount = 0;
      
    }
    else
    {
        system.debug('Proceeding to search request');
            searchRes 
             = docSearch.Search(dc.pooled_session_Id__c, query, dc.Endpoint__c);
    }
           //Check for a bad pooled session
    if(searchRes.ErrorCode == 4)
    {
     
       if(!DRCiPooledSessionManager.getInstance().isBusyTransaction() )
       {
         
         //lock the session update process so that multiple threads don't
         //create sessions at the same time.
         DRCiPooledSessionManager.getInstance().setBusyTransaction();
         
         //get a new pooled session
         if(!runTest)
            {
             loginRes 
            = login.Login(dc.Instance__c
                        ,dc.Username__c
                        ,dc.Password__c
                        ,dc.Alias__c
                        ,'POOL'
                         ,dc.Endpoint__c);
            }
        //Check  for valid login
        //if(loginRes.ErrorMsg !=null && loginRes.ErrorMsg.length() == 0)
         if(String.isNotBlank(loginRes.ErrorMsg))
        {
          DRCiPooledSessionManager.getInstance().releaseBusyTransaction();
           contractResponse.hitCount=0;
          contractResponse.errorMsg = '** Error Logging ointo the DRCi System. Please contact your system Administrator to Check the Salesforce Configuration for the DRCi Username ann Password. ['+loginRes.ErrorMsg+']';
            return contractResponse;
        }
        else
        {
          updateDc = true;
          dc.pooled_session_Id__c = loginRes.SessionToken;
          dc.pooled_session_Cookie__c = login.outputHttpHeaders_x.get('Set-Cookie');
          dc.Locked_For_Pooled_Session_Update__c = false;
        } 
       
          //try the search again
          if(!runSearchTest)
           {   
            searchRes 
              = docSearch.Search(dc.pooled_session_Id__c, query, dc.Endpoint__c);
           }
          
          
       }
           
    }
    
    
    //Create a new Pooled session
    if(updateDc)
    {//update the DRCi Config attributes
    update dc;
    //free up the singleton so that the system can create a session again
    DRCiPooledSessionManager.getInstance().releaseBusyTransaction();
    }
        
    if(searchRes.ErrorMsg.length() == 0 )
    {
      //success so load the response values
      contractResponse.hitCount= searchRes.HitCount;
      WsDRCiSearchService.HitsType hits = searchRes.Hits; 
      
      if(contractResponse.hitCount>0)
      { 
        DrciDocument[] docs = new DrciDocument[hits.Hit.size()];
        for(Integer i = 0; i < hits.Hit.size(); i++ )
        {
          //load the array of documents
          DrciDocument doc = new DrciDocument();
          doc.documentName = hits.Hit[i].DocName;
          doc.documentLink = hits.Hit[i].DownloadURL; 
          docs[i] = doc;       
        }
        contractResponse.documents = docs;
      }
    }
    else
    {
      //There was an error. Return the error message.
      contractResponse.hitCount=0;
      contractResponse.errorMsg = ' error retrieving document for contract '+contract.IM_DRCi_Contract_Number__c+'. Please contact your system Administrator to Check the Salesforce Configuration for the DRCi. ['+searchRes.ErrorCode+'-'+searchRes.ErrorMsg+']';
    }
    
   return contractResponse;
   
 }
 
 @future (callout=true)
 public static void cleanupPooledConnection(String pooled_session_Id, String Endpoint)
 {
   
  //lock other threads from accessing the login routine
  DRCiPooledSessionManager.getInstance().setBusyTransaction();
  
  //the number of connections is configured in a label
  Integer connections = Integer.valueOf(Label.DRCiMaxConnections);
  //create the web service objects
  WsDRCiLogoutService lsvc = new WsDRCiLogoutService();
   WsDRCiLogoutService.LogoutServiceSoap logout = new WsDRCiLogoutService.LogoutServiceSoap();
  for(Integer i = 0; i < connections; i ++)
  {
     //in a pooled session, each logout call releases one connection
       try{
          WsDRCiLogoutService.LogoutResponse_element logoutRes 
                           = logout.Logout(pooled_session_Id, Endpoint);
       }
       catch(Exception e){}
    
  }
  
  //unlock the login routine so it can be called again
  DRCiPooledSessionManager.getInstance().releaseBusyTransaction();
  
  
 }
}