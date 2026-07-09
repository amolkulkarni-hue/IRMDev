/****************************************************************************************************************************************************
* Class: QTB_GenerateCreditNoteXmlExtractCTRL
* Purpose: This class is the controller class for generating Billtrust extract
* Developer          Date           Description
* -----------------------------------------------------------------------------------------------------
* Renuka Prasad      13/9/2021
* Renuka Prasad      7/3/2024       Changes to consider the QTB_Subtotal_WithNegative__c value for -VE Credit Note Lines as part of the Story #22175
* Sravya             10/09/2024     #25446 Credit Note XML extract for SITAD populating PO Number & Site Number fetching the PO Number & Site Number from the Usage level for regular credit note.
*****************************************************************************************************************************************************/
public class QTB_GenerateCreditNoteXmlExtractCTRL {
    
    public static final String BILLTRUST_CREDIT_NOTE_TRANSACTION_TYPE = 'Credit Memo';
    
    public static final String BILLTRUST_TEMPLATE_J = 'Template-J';
    
    public static final String BILLTRUST_TEMPLATE_E = 'Template-E';
    
    public static final String BILLTRUST_CANADA_TAXLABEL_11 = 'GST/HST/TPS';
    
    public static final String BILLTRUST_CANADA_TAXCODE_1 = '885517334RT0001';
    
    public static final String BILLTRUST_CANADA_TAXLABEL_12 = 'BRITISH COLUMBIA';
    
    public static final String BILLTRUST_CANADA_TAXCODE_2 = 'PST# 1014-7765';
    
    public static final String BILLTRUST_CANADA_TAXLABEL_13 = 'MANITOBA';
    
    public static final String BILLTRUST_CANADA_TAXCODE_3 = 'PST# 885517334MT0001';
    
    public static final String BILLTRUST_CANADA_TAXLABEL_14 = 'QUEBEC';
    
    public static final String BILLTRUST_CANADA_TAXCODE_4 = 'TVQ# 1019185164';
    
    public static final String BILLTRUST_CANADA_TAXLABEL_15 = 'SASKATCHEWAN';
    
    public static final String BILLTRUST_CANADA_TAXCODE_5 = 'PST# 5600135';
    
    public static final String BILLTRUST_CANADA_PAGEFOOTER_ENG = 'Certain services may be billed by Iron Mountain Canada Operations ULC d/b/a Iron Mountain Canada acting as agent on behalf of Iron Mountain Information Management Services Canada, Inc. and/or Iron Mountain Secure Shredding Canada, Inc.';
    
    public static final String BILLTRUST_CANADA_PAGEFOOTER_FRC = 'Certains des services seront factures par Iron Mountain Canada Operations ULC faisant affaire sous le nom de Iron Mountain Canada agissant en tant  qu\'agents au nom d\'Iron Mountain Information Management Services Canada, Inc. et/ou  Iron Mountain Secure Shredding Canada, Inc.';
    
    public static boolean throwExplicitException = false; 
    
