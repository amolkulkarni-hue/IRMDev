/***************************************************************************************************
Class    :  IMGAUtilities.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :    June 15, 2013
Modified :  August 09, 2013
Objective:  This class provides methods to service other, especially test, classes. 

***************************************************************************************************/

public with sharing class IMGAUtilities
{
    //  public constants declared in alphabetical order
    //  Commenting because the record type is inactive. Gitlab story #28236
/*
    public static final String ACCOUNT_IMGA_AT_RISK_RECORDTYPE =
            [ select name from recordtype
               where sobjecttype = 'Account' and developername = 'IMGA_Record_Type_At_Risk' ].Name;
*/
    public static final String ACCOUNT_IMGA_RECORDTYPE =
            [ select name from recordtype
               where sobjecttype = 'Account' and developername = 'IMGA_Record_Type' ].Name;

     //  Commenting because the record type is inactive. Gitlab story #28236
/*
     public static final Id ACCOUNT_IMGA_AT_RISK_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'Account' and developername = 'IMGA_Record_Type_At_Risk' ].Id;
*/   
//Commenting as part of Gitlab #28236
   /* public static final Id M4_IMGA_ID =
            [ select id from recordtype
               where sobjecttype = 'M4_Revenue_Coverage__c' and developername = 'IMGA' ].Id;*/

    public static final Id ACCOUNT_IMGA_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'Account' and developername = 'IMGA_Record_Type' ].Id;

    public static final Id ACCOUNT_STANDARD_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'Account' and developername = 'Standard_Account' ].Id;
	
    //#30774: Decommission At Risk KPI Object and all related Components/References
    /*public static final Id AT_RISK_KPI_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'At_Risk_KPI__c' and developername = 'BW_NA_Risk_Assessment' ].Id;*/

    public static final Id BILLINGS_MANUAL_ENTRY_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'Billings__c' and developername = 'Manual_Entry' ].Id;

    public static final Id CUSTOMER_ACCOUNT_NA_AT_RISK_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'IM_Customer_Account__c'
                 and developername = 'NA_Customer_Account_At_Risk' ].Id;

    public static final Id CUSTOMER_ACCOUNT_NA_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'IM_Customer_Account__c'
                 and developername = 'NA_Customer_Account' ].Id;

    public static final Id DIVISION_NA_ID =
            [ select id from division where name = 'North America' ].Id;    

    public static final Id IMGA_RISK_ASSESSMENT_RECORDTYPE_ID =
            [ select id from recordtype
               where sobjecttype = 'IMGA_Risk_Assessment__c' and developername = 'At_Risk_BW' ].Id;

  /*  public static final Id USER_BDE_ROLE_ID =
            [ select id from userrole where developername = 'BDE_DB_R' ].Id;
	
    public static final Id USER_CDE_ROLE_ID =
            [ select id from userrole where developername = 'CDE_DB_R' ].Id;
	*/
    public static final Id USER_SALES_PROFILE_ID =
            [ select id from profile where name = 'IM_Sales' ].Id;

    //  public methods listed in alphabetical order
    public static List <User> insertSalesReps ()
    {
        List <User> salesreps = new List <User> (); 

        User bdeUser = instantiateUser ('bdeuser', 'John', 'Smythe', 'BDE');
        User cdeUser = instantiateUser ('cdeuser', 'Jane', 'Doe', 'CDE');

        insert bdeUser;
        insert cdeUser;     

        salesreps.add (bdeUser);
        salesreps.add (cdeUser);

        return salesreps;

    }   //  insertSalesReps ()

    public static List <Account> instantiateAccounts ( List <Account> imgas )
    {
        Account account = null;
        List <Account> accounts = new List <Account> ();        

        for ( Account imga : imgas )
        {
            account = new Account ();

            account.Name         = imga.Name;
            account.ParentId     = imga.Id; 
            account.RecordTypeId = ACCOUNT_STANDARD_RECORDTYPE_ID;
            account.Type         = 'Customer';

            accounts.add (account);

        }   //  each account in accounts

        return accounts;

    }   //  instantiateAccounts ()

    //#30774: Decommission At Risk KPI Object and all related Components/References
    /*public static List <At_Risk_KPI__c> intantiateAtRiskKpis ( List <IM_Customer_Account__c> customerAccounts )
    {
        At_Risk_KPI__c atRiskKpi = null;
        List <At_Risk_KPI__c> atRiskKpis = new List <At_Risk_KPI__c> ();
        Integer atRiskScore = 0;
        Double price = null;
        Double relationship = null;
        final String segment = 'Medium Risk - Priority 2';
        Double service = null;

        for ( IM_Customer_Account__c customerAccount : customerAccounts )
        {
            atRiskScore ++;

            if ( atRiskScore > 10 )
                atRiskScore = 1;

            price = atRiskScore / 100;
            relationship = atRiskScore / 50;
            service = 1 - ( price + relationship ); 

            atRiskKpi = new At_Risk_KPI__c ();

            atRiskKpi.Avg_Monthly_Incoming_Requests_6_Mos__c  = atRiskScore;
            atRiskKpi.Avg_Monthly_Meeting_Activities_6_Mos__c = atRiskScore;
            atRiskKpi.Customer_Account__c                     = customerAccount.Id;
            atRiskKpi.DBR_At_Risk_Score__c                    = atRiskScore;
            atRiskKpi.DBR_Monthly_Value__c                    = 100 * atRiskScore;
            atRiskKpi.DBR_Price__c                            = price;
            atRiskKpi.DBR_Relationship__c                     = relationship;
            atRiskKpi.DBR_Segment__c                          = segment;
            atRiskKpi.DBR_Service__c                          = service;
            atRiskKpi.Incoming_Service_Request_Last_6_Mos__c  = atRiskScore;               
            atRiskKpi.Overall_At_Risk_Score__c                = atRiskScore;
            atRiskKpi.Overall_Price__c                        = price;
            atRiskKpi.Overall_Relationship__c                 = relationship;
            atRiskKpi.Overall_Service__c                      = service;
            atRiskKpi.RM_At_Risk_Score__c                     = atRiskScore;
            atRiskKpi.RM_Monthly_Value__c                     = 100 * atRiskScore;
            atRiskKpi.RM_Price__c                             = price;
            atRiskKpi.RM_Relationship__c                      = relationship;
            atRiskKpi.RM_Segment__c                           = segment;
            atRiskKpi.RM_Service__c                           = service;
            atRiskKpi.Segment__c                              = segment;
            atRiskKpi.Shred_At_Risk_Score__c                  = atRiskScore;
            atRiskKpi.Shred_Monthly_Value__c                  = 100 * atRiskScore;
            atRiskKpi.Shred_Price__c                          = price;
            atRiskKpi.Shred_Relationship__c                   = relationship;
            atRiskKpi.Segment__c                              = segment;
            atRiskKpi.Shred_Service__c                        = service;
            atRiskKpi.Total_Distinct_Bill_Codes_in_year__c    = 5 * atRiskScore;
            atRiskKpi.Total_Incoming_Requests_last_6_mos__c   = 6 * atRiskScore;
            atRiskKpi.Total_Meeting_Activities_Last_6_Mos__c  = 4 * atRiskScore;

            atRiskKpis.add (atRiskKpi); 

        }   //  each customer account in customerAccounts

        return atRiskKpis;

    }   //  intantiateAtRiskKpis ()*/

