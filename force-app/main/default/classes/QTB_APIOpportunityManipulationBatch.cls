/*****************************************************************************************************
* Class         : QTB_APIOpportunityManipulationBatch
* Test Class    : QTB_APIOpportunityManipulationBatch_Test
* Author        : IRM/Virtusa
* Purpose       : This class is responsible to update the Opportunity stages along with required fields.
* Requirement   : Gitlab US #12041 - Main Uplift Functionality: Update Quote Status and Move Opportunity Stages
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Shailesh              08/12/2022      Gitlab US #12041 - Main Uplift Functionality: Update Quote Status and Move Opportunity Stages 
*******************************************************************************************************/
public class QTB_APIOpportunityManipulationBatch implements Database.Batchable<sObject>,Database.Stateful {
    public static final string QTB_APIOpportunityManipulationBatch = 'QTB_APIOpportunityManipulationBatch';
    Set<String> failedContractSet = new Set<String>();
    Set<String> successContractSet = new Set<String>();
    Id dataHolderAPIObjId;
    List<Opportunity> oppFinalList = new List<Opportunity>();
    public static boolean throwExplicitException = false;    
    
    public QTB_APIOpportunityManipulationBatch(Set<String> successContractSetVar ,Set<String> failedContractSetVar, Id dataHolderAPIObjIdVar){
        System.debug('QTB_APIOpportunityManipulationBatch_successContractSetVar@@'+successContractSetVar);
        System.debug('QTB_APIOpportunityManipulationBatch_failedContractSetVar@@'+failedContractSetVar);
        successContractSet = successContractSetVar;
        failedContractSet = failedContractSetVar;        
        dataHolderAPIObjId = dataHolderAPIObjIdVar;
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters : Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab US #12041
* Description: start() method is used for to query all Opportunity based on RenewalContractName
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc){
        String opportunityQuery ='SELECT Id,Name,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.Name,AccountId,StageName,Primary_Product_Line__c,Pricebook2Id,'+
            ' GSA_Eligibility__c,US_Federal_GSA_Pricing__c,IME_Reason_Won__c,SBQQ__RenewedContract__r.SBQQ__Opportunity__r.GSA_Eligibility__c,'+
            ' SBQQ__RenewedContract__r.SBQQ__Opportunity__r.US_Federal_GSA_Pricing__c,SBQQ__RenewedContract__r.SBQQ__Opportunity__r.IME_Reason_Won__c'+
            ' FROM Opportunity'+
            ' WHERE SBQQ__RenewedContract__r.Name IN :successContractSet order by SBQQ__RenewedContract__r.Name asc';
        System.debug('QTB_APIQuoteManipulationBatch_opportunityQuery@@'+opportunityQuery);
        Database.QueryLocator queryResult = Database.getQueryLocator( opportunityQuery ); 
        Database.QueryLocatorIterator iterate =  queryResult.iterator();
        Integer countVariable = 0;
        if(iterate != null){
            while (iterate.hasNext())
            {     
                countVariable++;
                break;
            }
        }
        if(countVariable == 0){
            failedContractSet.addAll(successContractSet);
            successContractSet.clear();
        }
        
        return Database.getQueryLocator(opportunityQuery);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters : Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab US #12041
* Description: execute() methods is used for updating Opportunity stage to stage 5 along with required fields.
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<Opportunity> OpportunityList){
        System.debug('QTB_APIOpportunityManipulationBatch_execute()_OpportunityList@@'+OpportunityList);
        Set<String> contractSet = new Set<String>();
        Set<Id> failedOpptyId = new Set<Id>();
        try {      
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(OpportunityList != null && !OpportunityList.isEmpty()){
                for(Opportunity opp : OpportunityList){
                    if(opp.SBQQ__RenewedContract__c != null){
                        contractSet.add(opp.SBQQ__RenewedContract__r.Name); 
                    }
                    Opportunity oppObj = new Opportunity();
                    oppObj.Id = opp.Id;
                    oppObj.StageName = '5 - Signed/PO in';
                    oppObj.QTB_APIProcess__c = true;//setting this field value as true & this field used in QTB_OpportunityProcess to exclude the sales order creation using process builder/Platform event. 
                    if(opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__c != null){
                        oppObj.GSA_Eligibility__c = opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.GSA_Eligibility__c;
                        oppObj.US_Federal_GSA_Pricing__c = opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.US_Federal_GSA_Pricing__c;
                        oppObj.IME_Reason_Won__c = opp.SBQQ__RenewedContract__r.SBQQ__Opportunity__r.IME_Reason_Won__c;   
                    }
                    oppFinalList.add(oppObj);
                }
            }
            //Update opportunities
            if(oppFinalList != null && !oppFinalList.isEmpty()){
                //update oppFinalList;
                Database.SaveResult[] srList = Database.update(oppFinalList, false);//partial updation
                String ErrorMsg;
                // Iterate through each returned result
                for (Integer i = 0; i < srList.size(); i++) {
                    if (!srList[i].isSuccess()) {
                        failedOpptyId.add(srList[i].getId());
                         ErrorMsg= srList[i].getErrors()[0].getMessage();                        
                    }
                }
                
                if(failedOpptyId != null && !failedOpptyId.isEmpty()){
                    for(Opportunity opp : [SELECT Id,Name,StageName,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.Name 
                                           FROM Opportunity
                                           WHERE ID IN :failedOpptyId])
                    {
                        failedContractSet.add(opp.SBQQ__RenewedContract__r.Name);
                        if(successContractSet != null && successContractSet.contains(opp.SBQQ__RenewedContract__r.Name))
                		{
                            successContractSet.remove(opp.SBQQ__RenewedContract__r.Name);
                        }
                        QTB_ExceptionLogger.enable();
                        QTB_ExceptionLogger.createLog(92,opp.SBQQ__RenewedContract__r.Name+'-'+ErrorMsg,ErrorMsg,'',QTB_APIOpportunityManipulationBatch); 
                    }
                }
            }         
        }
        catch (Exception e){
            failedContractSet.addAll(contractSet);
            successContractSet.clear();
            System.debug('Apex Class@@'+QTB_APIOpportunityManipulationBatch);            
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIOpportunityManipulationBatch); 
        }
    }
    /*********************************************************************************************************
* Method Name: finish
* Parameters : Database.BatchableContext
* Return Type: void
* Requirement: Gitlab US #12041
* Description: finish() method is used for to update opportunity stage to 6 
: and if failure case sending email to logged-in user for failed contracts
**********************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        try{
            System.debug('QTB_APIOpportunityManipulationBatch_finish()_successContractSet@@'+successContractSet);
            System.debug('QTB_APIOpportunityManipulationBatch_finish()_failedContractSet@@'+failedContractSet);
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if(successContractSet != null && !successContractSet.isEmpty()){
                List<Opportunity> oppFinalList = new List<Opportunity>();
                Set<Id> oppIdSet = new Set<Id>();
                //Fetching Opportunity based on renewal Contract & Set the Opportunity Stage to stage 6
                for(Opportunity opp : [SELECT Id, Name,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.Name,StageName,QTB_APIProcess__c
                                       FROM Opportunity
                                       WHERE SBQQ__RenewedContract__r.Name IN :successContractSet])
                {
                    oppIdSet.add(opp.Id);
                    Opportunity oppObj = new Opportunity();
                    oppObj.Id = opp.Id;
                    oppObj.StageName = '6 - Setup';
                    oppFinalList.add(oppObj);
                }
                if(oppFinalList != null && !oppFinalList.isEmpty()){
                    update oppFinalList;
                    //Calling QTB_APICreateSalesOrderBatch batch, batch size should be 1.
                    if(!Test.isRunningTest()){
                        Database.executeBatch(new QTB_APICreateSalesOrderBatch(successContractSet,failedContractSet,oppIdSet,dataHolderAPIObjId), Integer.valueOf(System.Label.QTB_APISalesOrderBatchSize));
                    }
                }
            }            
            //successContractSet is empty & failedContractSet is not empty
            else if((successContractSet == null || successContractSet.isEmpty()) && (failedContractSet != null && !failedContractSet.isEmpty())){
                //Updating Status to Failed
                QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
                dataHolderAPIObj.Id = dataHolderAPIObjId;
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed'; 
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
                update dataHolderAPIObj;
                //Send email to logged-in user with failed contracts
                QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'Opportunity');
            }
        }
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APIOpportunityManipulationBatch);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            //Updating Status to Failed
            if(dataHolderAPIObjId !=null){
                QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
                dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
                dataHolderAPIObj.Id = dataHolderAPIObjId;
                dataHolderAPIObj.QTB_APISuccessContracts__c = String.join(new List<String>(successContractSet), ','); 
                dataHolderAPIObj.QTB_APIFailedContracts__c = String.join(new List<String>(failedContractSet), ',');
                dataHolderAPIObj.QTB_APIErrorMessage__c = 'Class-'+QTB_APIOpportunityManipulationBatch+', Line No-'+e.getLineNumber() +', Error Message-'+e.getMessage();
                update dataHolderAPIObj;  
            }
            //Send email to logged-in user with failed contracts
            failedContractSet.addAll(successContractSet); //if any exception caught then storing all contracts to failedContractSet 
            QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet,'Opportunity');
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIOpportunityManipulationBatch); 
        }
    }
}