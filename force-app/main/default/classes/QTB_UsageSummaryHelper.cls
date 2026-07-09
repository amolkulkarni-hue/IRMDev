/*****************************************************************************************************
* Class: QTB_UsageSummaryHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to Usage Summary  object
* Requirement: SFCPQBLG-519
* Change History: 10-06-2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* 		 	 	10-06-2020
* Accenture	15-03-2021		Fixed the misplacement of function called inside For, GitLab # 1407 comments
* Accenture    17-03-2021      Added condition to only update usage summary status to new, if no usage under it
*                              GitLab # 1407 second revision
* Virtusa		28-08-2023     Gitlab US #17768 Defect fix 
* Virtusa		28-10-2025     Gitlab US #19002 code optimization 
*******************************************************************************************************/
public with sharing class QTB_UsageSummaryHelper{

    public static final String USAGESUMMARY_HELPER = 'QTB_UsageSummaryHelper';
    public static final String DEFAULT_PRODUCTS = 'Fuel Surcharge; Minimum Storage Charges; Minimum Invoice Charges'; //Gitlab US #19002 changed case
    //Gitlab US #19002 Recursion guard: tracks processed Usage Summary Ids per transaction for invoice status update
    private static Map<String, Boolean> processedForInvStatusMap = new Map<String, Boolean>();  // Key = Id (as String), Value = Boolean processed marker
    
    /***********************************************************************************************************
* Method : trigController
* Parameters: List<blng__UsageSummary__c>, Map<ID,blng__UsageSummary__c>,System.TriggerOperation
* Requirement :
* Start Date : 10-06-2020
* Author : Accenture
* Description: Generic method to handle all operations on the usage summary Records
**************************************************************************************************************/
    public static void trigController(List<blng__UsageSummary__c> usgSummaryNewList, Map<ID,blng__UsageSummary__c> usgSummaryOldMap,
                                    System.TriggerOperation operationType){ //Gitlab US #19002 renamed newlist and OldMap
                                       
        List<blng__UsageSummary__c> usgSummIDsQueuedToNewList = new List<blng__UsageSummary__c>();// Added as part of GitLab #1407, count usages under each usage summary
        Set<ID> defaultProductsUsageSummIdSet = new Set<ID>();    
        Map<ID,blng__UsageSummary__c> finalUpdateUsageSummaryMap = new Map<ID,blng__UsageSummary__c>(); //Gitlab US #19002 created a Map  for updating blng__UsageSummary__c only once when ever the blng__UsageSummary__c is to be Updated(New Structure of code)
        String billingCountry = (QTB_Billing_Countries__c.getValues(usgSummaryNewList[0].QTB_Legal_Entity_Country__c)) != null 
                                ? (QTB_Billing_Countries__c.getValues(usgSummaryNewList[0].QTB_Legal_Entity_Country__c).Name) : '';
        for (blng__UsageSummary__c usm : usgSummaryNewList){
            switch on operationType{
                //Gitlab #1407 Making the status of usage summary to new when all its usages are deleted
                when BEFORE_UPDATE {
                    //Gitlab US#24005 -- Scenario1 -- new usage creation
                    if(usm.blng__UnitPrice__c != null){
                       usm.QTB_UnitPrice__c = usm.blng__UnitPrice__c;
                    }  
                    //Gitlab US#24005 -- Scenario2 -- usage already present, invoice is getting created 
                    if(usgSummaryOldMap.get(usm.ID).blng__UnitPrice__c != usm.blng__UnitPrice__c && usgSummaryOldMap.get(usm.ID).blng__UnitPrice__c != null 
                    && usgSummaryOldMap.get(usm.ID).blng__UnitPrice__c != 0 && usm.blng__UnitPrice__c == 0){
                        usm.QTB_UnitPrice__c = usgSummaryOldMap.get(usm.ID).blng__UnitPrice__c; 
                    }
                    if(usgSummaryOldMap.get(usm.ID).blng__Status__c != usm.blng__Status__c && usm.blng__Status__c =='Cancelled'){
                        usm.blng__MatchingId__c='Invalid-'+usm.blng__MatchingId__c;
                    } 
                    if(usm.blng__Status__c == QTB_Constants.STATUS_QUEUED_FOR_INVOICE && usm.blng__PreratedQuantity__c == 0 // Gitlab US Gitlab US #19002 removed nullcheck from oldMap
                    && usm.blng__TotalQuantity__c == 0 && usm.blng__PreratedAmount__c == 0 && usm.blng__UnbilledQuantity__c == 0 && usm.blng__Subtotal__c == 0){
                        // usage summary status should be new only if there are no usages under it // GitLab # 1407
                        usgSummIDsQueuedToNewList.add(usm);
                    }
                }
                when AFTER_UPDATE{
                    //defect fix US#17768
                    //Setting usageSummId when InvoiceRunProcessingStatus is Will Not Invoice for default product AND other than billing only countries
                    if(usgSummaryOldMap.get(usm.ID).blng__InvoiceRunStatusIndex__c != usm.blng__InvoiceRunStatusIndex__c && usm.blng__Status__c == 'New'
                    && usm.blng__InvoiceRunStatusIndex__c == 'Will Not Invoice' && DEFAULT_PRODUCTS.containsIgnoreCase(usm.QTB_Product_Name__c)
                    && usm.QTB_Legal_Entity_Country__c != billingCountry
                    && !processedForInvStatusMap.containsKey((String)usm.Id) //Gitlab US #19002 check if the record is processed.
                    && (usm.blng__Order__r.QTB_OrderCategory__c == 'ReBill' //Gitlab US #19002 added at the start instead of checking inside the for Loop. 
                    && (usm.blng__OrderProduct__r.Product2.ProductCode == System.Label.QTB_Minimum_Storage || usm.QTB_Product_Name__c == 'Fuel Surcharge'
                        || usm.blng__OrderProduct__r.Product2.ProductCode == System.Label.QTB_Invoice_Minimum))){
                        
                        defaultProductsUsageSummIdSet.add(usm.ID); 
                    }                    
                }
            } 
        }
        switch on operationType{
            when BEFORE_INSERT{
                if(!usgSummaryNewList.isEmpty()){ //Gitlab US #19002 check if the parameter isempty before calling the method
                    countryClone(usgSummaryNewList); 
                    sitadMatchingAttributeAssignment(usgSummaryNewList); //Calling sitadMatchingAttributeAssignment method to update Matching attribute on usage summary(Gitlab #24893)
                }
            }
            when BEFORE_UPDATE{
                if(!usgSummIDsQueuedToNewList.isEmpty()){
                    getUsageCountByUsageSummary(usgSummIDsQueuedToNewList);
                }
            }
            when AFTER_UPDATE{
                if(!defaultProductsUsageSummIdSet.isEmpty()){
                    List<blng__UsageSummary__c> usgSummaryUpdateList = setUsgSummaryInvStatus(defaultProductsUsageSummIdSet); //Gitlab US #19002 starts by changing return Type
                    for (Id processedId : defaultProductsUsageSummIdSet){
                        processedForInvStatusMap.put((String)processedId, true); //Gitlab US #19002 mark as processed in this transaction to avoid re-entry across multiple trigger chunks
                    }
                    if(finalUpdateUsageSummaryMap!=null && usgSummaryUpdateList!=null && usgSummaryUpdateList.isEmpty()){
                        for(blng__UsageSummary__c usgSum: usgSummaryUpdateList){
                            finalUpdateUsageSummaryMap.put(usgSum.ID,usgSum); //Gitlab US #19002 first addition hence added directly to the Map.
                        }
                        usgSummaryUpdateList.clear();// 19002 ends
                    }
                }
            }
        }
        // //Gitlab US #19002 Updating only once as per the new structure -19002
        if(finalUpdateUsageSummaryMap!=null && !finalUpdateUsageSummaryMap.isEmpty()){ //Gitlab US #19002 performed single DML per object
            update finalUpdateUsageSummaryMap.values();
            finalUpdateUsageSummaryMap.clear();
        }
    }

/***********************************************************************************************************
* Method : countryClone
* Parameters: List<QTB_PurchaseOrder__c>
* Requirement : SFCPQBLG-519
* Start Date : 10-06-2020
* Author : Accenture
* Description:
* History		28-10-2025     Gitlab US #19002 Added null check and performed code optimization 
**************************************************************************************************************/
    public static void countryClone(List<blng__UsageSummary__c> usagesummaryList) {
        try{
            if(usageSummaryList == null || usageSummaryList.isEmpty() || QTB_UsageSummaryTriggerHandler.throwExplicitException){
                throw new NullPointerException();  //Gitlab US #19002 return early if either of the parameter is null
            }
            Set<ID> billingAccountSet = new Set<ID>(); //Gitlab US #19002 added Set keyword
            Set<ID> ordProductIdsSet = new Set <ID>(); //Gitlab US #19002 added Set keyword
            for (blng__UsageSummary__c us : usagesummaryList){
                billingAccountSet.add(us.blng__Account__c);
                ordProductIdsSet.add(us.blng__OrderProduct__c);
            }
            if(billingAccountSet.isEmpty() || ordProductIdsSet.isEmpty()){return; } //Gitlab US #19002 return early if the set is empty

            Map<ID,Account> accountToCountryMap = new Map<ID,Account>([SELECT ID, QTB_Legal_Entity_Country__c,QTB_Customer_Number__c,QTB_Account_Record_Type__c 
                                                                        FROM Account 
                                                                        WHERE ID IN :billingAccountSet]); //Gitlab US #19002 changed the indentation  of SOQL
            //Gitlab US#22731 -- OrderItemNumber added IN query
            Map<ID,Orderitem> ordItemToProductcodeMap = new Map<ID,Orderitem>([SELECT ID,OrderItemNumber,product2.ProductCode,QTB_PrefixMatchingID__c,QTB_Order_Product_Type__c,blng__InvoiceGroupId__c,Order.OrderNumber ,Order.QTB_OrderCategory__c 
                                                                            FROM OrderItem 
                                                                            WHERE ID IN :ordProductIdsSet]); //Gitlab US #19002 changed the indentation  of SOQL
            if(accountToCountryMap == null || accountToCountryMap.size() == 0 || ordItemToProductcodeMap ==null || ordItemToProductcodeMap.size()==0) {
                return; //Gitlab US #19002 return early if the map is empty
            }
            for (blng__UsageSummary__c usummary : usagesummaryList) {
                if(!accountToCountryMap.containsKey(usummary.blng__Account__c) && !ordItemToProductcodeMap.containsKey(usummary.blng__OrderProduct__c)) 
                {continue;} //Gitlab US #19002 move to the next Item in the Loop if the condition is not satisfied

                if(ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).QTB_PrefixMatchingID__c != null 
                && ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).QTB_Order_Product_Type__c == 'ReBill'){
                    //Gitlab US#22731 --Changing the matchingAttribute value from orderNumber to OrderItemNumber for unique value
                    usummary.blng__MatchingAttribute__c = ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).OrderItemNumber;// ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).QTB_PrefixMatchingID__c;
                }
                if(ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).blng__InvoiceGroupId__c != null 
                && ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).Order.QTB_OrderCategory__c == 'Ad-hoc'){
                    //Gitlab US#22731 --Changing the matchingAttribute value from orderNumber to OrderItemNumber for unique value
                    usummary.blng__MatchingAttribute__c = ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).blng__InvoiceGroupId__c;// ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).QTB_PrefixMatchingID__c;
                }
                
                String prefix = ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).QTB_PrefixMatchingID__c != null 
                                        ? ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).QTB_PrefixMatchingID__c 
                                        : ''; //Gitlab US #19002 Used Ternary operators to store the value of prefix

                usummary.blng__MatchingId__c = prefix+ accountToCountryMap.get(usummary.blng__Account__c).QTB_Customer_Number__c + 
                                            ordItemToProductcodeMap.get(usummary.blng__OrderProduct__c).product2.ProductCode;

                if(accountToCountryMap.get(usummary.blng__Account__c).QTB_Account_Record_Type__c.containsIgnoreCase('Billing')){
                    usummary.QTB_Legal_Entity_Country__c = accountToCountryMap.get(usummary.blng__Account__c).QTB_Legal_Entity_Country__c;
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), USAGESUMMARY_HELPER);
            throw e;
        }
    }

