/*****************************************************************************************************
 * Class         : QTB_IRMVertexResponseUtil 
 * Test Class    : QTB_IRMToVertex_Test
 * Purpose       : This is a Response Util Class used for parsing Vertex response and storing value in salesforce
 * Requirement   : Gitlab #
 * Author        : IRM/Virtusa
 * Developer     : Gopi/Shailesh
 * Change History: 07/07/2021
 * Developer       Date            Description 
 * ------------------------------------------------------------------------------------------- 
 * IRM/Virtusa       07/07/2021       Gitlab #857, Vertex Integration
 * Virtusa           12/16/2021       Gitlab #6056 Vertex Tax Integration for Posted Invoice
 * TCS               19/01/2024       Gitlab #21048 Grouping of Tax Details as per the JurisdictionLevel
 *******************************************************************************************************/
public with sharing class QTB_IRMVertexResponseUtil {
    public static List < blng__Invoice__c > invoiceListFinal = new List < blng__Invoice__c > ();
    public static List < blng__InvoiceLine__c > invoiceLineListFinal = new List < blng__InvoiceLine__c > ();
    public static List < blng__Usage__c > usageListFinal = new List < blng__Usage__c > ();
    public static List < blng__UsageSummary__c > usgSummaryList = new List < blng__UsageSummary__c > ();
    public static Map < id, decimal > usageIdTaxValueMap = new Map < id, decimal > ();
    public static List < blng__CreditNote__c > creditNoteListFinal = new List < blng__CreditNote__c > ();
    public static List < blng__CreditNoteLine__c > creditNoteLineListFinal = new List < blng__CreditNoteLine__c > ();
    public static List < Id > creditNoteLinesIdListFinal = new List < Id > ();
    public static map < id, decimal > usageIdUsageTaxAmountMap = new map < id, decimal > ();
    public static set < id > currentInvliceLineIds = new set < id > ();
    public static string RecurringLines = 'Recurring';
    public static List < QTB_Tax_Detail__c > TaxDetailList = new List < QTB_Tax_Detail__c > ();
    public static List < QTB_Tax_Detail__c > TaxDetailListFinal = new List < QTB_Tax_Detail__c > ();
    public static Map < Id, Id > usagToUsageSummaryId = new Map < Id, Id > ();
    public static Map < Id, Id > creditNoteLineWithInvoiceLineIdMap = new Map < Id, Id > ();
    public static string CurrencyCode = '';
    public static boolean isPosted = false;
    public static Set < Id > creditNoteAccountIds = new Set < Id > ();
    public static map < id, decimal > objectIdWithTotalTaxMap = new map < id, decimal > ();

    //Map to store the InvoiceLine/CreditNoteLine/Usage Tax Detail group by JurisdictionLevel, KEY => LineId+JurisdictionLevel VALUE => Tax Detail Record
    public static Map < String, QTB_Tax_Detail__c > lineJurLevelTaxDetail = new Map < String, QTB_Tax_Detail__c > ();

    /*********************************************************************************************************
     * Method Name: responseMapping
     * Parameters:  null
     * Return Type: void
     * Requirement: Gitlab #
     * Description: This method will make REST request to vertex to get Authorization Code 
     **********************************************************************************************************/
    public static void responseMapping(string responseBody, boolean checkLastBatchChunk) {
        try {
            id invoiceId;
            Dom.Document doc = new Dom.Document();
            doc.load(responseBody);
            Dom.XMLNode root = doc.getRootElement();
            for (Dom.XmlNode invoiceNode: root.getChildElements()) {
                for (Dom.XmlNode invoiceChildNode: invoiceNode.getChildElements()) {
                    for (Dom.XmlNode invoiceChildNode1: invoiceChildNode.getChildElements()) {
                        if (invoiceChildNode1.getName() == 'InvoiceResponse' || invoiceChildNode1.getName() == 'QuotationResponse') {
                            invoiceId = invoiceChildNode1.getAttribute('transactionId', null);
                            isPosted = invoiceChildNode1.getName() == 'InvoiceResponse' ? true : false;
                            //to handle invoiceOrCreditNote response
                            readInvoiceResponse(invoiceChildNode1);
                        }
                    }
                }
            }

            //check if the trasaction is for Invoice or Credit Note
            boolean isInvoiceUpdate = invoiceId.getSobjectType() == blng__Invoice__c.getSObjectType() ? true : false;
            //Update Credit Note Line every time by summing up the Usages
            if (!isInvoiceUpdate) {
                if (usageListFinal.size() > 0 || creditNoteLineListFinal.size() > 0) {
                    Map < id, id > invoiceLineToCreditNoteId = new Map < id, id > ();
                    Map < id, id > creditNoteLineToInvoiceLineId = new Map < id, id > ();
                    Map < id, List < blng__CreditNoteLine__c >> usageSummaryCreditNoteLineListMap = new Map < id, List < blng__CreditNoteLine__c >> ();
                    Map < id, id > creditNoteLineToUsageSummary = new Map < id, id > ();
                    Map < id, id > usageSummaryCreditNoteLineMap = new Map < id, id > ();
                    Map < id, id > usageSummaryInvoiceLineMap = new Map < id, id > ();
                    //Get all the credit Note Line and Invoice Line
                    List < blng__CreditNoteLine__c > creditNoteLineList = [Select id, Name, blng__CreditNote__c, blng__TaxAmount__c, QTB_Tax_Override_Amount__c, blng__CreditNote__r.Id, CurrencyIsoCode,
                        blng__TotalAmount__c, blng__Subtotal__c, blng__TaxErrorMessage__c, blng__InvoiceLine__r.QTB_Charge_Type__c,
                        blng__InvoiceLine__c, blng__InvoiceLine__r.blng__TaxAmount__c, blng__InvoiceLine__r.QTB_Tax_Override_Amount__c, blng__InvoiceLine__r.blng__UsageSummary__c,
                        blng__InvoiceLine__r.blng__UsageSummary__r.id, blng__InvoiceLine__r.QTB_HasConsumptionSchedule__c,
                        blng__InvoiceLine__r.blng__Subtotal__c, blng__InvoiceLine__r.QTB_Taxable_Amount__c, blng__CreditNote__r.blng__TaxErrorMessage__c
                        From blng__CreditNoteLine__c
                        where blng__CreditNote__c =: invoiceId
                    ];
                    for (blng__CreditNoteLine__c creditLine: creditNoteLineList) {
                        //Git US#15519, in map creditNoteLineWithInvoiceLineIdMap-- storing the creditNoteLineId with InvoiceLineId
                        creditNoteLineWithInvoiceLineIdMap.put(creditLine.Id, creditLine.blng__InvoiceLine__c);
                        System.debug('creditNoteLineWithInvoiceLineIdMap@@' + creditNoteLineWithInvoiceLineIdMap);
                        invoiceLineToCreditNoteId.put(creditLine.blng__InvoiceLine__c, creditLine.blng__CreditNote__c);
                        creditNoteLineToInvoiceLineId.put(creditLine.blng__CreditNote__c, creditLine.blng__InvoiceLine__c);
                        //Check consumption schedule
                        //Credit Note Id -> List Non Recurring CeditNoteLines
                        if (creditLine.blng__InvoiceLine__r.blng__UsageSummary__c != null) {
                            if (usageSummaryCreditNoteLineListMap.containsKey(creditLine.blng__InvoiceLine__r.blng__UsageSummary__c)) {
                                usageSummaryCreditNoteLineListMap.get(creditLine.blng__InvoiceLine__r.blng__UsageSummary__c).add(creditLine);
                            } else {
                                usageSummaryCreditNoteLineListMap.put(creditLine.blng__InvoiceLine__r.blng__UsageSummary__c, new List < blng__CreditNoteLine__c > {
                                    creditLine
                                });
                            }
                            // usageSummaryCreditNoteLineMap.put(creditLine.blng__InvoiceLine__r.blng__UsageSummary__c,creditLine);
                            creditNoteLineToUsageSummary.put(creditLine.id, creditLine.blng__InvoiceLine__r.blng__UsageSummary__c);
                        }
                    }
                    //Get if there is any error message in invoice
                    string creditNoteErrorMsg = creditNoteLineList[0].blng__CreditNote__r.blng__TaxErrorMessage__c;
                    CurrencyCode = creditNoteLineList[0].CurrencyIsoCode;
                    map < id, decimal > usageSummaryIdTotalUsageTaxMap = new map < id, decimal > ();
                    List < blng__Usage__c > usageList = [Select id, Name, blng__Subtotal__c, blng__UsageSummary__c
                        From blng__Usage__c
                        where Id IN: usageIdUsageTaxAmountMap.KeySet()
                    ];
                    system.debug('Credit CHeck3' + usageList.size());

                    //Credit Note Id -> List Usages
                    for (blng__Usage__c usg: usageList) {
                        //For Tax Details creation, setting usage with usageSummaryValye
                        usagToUsageSummaryId.put(usg.id, usg.blng__UsageSummary__c);
                        //put usage Summary wise Total  tax
                        if (usageSummaryIdTotalUsageTaxMap.containskey(usg.blng__UsageSummary__c)) {
                            usageSummaryIdTotalUsageTaxMap.put(usg.blng__UsageSummary__c, usageSummaryIdTotalUsageTaxMap.get(usg.blng__UsageSummary__c) + usageIdUsageTaxAmountMap.get(usg.id));
                        } else {
                            usageSummaryIdTotalUsageTaxMap.put(usg.blng__UsageSummary__c, usageIdUsageTaxAmountMap.get(usg.id));
                        }
                    }
                    Map < id, Decimal > UsIdWithcreditNoteLinePercentMap = new Map < id, Decimal > ();
                    for (Id usSumId: usageSummaryCreditNoteLineListMap.keyset()) {
                        decimal temp = 0.0;
                        for (blng__CreditNoteLine__c c: usageSummaryCreditNoteLineListMap.get(usSumId)) {
                            temp = temp + c.blng__Subtotal__c;
                            UsIdWithcreditNoteLinePercentMap.put(usSumId, temp); // usageSummaryId with TotalCreditNoteLineAmount for respective usageSummary
                        }
                    }
                    Map < Id, Decimal > utilizationPercentMap = new Map < Id, Decimal > ();
                    for (Id us: usageSummaryCreditNoteLineListMap.keyset()) {
                        decimal temp1 = 0;
                        for (blng__CreditNoteLine__c c: usageSummaryCreditNoteLineListMap.get(us)) {
                            if (UsIdWithcreditNoteLinePercentMap.get(us)  != null && c.blng__Subtotal__c !=0 ) { // GITLAB #22532. GITLAB US#24005 divide by 0 issue fixed
                                temp1 = c.blng__Subtotal__c / UsIdWithcreditNoteLinePercentMap.get(us);
                            }
                            utilizationPercentMap.put(c.id, temp1); // cnl1 -- 16%,  cnl2 --83%
                        }
                    }

                    if (usageSummaryIdTotalUsageTaxMap != null) {
                        for (id usgId: usageSummaryIdTotalUsageTaxMap.keySet()) {
                            for (blng__CreditNoteLine__c c: usageSummaryCreditNoteLineListMap.get(usgId)) {
                                //For Tax Details storing -- UsageSummary to creditNOteLine Id value in map
                                usageSummaryCreditNoteLineMap.put(usgId, c.id);
                                usageSummaryInvoiceLineMap.put(usgId, c.blng__InvoiceLine__c);
                                blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
                                cnl.id = c.id;
                                cnl.blng__TaxAmount__c = -1 * (usageSummaryIdTotalUsageTaxMap.get(usgId) * utilizationPercentMap.get(c.id));
                                //Update QTB_Tax_Override_Amount__c Credit Note Line #21202
                                cnl.QTB_Tax_Override_Amount__c = -1 * (usageSummaryIdTotalUsageTaxMap.get(usgId) * utilizationPercentMap.get(c.id));
                                cnl.blng__TaxErrorMessage__c = '';
                                creditNoteLineListFinal.add(cnl);
                            }
                        }
                    }
                    //Update blng__CreditNote__c if any previous error message is there
                    blng__CreditNote__c cn = new blng__CreditNote__c();
                    cn.id = invoiceId;
                    if (isPosted) { //Success scenario -- Posted CreditNote
                        cn.blng__TaxErrorMessage__c = '';
                        cn.recordTypeId = QTB_Utils.CREDITNOTE_POSTED_RECTYPEID; //setting record type as posted. 
                        String result = blng.CreditNoteAPI.postTaxForCreditNote(cn.Id);
                        creditNoteListFinal.add(cn);
                    } else { //Success scenario -- Draft CreditNote
                        cn.blng__TaxErrorMessage__c = '';
                        creditNoteListFinal.add(cn);
                    }
                    System.debug('TaxDetailList@@' + TaxDetailList);
                    for (QTB_Tax_Detail__c taxD: TaxDetailList) {
                        System.debug('TaxDetailList_taxD@@' + taxD);
                        if (usagToUsageSummaryId.containsKey(taxD.QTB_Usage__c)) {
                            //Commenting the below line as per GITLAB - #17237 (Remove Invoice Line Reference)
                            //taxD.QTB_Invoice_Line__c = usageSummaryInvoiceLineMap.get(usagToUsageSummaryId.get(taxD.QTB_Usage__c));
                            taxD.QTB_Credit_Note_Line__c = usageSummaryCreditNoteLineMap.get(usagToUsageSummaryId.get(taxD.QTB_Usage__c));
                            taxD.CurrencyIsoCode = CurrencyCode;
                            System.debug('taxD_usage@@' + taxD);
                            TaxDetailListFinal.add(taxD);
                        }
                    }
                }
                //If no line present, then simply making the credit note as posted
                else {
                    if (isPosted) {
                        //Update blng__CreditNote__c if any previous error message is there
                        blng__CreditNote__c cnt = new blng__CreditNote__c();
                        cnt.id = invoiceId;
                        cnt.blng__TaxErrorMessage__c = '';
                        cnt.recordTypeId = QTB_Utils.CREDITNOTE_POSTED_RECTYPEID; //setting record type as posted. 
                        //cnt.blng__Status__c = 'Posted';
                        String result = blng.CreditNoteAPI.postTaxForCreditNote(invoiceId);
                        creditNoteListFinal.add(cnt);
                    }
                }
            }

            //Current/everytime transaction usage // Only update Usages if it's not a Credit Note
            if (usageListFinal.size() > 0 && isInvoiceUpdate) {
                update usageListFinal;
            }
            //Last chunk update
            if (checkLastBatchChunk && isInvoiceUpdate) {
                List < blng__Invoice__c > updateInvoice = new List < blng__Invoice__c > ();
                //Get all the Invoice line for the current Invoice
                if (usageListFinal.size() > 0 || invoiceLineListFinal.size() > 0) {
                    //Query for invoiceLineItems related to invoice
                    List < blng__InvoiceLine__c > invoiceLineItems = new List < blng__InvoiceLine__c > ();
                    Map < id, decimal > usageSummaryToatlMap = new Map < id, decimal > ();
                    Map < id, string > usageSummaryIfError = new Map < id, string > ();
                    Map < id, id > usageSummaryinvoiceLineMap = new Map < id, id > ();

                    //Get only non recurring lines
                    // As per GITLAB #17949  commented blng__TaxRule__r.Name !='No Tax Rule to fix List index out of bounds exception                  
                    invoiceLineItems = [select id, blng__UsageSummary__c, blng__TaxErrorMessage__c, blng__Product__c, blng__UnitPrice__c, blng__Subtotal__c,
                        QTB_Charge_Type__c, QTB_HasConsumptionSchedule__c, blng__Invoice__r.blng__TaxErrorMessage__c, blng__TaxRule__r.Name, CurrencyIsoCode,
                        blng__Invoice__r.QTB_Parent_Invoice__c, blng__Invoice__c, blng__Invoice__r.Name, blng__Invoice__r.QTB_Parent_Invoice__r.Name
                        from blng__InvoiceLine__c
                        where blng__Invoice__c =: invoiceId /*AND blng__TaxRule__r.Name !='No Tax Rule'*/
                    ];

                    set < string > usageSummaries = new set < string > ();
                    List < blng__InvoiceLine__c > recurringInvoiceLine = new List < blng__InvoiceLine__c > ();
                    decimal TotalCalculatedAmount = 0;
                    boolean prevousChunkError = false;
                    string invoiceErrorMsg = '';
                    CurrencyCode = invoiceLineItems[0].CurrencyIsoCode;
                    if (invoiceLineItems.size() > 0 && invoiceLineItems != null) {
                        for (blng__InvoiceLine__c invLin: invoiceLineItems) {
                            if (!invLin.QTB_Charge_Type__c.equals(RecurringLines)) {
                                usageSummaries.add(invLin.blng__UsageSummary__c);
                                usageSummaryinvoiceLineMap.put(invLin.blng__UsageSummary__c, invLin.id);
                                System.debug('usageSummaryinvoiceLineMap@@' + usageSummaryinvoiceLineMap);
                            } else {
                                //Check if any error for recurring invoice line for existing/ previous chunk
                                if (invLin.blng__TaxErrorMessage__c != null && !currentInvliceLineIds.contains(invLin.id)) {
                                    prevousChunkError = true;
                                    break;
                                }
                            }
                        }
                        //Get if there is any error message in invoice
                        invoiceErrorMsg = invoiceLineItems[0].blng__Invoice__r.blng__TaxErrorMessage__c;
                    }
                    //if No error in Invoice Line
                    if (!usageSummaries.isEmpty() && !prevousChunkError) {
                        // remove blanks and nulls
                        usageSummaries.remove('');
                        usageSummaries.remove(null);
                        //Get all the usages
                        for (blng__Usage__c usgS: [Select QTB_Rated_Amount__c, QTB_TaxErrorMessage__c, blng__PreratedAmount__c, QTB_Rated_Unit_Price__c,
                                QTB_TaxAmount__c, blng__UsageSummary__r.blng__UnitPrice__c
                                from blng__Usage__c
                                where blng__UsageSummary__c in: usageSummaries
                            ]) {
                            //If Error message is there
                            if (usgS.QTB_TaxErrorMessage__c != null) {
                                prevousChunkError = true;
                                break;
                            } else {
                                usagToUsageSummaryId.put(usgS.id, usgS.blng__UsageSummary__c);
                                System.debug('usagToUsageSummaryId@@' + usagToUsageSummaryId);
                                if (usageSummaryToatlMap.containsKey(usgS.blng__UsageSummary__c)) {
                                    usageSummaryToatlMap.put(usgS.blng__UsageSummary__c, usageSummaryToatlMap.get(usgS.blng__UsageSummary__c) + usgS.QTB_TaxAmount__c);
                                } else {
                                    usageSummaryToatlMap.put(usgS.blng__UsageSummary__c, usgS.QTB_TaxAmount__c);
                                }
                            }
                        }
                        //No previous Error in usage
                        if (!prevousChunkError) {
                            //Success Update
                            //Update the Usage Summary Level tax value      
                            System.debug('usageSummaryToatlMap@@' + usageSummaryToatlMap);
                            for (id usgSummaryId: usageSummaryToatlMap.keySet()) {
                                System.debug('usgSummaryId@@' + usgSummaryId);
                                //UsageSummary Update
                                blng__UsageSummary__c uSumm = new blng__UsageSummary__c();
                                uSumm.id = usgSummaryId;
                                uSumm.QTB_TaxAmount__c = usageSummaryToatlMap.get(usgSummaryId);
                                uSumm.QTB_TaxErrorMessage__c = '';
                                usgSummaryList.add(uSumm);
                                //InvoiceLine Update
                                blng__InvoiceLine__c iLine = new blng__InvoiceLine__c();
                                iLine.id = usageSummaryinvoiceLineMap.get(usgSummaryId);
                                iLine.blng__TaxAmount__c = usageSummaryToatlMap.get(usgSummaryId);
                                //Update QTB_Tax_Override_Amount__c Invoice Line #21202
                                iLine.QTB_Tax_Override_Amount__c = usageSummaryToatlMap.get(usgSummaryId);
                                iLine.blng__TaxStatus__c = 'Completed';
                                iLine.blng__TaxErrorMessage__c = '';
                                invoiceLineListFinal.add(iLine);
                                //Order Product Update // Pending

                            }
                            //Update Invoice if any previous error message is there
                            if (invoiceErrorMsg != null && invoiceErrorMsg != '') {
                                blng__Invoice__c inv = new blng__Invoice__c();
                                inv.id = invoiceId;
                                inv.blng__TaxErrorMessage__c = '';
                                inv.blng__TaxStatus__c = 'Completed';
                                updateInvoice.add(inv);
                            }
                            System.debug('TaxDetailList@@' + TaxDetailList);
                            for (QTB_Tax_Detail__c taxD: TaxDetailList) {
                                if (usagToUsageSummaryId.containsKey(taxD.QTB_Usage__c)) {
                                    taxD.QTB_Invoice_Line__c = usageSummaryinvoiceLineMap.get(usagToUsageSummaryId.get(taxD.QTB_Usage__c));
                                    taxD.CurrencyIsoCode = CurrencyCode;
                                    System.debug('taxD@@' + taxD);
                                    TaxDetailListFinal.add(taxD);
                                }
                            }
                        }
                    }
                }

                //DML Operation only for Invoice// Only last trasaction we want to update
                if (usgSummaryList.size() > 0) {
                    update usgSummaryList;
                }
                //DML for Invoice
                if (updateInvoice.size() > 0) {
                    update updateInvoice;
                }
            }

            // DML Opertaion for Invoice Line // Non recurring
            if (!isPosted && invoiceLineListFinal.size() > 0) {
                update invoiceLineListFinal;
            }
            // DML Operation for Credit Note Line // Non recurring
            if (creditNoteLineListFinal.size() > 0) {
                update creditNoteLineListFinal;
            }

            //DML operation of CreditNote
            if (creditNoteListFinal.size() > 0) {
                update creditNoteListFinal;
            }

            //DML for TaxDetails
            if (TaxDetailListFinal.size() > 0) {
                //deleting existing tax details.
                deleteExistingTaxDetails(invoiceId, isInvoiceUpdate);
                //Git US#15519 --Setting the QTB_Invoice_Line__c on tax detail if its missing in CreditNoteLine scenario,
                //as QTB_Invoice_Line__c is mandatory while inserting the taxDetail record.
                for (QTB_Tax_Detail__c taxD: TaxDetailListFinal) {
                    //Commenting the below line as per GITLAB - #17237  (Remove Invoice Line Reference)
                    /* if(taxD.QTB_Invoice_Line__c == null && taxD.QTB_Credit_Note_Line__c !=null && taxD.QTB_Usage__c == null &&
                       !creditNoteLineWithInvoiceLineIdMap.isEmpty() && creditNoteLineWithInvoiceLineIdMap.containsKey(taxD.QTB_Credit_Note_Line__c)){
                           //taxD.QTB_Invoice_Line__c = creditNoteLineWithInvoiceLineIdMap.get(taxD.QTB_Credit_Note_Line__c);
                           //taxD.CurrencyIsoCode = CurrencyCode;
                           System.debug('taxD_recurring@@'+taxD);                       
                       } 
          */

                    // GIT US #17238 created objectIdWithTotalTaxMap Map and used to Update the Total Tax and Calculated Tax in the Tax Detail Object when calling Vertex
                    if (!objectIdWithTotalTaxMap.isEmpty()) {
                        if (objectIdWithTotalTaxMap.containskey(taxD.QTB_Invoice_Line__c)) {
                            taxD.QTB_CalculatedTax__c = objectIdWithTotalTaxMap.get(taxD.QTB_Invoice_Line__c);
                        } else if (objectIdWithTotalTaxMap.containskey(taxD.QTB_Usage__c)) {
                            if (objectIdWithTotalTaxMap.get(taxD.QTB_Usage__c) >= 0) {
                                taxD.QTB_CalculatedTax__c = objectIdWithTotalTaxMap.get(taxD.QTB_Usage__c);
                            } else {
                                taxD.QTB_CalculatedTax__c = (-1) * objectIdWithTotalTaxMap.get(taxD.QTB_Usage__c);
                            }
                            system.debug('Here 366 ' + taxD.QTB_CalculatedTax__c);
                        } else if (objectIdWithTotalTaxMap.containskey(taxD.QTB_Credit_Note_Line__c)) {
                            //taxD.QTB_CalculatedTax__c = objectIdWithTotalTaxMap.get(taxD.QTB_Credit_Note_Line__c);
                            if (objectIdWithTotalTaxMap.get(taxD.QTB_Credit_Note_Line__c) >= 0) {
                                taxD.QTB_CalculatedTax__c = objectIdWithTotalTaxMap.get(taxD.QTB_Credit_Note_Line__c);
                            } else {
                                taxD.QTB_CalculatedTax__c = (-1) * objectIdWithTotalTaxMap.get(taxD.QTB_Credit_Note_Line__c);
                            }
                            system.debug('Here 376 ' + taxD.QTB_CalculatedTax__c);
                        }
                    }
                }
                System.debug('TaxDetailListFinal.size()@@' + TaxDetailListFinal.size());
                System.debug('TaxDetailListFinal@@' + TaxDetailListFinal);
                insert TaxDetailListFinal;
            }
        } catch (Exception e) {
            System.debug('QTB_IRMVertexResponseUtil.responseMapping@@');
            System.debug('e.getLineNumber()@@' + e.getLineNumber());
            System.debug('e.getMessage()@@' + e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexResponseUtil.responseMapping');
        }
    }
    
    /*********************************************************************************************************
     * Method Name: deleteExistingTaxDetails
     * Parameters:  Id InvoiceOrCreditNoteId, boolean isInvoiceUpdate
     * Return Type: void
     * Requirement: Gitlab #
     * Description: This method is used to delete existing TaxDetail record
     **********************************************************************************************************/
    public static void deleteExistingTaxDetails(Id InvoiceOrCreditNoteId, boolean isInvoiceUpdate) {
        List<QTB_Tax_Detail__c> taxDetailList = new List<QTB_Tax_Detail__c>();
        if (isInvoiceUpdate) {
            taxDetailList = [Select Id, QTB_Invoice__c,OwnerId From QTB_Tax_Detail__c where QTB_Invoice__c =: InvoiceOrCreditNoteId];
        } else {
            taxDetailList = [Select Id, QTB_Invoice__c,QTB_Credit_Note__c,OwnerId From QTB_Tax_Detail__c where QTB_Credit_Note__c =: InvoiceOrCreditNoteId];
        }

        if (!taxDetailList.isEmpty()) {
            //Defect Fix Gitlab US #22132 -- If other user trying to delete the taxDetail record then getting the exception
            //To fix this defect, before deleting the taxDetail record changing the record owner
            List<QTB_Tax_Detail__c> updateTaxDetailList = new List<QTB_Tax_Detail__c>();
            for(QTB_Tax_Detail__c taxDetail : taxDetailList){
                //Checking tax detail ownerId and logged-in userId is matching or not
                if(taxDetail.OwnerId != System.UserInfo.getUserId()){
                    QTB_Tax_Detail__c taxDetailObj = new QTB_Tax_Detail__c();
                    taxDetailObj.Id = taxDetail.Id;
                    taxDetailObj.OwnerId = System.UserInfo.getUserId();
                    updateTaxDetailList.add(taxDetailObj);
                }
            }
            if(!updateTaxDetailList.isEmpty()){
                update updateTaxDetailList;
                updateTaxDetailList.clear();
            }
            delete taxDetailList;
        }
    }

    /*********************************************************************************************************
     * Method Name: readInvoiceResponse
     * Parameters:  Dom.XmlNode invoiceChildNode1
     * Return Type: void
     * Requirement: Gitlab #
     * Description: This method is used for reading value from response
     **********************************************************************************************************/
    public static void readInvoiceResponse(Dom.XmlNode invoiceChildNode1) {
        try {
            Id InvoiceOrCreditNoteId = invoiceChildNode1.getAttribute('transactionId', null);
            for (Dom.XmlNode invoiceResp: invoiceChildNode1.getChildElements()) {
                if (invoiceResp.getName() == 'LineItem') {
                    Id objectId = invoiceResp.getAttribute('lineItemId', null);

                    //Based on ObjectId sObjectType, performing operation for either Invoiceline level or Usage level
                    //Usage
                    if (objectId.getSobjectType() == blng__Usage__c.getSObjectType()) {
                        blng__Usage__c usage = new blng__Usage__c();

                        usage.id = objectId;
                        System.debug('usage@@' + usage.id);
                        for (Dom.XmlNode usageChildNode: invoiceResp.getChildElements()) {
                            QTB_Tax_Detail__c TaxDetail = new QTB_Tax_Detail__c();
                            if (usageChildNode.getName() == 'Taxes') {
                                System.debug('Taxes_Usages@@');
                                TaxDetail = addTaxDetail(usageChildNode, 'Usage', objectId, TaxDetail, InvoiceOrCreditNoteId);
                                //TaxDetailList.add(TaxDetail);
                            }
                            if (usageChildNode.getName() == 'TotalTax') {
                                System.debug('Total Usage Tax@@' + usageChildNode.getText());
                                usage.QTB_TaxAmount__c = Decimal.valueOf(usageChildNode.getText());
                                system.debug('usage.QTB_TaxAmount__c@@' + usage.QTB_TaxAmount__c);
                                objectIdWithTotalTaxMap.put(objectId, usage.QTB_TaxAmount__c);
                                usageIdUsageTaxAmountMap.put(objectId, usage.QTB_TaxAmount__c);
                                if (usage.QTB_TaxAmount__c != null) {
                                    usage.QTB_TaxErrorMessage__c = '';
                                }
                            }
                        }
                        TaxDetailList.addAll(lineJurLevelTaxDetail.values());
                        System.debug('TaxDetailList>>' + TaxDetailList);
                        System.debug('lineJurLevelTaxDetail>>' + lineJurLevelTaxDetail);
                        lineJurLevelTaxDetail.clear();
                        usageListFinal.add(usage);
                    }
                    //Invoice line
                    else if (objectId.getSobjectType() == blng__InvoiceLine__c.getSObjectType()) {
                        blng__InvoiceLine__c ivl = new blng__InvoiceLine__c();
                        ivl.id = objectId;
                        System.debug('InvoiceLineId@@' + ivl.id);
                        for (Dom.XmlNode invoiceChildNode: invoiceResp.getChildElements()) {
                            QTB_Tax_Detail__c TaxDetail = new QTB_Tax_Detail__c();
                            if (invoiceChildNode.getName() == 'Taxes') {
                                System.debug('Taxes_InvoiceLines@@');
                                TaxDetail = addTaxDetail(invoiceChildNode, 'InvoiceLine', objectId, TaxDetail, InvoiceOrCreditNoteId);

                            }
                            if (invoiceChildNode.getName() == 'TotalTax') {
                                System.debug('TotalinvoiceLineTax@@' + invoiceChildNode.getText());
                                ivl.blng__TaxAmount__c = Decimal.valueOf(invoiceChildNode.getText());
                                //Update QTB_Tax_Override_Amount__c Invoice Line #21202
                                ivl.QTB_Tax_Override_Amount__c = Decimal.valueOf(invoiceChildNode.getText());
                                system.debug('ivl.QTB_Tax_Override_Amount__c@@' + ivl.QTB_Tax_Override_Amount__c);
                                ivl.blng__TaxStatus__c = 'Completed';
                                ivl.blng__TaxErrorMessage__c = '';
                                //track current last trasaction invoiceLine error msg
                                currentInvliceLineIds.add(objectId);
                                objectIdWithTotalTaxMap.put(objectId, ivl.blng__TaxAmount__c);
                            }
                        }
                        TaxDetailList.addAll(lineJurLevelTaxDetail.values());
                        TaxDetailListFinal.addAll(lineJurLevelTaxDetail.values());
                        System.debug('TaxDetailList>>' + TaxDetailList);
                        System.debug('lineJurLevelTaxDetail>>' + lineJurLevelTaxDetail);
                        lineJurLevelTaxDetail.clear();
                        invoiceLineListFinal.add(ivl);
                    }
                    //CreditNoteLine
                    else if (objectId.getSobjectType() == blng__CreditNoteLine__c.getSObjectType()) {
                        blng__CreditNoteLine__c cnL = new blng__CreditNoteLine__c();
                        cnL.id = objectId;
                        System.debug('CreditLineId@@' + cnL.id);
                        for (Dom.XmlNode invoiceChildNode: invoiceResp.getChildElements()) {
                            QTB_Tax_Detail__c TaxDetail = new QTB_Tax_Detail__c();
                            if (invoiceChildNode.getName() == 'Taxes') {
                                TaxDetail = addTaxDetail(invoiceChildNode, 'CreditNoteLine', objectId, TaxDetail, InvoiceOrCreditNoteId);

                            }
                            if (invoiceChildNode.getName() == 'TotalTax') {
                                System.debug('TotalCreditNoteLineTax@@' + invoiceChildNode.getText());
                                cnL.blng__CalculateTax__c = false;
                                cnL.blng__TaxAmount__c = (-1) * Decimal.valueOf(invoiceChildNode.getText());
                                //Update QTB_Tax_Override_Amount__c Invoice Line #21202
                                cnL.QTB_Tax_Override_Amount__c = (-1) * Decimal.valueOf(invoiceChildNode.getText());
                                system.debug('cnL.QTB_Tax_Override_Amount__c' + cnL.QTB_Tax_Override_Amount__c);
                                cnL.blng__TaxErrorMessage__c = '';
                                objectIdWithTotalTaxMap.put(objectId, cnL.blng__TaxAmount__c);
                            }
                        }
                        TaxDetailList.addAll(lineJurLevelTaxDetail.values());
                        TaxDetailListFinal.addAll(lineJurLevelTaxDetail.values());
                        System.debug('TaxDetailList>>' + TaxDetailList);
                        System.debug('lineJurLevelTaxDetail>>' + lineJurLevelTaxDetail);
                        lineJurLevelTaxDetail.clear();
                        creditNoteLineListFinal.add(cnL);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('QTB_IRMVertexResponseUtil.readInvoiceResponse@@');
            System.debug('e.getLineNumber()@@' + e.getLineNumber());
            System.debug('e.getMessage()@@' + e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexResponseUtil.readInvoiceResponse');
        }
    }

    public static QTB_Tax_Detail__c addTaxDetail(Dom.XmlNode objectChildNode, string ObjectName, id objectId, QTB_Tax_Detail__c taxDetail, Id InvoiceOrCreditNoteId) {
        System.debug('addTaxDetail@@');
        taxDetail.QTB_TaxType__c = objectChildNode.getAttribute('taxType', null);

        //variable to store the LineID+JurisdictionLevel KEY in the lineJurLevelTaxDetail map - Story #21048
        String lineJurLevel = '';
        for (Dom.XmlNode taxesChildNode: objectChildNode.getChildElements()) {
            if (taxesChildNode.getName() == 'Jurisdiction') {
                taxDetail.QTB_JurisdictionLevel__c = taxesChildNode.getAttribute('jurisdictionLevel', null);
                taxDetail.QTB_Jurisdiction__c = taxesChildNode.getText();
                //Assigning QTB_JurisdictionLevel__c value to QTB_Tax_Code__c field as per GitLab #19529
                taxDetail.QTB_Tax_Code__c = taxDetail.QTB_JurisdictionLevel__c;

                lineJurLevel = objectId + taxDetail.QTB_JurisdictionLevel__c;
            }
            //Grouping of LineID+JurisdictionLevel Tax Details Logic - Story #21048
            //IF BLOCK for LineID+JurisdictionLevel group record is not present. Create new tax detail for the group combination.
            if (!lineJurLevelTaxDetail.containsKey(lineJurLevel)) {
                if (taxesChildNode.getName() == 'CalculatedTax') {
                    if (InvoiceOrCreditNoteId.getSobjectType() == blng__Invoice__c.getSObjectType()) {
                        taxDetail.QTB_CalculatedTax__c = Decimal.valueOf(taxesChildNode.getText());
                        taxDetail.QTB_Individual_Tax_Amount__c = Decimal.valueOf(taxesChildNode.getText());
                        //Update QTB_Tax_Override_Amount__c Tax Detail #21202
                        taxDetail.QTB_Tax_Override_Amount__c = Decimal.valueOf(taxesChildNode.getText());
                    } else {
                        taxDetail.QTB_Individual_Tax_Amount__c = (-1) * Decimal.valueOf(taxesChildNode.getText());
                        //Update QTB_Tax_Override_Amount__c Tax Detail #21202
                        taxDetail.QTB_Tax_Override_Amount__c = (-1) * Decimal.valueOf(taxesChildNode.getText());
                    }
                }
                if (taxesChildNode.getName() == 'EffectiveRate') {
                    Decimal effectiveRate = Decimal.valueOf(taxesChildNode.getText());
                    //Changes for the story #7977 to convert the tax rate to percentage
                    taxDetail.QTB_EffectiveRate__c = effectiveRate * 100;
                }
                if (taxesChildNode.getName() == 'Imposition') {
                    taxDetail.QTB_ImpositionId__c = Decimal.valueOf(taxesChildNode.getAttribute('impositionId', null));
                    taxDetail.QTB_Imposition__c = taxesChildNode.getText();
                }
                if (taxesChildNode.getName() == 'ImpositionType') {
                    taxDetail.QTB_ImpositionType__c = taxesChildNode.getText();
                }
                if (ObjectName == 'Usage') {
                    taxDetail.QTB_Usage__c = objectId;
                } else if (ObjectName == 'InvoiceLine') {
                    taxDetail.QTB_Invoice_Line__c = objectId;
                } else if (ObjectName == 'CreditNoteLine') {
                    taxDetail.QTB_Credit_Note_Line__c = objectId;
                }
                if (InvoiceOrCreditNoteId.getSobjectType() == blng__Invoice__c.getSObjectType()) {
                    taxDetail.QTB_Invoice__c = InvoiceOrCreditNoteId;
                } else {
                    taxDetail.QTB_Credit_Note__c = InvoiceOrCreditNoteId;
                }
            } else {
                //ELSE BLOCK for LineID+JurisdictionLevel group record is present, update the existing tax detail record to have
                //consolidated Tax information on the same record - Story #21048
                System.debug('INSIDE ELSE>>');
                taxDetail = lineJurLevelTaxDetail.get(lineJurLevel);

                //Logic to update the common JurisdictionLevel name in case of mulitple taxes for same JurisdictionLevel
                //if(taxesChildNode.getName() == 'Jurisdiction'){
                //taxDetail.QTB_JurisdictionLevel__c = 'Multiple ' + taxesChildNode.getAttribute('jurisdictionLevel',null) + ' Taxes';
                //}

                if (taxesChildNode.getName() == 'CalculatedTax') {
                    if (InvoiceOrCreditNoteId.getSobjectType() == blng__Invoice__c.getSObjectType()) {
                        Decimal calculatedTaxAmount = (taxDetail.QTB_CalculatedTax__c != null) ? taxDetail.QTB_CalculatedTax__c + Decimal.valueOf(taxesChildNode.getText()) : Decimal.valueOf(taxesChildNode.getText());
                        taxDetail.QTB_CalculatedTax__c = calculatedTaxAmount;
                        taxDetail.QTB_Individual_Tax_Amount__c = calculatedTaxAmount;
                        //Update QTB_Tax_Override_Amount__c Tax Detail #21202
                        taxDetail.QTB_Tax_Override_Amount__c = calculatedTaxAmount;
                    } else {
                        Decimal calculatedTaxAmount = (taxDetail.QTB_CalculatedTax__c != null) ? (taxDetail.QTB_CalculatedTax__c + (-1) * Decimal.valueOf(taxesChildNode.getText())) : (-1) * Decimal.valueOf(taxesChildNode.getText()); //GitLab US #31262
                        taxDetail.QTB_CalculatedTax__c = calculatedTaxAmount;//GitLab US #31262
                        taxDetail.QTB_Individual_Tax_Amount__c = calculatedTaxAmount;//GitLab US #31262
                        //Update QTB_Tax_Override_Amount__c Tax Detail #21202
                        taxDetail.QTB_Tax_Override_Amount__c = calculatedTaxAmount; 
                    }
                }
                if (taxesChildNode.getName() == 'EffectiveRate') {
                    Decimal effectiveRate = (taxDetail.QTB_EffectiveRate__c != null) ? taxDetail.QTB_EffectiveRate__c + (Decimal.valueOf(taxesChildNode.getText()) * 100) : Decimal.valueOf(taxesChildNode.getText()) * 100;

                    //Changes for the story #7977 to convert the tax rate to percentage
                    taxDetail.QTB_EffectiveRate__c = effectiveRate;
                }
            }
            lineJurLevelTaxDetail.put(lineJurLevel, taxDetail);
        }
        System.debug('addTaxDetail_taxDetail@@' + taxDetail);
        return taxDetail;
    }
    /*********************************************************************************************************
     * Class Name: handleErrorResponse
     * Return Type: void
     * Requirement: Gitlab #857, #2002
     * Description: Wrapper class to handle JSON Error message
     **********************************************************************************************************/
    public class handleErrorResponse {
        public Boolean success;
        public List < Errors > errors;
        public handleErrorResponse parse(String errorResponse) {
            return (handleErrorResponse) System.JSON.deserialize(errorResponse, handleErrorResponse.class);
        }
    }
    public class Errors {
        public String code;
        public String message;
    }



    /*********************************************************************************************************
     * Method Name: handleErrorResponseMapping
     * Parameters:  string responseBody
     * Return Type: void
     * Requirement: Gitlab #857, #2002
     * Description: This method is used for handling response error
     **********************************************************************************************************/
    public static void handleErrorResponseMapping(string responseBody, sObject InvoiceCreditNote, List < sObject > invoiceLineCreditNoteLine, Map < Id, List < blng__InvoiceLine__c >> invoiceIdToInvoiceLineMap, Map < Id, set < id >> invoiceIdToUsageSummaryMap, Map < Id, List < blng__Usage__c >> invoiceIdToUsageMap) {
        try {
            System.debug('handleErrorResponseMapping@@');
            System.debug('responseBody@@' + responseBody);
            //handling XML error response
            if (responseBody.contains('<')) {
                Dom.Document doc = new Dom.Document();
                doc.load(responseBody);
                Dom.XMLNode root = doc.getRootElement();
                for (Dom.XmlNode errorResponseNode: root.getChildElements()) {
                    for (Dom.XmlNode errorResponseChildNode: errorResponseNode.getChildElements()) {
                        //Fetching Fault Node from errorResponse
                        if (errorResponseChildNode.getName() == 'Fault') {
                            for (Dom.XmlNode errorNode: errorResponseChildNode.getChildElements()) {
                                if (errorNode.getName() == 'detail') {
                                    for (Dom.XmlNode errorChildNode1: errorNode.getChildElements()) {
                                        String ErrorMessage = (!errorChildNode1.getChildElements().isEmpty() && errorChildNode1.getChildElements().size() > 0) ? errorChildNode1.getChildElements()[1].getText() : '';
                                        updateErrorToInvoiceUsageLevel(ErrorMessage, InvoiceCreditNote, invoiceLineCreditNoteLine, invoiceIdToInvoiceLineMap, invoiceIdToUsageSummaryMap, invoiceIdToUsageMap);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //handling JSON error response
            else {
                handleErrorResponse errorRes = new handleErrorResponse();
                errorRes = errorRes.parse(responseBody);
                boolean successOrFailure = errorRes.success;
                List < Errors > errorList = new List < Errors > ();
                errorList = errorRes.errors;
                Errors err1 = new Errors();
                err1.message = (!errorList.isEmpty() && errorList.size() > 0) ? errorList[0].message : '';
                err1.code = (!errorList.isEmpty() && errorList.size() > 0) ? errorList[0].code : '';
                System.debug('err1.message@@' + err1.message);
                updateErrorToInvoiceUsageLevel(err1.code + ' - ' + err1.message, InvoiceCreditNote, invoiceLineCreditNoteLine, invoiceIdToInvoiceLineMap, invoiceIdToUsageSummaryMap, invoiceIdToUsageMap);
            }
            //Gitlab US#24525 - removed the update operation from here and added to the updateErrorToInvoiceUsageLevel
        } catch (Exception e) {
            System.debug('QTB_IRMVertexResponseUtil.handleErrorResponseMapping@@');
            System.debug('e.getLineNumber()@@' + e.getLineNumber());
            System.debug('e.getMessage()@@' + e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexResponseUtil.handleErrorResponseMapping');
        }
    }

    /*********************************************************************************************************
     * Method Name: updateErrorToInvoiceUsageLevel
     * Parameters:  String ErrorMessage, Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap,Map<Id,blng__UsageSummary__c> invoiceIdToUsageSummaryMap, Map<Id,List<blng__Usage__c>> invoiceIdToUsageMap
     * Return Type: void
     * Requirement: Gitlab #
     * Description: This method is used for storing error message on Invoice, InvoiceLine, UsageSummary & Usages object
     **********************************************************************************************************/
    public static void updateErrorToInvoiceUsageLevel(String ErrorMessage, sObject InvoiceCreditNote, List < sObject > invoiceLineCreditNoteLine, Map < Id, List < blng__InvoiceLine__c >> invoiceIdToInvoiceLineMap, Map < Id, set < id >> invoiceIdToUsageSummaryMap, Map < Id, List < blng__Usage__c >> invoiceIdToUsageMap) {
        try {
            ErrorMessage = (ErrorMessage != null && ErrorMessage.length() > 255) ? ErrorMessage.substring(0, 254) : ErrorMessage;
            System.debug('updateErrorToInvoiceUsageLevel_ErrorMessage@@' + ErrorMessage);
            //storing error message in Invoice obj            
            if (InvoiceCreditNote.id.getSobjectType() == blng__Invoice__c.getSObjectType()) {
                //storing error message in Invoice obj
                for (id invoiceID: invoiceIdToInvoiceLineMap.keySet()) {
                    blng__Invoice__c iv = new blng__Invoice__c();
                    iv.id = invoiceID;
                    iv.blng__TaxErrorMessage__c = ErrorMessage;
                    iv.blng__TaxStatus__c = 'Error';
                    invoiceListFinal.add(iv);

                    //storing error message in InvoiceLine obj
                    for (blng__InvoiceLine__c invl: invoiceIdToInvoiceLineMap.get(invoiceID)) {
                        blng__InvoiceLine__c inv = new blng__InvoiceLine__c();
                        inv.id = invl.id;
                        inv.blng__TaxErrorMessage__c = ErrorMessage;
                        inv.blng__TaxStatus__c = 'Error';
                        invoiceLineListFinal.add(inv);
                    }

                    //storing error message in Usage obj
                    if (!invoiceIdToUsageMap.isEmpty() && invoiceIdToUsageMap != null) {
                        for (blng__Usage__c usage: invoiceIdToUsageMap.get(invoiceId)) {
                            blng__Usage__c us = new blng__Usage__c();
                            us.id = usage.id;
                            us.QTB_TaxErrorMessage__c = ErrorMessage;
                            usageListFinal.add(us);
                        }
                    }

                    //storing error message in UsageSummary obj
                    if (!invoiceIdToUsageSummaryMap.isEmpty() && invoiceIdToUsageSummaryMap != null) {
                        for (id usageSum: invoiceIdToUsageSummaryMap.get(invoiceId)) {
                            if (usageSum != null) {
                                blng__UsageSummary__c us = new blng__UsageSummary__c();
                                us.id = usageSum;
                                us.QTB_TaxErrorMessage__c = ErrorMessage;
                                usgSummaryList.add(us);
                            }
                        }
                    }
                }
            }
            else {
                Map < id, string > usagetaxError = new Map < id, string > ();
                set < id > usageSummaryId = new set < id > ();
                if (InvoiceCreditNote.id.getSobjectType() == blng__CreditNote__c.getSObjectType()) {
                    //storing error message in CreditNote obj                
                    blng__CreditNote__c cn = new blng__CreditNote__c();
                    cn.id = InvoiceCreditNote.id;
                    cn.blng__TaxErrorMessage__c = ErrorMessage;
                    creditNoteListFinal.add(cn);
                }

                for (sObject creditLineOrUsage: invoiceLineCreditNoteLine) {
                    if (creditLineOrUsage.id.getSobjectType() == blng__CreditNoteLine__c.getSObjectType()) {
                        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
                        blng__CreditNoteLine__c cnl1 = (blng__CreditNoteLine__c) creditLineOrUsage;
                        if (cnl1.blng__Status__c != 'Posted') {
                            cnl.id = cnl1.id;
                            cnl.blng__TaxErrorMessage__c = ErrorMessage;
                            cnl.blng__TaxStatus__c = 'Error';
                            creditNoteLineListFinal.add(cnl);
                        }

                    } else {
                        blng__Usage__c cnl1 = (blng__Usage__c) creditLineOrUsage;
                        usagetaxError.put(cnl1.id, ErrorMessage);
                    }
                }
                if (usagetaxError != null && usagetaxError.size() > 0) {
                    // Update later based on usages
                    for (blng__Usage__c usg: [Select id, blng__UsageSummary__c from blng__Usage__c WHERE Id in: usagetaxError.keySet()]) {
                        usageSummaryId.add(usg.blng__UsageSummary__c);
                    }
                    //Get all the credit Note Line and Invoice Line
                    for (blng__CreditNoteLine__c credLine: [Select id, Name, blng__TaxErrorMessage__c, blng__Status__c,
                            blng__InvoiceLine__r.blng__UsageSummary__c
                            From blng__CreditNoteLine__c
                            where blng__Status__c != 'Posted'
                            and blng__InvoiceLine__r.blng__UsageSummary__c IN: usageSummaryId
                        ]) {
                        credLine.blng__TaxErrorMessage__c = ErrorMessage;
                        creditNoteLineListFinal.add(credLine);
                    }
                }
            }
            //Gitlab US#24525 - added update operations here as this method is also getting called from QTB_IRMToVertexService as well if any exception while callout
            system.debug('invoiceListFinal@@' + invoiceListFinal);
            //Updating Invoice, InvoiceLine, UsageSummary, Usage
            if (!invoiceListFinal.isEmpty() && invoiceListFinal.size() > 0) {
                update invoiceListFinal;
            }
            if (!invoiceLineListFinal.isEmpty() && invoiceLineListFinal.size() > 0) {
                update invoiceLineListFinal;
            }
            if (!usgSummaryList.isEmpty() && usgSummaryList.size() > 0) {
                update usgSummaryList;
            }
            if (!usageListFinal.isEmpty() && usageListFinal.size() > 0) {
                update usageListFinal;
            }
            //Update CreditNoteLine with error message
            if (!creditNoteLineListFinal.isEmpty() && creditNoteLineListFinal.size() > 0) {
                update creditNoteLineListFinal;
            }
            //Update CreditNote with error message
            if (!creditNoteListFinal.isEmpty() && creditNoteListFinal.size() > 0) {
                update creditNoteListFinal;
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_IRMVertexResponseUtil.updateErrorToInvoiceUsageLevel');
        }
    }
}