/*****************************************************************************************************
* Class: QTB_UsageSummary_deletion_OrderSpecific
* Author: Virtusa
* Purpose: This is a Batch class to clean non used Usage Summary 
* Requirement: GIT# epics/2939
* Change History: NA
*******************************************************************************************************/
Public class QTB_UsageSummary_deletion_OrderSpecific implements Database.Batchable<SObject>,Database.Stateful
{
    Public static final string className = QTB_UsageSummary_deletion_OrderSpecific.class.getName();
    public boolean throwExplicitException = false;
    private final string BLANK = 'BLANK';
    private String errorIds = '';   
    private Id orderId;
    private string query;
    private Integer USdeleteCount=0;
    private Integer  usageSummaryEndDate;
    private  List<String> userEmail =New List<String>();
    private List<String> legalEntityCountry =New List<String>();
    private List<String> legalEntityId =New List<String>();
    private String orderLimit;
    private Date   orderStartDate;
    private Date   orderEndDate;
    private Integer batchChunkSize;
    Public QTB_UsageSummary_deletion_OrderSpecific() {    
        this.orderId = null; 
    } 
    
    Public QTB_UsageSummary_deletion_OrderSpecific(Id orderId) {
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
        this.query += 'Where  Usagesummary_deletion_batchRun__c = False And AccountId != Null ';
        this.query += ((orderStartDate != null) ? 'And EffectiveDate >= :orderStartDate ' : '');
        this.query += (orderEndDate != null) ? 'AND EndDate <= :orderEndDate ' : '';
        this.query += ((!legalEntityId.isEmpty()) ? 'AND Account.QTB_Contract_Entity__c In :legalEntityId ' : '');
        this.query += ((!legalEntityCountry.isEmpty()) ? 'AND Account.QTB_Contract_Entity__r.blng__Country__c In :legalEntityCountry ' : '');
        this.query += (String.isNotBlank(orderId) ? 'AND Id = \'' + orderId + '\' ' : '');
        this.query += 'LIMIT ' + ((orderLimit != null) ? orderLimit : '1');
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
        String errorIds = '';        
        try {
            if (this.throwExplicitException) {
                throw new NullPointerException();
            }
            //to store processed US
            Set<String> processedUS =new Set<String>();
            //Order which is needs to update 
            List<Order> orderToBeUpdate = new List<Order>();
            //orderUOMBasedMap  for holding order Id and unique identifier for usage summary related to order product based on UOM    
            Map<Id, Set<String>> orderUOMBasedMap = new Map<Id,Set<String>>();
            //orderAndOPTerminatedRecUS for holding order id and set of order product id so that any
            // Us having processed record with this order product then we can delete rest new us Present there
            Map<Id, Set<Id>> orderAndOPTerminatedRecUS = new Map<Id,Set<Id>>();
            //Creating Map to store usage summary id and record 
            Map<Id,blng__UsageSummary__c> usageSummaryToBeDeletedMap = new Map<Id,blng__UsageSummary__c>();
            Set<String> usageSummaryStatus = new Set<String>{QTB_Constants.STATUS_NEW, QTB_Constants.STATUS_Cancelled,QTB_Constants.STATUS_PROCESSED};
            //UsageSummaryList this.this.query usage summary realted to order coming in execute method
            List<blng__UsageSummary__c> usageSummaryList = [SELECT Id,blng__SummaryEndDate__c, blng__TotalQuantity__c, blng__Status__c, blng__UnitOfMeasure__c, blng__OrderProduct__r.OrderId,  blng__OrderProduct__c,blng__OrderProduct__r.SBQQ__TerminatedDate__c 
                                                            FROM blng__UsageSummary__c 
                                                            WHERE blng__OrderProduct__r.OrderId IN :scope AND blng__Status__c IN :usageSummaryStatus and blng__OrderProduct__c != null Limit 50000 ];

            //Running a loop on usageSummary and checking if any processed record is there then it should be added in orderAndOPTerminatedRecUS map so that 
            //we can delete rest of the usagesummary related to that orderproduct 
            for (blng__UsageSummary__c usageSummary : UsageSummaryList) {
                String uniqueIdentifier;
                uniqueIdentifier=usageSummary.blng__OrderProduct__c + (String.isNotBlank(usageSummary.blng__UnitOfMeasure__c) ? usageSummary.blng__UnitOfMeasure__c: this.BLANK);                      
               //If we get any usage summary with status cancel we have to delete it directly 
                If(usageSummary.blng__Status__c == QTB_Constants.STATUS_Cancelled){
                    usageSummaryToBeDeletedMap.put(usageSummary.Id,usageSummary);
                }
                //If we usage summary orderproduct id + UOM is alrwady present in processedUS set then in that case we have to delete usage summary
                else if(usageSummary.blng__Status__c == QTB_Constants.STATUS_PROCESSED && !processedUS.contains(uniqueIdentifier)){
                         //uniqueIdentifier will be a combination of Orderproduct Id and UOM so that we can find unique usagesummary based on blng__UnitOfMeasure__c
                         processedUS.add(uniqueIdentifier);
                }
                //In case when order product terminated data not null then in that case we have to delete all new and cancel us related to that orderproduct 
                else if(usageSummary.blng__OrderProduct__r.SBQQ__TerminatedDate__c != Null){
                    //Checking if orderAndOPTerminatedRecUS if it contains order id if not then we can add
                    if (!orderAndOPTerminatedRecUS.containsKey(usageSummary.blng__OrderProduct__r.OrderId)) {
                        orderAndOPTerminatedRecUS.put(usageSummary.blng__OrderProduct__r.OrderId, new Set<Id>{usageSummary.blng__OrderProduct__c});
                       
                    }
                    //If if contain order id then in that case we can add ordrproduct id if not already added 
                    else {
                        if(!orderAndOPTerminatedRecUS.get(usageSummary.blng__OrderProduct__r.OrderId).contains(usageSummary.blng__OrderProduct__c)){
                            orderAndOPTerminatedRecUS.get(usageSummary.blng__OrderProduct__r.OrderId).add(usageSummary.blng__OrderProduct__c);
                        } 
                    }           
                }
            }
            //Now we have to run loop again on UsageSummaryList to deal with New and rest Us which has to be deleted        
            for (blng__UsageSummary__c usageSummary : UsageSummaryList) {
                String uniqueIdentifier;
                //uniqueIdentifier will be a combination of Orderproduct Id and UOM so that we can find unique usagesummary based on blng__UnitOfMeasure__c
                uniqueIdentifier=usageSummary.blng__OrderProduct__c + (String.isNotBlank(usageSummary.blng__UnitOfMeasure__c) ? usageSummary.blng__UnitOfMeasure__c: this.BLANK);
                    
                //we are checking if this usagesummary in orderAndOPTerminatedRecUS map then we need to delte this usagesummary
                //With the help of this condition we can delete for order product which having processed  US and orderproduct which got terminated
                if((usageSummary.blng__Status__c == QTB_Constants.STATUS_NEW && orderAndOPTerminatedRecUS.containsKey(usageSummary.blng__OrderProduct__r.OrderId) && orderAndOPTerminatedRecUS.get(usageSummary.blng__OrderProduct__r.OrderId).contains(usageSummary.blng__OrderProduct__c))
                || (usageSummary.blng__Status__c == QTB_Constants.STATUS_NEW && processedUS.contains(uniqueIdentifier)))
                {   
                    usageSummaryToBeDeletedMap.put(usageSummary.Id,usageSummary);

                }
                
                //if orderAndOPTerminatedRecUS not contains this orderproduct id then we have to keep usagesummary which having unique UOM related to orderproduct.
                else if(usageSummary.blng__Status__c == QTB_Constants.STATUS_NEW && usageSummary.blng__TotalQuantity__c == Null  && this.usageSummaryEndDate !=null && usageSummary.blng__SummaryEndDate__c < Date.today().addDays(-this.usageSummaryEndDate))
                {
                    
                    //If orderUOMBasedMap is already having that usage summary with this blng__UnitOfMeasure__c then we can delete this usage summary 
                    if(orderUOMBasedMap.containsKey(usageSummary.blng__OrderProduct__r.OrderId)){
                        if(orderUOMBasedMap.get(usageSummary.blng__OrderProduct__r.OrderId).contains(uniqueIdentifier)){
                            usageSummaryToBeDeletedMap.put(usageSummary.Id,usageSummary);

                            
                        }
                        //if orderUOMBasedMap is not having that usage summary with this blng__UnitOfMeasure__c then we have to add that usage summary in map
                        else{
                            orderUOMBasedMap.get(usageSummary.blng__OrderProduct__r.OrderId).add(uniqueIdentifier);
                        }
                    }
                    // If order id itseld is not present in this map then we need to add orderId with unique identifier value
                    else{                     
                        orderUOMBasedMap.put(usageSummary.blng__OrderProduct__r.OrderId, new set<string>{uniqueIdentifier});                  
                    }
                    
                }   
            }
           //Delete unused usage summary which is having in usageSummaryToBeDeletedMap
           if (!usageSummaryToBeDeletedMap.isEmpty())
            {  
               Delete usageSummaryToBeDeletedMap.Values();
               this.USdeleteCount += usageSummaryToBeDeletedMap.size();
              

            }
         //Running a loop on order and update those order Usagesummary_deletion_batchRun__c to true so that batch should not pickup this again
         For(Order orderRec:scope){
            Order orderRecToUpdate = new Order();
            orderRecToUpdate.Id=orderRec.Id;
            orderRecToUpdate.Usagesummary_deletion_batchRun__c=True;
            orderToBeUpdate.add(orderRecToUpdate);
         }

        //Update orderToBeUpdate if not empty list
    if (!orderToBeUpdate.isEmpty()) {
        update orderToBeUpdate;
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
        String subject = 'Batch Job Completion: Deleted usage summary count';
        String body = 'The batch job to delete usage summary record has been completed.\n\n';
        body += 'Total records processed and successfully deleted: ' + this.USdeleteCount + '\n\n';
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
         String jsonString = System.Label.QTB_usageSummaryDeleteBatchParameters;
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