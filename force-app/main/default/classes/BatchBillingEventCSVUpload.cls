public class BatchBillingEventCSVUpload implements Database.Batchable<sObject>, Database.Stateful {

    // Instance variables
    private Set<Id> allFailedId = new Set<Id>();
    private Set<Id> billingEventItemIds;
    private List<pse__Billing_Event__c> billingEventList;
    private Map<Id, BillingEventRecordUpdateWithCtrl.BillingEventFields> billingEventItemMap;
    private Integer totalInputCount = 0; // Track total input records

    // Constructor to initialize variables and prepare data
    public BatchBillingEventCSVUpload(List<BillingEventRecordUpdateWithCtrl.BillingEventFields> records) {
        billingEventItemIds = new Set<Id>();
        billingEventList = new List<pse__Billing_Event__c>();
        billingEventItemMap = new Map<Id, BillingEventRecordUpdateWithCtrl.BillingEventFields>();
        totalInputCount = records != null ? records.size() : 0;

        for (BillingEventRecordUpdateWithCtrl.BillingEventFields record : records) {
            billingEventItemIds.add(record.billingEventItemID);
            billingEventItemMap.put(record.billingEventItemID, record);
        }
        System.debug('billingEventItemMap' + billingEventItemMap);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, pse__Billing_Event__c, pse__Project__r.pse__Stage__c,
                (SELECT Id, pse__Invoice_Date__c, pse__Invoice_Number__c, pse__Invoiced__c FROM pse__Milestones__r)
            FROM pse__Billing_Event_Item__c
            WHERE Id IN :billingEventItemIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<pse__Billing_Event_Item__c> scope) {
        System.debug('scope ::' + scope[0].pse__Milestones__r);
        try {
            Map<Id, BillingEventRecordUpdateWithCtrl.BillingEventFields> billingEventMap = new Map<Id, BillingEventRecordUpdateWithCtrl.BillingEventFields>();
            // Map<Id, BillingEventRecordUpdateWithCtrl.BillingEventFields> billingCodeEventMap = new Map<Id, BillingEventRecordUpdateWithCtrl.BillingEventFields>(); // COMMENTED

            // Populate billingEventMap
            for (pse__Billing_Event_Item__c itemId : scope) {
                if (itemId.pse__Project__r != null && itemId.pse__Project__r.pse__Stage__c == 'Completed') {
                    System.debug('Skipping record due to Completed project stage: ' + itemId.Id);
                    continue;
                }
                if (billingEventItemMap.containsKey(itemId.Id)) {
                    BillingEventRecordUpdateWithCtrl.BillingEventFields csvData = billingEventItemMap.get(itemId.Id);
                    billingEventMap.put(itemId.pse__Billing_Event__c, csvData);
                    // system.debug('itemId.pse__Milestones__r==' + itemId.pse__Milestones__r); // COMMENTED
                    // for (pse__Milestone__c billcode : itemId.pse__Milestones__r) { // COMMENTED
                    //     billingCodeEventMap.put(billcode.Id, csvData); // COMMENTED
                    // } // COMMENTED
                }
            }

            System.debug('billingEventMap' + billingEventMap.keySet());
            List<pse__Billing_Event__c> billingEvents = [
                SELECT Id, pse__Invoice_Date__c, pse__Invoice_Number__c, pse__Invoiced__c, pse__Status__c
                FROM pse__Billing_Event__c
                WHERE Id IN :billingEventMap.keySet()
            ];
            System.debug('billingEvents::' + billingEvents);

            for (pse__Billing_Event__c record : billingEvents) {
                System.debug('record::' + record);
                BillingEventRecordUpdateWithCtrl.BillingEventFields billEventWrap = billingEventMap.get(record.Id);
                System.debug('billEventWrap::' + billEventWrap);
                String dateValueFormat = billEventWrap.billingEventItemBillingEventInvoiceDate;
                System.debug('dateValueFormat' + dateValueFormat);
                List<String> parts = dateValueFormat.split('-');
                System.debug('parts::' + parts);
                String reformattedDate = parts[0] + '-' + parts[2] + '-' + parts[1];
                Date dateValue = Date.valueOf(reformattedDate);
                system.debug('apex class dateValue==' + dateValue);
                record.pse__Invoice_Date__c = dateValue;
                record.pse__Invoice_Number__c = billEventWrap.billingEventItemBillingEventInvoiceNumber;
                record.pse__Invoiced__c = true;
                record.pse__Status__c = 'Completed';
                billingEventList.add(record);
            }
            System.debug('billingEventList' + billingEventList.size());

            if (!billingEventList.isEmpty()) {
                database.SaveResult[] BE_FailedId = database.update(billingEventList, false);
                for (database.SaveResult s : BE_FailedId) {
                    if (!s.isSuccess()) {
                        allFailedId.add(s.getId());
                        System.debug('fail ' + s.getId());
                    } else {
                        System.debug('success ' + s.getId());
                    }
                }
            }

            // ======= MILESTONE LOGIC FULLY COMMENTED OUT =======
            /*
            List<pse__Milestone__c> billingCodeEvents = [
                SELECT Id, pse__Invoice_Date__c, pse__Invoice_Number__c, pse__Invoiced__c
                FROM pse__Milestone__c
                WHERE Id IN :billingCodeEventMap.keySet()
            ];
            system.debug('billingCodeEvents List===' + billingCodeEvents);
            List<pse__Milestone__c> billingCodeEventList = new List<pse__Milestone__c>();
            for (pse__Milestone__c record : billingCodeEvents) {
                BillingEventRecordUpdateWithCtrl.BillingEventFields billEventWrap = billingCodeEventMap.get(record.Id);
                String dateValueFormat = billEventWrap.billingEventItemBillingEventInvoiceDate;
                List<String> parts = dateValueFormat.split('-');
                String reformattedDate = parts[0] + '-' + parts[2] + '-' + parts[1];
                Date dateValue = Date.valueOf(reformattedDate);
                record.pse__Invoice_Date__c = dateValue;
                record.pse__Invoice_Number__c = billEventWrap.billingEventItemBillingEventInvoiceNumber;
                billingCodeEventList.add(record);
            }
            System.debug('billingCodeEventList' + billingCodeEventList);
            if (!billingCodeEventList.isEmpty()) {
                database.SaveResult[] bcFailedId = database.update(billingCodeEventList, false);
                for (database.SaveResult s : bcFailedId) {
                    if (!s.isSuccess()) {
                        allFailedId.add(s.getId());
                        System.debug('fail ' + s.getId());
                    } else {
                        System.debug('success ' + s.getId());
                    }
                }
                System.debug('allFailedId2 ' + allFailedId);
            }
            */
            System.debug('allFailedId3 ' + allFailedId);

        } catch (DmlException e) {
            System.debug('DmlException ' + e);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('allFailedId ' + allFailedId);
        AsyncApexJob job = [SELECT Id, Status,CreatedById, numberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        if (!allFailedId.isEmpty()) {
            sendFailureEmail(job.Id, job.NumberOfErrors);
        }
        Integer failedCount = allFailedId.size();
        Integer numRecordsCreated = totalInputCount - failedCount;
        String message;
        if (numRecordsCreated == totalInputCount) {
            message = 'All Billing Event Records are Updated !!';
        } else {
            message =  failedCount + 'Billing Event records are failed';
        }

        // Send Custom Notification to current user using targetId
        CustomNotificationType notifType = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'PSA_BC_Batch_Apex_Completion'
            LIMIT 1
        ];
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(notifType.Id);
        notification.setTitle('PSA Billing File Completion');
        notification.setBody(message);
        notification.setTargetId(UserInfo.getUserId()); // Directly set the user’s Id!
          try {
            notification.send(new Set<String>{ job.CreatedById });
        } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }

    }

    // Send the email notificaiton
      
    private void sendFailureEmail(Id jobId, Integer numberOfErrors) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {
            UserInfo.getUserEmail(),
            'im-project-billingfile-uploads.groups@ironmountain.com'
        };
        mail.setToAddresses(toAddresses);
        mail.setSubject('FAILURE: Billing File Upload');
        mail.setPlainTextBody('An IM Project Billing File upload has failed. This upload was submitted by ' +
            UserInfo.getName() + ' ' + allFailedId);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}