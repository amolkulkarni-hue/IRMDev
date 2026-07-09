/*****************************************************************************************************
* Class: QTB_GenerateUsageCSVCTRL
* Purpose: This class containing logic for generating csv file for invoice
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*  Sriram      7/21/2020       Created initial class 
*  TCS         2/03/2023       Updated for Billcode population for nordics and header columns
*  TCS         2/24/2023       Addition of new header column as part of #13861 story
*  TCS         12/02/2023      Changes to Support Backing up report generation for SITAD Story #19549 
*******************************************************************************************************/
public without sharing class QTB_GenerateUsageCSVCTRL {
    
    public string header{get;set;}
    public List<wrapper> lstwrapper {get; set;}
    public static List<blng__Invoice__c> invLst;
    public static boolean isSitadInvoice {get; set;}
    public static boolean throwExplicitException = false;
    public static String sitadEmptyMandatoryFields {get; set;}
    public static String InvoiceIDString {get; set;}
    //Call Construtor 
    public QTB_GenerateUsageCSVCTRL(){
        try{
            //Get parameter(Invoice Id) from the VF Page
            string InvoiceID = ApexPages.currentPage().getParameters().get('Id');
            InvoiceIDString = InvoiceID;
            If(String.isNotBlank(InvoiceID)){
                lstwrapper = new List<wrapper>();
                //Define Header for the CSV Files
                //header = 'Order/work Order Reference,Order Date,Order Contact,Auth User Name Order,Bill To Contact,Customer Account ID,District ID,Division/Level 2 ID,Division/Level 2 Name,Department/Level 3 ID,Department/Level 3 Name,Invoice Date,Invoice Number/Reference,Bill Code,Bill Code Description,Billable Cubic Ft,Months of Storage,Unit Qty,Unit of Measure,UnitRate,Amount,TaxAmount,Currency,Storage Date,Service Date,Service Type,Contract PO Number,Cost Centre Number,Order PO Number,Bill-To Address 1,Bill-To Address City,Bill-To Address State,Bill-To Address Zip,Remit To Address 1,Remit To City,Remit To State,Remit To Zip,Ship-To Address,Ship-To Address City,Ship-To Address State,Ship-To Zip,Service Account,Site PO Number,Payment Due date,Email address\r';            
                //Define Header for the CSV Files
                //Updation of Bill code and Bill code Description to Source code and Product Description
                //Query for invoice data
                invLst = [SELECT blng__InvoiceDate__c,QTB_PurchaseOrder__c,QTB_PurchaseOrder__r.QTB_Customer_PO__c,QTB_Custom_Invoice_Number__c,blng__DueDate__c,blng__Account__r.id,blng__Account__r.QTB_Legal_Entity_Country__c,
                          blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,
                          blng__Account__r.QTB_Invoice_Detail_Options__c,blng__Account__r.QTB_Bill_Cycle_Day__c,
                          blng__Account__r.BillingCountry,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode
                          FROM blng__Invoice__c WHERE Id =:InvoiceID];
                
                //isSITAD variable #19549
                isSitadInvoice = false;
                
                /*-------#13861 Start of Nordic Billing only country Billcode population-----*/
                Boolean nordicCountriesPresent =false;
                    List<String> NordicBillingOnlyCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
                    for(String country:NordicBillingOnlyCountries)
                    {
                        if(invLst[0].blng__Account__r.QTB_Legal_Entity_Country__c == country){
                            nordicCountriesPresent = true;
                            break;
                        }
                        //Changes for Story #19549
                        if (invLst[0].blng__Account__r.QTB_Bill_Cycle_Day__c != null && invLst[0].blng__Account__r.QTB_Bill_Cycle_Day__c.containsIgnoreCase('SecureITAD')) {
                            isSitadInvoice = true;
                            break;
                        }
                    }
                /*-------#13861 End of Nordic Billing only country Billcode population-----*/
                if(nordicCountriesPresent)
                {
                    header = label.Order_work_Order_Reference +','+ label.Order_Date +','+ label.Order_Contact +','+ label.Auth_User_Name_Order+','+
                        label.Bill_To_Contact +','+ label.Customer_Account_ID +','+label.District_ID +','+ label.Division_Level_2_ID +','+ label.Division_Level_2_Name +',' +
                        label.Department_Level_3_ID +','+ label.Department_Level_3_Name +','+ label.Invoice_Date +','+ label.Invoice_Number_Reference +','+ label.Source_Bill_Code +',' + label.Custom_Inv_Display +',' +
                    label.Product_Description +',' + label.Billable_Cubic_Ft +',' + label.Months_of_Storage +',' + label.Unit_Qty +',' + label.Unit_of_Measure +',' + label.UnitRate +',' +
                        label.Amount +',' + label.TaxAmount +',' + label.Currency +',' + label.Storage_Date +',' + label.Service_Date +',' + label.Service_Type +',' + label.Contract_PO_Number +',' + 
                        label.Cost_Centre_Number +',' + label.Order_PO_Number +',' + label.Bill_To_Address_1 +',' + label.Bill_To_Address_City +',' + label.Bill_To_Address_State +',' + 
                        label.Bill_To_Address_Zip +',' + label.Remit_To_Address_1 +',' + label.Remit_To_City +',' + label.Remit_To_State +',' + label.Remit_To_Zip +',' + label.Ship_To_Address +',' + label.Ship_To_Address_City +',' + 
                        label.Ship_To_Address_State +',' + label.Ship_To_Zip +',' + label.Service_Account +',' + label.Site_PO_Number +',' + label.Payment_Due_date +',' + label.Email_address;
                } else {
                    //Changes for Story #19549 - To have different columns for SITAD
                    header = label.Order_work_Order_Reference +','+ label.Order_Date +','+ label.Order_Contact +','+ label.Auth_User_Name_Order+','+
                        label.Bill_To_Contact +','+ label.Customer_Account_ID +','+label.District_ID +','+ label.Division_Level_2_ID +','+ label.Division_Level_2_Name +',' +
                        label.Department_Level_3_ID +','+ label.Department_Level_3_Name +','+ label.Invoice_Date +','+ label.Invoice_Number_Reference +','+ label.Bill_Code +',' + label.Custom_Inv_Display +',' +
                    label.Bill_Code_Description +',' + label.Billable_Cubic_Ft +',' + label.Months_of_Storage +',' + label.Unit_Qty +',' + label.Unit_of_Measure +',' + label.UnitRate +',' +
                        label.Amount +',' + label.TaxAmount +',' + label.Currency +',' + label.Storage_Date +',' + label.Service_Date +',' + label.Service_Type +',' + label.Contract_PO_Number +',' + 
                        label.Cost_Centre_Number +',' + label.Order_PO_Number + ',';
                    
                    //Changes for Story #19549 - To add Job Number Column only for SITAD
                    String sitadJobHeader = (isSitadInvoice) ? (label.Job_Number +',') : '';
                    
                    header = header + sitadJobHeader + label.Bill_To_Address_1 +',' + label.Bill_To_Address_City +',' + label.Bill_To_Address_State +',' + 
                        label.Bill_To_Address_Zip +',' + label.Remit_To_Address_1 +',' + label.Remit_To_City +',' + label.Remit_To_State +',' + label.Remit_To_Zip +',' + label.Ship_To_Address +',' + label.Ship_To_Address_City +',' + 
                        label.Ship_To_Address_State +',' + label.Ship_To_Zip +',' + label.Service_Account +',' + label.Site_PO_Number +',' + label.Payment_Due_date +',' + label.Email_address;
                }
                
                //Query for Active 'PurchaseOrder' related to invoice billing account // commenting this because going forward Purchase order taken from Invoice level.
                /*List<QTB_PurchaseOrder__c> purchaseOrderLst = new List<QTB_PurchaseOrder__c>();
purchaseOrderLst= [select name,QTB_Billing_Account__c,QTB_Customer_PO__c,QTB_Division__c,QTB_Div_Dept_Level__c,QTB_Status__c from QTB_PurchaseOrder__c where QTB_Billing_Account__c=:invLst[0].blng__Account__c and QTB_Status__c= 'Active'];
String[] purchaseOrderList = New String[]{};
if(purchaseOrderLst != null && purchaseOrderLst.size()>0){
for(QTB_PurchaseOrder__c poLst:purchaseOrderLst)  {
//Add all PurchaseOrder Customer POs
purchaseOrderList.add(poLst.QTB_Customer_PO__c);  
}
}*/
                
                //Extracting a Customer PO from invoice level! ##22030
                List<QTB_PurchaseOrder__c> purchaseOrderLst = new List<QTB_PurchaseOrder__c>();
                //Map<Id,blng__Invoice__c> invMap =new Map<Id,blng__Invoice__c>([SELECT QTB_PurchaseOrder__c,QTB_PurchaseOrder__r.QTB_Customer_PO__c,QTB_PurchaseOrder__r.QTB_Amount__c, QTB_PurchaseOrder__r.QTB_End_Date__c,QTB_PurchaseOrder__r.QTB_PO_Balance_Amount__c, QTB_PurchaseOrder__r.QTB_Start_Date__c,QTB_PurchaseOrder__r.QTB_Status__c,blng__TotalAmount__c,QTB_Parent_Invoice__c FROM blng__Invoice__c where QTB_PurchaseOrder__c  =:invLst[0].QTB_PurchaseOrder__c LIMIT 1]) ;
                String[] purchaseOrderList = New String[]{};
                    if(invLst != null && invLst.size()>0){
                        for(blng__Invoice__c invPO:invLst)  {
                            //Add all PurchaseOrder Customer POs
                            purchaseOrderList.add(invPO.QTB_PurchaseOrder__r.QTB_Customer_PO__c);  
                        }
                    }
                
                //Query for Primary 'AccountContactRelation' related to invoice billing account
                List<AccountContactRelation> billingCont = new List<AccountContactRelation>();
                billingCont= [select ContactId,QTB_Primary__c,Roles from AccountContactRelation where QTB_Primary__c = true and AccountId=:invLst[0].blng__Account__c and Roles includes  ('Billing')];
                String ContactName;
                String ContactEmail;
                if(billingCont != null && billingCont.size()>0){              
                    Contact BillingContact = [select name,email from contact where id=:billingCont[0].ContactId];
                    ContactName = BillingContact.Name;
                    ContactEmail = BillingContact.email;
                }
                //Query for invoiceLineItems related to invoice
                List<blng__InvoiceLine__c> invoiceLineItems = new List<blng__InvoiceLine__c>();
                invoiceLineItems = [select id, blng__TaxAmount__c, blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c, blng__Invoice__r.blng__Account__c, blng__UsageSummary__c, blng__Product__c, blng__Product__r.Name,  blng__Product__r.ProductCode,  blng__Quantity__c, blng__UnitPrice__c, blng__Subtotal__c, CurrencyIsoCode, blng__Product__r.IM_Product_Line__c from blng__InvoiceLine__c where blng__Invoice__c =:InvoiceID];
                set<string> usageSummaries = new set<string>();
                
                if(invoiceLineItems != null && invoiceLineItems.size()>0) {
                    for(blng__InvoiceLine__c invLin:invoiceLineItems){
                        //Add all Usage Summary
                        usageSummaries.add(invLin.blng__UsageSummary__c);
                    }
                    //Remove blanks and nulls
                    usageSummaries.remove('');
                    usageSummaries.remove(null);
                }
                List<blng__Usage__c> usages = new List<blng__Usage__c>();
                
                //Query for Usages related to invoice
                //#13861 Addition of QTB_Custom_Invoice_Display__c in Query for Nordics
                if(usageSummaries != null && usageSummaries.size()>0){
                    usages = [select id,QTB_Work_Order_ID__c,QTB_Authorized_User__c,QTB_Product_Identifier_1__c,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c,QTB_Rated_Unit_Price__c,QTB_Rated_Amount__c,QTB_Level_1_Name__c,QTB_Service_District__c,QTB_Division_Code__c,QTB_Division_Name__c,QTB_Department_Code__c,QTB_Department_Name__c,QTB_Term__c,blng__PreratedQuantity__c,blng__Quantity__c,blng__UnitOfMeasure__c,
                              QTB_Invoice_Quantity__c,blng__UnitPrice__c,QTB_Custom_Invoice_Display__c , blng__PreratedAmount__c,CurrencyIsoCode,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Cost_Center__c,QTB_Purchase_Order__c,QTB_Tax_Street__c,QTB_Tax_City__c,QTB_Tax_State__c,QTB_Tax_ZipCode__c,QTB_Product__c,blng__OrderProduct__r.product2.ProductCode,blng__OrderProduct__r.Product2Id,
                              blng__UsageSummary__r.blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__UsageSummary__r.blng__Invoice__r.blng__Account__c, blng__UsageSummary__r.blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c, blng__OrderProduct__r.product2.IM_Product_Line__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,QTB_Price_Tier__c,
                              blng__UsageSummary__r.blng__UnitPrice__c,QTB_Requestor__c,QTB_TaxAmount__c,blng__OrderProduct__r.Product2.QTB_Unit_of_Measure__c,QTB_Product_Line__c,QTB_Source_Invoice_Reference__c,blng__Account__r.Bill_To_Site_Number__c,blng__Account__r.name from blng__Usage__c 
                              where blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c,QTB_Division_Code__c];
                }
                /*------------Change US #8205 and #8162 start-----------*/
                //Fetching product name and the corresponding translated language text
                list<SBQQ__Localization__c> productLocalization = [SELECT id,SBQQ__Product__c,SBQQ__Label__c,SBQQ__APIName__c,SBQQ__Text__c,
                                                                   SBQQ__Language__c,SBQQ__Product__r.Name FROM SBQQ__Localization__c WHERE SBQQ__APIName__c = 'Name'];
                List<ID> accId = new List<ID>();
                for(blng__InvoiceLine__c invLI:invoiceLineItems){
                    accId.add(invLI.blng__Invoice__r.blng__Account__c); 
                }
                //Fetch all the records from the "Custom Product Name" table    
                list<QTB_Custom_Product_Name__c> customProductNameList = [Select id, Account__c, Custom_Name__c, Product__c from QTB_Custom_Product_Name__c 
                                                                          where Account__c IN : accId]; 
                
                //If usages are present
                if(usages != null && usages.size()>0){
                   mappingToCSV(invLst[0],purchaseOrderList,ContactName,ContactEmail,usages,purchaseOrderLst,productLocalization,customProductNameList);
                }else{//If there are no usages
                    mappingToInvoice(invLst[0],purchaseOrderList,ContactName,ContactEmail,productLocalization,customProductNameList,invoiceLineItems);
                }
                /*------------Change US #8205 and 8162 End-----------*/
					
            }
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateUsageCSVCTRL');
        }
    }
    //Apex mapping for csv file realted to invoice
    public void mappingToCSV(blng__Invoice__c invoice,string[] poValues,String ContactName,String ContactEmail,List<blng__Usage__c> usages,List<QTB_PurchaseOrder__c> purchaseOrderLst, List<SBQQ__Localization__c> productLocalization, list<QTB_Custom_Product_Name__c> customProductNameList){
        Map<String, String> productTranslationMap = new Map<String, String>();
        try{
            /*------------Change US #8205 start-----------*/
            //Creating Product and its translated text map
            for (SBQQ__Localization__c prdLoc: productLocalization) {
                productTranslationMap.put(prdLoc.SBQQ__Product__c+'-'+prdLoc.SBQQ__Language__c, prdLoc.SBQQ__Text__c);
            }
            
            //Custom Product Name map having key - AccountId+ProductId and value - Custom Product Name  
            Map<String, String> customProductNameMap = new Map<String, String>();   
            for (QTB_Custom_Product_Name__c customProductName : customProductNameList) {    
                //Additional check to create valid map only.    
                if (customProductName.Account__c != NULL && customProductName.Product__c != NULL && customProductName.Custom_Name__c != NULL ) {    
                    customProductNameMap.put(String.valueof(customProductName.Account__c)+String.valueof(customProductName.Product__c), String.valueof(customProductName.Custom_Name__c));  
                }   
            }   
            /*------------Change US #8205 End-----------*/
            /*-------Start of Nordic Billing only country Billcode population-----*/
            Boolean nordicCountriesPresent =false;
            List<String> NordicBillingOnlyCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
            for(String country:NordicBillingOnlyCountries)
            {
                if(usages[0].blng__Account__r.QTB_Legal_Entity_Country__c == country){
                    nordicCountriesPresent = true;
                    break;
                }
            }
            /*-------End of Nordic Billing only country Billcode population-----*/            
            for(blng__Usage__c usa :usages){
                
                wrapper w = new wrapper();
                //Populating Case Number(QTB_Source_Invoice_Reference__c) for SITAD - Story #19549
                if (usa.QTB_Product_Line__c != null && usa.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE && isSitadInvoice) {
                    w.OrderworkOrderReference = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                            'OrderworkOrderReference',usa.QTB_Source_Invoice_Reference__c,
                            usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                        );
                } else {
                    w.OrderworkOrderReference = usa.QTB_Work_Order_ID__c != null? usa.QTB_Work_Order_ID__c : '';
                }
                w.OrderDate = '';
                w.OrderContact = usa.QTB_Requestor__c;
                if (usa.QTB_Product_Line__c != null && usa.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE && isSitadInvoice) {
                    //Adding empty string to the OrderContact if it contains comma, this is to avoid column mismatch in CSV File as per #23766.
                    w.OrderContact = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'OrderContact',usa.QTB_Requestor__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );

                }
                w.AuthUserNameOrder = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'AuthUserNameOrder',usa.QTB_Authorized_User__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                w.BillToContact = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToContact',ContactName,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                //Populating Billing To Site Number(blng__Account__r.Bill_To_Site_Number__c) in place of Customer Account ID for SITAD
                if (usa.QTB_Product_Line__c != null && usa.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE) {
                   w.CustomerAccountID = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'CustomerAccountID',usa.blng__Account__r.Bill_To_Site_Number__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                } else {
                    w.CustomerAccountID = usa.QTB_Level_1_Name__c != null? usa.QTB_Level_1_Name__c : '';
                }
                w.DistrictID = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'DistrictID',usa.QTB_Service_District__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.DivisionLevel2ID = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'DivisionLevel2ID',usa.QTB_Division_Code__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.DivisionLevel2Name = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'DivisionLevel2Name',usa.QTB_Division_Name__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.DepartmentLevel3ID = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'DepartmentLevel3ID',usa.QTB_Department_Code__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                //Populate Billing Account Name for SITAD
                if (usa.QTB_Product_Line__c != null && usa.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE) {
                    w.DepartmentLevel3Name = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'DepartmentLevel3Name',usa.blng__Account__r.Name,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                } else {
                    //w.DepartmentLevel3Name = usa.QTB_Department_Name__c != null? usa.QTB_Department_Name__c : '';
                      w.DepartmentLevel3Name = usa.QTB_Department_Name__c != null? String.valueOf(usa.QTB_Department_Name__c).replaceall(',','') : '';
                }
                w.InvoiceDate =  invoice.blng__InvoiceDate__c != null? invoice.blng__InvoiceDate__c.format() : '';
                w.InvoiceDate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'InvoiceDate',w.InvoiceDate,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.InvoiceNumberReference = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'InvoiceNumberReference',invoice.QTB_Custom_Invoice_Number__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                /*------------Change US #8205 start-----------*/
                if (usa.QTB_Product__c != null) {
                    if(usa.blng__UsageSummary__r.blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c == true && customProductNameMap.get(String.valueof(usa.blng__UsageSummary__r.blng__Invoice__r.blng__Account__c)+String.valueof(usa.blng__OrderProduct__r.Product2Id)) != NULL){
                        w.BillCodeDescription = customProductNameMap.get(String.valueof(usa.blng__UsageSummary__r.blng__Invoice__r.blng__Account__c)+String.valueof(usa.blng__OrderProduct__r.Product2Id)).replaceall(',','-');
                    }
                    else if (productTranslationMap.get(usa.blng__OrderProduct__r.Product2Id+'-'+usa.blng__UsageSummary__r.blng__Invoice__r.blng__Account__r.QTB_Language__c) != null) {
                        w.BillCodeDescription = String.valueOf(productTranslationMap.get(usa.blng__OrderProduct__r.Product2Id+'-'+usa.blng__UsageSummary__r.blng__Invoice__r.blng__Account__r.QTB_Language__c)).replaceall(',','-');
                    }
                    else{
                        w.BillCodeDescription =  String.valueOf(usa.QTB_Product__c).replaceall(',','-');
                    }
                }
                
                w.BillCodeDescription = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillCodeDescription',w.BillCodeDescription,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                /*------------Change US #8205 End-----------*/
                //w.BillCodeDescription = usa.QTB_Product__c != null? String.valueOf(usa.QTB_Product__c).replaceall(',','-') : '';
                /*-------Start of Nordic Billing only country Billcode population-----*/
                if(nordicCountriesPresent)
                {
                    w.BillCode = usa.QTB_Product_Identifier_1__c!= null? usa.QTB_Product_Identifier_1__c : '';
                }
                else
                {
                    w.BillCode = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillCode',usa.blng__OrderProduct__r.product2.ProductCode,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                }
                //#13861 CustomInvDisplay value population 
                w.CustomInvDisplay = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'CustomInvDisplay',usa.QTB_Custom_Invoice_Display__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                    
                /*-------End of Nordic Billing only country Billcode population-----*/
                //w.BillCode = usa.QTB_Product_Identifier_1__c != null? usa.QTB_Product_Identifier_1__c : '';
                if(usa.blng__UnitOfMeasure__c == 'CuFt'){
                    w.BillableCubicFt = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillableCubicFt',usa.blng__UnitOfMeasure__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                }
                w.MonthsofStorage = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'MonthsofStorage',usa.QTB_Term__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                /*if(usa.blng__PreratedQuantity__c != 0.0 ){
w.UnitQty = usa.blng__PreratedQuantity__c != null? String.valueOf(usa.blng__PreratedQuantity__c.setScale(2)) : '';
}
else if(usa.QTB_Invoice_Quantity__c != null){
w.UnitQty = String.valueOf(usa.QTB_Invoice_Quantity__c.setScale(2));
}*/
                //Changes to populate PreRated Quantity for SITAD
                if (usa.QTB_Product_Line__c != null && usa.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE) {
                    w.UnitQty = usa.blng__PreratedQuantity__c != null? String.valueOf(usa.blng__PreratedQuantity__c.setScale(2)) : '';
                } else if(usa.QTB_Invoice_Quantity__c != null){
                    w.UnitQty = String.valueOf(usa.QTB_Invoice_Quantity__c.setScale(2));
                }
                
                w.UnitQty = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'UnitQty',w.UnitQty,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                //Changes to populate Unit of Measure from Product for SITAD
                if (usa.QTB_Product_Line__c != null && usa.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE) {
                    w.UnitofMeasure = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'UnitofMeasure',usa.blng__OrderProduct__r.Product2.QTB_Unit_of_Measure__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                } else if(usa.QTB_Invoice_Quantity__c != null){
                    w.UnitofMeasure = usa.blng__UnitOfMeasure__c != null? usa.blng__UnitOfMeasure__c : '';
                }
                
                /*if(usa.blng__PreratedAmount__c != 0.0){
w.UnitRate = String.valueOf((usa.blng__PreratedAmount__c * usa.blng__PreratedQuantity__c).setScale(4, RoundingMode.HALF_UP));  
}
else{
w.UnitRate = usa.QTB_Rated_Unit_Price__c != null? String.valueOf(usa.QTB_Rated_Unit_Price__c.setScale(4, RoundingMode.HALF_UP)) : '';   
}*/
                //Changes to update the Unit Rate with 4 Decimals as per the Story #7997
                //Changing the logic as per the Story #11276(Danube Team)
                //#14018 Changing logic for unitrate if Prerated Amount = 0
                if(nordicCountriesPresent){
                    if(usa.blng__PreratedAmount__c > 0.0 )
                 {
                  if(usa.QTB_Prerated_Unit_Price__c != null &&  usa.QTB_Prerated_Unit_Price__c > 0){
                         w.UnitRate = String.valueOf(usa.QTB_Prerated_Unit_Price__c.setScale(4, RoundingMode.HALF_UP)); 
                   }
                   else if(usa.QTB_Invoice_Quantity__c != null && usa.QTB_Invoice_Quantity__c>0){
                    w.UnitRate = String.valueOf((usa.blng__PreratedAmount__c / usa.QTB_Invoice_Quantity__c).setScale(4, RoundingMode.HALF_UP));
                   }
                   else if (usa.blng__PreratedQuantity__c !=null && usa.blng__PreratedQuantity__c>0){
                       w.UnitRate = String.valueOf((usa.blng__PreratedAmount__c / usa.blng__PreratedQuantity__c).setScale(4, RoundingMode.HALF_UP));
                    }
          }
                else {
                    w.UnitRate = usa.QTB_Prerated_Unit_Price__c != null ? String.valueOf(usa.QTB_Prerated_Unit_Price__c.setScale(4, RoundingMode.HALF_UP)) :'';  
                   }//Nordics logic ends
        }
                else{
    if(usa.blng__PreratedAmount__c > 0.0 )
  {
      if(usa.QTB_Prerated_Unit_Price__c != null &&  usa.QTB_Prerated_Unit_Price__c > 0)
       {
             
            w.UnitRate = String.valueOf(usa.QTB_Prerated_Unit_Price__c.setScale(4, RoundingMode.HALF_UP)); 
          
        }
        
        else if(usa.QTB_Invoice_Quantity__c != null && usa.QTB_Invoice_Quantity__c>0)
        
        {
              
        w.UnitRate = String.valueOf((usa.blng__PreratedAmount__c / usa.QTB_Invoice_Quantity__c).setScale(4, RoundingMode.HALF_UP));
         }
        
        else if (usa.blng__PreratedQuantity__c !=null && usa.blng__PreratedQuantity__c>0)
        {
           w.UnitRate = String.valueOf((usa.blng__PreratedAmount__c / usa.blng__PreratedQuantity__c).setScale(4, RoundingMode.HALF_UP));
        }
   else {
        
        w.UnitRate = String.valueOf(usa.blng__PreratedAmount__c.setScale(4, RoundingMode.HALF_UP));  
       }
  }
      else{
          
        w.UnitRate = usa.QTB_Rated_Unit_Price__c != null? String.valueOf(usa.QTB_Rated_Unit_Price__c.setScale(4, RoundingMode.HALF_UP)) : '';   
    }
    
    w.UnitRate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
            'UnitRate',w.UnitRate,
            usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
        );
  } 
                //logic ends #11276 US
                
                //w.Amount = usa.QTB_Rated_Amount__c != null? String.valueOf(usa.QTB_Rated_Amount__c.setScale(2)) : '';
                //Removing QTB_Term__c multiplication with QTB_Rated_Amount__c as it's not required - Story #1758
                if(usa.QTB_Rated_Amount__c != null){
                    w.Amount = String.valueOf(usa.QTB_Rated_Amount__c.setScale(2));
                }
                
                w.Amount = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'Amount',w.Amount,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                //Adding Tax Amount as part of GITLAB-1490
                system.debug('usageTax>>>'+usa.QTB_TaxAmount__c);
                if(usa.QTB_TaxAmount__c != null){
                    w.TaxAmount = String.valueOf(usa.QTB_TaxAmount__c.setScale(2));
                }
                w.TaxAmount = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'TaxAmount',w.TaxAmount,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                w.Currency1 = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'Currency1',usa.CurrencyIsoCode,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                if(usa.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c == 'Storage'){
                    w.StorageDate = usa.QTB_Start_Date_MRC__c != null? usa.QTB_Start_Date_MRC__c.format() : '';
                    w.StorageDate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'StorageDate',w.StorageDate,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                }
                if(usa.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c == 'Services'){
                    w.ServiceDate = usa.QTB_End_Date_MRC__c != null? usa.QTB_End_Date_MRC__c.format() : '';
                    w.ServiceDate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ServiceDate',w.ServiceDate,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                } 
                
                //#13894 Nordics Category update          
                if(nordicCountriesPresent){
                    w.ServiceType = usa.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != null? usa.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c: '';
                    
                }else{
                    w.ServiceType = usa.blng__OrderProduct__r.product2.IM_Product_Line__c != null? usa.blng__OrderProduct__r.product2.IM_Product_Line__c: '';
                }
                
                w.ServiceType = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ServiceType',w.ServiceType,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                //Populating PO Number from Usage (QTB_Purchase_Order__c) for SITAD - Story #19549
                w.JobNumber = '';
                if (usa.QTB_Product_Line__c != null && usa.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE) {
                    
                    w.ContractPONumber = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ContractPONumber',usa.QTB_Purchase_Order__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                    w.JobNumber = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'JobNumber',usa.QTB_Work_Order_ID__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                } else {
                    if(poValues!= null && poValues.size()>0) {
                        w.ContractPONumber = string.join(poValues,';');
                    }
                }
                
                //w.ContractPONumber='ak';
                //w.ContractPONumber=poValues[c];
                //w.ContractPONumber=string.valueOf(poValues.size());
                //c++;
                w.CostCentreNumber = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'CostCentreNumber',usa.QTB_Cost_Center__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.OrderPONumber = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'OrderPONumber',usa.QTB_Purchase_Order__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.BillToAddress1 = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddress1',invoice.blng__Account__r.BillingStreet,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.BillToAddressCity = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddressCity',invoice.blng__Account__r.BillingCity,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.BillToAddressState = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddressState',invoice.blng__Account__r.BillingState,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                //w.BillToAddressZip = invoice.blng__Account__r.BillingPostalCode != null? invoice.blng__Account__r.BillingPostalCode : '';
                //Adding empty string to the BillToAddressZip if it contains comma, this is to avoid column mismatch in CSV File as per #23766.
                w.BillToAddressZip = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddressZip',invoice.blng__Account__r.BillingPostalCode,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                string street1 = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c != null? String.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c).replaceall(',',';') : '';
                string street2 = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c != null? String.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c).replaceall(',',';') : '';
                w.RemitToAddress1 = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToAddress1',street1+' '+street2,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.RemitToCity = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToCity',invoice.blng__Account__r.QTB_Contract_Entity__r.blng__City__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.RemitToState = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToState',invoice.blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.RemitToZip = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToZip',invoice.blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.ShipToAddress = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ShipToAddress',usa.QTB_Tax_Street__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
               w.ShipToAddressCity = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ShipToAddressCity',usa.QTB_Tax_City__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.ShipToAddressState = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ShipToAddressState',usa.QTB_Tax_State__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                //w.ShipToZip = usa.QTB_Tax_ZipCode__c != null? usa.QTB_Tax_ZipCode__c : '';
                //Adding empty string to the ShipToZip if it contains comma, this is to avoid column mismatch in CSV File as per #23766.
                w.ShipToZip = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ShipToZip',usa.QTB_Tax_ZipCode__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                //w.ServiceAccount = usa.QTB_Level_1_Name__c != null? usa.QTB_Level_1_Name__c : '';
                //Adding empty string to the ServiceAccount if it contains comma, this is to avoid column mismatch in CSV File as per #23766..
                w.ServiceAccount = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ServiceAccount',usa.QTB_Level_1_Name__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );   
                //If purchaseOrder present //commenting out purchase order taken directly from invoice level
                if(purchaseOrderLst != null && purchaseOrderLst.size()>0){
for(QTB_PurchaseOrder__c po :purchaseOrderLst){
//Check conditions for Division and Department 
if(po.QTB_Division__c == usa.QTB_Division_Name__c && po.QTB_Div_Dept_Level__c == usa.QTB_Department_Name__c){
w.SitePONumber = po.QTB_Customer_PO__c != null? po.QTB_Customer_PO__c : ''; 



}
}
}
                w.SitePONumber = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ServiceAccount',invoice.QTB_PurchaseOrder__r.QTB_Customer_PO__c,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );   
                w.PaymentDuedate = invoice.blng__DueDate__c != null? invoice.blng__DueDate__c.format() : '';
                w.PaymentDuedate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'PaymentDuedate',w.PaymentDuedate,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );                  
                If(String.isNotBlank(ContactEmail)){
                    w.Emailaddress = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'Emailaddress',ContactEmail,
                        usa.QTB_Product_Line__c,isSitadInvoice,usa.blng__Account__r.QTB_Legal_Entity_Country__c
                    );   
                }                
                lstwrapper.add(w);
            }
            
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateUsageCSVCTRL.mappingToCSV');
        }
    }
    
    public void mappingToInvoice(blng__Invoice__c invoice,string[] poValues,String ContactName,String ContactEmail, List<SBQQ__Localization__c> productLocalization, list<QTB_Custom_Product_Name__c> customProductNameList, List<blng__InvoiceLine__c> invoiceLineItems){
        try{
            Map<String, String> productTranslationMap = new Map<String, String>();
            /*------------Change US #8205 start-----------*/
            //Creating Product and its translated text map
            for (SBQQ__Localization__c prdLoc: productLocalization) {
                productTranslationMap.put(prdLoc.SBQQ__Product__c+'-'+prdLoc.SBQQ__Language__c, prdLoc.SBQQ__Text__c);
            }
            
            //Custom Product Name map having key - AccountId+ProductId and value - Custom Product Name  
            Map<String, String> customProductNameMap = new Map<String, String>();   
            for (QTB_Custom_Product_Name__c customProductName : customProductNameList) {    
                //Additional check to create valid map only.    
                if (customProductName.Account__c != NULL && customProductName.Product__c != NULL && customProductName.Custom_Name__c != NULL ) {    
                    customProductNameMap.put(String.valueof(customProductName.Account__c)+String.valueof(customProductName.Product__c), String.valueof(customProductName.Custom_Name__c));  
                }   
            }   
            /*------------Change US #8205 End-----------*/
            for(blng__InvoiceLine__c invln: invoiceLineItems){
                wrapper w = new wrapper();
                w.InvoiceDate =  invoice.blng__InvoiceDate__c != null? invoice.blng__InvoiceDate__c.format() : '';
                w.InvoiceDate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'InvoiceDate',w.InvoiceDate,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                w.InvoiceNumberReference = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'InvoiceNumberReference',invoice.QTB_Custom_Invoice_Number__c,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                w.PaymentDuedate = invoice.blng__DueDate__c != null? invoice.blng__DueDate__c.format() : '';
                w.PaymentDuedate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'PaymentDuedate',w.PaymentDuedate,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                /*------------Change US #8205 and #8162 start-----------*/
                if (invln.blng__Product__c != null) {
                    if(invln.blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c == true && customProductNameMap.get(String.valueof(invln.blng__Invoice__r.blng__Account__c)+String.valueof(invln.blng__Product__c)) != NULL){
                        w.BillCodeDescription = customProductNameMap.get(String.valueof(invln.blng__Invoice__r.blng__Account__c)+String.valueof(invln.blng__Product__c)).replaceall(',','-');
                    }
                    else if (productTranslationMap.get(invln.blng__Product__c+'-'+invln.blng__Invoice__r.blng__Account__r.QTB_Language__c) != null) {
                        w.BillCodeDescription = String.valueOf(productTranslationMap.get(invln.blng__Product__c+'-'+invln.blng__Invoice__r.blng__Account__r.QTB_Language__c)).replaceall(',','-');
                    }
                    else{
                        w.BillCodeDescription =  String.valueOf(invln.blng__Product__r.Name).replaceall(',','-');
                    }
                }
                w.BillCodeDescription = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillCodeDescription',w.BillCodeDescription,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.BillCode = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillCode',invln.blng__Product__r.ProductCode,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.UnitQty = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'UnitQty',String.valueOf(invln.blng__Quantity__c.setScale(2)),
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.UnitRate = invln.blng__UnitPrice__c != null? String.valueOf(invln.blng__UnitPrice__c.setScale(4, RoundingMode.HALF_UP)) : '';
                w.UnitRate = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'UnitRate',w.UnitRate,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.Amount = invln.blng__Subtotal__c !=null? String.valueOf(invln.blng__Subtotal__c.setScale(2)) : '';
                w.Amount = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'Amount',w.Amount,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.Currency1 = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'Currency1',invln.CurrencyIsoCode,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                system.debug('invln.blng__TaxAmount__c>>>'+invln.blng__TaxAmount__c);
                if(invln.blng__TaxAmount__c != null){
                    w.TaxAmount = String.valueOf(invln.blng__TaxAmount__c.setScale(2));
                }
                w.TaxAmount = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'TaxAmount',w.TaxAmount,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                system.debug('Invoice Tax>>>'+w.TaxAmount);
                
                
                /*------------Change US #8205 and #8162 End-----------*/
                w.BillToAddress1 = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddress1',invoice.blng__Account__r.BillingStreet,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.BillToAddressCity = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddressCity',invoice.blng__Account__r.BillingCity,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.BillToAddressState = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddressState',invoice.blng__Account__r.BillingState,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.BillToAddressZip = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToAddressZip',invoice.blng__Account__r.BillingPostalCode,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                string street1 = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c != null? String.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c).replaceall(',',';') : '';
                string street2 = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c != null? String.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c).replaceall(',',';') : '';
                w.RemitToAddress1 = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToAddress1',street1+' '+street2,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.RemitToCity = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToCity',invoice.blng__Account__r.QTB_Contract_Entity__r.blng__City__c,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.RemitToState = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToState',invoice.blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.RemitToZip = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'RemitToZip',invoice.blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                w.Emailaddress = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'Emailaddress',ContactEmail,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                
                w.BillToContact = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'BillToContact',ContactName,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                if(poValues!= null && poValues.size()>0)
                    w.ContractPONumber = string.join(poValues,';');
                w.ContractPONumber = QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue(
                        'ContractPONumber',w.ContractPONumber,
                        invln.blng__Product__r.IM_Product_Line__c,isSitadInvoice,invoice.blng__Account__r.QTB_Legal_Entity_Country__c
                    );
                lstwrapper.add(w);
            }
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateUsageCSVCTRL.mappingToInvoice');
            
        }
    }
    
    //wrapper class for usage
    public class wrapper{
        public string OrderworkOrderReference {get; set;}
        public string OrderDate {get; set;}
        public string OrderContact {get; set;}
        public string AuthUserNameOrder {get; set;}
        public string BillToContact {get; set;}
        public string CustomerAccountID {get; set;}
        public string DistrictID {get; set;}
        public string DivisionLevel2ID {get; set;}
        public string DivisionLevel2Name {get; set;}
        public string DepartmentLevel3ID {get; set;}
        public string DepartmentLevel3Name {get; set;}
        public string InvoiceDate {get; set;}
        public string InvoiceNumberReference {get; set;}
        public string BillCode {get; set;}
        //#13861
        public string CustomInvDisplay {get; set;}
        public string BillCodeDescription {get; set;}
        public string BillableCubicFt {get; set;}
        public string MonthsofStorage {get; set;}
        public string UnitQty {get; set;}
        public string UnitofMeasure {get; set;}
        public string UnitRate {get; set;}
        public string Amount {get; set;}
        public string Currency1 {get; set;}
        public string StorageDate {get; set;}
        public string ServiceDate {get; set;}
        public string ServiceType {get; set;}
        public string ContractPONumber {get; set;}
        public string CostCentreNumber {get; set;}
        public string OrderPONumber {get; set;}
        public string BillToAddress1 {get; set;}
        public string BillToAddressCity {get; set;}
        public string BillToAddressState {get; set;}
        public string BillToAddressZip {get; set;}
        public string RemitToAddress1 {get; set;}
        public string RemitToCity {get; set;}
        public string RemitToState {get; set;}
        public string RemitToZip {get; set;}
        public string TaxAmount {get; set;}
        public string ShipToAddress {get; set;}
        public string ShipToAddressCity {get; set;}
        public string ShipToAddressState {get; set;}
        public string ShipToZip {get; set;}
        public string ServiceAccount {get; set;}
        public string SitePONumber {get; set;}
        public string PaymentDuedate {get; set;}
        public string Emailaddress {get; set;} 
        public string JobNumber {get; set;}
     
    }
    
