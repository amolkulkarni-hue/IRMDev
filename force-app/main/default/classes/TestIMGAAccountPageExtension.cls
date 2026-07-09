@isTest
public class TestIMGAAccountPageExtension
{
    //  static variables declared in alphabetical order
    static User admin = [ select id, firstname from user where id =: UserInfo.getUserId () ];

    //  methods listed in alphabetical order
    static testMethod void testExtension ()
    {
        
        List <User> salesreps = IMGAUtilities.insertSalesReps ();

        System.assertEquals (2, salesreps.size ());

        User bdeUser = salesreps [0];
        User cdeUser = salesreps [1];

        String imgaUrl = Url.getSalesforceBaseUrl ().toExternalForm ();

        System.RunAs (admin)
        {
            Test.startTest ();

            List <Account> imgas = IMGAUtilities.instantiateImgaAccounts (1, bdeUser.Id, cdeUser.Id);

            insert imgas;

            System.assertEquals (1, imgas.size ());

            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);

            insert accounts;

            System.assertEquals (1, accounts.size ());

            List <IMGA_Risk_Assessment__c> imgaRiskAssessments 
                         = IMGAUtilities.instatiateImgaRiskAssessments (imgas);

            insert imgaRiskAssessments;

            System.assertEquals (1, imgaRiskAssessments.size ());

            imgaUrl += '/' + imgas [0].Id;
            PageReference pageReference = new PageReference (imgaUrl);
            
            Test.setCurrentPageReference (pageReference);
            
            ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller (imgas [0]);
            IMGAAccountPageExtension extension = new IMGAAccountPageExtension (controller); 

            System.assertEquals (imgas [0].Id, extension.getAccountId ());

            System.assertEquals (imgas [0].Name, extension.getAccountName ());

            List <Report> reports = extension.getAtRiskReports ();

            reports = extension.getBillingReports ();

            System.assertEquals (null, extension.getFinishLocation ());

            System.assertEquals (false, extension.getRedAlertFlag ());

            System.assertEquals (7, extension.getRiskScore ());

            System.assertEquals (IMGAUtilities.ACCOUNT_IMGA_RECORDTYPE, extension.getRecordType ());//Replacing the record type 'IMGA_Record_Type_At_Risk', because it is inactive. Gitlab #28236

            System.assertEquals (true, extension.getShowDbrTab ());

            System.assertEquals (true, extension.getShowDmsTab ());

            System.assertEquals (true, extension.getShowRmTab ());

            System.assertEquals (true, extension.getShowOtherTab ());

            System.assertEquals (true, extension.getShowShredTab ());

            System.assertEquals (admin.FirstName, extension.getUserFirstName ());

        }
    
    }   //  testExtension ()

}