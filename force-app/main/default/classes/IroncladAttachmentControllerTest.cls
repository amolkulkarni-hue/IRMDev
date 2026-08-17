@isTest
private class IroncladAttachmentControllerTest {

    // Mock that simulates Ironclad returning a 200 success response
    private class IroncladCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assert(req.getEndpoint().contains('/documents/'), 'Endpoint should target the documents API');
            System.assertEquals('POST', req.getMethod());
            System.assert(req.getHeader('Content-Type').startsWith('multipart/form-data'), 'Should be multipart');

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock that simulates a 409 / INVALID_STATE response (workflow not in Review)
    private class IroncladCalloutMockInvalidState implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "INVALID_STATE"}');
            res.setStatusCode(409);
            return res;
        }
    }

    // Mock that simulates a duplicate-filename rejection
    private class IroncladCalloutMockDuplicate implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Cannot upload multiple files with the same name"}');
            res.setStatusCode(400);
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
    	insert testCountry;
    	insert new IM_Alternative_Country_Name__c(
        IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
    	);
    	insert new Country_Settings__c(
        Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId()
        );
    	insert new List<Opportunity_Security__c>{
        new Opportunity_Security__c(Name = 'Primary CDE', Field_Name__c = 'Primary_CDE__c', Object_Name__c = 'Account', Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
        new Opportunity_Security__c(Name = 'Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
        new Opportunity_Security__c(Name = 'Primary BDE', Field_Name__c = 'Primary_BDE__c', Object_Name__c = 'Account', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
   		};
    	insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct', Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');
        
       Account testAccount = new Account();
            testAccount.Name = 'Test Account';
            testAccount.BillingCountry = 'United States';
            testAccount.BillingPostalCode = '11209';
            testAccount.BillingState = 'NY';
            testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert testAccount;
        
	   Opportunity testOpportunity = new Opportunity();
         
         testOpportunity.CloseDate = Date.today();
         testOpportunity.StageName='0 - Pre-Qualification';
         testOpportunity.AccountId = testAccount.Id;
         testOpportunity.Lead_Source_Most_Recent__c = 'Email';
         testOpportunity.IME_Reason_Won__c = 'Price';
         testOpportunity.Name = 'testOpp';
         
         Insert testOpportunity;

        // Simulated blob content - stands in for a real file (PDF/DOCX/etc.) sent to Ironclad
        Blob fakeFileBody = Blob.valueOf('%PDF-1.4 simulated binary content for test upload purposes only');

		ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = fakeFileBody,
            IsMajorVersion = true
        );
		insert cv;
        
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
		ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = contentDocId,
        LinkedEntityId = testOpportunity.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    	);
        insert cdl;
      
    }

  

    @isTest
    static void testUploadAttachments_Success() {
        Test.setMock(HttpCalloutMock.class, new IroncladCalloutMock());

        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        List<Id> cvIds = new List<Id>{ cv.Id };

        Test.startTest();
        String result = IroncladAttachmentController.uploadAttachments('wf-123', 'attr-456', cvIds);
        Test.stopTest();

        System.assertEquals('Success', result, 'Expected Success string when Ironclad returns HTTP 200');
    }

    @isTest
    static void testUploadAttachments_InvalidState() {
        Test.setMock(HttpCalloutMock.class, new IroncladCalloutMockInvalidState());

        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        List<Id> cvIds = new List<Id>{ cv.Id };

        Test.startTest();
        String result = IroncladAttachmentController.uploadAttachments('wf-123', 'attr-456', cvIds);
        Test.stopTest();

        System.assert(
            result.contains('Review stage'),
            'Expected the INVALID_STATE branch to produce a Review-stage error message'
        );
    }

    @isTest
    static void testUploadAttachments_DuplicateFile() {
        Test.setMock(HttpCalloutMock.class, new IroncladCalloutMockDuplicate());

        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        List<Id> cvIds = new List<Id>{ cv.Id };

        Test.startTest();
        String result = IroncladAttachmentController.uploadAttachments('wf-123', 'attr-456', cvIds);
        Test.stopTest();

        System.assert(
            result.contains('already exists in this workflow'),
            'Expected the duplicate-file branch to fire'
        );
    }
    
    @isTest
    static void testGetDocuments(){
        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        IroncladAttachmentController.getOpportunityFiles(oppty.Id);
    }
}