/*****************************************************************************************************
* Class:   QTB_TaxOverrideAmountCalculationBatch
* Test:    QTB_TaxOverrideAmountCalBatch_Test
* Author: Virtusa
* Purpose: This is a Batch class to update tax oveerirde amount field on invoice and invoice line
* Requirement: #33697
* Change History:
* Developer     			Date           Description
* -------------------------------------------------------------------------------------------
* Parth(Virtusa)            06/10/2025     tax oveeride calculation logic is written on invoice line trigger, but it is not updating if no. if invoice line are more on a single invoice,
it is updating tax override amount on fist 200 invoice line post that method is not getting called due to recurrsion check, so moved the logic to batch class
*******************************************************************************************************/
public class QTB_TaxOverrideAmountCalculationBatch implements Database.Batchable<SObject>{
    
    Public static final string className = QTB_TaxOverrideAmountCalculationBatch.class.getName();
    Public static boolean throwExplicitException = false;
    Public String query;
    Set<ID> invidsSet = new Set<ID>();
    Set<ID> invSchedulerId = new Set<Id>();
    //Constructor for the class QTB_TaxOverrideAmountCalculationBatch
    Public QTB_TaxOverrideAmountCalculationBatch(Set<ID> invoiceIdsSet,set<Id>invoiceSchedulerIdSet) {
        invidsSet = invoiceIdsSet;
        invSchedulerId = invoiceSchedulerIdSet;
        query = 'Select Id from blng__Invoice__c where Id IN :invidsSet'; //only fetching invoice Id and based on that will fetch invoice line in execut method
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
Parameters: Database.BatchableContext,List<blng__InvoiceLine__c> InvoiceLineLst
Return Type: voidQTB
Requirement:
Description: This is having the Functionality to update updateInvoiceMRCDates of Invoice MRC start AND End End date AND Service Start AND End date
based on Account - Billing Frequency AND Account - Billing Forward type AND Invoice Scheduler Legal Entity AND Invoice period selected
**********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<blng__Invoice__c> InvoiceLst) {
        try{
            if(QTB_TaxOverrideAmountCalculationBatch.throwExplicitException){
                throw new NullPointerException();
            }
            if(!InvoiceLst.isEmpty()){
                List<blng__InvoiceLine__c>InvoiceLineLst = [SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,
                                                            blng__Invoice__r.blng__Subtotal__c,blng__LegalEntity__r.ID,blng__Invoice__r.blng__InvoiceStatus__c,blng__Invoice__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                            blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                            QTB_Tax_Code__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c,blng__Invoice__r.QTB_Invoice_Type__c,
                                                            blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c,blng__Invoice__r.blng__NumberOfInvoiceLines__c,
                                                            blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN :InvoiceLst];
                if(!InvoiceLineLst.isEmpty()){
                    Set<String> addressComparisonSet = new Set<String>();
                    Map<String, List<blng__TaxRate__c>> taxRatesMaps = new Map<String, List<blng__TaxRate__c>>();
                    Map<ID,Boolean>mapOfInvIdAndTieredLines = new Map<ID,Boolean>(); // #30514 map to store if invoice has any tiered invoice line
                    Map<ID,blng__Invoice__c> mapOfInvcIdAndInvc = new Map<ID,blng__Invoice__c>(); // Map to store Invoice ID and List of invoice which will get updated when Tax Applicability is Flat Rate
                    Map<ID,Decimal> mapOfInvcIdTaxOvrd = new Map<ID,Decimal>();
                    List<blng__InvoiceLine__c> listUpdateInvcLine  = new List<blng__InvoiceLine__c>();// List to Update Invoice Line for when Tax Applicability is Product Based
                    boolean hasTieredLines = false;
                    
                    For(blng__InvoiceLine__c invLine :InvoiceLineLst){
                        //Create Set of Address comparison for fetching Tax Rate record based on address Comparison field on Tax Ratecompare address with Tax Rate addressComparisonSet field
                        String invoiceLineComparison = invLine?.blng__TaxCountry__c +'-' + invLine?.blng__TaxState__c +'-' +  invLine?.blng__TaxCity__c +'-' +
                            invLine?.blng__TaxZipCode__c +'-' + invLine?.QTB_Tax_Code__c +'-' + invLine?.blng__LegalEntity__c;
                        invoiceLineComparison = invoiceLineComparison.replaceAll('null',''); 
                        addressComparisonSet.add(invoiceLineComparison);
                    }
                    
                    QTB_InvoiceHelper.buildTaxRateMap(addressComparisonSet); // Calling buildTaxRateMap method to get taxrate records 
                    // Create Map of address comparison key with List of tax rate record
                    taxRatesMaps = QTB_InvoiceHelper.taxRatesMap;// Note that taxRatesMaps is a static variable refernced from QTB_InvoiceHelper
                    
                    For(blng__InvoiceLine__c invLine :InvoiceLineLst){
                        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(); //Initialization and decleration of blng__InvoiceLine__c to store the Invoice Line when Tax Applicability is Product Based 
                        blng__Invoice__c invc = new blng__Invoice__c(); //Initialization and decleration of Invoice to store the Invoice when Tax Applicability is Flat Rate 
                        //#30514 - updating has tiered lines to true if any invoice line has tiered flag as true
                        hasTieredLines = invLine.QTB_Tiered_Flag__c;
                        // if tiered flag is true line than storeing in map, which will help to update has tired flag to true on invoice
                        if(!mapOfInvIdAndTieredLines.containsKey(invLine.blng__Invoice__r.ID) && hasTieredLines){
                            mapOfInvIdAndTieredLines.put(invLine.blng__Invoice__r.ID,True);
                        }
                        // Create Address comparison String to compare address with Tax Rate addressComparisonSet field //US #29100 added .replace directly into the String
                        String invoiceLineComparison = (invLine?.blng__TaxCountry__c +'----' + invLine?.QTB_Tax_Code__c +'-' + invLine?.blng__LegalEntity__c).replaceAll('null','');//remove null FROM String;
                        // Update QTB_Tax_Override_Amount__c on invoice and Invoice Line when Tax Exempt on Account is No
                        if(invLine.blng__Invoice__r.blng__Account__r?.SBQQ__TaxExempt__c.equalsIgnoreCase(QTB_Constants.TAX_EXEMPT_NO) &&
                           (invLine.blng__TaxPercentageApplied__c != null || (Label.QTB_NA_Countries!=null && Label.QTB_NA_Countries.containsIgnoreCase(invLine.blng__TaxCountry__c)))){ //#Gitlab 29100 added null check before checking contains Label.QTB_NA_Countries
                               
                               // Update QTB_Tax_Override_Amount__c on invoice for Tax Type Flat Rate
                               if(invLine.blng__TaxTreatment__c != null && invLine.blng__LegalEntity__r?.QTB_Tax_Applicability__c.equalsIgnoreCase(QTB_Constants.LEGALENTITY_TYPE_FLAT)
                                  &&(!mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__c)) && (taxRatesMaps.containsKey(invoiceLineComparison))){ 
                                      // Fetching Tax Rate record FROM taxRatesMaps based on address comparison
                                      for(blng__TaxRate__c taxRate : taxRatesMaps.get(invoiceLineComparison)){
                                          // Calculating Tax Rate value based on Rate of Tax Rate and Invoice Sub Total
                                          Decimal taxRoundOff =  (invLine.blng__Invoice__r.blng__Subtotal__c != null && taxRate.blng__Rate__c != null) ? ((invLine.blng__Invoice__r.blng__Subtotal__c * taxRate.blng__Rate__c * 0.01)).setScale(2, System.RoundingMode.HALF_UP): 0.0;
                                          if(!mapOfInvcIdTaxOvrd.containsKey(invLine.blng__Invoice__r.ID)){ 
                                              mapOfInvcIdTaxOvrd.put(invLine.blng__Invoice__r.ID,taxRoundOff); 
                                          }
                                          // Calculating Tax Rate value based on Rate of Tax Rate and Invoice Sub Total for the country India (cgst+sgst)
                                          else{
                                              mapOfInvcIdTaxOvrd.put(invLine.blng__Invoice__r.ID,(taxRoundOff + mapOfInvcIdTaxOvrd.get(invLine.blng__Invoice__r.ID)));
                                          } 
                                      }
                                      // Create Map to store Invoice record along with its Tax override value
                                      invc.ID = invLine.blng__Invoice__r.ID;
                                      invc.QTB_hasTieredLines__c = false;
                                      invc.QTB_Tax_Override_Amount__c = (mapOfInvcIdTaxOvrd.containsKey(invLine.blng__Invoice__r.ID)) ? (mapOfInvcIdTaxOvrd.get(invLine.blng__Invoice__r.ID)): 0;
                                      invc.QTB_Total_Tax_Rate__c = (invLine.blng__TaxPercentageApplied__c!= null) ? invLine.blng__TaxPercentageApplied__c : 0;
                                      mapOfInvcIdAndInvc.put(invc.ID,invc);
                                  }
                               else if(invLine.blng__LegalEntity__r.QTB_Tax_Applicability__c != QTB_Constants.LEGALENTITY_TYPE_FLAT){
                                   // Update QTB_Tax_Override_Amount__c on invoice line for Tax Type Product based Rate
                                   invoiceLine.ID = invLine.ID; 
                                   invc.QTB_hasTieredLines__c = false;
                                   invc.ID = invLine.blng__Invoice__r.ID;      
                                   invoiceLine.QTB_Tax_Override_Amount__c = (invLine.blng__TaxAmount__c!= null)? invLine.blng__TaxAmount__c : 0; //for product based tax override amount will be same as of tax amount
                                   invc.QTB_Total_Tax_Rate__c = (invLine.blng__TaxPercentageApplied__c!= null)? invLine.blng__TaxPercentageApplied__c: 0; //#28097 Added as part to stamp the Total Tax rate for Product Based same like Flat rate
                                   
                                   // Update Tax Override IN Invoice
                                   if(!mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__r.ID)){
                                       invc.QTB_Tax_Override_Amount__c = invLine?.blng__TaxAmount__c;
                                       mapOfInvcIdAndInvc.put(invc.ID,invc);
                                   }else{ 
                                       Decimal existingTaxOverride = (mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__r.ID) && mapOfInvcIdAndInvc.get(invLine.blng__Invoice__r.ID).QTB_Tax_Override_Amount__c != null) 
                                           ? (mapOfInvcIdAndInvc.get(invLine.blng__Invoice__r.Id).QTB_Tax_Override_Amount__c): 0.0;
                                       // Get the current line's tax, also defaulting to 0.0 if it's null.
                                       Decimal currentLineTax = (invLine.blng__TaxAmount__c != null) ? invLine.blng__TaxAmount__c : 0.0;
                                       // Calculate the new total by simply adding the two values.
                                       invc.QTB_Tax_Override_Amount__c = existingTaxOverride + currentLineTax;
                                       mapOfInvcIdAndInvc.put(invc.ID,invc);
                                   }
                                   listUpdateInvcLine.add(invoiceLine);    
                               }
                           }
                        else{  // when Tax Exempt on Account is Yes
                            // updating QTB_Tax_Override_Amount__c and QTB_Total_Tax_Rate__c to 0 at header level   
                            if(!mapOfInvcIdAndInvc.containsKey(invLine.blng__Invoice__r.ID)){
                                invc.ID = invLine.blng__Invoice__r.ID;
                                invc.QTB_hasTieredLines__c = false;
                                invc.QTB_Tax_Override_Amount__c = 0;
                                invc.QTB_Total_Tax_Rate__c = 0;
                                mapOfInvcIdAndInvc.put(invc.ID,invc);
                            }
                            // Updating QTB_Tax_Override_Amount__c to zeros on invoice line when Tax Type is Product based Rate
                            if(invoiceLine?.blng__LegalEntity__c!=null && invLine?.blng__LegalEntity__r?.QTB_Tax_Applicability__c.equalsIgnoreCase(QTB_Constants.LEGALENTITY_PRODUCT_BASED)){
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
                    
                    // updating tax override amount on invoice line
                    if(!listUpdateInvcLine.isEmpty()){
                        update listUpdateInvcLine;
                        listUpdateInvcLine.clear();
                    }
                    // updating tax override amount value on invoice header
                    if(!mapOfInvcIdAndInvc.isEmpty()){
                        update mapOfInvcIdAndInvc.values();
                        mapOfInvcIdAndInvc.clear();
                    }
                }
            }
        }
        catch (Exception e){
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
        system.debug('in finish');
        String errorIds = '';
        try {
            if (QTB_TaxOverrideAmountCalculationBatch.throwExplicitException){
                throw new NullPointerException();
            }
            
            //#33490 - updating invoice run complete to true, if all chunks got completed
            AsyncApexJob jobStatus = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId()];
            if (jobStatus.NumberOfErrors == 0) {
                // Success! All chunks completed without a batch-halting error.
                List<blng__InvoiceScheduler__c>invSchLst = new List<blng__InvoiceScheduler__c>();
                for(Id invs :invSchedulerId){
                    blng__InvoiceScheduler__c invSch = new blng__InvoiceScheduler__c(Id = invs,QTB_InvoiceRunCompleted__c  = true);
                    invSchLst.add(invSch);
                }
                // disabling the trigger to bypass the invoice scheduler validation error that Enter a Start Date Time equal to or later than today.: [blng__StartDateTime__c]
                sbqq.TriggerControl.disable();
                Update invSchLst;
                sbqq.TriggerControl.enable();
            }
        }
        catch (exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className);
        }
    }
}