/*****************************************************************************************************
 * Class         : QTB_CreditRebillUtil
 * Test Class    : QTB_CreditRebillUtilTest
 * Author        : IRM/Virtusa
 * Purpose       : This is a helper class for all business logic related to credit & rebill for invoiceHelper
 * Requirement   :
 * Change History:  09/14/2022
 * Developer        Date             Description
 * -------------------------------------------------------------------------------------------
 * Gopi/Shailesh     09/14/2022      Gitlab US #9256 Credit & Rebill
 * Shailesh(Virtusa) 07/14/2023      SplitRebill -- Gitlab US#16256
 * Sarwar Baig       04/10/2025     Optimization of InvoiceLine Class(29100)
 *******************************************************************************************************/
public without sharing class QTB_CreditRebillUtil{
    
    private static final String CLASSNAME = 'QTB_CreditRebillUtil';
    public static Boolean throwExplicitException = false;
    
    /***********************************************************************************************************
     * Method : handleInvoiceHelperCreditRebill
     * Parameters: Set<ID> rebillInvoiceIdsSet, Boolean isCancel
     * Return Type : Map<String,List<SObject>>
     * Developer     Date           Description
    --------------------------------------------------------------------------------------
         * Sarwar Baig   04/10/2025     the new Data Type is Changed to List<SObject>(29100)
     ***************************************************************************************************************/
    public static Map<String,List<SObject>> handleInvoiceHelperCreditRebill(Set<ID> rebillInvoiceIdsSet, Boolean isCancel){
        try {
            if(QTB_CreditRebillUtil.throwExplicitException){
                throw new NullPointerException();
            }
            if(rebillInvoiceIdsSet ==null ||rebillInvoiceIdsSet.isEmpty()){return null; } // #Gitlab 29101  exit early
            
            //Issue - On Cancel Invoice, only invoice status is cancelled, but related orderproduct, usages are not getting cancelled., because its duplicate invoices are generated.
            //Solution -- On Cancel invoice (AND reject credit note) scenario -- making OrderProduct as Yes, so duplicate invoice will not get created
            //US #11567 - Order Product Activate Flag Changed to False when we are cancelling the invoice
            Set<ID> rebillParentInvoiceIdSet = new Set<ID>();
            Boolean isRebillInvoiceSubtotal = false;
            Decimal allRebillInvoiceSubtotal = 0.0;
            Map<String,List<SObject>> resultMap = new Map<String,List<SObject>>(); //#29101 Map to store the records to perform DML operations
            
            //Rebill Invoice
            //defect fix #18410-- by adding blng__InvoiceStatus__c condition as Draft, Earlier Inititate rebill invoice getting fetch AND due to that wrong values are captured
            //#25753 Added the QTB_Parent_Invoice__r.QTB_Invoice_Type__c in the Query
            List<blng__Invoice__c> rebillInvoiceList = [SELECT Id,blng__InvoiceStatus__c,QTB_Parent_Invoice__c,blng__Subtotal__c,QTB_Parent_Invoice__r.blng__Account__c,QTB_Parent_Invoice__r.blng__Subtotal__c,CurrencyIsoCode,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Parent_Invoice__r.QTB_ReBill_Status__c,QTB_Rebill_Type__c,QTB_Parent_Invoice__r.QTB_SplitRebillSubtotalOnParentInvoice__c, QTB_ReBill_Credit_Reason__c,QTB_ReBill_CreditNote_Internal_Note__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Parent_Invoice__r.QTB_ReBill_CreditNote_Internal_Note__c,QTB_Parent_Invoice__r.QTB_ReBill_Credit_Reason__c,QTB_Parent_Invoice__r.QTB_Invoice_Type__c, QTB_Parent_Invoice__r.QTB_Account_Sitad__c, QTB_Parent_Invoice__r.QTB_Site_Number__c, QTB_Parent_Invoice__r.QTB_Purchase_Order__c, QTB_Parent_Invoice__r.QTB_Case_Number__c //Gitlab - 27814
                                                        FROM blng__Invoice__c 
                                                        WHERE ID IN: rebillInvoiceIdsSet AND blng__InvoiceStatus__c = 'Draft' ];
            if(rebillInvoiceList== null || rebillInvoiceList.isEmpty()){return null; } // #Gitlab 29101  exit early
            
            for (blng__Invoice__c rebillInv : rebillInvoiceList) { // #Gitlab 29101 optimized the loop
                //  if (rebillParentInvoiceIdSet!=null && rebillInv.QTB_Parent_Invoice__c != null) { // 29101 Added nullcheck
                    if(rebillInv.QTB_Parent_Invoice__c != null){
                        rebillParentInvoiceIdSet.add(rebillInv?.QTB_Parent_Invoice__c);
                    }
                    isRebillInvoiceSubtotal = (rebillInv.QTB_Parent_Invoice__r?.blng__Subtotal__c > 0 || rebillInv.blng__Subtotal__c > 0) ? true : false;// Gitlab #29101 Optimized isRebillInvoiceSubtotal using direct comparison
                    allRebillInvoiceSubtotal += (rebillInv.blng__Subtotal__c != null ? rebillInv.blng__Subtotal__c : 0);// Gitlab #29101 Null-safe addition for allRebillInvoiceSubtotal
                }
                if(isCancel){
                    List<ID> orderProductIdList = new List<ID>();
                    List<OrderItem> orderProductList = new List<OrderItem>();
                    //fetching all rebill invoice lines based on rebill invoice ids
                    for(blng__InvoiceLine__c rebillInvLine :[SELECT ID,blng__OrderProduct__c 
                                                        FROM blng__InvoiceLine__c 
                                                        WHERE blng__Invoice__c IN: rebillInvoiceIdsSet]){
                        if (orderProductIdList!=null && rebillInvLine.blng__OrderProduct__c != null){ //Gitlab #29100 added null check
                            orderProductIdList.add(rebillInvLine?.blng__OrderProduct__c);
                        }
                    }
                    if(orderProductIdList!= null && !orderProductIdList.isEmpty()){
                        for(OrderItem ordItm : [SELECT ID,blng__HoldBilling__c 
                                            FROM OrderItem 
                                            WHERE ID IN :orderProductIdList ]){
                            // Order Product Activate Flag Changed to False() //29101 modified  and added directly to orderProductList
                            orderProductList.add(new OrderItem(ID = ordItm.ID, blng__HoldBilling__c ='Yes', SBQQ__Activated__c = false));
                        }
                        if(orderProductIdList!= null && !orderProductIdList.isEmpty()){//#29101 null check before adding
                            resultMap.put('updateOrderItem', orderProductList);
                        } //#29101 removed update orderProductList;
                    }
                }//After rebillInvoice generated -- creating CreditNote & CreditNoteLines based on parentInvoice
                else{
                    List<blng__CreditNoteLine__c> existingCreditNoteLinesList = [SELECT ID,blng__CreditNote__c,blng__CreditNote__r.blng__Subtotal__c,blng__CreditNote__r.blng__Status__c,QTB_Credit_Quantity__c,
                                                                            blng__Subtotal__c,QTB_Invoice__c,blng__Product__c,QTB_InvoiceLine__c,QTB_Invoice__r.QTB_ReBill_Status__c,blng__CreditNote__r.QTB_ReBill_Credit_Amount__c,CurrencyIsoCode
                                                                            FROM blng__CreditNoteLine__c 
                                                                            WHERE QTB_Invoice__c  IN:rebillParentInvoiceIdSet AND blng__Subtotal__c > 0 AND blng__Status__c != 'Cancelled'  ORDER BY createdDate DESC];
                    // blng__CreditNote__r.blng__Status__c from SOQL can be removed
                    List<Credit_ReBill_InvoiceSchedulerValidation__c> creditReBillInvSch = new List<Credit_ReBill_InvoiceSchedulerValidation__c>() ; //#29101 declared
                    
                    if(!rebillInvoiceList.isEmpty()&& rebillInvoiceList!=null && rebillInvoiceList[0].blng__Account__r.QTB_Legal_Entity_Country__c!=null
                    && rebillInvoiceList[0].blng__Account__r?.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c !=null && Credit_ReBill_InvoiceSchedulerValidation__c.getInstance()!= null){
                        
                        //Gitlab US#22511 -- creating the combination of LegalEntityCountry-LegalEntityNumber AND the passing to the method
                        String countryWithLegalEntityNumber = rebillInvoiceList[0].blng__Account__r.QTB_Legal_Entity_Country__c+'-'+rebillInvoiceList[0].blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c;
                        // Only get instance if the combination is not empty //#29101 concatenating null with string produces NUll
                        if(countryWithLegalEntityNumber!=null && Credit_ReBill_InvoiceSchedulerValidation__c.getInstance(countryWithLegalEntityNumber)!=null){
                            creditReBillInvSch.add(Credit_ReBill_InvoiceSchedulerValidation__c.getInstance(countryWithLegalEntityNumber));
                        }
                    }//#29101 check!='-', it will contain atleast hyphen if other Strings are blank; also note that concatenating null with string produces NUll
                    
                    if(creditReBillInvSch != null && creditReBillInvSch.size()>0){
                        creditReBillInvSch[0].isRunning__c = false; //Updating the isRunning__c to false, so other user can create invoice scheduler
                        creditReBillInvSch[0].Date_Time__c =System.now();
                    }   //#29101 removed update crediteReBillInvSch;
                    resultMap.put('updateCredit_ReBill_InvoiceSchedulerValidation__c',creditReBillInvSch);
                    
                    if(rebillInvoiceList!=null && !rebillInvoiceList.isEmpty() && isRebillInvoiceSubtotal && existingCreditNoteLinesList!=null && (existingCreditNoteLinesList.isEmpty() //#29100 Added!=null
                    ||(!existingCreditNoteLinesList.isEmpty() && existingCreditNoteLinesList[0].blng__CreditNote__r.blng__Subtotal__c  == 0))){
                        
                        List<blng__CreditNoteLine__c> creditNoteLinesList = new List<blng__CreditNoteLine__c>();
                        Map<ID,Decimal> invoiceLineIdWithCreditNoteLinesSubtotalMap = new Map<ID,Decimal>();
                        Map<ID,Decimal> invoiceLineIdWithCreditNoteLinesQuantityMap = new Map<ID,Decimal>();
                        blng__CreditNote__c crNote = new blng__CreditNote__c();//Create CreditNote for ReBill Invoice
                        
                        crNote.blng__Account__c = (rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Account__c !=null) ? rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Account__c : null;// #Gitlab 29101 added ternary operators
                        crNote.blng__RelatedInvoice__c = (rebillInvoiceList[0].QTB_Parent_Invoice__c!=null)?( rebillInvoiceList[0].QTB_Parent_Invoice__c) : null; //Relate to the Parent Ivoice
                        crNote.QTB_Reason_Code__c = rebillInvoiceList[0].QTB_Parent_Invoice__r?.QTB_ReBill_Credit_Reason__c; // Gitlab - 24173 #Gitlab 29101 added safe navigation operator ?.
                        
                        //updated the below line to fetch internalNotes from parent invoice level GITLAB #22676
                        crNote.QTB_Internal_Notes__c = rebillInvoiceList[0].QTB_Parent_Invoice__r?.QTB_ReBill_CreditNote_Internal_Note__c; // For Capturing Internal Notes from Invoice to Credit Note as per #14554 // Gitlab - 24173 #Gitlab 29101 added safe navigation operator ?.
                        crNote.CurrencyIsoCode = (rebillInvoiceList[0].CurrencyIsoCode != null)? rebillInvoiceList[0].CurrencyIsoCode: null; // #Gitlab 29101 added ternary operators
                        crNote.blng__CreditNoteDate__c = System.today();
                        crNote.blng__EffectiveTaxDate__c = System.today();
                        
                        if(rebillInvoiceList[0].QTB_Rebill_Type__c.equalsIgnoreCase(System.Label.QTB_SplitRebill)){ //SplitRebill
                            crNote.QTB_Credit_Note_Type__c ='Split ReBill'; //Added under user story 18987
                            Decimal differenceAmount = rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Subtotal__c - allRebillInvoiceSubtotal;
                            crNote.QTB_ReBill_Credit_Amount__c = (differenceAmount > 0) ? differenceAmount : (-1) * differenceAmount;
                        }else{
                            //if it Regular credit & rebill process (other than split) store the rebill invoice reference on credit note
                            crNote.QTB_Credit_Note_Type__c ='ReBill'; // Added under user story 18987
                            crNote.QTB_Rebill_Invoice__c = rebillInvoiceList[0].Id; //Rebill Invoice Id
                            Decimal differenceAmount = rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Subtotal__c - rebillInvoiceList[0].blng__Subtotal__c;
                            crNote.QTB_ReBill_Credit_Amount__c = (differenceAmount > 0) ? differenceAmount : (-1) * differenceAmount;
                        }
                        
                        //if it Regular credit & rebill process (other than split) store the rebill invoice reference on credit note //#29100 Determine if it's a SplitRebill
                        Boolean isSplitRebill = (rebillInvoiceList[0].QTB_Rebill_Type__c!=null && rebillInvoiceList[0].QTB_Rebill_Type__c.equalsIgnoreCase(System.Label.QTB_SplitRebill));
                        //#29101 Using ternary operator for Credit Note Type and ReBill Invoice Reference
                        crNote.QTB_Credit_Note_Type__c = isSplitRebill ? 'Split ReBill' : 'ReBill'; //Added under user story 18987
                        crNote.QTB_Rebill_Invoice__c = isSplitRebill ? null : rebillInvoiceList[0].Id; //#29101 Set to null if SplitRebill //Rebill Invoice Id
                        //#29101 Calculate difference amount
                        Decimal differenceAmount = isSplitRebill
                            ? (((rebillInvoiceList[0].QTB_Parent_Invoice__r != null && rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Subtotal__c != null))
                            ? (rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Subtotal__c - allRebillInvoiceSubtotal) : 0)
                            : (rebillInvoiceList[0].QTB_Parent_Invoice__r != null && rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Subtotal__c != null
                            ? (rebillInvoiceList[0].QTB_Parent_Invoice__r.blng__Subtotal__c - rebillInvoiceList[0].blng__Subtotal__c) : 0);
                        crNote.QTB_ReBill_Credit_Amount__c = (differenceAmount > 0) ? differenceAmount : (-1) * differenceAmount; // Set the credit amount using a ternary operator to ensure it's positive or negative
                        
                        //25753 Adding the Related Legacy invoice as Parent Invoice and Credit Note Type as legacy Credit after getting all the values for Stamping the Status as Legacy Cancelled as Legacy Invocies will not forward to EDP Integration
                        if(rebillInvoiceList[0].QTB_Parent_Invoice__r.QTB_Invoice_Type__c!=null && rebillInvoiceList[0].QTB_Parent_Invoice__r.QTB_Invoice_Type__c=='Legacy Invoice'){
                            crNote.QTB_Related_Legacy_Invoice__c = rebillInvoiceList[0].QTB_Parent_Invoice__c;
                            crNote.QTB_Credit_Note_Type__c = 'Legacy Credit';
                        }
                        if(rebillInvoiceList[0].QTB_Parent_Invoice__r.QTB_Account_Sitad__c){ //Gitlab - 27814
                            crNote.QTB_Site_Number__c = rebillInvoiceList[0].QTB_Parent_Invoice__r?.QTB_Site_Number__c; //#29101 added SafeNavigation
                            crNote.QTB_PO_Number__c = rebillInvoiceList[0].QTB_Parent_Invoice__r?.QTB_Purchase_Order__c; //#29101 added SafeNavigation
                            crNote.QTB_Case_Number__c = rebillInvoiceList[0].QTB_Parent_Invoice__r?.QTB_Case_Number__c;//#29101 added SafeNavigation
                        }   //Gitlab - 27814
                        
                        Database.SaveResult saveResults = Database.insert(crNote,true);//#29101 removed  resultMap.put('insertCreditNote', crNoteList);
                        for(blng__CreditNoteLine__c crdLine : existingCreditNoteLinesList){ // #29101 removed existingCreditNoteLinesList null check as it was done in the start of the if condition at creditNoteLinesList declaration
                            //Storing InvoiceLineId with CreditNoteLineSubtotal in invoiceLineIdWithCreditNoteLinesSubtotalMap
                            //Storing InvoiceLineId with CreditNoteQuantity in invoiceLineIdWithCreditNoteLinesQuantityMap
                            if(invoiceLineIdWithCreditNoteLinesSubtotalMap!=null  && invoiceLineIdWithCreditNoteLinesQuantityMap!=null && invoiceLineIdWithCreditNoteLinesSubtotalMap.containsKey(crdLine.QTB_InvoiceLine__c)){
                                invoiceLineIdWithCreditNoteLinesSubtotalMap.put(crdLine.QTB_InvoiceLine__c, invoiceLineIdWithCreditNoteLinesSubtotalMap.get(crdLine.QTB_InvoiceLine__c) + crdLine.blng__Subtotal__c);
                                invoiceLineIdWithCreditNoteLinesQuantityMap.put(crdLine.QTB_InvoiceLine__c, invoiceLineIdWithCreditNoteLinesQuantityMap.get(crdLine.QTB_InvoiceLine__c) + crdLine.QTB_Credit_Quantity__c);
                            }
                            else if(invoiceLineIdWithCreditNoteLinesSubtotalMap!=null && invoiceLineIdWithCreditNoteLinesQuantityMap!=null){
                                invoiceLineIdWithCreditNoteLinesSubtotalMap.put(crdLine.QTB_InvoiceLine__c, crdLine.blng__Subtotal__c);
                                invoiceLineIdWithCreditNoteLinesQuantityMap.put(crdLine.QTB_InvoiceLine__c, crdLine.QTB_Credit_Quantity__c);
                            }
                        }
                        
                        //based on current rebill Invoice fetching Parent Invoice, AND creating CreditNote Lines wrt to Parent Invoice Lines.
                        //DefectFix #21478-- added field in query -- QTB_SITAD__c  & commented where clause blng__Balance__c > 0
                        for (blng__InvoiceLine__c eachInvoiceLine : [SELECT ID,blng__Invoice__r.blng__Account__c,blng__Quantity__c,blng__Product__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c,
                                                                    blng__TotalAmount__c, blng__Subtotal__c,CurrencyIsoCode,blng__StartDate__c,blng__EndDate__c,blng__TaxCountry__c,
                                                                    blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Unit_Price__c, QTB_Charge_Type__c
                                                                    FROM blng__InvoiceLine__c
                                                                    WHERE blng__Invoice__c IN:rebillParentInvoiceIdSet]){
                            
                            //Creating CreditNoteLines based on InvoiceLines of Parent Invoice
                            blng__CreditNoteLine__c crdNoteLine = new blng__CreditNoteLine__c(); //#29101 Added safeNavigation Operator
                            crdNoteLine.blng__CreditNote__c = crNote.ID;
                            crdNoteLine.QTB_Account__c = eachInvoiceLine.blng__Invoice__r.blng__Account__c;
                            crdNoteLine.QTB_Invoice__c = eachInvoiceLine.blng__Invoice__c;
                            crdNoteLine.QTB_InvoiceLine__c = eachInvoiceLine.ID;
                            crdNoteLine.blng__Product__c = eachInvoiceLine?.blng__Product__c;
                            crdNoteLine.blng__CalculateTax__c = true;
                            crdNoteLine.CurrencyIsoCode = eachInvoiceLine?.CurrencyIsoCode;
                            crdNoteLine.blng__StartDate__c = eachInvoiceLine?.blng__StartDate__c;
                            crdNoteLine.blng__EndDate__c = eachInvoiceLine?.blng__EndDate__c;
                            // Gitlab 20604 Commenting the Tax country as its taken care in QTB_CNLhelper updating to legalEntity country
                            //crdNoteLine.blng__TaxCountry__c = eachInvoiceLine.blng__TaxCountry__c; // 13609 Added for Assigning tax country for diff shipto country for Estimate Tax for diff shipto country for Estimate Tax
                            //if already partial credit or full credit is done, then based on that creating/excluding creditnote lines
                            String legalEntityCountry = eachInvoiceLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c; //DefectFix #21478
                            if(creditNoteLinesList!=null && invoiceLineIdWithCreditNoteLinesSubtotalMap!=null && invoiceLineIdWithCreditNoteLinesQuantityMap!=null && invoiceLineIdWithCreditNoteLinesSubtotalMap.containsKey(eachInvoiceLine.ID)
                            && eachInvoiceLine.blng__Subtotal__c > invoiceLineIdWithCreditNoteLinesSubtotalMap.get(eachInvoiceLine.ID)){
                                // 29101 we merged the if
                                //Adding reamining Subtotal & Quantity
                                crdNoteLine.QTB_Credit_Quantity__c = eachInvoiceLine.blng__Quantity__c - invoiceLineIdWithCreditNoteLinesQuantityMap.get(eachInvoiceLine.ID);
                                Decimal remainingSubtotal = (eachInvoiceLine?.blng__Subtotal__c )- (invoiceLineIdWithCreditNoteLinesSubtotalMap.get(eachInvoiceLine.ID));
                                crdNoteLine.blng__Subtotal__c = remainingSubtotal;
                                creditNoteLinesList.add(crdNoteLine);
                            }else if(!invoiceLineIdWithCreditNoteLinesSubtotalMap.containsKey(eachInvoiceLine.ID) && creditNoteLinesList!=null){
                                //Gitlab #30243
                                decimal relainvlQty = eachInvoiceLine.blng__Quantity__c != null ? eachInvoiceLine.blng__Quantity__c : 0;
                                crdNoteLine.QTB_Credit_Quantity__c = relainvlQty;
                                
                                
                                    
                                    crdNoteLine.blng__Subtotal__c = eachInvoiceLine.blng__Subtotal__c;
                                creditNoteLinesList.add(crdNoteLine);
                        }
                    }
                    if(creditNoteLinesList!=null && !creditNoteLinesList.isEmpty()){// removed && creditNoteLinesList.size() > 0 as part of optimization
                        Database.SaveResult[] saveResults1 = Database.insert(creditNoteLinesList,true);//#29101 removed  resultMap.put('insertCreditNote', crNoteList);
                        
                        rebillParentInvoiceIdSet.clear();//#29101
                        invoiceLineIdWithCreditNoteLinesSubtotalMap.clear(); //#29101
                        invoiceLineIdWithCreditNoteLinesQuantityMap.clear(); //#29101
                    }
                }
                //this condition is reuqired to calculate the correct value for QTB_ReBill_Credit_Amount__c of credit note
                //if multiple invoice are update one by one sequentially
                else if(existingCreditNoteLinesList!=null && rebillInvoiceList[0].QTB_Rebill_Type__c=='Split' && !existingCreditNoteLinesList.isEmpty()
                && existingCreditNoteLinesList[0].blng__CreditNote__r.QTB_ReBill_Credit_Amount__c != null){
                    List<blng__CreditNote__c> crNoteList = new List<blng__CreditNote__c>();
                    blng__CreditNote__c creditNote = new blng__CreditNote__c();
                    creditNote.ID = existingCreditNoteLinesList[0].blng__CreditNote__c;                   
                    creditNote.CurrencyIsoCode = existingCreditNoteLinesList[0].CurrencyIsoCode;
                    Decimal differenceAmount =0.0;
                    differenceAmount = (rebillInvoiceList[0]?.QTB_Parent_Invoice__r.QTB_SplitRebillSubtotalOnParentInvoice__c != null)
                        ?  (rebillInvoiceList[0].QTB_Parent_Invoice__r?.blng__Subtotal__c - rebillInvoiceList[0].QTB_Parent_Invoice__r?.QTB_SplitRebillSubtotalOnParentInvoice__c)
                        :  (rebillInvoiceList[0].QTB_Parent_Invoice__r?.blng__Subtotal__c - allRebillInvoiceSubtotal);
                    
                    creditNote.QTB_ReBill_Credit_Amount__c = (differenceAmount > 0) ? differenceAmount : (-1) * differenceAmount;
                    crNoteList.add(creditNote);
                    resultMap.put('updatecreditNote', crNoteList);//29101  update crNoteList;
                }
            }
            if(resultMap!= null && !resultMap.isEmpty()){
                return resultMap;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method     : calculateRebillAmountsOnSplitRebillInvoice
     * Parameters : Set<ID> splitRebillInvoiceIdSet
     * Description: SplitRebill -- this method is used to update all rebill invoices "Subtotal", "Total amount", "Invoice No. with total amount" on Parent Invoice
    : for Vertex Taxation AND for StANDard Taxation logic is different hANDle in if AND elseif condition
         * Developer     Date           Description
    --------------------------------------------------------------------------------------
         * Sarwar Baig   04/10/2025     Changed 29101 return type from void to List<blng__Invoice__c>(#29100)
     **************************************************************************************************************/
    
    public static List<blng__Invoice__c> calculateRebillAmountsOnSplitRebillInvoice(Set<ID> splitRebillInvoiceId) {
        try{
            if (QTB_CreditRebillUtil.throwExplicitException || splitRebillInvoiceId == null ) {
                throw new NullPointerException();
            }
            Map<ID,blng__Invoice__c> parentInvoiceUpdatefinalMap = new Map<ID,blng__Invoice__c>();
            Map<String,String> invoiceNameWithInvWithTotalAmtMap = new Map<String,String>();
            Map<String,Decimal> invoiceNameWithTotalAmtMap = new Map<String,Decimal>();
            Map<String,Decimal> invoiceNameWithSubtotalAmtMap = new Map<String,Decimal>();
            List<String> finalInvWithTotalAmtList = new List<String>();
            Decimal finalTotalAmtWithTax = 0.0;
            Decimal finalSubtotal = 0.0;
            ID parentInvoiceId;
            Boolean regularTaxRule = false;
            Boolean moreInvoiceGenerated = false;
            List<String> totalRebillInvoiceList = new List<String>();
        
            //Fetching all splitRebill invoices based on provided splitRebillInvoiceId
            List<blng__Invoice__c> splitRebillinvoicelist = [SELECT id,Name,blng__Subtotal__c,blng__TotalAmount__c,blng__InvoiceStatus__c,QTB_Parent_Invoice__r.QTB_ReBill_Total_Amount__c,
                                                             QTB_Parent_Invoice__r.QTB_SplitRebillSubtotalOnParentInvoice__c,QTB_Parent_Invoice__r.QTB_ReBill_Invoice_With_Total__c,blng__Account__c, blng__Account__r.QTB_Legal_Entity_Country__c,blng__TaxStatus__c,CurrencyISOCode
                                                             FROM blng__Invoice__c WHERE Id IN :splitRebillInvoiceId AND blng__InvoiceStatus__c != 'Cancelled' AND blng__InvoiceStatus__c != 'Posted'];     
            
            //Setting regularTaxRule = true, if Account LegalEntityCountry is other than United States or Canada (other than Vertex)
            regularTaxRule = !( !splitRebillinvoicelist.isEmpty() && (splitRebillinvoicelist[0].blng__Account__r.QTB_Legal_Entity_Country__c == 'United States' || 
                                                                      splitRebillinvoicelist[0].blng__Account__r.QTB_Legal_Entity_Country__c == 'Canada') ) ? true : false;

            
            if(splitRebillinvoicelist==null || splitRebillinvoicelist.isEmpty()){ return null;}
           
            String parentInvWithTotal = splitRebillinvoicelist[0].QTB_Parent_Invoice__r.QTB_ReBill_Invoice_With_Total__c;
            if(parentInvWithTotal != null){
                totalRebillInvoiceList = parentInvWithTotal.split(' , '); 
            }
            moreInvoiceGenerated = (!totalRebillInvoiceList.isEmpty() && splitRebillinvoicelist.size() > totalRebillInvoiceList.size()); // The condition itself already returns a boolean, so you can assign it directly.
            
            blng__Invoice__c parentInvoice = new blng__Invoice__c();
            for(blng__Invoice__c rebillinvoiceinstance :splitRebillinvoicelist)
            {
                String rebillInvoiceWithTotalAmt = rebillinvoiceinstance.Name+' = '+ rebillinvoiceinstance.CurrencyISOCode+' '+rebillinvoiceinstance.blng__TotalAmount__c;
                parentInvoice.Id = rebillinvoiceinstance.QTB_Parent_Invoice__c;
                parentInvoiceId = rebillinvoiceinstance.QTB_Parent_Invoice__c;
                if(rebillinvoiceinstance.QTB_Parent_Invoice__r.QTB_ReBill_Invoice_With_Total__c == null || moreInvoiceGenerated){
                    
                    Boolean hasParent = !parentInvoiceUpdatefinalMap.isEmpty() && parentInvoiceUpdatefinalMap.containsKey(rebillinvoiceinstance.QTB_Parent_Invoice__c);
                   
                    parentInvoice.QTB_SplitRebillSubtotalOnParentInvoice__c = hasParent 
                        ? (parentInvoiceUpdatefinalMap.get(rebillinvoiceinstance.QTB_Parent_Invoice__c).QTB_SplitRebillSubtotalOnParentInvoice__c + rebillinvoiceinstance.blng__Subtotal__c )
                        : (rebillinvoiceinstance.blng__Subtotal__c);
                    parentInvoice.QTB_ReBill_Total_Amount__c = hasParent 
                         ? (parentInvoiceUpdatefinalMap.get(rebillinvoiceinstance.QTB_Parent_Invoice__c).QTB_ReBill_Total_Amount__c + rebillinvoiceinstance.blng__TotalAmount__c)
                         : (rebillinvoiceinstance.blng__TotalAmount__c);
                    parentInvoice.QTB_ReBill_Invoice_With_Total__c = hasParent 
                         ? (parentInvoiceUpdatefinalMap.get(rebillinvoiceinstance.QTB_Parent_Invoice__c).QTB_ReBill_Invoice_With_Total__c +' , '+ rebillinvoiceinstance.Name+' = '+ rebillinvoiceinstance.CurrencyISOCode+' '+rebillinvoiceinstance.blng__TotalAmount__c)
                         : (rebillinvoiceinstance.Name+' = '+ rebillinvoiceinstance.CurrencyISOCode+' '+rebillinvoiceinstance.blng__TotalAmount__c);
                    
                	parentInvoiceUpdatefinalMap.put(parentInvoice.Id,parentInvoice);
                }
                //For Vertex Tax Scenario, at a time only 1 rebill invoice will process from vertex
                else if(rebillinvoiceinstance.QTB_Parent_Invoice__r.QTB_ReBill_Invoice_With_Total__c != null &&
                        !rebillinvoiceinstance.QTB_Parent_Invoice__r.QTB_ReBill_Invoice_With_Total__c.contains(rebillInvoiceWithTotalAmt)){
                            
                    //Below logic is handling to store updated value(with tax value) in QTB_ReBill_Total_Amount__c, QTB_ReBill_Invoice_With_Total__c on Parent Invoice
                    String invWithTotalAmtTemp = rebillinvoiceinstance.QTB_Parent_Invoice__r.QTB_ReBill_Invoice_With_Total__c; //eg. INV-58560 = USD 1000.00 , INV-58561 = USD 3000.00
                    String finalInvWithAmt = '';
                    List<String> invWithAmtList = new List<String>();                    
                    invWithAmtList = invWithTotalAmtTemp.split(' , '); //eg. [INV-58560 = USD 1000.00 , INV-58561 = USD 3000.00]
                    if(regularTaxRule && rebillinvoiceinstance.QTB_Parent_Invoice__r.QTB_SplitRebillSubtotalOnParentInvoice__c == 0){
                        invoiceNameWithSubtotalAmtMap.put(rebillinvoiceinstance.Name,rebillinvoiceinstance.blng__Subtotal__c);
                    }
                    for(String eachInv : invWithAmtList){ //eg. INV-58560 = USD 1000.00
                        String invName = eachInv.substringBefore(' = '+rebillinvoiceinstance.CurrencyISOCode);
                        if(eachInv.contains(rebillinvoiceinstance.Name)){
                            
                            String oldTotalAmountVar = eachInv.substringAfterLast(rebillinvoiceinstance.CurrencyISOCode+' '); //return the amount
                            Decimal oldTotalAmoutDecimal = Decimal.valueOf(oldTotalAmountVar); //converting string amount to decimal amount
                            Decimal newTotalAmoutDecimal = rebillinvoiceinstance.blng__TotalAmount__c; //getting updated amount(amount with tax)
                            eachInv = rebillinvoiceinstance.Name+' = '+ rebillinvoiceinstance.CurrencyISOCode+' '+ rebillinvoiceinstance.blng__TotalAmount__c; //replacing old value with updated new value
                            if(invoiceNameWithTotalAmtMap!=null  && oldTotalAmoutDecimal != newTotalAmoutDecimal){
                                
                                invoiceNameWithTotalAmtMap.put(rebillinvoiceinstance.Name,newTotalAmoutDecimal); //this for Regular Tax
                                //this logic is for NA countries Vertex //#29101 used Ternary Operators
                                finalTotalAmtWithTax = (!regularTaxRule)? (rebillinvoiceinstance.QTB_Parent_Invoice__r?.QTB_ReBill_Total_Amount__c - oldTotalAmoutDecimal + newTotalAmoutDecimal)
                                    									: 0;		
                            }
                            invoiceNameWithInvWithTotalAmtMap.put(rebillinvoiceinstance.Name,eachInv);
                        }else{
                            if(!invoiceNameWithInvWithTotalAmtMap.containsKey(InvName)){
                                invoiceNameWithInvWithTotalAmtMap.put(InvName,eachInv);
                            }
                        }
                    }
                    if(invoiceNameWithInvWithTotalAmtMap!=null && !invoiceNameWithInvWithTotalAmtMap.isEmpty()){ //#29101 added null check
                       for(String eachInv : invoiceNameWithInvWithTotalAmtMap.values()){
                    		finalInvWithAmt = (finalInvWithAmt == '') ? (eachInv) : (finalInvWithAmt + ' , ' + eachInv);
                    	}
                    }
                    if(finalTotalAmtWithTax != null && !regularTaxRule ){ //for Vertex
                        parentInvoice.QTB_ReBill_Total_Amount__c = finalTotalAmtWithTax;
                    }
                    if(finalInvWithAmt!=null){ // 29101 added null check;
                        parentInvoice.QTB_ReBill_Invoice_With_Total__c = finalInvWithAmt;
                    }
                    if(parentInvoiceUpdatefinalMap!=null && parentInvoice!=null){
                        parentInvoiceUpdatefinalMap.put(parentInvoice.Id,parentInvoice);// #29101 added to the Map and then null checked
                    }
                }
            }
            if(!invoiceNameWithTotalAmtMap.isEmpty() && regularTaxRule){  //for Regular Tax
                for(Decimal totalInvAmt : invoiceNameWithTotalAmtMap.values()){
                    finalTotalAmtWithTax = finalTotalAmtWithTax + totalInvAmt; 
                } 
                parentInvoice.QTB_ReBill_Total_Amount__c = finalTotalAmtWithTax;
            }
            
            if(!invoiceNameWithSubtotalAmtMap.isEmpty()){ //for Regular Tax
                for(Decimal subtotal : invoiceNameWithSubtotalAmtMap.values()){
                    finalSubtotal = finalSubtotal + subtotal;
                }
                parentInvoice.QTB_SplitRebillSubtotalOnParentInvoice__c = finalSubtotal;
            }
            if(parentInvoiceId != null ){
                parentInvoiceUpdatefinalMap.put(parentInvoiceId,parentInvoice); 
            }
            if(!parentInvoiceUpdatefinalMap.isEmpty() && parentInvoiceUpdatefinalMap !=null && parentInvoiceUpdatefinalMap.values() != null){
                 return parentInvoiceUpdatefinalMap.values();
            }else{
                return null;
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        } 
    }
}