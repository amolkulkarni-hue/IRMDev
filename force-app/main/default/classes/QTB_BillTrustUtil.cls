/*****************************************************************************************************
* Class: QTB_BillTrustUtil
* Purpose: This class is util class for BillTrust
* Developer       Date           Description
* -----------------------------------------------------------------------------------------------------
* Renuka Prasad    20/7/2021
* Renuka Prasad    02/27/2024    Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS
* Sravya           02/08/2024    #25444:Add 'Non Prod' to the Bill Trust File to display the BillTrustFileName
-----------------------------------------------------------------------------------------------------
* Requirement: Refactored for #31454
* Change History:
* Developer       Date            Description
* ------------------------------------------------------------------------------------------- 
* Chetan Kumar    11/07/2025      Refactored to use QTB_PurchaseOrderAccount__c junction object
*******************************************************************************************************/
public class QTB_BillTrustUtil
{
    public static final String SFDC_BILLTRUST_MAP = '{"Monthly":"EOM","Email":"EML","en_US":"ENG","en_GB":"ENG","fr":"FRC","Paper":"PRT","Customer Portal":"CUS","EDI":"EDI","Standard Invoice Download":"SID","Custom Solution":"CUS","IMBillContactPN_Frc":"888-365-4766","IMBillContactEmail_Frc":"csateam@ironmountain.com"}';
    
    public static final String BILLTRUST_IM_ORG_US = '<Orgname>IM US OU</Orgname>';
    
    public static final String BILLTRUST_IM_ORG_CANADA = '<Orgname>IM Canada OU</Orgname>';
  
    public static Map<ID, list<AccountContactRelation>> getAccountContactMap(list<ID> accountIds) {
    
	    //Map<ID, list<Contact>> accountContactMap = new Map<ID, list<Contact>>();
        Map<ID, list<AccountContactRelation>> accountContactMap = new Map<ID, list<AccountContactRelation>>();
        try
        {
            //Fetch primary contact
            list<AccountContactRelation> accountContacts = [Select Id,Contact.Email, Contact.Name, Roles, AccountId, Contact.IM_Role__c, QTB_Primary__c from AccountContactRelation where AccountId IN: accountIds];
            
            //for (Contact cnt: accountContacts) {
            for (AccountContactRelation cnt: accountContacts) {
                if (accountContactMap.containsKey(cnt.AccountId)) {
                    list<AccountContactRelation> tempContacts = new list<AccountContactRelation>();
                    tempContacts = accountContactMap.get(cnt.AccountId);
                    tempContacts.add(cnt);
                    
                    accountContactMap.put(cnt.AccountId, tempContacts);
                } else {
                    list<AccountContactRelation> tempContact = new list<AccountContactRelation>();
                    tempContact.add(cnt);
                    accountContactMap.put(cnt.AccountId, tempContact);
                }
            }
        } catch(exception e) {
            system.debug('Inside getAccountContactMap exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BillTrustUtil.getAccountContactMap');
        }
        System.debug('accountContactMap>>'+accountContactMap);
        return accountContactMap;
    }
    
/****************************************************************************************************************************************************
* Method : getAccountPurchaseOrderMap
* Parameters: list<ID> accountIds
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To get AccountPurchaseOrderMap
-----------------------------------------------------------------------------------------------------
* Requirement: Refactored for #31454
* Change History:
* Developer       Date            Description
* --------------------------------------------------------------------------------------------------- 
* Chetan Kumar    11/07/2025      Refactored to use QTB_PurchaseOrderAccount__c junction object
*******************************************************************************************************************************************************/
    /**public static Map<ID, list<QTB_PurchaseOrder__c>> getAccountPurchaseOrderMap(list<ID> accountIds)
    {
        Map<ID, list<QTB_PurchaseOrder__c>> accountPurchaseOrderMap = new Map<ID, list<QTB_PurchaseOrder__c>>();
        try
        {
            //Fetch eligible Purchase Order
            list<QTB_PurchaseOrder__c> purchseOrders = [Select Id,QTB_Start_Date__c,QTB_End_Date__c,QTB_Customer_PO__c,QTB_Billing_Account__c from QTB_PurchaseOrder__c
                                                        where QTB_Billing_Account__c IN :accountIds AND QTB_Status__c = 'Active' and QTB_PO_Type__c = 'Standard'];
            
            for (QTB_PurchaseOrder__c po: purchseOrders) {
                if (accountPurchaseOrderMap.containsKey(po.QTB_Billing_Account__c)) {
                    list<QTB_PurchaseOrder__c> tempPos = new list<QTB_PurchaseOrder__c>();
                    tempPos = accountPurchaseOrderMap.get(po.QTB_Billing_Account__c);
                    tempPos.add(po);
                    
                    accountPurchaseOrderMap.put(po.QTB_Billing_Account__c, tempPos);
                } else {
                    list<QTB_PurchaseOrder__c> tempPo = new list<QTB_PurchaseOrder__c>();
                    tempPo.add(po);
                    
                    accountPurchaseOrderMap.put(po.QTB_Billing_Account__c, tempPo);
                }
            }
        } catch(exception e) {
            system.debug('Inside getAccountContactMap exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BillTrustUtil.getAccountPurchaseOrderMap');
        }
        return accountPurchaseOrderMap;
    }**/
    public static Map<ID, List<QTB_PurchaseOrder__c>> getAccountPurchaseOrderMap(List<ID> accountIds) {
        Map<ID, List<QTB_PurchaseOrder__c>> accountPurchaseOrderMap = new Map<ID, List<QTB_PurchaseOrder__c>>();
        try {
            List<QTB_PurchaseOrderAccount__c> poAccountList = [
                SELECT QTB_Account__c,
                    QTB_Purchase_Order__r.Id,
                    QTB_Purchase_Order__r.QTB_Start_Date__c,
                    QTB_Purchase_Order__r.QTB_End_Date__c,
                    QTB_Purchase_Order__r.QTB_Customer_PO__c
                FROM QTB_PurchaseOrderAccount__c
                WHERE QTB_Account__c IN :accountIds
                AND QTB_Purchase_Order__r.QTB_Status__c = 'Active'
                AND QTB_Purchase_Order__r.QTB_PO_Type__c = 'Standard'
            ];
                for (QTB_PurchaseOrderAccount__c poAcc : poAccountList) {
                QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c(
                    Id = poAcc.QTB_Purchase_Order__r.Id,
                    QTB_Start_Date__c = poAcc.QTB_Purchase_Order__r.QTB_Start_Date__c,
                    QTB_End_Date__c = poAcc.QTB_Purchase_Order__r.QTB_End_Date__c,
                    QTB_Customer_PO__c = poAcc.QTB_Purchase_Order__r.QTB_Customer_PO__c
                );
                List<QTB_PurchaseOrder__c> tempPOList = accountPurchaseOrderMap.get(poAcc.QTB_Account__c);
                if (tempPOList == null) {
                    tempPOList = new List<QTB_PurchaseOrder__c>();
                    accountPurchaseOrderMap.put(poAcc.QTB_Account__c, tempPOList);
                }
                tempPOList.add(po);
            }
        } catch (Exception e) {
            System.debug('Inside getAccountPurchaseOrderMap exception block: ' + e.getMessage() + ' Line Number: ' + e.getLineNumber());
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BillTrustUtil.getAccountPurchaseOrderMap');
        }
        return accountPurchaseOrderMap;
    }

