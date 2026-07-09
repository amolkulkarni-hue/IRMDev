/**
     * Modified By: Keerthi Senthilnathan on 21-May-2018 
     *          -- Modified Non_Standard_Setup__c field value to 'No'
     *          -- Case # 07485178
     * 
     *  *Modified By: Revathy Saminathan on 19-Nov-2019
     *          -- Case # 08408424
     *          -- Removed the Recall Onboarding Queue and Recall onBoarding record
     *             for the Decommission Recall Onboarding Queue
     * 
     *  *Modified By: Revathy Saminathan on 12-Dec-2019
     *          -- Case # 08408424
     *          -- Removed the Recall Onboarding Queue and Recall onBoarding record
     *             for the Decommission Recall Onboarding Queue production issue fix
     * Modified By: Renuka Prasad on 26-Mar-2024
     *          -- Gitlab Story #22791
     *          -- Replacing Billing Account instead of Customer ID for SITAD UpSell
**/

public with sharing class NCSPWizardCtrl {

/****************************Constants ****************************************/

    public static final String OPP_ID_PARAM = 'oppId';
    public static final String NEW_DEAL = 'New Deal';
    public static final String SERVICE_LINE_RM = 'RM';
    public static final String SERVICE_LINE_SHRED = 'Shred';
    public static final String SERVICE_LINE_ONE_TIME_SHRED = 'One Time Shred';
    public static final String SERVICE_LINE_DBnR = 'DB&R';
    public static final String SERVICE_LINE_DMS = 'DMS';
    public static final String SERVICE_LINE_PATHOLOGY = 'RM Pathology';
    public static final String SERVICE_LINE_VAULT_CLIMATE = 'Vault Climate Control';
    public static final String DMS_TYPE_CONVERSION_SERVICES  = 'Conversion Services';
    public static final String DMS_TYPE_CONVERSION_SERVICES_W_DRCI  = 'Conversion Services with DRCI';

    public static final String CLOUD_BLUE = 'CloudBlue';
    public static final String LIBRARY_MOVE = 'Library Move';

    public static final String STANDARD_SETUP_TYPE = 'Standard';
    public static final String HEALTHCARE_ACCOUNT_TYPE = 'Healthcare Account';
    public static final String STATUS_NEW = 'New';
    public static final String NEW_SERVICE_LINE = 'New Service Line';
    public static final String UPSELL_TYPE = 'Up-Sell/Lift';
    public static final String YES = 'Yes';
    public static final String NO  = 'No';


    public static final String DEAL_TYPE_UPSELL = 'Upsell';
    public static final String DEAL_TYPE_DEPARMENT_ADD = 'Department Add';

    public static final String UPSELL_TYPE_SERVICE_FREQUENCY = 'Service Frequency';
    public static final String UPSELL_TYPE_SUPPLY_INCREASE = 'Supply Increase';
    public static final String UPSELL_TYPE_STORAGE_INCREASE = 'Storage Increase';
    public static final String UPSELL_TYPE_INVENTORY_TRANSFER = 'Inventory Transfer';
    public static final String UPSELL_TYPE_MEDIA_DESTRUCTION = 'Media Destruction';

    public static final String DMS_LITIGATION_RUSH_COMMENT = 'DMS Litigation';
    public static final String HEALTHCARE_TYPE = 'Healthcare';
    public static final String TAPE_CATALOG_MANAGER = 'Tape Catalog Manager';
    public static final String TAPE_VAULTING = 'Tape Vaulting';
    
    public static final String NCSP_WIZARD_FREE_UP_IN = 'ncspwizardfreeupin';
    public static final String DM_SITAD_PRIMARY_PRODUCT_LINE = 'DM SITAD'; //Changes for Story #22791
    
/****************************Properties****************************************/

    public Opportunity opportunity {get; set;}
    public CaseComment casecomment {get; set;}
    public final Customer_Profile__c profile {get; private set;}
    public final Case ncspCase {get; private set;}

    public transient String contactSearchTerm {get; set;}
    public transient List<Contact> contacts {get; set;}

    public Boolean isHealthcareAccountStoringPatientRecords {get; set;}
    public Contact selectedContact {get; set;}
    public Contact BillingContact {get; set;}
    public String step1Title {get; private set;}
    public Boolean showMainFrame {get; private set;}
    public Boolean isNewDeal {get; private set;}
    public Boolean isUpsell {get; private set;}
    public Boolean isBundle {get; private set;}
    public Boolean isOpportunityHealthCare {get; private set;}
    public Boolean doCreateNewContact {get; private set;}
    public Boolean isInternational {get;private set;}
    public ID internationalCaseOwnerID {get;set;}
    /* Devloper Name:Madhu Paladugu
       Case Number  :01045376
        Discription  : Added the following assignment statement
      */
    public String CURRENT_USER_PROFILE;
    
    //following line commented as we are including cluster1 countries @Thri
    //public Boolean isNASitad {get; private set;} //Changes for Story #22791

    public Boolean isSitadCluster {get; private set;} //@Thri changes for SITAD Cluster1 countries

    public Boolean hasEditableDealTypeOnOverview
    {
        get
        {
            Set<String> noneditableDealTypes = new Set<String>{DEAL_TYPE_UPSELL, DEAL_TYPE_DEPARMENT_ADD, NEW_SERVICE_LINE};
            return  !noneditableDealTypes.contains(profile.Deal_Type__c);
        }
    }


    public Boolean isDBRFrequencyNeeded
    {
        get
        {
            return (profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY && profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR && profile.Supplies_Order_Required__c  == YES )
                   ||
                    (profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY && profile.Second_Service_Line__c == SERVICE_LINE_DBnR && profile.Second_Supplies_Order_Required__c == YES);
        }
    }

    public Boolean isOTSBoxQuantityDisabled
    {
        get
        {
            return !(profile.NCSP_Upsell_Type__c == 'Paper Destruction' && profile.NCSP_Service_Line__c == 'One Time Shred'
                       ||
                      (profile.Second_NCSP_Upsell_Type__c == 'Paper Destruction' && profile.Second_Service_Line__c == 'One Time Shred'))
            ;
        }
    }

    public Boolean isShredServiceFrequencyDisabled
    {
        get
        {
            return profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE || profile.NCSP_Upsell_Type__c == 'Paper Destruction';
        }
    }

    public Boolean isContainerTypeDisabled
    {
        get
        {
            Set<String> eligibleServiceLine = new Set<String>{SERVICE_LINE_DBnR};

            return ( this.isNewDeal && profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR && profile.Supplies_Order_Required__c  == NO )
                    ||
                    ( eligibleServiceLine.contains(profile.NCSP_Service_Line__c)   && ( ( profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY && profile.Supplies_Order_Required__c  == NO )  || profile.NCSP_Upsell_Type__c == UPSELL_TYPE_MEDIA_DESTRUCTION ) )
                   ||
                    ( eligibleServiceLine.contains(profile.Second_Service_Line__c) && ( (profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY  && profile.Second_Supplies_Order_Required__c  == NO ) || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_MEDIA_DESTRUCTION ) );
        }
    }

    public Boolean isContainerQuantityDisabled
    {
        get
        {
            return isContainerTypeDisabled;
        }
    }

    public Boolean isServiceFrequencyDisabled
    {
        get
        {
            Set<String> eligibleUpsellTypes = new Set<String>{UPSELL_TYPE_SUPPLY_INCREASE};
            Set<String> eligibleServiceLine = new Set<String>{SERVICE_LINE_DBnR};
            return ( this.isNewDeal ||
                     ( eligibleUpsellTypes.contains(profile.NCSP_Upsell_Type__c) && eligibleServiceLine.contains(profile.NCSP_Service_Line__c) ) ||
                     ( eligibleUpsellTypes.contains(profile.Second_NCSP_Upsell_Type__c) && eligibleServiceLine.contains(profile.Second_Service_Line__c) )
            );

        }
    }

    public Boolean isPreferredServiceDaysDisabled
    {
        get
        {
            return ! this.isNewDeal;

        }
    }

    public Boolean isBoxQuantityDisabled
    {
        get
        {
            return ( this.isNewDeal ||
                     ( profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR && (profile.NCSP_Upsell_Type__c == UPSELL_TYPE_STORAGE_INCREASE || profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE ||profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY) )  ||
                     ( profile.Second_Service_Line__c == SERVICE_LINE_DBnR && (profile.Second_NCSP_Upsell_Type__c ==  UPSELL_TYPE_STORAGE_INCREASE || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY) )
            );
        }
    }

    public Boolean isBoxQuantityRequired
    {
        get
        {
            return (
                     (profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR   && profile.NCSP_Upsell_Type__c        == UPSELL_TYPE_MEDIA_DESTRUCTION )||
                     (profile.Second_Service_Line__c == SERVICE_LINE_DBnR && profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_MEDIA_DESTRUCTION )
            );
        }
    }

    public Boolean isTapeQuantityDisabled
    {
        get
        {
            return ( this.isNewDeal ||
                     (profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR && ( profile.NCSP_Upsell_Type__c == UPSELL_TYPE_STORAGE_INCREASE || profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE ||profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY ) )||
                     (profile.Second_Service_Line__c == SERVICE_LINE_DBnR && (profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_STORAGE_INCREASE || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY))
            );
        }
    }

    public Boolean isTapeQuantityRequired
    {
        get
        {
            return (
                     (profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR   && profile.NCSP_Upsell_Type__c        == UPSELL_TYPE_MEDIA_DESTRUCTION )||
                     (profile.Second_Service_Line__c == SERVICE_LINE_DBnR && profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_MEDIA_DESTRUCTION )
            );
        }
    }

    public Boolean isAuthorizationNumberDisabled
    {
        get
        {
            return ( profile.NCSP_Service_Line__c != SERVICE_LINE_DBnR  && profile.Second_Service_Line__c != SERVICE_LINE_DBnR );
        }
    }

    public Boolean isQuantityConsolesDisabled
    {
        get
        {
            return !(profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE);
        }
    }

    public Boolean isShredServiceDisabled
    {
        get
        {
            return !(profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY);
        }
    }

    public Boolean isShredQuantityConsolesOrderedEnable
    {
        get
        {
            Set<String> eligibleUpsellTypes = new Set<String>{UPSELL_TYPE_SUPPLY_INCREASE, UPSELL_TYPE_SERVICE_FREQUENCY};
            return ( this.isNewDeal || eligibleUpsellTypes.contains(profile.NCSP_Upsell_Type__c) || eligibleUpsellTypes.contains(profile.Second_NCSP_Upsell_Type__c) );
        }
    }

    public Boolean isShredQuantity65GallonOrderedEnable
    {
        get
        {
            Set<String> eligibleUpsellTypes = new Set<String>{UPSELL_TYPE_SUPPLY_INCREASE, UPSELL_TYPE_SERVICE_FREQUENCY};
            return ( this.isNewDeal || eligibleUpsellTypes.contains(profile.NCSP_Upsell_Type__c) || eligibleUpsellTypes.contains(profile.NCSP_Service_Line__c) );
        }
    }

    public Boolean isOTSBoxQuantityEnable
    {
        get
        {
            Set<String> eligibleDealTypes = new Set<String>{'New Service Line', 'New Deal', 'Department Add' };
            return (    ( profile.NCSP_Service_Line__c       == SERVICE_LINE_ONE_TIME_SHRED && ( profile.NCSP_Upsell_Type__c        == 'Paper Destruction' || eligibleDealTypes.contains( profile.Deal_Type__c ) ) )
                      || ( profile.Second_NCSP_Upsell_Type__c == SERVICE_LINE_ONE_TIME_SHRED && ( profile.Second_NCSP_Upsell_Type__c == 'Paper Destruction' || eligibleDealTypes.contains( profile.Deal_Type__c ) ) )
                    );
        }
    }

    public Boolean isOTSQuantityConsolesOrderedEnable
    {
        get{
            return  (profile.NCSP_Service_Line__c == SERVICE_LINE_ONE_TIME_SHRED && profile.Supplies_Order_Required__c  == YES) ||
                     ( profile.Second_Service_Line__c == SERVICE_LINE_ONE_TIME_SHRED && profile.Second_Supplies_Order_Required__c == YES );
        }
    }

    public Boolean isOTSQuantity65GallonOrdered
    {
        get{
            return isOTSQuantityConsolesOrderedEnable;
        }
    }


    public Boolean isQuantity65GallonDisabled
    {
        get
        {
            return !(profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE || profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SUPPLY_INCREASE);
        }
    }

    public List<Attachment> attachments {
        get {
            if ( null == internal_attachments )
                internal_attachments = [SELECT Id, Name, LastModifiedDate, CreatedBy.Name FROM Attachment WHERE ParentId = :opportunityId ];
            return internal_attachments;
        }
    }

    public Boolean isRM{
        get{
            return  ( ( profile.NCSP_Service_Line__c == SERVICE_LINE_RM && profile.Supplies_Order_Required__c  == YES )  ||
                (profile.Second_Service_Line__c == SERVICE_LINE_RM && profile.Second_Supplies_Order_Required__c == YES ) );
        }
    }
        

    public Boolean isCloudBlue
    {
        get
        {
            return ( profile.NCSP_Upsell_Type__c == CLOUD_BLUE || profile.Second_NCSP_Upsell_Type__c == CLOUD_BLUE );
        }
    }

    public Boolean isDBnREnabled{
        get{
            return ( ( profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR && profile.NCSP_Upsell_Type__c != CLOUD_BLUE && profile.NCSP_Upsell_Type__c != LIBRARY_MOVE && profile.Supplies_Order_Required__c  == YES )
                || ( profile.Second_Service_Line__c == SERVICE_LINE_DBnR && profile.Second_NCSP_Upsell_Type__c != CLOUD_BLUE && profile.Second_NCSP_Upsell_Type__c != LIBRARY_MOVE && profile.Second_Supplies_Order_Required__c == YES) );
        }
    }

    public Boolean isDBnRSO{
        get{
            return  ( ( isDBnREnabled && profile.Supplies_Order_Required__c  == YES )  ||
                (isDBnREnabled && profile.Second_Supplies_Order_Required__c == YES ) );
        }
    }
    
    public Set<String> eligibleNonStandardSetupServiceLineItems
    {
        get
        {
            Set<String> nonStandardSetupPageEligible = new Set<String>{SERVICE_LINE_ONE_TIME_SHRED, SERVICE_LINE_DBnR, SERVICE_LINE_RM, SERVICE_LINE_PATHOLOGY, SERVICE_LINE_VAULT_CLIMATE, SERVICE_LINE_SHRED};
            return nonStandardSetupPageEligible;
        }
    }

    public Boolean isNonStandardFieldsEnable{
        get{
            Set<String> validServiceLines = new Set<String>{    SERVICE_LINE_RM, SERVICE_LINE_ONE_TIME_SHRED, SERVICE_LINE_SHRED, SERVICE_LINE_PATHOLOGY, SERVICE_LINE_VAULT_CLIMATE};
            return validServiceLines.contains(profile.NCSP_Service_Line__c) || validServiceLines.contains(profile.Second_Service_Line__c);
        }
    }

    public Boolean isDBnR{
        get{
            return profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR || profile.Second_Service_Line__c == SERVICE_LINE_DBnR;
        }
    }

    public Boolean isShred{
        get{
            return ( ( profile.NCSP_Service_Line__c == SERVICE_LINE_SHRED && profile.Supplies_Order_Required__c  == YES )
                || ( profile.Second_Service_Line__c == SERVICE_LINE_SHRED && profile.Second_Supplies_Order_Required__c == YES ) );
        }
    }

    public Boolean isShredFrequencyNeeded{
        get{
            return ( profile.NCSP_Service_Line__c == SERVICE_LINE_SHRED && profile.NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY )
                || ( profile.Second_Service_Line__c == SERVICE_LINE_SHRED && (profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_SERVICE_FREQUENCY ) );
        }
    }


    public Boolean isOneTimeShred{
        get{
            return ( profile.NCSP_Service_Line__c == SERVICE_LINE_ONE_TIME_SHRED || profile.Second_Service_Line__c == SERVICE_LINE_ONE_TIME_SHRED ) ;
        }
    }

    public Boolean isDMSConfigNeeded{
        get{
            return ( ( profile.NCSP_Service_Line__c == SERVICE_LINE_DMS && ( profile.DMS_Type__c == DMS_TYPE_CONVERSION_SERVICES || profile.DMS_Type__c == DMS_TYPE_CONVERSION_SERVICES_W_DRCI ) )
                    || ( profile.Second_Service_Line__c == SERVICE_LINE_DMS && ( profile.DMS_Type__c == DMS_TYPE_CONVERSION_SERVICES || profile.DMS_Type__c == DMS_TYPE_CONVERSION_SERVICES_W_DRCI ) ) ) ;
        }
    }

    public Boolean isDMS{
        get{
            return ( ( profile.NCSP_Service_Line__c == SERVICE_LINE_DMS && profile.Supplies_Order_Required__c  == YES )
                    || ( profile.Second_Service_Line__c == SERVICE_LINE_DMS && profile.Second_Supplies_Order_Required__c == YES ) ) ;
        }
    }

    public Boolean isHealthcare {
        get{
            return false;
        }
    }

    public Boolean isFreeUpIn{
        get{
            return  ( profile.Free_Up_In__c == YES  && ( profile.NCSP_Service_Line__c == SERVICE_LINE_RM || profile.Second_Service_Line__c == SERVICE_LINE_RM ) && (! Apexpages.currentPage().getUrl().toLowerCase().contains(NCSP_WIZARD_FREE_UP_IN)));  
        }
    }
    
    public static List<RecordType> recordCreatedInWizard
    {
        get
        {
            if( recordCreatedInWizard == null)
            {
                List<String> recordNames = new List<String>{ 'NCSP_Upsell', 'NCSP_SKP_Department_Add_Only', 'NCSP_SKP_New_customer_setup','NCSP_New_Customer_Setup',
                                                              'NCSP_Tech_Services_New_Customer_Setup', 'NCSP_DP_Onboarding_team', 'NCSP_DMS'};
                recordCreatedInWizard = [SELECT Id FROM RecordType WHERE DeveloperName IN :recordNames];
            }
            return recordCreatedInWizard;
        }
    }

    public Id standardCaseQueueId
    {
        get
        {
            if(standardCaseQueueId == null)
            {
                List<Group> groups = [Select Id, name from Group where name = 'NCSP FIFO (First in First out)'];
                if(groups.size() > 0)
                    standardCaseQueueId = groups[0].Id;
            }
            return standardCaseQueueId;
        }
        private set;
    }
    // Changes made by Venkateswarlu Avula realted to O2I Project
    public Id standardCaseQueueIdnew
    {
        get
        {
            if(standardCaseQueueIdnew == null)
            {
                List<Group> groups = [Select Id, name from Group where name = 'Data Entry'];
                if(groups.size() > 0)
                    standardCaseQueueIdnew = groups[0].Id;
            }
            return standardCaseQueueIdnew;
        }
        private set;
    }
    
    //Changed by Aditya for Recall onboarding FIFO Queue
  /*  public Id RecallCaseQueueId
    {
        get
        {
            if(RecallCaseQueueId== null)
            {
                List<Group> groups = [Select Id, name from Group where name = 'Recall Onboarding (FIFO)'];
                if(groups.size() > 0)
                    RecallCaseQueueId = groups[0].Id;
            }
            return RecallCaseQueueId;
        }
        private set;
    }*/

    public User opportunityOwner
    {
        get
        {
            if(opportunityOwner == null)
            {
                List<User> users = [Select Id, Profile.Name from User where id = :opportunity.OwnerId];
                if(users.size() > 0)
                    opportunityOwner = users[0];
            }
            return opportunityOwner;
        }
        private set;
    }
    public static User runningUser {
        get{
            if(runningUser == null){
                runningUser = [Select id, country from User where ID =: UserInfo.getUserId() limit 1];
            }
            return runningUser;
        } set;
    }

    public String insideSalesNameFactory
    {
        get
        {
             if(insideSalesNameFactory == null && opportunityOwner != null && (CURRENT_USER_PROFILE=='IM_Sales_eSignature' ||opportunityOwner.Profile.Name == 'IM_Sales_eSignature'))
            {
               /*Changed assiging value for case :01232624*/
                //insideSalesNameFactory = opportunity.OwnerId;
                if(opportunityOwner.Profile.Name =='IM_Sales_eSignature'){
                    insideSalesNameFactory=opportunity.OwnerId;
                }
                else{
                    insideSalesNameFactory = UserInfo.getUserId();
                }

            }
            return insideSalesNameFactory;
        }
        private set;
    }

    public String salesSupport
    {
        get
        {
            if(salesSupport == null && opportunityOwner != null && CURRENT_USER_PROFILE == 'IM_Sales_Support')
            {
                salesSupport = UserInfo.getUserId();
            }
            return salesSupport;
        }
        private set;
    }


    public List<SelectOption> rmSupplyBoxOrderTypeOptions
    {
        get
        {
            List<SelectOption> options = new List<SelectOption> { new SelectOption('', '--None--') };
            for(Schema.PicklistEntry pickVal : Schema.Customer_Profile__c.RM_Supply_Box_Order_Type__c.getDescribe().getPicklistValues())
            {
                options.add( new SelectOption(pickVal.getValue(), pickVal.getValue()) );
            }
            return options;
        }
    }

    public List<SelectOption> rmLabelTypeOptions
    {
        get
        {
            List<SelectOption> options = new List<SelectOption> { new SelectOption('', '--None--') };
            for(Schema.PicklistEntry pickVal : Schema.Customer_Profile__c.RM_Label_Type__c.getDescribe().getPicklistValues())
            {
                options.add( new SelectOption(pickVal.getValue(), pickVal.getValue()) );
            }
            return options;
        }
    }

    public List<NCSP_DBR_Products__c> NCSP_DBR_Products
    {
        get
        {
            if ( NCSP_DBR_Products == null )
            {
                NCSP_DBR_Products = NCSP_DBR_Products__c.getAll().values();
            }
            return NCSP_DBR_Products;
        }
        private set;
    }
    
    public List<String> selectedDBRProducts { get; set; }
    public List<SelectOption> DBRProductOptions
    {
        get
        {
            List<SelectOption> values = new List<SelectOption>();
            for ( NCSP_DBR_Products__c product : NCSP_DBR_Products )
            {
                Boolean newDeal = this.isNewDeal && product.Opportunity_Type__c ==  NEW_DEAL;
                Boolean upsell = this.isUpsell && UPSELL_TYPE.contains(String.ValueOf(product.Opportunity_Type__c));
                Boolean isSitadCluster = (this.opportunity.Primary_Product_Line__c == DM_SITAD_PRIMARY_PRODUCT_LINE &&
                    this.opportunity.QTB_Billing_Country_Name__c != null &&
                    System.Label.QTB_SITAD_Countries.contains(this.opportunity.QTB_Billing_Country_Name__c)); //Changes for Story #22791
                if ( newDeal || upsell )
                { 
                    values.add( new SelectOption( product.Name, product.Product_Name__c ) );
                }
            }
            return values;
        }
    }
    
    public List<SelectOption> splitTypeOptions {
        get{
            splitTypeOptions = new List<SelectOption>();
            splitTypeOptions.add(new SelectOption('100% / 0%', '100% / 0%'));
            
            if(isInternational != null && (!isInternational) ){
                splitTypeOptions.add(new SelectOption('75% / 75%', '75% / 75%'));
            }
            
            splitTypeOptions.add(new SelectOption('75% / 25%', '75% / 25%'));
            splitTypeOptions.add(new SelectOption('70% / 30%', '70% / 30%')); 
            splitTypeOptions.add(new SelectOption('50% / 50%', '50% / 50%'));
            splitTypeOptions.add(new SelectOption('25% / 75%', '25% / 75%'));
            
            if(isInternational != null && (!isInternational) ){
                splitTypeOptions.add(new SelectOption('100% / 100%', '100% / 100%'));
                splitTypeOptions.add(new SelectOption('100% / 75% / 25%', '100% / 75% / 25%'));
                splitTypeOptions.add(new SelectOption('75% / 100% / 25%', '75% / 100% / 25%'));
            }
            splitTypeOptions.add(new SelectOption('Custom', 'Custom'));
            
            return splitTypeOptions;
        } set;
    }
    
    
/*************************** Private Variables ********************************/

    private final Id opportunityId;
    private transient List<Attachment> internal_attachments;
    private List<PageReference> previous = new List<PageReference>();

    // Initialization block
    {
        showMainFrame = false;
        doCreateNewContact=true;
        ncspCase =  new Case ();
        casecomment = new CaseComment();
    }

    public NCSPWizardCtrl (){
        Profile CU_UR_PROFILE=[select Name from Profile where Id=:UserInfo.getProfileId()];
        CURRENT_USER_PROFILE=CU_UR_PROFILE.Name;

        this.opportunityId = Apexpages.currentPage().getParameters().get( OPP_ID_PARAM );

        // TODO : Add validations rules tro when this is accessible

        if( this.opportunityId == null )
        {
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , 'Opportunity Not Found') );
            return;
        }

        this.opportunity = [ SELECT Type, OwnerId, Owner.Name, AccountId, Upsell_Customer_ID__c,
                                      Upsell_Customer_ID__r.Name, Upsell_Customer_ID__r.Owning_District_Id__c, Account.IM_IMGA_Indexed__c,
                                      Upsell_Customer_ID__r.IM_Customer_Account_Name__c, Sales_Sub_Segment__c,/*,#16915 Bundle__c,*/
                                      Split_Type__c, Sales_Rep_Percent__c, Split_Rep_Percent__c, Split_Commission_Rep__c,
                                      Split_Rep_2_Percent__c, Split_Commission_Rep_2__c, DM_Quad_2_Account__c,
                                      QTB_Billing_Country_Name__c,Primary_Product_Line__c,  //Changes for Story #22791
                                      Billing_Account__r.Name,Billing_Account__r.Bill_To_Site_Number__c,Billing_Account__r.QTB_Market__c,
                                      (Select Id from Cases1__r where RecordTypeId in :recordCreatedInWizard LIMIT 1),
                                      Group_Purchasing_Organization_GPO__c
                             FROM Opportunity WHERE Id = :this.opportunityId ];

        if( opportunity.Cases1__r != null && opportunity.Cases1__r.size() > 0 ){
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Warning , Label.NCSP_Opportunity_with_cases_warning ) );
            return;
        }

        List< Customer_Profile__c > profiles = [Select Customer_Name__c, Service_District__c, Selling_District__c, Split_Commission_Rep__c,
                                                        Address__c, Address_Line_2__c, City__c, State_Province__c, Zip_Postal_Code__c, Country__c,
                                                        Same_as_Service_Address__c, Billing_Address__c, Billing_City__c, Billing_State_Province__c,
                                                        Billing_Zip_Postal_Code__c,Same_as_Service_Address_cor__c, Correspondence_Address__c,
                                                        Correspondence_City__c, Same_as_Billing_Address__c, Same_as_Current_Billing_Address__c,
                                                        Same_as_Current_Correspondence_Address__c, Correspondence_State_Province__c,
                                                        Correspondence_Zip_Postal_Code__c,NCSP_Service_Line__c, Second_Service_Line__c, DMS_Type__c,
                                                        NCSP_Upsell_Type__c , Second_NCSP_Upsell_Type__c, Non_Standard_Setup__c,Division_Enabled__c,
                                                        Department_Restricted__c,Remittance_Level__c,Department_Billing_Code__c,File_Level_Descriptive_Data_Entry__c,
                                                        Record_Code_Parameter__c,RM_Supply_Box_Order_Type__c,RM_Supply_Box_Order_Qty__c,RM_Label_Type__c,
                                                        RM_Label_Quantities__c,Customer_ID_for_Inventory_Transfer__c, Shred_Service_Frequency__c, Shred_Service_Method__c,
                                                        Shred_Quantity_Consoles_Ordered__c, Shred_Quantity_65_Gallon_Ordered__c, OTS_Box_Quantity__c,Shred_Gallon_Ordered__c,
                                                        DB_R_Container_Type__c,DB_R_Container_Quantity__c, DB_R_Consolidated_Invoices__c, Customer_ID_for_Consolidated_Billing__c,
                                                        DB_R_Service_Frequency__c, DB_R_Preferred_Service_Days__c, DB_R_Box_Quantity__c, DB_R_Tape_Quantity__c,
                                                        DB_R_Authorization_Number__c,Billing_Division__c, billing_department__c, imaging_center__c, PO_Number__c,
                                                        Special_Commission_Approval_Included__c, Separate_DMS_Invoice_Needed__c,Billing_for_Separator_Sheets__c,
                                                        Litigation_DMS__c, Sales_Rep_percent__c, Split_Rep_percent__c,Deal_Type__c,
                                                        OTS_Quantity_Consoles_Ordered__c,OTS_Service_Method__c,OTS_Quantity_65_Gallon_Ordered__c,OTS_Gallon_Ordered__c,
                                                        Billing_Country__c,Correspondence_Country__c,Supplies_Order_Required__c,Second_Supplies_Order_Required__c,
                                                       //8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/15/2022
                                                       /* Reason_No_Supply__c,*/Second_Reason_No_Supply__c, Primary_Service_Contact__c, DMS_Label_Quantities__c, DMS_Label_Type__c,
                                                        DMS_Supply_Box_Order_Qty__c, DMS_Supply_Box_Order_Type__c, Media_Destruction_Customer__c,
                                                        Case_Created__c, HealthcareAccountStoringPatientRecords__c, How_will_the_customer_store_records__c,
                                                        Individually_List_Files__c,Charges_Waived__c, Total_number_of_catalogs_requested__c, What_backup_software_is_used__c,
                                                        What_is_the_software_version__c, What_is_the_operating_system__c, Is_the_backup_system_alive__c, Billing_Contact__c, 
                                                        Correspondence_Contact__c, Invoice_Package__c, Invoice_Delivery_Method__c, Free_Up_In__c, Is_2000_Cube_Moving_via_Free_Up_In__c, 
                                                        Customer_Reimbursement_for_Term_Fees__c, Material_Moving_From_Another_Vendor__c, Group_Purchasing_Organization_GPO__c,
                                                        Group_Purchasing_Organization_Name__c,Autopay_Agreed__c,PO_Required__c,Billing_Contact_Phone__c,Billing_Contact_Email__c
                                                   FROM Customer_Profile__c WHERE Opportunity__c = :opportunityId ];
      //JM - Added "Billing Contact__c, Correspondence_Contacts__c, Invoice_Package__c, Invoice_Delivery_Method__c,"

        if ( profiles.isEmpty() ){
            this.profile = new Customer_Profile__c( Opportunity__c = opportunityId , OwnerId = opportunity.OwnerId );
        }else if ( profiles.size() == 1 ){
            this.profile = profiles[0];
        }else{
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , Label.NCSP_Opportunity_with_multiple_profile_error ) );
            return ;
        }

        //Changes for Story #22791
        if (UPSELL_TYPE.contains(String.ValueOf(this.opportunity.Type)) &&
            this.opportunity.Primary_Product_Line__c == DM_SITAD_PRIMARY_PRODUCT_LINE &&
            this.opportunity.QTB_Billing_Country_Name__c != null &&
            System.Label.QTB_SITAD_Countries.contains(this.opportunity.QTB_Billing_Country_Name__c)
        ) {
            this.profile.Customer_Name__c = opportunity.Billing_Account__r.Name;
            this.profile.Service_District__c = opportunity.Billing_Account__r.QTB_Market__c;
            System.debug('this.profile.Customer_Name__c>>>789'+this.profile.Customer_Name__c);
            System.debug('this.profile.Service_District__c>>>790'+this.profile.Service_District__c);
        } else if (UPSELL_TYPE.contains(String.ValueOf(this.opportunity.Type)))
        {
            this.profile.Customer_Name__c = opportunity.Upsell_Customer_ID__r.IM_Customer_Account_Name__c;
            this.profile.Service_District__c = opportunity.Upsell_Customer_ID__r.Owning_District_Id__c;
        }else if( NEW_DEAL == this.opportunity.Type   )
        {
            this.profile.Deal_Type__c = NEW_DEAL;
        }

        this.isNewDeal = ( this.opportunity.Type == NEW_DEAL );
        
        this.isUpsell = (UPSELL_TYPE.contains(String.ValueOf(this.opportunity.Type)));
        this.isUpsell = (UPSELL_TYPE.contains(String.ValueOf(this.opportunity.Type)));
        Boolean isSitadCluster = (this.opportunity.Primary_Product_Line__c == DM_SITAD_PRIMARY_PRODUCT_LINE &&  //Changes for Story #22791
            this.opportunity.QTB_Billing_Country_Name__c != null &&
            System.Label.QTB_SITAD_Countries.contains(this.opportunity.QTB_Billing_Country_Name__c));
        // #16915 this.isBundle = String.isNotEmpty( this.opportunity.Bundle__c );
        this.showMainFrame = true;

        this.isOpportunityHealthCare = ( this.opportunity.Sales_Sub_Segment__c == HEALTHCARE_TYPE );
        
        NCSP_International_Countries__c ncspCountry = NCSP_International_Countries__c.getValues(runningUser.country);
        
        if(ncspCountry != null ) {
            if( ncspCountry.Recordtype_ID_18__c != null) {
                this.profile.RecordTypeID = ncspCountry.Recordtype_ID_18__c;
            }
            if(ncspCountry.Case_Owner_ID__c != null) {
                internationalCaseOwnerID = ncspCountry.Case_Owner_ID__c;
            }
        }
        isInternational = !(runningUser.country =='United States' || runningUser.country =='Canada' );
        step1Title = (isInternational) ? 'Service/Contract Related Attachments' : 'Contract Package Information' ;
        
    }
    /*
        Search contacts
    */
    public void searchContacts (){
        
        String Str_Imga_Indexed;
        if(this.opportunity.Account.IM_IMGA_Indexed__c!=Null)        
        { Str_Imga_Indexed = this.opportunity.Account.IM_IMGA_Indexed__c.replace('\'','\\\''); }
        String soql = 'SELECT Id,FirstName,LastName,Phone,Email, AccountId, MailingCity,MailingState, MailingCountry, Primary_NCSP_Contact__c FROM Contact ' + 
                      'WHERE (AccountId = \'' + this.opportunity.AccountId + '\' OR Account.IM_IMGA_Indexed__c = \'' + Str_Imga_Indexed + '\')';
         
        if (contactSearchTerm != null){
            contactSearchTerm=contactSearchTerm.replace('\'','\\\'') ;
            soql += ' AND (Name LIKE \'%' + contactSearchTerm +'%\')';
        } else {
            soql += ' AND Primary_NCSP_Contact__c = true';
        }        
        soql +=' ORDER BY Primary_NCSP_Contact__c DESC, LastName LIMIT 200'; 
        contacts = Database.query ( soql ); 
        
    }
    
    public void fetchcontact(){
        BillingContact = [SELECT Id, Name, Phone,Email FROM Contact WHERE Id = : this.profile.Billing_Contact__c ];
        profile.Billing_Contact_Email__c = BillingContact.Email;
        profile.Billing_Contact_Phone__c = BillingContact.Phone;
    }
    /*
        @return Pagereference
    */
    public Pagereference cancel (){
        return new Pagereference ( '/' + opportunityId );
    }

    /*
        @return Pagereference
    */
    public Pagereference attachDocuments (){
        return new Pagereference ( '/p/attach/NoteAttach?pid='+ opportunityId +'&retURL=/apex/NCSPWizard_Step1?oppId='+ opportunityId );
    }

    public PageReference previous()
    {
        if(previous.size() == 0)
            return null;
        else
            return previous.remove(previous.size()-1);
    }
    
    public pageReference updateOpportunityCustomerID(){
        saveSobject(opportunity);
        this.opportunity = [ SELECT Type, OwnerId, Owner.Name, AccountId, Upsell_Customer_ID__c,Upsell_Customer_ID__r.Name,
                                      Upsell_Customer_ID__r.Owning_District_Id__c, Account.IM_IMGA_Indexed__c,
                                      Upsell_Customer_ID__r.IM_Customer_Account_Name__c, Sales_Sub_Segment__c, /* #16915 Bundle__c,*/
                                      Split_Type__c, Sales_Rep_Percent__c, Split_Rep_Percent__c, Split_Commission_Rep__c,
                                      Split_Rep_2_Percent__c, Split_Commission_Rep_2__c, DM_Quad_2_Account__c,
                                      QTB_Billing_Country_Name__c,Primary_Product_Line__c,Billing_Account__r.Name, //Changes for Story #22791
                                      Billing_Account__r.Bill_To_Site_Number__c,Billing_Account__r.QTB_Market__c,
                                      (Select Id from Cases1__r where RecordTypeId in :recordCreatedInWizard LIMIT 1)
                             FROM Opportunity WHERE Id = :this.opportunityId ];
        
        //Changes for Story #22791
        if (this.opportunity.Primary_Product_Line__c == DM_SITAD_PRIMARY_PRODUCT_LINE && this.opportunity.QTB_Billing_Country_Name__c != null &&
            System.Label.QTB_SITAD_Countries.contains(this.opportunity.QTB_Billing_Country_Name__c)) {
            this.profile.Customer_Name__c = opportunity.Billing_Account__r.Name;
            this.profile.Service_District__c = opportunity.Billing_Account__r.QTB_Market__c;
            System.debug('this.profile.Customer_Name__c>>1073'+this.profile.Customer_Name__c);
            System.debug('this.profile.Service_District__c>>1074'+this.profile.Customer_Name__c);
        } else {
            this.profile.Customer_Name__c = opportunity.Upsell_Customer_ID__r.IM_Customer_Account_Name__c;
            this.profile.Service_District__c = opportunity.Upsell_Customer_ID__r.Owning_District_Id__c;
        }
        
        return null;
    }
    
    
    /*
        @return Pagereference
    */
    public Pagereference stepTwo (){
        previous.add( ApexPages.currentPage() );
        return Page.NCSPWizard_Step2;
    }

    /*
        This method should be call from the second step
        @return Pagereference
    */
    public Pagereference saveAndGoToStepThree (){
        if ( validateCustomerProfileStep2() && saveSObject( this.profile ) && saveSObject( this.opportunity) )
        {
            previous.add( ApexPages.currentPage() );
            return Page.NCSPWizard_Step3;
        }
        return null;
    }


    /*
        This method should be call from the Third step
        @return Pagereference
    */
    
    /* JM */
    public Pagereference attachDocumentsfreeupin (){
      if( saveSObject( this.profile ) )
       
      {
        return new Pagereference ( '/p/attach/NoteAttach?pid='+ opportunityId +'&retURL=/apex/NCSPWizardFreeUpIn?oppId='+ opportunityId );        
    }
        return null;
        }
        
    public Pagereference previousFreeUpIn (){
        if ( saveSObject( this.profile ) )
        {
            previous.add( Page.NCSPWizard_Step2 );
            return Page.NCSPWizard_Step3  ;
        }
        return null;
    }
        
        
    /* JM */
    /* Modified Non_Standard_Setup__c filed value to 'No' for case#07485178 */
    public Pagereference saveAndGoToStepFour ()
    {
        if ( validateCustomerProfileStep3() )
        {
            populateDBnRProductsOnCustomerProfile();
            if( saveSObject( this.profile ) )
            {
                previous.add( ApexPages.currentPage() );
                Set<String> nonStandardSetupPageEligible = eligibleNonStandardSetupServiceLineItems;
                if(isFreeUpIn) return Page.NCSPWizardFreeUpIn;
                
                return ( this.profile.Non_Standard_Setup__c == 'No') &&
                         ( nonStandardSetupPageEligible.contains(profile.NCSP_Service_Line__c) || nonStandardSetupPageEligible.contains(profile.Second_Service_Line__c) )
                       ? Page.NCSPWizard_Step4 : saveAndGoToTapeCatalogManager();
            }
        }
        return null;
    }
    
    private Pagereference saveAndGoToTapeCatalogManager()
    {
        previous.add( ApexPages.currentPage() );
        return ( isTapeCatalogManagerSelected() )? Page.NCSPWizard_TapeCatalogManager : saveAndGoToHealthcareOrConfig();
    }
    
    private Boolean isTapeCatalogManagerSelected()
    {
       if( isDBnR )
        { 
            for( String name : selectedDBRProducts )
            {
                NCSP_DBR_Products__c selectedProductInstance = NCSP_DBR_Products__c.getInstance( name );
                if( selectedProductInstance.Product_Name__c ==  TAPE_CATALOG_MANAGER )
                {
                    return true;
                }
            }
        } 
        return false;
    }

    private Pagereference saveAndGoToHealthcareOrConfig ()
    {
        clearCatalogManagerFields();
        previous.add( ApexPages.currentPage() );
        return this.profile.HealthcareAccountStoringPatientRecords__c == 'Yes' ? Page.NCSPWizard_Healthcare : goToConfigOrStepFive();
    }
    
    private void clearCatalogManagerFields()
    {
        this.profile.Total_number_of_catalogs_requested__c = NULL;
        this.profile.What_backup_software_is_used__c = NULL;
        this.profile.What_is_the_software_version__c = NULL;
        this.profile.What_is_the_operating_system__c = NULL;
        this.profile.Is_the_backup_system_alive__c = NULL;
    }

    /*
        This method should be call from the forth step
        @return Pagereference
    */
    public Pagereference saveAndGoToStepFive (){
        if ( saveSObject( this.profile ) )
        {
            previous.add( ApexPages.currentPage() );
            return saveAndGoToTapeCatalogManager () ;
        }
        return null;
    }
    

    /*
        This method should be call from the healthcare step
        @return Pagereference
    */
    public Pagereference saveAndGoToConfigOrStepFive (){
        if ( saveSObject( this.profile ) )
        {
            return goToConfigOrStepFive () ;
        }
        return null;
    }

    public Pagereference configNextPage () {
        previous.add( ApexPages.currentPage() );
        return stepFive ();
    }


    /*
        This method should be call from the third step
        @return Pagereference
    */
    private Pagereference stepFive (){
        
        system.debug('In Here - stepFive');
        system.debug('In Here - isDBnREnabled=='+isDBnREnabled);
        system.debug('In Here - isRM=='+isRM);
        system.debug('In Here - isDMS=='+isDMS);
        system.debug('In Here - isShred=='+isShred);
        system.debug('In Here - isOneTimeShred=='+isOneTimeShred);
        system.debug('In Here - isShredFrequencyNeeded=='+isShredFrequencyNeeded);
        system.debug('In Here - isDBRFrequencyNeeded=='+isDBRFrequencyNeeded);
        system.debug('In Here - isShredFrequencyNeeded=='+isShredFrequencyNeeded);
        Pagereference a=(isRM || isDBnREnabled || isDMS || isShred || isOneTimeShred || isShredFrequencyNeeded || isDBRFrequencyNeeded)
           ? Page.NCSPWizard_Step5 : Page.NCSPWizard_Step6;
        system.debug('step Five='+a);
        return ( isRM || isDBnREnabled || isDMS || isShred || isOneTimeShred || isShredFrequencyNeeded || isDBRFrequencyNeeded)
           ? Page.NCSPWizard_Step5 : Page.NCSPWizard_Step6;
    }

    private PageReference goToConfigOrStepFive()
    {
        previous.add( ApexPages.currentPage() );
        return isDMSConfigNeeded ? Page.NCSPWizard_ServiceLine_Config : stepFive();
    }


    /*
        This method should be called from the Fith step
        @return Pagereference
    */
    public Pagereference saveAndGoToStepSix (){
        if ( saveSObject( this.profile ) )
        {
            previous.add( ApexPages.currentPage() );
            return Page.NCSPWizard_Step6 ;
        }
        return null;
    }

    /*
        This method should be called from the sixth step
        @return Pagereference
    */
    public Pagereference saveAndGoToStepSix_b (){
        if ( String.isEmpty( this.profile.Primary_Service_Contact__c ) )
        {
            searchContacts();
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , 'Please select one contact' ) );
            return null;
        }

        selectedContact = [SELECT Id, Name, Primary_NCSP_Contact__c, Phone,Email FROM Contact WHERE Id = : this.profile.Primary_Service_Contact__c ];
        
         try{
             if( ! selectedContact.Primary_NCSP_Contact__c) {
                selectedContact.Primary_NCSP_Contact__c = true;
                update selectedContact;
             }
            
        } catch (DMLexception ex){
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , ex.getMessage() ) );   
        }
        
        doCreateNewContact = false;

        previous.add( ApexPages.currentPage() );
        return Page.NCSPWizard_Step6b;

    }

    /*
        This method should be called from the six-b step
        @return Pagereference
    */
    public Pagereference saveContactAndGoToStepSeven (){
        if ( saveSObject( this.selectedContact ) && saveSObject( this.profile ) )
        {
            
            previous.add( ApexPages.currentPage() );
            return  (this.isNewDeal || this.profile.Deal_Type__c == NEW_SERVICE_LINE ) && (!this.isInternational) ? Page.NCSPWizard_Step7 : Page.NCSPWizard_Step8 ;
        }
        return null;
    }

    /*
        This method should be called from the sixth step
        @return Pagereference
    */
    public Pagereference createNewContact (){
        previous.add( ApexPages.currentPage() );
        selectedContact = new Contact ( AccountId = this.opportunity.AccountId );
        return  Page.NCSPWizard_Step6b;
    }

    /*
        This method should be called from the seven step
        @return Pagereference
    */
    public Pagereference stepEight (){

        if ( ncspCase.Date_Contract_Signed__c > Date.today().addDays( 1 ) )
        {
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , Label.NCSP_Invalid_date_contract_error ) );
            return null;
        }

        previous.add( ApexPages.currentPage() );
        return  Page.NCSPWizard_Step8;
    }

    public Pagereference createCase (){

        this.profile.Case_Created__c = true;
        
        // Map fields
        ncspCase.AccountId             = this.opportunity.AccountId;
        ncspCase.Address__c            = this.profile.Address__c;
        ncspCase.Address_Line_2__c     = this.profile.Address_Line_2__c;
        ncspCase.City__c               = this.profile.City__c;
        ncspCase.ContactId             = this.profile.Primary_Service_Contact__c =selectedContact.Id;
        ncspCase.Country__c            = this.profile.Country__c;
        if (this.opportunity.Primary_Product_Line__c == DM_SITAD_PRIMARY_PRODUCT_LINE && this.opportunity.QTB_Billing_Country_Name__c != null &&
            System.Label.QTB_SITAD_Countries.contains(this.opportunity.QTB_Billing_Country_Name__c)) {
            //Changes for Story #22791
            ncspCase.Bill_To_Site_Number__c = (this.opportunity.Billing_Account__r.Bill_To_Site_Number__c != null) ? this.opportunity.Billing_Account__r.Bill_To_Site_Number__c: null;
        } else {
            ncspCase.Customer_ID__c    = (UPSELL_TYPE.contains(String.ValueOf(this.opportunity.Type))) ? this.opportunity.Upsell_Customer_ID__c: null;
        }
        ncspCase.NCSP_Cust_Name__c     = this.profile.Customer_Name__c;
        ncspCase.Customer_Profile__c   = this.profile.Id;
        ncspCase.Date_Paperwork_Received__c = System.now();
        ncspCase.DMS_Type__c           = this.profile.DMS_Type__c;
        ncspCase.Imaging_Center__c     = this.profile.Imaging_Center__c;
        ncspCase.Inside_Sales_Name_Sales_factory__c   = insideSalesNameFactory;
        ncspCase.NCSP_Opportunity__c   = this.opportunityId;
        ncspCase.Origin                = findCaseOrigin( Userinfo.getProfileId() );
        system.debug('this.profile.Deal_Type__c'+this.profile.Deal_Type__c);
        // Changes made by Venkateswarlu Avula realted to O2I Project
        if(isInternational & this.internationalCaseOwnerID != null) {
            ncspCase.ownerID= this.internationalCaseOwnerID;
        }
        else if((this.profile.Deal_Type__c == 'Upsell' || this.profile.Deal_Type__c == 'Department Add'))
        {
             ncspCase.OwnerId               = (standardCaseQueueIdnew == null) ? UserInfo.getUserId() : standardCaseQueueIdnew;
          /*   Database.DMLOptions dmo = new Database.DMLOptions();
             dmo.assignmentRuleHeader.useDefaultRule = true;
             dmo.EmailHeader.triggerUserEmail = true;
            
             ncspCase.setOptions(dmo);*/

        } 
        else if(this.profile.Deal_Type__c == 'Department Add' || this.profile.Deal_Type__c == 'New Service Line' || this.profile.Deal_Type__c == 'New Deal' || this.profile.Deal_Type__c == 'Upsell')
        {
             ncspCase.OwnerId               = (standardCaseQueueIdnew == null) ? UserInfo.getUserId() : standardCaseQueueIdnew;
        }
       else if(this.profile.Deal_Type__c == 'Upsell')
        {
              ncspCase.OwnerId               = (standardCaseQueueIdnew == null) ? UserInfo.getUserId() : standardCaseQueueIdnew;
        }
   
        ncspCase.Sales_Person_Name_Account_Manager__c = opportunity.OwnerId;
        ncspCase.Setup_Type__c                        = STANDARD_SETUP_TYPE;
        ncspCase.State__c                             = this.profile.State_Province__c;
        ncspCase.Status                               = STATUS_NEW;
        ncspCase.Zip__c                               = this.profile.Zip_Postal_Code__c;
        ncspCase.NSCP_Case_Creator_Name__c = UserInfo.getUserId();
        /* Added for A2C project - vijay*/
        if(this.profile.Same_as_Service_Address__c)
        {
        ncspCase.Billing_Address__c            = this.profile.Address__c + (String.isBlank(this.profile.Address_Line_2__c) ? '': ','+'  ' + this.profile.Address_Line_2__c);
        ncspCase.Billing_City__c               = this.profile.City__c;
        ncspCase.Billing_Country__c            = this.profile.Country__c;
        ncspCase.Billing_State_Province__c     = this.profile.State_Province__c;
        ncspCase.Billing_Zip_Postal_Code__c    = this.profile.Zip_Postal_Code__c;
       } 
        else{
        ncspCase.Billing_Address__c            = this.profile.Billing_Address__c;
        ncspCase.Billing_City__c               = this.profile.Billing_City__c;
        ncspCase.Billing_Country__c            = this.profile.Billing_Country__c;
        ncspCase.Billing_State_Province__c     = this.profile.Billing_State_Province__c;
        ncspCase.Billing_Zip_Postal_Code__c    = this.profile.Billing_Zip_Postal_Code__c;
        }
        ncspCase.Billing_Contact__c            = this.profile.Billing_Contact__c;
        ncspCase.Autopay_Agreed__c             = this.profile.Autopay_Agreed__c;
        ncspCase.PO_Required__c                = this.profile.PO_Required__c;
        ncspCase.Billing_Contact_Email__c      = this.profile.Billing_Contact_Email__c;
        ncspCase.Billing_Contact_Phone__c      = this.profile.Billing_Contact_Phone__c; 
       // JM added - 
        ncspCase.Invoice_Package__c    = this.profile.Invoice_Package__c;
        ncspCase.Invoice_Delivery_Method__c    = this.profile.Invoice_Delivery_Method__c;
        ncspCase.Material_Moving_From_Another_Vendor__c    = this.profile.Material_Moving_From_Another_Vendor__c;
        ncspCase.Free_Up_In__c    = this.profile.Free_Up_In__c;
       /* Devloper Name:Madhu Paladugu
          Case Number  :01045376
          Discription  : Added the following assignment statement
       */
       ncspCase.Sales_Support__c                      =salesSupport;
        List <Case> casesToCreate = new List <Case> ();
        // Create Second Service line Case
        if ( null != this.profile.Second_Service_Line__c  ){
            Case secondNcspCase =  ncspCase.clone( false, true );
            secondNcspCase.NCSP_Service_Line__c = this.profile.Second_Service_Line__c;
            secondNcspCase.NCSP_Upsell_Type__c  = this.profile.Second_NCSP_Upsell_Type__c;
            if((this.profile.Deal_Type__c == 'Upsell' || this.profile.Deal_Type__c == 'Department Add'))
            {
                 secondNcspCase.RecordTypeId         = findRecordTypeId( secondNcspCase.NCSP_Service_Line__c ); 
            }
            else 
            secondNcspCase.RecordTypeId         = findRecordTypeId( secondNcspCase.NCSP_Service_Line__c );
            //secondNcspCase.Reason_No_Supply__c           = this.profile.Second_Reason_No_Supply__c;
            secondNcspCase.Supplies_Order_Required__c    = this.profile.Second_Supplies_Order_Required__c;
            setCaseServiceLineFields ( secondNcspCase, this.profile.Second_Service_Line__c );
            if(isInternational && internationalCaseOwnerID != null) {
                secondNcspCase.ownerID= this.internationalCaseOwnerID;
            }
            casesToCreate.add( secondNcspCase );
        }

        // Set the fields after after second service line was created
        ncspCase.NCSP_Service_Line__c  = this.profile.NCSP_Service_Line__c;
        ncspCase.NCSP_Upsell_Type__c   = this.profile.NCSP_Upsell_Type__c;
        // 8977 - Nandini Mishra - Removed dependency for Reason_No_Supply__c 6/15/2022
        /*ncspCase.Reason_No_Supply__c   = this.profile.Reason_No_Supply__c;*/
        ncspCase.Supplies_Order_Required__c  = this.profile.Supplies_Order_Required__c;
        setCaseServiceLineFields ( ncspCase , this.profile.NCSP_Service_Line__c);

       if( this.profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR )
        {
            for( String dbnrProductSelected : selectedDBRProducts )
            {
                Case dbrTypeCase =  ncspCase.clone( false, true );
                dbrTypeCase.RecordTypeId = NCSP_DBR_Products__c.getInstance( dbnrProductSelected ).Case_RecordTypeId__c;
                dbrTypeCase.DB_R_Type__c = NCSP_DBR_Products__c.getInstance( dbnrProductSelected ).Product_Name__c;
                dbrTypeCase.Customer_ID__c = NULL;
                if (this.opportunity.Primary_Product_Line__c == DM_SITAD_PRIMARY_PRODUCT_LINE && this.opportunity.QTB_Billing_Country_Name__c != null &&
                    System.Label.QTB_SITAD_Countries.contains(this.opportunity.QTB_Billing_Country_Name__c)) {
                    //Changes for Story #22791
                    dbrTypeCase.Bill_To_Site_Number__c = (this.opportunity.Billing_Account__r.Bill_To_Site_Number__c != null) ? this.opportunity.Billing_Account__r.Bill_To_Site_Number__c: null;
                } else if(UPSELL_TYPE.contains(String.ValueOf(this.opportunity.Type)) && dbrTypeCase.DB_R_Type__c == TAPE_VAULTING )
                {
                    dbrTypeCase.Customer_ID__c = this.opportunity.Upsell_Customer_ID__c;
                }
                if( dbrTypeCase.DB_R_Type__c == TAPE_CATALOG_MANAGER )
                {
                    dbrTypeCase.Total_number_of_catalogs_requested__c = this.profile.Total_number_of_catalogs_requested__c;
                }
                casesToCreate.add( dbrTypeCase );
            }
        } 
         if((this.profile.Deal_Type__c == 'Upsell' || this.profile.Deal_Type__c == 'Department Add'))
        { 
            ncspCase.RecordTypeId = findRecordTypeId( this.profile.NCSP_Service_Line__c );
            casesToCreate.add(ncspCase);
        }
        else
        {
            system.debug(LoggingLevel.INFO,'recordType=='+findRecordTypeId( this.profile.NCSP_Service_Line__c )); 
            ncspCase.recordTypeId = findRecordTypeId( this.profile.NCSP_Service_Line__c );
            casesToCreate.add( ncspCase );
        }
        if ( validateCustomerProfileStep2()  )
        {
            
            Savepoint sp = Database.setSavepoint();
            if (  !( saveSObject( this.profile ) && saveSObject( this.selectedContact )
               && saveSObjects( casesToCreate ) ) )
            {
                Database.rollback(sp);
                return null;
            }
        }else {
            return null;
        }
        
        if(casecomment.CommentBody != null){
            CaseComment comment = new CaseComment(CommentBody =casecomment.CommentBody ,ParentId =casesToCreate[0].Id );
            saveSObject( comment );
        }
        return new Pagereference ('/' + casesToCreate[0].Id);
    }

    private Boolean validateCustomerProfileStep3()
    {
        if( profile.Autopay_Agreed__c == 'Yes' && profile.Invoice_Delivery_Method__c != 'Print / Mail Delivery' && this.opportunity.Type == 'New Deal' && (!isInternational))
        {
           ApexPages.addMessage( new ApexPages.Message( Apexpages.Severity.Error, 'Please select Print/Mail Delivery option for Autopay customers' ));
         //   profile.Invoice_Delivery_Method__c.addError('Please select Print/Mail Delivery option for Autopay customers');
            return false;
        }
        if( String.isEmpty( profile.Customer_ID_for_Inventory_Transfer__c)  &&
            ( (profile.NCSP_Service_Line__c == SERVICE_LINE_RM && profile.NCSP_Upsell_Type__c == UPSELL_TYPE_INVENTORY_TRANSFER) ||
            (profile.Second_Service_Line__c == SERVICE_LINE_RM && profile.Second_NCSP_Upsell_Type__c == UPSELL_TYPE_INVENTORY_TRANSFER) )
           )
        {
            ApexPages.addMessage( new ApexPages.Message( Apexpages.Severity.Error, 'Customer Id for Inventory transfer is required when the service line is ' + SERVICE_LINE_RM + ' and the upsell type is ' + UPSELL_TYPE_INVENTORY_TRANSFER));
            return false;
        }

        if( String.isEmpty( profile.DB_R_Authorization_Number__c)  && profile.Deal_Type__c == 'Upsell' &&
            ( profile.NCSP_Service_Line__c == SERVICE_LINE_DBnR || profile.Second_Service_Line__c == SERVICE_LINE_DBnR  )
           )
        {
            ApexPages.addMessage( new ApexPages.Message( Apexpages.Severity.Error, 'Authorization Number  is required when the service line is ' + SERVICE_LINE_DBnR ));
            return false;
        }
        
       if(this.isDBnR && this.selectedDBRProducts.isEmpty() )
        {
            ApexPages.addMessage( new ApexPages.Message( Apexpages.Severity.Error, Label.NCSP_DB_R_ProductType_validation ));
            return false;
        } 

        return true;
    }
    
    public void populateDBnRProductsOnCustomerProfile()
    {
        if( this.isDBnR )
        {
            String productTypes = '';
            for( String selectedType : selectedDBRProducts )
            {
                productTypes += NCSP_DBR_Products__c.getInstance( selectedType ).Product_Name__c + ';' ;
            }
            this.profile.DB_R_Type__c = productTypes;
        } 
    }

    /*
        Validate if the CustomerProfile Step data
        is correct
    */
    private boolean validateCustomerProfileStep2(){
        boolean isValid = true ;

        if ( !this.profile.Same_as_Service_Address__c && !this.profile.Same_as_Current_Billing_Address__c &&
            ( String.isEmpty( profile.Billing_Address__c ) || (String.isEmpty( profile.Billing_State_Province__c ) && (!isInternational))
            || String.isEmpty( profile.Billing_City__c ) || String.isEmpty( profile.Billing_Zip_Postal_Code__c ) || String.isEmpty( profile.Billing_Country__c )  ) ){
            isValid = false;
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , Label.NCSP_Billing_Address_Error_Message ) );
        }
        if ( !this.profile.Same_as_Service_Address_cor__c && !this.profile.Same_as_Billing_Address__c && !this.profile.Same_as_Current_Correspondence_Address__c &&
            ( String.isEmpty( profile.Correspondence_Address__c ) || (String.isEmpty( profile.Correspondence_State_Province__c )  && (!isInternational) )
            || String.isEmpty( profile.Correspondence_City__c ) || String.isEmpty( profile.Correspondence_Zip_Postal_Code__c ) || String.isEmpty( profile.Correspondence_Country__c )  ) ){
            isValid = false;
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , Label.NCSP_Correspondence_Address_Error_Message ) );
        }
        return isValid;
    }

    private void setCaseServiceLineFields ( Case aCase, final String serviceLine ){

            if ( serviceLine == SERVICE_LINE_ONE_TIME_SHRED ) {
                aCase.OTS_Box_Quantity__c   = this.profile.OTS_Box_Quantity__c;
                aCase.Shred_Quantity_Consoles_Ordered__c   = this.profile.OTS_Quantity_Consoles_Ordered__c ;
                aCase.Shred_Quantity_65_Gallon_Ordered__c = this.profile.OTS_Quantity_65_Gallon_Ordered__c;
                aCase.Shred_Gallon_Ordered__c  = this.profile.OTS_Gallon_Ordered__c;
                aCase.Shred_Service_Method__c              = this.profile.OTS_Service_Method__c;
            }else if ( serviceLine == SERVICE_LINE_DMS ){
                aCase.Billing_Department__c = this.profile.Billing_Department__c;
                aCase.Billing_Division__c   = this.profile.Billing_Division__c;
                aCase.Imaging_Center__c     = this.profile.Imaging_Center__c;
                aCase.PO_Number__c          = this.profile.PO_Number__c;
                aCase.Special_Commission_Approval_Included__c   = (this.profile.Special_Commission_Approval_Included__c ? YES : NO);
                aCase.Separate_DMS_Invoice_Needed__c            = (this.profile.Separate_DMS_Invoice_Needed__c ? YES : NO);
                aCase.Litigation_DMS__c                         = (this.profile.Litigation_DMS__c ? YES : NO);
                aCase.Rush__c                                   = this.profile.Litigation_DMS__c ;
                aCase.Rush_Comments__c                          = (aCase.Rush__c ? DMS_LITIGATION_RUSH_COMMENT : NULL);
                aCase.Billing_for_Separator_Sheets__c           = this.profile.Billing_for_Separator_Sheets__c ? YES : NO;
                aCase.RM_Label_Quantities__c               = profile.DMS_Label_Quantities__c;
                aCase.RM_Label_Type__c                     = profile.DMS_Label_Type__c;
                aCase.RM_Supply_Box_Order_Qty__c           = profile.DMS_Supply_Box_Order_Qty__c;
                aCase.RM_Supply_Box_Order_Type__c          = profile.DMS_Supply_Box_Order_Type__c;
            }else if ( serviceLine == SERVICE_LINE_DBnR ){
                aCase.DP_Container_Type__c    = this.profile.DB_R_Container_Type__c;
                aCase.DB_R_Service_Frequency__c = this.profile.DB_R_Service_Frequency__c;
                aCase.DP_Container_Quantity__c   = this.profile.DB_R_Container_Quantity__c;
                aCase.DB_R_Preferred_Service_Days__c = this.profile.DB_R_Preferred_Service_Days__c;
                aCase.DB_R_Box_Quantity__c = String.valueOf( this.profile.DB_R_Box_Quantity__c );
                aCase.DB_R_Tape_Quantity__c = this.profile.DB_R_Tape_Quantity__c;
                aCase.Authorization_Number__c = this.profile.DB_R_Authorization_Number__c;
            }else if ( serviceLine == SERVICE_LINE_SHRED ){
                aCase.Shred_Quantity_65_Gallon_Ordered__c = this.profile.Shred_Quantity_65_Gallon_Ordered__c;
                aCase.Shred_Gallon_Ordered__c  = this.profile.Shred_Gallon_Ordered__c;
                aCase.Shred_Quantity_Consoles_Ordered__c   = this.profile.Shred_Quantity_Consoles_Ordered__c;
                aCase.Shred_Service_Frequency__c           = this.profile.Shred_Service_Frequency__c;
                aCase.Shred_Service_Method__c              = this.profile.Shred_Service_Method__c;
                aCase.Media_Destruction_Customer__c        = this.profile.Media_Destruction_Customer__c;
            }else if ( serviceLine == SERVICE_LINE_RM ){
                aCase.RM_Label_Quantities__c               = this.profile.RM_Label_Quantities__c;
                aCase.RM_Label_Type__c                     = this.profile.RM_Label_Type__c;
                aCase.RM_Supply_Box_Order_Qty__c           = this.profile.RM_Supply_Box_Order_Qty__c;
                aCase.RM_Supply_Box_Order_Type__c          = this.profile.RM_Supply_Box_Order_Type__c;
                aCase.Setup_Type__c                        = this.profile.HealthcareAccountStoringPatientRecords__c=='Yes'? HEALTHCARE_ACCOUNT_TYPE : STANDARD_SETUP_TYPE;

                //Customer_ID_for_Inventory_Transfer__c
            }

    }


    /*
        Find the record type id base on the service line
        @param  String
        @return Id

    */
    private Id findRecordTypeId (final String serviceLine )
    {

        final Set<String> NCSP_SKP_NEW_CUSTOMER =  new Set<String>{'RM', 'Shred', 'One Time Shred', 'RM Pathology', 'Vault Climate Control','Geological Core'};
        final Set<String> NCSP_TECH_SERVICES    =  new Set<String>{ 'Connected', 'Live Vault', 'EVault', 'DRCMI', 'Iron Cloud', 'CDR', 'Cloud Archive' };

        if ( this.profile.Deal_Type__c == DEAL_TYPE_UPSELL ){
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_Upsell'].Id;
        }
        else if ( this.profile.Deal_Type__c == DEAL_TYPE_DEPARMENT_ADD ){
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_SKP_Department_Add_Only'].Id;
        }
        else if ( NCSP_SKP_NEW_CUSTOMER.contains( serviceLine )  )
        {
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_SKP_New_customer_setup'].Id;
        }
        else if ( 'Accutrac' == serviceLine )
        {
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_New_Customer_Setup'].Id;
        }
        else if ( 'Data Breach' == serviceLine )
        {
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_New_Customer_Setup'].Id;
        }
        else if ( NCSP_TECH_SERVICES.contains ( serviceLine ) )
        {
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_Tech_Services_New_Customer_Setup'].Id;
        }
        else if ( 'DB&R' == serviceLine )
        {
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_DP_Onboarding_team'].Id;
        }
            
         else if ( 'Data Center' == serviceLine )
        {
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_DP_Onboarding_team'].Id;    
        }
           else if ( 'Entertainment Services' == serviceLine )
        {
            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_DP_Onboarding_team'].Id;    
              
            
        }else if ( 'DMS' == serviceLine ) {

            return [SELECT Id FROM RecordType WHERE DeveloperName =  'NCSP_DMS'].Id;
        }

        return null;
    }

    /*

    */
    public static String findCaseOrigin ( Id profileId ){

        final Map<String, String> profilesOrigin = new Map<String, String>();
        for( Profiles_Origin__c customSetting : Profiles_Origin__c.getAll().values() )
        {
        profilesOrigin.put( customSetting.Profile_Name__c, customSetting.Origin__c );
        }
        List<Profile> userProfile = [Select Name from Profile where id = :profileId];
        String caseOrigin = profilesOrigin.get(userProfile[0].Name );
        if(caseOrigin == null)
        {
            caseOrigin = profilesOrigin.get('Other');
        }
        return caseOrigin;
    }

    /*
        Save a list of sObjects
        @param sObject
        return boolean
    */
    private boolean saveSObject( sObject obj ){
        try{
            upsert obj;
        }catch (Dmlexception ex){
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , ex.getMessage() ) );
            return false;
        }
        return true;
    }

    /*
        Save a list of sObjects
        @param List<sObject>
        return boolean
    */
    private boolean saveSObjects( List<sObject> objs ){
        try{
            System.debug('Object>>>>>>>'+objs);
            upsert objs;
         }catch (Dmlexception ex){
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , ex.getMessage() ) );
            return false;
        }
        return true;
    }
}