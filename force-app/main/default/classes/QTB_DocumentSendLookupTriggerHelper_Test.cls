/*****************************************************************************************************
* Test Class    : QTB_DocumentSendLookupTriggerHelper_Test
* Author		: Virtusa
* Purpose		: This is a helper class for all business logic related to I object
* Requirement	: Gitlab US #20933 -- Stop schedule call and run the logic based on need
* Change History: 01/22/2024
* Developer        Date           Description
* -------------------------------------------------------------------------------------------
*  Virtusa       01/22/2024      Gitlab US #20933 -- Stop schedule call and run the logic based on need
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_DocumentSendLookupTriggerHelper_Test {

    @testSetup
    static void setup(){
        QTB_Documents_Send_Lookup_Queue__c documentLookupObj = new QTB_Documents_Send_Lookup_Queue__c();
        documentLookupObj.QTB_Status__c = 'New';
        insert documentLookupObj;
    }
    
    @isTest
    static void testmethod1() {
       List<QTB_Documents_Send_Lookup_Queue__c> documLookUpList = [Select Id, Name,QTB_Status__c From QTB_Documents_Send_Lookup_Queue__c ];
        QTB_Documents_Send_Lookup_Queue__c docLookupUpdate = new QTB_Documents_Send_Lookup_Queue__c();
        docLookupUpdate.id = documLookUpList[0].Id;
        docLookupUpdate.QTB_Status__c = 'delete';
        update docLookupUpdate;
    }
}