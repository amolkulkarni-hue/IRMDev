/*****************************************************************************************************
* Class: QTB_InvoiceLineHelperUtils
* Author: Accenture
* Purpose: Utilize this class for writing methods related to Invoice Line
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Virtusa       12/27/2023     Tax Rounding for creation of Tax Detail records based on Tax Type Flat Rate and Product Based
* Sarwar        04/10/2025     Optimized the class and changed the return type of few method to perform DML on InvoiceLineHelper(#29100)
*******************************************************************************************************/
public without sharing class QTB_InvoiceLineHelperUtils {
    
    public static final String INVOICELINE_HELPER_UTILS = 'QTB_InvoiceLineHelperUtils';
    //Gitlab 20432 List of Invoice Line ID for Tax Rounding
    public static Map<String, List<blng__TaxRate__c>> taxRatesMaps = new Map<String, List<blng__TaxRate__c>>();
    
    /***********************************************************************************************************
* Method : updateInvcAndInvocLineWithTaxOverride
* Parameters: List<blng__InvoiceLine__c>, Set<String>
* Return Type : void
* Description: This is having the Functionality to update Tax Override Amount on Invoice and Invoice Line based on Tax Type
* Change History: 
* Description: Gitlab #20432
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------- 
* Virtusa        27/12/2023        To update new field of QTB_Tax_Override_Amount__c on invoice and invoice line based on Tax Type Flat Rate and Product based based on story #20432.
* Virtusa        19/03/2025      Changed return type to List<Sobject> 29100
**************************************************************************************************************/
    public static List<SObject> updateInvcAndInvocLineWithTaxOverride(Map<ID,blng__InvoiceLine__c> invoiceLineMap, Set<String> addressComparisonSet){
           
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invoiceLineMap== null || addressComparisonSet== null || invoiceLineMap.isEmpty()||addressComparisonSet.isEmpty()){return null;}//US #29100 early exit if parameters are null
            
            //#24548 - Start //#29100 placed inside try block
            List<blng__InvoiceLine__c> listInvoiceLine = invoiceLineMap.values();
            QTB_RecursiveHandlerCheck.updateInvcAndInvocLineWithTaxOverrideAmntAfterInsert.put('afterinsert',invoiceLineMap.keySet()); 
            //#24548 - Stop   
            List<SObject> recordsToUpdateList = new List<SObject>();  // List to store the records to update 29100
            List<blng__InvoiceLine__c> listUpdateInvcLine  = new List<blng__InvoiceLine__c>();// List to Update Invoice Line for when Tax Applicability is Product Based
            Map<ID,blng__Invoice__c> mapOfInvcIdAndInvc = new Map<ID,blng__Invoice__c>(); // Map to store Invoice ID and List of invoice which will get updated when Tax Applicability is Flat Rate
            Map<ID,Decimal> mapOfInvcIdTaxOvrd = new Map<ID,Decimal>();
            Map<ID,Boolean>mapOfInvIdAndTieredLines = new Map<ID,Boolean>(); // #30514 map to store if invoice has any tiered invoice line
            boolean hasTieredLines = false; // #30514
            QTB_InvoiceHelper.buildTaxRateMap(addressComparisonSet); // Calling buildTaxRateMap method to get taxrate records 
            // Create Map of address comparison key with List of tax rate record
            taxRatesMaps = QTB_InvoiceHelper.taxRatesMap;// #29100 Note that taxRatesMaps is a static variable refernced from QTB_InvoiceHelper

            if(listInvoiceLine== null || listInvoiceLine.isEmpty()) {return null;}//US #29100 early exit if listInvoiceLine is null

            for(blng__InvoiceLine__c invLine : listInvoiceLine){// Iterating over each Invoice Line to update Tax override amount
                
                //#24548 - Start 
                if(QTB_RecursiveHandlerCheck.updateInvcAndInvocLineWithTaxOverrideAmntAfterInsert.get('afterinsert').contains(invLine.Id)){
                //#24548 - Stop 
                  
                    blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(); //Initialization and decleration of blng__InvoiceLine__c to store the Invoice Line when Tax Applicability is Product Based 
                    blng__Invoice__c invc = new blng__Invoice__c(); //Initialization and decleration of Invoice to store the Invoice when Tax Applicability is Flat Rate 
                    invc.QTB_resendToVertex__c = false; //#34196 making it to false
                    //#30514 - updating has tiered lines to true if any invoice line has tiered flag as true
                    hasTieredLines = invLine.QTB_Tiered_Flag__c;
                    // if tiered flag is true line than storeing in map, which will help to update has tired flag to true on invoice
                    if(!mapOfInvIdAndTieredLines.containsKey(invLine.blng__Invoice__r.ID) && hasTieredLines){
                        mapOfInvIdAndTieredLines.put(invLine.blng__Invoice__r.ID,True);
                    }
                    // Create Address comparison String to compare address with Tax Rate addressComparisonSet field //US #29100 added .replace directly into the String
                    String invoiceLineComparison = (invLine?.blng__TaxCountry__c +'----' + invLine?.QTB_Tax_Code__c +'-' + invLine?.blng__LegalEntity__c).replaceAll('null','');//remove null FROM String;
                     String taxExempt = invLine?.blng__Invoice__r?.blng__Account__r?.SBQQ__TaxExempt__c;
                    // Update QTB_Tax_Override_Amount__c on invoice and Invoice Line when Tax Exempt on Account is No
                    if(taxExempt != null && taxExempt.equalsIgnoreCase(QTB_Constants.TAX_EXEMPT_NO) &&
                    (invLine.blng__TaxPercentageApplied__c != null || (Label.QTB_NA_Countries!=null && Label.QTB_NA_Countries.containsIgnoreCase(invLine.blng__TaxCountry__c)))){ //#Gitlab 29100 added null check before checking contains Label.QTB_NA_Countries
                    
                        // Update QTB_Tax_Override_Amount__c on invoice for Tax Type Flat Rate
                        if(invLine.blng__TaxTreatment__c != null 
                        && invLine.blng__LegalEntity__r?.QTB_Tax_Applicability__c.equalsIgnoreCase(QTB_Constants.LEGALENTITY_TYPE_FLAT)
                        // Map to store Tax override amount for Invoice for Flat Rate //#29100 merged if statements
                        &&(mapOfInvcIdAndInvc!=null && !mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__c)) 
                        &&(taxRatesMaps!=null && taxRatesMaps.containsKey(invoiceLineComparison))){// merged if statement 29100
                        // comparing address comparison of invoice line with tax Rate Map along with Invoice Line Tax Treatment Null check
                    
                            // Fetching Tax Rate record FROM taxRatesMaps based on address comparison
                            for(blng__TaxRate__c taxRate : taxRatesMaps.get(invoiceLineComparison)){
                            
                                // Calculating Tax Rate value based on Rate of Tax Rate and Invoice Sub Total 
                                //#29100 used ternary operators for null check ensuring that if calculated values are!=0 taxRoundOff will have a default value of 0.0 
                                Decimal taxRoundOff =  (invLine.blng__Invoice__r.blng__Subtotal__c != null && taxRate.blng__Rate__c != null && invLine.blng__Invoice__r.blng__Subtotal__c !=0 && taxRate.blng__Rate__c!= 0)
                                ? ((invLine.blng__Invoice__r.blng__Subtotal__c * taxRate.blng__Rate__c * 0.01)).setScale(2, System.RoundingMode.HALF_UP): 0.0;
                                                                    
                                // Calculating Tax Rate value based on Rate of Tax Rate and Invoice Sub Total
                                if(mapOfInvcIdTaxOvrd!=null && !mapOfInvcIdTaxOvrd.containsKey(invLine.blng__Invoice__r.ID)){ 
                                    mapOfInvcIdTaxOvrd.put(invLine.blng__Invoice__r.ID,taxRoundOff); //#29100 taxRoundOff willAlways have a defaultValue of 0.0 soNeedNotCheck null for it 
                                }
                                // Calculating Tax Rate value based on Rate of Tax Rate and Invoice Sub Total for the country India (cgst+sgst)
                                else{ 
                                    //#29100 taxRoundOff willAlways have a defaultValue of 0.0 soNeedNotCheck null for it 
                                    mapOfInvcIdTaxOvrd.put(invLine.blng__Invoice__r.ID,(taxRoundOff + mapOfInvcIdTaxOvrd.get(invLine.blng__Invoice__r.ID)));
                                } 
                            }
                            // Create Map to store Invoice record along with its Tax override value
                            invc.ID = invLine.blng__Invoice__r.ID;
                            invc.QTB_hasTieredLines__c = false;
                            //#29100 Used TernaryOperators to check if the Map containsKey else assigned null
                            invc.QTB_Tax_Override_Amount__c = (mapOfInvcIdTaxOvrd!=null && mapOfInvcIdTaxOvrd.containsKey(invLine.blng__Invoice__r.ID)) 
                                                                ? (mapOfInvcIdTaxOvrd.get(invLine.blng__Invoice__r.ID)): 0;
                            invc.QTB_Total_Tax_Rate__c = (invLine.blng__TaxPercentageApplied__c!= null)
                                                                ? invLine.blng__TaxPercentageApplied__c : 0;
                            mapOfInvcIdAndInvc.put(invc.ID,invc);

                        }else if(invLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != QTB_Constants.LEGALENTITY_TYPE_FLAT)
                        {//#Added 29100 listUpdateInvcLine null check to avoid error while adding to the list
                        // Update QTB_Tax_Override_Amount__c on invoice line for Tax Type Product based Rate
                    
                            invoiceLine.ID = invLine.ID; 
                            invc.QTB_hasTieredLines__c = false;
                            invc.ID = invLine.blng__Invoice__r.ID;      //#29100 Used TernaryOperators to Nullcheck else assigned null
                            invoiceLine.QTB_Tax_Override_Amount__c = (invLine.blng__TaxAmount__c!= null)? invLine.blng__TaxAmount__c : 0; //#28097 Added as part to stamp the Total Tax rate for Product Based same like Flat rate
                            invc.QTB_Total_Tax_Rate__c = (invLine.blng__TaxPercentageApplied__c!= null)? invLine.blng__TaxPercentageApplied__c: 0; 
                            
                            // Update Tax Override IN Invoice
                            if(mapOfInvcIdAndInvc!= null && !mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__r.ID)){
                                invc.QTB_Tax_Override_Amount__c = invLine?.blng__TaxAmount__c;
                                mapOfInvcIdAndInvc.put(invc.ID,invc);
                            }else{ 
                                // Update Tax Override IN Invoice this condition will work for India (cgst + sgst)

                                Decimal existingTaxOverride = (mapOfInvcIdAndInvc!= null && mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__r.ID) && mapOfInvcIdAndInvc.get(invLine.blng__Invoice__r.ID).QTB_Tax_Override_Amount__c != null) 
                                                            ? (mapOfInvcIdAndInvc.get(invLine.blng__Invoice__r.Id).QTB_Tax_Override_Amount__c): 0.0; //#29100 added 0.0 in else
                                
                                //Gitlab #29100 optimized using ternary operators
                                //1. If both existingTaxOverride and invLine.blng__TaxAmount__c are non-null: Add them together.             2.If existingTaxOverride is not null and invLine.blng__TaxAmount__c is null: Keep the existing value.
                                //3. If existingTaxOverride is null and invLine.blng__TaxAmount__c is not null: Assign the new tax amount.   4. If both are null: Assign null.

                                invc.QTB_Tax_Override_Amount__c = (existingTaxOverride != null && invLine.blng__TaxAmount__c != null) 
                                                                    ? (existingTaxOverride + invLine?.blng__TaxAmount__c)
                                                                : (existingTaxOverride != null && invLine.blng__TaxAmount__c == null)
                                                                        ? (existingTaxOverride) : (invLine?.blng__TaxAmount__c);
                                mapOfInvcIdAndInvc.put(invc.ID,invc);
                            }
                            listUpdateInvcLine.add(invoiceLine);    
                        }
                    }else{  // when Tax Exempt on Account is Yes
                    // updating QTB_Tax_Override_Amount__c and QTB_Total_Tax_Rate__c to 0 at header level   
                        if(mapOfInvcIdAndInvc!=null && !mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__r.ID)){

                            invc.ID = invLine.blng__Invoice__r.ID;
                            invc.QTB_hasTieredLines__c = false;
                            invc.QTB_Tax_Override_Amount__c = 0;
                            invc.QTB_Total_Tax_Rate__c = 0;
                            mapOfInvcIdAndInvc.put(invc.ID,invc);
                        }
                        
                        // Updating QTB_Tax_Override_Amount__c to zeros on invoice line when Tax Type is Product based Rate
                        if(listUpdateInvcLine!=null && invoiceLine?.blng__LegalEntity__c!=null && invLine?.blng__LegalEntity__r?.QTB_Tax_Applicability__c.equalsIgnoreCase(QTB_Constants.LEGALENTITY_PRODUCT_BASED)){
                            
                            invoiceLine.ID = invLine.ID;
                            invoiceLine.QTB_Tax_Override_Amount__c = 0;
                            listUpdateInvcLine.add(invoiceLine);
                        }
                    }
                    /*Epic-3137 : Adding below if condition to populate Tax override amount for NA Countries Only*/
                    if(Label.QTB_NA_Countries.containsIgnoreCase(invLine.blng__TaxCountry__c))
                    {
                        Decimal taxRoundOff =  invLine.blng__TaxAmount__c!=null ? invLine.blng__TaxAmount__c : 0.0;
                        if(mapOfInvcIdTaxOvrd.isEmpty()){ 
                            mapOfInvcIdTaxOvrd.put(invLine.blng__Invoice__r.ID,taxRoundOff); //#29100 taxRoundOff willAlways have a defaultValue of 0.0 soNeedNotCheck null for it 
                        }
                        else if(!mapOfInvcIdTaxOvrd.isEmpty() && mapOfInvcIdTaxOvrd.containsKey(invLine.blng__Invoice__r.ID)){ 
                            mapOfInvcIdTaxOvrd.put(invLine.blng__Invoice__r.ID,(taxRoundOff + mapOfInvcIdTaxOvrd.get(invLine.blng__Invoice__r.ID)));
                        }
                        else{ 
                            mapOfInvcIdTaxOvrd.put(invLine.blng__Invoice__r.ID,(taxRoundOff));
                        } 
                        
                        invc.ID = invLine.blng__Invoice__r.ID;
                        invc.QTB_Tax_Override_Amount__c = mapOfInvcIdTaxOvrd.get(invLine.blng__Invoice__r.ID);
                        mapOfInvcIdAndInvc.put(invc.ID,invc); 
                    }
                    // #30514 updating has tiered line check box to true if any one invoice line has tiered checkbox true
                    if(mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__r.ID)  && mapOfInvIdAndTieredLines.containsKey(invLine.blng__Invoice__r.ID) 
                       && mapOfInvcIdAndInvc.get(invLine.blng__Invoice__r.ID).QTB_hasTieredLines__c == false){
                        mapOfInvcIdAndInvc.get(invLine.blng__Invoice__r.ID).put('QTB_hasTieredLines__c',True);
                    }
                }
            }
            mapOfInvIdAndTieredLines.clear();
            // updating tax override amount and total tax rate to 0 at invoice header level IN case of tax exmpt yes 
            if(mapOfInvcIdAndInvc!=null && !mapOfInvcIdAndInvc.isEmpty()){                          //#29100 instead of updating mapOfInvcIdAndInvc, we are
                recordsToUpdateList.addAll(mapOfInvcIdAndInvc.values()); // Adding mapOfInvcIdAndInvc to recordsToUpdateList
                mapOfInvcIdAndInvc.clear();
            }
            // update Invoice for Tax Override amount on Invoice Line when Tax Type Product Rate
            if(recordsToUpdateList!=null && listUpdateInvcLine!=null && !listUpdateInvcLine.isEmpty()){//#29100 instead of updating listUpdateInvcLine, we are
                recordsToUpdateList.addAll(listUpdateInvcLine);   // Adding listUpdateInvcLine to recordsToUpdateList
                listUpdateInvcLine.clear();//29100
            }
            if(recordsToUpdateList!=null && !recordsToUpdateList.isEmpty()){//#29100 returning recordsToUpdateList so that the method returns a value
                return recordsToUpdateList;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),INVOICELINE_HELPER_UTILS);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method : updateLegacyInvoice
