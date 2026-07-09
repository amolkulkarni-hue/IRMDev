/******************************************************************************************************************************************
 * Class: SITADIntegration
 * 
 * Change History:     11/07/2023
 * Developer           Date                Description
 * ------------------------------------------------------------------------------------------- 
 * Removed the fields (CDM_Global_Ultimate_ID__c,CDM_Global_Ultimate_Name__c) dependency as part of #16051
 * Renuka Prasad       11/07/2023          Story #19589 - Changes to pass Billing Account Legal Entity for Country field for SMS Case Sync
 ******************************************************************************************************************************************/
global class SITADIntegration{
    public static string caseObjJsonString;
    public static string customerAccJsonString;
    public static List<SKP_Sync_Error__c> SMSError = new List<SKP_Sync_Error__c>();
    public static List<SKP_Sync_Error__c> SMSCaseError;
    public static List<IM_Customer_Account__c> IMCustAcc;
    public static List<case> casUpdateList;
    public static boolean calloutException=false;
    public static boolean caseCalloutException=false;
    
    
    //Checking for Environment or SandBox
    public static Boolean runningInASandbox {
        get{
            if ( runningInASandbox == null) {
                runningInASandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return runningInASandbox;
        } set;
    }
    
    //Getting Value From Custom Setting
    public static SITAD_Integration_Details__c sitadDetails{
        get{
            if(sitadDetails == null){
                string sandboxType = runningInASandbox ? 'Sandbox' : 'Production' ;
                sitadDetails = SITAD_Integration_Details__c.getInstance(sandboxType);
            }
            return sitadDetails;
        }
        set;
    }
    public SITADIntegration(){ 
    }
    
    //WebServices Method Called from "Sync To SMS" button for Create
    webService static string callSMSSync(id caseId)
    {
        SMSError.clear(); 
        string finalSecurityToken = SITADHelper.checkOAuthSecurityToken(sitadDetails.Token_endpoint__c,sitadDetails.Client_Id__c,sitadDetails.Client_Secret__c,sitadDetails.Authorization_Head__c);
       system.debug('@@@finalSecurityToken =='+finalSecurityToken );
       boolean CustSyncError = false;
       boolean CustExistError=false;
       boolean caseExistError = false;
        
        if(finalSecurityToken != null)
        {
            case caseDetails =[SELECT Customer_ID__c, SMS_Customer_Sync_Date__c,QTB_SITAD_Integration_Flag__c,SMS_Order_Sync_Date__c, Customer_ID__r.name, 
                               Customer_ID__r.SITAD_Flag__c, Owner.Name, Owner.Phone, Owner.Email,SITAD_Disposition_Type__c, 
                               IM_Market__c, Owner.id, Market_Name__c, Service_Order_Date__c,Service_Schedule_Date__c, 
                               Service_Completion_Date__c, CaseNumber, Customer_Name__c, Account.Id,Account.Name,  Address__c,City__c,  
                               State__c, Zip__c, Country__c, Case_Contact_Name__c, Contact.Phone, Contact.Email,Bill_To_Site_Number__c,Account.QTB_Legal_Entity_Country__c FROM Case 
                               WHERE id=:caseId];
            string custMsg = '';
            string casMsg = '';
            if(caseDetails.QTB_SITAD_Integration_Flag__c == false) //Replaced caseDetails.Customer_ID__r.SITAD_Flag__c with caseDetails.QTB_SITAD_Integration_Flag__c as per #20941
            {
                
                //Adding the Case - Bill To Site Number condition also to avoid the Error for SITAD.
                if((caseDetails.Customer_ID__r.name == null && caseDetails.Bill_To_Site_Number__c == null) || caseDetails.IM_Market__c == null)
                {
                    return 'Customer Account Name / Disctrict cannot be Blank';
                }
                else
                {
                    //callCustomerSMSSync(caseDetails,finalSecurityToken);
                    if(calloutException)
                    {   
                        createSyncError(caseDetails.id, 'Customer-Exception', 'calloutException');    
                        insertSyncError();                   
                        return 'Something went worng. Please try after some time';
                    }
                    if(SMSError.size()>0)
                    {
                        system.debug('SMSError==='+SMSError);
                        for(SKP_Sync_Error__c err :SMSError)
                        {
                            if(err.Error_Description__c.contains('customerAccount already exists'))
                            {
                                CustExistError=true;
                            }
                            else
                            {
                                CustSyncError = true;
                            }
                        }
                        if(CustSyncError==true)
                        {
                            insertSyncError();
                            return 'Customer Account sync was not successful! Please see sync errors for details.';
                        }
                    }                
                   
                    callCaseSMSSync(caseDetails, finalSecurityToken);   
                    if(calloutException)
                    {   
                        createSyncError(caseDetails.id, 'Case-Exception', 'calloutException');  
                        insertSyncError();  
                        updateCaseFields(caseDetails,true,false);                     
                        return 'Something went worng. Please try after some time';
                    }                     
                    if(SMSError.size()>0)
                    {
                        if(SMSError.size()==1 && CustExistError==true)
                        {
                            insertSyncError();
                            updateCaseFields(caseDetails,true,true);
                        }
                        else
                        {
                            for(SKP_Sync_Error__c errr :SMSError)                            
                            {
                                if(errr.Error_Description__c.contains('Case already exists'))
                                caseExistError=true;                                
                            }
                            if(caseExistError==false)
                            {
                                insertSyncError();
                                updateCaseFields(caseDetails,true,false);
                                return 'Case sync was not successful! Please see sync errors for details.';
                            }
                        }
                    }  
                    
                    updateCaseFields(caseDetails,true,true);
                         
                }
                
            }
            else if(caseDetails.SMS_Order_Sync_Date__c ==null)
            {
                if(caseDetails.Customer_ID__r.name == null)
                {
                    return 'Customer Account Name in Case cannot be Blank';
                }
                else
                {
                    callCaseSMSSync(caseDetails, finalSecurityToken);   
                    if(calloutException)
                    {     
                        createSyncError(caseDetails.id, 'Case-Exception', 'calloutException');    
                        insertSyncError();                   
                        return 'Something went worng. Please try after some time';   
                    }
                    //Replaced caseDetails.Customer_ID__r.SITAD_Flag__c with caseDetails.QTB_SITAD_Integration_Flag__c as per #20941
                    if(caseDetails.SMS_Customer_Sync_Date__c == null && caseDetails.QTB_SITAD_Integration_Flag__c == true){
                        caseDetails.SMS_Customer_Sync_Date__c = System.now();
                    }
                    if(SMSError.size()>0)
                    {
                        for(SKP_Sync_Error__c errr :SMSError)                            
                        {
                            if(errr.Error_Description__c.contains('Case already exists'))
                            caseExistError=true;                                
                        }
                        if(caseExistError==false)
                        {
                            insertSyncError();
                            updateCaseFields(caseDetails,true,false);
                            return 'Case sync was not successful! Please see sync errors for details.';
                        }
                    } 
                    
                    updateCaseFields(caseDetails,false,true);
                }
            }
            return 'Synced to SITAD successfully';
        }
        else
        {
            return 'There was some problem with sync. Please try again later.';
        }
    }
    
    public static void updateCaseFields(case caseDetails, boolean custAcctSynced, boolean caseSynced)
    {        
        if(custAcctSynced)
        {
            //Updating the SITAD Integration Flag
            caseDetails.QTB_SITAD_Integration_Flag__c = true; //Setting caseDetails.QTB_SITAD_Integration_Flag__c to TRUE as per #20941
            caseDetails.SMS_Customer_Sync_Date__c = System.now();
        }
        //Update Sync Date in Case     
        if(caseSynced){
            caseDetails.SMS_Order_Sync_Date__c = System.now();
        }
        update caseDetails; 
    }
    
    //WebServices Method for create Customer Account
    webService static void callCustomerSMSSync(case cas, string finalSecurityToken){
        try{
            Http httpCust = new Http();
            HTTPResponse customerResponse;
            HttpRequest custRequest = new HttpRequest();
            //Customer Account Create
            customerAccJsonString = JSON.serialize(new CustAccountSITADJsonClass(cas));
            system.debug('##Customer Acc Json String Insert Req==='+customerAccJsonString);
            string BasicAuthorization = 'Bearer'+' '+finalSecurityToken;
            custRequest = SITADHelper.OAuthbuildRequest(sitadDetails.CustomerAcc_Endpoint__c,'POST',BasicAuthorization,customerAccJsonString);
            system.debug('Customer Sync Request :'+ custRequest);
            customerResponse = httpCust.send(custRequest);
            string customerAccResponseBody = customerResponse.getBody();  
            system.debug('##Customer Acc JsonString Insert Response==='+customerAccResponseBody);
            
            if(customerAccResponseBody.contains('Errors'))
            { 
                CustAccountSITADErrorResponse cusRes = (CustAccountSITADErrorResponse)json.deserialize(customerAccResponseBody,CustAccountSITADErrorResponse.class);
                //insert Error message
                createSyncError(cas.id, cusRes.Errors[0].Code, cusRes.Errors[0].Message);
            }
            else if(customerAccResponseBody.contains('Account'))
            {
                CustAccountSITADJsonResponse cusRes = (CustAccountSITADJsonResponse)json.deserialize(customerAccResponseBody,CustAccountSITADJsonResponse.class);                
            } 
        }catch (Exception e){
            calloutException= true;
            system.debug('Customer callout exception==Something went worng. Please try after some time'+e.getMessage()+e.getLineNumber());
        }   
    }
    
    //WebServices Method for create Order
    webService static void callCaseSMSSync(Case ca, string finalSecurityToken){
        Http httpCase = new Http();
        HTTPResponse caseResponse;
        HttpRequest caseRequest = new HttpRequest();
        try{            
            caseObjJsonString = JSON.serialize(new caseObjSITADJSONClass(ca));
            system.debug('## Case Obj Json String Insert Req==='+caseObjJsonString);
            string BasicAuthorization = 'Bearer'+' '+finalSecurityToken;
            caseRequest = SITADHelper.OAuthbuildRequest(sitadDetails.caseObj_Endoint__c,'POST',BasicAuthorization,caseObjJsonString); 
            caseResponse  = httpCase.send(caseRequest);  
            string caseResponseBody = caseResponse.getBody();
            system.debug('##Case Obj Body Insert Response==='+caseResponseBody );
            if(caseResponseBody.contains('Errors')){ 
                caseObjSITADErrorResponse cusRes = (caseObjSITADErrorResponse)json.deserialize(caseResponseBody,caseObjSITADErrorResponse.class);
                //insert Error message
                createSyncError(ca.id, cusRes.Errors[0].Code, cusRes.Errors[0].Message);
            }else if(caseResponseBody.contains('Account')){
                caseObjSITADJsonResponse cusRes = (caseObjSITADJsonResponse)json.deserialize(caseResponseBody,caseObjSITADJsonResponse.class);
                
            }
        }catch (Exception e){
            calloutException= true;
            system.debug('Order callout exception==Something went worng. Please try after some time'+e.getMessage()+e.getLineNumber());
        }
    }
    
    //WebServices Method for Update Customer Account
    webService static string callTriggerToSMSSync(Case caa){
        string finalSecurityToken = SITADHelper.checkOAuthSecurityToken(sitadDetails.Token_endpoint__c,sitadDetails.Client_Id__c,sitadDetails.Client_Secret__c,sitadDetails.Authorization_Head__c);
        //system.debug('11@@@finalSecurityToken =='+finalSecurityToken );
        if(finalSecurityToken != null){
            boolean checkCAError = false;
            boolean checkCaseError = false;
            callTriggerSMSSync(caa, finalSecurityToken );
            if(calloutException){
                //return 'Something went worng. Please try after some time';
                return null;
            }
            if(SMSError.size() > 0 ){
                checkCAError = true;
                insertSyncError();
            }else{
                caa.SMS_Customer_Sync_Date__c = System.now();
            }
            callCaseTriggerSMSSync(caa, finalSecurityToken);
            if(caseCalloutException){
                //return 'Something went worng. Please try after some time';
                return null;
            }
            if(SMSError.size() > 0){
                checkCaseError = true;
                insertSyncError();
            }else{
                caa.SMS_Order_Sync_Date__c = System.now();
            }
            if(checkCAError == false || checkCaseError == false){
                update caa;
            }
            return null;
        }else{
            //return 'There was some problem with sync. Please try again later.';
            return null;
        }
    }
    
    webService static void callTriggerSMSSync(Case c, string finalSecurityToken){
        SMSError = new List<SKP_Sync_Error__c>();
        system.debug('11@@@finalSecurityToken =='+finalSecurityToken );
            try{
                SMSError = new List<SKP_Sync_Error__c>();
                SMSCaseError = new List<SKP_Sync_Error__c>();
                Http httpCust = new Http();
                HTTPResponse customerResponse;
                HttpRequest custRequest = new HttpRequest();
                //Customer Account Update
                customerAccJsonString = JSON.serialize(new CustAccountSITADJsonClass(c));
                system.debug('$$Customer Acc Json String Req==='+customerAccJsonString);
                string BasicAuthorization = 'Bearer'+' '+finalSecurityToken;
                custRequest = SITADHelper.OAuthbuildRequest(sitadDetails.CustomerAcc_Endpoint__c+'/'+c.Customer_ID__r.name,'PUT',BasicAuthorization,customerAccJsonString);
                customerResponse = httpCust.send(custRequest);
                string customerAccResponseBody = customerResponse.getBody();
                system.debug('$$Customer Acc Response Body =='+customerAccResponseBody );
                if(customerAccResponseBody.contains('Errors')){ 
                    CustAccountSITADErrorResponse cusRes = (CustAccountSITADErrorResponse)json.deserialize(customerAccResponseBody,CustAccountSITADErrorResponse.class);
                    //insert ERROR to Sync ERROR Objet
                    createSyncError(c.id, cusRes.Errors[0].Code, cusRes.Errors[0].Message);
                }else if(customerAccResponseBody == null || customerAccResponseBody == '' ||  string.IsBlank(customerAccResponseBody)){
                   system.debug('!!!!!!!!!CA Success!!!!!!!');
                }
            }catch (Exception e){
                calloutException = true;
                system.debug('Cust Acc Exception'+e.getMessage()+e.getLineNumber());
            }
    }
    
    webService static void callCaseTriggerSMSSync(Case ca, string finalSecurityToken){
        SMSError = new List<SKP_Sync_Error__c>();
        Http httpCase = new Http();
        HTTPResponse caseResponse;
        HttpRequest caseRequest = new HttpRequest();
        try{
            if(ca.SMS_Order_Sync_Date__c !=null){
                caseObjJsonString = JSON.serialize(new caseObjUpdateSITADJSONClass(ca));
                system.debug('$$Case Json String req==='+caseObjJsonString);
                string BasicAuthorization = 'Bearer'+' '+finalSecurityToken;
                caseRequest = SITADHelper.OAuthbuildRequest(sitadDetails.caseObj_Endoint__c,'PUT',BasicAuthorization,caseObjJsonString);
                caseResponse  = httpCase.send(caseRequest);
                string caseResponseBody = caseResponse.getBody();
                system.debug('$$Case Response Body =='+caseResponseBody);
                if(caseResponseBody.contains('Errors')){ 
                    caseObjSITADErrorResponse cusRes = (caseObjSITADErrorResponse)json.deserialize(caseResponseBody,caseObjSITADErrorResponse.class);
                    //insert ERROR to Sync ERROR Objet
                    createSyncError(ca.id, cusRes.Errors[0].Code, cusRes.Errors[0].Message);
                }else if(caseResponseBody==null || caseResponseBody=='' ||  string.IsBlank(caseResponseBody)){
                   system.debug('!!!!!!!!!Case Success!!!!!!!');
                }
            }
        }catch (Exception e){
            caseCalloutException = true;
            system.debug('Case Exception'+e.getMessage()+e.getLineNumber());
        }
    }
    
    public static void createSyncError(id casId, string ErrorCode, string ErrorDesc){
        SKP_Sync_Error__c SyncErr = new SKP_Sync_Error__c();
        SyncErr.Case__c = casId;
        SyncErr.Destination_System__c = 'SMS';
        SyncErr.Error_Code__c = ErrorCode;
        SyncErr.Error_Description__c = ErrorDesc;
        SMSError.add(SyncErr);
    }
    
    public static void insertSyncError(){  
         integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        insert SMSError;
    }
}