    /****************************************************************************************************************************************************
* Method : getAccountServiceLocationMap
* Parameters: list<ID> accountIds
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To get AccountServiceLocationMap
*******************************************************************************************************************************************************/
    public static Map<ID, list<Service_Location__c>> getAccountServiceLocationMap(list<ID> accountIds) {
        
        Map<ID, list<Service_Location__c>> accountSrvLcnMap = new Map<ID, list<Service_Location__c>>();
        try
        {
            list<Service_Location__c> serviceLocation = [Select id,QTB_Billing_Account__c,QTB_Site_Number__c,Name,QTB_SiteID__c, Svc_District_Id__r.Owning_District_Id__c
                                                         from Service_Location__c where QTB_Billing_Account__c IN :accountIds];
            
            for (Service_Location__c sl: serviceLocation) {
                if (accountSrvLcnMap.containsKey(sl.QTB_Billing_Account__c)) {
                    list<Service_Location__c> tempSls = new list<Service_Location__c>();
                    tempSls = accountSrvLcnMap.get(sl.QTB_Billing_Account__c);
                    tempSls.add(sl);
                    
                    accountSrvLcnMap.put(sl.QTB_Billing_Account__c, tempSls);
                } else {
                    list<Service_Location__c> tempSl = new list<Service_Location__c>();
                    tempSl.add(sl);
                    
                    accountSrvLcnMap.put(sl.QTB_Billing_Account__c, tempSl);
                }
            }
        } catch(exception e) {
            system.debug('Inside getAccountContactMap exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BillTrustUtil.getAccountServiceLocationMap');
        }
        return accountSrvLcnMap;
    }
    
