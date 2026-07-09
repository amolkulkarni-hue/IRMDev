/*****************************************************************************************************
* Class: QTB_orderUpdateForUSDelete
* Author: Virtusa
* Purpose: This is a Batch class to Update Order checbox Usagesummary_deletion_batchRun__c for delete unused usageSummary 
* Requirement: GIT# epics/2866
* Change History: NA
*******************************************************************************************************/
Public class QTB_orderUpdateForUSDelete implements Database.Batchable<SObject>,Database.Stateful
{
    Public static final string className = QTB_orderUpdateForUSDelete.class.getName();
    public boolean throwExplicitException = false;
    private final string BLANK = 'BLANK';
    private String errorIds = '';   
    private Id orderId;
    private string query;
    private Integer OrderUpdateCount=0;
    private Integer  usageSummaryEndDate;
    private  List<String> userEmail =New List<String>();
    private List<String> legalEntityCountry =New List<String>();
    private List<String> legalEntityId =New List<String>();
    private String orderLimit;
    private Date   orderStartDate;
    private Date   orderEndDate;
    private Integer batchChunkSize;
    Public QTB_orderUpdateForUSDelete() {    
        this.orderId = null; 
    } 
    
    Public QTB_orderUpdateForUSDelete(Id orderId) {
        this.orderId = orderId ?? '';
    } 
    
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Description: Fetch required records
**********************************************************************************************************/
    Public Database.QueryLocator start(Database.BatchableContext BC) {
        this.customLabelJSONToVariableAssignment();
        this.query = 'SELECT Id FROM Order ';
        this.query += 'Where  Usagesummary_deletion_batchRun__c = true And AccountId != Null ';
        this.query += ((orderStartDate != null) ? 'And EffectiveDate >= :orderStartDate ' : '');
        this.query += (orderEndDate != null) ? 'AND EndDate <= :orderEndDate ' : '';
        this.query += ((!legalEntityId.isEmpty()) ? 'AND Account.QTB_Contract_Entity__c In :legalEntityId ' : '');
        this.query += ((!legalEntityCountry.isEmpty()) ? 'AND Account.QTB_Contract_Entity__r.blng__Country__c In :legalEntityCountry ' : '');
        this.query += (String.isNotBlank(orderId) ? 'AND Id = \'' + orderId + '\' ' : '');
        this.query += ' order by LastModifiedDate LIMIT ' + ((orderLimit != null) ? orderLimit : '1');
        return Database.getQueryLocator(this.query);
        
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__UsageSummary__c>
Return Type: void
Requirement: 
Description: To delete US.
**********************************************************************************************************/
    Public void execute(Database.BatchableContext BC, List<Order> scope) {
        // Initialize a holder for any error IDs 
        String errorIds = '';
        
        try {
            // Test hook: force a NullPointerException when flag is true 
            if (this.throwExplicitException) {
                throw new NullPointerException();
            }
            
            // Calculate the date cutoff for UsageSummary records:
            //  – If usageSummaryEndDate is provided, subtract that many days
            //  – Otherwise default to 90 days ago
            Date endDateOffset = (this.usageSummaryEndDate != null)
                ? System.today().addDays(-this.usageSummaryEndDate)
                : System.today().addDays(-90);
            
            // Map to collect Orders that need their deletion‐batch flag reset
            Map<Id, Order> ordersToUpdateMap = new Map<Id, Order>();
            
            // Retrieve up to 50,000  UsageSummary__c records in one chunk
            // Filtering by summary end date and Orders in this batch's scope
            for (blng__UsageSummary__c usageSummary : [
                SELECT Id,
                blng__OrderProduct__r.OrderId
                FROM blng__UsageSummary__c
                WHERE ((blng__SummaryEndDate__c < :endDateOffset and  blng__Status__c ='New' ) OR blng__Status__c ='Cancelled')
                AND blng__OrderProduct__r.OrderId IN :scope
                LIMIT 50000
            ]) {
                // Queue each Order once for update
                if (!ordersToUpdateMap.containsKey(usageSummary.blng__OrderProduct__r.OrderId)) {
                    ordersToUpdateMap.put(
                        usageSummary.blng__OrderProduct__r.OrderId,
                        new Order(
                            Id = usageSummary.blng__OrderProduct__r.OrderId,
                            Usagesummary_deletion_batchRun__c = false
                        )
                    );
                }
            }
        
            //To update remaining Records
            for (Order orderRec : scope) {
                if (!ordersToUpdateMap.containsKey(orderRec.Id)) {
                    ordersToUpdateMap.put(
                        orderRec.Id,
                        new Order(
                            Id = orderRec.Id,
                            Usagesummary_deletion_batchRun__c = true
                        )
                    );
                }
            }
            // Perform a single DML update if there are Orders to update
            if (!ordersToUpdateMap.isEmpty()) {
                update ordersToUpdateMap.values();
                this.OrderUpdateCount += ordersToUpdateMap.size();
            }        
        } catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
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
Requirement: Sending count of US deleted record
Description: Send US delete count to email address stored in custom label QTB_USDeleteBatch_UserEmail
**********************************************************************************************************/
    Public void finish(Database.BatchableContext BC) {
        String errorIds = '';        
        try {
            if (this.throwExplicitException) {
                throw new NullPointerException();
            }
            String subject = 'Batch Job Completion:  Order update count';
            String body = 'The batch job to Update order record has been completed.\n\n';
            body += 'Total records processed and successfully : ' + this.OrderUpdateCount + '\n\n';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if(!(this.userEmail).isEmpty()){
                mail.setToAddresses(this.userEmail);
            }
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            if (!Test.isRunningTest() && !(this.userEmail).isEmpty()) { // Avoid sending emails during test execution
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
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
Method Name: customLabelJSONToVariableAssignment
Parameters: void
Return Type: void
Description: Convert custom label JSON format to apex variable assignment format
**********************************************************************************************************/
    private void customLabelJSONToVariableAssignment(){
        String errorIds = '';        
        // Retrieve the JSON string from the custom label
        String jsonString = System.Label.QTB_orderUpdateBatchParameters;
        Map<String, Object> dataMap;
        try {
            if (this.throwExplicitException) {
                throw new NullPointerException();
            }
            // Check if the custom label is null or empty
            if (String.isNotBlank(jsonString)) {
                // Deserialize the JSON string into an untyped Map
                dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            }
            
            // Ensure the deserialized map is not null
            if (dataMap == null) {   
                return;
            }
            // Process order start date if the key exists and is not blank
            if (dataMap.containsKey('orderStartDate') && dataMap.get('orderStartDate') != null) {
                String orderStartDateStr = String.valueOf(dataMap.get('orderStartDate'));
                if (!String.isBlank(orderStartDateStr)) {
                    this.orderStartDate = Date.valueOf(orderStartDateStr);
                }
            } 
            // Process order enddate if the key exists and is not blank
            if (dataMap.containsKey('orderEndDate') && dataMap.get('orderEndDate') != null) {
                String orderEndDateStr = String.valueOf(dataMap.get('orderEndDate'));
                if (!String.isBlank(orderEndDateStr)) {
                    this.orderEndDate = Date.valueOf(orderEndDateStr);
                } 
            } 
            
            // Process orderLimit.
            if (dataMap.containsKey('orderLimit') && dataMap.get('orderLimit') != null) {
                String orderLimitStr = String.valueOf(dataMap.get('orderLimit')).trim();
                if (!String.isBlank(orderLimitStr)) {
                    this.orderLimit = orderLimitStr;
                    
                }
            }
            
            // Process UsageSummaryOffSet.
            if (dataMap.containsKey('usageSummaryEndDateOffSet') && dataMap.get('usageSummaryEndDateOffSet') != null) {
                String usageSummaryOffSetStr = String.valueOf(dataMap.get('usageSummaryEndDateOffSet')).trim();
                if (!String.isBlank(usageSummaryOffSetStr)) {
                    this.usageSummaryEndDate = Integer.valueOf(usageSummaryOffSetStr);
                    
                }
            }
            
            // Process legalEntityCountry as a List<String> using direct split.
            if (dataMap.containsKey('legalEntityCountry') && dataMap.get('legalEntityCountry') != null) {
                String legalEntityCountryStr = String.valueOf(dataMap.get('legalEntityCountry')).trim();
                if (!String.isBlank(legalEntityCountryStr)) {
                    this.legalEntityCountry = legalEntityCountryStr.split(';');
                    
                }
            }
            
            // Process legalEntityId as a List<String> using direct split.
            if (dataMap.containsKey('legalEntityId') && dataMap.get('legalEntityId') != null) {
                String legalEntityStr = String.valueOf(dataMap.get('legalEntityId')).trim();
                if (!String.isBlank(legalEntityStr)) {
                    this.legalEntityId = legalEntityStr.split(',');
                    
                }
            }
            
            // Process userEmail as a List<String> using direct split.
            if (dataMap.containsKey('userEmail') && dataMap.get('userEmail') != null) {
                String userEmailStr = String.valueOf(dataMap.get('userEmail')).trim();
                if (!String.isBlank(userEmailStr)) {
                    this.userEmail = userEmailStr.split(',');
                    
                }
            }
            
            
        } catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
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
}