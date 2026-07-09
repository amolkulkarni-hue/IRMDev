/*****************************************************************************************************
* Class         : QTB_GenerateApixExtractBatch
* Test Class    : QTB_GenerateApexExtractCTRL_Test
* Author        : Virtusa
* Purpose       : This class containing logic for generating txt file for invoice
* Developer         Date          Description
* ------------------------------------------------------------------------------------------- 
*  Shailesh        12/06/2024      Gitlab US#24329 - Text File data created for Apix Extract from Invoice level
*******************************************************************************************************/
public class QTB_GenerateApixExtractBatch implements Database.Batchable<sObject>, Database.stateful{
    Id InvoiceId;
    List<blng__Invoice__c> invLst = new List<blng__Invoice__c>();
    boolean nordicBillingCountriesPresent;
    boolean isNordeaAcc;
    String contactEmail;
    List<IM_Country__c> country;
    List<String> usageCodes = New List<String>();
    set<string> usageLevelCode = new set<string>();
    String PaymentTerm = '';
    Date invoiceLineStartdate;
    Date invoiceLineEnddate; //#16008 Nordics print_to_date update to Invlin.Enddate
    map<string,string> maplocalization = new map<string,string>();
    Map<string, integer> L1L2L3L4GrpMap = new Map<string, integer>();
    Map<String, String> accLanguage = new Map<String, String>();
    String invNumber;string invName;string invStatus;
    set<string> accProductNames = new set<string>();
    set<string> accLan = new set<string>();
    //Gitlab US#25656
    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> finalGroupedUsages = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
    Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>finalGroupedUsagesMap = new Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();
    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> Level1Fina5GrpFinal = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
    
    public QTB_GenerateApixExtractBatch(List<blng__Invoice__c> invLstVar,boolean isNordicBillingCountriesPresent,boolean isNordeaAccVar,
                                        string contactEmailVar,List<IM_Country__c> countryVar, Map<String, String> accLanguageVar)
    {
        System.debug('QTB_GenerateApixExtractBatch@@');
        nordicBillingCountriesPresent = isNordicBillingCountriesPresent;
        this.InvoiceId = invLstVar[0].Id;
        invLst.addAll(invLstVar);
        isNordeaAcc = isNordeaAccVar;
        contactEmail = contactEmailVar;
        country = countryVar;
        accLanguage = accLanguageVar;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query InvoiceLine records related to the invoice
        String invoiceLineQuery = 'SELECT id,blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,blng__Product__r.QTB_PriceScheduleCategory__c,'+
            ' blng__OrderProduct__r.Product2.Name,blng__OrderProduct__r.Product2.ProductCode,blng__UsageSummary__c,blng__Product__c,'+
            ' blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,'+
            ' QTB_HasConsumptionSchedule__c,blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c,blng__StartDate__c,blng__OrderProduct__r.Product2.Id,'+
            ' blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c,blng__EndDate__c '+
            ' FROM blng__InvoiceLine__c '+
            ' WHERE blng__Invoice__c =:InvoiceId order by blng__Product__r.QTB_PriceScheduleCategory__c, blng__Product__r.Name' ;
        return Database.getQueryLocator(invoiceLineQuery);
    }
    
