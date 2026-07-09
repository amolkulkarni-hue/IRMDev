/*****************************************************************************************************
 * Class: QTB_Constants
 * Author: Accenture
 * Change History: 05/29/2020
 * Purpose: This is a generic Class to store the constants.
 *******************************************************************************************************/
public with sharing class QTB_Constants {
    //Account Constants
    public static final String ACCOUNT_TRIGGER = 'AccountTrigger';
    public static final String ACCOUNT_OBJECT = 'AccountObject';
    public static final string ACCOUNT_HELPER = 'QTB_AccountHelper';
    public static final String BILL_ACC_CREATION = 'Creation';
    public static final String BILL_ACC_ASSOCIATION = 'Association';
    public static final String TAX_EXEMPT_YES = 'Yes';
    public static final String TAX_EXEMPT_NO = 'No';
  
    //Opportunity Constants
    public static final String STAGEVALUE_ONESETUP = '1 - Qualification';
    public static final String STAGEVALUE_SIXSETUP = '6 - Setup';
    public static final String STAGEVALUE_SEVENSETUP = '7 - Closed';
    public static final String DATA_MANAGEMENT = 'Data Management';
    public static final String RECORDS_MANAGEMENT = 'Records Management';
    public static final String SMB_PACKAGES = 'SMB Packages';
    public static final String SHRED = 'Shred';
    public static final String SCAN = 'Scan';
    public static final String OPP_TYPE = 'Renewal';
    public static final String OPP_TYPE_AMEND = 'Rate Change';
    public static final String OPP_TYPE_RATE_CHANGE = 'Rate Change';
    public static final String OPP_TYPE_UP_SELL = 'Up-Sell';
    public static final String OPP_TYPE_NEWDEAL = 'New Deal';
    public static final String SPECIALPROJECT_RM = 'Special Projects - Records Management & Shred';
    public static final String SPECIALPROJECT_DM = 'Special Projects - Data Management';
    public static final String SPECIALPROJECT_International = 'Special Projects - International';
    public static final String DM = 'DM';
  
    //Quote Constatns
    public static final String APPROVED_STATUS = 'Approved';
    public static final String QUOTE_EXPIRED_STATUS = 'Expired';
    public static final String SUBSCRIPTION_TERM_TWELVE = '12';
    public static final String QUOTE_TYPE_RENEWAL = 'Renewal'; // following object_field_value naming
    public static final String IN_REVIEW_STATUS = 'In Review';
    public static final String DENIED_STATUS = 'Denied';
    public static final String PRESENTED_STATUS = 'Presented';
    public static final String ACCEPTED_STATUS = 'Accepted';
    public static final String REJECTED_STATUS = 'Rejected';
    public static final List<String> QUOTE_RECORD_TYPE = new List<String>{
      'Sales Quote',
      'Sales Quote - Approved',
      'Sales Quote - In Review'
    };
    public static final String QUOTE_TRIGGER = 'QTB_QuoteTrigger';
    public static final String QUOTE_TYPE_STANDARD = 'Standard';
    public static final String QUOTE_TYPE_AMEND = 'Amendment';
    public static final String QUOTE_TYPE_QUOTE = 'Quote';
    public static final String QUOTE_DRAFT_STATUS = 'Draft';
    public static final String TERMINATION = 'Termination';
    public static final String RETENTION = 'Retention';
    public static final String ORDCATEGORY_SPECIALPROJECTS = 'Special Projects';
    public static final String ORDCATEGORY_ONETIMESHRED = 'One Time Shred';
    public static final String ORDCATEGORY_RETENTION = 'Retention';
    public static final String ORDCATEGORY_TERMINATION = 'Termination';
    public static final String ORDCATEGORY_EVERGREEN = 'Evergreen';
    
    
  
    //Quote Share Constants
    public static final String QSHARE_ACCESSLEVEL = 'Edit';
  
    //Opportunity Team Constants
    public static final String OPPTY_ACCESSLEVEL = 'Edit';
  
    //Order Constatns
    public static final String DRAFT_STATUS = 'Draft';
    public static final String ACTIVATED_STATUS = 'Activated';
    public static final String ORDER_SALES_TYPE = 'Sales';
    public static final String ORDER_BILLING_TYPE = 'Billing';
    public static final String ORDER_TYPE_AMENDMENT = 'Amendment';
    public static final String ORDER_TYPE_RENEWAL = 'Renewal';
    public static final String ORDER_TYPE_New = 'New';
    public static final String ORDER_PRICE_CALC_STATUS = 'Completed';
        public static final String ORDCATEGORY_ADHOC = 'Ad-Hoc';
        public static final String ORDCATEGORY_WORKORDER = 'Work Order';
        public static final String ORDCATEGORY_REBILL = 'Rebill';



  
    //Contact Constants
    public static final String CONTACT_ROLE = 'Billing';
  
    //Contract Constatns
    //  public static final String DRAFT_STATUS= 'Draft';
    public static final String CONT_ACTIVATED_STATUS = 'Activated';
    public static final String CONTRACT_PLATFORM_EVENT = 'ContractPlatformEvent';
  
    //Opportunity Team Member Constants
    public static final String OPPTY_ACCESSLEVEL_READ = 'Read';
    public static final String OPPORTUNITYTEAM_TRIGGER = 'QTB_OpportunityTeamTrigger';
  
    //Framework Constants
    public static final String TYPE_AMEND = 'Amend';
    public static final String TYPE_RENEWAL = 'Renewal';
  
    //Handler Constrants
    public static final String TYPE_CONTRACT = 'Contract';
    public static final String TYPE_OPPORTUNITY = 'Opportunity';
    public static final String TYPE_AMENDMENT = 'Amendment';
    public static final String TYPE_SBQQ_QUOTE = 'SBQQ__Quote__c';
    public static final String TYPE_SBQQ_QUOTELINE = 'SBQQ__QuoteLine__c';
  
    // Credit Note Line Constants
    public static final String CREDITNOTELINE_STATUS_DRAFT = 'Draft';
    public static final String CREDITNOTELINE_STATUS_POSTED = 'Posted';
    public static final String CREDITNOTELINE_TAX_STATUS = 'Completed';
  
    // sbaa__Approval__c Constants
    public static final String APPROVAL_STATUS_REQUESTED = 'Requested';
    public static final String APPROVAL_STATUS_ASSIGNED = 'Assigned';
    public static final String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final String APPROVAL_STATUS_REJECTED = 'Rejected';
    public static final String APPROVAL_STATUS_REVOKED = 'Revoked';
    public static final String APPROVAL_STATUS_RECALLED = 'Recalled';
    public static final String APPROVAL_STATUS_PENDING = 'Pending';
  
    // blng__CreditNote__c constants
    public static final String CREDITNOTE_STATUS_DRAFT = 'Draft';
    public static final String CREDITNOTE_STATUS_POSTED = 'Posted';
    public static final String CREDITNOTE_APPROVALSTATUS_PENDING = 'Pending';
    public static final String CREDITNOTE_APPROVALSTATUS_APPROVED = 'Approved';
    public static final String CREDITNOTE_APPROVALSTATUS_REJECTED = 'Rejected';
    public static final String CREDITNOTE_APPROVALSTATUS_RECALLED = 'Recalled';
  
    // sbaa__Approver__c constants
    public static final String APPROVER_LEVEL_MANAGER = 'Manager';
    public static final String APPROVER_LEVEL_SUPERVISOR = 'Supervisor';
    public static final String APPROVER_LEVEL_DIRECTOR = 'Director';
    public static final String APPROVER_LEVEL_VP = 'VP';
    public static final String APPROVER_LEVEL_SVP = 'SVP';
    public static final String APPROVER_LEVEL_EVP = 'EVP';
    public static final String APPROVER_LEVEL_CEO = 'CEO';
    public static final String APPROVER_LEVEL_CFO = 'CFO';
  
    // sbaa__Approval__c constants
    public static final String APPROVAL_FIELD_CREDITNOTE = 'QTB_Credit_Note__c';
  
    // Object prefix
    public static final String USER_PREFIX = Schema.SObjectType.User.getKeyPrefix();
  
    // blng__TaxRule__c contants
    public static final String TAXABLE_YES = 'Yes';
    public static final String TAXABLE_NO = 'No';
  
    // blng__BillingRule__c contants
    public static final String GENERATE_INVOICE_YES = 'Yes';
    public static final String GENERATE_INVOICE_NO = 'No';
  
    // blng__Invoice__c constants
    public static final String INVOICE_STATUS_DRAFT = 'Draft';
    public static final String INVOICE_STATUS_INITIATED ='Initiated';
    public static final String INVOICE_STATUS_POSTED = 'Posted';
    public static final String INVOICE_STATUS_CANCELLED = 'Cancelled';
    public static final String INVOICE_COUNTRY_NORWAY = 'norway';
    public static final String CREDIT_COUNTRY_NORWAY = 'norway credit';
    public static final String INVOICE_COUNTRY_DENMARK = 'denmark';
    public static final String CREDIT_COUNTRY_DENMARK = 'denmark credit';
    public static final String INVOICE_COUNTRY_SWEDEN = 'sweden';
    public static final String CREDIT_COUNTRY_SWEDEN = 'sweden credit';
    public static final String INVOICE_COUNTRY_FINLAND = 'finland';
    public static final String CREDIT_COUNTRY_FINLAND = 'finland credit';
    public static final String INVOICE_COUNTRY_INDIA = 'india';
    public static final String CREDIT_COUNTRY_INDIA = 'india credit';
    public static final String INVOICE_COUNTRY_TAIWAN = 'taiwan';
    public static final String CREDIT_COUNTRY_TAIWAN = 'taiwan credit';
    public static final String INVOICE_COUNTRY_THAILAND = 'thailand';
    public static final String CREDIT_COUNTRY_THAILAND = 'thailand credit';
    public static final String INVOICE_COUNTRY_MALAYSIA = 'malaysia';
    public static final String CREDIT_COUNTRY_MALAYSIA = 'malaysia credit';
    public static final String INVOICE_COUNTRY_HONGKONG = 'hong kong';
    public static final String CREDIT_COUNTRY_HONGKONG = 'hong kong credit';
    public static final String INVOICE_COUNTRY_SINGAPORE = 'singapore';
    public static final String CREDIT_COUNTRY_SINGAPORE = 'singapore credit';
    public static final String INVOICE_COUNTRY_FRANCE = 'france';
    public static final String CREDIT_COUNTRY_FRANCE = 'france credit';
    public static final String INVOICE_COUNTRY_BELGIUM = 'belgium';
    public static final String CREDIT_COUNTRY_BELGIUM = 'belgium credit';
    public static final String INVOICE_COUNTRY_NETHERLANDS = 'netherlands';
    public static final String CREDIT_COUNTRY_NETHERLANDS = 'netherlands credit';
    //GitLab #27336 - Added for UK & Ireland
    public static final String INVOICE_COUNTRY_UNITEDKINGDOM = 'united kingdom';
    public static final String CREDIT_COUNTRY_UNITEDKINGDOM = 'united kingdom credit';
    public static final String INVOICE_COUNTRY_IRELAND = 'ireland';
    public static final String CREDIT_COUNTRY_IRELAND = 'ireland credit';
    //GitLab #27336 - End
    //Cluster 3 countries
    public static final String INVOICE_COUNTRY_ROMANIA = 'romania';
    public static final String CREDIT_COUNTRY_ROMANIA = 'romania credit';
    public static final String INVOICE_COUNTRY_SLOVAKIA = 'slovakia';
    public static final String CREDIT_COUNTRY_SLOVAKIA = 'slovakia credit';
    public static final String INVOICE_COUNTRY_GREECE = 'greece';
    public static final String CREDIT_COUNTRY_GREECE = 'greece credit';
    public static final String INVOICE_COUNTRY_CZECH_REPUBLIC = 'czech republic';
    public static final String CREDIT_COUNTRY_CZECH_REPUBLIC = 'czech republic credit';
    //#30973 #31259 Cluster 4 countries Turkey, New Zealand,Australia
    //#34738 Commeneted below turkey Assignments
    //public static final String INVOICE_COUNTRY_TURKEY = 'turkey';
    //public static final String CREDIT_COUNTRY_TURKEY = 'turkey credit';
    public static final String INVOICE_COUNTRY_AUSTRALIA = 'australia';
    public static final String CREDIT_COUNTRY_AUSTRALIA = 'australia credit';
    public static final String INVOICE_COUNTRY_NEW_ZEALAND = 'new zealand';
    public static final String CREDIT_COUNTRY_NEW_ZEALAND = 'new zealand credit';
	//Cluster 3A countries
	public static final String INVOICE_COUNTRY_HUNGARY = 'hungary';
    public static final String CREDIT_COUNTRY_HUNGARY = 'hungary credit';
    public static final String INVOICE_COUNTRY_AUSTRIA = 'austria';
    public static final String CREDIT_COUNTRY_AUSTRIA = 'austria credit';
    public static final String INVOICE_COUNTRY_SPAIN = 'spain';
    public static final String CREDIT_COUNTRY_SPAIN = 'spain credit';
    public static final String INVOICE_COUNTRY_GERMANY = 'germany';
    public static final String CREDIT_COUNTRY_GERMANY = 'germany credit';
    public static final String DENMARK_PREFIX = '+71<0000';
    public static final String DENMARK_POSTFIX = '        +89423821<';
    public static final String DENMARK_PREFIX_ISO = 'DNK';
    public static final String DENMARK_CREDIT_PREFIX = 'DKC';
    public static final String SWEDEN_PREFIX = 'SWE';
    public static final String SWEDEN_CREDIT_PREFIX = 'SEC';
    public static final String INDIA_PREFIX = '17';
    public static final String INDIA_PREFIX_ISO = 'IND';
    public static final String INDIA_CREDIT_PREFIX = 'INDC';
    public static final String FINLAND_PREFIX_ISO = 'FIN';
    public static final String FINLAND_CREDIT_PREFIX = 'FIC';
    public static final String NORWAY_PREFIX_ISO = 'NOR';
    public static final String NORWAY_CREDIT_PREFIX = 'NOC';
    public static final String TAIWAN_PREFIX = 'TWN';
    public static final String TAIWAN_CREDIT_PREFIX = 'TWNC';
    public static final String THAILAND_PREFIX = 'THA';
    public static final String THAILAND_CREDIT_PREFIX = 'THAC';
    public static final String MALAYSIA_PREFIX = 'MYS';
    public static final String MALAYSIA_CREDIT_PREFIX = 'MYSC';
    public static final String HONGKONG_PREFIX = 'HKG';
    public static final String HONGKONG_CREDIT_PREFIX = 'HKGC';
    public static final String SINGAPORE_PREFIX = 'SGP';
    public static final String SINGAPORE_CREDIT_PREFIX = 'SGPC';
    public static final String FRANCE_PREFIX = 'FRA';
    public static final String FRANCE_CREDIT_PREFIX = 'FRAC';
    public static final String BELGIUM_PREFIX = 'BEL';
    public static final String BELGIUM_CREDIT_PREFIX = 'BELC';
    public static final String NETHERLANDS_PREFIX = 'NLD';
    public static final String NETHERLANDS_CREDIT_PREFIX = 'NLDC';
     //GitLab #27336 - Added for UK & Ireland
    public static final String UNITEDKINGDOM_PREFIX = 'UK';
    public static final String IRELAND_PREFIX = 'IRE';
    public static final String UNITEDKINGDOM_CREDIT_PREFIX = 'UKC';
    public static final String IRELAND_CREDIT_PREFIX = 'IREC';
     //GitLab #27336 - End
    //Cluster 3 countries
    public static final String ROMANIA_PREFIX = 'RO';
    public static final String ROMANIA_CREDIT_PREFIX = 'ROC';
    public static final String SLOVAKIA_PREFIX = 'SK';
    public static final String SLOVAKIA_CREDIT_PREFIX = 'SKC';
    public static final String GREECE_PREFIX = 'GR';
    public static final String GREECE_CREDIT_PREFIX = 'GRC';
    public static final String CZECH_REPUBLIC_PREFIX = 'CZ';
    public static final String CZECH_REPUBLIC_CREDIT_PREFIX = 'CZC';
	 //Cluster 3A countries
    public static final String HUNGARY_PREFIX = 'HU';
    public static final String HUNGARY_CREDIT_PREFIX = 'HUC';
    public static final String AUSTRIA_PREFIX = 'AT';
    public static final String AUSTRIA_CREDIT_PREFIX = 'ATC';
    public static final String SPAIN_PREFIX_INVOICE = 'ES';
    public static final String SPAIN_PREFIX_CREDIT_NOTE = 'ESC';
    public static final String GERMANY_PREFIX = 'DE';
    public static final String GERMANY_PREFIX_CREDIT_NOTE = 'DEC';
    //#30973 #31259 Cluster 4 countries Turkey, New Zealand,Australia
    public static final String TURKEY_FATURA_DELIVERY_OPTION = 'e-Fatura';
    public static final String TURKEY_ARSIV_DELIVERY_OPTION = 'e-Arşiv';
    public static final String TURKEY_FATURA_PREFIX = 'IRM';
    public static final String TURKEY_FATURA_PREFIX_CREDIT_NOTE = 'IRMC';
    public static final String TURKEY_ARSIV_PREFIX = 'IRA';
    public static final String TURKEY_ARSIV_PREFIX_CREDIT_NOTE = 'IRAC';
    public static final String AUSTRALIA_PREFIX = 'AU';
    public static final String AUSTRALIA_PREFIX_CREDIT_NOTE = 'AUC';
    public static final String NEW_ZEALAND_PREFIX = 'NZ';
    public static final String NEW_ZEALAND_PREFIX_CREDIT_NOTE = 'NZC';
    public static final String DRAFT_INVOICE_RECORDTYPE = 'Draft Invoice';
    public static final String INVOICE_TAXSTATUS_COMPLETED = 'Completed';
  
    // public static final String INVOICE_SWEDEN_DM = '105';
    // public static final String INVOICE_SWEDEN_NONDM = '405';
  
    // blng__InvoiceLine__c constants
    public static final String INVOICELINE_STATUS_DRAFT = 'Draft';
    public static final String INVOICELINE_STATUS_POSTED = 'Posted';
    public static final String INVOICELINE_STATUS_WARNING = 'Warning';
    public static final String INVOICELINE_STATUS_CANCELLED = 'Cancelled';
    public static final String INVOICELINE_TAX_STATUS_COMPLETED = 'Completed';
  
    // blng__TaxIntegration__c constants
    public static final String TAXINTEGRATION_STANDARD = 'Standard';
    public static final String TAXINTEGRATION_AVALARA_AVA_TAX = 'Avlara Ava Tax';
  
    // blng__LegalEntity__c constants
    public static final String LEGALENTITY_TYPE_TAX = 'Tax';
    public static final String LEGALENTITY_TYPE_CONTRACT = 'Contract';
    public static final String LEGALENTITY_TYPE_FLAT = 'Flat Rate';
    public static final String LEGALENTITY_PRODUCT_BASED = 'Product Based';
  
    // blng__UsageSummary__c constants
    public static final String INVOICE_STATUS_PENDING_BILLING = 'Pending Billing';
    public static final String INVOICE_IN_PROGRESS = 'In Progress';
    public static final String INVOICE_COMPLETED = 'Completed';
    public static final String STATUS_QUEUED_FOR_INVOICE = 'Queued For Invoice';
    public static final String STATUS_PROCESSED = 'Processed';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_Cancelled = 'Cancelled';
    //blng__Usage__c constants
    public static final String USAGE_STATUS_WARNING_UNRATED = 'Warning - Unrated';
    public static final String USAGE_STATUS_ERROR = 'Error';
    public static final String USAGE_STATUS_PROCESSED = 'Processed';
  
    //  OrderItem constants
    public static final String CHARGE_TYPE_RECURRING = 'Recurring';
    public static final String CHARGE_TYPE_USAGE = 'Usage';
    public static final String CHARGE_TYPE_ONE_TIME = 'One-Time';
    public static final String SUBSCRIPTION_TYPE_EVERGREEN='Evergreen';
    public static final String SUBSCRIPTION_TYPE_RENEWABLE='Renewable';
    public static final String SUBSCRIPTION_TYPE_ONETIME='One-time';
    public static final String SITAD_PRODUCT_LINE = 'ALM-Secure ITAD';
  
    /*// Approval Notification Event
      public static final String NOTIFICATION_EVENT_INITIAL   = 'Initial';
      public static final String NOTIFICATION_EVENT_APPROVAL  = 'Approval';
      public static final String NOTIFICATION_EVENT_REJECTION = 'Rejection';
      public static final String NOTIFICATION_EVENT_RECALL    = 'Recall';*/
  
    //SObject API Name Constants
    public static final String SOBJECT_BLNG_CREDITNOTE = 'blng__CreditNote__c';
    public static final String SOBJECT_BLNG_CNL = 'blng__CreditNoteLine__c';
    public static final String SOBJECT_ORDERPRODUCT = 'OrderProduct';
    public static final String SOBJECT_ORDER = 'Order';
    public static final String SOBJECT_CONTRACT = 'Contract';
    public static final String SOBJECT_BLNG_USAGE = 'blng__Usage__c';
    public static final String SOBJECT_BLNG_USAGE_SUMMARY = 'blng__UsageSummary__c';
    public static final String SOBJECT_BLNG_INVOICELINE = 'blng__InvoiceLine__c';
    public static final String SOBJECT_ACCOUNT = 'Account';
    public static final String SOBJECT_OPPORTUNITYTEAM = 'OpportunityTeam';
    public static final String SOBJECT_QUOTE = 'SBQQ__Quote__c';
    public static final String SOBJECT_QUOTE_LINE = 'SBQQ__QuoteLine__c';
    public static final String SOBJECT_PURCHASEORDER = 'QTB_PurchaseOrder__c';
    public static final String SOBJECT_ACCOUNTCONTACTRELATION = 'AccountContactRelation';
    public static final String SOBJECT_BLNG_INVOICE = 'blng__Invoice__c';
    public static final String SOBJECT_USER = 'User';
    public static final String SOBJECT_QUOTE_DOCUMENT = 'SBQQ__QuoteDocument__c';
    public static final String SOBJECT_PURCHASEORDER_ACCOUNT = 'QTB_PurchaseOrderAccount__c'; //US #31455
    public static final String SOBJECT_BLNG_INVOICE_SCHEDULER = 'blng__InvoiceScheduler__c';
  
    // json response constants
    public static final String BILLCODERATES = 'billCodeRates';
    public static final String CURRENTRATEINFO = 'currentRateInfo';
    public static final string OK = 'OK';
    public static final Integer TWOHUNDRED = 200;
  
    //price fx end point constants
    public static final String PRICEFXNAMEDCREDENTIAL = 'callout:Pricefx_Credentials';
    public static final String CONSOLIDATERATESERVICE = '/consolidation/consolidated-rates-from-imsights';
    public static final String RMSERVICE = '/new-customer/rm';
    public static final String DMSERVICE = '/new-customer/dm';
    public static final String SHREDSERVICE = '/new-customer/ss';
  
    //ScheduleProcessName
    public static final String BILLING_RENEWAL_PROCESSNAME = 'Billing Renewal';
    public static final String BILLING_AMENDMENT_PROCESSNAME = 'Billing Renewal Amendment';
    public static final String BILLING_ASSOCIATION_PROCESSNAME = 'Billing Account Association';
    public static final String BILLING_ORDER_ACTIVATION_PROCESSNAME = 'Billing Order Process';
    public static final string STORAGE_CONSTANT = 'Storage';
    public static final string NONSTORAGE_CONSTANT = 'Non-Storage';
    public static final String BILLING_ERROR_LOG_IDS = 'BillingProcessEmailID';
    public static final String BILLING_ORDERPROCESS = 'Orderprocess';
  
    //AccountContactRelation Constants
    public static final String ACCOUNTCONTACTRELATION_TRIGGER = 'QTB_AccountContactRelationTrigger';
    public static final String ACCOUNTCONTACTRELATION = 'AccountContactRelation';
    public static final String PRIMARY_FIELD = 'QTB_Contact_Primary__c';
    public static final String ACCOUNTID = 'AccountId';
    public static final String ACCOUNTCONTACTRELATION_ROLES = 'Billing';
  
    //Account Constants
    public static final String ACCOUNT_RM = 'QTB_Records_Management__c';
    public static final String ACCOUNT_DM = 'QTB_Data_Management__c';
    public static final String ACCOUNT_SHRED = 'QTB_shred__c';
    public static final String ACCOUNT_SCAN = 'QTB_scan__c';
    public static final String ACCOUNT_LAST_DATE = 'QTB_LastModifiedDate__c';
    public static final String ACCOUNT_CONTACT_NAME = 'QTB_Contact_Name__c';
    public static final String ACCOUNT_LASTDATE = 'QTB_LastModifiedDate__c';
    public static final String ACCOUNT_CREATEDATE = 'QTB_CreatedDate__c';
    public static final String LEGAL_ENTITY = 'QTB_Legal_Entity_Number__c';
  
    //Quote Constants
    public static final String QUOTE_RENEWAL_DATE = 'QTB_Fee_Schedule_Renewal_Date__c';
  
    //Quote Template Constants
    public static final String DRAFT_PRICE = 'Price Quote';
    public static final String SERVICES = 'Services';
    public static final String SERVICES_OFF_SITE = 'Services Off-Site';
    public static final String SERVICES_ON_SITE = 'Services On-Site';
    public static final String STORAGE = 'Storage';
    public static final String SUPPLIES = 'Supplies';
    public static final String OTHERPROGRAMFEES = 'Other Program Fees';
    public static final String TRANSPORTATION = 'Transportation';
    public static final String QID = 'qid';
    public static final String LANGUAGE = 'language';
    public static final String TID = 'tid';
    public static final String ENGLISH_LANGUAGE = 'en_US';
    public static final String PRODUCT_NAME = 'Product Name';
    public static final String SECURE_SHREDDING = 'Secure Shredding';
    public static final String UNITED_STATES = 'United States';
    public static final String CANADA = 'United States';
    public static final String FRENCH_LANGUAGE = 'fr';
    public static final String QTB_PREFIX = 'QTB_';
    public static final String UNDERSCORE_CONST = '_';
    public static final String SPACE_CONST = ' ';
    public static final String SLASH_CONST = '/';
    public static final String HYPHEN_CONST = '-';
    public static final String FUEL_SURCHARGE = 'Fuel Surcharge';
    public static final String PAPER_SURCHARGE = 'Paper Recycling Surcharge';
    public static final String INITIAL_MOVE = 'Initial Move';
    
  
    //classname
    public static final String RENEWALUPLIFT_BATCH = 'QTB_RenewalUpliftBatch';
  
    //Platform Event Constants
    public static final String ORACLE_PE = 'QTB_Billing_Account_Oracle__e';
    public static final String BILLING_OS_PE = 'QTB_Billing_Account_OS__e';
    public static final String BILLTO = 'BILL TO';
    public static final String BILLING_OS_PE_COND = 'BillingAccountOS';
    public static final String SALESFORCE = 'Salesforce';
    public static final String DETAIL = 'Detail';
    public static final String ACTIVE = 'Active';
    public static final String IM_MONTHLY = 'IM_Monthly_1';
    public static final String FLAT_FLEE = 'N';
    public static final String CATALOG_CODE = 'DPS';
    public static final String PRIMARY_CONTACT_CHECK = 'true';
    public static final String SEND_STATEMENT = 'QTB_Send_Statements__c';
    public static final String SEND_DUNNING = 'QTB_Send_Dunning__c';
    public static final String BILLING_ORACLE_PE_COND = 'OraclePlatformEvent';
    public static final String PRICE_SCHEDULE_PE = 'QTB_Price_Schedule__e';
    public static final String PRICE_PE_COND = 'PriceSchedule';
    public static final String CUSTOMER_NUMBER = 'QTB_Parent_Billing_Account_Number__c';
    public static final boolean PRIMARY_QUOTE = true;
    public static final String PARENT_PAYABLE_MODEL = 'QTB_Parent_Payable_Model__c';
    public static final String CONTACT = 'Contact';
    public static final String NAME = 'Name';
    public static final String CONTACT_NAME = 'QTB_Contact_Name__c';
    public static final String Excluded_Country = 'Finland';
  
    //Profiles & Permission Sets
    public static final String CUSTOM_SYS_ADMIN = 'IM_Custom Sys Admin';
    public static final String SYS_ADMIN = 'System Administrator';
    public static final String BILLING_USER = 'QTB_Billing_User';
    public static final String CREATE_BILLING_ACCOUNT_USER = 'QTB_Create_Billing_Account';
  
    //Contract Scheduler constants
    public static final String GET_FIRST_RECORD = 'FirstRecord';
    public static final String CONTRACT_STRING = 'CONTRACT_PROCESSING';
  
    //Record Job constants
    public static final String RECORDJOB_COMPLETED = 'Completed';
    public static final String RECORDJOB_INPROGRESS = 'In Progress';
    public static final String RECORDJOB_FAILED = 'Failed';
    public static final Integer WAIT_TIME = 25000;
    public static final String JOBDETAIL_STRING = 'RenewContract';
  
    //State Constants
    public static final String CANADA_COUNTRY = 'Canada';
    public static final String US_COUNTRY = 'United States';
  }