public with sharing class DocuSignBulkVFController {
    public String statusMessage { get; set; }
    public List<Customer_Notification__c> selectedRecords { get; set; }

    // Constructor: automatically gets selected records from List Button
    public DocuSignBulkVFController(ApexPages.StandardSetController controller) {
        selectedRecords = (List<Customer_Notification__c>) controller.getSelected();
        System.debug('Selected Records: ' + selectedRecords);
    }

    // Action to send envelopes
    public PageReference sendEnvelopes() {
        if (selectedRecords == null || selectedRecords.isEmpty()) {
            statusMessage = 'No customer records selected.';
            return null;
        }

        List<Id> ids = new List<Id>();
        for (Customer_Notification__c rec : selectedRecords) {
            ids.add(rec.Id);
        }

        // Queue the job for DocuSign sending
        System.enqueueJob(new DocuSignBulkQueueable(ids));

        statusMessage = 'Envelopes sent for ' + ids.size() + ' records.';
        System.debug('Enqueued envelopes for IDs: ' + ids);
        return null;
    }

    // Optional cancel action
    public PageReference cancel() {
        return new PageReference('/' + Schema.SObjectType.Customer_Notification__c.getKeyPrefix());
    }
}