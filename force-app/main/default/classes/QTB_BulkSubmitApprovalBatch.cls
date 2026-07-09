global class QTB_BulkSubmitApprovalBatch  implements Database.Batchable<sObject> {
    public set<id> quoteforbulkApproval = new set<id>();
    public QTB_BulkSubmitApprovalBatch(set<ID> quoteSet){
        quoteforbulkApproval = quoteSet;
    }
    global database.QueryLocator start(Database.BatchableContext bc) {
       string query = 'select id from SBQQ__Quote__c where id IN :quoteforbulkApproval';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> scope){
        for(SBQQ__Quote__c eachQuote: scope){
            QTB_QuoteHelper.skipFromBOBBulkApprovals = false;
            sbaa.ApprovalAPI.submit(eachQuote.id, sbaa__Approval__c.QTB_Quote__c);
        }
         
    }
    global void finish(Database.BatchableContext bc){
         
    }
    
    

}