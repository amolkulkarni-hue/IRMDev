/*****************************************************************************************************
* Class         : QTB_IRMToVertexHelper
* Test Class    : QTB_IRMToVertex_Test
* Purpose       : This is a Integration Class to send request to Vertex for tax calculation
* Requirement   : Gitlab #857, #2002
* Author        : IRM / Virtusa
* Developer     : Gopi / Shailesh
* Change History: 07/07/2021
* Developer                 Date            Description 
* ------------------------------------------------------------------------------------------- 
* Gopi / Shailesh       08/08/2021      #857 -- Vertex Tax calculation
* Ramesh                08/08/2023      GITLAB #17160 -- commented "blng__TaxRule__r.Name != :NoTaxRule" to allow all 
Invoice lines irrespective of taxrule to send to vertex
* Renuka Prasad         11/07/2023      #19547 -- Changes to calculate tax on Usage address from VERTEX for SITAD
*                        to support multiple location taxing                                        
*******************************************************************************************************/
public with sharing class QTB_IRMToVertexHelper {
    public static blng__Invoice__c invoice;
    public static List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
    public static Map<ID, blng__Invoice__c> invoiceIdToInvoiceMap = new Map<ID, blng__Invoice__c>();    
    public static List<blng__InvoiceLine__c> invoiceLineList = new List<blng__InvoiceLine__c>();
    public static Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
    public static Map<blng__Invoice__c, List<blng__InvoiceLine__c>> invoiceToInvoiceLineMap = new Map<blng__Invoice__c, List<blng__InvoiceLine__c>>();
    public static Map<Id, String> invoiceToLocationCodeMap = new Map<Id,String>();
    public static Map<Id, String> invoiceToServiceLocationMap = new Map<Id,String>();
    public static Map<id,blng__UsageSummary__c> usageSummaryMap = new Map<id,blng__UsageSummary__c>();
    public static List<blng__Usage__c> usageList = new List<blng__Usage__c>();
    public static Map<Id, String> mapSchedxProdItem = new Map<Id,String>();
    public static Map<Id,ConsumptionSchedule> validSchedMap = new Map<Id,ConsumptionSchedule>();
    public static Map<Id,set<id>> invoiceIdToUsageSummaryMap = new Map<Id,set<id>>();
    public static Map<Id,List<blng__Usage__c>> invoiceIdToUsageMap = new Map<Id,List<blng__Usage__c>>();
    public static Map<id,string> invoiceLineIdToBillCode = new Map<id,string>();
    public static Map<id,set<id>> alreadyProcessedIdsMap = new  Map<id,set<id>>();
    public static Map<id,boolean> invIdRequestCompletion = new  Map<id,boolean>();
    public static List<sObject> invoiceLineOrUsageListTax = new List<sObject>();
    public static Map<id, blng__InvoiceLine__c> usageSummInvoiceLine = new Map<id, blng__InvoiceLine__c>();
    // public static string NoTaxRule = 'No Tax Rule';
    public static string RecurringLines = 'Recurring';
    
    /*********************************************************************************************************
* Method Name: callMainMethod
* Parameters : List<id> invoiceIds
* Return Type: void    
* Company    : IRM/Virtusa
* Developer  : Gopi/Shailesh
* Description: This method will make REST request to vertex to get Authorization Code 
**********************************************************************************************************/
    public static void callMainMethod( List<id> invoiceIds){
        setInvoiceAndInvoiceLineItem(invoiceIds); // set invoice & invoiceLine records based on provided invoiceIds
        setUsageSummaryAndUsage(invoiceIds);     // set UsageSummary & usage records based on provided invoiceIds
    }
    
    
    /*********************************************************************************************************
* Method Name: getInvoice
* Parameters:  List<Id> invoiceIds
* Return Type: blng__Invoice__c    
* Company    : IRM/Virtusa
* Developer  : Gopi/Shailesh
* Description: getting invoice record based on invoiceId
**********************************************************************************************************/
    public static blng__Invoice__c getInvoice(List<Id> invoiceIds){
        try{
            if(!invoiceIdToInvoiceMap.isEmpty()){
                for(Id invoiceObj : invoiceIdToInvoiceMap.keySet()){ 
                    invoice = invoiceIdToInvoiceMap.get(invoiceObj); 
                    invoiceList.add(invoice);
                }
                return invoiceList[0];
            }
            return null;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab US#24005
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexHelper.getInvoice');
            throw e;
        }
        
    }
    
    /*********************************************************************************************************
* Method Name: getInvoiceLineUsageList
* Parameters : List<Id> invoiceIds,Map<id,set<id>> alreadyProcessedIdss, Map<id,boolean> invIdRequestCompletions
* Return Type: void
* Requirement: Gitlab #857
* Description: 
**********************************************************************************************************/
    public static  void getInvoiceLineUsageList(List<Id> invoiceIds,Map<id,set<id>> alreadyProcessedIdss, Map<id,boolean> invIdRequestCompletions){
        try{
            integer tempCount = 0;
            boolean checkLeftRecords = true;
            boolean checkStillLeftRecords = false;
            Map<id,decimal> usageToPercentage = new Map<id,decimal>();
            
            if(alreadyProcessedIdss != null){
                alreadyProcessedIdsMap = alreadyProcessedIdss;
            }
            if(invIdRequestCompletions != null){
                invIdRequestCompletion = invIdRequestCompletions;
            }
            if(!invoiceIdToInvoiceMap.isEmpty()){                
                for(Id invoiceObj : invoiceIdToInvoiceMap.keySet()){ 
                    decimal percentage = 0;
                    if(!invoiceIDToInvoiceLineMap.isEmpty() && invoiceIDToInvoiceLineMap.get(invoiceObj) !=null){
                        system.debug('invoiceIDToInvoiceLineMap.get(invoiceObj)@@'+invoiceIDToInvoiceLineMap.get(invoiceObj).size());
                        for(blng__InvoiceLine__c invoiceLine : invoiceIDToInvoiceLineMap.get(invoiceObj)){
                            if(invoiceLine.QTB_Charge_Type__c.equals(RecurringLines)){
                                System.debug('recurring count');
                                //If record not processed previously
                                if(alreadyProcessedIdsMap == null || (alreadyProcessedIdsMap != null && (!alreadyProcessedIdsMap.containsKey(invoiceObj) || (alreadyProcessedIdsMap.containsKey(invoiceObj) && !alreadyProcessedIdsMap.get(invoiceObj).contains(invoiceLine.id))))){
                                    if(tempCount < integer.valueOf(system.Label.QTB_Vertex_Request_Line_Size)){
                                        System.debug('inside if@@');
                                        tempCount ++;
                                        //Check the allocation and based on that add the Amount value
                                        //Check if taxable amount present or not
                                        if(invoiceLine.QTB_Allocated_Revenue_Amount__c != null && invoiceLine.QTB_Allocated_Revenue_Amount__c != 0){
                                            invoiceLine.put('blng__Subtotal__c', invoiceLine.QTB_Allocated_Revenue_Amount__c);
                                        }
                                        invoiceLineOrUsageListTax.add(invoiceLine);
                                        if(alreadyProcessedIdsMap.containsKey(invoiceObj)){
                                            alreadyProcessedIdsMap.get(invoiceObj).add(invoiceLine.id);    
                                        }else{
                                            alreadyProcessedIdsMap.put(invoiceObj, new Set<id>{invoiceLine.id});   
                                        }
                                        System.debug('alreadyProcessedIdsMap@@'+alreadyProcessedIdsMap);
                                    }else{
                                        checkStillLeftRecords = true;
                                    }
                                }
                            }
                            else if(invoiceLine.QTB_Charge_Type__c.equals('Usage') && invoiceLine.QTB_Inc_Quantity__c != null && 
                                    invoiceLine.QTB_Inc_Quantity__c >0 && invoiceLine.blng__Quantity__c > 0 && invoiceLine.QTB_Charged_Quantity__c > 0){
                                        percentage = (invoiceLine.QTB_Charged_Quantity__c/invoiceLine.blng__Quantity__c)*100;
                                        usageToPercentage.put(invoiceLine.blng__UsageSummary__c,percentage);
                                        System.debug('usageToPercentage@@'+usageToPercentage);
                                    }
                        }
                    }
                    if(!invoiceIdToUsageMap.isEmpty() && invoiceIdToUsageMap.get(invoiceObj) !=null){
                        System.debug('invoiceIdToUsageMap.get(invoiceObj)@@'+invoiceIdToUsageMap.get(invoiceObj).size());
                        for(blng__Usage__c usage : invoiceIdToUsageMap.get(invoiceObj)){
                            if(alreadyProcessedIdsMap == null || (alreadyProcessedIdsMap != null && (!alreadyProcessedIdsMap.containsKey(invoiceObj) || (alreadyProcessedIdsMap.containsKey(invoiceObj) && !alreadyProcessedIdsMap.get(invoiceObj).contains(usage.id))))){
                                if(tempCount < integer.valueOf(system.Label.QTB_Vertex_Request_Line_Size)){
                                    //Check the allocation and based on that add the Amount value
                                    //Check if taxable amount present or not ----> usage.blng__Subtotal__c -> InvoiceLine.QTB_Allocated_Revenue_Amount__c
                                    /*if(usageSummInvoiceLine.get(usage.blng__UsageSummary__c).QTB_Taxable_Amount__c != null && usageSummInvoiceLine.get(usage.blng__UsageSummary__c).QTB_Taxable_Amount__c != 0 &&
usageToPercentage != null && usage.blng__UsageSummary__c != null && usageToPercentage.containsKey(usage.blng__UsageSummary__c) )
{
//usage.put('blng__Subtotal__c',usage.blng__UsageSummary__r.blng__UnitPrice__c * (usage.blng__Quantity__c * usageToPercentage.get(usage.blng__UsageSummary__c)/100)* (usageSummInvoiceLine.get(usage.blng__UsageSummary__c).blng__Subtotal__c/usageSummInvoiceLine.get(usage.blng__UsageSummary__c).QTB_Charged_Quantity__c));

usage.put('blng__Subtotal__c',usage.blng__Quantity__c * (usageSummInvoiceLine.get(usage.blng__UsageSummary__c).QTB_Charged_Quantity__c/usageSummInvoiceLine.get(usage.blng__UsageSummary__c).blng__Quantity__c)*(usageSummInvoiceLine.get(usage.blng__UsageSummary__c).blng__Subtotal__c/usageSummInvoiceLine.get(usage.blng__UsageSummary__c).QTB_Charged_Quantity__c));
System.debug('usage@@'+usage);
}else{*/                                      
                                    //if(usage.blng__PreratedAmount__c !=null && usage.blng__PreratedAmount__c > 0){ #GITLAB 9379 BugFix
                                    if(usage.blng__PreratedAmount__c !=null && usage.blng__PreratedAmount__c != 0){
                                        usage.put('blng__Subtotal__c',usage.blng__PreratedAmount__c);
                                    }else if(usage.blng__Quantity__c != null && usage.blng__UsageSummary__r.blng__UnitPrice__c !=null) {
                                        usage.put('blng__Subtotal__c',usage.blng__UsageSummary__r.blng__UnitPrice__c * usage.blng__Quantity__c);
                                    }else{
                                        usage.put('blng__Subtotal__c',0);
                                    }
                                    //}
                                    
                                    // #GITLAB 11206 - If Usage record is using a Product with a FlatFee Consumption Rate,
                                    // use the calculated Subtotal field value directly.
                                    if(validSchedMap.containsKey(mapSchedxProdItem.get(usage.blng__OrderProduct__c))){
                                        usage.put('blng__Subtotal__c',usage.blng__Subtotal__c);
                                    }                                    
                                    invoiceLineOrUsageListTax.add(usage);
                                    tempCount ++;
                                    //alreadyProcessedIdsMap.add(usage.id);
                                    if(alreadyProcessedIdsMap.containsKey(invoiceObj)){
                                        alreadyProcessedIdsMap.get(invoiceObj).add(usage.id);    
                                    }else{
                                        alreadyProcessedIdsMap.put(invoiceObj, new Set<id>{usage.id});   
                                    }
                                }else{
                                    checkStillLeftRecords = true;
                                }
                            }
                        }
                    }
                    if(checkStillLeftRecords){
                        invIdRequestCompletion.put(invoiceIds[0], false);
                    }else{
                        invIdRequestCompletion.put(invoiceIds[0], true);
                        alreadyProcessedIdsMap.put(invoiceObj,new Set<id>{invoiceObj});
                    }
                }
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab US#24005
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexHelper.getInvoiceLineUsageList');
            throw e;
        }    }
    
    /*********************************************************************************************************
* Method Name: getProductBillCode
* Parameters:  List<Id> invoiceIds 
* Return Type: void
* Requirement: Gitlab #
* Description: This method is used for storing InvoicelineId with BillCode
**********************************************************************************************************/
    public static Map<id,string> getProductBillCode(List<Id> invoiceIds ){
        try{
            Map<id,id> invoiceLineProductMap = new Map<id,id>();
            Map<id,string> ProductToBillMap = new Map<id,string>();
            // InvCountry added as part of GITLAB #15327 for Country check in QTB_Bill_Code_Product_Lookup__c query
            Set<String> InvCountry = new Set<String>();
            if(invoiceIDToInvoiceLineMap.containsKey(invoiceIds[0])){
                for(blng__InvoiceLine__c invline : invoiceIDToInvoiceLineMap.get(invoiceIds[0])){
                    invoiceLineProductMap.put(invline.id,invline.blng__Product__c);
                    InvCountry.add(invline.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c);
                    system.debug('InvCountry@@214'+InvCountry);
                }  
                for(QTB_Bill_Code_Product_Lookup__c billCode : [Select Id, Name,QTB_Source_Bill_Code__c,QTB_Product2__c 
                                                                From QTB_Bill_Code_Product_Lookup__c 
                                                                where QTB_Product2__c IN : invoiceLineProductMap.values() AND  QTB_Country__r.Name IN :InvCountry ] )
                {
                    system.debug('billCode@@' +billCode);
                    ProductToBillMap.put(billCode.QTB_Product2__c,billCode.QTB_Source_Bill_Code__c);
                }
                for(blng__InvoiceLine__c invline : invoiceIDToInvoiceLineMap.get(invoiceIds[0])){
                    invoiceLineIdToBillCode.put(invline.id, ProductToBillMap.get(invoiceLineProductMap.get(invline.id)));
                } 
                
            }
            return invoiceLineIdToBillCode;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab US#24005
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexHelper.getProductBillCode');
            throw e;
        }
    }
    
    
    public static Map<Id, String> getDistrict(List<Id> invoiceId){
        return getDistrictAndLocation(invoiceIdToInvoiceMap.get(invoiceId[0]),'District');
    }
    
    public static Map<Id, String> getLocation(List<Id> invoiceId){
        return getDistrictAndLocation(invoiceIdToInvoiceMap.get(invoiceId[0]),'Location');
    }
    
    /*********************************************************************************************************
* Method Name: getDistrictAndLocation
* Parameters:  blng__Invoice__c invoices, string DistrictOrLocation
* Return Type: void
* Requirement: Gitlab #
* Description: This method is used for to get DistrictCode & LocationCode from Service_Location__c obj
**********************************************************************************************************/
    public static Map<Id, String> getDistrictAndLocation(sObject invoices, string DistrictOrLocation){
        try{
            Map<id,id> accountToInvoiceMap = new Map<id,id>(); 
            Map<Id,String> billingAcctIdWithCustomerDistrictMap = new Map<Id,String>();//Gitlab US#24005
            for(blng__Invoice__c inv : invoiceIdToInvoiceMap.values()){
                accountToInvoiceMap.put(inv.blng__Account__r.Id,inv.id );
                billingAcctIdWithCustomerDistrictMap.put(inv.Id,inv.blng__Account__r.QTB_Customer_District__c);//Gitlab US#24005
            }
            
            //Gitlab US#24005 -- logic modified to get the serviceDistrict if BillingAccount dont have service location 
            List<Service_Location__c> serviceLocationList = [SELECT Id, Name,Address1__c, Address2__c, Address3__c, IM_Country_name__c, IM_County_Name__c,
                                                             Postal_Code__c,QTB_Billing_Account__c, Owning_District_Id__r.Owning_District_Id__c,Owning_District_Id__r.QTB_Oracle_Location_Code__c
                                                             FROM Service_Location__c 
                                                             WHERE QTB_Billing_Account__c IN : accountToInvoiceMap.keySet()];
            if(!serviceLocationList.isEmpty()){
                for(Service_Location__c serviceLocation : serviceLocationList)
                {
                    string districtCode = (serviceLocation.Owning_District_Id__c != null && serviceLocation.Owning_District_Id__r.Owning_District_Id__c !=null ) ? serviceLocation.Owning_District_Id__r.Owning_District_Id__c : '';
                    string locationCode = (serviceLocation.Owning_District_Id__c != null && serviceLocation.Owning_District_Id__r.QTB_Oracle_Location_Code__c !=null) ? serviceLocation.Owning_District_Id__r.QTB_Oracle_Location_Code__c : '';
                    invoiceToServiceLocationMap.put(accountToInvoiceMap.get(serviceLocation.QTB_Billing_Account__c),districtCode);
                    invoiceToLocationCodeMap.put(accountToInvoiceMap.get(serviceLocation.QTB_Billing_Account__c),locationCode);
                }
                if(DistrictOrLocation == 'District'){
                    return invoiceToServiceLocationMap;
                }
                if(DistrictOrLocation == 'Location' ){
                    return invoiceToLocationCodeMap;
                }
            }
            else{
                return billingAcctIdWithCustomerDistrictMap;//Gitlab US#24005
            }            
            return null;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab US#24005
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexHelper.getDistrictAndLocation');
            throw e;
        }
        
    }
    
    /*********************************************************************************************************
* Method Name: setInvoiceAndInvoiceLineItem
* Parameters:  List<Id> invoiceIds
* Return Type: void
* Requirement: Gitlab #
* Description: This method is used for fetching Invoice & Invoice for given invoieId
**********************************************************************************************************/
    public static void setInvoiceAndInvoiceLineItem(List<Id> invoiceIds){
        try{
            //Get all the Invoices in a map
            invoiceIdToInvoiceMap = new Map<ID, blng__Invoice__c>([Select ID,blng__InvoiceDate__c,Name,blng__InvoiceStatus__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.Name,blng__Account__r.QTB_Billing_Account_Invoice_Name__c, blng__Account__r.AccountNumber,
                                                                   blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.IME_Display_Division__c,blng__Account__r.ShippingState,blng__Account__r.ShippingPostalCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                                                   blng__Order__r.SBQQ__Quote__r.QTB_Opportunity_Product_Line__c,blng__Account__r.CurrencyISOCode,blng__TaxErrorMessage__c                                         
                                                                   ,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c, blng__Account__r.QTB_Customer_District__c//Gitlab US#24005--added field
                                                                   From blng__Invoice__c where Id IN : invoiceIds ]); 
            //Get all the invoiceLines
            invoiceLineList = [Select ID,blng__ChargeType__c,QTB_Inc_Quantity__c,QTB_Charged_Quantity__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                               blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Oracle_Product_Code__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__TotalAmount__c, blng__Invoice__r.blng__Account__c,
                               blng__Subtotal__c,QTB_Allocated_Revenue_Amount__c,blng__Invoice__r.blng__Account__r.BillingCity,blng__Invoice__r.blng__Account__r.BillingState, blng__Invoice__r.blng__Account__r.BillingPostalCode, blng__Invoice__r.blng__Account__r.ShippingCity,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.ShippingState,blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                               blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.BillingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                               blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c,blng__TaxRule__c,blng__TaxRule__r.Name                        
                               From blng__InvoiceLine__c where blng__Invoice__c IN : invoiceIds /* and blng__TaxRule__r.Name != :NoTaxRule */  order by Name];
            //GITLAB #17160 -- commented "blng__TaxRule__r.Name != :NoTaxRule" to allow all  Invoice lines irrespective of taxrule to send to vertex
            //Map to keep Invoice Id and List of InviceLine
            for(blng__InvoiceLine__c invoiceLine : invoiceLineList){
                //Don't consider null Usage Summary
                if(invoiceLine.blng__UsageSummary__c != null){
                    usageSummInvoiceLine.put(invoiceLine.blng__UsageSummary__c, invoiceLine);
                }
                if(invoiceIdToUsageSummaryMap.containsKey(invoiceLine.blng__Invoice__c)){
                    invoiceIdToUsageSummaryMap.get(invoiceLine.blng__Invoice__c).add(invoiceLine.blng__UsageSummary__c);
                }else{
                    invoiceIdToUsageSummaryMap.put(invoiceLine.blng__Invoice__c,new set<id>{invoiceLine.blng__UsageSummary__c});
                }
                if(invoiceIdToInvoiceLineMap.containsKey(invoiceLine.blng__Invoice__c)){
                    invoiceIdToInvoiceLineMap.get(invoiceLine.blng__Invoice__c).add(invoiceLine);
                }
                else{
                    invoiceIDToInvoiceLineMap.put(invoiceLine.blng__Invoice__c,new List<blng__InvoiceLine__c>{invoiceLine});
                }
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab US#24005
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexHelper.setInvoiceAndInvoiceLineItem');
            throw e;
        }
        
    }
    
    /*********************************************************************************************************
* Method Name: setUsageSummaryAndUsage
* Parameters:  List<Id> invoiceIds
* Return Type: void
* Requirement: Gitlab #
* Description: This method is used for fetching usageSummary & Usage for given invoieId
**********************************************************************************************************/
    public static void setUsageSummaryAndUsage(List<Id> invoiceIds){
        try{
            /*usageSummaryMap = new Map<ID, blng__UsageSummary__c>([Select id, Name,blng__Invoice__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.Name, blng__Account__r.QTB_Customer_Number__c,blng__Status__c,blng__SummaryStartDate__c, blng__OrderProduct__r.Product2.Name,
blng__Account__r.ShippingCity,blng__Account__r.ShippingPostalCode,blng__Account__r.IME_Display_Division__c,blng__Account__r.QTB_Legal_Entity_Country__c,
blng__Account__r.ShippingCountry,blng__Account__r.CurrencyISOCode From blng__UsageSummary__c where blng__Invoice__c IN : invoiceIds   ]); //'aJN7b000000MjKOGA0'
*/
            
            
            usageList = [Select id,blng__Subtotal__c, Name,QTB_Service_District__c,QTB_Product_Identifier_1__c,blng__UsageSummary__r.blng__Account__c,blng__Account__r.Id,blng__UsageSummary__c,blng__UsageSummary__r.id,blng__UsageSummary__r.blng__Status__c,blng__UsageSummary__r.blng__Invoice__c,QTB_Product__c,blng__OrderProduct__c,blng__OrderProduct__r.Id,blng__OrderProduct__r.Product2Id,
                         blng__OrderProduct__r.Product2.id,blng__OrderProduct__r.Product2.Name, blng__OrderProduct__r.Product2.QTB_Tax_Category__c,blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,blng__OrderProduct__r.Product2.QTB_Oracle_GL_Account_Code__c,blng__OrderProduct__r.Product2.IM_Product_Class__c, blng__OrderProduct__r.Product2.ProductCode,blng__OrderProduct__r.Product2.Bill_Code__c, blng__ProcessingDate__c,
                         blng__Account__r.BillingCity,blng__Account__r.BillingPostalCode,blng__Account__r.BillingState, blng__Account__r.IME_Display_Division__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.BillingCountry,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.ShippingState,blng__Account__r.ShippingPostalCode,QTB_Rated_Amount__c,blng__UnitPrice__c,blng__Quantity__c,blng__PreratedQuantity__c,QTB_Invoice_Quantity__c,blng__OrderProduct__r.Order.OrderNumber,blng__PreratedAmount__c,blng__UsageSummary__r.blng__UnitPrice__c,
                         QTB_Product_Line__c,QTB_Tax_City__c,QTB_Tax_ZipCode__c,QTB_Tax_State__c,QTB_Tax_Country__c,QTB_Department_Code__c,QTB_Prerated_Unit_Price__c,QTB_Rated_Unit_Price__c//Gitlab#24005  //Story #19547 To calculate tax on Usage address from VERTEX for SITAD to support multiple location taxing
                         From blng__Usage__c where blng__UsageSummary__c IN: usageSummInvoiceLine.keySet() order by Name ];
            
            /*for(blng__UsageSummary__c usageSummaryObj : usageSummaryMap.values()){
invoiceIdToUsageSummaryMap.put(usageSummaryObj.blng__Invoice__c,usageSummaryMap.values());
}*/
            Set<Id> usageProductIdSet = new Set<Id>();
            System.debug('usageList@@'+usageList);
            //invoiceId to Usages (List of Usage) mapping
            for(blng__Usage__c usage : usageList)
            {
                usageProductIdSet.add(usage.blng__OrderProduct__c);
                if(invoiceIdToUsageMap.containsKey(usageSummInvoiceLine.get(usage.blng__UsageSummary__c).blng__Invoice__c))
                {
                    invoiceIdToUsageMap.get(usageSummInvoiceLine.get(usage.blng__UsageSummary__c).blng__Invoice__c).add(usage);
                }
                else{
                    invoiceIdToUsageMap.put(usageSummInvoiceLine.get(usage.blng__UsageSummary__c).blng__Invoice__c,new List<blng__Usage__c>{usage});
                }
            }        
            System.debug('invoiceIdToUsageMap@@'+invoiceIdToUsageMap);
            
            // Find Products with a "Flat Fee" pricing method on their Consumption Rate that are used by Usage records
            for(SBQQ__OrderItemConsumptionSchedule__c j : [SELECT Id, SBQQ__ConsumptionSchedule__c, SBQQ__OrderItem__c FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c IN: usageProductIdSet]){
                mapSchedxProdItem.put(j.SBQQ__OrderItem__c, j.SBQQ__ConsumptionSchedule__c);
            }
            validSchedMap = new Map<Id,ConsumptionSchedule>([SELECT Id, Name FROM ConsumptionSchedule WHERE Id IN: mapSchedxProdItem.values() AND Id IN (SELECT ConsumptionScheduleId FROM ConsumptionRate WHERE PricingMethod = 'FlatFee')]);
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab US#24005
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexHelper.setUsageSummaryAndUsage');
            throw e;
        }
    }
}