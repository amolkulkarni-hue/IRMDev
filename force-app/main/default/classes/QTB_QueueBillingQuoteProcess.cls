/*****************************************************************************************************
* Class: QTB_QueueBillingQuoteProcess
* Author: Accenture
* Purpose: This is a Queuable class calling QTB_QueueBillingQuoteProcess
* Requirement: SFCPQBLG-398,SFCPQBLG-49,SFCPBLG-295
* Change History: 07/27/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              
*******************************************************************************************************/
global class QTB_QueueBillingQuoteProcess implements Queueable{
    global List<Id> quoteIdList;
    global String processName;
    global Id latestOpptyId;
    global List<Contract> contrList = new List<Contract>();
    global static final integer queueSize=2;
    global QTB_QueueBillingQuoteProcess(List<Id> qIdList,String pName){
        quoteIdList=qIdList;
        processName=pName;
    }
    global QTB_QueueBillingQuoteProcess(List<Id> qIdList,String pName,List<contract> contList,Id latestOpportunityId){
        quoteIdList=qIdList;
        processName=pName;
        contrList=contList;
        latestOpptyId = latestOpportunityId;
    }
    global void execute(QueueableContext qc){
        List<Id> failedQtIdList=new List<Id>();
        List<SBQQ__Quote__c> qtsToUpdate=new List<SBQQ__Quote__c>();
        SBQQ__Quote__c qt=new SBQQ__Quote__c();
        qt.id=quoteIdList[0];
        qt.SBQQ__Ordered__c=TRUE;
        qtsToUpdate.add(qt);
        Database.SaveResult[] qtUpdateSR = Database.update(qtsToUpdate,false);
        for(Database.SaveResult SR: qtUpdateSR ){
            if(!SR.isSuccess()){
                Database.Error errors =  SR.getErrors().get(0);
                System.debug('Error Occurs While Processing The Record'+errors.getMessage());
                failedQtIdList.add(qtsToUpdate[0].id); //only one Quote processed in each transaction                                           
            }                  
            
        }
        /*Comment Out the code as per Git lab story Number #30007
        if(failedQtIdList.size()>0)
        	QTB_RenewalBillingBatchHelper.sendErrorLogMail(failedQtIdList,processName);*/
        
        quoteIdList.remove(0);
        if(quoteIdList.size()>0)
            system.enqueueJob(new QTB_QueueBillingQuoteProcess(quoteIdList,'Orderprocess'));
        
        if(contrList.size() > 0 && processName == QTB_Constants.BILLING_RENEWAL_PROCESSNAME)
        {
            contrList.remove(0);
            if(contrList.size()>0)
                system.enqueueJob(new QTB_QueueRenewalBilling(contrList));
        }
        if(contrList.size() > 0 && processName == QTB_Constants.BILLING_AMENDMENT_PROCESSNAME)
        {
            contrList.remove(0);
            if(contrList.size()>0){
                //ALM Defect 361 - Passing Latest Oppty Id for 2nd contract
                system.enqueueJob(new QTB_QueueBillingAmendAPI(contrList,latestOpptyId));
            }
        }
    }
    
}