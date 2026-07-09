@isTest
private class GSCBusinessCaseAgeTest {
    
    // Test method to verify the calculateBusinessCaseAge method
    @isTest
    static void testCalculateBusinessCaseAge() {
        // Create a test Contact record
       Contact testContact = new Contact(
               FirstName = 'Test',
               LastName = 'Test Contact'
                 );
           insert testContact;
        // Test case 1: Closed case with valid data
        BusinessHours defaultBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        System.assertNotEquals(null, defaultBusinessHours, 'Default Business Hours record not found');

        Case testCase1 = new Case(
            Subject = 'Test Case 1',
            CreatedDate = DateTime.now().addDays(-5),
            ClosedDate = DateTime.now(),
            Country__c = 'Poland',
            ContactId = testContact.Id
        );
        insert testCase1;

        List<GSCBusinessCaseAge.DataWrapper> testData1 = new List<GSCBusinessCaseAge.DataWrapper>{
            new GSCBusinessCaseAge.DataWrapper()
        };
        testData1[0].createdDate = testCase1.CreatedDate;
        testData1[0].closedDate = testCase1.ClosedDate;
        testData1[0].country = testCase1.Country__c;
        testData1[0].recordId = testCase1.Id;

        // Test case 2: Open case (closedDate is null)
        Case testCase2 = new Case(
            Subject = 'Test Case 2',
            CreatedDate = DateTime.now().addDays(-5),
            Country__c = 'TestCountry',
            
            ContactId = testContact.Id
        );
        insert testCase2;

        List<GSCBusinessCaseAge.DataWrapper> testData2 = new List<GSCBusinessCaseAge.DataWrapper>{
            new GSCBusinessCaseAge.DataWrapper()
        };
        testData2[0].createdDate = testCase2.CreatedDate;
        testData2[0].country = testCase2.Country__c;
        testData2[0].recordId = testCase2.Id;


        // Test case 3: Add a scenario where dw.country is null
        Case testCase3 = new Case(
            Subject = 'Test Case 3',
            CreatedDate = DateTime.now().addDays(-5),
            ClosedDate = DateTime.now(),
            ContactId = testContact.Id
        );
        insert testCase3;

        List<GSCBusinessCaseAge.DataWrapper> testData3 = new List<GSCBusinessCaseAge.DataWrapper>{
            new GSCBusinessCaseAge.DataWrapper()
        };
        testData3[0].createdDate = testCase3.CreatedDate;
        testData3[0].closedDate = testCase3.ClosedDate;
        testData3[0].recordId = testCase3.Id;
        
    

 
       // Query an existing Case record ID
       Case existingCase = [SELECT Id FROM Case LIMIT 1];

          // Create a new DataWrapper object
        GSCBusinessCaseAge.DataWrapper testData = new GSCBusinessCaseAge.DataWrapper();
        testData.createdDate = DateTime.now();
        testData.closedDate = DateTime.now();
        testData.recordId = existingCase.Id; // Use the existing Case record ID

        
        List<GSCBusinessCaseAge.DataWrapper> testDataList = new List<GSCBusinessCaseAge.DataWrapper>{ testData }; 


        Test.startTest();
        GSCBusinessCaseAge.calculateBusinessCaseAge(testData1);
        GSCBusinessCaseAge.calculateBusinessCaseAge(testData2);
        GSCBusinessCaseAge.calculateBusinessCaseAge(testData3);
        GSCBusinessCaseAge.calculateBusinessCaseAge(testDataList);
        Test.stopTest();
        
        Case updatedCase1 = [SELECT Business_Case_Age__c FROM Case WHERE Id = :testCase1.Id];
        System.assertEquals(0, updatedCase1.Business_Case_Age__c, 'Test Case 1: Business Case Age not calculated correctly');
        
        Case updatedCase2 = [SELECT Business_Case_Age__c FROM Case WHERE Id = :testCase2.Id];
        System.assertEquals(null, updatedCase2.Business_Case_Age__c, 'Test Case 2: Business Case Age should be null');
        
        Case updatedCase3 = [SELECT Business_Case_Age__c FROM Case WHERE Id = :testCase3.Id];
   //     System.assertEquals(13.333333333333334, updatedCase3.Business_Case_Age__c, 'Test Case 3: Business Case Age should be null');

       
    }
}