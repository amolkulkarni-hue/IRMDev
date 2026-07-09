/**
     * Created By: Revathy Saminathan on 21-Feb-2020
     *          -- for the Sync to SMS button functionality to lightning compantability
     *          -- Case # 13188385 
     *          -- Related Visualforce Page : SITADIntegration_Lightning
     * Change History :
     *       Removed the fields (CDM_Global_Ultimate_ID__c,CDM_Global_Ultimate_Name__c) dependency as part of #16051
**/
global class SITADIntegration_Lightning {
    public static string caseObjJsonString;
    public static string customerAccJsonString;
    public static List<SKP_Sync_Error__c> SMSError = new List<SKP_Sync_Error__c>();
    public static List<SKP_Sync_Error__c> SMSCaseError;
    public static boolean calloutException=false;
    // Added by Revathy Saminathan
    public static String caseId{get; set;}
    public Case currentCaseRecored{get; set;} 
    public Id cs;
    private ApexPages.StandardController sctrl; 
    //Checking for Environment or SandBox
    public static Boolean runningInASandbox {
        get{
            if (runningInASandbox == null) {
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
    public SITADIntegration_Lightning(ApexPages.StandardController controller)
    {
        this.cs = controller.getRecord().id;
        this.sctrl = controller;
        caseId = ApexPages.currentPage().getParameters().get('id'); 
    }
    public void sysnToSMS()
    {
        currentCaseRecored = [Select Id,Recordtype.name,CaseNumber,Billing_Contact_Email__c,SMS_Customer_Sync_Date__c,SMS_Order_Sync_Date__c from Case where Id =: this.cs];
        System.debug('Current Case Record Detail>>>>>>>'+currentCaseRecored);
        if(currentCaseRecored.Billing_Contact_Email__c == null && 
          (currentCaseRecored.recordtype.name =='NCSP: DP New Customer Setup'|| currentCaseRecored.recordtype.name =='NCSP: Upsell') ){
              Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'Please add Billing contact email on Case before sending it to SMS'));

        }
        if(currentCaseRecored.SMS_Order_Sync_Date__c == Null)
        {
            try
            {
                String syncToSMS = callSMSSync(this.cs);


                Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,syncToSMS)); 
            }
            catch(exception e){
                  Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'Something went worng. Please try after some time'+e));
            }
        }
        else if(currentCaseRecored.SMS_Order_Sync_Date__c != Null){
            Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'Case is already Synced')); 
        }
    }
    
    //WebServices Method Called from "Sync To SMS" button for Create
    public static string callSMSSync(id caseId){
        String finalSecurityToken = SITADHelper.checkOAuthSecurityToken(sitadDetails.Token_endpoint__c,sitadDetails.Client_Id__c,sitadDetails.Client_Secret__c,sitadDetails.Authorization_Head__c);
        boolean caseExistError = false;
        SMSError.clear();   
         
        if(finalSecurityToken != null){
            System.debug('>>insideif'+caseId); 
            case caseDetails =[SELECT QTB_Case_Number__c,QTB_SITAD_Integration_Flag__c, SMS_Order_Sync_Date__c, Owner.Name, Owner.Phone, Owner.Email,SITAD_Disposition_Type__c, IM_Market__c, Owner.id, Market_Name__c, Service_Order_Date__c,Service_Schedule_Date__c, Service_Completion_Date__c, CaseNumber, Customer_Name__c, Account.Id,Account.Name,  Address__c,City__c,  State__c, Zip__c, Country__c, Case_Contact_Name__c, Contact.Phone, Contact.Email,Bill_To_Site_Number__c,QTB_SMS_Order_Details__c,QTB_Service_Market_ID__c,Account.QTB_Legal_Entity_Country__c FROM Case WHERE id=:caseId];
            System.debug('>>querycasedetails'+caseDetails.QTB_SITAD_Integration_Flag__c);
            if(caseDetails.QTB_SITAD_Integration_Flag__c == false){
                //Replaced caseDetails.Customer_ID__r.SITAD_Flag__c with caseDetails.QTB_SITAD_Integration_Flag__c as per #20941
                //Adding the Case - Bill To Site Number condition also to avoid the Error for SITAD.
                if(caseDetails.Bill_To_Site_Number__c == null || caseDetails.IM_Market__c == null){
                    System.debug('>>Bill_To_Site_Number__c'+caseDetails.Bill_To_Site_Number__c);
                    return 'Bill To Site Number/Disctrict cannot be blank';
                }
                else{
                    callCaseSMSSync(caseDetails, finalSecurityToken);// Commented this code #16080,20686 
                    if(calloutException){   
                        createSyncError(caseDetails.id, 'Case-Exception', 'calloutException');  
                        insertSyncError();  
                        updateCaseFields(caseDetails,false);                     
                        return 'Something went wrong. Please try after some time';
                        //return 'Synced to SITAD successfully';
                    }
                    if(SMSError.size()>0){
                        if(SMSError.size()==1){
                            insertSyncError();
                            //updateCaseFields(caseDetails,true);
                            return 'Case sync was not successful! Please check sync errors for details.';
                        }
                        else{
                            for(SKP_Sync_Error__c errr :SMSError){
                                if(errr.Error_Description__c.contains('Case already exists'))
                                caseExistError=true;                                
                            }
                            if(caseExistError == false){
                                insertSyncError();
                                updateCaseFields(caseDetails,false);
                                return 'Case sync was not successful! Please check sync errors for details.';
                            }
                        }
                    }  
                    updateCaseFields(caseDetails,true);
                }
            }
            return 'Synced to SITAD successfully';
        }
        else{
            return 'There was some problem with sync. Please try again later.';
        }
    }
    
    public static void updateCaseFields(case caseDetails, boolean caseSynced){        
        //Update Sync Date in Case     
        if(caseSynced){                                  
            //Updating the SITAD Integration Flag
            caseDetails.QTB_SITAD_Integration_Flag__c = true; //Setting caseDetails.QTB_SITAD_Integration_Flag__c to TRUE as per #20941
        	caseDetails.SMS_Order_Sync_Date__c = System.now();
        }
        update caseDetails; 
    }
    
    //WebServices Method for create Order // Commented this code #16080,20686 
    webService static void callCaseSMSSync(Case ca, string finalSecurityToken){
        Http httpCase = new Http();
        HTTPResponse caseResponse;
        HttpRequest caseRequest = new HttpRequest();
        try{            
            caseObjJsonString = JSON.serialize(new caseObjSITADJSONClass(ca));
            system.debug('## Case Obj Json String Insert Req==='+caseObjJsonString);
            string BasicAuthorization = 'Bearer'+' '+finalSecurityToken;
            /* Changes related to 20447*/
            //Start
            if(String.isBlank(ca.QTB_Case_Number__c)){
                caseRequest = SITADHelper.OAuthbuildRequest(sitadDetails.caseObj_Endoint__c,'POST',BasicAuthorization,caseObjJsonString); 
            }else{
                caseRequest = SITADHelper.OAuthbuildRequest(sitadDetails.caseObj_Endoint__c,'PUT',BasicAuthorization,caseObjJsonString); 
            }
            //Stop
            caseRequest.setTimeout(20000); 
            caseResponse  = httpCase.send(caseRequest); 
            System.debug('>>caseRequest'+caseRequest);
            string caseResponseBody = caseResponse.getBody();
            System.debug('caseResponseBody>>'+caseResponseBody);
            if(String.isNotBlank(caseResponseBody)){
                if(caseResponseBody.contains('Errors')){ 
                    caseObjSITADErrorResponse cusRes = (caseObjSITADErrorResponse)json.deserialize(caseResponseBody,caseObjSITADErrorResponse.class);
                    //insert Error message
                    createSyncError(ca.id, cusRes.Errors[0].Code, cusRes.Errors[0].Message);
                }else{
                    caseObjSITADJsonResponse cusRes = (caseObjSITADJsonResponse)Json.deserialize(caseResponseBody,caseObjSITADJsonResponse.class);
                } 
        	}
        }catch (Exception e){
            calloutException= true;
           
            System.debug('Order callout exception==Something went worng. Please try after some time'+e.getMessage()+e.getLineNumber());
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
        insert SMSError;
    }
    
    public pagereference cancel(){
        PageReference cancel = sctrl.cancel();
        return cancel;
    }   
}