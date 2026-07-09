/*****************************************************************************************************
* Class: QTB_GenerateBillTrustExtractCTRL
* Purpose: This class is the controller class for generating Billtrust extract
* Developer       Date           Description
* -----------------------------------------------------------------------------------------------------
* Renuka Prasad      20/7/2021
* Renuka Prasad      15/4/2024   Changes for Grouping same Invoice Lines and Price for Presentment
*******************************************************************************************************/
public class QTB_GenerateBillTrustExtractCTRL { 
    
    public static final String BILLTRUST_XML_HEADER = '<?xml version="1.0"?>'+
        '<dsInvoiceData xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
        '<InvoiceData>';
    
    public static final String BILLTRUST_XML_INVOICE_HEADER_START_TAG = '<InvoiceHeader>';
    
    public static final String BILLTRUST_XML_INVOICE_HEADER_END_TAG = '</InvoiceHeader>';
    
    public static final String BILLTRUST_XML_HEADER_END_TAG = '</InvoiceData>'+
        '</dsInvoiceData>';
    
    public static final String BILLTRUST_XML_DSINVOICE_DATA_END_TAG = '</dsInvoiceData>';
    
    public static final String BILLTRUST_XML_INVOICE_LINE_DETAIL_START_TAG = '<InvoiceLineDetail>';
    
    public static final String BILLTRUST_XML_INVOICE_LINE_DETAIL_END_TAG = '</InvoiceLineDetail>';
    
    public static final String BILLTRUST_INVOICE_TRANSACTION_TYPE = 'Invoice';
    
    public static final String BILLTRUST_SINGLE_INVOICE_CONSOLIDATION_TYPE = 'S';
    
    public static final String BILLTRUST_STORAGE_START_TAG = '<STORAGE>';
    
    public static final String BILLTRUST_STORAGE_END_TAG = '</STORAGE>';
    
    public static final String BILLTRUST_SERVICE_START_TAG = '<SERVICE>';
    
    public static final String BILLTRUST_SERVICE_END_TAG = '</SERVICE>';
    
    public static final String BILLTRUST_OTHER_START_TAG = '<OTHER>';
    
    public static final String BILLTRUST_OTHER_END_TAG = '</OTHER>';
    
    public static final String INVOICE_PRESENTMENT_BILLTRUST = 'Billtrust';
    
    public static final String INVOICE_PRESENTMENT_APIX = 'Apix';
    
    public static final String BILLTRUST_TEMPLATE_A = 'Template-A';
    
    public static final String BILLTRUST_TEMPLATE_H = 'Template-H';
    
    public static final String BILLTRUST_GOVERNMENT_TYPE = 'Government';
    
    public static final String BILLTRUST_FEDERAL_TYPE = 'Federal';
    
    public static final String BILLTRUST_HOLDIND_VALUE = 'Outsource';
    
    public static final String BILLTRUST_INVOICETYPE_NA = 'N/A';
    
    public static final String BILLTRUST_EXTRACT_TYPE_SINGLE = 'S';
    
    public static final String CANADA_COUNTRY_ISO_CODE = 'CA';
    
