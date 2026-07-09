@isTest(SeeAllData=true)

public class Test_IMGAAccountServices{
    
     static User admin = [ select id from user where id = :UserInfo.getUserId () ];
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

            Integer tenCount = 0;
            
            for ( Account imga : imgas )
                if ( imga.At_Risk_Score__c == 10 )
                    tenCount ++;

            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);
            insert accounts;


            List <IM_Customer_Account__c> customerAccounts
                          = IMGAUtilities.instantiateCustomerAccounts (accounts);
            insert customerAccounts;


            List <Account> overridenImgas = new List <Account>
            {
              imgas [0]
            , imgas [14]
            , imgas [24]
            };

            List <IMGA_Risk_Assessment__c> imgaRiskAssessments 
                         = IMGAUtilities.instatiateImgaRiskAssessments (overridenImgas);

            insert imgaRiskAssessments;
            
            IMGARiskAssessmentLauncherCont.fireRiskProcessingBatch();

            Test.stopTest ();

            AsyncApexJob job = [   select 
                                        createdby.email
                                      , id
                                      , jobitemsprocessed
                                      , numberoferrors
                                      , status
                                      , totaljobitems
                                    from asyncapexjob 

                                    where id = : IMGARiskAssessmentLauncherCont.processID
                                  ];

        }

    }   //  testProcessingBatch ()
    
     static testMethod void testExtension ()
    {
        
        List <User> salesreps = IMGAUtilities.insertSalesReps ();

        User bdeUser = salesreps [0];
        User cdeUser = salesreps [1];

        String imgaUrl = Url.getSalesforceBaseUrl ().toExternalForm ();

        System.RunAs (admin)
        {
            Test.startTest ();

            List <Account> imgas = IMGAUtilities.instantiateImgaAccounts (1, bdeUser.Id, cdeUser.Id);
            insert imgas;
            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);
            insert accounts;
            List <IMGA_Risk_Assessment__c> imgaRiskAssessments  = IMGAUtilities.instatiateImgaRiskAssessments (imgas);
            insert imgaRiskAssessments;

            imgaUrl += '/' + imgas [0].Id;
            PageReference pageReference = new PageReference (imgaUrl);
            Test.setCurrentPageReference (pageReference);
            
            ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller (imgas [0]);
            IMGAAccountPageExtension extension = new IMGAAccountPageExtension (controller); 

            List <Report> reports = extension.getAtRiskReports ();
            reports = extension.getBillingReports ();
            
            Test.stopTest ();

        }
    
    }   //  testExtension ()
    
    static testMethod void testAccountSet(){
    
    System.RunAs (admin)
        {
            Test.startTest ();
            
            String imga = 'Test Imga';
            Account  A = new Account(name='Account4TestMethod', BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States', IM_IMGA_Indexed__c=imga );
            insert A;
         /* Commented out - Avoiding "Non-selective query against large object type (more than 100000 rows)" */
         //   Set<Id> imgaSet = IMGAAccountServices.getAccountIdSetByImga(imga);
            
            Test.stopTest ();
    }
    }
    
    static testMethod void testRiskNotifications(){
        List <User> salesreps = IMGAUtilities.insertSalesReps ();
        User bdeUser = salesreps [0];
        User cdeUser = salesreps [1];
        Id bdeId = bdeUser.Id;
        Id cdeId = cdeUser.Id;

        System.RunAs (admin)
        {
            Test.startTest ();

            List <Account> imgas = IMGAUtilities.instantiateImgaAccounts (25, bdeUser.Id, cdeUser.Id);
            
             String imga = 'Test Imga';
             Account  A = new Account(name='Account4TestMethod', BillingStreet='test',
                                     BillingState='MA',BillingCity='Boston',BillingCountry='United States', 
                                     IM_IMGA_Indexed__c=imga, DBR_At_Risk_Score__c =10, RM_At_Risk_Score__c =10);
                                     
             a.Primary_CDE__c= bdeId; 
             a.Primary_CDE_DB_R__c= cdeId;
             
             imgas.add(a);
            insert imgas;
            
            
            List <Account> accounts = IMGAUtilities.instantiateAccounts (imgas);
            insert accounts;
            
            List<IMGA_Risk_Assessment__c> riskAssessList = new List<IMGA_Risk_Assessment__c>();
            IMGA_Risk_Assessment__c riskA = new IMGA_Risk_Assessment__c();
            riskA.at_risk_assessor__c = salesreps[0].Id;
            riskA.at_risk_override_date__c=system.today();
            riskA.at_risk_status__c = 'Accept Risk';
            riskA.imga_account__c=a.Id;
            
            riskAssessList.add(riskA);
            insert riskAssessList;
            
            List <ConnectApi.FeedItem> apiFeedList = IMGAAccountServices.sendImgaRiskNotifications(accounts);
            List<Id> imgaRiskList = IMGAAccountServices.getImgaRiskAssessorIds(a);
            List <ConnectApi.FeedItem> apiFeed = IMGAAccountServices.sendImgaRiskNotifications(imgas);
            List <ConnectApi.FeedItem> imgaRiskNotificationsList = IMGAAccountServices.sendImgaRiskNotifications(riskAssessList);
            Boolean bypassNotif = IMGAAccountServices.bypassNotification(a);
            Test.stopTest ();
    
    }
    }

}