    //scope should be 1
    public void execute(Database.BatchableContext BC, List<blng__InvoiceLine__c> invoiceLineList) {
        try{
            // Process each chunk of invoiceline records
            if(invoiceLineList != null && !invoiceLineList.isEmpty()){
                Set<String> usageSummaries = new Set<String>();
                List<blng__InvoiceLine__c> recurringInvoiceLine = new List<blng__InvoiceLine__c>();
                
                for (blng__InvoiceLine__c invLin : invoiceLineList) {
                    if (String.isNotBlank(invLin.blng__UsageSummary__c)) {
                        usageSummaries.add(invLin.blng__UsageSummary__c);
                    }
                    
                    // As per New Architecture, Recurring Lines are decided by 'QTB_HasConsumptionSchedule__c'
                    // As per Story #6478 & #6509, Recurring Lines are decided by 'QTB_Charge_Type__c'
                    if (invLin.QTB_Charge_Type__c == 'Recurring') {
                        recurringInvoiceLine.add(invLin);
                    }
                    
                    if (String.isBlank(PaymentTerm) && invLin.blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c != null) {
                        PaymentTerm = invLin.blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c;
                    }
                    
                    if (invoiceLineStartdate == null && invLin.blng__StartDate__c != null) {
                        invoiceLineStartdate = invLin.blng__StartDate__c;
                    }
                    
                    //#16008 Nordics print_to_date update to Invlin.Enddate
                    if (invoiceLineEnddate == null && invLin.blng__EndDate__c != null) {
                        invoiceLineEnddate = invLin.blng__EndDate__c;
                    }
                }
                
                //Query for Usages related to invoice's usageSummaries with a proper Order 'QTB_Department_Code__c','QTB_Division_Code__c','QTB_Price_Schedule_Category__c' & 'product2.Name'
                //#13521
                //Added QTB_SITAD__c & blng__Account__r.name in below queries as part of Gitlab US #27216 & #28005
                List<blng__Usage__c> usages = new List<blng__Usage__c>();
                if(!usageSummaries.isEmpty()){
                    if(nordicBillingCountriesPresent){
                        usages = [SELECT blng__OrderProduct__r.Product2.Name,blng__OrderProduct__r.product2.ProductCode,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,
                                  blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Division_Code__c ,QTB_Department_Code__c ,QTB_Rated_Amount__c,
                                  blng__UsageSummary__r.blng__UnitPrice__c,blng__UnitPrice__c,blng__UsageSummary__r.blng__SummaryStartDate__c,blng__Subtotal__c,blng__Account__c,
                                  blng__OrderProduct__c,QTB_Department_Name__c,QTB_Custom_Invoice_Display__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,
                                  blng__Account__r.QTB_Language__c ,QTB_Level_1_Name__c ,QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Rated_Unit_Price__c,QTB_Invoice_Quantity__c,
                                  blng__PreratedQuantity__c,blng__PreratedAmount__c, blng__Quantity__c,QTB_Term__c,QTB_Work_Order_ID__c,QTB_Requestor__c,blng__OrderProduct__r.Product2.Id,
                                  QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c,QTB_Product_Identifier_1__c,QTB_Price_Tier__c, blng__Account__r.QTB_SITAD__c, blng__Account__r.name 
                                  FROM blng__Usage__c 
                                  WHERE blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c NULLS LAST, QTB_Division_Code__c NULLS LAST,QTB_Department_Code__c NULLS LAST, blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,QTB_Work_Order_ID__c NULLS LAST,blng__OrderProduct__r.product2.Name NULLS LAST];
                    }
                    else{
                        usages = [SELECT blng__OrderProduct__r.Product2.Name,blng__OrderProduct__r.product2.ProductCode,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,
                                  blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Division_Code__c ,QTB_Department_Code__c ,QTB_Rated_Amount__c,
                                  blng__UsageSummary__r.blng__UnitPrice__c,blng__UnitPrice__c,blng__UsageSummary__r.blng__SummaryStartDate__c,blng__Subtotal__c,blng__Account__c,
                                  blng__OrderProduct__c,QTB_Department_Name__c,QTB_Custom_Invoice_Display__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,
                                  blng__Account__r.QTB_Language__c ,QTB_Product_Identifier_1__c,QTB_Price_Tier__c,QTB_Level_1_Name__c ,QTB_Level_1_Code__c,QTB_Division_Name__c,
                                  QTB_Rated_Unit_Price__c ,QTB_Invoice_Quantity__c,blng__PreratedQuantity__c,blng__PreratedAmount__c, blng__Quantity__c,QTB_Term__c,
                                  QTB_Work_Order_ID__c,QTB_Requestor__c,blng__OrderProduct__r.Product2.Id,QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c, blng__Account__r.QTB_SITAD__c, blng__Account__r.name
                                  FROM blng__Usage__c 
                                  WHERE blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c NULLS LAST, QTB_Division_Code__c NULLS LAST,QTB_Department_Code__c NULLS LAST,QTB_Work_Order_ID__c NULLS LAST, blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,blng__OrderProduct__r.product2.Name NULLS LAST];
                    }
                }
                
                //Initialize necessary collections
                Map<String, QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> groupWrapperMap = new Map<String, QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                List<Map<String, QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>> usagesWrapperList = new List<Map<String, QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();                
                for (blng__Usage__c usg : usages) {
                    //Generate the key string
                    string keyString = '';
                    keyString = usg.QTB_Level_1_Code__c != null ? usg.QTB_Level_1_Code__c : 'Null';
                    keyString += usg.QTB_Department_Code__c != null ? usg.QTB_Department_Code__c : 'Null';
                    keyString += usg.QTB_Division_Code__c != null ? usg.QTB_Division_Code__c : 'Null';
                    
                    //Handle Price Schedule Category conditions
                    if (usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != null) {
                        if (usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Storage' &&
                            usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Transportation' &&
                            usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Supplies') 
                        {
                            keyString += 'Services';
                        } 
                        else {
                            keyString += usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                        }
                    }
                    else {
                        keyString += 'Null';
                    }
                    
                    //Add QTB_Product_Identifier_1__c and QTB_Price_Tier__c for NordicBilling countries
                    if (nordicBillingCountriesPresent) {
                        keyString += usg.QTB_Product_Identifier_1__c != null ? usg.QTB_Product_Identifier_1__c : 'Null';
                        keyString += usg.QTB_Price_Tier__c != null ? usg.QTB_Price_Tier__c : 'Null';//#20247 Addition of Price tier for grouping
                    }
                    
                    keyString += usg.blng__OrderProduct__r.product2.Name != null ? usg.blng__OrderProduct__r.product2.Name : 'Null';
                    keyString += usg.QTB_Rated_Unit_Price__c != null && invLst[0].blng__InvoiceStatus__c == 'Posted' 
                        ? String.valueOf(usg.QTB_Rated_Unit_Price__c)
                        : usg.blng__UsageSummary__r.blng__UnitPrice__c != null && invLst[0].blng__InvoiceStatus__c == 'Draft' 
                            ? String.valueOf(usg.blng__UsageSummary__r.blng__UnitPrice__c) 
                            : 'Null';
                    
                    // Add Work Order ID if it's a Nordea Account
                    keyString += (isNordeaAcc && usg.QTB_Work_Order_ID__c != null ? usg.QTB_Work_Order_ID__c : 'Null');
                    
                    // Add further grouping if QTB_Price_Schedule_Category__c is 'Storage'
                    if (usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c == 'Storage')
                    {
                        keyString += usg.QTB_Start_Date_MRC__c != null ? String.valueOf(usg.QTB_Start_Date_MRC__c) : 'Null';
                        keyString += usg.QTB_End_Date_MRC__c != null ? String.valueOf(usg.QTB_End_Date_MRC__c) : 'Null';
                    }
                    
                    //Update or create the map based on the key string
                    if (groupWrapperMap.containsKey(keyString)) {
                        QTB_GenerateApexExtractVFCTRL.GroupWrapperCls existingWrapper = groupWrapperMap.get(keyString);
                        groupWrapperMap.put(keyString, new QTB_GenerateApexExtractVFCTRL.GroupWrapperCls(usg, existingWrapper));
                    } else {
                        groupWrapperMap.put(keyString, new QTB_GenerateApexExtractVFCTRL.GroupWrapperCls(usg, null));
                    }
                    }
                // Add the final map to the list
                usagesWrapperList.add(groupWrapperMap);
                
                ///////////////
                //Sorting Records// Gopi Today
                List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> Level1Fina5Grp = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                if (!usages.isEmpty()) {
                    // Group wrapper records by different levels
                    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> Level1FinalGrp = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> Level1Fina2Grp = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> Level1Fina3Grp = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> Level1Fina4Grp = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> Level1FinalTierGrp = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                    
                    Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>> codeToLevel1Grp = new Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();
                    Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>> codeToLevel2Grp = new Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();
                    Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>> codeToLevel3Grp = new Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();
                    Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>> codeToLevel4Grp = new Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();
                    Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>> codeToLevel5Grp = new Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();
                    Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>> codeToLevelTierGrp = new Map<String, List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>>();
                    
                    List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> tempHolder = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                    
                    for (Map<String, QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> wrpMap : usagesWrapperList) {
                        for (QTB_GenerateApexExtractVFCTRL.GroupWrapperCls record : wrpMap.values()) {
                            if (record.lev1code != null) {
                                if (!codeToLevel1Grp.containsKey(record.lev1code)) {
                                    codeToLevel1Grp.put(record.lev1code, new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>());
                                }
                                codeToLevel1Grp.get(record.lev1code).add(record);
                            } else {
                                tempHolder.add(record);
                            }
                        }
                    }
                    for (List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> lev1 : codeToLevel1Grp.values()) {
                        Level1FinalGrp.addAll(lev1);
                    }
                    if (!tempHolder.isEmpty()) {
                        Level1FinalGrp.addAll(tempHolder);
                        tempHolder.clear();
                    }
                    
                    // Group by Level 2
                    for (QTB_GenerateApexExtractVFCTRL.GroupWrapperCls record : Level1FinalGrp) {
                        String keyStr = record.lev1code != null ? record.lev1code : 'Null';
                        keyStr += record.divisionCode != null ? record.divisionCode : 'Null';
                        
                        if (!codeToLevel2Grp.containsKey(keyStr)) {
                            codeToLevel2Grp.put(keyStr, new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>());
                        }
                        codeToLevel2Grp.get(keyStr).add(record);
                    }
                    for (List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> lev2 : codeToLevel2Grp.values()) {
                        Level1Fina2Grp.addAll(lev2);
                    }
                    
                    // Group by Level 3
                    for (QTB_GenerateApexExtractVFCTRL.GroupWrapperCls record : Level1Fina2Grp) {
                        String keyStr = record.lev1code != null ? record.lev1code : 'Null';
                        keyStr += record.divisionCode != null ? record.divisionCode : 'Null';
                        keyStr += record.departmentCode != null ? record.departmentCode : 'Null';
                        
                        if (!codeToLevel3Grp.containsKey(keyStr)) {
                            codeToLevel3Grp.put(keyStr, new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>());
                        }
                        codeToLevel3Grp.get(keyStr).add(record);
                    }
                    for (List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> lev3 : codeToLevel3Grp.values()) {
                        Level1Fina3Grp.addAll(lev3);
                    }
                    
                    // Group by Level 4
                    for (QTB_GenerateApexExtractVFCTRL.GroupWrapperCls record : Level1Fina3Grp) {
                        String keyStr = record.lev1code != null ? record.lev1code : 'Null';
                        keyStr += record.divisionCode != null ? record.divisionCode : 'Null';
                        keyStr += record.departmentCode != null ? record.departmentCode : 'Null';
                        keyStr += record.productIdentifier != null ? record.productIdentifier : 'Null';
                        
                        if (!codeToLevel4Grp.containsKey(keyStr)) {
                            codeToLevel4Grp.put(keyStr, new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>());
                        }
                        codeToLevel4Grp.get(keyStr).add(record);
                    }
                    for (String keys : codeToLevel4Grp.keySet()) {
                        Level1Fina4Grp.addAll(codeToLevel4Grp.get(keys));
                    }
                    
                    // Group by Price Tier
                    for (QTB_GenerateApexExtractVFCTRL.GroupWrapperCls record : Level1Fina4Grp) {
                        String keyStr = record.lev1code != null ? record.lev1code : 'Null';
                        keyStr += record.divisionCode != null ? record.divisionCode : 'Null';
                        keyStr += record.departmentCode != null ? record.departmentCode : 'Null';
                        keyStr += record.productIdentifier != null ? record.productIdentifier : 'Null';
                        keyStr += record.priceTier != null ? record.priceTier : 'Null';
                        
                        if (!codeToLevelTierGrp.containsKey(keyStr)) {
                            codeToLevelTierGrp.put(keyStr, new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>());
                        }
                        codeToLevelTierGrp.get(keyStr).add(record);
                    }
                    for (String keys : codeToLevelTierGrp.keySet()) {
                        Level1FinalTierGrp.addAll(codeToLevelTierGrp.get(keys));
                    }
                    
                    // Group by Schedule Category
                    for (QTB_GenerateApexExtractVFCTRL.GroupWrapperCls record : Level1FinalTierGrp) {
                        String keyStr = record.lev1code != null ? record.lev1code : 'Null';
                        keyStr += record.divisionCode != null ? record.divisionCode : 'Null';
                        keyStr += record.departmentCode != null ? record.departmentCode : 'Null';
                        keyStr += record.productIdentifier != null ? record.productIdentifier : 'Null';
                        keyStr += record.priceTier != null ? record.priceTier : 'Null';
                        
                        if (isNordeaAcc) {
                            keyStr += record.workOrderId != null ? record.workOrderId : 'Null';
                        }
                        
                        keyStr += record.scheduleCategory != null ? record.scheduleCategory : 'Null';
                        
                        if (!codeToLevel5Grp.containsKey(keyStr)) {
                            codeToLevel5Grp.put(keyStr, new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>());
                        }
                        codeToLevel5Grp.get(keyStr).add(record);
                    }
                    for (String keys : codeToLevel5Grp.keySet()) {
                        Level1Fina5Grp.addAll(codeToLevel5Grp.get(keys));
                    }
                    
                }
                
                //3 level of grouping
                //Grouping based on certain field values(lev1code, divisionCode, departmentCode,workOrderId(Nordea))
                if(!usages.isEmpty()){
                    //for(GroupWrapperCls ar : wrpMap.values()){
                    for(QTB_GenerateApexExtractVFCTRL.GroupWrapperCls ar : Level1Fina5Grp){
                       Level1Fina5GrpFinal.add(ar);//Gitlab US#25656
                }
                System.debug('Level1Fina5GrpFinal_Execute@@'+Level1Fina5GrpFinal);
                    }
                //Adding Recurring InvoiceLine at the end of all Usages Wrapper
                if(recurringInvoiceLine.size() > 0 || Test.isRunningTest()){
                    for(blng__InvoiceLine__c invLine : recurringInvoiceLine){
                        //Create dummy blng__Usage__c record from Invoice Line for the tempGroupWrapper wrapper class as we need to show Recurring invoice lines as line No 20
                        blng__Usage__c tempUsages = new blng__Usage__c();
                        tempUsages.QTB_Invoice_Quantity__c = invLine.blng__Quantity__c;
                        tempUsages.blng__UnitPrice__c = invLine.blng__UnitPrice__c;
                        tempUsages.blng__Subtotal__c = invLine.blng__Subtotal__c;
                        tempUsages.blng__Account__c = invLine.blng__Invoice__r.blng__Account__c;
                        tempUsages.QTB_Cost_Center__c = invLine.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                        tempUsages.blng__MatchingAttribute__c = invLine.blng__OrderProduct__r.Product2.Name;
                        tempUsages.blng__ErrorMessage__c = invLine.blng__OrderProduct__r.Product2.ProductCode;
                        tempUsages.QTB_UsedforRerate__c = invLine.blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c;
                        tempUsages.QTB_Service_District__c = invLine.blng__Invoice__r.blng__Account__r.QTB_Language__c;
                        
                        /************** Changes for Story #1317 Starts **************/  
                        QTB_GenerateApexExtractVFCTRL.GroupWrapperCls tempGroupWrapper = new QTB_GenerateApexExtractVFCTRL.GroupWrapperCls(tempUsages,null);    
                        tempGroupWrapper.productId = (tempGroupWrapper.productId == null) ? invLine.blng__OrderProduct__r.Product2.Id : tempGroupWrapper.productId;
                        tempGroupWrapper.productName = (tempGroupWrapper.productName == null) ? invLine.blng__OrderProduct__r.Product2.Name : tempGroupWrapper.productName; 
                        if (tempGroupWrapper.displayPnameCheck == false && invLine.blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c == true) { 
                            tempGroupWrapper.displayPnameCheck = true;  
                        }   
                        /************** Changes for Story #1317 Ends **************/    
                        accProductNames.add(String.valueOf(invLine.blng__OrderProduct__r.Product2.ProductCode));
                        accLan.add(String.valueOf(invLine.blng__Invoice__r.blng__Account__r.QTB_Language__c)); //What is Account Language for Invoice Line
                        //Add the blng__Usage__c record to the wrapper class as a new record
                        finalGroupedUsages.add(tempGroupWrapper);
                    }
                }
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApixExtractBatch_execute');  
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        try{
            //query localization records for converting product name based on account lan
            list<SBQQ__Localization__c> localization = new list<SBQQ__Localization__c>();
            
            if(!accProductNames.isEmpty() && !accLan.isEmpty()){
                localization = [SELECT id,SBQQ__Text__c,SBQQ__Product__r.Name,SBQQ__Product__r.ProductCode,SBQQ__APIName__c,SBQQ__Language__c 
                                FROM SBQQ__Localization__c 
                                WHERE SBQQ__Product__r.ProductCode IN: accProductNames and SBQQ__Language__c IN: accLan and SBQQ__APIName__c = 'Name'];  
                //Create a Map as key productcode + language -> Translated value of that Product Name
                for(SBQQ__Localization__c loc:localization){
                    string locKey = loc.SBQQ__Product__r.ProductCode+' '+loc.SBQQ__Language__c;
                    maplocalization.put(locKey,loc.SBQQ__Text__c);
                }
            }
            
            //Query for Active 'PurchaseOrder' related to invoice billing account
            List<QTB_PurchaseOrder__c> purchaseOrderLst = new List<QTB_PurchaseOrder__c>();
            set<String> purchaseOrderLists = new set<String>();    
            List<String> purchaseOrderList = new List<String>();    
            purchaseOrderLst= [SELECT Name,QTB_Status__c,QTB_Division__c,QTB_Customer_PO__c,QTB_Div_Dept_Level__c,QTB_Customer_Id__c, 
                                 (SELECT Id, Name, QTB_Account__c, QTB_Purchase_Order__c FROM PurchaseOrderAccounts__r) 
                               FROM QTB_PurchaseOrder__c 
                               WHERE Id IN (SELECT QTB_Purchase_Order__c FROM QTB_PurchaseOrderAccount__c WHERE QTB_Account__c =:invLst[0].blng__Account__c) 
                                    And QTB_Status__c= 'Active']; // Gitlab #31452  
            if(purchaseOrderLst != null && purchaseOrderLst.size()>0){ 
                for(QTB_PurchaseOrder__c poLst:purchaseOrderLst)  {
                    //Add all PurchaseOrder Names
                    if((poLst.QTB_Division__c == null || poLst.QTB_Division__c == '') && (poLst.QTB_Div_Dept_Level__c == null || poLst.QTB_Div_Dept_Level__c == '') && poLst.QTB_Customer_PO__c != null && poLst.QTB_Customer_PO__c != '')
                        purchaseOrderLists.add(poLst.QTB_Customer_PO__c);  
                }
                if(purchaseOrderLists.size() > 0){
                    purchaseOrderList.addAll(purchaseOrderLists);
                }
            }
            
                        //Gitlab US#25656
            if(Level1Fina5GrpFinal != null){
                for(QTB_GenerateApexExtractVFCTRL.GroupWrapperCls ar : Level1Fina5GrpFinal){
                    System.debug('ar@@'+ar);
                    //Add all the wrapper records to a Final Wrapper List 
                    finalGroupedUsages.add(ar);
                    usageLevelCode.add(String.valueOf(ar.lev1code));
                    accProductNames.add(String.valueOf(ar.productCode));
                    accLan.add(String.valueOf(ar.AccLanguage));
                    //Check the records for grouping and adding line '40th Line' at the proper place
                    string grpKeyString = '';
                    string grpKeyOrder = '';
                    if(ar.lev1code != null){
                        grpKeyString += ar.lev1code;
                        usageCodes.add(String.valueOf(ar.lev1code));
                    }
                    if(ar.divisionCode != null){
                        grpKeyString += ar.divisionCode;
                        usageCodes.add(String.valueOf(ar.divisionCode));
                    }
                    if (ar.departmentCode != null){
                        grpKeyString += ar.departmentCode;
                        usageCodes.add(String.valueOf(ar.departmentCode));
                    }
                    
                    //If the Account is a Nordea Account
                    if(isNordeaAcc){
                        if(ar.workOrderId != null){
                            grpKeyString += ar.workOrderId;
                        }
                    }
                    System.debug('grpKeyString@@'+grpKeyString);
                    //#13521 Addition of keystring to the new map for Subtotal calculation
                    if(grpKeyString != ''){
                        if(L1L2L3L4GrpMap.containsKey(grpKeyString)){
                            L1L2L3L4GrpMap.put(grpKeyString,L1L2L3L4GrpMap.get(grpKeyString)+1);
                        }else{
                            L1L2L3L4GrpMap.put(grpKeyString,1);
                        }
                        
                        if(!finalGroupedUsagesMap.containsKey(grpKeyString)) {
                            finalGroupedUsagesMap.put(grpKeyString, new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls> { ar });
                        }
                        else{
                            finalGroupedUsagesMap.get(grpKeyString).add(ar);
                        }
                    }
                    //#13521
                    if(nordicBillingCountriesPresent){
                        if (ar.productIdentifier != null){
                            grpKeyString += ar.productIdentifier;
                            usageCodes.add(String.valueOf(ar.productIdentifier));
                        }
                        if (ar.priceTier != null){
                            grpKeyString += ar.priceTier;
                            usageCodes.add(String.valueOf(ar.priceTier));
                        }
                    }
                }
            }
            //Gitlab US#25656
            if(!finalGroupedUsagesMap.isEmpty()){
                finalGroupedUsages = new List<QTB_GenerateApexExtractVFCTRL.GroupWrapperCls>();
                for(string key : finalGroupedUsagesMap.keySet()){
                    for(QTB_GenerateApexExtractVFCTRL.GroupWrapperCls ar : finalGroupedUsagesMap.get(key)){
                        System.debug('ar_final@@'+ar);
                        finalGroupedUsages.add(ar);
                    }
                }  
            }
            
            //Initialize data for wrapper
            List<QTB_GenerateApexExtractVFCTRL.wrapper> wrapList = new List<QTB_GenerateApexExtractVFCTRL.wrapper>();
            List<QTB_GenerateApexExtractVFCTRL.usagewrapper> usagewrapperList = new List<QTB_GenerateApexExtractVFCTRL.usagewrapper>();
            QTB_GenerateApexExtractVFCTRL obj = new QTB_GenerateApexExtractVFCTRL();
            obj.nordicBillingCountriesPresent = nordicBillingCountriesPresent;
            wrapList = obj.mappingToTxt(invLst[0],purchaseOrderList,contactEmail,country,accLanguage,usageCodes,usageLevelCode,null,PaymentTerm,invoiceLineStartdate,invoiceLineEnddate);
            if(!finalGroupedUsages.isEmpty()){
                usagewrapperList = obj.mappingToUsage(finalGroupedUsages,country,invLst[0],purchaseOrderLst,maplocalization,isNordeaAcc ,L1L2L3L4GrpMap);
            }   
            
            // Convert wrapList to JSON and store it in the custom metadata type
            String jsonData1 = JSON.serialize(wrapList);
            String jsonData2 = JSON.serialize(usagewrapperList);           
            //Split and set the JSON data into the invoice fields
            splitAndSetUsageData(jsonData1,jsonData2,invLst[0]);
            
            invNumber = invLst[0].QTB_Custom_Invoice_Number__c;
            invName = invLst[0].Name;
            // Now call the VF page via queueable class and get content bcoz it should executed after the data inserted in invoice 
            System.enqueueJob(new QTB_GenerateApixExtractQueueable(invLst,true));
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApixExtractBatch_finish');  
        }
    }
    
    // Helper method to split JSON data into multiple fields
    public static void splitAndSetUsageData(String jsonData1, String data, blng__Invoice__c invoiceVar) {
        Integer maxTextAreaLength = 131072; // Long Text area field max length is 131,072
        List<String> fieldNames = new List<String>();
        fieldNames.add('QTB_StoreApixUsageExtract1__c');
        fieldNames.add('QTB_StoreApixUsageExtract2__c');
        fieldNames.add('QTB_StoreApixUsageExtract3__c');
        fieldNames.add('QTB_StoreApixUsageExtract4__c');
        fieldNames.add('QTB_StoreApixUsageExtract5__c');
        fieldNames.add('QTB_StoreApixUsageExtract6__c');
        
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.Id = invoiceVar.Id;
        invoice.QTB_StoreApixInvoiceExtract__c = jsonData1;
        
        for(Integer i = 0; i < fieldNames.size() && data.length() > 0; i++) 
        {
            if (data.length() > maxTextAreaLength) {
                invoice.put(fieldNames[i], data.substring(0, maxTextAreaLength));
                data = data.substring(maxTextAreaLength);
            } else {
                invoice.put(fieldNames[i], data);
                data = '';
            }
        }
        update invoice;
        System.debug('finish_inv@@'+invoice); 
    }
    
    public static String getCustomLabelTranslation(String labelName, String lang) {
        switch on labelName {
            when 'Services' {
                if (lang == 'da') return 'Ydelser';
                else if (lang == 'fi') return 'Palvelut';
                // else if (lang == 'fr') return 'Prestations de service';
                else if (lang == 'no') return 'Tjenester';
                else if (lang == 'sv') return 'Tjänster';
                //else if (lang == 'th') return 'บริการ';
                else return 'Services';
            }
            when 'Transportation' {
                if (lang == 'da') return 'Transport';
                else if (lang == 'fi') return 'Kuljetus';
                //else if (lang == 'fr') return 'Transport';
                else if (lang == 'no') return 'Transport';
                else if (lang == 'sv') return 'Transport';
                //else if (lang == 'th') return 'การขนส่ง';
                else return labelName;
            }
            when 'Other Program Fees' {
                if (lang == 'da') return 'Andre omkostninger';
                else if (lang == 'fi') return 'Muut palvelut';
                // else if (lang == 'fr') return 'Autres frais du programme';
                else if (lang == 'no') return 'Andre omkostninger';
                else if (lang == 'sv') return 'Andra omkostnader';
                // else if (lang == 'th') return 'ค่าธรรมเนียมโปรแกรมอื่นๆ';
                else return labelName;
            }
            when 'Storage' {
                if (lang == 'da') return 'Opbevaring';
                else if (lang == 'fi') return 'Säilytys';
                //else if (lang == 'fr') return 'Stockage';
                else if (lang == 'no') return 'Leie';
                else if (lang == 'sv') return 'Arkivering';
                // else if (lang == 'th') return 'พื้นที่จัดเก็บ';
                else return labelName;
            }
            when 'Supplies' {
                if (lang == 'da') return 'Emballage';
                else if (lang == 'fi') return 'Tarvikkeet';
                // else if (lang == 'fr') return 'Fournitures';
                else if (lang == 'no') return 'Emballasje';
                else if (lang == 'sv') return 'Emballage';
                //else if (lang == 'th') return 'เสบียง';
                else return labelName;
            }
            when else {//all other category will consider as Services
                if (lang == 'da') return 'Tjenester';
                else if (lang == 'fi') return 'Palvelut';
                else if (lang == 'no') return 'Tjenester';
                else if (lang == 'fr') return 'Prestations de service';
                else if (lang == 'sv') return 'Tjänster';
                else if (lang == 'th') return 'บริการ';
                else return 'Services'; 
            }
        }
    }
}