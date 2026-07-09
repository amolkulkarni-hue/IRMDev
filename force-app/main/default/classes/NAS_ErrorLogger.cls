/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Error Logger Class. Utilized in North America Services project to Logg Integration Errors to 
* Custom Object NAS_Integration_Error__c
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class NAS_ErrorLogger {
    /**
     * @name log
     * @description Logs the error message received to NAS_Integration_Error__c custom object.
    **/
	public static void log(String className, String message, String dataDump)
    {
        INSERT new NAS_Integration_Error__c(
                NAS_Apex_Class_Name__c = className,
                NAS_Error_Message__c = message,
                NAS_Request_Data__c = dataDump
            );
    }
}