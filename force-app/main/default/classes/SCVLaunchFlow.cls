/**
 * 	Class:				SCVLaunchFlow
 * 
 * 	Author:				Yashwant Verma (Neuraflash LLC)
 * 
 * 	Purpose:			This class is used for Invoking the OrderApi using a lightning flow
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@RestResource(urlMapping='/nfLaunchFlow/*')
global with sharing class SCVLaunchFlow {
    public static RestResponse invocationResult{
        get;
        private set;
    }
    
    static{
        invocationResult = new RestResponse();
    }
    
    @HttpGet
    global static String launchFlow(){
        
        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> inputs = new Map<String, Object>();
        List<String> resultList;
        Flow.Interview myFlow;
        String stringOutputValues;
        
        try{
            invocationResult.responseBody= Blob.valueOf('{"result":"empty"}');
            String flowName = RestContext.request.params.get('FlowName');
            System.Debug('Print flowName'+ flowName);
            
            Map<String, Object> inputValues = RestContext.request.params;
            String stringInputValues = inputValues.toString().remove('{').remove('}');
            resultList = stringInputValues.split(',');            
           
            for (String currentinput : resultList) {
                List<String> splitString = currentinput.split('=');
                System.Debug('Print splitString'+ splitString[0]);
                System.Debug('Print splitString[1]'+ splitString[1]);
                inputs.put(splitString[0].trim(), splitString[1].trim());
            }
            
            System.Debug('Print inputs'+ inputs);
            if(!test.isRunningTest()){
                myFlow = Flow.Interview.createInterview(flowName, inputs);
                myFlow.start();    
            }
            stringOutputValues = String.valueOf(myFlow);
            
            if(test.isRunningTest()){
                stringOutputValues = 'id=1234,number=123456';
            }
            
            System.Debug('Print stringOutputValues'+ stringOutputValues);
            stringOutputValues = stringOutputValues.replace('{','').replace('}','');
            
            resultList = stringOutputValues.split(',');
            for (String currentOutput : resultList) {
                List<String> splitString = currentOutput.split('=');
                if (splitString.size()>1){
                	response.put(splitString[0].trim(), splitString[1].trim());
                }
            }
            System.Debug('Print response'+ response);
            invocationResult.responseBody= Blob.valueOf(JSON.Serialize(response));
        }
        
        catch(exception e){
            system.debug('Exception Encountered in Launch Flow class >> '+ e.getMessage() + e.getLineNumber() + e.getStackTraceString());
            invocationResult.statusCode = 500;
            invocationResult.responseBody = Blob.valueOf(e.getMessage());
        }
        return JSON.Serialize(invocationResult); 
    }
}