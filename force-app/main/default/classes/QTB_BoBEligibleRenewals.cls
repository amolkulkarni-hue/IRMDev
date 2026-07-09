/*****************************************************************************************************
* Class: QTB_BoBEligibleRenewals
* Author: Accenture
* Purpose: This a class to show all the Renewal Quotes showing calculations based on Storage Products and Recurring which can be selected in bulk by the user.
* Requirement: Gitlab#10
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*           28/01/2021
*******************************************************************************************************/

/* Commenting the entire code as part of Gitlab #25402 */

public class QTB_BoBEligibleRenewals {
    
    public QTB_BoBEligibleRenewals(){
        
    }
}
/*
    public List<renewalQuoteData> quotewrapperList { get; set; }
    public decimal renewalquotesNetUnitPriceSum {get; set;} 
    public decimal originalquotesNetUnitPriceSum {get;set;}
    public decimal renewalNetPending {get; set;}   
    public decimal originalNetPending {get; set;}   
    public decimal targetEligibleIncreaseAmount {get; set;}
    public decimal targetEligibleIncreasePercent {get; set;}
    public List<renewalQuoteData> selectedQuotes {get; set;}
    public set<id> selectedQuoteids {get; set;}
    public list<SBQQ__Quote__c> renewalQuotesList;
    public string userCurrency {get; set;}
    
    //This list - quoteToShow is defined to support pagination to limit data per page
    @TestVisible
    public List<renewalQuoteData> quoteToShow { get; set; }     
    
    
    //Navigation Variables
    Integer counter = 0;       // To track number of records parsed
    public Integer limitSize = 20;    // Number of records to be displayed
    Integer totalSize = 0;     // To store the total number of records available
    
    
    public QTB_BoBEligibleRenewals() {
        renewalquotesNetUnitPriceSum = 0;  
        originalquotesNetUnitPriceSum = 0;
        renewalNetPending = 0;       
        originalNetPending = 0;        
        targetEligibleIncreaseAmount =0;
        targetEligibleIncreasePercent =0;
        quoteToShow = new List<renewalQuoteData>();        
        quotewrapperList = new List<renewalQuoteData>();
        selectedQuotes = new List<renewalQuoteData>();
        selectedQuoteids = new set<id>();
        renewalQuotesList = new list<SBQQ__Quote__c>();
        userCurrency  = userInfo.getDefaultCurrency();
        //This query fetches renewal quotes created by active session user for recurring products
        for (SBQQ__Quote__c quote : [SELECT id,Name,QTB_Account_Name__c,QTB_NetAmount__c,SBQQ__Opportunity2__r.QTB_Days_Until_Renewal_Notice__c,
                                     QTB_QL_Recurring_Products_Net_Unit_price__c,ApprovalStatus__c,SBQQ__Status__c,
                                     QTB_BoB_Proposed_Annual_Value_Of_Storage__c,QTB_BoB_Proposed_Annual_Value_Of_Renewal__c,
                                     QTB_BoB_AnnValOf_Original_for_Storage__c,QTBBoB_AnnValueOf_Original_for_Renewable__c,QTB_QL_Net_Amount_Conversion__c,
                                     SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r.QTB_QL_Recurring_Products_Net_Unit_price__c,
                                     SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r.ApprovalStatus__c,
                                     SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r.QTB_QL_Net_Amount_Conversion__c,  
                                     SBQQ__Opportunity2__r.Primary_Product_Line__c,QTB_Price_Schedule_Term__c,QTB_Multi_Year_Check__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c = :QTB_Constants.QUOTE_TYPE_RENEWAL  
                                     AND SBQQ__Primary__c = TRUE AND  QTB_Multi_Year_Check__c=False AND OwnerId =: UserInfo.getUserId()
                                     ORDER BY SBQQ__Opportunity2__r.Primary_Product_Line__c]) 
        {
            if(quote.SBQQ__Status__c == QTB_Constants.QUOTE_DRAFT_STATUS){
                RenewalQuoteData quotewr = new RenewalQuoteData(quote, false);
                quotewr.defaultCalculatedFields();
                quotewrapperList.add(quotewr);
            }
            //Calculate Net Price & Net Unit Price for Pending renewal, Approved renewal or Renewal Quote
            if(quote.QTB_QL_Recurring_Products_Net_Unit_price__c <> NULL){
                if(quote.ApprovalStatus__c == QTB_Constants.APPROVAL_STATUS_PENDING){
                    renewalNetPending = renewalNetPending + quote.QTB_QL_Net_Amount_Conversion__c;
                }
                else{ 
                renewalquotesNetUnitPriceSum = renewalquotesNetUnitPriceSum+quote.QTB_QL_Net_Amount_Conversion__c;
                }
            }
            //Calculate Original Net Price & Net Unit Price for Pending renewal, Approved renewal or Renewal Quote
            if(quote?.SBQQ__Opportunity2__r?.SBQQ__RenewedContract__r?.SBQQ__Quote__r?.QTB_QL_Recurring_Products_Net_Unit_price__c <> NULL){
                if(quote.ApprovalStatus__c == QTB_Constants.APPROVAL_STATUS_PENDING){
                    originalNetPending = originalNetPending+ quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r.QTB_QL_Net_Amount_Conversion__c;
                }
                originalquotesNetUnitPriceSum = originalquotesNetUnitPriceSum + 
                    quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r.QTB_QL_Net_Amount_Conversion__c;
            }
        }
        List<CurrencyType> currencyTypeList = [select id,IsoCode,ConversionRate from CurrencyType where isActive = true and IsoCode =: userCurrency] ;
        Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
        for(CurrencyType c : currencyTypeList) {
            isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
        }
        //Currency Conversion for Prices using user currency
        if(isoWithRateMap.containsKey(userCurrency)){
            renewalNetPending = renewalNetPending*isoWithRateMap.get(userCurrency);            
            renewalquotesNetUnitPriceSum=renewalquotesNetUnitPriceSum*isoWithRateMap.get(userCurrency);
            originalNetPending=originalNetPending*isoWithRateMap.get(userCurrency);
            originalquotesNetUnitPriceSum=originalquotesNetUnitPriceSum*isoWithRateMap.get(userCurrency);
            
        }
       
        //Calculation of Target Eligible increase amount
        if(renewalquotesNetUnitPriceSum <> NULL && originalquotesNetUnitPriceSum <> NULL){
            targetEligibleIncreaseAmount = renewalquotesNetUnitPriceSum - originalquotesNetUnitPriceSum;
        }
        //Calculation of Target Eligible Increase Percent
        if(targetEligibleIncreaseAmount <> NULL && renewalquotesNetUnitPriceSum <> NULL && renewalquotesNetUnitPriceSum != 0){
            targetEligibleIncreasePercent = (targetEligibleIncreaseAmount/renewalquotesNetUnitPriceSum)*100;  
        }
        //Pagination Limit of quote display data  
        totalSize = quotewrapperList.size();
        if ((counter + limitSize) <= totalSize) {
            for (Integer i = 0; i < limitSize; i++)
                quoteToShow.add(quotewrapperList.get(i));
        } else {
            for (Integer i = 0; i < totalSize; i++)
                quoteToShow.add(quotewrapperList.get(i));
        }
        //Store Selected Quote ID's for submission
        for(RenewalQuoteData eachQuoteWrapper: quoteToShow){
            if(eachQuoteWrapper.selected == True){
                selectedQuoteids.add(eachQuoteWrapper.record.id);
            }
            
        }
        system.debug('selectedQuoteids'+selectedQuoteids);
    }
    
    //Navigation methods for pagination(previous and next)
    
    // Next button
    public void next() {
        quoteToShow.clear();
        counter = counter + limitSize;
        if ((counter + limitSize) <= totalSize) {
            for (Integer i = counter; i < (counter + limitSize); i++) {
                quoteToShow.add(quotewrapperList.get(i));
            }
        } else {
            for (Integer i = counter; i < totalSize; i++) {
                quoteToShow.add(quotewrapperList.get(i));
            }
        }
    }
    
    // Previous button
    public void previous() {
        quoteToShow.clear();
        counter = counter - limitSize;
        for (Integer i = counter; i < (counter + limitSize); i++) {
            quoteToShow.add(quotewrapperList.get(i));
        }
    }
    //Method to disable next button depending upon limit reached
    public Boolean getDisableNext() {
        if ((counter + limitSize) >= totalSize){
            return true;
        }
        else{
            return false;
        }
    }
    //Method to disable previous button if on 1st page
    public Boolean getDisablePrevious() {
        if (counter == 0){
            return true;
        }
        else{
            return false;
        }
    }
    
    //Method to validate quote status and store quotes for approval submission
    public void submitAll(){ 
        for(RenewalQuoteData eachQuoteWrapper: quoteToShow){  
            if(eachQuoteWrapper.selected == True){
                eachQuoteWrapper.record.SBQQ__Status__c ='Queued for Approval';
                renewalQuotesList.add(eachQuoteWrapper.record);
                selectedQuoteids.add(eachQuoteWrapper.record.id);
            }
            
        }
        //Update renewal quote list
        if(!renewalQuotesList.isEmpty()){
            SBQQ.TriggerControl.disable();
            update renewalQuotesList;
            SBQQ.TriggerControl.enable();
        }
        system.debug('selectedQuoteids:'+selectedQuoteids);
        //Batch execustion of submission of renewal quote
        database.executeBatch(new QTB_BulkSubmitApprovalBatch(selectedQuoteids), 1);
    }
    
    //wrapper class
    public with sharing class RenewalQuoteData {
        public Boolean selected { get; set; }
        public SBQQ__Quote__c record { get; private set; }
        public Decimal originalStorage { get; set; }
        public Decimal proposedRenewalStorage { get; set; }
        public Decimal valChangeStorage { get; set; }
        public Decimal percentageStorage { get; set; }
        public Decimal originalRecurring { get; set; }
        public Decimal proposedRecurringQriginal { get; set; }
        public Decimal valChangeRecurring { get; set; }
        public Decimal percentageRecurring { get; set; }
        
        //constructor
        public RenewalQuoteData(SBQQ__Quote__c quote, Boolean exists) {
            this.record = quote;
            this.selected = exists;
            this.proposedRenewalStorage = quote.QTB_BoB_Proposed_Annual_Value_Of_Storage__c;
            this.proposedRecurringQriginal = quote.QTB_BoB_Proposed_Annual_Value_Of_Renewal__c;       
        }
        //Class to calculate Default calculate fields    
        public void defaultCalculatedFields() {
            
            Decimal originalStorageTotal = this.record.QTB_BoB_AnnValOf_Original_for_Storage__c;
            Decimal originalRecurringTotal = this.record.QTBBoB_AnnValueOf_Original_for_Renewable__c;
            //Calculate Original Storage, Value Storage change, Percentage storage
            if (originalStorageTotal <> null) {
                this.originalStorage = originalStorageTotal;
                if (this.proposedRenewalStorage <> null) {
                    this.valChangeStorage = originalStorageTotal - this.proposedRenewalStorage;
                    if (this.proposedRenewalStorage <> 0) {
                        Decimal percentageStorageCalc =  (this.valChangeStorage / this.proposedRenewalStorage)*100;
                        this.percentageStorage = percentageStorageCalc;
                    }
                    else{
                        this.percentageStorage = 0;
                    }
                }
            }
            //Calculate Original recurring, Value Change Recurring, Percentage Recurring
            if (originalRecurringTotal <> null) {
                this.originalRecurring = originalRecurringTotal;
                if (this.proposedRecurringQriginal <> null) {
                    this.valChangeRecurring =
                        originalRecurringTotal - this.proposedRecurringQriginal;
                    if (originalRecurringTotal <> 0) {
                        Decimal percentageRecurringCalc = (this.valChangeRecurring / originalRecurringTotal)*100;
                        this.percentageRecurring = percentageRecurringCalc;
                    }                    
                    else{                                              
                        this.percentageRecurring = 0;
                    }                
                }            
            }        
        }
        
    }
}
*/