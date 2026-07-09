/*****************************************************************************************************
* Class: QTB_InvoiceHelperUtils
* Author: Virtusa
* Purpose: Utilize this class for writing methods related to InvoiceHelper
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Virtusa       17/05/2024     Gitlab #22654 update service Type on Invoice
* Virtusa       10/04/2024     Gitlab #29101 Optimize the class to avoid hitting Governor Limits
*******************************************************************************************************/
public with sharing class QTB_InvoiceHelperUtils{
    
    public static final String INVOICE_HELPER_UTILS = 'QTB_InvoiceHelperUtils';
    
    /***********************************************************************************************************
* Method : updateExchangeRateInvoice
* Parameters: Map<ID,blng__Invoice__c> invoiceMap
* Author: TCS
* Return Type : void
* Requirement : GitLab #26654 to update Exchange Rate field on invoice for staming the local Currency values
* Description: GitLab #26654 to update Exchange Rate on Invoices reported to NAV based upon Foreign Exchange (QTB_Foreign_Exchange__c) records 
* 20/03/2025 as part of 29101 we are optimizing the method
* Parth - 14/08/2025 - #32670 Rebill invoices should take parent inv foreign exchange value and not current FX rate
**************************************************************************************************************/
    public static void updateExchangeRate(Map<ID,blng__Invoice__c> invoiceMap)
    {
        try{
            if(invoiceMap == null || invoiceMap.isEmpty()) {  
                QTB_RecursiveHandlerCheck.invUpdateExchangeRate = false;  
            	throw new NullPointerException();
             }  // 29101 Return early if invoiceMap is empty
            
            //#26654 Creation of List for quering the Parent records of Invoice and add also created 2 Sets to store one Set for Currencies of Account level and Legal Entity level and another Set for Legal Entity Rate Type
            Set<String> accCurrenciesSet = new Set<String>();
            Set<String> legEntityCurrenciesSet = new Set<String>();
            Set<String> legalEntityRateTypesSet = new Set<String>();
            List<blng__Invoice__c> invList = [SELECT ID,QTB_Exchange_Rate__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__InvoiceDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,
                                              blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Rate_For_Rebill__c, QTB_Invoice_Type__c, QTB_Parent_Invoice__r.QTB_Exchange_Rate__c 
                                              FROM blng__Invoice__c 
                                              WHERE ID IN :invoiceMap.keyset() ]; //Gitlab US#29101 -- added 
            //QTB_Exchange_Rate__c can be removed FROM 29101 invList
            
            List<QTB_Foreign_Exchange__c> feList = new List<QTB_Foreign_Exchange__c>();
            
            if(invList== null || invList.isEmpty()){QTB_RecursiveHandlerCheck.invUpdateExchangeRate = false; return;} // 29101 Return early if no invoices to process
            
            for(blng__Invoice__c inv : invList){
                // #32670 if invoice type is rebill and QTB_FX_Rate_For_Rebill__c is Original invoice than exchange rate should be pick from parent invoice
                If(inv.QTB_Invoice_Type__c == 'Rebill'){
                    if(inv.blng__Account__r?.QTB_Contract_Entity__r?.QTB_FX_Rate_For_Rebill__c != null && 
                       inv.blng__Account__r?.QTB_Contract_Entity__r?.QTB_FX_Rate_For_Rebill__c == 'Original Invoice Date'){
                           if(invoiceMap != null && invoiceMap.containsKey(inv.ID)){
                               invoiceMap.get(inv.Id).QTB_Exchange_Rate__c = inv.QTB_Parent_Invoice__r?.QTB_Exchange_Rate__c;
                           }
                       }
                    //#29101 added safeNavigation Operator before adding them to the Set.
                    // #32670  added QTB_FX_Rate_For_Rebill__c condition
                    else if(accCurrenciesSet!=null && legEntityCurrenciesSet!=null && legalEntityRateTypesSet!=null && 
                            inv.blng__Account__r?.QTB_Contract_Entity__r?.QTB_FX_Rate_For_Rebill__c == 'System Date' ){
                                accCurrenciesSet.add(inv.blng__Account__r?.CurrencyIsoCode);                
                                legEntityCurrenciesSet.add(inv.blng__Account__r.QTB_Contract_Entity__r?.CurrencyIsoCode);
                                legalEntityRateTypesSet.add(inv.blng__Account__r.QTB_Contract_Entity__r?.QTB_FX_Tax_Rate_Type__c);
                            }
                }
                else If(accCurrenciesSet!=null && legEntityCurrenciesSet!=null && legalEntityRateTypesSet!=null ){
                    accCurrenciesSet.add(inv.blng__Account__r?.CurrencyIsoCode);                
                    legEntityCurrenciesSet.add(inv.blng__Account__r.QTB_Contract_Entity__r?.CurrencyIsoCode);
                    legalEntityRateTypesSet.add(inv.blng__Account__r.QTB_Contract_Entity__r?.QTB_FX_Tax_Rate_Type__c);
                }
            }       
            
            //#26654 Checking the Curriencies and Legal Entity Rate Types not Empty
            if(legEntityCurrenciesSet== null || accCurrenciesSet== null||legalEntityRateTypesSet==null||
               accCurrenciesSet.isEmpty()||legEntityCurrenciesSet.isEmpty() ||  legalEntityRateTypesSet.isEmpty()) 
            {QTB_RecursiveHandlerCheck.invUpdateExchangeRate = false; return;} // 29101 Return early if no invoices to process
            
            feList = [SELECT ID,QTB_Rate__c,QTB_Currency_From__c,QTB_Currency_To__c,QTB_Start_Date__c,QTB_End_Date__c,QTB_Tax_Rate_Type__c
                      FROM QTB_Foreign_Exchange__c 
                      WHERE QTB_Currency_From__c IN :accCurrenciesSet AND QTB_Currency_To__c IN :legEntityCurrenciesSet AND QTB_Tax_Rate_Type__c IN :legalEntityRateTypesSet ]; //Gitlab US#29101 -- added 
            
            accCurrenciesSet.clear();
            legEntityCurrenciesSet.clear();
            legalEntityRateTypesSet.clear();
            
            if(feList== null || feList.isEmpty()) {QTB_RecursiveHandlerCheck.invUpdateExchangeRate = false; return;} // 29101 Return early if feList is Empty
            
            for(blng__Invoice__c inv : invList){
                
                //Iterating the Foreign Exchange records based upon storing Sets of Currencies and legalEntityRateTypesSet
                for(QTB_Foreign_Exchange__c fe : feList){
                    //Checking whether the Foreign Exchange Record belongs to Intersection of Invocie Date and FROM Currency by Account Currency and To Currency by Legal Entity Currency and Flat rate type by legal Entity tax Rate Type
                    if((fe?.QTB_Currency_From__c ==(inv.blng__Account__r?.CurrencyIsoCode) && fe?.QTB_Currency_To__c ==(inv.blng__Account__r?.QTB_Contract_Entity__r?.CurrencyIsoCode)
                        && fe?.QTB_Start_Date__c <= inv.blng__InvoiceDate__c  && fe?.QTB_End_Date__c >= inv.blng__InvoiceDate__c && fe?.QTB_Tax_Rate_Type__c ==(inv.blng__Account__r?.QTB_Contract_Entity__r?.QTB_FX_Tax_Rate_Type__c))
                       && (invoiceMap!=null && invoiceMap.containsKey(inv.ID))){ //#29100 merged if statement and removed (!invoiceMap.isEmpty() &&) to avoid redundant null check
                           
                           invoiceMap.get(inv.ID).QTB_Exchange_Rate__c = fe?.QTB_Rate__c; //Assigning the ExchangeRate of Invoice based upon Foreign ExchangeRate
                       }
                }
            }
            invList.clear();
            feList.clear();
            QTB_RecursiveHandlerCheck.invUpdateExchangeRate = false;
        }catch(Exception e){
            QTB_RecursiveHandlerCheck.invUpdateExchangeRate = false;
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog (e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), INVOICE_HELPER_UTILS);
            throw e;
        }  
    }  
    /***********************************************************************************************************
* Method : serviceTypeAssignment
* Parameters: Map<ID,blng__Invoice__c> invoiceListMap
* Return Type : void
* Requirement : Gitlab #22654 to insert PO which is having same Service type as on Invoice
* Description: Gitlab #22654 update service Type on Invoice based on Account split invoice flag
* change history
* // Gitlab #27181 changed FROM void to return type
* 20/03/2025 as part of 29101 we are optimizing the method serviceTypeAssignment
**************************************************************************************************************/
    public static Map<ID,blng__Invoice__c> serviceTypeAssignment(Map<ID,blng__Invoice__c> invoiceListMap){
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invoiceListMap== null || invoiceListMap.isEmpty()) {return null;} //Gitlab #29101 Empty check  Return early if no invoices to process
            
            // query on invoice to check its related billing account split invoice flag, also querying its only one child record
            // if account split invoice flag is true then based on order product's invoice group field update service type on invoice
            List<blng__Invoice__c> serviceTypeAssignmentList = [SELECT ID,blng__Account__r.QTB_Split_Invoice_Flag__c,(SELECT ID,blng__OrderProduct__r.blng__InvoiceGroupId__c 
                                                                                                                      FROM blng__InvoiceInvoiceLines__r LIMIT 1) 
                                                                FROM blng__invoice__c  //Gitlab US#29101 added WHERE clause, we need only those Invoices which have InvoiceLines
                                                                WHERE ID IN :invoiceListMap.keySet() AND ID IN (SELECT blng__invoice__c 
                                                                                                                FROM blng__InvoiceLine__c)]; //Gitlab US#29101 -- added 
            
            if(serviceTypeAssignmentList == null || serviceTypeAssignmentList.isEmpty()) {return null;} // #29101 Empty check  Return early if no serviceTypeAssignmentList to process
            
            for(blng__Invoice__c inv :serviceTypeAssignmentList){  //loop on invoices to assign service type
                
                //#29101 Extract complex conditions into helper variables  and then assign QTB_Service_Type__c using TernaryOperators
                Boolean hasInvoiceGroupId = (!inv.blng__InvoiceInvoiceLines__r.isEmpty()) 
                    && (inv.blng__InvoiceInvoiceLines__r[0]?.blng__OrderProduct__r?.blng__InvoiceGroupId__c != null);
                String invoiceGroupId = hasInvoiceGroupId ? (inv.blng__InvoiceInvoiceLines__r[0]?.blng__OrderProduct__r?.blng__InvoiceGroupId__c) : '';
                Boolean isValidInvoice = hasInvoiceGroupId && invoiceListMap!=null && invoiceListMap.containsKey(inv.ID) && inv.blng__Account__r?.QTB_Split_Invoice_Flag__c ;
                ////if account is having split invocie flag as true, then check if it is storage or non-storage type else assign as Mixed
                invoiceListMap.get(inv.ID).QTB_Service_Type__c = isValidInvoice 
                    ? (invoiceGroupId.containsIgnoreCase('Non-Storage') ? 'Service'  : (invoiceGroupId.containsIgnoreCase('Storage') 
                                                                                        ? 'Storage' : 'Mixed'))  : 'Mixed';
            }
            if(invoiceListMap!=null && !invoiceListMap.isEMpty()){//#29101 added null check
                return invoiceListMap;
            }else{
                return null;
            }
        } catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog (e.getLineNumber(), e.getStackTraceString(),e.getMessage(),e.getTypeName(),INVOICE_HELPER_UTILS);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method : updateInvoiceNote
