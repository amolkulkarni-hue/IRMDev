/***************************************************************************************************
Class    :  TestIMGARiskAssessmentPageExtension.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :  July 11, 2013
Modified :  July 25, 2013
Objective:  This class provides methods to test IMGARiskAssessmentPageExtension.cls. 

***************************************************************************************************/

@isTest
public class TestIMGARiskAssessmentPageExtension
{
    //  static variables declared in alphabetical order
    static User admin = [ select id from user where id = :UserInfo.getUserId () ];

    //  methods listed in alphabetical order
    static testMethod void testExtension ()
    {
        List <User> salesreps = IMGAUtilities.insertSalesReps ();

        System.assertEquals (2, salesreps.size ());

        User bdeUser = salesreps [0];
        User cdeUser = salesreps [1];

        String riskAssessmentUrl = Url.getSalesforceBaseUrl ().toExternalForm ();

        System.RunAs (admin)
        {
            Test.startTest ();

            List <Account> imgas = IMGAUtilities.instantiateImgaAccounts (1, bdeUser.Id, cdeUser.Id);

            insert imgas;

            System.assertEquals (1, imgas.size ());

            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);

            insert accounts;

            System.assertEquals (1, accounts.size ());
/*  imgas created in this test class will not pass filter validations for parents of 
         newly-created Bob_Coverage__c records
            List <BoB_Coverage__c> coverages = IMGAUtilities.instantiateCoverages (imgas, bdeUser.Id);

            insert coverages;

            System.assertEquals (1, coverages.size ());
*/
            List <Contact> contacts = IMGAUtilities.instantiateContacts (accounts);

            insert contacts;

            System.assertEquals (1, contacts.size ());

            List <IM_Customer_Account__c> customerAccounts = IMGAUtilities.instantiateCustomerAccounts (accounts);

            insert customerAccounts;

            System.assertEquals (20, customerAccounts.size ());

            List <IMGA_Risk_Assessment__c> imgaRiskAssessments = IMGAUtilities.instatiateImgaRiskAssessments (imgas);

            insert imgaRiskAssessments;

            System.assertEquals (1, imgaRiskAssessments.size ());

            riskAssessmentUrl += '/apex/IMGARiskAssessmentPage?id' + imgaRiskAssessments [0].Id;
            PageReference pageReference = new PageReference (riskAssessmentUrl);
            Test.setCurrentPageReference (pageReference);
            ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller (imgaRiskAssessments [0]);
            IMGARiskAssessmentPageExtension extension = new IMGARiskAssessmentPageExtension (controller); 

            System.assertNotEquals (null, extension.createImgaSalesSupportRequest ());

            System.assertEquals (imgas [0].Id, extension.getAccountId ());

            System.assertNotEquals (null, extension.getAssessmentId ());

            System.assertEquals ('N/A', extension.getBusinessFunction ());

            //  no criteria
            System.assertEquals (0, extension.getContacts ().size ());

            //  all criteria
            extension.contactAccount   = 'bwtestimga000';
            extension.contactFirstName = 'Sally';
            extension.contactLastName  = 'bwtestimga000';

            System.assertEquals (0, extension.getContacts ().size ());

            //  account + first name
            extension.contactAccount   = 'bwtestimga000';
            extension.contactFirstName = 'Sally';
            extension.contactLastName  = null;

            System.assertEquals (0, extension.getContacts ().size ());

            //  account + last name
            extension.contactAccount   = 'bwtestimga000';
            extension.contactFirstName = null;
            extension.contactLastName  = 'bwtestimga000';

            System.assertEquals (0, extension.getContacts ().size ());            

            //  account
            extension.contactAccount   = 'bwtestimga000';
            extension.contactFirstName = null;
            extension.contactLastName  = null;

            System.assertEquals (0, extension.getContacts ().size ());

            //  first name + last name
            extension.contactAccount   = null;
            extension.contactFirstName = 'Sally';
            extension.contactLastName  = 'bwtestimga000';

            System.assertEquals (0, extension.getContacts ().size ());

            //  first name
            extension.contactAccount   = null;
            extension.contactFirstName = 'Sally';
            extension.contactLastName  = null;

            System.assertEquals (0, extension.getContacts ().size ());  

            //  last name
            extension.contactAccount   = null;
            extension.contactFirstName = null;
            extension.contactLastName  = 'bwtestimga000';

            System.assertEquals (0, extension.getContacts ().size ());

            System.assertNotEquals (null, extension.getFinishLocation ());

            //System.assertEquals (0, extension.getPrimaryReps ().size ()); // Commented as part of gitlab #25402

            System.assertEquals (null, extension.getReason1 ());

            System.assertEquals (null, extension.getReason2 ());

            System.assertEquals (null, extension.getReason3 ());

            System.assertEquals (null, extension.getReason4 ());

            System.assertEquals (null, extension.getReason5 ());

            extension.getResults ();

            System.assertEquals (true, extension.getShowDbrTab ());

            System.assertEquals (true, extension.getShowDmsTab ());

            System.assertEquals (false, extension.getShowReasons ());

            System.assertEquals (true, extension.getShowRmTab ());

            System.assertEquals (true, extension.getShowOtherTab ());

            System.assertEquals (true, extension.getShowShredTab ());

            System.assertEquals ('N/A', extension.getTrigger ());

            extension.selectUser ();

        }

    }   //  testExtension ()

}