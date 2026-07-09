public with sharing class BillCodeSelectionController {
    @AuraEnabled(cacheable=true)
    public static List<pse__milestone__c> getBillCodes(Id projectId) {
        // Query the project's Billing Type
        pse__proj__c project = [
            SELECT Id, pse__Billing_Type__c,CurrencyIsoCode
            FROM pse__proj__c
            WHERE Id = :projectId
            LIMIT 1
        ];

        if (project == null) {
            throw new AuraHandledException('Project not found.');
        }

        // Initialize billCodes list
        List<pse__milestone__c> billCodes = new List<pse__milestone__c>();

        // Handle different Billing Types
        if (project.pse__Billing_Type__c == 'Time and Materials') {
            // Fetch all bill codes for Itemized billing
            billCodes = [
                SELECT Id, Name, BC_ID__c, Bill_Code_Rate__c, Billing_Code__c, Last_WIP_Update__c,
                Actual_Cost_Rate__c,CurrencyIsoCode,pse__Project__c
                FROM pse__milestone__c
                WHERE pse__Project__c = :projectId AND Bill_Code_Rate__c != NULL
            ];
        }  
        else if (project.pse__Billing_Type__c == 'Outcome') {
            // Fetch only child bill codes where Parent_Bill_Code__c is not null
            billCodes = [
                SELECT Id, Name, BC_ID__c, Bill_Code_Rate__c, Billing_Code__c, Last_WIP_Update__c,
                Parent_Bill_Code__c,Actual_Cost_Rate__c,CurrencyIsoCode,pse__Project__c,Bundle_Bill_Code__c
                FROM pse__milestone__c
                WHERE pse__Project__c = :projectId 
                AND Bundle_Bill_Code__c = False
                AND Bill_Code_Rate__c != NULL
            ];
        } 
        else if (project.pse__Billing_Type__c =='Bundle') {
            // Fetch only child bill codes where Parent_Bill_Code__c is not null
            billCodes = [
                SELECT Id, Name, BC_ID__c, Bill_Code_Rate__c, Billing_Code__c, Last_WIP_Update__c,Billing_Generated__c,
                Parent_Bill_Code__c,Actual_Cost_Rate__c,CurrencyIsoCode,pse__Project__c, Units_Complete__c,Bundle_Bill_Code__c
                FROM pse__milestone__c
                WHERE pse__Project__c = :projectId 
                AND Bundle_Bill_Code__c = False
                AND Bill_Code_District_ID__c = NULL
            ];
        }
        else {
            throw new AuraHandledException('Unsupported Billing Type: ' + project.pse__Billing_Type__c);
        }
        return billCodes;
    }

    @AuraEnabled
    public static String createPreBillRecords(List<WIP_Units_Complete__c> records) {
        if (records == null || records.isEmpty()) {
            throw new AuraHandledException('No records to insert.');
        }
        try {
            Set<Id> billCodeIds = new Set<Id>();
            for (WIP_Units_Complete__c record : records) {
                if (record.BillCode_Name__c != null) {
                    billCodeIds.add(record.BillCode_Name__c);
                }
            }
            //Query Bill Code records with Actual_Cost_Rate__c
            Map<Id, Decimal> billCodeToActualRateMap = new Map<Id, Decimal>();
            Map<Id, String> billCodeToCurrencyMap = new Map<Id, String>();
            for (pse__milestone__c billCode : [
                SELECT Id, Actual_Cost_Rate__c, pse__Project__r.CurrencyIsoCode, CurrencyIsoCode,pse__Project__c
                FROM pse__milestone__c
                WHERE Id IN :billCodeIds
            ]) {
                billCodeToCurrencyMap.put(billCode.Id, billCode.pse__Project__r.CurrencyIsoCode);
                billCodeToActualRateMap.put(billCode.Id, billCode.Actual_Cost_Rate__c);
            }
            for (WIP_Units_Complete__c record : records) {
                if (record.BillCode_Name__c != null && billCodeToActualRateMap.containsKey(record.BillCode_Name__c)) {
                    record.Actual_Cost_Rate__c = billCodeToActualRateMap.get(record.BillCode_Name__c);
                    record.CurrencyIsoCode = billCodeToCurrencyMap.get(record.BillCode_Name__c);
                }
            }
            insert records;
            updateLastPreBillDate(records);
            updateProjectWIPAmount(records);
            return 'Records inserted and Project WIP updated successfully'; 
        } catch (Exception e) {
            throw new AuraHandledException('Error inserting records: ' + e.getMessage());
        }
    }

    // Update the last Pre-Bill update date on BillCode_Name__c
    private static void updateLastPreBillDate(List<WIP_Units_Complete__c> records) {
        system.debug('updateLastPreBillDate>>>');
        Set<Id> billCodeIds = new Set<Id>();

        // Collect Bill Code Ids from inserted Pre-Bill Management records
        for (WIP_Units_Complete__c record : records) {
            if (record.BillCode_Name__c != null) {
                billCodeIds.add(record.BillCode_Name__c);
            }
        }

        if (billCodeIds.isEmpty()) {
            return;
        }

        // Query latest LastModifiedDate for each Bill Code
        Map<Id, DateTime> billCodeToLastModifiedMap = new Map<Id, DateTime>();
        List<AggregateResult> results = [
            SELECT BillCode_Name__c Id, MAX(Date_Completed__c) lastModified
            FROM WIP_Units_Complete__c
            WHERE BillCode_Name__c IN :billCodeIds
            GROUP BY BillCode_Name__c
        ];

        for (AggregateResult result : results) {
            billCodeToLastModifiedMap.put((Id) result.get('Id'), (DateTime) result.get('lastModified'));
        }

        // Update BillCode_Name__c records with the latest LastModifiedDate
        List<pse__milestone__c> billCodesToUpdate = new List<pse__milestone__c>();
        for (pse__milestone__c billCode : [
            SELECT Id, Last_WIP_Update__c,CurrencyIsoCode,pse__Project__c
            FROM pse__milestone__c
            WHERE Id IN :billCodeIds
        ]) {
            if (billCodeToLastModifiedMap.containsKey(billCode.Id)) {
                billCode.Last_WIP_Update__c = billCodeToLastModifiedMap.get(billCode.Id);
                billCodesToUpdate.add(billCode);
            }
        }

        if (!billCodesToUpdate.isEmpty()) {
            update billCodesToUpdate;
        }
    }

    public class WIPInputWrapper {
        @InvocableVariable(required=true)
        public Id wipRecordId;
    }
    @InvocableMethod(label='Update Project WIP Amounts from WIP Records')
    public static void updateProjectWIPFromFlow(List<WIPInputWrapper> inputList) {
        if (inputList == null || inputList.isEmpty()) {
            return;
        }

        Set<Id> recordIds = new Set<Id>();
        for (WIPInputWrapper input : inputList) {
            if (input.wipRecordId != null) {
                recordIds.add(input.wipRecordId);
            }
        }

        // Query actual records
        List<WIP_Units_Complete__c> records = [
            SELECT Id, SOW_Rate__c, WIP_Completed_Units__c, Date_Completed__c,
                BillCode_Name__r.Bundle_Bill_Code__c, BillCode__c, BillCode_Name__c,
                Project__c, Actual_Cost_Rate__c, Project__r.pse__Billing_Type__c
            FROM WIP_Units_Complete__c
            WHERE Id IN :recordIds
        ];

        updateProjectWIPAmount(records); // call your original method
    }
    
    private static void updateProjectWIPAmount(List<WIP_Units_Complete__c> records) {
        system.debug('====> Entering updateProjectWIPAmount Method');

        Set<Id> projectIds = new Set<Id>();

        // Ensure records contain related Project__c field
        Set<Id> preBillIds = new Set<Id>();
        for (WIP_Units_Complete__c rec : records) {
            preBillIds.add(rec.Id);
        }

        // Query the records again to ensure relationships are included
        List<WIP_Units_Complete__c> preBillRecordsWithProject = [
            SELECT Id, SOW_Rate__c, WIP_Completed_Units__c, Date_Completed__c,BillCode_Name__r.Bundle_Bill_Code__c,
                BillCode__c,BillCode_Name__c, Project__c, Actual_Cost_Rate__c
            FROM WIP_Units_Complete__c
            WHERE Id IN :preBillIds
        ];

        system.debug('====> Total Pre-Bill Records Passed: ' + records.size());
        system.debug('====> Total Pre-Bill Records Retrieved with Project Data: ' + preBillRecordsWithProject.size());

        // Collect unique Project IDs
        for (WIP_Units_Complete__c objPreBill : preBillRecordsWithProject) {
            if (objPreBill.BillCode_Name__r != null && objPreBill.Project__c != null) {
                projectIds.add(objPreBill.Project__c);
                system.debug('====> Found Project ID: ' + objPreBill.Project__c);
            } else {
                system.debug('Skipping Pre-Bill Record due to missing Project reference: ' + objPreBill);
            }
        }

        system.debug('====> Identified Project IDs: ' + projectIds);

        if (projectIds.isEmpty()) {
            system.debug('====> No Projects found. Exiting updateProjectWIPAmount.');
            return;
        }

        // Query all Pre-Bill Management records related to these Projects
        List<WIP_Units_Complete__c> preBillRecords = [
            SELECT Id, SOW_Rate__c, WIP_Completed_Units__c, BillCode_Name__r.Bundle_Bill_Code__c,
            Project__c,Date_Completed__c,Actual_Cost_Rate__c,Project__r.pse__Billing_Type__c
            FROM WIP_Units_Complete__c
            WHERE Project__c IN :projectIds
        ];

        system.debug('====> Total Pre-Bill Records Fetched: ' + preBillRecords.size());

        Map<Id, Decimal> projectToWIPAmount = new Map<Id, Decimal>();

        // Aggregate WIP Amount for each Project
        for (WIP_Units_Complete__c record : preBillRecords) {
            if (record.BillCode_Name__r == null || record.Project__c == null) {
                system.debug('Skipping record due to null Project reference: ' + record);
                continue;
            }

            if (record.Project__r.pse__Billing_Type__c =='Bundle' && record.BillCode_Name__r.Bundle_Bill_Code__c == false){
                continue;
            }

            Id projectId = record.Project__c;
            Decimal totalWIP = (record.SOW_Rate__c != null ? record.SOW_Rate__c : 0) * 
                            (record.WIP_Completed_Units__c != null ? record.WIP_Completed_Units__c : 0);

            system.debug('====> Processing Record: ' + record);
            system.debug('====> Project: ' + projectId + ', WIP Contribution: ' + totalWIP);

            if (projectToWIPAmount.containsKey(projectId)) {
                projectToWIPAmount.put(projectId, projectToWIPAmount.get(projectId) + totalWIP);
            } else {
                projectToWIPAmount.put(projectId, totalWIP);
            }
        }

        system.debug('====> Calculated WIP Amount per Project: ' + projectToWIPAmount);

        // Query Projects and update WIP_Amount_Remaining__c
        List<pse__proj__c> projectsToUpdate = new List<pse__proj__c>();

        for (pse__proj__c project : [
            SELECT Id, pse__Bookings__c, WIP_Amount_Remaining__c
            FROM pse__proj__c
            WHERE Id IN :projectIds
        ]) {
            system.debug('====> Retrieved Project for Update: ' + project.Id);

            if (projectToWIPAmount.containsKey(project.Id)) {
                Decimal totalWIP = projectToWIPAmount.get(project.Id);
                project.WIP_Amount_Remaining__c = (project.pse__Bookings__c != null ? project.pse__Bookings__c : 0) - totalWIP;

                system.debug('====> Updating Project: ' + project.Id + ', New WIP_Amount_Remaining: ' + project.WIP_Amount_Remaining__c);

                projectsToUpdate.add(project);
            }
        }

        if (!projectsToUpdate.isEmpty()) {
            update projectsToUpdate;
            system.debug('====> Updated Projects WIP successfully.');
        } else {
            system.debug('====> No Projects needed updating.');
        }

        system.debug('====> Exiting updateProjectWIPAmount Method');
    }

    //Delete record code
    public static void handleNonBillableDeletion(List<WIP_Units_Complete__c> deletedRecords) {
        if (deletedRecords == null || deletedRecords.isEmpty()) {
            System.debug('No deleted WIP_Units_Complete__c records to process.');
            return;
        }

        // Step 1: Collect Bill Code IDs from deleted records
        Set<Id> billCodeIds = new Set<Id>();
        for (WIP_Units_Complete__c record : deletedRecords) {
            if (record.BillCode_Name__c != null) {
                billCodeIds.add(record.BillCode_Name__c);
            }
        }

        if (billCodeIds.isEmpty()) {
            System.debug('No valid Bill Code references found in deleted records.');
            return;
        }

        // Step 2: Query Bill Codes and their related Projects
        Map<Id, pse__milestone__c> billCodeMap = new Map<Id, pse__milestone__c>(
            [SELECT Id, PreBill_Unit_Complete_Cost__c, pse__Project__c,Bundle_Bill_Code__c
            FROM pse__milestone__c
            WHERE Id IN :billCodeIds]
        );

        Set<Id> projectIds = new Set<Id>();
        for (pse__milestone__c billCode : billCodeMap.values()) {
            if (billCode.pse__Project__c != null) {
                projectIds.add(billCode.pse__Project__c);
            }
        }

        Map<Id, pse__proj__c> projectMap = new Map<Id, pse__proj__c>(
            [SELECT Id, WIP_Amount_Remaining__c, pse__Bookings__c,pse__Billing_Type__c
            FROM pse__proj__c
            WHERE Id IN :projectIds]
        );

        // Step 3: Aggregate WIP and Completed Cost to restore
        Map<Id, Decimal> projectToWIPRestore = new Map<Id, Decimal>();
        Map<Id, Decimal> billCodeToCostRestore = new Map<Id, Decimal>();

        for (WIP_Units_Complete__c record : deletedRecords) {
            Id billCodeId = record.BillCode_Name__c;
            if (billCodeId == null || !billCodeMap.containsKey(billCodeId)) continue;

            pse__milestone__c billCode = billCodeMap.get(billCodeId);
            Id projectId = billCode.pse__Project__c;
            
            Boolean skipWIPUpdate = false;
            if (projectMap.containsKey(projectId)) {
                String billingType = projectMap.get(projectId).pse__Billing_Type__c;
                if (billingType == 'Bundle' && billCode.Bundle_Bill_Code__c == false) {
                    skipWIPUpdate = true; // Skip WIP update, but not cost update
                }
            }

            Decimal units = record.WIP_Completed_Units__c != null ? record.WIP_Completed_Units__c : 0;
            Decimal sowRate = record.SOW_Rate__c != null ? record.SOW_Rate__c : 0;
            Decimal completedCost = record.Bill_Code_Completed_Cost__c != null ? record.Bill_Code_Completed_Cost__c : 0;

            Decimal wipAmount = sowRate * units;

            // Aggregate for Project
            if (!skipWIPUpdate && projectId != null) {
                Decimal existingWIP = projectToWIPRestore.containsKey(projectId) ? projectToWIPRestore.get(projectId) : 0;
                projectToWIPRestore.put(projectId, existingWIP + wipAmount);
            }

            // Aggregate for Bill Code
            Decimal existingCost = billCodeToCostRestore.containsKey(billCodeId) ? billCodeToCostRestore.get(billCodeId) : 0;
            billCodeToCostRestore.put(billCodeId, existingCost + completedCost);


            System.debug('Processed Deleted Record: ' + record.Id +
                        ' | Units: ' + units +
                        ' | SOW Rate: ' + sowRate +
                        ' | WIP Amount: ' + wipAmount +
                        ' | Completed Cost: ' + completedCost);
        }

        // Step 4: Update Projects
        List<pse__proj__c> projectsToUpdate = new List<pse__proj__c>();
        for (Id projectId : projectToWIPRestore.keySet()) {
            if (projectMap.containsKey(projectId)) {
                pse__proj__c project = projectMap.get(projectId);
                Decimal currentWIP = project.WIP_Amount_Remaining__c != null ? project.WIP_Amount_Remaining__c : 0;
                Decimal updatedWIP = currentWIP + projectToWIPRestore.get(projectId);
                project.WIP_Amount_Remaining__c = updatedWIP;

                System.debug('Updating Project ' + projectId +
                            ' | WIP from ' + currentWIP +
                            ' to ' + updatedWIP);
                projectsToUpdate.add(project);
            }
        }

        // Step 5: Update Bill Codes
        List<pse__milestone__c> billCodesToUpdate = new List<pse__milestone__c>();
        for (Id billCodeId : billCodeToCostRestore.keySet()) {
            if (billCodeMap.containsKey(billCodeId)) {
                pse__milestone__c billCode = billCodeMap.get(billCodeId);
                Decimal currentCost = billCode.PreBill_Unit_Complete_Cost__c != null ? billCode.PreBill_Unit_Complete_Cost__c : 0;
                Decimal updatedCost = currentCost - billCodeToCostRestore.get(billCodeId);
                billCode.PreBill_Unit_Complete_Cost__c = updatedCost;

                System.debug('Updating Bill Code ' + billCodeId +
                            ' | PreBill_Unit_Complete_Cost__c from ' + currentCost +
                            ' to ' + updatedCost);
                billCodesToUpdate.add(billCode);
            }
        }

        // Step 6: Perform DML
        if (!projectsToUpdate.isEmpty()) {
            update projectsToUpdate;
            System.debug('Updated Projects: ' + projectsToUpdate);
        }

        if (!billCodesToUpdate.isEmpty()) {
            update billCodesToUpdate;
            System.debug('Updated Bill Codes: ' + billCodesToUpdate);
        }
    }
}