/*********************************************************************************************************
* Method Name: sitadMatchingAttributeAssignment
* Parameters: List<blng__UsageSummary__c> usageSumList
* Return Type: void
* Requirement: Gitlab #24893
* Description: This Method is to update Matching attribute on Usage summary with Order Case Number For SITAD.
* History		28-10-2025     Gitlab US #19002 Added null check and performed code optimization 
**********************************************************************************************************/ 
    public static void sitadMatchingAttributeAssignment(List<blng__UsageSummary__c> usageSumList){
        try{
            if (usageSumList == null || usageSumList.isEmpty() || QTB_UsageSummaryTriggerHandler.throwExplicitException) {
                throw new NullPointerException();  // Gitlab US #19002 return early if either of the parameter is null
            }
            Set<ID> billingOrderSet = new Set<ID>();
            for(blng__UsageSummary__c usgSum:usageSumList){
                if(usgSum.blng__Order__c!=null) billingOrderSet.add(usgSum.blng__Order__c); //adding billingorderId IN billingOrderSet Set
            }
            
            List<String> getSITADCountries = System.Label.QTB_SITAD_Countries.split(';');//GitLab #27021 - Fetching QTB_SITAD_Countries CustomLable Values 
            Map<ID,Order> orderIdsMap = new Map<ID,Order>([SELECT ID,QTB_Case_Number__c,QTB_DM_Source_System_Name__c,QTB_OrderCategory__c,OrderNumber
                                                           FROM Order //Gitlab #27220 - added 'Ad-Hoc' IN below query to support Additional Order Creation
                                                           WHERE QTB_DM_Source_System_Name__c = 'SITAD' AND QTB_OrderCategory__c IN ('Evergreen','Ad-Hoc') AND Account.QTB_Legal_Entity_Country__c IN:getSITADCountries AND ID IN:billingOrderSet]);
            if(orderIdsMap.size() == 0){ return;}  // Gitlab US #19002 return early if the SOQL RETURN NOTHING
            for(blng__UsageSummary__c usageSum :usageSumList){ 
                if(orderIdsMap.containsKey(usageSum.blng__Order__c)){ //Gitlab#27807 - assigning OrderNumber to Usagesummary Matching Attribure if Order CaseNumber is empty for SITAD Additional Order
                    usageSum.blng__MatchingAttribute__c = (orderIdsMap.get(usageSum.blng__Order__c).QTB_OrderCategory__c == 'Ad-Hoc' && orderIdsMap.get(usageSum.blng__Order__c).QTB_Case_Number__c == null)
                            ? (orderIdsMap.get(usageSum.blng__Order__c).OrderNumber) : (orderIdsMap.get(usageSum.blng__Order__c).QTB_Case_Number__c);
                } // Gitlab US #19002 used TERNARY OPERATORS
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), USAGESUMMARY_HELPER);
            throw e;
        }
    }
	 
