/*****************************************************************************************************
* Class: QTB_QueueBillingAmendAPI
* Author: Accenture
* Purpose: This is a Queuable class to generate Billing clones in Amend Scenario
* Requirement: SFCPQBLG-398
* Change History: 07/03/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              
*******************************************************************************************************/
global  class QTB_QueueBillingAmendAPI implements Queueable,Database.AllowsCallouts {
    global Id latestOppId;
    global List<Contract> billContractList;
    public static boolean throwExplicitException = false;
    
    //Passing Sales Contract Id and Latest Amended Billing Opportunity id to query Billing Contracts
    global QTB_QueueBillingAmendAPI(Id salesAmendContract,Id oppId){
        latestOppId=oppId;
        billContractList=Database.query('SELECT Id FROM Contract WHERE RecordTypeId =\''+QTB_Utils.CONTRACT_BILL_RECTYPEID+'\' '+
                                        'AND QTB_Sales_Contract__c =: salesAmendContract AND Status =\''+QTB_Constants.CONT_ACTIVATED_STATUS+'\'');
    }   
    global QTB_QueueBillingAmendAPI(List<Contract> contractList, ID latestOpptyId){
        billContractList=contractList;
        latestOppId = latestOpptyId;
    }  
    
    global void execute(QueueableContext qc){
        if(billContractList.size()>0){
            Contract con=billContractList[0];
            SBQQ.TriggerControl.disable();
            amendOpp(con.Id,latestOppId,billContractList);
        }
    }
    global void amendOpp(Id conId,Id latestOppId,List<Contract> billContractList){
        List<QuoteLineModel> quoteLineList = new List<QuoteLineModel>();
        QuoteModel quote = new QuoteModel();
        try{ 
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            ContractAmender amender = new ContractAmender();
            quote = amender.load(conId);
            quoteLineList.addAll(quote.lineItems);
            if(quote.record != NULL){
                List<SBQQ__QuoteLine__c> delqtLineList = new List<SBQQ__QuoteLine__c>();
                //Loop on QuoteLineModel class to Delete quote line items created from API
                for(QuoteLineModel lines : quoteLineList){
                    delqtLineList.add(new SBQQ__QuoteLine__c(Id = lines.record.id));
                }
                 system.debug('deleted quotelines>>>>'+delqtLineList);
                if(!delqtLineList.isEmpty()){
                    delete delqtLineList;
                }
                
                //Fetch Amended Sales Quote Lines via Latest Opportunity and clone the quote lines
                List<QuoteLineModel> lineModalList = new List<QuoteLineModel>();
                List<SBQQ__QuoteLine__c> qteLineList = new List<SBQQ__QuoteLine__c>();
                List<String> quoteLineFieldsList = new List<String>(SBQQ__QuoteLine__c.SObjectType.getDescribe().fields.getMap().keySet());
                system.debug('latestoppId>>>>'+latestOppId);
                String lineQuery = 'SELECT SBQQ__Quote__r.SBQQ__StartDate__c,SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,' + 
                    String.join( quoteLineFieldsList, ',' ) + 
                    ' FROM SBQQ__QuoteLine__c ' +
                    ' WHERE ' + 
                    ' SBQQ__Quote__r.SBQQ__Opportunity2__c = :latestOppId ';
                
                //To store the quote line records fetched above from latest opportunity to clone
                qteLineList = Database.query(lineQuery);
                
                Set<String> originalUpgradedSubsSet = new Set<String>();
                Map<String,Id> originalToUpgradedSubsMap = new Map<String,Id>();
                Set<ID> quoteLineIdSet = new Set<ID>();
                Map<ID,Id> quoteLineIdToSubsIdMap = new Map<ID,Id>();
                //set of Upgraded Subscription id to update in Billing Amended Quote Lines
                 system.debug('quotelines from 73 >>>>'+qteLineList);
                for(SBQQ__QuoteLine__c qline : qteLineList){
                    //Set of Quote Line Ids
                    quoteLineIdSet.add(qline.id);
                    //Set of Upgraded Subscription of Amended Quote Lines
                    if(qline.SBQQ__UpgradedSubscription__c != NULL){
                        originalUpgradedSubsSet.add(qline.SBQQ__UpgradedSubscription__c);
                    }
                }
                
                //Query on subscription to create Map of Quote Line Ids to Subscription Ids
                for(SBQQ__Subscription__c subs : [select id,SBQQ__QuoteLine__c from SBQQ__Subscription__c 
                                                  where SBQQ__QuoteLine__c IN: quoteLineIdSet]){
                                                      quoteLineIdToSubsIdMap.put(subs.SBQQ__QuoteLine__c,subs.id);  
                                                  }
                
                //Update Upgraded Subscription on New Amended Billing Quote Lines
                if(!originalUpgradedSubsSet.isEmpty()){
                    for(SBQQ__Subscription__c subs : [select id,QTB_RateCard_Subscription__c from SBQQ__Subscription__c 
                                                      where SBQQ__Contract__r.RecordTypeId =: QTB_Utils.CONTRACT_BILL_RECTYPEID
                                                      AND QTB_RateCard_Subscription__c IN : originalUpgradedSubsSet
                                                      AND SBQQ__Contract__c =:conId ]){
                                                          originalToUpgradedSubsMap.put(subs.QTB_RateCard_Subscription__c,subs.id); 
                                                      }
                }
                //Key to uniquely identify each quote lines in quoteline model
                Integer qteLineKey = 1;
                SBQQ__Quote__c qtefields = new SBQQ__Quote__c();
                for(SBQQ__QuoteLine__c qteline : qteLineList){
                    qtefields.SBQQ__StartDate__c = qteline.SBQQ__Quote__r.SBQQ__StartDate__c;
                    qtefields.SBQQ__SubscriptionTerm__c = qteline.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                    QuoteLineModel qteLineModal = new QuoteLineModel();
                    //Clone of Amended Sales Quote Lines
                    qteLineModal.record = qteline.clone();
                    qteLineModal.record.SBQQ__Quote__c = quote.record.Id;
                    qteLineModal.record.SBQQ__RequiredBy__c = NULL;
                    if(quoteLineIdToSubsIdMap.containsKey(qteline.id)){
                        qteLineModal.record.QTB_RateCard_Subscription__c = quoteLineIdToSubsIdMap.get(qteline.id);
                    }
                    qteLineModal.key = qteLineKey;
                    if(!originalToUpgradedSubsMap.isEmpty() && 
                       originalToUpgradedSubsMap.containsKey(qteLineModal.record.SBQQ__UpgradedSubscription__c)){
                           qteLineModal.record.SBQQ__UpgradedSubscription__c = originalToUpgradedSubsMap.get(qteLineModal.record.SBQQ__UpgradedSubscription__c);
                       }
                    lineModalList.add(qteLineModal); 
                    qteLineKey++;
                }
                //Update Quote fields
                quote.record.SBQQ__Status__c = QTB_Constants.APPROVED_STATUS;
                quote.record.RecordTypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
                //ALM Defect-372 Updating Billing Amend Quote start date and subscription term 
                quote.record.SBQQ__StartDate__c = qtefields.SBQQ__StartDate__c;
                quote.record.SBQQ__SubscriptionTerm__c = qtefields.SBQQ__SubscriptionTerm__c;
                
                //Clear the Quote Lines deleted
                quote.lineItems.clear();
                system.debug('lineModalList>>>>>');
                quote.lineItems.addAll(lineModalList);
                lineModalList.clear();
                QuoteSaver saver = new QuoteSaver();
                QuoteModel savedQuote = saver.save(quote);
                system.debug('saved quote>>>>'+savedQuote.record.id);
                System.enqueueJob(new QTB_QueueBillingQuoteProcess(new List<Id>{savedQuote.record.id},QTB_Constants.BILLING_AMENDMENT_PROCESSNAME,billContractList,latestOppId));             
            }
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'Quote Saver Error');  
        }
    }
}