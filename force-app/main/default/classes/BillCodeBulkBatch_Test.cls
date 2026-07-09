@isTest
public class BillCodeBulkBatch_Test {

    @isTest
    static void testBatchExecution() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // --- DML Best Practice: Create Projects in a List ---
        List<pse__Proj__c> projectsToInsert = new List<pse__Proj__c>();

        // Setup required Project record 1
        pse__Proj__c proj = new pse__Proj__c(
            Name = 'Test Project',
            pse__Account__c = acc.Id,
            pse__Billing_Type__c = 'Bundle',
            Service_State__c = 'Test',
            CurrencyIsoCode = 'USD'
        );
        projectsToInsert.add(proj);
        
        // Setup required Project record 2
        pse__Proj__c proj1 = new pse__Proj__c(
            Name = 'Test Project 2', // Best to use a unique name
            pse__Account__c = acc.Id,
            pse__Billing_Type__c = '',
            Service_State__c = 'Test',
            CurrencyIsoCode = 'USD'
        );
        projectsToInsert.add(proj1);
        
        pse__Proj__c proj2 = new pse__Proj__c(
            Name = 'Test Project 3', // Best to use a unique name
            pse__Account__c = acc.Id,
            pse__Billing_Type__c = 'Time and Materials',
            Service_State__c = 'Test',
            CurrencyIsoCode = 'USD'
        );
        projectsToInsert.add(proj2);

        // Insert all projects at once
        insert projectsToInsert;

        // --- DML Best Practice: Create Milestones in a List ---
        List<pse__Milestone__c> milestonesToInsert = new List<pse__Milestone__c>();

        // Setup reference milestone 1
        pse__Milestone__c refMilestone = new pse__Milestone__c(
            pse__Project__c = proj.Id,
            Actual_Cost_Rate__c = 100,
            Name = 'Ref Milestone',
            Contract_Rate__c = 110,
            Adjustment__c = 5,
            CurrencyIsoCode = 'USD',
            pse__Target_Date__c = Date.today()
        );
        milestonesToInsert.add(refMilestone);

        // Setup reference milestone 2
        pse__Milestone__c refMilestone1 = new pse__Milestone__c(
            pse__Project__c = proj1.Id,
            Actual_Cost_Rate__c = 100,
            Name = 'Ref Milestone1',
            Contract_Rate__c = 110,
            Adjustment__c = 5,
            CurrencyIsoCode = 'USD',
            pse__Target_Date__c = Date.today()
        );
        milestonesToInsert.add(refMilestone1);
        
        // Setup reference milestone 3
        pse__Milestone__c refMilestone2 = new pse__Milestone__c(
            pse__Project__c = proj2.Id,
            Actual_Cost_Rate__c = 100,
            Name = 'Ref Milestone2',
            Contract_Rate__c = 110,
            Adjustment__c = 5,
            CurrencyIsoCode = 'USD',
            pse__Target_Date__c = Date.today()
        );
        milestonesToInsert.add(refMilestone2);

        // Insert all milestones at once
        insert milestonesToInsert;

        // Create input records for the batch class
        List<Map<String, Object>> inputRecords = new List<Map<String, Object>>();
        
        Map<String, Object> rec1 = new Map<String, Object>{
            'Project_ID__c' => proj.Id,
            'Bill_Code_ID__c' => 'BC001',
            'Billing_Code__c' => 'BCode1',
            'Bill_Code_District_ID__c' => 'Dist123',
            'Units_Complete__c' => 10,
            'Service_Order__c' => 'SO123',
            'Division_ID__c' => 'Div1',
            'Department_ID__c' => 'DeptA'
        };
        inputRecords.add(rec1);

        Map<String, Object> rec2 = new Map<String, Object>{
            'Project_ID__c' => proj.Id,
            'Bill_Code_ID__c' => 'BC001',
            'Billing_Code__c' => 'BCode1',
            'Bill_Code_District_ID__c' => 'Dist123',
            'Units_Complete__c' => 5,
            'Service_Order__c' => 'SO123',
            'Division_ID__c' => 'Div1',
            'Department_ID__c' => 'DeptA'
        };
        inputRecords.add(rec2);

        // Initialize and execute batch within Test context
        Test.startTest();
        BillCodeBulkBatch batch = new BillCodeBulkBatch(proj.Id, inputRecords);
        Database.executeBatch(batch, inputRecords.size());
        Test.stopTest();

        // Validate milestones creation from the batch process
        List<pse__Milestone__c> createdMilestones = [
            SELECT BC_ID__c, Name, Bundle_Bill_Code__c, Units_Complete__c, Contract_Rate__c, Adjustment__c 
            FROM pse__Milestone__c 
            WHERE pse__Project__c = :proj.Id 
            AND BC_ID__c = 'BC001' // Query for the ID you expect the batch to create
        ];
        
    }
}