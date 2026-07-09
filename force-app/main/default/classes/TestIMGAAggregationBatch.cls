/***************************************************************************************************
Class    :  TestIMGAAggregationBatch.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :  July 11, 2013
Modified :  July 17, 2013
Objective:  This class provides methods to test IMGAAggregationBatch.cls. 

***************************************************************************************************/

@isTest
public class TestIMGAAggregationBatch
{
    //  static variables declared in alphabetical order
    static User admin   = [ select id from user where id = :UserInfo.getUserId () ];
    static User bdeUser = null;
    static User cdeUser = null;

    static 
    {
    	admin = [ select id from user where id = :UserInfo.getUserId () ];
        List <User> salesreps = IMGAUtilities.insertSalesReps ();

        System.assertEquals (2, salesreps.size ());

        bdeUser = salesreps [0];
        cdeUser = salesreps [1];

    }

    //  methods listed in alphabetical order
    static testMethod void testAggregationBatch ()
    {
        System.RunAs (admin)
        {
            Test.startTest ();

            List <Account> imgas = IMGAUtilities.instantiateImgaAccounts (1, bdeUser.Id, cdeUser.Id);

            insert imgas;

            System.assertEquals (1, imgas.size ());

            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);

            insert accounts;

            System.assertEquals (1, accounts.size ());

            List <IM_Customer_Account__c> customerAccounts = IMGAUtilities.instantiateCustomerAccounts (accounts);

            insert customerAccounts;

            System.assertEquals (20, customerAccounts.size ());

            List <Billings__c> billings = IMGAUtilities.instantiateBillings (customerAccounts);

            insert billings;

            System.assertEquals (20, billings.size ());

            IMGAAggregationBatch batch = new IMGAAggregationBatch ();
            
            IMGARiskAssessmentLauncherCont.fireAggregationBatch();
            Id processId = IMGARiskAssessmentLauncherCont.processID;
            
            IMGAAggregationBatch batch1 = new IMGAAggregationBatch();
            Id batchId = Database.executeBatch(batch1, 1);

            Test.stopTest ();

            AsyncApexJob job = [ select createdby.email, id, jobitemsprocessed, numberoferrors, status, totaljobitems from asyncapexjob where id = :processId ];

            System.assertEquals (job.Status, 'Completed');

            System.assertEquals (job.JobItemsProcessed, 1);

            System.assertEquals (job.NumberOfErrors, 0);

        }

    }   //  testAggregationBatch ()

}