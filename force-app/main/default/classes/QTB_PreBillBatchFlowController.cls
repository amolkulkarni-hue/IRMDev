/*****************************************************************************************************
* Class         : QTB_PreBillBatchFlowController 
* Test Class    : QTB_PreBillBatchFlowController_Test
* Author        : Accenture
* Purpose       : This is a class called from prebill batches flow to kick start the pre bill batches
* Change History: 24/5/2021
* Developer                 Date           Description
* -------------------------------------------------------------------------------------------
* Accenture
* Shailesh(Virtusa)       12/26/2023    Gitlab US#20367 - Excluding Pre-bill Run for BillingOnlyCountries for Regular & Credit-Rebill Invoice generation process
* Ramesh/Abdul            26/07/2024    Gitlab US#24172 (Credit/Rebill Billnow)
* Parth					  28/10/2024    Gitlab US#25905 (Ad-Hoc order BillNow)
* Parth					  07/01/2025    Gitlab US#28211 - added existing code into new methods (checkRebillOrAdHoc, executePreBill) to use the same logic from QTB_ExchangeRateFieldsUpdatesForPrebill class		
*******************************************************************************************************/
public class QTB_PreBillBatchFlowController {
    @InvocableMethod
    public static void runPreBillBatches(list <FlowInputs> request)
    {
        try
        {
            set<String>invBatchValues = new set<String>(request[0].invoiceBatches.split(';'));
            String PENDING = QTB_Constants.INVOICE_STATUS_PENDING_BILLING;
            // querying on usagesummary to check if contractRate is applicable if yes then calling QTB_ExchangeRateFieldsUpdatesForPrebill batch class before prebill logic
            List<blng__UsageSummary__c>UsgSummaryLst = [Select id,blng__PreratedAmount__c,blng__UnitPrice__c,blng__TotalQuantity__c,blng__AppliedUnitPrice__c,blng__Account__r.QTB_Contract_Currency__c,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Subtotal__c,blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c,
                                                        blng__MatchingId__c,QTB_Contracted_Currency_Rate__c,blng__NextBillingDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__MatchingAttribute__c,blng__Account__r.CurrencyIsoCode from blng__UsageSummary__c where blng__Order__r.blng__InvoiceBatch__c in :invBatchValues and
                                                        blng__Subtotal__c != Null and blng__Account__r.QTB_Hold_Billing__c = False and blng__OrderProduct__r.SBQQ__Activated__c=True and blng__Status__c = 'Queued For Invoice'  and 
                                                        blng__InvoiceRunProcessingStatus__c=:PENDING and blng__Account__r.QTB_Contract_Entity__r.QTB_Contract_Currency_Applicable__c = true and
                                                        blng__Account__r.QTB_isContractRateApplicable__c = true and blng__NextBillingDate__c <=:request[0].targetDate Limit 1];
            
            system.debug('Prebill class--->'+UsgSummaryLst);
            if(UsgSummaryLst.isEmpty()){
                executePreBill(request);
            }
            else{
                QTB_ExchangeRateFieldsUpdateForPreBill.runPreBillExchangeRateBatch(request);
            }
            
            
        }
        catch(Exception e)
        {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_PreBillBatchFlowController');
        }
    }
    
    public class FlowInputs
    {
        @InvocableVariable    
        public Id prebillBatchRunRecordId;
        
        @InvocableVariable
        public String invoiceBatches;
        
        @InvocableVariable
        public Date targetDate;
        
        @InvocableVariable
        public String orderCategory;

        @InvocableVariable
        public date invoiceDate;
        
        @InvocableVariable
        public decimal parentInvoiceContractCurrency;
        