    /***********************************************************************************************************
* Method : getSupplementaryInfo
* Parameters: list<blng__Invoice__c> invoiceList, list<blng__CreditNote__c> creditNoteList
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To get the additional details required for Bill Trust XML
**************************************************************************************************************/
    public static QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo getSupplementaryInfo(list<blng__Invoice__c> invoiceList, list<blng__CreditNote__c> creditNoteList) {
        
        QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo suppliInfo = new QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo();
        Map<ID, QTB_GenerateBillTrustExtractCTRL.AdditionalInfo> accountAdditionalMap = new Map<ID, QTB_GenerateBillTrustExtractCTRL.AdditionalInfo>();
        
        try {   
            list<ID> accountIds = new list<ID>();
            Set<String> countries = new Set<String>();
            Map<ID, String> accountCountryMap = new Map<ID, String>();
            list<blng__InvoiceLine__c> tempInvLines = new list<blng__InvoiceLine__c>();
            list<blng__CreditNoteLine__c> tempCreditNoteLines = new list<blng__CreditNoteLine__c>();
            Map<ID, String> productCodeMap = new Map<ID, String>();
            Set<ID> productIds = new Set<ID>();
            Map<ID, String> productBillCodeMap = new Map<ID, String>();
            Map<ID, list<ID>> accountInvCrdListMap = new Map<ID, list<ID>>();
            Map<ID, blng__Invoice__c> invoiceMap = new Map<ID, blng__Invoice__c>();
            Map<ID, blng__CreditNote__c> creditNoteMap = new Map<ID, blng__CreditNote__c>();
            Map<ID, String> accountSiteNameMap = new Map<ID, String>();
            Map<String, String> productTranslationMap = new Map<String, String>();
            list<ID> invoiceLineIds = new list<ID>();
            list<ID> creditNoteLineIds = new list<ID>();
            Set<String> AccountLEntityCountry = new Set<String>(); 
            
            if (invoiceList.size() > 0) {
                //To fetch eligible accounts and invoices
                for (blng__Invoice__c inv: invoiceList) {
                    accountIds.add(inv.blng__Account__c);
                    countries.add(inv.blng__Account__r.QTB_Legal_Entity_Country__c);
          AccountLEntityCountry.add(inv.blng__Account__r.QTB_Legal_Entity_Country__c);
                    invoiceMap.put(inv.id, inv);
                    accountSiteNameMap.put(inv.blng__Account__c, inv.blng__Account__r.QTB_Billing_Account_Invoice_Name__c);
                    
                    if (!accountCountryMap.containsKey(inv.blng__Account__c)) {
                        accountCountryMap.put(inv.blng__Account__c, inv.blng__Account__r.QTB_Legal_Entity_Country__c);
                    }
                    
                    tempInvLines.addAll(inv.blng__InvoiceInvoiceLines__r);
                    
                    if (accountInvCrdListMap.get(inv.blng__Account__c) != null && accountInvCrdListMap.get(inv.blng__Account__c).size() > 0) {
                        list<ID> tempInvList = accountInvCrdListMap.get(inv.blng__Account__c);
                        tempInvList.add(inv.id);
                        
                        accountInvCrdListMap.put(inv.blng__Account__c, tempInvList);
                    } else {
                        list<ID> newTempInvList = new list<ID>();
                        newTempInvList.add(inv.id);
                        
                        accountInvCrdListMap.put(inv.blng__Account__c, newTempInvList);
                    }
                }
                
                for (blng__InvoiceLine__c tempInvLine: tempInvLines) {
                    productIds.add(tempInvLine.blng__Product__c);
                    invoiceLineIds.add(tempInvLine.Id);
                }
            }
            
            if (creditNoteList.size() > 0) {
                //To fetch eligible accounts and invoices
                for (blng__CreditNote__c crdNte: creditNoteList) {
                    accountIds.add(crdNte.blng__Account__c);
                    countries.add(crdNte.blng__Account__r.QTB_Legal_Entity_Country__c);
          AccountLEntityCountry.add(crdNte.blng__Account__r.QTB_Legal_Entity_Country__c);
                    creditNoteMap.put(crdNte.Id, crdNte);
                    accountSiteNameMap.put(crdNte.blng__Account__c, crdNte.blng__Account__r.QTB_Billing_Account_Invoice_Name__c);
                    
                    if (!accountCountryMap.containsKey(crdNte.blng__Account__c)) {
                        accountCountryMap.put(crdNte.blng__Account__c, crdNte.blng__Account__r.QTB_Legal_Entity_Country__c);
                    }
                    
                    tempCreditNoteLines.addAll(crdNte.blng__CreditNoteCreditLines__r);
                    
                    if (accountInvCrdListMap.get(crdNte.blng__Account__c) != null && accountInvCrdListMap.get(crdNte.blng__Account__c).size() > 0) {
                        list<ID> tempCrdNtList = accountInvCrdListMap.get(crdNte.blng__Account__c);
                        tempCrdNtList.add(crdNte.id);
                        
                        accountInvCrdListMap.put(crdNte.blng__Account__c, tempCrdNtList);
                    } else {
                        list<ID> newTempCrdNtList = new list<ID>();
                        newTempCrdNtList.add(crdNte.id);
                        
                        accountInvCrdListMap.put(crdNte.blng__Account__c, newTempCrdNtList);
                    }
                }
                
                for (blng__CreditNoteLine__c tempCredLine: tempCreditNoteLines) {
                    productIds.add(tempCredLine.blng__Product__c);
                    creditNoteLineIds.add(tempCredLine.Id);
                }
            }
            
            //Fetching product name and the corresponding translated language text
            list<SBQQ__Localization__c> productLocalization = [SELECT id,SBQQ__Product__c,SBQQ__Label__c,SBQQ__APIName__c,SBQQ__Text__c,
                                                               SBQQ__Language__c,SBQQ__Product__r.Name FROM SBQQ__Localization__c WHERE SBQQ__APIName__c = 'Name'];
            //Creating Product and its translated text map
            for (SBQQ__Localization__c prdLoc: productLocalization) {
                productTranslationMap.put(prdLoc.SBQQ__Product__c+'-'+prdLoc.SBQQ__Language__c, prdLoc.SBQQ__Text__c);
            }
            suppliInfo.productTranslationMap = productTranslationMap;
            
            
            //AccountLEntityCountry check added as pert of GITLAB #15327 in QTB_Bill_Code_Product_Lookup__c query
            //Fetching billcodes for the eligible invoice lines
            system.debug('AccountLEntityCountry@@' +AccountLEntityCountry);
            list<QTB_Bill_Code_Product_Lookup__c> billCodeInfo = [Select id, QTB_Source_Bill_Code__c, QTB_Description__c, QTB_Product2__c
                                                                  from QTB_Bill_Code_Product_Lookup__c where QTB_Product2__c IN :productIds AND QTB_Country__r.Name IN :AccountLEntityCountry];
            system.debug('billCodeInfo@@@' +billCodeInfo);
            for (QTB_Bill_Code_Product_Lookup__c billCode: billCodeInfo) {
                productCodeMap.put(billCode.QTB_Product2__c, billCode.QTB_Source_Bill_Code__c);
            }
            //Updating the billcode map in the wrapper class
            suppliInfo.productBillCodeMap = productCodeMap;
            
            //Fetching the Country ISO codes for the eligible accounts
            list<IM_Country__c> countryInfo = [Select id, Name, CountryName_Ext_ID__c, Iso31662Code__c, Iso31663Code__c from IM_Country__c where Active__c = true AND Name IN:countries];
            
            Map<String, String> countryCodeMap = new Map<String, String>();
            for (IM_Country__c cntry: countryInfo) {
                countryCodeMap.put(cntry.Name, cntry.Iso31662Code__c);
            }
            
            Map<ID, Map<String, Decimal>> siteTaxDetailsMap = new Map<ID, Map<String, Decimal>>();
            list<String> countryList = new list<String>();
            countryList.addAll(countries);
            //Fetch the SiteTax Details only for Canada
            if (countryList.size() > 0 && countryCodeMap.get(countryList[0]) == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                if (invoiceLineIds.size() > 0) {
                    siteTaxDetailsMap = QTB_BillTrustUtil.getSiteTaxDetailsMap(invoiceLineIds, true);
                } else if (creditNoteLineIds.size() > 0) {
                    siteTaxDetailsMap = QTB_BillTrustUtil.getSiteTaxDetailsMap(creditNoteLineIds, false);
                }
            }
            suppliInfo.siteTaxDetailsMap = siteTaxDetailsMap;
            
            suppliInfo.productTranslationMap = productTranslationMap;
            
            //Fetch Contacts
            Map<ID, list<AccountContactRelation>> accountContactMap = QTB_BillTrustUtil.getAccountContactMap(accountIds);
            
            //Fetch Purchase Orders
            Map<ID, list<QTB_PurchaseOrder__c>> accountPurchaseOrderMap = QTB_BillTrustUtil.getAccountPurchaseOrderMap(accountIds);
            
            //Fetch Service Locations
            Map<ID, list<Service_Location__c>> accountServiceLocationMap = QTB_BillTrustUtil.getAccountServiceLocationMap(accountIds);
            
            //Logic to set the account level additional details to the AdditionalInfo wrapper
            for (ID accountId: accountIds) {
                QTB_GenerateBillTrustExtractCTRL.AdditionalInfo info = new QTB_GenerateBillTrustExtractCTRL.AdditionalInfo();
                
                if (accountContactMap.get(accountId) != null) {
                    list<AccountContactRelation> accountContacts = accountContactMap.get(accountId);
                    String customerContactName = '';
                    String billintContactEmail = '';
                    Boolean isPrimaryContactSet = false;
                    for (AccountContactRelation cnt: accountContacts) {
                        if (cnt.Roles != null && cnt.Roles.contains('Billing')) {
                            
                            if (!isPrimaryContactSet) {
                                customerContactName = cnt.Contact.Name;
                            }
                            if (cnt.QTB_Primary__c == true) {
                                customerContactName = cnt.Contact.Name;
                                isPrimaryContactSet = true;
                            }
                            
                            if (String.isBlank(billintContactEmail)) {
                                billintContactEmail = cnt.Contact.Email;
                            } else {
                                billintContactEmail = billintContactEmail + ';' + cnt.Contact.Email;
                            }
                        }
                    }
                    System.debug('billintContactEmail'+billintContactEmail);
                    info.customerContactName = customerContactName;
                    info.primaryContactEmail = billintContactEmail;
                }
                
                if (accountPurchaseOrderMap.get(accountId) != null && accountInvCrdListMap.get(accountId) != null) {
                    list<QTB_PurchaseOrder__c> accountPurchaseOrders = accountPurchaseOrderMap.get(accountId);
                    
                    Map<ID, String> invoicePoMap = new Map<ID, String>();
                    list<ID> tempRecordIds = accountInvCrdListMap.get(accountId);
                    
                    for (ID tempId: tempRecordIds) {
                        for (QTB_PurchaseOrder__c po: accountPurchaseOrders) {
                            Date invCrdDate = System.today();
                            
                            if (invoiceMap.get(tempId) != null && invoiceMap.get(tempId).blng__InvoiceDate__c != null) {
                                invCrdDate = invoiceMap.get(tempId).blng__InvoiceDate__c;
                            } else if (creditNoteMap.get(tempId) != null && creditNoteMap.get(tempId).blng__CreditNoteDate__c != null) {
                                invCrdDate = creditNoteMap.get(tempId).blng__CreditNoteDate__c;
                            }
                            
                            if (po.QTB_Start_Date__c <= invCrdDate && po.QTB_End_Date__c >= invCrdDate) {
                                invoicePoMap.put(tempId, po.QTB_Customer_PO__c);
                            }
                        }
                    }
                    
                    info.customerPO = invoicePoMap;
                }
                
                if (accountServiceLocationMap.get(accountId) != null) {
                    list<Service_Location__c> accountServiceLocation = accountServiceLocationMap.get(accountId);
                    String siteId = '';
                    String siteNumber = '';
                    
                    for (Service_Location__c sl: accountServiceLocation) {
                        //if (sl.QTB_SiteID__c != null) {
                        //siteId = sl.QTB_SiteID__c;
                        if (sl.QTB_Site_Number__c != null) {
                            siteId = sl.QTB_Site_Number__c;
                        }
                        
                        String owningDist = '';
                        if (sl.Svc_District_Id__c != null && sl.Svc_District_Id__r.Owning_District_Id__c != null 
                            && !(sl.Svc_District_Id__r.Owning_District_Id__c == 'null')) {
                                owningDist = sl.Svc_District_Id__r.Owning_District_Id__c;
                            }
                        
                        String serviceLcnSiteNumber = '';
                        if (sl.QTB_Site_Number__c != null && !(sl.QTB_Site_Number__c == 'null')) {
                            serviceLcnSiteNumber = sl.QTB_Site_Number__c;
                        }
                        
                        siteNumber = owningDist + '.' + serviceLcnSiteNumber;
                    }
                    
                    info.siteId = siteId;
                    info.siteNumber = siteNumber;
                }
                
                if (accountCountryMap.get(accountId) != null
                    && countryCodeMap.get(accountCountryMap.get(accountId)) != null)
                {
                    info.countryISOCode = countryCodeMap.get(accountCountryMap.get(accountId));
                }
                
                String siteName = '';
                if (accountSiteNameMap.get(accountId) != null) {
                    siteName = accountSiteNameMap.get(accountId);
                }
                info.siteName = siteName;
                
                System.debug('info'+info);
                accountAdditionalMap.put(accountId, info);
                System.debug('accountAdditionalMap'+accountAdditionalMap);
            }
            //Updating the accountAdditionalInfoMap to the SupplementaryInfo wrapper
            suppliInfo.accountAdditionalInfoMap = accountAdditionalMap;
            
        } catch(exception e) {
            system.debug('Inside getAdditionalInfo exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_GenerateBillTrustExtractCTRL.getAdditionalInfo');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
        
        return suppliInfo;
    }
    
    /****************************************************************************************************************************************************
* Method : generateBilltrustRequest
* Parameters: List<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> invoicesInfo, Boolean isMassExtract, String invSchedulerName, String invSchedulerId
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To generate Bill Trust request XML
*******************************************************************************************************************************************************/
    public static void generateBilltrustRequest(List<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> invoicesInfo, Boolean isMassExtract, String invSchedulerName, String invSchedulerId)
    {
        try
        {
            if (invoicesInfo.size() <= 0) {
                throw new AuraHandledException('No valid invoice found.');
            }
            
            String invoiceParams = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_XML_HEADER;
            
            String invName = '';
            String invoiceId = '';
            String invoiceStatus = '';
            String invNumber = '';
            String canadaCountryPrefix = '';
            String legalCountry = '';
            String referenceId = '';
            
            if (invoicesInfo != null && invoicesInfo.size() > 0) {
                if (invoicesInfo[0].customerCountry != NULL && invoicesInfo[0].customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceParams = invoiceParams+QTB_BillTrustUtil.BILLTRUST_IM_ORG_US;
                    legalCountry = QTB_Constants.US_COUNTRY;
                } else {
                    invoiceParams = invoiceParams+QTB_BillTrustUtil.BILLTRUST_IM_ORG_CANADA;
                    legalCountry = QTB_Constants.CANADA_COUNTRY;
                }
            }
            
            for (QTB_GenerateBillTrustExtractCTRL.InvoiceInfo invInfo : invoicesInfo) {
                
                if (!isMassExtract) {
                    invName = invInfo.invName;
                    invoiceId = invInfo.invId;
                    invNumber = invInfo.invNumber;
                }
                invoiceStatus = invInfo.invoiceStatus;
                
                invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_XML_INVOICE_HEADER_START_TAG;
                
                //Updating invoice details
                invoiceParams = invoiceParams+'<TransactionType>'+invInfo.transactionType+'</TransactionType>';
                invoiceParams = invoiceParams+'<InvoiceType>'+invInfo.invoiceType+'</InvoiceType>';
                invoiceParams = invoiceParams+'<Consolidated-Single>'+invInfo.consolidated_single+'</Consolidated-Single>';
                if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceParams = invoiceParams+'<GovernmentType>'+invInfo.governmentType+'</GovernmentType>';
                }
                invoiceParams = invoiceParams+'<TemplateType>'+invInfo.templateType+'</TemplateType>';
                invoiceParams = invoiceParams+'<DeliveryType>'+invInfo.deliveryType+'</DeliveryType>';
                invoiceParams = invoiceParams+'<InvoiceDeliveryEmailAddress>'+invInfo.invoiceDeliveryEmailAddress+'</InvoiceDeliveryEmailAddress>';
                invoiceParams = invoiceParams+'<HoldInd>'+invInfo.holdInd+'</HoldInd>';
                invoiceParams = invoiceParams+'<HoldRequester>'+invInfo.holdRequester+'</HoldRequester>';
                invoiceParams = invoiceParams+'<IMCompany>'+invInfo.imCompany+'</IMCompany>';
                invoiceParams = invoiceParams+'<CustomerLanguage>'+invInfo.customerLanguage+'</CustomerLanguage>';
                invoiceParams = invoiceParams+'<Currency>'+invInfo.accountCurrency+'</Currency>';
                invoiceParams = invoiceParams+'<ReturnAddress1>'+invInfo.returnAddress1+'</ReturnAddress1>';
                invoiceParams = invoiceParams+'<ReturnAddress2>'+invInfo.returnAddress2+'</ReturnAddress2>';
                invoiceParams = invoiceParams+'<ReturnAddress3>'+invInfo.returnAddress3+'</ReturnAddress3>';
                invoiceParams = invoiceParams+'<ReturnCity>'+invInfo.returnCity+'</ReturnCity>';
                invoiceParams = invoiceParams+'<ReturnState>'+invInfo.returnState+'</ReturnState>';
                invoiceParams = invoiceParams+'<ReturnPostalCode>'+invInfo.returnPostalCode+'</ReturnPostalCode>';
                invoiceParams = invoiceParams+'<IMBillContact>'+invInfo.imBillContact+'</IMBillContact>';
                invoiceParams = invoiceParams+'<IMBillContactPN>'+invInfo.imBillContactPN+'</IMBillContactPN>';
                invoiceParams = invoiceParams+'<IMBillContactEmail>'+invInfo.imBillContactEmail+'</IMBillContactEmail>';
                invoiceParams = invoiceParams+'<CustomerName>'+invInfo.customerName+'</CustomerName>';
                invoiceParams = invoiceParams+'<CustomerContact>'+invInfo.customerContact+'</CustomerContact>';
                invoiceParams = invoiceParams+'<CustomerAddress1>'+invInfo.customerAddress1+'</CustomerAddress1>';
                invoiceParams = invoiceParams+'<CustomerAddress2>'+invInfo.customerAddress2+'</CustomerAddress2>';
                invoiceParams = invoiceParams+'<CustomerAddress3>'+invInfo.CustomerAddress3+'</CustomerAddress3>';
                invoiceParams = invoiceParams+'<CustomerAddress4>'+invInfo.customerAddress4+'</CustomerAddress4>';
                invoiceParams = invoiceParams+'<CustomerCity>'+invInfo.customerCity+'</CustomerCity>';
                System.debug('invInfo.customerCountry>>>'+invInfo.customerCountry);
                if (invInfo.customerCountry != NULL && invInfo.customerCountry == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceParams = invoiceParams+'<CustomerProvince>'+invInfo.customerState+'</CustomerProvince>';
                    if (canadaCountryPrefix == '') {
                        canadaCountryPrefix = QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE + '_';
                    }
                } else {
                    invoiceParams = invoiceParams+'<CustomerState>'+invInfo.customerState+'</CustomerState>';
                }
                invoiceParams = invoiceParams+'<CustomerPostalCode>'+invInfo.customerPostalCode+'</CustomerPostalCode>';
                invoiceParams = invoiceParams+'<CustomerCountry>'+invInfo.customerCountry+'</CustomerCountry>';
                invoiceParams = invoiceParams+'<InvoiceID>'+invInfo.invoiceID+'</InvoiceID>';
                invoiceParams = invoiceParams+'<InvoiceDate>'+invInfo.invoiceDate+'</InvoiceDate>';
                invoiceParams = invoiceParams+'<ServicePeriod>'+invInfo.servicePeriod+'</ServicePeriod>';
                invoiceParams = invoiceParams+'<CustomerID>'+invInfo.customerID+'</CustomerID>';
                if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceParams = invoiceParams+'<TaxID>'+invInfo.TaxID+'</TaxID>';
                }
                invoiceParams = invoiceParams+'<PONumber>'+invInfo.poNumber+'</PONumber>';
                invoiceParams = invoiceParams+'<DueDate>'+invInfo.dueDate+'</DueDate>';
                invoiceParams = invoiceParams+'<TotalStorage>'+invInfo.totalStorage+'</TotalStorage>';
                invoiceParams = invoiceParams+'<TotalService>'+invInfo.totalService+'</TotalService>';
                invoiceParams = invoiceParams+'<TotalOther>'+invInfo.totalOther+'</TotalOther>';
                invoiceParams = invoiceParams+'<TotalTaxAmount>'+invInfo.totalTaxAmount+'</TotalTaxAmount>';
                invoiceParams = invoiceParams+'<TotalAdjustmentAmount>'+invInfo.totalAdjustmentAmount+'</TotalAdjustmentAmount>';
                invoiceParams = invoiceParams+'<LateFee>'+invInfo.lateFee+'</LateFee>';
                invoiceParams = invoiceParams+'<InvoiceTotalAmount>'+invInfo.invoiceTotalAmount+'</InvoiceTotalAmount>';
                invoiceParams = invoiceParams+'<PayMntName>'+invInfo.payMntName+'</PayMntName>';
                invoiceParams = invoiceParams+'<PayMntAddress1>'+invInfo.payMntAddress1+'</PayMntAddress1>';
                invoiceParams = invoiceParams+'<PayMntAddress2>'+invInfo.payMntAddress2+'</PayMntAddress2>';
                invoiceParams = invoiceParams+'<PayMntAddress3>'+invInfo.payMntAddress3+'</PayMntAddress3>';
                invoiceParams = invoiceParams+'<PayMntCity>'+invInfo.payMntCity+'</PayMntCity>';
                invoiceParams = invoiceParams+'<PayMntState>'+invInfo.PayMntState+'</PayMntState>';
                invoiceParams = invoiceParams+'<PayMntPostalCode>'+invInfo.payMntPostalCode +'</PayMntPostalCode>';
                if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceParams = invoiceParams+'<ContractNumber>'+invInfo.contractNumber+'</ContractNumber>';
                    invoiceParams = invoiceParams+'<CageCode>'+invInfo.CageCode+'</CageCode>';
                    invoiceParams = invoiceParams+'<DunsNumber>'+invInfo.dunsNumber+'</DunsNumber>';
                }
                
                QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo invLine = invInfo.invoiceDetails;
                
                invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_XML_INVOICE_LINE_DETAIL_START_TAG;
                
                invoiceParams = invoiceParams+'<SiteID>'+invLine.siteID+'</SiteID>';
                invoiceParams = invoiceParams+'<SiteName>'+invLine.SiteName+'</SiteName>';
                invoiceParams = invoiceParams+'<InvoiceID>'+invLine.invoiceID+'</InvoiceID>';
                invoiceParams = invoiceParams+'<ReferenceID>'+invLine.referenceID+'</ReferenceID>';
                invoiceParams = invoiceParams+'<InvoiceDate>'+invLine.InvoiceDate+'</InvoiceDate>';
                invoiceParams = invoiceParams+'<PONumber>'+invLine.PONumber+'</PONumber>';
                System.debug('storageDetails>>>'+invLine.storageDetails);
                referenceId = invLine.referenceID;
                if (invLine.storageDetails != null) {
                    for (QTB_GenerateBillTrustExtractCTRL.ProductInfo storage: invLine.storageDetails) {
                        if (storage.lineAmountTotal != null && storage.lineAmountTotal != '0.00') {
                            invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_STORAGE_START_TAG;
                            
                            invoiceParams = invoiceParams+'<BillCD>'+storage.billCD+'</BillCD>';
                            if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                                invoiceParams = invoiceParams+'<CLIN>'+storage.cLIN+'</CLIN>';
                            }
                            invoiceParams = invoiceParams+'<Description>'+storage.description+'</Description>';
                            invoiceParams = invoiceParams+'<QuantityCnt>'+storage.quantityCnt+'</QuantityCnt>';
                            invoiceParams = invoiceParams+'<RateAmount>'+storage.rateAmount+'</RateAmount>';
                            invoiceParams = invoiceParams+'<InvoiceLineAmount>'+storage.invoiceLineAmount+'</InvoiceLineAmount>';
                            if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                                invoiceParams = invoiceParams+'<TaxLineAmount>'+storage.taxLineAmount+'</TaxLineAmount>';
                                invoiceParams = invoiceParams+'<LineAmountTotal>'+storage.lineAmountTotal+'</LineAmountTotal>';
                            }
                            invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_STORAGE_END_TAG;
                        }
                    }
                }
                invoiceParams = invoiceParams+'<TotalStorageAmount>'+invLine.totalStorageAmount+'</TotalStorageAmount>';
                
                if (invLine.serviceDetails != null) {
                    for (QTB_GenerateBillTrustExtractCTRL.ProductInfo service: invLine.serviceDetails) {
                        if (service.lineAmountTotal != null && service.lineAmountTotal != '0.00') {
                            invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_SERVICE_START_TAG;
                            
                            invoiceParams = invoiceParams+'<BillCD>'+service.billCD+'</BillCD>';
                            if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                                invoiceParams = invoiceParams+'<CLIN>'+service.cLIN+'</CLIN>';
                            }
                            invoiceParams = invoiceParams+'<Description>'+service.description+'</Description>';
                            invoiceParams = invoiceParams+'<QuantityCnt>'+service.quantityCnt+'</QuantityCnt>';
                            invoiceParams = invoiceParams+'<RateAmount>'+service.rateAmount+'</RateAmount>';
                            invoiceParams = invoiceParams+'<InvoiceLineAmount>'+service.invoiceLineAmount+'</InvoiceLineAmount>';
                            if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                                invoiceParams = invoiceParams+'<TaxLineAmount>'+service.taxLineAmount+'</TaxLineAmount>';
                                invoiceParams = invoiceParams+'<LineAmountTotal>'+service.lineAmountTotal+'</LineAmountTotal>';
                            }
                            
                            invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_SERVICE_END_TAG;
                        }
                    }
                }
                invoiceParams = invoiceParams+'<TotalServiceAmount>'+invLine.totalServiceAmount+'</TotalServiceAmount>';
                
                if (invLine.otherDetails != null) {
                    for (QTB_GenerateBillTrustExtractCTRL.ProductInfo other: invLine.otherDetails) {
                        if (other.lineAmountTotal != null && other.lineAmountTotal != '0.00') {
                            invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_OTHER_START_TAG;
                            
                            invoiceParams = invoiceParams+'<BillCD>'+other.billCD+'</BillCD>';
                            if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                                invoiceParams = invoiceParams+'<CLIN>'+other.cLIN+'</CLIN>';
                            }
                            invoiceParams = invoiceParams+'<Description>'+other.description+'</Description>';
                            invoiceParams = invoiceParams+'<QuantityCnt>'+other.quantityCnt+'</QuantityCnt>';
                            invoiceParams = invoiceParams+'<RateAmount>'+other.rateAmount+'</RateAmount>';
                            invoiceParams = invoiceParams+'<InvoiceLineAmount>'+other.invoiceLineAmount+'</InvoiceLineAmount>';
                            if (invInfo.customerCountry != NULL && invInfo.customerCountry != QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                                invoiceParams = invoiceParams+'<TaxLineAmount>'+other.taxLineAmount+'</TaxLineAmount>';
                                invoiceParams = invoiceParams+'<LineAmountTotal>'+other.lineAmountTotal+'</LineAmountTotal>';
                            }
                            invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_OTHER_END_TAG;
                        }
                    }
                }
                invoiceParams = invoiceParams+'<TotalOtherAmount>'+invLine.totalOtherAmount+'</TotalOtherAmount>';
                
                if (invInfo.customerCountry != NULL && invInfo.customerCountry == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceParams = invoiceParams+'<SiteSubTotal>'+invLine.siteSubTotal+'</SiteSubTotal>';
                    invoiceParams = invoiceParams+'<SiteTaxDescription1>'+invLine.siteTaxDescription1+'</SiteTaxDescription1>';
                    invoiceParams = invoiceParams+'<SiteTaxAmount1>'+invLine.siteTaxAmount1+'</SiteTaxAmount1>';
                    invoiceParams = invoiceParams+'<SiteTaxDescription2>'+invLine.siteTaxDescription2+'</SiteTaxDescription2>';
                    invoiceParams = invoiceParams+'<SiteTaxAmount2>'+invLine.siteTaxAmount2+'</SiteTaxAmount2>';
                }
                
                invoiceParams = invoiceParams+'<SiteAdjustmentTotal>'+invLine.siteAdjustmentTotal+'</SiteAdjustmentTotal>';
                invoiceParams = invoiceParams+'<SiteNumber>'+invLine.siteNumber+'</SiteNumber>';
                invoiceParams = invoiceParams+'<SiteNumberTotal>'+invLine.siteNumberTotal+'</SiteNumberTotal>';
                invoiceParams = invoiceParams+'<SiteLateFeeAmount>'+invLine.siteLateFeeAmount+'</SiteLateFeeAmount>';
                invoiceParams = invoiceParams+'<InvoiceTotalAmount>'+invLine.invoiceTotalAmount+'</InvoiceTotalAmount>';
                invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_XML_INVOICE_LINE_DETAIL_END_TAG;
                invoiceParams = invoiceParams+'<ReceivedBy>'+invInfo.receivedBy+'</ReceivedBy>';
                invoiceParams = invoiceParams+'<PastDueBalancePrior>'+invInfo.pastDueBalancePrior+'</PastDueBalancePrior>';
                invoiceParams = invoiceParams+'<ReceivedByPay>'+invInfo.invoiceDate+'</ReceivedByPay>';
                invoiceParams = invoiceParams+'<PaymentsRcvd>'+invInfo.paymentsRcvd+'</PaymentsRcvd>';//NEW Field
                invoiceParams = invoiceParams+'<ReceivedByAdjust>'+invInfo.receivedByAdjust+'</ReceivedByAdjust>';
                invoiceParams = invoiceParams+'<AdjustmentsRcvdAmt>'+invInfo.adjustmentsRcvdAmt+'</AdjustmentsRcvdAmt>';//NEW Field
                invoiceParams = invoiceParams+'<ReceivedByBal>'+invInfo.receivedByBal+'</ReceivedByBal>';
                invoiceParams = invoiceParams+'<PastDueBalanceTotal>'+invInfo.pastDueBalanceTotal+'</PastDueBalanceTotal>';//NEW Field
                invoiceParams = invoiceParams+'<CurrentTotalAmount>'+invInfo.currentTotalAmount+'</CurrentTotalAmount>';//NEW Field
                invoiceParams = invoiceParams+'<TotalBalance>'+invInfo.totalBalance+'</TotalBalance>';//Derived values based on new fields
                
                if (invInfo.customerCountry != NULL && invInfo.customerCountry == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceParams = invoiceParams+'<TaxLabel1>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXLABEL_11+'</TaxLabel1>';
                    invoiceParams = invoiceParams+'<TaxCode1>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXCODE_1+'</TaxCode1>';
                    invoiceParams = invoiceParams+'<TaxLabel2>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXLABEL_12+'</TaxLabel2>';
                    invoiceParams = invoiceParams+'<TaxCode2>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXCODE_2+'</TaxCode2>';
                    invoiceParams = invoiceParams+'<TaxLabel3>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXLABEL_13+'</TaxLabel3>';
                    invoiceParams = invoiceParams+'<TaxCode3>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXCODE_3+'</TaxCode3>';
                    invoiceParams = invoiceParams+'<TaxLabel4>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXLABEL_14+'</TaxLabel4>';
                    invoiceParams = invoiceParams+'<TaxCode4>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXCODE_4+'</TaxCode4>';
                    invoiceParams = invoiceParams+'<TaxLabel5>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXLABEL_15+'</TaxLabel5>';
                    invoiceParams = invoiceParams+'<TaxCode5>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_TAXCODE_5+'</TaxCode5>';
                    if (invInfo.customerLanguage == 'ENG') {
                        invoiceParams = invoiceParams+'<Page1Footer>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_PAGEFOOTER_ENG+'</Page1Footer>';
                    } else {
                        invoiceParams = invoiceParams+'<Page1Footer>'+QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CANADA_PAGEFOOTER_FRC+'</Page1Footer>';
                    }
                }
                
                
                invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_XML_INVOICE_HEADER_END_TAG;
            }
            invoiceParams = invoiceParams+QTB_GenerateBillTrustExtractCTRL.BILLTRUST_XML_HEADER_END_TAG;
            
            Blob pageData;
            pageData = blob.valueOf(invoiceParams);
            
            Date tempDate = Date.today();
            String invDate = DateTime.newInstance(tempDate.year(),tempDate.month(),tempDate.day()).format('DDMMMYYYY');
            
            //Attach XML File to the Current invoice Record
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Network.
            
            
            DateTime myDateTime = System.now();
            String formatted = myDateTime.format('ddMMMyyyyhhmmss');
            system.debug(formatted);
            
             if (!isMassExtract) {
                if(invoiceStatus == QTB_Constants.INVOICE_STATUS_POSTED){
                //added getBillTrustFileName() method to display the name based on sandbox or prod ##25444
                    conVer.PathOnClient = canadaCountryPrefix +getBillTrustFileName()+formatted+'.xml';
                    conVer.Title = canadaCountryPrefix + getBillTrustFileName()+formatted+'.xml'; // Display name of the files
                } else {
                    conVer.PathOnClient = canadaCountryPrefix +getBillTrustFileName()+formatted+'.xml';
                    conVer.Title = canadaCountryPrefix + getBillTrustFileName()+formatted+'.xml'; // Display name of the files   
                }
                conVer.VersionData = pageData;//File content
                insert conVer;
                Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                
                QTB_Documents_Send_Lookup_Queue__c docSendLookup = new QTB_Documents_Send_Lookup_Queue__c();
                
                docSendLookup.QTB_Status__c = 'New';
                docSendLookup.QTB_Document_Receiver__c = 'Bill Trust';
                docSendLookup.QTB_Document_Country__c = legalCountry;
                //Logic to check if the extract generation is from Single Invoice/Credit Note
                if (referenceId != null && referenceId.contains(QTB_GenerateApexExtractVFCTRL.INVOICE_POSTED_BILLING_STATUS)) {
                    docSendLookup.QTB_Invoice__c= invoiceId;
                    docSendLookup.QTB_Document_Source__c = 'Invoice';
                } else {
                    docSendLookup.QTB_Credit_Note__c = invoiceId;
                    docSendLookup.QTB_Document_Source__c = 'Credit Note';
                }
                if (invoiceStatus == QTB_Constants.INVOICE_STATUS_POSTED) {
                    insert docSendLookup;
                }
                system.debug('docSendLookup'+docSendLookup.Id);
                
                //Create ContentDocumentLink for QTB_Documents_Send_Lookup_Queue__c object #5808
                
                list<ContentDocumentLink> contentDocList = new list<ContentDocumentLink>();
                ContentDocumentLink contentDoc = new ContentDocumentLink();
                contentDoc.ContentDocumentId = conDoc;
                contentDoc.LinkedEntityId = invoiceId; // We can use objectId,GroupId etc
                contentDoc.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                contentDoc.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                contentDocList.add(contentDoc);
                
                if (invoiceStatus == QTB_Constants.INVOICE_STATUS_POSTED) {
                    //Create ContentDocumentLink
                    ContentDocumentLink contentDoc1 = new ContentDocumentLink();
                    contentDoc1.ContentDocumentId = conDoc;
                    contentDoc1.LinkedEntityId = docSendLookup.id;
                    contentDoc1.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                    contentDoc1.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                    contentDocList.add(contentDoc1);
                }
                
                insert contentDocList;
                
                
            } else if (isMassExtract) {
                //Create 'QTB_Invoice_Backing_Report_Compression__c' record for creation of ZIP File
                // creating record in QTB_Documents_Send_Lookup_Queue__c object.
                QTB_Documents_Send_Lookup_Queue__c docSendLookup = new QTB_Documents_Send_Lookup_Queue__c();
                docSendLookup.QTB_Invoice_Scheduler__c = invSchedulerId;
                docSendLookup.QTB_Status__c = 'New';
                docSendLookup.QTB_Document_Source__c = 'Invoice Scheduler';
                docSendLookup.QTB_Document_Receiver__c = 'Bill Trust';
                docSendLookup.QTB_Document_Country__c = legalCountry;
                //docSendLookup.QTB_Credit_Note__c = invoiceId;
                if (invoiceStatus == 'Posted') {
                    insert docSendLookup;
                    system.debug('docSendLookup'+docSendLookup.Id);
                }
                 // added billTrustFileNameForSandbox() method to display the name based on sandbox or prod #25444
                conVer.PathOnClient = canadaCountryPrefix +getBillTrustFileName()+formatted+'.xml';
                conVer.Title = canadaCountryPrefix +getBillTrustFileName()+formatted+'.xml'; // Display name of the files
                
                conVer.VersionData = pageData;//File content
                insert conVer;
                Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                
                //Create ContentDocumentLink for QTB_Documents_Send_Lookup_Queue__c object #5807
                
                list<ContentDocumentLink> contentDocList = new list<ContentDocumentLink>();
                ContentDocumentLink contentDoc = new ContentDocumentLink();
                contentDoc.ContentDocumentId = conDoc;
                contentDoc.LinkedEntityId = invSchedulerId; // We can use objectId,GroupId etc
                contentDoc.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                contentDoc.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                contentDocList.add(contentDoc);
                
                if (invoiceStatus == 'Posted') {
                    //Create ContentDocumentLink
                    ContentDocumentLink contentDoc1 = new ContentDocumentLink();
                    contentDoc1.ContentDocumentId = conDoc;
                    contentDoc1.LinkedEntityId = docSendLookup.id;
                    contentDoc1.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                    contentDoc1.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                    contentDocList.add(contentDoc1);
                }
                
                insert contentDocList;
            }
        } catch(exception e) {
            system.debug('Inside exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateBillTrustExtractCTRL.generateTxt');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        } 
    }
    
    //calling VF page to generate CSV files
    public static void generateCSV(blng__Invoice__c Inv, String invZipId)
    {
        try
        {
            string recordID = Inv.id;
            String invNumber = Inv.QTB_Custom_Invoice_Number__c;
            //Call VF page to create the Data in proper CSV format
            PageReference vfPg = new PageReference ('/apex/QTB_GenerateUsageCSV');
            vfPg.getParameters().put('Id',recordID);
            Blob pageData;
            if(Test.isRunningTest()) { 
                pageData = blob.valueOf('Unit.Test');
            } else {
                pageData = vfPg.getContent();
            }
            //Attach CSV File to the Current invoice Record
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            conVer.PathOnClient = 'IRM_InvRep_'+invNumber+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv';
            conVer.Title = 'IRM_InvRep_'+invNumber+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv'; // Display name of the files
            conVer.VersionData = pageData;//File content
            insert conVer;
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            
            //Create ContentDocumentLink
            list<ContentDocumentLink> listcDe = new list<ContentDocumentLink>();
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId = recordID; // you can use objectId,GroupId etc
            cDe.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDe.Visibility = 'InternalUsers'; //AllUsers, InternalUsers, SharedUsers
            listcDe.add(cDe);
            
            if (invZipId != null) {
                ContentDocumentLink cDe1 = new ContentDocumentLink();
                cDe1.ContentDocumentId = conDoc;
                cDe1.LinkedEntityId = invZipId; // you can use objectId,GroupId etc
                cDe1.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDe1.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                listcDe.add(cDe1);
            }
            insert listcDe;
            
            //Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS for SITAD Posted Invoices
            if (Inv.blng__Account__r.QTB_SITAD__c && Inv.blng__InvoiceStatus__c == QTB_Constants.INVOICE_STATUS_POSTED) {
                //QTB_Documents_Send_Lookup_Queue__c object with backing up report details for SMS
                QTB_Documents_Send_Lookup_Queue__c docSendLookup = new QTB_Documents_Send_Lookup_Queue__c();
                docSendLookup.QTB_Status__c = 'New';
                docSendLookup.QTB_Document_Source__c = 'Invoice';
                docSendLookup.QTB_Document_Receiver__c = 'SMS';
                docSendLookup.QTB_Document_Country__c = Inv.blng__Account__r.QTB_Legal_Entity_Country__c;
                docSendLookup.QTB_Invoice__c = recordID;
                insert docSendLookup;
                
                //Create ContentDocumentLink for QTB_Documents_Send_Lookup_Queue__c
                list<ContentDocumentLink> contentDocList = new list<ContentDocumentLink>();
                ContentDocumentLink contentDoc = new ContentDocumentLink();
                contentDoc.ContentDocumentId = conDoc;
                contentDoc.LinkedEntityId = docSendLookup.id;
                contentDoc.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                contentDoc.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                contentDocList.add(contentDoc);
                
                insert contentDocList;
            }
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BillTrustUtil.generateCSV');
        }
    }
    
    /****************************************************************************************************************************************************
* Method : getSiteTaxDetailsMap
* Parameters: list<blng__Invoice__c> invoiceList
* Parameters: Boolean isInvoiceList
* Requirement : GITLAB-5483
* Start Date : 27/10/2021
* Author : Renuka Prasad
* Description: To get getSiteTaxDetailsMap
*******************************************************************************************************************************************************/
    public static Map<ID, Map<String, Decimal>> getSiteTaxDetailsMap(list<ID> eligibleIds, Boolean isInvoiceList) {
        
        Map<ID, Map<String, Decimal>> siteTaxDetailsMap = new Map<ID, Map<String, Decimal>>();
        try
        {
            list<QTB_Tax_Detail__c> taxDetails = new list<QTB_Tax_Detail__c>();
            if (isInvoiceList) {
                taxDetails = [Select Id,QTB_Invoice__c,QTB_Invoice_Line__c,QTB_Invoice_Line__r.blng__Invoice__c,QTB_Credit_Note_Line__c,
                              QTB_Imposition__c,QTB_ImpositionType__c,QTB_Jurisdiction__c,QTB_JurisdictionLevel__c,QTB_TaxType__c,QTB_CalculatedTax__c
                              from QTB_Tax_Detail__c where QTB_Invoice_Line__c IN :eligibleIds];
                
                
                for (QTB_Tax_Detail__c taxInfo: taxDetails) {
                    if (taxInfo.QTB_Invoice_Line__c != null && 
                        (taxInfo.QTB_Jurisdiction__c != null || taxInfo.QTB_Imposition__c != null) &&
                        taxInfo.QTB_CalculatedTax__c != null
                       ) {
                           String jurisdiction = (taxInfo.QTB_Jurisdiction__c != null) ? taxInfo.QTB_Jurisdiction__c : '';
                           String imposition = (taxInfo.QTB_Imposition__c != null) ? taxInfo.QTB_Imposition__c : '';
                           
                           Map<String, Decimal> tempTaxMap = new Map<String, Decimal>();
                           if (siteTaxDetailsMap.get(taxInfo.QTB_Invoice_Line__r.blng__Invoice__c) != null) {
                               tempTaxMap = siteTaxDetailsMap.get(taxInfo.QTB_Invoice_Line__r.blng__Invoice__c);
                               
                               if (tempTaxMap.get(jurisdiction + ' ' + imposition) != null) {
                                   Decimal taxAmount = tempTaxMap.get(jurisdiction + ' ' + imposition) + taxInfo.QTB_CalculatedTax__c;
                                   tempTaxMap.put(jurisdiction + ' ' + imposition, taxAmount);
                               } else {
                                   Decimal taxAmount = taxInfo.QTB_CalculatedTax__c;
                                   tempTaxMap.put(jurisdiction + ' ' + imposition, taxAmount);
                               }
                               
                               siteTaxDetailsMap.put(taxInfo.QTB_Invoice_Line__r.blng__Invoice__c, tempTaxMap);
                           } else {
                               
                               Decimal taxAmount = taxInfo.QTB_CalculatedTax__c;
                               tempTaxMap.put(jurisdiction + ' ' + imposition, taxAmount);
                               
                               siteTaxDetailsMap.put(taxInfo.QTB_Invoice_Line__r.blng__Invoice__c, tempTaxMap);
                           }
                       }
                }
            } else {
                taxDetails = [Select Id,QTB_Invoice__c,QTB_Invoice_Line__c,QTB_Credit_Note_Line__c,QTB_Credit_Note_Line__r.blng__CreditNote__c,
                              QTB_Imposition__c,QTB_ImpositionType__c,QTB_Jurisdiction__c,QTB_JurisdictionLevel__c,QTB_TaxType__c,QTB_CalculatedTax__c
                              from QTB_Tax_Detail__c where QTB_Credit_Note_Line__c IN :eligibleIds];
                
                for (QTB_Tax_Detail__c taxInfo: taxDetails) {
                    if (taxInfo.QTB_Credit_Note_Line__c != null &&
                        (taxInfo.QTB_Jurisdiction__c != null || taxInfo.QTB_Imposition__c != null) &&
                        taxInfo.QTB_CalculatedTax__c != null
                       ) {
                           String jurisdiction = (taxInfo.QTB_Jurisdiction__c != null) ? taxInfo.QTB_Jurisdiction__c : '';
                           String imposition = (taxInfo.QTB_Imposition__c != null) ? taxInfo.QTB_Imposition__c : '';
                           
                           Map<String, Decimal> tempTaxMap = new Map<String, Decimal>();
                           if (siteTaxDetailsMap.get(taxInfo.QTB_Credit_Note_Line__r.blng__CreditNote__c) != null) {
                               tempTaxMap = siteTaxDetailsMap.get(taxInfo.QTB_Credit_Note_Line__r.blng__CreditNote__c);
                               
                               if (tempTaxMap.get(jurisdiction + ' ' + imposition) != null) {
                                   Decimal taxAmount = tempTaxMap.get(jurisdiction + ' ' + imposition) + taxInfo.QTB_CalculatedTax__c;
                                   tempTaxMap.put(jurisdiction + ' ' + imposition, taxAmount);
                               } else {
                                   
                                   Decimal taxAmount = taxInfo.QTB_CalculatedTax__c;
                                   tempTaxMap.put(jurisdiction + ' ' + imposition, taxAmount);
                               }
                               
                               siteTaxDetailsMap.put(taxInfo.QTB_Credit_Note_Line__r.blng__CreditNote__c, tempTaxMap);
                           } else {
                               
                               Decimal taxAmount = taxInfo.QTB_CalculatedTax__c;
                               tempTaxMap.put(jurisdiction + ' ' + imposition, taxAmount);
                               
                               siteTaxDetailsMap.put(taxInfo.QTB_Credit_Note_Line__r.blng__CreditNote__c, tempTaxMap);
                           }
                       }
                }
            }
        } catch(exception e) {
            system.debug('Inside getAccountContactMap exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BillTrustUtil.getAccountServiceLocationMap');
        }
        return siteTaxDetailsMap;
    }
 /****************************************************************************************************************************************************
* Method : getBillTrustFileName
* Parameters: String billTrustFileName
* Requirement : GITLAB-25444
* Start Date : 02/08/2024
* Author : Sravya
* Description: Adding 'Non Prod' to the Bill Trust File to display the name for sandbox and prod differently to resolve the issue SIT files going into Billtrust production
*******************************************************************************************************************************************************/
 public static String getBillTrustFileName(){
    String billTrustFileName = '';
    boolean isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
   try{
    if(isSandbox){
        billTrustFileName = 'DM_S_BILLTRUST_TRANSACTION_NONPROD_';
    }else{
        billTrustFileName = 'DM_S_BILLTRUST_TRANSACTION_';
    }
   }
   catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BillTrustUtil.getBillTrustFileName');
        }
    return billTrustFileName;
}
  
}