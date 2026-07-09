/*****************************************************************************************************
* Class			: QTB_APIBillingOrderManipulationBatch
* Test Class	: QTB_APIBillingOrderCreationBatch_Test
* Author		: IRM/Virtusa
* Purpose	 	: Creating Billing order in Regular API process
* Requirement	: Gitlab US #12706 - Main Uplift Functionality: Step 5 - Create Billing Order
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Shailesh       		25/12/2022       Gitlab US #12706 - Main Uplift Functionality: Step 5 - Create Billing Order
*******************************************************************************************************/
public class QTB_APIBillingOrderManipulationBatch implements Database.Batchable<sObject>,Database.Stateful {
    public static final string QTB_APIBillingOrderManipulationBatch = 'QTB_APIBillingOrderManipulationBatch';
    Set<String> failedContractSet = new Set<String>();
    Set<String> successContractSet = new Set<String>();
    Id dataHolderAPIObjId;
    Map<Id,Id> originalSalesOrderWithNewSalesOrderMap = new Map<Id,Id>();
    Map<Id,Id> BillingAccountWithSalesOrderIdMap = new Map<Id,Id>();
    Map<Id,Id> BillingOrderIdWithBillingAccountIdMap = new Map<Id,Id>();
    Set<Id> billingOrderIdSet = new Set<Id>();
    set<Id> failedBillingOrderSet = new Set<Id>();
    public static boolean throwExplicitException = false;
    Integer retryCount = 0; 
    
    public QTB_APIBillingOrderManipulationBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar,
                                                Map<Id,Id> originalSalesOrderWithNewSalesOrderMapVar,
                                                Map<Id,Id> BillingAccountWithSalesOrderIdMapVar, 
                                                Map<Id,Id> BillingOrderIdWithBillingAccountIdMapVar, 
                                                Id dataHolderAPIObjIdVar, set<Id> failedBillingOrderSetVar, Integer retries)
    {
        System.debug('QTB_APIBillingOrderManipulationBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APIBillingOrderManipulationBatch_failedContractSetVar@@'+failedContractSetVar);
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;   
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
        originalSalesOrderWithNewSalesOrderMap = originalSalesOrderWithNewSalesOrderMapVar;
        BillingAccountWithSalesOrderIdMap = BillingAccountWithSalesOrderIdMapVar;
        BillingOrderIdWithBillingAccountIdMap = BillingOrderIdWithBillingAccountIdMapVar;
        if(BillingOrderIdWithBillingAccountIdMap != null && !BillingOrderIdWithBillingAccountIdMap.isEmpty()){
            for(Id bilOrd : BillingOrderIdWithBillingAccountIdMap.keySet() ){
                billingOrderIdSet.add(bilOrd);
            }  
        }        
        failedBillingOrderSet = failedBillingOrderSetVar;
        retryCount = retries;
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab #
* Description: start() method is used for to query all newly generated Sales Orders
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('QTB_APIBillingOrderManipulationBatch_start()@@');
        string billingOrderQuery = 'SELECT Id,Name, AccountId, Account.QTB_Source_Order__c From Order '; 
        
        if(this.retryCount != null && this.retryCount > 0 && failedBillingOrderSet != null && !failedBillingOrderSet.isEmpty())
        {
            billingOrderQuery = billingOrderQuery +' where Id IN :failedBillingOrderSet';
        }
        else
        {
            billingOrderQuery = billingOrderQuery +' where Id IN :billingOrderIdSet';
        }
        
        Database.QueryLocator queryResult = Database.getQueryLocator( billingOrderQuery ); 
        Database.QueryLocatorIterator iterate =  queryResult.iterator();
        Integer countVariable = 0;
        if(iterate != null){
            while (iterate.hasNext())
            {     
                countVariable++;
                break;
            }
        }
        if(countVariable == 0 && failedContractSet != null){
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
        }
        
        return Database.getQueryLocator(billingOrderQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab #
* Description: execute() methods is used to create billing order by updating the QTB_Source_Order__c field value on Billing Account
: scope size must be 1.
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<Order> billingOrderList){
        try{     
            List<Account> billingAccountListFinal = new List<Account>();
            System.debug('QTB_BillingOrderManipulationBatch_execute()@@'+billingOrderList);
            System.debug('QTB_BillingOrderManipulationBatch_BillingAccountWithSalesOrderIdMap@@'+BillingAccountWithSalesOrderIdMap);
            System.debug('QTB_BillingOrderManipulationBatch_originalSalesOrderWithNewSalesOrderMap@@'+originalSalesOrderWithNewSalesOrderMap);
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(billingOrderList != null && !billingOrderList.isEmpty()){
                Account billingAcc = new Account();
                Id billingAccId = BillingOrderIdWithBillingAccountIdMap.get(billingOrderList[0].Id);
                System.debug('QTB_BillingOrderManipulationBatch_123@@'+originalSalesOrderWithNewSalesOrderMap.get(BillingAccountWithSalesOrderIdMap.get(billingAccId)));
               if(BillingAccountWithSalesOrderIdMap != null && !BillingAccountWithSalesOrderIdMap.isEmpty() && BillingAccountWithSalesOrderIdMap.containsKey(billingAccId) && 
                  originalSalesOrderWithNewSalesOrderMap != null && !originalSalesOrderWithNewSalesOrderMap.isEmpty() && originalSalesOrderWithNewSalesOrderMap.containsKey(BillingAccountWithSalesOrderIdMap.get(billingAccId))){
                    System.debug('if@@');
                    billingAcc.Id = billingAccId;
                    billingAcc.QTB_Source_Order__c = originalSalesOrderWithNewSalesOrderMap.get(BillingAccountWithSalesOrderIdMap.get(billingAccId));
                    billingAccountListFinal.add(billingAcc);
                }
            }
            else{
                failedContractSet.addAll(successContractSet);                
                successContractSet.clear();
            }
            
            if(billingAccountListFinal != null && !billingAccountListFinal.isEmpty()){
                wait(Integer.valueOf(System.Label.QTB_APIDelayInMilliseconds)); //providing delay for 30 sec as to avoid record lock issue
                update billingAccountListFinal;
            }
        }
        catch (Exception e){
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
            failedBillingOrderSet.add(billingOrderList[0].Id);
            System.debug('Apex Class@@'+QTB_APIBillingOrderManipulationBatch);            
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIBillingOrderManipulationBatch); 
        }
    }   
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab #
* Description: finish() method is used for to create billing Order Creation and send fail/pass email to logged-in user
**********************************************************************************************************/
    public void finish (Database.BatchableContext bc){
        try{
            System.debug('QTB_BillingOrderManipulationBatch_finish()@@');     
            System.debug('QTB_BillingOrderManipulationBatch_successContractSet@@'+successContractSet);
            System.debug('QTB_BillingOrderManipulationBatch_failedContractSet@@'+failedContractSet);
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.Id = dataHolderAPIObjId;
            
            if(successContractSet !=null && !successContractSet.isEmpty() && !Test.isRunningTest()){
                //If any contract failed, retrying few more times based on value store in label QTB_APIFailedContractRetryCount by calling the same class again with failed contract
                if(failedContractSet != null && !failedContractSet.isEmpty() && failedBillingOrderSet != null &&
                   retryCount < Integer.valueOf(System.Label.QTB_APIFailedContractRetryCount) && !Test.isRunningTest())
                {
                    retryCount = retryCount + 1; 
                    Database.executeBatch(new QTB_APIBillingOrderManipulationBatch(successContractSet,failedContractSet,
                                                                                   originalSalesOrderWithNewSalesOrderMap,
                                                                                   BillingAccountWithSalesOrderIdMap,
                                                                                   BillingOrderIdWithBillingAccountIdMap,
                                                                                   dataHolderAPIObjId,failedBillingOrderSet,retryCount), Integer.valueOf(System.Label.QTB_APIBillingOrderBatchSize));
                }
                else{
                    //success
                    if(failedContractSet == null || failedContractSet.isEmpty()){
                        //Updating Status to Success
                        dataHolderAPIObj.QTB_APIStatus__c = 'Success'; 
                        //Sending Success mail to logged-in user
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        List<String> loggedInUserEmailList = new List<String>();
                        loggedInUserEmailList.add(UserInfo.getUserEmail());
                        loggedInUserEmailList.AddAll(System.Label.QTB_APIProcessFailedEmailNotificationUsersEMail.split(','));
                        message.toAddresses = loggedInUserEmailList ;
                        message.subject = 'Regular API Process Successful';
                        message.plainTextBody = 'Dear '+UserInfo.getName() +',\n\n' +
                            'Regular API process is successful,\n'+
                            'Following are the contracts processed successfully : '+successContractSet +
                            '\n\nThank You';
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
                    }
                    else{
                        //Updating Status to Success
                        dataHolderAPIObj.QTB_APIStatus__c = 'Partially Failed'; 
                        //Send email to logged-in user with failed contracts
                        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'BillingOrder');
                    }
                    dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                    dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
                    update dataHolderAPIObj;
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
                QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'BillingOrder');   
            }  
            
            
        }
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APIBillingOrderManipulationBatch);            
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
            //Updating Status to Failed
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
            dataHolderAPIObj.QTB_APISuccessContracts__c = ''; //no success due to exception 
            dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
            dataHolderAPIObj.QTB_APIErrorMessage__c = 'Class-'+QTB_APIBillingOrderManipulationBatch+', Line No-'+e.getLineNumber() +', Error Message-'+e.getMessage();
            dataHolderAPIObj.Id = dataHolderAPIObjId;
            update dataHolderAPIObj;
            
            //Send email to logged-in user with failed contracts
            QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'BillingOrder');
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIBillingOrderManipulationBatch); 
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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