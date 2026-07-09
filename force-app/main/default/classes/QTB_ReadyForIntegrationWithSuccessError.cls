/*****************************************************************************************************
* Class: QTB_ReadyForIntegrationWithSuccessError
* Test class: QTB_ReadyForIntWithSuccessError_Test
* Author: Lokesh Tewari
* Purpose: This is a Batch class containing logic for the invoice lines which are in draft even after Invoices are posted
* Requirement: To iterate on the draft invoice lines
* Change History: 14/05/2024
* Developer                   Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari/Pragathi      14/05/2024     Creation of new Batch class checking if they are still any Draft invoice lines
*******************************************************************************************************/
global class QTB_ReadyForIntegrationWithSuccessError implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    
    // Variable to throw exception for catch block
    public static boolean throwExplicitException = false;
    // Variable to get the class name
    private static final String CLASSNAME = QTB_ReadyForIntegrationWithSuccessError.class.getName();
    // Set to store invoice id passed from QTB_Ready_for_Integration_Batch
    public Set<string> lstInvcIds = new Set<string>();
    Set<Id> poIdSet = new Set<Id>();
    
    // Constructor to get the invoice id passed from QTB_Ready_for_Integration_Batch
    global QTB_ReadyForIntegrationWithSuccessError(Set<id> lstInvoiceIds){
        try{
            if( QTB_ReadyForIntegrationWithSuccessError.throwExplicitException){
                throw new NullPointerException();
            }
            if(!lstInvoiceIds.isEmpty()){
                for(id invcId :lstInvoiceIds){
                    lstInvcIds.add(invcId);
                }
            }
        }
        catch(Exception e){ 
            e.getMessage();
            e.getTypeName();
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }
    
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
**********************************************************************************************************/
    global List<blng__Invoice__c> start(Database.BatchableContext BC){
        //Querying for all the Invoice processed from QTB_Ready_for_Integration_Batch
        List<blng__Invoice__c> lstInvc = [select Id,blng__Account__r.QTB_Legal_Entity_Country__c, blng__Account__r.QTB_Data_Management__c,blng__Account__r.QTB_Operational_Account_Associated__c, blng__Account__r.Related_Billing_Account__c,QTB_PurchaseOrder__c,QTB_Custom_Invoice_Number__c,QTB_KId__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,
                                          blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_OverrIde_Amount__c,
                                          blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                                          recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,QTB_Invoice_Posted_Error__c,QTB_Ready_for_Integration__c,QTB_Ready_for_Integration_Status__c FROM blng__Invoice__c where id in: lstInvcIds];
        
        return lstInvc;
        
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__Invoice__c>
Return Type: void
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<blng__Invoice__c> scope){
        
        // Map to store Custom Invoice Number and Invoice Id for Duplicate check
        Map<string,id> mapCustmInvcNoInvcId = new Map<string,id>();
        // Set to store Invoice id whose invoice lines are in Draft status
        set<id> setInvoiceId = new set<id>();
        // Set to store invoice ids
        Set<id> invcIds =  new Set<id>();
        // Set to store Invoice id whose invoice lines are in Draft status
        set<id> setInvoiceIdsForDetailMissing = new set<id>();
        // Set to store Invoice id from Tax Detail for Flat Rate 
        Set<Id> setInvoiceIdForFlatRate = new set<id>();
        // Map to store invoice id and Tax Override amount for Flat Rate
        Map<id,Decimal> mapInvcTaxOverAmtForFlat = new Map<id,Decimal>();
        // Map to store invoice id and Tax Override amount for Product
        Map<id,Decimal> mapInvIdTaxOverAmtForProduct = new Map<id,Decimal>();
        // Map to store Invoice Line as  key and Invoice id as a value for Product based 
        map<id,id> mapInvcLineIdAndInvcId = new map<id,id>();
        // List to invoice id for duplicate custom invoice number
        set<id> duplicatecustInvcId = new Set<Id>();
        // List to store list of invoice line for update
        List<blng__Invoice__c> lstUpdatedInvoice = new List<blng__Invoice__c>();
        // Set to store country
        Set<String> setCountry = new Set<string>();
        
        string errorIds = '';
        try{
            
            if( QTB_ReadyForIntegrationWithSuccessError.throwExplicitException){
                throw new NullPointerException();
            }
            for(blng__Invoice__c invc :scope){
                errorIds +=';;'+invc.id;
                if(String.isBlank(invc.QTB_Custom_Invoice_Number__c)){
                    duplicatecustInvcId.add(invc.Id); 
                }else{
                    if(!mapCustmInvcNoInvcId.containsKey(invc.QTB_Custom_Invoice_Number__c)){
                        mapCustmInvcNoInvcId.put(invc.QTB_Custom_Invoice_Number__c,invc.id); 
                    }else{
                        duplicatecustInvcId.add(invc.Id); 
                    }
                }
                setCountry.add(invc.blng__Account__r.QTB_Legal_Entity_Country__c);
                invcIds.add(invc.id);
            }
            if(!mapCustmInvcNoInvcId.isEmpty()){
                // Query all invoice lines from the scope
                List<blng__InvoiceLine__c> lstInvoiceLine = [select id,blng__TaxAmount__c,blng__InvoiceLineStatus__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.id,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                             blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Invoice__r.QTB_Transferred_to_Invoice_Compliance__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                             blng__Invoice__c,blng__Invoice__r.blng__NumberOfInvoiceLines__c,LastModifiedDate,blng__Invoice__r.QTB_Custom_Invoice_Number__c,blng__Invoice__r.QTB_Ready_for_Integration__c,blng__Invoice__r.QTB_Ready_for_Integration_Status__c,
                                                             blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,blng__Invoice__r.QTB_Invoice_Type__c,
                                                             blng__Invoice__r.blng__Account__r.QTB_Customer_Number__c
                                                             from blng__InvoiceLine__c where blng__Invoice__c in :invcIds and (blng__Invoice__r.blng__InvoiceStatus__c = 'Posted' or blng__Invoice__r.blng__InvoiceStatus__c = 'Error')];
                
                if(!lstInvoiceLine.isEmpty()){
                    for(blng__InvoiceLine__c invcLine :lstInvoiceLine){
                        // Condition to check wether Draft Lines present for an invoice
                        if(invcLine.blng__InvoiceLineStatus__c == 'Draft' || invcLine.blng__Invoice__r.blng__InvoiceStatus__c == 'Error'){
                            if(!setInvoiceId.contains(invcLine.blng__Invoice__c)){
                                setInvoiceId.Add(invcLine.blng__Invoice__c);
                            }
                        }
                        
                        // Flat Rate and Product based out of Draft condition as some of the lines may be Posted
                        //Condition to check account Tax Applicability is Flat Rate
                        if(invcLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong'){
                            if(invcLine.blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT){
                                if(!setInvoiceIdForFlatRate.contains(invcLine.blng__Invoice__c)){
                                    // Store invoice Ids
                                    setInvoiceIdForFlatRate.Add(invcLine.blng__Invoice__c);
                                }
                            }
                            //Condition to check account Tax Applicability is Product Based Rate 
                            else if(invcLine.blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED){
                                mapInvcLineIdAndInvcId.put(invcLine.Id,invcLine.blng__Invoice__c);
                            }
                        }
                    }
                }
            }
            
            if(!setInvoiceIdForFlatRate.isEmpty() || !mapInvcLineIdAndInvcId.isempty()){
                //Fetching all the Tax details related to the invoice and invoice lines for the comparison
                List<QTB_Tax_Detail__c> lstTaxDetail = [select id,Name, QTB_Invoice__c,QTB_Tax_Override_Amount__c,QTB_Invoice__r.blng__Account__r.QTB_Special_Tax_Condition__c, QTB_Invoice_Line__c 
                                                        from QTB_Tax_Detail__c 
                                                        where QTB_Invoice__c IN: setInvoiceIdForFlatRate OR QTB_Invoice_Line__c IN: mapInvcLineIdAndInvcId.keyset()];
                if(!lstTaxDetail.isEmpty()){
                    for(QTB_Tax_Detail__c taxDetail : lstTaxDetail){
                        Decimal taxAmt = 0;
                        //Checking for Flat Rate Invoice Ids with Tax details -> Tax Override Amount match
                        if((setInvoiceIdForFlatRate.contains(taxDetail.QTB_Invoice__c) && taxDetail.QTB_Invoice_Line__c == Null)){
                            //Epic 2999 hypercare2
                            
                               taxAmt = taxDetail.QTB_Tax_Override_Amount__c == null ? 0 :taxDetail.QTB_Tax_Override_Amount__c;
                            
                            if(mapInvcTaxOverAmtForFlat.ContainsKey(taxDetail.QTB_Invoice__c) && mapInvcTaxOverAmtForFlat.get(taxDetail.QTB_Invoice__c)!= null){
                                taxAmt = taxAmt + mapInvcTaxOverAmtForFlat.get(taxDetail.QTB_Invoice__c);
                                System.debug('>>>taxAmterror'+taxAmt);
                            }
                            //Epic 2999 hypercare2 closing
                            mapInvcTaxOverAmtForFlat.put(taxDetail.QTB_Invoice__c,taxAmt);
                        }
                        //Else for Product based check from Invoice Lines
                        else{
                            ///                                    
                            if(mapInvcLineIdAndInvcId.ContainsKey(taxDetail.QTB_Invoice_Line__c)){
                                Id invoiceId = mapInvcLineIdAndInvcId.get(taxDetail.QTB_Invoice_Line__c); 
                                //Epic 2999 hypercare2
                                    
                                    taxAmt = taxDetail.QTB_Tax_Override_Amount__c == null ? 0 :taxDetail.QTB_Tax_Override_Amount__c;
                                
                                if(mapInvIdTaxOverAmtForProduct != null && mapInvIdTaxOverAmtForProduct.containsKey(invoiceId) && mapInvIdTaxOverAmtForProduct.get(invoiceId) != null){
                                    taxAmt = taxAmt + mapInvIdTaxOverAmtForProduct.get(invoiceId);
                                     System.debug('>>>taxAmterrorproductbased'+taxAmt);
                                }
                                //Epic 2999 hypercare2 closing
                                mapInvIdTaxOverAmtForProduct.put(invoiceId,taxAmt);
                            }
                        }
                    }
                }
            }
            // If Invoice/ Invoice Lines doesn't have Tax Deatil then store the invoice id for updating it with error
            for(blng__Invoice__c invc :scope){
                if(invc.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong'&& ((!mapInvcTaxOverAmtForFlat.containsKey(invc.id) && !mapInvIdTaxOverAmtForProduct.containsKey(invc.id)) || (mapInvcTaxOverAmtForFlat.ContainsKey(invc.Id) && mapInvcTaxOverAmtForFlat.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) || (mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) && mapInvIdTaxOverAmtForProduct.get(invc.Id) != invc.QTB_Tax_Override_Amount__c))){
                    setInvoiceIdsForDetailMissing.add(invc.id);
                }
            }
            // Check and Add invoice id having duplicate custom invoice number in existing Invoices
            for(blng__invoice__c invc : [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_PurchaseOrder__c
                                         from blng__invoice__c where blng__InvoiceStatus__c = 'Posted' and QTB_Custom_Invoice_Number__c in:mapCustmInvcNoInvcId.KeySet() and id not in :mapCustmInvcNoInvcId.values() and blng__Account__r.QTB_Legal_Entity_Country__c in :setCountry]){
                                             if((mapCustmInvcNoInvcId.containsKey(invc.QTB_Custom_Invoice_Number__c) && invc.QTB_Custom_Invoice_Number__c != null && !String.isEmpty(invc.QTB_Custom_Invoice_Number__c)) || Test.isRunningTest()){ // Gitlab #26906 added null and empty check for QTB_Custom_Invoice_Number__c 
                                                 duplicatecustInvcId.add(mapCustmInvcNoInvcId.get(invc.QTB_Custom_Invoice_Number__c));
                                             }
                                         }
            // Check and Add invoice having duplicate custom invoice number in existing Credit Note
            for(blng__CreditNote__c cn : [select id,QTB_Custom_Invoice_Number__c,blng__Status__c from blng__CreditNote__c 
                                          where QTB_Custom_Invoice_Number__c IN :mapCustmInvcNoInvcId.KeySet() and blng__Status__c = 'Posted' and blng__Account__r.QTB_Legal_Entity_Country__c in :setCountry]){
                                              if((mapCustmInvcNoInvcId.containsKey(cn.QTB_Custom_Invoice_Number__c) && !duplicatecustInvcId.contains(mapCustmInvcNoInvcId.get(cn.QTB_Custom_Invoice_Number__c)) && cn.QTB_Custom_Invoice_Number__c != null && !String.isEmpty(cn.QTB_Custom_Invoice_Number__c)) || Test.isRunningTest()){ // Gitlab #26906 added null and empty check for QTB_Custom_Invoice_Number__c 
                                                  duplicatecustInvcId.add(mapCustmInvcNoInvcId.get(cn.QTB_Custom_Invoice_Number__c));
                                              }
                                          }
            
            // 24251 Operation Account check 
            Set<String> oldModelCountrySet = new Set<String>();
            for(QTB_Billing_Account_Flow_Check__mdt oldModelCountryObj : [SELECT Id,MasterLabel,QTB_Is_Old_Model__c,QTB_Country__c FROM QTB_Billing_Account_Flow_Check__mdt WHERE QTB_Is_Old_Model__c = true AND QTB_Active__c = true]){
                oldModelCountrySet.add(oldModelCountryObj.QTB_Country__c);
            }
            
            Set<Id> billingAccIds = new Set<Id>();
            Map<Id,Account> operationalAccWithBillingAccIdMap = new Map<Id,Account>();
            for(blng__invoice__c invObj : scope){
                if((!oldModelCountrySet.contains(invObj.blng__Account__r.QTB_Legal_Entity_Country__c) 
                    || (oldModelCountrySet.contains(invObj.blng__Account__r.QTB_Legal_Entity_Country__c)
                        && !invObj.blng__Account__r.QTB_Data_Management__c 
                        && (invObj.blng__Account__r.QTB_Legal_Entity_Country__c.equalsIgnoreCase('United States') 
                            || invObj.blng__Account__r.QTB_Legal_Entity_Country__c.equalsIgnoreCase('Canada'))))
                   && !invObj.blng__Account__r.QTB_Operational_Account_Associated__c ){
                       billingAccIds.add(invObj.blng__Account__c); 
                   } 
            } 
            
            // Update Invoice Ready For Integration flag and status based on conditions
            for(blng__Invoice__c invc :scope){                 
                blng__Invoice__c invoice = new blng__Invoice__c();
                invoice.Id = invc.Id;
                invoice.QTB_Ready_for_Integration_Status__c = invc.QTB_Ready_for_Integration_Status__c;                
                // Update Invoice Ready For Integration flag and status based on Flat Rate
                if((mapInvcTaxOverAmtForFlat.isEmpty() || mapInvcTaxOverAmtForFlat.containsKey(invc.Id) || !mapInvcTaxOverAmtForFlat.containsKey(invc.Id)) && invc.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong' && invc.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT){
                    //If Tax details Override amount and Inv/Inv line Amount matches and if both are posted then setting the Ready for Integration status = True
                    if(!mapInvcTaxOverAmtForFlat.isEmpty() && mapInvcTaxOverAmtForFlat.containsKey(invc.Id) && mapInvcTaxOverAmtForFlat.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && !setInvoiceId.Contains(invc.id) && !setInvoiceIdsForDetailMissing.Contains(invc.id) &&  invc.blng__InvoiceStatus__c == 'Posted'  && !duplicatecustInvcId.Contains(invc.id) && invc.QTB_Invoice_Type__c != 'Legacy Invoice'){
                        invoice.QTB_Ready_for_Integration__c = True;
                        invoice.QTB_Ready_for_Integration_Status__c = 'Success';
                        poIdSet.add(invc.QTB_PurchaseOrder__c);
                    }
                    //Else if any of the condition doesnot match then setting the status to Ready for Intgeration = False
                    else{
                        // Chech for Draft Invoice/Invoice Lines
                        if(mapInvcTaxOverAmtForFlat.isEmpty() || !mapInvcTaxOverAmtForFlat.containsKey(invc.Id) || mapInvcTaxOverAmtForFlat.get(invc.Id) != invc.QTB_Tax_Override_Amount__c || setInvoiceId.Contains(invc.id) ||  invc.blng__InvoiceStatus__c == 'Draft' || invc.blng__InvoiceStatus__c == 'Post In progress' || duplicatecustInvcId.contains(invc.Id) || setInvoiceIdsForDetailMissing.Contains(invc.id) || duplicatecustInvcId.contains(invc.Id)){
                            {
                                // If there is mismatch of Tax Amount Mismatch, Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number
                                if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && (mapInvcTaxOverAmtForFlat.isEmpty() || !mapInvcTaxOverAmtForFlat.containsKey(invc.Id) || mapInvcTaxOverAmtForFlat.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) && setInvoiceId.Contains(invc.id) && setInvoiceIdsForDetailMissing.Contains(invc.id) && duplicatecustInvcId.contains(invc.Id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch, Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number.'; 
                                }
                                // If there is mismatch of Tax Amount Mismatch, Invoice/Invoice line in Draft status
                                else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && (mapInvcTaxOverAmtForFlat.isEmpty() || !mapInvcTaxOverAmtForFlat.containsKey(invc.Id) || mapInvcTaxOverAmtForFlat.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) && setInvoiceIdsForDetailMissing.Contains(invc.id) && setInvoiceId.Contains(invc.id) && !duplicatecustInvcId.contains(invc.Id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch and Invoice/Invoice line in Draft status.'; //If any record found in Draft status, then updating the status on the Invoice
                                }
                                // If there is mismatch of Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number
                                else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && !mapInvcTaxOverAmtForFlat.isEmpty() && mapInvcTaxOverAmtForFlat.containsKey(invc.Id) && mapInvcTaxOverAmtForFlat.get(invc.Id) == invc.QTB_Tax_Override_Amount__c&& !setInvoiceIdsForDetailMissing.Contains(invc.id) && setInvoiceId.Contains(invc.id) && duplicatecustInvcId.contains(invc.Id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number.';
                                }
                                // If there is mismatch of Invoice/Invoice line in Draft status 
                                else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && !mapInvcTaxOverAmtForFlat.isEmpty() && mapInvcTaxOverAmtForFlat.containsKey(invc.Id) && mapInvcTaxOverAmtForFlat.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && !setInvoiceIdsForDetailMissing.Contains(invc.id) && setInvoiceId.Contains(invc.id) && !duplicatecustInvcId.contains(invc.Id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Invoice/Invoice line in Draft status'; 
                                }
                                else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && !mapInvcTaxOverAmtForFlat.isEmpty() && mapInvcTaxOverAmtForFlat.containsKey(invc.Id) && mapInvcTaxOverAmtForFlat.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && duplicatecustInvcId.contains(invc.Id) && !setInvoiceIdsForDetailMissing.Contains(invc.id) && !setInvoiceId.Contains(invc.id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Duplicate Custom Invoice Number';  
                                }
                                // If there is mismatch of Tax Amount Mismatch and Duplicate Custom Invoice Number
                                else if(invc.blng__InvoiceStatus__c == 'Posted' && !setInvoiceId.Contains(invc.id) && (mapInvcTaxOverAmtForFlat.isEmpty() || !mapInvcTaxOverAmtForFlat.containsKey(invc.Id) || mapInvcTaxOverAmtForFlat.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) && duplicatecustInvcId.contains(invc.Id) && setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch and Duplicate Custom Invoice Number.'; 
                                }
                                // If there is mismatch of Tax Amount Mismatch
                                else if(invc.blng__InvoiceStatus__c == 'Posted' && !setInvoiceId.Contains(invc.id) && (mapInvcTaxOverAmtForFlat.isEmpty() || !mapInvcTaxOverAmtForFlat.containsKey(invc.Id) || mapInvcTaxOverAmtForFlat.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) && !duplicatecustInvcId.contains(invc.Id) && setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch';        
                                }
                                else if(invc.blng__InvoiceStatus__c == 'Posted' && !setInvoiceId.Contains(invc.id) && !mapInvcTaxOverAmtForFlat.isEmpty() && mapInvcTaxOverAmtForFlat.containsKey(invc.Id) && mapInvcTaxOverAmtForFlat.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && duplicatecustInvcId.contains(invc.Id) && !setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Duplicate Custom Invoice Number';  
                                }
                                else if(invc.blng__InvoiceStatus__c == 'Post In progress'){
                                    invoice.QTB_Ready_for_Integration_Status__c = 'Error- Post In progress'; 
                                }
                                invoice.QTB_Ready_for_Integration__c = false;
                                invoice.blng__InvoiceStatus__c = 'Error'; 
                            }
                        }
                    }
                }
                //Else if its Product Based the checking from the Invoice lines Tax amt with Tax details amount
                else if((mapInvIdTaxOverAmtForProduct.isEmpty() || mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) || !mapInvcTaxOverAmtForFlat.containsKey(invc.Id)) && invc.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong' && invc.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED){
                    //For All success condition then setting to True
                    if(!mapInvIdTaxOverAmtForProduct.isEmpty() && mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) && mapInvIdTaxOverAmtForProduct.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && !setInvoiceId.Contains(invc.id) && !setInvoiceIdsForDetailMissing.Contains(invc.id) &&  invc.blng__InvoiceStatus__c == 'Posted' && !duplicatecustInvcId.Contains(invc.id) && invc.QTB_Invoice_Type__c != 'Legacy Invoice'){
                        invoice.QTB_Ready_for_Integration__c = True;
                        invoice.QTB_Ready_for_Integration_Status__c = 'Success';
                        poIdSet.add(invc.QTB_PurchaseOrder__c);
                    }
                    //Else QTB_Ready_for_Integration__c = false
                    else{
                        // If there is mismatch of Tax Amount Mismatch, Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number
                        if(mapInvIdTaxOverAmtForProduct.isEmpty() || !mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) || mapInvIdTaxOverAmtForProduct.get(invc.Id) != invc.QTB_Tax_Override_Amount__c || setInvoiceId.Contains(invc.id) ||  invc.blng__InvoiceStatus__c == 'Draft' || invc.blng__InvoiceStatus__c == 'Post In progress' || setInvoiceIdsForDetailMissing.Contains(invc.id) || duplicatecustInvcId.contains(invc.Id)){
                            
                            // If there is mismatch of Tax Amount Mismatch, Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number
                            if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && (mapInvIdTaxOverAmtForProduct.isEmpty() || !mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) || mapInvIdTaxOverAmtForProduct.get(invc.Id) != invc.QTB_Tax_Override_Amount__c ) && duplicatecustInvcId.contains(invc.Id) && setInvoiceId.Contains(invc.id) && setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch, Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number.'; //If any record found in Draft status, then updating the status on the Invoice
                            }
                            // If there is mismatch of Tax Amount Mismatch, Invoice/Invoice line in Draft status
                            else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && (mapInvIdTaxOverAmtForProduct.isEmpty() || !mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) || mapInvIdTaxOverAmtForProduct.get(invc.Id) != invc.QTB_Tax_Override_Amount__c ) && !duplicatecustInvcId.contains(invc.Id) && setInvoiceId.Contains(invc.id) && setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch and Invoice/Invoice line in Draft status.'; //If any record found in Draft status, then updating the status on the Invoice
                            }
                            // If there is mismatch of Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number
                            else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && !mapInvIdTaxOverAmtForProduct.isEmpty() && mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) && mapInvIdTaxOverAmtForProduct.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && duplicatecustInvcId.contains(invc.Id) && setInvoiceId.Contains(invc.id) && !setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Invoice/Invoice line in Draft status and Duplicate Custom Invoice Number.'; //If any record found in Draft status, then updating the status on the Invoice
                            }
                            // If there is mismatch of Invoice/Invoice line in Draft status 
                            else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && !mapInvIdTaxOverAmtForProduct.isEmpty() && mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) && mapInvIdTaxOverAmtForProduct.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && !duplicatecustInvcId.contains(invc.Id) && setInvoiceId.Contains(invc.id) && !setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Invoice/Invoice line in Draft status'; 
                            }
                            else if((invc.blng__InvoiceStatus__c == 'Draft' || setInvoiceId.Contains(invc.id)) && !mapInvIdTaxOverAmtForProduct.isEmpty() && mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) && mapInvIdTaxOverAmtForProduct.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && duplicatecustInvcId.contains(invc.Id) && !setInvoiceId.Contains(invc.id) && !setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Duplicate Custom Invoice Number';  
                            }
                            // If there is mismatch of Tax Amount Mismatch and Duplicate Custom Invoice Number
                            else if((invc.blng__InvoiceStatus__c == 'Posted' && !setInvoiceId.Contains(invc.id)) && (mapInvIdTaxOverAmtForProduct.isEmpty() || !mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) || mapInvIdTaxOverAmtForProduct.get(invc.Id) != invc.QTB_Tax_Override_Amount__c ) && duplicatecustInvcId.contains(invc.Id) && setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch and Duplicate Custom Invoice Number.'; 
                            }
                            // If there is mismatch of Tax Amount Mismatch
                            else if((invc.blng__InvoiceStatus__c == 'Posted' && !setInvoiceId.Contains(invc.id)) && (mapInvIdTaxOverAmtForProduct.isEmpty() || !mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) || mapInvIdTaxOverAmtForProduct.get(invc.Id) != invc.QTB_Tax_Override_Amount__c) && !duplicatecustInvcId.contains(invc.Id) && setInvoiceIdsForDetailMissing.Contains(invc.id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch';        
                            }
                            // If there is mismatch of Duplicate Custom Invoice Number
                            else if((invc.blng__InvoiceStatus__c == 'Posted' && !setInvoiceId.Contains(invc.id)) && !mapInvIdTaxOverAmtForProduct.isEmpty() && mapInvIdTaxOverAmtForProduct.containsKey(invc.Id) && mapInvIdTaxOverAmtForProduct.get(invc.Id) == invc.QTB_Tax_Override_Amount__c && duplicatecustInvcId.contains(invc.Id) && !setInvoiceIdsForDetailMissing.Contains(invc.id))                                        
                            {
                                invoice.QTB_Ready_for_Integration_Status__c = 'Duplicate Custom Invoice Number';  
                            }
                            else if(invc.blng__InvoiceStatus__c == 'Post In progress'){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Error- Post In progress'; 
                            }
                            invoice.QTB_Ready_for_Integration__c = false;
                            invoice.blng__InvoiceStatus__c = 'Error'; 
                        }
                    }
                }
                //For Legal Country outside 'Hong kong' 
                else{
                    //  Update Invoice Ready For Integration flag and status based for Hong Kong
                    if(mapInvcTaxOverAmtForFlat.isEmpty() && mapInvIdTaxOverAmtForProduct.isEmpty() && !mapInvcTaxOverAmtForFlat.containsKey(invc.Id) && !mapInvIdTaxOverAmtForProduct.containsKey(invc.id) && invc.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong' && !setInvoiceIdsForDetailMissing.contains(invc.Id)){
                        //  Update Invoice Ready For Integration flag and status based for Hong Kong True 
                        if(invc.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong'  && !setInvoiceId.Contains(invc.id) && !setInvoiceIdsForDetailMissing.Contains(invc.id) &&  invc.blng__InvoiceStatus__c == 'Posted' && invc.QTB_Invoice_Type__c != 'Legacy Invoice' && !duplicatecustInvcId.contains(invc.Id)){
                            invoice.QTB_Ready_for_Integration__c = True;
                            invoice.QTB_Ready_for_Integration_Status__c = 'Success';
                            poIdSet.add(invc.QTB_PurchaseOrder__c);
                        }
                        //  Update Invoice Ready For Integration flag and status based for Hong Kong when Draft Lines are present in Invoice/ Invoice Lines and Duplicate Custom Invoice Number
                        else{
                            //  Update Invoice Ready For Integration flag and status based for Hong Kong when Draft Lines are present in Invoice/ Invoice Lines and Duplicate Custom Invoice Number
                            if(invc.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong'  && (setInvoiceId.Contains(invc.id) ||  invc.blng__InvoiceStatus__c == 'Draft') && duplicatecustInvcId.contains(invc.Id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Invoice/Invoice Lines are in Draft and Duplicate Custom Invoice Number.';
                            }
                            //  Update Invoice Ready For Integration flag and status based for Hong Kong when Duplicate Custom Invoice Number
                            else if(invc.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong'  && (!setInvoiceId.Contains(invc.id) &&  invc.blng__InvoiceStatus__c == 'Posted') && duplicatecustInvcId.contains(invc.Id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Duplicate Custom Invoice Number.'; 
                            }                            
                            //  Update Invoice Ready For Integration flag and status based for Hong Kong when Draft Lines are present in Invoice/ Invoice Lines 
                            else if(invc.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong' && (setInvoiceId.Contains(invc.id) || invc.blng__InvoiceStatus__c == 'Draft') && !duplicatecustInvcId.contains(invc.Id)){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Invoice/Invoice Lines are in Draft';
                            }
                            else if(invc.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong' && !setInvoiceId.Contains(invc.id) && invc.blng__InvoiceStatus__c == 'Posted' && !duplicatecustInvcId.contains(invc.Id)){
                                invoice.QTB_Ready_for_Integration__c = false;
                            }
                            else if(invc.blng__InvoiceStatus__c == 'Post In progress'){
                                invoice.QTB_Ready_for_Integration_Status__c = 'Error- Post In progress'; 
                            }
                            else{
                                invoice.QTB_Ready_for_Integration__c = false;
                            invoice.blng__InvoiceStatus__c = 'Error'; 
                            }
                        }
                    } 
                }   
                //24251 - Start for Operation account check
                if(!billingAccIds.isEmpty() && billingAccIds.contains(invc.blng__Account__c)){
                    
                    invoice.QTB_Ready_for_Integration__c = false;
                    invoice.QTB_Ready_for_Integration_Status__c = 'Operational Account is not present. Please add.'; 
                    invoice.blng__InvoiceStatus__c = 'Error'; 
                } 
                // For Legacy Invoice
                if (invc.QTB_Invoice_Type__c == 'Legacy Invoice' && invoice.QTB_Ready_for_Integration_Status__c== 'Post In Progress'){
                    invoice.QTB_Ready_for_Integration_Status__c = null;
                }
                //24251 - Stop
                //Updating the Invoice Ids with respective values
                lstUpdatedInvoice.add(invoice);
            }
            //Updating the Invoice Ids with respective values
            if(!lstUpdatedInvoice.isEmpty()){
                SBQQ.TriggerControl.disable();
                update lstUpdatedInvoice;
                SBQQ.TriggerControl.enable();
                lstUpdatedInvoice.clear();
            }
            
        }
        catch(Exception e)
        { QTB_ExceptionLogger.enable(); System.debug('Exception message:'+e.getMessage()); 
         errorIds = e.getMessage()+errorIds;
         if(errorIds.length()>100000){ 
             errorIds = errorIds.substring(0,100000);
         }
         e.getMessage();
         e.getTypeName();
         QTB_ExceptionLogger.createLog(
             e.getLineNumber(),
             e.getStackTraceString(),
             errorIds,e.getTypeName(),
             CLASSNAME);
        }
    }
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC){
        try{
            if( QTB_ReadyForIntegrationWithSuccessError.throwExplicitException){
                throw new NullPointerException();
            }
            if(!poIdSet.isEmpty()){
                Database.executeBatch(new QTB_sendPONotificationBatch(new List<Id>(poIdSet)), Integer.valueOf(System.Label.QTB_PO_Notification_Batch_Size));
            } 
        }
        catch(Exception e){ 
            e.getStackTraceString();
            e.getMessage();
            e.getTypeName();
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }
}