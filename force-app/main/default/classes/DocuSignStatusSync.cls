public with sharing class DocuSignStatusSync implements Schedulable, Database.AllowsCallouts {

    public void execute(SchedulableContext sc) {
        syncDocuSignStatuses();
    }

    public static void syncDocuSignStatuses() {
        // Fetch all Customer Notifications with envelopes sent/pending
        List<Customer_Notification__c> pendingRecords = [
            SELECT Id, Name, Envelope_Id__c, Status__c
            FROM Customer_Notification__c
            WHERE Envelope_Id__c != null AND (Status__c = 'Sent' OR Status__c = 'Pending')
        ];

        System.debug(' Found ' + pendingRecords.size() + ' pending DocuSign envelopes.');

        // List to hold completed envelope IDs for PDF fetch
        List<Id> completedRecordIds = new List<Id>();
        List<String> completedEnvelopeIds = new List<String>();

        for (Customer_Notification__c record : pendingRecords) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:DocuSignNC/restapi/v2.1/accounts/a3451c81-ddf7-4976-b230-22c246e126cc/envelopes/' + record.Envelope_Id__c);
                req.setMethod('GET');
                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> envelopeData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    String status = (String) envelopeData.get('status');

                    if (status != null && status.equalsIgnoreCase('completed')) {
                        System.debug('Envelope ' + record.Envelope_Id__c + ' is completed.');

                        // Add to completed list (no callout yet)
                        record.Status__c = 'Completed';
                        completedRecordIds.add(record.Id);
                        completedEnvelopeIds.add(record.Envelope_Id__c);
                    } else {
                        System.debug('Envelope ' + record.Envelope_Id__c + ' is still in status: ' + status);
                    }
                } else {
                    System.debug('Failed to fetch envelope: ' + record.Envelope_Id__c + ' - ' + res.getStatus());
                }

            } catch (Exception e) {
                System.debug('Error processing record ' + record.Id + ': ' + e.getMessage());
            }
        }

        //Perform DML update first (safe)
        if (!completedRecordIds.isEmpty()) {
            List<Customer_Notification__c> toUpdate = [
                SELECT Id, Status__c FROM Customer_Notification__c WHERE Id IN :completedRecordIds
            ];
            for (Customer_Notification__c rec : toUpdate) {
                rec.Status__c = 'Completed';
            }
            update toUpdate;
            System.debug('Updated ' + toUpdate.size() + ' records to Completed.');

            // Then enqueue PDF download as a separate future callout
            for (Integer i = 0; i < completedRecordIds.size(); i++) {
                DocuSignPDFService.downloadAndStorePDF(completedEnvelopeIds[i], completedRecordIds[i]);
            }
        }
    }
}