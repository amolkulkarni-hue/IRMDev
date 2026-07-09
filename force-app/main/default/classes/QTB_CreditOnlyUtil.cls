/*****************************************************************************************************
* Class         : QTB_CreditOnlyUtil 
* Test Class    : QTB_CreditOnlyUtiltest
* Author        : IRM/Virtusa/tcs
* Purpose       : This is a helper class for all business logic related to credit only invoiceHelper
* Requirement   : 
* Change History:  10/04/2023
* Developer                 Date             Description
* -------------------------------------------------------------------------------------------
* Shailesh(Virtusa)/Veera   09/04/2023
* Parth(Virtusa)            27/02/2024       #21897 Tax status and tax percentage applied fields are not getting updated in CN line upon creation
*******************************************************************************************************/
public class QTB_CreditOnlyUtil {
    private static final String CLASSNAME = 'QTB_CreditOnlyUtil';
    public static boolean throwExplicitException = false;
    
    /***********************************************************************************************************
* Method     : handleCreditOnlyUtil
* Parameters : Id creditonlyInvoicId,boolean Tax,string creditReason,string internalNotes,Date creditNoteDate
* Description: This method Fetch the Invoice record and create the Credit note recrod
**************************************************************************************************************/
    @AuraEnabled
    public static String handleCreditOnlyUtil(Id creditonlyInvoicId,boolean Tax,string creditReason,string internalNotes,Date creditNoteDate){
        try {
            System.debug('handleCreditOnlyUtil_creditonlyInvoicId='+creditonlyInvoicId +' Tax='+Tax);
            boolean isTaxDetailCreated = false;
            // Added # 22304 as part of legacy Invoice build added Boolean flag for Breaking the Linkage of Invoice and line ref for On Acc credit
            //boolean isLegacyInvoice = false;
            if (QTB_CreditRebillUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            //Fetching the invoice based on InvoiceId
            // Added #22304 as part of legacy Invoice build for Querying the Invoice type field from Invoice
            List<blng__Invoice__c> invoiceList = [SELECT Id,blng__InvoiceStatus__c,QTB_Parent_Invoice__c,blng__Subtotal__c, QTB_Parent_Invoice__r.blng__Subtotal__c,CurrencyIsoCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                                  QTB_Parent_Invoice__r.QTB_ReBill_Status__c,QTB_Rebill_Type__c,QTB_Parent_Invoice__r.QTB_SplitRebillSubtotalOnParentInvoice__c,QTB_Invoice_Type__c,
                                                  QTB_ReBill_Credit_Reason__c,QTB_ReBill_CreditNote_Internal_Note__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c, 
                                                  QTB_Site_Number__c, QTB_Purchase_Order__c, QTB_Case_Number__c, QTB_Account_Sitad__c   //Gitlab - 27814
                                                  FROM blng__Invoice__c
                                                  WHERE Id =:creditonlyInvoicId AND blng__InvoiceStatus__c = 'posted'];
            
            List<blng__CreditNoteLine__c> creditNoteLineList;
            //#30650 Made necessary changes to Legacy Credit Only Credits to Normal Credits not like On Account credit
            if(!invoiceList.isEmpty()){                
                blng__CreditNote__c crNote = new blng__CreditNote__c();
                crNote.blng__Account__c = invoiceList[0].blng__Account__c;
                //#30650 Made global Assignments for related Invoice and Reason Code
                crNote.blng__RelatedInvoice__c = invoiceList[0].Id;
                crNote.QTB_Reason_Code__c = creditReason;
                crNote.CurrencyIsoCode = invoiceList[0].CurrencyIsoCode;
                // Added #22304 as part of legacy Invoice build if and else blocks
                if(invoiceList[0].QTB_Invoice_Type__c != 'Legacy Invoice'){
                    //Relate to the Parent Ivoice
                    crNote.QTB_Credit_Note_Type__c ='Credit Only'; //Added under user story 18987
                    if(invoiceList[0].QTB_Account_Sitad__c){//Gitlab - 27814 start
                        crNote.QTB_Site_Number__c = invoiceList[0].QTB_Site_Number__c;
                        crNote.QTB_PO_Number__c = invoiceList[0].QTB_Purchase_Order__c;
                        crNote.QTB_Case_Number__c = invoiceList[0].QTB_Case_Number__c;
                    }//Gitlab - 27814 end
                }
                else{
                    //crNote.blng__RelatedInvoice__c = null;
                    // Added as part of #23205 which is part of Legacy order change for assigning the Related Legacy invocie to Credit Note for #23170
                    crNote.QTB_Related_Legacy_Invoice__c = invoiceList[0].Id; // Related Legacy invoice Attaching to Credit note for ref
                    //#30650 Commented the below Assignments making Normal Credit not On Account Credit and making parallel to Credit rebill thing
                    //crNote.QTB_On_Account_Credit__c = true;
                    //#29685 As part of this story the Credit Note type to be stamped as Legacy Credit for legacy Credits
                    crNote.QTB_Credit_Note_Type__c  = 'Legacy Credit';
                    //crNote.QTB_Reason_Code__c = 'Legacy Credit';
                    // Added Boolean to true for Legacy Invoices
                    //isLegacyInvoice = true;
                    if(invoiceList[0].QTB_Account_Sitad__c){//Gitlab - 28779 Defect fix start
                        crNote.QTB_Site_Number__c = invoiceList[0].QTB_Site_Number__c;
                    }//Gitlab - 28779 Defect fix start
                }
                
                //crNote.QTB_Credit_Note_Type__c ='Credit Only'; //Added under user story 18987
                crNote.QTB_Internal_Notes__c = internalNotes;
                crNote.blng__CreditNoteDate__c = system.today();
                crNote.blng__EffectiveTaxDate__c = system.today();
                //#26819 - credit note without changes
                if(!tax){
                    crNote.Is_Tax_Applicable__c=false;
                }
                //#24075 - Commercial Credit check for Credit note without Tax
                if(!Tax && invoiceList[0].blng__Account__r.QTB_Legal_Entity_Country__c == 'India'){
                    crNote.QTB_Commercial_Credit__c = true;
                }

                insert crNote;
                system.debug('Created Credit note:'+crNote);
                //Gitlab #21526, due to twin field QTB_Tax_Override_Amount__c is getting updated from invoice level
                // updating the field value to 0 in case of witout tax 
                if(!tax){
                    blng__CreditNote__c crdtNote = new blng__CreditNote__c();
                    crdtNote.Id = crNote.Id; 
                    crdtNote.QTB_Tax_Override_Amount__c = 0;
                    //#28097 Added Product BAsed condition as well
                    if(invoiceList[0].blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT ||
                      invoiceList[0].blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED){
                      crdtNote.QTB_Total_Tax_Rate__c = 0;
                    }
                    update crdtNote;
                }
                //Create CreditNoteLine for Credit only process
                // Added #22304 as part of legacy Invoice build Added Extra Variable for passing as Legacy invoice or noyt for Creation of Credit note lines
                //#30650 Commenting one Parameter while passing the creation of Cn Lines
                creditNoteLineList = createCreditNoteLines(creditonlyInvoicId,crNote.Id,Tax/*,isLegacyInvoice*/); 
                
                ///Defect Fix Gitlab US#21245 getting metadata record of Tax Integration settin for checking vertex country
                QTB_Tax_Integration_Setting__mdt countryValForVertex = QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration');
                String legalEntityCountry = invoiceList[0].blng__Account__r.QTB_Legal_Entity_Country__c;
                boolean billingOnlyCountry = false;
                //Tax Details records create process on withtax redio button
                //Defect Fix Gitlab US#21245 -- Not cloning Tax Details record for billingOnlyCountries
                // Gitlab 24091 added creditNoteLineList != null for de-reference a null object 
                if(Tax && creditNoteLineList != null  && !creditNoteLineList.isEmpty() && legalEntityCountry != null && 
                   (countryValForVertex != null && countryValForVertex.QTB_End_System__c == 'Vertex' && countryValForVertex.QTB_Country__c != null && 
                    countryValForVertex.QTB_Country__c.containsIgnoreCase(legalEntityCountry)))
                {
                    isTaxDetailCreated = createTaxDetails(creditNoteLineList);
                }
                else{
                    billingOnlyCountry = true;
                }
                System.debug('isTaxDetailCreated@@'+isTaxDetailCreated);
                System.debug('creditNoteId@@'+crNote.Id);                
                if(!creditNoteLineList.isEmpty() && creditNoteLineList != null && ((Tax && isTaxDetailCreated) || (!Tax))){
                                    return crNote.Id;
                }
                if(billingOnlyCountry){
                    return crNote.Id;
                }
            }
            return null;
        }
        catch(Exception e){
            System.debug('QTB_CreditRebillUtil_Exception@@'+e.getLineNumber()+'-'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);            
            return null;
        }
    }
    
    /***********************************************************************************************************
* Method     : createCreditNoteLines
* Parameters : Id creditonlyInvoicId,Id creditNoteId,boolean Tax,boolean IsLegacyInvoice
* Description: This method Fetch and loop the Invoice line records and create the Credit note line recrods
**************************************************************************************************************/
    @AuraEnabled
    // Added #22304 as part of legacy Invoice build - Added Extra paramater as legacy invoice Boolean for Considering whetehr that is Legacy Invoice or not
    //#30650 Commented one Parameter
    public static List<blng__CreditNoteLine__c> createCreditNoteLines(Id creditonlyInvoicId,Id creditNoteId,boolean Tax/*,boolean islegacy*/){
        System.debug('createCreditNoteLines@@'+'creditonlyInvoicId='+creditonlyInvoicId+',creditNoteId ='+creditNoteId+', Tax = '+Tax);
        List<blng__CreditNoteLine__c> creditNoteLines = new List<blng__CreditNoteLine__c>();
        Map<Id,Decimal> invLineWithInvLineSubtotal = new Map<Id,Decimal>(); //Gitlab-22875
        Map<Id,Decimal> invLineWithInvLineTaxMap = new Map<Id,Decimal>();
        //created map to update QTB_Tax_Override_Amount__c on credit note Line #21202
        Map<Id,Decimal> invLineWithInvLineTaxoverride = new Map<Id,Decimal>();
        //created map to update tax status and tax percentage applied on credit note line #21897
        Map<Id,blng__InvoiceLine__c>invLineMap = new Map<Id,blng__InvoiceLine__c>();
        List<SBQQ__ProductOption__c> productOptionsList = [Select Id, Name,SBQQ__ConfiguredSKU__c,SBQQ__ConfiguredSKU__r.Name, SBQQ__OptionalSKU__c,SBQQ__OptionalSKU__r.Name 
                                                           From SBQQ__ProductOption__c where QTB_Revenue_Allocation__c > 0
                                                           AND SBQQ__OptionalSKU__r.RecordType.Name = 'Global Sales Product'];
        
        Set<String> ProductIdSet = new Set<String>();
        if(!productOptionsList.isEmpty()) {
            for (SBQQ__ProductOption__c  POption : productOptionsList) {
                ProductIdSet.add(POption.SBQQ__OptionalSKU__c);
            }
        } 
        //based on current r Invoice fetching Parent Invoice, and creating CreditNote Lines wrt to Parent Invoice Lines.
       //DefectFix #21478-- added field in query -- QTB_SITAD__c 
       // Added #22304 as part of legacy Invoice build - Queried the Invoice type from Invoice to differenciate whether its legacy Invoice or not
        for (blng__InvoiceLine__c eachInvoiceLine : [SELECT Id,QTB_Tax_Override_Amount__c,blng__Invoice__r.blng__Account__c,blng__Quantity__c,blng__Product__c,blng__Product__r.Name,QTB_Charge_Type__c,
                                                     blng__TotalAmount__c, blng__Subtotal__c,CurrencyIsoCode,blng__StartDate__c,blng__EndDate__c,blng__InvoiceLineStatus__c,
                                                     blng__TaxPercentageApplied__c,blng__TaxStatus__c,blng__TaxCountry__c,blng__TaxAmount__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c, 
                                                     blng__Invoice__r.QTB_Invoice_Type__c
                                                     FROM blng__InvoiceLine__c 
                                                     WHERE blng__Invoice__c =:creditonlyInvoicId AND blng__InvoiceLineStatus__c = 'Posted' /*and
blng__Product__c NOT IN :ProductIdSet */])
        {
            System.debug('eachInvoiceLine@@'+eachInvoiceLine);
            //Creating CreditNoteLines based on InvoiceLines of Parent Invoice
            blng__CreditNoteLine__c crdNoteLine = new blng__CreditNoteLine__c();
            crdNoteLine.blng__CreditNote__c = creditNoteId;
            crdNoteLine.QTB_Account__c = eachInvoiceLine.blng__Invoice__r.blng__Account__c;
            crdNoteLine.QTB_Invoice__c = eachInvoiceLine.blng__Invoice__c;
            crdNoteLine.QTB_InvoiceLine__c = eachInvoiceLine.Id;
            crdNoteLine.blng__Product__c = eachInvoiceLine.blng__Product__c;
            crdNoteLine.CurrencyIsoCode = eachInvoiceLine.CurrencyIsoCode;
            crdNoteLine.blng__StartDate__c = eachInvoiceLine.blng__StartDate__c;
            crdNoteLine.blng__EndDate__c = eachInvoiceLine.blng__EndDate__c;
            crdNoteLine.blng__TaxCountry__c = eachInvoiceLine.blng__TaxCountry__c; 
            crdNoteLine.QTB_Credit_Quantity__c = eachInvoiceLine.blng__Quantity__c;
            crdNoteLine.QTB_CreditOnlyIsTaxable__c = Tax;
            /*if(!Test.isRunningTest()){
                //DefectFix #21478 -- Fix is only for SITAD -- North America(United States & Canada)
                string legalEntityCountry = eachInvoiceLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c;
                if((legalEntityCountry.equalsIgnoreCase('united states') || legalEntityCountry.equalsIgnoreCase('canada')) &&
                   eachInvoiceLine.blng__Invoice__r.blng__Account__r.QTB_SITAD__c){
                       crdNoteLine.blng__Subtotal__c = eachInvoiceLine.blng__Subtotal__c >= 0 ? eachInvoiceLine.blng__Subtotal__c : 0; //if -ve invoice line, then store 0
                       crdNoteLine.QTB_Subtotal_WithNegative__c = eachInvoiceLine.blng__Subtotal__c; //store invoice line subtotal either its +ve or -ve value
                   }
                else if(eachInvoiceLine.blng__Subtotal__c >= 0){ //not allowing -ve line // GIT #22532*/
                    crdNoteLine.blng__Subtotal__c = eachInvoiceLine.blng__Subtotal__c;
               /* } 
            }*/
			//Gitlab US#25626 -- exception fix
			if(eachInvoiceLine.blng__Subtotal__c != null){
            invLineWithInvLineSubtotal.put(eachInvoiceLine.Id,eachInvoiceLine.blng__Subtotal__c); //Gitlab-22875
			 }//Gitlab US#25626 -- exception fix
            if(eachInvoiceLine.blng__TaxAmount__c != null){
            invLineWithInvLineTaxMap.put(eachInvoiceLine.Id,eachInvoiceLine.blng__TaxAmount__c);
			}
            //For updating QTB_Tax_Override_Amount__c on credit note Line #21202
			 //Gitlab US#25626 -- exception fix
            if(eachInvoiceLine.QTB_Tax_Override_Amount__c !=null){
            invLineWithInvLineTaxoverride.put(eachInvoiceLine.Id,eachInvoiceLine.QTB_Tax_Override_Amount__c);
			}
            //For updating blng__taxStatus__c and blng_TaxPercentageApplied__c on credit note line #21897
            invLineMap.put(eachInvoiceLine.Id,eachInvoiceLine);
            creditNoteLines.add(crdNoteLine);
        }
        if(!creditNoteLines.isEmpty() && creditNoteLines.size() > 0){
            system.debug('creditNoteLines@@'+creditNoteLines.size());
            //SBQQ.TriggerControl.disable();
            insert creditNoteLines;
            //SBQQ.TriggerControl.enable();
            //if Credit Note with Tax, the apply tax to creditNoteline and update it, as while insertion tax is not getting added to total amount with tax
            // Added as #22304 part of legacy Invoice build - Added Extra Or Condition for Making Invoice and Line Null values as Null for On Acc credit
            //#30650 Commented Is legacy
            if(Tax /*|| islegacy*/){
                List<blng__CreditNoteLine__c> creditNoteLineUpateList = new List<blng__CreditNoteLine__c>();
                List<blng__CreditNoteLine__c> creditNoteLineUpateList1 = new List<blng__CreditNoteLine__c>();
                for(blng__CreditNoteLine__c crdNoteLine : creditNoteLines){
                    blng__CreditNoteLine__c crdNoteLineObj = new blng__CreditNoteLine__c();
                    crdNoteLineObj.id = crdNoteLine.Id;
                    crdNoteLineObj.QTB_InvoiceLine__c = crdNoteLine.QTB_InvoiceLine__c; //#21897
                    //crdNoteLineObj.blng__CalculateTax__c = Tax; 
                    // Added #22304 as part of legacy Invoice build - Added the below If to Calculate tax as true for only taxable products 
                    //#30650 If Block as everything is same 
                    //if(Tax){
                        crdNoteLineObj.blng__TaxAmount__c = invLineWithInvLineTaxMap.get(crdNoteLine.QTB_InvoiceLine__c);
						//For updating blng__TotalAmount__c on CNL Gitlab-22875
						//Gitlab US#25626 -- exception fix
						Decimal subTotal = invLineWithInvLineSubtotal.get(crdNoteLine.QTB_InvoiceLine__c) != null ? invLineWithInvLineSubtotal.get(crdNoteLine.QTB_InvoiceLine__c) : 0;
						Decimal taxAmt = invLineWithInvLineTaxMap.get(crdNoteLine.QTB_InvoiceLine__c) !=null ? invLineWithInvLineTaxMap.get(crdNoteLine.QTB_InvoiceLine__c) : 0 ;
						crdNoteLineObj.blng__TotalAmount__c =subTotal + taxAmt;
						
                        //For updating QTB_Tax_Override_Amount__c on credit note Line #21202
                        crdNoteLineObj.QTB_Tax_Override_Amount__c = invLineWithInvLineTaxoverride.get(crdNoteLine.QTB_InvoiceLine__c);
                        system.debug('crdNoteLineObj.blng__TaxAmount__c@@' +crdNoteLineObj.blng__TaxAmount__c);
                        crdNoteLineObj.blng__CalculateTax__c = Tax;
                        //updating taxStatus and taxPercentage applied on CNL #21897
                        crdNoteLineObj.blng__TaxStatus__c = invLineMap.get(crdNoteLine.QTB_InvoiceLine__c).blng__TaxStatus__c;
                        crdNoteLineObj.blng__TaxPercentageApplied__c = invLineMap.get(crdNoteLine.QTB_InvoiceLine__c).blng__TaxPercentageApplied__c;
                    //#30650 Commenetd below lines as the references to be there for all legacy Credits and Credit Note Lines
                    //}
                    // Added #22304 as part of legacy Invoice build Added to make all necessary Values as Null for On Account Credit
                    /*if(islegacy){
                        crdNoteLineObj.QTB_Invoice__c = null;
                        crdNoteLineObj.QTB_InvoiceLine__c = null;
                        crdNoteLineObj.blng__InvoiceLine__c = null;
                        //#24075 - Commercial Credit check for Credit note without Tax
                        if(!Tax){
							crdNoteLineObj.blng__CalculateTax__c = false;
						System.debug('Calculate tax on CNL>>>'+crdNoteLineObj.blng__CalculateTax__c);
						}
                    }*/
                    creditNoteLineUpateList.add(crdNoteLineObj);
                }
                // #22875 Clearing the map which is created as part of that story
                    invLineWithInvLineSubtotal.clear();
                if(!creditNoteLineUpateList.isempty()){
                    SBQQ.TriggerControl.disable();
                    update creditNoteLineUpateList;
                    SBQQ.TriggerControl.enable();
                }
                system.debug('creditNoteLineUpateList--->'+creditNoteLineUpateList);
            }
            return creditNoteLines;
        }
        return null;
    }
    
    /***********************************************************************************************************
* Method     : createTaxDetails
* Parameters : List<blng__CreditNoteLine__c> creditNoteLineList
* Description: This method Iterating on TaxDetail based on InvoiceLineIds and  create the tax details creates on Credit note lines
************************************************************************************************************/
    @AuraEnabled
    public static boolean createTaxDetails(List<blng__CreditNoteLine__c> creditNoteLineList){
        System.debug('createTaxDetails@@');
        List<QTB_Tax_Detail__c> taxDetailList =new List<QTB_Tax_Detail__c>();
        Map<Id,blng__CreditNoteLine__c> invoiceToCreditNoteMap =new Map<Id,blng__CreditNoteLine__c>();
        Set<Id> invoiceLineIdSet = new Set<Id>();
        if(!creditNoteLineList.isEmpty()){
            for(blng__CreditNoteLine__c cr : creditNoteLineList)
            {
               //Adding Null check as a part of #Git Issues/29824
               //Adding QTB_InvoiceLine__c null check before adding into invoiceLineIdSet ,invoiceToCreditNoteMap
               if(cr.QTB_InvoiceLine__c !=null){
                    invoiceToCreditNoteMap.put(cr.QTB_InvoiceLine__c, cr);
                    invoiceLineIdSet.add(cr.QTB_InvoiceLine__c);
                }
            } 
         }
        List<String> taxDetailFieldsList = new List<String>(QTB_Tax_Detail__c.SObjectType.getDescribe().fields.getMap().keyset());
        List<QTB_Tax_Detail__c> taxDetailAllRecordList =new List<QTB_Tax_Detail__c>();
        //Adding Null check as a part of #Git Issues/29824
        //Before query the Tax details record put null check for invoiceLineIdSet to avoid Errors
        if(!invoiceLineIdSet.isEmpty())
        {
            string taxDetailQuery = ' SELECT ' +  String.join( taxDetailFieldsList, ',' ) + 
                ' FROM QTB_Tax_Detail__c WHERE QTB_Invoice_Line__c IN : invoiceLineIdSet';
            taxDetailAllRecordList =  Database.query( taxDetailQuery ); 
        }
        
        
        //tax detail record wont be present for some countries(eg. Hongkong has 0 tax) when Invoice line level tax is empty
        //for this scenario -- if TaxDetail records not exist for invoice line, then returning true
        if(taxDetailAllRecordList.isEmpty()){
            return true; 
        }else{
            //Iterating on TaxDetail based on InvoiceLineIds
            for(QTB_Tax_Detail__c taxDetails: taxDetailAllRecordList)                                       
            {
                //Creating the TaxDetail records for CreditNoteLines
                QTB_Tax_Detail__c taxDetail = taxDetails.clone();
                taxDetail.QTB_Credit_Note__c = invoiceToCreditNoteMap.get(taxDetails.QTB_Invoice_Line__c).blng__CreditNote__c;
                taxDetail.QTB_Credit_Note_Line__c = invoiceToCreditNoteMap.get(taxDetails.QTB_Invoice_Line__c).Id;
                taxDetail.QTB_Usage__c = null;
                taxDetail.QTB_Invoice__c = null;
                taxDetail.QTB_Invoice_Line__c = null;  
                taxDetail.OwnerId = System.UserInfo.getUserId(); //Defect Fix Gitlab US #20639
                taxDetailList.add(taxDetail);
            }
        }
        // Inserting tax detail record list
        if (!taxDetailList.isEmpty()) {
            insert taxDetailList;
            System.debug('taxDetailList@@'+taxDetailList.size());
            taxDetailList.clear();
            invoiceToCreditNoteMap.clear();
            return true;
        }
        return false;
    }
}