    /***********************************************************************************************************
* Method : generateBillTrustXml
* Parameters: list<blng__Invoice__c> invoiceList, String invSchedulerName, String invSchedulerId
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: Generating the Mass Invoice XML for Bill Trust system
**************************************************************************************************************/
    @AuraEnabled
    public static void generateBillTrustXml(list<blng__Invoice__c> invoiceList, String invSchedulerName, String invSchedulerId)
    {
        try
        {
            if (invoiceList.size() <= 0) {
                throw new AuraHandledException('No valid invoices found.');
            }
            
            //Fetching additional details required to create Billtrust extract
            list<blng__CreditNote__c> creditNoteList = new list<blng__CreditNote__c>();
            SupplementaryInfo supplementaryDetails = QTB_BillTrustUtil.getSupplementaryInfo(invoiceList, creditNoteList);
            Boolean isMassExtract = (invSchedulerName != null) ? true : false;
            
            list<InvoiceInfo> invoiceInfoDetails = new list<InvoiceInfo>();
            for (blng__Invoice__c inv: invoiceList) {
                InvoiceInfo tempInvoiceInfo = getInvoiceInfo(inv, isMassExtract, supplementaryDetails);
                invoiceInfoDetails.add(tempInvoiceInfo);
            }
            
            //Logic to generate Billtrust extract
            if (invoiceInfoDetails.size() > 0) {
                QTB_BillTrustUtil.generateBilltrustRequest(invoiceInfoDetails, isMassExtract, invSchedulerName, invSchedulerId);
            }
            
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateBillTrustExtractCTRL.generateBillTrustXml');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
    }
    
    /***********************************************************************************************************
* Method : getInvoiceInfo
* Parameters: blng__Invoice__c invoiceInfo, Boolean isMassExtract, SupplementaryInfo supplementaryDetails
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: Method to fetch the Invoice Details
**************************************************************************************************************/    
    public static InvoiceInfo getInvoiceInfo(blng__Invoice__c invoiceInfo, Boolean isMassExtract, SupplementaryInfo supplementaryDetails)
    {
        InvoiceInfo invDetails = new InvoiceInfo();
        try
        {
            if (invoiceInfo == null) {
                throw new AuraHandledException('Not valid invoice.');
            }
            
            String sfdcBilTrstMapString = QTB_BillTrustUtil.SFDC_BILLTRUST_MAP;
            
            //Fetching the Billtrust Salesforce Mapping details from the constant
            Map<String, String> sfdcBillTrustFieldMap = (Map<String, String>) JSON.deserialize(sfdcBilTrstMapString, Map<String, String>.class);
            
            //To store the Salesforce Product and Billing codes
            Map<ID, string> productMap = supplementaryDetails.productBillCodeMap;
            
            //To store the Product and the translation text
            Map<String, String> productTranslationMap = supplementaryDetails.productTranslationMap;
            
            //Getting the account level additional details
            Map<ID, AdditionalInfo> additonalInfo = supplementaryDetails.accountAdditionalInfoMap;
            AdditionalInfo additionalDetails = (AdditionalInfo) additonalInfo.get(invoiceInfo.blng__Account__c);
            
            //Getting the Tax details
            Map<ID, Map<String, Decimal>> siteTaxDetailsMap = supplementaryDetails.siteTaxDetailsMap;
            Map<String, Decimal> siteTaxInfo = siteTaxDetailsMap.get(invoiceInfo.Id);
            
            Map<id, list<blng__InvoiceLine__c>> invoiceLineInfoMap = new Map<id, list<blng__InvoiceLine__c>>();
            Map<ID, list<blng__InvoiceLine__c>> storageLinesInfo = new Map<ID, list<blng__InvoiceLine__c>>();
            Decimal storageTotal = 0.0;
            Decimal storageTotalWithTax = 0.0;
            Map<ID, list<blng__InvoiceLine__c>> serviceLinesInfo = new Map<ID, list<blng__InvoiceLine__c>>();
            Decimal serviceTotal = 0.0;
            Decimal serviceTotalWithTax = 0.0;
            Map<ID, list<blng__InvoiceLine__c>> otherItemsInfo = new Map<ID, list<blng__InvoiceLine__c>>();
            Decimal otherTotal = 0.0;
            Decimal otherTotalWithTax = 0.0;
            String servicePeriod = '';
            
            //Logic to seggregate the products based on the schedule category
            for(blng__InvoiceLine__c invLin : invoiceInfo.blng__InvoiceInvoiceLines__r) {
                if (invLin.blng__Product__r.QTB_Price_Schedule_Category__c != null && invLin.blng__Product__r.QTB_Price_Schedule_Category__c == QTB_Constants.STORAGE) {
                    list<blng__InvoiceLine__c> tempStorageLines = new list<blng__InvoiceLine__c>();
                    
                    if (storageLinesInfo.get(invoiceInfo.id) != null) {
                        tempStorageLines = storageLinesInfo.get(invoiceInfo.id);
                    }
                    tempStorageLines.add(invLin);
                    storageLinesInfo.put(invoiceInfo.id, tempStorageLines);
                    
                    if(invLin.blng__Subtotal__c != null) {
                        storageTotal = storageTotal + invLin.blng__Subtotal__c;
                    }
                    
                    if(invLin.blng__TotalAmount__c != null) {
                        storageTotalWithTax = storageTotalWithTax + invLin.blng__TotalAmount__c;
                    }
                    
                } else if (invLin.blng__Product__r.QTB_Price_Schedule_Category__c != null && invLin.blng__Product__r.QTB_Price_Schedule_Category__c == QTB_Constants.SERVICES) {
                    list<blng__InvoiceLine__c> tempServiceLines = new list<blng__InvoiceLine__c>();
                    
                    if (serviceLinesInfo.get(invoiceInfo.id) != null) {
                        tempServiceLines = serviceLinesInfo.get(invoiceInfo.id);
                    }
                    tempServiceLines.add(invLin);
                    serviceLinesInfo.put(invoiceInfo.id, tempServiceLines);
                    
                    if(invLin.blng__Subtotal__c != null) {
                        serviceTotal = serviceTotal + invLin.blng__Subtotal__c;
                    }
                    
                    if(invLin.blng__TotalAmount__c != null) {
                        serviceTotalWithTax = serviceTotalWithTax + invLin.blng__TotalAmount__c;
                    }
                    
                } else {
                    list<blng__InvoiceLine__c> tempOtherLines = new list<blng__InvoiceLine__c>();
                    
                    if (otherItemsInfo.get(invoiceInfo.id) != null) {
                        tempOtherLines = otherItemsInfo.get(invoiceInfo.id);
                    }
                    tempOtherLines.add(invLin);
                    otherItemsInfo.put(invoiceInfo.id, tempOtherLines);
                    
                    if(invLin.blng__Subtotal__c != null) {
                        otherTotal = otherTotal + invLin.blng__Subtotal__c;
                    }
                    
                    if(invLin.blng__TotalAmount__c != null) {
                        otherTotalWithTax = otherTotalWithTax + invLin.blng__TotalAmount__c;
                    }
                    
                }
                
                if (invLin.blng__UsageSummary__r.blng__SummaryEndDate__c != null && servicePeriod == '') {
                    Date tempServiceDate = invLin.blng__UsageSummary__r.blng__SummaryEndDate__c;
                    servicePeriod = DateTime.newInstance(tempServiceDate.year(),tempServiceDate.month(),tempServiceDate.day()).format('MMM-yyyy');
                }
            }
            
            invDetails.transactionType = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_INVOICE_TRANSACTION_TYPE;
            String invoiceType = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_INVOICETYPE_NA;
            if (invoiceInfo.blng__Account__r.QTB_Billing_Frequency__c != null && sfdcBillTrustFieldMap.get(invoiceInfo.blng__Account__r.QTB_Billing_Frequency__c) != null) {
                invoiceType = sfdcBillTrustFieldMap.get(invoiceInfo.blng__Account__r.QTB_Billing_Frequency__c);
            }
            invDetails.invoiceType = invoiceType;
            
            String extractType = (invoiceInfo.blng__Account__r.QTB_Consolidation_Flag__c != null && invoiceInfo.blng__Account__r.QTB_Consolidation_Flag__c == true) ? 'C' : 'S';
            invDetails.consolidated_single = extractType;
            
            String governmentType = '';
            String accntClassification = '';
            if (invoiceInfo.blng__Account__r.QTB_Customer_Classification__c != null) {
                accntClassification = String.valueof(invoiceInfo.blng__Account__r.QTB_Customer_Classification__c);
                if (String.valueof(invoiceInfo.blng__Account__r.QTB_Customer_Classification__c).contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_GOVERNMENT_TYPE)
                    || String.valueof(invoiceInfo.blng__Account__r.QTB_Customer_Classification__c).contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_FEDERAL_TYPE)) {
                        //invDetails.governmentType = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_GOVERNMENT_TYPE;
                    }
            }
            invDetails.governmentType = governmentType;
            
            String templateType = '';
            //if (!isMassExtract) {
            if (accntClassification.contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_GOVERNMENT_TYPE)
                || accntClassification.contains(QTB_GenerateBillTrustExtractCTRL.BILLTRUST_FEDERAL_TYPE)) {
                    templateType = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_TEMPLATE_H;
                } else {
                    templateType = QTB_GenerateBillTrustExtractCTRL.BILLTRUST_TEMPLATE_A;
                }
            //}
            invDetails.templateType = templateType;
            
            String deliveryType = '';
            if (invoiceInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c != null
                && sfdcBillTrustFieldMap.get(invoiceInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c) != null) {
                    deliveryType = sfdcBillTrustFieldMap.get(invoiceInfo.blng__Account__r.QTB_Invoice_Delivery_Options__c);
                }
            invDetails.deliveryType = deliveryType;
            
            invDetails.invoiceDeliveryEmailAddress = additionalDetails.primaryContactEmail;
            
            String holdInd = (invoiceInfo.blng__Account__r.QTB_HoldInd__c != null) ? invoiceInfo.blng__Account__r.QTB_HoldInd__c : BILLTRUST_HOLDIND_VALUE; 
            invDetails.holdInd = holdInd;
            
            String holdRequester = (invoiceInfo.blng__Account__r.QTB_HoldRequester__c != null) ? invoiceInfo.blng__Account__r.QTB_HoldRequester__c : ''; 
            invDetails.holdRequester = holdRequester;
            
            String imCompany = (invoiceInfo.blng__Account__r.QTB_IMCompany__c != null) ? invoiceInfo.blng__Account__r.QTB_IMCompany__c : ''; 
            
            if (additionalDetails.countryISOCode != NULL && additionalDetails.countryISOCode == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                imCompany = 'IRM';
            }
            invDetails.imCompany = imCompany;
            
            String customerLanguage = '';
            if (invoiceInfo.blng__Account__r.QTB_Language__c != null && sfdcBillTrustFieldMap.get(invoiceInfo.blng__Account__r.QTB_Language__c) != null) {
                customerLanguage = sfdcBillTrustFieldMap.get(invoiceInfo.blng__Account__r.QTB_Language__c);
            }
            invDetails.customerLanguage = customerLanguage;
            
            String accountCurrency = '';
            if (invoiceInfo.CurrencyIsoCode != null) {
                accountCurrency = invoiceInfo.CurrencyIsoCode;
            }
            invDetails.accountCurrency = accountCurrency;
            
