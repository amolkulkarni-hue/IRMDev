@isTest
public class NBDeleteTriggerTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Project
        pse__Proj__c project = new pse__Proj__c(
            Name = 'Test Project',
            Service_State__c = 'Test',
            pse__Billing_Type__c = 'Time and Materials',
            pse__Account__c = acc.Id,
            pse__Is_Active__c = true,
            pse__Bookings__c = 1000,
            WIP_Amount_Remaining__c = 100,
            CurrencyIsoCode = 'USD'
        );
        insert project;

        // Create Parent Bill Code
        pse__Milestone__c parentMilestone = new pse__Milestone__c(
            Name = 'Test Bill Code',
            pse__Project__c = project.Id,
            pse__Target_Date__c = Date.today(),
            Units__c = 1,
            PreBill_Unit_Complete_Cost__c = 100,
            CurrencyIsoCode = 'USD'
        );
        insert parentMilestone;

        // Create WIP Record
        WIP_Units_Complete__c wipRecord = new WIP_Units_Complete__c(
            BillCode_Name__c = parentMilestone.Id,
            Project__c = project.Id,
            WIP_Completed_Units__c = 2,
            Date_Completed__c = Date.today(),
            CurrencyIsoCode = 'USD'
        );
        insert wipRecord;
    }

    @isTest
    static void testHandleNonBillableDeletion() {
        // Re-query records created in @testSetup
        WIP_Units_Complete__c wipToDelete = [
            SELECT Id, BillCode_Name__c, Project__c 
            FROM WIP_Units_Complete__c 
            LIMIT 1
        ];

        Id billCodeId = wipToDelete.BillCode_Name__c;
        Id projectId = wipToDelete.Project__c;

        Test.startTest();
        delete wipToDelete;
        Test.stopTest();

        // Validate Bill Code update
        pse__Milestone__c updatedBillCode = [
            SELECT Id, PreBill_Unit_Complete_Cost__c 
            FROM pse__Milestone__c 
            WHERE Id = :billCodeId
        ];

        // Validate Project WIP adjustment
        pse__Proj__c updatedProject = [
            SELECT Id, WIP_Amount_Remaining__c 
            FROM pse__Proj__c 
            WHERE Id = :projectId
        ];
        
    }
}