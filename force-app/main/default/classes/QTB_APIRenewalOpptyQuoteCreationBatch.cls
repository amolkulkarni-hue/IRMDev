/*****************************************************************************************************
* Class			: QTB_APIRenewalOpptyQuoteCreationBatch
* Test Class	: QTB_APISubscriptionUpliftBatch_Test
* Author		: IRM/Virtusa
* Purpose	 	: Regular API Uplift:- This batch class is responsible to create Renewal Opportunity, Renewal Quote by updating renewal Quoted as true on Contract. 
and provided delay to give some time to complete backend process while generation on renewal Oppty/renewal Quote. 
* Requirement	: Gitlab US #10330 - Main Uplift Functionality: Build for Testing: Step Two - Set Contract to Renew / Renewal Opportunity and Quote Created
* Developer                Date            Description
* -----------------------------------------------------------------------------------------------------
* Shailesh       		11/25/2022       Gitlab US #10330 - Set Contract to Renew / Renewal Opportunity and Quote Created
*******************************************************************************************************/
public class QTB_APIRenewalOpptyQuoteCreationBatch implements Database.Batchable<sObject>,Database.Stateful {
    static final string QTB_APIRenewalOpptyQuoteCreationBatch = 'QTB_APISubscriptionUpliftBatch';       
    String dataHolderObjId;
    Set<String> successContractNameSet = new Set<String>();
    Set<String> failedContractNameSet = new Set<String>();
    Id prevAccountId;
    Id prevContractId;
    Set<String> renewalContractSet = new Set<String>();
    Integer retryCount = 0;
    public static boolean throwExplicitException = false;
    Set<Id> productToUpdateSet = new Set<Id>();
    
    
    /*********************************************************************************************************
* Method Name: QTB_APISubscriptionUpliftBatch
* Parameters : List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList,String contentDocumentId
* Requirement: Gitlab US #10330
* Description: This constructor is responsible to store success, failed contracts and dataholderobjectId
**********************************************************************************************************/    
    public QTB_APIRenewalOpptyQuoteCreationBatch(Set<String> successContractVar, Set<String> failedContractVar,Set<Id> productToUpdateSetVar, String dataHolderObjIdVar){
        System.debug('QTB_APIRenewalOpptyQuoteCreationBatch1_successContractVar@@'+successContractVar);
        System.debug('QTB_APIRenewalOpptyQuoteCreationBatch1_failedContractVar@@'+failedContractVar);
        successContractNameSet = successContractVar;
        failedContractNameSet = failedContractVar;
        dataHolderObjId =  dataHolderObjIdVar;
        productToUpdateSet = productToUpdateSetVar;
    }
    /*********************************************************************************************************
* Method Name: QTB_APISubscriptionUpliftBatch
* Parameters : List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList,String contentDocumentId,Integer retries
* Requirement: Gitlab US #10330
* Description: This constructor is responsible to store success & failed contracts,  dataholderobjectId and retryCount
**********************************************************************************************************/     
    public QTB_APIRenewalOpptyQuoteCreationBatch(Set<String> successContractVar, Set<String> failedContractVar, Set<Id> productToUpdateSetVar,String dataHolderObjIdVar, Integer retries) {
        System.debug('QTB_APIRenewalOpptyQuoteCreationBatch2_successContractVar@@'+successContractVar);
        System.debug('QTB_APIRenewalOpptyQuoteCreationBatch2_failedContractVar@@'+failedContractVar);
        successContractNameSet.addAll(successContractVar);
        failedContractNameSet.addAll(failedContractVar);
        dataHolderObjId =  dataHolderObjIdVar;
        this.retryCount = retries;
        productToUpdateSet = productToUpdateSetVar;
        System.debug('retryCount@@'+retryCount);
    }
    
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab US #10330
* Description: start() method is used for to Query on Contract and fetched all the contracts based on provided contractNameSet 
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String contractQuery = 'SELECT Id,Name,AccountId FROM Contract '; 
        if(this.retryCount > 0){
            contractQuery = contractQuery +' WHERE Name IN:failedContractNameSet order by Name asc';
        }else{
            contractQuery = contractQuery +' WHERE Name IN:successContractNameSet order by Name asc';
        }
        
        //If query return no record, then storing not found contracts in this list failedContractNameSet        
        Database.QueryLocator queryResult = Database.getQueryLocator( contractQuery ); 
        Database.QueryLocatorIterator iterate =  queryResult.iterator();
        Integer countVariable = 0;
        if(iterate != null){
            while (iterate.hasNext())
            {     
                countVariable++;
                break;
            }
        }
        if(countVariable == 0 && retryCount == 0 ){
            failedContractNameSet.addAll(successContractNameSet);
            successContractNameSet.clear();
        }
        
