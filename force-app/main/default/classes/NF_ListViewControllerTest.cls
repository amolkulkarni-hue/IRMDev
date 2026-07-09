/**
 * @description       : Test class for NF_ListViewController
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 04-29-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@isTest(seeAllData = false)
public with sharing class NF_ListViewControllerTest {
    @TestSetup
    static void makeData(){
        Id VALIDATE_RECORD_TYPE = RecordTypeCache.get(Case.SObjectType, 'NCSP_DMS').Id;
            List<case> listOfCases = new SObjectBuilder(Case.SObjectType)
                .put(Case.Status, 'Open')
                .put(Case.Project_Completion_Date__c, system.today() )
                //.put(Case.Transition_Date__c, system.today() )
                .put(Case.RecordTypeId, VALIDATE_RECORD_TYPE)
                .count(1).create().getRecords();
    }

    @isTest
    public static void getListViewDetailsTest(){
        Test.startTest();

        NF_ListViewController.ListViewresponseToSend response = NF_ListViewController.getListViewDetails(
            JSON.serialize(new Map<String, Object>{
                'requestedListView' => 'Case_Home_Page_Infinite',
                'existingRecordIds' => new List<Case>()
            })
        );

        Test.stopTest();

        System.assertEquals(1, response.recordsToDisplay.size(), '1 case to display');
    }
}