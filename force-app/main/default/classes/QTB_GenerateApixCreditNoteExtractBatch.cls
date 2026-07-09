/*****************************************************************************************************
* Class         : QTB_GenerateApixCreditNoteExtractBatch
* Test Class    : QTB_GenerateApixCNExtractBatch_Test
* Author        : Virtusa
* Purpose       : This class containing logic for generating txt file for invoice
* Developer         Date          Description
* ------------------------------------------------------------------------------------------- 
*  Shailesh        12/06/2024      Gitlab US#24329 - Text File data created for Apix Extract from Invoice level
*******************************************************************************************************/
public class QTB_GenerateApixCreditNoteExtractBatch implements Database.Batchable<sObject>, Database.stateful{
    Id creditNoteId;
    public QTB_Generate_Creditnote_Ctrl.HeaderLines Header ;
    public List<QTB_Generate_Creditnote_Ctrl.usagewrapper> lstusagewrapper = new List<QTB_Generate_Creditnote_Ctrl.usagewrapper>();
    public List<QTB_Generate_Creditnote_Ctrl.LineItems> CrLineItems = new List<QTB_Generate_Creditnote_Ctrl.LineItems>();
    Map<String, String> accountLanguage = new Map<String, String>();
    // Map of  Value vs Translated label of price schedule category
    public Map<String, String> prScCategoryTranslation = new Map<String, String>();
    String ContactEmail;
    //Credit Note Billing Status for Draft and Posted Credit Notes
    public static final String CREDITNOTE_DRAFT_BILLING_STATUS = 'PRC';
    public static final String CREDITNOTE_POSTED_BILLING_STATUS = 'CRE';
    //#13894 NordicBilling Country specific Bill Code population
    public Boolean nordicBillingCountriesPresent {get; set;}
    //#15993 On Account Credit check 
    public Boolean nordicsOnAccountCheck {get; set;}
    public AggregateResult[] creditLines;
    public List<String> InvoiceNumbers = New  List<String>{};
    public List<blng__CreditNote__c> creditNotes;
    String ISOCode ='';
    String Language;
    public integer invnum = 1;
    public static boolean throwExplicitException = false;
    public List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> finalGroupedUsages = new List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
    Map<Id,blng__CreditNoteLine__c> prdQty = new Map<Id,blng__CreditNoteLine__c>(); // #2300
    Map<string, integer> L1L2L3L4GrpMap = new Map<string, integer>();
    