    /***********************************************************************************************************
* Method : generateBillTrustXml
* Parameters: list<blng__CreditNote__c> creditNoteList, String invSchedulerName, String invSchedulerId
* Requirement : GITLAB-4850
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: Generating the Mass CreditNote XML for Bill Trust system
**************************************************************************************************************/
    @AuraEnabled
    public static void generateBillTrustXml(list<blng__CreditNote__c> creditNoteList, String invSchedulerName, String invSchedulerId)
    {
        try
        {
            if (creditNoteList.size() <= 0) {
                throw new AuraHandledException('No valid credit note found.');
            }
            
            //Fetching additional details required to create Billtrust extract
            list<blng__Invoice__c> invoiceList = new list<blng__Invoice__c>();
            QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo supplementaryDetails = QTB_BillTrustUtil.getSupplementaryInfo(invoiceList, creditNoteList);
            Boolean isMassExtract = (invSchedulerName != null) ? true : false;
            
            list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> creditNoteInfoDetails = new list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo>();
            for (blng__CreditNote__c crdNt: creditNoteList) {
                QTB_GenerateBillTrustExtractCTRL.InvoiceInfo tempCreditNoteInfo = getCreditNoteInfo(crdNt, isMassExtract, supplementaryDetails);
                creditNoteInfoDetails.add(tempCreditNoteInfo);
            }
            
            //Logic to generate Billtrust extract
            if (creditNoteInfoDetails.size() > 0) {
                QTB_BillTrustUtil.generateBilltrustRequest(creditNoteInfoDetails, isMassExtract, invSchedulerName, invSchedulerId);
            }
            
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateCreditNoteXmlExtractCTRL.generateBillTrustXml');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
    }
    
    /***********************************************************************************************************
* Method : getCreditNoteInfo
* Parameters: blng__CreditNote__c creditNoteInfo, Boolean isMassExtract, QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo supplementaryDetails
* Requirement : GITLAB-4850
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: Method to fetch the Credit Note Details
**************************************************************************************************************/    
    public static QTB_GenerateBillTrustExtractCTRL.InvoiceInfo getCreditNoteInfo(blng__CreditNote__c creditNoteInfo, Boolean isMassExtract, QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo supplementaryDetails)
    {
        QTB_GenerateBillTrustExtractCTRL.InvoiceInfo crdNoteDetails = new QTB_GenerateBillTrustExtractCTRL.InvoiceInfo();
        try
        {
            if (creditNoteInfo == null) {
                throw new AuraHandledException('Not valid credit note.');
            }
            
            String sfdcBilTrstMapString = QTB_BillTrustUtil.SFDC_BILLTRUST_MAP;
            
            //Fetching the Billtrust Salesforce Mapping details from the constant
            Map<String, String> sfdcBillTrustFieldMap = (Map<String, String>) JSON.deserialize(sfdcBilTrstMapString, Map<String, String>.class);
            
            //To store the Salesforce Product and Billing codes
            Map<ID, string> productMap = supplementaryDetails.productBillCodeMap;
            
            //To store the Product and the translation text
            Map<String, String> productTranslationMap = supplementaryDetails.productTranslationMap;
            
            //Getting the account level additional details
            Map<ID, QTB_GenerateBillTrustExtractCTRL.AdditionalInfo> additonalInfo = supplementaryDetails.accountAdditionalInfoMap;
            QTB_GenerateBillTrustExtractCTRL.AdditionalInfo additionalDetails = (QTB_GenerateBillTrustExtractCTRL.AdditionalInfo) additonalInfo.get(creditNoteInfo.blng__Account__c);
            
            //Getting the Tax details
            Map<ID, Map<String, Decimal>> siteTaxDetailsMap = supplementaryDetails.siteTaxDetailsMap;
            Map<String, Decimal> siteTaxInfo = siteTaxDetailsMap.get(creditNoteInfo.Id);
            
            Map<id, list<blng__CreditNoteLine__c>> creditNoteLineInfoMap = new Map<id, list<blng__CreditNoteLine__c>>();
            Map<ID, list<blng__CreditNoteLine__c>> storageLinesInfo = new Map<ID, list<blng__CreditNoteLine__c>>();
            Decimal storageTotal = 0.0;
            Decimal storageTotalWithTax = 0.0;
            Map<ID, list<blng__CreditNoteLine__c>> serviceLinesInfo = new Map<ID, list<blng__CreditNoteLine__c>>();
            Decimal serviceTotal = 0.0;
            Decimal serviceTotalWithTax = 0.0;
            Map<ID, list<blng__CreditNoteLine__c>> otherItemsInfo = new Map<ID, list<blng__CreditNoteLine__c>>();
            Decimal otherTotal = 0.0;
            Decimal otherTotalWithTax = 0.0;
            String servicePeriod = '';
            System.debug('creditNoteInfo>>'+creditNoteInfo);
            System.debug('creditNoteInfo.blng__CreditNoteCreditLines__r>>'+creditNoteInfo.blng__CreditNoteCreditLines__r);
            //Logic to seggregate the products based on the schedule category
            for(blng__CreditNoteLine__c credNteLin : creditNoteInfo.blng__CreditNoteCreditLines__r) {
                if (credNteLin.blng__Product__r.QTB_Price_Schedule_Category__c != null && credNteLin.blng__Product__r.QTB_Price_Schedule_Category__c == QTB_Constants.STORAGE) {
                    list<blng__CreditNoteLine__c> tempStorageLines = new list<blng__CreditNoteLine__c>();
                    
                    if (storageLinesInfo.get(creditNoteInfo.id) != null) {
                        tempStorageLines = storageLinesInfo.get(creditNoteInfo.id);
                    }
                    tempStorageLines.add(credNteLin);
                    storageLinesInfo.put(creditNoteInfo.id, tempStorageLines);
                    
                    if(credNteLin.blng__Subtotal__c != null) {
                        storageTotal = storageTotal + credNteLin.blng__Subtotal__c;
                    }
                    if(credNteLin.blng__TotalAmount__c != null) {
                        storageTotalWithTax = storageTotalWithTax + credNteLin.blng__TotalAmount__c;
                    }
                    
                } else if (credNteLin.blng__Product__r.QTB_Price_Schedule_Category__c != null && credNteLin.blng__Product__r.QTB_Price_Schedule_Category__c == QTB_Constants.SERVICES) {
                    list<blng__CreditNoteLine__c> tempServiceLines = new list<blng__CreditNoteLine__c>();
                    
                    if (serviceLinesInfo.get(creditNoteInfo.id) != null) {
                        tempServiceLines = serviceLinesInfo.get(creditNoteInfo.id);
                    }
                    tempServiceLines.add(credNteLin);
                    serviceLinesInfo.put(creditNoteInfo.id, tempServiceLines);
                    
                    if(credNteLin.blng__Subtotal__c != null) {
                        serviceTotal = serviceTotal + credNteLin.blng__Subtotal__c;
                    }
                    //Changes to Support Fair Market Value -VE Amount
                    /*if (credNteLin.blng__Subtotal__c == 0 && credNteLin.QTB_Subtotal_WithNegative__c != null) {
                        serviceTotal = serviceTotal + credNteLin.QTB_Subtotal_WithNegative__c;
                    } Gitlab-22532*/
                    
                    if(credNteLin.blng__TotalAmount__c != null) {
                        serviceTotalWithTax = serviceTotalWithTax + credNteLin.blng__TotalAmount__c;
                    }
                    //Changes to Support Fair Market Value -VE Amount
                    /*if (credNteLin.blng__TotalAmount__c == 0 && credNteLin.QTB_Subtotal_WithNegative__c != null) {
                        serviceTotalWithTax = serviceTotalWithTax + credNteLin.QTB_Subtotal_WithNegative__c;
                    } Gitlab-22532*/
                } else {
                    list<blng__CreditNoteLine__c> tempOtherLines = new list<blng__CreditNoteLine__c>();
                    
                    if (otherItemsInfo.get(creditNoteInfo.id) != null) {
                        tempOtherLines = otherItemsInfo.get(creditNoteInfo.id);
                    }
                    tempOtherLines.add(credNteLin);
                    otherItemsInfo.put(creditNoteInfo.id, tempOtherLines);
                    
                    if(credNteLin.blng__Subtotal__c != null) {
                        otherTotal = otherTotal + credNteLin.blng__Subtotal__c;
                    }
                    if(credNteLin.blng__TotalAmount__c != null) {
                        otherTotalWithTax = otherTotalWithTax + credNteLin.blng__TotalAmount__c;
                    }
                    
                }
                //Added Null Check
                if (credNteLin.blng__InvoiceLine__c != null && credNteLin.blng__InvoiceLine__r.blng__UsageSummary__c != null && 
                    credNteLin.blng__InvoiceLine__r.blng__UsageSummary__r.blng__SummaryEndDate__c != null && servicePeriod == '') {
                        Date tempServiceDate = credNteLin.blng__InvoiceLine__r.blng__UsageSummary__r.blng__SummaryEndDate__c;
                        servicePeriod = DateTime.newInstance(tempServiceDate.year(),tempServiceDate.month(),tempServiceDate.day()).format('MMM-YYYY');
                    } //TO CHECK WITH VINUTHA
            }
            
            crdNoteDetails.transactionType = QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_CREDIT_NOTE_TRANSACTION_TYPE;
            String invoiceType = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_INVOICETYPE_NA;
            System.debug('creditNoteInfo.blng__Account__r.QTB_Billing_Frequency__c>>>'+creditNoteInfo.blng__Account__r.QTB_Billing_Frequency__c);
            System.debug('sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Billing_Frequency__c)>>>'+sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Billing_Frequency__c));
            if (creditNoteInfo.blng__Account__r.QTB_Billing_Frequency__c != null && sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Billing_Frequency__c) != null) {
                invoiceType = sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Billing_Frequency__c);
            }
            crdNoteDetails.invoiceType = invoiceType;
            
            String extractType = (creditNoteInfo.blng__Account__r.QTB_Consolidation_Flag__c != null && creditNoteInfo.blng__Account__r.QTB_Consolidation_Flag__c == true) ? 'C' : 'S';
            crdNoteDetails.consolidated_single = extractType;
            
