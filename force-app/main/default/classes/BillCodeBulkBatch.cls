public class BillCodeBulkBatch implements Database.Batchable<Map<String, Object>>, Database.Stateful {
    private final Id projectId;
    private final List<Map<String, Object>> inputRecords;
    // Add a map for BC_ID__c => milestone fields
    private Map<String, pse__Milestone__c> billCodeIdToMilestone = new Map<String, pse__Milestone__c>();
    private String billingType;
    // Counter for successfully created records
    public Integer numRecordsCreated = 0;

    public BillCodeBulkBatch(Id projectId, List<Map<String, Object>> records) {
        this.projectId = projectId;
        this.inputRecords = records;
    }

    public Iterable<Map<String, Object>> start(Database.BatchableContext bc) {
        // Query the billing type from the project record
        pse__Proj__c proj = [
            SELECT pse__Billing_Type__c
            FROM pse__Proj__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        billingType = proj.pse__Billing_Type__c;
        // Preload all existing SOW Bill Codes with Bill_Code_District_ID__c = null for the project
        for (pse__Milestone__c m : [
            SELECT BC_ID__c, Actual_Cost_Rate__c, Name, Contract_Rate__c, Adjustment__c, Amount_Complete__c
            FROM pse__Milestone__c
            WHERE pse__Project__c = :projectId
            AND Bill_Code_District_ID__c = null
            AND BC_ID__c != null
        ]) {
            billCodeIdToMilestone.put(m.BC_ID__c, m);
        }
        return inputRecords;
    }

    public void execute(Database.BatchableContext bc, List<Map<String, Object>> scope) {
        List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();
        for (Map<String, Object> rec : scope) {
            try {
                pse__Milestone__c ms = new pse__Milestone__c();
                ms.pse__Project__c = projectId;
                ms.pse__Target_Date__c = Date.today();
                ms.pse__Actual_Date__c = Date.today();
                // Set Bundle_Bill_Code__c based on project billing type
                if (billingType == 'Bundle') {
                    ms.Bundle_Bill_Code__c = true;
                } else if (billingType == 'Time and Materials') {
                    ms.Bundle_Bill_Code__c = false;
                }
                if (rec.containsKey('Project_ID__c')) ms.Project_ID__c = (String)rec.get('Project_ID__c');
                if (rec.containsKey('Bill_Code_ID__c')) {
                    String codeId = (String)rec.get('Bill_Code_ID__c');
                    ms.Bill_Code_ID__c = codeId;

                    // Check for BC match and set additional fields
                    if (billCodeIdToMilestone.containsKey(codeId)) {
                        pse__Milestone__c refMilestone = billCodeIdToMilestone.get(codeId);
                        ms.Name = refMilestone.Name;
                        ms.Actual_Cost_Rate__c = refMilestone.Actual_Cost_Rate__c;
                        ms.Contract_Rate__c = refMilestone.Contract_Rate__c;
                        ms.Adjustment__c = refMilestone.Adjustment__c;
                        //ms.pse__Milestone_Amount__c = refMilestone.Amount_Complete__c;
                    }
                }
                if (rec.containsKey('Billing_Code__c')) ms.Billing_Code__c = (String)rec.get('Billing_Code__c');
                if (rec.containsKey('Bill_Code_District_ID__c')) ms.Bill_Code_District_ID__c = (String)rec.get('Bill_Code_District_ID__c');
                if (rec.containsKey('Units_Complete__c')) {
                    Object units = rec.get('Units_Complete__c');
                    if (units != null && String.valueOf(units).trim() != '') {
                        ms.Units_Complete__c = Decimal.valueOf(String.valueOf(units));
                    }
                }
                if (rec.containsKey('Service_Order__c')) ms.Service_Order__c = (String)rec.get('Service_Order__c');
                if (rec.containsKey('Bill_Code_Customer_ID__c')) ms.Bill_Code_Customer_ID__c = (String)rec.get('Bill_Code_Customer_ID__c');
                if (rec.containsKey('Division_ID__c')) ms.Division_ID__c = (String)rec.get('Division_ID__c');
                if (rec.containsKey('Department_ID__c')) ms.Department_ID__c = (String)rec.get('Department_ID__c');
                milestones.add(ms);
            } catch (Exception ex) {
                System.debug('Error parsing record: ' + ex.getMessage());
                if (Test.isRunningTest()) throw ex;
            }
        }

        if (!milestones.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.insert(milestones, false);
                // Count successful inserts
                for (Database.SaveResult result : results) {
                    if (result.isSuccess()) {
                        numRecordsCreated++;
                    } else {
                        // Log errors for failed records
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Insert error: ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception dmlEx) {
                System.debug('Error during insert: ' + dmlEx.getMessage());
                if (Test.isRunningTest()) throw dmlEx;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Get counts
        Integer totalInputCount = inputRecords != null ? inputRecords.size() : 0;
        String message;
        if (numRecordsCreated == totalInputCount) {
                message = 'Upload successful! All ' + totalInputCount + ' records were processed.';
            } else {
                Integer failedCount = totalInputCount - numRecordsCreated;
                message = 'Upload complete. ' + numRecordsCreated + ' records uploaded successfully, ' + failedCount + ' failed.';
            }

        // Query the job to get the batch submitter's user ID
        AsyncApexJob job = [
            SELECT Id, CreatedById 
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];

        // Query your custom notification type by API Name
        CustomNotificationType notifType = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'PSA_BC_Batch_Apex_Completion'
            LIMIT 1
        ];

        // Prepare the custom notification with input and created counts
        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setNotificationTypeId(notifType.Id);
        notif.setTitle('Market Bill Code Creation Job Completed - Success');
        notif.setBody(message);
        notif.setTargetId(projectId); // Use your Project Id for navigation

        // Send the notification to the batch submitter
        try {
            notif.send(new Set<String>{ job.CreatedById });
        } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
    }
}