/***********************************************************************************************************
* Method        : getUsageCountByUsageSummary
* Parameters    : List<blng__UsageSummary__c>
* Requirement   : GitLab # 1407
* Start Date    : 17-03-2021
* Author        : Accenture
* Description   : getUsageCountByUsageSummary(List<blng__UsageSummary__c> usageSummaries) is called from before update
* History		28-10-2025     Gitlab US #19002 Added null check and performed code optimization 
**************************************************************************************************************/
    private static void getUsageCountByUsageSummary(List<blng__UsageSummary__c> usageSummaries){
        try{
            if(usageSummaries == null || usageSummaries.isEmpty()){ //Gitlab US #19002  return early if either of the parameter is null
                throw new NullPointerException();
            }
            Map<ID,Integer> usageCountByUsageSummaryMap = new Map<ID,Integer>();
            for(AggregateResult eachResult : [SELECT blng__UsageSummary__c, COUNT(ID) usages //Gitlab US #19002 corrected the indentation of the SOQL query
                                                FROM blng__Usage__c
                                            WHERE blng__UsageSummary__c IN :usageSummaries AND blng__UsageSummary__c != null AND QTB_UsedforRerate__c = FALSE GROUP BY blng__UsageSummary__c]) {
                if(eachResult.get('blng__UsageSummary__c') != null){
                    usageCountByUsageSummaryMap.put(ID.valueOf(String.valueOf(eachResult.get('blng__UsageSummary__c'))),Integer.valueOf(eachResult.get('usages')));
                }
            }
            for(blng__UsageSummary__c usgSum : usageSummaries){
                if(usageCountByUsageSummaryMap.get(usgSum.ID) == null){
                    SBQQ.TriggerControl.disable();
                    usgSum.blng__Status__c = QTB_Constants.STATUS_NEW;
                    SBQQ.TriggerControl.enable();
                }
            }
        } catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), USAGESUMMARY_HELPER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method 	 : setUsgSummaryInvStatus
