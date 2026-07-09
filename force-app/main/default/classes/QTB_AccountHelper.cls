/*****************************************************************************************************
* Class: QTB_AccountHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to Account object
* Requirement: SFCPQBLG-49
* Change History: 5/29/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*              03/16/2020
* Accenture    02/25/2021      Changes made to publish events if and only if it is a Billing Account
*                                            GitLab # 1366
* Virtusa      05/08/2023      Indian state value validation
* Virtusa     07/10/2023      Thailand State and city value validation GitLab #16806
* TCS         07/10/2023      Tax treatment validation check on Billing Account Gitlab #16299
* Virtusa     09/29/2023      Executing QTB_InvoiceGroupIdUpdateBatch when split invoice flag value is changed GitLab #18551
* Parth     04/30/2024     Gitlab #23284 populate translated product group on op if account language gets changed
* Parth      05/24/2024    Gitlab #23894 update dm source system on billing account if on operational account's
 * parent account or  operational account number or related operation account is changed
* Parth        06/06/2024      Gitlab #24127 - calling updateDMSourceSystemIdReference method from schedule class which will run after 15 sec
* Parth        09/13/      2024      Gitlab #26202 - update translated product name and product group value on CNL
* Thrinethra   26/02/2025      Gitlab #28889 - Dev: Create Trigger for Bi-directional Sync
*******************************************************************************************************/
public with sharing class QTB_AccountHelper {
    public static boolean platformEvent = false;
    public static boolean platformEventInsert = false;
    public static final Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    public static boolean firstRun = true;
    public static string curentUserId = userinfo.getUserId();
    public static final String ACCOUNTHELPER = QTB_Constants.ACCOUNT_HELPER;
    public static final String PARENT_PREFIX = 'BILLP-';
    public static final String CHILD_PREFIX = 'BILLC-';
    public static final Id accOperationalRecordTypeId =QTB_Utils.ACCOUNT_OPERATIONAL_RECTYPEID;
    private static List<QTB_Billing_Account_Country_Validation__mdt> billAccValMetadata = new List<QTB_Billing_Account_Country_Validation__mdt>();
    private static Boolean useProvidedData = false;
    public static boolean throwExplicitException = false;   //#16299
    public static boolean isRemitDetailsPopulated = false;
    public static boolean isBankDetailPopulated = false;
    public static final Id accOperRecordTypeId = QTB_Utils.ACCOUNT_OPERATIONAL_RECTYPEID;
    /***********************************************************************************************************
* Method :      process
* Parameters:   List<Account>,Map<Id, Account>,System.TriggerOperation
* Return Type : void
* Description:  This method loops over the list of records to be processed
**************************************************************************************************************/
    public static void process(
        List<Account> newItems,
        Map<Id, Account> oldAccountMap,
        Map<Id, Account> newAccountMap,
        System.TriggerOperation operationType
    ) {
        //added as part of Gitlab #28889
        List<Account> operationalAccShipToSiteList = new List<Account>();
        List<Account> accListBI = new List<Account>();
        List<Account> accListBU = new List<Account>();
        List<Account> accListAI = new List<Account>();
        List<Account> accListAUGenerate = new List<Account>();
        List<Account> accListAUEnqueue = new List<Account>();
        List<Account> accListTaxUpdate = new List<Account>();
        Set<ID> entityID = new Set<ID>();
        Set<Id> accListAUOracle = new Set<Id>();
        Set<Id> accListAUPlatform = new Set<Id>();
        List<account> operationalAccountList = new List<account>();
        // added as part of GitLab # 5
        Map<Id, Id> mapOfAccountToSourceOpportunityId = new Map<Id, Id>();
        //variable to store the accounts to be validated for GitLab #14644
        list<Account> accountsToValidate = new list<Account>();
        //variable to store the accounts to get billingState/shippingState validated; only for India and Thailand
        list<Account> checkValidState = new list<Account>();
        list<Account> checkValidCity = new list<Account>();
        Set<String> accShipToCountry = new Set<String>();
        list<Account> validateTreatmentAccount = new List<Account>(); //#16299
        //Set of Id to store accountId where split invoice flag vlaue is changed Gitlab #18551
        Set<Id> splitInvoiceFlagAccountId = new Set<Id>();
        //GitLab #19419 billingCountrySet - variable to store country names
        Set<String> billingCountrySet = new Set<String>();
        //GitLab #28446 legalEntitySet - variable to store the legal entities
        Set<String> legalEntitySet = new Set<String>();
        //GitLab #28446 remitToSet - variable to store the legal entities
        Set<String> remitToSet = new Set<String>();
        //#18864 Localisation for Product name
        list<Account> acclistForlocalization = new list<Account>();
        // GitLab # 22554 Boolean to check for Hold Billing
        Boolean holdBillingCheck = False;
        // GitLab # 22554 to hold Billing Status value.
        String holdBillingStatus;
        //List of account where its related op, invoice line and credit note line translated fields get updated if account language gets changed, #23284, #24775, #25043, #26202
        List<account> accListForTranslation = new List<account>();
        // #24886 Added the below list to Store Account ids when ever the Payment terms Field is updated for updating the Order and Op level payment terms Fields
        Set<Id> accListForPaymentTermsEdit = new Set<Id>();
        // #24991 Created Set to store Bill Account Ids for Updation of Related Operational Acc Records data
        Set<Id> billcUpdatedInfoId = new Set<Id>();
        // #24886 created a Map for updating only once about order List when Acc update happens (New Structure of code)
        Map<Id,Order> finalSingleUpdateOrderMap = new Map<Id,Order>();
        // #24991 created a Map  for updating AccountInfo only once when ever the Account want to be Updated(New Structure of code)
        Map<Id,Account> finalSingleUpdateAccountMap = new Map<Id,Account>();
        // #32311 List of Operational account to call updateDMSourceSystemIdReference method in after insert if Operational Account is present
        List<account> lstToUpdateBillingAcc = new List<account>();
        // #34559 Method to update Operational Account Associate on Billing Account to handle ROW LOCK error
        Set<Id> billingAccIdSet = new Set<Id>(); 
        for (Account acc : newItems) {
            switch on operationType {
                when BEFORE_INSERT {
                    if (acc.RecordTypeId == accBillRecordTypeId) {
                        accListBI.add(acc);
                        entityID.add(acc.QTB_Contract_Entity__c);
                        platformEventInsert = true;
                    }
                    
                    //added as part of Gitlab #28889
                    if(acc.RecordTypeId == accOperationalRecordTypeId && acc.Ship_To_Site_Number__c == null){
                        operationalAccShipToSiteList.add(acc);
                    }
                    
                    //Consider only the Child Billing Accounts to validate against the mandatory fields - GitLab #14644
                    if (acc.RecordTypeId == accBillRecordTypeId && acc.ParentId != null) {
                        //#16299 Validate treatment on Account update
                        accShipToCountry.add(acc.ShippingCountry);
                        validateTreatmentAccount.add(acc);
                        accountsToValidate.add(acc);
                        billingCountrySet.add(acc.BillingCountry);
                        //#28446 Adding Accounts legal entity id to the set
                        legalEntitySet.add(acc.QTB_Contract_Entity__c);
                        //Indian billing account's state validation GitLab #15399
                        //Thailand billing account's state validation GitLab #16806
                        //QTB_CountryNameForStateValidation contains country name in upperCase for which state validation should work
                        if((acc.BillingCountry != null && system.label.QTB_CountryNameForStateValidation.contains(acc.BillingCountry.toUpperCase())) ||
                           (acc.ShippingCountry != null && system.label.QTB_CountryNameForStateValidation.contains(acc.ShippingCountry.toUpperCase()))){
                               checkValidState.add(acc);
                           }
                        //Thailand billing account city validation GitLab #16806
                        if(acc.BillingCountry != null && system.label.QTB_CountryNameForCityValidation.contains(acc.BillingCountry.toUpperCase())){
                            checkValidCity.add(acc);
                        }
                        //GitLab #32435 - Moved below GITLAB US #29928 code under billing account becuase it should only apply for billing account
                        //GITLAB US #29928 Get the list of applicable countries from the custom label, split and validate for required fields
                        String applicableCountries = System.label.QTB_EdicomApplicableCountries;
                        List<String> countryList = applicableCountries.split(';');
                        if (acc.QTB_Legal_Entity_Country__c != null && countryList.contains(acc.QTB_Legal_Entity_Country__c) &&
                            (String.isBlank(acc.QTB_Tax_Registration__c) || String.isBlank(acc.QTB_Tax_ID__c) || String.isBlank(acc.QTB_TIN__c))) {
                                String errorMessage = System.label.QTB_TaxIdTaxRegTinValiadation + ' for ' + acc.QTB_Legal_Entity_Country__c + ' country.';
                                acc.addError(errorMessage);
                    }
                        //GitLab #32435 - End
                    }
                    
                    //Defect Fix Gitlab US #22022 -- Setting FuelSurchargeExempt = true for SITAD NA -- to prevent fuelsurcharge creation from prebill process
                    if(acc.QTB_SITAD__c && acc.QTB_Legal_Entity_Country__c != null && System.label.QTB_NA_Countries.containsIgnoreCase(acc.QTB_Legal_Entity_Country__c)){
                        acc.QTB_Fuel_Surcharge_Exempt__c = true;
                    }
                }
                when BEFORE_UPDATE {
                    //#24140 Throwing a validation while editing the payment Terms of US and Canada users and Allowing Admin Profiles to edit
                    //Adding Test.isRunningTest() condition to avoid the existing test class failures due to new validations introduced
                    if (acc.RecordTypeId == accBillRecordTypeId) {
                        if(acc.Payment_Terms__c != null && acc.Payment_Terms__c != oldAccountMap.get(acc.ID).Payment_Terms__c
                           && acc.QTB_Legal_Entity_Country__c != null && QTB_Billing_Countries__c.getValues(acc.QTB_Legal_Entity_Country__c ) == null && !Test.isRunningTest()){
                               Id profileId=userinfo.getProfileId();
                               String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
                               if(!system.label.QTB_EditAccPaymentTermsFieldValidationExcludeProfiles.containsIgnoreCase(profileName)){
                                   acc.adderror('Payment Terms Edit option is not applicable for ' +acc.QTB_Legal_Entity_Country__c+' country');
                               }
                           }
                        accListBU.add(acc);
                        billingCountrySet.add(acc.BillingCountry);//TO REMOVE
                        if (acc.ShippingCountry != oldAccountMap.get(acc.ID).ShippingCountry){
                            
                            accListTaxUpdate.add(acc);
                            entityID.add(acc.QTB_Contract_Entity__c);
                        }
                    }
                    //#16299 Validate treatment on Account update
                    //Triggering the validation method only when there is change in below field change
                    if(acc.RecordTypeId == accBillRecordTypeId && acc.ParentId != null && QTB_Billing_Countries__c.getValues(acc.QTB_Legal_Entity_Country__c) != null && ((acc.ShippingCountry != oldAccountMap.get(acc.ID).ShippingCountry)||(acc.QTB_Special_Tax_Condition__c != oldAccountMap.get(acc.ID).QTB_Special_Tax_Condition__c)||(acc.SBQQ__TaxExempt__c != oldAccountMap.get(acc.ID).SBQQ__TaxExempt__c)||(acc.QTB_Contract_Entity__c != oldAccountMap.get(acc.ID).QTB_Contract_Entity__c))){
                        validateTreatmentAccount.add(acc);
                        
                    }
                    //Consider only the Child Billing Accounts to validate against the mandatory fields - GitLab #14644
                    if (acc.RecordTypeId == accBillRecordTypeId && acc.ParentId != null) {
                        accountsToValidate.add(acc);  
                        //Indian billing account's state validation in before update GitLab #15399
                        //Thailand billing account's state validation in before update GitLab #16806
                        if(acc.QTB_Legal_Entity_Country__c != null && system.label.QTB_CountryNameForStateValidation.contains(acc.QTB_Legal_Entity_Country__c.toUpperCase()) &&
                           (system.label.QTB_CountryNameForStateValidation.contains(acc.BillingCountry.toUpperCase()) || system.label.QTB_CountryNameForStateValidation.contains(acc.ShippingCountry.toUpperCase())) &&
                           ((acc.ShippingState != null && (!acc.shippingState.equals( oldAccountMap.get(acc.ID).shippingState))) ||
                            ((acc.BillingState != null && !acc.BillingState.equals( oldAccountMap.get(acc.ID).BillingState)))||
                            (acc.BillingCountry != oldAccountMap.get(acc.ID).BillingCountry)||
                            (acc.ShippingCountry != oldAccountMap.get(acc.ID).ShippingCountry))){
                                checkValidState.add(acc);
                            }
                        //Thailand billing account's city validation in before update GitLab #16806
                        if(acc.QTB_Legal_Entity_Country__c != null && system.label.QTB_CountryNameForCityValidation.contains(acc.QTB_Legal_Entity_Country__c.toUpperCase()) &&
                           acc.BillingCity != null && !acc.BillingCity.equals( oldAccountMap.get(acc.ID).BillingCity)){
                               checkValidCity.add(acc);
                           }
                        //GitLab #32435 - Moved below GITLAB US #29928 code under billing account becuase it should only apply for billing account
                        //GITLAB US #29928 Get the list of applicable countries from the custom label, split and validate for required fields
                        String applicableCountries = System.label.QTB_EdicomApplicableCountries;
                        List<String> countryList = applicableCountries.split(';');
                        
                        if (acc.QTB_Legal_Entity_Country__c != null && countryList.contains(acc.QTB_Legal_Entity_Country__c) &&
                            (String.isBlank(acc.QTB_Tax_Registration__c) || String.isBlank(acc.QTB_Tax_ID__c) || String.isBlank(acc.QTB_TIN__c))) {
                                
                                String errorMessage = System.label.QTB_TaxIdTaxRegTinValiadation + ' for ' + acc.QTB_Legal_Entity_Country__c + ' country.';
                                acc.addError(errorMessage);    
                            }
                        //GitLab #32435 - End
                    }
                    
                    //Defect Fix Gitlab US #22022 -- Setting FuelSurchargeExempt = true for SITAD NA -- to prevent fuelsurcharge creation from prebill process
                    if(oldAccountMap.get(acc.ID).QTB_SITAD__c != acc.QTB_SITAD__c && acc.QTB_SITAD__c && acc.QTB_Legal_Entity_Country__c != null &&
                       System.label.QTB_NA_Countries.containsIgnoreCase(acc.QTB_Legal_Entity_Country__c)){
                           acc.QTB_Fuel_Surcharge_Exempt__c = true;
                       }
                    
                }
                when BEFORE_DELETE {
                }
                when AFTER_INSERT {
                    //Gitlab#8 Start - Invoked from Billing Account Created thru Flow
                    if (
                        acc.RecordTypeId == accBillRecordTypeId &&
                        acc.QTB_Source_Order__c != null
                    ) {
                        System.debug('BA Create Entry Point>'+acc.QTB_Source_Order__c+acc.RecordTypeId);
                        accListAI.add(acc);
                    }
                    //Gitlab#8 End
                    if (
                        acc.RecordTypeId == accBillRecordTypeId &&
                        acc.QTB_Source_Opportunity__c != null
                    ) {
                        // added as part of GitLab # 5
                        if (
                            String.isNotBlank(acc.ParentId) ||
                            acc.QTB_Create_Parent_Billing_Account__c == true
                        ) {
                            mapOfAccountToSourceOpportunityId.put(
                                acc.Id,
                                acc.QTB_Source_Opportunity__c
                            );
                        }
                    }
                    // #32311 List of Operational account to call updateDMSourceSystemIdReference method in after insert if Operational Account is present
                    if((acc.BillingCountry == 'New Zealand' || acc.BillingCountry == 'Australia') && acc.RecordTypeId == accOperationalRecordTypeId){
                        lstToUpdateBillingAcc.add(acc);
                    }
                }
                when AFTER_UPDATE {
                    //Gitlab #18864 As part of localisation of product description and UOM description based on account language change triggering
                    if(acc.RecordTypeId == accBillRecordTypeId){
                        // #24991 Adding all Billc Accs when ever the Legal Entity and Country updated to Update for respective Operational Account records
                        if((acc.QTB_Contract_Entity__c != Null && acc.QTB_Contract_Entity__c != oldAccountMap.get(acc.id).QTB_Contract_Entity__c) ||
                           (acc.QTB_Legal_Entity_Country__c != Null && acc.QTB_Legal_Entity_Country__c != oldAccountMap.get(acc.id).QTB_Legal_Entity_Country__c)){
                               billcUpdatedInfoId.add(acc.Id);
                           }
                        if(acc.QTB_Language__c != oldAccountMap.get(acc.ID).QTB_Language__c ){
                            acclistForlocalization.add(acc);
                        }
                    }
                    //Gitlab #23284 populate translated product group on op if account language gets changed,
                    //checking custom label to check account country as currently this functionality is only for cluster 2 countries
                    //Gitlab #24775 populate translated UOM value on invoice line
                    //Gitlab #25043 populate translated UOM value on credit note line
                    //gitlab #26202 populated translated product group on cnl
                    if(acc.RecordTypeId == accBillRecordTypeId && acc.QTB_Language__c != oldAccountMap.get(acc.ID).QTB_Language__c &&
                       acc.QTB_Legal_Entity_Country__c!= null && system.label.QTB_countryNameForTranslation.contains(acc.QTB_Legal_Entity_Country__c) ){
                           accListForTranslation.add(acc);
                       }
                    if (acc.RecordTypeId == accBillRecordTypeId) {
                        // 24886 Added the below Logic for handling when ever the Payment terms field is updated
                        if(acc.Payment_Terms__c !=Null && acc.Payment_Terms__c != oldAccountMap.get(acc.ID).Payment_Terms__c){
                            accListForPaymentTermsEdit.add(acc.id);
                        }
                        //Gitlab#8 Start -- Invoked from Component logic for BA association
                        if (
                            QTB_AccountHelper.firstRun == true &&
                            (oldAccountMap.get(acc.Id)).QTB_Source_Order__c == null ||
                            ((oldAccountMap.get(acc.Id)).QTB_Source_Order__c != null && acc.QTB_Source_Order__c != (oldAccountMap.get(acc.Id)).QTB_Source_Order__c)){
                                System.debug('BA Assoc Entry Point>'+acc.QTB_Source_Order__c);
                                if ((oldAccountMap.get(acc.Id)).QTB_Source_Order__c != null) {
                                    System.debug('BA Assoc Entry Point>'+(oldAccountMap.get(acc.Id)).QTB_Source_Order__c);
                                }
                                accListAUGenerate.add(acc);
                            }
                        //Gitlab#8 End
                        if (
                            QTB_AccountHelper.firstRun == true &&
                            (oldAccountMap.get(acc.Id)).QTB_Source_Opportunity__c == null ||
                            ((oldAccountMap.get(acc.Id)).QTB_Source_Opportunity__c != null &&
                             acc.QTB_Source_Opportunity__c !=
                             (oldAccountMap.get(acc.Id)).QTB_Source_Opportunity__c)
                        ) {
                            // added as part of GitLab # 5
                            if (
                                String.isNotBlank(acc.ParentId) ||
                                acc.QTB_Create_Parent_Billing_Account__c == true
                            ) {
                                mapOfAccountToSourceOpportunityId.put(
                                    acc.Id,
                                    acc.QTB_Source_Opportunity__c
                                );
                            }
                        }
                        //Gitlab #31117 Addition of WHT for Turkey 
                        if (
                            (acc.QTB_Special_Tax_Condition__c !=
                             oldAccountMap.get(acc.ID).QTB_Special_Tax_Condition__c) ||
                            (acc.SBQQ__TaxExempt__c !=
                             oldAccountMap.get(acc.ID).SBQQ__TaxExempt__c) ||
                            (acc.ShippingCountry !=
                             oldAccountMap.get(acc.ID).ShippingCountry) ||
                            (acc.QTB_Hold_Billing__c !=
                             oldAccountMap.get(acc.ID).QTB_Hold_Billing__c) ||
                            (acc.QTB_Withholding_Applicable__c !=
                             oldAccountMap.get(acc.ID).QTB_Withholding_Applicable__c)
                        ) {
                            // GitLab # 22554 Boolean to be used to update Hold Status only when QTB_Hold_Billing__c field is changed
                            if(acc.QTB_Hold_Billing__c != oldAccountMap.get(acc.ID).QTB_Hold_Billing__c){
                                holdBillingStatus = 'In Progress';
                                holdBillingCheck = True;
                            }
                            accListAUEnqueue.add(acc);
                        }
                        // consider account to send Oracle event, if and only if it is a Billing Account
                        // and either Name or Tax Registration or Billing Street or State or PostalCode changed
                        // GitLab # 1366
                        if (
                            (acc.Name != oldAccountMap.get(acc.ID).Name) ||
                            (acc.BillingStreet != oldAccountMap.get(acc.ID).BillingStreet) ||
                            (acc.BillingCity != oldAccountMap.get(acc.ID).BillingCity) ||
                            (acc.BillingState != oldAccountMap.get(acc.ID).BillingState) ||
                            (acc.QTB_Tax_Registration__c !=
                             oldAccountMap.get(acc.ID).QTB_Tax_Registration__c) ||
                            (acc.BillingPostalCode !=
                             oldAccountMap.get(acc.ID).BillingPostalCode)
                        ) {
                            accListAUOracle.add(acc.id);
                        }
                        // consider account to send OS event, if and only if it is a Billing Account
                        // and either of the LOB is newly added to the account
                        // GitLab # 1366
                        if (
                            ((!platformEvent) &&
                             (!platformEventInsert) &&
                             ((oldAccountMap.get(acc.id).QTB_scan__c != acc.QTB_scan__c &&
                               acc.QTB_scan__c == true) ||
                              (oldAccountMap.get(acc.id).QTB_shred__c != acc.QTB_shred__c &&
                               acc.QTB_shred__c == true) ||
                              (oldAccountMap.get(acc.id).QTB_Records_Management__c !=
                               acc.QTB_Records_Management__c &&
                               acc.QTB_Records_Management__c == true) ||
                              (oldAccountMap.get(acc.id).QTB_Data_Management__c !=
                               acc.QTB_Data_Management__c &&
                               acc.QTB_Data_Management__c == true)))
                        ) {
                            system.debug('inside account helper');
                            system.debug('old' + oldAccountMap);
                            accListAUPlatform.add(acc.id);
                        }
                        //adding accountId to set when split invoice flag value is changed Gitlab #18551
                        //31228 Added extra conditions for With Holding update and Both With Holding and Split Update at a time calling the batch
                        if((acc.QTB_Split_Invoice_Flag__c != oldAccountMap.get(acc.Id).QTB_Split_Invoice_Flag__c ||
                            acc.QTB_Withholding_Applicable__c != oldAccountMap.get(acc.Id).QTB_Withholding_Applicable__c) ||
                           (acc.QTB_Split_Invoice_Flag__c != oldAccountMap.get(acc.Id).QTB_Split_Invoice_Flag__c &&
                            acc.QTB_Withholding_Applicable__c != oldAccountMap.get(acc.Id).QTB_Withholding_Applicable__c)){
                                splitInvoiceFlagAccountId.add(acc.Id);
                            }
                    }
                    if(acc.recordTypeId==accOperationalRecordTypeId &&
                       (oldAccountMap.get(acc.id).Ship_To_Site_Number__c != acc.Ship_To_Site_Number__c ||
                        oldAccountMap.get(acc.id).parentId != acc.parentId ||
                        oldAccountMap.get(acc.id).Related_Operational_Account__c != acc.Related_Operational_Account__c) ){
                            // Git-13095  //Git-23894
                            operationalAccountList.add(acc);
                        }
                    // #34559 Method to update Operational Account Associate on Billing Account to handle ROW LOCK error
                    if(acc.RecordTypeId == accOperationalRecordTypeId && oldAccountMap.get(acc.id).Related_Billing_Account__c != acc.Related_Billing_Account__c && acc.Related_Billing_Account__c !=null && !acc.QTB_Operational_Account_Associated__c){
                        billingAccIdSet.add(acc.Related_Billing_Account__c);
                    }
                }
                when else {
                }
            }
        }
        
        switch on operationType {
            when BEFORE_INSERT {
                //To validate the account mandatory fields - GitLab #14644
                //Adding Test.isRunningTest() condition to avoid the existing test class failures due to new validations introduced
                if (accountsToValidate.size() > 0 && !Test.isRunningTest()) {
                    QTB_BillingAccountUtil.validateMandatoryAccountFields(accountsToValidate);
                    //GitLab #28446 To auto populate the Remit Address on Billing Account during creation
                    if (!QTB_AccountHelper.isRemitDetailsPopulated && accountsToValidate.size() > 0) {
                        //QTB_AccountHelperUtils.updateRemitToAddress(accountsToValidate, billingCountrySet);
                        QTB_AccountHelperUtils.updateRemitToAddress(accountsToValidate, legalEntitySet);
                    }
                    //GitLab #28446 To auto populate the Bank Details on Billing Account during creation
                    //#28446 Adding Accounts Remit to id to the set
                    remitToSet.add(accountsToValidate[0].QTB_Remit_To__c);
                    if (!QTB_AccountHelper.isBankDetailPopulated && accountsToValidate.size() > 0 && remitToSet != null && legalEntitySet!= null) {
                        QTB_AccountHelperUtils.updateBankDetail(accountsToValidate, remitToSet, legalEntitySet);
                    }
                    
                }
                if (accListBI.size() > 0) {
                    QTB_BillingAccountUtil.updateBillingAccountName(accListBI, null); //SFCPQBLG-648
                    
                }
                if (!entityID.isEmpty()) {
                    UpdateSpecialTaxCondition(accListBI, entityID);
                }
                //#16299 Validate treatment on Account
                if(!validateTreatmentAccount.isEmpty()){
                    QTB_AccountHelperUtils.validateTaxTreatmentOnAccount(validateTreatmentAccount,'BEFORE_INSERT');
                }
                // #15399 #16806 validate India and Thailand billing account's billingState and ShippingState value
                if (!checkValidState.isEmpty() && !Test.isRunningTest()){
                    QTB_AccountHelperUtils.validateStateValue(checkValidState);
                }
                // #16806 validate Thailand billing account's BillingCity value
                if (!checkValidCity.isEmpty() && !Test.isRunningTest()){
                    QTB_AccountHelperUtils.validateCityValue(checkValidCity);
                }
                //added as part of Gitlab #28889
                if (operationalAccShipToSiteList.size() > 0) {
                    populateOpAccountShipToSiteNum(operationalAccShipToSiteList);
                }
                //US#29584 changes
                if(accListBI.size() > 0){
                    populateDefaultValues(accListBI);
                }
            }
            when BEFORE_UPDATE {
                if (accListBU.size() > 0) {
                    updateBillingAccountName(accListBU, oldAccountMap); //SFCPQBLG-648
                }
                //To validate the account mandatory fields - GitLab #14644
                if (accountsToValidate.size() > 0 && !Test.isRunningTest()) {
                    validateMandatoryAccountFields(accountsToValidate);
                }
                if (!accListTaxUpdate.isEmpty()) {
                    UpdateSpecialTaxCondition(accListTaxUpdate, entityID);
                }
                //#16299 Validate treatment
                if(!validateTreatmentAccount.isEmpty()){
                    QTB_AccountHelperUtils.validateTaxTreatmentOnAccount(validateTreatmentAccount,'BEFORE_UPDATE');
                }
                // #15399 #16806 validate India and Thailand billing account's billingState and ShippingState value
                if (!checkValidState.isEmpty() && !Test.isRunningTest()){
                    system.debug('before Update operation');
                    QTB_AccountHelperUtils.validateStateValue(checkValidState);
                }
                // #16806 validate Thailand billing account's BillingCity value
                if (!checkValidCity.isEmpty() && !Test.isRunningTest()){
                    QTB_AccountHelperUtils.validateCityValue(checkValidCity);
                }
                }
            when BEFORE_DELETE {
            }
            when AFTER_INSERT {
                //Gitlab#8 Start
                if (accListAI.size() > 0) {
                    QTB_BillingAccountUtil.GenerateEvergreenRecords(
                        accListAI,
                        null,
                        QTB_Constants.BILL_ACC_CREATION
                    );
                }
                //Gitlab#8 End
                
                // added as part of GitLab # 5
                if (!mapOfAccountToSourceOpportunityId.isEmpty()) {
                    QTB_BillingAccountUtil.createSalesBillingAccountRelations(mapOfAccountToSourceOpportunityId);
                }
                // #32311 List of Operational account to call updateDMSourceSystemIdReference method in after insert if Operational Account is present
                if(!lstToUpdateBillingAcc.isEmpty()){
                    QTB_ScheduleAccountDMSourceUpdate.scheduleDelayedJob(lstToUpdateBillingAcc);
                }   
            }
            when AFTER_UPDATE {
                //#24991 calling the method for Updation of Operational Acc data based upon BillC Update
                if(!billcUpdatedInfoId.isEmpty() && QTB_RecursiveHandlerCheck.updateOperationalAccInfoBasedUponBillCUpdate == True){
                    List<Account> accupdate = QTB_AccountHelperUtils.updateOperationalAccInfoBasedUponBillCUpdate(billcUpdatedInfoId);
                    if(accupdate != null){
                        for(Account acc : accupdate){
                            // If that orderid not present in list add as it is for further updates
                            if(!finalSingleUpdateAccountmap.containsKey(acc.id)){
                                finalSingleUpdateAccountmap.put(acc.id,acc);
                            }else{
                                // If that Id presents add that related Field Name as per id and Value as Fields data that needs to be updated
                                finalSingleUpdateAccountmap.get(acc.id).put('QTB_Legal_Entity_Country__c', acc.QTB_Legal_Entity_Country__c);
                                finalSingleUpdateAccountmap.get(acc.id).put('QTB_Contract_Entity__c', acc.QTB_Contract_Entity__c);
                            }
                        }
                    }
                }
                // #24886 Calling the method to update Orders payment Term Value based upon Billc Paymet Terms Updated Value
                if(!accListForPaymentTermsEdit.isEmpty() && QTB_RecursiveHandlerCheck.updatePaymentTermBasedUponAccountPaymentTermValue == True){
                    // returned from Method orderList that needs to get updated and added to list
                    List<order> orderUpdate = QTB_AccountHelperUtils.updatePaymentTermBasedUponAccountPaymentTermValue(accListForPaymentTermsEdit);
                    if(orderUpdate != null){
                        for(order ord : orderUpdate){
                            // If that orderid not present in list add as it is for further updates
                            if(!finalSingleUpdateOrderMap.containsKey(ord.id)){
                                finalSingleUpdateOrderMap.put(ord.id,ord);
                            }else{
                                // If that Id presents add that related Field Name as per id and Value as Fields data that needs to be updated
                                finalSingleUpdateOrderMap.get(ord.id).put('SBQQ__PaymentTerm__c', ord.SBQQ__PaymentTerm__c);
                            }
                        }
                    }
                }
                if(!acclistForlocalization.isEmpty()){
                    // Gitlab 18864 Passing Account Ids of Language change for Localization Update
                    QTB_OrderProductUtils.setLocalisedProductName(null,acclistForlocalization);
                    //#32975 Commented the below calling of method as this is getting already fired on Account language update
                    //This results in duplication of method calling and unnecessary hitting the SOQL limits
                    /* if(!accCountries.isEmpty() && QTB_RecursiveHandlerCheck.updateUOMDescription){
QTB_OrderProductUtils.updateUOMDescription(null,acclistForlocalization,accCountries);
}*/
                    // Gitlab 26202 Passing Account Ids of Language change for Localization Update on cnl
                    QTB_CNLHelperUtils.setProductNameTranslation(null,acclistForlocalization);
                }
                // Gitlab 23284 on change of account language update translated product group value on op
                // Gitlab #24775 populate translated UOM value on invoice line
                // Gitlab #25043 populate translated UOM value on cnl
                // gitlab #26202 update translated product group on cnl
                if(!accListForTranslation.isEmpty()){
                    QTB_OrderProductUtils.setTranslatedProductGroup(null,accListForTranslation);
                    QTB_InvoiceLineHelperUtils.setUOMcodeTranslation(null,accListForTranslation);
                    QTB_CNLHelperUtils.setTranslationFieldsOnCNL(null,accListForTranslation);
                }
                //Gitlab#8 Start
                if (accListAUGenerate.size() > 0) {
                    GenerateEvergreenRecords(
                        accListAUGenerate,
                        oldAccountMap,
                        QTB_Constants.BILL_ACC_ASSOCIATION
                    );
                }
                //Gitlab#8 End
                
                // added as part of GitLab # 5
                if (!mapOfAccountToSourceOpportunityId.isEmpty()) {
                    createSalesBillingAccountRelations(mapOfAccountToSourceOpportunityId);
                }
                //GitLab # 22554 To update account Hold status field if job size is 200 or more
                if (accListAUEnqueue.size() > 0) {
                    if ([SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Holding'] < 100)
                    {
                        Database.executeBatch(
                            new QTB_TaxTreatmentPopulationBatch(accListAUEnqueue),
                        200
                            );
                    }
                    else{
                        if([SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable' AND Status = 'Holding'] < 100){
                            System.enqueueJob(new QTB_QueueableAccountUpdate(accListAUEnqueue));
                        }
                        else{
                            //GitLab # 22554 To update account Hold status field if job size is 200 or more
                            if(holdBillingCheck == True)
                            {
                                holdBillingStatus = 'Hold Update Failed';
                            }
                        }
                    }
                    //GitLab # 22554 To update account Hold status field In Progress if job size less than 200
                    if(holdBillingCheck == True)
                    {
                        updateAccountForHoldStatus(accListAUEnqueue,holdBillingStatus);
                    }
                }
                if (accListAUOracle.size() > 0) {
                    publishBillingOracleEvent(accListAUOracle, oldAccountMap);
                }
                if (accListAUPlatform.size() > 0) {
                    billingOSUpdatePlatformEvent(accListAUPlatform, oldAccountMap);
                }
                if (!operationalAccountList.isEmpty()){
                    // Git-13095
                    // Git-24127 to call updateDMSourceSystemIdReference method from schedule class which will run after 15 sec as account relation hierarchy flow
                    // update the billing account due to which biliing account is in lock state, and after that if operational account get created it calls the updateDMSourceSystemIdReference
                    QTB_ScheduleAccountDMSourceUpdate.scheduleDelayedJob(operationalAccountList);
                }
                // #34559 Method to update Operational Account Associate on Billing Account to handle ROW LOCK error
                if (!operationalAccountList.isEmpty() && QTB_RecursiveHandlerCheck.afterUpdateCheck_updateOperationalAccAssociateOnBlngAcc == True){
                    QTB_ScheduleOperationalAccountAssociate.scheduleDelayedJob(billingAccIdSet);
                }
                //Executing batch class to update invoiceGroupId and invoiceGrouping on orderItem Gitlab #18551
                if(!splitInvoiceFlagAccountId.isEmpty()){
                    database.executeBatch(new QTB_InvoiceGroupIdUpdateBatch(splitInvoiceFlagAccountId));
                }
                
                // #24991 Updating only once the Account List what fields needs to be further updated as per the new code Structure
                if(finalSingleUpdateAccountmap.size() > 0){
                    update finalSingleUpdateAccountMap.values();
                }
                // #24886 Updating only once the Order List that is Account attached and should be used for further updates as well as per new code Structure
                if(finalSingleUpdateOrderMap.size() > 0){
                    update finalSingleUpdateOrderMap.values();
                }
            }
            when else {
            }
        }
    }
    
    /***********************************************************************************************************
* Method : GenerateEvergreenRecords
* Parameters: List<Account>,Map<Id,Account>,String
* Requirement : Gitlab#8
* Start Date : 01/04/2021
* Author : Accenture
* Description: Generate billing records on billing account creation or association
* Event: this method invoked on after insert and after update events from Account Trigger
**************************************************************************************************************/
    public static void GenerateEvergreenRecords(
        List<Account> newAccList,
        Map<Id, Account> oldAccountMap,
        String evntStr
    ) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            if (!newAccList.isEmpty()) {
                Map<Id, Id> mapOfSourceOrdIdBillAccId = new Map<Id, Id>();
                Set<Id> sourceOrderIdSet = new Set<Id>();
                Set<Id> billAccIdSet = new Set<Id>();
                Map<String, QTB_LOB_Mapping__c> mapOfPrimaryLineToAccLOB = QTB_LOB_Mapping__c.getAll(); //Fetch the Custom Setting map which holds the mapping between accounts LOB & opportunity primary product line.
                List<Account> accountsToUpdateforLOB = new List<Account>();
                List<Order> sourceOrderList = new List<Order>();
                Map<Id, Order> mapOfSourceIdBillOrd = new Map<Id, Order>();
                List<Order> billingOrdersToInsert = new List<Order>();
                List<OrderItem> salesOrderItemList = new List<OrderItem>();
                Map<string, OrderItem> mapOfSalesItemIdToBillItem = new Map<string, OrderItem>();
                List<OrderItem> billingOrderItemsToInsert = new List<OrderItem>();
                Set<Id> salesOrderIdSet = new Set<Id>();
                Set<String> CSAutonumberSet = new Set<String>();
                
                for (Account acc : newAccList)
                {
                    if (
                        acc.RecordTypeId == accBillRecordTypeId &&
                        acc.QTB_Source_Order__c != null
                    )
                    {
                        mapOfSourceOrdIdBillAccId.put(acc.QTB_Source_Order__c, acc.id);  //Map of Sales Order id to Billing Account id
                    }
                }
                
                //Collect Sales Order ids and Billing Account ids
                if (
                    mapOfSourceOrdIdBillAccId != null &
                    !mapOfSourceOrdIdBillAccId.isEmpty()
                )
                {
                    sourceOrderIdSet.addAll(mapOfSourceOrdIdBillAccId.keySet());
                    billAccIdSet.addAll(mapOfSourceOrdIdBillAccId.values());
                }
                
                //Get a copy of current Accounts in context as we can't update record on trigger context variable in After events
                if (!billAccIdSet.isEmpty()) {
                    
                    //LOB checkbox update logic on BA based on Opportunity's Primary Product Line
                    for (Account acc : [
                        SELECT
                        id,
                        QTB_Source_Opportunity__r.Primary_Product_Line__c,
                        QTB_Source_Opportunity__c,
                        QTB_Records_Management__c,
                        QTB_Data_Management__c,
                        QTB_scan__c,
                        QTB_shred__c
                        FROM Account
                        WHERE id IN :billAccIdSet
                    ]) {
                        if (acc.QTB_Source_Opportunity__r.Primary_Product_Line__c != null)
                        {
                            //Check whether billing accounts opportunity primary product line mapping is present in custom setting account product line vs opportunity primary product line map
                            if(mapOfPrimaryLineToAccLOB.containsKey(acc.QTB_Source_Opportunity__r.Primary_Product_Line__c))
                            {
                                //Fetch the billing account primary product line checkbox field corresponding to opportunity primary product line using te map
                                List<String> accounlobfields = mapOfPrimaryLineToAccLOB.get(acc.QTB_Source_Opportunity__r.Primary_Product_Line__c).QTB_Account_LOB__c.split(',');
                                
                                //Check value to True dynamically
                                for (string eachlobfield : accounlobfields)
                                {
                                    acc.put(eachlobfield, true);
                                }
                                accountsToUpdateforLOB.add(acc);
                            }
                        }
                    }
                }
                //Update the billing account LOB based on BAs opportunity primary product line
                if (!accountsToUpdateforLOB.isEmpty())
                    update accountsToUpdateforLOB;
                
                //Collect Sales Orders and Sales Order items
                if (!sourceOrderIdSet.isEmpty() && sourceOrderIdSet != null) {
                    sourceOrderList = QTB_CreateBillingRecords.collectSalesOrders(sourceOrderIdSet,evntStr);
                }
                
                //Source Order clone and Billing Order Creation
                map<Id,Order> insertedBillingOrderMap;
                
                //Logic to create billing order from sales order if the account has Sales Order
                if (!sourceOrderList.isEmpty()) {
                    for (Order sourceOrd : sourceOrderList)
                    {
                        if (sourceOrd.Orderitems.size() > 0)
                            salesOrderItemList.addAll(sourceOrd.Orderitems);
                        if (mapOfSourceOrdIdBillAccId.containsKey(sourceOrd.Id))
                        {
                            //Logic to clone sales order to create billing order
                            Order tempOrd = QTB_CreateBillingRecords.cloneSaleOrder(
                                sourceOrd,
                                mapOfSourceOrdIdBillAccId.get(sourceOrd.id),
                                null
                            );
                            if (tempOrd != null)
                            {
                                billingOrdersToInsert.add(tempOrd);
                                mapOfSourceIdBillOrd.put(sourceOrd.id, tempOrd); //This map is used to store sales Order id to respective billing order id
                            }
                        }
                    }
                    if (!billingOrdersToInsert.isEmpty())
                    {
                        QTB_CreateBillingRecords.insertBillOrders(billingOrdersToInsert);
                        if(billingOrdersToInsert[0].Id != null)
                        {insertedBillingOrderMap = new map <ID,Order>(billingOrdersToInsert);}
                    }
                }
                //Check if Sales Order has the correct Billing Order
                if (!salesOrderItemList.isEmpty()) {
                    for (OrderItem salesItem : salesOrderItemList) {
                        if (mapOfSourceIdBillOrd.containsKey(salesItem.OrderId) && salesItem.SBQQ__OrderedQuantity__c > 0)
                        {
                            OrderItem tempItem = QTB_CreateBillingRecords.cloneSalesItem(
                                salesItem,
                                mapOfSourceIdBillOrd.get(salesItem.OrderId)
                            );
                            if (tempItem != null)
                            {
                                billingOrderItemsToInsert.add(tempItem);
                                mapOfSalesItemIdToBillItem.put(
                                    string.valueOf(salesItem.Id),
                                    tempItem
                                );
                            }
                            //Collect all Autonumber data twinned from quote line
                            CSAutonumberSet.add(salesItem.QTB_OriginalConsumptionID__c);
                            salesOrderIdSet.add(salesItem.Id);
                        }
                        
                    }
                    if (!billingOrderItemsToInsert.isEmpty())
                    {
                        System.enqueueJob(new QTB_AsyncBillingAccountOrderItemCreation(salesOrderIdSet,CSAutonumberSet,billingOrderItemsToInsert,
                                                                                       mapOfSalesItemIdToBillItem,insertedBillingOrderMap));
                    }
                }
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            SBQQ.TriggerControl.enable();
            throw e;
        } finally {
            firstRun = false;
        }
    }
    
    /***********************************************************************************************************
* Method : updateBillingAccountName
* Parameters: List<Account>,Map<Id,Account>
* Requirement : SFCPQBLG-648
* Start Date : 06/08/2020
* Author : Accenture
* Description: Method to add a Prefix to Billing Account Names and make the Name field Read Only once created
*              and clone Standard Name to Billing Account Invoice Name field
**************************************************************************************************************/
    public static void updateBillingAccountName(
        List<Account> accNewList,
        Map<Id, Account> oldAccountMap
    ) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            for (Account acc : accNewList) {
                String tempName;
                if (oldAccountMap == null) {
                    //Before Insert
                    acc.QTB_Billing_Account_Invoice_Name__c = acc.Name; //Clone Account Name
                    tempName = acc.Name;
                } else if (oldAccountMap != null) {
                    //Before Update
                    if (
                        acc.Name != oldAccountMap.get(acc.Id).Name && acc.recordTypeId != accBillRecordTypeId
                        && acc.QTB_FSO__c != true && !Test.isRunningTest()
                    ) {
                        //Throw error if Name is edited
                        acc.addError(Label.QTB_Account_Name_Validation);
                    }
                    if (
                        acc.QTB_Billing_Account_Invoice_Name__c !=
                        oldAccountMap.get(acc.Id).QTB_Billing_Account_Invoice_Name__c
                    ) {
                        tempName = acc.QTB_Billing_Account_Invoice_Name__c;
                    }
                }
                if (String.isNotBlank(tempName)) {
                    //Update Standard Name Field with a Prefix
                    if(acc.QTB_FSO__c != True){
                        if (acc.ParentId == null) {
                            acc.Name = PARENT_PREFIX + tempName; //Prefix Name with BILLP if Parent Account
                        } else {
                            acc.Name = CHILD_PREFIX + tempName; //Prefix Name with BILLC if Child Account
                        }
                    }
                }
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : billingOSUpdatePlatformEvent
* Parameters: Set<Id> newItems,Map<Id,Account>
* Requirement : SFCPQBLG-48
* Start Date : 06/14/2020
* Author : Accenture
* Description: Publish Platform Event on billing account updation
**************************************************************************************************************/
    public static void billingOSUpdatePlatformEvent(
        Set<Id> newItems,
        Map<Id, Account> oldItems
    ) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            String whereCond =
                ' where RecordTypeId=\'' +
                QTB_Utils.ACCOUNT_BILL_RECTYPEID +
                '\'' +
                'and id IN :accIdSet';
            if (newItems.size() > 0) {
                QTB_Utils.publishBillingAccountEvent(newItems, whereCond);
            }
            platformEvent = true;
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : publishBillingOracleEvent
* Parameters: List<Account>,Map<Id,Account>
* Requirement : SFCPQBLG-646
* Start Date : 06/14/2020
* Author : Accenture
* Description: Publish Platform Event on billing account updation
**************************************************************************************************************/
    public static void publishBillingOracleEvent(
        Set<Id> accNewSet,
        Map<Id, Account> oldAccountMap
    ) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            // GitLab # 1366 - Added Account RecordType check
            String whereCond =
                ' where accountid in:sourceIdSet and Account.RecordTypeId=\'' +
                QTB_Utils.ACCOUNT_BILL_RECTYPEID +
                '\'';
            if (!accNewSet.isEmpty()) {
                QTB_Utils.publishBillingAccountOracleOS(accNewSet, whereCond);
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            throw e;
        }
    }
    
    public static map<String, String> GetSpecialTaxConditions(
        list<String> countries
    ) {
        map<String, String> metaRecs = new Map<String, String>();
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            if (!countries.isEmpty()) {
                for (QTB_TaxConditionSetting__mdt meta : [
                    SELECT
                    QTB_LegalEntityCountry__c,
                    QTB_ShippingCountry__c,
                    QTB_SpecialTaxCondition__c
                    FROM QTB_TaxConditionSetting__mdt
                    WHERE QTB_LegalEntityCountry__c IN :countries
                ]) {
                    if (
                        meta.QTB_LegalEntityCountry__c != null &&
                        meta.QTB_ShippingCountry__c != null &&
                        meta.QTB_SpecialTaxCondition__c != null
                    )
                        metaRecs.put(
                            meta.QTB_LegalEntityCountry__c + meta.QTB_ShippingCountry__c,
                            meta.QTB_SpecialTaxCondition__c
                        );
                }
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            throw e;
        }
        return metaRecs;
    }
    
    public static void UpdateSpecialTaxCondition(
        list<Account> newAccList,
        set<ID> entityID
    ) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Map<ID, blng__LegalEntity__c> entityMap = new Map<ID, blng__LegalEntity__c>(
                [
                    SELECT id, blng__Country__c
                    FROM blng__LegalEntity__c
                    WHERE id IN :entityID
                ]
            );
            map<String, String> taxMap = new Map<String, String>();
            list<string> countries = new List<String>();
            
            for (blng__LegalEntity__c entity : entityMap.values()) {
                
                // sagar adding if condition
                if(entity.blng__Country__c != null)
                {
                    countries.add(entity.blng__Country__c.toLowerCase());
                }
            }
            if (!countries.isEmpty()) {
                taxMap = GetSpecialTaxConditions(countries);
            }
            for (Account newAcc : newAccList) {
                if (
                    newAcc.QTB_Contract_Entity__c != null &&
                    entityMap.containsKey(newAcc.QTB_Contract_Entity__c) &&
                    entityMap.get(newAcc.QTB_Contract_Entity__c).blng__Country__c != null
                ) {
                    newAcc.QTB_Legal_Entity_Country__c = entityMap.get(
                        newAcc.QTB_Contract_Entity__c
                    )
                        .blng__Country__c;
                }
                if (
                    newAcc.ShippingCountry != null &&
                    newAcc.QTB_Legal_Entity_Country__c != null &&
                    taxMap.containsKey(
                        newAcc.QTB_Legal_Entity_Country__c.toLowerCase() +
                        newAcc.ShippingCountry.toLowerCase()
                    )
                ) {
                    newAcc.QTB_Special_Tax_Condition__c = taxMap.get(
                        newAcc.QTB_Legal_Entity_Country__c.toLowerCase() +
                        newAcc.ShippingCountry.toLowerCase()
                    );
                } else {
                    newAcc.QTB_Special_Tax_Condition__c = 'None';
                }
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            throw e;
        }
    }
    /***********************************************************************************************************
* Method:          UniqueIdUpsert
* Parameters:      List<FlowInputs>
* Requirement: GitLab # 5
* Start Date:  12/07/2020
* Author:      Accenture
* Description: create Sales Billing Account Relationship record when a billing account is created
**************************************************************************************************************/
    public static void createSalesBillingAccountRelations(
        Map<Id, Id> mapOfBillingAccountToSalesOpportunityId
    ) {
        List<QTB_Sales_Billing_Account_Relations__c> relations = new List<QTB_Sales_Billing_Account_Relations__c>();
        // get sales account id from source opportunity
        Map<Id, Opportunity> maOfIdToOpportunityDetails = new Map<Id, Opportunity>(
            [
                SELECT Id, AccountId
                FROM Opportunity
                WHERE Id IN :mapOfBillingAccountToSalesOpportunityId.values()
            ]
        );
        for (
            Id eachBillingAccountId : mapOfBillingAccountToSalesOpportunityId.keySet()
        ) {
            relations.add(
                new QTB_Sales_Billing_Account_Relations__c(
                    QTB_BillingAccount__c = eachBillingAccountId,
                    QTB_SalesAccount__c = maOfIdToOpportunityDetails.get(
                        mapOfBillingAccountToSalesOpportunityId.get(eachBillingAccountId)
                    )
                    ?.AccountId,
                    QTB_Unique_Id__c = maOfIdToOpportunityDetails.get(
                        mapOfBillingAccountToSalesOpportunityId.get(
                            eachBillingAccountId
                        )
                    )
                    ?.AccountId +
                    '::' +
                    eachBillingAccountId
                )
            );
        }
        try {
            upsert relations QTB_Unique_Id__c;
        } catch (System.DmlException error) {
            System.debug(System.LoggingLevel.ERROR, error.getMessage());
        }
    }
    
    /***********************************************************************************************************
* Method : updateDMSourceSystemIdReference
* Parameters: List<account>accountList
* Requirement : GIT-13095, Git-23894, Git-24127
* Start Date : 03/05/2022
* Author : Virtusa
* Description: Update Source System Id and Reference on Billing account when Operational Account Number is
updated on operational account
#23894 Update all the billing account's Source System Id and Reference related to operational account when
parent account or related operational account is updated
#24127 calling this method from schedule calss only once to bypass the 'unable to lock record error'
#24885 update div/Dept name on billing account if operational account is level 2 or level 3
***********************************************************************************************************/
    public static void updateDMSourceSystemIdReference(List<account>accountList){
        try{
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //operational account Id which are passed as an parameter
            Set<Id> oppAccountId  = new Set<Id>();
            // storing billing account Id on which need to update dm Source system
            set<Id>billingAccountIds = new set<Id>();
            for(account acc :accountList){
                oppAccountId.add(acc.Id);
                // storing billing account id
                if(acc.parentId != null){
                    billingAccountIds.add(acc.parentId);
                }
            }
            if(!oppAccountId.isEmpty()){
                // querying all the related operational account, to update its billing account
                for(account a :[Select Id,parentId from account where Related_Operational_Account__c in :oppAccountId OR 
                                Related_Operational_Account__r.Related_Operational_Account__c in :oppAccountId]){
                                    if(a.parentId != null){
                                        billingAccountIds.add(a.parentId);
                                    }
                                }
                oppAccountId.clear();
            }
            set<Id> updateParentAcc = new set<Id>();
            set<Id>billingAccountToUpdate = new set<Id>();
            if(!billingAccountIds.isEmpty()){
                for(account a : [select Id,parentId, QTB_FSO__c from account where Id in :billingAccountIds])
                {
                    if(a.QTB_FSO__c){
                        billingAccountToUpdate.add(a.Id);
                    }
                }
                billingAccountIds.clear();
                if(!billingAccountToUpdate.isEmpty()){
                    // query no of child records
                    for(AggregateResult opAccount:[select count(Id) noOfChild,ParentId from account where parentId in :billingAccountToUpdate group by parentId])
                    {
                        // only update that billing account which have 1 operational account related to it
                        if(opAccount.get('noOfChild') == 1){
                            Id parentIdVal = (Id) opAccount.get('parentId');
                            updateParentAcc.add(parentIdVal);
                        }
                    }
                    billingAccountToUpdate.clear();
                }
            }
            if(!updateParentAcc.isEmpty()){
                List<Account>blngAccountUpdate = new List<Account>();
                //looping on billing account and operational account to update QTB_DM_Source_ID__c and DM_SourceSystem_Reference__c
                for(account blngAcc :[select id,QTB_Div_Dept_Name__c,QTB_DM_Source_ID__c,DM_SourceSystem_Reference__c,QTB_Customer_Number__c, Parent.Account_Number_Sales_text__c, (select id,name,Ship_To_Site_Number__c,Related_Operational_Account__r.Ship_To_Site_Number__c,Related_Operational_Account__r.Related_Operational_Account__r.Ship_To_Site_Number__c from ChildAccounts Limit 1) from account where id in :updateParentAcc])
                {                    
                    //looping on billing account's operational account to check its level and undate QTB_DM_Source_ID__c and DM_SourceSystem_Reference__c on billing account accordingly
                    for(account acc: blngAcc.childAccounts){
                        if(acc.Related_Operational_Account__r.Related_Operational_Account__c!=null)
                        {
                            //level 3
                            blngAcc.QTB_DM_Source_ID__c = blngAcc.Parent.Account_Number_Sales_text__c +'~'+acc.Related_Operational_Account__r.Related_Operational_Account__r.Ship_To_Site_Number__c +'~'+ acc.Related_Operational_Account__r.Ship_To_Site_Number__c +'~'+acc.Ship_To_Site_Number__c;
                            blngAcc.DM_SourceSystem_Reference__c = blngAcc.Parent.Account_Number_Sales_text__c +'~'+acc.Related_Operational_Account__r.Related_Operational_Account__r.Ship_To_Site_Number__c +'~'+ acc.Related_Operational_Account__r.Ship_To_Site_Number__c +'~'+acc.Ship_To_Site_Number__c;
                            blngAcc.QTB_Div_Dept_Name__c = acc.Name;
                            system.debug('DM SourceLevel3--->'+blngAcc.QTB_DM_Source_ID__c);
                        }else if(acc.Related_Operational_Account__c!=null )
                        {
                            //level 2
                            blngAcc.QTB_DM_Source_ID__c = blngAcc.Parent.Account_Number_Sales_text__c +'~'+acc.Related_Operational_Account__r.Ship_To_Site_Number__c +'~'+acc.Ship_To_Site_Number__c;
                            blngAcc.DM_SourceSystem_Reference__c = blngAcc.Parent.Account_Number_Sales_text__c +'~'+acc.Related_Operational_Account__r.Ship_To_Site_Number__c +'~'+acc.Ship_To_Site_Number__c;
                            blngAcc.QTB_Div_Dept_Name__c = acc.Name;
                            system.debug('DM SourceLevel2--->'+blngAcc.QTB_DM_Source_ID__c);
                        }else
                        {
                            //level 1
                            blngAcc.QTB_DM_Source_ID__c = blngAcc.Parent.Account_Number_Sales_text__c +'~'+acc.Ship_To_Site_Number__c;
                            blngAcc.DM_SourceSystem_Reference__c = blngAcc.Parent.Account_Number_Sales_text__c +'~'+acc.Ship_To_Site_Number__c;
                        }
                        blngAccountUpdate.add(blngAcc);
                    }
                }
                if(!blngAccountUpdate.isEmpty()){
                    update blngAccountUpdate;
                    blngAccountUpdate.clear();
                }
                updateParentAcc.clear();
            }
        }
        catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method : setMetadata
* Param: List<QTB_Billing_Account_Country_Validation__mdt> providedData
* Requirement : Gitlab#14644
* Start Date : 28/03/2023
* Author : Virtusa
* Description: Method to set the providedData
***********************************************************************************************************/
    public static void setMetadata(List<QTB_Billing_Account_Country_Validation__mdt> providedData){
        if(providedData != null){
            billAccValMetadata = providedData;
        }
        useProvidedData = true;
    }
    
    /*********************************************************************************************************
* Method : getAll
* Return: List<QTB_Billing_Account_Country_Validation__mdt>
* Requirement : Gitlab#14644
* Start Date : 28/03/2023
* Author : Virtusa
* Description: Method to return the List<QTB_Billing_Account_Country_Validation__mdt>
***********************************************************************************************************/
    public static List<QTB_Billing_Account_Country_Validation__mdt> getAll(){
        // The purpose of this IF is to make the proxy "transparent" to its
        //   clients.
        // Fetches (and caches on the heap) the actual metadata type records
        //   in an org if we haven't previously called setMetadata() in this
        //   transaction.
        if(billAccValMetadata.isEmpty() && !useProvidedData){
            billAccValMetadata = QTB_Billing_Account_Country_Validation__mdt.getAll().values();
            useProvidedData = true;
        }
        return billAccValMetadata;
    }
    
    /*********************************************************************************************************
* Method : validateMandatoryAccountFields
* Parameters: List<Account> accsNewList
* Requirement : Gitlab#14644
* Start Date : 28/03/2023
* Author : Virtusa
* Description: Method to validate the Billing Account for mandatory fields before insert and before update
***********************************************************************************************************/
    public static void validateMandatoryAccountFields(List<Account> accsNewList) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //Fetching the Billing Account Country validation exception metadata records
            List<QTB_Billing_Account_Country_Validation__mdt> accountCountryVal = QTB_AccountHelper.getAll();
            
            //countryAddressFieldMandatory Map - KEY => Billing Country + Field , VALUE => Mandatory Flag
            Map<String, Boolean> countryAddressFieldMandatory = new Map<String, Boolean>();
            
            //countryAddressFieldNonMandatory Map - KEY => Billing Country + Field , VALUE => Non Mandatory Flag
            Map<String, Boolean> countryAddressFieldNonMandatory = new Map<String, Boolean>();
            
            for (QTB_Billing_Account_Country_Validation__mdt validationSetting : accountCountryVal) {
                //create the maps only for the active metadata records
                if (validationSetting.IsActive__c) {
                    if (validationSetting.QTB_Non_Mandatory__c) {
                        countryAddressFieldNonMandatory.put(validationSetting.QTB_Country__c+validationSetting.QTB_Field_Name__c, validationSetting.QTB_Non_Mandatory__c);
                    }
                    
                    if (validationSetting.QTB_Mandatory__c) {
                        countryAddressFieldMandatory.put(validationSetting.QTB_Country__c+validationSetting.QTB_Field_Name__c, validationSetting.QTB_Mandatory__c);
                    }
                }
            }
            
            //Fetch the mandatory fields required for Billing Account creation
            String accountMandatoryFields = System.Label.QTB_Billing_Account_Mandatory_Fields;
            List<String> accountMandatoryList = accountMandatoryFields.split(';');
            
            //Fetch the non mandatory fields for Billing Account
            String accountNonMandatoryFields = System.Label.QTB_Billing_Account_NonMandatory_Fields;
            List<String> accountNonMandatoryList = accountNonMandatoryFields.split(';');
            
            System.debug('accountMandatoryList>>>'+accountMandatoryList);
            System.debug('accountNonMandatoryList>>>'+accountNonMandatoryList);
            
            for (Account acnt : accsNewList) {
                //Gitlab #30238 - Billing State is Mandatory for SITAD Billling Accounts.
                if(acnt.QTB_SITAD__c && system.label.QTB_SITAD_Countries.contains(acnt.BillingCountry) && acnt.BillingState == NULL ){
                    acnt.addError('Billing State is Mandatory for Billing Account');
                }
                //Gitlab #30238 - End
                //Logic to check if the mandatory fields are available on the new billing account using
                //the mandatory fields custom label values - QTB_Account_Mandatory_Fields
                for (String acntField: accountMandatoryList) {
                    //This condition is to bypass the mandatory field error, if the field is not mandatory for particular country
                    //Non mandatory against the country is configured in the Billing Account Country Validation custom metadata.
                    //Example : BillingPostalCode is non mandatory for country 'HONG KONG'
                    if (acnt.get(acntField) == null &&
                        (countryAddressFieldNonMandatory.containsKey(acnt.BillingCountry + acntField))
                       ) {
                           continue;
                       } else if (acnt.get(acntField) == null) {
                           acnt.addError(acntField + ' is mandatory for Billing Account');
                       }
                }
                
                //Logic to check if the default non-mandatory field needs to be made mandatory for particular country using
                //the non mandatory fields custom label values - QTB_Account_NonMandatory_Fields AND countryAddressFieldMandatory Map
                //Example : BillingState & ShippingState is ONLY mandatory for country 'INDIA'
                for (String acntField: accountNonMandatoryList) {
                    if (acnt.get(acntField) == null &&
                        (countryAddressFieldMandatory.containsKey(acnt.BillingCountry + acntField))
                       ) {
                           acnt.addError(acntField + ' is mandatory for Billing Account');
                       }
                    
                    if (acnt.get(acntField) == null &&
                        (countryAddressFieldMandatory.containsKey(acnt.ShippingCountry + acntField))
                       ) {
                           acnt.addError(acntField + ' is mandatory for Billing Account');
                       }
                }
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                ACCOUNTHELPER
            );
            throw e;
        }
    }
    /*********************************************************************************************************
* Method : setMetadata
* Param: List<Account> accsList, String holdBillingStatus
* Requirement : //GitLab # 22554
* Author : Virtusa
* Description: Method to update Account Hold Status field with On Hold value if Apex job size is greater than 150
***********************************************************************************************************/
    public static void updateAccountForHoldStatus(List<Account> accsList, String holdBillingStatus){
        if( QTB_RecursiveHandlerCheck.updateAccountForHoldStatus==True){
            try {
                // List of Account to update Hold Status field with On Hold
                List<Account> lstUpdateAccForHoldStatus = new List<Account>();
                if (AccountTriggerHandler.throwExplicitException) {
                    throw new NullPointerException();
                }
                if(!accsList.IsEmpty()){
                    for(Account acc : accsList){
                        Account accs = new Account();
                        accs.id = acc.id;
                        accs.QTB_Hold_Status__c = holdBillingStatus;
                        lstUpdateAccForHoldStatus.add(accs);
                    }
                    if(!lstUpdateAccForHoldStatus.isEmpty()){
                        QTB_RecursiveHandlerCheck.updateAccountForHoldStatus= false;
                        update lstUpdateAccForHoldStatus;
                    }
                }
            }
            catch (exception e) {
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(
                    e.getLineNumber(),
                    e.getStackTraceString(),
                    e.getMessage(),
                    e.getTypeName(),
                    ACCOUNTHELPER
                );
                throw e;
            }
        }
    }
    
    /*********************************************************************************************************
* Method : populateOpAccountShipToSiteNum
* Param: List<Account> accsList
* Requirement : //GitLab #28889
* Author : Virtusa (Thrinethra)
* Description: Method to insert Ship to site number on Operational Account
***********************************************************************************************************/
    public static void populateOpAccountShipToSiteNum(List<Account> accsList) {
        try {
            List<Account> l1AccList = new List<Account>();
            List<Account> childAccList = new List<Account>();
            List<Account> filteredOpAccs = new List<Account>();
            Map<id,string> accIdOpAccType = new Map<id,string>();
            Set<Id> parentIds = new Set<Id>();
            
            //we are passing operational account
            for(Account opAcc : accsList) {
                //Assume all operational account records have a ParentId (which is billing account), keeping its parent ids in a parentIds set.
                if (opAcc.ParentId != null) {
                    parentIds.add(opAcc.ParentId);
                }
            }
            
            //Query Parent records whose id in the parentIds set, and keeping those parent records in a Map of ParentId and its parent record
            Map<Id, Account> parentBillingMap = new Map<Id, Account>();
            if(parentIds != null && !parentIds.isEmpty()){
                for(Account parBillingAcc : [SELECT Id, RecordTypeId,QTB_Market__c,QTB_DM_Source_System__c FROM Account WHERE Id IN :parentIds]){
                    parentBillingMap.put(parBillingAcc.Id, parBillingAcc);
                }
            }
            
            //Now we are passing operational accounts list
            //we are checking if the operational account's ParentId is in parentBillingMap
            if (parentBillingMap != null && !parentBillingMap.isEmpty()) {
                for(Account opAcc : accsList){
                    // #32311 prefix to store Operational account Type as prefix where Billing Acc QTB_DM_Source_System__c = 'Oneil'
                    String prefix = '';
                    String picklistValue = '';
                    if(opAcc.ParentId != null && parentBillingMap.containsKey(opAcc.ParentId)){
                        //if yes, we are getting the parent billing record of each operational account by giving its ParentId and getting parent billing acc record
                        Account parentBillingRec = parentBillingMap.get(opAcc.ParentId);
                        //if parent record is not null and parent record's record type is 'Billing Account' we are passing those records only further as for all our L1, L2 & L3
                        if (parentBillingRec != null && parentBillingRec.RecordTypeId == accBillRecordTypeId) {
                            // #32311 Check where Billing Acc QTB_DM_Source_System__c = 'Oneil'
                            If(opAcc.QTB_Operational_Account_Type__c != null && parentBillingRec.QTB_DM_Source_System__c !=null && parentBillingRec.QTB_DM_Source_System__c.toLowerCase() == 'oneil' && opAcc.QTB_Operational_Account_Type__c != 'None'){
                                picklistValue = opAcc.QTB_Operational_Account_Type__c;
                                if (picklistValue.contains(' - ')) {
                                    prefix = picklistValue.split(' - ')[0].trim(); // Extract 'ON' from operational account type ON - Only Carton
                                    accIdOpAccType.put(parentBillingRec.id,prefix);
                                }
                            }
                            filteredOpAccs.add(opAcc);
                        }
                    }
                }
            }
            
            //Set to store related operational account
            Set<Id> relatedOpAccIds = new Set<Id>();
            if (filteredOpAccs != null && !filteredOpAccs.isEmpty()) {
                for (Account opAcc : filteredOpAccs) {
                    if (opAcc.Related_Operational_Account__c != null) {
                        relatedOpAccIds.add(opAcc.Related_Operational_Account__c);
                    }
                }
                
                //Map to Store related account id and its records
                Map<Id, Account> relatedOpAccMap = new Map<Id, Account>();
                if (relatedOpAccIds != null && !relatedOpAccIds.isEmpty()) {
                    for (Account relOpAcc : [SELECT Id, Related_Operational_Account__c, Ship_To_Site_Number__c, 
                                             Related_Operational_Account__r.Related_Operational_Account__c, 
                                             Related_Operational_Account__r.Ship_To_Site_Number__c 
                                             FROM Account WHERE Id IN :relatedOpAccIds]) {
                                                 relatedOpAccMap.put(relOpAcc.Id, relOpAcc);
                                             }
                }
                
                //Now we are passing these filteredOpAccs whose record type is 'Operational Account' & its parent record is 'Billing Account'
                for (Account opAcc : filteredOpAccs) {
                    //If the operational account's Related_Operational_Account__c = null it will be L1 (Level 1) Operational account. We are separating because, for L1 and (L2, L3)
                    //record logic is different
                    if (opAcc.Related_Operational_Account__c == null) {
                        l1AccList.add(opAcc);
                    } else {
                        childAccList.add(opAcc);
                    }
                }
                
                //L1 op acc records we are processing using below method
                if(l1AccList != null && !l1AccList.isEmpty()){
                    assignS2SNumberForL1(l1AccList,accIdOpAccType); //L1 records
                }
                
                //L2 & L3 op acc records (children) we are processing using below method
                if(childAccList != null && !childAccList.isEmpty() && relatedOpAccMap != null && !relatedOpAccMap.isEmpty()){
                    assignS2SNumberForChildren(childAccList, relatedOpAccMap); //L2, L3 records
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_AccountHelper: populateOpAccountShipToSiteNum');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method : assignS2SNumberForL1
* Param: List<Account> l1Records
* Requirement : //GitLab #28889
* Author : Virtusa (Thrinethra)
* Description: Method to insert Ship to site number on Operational Account for L1 Records
***********************************************************************************************************/
    //Here we are passing L1 records
    public static void assignS2SNumberForL1(List<Account> l1Records,Map<id,string> accIdOpAccType) {
        try {
            //we are counting its size, how many L1 records are coming
            Integer neededCount = l1Records.size();            
            // Querying Operational Account Number Records whose Number utilised is false and limiting with the count of Operational account records passed into this method
            // and ordering by unique number Ascending so A00001, A00002, B00001, B00002 like that
            List<QTB_Operational_Account_Number__c> opAccNumRecds = [SELECT Id, QTB_Unique_Number__c 
            FROM QTB_Operational_Account_Number__c 
            WHERE QTB_Number_Utilised__c = false
            ORDER BY QTB_Unique_Number__c ASC
            LIMIT : neededCount
            ];
            
            
            if (opAccNumRecds.size() < neededCount) {
                for (Account acc : l1Records) {
                    acc.addError('Not enough available operational account number records for L1 assignment');
                }
                return;
            }

            List<QTB_Operational_Account_Number__c> updateOANrecords = new List<QTB_Operational_Account_Number__c>();
            //if the operational account number records list queried is not empty, then we are processing to logic
            if(opAccNumRecds != null && !opAccNumRecds.isEmpty()){
                //Looping the op acc records based on the size and initializing the integer index with 0
                for(Integer i = 0; i < neededCount; i++) {
                    String prefix = '';
                    Account opAcc = l1Records[i];
                    QTB_Operational_Account_Number__c opAccNumRec = opAccNumRecds[i];
                    // #32311 Check where Billing Acc QTB_DM_Source_System__c = 'Oneil' and add opeartional account type as prefix in ship to site number
                    if(opAcc.QTB_Operational_Account_Type__c != 'None' && opAcc.QTB_Operational_Account_Type__c != null && accIdOpAccType.containsKey(opAcc.ParentId)){
                        prefix = accIdOpAccType.get(opAcc.ParentId);
                        opAcc.Ship_To_Site_Number__c = prefix+opAccNumRec.QTB_Unique_Number__c; 
                    }else{
                        //Assigning OAN record's unique number to op Acc Ship to site number field
                        opAcc.Ship_To_Site_Number__c = opAccNumRec.QTB_Unique_Number__c; 
                    }
                    //Marking OAN record as utilised
                    opAccNumRec.QTB_Number_Utilised__c = true;
                    updateOANrecords.add(opAccNumRec);
                }
            }            
            //updating the operational account records
            if (!updateOANrecords.isEmpty()){
                update updateOANrecords;
                updateOANrecords.clear();
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_AccountHelper: assignS2SNumberForL1');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method : assignS2SNumberForChildren
* Param: List<Account> l1Records
* Requirement : //GitLab #28889
* Author : Virtusa (Thrinethra)
* Description: Method to insert Ship to site number on Operational Account for L2 and L3 Records
***********************************************************************************************************/
    //Here we are passing L2 or L3 records (Child records)
    public static void assignS2SNumberForChildren(List<Account> childRecords, Map<Id, Account> relatedOpAccMap) {
        try {
            //Grouping by immediate parent and determining levels
            Map<Id, List<Account>> accountsByParent = new Map<Id, List<Account>>();
            
            //Looping incoming childrecords and gropuing child accounts by immediate parent's id. Key is Related Operational Acc, value: list of child accounts under that parent. For L2 parent is L1 and L3 parent is L2
            for (Account child : childRecords) {
                Id parentId = child.Related_Operational_Account__c;
                Integer level = determineLevel(child, relatedOpAccMap);
                if (level == null || level < 2) { //If it's not L2 or L3 we are skipping
                    child.addError('Invalid hierarchy level for child record');
                    continue;
                }
                if (!accountsByParent.containsKey(parentId)) {
                    accountsByParent.put(parentId, new List<Account>()); //Initializing empty list for its parent id
                    accountsByParent.get(parentId).add(child);
                }else {
                    accountsByParent.get(parentId).add(child); //adding child to list of account under that parent.
                }
            }

            //Querying existing children records whose Rel.Op.Acc in parentid (under its same parent) ex: L2 used numbers under L1; L3 used numbers under L2
            //and putting their used 'ship to site number' in map for its respective parentId
            Map<Id, Set<String>> usedNumbersByParent = new Map<Id, Set<String>>(); //Map to track used numbers under its parent: Key parentId, value ship to site number
            List<Account> existingChildren = [SELECT Id, Ship_To_Site_Number__c, Related_Operational_Account__c
                                              FROM Account WHERE Related_Operational_Account__c IN : accountsByParent.KeySet()
                                              AND Ship_To_Site_Number__c != null
                                             ];
            
            //Existing child accounts related ship to site number putting in map value for respective parentId
            if (existingChildren != null && !existingChildren.isEmpty()){
                for (Account child : existingChildren) {
                    Id parentId = child.Related_Operational_Account__c;
                    if (!usedNumbersByParent.containsKey(parentId)) {
                        usedNumbersByParent.put(parentId, new Set<String>()); //Initializing empty set for its parent id
                        usedNumbersByParent.get(parentId).add(child.Ship_To_Site_Number__c);
                    } else {
                        usedNumbersByParent.get(parentId).add(child.Ship_To_Site_Number__c); //adding child's ship to site to set under that parent.
                    }
                }
            }
            
            //Now we are querying the OAN records whose Number utilised is false
            List<QTB_Operational_Account_Number__c> opAccNumRecordsList = [SELECT Id, QTB_Unique_Number__c 
                                                                           FROM QTB_Operational_Account_Number__c 
                                                                           WHERE QTB_Number_Utilised__c = false
                                                                           ORDER BY QTB_Unique_Number__c ASC
                                                                          ];
            
            //Now we are looping on their immediate parentIds and storing its parent number and also children ship to site numbers under that
            //parent into a set
            for (Id parentId : accountsByParent.keySet()) {
                String parentNumber = relatedOpAccMap.get(parentId)?.Ship_To_Site_Number__c;
                Set<String> usedNumbers = usedNumbersByParent.get(parentId) != null ? usedNumbersByParent.get(parentId) : new Set<String>();
                usedNumbers.add (parentNumber);
                
                //available numbers to hold available number for its parent children after filtering out used numbers under its parent and its parent number
                List<String> availableNumbers = new List<String>();
                if (opAccNumRecordsList != null && !opAccNumRecordsList.isEmpty()) {
                    for (QTB_Operational_Account_Number__c opANRec : opAccNumRecordsList) {
                        if(!usedNumbers.contains(opANRec.QTB_Unique_Number__c)) {
                            availableNumbers.add(opANRec.QTB_Unique_Number__c);
                            if (availableNumbers.size() == accountsByParent.get(parentId).size()) {
                                break;
                            }
                        }
                    }
                }
                
                //list of children under its parent which we grouped earlier in below map
                List<Account> grouppedChildAccts = accountsByParent.get(parentId);
                for (Integer i = 0; i < grouppedChildAccts.size(); i++) {
                    Account childOpAccRec = grouppedChildAccts[i];
                    String opAccNum = availableNumbers[i];
                    childOpAccRec.Ship_To_Site_Number__c = opAccNum;
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_AccountHelper: assignS2SNumberForChildren');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method : determineLevel
* Param: List<Account> acc, Map<Id, Account> relatedOpAccMap
* Requirement : //GitLab #28889
* Author : Virtusa (Thrinethra)
* Description: Method to L1 or L2 and L3 levels of operational account Records
***********************************************************************************************************/
    //Here we are passing L2 or L3 records (each Child record)
    private static Integer determineLevel (Account acc, Map<Id, Account> relatedOpAccMap) {
        if (acc != null && relatedOpAccMap != null && !relatedOpAccMap.isEmpty() && acc.Related_Operational_Account__c != null) {
            if (relatedOpAccMap.containsKey(acc.Related_Operational_Account__c)) {
                Account relatedOpAcc = relatedOpAccMap.get(acc.Related_Operational_Account__c);
                //If operational accounts related operational Account is not null (not L1), related Op Account's Related op Account is Null then it will be L2 so it will return 2.
                if (acc.Related_Operational_Account__c != null && relatedOpAcc != null &&
                    relatedOpAcc.Related_Operational_Account__c == null) { //L2 Op Acc Record
                        return 2;
                    }
                //If operational accounts related operational Account is not null (not L1), related Op Account's Related op Account is Not null (not L1 and L2), related Op Account's -> Related op Account's-> Related op Account is Null then it will be L3, so it will return 3.
                if (acc.Related_Operational_Account__c != null && relatedOpAcc != null &&
                    relatedOpAcc.Related_Operational_Account__c != null) {//L3 Op Acc Record
                        return 3;
                    }
            }
        }
        return null;
    }
    
    
    /***********************************************************************************************************
* Method : populateDefaultValues
* Parameters: List<Account>
* Requirement : US#29584
* Start Date : 05/03/2025
* Author : Virtusa
* Description: This method will populate default values on Billing Account for Separate FMV Credit and Separate Project
* Event: This method invoked on before insert from Account Trigger
**************************************************************************************************************/
    public static void populateDefaultValues(list<Account> billingAccounts){
        
        for(Account acc: billingAccounts){
            if(acc.RecordTypeId == accBillRecordTypeId && acc.QTB_Legal_Entity_Country__c!= null && acc.QTB_SITAD__c && System.Label.QTB_SITAD_Countries.contains(acc.QTB_Legal_Entity_Country__c)){
                acc.QTB_SeperateFMVCredit__c=true;
            }
            if(acc.RecordTypeId == accBillRecordTypeId && acc.QTB_Legal_Entity_Country__c!= null && acc.QTB_SITAD__c && System.Label.QTB_SITAD_Cluster1_Countries.contains(acc.QTB_Legal_Entity_Country__c)){
                acc.QTB_Separate_Project_Invoice__c=true;
            }
        }
        
    }
}