    public QTB_GenerateApixCreditNoteExtractBatch(Id creditNoteIdVar)
    {
        System.debug('QTB_GenerateApixCreditNoteExtractBatch@@');
        creditNoteId = creditNoteIdVar;
        accountLanguage.put('no', 'NOR');
        accountLanguage.put('fi', 'FIN');
        accountLanguage.put('da', 'DAN');
        accountLanguage.put('sv', 'SVE');
        accountLanguage.put('en_US', 'ENG');
        accountLanguage.put('th', 'Thai');
        accountLanguage.put('zh_TW', 'Chinese Traditional');
        accountLanguage.put('en_GB', 'English(UK)');
        
        //translated value of price schedule category
        Schema.DescribeFieldResult statusOptions = product2.QTB_Price_Schedule_Category__c.getDescribe();
        for(Schema.PicklistEntry p : statusOptions.getPicklistValues()){
            prScCategoryTranslation.put(String.valueOf(p.getValue()), String.valueOf(p.getLabel()));
        }
        
        //Query for CreditNote related information
        //15993 Addition of QTB_On_Account_Credit__c in the query
        //#21361 Addition of override fields
        creditNotes = [SELECT Id,name,blng__Status__c,blng__Notes__c,QTB_Custom_Invoice_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                       blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                       blng__Account__r.QTB_Language__c,blng__CreditNoteDate__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                       blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c,
                       blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c,
                       blng__Account__r.QTB_EDI_Identifier__c, blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,
                       blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c, 
                       blng__Account__r.QTB_Invoice_Notes__c,blng__Subtotal__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__TotalAmount__c,
                       QTB_Total_Amount_with_Tax_Override__c,CurrencyIsoCode,QTB_On_Account_Credit__c 
                       FROM blng__CreditNote__c WHERE Id =: creditNoteId];
        
        //Query for AccountContactRelation related to Credit Note account
        List<AccountContactRelation> billingCont= [SELECT ContactId,QTB_Primary__c,Roles 
                                                   FROM AccountContactRelation 
                                                   WHERE QTB_Primary__c = true and AccountId=:creditNotes[0].blng__Account__c and Roles includes ('Billing')];
        
        if(billingCont != null && billingCont.size()>0 && billingCont[0].ContactId != null)
        {              
            Contact BillingContact = [select name,email,Phone from contact where id=:billingCont[0].ContactId];
            ContactEmail = BillingContact.email;
        }
        
        String legalEntCountry = creditNotes[0].blng__Account__r.QTB_Contract_Entity__r.blng__Country__c; 
        if(legalEntCountry!=null && legalEntCountry!='')
        {
            List<IM_Country__c> CRCountry = [SELECT Iso31662Code__c FROM IM_Country__c WHERE Name = :legalEntCountry and Active__c = true];
            ISOCode = CRCountry[0].Iso31662Code__c;
        }
        
        //#15993 - On_Account Credit note Items querying for Nordic Billing countries 
        //-------Start of logic to check Nordic country Git #13894-----/
        List<String> nordicCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
        for(String country:nordicCountries)
        {
            if(creditNotes[0].blng__Account__r.QTB_Legal_Entity_Country__c == country){
                nordicBillingCountriesPresent = true;
                break;
            }
        }
        //#15993 On Account check 
        if(creditNotes[0].QTB_On_Account_Credit__c == TRUE ){
            nordicsOnAccountCheck = true;
        }
        //-------End of logic to check Nordic country Git #13894-----/
        
        if(nordicBillingCountriesPresent != null && nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == TRUE){
            system.debug('On Account Query >>> ');
            creditLines = [SELECT CurrencyIsoCode currCode, sum(QTB_Credit_Quantity__c) Qty,sum(QTB_Subtotal__c) subTotal,QTB_Invoice__r.QTB_Custom_Invoice_Number__c InvNum, 
                           blng__Product__r.QTB_Price_Schedule_Category__c scheduleCategory, blng__Product__r.Name ProdName, sum(blng__InvoiceLine__r.QTB_Unit_Price__c) unitPrice,
                           QTB_Product_Identifier_1__c productIdentifier,QTB_Custom_Invoice_Display__c CusInvDisplay  
                           FROM blng__CreditNoteLine__c
                           WHERE blng__CreditNote__c = :creditNoteId GROUP BY CurrencyIsoCode, blng__Product__r.QTB_Price_Schedule_Category__c,
                           QTB_Invoice__r.QTB_Custom_Invoice_Number__c, blng__Product__r.Name, QTB_Product_Identifier_1__c,QTB_Custom_Invoice_Display__c]; 
        }
        else{
            //Query for Credit Line Items related to Credit Note group by Currency, Product Schedule, Product, Invoice
            creditLines = [SELECT CurrencyIsoCode currCode, sum(QTB_Credit_Quantity__c) qty,sum(QTB_Subtotal__c) subTotal, QTB_Invoice__r.QTB_Custom_Invoice_Number__c InvNum, 
                           blng__Product__r.QTB_Price_Schedule_Category__c scheduleCategory, blng__Product__r.Name ProdName,sum(blng__InvoiceLine__r.QTB_Unit_Price__c) unitPrice
                           FROM blng__CreditNoteLine__c 
                           WHERE blng__CreditNote__c = :creditNoteId GROUP BY CurrencyIsoCode, blng__Product__r.QTB_Price_Schedule_Category__c,
                           QTB_Invoice__r.QTB_Custom_Invoice_Number__c, blng__Product__r.Name]; 
        }
        set<string> ProductNames = new set<string>();
        Language = creditNotes[0].blng__Account__r.QTB_Language__c;
        
        for(AggregateResult ar: creditLines){
            if(!InvoiceNumbers.contains(String.valueOf(ar.get('InvNum'))))
                InvoiceNumbers.add(String.valueOf(ar.get('InvNum')));  
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query InvoiceLine records related to the invoice
        String creditNoteLineQuery ='SELECT Id,Name,QTB_Invoice__r.QTB_Custom_Invoice_Number__c,blng__Product__r.Name,blng__Product__c,blng__CreditNote__c,blng__Subtotal__c,'+
            ' blng__InvoiceLine__c,QTB_Credit_Quantity__c, blng__InvoiceLine__r.blng__UsageSummary__c,blng__CreditNote__r.QTB_Country__c,blng__Product__r.QTB_Price_Schedule_Category__c '+
            ' FROM blng__CreditNoteLine__c WHERE blng__CreditNote__c =: creditNoteId Order By blng__Product__r.QTB_Price_Schedule_Category__c,blng__Product__r.Name';
        return Database.getQueryLocator(creditNoteLineQuery);
    }
    
    //scope should be 1
    public void execute(Database.BatchableContext BC, List<blng__CreditNoteLine__c> creditNoteLineList) {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            // Process each chunk of creditNoteLine record
            set<string> usageSummaries = new set<string>();
           
            Map<Id,String> invoiceMap = new Map<Id,String>();
            boolean onAccountCredit = false;
            if(creditNoteLineList != null && !creditNoteLineList.isEmpty()){   
                for(blng__CreditNoteLine__c crdline:creditNoteLineList){
                    if(crdline.blng__InvoiceLine__r.blng__UsageSummary__c != null){
                        usageSummaries.add(crdline.blng__InvoiceLine__r.blng__UsageSummary__c);
                        if( !invoiceMap.containskey(crdline.blng__InvoiceLine__r.blng__UsageSummary__c)){
                            invoiceMap.put(crdline.blng__InvoiceLine__r.blng__UsageSummary__c,crdline.QTB_Invoice__r.QTB_Custom_Invoice_Number__c); 
                        }
                        // # 2300 capture the Usage summary and creditnoteline
                        if(!prdQty.containskey(crdline.blng__Product__c)){
                            prdQty.put(crdline.blng__InvoiceLine__r.blng__UsageSummary__c,crdline);
                        }
                    }
                }
                //#15993 QTB_On_Account_Credit__c check for nordics billing countries
                if(nordicBillingCountriesPresent!=null && nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == FALSE)
                {
                    // lstusagewrapper = new List<QTB_Generate_Creditnote_Ctrl.usagewrapper>(); //Gitlab US#24329 -- commented, declared at class level
                    //Query for Usages related to invoice's usageSummaries with a proper Order 'QTB_Department_Code__c','QTB_Division_Code__c','QTB_Price_Schedule_Category__c' & 'product2.Name'
                    //#13521
                    List<blng__Usage__c> usages = new List<blng__Usage__c>();
                    if(!usageSummaries.isEmpty()){
                        usages = [SELECT blng__UsageSummary__c,blng__OrderProduct__r.Product2.Name ,blng__OrderProduct__r.product2.ProductCode,QTB_Start_Date_MRC__c,
                                  QTB_End_Date_MRC__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Division_Code__c ,QTB_Department_Code__c,QTB_Rated_Amount__c,
                                  blng__UsageSummary__r.blng__UnitPrice__c,blng__UnitPrice__c,blng__UsageSummary__r.blng__SummaryStartDate__c,blng__Subtotal__c,blng__Account__c,
                                  blng__OrderProduct__c,QTB_Department_Name__c,QTB_Custom_Invoice_Display__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,
                                  blng__Account__r.QTB_Language__c ,QTB_Level_1_Name__c ,QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Rated_Unit_Price__c ,QTB_Invoice_Quantity__c,
                                  blng__PreratedQuantity__c,blng__PreratedAmount__c, blng__Quantity__c,QTB_Term__c,QTB_Work_Order_ID__c,QTB_Requestor__c,
                                  blng__OrderProduct__r.Product2.Id,QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c,QTB_Product_Identifier_1__c,QTB_Price_Tier__c 
                                  FROM blng__Usage__c 
                                  WHERE blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c NULLS LAST, QTB_Division_Code__c NULLS LAST,
                                  QTB_Department_Code__c NULLS LAST, blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,QTB_Work_Order_ID__c NULLS LAST,
                                  blng__OrderProduct__r.product2.Name NULLS LAST];
                    }
                    
                    
                    Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> groupWrapperMap = new Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                    List<Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>> usagesWrapperList = new List<Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>>();
                    
                    for(blng__Usage__c usg : usages){
                        string keyString = '';
                        //#21175 Level 1 code addition
                        if(usg.QTB_Level_1_Code__c != null){
                            keyString = usg.QTB_Level_1_Code__c;
                        }else{
                            keyString = 'Null';
                        }
                        //#21175 Level 1 code (+)
                        if(usg.QTB_Department_Code__c != null){
                            keyString += usg.QTB_Department_Code__c;
                        }else{
                            keyString += 'Null';
                        }
                        if(usg.QTB_Division_Code__c != null){
                            keyString += usg.QTB_Division_Code__c;
                        }else{
                            keyString += 'Null';
                        }
                        if(usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != null){
                            keyString += usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                        }
                        else{
                            keyString += 'Null';
                        }
                        if(usg.QTB_Product_Identifier_1__c != null){
                            keyString += usg.QTB_Product_Identifier_1__c;
                        }else{
                            keyString += 'Null';
                        }
                        
                        //2300 Adding Invoice number
                        if(invoiceMap.get(usg.blng__UsageSummary__c) != null){
                            keyString +=invoiceMap.get(usg.blng__UsageSummary__c);
                        }else{
                            keyString += 'Null';
                        }
                        //#20247 Addition of Price tier for grouping
                        if(usg.QTB_Price_Tier__c != null){
                            keyString += usg.QTB_Price_Tier__c;
                        }else{
                            keyString += 'Null';
                        }
                        if(usg.blng__OrderProduct__r.product2.Name != null){
                            keyString += usg.blng__OrderProduct__r.product2.Name;
                        }else{
                            keyString += 'Null';
                        }
                        //Create Map based on Key and add map to the List for maintaining the 'Proper Order/ Sequence'
                        if(usagesWrapperList.size() > 0){
                            boolean addMapToList = true;
                            for(Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> wrpMap : usagesWrapperList){
                                //Already key exist
                                if(wrpMap.containskey(keyString)){
                                    addMapToList = false;
                                    QTB_Generate_Creditnote_Ctrl.GroupWrapperCls wrp = wrpMap.get(keyString);
                                    //Over ride the map 
                                    wrpMap.put(keyString,new QTB_Generate_Creditnote_Ctrl.GroupWrapperCls(usg,wrp));
                                }
                            }
                            if(addMapToList){
                                groupWrapperMap = new Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                                //Create new Map, so pass null
                                groupWrapperMap.put(keyString,new QTB_Generate_Creditnote_Ctrl.GroupWrapperCls(usg,null));
                                usagesWrapperList.add(groupWrapperMap);
                            }
                        }else{
                            groupWrapperMap = new Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                            //Create new Map, so pass null 
                            groupWrapperMap.put(keyString,new QTB_Generate_Creditnote_Ctrl.GroupWrapperCls(usg,null));
                            usagesWrapperList.add(groupWrapperMap);
                        }
                    }
                    //Variable Declaration
                    String[] usageCodes = New String[]{};
                        set<string> usageLevelCode = new set<string>();
                    set<string> accProductNames = new set<string>();
                    Map<string, integer> L1L2L3GrpMap = new Map<string, integer>();
                    //#13521 New map to hold keystring without product identifier value
                    
                    List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> finalGroupedUsagesTemp = new List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                    List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> tempOrderList = new List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                    List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> tempOrderListFinal = new List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                    set<string> checkDup = new set<string>();
                    Map<string, integer> L1L2L3GrpCompareMap = new Map<string, integer>();
                    //3 level of grouping
                    //Grouping based on certain field values(lev1code, divisionCode, departmentCode,workOrderId(Nordea))
                    if(!usages.isEmpty()){
                        //Iterate all the wrapper records
                        for(Map<string,QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> wrpMap : usagesWrapperList){
                            for(QTB_Generate_Creditnote_Ctrl.GroupWrapperCls ar : wrpMap.values()){
                                //Add all the wrapper records to a Final Wrapper List 
                                finalGroupedUsagesTemp.add(ar);
                                usageLevelCode.add(String.valueOf(ar.lev1code));
                                accProductNames.add(String.valueOf(ar.productCode));
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
                                //#13521 Addition of keystring to the new map for Subtotal calculation
                                if(grpKeyString != ''){
                                    if(L1L2L3L4GrpMap.containsKey(grpKeyString)){
                                        L1L2L3L4GrpMap.put(grpKeyString,L1L2L3L4GrpMap.get(grpKeyString)+1);
                                    }else{
                                        L1L2L3L4GrpMap.put(grpKeyString,1);
                                    }
                                }
                                if (ar.productIdentifier != null){
                                    grpKeyString += ar.productIdentifier;
                                    usageCodes.add(String.valueOf(ar.productIdentifier));
                                }
                                //#20247 Addition of Price Tier 
                                if (ar.priceTier != null){
                                    grpKeyString += ar.priceTier;
                                    usageCodes.add(String.valueOf(ar.priceTier));
                                }
                                //Add to Grouping Map which contains Number of records fr each Group(Key).
                                if(grpKeyString != ''){
                                    if(L1L2L3GrpMap.containsKey(grpKeyString)){
                                        L1L2L3GrpMap.put(grpKeyString,L1L2L3GrpMap.get(grpKeyString)+1);
                                    }else{
                                        L1L2L3GrpMap.put(grpKeyString,1);
                                    }
                                }
                            }
                        }
                        //Keep all the schedule category in a Order manner
                        for(QTB_Generate_Creditnote_Ctrl.GroupWrapperCls ar : finalGroupedUsagesTemp){
                            string grpKeyString = '';
                            
                            if(ar.lev1code != null){
                                grpKeyString += ar.lev1code;
                                
                            }
                            if(ar.divisionCode != null){
                                grpKeyString += ar.divisionCode;
                                
                            }
                            if (ar.departmentCode != null){
                                grpKeyString += ar.departmentCode;
                                
                            }
                            if (ar.productIdentifier != null){
                                grpKeyString += ar.productIdentifier;
                            }
                            //#20247 Addition of Price Tier
                            if (ar.priceTier != null){
                                grpKeyString += ar.priceTier;
                            }
                            //Add to Grouping Map
                            if(grpKeyString != ''){
                                if(L1L2L3GrpCompareMap.containsKey(grpKeyString)){
                                    L1L2L3GrpCompareMap.put(grpKeyString,L1L2L3GrpCompareMap.get(grpKeyString)+1);
                                }else{
                                    L1L2L3GrpCompareMap.put(grpKeyString,1);
                                }
                            }else{
                                //These are the records where we don't have L1/L2/L3
                                finalGroupedUsages.add(ar);
                            }
                            //Grouping key present or not
                            if(L1L2L3GrpMap.containsKey(grpKeyString)){
                                //Grouping number matches means the grouping is already having the full records for this group
                                if(L1L2L3GrpMap.get(grpKeyString) == L1L2L3GrpCompareMap.get(grpKeyString)){
                                    //Multiple records are there in the group
                                    if(tempOrderListFinal.size() > 0){
                                        //As we have added the current record so need to Sort/Order for the schedule catagory
                                        if(checkDup.contains(ar.schedulecategory)){
                                            for(integer i=0; i< tempOrderList.size() ; i++){
                                                if(tempOrderList[i].schedulecategory == ar.schedulecategory){
                                                    tempOrderListFinal.add(i,ar);
                                                    break;
                                                }
                                            }
                                            tempOrderList.clear();
                                            tempOrderList.addAll(tempOrderListFinal);
                                        }else{
                                            checkDup.add(ar.schedulecategory);
                                            tempOrderList.add(ar);
                                            tempOrderListFinal.add(ar);
                                        }
                                        
                                        finalGroupedUsages.addAll(tempOrderListFinal);
                                    }else{//First time number matches
                                        // Only 1 record present for that Group
                                        finalGroupedUsages.add(ar);
                                    }
                                    checkDup = new set<string>();
                                    tempOrderList = new List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                                    tempOrderListFinal = new List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>();
                                }else{//Grouping number not matches
                                    //Already present the key// More number of records in the grouping
                                    //Start Order/Sort for Schedule Category for all the records for that group
                                    if(checkDup.contains(ar.schedulecategory)){
                                        for(integer i=0; i< tempOrderList.size() ; i++){
                                            if(tempOrderList[i].schedulecategory == ar.schedulecategory){
                                                tempOrderListFinal.add(i,ar);
                                                break;
                                            }
                                        }
                                        tempOrderList.clear();
                                        tempOrderList.addAll(tempOrderListFinal);
                                        //First time the record came to the group
                                    }else{
                                        checkDup.add(ar.schedulecategory);
                                        tempOrderList.add(ar);
                                        tempOrderListFinal.add(ar);
                                    }
                                }
                            }
                        }
                    }
                }   
                //For all non-NordicsBillingcountries
                else{
                    set<string> ProductNames = new set<string>();
                    String Language = creditNotes[0].blng__Account__r.QTB_Language__c;
                    System.debug('Language@@'+Language);
                    System.debug('creditLines@@'+creditLines);
                    for(AggregateResult ar : creditLines)
                    {
                        System.debug('insideif@@'+Language);
                        ProductNames.add(String.valueOf(ar.get('ProdName')));
                    }
                    //Get translations of the product names in the account language
                    List<SBQQ__Localization__c> localization;
                    map<string,string> mapLocalization = new map<string,string>();
                    if(!ProductNames.isEmpty())
                    {
                        localization = [SELECT id,SBQQ__Text__c,SBQQ__Product__r.Name,SBQQ__APIName__c,SBQQ__Language__c 
                                        FROM SBQQ__Localization__c 
                                        WHERE SBQQ__Product__r.Name IN:ProductNames and SBQQ__Language__c =:Language and SBQQ__APIName__c = 'Name'];  
                        
                        for(SBQQ__Localization__c loc:localization)
                        {
                            maplocalization.put(loc.SBQQ__Product__r.Name,loc.SBQQ__Text__c);
                        }
                    }
                    
                    //Credit Note Line items mapping
                    integer row = 1;
                    for(AggregateResult ar : creditLines)
                    {
                        system.debug('ar=='+ar);
                        if(!InvoiceNumbers.contains(String.valueOf(ar.get('InvNum'))))
                            InvoiceNumbers.add(String.valueOf(ar.get('InvNum')));  
                        
                        QTB_Generate_Creditnote_Ctrl.LineItems li = new QTB_Generate_Creditnote_Ctrl.LineItems();   
                        li.RowNum=String.valueOf(row);
                        
                        if(ar.get('qty') != '' && ar.get('qty') != null){
                            Decimal Qty = double.valueof(ar.get('qty'))*-1;
                            li.crLIQty = String.valueOf(Qty);
                        }
                        if(ar.get('subTotal') != '' && ar.get('subTotal') != null){
                            Decimal subTotal = double.valueof(ar.get('subTotal'));
                            subTotal = subTotal*-1;
                            li.crLISubTotal = String.valueOf(subTotal.setScale(2, RoundingMode.HALF_UP));
                        }
                        
                        //#15993 On Account Nordics value population
                        if(nordicBillingCountriesPresent !=null && nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == TRUE){
                            if(ar.get('scheduleCategory') != '' && ar.get('scheduleCategory') != null ){
                                li.ProdScheduleCateg = String.valueOf(ar.get('scheduleCategory'));
                            }
                            //#15993 On Account Nordics value population
                            if(ar.get('CusInvDisplay') != '' && ar.get('CusInvDisplay') != null){
                                li.ProdName = String.valueOf(ar.get('CusInvDisplay'));
                            }
                            if(ar.get('qty') != 0 && ar.get('qty') != null){
                                /*Gitlab 28417 The formula field 'blng__CreditNoteLine__c.QTB_Unit_Price__c' gives incorrect values in aggregate queries due to grouping. 
									To fix this, we calculate UnitPrice as Subtotal/Quantity after grouping*/
                                Decimal unitPrice = double.valueOf(decimal.valueOf(li.crLISubTotal)/decimal.valueOf(li.crLIQty));
                                li.crLIUnitPrice = String.valueOf(unitPrice.setScale(3, RoundingMode.HALF_UP)); 
                            }
                            li.POGR = creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c != null? creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c : '';
                        }
                        else{
                            if(ar.get('scheduleCategory') != '' && ar.get('scheduleCategory') != null && prScCategoryTranslation.containsKey(String.valueOf(ar.get('scheduleCategory'))) && !nordicBillingCountriesPresent){
                                li.ProdScheduleCateg = prScCategoryTranslation.get(String.valueOf(ar.get('scheduleCategory')));
                            }
                            
                            if(ar.get('ProdName') != '' && ar.get('ProdName') != null && nordicBillingCountriesPresent!=null && !nordicBillingCountriesPresent){
                                string ProdName = String.valueOf(ar.get('ProdName'));
                                if(maplocalization.containsKey(ProdName))
                                {
                                    li.ProdName = maplocalization.get(ProdName);
                                }
                                else
                                {
                                    li.ProdName = ProdName;                    
                                }
                            }
                            if(ar.get('unitPrice') != '' && ar.get('unitPrice') != null){
                                Decimal unitPrice = double.valueOf(ar.get('unitPrice'));
                                li.crLIUnitPrice = String.valueOf(unitPrice.setScale(3, RoundingMode.HALF_UP));
                            }
                        }  
                        CrLineItems.add(li);
                        row++;
                    }  
                }
                
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApixCreditNoteExtractBatch_execute');  
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            Map<string, integer> L1L2L3GrpCompareMap1 = new Map<string, integer>();
            Map<string, Decimal> L1L2L3GrpSubTotalMap = new Map<string, Decimal>();
            //w.header6 = '20';
            //Gitlab US#25656
            Map<String,List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>> finalGroupedUsagesMap = new Map<String,List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls>>();
            for(QTB_Generate_Creditnote_Ctrl.GroupWrapperCls ar : finalGroupedUsages){
                String grpKeyString = '';
                
                if(ar.lev1code != null){
                    grpKeyString += ar.lev1code;
                }
                if(ar.divisionCode != null){
                    grpKeyString += ar.divisionCode;                            
                }
                if (ar.departmentCode != null){
                    grpKeyString += ar.departmentCode;                            
                }
                if(grpKeyString != ''){
                    if(!finalGroupedUsagesMap.containsKey(grpKeyString)) {
                        finalGroupedUsagesMap.put(grpKeyString, new List<QTB_Generate_Creditnote_Ctrl.GroupWrapperCls> { ar });
                    }
                    else{
                        finalGroupedUsagesMap.get(grpKeyString).add(ar);
                    }
                }
            }
            //Gitlab US#25656
            for(String key : finalGroupedUsagesMap.keySet()){
                System.debug('key@@'+key);
                for(QTB_Generate_Creditnote_Ctrl.GroupWrapperCls ar :finalGroupedUsagesMap.get(key)){
                    System.debug('ar@@'+ar);
                    QTB_Generate_Creditnote_Ctrl.usagewrapper w = new QTB_Generate_Creditnote_Ctrl.usagewrapper();
                    w.inv_linenum = invnum++;
                    w.usageproduct = ar.CusInvDisplay;
                    if(prdQty.containskey(ar.USrecordId) && prdQty.keySet().size() > 0){
                        System.debug('String.valueOf(prdQty.get(ar.USrecordId).QTB_Credit_Quantity__c='+ String.valueOf(prdQty.get(ar.USrecordId).QTB_Credit_Quantity__c));
                        w.lineqty=String.valueOf(prdQty.get(ar.USrecordId).QTB_Credit_Quantity__c.SetScale(2, RoundingMode.HALF_UP)*(-1));
                        System.debug('String.valueOf(prdQty.get(ar.USrecordId).QTB_Credit_Quantity__c='+ String.valueOf(prdQty.get(ar.USrecordId).QTB_Credit_Quantity__c));
                        System.debug(' w.lineqty ='+  w.lineqty);
                    }
                    //Addition of POGR
                    w.POGR =  creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c != null? creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c : '';
                    if(creditNotes[0].blng__Status__c == 'Posted'){
                        Decimal usageratedamount = double.valueof(ar.ratedAmount);
                        //w.invlineamount = String.valueOf(usageratedamount.SetScale(2, RoundingMode.HALF_UP)*(-1)); // # 2300
                        w.invlineamount =String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c.SetScale(2, RoundingMode.HALF_UP)*(-1));
                        System.debug('String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c='+ String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c));
                        System.debug(' w.lineqty ='+  w.lineqty);
                        System.debug(' w.invlineamount ='+  w.invlineamount);
                    }else if(creditNotes[0].blng__Status__c == 'Draft' && ar.prerateamount != 0.0 ){
                        Decimal usagepreamount = double.valueof(ar.prerateamount);
                        //w.invlineamount = String.valueOf(usagepreamount.SetScale(2, RoundingMode.HALF_UP)*(-1)); // # 2300
                        w.invlineamount =String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c.SetScale(2, RoundingMode.HALF_UP)*(-1));
                        System.debug('String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c='+ String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c));
                        System.debug(' w.lineqty ='+  w.lineqty);
                        System.debug(' w.invlineamount ='+  w.invlineamount);
                    }else{
                        if(String.valueOf(ar.usQuantity) != null && String.valueOf(ar.usSumUnitprice) != null){
                            // # 2300
                            // w.invlineamount = String.valueOf(Decimal.valueof(double.valueOf(ar.usQuantity)*double.valueOf(ar.usSumUnitprice)).SetScale(2, RoundingMode.HALF_UP)*(-1));
                            w.invlineamount =String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c.SetScale(2, RoundingMode.HALF_UP)*(-1)); 
                            System.debug('String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c='+ String.valueOf(prdQty.get(ar.USrecordId).blng__Subtotal__c));
                            System.debug(' w.lineqty ='+  w.lineqty);
                            System.debug(' w.invlineamount ='+  w.invlineamount);
                        }
                    }
                    //For both Draft and Posted
                    //For both Draft and Posted
                    Decimal usageunitprice =0;
                    if(ar.prerateamount > 0){
                        if(w.lineqty != null && decimal.valueOf(w.lineqty) != 0){
                            System.debug('Decimal.valueOf(w.invlineamount) ='+ Decimal.valueOf(w.invlineamount));
                            System.debug(' w.lineqty ='+  w.lineqty);
                            usageunitprice = double.valueof(decimal.valueOf(w.invlineamount)/decimal.valueOf(w.lineqty));
                            //w.unitamt = String.valueOf(usageunitprice.SetScale(4, RoundingMode.HALF_UP)); // # 2300
                            w.unitamt = ar.ratedunitPrice != null ? String.valueOf(ar.ratedunitPrice.SetScale(4, RoundingMode.HALF_UP)) : String.valueOf(ar.ratedunitPrice);//Gitlab US#24844 - exception fix
                            System.debug('  w.unitamt  ='+   w.unitamt );
                            System.debug('  usageunitprice  ='+   usageunitprice);
                        }
                    }else{
                        //w.unitamt = String.valueOf(ar.preratedUnitPrice.SetScale(4, RoundingMode.HALF_UP)); // # 2300
                        w.unitamt = ar.preratedUnitPrice !=null ? String.valueOf(ar.preratedUnitPrice.SetScale(4, RoundingMode.HALF_UP)) : String.valueOf(ar.preratedUnitPrice);//Gitlab US#24844 - exception fix
                        System.debug('  w.unitamt  ='+   w.unitamt );
                        System.debug('  ar.preratedUnitPrice  ='+   ar.preratedUnitPrice);
                    }
                    if(ar.scheduleCategory!= null){
                        w.usg_category = ar.scheduleCategory;  
                    }
                    //Check the records for grouping and adding line 40th Line at the proper place
                    QTB_Generate_Creditnote_Ctrl.usageSubtotalWrapper usWrapSub = new QTB_Generate_Creditnote_Ctrl.usageSubtotalWrapper();
                    //New Grouping logic based on Level1/ level2/ level3/ workorder id
                    String grpKeyString = '';
                    