            String returnAddress1 = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c : '';
            invDetails.returnAddress1 = returnAddress1;
            
            String returnAddress2 = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c : '';
            invDetails.returnAddress2 = returnAddress2;
            
            String returnAddress3 = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c : '';
            invDetails.returnAddress3 = returnAddress3;
            
            String returnCity = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c : '';
            invDetails.returnCity = returnCity;
            
            String returnState = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c : '';
            invDetails.returnState = returnState;
            
            String returnPostalCode = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c : '';
            invDetails.returnPostalCode = returnPostalCode;
            
            String imBillContact = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c : '';
            invDetails.imBillContact = imBillContact;
            
            String imBillContactPN = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c : '';
            invDetails.imBillContactPN = imBillContactPN;
            if (customerLanguage == 'FRC') {
                invDetails.imBillContactPN = sfdcBillTrustFieldMap.get('IMBillContactPN_Frc');
            }
            
            String imBillContactEmail = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c : '';
            invDetails.imBillContactEmail = imBillContactEmail;
            if (customerLanguage == 'FRC') {
                invDetails.imBillContactEmail = sfdcBillTrustFieldMap.get('IMBillContactEmail_Frc');
            }
            
            String customerName = '';
            if (invoiceInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null) {
                customerName = invoiceInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c;
            }
            invDetails.customerName = customerName;
            
            String customerContact = '';
            if (invoiceInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null) {
                customerContact = invoiceInfo.blng__Account__r.QTB_Billing_Account_Invoice_Name__c;
            }
            //Updating the Billing Contact Name
            invDetails.customerContact = additionalDetails.customerContactName;
            
            String customerAddress1 = '';
            if (invoiceInfo.blng__Account__r.BillingStreet != null) {
                customerAddress1 = invoiceInfo.blng__Account__r.BillingStreet;
            }
            invDetails.customerAddress1 = customerAddress1;
            
            String customerAddress2 = '';//NULL TO BE PASSED
            invDetails.customerAddress2 = customerAddress2;
            
            String customerAddress3 = '';//NULL TO BE PASSED
            invDetails.customerAddress3 = customerAddress3;
            
            String customerAddress4 = '';//NULL TO BE PASSED
            invDetails.customerAddress4 = customerAddress4;
            
            
            String customerCity = '';
            if (invoiceInfo.blng__Account__r.BillingCity != null) {
                customerCity = invoiceInfo.blng__Account__r.BillingCity;
            }
            invDetails.customerCity = customerCity;
            
            String customerState = '';
            if (invoiceInfo.blng__Account__r.BillingState != null) {
                customerState = invoiceInfo.blng__Account__r.BillingState;
            }
            invDetails.customerState = customerState;
            
            String customerPostalCode = '';
            if (invoiceInfo.blng__Account__r.BillingPostalCode != null) {
                customerPostalCode = invoiceInfo.blng__Account__r.BillingPostalCode;
            }
            invDetails.customerPostalCode = customerPostalCode;
            
            invDetails.customerCountry = additionalDetails.countryISOCode;
            
            String invoiceID = '';
            if (invoiceInfo.Name != null) {
                invoiceID = invoiceInfo.Name;
            }
            invDetails.invoiceID = invoiceID;
            
            String invoiceDate = '';
            if (invoiceInfo.blng__InvoiceDate__c != null) {
                Date tempDate = invoiceInfo.blng__InvoiceDate__c;
                
                if(additionalDetails.countryISOCode == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    invoiceDate = DateTime.newInstance(tempDate.year(),tempDate.month(),tempDate.day()).format('dd-MMM-YY');
                    invoiceDate = invoiceDate.toUpperCase();
                } else {
                    invoiceDate = DateTime.newInstance(tempDate.year(),tempDate.month(),tempDate.day()).format('MM/dd/yyyy');
                }
            }
            invDetails.invoiceDate = invoiceDate;
            
            invDetails.servicePeriod = servicePeriod.toUpperCase();
            
            String customerID = '';
            if (invoiceInfo.blng__Account__r.QTB_Customer_Number__c != null) {
                customerID = invoiceInfo.blng__Account__r.QTB_Customer_Number__c;
            }
            invDetails.customerID = customerID;
            
            String taxID = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c : '';
            invDetails.taxID = taxID;
            
            /*Map<ID, String> poMap = additionalDetails.customerPO;
String poNumber = (poMap.get(invoiceInfo.id) != null) ? poMap.get(invoiceInfo.id) : '';
invDetails.poNumber = poNumber;*/           
            
            //Story Git #7673 
            //Conditionally Map the PO Number to the QTB_Purchase_Order__c field on the Invoice Object for SITAD Only (Slalom)
            Map<ID, String> poMap = additionalDetails.customerPO;
            String poNumber = (poMap.get(invoiceInfo.id) != null) ? poMap.get(invoiceInfo.id) : '';


            
            
            
            /* GIT #7673 Start (1 of 2) Slalom */
            //invDetails.poNumber = poNumber; //Original 
            
            If (invoiceinfo.blng__InvoiceRunCreatedBy__r.name !=null) { // check
                If(invoiceinfo.blng__InvoiceRunCreatedBy__r.name.Contains('SecureITAD')){  
                    invDetails.poNumber = invoiceInfo.QTB_Purchase_Order__c;
                }else{
                    invDetails.poNumber = poNumber;             
                }
            }
            
            /* GIT #7673 End (1 of 2) Slalom */
            
            
            
            String dueDate  = '';
            if (invoiceInfo.blng__DueDate__c != null) {
                Date tempDueDate = invoiceInfo.blng__DueDate__c;
                if(additionalDetails.countryISOCode == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                    dueDate = DateTime.newInstance(tempDueDate.year(),tempDueDate.month(),tempDueDate.day()).format('dd-MMM-YY');
                    dueDate = dueDate.toUpperCase();
                } else {
                    dueDate = DateTime.newInstance(tempDueDate.year(),tempDueDate.month(),tempDueDate.day()).format('MM/dd/YYYY');
                }
            }
            invDetails.dueDate = dueDate;
            
            System.debug('storageTotalHHH'+storageTotal);
            System.debug('storageTotalHHHSTR'+String.valueOf(storageTotal));
            //Logic to show Total amount without Tax for both US & Canada in Invoice Page 1
            invDetails.totalStorage = String.valueOf(storageTotal.setScale(2));
            invDetails.totalService = String.valueOf(serviceTotal.setScale(2));
            invDetails.totalOther = String.valueOf(otherTotal.setScale(2)); 
            
            System.debug('invDetails>>>'+invDetails);
            System.debug('invDetails>>>totalStorage'+invDetails.totalStorage);
            String totalTaxAmount = (invoiceInfo.blng__TaxAmount__c != null) ? String.valueof(invoiceInfo.blng__TaxAmount__c.setScale(2)) : '0.00';
            invDetails.totalTaxAmount = totalTaxAmount;
            
            String totalAdjustmentAmount = (invoiceInfo.QTB_TotalAdjustmentAmount__c != null) ? String.valueof(invoiceInfo.QTB_TotalAdjustmentAmount__c.setScale(2)) : String.valueOf(0.00);
            invDetails.totalAdjustmentAmount = totalAdjustmentAmount;
            