* Parameters : Set<ID> defaultProductsUsageSummIdSet
* Author     : Virtusa
* Description: Defect fix US#17768 -- Setting the UsageSummaryStatus to Pending Billing for other than billingOnlyCountries for default products(Fuel Surcharge, Minimum Storage Charges, Minimum Invoice Charges)
: explicitely setting blng__InvoiceRunProcessingStatus__c value because sometime usageSummary is failing to Set status due to billing package issue(script thrown exception)
* History		28-10-2025     Gitlab US #19002 Added null check and performed code optimization and changed the the return type
**************************************************************************************************************/
    public static List<blng__UsageSummary__c> setUsgSummaryInvStatus(Set<ID> defaultProductsUsageSummIdSet){ //Gitlab US #19002 changed the return type of the method
        try{
            if(defaultProductsUsageSummIdSet == null || defaultProductsUsageSummIdSet.isEmpty() || QTB_UsageSummaryTriggerHandler.throwExplicitException){
                throw new NullPointerException();  // Gitlab US #19002 return early if either of the parameter is null
            }
            List<blng__UsageSummary__c> usgSummList = new List<blng__UsageSummary__c>();
            for(blng__UsageSummary__c usgSumm : [SELECT ID FROM blng__UsageSummary__c
                                                WHERE ID IN : defaultProductsUsageSummIdSet]){ //Gitlab US #19002 changed formatting
                                            // removed as part of Gitlab US#19002 ,QTB_Product_Name__c,QTB_Legal_Entity_Country__c,blng__Order__c,blng__OrderProduct__c,blng__OrderProduct__r.Product2.ProductCode,blng__Order__r.QTB_OrderCategory__c, blng__InvoiceRunProcessingStatus__c,blng__InvoiceRunStatusIndex__c
                usgSummList.add(new blng__UsageSummary__c( ID = usgSumm.ID, 
                                                        blng__InvoiceRunProcessingStatus__c = 'Pending Billing',
                                                        blng__InvoiceRunStatusIndex__c = 'Pending Billing'));
            }
            //Gitlab US #19002 mark as processed in this transaction to avoid re-entry across multiple trigger chunks Using internal static Map processedForInvStatusMap as recursion guard; no longer toggling global flag.
            if(!usgSummList.isEmpty()){ //Gitlab US #19002 added return type
               return usgSummList; 
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), USAGESUMMARY_HELPER);
            throw e;
        }
    }
}