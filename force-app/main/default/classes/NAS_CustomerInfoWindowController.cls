/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Lightning Component Controller to handle API Communication requests from Lightning Component
* for Customer Information Window (InfoWindow)
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class NAS_CustomerInfoWindowController {
    /**
* @name getTabContent
* @description Aura Enabled method to return InfoWindow tab Contents. Used by Custom Lightning 
* Component NASCustomerInfoWindow.
* @param {String} customerId - SKP Id of Customer Account.
* @param {String} tabId - Unique Id of the tab content being requested.
**/
    @AuraEnabled
    public static string getTabContent(String customerId, String tabId)
    {
        String resp = JSON.serialize(getTransformedInfoWindowResponse(customerId, tabId));  
        system.debug('response received=='+resp);
        return resp;
    }
    
    @AuraEnabled
    public static string getNoCustomerResponse()
    {
        String resp = JSON.serialize(getErrorResponse());  
        system.debug('response received=='+resp);
        return resp;
    }
    
    private static Map<String, Object> getErrorResponse()
    {
        Map<String, Object> returnValue = new Map<String, Object>();                
        returnValue.put('Error','Customer ID Not Found On Case');        
        return returnValue;
    }
    
    /**
* @name getTransformedInfoWindowResponse
* @description Transformation layer returns transformed tab content as applicable. 
* @param {String} customerId - SKP Id of Customer Account.
* @param {String} tabId - Unique Id of the tab content being requested.
**/
    private static Map<String, Object> getTransformedInfoWindowResponse(String customerId, String tabId)
    {
        Map<String, Object> returnValue = new Map<String, Object>();
        returnValue.put('ERROR', NAS_Constants.UNAVAILABLE_REMOTE_SYSTEM);
        if(tabId == NAS_Constants.INFOWIN_CUSTOMERINSTRUCTIONS_TABID) 
        {
            returnValue = NAS_CustomerInfoWindowController.getCustomerInstructions(customerId);
        }
        else if(tabId == NAS_Constants.INFOWIN_SERVICEPROFILE_TABID)
        {
            returnValue = NAS_CustomerInfoWindowController.getServiceProfile(customerId);
        }
        else if(tabId == NAS_Constants.INFOWIN_BILLING_TABID || 
                tabId == NAS_Constants.INFOWIN_QA_TABID || 
                tabId == NAS_Constants.INFOWIN_DEER_TABID) 
        {
            returnValue = NAS_CustomerInfoWindowController.getNotes(customerId);
        }
        return returnValue;
    }  
    
    public class CustomerInstruction 
    {
        public String CustomerName;
        public String Instruction;
    }    
    /**
* @name getCustomerInstructions
* @description Makes request to Customer Instructions SKP API endpoint and returns the result. 
* @param {String} customerId - SKP Id of Customer Account.
**/
    
    private static Map<String, Object> getCustomerInstructions(String customerId)
    {
        NAS_DataTypeFactory.SKPAPIResponse returnValue = new NAS_DataTypeFactory.SKPAPIResponse();
        
        Map<String, string> filter = new Map<String, string>();
        filter.put('customerId', customerId);
        Map<String, Object> requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(filter); 
        
        Map<String, Object> getResponseMap = NAS_RequestFactory.postSKPHttpRequest(NAS_Constants.RQTYPE_SKP_API_INFOWIN_CUST_INSTR, 
                                                                                   requestJSON);
        
        Map<String , Object > getCustomerJson = New Map<String , Object>();  
        
        if(getResponseMap.get('statusCode') == 200 && getResponseMap.get('success') == true)
        {     
            List<Object> customerInstrunction = (List<Object>)getResponseMap.get('customerInfoDetails'); 
            List<Object> customerInstList = new List<Object>();
            if(customerInstrunction.size()>0)
            {
                for(Object objVal : customerInstrunction)
                { 
                    Map<String,Object> inst = (Map<string,Object>)objVal;  
                    CustomerInstruction ci = new CustomerInstruction();
                    ci.CustomerName = String.valueOf(inst.get('categoryName'));
                    ci.Instruction = String.valueOf(inst.get('instruction'));
                    customerInstList.add(ci); 
                }
                if(customerInstList.size()>0)
                {
                    getCustomerJson.put('customerInstruction',customerInstList);
                }
                else
                {
                    getCustomerJson.put('customerInstruction','Customer Instructions not available');
                }
            }
            else
            {
                List<Object> infoInstruction = (List<Object>)getResponseMap.get('info');  
                System.debug('Info instruction>>'+infoInstruction);
                for(Object obj : infoInstruction)
                {
                    Map<String,Object> info = (Map<string,Object>)obj;                    
                    getCustomerJson.put('customerInstruction',info.get('message')); 
                }   
            }
            
        }
        else 
        {
            List<Object> errors = (List<Object>)getResponseMap.get('errors');
            if(errors != null)
            {
                for(Object ob : errors){
                    Map<String, Object> error = (Map<String, Object>) ob;
                    getCustomerJson.put('customerInstruction',error.get('message'));
                }   
            }
        } 
        
        NAS_TransformationFactory.updateSKPAPIReponse(getCustomerJson, returnValue);
        
        return getCustomerJson; 
    }
    
    public class serviceProfile 
    {
        public String Name;
        public Object serviceProfileDetails;
    } 
    
    public class serviceProfileDetails 
    {
        public String serviceProfile;
        public String businessDay;
        public String serviceParameters;
    } 
    
    /**
* @name getServiceProfile
* @description Makes request to Service Profile SKP API endpoint and returns the result. 
* @param {String} customerId - SKP Id of Customer Account.
**/
    private static Map<String, Object> getServiceProfile(String customerId)
    {
        NAS_DataTypeFactory.SKPAPIResponse returnValue = new NAS_DataTypeFactory.SKPAPIResponse();
        
        Map<String, string> filter = new Map<String, string>();
        filter.put('customerId', customerId);
        Map<String, Object> requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(filter); 
        
        Map<String, Object> getResponseMap = NAS_RequestFactory.postSKPHttpRequest(NAS_Constants.RQTYPE_SKP_API_INFOWIN_SRVC_PRFL, 
                                                                                   requestJSON);
        
        Map<String , Object > getServiceProfileJson = New Map<String , Object>();  
        List<Object> serviceProfileList = new List<Object>();
     
        if(getResponseMap.get('statusCode') == 200 && getResponseMap.get('success') == true)
        {                 
            Object HardCopy = getResponseMap.get('hardCopyProfile');
            Object ShredProfile = getResponseMap.get('shreddingProfile');
            
            if(HardCopy != null)
            {				
                Map<String, Object> hardCopyProfile = (Map<String, Object>)getResponseMap.get('hardCopyProfile');               	
                serviceProfile HCP = new serviceProfile();                
                serviceProfileDetails HCPDetail = new serviceProfileDetails();
                
                string hardCopyOverride = String.valueOf(hardCopyProfile.get('override'));                
                HCPDetail.serviceProfile = String.valueOf(hardCopyProfile.get('serviceLevelProfileId'));
                HCPDetail.businessDay = String.valueOf(hardCopyProfile.get('description'));                
                
                if(hardCopyOverride=='true')
                {
                    string serviceParametersStr = String.valueOf(hardCopyProfile.get('serviceParameters'));                     
        			serviceParametersStr = serviceParametersStr.replace('\n', '<br>');                                           
        			serviceParametersStr = serviceParametersStr.replace('                 ', '<br>&emsp;&emsp;');                             
        			serviceParametersStr = serviceParametersStr.replace('HALF DAY:', '<br>HALF DAY:');                  
        			serviceParametersStr = serviceParametersStr.replace('RUSH:', '<br>RUSH:');                          
        			serviceParametersStr = serviceParametersStr.replace('RUSH/AFT HRS:', '<br>RUSH/AFT HRS:');              
        			serviceParametersStr = serviceParametersStr.replace('<br>&emsp;&emsp;<br>', '<br>');             
        			serviceParametersStr = serviceParametersStr.replace('<br><br>', '<br>');
                    HCPDetail.serviceParameters = serviceParametersStr;
                }
                else if(hardCopyOverride=='false')
                {
                    //Next Day Details
                    string nextDay = String.valueOf(hardCopyProfile.get('nextDay'));
                    string nextDays = '';
                    Integer nextDayCutoff = Integer.valueOf(hardCopyProfile.get('nextDayCutoff'));
                    Integer nextTime = Integer.valueOf(hardCopyProfile.get('nextTime'));
                    
                    if(String.valueOf(hardCopyProfile.get('nextDays'))=='0') nextDays= 'SAME DAY';
                    else if(String.valueOf(hardCopyProfile.get('nextDays'))=='1') nextDays = 'NEXT DAY';
                    else nextDays = 'in '+String.valueOf(hardCopyProfile.get('nextDays'))+' DAYS';
                    
                    String nextDayDetails='';
                    if(nextDay=='true')
                    {
                        nextDayDetails +='NEXT DAY:  CALL BY '+ DateTime.valueOf(nextDayCutoff*1000).format('h:mm a');
                        
                        nextDayDetails +=' FOR DELIVERY '+ nextDays +' BY '+ DateTime.valueOf(nextTime*1000).format('h:mm a');
                    }                    
                    
                    //Half Day Details
                    string halfDay = String.valueOf(hardCopyProfile.get('halfDay'));
                    Integer halfDayAMCutoff = Integer.valueOf(hardCopyProfile.get('halfDayAMCutoff'));
                    String halfDayAMDays = '';
                    Integer halfDayAMTime = Integer.valueOf(hardCopyProfile.get('halfDayAMTime'));
                    
                    Integer halfDayPMCutoff = Integer.valueOf(hardCopyProfile.get('halfDayPMCutoff'));
                    String halfDayPMDays = '';
                    Integer halfDayPMTime = Integer.valueOf(hardCopyProfile.get('halfDayPMTime'));
                    
                    if(String.valueOf(hardCopyProfile.get('halfDayAMDays'))=='0') halfDayAMDays= ' THE SAME DAY';
                    else if(String.valueOf(hardCopyProfile.get('halfDayAMDays'))=='1') halfDayAMDays = ' THE NEXT DAY';
                    else halfDayAMDays = 'in '+String.valueOf(hardCopyProfile.get('halfDayAMDays'))+' DAYS';  
                    
                    if(String.valueOf(hardCopyProfile.get('halfDayPMDays'))=='0') halfDayPMDays= ' THE SAME DAY';
                    else if(String.valueOf(hardCopyProfile.get('halfDayPMDays'))=='1') halfDayPMDays = ' THE NEXT DAY';
                    else halfDayPMDays = 'in '+String.valueOf(hardCopyProfile.get('halfDayPMDays'))+' DAYS';
                    
                    String halfDayDetails='';
                    if(halfDay=='true')
                    {
                        halfDayDetails +='<br/>HALF DAY:  CALL BY '+ DateTime.valueOf(halfDayAMCutoff*1000).format('h:mm a');                       
                        halfDayDetails +=' FOR DELIVERY '+ halfDayAMDays +' BY '+ DateTime.valueOf(halfDayAMTime*1000).format('h:mm a');
                        halfDayDetails +=' CALL BY '+ DateTime.valueOf(halfDayPMCutoff*1000).format('h:mm a');                       
                        halfDayDetails +=' FOR DELIVERY '+ halfDayPMDays +' BY '+ DateTime.valueOf(halfDayPMTime*1000).format('h:mm a');
                    }  
                    
                    //Rush Details                                        
                    string rush = String.valueOf(hardCopyProfile.get('hardCopyProfile.rush'));
                    Integer rushCutoff = Integer.valueOf(hardCopyProfile.get('hardCopyProfile.rushCutoff'));
                    Integer rushTurnaround = Integer.valueOf(hardCopyProfile.get('hardCopyProfile.rushTurnaround'));                
                    
                    string rushAfterHrs = String.valueOf(hardCopyProfile.get('hardCopyProfile.rushAfterHrs'));
                    Integer rushAfterHrsCutoff = Integer.valueOf(hardCopyProfile.get('hardCopyProfile.rushAfterHrsCutoff'));
                    Integer rushAfterHrsTurnaround = Integer.valueOf(hardCopyProfile.get('hardCopyProfile.rushAfterHrsTurnaround'));
                    
                    String rushDetails='';
                    if(rush=='true')
                    {
                        rushDetails +='<br/>RUSH: CALL BY '+ DateTime.valueOf(rushCutoff*1000).format('h:mm a');                       
                        rushDetails +=' FOR DELIVERY IN '+ rushTurnaround + ' HOURS';
                    }  
                    
                    String rushAfterDetails='';
                    if(rushAfterHrs=='true')
                    {
                        rushAfterDetails +='<br/>RUSH AFTER HOURS: CALL AFTER '+ DateTime.valueOf(rushAfterHrsCutoff*1000).format('h:mm a');                       
                        rushAfterDetails +=' FOR DELIVERY IN '+ rushAfterHrsTurnaround + ' HOURS';
                    }  
                    
                    //Pickup Details
                    Integer pickupCutoff = Integer.valueOf(hardCopyProfile.get('pickupCutoff'));
                    Integer pickupTurnaround = Integer.valueOf(hardCopyProfile.get('pickupTurnaround')); 
                    
                    String pickupDetails='<br/>NORMAL PICKUP: ';
                    if(pickupCutoff>0)
                        pickupDetails +='CALL AFTER '+ DateTime.valueOf(pickupCutoff*1000).format('h:mm a');  
                    else                            
                        pickupDetails +='NO CUTOFF';
                    pickupDetails +=' FOR DELIVERY IN '+ pickupTurnaround + ' Days';
                    HCPDetail.serviceParameters = nextDayDetails + halfDayDetails + rushDetails + rushAfterDetails + pickupDetails;
                }
                
                HCP.Name = 'Hard Copy Profile';
                HCP.serviceProfileDetails = HCPDetail;
                serviceProfileList.add(HCP);                 
            }
            if(ShredProfile != null)
            {
                Map<String, Object> shreddingProfile = (Map<String, Object>)getResponseMap.get('shreddingProfile');               	
                serviceProfile SSP = new serviceProfile();                
                serviceProfileDetails SSPDetail = new serviceProfileDetails();
                
                string shreddingOverride = String.valueOf(shreddingProfile.get('override'));                
                SSPDetail.serviceProfile = String.valueOf(shreddingProfile.get('serviceLevelProfileId'));
                SSPDetail.businessDay = String.valueOf(shreddingProfile.get('description'));      
                
                if(shreddingOverride=='true')
                {
                    string serviceParametersStr = String.valueOf(shreddingProfile.get('serviceParameters'));
                    SSPDetail.serviceParameters = serviceParametersStr;
                }
                else if(shreddingOverride=='false')
                {
                    //Next Day Details
                    string nextDay = String.valueOf(shreddingProfile.get('nextDay'));
                    string nextDays = '';
                    Integer nextDayCutoff = Integer.valueOf(shreddingProfile.get('nextDayCutoff'));
                    Integer nextTime = Integer.valueOf(shreddingProfile.get('nextTime'));
                    
                    if(String.valueOf(shreddingProfile.get('nextDays'))=='0') nextDays= 'SAME DAY';
                    else if(String.valueOf(shreddingProfile.get('nextDays'))=='1') nextDays = 'NEXT DAY';
                    else nextDays = 'in '+String.valueOf(shreddingProfile.get('nextDays'))+' DAYS';
                    
                    String nextDayDetails='NORMAL: ';
                    if(nextDay=='true')
                    {
                        nextDayDetails +=' CALL BY '+ DateTime.valueOf(nextDayCutoff*1000).format('h:mm a');
                        
                        nextDayDetails +=' FOR SERVICE '+ nextDays +' BY '+ DateTime.valueOf(nextTime*1000).format('h:mm a');
                    }
                    
                    //Rush Details
                    string rush = String.valueOf(shreddingProfile.get('rush'));
                    string rushDays = '';
                    Integer rushCutoff = Integer.valueOf(shreddingProfile.get('rushCutoff'));    
                    Integer rushTurnaround = Integer.valueOf(shreddingProfile.get('rushTurnaround'));                     
                    
                    if(String.valueOf(shreddingProfile.get('rushDays'))=='0') rushDays= 'SAME DAY';
                    else if(String.valueOf(shreddingProfile.get('rushDays'))=='1') rushDays = 'NEXT DAY';
                    else rushDays = 'in '+String.valueOf(shreddingProfile.get('rushDays'))+' DAYS';
                    
                    String RushDetails='';
                    if(rush=='true')
                    {
                        nextDayDetails +='<br/>RUSH CALL AFTER '+ DateTime.valueOf(rushCutoff*1000).format('h:mm a');
                        
                        nextDayDetails +=' '+ nextDays +' BY '+ DateTime.valueOf(rushTurnaround*1000).format('h:mm a');
                    }                    
                    SSPDetail.serviceParameters = nextDayDetails + ' ' + RushDetails;
                }
                
                SSP.Name = 'Shredding Profile';
                SSP.serviceProfileDetails = SSPDetail;
                serviceProfileList.add(SSP);                 
            }
            if(serviceProfileList.size()>0)getServiceProfileJson.put('serviceProfile',serviceProfileList);            
        }
        else 
        {
            List<Object> errors = (List<Object>)getResponseMap.get('errors');
            if(errors != null)
            {
                for(Object ob : errors)
                {
                    Map<String, Object> error = (Map<String, Object>) ob;                 
               		getServiceProfileJson.put('serviceProfile',String.valueOf(error.get('message')));   
                } 
            }
        } 
        
        NAS_TransformationFactory.updateSKPAPIReponse(getServiceProfileJson, returnValue);
        
        return getServiceProfileJson; 
    }
    
    public class NotesLine 
    {
        public String Text;
    }
    
    /**
* @name getNotes
* @description Makes request to Get Notes SKP API endpoint and returns the result. 
* @param {String} customerId - SKP Id of Customer Account.
**/
    @AuraEnabled
    public static Map<String, Object> getNotes(String customerId)
    {        
        NAS_DataTypeFactory.SKPAPIResponse returnValue = new NAS_DataTypeFactory.SKPAPIResponse();
        Map<String, string> filter = new Map<String, string>();
        filter.put('customerId', customerId);
        Map<String, Object> requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(filter);
        Map<String, Object> getNotesJSON = NAS_RequestFactory.postSKPHttpRequest(NAS_Constants.RQTYPE_SKP_API_INFOWIN_CUST_NOTES, 
                                                                                 requestJSON);
        system.debug('getNotesJSON is =='+getNotesJSON);
        Map<String, Object> getNotesResp = new Map<String, Object>();   
        if(getNotesJSON.get('statusCode') == 200 && getNotesJSON.get('success') == true)
        {
            string Notes = String.valueOf(getNotesJSON.get('customerNotesDetails'));	
            List<Object> customerNotes = (List<Object>)getNotesJSON.get('customerNotesDetails');  
            if(customerNotes.size()>0)
            {
                List<Object> BillNotes = new List<Object>();
                List<Object> QANotes =  new List<Object>();   
                List<Object> DeerNotes =  new List<Object>();   
                for(Object obj : customerNotes)
                {
                    Map<String,Object> notesName = (Map<string,Object>)obj;
                    if(notesName.get('type')=='BIL')
                    {	
                        List<Object> customerNotesLines = (List<Object>)notesName.get('notesLines');   
                        for(Object obj1 : customerNotesLines)
                        {
                            Map<String,Object> notesText = (Map<string,Object>)obj1;
                            if(notesText.get('text')!='')
                            {	
                                NotesLine BN = new NotesLine();
                                BN.Text = String.valueOf(notesText.get('text'));
                                BillNotes.add(BN);
                            }
                        } 
                    }
                    else if(notesName.get('type')=='QA')
                    {	
                        List<Object> customerNotesLines = (List<Object>)notesName.get('notesLines');   
                        for(Object obj1 : customerNotesLines)
                        {
                            Map<String,Object> notesText = (Map<string,Object>)obj1;
                            if(notesText.get('text')!='')
                            {	
                                NotesLine BN = new NotesLine();
                                BN.Text = String.valueOf(notesText.get('text'));
                                QANotes.add(BN);
                            }
                        } 
                    }
                    else if(notesName.get('type')=='DER')
                    {	
                        List<Object> customerNotesLines = (List<Object>)notesName.get('notesLines');   
                        for(Object obj1 : customerNotesLines)
                        {
                            Map<String,Object> notesText = (Map<string,Object>)obj1;
                            if(notesText.get('text')!='')
                            {	
                                NotesLine BN = new NotesLine();
                                BN.Text = String.valueOf(notesText.get('text'));
                                DeerNotes.add(BN);
                            }
                        } 
                    }                  
                }        
                
                if(BillNotes.size()>0)
                    getNotesResp.put('billing',BillNotes); 
                else
                    getNotesResp.put('billing','Billing Notes Do Not Exist For This Customer.');     
                
                if(QANotes.size()>0)
                    getNotesResp.put('qa',QANotes);
                else
                    getNotesResp.put('qa','QA Notes Do Not Exist For This Customer.'); 
                
                if(DeerNotes.size()>0)
                    getNotesResp.put('deer',DeerNotes);
                else
                    getNotesResp.put('deer','DEER Notes Do Not Exist For This Customer.'); 
            }
            else
            {                	
                List<Object> infoNotes = (List<Object>)getNotesJSON.get('info');  
                for(Object obj : infoNotes)
                {
                    Map<String,Object> info = (Map<string,Object>)obj;  
                    getNotesResp.put('billing','Billing Notes Do Not Exist For This Customer.');
                    getNotesResp.put('qa','QA Notes Do Not Exist For This Customer.');  
                    getNotesResp.put('deer','DEER Notes Do Not Exist For This Customer.'); 
                }                      
            }
        }
        else   
        {
            List<Object> infoNotes = (List<Object>)getNotesJSON.get('errors');  
            for(Object obj : infoNotes)
            {
                Map<String,Object> info = (Map<string,Object>)obj;                    
                getNotesResp.put('billing',info.get('message'));        
                getNotesResp.put('qa',info.get('message'));                 
                getNotesResp.put('deer',info.get('message'));   
            }              
        }
        NAS_TransformationFactory.updateSKPAPIReponse(getNotesJSON, returnValue);
        return getNotesResp;
    }
}