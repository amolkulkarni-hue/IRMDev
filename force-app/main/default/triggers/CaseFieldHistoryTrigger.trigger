/**
     * Modified By: Vinutha Iyengar on 25-Nov-2015 
     *           --To stop trigger being fired from Email Archive batch job
     * Jitendra Mishra 26/08/2024      Commenting the entire Trigger as this functionality is no longer in use, story #25700
**/


trigger CaseFieldHistoryTrigger on Case (after update) {
  //#25700 Commenting the code starts 
   /*  
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    Boolean IsEmailArchiveBatchJob=false;
    if(system.isBatch()==true)
    {
        if(Validator_cls.isArchiveBatchJobDone())
        {
            IsEmailArchiveBatchJob=Validator_cls.isArchiveJobExecuting();
        }
        else
        {
            List<String> classIds = Label.Email_Archive_Class.split(';');
            List<AsyncapexJob> emailArchiveJob=[SELECT Id FROM AsyncapexJob WHERE ApexClassID in :classIds and Status = 'Processing'];
            if(!emailArchiveJob.isEmpty())            
            {
                Validator_cls.setArchiveJobExecuting();
                IsEmailArchiveBatchJob=true;
            }
            Validator_cls.setArchiveBatchJobDone();
        }
    }
    system.debug(LoggingLevel.INFO,'CaseFieldHistoryTrigger - emailArchiveBatchJob value is  =='+IsEmailArchiveBatchJob); 
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    
    if(Trigger.isUpdate && Trigger.isAfter && !IsEmailArchiveBatchJob)
    {   
        List<Case> casesModifiedByExternalUser = CaseFieldHistoryServices.filterCasesModifiedByExternalUser( Trigger.new );
         System.debug('Userss--' + casesModifiedByExternalUser );
        if (!casesModifiedByExternalUser.isEmpty()) {
            Map<Id, Set<String>> case2Fields = 
                CaseFieldHistoryServices.buildFieldsToCheckMap( casesModifiedByExternalUser );
                //System.debug('case2Fields --' + case2Fields );
            List<Case_Field_History__c> histories = CaseFieldHistoryServices.createCaseFieldHistories(casesModifiedByExternalUser, Trigger.oldMap, case2Fields); 
            //System.debug('Histories--' + histories);
            if (!histories.isEmpty())
                CaseFieldHistoryServices.insertFieldHistoriess(histories);
        }
    }     
*/    
 //#25700 Commenting the code End  
}