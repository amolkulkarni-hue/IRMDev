/*****************************************************************************************************
* Class: QTB_BatchForBoxSummaryUpdate
* Author: Lokesh Tewari
* Purpose: GitLab #22656 To link Box Summary record with EOM invoices
* Requirement: GitLab #22656 To link Box Summary record with EOM invoices 
* Change History: 05/05/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari      03/06/2024     GitLab #22656 To link Box Summary record with EOM invoices
*******************************************************************************************************/

Global class QTB_BatchForBoxSummaryUpdate implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    
    Private static final String CLASSNAME = QTB_BatchForBoxSummaryUpdate.class.getName();
    public static boolean throwExplicitException = false;
    // Map to store Custom Invoice Number and Invoice 
    public Map<String,blng__Invoice__c> mapOfCustmNumberAndInvc = new Map<String,blng__Invoice__c>();  
    // Map to store Service period as a key along with list of Period start and end date  
    public Map<String,List<Date>> mapServicePeriod = new Map<String,List<Date>>();
    // Set to store service period
    public Set<String> servicePeriod = new Set<String>();
    // Map to store invoice id and Service period of Usage
    Map<id,String> mapInvcIdServicePeriod = new Map<id,String>();
    
    // Constructor to receive Map of Custom Invc Number in Invoice record and Set of Service Period
    global QTB_BatchForBoxSummaryUpdate(Map<String,blng__Invoice__c> mapOfCustmNumberInvc,Map<id,String> mapSrvcPeriod){
        try{
            if( QTB_BatchForBoxSummaryUpdate.throwExplicitException){
                throw new NullPointerException();
            }

            if(!mapSrvcPeriod.isEmpty() && !mapOfCustmNumberInvc.isEmpty()){
                for(string servPd : mapSrvcPeriod.Values()){
                    // Set to store service Period of invoice related usage
                    servicePeriod.add(servPd);
                }
                mapInvcIdServicePeriod.putAll(mapSrvcPeriod);
                
                // Map of Custom Invc Number in Invoice record
                mapOfCustmNumberAndInvc.putAll(mapOfCustmNumberInvc);
                // List of Finance Period to get Period Start and End Date
                List<blng__FinancePeriod__C> lstFinancePeriod = [select id,name, blng__PeriodEndDate__c, blng__PeriodStartDate__c from blng__FinancePeriod__C where name=:servicePeriod];
                if(!lstFinancePeriod.isEmpty()){
                    for(blng__FinancePeriod__C fp:lstFinancePeriod){
                        List<Date> lstStartEndDate = new List<Date>();
                        lstStartEndDate.add(fp.blng__PeriodStartDate__c);
                        lstStartEndDate.add(fp.blng__PeriodEndDate__c);
    					// Map to store Service period as a key along with list of Period start and end date  
                        mapServicePeriod.put(fp.Name,lstStartEndDate);
                    }
                }
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),CLASSNAME);
        }
    }
        /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: List<QTB_Box_Summary__c>
**********************************************************************************************************/
    global List<QTB_Box_Summary__c> start(Database.BatchableContext BC){
        // List of QTB_Box_Summary__c record based on invoice service period and custom invoice number
        list<QTB_Box_Summary__c> lstBoxSummary =[select id,Name,QTB_ServicePeriod__c, QTB_Customer_Number__c,QTB_Invoice__c 
                                                 from QTB_Box_Summary__c where QTB_ServicePeriod__c In:servicePeriod and QTB_Invoice__c=Null and QTB_Customer_Number__c In:mapOfCustmNumberAndInvc.KeySet()];
        
        return lstBoxSummary;
    }
    
     /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext BC, List<QTB_Box_Summary__c> scope
Return Type: void
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<QTB_Box_Summary__c> scope){
        string errorIds = '';
        try{
            if( QTB_BatchForBoxSummaryUpdate.throwExplicitException){
                throw new NullPointerException();
            }
            if(!scope.isEmpty()){
                // List of QTB_Box_Summary__c to be updated with Invoice
                list<QTB_Box_Summary__c> lstUpdatedBoxSmr = new list<QTB_Box_Summary__c>();
                // List of finance Period start and end date in index 0 and 1  
                List<Date> lstServicePeriodDate ;
                for(QTB_Box_Summary__c boxSmr:scope){
                    errorIds +=';;'+boxSmr.id;
                    lstServicePeriodDate = new List<Date>();
                    // Map to get invoice record based on custom invoice number 
                    if(mapOfCustmNumberAndInvc.containsKey(boxSmr.QTB_Customer_Number__c)){
                        blng__Invoice__c invoice = new blng__Invoice__c ();
                        // Invoice record ahving same custom invoice number as in Box Smr record
                        invoice = mapOfCustmNumberAndInvc.get(boxSmr.QTB_Customer_Number__c);                       
                        // Check if box summary service period lies in between finance period start and end date
                        /*if(mapServicePeriod.containsKey(boxSmr.QTB_ServicePeriod__c)){
                            lstServicePeriodDate.AddAll(mapServicePeriod.get(boxSmr.QTB_ServicePeriod__c));*/
                            // Compare box summary service period lies in between Invoice Service start and end date
                            //#31583 Compare box summary service period is same as Finance Period because of change in Service dates logic
                            if(/*invoice.QTB_Service_Start_Date__c >= lstServicePeriodDate[0] && lstServicePeriodDate[1] <= invoice.QTB_Service_End_Date__c &&*/ mapInvcIdServicePeriod.get(invoice.id) == boxSmr.QTB_ServicePeriod__c){
                                boxSmr.QTB_Invoice__c = invoice.id;
                                lstUpdatedBoxSmr.add(boxSmr);  
                            }
                        //}
                    }
                } 
                // Update Box Summary Record
                if(!lstUpdatedBoxSmr.isEmpty()){
                    update lstUpdatedBoxSmr;
                    lstUpdatedBoxSmr.clear();
                }
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            System.debug('Exception message:'+e.getMessage());
            errorIds = e.getMessage()+errorIds;
            if(errorIds.length()>100000){
                errorIds = errorIds.substring(0,100000);
            }
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,e.getTypeName(),
                CLASSNAME);
        }
    }
    global void finish(Database.BatchableContext BC){
         try{
            if( QTB_BatchForBoxSummaryUpdate.throwExplicitException){
                throw new NullPointerException();
            }
         }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),CLASSNAME);
        }
    }
}