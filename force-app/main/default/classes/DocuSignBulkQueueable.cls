public class DocuSignBulkQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> recordIds;

    public DocuSignBulkQueueable(List<Id> recordIds) {
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext ctx) {
        System.debug('DocuSignBulkQueueable starting for: ' + recordIds);

        // Step 1: send envelopes and get processed Ids
        List<Id> processedIds = DocuSignBulkProcessor.process(recordIds);

        // Step 2: do not attempt to fetch PDFs here — PDFs are only available after completion.
        // The scheduled sync will pick up completed envelopes and call DocuSignPDFService.saveCompletedPDF.

        System.debug('DocuSignBulkQueueable finished. processedIds:' + processedIds);
    }
}