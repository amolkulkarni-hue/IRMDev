/*****************************************************************************************************
* Class         : QTB_UsageHelpers
* Test Class    : QTB_UsageHelper_Test
* Author        : Accenture
* Purpose       : This is a helper class for all business logic related to Usage object
* Requirement   : QTB-14/SFCPQBLG 62
* Change History: 6/02/2020
* Developer         Date           Description
* ------------------------------------------------------------------------------------------- 
*                    5/22/2020
* Gopi/Shailesh      06/30/2022     Gitlab US #9256 Credit & Rebill -- Added PlatformEvent & Update Usage & UsageSummary quantity/unit price logic
* (Shailesh)Virtusa  12/27/2023     Gitlab US #20554 -- Exception fix
* (Parth)Virtusa     03/29/2024     Gitlab #22507 - Deletion of usages is not updating the amount on usage summary
* (Renuka Prasad)TCS 07/31/2024     Gitlab US #25172 -- Usage Re-Rate, usage summary recalculation
* Parth              10/28/2024     Gitlab #25905 update order subtoatl based on usage prerated amount
* Virtusa		     10/28/2025     Gitlab US #18998 code optimization 
*******************************************************************************************************/
public with sharing class QTB_UsageHelper {
    
    private static final String CLASSNAME = QTB_UsageHelper.class.getName();
    // Recursion guard: track processed UsageSummary Ids for makeFieldsNonEditableForProcessed
    private static Map<Id, Boolean> USG_SUM_GUARD = new Map<Id, Boolean>();
    @TestVisible private static void clearUsgSumGuard() { USG_SUM_GUARD.clear(); }
    
/***********************************************************************************************************
* Method : process
* Parameters: List<blng__Usage__c>, Map<ID,blng__Usage__c>, System.TriggerOperation
* Requirement :
* Start Date :
* Author : Accenture
* Description: Generic method to handle all operations on the usage Records
* Virtusa		     10/28/2025     Gitlab US #18998 code optimization added new variable for single DML/object
**************************************************************************************************************/
    public static void process(List<blng__Usage__c> newItems, Map<ID,blng__Usage__c> oldMap, System.TriggerOperation operationType) {
        
        List<blng__Usage__c> usageList = new List<blng__Usage__c>();
        List<QTB_Usage_Suspense__c> newErrorUsagesMirrorObjList= new List<QTB_Usage_Suspense__c>(); // Gitlab US #18998 appended List
        List<String> excludedProfilesList = System.Label.QTB_LockdownExcludedProfiles.split(','); // Gitlab US #18998 Added System.Label instead of .Label
        List<QTB_Field_Mapping__mdt> metadataList = new List<QTB_Field_Mapping__mdt>(); 
        List<User> lgUserList = new List<User>();
        List<QTB_OrderProduct_Usage_Rebill_Platform__e> refreshRecordEventsList = new List<QTB_OrderProduct_Usage_Rebill_Platform__e>();// Gitlab 9256
        List<Order> orderforCategoryList = new List<Order>();
        List<QTB_Usage_Suspense__c> finalUsageSuspenseInsertList = new List<QTB_Usage_Suspense__c>();//Gitlab US #18998 created a Map for inserting QTB_Usage_Suspense__c only once when ever the QTB_Usage_Suspense__c is to be Updated(New Structure of code)
        
        String dataExchangeUserName = System.Label.Data_Exchange_Integration_User; // #28503
        Set<ID> blngAccountIdsSet = new Set<ID>();
        Set<blng__Usage__c> usageIdsForReBillSet = new Set<blng__Usage__c>();
        Set<ID> usgSumIdsSet = new Set<ID>(); // to store usageSummary and store it for the method updateUsageUsageSummary
        Set<ID> orderPrdIdsSet = new Set<ID>(); // to store id of orderItem and store it for the method updateUsageUsageSummary
        //#20867 Tiered flag on usage summary
        Set<ID> tieredUsgSumIdsSet = new Set<ID>();
        Set<ID> oldNullAndNewTieredUsgSummIdsSet = new Set<ID>();
        Set<ID> oldTierAndNewNullUsgSummIdsSet = new Set<ID>();
        Set<ID> orderIdSet = new Set<ID>(); // to capture order whose category = adhoc
        Set<ID> usgSummIdSet = new Set<ID>(); // to capture usage summary from the usages
        Set<ID> usageOrderIdsSet = new Set<ID>(); // to capture order from the usages
        Boolean isRebill = false;
        Boolean revReportFieldsUpdated = false; // #28503
        Boolean callValidateProductIdentifierOne = false; // Gitlab #30390
        Boolean isDataExchangeUser = System.userInfo.getName().contains(dataExchangeUserName); // #Gitlab 28503 // Gitlab US #18998 added System. do not change to containsIgnorecase based upon peer review comments

        Map<ID,Decimal> usageSummaryReRateAmountMap = new Map<ID,Decimal>(); //Changes for the Story #25172 map usageSummaryReRateAmountMap, Key = UsageSummaryId & Value = ReRatedAmount
        Map<ID,Decimal> usageSummaryReRateQuantityMap = new Map<ID,Decimal>();//Story #25172 map usageSummaryReRateQuantityMap, Key = UsageSummaryId & Value = ReRatedQuantity
        Map<ID,Order> finalOrderUpdateMap = new Map<ID,Order>();//Gitlab US #18998 created a Map for updating Order only once when ever the Order is to be Updated(New Structure of code)
        Map<ID,blng__UsageSummary__c> finalUsageSummaryUpdateDisableTriggerMap = new Map<ID,blng__UsageSummary__c>();//Gitlab US #18998 created a Map for updating blng__UsageSummary__c only once when ever the blng__UsageSummary__c is to be Updated(New Structure of code)
        Map<ID,OrderItem> finalOrderItemUpdateMap = new Map<ID,OrderItem>();//Gitlab US #18998 created a Map  for updating OrderItem only once when ever the OrderItem is to be Updated(New Structure of code)
        Map<ID,Decimal> usgSummaryToPreratedUnitPriceMap = new Map<ID,Decimal>(); // GITLAB #34411
        switch on operationType{
            when AFTER_DELETE {
                metadataList = QTB_Utils.GetFieldMapMetadata('blng__Usage__c', 'QTB_Usage_Suspense__c','Usage');
            }
        }
        for (blng__Usage__c us : newItems){
            switch on operationType{
                when BEFORE_INSERT {
                    if(us.blng__Account__c != null && us.blng__Order__c!=null){//Gitlab US #18998 null check // Gitlab #28503 The below logic added to check the rebill orders linked to usages
                        blngAccountIdsSet.add(us.blng__Account__c); // 28503
                        usageList.add(us);
                        usageOrderIdsSet.add(us.blng__Order__c );
                    }
                    /*  #30931 - To keep blng__PreratedAmount__c value IN sync with calculation prerated unit price ad prerated quantity 
                    AND avoid firing validation marking prerated Amount to 2 Decimal places on insert or update */
                 /*   if(us.blng__PreratedAmount__c != null && !isDataExchangeUser){
                        us.blng__PreratedAmount__c = us.blng__PreratedAmount__c.setScale(2, RoundingMode.HALF_UP);//Gitlab US #18998 setScale already returns a Decimal with the desired scale and rounding.
                    } */
                }
                when AFTER_INSERT{
                    if(us.blng__UsageSummary__c!=null && us.QTB_Price_Tier__c != null && us.QTB_Price_Tier__c !='None'){ //Gitlab US #18998 null check
                        tieredUsgSumIdsSet.add(us.blng__UsageSummary__c);  //Gitlab 20867 Tiered flag Set on usage summary
                    }
                    // as part of #34465 , removed "&& us.blng__Order__r.QTB_OrderCategory__c == 'Ad-Hoc'" as it is coming as null and need to query order data again
                    if(us.blng__PreratedAmount__c != null && us.blng__Order__c != null ){ //Gitlab US #19002 Add to the set only for AdHoc Orders
                        orderIdSet.add(us.blng__Order__c); //25905 update order subtoatl based on usage prerated amount  
                    }
                }
                when BEFORE_UPDATE{
                    //Gitlab -#30390  if updating product identifier to blank or null fire the validation
                    //updated the condition with adding not rebill check as IN rebill scenario this validation is getting fired
                    if(us.QTB_Usage_Type__c !='Rebill' && (us.QTB_Product_Identifier_1__c == null || String.isBlank(us.QTB_Product_Identifier_1__c))){
                        us.addError(System.Label.QTB_ProductIdentifierValidation);
                    }
                    // Gitlab 9256 // Credit ReBill By IRM/Virtusa  // Condition Checking
                    // 1. Condition Checking- existing usage is have quanity & user trying to add pre-reated quantity
                    // 2. Condition Checking -- existing usage is have pre-reated quantity & user is trying to add quantity
                    // Defect fix Gitlab US #20554 -- Prerated quantity & quantity not allowed together
                    if(us.QTB_Usage_Type__c == 'Rebill'
                    &&(oldMap.get(us.ID).blng__Quantity__c != us.blng__Quantity__c && us.blng__Quantity__c > 0 && us.blng__PreratedQuantity__c != null && us.blng__PreratedQuantity__c != 0) 
                        ||(oldMap.get(us.ID).blng__PreratedQuantity__c != us.blng__PreratedQuantity__c && us.blng__PreratedQuantity__c != 0 && us.blng__Quantity__c != null && us.blng__Quantity__c > 0)){
                        //us.addError('Quantity AND Prerated Quantity both can not be change.');
                        us.addError(System.Label.QTB_QuantityandPreratedQuantity); // Gitlab US #18998 Added CustomLabels
                    }
                    else if(us.QTB_Usage_Type__c == 'Rebill'  // Defect fix Gitlab US #20554 -- Prerated amount & quantity not allowed together
                    &&(oldMap.get(us.ID).blng__Quantity__c != us.blng__Quantity__c && us.blng__Quantity__c > 0 && us.blng__PreratedAmount__c != null && us.blng__PreratedAmount__c != 0 )
                        ||(oldMap.get(us.ID).blng__PreratedAmount__c != us.blng__PreratedAmount__c && us.blng__PreratedAmount__c != 0 && us.blng__Quantity__c != null && us.blng__Quantity__c > 0)){
                        //us.addError('Quantity AND Prerated Amount both can not be change.');
                        us.addError(System.Label.QTB_QuantityandPreratedAmount); // Gitlab US #18998 Added CustomLabels
                    }
                    // Gitlab US #30094 - Validation to not allow user's to update Unit of Measure field FROM blank to any value or FROM one value to other value   
                    if(us.blng__UnitOfMeasure__c != oldMap.get(us.ID).blng__UnitOfMeasure__c){
                        us.addError(System.Label.QTB_Unit_Of_MeasureValidation);
                    }
                    /*Change for 26921 - START*/
                    if(us.blng__UsageSummary__c!=null && us.blng__Status__c == QTB_Constants.USAGE_STATUS_PROCESSED){
                        usgSummIdSet.add(us.blng__UsageSummary__c); //Gitlab US #18998 added nullcheck
                    }
                    if(us.blng__Order__c != null){
                        usageOrderIdsSet.add(us.blng__Order__c);
                    }
                    if(!isDataExchangeUser && (us.QTB_Start_Date_MRC__c != oldMap.get(us.ID).QTB_Start_Date_MRC__c 
                        || us.QTB_End_Date_MRC__c != oldMap.get(us.ID).QTB_End_Date_MRC__c
                        || us.blng__PreratedQuantity__c != oldMap.get(us.ID).blng__PreratedQuantity__c
                        || us.blng__PreratedAmount__c != oldMap.get(us.ID).blng__PreratedAmount__c
                        || us.QTB_Prerated_Unit_Price__c != oldMap.get(us.ID).QTB_Prerated_Unit_Price__c
                        || us.QTB_Term__c != oldMap.get(us.ID).QTB_Term__c
                        || us.QTB_Actual_Quantity__c != oldMap.get(us.ID).QTB_Actual_Quantity__c)){
                        revReportFieldsUpdated = true;
                    }
                    //Gitlab -#30390 if updating product identifier to value call the method to check valid or invalid product identifier AND fir validation
                    if(us.QTB_Product_Identifier_1__c !=null && us.QTB_Product_Identifier_1__c != oldMap.get(us.ID).QTB_Product_Identifier_1__c){
                        callValidateProductIdentifierOne = true;
                    }
                    /*Change for 26921 - END*/
                    if(us.blng__Account__c !=null && us.QTB_Legal_Entity_Country__c == null && us.blng__Status__c == QTB_Constants.USAGE_STATUS_PROCESSED){
                        blngAccountIdsSet.add(us.blng__Account__c);
                        usageList.add(us);
                    }
                    // Gitlab 9256 // Credit ReBill By IRM/Virtusa
                    if(us.QTB_Usage_Type__c == 'Rebill' 
                    && (us.blng__Quantity__c != oldMap.get(us.ID).blng__Quantity__c || us.blng__PreratedQuantity__c != oldMap.get(us.ID).blng__PreratedQuantity__c 
                        || us.blng__PreratedAmount__c != oldMap.get(us.ID).blng__PreratedAmount__c )){
                            
                        usageIdsForReBillSet.add(us);
                        usgSumIdsSet.add(us.blng__UsageSummary__c);
                        orderPrdIdsSet.add(us.blng__OrderProduct__c);
                    }
                    if(us.QTB_Price_Tier__c != oldMap.get(us.ID).QTB_Price_Tier__c){ //Gitlab #20344 Tiered based usage warning Set
                        us.QTB_Usage_Alert__c = true;
                    }
                }
                when AFTER_UPDATE{
                    // Gitlab 9256 // Credit ReBill By IRM/Virtusa //Gitlab US #18998 added null checks
                    if(us.blng__UsageSummary__c!=null && us.blng__OrderProduct__c!=null && us.QTB_Usage_Type__c == 'Rebill' && (us.blng__Quantity__c != oldMap.get(us.ID).blng__Quantity__c 
                        || us.blng__PreratedQuantity__c != oldMap.get(us.ID).blng__PreratedQuantity__c
                        || us.blng__PreratedAmount__c != oldMap.get(us.ID).blng__PreratedAmount__c)){
                        refreshRecordEventsList.add(new QTB_OrderProduct_Usage_Rebill_Platform__e(QTB_Record_Id__c = us.ID));
                        usageIdsForReBillSet.add(us);
                        usgSumIdsSet.add(us.blng__UsageSummary__c);
                        orderPrdIdsSet.add(us.blng__OrderProduct__c);
                    }
                    //Gitlab #20867 Tiered flag Set on usage summary & Old Usage having null AND now changed to tiered value //Gitlab US #18998 added null checks
                    if(us.blng__UsageSummary__c!=null && (oldMap.get(us.ID).QTB_Price_Tier__c != us.QTB_Price_Tier__c) && (oldMap.get(us.ID).QTB_Price_Tier__c == null || oldMap.get(us.ID).QTB_Price_Tier__c == 'None') 
                    && (us.QTB_Price_Tier__c != null && us.QTB_Price_Tier__c != 'None')){
                        oldNullAndNewTieredUsgSummIdsSet.add(us.blng__UsageSummary__c);
                    }
                    //Gitlab #20867 Old Usage having value AND now changed to null value //Gitlab US #18998 added null checks
                    if(us.blng__UsageSummary__c!=null && (oldMap.get(us.ID).QTB_Price_Tier__c != us.QTB_Price_Tier__c) && (oldMap.get(us.ID).QTB_Price_Tier__c != null 
                    && oldMap.get(us.ID).QTB_Price_Tier__c != 'None') && (us.QTB_Price_Tier__c == null || us.QTB_Price_Tier__c == 'None')){
                        oldTierAndNewNullUsgSummIdsSet.add(us.blng__UsageSummary__c);
                    }
                    //Gitlab #25905 update order subtoatl based if amount get changed
        	        // as part of #34465 , removed "&& us.blng__Order__r.QTB_OrderCategory__c == 'Ad-Hoc'" as it is coming as null and need to query order data again
                    if(us.blng__PreratedAmount__c != null && us.blng__Order__c != null && us.blng__PreratedAmount__c != oldMap.get(us.ID).blng__PreratedAmount__c){  //Gitlab US #19002 Add to the set only for AdHoc Orders
                        orderIdSet.add(us.blng__Order__c);
                    }
                    //Gitlab #25905 update order subtoatl based if order get changed
					// as part of #34465 , removed "&& us.blng__Order__r.QTB_OrderCategory__c == 'Ad-Hoc'" as it is coming as null and need to query order data again
                    if(us.blng__PreratedAmount__c != null && us.blng__Order__c != null && us.blng__Order__c != oldMap.get(us.ID).blng__Order__c){ //Gitlab US #19002 Add to the set only for AdHoc Orders
                        orderIdSet.add(us.blng__Order__c);
                        /*if(oldMap.get(us.ID).blng__Order__c != null){ Gitlab US #18998 not needed bec us.blng__Order__c is equal to this parameter and its not Null*/
                        orderIdSet.add(oldMap.get(us.ID).blng__Order__c);
                        //}
                    }
					// GITLAB US - #34411 - to capture the QTB_Prerated_Unit_Price__c at usageSummary record
					if(us.QTB_Subline_Enabled__c && Label.QTB_PreRatedPriceEnabled_Countries.containsIgnoreCase(us.QTB_Legal_Entity_Country__c) &&
						(us.QTB_Price_Tier__c == null || us.QTB_Price_Tier__c == 'None')  && 
					    us.blng__UsageSummary__c != null && (us.QTB_Prerated_Unit_Price__c != null && us.QTB_Prerated_Unit_Price__c !=0 ) &&
						!usgSummaryToPreratedUnitPriceMap.containsKey(us.blng__UsageSummary__c)) 
						{
						usgSummaryToPreratedUnitPriceMap.put(us.blng__UsageSummary__c, us.QTB_Prerated_Unit_Price__c );
					    }
					
                }
                when BEFORE_DELETE {
                    // Gitlab 9256 // Credit ReBill By IRM/Virtusa Gitlab US #18998 added null check
                    if(us.blng__UsageSummary__c!=null && us.blng__OrderProduct__c!=null && us.QTB_Usage_Type__c == 'Rebill'){
                        usageIdsForReBillSet.add(us);
                        usgSumIdsSet.add(us.blng__UsageSummary__c);
                        orderPrdIdsSet.add(us.blng__OrderProduct__c);
                    }
                }
                when AFTER_DELETE {
                    if((us.QTB_Usage_Summary_Invoice_Status__c== QTB_Constants.INVOICE_IN_PROGRESS && us.QTB_Usage_Summary_Status__c== QTB_Constants.STATUS_QUEUED_FOR_INVOICE) 
                    || (us.QTB_Usage_Summary_Invoice_Status__c== QTB_Constants.INVOICE_COMPLETED && us.QTB_Usage_Summary_Status__c== QTB_Constants.STATUS_PROCESSED)){
                        us.addError(System.Label.QTB_ErrorBilledUsages);
                    }
                    //18998 optimized completely Consolidated guards to avoid duplicate conditions
                    Boolean isEligible = (us.QTB_System_Cancelled__c == false && us.QTB_UsedforRerate__c == false);
                    Boolean isPendingProcessed = (us.QTB_Usage_Summary_Invoice_Status__c == QTB_Constants.INVOICE_STATUS_PENDING_BILLING
                        && us.QTB_Usage_Summary_Status__c == QTB_Constants.STATUS_QUEUED_FOR_INVOICE
                        && us.blng__Status__c == QTB_Constants.USAGE_STATUS_PROCESSED);

                    if (isEligible && isPendingProcessed) {
                        // Compute deltas once, avoid duplicate Map lookups and puts
                        Decimal addAmount = (us.blng__PreratedAmount__c != null && us.blng__PreratedAmount__c != 0)
                            ? us.blng__PreratedAmount__c
                            : ((us.blng__PreratedAmount__c == null || us.blng__PreratedAmount__c == 0) && us.blng__Subtotal__c != 0)
                                ? us.blng__Subtotal__c
                                : null;
                        if (addAmount != null && addAmount != 0) {
                            Decimal currentAmt = usageSummaryReRateAmountMap.get(us.blng__UsageSummary__c);
                            currentAmt = (currentAmt == null) ? 0 : currentAmt;
                            usageSummaryReRateAmountMap.put(us.blng__UsageSummary__c, currentAmt + addAmount);
                        }

                        Decimal addQty = (us.blng__PreratedQuantity__c != null && us.blng__PreratedQuantity__c != 0)
                            ? us.blng__PreratedQuantity__c
                            : ((us.blng__PreratedQuantity__c == null || us.blng__PreratedQuantity__c == 0) && us.blng__Quantity__c != 0)
                                ? us.blng__Quantity__c
                                : null;
                        if (addQty != null && addQty != 0) {
                            Decimal currentQty = usageSummaryReRateQuantityMap.get(us.blng__UsageSummary__c);
                            currentQty = (currentQty == null) ? 0 : currentQty;
                            usageSummaryReRateQuantityMap.put(us.blng__UsageSummary__c, currentQty + addQty);
                        }
                    }

                    if (isEligible && (isPendingProcessed
                        || us.blng__Status__c == QTB_Constants.USAGE_STATUS_WARNING_UNRATED
                        || us.blng__Status__c == QTB_Constants.USAGE_STATUS_ERROR)) {

                        QTB_Usage_Suspense__c newObj = new QTB_Usage_Suspense__c(); // To move the deleted unbilled usages to suspense object
                        QTB_Utils.MapSourceFldValuetoDestFldVal(newObj, us, metadataList);
                        newErrorUsagesMirrorObjList.add(newObj);   // Gitlab US #18998
                    } // //18998 optimized completely ends
                    // Gitlab 9256 // Credit ReBill By IRM/Virtusa
                    if(us.blng__UsageSummary__c!=null && us.blng__OrderProduct__c!=null && us.QTB_Usage_Type__c == 'Rebill'){ //Gitlab US #18998 added null check
                        usgSumIdsSet.add(us.blng__UsageSummary__c);
                        orderPrdIdsSet.add(us.blng__OrderProduct__c);
                    }
                    // as part of #34465 , removed "&& us.blng__Order__r.QTB_OrderCategory__c == 'Ad-Hoc'" as it is coming as null and need to query order data again
                    if(us.blng__PreratedAmount__c != null && us.blng__Order__c != null ){ // #25905 update order subtoatl if any usage get deleted
                        orderIdSet.add(us.blng__Order__c);//Gitlab US #19002 Add to the set only for AdHoc Orders
                    }
                }
                when AFTER_UNDELETE {
                    // as part of #34465 , removed "&& us.blng__Order__r.QTB_OrderCategory__c == 'Ad-Hoc'" as it is coming as null and need to query order data again
                    if(us.blng__PreratedAmount__c != null && us.blng__Order__c != null){ // #25905 //Gitlab US #19002 Add to the set only for AdHoc Orders
                        orderIdSet.add(us.blng__Order__c);
                    }
                }
            }             
        }
        if(!refreshRecordEventsList.isEmpty()){ // Gitlab 9256 //Gitlab US #18998 removed && refreshRecordEventsList.size() > 0
            EventBus.publish(refreshRecordEventsList);
        }
        // post processing
        switch on operationType {
            when BEFORE_INSERT {
                // #28503 // Gitlab Gitlab US #18998 moved outside of countryClone null check
                if(!isDataExchangeUser && usageOrderIdsSet !=null && !usageOrderIdsSet.isEmpty()){
                    orderforCategoryList = [SELECT ID, QTB_OrderCategory__c 
                                            FROM Order  
                                            WHERE ID IN :usageOrderIdsSet AND QTB_OrderCategory__c = 'Rebill'];
                    isRebill = (orderforCategoryList.size()>0) ? true : false;
                }
                //Gitlab #28503 Added Rebill check to fire the method only if usage is manual AND not for rebill IN insert
                if(!isDataExchangeUser && !isRebill){      
                    calculateTermForStorageUsage(newItems); //Gitlab US #18998 removed the 2nd parameter ie 'Insert'
                    validateProductIdentifierOne(newItems); // Gitlab #30390 //Gitlab US #18998 removed the 2nd parameter ie 'Insert'
                }//Gitlab US #18998 moved outside last line
                if(!usageList.isEmpty() && !blngAccountIdsSet.isEmpty()){
                    countryClone(usageList,blngAccountIdsSet);
                }
            }
            when BEFORE_UPDATE{
                if(!usageList.isEmpty() && !blngAccountIdsSet.isEmpty()){
                    countryClone(usageList,blngAccountIdsSet);                        
                }
                if(revReportFieldsUpdated){
                    updateRevenueFieldsCalculation(newItems, oldMap);
                }
                //30390 start
                // Gitlab #31033 - As part of the bug, on update of rebill usage expected product identifier validation should be checked
                if (callValidateProductIdentifierOne && !isDataExchangeUser){ 
                    validateProductIdentifierOne(newItems); // Gitlab #30390 //Gitlab US #18998 removed the 2nd parameter ie 'update'
                }
                // Gitlab 9256 // Credit ReBill By IRM/Virtusa
                if(!usageIdsForReBillSet.isEmpty()){ // Gitlab US #18998 removed && usageIdsForReBillSet.size() > 0  // Gitlab US #18998 modified the return type
                    List<blng__UsageSummary__c> usgSummaryUpdate = updateUsageUsageSummary(usgSumIdsSet,orderPrdIdsSet);
                    if(finalUsageSummaryUpdateDisableTriggerMap!=null && usgSummaryUpdate != null && !usgSummaryUpdate.isEmpty()){//Gitlab US #18998 modified
                        for(blng__UsageSummary__c usgSum: usgSummaryUpdate){
                           // if that usgSummaryId is not present in Map add as it is for further updates
                            if(finalUsageSummaryUpdateDisableTriggerMap!=null && !finalUsageSummaryUpdateDisableTriggerMap.containsKey(usgSum.ID)){
                                finalUsageSummaryUpdateDisableTriggerMap.put(usgSum.ID,usgSum);
                            }else if(finalUsageSummaryUpdateDisableTriggerMap!=null){
                                // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Status__c', usgSum.blng__Status__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedAmount__c', usgSum.blng__PreratedAmount__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedQuantity__c', usgSum.blng__PreratedQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Subtotal__c', usgSum.blng__Subtotal__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__TotalQuantity__c', usgSum.blng__TotalQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnbilledQuantity__c', usgSum.blng__UnbilledQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnitPrice__c', usgSum.blng__UnitPrice__c);
                            }
                        }
                        usgSummaryUpdate.clear();
                    }
                }
                // 25283: Use static Map<Id,Boolean> guard on UsageSummary Ids to avoid recursion
                if (usgSummIdSet != null && System.Label.IsUsageFieldsNonEditableForProcessed == 'true') {
                    // Filter out UsageSummary Ids already processed in this transaction
                    Set<Id> toProcessUsgSumIds = new Set<Id>();
                    for (Id usgSumId : usgSummIdSet) {
                        if (!USG_SUM_GUARD.containsKey(usgSumId)) {
                            toProcessUsgSumIds.add(usgSumId);
                        }
                    }
                    if (!toProcessUsgSumIds.isEmpty()) {
                        lgUserList = [SELECT ID ,Name,profile.Name 
                                        FROM User 
                                    WHERE profile.Name NOT IN: excludedProfilesList AND ID =: userinfo.getuserId()];
                        if (lgUserList != null && !lgUserList.isEmpty()) {
                            // Call with original sets/lists; method already iterates over newItems and oldMap
                            makeFieldsNonEditableForProcessed(newItems, oldMap, toProcessUsgSumIds);
                            // Mark processed UsageSummaries to prevent re-entry
                            for (Id idProcessed : toProcessUsgSumIds) {
                                USG_SUM_GUARD.put(idProcessed, true);
                            }
                        }
                    }
                }
                if(System.Label.IsUsageFieldsReadOnlyForProcessed == 'true'){
                    //makeFieldsReadOnlyForProcessed(newItems, oldMap);
                }             
                if(Test.isRunningTest()){  //Gitlab US #18998 the code existed before; it works only for test classes
                    makeFieldsReadOnlyForProcessed(newItems, oldMap);  
                    //makeFieldsNonEditableForProcessed(newItems, oldMap,usgSummIdSet);
                }
            }
            when BEFORE_DELETE {
                // Gitlab 9256 // Credit ReBill By IRM/Virtusa
                if(!usageIdsForReBillSet.isEmpty()){ // Gitlab US #18998 removed && usageIdsForReBillSet.size() > 0
                    List<blng__UsageSummary__c> usgSummaryUpdate = updateUsageUsageSummary(usgSumIdsSet,orderPrdIdsSet);
                    if(finalUsageSummaryUpdateDisableTriggerMap!=null && usgSummaryUpdate != null && !usgSummaryUpdate.isEmpty()){//Gitlab US #18998 modified
                        for(blng__UsageSummary__c usgSum: usgSummaryUpdate){
                            // if that usgSummaryId is not present in Map add as it is for further updates
                            if(finalUsageSummaryUpdateDisableTriggerMap!=null && !finalUsageSummaryUpdateDisableTriggerMap.containsKey(usgSum.ID)){
                                finalUsageSummaryUpdateDisableTriggerMap.put(usgSum.ID,usgSum);
                            }else if(finalUsageSummaryUpdateDisableTriggerMap!=null){
                                // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Status__c', usgSum.blng__Status__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedAmount__c', usgSum.blng__PreratedAmount__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedQuantity__c', usgSum.blng__PreratedQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Subtotal__c', usgSum.blng__Subtotal__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__TotalQuantity__c', usgSum.blng__TotalQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnbilledQuantity__c', usgSum.blng__UnbilledQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnitPrice__c', usgSum.blng__UnitPrice__c);
                            }
                        }
                        usgSummaryUpdate.clear();
                    }
                    
                    List<OrderItem> orderItemUpdate =updateOrderItem(usageIdsForReBillSet,orderPrdIdsSet);  // Gitlab US #18998 separated the logic exclusive for beforeDelete
                    if(finalOrderItemUpdateMap!=null && orderItemUpdate != null && !orderItemUpdate.isEmpty()){// Gitlab US #18998 added
                        for(orderItem ordItem: orderItemUpdate){
                            finalOrderItemUpdateMap.put(ordItem.ID,ordItem);
                        }
                        orderItemUpdate.clear();
                    }
                }
            }
            // update usage summaries after deleting unbilled usages AND add deleted usage to suspense object
            when AFTER_DELETE{                     
                if (!newErrorUsagesMirrorObjList.isEmpty()){ // Gitlab US #18998 appended List to the variable
                    finalUsageSuspenseInsertList.addAll(newErrorUsagesMirrorObjList); //Gitlab US #18998 ask SHAILESH VVIMP
                }
                if(!usageSummaryReRateAmountMap.isEmpty() && !usageSummaryReRateQuantityMap.isEmpty()){
                    List<blng__UsageSummary__c> usgSummUpdate = afterDelete(usageSummaryReRateAmountMap,usageSummaryReRateQuantityMap);
                    if(finalUsageSummaryUpdateDisableTriggerMap!=null && usgSummUpdate != null && !usgSummUpdate.isEmpty()){ // Gitlab US #18998 added
                        for(blng__UsageSummary__c usgSumm: usgSummUpdate){
                            finalUsageSummaryUpdateDisableTriggerMap.put(usgSumm.ID,usgSumm);
                        }
                        usgSummUpdate.clear();
                    }
                }
                // Gitlab 9256 // Credit ReBill By IRM/Virtusa
                if(!usgSumIdsSet.isEmpty() && !orderPrdIdsSet.isEmpty()){ // Gitlab US #18998 removed && usgSumIdsSet.size() > 0 && orderPrdIdsSet.size() > 0
                    List<blng__UsageSummary__c> usgSummaryUpdate = updateUsageUsageSummary(usgSumIdsSet,orderPrdIdsSet);
                    if(finalUsageSummaryUpdateDisableTriggerMap!=null && usgSummaryUpdate != null && !usgSummaryUpdate.isEmpty()){//Gitlab US #18998 modified
                        for(blng__UsageSummary__c usgSum: usgSummaryUpdate){
                            // if that usgSummaryId is not present in Map add as it is for further updates
                            if(finalUsageSummaryUpdateDisableTriggerMap!=null && !finalUsageSummaryUpdateDisableTriggerMap.containsKey(usgSum.ID)){
                                finalUsageSummaryUpdateDisableTriggerMap.put(usgSum.ID,usgSum);
                            }else if(finalUsageSummaryUpdateDisableTriggerMap!=null){
                                // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Status__c', usgSum.blng__Status__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedAmount__c', usgSum.blng__PreratedAmount__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedQuantity__c', usgSum.blng__PreratedQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Subtotal__c', usgSum.blng__Subtotal__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__TotalQuantity__c', usgSum.blng__TotalQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnbilledQuantity__c', usgSum.blng__UnbilledQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnitPrice__c', usgSum.blng__UnitPrice__c);
                            }
                        }
                        usgSummaryUpdate.clear();
                    }
                }
                //25905
                if(!orderIdSet.isEmpty()){
                    List<Order> updateOrderSubtotalList = updateOrderSubtotalOnAdHocOrder(orderIdSet);
                    if(updateOrderSubtotalList!=null && !updateOrderSubtotalList.isEmpty()){
                        for(Order ord : updateOrderSubtotalList){       //Gitlab US #18998 added to ASK and TODO
                            finalOrderUpdateMap.put(ord.ID, ord);  //Gitlab US #18998 Add Order records to finalOrderUpdateMap
                        }
                        updateOrderSubtotalList.clear();// clearing the Memory
                    }
                }
            }
            when AFTER_INSERT{
                //Gitlab #20867 Tiered flag method calling
                if(!tieredUsgSumIdsSet.isEmpty()){ // Gitlab US #18998 removed && tieredUsgSumIdsSet.size() > 0
                    List<blng__UsageSummary__c> updateTieredFlagOnUsgSummaryInsertList = updateTieredFlagOnUsgSummary(tieredUsgSumIdsSet,null,null,'AFTER_INSERT');// Gitlab US #18998 changed the returnType
                    if(finalUsageSummaryUpdateDisableTriggerMap !=null && updateTieredFlagOnUsgSummaryInsertList != null && !updateTieredFlagOnUsgSummaryInsertList.isEmpty()){
                        for(blng__UsageSummary__c usgSum: updateTieredFlagOnUsgSummaryInsertList){
                            finalUsageSummaryUpdateDisableTriggerMap.put(usgSum.ID,usgSum);
                        }
                        updateTieredFlagOnUsgSummaryInsertList.clear(); // Gitlab US #18998 changed the returnType ends here
                    }
                }
                //25905
                if(!orderIdSet.isEmpty()){
                    List<Order> updateOrderSubtotalList = updateOrderSubtotalOnAdHocOrder(orderIdSet);
                    if(updateOrderSubtotalList!=null && !updateOrderSubtotalList.isEmpty()){
                        for(Order ord : updateOrderSubtotalList){       //Gitlab US #18998 added to ASK and TODO
                            finalOrderUpdateMap.put(ord.ID, ord);  //Gitlab US #18998 Add Order records to finalOrderUpdateMap
                        }
                        updateOrderSubtotalList.clear();// clearing the Memory
                    }
                }
            }
            when AFTER_UPDATE{
                // Gitlab 9256 // Credit ReBill By IRM/Virtusa
                if(!usageIdsForReBillSet.isEmpty()){ // Gitlab US #18998 removed && usageIdsForReBillSet.size() > 0
                    List<blng__UsageSummary__c> usgSummaryUpdate = updateUsageUsageSummary(usgSumIdsSet,orderPrdIdsSet);
                    if(finalUsageSummaryUpdateDisableTriggerMap!=null && usgSummaryUpdate != null && !usgSummaryUpdate.isEmpty()){//Gitlab US #18998 modified
                        for(blng__UsageSummary__c usgSum: usgSummaryUpdate){
                            // if that usgSummaryId is not present in Map add as it is for further updates
                            if(finalUsageSummaryUpdateDisableTriggerMap!=null && !finalUsageSummaryUpdateDisableTriggerMap.containsKey(usgSum.ID)){
                                finalUsageSummaryUpdateDisableTriggerMap.put(usgSum.ID,usgSum);
                            }else if(finalUsageSummaryUpdateDisableTriggerMap!=null){
                                // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Status__c', usgSum.blng__Status__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedAmount__c', usgSum.blng__PreratedAmount__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__PreratedQuantity__c', usgSum.blng__PreratedQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__Subtotal__c', usgSum.blng__Subtotal__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__TotalQuantity__c', usgSum.blng__TotalQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnbilledQuantity__c', usgSum.blng__UnbilledQuantity__c);
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('blng__UnitPrice__c', usgSum.blng__UnitPrice__c);
                            }
                        }
                        usgSummaryUpdate.clear();
                    }
                }
                //Gitlab #20867 Tiered flag method calling
                if(!oldNullAndNewTieredUsgSummIdsSet.isEmpty()){ // Gitlab US #18998 removed && oldNullAndNewTieredUsgSummIdsSet.size() > 0
                    List<blng__UsageSummary__c> updateTieredFlagOnUsgSummaryUpdateList = updateTieredFlagOnUsgSummary(null,oldNullAndNewTieredUsgSummIdsSet,null,'AFTER_UPDATE'); // Gitlab US #18998 changed the returnType starts
                    if(finalUsageSummaryUpdateDisableTriggerMap !=null && updateTieredFlagOnUsgSummaryUpdateList != null && !updateTieredFlagOnUsgSummaryUpdateList.isEmpty()){
                        for(blng__UsageSummary__c usgSum: updateTieredFlagOnUsgSummaryUpdateList){
                            // if that usgSummaryId is not present in Map add as it is for further updates
                            if(finalUsageSummaryUpdateDisableTriggerMap!=null && !finalUsageSummaryUpdateDisableTriggerMap.containsKey(usgSum.ID)){
                                finalUsageSummaryUpdateDisableTriggerMap.put(usgSum.ID,usgSum);
                            }else if(finalUsageSummaryUpdateDisableTriggerMap!=null){
                                // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('QTB_Tiered_Flag__c', usgSum.QTB_Tiered_Flag__c);
                            }
                        }
                        updateTieredFlagOnUsgSummaryUpdateList.clear();// Gitlab US #18998 changed the returnType ends here
                    }
                }
                if(!oldTierAndNewNullUsgSummIdsSet.isEmpty()){ // Gitlab US #18998 removed && oldTierAndNewNullUsgSummIdsSet.size() > 0
                    List<blng__UsageSummary__c> oldTieredFlagOnUsgSummaryUpdateList = updateTieredFlagOnUsgSummary(null,null,oldTierAndNewNullUsgSummIdsSet,'AFTER_UPDATE');// Gitlab US #18998 changed the returnType starts
                    if(finalUsageSummaryUpdateDisableTriggerMap !=null && oldTieredFlagOnUsgSummaryUpdateList != null && !oldTieredFlagOnUsgSummaryUpdateList.isEmpty()){
                        for(blng__UsageSummary__c usgSum: oldTieredFlagOnUsgSummaryUpdateList){
                            // if that usgSummaryId is not present in Map add as it is for further updates
                            if(finalUsageSummaryUpdateDisableTriggerMap!=null && !finalUsageSummaryUpdateDisableTriggerMap.containsKey(usgSum.ID)){
                                finalUsageSummaryUpdateDisableTriggerMap.put(usgSum.ID,usgSum);
                            }else if(finalUsageSummaryUpdateDisableTriggerMap!=null){
                                // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                finalUsageSummaryUpdateDisableTriggerMap.get(usgSum.ID).put('QTB_Tiered_Flag__c', usgSum.QTB_Tiered_Flag__c);
                            }
                        }
                        oldTieredFlagOnUsgSummaryUpdateList.clear();// Gitlab US #18998 changed the returnType ends here
                    }
                }
				
				// GITLAB US #34411 — update QTB_Prerated_Unit_Price__c using unified DML
				if (!usgSummaryToPreratedUnitPriceMap.isEmpty()){
				    for (Id usgSumId : usgSummaryToPreratedUnitPriceMap.keySet()) {
                        Decimal preratedUnitPrice = usgSummaryToPreratedUnitPriceMap.get(usgSumId);

                        if (!finalUsageSummaryUpdateDisableTriggerMap.containsKey(usgSumId)){
                            blng__UsageSummary__c usgSumm = new blng__UsageSummary__c();
                            usgSumm.Id = usgSumId;
                            usgSumm.QTB_Prerated_Unit_Price__c = preratedUnitPrice;

                            finalUsageSummaryUpdateDisableTriggerMap.put(usgSumId, usgSumm);
                        } else {
                            finalUsageSummaryUpdateDisableTriggerMap.get(usgSumId).put('QTB_Prerated_Unit_Price__c', preratedUnitPrice);
                        }
			        }
		        }
                //25905
                if(!orderIdSet.isEmpty()){ 
                    List<Order> updateOrderSubtotalList = updateOrderSubtotalOnAdHocOrder(orderIdSet);
                    if(updateOrderSubtotalList!=null && !updateOrderSubtotalList.isEmpty()){
                        for(Order ord : updateOrderSubtotalList){       //Gitlab US #18998 added to ASK and TODO
                            finalOrderUpdateMap.put(ord.ID, ord);  //Gitlab US #18998 Add Order records to finalOrderUpdateMap
                        }
                        updateOrderSubtotalList.clear();// clearing the Memory
                    }
                }
            }
            when AFTER_UNDELETE{
                //25905
                if(!orderIdSet.isEmpty()){
                    List<Order> updateOrderSubtotalList = updateOrderSubtotalOnAdHocOrder(orderIdSet);
                    if(updateOrderSubtotalList!=null && !updateOrderSubtotalList.isEmpty()){
                        for(Order ord : updateOrderSubtotalList){       //Gitlab US #18998 added to ASK and TODO
                            finalOrderUpdateMap.put(ord.ID, ord);  //Gitlab US #18998 Add Order records to finalOrderUpdateMap
                        }
                        updateOrderSubtotalList.clear();// clearing the Memory
                    }
                }
            }
        }  
        if(finalOrderUpdateMap != null && !finalOrderUpdateMap.isEmpty()){ //Gitlab US #18998 Updating only once as per the new structure
            update finalOrderUpdateMap.values(); //Gitlab US #18998 finalOrderUpdateMap moved outside the loop as part of //Gitlab US #18998 optimization 
            finalOrderUpdateMap.clear(); 
        } 
        if(finalUsageSummaryUpdateDisableTriggerMap != null && !finalUsageSummaryUpdateDisableTriggerMap.isEmpty()){ //Gitlab US #18998 Updating only once as per the new structure
            SBQQ.TriggerControl.disable();
            update finalUsageSummaryUpdateDisableTriggerMap.values(); //Gitlab US #18998 finalUsageSummaryUpdateDisableTriggerMap moved outside the loop as part of //Gitlab US #18998 optimization 
            SBQQ.TriggerControl.enable();
            finalUsageSummaryUpdateDisableTriggerMap.clear();
        } 
        if(finalOrderItemUpdateMap != null && !finalOrderItemUpdateMap.isEmpty()){ //Gitlab US #18998 Updating only once as per the new structure
            update finalOrderItemUpdateMap.values(); //Gitlab US #18998 finalOrderItemUpdateMap moved outside the loop as part of //Gitlab US #18998 optimization 
            finalOrderItemUpdateMap.clear();
        }   
        if(finalUsageSuspenseInsertList != null && !finalUsageSuspenseInsertList.isEmpty()){ //Gitlab US #18998 inserting only once as per the new structure
            Database.insert(finalUsageSuspenseInsertList); //Gitlab US #18998 finalUsageSuspenseInsertList moved outside the loop as part of //Gitlab US #18998 optimization 
            finalUsageSuspenseInsertList.clear();
        } 
    }

    /***********************************************************************************************************
* Method    : calculateTermForStorageUsage
* Parameters : List<blng__Usage__c> usageList, String operationType
* Description: this method is created to check MRC dates, Term, Actual Unit price, Prerated unit price
* Story Number: Gitlab #28503 SFDC Rev Mgmt Reporting: Rev Rec Calculations
* Virtusa		     10/28/2025     Gitlab US #18998 code optimization; removed the parameter String operationType
**************************************************************************************************************/
    public static void calculateTermForStorageUsage(List<blng__Usage__c> usageList) {
        try{
            if(usageList== null || usageList.isEmpty()){
                throw new NullPointerException(); // Gitlab US #18998 added Null Check
            }
            Set<ID> usageSummaryIdSet = new Set<ID>(); // Gitlab US #18998 added Set to the variableName
            String dataExchangeUserName = System.Label.Data_Exchange_Integration_User.toLowerCase();

            for(blng__Usage__c usage : usageList){ 
                if(usage.blng__UsageSummary__c!=null) {
                    usageSummaryIdSet.add(usage.blng__UsageSummary__c);// Collect UsageSummary IDs; only the ones that have usages
                }
            }
            if(usageSummaryIdSet.isEmpty()) {return;}

            // Query UsageSummaries with related info // Gitlab US #18998 removed spaces
            Map<ID,blng__UsageSummary__c> usageSummaryMap = new Map<ID,blng__UsageSummary__c>([SELECT ID, blng__OrderProduct__r.Product2.QTB_Storage_Product__c,blng__Order__r.QTB_OrderCategory__c,blng__Account__r.QTB_isContractRateApplicable__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.QTB_Legal_Entity__r.QTB_Contract_Currency_Applicable__c
                                                                                                FROM blng__UsageSummary__c
                                                                                                WHERE ID IN :usageSummaryIdSet]);
            for(blng__Usage__c usage : usageList){
                Integer totalMonths = 0;
                Date startDate = usage.QTB_Start_Date_MRC__c;
                Date endDate = usage.QTB_End_Date_MRC__c;
                blng__UsageSummary__c usgSummary = usageSummaryMap.get(usage.blng__UsageSummary__c);
                if (usgSummary == null || usgSummary.blng__OrderProduct__r == null || usgSummary.blng__Order__r == null) {
                    continue;
                }
                Boolean isStorageProduct = usgSummary.blng__OrderProduct__r.Product2.QTB_Storage_Product__c;
                //Gitlab - #31789- Start // Validate Start Date AND Term for storage products
                if(isStorageProduct && (usage.QTB_Start_Date_MRC__c == null || usage.QTB_End_Date_MRC__c == null 
                        || (usage.QTB_End_Date_MRC__c != null && usage.QTB_Start_Date_MRC__c != null && usage.QTB_End_Date_MRC__c < usage.QTB_Start_Date_MRC__c))) {
                    usage.addError(System.Label.QTB_MRCDatesValidation); 
                }
                //Gitlab - #30720 restructured the logic as per the bug raised
                if(startDate != null && endDate != null && endDate >= startDate){
                    Date tempDate = startDate.toStartOfMonth();
                    while (tempDate <= endDate){
                        totalMonths++;
                        tempDate = tempDate.addMonths(1);
                    }
                }else{ // defaulting Term to 1 only to storage products
                    if((usage.QTB_Term__c == null || totalMonths < 1 ) && isStorageProduct){
                        totalMonths = 1; // fallback if invalid dates
                    }
                }
                // Gitlab -> #31563 reset the term to blank for non storage products if MRC dates are blank
                usage.QTB_Term__c = (isStorageProduct == false && usage.QTB_Start_Date_MRC__c == null && usage.QTB_End_Date_MRC__c == null)
                                    ?  usage.QTB_Term__c : String.valueOf(totalMonths); //Gitlab US #18998 modified with termary operator // placed default value of the variable instead of ''

                // Default Actual Quantity to 1 if PreratedQuantity missing or zero
                if (usage.blng__PreratedQuantity__c == null || usage.blng__PreratedQuantity__c == 0){
                    usage.QTB_Actual_Quantity__c = 1;
                }else if(totalMonths > 0){
                    usage.QTB_Actual_Quantity__c = (usage.blng__PreratedQuantity__c / totalMonths).setScale(3, System.RoundingMode.HALF_UP);
                }

                // Calculate Prerated Unit Price WHERE applicable
                if (usage.QTB_Prerated_Unit_Price__c == null && usage.blng__PreratedAmount__c != null && usage.blng__PreratedAmount__c != 0 
                && usage.blng__PreratedQuantity__c != null && usage.blng__PreratedQuantity__c != 0 && !usgSummary.blng__Account__r.QTB_isContractRateApplicable__c){
                    Integer scale = (usgSummary.blng__Account__r.QTB_Legal_Entity__r.QTB_Contract_Currency_Applicable__c) ? 4 : 6;
                    usage.QTB_Prerated_Unit_Price__c = (usage.blng__PreratedAmount__c / usage.blng__PreratedQuantity__c).setScale(scale, System.RoundingMode.HALF_UP);
                } else if ((usage.blng__PreratedAmount__c == null || usage.blng__PreratedAmount__c == 0) ||
                        (usage.blng__PreratedQuantity__c == null || usage.blng__PreratedQuantity__c == 0)){
                    usage.QTB_Prerated_Unit_Price__c = 0;
                }
                
                // Validate Prerated Amount mismatch
                if(usage.QTB_Prerated_Unit_Price__c != null && usage.blng__PreratedQuantity__c != null && usage.blng__PreratedAmount__c != null){
                    Decimal calculatedAmount = (usage.QTB_Prerated_Unit_Price__c * usage.blng__PreratedQuantity__c).setScale(2, System.RoundingMode.HALF_UP);
					Decimal difference = (calculatedAmount - usage.blng__PreratedAmount__c).abs();
                    // Fire the validation only the decimal difference is greater than 1.
					if((calculatedAmount != usage.blng__PreratedAmount__c) && difference >= 1){
						usage.addError(System.Label.QTB_calculationMisMatchValidation);
					}
                }
            }
        }catch (Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( e.getLineNumber(), e.getStackTraceString(),e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method    : validateProductIdentifierOne
* Parameters : List<blng__Usage__c> usageList, String operationType
* Description: this method is created to check Product Identifier 1 then throw validation error Account country AND Product level Bill Code
* Story Number: Gitlab #30390 SFDC Manual Usage Processing
* Virtusa		     10/28/2025     Gitlab US #18998 code optimization ; removed the parameter String operationType
************************ **************************************************************************************/
    public static void validateProductIdentifierOne(List<blng__Usage__c> newItems) {
        try{
            if (newItems == null || newItems.isEmpty()) {
                throw new NullPointerException(); // Gitlab US #18998 added Null Check
            }
            Set<ID> usgSummaryIdsSet = new Set<ID>();
            Set<String> usglegalEntityCountriesSet = new Set<String>(); //Gitlab US #18998 Prepare list of countries
            Set<String> usgProductNamesSet = new Set<String>(); //Gitlab US #18998 Prepare list of product names
            Map<String, Map<String, Set<String>>> countryToCodeToProductsMap = new Map<String, Map<String, Set<String>>>(); // Gitlab US #18998 Optimized lookup structure: Country -> BillCode -> Set<ProductName>
            
            for(blng__Usage__c usage : newItems){
                if(usage.blng__Account__c != null && usage.blng__Order__c != null && usage.blng__UsageSummary__c != null ){
                    usgSummaryIdsSet.add(usage.blng__UsageSummary__c); //Gitlab US #18998 added proper null check and removed unnnecessary set variables
                }
            }
            if(usgSummaryIdsSet.isEmpty()){ return;}
            Map<ID,blng__UsageSummary__c> usgSummaryMap = new Map<ID,blng__UsageSummary__c>([SELECT ID, QTB_Product_Name__c, QTB_Legal_Entity_Country__c 
                                                        FROM blng__UsageSummary__c 
                                                        WHERE ID IN :usgSummaryIdsSet]); // Step 1: Load usage summary details
            for (blng__UsageSummary__c usgSum : usgSummaryMap.values()){
                if(usgSum.QTB_Legal_Entity_Country__c != null){
                    usglegalEntityCountriesSet.add(usgSum.QTB_Legal_Entity_Country__c);
                }
                if(usgSum.QTB_Product_Name__c != null){
                    usgProductNamesSet.add(usgSum.QTB_Product_Name__c);
                }
            }

            if (usglegalEntityCountriesSet.isEmpty()) return;  // Gitlab US #18998 return early
            // Step 2: Build the product lookup map
            for (QTB_Bill_Code_Product_Lookup__c lookup : [SELECT QTB_Source_Bill_Code__c, QTB_Country__r.Name, QTB_Product2__r.Name //Gitlab US #18998 checked if SourceBillCode and ProductName is not null
                                                        FROM QTB_Bill_Code_Product_Lookup__c 
                                                        WHERE QTB_Country__r.Name IN :usglegalEntityCountriesSet AND QTB_Active__c = true AND QTB_Source_Bill_Code__c!='' AND QTB_Product2__r.Name!='']) {
                String country = lookup.QTB_Country__r.Name;
                String billCode = lookup.QTB_Source_Bill_Code__c;
                String productName = lookup.QTB_Product2__r.Name;

                if (!countryToCodeToProductsMap.containsKey(country)){
                    countryToCodeToProductsMap.put(country, new Map<String, Set<String>>());
                }
                Map<String,Set<String>> codeToProducts = countryToCodeToProductsMap.get(country);

                if (!codeToProducts.containsKey(billCode)) {
                    codeToProducts.put(billCode, new Set<String>());
                }
                codeToProducts.get(billCode).add(productName);
            }

            for (blng__Usage__c usage : newItems) { // Step 3: Validate each usage
                if (String.isBlank(usage.QTB_Product_Identifier_1__c)) {
                    usage.addError(System.Label.QTB_ProductIdentifierValidation);
                    continue  ;// return; ASK SHAILESH 29th October
                }
                if (usage.blng__Account__c == null || usage.blng__UsageSummary__c == null) {
                    continue;
                }
                blng__UsageSummary__c usageSummary = usgSummaryMap.get(usage.blng__UsageSummary__c);
                if (usageSummary == null || String.isBlank(usageSummary.QTB_Legal_Entity_Country__c)) {
                    continue;
                }
                
                Boolean isValid = false;
                // Gitlab US #18998 perform null checks
                if (usageSummary.QTB_Legal_Entity_Country__c !=null && countryToCodeToProductsMap.containsKey(usageSummary.QTB_Legal_Entity_Country__c)) {
                    Map<String, Set<String>> codeToProducts = countryToCodeToProductsMap.get(usageSummary.QTB_Legal_Entity_Country__c);
                    if (usage.QTB_Product_Identifier_1__c != null && codeToProducts.containsKey(usage.QTB_Product_Identifier_1__c)) {
                        Set<String> validProducts = codeToProducts.get(usage.QTB_Product_Identifier_1__c);
                        if (usageSummary.QTB_Product_Name__c!=null && validProducts.contains(usageSummary.QTB_Product_Name__c)) {
                            isValid = true;
                        }
                    }
                }
                if (!isValid) {
                    usage.addError(System.Label.QTB_ProductIdentifier_Not_Match);
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( e.getLineNumber(), e.getStackTraceString(),e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method : countryClone
* Parameters: List<blng__Usage__c>, Set<ID>
* Start Date : 06-10-2020
* Author : Accenture
* Description: To carry legal entity country FROM billing account to usage records
* Virtusa		     10/28/2025     Gitlab US #18998 code optimization 
**************************************************************************************************************/
    public static void countryClone(List<blng__Usage__c> usageList, Set<ID> blngAccounts){
        try{
            if(QTB_UsageTriggerHandler.throwExplicitException || usageList == null || blngAccounts == null || usageList.isEmpty() || blngAccounts.isEmpty()){ //Gitlab US #18998 added null check
                throw new NullPointerException();
            }
            Map<ID,Account> accountToCountryMap = new Map<ID,Account>([SELECT ID,QTB_Legal_Entity_Country__c 
                                                                        FROM Account 
                                                                        WHERE ID IN: blngAccounts]);
            if(accountToCountryMap ==null || accountToCountryMap.isEmpty()) { return;} //Gitlab US #18998 return if the Map is empty
            for(blng__Usage__c usg: usageList){
                usg.QTB_Legal_Entity_Country__c = ((usg.blng__Account__c!=null && accountToCountryMap.containsKey(usg.blng__Account__c))) //Gitlab US #18998 assign value only if theMap contains key
                            ? accountToCountryMap.get(usg.blng__Account__c).QTB_Legal_Entity_Country__c : usg.QTB_Legal_Entity_Country__c; // else let the default value be assigned
            }  
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method    : updateRevenueFieldsCalculation
* Parameters : List<blng__Usage__c> newItems, Map<ID, blng__Usage__c> oldMap
* Description: this method is created calculate Revenue Reporting Fields Term,Actual Quantity,Prerated Unit Price on update of usages
* Story Number: Gitlab #28503 
**************************************************************************************************************/
   public static void updateRevenueFieldsCalculation(List<blng__Usage__c> newItems, Map<ID,blng__Usage__c> oldMap){
        try{
            if(newItems == null || oldMap == null || newItems.isEmpty() || oldMap.isEmpty()){//Gitlab US #18998 added null check
                throw new NullPointerException();
            }
            Set<ID> usageSummaryIdSet = new Set<ID>();
            for (blng__Usage__c us : newItems) {
                if(us.blng__UsageSummary__c != null) {
                    usageSummaryIdSet.add(us.blng__UsageSummary__c); //Gitlab US #18998 added null check
                }
            }
            Map<ID,blng__UsageSummary__c> usageSummaryMap = new Map<ID,blng__UsageSummary__c>([SELECT ID,blng__OrderProduct__r.Product2.QTB_Storage_Product__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Legal_Entity__r.QTB_Contract_Currency_Applicable__c,
                                                                            blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.QTB_isContractRateApplicable__c
                                                                FROM blng__UsageSummary__c 
                                                                WHERE ID IN :usageSummaryIdSet]); //Querying  UsageSummary with Product AND related Account fields
            if(usageSummaryMap.isEmpty()) { return;}  //Gitlab US #18998 return early    
            Map<ID,Boolean> productStorageMap = new Map<ID,Boolean>();// Build productStorageMap FROM UsageSummary records
            for(blng__UsageSummary__c usgSum : usageSummaryMap.values()){
                productStorageMap.put(usgSum.ID, usgSum.blng__OrderProduct__r.Product2.QTB_Storage_Product__c);
            }
            if(productStorageMap.isEmpty()) { return;}  //Gitlab US #18998 return early

            for(blng__Usage__c us : newItems){
                blng__Usage__c oldUs = oldMap.get(us.ID); //Gitlab US #18998 this would never be null as oldMap is a Map of Map<ID,blng__Usage__c> 
                blng__UsageSummary__c usageSummary = usageSummaryMap.get(us.blng__UsageSummary__c);// Retrieve UsageSummary AND Account related data
                if(usageSummary == null) {continue; }//Gitlab US #18998 safety check and moves to the next Item if its null
                
                Boolean isStorageProduct = productStorageMap.get(us.blng__UsageSummary__c);
                String currencyIso = (usageSummary.blng__Account__r != null) ? (usageSummary.blng__Account__r.CurrencyIsoCode) : (null);
                String contractCurrency = (usageSummary.blng__Account__r != null) ? (usageSummary.blng__Account__r.QTB_Contract_Currency__c) : (null);
                String term = us.QTB_Term__c;
                Date startDate = us.QTB_Start_Date_MRC__c;
                Date endDate = us.QTB_End_Date_MRC__c;
                Integer totalMonths = 0;
                if(isStorageProduct && (((startDate == null && startDate != oldUs.QTB_Start_Date_MRC__c) 
                    || (endDate == null && endDate != oldUs.QTB_End_Date_MRC__c)) 
                    || ((startDate != oldUs.QTB_Start_Date_MRC__c || endDate != oldUs.QTB_End_Date_MRC__c) && (endDate < startDate)))) {
                    us.addError(System.Label.QTB_MRCDatesValidation); // Validation on MRC Dates for Storage Product
                }
                if (startDate != null && endDate != null && endDate >= startDate){
                    Date tempDate = startDate.toStartOfMonth();
                    while (tempDate <= endDate) {
                        totalMonths++;
                        tempDate = tempDate.addMonths(1);
                    }
                }else{
                    if (totalMonths < 1 && isStorageProduct){ //Gitlab US #18998 removed totalMOnths = 0 as it is by default
                        totalMonths = 1;    // Only set default of 1 month if not already set and it's a storage product
                    }
                }
                // Gitlab -> #31563 reset the term to blank for non storage products if MRC dates are blank
                us.QTB_Term__c = (!isStorageProduct && us.QTB_Start_Date_MRC__c == null && us.QTB_End_Date_MRC__c == null) 
                                ? us.QTB_Term__c : String.valueOf(totalMonths);//Gitlab US #18998 modified with termary operator
                
                // Set Actual Quantity
                if (us.QTB_Usage_Type__c != 'Rebill') {
                    if (us.blng__PreratedQuantity__c == null || us.blng__PreratedQuantity__c == 0) {
                        us.QTB_Actual_Quantity__c = 1;
                    } else if (us.QTB_Term__c != null && String.isNotBlank(us.QTB_Term__c) && Integer.valueOf(us.QTB_Term__c) != 0 &&
                            (us.blng__PreratedQuantity__c != oldUs.blng__PreratedQuantity__c ||
                                us.QTB_Term__c != oldUs.QTB_Term__c)) {
                        us.QTB_Actual_Quantity__c = (us.blng__PreratedQuantity__c / Integer.valueOf(us.QTB_Term__c)).setScale(2, RoundingMode.HALF_UP);
                    } else if (us.QTB_Term__c == null) {
                        us.QTB_Actual_Quantity__c = us.blng__PreratedQuantity__c;
                    }
                }
                
                // Gitlab - #31192 -> SIT: Make Prerated unit price precison to 4 decimals // Set Prerated Unit Price using Account currencies FROM UsageSummary
                if(us.blng__PreratedAmount__c != null && us.blng__PreratedAmount__c != 0 && us.blng__PreratedQuantity__c != null && us.blng__PreratedQuantity__c != 0 
                    && usageSummary.blng__Account__r.QTB_isContractRateApplicable__c == false){ //pre-rated unit is calculated IN prebill for contracted currency   
                    Integer scale = (usageSummary.blng__Account__r.QTB_Legal_Entity__r.QTB_Contract_Currency_Applicable__c) ? 4 : 6;
                    us.QTB_Prerated_Unit_Price__c = (us.blng__PreratedAmount__c / us.blng__PreratedQuantity__c).setScale(scale, RoundingMode.HALF_UP);
                }

                us.blng__PreratedAmount__c = (us.blng__PreratedAmount__c != null && us.blng__PreratedAmount__c != oldUs.blng__PreratedAmount__c)
                    ? Decimal.valueOf(String.valueOf(us.blng__PreratedAmount__c.setScale(2, RoundingMode.HALF_UP))) : us.blng__PreratedAmount__c;  //Gitlab US #18998 made ternaryOperator

                // Validation: Price * Quantity = Amount
                if (us.QTB_Prerated_Unit_Price__c != null && us.blng__PreratedQuantity__c != null && us.blng__PreratedAmount__c != null 
                && (us.QTB_Prerated_Unit_Price__c != oldUs.QTB_Prerated_Unit_Price__c || us.blng__PreratedQuantity__c != oldUs.blng__PreratedQuantity__c 
                    || us.blng__PreratedAmount__c != oldUs.blng__PreratedAmount__c)) {
                    Decimal calculatedAmount = (us.QTB_Prerated_Unit_Price__c * us.blng__PreratedQuantity__c).setScale(2, RoundingMode.HALF_UP);
                    Decimal difference = (calculatedAmount - us.blng__PreratedAmount__c).abs();

                    if ((calculatedAmount != us.blng__PreratedAmount__c) && difference >= 1){  // Fire the validation only the Decimal difference is greater than 1.
                        us.addError(System.Label.QTB_calculationMisMatchValidation);
                    }
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( e.getLineNumber(), e.getStackTraceString(),e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

/***********************************************************************************************************
* Method        : updateOrderItem
* Parameters    : Set<blng__Usage__c> usageIdsForReBillSet,Set<ID> orderProductIdsSet, String operationType
* Start Date    : 10-22-2025
* Author        : IRM/Virtusa
* Description   : Gitlab US #18998 Separate the action before delete from the method updateUsageUsageSummary; 
                                    works for rebill scenario only just like updateUsageUsageSummary
**************************************************************************************************************/
    
    public static List<OrderItem> updateOrderItem(Set<blng__Usage__c> usageIdsForReBillSet,Set<ID> orderProductIdsSet){ ////Gitlab US #18998 appended Set to variableName
        try{
            if(usageIdsForReBillSet==null || orderProductIdsSet ==null || usageIdsForReBillSet.isEmpty()|| usageIdsForReBillSet.isEmpty()){
                throw new NullPointerException(); //Gitlab US #18998 added null check
            }

            Set<ID> usageId = new Set<ID>();
            Map<ID,OrderItem> orderItemMap = new Map<ID,OrderItem>();
            Map<ID,Integer> orderProductIdWithTotalUsages = new Map<ID,Integer>();
            //before Delete
            //1 ORder product can have many usages // check if order product usage count is 0 , then Set hold billing as Yes
            for(blng__Usage__c usg : usageIdsForReBillSet){
                if(usg.blng__OrderProduct__c!=null && orderProductIdWithTotalUsages.containsKey(usg.blng__OrderProduct__c)){  //OrderProduct with total related usages
                    orderProductIdWithTotalUsages.put(usg.blng__OrderProduct__c,orderProductIdWithTotalUsages.get(usg.blng__OrderProduct__c)+1);
                }else if(usg.blng__OrderProduct__c!=null){
                    orderProductIdWithTotalUsages.put(usg.blng__OrderProduct__c,1);
                }
            }   
            List<OrderItem> ordItemList = [SELECT ID,blng__HoldBilling__c, (SELECT ID FROM blng__OrderProductUsages__r)
                                            FROM OrderItem 
                                            WHERE ID IN : orderProductIdsSet]; //Gitlab US #18998 here we are using only to rebill so we cant have more than 200 child to execute in the sub query         
            for(OrderItem ordItem : ordItemList){
                if(orderProductIdWithTotalUsages.containsKey(ordItem.ID) && ordItem.blng__OrderProductUsages__r.size() == orderProductIdWithTotalUsages.get(ordItem.ID)
                && (ordItem.blng__OrderProductUsages__r.size() > 0)){ //Gitlab US #18998 merged If
                    for(blng__Usage__c u : ordItem.blng__OrderProductUsages__r){
                        usageId.add(u.ID);     
                    }
                    if(usageId.isEmpty()){continue;} //Gitlab US #18998 move to the next item in the Loop

                    OrderItem opItem = new OrderItem();
                    opItem.ID = ordItem.ID;
                    opItem.blng__HoldBilling__c = 'Yes';
                    opItem.blng__InvoiceRunProcessingStatus__c ='Will Not Invoice';
                    opItem.blng__InvoiceRunStatusIndex__c ='Will Not Invoice';
                    orderItemMap.put(opItem.ID,opItem);
                    
                }
            }
            if(!orderItemMap.isEmpty()){ // gets executed when its before delete // Gitlab US #18998 removed && orderItemMap.size() > 0 
                return orderItemMap.values();
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( e.getLineNumber(), e.getStackTraceString(),e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method        : updateUsageUsageSummary
* Parameters    : Set<ID> usageSumIdsSet, Set<ID> orderProductIdsSet
* Start Date    : 07-25-2022
* Author        : IRM/Virtusa
* Description   : US#9505 to update usage/usageSummary unit price/quantity/subtotal explicitly bcoz values are not auto updating IN update scenario. It works for rebill scenario alone
* Virtusa	10/28/2025  Gitlab US #18998 code optimization; changed the return type of the method; removed parameter , String operationType
**************************************************************************************************************/
    public static List<blng__UsageSummary__c> updateUsageUsageSummary(Set<ID> usageSumIdsSet, Set<ID> orderProductIdsSet){//Gitlab US #18998 appended Set to variableNamel removed usageIdsForReBillSet as parameter
        try{
            if(orderProductIdsSet ==null || usageSumIdsSet ==null || usageSumIdsSet.isEmpty() || orderProductIdsSet.isEmpty()){
                throw new NullPointerException(); //Gitlab US #18998 added null check // || usageIdsForReBillSet.isEmpty() check is not needed
            }

            List<blng__Usage__c> usgFinalList = new List<blng__Usage__c>();
            List<blng__Usage__c> usgInitialList = new List<blng__Usage__c>();
            Map<ID,blng__UsageSummary__c> usgSummaryFinalMap = new Map<ID,blng__UsageSummary__c>();
            Set<ID> orderPrdIdsSet = new Set<ID>();
            Decimal quantity,subtotal,preRatedQuantity,preRatedAmount;
            
            // Bug #19736 : System.QueryException: Aggregate query has too many rows for direct assignment,
            //  use FOR loop; created a List to query  AND used for loop as written below
            List<blng__UsageSummary__c> usgSummList = [SELECT ID,Name,blng__TotalQuantity__c,blng__UnbilledQuantity__c,blng__Subtotal__c,blng__PreratedQuantity__c,blng__UnitPrice__c,
                                                        (SELECT ID, blng__UnitPrice__c,blng__Quantity__c,blng__PreratedQuantity__c, blng__PreratedAmount__c,blng__Status__c,blng__OrderProduct__r.UnitPrice,
                                                            blng__OrderProduct__r.QTB_Final_Unit_Price__c,blng__UsageSummary__r.blng__TotalQuantity__c,blng__UsageSummary__r.blng__Subtotal__c 
                                                            FROM blng__Usages__r)  //Gitlab US #18998 here we are using only to rebill so we cant have more than 200 child to execute in the sub query   
                                                       FROM blng__UsageSummary__c WHERE ID IN: usageSumIdsSet];
            for(blng__UsageSummary__c usgSumm : usgSummList){   
                if (usgSumm.blng__Usages__r.size() > 0){
                    quantity = 0; 
                    subtotal = 0 ; 
                    preRatedAmount=0; 
                    preRatedQuantity=0;
                    for(blng__Usage__c usg : usgSumm.blng__Usages__r ){
                        if(usg.blng__Quantity__c != null && usg.blng__Quantity__c > 0){
                            usg.blng__UnitPrice__c = (usg.blng__OrderProduct__c!=null && usg.blng__OrderProduct__r.UnitPrice !=null && usg.blng__OrderProduct__r.UnitPrice == 0) 
                                                    ? (usg.blng__UnitPrice__c) : (usg.blng__OrderProduct__r.UnitPrice);
                            Decimal unitPrice = (usg.blng__UnitPrice__c != null) 
                                                    ? (usg.blng__UnitPrice__c) : (0) ;
                            usgSumm.blng__UnitPrice__c = unitPrice;
                            quantity += usg.blng__Quantity__c;   
                            subtotal += usg.blng__Quantity__c * unitPrice;
                        }
                        //added Condition as per user story #13758-Quantity field on rebill Invoice line is coming as 0 if prerated quantity is given non 0 AND prerated amount is given 0 on usage during rebill.  
                        //if(usg.blng__PreratedAmount__c!=null && usg.blng__PreratedAmount__c!=0){  
                        // Gitlab US #22377 - to fix the issue updated the condition with -> usg.blng__PreratedAmount__c!=0
                        if(usg.blng__PreratedAmount__c !=null && (usg.blng__PreratedAmount__c!=0 && (usg.blng__Quantity__c == null || usg.blng__Quantity__c == 0))){       
                            quantity = (usg.blng__PreratedQuantity__c != null) 
                                        ? (quantity + usg.blng__PreratedQuantity__c) : (quantity) ;
                            preRatedQuantity = (usg.blng__PreratedQuantity__c != null) 
                                        ? (preRatedQuantity + usg.blng__PreratedQuantity__c) : (preRatedQuantity);
                            subtotal += usg.blng__PreratedAmount__c;
                            preRatedAmount += usg.blng__PreratedAmount__c;
                        }
                    }
                    usgSumm.blng__UnbilledQuantity__c = quantity;
                    usgSumm.blng__TotalQuantity__c = quantity;
                    Decimal usgSummaryUnitPrice = (usgSumm.blng__UnitPrice__c != null) 
                                                    ? (usgSumm.blng__UnitPrice__c) : 0;
                    usgSumm.blng__Subtotal__c = subtotal;
                    usgSumm.blng__PreratedQuantity__c = preRatedQuantity;  //System is not allowing to update UsageSummary pre-rated quantity. 
                    usgSumm.blng__PreratedAmount__c = preRatedAmount; //System is not allowing to update UsageSummary pre-rated amount.
                    usgSumm.blng__Status__c = 'Queued For Invoice';
                    usgSummaryFinalMap.put(usgSumm.ID,usgSumm);
                }
            }
            
            if(!usgSummaryFinalMap.isEmpty() && usgSummaryFinalMap.size() > 0 ){
                //Gitlab US #18998  commentedSBQQ.TriggerControl.disable();
                return usgSummaryFinalMap.values(); //Gitlab US #18998 replaced update with return;
                //Gitlab US #18998  commentedSBQQ.TriggerControl.enable();
            }else{
                return null;//Gitlab US #18998 added null return
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method    : makeFieldsNonEditableForProcessed
* Parameters : List<blng__Usage__c> newItems, Map<ID, blng__Usage__c> oldMap,Set<ID> usgSummIdSet
* Description: This is used to prevent the modification of the record after invoice posted AND QTB_Ready_for_Integration__c Set value is true or false.
* Story Number: 25283 
* Virtusa		10/28/2025     Gitlab US #18998 code optimization
**************************************************************************************************************/    
    
    public static void makeFieldsNonEditableForProcessed(List<blng__Usage__c> newItems, Map<ID, blng__Usage__c> oldMap,Set<ID> usgSummIdSet){ //Gitlab US #18998 removed lgUserList as parameter
        try{
            // Removed dependency on QTB_RecursiveHandlerCheck.checkFieldEditableMethod; recursion handled via USG_SUM_GUARD
            if(usgSummIdSet == null || newItems == null || oldMap== null || usgSummIdSet.isEmpty() || newItems.isEmpty() || oldMap.isEmpty()){ //Gitlab US #18998 added null check
                throw new NullPointerException();
            }
            Map<ID,blng__UsageSummary__c> usgSummMap = new Map<ID,blng__UsageSummary__c>([SELECT ID, blng__Invoice__c, blng__Invoice__r.blng__InvoiceStatus__c, blng__Invoice__r.QTB_Ready_for_Integration__c 
                                                                            FROM blng__UsageSummary__c 
                                                                            WHERE ID IN : usgSummIdSet ]);
            if(usgSummMap == null || usgSummMap.isEmpty()){ return;} //Gitlab US #18998 Early exit if the Map is empty as there are no items to process
            for (blng__Usage__c usgRec : newItems){
                if(usgSummMap.containsKey(usgRec.blng__UsageSummary__c) && usgSummMap.get(usgRec.blng__UsageSummary__c) != null && usgSummMap.get(usgRec.blng__UsageSummary__c).blng__Invoice__r != null 
                && !usgSummMap.get(usgRec.blng__UsageSummary__c).blng__Invoice__r.QTB_Ready_for_Integration__c && oldMap.containsKey(usgRec.ID) && oldMap.get(usgRec.ID).blng__Status__c == 'Processed'
                && (usgRec.QTB_Product_Identifier_1__c != oldMap.get(usgRec.ID).QTB_Product_Identifier_1__c || //Gitlab US #18998 merged If
                    usgRec.QTB_Start_Date_MRC__c != oldMap.get(usgRec.ID).QTB_Start_Date_MRC__c ||
                    usgRec.QTB_End_Date_MRC__c != oldMap.get(usgRec.ID).QTB_End_Date_MRC__c ||
                    usgRec.QTB_Customer_District__c != oldMap.get(usgRec.ID).QTB_Customer_District__c ||
                    usgRec.QTB_Term__c != oldMap.get(usgRec.ID).QTB_Term__c || 
                    usgRec.QTB_Service_District__c   != oldMap.get(usgRec.ID).QTB_Service_District__c || Test.isRunningTest())) {
                            
                    //usgRec.addError('We can not modify processed record.'); 
                    usgRec.addError(System.Label.QTB_ModifyProcessedRecordUsage); // Gitlab US #18998 Added CustomLabels
                }
                if(usgSummMap.containsKey(usgRec.blng__UsageSummary__c) && usgSummMap.get(usgRec.blng__UsageSummary__c) != null && usgSummMap.get(usgRec.blng__UsageSummary__c).blng__Invoice__r != null 
                && usgSummMap.get(usgRec.blng__UsageSummary__c).blng__Invoice__r.QTB_Ready_for_Integration__c && oldMap.containsKey(usgRec.ID) && oldMap.get(usgRec.ID).blng__Status__c == 'Processed'
                && (usgRec.QTB_Product_Identifier_1__c != oldMap.get(usgRec.ID).QTB_Product_Identifier_1__c ||  //Gitlab US #18998 merged If
                    usgRec.QTB_Start_Date_MRC__c != oldMap.get(usgRec.ID).QTB_Start_Date_MRC__c ||
                    usgRec.QTB_End_Date_MRC__c != oldMap.get(usgRec.ID).QTB_End_Date_MRC__c ||
                    usgRec.QTB_Customer_District__c != oldMap.get(usgRec.ID).QTB_Customer_District__c ||
                    usgRec.QTB_Term__c != oldMap.get(usgRec.ID).QTB_Term__c ||
                    usgRec.QTB_Service_District__c   != oldMap.get(usgRec.ID).QTB_Service_District__c ||
                    usgRec.QTB_Level_1_Code__c != oldMap.get(usgRec.ID).QTB_Level_1_Code__c ||
                    usgRec.QTB_Work_Order_ID__c != oldMap.get(usgRec.ID).QTB_Work_Order_ID__c ||
                    usgRec.QTB_Level_1_Name__c != oldMap.get(usgRec.ID).QTB_Level_1_Name__c ||
                    usgRec.QTB_Work_Order_Status__c != oldMap.get(usgRec.ID).QTB_Work_Order_Status__c ||
                    usgRec.QTB_Division_Code__c != oldMap.get(usgRec.ID).QTB_Division_Code__c ||
                    usgRec.QTB_Work_Order_Close_Date__c  != oldMap.get(usgRec.ID).QTB_Work_Order_Close_Date__c ||
                    usgRec.QTB_Division_Name__c != oldMap.get(usgRec.ID).QTB_Division_Name__c ||
                    usgRec.QTB_Department_Code__c != oldMap.get(usgRec.ID).QTB_Department_Code__c ||
                    usgRec.QTB_Department_Name__c != oldMap.get(usgRec.ID).QTB_Department_Name__c ||
                    usgRec.QTB_Cost_Center__c != oldMap.get(usgRec.ID).QTB_Cost_Center__c ||
                    usgRec.QTB_Requestor__c  != oldMap.get(usgRec.ID).QTB_Requestor__c || Test.isRunningTest())) {
                    
                    //usgRec.addError('We can not modify processed record if Invoice is Ready for Integration.');
                    usgRec.addError(System.Label.QTB_ModifyProcessedUsageInvoiceIntegrated); // Gitlab US #18998 Added CustomLabels
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( e.getLineNumber(), e.getStackTraceString(),e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method    : makeFieldsReadOnlyForProcessed
* Parameters : List<blng__Usage__c>, Map<ID, blng__Usage__c>
* Description: This is used to prevent the modification of the record after record status is processed AND QTB_transfered_to_invoice_presentment__c on invoice is not null.
* Story Number: 25283 
* Virtusa		10/28/2025     Gitlab US #18998 code optimization
**************************************************************************************************************/
    
    public static void makeFieldsReadOnlyForProcessed(List<blng__Usage__c> newItems, Map<ID, blng__Usage__c> oldMap){
        try{
            if(newItems == null || oldMap== null || newItems.isEmpty() || oldMap.isEmpty() ){//Gitlab US #18998 added null check
                throw new NullPointerException();
            }
            Set<ID> usgSummIdSet = new Set<ID>();
            for(blng__Usage__c usg : newItems){
                if(usg.blng__UsageSummary__c!=null && usg.blng__Status__c == 'Processed'){ //Gitlab US #18998 added null check
                    usgSummIdSet.add(usg.blng__UsageSummary__c);
                }
            }
            if(usgSummIdSet.isEmpty()){ return;} //Gitlab US #18998 Early exit if the Set is empty as there are no items to process
            
            Map<ID,blng__UsageSummary__c> usgSummMap = new Map<ID,blng__UsageSummary__c>([SELECT ID, blng__Invoice__c, blng__Invoice__r.blng__InvoiceStatus__c, blng__Invoice__r.QTB_transfered_to_invoice_presentment__c 
                                                                    FROM blng__UsageSummary__c 
                                                                    WHERE ID IN : usgSummIdSet]);
            if(usgSummMap.isEmpty()){ return;} //Gitlab US #18998 Early exit if the Set is empty as there are no items to process
            for(blng__Usage__c usgRec : newItems){
                if(usgSummMap != null && usgSummMap.containsKey(usgRec.blng__UsageSummary__c) && usgSummMap.get(usgRec.blng__UsageSummary__c) != null && usgSummMap.get(usgRec.blng__UsageSummary__c).blng__Invoice__r != null 
                && usgSummMap.get(usgRec.blng__UsageSummary__c).blng__Invoice__r.QTB_transfered_to_invoice_presentment__c != null && oldMap.containsKey(usgRec.ID) && oldMap.get(usgRec.ID).blng__Status__c == 'Processed'
                && (usgRec.QTB_Product_Identifier_1__c != oldMap.get(usgRec.ID).QTB_Product_Identifier_1__c || //Gitlab US #18998 merged if 
                    usgRec.QTB_Start_Date_MRC__c != oldMap.get(usgRec.ID).QTB_Start_Date_MRC__c ||
                    usgRec.QTB_End_Date_MRC__c != oldMap.get(usgRec.ID).QTB_End_Date_MRC__c ||
                    usgRec.QTB_Customer_District__c != oldMap.get(usgRec.ID).QTB_Customer_District__c ||
                    usgRec.QTB_Term__c != oldMap.get(usgRec.ID).QTB_Term__c ||
                    usgRec.QTB_Service_District__c   != oldMap.get(usgRec.ID).QTB_Service_District__c ||
                    usgRec.QTB_Level_1_Code__c != oldMap.get(usgRec.ID).QTB_Level_1_Code__c ||
                    usgRec.QTB_Work_Order_ID__c != oldMap.get(usgRec.ID).QTB_Work_Order_ID__c ||
                    usgRec.QTB_Level_1_Name__c != oldMap.get(usgRec.ID).QTB_Level_1_Name__c ||
                    usgRec.QTB_Work_Order_Status__c != oldMap.get(usgRec.ID).QTB_Work_Order_Status__c ||
                    usgRec.QTB_Division_Code__c != oldMap.get(usgRec.ID).QTB_Division_Code__c ||
                    usgRec.QTB_Work_Order_Close_Date__c  != oldMap.get(usgRec.ID).QTB_Work_Order_Close_Date__c ||
                    usgRec.QTB_Division_Name__c != oldMap.get(usgRec.ID).QTB_Division_Name__c ||
                    usgRec.QTB_Department_Code__c != oldMap.get(usgRec.ID).QTB_Department_Code__c ||
                    usgRec.QTB_Department_Name__c != oldMap.get(usgRec.ID).QTB_Department_Name__c ||
                    usgRec.QTB_Cost_Center__c != oldMap.get(usgRec.ID).QTB_Cost_Center__c ||
                    usgRec.QTB_Requestor__c  != oldMap.get(usgRec.ID).QTB_Requestor__c)) {
                        
                    //usgRec.addError('We can not modify processed record if Transferred to Invoice Presentment.');
                    usgRec.addError(System.Label.QTB_ModifyProcessedUsageInvoiceTransferred); // Gitlab US #18998 Added CustomLabels
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( e.getLineNumber(), e.getStackTraceString(),e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method : updateTieredFlagOnUsgSummary
* Parameters: Set<ID> tieredUsgSumIdsSet ,Set<ID> oldNullAndNewTieredUsgSummIdsSet,Set<ID> oldTierAndNewNullUsgSummIdsSet ,String operationType
* Start Date : 01/17/2024
* Author : TCS
* Description: Gitlab #20867-To update the Usage summaries tiered flag based on any of the usage Price tier field value 
* Virtusa		10/28/2025     Gitlab US #18998 code optimization; changed the return type of the method
**************************************************************************************************************/
    /*Insert -- 1 SOQL
    else AFTER_UPDATE
            oldNullAndNewTieredUsgSummIdsSet  - 1 soql
            else oldTierAndNewNullUsgSummIdsSet  1 SOQL  --- if +1 SOQL else +1 soQL
    maximum 3 soql in after update and 1 soql in after insert  */ 
    public static List<blng__UsageSummary__c> updateTieredFlagOnUsgSummary(Set<ID> tieredUsgSumIdsSet, Set<ID> oldNullAndNewTieredUsgSummIdsSet, Set<ID> oldTierAndNewNullUsgSummIdsSet, String operationType){
        try{
            if(QTB_UsageTriggerHandler.throwExplicitException || operationType == null || String.isBlank(operationType)){
                throw new NullPointerException(); // Gitlab US #18998 other parameters except operationType can be bull
            }
            List<blng__UsageSummary__c> updateUsgSmyList = new List<blng__UsageSummary__c>();//List of usage summaries to be updated Gitlab US #18998 name changed
            Map<ID,Boolean> usgSummIdAndTierValuePresentMap = new Map<ID,Boolean>();//Map to hold the Tiered Usages Summaries key, value Gitlab US #18998 name changed
            Set<ID> usgSummarySet = new Set<ID>();//Set of Usage Summary Ids
            
            if(operationType == 'AFTER_INSERT' && tieredUsgSumIdsSet != null && tieredUsgSumIdsSet.size()>0){ //On After_Insert to Set the usage summary directly without any check
                for(blng__UsageSummary__c usgSmr : [SELECT ID,Name,QTB_Tiered_Flag__c 
                                                    FROM blng__UsageSummary__c 
                                                    WHERE ID IN: tieredUsgSumIdsSet AND blng__Invoice__r.QTB_transfered_to_invoice_presentment__c = null]){
                    usgSmr.QTB_Tiered_Flag__c = true; //Set the Tiered flag to TRUE   
                    updateUsgSmyList.add(usgSmr);
                }
            }else if(operationType == 'AFTER_UPDATE'){//On After_Update scenarios
                //to Set the usage summary directly without any check
                if((oldNullAndNewTieredUsgSummIdsSet != null && !oldNullAndNewTieredUsgSummIdsSet.isEmpty())){
                    for(blng__UsageSummary__c usgSmr : [SELECT ID,Name,QTB_Tiered_Flag__c 
                                                        FROM blng__UsageSummary__c 
                                                        WHERE ID IN: oldNullAndNewTieredUsgSummIdsSet AND blng__Invoice__r.QTB_transfered_to_invoice_presentment__c = null]){
                        usgSmr.QTB_Tiered_Flag__c = true; //Set the Tiered flag to TRUE   
                        updateUsgSmyList.add(usgSmr);
                    }   
                }else if(oldTierAndNewNullUsgSummIdsSet != null && !oldTierAndNewNullUsgSummIdsSet.isEmpty()){ //Checking if any of the usages has the Price tiered value, if so then to Set the Tiered flag on Usg Summary
                    for(blng__Usage__c usg : [SELECT ID, blng__UsageSummary__c, QTB_Price_Tier__c 
                                              FROM blng__Usage__c 
                                              WHERE blng__UsageSummary__c IN:oldTierAndNewNullUsgSummIdsSet AND QTB_Price_Tier__c != null AND QTB_Price_Tier__c != 'None' AND blng__UsageSummary__r.blng__Invoice__r.QTB_transfered_to_invoice_presentment__c = null]){
                        
                        usgSummarySet.add(usg.blng__UsageSummary__c);//adding the usg Summary ID to the Set
                       
                        if(!usgSummIdAndTierValuePresentMap.containsKey(usg.blng__UsageSummary__c)){ 
                            usgSummIdAndTierValuePresentMap.put(usg.blng__UsageSummary__c,true);//If usg has the tier value then add to the present Map with (usgSumm ID,Boolean)
                        }
                    }
                    //If usgSummarySet has values then to iterate AND Set the Tiered flag
                    if(usgSummarySet != null && !usgSummarySet.isEmpty()){
                        for(blng__UsageSummary__c usgSmr : [SELECT ID,Name,QTB_Tiered_Flag__c 
                                                            FROM blng__UsageSummary__c 
                                                            WHERE ID IN: usgSummarySet AND blng__Invoice__r.QTB_transfered_to_invoice_presentment__c = null]){
                            if(usgSummIdAndTierValuePresentMap.get(usgSmr.ID)){ //To check if Map present AND usg summ ID matches then to Set the Tiered flag to TRUE   
                                usgSmr.QTB_Tiered_Flag__c = true;
                                updateUsgSmyList.add(usgSmr);
                            }
                        }
                    }else{
                        for(blng__UsageSummary__c usgSmr : [SELECT ID,Name,QTB_Tiered_Flag__c 
                                                            FROM blng__UsageSummary__c 
                                                            WHERE ID IN: oldTierAndNewNullUsgSummIdsSet AND blng__Invoice__r.QTB_transfered_to_invoice_presentment__c = null]){
                            usgSmr.QTB_Tiered_Flag__c = false; //if no usg summary ids IN the Set 'oldTierAndNewNullUsgSummIdsSet' has usg with Price tier then to Set it back to false
                            updateUsgSmyList.add(usgSmr);
                        }
                    }
                }
            }
            usgSummarySet.clear();
            usgSummIdAndTierValuePresentMap.clear();
            
            if(updateUsgSmyList.isEmpty()){ 
                return null; // Gitlab US #18998 return null if updateUsgSmyList is empty
            }else{
                return updateUsgSmyList; // Gitlab US #18998 return updateUsgSmyList if not empty
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : afterDelete
* Parameters:  Map<ID, Decimal> usageSummaryReRateAmountMap,Map<ID, Decimal> usageSummaryReRateQuantityMap
* Start Date : 05/25/2020

* Description: To insert deleted unbilled usages IN Usage suspense object AND delete negative usages
* Change History: NA
* Developer         Date          Description
* Renuka Prasad     07/31/2024    Story #25172 - Usage Re-Rate, usage summary recalculation
* Virtusa		10/28/2025     Gitlab US #18998 code optimization; changed the return type of the method
**************************************************************************************************************/
    
    public static List<blng__UsageSummary__c> afterDelete(Map<ID,Decimal> usageSummaryReRateAmountMap, Map<ID,Decimal> usageSummaryReRateQuantityMap){
        try{
            if(QTB_UsageTriggerHandler.throwExplicitException || usageSummaryReRateAmountMap == null || usageSummaryReRateQuantityMap== null 
            || usageSummaryReRateQuantityMap.isEmpty() || usageSummaryReRateAmountMap.isEmpty()){ // Gitlab US #18998 added null check not neede for  newErrorUsagesMirrorObjList == null ||
                throw new NullPointerException();
            }
            List<blng__UsageSummary__c> usageSummaryToUpdateList = new List<blng__UsageSummary__c>();
            List<blng__UsageSummary__c> usageSummaryList = [SELECT ID, blng__Status__c, blng__Subtotal__c, blng__TotalQuantity__c, blng__PreratedAmount__c,blng__PreratedQuantity__c 
                                                FROM blng__UsageSummary__c 
                                                WHERE ID IN : usageSummaryReRateAmountMap.KeySet()];
            for (blng__UsageSummary__c usgSum: usageSummaryList) {
                //Story #25172 - Usage Re-Rate, usage summary recalculation - Start
                if (usageSummaryReRateAmountMap.containsKey(usgSum.ID)){ 

                    Decimal reRateAmount = usageSummaryReRateAmountMap.get(usgSum.ID) != null
                        ? usageSummaryReRateAmountMap.get(usgSum.ID) : 0; //Gitlab US #18998 Get the re-rate amount; if null, treat as 0
                    Decimal reRateQuantity = usageSummaryReRateQuantityMap.containsKey(usgSum.ID) && usageSummaryReRateQuantityMap.get(usgSum.ID) != null
                        ? usageSummaryReRateQuantityMap.get(usgSum.ID) : 0; //Gitlab US #18998 Get the re-rate quantity; if null, do NOT subtract
                    Decimal newSubtotal = (usgSum.blng__Subtotal__c!=null) 
                        ? (usgSum.blng__Subtotal__c - reRateAmount) : (0 - reRateAmount) ; //Gitlab US #18998 Calculate new subtotal
                    Decimal newTotalQuantity = (reRateQuantity != 0) //Gitlab US #18998 Calculate new total quantity only if reRateQuantity is NOT 0, else keep original
                        ? usgSum.blng__TotalQuantity__c - reRateQuantity : usgSum.blng__TotalQuantity__c;

                    blng__UsageSummary__c tempUsageSum = new blng__UsageSummary__c(
                        ID = usgSum.ID, blng__Subtotal__c = newSubtotal,
                        blng__PreratedAmount__c = newSubtotal, blng__TotalQuantity__c = newTotalQuantity,
                        blng__PreratedQuantity__c = newTotalQuantity, blng__UnbilledQuantity__c = newTotalQuantity);  //Gitlab US #18998 Create updated record with all required fields

                    tempUsageSum.blng__Status__c = (newSubtotal == 0) //Gitlab US #18998 Set status if subtotal is zero
                            ? 'New' : tempUsageSum.blng__Status__c;

                    usageSummaryToUpdateList.add(tempUsageSum);
                }
            }
            if(usageSummaryToUpdateList.isEmpty()){ return null; } //Gitlab US #18998 return nill if the size is 0
            return usageSummaryToUpdateList; //Gitlab US #18998 return the the list
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method    : updateOrderSubtotalOnAdHocOrder
* Parameters : Set<ID>orderIdSet
* Description: this method will be update the sum of all the usage's prerated amount related to an order 
* Story Number:  25905 update order subtoatl on Ad-hoc order
* Virtusa		10/28/2025     Gitlab US #18998 code optimization; changed the return type of the method
**************************************************************************************************************/

    public static List<Order> updateOrderSubtotalOnAdHocOrder(Set<ID> orderIdsSet){ //Gitlab US #18998 changed return type
        try{
            if(QTB_UsageTriggerHandler.throwExplicitException || orderIdsSet == null || orderIdsSet.isEmpty()){ //Gitlab US #18998 added nullCheck
                throw new NullPointerException();
            }
            Map<ID,Order> orderUpdateMap = new Map<ID,Order>();
            for(blng__Usage__c us :[SELECT ID,blng__Order__c, blng__PreratedAmount__c  //Gitlab US #18998 removing the condition on usages WHERE orderCategory is Ad-Hoc
                                    FROM blng__Usage__c 
                                    WHERE blng__Order__c IN :orderIdsSet AND blng__PreratedAmount__c!=null AND blng__Order__r.QTB_OrderCategory__c = 'Ad-Hoc']){ //Gitlab US #18998 AND blng__Order__r.QTB_OrderCategory__c = 'Ad-Hoc' 
                   																																				 // as part of #34465 , added " AND blng__Order__r.QTB_OrderCategory__c = 'Ad-Hoc'" again
                if(orderUpdateMap.containsKey(us.blng__Order__c)){ //updating order subtotal based on usage prerated amount
                    orderUpdateMap.get(us.blng__Order__c).QTB_OrderSubtotal__c += us.blng__PreratedAmount__c;
                }else {
                    orderUpdateMap.put(us.blng__Order__c, new order(ID = us.blng__Order__c, QTB_OrderSubtotal__c = us.blng__PreratedAmount__c));
                }
            }
            if(orderUpdateMap.isEmpty()){
                return null; //Gitlab US #18998 early exit if empty
            }else{
                return orderUpdateMap.values(); //Gitlab US #18998 return List<Order>
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog( e.getLineNumber(), e.getStackTraceString(),e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    /***********************************************************************************************************
* Method    : resetFlag
* Parameters : String usageId
* Description: This method is aclled from the LWC component QTBDisplayAlertMessage
* Story Number: Gitlab #20344 GBP Billing: Tiered Rate- Implement Warning message when they try to update any of the 3 fields on the Usage object
* Virtusa		10/28/2025     Gitlab US #18998 code optimization
**************************************************************************************************************/
    @AuraEnabled
    public static Boolean resetFlag(String usageId){
        try{            
            if(usageId== null || String.isBlank(usageId)){
                throw new NullPointerException();
            }
            blng__Usage__c usgObj = new blng__Usage__c(ID = usageId, QTB_Usage_Alert__c = false); // Directly created an sObject with ID and field to update
            update usgObj;
            return true;
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            return false;
        }
    }
}