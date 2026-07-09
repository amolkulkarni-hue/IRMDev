/**
 * 	Class:				SCVGoLogger
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class will create the exception logs. Also if there is an error while 
 * 						creating the records, then an email is sent to NeuraFlash email Id.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

public with sharing class SCVGoLogger {

    public static void log(Object obj){
        if(Schema.sObjectType.SG_Log__e.isCreateable()){
            SG_Log__e log = new SG_Log__e();
            
            if(obj instanceof Exception) {
                Exception ex = (Exception)obj;
                log.Message__c = getExceptionData(ex);
                log.Type__c = ex.getTypeName();
                log.Trace__c = ex.getStackTraceString();
            } else {
                log.Message__c = String.valueOf(obj);
            }

            if(log.Type__c.length() > 255){
                log.Type__c = String.valueOf(log.Type__c).substring(0, 255);
            }

            if(log.Message__c.length() > 255){
                log.Message__c = String.valueOf(log.Message__c).substring(0, 255);
            }
            log.User_Information__c = UserInfo.getUserName() + ' - ' + UserInfo.getUserId();
            publishEvent(log);
        }
    }

    public static void createExceptionLog(String msg, String mtype){
        SG_Log__e log = new SG_Log__e();
        log.Message__c = msg;
        log.Type__c = mtype;
        log.User_Information__c = UserInfo.getUserName() + ' - ' + UserInfo.getUserId();

        if(log.Type__c.length() > 255){
            log.Type__c = String.valueOf(log.Type__c).substring(0, 255);
        }

        if(log.Message__c.length() > 255){
            log.Message__c = String.valueOf(log.Message__c).substring(0, 255);
        }
        publishEvent(log);
    }

    public static void createExceptionLogWithData(String errtype, String errmsg, String errtrace, String errdata){
        SG_Log__e log = new SG_Log__e();
        log.Type__c = errtype;
        log.Message__c = errmsg;
        log.Trace__c = errtrace;
        log.Data__c = errdata;
        log.User_Information__c = UserInfo.getUserName() + ' - ' + UserInfo.getUserId();

        if(log.Type__c.length() > 255){
            log.Type__c = String.valueOf(log.Type__c).substring(0, 255);
        }

        if(log.Message__c.length() > 255){
            log.Message__c = String.valueOf(log.Message__c).substring(0, 255);
        }
        publishEvent(log);
    }

    private static String getExceptionData(Exception ex) {
        String exceptionTrace = '====== ** SYSTEM HANDLED EXCEPTION ** ======';
        exceptionTrace += '\n';
        exceptionTrace += 'Source: ' + ex.getLineNumber();
        exceptionTrace += '\n';
        exceptionTrace += '==== ** Exception Message ** ====';
        exceptionTrace += '\n';
        exceptionTrace += ex.getMessage();
        exceptionTrace += '\n=== ** Current Log ** ===\n';
        return exceptionTrace;
    }

    public static void LogCalloutException(HttpRequest request, HttpResponse response){
        String errType, errMessage, errTrace, errData;
        errType = 'SCVGo - HttpCalloutException';
        if(response != null){
            errMessage = response.getStatusCode() + ' : ' + response.getStatus();
            errData = response.getBody();
        }
        else{
            errMessage = 'Unknown Http Response Message';
            errData = 'Unknown Http Response Body';
        }

        if(request != null){
            errTrace = 'METHOD: ' + request.getMethod() + '\n' + 'ENDPOINT: ' + request.getEndpoint();
        }
        else{
            errTrace = 'Unknown Http Request';
        }

        createExceptionLogWithData(errType, errMessage, errTrace, errData);
    }

    public static void publishEvent(SG_Log__e log){
        // Call method to publish events
        Database.SaveResult results = EventBus.publish(log);
        
        // Inspect publishing result for errors
        if(results != null){
            if (!results.isSuccess()) {
                String subject = 'SCV Go Log Information', message = 'Dear User, <br/><br/>';
                message += 'Below error occurred while logging an exception.<br/>';
                
                if(results.getErrors() != null && !results.getErrors().isEmpty()){
                    message += 'Here are additional field details:<br/>';
                    for(Database.Error err : results.getErrors()) {
                        message += '<b>Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage() + '</b><br/>';
                        message += '<ol>';
                        for(String fld : err.getFields()){
                            message += '<li>' + fld + '</li>';
                        }
                        message += '</ol><br/>';
                    }
                }

                sendMailWithMessage('salesforce-admin@neuraflash.com', subject, message);
            } 
        }
    }

    public static Boolean sendMailWithMessage(String mailId, String subject, String message){
        Boolean messageSent = false;
        try{
            if(String.isNotBlank(mailId) && String.isNotBlank(message)){
                List<Messaging.SingleEmailMessage> lstMsgs = new List<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setToAddresses(new List<String>{mailId});
                msg.setSubject(subject);
                msg.setHtmlBody(message);
                lstMsgs.add(msg);
                Messaging.sendEmail(lstMsgs);

                messageSent = true;
            }
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
            ExceptionLogger.createLog(ex.getLineNumber(), ex.getStackTraceString(), ex.getMessage(), ex.getTypeName(), 'SCVGoLogger');
        }
        return messageSent;
    }
}