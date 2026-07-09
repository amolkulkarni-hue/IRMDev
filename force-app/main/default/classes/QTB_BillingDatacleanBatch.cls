/*****************************************************************************************************
* Class: QTB_BillingDatacleanBatch
* Author: Virtusa
* Purpose: This is a Batch class to clean non used Usage Summary 
* Requirement: GIT# 8145
* Change History: NA
* Developer         Date           Description
* -------------------------------------------------------------------------------------------
* Yogesh Narad     06/08/2022     This is a Batch class to clean non used Usage Summary 
*******************************************************************************************************/
Public class QTB_BillingDatacleanBatch implements Database.Batchable<SObject>,Database.Stateful
{
    Public static final string className = QTB_BillingDatacleanBatch.class.getName();
    Public static boolean throwExplicitException = false;
    private final string BLANK = 'BLANK';
    Public String query; 
    private Id orderproductId;
    Public QTB_BillingDatacleanBatch() {    
        this.orderproductId = null;        
    } 
    
    Public QTB_BillingDatacleanBatch(Id orderproductId) {
        this.orderproductId = orderproductId ?? '';
    } 
    
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Description: Fetch required records
**********************************************************************************************************/
    Public Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('this.orderproductId'+this.orderproductId);
        query = 'select id,blng__OrderProduct__c,blng__UnitOfMeasure__c from blng__UsageSummary__c where ' +
            'blng__Status__c = \'' + QTB_Constants.STATUS_NEW + '\' AND ' +
            'blng__SummaryEndDate__c < LAST_N_DAYS:90 AND ' +
            'blng__TotalQuantity__c = NULL ';  
        query += (String.isNotBlank(this.orderproductId) ? 'AND blng__OrderProduct__c = \'' + this.orderproductId + '\' ' : 'AND blng__OrderProduct__c != null ');
        query += 'LIMIT ' + System.Label.QTB_UsageSummaryDeletionLimit;
        system.debug('query'+query);        
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__UsageSummary__c>
Return Type: void
Requirement: 
Description: To delete US.
**********************************************************************************************************/
    Public void execute(Database.BatchableContext BC, List<blng__UsageSummary__c> scope) {
        String errorIds = '';        
        try {
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            }
            // Define a map to hold product IDs with their respective UOM sets related to usagesummary
            Map<Id, Set<String>> ProductWithUOM = new Map<Id, Set<String>>();  
            // Initialize a list to hold Usage Summary records to be deleted
            List<blng__UsageSummary__c> usageSummaryTobeDeleted = new List<blng__UsageSummary__c>();
            //running loop on usageSummary Records
            for(blng__UsageSummary__c usageSummary : scope)
            {   
                // If the map does not already contain the Order Product ID as a key
                if( !ProductWithUOM.containsKey(usageSummary.blng__OrderProduct__c) ){
                    ProductWithUOM.put(usageSummary.blng__OrderProduct__c, new Set<String>{String.isNotBlank(usageSummary.blng__UnitOfMeasure__c) ? usageSummary.blng__UnitOfMeasure__c: this.BLANK});
                    system.debug('usageSummary Id '+usageSummary.Id);
                    
                }
                // If the set for the Order Product ID already contains the Unit of Measure then add to delete that usage summary
                else{
                    if (ProductWithUOM.get(usageSummary.blng__OrderProduct__c).contains(String.isNotBlank(usageSummary.blng__UnitOfMeasure__c) ? usageSummary.blng__UnitOfMeasure__c : this.BLANK)) 
                    {
                        usageSummaryTobeDeleted.add(usageSummary);  
                        system.debug('usageSummaryTobeDeleted'+usageSummaryTobeDeleted);
                        
                    }else{
                        ProductWithUOM.get(usageSummary.blng__OrderProduct__c).add(String.isNotBlank(usageSummary.blng__UnitOfMeasure__c) ? usageSummary.blng__UnitOfMeasure__c: this.BLANK);   
                        system.debug('usageSummary Id '+usageSummary.Id);
                        
                    }
                }
            }
            system.debug('ProductWithUOM'+ProductWithUOM);
            //Deleting the usagesummaries           
            if (!usageSummaryTobeDeleted.isEmpty())
            {
                system.debug('usageSummaryTobeDeleted'+usageSummaryTobeDeleted);
                Delete usageSummaryTobeDeleted;
            }
        } catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch 66>>>>>>>>>>');
            system.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className
            );
        }
    }
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Requirement: 
Description: No action to be taken
**********************************************************************************************************/
    Public void finish(Database.BatchableContext BC) {
        //system.debug('Usage Summary Deleted total:' + usIdSet.size());
        
    }
}