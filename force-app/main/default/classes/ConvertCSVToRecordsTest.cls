@isTest
public class ConvertCSVToRecordsTest {
    
    @TestSetup
    static void setupTestData() {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestCSV';
        cv.PathOnClient = 'TestCSV.csv';
        
        String csvContent = 'Name,Industry\n' +
                           'Test Account 1,Technology\n' +
                           'Test Account 2,Manufacturing\n' +
                           'Test Account 3,Healthcare';
        
        cv.VersionData = Blob.valueOf(csvContent);
        cv.IsMajorVersion = true;
        insert cv;
    
        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'TestCSVComplex';
        cv2.PathOnClient = 'TestCSVComplex.csv';
        
        String csvComplexContent = 'Name,AnnualRevenue,NumberOfEmployees,Rating,Website,Contract_End_Date\n' +
                                  'Complex Account 1,"1,000,000.50",500,Hot,http://example.com,2020-01-15\n' +
                                  'Complex Account 2,"2,500,500.75",1200,Warm,http://test.com,2015-06-30';
        
        cv2.VersionData = Blob.valueOf(csvComplexContent);
        cv2.IsMajorVersion = true;
        insert cv2;
    }
    
    @isTest
    static void testBasicCSVConversion() {
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'TestCSV' LIMIT 1];
        String contentDocumentId = cv.ContentDocumentId;
        ConvertCSVToRecords.Request req = new ConvertCSVToRecords.Request();
        req.objectApiName = 'Account';
        req.FSep = ',';        // Field separator
        req.DSep = '.';        // Decimal separator
        req.TSep = ',';        // Thousands separator
        req.vCur = '$';        // Currency symbol
        req.contentDocumentId = contentDocumentId;
        req.isTrim = true;
        
        Test.startTest();
        List<ConvertCSVToRecords.Response> responses = ConvertCSVToRecords.convert(new List<ConvertCSVToRecords.Request>{req});
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should have one response');
        List<SObject> convertedRows = responses[0].convertedCSVRows;
        System.assertEquals(3, convertedRows.size(), 'Should have 3 converted records');
        
        Account acc1 = (Account)convertedRows[0];
        System.assertEquals('Test Account 1', acc1.Name, 'First account name should match');
        System.assertEquals('Technology', acc1.Industry, 'First account industry should match');
        
