/*****************************************************************************************************
 * Class:   QTB_UpdateStorageServiceDatesOnInvBatch
 * Test: QTB_UpdateStorageServiceDatesBatch_Test
 * Author: Virtusa
 * Purpose: This is a Batch class to update the Date Fields in Invoice
 * Requirement:
 * Change History:
 * Developer     			Date           Description
 * -------------------------------------------------------------------------------------------
 * Parth(Virtusa)            18/07/2025     #32284 #32285updating Mrc dates and Service dates based on Storage Date on Invoice and Service Date on Invoice picklist field
along with above story moved the updateInvoiceMRCDates method from trigger to batch class as getting error 50000 limit error when doing bulk testing
     *******************************************************************************************************/
public class QTB_UpdateStorageServiceDatesOnInvBatch implements Database.Batchable<SObject>{
    
    Public static final string className = QTB_UpdateStorageServiceDatesOnInvBatch.class.getName();
    public static final String STATUS_DRAFT = 'Draft';
    public static final String NONE = 'None';
    Public static boolean throwExplicitException = false;
    Public String query;
    Set<ID> invidsSet = new Set<ID>();
    Set<ID> invSchedulerId = new Set<Id>();
    //Constructor for the class QTB_UpdateStorageServiceDatesOnInvBatch
    Public QTB_UpdateStorageServiceDatesOnInvBatch(Set<ID> invoiceIdsSet,set<Id>invoiceSchedulerIdSet) {
        invidsSet = invoiceIdsSet;
        invSchedulerId = invoiceSchedulerIdSet;
        query = 'SELECT ID,QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,'+
            'QTB_Service_End_Date__c,blng__Account__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,'+
            'blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,'+
            'blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,'+
            'blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c '+
            'FROM blng__Invoice__c WHERE ID IN :invidsSet AND blng__InvoiceStatus__c = :STATUS_DRAFT AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND '+
            'blng__Account__r.QTB_Bill_Forward_Type__c != :NONE AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null';
    }
    /*********************************************************************************************************
    Method Name: start
        Parameters: Database.BatchableContext
        Return Type: Database.QueryLocator
        Requirement:
        Description: Fetch required records
         **********************************************************************************************************/
    Public Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
    Method Name: execute
        Parameters: Database.BatchableContext,List<blng__Invoice__c> updatedInvoice
        Return Type: void
        Requirement:
        Description: This is having the Functionality to update updateInvoiceMRCDates of Invoice MRC start AND End End date AND Service Start AND End date
        based on Account - Billing Frequency AND Account - Billing Forward type AND Invoice Scheduler Legal Entity AND Invoice period selected
         **********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<blng__Invoice__c> updatedInvoice) {
        try{
            if(QTB_UpdateStorageServiceDatesOnInvBatch.throwExplicitException){
                throw new NullPointerException();
            }
            if(!updatedInvoice.isEmpty()){
                system.debug('updatedInvoice -'+updatedInvoice);
                List<ID> usgSummidList = new List<ID>();
                List<ID> usgSummProdSalesidList = new List<ID>(); //#28758  Created a List to store product Sales Summary ids
                Map<ID,Date> dateCalMap = new Map<ID,Date>();
                Map<ID,Date> invDateCalMap = new Map<ID,Date>();
                Map<ID,Date> invDateCalMapMin = new Map<ID,Date>(); //30166 Added Map to store Max Source Service Date as key value and ID for respective usage summary
                Map<ID,Date> invDateCalMapMax = new Map<ID,Date>();
                Map<ID,Date> invDateCalMapMinMRC = new Map<ID,Date>(); //30146 Added Map to store Min and Max Storage Dates as key value and ID for respective usage summary
                Map<ID,Date> invDateCalMapMaxMRC = new Map<ID,Date>();
                Map<ID,Date> usageStartDateCalMap = new Map<ID,Date>();  //27496 Adding one Map to store the Minimum Start date as key value AND ID as respective Usage Summary
                Map<ID,Date> usageEndDateCalMap = new Map<ID,Date>(); //27496 Adding one Map to store the Max End date as key value AND ID as respective Usage Summary
                Map<ID,Date> usageServStartDateCalMap = new Map<ID,Date>(); //30166 Adding usageServStartDateCalMap and usageServEndDateCalMap to store the Min Service Start and End date as key value AND ID as respective Usage Summary
                Map<ID,Date> usageServEndDateCalMap = new Map<ID,Date>();
                Map<ID,Date> usageStorageStartDateCalMap = new Map<ID,Date>(); //30146 Adding usageStorageStartDateCalMap and usageStorageEndDateCalMap to store the Min Storage Start and Max End date MRC as key value AND ID as respective Usage Summary
                Map<ID,Date> usageStorageEndDateCalMap = new Map<ID,Date>();
                Map<ID,Date> taxPeriodStartDateMap = new Map<ID,Date>();
                Map<ID,Date> taxPeriodEndDateMap = new Map<ID,Date>();
                Map<ID,blng__Invoiceline__c> usageSummryToInvLineMap = new Map<ID,blng__Invoiceline__c>();
                Date firstDayOfMonth;
                List<blng__Invoice__c> listToUpdate = new List<blng__Invoice__c>();
                //#28758 Added Billing Account type field from Account level to know whether its Product Sales or Existing
                List<blng__Invoiceline__c> updatedInvoiceLinesList = [SELECT ID, blng__Invoice__c, blng__UsageSummary__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Type__c, 
                                                                      blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c, blng__Invoice__r.QTB_InvoiceProductType__c,
                                                                      QTB_ProductType__c FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN :updatedInvoice ]; //Gitlab US#29101 -- added
                system.debug('updatedInvoiceLinesList Size - '+updatedInvoiceLinesList.size());
                //Adding usage summary ID to List AND Usage summary AND Inv lines into Map
                for(blng__Invoiceline__c invline : updatedInvoiceLinesList){
                    //#27494 Added if loop to avoid null Pointer Exception
                    //#28758 Added if AND Else if conditions to diff from whether its Product Sales or not
                    if(invline.blng__UsageSummary__c != null)
                    {
                        if(invline.blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Type__c != 'Product Sales'){
                            usgSummidList.add(invline.blng__UsageSummary__c);
                        } else{
                            usgSummProdSalesidList.add(invline.blng__UsageSummary__c);
                        }
                        usageSummryToInvLineMap.put(invline.blng__UsageSummary__c, invline); // 29101 merged if
                    }
                }
                //27494 Created List for handling Query More () Exception AND also added null checks for all queried as From Query
                //#28758 Added if AND Else if conditions to differenciate the product Sales AND Contionous Service AND also queried required fields only in both the queries
                if((usgSummidList != null && !usgSummidList.isEmpty()) || (usgSummProdSalesidList != null && !usgSummProdSalesidList.isEmpty())){
                    //#28758 Added both List check and its respective Service period data null check because this logic should work for both Product Sales AND Contious Service
                    for(blng__Usage__c usg :[SELECT ID,blng__UsageSummary__c,QTB_Service_Period_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Delivery_Date__c,
                                             blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,QTB_Product_Line__c,QTB_Storage_Type__c, blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c 
                                             FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usgSummidList OR blng__UsageSummary__c IN :usgSummProdSalesidList ])
                    {
                        system.debug('usg.QTB_Service_Period_Date__c - '+usg.QTB_Service_Period_Date__c);
                        system.debug('usg.QTB_Start_Date_MRC__c - '+usg.QTB_Start_Date_MRC__c);
                        system.debug('usg.QTB_End_Date_MRC__c - '+usg.QTB_End_Date_MRC__c);
                        if(dateCalMap != null && !dateCalMap.isEmpty() && dateCalMap.containsKey(usg.blng__UsageSummary__c) && usg.QTB_Service_Period_Date__c != null && dateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Service_Period_Date__c){
                            dateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Service_Period_Date__c);
                        }
                        else if(dateCalMap != null && usg.QTB_Service_Period_Date__c != null && !dateCalMap.containsKey(usg.blng__UsageSummary__c)){
                            dateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Service_Period_Date__c);
                        }
                        // #27494 getting the Min AND Max Dates FROM respective usage Summary Usages (Multiple Usages to same Usage Summary Scenario) AND adding to Map as Usage Summary as Key AND date as value
                        //when Source Servie Date != null AND Start Date AND MRC dates == null
                        //#28758 Added if loop to Bypass the below logic for Product Sales
                        if(usgSummidList!= null && !usgSummidList.isEmpty()){
                            //when Source Servie Date != null AND Start Date AND MRC dates == null
                            if(usg.QTB_Source_Service_Date__c != null &&  usg.QTB_Start_Date_MRC__c == null && usg.QTB_End_Date_MRC__c == null){
                                //Stroing min of QTB_Source_Service_Date__c
                                if(usageStartDateCalMap != null && !usageStartDateCalMap.isEmpty() && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Source_Service_Date__c){
                                    usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                }
                                else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                    usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                }
                                //Stroing max of QTB_Source_Service_Date__c
                                if(usageEndDateCalMap != null && !usageEndDateCalMap.isEmpty() && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_Source_Service_Date__c){
                                    usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                }
                                else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                    usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                }
                            }
                            //#27494 when Start date AND End Dare MRC != null AND Source Service Date == null
                            else if(usg.QTB_Start_Date_MRC__c != null && usg.QTB_End_Date_MRC__c != null && usg.QTB_Source_Service_Date__c == null)
                            {
                                //Stroing min of QTB_Start_Date_MRC__c
                                if(usageStartDateCalMap != null && !usageStartDateCalMap.isEmpty() && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Start_Date_MRC__c){
                                    usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                                }
                                else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                    usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                                }
                                //Stroing max of QTB_End_Date_MRC__c
                                if(usageEndDateCalMap != null && !usageEndDateCalMap.isEmpty() && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_End_Date_MRC__c){
                                    usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                                }
                                else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                    usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                                }
                            }
                            //#27494 when Both Source Servie Date != null && Start AND End MRC Dates != null
                            else if(usg.QTB_Start_Date_MRC__c != null && usg.QTB_End_Date_MRC__c != null && usg.QTB_Source_Service_Date__c != null){
                                // Storing the minimum start date: Choose the earlier of MRC Start or Source Service Start
                                if(usageStartDateCalMap != null && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                    Date existingStartDate = usageStartDateCalMap.get(usg.blng__UsageSummary__c);
                                    Date newStartDate = usg.QTB_Start_Date_MRC__c <= usg.QTB_Source_Service_Date__c ? usg.QTB_Start_Date_MRC__c : usg.QTB_Source_Service_Date__c;
                                    if (existingStartDate > newStartDate){
                                        usageStartDateCalMap.put(usg.blng__UsageSummary__c, newStartDate);
                                    }
                                }else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                    usageStartDateCalMap.put(usg.blng__UsageSummary__c, usg.QTB_Start_Date_MRC__c <= usg.QTB_Source_Service_Date__c ? usg.QTB_Start_Date_MRC__c : usg.QTB_Source_Service_Date__c);
                                }
                                
                                // Storing the maximum end date: Choose the later of MRC End or Source Service End
                                if(usageEndDateCalMap != null && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c))
                                {
                                    Date existingEndDate = usageEndDateCalMap.get(usg.blng__UsageSummary__c);
                                    Date newEndDate = usg.QTB_End_Date_MRC__c >= usg.QTB_Source_Service_Date__c ? usg.QTB_End_Date_MRC__c : usg.QTB_Source_Service_Date__c;
                                    if (existingEndDate < newEndDate){
                                        usageEndDateCalMap.put(usg.blng__UsageSummary__c, newEndDate);
                                    }
                                }else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                    
                                    usageEndDateCalMap.put(usg.blng__UsageSummary__c, usg.QTB_End_Date_MRC__c >= usg.QTB_Source_Service_Date__c ? usg.QTB_End_Date_MRC__c : usg.QTB_Source_Service_Date__c);
                                }
                            }
                        }
                        else if(usgSummProdSalesidList!= null && !usgSummProdSalesidList.isEmpty() && usg.QTB_Delivery_Date__c != null){
                            //Stroing min of QTB_Delivery_Date__c
                            if(usageStartDateCalMap != null && !usageStartDateCalMap.isEmpty() && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Delivery_Date__c){
                                usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                            }
                            else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                            }
                            //Stroing max of QTB_Delivery_Date__c
                            if(usageEndDateCalMap != null && !usageEndDateCalMap.isEmpty() && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_Delivery_Date__c){
                                usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                            }
                            else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                            }
                        }
                        //30166
                        //30166 to get minimum and maximum Source service period dates where Storage/Service Period Range = true and Product line! = Storage
                        //32285 - considering Service Date on Invoice picklist value for service date calculation
                        if(usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Service Range' &&
                            usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c != null && usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c != 'Storage' &&
                        usg.QTB_Source_Service_Date__c != null ){
                            //30166 Stroing min of QTB_Source_Service_Date__c
                            if(usageServStartDateCalMap != null && !usageServStartDateCalMap.isEmpty() && usageServStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageServStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Source_Service_Date__c){
                                usageServStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                            }
                            else if(usageServStartDateCalMap != null && !usageServStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                usageServStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                            }
                            //30166 Stroing max of QTB_Source_Service_Date__c
                            if(usageServEndDateCalMap != null && !usageServEndDateCalMap.isEmpty() && usageServEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageServEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_Source_Service_Date__c){
                                usageServEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                            }
                            else if(usageServEndDateCalMap != null && !usageServEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                usageServEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                            }
                        }
                        //32285 - considering Storage Date on Invoice picklist value for Storage date calculation
                        if(usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c != null && usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c == 'Storage Range' &&
                            usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c != null && usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c == 'Storage' &&
                        usg.QTB_Storage_Type__c != null && usg.QTB_Storage_Type__c == 'Regular' ){
                            //30166 Stroing min of QTB_Start_Date_MRC__c
                            if(usageStorageStartDateCalMap != null && !usageStorageStartDateCalMap.isEmpty() && usageStorageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usg.QTB_Start_Date_MRC__c != null && usageStorageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Start_Date_MRC__c){
                                usageStorageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                            }
                            else if(usageStorageStartDateCalMap != null && usg.QTB_Start_Date_MRC__c != null && !usageStorageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                usageStorageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                            }
                            //30166 Stroing max of QTB_End_Date_MRC__c
                            if(usageStorageEndDateCalMap != null && !usageStorageEndDateCalMap.isEmpty() && usageStorageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usg.QTB_End_Date_MRC__c != null && usageStorageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_End_Date_MRC__c){
                                usageStorageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                            }
                            else if(usageStorageEndDateCalMap != null && usg.QTB_End_Date_MRC__c != null && !usageStorageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                usageStorageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                            }
                        }
                    }
                    
                    //Add invoice lines to List invLList that are available in dateCalMap Map which contains usage summary ID AND minimum date from related usages
                    List<blng__InvoiceLine__c> invLList = new List<blng__InvoiceLine__c>();
                    //#27494 Added the bewlow Set to Add the usage Summaries respective scenarios
                    Set<ID> usageSummaryids = new Set<ID>();
                    if(!usageStartDateCalMap.isEmpty()|| (usageStartDateCalMap.size() > 0 && dateCalMap.size() > 0)){
                        usageSummaryids = usageStartDateCalMap.keyset();
                    }
                    else if(!usageEndDateCalMap.isEmpty()|| (usageEndDateCalMap.size() > 0 && dateCalMap.size() > 0)){
                        usageSummaryids = usageEndDateCalMap.keyset();
                    }
                    else if(!dateCalMap.isEmpty()){
                        usageSummaryids = dateCalMap.keyset();
                    }
                    for(ID usid : usageSummaryids){
                        if (usageSummryToInvLineMap.containskey(usid)){
                            invLList.add(usageSummryToInvLineMap.get(usid));
                        }
                    }
                    
                    //Loop through invoice lines to get minimum service date on invoice from related usage summary
                    for(blng__InvoiceLine__c invo : invLList){
                        if(invDateCalMap.containsKey(invo.blng__Invoice__c) && dateCalMap.containsKey(invo.blng__UsageSummary__c)){
                            //Get minimum service date on invoice by iterating through AND comparing dates on all related invoice lines.
                            invDateCalMap.put(invo.blng__Invoice__c, invDateCalMap.get(invo.blng__Invoice__c) < dateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMap.get(invo.blng__Invoice__c) : dateCalMap.get(invo.blng__UsageSummary__c));
                        }
                        else if(dateCalMap.containsKey(invo.blng__UsageSummary__c)){
                            invDateCalMap.put(invo.blng__Invoice__c, dateCalMap.get(invo.blng__UsageSummary__c));
                        }
                        //30166 Calculate minimum source service date from service usages.
                        if(invo.QTB_ProductType__c!='Storage'){
                            if(invDateCalMapMin.containsKey(invo.blng__Invoice__c)){
                                //Get minimum source service date from service usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMin.put(invo.blng__Invoice__c, invDateCalMapMin.get(invo.blng__Invoice__c) < usageServStartDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMin.get(invo.blng__Invoice__c) : usageServStartDateCalMap.get(invo.blng__UsageSummary__c));
                            } else{
                                invDateCalMapMin.put(invo.blng__Invoice__c, usageServStartDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                            //30166 Calculate maximum source service date from service usages.
                            if(invDateCalMapMax.containsKey(invo.blng__Invoice__c)){
                                //Get maximum source service date from service usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMax.put(invo.blng__Invoice__c, invDateCalMapMax.get(invo.blng__Invoice__c) > usageServEndDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMax.get(invo.blng__Invoice__c) : usageServEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }else{
                                invDateCalMapMax.put(invo.blng__Invoice__c, usageServEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                        }
                        
                        //30146 Calculate minimum storage date on invoice from multiple usage summaries which has multiple usages.
                        if(invo.QTB_ProductType__c == 'Storage' && usageStorageStartDateCalMap.containsKey(invo.blng__UsageSummary__c) && usageStorageEndDateCalMap.containsKey(invo.blng__UsageSummary__c)){
                            if(invDateCalMapMinMRC.containsKey(invo.blng__Invoice__c)) {
                                //Get minimum storage date from storage usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMinMRC.put(invo.blng__Invoice__c, invDateCalMapMinMRC.get(invo.blng__Invoice__c) < usageStorageStartDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMinMRC.get(invo.blng__Invoice__c) : usageStorageStartDateCalMap.get(invo.blng__UsageSummary__c));
                            } else{
                                invDateCalMapMinMRC.put(invo.blng__Invoice__c, usageStorageStartDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                            //30146 Calculate maximum storage date from storage usages.
                            if(invDateCalMapMaxMRC.containsKey(invo.blng__Invoice__c)){
                                //Get maximum storage date from storage usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMaxMRC.put(invo.blng__Invoice__c, invDateCalMapMaxMRC.get(invo.blng__Invoice__c) > usageStorageEndDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMaxMRC.get(invo.blng__Invoice__c) : usageStorageEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }else{
                                invDateCalMapMaxMRC.put(invo.blng__Invoice__c, usageStorageEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                        }
                        
                        //#27494 Putting the Values of Invocie AND its Date to be stamped on tax period Start Date
                        if(usageStartDateCalMap.size() >0 && taxPeriodStartDateMap.containsKey(invo.blng__Invoice__c)){
                            //Get minimum service date on invoice by iterating through AND comparing dates on all related invoice lines.
                            taxPeriodStartDateMap.put(invo.blng__Invoice__c, taxPeriodStartDateMap.get(invo.blng__Invoice__c) <= usageStartDateCalMap.get(invo.blng__UsageSummary__c) ? taxPeriodStartDateMap.get(invo.blng__Invoice__c) : usageStartDateCalMap.get(invo.blng__UsageSummary__c));
                        } else{
                            taxPeriodStartDateMap.put(invo.blng__Invoice__c, usageStartDateCalMap.get(invo.blng__UsageSummary__c));
                        }
                        //#27494 Putting the Values of Invocie AND its Date to be stamped on tax period End Date
                        if(usageEndDateCalMap.size() >0 && taxPeriodEndDateMap.containsKey(invo.blng__Invoice__c)) {
                            //Get minimum service date on invoice by iterating through AND comparing dates on all related invoice lines.
                            taxPeriodEndDateMap.put(invo.blng__Invoice__c, taxPeriodEndDateMap.get(invo.blng__Invoice__c) >= usageEndDateCalMap.get(invo.blng__UsageSummary__c) ? taxPeriodEndDateMap.get(invo.blng__Invoice__c) : usageEndDateCalMap.get(invo.blng__UsageSummary__c));
                        } else{
                            taxPeriodEndDateMap.put(invo.blng__Invoice__c, usageEndDateCalMap.get(invo.blng__UsageSummary__c));
                        }
                    }
                    System.debug(invDateCalMap);
                    for(blng__Invoice__c inl: updatedInvoice){
                        //if Service Date on usage is null, calculate MRC AND service dates based on Invoice Period
                        System.debug(invDateCalMap);
                        if(invDateCalMap.get(inl.ID) == null){
                            //GITLAB US #25356 (Credit/Rebill Billnow)
                            firstDayOfMonth = inl.QTB_Invoice_Period__r.blng__PeriodEndDate__c.toStartOfMonth();
                        } else{
                            //Else calculate MRC AND service dates based on minimum service date on usages
                            firstDayOfMonth = invDateCalMap.get(inl.ID);
                        }
                        //#27494 Stampage of values based upon mp what we got
                        if(taxPeriodStartDateMap.size() > 0 && taxPeriodStartDateMap.containsKey(inl.ID)){
                            inl.QTB_Tax_Period_Start_Date__c = taxPeriodStartDateMap.get(inl.ID);
                        }
                        if(taxPeriodEndDateMap.size() > 0 && taxPeriodEndDateMap.containsKey(inl.ID)){
                            inl.QTB_Tax_Period_End_Date__c = taxPeriodEndDateMap.get(inl.ID);
                        }
                        // #32284, #32285 - added new picklist value on legal entity based on which need to calculate dates
                        if((inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c  != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c == 'Regular Storage') ||
                        (inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Invoice Period')){ //#30146 and #30166
                            if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Monthly')) {//29101 added equalsIgnoreCase
                                if (inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {  //29101 added equalsIgnoreCase
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                } else{
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(2).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                }
                            }
                            else if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Quarterly')) { //29101 added equalsIgnoreCase
                                if(inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {  //29101 added equalsIgnoreCase
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth.addmonths(-2),firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                } else{
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(4).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                }
                            }
                            else if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Semiannual')) { //29101 added equalsIgnoreCase
                                if (inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {  //29101 added equalsIgnoreCase
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth.addmonths(-5),firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                } else{
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(7).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                }
                            }
                            else if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Annual')) {//29101 added equalsIgnoreCase
                                if (inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {//29101 added equalsIgnoreCase
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth.addmonths(-11),firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                } else{
                                    QTB_InvoiceHelper.updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(13).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                }
                            }
                        }
                        
                        if(inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Service Range'){// 32285
                            inl.QTB_Service_Start_Date__c = invDateCalMapMin.get(inl.ID);
                            inl.QTB_Service_End_Date__c = invDateCalMapMax.get(inl.ID);
                        }
                        if(inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c == 'Storage Range'){// 32284
                            //30146: Updating Storage Period dates for Invoices with Regular Storage Type
                            if(invDateCalMapMinMRC.containsKey(inl.ID) && invDateCalMapMaxMRC.containsKey(inl.ID)){
                                inl.QTB_Start_Date_MRC__c = invDateCalMapMinMRC.get(inl.ID);
                                inl.QTB_End_Date_MRC__c = invDateCalMapMaxMRC.get(inl.ID);
                            }else{
                                inl.QTB_Start_Date_MRC__c = null;
                                inl.QTB_End_Date_MRC__c = null;
                            }
                        }
                        // 33924 Service Period customization for ANZ, serice start date and end date to be calculated based on billing frequency if QTB_Service_Date_on_Invoice__c on legal entity is Billing Frquency
                        if(inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Billing Frequency'){
                            inl.QTB_Service_End_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(1).addDays(-1);
                            if(inl.blng__Account__r.QTB_Billing_Frequency__c == 'Annual'){
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(-11);
                            }else if(inl.blng__Account__r.QTB_Billing_Frequency__c == 'Semiannual'){
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(-5);
                            }else if(inl.blng__Account__r.QTB_Billing_Frequency__c == 'Quarterly'){
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(-2);
                            }else{
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth();
                            }
                        }
                        //28275 - if custom lable contains legal entity country than based on invoice product type update service date AND storage dates
                        if(System.label.QTB_ServiceTypeDates_Countries_list.containsIgnoreCase(inl.QTB_LegalEntityCountry__c)){
                            // if invoice contains only storage product than Service period should be blank AND if invoice contains only services type
                            // of product than Storage period should be bland AND if invoice have mixed type of products than no change
                            if(inl.QTB_InvoiceProductType__c==('Storage')){ //29101 added equalsIgnoreCase
                                inl.QTB_Service_Start_Date__c = null;
                                inl.QTB_Service_End_Date__c = null;
                            }
                            else if(inl.QTB_InvoiceProductType__c==('Services')){//29101 added equalsIgnoreCase
                                inl.QTB_Start_Date_MRC__c = null;
                                inl.QTB_End_Date_MRC__c   = null;
                            }
                        }
                        listToUpdate.add(inl);
                    }
                }
                invidsSet.clear();
                usgSummidList.clear();
                usgSummProdSalesidList.clear();
                dateCalMap.clear();
                invDateCalMap.clear();
                invDateCalMapMin.clear();
                invDateCalMapMax.clear();
                invDateCalMapMinMRC.clear();
                invDateCalMapMaxMRC.clear();
                usageStartDateCalMap.clear();
                usageEndDateCalMap.clear();
                usageServStartDateCalMap.clear();
                usageServEndDateCalMap.clear();
                usageStorageStartDateCalMap.clear();
                usageStorageEndDateCalMap.clear();
                taxPeriodStartDateMap.clear();
                taxPeriodEndDateMap.clear();
                usageSummryToInvLineMap.clear();
                //QTB_RecursiveHandlerCheck.afterUpdateCheck_updateInvoiceMRCDates = false; // US #31275 defect fix
                update listToUpdate;
            }
            
        } catch (Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog
                (
                e.getLineNumber(),
            e.getStackTraceString(),
            e.getMessage(),
            e.getTypeName(),
            CLASSNAME
                );
        }
    }
    /*********************************************************************************************************
    Method Name: finish
        Parameters: Database.BatchableContext
        Return Type: void
        Requirement:
        Description: No action to be taken
         **********************************************************************************************************/
    Public void finish(Database.BatchableContext BC) {
        
        system.debug('in finish==========');
        String errorIds = '';
        try {
            if (QTB_UpdateStorageServiceDatesOnInvBatch.throwExplicitException) {throw new NullPointerException();}
            //#33490 - updating invoice run complete to true, if all chunks got completed
            AsyncApexJob jobStatus = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId()];
            if (jobStatus.NumberOfErrors == 0) {
                /*// Success! All chunks completed without a batch-halting error.
                List<blng__InvoiceScheduler__c>invSchLst = new List<blng__InvoiceScheduler__c>();
                for(Id invs :invSchedulerId){
                    blng__InvoiceScheduler__c invSch = new blng__InvoiceScheduler__c(Id = invs,QTB_InvoiceRunCompleted__c  = true);
                    invSchLst.add(invSch);
                }
                // disabling the trigger to bypass the invoice scheduler validation error that Enter a Start Date Time equal to or later than today.: [blng__StartDateTime__c]
                sbqq.TriggerControl.disable();
                Update invSchLst;
                sbqq.TriggerControl.enable();*/
                Integer size = Integer.ValueOf(System.Label.QTB_TaxOverrideAmountCalculationBatch_Size);
                Database.executeBatch(new QTB_TaxOverrideAmountCalculationBatch(invidsSet,invSchedulerId), size);
            }
        }
        catch (exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)errorIds = errorIds.substring(0, 100000);
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className);
        }
    }
    
}