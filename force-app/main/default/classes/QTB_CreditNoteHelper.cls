/*****************************************************************************************************
 * Class         : QTB_CreditNoteHelper
 * Test Class    : QTB_CreditNoteHelper_Test
 * Author        : Accenture
 * Purpose       : This is a helper class for all business logic related to Credit Note object
 * Change History: 4/29/2020
 * Developer         Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture         05/29/2020
 * Accenture         04/06/2021       GitLab # 1731, if the credit note is allocated with Custom Rebill reason
 *                                    code, the invoice status will be updated to IRM Rebill
 * Virtusa           11/09/2021       Gitlab #857 - Credit Note Tax calculation using Vertex for NA region
 * Virtusa           12/16/2021       Gitlab #6056 - Vertex Tax Integration for Posted Invoice
 * Gopi/Shailesh     06/30/2022       Gitlab US #9256 Credit & Rebill //Credit ReBill By IRM/Virtusa
 * TCS               11/10/2022       Gitlab US #10736 Credit & Rebill
 * TCS               04/20/2023       Gitlab US #14899 Credit Rebill Schedular invoked Dynamically
 * Ramesh/Shailesh   05/30/2023       Gitlab US #15242,14752 Create Credit Note from Account Level Related List - 1
 * Parth             05/10/2023       Gitlab #15553 - tax detail record creation on credit note lines when credit note are posted.
 * Karthik TCS       06/02/2023       Gitlab US #16104 & 16075 & 16304 On Account Credit note scenario for Billing only countries
 * Shailesh/Ramesh   26/02/2024       Gitlab US #20721 Refactoring/Restructure of Code
 *******************************************************************************************************/
