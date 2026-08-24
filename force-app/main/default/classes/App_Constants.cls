/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Class : App_Constants
* Date : 4th JUN 2020
* Class Description : Constants class, utilized to store the reusable Constants
* Constants used for trigger helper classes and other apex classes.
* Added By : arajendran (BCT)
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/


public with sharing class App_Constants {  
   
    public static final string IME_STD_OPPORTUNITY_RECTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('IME_Standard_Opportunity').getRecordTypeId();
    public static final string IMAP_STD_OPPORTUNITY_RECTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('IMAP_Standard_Opportunity').getRecordTypeId();
    public static final string IMLA_STD_OPPORTUNITY_RECTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('IMLA_Standard_Opportunity').getRecordTypeId();
    public static final string Team_MemberROLE_NA_SALES_UNIT = 'NA - Tactical Sales Unit';
    public static final string STD_OPPORTUNITY_RECTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
    public static final string FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Framework_Parent_Opportunity').getRecordTypeId();
    public static final Set<string> OPPORTUNITY_STAGE = new Set<String>{'2 - Solution Developed','3 - Solution Agreed','4 - Negotiate'
                                                                        ,'5 - Signed/PO in','6 - Setup','7 - Closed'
                                                                        ,'Lost','Dead','Postponed','0 - Forecast'
                                                                        ,'1 - Under Review','2 - Price Plan Set'
                                                                        ,'3 - Manager Review','4 - Revenue Management Review'
                                                                        ,'5 - Closed - In Fulfillment','5 - Closed - Rates Uploaded'
                                                                        ,'Deferred','Excluded','Expired'}; 
    public static final string CPQ_BILLING_OPPORTUNITY_RECTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CPQ_Billing_Opportunity').getRecordTypeId();
    public static final string CPQ_SALES_OPPORTUNITY_RECTYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('CPQ_Sales_Opportunity').getRecordTypeId();
                                                                 
                                                                            
    /* --- Contract Object Record Type(RT) Ids --- */
     public static final Id RT_ID_IME_ADDENDUM_CONTRACT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('IME_Addendum').getRecordTypeId();
     public static final Id RT_ID_IME_ADDENDUM_EXTENSION_CONTRACT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('IME_Addendum_Extension').getRecordTypeId();
     public static final Id RT_ID_IME_CHILD_CONTRACT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('IME_Child_Contract').getRecordTypeId();
     public static final Id RT_ID_IME_CONTRACT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('IME_Contract').getRecordTypeId();
    
    /* --- Picklist values of IM Contract Term Types from Contract Object */
     public static final string CONTRACT_TERM_FIXED_TERM = 'Fixed term';
     public static final string CONTRACT_TERM_EVERGREEN = 'Evergreen';
     public static final string CONTRACT_TERM_EVERGREEN_OPEN_ROLLING = 'Evergreen (open rolling)';
    
     //Added by Yetender on 4 AUG 2020,W-000579
    /*--- Picklist values for Status field from Contract Object */
    public static final string CONTRACT_STATUS_DRAFT = 'Draft';
    public static final string CONTRACT_STATUS_ACTIVATED = 'Activated';
    public static final string CONTRACT_STATUS_CANCELLED = 'Cancelled';
    public static final string CONTRACT_STATUS_TERMINATED = 'Terminated';
    
    //Contract RecordType DeveloperName
     public static final string IME_PARENTCONTRCT_DEVELOPERNAME = 'IME_Contract';
     public static final string IME_CHILDCONTRACT_DEVELOPERNAME = 'IME_Child_Contract';
     public static final string IME_ADDENDUMEXTENSION_DEVELOPENAME = 'IME_Addendum_Extension';

    /* --- Case Object Record Type Ids (used by CaseFieldMappingEngine's eligibility gate) --- */
    public static final Id B2B_IMPLEMENTATION_CASE_RECTYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Support').getRecordTypeId();
    public static final Id DEAL_SUPPORT_CASE_RECTYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Deal_Support').getRecordTypeId();
}