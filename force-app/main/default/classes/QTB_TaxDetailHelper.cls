/*****************************************************************************************************
* Class       : QTB_TaxDetailHelper
* Test Class  : QTB_TaxDetailHelper_Test
* Author      : IRM/Virtusa
* Purpose     : This is a helper class for all business logic related to Tax Detail object
* Requirement: 
* Change History: 07/11/2025 
* Developer     Date          Description
* ------------------------------------------------------------------------------------------- 
* Parth       07/11/2025    
*******************************************************************************************************/
public class QTB_TaxDetailHelper {
    
    private static final String CLASSNAME = QTB_TaxDetailHelper.class.getName();

    /***********************************************************************************************************
    * Method : process
    * Description: Generic method to handle all operations on the Tax Detail Records
    **************************************************************************************************************/
    public static void process(List<QTB_Tax_Detail__c> taxDetailNewList, Map<Id,QTB_Tax_Detail__c> taxDetailOldMap, System.TriggerOperation operationType) { 
        
        Set<Id> invoiceLineIdSet = new Set<Id>();
        Set<Id> subInvoiceLineIdSet = new Set<Id>();
        Map<ID, QTB_Tax_Detail__c> finalUpdateTaxDetailMap = new Map<ID, QTB_Tax_Detail__c>();

        for(QTB_Tax_Detail__c taxDetail : taxDetailNewList) {
            SWITCH ON operationType {
                WHEN AFTER_UPDATE {
                    // #34408 - if tax override amount is changed, update standard tax amount
                    if (taxDetail.QTB_Legal_Entity_Country__c == 'Turkey' && taxDetailOldMap.containsKey(taxDetail.Id) &&
                        taxDetail.QTB_Tax_Override_Amount__c != taxDetailOldMap.get(taxDetail.Id).QTB_Tax_Override_Amount__c && 
                        QTB_RecursiveHandlerCheck.afterUpdate_calculateStdTaxOverrideAmt) 
                    {
                        // Add the relevant parent ID
                        if (taxDetail.QTB_Sub_Invoice_Line__c != null) {
                            subInvoiceLineIdSet.add(taxDetail.QTB_Sub_Invoice_Line__c);
                        } else if (taxDetail.QTB_Invoice_Line__c != null) {
                            invoiceLineIdSet.add(taxDetail.QTB_Invoice_Line__c);
                        }
                    }
                }
                WHEN AFTER_INSERT {
                    // #34408 - On any new tax detail insert for Turkey, we must trigger
                    // a recalculation for that parent/sub-parent.
                    if (taxDetail.QTB_Legal_Entity_Country__c == 'Turkey') {
                        if (taxDetail.QTB_Sub_Invoice_Line__c != null) {
                            subInvoiceLineIdSet.add(taxDetail.QTB_Sub_Invoice_Line__c);
                        } else if (taxDetail.QTB_Invoice_Line__c != null) {
                            invoiceLineIdSet.add(taxDetail.QTB_Invoice_Line__c);
                        }
                    }
                }
            }
        }
        
        if (!invoiceLineIdSet.isEmpty() || !subInvoiceLineIdSet.isEmpty()) {
            
            List<QTB_Tax_Detail__c> taxDetailToUpdate = calculateStdTaxOverrideAmt(invoiceLineIdSet, subInvoiceLineIdSet);
            if (taxDetailToUpdate != null && !taxDetailToUpdate.isEmpty()) {
                for (QTB_Tax_Detail__c td : taxDetailToUpdate) {
                    // Use the map to handle potential duplicates from different events
                    if (!finalUpdateTaxDetailMap.containsKey(td.Id)) {
                        finalUpdateTaxDetailMap.put(td.Id, td);
                    } else {
                        // If already in map, just update the field
                        finalUpdateTaxDetailMap.get(td.Id).QTB_Standard_Tax_Override_Amount__c = td.QTB_Standard_Tax_Override_Amount__c;
                    }
                }
            }
            // Clear sets after use
            invoiceLineIdSet.clear();
            subInvoiceLineIdSet.clear();
        }

        // --- DML OPERATION ---
        if (!finalUpdateTaxDetailMap.isEmpty()) {
            try {
                update finalUpdateTaxDetailMap.values();
                QTB_RecursiveHandlerCheck.afterUpdate_calculateStdTaxOverrideAmt = false;
            } catch (Exception e) {
                // Handle DML exception if necessary
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
                throw e; // Re-throw to signal trigger failure
            }
        }
    }