            String lateFee = '0.00';//(invoiceInfo.QTB_Late_Fee_Amount__c != null) ? String.valueof(invoiceInfo.QTB_Late_Fee_Amount__c.setScale(2)) : '0.00';
            invDetails.lateFee = lateFee;
            
            String invoiceTotalAmount = (invoiceInfo.blng__TotalAmount__c != null) ? String.valueof(invoiceInfo.blng__TotalAmount__c.setScale(2)) : '0.00';
            invDetails.invoiceTotalAmount = invoiceTotalAmount;
            
            
            String payMntName = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c : '';
            invDetails.payMntName = payMntName;
            
            String payMntAddress1 = '';
            if (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c != null) {
                //payMntAddress1 = invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c;
            }
            invDetails.payMntAddress1 = payMntAddress1;
            
            String payMntAddress2 = '';
            if (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c != null) {
                payMntAddress2 = invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c;
            }
            invDetails.payMntAddress2 = payMntAddress2;
            
            String payMntAddress3 = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c : '';
            invDetails.payMntAddress3 = payMntAddress3;
            
            String payMntCity = '';
            if (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__City__c != null) {
                payMntCity = invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__City__c;
            }
            invDetails.payMntCity = payMntCity;
            
            String payMntState = '';
            if (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__State__c != null) {
                payMntState = invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__State__c;
            }
            invDetails.payMntState = payMntState;
            
            String payMntPostalCode = '';
            if (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c != null) {
                payMntPostalCode = invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c;
            }
            invDetails.payMntPostalCode = payMntPostalCode;
            
            String contractNumber = (invoiceInfo.blng__Account__r.QTB_ContractNumber__c != null) ? invoiceInfo.blng__Account__r.QTB_ContractNumber__c : '';
            invDetails.contractNumber = contractNumber; 
            
            String cageCode = (invoiceInfo.blng__Account__r.QTB_CageCode__c != null) ? invoiceInfo.blng__Account__r.QTB_CageCode__c : '';
            invDetails.cageCode = cageCode;
            
            String dunsNumber  = (invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c != null) ? invoiceInfo.blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c : '';
            invDetails.dunsNumber = dunsNumber;
            
            String receivedBy = '';
            if (invoiceDate != null) {
                receivedBy = invoiceDate;
            }
            invDetails.receivedBy = receivedBy;
            
            String pastDueBalancePrior = '0.00';
            if (invoiceInfo.blng__Account__r.QTB_Account_Balance__c != null) {
                pastDueBalancePrior = String.valueof(invoiceInfo.blng__Account__r.QTB_Account_Balance__c.setScale(2));
            }
            invDetails.pastDueBalancePrior = pastDueBalancePrior;
            
            String receivedByPay = invoiceDate;
            invDetails.receivedByPay = receivedByPay;
            
            String paymentsRcvd = (invoiceInfo.QTB_PaymentsRcvd__c != null) ? String.valueOf(invoiceInfo.QTB_PaymentsRcvd__c.setScale(2)) : '0.00';
            invDetails.paymentsRcvd = paymentsRcvd;
            
            String receivedByAdjust = invoiceDate;
            invDetails.receivedByAdjust = receivedByAdjust;
            
            String adjustmentsRcvdAmt = (invoiceInfo.QTB_AdjustmentsRcvdAmt__c != null) ? String.valueOf(invoiceInfo.QTB_AdjustmentsRcvdAmt__c.setScale(2)) : '0.00';
            invDetails.adjustmentsRcvdAmt = adjustmentsRcvdAmt;
            
            String receivedByBal = invoiceDate;
            invDetails.receivedByBal = receivedByBal;
            
            String pastDueBalanceTotal = (invoiceInfo.QTB_PastDueBalanceTotal__c != null) ? String.valueOf(invoiceInfo.QTB_PastDueBalanceTotal__c.setScale(2)) : '0.00';
            invDetails.pastDueBalanceTotal = pastDueBalanceTotal;
            
            String currentTotalAmount = (invoiceInfo.blng__TotalAmount__c != null) ? String.valueOf(invoiceInfo.blng__TotalAmount__c.setScale(2)) : '0.00';
            invDetails.currentTotalAmount = currentTotalAmount;
            
            
            Decimal pastDue = (!String.isEmpty(pastDueBalanceTotal)) ? Decimal.ValueOf(pastDueBalanceTotal) : 0.0;
            Decimal currentAmnt = (!String.isEmpty(currentTotalAmount) != null) ? Decimal.ValueOf(currentTotalAmount) : 0.0;
            
            Decimal totalBalance = pastDue + currentAmnt;
            invDetails.totalBalance = String.ValueOf(totalBalance.setScale(2));
            
            String invoiceStatus = '';
            if (invoiceInfo.blng__InvoiceStatus__c != null) {
                invoiceStatus = invoiceInfo.blng__InvoiceStatus__c;
            }
            invDetails.invoiceStatus = invoiceStatus;
            
            String invNumber = '';
            if (invoiceInfo.QTB_Custom_Invoice_Number__c != null) {
                invNumber = invoiceInfo.QTB_Custom_Invoice_Number__c;
            }
            invDetails.invNumber = invNumber;
            
            String invName = '';
            if (invoiceInfo.Name != null) {
                invName = invoiceInfo.Name;
            }
            invDetails.invName = invName;
            
            String invId = '';
            if (invoiceInfo.Id != null) {
                invId = invoiceInfo.Id;
            }
            invDetails.invId = invId;
            
            //Changes for Invoice Line Details Starts
            InvoiceLineInfo invLineInfo = new InvoiceLineInfo();

            String siteId = additionalDetails.siteId;
            String siteName = additionalDetails.siteName;
            
            invLineInfo.siteID = siteId;
            invLineInfo.siteName = siteName;
            invLineInfo.invoiceID = invoiceID;
            invLineInfo.referenceID = invoiceID;
            invLineInfo.invoiceDate = invoiceDate;
            
            /* GIT #7673 Start (2 of 2) Slalom */
            
            //invLineInfo.poNumber = poNumber; //Original
            //invLineInfo.siteNumber = additionalDetails.siteNumber; //Original

            
            
            If (invoiceinfo.blng__InvoiceRunCreatedBy__r.name !=null) { // check
                If(invoiceinfo.blng__InvoiceRunCreatedBy__r.name.Contains('SecureITAD')){  
                    invLineInfo.poNumber = invoiceInfo.QTB_Purchase_Order__c;  
                    invLineInfo.siteNumber = invoiceinfo.QTB_Site_Number__c;
                }
                else{
                    invLineInfo.poNumber = poNumber;   
                    invLineInfo.siteNumber = additionalDetails.siteNumber;
                } 
            }
            
            /* GIT #7673 Start (2 of 2) Slalom */
            
