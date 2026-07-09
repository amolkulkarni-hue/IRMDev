@IsTest
class RecordTypeCacheTest
{
    static final Integer ITERATIONS = Limits.getLimitQueries() + 1;
    static final Schema.SObjectType WITHOUT_RECORDTYPE = Report.SObjectType;
    static Schema.SObjectType WITH_RECORDTYPE;
    static String EXISTING_DEVELOPERNAME;

    static void setupExistingRecordtype() {
        RecordType someRecordtype = [ SELECT SObjectType, DeveloperName FROM RecordType WHERE isActive = true LIMIT 1];
        WITH_RECORDTYPE = Schema.getGlobalDescribe().get(someRecordtype.SObjectType);
        EXISTING_DEVELOPERNAME = someRecordtype.DeveloperName;
    }

    static testMethod void testGet_List_Exists()
    {
        setupExistingRecordtype();
        List<RecordType> EXPECTED_TYPES = [
            SELECT Id FROM RecordType
            WHERE SObjectType = :String.valueOf(WITH_RECORDTYPE)
        ];
        system.assert(EXPECTED_TYPES.size() > 0, 'This test does not mean anything');

        Test.startTest();
            List<RecordType> returnedTypes;
            for (Integer i = 0; i < ITERATIONS; i++)
            {
                returnedTypes = RecordTypeCache.get(WITH_RECORDTYPE);
            }
            Integer consumedQueries = Limits.getQueries();
        Test.stopTest();

        system.assertEquals(1, consumedQueries,
            'Only one query should ever be consumed by the cache');
        system.assertNotEquals(null, returnedTypes,
            'A list should always be returned');
        system.assertEquals(EXPECTED_TYPES.size(), returnedTypes.size(),
            'Each RecordType for this SObjectType should be found');
        system.assertEquals(Pluck.ids(EXPECTED_TYPES), Pluck.ids(returnedTypes),
            'The correct RecordTypes for this SObjectType should be found');
    }

    static testMethod void testGet_List_DNE()
    {
        List<RecordType> EXPECTED_TYPES = [
            SELECT Id FROM RecordType
            WHERE SObjectType = :String.valueOf(WITHOUT_RECORDTYPE)
        ];
        system.assert(EXPECTED_TYPES.isEmpty(), 'This test does not mean anything');

        Test.startTest();
            List<RecordType> returnedTypes;
            for (Integer i = 0; i < ITERATIONS; i++)
            {
                returnedTypes = RecordTypeCache.get(WITHOUT_RECORDTYPE);
            }
            Integer consumedQueries = Limits.getQueries();
        Test.stopTest();

        system.assertEquals(1, consumedQueries,
            'Only one query should ever be consumed by the cache');
        system.assertNotEquals(null, returnedTypes,
            'A list should always be returned');
        system.assert(returnedTypes.isEmpty(),
            'If an SObjectType has no RecordTypes, the result should be empty');
    }

    static testMethod void testGet_Single_Exists()
    {
        setupExistingRecordtype();
        RecordType EXPECTED_TYPE = [
            SELECT Id FROM RecordType
            WHERE SObjectType = :String.valueOf(WITH_RECORDTYPE)
            AND DeveloperName = :EXISTING_DEVELOPERNAME
        ];

        Test.startTest();
            RecordType returnedType;
            for (Integer i = 0; i < ITERATIONS; i++)
            {
                returnedType = RecordTypeCache.get(WITH_RECORDTYPE, EXISTING_DEVELOPERNAME);
            }
            Integer consumedQueries = Limits.getQueries();
        Test.stopTest();

        system.assertEquals(1, consumedQueries,
            'Only one query should ever be consumed by the cache');
        system.assertNotEquals(null, returnedType,
            'A RecordType should be found');
        system.assertEquals(EXPECTED_TYPE.Id, returnedType.Id,
            'The correct RecordType should be found');
    }

    static testMethod void testGet_Single_DNE()
    {
        Test.startTest();
            RecordType returnedType;
            for (Integer i = 0; i < ITERATIONS; i++)
            {
                returnedType = RecordTypeCache.get(WITHOUT_RECORDTYPE, 'Any');
            }
            Integer consumedQueries = Limits.getQueries();
        Test.stopTest();

        system.assertEquals(1, consumedQueries,
            'Only one query should ever be consumed by the cache');
        system.assertEquals(null, returnedType,
            'No RecordType should be found');
    }
}