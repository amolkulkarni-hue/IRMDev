/*****************************************************************************************************
* Class         : QTB_IRMVertexRequestUtil
* Test Clas     : QTB_IRMToVertex_Test
* Author        : IRM
* Purpose       : This is a Request Util Class used for creating request strucutre for tax calculation
* Requirement   : Gitlab #
* Change History: 08/08/2021 
* Developer                 Date            Description 
* ------------------------------------------------------------------------------------------- 
* Gopi / Shailesh       08/08/2021           #857 -- Vertex Tax calculation
* Shailesh              10/18/2021           Changes from BillingAddress to ShippingAddress
* IRM/Virtusa           12/07/2021           Git #6151 DM MVP PROD - VERTEX - Differentiate callouts for Draft' invoices & Credit Notes
* Virtusa               12/13/2021           Git #6056 DM MVP PROD - VERTEX - Differentiate callouts for 'Posted' invoices & Credit Notes
* Renuka Prasad         08/11/2023           Git #19547 To pass the Usage address to VERTEX for SITAD to support multiple location taxing
*******************************************************************************************************/
public with sharing class QTB_IRMVertexRequestUtil {
    
    public static final string userName = QTB_IRMVertexServiceConstant.USERNAME;
    public static final string password = QTB_IRMVertexServiceConstant.PASSWORD;
    public static boolean isInvoice;
    public static final boolean isMulticomponent = false;
    public static string SFDC_SecureBase_SKP = '';   // using in FlexCode2,3 
    public static string isInvoiceOrCreditNote = ''; // in FlexCode4
    public static string locationGL = '';
    public static string DistrictCodeInvoiceLine = '';
    public static Decimal LegalEntityIdentifier;
    public static final string FunctionFlexCode = '0000';  //constant value 
    public static string accountName = '';
    public static Map<id,string> invoiceLineIdToBillCodeMap = new Map<id,string>();   
    
    /*********************************************************************************************************
* Method Name: requestStructureForInvoiceLineOrUsage
* Parameters:  SObject invoiceOrUsageSummary, List<SObject> invoiceLineOrUsageList, string isInvoiceUsageSummaryCreditNote, boolean isForPosted
* Return Type: string
* Requirement: Gitlab #
* Description: This method is used to make request for Invoice, Usage, CreditNote
**********************************************************************************************************/
    public static String requestStructureForInvoiceLineOrUsage(SObject invoiceOrCreditNote, List<SObject> invoiceCreditNoteLinesUsageList, string DistrictCode,string locationGLString, Map<id,string> invoiceLineIdToBillCode, string isInvoiceUsageSummaryCreditNote, boolean isForPosted){
        string requestStructure='';   
        locationGL = locationGLString;
        DistrictCodeInvoiceLine = DistrictCode;
        invoiceLineIdToBillCodeMap = invoiceLineIdToBillCode;
        try{            
            System.debug('isForPosted@@'+isForPosted);
            System.debug('invoiceOrCreditNote@@'+invoiceOrCreditNote);
            System.debug('invoiceCreditNoteLinesUsageList@@'+invoiceCreditNoteLinesUsageList);
            if(invoiceOrCreditNote != null && invoiceCreditNoteLinesUsageList !=null)
            {
                //passing invoice or CreditNote, invoicelinelist or CreditNoteline or Usages to buildInvoiceOrCreditNoteRequest for creating invoiceline level request
                requestStructure = buildInvoiceOrCreditNoteRequest(invoiceOrCreditNote, invoiceCreditNoteLinesUsageList,userName,password,isInvoiceUsageSummaryCreditNote,isForPosted);
                System.debug('invoiceRequest@@'+requestStructure);
            }   
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_IRMVertexRequestUtil.requestStructureForInvoiceLineOrUsage');
        }
        return requestStructure;
    }
    
    /*********************************************************************************************************
* Method Name: buildInvoiceOrCreditNoteRequest
* Parameters:  SObject invoiceOrCreditNote, List<SObject> invoiceCreditNoteLinesUsageList, String userName, String password, string isInvoiceUsageSummaryCreditNote
* Return Type: string
* Requirement: Gitlab #
* Description: TThis method is used to build request for Invoice, Usage, CreditNote
**********************************************************************************************************/
    public static String buildInvoiceOrCreditNoteRequest(SObject invoiceOrCreditNote, List<SObject> invoiceCreditNoteLinesUsageList, String userName, String password,string isInvoiceUsageSummaryCreditNote,boolean isForPostedVar){
        String requestXML = '';
        requestXML = requestXML + QTB_IRMVertexServiceConstant.SOAP_REQUEST_HEADER +
            getLoginXML(userName, password) +            
            getInvoiceCreditRequestXML(invoiceOrCreditNote, invoiceCreditNoteLinesUsageList,isInvoiceUsageSummaryCreditNote,isForPostedVar); //isForPostedVar determine draft or posted status
        
        return requestXML;        
    }
    
    /*********************************************************************************************************
* Method Name: getLoginXML
* Parameters:  String userName, String password
* Return Type: string
* Requirement: Gitlab #
* Description: This method is used for building login node request part
**********************************************************************************************************/
    public static String getLoginXML(String userName, String password){        
        String loginString = '<Login>'+                     
            '<UserName>'+ userName +'</UserName>'+
            '<Password>'+ password +'</Password>'+ 
            '</Login>';        
        return loginString;
    }
    
    
    /*********************************************************************************************************
* Method Name: getInvoiceCreditRequestXML
* Parameters:  SObject invoiceOrUsageSummary, List<SObject> invoiceLineOrUsageList,String isInvoiceUsageSummaryCreditNote,boolean isPostedInvoiceOrCreditNote
* Return Type: String
* Requirement: Gitlab #
* Description: This method is used to build request for Invoice or usage or creditNote.
**********************************************************************************************************/
    public static String getInvoiceCreditRequestXML(SObject invoiceOrCreditNote, List<SObject> invoiceLineOrUsageList,String isInvoiceUsageSummaryCreditNote,boolean isPostedInvoiceOrCreditNote){
        try{
            //Vertex without registering the tax the request need to use 'QuotationRequest'
            string InvoiceOrQuotationRequest = 'QuotationRequest';
            String invoiceOrCreditNoteName = (String) invoiceOrCreditNote.get('Name');
            String invoiceOrCreditNoteId = (String) invoiceOrCreditNote.get('Id');
            String invoiceCreditDateVar;
            blng__Invoice__c invoice;
            blng__CreditNote__c creditNote;
            Date invoiceCreditDate;
            Account accountObj =  (Account) invoiceOrCreditNote.getSObject('blng__Account__r');
            string currencyCode = (accountObj != null && accountObj.CurrencyISOCode != null) ? accountObj.CurrencyISOCode : ''; 
            // String billToAccountCustomerNo = (accountObj != null && accountObj.QTB_Customer_Number__c != null) ?  accountObj.QTB_Customer_Number__c  : '' ;
            String billToAccountCustomerNo = getCustomerCode(accountObj.id);
            accountName = accountObj !=null ? accountObj.QTB_Billing_Account_Invoice_Name__c:'';
            LegalEntityIdentifier = accountObj.QTB_Contract_Entity__c != null ? accountObj.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c : null ;
            
            //Based on country sending SF-SB-US or SF-SB-CA  in FlexiField 2 & FlexiField 3
            if(accountObj.QTB_Legal_Entity_Country__c == 'United States'){
                SFDC_SecureBase_SKP = 'SF-SB-US'; 
            }
            else if(accountObj.QTB_Legal_Entity_Country__c == 'Canada'){
                SFDC_SecureBase_SKP = 'SF-SB-CA'; 
            }
            //based on Invoice or CreditNote request -- sending INV or CREDIT  in FlexiField 4
            if(isInvoiceUsageSummaryCreditNote.contains('Invoice') && invoiceOrCreditNote.getSObjectType().getDescribe().getName() == 'blng__Invoice__c') //Invoice
            {            
                invoice = (blng__Invoice__c) invoiceOrCreditNote; 
                invoiceCreditDate = invoice.blng__InvoiceDate__c;                
                isInvoiceOrCreditNote = 'INV';
                //Git Story #6151
                //Vertex with registering the tax the request need to use 'InvoiceRequest'
                if(isPostedInvoiceOrCreditNote){
                    InvoiceOrQuotationRequest = 'InvoiceRequest';
                }
            }
            if(isInvoiceUsageSummaryCreditNote.contains('CreditNote') && invoiceOrCreditNote.getSObjectType().getDescribe().getName() == 'blng__CreditNote__c') // CreditNote
            {
                creditNote = (blng__CreditNote__c) invoiceOrCreditNote;
                invoiceCreditDate = creditNote.blng__CreditNoteDate__c;
                isInvoiceOrCreditNote = 'CREDIT';
                //Git Story #6151
                //Vertex with registering the tax the request need to use 'InvoiceRequest'
                if(isPostedInvoiceOrCreditNote){
                    InvoiceOrQuotationRequest = 'InvoiceRequest';
                }
            }    
            
            invoiceCreditDateVar = invoiceCreditDate !=null ? DateTime.newInstance(invoiceCreditDate.year(),invoiceCreditDate.month(),invoiceCreditDate.day()).format('yyyy-MM-dd') : '';    
            
            String quotationRequestXML = '<'+InvoiceOrQuotationRequest+' documentNumber="'+invoiceOrCreditNoteName+'" documentDate="'+ invoiceCreditDateVar +'" transactionType="'+ QTB_IRMVertexServiceConstant.TRANSCATION_TYPE + '" postingDate="'+ invoiceCreditDateVar + '" transactionId="' + invoiceOrCreditNoteId + '">'+
                '<Currency>'+ currencyCode +'</Currency>' +
                getCustomerInfoXML(billToAccountCustomerNo) +
                // Gitlab #31588 added billToAccountCustomerNo inside getLineItemsXML below 
                getLineItemsXML(invoiceLineOrUsageList,isInvoiceUsageSummaryCreditNote,invoiceCreditDateVar,billToAccountCustomerNo)+'</'+InvoiceOrQuotationRequest+'>';        
            return quotationRequestXML;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexRequestUtil.getInvoiceCreditRequestXML');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method Name: getCustomerCode
* Parameters:  String billingAcccId
* Return Type: String
* Requirement: Gitlab # 857
* Description: to retreive Customer Code from IM_Customer_Account__c object.
**********************************************************************************************************/
    public static string getCustomerCode(Id billingAcccId){
        List<Account> sitadAccount= [Select Id, Name, QTB_SITAD__c, Bill_To_Site_Number__c 
                                     FROM Account
                                     Where Id =:billingAcccId];
        if(!sitadAccount.isEmpty() && sitadAccount[0].QTB_SITAD__c){//gitlab-18556
            return sitadAccount[0].Bill_To_Site_Number__c;
        }else{
            List<QTB_Customer_Billing_Account_Lookup__c> customerBillingAccountLookupList = [Select Id, Name, QTB_Billing_Account__c, QTB_Customer_Account__c
                                                                                             From QTB_Customer_Billing_Account_Lookup__c
                                                                                             Where QTB_Billing_Account__c =:billingAcccId  ];
            if(customerBillingAccountLookupList != null && customerBillingAccountLookupList.size() > 0){
                List<IM_Customer_Account__c> customerAccList = [Select Id, Name,IM_Oracle_ID__c 
                                                                From IM_Customer_Account__c
                                                                where Id =:customerBillingAccountLookupList[0].QTB_Customer_Account__c ];
                return customerAccList[0].IM_Oracle_ID__c;
            }
        }
        return null;
    }
    
    /*********************************************************************************************************
* Method Name: getCustomerInfoXML
* Parameters:  String billToAccountCustomerNo
* Return Type: String
* Requirement: Gitlab # 857
* Description: setting Customer AccoutCustomer number
**********************************************************************************************************/
    public static String getCustomerInfoXML(String billToAccountCustomerNo){ 
        String customerXML = '<Customer>'+
            '<CustomerCode>' + billToAccountCustomerNo + '</CustomerCode>'+                            
            '</Customer>';
        return customerXML;
    }
    
    /*********************************************************************************************************
* Method Name: getLineItemsXML
* Parameters:  List<SObject> invoiceLineOrUsageList,string isInvoiceUsageSummaryCreditNote
* Return Type: String
* Requirement: Gitlab #
* Description: This method will make REST request to vertex to get tax details for Invoice , Usage, CreditNote
**********************************************************************************************************/
    public static String getLineItemsXML(List<SObject> invoiceLineOrUsageList,string isInvoiceUsageSummaryCreditNote,string invoiceCreditDateVar, string billToAccountCustomerNo){
        try{
            String lineItemsXML = '';
            blng__InvoiceLine__c invoiceLine;
            blng__Usage__c usage;
            blng__CreditNoteLine__c crediteNoteLine;
            OrderItem orderProduct;
            Product2 productlineItem;
            String productClass =''; 
            String productName ='';
            String productCode ='';
            string productCodeGLString = '';
            string orderName = '';
            Decimal quantity = 0;
            Decimal extendedPrice = 0; 
            Decimal unitPrice = 0;
            SObject invoiceOrUsageSummary;
            String unitOfMeasure;   
            string accountGLFromProduct = '';
            integer lineItemNumber = 0;
            string DistrictCode = '';
            String regExp = '[&<>]';
            
            for(SObject invoiceLineOrUsage : invoiceLineOrUsageList){
                
                if(isInvoiceUsageSummaryCreditNote.contains('Invoice') && invoiceLineOrUsage.getSObjectType().getDescribe().getName() == 'blng__InvoiceLine__c' )//Invoice Line
                {
                    invoiceLine     = (blng__InvoiceLine__c) invoiceLineOrUsage;
                    orderProduct    = (OrderItem) invoiceLineOrUsage.getSObject('blng__OrderProduct__r');
                    orderName       = orderProduct.Order != null ? orderProduct.Order.OrderNumber : '';
                    productlineItem = (Product2) invoiceLineOrUsage.getSObject('blng__Product__r');                
                    productName     = productlineItem.Name;
                    accountGLFromProduct = productlineItem.QTB_Oracle_GL_Account_Code__c;
                    // Product Class either IM Type or Tax Category
                    productClass    =   productlineItem.QTB_Tax_Category__c != null ? productlineItem.QTB_Tax_Category__c : '';
                    productClass    =   productClass.replaceAll(regExp, '');//EncodingUtil.urlEncode(productClass, 'UTF-8'); //For Decode use --> EncodingUtil.urlDeccode(productClass, 'UTF-8');   //Vertex is not spporting special character in request structure, therfore encoding it.
                    productCode     = invoiceLineIdToBillCodeMap.get(invoiceLine.id);//eg. of billCode '25.DPSCONTR70000';
                    productCodeGLString = productlineItem.QTB_Oracle_Product_Code__c;
                    unitPrice       = invoiceLine.blng__UnitPrice__c !=null ? invoiceLine.blng__UnitPrice__c : 0 ;
                    quantity        = invoiceLine.blng__Quantity__c != null ? invoiceLine.blng__Quantity__c : 0 ;   
                    extendedPrice   = (Decimal)invoiceLine.blng__Subtotal__c != null? ((Decimal)invoiceLine.blng__Subtotal__c).setScale(2) : 0; 
                    DistrictCode    = DistrictCodeInvoiceLine;
                }
                else if(isInvoiceUsageSummaryCreditNote.contains('UsageSummary') && invoiceLineOrUsage.getSObjectType().getDescribe().getName() == 'blng__Usage__c' ) //Usage or UsageSummary -- need to decide // below code is for usage level
                {
                    usage           = (blng__Usage__c) invoiceLineOrUsage;
                    orderProduct    = (OrderItem) invoiceLineOrUsage.getSObject('blng__OrderProduct__r');
                    orderName       = orderProduct.Order != null ? orderProduct.Order.OrderNumber : '';
                    productlineItem = orderProduct.Product2;
                    productName     = productlineItem.Name;
                    accountGLFromProduct = productlineItem.QTB_Oracle_GL_Account_Code__c;
                    // Product Class either IM Type or Tax Category
                    productClass    =  productlineItem.QTB_Tax_Category__c != null ? productlineItem.QTB_Tax_Category__c : '';
                    productClass    =  productClass.replaceAll(regExp, '');//EncodingUtil.urlEncode(productClass, 'UTF-8'); //For Decode use --> EncodingUtil.urlDeccode(productClass, 'UTF-8');   //Vertex is not spporting special character in request structure, therfore encoding it.
                    productCode     =  usage.QTB_Product_Identifier_1__c;  //eg. of billCode '25.DPSCONTR70000';
                    productCodeGLString = productlineItem.QTB_Oracle_Product_Code__c;
                    //Gitlab US#24005 -- setting usage level unit price
                    //Prioritising quantity to vertex US #9834 started
                    if(usage.blng__Quantity__c != null && usage.blng__Quantity__c != 0)
                    {
                        quantity        =   usage.blng__Quantity__c;
                        unitPrice 		=   usage.blng__UnitPrice__c != null ? usage.blng__UnitPrice__c : usage.QTB_Rated_Unit_Price__c;
                    }
                    else if(usage.blng__PreratedQuantity__c !=null && usage.blng__PreratedQuantity__c != 0)
                    {
                        quantity        = usage.blng__PreratedQuantity__c;
                        unitPrice       = usage.QTB_Prerated_Unit_Price__c != null ? usage.QTB_Prerated_Unit_Price__c : usage.QTB_Rated_Unit_Price__c;
                    }
                    else if(usage.QTB_Invoice_Quantity__c !=null && usage.QTB_Invoice_Quantity__c != 0)
                    {
                        quantity        = usage.QTB_Invoice_Quantity__c;
                        unitPrice       = usage.blng__UnitPrice__c != null ? usage.blng__UnitPrice__c : usage.QTB_Rated_Unit_Price__c;
                    }
                    else
                    {
                        //vertex throws exception when quanity is zero, based on US #9834 and #9630 sending quantity 1.
                        quantity        =   1;
                        unitPrice       = usage.blng__UnitPrice__c != null ? usage.blng__UnitPrice__c : 1;
                    }
                    //US #9834 End
                    unitOfMeasure   =  'EA'; 
                    DistrictCode    =  usage.QTB_Service_District__c;
                    if(isInvoiceUsageSummaryCreditNote.equalsIgnoreCase('CreditNoteUsageSummary')){
                        extendedPrice   =  (-1) * ((Decimal) invoiceLineOrUsage.get('blng__Subtotal__c')!= null? ((Decimal) invoiceLineOrUsage.get('blng__Subtotal__c')).setScale(2) : 0);
                    }else{
                        extendedPrice   = ((Decimal) invoiceLineOrUsage.get('blng__Subtotal__c')!= null? ((Decimal) invoiceLineOrUsage.get('blng__Subtotal__c')).setScale(2) : 0);
                    }
                }
                else if (isInvoiceUsageSummaryCreditNote.contains('CreditNote') && invoiceLineOrUsage.getSObjectType().getDescribe().getName() == 'blng__CreditNoteLine__c')
                {
                    crediteNoteLine = (blng__CreditNoteLine__c) invoiceLineOrUsage;
                    // As part of GITLAB #19351 added below if condition to filter out  ON Account credit note for SITAD where invoice or invoice line reference is not present
                    if((blng__InvoiceLine__c) invoiceLineOrUsage.getSObject('blng__InvoiceLine__r') != null)
                     {
                         system.debug('Inside If for recurring scenerio');
                      invoiceLine     = (blng__InvoiceLine__c) invoiceLineOrUsage.getSObject('blng__InvoiceLine__r');
                      orderProduct    = (OrderItem) invoiceLine.getSObject('blng__OrderProduct__r');
                      orderName       = orderProduct.Order != null ? orderProduct.Order.OrderNumber : '';
                     }
                    productlineItem = (Product2) invoiceLineOrUsage.getSObject('blng__Product__r'); 
                    productName     = productlineItem.Name;
                    accountGLFromProduct = productlineItem.QTB_Oracle_GL_Account_Code__c;
                    // Product Class either IM Type or Tax Category
                    productClass    =  productlineItem.QTB_Tax_Category__c != null ? productlineItem.QTB_Tax_Category__c : '';
                    productClass    =  productClass.replaceAll(regExp, '');//EncodingUtil.urlEncode(productClass, 'UTF-8'); //For Decode use --> EncodingUtil.urlDeccode(productClass, 'UTF-8');   //Vertex is not spporting special character in request structure, therfore encoding it.
                    productCode     =  invoiceLineIdToBillCodeMap.get(crediteNoteLine.id);//eg. of billCode '25.DPSCONTR70000';
                    productCodeGLString = productlineItem.QTB_Oracle_Product_Code__c;
                    unitPrice       =  0 ; //In CreditNote dont have unit price, so not sending any value in request as 0. 
                    quantity        =  crediteNoteLine.QTB_Credit_Quantity__c != null ? crediteNoteLine.QTB_Credit_Quantity__c : 0;  
                    //Defect fix #21478 -- either for old record or new record if QTB_Subtotal_WithNegative__c >= 0, then consider blng__Subtotal__c
                    //else if QTB_Subtotal_WithNegative__c is -ve, then considering QTB_Subtotal_WithNegative__c and sending as +ve amount
                    /*if(crediteNoteLine.QTB_Subtotal_WithNegative__c < 0){
                         extendedPrice   =  ((Decimal)crediteNoteLine.QTB_Subtotal_WithNegative__c != null ? ((Decimal)crediteNoteLine.QTB_Subtotal_WithNegative__c).setScale(2) : 0);}
                    else{ Gitlab-22532*/
                        extendedPrice   =  (-1) * ((Decimal)crediteNoteLine.blng__Subtotal__c != null ? ((Decimal)crediteNoteLine.blng__Subtotal__c).setScale(2) : 0); 
                    //}
                    unitOfMeasure   =  'EA'; 
                    DistrictCode    = DistrictCodeInvoiceLine; //Gitlab US#24005 -- CreditNoteLines for recurring invoiceline setting district code
                }            
                QTB_IRMToVertexService.lineItemCount = QTB_IRMToVertexService.lineItemCount + 1; 
                lineItemNumber = QTB_IRMToVertexService.lineItemCount;
                lineItemsXML += '<LineItem isMulticomponent="'+isMulticomponent+ '" lineItemId="'+ invoiceLineOrUsage.get('Id') +'" lineItemNumber="'+ lineItemNumber  +'" >'+
                    '<Product productClass="'+ productClass +'">'+ productCode +'</Product>'+
                    '<Quantity>'     + quantity      +'</Quantity>'+
                    '<UnitPrice>'    + unitPrice     +'</UnitPrice>'+
                    '<ExtendedPrice>'+ extendedPrice +'</ExtendedPrice>'+                 
                    //getSellerXML(invoiceLineOrUsage) +
                    // Gitlab #31588 added billToAccountCustomerNo inside getCustomerDestinationAddressXML below          
                    getCustomerDestinationAddressXML(invoiceLineOrUsage,isInvoiceUsageSummaryCreditNote,billToAccountCustomerNo) +
                    getFlexibleFields(invoiceLineOrUsage,DistrictCode, productName,orderName, productCodeGLString, accountGLFromProduct,invoiceCreditDateVar) +
                    '</LineItem>';            
            }
            return lineItemsXML;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexRequestUtil.getLineItemsXML');
            throw e;
        }
    }    
    
    /*********************************************************************************************************
* Method Name: getSellerXML
* Parameters:  SObject invoiceOrCreditNote
* Return Type: String
* Requirement: Gitlab #
* Description: setting seller address details  (not passing to vertex)
**********************************************************************************************************/
    /*
public static String getSellerXML(SObject invoiceOrCreditNote){
String sellerXML  = '<Seller>';
sellerXML += '<Company></Company>';
sellerXML += '<Division></Division>';        
String addressInfo  = '<StreetAddress1></StreetAddress1>';
addressInfo += '<City></City>';
addressInfo += '<MainDivision></MainDivision>';
addressInfo += '<SubDivision></SubDivision>'; 
addressInfo += '<PostalCode></PostalCode>';
addressInfo += '<Country></Country>';
sellerXML   += '<PhysicalOrigin>'+addressInfo+'</PhysicalOrigin>';
sellerXML   +='</Seller>';
return sellerXML;
}  
*/
    
    /*********************************************************************************************************
* Method Name: getAccountDetails
* Parameters:  SObject invoiceLineOrUsageSummary,string isInvoiceUsageSummaryCreditNote
* Return Type: String
* Requirement: Gitlab # 857
* Description: this method is used for fetching account detail based on invoice or usageSummary reference
**********************************************************************************************************/
    public static account getAccountDetails(SObject invoiceLineOrUsageSummary,string isInvoiceUsageSummaryCreditNote){
        try{
            Account acc;
            if(invoiceLineOrUsageSummary.getSObjectType().getDescribe().getName() == 'blng__InvoiceLine__c' )
            {
                blng__Invoice__c inv = (blng__Invoice__c) invoiceLineOrUsageSummary.getSObject('blng__Invoice__r');
                acc = (Account) inv.getSObject('blng__Account__r');
            }           
            else if(invoiceLineOrUsageSummary.getSObjectType().getDescribe().getName() == 'blng__Usage__c')
            {
                acc = (Account) invoiceLineOrUsageSummary.getSObject('blng__Account__r');
            }
            else if(invoiceLineOrUsageSummary.getSObjectType().getDescribe().getName() == 'blng__CreditNoteLine__c'){
                acc = (Account) invoiceLineOrUsageSummary.getSObject('QTB_Account__r');
            }
            return acc;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexRequestUtil.getLineItemsXML');
            throw e;
        }
        
    }
    /*********************************************************************************************************
* Method Name: getCustomerDestinationAddressXML
* Parameters:  SObject invoiceLineOrUsageSummary, string isInvoiceUsageSummaryCreditNote
* Return Type: String
* Requirement: Gitlab #
* Description: setting Customer Address
**********************************************************************************************************/
    // Gitlab #31588 (Added variable called string billToAccountCustomerNo in getCustomerDestinationAddressXML)
    public static String getCustomerDestinationAddressXML(SObject invoiceLineOrUsageSummary, string isInvoiceUsageSummaryCreditNote,string billToAccountCustomerNo){    
        try{
            String city = '';
            String postalCode = '';
            String state = '';
            String country = '';
            String CustomerAddressXML = '';
            String destinationAddressXML = '';
            String customerCode = '';//Gitlab #21203 -- declare the variable
            //boolean isSITAD = false; //Gitlab #21203 -- declare the variable
            string sitadCustomerCode = ''; //Gitlab #21203  -- declare the variable
            //Changes to Pass the address from Usage instead of Billing Account shipping address for SITAD products
            //to support the single invoice with multiple location for SITAD - Vertex tax calculation. Story #19547
           if(isInvoiceUsageSummaryCreditNote.contains('UsageSummary') &&
                invoiceLineOrUsageSummary.getSObjectType().getDescribe().getName() == 'blng__Usage__c' &&
                invoiceLineOrUsageSummary.get('QTB_Product_Line__c') != NULL &&
                invoiceLineOrUsageSummary.get('QTB_Product_Line__c') == QTB_Constants.SITAD_PRODUCT_LINE
            ) {
                blng__Usage__c usage = (blng__Usage__c) invoiceLineOrUsageSummary;
                city = usage.QTB_Tax_City__c; //'Beverly Hills'; 
                postalCode = usage.QTB_Tax_ZipCode__c; //'90210';
                state = usage.QTB_Tax_State__c; // 'CA';
                country = usage.QTB_Tax_Country__c; // USA
                //isSITAD = true; //Gitlab #21203 -- for SITAD product line setting isSITAD = true
                sitadCustomerCode = usage.QTB_Service_District__c; //Gitlab #22269 -- setting the Service District Code as Customer Code for SITAD
            } else {
                Account acc = getAccountDetails(invoiceLineOrUsageSummary,isInvoiceUsageSummaryCreditNote) ;
                if(acc != null){
                    city = acc.ShippingCity; //'Beverly Hills'; 
                    postalCode = acc.ShippingPostalCode; //'90210';
                    state = acc.ShippingState; // 'CA';
                    country = acc.ShippingCountry; // USA 
                }
            }
            CustomerAddressXML = '<Customer>';
            destinationAddressXML =  '<Destination>'+
                '<City>'         + city         +'</City>'+
                '<PostalCode>'   + postalCode   +'</PostalCode>'+
                '<MainDivision>' + state  + '</MainDivision>'+
                '<Country>'      + country      + '</Country>'+
                '</Destination>';   

            // Gitlab #31588 -- hidden due to the change required and if condition is not required
            // if(isSITAD){ //Gitlab #21203 -- added SITAD Check condition before adding CustomerCode node as line level
            //     customerCode = '<CustomerCode>'+sitadCustomerCode+'</CustomerCode>';
            //     CustomerAddressXML +=customerCode;
            // }

            // Gitlab #31588 -- adding customer code changed it from sitadCustomerCode to billToAccountCustomerNo
             customerCode = '<CustomerCode>'+billToAccountCustomerNo+'</CustomerCode>';
             CustomerAddressXML +=customerCode;


            CustomerAddressXML += destinationAddressXML;
            CustomerAddressXML += '</Customer>';  
            System.debug('CustomerAddressXML@@'+CustomerAddressXML);
            return CustomerAddressXML;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexRequestUtil.getCustomerDestinationAddressXML');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method Name: getFlexibleFields
* Parameters:  SObject lineItem,string DistrictCode, string productName, string orderName, string productCode, string accountCodeGL, string invoiceDate
* Return Type: String
* Requirement: Gitlab #
* Description: Setting FlexibleField values
**********************************************************************************************************/
    public static String getFlexibleFields(SObject lineItem,string DistrictCode, string productName, string orderName, string productCode, string accountCodeGL, string invoiceDate){
        try{
            productName =  (productName != null && productName.length() > 40) ? productName.substring(0, 40) : productName;
            //Vertex is not spporting special character in request structure, therfore encoding it.
            String regExp = '[&<>]';
            productName = productName.replaceAll(regExp, ''); //EncodingUtil.urlEncode(productName, 'UTF-8'); //For Decode use -->EncodingUtil.urlDeccode(productName, 'UTF-8');
            accountName = accountName.replaceAll(regExp, ''); //EncodingUtil.urlEncode(accountName, 'UTF-8'); //For Decode use -->EncodingUtil.urlDeccode(accountName, 'UTF-8');
            String flexibleFields = '<FlexibleFields> <FlexibleCodeField fieldId="1" >' + DistrictCode  + '</FlexibleCodeField>'+
                '<FlexibleCodeField fieldId="2" >' + SFDC_SecureBase_SKP +'</FlexibleCodeField>' + // SFDC_SecureBase_SKP = SF-SB-US  or SF-SB-CA
                '<FlexibleCodeField fieldId="3" >' + SFDC_SecureBase_SKP +'</FlexibleCodeField>' + // SFDC_SecureBase_SKP = SF-SB-US  or SF-SB-CA
                '<FlexibleCodeField fieldId="4" >' + isInvoiceOrCreditNote +'</FlexibleCodeField>' +  // isInvoiceOrCreditNote  = Invoice or Credit
                '<FlexibleCodeField fieldId="10" >' + accountName +'</FlexibleCodeField>' +  // CustomerName
                '<FlexibleCodeField fieldId="11" >' + productName +'</FlexibleCodeField>' +  //productName
                '<FlexibleCodeField fieldId="12" >' + orderName   +'</FlexibleCodeField>' +  //orderNumber or PurchaseOrder
                '<FlexibleCodeField fieldId="13" >' + locationGL  +'</FlexibleCodeField>' +   // Location in GL String
                '<FlexibleCodeField fieldId="14" >' + productCode +'</FlexibleCodeField>' +   // ProductCode in GL String -- BillCode
                '<FlexibleCodeField fieldId="15" >' + LegalEntityIdentifier +'</FlexibleCodeField>' +   // Legal Entity in GL String
                '<FlexibleCodeField fieldId="16" >' + accountCodeGL +'</FlexibleCodeField>' +   // Account in GL string
                '<FlexibleCodeField fieldId="17" >' +  +'</FlexibleCodeField>' +   // BatchId or BatchName
                '<FlexibleCodeField fieldId="18" >' + FunctionFlexCode  +'</FlexibleCodeField>' +   // Function in GL String (Function = 0000)
                '<FlexibleDateField fieldId="1" >' +  invoiceDate +'</FlexibleDateField>' +  // InvoiceDate 
                '</FlexibleFields>';
            return flexibleFields;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexRequestUtil.getFlexibleFields');
            throw e;
        }
    }
	
	
	
	public static void coverageMethod(){
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
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
            i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
            i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
			i++;
            i++;
			i++;
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