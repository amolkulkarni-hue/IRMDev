/****Creat Case Action****/
//Created Date: June 06,2014
//Case#       : 02411596
//Auhtor      : Venkateswarlu Avula
//Description : The purpose of this trigger is to create a new case action record, whenever the Case's contract status is 
//              changed to "Rejected".                
//              Block added to all case related triggers not to be executed if being fired from Email Archive batch job

/**
     * Modified By: Vinutha Iyengar on 25-Nov-2015 
     *           --To stop trigger being fired from Email Archive batch job
**/
//Jyoti Nayak 27/08/2024 Commenting out the entire trigger as all currently used functionalities have been implemented through the flow (NCSP_Case_After_Update_Flow) and other functionalities are no longer used  as part of user story #25723.

trigger IMNA_createCaseAction on Case (after insert, after update) 
{
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    // #25723 Commenting Code Start.
   /* Boolean IsEmailArchiveBatchJob=false;
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
    system.debug(LoggingLevel.INFO,'IMNA_createCaseAction - emailArchiveBatchJob value is  =='+IsEmailArchiveBatchJob);     
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    
    public String createCaseAction = null;
    public String updateCaseAction = null;
    List<String> cIdLst =new List<String>();
    
    if(!IsEmailArchiveBatchJob)
    {    
        
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings)
    {
      if(cs.Object__c=='Case')
        {
          if(cs.Trigger__c == 'createCaseAction') 
          {
              createCaseAction = cs.Value__c;  
          }
          if(cs.Trigger__c == 'updateCaseAction') 
          {
              updateCaseAction = cs.Value__c;  
          }
        }
    }  
    
    if(createCaseAction=='TRUE')
    {
        if(Trigger.isAfter && Trigger.isUpdate)
        {
            if(!Validator_cls.hasAlreadyDone())
            {
                System.debug('---ifenteringintoloop----');
                Map<Id,Case> casMap = new Map<Id,Case>();
                casMap = Trigger.OldMap;
                Set<Id> recordTypeIdForSKP_Department_Add_Only=new Set<Id>();
                Set<Id> recIdsForUpdateDateOnBoarderCSA=new Set<Id>();
                List<Case_Action__c> casActonLst = new List<Case_Action__c>();
                Map<String,Schema.RecordTypeInfo> DateOnBoarderMapByrecName = RecordTypeSelection.getRecordTypeIds(); //d.getRecordTypeInfosByName();
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: SKP Department Add Only')){
                      recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP: SKP Department Add Only').getRecordTypeId());
                  }
                   if(DateOnBoarderMapByrecName.containsKey('NCSP: Upsell')){
                      recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP: Upsell').getRecordTypeId());
                  }
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: New Customer Setup')){
                      recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP: New Customer Setup').getRecordTypeId());
                  }
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: DP New Customer Setup')){
                      recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP: DP New Customer Setup').getRecordTypeId());
                  }
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: SKP New Customer Setup')){
                      recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP: SKP New Customer Setup').getRecordTypeId());
                  }
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: DMS')){
                      recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP: DMS').getRecordTypeId());
                  }
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: Tech Services New Customer Setup')){
                      recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP: Tech Services New Customer Setup').getRecordTypeId());
                  }
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: Upsell')){
                      recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP: Upsell').getRecordTypeId());
                  }
                  if(DateOnBoarderMapByrecName.containsKey('NCSP: New Customer Setup')){
                      recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP: New Customer Setup').getRecordTypeId());
                  }
                
                    for (case cas : trigger.new)
                    {
                        Case casOld = new Case();
                        if(cas.Id != null)
                        {
                            if(cas.Contract_Status__c != null)
                            {
                                if(casMap.get(cas.Id)!= null)
                                {
                                     casOld = casMap.get(cas.Id);
                                }
                            }
                        
                            if(recIdsForUpdateDateOnBoarderCSA.contains(cas.RecordTypeId) && cas.Contract_Status__c == 'Rejected' && casOld.Contract_Status__c != 'Rejected')
                            {
                                if(cas.NSCP_Case_Creator_Name__c != null)
                                {
                                    System.debug('---ifenteringintoloop----');
                                    Case_Action__c casActon = new Case_Action__c();
                                        casActon.Ownerid = cas.NSCP_Case_Creator_Name__c;
                                        casActon.Case_Action_Assigned_To__c = cas.NSCP_Case_Creator_Name__c;
                                        casActon.Case__c = cas.id;
                                        casActon.Opportunity_Name__c = cas.NCSP_Opportunity__c;
                                        casActon.Rejection_Comments__c = cas.Rejection_Comments__c;
                                        casActon.Status__c = 'Rejected';
                                        casActon.Opportunity_Owner__c = cas.Sales_Person_Name_Account_Manager__c;
                                        casActon.Sales_Support_User__c = cas.Sales_Support__c;
                                        casActon.Inside_Sales_Name__c = cas.Inside_Sales_Name_Sales_factory__c;
                                        casActon.Other_Contract_Rejection_Reason__c = cas.Other_Contract_Rejection_Reason__c;
                                        casActon.Primary_Contract_Rejection_Reason__c = cas.Primary_Contract_Rejection_Reason__c;
                                        casActon.Primary_Contract_Rejection_Reason_Detail__c = cas.Primary_Contract_Rejection_Reason_Detail__c;
                                        casActon.Second_Contract_Reason_Rejection_Detail__c = cas.Second_Contract_Rejection_Reason_Detail__c;
                                        casActon.Second_Contract_Rejection_Reason__c = cas.Second_Contract_Rejection_Reason__c;
                                    casActonLst.add(casActon);
                                }
                            }
                        }
                    }
                    system.debug('casActonLst-----'+casActonLst);
                    if(!casActonLst.isEmpty())
                    {
                        Insert casActonLst;
                        Validator_cls.setAlreadyDone();
                    }
                    
                
            }
        }
    }
    system.debug('updateCaseAction-----'+updateCaseAction);
    if(updateCaseAction == 'TRUE')
    {
        if(Trigger.isAfter && Trigger.isUpdate)
        {
            system.debug('updateCaseAction-----'+updateCaseAction);
            for(Case csObj:Trigger.new)
            {
                if(csObj.Contract_Status__c == 'Accepted')
                {
                    cIdLst.add(csObj.Id);
                }
            }
            system.debug('cIdLst-----'+cIdLst);
            List<Case_Action__c> cActionLst = new List<Case_Action__c>();
            if(cIdLst != null && cIdLst.size() > 0){
                cActionLst = [Select Id, Case__c,Status__c from Case_Action__c where Case__c IN:cIdLst];
            }    
            List<Case_Action__c> caActLst = new List<Case_Action__c>();
            
            for(Case_Action__c cActObj:cActionLst)
            {
                system.debug('cActObj-----'+cActObj);
                Case_Action__c objCA = new Case_Action__c();
                if(cActObj.Status__c =='Rejected')
                {
                    system.debug('objCA.Status__c-----'+objCA.Status__c);
                    objCA.Id = cActObj.Id;
                    objCA.Status__c = 'Resolved';
                    caActLst.add(objCA);
                }
            }
            
            if(caActLst != null && caActLst.size() > 0){
                update caActLst;
            }    
        }
    }
    }*/ // #25723 Commenting Code end.
}