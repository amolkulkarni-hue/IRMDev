/**
 * Name            : IRM_ScheduleAControllerExt_RestApi 
 * Description     : Rest API controller for PA Model XML Upload
 * Author          : Shubha Venugopal
 * Modification Log: Created:17-Dec-2024 
 * Gitlab story    : #28212 Create Rest API to Receive XML Data From Mulesoft
 **/
@RestResource(urlMapping='/PAModelUpload/*')
global class IRM_ScheduleAControllerExt_RestApi {
    //Define the response structure
     global class ApiResponse {
        public String status;
        public String scheduleName;
        public String opportunityId;
        public List<String> errors;
        public List<String> warnings;
       
        // Constructor to initiate the response
        public ApiResponse(String status,String opportunityId, String scheduleName, List<String> errors, List<String> warnings) {
            this.status = status;
            this.opportunityId = opportunityId;
            this.scheduleName=scheduleName;
            this.errors = errors != null ? errors : new List<String>();
            this.warnings = warnings != null ? warnings : new List<String>();
        }
         
         //Serialize the response in the desired format
         public String serialize() {
             String response = '{"status":' + JSON.serialize(this.status) + ',' +
                 				'"scheduleNumber":' + JSON.serialize(this.scheduleName) + ',' +
                 				'"opportunityId":'+ JSON.serialize(this.opportunityId) + ',' +
                 				'"errors":'+ JSON.serialize(this.errors) + ',' +
                 				'"warnings":'+ JSON.serialize(this.warnings) +'}';
             return response;
         }
    }
    
    @HttpPost
    global static void UploadPAModel() {
            // HTTP request and response objects          
           RestResponse res = RestContext.response;
           RestRequest req = RestContext.request;
           
           /*system.debug('Request:' + req);
           system.debug('Request Headers:' +req.headers);
           system.debug('Request URI:' +req.requestURI);
           system.debug('Request Body:' +req.requestBody);
           system.debug('Request String:' + req.requestBody.toString());*/

        
           //PA Model Schedule object
           Schedule_A__c schedule = New Schedule_A__c();
           //Error List
           List<String> errorList = new List<String>();
           //Upload Status
           string status='';
           //Schedule Name
           string scheduleName='';
           //Fetch opporutnityId from requestURI
           string opportunityId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
           system.debug(opportunityId);
      
           
           //Create an unique reference name
           string referenceName = 'Api_' + Datetime.Now().format('yyyyMMddhmmss');
           
           //Fetch XML to be uploaded
           string uploadXML=req.requestBody.toString();
        
           //system.debug(uploadXML);
            try {
           
                IRM_ScheduleAParseXML.INVOCATION_CONTEXT='Rest_Api';
                //Parse the PA Model XML and Insert data into objects
                schedule = IRM_ScheduleAParseXML.parseXML(referenceName,uploadXML,opportunityId);
                
                //If PA Model record is not created set error
                if (schedule==null) {
                    
                	IRM_ScheduleAParseXML.ERROR_LIST.add('Schedule A record is not created');
                }
                else
                {
                    //Fetch the schedule Name from the Schedule A record
                    schedule_A__c scheduleA =[select Name from schedule_A__c where Id=:schedule.Id LIMIT 1];
                    scheduleName = scheduleA.Name;
                  
                    //Add Notes to the Schedule A record
                    addNote(schedule.Id,IRM_ScheduleAParseXML.ERROR_LIST,IRM_ScheduleAParseXML.WARNING_LIST);
                }
                //system.debug('ERRORS' + IRM_ScheduleAParseXML.ERROR_LIST);
             }
            catch(Exception e) {
                IRM_ScheduleAParseXML.ERROR_LIST.add(System.Label.Error_occured_processing_PA_File);
            }
        
            //Set Status
            if (IRM_ScheduleAParseXML.ERROR_LIST.isEmpty())
            {
                status='Success';
            }
            else
            {
                status='Failure';
            }
           
            //Get the Response object
            ApiResponse response = New ApiResponse(status,
                                                   opportunityId,
                                                   scheduleName,
                                                   IRM_ScheduleAParseXML.ERROR_LIST,
                                                   IRM_ScheduleAParseXML.WARNING_LIST);
           
            //String jsonResponse = JSON.serialize(response);
            String jsonResponse = response.serialize();
            system.debug('response:' + jsonResponse);
            // Set response properties
            res.addHeader('Content-Type', 'application/json');        
            res.responseBody = Blob.valueOf(jsonResponse);
            res.statusCode = 200;
       		//return jsonResponse;
    }
    
    @future
    private static void addNote(Id recordId, List<String> errorList, List<String> warningList){
        try {
            String Notes='';
            //if PA model uploaded successfully without any errors of warnings
            if (errorList.isempty() && warningList.isempty())
            {
                Notes='PA Model Uploaded Successfully';
            }
            
            //if PA Model upload failed with errors
            if (!errorList.isEmpty())
            {
                Notes='PA Model Upload failed. <p>' + ' Errors: <p>' + String.join(errorList,',<p>');
                if (!warningList.isEmpty())
                Notes = Notes + ' Warnings: <p>' + String.join(warningList,',<p>');
            }
            
            //if PA Model uploaded successfully with warnings
            if (errorList.isEmpty() && !warningList.isEmpty())
            {
                 Notes='PA Model Uploaded Successfully with Warnings.<p>';
                 Notes = Notes + ' Warnings: <p>' + String.join(warningList,',<p>');
            }
           
            ContentNote newNote = new ContentNote();
            newNote.Title = 'PA Model Upload Status';
            newNote.Content = Blob.valueOf(Notes);
            insert newNote;
            Id noteId = newNote.Id;
            // Create a ContentDocumentLink to relate the note to a record
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = recordId;
            link.ContentDocumentId = noteId;
            link.ShareType = 'V'; // Viewer access
            link.Visibility = 'AllUsers'; // Visible to all users 
            insert link;
            system.debug('Notes:' + Notes);
            system.debug('noteid:'+ noteId);
            system.debug('linkid:' +  link.Id);
        }
        catch (Exception ex)
        {
            System.debug(ex.getmessage());
        }
        
    }
}