public with sharing class QTB_CreditNoteHelper {
    private static final String CLASSNAME = QTB_CreditNoteHelper.class.getName();
    public static boolean isPOEligibleCountry = false;
    public static List<blng__CreditNoteLine__c> CreditNoteLineList;
    /***********************************************************************************************************
     * Method :      process
     * Parameters:   List<blng__CreditNote__c>,Map<Id, blng__CreditNote__c>,Map<Id, blng__CreditNote__c>,System.TriggerOperation
     * Return Type : void
     * Description:  This method loops over the list of records to be processed
     **************************************************************************************************************/
    public static void process(  List<blng__CreditNote__c> newItems, Map<Id, blng__CreditNote__c> mapOfNewCreditNotes,
    Map<Id, blng__CreditNote__c> mapOfOldCreditNotes,System.TriggerOperation operationType )
    {
        try {
            if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            List<blng__CreditNote__c> PostedCreditNotes = new List<blng__CreditNote__c>();  // CreditNoteIdGeneration
            Set<ID> postedCreditNoteIds = new Set<ID>();//Adding variable postedCreditNoteIds for Purchase Order Balance Update logic
            Set<Id> AccountId = new Set<ID>();
            Map<Id, blng__CreditNote__c> mapOfCreditNoteIdsInApproval = new Map<Id, blng__CreditNote__c>(); // Collection of Credit Notes those are in approval
            Set<Id> setOfApproverIds = new Set<Id>();// Set of Approvers who will be notified
            Set<Id> customRebillInvoiceIds = new Set<Id>(); // Invoices to be marked for IRM Rebill, GitLab GITLAB US #1731
            Set<Id> newRebillInvoiceIds = new Set<Id>(); // Invoices to be removed, GitLab US #3483
            Set<id> creditNoteSetIDs = new Set<id>();
            Set<id> postedCRDNIds = new Set<id>(); // capture posted creditnote for Duplicate creditnote //25457
            Set<id> correctAmountCrNoteId = new Set<id>(); // capture the creditnoteId for Correct Amount calculation #27320
            Set<id> creditonlySetIDs = new Set<id>();
            string postedCrediteNote = null;
            Set<Id> parentInvoiceIdInsert = new Set<Id>(); //Credit ReBill By IRM/Virtusa
            Set<Id> parentInvoiceIdUpdate = new Set<Id>(); //Credit ReBill By IRM/Virtusa
            List<blng__CreditNote__c> sitadCreditNotes = new list<blng__CreditNote__c>();
            Set<Id> sitadAccountIds = new Set<Id>();
            List<QTB_CreditRebillVertexCall__e > creditRebillVertexCallEvents = new List<QTB_CreditRebillVertexCall__e >();//Credit ReBill By IRM/Virtusa
            boolean isVertexTaxCall = false;
            //GITLAB US #16104 created Set to store Credit Note Account Ids for firing validations based on Account LOBS's
            Set<Id> onCreditnoteAccountIds  = new Set<Id>();
            // GITLAB US #16075 Added one Boolean variable for Bypassing the Validation rule for Billing countries
            Boolean onAccountCreditBillingCountry = false;
            Boolean callCN_CheckRestrictedFields = false;//GITLAB US #20672
            Boolean callCN_ParentBillingAccount = false;//GITLAB US #20391
            // 23170 Created below Set for storing Legacy Invoice Ids
            set<Id> legacyPostedCNInvoiceIds = new Set<Id>();
            //#26371 Created a Map to store ids of newly created Credit Notes and value as credit note
            Map<Id,blng__CreditNote__c> cNDueDateUpdateMap = new map<Id,blng__CreditNote__c>();
            //26654 Created Map for storing the Ids and Credit Note for Updating the Exchange Rate based upon Foreign Exchange object (Local Currency)
            Map<Id,blng__CreditNote__c> cnExchangeRateUpdateMap = new map<Id,blng__CreditNote__c>();
            //#28078 Created extra Map for storing Non Account credit related stuff for Exchange rate stampage
            Map<Id,blng__CreditNote__c> cnExchangeRateInvRefUpdateMap = new map<Id,blng__CreditNote__c>();
            set<blng__CreditNote__c> commercialCNIds = new Set<blng__CreditNote__c>();//Commercial CN Validation
            // GITLAB US #857 -- Fetching value from Tax Integration Metadata, to check vertex tax country
            QTB_Tax_Integration_Setting__mdt countryValForVertex = QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration');
            Map<Id,blng__CreditNote__c> finalSingleUpdateCreditNoteMap = new Map<Id,blng__CreditNote__c>(); //GITLAB #27320
            //GITLAB US #15242 -- Created map to store legalEntityCountry with AccountLevelCustomMetadata
            Map<String,QTB_Account_Level_Credit_Note_Setting__mdt> legalCountryWithAccLevelCreditMetadataMap = new Map<String,QTB_Account_Level_Credit_Note_Setting__mdt>();
            // #29361 Set to store Credit Note Ids Automate invoice notes
            Map<Id, blng__CreditNote__c> crdIdAndCrdMap = new Map<Id, blng__CreditNote__c>();
            
            for(QTB_Account_Level_Credit_Note_Setting__mdt accLevelCreditMeta : QTB_Account_Level_Credit_Note_Setting__mdt.getAll().values())
            {
                String country = (accLevelCreditMeta.QTB_Acc_LegalEntityCntry__c).toLowerCase();
                legalCountryWithAccLevelCreditMetadataMap.put(country,accLevelCreditMeta);
            }
            
            switch on operationType {
                when BEFORE_UPDATE {
                    //25283
                    if(System.Label.IsCreditNoteFieldsNonEditableForPosted == 'true'){
                        makeFieldsNonEditableForPosted(newItems,mapOfOldCreditNotes);
                    }
                    if(System.Label.IsCreditNoteFieldsReadOnlyForProcessed == 'true'){
                        //  makeFieldsReadyOnlyForPosted(newItems,mapOfOldCreditNotes);
                    }
                    if(Test.isRunningTest()){
                        makeFieldsNonEditableForPosted(newItems,mapOfOldCreditNotes);
                        makeFieldsReadyOnlyForPosted(newItems,mapOfOldCreditNotes);
                    }
                }
            }
            Boolean isTaxDetailAvailableAfterRetry = false; //Duplicate CreditNote number
            
            for(blng__CreditNote__c eachCreditNote : newItems)
            {
                //Start 26026 Duplicate CreditNote Number
                if(eachCreditNote.IsTaxDetailPresent__c){
                    isTaxDetailAvailableAfterRetry = true;
                }
                //Stop 26026 Duplicate CreditNote Number
                callCN_ParentBillingAccount = true; //GITLAB US #20391
                // GITLAB US #16075 Added If Condition for Bypass the Fair Market Value Validation rule for Billing countries by creating Label
                if(eachCreditNote.QTB_Country__c != null && System.Label.QTB_On_Acc_Credit_for_Billing_Only_Eligible_Countries.contains(eachCreditNote.QTB_Country__c))
                {
                    onAccountCreditBillingCountry = True;
                }
                //Setting isVertexTaxCall boolean value to true for NA countries(UnitedStates & Canada)
                //Excluding Vertex taxation for "Credit Only" functionality, bcoz we are copying taxes from Invoice to creditnote
                if(countryValForVertex.QTB_End_System__c == 'Vertex' && eachCreditNote.QTB_Country__c != null &&
                    eachCreditNote.QTB_Credit_Note_Type__c !='Credit Only' && countryValForVertex.QTB_Country__c.containsIgnoreCase(eachCreditNote.QTB_Country__c))
                {
                    isVertexTaxCall = true;
                }
                switch on operationType {
                    when BEFORE_INSERT {
                        //ReadyForIntegration change
                        eachCreditNote.QTB_Transferred_To_Oracle__c = false;
                        // Gitlab #28277 - setting the fields to blank for credit only and Rebill credit notes
                        if((eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only' || eachCreditNote.QTB_Credit_Note_Type__c == 'ReBill' ||
                        eachCreditNote.QTB_Credit_Note_Type__c == 'Split ReBill') && eachCreditNote.blng__Status__c == 'Draft'){
                            eachCreditNote.QTB_Transferred_to_Invoice_Compliance__c = null;
                            eachCreditNote.QTB_transfered_to_invoice_presentment__c = null;
                            eachCreditNote.QTB_Compliance_Ref_Number__c = null;
                            eachCreditNote.QTB_Compliance_Ack_Date__c = null;
                            eachCreditNote.QTB_Compliance_Ack_Number__c = null;
                            eachCreditNote.QTB_Compliance_QR_Code__c = null;
                            eachCreditNote.QTB_Compliance_Status__c = null;
                            eachCreditNote.QTB_Compliance_Message__c = null;
                        }
                        if(eachCreditNote.QTB_On_Account_Credit__c) // On Account is true
                        {   // GITLAB US #20082 to capture the credit note type for On Account Credit note
                            //29685 Added below if loop to By pass the credit Note Type name to be as On Account credit (It should be Legacy Credit for both Credit only and Credit Rebill Scenarios)
                            if(eachCreditNote.QTB_Related_Legacy_Invoice__c == Null){
                                eachCreditNote.QTB_Credit_Note_Type__c = 'On Account Credit';
                            }
                            //GITLAB US #16104 Adding Before Insert AccountIds of On Account is true for Credit Note for throwing Validation of Account and Its LOB not available for On Accountnscenario
                            onCreditnoteAccountIds.add(eachCreditNote.blng__Account__c);
                            //GITLAB US #15242 -- AccountLevelCredit -- throwing validation message if other than "Remarketing Credit" reason code selected for accountLevelCredit
                            //GITLAB US #16075 -- Adding Not condition for Bypassing the Validation that is existing for Billing countries
                            //Other than Billing country (north america - united states & canada)
                            //GITLAB US #23743 -- NA-SITAD AccountLevelCredit -- throwing validation message if other than "Remarketing Credit/Legacy Credit/Fair Market Value" reason code selected for accountLevelCredit
                            if(!onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c !=null)
                            {
                                if((!eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode) && eachCreditNote.QTB_SITAD__c == false) ||
                                (!System.label.QTB_OnAccountCreditReasonCode_SITAD.contains(eachCreditNote.QTB_Reason_Code__c) && eachCreditNote.QTB_SITAD__c == true)){
                                    if(eachCreditNote.QTB_SITAD__c == false){//it is for NON NA-SITAD
                                        eachCreditNote.addError(System.label.QTB_OnAccountCreditReasonCodeValidation1);
                                    }else{//it is for NA-SITAD
                                        eachCreditNote.addError(System.label.QTB_OnAccountCreditReasonCodeValidation_SITAD);
                                    }
                                }
                            }
                            //GITLAB US #23743 - End
                            //GITLAB US #16304 -- AccountLevelCredit -- throwing validation message if other than "Legacy Credit" reason code selected for accountLevelCredit for Billing only countries
                            //BillingOnly countries
                            //#34240 Updated System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c) from eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode) 
                            else if(onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c !=null && !System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c))
                            {
                                eachCreditNote.addError(system.label.QTB_OnAccountCreditReasonCodeBillingOnlyValidation1);
                            }
                        }
                        else // On Account is false
                        {
                            //GITLAB US #30332 -- Manual Credit -- Condition added to handle Manual Credit
                            if(eachCreditNote.QTB_IsReBill__c == false &&
                               eachCreditNote.QTB_Credit_Note_Type__c != 'Credit Only' && eachCreditNote.QTB_Credit_Note_Type__c != 'Legacy Credit'){
                                   eachCreditNote.QTB_Credit_Note_Type__c = 'Manual Credit';
                               }
                            //GITLAB US #15242 -- AccountLevelCredit -- throwing validation message if "Remarketing Credit" reason code selected and On Account Credit is false for accountLevelCredit
                            //GITLAB US #16075 -- Adding Not condition for Bypassing the Validation that is existing for Billing countries
                            if(!onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c !=null && eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode))
                            {
                                eachCreditNote.addError(System.label.QTB_OnAccountCreditReasonCodeValidation2);
                            }
                            //GITLAB US #16304 -- AccountLevelCredit -- throwing validation message if "Legacy Credit" reason code selected and On Account Credit is false for accountLevelCredit for Billing only countries
                            //25753 Adding the related legacy Invoice check and Credit Note Type as not equals to Legacy Credit
                            //#34240 Updated System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c) from eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode) 
                            else if(onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c !=null &&  System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c)
                                && eachCreditNote.QTB_Related_Legacy_Invoice__c == Null && eachCreditNote.QTB_Credit_Note_Type__c != 'Legacy Credit')
                            {
                                eachCreditNote.addError(system.label.QTB_OnAccountCreditReasonCodeBillingOnlyValidation2);
                            }
                        }
                        // Commercial Credit note check out of India
                        if(eachCreditNote.QTB_Country__c != null && eachCreditNote.QTB_Country__c != 'India' && eachCreditNote.QTB_Commercial_Credit__c == TRUE){
                            eachCreditNote.addError(system.label.QTB_Commercial_Credit_outside_India);
                        }
                        //#25446 On Account Creditnote Validation - PO number and Site numbers are mandatory for On Account Credit type and SITAD account
                        // GitLab US #28779 Po number is not mandatory
                        system.debug('creditNote###'+eachCreditNote.QTB_Credit_Note_Type__c);
                        //GitLab 29058 - Start - Added Case Number also mandatory for cluster 1 countries
                        if(eachCreditNote.QTB_Credit_Note_Type__c == 'ON Account Credit'  && (eachCreditNote.QTB_Site_Number__c == null || eachCreditNote.QTB_Case_Number__c == null) &&
                           eachCreditNote.QTB_SITAD__c == true && System.Label.QTB_SITAD_Countries.contains(eachCreditNote.QTB_Country__c)){
                            eachCreditNote.addError(system.label.QTB_Creditnote_OnAccount_Validation);
                        }
                        //GitLab 29058 - End 
                       //#27757 changes- Populating Case number on Notes.
                        if(eachCreditNote.QTB_SITAD__c && 
                            System.label.QTB_SITAD_Cluster1_Countries.contains(eachCreditNote.QTB_Country__c)){
                                sitadAccountIds.add(eachCreditNote.blng__Account__c);
                                sitadCreditNotes.add(eachCreditNote);
                           
                        }
                    }
                    when BEFORE_UPDATE {
                        // Gitlab- 30684 Start
                        if(eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.ID).QTB_On_Account_Credit__c && eachCreditNote.QTB_On_Account_Credit__c == false) 
                        {
                            eachCreditNote.QTB_Credit_Note_Type__c = 'Manual Credit';
                        }
                        else if(eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.ID).QTB_On_Account_Credit__c && eachCreditNote.QTB_On_Account_Credit__c == true)
                        {
                            eachCreditNote.QTB_Credit_Note_Type__c = 'ON Account Credit';
                        }
						// Gitlab- 30684 Ends
                        //#26371 calling method to stamp CN Due date for Hungary from Invoice due date
                        //Gitlab US #31327 Due date auto-population for NA-SITAD CNs
                        if((eachCreditNote.ApprovalStatus__c == QTB_Constants.APPROVAL_STATUS_PENDING || (system.label.QTB_NA_Countries.contains(eachCreditNote.QTB_Country__c) && eachCreditNote.QTB_SITAD__c == true)) &&
                            eachCreditNote.ApprovalStatus__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).ApprovalStatus__c)
                        {
                            if(eachCreditNote.QTB_Country__c == 'Hungary' && eachCreditNote.QTB_On_Account_Credit__c == false){
                                cNDueDateUpdateMap.put(eachCreditNote.id,eachCreditNote);
                            }
                            else{
                                eachCreditNote.QTB_Due_Date__c = eachCreditNote.blng__CreditNoteDate__c;
                            }
                        }
                        //#26371 ends
                        //GITLAB US #12856 - To make QTB_Custom_Invoice_Number__c blank when creditnote is generated and in draft status
                        //GITLAB US #19803 - Added condition for Credit Only to make QTB_Custom_Invoice_Number__c blank when creditnote is generated
                        if(eachCreditNote.blng__Status__c == 'Draft' && (eachCreditNote.QTB_IsReBill__c == true || eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only') )
                        {
                            eachCreditNote.QTB_Custom_Invoice_Number__c = '';
                            eachCreditNote.QTB_Ready_for_Integration__c = false;        //26026
                            eachCreditNote.QTB_Ready_for_Integration_Status__c = '';    //26026
                            
                        }
                        //GITLAB US #19895 setting vertex request and response field to blank on Credit Only scenerio
                        if(eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only' && (eachCreditNote.QTB_IRM_to_Vertex_Tax_Request__c != null || eachCreditNote.QTB_IRM_to_Vertex_Tax_Response__c != null) )
                        {
                            eachCreditNote.QTB_IRM_to_Vertex_Tax_Request__c = '';
                            eachCreditNote.QTB_IRM_to_Vertex_Tax_Response__c = '';
                        }
                        //#26654 Changing the position of eachCreditNote.blng__Status__c == 'Draft' for reuse purpose
                        if(eachCreditNote.blng__Status__c != null && eachCreditNote.blng__Status__c == 'Draft' && eachCreditNote.blng__Subtotal__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Subtotal__c )
                        {
                            //#26654 Adding the InvocieIds as Key and Value as Invoice whenever status is changed and its equals to Draft for calling the method updateExchangeRate for stamping the Exchange Rate based upon Foreign Exchange object
                            //Adding the new Formula field which will decide whether its a Forex Credit Note or not
                            //#28078 Added whether its an On Account Credit
                            if(eachCreditNote.QTB_Foreign_Exchange_Applicable__c){
                                if(eachCreditNote.QTB_On_Account_Credit__c){
                                    cnExchangeRateUpdateMap.put(eachCreditNote.id,eachCreditNote);
                                }
                                //#28078 Added else if to check whether its not an Account Credit for differenciating the Invoice reference
                                else{
                                    cnExchangeRateInvRefUpdateMap.put(eachCreditNote.id,eachCreditNote);
                                }
                            }
                            //GITLAB US #857 -- for NA region-- Tax gets calculated using Vertex service, therefore added Country check
                            //#26654 Removal of eachCreditNote.blng__Status__c == 'Draft' and Adding above If loop
                            if(isVertexTaxCall){
                                creditNoteSetIDs.add(eachCreditNote.id);
                                postedCrediteNote=null; //for Draft CreditNote status sending as null
                            }
                        }
                        // update record type and custom invoice number
                        if (eachCreditNote.blng__Status__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Status__c &&
                            eachCreditNote.blng__Status__c == QTB_Constants.CREDITNOTE_STATUS_POSTED)
                        {
                            PostedCreditNotes.add(eachCreditNote);
                            postedCRDNIds.add(eachCreditNote.id);//26026
                            AccountId.add(eachCreditNote.blng__Account__c);
                            if(!isVertexTaxCall)
                            {
                                // SFCPQBLG-518 changing the record type of the credit note
                                eachCreditNote.recordTypeId = QTB_Utils.CREDITNOTE_POSTED_RECTYPEID;
                            }
                            if (eachCreditNote.QTB_CreditNote_Posted_Date__c == NULL)
                            {
                                eachCreditNote.QTB_CreditNote_Posted_Date__c = System.today();
                            }
                        }
                        
                        // GITLAB US # 3483, if custom rebill credit note is rejected
                        // get the rebill invoice and undo the entire rebill process by removing those records
                        if( String.isNotEmpty(eachCreditNote.QTB_Rebill_Invoice__c) && String.isNotEmpty(eachCreditNote.blng__RelatedInvoice__c) &&
                            eachCreditNote.ApprovalStatus__c == 'Rejected' && eachCreditNote.ApprovalStatus__c <>  mapOfOldCreditNotes.get(eachCreditNote.Id)?.ApprovalStatus__c)
                        {
                            eachCreditNote.blng__Status__c = 'Cancelled';
                        }
                        //Credit ReBill By IRM/Virtusa GITLAB US #9256
                        //For Rejected CreditNOte, cancelling the credit Note
                        if((eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only' || eachCreditNote.QTB_IsReBill__c == true) && String.isNotEmpty(eachCreditNote.blng__RelatedInvoice__c) &&
                            eachCreditNote.ApprovalStatus__c == 'Rejected' && eachCreditNote.ApprovalStatus__c <>  mapOfOldCreditNotes.get(eachCreditNote.Id)?.ApprovalStatus__c)
                        {
                            eachCreditNote.blng__Status__c = 'Cancelled';
                        }
                        //Credit ReBill By IRM/Virtusa US #9256
                        //For AutoApproved CreditNote, Posting the credit Note
                        if((eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only' || eachCreditNote.QTB_IsReBill__c == true) && String.isNotEmpty(eachCreditNote.blng__RelatedInvoice__c) &&
                            eachCreditNote.ApprovalStatus__c == 'Approved' && eachCreditNote.ApprovalStatus__c <>  mapOfOldCreditNotes.get(eachCreditNote.Id)?.ApprovalStatus__c)
                        {
                            eachCreditNote.blng__Status__c = 'Posted';
                            eachCreditNote.recordTypeId = QTB_Utils.CREDITNOTE_POSTED_RECTYPEID;
                            eachCreditNote.QTB_CreditNote_Posted_Date__c = System.today();
                            if(!PostedCreditNotes.contains(eachCreditNote))
                            {
                                PostedCreditNotes.add(eachCreditNote);
                                postedCRDNIds.add(eachCreditNote.id);//26026
                                AccountId.add(eachCreditNote.blng__Account__c);
                            }
                        }
                        // GITLAB US #19464 - If credit note status updated to cancelled manually update the recordtype Applicable
                        // only to manual credit note and ON Account credit note scenerio
                        if (eachCreditNote.blng__Status__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Status__c &&
                            eachCreditNote.blng__Status__c == 'Cancelled')
                        {
                            eachCreditNote.recordTypeId = QTB_Utils.CREDITNOTE_POSTED_RECTYPEID; //setting recordtype for Cancelled CreditNote
                        }
                        // GITLAB US #21230 - If user tries to update the credit note date on cancelled credit note user gets an error message
                        if (eachCreditNote.blng__CreditNoteDate__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__CreditNoteDate__c &&
                            eachCreditNote.blng__Status__c == 'Cancelled')
                        {
                            eachCreditNote.addError(system.label.QTB_CancelledCreditNoteValidation);
                        }
                        //GITLAB US #15242 -- AccountLevelCredit -- On Account Credit checkbox not allowing to modify if associated credit note lines present
                        if(eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_On_Account_Credit__c &&
                            eachCreditNote.QTB_CreditNoteLineCount__c > 0 )
                        {
                            eachCreditNote.addError(System.label.QTB_OnAccountCreditChangeValidation);
                        }
                        //GITLAB US #15242 -- AccountLevelCredit -- throwing validation message if other than "Remarketing Credit" reason code selected for accountLevelCredit
                        //GITLAB US #22186 -- As part of testing after code restructuring its observed validation is firing incorrectly, to fix the issue credit note type check is removed
                        //Also, validation related to credit note type field using - label QTB_Validationif_creditNoteType_Present is removed as its not required anymore. As Credit note type
                        //field is made read-only in pagelayout level
                        if(eachCreditNote.QTB_On_Account_Credit__c) // On Account is true
                        {
                            //GITLAB US #16104 Adding Before Update AccountIds of Credit note that are On Account check box updated for throwing Validation Not Applicable scenarios fro On Account
                            if(eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_On_Account_Credit__c)
                            {
                                onCreditnoteAccountIds.add(eachCreditNote.blng__Account__c);
                            }
                            if((eachCreditNote.QTB_Reason_Code__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_Reason_Code__c) ||
                                (eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_On_Account_Credit__c))
                            {
                                //GITLAB US #16075 -- Adding Not condition for Bypassing the Validation that is existing for Billing countries
                                //GITLAB US #23743 -- NA-SITAD AccountLevelCredit -- throwing validation message if other than "Remarketing Credit/Legacy Credit/Fair Market Value" reason code selected for accountLevelCredit
                                if(!onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c !=null)
                                {
                                    if((!eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode) && eachCreditNote.QTB_SITAD__c == false) ||
                                    (!System.label.QTB_OnAccountCreditReasonCode_SITAD.contains(eachCreditNote.QTB_Reason_Code__c) && eachCreditNote.QTB_SITAD__c == true)){
                                        if(eachCreditNote.QTB_SITAD__c == false){//it is for NON NA-SITAD
                                            eachCreditNote.addError(System.label.QTB_OnAccountCreditReasonCodeValidation1);
                                        }else{//it is for NA-SITAD
                                            eachCreditNote.addError(System.label.QTB_OnAccountCreditReasonCodeValidation_SITAD);
                                        }
                                    }
                                }
                                //GITLAB US #23743 - End
                                //GITLAB US #16304 -- AccountLevelCredit -- throwing validation message if other than "Legacy Credit" reason code selected for accountLevelCredit for Billing only Countries
                                //#34240 Updated System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c) from eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode) 
                                else if(onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c !=null &&
                                    !System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c))
                                {
                                    eachCreditNote.addError(system.label.QTB_OnAccountCreditReasonCodeBillingOnlyValidation1);
                                }
                            }
                        }
                        else // On Account is false
                        {
                            //GITLAB US #15242 -- AccountLevelCredit -- throwing validation message if "Remarketing Credit" reason code selected and On Account Credit is false for accountLevelCredit
                            if((eachCreditNote.QTB_Reason_Code__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_Reason_Code__c)||
                                (eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_On_Account_Credit__c))
                            {
                                //GITLAB US #16075 -- Adding Not condition for Bypassing the Validation that is existing for Billing countries
                                //throwing validation error if user is selecting Remarking Credit as reason code
                                if(!onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c !=null &&eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode))
                                {
                                    eachCreditNote.addError(System.label.QTB_OnAccountCreditReasonCodeValidation2);
                                }
                                //GITLAB US #16304 -- AccountLevelCredit -- throwing validation message if "Legacy Credit" reason code selected and On Account Credit is false for accountLevelCredit for Billing only countries
                                //25753 Adding the related legacy Invoice check and Credit Note Type as not equals to Legacy Credit
                                //#34240 Updated System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c) from eachCreditNote.QTB_Reason_Code__c.contains(System.label.QTB_OnAccountCreditReasonCode) 
                                else if(onAccountCreditBillingCountry && eachCreditNote.QTB_Reason_Code__c != null && System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(eachCreditNote.QTB_Reason_Code__c)
                                    && eachCreditNote.QTB_Related_Legacy_Invoice__c == Null && eachCreditNote.QTB_Credit_Note_Type__c != 'Legacy Credit')
                                {
                                    eachCreditNote.addError(system.label.QTB_OnAccountCreditReasonCodeBillingOnlyValidation2);
                                }
                                
                                // GITLAB US #22186 - As part of code optimzation its found for non billing country system is allowing to update on account credit to true
                                // so added the below condition
                                else if(eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_On_Account_Credit__c &&
                                    eachCreditNote.QTB_On_Account_Credit__c )
                                {
                                    eachCreditNote.addError(System.label.QTB_Validationif_creditNoteType_Present);
                                }
                                
                            }
                            
                            // GITLAB US #20082 - fire validation error if user tries to update the credit note to ON Account if credit note type is present
                            else
                            {
                                if(eachCreditNote.QTB_Credit_Note_Type__c != 'On Account Credit' &&
                                    eachCreditNote.QTB_On_Account_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_On_Account_Credit__c &&
                                    eachCreditNote.QTB_On_Account_Credit__c )
                                {
                                    eachCreditNote.addError(System.label.QTB_Validationif_creditNoteType_Present);
                                }
                            }
                        }
                        // GITLAB US #20672 This condition checks Full Credit (Credit only, Rebill, Split rebill)
                        // We are allowing status to Cancelled
                        // #29685
                        if(eachCreditNote.blng__Status__c != 'Cancelled' && eachCreditNote.blng__Status__c != 'Posted' && eachCreditNote.QTB_Credit_Note_Type__c != 'ON Account Credit' && eachCreditNote.QTB_Credit_Note_Type__c != 'Legacy Credit' &&  /*!String.isEmpty(eachCreditNote.QTB_Credit_Note_Type__c) Gitlab--30332*/ eachCreditNote.QTB_Credit_Note_Type__c != 'Manual Credit' && !mapOfOldCreditNotes.isEmpty() && !test.isRunningTest()){
                            callCN_CheckRestrictedFields = true;
                        }
                        //GitLab #23820 Commercial Credit note check out of India
                        if(eachCreditNote.QTB_Country__c != null && eachCreditNote.QTB_Country__c != 'India' && eachCreditNote.QTB_Commercial_Credit__c == TRUE){
                            eachCreditNote.addError('Commercial Credit is not applicable for this Legal Entity Country');
                        }
                        //GitLab #23820 Commercial Credit note check
                        //Start
                        if((eachCreditNote.QTB_Commercial_Credit__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_Commercial_Credit__c) && eachCreditNote.QTB_Country__c != null && eachCreditNote.QTB_Country__c == 'India'){
                            commercialCNIds.add(eachCreditNote);
                        }
                        if(commercialCNIds != null && !commercialCNIds.isEmpty()){
                            QTB_CreditNoteHelperUtils.commercialCreditNoteCheck(commercialCNIds);
                        }
                        //#25446 On Account Creditnote Validation - PO number and Site numbers are mandatory for On Account Credit type and SITAD account
                        // GitLab US #28779 Po number is not mandatory
                        //GitLab 29058 - Start - Added Case Number also mandatory
                        if(eachCreditNote.QTB_Credit_Note_Type__c == 'ON Account Credit'  && (eachCreditNote.QTB_Site_Number__c == null || eachCreditNote.QTB_Case_Number__c == null) &&
                           eachCreditNote.QTB_SITAD__c == true && System.Label.QTB_SITAD_Countries.contains(eachCreditNote.QTB_Country__c)){
                            eachCreditNote.addError(system.label.QTB_Creditnote_OnAccount_Validation);
                        }
                         //GitLab 29058 - End
                        //End
                        //#29005 - update credit note date with today's date
                        if(eachCreditNote.QTB_Country__c !=  null && system.label.QTB_InvoiceDateUpdate.containsIgnoreCase(eachCreditNote.QTB_Country__c) && mapOfOldCreditNotes!= Null && 
                           mapOfOldCreditNotes.get(eachCreditNote.id).blng__Status__c != eachCreditNote.blng__Status__c && eachCreditNote.blng__Status__c == 'Posted')
                        {
                            eachCreditNote.blng__CreditNoteDate__c = system.today();
                        }
                        
                    }
                    when BEFORE_DELETE {}
                    when AFTER_INSERT {
                        //Credit ReBill By IRM/Virtusa
                        if(eachCreditNote.QTB_IsReBill__c == true){  //Only call for Rebill Invoice
                            parentInvoiceIdInsert.add(eachCreditNote.blng__RelatedInvoice__c);   //for RebillCreditNote setting invoiceID
                            creditNoteSetIDs.add(eachCreditNote.id);
                            //Vertex tax is not getting called due to rebill process is from batch context,
                            //so to call vertex service using platform event
                            //and this approach is applicable only for single rebill process
                            if(isVertexTaxCall){
                                creditRebillVertexCallEvents.add(new QTB_CreditRebillVertexCall__e(QTB_CreditNoteId__c = eachCreditNote.Id));
                            }
                        }
                    }
                    when AFTER_UPDATE {
                        // #23170 Checking whether Credit Note status changed to POST then only adding taht related InvoiceIds to particlar set
                        // apply tax for credit note
                        if ( eachCreditNote.ApprovalStatus__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).ApprovalStatus__c &&
                            eachCreditNote.ApprovalStatus__c == QTB_Constants.CREDITNOTE_APPROVALSTATUS_APPROVED &&
                            eachCreditNote.blng__Status__c == QTB_Constants.CREDITNOTE_STATUS_DRAFT)
                        {
                            //Credit ReBill By IRM/Virtusa
                            if(eachCreditNote.QTB_IsReBill__c == true || eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only'  )
                            {
                                creditNoteSetIDs.add(eachCreditNote.id);
                                parentInvoiceIdUpdate.add(eachCreditNote.blng__RelatedInvoice__c);
                            }
                            if(isVertexTaxCall)
                            {
                                //GITLAB US #6056 Vertex Tax Integration for Posted Invoice
                                //CreditNote status making posted in vertex response class.
                                creditNoteSetIDs.add(eachCreditNote.id);
                                postedCrediteNote = 'Posted'; //for Posted credit note status sending as Posted.
                            }
                            else{
                                String result = blng.CreditNoteAPI.postTaxForCreditNote(eachCreditNote.Id);
                            }
                        }
                        // if the status is Draft and approval status is changed to pending
                        if ( String.isNotBlank(eachCreditNote.blng__Status__c) && eachCreditNote.blng__Status__c == QTB_Constants.CREDITNOTELINE_STATUS_DRAFT &&
                            String.isNotBlank(eachCreditNote.ApprovalStatus__c) && eachCreditNote.ApprovalStatus__c == QTB_Constants.CREDITNOTE_APPROVALSTATUS_PENDING &&
                            eachCreditNote.ApprovalStatus__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).ApprovalStatus__c )
                        {
                            // if approval status is pending get all the approvers to notify
                            mapOfCreditNoteIdsInApproval.put(eachCreditNote.Id, eachCreditNote);
                            setOfApproverIds.add(eachCreditNote.QTB_Manager_Approver__c);
                            setOfApproverIds.add(eachCreditNote.QTB_Supervisor_Approver__c);
                            setOfApproverIds.add(eachCreditNote.QTB_Director_Approver__c);
                            setOfApproverIds.add(eachCreditNote.QTB_VP_Approver__c);
                            setOfApproverIds.add(eachCreditNote.QTB_SVP_Approver__c);
                            setOfApproverIds.add(eachCreditNote.QTB_EVP_Approver__c);
                            setOfApproverIds.add(eachCreditNote.QTB_CEO_Approver__c);
                            setOfApproverIds.add(eachCreditNote.QTB_CFO_Approver__c);
                        }
                        
                        // GITLAB US # 1731, if the custom rebill credit note is posted
                        // and allocation is same as the total amount, get the source
                        // invoice and mark the related invoice as IRM Rebill
                        if ( String.isNotEmpty(eachCreditNote.QTB_Rebill_Invoice__c) && String.isNotEmpty(eachCreditNote.blng__RelatedInvoice__c) &&
                            eachCreditNote.blng__Status__c == 'Posted' && eachCreditNote.blng__Unallocations__c == 0 &&
                            eachCreditNote.blng__Allocations__c == eachCreditNote.blng__TotalAmount__c &&
                            eachCreditNote.blng__Allocations__c <> mapOfOldCreditNotes.get(eachCreditNote.Id)?.blng__Allocations__c)
                        {
                            customRebillInvoiceIds.add(eachCreditNote.blng__RelatedInvoice__c);
                        }
                        // GITLAB US # 3483, if custom rebill credit note is rejected
                        // get the rebill invoice and undo the entire rebill process
                        // by removing those records
                        if( String.isNotEmpty(eachCreditNote.QTB_Rebill_Invoice__c) && String.isNotEmpty(eachCreditNote.blng__RelatedInvoice__c) &&
                            eachCreditNote.ApprovalStatus__c == 'Rejected' && eachCreditNote.ApprovalStatus__c <>  mapOfOldCreditNotes.get(eachCreditNote.Id)?.ApprovalStatus__c)
                        {
                            //excludig existing process for new credit & rebill IRM/Virtusa
                            //AccountLevelCredit -- added check on account should be false
                            if(eachCreditNote.QTB_IsReBill__c == false && eachCreditNote.QTB_On_Account_Credit__c == false){
                                newRebillInvoiceIds.add(eachCreditNote.QTB_Rebill_Invoice__c);
                            }
                        }
                        
                        //Changes for Purchase Order Balance Update
                        if (eachCreditNote.blng__Status__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Status__c &&
                            eachCreditNote.blng__Status__c == QTB_Constants.CREDITNOTE_STATUS_POSTED)
                        {
                            postedCreditNoteIds.add(eachCreditNote.Id);
                            //Added Country check,For Eligible Countries -- calculating PO
                            //GITLAB US #9089 added Country check,For Eligible Countries -- calculating PO
                            if(System.Label.QTB_POEligibleCountries.contains(eachCreditNote.QTB_Country__c))
                            {
                                isPOEligibleCountry = true;
                            }
                        }
                        //Credit ReBill By IRM/Virtusa
                        if ((eachCreditNote.QTB_IsReBill__c == true || eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only') &&
                            eachCreditNote.blng__Subtotal__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Subtotal__c )
                        {
                            creditNoteSetIDs.add(eachCreditNote.id);
                            parentInvoiceIdUpdate.add(eachCreditNote.blng__RelatedInvoice__c);
                        }
                        //Credit ReBill By IRM/Virtusa
                        if ((eachCreditNote.QTB_IsReBill__c == true || eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only') &&
                            eachCreditNote.ApprovalStatus__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).ApprovalStatus__c &&
                            eachCreditNote.ApprovalStatus__c == QTB_Constants.CREDITNOTE_APPROVALSTATUS_APPROVED && eachCreditNote.blng__Status__c == 'Posted' )
                        {
                            creditNoteSetIDs.add(eachCreditNote.id);
                            parentInvoiceIdUpdate.add(eachCreditNote.blng__RelatedInvoice__c);
                        }
                        //Credit ReBill By IRM/Virtusa
                        if((eachCreditNote.QTB_IsReBill__c == true || eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only') 
                               && eachCreditNote.blng__Status__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Status__c &&
                            eachCreditNote.blng__Status__c == 'Cancelled')
                        {
                            creditNoteSetIDs.add(eachCreditNote.id);
                            parentInvoiceIdUpdate.add(eachCreditNote.blng__RelatedInvoice__c);
                        }
                        //GITLAB US #18987 setting CreditOnlyId for triggering Auto Approval process
                        if(eachCreditNote.QTB_Credit_Note_Type__c == 'Credit Only' &&
                            eachCreditNote.ApprovalStatus__c <>  mapOfOldCreditNotes.get(eachCreditNote.Id)?.ApprovalStatus__c  && eachCreditNote.ApprovalStatus__c =='Pending')
                        {
                            creditonlySetIDs.add(eachCreditNote.id);
                        }
                        
                        //25753 Placing the Adding of Ids to the last because the Reference will be moved before Posting of CNs
                        // #23205 Added QTB_Related_Legacy_Invoice__c rather than Existing Related Invoice field because facing some issues with existing field as Custom Invoice Number generating in draft stage
                        if(eachCreditNote.blng__Status__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Status__c &&
                            eachCreditNote.blng__Status__c == QTB_Constants.CREDITNOTE_STATUS_POSTED &&
                        eachCreditNote.QTB_Related_Legacy_Invoice__c != Null){
                            legacyPostedCNInvoiceIds.add(eachCreditNote.QTB_Related_Legacy_Invoice__c);
                        }
                        
                        // GITLAB - #27320 - to get the creditnoteId for passing the parameter when calling updatecorrectAmount method
                        // GITLAB - #33276 - updated code as per requirement change
                        if (eachCreditNote.blng__Subtotal__c !=null &&
                            eachCreditNote.blng__Subtotal__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).blng__Subtotal__c &&
							System.Label.QTB_CorrectAmount_Applicable_Countries.contains(eachCreditNote.QTB_Country__c) &&
                           !eachCreditNote.QTB_On_Account_Credit__c)
                        {
                            system.debug('calling correct amount method');
                            correctAmountCrNoteId.add(eachCreditNote.id);
                            
                        }
                        // #29361 Automate invoice notes to display exchange rate on Foreign currency Credit Note                       
                        if (eachCreditNote.blng__Status__c == 'Draft' && !eachCreditNote.QTB_On_Account_Credit__c && eachCreditNote.QTB_Credit_Note_Type__c !='Manual Credit' &&
                            mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_Tax_Override_Amount__c !=null &&
                            eachCreditNote.QTB_Tax_Override_Amount__c != null &&
                            (eachCreditNote.QTB_Tax_Override_Amount__c <> mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_Tax_Override_Amount__c || 
                             eachCreditNote.QTB_Tax_Override_Amount__c == mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_Tax_Override_Amount__c) &&
                            ((eachCreditNote.QTB_Related_Legacy_Invoice__c !=null && mapOfOldCreditNotes.get(eachCreditNote.Id).QTB_Related_Legacy_Invoice__c != eachCreditNote.QTB_Related_Legacy_Invoice__c) ||
                            (eachCreditNote.blng__RelatedInvoice__c !=null)))
                        {
                            crdIdAndCrdMap.put(eachCreditNote.id,eachCreditNote);
                        }
                    }
                }
            }
            //US #29809 changes
            if(sitadCreditNotes.size()>0){
                Map<Id, Account> accountIdRecordMap = new Map<Id, Account>(); 
                for(Account acct: [select id, QTB_Language__c from Account where id IN:sitadAccountIds]){
                    accountIdRecordMap.put(acct.id,acct);
                }
                for(blng__CreditNote__c   cn:sitadCreditNotes){
                    if(cn.QTB_Country__c == 'France' && accountIdRecordMap.get(cn.blng__Account__c).QTB_Language__c == 'fr'){
                        cn.blng__Notes__c = 'N° Projet ALM: ' +  cn.QTB_Case_Number__c;

                    }else{
                        cn.blng__Notes__c = 'ALM Case No: ' +  cn.QTB_Case_Number__c;

                    }
                }
            }
             // #29361 Set to store Credit Note Ids Automate invoice notes
            if(QTB_RecursiveHandlerCheck.updateNoteOnCreditNote && !crdIdAndCrdMap.isEmpty()){
                if(crdIdAndCrdMap.size()>0){
                    List<blng__CreditNote__c> lstCreditNotes = QTB_CreditNoteHelperUtils.updateNoteOnCreditNote(crdIdAndCrdMap);
                    if(lstCreditNotes != null)
                    {
                        for(blng__CreditNote__c cr : lstCreditNotes)
                        {
                            if(!finalSingleUpdateCreditNoteMap.containsKey(cr.id)){
                                finalSingleUpdateCreditNoteMap.put(cr.id,cr);
                            }
                        }
                    }
                } 
            }
            //GILTAB #27320 - Calling the updateCorrectAmount method and perform update for correct amount field
            //GITLAB #33276 - updated code as per requirement change
            if(!correctAmountCrNoteId.isEmpty() && QTB_RecursiveHandlerCheck.updateCorrectAmount ==True){
                //  updateCorrectAmount(correctAmountCrNoteId);
                List<blng__CreditNote__c> crNotepdate = QTB_CreditNoteHelperUtils.updateCorrectAmount(correctAmountCrNoteId);
                if(crNotepdate != null)
                {
                    for(blng__CreditNote__c cr : crNotepdate)
                    {
                        if(!finalSingleUpdateCreditNoteMap.containsKey(cr.id)){
                            finalSingleUpdateCreditNoteMap.put(cr.id,cr);
                        }
                    }
            
                }
            }
            if (finalSingleUpdateCreditNoteMap.size() > 0){
                system.debug('updating finalSingleUpdateCreditNoteMap');
                update finalSingleUpdateCreditNoteMap.values();
            }
            // GITLAB US #20391 calling the method below - Users should not be able select any non-billing account when performing an On Account Credit or Credit
            if(callCN_ParentBillingAccount){
                CN_ParentBillingAccount(newItems);
            }
            
            // GITLAB US #20672 calling the method below - Block Credit Note Editing after full Credit - restrict user to edit fields if it is in Draft status
            if(callCN_CheckRestrictedFields){
                CN_CheckRestrictedFields(newItems, mapOfOldCreditNotes, String.valueOf(System.label.CN_RestrictedFields_Draft));
            }
            //Credit ReBill By IRM/Virtusa
            if(!parentInvoiceIdInsert.isEmpty() && parentInvoiceIdInsert.size() > 0){
                creditReBill(parentInvoiceIdInsert,creditNoteSetIDs,'Insert',null);
            }
            
            //Credit ReBill By IRM/Virtusa
            if(!parentInvoiceIdUpdate.isEmpty() && parentInvoiceIdUpdate.size() > 0){
                creditReBill(parentInvoiceIdUpdate,creditNoteSetIDs,'Update',isVertexTaxCall);
            }
            
            //Credit ReBill By IRM/Virtusa
            if(!creditRebillVertexCallEvents.isEmpty() && creditRebillVertexCallEvents.size() > 0){
                EventBus.publish(creditRebillVertexCallEvents);
            }
            
            //GITLAB #16104 -- AccountLevelCredit --  Calling the method for firing Validation that are not eligible for On Account Scenario
            if(onCreditnoteAccountIds.size() > 0){
                onAccountCreditNote(onCreditnoteAccountIds,newItems,mapOfOldCreditNotes);
            }
            
            /** Post Process **/
            // set approvers on credit note
            if (operationType.name() == 'BEFORE_INSERT') {
                setApprovers(newItems);
            }
            
            //GITLAB US - #857 Before update, calling vertex tax to set the tax before posted
            //Before Posted credit note, calling vertex to get tax, and in response class making credit note posted.
            //GITLAB US - #6056 Vertex Tax Integration for Posted Invoice
            if (!system.isBatch() && creditNoteSetIDs.size() > 0 && isVertexTaxCall) {
                Database.executeBatch(new QTB_vertexTaxCalloutBatch(postedCrediteNote,null,creditNoteSetIDs,null,null,false),1);
            }
            
            //continue same logic, if its not for vertex country
            // generate the custom invoice number and stamp it on credit note
            if (!AccountID.isEmpty() && !PostedCreditNotes.isEmpty()) {
                QTB_CreditNoteIDGeneration.processCreditNote( PostedCreditNotes, AccountID);
            }
            
            //GITLAB US #15553 --- AccountLevelCredit--tax detail record creation on credit note lines when credit note are posted.
            if(postedCreditNoteIds != null && postedCreditNoteIds.size() > 0){
                Set<ID> postedCreditNoteIdsForTaxDetail = new Set<ID>();
                postedCreditNoteIdsForTaxDetail.addAll(postedCreditNoteIds);
                //26026 Start
                //Added Recursive check for update Partial and on account credit note 
                if(!isTaxDetailAvailableAfterRetry && QTB_RecursiveHandlerCheck.updatePartialCreditNoteCheck){
                    QTB_CreditNoteHelperUtils.calculateIndividualTaxAmountsOnCreditNoteLines(postedCreditNoteIdsForTaxDetail);
                }
                //26026 Ends
            }
            //Changes for Purchase Order Balance Update
            //GITLAB US #9089 added Country check,For Eligible Countries -- calculating PO
            if (postedCreditNoteIds != null && postedCreditNoteIds.size() > 0 && isPOEligibleCountry && !System.isBatch()) {
                //Calling QTB_CalculatePOBalanceBatch to update the PO Balance for the processed invoices
                Set<ID> creditNoteIds = new Set<ID>();
                Set<ID> processedInvoiceIds = new Set<ID>();
                Set<ID> poIds = new Set<ID>();
                creditNoteIds.addAll(postedCreditNoteIds);
                //Database.executeBatch(new QTB_CalculatePOBalanceBatch(processedInvoiceIds, creditNoteIds, poIds), Integer.valueOf(System.Label.QTB_CalculatePOBatchSize));
            }
            
            // notify the lower level approvers about credit not submitted for approval
            if (!setOfApproverIds.isEmpty()) {
                notifyAdditionalRecipientsOnApprovalSubmission(mapOfCreditNoteIdsInApproval,setOfApproverIds);
            }
            //#26371
            if(cNDueDateUpdateMap.size()>0 && QTB_RecursiveHandlerCheck.updateDueDate == True){
                QTB_CreditNoteHelperUtils.updateDueDate(cNDueDateUpdateMap);
            }
            //26654 Calling updateExchangeRate from Utils to stamp the Exchange Rate on Invoice based upon Foreign Exchange object Record data
            if(QTB_RecursiveHandlerCheck.cnUpdateExchangeRate){
                if(cnExchangeRateUpdateMap.size()>0){
                    QTB_CreditNoteHelperUtils.updateExchangeRate(cnExchangeRateUpdateMap,true);
                }
                //#28078 Added else if and hecking the new Map size not empty and calling the method to Stamp Exchange Rate based upon invocie Exchaneg rate
                else if(cnExchangeRateInvRefUpdateMap.size()>0){
                    QTB_CreditNoteHelperUtils.updateExchangeRate(cnExchangeRateInvRefUpdateMap,false);
                }
            }
            // # 23170 Calling below method by Passing the Legacy invoices which are ready to make status of "legacy"
            if(!legacyPostedCNInvoiceIds.isEmpty()){
                QTB_CreditNoteHelperUtils.updateFieldsForLegacyInvoiceOfPostedCNS(legacyPostedCNInvoiceIds);
            }
            //Credit only auto approval Process user story #18987
            if(!creditonlySetIDs.isEmpty()){
                Id setid= null;
                for(Id firstelement:creditonlySetIDs)
                {
                    setid=firstelement;
                    break;
                }
                sbaa.ApprovalAPI.submit(setid, sbaa__Approval__c.QTB_Credit_Note__c);
            }
        }
        catch(Exception e) {QTB_ExceptionLogger.enable(); QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME); throw e;}
    }
    
    /***********************************************************************************************************
     * Method : getApproverIds
     * Parameters: Set<String>
     * Return Type : Map<String, Id>
     * Requirement : JIRA# SFCPQBLG-64
     * Description: This method returns Approver Id map for the respective country or user
     **************************************************************************************************************/
    public static Map<String, Id> getApproverIds(Set<String> setOfUserIdOrCountires)
    {
        Map<String, Id> mapOfUserOrCountryApproverId = new Map<String, Id>();
        try {
            if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            // Get all the Approver records whose User or Approver Country matches with the keys in mapOfCountryCreditNotes
            for (sbaa__Approver__c eachApprover : [SELECT Id, Name,sbaa__User__c,sbaa__GroupId__c,QTB_Approver_Country__c,QTB_Approver_Level__c
                                                   FROM sbaa__Approver__c
                                                   WHERE sbaa__User__c IN :setOfUserIdOrCountires OR QTB_Approver_Country__c IN :setOfUserIdOrCountires])
            {
                if(String.isNotBlank(eachApprover.sbaa__User__c)) {
                    mapOfUserOrCountryApproverId.put((String) eachApprover.sbaa__User__c, eachApprover.Id);
                }
                else if(String.isNotBlank(eachApprover.sbaa__GroupId__c) && String.isNotBlank(eachApprover.QTB_Approver_Country__c) &&
                    String.isNotBlank(eachApprover.QTB_Approver_Level__c))
                {
                    // if the GroupId is populated and there are Credit Notes with matching country
                    mapOfUserOrCountryApproverId.put(eachApprover.QTB_Approver_Country__c +eachApprover.QTB_Approver_Level__c, eachApprover.Id);
                }
            }
        } catch (Exception e) { QTB_ExceptionLogger.enable(); QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME); throw e; }
        return mapOfUserOrCountryApproverId;
    }
    
    /***********************************************************************************************************
     * Method :setApprovers
     * Parameters:List<blng__CreditNote__c>
     * Return Type : void
     * Requirement : JIRA# SFCPQBLG - 64(QTB-41)
     * Description: This method sets the approvers on the Credit Note based on country and created by user
     **************************************************************************************************************/
    public static void setApprovers(List<blng__CreditNote__c> listOfNewCreditNotes)
    {
        /* Initializing variables and collections */
        Set<Id> setOfAccountIds = new Set<Id>();// Set of Account Ids from the listOfNewCreditNotes to get the Currency info from these accounts
        Set<String> setOfUserIdOrCountires = new Set<String>();// Set of user ids or countries
        Map<Id, Account> mapOfAccounts = new Map<Id, Account>();// Map of account id and details
        Map<String, Id> mapOfUserOrCountryApproverId = new Map<String, Id>(); // Map of the User Id and the Approver Id where the User Ids match
        try {
            if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            // Get current user's Manager, Supervisor, Director
            User currentUser = [SELECT Id, ManagerId, QTB_Supervisor__c, IM_RSM__c
                                FROM User
                                WHERE Id = :UserInfo.getUserId()];
            // add user's supervisor, manager, director fields to get matching approvers
            setOfUserIdOrCountires.add(currentUser.QTB_Supervisor__c);
            setOfUserIdOrCountires.add(currentUser.ManagerId);
            setOfUserIdOrCountires.add(currentUser.IM_RSM__c);
            
            /* Preprocessing */
            for (blng__CreditNote__c eachCreditNote : listOfNewCreditNotes) {
                // Get all the accounts to update currency from
                setOfAccountIds.add(eachCreditNote.blng__Account__c);
                // Get all the countries
                if (String.isNotBlank(eachCreditNote.QTB_Country__c)) {
                    setOfUserIdOrCountires.add(eachCreditNote.QTB_Country__c);
                }
                else {
                    // if there is no country, show error to the user to add country
                    eachCreditNote.addError(Label.QTB_Country_Missing_on_Account_Validation_Message);
                }
            }
            // Get Account details
            if (!setOfAccountIds.isEmpty()) {
                mapOfAccounts.putAll([SELECT Id, CurrencyIsoCode FROM Account WHERE Id IN :setOfAccountIds]);
            }
            // Get Approvers
            if (!setOfUserIdOrCountires.isEmpty()) {
                setOfUserIdOrCountires.remove(null);
                mapOfUserOrCountryApproverId.putAll(getApproverIds(setOfUserIdOrCountires));
            }
            
            /* Postprocessing */
            for (blng__CreditNote__c eachCreditNote : listOfNewCreditNotes)
            {
                // Default currency to the account currency
                eachCreditNote.CurrencyIsoCode = (mapOfAccounts.containsKey(eachCreditNote.blng__Account__c))
                    ? mapOfAccounts.get(eachCreditNote.blng__Account__c).CurrencyIsoCode
                    : eachCreditNote.CurrencyIsoCode;
                // populate all approver lookup field
                eachCreditNote.QTB_Supervisor_Approver__c = mapOfUserOrCountryApproverId.containsKey(currentUser.QTB_Supervisor__c)
                    ? mapOfUserOrCountryApproverId.get(currentUser.QTB_Supervisor__c)
                    : eachCreditNote.QTB_Supervisor_Approver__c;
                eachCreditNote.QTB_Manager_Approver__c = mapOfUserOrCountryApproverId.containsKey(currentUser.ManagerId)
                    ? mapOfUserOrCountryApproverId.get(currentUser.ManagerId)
                    : eachCreditNote.QTB_Manager_Approver__c;
                eachCreditNote.QTB_Director_Approver__c = mapOfUserOrCountryApproverId.containsKey(currentUser.IM_RSM__c)
                    ? mapOfUserOrCountryApproverId.get(currentUser.IM_RSM__c)
                    : eachCreditNote.QTB_Director_Approver__c;
                eachCreditNote.QTB_VP_Approver__c = mapOfUserOrCountryApproverId.containsKey(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_VP)
                    ? mapOfUserOrCountryApproverId.get(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_VP)
                    : eachCreditNote.QTB_VP_Approver__c;
                eachCreditNote.QTB_SVP_Approver__c = mapOfUserOrCountryApproverId.containsKey( eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_SVP)
                    ? mapOfUserOrCountryApproverId.get( eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_SVP)
                    : eachCreditNote.QTB_SVP_Approver__c;
                eachCreditNote.QTB_EVP_Approver__c = mapOfUserOrCountryApproverId.containsKey(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_EVP)
                    ? mapOfUserOrCountryApproverId.get(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_EVP)
                    : eachCreditNote.QTB_EVP_Approver__c;
                eachCreditNote.QTB_CEO_Approver__c = mapOfUserOrCountryApproverId.containsKey(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_CEO)
                    ? mapOfUserOrCountryApproverId.get(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_CEO)
                    : eachCreditNote.QTB_CEO_Approver__c;
                eachCreditNote.QTB_CFO_Approver__c = mapOfUserOrCountryApproverId.containsKey(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_CFO)
                    ? mapOfUserOrCountryApproverId.get(eachCreditNote.QTB_Country__c + QTB_Constants.APPROVER_LEVEL_CFO)
                    : eachCreditNote.QTB_CFO_Approver__c;
            }
        } catch (Exception e) { 
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME); 
            throw e; }
    }
    
    /***********************************************************************************************************
     * Method :notifyAdditionalRecipientsOnApprovalSubmission
     * Parameters: Map<Id, blng__CreditNote__c> , Map<Id, blng__CreditNote__c>
     * Return Type : void
     * Requirement : JIRA# SFCPQBLG - 64(QTB-41)
     * Description: This method sends email to the additional recipients mentioned on the approval rule upon
     *                                                      approval submission
     **************************************************************************************************************/
    public static void notifyAdditionalRecipientsOnApprovalSubmission( Map<Id, blng__CreditNote__c> mapOfCreditNoteIdsInApproval,Set<Id> setOfApproverIds)
    {
        try {
            if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            setOfApproverIds.remove(null);
            // Send notification to the approvers specified
            if (mapOfCreditNoteIdsInApproval != null && !mapOfCreditNoteIdsInApproval.isEmpty()) {
                QTB_ApprovalEmailHandler.sendNotification(QTB_Constants.APPROVAL_FIELD_CREDITNOTE,mapOfCreditNoteIdsInApproval, setOfApproverIds);
            }
        } catch (Exception e) { 
            QTB_ExceptionLogger.enable(); 
            QTB_ExceptionLogger.createLog( 
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME); 
            throw e;}
    }
    
    /***********************************************************************************************************
     * Method      :creditReBill
     * Parameters  : Map<Id, blng__CreditNote__c> , Map<Id, blng__CreditNote__c>
     * Return Type : void
     * Requirement : Git #9456 Credit & Rebill //Credit ReBill By IRM/Virtusa
     * Description : This method is used for sending creditNote for approval, updating billflowcontroller for post bill activity
     **************************************************************************************************************/
    public static void creditReBill(Set<Id> parentInvoiceIds, Set<Id> creditNoteSetIDs, String Operation,boolean isVertexTaxCall){
        try{
            if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Map<Id,blng__Invoice__c> invMap = new Map<Id,blng__Invoice__c>();
            Set<Id> rebillInvoiceId = new Set<Id>(); // Gitlab US#24176 (Credit/Rebill Billnow)
            Set<Id> invoiceSchedulareIds = new Set<Id>();
            List<QTB_Bill_Flow_Controller__c> billFlowControllerFinalList = new List<QTB_Bill_Flow_Controller__c>();
            Map<Id,blng__CreditNote__c> invoiceIdWithCreditNoteMap = new Map<Id,blng__CreditNote__c>();
            List<blng__Invoice__c> finalInvoiceList = new List<blng__Invoice__c>();
            List<blng__CreditNoteLine__c> crdNoteLineList = new List<blng__CreditNoteLine__c>();
            Set<Id> cancelledCreditNoteId = new Set<Id>();
            Set<Id> postedCreditNoteId = new Set<Id>();
            //fetched rebillInvoice based on parent InvoiceId
            //SplitRebill -- added invoicestatus in where clause and remove limit 1 , so all split rebill invoice get fetch based on parent invoice
            //Gitlab US #17138 -- defect fixed by checking invoice status other than cancelled & posted, so all draft,initiated rebill invoice get return
            List<blng__Invoice__c> rebillInvoiceList = [SELECT Id, NAme,blng__Subtotal__c, QTB_Parent_Invoice__c,blng__InvoiceStatus__c,
                                                        blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Parent_Invoice__c
                                                        FROM blng__Invoice__c 
                                                        WHERE QTB_Parent_Invoice__c IN :parentInvoiceIds 
                                                        AND blng__InvoiceStatus__c != 'Cancelled' AND blng__InvoiceStatus__c != 'Posted' 
                                                        order by createdDate desc];
            
            List<blng__CreditNote__c> crdNoteList =  [SELECT ID,blng__Status__c,blng__TaxAmount__c,Name,ApprovalStatus__c,QTB_Country__c,QTB_ReBill_Credit_Amount__c,
                                                      blng__RelatedInvoice__c,blng__RelatedInvoice__r.blng__Subtotal__c,QTB_Credit_Note_Type__c,QTB_IsReBill__c,//GITLAB US#23532 --added fields
                                                      blng__RelatedInvoice__r.blng__TaxAmount__c,blng__Account__r.SBQQ__TaxExempt__c, blng__Subtotal__c,
                                                      blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,blng__TaxErrorMessage__c//Gitlab US#22511,#24523--added field in query
                                                      /*(Select Id,blng__TotalAmount__c,blng__TaxAmount__c,blng__CreditNote__c,blng__Subtotal__c FROM blng__CreditNoteCreditLines__r)*/
                                                      FROM blng__CreditNote__c  
                                                      WHERE ID IN :creditNoteSetIDs ];
            for(blng__CreditNote__c crd :crdNoteList ){
                invoiceIdWithCreditNoteMap.put(crd.blng__RelatedInvoice__c,crd);
            }
            if(Operation == 'Insert'){
                if(rebillInvoiceList != null && rebillInvoiceList.size() > 0 && !crdNoteList.isEmpty()){
                    for(blng__CreditNote__c eachCreditNote : crdNoteList){
                        //Change Invoice ReBill Status
                        blng__Invoice__c inv = new blng__Invoice__c();
                        inv.id = eachCreditNote.blng__RelatedInvoice__c;
                        inv.QTB_ReBill_Status__c = 'Invoice & Credit Note Completed';
                        invMap.put(inv.id,inv);
                    }
                }
            }
            else if(Operation == 'Update'){
                String result;
                //For Draft Credit Note Auto calculate Tax
                //GITLAB US#23532 -- below logic should only needs to execute in Rebill scenario, not for CreditOnly
                if(System.Label.QTB_RebillStandardTaxCountries.containsIgnoreCase(crdNoteList[0].QTB_Country__c) &&
                    crdNoteList[0].blng__status__c == 'Draft' && crdNoteList[0].QTB_Credit_Note_Type__c != 'Credit Only' &&
                    (crdNoteList[0].blng__Account__r.SBQQ__TaxExempt__c == 'No' ||
                    (crdNoteList[0].blng__Account__r.SBQQ__TaxExempt__c == 'Yes' && crdNoteList[0].blng__RelatedInvoice__r.blng__TaxAmount__c > 0)))
                {
                    result = blng.CreditNoteLineAPI.estimateTaxForCreditNoteLines(crdNoteList[0].Id);//if success, it return 'Tax Estimated' as response.
                }
                //if Auto Calculate tax response success, then adding tax values to creditnote line.
                if(result == 'Tax Estimated'){
                    for(blng__CreditNoteLine__c cnl :[SELECT Id, blng__TaxAmount__c,blng__Subtotal__c,blng__TotalAmount__c 
                                                      FROM blng__CreditNoteLine__c
                                                      WHERE blng__CreditNote__c IN :creditNoteSetIDs])
                    {
                        blng__CreditNoteLine__c cn = new blng__CreditNoteLine__c();
                        cn.Id = cnl.Id;
                        Decimal Tax = cnl.blng__TaxAmount__c !=null ? cnl.blng__TaxAmount__c  : 0;
                        cn.blng__TotalAmount__c =  cnl.blng__TaxAmount__c + cnl.blng__Subtotal__c;
                        crdNoteLineList.add(cn);
                    }
                }
                /*
                Added line 881 - 886 as part story- 28291
                Description- Checking if user has Advance Approval Permission set or no
                IF YEs, execute the exisitng logic else run the approval part in future
                line - 938 -943
                */
                boolean isPermission = false;
                List<permissionsetassignment> isPermissionSetList = [select assigneeid, assignee.email, PermissionSet.Name from permissionsetassignment 
                                                                        where assigneeid = :UserInfo.getUserId() and PermissionSet.Name like 'AdvancedApprovals%' order by PermissionSet.Name ASC];
                if(isPermissionSetList.size() > 0){
                    isPermission = true;
                }
                //iterating on creditNoteList
                for(blng__CreditNote__c eachCreditNote : crdNoteList){
                    //CreditNote ReBill Amount is not null, then sending creditNote for approval
                    if(eachCreditNote.QTB_ReBill_Credit_Amount__c != null && eachCreditNote.QTB_ReBill_Credit_Amount__c >= 0 &&
                        eachCreditNote.blng__status__c == 'Draft' && (eachCreditNote.ApprovalStatus__c == 'Draft' || eachCreditNote.ApprovalStatus__c == null))
                    {
                        //sending creditnote for approval
                        //to restrict auto approval for credit & rebill
                        //Gitlab US#22511 - creating the combination of LegalEntityCountry-LegalEntityNumber and the fetching value based on the combination
                        string countryWithLegalEntityNumber = eachCreditNote.QTB_Country__c +'-' +eachCreditNote.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c;
                        Credit_ReBill_InvoiceSchedulerValidation__c creditAutoApprovalCondCheck = Credit_ReBill_InvoiceSchedulerValidation__c.getInstance(countryWithLegalEntityNumber);
                        // GITLAB US #10736 - Added condition before submission of approval: for Credit note blng__TaxAmount__c Field Value must not be null
                        // Added above condition in QTB_CreditNoteApprovalSchedular class
                        //Gitlab US #10736 Credit & Rebill : Rebill Credit Note Approval email is sent before Tax calculation on Rebill Invoice and Credit Note.
                        //for vertex countries QTB_CreditNoteApprovalSchedular will run and for non-vextex countries it will directly go via approval API
                        if(Test.isRunningTest() || (creditAutoApprovalCondCheck !=null &&  eachCreditNote.QTB_ReBill_Credit_Amount__c > creditAutoApprovalCondCheck.QTB_Threshold_Approval_Amount__c))
                        {
                            if(Test.isRunningTest() || isVertexTaxCall==True)
                            {
                                String day = string.valueOf(system.now().day());
                                String month = string.valueOf(system.now().month());
                                String hour = string.valueOf(system.now().hour());
                                String minute = string.valueOf(integer.valueOf(system.now().minute()) + integer.valueOf(System.Label.QTB_CNApprovalTimeSchedular)); //adding 2 more minute so it will run in future
                                //SplitRebill -- if minute is 60 then setting to 1 min and increasing the hour
                                //0-59 value only consider while scheduling the job, therefore setting the value accordingly if its 60
                                if(Integer.valueOf(minute) >= 60){
                                    minute = '01';
                                    hour = string.valueOf(system.now().hour()+1);
                                }
                                String second = string.valueOf(system.now().second());
                                if(Integer.valueOf(second) == 60){
                                    second = '59';
                                }
                                String year = string.valueOf(system.now().year());
                                
                                String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
                                //Gitlab US #14899 Credit Rebill Schedular invoked Dynamically
                                //creditnoteline_TaxCountry Field used to dynamically create Cronjobs for United states and Canada respectively
                                // Gitlab US#24176 (Credit/Rebill Billnow)
                                List<CronTrigger> CronTrigger_objs;
                                String creditnote_TaxCountry = 'ReBillCreditNoteApproval_QTB_CreditNoteApprovalSchedular'+'_'+eachCreditNote.QTB_Country__c +'_'+eachCreditNote.Id;
                                CronTrigger_objs = [SELECT Id, CronJobDetail.Name, CronJobDetail.Id,State FROM CronTrigger where CronJobDetail.Name =:creditnote_TaxCountry];
                                if(CronTrigger_objs.isEmpty()){
                                    System.schedule(creditnote_TaxCountry, strSchedule, new QTB_CreditNoteApprovalSchedular(eachCreditNote));
                                }
                            }
                            else
                            {
                               if(isPermission){ // added as part of 28291
                                    sbaa.ApprovalAPI.submit(eachCreditNote.id, sbaa__Approval__c.QTB_Credit_Note__c);
                                }
                            }
                        }
                    }
                    if(eachCreditNote.blng__status__c == 'Cancelled'){
                        //storing cancelled credit note ids
                        cancelledCreditNoteId.add(eachCreditNote.Id);
                    }
                    else if(eachCreditNote.blng__status__c == 'Posted'){
                        //storing posted credit note ids
                        postedCreditNoteId.add(eachCreditNote.Id);
                    }
                }
                
                if(!cancelledCreditNoteId.isEmpty()){
                    for(blng__CreditNoteLine__c cnl : [SELECT Id, blng__status__c 
                                                       FROM blng__CreditNoteLine__c
                                                       WHERE blng__CreditNote__c IN :cancelledCreditNoteId ])
                    {
                        //cancelling the credit note lines
                        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
                        cnl1.Id = cnl.id;
                        cnl1.blng__Status__c = 'Cancelled';
                        crdNoteLineList.add(cnl1);
                    }
                }
                else if(!postedCreditNoteId.isEmpty()){
                    for(blng__CreditNoteLine__c cnl : [SELECT Id, blng__status__c 
                                                       FROM blng__CreditNoteLine__c
                                                       WHERE blng__CreditNote__c IN :postedCreditNoteId ])
                    {
                        //posting the credit note lines
                        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
                        cnl1.Id = cnl.id;
                        cnl1.blng__Status__c = 'Posted';
                        crdNoteLineList.add(cnl1);
                    }
                }
                //manual approval change
                if(!System.isBatch()){
                    if(rebillInvoiceList != null && rebillInvoiceList.size() > 0){
                        for(blng__Invoice__c inv : rebillInvoiceList){
                            //If CreditNote is rejected, cancelling the invoice.
                            //Gitlab US#24523 -- Dont cancelled the Rebill Invoice if Error Msg is due to Tax difference
                            string crdTaxError = invoiceIdWithCreditNoteMap.get(inv.QTB_Parent_Invoice__c).blng__TaxErrorMessage__c;
                            if(invoiceIdWithCreditNoteMap.containsKey(inv.QTB_Parent_Invoice__c) &&
                                invoiceIdWithCreditNoteMap.get(inv.QTB_Parent_Invoice__c).blng__Status__c == 'Cancelled' &&
                                (crdTaxError == null || (crdTaxError !=null && !crdTaxError.contains(System.Label.QTB_CreditRebillTaxDiffParentInvoiceCreditNote))))
                            {
                                inv.blng__InvoiceStatus__c = 'Cancelled';
                                finalInvoiceList.add(inv);
                                
                                blng__Invoice__c inv1 = new blng__Invoice__c();
                                inv1.id =  crdNoteList[0].blng__RelatedInvoice__c;
                                inv1.QTB_ReBill_Status__c = null;
                                invMap.put(inv1.id,inv1);
                            }else{
                                rebillInvoiceId.add(inv.id);  // Gitlab US#24176 (Credit/Rebill Billnow)
                                invoiceSchedulareIds.add(inv.blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c);
                            }
                        }
                        if(!finalInvoiceList.isEmpty() && finalInvoiceList.size() > 0){
                            SBQQ.TriggerControl.disable();
                            update finalInvoiceList;
                            finalInvoiceList.clear(); //clearing the memory
                            SBQQ.TriggerControl.enable();
                        }
                        // Gitlab US#24176 (Credit/Rebill Billnow) - modified the below condition to work exisiting Rebill Invoice(InvoiceScheduler functionality)
                        // and New rebill invoice generated via billNow functionality
                        if((!rebillInvoiceId.isEmpty() || invoiceSchedulareIds.isEmpty()) &&
                            invoiceIdWithCreditNoteMap.containsKey(rebillInvoiceList[0].QTB_Parent_Invoice__c) &&
                            invoiceIdWithCreditNoteMap.get(rebillInvoiceList[0].QTB_Parent_Invoice__c).ApprovalStatus__c == 'Approved')
                        {
                            //Fetching billFlowController records based on invoiceSchedularIds
                            List<QTB_Bill_Flow_Controller__c> billFlowControllerList = [SELECT Id, Execute_Pre_Bill_Run__c,Execute_Post_Bill_Run__c
                                                                                        FROM QTB_Bill_Flow_Controller__c
                                                                                        WHERE (QTB_Rebill_Invoice__c != null AND QTB_Rebill_Invoice__c IN :rebillInvoiceId) 
                                                                                        OR (Invoice_Scheduler__c != null AND Invoice_Scheduler__c IN :invoiceSchedulareIds AND QTB_Rebill_Invoice__c = null)];
                            for(QTB_Bill_Flow_Controller__c bfc : billFlowControllerList){
                                if(bfc.Execute_Pre_Bill_Run__c == true && bfc.Execute_Post_Bill_Run__c == false ){
                                    QTB_Bill_Flow_Controller__c bfcObj = new QTB_Bill_Flow_Controller__c();
                                    bfcObj.id = bfc.id;
                                    bfcObj.Execute_Post_Bill_Run__c = true;
                                    billFlowControllerFinalList.add(bfcObj);
                                }
                            }
                            
                            //Update BillFlowController record for PostBill execution
                            if(!billFlowControllerFinalList.isEmpty() && billFlowControllerFinalList.size()>0){
                                update billFlowControllerFinalList;
                                billFlowControllerFinalList.clear();////clearing the memory
                            }
                        }
                    }
                }
                if(!crdNoteLineList.isEmpty() && crdNoteLineList.size() > 0){
                    update crdNoteLineList;
                    crdNoteLineList.clear();//clearing the memory
                }
            }
            //Updating InvoiceList
            if(!invMap.isEmpty() && invMap.values().size() >0){
                update invMap.values();
                invMap.clear(); //clearing the memory
            }
        }
        catch (Exception e) { 
            QTB_ExceptionLogger.enable(); 
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(), 
                CLASSNAME); 
            throw e; }
    }
    
    /***********************************************************************************************************
     * Method : onAccountCreditNote
     * Parameters: Set<Id>, List<blng__CreditNote__c>,Map<Id, blng__CreditNote__c>
     * Start Date : 2nd June 2023
     * Return type : Void
     * Author :   TCS
     * Requirement :  16104 - convert the QTB_Restrict_CN_OnAccount on Credit note Validation rule
     * Description: This method is used for On Account Credit Note to fire a validation rule for comparing the Meta data LOB's and Account LOB's (to restrict the LOB)
     **************************************************************************************************************/
    public static void onAccountCreditNote(Set<Id> CreditNoteAccountIds,List<blng__CreditNote__c> newItems,Map<Id, blng__CreditNote__c> mapOfOldCreditNotes)
    {
        if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
            throw new NullPointerException();
        }
        Map<String,QTB_Account_Level_Credit_Note_Setting__mdt> countryToAccountCreditMap = new Map<String,QTB_Account_Level_Credit_Note_Setting__mdt>();
        Map<Id,Account> accMap = new Map<Id,Account>([Select id,QTB_Data_Management__c,
                                                      QTB_Records_Management__c,QTB_scan__c,QTB_shred__c,QTB_SITAD__c  from Account
                                                      where Id IN :CreditNoteAccountIds]);
        for(QTB_Account_Level_Credit_Note_Setting__mdt acctLevelCrdMetada : QTB_Account_Level_Credit_Note_Setting__mdt.getAll().values())
        {
            countryToAccountCreditMap.put((acctLevelCrdMetada.QTB_Acc_LegalEntityCntry__c).toLowerCase(),acctLevelCrdMetada);
        }
        try{
            //Update
            if(mapOfOldCreditNotes !=null)
            {
                for(blng__CreditNote__c crd : mapOfOldCreditNotes.values())
                {
                    // Added Country Null check as part of GITLAB US #17197
                    if(accMap != null && accMap.containsKey(crd.blng__Account__c) && crd.QTB_Country__c != Null)
                    {
                        String creditNoteCountry = crd.QTB_Country__c.toLowerCase();
                        if(!(( countryToAccountCreditMap.containsKey(creditNoteCountry) &&
                            countryToAccountCreditMap.get(creditNoteCountry).QTB_Acc_LegalEntityCntry__c.toLowerCase() == creditNoteCountry) &&
                            countryToAccountCreditMap.get(creditNoteCountry).QTB_Active__c &&
                            ((countryToAccountCreditMap.get(creditNoteCountry).QTB_DM__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_DM__c == accMap.get(crd.blng__Account__c).QTB_Data_Management__c) ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_Scan__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_Scan__c == accMap.get(crd.blng__Account__c).QTB_scan__c) ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_RM__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_RM__c == accMap.get(crd.blng__Account__c).QTB_Records_Management__c) ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_Shred__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_Shred__c == accMap.get(crd.blng__Account__c).QTB_Shred__c)  ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_SITAD__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_SITAD__c == accMap.get(crd.blng__Account__c).QTB_SITAD__c ))))
                        {
                            trigger.newmap.get(crd.id).addError(crd.QTB_Country__c +' '+System.label.QTB_OnAccountCreditNoteLOBValidation);// India country or it's Account LOB is not applicable for On Account Credit.
                        }
                    }
                }
            }
            else//Insert
            {
                for(blng__CreditNote__c crd : newItems)
                {
                    // Added Country Null check as part of GITLAB US #17197
                    if(accMap != null && accMap.containsKey(crd.blng__Account__c) && crd.QTB_Country__c != Null)
                    {
                        String creditNoteCountry = crd.QTB_Country__c.toLowerCase();
                        if(!(countryToAccountCreditMap.containsKey(creditNoteCountry) &&
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_Acc_LegalEntityCntry__c.toLowerCase() == creditNoteCountry) &&
                            countryToAccountCreditMap.get(creditNoteCountry).QTB_Active__c &&
                            ((countryToAccountCreditMap.get(creditNoteCountry).QTB_DM__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_DM__c == accMap.get(crd.blng__Account__c).QTB_Data_Management__c) ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_Scan__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_Scan__c == accMap.get(crd.blng__Account__c).QTB_Scan__c) ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_RM__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_RM__c == accMap.get(crd.blng__Account__c).QTB_Records_Management__c) ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_Shred__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_Shred__c == accMap.get(crd.blng__Account__c).QTB_shred__c)  ||
                            (countryToAccountCreditMap.get(creditNoteCountry).QTB_SITAD__c && countryToAccountCreditMap.get(creditNoteCountry).QTB_SITAD__c == accMap.get(crd.blng__Account__c).QTB_SITAD__c ))))
                        {
                            crd.addError(crd.QTB_Country__c +' '+System.label.QTB_OnAccountCreditNoteLOBValidation);// India country or it's Account LOB is not applicable for On Account Credit.
                        }
                    }
                }
            }
        } catch (Exception e) { 
            QTB_ExceptionLogger.enable(); 
            QTB_ExceptionLogger.createLog( 
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME); 
            throw e; }
    }
    
    
    
    /**************************************************************************************************************************************
     * Method: CN_ParentBillingAccount
     * Author: AbdulMuktar
     * Purpose: Users should not be able select any non-billing account when performing an On Account Credit or Credit
     * Requirement:20391 Update Filter for Credit Notes and On Account Credits
     * Note: The account field is a Master-Detail and Reparentable  is not enabled, the user will not be able to edit the Account field while the update below method is not needed for the update
     ****************************************************************************************************************************************/
    public static void CN_ParentBillingAccount(List<blng__CreditNote__c> newCredits){
        try{
            Set<Id> accountIds = new Set<Id>();
            for(blng__CreditNote__c credit : newCredits){
                accountIds.add(credit.blng__Account__c);
            }
            
            list<string> restrictedBA = label.QTB_restrictParentAccount.split(';');
            
            Map<Id, Account> accountsWithRecordTypes = new Map<Id, Account>([SELECT Id, RecordType.DeveloperName, QTB_Is_Parent_Billing_Account__c
                                                                             FROM Account
                                                                             WHERE Id IN:accountIds AND RecordType.DeveloperName = 'QTB_Billing_Account' AND 
                                                                             Name like 'BILLP%' AND ID NOT IN: restrictedBA]);
            for(blng__CreditNote__c credit : newCredits){
                if (!Test.isRunningTest() && accountsWithRecordTypes.containsKey(credit.blng__Account__c)) {
                    credit.addError(System.Label.QTB_BillingAccount_validation);
                }
            }
        } catch (Exception e) { 
            QTB_ExceptionLogger.enable(); 
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME); 
            throw e; }
    }
    
    /***********************************************************************************************************
     * Method : CN_CheckRestrictedFields
     * Parameters: List<blng__CreditNote__c> newRecords, Map<Id, blng__CreditNote__c> oldRecords, String restrictedFieldsApiName
     * Return Type : void
     * Requirement : GIT #20672
     * Description: Block Credit Note Editing after full Credit - restrict user to edit fields if it is in Draft status
     **************************************************************************************************************/
    public static void CN_CheckRestrictedFields(List<blng__CreditNote__c> newRecords, Map<Id, blng__CreditNote__c> oldRecords, String restrictedFieldsApiName){
        
        List<String> restrictedFields = restrictedFieldsApiName.split(',');
        try{
            for(blng__CreditNote__c newRecord : newRecords){
                blng__CreditNote__c oldRecord = oldRecords.get(newRecord.Id);
                for(String fieldName : restrictedFields){
                    Object oldValue = oldRecord !=null ? oldRecord.get(fieldName) : null;
                    Object newValue = newRecord.get(fieldName);
                    if(oldValue != newValue ) {
                        newRecord.addError(System.label.CN_Restricted_Draft_validation);
                    }
                }
            }
        }
        catch (Exception e) { 
            QTB_ExceptionLogger.enable(); 
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_CreditNoteHelper'); 
            throw e; }
    }
    
    /***********************************************************************************************************
     * Method     : autoUpdatePO
     * Parameters : List<blng__CreditNote__c> newItems
     * Description: this method helps to  select PO automatically in the credit note level once its posted.#22030
    :
         **************************************************************************************************************/
    public static void autoUpdatePO(List<blng__CreditNote__c> newItems) {
        
        Map<id,QTB_PurchaseOrder__c> poMap;
        Set<id> cnIdsSet = new Set<id>(); //Gitlab #27000
        list<id> billingAccount = new list<id>();
        Map<id,List<QTB_PurchaseOrder__c>> accountIdPoMap = new Map<id,List<QTB_PurchaseOrder__c>>();
        Map<id,blng__CreditNote__c> credMap;
        Map<id,blng__CreditNote__c> credUpdate = new Map<id,blng__CreditNote__c>();
        List<QTB_PurchaseOrder__c> poList;
        
        // Gitlab #27000
        if (newItems != null && newItems.size() > 0) {
            for(blng__CreditNote__c crdNoteId : newItems)
            {
                cnIdsSet.add(crdNoteId.id);
            }
        }
        
        List<blng__CreditNote__c> cred =[select id,name,blng__RelatedInvoice__c,QTB_Purchase_Order__c,QTB_Internal_PO_Notes__c,QTB_Credit_Note_Type__c,blng__Status__c,blng__RelatedInvoice__r.QTB_Internal_PO_Notes__c,blng__RelatedInvoice__r.QTB_PurchaseOrder__c from blng__CreditNote__c where ID IN:cnIdsSet];//Gitlab #27000 changed reference from related invoice to cn id
        
        for(blng__CreditNote__c credN: cred)
        {
            
            
            if(credN != null && credN.blng__RelatedInvoice__c != null && credN.blng__RelatedInvoice__r.QTB_PurchaseOrder__c != null && credN.blng__Status__c == 'Draft' && (/*credN.QTB_Credit_Note_Type__c == null Gitlab-#30332 */ credN.QTB_Credit_Note_Type__c == 'Manual Credit' || credN.QTB_Credit_Note_Type__c =='ReBill' || credN.QTB_Credit_Note_Type__c == 'Split ReBill' || credN.QTB_Credit_Note_Type__c == 'Credit Only'))
            {
                credN.QTB_Purchase_Order__c = credN.blng__RelatedInvoice__r.QTB_PurchaseOrder__c; //auto-populating the creditnote based on reference invoice
                credUpdate.put(credN.Id,credN);
            }
            
            if(credN.QTB_Credit_Note_Type__c == 'ON Account Credit')
            {
                credN.QTB_Purchase_Order__c = null;
            }
            
            //if PO null update the internal Po notes with some reason
            if (credN.QTB_Purchase_Order__c == null) {
                        credN.QTB_Internal_PO_Notes__c = System.Label.QTB_NoPOCn; // Gitlab #27181 if no PO populated at parent ivoice show no po found in CN internal po notes
                credUpdate.put(credN.Id, credN);
            }
            
        }
        
        QTB_RecursiveHandlerCheck.autoUpdateCred = false; //Gitlab #27000
        if(!credUpdate.isEmpty())
            
        {
            // QTB_RecursiveHandlerCheck.autoUpdateCred = false;
            update credUpdate.values();
        }
        
    }

    /***********************************************************************************************************
     * Method : CN_AutoUpdatePOBalance
     * Parameters: List<blng__CreditNote__c> newItems, Map<Id, blng__CreditNote__c> mapOfNewCreditNotes, Map<Id, blng__CreditNote__c> mapOfOldCreditNotes,System.TriggerOperation operationType
     * Return Type : void
     * Requirement :
     * Description: Autopopulate the Purchase Order PO balalnce amount
     **************************************************************************************************************/
    public static void CN_AutoUpdatePOBalance(List<blng__CreditNote__c> newItems, Map<id,blng__CreditNote__c> oldMap){
        
        try{
            
            Set<Id> newPOId =new set<id>();
            Map<Id,blng__CreditNote__c> credMap;
            Map<Id,blng__CreditNote__c> oldCredMap;
            Map<id,QTB_PurchaseOrder__c> purchaseOrderToUpdate = new Map<id,QTB_PurchaseOrder__c>();
            Map<String, Decimal> billingAcntcredAmountMap = new Map<String, Decimal>();
            
            Decimal newPobalanceAmount;
            for(blng__CreditNote__c cred : newItems){
                
                if(oldMap !=null && oldMap.get(cred.id) != null && oldMap.get(cred.id).blng__Status__c != 'Posted' && cred.QTB_Purchase_Order__c !=null && cred.blng__Status__c == 'Posted' && (/*cred.QTB_Credit_Note_Type__c == null Gitlab-#30332 */ cred.QTB_Credit_Note_Type__c == 'Manual Credit' || cred.QTB_Credit_Note_Type__c =='ReBill' || cred.QTB_Credit_Note_Type__c == 'Split ReBill' || cred.QTB_Credit_Note_Type__c == 'Credit Only')){
                    newPOId.add(cred.QTB_Purchase_Order__c);
                    
                }
            }
            //Querying the creditnote with respect to PO
            if(!newPOId.isEmpty()){
                credMap = new Map<Id,blng__CreditNote__c>([Select id, name,QTB_Purchase_Order__c ,QTB_Purchase_Order__r.QTB_PO_Balance_Amount__c,blng__TotalAmount__c from blng__CreditNote__c where QTB_Purchase_Order__c IN :newPOId AND QTB_Purchase_Order__r.QTB_Status__c ='Active']) ;
                if(credMap != null && !credMap.isEmpty())
                {
                    for(blng__CreditNote__c cred: credMap.values())
                    {
                        String key = cred.QTB_Purchase_Order__c+'-'+ cred.Id;
                        billingAcntcredAmountMap.put(key, cred.blng__TotalAmount__c);
                    }
                }
            }
            
            
            Set<Id> poIdSet = new Set<Id>();
            Decimal amt = 0;
            for(blng__CreditNote__c cred :newItems) {
                
                //Invoking PO Number in creditnote level #21525 and calculating the PO Balance once Purchase order linked with creditnote.
                
                String key = cred.QTB_Purchase_Order__c+'-'+ cred.Id;
                if (billingAcntcredAmountMap.containskey(key) && cred.QTB_Purchase_Order__c != null) {
                    if(!poIdSet.contains( cred.QTB_Purchase_Order__c)){
                        newPobalanceAmount = credMap.get(cred.id).QTB_Purchase_Order__r.QTB_PO_Balance_Amount__c;
                    }else{
                        newPoBalanceAmount = amt;
                    }
                    poIdSet.add(cred.QTB_Purchase_Order__c);
                    amt = newPoBalanceAmount  + (billingAcntcredAmountMap.get(key)); //Logic to add funds
                    QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c();
                    po.id = cred.QTB_Purchase_Order__c;
                    po.QTB_PO_Balance_Amount__c = amt;
                    purchaseOrderToUpdate.put(po.id,po);
                    
                }
            }
            if(!purchaseOrderToUpdate.isEmpty())
            {
                QTB_RecursiveHandlerCheck.afterupdateCheck_UpdatePOCred=false;
                update purchaseOrderToUpdate.values();
                
            }
        }catch (Exception e) {
            QTB_ExceptionLogger.enable(); 
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
            throw e;}
    }
    
    
    
    
    
    
    /***********************************************************************************************************
     * Method    : makeFieldsNonEditableForPosted
     * Parameters : List<blng__CreditNote__c>, Map<Id, blng__CreditNote__c>
     * Description: This is used to prevent the modification of the record after invoice posted and QTB_Ready_for_Integration__c set as false.
     * Story Number: 25283
     **************************************************************************************************************/
    public static void makeFieldsNonEditableForPosted(List<blng__CreditNote__c> newItems, Map<Id, blng__CreditNote__c> oldMap){
        List<String> excludedProfiles = Label.QTB_LockdownExcludedProfiles.Split(',');
        Set<id> creditNoteIdSet =new Set<id>();
        Map<Id,blng__CreditNoteLine__c> creditNoteLineMap = new Map<Id,blng__CreditNoteLine__c>();
        for(blng__CreditNote__c cn : newItems){
            creditNoteIdSet.add(cn.Id);
        }
        if(CreditNoteLineList == null || CreditNoteLineList.isEmpty()){
            CreditNoteLineList = [Select id,blng__CreditNote__c ,QTB_Invoice__r.QTB_Ready_for_Integration__c, QTB_Invoice__r.QTB_transfered_to_invoice_presentment__c, blng__Product__c from blng__CreditNoteLine__c where blng__CreditNote__c IN : creditNoteIdSet];
        }
        //List<blng__CreditNoteLine__c> cnlList = CreditNoteLineList;
        
        for(blng__CreditNoteLine__c cnl : CreditNoteLineList){
            creditNoteLineMap.put(cnl.blng__CreditNote__c,cnl);
        }
        System.debug('creditNoteLineMap>>'+ creditNoteLineMap);
        if(!creditNoteLineMap.isEmpty() && creditNoteLineMap !=null ){
            List<user> lgUser = [SELECT ID ,profile.Name FROM User where profile.Name NOT IN: excludedProfiles AND Id =: userinfo.getuserId()];
            System.debug('lgUser>>'+ lgUser);
            for(blng__CreditNote__c cn : newItems){
                if(((lgUser != null && !lgUser.isEmpty())|| Test.isRunningTest()) && creditNoteLineMap.get(cn.Id) != null && creditNoteLineMap.get(cn.Id).QTB_Invoice__c != null && cn.blng__Status__c=='Posted' && oldMap.get(cn.id).blng__Status__c == 'Posted'){
                    if(//cn.QTB_Custom_Invoice_ID__c != oldMap.get(cn.id).QTB_Custom_Invoice_ID__c ||
                        //cn.QTB_Internal_Notes__c != oldMap.get(cn.id).QTB_Internal_Notes__c ||
                    //cn.blng__Status__c != oldMap.get(cn.id).blng__Status__c ||
                    cn.blng__CreditNoteDate__c != oldMap.get(cn.id).blng__CreditNoteDate__c ||
                        cn.QTB_Transferred_To_Oracle__c != oldMap.get(cn.id).QTB_Transferred_To_Oracle__c ||
                        cn.QTB_Oracle_Error__c != oldMap.get(cn.id).QTB_Oracle_Error__c ||
                        cn.QTB_ReBill_Credit_Amount__c != oldMap.get(cn.id).QTB_ReBill_Credit_Amount__c ||
                        cn.QTB_Transferred_to_Invoice_Compliance__c != oldMap.get(cn.id).QTB_Transferred_to_Invoice_Compliance__c ||
                        cn.QTB_Oracle_Integration_Error__c != oldMap.get(cn.id).QTB_Oracle_Integration_Error__c ||
                        cn.QTB_transfered_to_invoice_presentment__c != oldMap.get(cn.id).QTB_transfered_to_invoice_presentment__c ||
                    cn.QTB_Commercial_Credit__c != oldMap.get(cn.id).QTB_Commercial_Credit__c ){
                        cn.addError('We can not Modify posted Credit Note record.');
                    }
                }
            }
        }
    }
    
    /***********************************************************************************************************
     * Method    : makeFieldsReadyOnlyForPosted
     * Parameters : List<blng__CreditNote__c>, Map<Id, blng__CreditNote__c>
     * Description: This is used to prevent the modification of the record after record status is posted and QTB_transfered_to_invoice_presentment__c on invoice is not null.
     * Story Number: 25283
     **************************************************************************************************************/
    public static void makeFieldsReadyOnlyForPosted(List<blng__CreditNote__c> newItems, Map<Id, blng__CreditNote__c> oldMap){
        Set<id> cnSet =new Set<id>();
        Map<Id,blng__CreditNoteLine__c> cmlMap = new Map<Id,blng__CreditNoteLine__c>();
        for(blng__CreditNote__c cn : newItems){
            cnSet.add(cn.Id);
        }
        
        if(CreditNoteLineList == null || CreditNoteLineList.isEmpty()){
            CreditNoteLineList = [Select id,blng__CreditNote__c ,QTB_Invoice__r.QTB_Ready_for_Integration__c, QTB_Invoice__r.QTB_transfered_to_invoice_presentment__c, blng__Product__c from blng__CreditNoteLine__c where blng__CreditNote__c IN : cnSet];
        }
        List<blng__CreditNoteLine__c> cnlList = CreditNoteLineList;
        
        for(blng__CreditNoteLine__c cnl : cnlList){
            cmlMap.put(cnl.blng__CreditNote__c,cnl);
        }
        if(!cmlMap.isEmpty() && cmlMap !=null ){
            for(blng__CreditNote__c cn : newItems){
                if(cmlMap.get(cn.Id) != null && cmlMap.get(cn.Id).QTB_Invoice__c != null && cmlMap.get(cn.Id).QTB_Invoice__r.QTB_transfered_to_invoice_presentment__c !=null){
                    if(//cn.QTB_Custom_Invoice_ID__c != oldMap.get(cn.id).QTB_Custom_Invoice_ID__c ||
                        //cn.QTB_Internal_Notes__c != oldMap.get(cn.id).QTB_Internal_Notes__c ||
                    //cn.blng__Status__c != oldMap.get(cn.id).blng__Status__c ||
                    cn.blng__CreditNoteDate__c != oldMap.get(cn.id).blng__CreditNoteDate__c ||
                        cn.QTB_Transferred_To_Oracle__c != oldMap.get(cn.id).QTB_Transferred_To_Oracle__c ||
                        cn.QTB_Oracle_Error__c != oldMap.get(cn.id).QTB_Oracle_Error__c ||
                        cn.QTB_ReBill_Credit_Amount__c != oldMap.get(cn.id).QTB_ReBill_Credit_Amount__c ||
                        cn.QTB_Transferred_to_Invoice_Compliance__c != oldMap.get(cn.id).QTB_Transferred_to_Invoice_Compliance__c ||
                        cn.QTB_Oracle_Integration_Error__c != oldMap.get(cn.id).QTB_Oracle_Integration_Error__c ||
                        cn.QTB_transfered_to_invoice_presentment__c != oldMap.get(cn.id).QTB_transfered_to_invoice_presentment__c ||
                    cn.QTB_Commercial_Credit__c != oldMap.get(cn.id).QTB_Commercial_Credit__c ){
                        cn.addError('We can not modify processed Credit Notes record if Transferred to Invoice Presentment.');
                    }
                }
            }
        }
    }
    
}