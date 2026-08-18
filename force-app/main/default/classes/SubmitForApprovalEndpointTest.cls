@isTest
private class SubmitForApprovalEndpointTest {

    @testSetup
    static void setupTestData() {
        // --- BYPASS THE ACCOUNT TRIGGER ---
        // This prevents AccountHelper OpportunityHelper and the Country Validation from firing during the test
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;



        // Query the Profile
        Profile im_sales_Profile = [SELECT Id FROM Profile WHERE Name = 'IM_Sales' LIMIT 1];
        
        // Create the Test User
        User IM_Sales_User = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Alias = 'tadmin',
            Email = 'testadmin_' + DateTime.now().getTime() + '@example.com',
            Username = 'testadmin_' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = im_sales_Profile.Id,
            Country = 'United States'
        );

        insert IM_Sales_User;


        List<PermissionSetGroup> psgList = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Sales_Operations_Business_Partner_PSG' LIMIT 1];
        
        if (!psgList.isEmpty()) {
            PermissionSetAssignment psgAssignment = new PermissionSetAssignment(
                AssigneeId = IM_Sales_User.Id,
                PermissionSetGroupId = psgList[0].Id 
            );
            insert psgAssignment;
            
 
            Test.calculatePermissionSetGroup(psgList[0].Id); 
        }

        //Query the Permission Set from 
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Logik_Custom_CPQ_PS' LIMIT 1];
        
        //Assign the Permission Set to the newly created User
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = IM_Sales_User.Id,
            PermissionSetId = ps.Id
        );
        insert psa;


        System.runAs(IM_Sales_User) {
            
        // 1. Create a Test Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // 2. Get the Standard Pricebook ID for the test context
        Id standardPricebookId = Test.getStandardPricebookId();

        IM_Country__c imContry = new  IM_Country__c(
        Name = 'United States',
        Originating_Org__c = 'Core',
        Region__c = 'North America',
        CurrencyIsoCode = 'USD',
        Active__c = true
        );

        insert imContry;


        Schema.DescribeFieldResult fieldResult = Opportunity.Primary_Product_Line__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        String validProductLine = ple[0].getValue();

        // 3. Create a Test Opportunity and associate the Pricebook
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAcc.Id,
            Pricebook2Id = standardPricebookId,
            StageName = '1 - Qualification',
            CloseDate = System.today().addDays(30),
            Primary_Product_Line__c = validProductLine,
            //Primary_Product_Line__c = 'SITAD',
            Billing_Country__c = imContry.id,
            Bypass_Validation__c = true
        );
        insert testOpp;

        // 4. Create the Logik Transaction with all required relationship fields
        LGK__Transaction__c testTrans = new LGK__Transaction__c(
            LGK__AccountId__c = testAcc.Id,
            LGK__OpportunityId__c = testOpp.Id,
            LGK__Pricebook2Id__c = standardPricebookId
        );
        insert testTrans;
        }
    }

    /*@isTest
    static void testGenerateDealReviewRecordsSuccess() {
        // Fetch the test records created in the setup phase
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        LGK__Transaction__c trans = [SELECT Id FROM LGK__Transaction__c LIMIT 1];

        // Construct the payload matching what the endpoint expects
        Map<String, Object> jsonMap = new Map<String, Object>{
            'opportunityId' => opp.Id,
            'accountId' => acc.Id,
            'transactionId' => trans.Id,
            'ACV' => '50000',
            'cashviewMargin' => '12.5'
        };

        // Configure the REST context to simulate an incoming HTTP POST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/submitForApproval/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(jsonMap));
        
        RestContext.request = req;
        RestContext.response = res;

        // Invoke the endpoint method
        Test.startTest();
        Map<String, String> response = SubmitForApprovalEndpoint.generateDealReviewRecords();
        Test.stopTest();

        // System Assertions to verify behavioral accuracy
        System.assertNotEquals(null, response, 'The response structure should not be null.');
        System.assert(response.containsKey('dealReviewId'), 'The response map must contain the dealReviewId.');
        
        Id dealReviewId = (Id) response.get('dealReviewId');
        
        // Assert that Deal_Review__c was correctly generated and values parsed
        Deal_Review__c createdReview = [SELECT Id, ACV_Annual_Contract_Value__c, Total_Cashview_Margin_Percent__c 
                                        FROM Deal_Review__c 
                                        WHERE Id = :dealReviewId];
                                        
        System.assertEquals(50000, createdReview.ACV_Annual_Contract_Value__c, 'ACV numeric parsing failed.');
        System.assertEquals(12.5, createdReview.Total_Cashview_Margin_Percent__c, 'Cashview Margin numeric parsing failed.');

        // Assert that the transaction record was successfully updated with the reference
        LGK__Transaction__c updatedTrans = [SELECT Id, Deal_Review__c FROM LGK__Transaction__c WHERE Id = :trans.Id];
        System.assertEquals(dealReviewId, updatedTrans.Deal_Review__c, 'Transaction failed to establish lookup relation with the Deal Review.');
    }*/

    @isTest
    static void testGenerateDealReviewRecordsWithFallbackValues() {

        User IM_Sales_User = [SELECT Id FROM User WHERE Alias = 'tadmin' LIMIT 1];

        System.runAs(IM_Sales_User) {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        LGK__Transaction__c trans = [SELECT Id FROM LGK__Transaction__c LIMIT 1];

        // Simulate fallback payload logic (blank and 'undefined' string variables)
        Map<String, Object> jsonMap = new Map<String, Object>{
            'opportunityId' => opp.Id,
            'accountId' => acc.Id,
            'transactionId' => trans.Id,
            'ACV' => 'undefined',
            'cashviewMargin' => ''
        };

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/submitForApproval/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(jsonMap));
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        Map<String, String> response = SubmitForApprovalEndpoint.generateDealReviewRecords();
        Test.stopTest();

        // Verify that the endpoint handled fallback conditions gracefully by setting defaults to 1
        Id dealReviewId = (Id) response.get('dealReviewId');
        Deal_Review__c createdReview = [SELECT Id, ACV_Annual_Contract_Value__c, Total_Cashview_Margin_Percent__c 
                                        FROM Deal_Review__c 
                                        WHERE Id = :dealReviewId];
                                        
        System.assertEquals(1, createdReview.ACV_Annual_Contract_Value__c, 'ACV should default to fallback value 1.');
        System.assertEquals(1, createdReview.Total_Cashview_Margin_Percent__c, 'Cashview Margin should default to fallback value 1.');
    }
    }
}