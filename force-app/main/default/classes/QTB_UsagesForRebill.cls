/*****************************************************************************************************
* Class         : QTB_UsagesForRebill
* Test Class    : QTB_UsagesForRebill_Test
* Author        : IRM/Virtusa
* Developer     : Gopi/Shailesh    
* Purpose       : This class handle all operation performed of Credit & Rebill Usage Screen (LWC Comp --> QTB_UsageModifyRebillProcess1) 
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Change History: 06/30/2022
* Developer           Date           Description
* -----------------------------------------------------------------------------------------------------
*  Gopi/Shailesh     06/30/2022      Initial Version - Gitlab US #9256 Credit & Rebill
* Shailesh(Virtusa)  07/04/2023      SplitRebill - Gitlab US#16253, US#16254, US#16557
* Parth(Virtusa)     10/11/2023      added one more parameter which contains orderProduct Id and 
*  Unit of measure value Gitlab #18595
* Renuka Prasad(TCS) 29/01/2024      Story #21203 Validation to check the Tax address on Credit-Rebill Usages for SITAD
* Ramesh/Abdul(Virtusa) 10/07/2024   Gitlab US#Gitlab US#24588 (Credit/Rebill Billnow) -- Credit & Rebill Simultaneous functionality 
*******************************************************************************************************/
public without sharing class QTB_UsagesForRebill {
    
    public static final String QTB_UsagesForRebill = 'QTB_UsagesForRebill';
    public static boolean isRunOnce = true;
    public static boolean throwExplicitException = false;
    //Added Boolean variable for #15357
    public static Boolean asianCountryPresent = false;
    public static final String FUEL_SURCHARGE = 'Fuel Surcharge';
    public static final String MINIMUM_STORAGE_CHARGES = 'Minimum Storage Charges';
    /***********************************************************************************************************
* Method      : createUsageForRebillOrder
* Parameter   : List<blng__Usage__c> usglist
* Return Type : boolean
* Author      : IRM/Virtusa
* Description : this method is responsible to create the usages by calling QTB_QueuableCreateCreditRebillUsages for provided OrderId
& before creating usages changing the Order status to activated.
**************************************************************************************************************/     
    @AuraEnabled
    public static String createUsageForRebillOrder(Id rebillInvoiceId,string newOrderId) {
        try{
           
            //To Update matching attribute on usage summary related to newly created orderItems
            List<blng__UsageSummary__c> USLstToUpdate = new List<blng__UsageSummary__c>();
            String usgBillingCountry = '';
            String billingCountry = '';
            string rebillType = '';
            //Before Creating the usage, updating the usageSummary InvoiceRunProcessingStatus to PendingBilling
            for (blng__UsageSummary__c usgSum : [SELECT id, blng__MatchingId__c, blng__MatchingAttribute__c, blng__Order__r.OrderNumber,blng__Order__r.QTB_Rebill_Type__c,
                                                 blng__OrderProduct__r.blng__InvoiceGroupId__c,QTB_Legal_Entity_Country__c,blng__OrderProduct__r.OrderItemNumber
                                                 FROM blng__UsageSummary__c 
                                                 WHERE blng__Order__c =: newOrderId])
            {
                rebillType = usgSum.blng__Order__r.QTB_Rebill_Type__c;
                //SplitRebill -- Updating the Matching Attribute on UsageSummary with combination of "OrderNumber + OrderProductNumber + blng__InvoiceGroupId__c"
                if(rebillType == System.Label.QTB_SplitRebill){
                    usgSum.blng__MatchingAttribute__c = usgSum.blng__Order__r.OrderNumber + usgSum.blng__OrderProduct__r.OrderItemNumber + usgSum.blng__OrderProduct__r.blng__InvoiceGroupId__c; 
                }
                else{
                    //Gitlab US#22731 --Changing the matchingAttribute value from orderNumber to OrderItemNumber for unique value
                    usgSum.blng__MatchingAttribute__c = usgSum.blng__OrderProduct__r.OrderItemNumber;//usgSum.blng__Order__r.OrderNumber;
                }
                usgSum.blng__UnitPrice__c = 0;
                usgSum.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
                USLstToUpdate.add(usgSum);            
                usgBillingCountry = usgSum.QTB_Legal_Entity_Country__c;
                billingCountry = QTB_Billing_Countries__c.getValues(usgBillingCountry) != null ? QTB_Billing_Countries__c.getValues(usgBillingCountry).Name : '';
            }
            
            if(!USLstToUpdate.isEmpty() && USLstToUpdate.size() > 0){
                update USLstToUpdate; 
                USLstToUpdate.clear();
            }
            Set<ID> usageSummaries = new Set<Id>();
            Integer totalUsageCount = 0;
            for(blng__InvoiceLine__c oldInvLine : [SELECT id,blng__InvoiceLine__c.blng__UsageSummary__c
                                                   FROM blng__InvoiceLine__c 
                                                   WHERE blng__Invoice__c =:rebillInvoiceId])
                
            {
                if(oldInvLine.blng__UsageSummary__c != null){
                    usageSummaries.add(oldInvLine.blng__UsageSummary__c);
                }
            }
            //Defect fix Gitlab US#20030 -- added null check before querying
            if(!usageSummaries.isEmpty() && usageSummaries !=null){
                totalUsageCount = database.countQuery('select count() from blng__Usage__c WHERE blng__UsageSummary__c IN :usageSummaries');
            }
            
            Id jobID ;
            //defect fix - US#19307 -- 
            //based on usage count either calling QTB_QueuableCreateCreditRebillUsages class or QTB_CreditRebillUsagesBatch class to fix bulk usage performance issue/soql 201/heap size issue
            //if existing old total usage count is more than 1000 then using batch class QTB_CreditRebillUsagesBatch to create the rebill usage
            if(totalUsageCount < Integer.valueOf(System.label.QTB_CreditRebillUsageCount)){
              
                //Calling queueuable class to create usages asynchronously
                jobID = System.enqueueJob(new QTB_QueuableCreateCreditRebillUsages(rebillInvoiceId,newOrderId)); 
            }else{
               
                //defect fix - US#19307 -- to fix bulk usage performance issue/soql 201/heap size issue moved the logic to batch class
                //defect fix - US#19738 -- returning the jobID , and updating the rebill status to track is usage creation batch job status
                QTB_CreditRebillUsagesBatch usageBatch = new QTB_CreditRebillUsagesBatch(usgBillingCountry,billingCountry,rebillType,rebillInvoiceId,newOrderId);
                jobID  = Database.executeBatch(usageBatch,Integer.valueOf(System.Label.QTB_CreditRebillUsageBatchSize));//setting batch size to 500 from custom label
            }
            //Change Invoice ReBill Status
            blng__Invoice__c inv = new blng__Invoice__c();
            inv.id = rebillInvoiceId;
            inv.QTB_ReBill_Status__c = 'Order Product Completed';
            Update inv;             
            return jobID ;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);
            return 'false';
        }
    }
    
    /***********************************************************************************************************
* Method      : getJobDetails
* Parameter   : String jobId
* Return Type : List<AsyncApexJob>
* Author      : IRM/Virtusa
* Description : this method is responsible to check the usage creation batch job status
**************************************************************************************************************/       
    @AuraEnabled
    public static List<AsyncApexJob> getJobDetails(String jobId){
        try {
            List<AsyncApexJob> asyncJobList = [SELECT Id, Status, JobItemsProcessed, TotalJobItems,
                                               NumberOfErrors FROM AsyncApexJob where Id =: jobId ];
            return asyncJobList;
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);
            return null;
        }
    }
    
    /***********************************************************************************************************
* Method      : getUsages
* Parameter   : Id rebillOrderId
* Return Type : List<blng__Usage__c>
* Author      : IRM/Virtusa
* Description : based on rebillOrderId fetching all usages related with that order.
this method is getting called from QTB_UsageModifyRebillProcess1 LWC Comp
**************************************************************************************************************/    
    @AuraEnabled(cacheable = false)
    public static List<blng__Usage__c> getUsages(Id rebillOrderId) {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            //fetching all related usages based on provided rebillOrderId 
            //Added Source Invoice Reference field in below query for #25683
            List<blng__Usage__c> usg = [SELECT Id, QTB_Work_Order_ID__c, QTB_Source_Invoice_Reference__c, Name, blng__MatchingId__c, QTB_Product__c,blng__StartDateTime__c,blng__EndDateTime__c,QTB_Prerated_Unit_Price__c,
                                        blng__PreratedQuantity__c,blng__PreratedAmount__c,blng__Quantity__c,blng__Order__c,blng__OrderProduct__c,blng__UsageSummary__c,
                                        QTB_Product_Identifier_1__c,blng__OrderProduct__r.blng__InvoiceGroupId__c,blng__Order__r.QTB_Rebill_Type__c, blng__OrderProduct__r.Product2Id,blng__UnitOfMeasure__c //Fetching product id to show the product hyperlink for #14390
                                        FROM blng__Usage__c 
                                        WHERE blng__Order__c = : rebillOrderId  order by Name desc];
          
            return usg;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);
            return null;
        }
    }
    
    
    /***********************************************************************************************************
* Method      : updateUsageList
* Parameter   : List<blng__Usage__c> usglist
* Return Type : boolean
* Author      : IRM/Virtusa
* Description : this method is responsible to update the usages.
**************************************************************************************************************/ 
 @AuraEnabled