//Commenting as part of Gitlab #28236    
    /*public static M4_Revenue_Coverage__c createTestM4(Id imgaId, Id pbmId, String countryCoverage, String productCoverages) 
    {
        M4_Revenue_Coverage__c m4 = new M4_Revenue_Coverage__c();
        m4.Account__c = imgaId;
        m4.Parent_Billing_Market__c = pbmId;
        m4.Country_Coverage__c = countryCoverage;
        m4.Product_Coverage__c = productCoverages;
        m4.RecordTypeId = M4_IMGA_ID;
        return m4;
    }*/

    public static Billings__c createTestBilling(Id customerAccountId, Date invoiceDate, Id billingMarketId, Id productId)
    {
        Billings__c billing         = new Billings__c ();   
        billing.Business_Line__c    = 'Secure Shredding';
        billing.Customer_Account__c = customerAccountId;
        billing.Entry_Date__c       = Date.today ();
        billing.Invoice_Date__c     = invoiceDate;
        billing.Source_System__c    = 'Test source system';
        billing.Unit_Qty__c         = 1;
        billing.Unit_Rate__c        = 11;
        billing.Billing_Market__c   = billingMarketId;
        billing.Bill_Code__c        = productId;
        return billing;
    }

    public static List <Billings__c> instantiateBillings ( List <IM_Customer_Account__c> customerAccounts )
    {
        Billings__c billing = null;
        List <Billings__c> billings = new List <Billings__c> ();
        Integer businessLine = 0;

        for ( IM_Customer_Account__c customerAccount : customerAccounts )
        {
            billing = new Billings__c ();         

            businessLine ++;

            if ( businessLine > 4 )
                businessLine = 1;

            if ( businessLine == 1)
                billing.Business_Line__c = 'Data Backup & Recovery';

            else if ( businessLine == 2)
                billing.Business_Line__c = 'Document Management Solutions';

            else if ( businessLine == 3)
                billing.Business_Line__c = 'Records Management';

            else
                billing.Business_Line__c = 'Secure Shredding';

            billing.Customer_Account__c = customerAccount.Id;
            billing.Entry_Date__c       = Date.today ();
            billing.Invoice_Date__c     = Date.today ().addMonths (-5 * businessLine);
            billing.Source_System__c    = customerAccount.Source_System__c;
            billing.Unit_Qty__c         = businessLine;
            billing.Unit_Rate__c        = businessLine + 10;

            billings.add (billing);

        }   //  each customer account in customerAccounts

        return billings;

    }   //  instantiateBillings ()

    public static List <Contact> instantiateContacts ( List <Account> accounts )
    {
        Contact contact = null;
        List <Contact> contacts = new List <Contact> ();

        for ( Account account : accounts )
        {
            contact = new Contact ();

            contact.AccountId         = account.Id;
            contact.Email             = 'sally@' + account.Name + '.com';
            contact.FirstName         = 'Sally';
            contact.LastName          = account.Name;
            contact.MailingCity       = 'Richardson';
            contact.MailingCountry    = 'USA';
            contact.MailingPostalCode = '75081';
            contact.MailingState      = 'TX';
            contact.MailingStreet     = '100 Centennial Blvd';

            contacts.add (contact);

        }   //  each account in accounts

        return contacts;

    }   //  instantiateContacts ()