        Account acc3 = (Account)convertedRows[2];
        System.assertEquals('Test Account 3', acc3.Name, 'Third account name should match');
        System.assertEquals('Healthcare', acc3.Industry, 'Third account industry should match');
    }
    
    @isTest
    static void testComplexCSVConversion() {

        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'TestCSVComplex' LIMIT 1];
        String contentDocumentId = cv.ContentDocumentId;

        ConvertCSVToRecords.Request req = new ConvertCSVToRecords.Request();
        req.objectApiName = 'Account';
        req.FSep = ',';        // Field separator
        req.DSep = '.';        // Decimal separator
        req.TSep = ',';        // Thousands separator
        req.vCur = '$';        // Currency symbol
        req.dateFormat = 'yyyy-MM-dd';
        req.contentDocumentId = contentDocumentId;
        
        Test.startTest();
        List<ConvertCSVToRecords.Response> responses = ConvertCSVToRecords.convert(new List<ConvertCSVToRecords.Request>{req});
        Test.stopTest();

        List<SObject> convertedRows = responses[0].convertedCSVRows;
        System.assertEquals(2, convertedRows.size(), 'Should have 2 converted records');

        Account acc1 = (Account)convertedRows[0];
        System.assertEquals('Complex Account 1', acc1.Name, 'First complex account name should match');
    }
    
    @isTest
    static void testMultipleFilesConversion() {

        List<ContentVersion> cvs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title IN ('TestCSV', 'TestCSVComplex')];
        List<String> contentDocumentIds = new List<String>();
        for(ContentVersion cv : cvs) {
            contentDocumentIds.add(cv.ContentDocumentId);
        }

        ConvertCSVToRecords.Request req = new ConvertCSVToRecords.Request();
        req.objectApiName = 'Account';
        req.FSep = ',';
        req.DSep = '.';
        req.TSep = ',';
        req.vCur = '$';
        req.contentDocumentIdList = contentDocumentIds;
        

        Test.startTest();
        List<ConvertCSVToRecords.Response> responses = ConvertCSVToRecords.convert(new List<ConvertCSVToRecords.Request>{req});
        Test.stopTest();
        
        System.assertEquals(1, responses.size(), 'Should have one response');
        List<SObject> convertedRows = responses[0].convertedCSVRows;
        System.assertEquals(5, convertedRows.size(), 'Should have 5 combined records (3 from first file, 2 from second)');
    }
    
    @isTest
    static void testFieldTypeConversion() {

        Object boolResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.BOOLEAN, 'true', ',', '.', '$', null);
        System.assertEquals(true, boolResult, 'Boolean "true" should convert to true');
        
        boolResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.BOOLEAN, '1', ',', '.', '$', null);
        System.assertEquals(true, boolResult, 'Boolean "1" should convert to true');
        
        boolResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.BOOLEAN, 'false', ',', '.', '$', null);
        System.assertEquals(false, boolResult, 'Boolean "false" should convert to false');
        

        Object decimalResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.CURRENCY, '$1,000.50', ',', '.', '$', null);
        System.assertEquals(1000.50, decimalResult, 'Currency should be properly converted');
        

        Object intResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.INTEGER, '1,234', ',', '.', '$', null);
        System.assertEquals(1234, intResult, 'Integer should be properly converted');
        
        Object dateResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.DATE, '2023-12-31', ',', '.', '$', 'yyyy-MM-dd');
        System.assertEquals(Date.newInstance(2023, 12, 31), dateResult, 'Date in yyyy-MM-dd format should be properly converted');

        dateResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.DATE, '31-12-2023', ',', '.', '$', 'dd-MM-yyyy');
        System.assertEquals(Date.newInstance(2023, 12, 31), dateResult, 'Date in dd-MM-yyyy format should be properly converted');

        dateResult = ConvertCSVToRecords.getConvertedFieldValue(Schema.DisplayType.DATE, '12-31-2023', ',', '.', '$', 'MM-dd-yyyy');
        System.assertEquals(Date.newInstance(2023, 12, 31), dateResult, 'Date in MM-dd-yyyy format should be properly converted');
    }
    
    @isTest
    static void testErrorHandling() {

        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'TestCSV' LIMIT 1];
        String contentDocumentId = cv.ContentDocumentId;

        ContentVersion updatedCv = new ContentVersion();
        updatedCv.ContentDocumentId = contentDocumentId;
        updatedCv.Title = 'TestCSVWithInvalidField';
        updatedCv.PathOnClient = 'TestCSVWithInvalidField.csv';
        updatedCv.VersionData = Blob.valueOf('Name,Invalid_Field__c\nTest Account,Invalid Value');
        updatedCv.IsMajorVersion = true;
        insert updatedCv;
        
        ConvertCSVToRecords.Request req = new ConvertCSVToRecords.Request();
        req.objectApiName = 'Account';
        req.FSep = ',';
        req.DSep = '.';
        req.TSep = ',';
        req.vCur = '$';
        req.contentDocumentId = contentDocumentId;
        

        Test.startTest();
        try {
            ConvertCSVToRecords.convert(new List<ConvertCSVToRecords.Request>{req});
            System.assert(false, 'Should have thrown an exception for invalid field');
        } catch(ConvertCSVToRecords.FlowCustomException e) {
            System.assert(e.getMessage().contains('Invalid Field Error'), 'Exception should indicate invalid field');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testMissingInputs() {
        ConvertCSVToRecords.Request req = new ConvertCSVToRecords.Request();
        req.objectApiName = 'Account';
        req.FSep = ',';
        req.DSep = '.';
        req.TSep = ',';
        req.vCur = '$';

        Test.startTest();
        try {
            ConvertCSVToRecords.convert(new List<ConvertCSVToRecords.Request>{req});
            System.assert(false, 'Should have thrown an exception for missing inputs');
        } catch(ConvertCSVToRecords.FlowCustomException e) {
            System.assert(e.getMessage().contains('You need to provide either a single ContentDocument Id OR a list of ContentDocumentIds'), 
                         'Exception should indicate missing document ID');
        }
        Test.stopTest();
    }
}