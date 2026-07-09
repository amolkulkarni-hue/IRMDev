public class BillingEventRecordUpdateWithCtrl {
   @AuraEnabled
    public static void updateBillingEventRecords(List<BillingEventFields> records) {
        System.debug('records '+records);
        Database.Batchable<sObject> bt = new BatchBillingEventCSVUpload(records);
        Database.executeBatch(bt,50);
    }
    
       @AuraEnabled
       public static List<BillingEventFields> billingEventFieldsReturn(){
           List<BillingEventFields> projectFieldRecords = new List<BillingEventFields>();
           BillingEventFields fields = new BillingEventFields ();
    
            fields.billingEventItemID='';
            fields.billingEventItemBillingEventInvoiceNumber='';
            fields.billingEventItemBillingEventInvoiceDate= '';
            projectFieldRecords.add(fields);
            
            return projectFieldRecords;   
       }
    
       public class BillingEventFields {
            @AuraEnabled
            public String billingEventItemID {get; set;}
            @AuraEnabled
            public String billingEventItemBillingEventInvoiceNumber {get; set;}
            @AuraEnabled
            public String billingEventItemBillingEventInvoiceDate {get; set;}
            @AuraEnabled
            public String projectid {get; set;}            
        }
    }