                    if(ar.lev1code != null){
                        grpKeyString += ar.lev1code;
                    }
                    if(ar.divisionCode != null){
                        grpKeyString += ar.divisionCode;                            
                    }
                    if (ar.departmentCode != null){
                        grpKeyString += ar.departmentCode;                            
                    }
                    if(grpKeyString != ''){
                        if(L1L2L3GrpCompareMap1.containsKey(grpKeyString)){
                            System.debug('L1L2L3GrpCompareMap1@@ contains');
                            L1L2L3GrpCompareMap1.put(grpKeyString,L1L2L3GrpCompareMap1.get(grpKeyString)+1);
                        }else{
                            System.debug('L1L2L3GrpCompareMap1@@ not contains');
                            L1L2L3GrpCompareMap1.put(grpKeyString,1);
                        }
                    }
                    //Check if the number of records for grouping is same or not?
                    //Grouping number matches, then add Line No 40(Subtotal)
                    System.debug('L1L2L3L4GrpMap@@'+L1L2L3L4GrpMap);
                    System.debug('L1L2L3GrpCompareMap1@@'+L1L2L3GrpCompareMap1);
                    if(L1L2L3L4GrpMap.containsKey(grpKeyString)){
                        if(L1L2L3L4GrpMap.get(grpKeyString) == L1L2L3GrpCompareMap1.get(grpKeyString)){
                            System.debug('if@@');
                            //Multiple records are there in the group
                            if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                                System.debug( 'L1L2L3GrpSubTotalMap.containskey(grpKeyString)');
                                System.debug(' L1L2L3GrpSubTotalMap.get(grpKeyString)= ' +L1L2L3GrpSubTotalMap.get(grpKeyString));
                                System.debug(' decimal.valueOf(w.invlineamount) = ' + decimal.valueOf(w.invlineamount));
                                // MGSB
                                usWrapSub.subtotal40thLine = (L1L2L3GrpSubTotalMap.get(grpKeyString)  + decimal.valueOf(w.invlineamount)*(-1)).SetScale(2, RoundingMode.HALF_UP);
                                w.usageSubtotal = usWrapSub;
                                System.debug('usWrapSub.subtotal40thLine  = '+usWrapSub.subtotal40thLine );
                                System.debug('w.invlineamount = '+w.invlineamount);
                                System.debug('w.usageSubtotal @@ = '+w.usageSubtotal);
                            }
                            else{
                                //Match in first time(only one occurance)
                                System.debug( 'L1L2L3GrpSubTotalMap does not containskey(grpKeyString)');
                                System.debug(' decimal.valueOf(w.invlineamount) = '+decimal.valueOf(w.invlineamount));
                                usWrapSub.subtotal40thLine = decimal.valueOf(w.invlineamount).SetScale(2, RoundingMode.HALF_UP)*(-1);
                                w.usageSubtotal = usWrapSub;
                                //Just keep the map in the sync // Not required to add the amount
                                L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueOf(w.invlineamount));
                                System.debug('usWrapSub.subtotal40thLine  = '+usWrapSub.subtotal40thLine );
                                System.debug('w.invlineamount = '+w.invlineamount);
                                System.debug('w.usageSubtotal @@ = '+w.usageSubtotal);  
                            }
                        }
                        else{
                            System.debug('else@@ Grouping number not matches');
                            //Grouping number not matches
                            //Already present the key// More number of records in the grouping
                            if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                                System.debug('L1L2L3GrpSubTotalMap.containskey(grpKeyString)');
                                L1L2L3GrpSubTotalMap.put(grpKeyString,L1L2L3GrpSubTotalMap.get(grpKeyString) + decimal.valueOf(w.invlineamount));
                            }else{
                                System.debug('L1L2L3GrpSubTotalMap.doesnot containskey(grpKeyString)');
                                //First time key
                                L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueOf(w.invlineamount));
                            }
                            System.debug('<<AfterL1L2L3GrpSubTotalMap>> '+L1L2L3GrpSubTotalMap.size()+'<<usWrapSub.subtotal40thLine>> '+usWrapSub.subtotal40thLine);
                        }
                    }
                    lstusagewrapper.add(w);
                    System.debug('lstusagewrapper = '+ lstusagewrapper);
                }
            }
            
            
            Header = new QTB_Generate_Creditnote_Ctrl.HeaderLines(creditNotes[0],ContactEmail,InvoiceNumbers,ISOCode,accountLanguage.get(Language));
            String jsonHeaderData = JSON.serialize(Header);
            String jsonCreditNoteLineData = JSON.serialize(CrLineItems);
            String jsonUsageWrapperData = JSON.serialize(lstusagewrapper);
            splitAndSetUsageData(jsonHeaderData,jsonCreditNoteLineData,jsonUsageWrapperData,creditNotes[0]);
            
            //Call queueable class to create the Text file
            System.enqueueJob(new QTB_GenerateApixExtractQueueable(creditNotes,false));
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApixCreditNoteExtractBatch_finish');  
        }
    }
    // Helper method to split JSON data into multiple fields
    public static void splitAndSetUsageData(String jsonHeaderData, string jsonCreditNoteLineData, String data, blng__CreditNote__c creditVar) {
        Integer maxTextAreaLength = 131072; // Long Text area field max length is 131,072
        List<String> fieldNames = new List<String>();
        fieldNames.add('QTB_StoreApixUsageExtract1__c');
        fieldNames.add('QTB_StoreApixUsageExtract2__c');
        fieldNames.add('QTB_StoreApixUsageExtract3__c');
        fieldNames.add('QTB_StoreApixUsageExtract4__c');
        fieldNames.add('QTB_StoreApixUsageExtract5__c');
        fieldNames.add('QTB_StoreApixUsageExtract6__c');
        
        blng__CreditNote__c crdNote = new blng__CreditNote__c();
        crdNote.Id = creditVar.Id;
        crdNote.QTB_StoreApixHeaderExtract__c = jsonHeaderData;
        crdNote.QTB_StoreApixCreditNoteLineExtract__c = jsonCreditNoteLineData;
        
        for(Integer i = 0; i < fieldNames.size() && data.length() > 0; i++) 
        {
            if (data.length() > maxTextAreaLength) {
                crdNote.put(fieldNames[i], data.substring(0, maxTextAreaLength));
                data = data.substring(maxTextAreaLength);
            } else {
                crdNote.put(fieldNames[i], data);
                data = '';
            }
        }
        update crdNote;
        System.debug('finish_crdNote@@'+crdNote); 
    }
}