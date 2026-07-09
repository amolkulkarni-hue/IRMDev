/*****************************************************************************************************
* Class: QTB_RecordJobHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to SBQQ__RecordJob__c object
* Requirement: ALM Defect 416
* Change History: 8/26/2020
* Developer     Date           	Description
* ------------------------------------------------------------------------------------------- 
*           
*******************************************************************************************************/
public class QTB_RecordJobHelper {     
    public static final string CLASSNAME='QTB_RecordJobHelper';
    /***********************************************************************************************************
* Method :      process
* Parameters:   List<SBQQ__RecordJob__c>,Map<Id, SBQQ__RecordJob__c>,System.TriggerOperation
* Return Type : void
* Description:  This method loops over the list of records to be processed 
**************************************************************************************************************/      
    public static void process(List<SBQQ__RecordJob__c> newItems, Map<Id, SBQQ__RecordJob__c> oldItems, System.TriggerOperation operationType){
        
        List<SBQQ__RecordJob__c> recordsAI=new List<SBQQ__RecordJob__c>();
        List<SBQQ__RecordJob__c> recordsAU=new List<SBQQ__RecordJob__c>();
        
        for(SBQQ__RecordJob__c eachRecord : newItems){
            switch on operationType
            {
                when AFTER_INSERT{
                    if(eachRecord.SBQQ__JobStatus__c==QTB_Constants.RECORDJOB_FAILED && 
                       eachRecord.SBQQ__RecordId__c.contains(QTB_Constants.JOBDETAIL_STRING) ){
                           recordsAI.add(eachRecord);
                       }
                    
                }
                when AFTER_UPDATE{
                    if(eachRecord.SBQQ__JobStatus__c==QTB_Constants.RECORDJOB_FAILED && 
                       eachRecord.SBQQ__RecordId__c.contains(QTB_Constants.JOBDETAIL_STRING) &&
                       eachRecord.LastModifiedDate != oldItems.get(eachRecord.id).LastModifiedDate
                      ){
                           recordsAU.add(eachRecord);
                       }
                    
                }
                when else {}
            }
        }
        
        switch on operationType {
            when AFTER_INSERT{
                if(recordsAI.size()>0)
                    ResetRenewalCheckBoxOnContract(recordsAI);
            }
            when AFTER_UPDATE{
                if(recordsAU.size()>0)
                    ResetRenewalCheckBoxOnContract(recordsAU);
            }
            when else {}
        }
    }
    
    /***********************************************************************************************************
* Method :      ResetRenewalCheckBoxOnContract
* Parameters:   List<SBQQ__RecordJob__c>
* Return Type : void
* Requirement : ALM defect 416
* Description:  This method is used in After insert of Quote Trigger to share quote with Oppty Team with Edit Access
**************************************************************************************************************/                
    public static void resetRenewalCheckBoxOnContract(List<SBQQ__RecordJob__c> listOfRecords ){
        try{ 
            Set<Id> contractIdSet=new Set<Id>();
            List<Contract> contractsToUpdate=new List<Contract>();
            
            //Collect all Contract Ids from Record Job Object
            for(SBQQ__RecordJob__c recJob:listOfRecords){
                contractIdSet.add(Id.valueOf(recJob.SBQQ__RecordId__c.substring(0,15)));
            }
            
            //Iterate over contracts and reset RenewalQuoted and RenewalForecast checkboxes on Contract if Renewal Opportuny isn't created
            for(Contract eachContract:[SELECT id,SBQQ__RenewalOpportunity__c,SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,EndDate,SBQQ__RenewalQuoted__c,SBQQ__RenewalForecast__c FROM Contract WHERE ID IN :contractIdSet]){
						if(eachContract.SBQQ__RenewalOpportunity__c == NULL){
                            	 	eachContract.SBQQ__RenewalForecast__c=FALSE;
                            		eachContract.SBQQ__RenewalQuoted__c=FALSE;
                        }else if(eachContract.SBQQ__RenewalOpportunity__c != NULL &&
                                 	eachContract.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c == NULL){
                            	 	eachContract.SBQQ__RenewalQuoted__c=FALSE;
                        }                         
                    contractsToUpdate.add(eachContract);              
            }
            if(contractsToUpdate.size()>0)
                update contractsToUpdate;
            
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
        }        
    }
    
}