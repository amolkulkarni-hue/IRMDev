/*****************************************************************************************************
* Class: QTB_QuoteTemplateController
* Author: Accenture
* Requirement : SFCPQBLG-37/SFCPQBLG-39
* Purpose: Custom Controller for Quote Template VF Page
* Change History: 9/25/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture     5/12/2020
* Accenture  24/12/2020    Changes added to support for deal upto 10 years GitLab # 46
* Accenture    01/04/2021      line 268, added where clause to the customer billing account records
* Accenture    01/04/2021      line 347, added where clause to the customer billing account records
* Accenture    01/07/2021      line 389, added fix for french template translation
* IRM          04/08/2021     Changes to support #1334

*******************************************************************************************************/
public with sharing class QTB_QuoteTemplateController {
    public static final String REGEXCHAR = '[\\(\\)\\[\\]\\{\\}\\,]';
    public static final String NOUOM = 'No UOM';
    public static boolean throwExplicitException = false;
    //gitlab# 746 arranged the category name
    public static List<String> categorySortList = new List<String>{
        QTB_Constants.STORAGE,
            QTB_Constants.SERVICES,
            QTB_Constants.SUPPLIES,
            QTB_Constants.OTHERPROGRAMFEES,
            QTB_Constants.TRANSPORTATION,
            QTB_Constants.SERVICES_ON_SITE,
            QTB_Constants.SERVICES_OFF_SITE
            };
                
    public static SBQQ__Quote__c originalQuote;
    public static boolean IS_FUEL_SURCHARGE { get; set; }
    public static boolean IS_MIX_AND_MATCH_BUNDLE { get; set; } 
    public static boolean IS_PAPER_SURCHARGE { get; set; }
    public static boolean IS_INITIAL_MOVE { get; set; }
    public static boolean SHOW_TIER_PRICE { get; set; }
    public static boolean IS_DISPLAY_IN_PRICE_SCHEDULE { get; set; }
    public static boolean PRODUCT_CLASS { get; set; }
    public String rm_render_check { get; set; }
    public String dm_render_check { get; set; }
    public String shred_render_check { get; set; }
    public String smb_render_check { get; set; }
    public String storage_render_check { get; set; }
    public String canada_country { get; set; }
    public String unitedstates_country { get; set; }
    public final String TRANSPORTATION { get; private set; }
    public String freeProducts { get; private set; }
    public List<SBQQ__QuoteLine__c> sbqqquoteline { get; set; }
    public List<SBQQ__QuoteLine__c> subsProdcuts{get; set;}
    public map<id, id> selectedcsQuotelineMap { get; set; }
    public set<id> quotelineIds;
    public map<id, list<SBQQ__QuoteLineConsumptionRate__c>> quotelineRatesMap {
        get;
        set;
    }
    public list<SBQQ__QuoteLineConsumptionRate__c> quotelineConsumptionRates {
        get;
        set;
    }
    public List<QTB_Customer_Billing_Account_Lookup__c> customerBilling {
        get;
        set;
    }
    public List<SBQQ__QuoteDocument__c> sbqqDocument { get; set; }
    public List<SBQQ__Quote__c> quotedetail { get; set; }
    public Map<id, String> mapQuotelineText { get; set; }
    public Map<Id, String> uomLabelMap { get; set; }
    public Map<Id, Map<String, Decimal>> qlfinalunitPriceMap {
        get;
        private set;
    }
    public Map<String, String> yearPriceMap { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> quoteLineMap { get; set; }
    public Map<Id, Decimal> quoteLineTierMap { get; set; }
    public List<String> categList { get; set; }
    public Map<String, String> categoryLabelMap { get; set; }
    
    public static string selectedLang { get; set; }
    public static Id recID { get; set; }
    public static Id templateID { get; set; }
    public static Id draftQuoteID { get; set; }
    
    public Integer colspan { get; set; }
    public Integer rowspan { get; set; }
    public Integer storageCounter { get; set; }
    public Integer invoiceCounter { get; set; }
    public Integer workOrderCounter { get; set; }
    public String website { get; set; }
    public String support_website { get; set; }
    public String recycling_website { get; set; }
    public String phoneNumber { get; set; }
    
    public static Boolean IS_EUR { get; set; }
    public Integer colspan6_10 { get; private set; }
    public Map<id, String> mapProduct { get; private set; }
    public static boolean NA_Surcharge{get;set;}    
    public set<string> SMBPapreShredBillCodes;
    
    public static boolean isClassicTapeSubPresent { get; set; }
    /***********************************************************************************************************
    * Class: QTB_QuoteTemplateController
    * Parameters: ApexPages.StandardController
    * Requirement : SFCPQBLG-37/SFCPQBLG-39
    * Description: Constructor Class for the Apex controller
    **************************************************************************************************************/
    public QTB_QuoteTemplateController(
        ApexPages.StandardController controller
    ) {
        recID =(Id) ApexPages.currentPage().getParameters().get(QTB_Constants.QID);
        system.debug('**********************recId'+recID);
        templateID = (Id) ApexPages.currentPage().getParameters().get(QTB_Constants.TID);
        selectedLang = ApexPages.currentPage()
            .getParameters()
            .get(QTB_Constants.LANGUAGE);
        
        rm_render_check = QTB_Constants.RECORDS_MANAGEMENT;
        dm_render_check = QTB_Constants.DATA_MANAGEMENT;
        shred_render_check = QTB_Constants.SHRED;
        smb_render_check = QTB_Constants.SMB_PACKAGES;
        storage_render_check = QTB_Constants.STORAGE;
        canada_country = QTB_Constants.CANADA_COUNTRY;
        unitedstates_country = QTB_Constants.US_COUNTRY;
        TRANSPORTATION = 'Transportation';
        fetchQuotelineData();
    }
    
    /***********************************************************************************************************
    * Method : fetchQuotelineData
    * Parameters: None
    * Return Type : List<SBQQ__Quote__c>
    * Requirement : SFCPQBLG-37/SFCPQBLG-39
    * Description: Method to fetch all data to be displayed on the VF quote template
    **************************************************************************************************************/
    public void fetchQuotelineData(){
        PRODUCT_CLASS = false;
        SHOW_TIER_PRICE = false;
        IS_FUEL_SURCHARGE = false;
        IS_PAPER_SURCHARGE = false;
        IS_DISPLAY_IN_PRICE_SCHEDULE = false;
        IS_INITIAL_MOVE = false;
        IS_EUR = false;
        NA_Surcharge = false;   
        isClassicTapeSubPresent = false;
        //Get all the Papre Shred related SMB Package Bill codes from Custom Label //Git #3146  
        if(System.label.QTB_SMBSurchargeProductCodesNA != null){          
          SMBPapreShredBillCodes = new set<string>();   
          //Tried to use the existing variable temporarily  
          categList = new list<string>();   
          categList = System.label.QTB_SMBSurchargeProductCodesNA.split(','); 
          //Keep the values in Map from list as it's easy to check the values in a Key form.    
          SMBPapreShredBillCodes.addAll(categList); 
          categList.clear();    
        }
        IS_MIX_AND_MATCH_BUNDLE = false;
        quotedetail = new List<SBQQ__Quote__c>();
        mapQuotelineText = new Map<id, String>();
        subsProdcuts = new List<SBQQ__QuoteLine__c>();
        quotelineIds = new Set<id>();
        sbqqquoteline = new List<SBQQ__QuoteLine__c>();
        quotelineConsumptionRates = new List<SBQQ__QuoteLineConsumptionRate__c>();
        quoteLineMap = new Map<String, List<SBQQ__QuoteLine__c>>();
        quotelineTierMap = new Map<Id, Decimal>();
        quotelineRatesMap = new Map<id, list<SBQQ__QuoteLineConsumptionRate__c>>();
        qlfinalunitPriceMap = new Map<Id, Map<String, Decimal>>();
        yearPriceMap = new Map<String, String>();
        categList = new List<String>();
        categoryLabelMap = new Map<String, String>();
        customerBilling = new List<QTB_Customer_Billing_Account_Lookup__c>();
        sbqqDocument = new List<SBQQ__QuoteDocument__c>();
        selectedcsQuotelineMap = new Map<id, id>();
        selectedLang = ApexPages.currentPage()
            .getParameters()
            .get(QTB_Constants.LANGUAGE);
        Set<Id> prodId = new Set<Id>();
        Set<Id> bundleProductId = new Set<Id>();
        uomLabelMap = new Map<Id, String>();
        mapProduct = new Map<Id, String>();
        colspan = 3;
        rowspan = 2;
        storageCounter = 3;
        invoiceCounter = 3;
        workOrderCounter = 3;
        colspan6_10 = 2;
        
        try { 
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            //This query is used to fetch quote details which will be displayed on quote document including quote line data.
            quotedetail = [
                SELECT
                Id,
                Name,
                SBQQ__Type__c,
                SBQQ__Opportunity2__c,
                QTB_IM_Legal_Entity__r.Name,
                SBQQ__Opportunity2__r.QTB_Original_Quote__c,
                QTB_Opportunity_Billing_Country__c,
                QTB_Invoice_Minimum_Start_Date__c,
                QTB_Work_Order_Minimum_Charges__c,
                QTB_Work_Order_Minimum_Start_Date__c,
                QTB_Invoice_Minimum_Charges__c,
                QTB_Free_Up_Start__c,
                SBQQ__QuoteLanguage__c,
                QTB_Price_Schedule_Term__c,
                QTB_Minimum_Charges_Start_Date__c,
                QTB_Minimum_Storage_Charges__c,
                QTB_Free_Month_1__c,
                QTB_Free_Month_2__c,
                QTB_Free_Month_3__c,
                QTB_PWD_Amount__c,
                QTB_Subscription_Exemptions__c,
                QTB_Free_Product_Names__c,
                SBQQ__Account__r.Name,
                QTB_Free_Products_Term__c,
                QTB_IPP_Amount__c,
                QTB_Free_Up_End__c,
                QTB_Pricing_Expiration_Date__c,
                QTB_Year_5_Start__c,
                QTB_Year_5_End__c,
                QTB_Year_4_Start__c,
                QTB_Year_4_End__c,
                QTB_Year_3_Start__c,
                QTB_Year_3_End__c,
                SBQQ__StartDate__c,
                QTB_Year_2_Start__c,
                QTB_Year_2_End__c,
                SBQQ__EndDate__c,
                SBQQ__BillingName__c,
                QTB_Year_2_Uplift__c,
                QTB_Year_3_Uplift__c,
                QTB_Year_4_Uplift__c,
                QTB_Year_5_Uplift__c,
                QTB_Year_10_End__c,
                QTB_Opportunity_Product_Line__c,
                SBQQ__CustomerAmount__c,
                CurrencyISOCode,
                SBQQ__PaymentTerms__c,
                QTB_Late_Fees__c,
                QTB_Year_6_Uplift__c,
                QTB_Year_7_Uplift__c,
                QTB_Year_8_Uplift__c,
                QTB_Year_9_Uplift__c,
                QTB_Year_10_Uplift__c,
                QTB_Year_6_Start__c,
                QTB_Year_6_End__c,
                QTB_Year_7_Start__c,
                QTB_Year_7_End__c,
                QTB_Year_8_Start__c,
                QTB_Year_8_End__c,
                QTB_Year_9_Start__c,
                QTB_Year_9_End__c,
                QTB_Year_10_Start__c,
                QTB_DocumentCurrencySymbol__c,
                QTB_Foreversafe_Billing__c,
                QTB_Fuel_Surcharge_Exempt__c,
                (
                    SELECT
                    id,
                    SBQQ__Quote__c,
                    SBQQ__Quote__r.QTB_Year_6_Uplift__c,
                    SBQQ__Quote__r.QTB_Year_7_Uplift__c,
                    SBQQ__Quote__r.QTB_Year_8_Uplift__c,
                    SBQQ__Quote__r.QTB_Year_9_Uplift__c,
                    SBQQ__Quote__r.QTB_Year_10_Uplift__c,
                    SBQQ__Bundled__c,
                    SBQQ__Product__r.IM_Product_Class__c,
                    SBQQ__Product__r.Name,
                    SBQQ__OptionLevel__c,
                    SBQQ__Bundle__c,
                    QTB_Display_in_Price_Schedule__c,
                    SBQQ__ProductName__c,
                    SBQQ__ProductCode__c,
                    QTB_Target_Price__c,
                    QTB_Final_Unit_Price__c,
                    QTB_Final_Unit_Price_2__c,
                    QTB_Final_Unit_Price_3__c,
                    QTB_Final_Unit_Price_4__c,
                    QTB_Final_Unit_Price_5__c,
                    QTB_Final_Unit_Price_6__c,
                    QTB_Final_Unit_Price_7__c,
                    QTB_Final_Unit_Price_8__c,
                    QTB_Final_Unit_Price_9__c,
                    QTB_Final_Unit_Price_10__c,
                    SBQQ__Product__r.QTB_Price_Schedule_Category__c,
                    SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__c,
                    SBQQ__ProductFamily__c,
                    QTB_Unit_of_Measure__c,
                    SBQQ__ListPrice__c,
                    SBQQ__Number__c,
                    Name,
                    QTB_Offered_for_Free__c,
                    CurrencyISOCode,
                    SBQQ__HasConsumptionSchedule__c,
                    QTB_Tier_List_Price__c,
                    QTB_QL_Consumption_Schedule_RecordID__c,
                    SBQQ__RequiredBy__r.SBQQ__ProductCode__c //adding parent product code to identify classic tape subscription quote Story #13088
                    FROM SBQQ__LineItems__r
                    WHERE
                    (QTB_Display_in_Price_Schedule__c = TRUE
                     OR QTB_Offered_for_Free__c = TRUE)
                    AND SBQQ__Quantity__c > 0
                    //Gitlab#746 sorted the product on quote document by Name
                    ORDER BY SBQQ__Number__c
                ),
                (
                    SELECT
                    id,
                    QTB_IMSight_Number__c,
                    QTB_Billing_Account__r.QTB_Billing_Account_Invoice_Name__c,
                    QTB_Billing_Account__c,
                    QTB_Pricefx_Customer_ID__c
                    FROM Customer_Billing_Account_Lookup__r
                    WHERE
                    QTB_Billing_Account__c != NULL // added for novacop fix
                    AND QTB_Pricefx_Customer_ID__c != NULL // added for novacop fix
                )
                FROM SBQQ__Quote__c
                WHERE id = :recID
            ]; //QTB_Unit_of_Measure__c added for SFCPQBLG-963
            String QTB_SubscriptionExemptions = quotedetail[0].QTB_Subscription_Exemptions__c;   
            //Check Quote for Mix & Match Products
            if(String.isNotBlank(QTB_SubscriptionExemptions) &&
               String.isNotEmpty(QTB_SubscriptionExemptions) && 
               QTB_SubscriptionExemptions.contains('Fuel Surcharge;Invoice Minimums;Storage Minimums')){
                IS_MIX_AND_MATCH_BUNDLE = true; 
            }
            draftQuoteID = [
                SELECT id, Name
                FROM SBQQ__QuoteTemplate__c
                WHERE Name = :QTB_Constants.DRAFT_PRICE
            ]
                .id;
            IS_EUR = quotedetail[0].CurrencyIsoCode == 'EUR';
            //Website Mapping
            for (QTB_Template_Footer_Mapping__mdt metadataRec : [
                SELECT
                Id,
                QTB_Opportunity_Country__c,
                QTB_Document_Language__c,
                QTB_Website__c,
                QTB_Phone__c,
                QTB_Primary_Website__c,
                QTB_Paper_Recycling_Website__c,
                QTB_Support_Website__c
                FROM QTB_Template_Footer_Mapping__mdt
                WHERE
                QTB_Opportunity_Country__c = :quotedetail[0].QTB_Opportunity_Billing_Country__c
            ]) {
                if (metadataRec.QTB_Paper_Recycling_Website__c != null) {
                    recycling_website = metadataRec.QTB_Paper_Recycling_Website__c;
                }
                if (metadataRec.QTB_Support_Website__c != null) {
                    support_website = metadataRec.QTB_Support_Website__c;
                }
                if (metadataRec.QTB_Document_Language__c == null) {
                    website = metadataRec.QTB_Website__c;
                    phoneNumber = metadataRec.QTB_Phone__c;
                } else if (
                    metadataRec.QTB_Document_Language__c != selectedLang &&
                    metadataRec.QTB_Primary_Website__c == true
                ) {
                    website = metadataRec.QTB_Website__c;
                    phoneNumber = metadataRec.QTB_Phone__c;
                } else if (
                    metadataRec.QTB_Document_Language__c == selectedLang
                ) {
                    website = metadataRec.QTB_Website__c;
                    phoneNumber = metadataRec.QTB_Phone__c;
                    break;
                }
            }
            
            if (
                (quotedetail[0].SBQQ__Type__c ==
                 QTB_Constants.QUOTE_TYPE_RENEWAL ||
                 quotedetail[0].SBQQ__Type__c ==
                 QTB_Constants.QUOTE_TYPE_AMEND) &&
                quotedetail[0].SBQQ__Opportunity2__c != null &&
                quotedetail[0].SBQQ__Opportunity2__r.QTB_Original_Quote__c !=
                null
            ) {
                originalQuote = [
                    SELECT
                    id,
                    name,
                    (
                        SELECT
                        Id,
                        QTB_Pricefx_Customer_ID__c,
                        QTB_Billing_Account__c,
                        QTB_Billing_Account__r.QTB_Billing_Account_Invoice_Name__c,
                        QTB_Compound_Key__c,
                        QTB_Quote__c,
                        QTB_IMSight_Number__c
                        FROM Customer_Billing_Account_Lookup__r
                        WHERE
                        QTB_Billing_Account__c != NULL // added for novacop fix
                        AND QTB_Pricefx_Customer_ID__c != NULL // added for novacop fix
                    )
                    FROM SBQQ__Quote__c
                    WHERE
                    Id = :quotedetail[0]
                    .SBQQ__Opportunity2__r.QTB_Original_Quote__c
                ];
            }
            //Storage Minimum Table Counter
            if (
                quotedetail[0].QTB_Minimum_Charges_Start_Date__c !=
                quotedetail[0].SBQQ__StartDate__c &&
                quotedetail[0].QTB_Minimum_Charges_Start_Date__c != null &&
                quotedetail[0].QTB_Minimum_Storage_Charges__c != null &&
                quotedetail[0].QTB_Minimum_Storage_Charges__c != 0
            ) {
                storageCounter = storageCounter + 1;
            }
            
            //Invoice Minimum Table Counter
            if (
                quotedetail[0].QTB_Invoice_Minimum_Start_Date__c !=
                quotedetail[0].SBQQ__StartDate__c &&
                quotedetail[0].QTB_Invoice_Minimum_Start_Date__c != null &&
                quotedetail[0].QTB_Invoice_Minimum_Charges__c != null &&
                quotedetail[0].QTB_Invoice_Minimum_Charges__c != 0
            ) {
                invoiceCounter = invoiceCounter + 1;
            }
            
            //WorkOrder Minimum Table Counter
            if (
                quotedetail[0].QTB_Work_Order_Minimum_Start_Date__c !=
                quotedetail[0].SBQQ__StartDate__c &&
                quotedetail[0].QTB_Work_Order_Minimum_Start_Date__c != null &&
                quotedetail[0].QTB_Work_Order_Minimum_Charges__c != null &&
                quotedetail[0].QTB_Work_Order_Minimum_Charges__c != 0
            ) {
                workOrderCounter = workOrderCounter + 1;
            }
            
            //Main Table Counter
            if (
                quotedetail[0].QTB_Year_2_Uplift__c != null &&
                quotedetail[0].QTB_Opportunity_Product_Line__c !=
                QTB_Constants.SMB_PACKAGES
            ) {
                colspan = colspan + 1;
            }
            if (
                quotedetail[0].QTB_Year_3_Uplift__c != null &&
                quotedetail[0].QTB_Opportunity_Product_Line__c !=
                QTB_Constants.SMB_PACKAGES
            ) {
                colspan = colspan + 1;
            }
            if (
                quotedetail[0].QTB_Year_4_Uplift__c != null &&
                quotedetail[0].QTB_Opportunity_Product_Line__c !=
                QTB_Constants.SMB_PACKAGES
            ) {
                colspan = colspan + 1;
            }
            if (
                quotedetail[0].QTB_Year_5_Uplift__c != null &&
                quotedetail[0].QTB_Opportunity_Product_Line__c !=
                QTB_Constants.SMB_PACKAGES
            ) {
                colspan = colspan + 1;
            }
            // Year 6 - 10 table column counter
            if (
                quotedetail[0].QTB_Opportunity_Product_Line__c !=
                QTB_Constants.SMB_PACKAGES
            ) {
                if (quotedetail[0].QTB_Year_6_Uplift__c != null) {
                    colspan6_10 += 1;
                }
                if (quotedetail[0].QTB_Year_7_Uplift__c != null) {
                    colspan6_10 += 1;
                }
                if (quotedetail[0].QTB_Year_8_Uplift__c != null) {
                    colspan6_10 += 1;
                }
                if (quotedetail[0].QTB_Year_9_Uplift__c != null) {
                    colspan6_10 += 1;
                }
                if (quotedetail[0].QTB_Year_10_Uplift__c != null) {
                    colspan6_10 += 1;
                }
            }
            // GitLab # 863, collect offered for free Product Ids
            List<Id> freePoductIds = new List<Id>();
            //Map of Category and List of Quote Lines
            if (!quotedetail.isEmpty()) {
                for (
                    SBQQ__QuoteLine__c line : quotedetail[0].SBQQ__LineItems__r
                ) {
                    prodId.add(line.SBQQ__Product__c);
                   // system.debug('Product');
                    sbqqquoteline.add(line);
                    quotelineIds.add(line.id);
                    if (
                        !line.QTB_Tier_List_Price__c &&
                        line.QTB_QL_Consumption_Schedule_RecordID__c <> null
                    ) {
                        selectedcsQuotelineMap.put(
                            line.id,
                            id.valueof(
                                line.QTB_QL_Consumption_Schedule_RecordID__c
                            )
                        );
                    }
                   
                   // Checking for Subscription Prodcuts
                   if(line.SBQQ__OptionLevel__c == 1 && line.SBQQ__Bundle__c == true){
                    subsProdcuts.add(line);
                    }
                    System.debug('***subsProdcuts***'+subsProdcuts);
                    if (
                        line.SBQQ__Product__r.Name ==
                        QTB_Constants.FUEL_SURCHARGE
                    ) {
                        IS_FUEL_SURCHARGE = true;
                    }
                    if (line.QTB_Display_in_Price_Schedule__c = true) {
                        IS_DISPLAY_IN_PRICE_SCHEDULE = true;
                    }
                    /*if (
                        line.SBQQ__Product__r.Name ==
                        QTB_Constants.PAPER_SURCHARGE
                    ) {
                        IS_PAPER_SURCHARGE = true;
                    }*/
                    //NA Paper Surcharge // Check if Shred LOB has been selected    
                    //OR    
                    //Shred SMB Bundle package with specific Product Codes Git #3146   
                    if(NA_Surcharge != true && (quotedetail[0].QTB_Opportunity_Billing_Country__c == unitedstates_country || quotedetail[0].QTB_Opportunity_Billing_Country__c == canada_country) && (quotedetail[0].QTB_Opportunity_Product_Line__c == shred_render_check ||   
                    (quotedetail[0].QTB_Opportunity_Product_Line__c == smb_render_check     
                    && line.SBQQ__ProductCode__c != null   
                    && SMBPapreShredBillCodes.contains(line.SBQQ__ProductCode__c)))){  
                        NA_Surcharge = true;    
                    }
                    if (
                        line.SBQQ__Product__r.Name == QTB_Constants.INITIAL_MOVE
                    ) {
                        IS_INITIAL_MOVE = true;
                    }
                     
                    if (
                        line.SBQQ__Product__r.QTB_Price_Schedule_Category__c !=
                        null &&
                        !quoteLineMap.containsKey(
                            line.SBQQ__Product__r.QTB_Price_Schedule_Category__c
                        )
                    ) {
                        quoteLineMap.put(
                            line.SBQQ__Product__r.QTB_Price_Schedule_Category__c,
                            new List<SBQQ__QuoteLine__c>{ line }
                        );
                    } else if (
                        line.SBQQ__Product__r.QTB_Price_Schedule_Category__c !=
                        null &&
                        quoteLineMap.containsKey(
                            line.SBQQ__Product__r.QTB_Price_Schedule_Category__c
                        )
                    ) {
                        quoteLineMap.get(
                            line.SBQQ__Product__r.QTB_Price_Schedule_Category__c
                        )
                            .add(line);
                    }
                    if (selectedLang == QTB_Constants.ENGLISH_LANGUAGE) {
                        mapProduct.put(
                            line.SBQQ__Product__c,
                            line.SBQQ__Product__r.Name
                        );
                        System.debug(LoggingLevel.INFO, line.SBQQ__Product__c + '==>' + mapProduct.get(line.SBQQ__Product__c));
                    }
                    if (
                        line.SBQQ__Product__r.IM_Product_Class__c ==
                        QTB_Constants.SECURE_SHREDDING
                    ) {
                        PRODUCT_CLASS = true;
                    }
                    if (line.QTB_Unit_of_Measure__c != null) {
                        //Map of QuoteLineId and UOM Custom Label Name
                        String uom = line.QTB_Unit_of_Measure__c;
                        String labelName =
                            QTB_Constants.QTB_PREFIX +
                            uom.replaceAll(
                                QTB_Constants.SPACE_CONST,
                                QTB_Constants.UNDERSCORE_CONST
                            );
                        labelName = labelName.replaceAll(
                            QTB_Constants.SLASH_CONST,
                            QTB_Constants.UNDERSCORE_CONST
                        );
                        labelName = labelName.replaceAll(REGEXCHAR, '');
                        uomLabelMap.put(line.id, labelName);
                    } else {
                        uomLabelMap.put(line.id, NOUOM);
                    }
                    
                    if (line.QTB_Offered_for_Free__c) {
                        freePoductIds.add(line.SBQQ__Product__c);
                    }
                    
                    //Logic to check if classic tape subscription is present in the quote
                    if (!isClassicTapeSubPresent && line.SBQQ__RequiredBy__c != null && 
                        line.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null && 
                        line.SBQQ__RequiredBy__r.SBQQ__ProductCode__c == System.Label.QTB_Classic_Tape_Subscription) {
                        isClassicTapeSubPresent = true;
                    }
                                        
                }
                if (originalQuote != null) {
                    for (
                        QTB_Customer_Billing_Account_Lookup__c custBilling : originalQuote.Customer_Billing_Account_Lookup__r
                    ) {
                      
 						if(custBilling.QTB_Billing_Account__r.QTB_Billing_Account_Invoice_Name__c.contains('&')){
                       		custBilling.QTB_Billing_Account__r.QTB_Billing_Account_Invoice_Name__c =String.valueof(custBilling.QTB_Billing_Account__r.QTB_Billing_Account_Invoice_Name__c.replace('&', 'And'));
                        }else{
                       		custBilling.QTB_Billing_Account__r.QTB_Billing_Account_Invoice_Name__c =custBilling.QTB_Billing_Account__r.QTB_Billing_Account_Invoice_Name__c;
                        }                        
                        custBilling.QTB_Pricefx_Customer_ID__c = custBilling.QTB_Pricefx_Customer_ID__c;
                        customerBilling.add(custBilling);
                    }
					
                }
            }
            
            for (String categ : categorySortList) {
                if (quoteLineMap.containsKey(categ)) {
                    categList.add(categ);
                    String labelName =
                        QTB_Constants.QTB_PREFIX +
                        categ.replaceAll(
                            QTB_Constants.SPACE_CONST,
                            QTB_Constants.UNDERSCORE_CONST
                        );
                    labelName = labelName.replaceAll(
                        QTB_Constants.HYPHEN_CONST,
                        QTB_Constants.UNDERSCORE_CONST
                    );
                    categoryLabelMap.put(categ, labelName);
                }
            }
            System.debug(quoteLineMap.get('Transportation'));
            //If selected language is other than English then translate product data 
            if (selectedLang != QTB_Constants.ENGLISH_LANGUAGE) {
                for (SBQQ__Localization__c local : [
                    SELECT
                    id,
                    SBQQ__Product__c,
                    SBQQ__Label__c,
                    SBQQ__APIName__c,
                    SBQQ__Text__c,
                    SBQQ__Language__c,
                    SBQQ__Product__r.Name
                    FROM SBQQ__Localization__c
                    WHERE
                    SBQQ__Product__c IN :prodId
                    AND SBQQ__Language__c = :selectedLang
                    AND SBQQ__APIName__c = 'Name'
                ]) {
                    mapProduct.put(local.SBQQ__Product__c, local.SBQQ__Text__c);
                    System.debug(
                        LoggingLevel.INFO,
                        local.SBQQ__Product__c + ' in ' + selectedLang + ' is ' + local.SBQQ__Text__c
                    );
                }
            }
            System.debug(LoggingLevel.DEBUG, 'Localization found for ' + mapProduct.size());
            System.debug(
                LoggingLevel.DEBUG,
                '----- Consumption Schedules -----\n' +
                String.valueOf(selectedcsQuotelineMap)
            );
            //Query to fetch quote line consumption rates data which will be displayed on quote document
            quotelineConsumptionRates = [
                SELECT
                id,
                SBQQ__LowerBound__c,
                SBQQ__UpperBound__c,
                SBQQ__PricingMethod__c,
                SBQQ__ProcessingOrder__c,
                QTB_First_Tier_Price1__c,
                QTB_FirstTier2ndYr__c,
                QTB_FirstTier3rdYr__c, 
                QTB_FirstTier4thYr__c,  
                QTB_FirstTier5thYr__c,  
                QTB_FirstTier6thYr__c,
                QTB_FirstTier7thYr__c,
                QTB_FirstTier8thYr__c,
                QTB_FirstTier9thYr__c,
                QTB_FirstTier10thYr__c, 
                SBQQ__QuoteLineConsumptionSchedule__c,
                SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c,
                SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__r.id
                FROM SBQQ__QuoteLineConsumptionRate__c
                WHERE
                SBQQ__QuoteLineConsumptionSchedule__c IN :selectedcsQuotelineMap.values()
                ORDER BY SBQQ__ProcessingOrder__c
            ];
            
            for (
                SBQQ__QuoteLineConsumptionRate__c eachRate : quotelineConsumptionRates
            ) {
                Id quotelineId = eachRate.SBQQ__QuoteLineConsumptionSchedule__r.SBQQ__QuoteLine__c;
                
                if (quotelineRatesMap.containsKey(quotelineId)) {
                    quotelineRatesMap.get(quotelineId).add(eachRate);
                } else {
                    quotelineRatesMap.put(
                        quotelineId,
                        new List<SBQQ__QuoteLineConsumptionRate__c>{ eachRate }
                    );
                }
            }
            System.debug(
                LoggingLevel.DEBUG,
                '----- Consumption Rates -----\n' +
                String.valueOf(quotelineRatesMap)
            );
            // system.debug('quotelinerates'+quotelineRatesMap);
            for (SBQQ__QuoteLine__c quotline : sbqqquoteline) {
                System.debug('ProductMapping');
                if (                 
                    mapProduct != null &&
                    mapProduct.containskey(quotline.SBQQ__Product__c) &&
                    String.isNotBlank(mapProduct.get(quotline.SBQQ__Product__c))                    
                ) {
                    mapQuotelineText.put(
                        quotline.id,
                        mapProduct.get(quotline.SBQQ__Product__c)
                    );
                } else {
                    mapQuotelineText.put(
                        quotline.id,
                        quotline.SBQQ__Product__r.Name
                    );
                    // if the product does not exist in the productname by productid map
                    mapProduct.put(quotline.SBQQ__Product__c, quotline.SBQQ__Product__r.Name);
                }
            }
          
            // GitLab # 863, Generate the free product names in comma separated fashion
            // from the free product ids
            List<String> freeProductTranslatedNames = new List<String>();
            for (Id freeProductId : freePoductIds) {
                freeProductTranslatedNames.add(mapProduct.get(freeProductId));
            }
            freeProducts = String.join(freeProductTranslatedNames, ', ');
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                QTB_QuoteLineHelper.class.getname()
            );
        }
    }
    @TestVisible
    private Decimal getUpliftedPrice(
        Decimal currentPrice,
        Decimal upliftPercent
    ) {
        return (currentPrice *
                (1 + (upliftPercent == null ? 0 : upliftPercent / 100)));
    }
    // GitLab # 490
    // To display appplied promotions to quote
    public List<QTB_Quote_Promotion__c> getQuotePromotionDetails() {
        Id quoteId = (Id) ApexPages.currentPage()
            .getParameters()
            .get(QTB_Constants.QID);
        List<QTB_Quote_Promotion__c> promotions = new List<QTB_Quote_Promotion__c>();
        promotions = [
            SELECT
            Id,
            Name,
            QTB_Promotion_Name__c,
            QTB_Promo_Product__c,
            QTB_Promotion_End_Date__c,
            QTB_Promo_Percent__c,
            QTB_Promo_Amount__c
            FROM QTB_Quote_Promotion__c
            WHERE QTB_Quote__c = :quoteId
        ];
        return promotions;
    }
}