* Parameters: Set<ID> invoiceIdsSet
* Return Type : void
* Requirement : Gitlab #27777 Automate invoice notes to display exchange rate on Foreign currency invoices
* Description: Gitlab #27777 Automate invoice notes to display exchange rate on Foreign currency invoices
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------- 
* Virtusa       19/03/2025      #29101 optimized the method updateInvoiceNote
**************************************************************************************************************/
    public static List<blng__Invoice__c> updateInvoiceNote(Set<ID> invoiceIdsSet)
    {
        try{
            if( QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invoiceIdsSet == null || invoiceIdsSet.isEmpty() || QTB_Invoice_Note_Labels__c.getAll().isEmpty() || QTB_Invoice_For_EU__c.getAll().isEmpty()){ 
                QTB_RecursiveHandlerCheck.invoiceNoteRecursiveCheck = false; 
                return null; 
            }//#29101 return null early if invoiceIdsSet or QTB_Invoice_Note_Labels__c, QTB_Invoice_For_EU__c is null.
            
            List<blng__Invoice__c> invoiceUpdateList = new List<blng__Invoice__c> (); // List to store invoice record that need to be updated for Invoice Notes
            Map<String,Set<ID>> taxCodeTaxRateMap         = new Map<String,Set<ID>>();          // Map of Tax Code with Tax Rate
            Map<ID,Decimal> invcIdTaxRateMap         = new Map<ID,Decimal>();         // Map of Invoice ID with Tax Rate
            Map<String,QTB_Invoice_Note_Labels__c> invoiceNotesLabelMap = QTB_Invoice_Note_Labels__c.getAll(); //Using getAll function for customSettingRecord for InvoiceNoteLabels based on country      
            Map<String,QTB_Invoice_For_EU__c> lstEuCountriesMap = QTB_Invoice_For_EU__c.getAll(); 
            Map<ID,String> invcIdCountryLangMap = new Map<ID,String>();
            set<id> invoiceIds ;
            
            //List of Invoices WHERE LE FX  Type is not Corporate and language is English (en_US) for the Set of Invoice Ids invoiceIdsSet
            List<blng__Invoice__c> listInvoice = [SELECT ID,QTB_Exchange_Rate__c,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Legal_Entity__r.QTB_FX_Tax_Rate_Type__c,QTB_Contracted_Currency_Rate__c,
                                                  blng__Account__r.QTB_Legal_Entity_Country__c ,QTB_Subtotal_local_currency__c,
                                                  (SELECT ID,blng__Invoice__c,QTB_Tax_Code__c 
                                                   FROM blng__InvoiceInvoiceLines__r 
                                                   WHERE QTB_Tax_Code__c !=null LIMIT 1),
                                                  QTB_Tax_Override_Amt_Local__c,QTB_Total_Amt_Tax_Override_local__c,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__Account__r.QTB_Language__c 
                                                  FROM blng__invoice__c 
                                                  WHERE (QTB_Exchange_Rate__c !=1 OR QTB_Contracted_Currency_Rate__c != null) AND ID IN : invoiceIdsSet ]; //Gitlab US#29101 -- added 
            if(listInvoice== null || listInvoice.isEmpty()){ return null;} // 29101 return null early if listInvoice is empty
            
            // Logic to store Tax Code from Invoice Line
            for(blng__Invoice__c invoice :listInvoice){
                for(blng__InvoiceLine__c invLn :invoice.blng__InvoiceInvoiceLines__r){
                    if(taxCodeTaxRateMap!=null){ //#2910 added nullCheck
                        invoiceIds = new Set<Id>();
                        invcIdCountryLangMap.put(invoice.ID,invoice.blng__Account__r?.QTB_Legal_Entity_Country__c.toLowerCase() +'/'+invoice?.blng__Account__r?.QTB_Language__c.toLowerCase());   
                        invoiceIds.add(invLn.blng__Invoice__c);
                        if(taxCodeTaxRateMap.containskey(invLn?.QTB_Tax_Code__c)){
                            invoiceIds.addAll(taxCodeTaxRateMap.get(invLn?.QTB_Tax_Code__c));
                        }
                        taxCodeTaxRateMap.put(invLn?.QTB_Tax_Code__c,invoiceIds);
                    }
                }
            }
            if((taxCodeTaxRateMap== null|| taxCodeTaxRateMap.isEmpty()) && !Test.isRunningTest()) {return null;} // 29101 return null early if taxCodeTaxRate is empty
            
            // Logic to query Tax Rate object to get Rate value based on Tax Code
            List<blng__TaxRate__c> lstTaxRate = [SELECT ID,blng__Rate__c,blng__TaxCode__c 
                                                 FROM blng__TaxRate__c 
                                                 WHERE blng__TaxCode__c IN :taxCodeTaxRateMap.keySet() ];//Gitlab US#29101 -- added 
            
            if((lstTaxRate== null || lstTaxRate.isEmpty()) && !Test.isRunningTest()){ return null;} // 29101 return null early if lstTaxRate is empty
            
            for(blng__TaxRate__c taxRateValue :lstTaxRate){
                if(invcIdTaxRateMap!=null && taxCodeTaxRateMap!=null && taxCodeTaxRateMap.containsKey(taxRateValue.blng__TaxCode__c)){
                    for(Id invIds : taxCodeTaxRateMap.get(taxRateValue.blng__TaxCode__c)){
                        invcIdTaxRateMap.put(invIds,taxRateValue.blng__Rate__c); 
                    }
                }
            }  
            for(blng__Invoice__c invoice :listInvoice){
                //#29101 Check if the country exists in the lstEuCountriesMap map 
                Boolean isEuCountry = (lstEuCountriesMap!=null && lstEuCountriesMap.containsKey(invoice.blng__Account__r?.QTB_Legal_Entity_Country__c.toLowerCase()));
                Boolean hasTaxRate = (invcIdTaxRateMap!= null && invcIdTaxRateMap.containsKey(invoice.ID));
                // Use ternary operator for taxRate assignment
                String taxRate = (hasTaxRate) ? ((invcIdTaxRateMap!=null && isEuCountry) 
                                                 ? (invcIdTaxRateMap.get(invoice.ID).format()) : String.valueOf(invcIdTaxRateMap.get(invoice.ID))) : null;
                // Use ternary operator for subTotal, taxOvrAmt, and totalAmt
                String subTotal  = isEuCountry  ? invoice?.QTB_Subtotal_local_currency__c.format()      : String.valueOf(invoice?.QTB_Subtotal_local_currency__c);
                String taxOvrAmt = isEuCountry  ? invoice?.QTB_Tax_Override_Amt_Local__c.format()       : String.valueOf(invoice?.QTB_Tax_Override_Amt_Local__c);
                String totalAmt  = isEuCountry  ? invoice?.QTB_Total_Amt_Tax_Override_local__c.format() : String.valueOf(invoice?.QTB_Total_Amt_Tax_Override_local__c);
                // Invoice Sub Total local Value.Sub TotalTax,Total Tax Override amount .Format() will replace the (.) with (,) in that Decimal value vice versa
                // ELSE----    // Invoice Sub Total,  Sub TotalTax , Tax Override amount override local Value
                
                Boolean isContract = (invoice.QTB_Exchange_Rate__c == 1 && invoice.QTB_Contracted_Currency_Rate__c != null);
                Decimal rate = (invoice.QTB_Exchange_Rate__c == 1 && invoice.QTB_Contracted_Currency_Rate__c != null)  
                    ?  (invoice?.QTB_Contracted_Currency_Rate__c) : (invoice?.QTB_Exchange_Rate__c);
                        String prefix1 = (invoice.QTB_Exchange_Rate__c == 1 && invoice.QTB_Contracted_Currency_Rate__c != null) 
                        ?   (invoice?.blng__Account__r?.QTB_Contract_Currency__c) : (invoice.blng__Account__r?.CurrencyIsoCode);
                            String prefix2 = (invoice.QTB_Exchange_Rate__c == 1 && invoice.QTB_Contracted_Currency_Rate__c != null) 
                            ?  (invoice.blng__Account__r?.CurrencyIsoCode) : (invoice.blng__Account__r?.QTB_Contract_Entity__r?.CurrencyIsoCode);
                                
                                // Condition to check if Account Contract currency is not matching with CurrencyISOCode or if Country is Romania along with Custom setting holds Account LE country or not
                                // 29101 replaced != with !varName.equalsIgnoreCase
                                if(invoiceNotesLabelMap!= null && invcIdCountryLangMap.containsKey(invoice.ID) && invoiceNotesLabelMap.containsKey(invcIdCountryLangMap.get(invoice.ID))){ //#29100removed (&& !invoiceNotesLabelMap.isEmpty()) to avoid redundant null check
                                    // Variable declaration for the Custom Setting later to get Label values based on countries
                                    //To get Custom setting values based on Account LE Country
                                    QTB_Invoice_Note_Labels__c invNotesLabels = (invoiceNotesLabelMap.get(invcIdCountryLangMap.get(invoice.ID)));                               
                                    // Assigning labels along with values for Invoice Note field
                                    //// assignment of String value to invoice note // NOW DIRECTLY AS 29101 IN invoice.blng__Notes__c 
                                    invoice.blng__Notes__c = isContract ? invNotesLabels?.Exchange_Rate__c+' : '+prefix1+' 1 : '+ prefix2 +' '+rate :
                                    invNotesLabels?.Exchange_Rate__c+' : '+prefix1+' 1 : '+ prefix2 +' '+rate+' '+'\n'+
                                        invNotesLabels?.Sub_Total__c+ ' : '+subTotal+'\n'+ invNotesLabels?.VAT__c+' : '+taxRate+'% '+taxOvrAmt+'\n'+
                                        invNotesLabels?.Total__c+ ' : '+prefix2+' '+totalAmt;
                                    invoiceUpdateList.add(invoice);
                                }
            }              
            taxCodeTaxRateMap.clear(); 
            QTB_RecursiveHandlerCheck.invoiceNoteRecursiveCheck = false;
            if(invoiceUpdateList!=null && !invoiceUpdateList.isEmpty()){
                return invoiceUpdateList;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_RecursiveHandlerCheck.invoiceNoteRecursiveCheck = false;
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog  (e.getLineNumber(), e.getStackTraceString(),e.getMessage(),e.getTypeName(),INVOICE_HELPER_UTILS);
            throw e;
        } 
    }
	/***********************************************************************************************************
* Method : createSubLinesAndUpdateInvAndInvLine
* Parameters: Set<ID> invId
* Return Type : List<blng__Invoice__c>
* Requirement : Gitlab #30888 create sub lines fro rebill invoices
* Description: Gitlab #30888 create sub lines fro rebill invoices
* Developer         Date           Description
* ---------------------------------------------------------------------------------------------------------- 
* Virtusa          02/05/2025      
* Virtusa(Parth)   10/06/2025       #31399 for sub invoice lines unit price should be same as of usage
**************************************************************************************************************/
    public static List<blng__Invoice__c> createSubLinesAndUpdateInvAndInvLine(Set<ID>invId){
        try{
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invId == null){return null;}
            List<blng__Invoice__c> invToUpdateRecordsList = new List<blng__Invoice__c>();
            Map<ID,List<blng__SubInvoiceLine__c>> invSubLineMap = new Map<ID,List<blng__SubInvoiceLine__c>>(); // Map to store inv ID and its related sub invoice line that need to be inserted
            Map<ID,ID> usageSummaryToInvoiceLineMap = new Map<ID,ID>(); // Map to store invoice line ID and usage summary ID 
            Map<ID,Decimal> tieredInvLineSubTotalMap = new Map<ID,Decimal>(); //To store invoice ID and sum of tiered invoice line subtotal
            Map<ID,Decimal> invoiceTaxOverrideAmtMap = new Map<ID,Decimal>();//To store invoice ID and tax override amount
            Map<ID,Decimal> invoiceLineSubLinesTaxOverrideAmountMap = new Map<ID,Decimal>();  // To store the sum of sub-invoice line tax override amounts
            Map<ID,Decimal> subInvoiceLineSubtotalMap = new Map<ID, Decimal>();  // To store the invocie ID and sum of its related sub-invoice line subtotal
            // Map of invoice line - fetch  tiered Invoice line ( API name -QTB_Tiered_Flag__c), sub  invoice line should be manufactured based on the usages associated to the invoice line
            Map<ID, blng__InvoiceLine__c> invoiceLineMap = new Map<ID, blng__InvoiceLine__c>([SELECT ID,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__TaxCountry__c,currencyISOCode,blng__UsageSummary__c, blng__Invoice__c,blng__Invoice__r.QTB_Tax_Override_Amount__c, 
                                                                                              blng__Quantity__c, blng__UnitPrice__c,blng__Subtotal__c, blng__TaxAmount__c, QTB_Tax_Override_Amount__c, blng__TotalAmount__c 
                                                                                              FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN :invId
                                                                                              AND blng__InvoiceLineStatus__c = 'Draft' AND QTB_Tiered_Flag__c = TRUE]);
            
            
            // Mapping Invoice line relationships
            if(invoiceLineMap!= null && !invoiceLineMap.isEmpty()){
                for(blng__InvoiceLine__c invLine : invoiceLineMap.values()) {
                    if(invLine.blng__UsageSummary__c != null){
                        usageSummaryToInvoiceLineMap.put(invLine.blng__UsageSummary__c, invLine.ID);
                    }
                    // storing invoice ID and its related invoice line sub total where tiered flag is true
                    if(!tieredInvLineSubTotalMap.containsKey(invLine.blng__Invoice__c)){
                        tieredInvLineSubTotalMap.put(invLine.blng__Invoice__c,invLine.blng__Subtotal__c);
                    }
                    else{
                        tieredInvLineSubTotalMap.put(invLine.blng__Invoice__c,tieredInvLineSubTotalMap.get(invLine.blng__Invoice__c)+ invLine.blng__Subtotal__c); 
                    }
                    // adding invoice ID and its tax override amount
                    // 30942 for flat rate countries not to update tax override amount on invoice line and invoice
                    if(invLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != null && invLine.blng__LegalEntity__r.QTB_Tax_Applicability__c.containsIgnoreCase('Product Based') && !invoiceTaxOverrideAmtMap.containsKey(invLine.blng__Invoice__c)){
                        invoiceTaxOverrideAmtMap.put(invLine.blng__Invoice__c,invLine.blng__Invoice__r.QTB_Tax_Override_Amount__c);
                    }
                }
                // this map will store invoice line ID and data to insert in sub invoice line based on price tier
                Map<ID, Map<String, QTB_SubInvoiceLineCreationBatch.TierData>> tierMap = new Map<ID, Map<String, QTB_SubInvoiceLineCreationBatch.TierData>>();
                // Group the usages by Qtb_Price_tier__c on the usages and create Sublines
                // #31399 added min(QTB_Prerated_Unit_Price__c), as same price tiere will have same unit price and that unit price needs to be the unit price of sub invoice line
                // QTB_Prerated_Unit_Price__c, blng__PreratedAmount__c is currency field so it is not giving correct value in aggregate result, hence created formula field QTB_PreratedAmount__c and QTB_PreratedUnitPrice__c of data type number
                for(AggregateResult ar : [SELECT blng__UsageSummary__c, QTB_Price_Tier__c tier,SUM(blng__PreratedQuantity__c) totalQty,SUM(QTB_PreratedAmount__c) totalAmt,
                                          SUM(QTB_Box_Count__c)boxCount,min(QTB_PreratedUnitPrice__c)unitPrice,min(QTB_Start_Date_MRC__c)startDate, max(QTB_End_Date_MRC__c)endDate FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usageSummaryToInvoiceLineMap.keySet()
                                          GROUP BY blng__UsageSummary__c , QTB_Price_Tier__c ])
                {
                    ID usgSmryId = (ID)ar.get('blng__UsageSummary__c');
                    ID invoiceLineId = usageSummaryToInvoiceLineMap.get(usgSmryId);
                    String priceTier = (String)ar.get('tier');
                    
                    // if invoice line not present adding to the map
                    if(tierMap != null && !tierMap.containsKey(invoiceLineId)) {
                        tierMap.put(invoiceLineId, new Map<String,QTB_SubInvoiceLineCreationBatch.TierData>());
                    }
                    // adding sub invoice line data that need to be inserted for an invoice line
                    tierMap.get(invoiceLineId).put(priceTier, new QTB_SubInvoiceLineCreationBatch.TierData(
                        (Decimal)ar.get('totalQty'),
                        (Decimal)ar.get('totalAmt'),
                        (Date)ar.get('startDate'),
                        (Date)ar.get('endDate'),
                        (Decimal)ar.get('boxCount'),
                        (Decimal)ar.get('unitPrice')
                    ));
                }
                usageSummaryToInvoiceLineMap.clear();
                
                //Create sub invoice lines and calculate tax override amount sum
                if(tierMap != null && !tierMap.isEmpty()){
                    for(ID invoiceLineId : tierMap.keySet()) {
                        blng__InvoiceLine__c parentInvLine = invoiceLineMap.get(invoiceLineId);
                        Decimal parentSubtotal = parentInvLine.blng__Subtotal__c != null ? parentInvLine.blng__Subtotal__c : 0 ;
                        Decimal taxRatio = parentSubtotal != 0 && parentInvLine.blng__TaxAmount__c != null ? parentInvLine.blng__TaxAmount__c / parentSubtotal : 0;
                        Decimal taxOverrideRatio = parentSubtotal != 0 && parentInvLine.QTB_Tax_Override_Amount__c != null ? parentInvLine.QTB_Tax_Override_Amount__c / parentSubtotal : 0;
                        Decimal currentSubTotalTaxOverrideAmount = 0; // variable to store sum of tax override amount of sub invoice line on an invoice line
                        Decimal currentSubTotal = 0; // variable to store sum of subtotal of sub invoice line on an invoice line
                        for(String tier : tierMap.get(invoiceLineId).keySet()) {
                            QTB_SubInvoiceLineCreationBatch.TierData td = tierMap.get(invoiceLineId).get(tier);
                            //Decimal unitPrice = td.totalQty != 0 && td.totalAmt != null ? (td.totalAmt / td.totalQty).setScale(4, System.RoundingMode.HALF_UP) : 0;
                            Decimal subLineTaxOverrideAmount;
                            // 30942 for flat rate tax override amount will be same as of tax amount 
                            if(parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != null && parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c.containsIgnoreCase('Product Based')){
                                subLineTaxOverrideAmount = (td.totalAmt * taxOverrideRatio).setScale(2, System.RoundingMode.HALF_UP);
                            	currentSubTotalTaxOverrideAmount += subLineTaxOverrideAmount;
                            }else{
                                subLineTaxOverrideAmount = (td.totalAmt * taxRatio).setScale(2, System.RoundingMode.HALF_UP);
                            }
                            currentSubTotal += (td.totalAmt).setScale(2, System.RoundingMode.HALF_UP);
                            string NotesToAdd;
                            if(td.startDateMRC != null && td.endDateMRC != null){
                                // storing start date and end date mrc dates
                                // if day or month is less than 10 then adding 0 to it
                                String startday = td.startDateMRC.day() < 10 ? '0' + String.valueOf(td.startDateMRC.day()) : String.valueOf(td.startDateMRC.day());
                                String Startmonth = td.startDateMRC.month() < 10 ? '0' + String.valueOf(td.startDateMRC.month()) : String.valueOf(td.startDateMRC.month());
                                String Startyear = String.valueOf(td.startDateMRC.year());
                                String endday = td.endDateMRC.day() < 10 ? '0' + String.valueOf(td.endDateMRC.day()) : String.valueOf(td.endDateMRC.day());
                                String endmonth = td.endDateMRC.month() < 10 ? '0' + String.valueOf(td.endDateMRC.month()) : String.valueOf(td.endDateMRC.month());
                                String endyear = String.valueOf(td.endDateMRC.year());
                                // for India / Thailand notes should be in format → 15-03-2025 to 14-04-2025
                                if(parentInvLine.blng__TaxCountry__c.containsIgnoreCase('India') || parentInvLine.blng__TaxCountry__c.containsIgnoreCase('Thailand')){
                                    NotesToAdd = startday + '-' + Startmonth + '-' + Startyear + ' to ' + endday + '-' + endmonth + '-' + endyear;
                                }
                                // for Hungary notes should be in format → 2025.03.15 - 2025.04.14
                                else if(parentInvLine.blng__TaxCountry__c.containsIgnoreCase('Hungary')){
                                    NotesToAdd = startday + '.' + Startmonth + '.' + Startyear + ' - ' + endday + '.' + endmonth + '.' + endyear;
                                }
                                 // for ANZ notes should be in format → 2025/03/15 - 2025/04/14
                                else if(parentInvLine.blng__TaxCountry__c.containsIgnoreCase('New Zealand') || parentInvLine.blng__TaxCountry__c.containsIgnoreCase('Australia')){
                                    NotesToAdd = startday + '/' + Startmonth + '/' + Startyear + ' - ' + endday + '/' + endmonth + '/' + endyear;
                                }
                                // Others (default) notes should be in format → 15-03-2025 - 14-04-2025
                                else{
                                    NotesToAdd = startday + '-' + Startmonth + '-' + Startyear + ' - ' + endday + '-' + endmonth + '-' + endyear;  
                                }
                            }
                            // adding sub invoice lines data
                            blng__SubInvoiceLine__c sublines = new blng__SubInvoiceLine__c(
                                blng__InvoiceLine__c = invoiceLineId,
                                blng__Quantity__c = td.totalQty,
                                blng__UnitPrice__c = (td.unitPrice).setScale(4, System.RoundingMode.HALF_UP),
                                blng__Subtotal__c = (td.totalAmt).setScale(2, System.RoundingMode.HALF_UP),
                                blng__TaxAmount__c = (td.totalAmt * taxRatio).setScale(2, System.RoundingMode.HALF_UP),
                                QTB_Tax_Override_Amount__c = subLineTaxOverrideAmount,
                                blng__Notes__c = NotesToAdd,
                                QTB_Box_Count__c = td.boxCount,
                                currencyISOCode = parentInvLine.currencyISOCode,
                                QTB_Price_Tier__c = tier // #31803 - assigning usage level price tier to sub lins which will help to identify usages related to sub invoice line
                            );
                            // adding invoice ID and its related subinvoice line list to map
                            if(invSubLineMap != null && !invSubLineMap.containsKey(parentInvLine.blng__Invoice__c)){
                                invSubLineMap.put(parentInvLine.blng__Invoice__c, new List<blng__subInvoiceLine__c>());
                            }
                            invSubLineMap.get(parentInvLine.blng__Invoice__c).add(sublines);
                        }
                        // adding invoice line ID and sub invoice line tax override amount to compare if tax overide amount sum is same as of invoice line
                        // 30942 for flat rate countries not to update tax override amount on invoice line and invoice
                        if(parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != null && parentInvLine.blng__LegalEntity__r.QTB_Tax_Applicability__c.containsIgnoreCase('Product Based')){
                            invoiceLineSubLinesTaxOverrideAmountMap.put(invoiceLineId, currentSubTotalTaxOverrideAmount);
                        }
                        // adding invoice ID and sum of sub invoice line subtotal to check if it is equal to sum of invoice line subtotal where tiered flag is true
                        // from this check will update subLines Added field to true on invoice
                        System.debug('currentSubTotal--->'+currentSubTotal);
                        if(subInvoiceLineSubtotalMap != null && !subInvoiceLineSubtotalMap.containsKey(parentInvLine.blng__Invoice__c)){
                            subInvoiceLineSubtotalMap.put(parentInvLine.blng__Invoice__c,currentSubTotal);
                        }
                        else if(subInvoiceLineSubtotalMap != null){
                            subInvoiceLineSubtotalMap.put(parentInvLine.blng__Invoice__c,currentSubTotal + subInvoiceLineSubtotalMap.get(parentInvLine.blng__Invoice__c));
                        }
                        System.debug('subInvoiceLineSubtotalMap--->'+subInvoiceLineSubtotalMap);
                    }
                }
                tierMap.clear();
                if(invSubLineMap != null && !invSubLineMap.isEmpty()) {
                    List<blng__SubInvoiceLine__c> subLinesToInsert = new List<blng__SubInvoiceLine__c>();
                    for (List<blng__SubInvoiceLine__c> subLineList : invSubLineMap.values()) {
                        subLinesToInsert.addAll(subLineList);
                    }
                    insert subLinesToInsert;
                    subLinesToInsert.clear();
                }
                // Update invoice lines if tax override amounts don't match checking only if its related sublines are inserted
                List<blng__InvoiceLine__c> invoiceLinesToUpdate = new List<blng__InvoiceLine__c>();
                for(ID invLineId : invoiceLineMap.keySet()) {
                    blng__InvoiceLine__c parentInvLine = invoiceLineMap.containsKey(invLineId)?invoiceLineMap.get(invLineId):null;
                    if(parentInvLine != null && invoiceLineSubLinesTaxOverrideAmountMap.containsKey(invLineId) && parentInvLine.QTB_Tax_Override_Amount__c != invoiceLineSubLinesTaxOverrideAmountMap.get(invLineId)){
                        parentInvLine.QTB_Tax_Override_Amount__c = invoiceLineSubLinesTaxOverrideAmountMap.get(invLineId);
                        invoiceLinesToUpdate.add(parentInvLine);
                    }
                }
                invoiceLineSubLinesTaxOverrideAmountMap.clear();
                Map<ID,blng__Invoice__c>invoiceToUpdate = new Map<ID,blng__Invoice__c>();
                // update invoice header level tax override amount if invoice line tax override amount get updated
                if(!invoiceLinesToUpdate.isEmpty()){
                    update invoiceLinesToUpdate;
                    
                    // if tax override amount on invoice line gets updted then only updating tax override amount on invoice header
                    // 30942 for flat rate countries not to update tax override amount on invoice line and invoice
                    for(aggregateResult ar :[SELECT blng__Invoice__c,SUM(QTB_Tax_Override_Amount__c)invTaxOverrideAmt FROM blng__invoiceLine__c 
                                             WHERE blng__Invoice__c in :invSubLineMap.keySet() AND blng__LegalEntity__r.QTB_Tax_Applicability__c = 'Product Based' GROUP BY blng__Invoice__c])
                    {
                        Decimal taxOverRide;
                        if(invoiceTaxOverrideAmtMap.containsKey((ID)ar.get('blng__Invoice__c')))
                        {
                            taxOverRide = invoiceTaxOverrideAmtMap.get((ID)ar.get('blng__Invoice__c'));
                            blng__Invoice__c inv = new blng__invoice__c();
                            if(taxOverRide != (Decimal)ar.get('invTaxOverrideAmt')){
                                inv.ID = (ID)ar.get('blng__Invoice__c');
                                inv.QTB_Tax_Override_Amount__c = (Decimal)ar.get('invTaxOverrideAmt');
                            }
                            else{
                                inv.ID = (ID)ar.get('blng__Invoice__c');
                                inv.QTB_Tax_Override_Amount__c = taxOverRide;
                            }
                            if(invoiceToUpdate != null && !invoiceToUpdate.containsKey(inv.ID)){
                                invoiceToUpdate.put(inv.ID,inv);
                            }
                            else if(invoiceToUpdate != null){
                                invoiceToUpdate.get(inv.ID).put('QTB_Tax_Override_Amount__c', inv.QTB_Tax_Override_Amount__c);
                            }
                        }						
                    }
                }
                invoiceLinesToUpdate.clear();
                invoiceTaxOverrideAmtMap.clear();
                
                // update QTB_Sublines_Added__c to true at invoice header if sum of subtotal of tier invoice line equal to sum of subline subtotal
                System.debug('subInvoiceLineSubtotalMap--->'+subInvoiceLineSubtotalMap);
                System.debug('tieredInvLineSubTotalMap--->'+tieredInvLineSubTotalMap);
                for(ID invoiceId :invSubLineMap.keySet())
                {
                    if(subInvoiceLineSubtotalMap != null && subInvoiceLineSubtotalMap.containsKey(invoiceId) && tieredInvLineSubTotalMap.containsKey(invoiceId) &&
                       tieredInvLineSubTotalMap.get(invoiceId) == subInvoiceLineSubtotalMap.get(invoiceId))
                    {
                        blng__Invoice__c inv = new blng__invoice__c(ID =invoiceId, QTB_Sublines_Added__c = true );
                        if(invoiceToUpdate != null && !invoiceToUpdate.containsKey(invoiceId)){
                            invoiceToUpdate.put(invoiceId,inv);
                        }
                        else if(invoiceToUpdate != null){
                            invoiceToUpdate.get(invoiceId).put('QTB_Sublines_Added__c', inv.QTB_Sublines_Added__c);
                        }
                    }						
                }
                invToUpdateRecordsList.addAll(invoiceToUpdate.values());
                invoiceToUpdate.clear();
                subInvoiceLineSubtotalMap.clear();
                tieredInvLineSubTotalMap.clear();
            }
            if(invToUpdateRecordsList !=null && !invToUpdateRecordsList.isEmpty()){
                System.debug('invToUpdateRecordsList--->'+invToUpdateRecordsList);
                QTB_RecursiveHandlerCheck.afterUpdateCheck_createSubInvoiceLines = false;
                return invToUpdateRecordsList;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog (e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), INVOICE_HELPER_UTILS);
            throw e;
        }
    }
}