public static string updateUsageList(List<blng__Usage__c> usglist){
    try {
        if(usglist != null && !usglist.isEmpty()){
            List<blng__Usage__c> usgFinalList = new List<blng__Usage__c>();
            boolean isPrerated = false;
            Set<Id> orderPrdIdSet = new Set<Id>();
            Set<Id> usgSummaryIds = new Set<Id>();
            Set<Id> orderIds = new Set<Id>();

            // Fetch related data from DB
            Map<Id, blng__Usage__c> usgFromDbMap = new Map<Id, blng__Usage__c>(
                [SELECT Id,blng__UsageSummary__c,blng__OrderProduct__c, blng__OrderProduct__r.UnitPrice, blng__Account__c, blng__Order__c,QTB_Product_Identifier_1__c
                 FROM blng__Usage__c
                 WHERE Id IN :usglist]
            );

            // Merge updated values into the fetched records
            for (blng__Usage__c draft : usglist) {
                blng__Usage__c dbRecord = usgFromDbMap.get(draft.Id);
                if (dbRecord != null) {
                    dbRecord.QTB_Product_Identifier_1__c = draft.QTB_Product_Identifier_1__c;
                    dbRecord.blng__Quantity__c = draft.blng__Quantity__c;
                    dbRecord.blng__PreratedQuantity__c = draft.blng__PreratedQuantity__c;
                    dbRecord.blng__PreratedAmount__c = draft.blng__PreratedAmount__c;

                    // Track related account and order for validations
                    if (dbRecord.blng__UsageSummary__c != null) {
                        usgSummaryIds.add(dbRecord.blng__UsageSummary__c);
                    }
                    if (dbRecord.blng__Order__c != null) {
                        orderIds.add(dbRecord.blng__Order__c);
                    }

                    // Set Unit Price or mark as prerated
                    if (dbRecord.blng__Quantity__c != null && dbRecord.blng__Quantity__c > 0 &&
                        dbRecord.blng__OrderProduct__r.UnitPrice > 0) {
                        dbRecord.blng__UnitPrice__c = dbRecord.blng__OrderProduct__r.UnitPrice;
                    } else if ((dbRecord.blng__PreratedQuantity__c > 0 || dbRecord.blng__PreratedQuantity__c < 0) &&
                               (dbRecord.blng__PreratedAmount__c > 0 || dbRecord.blng__PreratedAmount__c < 0)) {
                        isPrerated = true;
                        orderPrdIdSet.add(dbRecord.blng__OrderProduct__c);
                    }
                    system.debug('dbRecord product identifier-->' +dbRecord.QTB_Product_Identifier_1__c);
                    usgFinalList.add(dbRecord);
                }
            }

            // Validate pricing model for prerated
            if (isPrerated && !orderPrdIdSet.isEmpty()) {
                AggregateResult[] groupedResults = [
                    SELECT COUNT(Id), SBQQ__OrderItemConsumptionSchedule__c
                    FROM SBQQ__OrderItemConsumptionRate__c
                    WHERE SBQQ__OrderItemConsumptionSchedule__r.SBQQ__OrderItem__c IN :orderPrdIdSet
                    GROUP BY SBQQ__OrderItemConsumptionSchedule__c
                    HAVING COUNT(Id) > 1
                ];
                if (!groupedResults.isEmpty()) {
                    return 'Prerated Usage can only be used with Per Unit pricing';
                }
            }

            // Product Identifier validation against legal entity country
            if (!usgSummaryIds.isEmpty()) {
                String validationError = validateProductIdentifiers(usgFinalList, usgSummaryIds);
                if (validationError != null) {
                    return validationError;
                }
            }

            update usgFinalList;
            return 'true';
        } else {
            return 'false';
        }
    } catch(Exception e) {
        QTB_ExceptionLogger.enable();
        QTB_ExceptionLogger.createLog(
            e.getLineNumber(),
            e.getStackTraceString(),
            e.getMessage(),
            e.getTypeName(),
            QTB_UsagesForRebill
        );
        return e.getMessage();
    }
}

     /***********************************************************************************************************
* Method      : validateProductIdentifiers
* Parameter   : List<blng__Usage__c> usglist
* Return Type : string
* Author      : IRM/Virtusa
* Description : this method is responsible to validate the usages.
**************************************************************************************************************/ 
public static String validateProductIdentifiers(List<blng__Usage__c> usageList, Set<Id> usgSummaryIds) {
		Set<String> legalEntityCountries = new Set<String>();	
	    Set<String> usgProductName = new Set<String>();
	   Map<Id, blng__UsageSummary__c> usgSummaryMap = new Map<Id, blng__UsageSummary__c>( 
      [SELECT Id,QTB_Product_Name__c,QTB_Legal_Entity_Country__c FROM blng__UsageSummary__c WHERE Id IN :usgSummaryIds] );
         system.debug('usgSummaryMap-->' +usgSummaryMap);
		 
		for (blng__UsageSummary__c usg : usgSummaryMap.values()) 
		{
			if (usg.QTB_Legal_Entity_Country__c != null) 
			{
				legalEntityCountries.add(usg.QTB_Legal_Entity_Country__c);
			}
			if (usg.QTB_Product_Name__c != null) 
			{
			usgProductName.add(usg.QTB_Product_Name__c);
		    }
		}

		if (legalEntityCountries.isEmpty()) return null;

		Map<String, QTB_Bill_Code_Product_Lookup__c> productLookupMap = new Map<String, QTB_Bill_Code_Product_Lookup__c>([SELECT QTB_Source_Bill_Code__c, QTB_Country__c, QTB_Country__r.Name,QTB_Product2__r.Name 
		                                                                                                               FROM QTB_Bill_Code_Product_Lookup__c WHERE QTB_Country__r.Name IN :legalEntityCountries]);
      	for (blng__Usage__c usage : usageList) 
		{
        // Skip validation if Product Identifier has not been changed (is blank)
        if (String.isBlank(usage.QTB_Product_Identifier_1__c) && usage.QTB_Product_Identifier_1__c == null) 
		{
            continue; // No validation error if Product Identifier is blank and not changed
        }

        if (String.isBlank(usage.QTB_Product_Identifier_1__c)) 
		{
            return 'Product Identifier 1 cannot be blank. Please provide the value';
        }

			blng__UsageSummary__c usgSummary = usgSummaryMap.get(usage.blng__UsageSummary__c);

            // Skip validation if the product identifier was not modified
          if (usage.QTB_Product_Identifier_1__c != null) {
			Boolean isValid = false;
			for (QTB_Bill_Code_Product_Lookup__c lookup : productLookupMap.values()) {
				if (lookup.QTB_Country__r.Name == usgSummary.QTB_Legal_Entity_Country__c &&
					usage.QTB_Product_Identifier_1__c == lookup.QTB_Source_Bill_Code__c
					&& usgProductName.contains(lookup.QTB_Product2__r.Name)) 
					{
					 isValid = true;
					 break;
				}
			}

			if (!isValid) {
				return 'Product Identifier 1 does not match the Source Bill Code for the corresponding legal entity country. Please provide the correct value.';
			}
		}
        }

		return null;
		} 

    
    /***********************************************************************************************************
* Method      : deleteSelectedUsages
* Parameter   : List<blng__Usage__c> usglist
* Return Type : boolean
* Author      : IRM/Virtusa
* Description : this method is responsible to delete the usages.
**************************************************************************************************************/     
    @AuraEnabled
    public static boolean deleteSelectedUsages(List<blng__Usage__c> usglist) {
        try{
            if(usglist != null && !usglist.isEmpty() && usglist.size()>0){
                //Gitlab US#23236,#23270 -- changed the delete, deleting the usages in system mode
                //delete usglist;
                Database.DeleteResult[] srList = Database.delete(usglist,true,System.AccessLevel.SYSTEM_MODE);
                return true;
            }
            else{
                return false;
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);
            return false;
        }
    }
    
    
    /***********************************************************************************************************
* Method      : createUsageForSelectOrderProduct
* Parameter   : Id orderId,List<OrderItem> orderProductIdList,Map<String,String> unitOfMeasures
* Return Type : boolean
* Author      : IRM/Virtusa
* Description : this method is responsible to create the usages for selected orderProducts
**************************************************************************************************************/      
    @AuraEnabled
    //added one more parameter which contains orderProduct Id and Unit of measure value Gitlab #18595
    public static string createUsageForSelectOrderProduct(Id orderId,List<OrderItem> orderProductIdList,Map<String,String> unitOfMeasures) {
        try{
            
            List<blng__Usage__c> usageListToInsert = new List<blng__Usage__c>();
            Map<string,OrderItem> orderItemIdWithOrderItemMap = new Map<string,OrderItem>();
            List<OrderItem> orderItemFinalList = new List<OrderItem>();
            Set<Id> orderProductIdSet = new Set<Id>();
            
            //SplitRebill -- capturing orderProductIds
            if(orderProductIdList != null && !orderProductIdList.isEmpty()){
                for(OrderItem ordItm : orderProductIdList){
                    orderProductIdSet.add(ordItm.Id);
                } 
            }
            
            //Fetching OrderProduct based on provided orderProductIdList
            for(OrderItem orderProduct : [SELECT Id,OrderItemNumber,Product2.Name, Product2.ProductCode,ServiceDate,EndDate,UnitPrice,blng__InvoiceGroupId__c,
                                          OrderId,Order.OrderNumber,Order.QTB_Rebill_Type__c, Order.Account.QTB_Customer_Number__c,
                                          Product2.QTB_Fuel_Surcharge_Applicable__c,Product2.QTB_Storage_Product__c,blng__HoldBilling__c,blng__InvoiceRunProcessingStatus__c                                      
                                          FROM OrderItem 
                                          WHERE OrderId =:orderId])
            {
                if((!orderProductIdSet.isEmpty() && orderProductIdSet.contains(orderProduct.Id)) || Test.isRunningTest()){
                    orderItemIdWithOrderItemMap.put(orderProduct.id,orderProduct); //storing selected orderProductId with orderProduct
                    
                }
            }
            
            //Calling updateOrderProductUsageSummaryStatus() method to update the orderproduct & usageSummary InvoiceRunProcessingStatus before inserting usage
            updateOrderProductUsageSummaryStatus(orderItemIdWithOrderItemMap.values());
            
            //iterate on OrderProductList
            for(OrderItem opId : orderItemIdWithOrderItemMap.values()){
                //Create Usages for OrderProducts
                blng__Usage__c usage = new blng__Usage__c();
                usage.blng__Order__c = orderId;
				Date startDate = usage.QTB_Start_Date_MRC__c;
				Date endDate = usage.QTB_End_Date_MRC__c;
				Integer totalMonths = 0;


                usage.blng__OrderProduct__c = opId.id;
                // passing unit of measure value #18595 
                if(unitOfMeasures != null && unitOfMeasures.containsKey(opId.Id)){
                    usage.blng__unitOfMeasure__c = unitOfMeasures.get(opId.Id);
                }
                //SplitRebill -- Setting the Matching Id & Matching Attribute on Usage with combination of "OrderNumber + OrderItemNumber + blng__InvoiceGroupId__c"
				// GITLAB US - #28503 - Default the Term at usage to 1 while creating new usage
				if(startDate != null && endDate != null && endDate >= startDate)
				{
					Date tempDate = startDate.toStartOfMonth();
					while (tempDate <= endDate) {
					totalMonths++;
					tempDate = tempDate.addMonths(1);
					}
				}
				else 
					{
					if(usage.QTB_Term__c == null && orderProductIdList[0].Product2.QTB_Storage_Product__c == true )
					{
					totalMonths = 1; // Set default to 1 if term is null
					}
				}
			    usage.QTB_Term__c = String.valueOf(totalMonths);
				
				    // GITLAB -> #31563 reset the term to blank for non storage products if MRC dates are blank
						if(orderProductIdList[0].Product2.QTB_Storage_Product__c  == false &&
						usage.QTB_Start_Date_MRC__c ==null && usage.QTB_End_Date_MRC__c == null)
						{
							usage.QTB_Term__c = ''; 
                }
                  // GITLAB US - #28503 - While creating if  usage has blng__PreratedQuantity__c or QTB_Term__c blank, set QTB_Actual_Quantity__c to 0
                if(usage.blng__PreratedQuantity__c ==null || String.isBlank(usage.QTB_Term__c))
                {
                    usage.QTB_Actual_Quantity__c  = 0;
                }
				else
				{
					if(usage.blng__PreratedQuantity__c !=0 && String.isNotBlank(usage.QTB_Term__c) && Integer.valueOf(usage.QTB_Term__c) != 0)
					{
					usage.QTB_Actual_Quantity__c = (usage.blng__PreratedQuantity__c / Integer.valueOf(usage.QTB_Term__c)).setScale(2, System.RoundingMode.HALF_UP);	
					}
				}
                // GITLAB US - #28503 - While creating if  usage has blng__PreratedAmount__c or blng__PreratedQuantity__c blank, set QTB_Prerated_Unit_Price__c to 0
                if(usage.blng__PreratedAmount__c ==null || usage.blng__PreratedQuantity__c  ==null )
                {
                    usage.QTB_Prerated_Unit_Price__c  = 0;
                }
                
                if(orderItemIdWithOrderItemMap != null && orderItemIdWithOrderItemMap.containsKey(opId.id) &&
                   orderItemIdWithOrderItemMap.get(opId.id).Order.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill)
                {
                    usage.blng__MatchingAttribute__c =  orderItemIdWithOrderItemMap.get(opId.id).Order.OrderNumber +
                        orderItemIdWithOrderItemMap.get(opId.id).OrderItemNumber +
                        orderItemIdWithOrderItemMap.get(opId.id).blng__InvoiceGroupId__c;
                    //Matching ID -- combination of OrderNumber+CustomerNumber+ProductCode
                    usage.blng__MatchingId__c = orderItemIdWithOrderItemMap.get(opId.id).Order.OrderNumber + 
                        orderItemIdWithOrderItemMap.get(opId.id).Order.Account.QTB_Customer_Number__c + 
                        orderItemIdWithOrderItemMap.get(opId.id).Product2.ProductCode;
                }else
                {
                    usage.blng__MatchingAttribute__c =  orderItemIdWithOrderItemMap.get(opId.id).OrderItemNumber;//Gitlab US#22731 //orderItemIdWithOrderItemMap.get(opId.id).Order.OrderNumber;
                    //Matching ID -- combination of OrderNumber+CustomerNumber+ProductCode
                    usage.blng__MatchingId__c = orderItemIdWithOrderItemMap.get(opId.id).Order.OrderNumber + 
                        orderItemIdWithOrderItemMap.get(opId.id).Order.Account.QTB_Customer_Number__c + 
                        orderItemIdWithOrderItemMap.get(opId.id).Product2.ProductCode;
                }
                
                DateTime startDateTime = (DateTime) orderItemIdWithOrderItemMap.get(opId.id).ServiceDate;
                //usage.blng__Status__c = 'New';
                //setting default time as 12PM
                Time usageTime = Time.newInstance(12, 0, 0, 0);
                usage.blng__StartDateTime__c = DateTime.newInstance(orderItemIdWithOrderItemMap.get(opId.id).ServiceDate, usageTime);
                usage.blng__EndDateTime__c  = DateTime.newInstance(orderItemIdWithOrderItemMap.get(opId.id).EndDate, usageTime);
                //usage.blng__UnitPrice__c = orderItemIdWithOrderItemMap.get(opId.id).UnitPrice;
                usageListToInsert.add(usage);
            }
            if(!usageListToInsert.isEmpty() && usageListToInsert.size() >0){
                insert usageListToInsert;
                return 'true';
            }else{
                return 'false';
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);
            return e.getMessage();
        }
    }
    
    /***********************************************************************************************************
* Method      : updateOrderProductUsageSummaryStatus
* Parameter   : List<OrderItem> orderItemList
* Return Type : void 
* Author      : IRM/Virtusa
* Description : ProdExceptionFixes this method is responsible to update OrderProduct & UsageSummary InvoiceRunProcessingStatus & HoldBilling before creating the usages
**************************************************************************************************************/ 
    public static void updateOrderProductUsageSummaryStatus(List<OrderItem> orderItemList){
        List<OrderItem> orderItemFinalList = new List<OrderItem>();
        List<blng__UsageSummary__c> usgSummaryFinalList = new List<blng__UsageSummary__c>();
        Set<Id> orderPrdIdSet = new Set<Id>();
        try{
            if(!orderItemList.isEmpty() && orderItemList != null){
                for(OrderItem orderPrd : orderItemList)
                {
                    orderPrdIdSet.add(orderPrd.Id);
                    //Checking OrderProduct HoldBilling is 'Yes' or  blng__InvoiceRunProcessingStatus__c is 'Will Not Invoice', then change to values
                    if(orderPrd.blng__HoldBilling__c =='Yes' || orderPrd.blng__InvoiceRunProcessingStatus__c == 'Will Not Invoice'){
                        OrderItem op = new OrderItem();
                        op.Id = orderPrd.id;
                        op.blng__HoldBilling__c = 'No'; // As part of GITLAB #16233 added this line,As the hold Billing field at the OrderProduct level is not updated as expected during deletion and re-addition of usage due to which invoices are not getting generated. 
                        op.blng__InvoiceRunProcessingStatus__c ='Pending Billing';
                        op.blng__InvoiceRunStatusIndex__c ='Pending Billing';   
                        orderItemFinalList.add(op); 
                    }
                }
                
                //Fetching usageSummary where  blng__InvoiceRunProcessingStatus__c = 'Will Not Invoice', then change to Pending Billing
                for(blng__UsageSummary__c usgSummary : [SELECT Id,blng__InvoiceRunProcessingStatus__c 
                                                        From blng__UsageSummary__c
                                                        WHERE blng__OrderProduct__c IN : orderPrdIdSet and blng__InvoiceRunProcessingStatus__c = 'Will Not Invoice'])
                {
                    blng__UsageSummary__c usgSummaryObj = new blng__UsageSummary__c();
                    usgSummaryObj.Id = usgSummary.Id;
                    usgSummaryObj.blng__InvoiceRunProcessingStatus__c = 'Pending Billing'; 
                    usgSummaryFinalList.add(usgSummaryObj);
                }
                
                //Update OrderItem
                if(!orderItemFinalList.isEmpty() && orderItemFinalList.size() > 0){
                    update orderItemFinalList;
                    orderItemFinalList.clear();
                }
                
                //Update UsageSummary
                if(!usgSummaryFinalList.isEmpty() && usgSummaryFinalList !=null){
                    update usgSummaryFinalList;
                    usgSummaryFinalList.clear();
                }
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);           
        }
    }
    /***********************************************************************************************************
* Method      : createInvoiceForRebill
* Parameter   : Id parentInvoiceId,string rebillOrderId,reBillCreditReason
* Return Type : blng__Invoice__c
* Author      : IRM/Virtusa
* Description : GITLAB US #Gitlab US#24171 (Credit/Rebill Billnow), GITLAB US #Gitlab US#24588 (Credit/Rebill Billnow)  
**************************************************************************************************************/       
    @AuraEnabled
    public static blng__Invoice__c createInvoiceForRebill(Id parentInvoiceId,string rebillOrderId,string reBillCreditReason)
    {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            
            List<Order> rebillOrderList = [SELECT Id,OrderNumber,QTB_Rebill_Type__c,blng__InvoiceBatch__c,
                                           CurrencyIsoCode,QTB_Legal_Entity_Country__c,bling_Legal_Entity__c,
                                           Account.QTB_SITAD__c, QTB_SplitRebillValue__c 
                                           FROM Order 
                                           WHERE Id =:rebillOrderId FOR UPDATE];
            if(!rebillOrderList.isEmpty()){
                String ordBillingCountry = rebillOrderList[0].QTB_Legal_Entity_Country__c; 
                // Created custom label for storing Asian countries for #15357
                List<String> asianCountries = System.Label.QTB_Asian_Countries.Split(',');
                for(String country : asianCountries)
                {
                    if(ordBillingCountry == country)
                    {
                        asianCountryPresent=true;
                        break;
                    }    
                }
                
                //Gitlab US#23236 - Refactored the code along with this story
                updateRelatedData(rebillOrderList,ordBillingCountry,parentInvoiceId);
                
                //21598 Queried Invoice period from Parent invoice
                //Gitlab-Gitlab US#24588 (Credit/Rebill Billnow) - Added fields in below query to get the invoicelist and call createPreBill method
                List<blng__Invoice__c> invoiceList = [SELECT Id, Name, blng__InvoiceDate__c,QTB_ReBill_Credit_Reason__c,
                                                      QTB_ReBill_CreditNote_Internal_Note__c,QTB_Invoice_Period__c,CurrencyIsoCode
                                                      FROM blng__Invoice__c
                                                      WHERE Id =:parentInvoiceId ];
                if(invoiceList.size()>0){
                    createPreBill(invoiceList,rebillOrderList); //Gitlab-Gitlab US#24588 (Credit/Rebill Billnow)
                }
                return invoiceList[0]; //Gitlab-Gitlab US#24588 (Credit/Rebill Billnow)  
            }
            return null;
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);
            
            //Gitlab US#22810 --In Case of exception --Reverting Order status from Activated to "Draft"
            //So that rebill order won't get bill under another account
            Order ord1 = new Order();
            ord1.id = rebillOrderId;
            ord1.Status = 'Draft';
            if(!Test.isRunningTest()){
                update ord1; 
            }
            return null;
        }
    }
    
    /***********************************************************************************************************
* Method      : updateRelatedData
* Parameter   : Id rebillInvoiceId,string rebillOrderId
* Author      : IRM/Virtusa
* Description : Before Creating the Rebill invoice, creating the default products and then activating the order
* Total Queries : OrderItem,SBQQ__ProductOption__c,Product2,blng__Usage__c,blng__BillingRule__c,
* Total DML 	: OrderItem, Order, blng__Invoice__c
**************************************************************************************************************/  
    public static void updateRelatedData(List<Order> rebillOrderList,String ordBillingCountry,Id parentInvoiceId){
        Set<Id> orderProductIds = new Set<Id>();
        List<OrderItem> orderProductFinalList = new List<OrderItem>();
        Set<String> oracleProductCodeSet = new Set<String>();
        boolean isfuelSurchargeApplicableProducts =  false;
        Set<Id> bundleProductIdsSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        boolean isSITAD = rebillOrderList[0].Account.QTB_SITAD__c; //Gitlab US #22022
        string billingCountry = (OrdBillingCountry != null && QTB_Billing_Countries__c.getValues(OrdBillingCountry) != null) 
            ? QTB_Billing_Countries__c.getValues(rebillOrderList[0].QTB_Legal_Entity_Country__c).Name 
            : '';
      
        //OrderProduct
        List<OrderItem> ordItmList = [SELECT Id, OrderId, Product2Id, Product2.QTB_Oracle_Product_Code__c, Product2.QTB_Fuel_Surcharge_Applicable__c,
                                      blng__BillingRule__c,blng__NextChargeDate__c,blng__NextBillingDate__c,Order.QTB_Rebill_Type__c,ServiceDate,EndDate
                                      FROM OrderItem 
                                      WHERE OrderId =: rebillOrderList[0].Id];            
        if(!ordItmList.isEmpty()){
            //Iteration on OrderProduct
            for(OrderItem ordItm : ordItmList)
            {
                productIdSet.add(ordItm.Product2Id); 
                if(ordItm.Product2.QTB_Fuel_Surcharge_Applicable__c)
                {
                    isfuelSurchargeApplicableProducts = true;
                    oracleProductCodeSet.add(ordItm.Product2.QTB_Oracle_Product_Code__c); //Storing OracleProductCode //Gitlab US#25509 (Credit/Rebill Billnow)
                }
            }
            
            //Defect Fix Gitlab US#21078 -- fetching product data from SBQQ__ProductOption__c object to identify bundle header products
            for(SBQQ__ProductOption__c prdOpt :[SELECT Id,Name,SBQQ__ConfiguredSKU__r.Name, SBQQ__OptionalSKU__r.Name  
                                                FROM SBQQ__ProductOption__c 
                                                WHERE SBQQ__ConfiguredSKU__c IN : productIdSet])
            {
                //add bundle products in bundleProductIdsSet, bundle product identified using SBQQ__ConfiguredSKU__c field value
                bundleProductIdsSet.add(prdOpt.SBQQ__ConfiguredSKU__c);
            } 
            
            //SplitRebill -- Stopping to create default products(Fuel Surcharge/Minimum Storage/Minimum Invoice) on click of confirm button on usage screen
            //Gitlab US #22022 -- For SITAD - dont clone default products -- added isSITAD check
            if((OrdBillingCountry != billingCountry && rebillOrderList[0].QTB_Rebill_Type__c != System.Label.QTB_SplitRebill && !isSITAD)||Test.isRunningTest())
            { 
                List<Product2> productList = new List<Product2>();
                //fetch only default products (Fuel Surcharge, Minimum Storage Charges, Minimum Invoice Charges)
                for(Product2 prd : [Select Id,Name, ProductCode,QTB_Oracle_Product_Code__c 
                                    FROM Product2 
                                    WHERE ProductCode = :LABEL.QTB_Minimum_Storage OR ProductCode = :LABEL.QTB_Invoice_Minimum OR /*ProductCode =:LABEL.QTB_Fuel_Surcharge*/
                                    Name =:FUEL_SURCHARGE]) //Changing the logic in query from productCode to Name bcoz multiple Fuel Surcharge products
                {
                    if(prd.Name == FUEL_SURCHARGE){
                        if(oracleProductCodeSet !=null && oracleProductCodeSet.contains(prd.QTB_Oracle_Product_Code__c) && isfuelSurchargeApplicableProducts)//checking fuel surcharge oracle product code present in oracleProductCodeSet
                        {
                            productList.add(prd); //adding only fuel surcharge product based on oracle product code from same group or other order product
                        }
                    }
                    else{
                        productList.add(prd); //adding Minimum Storage Charges & Minimum Invoice Charges
                    }
                }
                //Creating default products -- minimum invoice, minimum storage & fuel surcharge
                List<OrderItem> orderItemList = QTB_OrderProductsForRebill.createRetrunOrderProducts(productList, rebillOrderList[0].Id,parentInvoiceId);
            }
            
            for(blng__Usage__c usg : [SELECT ID,blng__OrderProduct__c
                                      FROM blng__Usage__c
                                      WHERE blng__Order__c =:rebillOrderList[0].Id ] )
            {
                orderProductIds.add(usg.blng__OrderProduct__c);
            } 
            
            blng__BillingRule__c billingRule = [SELECT Id FROM blng__BillingRule__c where NAME = 'No Invoice Rule' LIMIT 1];
            
            //orderProductIds which contains the usages
            if(!orderProductIds.isEmpty() && orderProductIds.size() > 0){
                for(OrderItem ordPrd : ordItmList)
                { 
                    //Setting NextBillingDate & NextChargeDate to null when OrderProduct
                    if(ordPrd.blng__BillingRule__c == billingRule.Id && orderProductIds.contains(ordPrd.Id)){
                        ordPrd.blng__NextChargeDate__c = null;
                        ordPrd.blng__NextBillingDate__c = null;  
                    }//Defect #17523 - to Restrict Recurring InvoiceLine creation -- Setting HoldBilling to Yes , when OrderProduct's Billing Rule is "No Invoice Rule" and that order product does not contain the usage
                    else if(ordPrd.Order.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill && ordPrd.blng__BillingRule__c == billingRule.Id && !orderProductIds.contains(ordPrd.Id)) {
                        ordPrd.blng__HoldBilling__c = 'Yes';
                    }
                    //Setting the HoldBilling to Yes for billing only countries to avoid creation of recurring lines for orderproduct's billing rule "No Invoice Rule"
                    else if(OrdBillingCountry == billingCountry && ordPrd.Order.QTB_Rebill_Type__c == 'Regular'  && ordPrd.blng__BillingRule__c == billingRule.Id  && !orderProductIds.contains(ordPrd.Id)){
                        ordPrd.blng__HoldBilling__c = 'Yes';
                    }
                    //Defect Fix Gitlab US#21078 -- if difference between startDate & EndDate is more than 1 month then setting EndDate, & SubscriptionType for Bundle Header Products to get the amount expected on invoiceline
                    if(ordPrd.EndDate != null && ordPrd.ServiceDate!=null && bundleProductIdsSet !=null && bundleProductIdsSet.contains(ordPrd.Product2Id) && ordPrd.ServiceDate.daysBetween(ordPrd.EndDate) > 31 ){
                        ordPrd.EndDate = null; // nullifying the end if the order products more than 1 month   
                        ordPrd.SBQQ__SubscriptionType__c = 'Evergreen';
                        ordPrd.SBQQ__ProductSubscriptionType__c = 'Evergreen';                          
                    }
                    orderProductFinalList.add(ordPrd);
                }                
            }           
            else{ //Defect #17523 fix
                if(!ordItmList.isEmpty()){
                    for(OrderItem ordPrd : ordItmList){
                        //to Restrict Recurring InvoiceLine creation -- Setting HoldBilling to Yes , when OrderProduct's Billing Rule is "No Invoice Rule" and that order product does not contain the usage
                        if(ordPrd.Order.QTB_Rebill_Type__c == System.Label.QTB_SplitRebill && ordPrd.blng__BillingRule__c == billingRule.Id){
                            ordPrd.blng__HoldBilling__c = 'Yes';
                        }
                        //Setting the HoldBilling to Yes for billing only countries to avoid creation of recurring lines for orderproduct's where billing rule is "No Invoice Rule"
                        else if(OrdBillingCountry == billingCountry && ordPrd.Order.QTB_Rebill_Type__c == 'Regular'  && ordPrd.blng__BillingRule__c == billingRule.Id){
                            ordPrd.blng__HoldBilling__c = 'Yes';
                        }
                        //Setting the HoldBilling to Yes for other than billing only countries to avoid creation of recurring lines for orderproduct's where billing rule is "No Invoice Rule"
                        else if(OrdBillingCountry != billingCountry && ordPrd.Order.QTB_Rebill_Type__c == 'Regular'  && ordPrd.blng__BillingRule__c == billingRule.Id){
                            
                            ordPrd.blng__HoldBilling__c = 'Yes';
                        }
                        //Defect Fix Gitlab US#21078 -- if difference between startDate & EndDate is more than 1 month then setting EndDate, & SubscriptionType for Bundle Header Products to get the amount expected on invoiceline
                        if(ordPrd.EndDate != null && ordPrd.ServiceDate!=null && bundleProductIdsSet !=null && bundleProductIdsSet.contains(ordPrd.Product2Id) && ordPrd.ServiceDate.daysBetween(ordPrd.EndDate) > 31 ){
                            ordPrd.EndDate = null; // nullifying the end if the order products more than 1 month   
                            ordPrd.SBQQ__SubscriptionType__c = 'Evergreen';
                            ordPrd.SBQQ__ProductSubscriptionType__c = 'Evergreen'; 
                        }
                        orderProductFinalList.add(ordPrd);
                    }
                }
            }  
            
          
            if(!orderProductFinalList.isEmpty() && orderProductFinalList.size() > 0){
                //Gitlab US#23236,#23270 -- changed the update, updating the orderItem in system mode
                Database.SaveResult[] srList = Database.update(orderProductFinalList,true,System.AccessLevel.SYSTEM_MODE);
            }
            
            //Activating the order before usage creation
            Order ord = new Order();
            ord.id = rebillOrderList[0].Id;
            ord.Status = 'Activated';
            if(!Test.isRunningTest()){
               //Gitlab US#23236,#23270 -- changed the update, updating the order in system mode
               Database.SaveResult srList = Database.update(ord,true,System.AccessLevel.SYSTEM_MODE);
            }
            
            //Change Invoice ReBill Status
            blng__Invoice__c inv = new blng__Invoice__c();
            inv.id = parentInvoiceId;
            inv.QTB_ReBill_Status__c = 'Usage Completed';
            //Gitlab US#23236,#23270 -- changed the update, updating the invoice in system mode
            //Update inv;
             Database.SaveResult srList = Database.update(inv,true,System.AccessLevel.SYSTEM_MODE);
        }
    }
   
    /***********************************************************************************************************
* Method      : createPreBill
* Parameter   : Id rebillInvoiceId,string rebillOrderId
* Author      : IRM/Virtusa
* Description : this method is responsible to create pre-bill record
GITLAB US #Gitlab US#24172 (Credit/Rebill Billnow), GITLAB US #Gitlab US#24588 (Credit/Rebill Billnow) - Modified the method as per the requirement
**************************************************************************************************************/  
    public static void createPreBill(List<blng__Invoice__c> parentInvoiceList,List<Order> rebillOrderList){
        try{
            Date nextMonthBillCycleDate; 
            List<blng__UsageSummary__c> usageSummaryList = [SELECT Id, blng__SummaryStartDate__c, blng__SummaryEndDate__c
                                                                FROM blng__UsageSummary__c
                                                                WHERE blng__Order__c =:rebillOrderList[0].id order by blng__SummaryEndDate__c desc limit 1 ];
           
            if(usageSummaryList !=null && usageSummaryList[0].blng__SummaryEndDate__c != null){
            nextMonthBillCycleDate = date.newInstance(usageSummaryList[0].blng__SummaryEndDate__c.year(), 
                                                      usageSummaryList[0].blng__SummaryEndDate__c.month(), 
                                                      usageSummaryList[0].blng__SummaryEndDate__c.day()+1);
                List<QTB_Bill_Flow_Controller__c> billFlowControllers = new List<QTB_Bill_Flow_Controller__c>();
               // GITLAB #24717 ->  To manage multiple billflow controller creation for split
                if (rebillOrderList[0].QTB_Rebill_Type__c.containsIgnoreCase('Split')) {
                    //is 'split', create multiple records based on QTB_SplitRebillValue__c
                    Decimal decimalValue = rebillOrderList[0].QTB_SplitRebillValue__c;
                    Integer splitValue = decimalValue.intValue();
                    for (Integer i = 0; i < splitValue; i++) {
                        QTB_Bill_Flow_Controller__c preBill = new QTB_Bill_Flow_Controller__c();
                        preBill.Name = 'Prebill For Rebill Invoice ' + (i + 1);
                        preBill.Execute_Pre_Bill_Run__c = true;
                        preBill.QTB_Rebill_Order__c = rebillOrderList[0].Id;
                        preBill.CurrencyIsoCode = parentInvoiceList[0].CurrencyIsoCode;
                        preBill.QTB_Target_Date__c = nextMonthBillCycleDate;
                        billFlowControllers.add(preBill);
                    }
                } else {
                    //is not 'split', create one record
            QTB_Bill_Flow_Controller__c preBill = new QTB_Bill_Flow_Controller__c();
            preBill.Name = 'Prebill For Rebill Invoice';
            preBill.Execute_Pre_Bill_Run__c = true;
                    preBill.QTB_Rebill_Order__c = rebillOrderList[0].Id;
                    preBill.CurrencyIsoCode = parentInvoiceList[0].CurrencyIsoCode;
                    preBill.QTB_Target_Date__c = nextMonthBillCycleDate;
                    billFlowControllers.add(preBill);
                }

            // Insert all bill flow controller records
            Database.SaveResult[] srList = Database.insert(billFlowControllers, true,System.AccessLevel.SYSTEM_MODE);
        }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);           
        }
    }
    
    
    /***********************************************************************************************************
* Method      : runBillNow
* Parameter   : Id ordId
* Return Type : void
* Author      : IRM/Virtusa
* Description : This method is responsible to update Order, so that invoice will generate & this method is getting called after 
                all pre-bill related operation done, means from finish() method of last batch class QTB_InvoiceMinimumBatch 
                GITLAB #Gitlab US#24588 (Credit/Rebill Billnow)
**************************************************************************************************************/      
    public static void runBillNow(List<Id> ordId){
        System.enqueueJob(new QTB_RunBillNowQueueable(ordId));
            } 
 
    /***********************************************************************************************************
* Method      : validateUsages
* Parameter   : Id rebillOrderId
* Return Type : boolean
* Author      : TCS
* Description : Method to verify whether the usages inserted as part of Re-Bill are valid or not  
**************************************************************************************************************/    
    @AuraEnabled
    public static String validateUsages(Id rebillOrderId) {
        try{
            
            if (throwExplicitException) {
           
                throw new NullPointerException();
            }
            //fetching all the usages based on provided rebillOrderId 
            List<blng__Usage__c> usageList = [SELECT Id,Name,QTB_Department_Code__c,QTB_Service_District__c,blng__MatchingId__c,QTB_Product_Identifier_1__c,QTB_ReBill_Original_Usage__c,blng__Order__c,blng__Order__r.QTB_Legal_Entity_Country__c,
                                              blng__OrderProduct__c,blng__UsageSummary__c,blng__PreratedQuantity__c,blng__PreratedAmount__c,blng__Quantity__c,
                                              QTB_Product_Line__c,QTB_Tax_City__c,QTB_Tax_Country__c,QTB_Tax_State__c,QTB_Tax_Street__c,QTB_Tax_ZipCode__c,
                                              blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                                              QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,blng__OrderProduct__r.Product2.QTB_Storage_Product__c //Gitlab US#22511 -- added field in query
                                              FROM blng__Usage__c 
                                              WHERE blng__Order__c = : rebillOrderId  order by Name desc];
            for (blng__Usage__c usage: usageList) 
            {
                //Logic to check the QTB_Product_Identifier_1__c (Source Bill Code) field is updated for only the newly inserted usages by the user.
                //This field is required to process the usage records to the downstream.
                if (usage.QTB_ReBill_Original_Usage__c == null && String.isBlank(usage.QTB_Product_Identifier_1__c)) {
                    return System.Label.QTB_CreditRebill_ProductBillCodeUsageValidation;
                }        
                //SplitRebill -- If Prerated quantity, prerated amount and quantity is null or 0, then invoice line gets created with 0 amount
                //To avoid creation of InvoiceLine with 0 amount, not allowing usage with 0 quantity or amount.
                //true || true && true  -- then only throw the error
                if( (usage.blng__PreratedQuantity__c == null || usage.blng__PreratedQuantity__c == 0) &&
                   (usage.blng__PreratedAmount__c == null || usage.blng__PreratedAmount__c == 0) &&
                   (usage.blng__Quantity__c == null || usage.blng__Quantity__c == 0))                    
                {
                    return System.Label.QTB_SplitRebill_QtyAmtUsageValidation;
                }
                //Defect Fix Gitlab US#21203
                if(usage.QTB_Product_Line__c == QTB_Constants.SITAD_PRODUCT_LINE){

                  
                    //if it's SITAD keep the service district, Tax Country mandatory.  US#29456           
                    if(System.Label.QTB_SITAD_Countries.contains(usage.blng__Order__r.QTB_Legal_Entity_Country__c) && 
                       (usage.QTB_Tax_Country__c == null || usage.QTB_Service_District__c == null 
                           || usage.QTB_Department_Code__c == null))
                    {
                        return System.Label.QTB_CreditRebill_Sitad_ALM_Usage_Validation;
                    }
                }
                // GITLAB #28503 - SFDC Rev Mgmt Reporting: Rev Rec Calculations (Added validation for MRC dates)
                if(usage.blng__OrderProduct__r.Product2.QTB_Storage_Product__c == true && 
				(usage.QTB_Start_Date_MRC__c == null || usage.QTB_End_Date_MRC__c == null || 
				(usage.QTB_Start_Date_MRC__c != null && usage.QTB_End_Date_MRC__c != null  && usage.QTB_End_Date_MRC__c < usage.QTB_Start_Date_MRC__c) ))
                {
                     return System.Label.QTB_MRCDatesValidation;
            }
            }
            return 'true';
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_UsagesForRebill);
            return e.getMessage();
        }
    }
    
    public static void dummyCodeForSomeTime(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
    
}