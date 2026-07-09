/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Constants class, utilized to store the reusable Constants.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class NAS_Constants {
	public static final String TYPEVALUE = 'TYPE';
    public static final String CATEGORY = 'CATEGORY';
    public static final String QUEUE = 'QUEUE';
       
    public static final String NEWCASESTATUS = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_CASE_NEW');
    public static final String NEW_RECURRING_CASE_STATUS = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_CASE_NEW_RECURRING');
    public static final String NEW_IMC_CASE_STATUS = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_CASE_NEW_IMC');
	public static final String IMC = 'IMC';
    public static final String DEFAULT_CASE_PRIOROTY = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_PRIORITY_CASE_DEFAULT');
    public static final String IMCORIGIN =  NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_ORIGIN_CASE_IMC_DEFAULT');
    
    public static final String SUCCESS = 'Success';
    public static final String FAILURE = 'Failure';
    
    public static final String NA_CUSTOMER_ACCOUNT_RECORDTYPE = NAS_DataFactory.getApplicationConfiguration(
        											'RECORDTYPE_NA_CUSTOMER_ACCOUNT');
    public static final String IMC_CASE_RECORDTYPE = NAS_DataFactory.getApplicationConfiguration(
        											'RECORDTYPE_IMC_CASE');
    public static final String AUTHORIZED_ACTIVE_STATUS = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_AUTHORIZED_ACTIVE');
    
    public static final String IM_CASE_SUBJECT_PREFIX = NAS_DataFactory.getApplicationConfiguration(
        											'SUBJECT_PREFIX_IMC_CASE');
    public static final String SUCCESS_MESSAGE = Label.NAS_IMC_SUCCESS_MESSAGE + ' ';
    public static final String FAILURE_MESSAGE = Label.NAS_IMC_FAILURE_MESSAGE + ' ';
    
    public static final String PIN = 'PIN';
    public static final String LTNG_AUTH_CONTACT_COMPONENT_TITLE = Label.NAS_Additional_Security_Verification_Component_Title;
    public static final String LTNG_AUTH_CONTACT_ERROR_CODE = Label.NAS_Additional_Security_Verification_Error_Code;
    public static final String LTNG_AUTH_CONTACT_ERROR_MESSAGE = Label.NAS_Additional_Security_Verification_Error_Message;
    public static final String LTNG_AUTH_CONTACT_SYSTEM_ERROR_MESSAGE = Label.NAS_Additional_Security_Verification_Error_Message_System_Error;
    public static final String LTNG_AUTH_CONTACT_SUCCESS_CODE = Label.NAS_Additional_Security_Verification_Success_Code;
    public static final String LTNG_AUTH_CONTACT_SUCCESS_MESSAGE = Label.NAS_Additional_Security_Verification_Success_Message;
    public static final String LTNG_AUTH_CONTACT_SUBMIT_BUTTON_LABEL = Label.NAS_Additional_Security_Verification_Submit_Button_Label;
    public static final String LTNG_AUTH_CONTACT_INPUT_FIELD_LABEL = Label.NAS_Additional_Security_Verification_PIN_Input_Field;
    
    public static final String SKP_API_BASE_URL = NAS_DataFactory.getApplicationConfiguration('SKP_API_BASE_URL');
    //system.debug('SKP_API_BASE_URL=='+SKP_API_BASE_URL);
    public static final String RQTYPE_SKP_API_GET_REPLICATION_EVENTS = 'RQTYPE_SKP_API_GET_REPLICATION_EVENTS';
    public static final String URL_SKP_API_GET_REPLICATION_EVENTS = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_GET_REPLICATION_EVENTS_PATH');
        							
    public static final String RQTYPE_SKP_API_UPDATE_REPLICATION_EVENTS = 'RQTYPE_SKP_API_UPDATE_REPLICATION_EVENTS';
    public static final String URL_SKP_API_UPDATE_REPLICATION_EVENTS = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_UPDATE_REPLICATION_EVENTS_PATH');
        							
	public static final String RQTYPE_SKP_API_UPDATE_COMMUNICATOR = 'RQTYPE_SKP_API_UPDATE_COMMUNICATOR';
    public static final String URL_SKP_API_UPDATE_COMMUNICATOR = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_UPDATE_COMMUNICATOR');
        							
	public static final String RQTYPE_SKP_API_GET_SERVICE_MARKET = 'RQTYPE_SKP_API_GET_SERVICE_MARKET';
    public static final String URL_SKP_API_GET_SERVICE_MARKET = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_SERVICE_MARKET_PATH');
    
    public static final String UNAVAILABLE_REMOTE_SYSTEM = Label.NAS_Unavailable_Remote_System;
    public static final String EMPTY_RESPONSE_FROM_REMOTE_SYSTEM = Label.NAS_Empty_Response;
    
    public static final String LTNG_INFOWIN_COMPONENT_TITLE = Label.NAS_InfoWindow_Component_Title;
    public static final String LTNG_INFOWIN_SHOW_DETAILS_BUTTON_TAB_DESCRIPTION = Label.NAS_InfoWindow_Show_Details_Button_Label;
    
    public static final String NAS_GENERAL_SUPPORT_CASE_RECORDTYPE = NAS_DataFactory.getApplicationConfiguration(
        											'RECORDTYPE_NAS_GENERAL_SUPPORT_CASE');
    public static final String RECURRING_CASE_RECORDTYPE = NAS_DataFactory.getApplicationConfiguration(
        											'RECORDTYPE_NAS_RECURRING_SUPPORT_CASE');
    public static final String RECURRING_CASE_ACTIVE = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_CASE_RECURRING_ACTIVE');
    public static String RECURRING_CASE_CRON_EXPRESSION{
        public get {
            	return NAS_DataFactory.getApplicationConfiguration('RECURRING_CASE_CRON_EXPRESSION');
            }
        private set;
    }
    public static final String RECURRING_CASE_SCHEDULED_JOB_NAME = NAS_DataFactory.getApplicationConfiguration(
        											'RECURRING_CASE_SCHEDULED_JOB_NAME');
    public static final String DAY = 'DAY';
    public static final String MONTH = 'MONTH';
    public static final String YEAR = 'YEAR';
    
    public static final Integer RECURRING_CASE_BATCH_SIZE = Integer.valueOf(
        											NAS_DataFactory.getApplicationConfiguration(
        											'RECURRING_CASE_BATCH_SIZE'));
    public static final String RECURRING_CASE_PAGE_LAYOUT = NAS_DataFactory.getApplicationConfiguration(
        											'RECURRING_CASE_PAGE_LAYOUT');
    public static final String RECURRING_CASE_PAGE_LAYOUT_SECTION_NAME = NAS_DataFactory.getApplicationConfiguration(
        											'RECURRING_CASE_PAGE_LAYOUT_SECTION_NAME');
    public static final String CASE_PAGE_LAYOUT_PREFIX = 'Case-';
    
    public static final String SKP_AES_128_PRIVATE_KEY = NAS_DataFactory.getApplicationConfiguration(
        											'SKP_AES_128_PRIVATE_KEY');
    public static final String SKP_AES_128_INITIALIZATION_VECTOR = NAS_DataFactory.getApplicationConfiguration(
        											'SKP_AES_128_INITIALIZATION_VECTOR');
    public static final String RQTYPE_SKP_API_PIN_VERIFICATION = 'RQTYPE_SKP_API_PIN_VERIFICATION';
    public static final String URL_SKP_API_PIN_VERIFICATION = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_PIN_VERIFICATION_PATH');
    public static final String PICKLIST_STATUS_CONTACT_ACTIVE = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_CONTACT_ACTIVE');
    public static final String PICKLIST_AUTH_STATUS_CONTACT_VERIFIED = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_AUTH_STATUS_CONTACT_VERIFIED');
    public static final String PICKLIST_STATUS_CASE_NEW = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_CASE_NEW');
    public static final String SKP_API_BARRED_CHARACTERS = NAS_DataFactory.getApplicationConfiguration(
        											'SKP_API_BARRED_CHARACTERS');
    public static final String SKP_API_BARRED_CHARACTER_REPLACEMENT = NAS_DataFactory.getApplicationConfiguration(
        											'SKP_API_BARRED_CHARACTER_REPLACEMENT');
    public static final String IMC_STATUS_CONTACT_ACTIVE = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_IMC_STATUS_CONTACT_ACTIVE');
    public static final String SKP_STATUS_CONTACT_ACTIVE = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_SKP_STATUS_CONTACT_ACTIVE');
    public static final String MASTER_DIVISION_DEPARTMENT = '';
    public static final String MASTER_DIVISION_DEPARTMENT_CODE = NAS_DataFactory.getApplicationConfiguration(
        											'MASTER_DIVISION_DEPARTMENT_CODE');
    public static Integer GET_EVENTS_FREQUENCY_IN_MINUTES = Integer.valueOf(NAS_DataFactory.getApplicationConfiguration(
        											'GET_EVENTS_FREQUENCY_IN_MINUTES'));
    public static final String GET_EVENTS_SCHEDULED_JOB_NAME = NAS_DataFactory.getApplicationConfiguration(
        											'GET_EVENTS_SCHEDULED_JOB_NAME');
    public static final String CECOMM = 'CECOMM'; 
    public static final String SUBJECT_PREFIX_CECOMM_CASE = NAS_DataFactory.getApplicationConfiguration(
        											'SUBJECT_PREFIX_CECOMM_CASE');
    public static final String CECOMM_CASE_RECORDTYPE = NAS_DataFactory.getApplicationConfiguration(
        											'RECORDTYPE_NAS_GENERAL_SUPPORT_CASE');
    public static final String NEW_CECOMM_CASE_CASE_STATUS = NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_STATUS_CASE_NEW_CECOMM');
    public static final String CECOMM_ORIGIN =  NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_ORIGIN_CASE_CECOMM');
	public static final String CECOMM_CREATED =  NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_CECOMM_STATUS_CASE_CREATED');
	public static final String CECOMM_NOTIFIED =  NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_CECOMM_STATUS_CASE_NOTIFIED');
	public static final String CECOMM_CLOSED =  NAS_DataFactory.getApplicationConfiguration(
        											'PICKLIST_CECOMM_STATUS_CASE_CLOSED');
	public static final String CASE_STATUS_CLOSED =  'Closed';
	public static final String CECOMM_CASE_OWNER_QUEUE_NAME = NAS_DataFactory.getApplicationConfiguration(
        											'CECOMM_CASE_OWNER_QUEUE_NAME');
    public static final Id CECOMM_CASE_OWNER_QUEUE_ID = NAS_DataFactory.getApplicationConfiguration(
        											'CECOMM_CASE_OWNER_QUEUE_ID');
    public static final Integer BATCH_SIZE_GET_REPLICATION_EVENTS_CECOMM = Integer.valueOf(NAS_DataFactory.getApplicationConfiguration(
        											'BATCH_SIZE_GET_REPLICATION_EVENTS_CECOMM'));
    public static final Integer REQUEST_COUNT_GET_REPLICATION_EVT_CECOMM = Integer.valueOf(NAS_DataFactory.getApplicationConfiguration(
        											'REQUEST_COUNT_GET_REPLICATION_EVT_CECOMM'));
    public static final Integer CECOMM_BULK_NOTIFY_LIMIT =  Integer.valueOf(NAS_DataFactory.getApplicationConfiguration(
        											'LIMIT_BULK_SKP_NOTIFICATION_CECOMM'));
    public static final String WSG_BASE_URL = NAS_DataFactory.getApplicationConfiguration('WSG_BASE_URL');
    public static final String RQTYPE_WSG_AUTHORIZATION = 'RQTYPE_WSG_AUTHORIZATION';
    public static final String URL_WSG_AUTHORIZATION = NAS_Constants.WSG_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('WSG_AUTHORIZATION_PATH');
    public static final String WSG_CLIENT_KEY = NAS_DataFactory.getApplicationConfiguration('WSG_CLIENT_KEY');
    public static final String WSG_CLIENT_SECRET = NAS_DataFactory.getApplicationConfiguration('WSG_CLIENT_SECRET');
    public static final String WSG_IRM_APP_ID = NAS_DataFactory.getApplicationConfiguration('WSG_IRM_APP_ID');
    public static final String WSG_PASSWORD = NAS_DataFactory.getApplicationConfiguration('WSG_PASSWORD');
    public static final String WSG_USERNAME = NAS_DataFactory.getApplicationConfiguration('WSG_USERNAME');
    public static final String WSG_USERNAME_B64 = NAS_DataFactory.getApplicationConfiguration('WSG_USERNAME_B64');
    public static final String NAS_PLATFORM_CACHE_ORG_PARTITION_NAME = 'NASApplicationCache';
    public static final String NAS_PLATFORM_CACHE_WSG_AUTH_TOKEN_KEY = 'NASWSGAuthorizationToken';
	public static final Integer WSG_AUTH_TOKEN_TIMEOUT = Integer.valueOf(NAS_DataFactory.getApplicationConfiguration('WSG_AUTH_TOKEN_TIMEOUT'));
	
	public static final String NAS_APPLICATION_CACHE_NAME = 'NASApplicationCache';
	public static final String KEY_ORG_CACHE_WSG_AUTHORIZATION_TOKEN = 'NASWSGAuthorizationToken';
	public static final String KEY_ORG_CACHE_APPLICATION_CONFIGURATION = 'NASApplicationConfiguration';
	public static final String KEY_ORG_CACHE_TYPE_CATEGORY_MAPPING = 'NASTypeCategoryMapping';
	public static final String KEY_CASE_TEAM_OMNI_QUEUE = 'CASE_TEAM_OMNI_QUEUE';
	public static final List<Object> CASE_TEAM_OMNI_QUEUE_LIST = (List<Object>)JSON.deserializeUntyped(
														NAS_DataFactory.getApplicationConfiguration(NAS_Constants.KEY_CASE_TEAM_OMNI_QUEUE));
	public static final String SOURCE_SYSTEM_CODE_SKP_NA = NAS_DataFactory.getApplicationConfiguration('SOURCE_SYSTEM_CODE_SKP_NA');
	public static final String SOURCE_SYSTEM_CODE_SB_NA = NAS_DataFactory.getApplicationConfiguration('SOURCE_SYSTEM_CODE_SB_NA');
    public static final String NAS_ORDER_NUMBER_VALIDATION_MESSAGE = Label.NAS_ORDER_NUMBER_VALIDATION_MESSAGE;
    public static final String NAS_DATA_NOT_AVAILABLE = Label.NAS_DATA_NOT_AVAILABLE;
    public static final String NAS_UNKNOWN_ERROR = Label.NAS_UNKNOWN_ERROR;
    public static final String SKP_ERROR = 'SKP Error: ';

    public static final String NAS_BI_INFOWINDOW_BO_REPORT_LINK = Label.NAS_BI_INFOWINDOW_BO_REPORT_LINK;
    public static final String NAS_GET_SERVICE_MARKET_BUTTON_LABEL = Label.NAS_GET_SERVICE_MARKET_BUTTON_LABEL;
    public static final String NAS_Contact_Inactive_Error_Message = Label.NAS_Contact_Inactive_Error_Message;

    public static final String Milestone_Name_TCOP_Enrichment = NAS_DataFactory.getApplicationConfiguration('Milestone_Name_TCOP_Enrichment');
    public static final String Milestone_Name_Agent_Validation = NAS_DataFactory.getApplicationConfiguration('Milestone_Name_Agent_Validation');
    public static final String Milestone_Name_Resln_Cust_Folowup = NAS_DataFactory.getApplicationConfiguration('Milestone_Name_Resln_Cust_Folowup');
    public static final String INFOWIN_CUSTOMERINSTRUCTIONS_TABID = 'customerInstructions';
    public static final String INFOWIN_SERVICEPROFILE_TABID = 'serviceProfile';
    public static final String INFOWIN_BILLING_TABID = 'billing';
    public static final String INFOWIN_QA_TABID = 'qa';
    public static final String INFOWIN_DEER_TABID = 'deer';
    public static final String RQTYPE_SKP_API_INFOWIN_CUST_INSTR = 'RQTYPE_SKP_API_INFOWIN_CUST_INSTR';
    public static final String URL_SKP_API_INFOWIN_CUST_INSTR = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_CUSTOMER_INSTRUCTION_PATH');
     
    public static final String RQTYPE_SKP_API_INFOWIN_SRVC_PRFL = 'RQTYPE_SKP_API_INFOWIN_SRVC_PRFL';
    public static final String URL_SKP_API_INFOWIN_SRVC_PRFL = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_SERVICE_PROFILE_PATH');
    public static final String RQTYPE_SKP_API_INFOWIN_CUST_NOTES = 'RQTYPE_SKP_API_INFOWIN_CUST_NOTES';
    public static final String URL_SKP_API_INFOWIN_CUST_NOTES = NAS_Constants.SKP_API_BASE_URL + 
        							NAS_DataFactory.getApplicationConfiguration('SKP_API_NOTES_PATH');
	
	public static final String LTNG_INFOWIN_BILLING_TAB_DESCRIPTION = Label.NAS_InfoWindow_Billing_Tab_Description;
    public static final String LTNG_INFOWIN_BILLING_TAB_NAME = Label.NAS_InfoWindow_Billing_Tab_Name;
   	public static final String LTNG_INFOWIN_CUST_INSTR_TAB_DESCRIPTION = Label.NAS_InfoWindow_Customer_Instructions_Tab_Description;
    public static final String LTNG_INFOWIN_CUST_INSTR_TAB_NAME = Label.NAS_InfoWindow_Customer_Instructions_Tab_Name;
    public static final String LTNG_INFOWIN_DEER_TAB_DESCRIPTION = Label.NAS_InfoWindow_DEER_Tab_Description;
    public static final String LTNG_INFOWIN_DEER_TAB_NAME = Label.NAS_InfoWindow_DEER_Tab_Name;
    public static final String LTNG_INFOWIN_QA_TAB_DESCRIPTION = Label.NAS_InfoWindow_QA_Tab_Description;
    public static final String LTNG_INFOWIN_QA_TAB_NAME = Label.NAS_InfoWindow_QA_Tab_Name;
    public static final String LTNG_INFOWIN_SERVICE_PROFILE_TAB_DESCRIPTION = Label.NAS_InfoWindow_Service_Profile_Tab_Description;
    public static final String LTNG_INFOWIN_SERVICE_PROFILE_TAB_NAME = Label.NAS_InfoWindow_Service_Profile_Tab_Name;   
    public static final String NAS_RECURRING_EMAIL_RECIPIENTS = NAS_DataFactory.getApplicationConfiguration(
        											'NAS_Recurring_Email_Recipients');
    public static final String EMAIL_NOTIFICATION_ACTIVATOR = 'Email_Notification_Activator';
    
}