public class NF_RetrieveUriEventDataQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> logFileIds;
    private Integer fileIndex;
    private List<String> csvLines;
    private Integer lineIndex;

    // Constructor for initial call
    public NF_RetrieveUriEventDataQueueable(List<Id> logFileIds) {
        this.logFileIds = logFileIds;
        this.fileIndex = 0;
        this.lineIndex = 0;
    }

    // Constructor for chained call (continuing within the same file or moving to the next)
    public NF_RetrieveUriEventDataQueueable(List<Id> logFileIds, Integer fileIndex, List<String> csvLines, Integer lineIndex) {
        this.logFileIds = logFileIds;
        this.fileIndex = fileIndex;
        this.csvLines = csvLines;
        this.lineIndex = lineIndex;
    }

    public void execute(QueueableContext context) {
        if (csvLines == null || lineIndex == 0) {
            if (fileIndex >= logFileIds.size()) {
                System.debug('All log files processed sequentially.');
                return;
            }
    
            // Check if we are in a test context and inject fake CSV data
            if (Test.isRunningTest()) {
                // Fake CSV data to simulate EventLogFile content for testing
                String userId = [Select Id From User Where IsActive=True Limit 1].Id;
                Lead l = new Lead(FirstName='Test', LastName='Lead', Company='Test Company', Status='Open');
                insert l;
                String leadId = l.Id;
                
                // ARMAN
                // //Account acct = new Account(Name='TestAcct', CurrencyIsoCode='CNY', IM_Country_Code__c='China', 
                                           //BillingCountry='China');
				//Account acct = new Account(Name='TestAcct', CurrencyIsoCode='CNY', BillingCountry='China');
                Account acct = new Account(Name='TestAcct', CurrencyIsoCode='CNY');                         
                insert acct;
                String acctId = acct.Id;
                
                // FAILURES with Country settings:
                //IM_Country__c billingCountry = [SELECT Id FROM IM_Country__c WHERE Name='United States' LIMIT 1];
                //IM_Country__c imCountry = new IM_Country__c(Name='United States');
                /*IM_Country__c imCountry = new IM_Country__c(Name='China');
                insert imCountry;
                Opportunity opty = new Opportunity(Name='Test Opp1', AccountId=acct.Id, Type='New Deal',
                                                   Primary_Product_Line__c='', ForecastCategoryName='Pipeline', 
                                                   StageName ='1 - Qualification', 
                                                   Amount = 9999, US_Federal_GSA_Pricing__c ='No', CloseDate=Date.Today()+100,
                                                   CurrencyIsoCode ='CNY', Billing_Country__c=imCountry.Id);
                insert opty;
                String optyId = opty.Id; */
                
                Contact cntct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id, Email='test@test.com');
                insert cntct;
                String contactId = cntct.Id;
                //**ARMAN**//
                
                csvLines = new List<String>{
                    '"Timestamp1","User1","/001DS00000M0sqQYAR","SomeOtherData","' + userId +  '","MoreData1","MoreData2","/' + acctId + '"',
                    '"Timestamp2","User2","/006DS00000M0sqQYAR","SomeOtherData","' + userId +  '","MoreData1","MoreData2","/' + acctId + '"',
                    '"Timestamp3","User3","/003DS00000M0sqQYAR","SomeOtherData","' + userId +  '","MoreData1","MoreData2","/' + contactId + '"',
                    '"Timestamp3","User3","/00QDS00000M0sqQYAR","SomeOtherData","' + userId +  '","MoreData1","MoreData2","/' + leadId + '"'
                };
                System.debug('-- csvLines.size(): ' + csvLines.size());
                System.debug('-- csvLines: ' + csvLines);
                lineIndex = 0;  // Set the lineIndex to 0 to start processing from the beginning
                System.debug('Fake CSV data injected for testing.');
            } else {
                // Normally fetch log file data from EventLogFile
                EventLogFile logFile = [SELECT Id, LogDate, LogFile FROM EventLogFile WHERE Id = :logFileIds[fileIndex] LIMIT 1];
                if (logFile.LogFile == null) {
                    System.debug('No log file data found for log file ID: ' + logFile.Id);
                    enqueueNextFile();
                    return;
                }
    
                String csvData = logFile.LogFile.toString();
                csvLines = new List<String>();
                Integer lineStart = 0;
                Integer lineEnd = csvData.indexOf('\n');
    
                while (lineEnd != -1) {
                    csvLines.add(csvData.substring(lineStart, lineEnd));
                    lineStart = lineEnd + 1;
                    lineEnd = csvData.indexOf('\n', lineStart);
                }
    
                if (lineStart < csvData.length()) {
                    csvLines.add(csvData.substring(lineStart));
                }
                lineIndex = 0;
            }
        }
    
        // Continue with the rest of the logic (processing CSV lines, inserting records, etc.)
        Integer batchSize = 1000;
        Integer endIndex = Math.min(lineIndex + batchSize, csvLines.size());
        List<User_Access__c> userAccessRecords = new List<User_Access__c>();
    
        Set<String> userIds = new Set<String>();
        Set<String> accountIds = new Set<String>();
        Set<String> opportunityIds = new Set<String>();
        Set<String> contactIds = new Set<String>();
        Set<String> leadIds = new Set<String>();
    
        for (Integer i = lineIndex; i < endIndex; i++) {
            List<String> columns = csvLines[i].split(',');
    
            String uri = columns[7].replace('"', '');
            //** ARMAN//
              System.debug('-- URI: ' + uri + ', uri.length(): ' + uri.length());
              System.debug('-- uri.substring(1, 4).isNumeric(): ' + uri.substring(1, 4).isNumeric());
            //* **ARMAN/
            //ARMAN:  if (uri != null && uri.length() > 3 && uri.substring(1, 4).isNumeric()) {
            if (uri != null && uri.length() > 3) {
                String userId = columns[4].replace('"', '');
                User_Access__c userAccessRecord = new User_Access__c();
                userAccessRecord.Record_URI__c = uri;
                userAccessRecord.User__c = userId;
                userAccessRecord.Event_Timestamp__c = columns[1].replace('"', '');
    
                String cleanUri = uri.replaceAll('^/', '').replaceAll('/e$', '');
                System.debug('-- cleanUri: '+cleanUri);
                String recordId = (cleanUri.length() == 15 || cleanUri.length() == 18) ? cleanUri : null;
                System.debug('-- recordId: '+recordId);
    
                if (recordId != null && isValidSalesforceId(recordId)) {
                    if (recordId.startsWith('001')) {        // Account
                        accountIds.add(recordId);
                    } else if (recordId.startsWith('006')) { // Opportunity
                        opportunityIds.add(recordId);
                    } else if (recordId.startsWith('003')) { // Contact
                        contactIds.add(recordId);
                    } else if (recordId.startsWith('00Q')) { // Lead
                        leadIds.add(recordId);
                    } 
                }
                if (uri.startsWith('/001') || uri.startsWith('/006') || uri.startsWith('/003') || uri.startsWith('/00Q')) {
                    userAccessRecords.add(userAccessRecord);
                }
    
                if (userId != null) {
                    userIds.add(userId);
                }
            }
        }
    
        Map<String, User> userDetailsMap = new Map<String, User>();
        for (User user : [SELECT Id, Name, Email, UserRole.Name, Profile.Name, Country, Department 
                          FROM User 
                          WHERE Id IN :userIds]) {
            userDetailsMap.put(String.valueOf(user.Id).substring(0, 15), user);
        }
    
        Map<String, String> recordOwnersMap = getRecordOwnersById(accountIds, opportunityIds, contactIds, leadIds);
    
        for (User_Access__c userAccessRecord : userAccessRecords) {
            String key = String.valueOf(userAccessRecord.User__c).substring(0, 15);
            if (userDetailsMap.containsKey(key)) {
                User user = userDetailsMap.get(key);
                userAccessRecord.User_Name__c = user.Name;
                userAccessRecord.User_Email__c = user.Email;
                userAccessRecord.User_Role__c = user.UserRole != null ? user.UserRole.Name : null;
                userAccessRecord.User_Profile__c = user.Profile != null ? user.Profile.Name : null;
                userAccessRecord.User_Country__c = user.Country;
                userAccessRecord.User_Department__c = user.Department;
            }
    
            String cleanUri = userAccessRecord.Record_URI__c.replaceAll('^/', '').replaceAll('/e$', '');
            String recordId = (cleanUri.length() == 15 || cleanUri.length() == 18) ? cleanUri : null;
            if (recordId != null && recordOwnersMap.containsKey(recordId)) {
                userAccessRecord.Record_Owner__c = recordOwnersMap.get(recordId);
            }
        }
    
        insert userAccessRecords;
        System.debug('Inserted ' + userAccessRecords.size() + ' User_Access__c records');
    
        if (endIndex < csvLines.size()) {
            //if (!Test.isRunningTest()) {
                System.enqueueJob(new NF_RetrieveUriEventDataQueueable(logFileIds, fileIndex, csvLines, endIndex));
            //}
        } else {
            enqueueNextFile();
        }
    }
    

    private void enqueueNextFile() {
        Integer nextFileIndex = fileIndex + 1;
        if (nextFileIndex < logFileIds.size()) {
            if (!Test.isRunningTest()) {
               System.enqueueJob(new NF_RetrieveUriEventDataQueueable(logFileIds, nextFileIndex, null, 0));
           }
        }
    }

    private Boolean isValidSalesforceId(String recordId) {
        return recordId != null && (recordId.length() == 15 || recordId.length() == 18) && Pattern.matches('^[a-zA-Z0-9]+$', recordId);
    }

    private Map<String, String> getRecordOwnersById(Set<String> accountIds, Set<String> opportunityIds, Set<String> contactIds, Set<String> leadIds) {
        Map<String, String> recordOwnersMap = new Map<String, String>();

        if (!accountIds.isEmpty()) {
            for (Account acc : [SELECT Id, Owner.Name FROM Account WHERE Id IN :accountIds]) {
                recordOwnersMap.put(acc.Id, acc.Owner.Name);
            }
        }

        if (!opportunityIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, Owner.Name FROM Opportunity WHERE Id IN :opportunityIds]) {
                recordOwnersMap.put(opp.Id, opp.Owner.Name);
            }
        }

        if (!contactIds.isEmpty()) {
            for (Contact con : [SELECT Id, Owner.Name FROM Contact WHERE Id IN :contactIds]) {
                recordOwnersMap.put(con.Id, con.Owner.Name);
            }
        }

        if (!leadIds.isEmpty()) {
            for (Lead lead : [SELECT Id, Owner.Name FROM Lead WHERE Id IN :leadIds]) {
                recordOwnersMap.put(lead.Id, lead.Owner.Name);
            }
        }

        return recordOwnersMap;
    }
}



