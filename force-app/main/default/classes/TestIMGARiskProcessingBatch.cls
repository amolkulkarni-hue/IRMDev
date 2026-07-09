/******************************************************************************************************
Class    :  TestIMGARiskProcessingBatch.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :    July 10, 2013
Modified :  August 05, 2013
Objective:  This class provides methods to test IMGARiskProcessingBatch.cls. 

******************************************************************************************************/

@IsTest(SeeAllData=true)
public class TestIMGARiskProcessingBatch
{
    //  static variables declared in alphabetical order
    static User admin = [ select id from user where id = :UserInfo.getUserId () ];

    //  methods listed in alphabetical order
    static testMethod void testProcessingBatch ()
    {
        List <User> salesreps = IMGAUtilities.insertSalesReps ();

        System.assertEquals (2, salesreps.size ());

        User bdeUser = salesreps [0];
        User cdeUser = salesreps [1];

        System.RunAs (admin)
        {
            Test.startTest ();

                        List <Account> imgas = IMGAUtilities.instantiateImgaAccounts (25, bdeUser.Id, cdeUser.Id);

            insert imgas;

            System.assertEquals (25, imgas.size ());

            Integer tenCount = 0;
            
            for ( Account imga : imgas )
                if ( imga.At_Risk_Score__c == 10 )
                    tenCount ++;

            System.assertEquals (15, tenCount);

            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);

            insert accounts;

            System.assertEquals (25, accounts.size ());

            List <IM_Customer_Account__c> customerAccounts
                          = IMGAUtilities.instantiateCustomerAccounts (accounts);

            insert customerAccounts;

            System.assertEquals (500, customerAccounts.size ());

            List <Account> overridenImgas = new List <Account>
            {
              imgas [0]
            , imgas [14]
            , imgas [24]
            };

            List <IMGA_Risk_Assessment__c> imgaRiskAssessments 
                         = IMGAUtilities.instatiateImgaRiskAssessments (overridenImgas);

            insert imgaRiskAssessments;

            System.assertEquals (3, imgaRiskAssessments.size ());
            
            IMGARiskAssessmentLauncherCont.fireRiskProcessingBatch();

            Test.stopTest ();

            AsyncApexJob job = [
                                    select

                                        createdby.email
                                      , id
                                      , jobitemsprocessed
                                      , numberoferrors
                                      , status
                                      , totaljobitems

                                    from asyncapexjob 

                                    where id = : IMGARiskAssessmentLauncherCont.processID
                                  ];

            System.assertEquals (job.Status, 'Completed');

            System.assertEquals (job.JobItemsProcessed, 1);

            System.assertEquals (job.NumberOfErrors, 0);

        }

    }   //  testProcessingBatch ()

}