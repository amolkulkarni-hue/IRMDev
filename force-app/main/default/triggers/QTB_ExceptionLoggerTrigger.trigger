/*****************************************************************************************************
* Class:          QTB_ExceptionLoggerTrigger
* Author:         Accenture
* Purpose:        This is a trigger for Exception Logger Platform Event
* Requirement:    Logging pattern using Platform Events
* Change History: 7/3/2020
* Developer     Date           	Description
* ------------------------------------------------------------------------------------------- 
* Accenture     7/3/2020
* Accenture     7/6/2020        moving logic to single handler
* Accenture		7/21/2020		Removed logging enabled check as this runs in Automated Process context
*******************************************************************************************************/
trigger QTB_ExceptionLoggerTrigger on QTB_Exception_Logger__e (after insert) {
    QTB_ExceptionLoggerTriggerHandler.getInstance().onAfterInsert(Trigger.new);
}