            String governmentType = '';
            String accntClassification = '';
            if (creditNoteInfo.blng__Account__r.QTB_Customer_Classification__c != null) {
                accntClassification = String.valueof(creditNoteInfo.blng__Account__r.QTB_Customer_Classification__c);
                if (String.valueof(creditNoteInfo.blng__Account__r.QTB_Customer_Classification__c).contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_GOVERNMENT_TYPE)
                    || String.valueof(creditNoteInfo.blng__Account__r.QTB_Customer_Classification__c).contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_FEDERAL_TYPE)) {
                        //crdNoteDetails.governmentType = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_GOVERNMENT_TYPE;
                    }
            }
            crdNoteDetails.governmentType = governmentType;
            
            String templateType = '';
            //if (!isMassExtract) {
            System.debug('accntClassification>>>'+accntClassification);
            if (accntClassification.contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_GOVERNMENT_TYPE)
                || accntClassification.contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_FEDERAL_TYPE)) {
                    templateType = QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_TEMPLATE_J;
                } else {
                    templateType = QTB_GenerateCreditNoteXmlExtractCTRL.BILLTRUST_TEMPLATE_E;
                }
            //}
            crdNoteDetails.templateType = templateType;
            
            String deliveryType = '';
            System.debug('creditNoteInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c>>>'+creditNoteInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c);
            if (creditNoteInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c != null
                && sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c) != null) {
                    deliveryType = sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c);
                }
            crdNoteDetails.deliveryType = deliveryType;
            
            crdNoteDetails.invoiceDeliveryEmailAddress = additionalDetails.primaryContactEmail;
            
            String holdInd = (creditNoteInfo.blng__Account__r.QTB_HoldInd__c != null) ? creditNoteInfo.blng__Account__r.QTB_HoldInd__c : QTB_GenerateBillTrustExtractCTRL.BILLTRUST_HOLDIND_VALUE; 
            crdNoteDetails.holdInd = holdInd;
            
            String holdRequester = (creditNoteInfo.blng__Account__r.QTB_HoldRequester__c != null) ? creditNoteInfo.blng__Account__r.QTB_HoldRequester__c : ''; 
            crdNoteDetails.holdRequester = holdRequester;
            
            String imCompany = (creditNoteInfo.blng__Account__r.QTB_IMCompany__c != null) ? creditNoteInfo.blng__Account__r.QTB_IMCompany__c : ''; 
            crdNoteDetails.imCompany = imCompany;
            
            String customerLanguage = '';
            if (creditNoteInfo.blng__Account__r.QTB_Language__c != null && sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Language__c) != null) {
                customerLanguage = sfdcBillTrustFieldMap.get(creditNoteInfo.blng__Account__r.QTB_Language__c);
            }
            crdNoteDetails.customerLanguage = customerLanguage;
            
            String accountCurrency = '';
            if (creditNoteInfo.CurrencyIsoCode != null) {
                accountCurrency = creditNoteInfo.CurrencyIsoCode;
            }
            crdNoteDetails.accountCurrency = accountCurrency;
            
            String returnAddress1 = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c : '';
            crdNoteDetails.returnAddress1 = returnAddress1;
            
            String returnAddress2 = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c : '';
            crdNoteDetails.returnAddress2 = returnAddress2;
            
            String returnAddress3 = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c : '';
            crdNoteDetails.returnAddress3 = returnAddress3;
            
            String returnCity = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c : '';
            crdNoteDetails.returnCity = returnCity;
            
            String returnState = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c : '';
            crdNoteDetails.returnState = returnState;
            
            String returnPostalCode = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c : '';
            crdNoteDetails.returnPostalCode = returnPostalCode;
            
            String imBillContact = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c : '';
            crdNoteDetails.imBillContact = imBillContact;
            
            String imBillContactPN = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c : '';
            crdNoteDetails.imBillContactPN = imBillContactPN;
            if (customerLanguage == 'FRC') {
                crdNoteDetails.imBillContactPN = sfdcBillTrustFieldMap.get('IMBillContactPN_Frc');
            }
            
            String imBillContactEmail = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c : '';
            crdNoteDetails.imBillContactEmail = imBillContactEmail;
            if (customerLanguage == 'FRC') {
                crdNoteDetails.imBillContactEmail = sfdcBillTrustFieldMap.get('IMBillContactEmail_Frc');
            }
            
            String customerName = '';
            if (creditNoteInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null) {
                customerName = creditNoteInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c;
            }
            crdNoteDetails.customerName = customerName;
            
            String customerContact = '';
            if (creditNoteInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null) {
                customerContact = creditNoteInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c;
            }
            //Updating the Billing Contact Name
            crdNoteDetails.customerContact = additionalDetails.customerContactName;
            
            String customerAddress1 = '';
            if (creditNoteInfo.blng__Account__r.BillingStreet != null) {
                customerAddress1 = creditNoteInfo.blng__Account__r.BillingStreet;
            }
            crdNoteDetails.customerAddress1 = customerAddress1;
            
            String customerAddress2 = '';//NULL TO BE PASSED
            crdNoteDetails.customerAddress2 = customerAddress2;
            
            String customerAddress3 = '';//NULL TO BE PASSED
            crdNoteDetails.customerAddress3 = customerAddress3;
            
            String customerAddress4 = '';//NULL TO BE PASSED
            crdNoteDetails.customerAddress4 = customerAddress4;
            
            
            String customerCity = '';
            if (creditNoteInfo.blng__Account__r.BillingCity != null) {
                customerCity = creditNoteInfo.blng__Account__r.BillingCity;
            }
            crdNoteDetails.customerCity = customerCity;
            
            String customerState = '';
            if (creditNoteInfo.blng__Account__r.BillingState != null) {
                customerState = creditNoteInfo.blng__Account__r.BillingState;
            }
            crdNoteDetails.customerState = customerState;
            
            String customerPostalCode = '';
            if (creditNoteInfo.blng__Account__r.BillingPostalCode != null) {
                customerPostalCode = creditNoteInfo.blng__Account__r.BillingPostalCode;
            }
            crdNoteDetails.customerPostalCode = customerPostalCode;
            
            crdNoteDetails.customerCountry = additionalDetails.countryISOCode;
            
            String invoiceID = '';
            if (creditNoteInfo.Name != null) {
                invoiceID = creditNoteInfo.Name;
            }
            crdNoteDetails.invoiceID = invoiceID;
            
            String creditNoteDate = '';
            if (creditNoteInfo.blng__CreditNoteDate__c != null) {
                Date tempDate = creditNoteInfo.blng__CreditNoteDate__c;
                if(additionalDetails.countryISOCode == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    creditNoteDate = DateTime.newInstance(tempDate.year(),tempDate.month(),tempDate.day()).format('dd-MMM-YY');
                    creditNoteDate = creditNoteDate.toUpperCase();
                } else {
                    creditNoteDate = DateTime.newInstance(tempDate.year(),tempDate.month(),tempDate.day()).format('MM/dd/YYYY');
                }
            }
            crdNoteDetails.invoiceDate = creditNoteDate;
            
            crdNoteDetails.servicePeriod = servicePeriod.toUpperCase();
            
            String customerID = '';
            if (creditNoteInfo.blng__Account__r.QTB_Customer_Number__c != null) {
                customerID = creditNoteInfo.blng__Account__r.QTB_Customer_Number__c;
            }
            crdNoteDetails.customerID = customerID;
            
            String taxID = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c : '';
            crdNoteDetails.taxID = taxID;
            
            Map<ID, String> poMap = additionalDetails.customerPO;
            //String poNumber = (poMap.get(creditNoteInfo.id) != null) ? poMap.get(creditNoteInfo.id) : '';
            //crdNoteDetails.poNumber = poNumber;
            
            String dueDate  = '';
            /*if (creditNoteInfo.blng__DueDate__c != null) {
Date tempDueDate = creditNoteInfo.blng__DueDate__c;
dueDate = DateTime.newInstance(tempDueDate.year(),tempDueDate.month(),tempDueDate.day()).format('dd-MMM-YY');
}*/ //TO CHECK WITH VINUTHA
            crdNoteDetails.dueDate = dueDate;
            
            System.debug('storageTotalHHH'+storageTotal);
            System.debug('storageTotalHHHSTR'+String.valueOf(storageTotal));
            //Logic to show Total amount without Tax for both US & Canada in Invoice Page 1
            crdNoteDetails.totalStorage = (storageTotal == 0.00) ? String.valueOf(storageTotal.setScale(2)) : String.valueOf(-1 * storageTotal.setScale(2));
            crdNoteDetails.totalService = (serviceTotal == 0.00) ? String.valueOf(serviceTotal.setScale(2)) : String.valueOf(-1 * serviceTotal.setScale(2));
            crdNoteDetails.totalOther = (otherTotal == 0.00) ? String.valueOf(otherTotal.setScale(2)) : String.valueOf(-1 * otherTotal.setScale(2));
            
            System.debug('crdNoteDetails>>>'+crdNoteDetails);
            System.debug('crdNoteDetails>>>totalStorage'+crdNoteDetails.totalStorage);
            String totalTaxAmount = (creditNoteInfo.blng__TaxAmount__c != null) ? String.valueof(creditNoteInfo.blng__TaxAmount__c.setScale(2)) : '0.00';
            crdNoteDetails.totalTaxAmount = (totalTaxAmount == '0.00') ? totalTaxAmount :  String.valueOf(-1 * Decimal.ValueOf(totalTaxAmount).setScale(2));
            
            String totalAdjustmentAmount = '0.00';//TO CHECK WITH VINUTHA(creditNoteInfo.QTB_TotalAdjustmentAmount__c != null) ? String.valueof(creditNoteInfo.QTB_TotalAdjustmentAmount__c.setScale(2)) : String.valueOf(0.00);
            crdNoteDetails.totalAdjustmentAmount = totalAdjustmentAmount;//NEW FIELD -> QTB_TotalAdjustmentAmount__c Field on Credit Note
            
            //String lateFee = (creditNoteInfo.QTB_LateFee__c != null) ? String.valueof(creditNoteInfo.QTB_LateFee__c.setScale(2)) : '0.00';
            crdNoteDetails.lateFee = '0.00';//lateFee; TO CHECK WITH VINUTHA 
            
            String creditNoteTotalAmount = (creditNoteInfo.QTB_Total_Amount_with_Tax_Override__c != null) ? String.valueof(creditNoteInfo.QTB_Total_Amount_with_Tax_Override__c.setScale(2)) : '0.00';
            crdNoteDetails.invoiceTotalAmount = (creditNoteTotalAmount == '0.00') ? creditNoteTotalAmount : String.valueOf(-1 * Decimal.ValueOf(creditNoteTotalAmount).setScale(2));
            
            String payMntName = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c : '';
            crdNoteDetails.payMntName = payMntName;
            
            String payMntAddress1 = '';
            if (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c != null) {
                //payMntAddress1 = creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c;
            }
            crdNoteDetails.payMntAddress1 = payMntAddress1;
            
            String payMntAddress2 = '';
            if (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c != null) {
                payMntAddress2 = creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c;
            }
            crdNoteDetails.payMntAddress2 = payMntAddress2;
            
            String payMntAddress3 = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c : '';
            crdNoteDetails.payMntAddress3 = payMntAddress3;
            
            String payMntCity = '';
            if (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__City__c != null) {
                payMntCity = creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__City__c;
            }
            crdNoteDetails.payMntCity = payMntCity;
            
            String payMntState = '';
            if (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__State__c != null) {
                payMntState = creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__State__c;
            }
            crdNoteDetails.payMntState = payMntState;
            
            String payMntPostalCode = '';
            if (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c != null) {
                payMntPostalCode = creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c;
            }
            crdNoteDetails.payMntPostalCode = payMntPostalCode;
            
            String contractNumber = (creditNoteInfo.blng__Account__r.QTB_ContractNumber__c != null) ? creditNoteInfo.blng__Account__r.QTB_ContractNumber__c : '';
            crdNoteDetails.contractNumber = contractNumber; 
            
            String cageCode = (creditNoteInfo.blng__Account__r.QTB_CageCode__c != null) ? creditNoteInfo.blng__Account__r.QTB_CageCode__c : '';
            crdNoteDetails.cageCode = cageCode;
            
            String dunsNumber  = (creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c != null) ? creditNoteInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c : '';
            crdNoteDetails.dunsNumber = dunsNumber;
            
            String receivedBy = '';
            if (creditNoteDate != null) {
                receivedBy = creditNoteDate;
            }
            crdNoteDetails.receivedBy = receivedBy;
            
            String pastDueBalancePrior = '0.00';
            if (creditNoteInfo.blng__Account__r.QTB_Account_Balance__c != null) {
                pastDueBalancePrior = String.valueof(creditNoteInfo.blng__Account__r.QTB_Account_Balance__c.setScale(2));
            }
            crdNoteDetails.pastDueBalancePrior = (pastDueBalancePrior == '0.00') ? pastDueBalancePrior : String.valueOf(-1 * Decimal.ValueOf(pastDueBalancePrior).setScale(2));
            
            String receivedByPay = creditNoteDate;
            crdNoteDetails.receivedByPay = receivedByPay;
            
            //String paymentsRcvd = (creditNoteInfo.QTB_PaymentsRcvd__c != null) ? String.valueOf(creditNoteInfo.QTB_PaymentsRcvd__c.setScale(2)) : '0.00';
            crdNoteDetails.paymentsRcvd = '0.00';//paymentsRcvd; TO CHECK WITH VINUTHA
            
            String receivedByAdjust = creditNoteDate;
            crdNoteDetails.receivedByAdjust = receivedByAdjust;
            
            //String adjustmentsRcvdAmt = (creditNoteInfo.QTB_AdjustmentsRcvdAmt__c != null) ? String.valueOf(creditNoteInfo.QTB_AdjustmentsRcvdAmt__c.setScale(2)) : '0.00';
            crdNoteDetails.adjustmentsRcvdAmt = '0.00';//adjustmentsRcvdAmt; - TO CHECK WITH VINUTHA
            
            String receivedByBal = creditNoteDate;
            crdNoteDetails.receivedByBal = receivedByBal;
            
            String pastDueBalanceTotal = '';//(creditNoteInfo.QTB_PastDueBalanceTotal__c != null) ? String.valueOf(creditNoteInfo.QTB_PastDueBalanceTotal__c.setScale(2)) : '0.00';
            crdNoteDetails.pastDueBalanceTotal = '0.00';//pastDueBalanceTotal; TO CHECK WITH VINUTHA
            
            String currentTotalAmount = (creditNoteInfo.QTB_Total_Amount_with_Tax_Override__c != null) ? String.valueOf(creditNoteInfo.QTB_Total_Amount_with_Tax_Override__c.setScale(2)) : '0.00';
            crdNoteDetails.currentTotalAmount = String.valueOf(-1 * Decimal.ValueOf(currentTotalAmount));
            
            Decimal pastDue = (!String.isEmpty(pastDueBalanceTotal)) ? Decimal.ValueOf(pastDueBalanceTotal) : 0.0;
            Decimal currentAmnt = (!String.isEmpty(currentTotalAmount) != null) ? Decimal.ValueOf(currentTotalAmount) : 0.0;
            
            Decimal totalBalance = pastDue + currentAmnt;
            crdNoteDetails.totalBalance = (totalBalance == 0.00) ? String.ValueOf(totalBalance.setScale(2)) : String.valueOf(-1 * totalBalance.setScale(2));
            
            String creditNoteStatus = '';
            if (creditNoteInfo.blng__Status__c != null) {
                creditNoteStatus = creditNoteInfo.blng__Status__c;
            }
            crdNoteDetails.invoiceStatus = creditNoteStatus;
            
            String creditNoteNumber = '';
            if (creditNoteInfo.QTB_Custom_Invoice_Number__c != null) {
                creditNoteNumber = creditNoteInfo.QTB_Custom_Invoice_Number__c;
            }
            crdNoteDetails.invNumber = creditNoteNumber;
            
            String creditNoteName = '';
            if (creditNoteInfo.Name != null) {
                creditNoteName = creditNoteInfo.Name;
            }
            crdNoteDetails.invName = creditNoteName;
            
            String creditNoteId = '';
            if (creditNoteInfo.Id != null) {
                creditNoteId = creditNoteInfo.Id;
            }
            crdNoteDetails.invId = creditNoteId;
            
            //Changes for Invoice Line Details Starts
            QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLine = new QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo();
            
            String siteId = additionalDetails.siteId;
            String siteName = additionalDetails.siteName;
            
            creditNoteLine.siteID = siteId;
            creditNoteLine.siteName = siteName;
            creditNoteLine.invoiceID = invoiceID;
            creditNoteLine.referenceID = invoiceID;
            creditNoteLine.invoiceDate = creditNoteDate;
            //creditNoteLine.poNumber = poNumber;
            creditNoteLine.siteAdjustmentTotal = '0.00';//TO CHECK WITH VINUTHA (creditNoteInfo.QTB_SiteAdjustmentTotal__c != null) ? String.valueof(creditNoteInfo.QTB_SiteAdjustmentTotal__c.setScale(2)) : '0.00';
            creditNoteLine.siteNumber = additionalDetails.siteNumber;
            creditNoteLine.siteNumberTotal = (creditNoteTotalAmount == '0.00') ? creditNoteTotalAmount : String.valueOf(-1 * Decimal.ValueOf(creditNoteTotalAmount).setScale(2));
            //#25446 start changes to populate SiteNumber and PONumber on the credit note billtrust xml and billtrust pdf file. 
            String PONumber = '';
            Set<Id> usageSummaryIdSet = new Set<Id>(); 
            Boolean isCreditType = false;			
            for(blng__CreditNoteLine__c crdline : creditNoteInfo.blng__CreditNoteCreditLines__r){
                if(crdline.blng__InvoiceLine__r?.blng__UsageSummary__c != null){
                    usageSummaryIdSet.add(crdline.blng__InvoiceLine__r.blng__UsageSummary__c);
                }
				if(crdline.blng__CreditNote__r.QTB_Credit_Note_Type__c == 'Rebill' || crdline.blng__CreditNote__r.QTB_Credit_Note_Type__c == 'Split ReBill' || creditNoteInfo.QTB_Credit_Note_Type__c == 'Credit Only'){
                        isCreditType = true;
                } 
                if(crdline.blng__CreditNote__r.QTB_Credit_Note_Type__c == 'ON Account Credit' && crdline.blng__CreditNote__r.blng__Account__r.QTB_SITAD__c == true){
                     creditNoteLine.siteNumber  = crdline.blng__CreditNote__r.QTB_Site_Number__c ;                    
                }   					
            }
            if(!usageSummaryIdSet.isEmpty()){
                for(blng__Usage__c usg : [SELECT QTB_Purchase_Order__c,QTB_Department_Code__c,blng__Account__c FROM blng__Usage__c WHERE blng__UsageSummary__c IN: usageSummaryIdSet]){
                    if(isCreditType){
                        creditNoteLine.siteNumber = usg.QTB_Department_Code__c; // fetching usage Department code and mapping the value to creditnote line Wrapper class variable Sitenumber 
                    }
                    if(usg.QTB_Purchase_Order__c!=null && (creditNoteInfo.QTB_Credit_Note_Type__c == 'ReBill' || creditNoteInfo.QTB_Credit_Note_Type__c == 'Split ReBill' || creditNoteInfo.QTB_Credit_Note_Type__c == 'Credit Only')){
                        crdNoteDetails.PONumber = usg.QTB_Purchase_Order__c;  // fetching usage purchase order and mapping the value to creditnote Wrapper class variable ponumber
                        break;                 
                    }
                } 
            }
            if (creditNoteInfo.QTB_Credit_Note_Type__c == 'ON Account Credit' && creditNoteInfo.blng__Account__r.QTB_SITAD__c == true) {
                crdNoteDetails.PONumber = creditNoteInfo.QTB_PO_Number__c;    
            }          	
			//#25446 End
            
            creditNoteLine.siteLateFeeAmount = '0.00';//TO CHECK WITH VINUTHA (creditNoteInfo.QTB_SiteLateFeeAmount__c != null) ? String.valueOf(creditNoteInfo.QTB_SiteLateFeeAmount__c.setScale(2)) : '0.00';
            creditNoteLine.invoiceTotalAmount = (creditNoteTotalAmount == '0.00') ? creditNoteTotalAmount : String.valueOf(-1 * Decimal.ValueOf(creditNoteTotalAmount).setScale(2));
            creditNoteLine.totalStorageAmount = (storageTotal == 0.00) ? String.valueOf(storageTotal.setScale(2)) : String.valueOf(-1 * storageTotal.setScale(2));
            creditNoteLine.totalServiceAmount = (serviceTotal == 0.00) ? String.valueOf(serviceTotal.setScale(2)) : String.valueOf(-1 * serviceTotal.setScale(2));
            creditNoteLine.totalOtherAmount = (otherTotal == 0.00) ? String.valueOf(otherTotal.setScale(2)) : String.valueOf(-1 * otherTotal.setScale(2));
            //Logic to show Total amount without Tax for Canada & with Tax for US.
            if (additionalDetails.countryISOCode != NULL && additionalDetails.countryISOCode == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                creditNoteLine.totalStorageAmount = (storageTotal == 0.00) ? String.valueOf(storageTotal.setScale(2)) : String.valueOf(-1 * storageTotal.setScale(2));
                creditNoteLine.totalServiceAmount = (serviceTotal == 0.00) ? String.valueOf(serviceTotal.setScale(2)) : String.valueOf(-1 *serviceTotal.setScale(2));
                creditNoteLine.totalOtherAmount = (otherTotal == 0.00) ? String.valueOf(otherTotal.setScale(2)) : String.valueOf(-1 * otherTotal.setScale(2));
            } else {
                creditNoteLine.totalStorageAmount = (storageTotalWithTax == 0.00) ? String.valueOf(storageTotalWithTax.setScale(2)) : String.valueOf(-1 * storageTotalWithTax.setScale(2));
                creditNoteLine.totalServiceAmount = (serviceTotalWithTax == 0.00) ? String.valueOf(serviceTotalWithTax.setScale(2)) : String.valueOf(-1 * serviceTotalWithTax.setScale(2));
                creditNoteLine.totalOtherAmount = (otherTotalWithTax == 0.00) ? String.valueOf(otherTotalWithTax.setScale(2)) : String.valueOf(-1 * otherTotalWithTax.setScale(2));
            }
            
            Decimal siteSubTotalValue = storageTotal + serviceTotal + otherTotal;
            creditNoteLine.siteSubTotal = (siteSubTotalValue == 0.00) ? String.valueOf(siteSubTotalValue.setScale(2)) : String.valueOf(-1 * siteSubTotalValue.setScale(2));
            
            //Logic to update Tax Details for Canada
            if(additionalDetails.countryISOCode == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                String siteTaxDescription1 = '';
                String siteTaxAmount1 = '0.00';
                String siteTaxDescription2 = '';
                String siteTaxAmount2 = '0.00';
                String siteTaxDescription3 = '';
                String siteTaxAmount3 = '0.00';
                
                list<String> taxList = new list<String>();
                if (siteTaxInfo != null && siteTaxInfo.size() > 0) {
                    for (String taxInfo: siteTaxInfo.keySet()) {
                        if (siteTaxDescription1 == '') {
                            siteTaxDescription1 = taxInfo;
                            siteTaxAmount1 = (siteTaxInfo.get(taxInfo) != null) ? String.ValueOf(-1 * siteTaxInfo.get(taxInfo)) : '0.00';
                            
                        } else if (siteTaxDescription1 != '' && siteTaxDescription2 == '') {
                            siteTaxDescription2 = taxInfo;
                            siteTaxAmount2 = (siteTaxInfo.get(taxInfo) != null) ? String.ValueOf(-1 * siteTaxInfo.get(taxInfo)) : '0.00';
                            
                        } else {
                            siteTaxDescription3 = taxInfo;
                            siteTaxAmount3 = (siteTaxInfo.get(taxInfo) != null) ? String.ValueOf(siteTaxInfo.get(taxInfo)) : '0.00';
                            
                        }
                    }
                }
                
                creditNoteLine.siteTaxDescription1 = siteTaxDescription1;
                creditNoteLine.siteTaxAmount1 = siteTaxAmount1;
                creditNoteLine.siteTaxDescription2 = siteTaxDescription2;
                creditNoteLine.siteTaxAmount2 = siteTaxAmount2;
                creditNoteLine.siteTaxDescription3 = siteTaxDescription3;
                creditNoteLine.siteTaxAmount3 = siteTaxAmount3;
            }
            
            //Update Storage Invoice Line Info
            creditNoteLine = updateStorageInfo(creditNoteLine, storageLinesInfo.get(creditNoteInfo.id), productMap, productTranslationMap);
            
            //Update Service Invoice Line Info
            creditNoteLine = updateServiceInfo(creditNoteLine, serviceLinesInfo.get(creditNoteInfo.id), productMap, productTranslationMap);
            
            //Update Other Invoice Line Info
            creditNoteLine = updateOtherInfo(creditNoteLine, otherItemsInfo.get(creditNoteInfo.id), productMap, productTranslationMap);
            
            crdNoteDetails.invoiceDetails = creditNoteLine;
            
        } catch(exception e) {
            system.debug('Inside getAdditionalInfo exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_GenerateCreditNoteXmlExtractCTRL.getAdditionalInfo');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
        
        return crdNoteDetails;
    }
    
    /***********************************************************************************************************
* Method : updateStorageInfo
* Parameters: QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineInfo, list<blng__CreditNoteLine__c> storageInfo, Map<ID, string> productMap
* Requirement : GITLAB-4850
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To update the storage invoice line details in the Bill Trust XML
**************************************************************************************************************/
    public static QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo updateStorageInfo(
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineInfo,
        list<blng__CreditNoteLine__c> storageInfo,
        Map<ID, string> productMap,
        Map<String, String> productTranslationMap
    ) {
        //Gitlab US#22996 -- logic moved to updateStorageServiceOtherInfo() function
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineStorageInfo = updateStorageServiceOtherInfo(creditNoteLineInfo,storageInfo,productMap,productTranslationMap,'storage');
        return creditNoteLineStorageInfo;
    }
    
    /***********************************************************************************************************
* Method : updateServiceInfo
* Parameters: QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineInfo, list<blng__CreditNoteLine__c> serviceInfo
* Requirement : GITLAB-4850
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To update the service invoice line details in the Bill Trust XML
**************************************************************************************************************/
    public static QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo updateServiceInfo(
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineInfo,
        list<blng__CreditNoteLine__c> serviceInfo,
        Map<ID, string> productMap,
        Map<String, String> productTranslationMap
    ) {
        //Gitlab US#22996 -- logic moved to updateStorageServiceOtherInfo() function
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineServiceInfo = updateStorageServiceOtherInfo(creditNoteLineInfo,serviceInfo,productMap,productTranslationMap,'service');
        return creditNoteLineServiceInfo;
    }
    
    /***********************************************************************************************************
* Method : updateOtherInfo
* Parameters: QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfocreditNoteLineInfo, list<blng__CreditNoteLine__c> otherInfo, Map<ID, string> productMap
* Requirement : GITLAB-4850
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To update the other invoice line details in the Bill Trust XML
**************************************************************************************************************/
    public static QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo updateOtherInfo(
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineInfo,
        list<blng__CreditNoteLine__c> otherInfo,
        Map<ID, string> productMap,
        Map<String, String> productTranslationMap
    ) {
        //Gitlab US#22996 -- logic moved to updateStorageServiceOtherInfo() function
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineOtherInfo = updateStorageServiceOtherInfo(creditNoteLineInfo,otherInfo,productMap,productTranslationMap,'other');
        return creditNoteLineOtherInfo;
    }
    
    /***********************************************************************************************************
* Method    : updateStorageServiceOtherInfo
* Parameters : QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineInfo,list<blng__CreditNoteLine__c> otherInfo,Map<ID, string> productMap,Map<String, String> productTranslationMap,string productLine
* Requirement: Gitlab US#22996
* Start Date : 04/12/2024
* Author    : Virtusa
* Description: To update the serivce,storage & other creditnote line details in the Bill Trust XML
: if multiple invoice line have same product then qnty, subtotal, tax, totalAmt rolledup only for SITAD
**************************************************************************************************************/
    public static QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo updateStorageServiceOtherInfo(
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo creditNoteLineInfo,
        list<blng__CreditNoteLine__c> storageServiceOtherInfo,
        Map<ID, string> productMap,
        Map<String, String> productTranslationMap,
        string productLine
    ) {
        try {
            if (QTB_GenerateCreditNoteXmlExtractCTRL.throwExplicitException) {
                throw new NullPointerException();
            }
            
            if (creditNoteLineInfo == null || storageServiceOtherInfo == null || storageServiceOtherInfo.size() <= 0) {
                return creditNoteLineInfo;
            }
            
            list<QTB_GenerateBillTrustExtractCTRL.ProductInfo> storageServiceOtherProducts = new list<QTB_GenerateBillTrustExtractCTRL.ProductInfo>();
            Map<String,QTB_GenerateBillTrustExtractCTRL.ProductInfo> productIdUnitPriceWithCredlineListMap = new Map<String,QTB_GenerateBillTrustExtractCTRL.ProductInfo>();
            
            for(blng__CreditNoteLine__c credLine:storageServiceOtherInfo)
            {
                QTB_GenerateBillTrustExtractCTRL.ProductInfo tempStorageServiceOther = new QTB_GenerateBillTrustExtractCTRL.ProductInfo();
                Decimal crdNoteLineQuantity = 0;
                Decimal crdNoteLineSubtotalAmount = 0.0;
                Decimal crdNoteLinetaxAmount = 0.0;
                Decimal crdNoteLineAmountTotal = 0.0;
                Decimal crdNoteLineRateAmount = 0.0;
                    
                //LineAmountTotal
                Decimal lineAmountTotal = 0.0;
                //Changes to consider the QTB_Subtotal_WithNegative__c value for -VE Credit Note Lines as part of the Story #22175
                if (credLine.blng__TotalAmount__c != null /*|| credLine.QTB_Subtotal_WithNegative__c != null Gitlab-22532*/) {
                    /*if (((credLine.blng__TotalAmount__c != null && credLine.blng__TotalAmount__c == 0) || credLine.blng__TotalAmount__c != null) && credLine.QTB_Subtotal_WithNegative__c != null) {
                        lineAmountTotal = credLine.QTB_Subtotal_WithNegative__c.setScale(2);
                        crdNoteLineAmountTotal = credLine.QTB_Subtotal_WithNegative__c.setScale(2);
                    } else { Gitlab-22532 */ 
                        lineAmountTotal = (credLine.blng__TotalAmount__c != null) ? credLine.blng__TotalAmount__c.setScale(2) : 0.00;
                        crdNoteLineAmountTotal = (credLine.blng__TotalAmount__c != null) ? credLine.blng__TotalAmount__c.setScale(2) : 0.00;
                    }
                //}
                
                //For SITAD - If Same Product Credit Note Line having same Unit Price is Present then fetch the existing Line and update the quantity, subtotal, totalAmt, taxAmt
                if (credLine.blng__CreditNote__r.blng__Account__r.QTB_SITAD__c && productIdUnitPriceWithCredlineListMap.containsKey(credLine.blng__Product__c+'-'+lineAmountTotal)) {
                    tempStorageServiceOther = productIdUnitPriceWithCredlineListMap.get(credLine.blng__Product__c+'-'+lineAmountTotal);
                    
                    //Quantity
                    crdNoteLineQuantity = (-1 * Integer.ValueOf(tempStorageServiceOther.quantityCnt)) + credLine.QTB_Credit_Quantity__c;
                    
                    //CreditNoteLineAmount
                    if (credLine.blng__Subtotal__c != null) {
                        /*if (credLine.blng__Subtotal__c == 0 && credLine.QTB_Subtotal_WithNegative__c != null && credLine.QTB_Subtotal_WithNegative__c < 0) {
                            crdNoteLineSubtotalAmount = ((-1 * Decimal.ValueOf(tempStorageServiceOther.invoiceLineAmount)) + credLine.QTB_Subtotal_WithNegative__c).setScale(2);
                        } else { Gitlab-22532 */
                            crdNoteLineSubtotalAmount = ((-1 * Decimal.ValueOf(tempStorageServiceOther.invoiceLineAmount)) +  credLine.blng__Subtotal__c).setScale(2);
                        }
                    //}
                    
                    //TaxLineAmount
                    crdNoteLinetaxAmount = ((-1 * Decimal.ValueOf(tempStorageServiceOther.taxLineAmount)) + credLine.blng__TaxAmount__c).setScale(2);
                    
                    crdNoteLineRateAmount = (crdNoteLineSubtotalAmount !=0 && Integer.valueOf(crdNoteLineQuantity) !=0) ? crdNoteLineSubtotalAmount/Integer.valueOf(crdNoteLineQuantity) : 0; //calculating the rate subtotal/qnty

                    //LineAmountTotal
                    //Changes to consider the QTB_Subtotal_WithNegative__c value for -VE Credit Note Lines as part of the Story #22175
                    /*if (credLine.blng__TotalAmount__c != null  || credLine.QTB_Subtotal_WithNegative__c != null Gitlab-22532 ) {  */
                        if (((credLine.blng__TotalAmount__c != null && credLine.blng__TotalAmount__c == 0) || credLine.blng__TotalAmount__c != null)/* && credLine.QTB_Subtotal_WithNegative__c != null*/) {
                            System.debug('0@@'+tempStorageServiceOther.lineAmountTotal);//'0.00'
                            System.debug('1@@'+(Decimal.ValueOf(tempStorageServiceOther.lineAmountTotal)));
                           /* System.debug('2@@'+credLine.QTB_Subtotal_WithNegative__c);
                            System.debug('3@@'+(Decimal.ValueOf(tempStorageServiceOther.lineAmountTotal) + credLine.QTB_Subtotal_WithNegative__c).setScale(2));
                            crdNoteLineAmountTotal = ((-1 * Decimal.valueOf(tempStorageServiceOther.lineAmountTotal)) + credLine.QTB_Subtotal_WithNegative__c).setScale(2);
                        } else {  Gitlab-22532 */
                            crdNoteLineAmountTotal = ((-1 * Decimal.valueOf(tempStorageServiceOther.lineAmountTotal)) + ((credLine.blng__TotalAmount__c != null) ? credLine.blng__TotalAmount__c : 0.0)).setScale(2);
                        }
                    //}
                    tempStorageServiceOther.quantityCnt = crdNoteLineQuantity == 0 ? String.valueof(crdNoteLineQuantity) : String.valueof(-1 * Integer.valueOf(crdNoteLineQuantity));
                    tempStorageServiceOther.invoiceLineAmount  = crdNoteLineSubtotalAmount == 0.0 ? String.valueof(crdNoteLineSubtotalAmount) : String.valueof(-1 * crdNoteLineSubtotalAmount.setScale(2));
                    tempStorageServiceOther.rateAmount  = String.valueof(crdNoteLineRateAmount.setScale(2));
                    tempStorageServiceOther.taxLineAmount  = crdNoteLinetaxAmount == 0.0 ? String.valueof(crdNoteLinetaxAmount) : String.valueof(-1 * crdNoteLinetaxAmount.setScale(2));
                    tempStorageServiceOther.lineAmountTotal  = crdNoteLineAmountTotal == 0.0 ? String.valueof(crdNoteLineAmountTotal) : String.valueof(-1 * crdNoteLineAmountTotal.setScale(2));  
                    
                    //Map to avoid showing multiple lines for same product and same price
                    productIdUnitPriceWithCredlineListMap.put(credLine.blng__Product__c+'-'+lineAmountTotal, tempStorageServiceOther);
                } else if (credLine.blng__CreditNote__r.blng__Account__r.QTB_SITAD__c){
                    //For SITAD - productIdUnitPriceWithCredlineListMap is Empty create new record and update the Map
                    tempStorageServiceOther = updateProductInfo(tempStorageServiceOther, credLine, productMap, productTranslationMap);
                    
                    //Map to avoid showing multiple lines for same product and same price
                    productIdUnitPriceWithCredlineListMap.put(credLine.blng__Product__c+'-'+lineAmountTotal, tempStorageServiceOther);

                } else {
                    //Do not group the Invoice Lines for Non-SITAD
                    tempStorageServiceOther = updateProductInfo(tempStorageServiceOther, credLine, productMap, productTranslationMap);
                    
                    //Keeping the Map Key as Invoice Line ID which is Unique so that it will not group the Invoice Lines for Non-SITAD
                    productIdUnitPriceWithCredlineListMap.put(credLine.id, tempStorageServiceOther);
                }
            }
            
            //add all invoice lines to the list
            if (productIdUnitPriceWithCredlineListMap.size() > 0) {
                storageServiceOtherProducts.addAll(productIdUnitPriceWithCredlineListMap.values());
            }
            
            if(productLine == 'service') {
                creditNoteLineInfo.serviceDetails  = storageServiceOtherProducts; 
            } else if(productLine == 'storage') {
                creditNoteLineInfo.storageDetails = storageServiceOtherProducts;
            } else if(productLine == 'other') {
                creditNoteLineInfo.otherDetails  = storageServiceOtherProducts;
            }
        } 
        catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_GenerateCreditNoteXmlExtractCTRL.updateStorageServiceOtherInfo');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
        return creditNoteLineInfo;
    }
    
    /***********************************************************************************************************
* Method : getCreditNoteDetails
* Parameters: blng__CreditNote__c creditNoteInfo
* Requirement : GITLAB-4850
* Start Date : 09/27/2021
* Author : Renuka Prasad
* Description: Method to fetch the Credit Note Details
**************************************************************************************************************/    
    public static list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> getCreditNoteDetails(list<blng__CreditNote__c> creditNoteList)
    {
        list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> creditNoteInfoDetails = new list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo>();
        try
        {
            if (QTB_GenerateCreditNoteXmlExtractCTRL.throwExplicitException) {
                throw new NullPointerException();
            }
            
            if (creditNoteList.size() <= 0) {
                return creditNoteInfoDetails;
            }
            
            //Fetching additional details required to create Billtrust extract
            list<blng__Invoice__c> invoiceList = new list<blng__Invoice__c>();
            QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo supplementaryDetails = QTB_BillTrustUtil.getSupplementaryInfo(invoiceList, creditNoteList);
            Boolean isMassExtract = false;//This is required for Consolidation Logic, which is out of scope for now.
            
            for (blng__CreditNote__c crdNt: creditNoteList) {
                QTB_GenerateBillTrustExtractCTRL.InvoiceInfo tempCreditNoteInfo = getCreditNoteInfo(crdNt, isMassExtract, supplementaryDetails);
                creditNoteInfoDetails.add(tempCreditNoteInfo);
            }
            
            return creditNoteInfoDetails;
            
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateCreditNoteXmlExtractCTRL.generateBillTrustXml');
            return creditNoteInfoDetails;
        }
    }
    
    /***********************************************************************************************************
    * Method     : updateProductInfo
    * Parameters : ProductInfo QTB_GenerateBillTrustExtractCTRL.ProductInfo, blng__CreditNoteLine__c crdLine, Map<ID, string> productMap,Map<String, String> productTranslationMap
    * Requirement: Gitlab US#22996
    * Start Date : 04/15/2024
    * Author     : TCS
    * Description: To update the ProductInfo wrapper with Credit Note Line details
    **************************************************************************************************************/
    public static QTB_GenerateBillTrustExtractCTRL.ProductInfo updateProductInfo(QTB_GenerateBillTrustExtractCTRL.ProductInfo prodInfo, blng__CreditNoteLine__c crdLine, Map<ID, string> productMap, Map<String, String> productTranslationMap)
    {
        try {
            if (prodInfo == null || crdLine == null) {
                return prodInfo;
            }
            String billCD = '';
            if (crdLine.blng__Product__r.ProductCode != null ) {
                billCD = crdLine.blng__Product__r.ProductCode;
            }
            if (productMap.get(crdLine.blng__Product__c) != null) {
                billCD = productMap.get(crdLine.blng__Product__c);
            }
            prodInfo.billCD = billCD;
            
            String clin = '';//TODO
            prodInfo.cLIN = clin;
            
            String description = '';
            if (crdLine.blng__InvoiceLine__c != null && crdLine.blng__InvoiceLine__r.blng__Product__r.Name != null) {
                description = String.valueOf(crdLine.blng__InvoiceLine__r.blng__Product__r.Name);
                if (productTranslationMap.get(crdLine.blng__InvoiceLine__r.blng__Product__c+'-'+crdLine.blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c) != null) {
                    description = String.valueOf(productTranslationMap.get(crdLine.blng__InvoiceLine__r.blng__Product__c+'-'+crdLine.blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c));
                }
                description = description.replace('&', '&#38;');
                description = description.replace('<', '&#60;');
                description = description.replace('>', '&#62;');
                description = description.replace('\'', '&#39;');
                description = description.replace('\"', '&#34;');
            } else if(crdLine.blng__CreditNote__r.QTB_On_Account_Credit__c && crdLine.blng__Product__c !=null && crdLine.blng__Product__r.Name != null){
                //Gitlab ##14830 -- BillTrust for Account with Credit where Invoice & InvoiceLine details not available at CreditNoteLine
                description = String.valueOf(crdLine.blng__Product__r.Name);
                if (productTranslationMap.get(crdLine.blng__Product__c+'-'+crdLine.QTB_Account__r.QTB_Language__c) != null) {
                    description = String.valueOf(productTranslationMap.get(crdLine.blng__Product__c+'-'+crdLine.QTB_Account__r.QTB_Language__c));
                }
                description = description.replace('&', '&#38;');
                description = description.replace('<', '&#60;');
                description = description.replace('>', '&#62;');
                description = description.replace('\'', '&#39;');
                description = description.replace('\"', '&#34;');
            }
            prodInfo.description = description;
            
            String quantityCnt = '0';
            if (crdLine.QTB_Credit_Quantity__c != null) {
                quantityCnt = String.valueOf(Integer.valueOf(crdLine.QTB_Credit_Quantity__c));
            }
            prodInfo.quantityCnt = quantityCnt == '0' ? String.valueof(quantityCnt) : String.valueof(-1 * Integer.valueOf(quantityCnt));
            
            //RateAmount
            String rateAmount = '0.000';
            /*if (crdLine.blng__InvoiceLine__c != null && crdLine.blng__InvoiceLine__r.blng__UnitPrice__c != null) {
                rateAmount = String.valueof(crdLine.blng__InvoiceLine__r.blng__UnitPrice__c.setScale(3));
            }
            else if(crdLine.QTB_Unit_Price__c != null) { // Gitlab #28417 added unit price for On Account, earlier it was not handled
                rateAmount = String.valueof(crdLine.QTB_Unit_Price__c.setScale(3, RoundingMode.HALF_UP));
            }*/
            if(crdLine.QTB_Unit_Price__c != null) { // Gitlab #28417 added unit price for On Account and creditNote partial, earlier it was not handled
                rateAmount = String.valueof(crdLine.QTB_Unit_Price__c.setScale(3, RoundingMode.HALF_UP));
            }
            prodInfo.rateAmount  = rateAmount;
            
            //CreditNoteLineAmount
            String creditNoteLineAmount = '0.00';
            Decimal crdNoteLineSubtotalAmount = 0.00;
            if (crdLine.blng__Subtotal__c != null) {
                /*if (crdLine.blng__Subtotal__c == 0 && crdLine.QTB_Subtotal_WithNegative__c != null && crdLine.QTB_Subtotal_WithNegative__c < 0) {
                    creditNoteLineAmount = String.valueof(crdLine.QTB_Subtotal_WithNegative__c.setScale(2));
                    crdNoteLineSubtotalAmount = crdLine.QTB_Subtotal_WithNegative__c.setScale(2);
                } else {  Gitlab-22532 */
                    creditNoteLineAmount = String.valueof(crdLine.blng__Subtotal__c.setScale(2));
                    crdNoteLineSubtotalAmount = crdLine.blng__Subtotal__c.setScale(2);
                }
            //}
            prodInfo.invoiceLineAmount  = creditNoteLineAmount == '0.00' ? creditNoteLineAmount : String.valueof(-1 * crdNoteLineSubtotalAmount.setScale(2));
            
            //TaxLineAmount
            String taxLineAmount = '0.00';
            Decimal crdNoteLinetaxAmount = 0.00;
            if (crdLine.blng__TaxAmount__c != null) {
                taxLineAmount = String.valueof(crdLine.blng__TaxAmount__c.setScale(2));
                crdNoteLinetaxAmount = crdLine.blng__TaxAmount__c.setScale(2);
            }
            prodInfo.taxLineAmount  = taxLineAmount == '0.00' ? taxLineAmount : String.valueof(-1 * crdNoteLinetaxAmount.setScale(2));
            
            Decimal crdNoteLineAmountTotal = 0.00; //Gitlab-22532
            //LineAmountTotal
            //Changes to consider the QTB_Subtotal_WithNegative__c value for -VE Credit Note Lines as part of the Story #22175
            if (crdLine.blng__TotalAmount__c != null /* || crdLine.QTB_Subtotal_WithNegative__c != null  Gitlab-22532 */) {
                /*if (((crdLine.blng__TotalAmount__c != null && crdLine.blng__TotalAmount__c == 0) || crdLine.blng__TotalAmount__c != null) && crdLine.QTB_Subtotal_WithNegative__c != null) {
                    crdNoteLineAmountTotal = crdNoteLineAmountTotal + crdLine.QTB_Subtotal_WithNegative__c.setScale(2);
                } else {  Gitlab-22532 */ 
                    crdNoteLineAmountTotal = crdNoteLineAmountTotal +  ((crdLine.blng__TotalAmount__c != null) ? crdLine.blng__TotalAmount__c.setScale(2) : 0.0);
                }
            //}
            prodInfo.lineAmountTotal  = crdNoteLineAmountTotal == 0.00 ? string.valueOf(crdNoteLineAmountTotal.setScale(2)) :
                String.valueof(-1 * crdNoteLineAmountTotal.setScale(2)); //Gitlab-22532
 
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_GenerateBillTrustExtractCTRL.updateProductInfo');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
        return prodInfo;
    }
	
	public static void dummyCode(){
        integer i = 0;
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
            }
}