/*public class NF_RetrieveUriEventDataQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> logFileIds;   // List of EventLogFile IDs
    private Integer fileIndex;     // Current index for log file processing
    private List<String> csvLines; // CSV lines from current file
    private Integer lineIndex;     // Index for batch processing within the CSV lines

    // Constructor for initial call
    public NF_RetrieveUriEventDataQueueable(List<Id> logFileIds) {
        this.logFileIds = logFileIds;
        this.fileIndex = 0;
        this.lineIndex = 0;
    }

    // Constructor for chained call (continuing within the same file or moving to the next)
    public NF_RetrieveUriEventDataQueueable(List<Id> logFileIds, Integer fileIndex, List<String> csvLines, Integer lineIndex) {
        this.logFileIds = logFileIds;
        this.fileIndex = fileIndex;
        this.csvLines = csvLines;
        this.lineIndex = lineIndex;
    }

    public void execute(QueueableContext context) {
        // Check if we're processing a new file or continuing with an existing CSV batch
        if (csvLines == null || lineIndex == 0) {
            // Retrieve and process the next EventLogFile
            if (fileIndex >= logFileIds.size()) {
                System.debug('All log files processed sequentially.');
                return;
            }

            EventLogFile logFile = [SELECT Id, LogDate, LogFile FROM EventLogFile WHERE Id = :logFileIds[fileIndex] LIMIT 1];
            if (logFile.LogFile == null) {
                System.debug('No log file data found for log file ID: ' + logFile.Id);
                enqueueNextFile();
                return;
            }

            // Convert Blob to String and split into lines
            csvLines = logFile.LogFile.toString().split('\n');
            lineIndex = 0; // Reset line index for batch processing within this file
        }

        // Process the current batch of lines
        Integer batchSize = 1000;
        Integer endIndex = Math.min(lineIndex + batchSize, csvLines.size());
        List<User_Access__c> userAccessRecords = new List<User_Access__c>();

        for (Integer i = lineIndex; i < endIndex; i++) {
            List<String> columns = csvLines[i].split(',');

            // Custom filter logic, e.g., filter on URI field
            String uri = columns[7].replace('"', '');
            if (uri != null && uri.length() > 3 && uri.substring(1, 4).isNumeric()) {
                User_Access__c userAccessRecord = new User_Access__c();
                userAccessRecord.Record_URI__c = uri;
                userAccessRecord.User__c = columns[4].replace('"', '');
                userAccessRecord.Event_Timestamp__c = columns[1].replace('"', '');
                userAccessRecords.add(userAccessRecord);
            }
        }

        // Insert batch of User_Access__c records
        insert userAccessRecords;
        System.debug('Inserted ' + userAccessRecords.size() + ' User_Access__c records');

        // Chain to the next batch within the same file or proceed to the next file
        if (endIndex < csvLines.size()) {
            System.enqueueJob(new NF_RetrieveUriEventDataQueueable(logFileIds, fileIndex, csvLines, endIndex));
        } else {
            enqueueNextFile();
        }
    }

    // Helper method to enqueue the next file in the list
    private void enqueueNextFile() {
        Integer nextFileIndex = fileIndex + 1;
        if (nextFileIndex < logFileIds.size()) {
            System.enqueueJob(new NF_RetrieveUriEventDataQueueable(logFileIds, nextFileIndex, null, 0));
        }
    }
}

*/