//Commenting as part of Gitlab #28236

    /*public static List <BoB_Coverage__c> instantiateCoverages ( List <Account> accounts, Id salesRepId )
    {
        BoB_Coverage__c coverage = null;
        List <BoB_Coverage__c> coverages = new List <BoB_Coverage__c> ();

        for ( Account account : accounts )
        {
            coverage = new BoB_Coverage__c ();

            coverage.Account__c          = account.id;
            coverage.Country_Coverage__c = 'North America';
            coverage.Name                = account.Name + ' Coverage';    
            coverage.Product_Coverage__c = 'Data Backup & Recovery';
            coverage.Sales_Rep_Name__c   = salesRepId;
            coverage.Sales_Rep_Role__c   = 'Sales-BDE Hybrid';

            coverages.add (coverage);

        }

        return coverages;
    
    }   //  instantiateCoverages ()
*/
    public static List <IM_Customer_Account__c> instantiateCustomerAccounts ( List <Account> accounts )
    {
        IM_Customer_Account__c customerAccount = null;
        List <IM_Customer_Account__c> customerAccounts = new List <IM_Customer_Account__c> ();
        String accountSuffix = null;

        for ( Account account : accounts )
        {
            for ( Integer i = 0 ; i < 20 ; i ++ )
            {
                customerAccount = new IM_Customer_Account__c ();         
            
                if ( i < 10 )
                    accountSuffix = '0' + i;

                else
                    accountSuffix = String.valueOf (i);

                customerAccount.IM_Account__c      = account.Id;
                customerAccount.IM_Status__c       = 'Active';
                customerAccount.Name               = account.Name + ' CID ' + accountSuffix;
                customerAccount.Source_System__c   = 'SKP NA';

                customerAccounts.add (customerAccount);

            }   //  50 iterations

        }   //  each account in accounts

        return customerAccounts;

    }   //  instantiateCustomerAccounts ()

    public static List <Account> instantiateImgaAccounts ( Integer count, Id bdeId, Id cdeId )
    {
        Account imgaAccount = null;
        List <Account> imgaAccounts = new List <Account> ();
        String accountSuffix = null;
        Integer atRiskScore = null;
        Id recordTypeId = null;

        if ( count > 50 )
            count = 50;

        for ( Integer i = 0 ; i < count ; i ++ )
        {
            imgaAccount = new Account ();          
            
            if ( i < 10 )
            {
                accountSuffix = '00' + i;
                atRiskScore = 7;
                recordTypeId = ACCOUNT_IMGA_RECORDTYPE_ID;//Replacing the record type 'IMGA_Record_Type_At_Risk', because it is inactive. Gitlab #28236


            }

            else if ( i < 30 )
            {          
                accountSuffix = '0' + i;
                atRiskScore = 10;
                recordTypeId = ACCOUNT_IMGA_RECORDTYPE_ID; //Replacing the record type 'IMGA_Record_Type_At_Risk', because it is inactive. Gitlab #28236

            }

            else
            {
                accountSuffix = String.valueOf (i);
                atRiskScore = 4;
                recordTypeId = ACCOUNT_IMGA_RECORDTYPE_ID;

            }   //  first ten accounts instantiated

            imgaAccount.At_Risk_Score__c       = atRiskScore;
            imgaAccount.DBR_At_Risk_Score__c   = atRiskScore;
            imgaAccount.Name                   = 'bwtestimga' + accountSuffix;
            imgaAccount.Primary_BDE__c         = bdeId;
            imgaAccount.Primary_BDE_DB_R__c    = bdeId;
            imgaAccount.Primary_CDE__c         = cdeId;
            imgaAccount.Primary_CDE_DB_R__c    = cdeId;
            imgaAccount.RecordTypeId           = recordTypeId;
            imgaAccount.IM_Hierarchy_Level__c  = 'IM Group (IMGA)';
            imgaAccount.IM_IMGA_Indexed__c     = 'IMGA Name ' + i;

            if ( math.Mod (i, 2) == 0 )
                imgaAccount.Shred_At_Risk_Score__c = atRiskScore;

            else
                imgaAccount.Shred_At_Risk_Score__c = 7;

            imgaAccount.Type                   = 'Customer';

            imgaAccounts.add (imgaAccount);

        }   //  count iterations

        return imgaAccounts;

    }   //  instantiateImgaAccounts ()

    public static List <IMGA_Risk_Assessment__c> instatiateImgaRiskAssessments ( List <Account> imgas )
    {
        IMGA_Risk_Assessment__c imgaRiskAssessment = null;
        List <IMGA_Risk_Assessment__c> imgaRiskAssessments = new List <IMGA_Risk_Assessment__c> ();

        for ( Account imga : imgas )
        {
            imgaRiskAssessment = new IMGA_Risk_Assessment__c ();

            imgaRiskAssessment.At_Risk_Override_Date__c = Date.today ().AddDays (-61);
            imgaRiskAssessment.IMGA_Account__c = imga.Id;

            imgaRiskAssessments.add (imgaRiskAssessment);

        }   //  each imga in imgas

        return imgaRiskAssessments;

    }   //  instatiateImgaRiskAssessments ()

    //  private methods listed in alphabetical order
    private static User instantiateUser ( String alias, String fName, String lName, String type )
    {
        User user = new User ();
  
        user.Alias             = alias;
        user.Country           = 'USA';
        user.DefaultDivision   = DIVISION_NA_ID;
        user.Email             = alias + '@bluewolfgroup.com';
        user.EmailEncodingKey  = 'ISO-8859-1';
        user.FirstName         = fName;
        user.LanguageLocaleKey = 'en_US';
        user.LastName          = lName;
        user.LocaleSidKey      = 'en_US';
        user.ProfileId         = USER_SALES_PROFILE_ID;
  		UserRole USER_BDE_ROLE_ID = new UserRole(name='BDE_DB_R');
        insert USER_BDE_ROLE_ID;
        
        UserRole USER_CDE_ROLE_ID = new UserRole(name='CDE_DB_R');
        insert USER_CDE_ROLE_ID;
        
        if ( type.equals ('BDE') )
            user.UserRoleId    = USER_BDE_ROLE_ID.Id;

        else
            user.UserRoleId    = USER_CDE_ROLE_ID.id;

        user.TimeZoneSidKey    = 'America/Chicago';
        user.Username          = alias + '@bluewolfgroup.com';

        return user;

    }   //  instantiateUser ()

}