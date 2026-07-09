public with sharing class RecordTypeCache
{
    static Map<String, List<RecordType>> recordTypes
    {
        get
        {
            if (recordTypes == null)
            {
                recordTypes = GroupBy.strings('SObjectType', [
                    SELECT DeveloperName, SObjectType, Name FROM RecordType
                ]);
            }
            return recordTypes;
        }
        private set;
    }
    static Map<String, Map<String, RecordType>> recordTypesByDeveloperName
    {
        get
        {
            if (recordTypesByDeveloperName == null)
            {
                recordTypesByDeveloperName = new Map<String, Map<String, RecordType>>();
            }
            return recordTypesByDeveloperName;
        }
        private set;
    }

    public static List<RecordType> get(Schema.SObjectType sObjectType)
    {
        return get(String.valueOf(sObjectType));
    }
    public static List<RecordType> get(String sObjectType)
    {
        return recordTypes.containsKey(sObjectType) ? recordTypes.get(sObjectType) : new List<RecordType>();
    }

    public static RecordType get(Schema.SObjectType sObjectType, String developerName)
    {
        return get(String.valueOf(sObjectType), developerName);
    }
    public static RecordType get(String sObjectType, String developerName)
    {
        if (!recordTypesByDeveloperName.containsKey(sObjectType))
        {
            Map<String, RecordType> byDeveloperName = new Map<String, RecordType>();
            for (RecordType recordType : get(sObjectType))
            {
                byDeveloperName.put(recordType.DeveloperName, recordType);
            }
            recordTypesByDeveloperName.put(sObjectType, byDeveloperName);
        }
        return recordTypesByDeveloperName.get(sObjectType).get(developerName);
    }
}