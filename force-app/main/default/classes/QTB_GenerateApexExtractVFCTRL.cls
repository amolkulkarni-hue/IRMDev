/*****************************************************************************************************
* Class: QTB_GenerateApexExtractVFCTRL
 * Test Class : QTB_GenerateApexExtractVFCTRL_Test
* Author: IRM
* Purpose: This class containing logic for generating txt file for invoice
* Developer     Date          Description
* ------------------------------------------------------------------------------------------- 
*  Sriram        7/21/2020      Created initial class
*  Gopi/Sriram   10/19/2020     Version 1: Logic change for Usage Grouping and Adding Invoice Line to the report
*  Gopi/Pragathi 16/02/2023     Version 2: Logic change for Nordics grouping lines and calculation 
 *  Thrinethra    22/11/2024		#27433 added logic to populate PO number from invoice level to apix presentment
 *  Thrinethra    13/12/2024     #27216 & #28005 added logic to add usage level Departmentcode presentment level customer number
*******************************************************************************************************/
public without sharing class QTB_GenerateApexExtractVFCTRL {
    
    public List<wrapper> lstwrapper {get; set;}
    public List<usagewrapper> lstusagewrapper {get; set;}
    public static List<blng__Invoice__c> invLst;
    public Boolean nordicBillingCountriesPresent =false;
    //Billing Status for Draft and Posted Invoices - Story #742
    public static final String INVOICE_DRAFT_BILLING_STATUS = 'PRI';
    public static final String INVOICE_POSTED_BILLING_STATUS = 'INV';
    
    //Call Construtor 
    public QTB_GenerateApexExtractVFCTRL(){
        try{
            string InvoiceID = ApexPages.currentPage()?.getParameters().get('Id'); //Get parameter(Invoice Id) from the VF Page
            string isUsageWithinLimit = ApexPages.currentPage()?.getParameters().get('isUsageWithinLimit');//Gitlab US#24329
            //Gitlab US#24329 -- basedd on isUsageWithinLimit param value, either using the existing code or using the new logic
            //Gitlab US#24329 -- removed comments & system.debug logs
            If(String.isNotBlank(InvoiceID) && isUsageWithinLimit == 'true'){
                System.debug('QTB_GenerateApexExtractVFCTRL_if@@');
                lstwrapper = new List<wrapper>();
                lstusagewrapper = new List<usagewrapper>();
                //Get Nordea Accounts from Custom Label // Use ';'(Semicoulmn) for more number of Accounts
                List<string> nordeaAccounts;
                if(Label.QTB_Nordea_Account_for_APIX_Extract != null){
                    nordeaAccounts = Label.QTB_Nordea_Account_for_APIX_Extract.split(';');
                }
                //Query for invoice data
				//#21361 Addition of override fields in the Query
                invLst = [Select id,Name, QTB_PurchaseOrder__c, QTB_Purchase_Order__c, QTB_Account_Sitad__c, QTB_PurchaseOrder__r.QTB_Customer_PO__c, QTB_Custom_Invoice_Number__c,blng__InvoiceStatus__c,blng__Subtotal__c,QTB_KID__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Language__c,blng__InvoiceDate__c,blng__TotalAmount__c,QTB_Total_Amount_with_Tax_Override__c,CurrencyIsoCode,blng__Account__r.id,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Notes__c,blng__Account__r.QTB_EDI_Identifier__c,
                          blng__Account__r.QTB_Invoice_Notes__c,blng__Account__r.BillingCountry,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.QTB_Customer_Number__c,blng__Order__r.SBQQ__PaymentTerm__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                          blng__DueDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,
                          blng__Account__r.Parent.Name,blng__Account__c,blng__Account__r.QTB_Display_Custom_Product_Names__c //Fetching billing account for Story #1317 changes
                          FROM blng__Invoice__c WHERE Id =:InvoiceID  ];	//#27433 added QTB_Purchase_Order__c, QTB_Account_Sitad__c as part of story
                boolean isNordeaAcc = false;
                if(invLst[0].blng__Account__r.Parent.Name != null && nordeaAccounts != null){
                    isNordeaAcc = nordeaAccounts.contains(invLst[0].blng__Account__r.Parent.Name);
                }
                //-------Start of logic to check Nordic country Git #13418-----/
                List<String> nordicCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
                for(String country:nordicCountries)
                {
                    if(invLst[0].blng__Account__r.QTB_Legal_Entity_Country__c == country){
                        nordicBillingCountriesPresent = true;
                        break;
                    }
                }
                //-------End of logic to check Nordic country Git #13418-----/
                
                //Create Map for Account language
                Map<String, String> accLanguage = new Map<String, String>();
                accLanguage.put('no', 'NOR');
                accLanguage.put('fi', 'FIN');
                accLanguage.put('da', 'DAN');
                accLanguage.put('sv', 'SVE');
                accLanguage.put('en_US', 'ENG');
                accLanguage.put('th', 'Thai');
                accLanguage.put('zh_TW', 'Chinese Traditional');
                accLanguage.put('en_GB', 'English(UK)');
                
                //Query for Active 'PurchaseOrder' related to invoice billing account
               List<QTB_PurchaseOrder__c> purchaseOrderLst = new List<QTB_PurchaseOrder__c>();
                set<String> purchaseOrderLists = new set<String>();    
                List<String> purchaseOrderList = new List<String>();    
                purchaseOrderLst= [select Name,QTB_Status__c,QTB_Division__c,QTB_Customer_PO__c,QTB_Div_Dept_Level__c,QTB_Customer_Id__c,
                                         (SELECT Id, Name, QTB_Account__c, QTB_Purchase_Order__c FROM PurchaseOrderAccounts__r)  
                                    from QTB_PurchaseOrder__c 
                                    where Id IN (SELECT QTB_Purchase_Order__c FROM QTB_PurchaseOrderAccount__c WHERE QTB_Account__c =:invLst[0].blng__Account__c)
                                    And QTB_Status__c= 'Active'];// Gitlab #31452   
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
                //Query for IM Country related to invoice billing account related legal entity
                List<IM_Country__c> country = new List<IM_Country__c>();
                if(invLst[0].blng__Account__r.QTB_Contract_Entity__r.blng__Country__c !=null){
                    //Git #12822 - Addition of Active chckbox in the query
                    country = [select id,Name,Iso31662Code__c from IM_Country__c where Name=:invLst[0].blng__Account__r.QTB_Contract_Entity__r.blng__Country__c and Active__c = true limit 1];
                }
                
                //Query for Primary 'AccountContactRelation' related to invoice billing account Where the Role is 'Billing'
                List<AccountContactRelation> billingCont = new List<AccountContactRelation>();
                billingCont= [select ContactId,QTB_Primary__c,Roles from AccountContactRelation where QTB_Primary__c = true and AccountId=:invLst[0].blng__Account__c and Roles = 'Billing'];
                String ContactEmail;
                if(billingCont != null && billingCont.size()>0 && billingCont[0].ContactId != null){              
                    Contact BillingContact = [select name,email,Phone from contact where id=:billingCont[0].ContactId];
                    ContactEmail = BillingContact.email;
                }
                
                //Query for invoiceLineItems related to invoice
                //#16008 Nordics print_to_date update to Invlin.Enddate
                List<blng__InvoiceLine__c> invoiceLineItems = new List<blng__InvoiceLine__c>();
                invoiceLineItems = [select id,blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,blng__OrderProduct__r.Product2.Name,blng__OrderProduct__r.Product2.ProductCode,blng__UsageSummary__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c,blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c,blng__StartDate__c,blng__OrderProduct__r.Product2.Id,blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c,blng__EndDate__c from blng__InvoiceLine__c where blng__Invoice__c =:InvoiceID order by blng__Product__r.Name ];
                set<string> usageSummaries = new set<string>();
                List<blng__InvoiceLine__c> recurringInvoiceLine = new List<blng__InvoiceLine__c>();
                string PaymentTerm = '';
                date invoiceLineStartdate;
                date invoiceLineEnddate;//#16008 Nordics print_to_date update to Invlin.Enddate
                if(invoiceLineItems.size()>0 && invoiceLineItems != null) {   
                    for(blng__InvoiceLine__c invLin:invoiceLineItems){
                        if(invLin.blng__UsageSummary__c != null){//Gitlab US#24329
                        usageSummaries.add(invLin.blng__UsageSummary__c);
                        }
                        //Adding all Recurring InvoiceLine 
                        //As per New Architecture, Recurring Lines are decided by 'QTB_HasConsumptionSchedule__c'
                        //As per Story #6478 & #6509, Recurring Lines are decided by 'QTB_Charge_Type__c'
                        if(invLin.QTB_Charge_Type__c == 'Recurring'){
                            recurringInvoiceLine.add(invLin);
                        }
                        if(PaymentTerm == '' && invLin.blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c != null){
                            PaymentTerm = invLin.blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c;
                        }
                        if(invoiceLineStartdate == null && invLin.blng__StartDate__c != null){
                            invoiceLineStartdate = invLin.blng__StartDate__c;
                        }
                        //#16008 Nordics print_to_date update to Invlin.Enddate
                        if(invoiceLineEnddate == null && invLin.blng__EndDate__c != null){
                            invoiceLineEnddate = invLin.blng__EndDate__c;
                        }
                    }
                    //Remove blanks and nulls
                    usageSummaries.remove('');
                    usageSummaries.remove(null);
                }
                
                //Query for Usages related to invoice's usageSummaries with a proper Order 'QTB_Department_Code__c','QTB_Division_Code__c','QTB_Price_Schedule_Category__c' & 'product2.Name'
                //#13521
                List<blng__Usage__c> usages = new List<blng__Usage__c>();
                if(!usageSummaries.isEmpty()){
                    if(nordicBillingCountriesPresent){
                        usages = [Select blng__OrderProduct__r.Product2.Name ,blng__OrderProduct__r.product2.ProductCode,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Division_Code__c ,QTB_Department_Code__c ,QTB_Rated_Amount__c ,blng__UsageSummary__r.blng__UnitPrice__c,blng__UnitPrice__c,blng__UsageSummary__r.blng__SummaryStartDate__c,blng__Subtotal__c,blng__Account__c,blng__OrderProduct__c,
                                  QTB_Department_Name__c,QTB_Custom_Invoice_Display__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,blng__Account__r.QTB_Language__c ,QTB_Level_1_Name__c ,QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Rated_Unit_Price__c ,QTB_Invoice_Quantity__c,blng__PreratedQuantity__c,blng__PreratedAmount__c, blng__Quantity__c,QTB_Term__c,QTB_Work_Order_ID__c,QTB_Requestor__c,blng__OrderProduct__r.Product2.Id,QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c,QTB_Product_Identifier_1__c,QTB_Price_Tier__c, blng__Account__r.QTB_SITAD__c, blng__Account__r.name
                                  from blng__Usage__c 
                                  where blng__UsageSummary__c in :usageSummaries 
                                  order by QTB_Level_1_Code__c NULLS LAST, 
                                      QTB_Division_Code__c NULLS LAST,
                                      QTB_Department_Code__c NULLS LAST, 
                                      blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,
                                      QTB_Work_Order_ID__c NULLS LAST,
                                      blng__OrderProduct__r.product2.Name NULLS LAST]; //#27216 & #28005 QTB_SITAD__c
                    }else{
                        usages = [Select blng__OrderProduct__r.Product2.Name ,blng__OrderProduct__r.product2.ProductCode,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Division_Code__c ,QTB_Department_Code__c ,QTB_Rated_Amount__c ,blng__UsageSummary__r.blng__UnitPrice__c,blng__UnitPrice__c,blng__UsageSummary__r.blng__SummaryStartDate__c,blng__Subtotal__c,blng__Account__c,blng__OrderProduct__c,
                                  QTB_Department_Name__c,QTB_Custom_Invoice_Display__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,blng__Account__r.QTB_Language__c ,QTB_Product_Identifier_1__c,QTB_Price_Tier__c,QTB_Level_1_Name__c ,QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Rated_Unit_Price__c ,QTB_Invoice_Quantity__c,blng__PreratedQuantity__c,blng__PreratedAmount__c, blng__Quantity__c,QTB_Term__c,QTB_Work_Order_ID__c,QTB_Requestor__c,blng__OrderProduct__r.Product2.Id,QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c, blng__Account__r.QTB_SITAD__c,blng__Account__r.name from blng__Usage__c where blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c NULLS LAST, QTB_Division_Code__c NULLS LAST,QTB_Department_Code__c NULLS LAST,QTB_Work_Order_ID__c NULLS LAST, blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,blng__OrderProduct__r.product2.Name NULLS LAST];//#27216 & #28005 QTB_SITAD__c
                    }
                    
                }
                Map<string,GroupWrapperCls> groupWrapperMap = new Map<string,GroupWrapperCls>();
                List<Map<string,GroupWrapperCls>> usagesWrapperList = new List<Map<string,GroupWrapperCls>>();
                //Duplicate check based on certain field values(QTB_Department_Code__c, QTB_Division_Code__c, QTB_Price_Schedule_Category__c, product2.Name, QTB_Rated_Unit_Price__c(Posted),blng__UsageSummary__r.blng__UnitPrice__c(Draft), QTB_Work_Order_ID__c(If Nordea),QTB_Start_Date_MRC__c(if QTB_Price_Schedule_Category__c='Storage'), QTB_End_Date_MRC__c(if QTB_Price_Schedule_Category__c='Storage'))
                for(blng__Usage__c usg : usages){
                    string keyString = '';
                    //Gopi Temp add
                    if(usg.QTB_Level_1_Code__c != null){
                        keyString = usg.QTB_Level_1_Code__c;
                    }else{
                        keyString = 'Null';
                    }
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
                    //Usage.Order Product.Product.Price Schedule Category = 'Services' OR 'Services Off-Site' OR 'Services On-Site' OR 'Other Program Fees' OR NOT(Storage,Transport,Supplies)
                    if(usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != null){
                        if(usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Storage' && usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Transportation' && usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Supplies'){
                            keyString += 'Services';
                        }else{
                            keyString += usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                        }
                    }else{
                        keyString += 'Null';
                    }
                    //#13521 Addition of QTB_Product_Identifier_1__c to grouping for NordicBilling countries
                    if(nordicBillingCountriesPresent){
                        if(usg.QTB_Product_Identifier_1__c != null){
                            keyString += usg.QTB_Product_Identifier_1__c;
                        }else{
                            keyString += 'Null';
                        }
						//#20247 Addition of Price tier for grouping
						if(usg.QTB_Price_Tier__c != null){
                            keyString += usg.QTB_Price_Tier__c;
                        }else{
                            keyString += 'Null';
                        }
                    }
                    
                    if(usg.blng__OrderProduct__r.product2.Name != null){
                        keyString += usg.blng__OrderProduct__r.product2.Name;
                    }else{
                        keyString += 'Null';
                    }
                    if(usg.QTB_Rated_Unit_Price__c != null && invLst[0].blng__InvoiceStatus__c == 'Posted'){
                        keyString += usg.QTB_Rated_Unit_Price__c;
                    }else if(usg.blng__UsageSummary__r.blng__UnitPrice__c != null && invLst[0].blng__InvoiceStatus__c == 'Draft'){
                        keyString += usg.blng__UsageSummary__r.blng__UnitPrice__c;
                    }else{
                        keyString += 'Null';
                    }
                    //Check 'Word Order', if it's a Nordea Account
                    if(isNordeaAcc && usg.QTB_Work_Order_ID__c != null){
                        keyString += usg.QTB_Work_Order_ID__c;
                    }else{
                        keyString += 'Null';
                    }
                    //Do further Grouping only if QTB_Price_Schedule_Category__c='Storage'
                    if(usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c =='Storage'){
                        if(usg.QTB_Start_Date_MRC__c != null){
                            keyString += usg.QTB_Start_Date_MRC__c;
                        }else{
                            keyString += 'Null';
                        }
                        if(usg.QTB_End_Date_MRC__c != null){
                            keyString += usg.QTB_End_Date_MRC__c;
                        }else{
                            keyString += 'Null';
                        }
                    }
                    //Create Map based on Key and add map to the List for maintaining the 'Proper Order/ Sequence'
                    if(usagesWrapperList.size() > 0){
                        boolean addMapToList = true;
                        for(Map<string,GroupWrapperCls> wrpMap : usagesWrapperList){
                            //Already key exist
                            if(wrpMap.containskey(keyString)){
                                addMapToList = false;
                                GroupWrapperCls wrp = wrpMap.get(keyString);
                                //Over ride the map 
                                wrpMap.put(keyString,new GroupWrapperCls(usg,wrp));
                            }
                        }
                        if(addMapToList){
                            groupWrapperMap = new Map<string,GroupWrapperCls>();
                            //Create new Map, so pass null
                            groupWrapperMap.put(keyString,new GroupWrapperCls(usg,null));
                            usagesWrapperList.add(groupWrapperMap);
                        }
                    }else{
                        groupWrapperMap = new Map<string,GroupWrapperCls>();
                        //Create new Map, so pass null 
                        groupWrapperMap.put(keyString,new GroupWrapperCls(usg,null));
                        usagesWrapperList.add(groupWrapperMap);
                    }
                    System.debug('*****keyString*****'+keyString+'***prod**'+usg.blng__OrderProduct__r.product2.Name);
                }
                //Sorting Records
                List<GroupWrapperCls> Level1Fina5Grp = new List<GroupWrapperCls>();
                if(!usages.isEmpty()){
                    //Iterate all the wrapper records for Level 1 Grouping
                    List<GroupWrapperCls> Level1FinalGrp = new List<GroupWrapperCls>();
                    List<GroupWrapperCls> Level1Fina2Grp = new List<GroupWrapperCls>();
                    List<GroupWrapperCls> Level1Fina3Grp = new List<GroupWrapperCls>();
                    List<GroupWrapperCls> Level1Fina4Grp = new List<GroupWrapperCls>();
					//#20247 Addition of Price tier for grouping
					List<GroupWrapperCls> Level1FinalTierGrp = new List<GroupWrapperCls>();
                    Map<string, GroupWrapperCls[]> codeToLevel1Grp = new Map<string, GroupWrapperCls[]>();
                    List<GroupWrapperCls> tempHolder = new List<GroupWrapperCls>();
                    for(Map<string,GroupWrapperCls> wrpMap : usagesWrapperList){
                        for(GroupWrapperCls record: wrpMap.values()) {
                            if(record.lev1code != null){
                                if(codeToLevel1Grp.containsKey(record.lev1code)) {
                                    // Code already in map
                                    codeToLevel1Grp.get(record.lev1code).add(record);
                                } else {
                                    // Code is not yet in Map
                                    codeToLevel1Grp.put(record.lev1code, new List<GroupWrapperCls> { record });
                                }
                            }else{
                                tempHolder.add(record);
                            }
                        }
                    }
                    for(List<GroupWrapperCls> lev1 : codeToLevel1Grp.values()){
                        Level1FinalGrp.addAll(lev1);
                    }
                    if(tempHolder.size() > 0){
                        Level1FinalGrp.addAll(tempHolder);
                        tempHolder = new List<GroupWrapperCls>();
                    }
                    //Iterate all the wrapper records for Level 2 Grouping
                    Map<string, GroupWrapperCls[]> codeToLevel2Grp = new Map<string, GroupWrapperCls[]>();
                    string keyStr = '';
                    for(GroupWrapperCls record: Level1FinalGrp) {
                        keyStr = '';
                        if(record.lev1code != null){
                            keyStr += record.lev1code;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.divisionCode != null){
                            keyStr += record.divisionCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(codeToLevel2Grp.containsKey(keyStr)) {
                            // Code already in map
                            codeToLevel2Grp.get(keyStr).add(record);
                        } else {
                            // Code is not yet in Map
                            codeToLevel2Grp.put(keyStr, new List<GroupWrapperCls> { record });
                        }
                    }
                    for(List<GroupWrapperCls> lev2 : codeToLevel2Grp.values()){
                        Level1Fina2Grp.addAll(lev2);
                    }
                    
                    //Iterate all the wrapper records for Level 3 Grouping
                    Map<string, GroupWrapperCls[]> codeToLevel3Grp = new Map<string, GroupWrapperCls[]>();
                    for(GroupWrapperCls record: Level1Fina2Grp) {
                        keyStr = '';
                        if(record.lev1code != null){
                            keyStr += record.lev1code;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.divisionCode != null){
                            keyStr += record.divisionCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.departmentCode != null){
                            keyStr += record.departmentCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(codeToLevel3Grp.containsKey(keyStr)) {
                            // Code already in map
                            codeToLevel3Grp.get(keyStr).add(record);
                        } else {
                            // Code is not yet in Map
                            codeToLevel3Grp.put(keyStr, new List<GroupWrapperCls> { record });
                        }
                    }
                    for(List<GroupWrapperCls> lev3 : codeToLevel3Grp.values()){
                        Level1Fina3Grp.addAll(lev3);    
                    }
                    //Iterate all the wrapper records for Level 4 Grouping
                    Map<string, GroupWrapperCls[]> codeToLevel4Grp = new Map<string, GroupWrapperCls[]>();
                    for(GroupWrapperCls record: Level1Fina3Grp) {
                        keyStr = '';
                        if(record.lev1code != null){
                            keyStr += record.lev1code;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.divisionCode != null){
                            keyStr += record.divisionCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.departmentCode != null){
                            keyStr += record.departmentCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.productIdentifier != null){
                            keyStr += record.productIdentifier;
                        }else{
                            keyStr += 'Null';
                        }
                        if(codeToLevel4Grp.containsKey(keyStr)) {
                            // Code already in map
                            codeToLevel4Grp.get(keyStr).add(record);
                        } else {
                            // Code is not yet in Map
                            codeToLevel4Grp.put(keyStr, new List<GroupWrapperCls> { record });
                        }
                    }
                    for(string keys : codeToLevel4Grp.keySet()){
                        for(GroupWrapperCls lev4 : codeToLevel4Grp.get(keys)){
                            Level1Fina4Grp.add(lev4);
                        }
                    }
					//#20247 Addition of Price tier for grouping 
					//Iterate all the wrapper records for Level 4 Grouping
                    Map<string, GroupWrapperCls[]> codeToLevelTierGrp = new Map<string, GroupWrapperCls[]>();
                    for(GroupWrapperCls record: Level1Fina4Grp) {
                        keyStr = '';
                        if(record.lev1code != null){
                            keyStr += record.lev1code;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.divisionCode != null){
                            keyStr += record.divisionCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.departmentCode != null){
                            keyStr += record.departmentCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.productIdentifier != null){
                            keyStr += record.productIdentifier;
                        }else{
                            keyStr += 'Null';
                        }
						if(record.priceTier != null){
                            keyStr += record.priceTier;
                        }else{
                            keyStr += 'Null';
                        }
                        if(codeToLevelTierGrp.containsKey(keyStr)) {
                            // Code already in map
                            codeToLevelTierGrp.get(keyStr).add(record);
                        } else {
                            // Code is not yet in Map
                            codeToLevelTierGrp.put(keyStr, new List<GroupWrapperCls> { record });
                        }
                    }
                    for(string keys : codeToLevelTierGrp.keySet()){
                        for(GroupWrapperCls lev5 : codeToLevelTierGrp.get(keys)){
                            Level1FinalTierGrp.add(lev5);
                        }
                    }
                    //PriceSchedule grouping
                    //Iterate all the wrapper records for Level 4 Grouping
                    Map<string, GroupWrapperCls[]> codeToLevel5Grp = new Map<string, GroupWrapperCls[]>();
                    for(GroupWrapperCls record: Level1FinalTierGrp) {
                        keyStr = '';
                        if(record.lev1code != null){
                            keyStr += record.lev1code;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.divisionCode != null){
                            keyStr += record.divisionCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.departmentCode != null){
                            keyStr += record.departmentCode;
                        }else{
                            keyStr += 'Null';
                        }
                        if(record.productIdentifier != null){
                            keyStr += record.productIdentifier;
                        }else{
                            keyStr += 'Null';
                        }
						if(record.priceTier != null){
                            keyStr += record.priceTier;
                        }else{
                            keyStr += 'Null';
                        }
                        //If Nodia Account then group
                        if(isNordeaAcc){
                            if(record.workOrderId != null){
                                keyStr += record.workOrderId;
                            }else{
                                keyStr += 'Null';
                            }
                        }
                        if(record.scheduleCategory != null){
                            keyStr += record.scheduleCategory;
                        }else{
                            keyStr += 'Null';
                        }
                        if(codeToLevel5Grp.containsKey(keyStr)) {
                            // Code already in map
                            codeToLevel5Grp.get(keyStr).add(record);
                        } else {
                            // Code is not yet in Map
                            codeToLevel5Grp.put(keyStr, new List<GroupWrapperCls> { record });
                        }
                    }
                    for(string keys : codeToLevel5Grp.keySet()){
                        for(GroupWrapperCls lev5 : codeToLevel5Grp.get(keys)){
                            Level1Fina5Grp.add(lev5);
                        }
                    }
                }
                //Variable Declaration
                String[] usageCodes = New String[]{};
                    set<string> usageLevelCode = new set<string>();
                set<string> accProductNames = new set<string>();
                set<string> accLan = new set<string>();
                //#13521 New map to hold keystring without product identifier value
                Map<string, integer>    L1L2L3L4GrpMap = new Map<string, integer>();
                List<GroupWrapperCls> finalGroupedUsages = new List<GroupWrapperCls>();
                //3 level of grouping
                //Grouping based on certain field values(lev1code, divisionCode, departmentCode,workOrderId(Nordea))
                if(!usages.isEmpty()){
                        for(GroupWrapperCls ar : Level1Fina5Grp){
                            //Add all the wrapper records to a Final Wrapper List 
                        //#27216 & #28005 start
                            if(ar.departmentCode != null && ar.lev1code == null && ar.isSitadAccount){
                                usageLevelCode.add(String.valueOf(ar.departmentCode));
                            }else if(ar.lev1code != null){
                                usageLevelCode.add(String.valueOf(ar.lev1code));
                            }//#27216 & #28005 end
                            finalGroupedUsages.add(ar);
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
                            system.debug('isNordeaAcc+++'+isNordeaAcc);
                            if(isNordeaAcc){
                                if(ar.workOrderId != null){
                                    grpKeyString += ar.workOrderId;
                                }
                            }
                            //#13521 Addition of keystring to the new map for Subtotal calculation
                            if(grpKeyString != ''){
                                if(L1L2L3L4GrpMap.containsKey(grpKeyString)){
                                    L1L2L3L4GrpMap.put(grpKeyString,L1L2L3L4GrpMap.get(grpKeyString)+1);
                                }else{
                                    L1L2L3L4GrpMap.put(grpKeyString,1);
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
                            System.Debug('<<<<GrpKeyString>>>>'+grpKeyString);
                                }
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
                        //Temporary use of these fields(QTB_Cost_Center__c,blng__MatchingAttribute__c,blng__ErrorMessage__c,QTB_UsedforRerate__c,QTB_Service_District__c) to store Data as an instance// No DML Operation
                        //To store QTB_Price_Schedule_Category__c value
                        tempUsages.QTB_Cost_Center__c = invLine.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                        //To store Product Name value
                        tempUsages.blng__MatchingAttribute__c = invLine.blng__OrderProduct__r.Product2.Name;
                        //To store ProductCode value
                        tempUsages.blng__ErrorMessage__c = invLine.blng__OrderProduct__r.Product2.ProductCode;
                        //To store QTB_Display_Custom_Product_Names__c value
                        tempUsages.QTB_UsedforRerate__c = invLine.blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c;
                        //To store Account QTB_Language__c value
                        tempUsages.QTB_Service_District__c = invLine.blng__Invoice__r.blng__Account__r.QTB_Language__c;
                        
                        /************** Changes for Story #1317 Starts **************/  
                        GroupWrapperCls tempGroupWrapper = new GroupWrapperCls(tempUsages,null);    
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
                //query localization records for converting product name based on account lan
                list<SBQQ__Localization__c> localization = new list<SBQQ__Localization__c>();
                map<string,string> maplocalization = new map<string,string>();
                if(!accProductNames.isEmpty() && !accLan.isEmpty()){
                    localization = [select id,SBQQ__Text__c,SBQQ__Product__r.Name,SBQQ__Product__r.ProductCode,SBQQ__APIName__c,SBQQ__Language__c from SBQQ__Localization__c Where SBQQ__Product__r.ProductCode IN: accProductNames and SBQQ__Language__c IN: accLan and SBQQ__APIName__c = 'Name'];  
                    //Create a Map as key productcode + language -> Translated value of that Product Name
                    for(SBQQ__Localization__c loc:localization){
                        string locKey = loc.SBQQ__Product__r.ProductCode+' '+loc.SBQQ__Language__c;
                        maplocalization.put(locKey,loc.SBQQ__Text__c);
                    }
                }
                mappingToTxt(invLst[0],purchaseOrderList,ContactEmail,country,accLanguage,usageCodes,usageLevelCode,usages,PaymentTerm,invoiceLineStartdate,invoiceLineEnddate);
                if(!finalGroupedUsages.isEmpty()){
                    //#13521 Passing new map(L1L2L3L4GrpMap) as a parameter inorder to calculate Subtotal 
                    mappingToUsage(finalGroupedUsages,country,invLst[0],purchaseOrderLst,maplocalization,isNordeaAcc ,L1L2L3L4GrpMap);
                }
            }
            else if(String.isNotBlank(InvoiceID) && isUsageWithinLimit == 'false'){ //Gitlab US#24329
                System.debug('QTB_GenerateApexExtractVFCTRL_else_if@@');
                List<blng__Invoice__c> invList = [SELECT Id,NAME,blng__Account__r.Parent.Name, blng__Account__r.QTB_Legal_Entity_Country__c, 
                                                  QTB_StoreApixInvoiceExtract__c,QTB_StoreApixUsageExtract1__c,QTB_StoreApixUsageExtract2__c,
                                                  QTB_StoreApixUsageExtract3__c,QTB_StoreApixUsageExtract4__c,QTB_StoreApixUsageExtract5__c,QTB_StoreApixUsageExtract6__c
                                                  FROM blng__Invoice__c 
                                                  WHERE Id =: invoiceId];
                System.debug('invList@@'+invList);
                lstwrapper = new List<wrapper>();
                List<string> nordeaAccounts = new List<string>();
                if(Label.QTB_Nordea_Account_for_APIX_Extract != null){
                    nordeaAccounts = Label.QTB_Nordea_Account_for_APIX_Extract.split(';');
                }
                boolean isNordeaAcc = false;
                if(invLst != null && invLst[0].blng__Account__r.Parent != null && invLst[0].blng__Account__r.Parent.Name != null && nordeaAccounts != null){
                    isNordeaAcc = nordeaAccounts.contains(invLst[0].blng__Account__r.Parent.Name);
                }
                //-------Start of logic to check Nordic country Git #13418-----/
                List<String> nordicCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
                for(String country:nordicCountries)
                {
                    if(invLst != null && invLst[0].blng__Account__r.QTB_Legal_Entity_Country__c != null &&
                        invLst[0].blng__Account__r.QTB_Legal_Entity_Country__c == country)
                    {
                        nordicBillingCountriesPresent = true;
                        break;
                    }
                }
                //-------End of logic to check Nordic country Git #13418-----/
                
                //Create Map for Account language
                Map<String, String> accLanguage = new Map<String, String>();
                accLanguage.put('no', 'NOR');
                accLanguage.put('fi', 'FIN');
                accLanguage.put('da', 'DAN');
                accLanguage.put('sv', 'SVE');
                accLanguage.put('en_US', 'ENG');
                accLanguage.put('th', 'Thai');
                accLanguage.put('zh_TW', 'Chinese Traditional');
                accLanguage.put('en_GB', 'English(UK)');
                
                lstusagewrapper = new List<usagewrapper>();
                if(invList != null && invList[0].QTB_StoreApixInvoiceExtract__c !=null && invList[0].QTB_StoreApixUsageExtract1__c !=null){
                    lstwrapper = (List<wrapper>) JSON.deserialize(invList[0].QTB_StoreApixInvoiceExtract__c, List<wrapper>.class);
                    String usageExtract = invList[0].QTB_StoreApixUsageExtract1__c;
                    if (invList[0].QTB_StoreApixUsageExtract2__c != null) {
                        usageExtract += invList[0].QTB_StoreApixUsageExtract2__c;
                    }
                    if (invList[0].QTB_StoreApixUsageExtract3__c != null) {
                        usageExtract += invList[0].QTB_StoreApixUsageExtract3__c;
                    }
                    if (invList[0].QTB_StoreApixUsageExtract4__c != null) {
                        usageExtract += invList[0].QTB_StoreApixUsageExtract4__c;
                    }
                    if (invList[0].QTB_StoreApixUsageExtract5__c != null) {
                        usageExtract += invList[0].QTB_StoreApixUsageExtract5__c;
                    }
                    if (invList[0].QTB_StoreApixUsageExtract6__c != null) {
                        usageExtract += invList[0].QTB_StoreApixUsageExtract6__c;
                    }
                    lstusagewrapper = (List<usagewrapper>) JSON.deserialize(usageExtract, List<usagewrapper>.class);
                }
            }
            else{ //Gitlab US#24329
                System.debug('QTB_GenerateApexExtractVFCTRL_else@@');
                lstwrapper = new List<wrapper>();
                lstusagewrapper = new List<usagewrapper>();
            }
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexExtractVFCTRL');
        }
    }
    //Apex mapping for txt file realted to invoice
    //Gitlab US#24329 -- return the List<wrapper>
    public List<wrapper> mappingToTxt(blng__Invoice__c invoice,string[] poValues,String contactEmail,List<IM_Country__c> country,Map<String, String> accLanguage,String[] usageCodes,set<string> usageLevelCode,List<blng__Usage__c> usages1,string PaymentTerm,date invoiceLineStartdate,date invoiceLineEnddate){
        try{
            wrapper w = new wrapper();
            //Invoice Header Row1 Mapping
            //w.header1 = '00';
            if(country != null && country.size() > 0){
                w.invoice_layout = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout2 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu2 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout3 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu3 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout4 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu4 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout5 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu5 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout7 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu7 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout8 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu8 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout9 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                w.invoice_layout_bu9 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
            }
            if(accLanguage.containsKey(invoice.blng__Account__r.QTB_Language__c) && accLanguage.get(invoice.blng__Account__r.QTB_Language__c)!= null)
                w.rpt_language_cd = accLanguage.get(invoice.blng__Account__r.QTB_Language__c);
            if(poValues != null && poValues.size()>0){
                w.PO_ID = string.join(poValues,',');
            }else if(invoice.QTB_Purchase_Order__c != null && invoice.QTB_Account_Sitad__c){ //#27433
                w.PO_ID = invoice.QTB_Purchase_Order__c;
            }
            
            if(invoice.blng__InvoiceStatus__c == 'Posted' || Test.isRunningTest() ){
                w.invoice_num = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                w.invoice_num2 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                w.report_file = 'IRM_InvRep_'+invoice.QTB_Custom_Invoice_Number__c+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv';
                w.invoice_num3 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                w.invoice_num4 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                w.invoice_num5 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                w.invoice_num7 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                w.invoice_num8 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                w.invoice_num9 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
            }
            else{
                w.invoice_num = 'TEMP-'+invoice.Name;
                w.invoice_num2 = 'TEMP-'+invoice.Name;
                w.invoice_num3 = 'TEMP-'+invoice.Name;
                w.invoice_num4 = 'TEMP-'+invoice.Name;
                w.invoice_num5 = 'TEMP-'+invoice.Name;
                w.invoice_num7 = 'TEMP-'+invoice.Name;
                w.invoice_num8 = 'TEMP-'+invoice.Name;
                w.invoice_num9 = 'TEMP-'+invoice.Name;       
            }
            w.print_invoice_date = invoice.blng__InvoiceDate__c != null? DateTime.newInstance(invoice.blng__InvoiceDate__c.year(),invoice.blng__InvoiceDate__c.month(),invoice.blng__InvoiceDate__c.day()).format('dd/MM/yyyy') : '';     //Story 3947 End date issue
            w.bill_cust_id = invoice.blng__Account__r.QTB_Customer_Number__c != null? invoice.blng__Account__r.QTB_Customer_Number__c : '';
            w.pay_terms_descrshort = PaymentTerm != null? PaymentTerm : '';
            
            w.print_due_date = invoice.blng__DueDate__c != null? DateTime.newInstance(invoice.blng__DueDate__c.year(),invoice.blng__DueDate__c.month(),invoice.blng__DueDate__c.day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
            //Changes for differentiate between 'Draft' and 'Posted' Invoice - Story #742
            w.invoice_status = QTB_GenerateApexExtractVFCTRL.INVOICE_POSTED_BILLING_STATUS;
            if (invoice.blng__InvoiceStatus__c != null && String.ValueOf(invoice.blng__InvoiceStatus__c) == QTB_Constants.INVOICE_STATUS_DRAFT) {
                w.invoice_status = QTB_GenerateApexExtractVFCTRL.INVOICE_DRAFT_BILLING_STATUS;
            }
            
            //Invoice Header Row2 Mapping
            //w.header2 = '01';
            w.print_gst = invoice.blng__Account__r.QTB_Tax_ID__c != null? invoice.blng__Account__r.QTB_Tax_ID__c : '';
            w.Cust_addr_ln1 = invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null? invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c : '';
           //w.invPONumber =   invoice.QTB_PurchaseOrder__r.QTB_Customer_PO__c != null? invoice.QTB_PurchaseOrder__r.QTB_Customer_PO__c : '';  //22030
            //Commenting as part of #25327 GITLAB
            /*w.invPONumber ='';
            if(invoice.QTB_PurchaseOrder__r.QTB_Customer_PO__c != null){
                w.invPONumber = invoice.QTB_PurchaseOrder__r.QTB_Customer_PO__c;  
            }else if(invoice.QTB_Purchase_Order__c != null && invoice.QTB_Account_Sitad__c){
                w.invPONumber = invoice.QTB_Purchase_Order__c;	//#27433
            }*/
            w.Cust_addr_str = invoice.blng__Account__r.BillingStreet != null? invoice.blng__Account__r.BillingStreet : '';
            w.Cust_addr_pc = invoice.blng__Account__r.BillingPostalCode != null? invoice.blng__Account__r.BillingPostalCode : '';
            w.Cust_addr_ci = invoice.blng__Account__r.BillingCity != null? invoice.blng__Account__r.BillingCity : '';
            w.Cust_addr_cou = invoice.blng__Account__r.BillingCountry != null? invoice.blng__Account__r.BillingCountry : '';
            
            //Invoice Header Row3 Mapping
            //w.header3 = '02';
            if(invoiceLineStartdate != null){
                w.print_from_date = DateTime.newInstance(invoiceLineStartdate.year(),invoiceLineStartdate.month(),invoiceLineStartdate.day()).format('dd/MM/yyyy');//Story 3947 End date issue
            }
            //#16008 Nordics print_to_date update to Invlin.Enddate
            if(nordicBillingCountriesPresent && invoiceLineEnddate != null){
                w.print_to_date = DateTime.newInstance(invoiceLineEnddate.year(),invoiceLineEnddate.month(),invoiceLineEnddate.day()).format('dd/MM/yyyy');//#16008 Nordics print_to_date update to Invlin.Enddate
            }else{
                w.print_to_date = invoice.blng__InvoiceDate__c != null? DateTime.newInstance(invoice.blng__InvoiceDate__c.year(),invoice.blng__InvoiceDate__c.month(),invoice.blng__InvoiceDate__c.day()).format('dd/MM/yyyy') : ''; //Story 3947 End date issue
            }
            w.retention_from_date = '';
            w.retention_to_date = '';
            w.bill_inquiry_phone = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c : '';
            if(usageCodes != null && usageCodes.size()>0){
                w.print_level = 'Y';
            }
            else{
                w.print_level = 'N';  
            }
            if(!usageLevelCode.isEmpty()){
                w.usage_level1name = new List<String> (usageLevelCode).get(0);
            }
            //Invoice Header Row4 Mapping
            //w.header4 = '03;
            If(String.isNotBlank(ContactEmail)){
                w.Email_id = ContactEmail;
            }
            //Invoice Notes Mapping
            //w.header5 = '10';
            w.header_note = invoice.blng__Account__r.QTB_Invoice_Notes__c != null? invoice.blng__Account__r.QTB_Invoice_Notes__c.replace('\n','') : '';
            w.header_note1 = invoice.blng__Notes__c != null? invoice.blng__Notes__c.replace('\n','') : '';
           
            //Tax Details Mapping
            //w.header7 = '50';
            w.inv_subtotal = invoice.blng__Subtotal__c != null? String.valueOf(invoice.blng__Subtotal__c.setScale(2)) : ''; 
			//#21361 Changed to QTB_Tax_Override_Amount__c and QTB_Total_Amount_with_Tax_Override__c
            w.inv_vat_tax = invoice.QTB_Tax_Override_Amount__c != null? String.valueOf(invoice.QTB_Tax_Override_Amount__c.setScale(2)) : '';
            w.con = '0';
            w.inv_sale_tax = invoice.QTB_Tax_Override_Amount__c != null? String.valueOf(invoice.QTB_Tax_Override_Amount__c.setScale(2)) : '';
            w.total_tax = invoice.QTB_Total_Amount_with_Tax_Override__c != null? String.valueOf(invoice.QTB_Total_Amount_with_Tax_Override__c.setScale(2)) : '';
            
            //File Footer Mapping
            //w.header8 = '90';
            w.remit_addr_bank = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c : '';
            w.remit_addr_acn = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c : '';
            w.remit_addr_cou = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c : '';
            w.inv_ref_num = invoice.QTB_KID__c != null? invoice.QTB_KID__c : '';
            w.iban = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c : '';
            //Swift code Addition in the Apix extract for Nordics 
            w.swift = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c : '';
            
            //File Footer2 Mapping
            //w.header9 = '91';
            w.print_invoice_date1 = invoice.blng__InvoiceDate__c != null? DateTime.newInstance(invoice.blng__InvoiceDate__c.year(),invoice.blng__InvoiceDate__c.month(),invoice.blng__InvoiceDate__c.day()).format('dd/MM/yyyy') : '';   //Story 3947 End date issue
            w.bill_to_cust_id1 = invoice.blng__Account__r.QTB_Customer_Number__c != null? invoice.blng__Account__r.QTB_Customer_Number__c : '';
            w.name1 = invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null? invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c : '';
            w.inv_amount = invoice.QTB_Total_Amount_with_Tax_Override__c != null? String.valueOf(invoice.QTB_Total_Amount_with_Tax_Override__c.setScale(2)) : '';
            w.bi_currency_cd = invoice.CurrencyIsoCode != null? invoice.CurrencyIsoCode : '';
            
            //Summary Details Mapping
            //w.header10 = '99';
            Datetime todayDate = Datetime.now();
            w.ReportDate = todayDate.format('dd/MM/yyyy');//Story 3947 End date issue
            w.ReportTime = String.valueOf(datetime.now().time());
            w.invoice_count = '1';
            w.rcl_total_bill_amt = invoice.QTB_Total_Amount_with_Tax_Override__c != null? String.valueOf(invoice.QTB_Total_Amount_with_Tax_Override__c.setScale(2)) : '';
            w.sum_currency = invoice.CurrencyIsoCode != null? invoice.CurrencyIsoCode : '';//#17381 Updation of the curcode from Invoice Currency code
            
            lstwrapper.add(w);
            return lstwrapper;//Gitlab US#24329
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractCTRL.mappingToTxt');
            return null;//Gitlab US#24329
        }
    }
    
    //Gitlab US#24329 -- returning the List<usagewrapper>
    public List<usagewrapper> mappingToUsage(List<GroupWrapperCls> usages,List<IM_Country__c> country,blng__Invoice__c invoice,List<QTB_PurchaseOrder__c> purchaseOrderLst,map<string,string> maplocalization, boolean isNordeaAcc , Map<string, integer> L1L2L3GrpMap)
    {
        integer invnum = 1;
        Map<string, integer> L1L2L3GrpCompareMap = new Map<string, integer>();
        Map<string, Decimal> L1L2L3GrpSubTotalMap = new Map<string, Decimal>();
        /************** Changes for Story #1317 Starts **************/  
        //Fetch all the records from the "Custom Product Name" table    
        list<QTB_Custom_Product_Name__c> customProductNameList = [Select id, Account__c, Custom_Name__c, Product__c 
                                                                  from QTB_Custom_Product_Name__c where Account__c = :invoice.blng__Account__c];  
        //Custom Product Name map having key - AccountId+ProductId and value - Custom Product Name  
        Map<String, String> customProductNameMap = new Map<String, String>();   
        for (QTB_Custom_Product_Name__c customProductName : customProductNameList) {    
            //Additional check to create valid map only.    
            if (customProductName.Account__c != NULL && customProductName.Product__c != NULL && customProductName.Custom_Name__c != NULL ) {    
                customProductNameMap.put(String.valueof(customProductName.Account__c)+String.valueof(customProductName.Product__c), String.valueof(customProductName.Custom_Name__c));  
            }   
        }   
        /************** Changes for Story #1317 Ends **************/
        try{
            for(GroupWrapperCls ar : usages){
                usagewrapper w = new usagewrapper();    
                //w.header6 = '20';
                if(country != null && country.size() > 0){
                    w.invoice_layout6 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                    w.invoice_layout_bu6 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                }
                if(invoice.blng__InvoiceStatus__c == 'Posted'){
                    w.invoice_num6 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                }
                else{
                    w.invoice_num6 = 'TEMP-'+invoice.Name;  
                }
                if((ar.lev1code != '' && ar.lev1code != null) || (ar.divisionCode != '' && ar.divisionCode != null) || (ar.departmentCode != '' && ar.departmentCode != null)){
                    w.print_level1 = 'Y';
                    //Add L1 Code / L2 Code / L3 Code in a sequence
                    string custId = '';
                    if(ar.lev1code != null){
                        custId = ar.lev1code;
                    }
                    if(ar.divisionCode != null){
                        if(custId != ''){
                            custId += '/'+ar.divisionCode;
                        }else{
                            custId = ar.divisionCode;
                        }
                    }
                    if(ar.departmentCode != null){
                        if(custId != ''){
                            custId += '/'+ar.departmentCode;
                        }else{
                            custId = ar.departmentCode;
                        }
                    }
                    //#30985 Changes
                    if(ar.isSitadAccount){
                       if(custId!= null){
                          String suffix = custId.contains('.')?custId.split('\\.')[1]:custId;
                          //Remove Leading zeros
                          custId = suffix.replaceFirst('^0+','');
                      }
                    }
                    w.level_custmer_id = custId;
                }
                else{
                    w.print_level1 = 'N'; 
                }
                
                //If It's a Nordea Account
                if(isNordeaAcc){
                    if(ar.departmentname != '' && ar.departmentname != null){
                        //If Work Order Id not Null
                        if(ar.workOrderId != null || ar.requestor != null){
                            if(ar.workOrderId != null && ar.requestor != null){
                                w.level_name_12 = String.valueOf(ar.departmentname)+' / '+ar.workOrderId +' '+ ar.requestor;   
                            }else if(ar.workOrderId != null){
                                w.level_name_12 = String.valueOf(ar.departmentname)+' / '+ar.workOrderId;
                            }else{
                                w.level_name_12 = String.valueOf(ar.departmentname)+' / '+ar.requestor;
                            }
                        }else{
                            w.level_name_12 = String.valueOf(ar.departmentname);
                        }
                        //If Div not Null    
                    }else if(ar.divisionname != '' && ar.divisionname != null){
                        //If Work Order Id not Null
                        if(ar.workOrderId != null || ar.requestor != null){
                            if(ar.workOrderId != null && ar.requestor != null){
                                w.level_name_12 = String.valueOf(ar.divisionname)+' / '+ar.workOrderId +' '+ ar.requestor;   
                            }else if(ar.workOrderId != null){
                                w.level_name_12 = String.valueOf(ar.divisionname)+' / '+ar.workOrderId;
                            }else{
                                w.level_name_12 = String.valueOf(ar.divisionname)+' / '+ar.requestor;
                            }
                        }else{
                            w.level_name_12 = String.valueOf(ar.divisionname);
                        }
                        //If Dep not Null
                    }else if(ar.lev1name != '' && ar.lev1name != null){
                        //If Work Order Id not Null
                        if(ar.workOrderId != null || ar.requestor != null){
                            if(ar.workOrderId != null && ar.requestor != null){
                                w.level_name_12 = String.valueOf(ar.lev1name)+' / '+ar.workOrderId +' '+ ar.requestor;   
                            }else if(ar.workOrderId != null){
                                w.level_name_12 = String.valueOf(ar.lev1name)+' / '+ar.workOrderId;
                            }else{
                                w.level_name_12 = String.valueOf(ar.lev1name)+' / '+ar.requestor;
                            }
                        }else{
                            w.level_name_12 = String.valueOf(ar.lev1name);
                        }
                        //If Dep not Null
                    }else if(ar.workOrderId != null || ar.requestor != null){
                        if(ar.workOrderId != null && ar.requestor != null){
                            w.level_name_12 = ar.workOrderId +' '+ ar.requestor;   
                        }else if(ar.workOrderId != null){
                            w.level_name_12 = ar.workOrderId;
                        }else{
                            w.level_name_12 = ar.requestor;
                        }
                    }
                    //If It's not a Nordea Account
                }else{
                    if(ar.departmentname != '' && ar.departmentname != null){
                        w.level_name_12 = String.valueOf(ar.departmentname);   
                    }else if(ar.divisionname != '' && ar.divisionname != null){
                        w.level_name_12 = String.valueOf(ar.divisionname);
                    }else if(ar.lev1name != '' && ar.lev1name != null){
                        w.level_name_12 = String.valueOf(ar.lev1name);
                    }else if (ar.isSitadAccount){
                        w.level_name_12 = String.valueOf(ar.billingAccountName);
                    }
                    // w.level_name_12 =EncodingUtil.base64Decode(w.level_name_12);
                }
                w.inv_linenum = invnum++;
                string lockey = String.valueOf(ar.productCode)+' '+String.valueOf(ar.AccLanguage);
                /************** Changes for Story #1317 Starts **************/  
                //#13521 - For Nordic Billing countries, line description to be picked from usages-> product identifier
                if(nordicBillingCountriesPresent){
                    if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(';;;')[0] == 'Storage' ){
                        string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : ''; //Story 3947 End date issue
                        string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';//Story 3947 End date issue
                        w.usageproduct = ar.CusInvDisplay+' '+'('+pStartDate+' '+pEndDate+')';
                    }else{
                        w.usageproduct = ar.CusInvDisplay;
                    }
                    
                }else{
                    if(ar.displayPnameCheck == true && customProductNameMap.get(String.valueof(invoice.blng__Account__c)+String.valueOf(ar.productId)) != NULL ){
                        // GITLAB# 1321 If Product Schedule Category is STORAGE then    
                        // usage product will Custom Inv Display (Start Date MRC  End Date MRC)
                        if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(';;;')[0] == 'Storage' ){
                            string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : ''; //Story 3947 End date issue
                            string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';//Story 3947 End date issue
                            w.usageproduct = customProductNameMap.get(String.valueof(invoice.blng__Account__c)+String.valueOf(ar.productId))+' '+'('+pStartDate+' '+pEndDate+')';
                        }else{
                            w.usageproduct = customProductNameMap.get(String.valueof(invoice.blng__Account__c)+String.valueOf(ar.productId));
                        }
                        /************** Changes for Story #1317 Ends **************/
                    }
                    else if(maplocalization.containsKey(lockey)){
                        string pName = maplocalization.get(lockey);
                        if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(';;;')[0] == 'Storage'){
                            string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : ''; //Story 3947 End date issue
                            string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                            w.usageproduct = pName+' '+'('+pStartDate+' '+pEndDate+')';
                        }else{
                            w.usageproduct = pName;
                        }
                    }else{
                        string pName = String.valueOf(ar.productName)  != null? String.valueOf(ar.productName) : '';
                        if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(';;;')[0] == 'Storage'){                    
                            string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                            string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                            w.usageproduct = pName+' '+'('+pStartDate+' '+pEndDate+')';
                        }else{
                            w.usageproduct = pName;
                        }
                    }
                }
                //Addition of POGR
                w.POGR =  invoice.blng__Account__r.QTB_EDI_Identifier__c != null? invoice.blng__Account__r.QTB_EDI_Identifier__c : '';
                system.debug('POGR >>> '+w.POGR);
                // Changes related to US #28622.Checking prerated quantity as quantity field is not populated.
                if (ar.preratequantity != null && ar.preratequantity >0 ){
                    w.lineqty = String.valueOf(ar.preratequantity.setScale(2, RoundingMode.HALF_UP));
                }else if(ar.quantity != null){
                    w.lineqty = String.valueOf(ar.quantity.setScale(2, RoundingMode.HALF_UP));
                }                    
                
                if(invoice.blng__InvoiceStatus__c == 'Posted'){
                    Decimal usageratedamount = double.valueof(ar.ratedAmount);
                    w.invlineamount = String.valueOf(usageratedamount.setScale(2, RoundingMode.HALF_UP));
                }else if(invoice.blng__InvoiceStatus__c == 'Draft' && ar.prerateamount != 0.0 ){
                    Decimal usagepreamount = double.valueof(ar.prerateamount);
                    w.invlineamount = String.valueOf(usagepreamount.setScale(2, RoundingMode.HALF_UP));
                }else{
                    if(String.valueOf(ar.usQuantity) != null && String.valueOf(ar.usSumUnitprice) != null){
                        w.invlineamount = String.valueOf(Decimal.valueof(double.valueOf(ar.usQuantity)*double.valueOf(ar.usSumUnitprice)).setScale(2, RoundingMode.HALF_UP));
                    }
                }
                //Only for Recurring Invoice Line
                if(ar.recordId == null && ar.subtotalLine != null){
                    w.invlineamount = String.valueOf(ar.subtotalLine.setScale(2, RoundingMode.HALF_UP));
                }
                //For both Draft and Posted
                Decimal usageunitprice =0;
                if(nordicBillingCountriesPresent){
                    //#18631 For Finland specific unit amount calculation
                    if(ar.legalEntityCountry == 'Finland'){
                        //If Prerated Unit Price is present then to populate its value else looks for Prerated amount / Qty
                        if(ar.preratedUnitAmount != null && ar.preratedUnitAmount > 0){
                            w.unitamt = String.valueOf(ar.preratedUnitAmount.setScale(4));
                        }
                        else if(ar.prerateamount > 0){
                            if(w.lineqty != null && decimal.valueOf(w.lineqty) != 0){
                                usageunitprice = double.valueof(decimal.valueOf(w.invlineamount)/decimal.valueOf(w.lineqty));
                                w.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                            }
                        }
                    }
                    //For all nordics countries which doesnot belongs to Finland then to calculate as earlier
                    else {
                        if(ar.prerateamount > 0){
                            if(w.lineqty != null && decimal.valueOf(w.lineqty) != 0){
                                usageunitprice = double.valueof(decimal.valueOf(w.invlineamount)/decimal.valueOf(w.lineqty));
                                w.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                            }
                        }else{
                            w.unitamt = String.valueOf(ar.preratedUnitPrice.setScale(4, RoundingMode.HALF_UP));
                        }
                }
                }
                
                else{
                    if(ar.prerateamount > 0){
                        if(w.lineqty != null && decimal.valueOf(w.lineqty) != 0){
                            usageunitprice = double.valueof(decimal.valueOf(w.invlineamount)/decimal.valueOf(w.lineqty));
                            w.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                        }else{
                            usageunitprice = double.valueof(w.invlineamount);
                            w.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                        }
                    }else{
                        if(invoice.blng__InvoiceStatus__c == 'Posted' && ar.ratedunitPrice != null){
                            usageunitprice = double.valueof(ar.ratedunitPrice);
                        }else if(ar.usSumUnitprice != null){
                            usageunitprice = double.valueof(ar.usSumUnitprice);
                        }
                        if(ar.term != null && usageunitprice != null){
                            w.unitamt = String.valueOf((usageunitprice * ar.term).setScale(4, RoundingMode.HALF_UP));
                        }else if(usageunitprice != null){
                            w.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                        }
                    }
                }
                //Only for Recurring Invoice Line
                if(ar.recordId == null && ar.unitPriceLine != null){
                    w.unitamt = String.valueOf(ar.unitPriceLine.setScale(4, RoundingMode.HALF_UP));
                }
                
                // Assign translated category to usg_category
                w.usg_category = String.valueOf(ar.scheduleCategory) != null? String.valueOf(ar.scheduleCategory).split(';;;')[1] : '';
                if(purchaseOrderLst != null && purchaseOrderLst.size()>0){
                    for(QTB_PurchaseOrder__c po :purchaseOrderLst){
                        if(ar.lev1code == po.QTB_Customer_Id__c){
                            if((ar.divisionCode != null && ar.departmentCode == null && po.QTB_Division__c == ar.divisionCode) || (ar.departmentCode!= null && ar.divisionCode == null && po.QTB_Div_Dept_Level__c == ar.departmentCode) || (ar.departmentCode!= null && ar.divisionCode != null && po.QTB_Div_Dept_Level__c == ar.departmentCode && po.QTB_Division__c == ar.divisionCode)){
                                w.usage_po = po.QTB_Customer_PO__c != null? po.QTB_Customer_PO__c : ''; 
                            }
                            //25327 - Populating PO From the invoice level.
                            else if(!invoice.QTB_Account_Sitad__c && invoice.QTB_PurchaseOrder__c != null)
                            {
                                System.debug('>>invPO');
                                w.usage_po = invoice.QTB_PurchaseOrder__r.QTB_Customer_PO__c;
                            }
                        }
                    }
                }
               
                else if(invoice.QTB_Purchase_Order__c != null && invoice.QTB_Account_Sitad__c) {
                    w.usage_po = invoice.QTB_Purchase_Order__c;	//#27433
                }
                //Check the records for grouping and adding line 40th Line at the proper place
                usageSubtotalWrapper usWrapSub = new usageSubtotalWrapper();
                if(invoice.blng__InvoiceStatus__c == 'Posted'){
                    usWrapSub.invoice_num12 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                }else{
                    usWrapSub.invoice_num12 = 'TEMP-'+invoice.Name;  
                }
                if(country != null && country.size() > 0){
                    usWrapSub.invoice_layout12 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                    usWrapSub.invoice_layout_bu12 = country[0].Iso31662Code__c != null? country[0].Iso31662Code__c+'IDS' : '';
                }
                
                //New Grouping logic based on Level1/ level2/ level3/ workorder id
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
                if(isNordeaAcc){
                    if(ar.workOrderId != null){
                        grpKeyString += ar.workOrderId;
                    }
                }
                if(grpKeyString != ''){
                    if(L1L2L3GrpCompareMap.containsKey(grpKeyString)){
                        L1L2L3GrpCompareMap.put(grpKeyString,L1L2L3GrpCompareMap.get(grpKeyString)+1);
                    }else{
                        L1L2L3GrpCompareMap.put(grpKeyString,1);
                    }
                }
                //Check if the number of records for grouping is same or not?
                //Grouping number matches, then add Line No 40(Subtotal)
                if(L1L2L3GrpMap.containsKey(grpKeyString)){
                    if(L1L2L3GrpMap.get(grpKeyString) == L1L2L3GrpCompareMap.get(grpKeyString)){
                        //Multiple records are there in the group
                        if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                            usWrapSub.subtotal40thLine = (L1L2L3GrpSubTotalMap.get(grpKeyString)  + decimal.valueOf(w.invlineamount) ).setScale(2, RoundingMode.HALF_UP);
                            w.usageSubtotal = usWrapSub;
                        }else{
                            //Match in first time(only one occurance)
                            usWrapSub.subtotal40thLine = decimal.valueOf(w.invlineamount).setScale(2, RoundingMode.HALF_UP);
                            w.usageSubtotal = usWrapSub;
                            //Just keep the map in the sync // Not required to add the amount
                            L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueOf(w.invlineamount));
                        }
                    }else{//Grouping number not matches
                        //Already present the key// More number of records in the grouping
                        if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                            L1L2L3GrpSubTotalMap.put(grpKeyString,L1L2L3GrpSubTotalMap.get(grpKeyString) + decimal.valueOf(w.invlineamount));
                        }else{
                            //First time key
                            L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueOf(w.invlineamount));
                        }
                    }
                }
                lstusagewrapper.add(w);
            }
            return lstusagewrapper; //Gitlab US#24329
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractCTRL.mappingToUsage');
            return null;//Gitlab US#24329
        }
    }
    Public class GroupWrapperCls{
        public string productName;
        public string productCode;
        public String scheduleCategory;
        public string divisionCode;
        public string departmentCode;
        //#13521
        public string productIdentifier;
		//#20247
        public string priceTier;
        //#18631
        public string legalEntityCountry;
        public decimal preratedUnitAmount;
        //Addition of POGR
        public string POGR;
        public decimal ratedAmount;
        public decimal usSumUnitprice;
        public string departmentname;
        public boolean displayPnameCheck;
        public string AccLanguage;
        //#27216 & #28005 addition of isSitadAccount
        public Boolean isSitadAccount;
        public string lev1name;
        public string lev1code;
        public string divisionname;
        public decimal ratedunitPrice;
        public decimal quantity;
        public decimal preratequantity;
        public decimal prerateamount;
        public decimal preratedUnitPrice;
        public decimal usQuantity;
        public string CusInvDisplay;
        public Date startdate;
        public Date enddate;
        public integer term;
        public string workOrderId;
        public string requestor;
        //Extra field for Invoice Line
        public decimal unitPriceLine;
        public decimal subtotalLine;
        //This is to identify if the record is a Usage record or a Invoice Line reocrd// Only Usage records will have the Id, else null
        public string recordId;
        public string productId; //Changes for Story #1317
        //Changes for story #28005
        public String billingAccountName;
        public GroupWrapperCls(blng__Usage__c usge,GroupWrapperCls exitingWraper){
            this.productName = usge.blng__OrderProduct__r.Product2.Name;
            this.productCode = usge.blng__OrderProduct__r.Product2.productCode;
            this.productId = usge.blng__OrderProduct__r.Product2.Id;
            string category;
            //setting picklist value and translated value of price schedule category. 
            Schema.DescribeFieldResult statusOptions = product2.QTB_Price_Schedule_Category__c.getDescribe();
            //Usage.Order Product.Product.Price Schedule Category = 'Services' OR 'Services Off-Site' OR 'Services On-Site' OR 'Other Program Fees' OR NOT(Storage,Transport,Supplies)
            if(usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Storage' && usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Transportation' && usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != 'Supplies'){
                //this.scheduleCategory = 'Services'+';;;'+'Services';
                for(Schema.PicklistEntry p : statusOptions.getPicklistValues()){
                    //Set Price schedule category translated values and api values into scheduleCategory.
                    if(p.getValue() == 'Services'){
                        this.scheduleCategory = p.getValue()+';;;'+p.getLabel();
                        category = p.getValue();
                    }
                }
            }else{
                for(Schema.PicklistEntry p : statusOptions.getPicklistValues()){
                    System.debug(LoggingLevel.ERROR, 'p.getLabel() = ' + p.getLabel()+'p.getValue() = ' + p.getValue());
                    //Set Price schedule category translated values and api values into scheduleCategory.
                    if(usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c == p.getValue()){
                        this.scheduleCategory = p.getValue()+';;;'+p.getLabel();
                        category = p.getValue();
                    }
                }
            }
            if(System.isBatch()){
                this.scheduleCategory = category +';;;'+ QTB_GenerateApixExtractBatch.getCustomLabelTranslation(category,usge.blng__Account__r.QTB_Language__c);
            }
            System.debug('@@@@@ schedule category@@@@ '+scheduleCategory);
            //this.scheduleCategory = usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
            this.divisionCode = usge.QTB_Division_Code__c;
            this.departmentCode = usge.QTB_Department_Code__c;
            this.departmentname = usge.QTB_Department_Name__c;
            this.displayPnameCheck = usge.blng__Account__r.QTB_Display_Custom_Product_Names__c;
            this.AccLanguage = usge.blng__Account__r.QTB_Language__c;
            this.lev1name = usge.QTB_Level_1_Name__c;
            this.lev1code = usge.QTB_Level_1_Code__c;
            //#27216 & #28005
            this.isSitadAccount = usge.blng__Account__r.QTB_SITAD__c;
            //#28005
            this.billingAccountName=usge.blng__Account__r.name;
            //#13521
            this.productIdentifier = usge.QTB_Product_Identifier_1__c;
			//#20247
            this.priceTier = usge.QTB_Price_Tier__c;
            //#18631
            this.legalEntityCountry = usge.QTB_Legal_Entity_Country__c;
            //#18631
            this.preratedUnitAmount = usge.QTB_Prerated_Unit_Price__c; 
            this.divisionname = usge.QTB_Division_Name__c;
            this.ratedunitPrice = usge.QTB_Rated_Unit_Price__c;
            this.usSumUnitprice = usge.blng__UsageSummary__r.blng__UnitPrice__c!= null? usge.blng__UsageSummary__r.blng__UnitPrice__c:0;
            this.CusInvDisplay = usge.QTB_Custom_Invoice_Display__c;
            this.startdate = usge.QTB_Start_Date_MRC__c;
            this.enddate = usge.QTB_End_Date_MRC__c;
            if(usge.QTB_Term__c != null){
                this.term = Integer.valueOf(usge.QTB_Term__c);
            }
            this.workOrderId = usge.QTB_Work_Order_ID__c;
            this.requestor = usge.QTB_Requestor__c;
            //This is to identify if the record is a Usage record or a Invoice Line reocrd
            this.recordId = usge.id;
            //Extra field for Invoice Line
            if(usge.id == null){
                if(usge.QTB_Cost_Center__c != 'Storage' && usge.QTB_Cost_Center__c != 'Transportation' && usge.QTB_Cost_Center__c != 'Supplies'){
                    //this.scheduleCategory = 'Services'+';;;'+'Services';
                    for(Schema.PicklistEntry p : statusOptions.getPicklistValues()){
                        //Set Price schedule category translated values and api values into scheduleCategory.
                        if(p.getValue() == 'Services'){
                            this.scheduleCategory = p.getValue()+';;;'+p.getLabel();
                        }
                    }
                }else{
                    for(Schema.PicklistEntry p : statusOptions.getPicklistValues()){
                        System.debug(LoggingLevel.ERROR, 'p.getLabel() = ' + p.getLabel()+'p.getValue() = ' + p.getValue());
                        //Set Price schedule category translated values and api values into scheduleCategory.
                        if(usge.QTB_Cost_Center__c == p.getValue()){
                            this.scheduleCategory = p.getValue()+';;;'+p.getLabel();
                        }
                    }
                }
                //Assign the values from the temporary Usages instances to Wrapper variables
                this.productName = usge.blng__MatchingAttribute__c;
                this.productCode = usge.blng__ErrorMessage__c;
                this.unitPriceLine = usge.blng__UnitPrice__c;
                this.subtotalLine = usge.blng__Subtotal__c;
                this.displayPnameCheck = usge.QTB_UsedforRerate__c;
                this.AccLanguage = usge.QTB_Service_District__c;
            }
            //Already existing record for the Grouping, get the existing value and add it/agreegate values
            if(exitingWraper!= null){
                this.ratedAmount = (usge.QTB_Rated_Amount__c!= null? usge.QTB_Rated_Amount__c:0)+exitingWraper.ratedAmount; 
                this.quantity = (usge.QTB_Invoice_Quantity__c!= null? usge.QTB_Invoice_Quantity__c:0)+exitingWraper.quantity; 
                this.preratequantity = (usge.blng__PreratedQuantity__c!= null? usge.blng__PreratedQuantity__c:0)+exitingWraper.preratequantity; 
                this.prerateamount = (usge.blng__PreratedAmount__c!= null? usge.blng__PreratedAmount__c:0)+exitingWraper.prerateamount; 
                this.preratedUnitPrice = (usge.QTB_Prerated_Unit_Price__c!= null? usge.QTB_Prerated_Unit_Price__c:0)+exitingWraper.preratedUnitPrice; 
                this.usQuantity = (usge.blng__Quantity__c!= null? usge.blng__Quantity__c:0)+exitingWraper.usQuantity; 
            }else{//Fresh record for the Grouping, keep the value else, values as '0'
                this.ratedAmount = usge.QTB_Rated_Amount__c!= null? usge.QTB_Rated_Amount__c:0;
                this.quantity = usge.QTB_Invoice_Quantity__c!= null? usge.QTB_Invoice_Quantity__c:0;
                this.preratequantity = usge.blng__PreratedQuantity__c!= null? usge.blng__PreratedQuantity__c:0;
                this.prerateamount = usge.blng__PreratedAmount__c!= null? usge.blng__PreratedAmount__c:0;
                this.preratedUnitPrice = usge.QTB_Prerated_Unit_Price__c!= null? usge.QTB_Prerated_Unit_Price__c:0;
                this.usQuantity = usge.blng__Quantity__c!= null? usge.blng__Quantity__c:0;
            }
        }
    }
    //wrapper class for usage
    public class usagewrapper{
        public string header6 {get; set;}
        public string invoice_layout6 {get; set;}
        public string invoice_layout_bu6 {get; set;}
        public string invoice_num6 {get; set;}
        public string print_level1 {get; set;}
        public string level_custmer_id {get; set;}
        public string level_name_12 {get; set;}
        public string usage_po {get; set;}
        //Addition of POGR
        public string POGR {get; set;}
        public string usageproduct {get; set;}
        public string usagequantity {get; set;}
        public string invlineamount {get; set;}
        public string unitamt {get; set;}
        public string lineqty {get; set;}
        public integer inv_linenum {get; set;}
        public string usg_category {get; set;}
        public usageSubtotalWrapper usageSubtotal {get;set;}
    }
    //wrapper class for getting the 40th Line Record.
    public class usageSubtotalWrapper{
        public decimal subtotal40thLine{get;set;}
        public string invoice_layout12{get;set;}
        public string invoice_layout_bu12{get;set;}
        public string invoice_num12{get;set;}
        public usageSubtotalWrapper(){
            
        }
    }
    //wrapper class for invoice
    public class wrapper{
        //Invoice Header Row1 Mapping
        //public string header1 {get; set;}
        public string invoice_layout {get; set;}
        public string invoice_layout_bu{get; set;}
        public string invoice_num{get; set;}
        public string rpt_language_cd {get; set;}
        public string print_invoice_date {get; set;}
        public string bill_cust_id {get; set;}
        public string pay_terms_descrshort {get; set;}
        public string print_due_date {get; set;}
        public string PO_ID {get; set;}
        public string report_file {get; set;}
        //Changes for differentiate between 'Draft' and 'Posted' Invoice - Story #742
        public string invoice_status {get;set;}
        
        //Invoice Header Row2 Mapping
        //public string header2 {get; set;}
        public string invoice_layout2 {get; set;}
        public string invoice_layout_bu2{get; set;}
        public string invoice_num2{get; set;}
        public string print_gst {get; set;}
        public string Cust_addr_ln1 {get; set;}
        //public String invPONumber {get; set;} //22030 //Commenting as part of #25327 GITLAB
        public string Cust_addr_str {get; set;}
        public string Cust_addr_pc {get; set;}
        public string Cust_addr_ci {get; set;}
        public string Cust_addr_cou {get; set;}
        //public string Cust_addr_ln6 {get; set;}
        //public string Cust_addr_ln7 {get; set;}
        //public string Cust_addr_ln8 {get; set;}
        
        //Invoice Header Row3 Mapping
        //public string header3 {get; set;}
        public string invoice_layout3 {get; set;}
        public string invoice_layout_bu3 {get; set;}
        public string invoice_num3 {get; set;}
        public string print_level {get; set;}
        public string usage_level1name {get; set;}
        public string print_from_date {get; set;}
        public string print_to_date {get; set;}
        public string retention_from_date {get; set;}
        public string retention_to_date {get; set;}
        public string bill_inquiry_phone {get; set;}
        public string original_invoice {get; set;}
        public string orig_inv_dt {get; set;}
        public string prior_adj_invoice {get; set;}
        public string prior_inv_dt {get; set;}
        
        //Invoice Header Row4 Mapping
        //public string header4 {get; set;}
        public string invoice_layout4 {get; set;}
        public string invoice_layout_bu4 {get; set;}
        public string invoice_num4 {get; set;}
        public string Email_id {get; set;}
        
        //Invoice Notes Mapping
        //public string header5 {get; set;}
        public string invoice_layout5 {get; set;}
        public string invoice_layout_bu5 {get; set;}
        public string invoice_num5 {get; set;}
        public string header_note {get; set;}
        public string header_note1 {get; set;}
        
        //Tax Details Mapping
        //public string header7 {get; set;}
        public string invoice_layout7 {get; set;}
        public string invoice_layout_bu7 {get; set;}
        public string invoice_num7 {get; set;}
        public string inv_subtotal{get; set;}
        public string inv_vat_tax{get; set;}
        public string con{get; set;}
        public string inv_sale_tax{get; set;}
        public string total_tax{get; set;}
        
        //File Footer Mapping
        //public string header8 {get; set;}
        public string invoice_layout8 {get; set;}
        public string invoice_layout_bu8 {get; set;}
        public string invoice_num8 {get; set;}
        public string remit_addr_bank{get; set;}
        public string remit_addr_acn{get; set;}
        public string remit_addr_cou{get; set;}
        public string inv_ref_num{get; set;}
        public string iban{get; set;}
        public string swift{get; set;}
        
        //File Footer2 Mapping
        //public string header9 {get; set;}
        public string invoice_layout9 {get; set;}
        public string invoice_layout_bu9 {get; set;}
        public string invoice_num9 {get; set;}
        public string print_invoice_date1{get; set;}
        public string bill_to_cust_id1{get; set;}
        public string name1{get; set;}
        public string inv_amount{get; set;}
        public string bi_currency_cd{get; set;}
        
        //Summary Details Mapping
        //public string header10 {get; set;}
        public string ReportDate {get; set;}
        public string ReportTime{get; set;}
        public string invoice_count{get; set;}
        public string rcl_total_bill_amt{get; set;}
        public string sum_currency{get; set;}
    }
}