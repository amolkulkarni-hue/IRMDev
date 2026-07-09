@isTest
public class ProjectQuickActionControllerTest {
    @isTest
    static void testGetScheduleAQuoteItems_ReturnsItems() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create Schedule_A__c record
        Schedule_A__c scheduleA = new Schedule_A__c(Status__c = 'Active',Account__c = acc.Id,Reference__c = 'Test' );
        insert scheduleA;

        // Create Deal_Review__c record and link to Schedule_A__c
        Deal_Review__c dealReview = new Deal_Review__c( Utility__c = False, Schedule_A__c = scheduleA.Id);
        insert dealReview;

        // Create pse__Proj__c record and link to Deal_Review__c
        pse__Proj__c project = new pse__Proj__c(Name = 'Test Project',pse__Account__c = acc.Id, Service_State__c = 'Test State', Deal_Review__c = dealReview.Id);
        insert project;

        // Create Schedule_A_Quote_Item__c record with XML_Proposed_Volume__c > 0 and correct Schedule_A__c
        Schedule_A_Quote_Item__c quoteItem = new Schedule_A_Quote_Item__c(
          //  Name = 'Test Quote Item',
           // Product_Name__c = 'Product 1',
            Product_Number__c = 'PN001',
          //  Unit_of_Measure__c = 'Unit',
            Cashview_Cost_Line__c = 100,
          //  Cashview_Margin_Line__c = 25,
            XML_Proposed_Volume__c = 10,
            Proposed_Price__c = 500,
            Target_Price__c = 550,
            Floor_Price__c = 450,
            Current_Price__c = 470,
            Current_Volume__c = 5,
            Line_Revenue__c = 2500,
            Schedule_A__c = scheduleA.Id
        );
        insert quoteItem;

        Test.startTest();
        List<Schedule_A_Quote_Item__c> result = ProjectQuickActionController.getScheduleAQuoteItems(project.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one quote item');
        System.assertEquals(quoteItem.Id, result[0].Id, 'Returned quote item Id should match inserted quote item');
    }

    @isTest
    static void testGetScheduleAQuoteItems_NullConditions() {
		Account acc = new Account(Name = 'Test Account');
        insert acc;
		
        // Create pse__Proj__c record without Deal_Review__c
        pse__Proj__c projectWithoutDealReview = new pse__Proj__c(pse__Account__c = acc.Id,Name = 'No Deal Review', Service_State__c = 'Test State');
        insert projectWithoutDealReview;

        Test.startTest();
        List<Schedule_A_Quote_Item__c> result1 = ProjectQuickActionController.getScheduleAQuoteItems(projectWithoutDealReview.Id);
        Test.stopTest();

        System.assertEquals(0, result1.size(), 'Should return empty list if Deal_Review__c is null');

      /*  // Create Deal_Review__c without Schedule_A__c
        Deal_Review__c dealReview = new Deal_Review__c(No_PA_Model_Required__c = true,Reason_for_No_PA_Model__c = 'Other',Dedicated_Capital__c = 100.0000,Floor_Revenue_Realization_Percent__c = 105,Submitter_Comments__c = 'Test Comments', Utility__c = False, Status__c = 'Approved');
        insert dealReview;

        pse__Proj__c projectWithoutScheduleA = new pse__Proj__c(pse__Account__c = acc.Id,Name = 'Project No ScheduleA', Service_State__c = 'Test State', Deal_Review__c = dealReview.Id);
        insert projectWithoutScheduleA;

        Test.startTest();
        List<Schedule_A_Quote_Item__c> result2 = ProjectQuickActionController.getScheduleAQuoteItems(projectWithoutScheduleA.Id);
        Test.stopTest();

        System.assertEquals(0, result2.size(), 'Should return empty list if Schedule_A__c is null in Deal_Review__c'); */
    } 
}