    /***********************************************************************************************************
    * Method : calculateStdTaxOverrideAmt (REFATORED)
    * Description: Calculates sums for non-withholding records and applies them to
    * sibling withholding records, separating logic for Invoice Lines
    * and Sub Invoice Lines.
    ************************************************************************************************************/
    public static List<QTB_Tax_Detail__c> calculateStdTaxOverrideAmt(Set<Id> invoiceLineIdSet, Set<Id> subInvoiceLineIdSet) {
        try {
            if (QTB_TaxDetailTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            
            // Map for sums related to Invoice Lines
            Map<Id, Decimal> sumByInvoiceLineId = new Map<Id, Decimal>();
            // Map for sums related to Sub Invoice Lines
            Map<Id, Decimal> sumBySubInvoiceLineId = new Map<Id, Decimal>();
            
            // This list will hold only the 'WithHolding' records we need to update.
            List<QTB_Tax_Detail__c> withholdingRecords = new List<QTB_Tax_Detail__c>();

            // Exit early if no IDs were passed
            if ((invoiceLineIdSet == null || invoiceLineIdSet.isEmpty()) && 
                (subInvoiceLineIdSet == null || subInvoiceLineIdSet.isEmpty())) {
                return null; // Nothing to process
            }
            
            // Loop through all results to aggregate sums and separate withholding records.
            for (QTB_Tax_Detail__c taxDetail : [SELECT Id, QTB_Invoice_Line__c, QTB_Sub_Invoice_Line__c, QTB_Tax_Category__c, 
                       							QTB_Tax_Override_Amount__c, QTB_Standard_Tax_Override_Amount__c FROM QTB_Tax_Detail__c 
               									WHERE (QTB_Invoice_Line__c IN :invoiceLineIdSet and QTB_Sub_Invoice_Line__c = null) OR QTB_Sub_Invoice_Line__c IN :subInvoiceLineIdSet]) 
            {
                // Get the override amount, handling nulls.
                Decimal overrideAmt = (taxDetail.QTB_Tax_Override_Amount__c == null) ? 0 : taxDetail.QTB_Tax_Override_Amount__c;

                if (taxDetail.QTB_Tax_Category__c == 'WithHolding Tax Rate') {
                    //If this is a withholding record, add it to list for later processing.
                    withholdingRecords.add(taxDetail);
                
                } else if (taxDetail.QTB_Sub_Invoice_Line__c != null) {
                    // This is a NON-withholding record for a SUB INVOICE LINE.
                    Decimal currentSum = sumBySubInvoiceLineId.ContainsKey(taxDetail.QTB_Sub_Invoice_Line__c) ? sumBySubInvoiceLineId.get(taxDetail.QTB_Sub_Invoice_Line__c) : 0 ;
                    sumBySubInvoiceLineId.put(taxDetail.QTB_Sub_Invoice_Line__c, currentSum + overrideAmt);

                } else if (taxDetail.QTB_Invoice_Line__c != null) {
                    // This is a NON-withholding record for a INVOICE LINE.
                    Id lineId = taxDetail.QTB_Invoice_Line__c;
                    Decimal currentSum = sumByInvoiceLineId.ContainsKey(taxDetail.QTB_Invoice_Line__c) ? sumByInvoiceLineId.get(lineId) : 0;
                    sumByInvoiceLineId.put(taxDetail.QTB_Invoice_Line__c, currentSum + overrideAmt);
                }
            }
            // loop through the 'WithHolding' records and update them with the correct sums.
            for (QTB_Tax_Detail__c whRecord : withholdingRecords)
            {
                if (whRecord.QTB_Sub_Invoice_Line__c != null) {
                    // This is a SUB INVOICE LINE withholding record.
                    // Get the final calculated sum for this sub-line. Default to 0.
                    Decimal newSum = sumBySubInvoiceLineId.containsKey(whRecord.QTB_Sub_Invoice_Line__c) ? sumBySubInvoiceLineId.get(whRecord.QTB_Sub_Invoice_Line__c) : 0;
                    whRecord.QTB_Standard_Tax_Override_Amount__c = newSum;

                } else if (whRecord.QTB_Invoice_Line__c != null) {
                    // This is a INVOICE LINE withholding record.
                    // Get the final calculated sum for this parent-line. Default to 0.
                    Decimal newSum = sumByInvoiceLineId.containsKey(whRecord.QTB_Invoice_Line__c) ? sumByInvoiceLineId.get(whRecord.QTB_Invoice_Line__c) : 0;
                    whRecord.QTB_Standard_Tax_Override_Amount__c = newSum;
                }
            }
            
            // Return the list of withholding records prepared for an update.
            return withholdingRecords.isEmpty() ? null : withholdingRecords;

        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
}