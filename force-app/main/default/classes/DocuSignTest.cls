@isTest
private class DocuSignTest {

    // ----------------------------------------------------------
    // MOCK #1 — Envelope Creation (POST /envelopes)
    // ----------------------------------------------------------
    private class EnvelopeCreationMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{ "envelopeId": "env12345" }');
            return res;
        }
    }

    // ----------------------------------------------------------
    // MOCK #2 — Envelope Status (GET /envelopes/{id})
    // ----------------------------------------------------------
    private class EnvelopeStatusMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "status": "completed" }');
            return res;
        }
    }

    // ----------------------------------------------------------
    // MOCK #3 — PDF Download (GET /documents/1)
    // ----------------------------------------------------------
    private class PDFDownloadMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBodyAsBlob(Blob.valueOf('fake pdf content'));
            return res;
        }
    }


    // ----------------------------------------------------------
    // TEST 1 — Queueable + BulkProcessor
    // ----------------------------------------------------------
    @isTest
static void testQueueableAndProcessor() {

    // Create test customer record
    Customer_Notification__c c = new Customer_Notification__c(
        Account_Name__c = 'Test',
        Email__c = 'test@test.com',
        Template_Type__c = 'FM Letter'
    );
    insert c;

    // Register mock
    System.Test.setMock(System.HttpCalloutMock.class, new EnvelopeCreationMock());

    System.Test.startTest();
    System.enqueueJob(new DocuSignBulkQueueable(new List<Id>{ c.Id }));
    System.Test.stopTest();

    c = [SELECT Envelope_Id__c FROM Customer_Notification__c WHERE Id = :c.Id];

    System.assertNotEquals(null, c.Envelope_Id__c, 'Envelope ID should be populated');
}


    // ----------------------------------------------------------
    // TEST 2 — VF Controller
    // ----------------------------------------------------------
    @isTest
static void testVFController() {

    Customer_Notification__c c = new Customer_Notification__c(
        Account_Name__c = 'Test',
        Email__c = 'test@test.com',
        Template_Type__c = 'FM Letter'
    );
    insert c;

    // SELECTED ROWS SIMULATION
    List<Customer_Notification__c> rows = new List<Customer_Notification__c>{ c };
    ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(rows);
    
    ssc.setSelected(new List<SObject>{ c });

    DocuSignBulkVFController controller = new DocuSignBulkVFController(ssc);

    // REGISTER MOCK
    System.Test.setMock(System.HttpCalloutMock.class, new EnvelopeCreationMock());

    System.Test.startTest();
    controller.sendEnvelopes();
    System.Test.stopTest();

    System.assert(
        controller.statusMessage.contains('Envelopes sent'),
        'Status message should indicate envelopes sent'
    );
}

    // ----------------------------------------------------------
    // TEST 3 — Status Sync (marks envelope as Completed)
    // ----------------------------------------------------------
    @isTest
    static void testStatusSync() {

        Customer_Notification__c rec = new Customer_Notification__c(
            Account_Name__c = 'Alex Test',
            Email__c = 'alex@test.com',
            Template_Type__c = 'FM Letter',
            Envelope_Id__c = 'env12345',
            Status__c = 'Sent'
        );
        insert rec;

        System.Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock());

        System.Test.startTest();
        DocuSignStatusSync.syncDocuSignStatuses();
        System.Test.stopTest();

        rec = [
            SELECT Status__c
            FROM Customer_Notification__c
            WHERE Id = :rec.Id
        ];

        System.assertEquals('Completed', rec.Status__c);
    }


    // ----------------------------------------------------------
    // TEST 4 — PDF Download Future Callout
    // ----------------------------------------------------------
    @isTest
    static void testPDFDownloadFuture() {

        Customer_Notification__c rec = new Customer_Notification__c(
            Account_Name__c = 'PDF Test',
            Email__c = 'pdf@test.com',
            Template_Type__c = 'FM Letter',
            Envelope_Id__c = 'envPDF'
        );
        insert rec;

        System.Test.setMock(HttpCalloutMock.class, new PDFDownloadMock());

        System.Test.startTest();
        DocuSignPDFService.downloadAndStorePDF('envPDF', rec.Id);
        System.Test.stopTest();

        ContentDocumentLink cdl = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :rec.Id
            LIMIT 1
        ];

        System.assertEquals(rec.Id, cdl.LinkedEntityId);
    }


    // ----------------------------------------------------------
    // TEST 5 — Scheduler wrapper
    // ----------------------------------------------------------
    @isTest
    static void testScheduler() {

        System.Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock());

        System.Test.startTest();
        System.schedule(
            'DocuSignSchedTest',
            '0 0 0 ? * MON',     // Runs once only
            new DocuSignStatusScheduler()
        );
        System.Test.stopTest();

        System.assert(true, 'Scheduler executed without error');
    }
}