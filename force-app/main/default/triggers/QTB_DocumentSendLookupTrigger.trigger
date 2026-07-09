/*****************************************************************************************************
* Trigger		: QTB_DocumentSendLookupTrigger
* Test Class    : QTB_DocumentSendLookupTriggerHelper_Test
* Author		: Virtusa
* Purpose		: This is trigger will call the QTB_DocumentSendLookupTriggerHandler class to handle all events of QTB_Documents_Send_Lookup_Queue__c obj 
* Requirement	: Gitlab US #20933 -- Stop schedule call and run the logic based on need
* Change History: 01/22/2024
* Developer        Date           Description
* -------------------------------------------------------------------------------------------
*  Virtusa       01/22/2024      Gitlab US #20933 -- Stop schedule call and run the logic based on need
*******************************************************************************************************/
trigger QTB_DocumentSendLookupTrigger on QTB_Documents_Send_Lookup_Queue__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
	TriggerDispatcher.Run(new QTB_DocumentSendLookupTriggerHandler()); 
}