/*
public class NF_RetrieveUriEventDataQueueable implements Queueable, Database.AllowsCallouts {
    private List<String> csvLines;
    private Integer startIndex;

    // Constructor 
    public NF_RetrieveUriEventDataQueueable(List<String> csvLines, Integer startIndex) {
        this.csvLines = csvLines;
        this.startIndex = startIndex;
    }

    public void execute(QueueableContext context) {
        Integer endIndex = Math.min(startIndex + 1000, csvLines.size());
        List<User_Access__c> userAccessRecords = new List<User_Access__c>();
        Set<String> userIds = new Set<String>();

        // Store IDs for bulk querying
        Set<String> accountIds = new Set<String>();
        Set<String> opportunityIds = new Set<String>();
        Set<String> contactIds = new Set<String>();
        Set<String> leadIds = new Set<String>();
        
        // Process lines from startIndex to endIndex
        for (Integer i = startIndex; i < endIndex; i++) {
            List<String> columns = csvLines[i].split(',');

            // Apply filter on URI field
            String uri = columns[7].replace('"', '');
            if (uri != null && uri.length() > 3 && uri.substring(1, 4).isNumeric()) {
                String userId = columns[4].replace('"', '');

                User_Access__c userAccessRecord = new User_Access__c();
                userAccessRecord.Record_URI__c = uri;
                userAccessRecord.User__c = userId;
                userAccessRecord.Event_Timestamp__c = columns[1].replace('"', ''); // Treating timestamp as a String

                // Clean URI to extract and categorize Salesforce record ID
                String cleanUri = uri.replaceAll('^/', '').replaceAll('/e$', ''); // Remove leading '/' and trailing '/e'
                String recordId = (cleanUri.length() == 15 || cleanUri.length() == 18) ? cleanUri : null;

                if (recordId != null && isValidSalesforceId(recordId)) {
                    if (recordId.startsWith('001')) {        // Account
                        accountIds.add(recordId);
                    } else if (recordId.startsWith('006')) { // Opportunity
                        opportunityIds.add(recordId);
                    } else if (recordId.startsWith('003')) { // Contact
                        contactIds.add(recordId);
                    } else if (recordId.startsWith('00Q')) { // Lead
                        leadIds.add(recordId);
                    }
                }

                userAccessRecords.add(userAccessRecord);

                if (userId != null) {
                    userIds.add(userId);
                }
            }
        }

        // Query User object for additional details
        Map<String, User> userDetailsMap = new Map<String, User>();
        for (User user : [SELECT Id, Name, Email, UserRole.Name, Profile.Name, Country, Department 
                          FROM User 
                          WHERE Id IN :userIds]) {
            userDetailsMap.put(string.valueOf(user.Id).substring(0, 15), user);
        }

        // Retrieve record owners using the helper method
        Map<String, String> recordOwnersMap = getRecordOwnersById(accountIds, opportunityIds, contactIds, leadIds);

        // Enhance User_Access__c records with additional user details and record owner
        for (User_Access__c userAccessRecord : userAccessRecords) {
            String key = String.valueOf(userAccessRecord.User__c).substring(0, 15);
            if (userDetailsMap.containsKey(key)) {
                User user = userDetailsMap.get(key);
                userAccessRecord.User_Name__c = user.Name;
                userAccessRecord.User_Email__c = user.Email;
                userAccessRecord.User_Role__c = user.UserRole != null ? user.UserRole.Name : null;
                userAccessRecord.User_Profile__c = user.Profile != null ? user.Profile.Name : null;
                userAccessRecord.User_Country__c = user.Country;
                userAccessRecord.User_Department__c = user.Department;
            }

            // Set Record Owner if it exists in the map
            String cleanUri = userAccessRecord.Record_URI__c.replaceAll('^/', '').replaceAll('/e$', ''); // Clean URI for the record ID
            String recordId = (cleanUri.length() == 15 || cleanUri.length() == 18) ? cleanUri : null;
            if (recordId != null && recordOwnersMap.containsKey(recordId)) {
                userAccessRecord.Record_Owner__c = recordOwnersMap.get(recordId);
            }
        }

        // Insert filtered User_Access__c records
        insert userAccessRecords;
        System.debug('Inserted ' + userAccessRecords.size() + ' User_Access__c records');

        // Chain another Queueable job if there are more lines to process
        if (endIndex < csvLines.size()) {
            System.enqueueJob(new NF_RetrieveUriEventDataQueueable(csvLines, endIndex));
        }
    }

    // Helper method to validate Salesforce ID (15 or 18 characters, alphanumeric)
    private Boolean isValidSalesforceId(String recordId) {
        return recordId != null && (recordId.length() == 15 || recordId.length() == 18) && Pattern.matches('^[a-zA-Z0-9]+$', recordId);
    }

    // Helper method to bulk query record owners by ID
    private Map<String, String> getRecordOwnersById(Set<String> accountIds, Set<String> opportunityIds, Set<String> contactIds, Set<String> leadIds) {
        Map<String, String> recordOwnersMap = new Map<String, String>();

        // Query Account owners
        if (!accountIds.isEmpty()) {
            for (Account acc : [SELECT Id, Owner.Name FROM Account WHERE Id IN :accountIds]) {
                recordOwnersMap.put(acc.Id, acc.Owner.Name);
            }
        }

        // Query Opportunity owners
        if (!opportunityIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, Owner.Name FROM Opportunity WHERE Id IN :opportunityIds]) {
                recordOwnersMap.put(opp.Id, opp.Owner.Name);
            }
        }

        // Query Contact owners
        if (!contactIds.isEmpty()) {
            for (Contact con : [SELECT Id, Owner.Name FROM Contact WHERE Id IN :contactIds]) {
                recordOwnersMap.put(con.Id, con.Owner.Name);
            }
        }

        // Query Lead owners
        if (!leadIds.isEmpty()) {
            for (Lead lead : [SELECT Id, Owner.Name FROM Lead WHERE Id IN :leadIds]) {
                recordOwnersMap.put(lead.Id, lead.Owner.Name);
            }
        }

        return recordOwnersMap;
    }
}

*/