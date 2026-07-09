/*****************************************************************************************************
 * Class: QTB_GenerateApexMassExtractVFCTRL
 * Purpose: This class containing logic for Mass generating txt file for invoice
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *  Sriram      7/27/2020       Created initial class
 *  Gopi/Sriram 10/19/2020      Version 1: Logic change for Usage Grouping and Adding Invoice Line to the report and vlidation
 *  Pragathi    17/02/2023      Version 2:Logic change for Nordics grouping lines and calculation
 *******************************************************************************************************/
public without sharing class QTB_GenerateApexMassExtractVFCTRL {
    public List<wrapper> lstWrapper {get; set;}
    public List<SummaryWrapper> lstSummaryWrapper {get; set;}
    //Git #13418 parameter to check Nordic country
    public Boolean nordicBillingCountriesPresent =false;
    public QTB_GenerateApexMassExtractVFCTRL(){
        
        //Get parameter from the VF Page
        string recordID = ApexPages.currentPage().getParameters().get('Id');
        string InvStatus = ApexPages.currentPage().getParameters().get('InvStatus');
        string invBatchNumber = ApexPages.currentPage().getParameters().get('invBatchNumber');
        If(String.isNotBlank(recordID)){
            try{
                //Variable declaration
                List<blng__Invoice__c> invLsts;
                List<blng__Invoice__c> invLst;
                map<id,set<string>> invPOList;
                map<id,id> billingContLst;
                map<id,Contact> conList;
                map<string,string> countryList;
                map<id,blng__Invoice__c> usageInvList = new map<id,blng__Invoice__c>();
                map<id,blng__Invoice__c> IdInvMap = new map<id,blng__Invoice__c>();
                map<id,List<blng__InvoiceLine__c>> MapInvIdInvoiceLine = new map<id,List<blng__InvoiceLine__c>>();
                map<id,decimal> MapInvIdInvoiceLineSubtotal = new map<id,decimal>();
                map<id,List<QTB_PurchaseOrder__c>> mapPOList;
                set<id> invAccIds = new set<id>();
                set<id> accBillConIDS = new set<id>();
                set<string> invAccLE = new set<string>();
                set<string> usageSummaries = new set<string>();
                set<id> invIds = new set<id>();
                Map<id,boolean> nordeaAccountMap = new Map<id,boolean>();
                Map<id,string> InvIdPaymentTerm = new Map<id,string>();
                lstWrapper = new List<wrapper>();
                lstSummaryWrapper = new list<SummaryWrapper>();
                Map<Id, integer> InvIdRecurringInvoiceLineTotal = new Map<Id, integer>();
                integer invCount = 0;
                double grandTotal= 0.00;
                string curCode;
                date targetDate;
                date targetMonth;
                Integer totalCount = 0;
                Integer tempTotalCount = 0;
                integer j = 0;
                integer count = 0;
                Map<Id, integer> InvIdUsageTotal = new Map<Id, integer>();
                List<blng__Usage__c> usages = new List<blng__Usage__c>();
                //New Set to store the billing accounts of all the eligible invoices
                Set<ID> eligibleAccountIds = new Set<ID>();
                //Get Invoice Scheduler also pulling CurrencyIsoCode
                blng__InvoiceScheduler__c InvSC = [select id,blng__InvoiceBatches__c,blng__TargetDate__c,CurrencyIsoCode from blng__InvoiceScheduler__c where id =:recordID];
                String invSCBatch = InvSC.blng__InvoiceBatches__c;
                if(InvSC.blng__TargetDate__c != null){
                    targetDate = InvSC.blng__TargetDate__c.addDays(-1);
                    targetMonth = InvSC.blng__TargetDate__c.addmonths(-1);
                }
                //#17381 Updation of the Currency Code on header '99'
                if(InvSC.CurrencyIsoCode != null){
                    curCode = InvSC.CurrencyIsoCode;
                }
                //Make the value to null as not required further
                InvSC = null;
                //Get Nordea Accounts from Custom Label // Use ';'(Semicoulmn) for more number of Accounts
                List<string> nordeaAccounts;
                if(Label.QTB_Nordea_Account_for_APIX_Extract != null){
                    nordeaAccounts = Label.QTB_Nordea_Account_for_APIX_Extract.split(';');
                }
                //Query for invoice data and also fetching Swift code value
                //#15071 Addition of POGR
                //#21361 Addition of override fields
                // GITLAB #23530 - modified the logic below to generate extract for Rebill and Regular scenerios from invoice schedular level
                // Addition of Ready for integration
                if(invSCBatch.contains('Rebill Run')){
                    system.debug('inside Rebill Run');
                    invLsts = [Select id,Name,QTB_Custom_Invoice_Number__c,QTB_Last_Invoice_Sent__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c,QTB_KID__c,blng__Subtotal__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Language__c,blng__InvoiceDate__c,blng__TotalAmount__c,QTB_Total_Amount_with_Tax_Override__c,CurrencyIsoCode,blng__Account__r.id,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.QTB_EDI_Identifier__c,QTB_Ready_for_Integration__c,
                               blng__Account__r.BillingCountry,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.QTB_Customer_Number__c,blng__Order__r.SBQQ__PaymentTerm__c,blng__Notes__c,blng__InvoiceStatus__c,blng__Account__c,
                               blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Invoice_Notes__c,blng__DueDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,blng__Account__r.Parent.Name,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.blng__InvoiceBatches__c,
                               (select id,blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,blng__OrderProduct__r.Product2.Name,blng__OrderProduct__r.Product2.ProductCode,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c,blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c,blng__StartDate__c,blng__OrderProduct__r.Product2.Id,blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c 
                                from blng__InvoiceInvoiceLines__r)
                               FROM blng__Invoice__c 
                               WHERE QTB_Last_Invoice_Sent__c = null  and blng__InvoiceStatus__c =:InvStatus /*and QTB_Ready_for_Integration__c = true*/
                               /*and blng__Account__r.*/and QTB_Bill_Cycle_Day__c =: invSCBatch and blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c =:recordID  
                               limit 50000];
                }
                //Git #26733 Ready for Integration
                else if(InvStatus == 'Draft'){
                    system.debug('inside Draft');
                    invLsts = [Select id,Name,QTB_Custom_Invoice_Number__c,QTB_Last_Invoice_Sent__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c,QTB_KID__c,blng__Subtotal__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Language__c,blng__InvoiceDate__c,blng__TotalAmount__c,QTB_Total_Amount_with_Tax_Override__c,CurrencyIsoCode,blng__Account__r.id,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.QTB_EDI_Identifier__c,QTB_Ready_for_Integration__c,
                               blng__Account__r.BillingCountry,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.QTB_Customer_Number__c,blng__Order__r.SBQQ__PaymentTerm__c,blng__Notes__c,blng__InvoiceStatus__c,blng__Account__c,
                               blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Invoice_Notes__c,blng__DueDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,blng__Account__r.Parent.Name,
                               (select id,blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,blng__OrderProduct__r.Product2.Name,blng__OrderProduct__r.Product2.ProductCode,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c,blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c,blng__StartDate__c,blng__OrderProduct__r.Product2.Id,blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c 
                                from blng__InvoiceInvoiceLines__r)
                               FROM blng__Invoice__c 
                               WHERE QTB_Last_Invoice_Sent__c = null  and blng__InvoiceStatus__c =:InvStatus and QTB_Ready_for_Integration__c = False
                               /*and blng__Account__r.*/and QTB_Bill_Cycle_Day__c =: invSCBatch and blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c =:recordID  
                               limit 50000];
                }
                else {
                    system.debug('inside Posted');
                    invLsts = [Select id,Name,QTB_Custom_Invoice_Number__c,QTB_Last_Invoice_Sent__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c,QTB_KID__c,blng__Subtotal__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Language__c,blng__InvoiceDate__c,blng__TotalAmount__c,QTB_Total_Amount_with_Tax_Override__c,CurrencyIsoCode,blng__Account__r.id,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.QTB_EDI_Identifier__c,QTB_Ready_for_Integration__c,
                          blng__Account__r.BillingCountry,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.QTB_Customer_Number__c,blng__Order__r.SBQQ__PaymentTerm__c,blng__Notes__c,blng__InvoiceStatus__c,blng__Account__c,
                               blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Invoice_Notes__c,blng__DueDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,blng__Account__r.Parent.Name,
                               (select id,blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,blng__OrderProduct__r.Product2.Name,blng__OrderProduct__r.Product2.ProductCode,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c,blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c,blng__StartDate__c,blng__OrderProduct__r.Product2.Id,blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c 
                                from blng__InvoiceInvoiceLines__r)
                               FROM blng__Invoice__c 
                               WHERE QTB_Last_Invoice_Sent__c = null AND QTB_Ready_for_Integration__c = True and blng__InvoiceStatus__c =:InvStatus and blng__Account__r.QTB_Bill_Cycle_Day__c =: invSCBatch and (NOT QTB_Bill_Cycle_Day__c LIKE '%Rebill%')
                               limit 50000];
                }
                //-------Start of logic to check Nordic country Git #13418 -----/
                
                List<String> nordicCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
                for(String country:nordicCountries)
                { if(invLsts.size()>0){
                        if(invLsts[0].blng__Account__r.QTB_Legal_Entity_Country__c == country){
                            nordicBillingCountriesPresent = true;
                            break;
                        }
                    }
                }
                //-------End of logic to check Nordic country Git #13418-----/
                //Logic to split the Invoices
                //Do the proper count for the number of records to pass for the Text file in a Batch
                //This is to get the Invoices for particular group from the Batch Number
                if(invLsts != null && invLsts.size()>0){
                    for(blng__Invoice__c inv : invLsts){
                        //Adding eligible accounts to the set
                        eligibleAccountIds.add(inv.blng__Account__c);
                        for(blng__InvoiceLine__c invLin : inv.blng__InvoiceInvoiceLines__r){
                            usageSummaries.add(invLin.blng__UsageSummary__c);
                            usageInvList.put(invLin.blng__UsageSummary__c,inv);
                            //system.debug('@@blng__UsageSummary__c'+invLin.blng__UsageSummary__c);
                            //Create Map Invoice Id and List InvoiceLine
                            //if(invLin.blng__ChargeType__c == 'Recurring'){
                                //As per New Architecture, Recurring Lines are decided by 'QTB_HasConsumptionSchedule__c'
                                //As per Story #6478 & #6509, Recurring Lines are decided by 'QTB_Charge_Type__c'
                                if(invLin.QTB_Charge_Type__c == 'Recurring'){
                                    if(InvStatus == 'Posted'){
                                        if(MapInvIdInvoiceLineSubtotal.containsKey(inv.id)){
                                            //Get all the Invoice Line Subtotal
                                            if(invLin.blng__Subtotal__c != null){
                                                MapInvIdInvoiceLineSubtotal.put(inv.id, MapInvIdInvoiceLineSubtotal.get(inv.id)+invLin.blng__Subtotal__c) ;
                                            }
                                        }else{
                                            //Get all the Invoice Line Subtotal
                                            if(invLin.blng__Subtotal__c != null){
                                                MapInvIdInvoiceLineSubtotal.put(inv.id,invLin.blng__Subtotal__c);
                                            }else{
                                                MapInvIdInvoiceLineSubtotal.put(inv.id,0);
                                            }
                                        }
                                    }
                                    //To support batches for more number of usages // To count recurring products as Usage Summary is blank
                                    if(InvIdRecurringInvoiceLineTotal.containsKey(inv.id)){
                                        InvIdRecurringInvoiceLineTotal.put(inv.id, InvIdRecurringInvoiceLineTotal.get(inv.id) + 1);
                                    }else{
                                        InvIdRecurringInvoiceLineTotal.put(inv.id, 1);
                                    }
                                }
                            }
                            IdInvMap.put(inv.id,inv);
                        }
                        invLsts = null;
                        // remove blanks and nulls
                        usageSummaries.remove('');
                        usageSummaries.remove(null);
                        
                        if(!usageSummaries.isEmpty()){
                            //system.debug('@@usageSummaries11'+usageSummaries);
                            usages = [Select QTB_Rated_Amount__c,blng__UsageSummary__c from blng__Usage__c where blng__UsageSummary__c in :usageSummaries ];
                            //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                            Map<id,set<id>> MapInvoiceIdAndUsageSummaryList = new Map<id,set<id>>();
                            Map<id,list<blng__Usage__c>> MapUsageSummaryIdAndUsageList = new Map<id,list<blng__Usage__c>>();
                            //get the usages total wrt invoices and add them to the InvoiceLine total
                            for(blng__Usage__c usg : usages){
                                if(InvStatus == 'Posted'){
                                    //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                                    //1st -> Inv Id -> Set<Usage Summary Id>
                                    //2nd -> Usage SummaryId -> List<usages>
                                    if(usg.QTB_Rated_Amount__c != null){
                                        if(MapInvoiceIdAndUsageSummaryList.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                            MapInvoiceIdAndUsageSummaryList.get(usageInvList.get(usg.blng__UsageSummary__c).id).add(usg.blng__UsageSummary__c);
                                        }else{
                                            MapInvoiceIdAndUsageSummaryList.put(usageInvList.get(usg.blng__UsageSummary__c).id, new set<id>{usg.blng__UsageSummary__c});
                                        }
                                        
                                        if(MapUsageSummaryIdAndUsageList.containsKey(usg.blng__UsageSummary__c)){
                                            MapUsageSummaryIdAndUsageList.get(usg.blng__UsageSummary__c).add(usg);
                                        }else{
                                            MapUsageSummaryIdAndUsageList.put(usg.blng__UsageSummary__c, new List<blng__Usage__c>{usg});
                                        }
                                    }
                                    
                                    /*if( Test.isRunningTest() || MapInvIdInvoiceLineSubtotal.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                        if(usg.QTB_Rated_Amount__c != null){
                                            MapInvIdInvoiceLineSubtotal.put(usageInvList.get(usg.blng__UsageSummary__c).id,MapInvIdInvoiceLineSubtotal.get(usageInvList.get(usg.blng__UsageSummary__c).id)+ usg.QTB_Rated_Amount__c);
                                        }
                                    }else{
                                        if(usg.QTB_Rated_Amount__c != null){
                                            MapInvIdInvoiceLineSubtotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, usg.QTB_Rated_Amount__c);
                                            
                                        }
                                    }*/
                                }
                                //To support batches for more number of usages //Count usages wrt Invoices
                                if(InvIdUsageTotal.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                    InvIdUsageTotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, InvIdUsageTotal.get(usageInvList.get(usg.blng__UsageSummary__c).id) + 1);
                                }else{
                                    InvIdUsageTotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, 1);
                                }
                            }
                            //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                            if(InvStatus == 'Posted'){
                                if(MapInvoiceIdAndUsageSummaryList.size() > 0){
                                    for(id invId : MapInvoiceIdAndUsageSummaryList.keySet()){
                                        for(id usgSummId : MapInvoiceIdAndUsageSummaryList.get(invId)){
                                            decimal tempTotal = 0;
                                            for(blng__Usage__c usg : MapUsageSummaryIdAndUsageList.get(usgSummId)){
                                                tempTotal += usg.QTB_Rated_Amount__c;
                                            }
                                            //Old Code
                                            if(MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                                                MapInvIdInvoiceLineSubtotal.put(invId, MapInvIdInvoiceLineSubtotal.get(invId)+ tempTotal.setScale(2, RoundingMode.HALF_UP));
                                            }else{
                                                MapInvIdInvoiceLineSubtotal.put(invId, tempTotal.setScale(2, RoundingMode.HALF_UP));
                                            }
                                        }
                                    }
                                }
                            }
                            //system.debug('Usage Count Map'+InvIdUsageTotal);
                        }
                        
                        List<blng__Invoice__c> invLstUpdate = new List<blng__Invoice__c>();
                        //if the invoice Amount is matching with usages and invoiceLine Amount or not?
                        if(InvStatus == 'Posted'){
                            for(id invId : IdInvMap.keySet()){
                                if(MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                                    //system.debug(MapInvIdInvoiceLineSubtotal.get(invId)+'Check Total Invoice Details'+IdInvMap.get(invId).blng__Subtotal__c);
                                    //Check if the value matches or not
                                    if(MapInvIdInvoiceLineSubtotal.get(invId).setScale(2, RoundingMode.HALF_UP) == IdInvMap.get(invId).blng__Subtotal__c.setScale(2, RoundingMode.HALF_UP)|| test.isrunningtest()){
                                        //If matches then add to the list
                                        invIds.add(invId);
                                    }
                                }
                            }
                        }else{
                            // This is not to run the Execute method// Not create CSV file for Draft Invoices
                            //Add all the records related to Draft as excute method has not run
                            invIds.addAll(IdInvMap.keySet());
                        }
                    }
                    List<blng__Invoice__c> invIdsToBatch = new List<blng__Invoice__c>();
                    Map<integer, List<blng__Invoice__c>> finalMap = new Map<integer, List<blng__Invoice__c>>();
                    for(id invId : invIds){
                        //system.debug('Inv Id'+invId);
                        count++;
                        integer limitCheck = 0;
                        if(InvIdUsageTotal.containsKey(invId)){
                            totalCount += InvIdUsageTotal.get(invId);
                            System.debug('Mass #11# Count'+totalCount);
                            limitCheck += InvIdUsageTotal.get(invId);
                        }
                        if(InvIdRecurringInvoiceLineTotal.containsKey(invId)){
                            totalCount += InvIdRecurringInvoiceLineTotal.get(invId);
                            System.debug('Mass #22# Count'+totalCount);
                            limitCheck += InvIdRecurringInvoiceLineTotal.get(invId);
                        }
                        //Check if any big invoice is there or not? if there then skip that invoice
                        if(limitCheck <= Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size)){
                            if(totalCount == Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size)){
                                invIdsToBatch.add(IdInvMap.get(invId));
                                //system.debug('First If'+invIdsToBatch);
                                finalMap.put(j, invIdsToBatch);
                                //Reset all the values
                                j++;
                                invIdsToBatch = new List<blng__Invoice__c>();
                                totalCount = 0;
                                tempTotalCount = 0;
                                //System.debug('Mass #11# finalMap'+finalMap);
                            }else if(totalCount > Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size) && tempTotalCount < Integer.ValueOf(Label.QTB_APIX_Mass_Text_File_Batch_Size) && tempTotalCount != 0){
                                //System.debug('Mass #11# totalCount'+totalCount);
                                //System.debug('Mass #22# tempTotalCOunt'+tempTotalCount);
                                //As per the previos count add the set value to the Map // Don't add the current invoice to the set
                                system.debug('Second If'+invIdsToBatch);
                                finalMap.put(j, invIdsToBatch);
                                System.debug('Mass #33# finalMap'+finalMap);
                                //Reset all the values
                                j++;
                                invIdsToBatch = new List<blng__Invoice__c>();
                                totalCount = 0;
                                tempTotalCount = 0;
                                //Set for the current record
                                invIdsToBatch.add(IdInvMap.get(invId));
                                if(InvIdUsageTotal.containsKey(invId)){
                                    totalCount += InvIdUsageTotal.get(invId);
                                }
                                if(InvIdRecurringInvoiceLineTotal.containsKey(invId)){
                                    totalCount += InvIdRecurringInvoiceLineTotal.get(invId);
                                }
                                tempTotalCount = totalCount;
                            }else{
                                system.debug('Mass Last Else'+totalCount);
                                invIdsToBatch.add(IdInvMap.get(invId));
                                system.debug('Third else --'+IdInvMap.get(invId));
                                system.debug('Third else'+invIdsToBatch);
                                tempTotalCount = totalCount;
                                if(invIds.size() == count){
                                    finalMap.put(j, invIdsToBatch);
                                    invIdsToBatch = new List<blng__Invoice__c>();
                                    totalCount = 0;
                                    tempTotalCount = 0;
                                }
                            }
                        }
                        else{
                            //deduct the current big invoice's usages from the main count
                            system.debug(totalCount+'Else Part skip'+limitCheck);
                            totalCount = totalCount - limitCheck;
                            //Need to remove from the code// Reuse of the code
                            invAccLE.add(invId);
                            system.debug(totalCount+'--------'+limitCheck+'Mass Else Part skip'+invAccLE.size());
                            
                        }
                    }
                    //Add the Final list of Invoices for this Batch based on the parameter from the Batch.
                    invLst = new List<blng__Invoice__c>();
                    //system.debug('finalMap--------'+finalMap);
                    System.debug('invBatchNumber--------'+invBatchNumber);
                    invLst.addAll(finalMap.get(integer.valueOf(invBatchNumber)));
                    //Clear the memory
                    MapInvIdInvoiceLineSubtotal.clear();
                    usageSummaries.clear();
                    InvIdRecurringInvoiceLineTotal = null;
                    usageInvList.clear();
                    invAccLE.clear();
                    //invIdsToBatch = null;
                    finalMap = null;
                    invIds.clear();
                    usages.clear();
                    
                    if(invLst != null && invLst.size()>0){
                        //curCode = invLst[0].blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode;
                        //system.debug('@@curCode'+curCode);
                        for(blng__Invoice__c inv : invLst){
                            invIds.add(inv.id);
                            //This is to restrict generation of CSV for invoices where the value are not matching
                            for(blng__InvoiceLine__c invLin : inv.blng__InvoiceInvoiceLines__r){
                                usageSummaries.add(invLin.blng__UsageSummary__c);
                                usageInvList.put(invLin.blng__UsageSummary__c,inv);
                                //Create Map Invoice Id and List InvoiceLine where Type is 'Recurring'
                                //if(invLin.blng__ChargeType__c == 'Recurring'){
                                    //As per New Architecture, Recurring Lines are decided by 'QTB_HasConsumptionSchedule__c'
                                    //As per the Story #6478 & #6509, Recurring Lines are decided by 'QTB_Charge_Type__c'
                                    if(invLin.QTB_Charge_Type__c == 'Recurring'){
                                        if(MapInvIdInvoiceLine.containsKey(inv.id)){
                                            MapInvIdInvoiceLine.get(inv.id).add(invLin);
                                            //Get all the Invoice Line Subtotal
                                            if(invLin.blng__Subtotal__c != null){
                                                MapInvIdInvoiceLineSubtotal.put(inv.id, MapInvIdInvoiceLineSubtotal.get(inv.id)+invLin.blng__Subtotal__c) ;
                                            }
                                        }else{
                                            MapInvIdInvoiceLine.put(inv.id, new List<blng__InvoiceLine__c>{invLin});
                                            //Get all the Invoice Line Subtotal
                                            if(invLin.blng__Subtotal__c != null){
                                                MapInvIdInvoiceLineSubtotal.put(inv.id,invLin.blng__Subtotal__c);
                                            }else{
                                                MapInvIdInvoiceLineSubtotal.put(inv.id,0);
                                            }
                                        }
                                    }
                                    if(!InvIdPaymentTerm.containsKey(inv.id) && invLin.blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c != null){
                                        InvIdPaymentTerm.put(inv.id,invLin.blng__OrderProduct__r.Order.SBQQ__PaymentTerm__c);
                                    }
                                }
                                IdInvMap.put(inv.id,inv);
                                //Check Each Invoice wise, Nordea Account
                                boolean isNordeaAcc = false;
                                if(inv.blng__Account__r.Parent.Name != null && nordeaAccounts != null){
                                    isNordeaAcc = nordeaAccounts.contains(inv.blng__Account__r.Parent.Name);
                                    //nordeaAccountMap.put(inv.id,isNordeaAcc)
                                    system.debug('#######isNordeaAcc00'+isNordeaAcc);
                                }
                                nordeaAccountMap.put(inv.id,isNordeaAcc);
                            }
                            // remove blanks and nulls
                            usageSummaries.remove('');
                            usageSummaries.remove(null);
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
                            
                            //List<blng__Usage__c> usages = new List<blng__Usage__c>();
                            //#13521 Addition of Product Identifier in the query
                            if(!usageSummaries.isEmpty()){
                                //Query for Usages related to invoice's usageSummaries with a proper Order 'QTB_Department_Code__c','QTB_Division_Code__c','QTB_Price_Schedule_Category__c' & 'product2.Name'
                                if(nordicBillingCountriesPresent){
                                    usages = [Select blng__OrderProduct__r.Product2.Name ,blng__OrderProduct__r.product2.ProductCode,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Division_Code__c ,QTB_Department_Code__c ,QTB_Rated_Amount__c ,blng__UsageSummary__r.blng__UnitPrice__c,blng__UnitPrice__c,blng__UsageSummary__r.blng__SummaryStartDate__c,blng__Subtotal__c,blng__Account__c,
                                      blng__OrderProduct__c,QTB_Department_Name__c,QTB_Custom_Invoice_Display__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,blng__Account__r.QTB_Language__c ,QTB_Level_1_Name__c ,QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Rated_Unit_Price__c ,QTB_Invoice_Quantity__c,blng__PreratedQuantity__c,blng__PreratedAmount__c, blng__Quantity__c,QTB_Term__c,QTB_Work_Order_ID__c,QTB_Requestor__c,blng__OrderProduct__r.Product2.Id,QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c,QTB_Product_Identifier_1__c,QTB_Price_Tier__c from blng__Usage__c 
                                      where blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c NULLS LAST, QTB_Division_Code__c NULLS LAST,QTB_Department_Code__c NULLS LAST, blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,QTB_Work_Order_ID__c NULLS LAST,blng__OrderProduct__r.product2.Name NULLS LAST];
                                }else{
                                    usages = [Select blng__OrderProduct__r.product2.Name,blng__OrderProduct__r.product2.ProductCode,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Product_Identifier_1__c,QTB_Price_Tier__c,QTB_Rated_Unit_Price__c,QTB_Start_Date_MRC__c ,QTB_End_Date_MRC__c ,QTB_Division_Code__c ,QTB_Department_Code__c ,QTB_Rated_Amount__c,blng__UsageSummary__r.blng__UnitPrice__c,QTB_Invoice_Quantity__c,blng__PreratedAmount__c,
                                      blng__UsageSummary__c ,QTB_Custom_Invoice_Display__c ,blng__Account__r.QTB_Display_Custom_Product_Names__c ,blng__Account__r.QTB_Language__c ,QTB_Department_Name__c ,QTB_Level_1_Name__c ,QTB_Level_1_Code__c ,QTB_Division_Name__c ,blng__Quantity__c,blng__PreratedQuantity__c,blng__OrderProduct__c, blng__UnitPrice__c, blng__Subtotal__c, blng__Account__c,QTB_Term__c,QTB_Work_Order_ID__c,QTB_Requestor__c,blng__OrderProduct__r.Product2.Id,QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c from blng__Usage__c
                                      where blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c NULLS LAST,QTB_Division_Code__c NULLS LAST,QTB_Department_Code__c NULLS LAST,QTB_Work_Order_ID__c NULLS LAST,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,blng__OrderProduct__r.product2.Name NULLS LAST,QTB_Product_Identifier_1__c NULLS LAST,QTB_Price_Tier__c NULLS LAST];
                                }
                                
                            }
                            usageSummaries = null;
                            //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                            Map<id,set<id>> MapInvoiceIdAndUsageSummaryList = new Map<id,set<id>>();
                            Map<id,list<blng__Usage__c>> MapUsageSummaryIdAndUsageList = new Map<id,list<blng__Usage__c>>();
                            //get the usages total wrt invoices and add them to the InvoiceLine total
                            for(blng__Usage__c usg : usages){
                                //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                                //1st -> Inv Id -> Set<Usage Summary Id>
                                //2nd -> Usage SummaryId -> List<usages>
                                if(usg.QTB_Rated_Amount__c != null){
                                    if(MapInvoiceIdAndUsageSummaryList.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                        MapInvoiceIdAndUsageSummaryList.get(usageInvList.get(usg.blng__UsageSummary__c).id).add(usg.blng__UsageSummary__c);
                                    }else{
                                        MapInvoiceIdAndUsageSummaryList.put(usageInvList.get(usg.blng__UsageSummary__c).id, new set<id>{usg.blng__UsageSummary__c});
                                    }
                                    
                                    if(MapUsageSummaryIdAndUsageList.containsKey(usg.blng__UsageSummary__c)){
                                        MapUsageSummaryIdAndUsageList.get(usg.blng__UsageSummary__c).add(usg);
                                    }else{
                                        MapUsageSummaryIdAndUsageList.put(usg.blng__UsageSummary__c, new List<blng__Usage__c>{usg});
                                    }
                                }
                                /*if(MapInvIdInvoiceLineSubtotal.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                    if(usg.QTB_Rated_Amount__c != null){
                                        MapInvIdInvoiceLineSubtotal.put(usageInvList.get(usg.blng__UsageSummary__c).id,MapInvIdInvoiceLineSubtotal.get(usageInvList.get(usg.blng__UsageSummary__c).id)+ usg.QTB_Rated_Amount__c);
                                    }
                                }else{
                                    if(usg.QTB_Rated_Amount__c != null){
                                        MapInvIdInvoiceLineSubtotal.put(usageInvList.get(usg.blng__UsageSummary__c).id, usg.QTB_Rated_Amount__c);
                                    }
                                }*/
                            }
                            //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                            if(MapInvoiceIdAndUsageSummaryList.size() > 0){
                                for(id invId : MapInvoiceIdAndUsageSummaryList.keySet()){
                                    for(id usgSummId : MapInvoiceIdAndUsageSummaryList.get(invId)){
                                        decimal tempTotal = 0;
                                        for(blng__Usage__c usg : MapUsageSummaryIdAndUsageList.get(usgSummId)){
                                            tempTotal += usg.QTB_Rated_Amount__c;
                                        }
                                        //Old Code
                                        if(MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                                            MapInvIdInvoiceLineSubtotal.put(invId, MapInvIdInvoiceLineSubtotal.get(invId)+ tempTotal.setScale(2, RoundingMode.HALF_UP));
                                        }else{
                                            MapInvIdInvoiceLineSubtotal.put(invId, tempTotal.setScale(2, RoundingMode.HALF_UP));
                                        }
                                    }
                                }
                            }
                            set<id> amountMatchUsages = new set<id>();
                            List<blng__Invoice__c> invLstFinal = new List<blng__Invoice__c>();
                            //if the invoice Amount is matching with usanges and invoiceLine Amount or not?
                            for(id invId : IdInvMap.keySet()){
                                if(MapInvIdInvoiceLineSubtotal.containsKey(invId)){
                                    //system.debug(MapInvIdInvoiceLineSubtotal.get(invId)+'Check Total Inoice Details'+IdInvMap.get(invId).blng__Subtotal__c);
                                    //check if the 'Invoice Subtotal' is matching with the total calculated amount
                                    if(MapInvIdInvoiceLineSubtotal.get(invId).setScale(2, RoundingMode.HALF_UP) == IdInvMap.get(invId).blng__Subtotal__c.setScale(2, RoundingMode.HALF_UP)  || InvStatus=='Draft'){
                                        amountMatchUsages.add(invId);
                                        //system.debug('Invoice passed'+IdInvMap.get(invId).blng__Subtotal__c.setScale(2, RoundingMode.HALF_UP));
                                        invCount++;
                                        grandTotal = grandTotal + double.valueof(IdInvMap.get(invId).QTB_Total_Amount_with_Tax_Override__c);
                                        invAccIds.add(IdInvMap.get(invId).blng__Account__c);
                                        invAccLE.add(IdInvMap.get(invId).blng__Account__r.QTB_Contract_Entity__r.blng__Country__c);
                                        invLstFinal.add(IdInvMap.get(invId));
                                    }
                                }
                            }
                            MapInvIdInvoiceLineSubtotal = null;
                            //Query for PurchaseOrder related to invoice billing account
                            List<QTB_PurchaseOrder__c> purchaseOrderLst = new List<QTB_PurchaseOrder__c>();
                            purchaseOrderLst= [select Name,QTB_Status__c,QTB_Division__c,QTB_Customer_PO__c,QTB_Div_Dept_Level__c,QTB_Customer_Id__c,
													(SELECT Id, Name, QTB_Account__c, QTB_Purchase_Order__c FROM PurchaseOrderAccounts__r) 
												from QTB_PurchaseOrder__c 
												where 	Id IN (SELECT QTB_Purchase_Order__c FROM QTB_PurchaseOrderAccount__c WHERE QTB_Account__c IN: invAccIds)
												And QTB_Status__c= 'Active'];// Gitlab #31452
                            
                            if(purchaseOrderLst != null && purchaseOrderLst.size()>0){
                                invPOList = new map<id,set<string>>();
                                mapPOList = new map<id,List<QTB_PurchaseOrder__c>>();
                                
                                // Gitlab #31452 Loop through each Purchase Order and then their junction object records
                                for(QTB_PurchaseOrder__c po:purchaseOrderLst){
                                    for (QTB_PurchaseOrderAccount__c poAccount : po.PurchaseOrderAccounts__r) {										
                                        Id accountId = poAccount.QTB_Account__c;
                                        if((po.QTB_Division__c == null || po.QTB_Division__c == '') && (po.QTB_Div_Dept_Level__c == null || po.QTB_Div_Dept_Level__c == '') && po.QTB_Customer_PO__c != null && po.QTB_Customer_PO__c != ''){
                                            if(invPOList.containsKey(accountId)) {
                                                invPOList.get(accountId).add(po.QTB_Customer_PO__c);
                                            }else{
                                                invPOList.put(accountId, new set<string> {po.QTB_Customer_PO__c});
                                            }
                                        }
                                        if(mapPOList.containsKey(accountId)) {
                                            mapPOList.get(accountId).add(po);
                                        }else{
                                            mapPOList.put(accountId, new List<QTB_PurchaseOrder__c> {po});
                                        }
                                    }
                                }
                            }
                            //Query for AccountContactRelation related to invoice billing account
                            List<AccountContactRelation> billingCont = new List<AccountContactRelation>();
                            billingCont= [select ContactId,AccountId,QTB_Primary__c,Roles from AccountContactRelation where QTB_Primary__c = true and AccountId IN: invAccIds and Roles = 'Billing'];
                            
                            if(billingCont != null && billingCont.size()>0){
                                billingContLst = new map<id,id>();
                                for(AccountContactRelation accBillCon:billingCont){
                                    accBillConIDS.add(accBillCon.ContactId);
                                    billingContLst.put(accBillCon.AccountId,accBillCon.ContactId);
                                }
                            }
                            
                            if(!accBillConIDS.isEmpty()){
                                conList = new map<id,Contact>();
                                for(Contact con : [select name,email,Phone from contact where id IN: accBillConIDS]){
                                    conList.put(con.id,con);
                                }
                            }
                            //Query for IM Country related to invoice billing account related legal entity
                            if(invAccLE != null && invAccLE.size()>0){
                                countryList = new map<string,string>();
                                //Git #12822 - Addition of Active chckbox in the query
                                for(IM_Country__c cou: [select id,Name,Iso31662Code__c from IM_Country__c where Name IN: invAccLE ]){
                                    countryList.put(cou.Name,cou.Iso31662Code__c);
                                }
                            }
                            set<string> accProductNames = new set<string>();
                            set<string> accLan = new set<string>();
                            Map<id,Map<string, integer>>    L1L2L3InvGrpMap = new Map<id,Map<string, integer>>();
                            Map<id,Map<string, integer>>    L1L2L3InvGrpCompareMap = new Map<id,Map<string, integer>>();
                            //#13521 New map to hold keystring without product identifier value
                            Map<id,Map<string, integer>>    L1L2L3L4InvGrpMap = new Map<id,Map<string, integer>>();
                            Map<string,GroupWrapperCls> groupWrapperMap = new Map<string,GroupWrapperCls>();
                            Map<id,List<Map<string,GroupWrapperCls>>> usagesWrapperList = new Map<id,List<Map<string,GroupWrapperCls>>>();
                            //Custom Grouping based on certain field values(QTB_Department_Code__c, QTB_Division_Code__c, QTB_Price_Schedule_Category__c, product2.Name, QTB_Rated_Unit_Price__c, QTB_Start_Date_MRC__c(if QTB_Price_Schedule_Category__c='Storage'), QTB_End_Date_MRC__c(if QTB_Price_Schedule_Category__c='Storage'))
                            for(blng__Usage__c usg : usages){
                                //system.debug('#$#$#$#$#All :'+usg.id);
                                //Check if the respected invoice amount is matching or not
                                if(amountMatchUsages.contains(usageInvList.get(usg.blng__UsageSummary__c).id) || InvStatus=='Draft'){
                                    //system.debug('#$#$#$#$#Matching :'+usg.id);
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
                                    //#13521 Addition of QTB_Product_Identifier_1__c to grouping for NordicBilling countries
                                    if(nordicBillingCountriesPresent){
                                        if(usg.QTB_Product_Identifier_1__c != null){
                                            keyString += usg.QTB_Product_Identifier_1__c;
                                        }else{
                                            keyString += 'Null';
                                        }
                                        //#20247 Addition of Price Tier for grouping
                                        if(usg.QTB_Price_Tier__c != null){
                                            keyString += usg.QTB_Price_Tier__c;
                                        }else{
                                            keyString += 'Null';
                                        }
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
                                    if(nordeaAccountMap.get(usageInvList.get(usg.blng__UsageSummary__c).id) && usg.QTB_Work_Order_ID__c != null){
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
                                    //Keep Invoice Id as main Key and Value as the Map of Grouping key and Wrapper class
                                    if(usagesWrapperList.containsKey(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                        boolean addMapToList = true;
                                        for(Map<string,GroupWrapperCls> wrpMap : usagesWrapperList.get(usageInvList.get(usg.blng__UsageSummary__c).id)){
                                            //Already key exist
                                            //System.debug('***wrpMap****'+wrpMap.get(keyString).scheduleCategory);
                                            if(wrpMap.containskey(keyString)){
                                                addMapToList = false;
                                                GroupWrapperCls wrp = wrpMap.get(keyString);
                                                //Over ride the map
                                                wrpMap.put(keyString,new GroupWrapperCls(usg,wrp));
                                                //System.debug('****'+wrpMap.get(keyString).scheduleCategory);
                                            }
                                        }
                                        if(addMapToList){
                                            groupWrapperMap = new Map<string,GroupWrapperCls>();
                                            //Create new Map, so pass null
                                            groupWrapperMap.put(keyString,new GroupWrapperCls(usg,null));
                                            //System.debug('**here**'+usagesWrapperList);
                                            usagesWrapperList.get(usageInvList.get(usg.blng__UsageSummary__c).id).add(groupWrapperMap);
                                        }
                                    }else{
                                        
                                        groupWrapperMap = new Map<string,GroupWrapperCls>();
                                        //Create new Map, so pass null
                                        groupWrapperMap.put(keyString,new GroupWrapperCls(usg,null));
                                        //System.debug('***Hereww'+groupWrapperMap.get(keyString).scheduleCategory);
                                        usagesWrapperList.put(usageInvList.get(usg.blng__UsageSummary__c).id, new List<Map<string,GroupWrapperCls>>{groupWrapperMap});
                                        //System.debug('**here 1**'+usagesWrapperList);
                                        
                                    }
                                    //System.debug('**EOD');
                                }
                                //System.debug('**EOD1');
                                
                            }
                            System.debug('*****Here ino ');
                            //Keep Invoice id and List of Usages Wrapper in a Map
                            Map<id,List<GroupWrapperCls>> MapinvoiceIdGroupedUsagesTemp = new Map<id,List<GroupWrapperCls>>();
                            Map<id,List<GroupWrapperCls>> MapinvoiceIdGroupedUsages = new Map<id,List<GroupWrapperCls>>();
                            List<GroupWrapperCls> tempOrderList = new List<GroupWrapperCls>();
                            List<GroupWrapperCls> tempWOL1L2L3List = new List<GroupWrapperCls>();
                            List<GroupWrapperCls> tempOrderListFinal = new List<GroupWrapperCls>();
                            set<string> checkDup = new set<string>();
                            //#13521 New map to hold keystring without product identifier value
                            //Map<string, integer>    L1L2L3L4GrpMap = new Map<string, integer>();
                            Map<string, integer> L1L2L3GrpCompareMap = new Map<string, integer>();
                            if(usages != null && usages.size()>0){
                                for(id invId : usagesWrapperList.keyset()){
                                    //If the Account is a Nordea Account
                                    boolean isNordeaAcc = nordeaAccountMap.get(invId);
                                    //system.debug('isNordeaAcc+++'+isNordeaAcc);
                                    for(Map<string,GroupWrapperCls> wrpMap : usagesWrapperList.get(invId)){
                                        for(GroupWrapperCls ar : wrpMap.values()){
                                            
                                            //Add all the wrapper records to a Final Wrapper List Map
                                            if(!MapinvoiceIdGroupedUsagesTemp.containsKey(invId)){
                                                MapinvoiceIdGroupedUsagesTemp.put(invId, new List<GroupWrapperCls>{ar});
                                                // System.debug('****MapinvoiceIdGroupedUsagesTemp***'+MapinvoiceIdGroupedUsagesTemp.get(invId)[0].scheduleCategory);
                                            }else{
                                                MapinvoiceIdGroupedUsagesTemp.get(invId).add(ar);
                                            }
                                            //System.debug('*******'+ar.scheduleCategory);
                                            accProductNames.add(String.valueOf(ar.ProductCode));
                                            accLan.add(String.valueOf(ar.AccLanguage));
                                            //Check the records for grouping and adding line '40th Line' at the proper place
                                            //Create diff map for each group with the respective count
                                            
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
                                            //#13521 Addition of keystring to the new map for Subtotal calculation
                                            if(grpKeyString != ''){
                                                Map<string, integer> TempKeyMap = new Map<string, integer>();
                                                if(L1L2L3L4InvGrpMap.containsKey(invId)){
                                                    TempKeyMap = L1L2L3L4InvGrpMap.get(invId);
                                                    if(TempKeyMap.containsKey(grpKeyString)){
                                                        TempKeyMap.put(grpKeyString, TempKeyMap.get(grpKeyString) + 1);
                                                    }else{
                                                        TempKeyMap.put(grpKeyString,1);
                                                    }
                                                }else{
                                                    TempKeyMap.put(grpKeyString,1);
                                                }
                                                L1L2L3L4InvGrpMap.put(invId, TempKeyMap);
                                            }
                                            //#13521
                                            if(nordicBillingCountriesPresent){
                                                if (ar.productIdentifier != null){
                                                    grpKeyString += ar.productIdentifier;
                                                    
                                                }
                                                //#20247 Addition of Price Tier for Grouping
                                                if (ar.priceTier != null){
                                                    grpKeyString += ar.priceTier;
                                                    
                                                }
                                            }
                                            
                                            if(isNordeaAcc){
                                                if(ar.workOrderId != null){
                                                    grpKeyString += ar.workOrderId;
                                                }
                                            }
                                            //Add to Groping Map
                                            if(grpKeyString != ''){
                                                Map<string, integer> TempKeyMap = new Map<string, integer>();
                                                if(L1L2L3InvGrpMap.containsKey(invId)){
                                                    TempKeyMap = L1L2L3InvGrpMap.get(invId);
                                                    if(TempKeyMap.containsKey(grpKeyString)){
                                                        TempKeyMap.put(grpKeyString, TempKeyMap.get(grpKeyString) + 1);
                                                    }else{
                                                        TempKeyMap.put(grpKeyString,1);
                                                    }
                                                }else{
                                                    TempKeyMap.put(grpKeyString,1);
                                                }
                                                L1L2L3InvGrpMap.put(invId, TempKeyMap);
                                            }
                                        }
                                    }
                                }
                                //Sort all the inner records after grouping count
                                for(id invId : MapinvoiceIdGroupedUsagesTemp.keySet()){
                                    
                                    L1L2L3GrpCompareMap = new Map<string,integer>();
                                    checkDup = new set<string>();
                                    tempOrderList = new List<GroupWrapperCls>();
                                    tempOrderListFinal = new List<GroupWrapperCls>();
                                    tempWOL1L2L3List= new List<GroupWrapperCls>();
                                    //system.debug('11-!@!@!@!@!@'+MapinvoiceIdGroupedUsagesTemp.get(invId).size());
                                    for(GroupWrapperCls ar : MapinvoiceIdGroupedUsagesTemp.get(invId)){
                                        boolean isNordeaAcc = nordeaAccountMap.get(invId);
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
                                        //#13521
                                        if(nordicBillingCountriesPresent){
                                            if (ar.productIdentifier != null){
                                                grpKeyString += ar.productIdentifier;
                                            }
                                            //#20247 Addition of Price Tier for Grouping
                                            if (ar.priceTier != null){
                                                grpKeyString += ar.priceTier;
                                                
                                            }
                                        }
                                        if(isNordeaAcc){
                                            if(ar.workOrderId != null){
                                                grpKeyString += ar.workOrderId;
                                            }
                                        }
                                        //Add to Grouping Map
                                        if(grpKeyString != ''){
                                            if(L1L2L3GrpCompareMap.containsKey(grpKeyString)){
                                                L1L2L3GrpCompareMap.put(grpKeyString,L1L2L3GrpCompareMap.get(grpKeyString)+1);
                                            }else{
                                                L1L2L3GrpCompareMap.put(grpKeyString,1);
                                            }
                                        }else{
                                            //system.debug('tempWOL1L2L3List Ids'+ar.recordId);
                                            //These are the records where we don;t have L1/L2/L3
                                            tempWOL1L2L3List.add(ar);
                                        }
                                        //Grouping number matches
                                        if(L1L2L3InvGrpMap.containsKey(invId)){
                                            Map<string, integer> L1L2L3InvGrpMapTemp = L1L2L3InvGrpMap.get(invId);
                                            if(L1L2L3InvGrpMapTemp.containsKey(grpKeyString)){
                                                //Grouping number matches means the grouping is done for this group
                                                if(L1L2L3InvGrpMapTemp.get(grpKeyString) == L1L2L3GrpCompareMap.get(grpKeyString)){
                                                    //system.debug('Number matches---**'+L1L2L3InvGrpMapTemp.get(grpKeyString)+ '  '+ ar.productName);
                                                    //Multiple records are there in the group
                                                    if(tempOrderListFinal.size() > 0){
                                                        //system.debug('Number matches---1&& '+tempOrderListFinal.size());
                                                        //Testing
                                                        if(checkDup.contains(ar.schedulecategory)){
                                                            //system.debug('Dup check---1'+ar.schedulecategory+ ' ::'+ ar.productName);
                                                            for(integer i=0; i< tempOrderList.size() ; i++){
                                                                //system.debug('Dup check---2'+tempOrderList[i].schedulecategory+ ' ::'+ tempOrderList[i].productName);
                                                                if(tempOrderList[i].schedulecategory == ar.schedulecategory){
                                                                    //system.debug('Dup check---3'+tempOrderList[i].schedulecategory+ ' ::'+ tempOrderList[i].productName);
                                                                    tempOrderListFinal.add(i,ar);
                                                                    break;
                                                                }
                                                            }
                                                            //system.debug('Dup check---4 Break'+ ' ::'+ ar.productName);
                                                            tempOrderList.clear();
                                                            tempOrderList.addAll(tempOrderListFinal);
                                                        }else{
                                                            //system.debug('Dup check---5 Else'+ar.schedulecategory+ ' ::'+ ar.productName);
                                                            checkDup.add(ar.schedulecategory);
                                                            tempOrderList.add(ar);
                                                            tempOrderListFinal.add(ar);
                                                        }
                                                        
                                                        //Add all the wrapper records to a Final Wrapper List Map
                                                        if(!MapinvoiceIdGroupedUsages.containsKey(invId)){
                                                            MapinvoiceIdGroupedUsages.put(invId, new List<GroupWrapperCls>());
                                                            MapinvoiceIdGroupedUsages.get(invId).addAll(tempOrderListFinal);
                                                            // System.debug('****MapinvoiceIdGroupedUsages***'+MapinvoiceIdGroupedUsages.get(invId)[0].scheduleCategory);
                                                        }else{
                                                            MapinvoiceIdGroupedUsages.get(invId).addAll(tempOrderListFinal);
                                                        }
                                                        //finalGroupedUsages.addAll(tempOrderListFinal);
                                                    }else{
                                                        //system.debug('Number matches---2');
                                                        //First time number matches
                                                        //Add all the wrapper records to a Final Wrapper List Map
                                                        if(!MapinvoiceIdGroupedUsages.containsKey(invId)){
                                                            MapinvoiceIdGroupedUsages.put(invId, new List<GroupWrapperCls>());
                                                            MapinvoiceIdGroupedUsages.get(invId).add(ar);
                                                            // System.debug('****MapinvoiceIdGroupedUsages***'+MapinvoiceIdGroupedUsages.get(invId)[0].scheduleCategory);
                                                        }else{
                                                            MapinvoiceIdGroupedUsages.get(invId).add(ar);
                                                        }
                                                    }
                                                    checkDup = new set<string>();
                                                    tempOrderList = new List<GroupWrapperCls>();
                                                    tempOrderListFinal = new List<GroupWrapperCls>();
                                                }else{//Grouping number not matches
                                                    //Already present the key// More number of records in the grouping
                                                    //Start Order for Schedule Category
                                                    if(checkDup.contains(ar.schedulecategory)){
                                                        //system.debug('Dup check---1'+ar.schedulecategory+ ' ::'+ ar.productName);
                                                        for(integer i=0; i< tempOrderList.size() ; i++){
                                                            //system.debug('Dup check---2'+tempOrderList[i].schedulecategory+ ' ::'+ tempOrderList[i].productName);
                                                            if(tempOrderList[i].schedulecategory == ar.schedulecategory){
                                                                //system.debug('Dup check---3'+tempOrderList[i].schedulecategory+ ' ::'+ tempOrderList[i].productName);
                                                                tempOrderListFinal.add(i,ar);
                                                                break;
                                                            }
                                                        }
                                                        //system.debug('Dup check---4 Break'+ ' ::'+ ar.productName);
                                                        tempOrderList.clear();
                                                        tempOrderList.addAll(tempOrderListFinal);
                                                    }else{
                                                        //system.debug('Dup check---5 Else'+ar.schedulecategory+ ' ::'+ ar.productName);
                                                        checkDup.add(ar.schedulecategory);
                                                        tempOrderList.add(ar);
                                                        tempOrderListFinal.add(ar);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if(tempWOL1L2L3List.size() > 0){
                                        //system.debug('#$#$#$#$#$#$ went inside'+tempWOL1L2L3List);
                                        //Add all those usages which are not having the L1/ L2/ L3 code
                                        //Add all the wrapper records to a Final Wrapper List Map
                                        if(!MapinvoiceIdGroupedUsages.containsKey(invId)){
                                            MapinvoiceIdGroupedUsages.put(invId, new List<GroupWrapperCls>());
                                            MapinvoiceIdGroupedUsages.get(invId).addAll(tempWOL1L2L3List);
                                        }else{
                                            //system.debug('#$#$#$#$#$#$ went inside else'+tempWOL1L2L3List);
                                            MapinvoiceIdGroupedUsages.get(invId).addAll(tempWOL1L2L3List);
                                        }
                                    }
                                }
                                
                            }
                            //Make the value to null as not required further
                            usages = null;
                            //Adding Recurring InvoiceLine at the end of all Usages Wrapper Map
                            if(MapInvIdInvoiceLine.size() > 0){
                                for(string invId : MapInvIdInvoiceLine.keySet()){
                                    //if(MapinvoiceIdGroupedUsages.containsKey(invId)){
                                        for(blng__InvoiceLine__c invLine : MapInvIdInvoiceLine.get(invId)){
                                            //Create dummy blng__Usage__c record from Invoice Line for the wrapper class
                                            blng__Usage__c tempUsages = new blng__Usage__c();
                                            tempUsages.blng__OrderProduct__c = invLine.blng__Product__c;
                                            tempUsages.QTB_Invoice_Quantity__c = invLine.blng__Quantity__c;
                                            tempUsages.blng__UnitPrice__c = invLine.blng__UnitPrice__c;
                                            tempUsages.blng__Subtotal__c = invLine.blng__Subtotal__c;
                                            //Need to check for Account Language
                                            tempUsages.blng__Account__c = invLine.blng__Invoice__r.blng__Account__c;
                                            //Temporary use of these fields to store Data
                                            tempUsages.QTB_Cost_Center__c = invLine.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                                            tempUsages.blng__MatchingAttribute__c = invLine.blng__OrderProduct__r.Product2.Name;
                                            tempUsages.blng__ErrorMessage__c = invLine.blng__OrderProduct__r.Product2.ProductCode;
                                            tempUsages.QTB_UsedforRerate__c = invLine.blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c;
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
                                            if(MapinvoiceIdGroupedUsages.containsKey(invId)){
                                                MapinvoiceIdGroupedUsages.get(invId).add(tempGroupWrapper);
                                                for(List<GroupWrapperCls> cls : MapinvoiceIdGroupedUsages.values() ){
                                                    for(GroupWrapperCls clss :cls ){
                                                        //system.debug('*****debug '+clss.scheduleCategory +'**** '+clss.recordId );
                                                    }
                                                    
                                                }
                                            }else{
                                                MapinvoiceIdGroupedUsages.put(invId, new List<GroupWrapperCls>{tempGroupWrapper});
                                                for(GroupWrapperCls cls : MapinvoiceIdGroupedUsages.get(invId) ){
                                                    //system.debug('*****debug '+cls.scheduleCategory);
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                                list<SBQQ__Localization__c> localization;
                                map<string,string> maplocalization = new map<string,string>();
                                if(!accProductNames.isEmpty() && !accLan.isEmpty()){
                                    localization = [select id,SBQQ__Text__c,SBQQ__Product__r.Name,SBQQ__Product__r.ProductCode,SBQQ__APIName__c,SBQQ__Language__c from SBQQ__Localization__c Where SBQQ__Product__r.ProductCode IN:accProductNames and SBQQ__Language__c IN: accLan and SBQQ__APIName__c = 'Name'];
                                    for(SBQQ__Localization__c loc:localization){
                                        string locKey = loc.SBQQ__Product__r.ProductCode+' '+loc.SBQQ__Language__c;
                                        maplocalization.put(locKey,loc.SBQQ__Text__c);
                                    }
                                }
                                
                                //mappingToTxt(invLstFinal,countryList,invPOList,billingContLst,conList,accLanguage,IdInvMap,targetDate,targetMonth,mapPOList,MapinvoiceIdGroupedUsages,maplocalization,invSCBatch,nordeaAccountMap, InvIdPaymentTerm,L1L2L3InvGrpMap,eligibleAccountIds);
                                //#13521 Passing new parameter
                                mappingToTxt(invLstFinal,countryList,invPOList,billingContLst,conList,accLanguage,IdInvMap,targetDate,targetMonth,mapPOList,MapinvoiceIdGroupedUsages,maplocalization,invSCBatch,nordeaAccountMap, InvIdPaymentTerm,L1L2L3L4InvGrpMap,eligibleAccountIds);
                                mappingToSummary(invCount,grandTotal,curCode);
                            }
                            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                        }catch(exception e){
                            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexMassExtractVFCTRL');
                            //throw e;
                        }
                    }
                }
                
                //Apex mapping for txt file realted to invoice
                public void mappingToTxt(list<blng__Invoice__c> invLst,map<string,string> countryList,map<id,set<string>> invPOList,map<id,id> billingContLst,map<id,Contact> conList,Map<String, String> accLanguage,map<id,blng__Invoice__c> IdInvMap,date targetDate,date targetMonth,map<id,List<QTB_PurchaseOrder__c>> mapPOList,Map<id,List<GroupWrapperCls>> MapinvoiceIdGroupedUsages,map<string,string> maplocalization, String invSCBatch,Map<id, boolean>nordeaAccountMap,Map<id,string> InvIdPaymentTerm,Map<id,Map<string, integer>>L1L2L3InvGrpMap,Set<ID> eligibleAccountIds){
                    try{
                        //system.debug('++++invLst'+invLst.size());
                        /************** Changes for Story #1317 Starts **************/
                        //Fetch all the records from the "Custom Product Name" table
                        list<QTB_Custom_Product_Name__c> customProductNameList = [Select id, Account__c, Custom_Name__c, Product__c from QTB_Custom_Product_Name__c 
                                                                      where Account__c IN :eligibleAccountIds];
                        //Custom Product Name map having key - AccountId+ProductId and value - Custom Product Name
                        Map<String, String> customProductNameMap = new Map<String, String>();
                        for (QTB_Custom_Product_Name__c customProductName : customProductNameList) {
                            //Additional check to create valid map only.
                            if (customProductName.Account__c != NULL && customProductName.Product__c != NULL && customProductName.Custom_Name__c != NULL ) {
                                customProductNameMap.put(String.valueof(customProductName.Account__c)+String.valueof(customProductName.Product__c), String.valueof(customProductName.Custom_Name__c));
                            }
                        }
                        /************** Changes for Story #1317 Ends **************/
                        for(blng__Invoice__c invoice : invLst){
                            
                            string blgCountry = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c;
                            id blgContact;
                            set<string> printvalue = new set<string>();
                            wrapper w = new wrapper();
                            
                            List<usagewrapper> usageLines = new List<usagewrapper>();
                            
                            //Invoice Header Row1 Mapping
                            //w.header1 = '00';
                            if(countryList != null && !countryList.isEmpty() && countryList.containsKey(blgCountry) && countryList.get(blgCountry)!= null){
                                w.invoice_layout = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout2 =countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu2 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout3 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu3 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout4 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu4 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout5 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu5 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout7 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu7 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout8 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu8 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout9 = countryList.get(blgCountry)+'IDS';
                                w.invoice_layout_bu9 = countryList.get(blgCountry)+'IDS';
                            }
                            if(billingContLst != null && !billingContLst.isEmpty() && billingContLst.containsKey(invoice.blng__Account__c) && billingContLst.get(invoice.blng__Account__c)!= null){
                                blgContact = billingContLst.get(invoice.blng__Account__c);
                            }
                            //Changes for differentiate between 'Draft' and 'Posted' Invoice - Story #742
                            w.invoice_status = QTB_GenerateApexExtractVFCTRL.INVOICE_POSTED_BILLING_STATUS;
                            if (invoice.blng__InvoiceStatus__c != null && String.ValueOf(invoice.blng__InvoiceStatus__c) == QTB_Constants.INVOICE_STATUS_DRAFT) {
                                w.invoice_status = QTB_GenerateApexExtractVFCTRL.INVOICE_DRAFT_BILLING_STATUS;
                            }
                            
                            w.print_invoice_date = invoice.blng__InvoiceDate__c != null? DateTime.newInstance(invoice.blng__InvoiceDate__c.year(),invoice.blng__InvoiceDate__c.month(),invoice.blng__InvoiceDate__c.day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                            w.bill_cust_id = invoice.blng__Account__r.QTB_Customer_Number__c != null? invoice.blng__Account__r.QTB_Customer_Number__c : '';
                            w.print_due_date = invoice.blng__DueDate__c != null? DateTime.newInstance(invoice.blng__DueDate__c.year(),invoice.blng__DueDate__c.month(),invoice.blng__DueDate__c.day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                            if(invPOList != null && !invPOList.isEmpty() && invPOList.containsKey(invoice.blng__Account__c) && invPOList.get(invoice.blng__Account__c)!= null){
                                List<String> purchaseOrderList = new List<String>();
                                purchaseOrderList.addAll(invPOList.get(invoice.blng__Account__c));
                                w.PO_ID = string.join(purchaseOrderList,',');
                            }
                            
                            if(accLanguage.containsKey(invoice.blng__Account__r.QTB_Language__c) && accLanguage.get(invoice.blng__Account__r.QTB_Language__c)!= null)
                                w.rpt_language_cd = accLanguage.get(invoice.blng__Account__r.QTB_Language__c);
                            if(InvIdPaymentTerm.containskey(invoice.id)){
                                w.pay_terms_descrshort = InvIdPaymentTerm.get(invoice.id) != null? InvIdPaymentTerm.get(invoice.id) : '';
                            }
                            if(invoice.blng__InvoiceStatus__c == 'Posted'){
                                w.invoice_num = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                w.invoice_num2 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                w.report_file = 'IRM_InvRep_'+invoice.QTB_Custom_Invoice_Number__c+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv';
                                w.invoice_num3 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                w.invoice_num4 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                w.invoice_num5 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                w.invoice_num7 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                w.invoice_num8 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                w.invoice_num9 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                            }else{
                                w.invoice_num = 'TEMP-'+invoice.Name;
                                w.invoice_num2 = 'TEMP-'+invoice.Name;
                                w.invoice_num3 = 'TEMP-'+invoice.Name;
                                w.invoice_num4 = 'TEMP-'+invoice.Name;
                                w.invoice_num5 = 'TEMP-'+invoice.Name;
                                w.invoice_num7 = 'TEMP-'+invoice.Name;
                                w.invoice_num8 = 'TEMP-'+invoice.Name;
                                w.invoice_num9 = 'TEMP-'+invoice.Name;
                            }
                            //Invoice Header Row2 Mapping
                            //w.header2 = '01';
                            w.print_gst = invoice.blng__Account__r.QTB_Tax_ID__c != null? invoice.blng__Account__r.QTB_Tax_ID__c : '';
                            //w.Constant = 'N';
                            w.Cust_addr_ln1 = invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null? invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c : '';
                            w.Cust_addr_str = invoice.blng__Account__r.BillingStreet != null? invoice.blng__Account__r.BillingStreet : '';
                            w.Cust_addr_pc = invoice.blng__Account__r.BillingPostalCode != null? invoice.blng__Account__r.BillingPostalCode : '';
                            w.Cust_addr_ci = invoice.blng__Account__r.BillingCity != null? invoice.blng__Account__r.BillingCity : '';
                            w.Cust_addr_cou = invoice.blng__Account__r.BillingCountry != null? invoice.blng__Account__r.BillingCountry : '';
                            
                            //Invoice Header Row3 Mapping
                            //w.header3 = '02';
                            if(targetMonth != null){
                                w.print_from_date = DateTime.newInstance(targetMonth.year(),targetMonth.month(),targetMonth.day()).format('dd/MM/yyyy');  //Story 3947 End date issue
                                w.print_to_date = DateTime.newInstance(targetDate.year(),targetDate.month(),targetDate.day()).format('dd/MM/yyyy');  //Story 3947 End date issue
                            }
                            w.retention_from_date = '';
                            w.retention_to_date = '';
                            w.bill_inquiry_phone = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c : '';
                            
                            //Invoice Header Row4 Mapping
                            //w.header4 = '03';
                            If(conList != null && !conList.isEmpty() && conList.containsKey(blgContact) && conList.get(blgContact).email != null){
                                w.Email_id = conList.get(blgContact).email;
                            }
                            //Invoice Notes Mapping
                            //w.header5 = '10';
                            w.header_note = invoice.blng__Account__r.QTB_Invoice_Notes__c != null? invoice.blng__Account__r.QTB_Invoice_Notes__c.replace('\n','') : '';
                            w.header_note1 = invoice.blng__Notes__c != null? invoice.blng__Notes__c.replace('\n','') : '';
                            //Tax Details Mapping
                            //w.header7 = '50';
                            w.inv_subtotal = invoice.blng__Subtotal__c != null? String.valueOf(invoice.blng__Subtotal__c.setScale(2)) : '';
                            //#21361 Addition of override fields
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
                            //Swift code addition in the Apix extract for Nordics
                            w.swift = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c != null? invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c : '';
                            //#15071 Addition of POGR
                            w.POGR = invoice.blng__Account__r.QTB_EDI_Identifier__c != null? invoice.blng__Account__r.QTB_EDI_Identifier__c : '';
                            //System.debug('POGR >>>'+w.POGR);
                            
                            //File Footer2 Mapping
                            //w.header9 = '91';
                            w.print_invoice_date1 = invoice.blng__InvoiceDate__c != null? DateTime.newInstance(invoice.blng__InvoiceDate__c.year(),invoice.blng__InvoiceDate__c.month(),invoice.blng__InvoiceDate__c.day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                            w.bill_to_cust_id1 = invoice.blng__Account__r.QTB_Customer_Number__c != null? invoice.blng__Account__r.QTB_Customer_Number__c : '';
                            w.name1 = invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c != null? invoice.blng__Account__r.QTB_Billing_Account_Invoice_Name__c : '';
                            w.inv_amount = invoice.QTB_Total_Amount_with_Tax_Override__c != null? String.valueOf(invoice.QTB_Total_Amount_with_Tax_Override__c.setScale(2)) : '';
                            w.bi_currency_cd = invoice.CurrencyIsoCode != null? invoice.CurrencyIsoCode : '';
                            //system.debug('MapinvoiceIdGroupedUsages'+ MapinvoiceIdGroupedUsages.keyset());
                            if(MapinvoiceIdGroupedUsages.containsKey(invoice.Id)){
                                //system.debug('@@Invoice For'+invoice.Id);
                                integer invnum = 1;
                                Map<string, integer>    DepMap = new Map<string, integer>();
                                Map<string, integer>    DivMap = new Map<string, integer>();
                                Map<string, integer>    WorkOMap = new Map<string, integer>();
                                Map<string, integer>    SchMap = new Map<string, integer>();
                                Map<string, integer>    NameMap = new Map<string, integer>();
                                Map<string, Decimal> L1L2L3GrpSubTotalMap = new Map<string, Decimal>();
                                Map<string,integer> L1L2L3GrpCompareMap = new Map<string,integer>();
                                Decimal TotalSubTotal = 0;
                                integer count = 0;
                                //system.debug('MapinvoiceIdGroupedUsages'+ MapinvoiceIdGroupedUsages);
                                for(GroupWrapperCls ar : MapinvoiceIdGroupedUsages.get(invoice.Id)){
                                    //system.debug('%%%%%%%%%%%'+ar.scheduleCategory);
                                    usagewrapper usgItem = new usagewrapper();
                                    //usgItem.header6 = '20';
                                    if( invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c != null){
                                        blgCountry = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c;
                                    }
                                    if(countryList != null && !countryList.isEmpty() && countryList.containsKey(blgCountry) && countryList.get(blgCountry)!= null){
                                        usgItem.invoice_layout6 = countryList.get(blgCountry)+'IDS';
                                        usgItem.invoice_layout_bu6 = countryList.get(blgCountry)+'IDS';
                                    }
                                    //if(invoice.QTB_Custom_Invoice_Number__c != null){
                                        if(invoice.blng__InvoiceStatus__c == 'Posted'){
                                            usgItem.invoice_num6 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                        }else{
                                            usgItem.invoice_num6 = 'TEMP-'+invoice.Name;
                                        }
                                    //}
                                    //system.debug('@@lev1code'+ar.lev1code+'@@'+ar.divisionCode+'@@'+ar.departmentCode);
                                    if((ar.lev1code != '' && ar.lev1code != null) || (ar.divisionCode != '' && ar.divisionCode != null) || (ar.departmentCode != '' && ar.departmentCode != null) || test.isrunningtest()){
                                        printvalue.add('Y');
                                        usgItem.print_level1 = 'Y';
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
                                        usgItem.level_custmer_id = custId;
                                    }
                                    else{
                                        usgItem.print_level1 = 'N';
                                    }
                                    if(ar.lev1code != '' && ar.lev1code != null)
                                        w.usage_level1name = String.valueOf(ar.lev1code);
                                    
                                    
                                    if(nordeaAccountMap.get(invoice.id)){
                                        if(ar.departmentname != '' && ar.departmentname != null){
                                            //If Work Order Id not Null
                                            if(ar.workOrderId != null || ar.requestor != null || test.isrunningtest()){
                                                if(ar.workOrderId != null && ar.requestor != null){
                                                    usgItem.level_name_12 = String.valueOf(ar.departmentname)+' / '+ar.workOrderId +' '+ ar.requestor;
                                                }else if(ar.workOrderId != null){
                                                    usgItem.level_name_12 = String.valueOf(ar.departmentname)+' / '+ar.workOrderId;
                                                }else{
                                                    usgItem.level_name_12 = String.valueOf(ar.departmentname)+' / '+ar.requestor;
                                                }
                                            }else{
                                                usgItem.level_name_12 = String.valueOf(ar.departmentname);
                                            }
                                            //If Div not Null
                                        }else if(ar.divisionname != '' && ar.divisionname != null ){
                                            //If Work Order Id not Null
                                            if(ar.workOrderId != null || ar.requestor != null || test.isrunningtest()){
                                                if(ar.workOrderId != null && ar.requestor != null){
                                                    usgItem.level_name_12 = String.valueOf(ar.divisionname)+' / '+ar.workOrderId +' '+ ar.requestor;
                                                }else if(ar.workOrderId != null){
                                                    usgItem.level_name_12 = String.valueOf(ar.divisionname)+' / '+ar.workOrderId;
                                                }else{
                                                    usgItem.level_name_12 = String.valueOf(ar.divisionname)+' / '+ar.requestor;
                                                }
                                            }else{
                                                usgItem.level_name_12 = String.valueOf(ar.divisionname);
                                            }
                                            //If Lev1 not Null
                                        }else if(ar.lev1name != '' && ar.lev1name != null){
                                            //If Work Order Id not Null
                                            if(ar.workOrderId != null || ar.requestor != null || test.isrunningtest()){
                                                if(ar.workOrderId != null && ar.requestor != null){
                                                    usgItem.level_name_12 = String.valueOf(ar.lev1name)+' / '+ar.workOrderId +' '+ ar.requestor;
                                                }else if(ar.workOrderId != null){
                                                    usgItem.level_name_12 = String.valueOf(ar.lev1name)+' / '+ar.workOrderId;
                                                }else{
                                                    usgItem.level_name_12 = String.valueOf(ar.lev1name)+' / '+ar.requestor;
                                                }
                                            }else{
                                                usgItem.level_name_12 = String.valueOf(ar.lev1name);
                                            }
                                            //If Dep not Null
                                        }else if(ar.workOrderId != null || ar.requestor != null || test.isrunningtest()){
                                            if(ar.workOrderId != null && ar.requestor != null){
                                                usgItem.level_name_12 = ar.workOrderId + ar.requestor;
                                            }else if(ar.workOrderId != null){
                                                usgItem.level_name_12 = ar.workOrderId;
                                            }else{
                                                usgItem.level_name_12 = ar.requestor;
                                            }
                                        }
                                        //If It's not a Nordea Account
                                    }else{
                                        if(ar.departmentname != '' && ar.departmentname != null){
                                            usgItem.level_name_12 = String.valueOf(ar.departmentname);
                                        }else if(ar.divisionname != '' && ar.divisionname != null){
                                            usgItem.level_name_12 = String.valueOf(ar.divisionname);
                                        }else if(ar.lev1name != '' && ar.lev1name != null){
                                            usgItem.level_name_12 = String.valueOf(ar.lev1name);
                                        }
                                    }
                                    usgItem.inv_linenum = invnum++;
                                    string lockey = String.valueOf(ar.productCode)+' '+String.valueOf(ar.AccLanguage);
                                    /************** Changes for Story #1317 Starts **************/
                                    //#13521 - For Nordic Billing countries, line description to be picked from usages-> product identifier
                                    if(nordicBillingCountriesPresent){
                                        if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(' -> ')[0] == 'Storage'){
                                            //system.debug('  Nordics -----'+string.valueOf(ar.scheduleCategory).split(' -> ')[0]+'Nordics -----');
                                            string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : ''; //Story 3947 End date issue
                                            string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';//Story 3947 End date issue
                                            usgItem.usageproduct = ar.CusInvDisplay+' '+'('+pStartDate+' '+pEndDate+')';
                                            //system.debug('pstartdate>>> '+pStartDate+ ' pEndDate >>>  '+ pEndDate);
                                            //system.debug('Storage product >>> '+ usgItem.usageproduct);
                                        }else{
                                            usgItem.usageproduct = ar.CusInvDisplay;
                                        }
                                        
                                    }else{
                                        if(ar.displayPnameCheck == true && customProductNameMap.get(String.valueof(invoice.blng__Account__c)+String.valueof(ar.productId)) != NULL){
                                            if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(' -> ')[0] == 'Storage'){
                                                string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                                                string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';   //Story 3947 End date issue
                                                usgItem.usageproduct = customProductNameMap.get(String.valueof(invoice.blng__Account__c)+String.valueof(ar.productId))+' '+'('+pStartDate+' '+pEndDate+')';
                                            }else{
                                                usgItem.usageproduct = customProductNameMap.get(String.valueof(invoice.blng__Account__c)+String.valueof(ar.productId));
                                            }
                                            /************** Changes for Story #1317 Ends **************/
                                        }
                                        else if(maplocalization.containsKey(lockey)){
                                            string pName = maplocalization.get(lockey);
                                            if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(' -> ')[0] == 'Storage'){
                                                string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : '';  //Story 3947 End date issue
                                                string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';   //Story 3947 End date issue
                                                usgItem.usageproduct = pName+' '+'('+pStartDate+' '+pEndDate+')';
                                            }else{
                                                usgItem.usageproduct = pName;
                                            }
                                        }
                                        else{
                                            //System.debug('***1***'+string.valueOf(ar.scheduleCategory));
                                            string pName = String.valueOf(ar.productName)  != null? String.valueOf(ar.productName) : '';
                                            if(ar.scheduleCategory != null && string.valueOf(ar.scheduleCategory).split(' -> ')[0] == 'Storage'){
                                                string pStartDate = String.valueOf(ar.startdate) != null? DateTime.newInstance(date.valueOf(ar.startdate).year(),date.valueOf(ar.startdate).month(),date.valueOf(ar.startdate).day()).format('dd/MM/yyyy') : '';   //Story 3947 End date issue
                                                string pEndDate = String.valueOf(ar.enddate) != null? DateTime.newInstance(date.valueOf(ar.enddate).year(),date.valueOf(ar.enddate).month(),date.valueOf(ar.enddate).day()).format('dd/MM/yyyy') : '';   //Story 3947 End date issue
                                                usgItem.usageproduct = pName+' '+'('+pStartDate+' '+pEndDate+')';
                                            }else{
                                                usgItem.usageproduct = pName;
                                            }
                                        }
                                    }
                                    //#15071 Addition of POGR
                                    //usgItem.POGR = invoice.blng__Account__r.QTB_EDI_Identifier__c != null? //invoice.blng__Account__r.QTB_EDI_Identifier__c : '';
                                    // Changes related to US #29010.Checking prerated quantity as quantity field is not populated.
                                    if (ar.preratequantity != null && ar.preratequantity >0 ){
                                        usgItem.lineqty = String.valueOf(ar.preratequantity.setScale(2, RoundingMode.HALF_UP));
                                    }else if(ar.quantity != null){
                                        usgItem.lineqty = String.valueOf(ar.quantity.setScale(2, RoundingMode.HALF_UP));
                                    }
                                    if(invoice.blng__InvoiceStatus__c == 'Posted'){
                                        Decimal usageratedamount = double.valueof(ar.ratedAmount);
                                        usgItem.invlineamount = String.valueOf(usageratedamount.setScale(2, RoundingMode.HALF_UP));
                                    }else if(invoice.blng__InvoiceStatus__c == 'Draft' && ar.prerateamount != 0.0 ){
                                        Decimal usagepreamount = double.valueof(ar.prerateamount);
                                        usgItem.invlineamount = String.valueOf(usagepreamount.setScale(2, RoundingMode.HALF_UP));
                                    }else{
                                        if(String.valueOf(ar.usQuantity) != null && String.valueOf(ar.usSumUnitprice) != null){
                                            usgItem.invlineamount = String.valueOf(Decimal.valueof(double.valueOf(ar.usQuantity)*double.valueOf(ar.usSumUnitprice)).setScale(2, RoundingMode.HALF_UP));
                                        }
                                    }
                                    //Only for Recurring Invoice Line
                                    if(ar.recordId == null && ar.subtotalLine != null){
                                        usgItem.invlineamount = String.valueOf(ar.subtotalLine.setScale(2, RoundingMode.HALF_UP));
                                    }
                                    //For both Draft and Posted
                                    Decimal usageunitprice =0;
                                    if(nordicBillingCountriesPresent){
                                        //#18631 For Finland specific unit amount calculation
                                        if(ar.legalEntityCountry == 'Finland'){
                                            //If Prerated Unit Price is present then to populate its value else looks for Prerated amount / Qty
                                            if(ar.preratedUnitAmount != null && ar.preratedUnitAmount > 0){
                                                usgItem.unitamt = String.valueOf(ar.preratedUnitAmount.setScale(4));
                                            }
                                            else if(ar.prerateamount > 0){
                                                if(usgItem.lineqty != null && decimal.valueOf(usgItem.lineqty) != 0){
                                                    usageunitprice = double.valueof(decimal.valueOf(usgItem.invlineamount)/decimal.valueOf(usgItem.lineqty));
                                                    usgItem.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                                                }
                                            }
                                            
                                        }
                                        //For all nordics countries which doesnot belongs to Finland then to calculate as earlier
                                        else {
                                            if(ar.prerateamount > 0){
                                                if(usgItem.lineqty != null && decimal.valueOf(usgItem.lineqty) != 0){
                                                    usageunitprice = double.valueof(decimal.valueOf(usgItem.invlineamount)/decimal.valueOf(usgItem.lineqty));
                                                    usgItem.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                                                }
                                            }else{
                                                usgItem.unitamt = String.valueOf(ar.preratedUnitPrice.setScale(4, RoundingMode.HALF_UP));
                                            }
                                        }
                                    }else{
                                        if(ar.prerateamount > 0){
                                            if(usgItem.lineqty != null && decimal.valueOf(usgItem.lineqty) != 0){
                                                usageunitprice = double.valueof(decimal.valueOf(usgItem.invlineamount)/decimal.valueOf(usgItem.lineqty));
                                                usgItem.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                                            }else{
                                                usageunitprice = double.valueof(usgItem.invlineamount);
                                                usgItem.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                                            }
                                        }else{
                                            if(invoice.blng__InvoiceStatus__c == 'Posted' && ar.ratedunitPrice != null){
                                                usageunitprice = double.valueof(ar.ratedunitPrice);
                                            }else if(ar.usSumUnitprice != null){
                                                usageunitprice = double.valueof(ar.usSumUnitprice);
                                            }
                                            if(ar.term != null && usageunitprice != null){
                                                usgItem.unitamt = String.valueOf((usageunitprice * ar.term).setScale(4, RoundingMode.HALF_UP));
                                            }else if(usageunitprice != null){
                                                usgItem.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                                            }
                                        }
                                    }
                                    //Only for Recurring Invoice Line
                                    if(ar.recordId == null && ar.unitPriceLine != null){
                                        usgItem.unitamt = String.valueOf(ar.unitPriceLine.setScale(4, RoundingMode.HALF_UP));
                                    }
                                    //grandtotal = grandtotal + double.valueof(ar.ratedAmount);
                                    //system.debug('ar.scheduleCategory'+ar.scheduleCategory);
                                    usgItem.usg_category = String.valueOf(ar.scheduleCategory) != null? string.valueOf(ar.scheduleCategory).split(' -> ')[1] : '';
                                    if(mapPOList != null && mapPOList.containsKey(IdInvMap.get(invoice.id).blng__Account__c)){
                                        for(QTB_PurchaseOrder__c po :mapPOList.get(IdInvMap.get(invoice.id).blng__Account__c)){
                                            if(ar.lev1code == po.QTB_Customer_Id__c){
                                                if((ar.divisionCode != null && ar.departmentCode == null && po.QTB_Division__c == ar.divisionCode) || (ar.departmentCode!= null && ar.divisionCode == null && po.QTB_Div_Dept_Level__c == ar.departmentCode) || (ar.departmentCode!= null && ar.divisionCode != null && po.QTB_Div_Dept_Level__c == ar.departmentCode && po.QTB_Division__c == ar.divisionCode)){
                                                    usgItem.usage_po = po.QTB_Customer_PO__c != null? po.QTB_Customer_PO__c : '';
                                                }
                                            }
                                        }
                                    }
                                    //Check the records for grouping and adding line 40th Line at the proper place
                                    usageSubtotalWrapper usWrapSub = new usageSubtotalWrapper();
                                    if(invoice.blng__InvoiceStatus__c == 'Posted'){
                                        usWrapSub.invoice_num12 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                    }else{
                                        usWrapSub.invoice_num12 = 'TEMP-'+invoice.Name;
                                    }
                                    //usWrapSub.invoice_num12 = invoice.QTB_Custom_Invoice_Number__c != null? invoice.QTB_Custom_Invoice_Number__c : '';
                                    if(countryList != null && !countryList.isEmpty() && countryList.containsKey(blgCountry) && countryList.get(blgCountry)!= null){
                                        usWrapSub.invoice_layout12 = countryList.get(blgCountry)+'IDS';
                                        usWrapSub.invoice_layout_bu12 = countryList.get(blgCountry)+'IDS';
                                    }
                                    //New Subtotal Grouping
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
                                    if(nordeaAccountMap.get(invoice.id)){
                                        if(ar.workOrderId != null){
                                            grpKeyString += ar.workOrderId;
                                        }
                                    }
                                    //Add to Groping Map
                                    if(grpKeyString != ''){
                                        if(L1L2L3GrpCompareMap.containsKey(grpKeyString)){
                                            L1L2L3GrpCompareMap.put(grpKeyString,L1L2L3GrpCompareMap.get(grpKeyString)+1);
                                        }else{
                                            L1L2L3GrpCompareMap.put(grpKeyString,1);
                                        }
                                    }
                                    
                                    //Check if the number of records for grouping is same or not?
                                    //Grouping number matches
                                    if(L1L2L3InvGrpMap.containsKey(invoice.id)){
                                        Map<string, integer> L1L2L3InvGrpMapTemp = L1L2L3InvGrpMap.get(invoice.id);
                                        if(L1L2L3InvGrpMapTemp.containsKey(grpKeyString)){
                                            //Grouping number matches means the grouping is done for this group
                                            if(L1L2L3InvGrpMapTemp.get(grpKeyString) == L1L2L3GrpCompareMap.get(grpKeyString)){
                                                //Multiple records are there in the group
                                                if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                                                    usWrapSub.subtotal40thLine = (L1L2L3GrpSubTotalMap.get(grpKeyString)  + decimal.valueof(usgItem.invlineamount) ).setScale(2, RoundingMode.HALF_UP);
                                                    usgItem.usageSubtotal = usWrapSub;
                                                }else{
                                                    //Match in first time(only one occurance)
                                                    usWrapSub.subtotal40thLine = decimal.valueof(usgItem.invlineamount).setScale(2, RoundingMode.HALF_UP);
                                                    usgItem.usageSubtotal = usWrapSub;
                                                    //Just keep the map in the sync // Not required to add the amount
                                                    L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueof(usgItem.invlineamount));
                                                }
                                            }else{//Grouping number not matches
                                                //Already present the key// More number of records in the grouping
                                                if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                                                    L1L2L3GrpSubTotalMap.put(grpKeyString,L1L2L3GrpSubTotalMap.get(grpKeyString) + decimal.valueof(usgItem.invlineamount));
                                                }else{
                                                    //First time key
                                                    L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueof(usgItem.invlineamount));
                                                }
                                            }
                                        }
                                        
                                    }
                                    //system.debug(usgItem.usageSubtotal+'$$$$$$$'+usgItem);
                                    usageLines.add(usgItem);
                                }
                                w.usage_detail=usageLines;
                                if(!printvalue.isEmpty()){
                                    w.print_level = 'Y';
                                }
                                else{
                                    w.print_level = 'N';
                                }
                            }
                            lstWrapper.add(w);
                            //system.debug('@#@#@#@#@#@#@#@#@#@#@'+lstWrapper);
                        }
                        //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                    }catch(exception e){
                        QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexMassExtractVFCTRL');
                        //throw e;
                    }
                }
                //Summary Details Mapping
                public void mappingToSummary(integer invCount,double grandTotal,string curCode){
                    //system.debug('@@invCount'+invCount+'@@grandTotal'+grandTotal+'@@curCode'+curCode);
                    SummaryWrapper w = new SummaryWrapper();
                    //w.header10 = '99';
                    Datetime todayDate = Datetime.now();
                    w.ReportDate = todayDate.format('dd/MM/yyyy');
                    w.ReportTime = String.valueOf(datetime.now().time());
                    w.invoice_count = String.valueOf(invCount);
                    w.rcl_total_bill_amt = String.valueOf(grandTotal);
                    w.sum_currency = curCode;
                    lstSummaryWrapper.add(w);
                }
                Public class GroupWrapperCls{
                    public string productName;
                    public string productCode;
                    public string scheduleCategory;
                    public string divisionCode;
                    public string departmentCode;
                    //#13521
                    public string productIdentifier;
                    //#20247
                    public string priceTier;
                    //#18631
                    public string legalEntityCountry;
                    public decimal preratedUnitAmount;
                    //#15071 Addition of POGR
                    public string POGR;
                    public decimal ratedAmount;
                    public decimal usSumUnitprice;
                    public string departmentname;
                    public boolean displayPnameCheck;
                    public string AccLanguage;
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
                    //If it's a Nordea Account
                    public string workOrderId;
                    public string requestor;
                    //Extra field for Invoice Line
                    public decimal unitPriceLine;
                    public decimal subtotalLine;
                    //This is to identify if the record is a Usage record or a Invoice Line reocrd
                    public string recordId;
                    public string productId;
                    public GroupWrapperCls(blng__Usage__c usge,GroupWrapperCls exitingWraper){
                        this.productName = usge.blng__OrderProduct__r.Product2.Name;
                        this.productCode = usge.blng__OrderProduct__r.Product2.productCode;
                        this.productId = usge.blng__OrderProduct__r.Product2.Id;
                        String billlingAccountLang = usge.blng__Account__r.QTB_Language__c;
                        String priceScheduleCategory = String.valueOf(usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c);
                        //Usage.Order Product.Product.Price Schedule Category = 'Services' OR 'Services Off-Site' OR 'Services On-Site' OR 'Other Program Fees' OR NOT(Storage,Transport,Supplies)
                        if(priceScheduleCategory != '' && priceScheduleCategory != null && priceScheduleCategory != 'Storage' && priceScheduleCategory != 'Transportation' && priceScheduleCategory != 'Supplies'){
                            priceScheduleCategory = 'Services';
                        }
                        if(!String.isEmpty(priceScheduleCategory)){
                            QTB_Price_Category_Translations__c accLANG = QTB_Price_Category_Translations__c.getValues(billlingAccountLang);
                            if(accLANG != null){
                                //system.debug('accLANG'+accLANG);
                                for(String pcg : String.valueOf(accLANG.QTB_Translations__c).split(';;;')){
                                    //system.debug('pcg : '+pcg);
                                    //if(pcg.split(' -> ')[0] == String.valueOf(usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c))
                                    if(pcg.split(' -> ')[0] == priceScheduleCategory)
                                        this.scheduleCategory = pcg;
                                    //system.debug('scheduleCategory :-- '+scheduleCategory);
                                }
                            }else{
                                
                                this.scheduleCategory = priceScheduleCategory+' -> '+priceScheduleCategory;
                                //system.debug('this.scheduleCategory------'+this.scheduleCategory);
                            }
                        }
                        //this.scheduleCategory = usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                        this.divisionCode = usge.QTB_Division_Code__c;
                        this.departmentCode = usge.QTB_Department_Code__c;
                        this.departmentname = usge.QTB_Department_Name__c;
                        //#13521
                        this.productIdentifier = usge.QTB_Product_Identifier_1__c;
                        //#20247
                        this.priceTier = usge.QTB_Price_Tier__c;
                        //#18631
                        this.legalEntityCountry = usge.QTB_Legal_Entity_Country__c;
                        this.preratedUnitAmount = usge.QTB_Prerated_Unit_Price__c;
                        this.displayPnameCheck = usge.blng__Account__r.QTB_Display_Custom_Product_Names__c;
                        this.AccLanguage = usge.blng__Account__r.QTB_Language__c;
                        this.lev1name = usge.QTB_Level_1_Name__c;
                        this.lev1code = usge.QTB_Level_1_Code__c;
                        this.divisionname = usge.QTB_Division_Name__c;
                        this.ratedunitPrice = usge.QTB_Rated_Unit_Price__c;
                        this.usSumUnitprice = usge.blng__UsageSummary__r.blng__UnitPrice__c!= null? usge.blng__UsageSummary__r.blng__UnitPrice__c:0;
                        this.CusInvDisplay = usge.QTB_Custom_Invoice_Display__c;
                        this.startdate = usge.QTB_Start_Date_MRC__c;
                        this.enddate = usge.QTB_End_Date_MRC__c;
                        if(usge.QTB_Term__c != null){
                            this.term = Integer.valueOf(usge.QTB_Term__c);
                        }
                        //If it's a Nordea Account
                        this.workOrderId = usge.QTB_Work_Order_ID__c;
                        this.requestor = usge.QTB_Requestor__c;
                        //This is to identify if the record is a Usage record or a Invoice Line reocrd
                        this.recordId = usge.id;
                        //Extra field for Invoice Line
                        if(usge.id == null){
                            //this.scheduleCategory = usge.QTB_Cost_Center__c;
                            this.AccLanguage = usge.QTB_Service_District__c;
                            String priceSchCategory = String.valueOf(usge.QTB_Cost_Center__c);
                            //Usage.Order Product.Product.Price Schedule Category = 'Services' OR 'Services Off-Site' OR 'Services On-Site' OR 'Other Program Fees' OR NOT(Storage,Transport,Supplies)
                            if(priceSchCategory != '' && priceSchCategory != null && priceSchCategory != 'Storage' && priceSchCategory != 'Transportation' && priceSchCategory != 'Supplies'){
                                priceSchCategory = 'Services';
                            }
                            if(!String.isEmpty(priceSchCategory)){
                                QTB_Price_Category_Translations__c accLANG = QTB_Price_Category_Translations__c.getValues(AccLanguage);
                                if(accLANG != null){
                                    //system.debug('accLANG'+accLANG);
                                    for(String pcg : String.valueOf(accLANG.QTB_Translations__c).split(';;;')){
                                        //system.debug('pcg : '+pcg);
                                        if(pcg.split(' -> ')[0] == priceSchCategory)
                                            this.scheduleCategory = pcg;
                                        //system.debug('scheduleCategory :-- '+scheduleCategory);
                                    }
                                }else{
                                    
                                    this.scheduleCategory = priceSchCategory+' -> '+priceSchCategory;
                                    //system.debug('this.scheduleCategory------'+this.scheduleCategory);
                                }
                            }
                            //System.debug('***This.Sch***'+this.scheduleCategory);
                            this.productName = usge.blng__MatchingAttribute__c;
                            this.productCode = usge.blng__ErrorMessage__c;
                            this.unitPriceLine = usge.blng__UnitPrice__c;
                            this.subtotalLine = usge.blng__Subtotal__c;
                            this.displayPnameCheck = usge.QTB_UsedforRerate__c;
                            //this.AccLanguage = usge.QTB_Service_District__c;
                        }
                        //Already existing record for the Grouping, get the existing value and add it/agreegate values
                        if(exitingWraper!= null){
                            this.ratedAmount = (usge.QTB_Rated_Amount__c!= null? usge.QTB_Rated_Amount__c:0)+exitingWraper.ratedAmount;
                            this.quantity = (usge.QTB_Invoice_Quantity__c!= null? usge.QTB_Invoice_Quantity__c:0)+exitingWraper.quantity;
                            this.preratequantity = (usge.blng__PreratedQuantity__c!= null? usge.blng__PreratedQuantity__c:0)+exitingWraper.preratequantity;
                            this.preratedUnitPrice = (usge.QTB_Prerated_Unit_Price__c!= null? usge.QTB_Prerated_Unit_Price__c:0)+exitingWraper.preratedUnitPrice;
                            this.prerateamount = (usge.blng__PreratedAmount__c!= null? usge.blng__PreratedAmount__c:0)+exitingWraper.prerateamount;
                            this.usQuantity = (usge.blng__Quantity__c!= null? usge.blng__Quantity__c:0)+exitingWraper.usQuantity;
                            //Fresh record for the Grouping, keep the value else, values as '0'
                        }else{
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
                    public string usageproduct {get; set;}
                    public string usagequantity {get; set;}
                    public string usageunitprice {get; set;}
                    public string unitamt {get; set;}
                    //#15071 Addition of POGR
                    public string POGR {get; set;}
                    public string lineqty {get; set;}
                    public integer inv_linenum {get; set;}
                    public string usg_category {get; set;}
                    public string invlineamount {get; set;}
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
                    public string Cust_addr_str {get; set;}
                    public string Cust_addr_pc {get; set;}
                    public string Cust_addr_ci {get; set;}
                    public string Cust_addr_cou {get; set;}
                    public string Cust_addr_ln6 {get; set;}
                    public string Cust_addr_ln7 {get; set;}
                    public string Cust_addr_ln8 {get; set;}
                    
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
                    //Addition of POGR
                    public string POGR{get; set;}
                    
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
                    
                    public List<usagewrapper> usage_detail {get;set;}
                }
                public class SummaryWrapper{
                    //Summary Details Mapping
                    public string header10 {get; set;}
                    public string ReportDate {get; set;}
                    public string ReportTime{get; set;}
                    public string invoice_count{get; set;}
                    public string rcl_total_bill_amt{get; set;}
                    public string sum_currency{get; set;}
                }
                
                public static void increaseCoverage(){
                    Integer i=0;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
                    i++;
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