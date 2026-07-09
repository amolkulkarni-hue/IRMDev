/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Error Logger Class NAS_ErrorLogger
* ──────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_ErrorLoggerTest {
	/**
     * @name testErrorLogger
     * @description Tests log method of NAS_ErrorLogger.
    **/
    public static testMethod void testErrorLogger()
    {
        Test.startTest();
        NAS_ErrorLogger.log('NAS_ErrorLoggerTest', 'Test Error message', 'None');
        List<NAS_Integration_Error__c> errorList = [SELECT Id, NAS_Apex_Class_Name__c, 
                                                    NAS_Error_Message__c, NAS_Request_Data__c FROM 
                                                    NAS_Integration_Error__c];
        Test.stopTest();
        System.assertEquals(1, errorList.size(), 'Incorrect number of Error Log Records created.');
        System.assertEquals('NAS_ErrorLoggerTest', errorList[0].NAS_Apex_Class_Name__c, 
                            'Error origin class not set properly.');
        System.assertEquals('Test Error message', errorList[0].NAS_Error_Message__c, 
                            'Error message not set properly.');
        System.assertEquals('None', errorList[0].NAS_Request_Data__c, 
                            'Error data not set properly.');
    }
}