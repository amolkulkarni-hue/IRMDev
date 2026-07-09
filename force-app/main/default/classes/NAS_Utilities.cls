/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Utilities Class to contain various utility methods.
* Modified getRecurringCaseQueryLocator method as a fix for case #12815451 on 14 jan 2020
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public class NAS_Utilities {
	/**
     * @name isExecuteGetReplicationEventsBatch
	 * @description returns true if there is a pending batch job for the batchable class NAS_GetReplicationEventsBatchable.
    **/
	public static Boolean isExecuteGetReplicationEventsBatch()
	{
        return NAS_Utilities.isPendingBatchableJob('NAS_GetReplicationEventsBatchable');
	}
	/**
     * @name isExecuteUpdateSKPEventQueueable
	 * @description returns true if there is a pending queueable job for the queueable class NAS_UpdateSKPEventQueueable
	 * and there are cases with pending SKP Event update.
    **/
	public static Boolean isExecuteUpdateSKPEventQueueable()
	{
        return NAS_Utilities.isPendingQueueableJob('NAS_UpdateSKPEventQueueable') && NAS_Utilities.isCasePendingSKPEventUpdate();
	}
	/**
     * @name isExecuteUpdateCommunicatorQueueable
	 * @description returns true if there is a pending queueable job for the queueable class NAS_UpdateCommunicatorQueueable
	 * and there are cases with pending SKP Communicator update.
    **/
	public static Boolean isExecuteUpdateCommunicatorQueueable()
	{
        return NAS_Utilities.isPendingQueueableJob('NAS_UpdateCommunicatorQueueable') && NAS_Utilities.isCasePendingSKPCommunicatorUpdate();
	}
	/**
     * @name isCasePendingSKPEventUpdate
	 * @description returns true if are cases with pending SKP Event update.
    **/
	public static Boolean isCasePendingSKPEventUpdate()
	{
		List<Case> casePendingSKPEventUpdateList = NAS_DataFactory.getCasePendingSKPEventUpdateList();
        return !casePendingSKPEventUpdateList.isEmpty();
	}
	/**
     * @name isCasePendingSKPCommunicatorUpdate
	 * @description returns true if are cases with pending SKP Communicator update.
    **/
	public static Boolean isCasePendingSKPCommunicatorUpdate()
	{
		List<Case> casePendingSKPUpdateCommunicatorList = NAS_DataFactory.getCasePendingSKPCommunicatorUpdateList();
        return !casePendingSKPUpdateCommunicatorList.isEmpty();
	}
	/**
     * @name isPendingBatchableJob
	 * @description returns true if there is a pending batch job for the batchable class matching with parameter jobApexClassName.
    **/
	private static Boolean isPendingBatchableJob(String jobApexClassName)
	{
        return NAS_Utilities.isPendingJob(jobApexClassName, 'Batch Apex');
	}
	/**
     * @name isPendingQueueableJob
	 * @description returns true if there is a pending Queueable job for the Queueable class matching with parameter jobApexClassName.
    **/
	private static Boolean isPendingQueueableJob(String jobApexClassName)
	{
        return NAS_Utilities.isPendingJob(jobApexClassName, 'Queueable');
	}
	/**
     * @name isPendingJob
	 * @description returns true if there is a pending job for the apex class matching with parameter jobApexClassName and of type jobType
    **/
	private static Boolean isPendingJob(String jobApexClassName, String jobType)
	{
		List<AsyncApexJob> pendingJobList = [SELECT Id, JobType, MethodName, ParentJobId, Status FROM AsyncApexJob 
                                     WHERE ApexClass.Name = :jobApexClassName AND JobType = :jobType AND 
                                     (Status != 'Aborted' AND Status != 'Completed' AND Status != 'Failed')];
        return pendingJobList.isEmpty();
	}
	/**
     * @name getOrgCache
	 * @description returns the org cache with name key from NAS Application Cache org partition. 
	 * If the key == NASWSGAuthorizationToken and there is a cache miss, it addas a new value with a defined time out.
	 * Returns the org cache value using Cach Builder for all other keys. 
    **/
    public static Object getOrgCache(String key, Boolean reset)
    {
    	Object returnValue = null;
        Cache.OrgPartition orgPartition = Cache.Org.getPartition(NAS_Constants.NAS_APPLICATION_CACHE_NAME);
        if(key == NAS_Constants.KEY_ORG_CACHE_WSG_AUTHORIZATION_TOKEN)
        {
            returnValue = orgPartition.get(key);
            if(returnValue == null || reset) 
            	orgPartition.put(key, NAS_RequestFactory.requestAuthorizationToken(), NAS_Constants.WSG_AUTH_TOKEN_TIMEOUT);
           	returnValue = orgPartition.get(key);
        }
        else 
        	returnValue = orgPartition.get(NAS_ApplicationCacheBuilder.class, key);
       	return returnValue;
    }
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    /**
     * @name getDescribeSObjectByObjectName
     * @description Singleton implementation to return DescribeSObjectResult for a given SObjectName.
    **/
    private static Map<String, Schema.DescribeSObjectResult> mapDescribeSObjectByObject 
        = new Map<String, Schema.DescribeSObjectResult>();
	private static Schema.DescribeSObjectResult getDescribeSObjectByObjectName(String objectName){
        if(mapDescribeSObjectByObject.get(objectName) == null)
            mapDescribeSObjectByObject.put(objectName, 
                  globalDescribe.get(objectName).getDescribe());
        return mapDescribeSObjectByObject.get(objectName);
    }
    /**
     * @name getFieldMapDescribeByObjectName
     * @description Singleton implementation to return Map<String, Schema.SObjectField> for a given SObjectName.
    **/
    private static Map<String, Map<String, Schema.SObjectField>> mapFieldMapDescribeByObject 
        = new Map<String, Map<String, Schema.SObjectField>>();
	private static Map<String, Schema.SObjectField> getFieldMapDescribeByObjectName(String objectName){
        if(mapFieldMapDescribeByObject.get(objectName) == null)
            mapFieldMapDescribeByObject.put(objectName, 
                  NAS_Utilities.getDescribeSObjectByObjectName(objectName).fields.getMap());
        return mapFieldMapDescribeByObject.get(objectName);
    }
    /**
     * @name isCreatable
     * @description Return Boolean value if the given fieldName of the objectName isCreatable by the running user.
    **/
    public static Boolean isCreatable(String objectName, String fieldName){
        Schema.SObjectField sobjField = NAS_Utilities.getFieldMapDescribeByObjectName(objectName).get(fieldName);
        Schema.DescribeFieldResult fr =  sobjField.getDescribe();
        return fr.isCreateable();
    }
    /**
     * @name getRecurringCaseFieldsToClone
     * @description Singleton implementation to return comma seperated Field Names for a given Page Layout Name.
    **/
    private static String commaSeparatedRecurringCaseFields = null;
    public static String getRecurringCaseFieldsToClone() {
        if(commaSeparatedRecurringCaseFields == null)
        {
            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(
                								Metadata.MetadataType.Layout, 
                								new List<String> {NAS_Constants.CASE_PAGE_LAYOUT_PREFIX + 
                                                    			  NAS_Constants.RECURRING_CASE_PAGE_LAYOUT});
            if(!layouts.isEmpty())
            {
                commaSeparatedRecurringCaseFields = '';
                Metadata.Metadata layout = layouts[0];
                List<Metadata.LayoutSection> layoutSections = ((Metadata.Layout)layout).layoutSections;
                for (Metadata.LayoutSection section : layoutSections) {
                    if(section.label == NAS_Constants.RECURRING_CASE_PAGE_LAYOUT_SECTION_NAME)
                    {
                        List<Metadata.LayoutColumn> layoutColumns = section.layoutColumns; 
                        for (Metadata.LayoutColumn col : layoutColumns) {
                            if(col.layoutItems != null){
                                for (Metadata.LayoutItem layoutItem : col.layoutItems) {
                                    commaSeparatedRecurringCaseFields = commaSeparatedRecurringCaseFields + 
                                        (commaSeparatedRecurringCaseFields == '' ? '' : ',') + 
                                        layoutItem.field;
                                }
                            }
                        }
                    }
                }
            }
        }
        return commaSeparatedRecurringCaseFields;
    }
    /**
     * @name getNextRecurrenceDate
     * @description Computes the next recurrence date from today for a given recurrence frequency.
     * Expected Values for recurrence frequency are:
     * DAY MONTH | YEAR + <Number to Add> 
     * Example: 
     * Daily = DAY + 1 
     * Weekly = DAY + 7 
     * Every 2 Week = DAY + 14 
     * Monthly = MONTH + 1
     * Quarterly = MONTH + 3 
     * Every 6 Month = MONTH + 6 
     * Yearly = YEAR + 1
    **/
    public static Date getNextRecurrenceDate(String recurrenceFrequency){
        Date returnValue = Date.today();
        if(recurrenceFrequency != null)
        {
            String[] recurrenceDimentionValuePair = recurrenceFrequency.split('\\+');
            if(recurrenceDimentionValuePair.size() == 2)
            {
                String dimention = recurrenceDimentionValuePair[0].trim().toUpperCase();
                Integer value = Integer.valueOf(recurrenceDimentionValuePair[1].trim());
                if(dimention == NAS_Constants.DAY)
            		returnValue = returnValue.addDays(value);
                else if(dimention == NAS_Constants.MONTH)
                    returnValue = returnValue.addMonths(value);
                else if(dimention == NAS_Constants.YEAR)
                    returnValue = returnValue.addYears(value);
            }
        }
        return returnValue;
    }
    /**
     * @name getRecurringCaseQueryLocator
     * @description Return Database.QueryLocator for Recurring Cases for Batch processing and generate Cases.
     * Modified query by Gouthami to fix Apex CPU limit for excluding old cases fix for case #12815451 on 14 jan 2020
    **/
    public static Database.QueryLocator getRecurringCaseQueryLocator() {
        String caseFieldListString = NAS_Utilities.getRecurringCaseFieldsToClone();
    	/*String query = 'SELECT ' + caseFieldListString +', NAS_Recurrence_Frequency__c FROM Case WHERE RecordTypeId = \'' + 
            NAS_DataFactory.getRecordTypeId('Case', NAS_Constants.RECURRING_CASE_RECORDTYPE) +
            '\'' +' AND NAS_Next_Case_Creation_Date__c <= TODAY AND CreatedDate > 2020-01-10T00:00:00Z AND Status = \'' +
            NAS_Constants.RECURRING_CASE_ACTIVE + '\' Limit 50000000';
         system.debug('query>>'+database.getQueryLocator(query));
       */
         return Database.getQueryLocator(
            'SELECT ' + caseFieldListString +', NAS_Recurrence_Frequency__c FROM Case WHERE RecordTypeId = \'' + 
            NAS_DataFactory.getRecordTypeId('Case', NAS_Constants.RECURRING_CASE_RECORDTYPE) +
            '\'' +' AND NAS_Next_Case_Creation_Date__c <= TODAY AND CreatedDate > 2020-01-10T00:00:00Z AND Status = \'' + 
                    NAS_Constants.RECURRING_CASE_ACTIVE + '\' Limit 50000000');
    }
    
     /**
     * @name encryptAES128WithSKPKey
     * @description Return encrypted text using AES128 and SKP 16 byte key.
    **/
    public static String encryptAES128WithSKPKey(String textToEncrypt)
    {
        Blob privateKey = EncodingUtil.convertFromHex(NAS_Constants.SKP_AES_128_PRIVATE_KEY);
        Blob initializationVector = EncodingUtil.convertFromHex(NAS_Constants.SKP_AES_128_INITIALIZATION_VECTOR);
        Blob data = Blob.valueOf(textToEncrypt);
        Blob encryptedData = Crypto.encrypt('AES128', privateKey, initializationVector, data);
        return EncodingUtil.convertToHex(encryptedData);
    }
    /**
     * @name decryptAES128WithSKPKey
     * @description Return decrypted text using AES128 and SKP 16 byte key.
    *
    public static String decryptAES128WithSKPKey(String textToDecrypt)
    {
        Blob privateKey = Blob.valueOf(NAS_Constants.SKP_AES_128_PRIVATE_KEY);
        Blob initializationVector = Blob.valueOf(NAS_Constants.SKP_AES_128_INITIALIZATION_VECTOR);
        Blob data = EncodingUtil.convertFromHex(textToDecrypt);
        Blob decryptedData = Crypto.decrypt('AES128', privateKey, initializationVector, data);
        return decryptedData.toString();
    }*/
    
    public static Map<String, Object> replaceBarredCharacters(Map<String, Object> data)
    {
		for(Object o : data.keySet())
		{
            String key = String.valueOf(o);
            Object dataElement = data.get(key);
    		if(dataElement instanceof Map<String, Object>)
        		data.put(key, NAS_Utilities.replaceBarredCharacters((Map<String, Object>) dataElement));
            else if(dataElement instanceof String)
        		data.put(key, ((String) dataElement).replaceAll('[' + 
                              NAS_Constants.SKP_API_BARRED_CHARACTERS + ']', 
                              NAS_Constants.SKP_API_BARRED_CHARACTER_REPLACEMENT));
		}
        return data;
    }
}