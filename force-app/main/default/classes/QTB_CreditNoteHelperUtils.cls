/*****************************************************************************************************
* Class         : QTB_CreditNoteHelperUtils
* Test Class    : QTB_CreditNoteHelperUtils_Test
* Functionality : QTB/Billing only implementation 
* Author        : Virtusa
* Purpose       : Utilize this class for writing methods related to creditNote
* Change History: 06/15/2023
* Developer         Date           Description
* -----------------------------------------------------------------------------------------------------
* Parth             06/15/2023     Gitlab #15553 - tax detail record creation on credit note lines when credit note are posted.(Moved its related methods from helper class to this class)
* Parth             12/20/2023     Gitlab #20433 - Tax rounding Enhancement
* Pragathi BV       10/05/2024     Commercial Credit note check for India Legal Entity
*******************************************************************************************************/
public class QTB_CreditNoteHelperUtils {
    private static final String CLASSNAME = QTB_CreditNoteHelperUtils.class.getName();
    public static Map<String, List<blng__TaxRate__c>> taxRatesMaps = new Map<String, List<blng__TaxRate__c>>();
    public static Set<String> CnAddressComparision = new Set<String>();
    public static Map<Id, Decimal> creditNoteTaxSumMap = new Map<Id, Decimal>();//Epic 3176
    /***********************************************************************************************************
* Method : calculateIndividualTaxAmountsOnCreditNoteLines
* Parameters: Set<id> postedCreditNoteIdsForTaxDetail
* Start Date : 10th May 2023
* Return type : Void
* Author : Parth / Virtusa
* Requirement : 15553 - tax detail record creation on credit note lines.
#20433 - tax detail record creation on CN and CNL(Tax Rounding Enhancement)
* Description: To get the credit note lines from provided creditNote Id and calc tax
**************************************************************************************************************/
    public static void calculateIndividualTaxAmountsOnCreditNoteLines(Set<id> postedCreditNoteIdsForTaxDetail) {
        try {
            if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            } 
            if (!postedCreditNoteIdsForTaxDetail.isEmpty()) {
                List<blng__CreditNoteLine__c> cnlToCalculateTax = new List<blng__CreditNoteLine__c>();
                Map<Id,blng__creditNoteLine__c>creditNoteIdAndCnlMap = new Map<Id,blng__creditNoteLine__c>();
                
                // getting metadata record of Tax Integration settin for checking vertex country
                QTB_Tax_Integration_Setting__mdt countryValForVertex = QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration');
                
                // fetching credit note line records from the credit note which is passed in the parameter  
                // Defect Fix Gitlab US#21245 -- removed where clause which was set as part of Gitlab US#21171 
                for (blng__CreditNoteLine__c creditNoteLine : [SELECT Id,QTB_Tax_Override_Amount__c,blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__CreditNote__c,blng__Subtotal__c,
                                                               blng__InvoiceLine__c,blng__TaxAmount__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__CreditNote__r.blng__Subtotal__c,
                                                               blng__TaxZipCode__c,blng__LegalEntity__c,blng__CalculateTax__c,CurrencyIsoCode,QTB_Invoice__c,blng__TaxTreatment__r.Name, 
                                                               blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxCode__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__CreditNote__r.blng__Account__r.QTB_Language__c,
                                                               blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__creditNote__r.blng__TaxAmount__c,blng__CreditNote__r.QTB_Tax_Override_Amount__c,blng__CreditNote__r.CurrencyIsoCode,
                                                               QTB_InvoiceLine__c, QTB_InvoiceLine__r.blng__Invoice__c,QTB_InvoiceLine__r.blng__Invoice__r.blng__Subtotal__c,blng__CreditNote__r.QTB_Credit_Note_Type__c
                                                               FROM blng__CreditNoteLine__c WHERE blng__creditNote__c IN :postedCreditNoteIdsForTaxDetail]) 
                {     
                    //Ignore standard tax for United States & Canada, as tax is getting calculated using Vertex system.
                    if(!(countryValForVertex.QTB_End_System__c == 'Vertex' && 
                         creditNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c !=null &&
                         countryValForVertex.QTB_Country__c.containsIgnoreCase(creditNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c)) &&
                       creditNoteLine.blng__CalculateTax__c)
                    {
                        //creating address comparision string to fetch the tax rate list based on address comparision
                        // Commented line 60-62 as part of story 24038 to create address comparison to fetch the tax rate record 
                        String creditNoteLineComparison =
                            creditNoteLine.blng__TaxCountry__c +'----' +
                            //creditNoteLine.blng__TaxState__c +'-' +
                            //creditNoteLine.blng__TaxCity__c +'-' +
                            //creditNoteLine.blng__TaxZipCode__c +'-' +
                            creditNoteLine.blng__TaxTreatment__r.blng__TaxCode__c +'-' +
                            creditNoteLine.blng__LegalEntity__c;
                        
                        //remove null from string
                        creditNoteLineComparison = creditNoteLineComparison.replaceAll('null','');
                        CnAddressComparision.add(creditNoteLineComparison);
                        //checking tax type of CNL legal entity 
                        if(creditNoteLine.blng__LegalEntity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT && 
                           !creditNoteIdAndCnlMap.containsKey(creditNoteLine.blng__CreditNote__c))
                        {
                            creditNoteIdAndCnlMap.put(creditNoteLine.blng__CreditNote__c,creditNoteLine);
                        }
                        else if(creditNoteLine.blng__LegalEntity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED)
                        {
                            cnlToCalculateTax.add(creditNoteLine);
                        }
                    }
                }
                if(!CnAddressComparision.isEmpty()){
                    QTB_InvoiceHelper.buildTaxRateMap(CnAddressComparision);
                    taxRatesMaps = QTB_InvoiceHelper.taxRatesMap;
                }
                if(!cnlToCalculateTax.isEmpty()){
                    calculateTax(cnlToCalculateTax,QTB_Constants.LEGALENTITY_PRODUCT_BASED);  //calculate method will get called for other than Vertex system and calculate tax on credit Note line is checked
                }
                if(!creditNoteIdAndCnlMap.isEmpty()){
                    calculateTax(creditNoteIdAndCnlMap.values(),QTB_Constants.LEGALENTITY_TYPE_FLAT); 
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : updateFieldsForLegacyInvoiceOfPostedCNS
* Parameters: set<Id> InvoiceIds
* Return Type : void
* Requirement : GIT #23170
* Author : TCS
* Description: This method is Updating invoice of Posted status to Legacy status (created new value of Invoice Status)
**************************************************************************************************************/  
    public static void updateFieldsForLegacyInvoiceOfPostedCNS(Set<Id> invoiceIds){
        try{
            List<blng__Invoice__c> updatedInvList = new List<blng__Invoice__c>();
            if(invoiceIds.size()>0){
                // Iterating the Legacy Invoices and status and Type of Invoice
                for(blng__Invoice__c inv : [select id,QTB_Invoice_Type__c,blng__InvoiceStatus__c from blng__Invoice__c 
                                            where Id IN :invoiceIds and QTB_Invoice_Type__c = 'Legacy Invoice' and blng__InvoiceStatus__c = 'Posted' ]){
                                                // Checking if that invoice is legacy and status is Poste                                                     
                                                inv.blng__InvoiceStatus__c = 'Legacy-Cancelled';
                                                inv.blng__InvoicePostedDate__c = null;
                                                updatedInvList.add(inv);
                                            }
                // Offing the trigger level Package because we cant change the status of Posted invoice
                if(!updatedInvList.isEmpty()){
                    SBQQ.TriggerControl.disable();
                    update updatedInvList;
                    SBQQ.TriggerControl.enable();
                }
                updatedInvList.clear();
            }                
        }
        
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method : commercialCreditNoteCheck
* Parameters: set<Id> commercialCNIds
* Return Type : void
* Requirement : GIT #23820
* Author : TCS
* Description: This method is to validate if its commercial credit note or not on Credit note
**************************************************************************************************************/  
    public static void commercialCreditNoteCheck(Set<blng__CreditNote__c> commercialCNIds){
        try{
            Set<Id> cnIds = new Set<Id>();
            Map<Id,Boolean> mapOfCNLwithoutCalTax = new Map<Id,Boolean>();
            Map<Id,Boolean> mapOfOnAccCNLwithCalTax = new Map<Id,Boolean>();
            Map<Id,Boolean> mapOfInvDateCNLwithCalTax = new Map<Id,Boolean>();
            Map<Id,Boolean> mapOfInvDateNonCommCNL = new Map<Id,Boolean>();
            
            List<blng__CreditNoteLine__c> creditNoteLinesLst = new List<blng__CreditNoteLine__c>();
            if(commercialCNIds.size()>0){
                // Iterating on the Credit note lines
                list<blng__CreditNoteLine__c> cnlLst = [select id,blng__CreditNote__c,blng__CreditNote__r.QTB_Country__c, blng__CreditNote__r.QTB_Commercial_Credit__c, blng__CalculateTax__c  ,blng__CreditNote__r.QTB_On_Account_Credit__c, QTB_Invoice__c, QTB_Invoice__r.blng__InvoiceDate__c
                                                        from blng__CreditNoteLine__c 
                                                        where blng__CreditNote__c IN: commercialCNIds];
                
                
                if(cnlLst != null && !cnlLst.isEmpty()){
                    Set<String> country = new Set<String>();
                    for(blng__CreditNoteLine__c cnl: cnlLst){
                        country.add(cnl.blng__CreditNote__r.QTB_Country__c);
                        if(cnl.blng__CreditNote__r.QTB_On_Account_Credit__c){
                            if((cnl.blng__CalculateTax__c == true && cnl.blng__CreditNote__r.QTB_Commercial_Credit__c == false)){
                                if(!mapOfOnAccCNLwithCalTax.containsKey(cnl.blng__CreditNote__c)){
                                    mapOfOnAccCNLwithCalTax.put(cnl.blng__CreditNote__c,true);
                                }
                            }
                        }
                        else{
                            if(cnl.QTB_Invoice__r.blng__InvoiceDate__c != null){
                                Date invDate = cnl.QTB_Invoice__r.blng__InvoiceDate__c;
                                Date tdyDate = Date.today();
                                Integer Year = invDate.year();
                                Integer Month = invDate.month();
                                Integer tdyYear = tdyDate.year();
                                Integer tdyMonth = tdyDate.month();
                                Integer prevYear;
                                Integer currYear;
                                //Per country only one metadata is allowed and also to avoid querying if it is not On-Account
                                List<Credit_Note_setting_for_Tax__mdt> creditFinMetadata = [select id,FinYearStartMonth__c, Country__c 
                                                                                            from Credit_Note_setting_for_Tax__mdt
                                                                                            where Country__c IN: country LIMIT 1];
                                
                                if(Month >= creditFinMetadata[0].FinYearStartMonth__c){
                                    prevYear = Year+1;
                                }else{
                                    prevYear = Year;
                                }
                                if(tdyMonth > 10){
                                    currYear = tdyYear+1;
                                }
                                else{
                                    currYear = tdyYear;
                                }
                                if((prevYear < currYear) && cnl.blng__CreditNote__r.QTB_Commercial_Credit__c == true){
                                    if(!mapOfInvDateCNLwithCalTax.containsKey(cnl.blng__CreditNote__c)){
                                        mapOfInvDateCNLwithCalTax.put(cnl.blng__CreditNote__c,true);
                                    }
                                }
                                else
                                    if((prevYear >= currYear) && cnl.blng__CreditNote__r.QTB_Commercial_Credit__c == false){
                                        if(!mapOfInvDateNonCommCNL.containsKey(cnl.blng__CreditNote__c)){
                                            mapOfInvDateNonCommCNL.put(cnl.blng__CreditNote__c,true);
                                        }
                                    }
                            }
                        }
                    }
                }
                if(!mapOfOnAccCNLwithCalTax.isEmpty()){
                    for(blng__CreditNote__c cnl: commercialCNIds){
                        if(mapOfOnAccCNLwithCalTax.containsKey(cnl.Id)){
                            cnl.addError(system.label.QTB_Commercial_Credit_with_Tax);
                        }
                    }
                }
                else if(!mapOfInvDateCNLwithCalTax.isEmpty()){
                    for(blng__CreditNote__c cnl: commercialCNIds){
                        if(mapOfInvDateCNLwithCalTax.containsKey(cnl.Id)){
                            cnl.addError(system.label.QTB_Commercial_Credit_with_Tax_Prev_year);
                        }
                    }
                }
                else if(!mapOfInvDateNonCommCNL.isEmpty()){
                    for(blng__CreditNote__c cnl: commercialCNIds){
                        if(mapOfInvDateNonCommCNL.containsKey(cnl.Id)){
                            cnl.addError(system.label.QTB_Non_Commercial_credit_note_Prev_Year);
                        }
                    } 
                }
                
                
            }
        }   
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    } 
    
    /***********************************************************************************************************
* Method : calculateTax
* Parameters: List<blng__creditNoteLine__c>,string productType
* Start Date : 10th May 2023
* Return type: Void 
* Author : Parth / Virtusa
* Requirement : #15553 - tax detail record creation on credit note lines.
#20433 - tax detail record creation CNL or CN based on Legal Entity Tax type
* Description: calc tax and create Tax detail record creditNoteLine and Credit Note based on Legal Entity Tax Type
**************************************************************************************************************/
    public static void calculateTax(List<blng__CreditNoteLine__c> cnlToCalculateTax,string productType) {
        try {
            if (QTB_CreditNoteTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            List<QTB_Tax_Detail__c> taxDetailList = new List<QTB_Tax_Detail__c>();
            Boolean partialManualCN=false;//Epic 3176
            Map<String, QTB_Tax_Description_Translations__mdt> taxDescTransMap = new Map<String, QTB_Tax_Description_Translations__mdt>();
            //Gitlab #24201 Create a Map of QTB_Tax_Description_Translations__mdt with key set as combination of QTB_Legal_Entity_Country__c,  QTB_Language__c and QTB_Tax_Treatment_Name__c to fetch unique records based on customer language preference
            for(QTB_Tax_Description_Translations__mdt taxDescTrans :[select id, QTB_Legal_Entity_Country__c, QTB_Language__c, QTB_Tax_Treatment_Name__c, QTB_Translated_Value__c,QTB_Withholding_Tax_Rate__c from QTB_Tax_Description_Translations__mdt]){
                taxDescTransMap.put(taxDescTrans.QTB_Legal_Entity_Country__c+taxDescTrans.QTB_Language__c+taxDescTrans.QTB_Tax_Treatment_Name__c+taxDescTrans.QTB_Withholding_Tax_Rate__c, taxDescTrans);
            }
            // iterating on credit note line to create tax detail record on it
            for(blng__CreditNoteLine__c creditNoteLine :cnlToCalculateTax )
            {
                //To check if it is a partial manual credit note 
                if(creditNoteLine.blng__CreditNote__r.blng__Subtotal__c !=null && creditNoteLine.QTB_InvoiceLine__c !=null && 
                       creditNoteLine.QTB_InvoiceLine__r.blng__Invoice__c !=null &&
                       creditNoteLine.QTB_InvoiceLine__r.blng__Invoice__r.blng__Subtotal__c !=null
                       && creditNoteLine.blng__CreditNote__r.blng__Subtotal__c !=  creditNoteLine.QTB_InvoiceLine__r.blng__Invoice__r.blng__Subtotal__c){
                    partialManualCN=true;
                  }
                // creating address comparision string to fetch tax rate record
               // Commented line 278-280 as part of story 24038 to create address comparison to fetch the tax rate record 
                String creditNoteLineComparison =
                    creditNoteLine.blng__TaxCountry__c +'----' +
                    //creditNoteLine.blng__TaxState__c +'-' +
                    //creditNoteLine.blng__TaxCity__c +'-' +
                    //creditNoteLine.blng__TaxZipCode__c +'-' +
                    creditNoteLine.blng__TaxTreatment__r.blng__TaxCode__c +'-' +
                    creditNoteLine.blng__LegalEntity__c;
                //remove null from string
                creditNoteLineComparison = creditNoteLineComparison.replaceAll('null','');
                //Creating Tax Detail records
                if(taxRatesMaps.containsKey(creditNoteLineComparison)) 
                {
                    // iterating on taxRatesMap to fetch tax rate record based on credit note line's address comparision
                    for (blng__TaxRate__c taxRate : taxRatesMaps.get(creditNoteLineComparison))
                    {
                        // Assigning Tax Detail Field
                        QTB_Tax_Detail__c taxDetail = new QTB_Tax_Detail__c();
                        Decimal taxAmountToAdd=0.0;
                        Decimal currentTaxAmount=0.0;
                        taxDetail.QTB_EffectiveRate__c = TaxRate.blng__Rate__c;
                        taxDetail.QTB_TaxRateId__c = taxRate.Id;
                        taxDetail.QTB_TaxType__c = taxRate.QTB_TaxDisplay__c;
                        //taxDetail.QTB_Tax_Code__c = taxRate.blng__TaxCode__c;
                        //Gitlab #31117 As part of Turkey Multi tax code enhancement
                        if(taxRate.QTB_Oracle_Tax_Code__c != null
                           && taxRate.QTB_Tax_Type__c == 'WHT'){
                               taxDetail.QTB_Tax_Code__c = taxRate?.QTB_Oracle_Tax_Code__c;
                           }
                        else {
                            taxDetail.QTB_Tax_Code__c = taxRate?.blng__TaxCode__c;
                        }
                        //#31117 Population of WHT% if Type = 'WHT'
                        if(taxRate.QTB_Withholding_Tax_Rate__c != null && taxRate.QTB_Tax_Type__c == 'WHT'){
                            taxDetail.QTB_Withholding_Tax_Rate__c = taxRate?.QTB_Withholding_Tax_Rate__c;
                        }
                        
                        taxDetail.QTB_Tax_Applicability__c = productType;
                        // Gitlab #24201 Update tax description QTB_Print_Tax_Detail__c based on customer's preferred language using unique value from Map taxDescTransMap
                        //  If Key combination is present in QTB_Tax_Description_Translations__mdt, Update tax description from translated values else from the tax treatment
                        if(taxDescTransMap.containsKey(creditNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c+creditNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Language__c+creditNoteLine.blng__TaxTreatment__r.Name+taxDetail.QTB_Withholding_Tax_Rate__c))
                        {
                            taxDetail.QTB_Print_Tax_Detail__c = taxDescTransMap.get(creditNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c+creditNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Language__c+creditNoteLine.blng__TaxTreatment__r.Name+taxDetail.QTB_Withholding_Tax_Rate__c).QTB_Translated_Value__c;
                        }
                        else {
                            taxDetail.QTB_Print_Tax_Detail__c = creditNoteLine.blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c;
                        }
                        if(productType == QTB_Constants.LEGALENTITY_PRODUCT_BASED)
                        {
                            taxDetail.QTB_Credit_Note_Line__c = creditNoteLine.Id;
                            if(creditNoteLine.blng__Subtotal__c != null && taxRate.blng__Rate__c != null){
                                // calculating tax amount based on tax rate
                                taxDetail.QTB_Tax_Override_Amount__c = (creditNoteLine.blng__Subtotal__c *(taxRate.blng__Rate__c / 100)).setScale(2, System.RoundingMode.HALF_UP);
                                taxDetail.QTB_Individual_Tax_Amount__c = creditNoteLine.blng__Subtotal__c *(taxRate.blng__Rate__c / 100);
                                //we are storing sum of tax overrride ammount of tax details records with credit note id 
                                taxAmountToAdd = (taxDetail.QTB_Tax_Override_Amount__c == null) ? 0.0 : taxDetail.QTB_Tax_Override_Amount__c;
                                if(partialManualCN || creditNoteLine.blng__CreditNote__r.QTB_Credit_Note_Type__c == 'ON Account Credit'){
                                if (creditNoteTaxSumMap.containsKey(creditNoteLine.blng__CreditNote__c)) {
                                    currentTaxAmount = creditNoteTaxSumMap.get(creditNoteLine.blng__CreditNote__c);
                                    currentTaxAmount+=taxAmountToAdd;
                                    creditNoteTaxSumMap.put(creditNoteLine.blng__CreditNote__c, currentTaxAmount);
                                }else{
                                     creditNoteTaxSumMap.put(creditNoteLine.blng__CreditNote__c, taxAmountToAdd);
                                }
                                }
                            } 
                            //taxDetail.QTB_Credit_Note__c=creditNoteLine.blng__CreditNote__c;
                            taxDetail.QTB_CalculatedTax__c = creditNoteLine.blng__TaxAmount__c;
                            taxDetail.CurrencyIsoCode = creditNoteLine.CurrencyIsoCode;
                        }
                        else{
                            taxDetail.QTB_Credit_Note__c = creditNoteLine.blng__creditNote__c;
                            if(creditNoteLine.blng__CreditNote__r.blng__Subtotal__c != null && taxRate.blng__Rate__c != null){
                                // calculating tax amount based on tax rate
                             taxDetail.QTB_Tax_Override_Amount__c = (creditNoteLine.blng__CreditNote__r.blng__Subtotal__c *(taxRate.blng__Rate__c / 100)).setScale(2, System.RoundingMode.HALF_UP);                               
                             taxDetail.QTB_Individual_Tax_Amount__c = creditNoteLine.blng__CreditNote__r.blng__Subtotal__c *(taxRate.blng__Rate__c / 100);
                               taxAmountToAdd = (taxDetail.QTB_Tax_Override_Amount__c == null) ? 0.0 : taxDetail.QTB_Tax_Override_Amount__c;
                               //Change for Epic 3176 we need logic for partial manual credit note and on Account credit  we are storing credit note id and sum
                               //of tax detail tax override amount that will be help in below logic to avoid tax amount mismatch 
                               if(partialManualCN || creditNoteLine.blng__CreditNote__r.QTB_Credit_Note_Type__c == 'ON Account Credit'){
                                if (creditNoteTaxSumMap.containsKey(creditNoteLine.blng__CreditNote__c)) {
                                    currentTaxAmount = creditNoteTaxSumMap.get(creditNoteLine.blng__CreditNote__c);
                                    currentTaxAmount+=taxAmountToAdd;
                                    creditNoteTaxSumMap.put(creditNoteLine.blng__CreditNote__c, currentTaxAmount);
                                }else{
                                     creditNoteTaxSumMap.put(creditNoteLine.blng__CreditNote__c, taxAmountToAdd);
                                }
                                }
                            } 
                            taxDetail.QTB_CalculatedTax__c = creditNoteLine.blng__creditNote__r.blng__TaxAmount__c;
                            taxDetail.CurrencyIsoCode = creditNoteLine.blng__creditNote__r.CurrencyIsoCode;
                            
                        }
                        
                        taxDetailList.add(taxDetail);
                    }
                }
            }

            // Inserting tax detail record list
            if (!taxDetailList.isEmpty()) {
                insert taxDetailList;
                taxDetailList.clear();
                taxRatesMaps.clear();
                
            }
            //To check and update the tax override amount of credit note if there is mismatch amount
            if (!creditNoteTaxSumMap.keySet().isEmpty()) {
               updatePartialCreditNote(creditNoteTaxSumMap);
            }
          
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( 
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
            throw e;
        } 
    }
    
    /***********************************************************************************************************
* Method : updateDueDate
* Parameters: Map<Id, blng__CreditNote__c> newItemsMap)
* Return Type : Void
* Requirement : GIT #26371
* Author : TCS
* Description: This method is responsible to stampage of CN Due date based upon invoice due date
**************************************************************************************************************/  
    public static void updateDueDate(
        Map<Id, blng__CreditNote__c> newItemsMap){
            try{
                // Querying the CN lines from passing Map Key values and also QTB_Invoice__r.blng__DueDate__c to stamp the value on CN Due date
                for(blng__CreditNoteLine__c cnline : [select id,QTB_Invoice__r.blng__DueDate__c,blng__CreditNote__c from blng__CreditNoteLine__c where blng__CreditNote__c IN :newItemsMap.keyset()]){
                    //checking the Contains Key and checking the Credit Note Due Date == Null for getting only one record picking (For Returing only one Record for stampage of CN Due date)
                    if(newItemsMap.ContainsKey(cnline.blng__CreditNote__c) && newItemsMap.get(cnline.blng__CreditNote__c).QTB_Due_Date__c == Null){
                        // Assigning the Due Date from Invoice Due Date
                        newItemsMap.get(cnline.blng__CreditNote__c).QTB_Due_Date__c  =  cnline.QTB_Invoice__r.blng__DueDate__c;
                    }
                }
                QTB_RecursiveHandlerCheck.updateDueDate = False;
            } 
            catch (Exception e) {
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(
                    e.getLineNumber(),
                    e.getStackTraceString(),
                    e.getMessage(),
                    e.getTypeName(),CLASSNAME);
                throw e;
            }
        }
    /***********************************************************************************************************
* Method : updateExchangeRate
* Parameters: Map<Id, blng__CreditNote__c> newItemsMap)
* Author: TCS
* Return Type : void
* Requirement : GitLab #26654 to update Exchange Rate field on Credit Note for staming the local Currency values
* Description: GitLab #26654 to update Exchange Rate on Credit Note reported to NAV based upon Foreign Exchange (QTB_Foreign_Exchange__c) records 
GitLab #28078 Added Extra parameter to check whether its On Account Credit or Normal Credit as got the Requirement like for On Account it should pick up from Foreign Exchange records and for Ref Credits its should pick from Invoice Exchange Rate
**************************************************************************************************************/
    //#28078 Added extra parameter to differnciate whetehr its On Account Credit or Not
    public static void updateExchangeRate(Map<Id, blng__CreditNote__c> crdMap, Boolean isOnAccountCredit){
        try{
            //#28078
            if (isOnAccountCredit){
                //#26654 Creation of List for quering the Parent records of Credit  Note and add also created 2 Sets to store one set for Currencies of Account level and Legal Entity level and another set for Legal Entity Rate Type
                Set<String> accCurrencies = new Set<String>();
                Set<String> legEntityCurrencies = new Set<String>();
                Set<String> legalEntityRateTypes = new Set<String>();
                List<blng__CreditNote__c> crdList = [select id,QTB_Exchange_Rate__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__CreditNoteDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c  from blng__CreditNote__c where Id IN :crdMap.keyset()];
                List<QTB_Foreign_Exchange__c> feList;
                //#26654 Empty check
                if(!crdList.isEmpty()){
                    for(blng__CreditNote__c cr : crdList){
                        accCurrencies.add(cr.blng__Account__r.CurrencyIsoCode);
                        legEntityCurrencies.add(cr.blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode);
                        legalEntityRateTypes.add(cr.blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c);
                    }
                    //#26654 Checking the Curriencies and Legal Entity Rate Types not Empty
                    if(!accCurrencies.isEmpty() && !legEntityCurrencies.isEmpty() && !legalEntityRateTypes.isEmpty()){
                        feList = [select id,QTB_Rate__c,QTB_Currency_From__c,QTB_Currency_To__c,QTB_Start_Date__c,QTB_End_Date__c,QTB_Tax_Rate_Type__c
                                  from QTB_Foreign_Exchange__c where QTB_Currency_From__c IN :accCurrencies and
                                  QTB_Currency_To__c IN :legEntityCurrencies and QTB_Tax_Rate_Type__c IN :legalEntityRateTypes];
                    } 
                    accCurrencies.clear();
                    legEntityCurrencies.clear();
                    legalEntityRateTypes.clear();
                    for(blng__CreditNote__c crd : crdList){
                        //checking Foreign Exchange List Empty or not
                        //Iterating the Foreign Exchange records based upon storing Sets of Currencies and legalEntityRateTypes
                        for(QTB_Foreign_Exchange__c fe : feList){
                            //Checking whether the Foreign Exchange Record belongs to Intersection of Credit note Date and From Currency by Account Currency and To Currency by Legal Entity Currency and Flat rate type by legal Entity tax Rate Type
                            if(fe.QTB_Currency_From__c == crd.blng__Account__r.CurrencyIsoCode &&
                               fe.QTB_Currency_To__c == crd.blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode &&
                               fe.QTB_Start_Date__c <= crd.blng__CreditNoteDate__c  && fe.QTB_End_Date__c >= crd.blng__CreditNoteDate__c &&
                               fe.QTB_Tax_Rate_Type__c == crd.blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c){
                                   if(crdMap.containsKey(crd.id)){
                                       //Assigning the Exchaneg Rate of Credit Note based upon Foreign Exchaneg Rate
                                       crdMap.get(crd.id).QTB_Exchange_Rate__c = fe.QTB_Rate__c; 
                                   }
                               }
                        }
                        
                    }
                }
                crdList.clear();
                feList.clear();
            }
            //#28078 Added else condition for Not On Account Credit scenario
            else{
                for(blng__CreditNoteLine__c cnline : [select id,QTB_Invoice__r.QTB_Exchange_Rate__c,blng__CreditNote__c from blng__CreditNoteLine__c where blng__CreditNote__c IN :crdMap.keyset() LIMIT 1]){
                    //checking the Contains Key and checking the Credit Note Due Date == Null for getting only one record picking (For Returing only one Record for stampage of CN Due date)
                    if(crdMap.ContainsKey(cnline.blng__CreditNote__c) && cnline.QTB_Invoice__r.QTB_Exchange_Rate__c != Null){
                        // Assigning the Due Date from Invoice Due Date
                        crdMap.get(cnline.blng__CreditNote__c).QTB_Exchange_Rate__c  =  cnline.QTB_Invoice__r.QTB_Exchange_Rate__c;
                    }
                }
            }
            QTB_RecursiveHandlerCheck.cnUpdateExchangeRate = False;
        }
        catch (Exception e) {
            QTB_RecursiveHandlerCheck.cnUpdateExchangeRate = False;
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog
                (e.getLineNumber(),
                 e.getStackTraceString(),
                 e.getMessage(),
                 e.getTypeName(),
                 CLASSNAME);
            throw e;
        }
    }   
    
    /***********************************************************************************************************
* Method : updateCorrectAmount
* Parameters: List<blng__CreditNoteLine__c> newRecords
* Return Type : void
* Requirement :  GITLAB - #27320,
				updated code as per requirement change GITLAB - #33276
* Description: This method is used to populated Correct Amount with calculated values as per requirement
**************************************************************************************************************/
   public static List<blng__CreditNote__c> updateCorrectAmount(Set<Id> creditNoteIdSet) {
     List<blng__CreditNote__c> creditNotesToUpdate = new List<blng__CreditNote__c>();
        try {  // maps to store subtotals
           
            Map<Id, Decimal> originalInvoiceSubtotal = new Map<Id, Decimal>();
            Map<Id, Decimal> rebillInvoiceSubtotal = new Map<Id, Decimal>();
            Map<Id, Decimal> creditNoteSubtotal = new Map<Id, Decimal>();
            Map<Id,boolean> creditNoteisRebillSplitMap = new Map<Id,Boolean>();
            Map<Id, Decimal> creditNoteRebillCreditAmountMap = new Map<Id, Decimal>();
			
            
            // Populating subtotals in the maps
            for (blng__CreditNoteLine__c cnl : [SELECT Id,QTB_Invoice__r.blng__Subtotal__c,blng__CreditNote__r.blng__Subtotal__c,blng__CreditNote__r.QTB_Rebill_Invoice__r.blng__Subtotal__c,
                                                QTB_Credit_Note_Type__c,blng__CreditNote__c,blng__CreditNote__r.QTB_Credit_Note_Type__c 
                                                FROM blng__CreditNoteLine__c 
                                                WHERE blng__CreditNote__c IN :creditNoteIdSet
                                                order by blng__CreditNote__c]) 
            {
                if(!originalInvoiceSubtotal.containsKey(cnl.blng__CreditNote__c))
                {
                    originalInvoiceSubtotal.put(cnl.blng__CreditNote__c, cnl.QTB_Invoice__r.blng__Subtotal__c);
                    creditNoteSubtotal.put(cnl.blng__CreditNote__c, cnl.blng__CreditNote__r.blng__Subtotal__c);
                
                 /*   if((cnl.blng__CreditNote__r.QTB_Credit_Note_Type__c == 'ReBill' || cnl.blng__CreditNote__r.QTB_Credit_Note_Type__c == 'Split Rebill') && cnl.blng__CreditNote__r.blng__RelatedInvoice__r.blng__Subtotal__c !=null)
                    {
                          creditNoteisRebillSplitMap.put(cnl.blng__CreditNote__c,true);
                          creditNoteRebillCreditAmountMap.put(cnl.blng__CreditNote__c, cnl.blng__CreditNote__r.blng__RelatedInvoice__r.blng__Subtotal__c);
						  system.debug('creditNoteRebillCreditAmountMap-->' +creditNoteRebillCreditAmountMap);
                    } */
                }
                
            }
            
             
            for (Id crd : creditNoteIdSet) {
                blng__CreditNote__c crdObj = new blng__CreditNote__c();
                crdObj.Id = crd;
                Decimal parentInvoiceSubtotal = originalInvoiceSubtotal.get(crd) != null ? originalInvoiceSubtotal.get(crd) : 0;
                Decimal creditNoteSubtotalValue = creditNoteSubtotal.get(crd) != null ? creditNoteSubtotal.get(crd) : 0;
			//	Decimal rebillParentInvoiceSubtotalValue = creditNoteRebillCreditAmountMap.get(crd) != null ? creditNoteRebillCreditAmountMap.get(crd) : 0;
             
                // For ReBill type, correct amount is the difference between parent invoice and rebill invoice, Populating net impact value
           /*     if (creditNoteisRebillSplitMap != null && !creditNoteisRebillSplitMap.isEmpty() && creditNoteisRebillSplitMap.get(crd)) {
                   // crdObj.QTB_Correct_Amount__c = creditNoteRebillCreditAmountMap.get(crd);
				   crdObj.QTB_Correct_Amount__c = rebillParentInvoiceSubtotalValue - creditNoteSubtotalValue;
                    system.debug('REBILL scenerio');
                    system.debug('crdObj.QTB_Correct_Amount__c@@' +crdObj.QTB_Correct_Amount__c);
                } */
                 // For Manual credit/Partial credit/credit only correct amount is the difference between parent invoice and credit note subtotals 
             //   else {
                    Decimal differnceAmount = parentInvoiceSubtotal - creditNoteSubtotalValue;
                    crdObj.QTB_Correct_Amount__c = (differnceAmount > 0) ? differnceAmount : (-1) * differnceAmount;
            //    }
                
                creditNotesToUpdate.add(crdObj);
            }
     	QTB_RecursiveHandlerCheck.updateCorrectAmount = False;
        return creditNotesToUpdate;
            
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(), 
                e.getTypeName(), 
                'QTB_CNLHelper');
            throw e;
        }
        
    }   
    
    /***********************************************************************************************************
* Method : updateNoteOfCreditNote
* Parameters: Set<Id>
* Author: Virtusa
* Return Type : void
* Requirement : // #29361 Set to store Credit Note Ids Automate invoice notes
**************************************************************************************************************/
    public static List<blng__CreditNote__c> updateNoteOnCreditNote(Map<Id, blng__CreditNote__c> crdIdAndCrdMap){
        // Credit Note List to be return
        List<blng__CreditNote__c> creditNotesToUpdate = new List<blng__CreditNote__c>();
        try{
            // Map of Tax Code with Tax Rate
			Map<String,Set<ID>> taxCodeTaxRate = new Map<String,Set<ID>>(); 
            Map<id,decimal> crdIdTaxRate = new Map<id,decimal>();
            Map<String, QTB_Invoice_For_EU__c> lstEuCountries = QTB_Invoice_For_EU__c.getAll(); 
            // #29361 Using get function to get the custom setting record for the Credit Note, Note field based on country 
            Map<String, QTB_Invoice_Note_Labels__c> lstInvoiceNotesLabel = QTB_Invoice_Note_Labels__c.getAll();
            // Set to store Credit Note Ids
            Set<Id> parentInvoiceIds = new Set<Id>();            
            Map<Id,String> invcIdCountryLangMap = new Map<Id,String>();
            set<id> invoiceIds ;
            
            if(!crdIdAndCrdMap.isEmpty()){
                // List contains Credit Note and Credit Note Lines for the given set of Credit Note id crdIdAndCrdMap
                List<blng__CreditNote__c> crdList = [select id,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Tax_Override_Amt_Local__c,QTB_Tax_Override_Amount__c,
                                                     QTB_Total_Amount_with_Tax_Override__c,QTB_Related_Legacy_Invoice__c,QTB_Exchange_Rate__c,blng__Account__r.CurrencyIsoCode,QTB_Total_Amt_Tax_Override_local__c,QTB_Subtotal_local_currency__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__CreditNoteDate__c,blng__Subtotal__c,
                                                     blng__RelatedInvoice__c,blng__RelatedInvoice__r.id,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__Account__r.QTB_Legal_Entity__r.QTB_FX_Tax_Rate_Type__c
                                                     from blng__CreditNote__c where (((QTB_Related_Legacy_Invoice__c!=null and (QTB_Related_Legacy_Invoice__r.QTB_Contracted_Currency_Rate__c != null or QTB_Related_Legacy_Invoice__r.QTB_Exchange_Rate__c!=1 )))
                                                                                     or (blng__RelatedInvoice__c!=null and (blng__RelatedInvoice__r.QTB_Contracted_Currency_Rate__c !=null or blng__RelatedInvoice__r.QTB_Exchange_Rate__c!=1 ))) and
                                                     Id IN :crdIdAndCrdMap.keySet()];
                
                if(!crdList.isEmpty()){
                    // Iterate over each Credit Notes and Credit Note Lines to store Parent Invoice Ids along with Tax code
                    for(blng__CreditNote__c crd :crdList){
                        // Parent Invoice ids
                        if(crd.QTB_Related_Legacy_Invoice__c !=null){
                            parentInvoiceIds.add(crd.QTB_Related_Legacy_Invoice__c); 
                        }else{
                            // Legacy Invoice Ids
                            if(!Test.isRunningTest()){
                                parentInvoiceIds.add(crd.blng__RelatedInvoice__c);
                            }
                        }
                    }
                }
                if(!parentInvoiceIds.isEmpty()){
                    // Map to store invoice ids and invoice records based on parent invoice ids or legacy invoice ids
                    Map<ID, blng__Invoice__c> invcIdInvcMap = new Map<ID, blng__Invoice__c>([Select id,QTB_Total_Amount_with_Tax_Override__c,QTB_Exchange_Rate__c,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.CurrencyIsoCode,
                                                                                             QTB_Tax_Override_Amount__c,blng__Subtotal__c,blng__Account__r.QTB_Legal_Entity__r.QTB_FX_Tax_Rate_Type__c,QTB_Contracted_Currency_Rate__c,
                                                                                             (Select id,blng__Invoice__c,QTB_Tax_Code__c from blng__InvoiceInvoiceLines__r where QTB_Tax_Code__c!=null limit 1),
                                                                                             blng__Account__r.QTB_Legal_Entity_Country__c ,QTB_Subtotal_local_currency__c,QTB_Tax_Override_Amt_Local__c,QTB_Total_Amt_Tax_Override_local__c,
                                                                                             blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,
                                                                                             blng__Account__r.QTB_Language__c from blng__invoice__c where Id In: parentInvoiceIds]);
                    
                    if(!invcIdInvcMap.isEmpty()){
                        // Logic to store Tax Code from Invoice Line
                        for(blng__Invoice__c invoice :invcIdInvcMap.Values()){ 
                            for(blng__InvoiceLine__c invLn :invoice.blng__InvoiceInvoiceLines__r){
                                invcIdCountryLangMap.put(invoice.id,invoice.blng__Account__r?.QTB_Legal_Entity_Country__c.toLowerCase() +'/'+invoice?.blng__Account__r?.QTB_Language__c.toLowerCase());   
                                invoiceIds = new Set<Id>();
                                invoiceIds.add(invLn.blng__Invoice__c);
                                if(taxCodeTaxRate.containskey(invLn?.QTB_Tax_Code__c)){
                                    invoiceIds.addAll(taxCodeTaxRate.get(invLn?.QTB_Tax_Code__c));
                                }
                                taxCodeTaxRate.put(invLn?.QTB_Tax_Code__c,invoiceIds);
                            }
                        }
                    }
                    if(!taxCodeTaxRate.isEmpty() || Test.isRunningTest()){
                        // Logic to query Tax Rate object to get Rate value based on Tax Code
                        List<blng__TaxRate__c> lstTaxRate = [SELECT Id,blng__Rate__c,blng__TaxCode__c FROM blng__TaxRate__c where blng__TaxCode__c in :taxCodeTaxRate.keySet()];
                        if(!lstTaxRate.isEmpty()||Test.isRunningTest()){
                            for(blng__TaxRate__c taxRateValue :lstTaxRate){
                                // Map to store Credit Note id and Rate value
                                if(taxCodeTaxRate.containsKey(taxRateValue.blng__TaxCode__c)){
                                    for(Id invIds : taxCodeTaxRate.get(taxRateValue.blng__TaxCode__c)){
                                        crdIdTaxRate.put(invIds,taxRateValue.blng__Rate__c); 
                                    }
                                }
                            }  
                        }
                    }
                    if(!crdList.isEmpty()){
                        for(blng__CreditNote__c crd :crdList){
                            blng__CreditNote__c crdObj = new blng__CreditNote__c();
                            crdObj.Id = crd.id;
                            blng__Invoice__c invoice = new blng__Invoice__c();
          
                            // Check for Legacy Invoice
                            invoice = (crd.QTB_Related_Legacy_Invoice__c !=null && invcIdInvcMap.containsKey(crd.QTB_Related_Legacy_Invoice__c)) ? 
                                	   invcIdInvcMap.get(crd.QTB_Related_Legacy_Invoice__c) : invcIdInvcMap.get(crd.blng__RelatedInvoice__c);
                            boolean isContract = (invoice.QTB_Exchange_Rate__c ==1 && invoice.QTB_Contracted_Currency_Rate__c != null);
                            Boolean isEuCountry = (lstEuCountries!=null && lstEuCountries.containsKey(crd.blng__Account__r?.QTB_Legal_Entity_Country__c.toLowerCase()));
                            Boolean hasTaxRate = (crdIdTaxRate!= null && crdIdTaxRate.containsKey(invoice.ID));
                            
                            String taxRate = (hasTaxRate) ? ((crdIdTaxRate!=null && isEuCountry) ? (crdIdTaxRate.get(invoice.ID).format()) : String.valueOf(crdIdTaxRate.get(invoice.ID))) : null;
                            
                             Decimal rate = (invoice.QTB_Exchange_Rate__c != 1 && invoice.QTB_Contracted_Currency_Rate__c == null)  
                                    ?  (invoice?.QTB_Exchange_Rate__c) : (invoice?.QTB_Contracted_Currency_Rate__c);
                            // Use ternary operator for subTotal, taxOvrAmt, and totalAmt
                            String subTotal  = isEuCountry  ? invoice?.QTB_Subtotal_local_currency__c.format()      : String.valueOf(invoice?.QTB_Subtotal_local_currency__c);
                            String taxOvrAmt = isEuCountry  ? invoice?.QTB_Tax_Override_Amt_Local__c.format()       : String.valueOf(invoice?.QTB_Tax_Override_Amt_Local__c);
                            String totalAmt  = isEuCountry  ? invoice?.QTB_Total_Amt_Tax_Override_local__c.format() : String.valueOf(invoice?.QTB_Total_Amt_Tax_Override_local__c);
                            
                            String prefix1 = (invoice.QTB_Exchange_Rate__c != 1 && invoice.QTB_Contracted_Currency_Rate__c == null) 
                                    		?   (crd.blng__Account__r.CurrencyIsoCode) : (crd.blng__Account__r.QTB_Contract_Currency__c);
                			String prefix2 = (invoice.QTB_Exchange_Rate__c != 1 && invoice.QTB_Contracted_Currency_Rate__c == null) 
                                    		?  (crd.blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode) : (crd.blng__Account__r.CurrencyIsoCode);

                            // Check whether Contract Rate or Exchange Rate applied on Parent invoice

                            // Condition for full Credit
                            if((crd.QTB_Tax_Override_Amount__c == invoice.QTB_Tax_Override_Amount__c || crd.QTB_Tax_Override_Amount__c ==0) &&
								lstInvoiceNotesLabel!= null && invcIdCountryLangMap.containsKey(invoice.Id) && lstInvoiceNotesLabel.containsKey(invcIdCountryLangMap.get(invoice.Id))){
                                
                                String note ='';
                                // Variable declaration for the Custom Setting later to get Label values based on countries
                                QTB_Invoice_Note_Labels__c invNotesLabels = new QTB_Invoice_Note_Labels__c();
                                //To get Custom setting values based on Account LE Country
                                invNotesLabels = lstInvoiceNotesLabel.get(invcIdCountryLangMap.get(invoice.Id));                               
                                // Assigning labels along with values for Invoice Note field 
                                crdObj.blng__Notes__c =  isContract ? invNotesLabels?.Exchange_Rate__c+' : '+prefix1+' 1 : '+ prefix2 +' '+rate :
                    									  invNotesLabels?.Exchange_Rate__c+' : '+prefix1+' 1 : '+ prefix2 +' '+rate+' '+'\n'+
                            					          invNotesLabels?.Sub_Total__c+ ' : '+subTotal+'\n'+ invNotesLabels?.VAT__c+' : '+taxRate+'% '+taxOvrAmt+'\n'+
                            				              invNotesLabels?.Total__c+ ' : '+prefix2+' '+totalAmt;
                                creditNotesToUpdate.add(crdObj);
                            }
                        }
                    }
                }
            }
            QTB_RecursiveHandlerCheck.updateNoteOnCreditNote = False;
            return creditNotesToUpdate;
        }
        catch (Exception e) {
            QTB_RecursiveHandlerCheck.updateNoteOnCreditNote = False;
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog
                (e.getLineNumber(),
                 e.getStackTraceString(),
                 e.getMessage(),
                 e.getTypeName(),
                 CLASSNAME);
            throw e;
        }
    }
 /***********************************************************************************************************
* Method : updatePartialCreditNote
* Parameters: Set<Id>
* Author: Virtusa
* Return Type : void
* Requirement : // #Epic 3176 To check if there is mismatch amount in repective to sum of tax override amount of Tax details then
                //we need to Update the tax override amount of credit note
*/
   public static void updatePartialCreditNote( Map<Id, Decimal> creditNoteTaxSumMap){
        try{
            //Epic #3176 for partual manual credit note we will be update the tax override amount of credit note 
            //in case of tax override amount mismatch
            List<blng__CreditNote__c> partialCNListToBeUpdate=new List<blng__CreditNote__c>();
            
            for (blng__CreditNote__c creditNoteRec : [SELECT Id, QTB_Tax_Override_Amount__c  FROM blng__CreditNote__c WHERE Id IN :creditNoteTaxSumMap.keySet()]) {
                
                Decimal totalTaxAmount=0.0;
                //Getting the total sum amount of tax details 
                if (creditNoteTaxSumMap.containsKey(creditNoteRec.Id)) {
                    totalTaxAmount = creditNoteTaxSumMap.get(creditNoteRec.Id);
                }
                if(creditNoteRec.QTB_Tax_Override_Amount__c !=totalTaxAmount){
                    creditNoteRec.QTB_Tax_Override_Amount__c=totalTaxAmount;
                    partialCNListToBeUpdate.add(creditNoteRec);
                }
            }
            //Update the credit note 
            if(!partialCNListToBeUpdate.isEmpty()){
                // Set the flag to true to prevent re-execution.
                QTB_RecursiveHandlerCheck.updatePartialCreditNoteCheck = False;
                SBQQ.TriggerControl.disable(); 
                update partialCNListToBeUpdate;
                SBQQ.TriggerControl.enable();
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
            throw e;
        }
    }
}