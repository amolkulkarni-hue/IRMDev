/*****************************************************************************************************
* Class       : QTB_InvoiceRunHelper
* Test Class  : QTB_InvoiceRun_Test
* Author      : IRM/Virtusa
* Purpose     : This is a helper class for all business logic related to Invoice Run object
* Requirement: 
* Change History: 07/12/2021 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Gopinandan  07/12/2021       Gitlab #857 Vertex Tax Integration
* Virtusa     12/16/2021       Gitlab #6056 Vertex Tax Integration for Posted Invoice
* Virtusa     12/12/2023       Gitlab #20256 Implement logic that checks rebill flag at the custom settings level
*******************************************************************************************************/
public with sharing class QTB_InvoiceRunHelper {
    private static final String CLASSNAME = QTB_InvoiceRunHelper.class.getName();
/***********************************************************************************************************
* Method : trigController
* Parameters: List<blng__InvoiceRun__c>, Map<Id,blng__InvoiceRun__c>,System.TriggerOperation
* Requirement : 
* Start Date : 
* Author : IRM
* Description: Generic method to handle all operations on the Invoice Run Records
**************************************************************************************************************/
    public static void trigController(List<blng__InvoiceRun__c> InvRunNewList,Map<Id,blng__InvoiceRun__c>invRunOldMap,System.TriggerOperation operationType)
    { 
        Set<ID> invRunIdSet = new Set<ID>();
        Set<ID> invSchedulerIdSet = new Set<Id>(); // #33490 - passing invoice scheduler Id to batch class to update QTB_InvoiceRunCompleted__c field
        for(blng__InvoiceRun__c invRun : InvRunNewList){
            SWITCH ON operationType {
                WHEN AFTER_UPDATE {
                    //#32284, #32285 On Invoice Run Complitation updating Mrc dates and service dates
                    if(invRunOldMap.get(invRun.Id).blng__Status__c != invRun.blng__Status__c && invRun.blng__Status__c == 'Completed' && 
                       QTB_RecursiveHandlerCheck.afterUpdateCheck_updateInvoiceMRCDates){
                       invRunIdSet.add(invRun.Id);
                       invSchedulerIdSet.add(invRun.blng__InvoiceScheduler__c);   
                    }
                }
            }
        }
        SWITCH ON operationType {
            WHEN AFTER_UPDATE {
                if(!InvRunNewList.isEmpty()) {
                    //Logic for Tax Calculation
                    vertexTaxCallOut(InvRunNewList, invRunOldMap);
                }
                //#32284, #32285 calling schedule class to update mrc dates and service dates
                if(!invRunIdSet.isEmpty() && !invSchedulerIdSet.isEmpty()) {
                    QTB_ScheduleUpdtStorageSeviceDatesOnInv.scheduleUpdateOfInvDates(invRunIdSet,invSchedulerIdSet);
                    invRunIdSet.clear();
                    invSchedulerIdSet.clear();
                }
            }
        }
    }
    
    /***********************************************************************************************************
* Method : vertexTaxCallOut
* Parameters: List<blng__InvoiceRun__c>
* Requirement : 
* Start Date : 
* Author : IRM
* Description: Do the Tax Claculation by sending the Invoice Details.
**************************************************************************************************************/
    public static void vertexTaxCallOut(List<blng__InvoiceRun__c> invoiceRunList, Map<Id, blng__InvoiceRun__c>invoiceRunOldMap){
        try{
            if(QTB_InvoiceRunTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            //Check if the Tax Setting is applied for the country or not?
            List<QTB_Tax_Integration_Setting__mdt> TaxIntegSetting = [Select id,QTB_Country__c, QTB_End_System__c, QTB_Product_Line__c FROM QTB_Tax_Integration_Setting__mdt];
            Map<string,string> countryToSystemMap = new Map<string,string>();
            Map<string, Set<ID> > taxSystemInvoiceMap = new  Map<string, Set<ID> >(); // Gitlab US#24777 (Credit/Rebill Billnow) Renamed insted of invoicRun
            List<id> invRunList = new List<id>();
            if(invoiceRunList == NULL){
                return; 
            }
            //Set to store the purchase order which needs to be re-calculated
            Set<ID> invoiceRunSet = new Set<ID>();
            
            for(blng__InvoiceRun__c ir: invoiceRunList){
                //Check if all the Invoice Run ststus is completed or not?
                if((invoiceRunOldMap.get(ir.Id).blng__Status__c <> ir.blng__Status__c && ir.blng__Status__c == 'Completed') || Test.isRunningTest()){
                    invoiceRunSet.add(ir.Id);
                }
            }
            System.debug('invoiceRunSet>>>'+invoiceRunSet);
            //Do a query to invoice Run and get the Invoice schedular 'blng__InvoiceBatches__c' and exclude if if it's related to Sierra 26
            //Keep Sierra 26's 'blng__InvoiceBatches__c'  in a custom Lable
            List<blng__InvoiceRun__c> invoiceRunOfSierraScheduler = [select id, blng__InvoiceScheduler__r.blng__InvoiceBatches__c 
                                                                     from blng__InvoiceRun__c 
                                                                     where id IN:invoiceRunSet 
                                                                     AND blng__InvoiceScheduler__r.blng__InvoiceBatches__c !=: System.Label.QTB_sierra26Label];
            Set<Id> excludeSeria26invoiceIds = (new Map<Id,SObject>(invoiceRunOfSierraScheduler )).keySet();	
            System.debug('excludeSeria26invoiceIds_invoiceRunSet>>>'+excludeSeria26invoiceIds);				
            invRunList.addAll(excludeSeria26invoiceIds);
            
            if (invRunList.size() > 0) {
                //Integration System Setting Check
                for(QTB_Tax_Integration_Setting__mdt taxInt : TaxIntegSetting){
                    if(taxInt.QTB_Country__c != null){
                        for(string countryString : taxInt.QTB_Country__c.split(';')){
                            //Infuture we can add Country and Product Line combination
                            //countryToSystemMap.put(taxInt.QTB_Product_Line__c + countryString, taxInt.QTB_End_System__c)
                            countryToSystemMap.put(countryString, taxInt.QTB_End_System__c);
                        }
                    }
                }
                //Get all the Invoice to check the Legal Conutry and based on that choose the integration system
                for(blng__Invoice__c inv : [SELECT Name, blng__Account__r.QTB_Legal_Entity_Country__c,blng__InvoiceRunCreatedBy__c 
                                            FROM blng__Invoice__c WHERE blng__InvoiceRunCreatedBy__c IN:invRunList])
                {
                    //Check if the country is present in the Custom Metadata or not
                    if(countryToSystemMap.containsKey(inv.blng__Account__r.QTB_Legal_Entity_Country__c)){
                        //Based on the country keep the end system and respective set of InvoiceRun
                        if(taxSystemInvoiceMap.containsKey(countryToSystemMap.get(inv.blng__Account__r.QTB_Legal_Entity_Country__c))){
                            taxSystemInvoiceMap.get(countryToSystemMap.get(inv.blng__Account__r.QTB_Legal_Entity_Country__c)).add(inv.id);// Gitlab US#24777 (Credit/Rebill Billnow) instead of blng__InvoiceRunCreatedBy__c passing inv.id
                        }else{
                            taxSystemInvoiceMap.put(countryToSystemMap.get(inv.blng__Account__r.QTB_Legal_Entity_Country__c), new Set<ID>{inv.id});// Gitlab US#24777 (Credit/Rebill Billnow) instead of blng__InvoiceRunCreatedBy__c passing inv.id
                        }
                    }
                }
                system.debug('taxSystemInvoiceMap--'+taxSystemInvoiceMap);
                //Callout for Vertex Batch Class
                if(taxSystemInvoiceMap.containskey('Vertex')){
                    //Gitlab #6056 Vertex Tax Integration for Posted Invoice
                    //added first 2 parameters as null, bcoz this vertex call is for draft invoice
                    Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,taxSystemInvoiceMap.get('Vertex'),null,null, true), integer.valueOf(system.label.QTB_Vertex_Callout_Batch_Size));
                }
                //Any Other Callout for other system 
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),QTB_InvoiceRunHelper.class.getname());
            throw e;
        }
    }
}