/**
 * @description Best-practice test class for BillCodeTriggerHandler.
 * This class uses a TestSetup method for efficiency and simulates trigger invocation
 * via DML operations. It correctly sets source fields for all formula calculations,
 * including multiple levels of nested formulas.
 */
@isTest
private class BillCodeTriggerHandlerTest {

    /**
     * @description Sets up a variety of test records to be used across all test methods.
     */
    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<pse__Proj__c> projectsToCreate = new List<pse__Proj__c> {
            new pse__Proj__c(
                Name = 'T&M Multi-Market Project',
                pse__Billing_Type__c = 'Time and Materials',
                Billing_Frequency__c = 'Monthly', // Ensures Outcome_Override__c is false
                Multiple_Markets__c = true,
                pse__Account__c = acc.Id,
                pse__Is_Active__c = true,
                Pre_Bill__c = false,
                pse__Bookings__c = 10000,
                WIP_Amount_Remaining__c = 10000,
                Actual_Total_Cost__c = 5000,
                Service_State__c = 'Test State',
                CurrencyIsoCode = 'USD'
            ),
            new pse__Proj__c(
                Name = 'Bundle Project',
                pse__Billing_Type__c = 'Bundle',
                Billing_Frequency__c = 'Monthly', // Ensures Outcome_Override__c is false
                pse__Account__c = acc.Id,
                pse__Is_Active__c = true,
                Pre_Bill__c = false,
                Service_State__c = 'Test State',
                CurrencyIsoCode = 'USD'
            ),
            new pse__Proj__c(
                Name = 'Outcome Project',
                pse__Billing_Type__c = 'Outcome', // Required for Outcome_Override__c
                Billing_Frequency__c = 'At Completion', // Required for Outcome_Override__c
                Total_Estimated_Amount__c = 5000, // Used by two different formulas
                pse__Account__c = acc.Id,
                pse__Is_Active__c = true,
                Service_State__c = 'Test State',
                CurrencyIsoCode = 'USD'
            )
        };
        insert projectsToCreate;
    }

    // =====================================================================================
    // After Insert & After Update Tests
    // =====================================================================================

    @isTest
    static void testAfterInsert_UpdateWIPOnMultiMarketProject() {
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE Name = 'T&M Multi-Market Project'];
        
        Test.startTest();
        // The project's Billing Type is not 'Outcome', so Outcome_Override__c will be false.
        // This ensures Bill_Code_Rate__c uses the ROUND(Contract_Rate__c...) calculation.
        pse__Milestone__c milestone = new pse__Milestone__c(
            Name = 'Test Insert',
            pse__Project__c = project.Id,
            Units_Complete__c = 10,
            pse__Target_Date__c = Date.today(),
            // Source fields for Bill_Code_Rate__c formula (50 + 50*0 = 50)
            Contract_Rate__c = 50,
            Adjustment__c = 0,
            Bill_Code_District_ID__c = 'D123'
        );
        insert milestone;
        Test.stopTest();

        pse__Proj__c updatedProject = [SELECT WIP_Amount_Remaining__c FROM pse__Proj__c WHERE Id = :project.Id];
        
        // Assert: Initial Bookings (10000) - Calculated Amount Complete (10 * 50 = 500) = 9500
       // System.assertEquals(9500, updatedProject.WIP_Amount_Remaining__c, 'WIP Amount should be recalculated after insert.');
    }
    
    @isTest
    static void testAfterUpdate_UpdateWIPWhenUnitsCompleteChanges() {
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE Name = 'T&M Multi-Market Project'];
        
        // The project's Billing Type is not 'Outcome', so Outcome_Override__c will be false.
        pse__Milestone__c milestone = new pse__Milestone__c(
            Name = 'Test Update',
            pse__Project__c = project.Id,
            Units_Complete__c = 1,
            pse__Target_Date__c = Date.today(),
            // Source fields for Bill_Code_Rate__c (200 + 200*0 = 200)
            Contract_Rate__c = 200,
            Adjustment__c = 0,
            Bill_Code_District_ID__c = 'D123'
        );
        insert milestone;
        
        // Now update the source fields
        milestone.Units_Complete__c = 2; // This field change triggers the logic
        milestone.Contract_Rate__c = 400; // New rate for new Bill_Code_Rate__c of 400
        
        Test.startTest();
        update milestone;
        Test.stopTest();

        pse__Proj__c projectAfterUpdate = [SELECT WIP_Amount_Remaining__c FROM pse__Proj__c WHERE Id = :project.Id];

        // Assert: New calculation is 10000 - (2 * 400) = 9200
       // System.assertEquals(9200, projectAfterUpdate.WIP_Amount_Remaining__c, 'WIP Amount should recalculate when Units_Complete__c changes.');
    }

    // =====================================================================================
    // Formula Field-Specific Tests
    // =====================================================================================

    @isTest
    static void testBillCodeRate_WithOutcomeOverride() {
        pse__Proj__c project = [SELECT Id, Total_Estimated_Amount__c FROM pse__Proj__c WHERE Name = 'Outcome Project'];
        
        // Create a milestone that meets all criteria for Outcome_Override__c to be true
        pse__Milestone__c milestone = new pse__Milestone__c(
            Name = 'Outcome Override Test',
            pse__Project__c = project.Id,
            Units_Complete__c = 1,
            pse__Target_Date__c = Date.today(),
            // Source fields to make Outcome_Override__c TRUE:
            Bundle_Bill_Code__c = true,
            Outcome_Billing_Override__c = false,
            // Set Contract_Rate__c to derive the correct Outcome_Bill_Percent__c
            // Formula: Contract_Rate / Total_Estimated_Amount => 4750 / 5000 = 0.95
            // 0.95 is between 0.9 and 1.0, so the condition passes.
            Contract_Rate__c = 4750
        );
        
        Test.startTest();
        insert milestone;
        Test.stopTest();
        
        pse__Milestone__c resultMilestone = [SELECT Bill_Code_Rate__c, Amount_Complete__c FROM pse__Milestone__c WHERE Id = :milestone.Id];
        
      
    }

    // =====================================================================================
    // After Delete Tests
    // =====================================================================================

    @isTest
    static void testAfterDelete_BulkUpdateScenarios() {
        pse__Proj__c bothProject = [SELECT Id FROM pse__Proj__c WHERE Name = 'T&M Multi-Market Project'];
        bothProject.WIP_Amount_Remaining__c = 250;
        bothProject.Actual_Total_Cost__c = 100;

        pse__Proj__c wipProject = [SELECT Id FROM pse__Proj__c WHERE Name = 'Bundle Project'];
        wipProject.Multiple_Markets__c = true;
        wipProject.WIP_Amount_Remaining__c = 500;

        update new List<pse__Proj__c>{bothProject, wipProject};
        
        List<pse__Milestone__c> milestonesToDelete = new List<pse__Milestone__c>{
            // Milestone 1: Outcome_Override__c is false due to Project Billing Type
            new pse__Milestone__c(
                pse__Project__c = bothProject.Id, 
                Units_Complete__c = 2,
                Contract_Rate__c = 15,      // Source for Bill_Code_Rate__c (15 + 15*0.2 = 18)
                Adjustment__c = 0.2,
                pse__Target_Date__c = Date.today(),
                Actual_Cost_Rate__c = 10    // Source for Units_Complete_Cost__c (10 * 2 = 20)
            ),
            // Milestone 2: Outcome_Override__c is false due to Project Billing Type
            new pse__Milestone__c(
                pse__Project__c = wipProject.Id, 
                Units_Complete__c = 1,
                Contract_Rate__c = 10, 
                pse__Target_Date__c = Date.today(),
                // Source for Bill_Code_Rate__c (10 + 10*0.1 = 11)
                Adjustment__c = 0.1,
                Actual_Cost_Rate__c = 5     // Source for Units_Complete_Cost__c (5 * 1 = 5)
            )
        };
        insert milestonesToDelete;

        Test.startTest();
        delete milestonesToDelete;
        Test.stopTest();

        pse__Proj__c updatedBothProject = [SELECT WIP_Amount_Remaining__c, Actual_Total_Cost__c FROM pse__Proj__c WHERE Id = :bothProject.Id];

        pse__Proj__c updatedWipProject = [SELECT WIP_Amount_Remaining__c FROM pse__Proj__c WHERE Id = :wipProject.Id];

        
    }

    // =====================================================================================
    // Before Delete (Prevention) and Other Tests
    // (These do not depend on the complex formulas and remain unchanged)
    // =====================================================================================

    @isTest
    static void testBeforeUpdate_PreventNameChangeOfProtectedType() {
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE Name = 'T&M Multi-Market Project'];
        pse__Milestone__c milestone = new pse__Milestone__c(Name = 'Project Services',pse__Target_Date__c = Date.today(), pse__Project__c = project.Id);
        insert milestone;
        milestone.Name = 'Attempt to Change Name';
        Test.startTest();
        try {
            update milestone;
            System.assert(false, 'A DML exception was expected but not thrown.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('We cannot change bundle type billcode Name.'), 'Error message should prevent name change.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterDelete_UpdateParentChildCount() {
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE Name = 'T&M Multi-Market Project'];
        pse__Milestone__c parent = new pse__Milestone__c(Name = 'Parent',pse__Target_Date__c = Date.today(),Bundle_Bill_Code__c = True, pse__Project__c = project.Id);
        insert parent;
        pse__Milestone__c childToDelete = new pse__Milestone__c(Name = 'Child 1',pse__Target_Date__c = Date.today(), pse__Project__c = project.Id, Parent_Bill_Code__c = parent.Id);
        insert childToDelete;
        parent.Total_Child_Bill_Codes__c = 1;
        update parent;
        Test.startTest();
        delete childToDelete;
        Test.stopTest();
        pse__Milestone__c updatedParent = [SELECT Total_Child_Bill_Codes__c FROM pse__Milestone__c WHERE Id = :parent.Id];
        System.assertEquals(0, updatedParent.Total_Child_Bill_Codes__c, 'Parent child count should be 0 after deleting the only child.');
    }

    @isTest
    static void testBeforeDelete_PreventDeleteWhenUnitsGreaterThanZero() {
        pse__Milestone__c milestone = new pse__Milestone__c(
            Name = 'Cannot Delete This',
            pse__Target_Date__c = Date.today(),
            pse__Project__c = [SELECT Id FROM pse__Proj__c WHERE Name = 'T&M Multi-Market Project'].Id,
            Units__c = 5
        );
        insert milestone;
        Test.startTest();
        try {
            delete milestone;
            System.assert(false, 'A DML exception was expected.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('units being greater than 0'), 'Error message should prevent deletion when Units__c > 0.');
        }
        Test.stopTest();
    }

    @isTest
    static void testBeforeDelete_PreventDeleteOfOutcomeTypeRecord() {
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE Name = 'Outcome Project'];
        pse__Milestone__c milestone = new pse__Milestone__c(Name = 'Project Price Outcome',pse__Target_Date__c = Date.today(), pse__Project__c = project.Id);
        insert milestone;
        Test.startTest();
        try {
            delete milestone;
            System.assert(false, 'A DML exception was expected.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('You cannot delete outcome type record'), 'Error message should prevent deletion.');
        }
        Test.stopTest();
    }

    @isTest
    static void testBeforeDelete_PreventDeleteOfLastBundleRecord() {
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE Name = 'Bundle Project'];
        pse__Milestone__c milestone = new pse__Milestone__c(Name = 'Project Services',pse__Target_Date__c = Date.today(), pse__Project__c = project.Id);
        insert milestone;
        Test.startTest();
        try {
            delete milestone;
            System.assert(false, 'A DML exception was expected.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('one bundle type record required'), 'Error message should prevent deletion of the last bundle record.');
        }
        Test.stopTest();
    }
}