            invLineInfo.siteAdjustmentTotal = (invoiceInfo.QTB_SiteAdjustmentTotal__c != null) ? String.valueof(invoiceInfo.QTB_SiteAdjustmentTotal__c.setScale(2)) : '0.00';
            //invLineInfo.siteNumberTotal = (invoiceInfo.QTB_SiteNumberTotal__c != null) ? String.valueOf(invoiceInfo.QTB_SiteNumberTotal__c.setScale(2)) : '0.00';
            invLineInfo.siteNumberTotal = invoiceTotalAmount;
            invLineInfo.siteLateFeeAmount = (invoiceInfo.QTB_SiteLateFeeAmount__c != null) ? String.valueOf(invoiceInfo.QTB_SiteLateFeeAmount__c.setScale(2)) : '0.00';
            invLineInfo.invoiceTotalAmount = invoiceTotalAmount;
            Decimal siteSubTotalValue = storageTotal + serviceTotal + otherTotal;
            invLineInfo.siteSubTotal = String.valueOf(siteSubTotalValue.setScale(2));
            
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
                            siteTaxAmount1 = (siteTaxInfo.get(taxInfo) != null) ? String.ValueOf(siteTaxInfo.get(taxInfo)) : '0.00';
                            
                        } else if (siteTaxDescription1 != '' && siteTaxDescription2 == '') {
                            siteTaxDescription2 = taxInfo;
                            siteTaxAmount2 = (siteTaxInfo.get(taxInfo) != null) ? String.ValueOf(siteTaxInfo.get(taxInfo)) : '0.00';
                            
                        } else {
                            siteTaxDescription3 = taxInfo;
                            siteTaxAmount3 = (siteTaxInfo.get(taxInfo) != null) ? String.ValueOf(siteTaxInfo.get(taxInfo)) : '0.00';
                            
                        }
                    }
                }
                
                invLineInfo.siteTaxDescription1 = siteTaxDescription1;
                invLineInfo.siteTaxAmount1 = siteTaxAmount1;
                invLineInfo.siteTaxDescription2 = siteTaxDescription2;
                invLineInfo.siteTaxAmount2 = siteTaxAmount2;
                invLineInfo.siteTaxDescription3 = siteTaxDescription3;
                invLineInfo.siteTaxAmount3 = siteTaxAmount3;
            }
            
            //Logic to show Total amount without Tax for Canada & with Tax for US.
            if (additionalDetails.countryISOCode != NULL && additionalDetails.countryISOCode == QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE) {
                invLineInfo.totalStorageAmount = String.valueOf(storageTotal.setScale(2));
                invLineInfo.totalServiceAmount = String.valueOf(serviceTotal.setScale(2));
                invLineInfo.totalOtherAmount = String.valueOf(otherTotal.setScale(2));
            } else {
                invLineInfo.totalStorageAmount = String.valueOf(storageTotalWithTax.setScale(2));
                invLineInfo.totalServiceAmount = String.valueOf(serviceTotalWithTax.setScale(2));
                invLineInfo.totalOtherAmount = String.valueOf(otherTotalWithTax.setScale(2));
            }
            //Update Storage Invoice Line Info
            invLineInfo = updateStorageInfo(invLineInfo, storageLinesInfo.get(invoiceInfo.id), productMap, productTranslationMap);
            
            //Update Service Invoice Line Info
            invLineInfo = updateServiceInfo(invLineInfo, serviceLinesInfo.get(invoiceInfo.id), productMap, productTranslationMap);
            
            //Update Other Invoice Line Info
            invLineInfo = updateOtherInfo(invLineInfo, otherItemsInfo.get(invoiceInfo.id), productMap, productTranslationMap);
            
            invDetails.invoiceDetails = invLineInfo;
            
        } catch(exception e) {
            system.debug('Inside getAdditionalInfo exception block'+e.getMessage()+'Line Number'+e.getLineNumber());
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_GenerateBillTrustExtractCTRL.getAdditionalInfo');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
        
        return invDetails;
    }
    
    /***********************************************************************************************************
* Method : updateStorageInfo
* Parameters: InvoiceLineInfo invLineInfo,list<blng__InvoiceLine__c> otherInfo,Map<ID, string> productMap,Map<String, String> productTranslationMap
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To update the storage invoice line details in the Bill Trust XML
**************************************************************************************************************/
    public static InvoiceLineInfo updateStorageInfo(
        InvoiceLineInfo invLineInfo,
        list<blng__InvoiceLine__c> storageInfo,
        Map<ID, string> productMap,
        Map<String, String> productTranslationMap
    ) {
        //Gitlab US#22996 -- logic moved to updateStorageServiceOtherInfo() function
        InvoiceLineInfo invLineStorageInfo = updateStorageServiceOtherInfo(invLineInfo,storageInfo,productMap,productTranslationMap,'storage');
        return invLineStorageInfo;





















































































    }
    
    
    /***********************************************************************************************************
* Method : updateServiceInfo
* Parameters: InvoiceLineInfo invLineInfo,list<blng__InvoiceLine__c> otherInfo,Map<ID, string> productMap,Map<String, String> productTranslationMap
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To update the service invoice line details in the Bill Trust XML
*************************************************************************************************************/
    public static InvoiceLineInfo updateServiceInfo(
        InvoiceLineInfo invLineInfo,
        list<blng__InvoiceLine__c> serviceInfo,
        Map<ID, string> productMap,
        Map<String, String> productTranslationMap
    ) {
         //Gitlab US#22996 -- logic moved to updateStorageServiceOtherInfo() function
        InvoiceLineInfo invLineServiceInfo = updateStorageServiceOtherInfo(invLineInfo,serviceInfo,productMap,productTranslationMap,'service');
        return invLineServiceInfo;



















































































    }
    
    /***********************************************************************************************************
* Method : updateOtherInfo
* Parameters: InvoiceLineInfo invLineInfo,list<blng__InvoiceLine__c> otherInfo,Map<ID, string> productMap,Map<String, String> productTranslationMap
* Requirement : GITLAB-1410
* Start Date : 07/20/2021
* Author : Renuka Prasad
* Description: To update the other invoice line details in the Bill Trust XML
**************************************************************************************************************/
    public static InvoiceLineInfo updateOtherInfo(
        InvoiceLineInfo invLineInfo,
        list<blng__InvoiceLine__c> otherInfo,
        Map<ID, string> productMap,
        Map<String, String> productTranslationMap
    ) {
         //Gitlab US#22996 -- logic moved to updateStorageServiceOtherInfo() function
        InvoiceLineInfo invLineOtherInfo = updateStorageServiceOtherInfo(invLineInfo,otherInfo,productMap,productTranslationMap,'other');
        return invLineOtherInfo;
    }
 
    /***********************************************************************************************************
    * Method     : updateStorageServiceOtherInfo
    * Parameters : InvoiceLineInfo invLineInfo,list<blng__InvoiceLine__c> otherInfo,Map<ID, string> productMap,Map<String, String> productTranslationMap,string productLine
    * Requirement: Gitlab US#22996
    * Start Date : 04/11/2024
    * Author     : Virtusa
    * Description: To update the serivce,storage & other invoice line details in the Bill Trust XML
    : if multiple invoice line have same product then qnty, subtotal, tax, totalAmt rolledup only for SITAD
    **************************************************************************************************************/
    public static InvoiceLineInfo updateStorageServiceOtherInfo(InvoiceLineInfo invLineInfo,
                                                                list<blng__InvoiceLine__c> storageServiceOtherInfo,
                                                                Map<ID, string> productMap,
                                                                Map<String, String> productTranslationMap,
                                                                string productLine)
    {
        try {
            System.debug('updateStorageServiceOtherInfo@@'+productLine);
            if (invLineInfo == null || storageServiceOtherInfo == null || storageServiceOtherInfo.size() <= 0) {
                return invLineInfo;
            }            
            list<ProductInfo> storageServiceOtherProducts = new list<ProductInfo>();
            Map<String,ProductInfo> productIdUnitPriceWithInvlineListMap = new Map<String,ProductInfo>();
            
            for(blng__InvoiceLine__c invLine : storageServiceOtherInfo)
            {
                ProductInfo tempStorageServiceOther = new ProductInfo();
                Decimal invLineQuantity = 0;
                Decimal invLineSubtotalAmount = 0.0;
                Decimal invLinetaxAmount = 0.0;
                Decimal invLineAmountTotal = 0.0;
                Decimal invLineRateAmount = 0.0;
                

                










                String rateAmount = '0.0000';
                Decimal unitPrice = 0.0;
                if (invLine.QTB_Unit_Price__c != null) {
                     if (invLine.QTB_Charged_Quantity__c != null && invLine.QTB_Charged_Quantity__c != 0) {
                        unitPrice = invLine.blng__Subtotal__c/invLine.QTB_Charged_Quantity__c;
                        rateAmount = String.valueof(unitPrice.setScale(4, RoundingMode.HALF_UP));
                    } else {
                        rateAmount = String.valueof(invLine.QTB_Unit_Price__c.setScale(4, RoundingMode.HALF_UP));

                    }
                }

                
                //For SITAD - If Same Product Invoice Line having same Unit Price is Present then fetch the existing Line and update the quantity, subtotal, totalAmt, taxAmt
                if (invLine.blng__Invoice__r.blng__Account__r.QTB_SITAD__c && productIdUnitPriceWithInvlineListMap.containsKey(invLine.blng__Product__c+'-'+invLine.QTB_Unit_Price__c)) {
                    tempStorageServiceOther = productIdUnitPriceWithInvlineListMap.get(invLine.blng__Product__c+'-'+invLine.QTB_Unit_Price__c);
                    
                    //If invoiceline with same product and same price, then adding the qnty,subtotal, totalAmt, taxAmt
                    if (invLine.QTB_Charge_Type__c != null && invLine.QTB_Charge_Type__c == 'Recurring' && invLine.QTB_Inc_Quantity__c != null && invLine.QTB_Inc_Quantity__c != 0) {
                        invLineQuantity = invLineQuantity + invLine.QTB_Inc_Quantity__c;
                    } else if (invLine.QTB_Charged_Quantity__c != null && invLine.QTB_Charged_Quantity__c != 0) {
                        invLineQuantity = invLineQuantity + invLine.QTB_Charged_Quantity__c;
                    } else {
                        invLineQuantity = invLineQuantity + invLine.blng__Quantity__c;
                    }
                    
                    invLineQuantity = Integer.ValueOf(tempStorageServiceOther.quantityCnt) + invLineQuantity;
                    invLineSubtotalAmount = (Decimal.ValueOf(tempStorageServiceOther.invoiceLineAmount) + invLine.blng__Subtotal__c).setScale(2);
                    invLinetaxAmount = (Decimal.ValueOf(tempStorageServiceOther.taxLineAmount) + invLine.blng__TaxAmount__c).setScale(2);
                    invLineAmountTotal = (Decimal.ValueOf(tempStorageServiceOther.lineAmountTotal) +  invLine.blng__TotalAmount__c).setScale(2);
                    
                    tempStorageServiceOther.quantityCnt = String.valueof(Integer.valueOf(invLineQuantity));
                    tempStorageServiceOther.rateAmount  = rateAmount;
                    tempStorageServiceOther.invoiceLineAmount  = String.valueof(invLineSubtotalAmount.setScale(2));
                    tempStorageServiceOther.taxLineAmount  = String.valueof(invLinetaxAmount.setScale(2));
                    tempStorageServiceOther.lineAmountTotal  = String.valueof(invLineAmountTotal.setScale(2)); 
                    
                    productIdUnitPriceWithInvlineListMap.put(invLine.blng__Product__c+'-'+invLine.QTB_Unit_Price__c, tempStorageServiceOther);
                } 
                else if (invLine.blng__Invoice__r.blng__Account__r.QTB_SITAD__c) {
                    //For SITAD - productIdUnitPriceWithInvlineListMap is Empty create new record and update the Map
                    tempStorageServiceOther = updateProductInfo(tempStorageServiceOther, invLine, productMap, productTranslationMap);
                    
                    //Map to avoid showing multiple lines for same product and same price
                    productIdUnitPriceWithInvlineListMap.put(invLine.blng__Product__c+'-'+invLine.QTB_Unit_Price__c, tempStorageServiceOther);
                } else {
                    //Do not group the Invoice Lines for Non-SITAD
                    tempStorageServiceOther = updateProductInfo(tempStorageServiceOther, invLine, productMap, productTranslationMap);
                    
                    //Keeping the Map Key as Invoice Line ID which is Unique so that it will not group the Invoice Lines for Non-SITAD
                    productIdUnitPriceWithInvlineListMap.put(invLine.id, tempStorageServiceOther);
                }
            }
                
            //add all invoice lines to the list
            if (productIdUnitPriceWithInvlineListMap.size() > 0) {
                storageServiceOtherProducts.addAll(productIdUnitPriceWithInvlineListMap.values());
            }
            if(productLine == 'service') {
                invLineInfo.serviceDetails  = storageServiceOtherProducts; 
            } else if(productLine == 'storage') {
                invLineInfo.storageDetails = storageServiceOtherProducts;
            } else if(productLine == 'other') {
                invLineInfo.otherDetails  = storageServiceOtherProducts;
            }
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            System.debug('Exceptio>>>'+e.getMessage()+'Line Number'+e.getLineNumber());
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_GenerateBillTrustExtractCTRL.updateStorageServiceOtherInfo');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }

        return invLineInfo;
    }
    
    /***********************************************************************************************************
* Method : getInvoiceDetails
* Parameters: list<blng__Invoice__c> invoiceList
* Requirement : GITLAB-4850
* Start Date : 09/27/2021
* Author : Renuka Prasad
* Description: Method to fetch the Invoice Details
**************************************************************************************************************/    
    public static list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> getInvoiceDetails(list<blng__Invoice__c> invoiceList)
    {
        list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> invoiceDetails = new list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo>();
        try
        {
            if (invoiceList.size() <= 0) {
                return invoiceDetails;
            }
            
            //Fetching additional details required to create Billtrust extract
            list<blng__CreditNote__c> creditNoteList = new list<blng__CreditNote__c>();
            QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo supplementaryDetails = QTB_BillTrustUtil.getSupplementaryInfo(invoiceList, creditNoteList);
            Boolean isMassExtract = false;//This is required for Consolidation Logic, which is out of scope for now.
            
            for (blng__Invoice__c inv: invoiceList) {
                QTB_GenerateBillTrustExtractCTRL.InvoiceInfo tempInvoiceInfo = getInvoiceInfo(inv, isMassExtract, supplementaryDetails);
                invoiceDetails.add(tempInvoiceInfo);
            }
            
            return invoiceDetails;
            
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateCreditNoteXmlExtractCTRL.generateBillTrustXml');
            return invoiceDetails;
        }
    }
    
    /***********************************************************************************************************
    * Method     : updateProductInfo
    * Parameters : ProductInfo prodInfo, blng__InvoiceLine__c invLine, Map<ID, string> productMap,Map<String, String> productTranslationMap
    * Requirement: Gitlab US#22996
    * Start Date : 04/15/2024
    * Author     : TCS
    * Description: To update the ProductInfo wrapper with Invoice Line details
    **************************************************************************************************************/
    public static ProductInfo updateProductInfo(ProductInfo prodInfo, blng__InvoiceLine__c invLine, Map<ID, string> productMap, Map<String, String> productTranslationMap)
    {
        try {
            if (prodInfo == null || invLine == null) {
                return prodInfo;
            }
            String billCD = '';
            if (invLine.blng__Product__r.ProductCode != null ) {
                billCD = invLine.blng__Product__r.ProductCode;
            }
            if (productMap.get(invLine.blng__Product__c) != null) {
                billCD = productMap.get(invLine.blng__Product__c);
            }
            prodInfo.billCD = billCD;
            
            String clin = '';//TODO
            prodInfo.cLIN = clin;
            
            String description = '';
            if (invLine.blng__Product__r.Name != null) {
                description = String.valueOf(invLine.blng__Product__r.Name);
                if (productTranslationMap.get(invLine.blng__Product__c+'-'+invLine.blng__Invoice__r.blng__Account__r.QTB_Language__c) != null) {
                    description = String.valueOf(productTranslationMap.get(invLine.blng__Product__c+'-'+invLine.blng__Invoice__r.blng__Account__r.QTB_Language__c));
                }
                description = description.replace('&', '&#38;');
                description = description.replace('<', '&#60;');
                description = description.replace('>', '&#62;');
                description = description.replace('\'', '&#39;');
                description = description.replace('\"', '&#34;');
            }
            prodInfo.description = description;
            
            String quantityCnt = '0';
            if (invLine.QTB_Charge_Type__c != null && invLine.QTB_Charge_Type__c == 'Recurring' && invLine.QTB_Inc_Quantity__c != null && invLine.QTB_Inc_Quantity__c != 0) {
                quantityCnt = String.valueOf(Integer.valueOf(invLine.QTB_Inc_Quantity__c));
            } else if (invLine.QTB_Charged_Quantity__c != null && invLine.QTB_Charged_Quantity__c != 0) {
                quantityCnt = String.valueOf(Integer.valueOf(invLine.QTB_Charged_Quantity__c));
            } else {
                quantityCnt = String.valueOf(Integer.valueOf(invLine.blng__Quantity__c));
            }
            prodInfo.quantityCnt = quantityCnt;
            
            String rateAmount = '0.0000';
            Decimal unitPrice = 0.0;
            if (invLine.QTB_Unit_Price__c != null) {
                if (invLine.QTB_Charged_Quantity__c != null && invLine.QTB_Charged_Quantity__c != 0) {
                    unitPrice = invLine.blng__Subtotal__c/invLine.QTB_Charged_Quantity__c;
                    rateAmount = String.valueof(unitPrice.setScale(4, RoundingMode.HALF_UP));
                } else {
                    rateAmount = String.valueof(invLine.QTB_Unit_Price__c.setScale(4, RoundingMode.HALF_UP));
                }
            }
            prodInfo.rateAmount  = rateAmount;
            
            String invoiceLineAmount = '0.00';
            if (invLine.blng__Subtotal__c != null) {
                invoiceLineAmount = String.valueof(invLine.blng__Subtotal__c.setScale(2));
            }
            prodInfo.invoiceLineAmount  = invoiceLineAmount;
            
            String taxLineAmount = '0.00';
            if (invLine.blng__TaxAmount__c != null) {
                taxLineAmount = String.valueof(invLine.blng__TaxAmount__c.setScale(2));
            }
            prodInfo.taxLineAmount  = taxLineAmount;
            
            String lineAmountTotal = '0.00';
            if (invLine.blng__TotalAmount__c != null) {
                lineAmountTotal = String.valueof(invLine.blng__TotalAmount__c.setScale(2));
            }
            prodInfo.lineAmountTotal  = lineAmountTotal;
        } catch(exception e) {
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_GenerateBillTrustExtractCTRL.updateStorageServiceOtherInfo');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
        return prodInfo;
    }

    /*************************************************************
* ClassName : InvoiceInfo
* Description: Wrapper class to store Invoice details
**************************************************************/
    public class InvoiceInfo
    {
        public String transactionType {get; set;}
        public String invoiceType {get; set;}
        public String consolidated_single {get; set;}
        public String governmentType {get; set;}
        public String templateType {get; set;}
        public String deliveryType {get; set;}
        public String invoiceDeliveryEmailAddress {get; set;}
        public String holdInd {get; set;}
        public String holdRequester {get; set;}
        public String imCompany {get; set;}
        public String customerLanguage {get; set;}
        public String accountCurrency {get; set;}
        public String returnAddress1 {get; set;}
        public String returnAddress2 {get; set;}
        public String returnAddress3 {get; set;}
        public String returnCity {get; set;}
        public String returnState {get; set;}
        public String returnPostalCode {get; set;}
        public String imBillContact {get; set;}
        public String imBillContactPN {get; set;}
        public String imBillContactEmail {get; set;}
        public String customerName {get; set;}
        public String customerContact {get; set;}
        public String customerAddress1 {get; set;}
        public String customerAddress2 {get; set;}
        public String customerAddress3 {get; set;}
        public String customerAddress4 {get; set;}
        public String customerCity {get; set;}
        public String customerState {get; set;}
        public String customerPostalCode {get; set;}    
        public String customerCountry {get; set;}
        public String invoiceID {get; set;}
        public String invoiceDate {get; set;}
        public String servicePeriod {get; set;}
        public String customerID {get; set;}
        public String taxID {get; set;}
        public String poNumber {get; set;}
        public String dueDate {get; set;}
        public String totalStorage {get; set;}
        public String totalService {get; set;}
        public String totalOther {get; set;}
        public String totalTaxAmount {get; set;}
        public String totalAdjustmentAmount {get; set;}
        public String lateFee {get; set;}
        public String invoiceTotalAmount {get; set;}
        public String payMntName {get; set;}
        public String payMntAddress1 {get; set;}
        public String payMntAddress2 {get; set;}
        public String payMntAddress3 {get; set;}    
        public String payMntCity {get; set;}
        public String payMntState {get; set;}
        public String payMntPostalCode {get; set;}
        public String contractNumber {get; set;}
        public String cageCode {get; set;}
        public String dunsNumber {get; set;}
        public InvoiceLineInfo invoiceDetails {get; set;}
        public String receivedBy {get; set;}
        public String pastDueBalancePrior {get; set;}
        public String receivedByPay {get; set;}
        public String paymentsRcvd {get; set;}
        public String receivedByAdjust {get; set;}
        public String adjustmentsRcvdAmt {get; set;}
        public String receivedByBal {get; set;}
        public String pastDueBalanceTotal {get; set;}
        public String currentTotalAmount {get; set;}
        public String totalBalance {get; set;}
        public String invoiceStatus {get; set;}
        public String invNumber {get; set;}
        public String invName {get; set;}
        public String invId {get; set;}
        
        /************************************
* Constructor for InvoiceInfo
*************************************/
        public InvoiceInfo() {
            this.transactionType = '';
            this.invoiceType = '';
            this.consolidated_single = '';
            this.governmentType = '';
            this.templateType = '';
            this.deliveryType = '';
            this.invoiceDeliveryEmailAddress = '';
            this.holdInd = '';
            this.holdRequester = '';
            this.imCompany = '';
            this.customerLanguage = '';
            this.accountCurrency = '';
            this.returnAddress1 = '';
            this.returnAddress2 = '';
            this.returnAddress3 = '';
            this.returnCity = '';
            this.returnState = '';
            this.returnPostalCode = '';
            this.imBillContact = '';
            this.imBillContactPN = '';
            this.imBillContactEmail = '';
            this.customerName = '';
            this.customerContact = '';
            this.customerAddress1 = '';
            this.customerAddress2 = '';
            this.customerAddress3 = '';
            this.customerAddress4 = '';
            this.customerCity = '';
            this.customerState = '';
            this.customerPostalCode = '';    
            this.customerCountry = '';
            this.invoiceID = '';
            this.invoiceDate = '';
            this.servicePeriod = '';
            this.customerID = '';
            this.taxID = '';
            this.poNumber = '';
            this.dueDate = '';
            this.totalStorage = '';
            this.totalService = '';
            this.totalOther = '';
            this.totalTaxAmount = '';
            this.totalAdjustmentAmount = '';
            this.lateFee = '';
            this.invoiceTotalAmount = '';
            this.payMntName = '';
            this.payMntAddress1 = '';
            this.payMntAddress2 = '';
            this.payMntAddress3 = '';    
            this.payMntCity = '';
            this.payMntState = '';
            this.payMntPostalCode = '';
            this.contractNumber = '';
            this.cageCode = '';
            this.dunsNumber = '';
            this.receivedBy = '';
            this.pastDueBalancePrior = '';
            this.receivedByPay = '';
            this.paymentsRcvd = '';
            this.receivedByAdjust = '';
            this.adjustmentsRcvdAmt = '';
            this.receivedByBal = '';
            this.pastDueBalanceTotal = '';
            this.currentTotalAmount = '';
            this.totalBalance = '';
            this.invoiceStatus = '';
            this.invNumber = '';
            this.invName = '';
            this.invId = '';
        }
    }
    
    /*************************************************************
* ClassName : InvoiceLineInfo
* Description: Wrapper class to store Invoice Line details
**************************************************************/
    public class InvoiceLineInfo
    {
        public String siteID {get; set;}
        public String siteName {get; set;}
        public String invoiceID {get; set;}
        public String referenceID {get; set;}
        public String invoiceDate {get; set;}
        public String poNumber {get; set;}
        public list<ProductInfo> storageDetails {get; set;}
        public String totalStorageAmount {get; set;}
        public list<ProductInfo> serviceDetails {get; set;}
        public String totalServiceAmount {get; set;}
        public list<ProductInfo> otherDetails {get; set;}
        public String totalOtherAmount {get; set;}
        public String siteAdjustmentTotal {get; set;}
        public String siteNumber {get; set;}
        public String siteNumberTotal {get; set;}
        public String siteLateFeeAmount {get; set;}
        public String invoiceTotalAmount {get; set;}
        public String siteSubTotal {get; set;}
        public String siteTaxDescription1 {get; set;}
        public String siteTaxAmount1 {get; set;}
        public String siteTaxDescription2 {get; set;}
        public String siteTaxAmount2 {get; set;}
        public String siteTaxDescription3 {get; set;}
        public String siteTaxAmount3 {get; set;}
        
        /************************************
* Constructor for InvoiceLineInfo
*************************************/
        public InvoiceLineInfo()
        {
            this.siteID= '';
            this.siteName= '';
            this.invoiceID= '';
            this.referenceID= '';
            this.invoiceDate= '';
            this.poNumber= '';
            this.totalStorageAmount= '';
            this.totalServiceAmount= '';
            this.totalOtherAmount= '';
            this.siteAdjustmentTotal= '';
            this.siteNumber= '';
            this.siteNumberTotal= '';
            this.siteLateFeeAmount= '';
            this.invoiceTotalAmount= '';
            this.siteSubTotal = '';
            this.siteTaxDescription1 = '';
            this.siteTaxAmount1 = '';
            this.siteTaxDescription2 = '';
            this.siteTaxAmount2 = '';
            this.siteTaxDescription3 = '';
            this.siteTaxAmount3 = '';
        }
    }
    
    /*************************************************************
* ClassName : ProductInfo
* Description: Wrapper class to store Product details
**************************************************************/
    public class ProductInfo
    {
        public String billCD {get; set;}
        public String cLIN {get; set;}
        public String description {get; set;}
        public String quantityCnt {get; set;}
        public String rateAmount {get; set;}
        public String invoiceLineAmount {get; set;}
        public String taxLineAmount {get; set;}
        public String lineAmountTotal {get; set;}
        
        /************************************
* Constructor for ProductInfo
*************************************/
        public ProductInfo()
        {
            this.billCD = '';
            this.cLIN = '';
            this.description = '';
            this.quantityCnt = '';
            this.rateAmount = '';
            this.invoiceLineAmount = '';
            this.taxLineAmount = '';
            this.lineAmountTotal = '';
        }
    }
    
    /***********************************************************************
* ClassName : SupplementaryInfo
* Description: Wrapper class to store Additional details
************************************************************************/
    public class SupplementaryInfo
    {
        public Map<ID, String> productBillCodeMap {get; set;}
        public Map<ID, AdditionalInfo> accountAdditionalInfoMap {get; set;}
        public Map<String, String> productTranslationMap {get; set;}
        public Map<ID, Map<String, Decimal>> siteTaxDetailsMap {get; set;}
        
        public SupplementaryInfo()
        {
            this.productBillCodeMap = new Map<ID, String>();
            this.accountAdditionalInfoMap = new Map<ID, AdditionalInfo>();
            this.productTranslationMap = new Map<String, String>();
            this.siteTaxDetailsMap = new Map<ID, Map<String, Decimal>>();
        }
    }
    
    /***********************************************************************
* ClassName : AdditionalInfo
* Description: Wrapper class to store account level additional details
************************************************************************/
    public class AdditionalInfo
    {
        public String primaryContactEmail {get; set;}
        public String customerContactName {get; set;}
        public String Name {get; set;}
        public Map<Id, String> customerPO {get; set;}
        
        public String siteId {get; set;}
        public String siteName {get; set;}
        public String siteNumber {get; set;}
        public String countryISOCode {get; set;}
        public Map<String, String> productCodeMap {get; set;}
        
        /************************************
* Constructor for AdditionalInfo
*************************************/
        public AdditionalInfo()
        {
            this.primaryContactEmail = '';
            this.customerContactName = '';
            this.Name = '';
            this.customerPO = new Map<Id, String>();
            this.siteId = '';
            this.siteName = '';
            this.siteNumber = '';
            this.countryISOCode = '';
            this.productCodeMap = new Map<String, String>();
        }
    }
}