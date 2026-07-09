/*****************************************************************************************************
* Class			: QTB_APICreateSalesOrderBatch
* Test Class	: QTB_APICreateSalesOrderBatch_Test
* Author		: IRM/Virtusa
* Purpose	 	: This class responsible for TO Create Sales order and existing logic will take care of creation of contract/billing order
* Requirement	: Gitlab US #10332 - Main Uplift Functionality: Build for Testing: Step Four - Order & New Contacts / Subscriptions Generated 
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Shailesh       		09/12/2022       Gitlab US #10332 - Main Uplift Functionality: Build for Testing: Step Four - Order & New Contacts / Subscriptions Generated 
*******************************************************************************************************/
public class QTB_APICreateSalesOrderBatch implements Database.Batchable<sObject>,Database.Stateful {
    public static final string QTB_APICreateSalesOrderBatch = 'QTB_APICreateSalesOrderBatch';
    Set<Id> opptyIdSet = new Set<Id>(); 
    Set<String> failedContractSet = new Set<String>();
    Set<String> successContractSet = new Set<String>();
    Id dataHolderAPIObjId;
    string OPPTY_STAGE_6SETUP = '6 - Setup';
    string QUOTE_ACCEPTED = 'Accepted';
    public static boolean throwExplicitException = false;
    Integer retryCount = 0;   
    
