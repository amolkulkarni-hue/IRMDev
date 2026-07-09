@isTest(seealldata=false)
private with sharing class ExceptionLogger_Test{
    
    static testmethod void test() {       
        Test.startTest();
        String classReference = 'InvoiceBatch';
        String errorMessage = ' Too many DML statements :151';
        String exceptionType = 'DML Exception';
        Integer lineNumber = 25;
        String stackTrace = 'Sample stack trace';
        ExceptionLogger.createLog(lineNumber,stackTrace,errorMessage,exceptionType,classReference);
        Test.stopTest();
        Exception_Log__c exceptionLog = [select id,Class_Reference__c ,Line_Number__c from Exception_Log__c where Class_Reference__c = 'InvoiceBatch'];
        System.assert(exceptionLog.Line_Number__c == 25);
    }
    static testmethod void test2() {       
        Test.startTest();
        String classReference = 'ClassReferenceTest';
        String errorMessage = ' Too many DML statements :151';
        Integer lineNumber = 25;
        String stackTrace = 'Sample stack trace';
        List<String> errmsg = new List<String>();
        errmsg.add(errorMessage);
        ExceptionLogger.createLogForFailedBatchRecords(errmsg, classReference, lineNumber);
        Test.stopTest();
        Exception_Log__c exceptionLog = [select id,Class_Reference__c ,Line_Number__c from Exception_Log__c where Class_Reference__c = 'ClassReferenceTest'];
        System.assert(exceptionLog.Line_Number__c == 25);
    }
}