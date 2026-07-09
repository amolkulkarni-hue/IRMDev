/*****************************************************************************************************
* Class: QTB_CalculatePOBalanceBatch
* Author: TCS
* Purpose: This is a Batch class for calculating Purchase Order Balance amount
* Requirement: Gitlab #1327
* Change History: 04/06/2021
* Developer       Date            Description
* ------------------------------------------------------------------------------------------- 
* Renuka Prasad   04/06/2021
* Renuka Prasad   02/27/2021      Gitlab #3772
*******************************************************************************************************/
public class QTB_CalculatePOBalanceBatch implements Database.Batchable<sObject>, Database.Stateful
{
    public static final String ACTIVE = QTB_Constants.ACTIVE;
    public static final String STATUS_POSTED = QTB_Constants.INVOICE_STATUS_POSTED;
    public Set<ID> purchaseOrderIds;
    public Set<ID> invoiceIds;
    public Set<ID> creditNoteIds;
    public list<Id> finalPOList;
    
    /*********************************************************************************************************
* Contructor for QTB_CalculatePOBalanceBatch
* Parameters: Set<ID> invoiceIds, Set<ID> creditNoteIds, Set<ID> purchaseOrderIds
* Requirement: Gitlab #1327
**********************************************************************************************************/
    public QTB_CalculatePOBalanceBatch (Set<ID> invoiceIds, Set<ID> creditNoteIds, Set<ID> purchaseOrderIds)
    {
        this.purchaseOrderIds = purchaseOrderIds;
        this.invoiceIds = invoiceIds;
        this.creditNoteIds = creditNoteIds;
        finalPOList = new list<Id>();
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters: Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: Gitlab #1327
* Description: Query required records
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = '';
        //Changing query logic for Gitlab #3772
        if (purchaseOrderIds.size() > 0)// Only from PO Trigger
        {
            //Query to fetch all the Purchase Orders for which po balance re-calculation is required.
            query =
                'SELECT id,QTB_Date_Of_100_Utilization__c,QTB_PO_Utilized_Amount__c, QTB_Amount__c, QTB_Billing_Account__c, QTB_Status__c, QTB_End_Date__c, QTB_Start_Date__c, ' +
                ' QTB_PO_Balance_Amount__c FROM QTB_PurchaseOrder__c where ' +
                ' QTB_Status__c =: ACTIVE and ID IN ' + ':purchaseOrderIds';
        } else {// Only from Invoice/ Credit Note Trigger
            //Qurey for fetching all the eligible PO's for balance calculations (StartDate < TODAY < EndDate)
            query =
                'SELECT id,QTB_Date_Of_100_Utilization__c, QTB_Amount__c,QTB_PO_Utilized_Amount__c, QTB_Billing_Account__c, QTB_Status__c, QTB_End_Date__c, QTB_Start_Date__c, ' +
                ' QTB_PO_Balance_Amount__c FROM QTB_PurchaseOrder__c where ' +
                ' QTB_Start_Date__c <= TODAY and QTB_End_Date__c >= TODAY and ' +
                ' QTB_Status__c =:ACTIVE';
        }
        System.debug('query>>'+query);
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
* Method Name: execute
* Parameters: Database.BatchableContext,List<SObject>
* Return Type: void
* Requirement: Gitlab #1327
**********************************************************************************************************/
    public void execute(Database.BatchableContext bc, list<QTB_PurchaseOrder__c> scope)
    {
        //Variables declaration
        Map<ID, QTB_PurchaseOrder__c> billingAcntPurchaseOrdMap = new Map<ID, QTB_PurchaseOrder__c>();
        Map<ID, List<QTB_PurchaseOrder__c>> acctPOMap = new Map<ID, List<QTB_PurchaseOrder__c>>(); //added by shailesh
        Map<string, Decimal> billingAcntInvAmountMap = new Map<string, Decimal>();
        Map<string, Decimal> billingAcntCredNteAmountMap = new Map<string, Decimal>();
        list<QTB_PurchaseOrder__c> purchaseOrderToUpdate = new list<QTB_PurchaseOrder__c>();
        try
        {
            system.debug('11+++');
            for (QTB_PurchaseOrder__c po: scope) {
                
                //po.QTB_PO_Balance_Amount__c = (po.QTB_Amount__c -integer.valueOf( po.QTB_PO_Utilized_Amount__c)); 
                //Gopi needs to change the reference
               /* billingAcntPurchaseOrdMap.put(po.QTB_Billing_Account__c, po);
                
                //Map account with list of Purchase Order
                if(acctPOMap.containsKey(po.QTB_Billing_Account__c)){
                    acctPOMap.get(po.QTB_Billing_Account__c).add(po);
                }
                else{
                    acctPOMap.put(po.QTB_Billing_Account__c, new List<QTB_PurchaseOrder__c>{po});
                } */
            }
            system.debug('22+++'+billingAcntPurchaseOrdMap);
            system.debug('33+++'+acctPOMap);
            //Logic for PO balance re-calculation in case of PO Amount, Start/End date changes
            Map<Id, List<blng__Invoice__c>> acctInvoiceMap = new Map<Id, List<blng__Invoice__c>>();
            Map<Id, List<blng__CreditNote__c>> acctCreditNoteMap = new Map<Id, List<blng__CreditNote__c>>();
            //Check whether PO balance re-calculation is required Gitlab #3772
           /* if (purchaseOrderIds.size() > 0) {
                for(blng__Invoice__c inv : [Select Id, blng__TotalAmount__c, blng__Account__c,blng__InvoicePostedDate__c from blng__Invoice__c 
                                            where blng__Account__c IN: billingAcntPurchaseOrdMap.keySet()
                                            AND blng__InvoiceStatus__c =: STATUS_POSTED ])
                {
                    if(acctInvoiceMap.containsKey(inv.blng__Account__c)){
                        acctInvoiceMap.get(inv.blng__Account__c).add(inv);
                    }
                    else{
                        acctInvoiceMap.put(inv.blng__Account__c, new List<blng__Invoice__c>{inv});
                    }                
                }
                //Fetch all eligible credit notes                       
                
                for(blng__CreditNote__c creditNote : [Select id, blng__TotalAmount__c, blng__Account__c,QTB_CreditNote_Posted_Date__c from blng__CreditNote__c
                                                      where blng__Account__c IN: billingAcntPurchaseOrdMap.keySet()
                                                      AND blng__Status__c =: STATUS_POSTED ])
                {
                    if(acctCreditNoteMap.containsKey(creditNote.blng__Account__c)){
                        acctCreditNoteMap.get(creditNote.blng__Account__c).add(creditNote);
                    }
                    else{
                        acctCreditNoteMap.put(creditNote.blng__Account__c, new List<blng__CreditNote__c>{creditNote});
                    } 
                }
                
                system.debug('44+++'+acctCreditNoteMap);
                system.debug('55+++'+acctInvoiceMap);
                // 1 Account --> can have multiple PO
                // 1 Account --> can have multiple Invoice
                // 1 Account --> can have multiple Creditnotes
                
                //Set<blng__Invoice__c> invoiceList = new Set<blng__Invoice__c>();
                //Set<blng__CreditNote__c> creditNoteList = new Set<blng__CreditNote__c>();
                set<string> checkDuplicate = new set<string>();
                if(!acctPOMap.isEmpty()){
                    for(Id accountId : acctPOMap.keySet() ){//looping on accountIds
                        for(QTB_PurchaseOrder__c po : acctPOMap.get(accountId)){//based on accountId fetching all related Purchase Orders PO
                            if(!acctInvoiceMap.isEmpty() && acctInvoiceMap.containsKey(accountId)){
                                for(blng__Invoice__c inv : acctInvoiceMap.get(accountId)){//based on accountId fetching all related invoices
                                    // blng__InvoicePostedDate__c >=: po.QTB_Start_Date__c AND blng__InvoicePostedDate__c <=: po.QTB_End_Date__c
                                    if(inv.blng__InvoicePostedDate__c >= po.QTB_Start_Date__c && inv.blng__InvoicePostedDate__c <=po.QTB_End_Date__c ){
                                        //Not Allow Duplicate Account Id and Invoice Id combination.
                                        if(!checkDuplicate.contains(string.valueOf(accountId)+string.valueOf(inv.id))){
                                            if (billingAcntInvAmountMap.containskey(string.valueOf(inv.blng__Account__c)+po.id)) {
                                                Decimal totalInvoiceAmount = billingAcntInvAmountMap.get(string.valueOf(inv.blng__Account__c)+po.id) + inv.blng__TotalAmount__c;
                                                billingAcntInvAmountMap.put(string.valueOf(inv.blng__Account__c)+po.id, totalInvoiceAmount);
                                            } else {
                                                billingAcntInvAmountMap.put(string.valueOf(inv.blng__Account__c)+po.id, inv.blng__TotalAmount__c);
                                            }
                                        }
                                        checkDuplicate.add(string.valueOf(accountId)+inv.id);
                                        //invoiceList.add(inv);
                                    }
                                }   
                            }
                            
                            if(!acctCreditNoteMap.isEmpty() && acctCreditNoteMap.containsKey(accountId)){
                                for(blng__CreditNote__c crd : acctCreditNoteMap.get(accountId) ){//based on accountId fetching all related creditNotes
                                    //QTB_CreditNote_Posted_Date__c >=: po.QTB_Start_Date__c AND QTB_CreditNote_Posted_Date__c <=: po.QTB_End_Date__c
                                    if(crd.QTB_CreditNote_Posted_Date__c >= po.QTB_Start_Date__c && crd.QTB_CreditNote_Posted_Date__c <=po.QTB_End_Date__c ){
                                        //Logic to update the billingAcntCredNteAmountMap
                                        //Not Allow Duplicate Account Id and Invoice Id combination.
                                        if(!checkDuplicate.contains(string.valueOf(accountId)+crd.id)){
                                            if (billingAcntCredNteAmountMap.containskey(string.valueOf(crd.blng__Account__c)+po.id)) {
                                                Decimal totalCreditNoteAmount = billingAcntCredNteAmountMap.get(string.valueOf(crd.blng__Account__c)+po.id) + crd.blng__TotalAmount__c;
                                                billingAcntCredNteAmountMap.put(string.valueOf(crd.blng__Account__c)+po.id, totalCreditNoteAmount);
                                            } else {
                                                billingAcntCredNteAmountMap.put(string.valueOf(crd.blng__Account__c)+po.id, crd.blng__TotalAmount__c);
                                            }
                                        }
                                        checkDuplicate.add(string.valueOf(accountId)+crd.id);   
                                        //creditNoteList.add(crd);
                                    }
                                }
                            }
                        }   
                    } 
                }
            }
            
            
            System.debug('billingAcntCredNteAmountMap>>'+billingAcntCredNteAmountMap);
            System.debug('billingAcntInvAmountMap>>'+billingAcntInvAmountMap);
            //Logic to check whether to update po balance
           /* if (purchaseOrderIds.size() <= 0)// Only from Invoice/ Credit Note Trigger
            {
                System.debug('INSIDDDDD>>');
                //PO Balance re-calculation
                list<blng__Invoice__c> invoiceList1 = [Select Id, blng__TotalAmount__c, blng__Account__c from blng__Invoice__c
                                                       where blng__Account__c IN: billingAcntPurchaseOrdMap.keyset()
                                                       AND blng__InvoiceStatus__c =: STATUS_POSTED
                                                       AND ID IN: invoiceIds];
                
                //Logic to update the billingAcntInvAmountMap
                for (blng__Invoice__c invoice: invoiceList1) {
                    if (billingAcntInvAmountMap.containskey(string.valueOf(invoice.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(invoice.blng__Account__c)).id)) {
                        Decimal totalInvoiceAmount = billingAcntInvAmountMap.get(string.valueOf(invoice.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(invoice.blng__Account__c)).id) + invoice.blng__TotalAmount__c;
                        billingAcntInvAmountMap.put(string.valueOf(invoice.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(invoice.blng__Account__c)).id, totalInvoiceAmount);
                    } else {
                        billingAcntInvAmountMap.put(string.valueOf(invoice.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(invoice.blng__Account__c)).id, invoice.blng__TotalAmount__c);
                    }
                }
                
                //Fetch all eligible credit notes
                list<blng__CreditNote__c> creditNoteList1 = [Select id, blng__TotalAmount__c, blng__Account__c from blng__CreditNote__c
                                                             where blng__Account__c IN: billingAcntPurchaseOrdMap.keyset()
                                                             AND blng__Status__c =: STATUS_POSTED
                                                             AND ID IN: creditNoteIds];
                
                //Logic to update the billingAcntCredNteAmountMap
                for (blng__CreditNote__c creditNote: creditNoteList1) {
                    if (billingAcntCredNteAmountMap.containskey(string.valueOf(creditNote.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(creditNote.blng__Account__c)).id)) {
                        Decimal totalCreditNoteAmount = billingAcntCredNteAmountMap.get(string.valueOf(creditNote.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(creditNote.blng__Account__c)).id) + creditNote.blng__TotalAmount__c;
                        billingAcntCredNteAmountMap.put(string.valueOf(creditNote.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(creditNote.blng__Account__c)).id, totalCreditNoteAmount);
                    } else {
                        billingAcntCredNteAmountMap.put(string.valueOf(creditNote.blng__Account__c)+billingAcntPurchaseOrdMap.get(string.valueOf(creditNote.blng__Account__c)).id, creditNote.blng__TotalAmount__c);
                    }
                }
            }
            
            //Logic to update the Purchase Order Balance Amount after Posting Invoice's/Credit Note's
            for (QTB_PurchaseOrder__c po: scope) {
                system.debug('11##'+po);
                Boolean isUpdateRequired = false;
                //Reset the purchase order balance to null for po balance re-calculate scenario Gitlab #3772
                if (purchaseOrderIds.size() > 0) {// Only from PO Trigger
                    po.QTB_PO_Balance_Amount__c = po.QTB_Amount__c;
                    isUpdateRequired = true;
                }
                
                Decimal newPoBalanceAmount = (po.QTB_PO_Balance_Amount__c != null) ? po.QTB_PO_Balance_Amount__c : po.QTB_Amount__c;
                system.debug('22##'+newPoBalanceAmount);
                //Logic to subtract the Invoice Amount from the PO Amount to calculate the PO Balance
                if (billingAcntInvAmountMap.containskey(string.valueOf(po.QTB_Billing_Account__c)+po.id)) {
                    newPoBalanceAmount = newPoBalanceAmount  - (billingAcntInvAmountMap.get(string.valueOf(po.QTB_Billing_Account__c)+po.id));
                    isUpdateRequired = true;
                    system.debug('33##'+newPoBalanceAmount);
                }
                
                //Logic to add the Credit Note Amount to PO Amount to calculate the PO Balance
                if (billingAcntCredNteAmountMap.containskey(string.valueOf(po.QTB_Billing_Account__c)+po.id)) {
                    newPoBalanceAmount = newPoBalanceAmount + (billingAcntCredNteAmountMap.get(string.valueOf(po.QTB_Billing_Account__c)+po.id));
                    isUpdateRequired = true;
                    system.debug('44##'+newPoBalanceAmount);
                }
                
                if (isUpdateRequired == true) {
                    po.QTB_PO_Balance_Amount__c = newPoBalanceAmount;
                    if(newPoBalanceAmount <= 0 && po.QTB_Date_Of_100_Utilization__c == null){
                        po.QTB_Date_Of_100_Utilization__c = system.today();
                    }
                    purchaseOrderToUpdate.add(po);
                }
            }
            system.debug('88+++'+purchaseOrderToUpdate);
            //Update the calculated PO balance
            if (purchaseOrderToUpdate.size() > 0) {
                System.debug('Update>>>'+purchaseOrderToUpdate.size());
                Database.saveresult[] purchaseOrderToUpdateResult = Database.update(purchaseOrderToUpdate, true);
                for(Integer i=0; i < purchaseOrderToUpdateResult.size(); i++) 
                {
                    if(i==(purchaseOrderToUpdateResult.size())-1 && purchaseOrderToUpdateResult.get(i).isSuccess())
                    {
                        finalPOList.add(purchaseOrderToUpdateResult.get(i).getId());
                    }
                }
            }
            //Re-Calculate the PO Balance when amount changes:
             /*for (QTB_PurchaseOrder__c po: scope) {
                 if (purchaseOrderIds.size() > 0) {
                  po.QTB_PO_Balance_Amount__c = (po.QTB_Amount__c -integer.valueOf( po.QTB_PO_Utilized_Amount__c));  
                 }
                 
             }*/
        }
        catch (Exception e)
        {
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_CalculatePOBalanceBatch'); 
        }
    }
    
    /*********************************************************************************************************
* Method Name: finish
* Parameters: Database.BatchableContext
* Return Type: void
* Requirement: Gitlab #1327 
* Description: finish method
**********************************************************************************************************/
    public void finish (Database.BatchableContext bc)
    {
        //Logic for the finish method // commenting as QTB_sendPONotificationBatch is called in Invoice helper class as part of #22030 ticket
        /*if(finalPOList != null && finalPOList.size() > 0){
            QTB_sendPONotificationBatch spn = new QTB_sendPONotificationBatch(finalPOList);
            ID batchProcessId = Database.executeBatch(spn, Integer.valueOf(system.label.QTB_PO_Notification_Batch_Size));
        }*/
    }
}