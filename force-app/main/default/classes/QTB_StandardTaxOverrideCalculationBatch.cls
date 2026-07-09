/*****************************************************************************************************
* Class: QTB_StandardTaxOverrideCalculationBatch
* Test class: 
* Author: Lokesh Tewari
* Purpose: This is a Batch class containing logic for calculating QTB_StandardTaxOverrideCalculation for Turkey after Ready for int checks
* Developer                   Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari			    10/11/2025     	This is a Batch class containing logic for calculating QTB_StandardTaxOverrideCalculation for Turkey after Ready for int checks
*******************************************************************************************************/

global class QTB_StandardTaxOverrideCalculationBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    
    // Variable to throw exception for catch block
    public static boolean throwExplicitException = false;
    // Variable to get the class name    
    private static final String CLASSNAME = QTB_StandardTaxOverrideCalculationBatch.class.getName();
    // Map to store invoice id and set of invoice line ids
    Map<id,Set<id>> mapOfInvcAndInvcLineSet = new Map<id,Set<id>>();
    // Constructor to get the invoice id passed from QTB_StandardTaxOverrideCalculationBatch
    global QTB_StandardTaxOverrideCalculationBatch(Map<id,Set<id>> mapOfInvcAndInvcLine){
        try{
            if( QTB_StandardTaxOverrideCalculationBatch.throwExplicitException){
                throw new NullPointerException();
            }
            mapOfInvcAndInvcLineSet.putAll(mapOfInvcAndInvcLine);
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
        //Querying for all the Invoice 
        List<blng__Invoice__c> lstInvc = [select Id,Name,blng__Subtotal__c,QTB_Total_Amount_With_Std_Tax_Override__c FROM blng__Invoice__c where id in :mapOfInvcAndInvcLineSet.keyset()];
        return lstInvc;
        
    }
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__Invoice__c>
Return Type: void
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<blng__Invoice__c> scope){
        string errorIds = '';
        try{
            // set to store invoice line id
            set<id> invoiceLineIds = new set<id>();
            // set to store invoice line id
            set<id> invoiceLineIdSet ;
            // List to temperary story Tax Details associated to each invoice
            List<QTB_Tax_Detail__c> lstTaxDetail ;
            // List to store invoices to be update
            List<blng__Invoice__c> lstInvoice = new List<blng__Invoice__c>();
            // Map to store Invoice Id and List of Tax Detail
            map<id,list<QTB_Tax_Detail__c>> invcIdLstTaxDetailMap = new map<id,list<QTB_Tax_Detail__c>>();
            
            if( QTB_StandardTaxOverrideCalculationBatch.throwExplicitException){
                throw new NullPointerException();
            }
            // Set to store all invoice Line ids
            for(blng__Invoice__c invoice:scope){
                if(mapOfInvcAndInvcLineSet.containsKey(invoice.Id)){
                    invoiceLineIds.addAll(mapOfInvcAndInvcLineSet.get(invoice.Id));
                }
            }
            // Check for set of Invoice Line ids present of not
            if(!invoiceLineIds.isEmpty() || Test.isRunningTest()){   
                //This query finds all matching Tax Details EXCLUDING the non 'WithHolding Tax Rate' category.
                List<QTB_Tax_Detail__c> lstTaxDetails = [SELECT id,QTB_Invoice_Line__c,QTB_Invoice_Line__r.blng__Invoice__c, QTB_Tax_Override_Amount__c FROM QTB_Tax_Detail__c
                                                         WHERE QTB_Tax_Category__c != 'WithHolding Tax Rate' and QTB_Invoice_Line__c in : invoiceLineIds]; 
                
                if(!lstTaxDetails.isEmpty()){
                    for(QTB_Tax_Detail__c taxDetail : lstTaxDetails){
                        lstTaxDetail= new List<QTB_Tax_Detail__c>();
                        lstTaxDetail.add(taxDetail);
                        // Check if the Invoice id present inside invcIdLstTaxDetailMap
                        if(invcIdLstTaxDetailMap.containsKey(taxDetail.QTB_Invoice_Line__r.blng__Invoice__c)){
                            lstTaxDetail.addAll(invcIdLstTaxDetailMap.get(taxDetail.QTB_Invoice_Line__r.blng__Invoice__c));
                        }
                        // create map to store Invoice Id and List of Tax Detail
                        invcIdLstTaxDetailMap.put(taxDetail.QTB_Invoice_Line__r.blng__Invoice__c,lstTaxDetail);
                    }
                    // For loop to update Invoices for Standard Tax field
                    for(blng__Invoice__c invoice:scope){
                        decimal standardTax =0;
                        if(invcIdLstTaxDetailMap.containsKey(invoice.id)){
                            for(QTB_Tax_Detail__c taxDetail :invcIdLstTaxDetailMap.get(invoice.id)){
                                standardTax = standardTax + taxDetail.QTB_Tax_Override_Amount__c;
                            }
                        }
                        invoice.QTB_Total_Amount_With_Std_Tax_Override__c = invoice.blng__Subtotal__c+standardTax;
                        lstInvoice.add(invoice);
                    }
                }
            }
            // Invoice Update
            if(!lstInvoice.isempty()){
                update lstInvoice;
            }
        }
        catch(Exception e)
        {
            QTB_ExceptionLogger.enable(); System.debug('Exception message:'+e.getMessage()); 
            System.debug('Exception message:'+e.getLineNumber()); 
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
            if( QTB_StandardTaxOverrideCalculationBatch.throwExplicitException){
                throw new NullPointerException();
            }}
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