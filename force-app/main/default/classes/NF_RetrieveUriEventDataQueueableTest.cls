@isTest
public class NF_RetrieveUriEventDataQueueableTest {

    @isTest
    static void testQueueableJob() {

        // Create fake CSV data as a string
        String fakeCsvData = 'Timestamp,URI,User\n2024-11-14T12:00:00Z,/003123456789,0056789012345\n2024-11-14T12:01:00Z,/001234567890,0056789012345';

        // Convert CSV data into a list of lines (simulating file content)
        List<String> csvLines = new List<String>();
        Integer lineStart = 0;
        Integer lineEnd = fakeCsvData.indexOf('\n');
        while (lineEnd != -1) {
            csvLines.add(fakeCsvData.substring(lineStart, lineEnd));
            lineStart = lineEnd + 1;
            lineEnd = fakeCsvData.indexOf('\n', lineStart);
        }
        if (lineStart < fakeCsvData.length()) {
            csvLines.add(fakeCsvData.substring(lineStart));
        }

        // Create a fake logFileId list (we don't need a real EventLogFile)
        List<Id> logFileIds = new List<Id>{'0ATDS00000YMW3Z4AX', '0ATDS00000YMVyN4AX'}; // Mocked log file IDs

        // Create an instance of the Queueable class and test execute
        Test.startTest();

        // Enqueue the Queueable job
        System.enqueueJob(new NF_RetrieveUriEventDataQueueable(logFileIds));

        Test.stopTest();

    }


    @isTest
    static void testQueueableConstructor() {
        // Step 1: Create mock data for the test
        
        // Simulate log file IDs (you can add real EventLogFile records here, but for the test we will mock them)
        List<Id> mockLogFileIds = new List<Id>{'0ATDS00000YMW3Z4AX', '0ATDS00000YMVyN4AX'};
        String userId = [Select Id From User Where IsActive=True Limit 1].Id;
        Lead l = new Lead(FirstName='Test', LastName='Lead', Company='Test Company', Status='Open');
        insert l;
        String leadId = l.Id;

        
        // Fake CSV lines for testing
        List<String> mockCsvLines = new List<String>{
                    '"Timestamp3","User3","/003DS00000M0sqQYAR","SomeOtherData","' + userId +  '","MoreData1","MoreData2","/' + leadId + '"',
                    '"Timestamp3","User3","/00QDS00000M0sqQYAR","SomeOtherData","' + userId +  '","MoreData1","MoreData2","/' + leadId + '"'
        };
        
        Integer mockFileIndex = 0; // Index of the current log file being processed
        Integer mockLineIndex = 0; // Start processing from the first line
        
        // Step 2: Create an instance of NF_RetrieveUriEventDataQueueable using the constructor
        Test.startTest(); // Start test context for asynchronous operations
        NF_RetrieveUriEventDataQueueable queueableJob = new NF_RetrieveUriEventDataQueueable(mockLogFileIds, mockFileIndex, mockCsvLines, mockLineIndex);
        Test.stopTest(); // Stop test context

    }    
}