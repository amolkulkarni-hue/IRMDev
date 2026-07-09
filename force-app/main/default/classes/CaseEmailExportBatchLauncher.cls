public with sharing class CaseEmailExportBatchLauncher {
    @AuraEnabled
    public static void startExportBatch() {
        CaseEmailExportBatch batch = new CaseEmailExportBatch();
        Database.executeBatch(batch, 2000);
    }
}