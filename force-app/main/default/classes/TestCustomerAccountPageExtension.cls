/***************************************************************************************************
Class    :  TestCustomerAccountPageExtension.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :  July 11, 2013
Modified :  July 18, 2013
Objective:  This class provides methods to test CustomerAccountPageExtension.cls. 

***************************************************************************************************/

@isTest
public class TestCustomerAccountPageExtension
{
    //  static variables declared in alphabetical order
    static User admin = [ select id, firstname from user where id = :UserInfo.getUserId () ];

    //  methods listed in alphabetical order
    static testMethod void testExtension ()
    {
        List <User> salesreps = IMGAUtilities.insertSalesReps ();

        System.assertEquals (2, salesreps.size ());

        User bdeUser = salesreps [0];
        User cdeUser = salesreps [1];

        String customerUrl = Url.getSalesforceBaseUrl ().toExternalForm ();

        System.RunAs (admin)
        {
            Test.startTest ();

            List <Account> imgas = IMGAUtilities.instantiateImgaAccounts (1, bdeUser.Id, cdeUser.Id);

            insert imgas;

            System.assertEquals (1, imgas.size ());

            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);

            insert accounts;

            System.assertEquals (1, accounts.size ());
            
             List <Contact> contacts = IMGAUtilities.instantiateContacts (accounts);

            insert contacts;

            System.assertEquals (1, contacts.size ());

            List <IM_Customer_Account__c> customerAccounts
                          = IMGAUtilities.instantiateCustomerAccounts (accounts);

            insert customerAccounts;

            System.assertEquals (20, customerAccounts.size ());

            //#30774: Decommission At Risk KPI Object and all related Components/References
            /*List <At_Risk_KPI__c> atRiskKpis = IMGAUtilities.intantiateAtRiskKpis (customerAccounts);

            insert atRiskKpis;

            System.assertEquals (20, atRiskKpis.size ());*/

            List <Billings__c> billings = IMGAUtilities.instantiateBillings (customerAccounts);

            insert billings;

            System.assertEquals (20, billings.size ());
                                                              
            customerUrl += '/' + customerAccounts [0].Id;
            PageReference pageReference = new PageReference (customerUrl);
            Test.setCurrentPageReference (pageReference);
            ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller (customerAccounts [0]);
            CustomerAccountPageExtension extension = new CustomerAccountPageExtension (controller); 

            System.assertEquals (accounts [0].Id, extension.getAccountId ());

            List <Report> reports = extension.getBillingReports ();

            System.assertEquals (customerAccounts [0].Id, extension.getCustomerAccountId ());

            System.assertEquals (customerAccounts [0].Name, extension.getCustomerAccountName ());
 
            System.assertEquals (false, extension.getShowDbrTab ()); 

            System.assertEquals (true, extension.getShowDmsTab ());

            System.assertEquals (true, extension.getShowRmTab ());

            System.assertEquals (true, extension.getShowOtherTab ());

            System.assertEquals (true, extension.getShowShredTab ());
       
        }

    }   //  testExtension ()

    
}