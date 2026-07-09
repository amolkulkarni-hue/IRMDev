/*****************************************************************************************************
* Class:          QTB_ExceptionLoggerTriggerHandler
* Author:         Accenture
* Purpose:        This is a handler class for all business logic related to User object
* Requirement:    Logging pattern using Platform Events
* Change History: 7/3/2020
* Developer     Date           	Description
* ------------------------------------------------------------------------------------------- 
* Accenture     7/3/2020
* Accenture		7/6/2020		Added singleton pattern and moved logic from helper to handler
* Accenture		7/9/2020		Changed Database.insert to insert and added try catch for DMLException
* Accenture		7/21/2020		Removed logging enabled check as this runs in Automated Process context
*******************************************************************************************************/
public class QTB_ExceptionLoggerTriggerHandler {
    private static QTB_ExceptionLoggerTriggerHandler handler;
    // lazy load and singleton
    public static QTB_ExceptionLoggerTriggerHandler getInstance() {
        if (handler == null) { handler = new QTB_ExceptionLoggerTriggerHandler(); }
        return handler;
    }
    
    /***********************************************************************************************************
    * Method :      onAfterInsert
    * Parameters:   List<QTB_Exception_Logger__e>
    * Return Type: 	void
    * Description:  This method creates records in QTB Exception Logger object for each event published
    ************************************************************************************************************/
    public void onAfterInsert(List<QTB_Exception_Logger__e> events) { 
        if (events <> NULL && !events.isEmpty()) {
            List<QTB_Exception_Log__c> logs = new List<QTB_Exception_Log__c>();
            for (QTB_Exception_Logger__e eachEvent : events) {
                QTB_Exception_Log__c log = new QTB_Exception_Log__c();
                log.QTB_Class_Reference__c = eachEvent.QTB_Origin__c;
                log.QTB_Exception_Type__c = eachEvent.QTB_Type__c;
                log.QTB_Stack_Trace__c = eachEvent.QTB_Body__c;
                logs.add(log);
            }
            if (!logs.isEmpty()) {
                try { insert logs; } 
                catch(DMLException e) { System.debug('Insert Failed, Error: ' + e.getMessage()); }
            }
        }
    }
}