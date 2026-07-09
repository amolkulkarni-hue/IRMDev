/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Test
 * @description Test for ArchivedEmailListViewController
 */

@isTest
private class ArchivedEmailListViewControllerTest {
    @isTest static void getArchivedEmails_nullArchiveEmails() {
        ArchivedEmailListViewController controller = createController();

        Test.startTest();
            List<Archive_Email__b> archivedEmails = controller.getArchivedEmails();
        Test.stopTest();

        System.assertEquals(null, archivedEmails, 'No archived emails should be return to display if none exist');
    }

    @isTest static void PreviousTest() {
        ArchivedEmailListViewController controller = createController();

        Test.startTest();
            controller.previous();
        Test.stopTest();

        System.assertEquals(-1, controller.pageNumber, 'The list should go to the previous page');
    }

    @isTest static void NextTest() {
        ArchivedEmailListViewController controller = createController();

        Test.startTest();
            controller.Next();
        Test.stopTest();

        System.assertEquals(1, controller.pageNumber, 'The list should go to the next page');
    }

    @isTest static void getDisablePreviousTest() {
        ArchivedEmailListViewController controller = createController();

        Test.startTest();
            Boolean isDisabled = controller.getDisablePrevious();
        Test.stopTest();

        System.assert(isDisabled, 'The previous button should be disabled');
    }

    @isTest static void getDisableNextTest() {
        ArchivedEmailListViewController controller = createController();

        Test.startTest();
            Boolean isDisabled = controller.getDisableNext();
        Test.stopTest();

        System.assert(isDisabled, 'The next button should be disabled');
    }

    @isTest static void getPageSizeTest() {
        ArchivedEmailListViewController controller = createController();

        Test.startTest();
            Integer totalPages = controller.getPageSize();
        Test.stopTest();

        System.assertEquals(5, totalPages, 'Default 5 records per page is set');
    }

    @isTest
    private static void getDisplayFullListButtonTest() {
        ArchivedEmailListViewController controller = createController();

        Test.startTest();
            Boolean buttonLogic = controller.getDisplayFullListButton();
        Test.stopTest();

        System.assert(!buttonLogic, 'The full list button boolean should reflected if there are more than 5 records in the page');
    }

    private static ArchivedEmailListViewController createController() {
        Case newCase = (Case) new SobjectBuilder(Case.SobjectType)
        .put(Case.RecordTypeId, Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Employees Support Case Closed (Locked)').getRecordTypeId())
        .put(Case.Subject, 'Holder')
        .put(Case.Status, 'Closed')
        .put(Case.Case_Sub_Category__c, 'IT Development')
        .create().getRecord();
        ApexPages.StandardController sc = new ApexPages.StandardController(newCase);

        return new ArchivedEmailListViewController(sc);
    }

}