        return Database.getQueryLocator(contractQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab US #10330
* Description: execute() method is used to update renewal Quoted checkbox value as true on Contract obj, so renewal Oppty & renewal Quote get generate.
: reference taken from QTB_RenewContractsBatch to provide some delay
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<Contract> scope){
        //Scope size is 1
        try {
            system.debug('QTB_APIRenewalOpptyQuoteCreationBatch_execute@@' + scope);
            String errorMessage = '';
            List<SBQQ__RecordJob__c> recordsList = new List<SBQQ__RecordJob__c>();
            List<Contract> contractList = new List<Contract>();
            
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(scope != null && !scope.isEmpty()){
                for (Contract eachContract : scope) {
                    eachContract.SBQQ__RenewalQuoted__c = true;
                    eachContract.QTB_APIProcess__c = true;
                    contractList.add(eachContract);
                }
                system.debug('Prior Account ID==>' +prevAccountId +';;Current AccountID==>' + scope[0].AccountId +';;Prev Contract Id==>' +prevContractId);
                //handle if current contract's account id is same as previous contract's account id
                if (!Test.isRunningTest() && (prevAccountId == scope[0].AccountId || prevContractId != null))
                {
                    string tempVar = prevContractId + '::RenewContract';
                    //SBQQ__RecordJob__c has stored contract details with success/failed/inprogress.
                    for (SBQQ__RecordJob__c recJob : [SELECT id,SBQQ__RecordId__c, SBQQ__JobStatus__c, Createddate, LastModifiedDate
                                                      FROM SBQQ__RecordJob__c
                                                      WHERE SBQQ__RecordId__c LIKE :tempVar order by LastModifiedDate desc LIMIT 1]) 
                    {
                        System.debug('recJob@@'+recJob);
                        //checking the recordJob created/modified date for the contract, and allowing only today's created/modified contract to process further
                        if ((Date.newInstance(recJob.Createddate.year(),recJob.Createddate.month(),recJob.Createddate.day()) == System.Today()) ||
                            (Date.newInstance(recJob.LastModifiedDate.year(),recJob.LastModifiedDate.month(),recJob.LastModifiedDate.day()) == System.Today()))
                        {
                            System.debug('If1@@');
                            //If previous contract is still processing, wait hold time of 50 sec and then process current record else simply update
                            if (!Test.isRunningTest() && (recJob.SBQQ__JobStatus__c == QTB_Constants.RECORDJOB_INPROGRESS || recJob.SBQQ__JobStatus__c == null))
                            {
                                System.debug('If2@@');
                                wait(Integer.valueOf(System.Label.QTB_APIDelayInMilliseconds)); //providing delay for 30 sec as to avoid record lock issue
                                update contractList;
                            } 
                            else if (recJob.SBQQ__JobStatus__c == QTB_Constants.RECORDJOB_FAILED || recJob.SBQQ__JobStatus__c == QTB_Constants.RECORDJOB_COMPLETED)
                            {
                                System.debug('ElseIf2@@');
                                update contractList;
                            }
                        }
                    }
                } 
                else if (prevAccountId != scope[0].AccountId) 
                {
                    wait(Integer.valueOf(System.Label.QTB_APIDelayInMilliseconds)); //providing delay for 30 sec as to avoid record lock issue
                    update contractList;
                }                
                //save current contract's account id as previous id for next transaction
                prevAccountId = scope[0].AccountId;
                prevContractId = scope[0].id;
                renewalContractSet.add(scope[0].id+'::RenewContract');
                if(this.retryCount > 0){
                    if(failedContractNameSet != null && failedContractNameSet.contains(scope[0].Name)) {
                        failedContractNameSet.remove(scope[0].Name);	
                        successContractNameSet.add(scope[0].Name);
                    }
                }
            }
        }
        catch (Exception e) {
            failedContractNameSet.add(scope[0].Name);
            successContractNameSet.remove(scope[0].Name);
            System.debug('Apex Class@@'+QTB_APIRenewalOpptyQuoteCreationBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage()); 
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),scope[0].Name+'-'+e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIRenewalOpptyQuoteCreationBatch);
        }
    }
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab US #10330
* Description: finish() method : Calling QTB_APIQuoteManipulationBatch after some time to perform Quote related operation.	
: and if any contract failed, then retrying 3 more time by calling same batch with failed contract
: and sending email to logged-in user with failed contract
**********************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        try{
            System.debug('QTB_APIRenewalOpptyQuoteCreationBatch_finish_successContractNameSet@@'+successContractNameSet);
            System.debug('QTB_APIRenewalOpptyQuoteCreationBatch_finish_failedContractNameSet@@'+failedContractNameSet);
            System.debug('QTB_APIRenewalOpptyQuoteCreationBatch_finish_productToUpdateSet@@'+productToUpdateSet);
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            Set<String> contractIdSet = new Set<String>();
            Set<String> allContractNameSet = new Set<String>();
            allContractNameSet.addAll(successContractNameSet);
            allContractNameSet.addAll(failedContractNameSet);
            System.debug('QTB_APIRenewalOpptyQuoteCreationBatch_finish@@');
            List<SBQQ__RecordJob__c> recordJobList =  new List<SBQQ__RecordJob__c>();
            if(renewalContractSet != null){
                recordJobList = [SELECT id,SBQQ__RecordId__c, SBQQ__JobStatus__c, Createddate, LastModifiedDate
                                 FROM SBQQ__RecordJob__c
                                 WHERE SBQQ__RecordId__c IN :renewalContractSet and SBQQ__JobStatus__c = 'Failed' ];
            }
            for(Contract con : [SELECT Id,Name,SBQQ__RenewalOpportunity__c FROM Contract where Name IN :allContractNameSet]){
                if(con.SBQQ__RenewalOpportunity__c == null){
                	contractIdSet.add(con.Id);
            	}
            }
            
            System.debug('QTB_APIRenewalOpptyQuoteCreationBatch_recordJobList@@'+recordJobList);
            System.debug('QTB_APIRenewalOpptyQuoteCreationBatch_retryCount@@'+retryCount);
            
            //If any contract failed, retrying 3 time by calling the same class again with failed contract
            if((contractIdSet !=null || (recordJobList != null && !recordJobList.isEmpty())) && retryCount < Integer.valueOf(System.Label.QTB_APIFailedContractRetryCount) && !Test.isRunningTest()){
                retryCount = retryCount + 1;
                
                for(SBQQ__RecordJob__c failedContract : recordJobList){
                    string contractId = (failedContract.SBQQ__RecordId__c).substringBefore('::RenewContract');
                    contractIdSet.add(contractId);
                }
                
                if(contractIdSet != null){
                    for(Contract contr : [SELECT Id, Name,SBQQ__RenewalQuoted__c,SBQQ__RenewalOpportunity__c FROM Contract WHERE (Id IN :contractIdSet OR Name IN :successContractNameSet ) AND SBQQ__RenewalOpportunity__c = null]){
                        failedContractNameSet.add(contr.Name);
                    }   
                }  
                successContractNameSet.removeAll(failedContractNameSet);
                //passing failed contract list to same class to retry again                
                Database.executeBatch(new QTB_APIRenewalOpptyQuoteCreationBatch(successContractNameSet,failedContractNameSet,productToUpdateSet,dataHolderObjId,retryCount),Integer.valueOf(System.Label.QTB_APIRegularBatchSize));
            }
            else{
                //Updating DataHolder record as Success/Failed 
                QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
                dataHolderAPIObj.Id = dataHolderObjId;     
                
                //Few contracts are Failed/Success
                if(successContractNameSet != null && !successContractNameSet.isEmpty()){ 
                    dataHolderAPIObj.QTB_APIStatus__c = 'InProgress';
                    update dataHolderAPIObj;
                    //Scheduled to execute QTB_APIQuoteManipulationBatch Batch class to run only once after 10 to 60 min, batch size should be 1. 
                    System.scheduleBatch(new QTB_APIQuoteManipulationBatch(successContractNameSet,failedContractNameSet,productToUpdateSet,dataHolderObjId),'QTB_APIQuoteManipulationBatchJob',Integer.valueOf(System.Label.QTB_APINextBatchFireTime),Integer.valueOf(System.Label.QTB_APIQuoteBatchSize));
                }
                //All contracts are Failed
                else if((failedContractNameSet != null && !failedContractNameSet.isEmpty()) && (successContractNameSet == null || successContractNameSet.isEmpty())){
                    //reverting Subscription's subscriptiontype to 'One-time' 
                    QTB_APISubscriptionUpliftBatch.revertSubscriptionTypeOfSubscription(successContractNameSet,failedContractNameSet,productToUpdateSet);               
                    //reverting the Product's subscription type back to 'One-time'
            		QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(false);
                    
                    dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                    dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractNameSet), ','); 
                    dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractNameSet), ',');
                    update dataHolderAPIObj;
                    //Email Notification for all failed contract records
                    QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractNameSet,'Renew Oppty/Quote');
                }
            }
        }
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APIRenewalOpptyQuoteCreationBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage()); 
            
            //reverting Subscription's subscriptiontype to 'One-time' 
            QTB_APISubscriptionUpliftBatch.revertSubscriptionTypeOfSubscription(successContractNameSet,failedContractNameSet,productToUpdateSet);
            //reverting the Product's subscription type back to 'One-time'
            QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(false);
            
            //Updating status to Failed
            if(dataHolderObjId != null){
                QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                dataHolderAPIObj.Id = dataHolderObjId;
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractNameSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractNameSet), ',');  
                dataHolderAPIObj.QTB_APIErrorMessage__c = 'Class-'+QTB_APIRenewalOpptyQuoteCreationBatch+', Line No-'+e.getLineNumber() +', Error Message-'+e.getMessage();
                update dataHolderAPIObj;  
            }            
            //Email Notification for all failed contract records
            QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractNameSet,'Renew Oppty/Quote'); 
            
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIRenewalOpptyQuoteCreationBatch);
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
}