/*****************************************************************************************************
 * Class: QTB_PurchaseOrderAccountHelper
 * Author: Virtusa
 * Purpose: This is a helper class for all business logic related to QTB_PurchaseOrderAccount object
 * Requirement: EPIC #2698
 * Change History: 16th June 2025
 * Developer        Date           Description
 * -------------------------------------------------------------------------------------------
 *              16th June 2025
 *******************************************************************************************************/
public with sharing class QTB_PurchaseOrderAccountHelper {
    
    private static final String CLASSNAME = QTB_PurchaseOrderAccountHelper.class.getName();
    
    /*Method : process
     * Parameters: List<QTB_PurchaseOrderAccount__c>, Map<ID,QTB_PurchaseOrderAccount__c>, System.TriggerOperation
     * Requirement : This is the process method gets called from PurchaseOrderAccount Trigger
     * Start Date :  16th June 2025
     * Author : Virtusa
     * Description: Generic method to handle all operations on the invoice Records
     **************************************************************************************************************/
    public static void process(List<QTB_PurchaseOrderAccount__c> newItems, Map<ID,QTB_PurchaseOrderAccount__c> oldMap,System.TriggerOperation operationType){
        Boolean callduplicateUpdateTimePeriod = false;
        try{
            /* if(newItems == null || newItems.isEmpty()) {
                throw new NullPointerException();
            } */
            if ((operationType != System.TriggerOperation.BEFORE_DELETE && operationType != System.TriggerOperation.AFTER_DELETE) &&
                (newItems == null || newItems.isEmpty()))
            {
                throw new NullPointerException();
            }
            // Calling custom Setting for Deactivating Validation Rule
            Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
            
            // Collect Purchase Order IDs FROM newItems before the loop
            Set<ID> purchaseOrderNewIdSet = new Set<ID>();
            Set<ID> accountNewIdSet = new Set<ID>();
            if (newItems !=null){
                for (QTB_PurchaseOrderAccount__c poa : newItems) {
                    if (poa.QTB_Purchase_Order__c != null) {
                        purchaseOrderNewIdSet.add(poa.QTB_Purchase_Order__c);
                    }
                    if (poa.QTB_Account__c != null) {
                        accountNewIdSet.add(poa.QTB_Account__c);
                    }
                }
            }
            // Query related Purchase Orders once
            Map<ID, QTB_PurchaseOrder__c> purchaseOrderNewMap = new Map<ID, QTB_PurchaseOrder__c>();
            if(!purchaseOrderNewIdSet.isEmpty()){
                purchaseOrderNewMap = new Map<ID, QTB_PurchaseOrder__c>([SELECT ID, QTB_Amount__c, QTB_Split_Invoice_Flag__c, QTB_Service_Type__c,QTB_Status__c,QTB_PO_Type__c,QTB_Start_Date__c,QTB_End_Date__c 
                                                                        FROM QTB_PurchaseOrder__c WHERE ID IN :purchaseOrderNewIdSet]);
            }
            // Query related Accounts once
            Map<ID, Account> accountMap = new Map<ID, Account>();
            if (!accountNewIdSet.isEmpty()) {
                accountMap = new Map<ID, Account>( [SELECT ID, Name, QTB_Split_Invoice_Flag__c
                    									 FROM Account WHERE ID IN :accountNewIdSet]);
            }
            if (newItems !=null){
                for(QTB_PurchaseOrderAccount__c poa : newItems){
                    switch on operationType {
                        when BEFORE_INSERT {
                            QTB_PurchaseOrder__c po = purchaseOrderNewMap.get(poa.QTB_Purchase_Order__c);
                            Account acc = accountMap.get(poa.QTB_Account__c);
                            if(po != null && acc != null){
                                if(acc.QTB_Split_Invoice_Flag__c == false && (po.QTB_Service_Type__c == 'Storage' || po.QTB_Service_Type__c == 'Service')) {
                                    poa.addError('Cannot create ' + po.QTB_Service_Type__c +' type PO as the billing account Split invoice flag is unchecked.');
                                }
                            }
                        }
                        when BEFORE_UPDATE{
                            
                        }
                        when BEFORE_DELETE {
                        }
                        when AFTER_DELETE{
                            
                        }
                        when AFTER_INSERT{
                        }
                    }
                }
            }
            switch on operationType {
                when BEFORE_INSERT {
                    System.debug('BEFORE_INSERT QTB_PurchaseOrderAccountHelper');
                    if(QTB_RecursiveHandlerCheck.afterUpdateCheck){
                        QTB_RecursiveHandlerCheck.afterUpdateCheck=false;
                        duplicateTimePeriod(newItems);
                        isPoContactPresent(newItems,purchaseOrderNewMap);
                    }
                }
                when BEFORE_UPDATE{
                    System.debug('BEFORE_UPDATE QTB_PurchaseOrderAccountHelper');
                    isPoContactPresent(newItems,purchaseOrderNewMap);
                    /*if(callduplicateUpdateTimePeriod)
                    {duplicateUpdateTimePeriod(newItems,oldMap);}*/
                }
                when BEFORE_DELETE {
                }
                when AFTER_DELETE{
                    system.debug('calling after delete');
                    //GITLAB US - #32514
                    clearLinkedSalesAccountIfNoPurchaseOrderAccounts(oldMap.values());
                }
                when AFTER_INSERT{
                }
            }
        }catch(Exception e ){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /******************************************************************************************************************
     * Method : isPoContactPresent
     * Parameters: List<QTB_PurchaseOrderAccount__c> poaList
     * Requirement : Gitlab EPIC #2698
     * Start Date : 16th June 2025
     * Author : Virtusa
     * Description: To validate if the billing account tagged in the Purchase order have contact with role as PO Contact
     ********************************************************************************************************************/
    public static void isPoContactPresent(List<QTB_PurchaseOrderAccount__c> purchaseOrderAccountList ,Map<ID,QTB_PurchaseOrder__c> purchaseOrderNewMap)
    {
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException || purchaseOrderAccountList == null || purchaseOrderNewMap == null){
                throw new NullPointerException();
            }
            System.debug('we are in = ');
            //Fetch all billing accounts related to the purchase orders and create billing account List
            List<ID> billingAccountList = new List<ID>();
            for(QTB_PurchaseOrderAccount__c poa: purchaseOrderAccountList){
                if(purchaseOrderNewMap.get(poa.QTB_Purchase_Order__c).QTB_Status__c == QTB_Constants.ACTIVE){
                    billingAccountList.add(poa.QTB_Account__c);
                }
            }
            
            //Fetching all the AccountContactRelation records for the eligible billing accounts
            List<AccountContactRelation> accountContactRelationList = [SELECT ID,Roles,AccountId,ContactId,QTB_Primary__c
                                                        FROM AccountContactRelation WHERE AccountId IN: billingAccountList WITH SYSTEM_MODE];
            System.debug('accountContactRelationList = ' + accountContactRelationList);
            Map<ID,List<ID>> billingAcntPoCntMap = new Map<ID,List<String>>();
            for(AccountContactRelation accountContactitem :accountContactRelationList){
                //Logic to check whether PO Contact is associated with the Billing Account
                if(accountContactitem.Roles!= null && String.valueOf(accountContactitem.Roles).contains('PO Contact')){
                    if(billingAcntPoCntMap.get(accountContactitem.AccountId) != null){
                        List<ID> contactIdList = billingAcntPoCntMap.get(accountContactitem.AccountId);
                        contactIdList.add(accountContactitem.ContactId);
                        billingAcntPoCntMap.put(accountContactitem.AccountId, contactIdList);
                    }else{
                        billingAcntPoCntMap.put(accountContactitem.AccountId, new List<ID>{accountContactitem.ContactId});
                    }
                }
            }
            for(QTB_PurchaseOrderAccount__c poa: purchaseOrderAccountList){
                //Logic to stop saving the Purchase order if the associated Billing Account doesn't have PO Contact
                if(billingAcntPoCntMap.get(poa.QTB_Account__c) == null && purchaseOrderNewMap.get(poa.QTB_Purchase_Order__c).QTB_Status__c == QTB_Constants.ACTIVE){
                    poa.addError(System.label.QTB_PurchaseOrder_Error);
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderAccountHelper.class.getname());
            throw e;
        }
    }
    
    /******************************************************************************************************************
     * Method : duplicateTimePeriod
     * Parameters: List<QTB_PurchaseOrderAccount__c> purchaseList
     * Requirement : Gitlab EPIC #2698
     * Start Date : 16th June 2025
     * Author : Virtusa
     * Description: To validate the new purchase order record with the same billing account has the already existing time period
    Gitlab EPIC #2698 - bypassing validation error to create PO with different service type with overlapping dates
         ********************************************************************************************************************/
    public static void duplicateTimePeriod(List<QTB_PurchaseOrderAccount__c> purchaseOrderAccountList)
    {
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException || purchaseOrderAccountList == null ){
                throw new NullPointerException();
            }
            
            Set<ID> poIdSet = new Set<ID>();
            List<ID> billingAccountList = new List<ID>();
            Map<ID,List<QTB_PurchaseOrder__c>> AccountIdNewPOMap = new Map<ID,List<QTB_PurchaseOrder__c>>();
            //Get all the PO Newly Inserted wrt Account ID
            for(QTB_PurchaseOrderAccount__c poa: purchaseOrderAccountList){
                if (poa.QTB_Purchase_Order__c != null && poa.QTB_Account__c != null) {
                    // if (poa.QTB_Purchase_Order__r.QTB_Status__c == QTB_Constants.ACTIVE){
                        poIdSet.add(poa.QTB_Purchase_Order__c);
                        billingAccountList.add(poa.QTB_Account__c);
                    }
                }
                
                //Check Active PO
                Map<ID, QTB_PurchaseOrder__c> poMap = new Map<ID, QTB_PurchaseOrder__c>([SELECT ID, QTB_Status__c, QTB_Service_Type__c, Name, QTB_Start_Date__c,            
                                                                                        QTB_End_Date__c, QTB_PO_Type__c 
                                                                                        FROM QTB_PurchaseOrder__c WHERE ID IN :poIdSet And QTB_Status__c = 'Active']);
                
                System.debug('billingAccountList'+billingAccountList);
                System.debug('poMap'+poMap);
                if(!poMap.isEmpty() && !billingAccountList.isEmpty()){
                    //Fetch all the purchase order related to the billing account
                    List<QTB_PurchaseOrder__c> polist = [SELECT ID,QTB_Service_Type__c, Name,QTB_Start_Date__c, QTB_End_Date__c,QTB_PO_Type__c, 
                                                    (SELECT ID, Name, QTB_Account__c, QTB_Purchase_Order__c FROM PurchaseOrderAccounts__r) 
                                                FROM QTB_PurchaseOrder__c 
                                                WHERE ID IN (SELECT QTB_Purchase_Order__c FROM QTB_PurchaseOrderAccount__c WHERE QTB_Account__c IN :billingAccountList) 
                                                AND QTB_Status__c =: QTB_Constants.ACTIVE];
                    
                    Map<ID,List<QTB_PurchaseOrder__c>> accountIdPOMap = new Map<ID,List<QTB_PurchaseOrder__c>>();
                    //Get all the Existing PO wrt Account ID
                    for (QTB_PurchaseOrder__c po : polist) {
                        for (QTB_PurchaseOrderAccount__c poAccount : po.PurchaseOrderAccounts__r) {
                            ID accountId = poAccount.QTB_Account__c;
                            
                            if (accountIdPOMap!=null && accountIdPOMap.containsKey(accountId)) {
                                accountIdPOMap.get(accountId).add(po);
                            } else {
                                accountIdPOMap.put(accountId, new List<QTB_PurchaseOrder__c>{ po });
                            }
                        }
                    }
                    //Check if the above condition not matching
                    for (QTB_PurchaseOrderAccount__c poa : purchaseOrderAccountList) {
                        QTB_PurchaseOrder__c curentPo = poMap.get(poa.QTB_Purchase_Order__c);
                        if (curentPo == null) {
                            continue;
                        }
                        //Check if Any Existing PO is present or not
                        if(poa.QTB_Account__c != null && accountIdPOMap.containsKey(poa.QTB_Account__c)){
                            for(QTB_PurchaseOrder__c exstingPo : accountIdPOMap.get(poa.QTB_Account__c)){
                                if (exstingPo == null) {
                                    continue;
                                }
                                //Gitlab #22654 -if service type is different then allow to create PO with overlapping dates
                                if((curentPo.QTB_Service_Type__c == exstingPo.QTB_Service_Type__c && curentPo.QTB_PO_Type__c == exstingPo.QTB_PO_Type__c)){
                                    if((curentPo.QTB_Start_Date__c  < exstingPo.QTB_Start_Date__c && curentPo.QTB_Start_Date__c  < exstingPo.QTB_End_Date__c) &&
                                        (curentPo.QTB_End_Date__c > exstingPo.QTB_Start_Date__c && curentPo.QTB_End_Date__c < exstingPo.QTB_End_Date__c) ||   // Mix
                                        // Mix
                                    ((curentPo.QTB_Start_Date__c  > exstingPo.QTB_Start_Date__c && curentPo.QTB_Start_Date__c  < exstingPo.QTB_End_Date__c) &&
                                        (curentPo.QTB_End_Date__c > exstingPo.QTB_Start_Date__c && curentPo.QTB_End_Date__c > exstingPo.QTB_End_Date__c)) ||
                                        // Inside
                                    ((curentPo.QTB_Start_Date__c  > exstingPo.QTB_Start_Date__c && curentPo.QTB_Start_Date__c  < exstingPo.QTB_End_Date__c) &&
                                        (curentPo.QTB_End_Date__c > exstingPo.QTB_Start_Date__c && curentPo.QTB_End_Date__c < exstingPo.QTB_End_Date__c))   ||
                                        // Outside
                                    ((curentPo.QTB_Start_Date__c  < exstingPo.QTB_Start_Date__c && curentPo.QTB_Start_Date__c  < exstingPo.QTB_End_Date__c) &&
                                        (curentPo.QTB_End_Date__c > exstingPo.QTB_Start_Date__c && curentPo.QTB_End_Date__c > exstingPo.QTB_End_Date__c)) ||
                                        // Only Start date Present
                                    (curentPo.QTB_Start_Date__c > exstingPo.QTB_Start_Date__c && curentPo.QTB_Start_Date__c < exstingPo.QTB_End_Date__c) ||
                                        // Only End date Present
                                    (curentPo.QTB_End_Date__c > exstingPo.QTB_Start_Date__c && curentPo.QTB_End_Date__c < exstingPo.QTB_End_Date__c))
                                    {
                                        //Throw Error
                                        poa.adderror(System.label.QTB_PO_Overlapping_TypeValidation+'  for PO Record: '+exstingPo.Name);
                                        break;
                                    }
                                    //Allowing  PO With same date range but should have different PO Types or Service Type //23922
                                    if((curentPo.QTB_PO_Type__c == exstingPo.QTB_PO_Type__c && curentPo.QTB_Service_Type__c == exstingPo.QTB_Service_Type__c )
                                        && (curentPo.QTB_Start_Date__c == exstingPo.QTB_Start_Date__c || curentPo.QTB_End_Date__c == exstingPo.QTB_End_Date__c
                                        || curentPo.QTB_Start_Date__c == exstingPo.QTB_End_Date__c || curentPo.QTB_End_Date__c == exstingPo.QTB_Start_Date__c))
                                    {
                                        System.debug('elseiffstartdate');
                                        poa.adderror(System.label.QTB_PO_Overlapping_TypeValidation);
                                    }
                                }
                            }
                        }
                    }
                }
            }catch(Exception e){
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
                throw e;
            }
        }
        /******************************************************************************************************************
         * Method : clearLinkedSalesAccountIfNoPurchaseOrderAccounts
         * Parameters: Iterable<QTB_PurchaseOrderAccount__c> deletedRecords
         * Requirement : Gitlab EPIC #2698, GITLAB US - #32514
         * Start Date : 5th August 2025
         * Author : Virtusa
         * Description: To set the linked sales Account field at purchase order to blank if the purchase order Account records
        delinked and no POA records exists to specific Purchase order records.
             ********************************************************************************************************************/
        public static void clearLinkedSalesAccountIfNoPurchaseOrderAccounts(Iterable<QTB_PurchaseOrderAccount__c> deletedRecords) {
            system.debug('calling clearLinkedSalesAccountIfNoPurchaseOrderAccounts');
            try {
                Set<Id> purchaseOrderIds = new Set<Id>();
                for (QTB_PurchaseOrderAccount__c poa : deletedRecords) {
                    if (poa.QTB_Purchase_Order__c != null) {
                        purchaseOrderIds.add(poa.QTB_Purchase_Order__c);
                    }
                }
                if (purchaseOrderIds.isEmpty()) return;
                
                // Aggregate query to find counts of remaining PurchaseOrderAccount records per PurchaseOrder
                AggregateResult[] groupedResults = [
                SELECT QTB_Purchase_Order__c purchaseOrderId, COUNT(Id) recordCount
                FROM QTB_PurchaseOrderAccount__c
                WHERE QTB_Purchase_Order__c IN :purchaseOrderIds
                GROUP BY QTB_Purchase_Order__c
            ];
                
                Map<Id, Integer> poIdToCountMap = new Map<Id, Integer>();
                for (AggregateResult ar : groupedResults) {
                    poIdToCountMap.put((Id)ar.get('purchaseOrderId'), Integer.valueOf(ar.get('recordCount')));
                }
                
                List<QTB_PurchaseOrder__c> purchaseOrdersToUpdate = new List<QTB_PurchaseOrder__c>();
                for (Id poId : purchaseOrderIds) {
                    Integer count = poIdToCountMap.containsKey(poId) ? poIdToCountMap.get(poId) : 0;
                    system.debug('count-->' +count);
                    if (count == 0) {
                        purchaseOrdersToUpdate.add(new QTB_PurchaseOrder__c(
                            Id = poId,
                        QTB_Linked_Sales_Account__c = null
                            ));
                    }
                }
                
                if (!purchaseOrdersToUpdate.isEmpty()) {
                    update purchaseOrdersToUpdate;
                }
            } catch (Exception e) {
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
                throw e;
            }
        }
        
    }