* Parameters: Set<ID>
* Return Type : void to List<blng__Invoice__c> as part of 29100
* Requirement : #20657 store Update invoice type with Legacy IN which Invoioce Line order Category is Legacy
* Description: This is having the Functionality related to Bill backout process.
* Change History :
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------- 
* Virtusa        19/03/2025      Changed return type to List<Sobject> #29100
**************************************************************************************************************/
    public static List<blng__Invoice__c> updateLegacyInvoice(Set<ID> invcIdSet){ // 29100 changed case of parameter
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invcIdSet==null || invcIdSet.isEmpty()){return null;} // 29100 exit if invcIdSet is empty
            List<blng__Invoice__c> updateLegacyInvoiceList = new List<blng__Invoice__c>();
             // 29100 exit if lstInvc is empty
            for(id inv :invcIdSet){
                blng__Invoice__c invoice = new blng__Invoice__c();
                invoice.id = inv;
                invoice.QTB_Invoice_Type__c = 'Legacy Invoice';
                invoice.QTB_Transferred_To_Oracle__c = true;
                invoice.QTB_Transferred_to_Invoice_Compliance__c = System.Now().addDays(-90);
                updateLegacyInvoiceList.add(invoice);
            }
            if(updateLegacyInvoiceList!=null && !updateLegacyInvoiceList.isEmpty()){
                return updateLegacyInvoiceList; // 29100
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                INVOICELINE_HELPER_UTILS);
            throw e;
        }    
    }
    
    /**************************************************************************************************************
* Method    : cancelInvoicesWithHoldBilling
* Parameters : List<blng__InvoiceLine__c> listInvcLine
* Requirement: Gitlab US #22554 to cancel those invoices and Invoice lines WHERE Hold Billing is true eith on Account or IN OI
* Author     : Virtusa
* Description: Gitlab US #22554 to cancel those invoices and Invoice lines WHERE Hold Billing is true eith on Account or IN OI 
* Change History :
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------- 
* Virtusa        11/04/2025      Gitlab US #29100 changed the return type to List<Sobject>
**************************************************************************************************************/   
    
    public static List<SObject> cancelInvoicesWithHoldBilling(List<blng__InvoiceLine__c> listInvcLine){
        if(QTB_RecursiveHandlerCheck.cancelInvoicesWithHoldBilling == true){
            try{
                if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                    throw new NullPointerException();
                }
                if(listInvcLine == null && listInvcLine.isEmpty()){return null;}// exit early
                
                List<SObject> recordSObjectList  = new List<SObject>();  //#Gitlab 29100 store in a Sobject List
                List<blng__Invoice__c> listUpdateInvcToCancelled = new List<blng__Invoice__c>();//List of Invoice need to be cancelled when HB is True
                Set<blng__Invoice__c> setUpdateInvcToCancelled = new Set<blng__Invoice__c>();//Set of Invoice need to be cancelled when HB is True
                List<Account> listToUpdatedAcc = new List<Account>(); //List of Account to be updated for hold billing
                Set<Account> setToUpdatedAcc = new Set<Account>(); //Set of Account to be updated for hold billing
                List<blng__UsageSummary__c> updatedUsgSumList = new List<blng__UsageSummary__c>(); //List of Usage Summary to be updated for hold billing
                Map<ID,Set<ID>> mapAccIdAndInvcIdSet = new Map<ID,Set<ID>>();  // Map to store Account ID and Set of Invoice ID
                Set<ID> invcIdToBeCancelledSet = new Set<ID>(); // Set of Invoice Ids to be Cancelled
                Set<ID> invcIdSet = new Set<ID>();// Set of Invoice ID Initialization
                Set<ID> dupCheckAccountIdSet = new Set<ID>(); // Set of Invoice ID to remove duplicate 
                
                for(blng__InvoiceLine__c invoiceLine : listInvcLine){
                    if(mapAccIdAndInvcIdSet == null){ break;} //break the loop if mapAccIdAndInvcIdSet is Null to avoid null pointer errors
                    
                    if(invcIdSet!=null){ //#29100 added null check
                        invcIdSet.add(invoiceLine.blng__Invoice__c);
                    }
                    // Map to store Account ID as a key and Set of Invoice ID as a value // 29100 check if map is not empty
                    if(mapAccIdAndInvcIdSet!=null && mapAccIdAndInvcIdSet.containsKey(invoiceLine.blng__Invoice__r.blng__Account__c)){
                        invcIdSet.addAll(mapAccIdAndInvcIdSet.get(invoiceLine.blng__Invoice__r.blng__Account__c)); 
                    }
                    mapAccIdAndInvcIdSet.put(invoiceLine.blng__Invoice__r.blng__Account__c,invcIdSet);
                }
                //check holdBilling on orderItem, also excluding bundle header as bundleHeader's holdBilling is true irrespective of Account holdilling value
                if(mapAccIdAndInvcIdSet == null || mapAccIdAndInvcIdSet.isEmpty()){return null;}//#29100 Gitlab
                
                Map<ID,List<OrderItem>> productOrderItemMap = new Map<ID,List<OrderItem>>();// Map to store product ID and its related OrderItem
                List<OrderItem> ordItmList = new List<OrderItem>();  //List of order item on which to check hold billing value, excluding bundle header order products
                Set<ID> bundleProductCheckSet = new Set<ID>();
                // querying on order item to check whether OI is bundle product or not, checking with field SBQQ__RequiredBy__c 
                for(OrderItem ordItm :[SELECT ID,SBQQ__RequiredBy__c , Product2Id, OrderId,blng__HoldBilling__c,Order.Account.QTB_Hold_Status__c ,Order.AccountId,Order.Account.QTB_Hold_Billing__c
                                       FROM OrderItem 
                                       WHERE Order.AccountId IN :mapAccIdAndInvcIdSet.keySet() AND SBQQ__Activated__c = true AND Order.QTB_OrderCategory__c !='Rebill' AND Order.QTB_OrderCategory__c !='Legacy' AND (SBQQ__TerminatedDate__c = null OR SBQQ__TerminatedDate__c >= TODAY)
                                       AND (blng__HoldBilling__c = 'Yes' OR Order.Account.QTB_Hold_Billing__c = true)]){ 
                                           // storing product ID and its related List of order item into Map
                                           if(productOrderItemMap!=null && productOrderItemMap.containsKey(ordItm.product2Id)){
                                               productOrderItemMap.get(ordItm.product2Id).add(ordItm);
                                           }else if(productOrderItemMap!=null){
                                               productOrderItemMap.put(ordItm.product2Id,new List<OrderItem>{ordItm});
                                           }
                                           // 29100 this if block was twice in each if and else in the condition if(productOrderItemMap.containsKey(ordItm.product2Id))
                                           if(ordItmList!=null && ordItm.SBQQ__RequiredBy__c != null){
                                               ordItmList.add(ordItm); //adding this product to main List as these products are part of bundle product
                                           }else if(bundleProductCheckSet!=null){ //#29100 added null check to avoid null pointer error enciuntered during Unit Testing
                                               bundleProductCheckSet.add(ordItm.Product2Id);// if SBQQ__RequiredBy__c is null -> order item is either standalone product or bundle product
                                           }
                                       }
                // checking on the order item's product, whethere it is bundle product or not
                if(bundleProductCheckSet== null || bundleProductCheckSet.isEmpty()){ 
                    for(Product2 prd :[SELECT ID,(SELECT ID FROM sbqq__Options__r LIMIT 1) 
                                       FROM Product2 
                                       WHERE ID IN :bundleProductCheckSet]){
                                           // if product is not having any product option that means, it is not bundle product
                                           if(ordItmList!=null && productOrderItemMap!=null && prd.sbqq__Options__r.isEmpty()&& productOrderItemMap.containsKey(prd.ID)){ //Gitlab US#29100 -- added containsKey check
                                               ordItmList.addAll(productOrderItemMap.get(prd.ID)); // adding the order item to the List to chcking hold billing
                                           }
                                       }
                }
                if(ordItmList == null || ordItmList.isEmpty()){
                    for (OrderItem oi : ordItmList){
                        if(invcIdToBeCancelledSet!=null &&(oi?.blng__HoldBilling__c=='Yes' || oi?.Order.Account.QTB_Hold_Billing__c == true)  // Check for Hold Billing True
                           // Set of Invoice Ids to be Cancelled due to Hold Billing #29100 and merged the if statements 
                           &&(mapAccIdAndInvcIdSet!=null && dupCheckAccountIdSet!=null && mapAccIdAndInvcIdSet.containsKey(oi.Order.AccountId) && !dupCheckAccountIdSet.contains(oi.Order.AccountId))){
                               
                               invcIdToBeCancelledSet.addAll(mapAccIdAndInvcIdSet.get(oi.Order.AccountId)); 
                               dupCheckAccountIdSet.add(oi.Order.AccountId);
                           }
                    }
                }
                
                for(blng__InvoiceLine__c invoiceLine : listInvcLine){
                    
                    if(setToUpdatedAcc!=null && setUpdateInvcToCancelled!=null && updatedUsgSumList!=null
                       &&invcIdToBeCancelledSet!=null && invcIdToBeCancelledSet.contains(invoiceLine.blng__Invoice__c)){ // removed || Test.isRunningTest()
                           
                           // Add the invoice to be Cancell to the collection for later update 29100
                           setUpdateInvcToCancelled.add(new blng__Invoice__c(ID = invoiceLine.blng__Invoice__c, blng__InvoiceStatus__c = 'Cancelled'));
                           // Add the Account to be updated Hold Update Fail to the collection for later update 29100
                           setToUpdatedAcc.add(new Account(ID = invoiceLine.blng__Invoice__r.blng__Account__c, QTB_Hold_Status__c = 'Hold Update Failed'));
                           // Update Usage Summary back to Pending Billing FROM IN Progress to get Invoiced again ,Add the blng__UsageSummary__c to the collection for later update 29100
                           updatedUsgSumList.add(new blng__UsageSummary__c(ID = invoiceLine.blng__UsageSummary__c,blng__InvoiceRun__c = null,  blng__InvoiceRunProcessingStatus__c = 'Pending Billing',blng__InvoiceRunStartDate__c = null));
                       }
                }
                if(listUpdateInvcToCancelled!=null && setUpdateInvcToCancelled!=null && setUpdateInvcToCancelled.isEmpty()){
                    QTB_RecursiveHandlerCheck.cancelInvoicesWithHoldBilling = false;  // Make recurssive handler check false
                    listUpdateInvcToCancelled.addAll(setUpdateInvcToCancelled);       // List to update Cancelled invoices
                }
                if(setToUpdatedAcc!=null && listToUpdatedAcc!=null && recordSObjectList!=null){
                    listToUpdatedAcc.addAll(setToUpdatedAcc); //List to update Account with Hold update fail
                    recordSObjectList.addAll(listToUpdatedAcc);////#29100 added to recordSObjectList bec Set cant be added directly
                }
                // Switching off trigger to update Invoice status to Cancelled
                SBQQ.TriggerControl.disable();
                if(listUpdateInvcToCancelled!=null && !listUpdateInvcToCancelled.isEmpty() && Schema.sObjectType.blng__Invoice__c.isUpdateable()){
                    update listUpdateInvcToCancelled; //#29100 Gitlab Added empty check and verified if we have proper access
                }
                SBQQ.TriggerControl.enable();
                
                if(updatedUsgSumList!=null && recordSObjectList!=null){
                    recordSObjectList.addAll(updatedUsgSumList);//#29100 updatedUsgSumList added to recordSObjectList
                }
                /*update listToUpdatedAcc;
update updatedUsgSumList; //#29100 Gitlab to review and then remove */
                
                invcIdSet.clear(); // 29100
                bundleProductCheckSet.clear(); 
                productOrderItemMap.clear();
                ordItmList.clear();
                dupCheckAccountIdSet.clear(); // clear duplicate invoice ID Set
                listInvcLine.clear(); // 29100
                listUpdateInvcToCancelled.clear(); // Releasing memory of List
                setToUpdatedAcc.clear();//#29100 Gitlab
                
                if(recordSObjectList!=null && !recordSObjectList.isEmpty()){
                    return recordSObjectList; //#29100 Gitlab Added empty check and returned values
                }else{
                    return null;
                }
            }catch(Exception e){
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(
                    e.getLineNumber(),
                    e.getStackTraceString(),
                    e.getMessage(),
                    e.getTypeName(),
                    INVOICELINE_HELPER_UTILS);
                throw e;
            }
        }else{
            return null; //Gitlab #US29100 added return type
        }
    }
    
    /***********************************************************************************************************
* Method    : setUOMcodeTranslation
* Parameters : List<blng__InvoiceLine__c> invLineUOMList, List<Account>accList
* Requirement: Gitlab US #24775
* Author     : Virtusa
* Description: setting Translated value for UOM, this method is getting called FROM QTB_accountHelper also 
when Account language is updated 
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------- 
* Virtusa        11/04/2025      Added Proper null checks and clearedMemory #29100
**************************************************************************************************************/   
    public static void setUOMcodeTranslation(List<blng__InvoiceLine__c> invLineUOMList, List<Account> accList) {
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if((invLineUOMList == null || invLineUOMList.isEmpty()) && (accList == null ||accList.isEmpty())){ return;}// return null if both the lists are empty 29100 and check the next ifElse
            
            //When Before_Insert is triggered FROM invLine item then iterating on List of InvLine and getting the QTB_UOM__c value & accLan values
            else if(invLineUOMList != null && !invLineUOMList.isEmpty()){
                updateUOM(invLineUOMList,'BEFORE_INSERT');
            }
            //When After_Update is triggered FROM Account helper when language is changed then iterating on List of Account ids and getting the invoiceLine 
            //(updating only that invoiceLine WHERE invoice's QTB_Transferred_to_Invoice_Compliance__c and QTB_transfered_to_invoice_presentment__c is blank)
            else if(accList!=null && !accList.isEmpty()){
                
                List<blng__InvoiceLine__c> invoiceLineList = [SELECT ID,QTB_Translated_UOM__c,QTB_AccountLanguage__c,blng__TaxCountry__c, QTB_UOM__c,blng__Product__c,blng__Product__r.name,blng__Invoice__c, blng__Invoice__r.blng__Account__c,blng__Invoice__r.QTB_LegalEntityCountry__c 
                                                              FROM blng__InvoiceLine__c 
                                                              WHERE blng__Invoice__r.blng__Account__c IN :accList AND blng__Invoice__r.QTB_Transferred_to_Invoice_Compliance__c = null AND blng__Invoice__r.QTB_transfered_to_invoice_presentment__c = null];  
                updateUOM(invoiceLineList,'AFTER_UPDATE');
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                INVOICELINE_HELPER_UTILS);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method    : updateUOM
* Parameters : List<blng__InvoiceLine__c> invLineUOMList, String OperationType
* Requirement: Gitlab US #24775
* Author     : Virtusa
* Description: setting Translated value for UOM
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------- 
* Virtusa        11/04/2025      Added Proper null checks and clearedMemory #29100
**************************************************************************************************************/
    public static void updateUOM(List<blng__InvoiceLine__c> invLineUOMList,String operationType){
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invLineUOMList == null || invLineUOMList.isEmpty() || operationType == null){ return;} // 29100 return early
            
            Set<String> uomValueSet = new Set<String>();
            Set<String> accLangValueSet = new Set<String>();
            if(uomValueSet!=null && accLangValueSet != null){ //#29100 Added nullCheck as we are using .clear() and thats throwing NullPointer error
                for(blng__InvoiceLine__c invL : invLineUOMList){
                    uomValueSet.add(invL?.QTB_UOM__c);
                    accLangValueSet.add(invL?.QTB_AccountLanguage__c);
                }
            }
            if(uomValueSet.isEmpty() || accLangValueSet.isEmpty()){return; } // 29100 return early if nul
            
            Map<String,QTB_UOM_Code_Translation__mdt> uomTranslationMap = new Map<String,QTB_UOM_Code_Translation__mdt>();// //Create a Map of QTB_UOM_Code_Translation__mdt, key as combination of QTB_UOM__c and QTB_Language__c
            //query QTB_UOM_Code_Translation__mdt records for translating UOM based on Account language
            for(QTB_UOM_Code_Translation__mdt transUOMcode :[SELECT ID, QTB_UOM__c, QTB_Language__c, QTB_Translated_Value__c 
                                                             FROM QTB_UOM_Code_Translation__mdt 
                                                             WHERE QTB_UOM__c IN:uomValueSet AND QTB_Language__c IN :accLangValueSet]){ //Gitlab US#29100 -- added  and then removed(#30721) WITH SECURITY_ENFORCED 
                                                                 if(uomTranslationMap!=null){
                                                                     uomTranslationMap.put((transUOMcode?.QTB_UOM__c+transUOMcode?.QTB_Language__c).toLowerCase(),transUOMcode);
                                                                 }// Gitlab #29100 transUOMcode.QTB_UOM__c && transUOMcode.QTB_Language__c beacuse the value comes from uomValueSet and accLangValueSet and we have already verified that theyre not null before placing on the SOQL for Loop
                                                                 uomValueSet.clear();
                                                                 accLangValueSet.clear();
                                                             }
            
            //Iterating on List of invoiceLine
            for(blng__InvoiceLine__c invL : invLineUOMList){
                //optimized using Ternary operators 29100
                String uomKey = (invL?.QTB_UOM__c + invL?.QTB_AccountLanguage__c).toLowerCase();
                invL.QTB_Translated_UOM__c = (uomTranslationMap!=null &&uomTranslationMap.containsKey(uomKey))
                    ? (uomTranslationMap.get(uomKey)?.QTB_Translated_Value__c) 
                    : (String.isNotBlank(System.label.QTB_FuelSurWorkOrderCountries) && System.label.QTB_FuelSurWorkOrderCountries.contains(invL?.blng__TaxCountry__c) && invL?.Name.containsIgnoreCase('Fuel Surcharge')) //GITLAB US #30937 Checking IF the counrties name matches with UOM country list
                ? 'Work Order' : invL?.QTB_UOM__c;  //GITLAB US #30937 Used Custom labels to store all UOM related countries list
            }
            uomTranslationMap.clear();
            if(invLineUOMList !=null && !invLineUOMList.isEmpty() && operationType.equalsIgnoreCase('AFTER_UPDATE')){
                update invLineUOMList;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),INVOICELINE_HELPER_UTILS);
            throw e;
        }
    }
}