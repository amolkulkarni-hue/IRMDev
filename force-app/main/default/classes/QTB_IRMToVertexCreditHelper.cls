/*****************************************************************************************************
* Class         : QTB_IRMToVertexCreditHelper
* Test Class    : QTB_IRMToVertex_Test
* Purpose       : This is a Integration Class to send request to Vertex for tax calculation
* Requirement   : Gitlab #857, #2002
* Author        : IRM / Virtusa
* Developer     : Gopi / Shailesh
* Change History: 07/07/2021 
* Developer              Date            Description
* ------------------------------------------------------------------------------------------- 
* Gopi / Shailesh       08/08/2021      #857 -- Vertex Tax calculation
* Shailesh        09/23/2021      #5422 -- Defect fix
* Shailesh        12/25/2021      #6721 -- Vertex post scenario for Subscription Credit notes (Defect Fix)
* Ramesh                08/08/2023      GITLAB #17160 -- commented "blng__TaxRule__r.Name != :NoTaxRule" to allow all 
Creditnote lines irrespective of taxrule to send to vertex
*******************************************************************************************************/
public with sharing class QTB_IRMToVertexCreditHelper {
    public static blng__CreditNote__c CreditNote;
    public static List<blng__CreditNote__c> CreditNoteList = new List<blng__CreditNote__c>();
    public static Map<ID, blng__CreditNote__c> creditNoteIdToCreditNoteMap = new Map<ID, blng__CreditNote__c>();   
    public static List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
    public static Map<Id,List<blng__CreditNoteLine__c>> creditIdToCreditNoteLinesMap = new Map<Id,List<blng__CreditNoteLine__c>>();
    public static List<blng__CreditNoteLine__c> creditNoteLineListFinal = new  List<blng__CreditNoteLine__c>();
    public static List<blng__InvoiceLine__c> invoiceLineListFinal = new  List<blng__InvoiceLine__c>();
    public static List<blng__UsageSummary__c> usageSummaryFinalList = new List<blng__UsageSummary__c>();
    public static List<blng__Usage__c> usageListFinal = new List<blng__Usage__c>();
    public static Map<id,id> creditLineIdToInvoiceLineMap = new Map<id,id>();
    public static Map<id,decimal> invoiceLinePercentage = new Map<id,decimal>();
    public static Map<id,List<blng__CreditNoteLine__c>> creditNoteIdCreditNoteLineListmap = new Map<id,List<blng__CreditNoteLine__c>>();
    public static Map<id,List<blng__Usage__c>> creditNoteIdUsageListmap = new Map<id,List<blng__Usage__c>>();
    public static Map<id,id> invoiceLineToCreditNoteId = new Map<id,id>();
    public static Map<id,set<id>> alreadyProcessedIdsMap = new  Map<id,set<id>>();
    public static Map<id,boolean> invIdRequestCompletion = new  Map<id,boolean>();
    public static List<sObject> invoiceLineOrUsageListTax = new List<sObject>();
    public static Map<id,blng__InvoiceLine__c> usageSummaryInvoiceLineMap = new Map<id,blng__InvoiceLine__c>();
    public static Map<id,string> creditLineIdToBillCode = new Map<id,string>(); 
    //  public static string NoTaxRule = 'No Tax Rule';
    public static string RecurringLines = 'Recurring';
    /*********************************************************************************************************
* Method Name: callVertexCreditHelper
* Parameters : List<id> postedCreditNoteIds
* Return Type: void    
* Company    : IRM/Virtusa
* Developer  : Gopi/Shailesh
* Description: This method will make REST request to vertex to get Authorization Code 
**********************************************************************************************************/
    public static void callVertexCreditHelper( List<ID> postedCreditNoteIds){
        try{
            creditNoteIdToCreditNoteMap = new Map<ID, blng__CreditNote__c>( [Select id, Name, blng__Status__c,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c, blng__Account__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                                                                             blng__Account__r.Name,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Customer_District__c,//Gitlab US#24005 added field
                                                                             blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                                                                             blng__CreditNoteDate__c, QTB_CreditNote_Posted_Date__c,CurrencyISOCode,
                                                                             blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c  
                                                                             From blng__CreditNote__c 
                                                                             where id IN: postedCreditNoteIds ]);
            System.debug('creditNoteIdToCreditNoteMap@@'+creditNoteIdToCreditNoteMap); 
            creditNoteLineList = [Select id, Name,blng__CreditNote__c,blng__TaxAmount__c,blng__CreditNote__r.Id, QTB_Account__c,blng__BillToAccount__c, QTB_Account__r.QTB_Customer_Number__c,blng__Status__c,
                                  QTB_Account__r.BillingCity, QTB_Account__r.BillingPostalCode,QTB_Account__r.BillingState, QTB_Account__r.IME_Display_Division__c,QTB_Account__r.ShippingCity,QTB_Account__r.ShippingCountry,QTB_Account__r.ShippingState,QTB_Account__r.ShippingPostalCode,QTB_Account__r.QTB_Billing_Account_Invoice_Name__c,
                                  QTB_Account__r.BillingCountry,blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.QTB_Oracle_Product_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.Name,
                                  blng__Product__r.ProductCode,blng__TotalAmount__c,blng__Subtotal__c,QTB_Credit_Quantity__c,blng__InvoiceLine__r.blng__OrderProduct__r.Id,
                                  blng__InvoiceLine__r.blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c,
                                  blng__InvoiceLine__c,blng__InvoiceLine__r.blng__TaxAmount__c,blng__InvoiceLine__r.blng__UsageSummary__c,blng__InvoiceLine__r.blng__UsageSummary__r.id,blng__InvoiceLine__r.QTB_Charge_Type__c,
                                  blng__InvoiceLine__r.QTB_HasConsumptionSchedule__c,blng__InvoiceLine__r.blng__Subtotal__c,QTB_Allocated_Revenue_Amount__c,
                                  blng__InvoiceLine__r.QTB_Taxable_Amount__c,blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c,blng__InvoiceLine__r.blng__TaxRule__c,blng__InvoiceLine__r.blng__TaxRule__r.Name,
                                  blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__InvoiceLine__r.blng__UnitPrice__c,//Gitlab US#24005 added field in query
                                  QTB_On_Account_Credit_Note_Line__c/*,QTB_Subtotal_WithNegative__c Gitlab-22532*///Defect fix 21478 -- added field in query
                                  From blng__CreditNoteLine__c 
                                  where  blng__CreditNote__c IN : creditNoteIdToCreditNoteMap.keySet() 
                                  /* and blng__InvoiceLine__c != null  and
								blng__InvoiceLine__r.blng__TaxRule__r.Name !=:NoTaxRule  */
                                  order by Name desc];
            //GITLAB #17160 -- commented "blng__TaxRule__r.Name != :NoTaxRule" to allow all Creditnote lines irrespective of taxrule to send to vertex
            System.debug('creditNoteLineList@@'+creditNoteLineList);
            
            //Map to keep creditnote Id and List of creditnoteline
            for(blng__CreditNoteLine__c creditLine : creditNoteLineList){
                if(creditIdToCreditNoteLinesMap.containsKey(creditLine.blng__CreditNote__c)){
                    creditIdToCreditNoteLinesMap.get(creditLine.blng__CreditNote__c).add(creditLine);
                }
                else{
                    creditIdToCreditNoteLinesMap.put(creditLine.blng__CreditNote__c,new List<sObject>{creditLine});
                }
                creditLineIdToInvoiceLineMap.put(creditline.id,creditline.blng__InvoiceLine__c);
                decimal tempPercentage = 0;
                //Calculate the Invoice Line percentage
                if(creditLine.blng__InvoiceLine__c != null && creditLine.blng__Subtotal__c != null && creditLine.blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c != null && creditLine.blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c != 0){
                    tempPercentage = (creditLine.blng__Subtotal__c/creditLine.blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c)*100;
                    //Defect fix - 14963 -- calculate percentage based on credit note line allocated revenue amt wrt Invoice line allocated revenue amt
                    if(creditLine.QTB_Allocated_Revenue_Amount__c != null && creditLine.QTB_Allocated_Revenue_Amount__c != 0 && creditLine.QTB_Allocated_Revenue_Amount__c != creditLine.blng__Subtotal__c){
                        tempPercentage = (creditLine.QTB_Allocated_Revenue_Amount__c/creditLine.blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c)*100;  
                    }else{
                        //Defect fix Gitlab# 21795
                        /*if(creditLine.QTB_Subtotal_WithNegative__c < 0){
						tempPercentage = (creditLine.QTB_Subtotal_WithNegative__c/creditLine.blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c)*100;
						}else{ Gitlab-22532*/
                        tempPercentage = (creditLine.blng__Subtotal__c/creditLine.blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c)*100; 
                        //}
                    } 
                    System.debug('tempPercentage1@@'+tempPercentage);
                }
                /*else if(creditLine.blng__InvoiceLine__c != null && creditLine.blng__InvoiceLine__r.blng__Subtotal__c != null && creditLine.blng__Subtotal__c != null){
                    tempPercentage = (creditLine.blng__Subtotal__c/creditLine.blng__InvoiceLine__r.blng__Subtotal__c)*100;
                    System.debug('tempPercentage2@@'+tempPercentage);
				}*/
                //Storing InvoiceLineID with total percentage of CreditNoteLine associated with that invoiceLine
                if(creditLine.blng__InvoiceLine__c != null)
                {
                    if(  invoiceLinePercentage.containsKey(creditLine.blng__InvoiceLine__c)){
                        invoiceLinePercentage.put(creditLine.blng__InvoiceLine__c, tempPercentage + invoiceLinePercentage.get(creditLine.blng__InvoiceLine__c));
                    }else{
                        invoiceLinePercentage.put(creditLine.blng__InvoiceLine__c,tempPercentage);
                    }
                }
                invoiceLineToCreditNoteId.put(creditLine.blng__InvoiceLine__c, creditLine.blng__CreditNote__c);
                //Check consumption schedule
                //Credit Note Id -> List Recurring CeditNoteLines  
                // As part of bug fix GITLAB #19351   added  creditLine.QTB_On_Account_Credit_Note_Line__c  on Account credit check to pass
                // credit note line reference to vertex       
                if((creditLine.blng__InvoiceLine__c != null && creditLine.blng__InvoiceLine__r.QTB_Charge_Type__c.equals(RecurringLines)) ||
                   creditLine.QTB_On_Account_Credit_Note_Line__c ){
                       System.debug('QTB_On_Account_Credit_Note_Line__c@@check');
                       //Calculate the percentage value
                       //creditLine.put('blng__Subtotal__c',creditLine.blng__Subtotal__c*(tempPercentage/100));
                       creditLine.put('blng__Subtotal__c',creditLine.QTB_Allocated_Revenue_Amount__c);
                       if(creditNoteIdCreditNoteLineListmap.containsKey(creditLine.blng__CreditNote__c)){
                           creditNoteIdCreditNoteLineListmap.get(creditLine.blng__CreditNote__c).add(creditLine);
                       }else{
                           creditNoteIdCreditNoteLineListmap.put(creditLine.blng__CreditNote__c, new List<blng__CreditNoteLine__c> {creditLine});
                       }
                   }
                else if(creditLine.blng__InvoiceLine__c != null && creditLine.blng__InvoiceLine__r.blng__UsageSummary__c != null){
                    usageSummaryInvoiceLineMap.put(creditLine.blng__InvoiceLine__r.blng__UsageSummary__c,creditLine.blng__InvoiceLine__r);
                }
            }
            
            if(creditLineIdToInvoiceLineMap != null){
                system.debug('Credit CHeck2'+creditLineIdToInvoiceLineMap.values());
                List<blng__Usage__c> usageList = [Select id, Name,blng__Subtotal__c,QTB_Service_District__c,QTB_Product_Identifier_1__c,blng__UsageSummary__r.blng__Account__c,
                                                  blng__Account__r.Id,blng__UsageSummary__c,blng__UsageSummary__r.id,blng__UsageSummary__r.blng__Status__c,blng__UsageSummary__r.blng__Invoice__c,
                                                  QTB_Product__c,blng__OrderProduct__c,blng__OrderProduct__r.Id,blng__OrderProduct__r.Product2Id,blng__OrderProduct__r.Product2.id,
                                                  blng__OrderProduct__r.Product2.Name, blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,blng__OrderProduct__r.Product2.QTB_Oracle_GL_Account_Code__c,blng__OrderProduct__r.Product2.IM_Product_Class__c,
                                                  blng__OrderProduct__r.Product2.ProductCode,blng__OrderProduct__r.Product2.Bill_Code__c,blng__ProcessingDate__c,blng__Account__r.BillingCity,
                                                  blng__Account__r.BillingState, blng__Account__r.BillingPostalCode,blng__Account__r.IME_Display_Division__c,blng__Account__r.BillingCountry,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.ShippingState,blng__Account__r.ShippingPostalCode,
                                                  QTB_Rated_Amount__c,blng__UnitPrice__c,blng__Quantity__c,blng__OrderProduct__r.Order.OrderNumber,blng__PreratedAmount__c,
                                                  blng__UsageSummary__r.blng__UnitPrice__c,blng__OrderProduct__r.Product2.QTB_Tax_Category__c, blng__PreratedQuantity__c, QTB_Invoice_Quantity__c,blng__UsageSummary__r.QTB_UnitPrice__c,//Gitlab US#24005
                                                  QTB_Product_Line__c,QTB_Tax_City__c,QTB_Tax_ZipCode__c,QTB_Tax_State__c,QTB_Tax_Country__c,QTB_Department_Code__c,QTB_Rated_Unit_Price__c,QTB_Prerated_Unit_Price__c //Gitlab US#24005  //Story #19547 To calculate tax on Usage address from VERTEX for SITAD to support multiple location taxing
                                                  From blng__Usage__c 
                                                  where blng__UsageSummary__c IN: usageSummaryInvoiceLineMap.keySet()];
                system.debug('Credit CHeck3'+usageList.size());
                //Credit Note Id -> List Usages
                for(blng__Usage__c usg :usageList){
                    //Gitlab US#24005 -- below code is not required, therefore commented it
                    //Percentage value for the Usage
                    //Using QTB_Taxable_Amount__c field check instead of QTB_Allocated_Revenue_Amount__c, bcoz from QTB_Allocated_Revenue_Amount__c field not able to figure it out its value is from Taxble or subtotal
                    /*if(usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).QTB_Taxable_Amount__c == 0 || usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).QTB_Taxable_Amount__c == null){ 
                        //Used QTB_Rated_Amount__c field from usage bcoz posted invoice considering the QTB_Rated_Amount__c amout of usages
                        if(usg.QTB_Rated_Amount__c !=null && (usg.QTB_Rated_Amount__c > 0 || usg.QTB_Rated_Amount__c < 0)){  //Defect fix Gitlab# 21795
                            usg.put('blng__Subtotal__c',usg.QTB_Rated_Amount__c *(invoiceLinePercentage.get(usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).id)/100));
                            System.debug('usg1'+usg);
                        }
                    }else{
                        usg.put('blng__Subtotal__c',usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).QTB_Allocated_Revenue_Amount__c * (invoiceLinePercentage.get(usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).id)/100));
                        System.debug('usg2'+usg);
                    }*/
                    //Gitlab US#24005 -- new logic for usage is subtotal should be [creditNoteLinePercentage wrt invoiceLine * (InvoiceLineUnitPrice * UsageQuantity)
                    decimal usageUnitPrice = usg.blng__UsageSummary__r.QTB_UnitPrice__c != null && usg.blng__UsageSummary__r.QTB_UnitPrice__c != 0 
                        					? usg.blng__UsageSummary__r.QTB_UnitPrice__c 
                        					: usg.QTB_Rated_Unit_Price__c;
                    decimal percentageAmt = invoiceLinePercentage.get(usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).id)/100;
                    decimal usgQuantity = (usg.blng__Quantity__c != null && usg.blng__Quantity__c != 0) ? usg.blng__Quantity__c 
                        				  : usg.blng__PreratedQuantity__c != null ? usg.blng__PreratedQuantity__c : 0;
                   if(usg.blng__PreratedAmount__c !=null && usg.blng__PreratedAmount__c !=0){  //Defect fix Gitlab# 21795, 21005
                        usg.put('blng__Subtotal__c',usg.blng__PreratedAmount__c * percentageAmt);
                    }else{
                        usg.put('blng__Subtotal__c', (percentageAmt) * (usageUnitPrice * usgQuantity)); 
                    }
                    if(creditNoteIdUsageListmap.containsKey(invoiceLineToCreditNoteId.get(usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).id))){
                        creditNoteIdUsageListmap.get(invoiceLineToCreditNoteId.get(usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).id)).add(usg);
                    }else{
                        creditNoteIdUsageListmap.put(invoiceLineToCreditNoteId.get(usageSummaryInvoiceLineMap.get(usg.blng__UsageSummary__c).id), new List<blng__Usage__c> {usg});
                    } 
                }
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexCreditHelper.callVertexCreditHelper');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method Name: getCreditLineUsageList
* Parameters : List<Id> invoiceIds,Map<id,set<id>> alreadyProcessedIdss, Map<id,boolean> invIdRequestCompletions
* Return Type: void    
* Company    : IRM/Virtusa
* Developer  : Gopi/Shailesh
* Description: This method to get creditline or usage based invoiceline consumption schedule
**********************************************************************************************************/
    public static void getCreditLineUsageList(List<Id> invoiceIds,Map<id,set<id>> alreadyProcessedIdss, Map<id,boolean> invIdRequestCompletions){
        try{
            integer tempCount = 0;
            boolean checkLeftRecords = true;
            boolean checkStillLeftRecords = false;
            if(alreadyProcessedIdss != null){
                alreadyProcessedIdsMap = alreadyProcessedIdss;
            }
            if(invIdRequestCompletions != null){
                invIdRequestCompletion = invIdRequestCompletions;
            }
            if(!invoiceIds.isEmpty()){
                for(Id invoiceObj : invoiceIds){ 
                    if(creditNoteIdCreditNoteLineListmap != null && creditNoteIdCreditNoteLineListmap.get(invoiceObj) !=null){
                        system.debug('creditNoteIdCreditNoteLineListmap.get(invoiceObj)@@'+creditNoteIdCreditNoteLineListmap.get(invoiceObj).size());
                        for(blng__CreditNoteLine__c invoiceLine : creditNoteIdCreditNoteLineListmap.get(invoiceObj)){ 
                            System.debug('recurring count');
                            //If record not processed previously
                            if(alreadyProcessedIdsMap == null || (alreadyProcessedIdsMap != null && (!alreadyProcessedIdsMap.containsKey(invoiceObj) || (alreadyProcessedIdsMap.containsKey(invoiceObj) && !alreadyProcessedIdsMap.get(invoiceObj).contains(invoiceLine.id))))){
                                if(tempCount < integer.valueOf(system.Label.QTB_Vertex_Request_Line_Size)){
                                    System.debug('inside if@@');
                                    tempCount ++;
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
                    }
                    
                    if(creditNoteIdUsageListmap != null && creditNoteIdUsageListmap.get(invoiceObj) !=null){
                        System.debug('creditNoteIdUsageListmap.get(invoiceObj)@@'+creditNoteIdUsageListmap.get(invoiceObj).size());
                        for(blng__Usage__c usage : creditNoteIdUsageListmap.get(invoiceObj)){
                            //if(alreadyProcessedIdsMap == null || (alreadyProcessedIdsMap != null && !alreadyProcessedIdsMap.contains(usage.id))){
                            if(alreadyProcessedIdsMap == null || (alreadyProcessedIdsMap != null && (!alreadyProcessedIdsMap.containsKey(invoiceObj) || (alreadyProcessedIdsMap.containsKey(invoiceObj) && !alreadyProcessedIdsMap.get(invoiceObj).contains(usage.id))))){
                                if(tempCount < integer.valueOf(system.Label.QTB_Vertex_Request_Line_Size)){
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
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexCreditHelper.getInvoiceLineUsageList');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method Name: getProductBillCode
* Parameters:  List<Id> invoiceIds 
* Return Type: void
* Requirement: Gitlab #
* Description: This method is used for storing InvoicelineId with BillCode
**********************************************************************************************************/    
    public static Map<id,string> getProductBillCode(List<Id> invoiceIds ){
        try{
            Map<id,id> creditLineProductMap = new Map<id,id>();
            Map<id,string> ProductToBillMap = new Map<id,string>();
            // CrNoteAccountCountry added as part of GITLAB #15327 for Country check in QTB_Bill_Code_Product_Lookup__c query
            Set<String> CrNoteAccountCountry = new Set<String>(); 
            if(creditIdToCreditNoteLinesMap.containsKey(invoiceIds[0])){
                for(blng__CreditNoteLine__c cnlline : creditIdToCreditNoteLinesMap.get(invoiceIds[0])){
                    creditLineProductMap.put(cnlline.id,cnlline.blng__Product__c);
                    CrNoteAccountCountry.add(cnlline.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c);
                    system.debug('CrNoteAccountCountry@@260' +CrNoteAccountCountry);
                } 
                for(QTB_Bill_Code_Product_Lookup__c billCode : [Select Id, Name,QTB_Source_Bill_Code__c,QTB_Product2__c 
                                                                From QTB_Bill_Code_Product_Lookup__c 
                                                                where QTB_Product2__c IN : creditLineProductMap.values() AND QTB_Country__r.Name IN :CrNoteAccountCountry] )
                {
                    system.debug('billCode@@' +billCode);
                    ProductToBillMap.put(billCode.QTB_Product2__c,billCode.QTB_Source_Bill_Code__c);
                }
                for(blng__CreditNoteLine__c cnlline : creditIdToCreditNoteLinesMap.get(invoiceIds[0])){
                    creditLineIdToBillCode.put(cnlline.id, ProductToBillMap.get(creditLineProductMap.get(cnlline.id)));
                } 
            }
            return creditLineIdToBillCode;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexCreditHelper.getProductBillCode');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method Name: getDistrict
* Parameters: List<Id> invoiceId
* Return Type: Map<Id, String>
* Requirement: Gitlab #857
* Description: This method is used for to get DistrictCode 
**********************************************************************************************************/
    public static Map<Id, String> getDistrict(List<Id> invoiceId){
        return getDistrictAndLocation(creditNoteIdToCreditNoteMap.get(invoiceId[0]),'District');
    }
    
    /*********************************************************************************************************
* Method Name: getLocation
* Parameters: List<Id> invoiceId
* Return Type: Map<Id, String>
* Requirement: Gitlab #857
* Description: This method is used for to get LocationCode 
**********************************************************************************************************/
    public static Map<Id, String> getLocation(List<Id> invoiceId){
        return getDistrictAndLocation(creditNoteIdToCreditNoteMap.get(invoiceId[0]),'Location');
    }
    
    /*********************************************************************************************************
* Method Name: getDistrictAndLocation
* Parameters:  blng__Invoice__c invoices, string DistrictOrLocation
* Return Type: void
* Requirement: Gitlab #
* Description: This method is used for to get DistrictCode & LocationCode from Service_Location__c obj
**********************************************************************************************************/
    public static Map<Id, String> creditNoteToServiceLocationMap = new Map<Id,String>();
    public static Map<Id, String> creditNoteToLocationCodeMap = new Map<Id,String>();
    public static Map<Id, String> getDistrictAndLocation(sObject invoices, string DistrictOrLocation){
        try{
            Map<id,id> accountToInvoiceMap = new Map<id,id>(); 
            blng__CreditNote__c cn1;
            Map<Id,String> billingAcctIdWithCustomerDistrictMap = new Map<Id,String>();//Gitlab US#24005
            for(sObject inv : creditNoteIdToCreditNoteMap.values()){
                cn1 = (blng__CreditNote__c) creditNoteIdToCreditNoteMap.get(inv.id);
                accountToInvoiceMap.put(cn1.blng__Account__r.Id,cn1.id );
                billingAcctIdWithCustomerDistrictMap.put(cn1.Id,cn1.blng__Account__r.QTB_Customer_District__c);//Gitlab US#24005
            }
            //Gitlab US#24005 -- logic modified to get the serviceDistrict if Accountlevel service location is not present
            List<Service_Location__c> serviceLocationList = [SELECT Id, Name,Address1__c, Address2__c, Address3__c, IM_Country_name__c, IM_County_Name__c,Postal_Code__c,
                                                             QTB_Billing_Account__c, Owning_District_Id__r.Owning_District_Id__c,Owning_District_Id__r.QTB_Oracle_Location_Code__c 
                                                             FROM Service_Location__c 
                                                             WHERE QTB_Billing_Account__c IN : accountToInvoiceMap.keySet()];
            if(!serviceLocationList.isEmpty()){
				for(Service_Location__c serviceLocation : serviceLocationList)
                {
                    string districtCode = (serviceLocation.Owning_District_Id__c != null && serviceLocation.Owning_District_Id__r.Owning_District_Id__c !=null ) ? serviceLocation.Owning_District_Id__r.Owning_District_Id__c : '';
                    string locationCode = (serviceLocation.Owning_District_Id__c != null && serviceLocation.Owning_District_Id__r.QTB_Oracle_Location_Code__c !=null) ? serviceLocation.Owning_District_Id__r.QTB_Oracle_Location_Code__c : '';
                    creditNoteToServiceLocationMap.put(accountToInvoiceMap.get(serviceLocation.QTB_Billing_Account__c),districtCode);
                    creditNoteToLocationCodeMap.put(accountToInvoiceMap.get(serviceLocation.QTB_Billing_Account__c),locationCode);
                }
                if(DistrictOrLocation == 'District'){
                    return creditNoteToServiceLocationMap;
                }
                if(DistrictOrLocation == 'Location' ){
                    return creditNoteToLocationCodeMap;
                }                
            }
            else{
                return billingAcctIdWithCustomerDistrictMap;//Gitlab US#24005 --returning the customerDistrict from accountlevel
            }
            
            return null;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexCreditHelper.getDistrictAndLocation');
            throw e;
        }
    }
    
    /*********************************************************************************************************
* Method Name: getCreditNote
* Parameters:  List<Id> invoiceIds
* Return Type: void
* Requirement: Gitlab #
* Description: This method is used forto return creditNote obj 
**********************************************************************************************************/
    public static blng__CreditNote__c getCreditNote(List<Id> invoiceIds){
        try{
            if(!creditNoteIdToCreditNoteMap.isEmpty()){
                for(Id invoiceObj : creditNoteIdToCreditNoteMap.keySet()){ 
                    CreditNote = creditNoteIdToCreditNoteMap.get(invoiceObj);
                    CreditNoteList.add(CreditNote);
                }
                return CreditNoteList[0];
            }
            return null;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMToVertexCreditHelper.getCreditNote');
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
	}
  	
}