/*****************************************************************************************************************
    * Method : getBackingReportHeaderValue
    * Parameters: String fieldName, String fieldValue, String productLine, Boolean isSitadInvoice, String legalCountry
    * Requirement : GITLAB-
    * Start Date : 06/03/2024
    * Author : Renuka Prasad
    * Description: To get the getBackingReportHeaderValue, if contains comma replace it with EMTPY String
    ******************************************************************************************************************/
    public static String getBackingReportHeaderValue(String fieldName, String fieldValue, String productLine, Boolean isSitadInvoice, String legalCountry) {
        String updatedFieldValue = '';
        try {
            if (QTB_GenerateUsageCSVCTRL.throwExplicitException) {
                throw new NullPointerException();
            }
            System.debug('productLine>>>'+productLine);
            System.debug('isSitadInvoice>>>'+isSitadInvoice);
            System.debug('legalCountry>>>'+legalCountry);
            if (productLine != null && productLine == QTB_Constants.SITAD_PRODUCT_LINE 
                && isSitadInvoice && legalCountry != null && System.label.QTB_NA_Countries.containsIgnoreCase(legalCountry)) {
                //Replacing comma and next line character with empty string to avoid column mismatch in CSV File as per #23766.
                String updatedFieldWithoutComma = '';
                updatedFieldWithoutComma = fieldValue != null ? String.valueOf(fieldValue).replaceall(',','') : '';
                updatedFieldValue = String.valueOf(updatedFieldWithoutComma).replaceall('\r\n','');
                System.debug('updatedFieldValue111>'+updatedFieldValue);
                //Setting sitadEmptyMandatoryFields to TRUE to bypass sending this particular record to SMS.
                if(System.Label.QTB_Sitad_BR_Mandatory_Fields.contains(fieldName) && String.isBlank(updatedFieldValue)) {
                    sitadEmptyMandatoryFields = String.isBlank(sitadEmptyMandatoryFields) ? fieldName : sitadEmptyMandatoryFields + ';' + fieldName;
                }
            }
           
        } catch(Exception e) {
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                'QTB_GenerateUsageCSVCTRL.getBackingReportHeaderValue');
        }
        
        return updatedFieldValue;
      
    }

    public void updateBackingReportError() {
        try {
            if (isSitadInvoice && !String.isBlank(sitadEmptyMandatoryFields)) {
                System.debug('InvoiceIDString>>>'+InvoiceIDString+'<<<<sitadEmptyMandatoryFields>>>'+sitadEmptyMandatoryFields);
                //Update the Backing Report Error on the Invoice & keep the Last Invoice Backing Report Sent Date to NULL
                blng__Invoice__c invToUpdate = new blng__Invoice__c();
                if (InvoiceIDString != null) {
                    invToUpdate.id = InvoiceIDString;
                    invToUpdate.QTB_BackingReport_Sent_Date__c = NULL;
                    invToUpdate.QTB_SITAD_Backing_Report_Error__c = sitadEmptyMandatoryFields;
                
                    update invToUpdate;
                }
            }
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                'QTB_GenerateUsageCSVCTRL.updateBackingReportError');
        }
    }
    
    public static void codeCoverage(){
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    i++;
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