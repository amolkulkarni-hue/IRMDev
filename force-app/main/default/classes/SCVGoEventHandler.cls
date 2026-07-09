/**
 * 	Class:				SCVGoEventHandler
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class creats record for SCV Go Log object.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class SCVGoEventHandler {

    public static void createLogs(List<SG_Log__e> exceptionsList){
        Schema.DescribeSObjectResult objSchema = SCVGo_Log__c.sObjectType.getDescribe();
        
        if(objSchema.isCreateable()) {
            Map<String, Schema.SObjectField> schemaMap = Schema.SObjectType.SCVGo_Log__c.fields.getMap();
            List<SCVGo_Log__c> logs = new List<SCVGo_Log__c>();
            
            for (SG_Log__e event : exceptionsList) {
                SCVGo_Log__c logRecord = new SCVGo_Log__c();
                    if(schemaMap.get('Message__c').getDescribe().isCreateable()) {
                        logRecord.put('Message__c' , event.Message__c);
                    }
                    if(schemaMap.get('Trace__c').getDescribe().isCreateable()) {
                        logRecord.put('Trace__c' , event.Trace__c);
                    }
                    if(schemaMap.get('Data__c').getDescribe().isCreateable()) {
                        logRecord.put('Data__c' , event.Data__c);
                    }
                    if(schemaMap.get('Type__c').getDescribe().isCreateable()) {
                        logRecord.put('Type__c' , event.Type__c);
                    }
                    if(schemaMap.get('User_Information__c').getDescribe().isCreateable()) {
                        logRecord.put('User_Information__c' , event.User_Information__c);
                    }
                    logs.add(logRecord);
            }
            if(!logs.isEmpty()){
                insert logs;
            }
        }
        
    }
}