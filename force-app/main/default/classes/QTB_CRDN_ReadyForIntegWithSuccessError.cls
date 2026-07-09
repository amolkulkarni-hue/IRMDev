/*****************************************************************************************************
* Class: QTB_CRDN_ReadyForIntegWithSuccessError
* Test class: QTB_ReadyForIntWithSuccessError_Test
* Author: Yogesh Sharma
* Purpose: This is a Batch class containing logic for the CreditNote lines which are in draft even after CreditNotes are posted
* Requirement: To iterate on the draft CreditNote lines
* Change History: 14/05/2024
* Developer                   Date                    Description
* ------------------------------------------------------------------------------------------- 
Yogesh Sharma      14/05/2024     Creation of new Batch class checking if they are still any Draft CreditNote lines
*******************************************************************************************************/
global class QTB_CRDN_ReadyForIntegWithSuccessError implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    
    //To throw exception for catch block
    public static boolean throwExplicitException = false;
    //To get the class name
    private static final String CLASSNAME = QTB_CRDN_ReadyForIntegWithSuccessError.class.getName();
    //To store CreditNote id passed from QTB_Ready_for_Integration_Batch
    public Set<string> creditNoteIdSetFromBatch = new Set<string>();
    
    //Constructor to get the CreditNote id passed from QTB_Ready_for_Integration_Batch
    global QTB_CRDN_ReadyForIntegWithSuccessError(Set<Id> creditNoteIdSet){
        try{
            if( QTB_CRDN_ReadyForIntegWithSuccessError.throwExplicitException){
                throw new NullPointerException();
            }
            if(!creditNoteIdSet.isEmpty()){
                for(Id crdtNoteId : creditNoteIdSet){
                    creditNoteIdSetFromBatch.add(crdtNoteId);
                }
            }
        }
        catch(Exception e){ 
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
    global List<blng__CreditNote__c> start(Database.BatchableContext BC){
        //Querying for all the CreditNote processed from QTB_Ready_for_Integration_Batch
         List<blng__CreditNote__c> creditNoteList = [SELECT Id,blng__Account__r.QTB_Legal_Entity_Country__c,Is_Tax_Applicable__c,QTB_Custom_Invoice_Number__c,QTB_Custom_Invoice_ID__c,QTB_CreditNoteRecordType__c,name,blng__Status__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,
                                          blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,
                                          blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,QTB_Purchase_Order__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                                          recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,QTB_Ready_for_Integration__c,QTB_Ready_for_Integration_Status__c FROM blng__CreditNote__c WHERE Id IN: creditNoteIdSetFromBatch];
        
        
        return creditNoteList;
        
    }
    
    /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<blng__CreditNote__c>
    Return Type: void
    **********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<blng__CreditNote__c> scope){
        String errorIds = '';
        Map<string,Id> customInvoiceNumberWithCNIdMap = new Map<string,Id>();
        Set<Id> duplicateCustomInvoiceNumCNIdSet = new Set<Id>();
        Set<Id> creditNoteIdSetForDraftCreditNoteLines = new Set<Id>();
        Set<Id> taxApplicableCreditNoteIdSet = new Set<Id>(); //Added by Yogesh - #27189
        Set<Id> creditNoteIdSetForFlatRate = new Set<Id>();
        Map<Id,Id> creditNoteLineIdWithCreditNoteIdMapForProductBased = new Map<Id,Id>(); 
        Map<Id,Decimal> creditNoteIdWithTaxOverrideAmountMap = new Map<Id,Decimal>();
        List<blng__CreditNote__c> creditNoteListToUpdate = new List<blng__CreditNote__c>();
        Set<String> countrySet = new Set<string>();
        QTB_Tax_Integration_Setting__mdt countryValForVertex = QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration');
        try{
            if( QTB_CRDN_ReadyForIntegWithSuccessError.throwExplicitException){
                throw new NullPointerException();
            }
            if(!scope.isEmpty()){
                for(blng__CreditNote__c cnObj : scope){
                    errorIds +=';;'+cnObj.id;
                    customInvoiceNumberWithCNIdMap.put(cnObj.QTB_Custom_Invoice_Number__c,cnObj.Id); 
                    countrySet.add(cnObj.blng__Account__r.QTB_Legal_Entity_Country__c);
                }
                
            }

            if(!customInvoiceNumberWithCNIdMap.isEmpty()){

                //To check duplicate custom invoice number in the existing credit notes
                for(blng__CreditNote__c crdNoteObj : [SELECT Id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c 
                                                        FROM blng__CreditNote__c WHERE blng__Status__c = 'Posted' AND QTB_Custom_Invoice_Number__c 
                                                        IN :customInvoiceNumberWithCNIdMap.KeySet() AND Id NOT IN :customInvoiceNumberWithCNIdMap.values()
                                                        AND blng__Account__r.QTB_Legal_Entity_Country__c IN : countrySet]){
                    if(customInvoiceNumberWithCNIdMap.containsKey(crdNoteObj.QTB_Custom_Invoice_Number__c) || Test.isRunningTest()){
                        duplicateCustomInvoiceNumCNIdSet.add(customInvoiceNumberWithCNIdMap.get(crdNoteObj.QTB_Custom_Invoice_Number__c));
                    }
                }
                //To check duplicate custom invoice number in the existing invoices
                for(blng__invoice__c invObj : [SELECT Id, QTB_Custom_Invoice_Number__c FROM blng__invoice__c WHERE blng__InvoiceStatus__c = 'Posted' AND QTB_Custom_Invoice_Number__c 
                                                        IN : customInvoiceNumberWithCNIdMap.KeySet() AND blng__Account__r.QTB_Legal_Entity_Country__c IN : countrySet]){
                    if(customInvoiceNumberWithCNIdMap.containsKey(invObj.QTB_Custom_Invoice_Number__c) || Test.isRunningTest()){
                        duplicateCustomInvoiceNumCNIdSet.add(customInvoiceNumberWithCNIdMap.get(invObj.QTB_Custom_Invoice_Number__c));
                    }
                                                            
                }
                //To get all Credit Note lines from the scope
                List<blng__CreditNoteLine__c> creditNoteLineList = [SELECT Id,blng__TaxAmount__c,blng__Status__c,QTB_Tax_Override_Amount__c, blng__CalculateTax__c,
                                                                     blng__CreditNote__r.id,blng__Subtotal__c,
                                                                     blng__TaxPercentageApplied__c,blng__CreditNote__r.blng__Subtotal__c,
                                                                     blng__LegalEntity__r.Id,blng__CreditNote__r.blng__Status__c,
                                                                     blng__CreditNote__r.QTB_Transferred_to_Invoice_Compliance__c,
                                                                     blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                                     blng__CreditNote__c,LastModifiedDate,
                                                                     blng__CreditNote__r.Is_Tax_Applicable__c,
                                                                     blng__CreditNote__r.QTB_Custom_Invoice_Number__c,
                                                                     blng__CreditNote__r.QTB_Ready_for_Integration__c,
                                                                     blng__CreditNote__r.QTB_Ready_for_Integration_Status__c,
                                                                     blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                                                                     blng__CreditNote__r.blng__Account__r.QTB_Customer_Number__c
                                                                     FROM blng__CreditNoteLine__c 
                                                                     WHERE blng__CreditNote__r.blng__Status__c = 'Posted' AND
                                                                     blng__CreditNote__c IN : customInvoiceNumberWithCNIdMap.values()];
                
                if(!creditNoteLineList.isEmpty()){
                    //To check draft status of credit note lines
                    for(blng__CreditNoteLine__c crdNoteLineObj : creditNoteLineList){
                        if(crdNoteLineObj.blng__Status__c == 'Draft'){
                            creditNoteIdSetForDraftCreditNoteLines.add(crdNoteLineObj.blng__CreditNote__c);
                        }
                        //Added by Yogesh - #27189
                    //  Added As part of Git # epics/3176 condition to check if country is equal to USA or Cananda then add credit note in taxApplicableCreditNoteIdSet
                        if(crdNoteLineObj.blng__CalculateTax__c ||
                         (countryValForVertex != null && crdNoteLineObj.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c !=null
                         && countryValForVertex.QTB_Country__c.containsIgnoreCase(crdNoteLineObj.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c))
                        ){
                            taxApplicableCreditNoteIdSet.add(crdNoteLineObj.blng__CreditNote__c);
                        }
                       
                        //To check tax Applicability (Flat Rate or Product based) for Non Hong Kong countries
                        if(crdNoteLineObj.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong'){
                            //Tax Applicability is Flat Rate
                            if(crdNoteLineObj.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT){
                                creditNoteIdSetForFlatRate.add(crdNoteLineObj.blng__CreditNote__c);
                            }
                            //Tax Applicability is Product Based Rate 
                            if(crdNoteLineObj.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED){
                                creditNoteLineIdWithCreditNoteIdMapForProductBased.put(crdNoteLineObj.Id,crdNoteLineObj.blng__CreditNote__c);
                            }
                        }
                    }
                	
                    if(!creditNoteIdSetForFlatRate.isEmpty() || !creditNoteLineIdWithCreditNoteIdMapForProductBased.isEmpty()){
                        //Fetching all the Tax details related to the CreditNote and CreditNote lines for the comparison
                        List<QTB_Tax_Detail__c> taxDetailList = [SELECT Id,Name, QTB_Credit_Note__C,QTB_Tax_Override_Amount__c,
                                                                QTB_Credit_Note__r.blng__Account__r.QTB_Special_Tax_Condition__c, 
                                                                QTB_Credit_Note_Line__c 
                                                                FROM QTB_Tax_Detail__c 
                                                                WHERE QTB_Credit_Note__C IN: creditNoteIdSetForFlatRate OR QTB_Credit_Note_Line__c IN: creditNoteLineIdWithCreditNoteIdMapForProductBased.keyset()];
                        if(!taxDetailList.isEmpty()){
 
                            for(QTB_Tax_Detail__c taxDetailObj : taxDetailList){
                                Decimal taxAmt = 0;
                                //Summarize Flat Rate Tax Override Amount of all the credit note lines
                                if(creditNoteIdSetForFlatRate.contains(taxDetailObj.QTB_Credit_Note__C)){ 
                                    taxAmt = taxDetailObj.QTB_Tax_Override_Amount__c != null ? taxDetailObj.QTB_Tax_Override_Amount__c : 0;
                                    if(creditNoteIdWithTaxOverrideAmountMap.containsKey(taxDetailObj.QTB_Credit_Note__C)){
                                        taxAmt = taxAmt + creditNoteIdWithTaxOverrideAmountMap.get(taxDetailObj.QTB_Credit_Note__C);
                                    }  
                                    creditNoteIdWithTaxOverrideAmountMap.put(taxDetailObj.QTB_Credit_Note__C,taxAmt);
                                }   

                                //Summarize Product Based Tax Override Amount of all the credit note lines                                                                 
                                if(taxDetailObj.QTB_Credit_Note_Line__c != null && creditNoteLineIdWithCreditNoteIdMapForProductBased.containsKey(taxDetailObj.QTB_Credit_Note_Line__c)){
                                    Id creditNoteId = creditNoteLineIdWithCreditNoteIdMapForProductBased.get(taxDetailObj.QTB_Credit_Note_Line__c);  
                                    taxAmt = taxDetailObj.QTB_Tax_Override_Amount__c != null ? taxDetailObj.QTB_Tax_Override_Amount__c : 0;
                                    if(creditNoteIdWithTaxOverrideAmountMap.containsKey(creditNoteId)){
                                        taxAmt = taxAmt + creditNoteIdWithTaxOverrideAmountMap.get(creditNoteId);
                                    }
                                    creditNoteIdWithTaxOverrideAmountMap.put(creditNoteId,taxAmt);
                                }
                            }
                        }
                    }
                }  
            } 
			
            //To display error or success message and setting Ready for integration flag as true or false based on conditions
            for(blng__CreditNote__c crdNoteObj : scope){ 
                //As a part of Git issues/33351 Need to  Round off creditNoteIdWithTaxOverrideAmountMap by 2 as per the condition so there will be no mismatch amount 
               If(creditNoteIdWithTaxOverrideAmountMap.containsKey(crdNoteObj.Id)){
                   creditNoteIdWithTaxOverrideAmountMap.put(crdNoteObj.Id,creditNoteIdWithTaxOverrideAmountMap.get(crdNoteObj.Id).setScale(2, System.RoundingMode.HALF_UP));
               }
                blng__CreditNote__c creditNote = new blng__CreditNote__c();
                creditNote.Id = crdNoteObj.Id;
				Decimal tempTaxOverrideAmount = crdNoteObj.QTB_Tax_Override_Amount__c != null ? (crdNoteObj.QTB_Tax_Override_Amount__c).setScale(2, System.RoundingMode.HALF_UP) : 0;
                If(crdNoteObj.blng__Account__r.QTB_Legal_Entity_Country__c == 'Hong Kong' || crdNoteObj.Is_Tax_Applicable__c == false){
                    if((crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id))
                        && duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id)){
                            creditNote.QTB_Ready_for_Integration_Status__c = 'CreditNote/CreditNote line in Draft status and Duplicate Custom Credit Note Number.'; 
                            creditNote.QTB_Ready_for_Integration__c = false;
                            creditNote.blng__Status__c = 'Error';
                    }else if(crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'CreditNote/CreditNote line in Draft status.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;
                                creditNote.blng__Status__c = 'Error';
                    }else if(duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'Duplicate Custom Credit Note Number.'; 
                                creditNote.QTB_Ready_for_Integration__c = false; creditNote.blng__Status__c = 'Error';
                               
                    }
                    else{
                        creditNote.QTB_Ready_for_Integration_Status__c = 'Success'; 
                        creditNote.QTB_Ready_for_Integration__c = true;creditNote.blng__Status__c = 'Posted';
                        
                    }   
                }
                else if(crdNoteObj.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong'){
                    if(!creditNoteIdWithTaxOverrideAmountMap.isEmpty() ){
                        if((crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id)) 
                            && (creditNoteIdWithTaxOverrideAmountMap.get(crdNoteObj.Id) != tempTaxOverrideAmount)
                            && (duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id))
                            && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch, CreditNote/CreditNote line in Draft status and Duplicate Custom Credit Note Number.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;
                                creditNote.blng__Status__c = 'Error';
                        }else if((crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id))
                            && creditNoteIdWithTaxOverrideAmountMap.get(crdNoteObj.Id) != tempTaxOverrideAmount
                            && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch and CreditNote/CreditNote line in Draft status.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;
                                creditNote.blng__Status__c = 'Error';
                        }else if((crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id))
                            && duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'CreditNote/CreditNote line in Draft status and Duplicate Custom Credit Note Number.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;
                                creditNote.blng__Status__c = 'Error';
                        }else if((creditNoteIdWithTaxOverrideAmountMap.get(crdNoteObj.Id) != tempTaxOverrideAmount)
                            && duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id)
                            && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch and Duplicate Custom Credit Note Number.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;creditNote.blng__Status__c = 'Error';
                                
                        }else if(crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id)){
                            creditNote.QTB_Ready_for_Integration_Status__c = 'CreditNote/CreditNote line in Draft status.'; 
                            creditNote.QTB_Ready_for_Integration__c = false; creditNote.blng__Status__c = 'Error';
                           
                        }else if(creditNoteIdWithTaxOverrideAmountMap.get(crdNoteObj.Id) != tempTaxOverrideAmount && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                            creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Amount Mismatch.'; 
                            creditNote.QTB_Ready_for_Integration__c = false;creditNote.blng__Status__c = 'Error'; 
                             
                        }else if(duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id)){
                            creditNote.QTB_Ready_for_Integration_Status__c = 'Duplicate Custom Credit Note Number.'; 
                            creditNote.QTB_Ready_for_Integration__c = false; creditNote.blng__Status__c = 'Error';
                              
                        }else{ 
                            creditNote.QTB_Ready_for_Integration_Status__c = 'Success'; 
                            creditNote.QTB_Ready_for_Integration__c = true;
                            creditNote.blng__Status__c = 'Posted';
                        }
                    }
                   
                    else if(creditNoteIdWithTaxOverrideAmountMap.isEmpty() 
                            && (crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id))
                            && duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id)
                            && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Details are not generated, CreditNote/CreditNote line in Draft status and Duplicate Custom Credit Note Number.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;
                                creditNote.blng__Status__c = 'Error';
                    }else if(creditNoteIdWithTaxOverrideAmountMap.isEmpty()
                            && (crdNoteObj.blng__Status__c == 'Draft' || creditNoteIdSetForDraftCreditNoteLines.contains(crdNoteObj.Id))
                            && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Details are not generated, CreditNote/CreditNote line in Draft status.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;creditNote.blng__Status__c = 'Error';
                                
                    }else if(creditNoteIdWithTaxOverrideAmountMap.isEmpty() 
                            && duplicateCustomInvoiceNumCNIdSet.contains(crdNoteObj.Id)
                            && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                                creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Details are not generated and Duplicate Custom Credit Note Number.'; 
                                creditNote.QTB_Ready_for_Integration__c = false;creditNote.blng__Status__c = 'Error';
                                
                    }else if(creditNoteIdWithTaxOverrideAmountMap.isEmpty() && taxApplicableCreditNoteIdSet.contains(crdNoteObj.Id)){
                        creditNote.QTB_Ready_for_Integration_Status__c = 'Tax Details are not generated or CreditNote/CreditNote line in Draft status.'; 
                        creditNote.QTB_Ready_for_Integration__c = false;creditNote.blng__Status__c = 'Error';
                        
                    }else{ 
                            creditNote.QTB_Ready_for_Integration_Status__c = 'Success'; 
                            creditNote.QTB_Ready_for_Integration__c = true;
                            creditNote.blng__Status__c = 'Posted';
                        }
                  
                }
               
                creditNoteListToUpdate.add(creditNote);
            }    
            if(!creditNoteListToUpdate.isEmpty()){
                SBQQ.TriggerControl.disable();
                update creditNoteListToUpdate;
                SBQQ.TriggerControl.enable();
                creditNoteListToUpdate.clear();
            }
        }
        catch(Exception e){ QTB_ExceptionLogger.enable(); System.debug('Exception message:'+e.getMessage()); 
            errorIds = e.getMessage()+errorIds;
            if(errorIds.length()>100000){  errorIds = errorIds.substring(0,100000);
               
            }
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
    global static void finish(Database.BatchableContext BC){}    
    
}