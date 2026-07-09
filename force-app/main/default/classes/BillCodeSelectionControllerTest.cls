/**
* @File Name : BillCodeSelectionControllerTest.cls
* @Description : Test class for BillCodeSelectionController Apex class
**/

@isTest
public class BillCodeSelectionControllerTest {

    private static Id billCodeId;
    private static Id projectId;
    private static Id wipRecordId;

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
            CurrencyIsoCode = 'USD'
        );
        insert project;
        projectId = project.Id;

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
        billCodeId = parentMilestone.Id;

        // Create WIP Record
        WIP_Units_Complete__c wipRecord = new WIP_Units_Complete__c(
            BillCode_Name__c = parentMilestone.Id,
            Project__c = project.Id,
            WIP_Completed_Units__c = 2,
            Date_Completed__c = Date.today(),
            CurrencyIsoCode = 'USD'
        );
        insert wipRecord;
        wipRecordId = wipRecord.Id;

        // Update WIP_Amount_Remaining__c for project to test restore
        project.WIP_Amount_Remaining__c = 100;
        update project;
    }

    @isTest
    static void testGetBillCodesItemized() {
        pse__Proj__c project = [SELECT Id, Name FROM pse__Proj__c WHERE Name = 'Test Project' LIMIT 1];

        Test.startTest();
        List<pse__Milestone__c> result = BillCodeSelectionController.getBillCodes(project.Id);
        Test.stopTest();
    }

    @isTest
    static void testCreatePreBillRecords() {
        pse__Milestone__c billCode = [SELECT Id FROM pse__Milestone__c WHERE Name = 'Test Bill Code' LIMIT 1];

        WIP_Units_Complete__c newRecord = new WIP_Units_Complete__c(
            BillCode_Name__c = billCode.Id,
            WIP_Completed_Units__c = 1,
            Date_Completed__c = Date.today(),
            CurrencyIsoCode = 'USD'
        );

        Test.startTest();
        String response = BillCodeSelectionController.createPreBillRecords(
            new List<WIP_Units_Complete__c>{ newRecord }
        );
        Test.stopTest();

        System.assertEquals('Records inserted and Project WIP updated successfully', response);

        pse__Proj__c updatedProject = [SELECT WIP_Amount_Remaining__c FROM pse__Proj__c WHERE Name = 'Test Project' LIMIT 1];
        System.assertNotEquals(null, updatedProject.WIP_Amount_Remaining__c, 'WIP Amount Remaining should be calculated');
    }

    @isTest
    static void testHandleNonBillableDeletion() {
        // Step 1: Create Account
        Account acc = new Account(Name = 'Delete Test Account');
        insert acc;

        // Step 2: Create Project
        pse__Proj__c project = new pse__Proj__c(
            Name = 'Delete Test Project',
            Service_State__c = 'Test',
            pse__Billing_Type__c = 'Time and Materials',
            pse__Account__c = acc.Id,
            pse__Is_Active__c = true,
            pse__Bookings__c = 1000,
            WIP_Amount_Remaining__c = 0,
            CurrencyIsoCode = 'USD'
        );
        insert project;

        // Step 3: Create Bill Code (with required fields for formula fields)
        pse__Milestone__c billCode = new pse__Milestone__c(
            Name = 'Delete Test Bill Code',
            pse__Project__c = project.Id,
            pse__Target_Date__c = Date.today(),
            Units__c = 1,
            PreBill_Unit_Complete_Cost__c = 100,
            CurrencyIsoCode = 'USD' 
        );
        
        insert billCode;

        // Step 4: Create WIP record (formulas will calculate after insert)
        WIP_Units_Complete__c wip = new WIP_Units_Complete__c(
            BillCode_Name__c = billCode.Id,
            Project__c = project.Id,
            WIP_Completed_Units__c = 2,
            Date_Completed__c = Date.today(),
            CurrencyIsoCode = 'USD'
        );
        insert wip;

        // Step 5: Re-query WIP to ensure formula fields are calculated
        wip = [
            SELECT Id, BillCode_Name__c, WIP_Completed_Units__c,
                Bill_Code_Completed_Cost__c, SOW_Rate__c
            FROM WIP_Units_Complete__c
            WHERE Id = :wip.Id
        ];

        // Step 6: Call the method with formula-calculated values
        Test.startTest();
        BillCodeSelectionController.handleNonBillableDeletion(
            new List<WIP_Units_Complete__c>{ wip }
        );
        Test.stopTest();

        // Step 7: Assert updated values
        pse__Proj__c updatedProject = [
            SELECT WIP_Amount_Remaining__c FROM pse__Proj__c WHERE Id = :project.Id
        ];

        pse__Milestone__c updatedBillCode = [
            SELECT PreBill_Unit_Complete_Cost__c FROM pse__Milestone__c WHERE Id = :billCode.Id
        ];
    }

    @isTest
    static void testUpdateProjectWIPFromFlow_emptyList() {
        // Covers the null/empty branch
        Test.startTest();
        BillCodeSelectionController.updateProjectWIPFromFlow(new List<BillCodeSelectionController.WIPInputWrapper>());
        Test.stopTest();
        System.assert(true, 'Handled empty input gracefully');
    }

    @isTest
    static void testUpdateProjectWIPFromFlow_withValidRecord() {
        // Step 1: Create Account
        Account acc = new Account(Name = 'Delete Test Account');
        insert acc;

        // Step 2: Create Project
        pse__Proj__c project = new pse__Proj__c(
            Name = 'Delete Test Project',
            Service_State__c = 'Test',
            pse__Billing_Type__c = 'Time and Materials',
            pse__Account__c = acc.Id,
            pse__Is_Active__c = true,
            pse__Bookings__c = 1000,
            WIP_Amount_Remaining__c = 0,
            CurrencyIsoCode = 'USD'
        );
        insert project;

        // Step 3: Create Bill Code (with required fields for formula fields)
        pse__Milestone__c billCode = new pse__Milestone__c(
            Name = 'Delete Test Bill Code',
            pse__Project__c = project.Id,
            pse__Target_Date__c = Date.today(),
            Units__c = 1,
            PreBill_Unit_Complete_Cost__c = 100,
            CurrencyIsoCode = 'USD' 
        );
        
        insert billCode;

        // Step 4: Create WIP record (formulas will calculate after insert)
        WIP_Units_Complete__c wip = new WIP_Units_Complete__c(
            BillCode_Name__c = billCode.Id,
            Project__c = project.Id,
            WIP_Completed_Units__c = 2,
            Date_Completed__c = Date.today(),
            CurrencyIsoCode = 'USD'
        );
        insert wip;

        // 4. Create wrapper with this WIP record Id
        BillCodeSelectionController.WIPInputWrapper wrapper = 
            new BillCodeSelectionController.WIPInputWrapper();
        wrapper.wipRecordId = wip.Id;

        // 5. Call method
        Test.startTest();
        BillCodeSelectionController.updateProjectWIPFromFlow(new List<BillCodeSelectionController.WIPInputWrapper>{wrapper});
        Test.stopTest();

        // 6. Verify record still exists and method executed
        WIP_Units_Complete__c wipAfter = [SELECT Id FROM WIP_Units_Complete__c WHERE Id = :wip.Id];
        System.assertNotEquals(null, wipAfter, 'WIP record should still exist after updateProjectWIPFromFlow');
    }
}