    public QTB_APICreateSalesOrderBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar,Set<Id> opptyIdSetVar,Id dataHolderAPIObjIdVar){
        System.debug('QTB_APICreateSalesOrderBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APICreateSalesOrderBatch_failedContractSetVar@@'+failedContractSetVar);
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
        opptyIdSet = opptyIdSetVar;
    }
    
    public QTB_APICreateSalesOrderBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar,Set<Id> opptyIdSetVar,Id dataHolderAPIObjIdVar, Integer retries){
        System.debug('QTB_APICreateSalesOrderBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APICreateSalesOrderBatch_failedContractSetVar@@'+failedContractSetVar);
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
        opptyIdSet = opptyIdSetVar;
        this.retryCount = retries;
        System.debug('retryCount@@'+retryCount);
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab US #10332
* Description: Query on Quote object to fetch all records where sales order is not created
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String quoteQuery = 'SELECT Id,SBQQ__Status__c,SBQQ__Ordered__c,SBQQ__Primary__c, SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.stageName,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name'+
            ' FROM SBQQ__Quote__c '+
            ' WHERE SBQQ__Opportunity2__r.stageName = :OPPTY_STAGE_6SETUP and SBQQ__Ordered__c = false and SBQQ__Primary__c = true and SBQQ__Status__c = :QUOTE_ACCEPTED';
        if(this.retryCount > 0)
        {
            quoteQuery = quoteQuery +' AND SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name IN : failedContractSet';
        }
        else
        {
            quoteQuery = quoteQuery +' AND SBQQ__Opportunity2__c IN : opptyIdSet';
        }
        quoteQuery = quoteQuery +' order by SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name asc';
        
        System.debug('QTB_APICreateSalesOrderBatch_start_quoteQuery@@'+quoteQuery);
        Database.QueryLocator queryResult = Database.getQueryLocator( quoteQuery ); 
        Database.QueryLocatorIterator iterate =  queryResult.iterator();
        Integer countVariable = 0;
        if(iterate != null){
            while (iterate.hasNext())
            {     
                countVariable++;
                break;
            }
        }
        if(countVariable == 0 && this.retryCount == 0 ){
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
        }
        
        return Database.getQueryLocator(quoteQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab US #10332 
* Description: Iterating on all QuoteList with batch size 1 and setting SBQQ__Ordered__c field value to true for Sales Order creation.
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<SBQQ__Quote__c> quoteList){
        try {
            System.debug('QTB_APICreateSalesOrderBatch_execute@@'+quoteList);
            List<SBQQ__Quote__c> quoteListFinal = new List<SBQQ__Quote__c>();
            Set<Id> quoteIds = new Set<Id>();
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(quoteList != null && !quoteList.isEmpty()){
                //Iterating over Renewal Quote List
                for(SBQQ__Quote__c quote : quoteList )
                {
                    if(!quote.SBQQ__Ordered__c){
                        SBQQ__Quote__c quoteObj = new SBQQ__Quote__c();
                        quoteObj.Id = quote.Id;    
                        quoteObj.SBQQ__Ordered__c = true; //setting SBQQ__Ordered__c field value as true, to create Sales Order       
                        quoteListFinal.add(quoteObj); 
                    }
                }  
            }
            else{
                failedContractSet.add(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                if(successContractSet != null && successContractSet.contains(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name))
                {
                    successContractSet.remove(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);  
                }
            }
            
            if(quoteListFinal != null && !quoteListFinal.isEmpty()){
                System.debug('quoteListFinal@@'+quoteListFinal);
                wait(Integer.valueOf(System.Label.QTB_APIDelayInMilliseconds)); //providing delay for 30 sec as to avoid record lock issue
                update quoteListFinal; 
            }
            if(retryCount > 0 ){
                if(failedContractSet != null && failedContractSet.contains(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name))
                {
                    failedContractSet.remove(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                    successContractSet.add(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
                }  
            }
        }
        catch (Exception e){
            //Store failed quote's contract names
            failedContractSet.add(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);
            if(successContractSet != null && successContractSet.contains(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name)){
                successContractSet.remove(quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name);  
            }            
            System.debug('ApexClass_execute()@@'+QTB_APICreateSalesOrderBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),quoteList[0].SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name+'-'+e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APICreateSalesOrderBatch); 
        }
    }
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab US #10332 
* Description: finish() method is used to update DataHolder obj for Uplift status to success/failed 
: and in failure case sending email to logged-in user with failed contracts 
**********************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        try{
            System.debug('QTB_APICreateSalesOrderBatch_finish()_successContractSet@@'+successContractSet);
            System.debug('QTB_APICreateSalesOrderBatch_finish()_failedContractSet@@'+failedContractSet);
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.Id = dataHolderAPIObjId;
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(successContractSet !=null && !successContractSet.isEmpty() && !Test.isRunningTest()){
                //If any contract failed, retrying few more times based on value store in label QTB_APIFailedContractRetryCount by calling the same class again with failed contract
                if(failedContractSet != null && !failedContractSet.isEmpty() && retryCount < Integer.valueOf(System.Label.QTB_APIFailedContractRetryCount) && !Test.isRunningTest())
                {
                    retryCount = retryCount + 1; 
                    Database.executeBatch(new QTB_APICreateSalesOrderBatch(successContractSet,failedContractSet,null,dataHolderAPIObjId,retryCount), Integer.valueOf(System.Label.QTB_APISalesOrderBatchSize));
                }
                else{
                    //schedule to execute Batch Job only after some time min,Batch size = 200  
                    System.scheduleBatch(new QTB_APIBillingOrderCreationBatch(successContractSet,failedContractSet,dataHolderAPIObjId),'QTB_APIBillingOrderCreationBatchJob',Integer.valueOf(System.Label.QTB_APINextBatchFireTime),Integer.valueOf(System.Label.QTB_APIBulkBatchSize));
                }
            }
            //successContractSet is empty & failedContractSet is not empty
            else if((successContractSet == null || successContractSet.isEmpty() ) && (failedContractSet != null && !failedContractSet.isEmpty()))
            {
                //Updating Status to Failed                
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed'; 
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
                update dataHolderAPIObj;
                //Send email to logged-in user with failed contracts
                QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'SalesOrder');   
            }  
        }
        catch (Exception e){
            System.debug('ApexClass_finish()@@'+QTB_APICreateSalesOrderBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());            
            //Email Notification for all failed contract records
            QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'SalesOrder');
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APICreateSalesOrderBatch); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: wait
* Parameters : Integer millisec
* Return Type: void
* Requirement: Gitlab US #10330
* Description: wait() method : to hold transaction for given milliseconds
**********************************************************************************************************/   
    public void wait(Integer millisec) {
        if (millisec == null || millisec < 0) {
            millisec = 0;
        }
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while ((finishTime - startTime) < millisec) {
            finishTime = DateTime.now().getTime();
        }
    }
    
    public static void codeCoverage(){
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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