        @InvocableVariable
        public string invocieType;
    }
    /*********************************************************************************************************
Method Name: executePreBill
Parameters: List<FlowInputs>
Return Type: void
Requirement: 
Description: Moved the existig code into this method as this method will be called from QTB_ExchangeRateFieldsUpdatesForPrebill class as well
**********************************************************************************************************/
    public static void executePreBill(List<FlowInputs>request){
        
        boolean isBillingOnlyCountry = False;
        boolean isSITAD = False;
        boolean isSplitRebill = false; ///Epic 2988
        string rebillBillingCountry;
        String primaryProductLine; //Epic 3016
        List<Id>rebillOrderIdLst = new List<Id>();
        // Gitlab US#24172 (Credit/Rebill Billnow)
        // Gitlab US#25905 (Ad-Hoc order BillNow)
        if(request != null && (request[0].invoiceBatches.containsIgnoreCase('Rebill Run') || request[0].orderCategory == 'Ad-Hoc')) 
        {
            List<QTB_Bill_Flow_Controller__c> billFlowList = [SELECT Id,QTB_Rebill_Invoice__c,QTB_Rebill_Order__c,QTB_Rebill_Order__r.QTB_OrderCategory__c,QTB_Target_Date__c,QTB_Rebill_Order__r.blng__InvoiceBatch__c,
                                                              QTB_Rebill_Invoice__r.blng__Account__r.W_L__c,QTB_Rebill_Order__r.AccountId,QTB_Rebill_Order__r.Account.W_L__c,
                                                              QTB_Rebill_Order__r.Account.QTB_Legal_Entity_Country__c,QTB_Rebill_Order__r.Account.QTB_Source_Opportunity__c,QTB_Rebill_Order__r.Account.QTB_Source_Opportunity__r.Primary_Product_Line__c 
                                                              FROM QTB_Bill_Flow_Controller__c 
                                                              WHERE Id = :request[0].prebillBatchRunRecordId WITH SYSTEM_MODE];// Gitlab US#24172 (Credit/Rebill Billnow) //Epic 3016 added in query
            // Gitlab US#24172 (Credit/Rebill Billnow)
            if(!billFlowList.isEmpty() && billFlowList[0].QTB_Rebill_Order__c != null){
                rebillOrderIdLst.add(billFlowList[0].QTB_Rebill_Order__c);
                
                if (billFlowList[0].QTB_Rebill_Order__r.Account != null &&
                    billFlowList[0].QTB_Rebill_Order__r.Account.QTB_Legal_Entity_Country__c != null) {
                        rebillBillingCountry = billFlowList[0].QTB_Rebill_Order__r.Account.QTB_Legal_Entity_Country__c.toLowerCase();
                    }
                //Start Epic #3016
                if(billFlowList[0].QTB_Rebill_Order__r.Account.QTB_Source_Opportunity__c != null && billFlowList[0].QTB_Rebill_Order__r.Account.QTB_Source_Opportunity__r.Primary_Product_Line__c != null)
                {
                    primaryProductLine =billFlowList[0].QTB_Rebill_Order__r.Account.QTB_Source_Opportunity__r.Primary_Product_Line__c; 
                }
                //End Epic #3016
            }
        }
        //GitLab #26040 - checking if Invoice schedular Invoicebatch related to SITAD
        if(request != null && request[0].invoiceBatches.containsIgnoreCase('SecureITAD')) 
        {
            isSITAD = true;
        }
        //Fetching all billingOnly countries from custom setting
        Map<String, QTB_Billing_Countries__c> billCountryCustomSetting = QTB_Billing_Countries__c.getAll();
        for(FlowInputs flow : request)
        {
            String invoiceBatch = (flow.invoiceBatches).toLowerCase(); //setting invoiceBatch value in lower case
            //Iterating on billingOnly custom setting
            for(String billingCountry : billCountryCustomSetting.keySet()){
                billingCountry = billingCountry.toLowerCase(); // setting billingCountry to lower case
                if(invoiceBatch.contains(billingCountry)){
                    isBillingOnlyCountry = true;
                    break;
                }
                //Gitlab US#22511 -- instead of equals to change to contains of "Rebill Run"
                // Gitlab US#24172 (Credit/Rebill Billnow)
                else if(invoiceBatch.containsIgnoreCase('Rebill Run') && rebillBillingCountry != null && (rebillBillingCountry.containsIgnoreCase(billingCountry) || Label.QTB_SITAD_Countries.containsIgnoreCase(rebillBillingCountry)))// GitLab US #28779 added sitad country check as part of this defect
                {
                    //Start Epic #3016 Adding check for fuel surcharge product- applicable only for NA DM (Usa and canada )
                    System.debug('>>>elseiff');
                    if(System.label.QTB_NA_Countries.containsIgnoreCase(rebillBillingCountry) && !primaryProductLine.contains('DM SITAD'))
                    {
                        System.debug('>>ifuss');
                        isBillingOnlyCountry = false;
                        break;	
                    }
                    //End Epic #3016
                    isBillingOnlyCountry = true;
                    break;
                }
            }
            //For BillingOnlyCountry Prebill is not needed, so directly updating the BillFlowController status to "Completed"
                //GitLab #26040 - We are skipping the prebill run for SITAD becuase it is not required for SITAD
                if(isBillingOnlyCountry || isSITAD){
                        update new QTB_Bill_Flow_Controller__c(Id = flow.prebillBatchRunRecordId, QTB_PreBill_Run_status__c = 'Completed');
                        //Gitlab US#22511 -- instead of equals to change to contains of "Rebill Run"
                        // Gitlab US#24172 (Credit/Rebill Billnow)
                        // Gitlab US#25905 (Ad-Hoc order BillNow)
                        if((flow.invoiceBatches.contains('Rebill Run') || flow.orderCategory == 'Ad-Hoc') &&  !rebillOrderIdLst.isEmpty() && rebillOrderIdLst != null)
                        {  
                            //QTB_UsagesForRebill.runBillNow(rebillOrderIdLst);
                            //Epic 2988 added this check: while doing SplitRebill -> we are getting Too many queueable jobs added to the queue: 2 error the below class calling 2times
                            if(request.size() == 1)
                            {
                                QTB_UsagesForRebill.runBillNow(rebillOrderIdLst);
                            }
                            else{
                                System.debug('>>spiltrebill');
                                isSplitRebill = true;
                            }
                           //closed Epic 2988
                        } 
                    }
                    else{ // other than BillingOnly countries pre-bill logic will work as earlier
                        QTB_ProductDiscountBatch pdbatch = new QTB_ProductDiscountBatch(flow.invoiceBatches,flow.targetDate,flow.prebillBatchRunRecordId);
                        Database.executeBatch(pdbatch);
                    }
        }
        //Epic 2988
        if(isSplitRebill)
        {
            System.debug('>>spiltrebilltrue');
            QTB_UsagesForRebill.runBillNow(rebillOrderIdLst);
        }
        //close /Epic 2988
    }  
}