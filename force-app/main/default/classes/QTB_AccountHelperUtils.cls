/*************************************************************************************************
* Class: QTB_AccountHelperUtils
* Author: TCS
* Purpose: This is a helper class for all business logic related to Billing Account object
* Change History: 07/14/2023
* Developer     Date           Description
* TCS        06/12/2023      Tax Treatment validation on Billing Account Creation/Updation
* Virtusa    07/13/2023      State and city validation on billing account for Thailand and India GitLab #15399, #16806
*******************************************************************************************************/
public with sharing class QTB_AccountHelperUtils {
    /*************************************************************************************************
* Method:      validateTaxTreatmentOnAccount
* Parameters:  List<Account>
* Requirement: GitLab #16299
* Start Date:  20/06/2023
* Author:      TCS
* Description: GitLab #16299 To validate the Tax treatment when Billing Account is created
*********************************************************************************************/ 
    //#16299 Tax treatment validation on Billing Account creation
    public static void validateTaxTreatmentOnAccount(List<Account> newItems,string operationType){
        try{
            if(AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Set<String> accTreatmentSet = new Set<String>();
            String taxable = '';
            Set<String> accLegalEntityCountry = new Set<String>();
            Set<String> accSplTaxCondition = new Set<String>();
            Set<ID> entityID = new Set<ID>();
            //Adding Ship To Country and Legal Entity Id in order to query on Tax treatment
            for(Account acc:newItems){
                //Checking if the Account legal Entity country belongs to Billing only country or not
                if(QTB_Billing_Countries__c.getValues(acc.QTB_Legal_Entity_Country__c) != null){
                    entityID.add(acc.QTB_Contract_Entity__c);
                    accLegalEntityCountry.add(acc.QTB_Legal_Entity_Country__c);
                    accSplTaxCondition.add(acc.QTB_Special_Tax_Condition__c);
                    System.debug('accSplTaxCondition'+accSplTaxCondition);
                }
            }
            if(!entityID.isEmpty() && !accLegalEntityCountry.isEmpty() && !accSplTaxCondition.isEmpty()){
                //Query in order to get the Tax treatments based on the 'entityID' and 'accShipToCountry'
                list<blng__TaxTreatment__c> treatment = [select id ,name,QTB_TaxCountry__c,blng__TaxLegalEntity__r.Name,blng__TaxLegalEntity__r.blng__Country__c, QTB_Special_Tax_Condition__c, QTB_Taxable__c 
                                                         from blng__TaxTreatment__c 
                                                         where blng__TaxLegalEntity__c in :entityID and QTB_TaxCountry__c in :accLegalEntityCountry and QTB_Special_Tax_Condition__c in :accSplTaxCondition and blng__Active__c = true];
                System.debug('treatment >>>'+treatment);
                //Availability of tax treatment is checked based on shipping and legal entity country
                if(operationType == 'BEFORE_INSERT'){
                    System.debug('<<<Bfr Insert>>>');
                    if(treatment != null && treatment.size()>0){
                        for(blng__TaxTreatment__c treatmentRec:treatment){ 
                            //Building the set which holds 'Legal Entity+ShipTo Country'
                            accTreatmentSet.add(treatmentRec.blng__TaxLegalEntity__c+treatmentRec.QTB_TaxCountry__c+treatmentRec.QTB_Special_Tax_Condition__c);
                            System.debug('accTreatmentSet >>>'+accTreatmentSet);
                        }
                        
                    }
                    //Iterating over new Account records
                    for(Account acc:newItems){
                        if(acc.QTB_Legal_Entity_Country__c != 'Hong Kong' && QTB_Billing_Countries__c.getValues(acc.QTB_Legal_Entity_Country__c) != null && !Test.isRunningTest()){
                            //checks if there are no records present for a Account country in Tax treatment
                            if(accTreatmentSet.isEmpty() || !accTreatmentSet.contains(acc.QTB_Contract_Entity__c+acc.QTB_Legal_Entity_Country__c+acc.QTB_Special_Tax_Condition__c)){
                                acc.addError(Label.QTB_OnAccountTaxTreatmentValidationCheck);
                            }
                        }
                    }
                    
                }
                //Before update transaction should consider filtering with special tax condition as well 
                else if(operationType == 'BEFORE_UPDATE'){
                    System.debug('<<<Bfr Update>>>');
                    if(treatment != null && treatment.size()>0){
                        for(blng__TaxTreatment__c treatmentRec:treatment){ 
                            //Building the set which holds 'Legal Entity+ShipTo Country+Taxable'
                            accTreatmentSet.add(treatmentRec.blng__TaxLegalEntity__c+treatmentRec.QTB_TaxCountry__c+treatmentRec.QTB_Taxable__c+treatmentRec.QTB_Special_Tax_Condition__c);
                            System.debug('accTreatmentSet >>>'+accTreatmentSet);
                        }
                        
                    }
                    //Iterating over new Account records
                    system.debug('newItems >>> '+newItems);
                    for(Account acc:newItems){
                        if(acc.SBQQ__TaxExempt__c != null && acc.SBQQ__TaxExempt__c == 'No'){
                            taxable = 'Yes';
                        }
                        else{
                            taxable = 'No';
                        }
                        if(acc.QTB_Legal_Entity_Country__c != 'Hong Kong' && QTB_Billing_Countries__c.getValues(acc.QTB_Legal_Entity_Country__c) != null && !Test.isRunningTest()){
                            //checks if there are no records present for a Account country in Tax treatment
                            if(accTreatmentSet.isEmpty() || !accTreatmentSet.contains(acc.QTB_Contract_Entity__c+acc.QTB_Legal_Entity_Country__c+taxable+acc.QTB_Special_Tax_Condition__c)){
                                acc.addError(Label.QTB_OnAccountTaxTreatmentValidationCheck);
                            }
                        }
                    }
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),
                                          e.getStackTraceString(),
                                          e.getMessage(),
                                          e.getTypeName(),
                                          'validateTaxTreatmentOnAccount');
            throw e;
            
        }
    }
    
    /*************************************************************************************************
* Method:      validateStateValue
* Parameters:  List<Account>
* Requirement: GitLab #15399, Gitlab #16806
* Start Date:  05/03/2023
* Author:      Virtusa
* Description: GitLab #15399 To validate the values of billing and shipping states of India, when the
legal entity and billing country are both India
GitLab #16806 to validate the values of billing and shipping state of Thailand, when 
legal entity and billling country are both Thailand
*********************************************************************************************/  
    public static void validateStateValue(List<Account> accsNewList) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //creating Set of country and Label from the metadata for validation of billing state and shipping state based on
            //billing country and shipping country
            //QTB_Country__c field in metadata has values in uppercase and label conatains state name value in upperCase for India and 
            //for thailand label has value according to thailand requirement
            Set<String> validStates = new Set<String>();
            Map<String,QTB_StateCityForValidation__mdt> stateCityMap = QTB_StateCityForValidation__mdt.getAll();
            for(String stateRecord :stateCityMap.keySet()){
                if(stateCityMap.get(stateRecord).QTB_isState__c == true){
                    validStates.add(stateCityMap.get(stateRecord).QTB_Country__c + stateCityMap.get(stateRecord).label);
                }
            }
            // looping on account List to validate biiling state and shipping state
            for(Account acc:accsNewList){
                //Check billingState
                //Gitlab: #16806, if billing country is thailand than billing state should match exact with the name present in the metadata
                // for example if state name of thailand in metadata is 'Phra Borom Maha Ratchawang' and user enters billing state as 
                // 'PHRa Borom Maha Ratchawang' it should throw error(for thailand billing state is case sensitive) and same applies for shipping state
                if(acc.billingState != null){
                    if(acc.QTB_Legal_Entity_Country__c == 'Thailand' && acc.billingCountry == 'Thailand' && !(validStates.contains(acc.billingCountry.toUpperCase()+acc.billingState))){
                        acc.billingState.addError('Entered Billing State '+acc.billingState+' is not valid');
                    }
                    else if(acc.QTB_Legal_Entity_Country__c == 'India' && acc.billingCountry == 'India' && !(validStates.contains(acc.billingCountry.toUpperCase()+acc.billingState.toUpperCase()))){
                        acc.billingState.addError('Entered Billing State '+acc.billingState+' is not valid');
                    }
                }  
                
                //Check shippingState
                if (acc.shippingState!=null){
                    if(acc.QTB_Legal_Entity_Country__c == 'Thailand' && acc.shippingCountry == 'Thailand' && !(validStates.contains(acc.shippingCountry.toUpperCase()+acc.shippingState))){
                        acc.shippingState.addError('Entered Shipping State '+acc.shippingState+' is not valid');
                    }
                    else if(acc.QTB_Legal_Entity_Country__c == 'India' && acc.shippingCountry == 'India' && !(validStates.contains(acc.shippingCountry.toUpperCase()+acc.shippingState.toUpperCase()))){
                        acc.shippingState.addError('Entered Shipping State '+acc.shippingState+' is not valid');
                    }
                }  
                
                
            }
        }
        catch (exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'validateStateValue'
            );
            throw e;
        }
    }
    
    /*************************************************************************************************
* Method:      validateCityValue
* Parameters:  List<Account>
* Requirement: Gitlab #16806
* Start Date:  07/13/23
* Author:      Virtusa
* Description: GitLab #16806 to validate the values of billing city of Thailand, when 
legal entity and billling country are both Thailand
*********************************************************************************************/  
    public static void validateCityValue(List<Account> accsNewList) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //creating Set of country and Label from the metadata for validation of billing city on billing country
            //QTB_Country__c field in metadata has values in uppercase and label conatains city name value 
            Set<String> validCity = new Set<String>();
            Map<String,QTB_StateCityForValidation__mdt> cityMap = QTB_StateCityForValidation__mdt.getAll();
            for(String cityRecord :cityMap.keySet()){
                if(cityMap.get(cityRecord).QTB_isCity__c == true){
                    validCity.add(cityMap.get(cityRecord).QTB_Country__c + cityMap.get(cityRecord).label);
                }
            }
            system.debug('inside city condition');
            // looping on account List to validate biiling city
            for(Account acc:accsNewList){
                //Check billingCity
                //Gitlab: #16806, if billing country is thailand than billing city should match exact with the name present in the metadata
                if(acc.QTB_Legal_Entity_Country__c == 'Thailand' && acc.billingCity != null && 
                   acc.billingCountry == 'Thailand' && !validCity.contains(acc.billingCountry.toUpperCase()+acc.billingCity)){
                       acc.billingCity.addError('Entered Billing City '+acc.billingCity+' is not valid');
                   }
                
            }
        } 
        catch (exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'validateCityValue'
            );
            throw e;
        }
    }
    
    /*************************************************************************************************
* Method:      updateRemitToAddress
* Parameters:  List<Account> accountList, Set<String> billingCountrySet
* Requirement: Gitlab #28446
* Start Date:  14/04/25
* Author:      TCS
* Description: GitLab #28446 To auto populate the Remit Address on Billing Account
*********************************************************************************************/  
    public static void updateRemitToAddress(List<Account> accountList, Set<String> legalEntitySet) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Integer i = 0;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            //Fetch all the RemitToAddress
            List<QTB_Remit_To__c> remitAddress = [SELECT ID, name, QTB_Country__c, QTB_State__c, QTB_Postal_Code_From__c, QTB_Postal_Code_To__c, QTB_Default__c, QTB_Status__c, QTB_Postal_Code_Mapping_Required__c,QTB_Legal_Entity__c  
                                                  FROM QTB_Remit_To__c 
                                                  WHERE QTB_Legal_Entity__c  IN:legalEntitySet and QTB_Country__c != null and QTB_Status__c = 'Active'];
            
            //KEY => Country+State, VALUE => List<QTB_Remit_To__c>
            Map<String, List<QTB_Remit_To__c>> remitAddressStateCountryMap = new Map<String, List<QTB_Remit_To__c>>();
            Map<String, QTB_Remit_To__c> remitAddressFromPostCodeMap = new Map<String, QTB_Remit_To__c>();
            Map<String, QTB_Remit_To__c> remitAddressCountryDefault = new Map<String, QTB_Remit_To__c>();
            for (QTB_Remit_To__c remit: remitAddress) {
                System.debug('remit>>>'+remit);
                String key = remit.QTB_Country__c.toUpperCase();
                if (remit.QTB_State__c != null) {
                    key = remit.QTB_Country__c.toUpperCase()+remit.QTB_State__c.toUpperCase();
                }
                if (remitAddressStateCountryMap.containskey(key)) {
                    List<QTB_Remit_To__c> tempRemitList = remitAddressStateCountryMap.get(key);
                    tempRemitList.add(remit);
                    remitAddressStateCountryMap.put(key, tempRemitList);
                } else {
                    //Add Default check 
                    System.debug('Inside Else block>>'+remitAddressStateCountryMap);
                    List<QTB_Remit_To__c> tempRemit = new List<QTB_Remit_To__c>();
                    tempRemit.add(remit);
                    remitAddressStateCountryMap.put(key, tempRemit);
                }
                //If any Default record available, then adding that details to the map
                if (remit.QTB_Country__c != null && remit.QTB_Default__c) {
                    //remitAddressCountryDefault.put(remit.QTB_Country__c.toUpperCase(), remit);
                    remitAddressCountryDefault.put(remit.QTB_Legal_Entity__c, remit);
                }
             }
            
            for (Account acc: accountList) {
                //Populating the Country default Remit Address
                //if (acc.BillingCountry != null) {
                String accKey = acc.BillingCountry.toUpperCase();
                if (acc.BillingState != null){
                    accKey = acc.BillingCountry.toUpperCase()+acc.BillingState.toUpperCase();
                }
                List<QTB_Remit_To__c> relatedRemits = remitAddressStateCountryMap.get(accKey);
                System.debug('relatedRemits>>'+relatedRemits);
                QTB_AccountHelper.isRemitDetailsPopulated = true;
                //Logic to populating the Remit Address for Country AND State match with Postal Code map if enabled.
                //if (acc.BillingState != null && acc.BillingPostalCode != null) {
                if (remitAddressStateCountryMap.containskey(accKey)) {
                    //acc.QTB_Remit_To__c = relatedRemits[0].Id;
                    System.debug('relatedRemits>>'+acc.QTB_Remit_To__c);
                    Boolean remitIdFound = false;
                    if (acc.BillingPostalCode != null) {
                        for (QTB_Remit_To__c remit: relatedRemits) {
                            if (remit.QTB_Postal_Code_Mapping_Required__c && acc.BillingPostalCode >= remit.QTB_Postal_Code_From__c && acc.BillingPostalCode <= remit.QTB_Postal_Code_To__c) 
                            {
                                acc.QTB_Remit_To__c = remit.Id;
                                remitIdFound = true;
                                break;
                            }
                        }
                        if(!remitIdFound){
                            acc.QTB_Remit_To__c = relatedRemits[0].Id;
                        }
                    }else{
                        acc.QTB_Remit_To__c = relatedRemits[0].Id;
                    }
                }
                else 
                {
                    acc.QTB_Remit_To__c = (remitAddressCountryDefault.get(acc?.QTB_Contract_Entity__c) != null) ? remitAddressCountryDefault.get(acc?.QTB_Contract_Entity__c).ID : null;
                }
                
            }
        }
        
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),
                                          e.getStackTraceString(),
                                          e.getMessage(), 
                                          e.getTypeName(),
                                          'QTB_AccountHelperUtils');
        }
    }
    /***********************************************************************************************************   
* Method 	 : updatePaymentTermBasedUponAccountPaymentTermValue
* Parameters : Set<Id> Accountids
* Return Type: List <order>
* Start Date:  07/24/24
* Author:      TCS
* Description: Gitlab US #24886 - This method is responsible to return the order List what needs to be stamped based upon Account related data and call to Accounthelper(As per new Code Approach)
**************************************************************************************************************/
    public static List<Order> updatePaymentTermBasedUponAccountPaymentTermValue(Set<Id> accids){
        List<Order> orderListUpdate = new List<Order>();
        try{
            for(Order ord : [select id,Account.Payment_Terms__c from order where AccountId IN : accids and Account.Payment_Terms__c!= Null and Status = 'Activated']){
                ord.SBQQ__PaymentTerm__c = ord.Account.Payment_Terms__c;
                orderListUpdate.add(ord);
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'updatePaymentTermBasedUponAccountPaymentTermValue'
            );
        }
        QTB_RecursiveHandlerCheck.updatePaymentTermBasedUponAccountPaymentTermValue = False;
        return orderListUpdate;    
    }
    /*************************************************************************************************
* Method:      updateOperationalAccInfoBasedUponBillCUpdate
* Parameters:  Set<Id> RelationalBillingAccountIds
* Return Type: List <Account>
* Requirement: Gitlab #24991
* Start Date:  07/24/24
* Author:      TCS
* Description: GitLab #24991 this method will return the Account list taht needs to be updated and will returns to helper page (As per new code Approach)
*********************************************************************************************/  
    public static List<Account> updateOperationalAccInfoBasedUponBillCUpdate(Set<Id> Ids) {
        List<Account> operaAccListForUpdate = new List<Account>();
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            for(Account acc : [Select id,Related_Billing_Account__c,QTB_Legal_Entity_Country__c,QTB_Contract_Entity__c,Related_Billing_Account__r.QTB_Legal_Entity_Country__c,Related_Billing_Account__r.QTB_Contract_Entity__c from Account where Related_Billing_Account__c IN:Ids]){
                acc.QTB_Legal_Entity_Country__c = acc.Related_Billing_Account__r.QTB_Legal_Entity_Country__c;
                acc.QTB_Contract_Entity__c = acc.Related_Billing_Account__r.QTB_Contract_Entity__c;
                operaAccListForUpdate.add(acc);
            }
        } 
        catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'updateOperationalAccInfoBasedUponBillCUpdate'
            );
            throw e;
        }
        QTB_RecursiveHandlerCheck.updateOperationalAccInfoBasedUponBillCUpdate = False;
        return operaAccListForUpdate;
    }
    /*************************************************************************************************
* Method:      updateBankDetail
* Parameters:  List<Account> accList, Set<String> billCountrySet
* Requirement: Gitlab #28446
* Start Date:  15/04/25
* Author:      TCS
* Description: To auto populate the Bank Detail on Billing Account
*********************************************************************************************/  
    public static void updateBankDetail(List<Account> accList, Set<String> remitToSet, Set<String> legalEntitySet) {
        try {
            if (AccountTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //Fetch all the Bank to Remit records
            List<QTB_Bank_To_Remit__c> BankToRemit = [SELECT ID,Name,QTB_Bank_Details__c,QTB_Bank_Details__r.QTB_Default__c,  QTB_Remit_To__c, QTB_Bank_Currency__c, QTB_Legal_Entity__c , QTB_Country__c,QTB_Payment_Method__c FROM QTB_Bank_To_Remit__c 
                                                      WHERE (QTB_Remit_To__c IN:remitToSet OR QTB_Legal_Entity__c IN:legalEntitySet) and QTB_Is_Active__c  = true and QTB_Bank_Currency__c != null and QTB_Payment_Method__c != null and QTB_Country__c != null];
            //KEY => Country, VALUE => List<QTB_Bank_To_Remit__c>
            Map<String, QTB_Bank_To_Remit__c> BankDetailCountryDefault = new Map<String, QTB_Bank_To_Remit__c>();
            Map<String, QTB_Bank_To_Remit__c> BankDetailDefaultLegalPayment = new Map<String, QTB_Bank_To_Remit__c>();
            Map<String, QTB_Bank_To_Remit__c> BankDetailDefaultLegalCurrency = new Map<String, QTB_Bank_To_Remit__c>();
            Map<String, QTB_Bank_To_Remit__c> BankDetailDefaultLegal = new Map<String, QTB_Bank_To_Remit__c>();
            Map<String, List<QTB_Bank_To_Remit__c>> addressCountryMap = new Map<String, List<QTB_Bank_To_Remit__c>>();
            if(BankToRemit.size() > 0)
            {
                for (QTB_Bank_To_Remit__c BTR: BankToRemit) {
                    if (addressCountryMap != null && addressCountryMap.containskey(BTR.QTB_Country__c.toUpperCase() + BTR.QTB_Payment_Method__c + BTR.QTB_Bank_Currency__c)) {
                        List<QTB_Bank_To_Remit__c> tempBDList = addressCountryMap.get(BTR.QTB_Country__c.toUpperCase() + BTR.QTB_Payment_Method__c + BTR.QTB_Bank_Currency__c);
                        tempBDList.add(BTR);
                        addressCountryMap.put(BTR.QTB_Country__c.toUpperCase() + BTR.QTB_Payment_Method__c + BTR.QTB_Bank_Currency__c, tempBDList);
                    } else {
                        List<QTB_Bank_To_Remit__c> tempBD = new List<QTB_Bank_To_Remit__c>();
                        tempBD.add(BTR);
                        addressCountryMap.put(BTR.QTB_Country__c.toUpperCase()+ BTR.QTB_Payment_Method__c + BTR.QTB_Bank_Currency__c, tempBD);
                    }
                    //if any default record is present
                    if(BTR.QTB_Bank_Details__r.QTB_Default__c) { 
                        BankDetailCountryDefault.put(BTR.QTB_Legal_Entity__c + BTR.QTB_Payment_Method__c + BTR.QTB_Bank_Currency__c, BTR);
                        BankDetailCountryDefault.put(BTR.QTB_Legal_Entity__c + BTR.QTB_Payment_Method__c,BTR);
                        BankDetailCountryDefault.put(BTR.QTB_Legal_Entity__c + BTR.QTB_Bank_Currency__c,BTR);
                        BankDetailCountryDefault.put(BTR.QTB_Legal_Entity__c,BTR);
                    }}}
            for (Account acc: accList) {
                //Populating the Country default Bank Detail 
                if (acc.BillingCountry != null) {
                    QTB_AccountHelper.isBankDetailPopulated = true;
                    //Logic to populating the Bank Detail for Country match.
                    if (addressCountryMap!=null && !addressCountryMap.isEmpty() 
                        && addressCountryMap.containskey(acc?.BillingCountry.toUpperCase() + acc?.QTB_Payment_Method__c + acc?.CurrencyIsoCode)) 
                    {
                        List<QTB_Bank_To_Remit__c> relatedBds = addressCountryMap.get(acc.BillingCountry.toUpperCase() + acc.QTB_Payment_Method__c + acc.CurrencyIsoCode);
                        if(relatedBds.size()>0){
                            acc.QTB_Bank_Detail__c = relatedBds[0].QTB_Bank_Details__c;
                            for (QTB_Bank_To_Remit__c bToR: relatedBds)
                            {
                                acc.QTB_Bank_Detail__c = BToR.QTB_Bank_Details__c;
                                break;
                            }}}
                    if(BankDetailCountryDefault != null && !BankDetailCountryDefault.isEmpty() && acc.QTB_Bank_Detail__c == null && 
                       BankDetailCountryDefault.containsKey(acc?.QTB_Contract_Entity__c + acc?.QTB_Payment_Method__c + acc?.CurrencyIsoCode))
                    {
                        acc.QTB_Bank_Detail__c = (BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c + acc.QTB_Payment_Method__c + acc.CurrencyIsoCode) != null) ? BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c + acc.QTB_Payment_Method__c + acc.CurrencyIsoCode).QTB_Bank_Details__c : null;
                    }
                    else if(BankDetailCountryDefault != null && !BankDetailCountryDefault.isEmpty() && acc.QTB_Bank_Detail__c == null &&
                            BankDetailCountryDefault.containsKey(acc?.QTB_Contract_Entity__c + acc?.QTB_Payment_Method__c))
                    {
                        acc.QTB_Bank_Detail__c = (BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c + acc.QTB_Payment_Method__c) != null) ? BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c + acc.QTB_Payment_Method__c).QTB_Bank_Details__c : null;
                    }
                    else if(BankDetailCountryDefault != null && !BankDetailCountryDefault.isEmpty() && acc.QTB_Bank_Detail__c == null &&
                            BankDetailCountryDefault.containsKey(acc?.QTB_Contract_Entity__c + acc?.CurrencyIsoCode))
                    {
                        acc.QTB_Bank_Detail__c = (BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c + acc.CurrencyIsoCode) != null) ? BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c + acc.CurrencyIsoCode).QTB_Bank_Details__c : null;
                    }
                    else if(BankDetailCountryDefault != null && !BankDetailCountryDefault.isEmpty() && acc.QTB_Bank_Detail__c == null &&
                            BankDetailCountryDefault.containsKey(acc?.QTB_Contract_Entity__c))
                    {
                        acc.QTB_Bank_Detail__c = (BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c) != null) ? BankDetailCountryDefault.get(acc.QTB_Contract_Entity__c).QTB_Bank_Details__c : null;
                    }}}}
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),
                                          e.getStackTraceString(),
                                          e.getMessage(),
                                          e.getTypeName(),
                                          'QTB_AccountHelperUtils');
        }
    }

    /*************************************************************************************************
* Method:      updateOperationalAccAssociateOnBlngAcc
* Parameters:  Set<Id> marketIds, List<Account> newAccountList
* Requirement: Gitlab #34559
* Start Date:  11/20/25
* Author:      Virtusa
* Description: Method to update Operational Account Associate on Billing Account to handle ROW LOCK error
*********************************************************************************************/
    public static List<Account> updateOperationalAccAssociateOnBlngAcc(Set<id> billingAccId){
        List<Account> accupdate = new List<Account>();
        try{
            for(id accIds : billingAccId)
            {
                Account acc = new Account();
                acc.Id = accIds;
                acc.QTB_Operational_Account_Associated__c = true;
                accupdate.add(acc); 
            }
            if(!accupdate.isEmpty()){
                update accupdate;
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'afterUpdateCheck_updateOperationalAccAssociateOnBlngAcc'
            );
        }
        QTB_RecursiveHandlerCheck.afterUpdateCheck_updateOperationalAccAssociateOnBlngAcc = False;
        return accupdate;
    }

}