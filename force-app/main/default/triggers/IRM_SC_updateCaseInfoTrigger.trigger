/**  
       * Name: UpdateCaseInfo
       * Description: Fetches the queue name and updates the Queue field on the Case page layout.
                      Set country, Business Hour, Business Hour, Country code and Division 
                      Set SLA and case status flow.
                      Populate Customer Account, Customer Account email, Owner manager and manager of 
                      owner's manager email.
                      Case assignment to customer acount's account manager based on toggle country feature.
                      Send Email through generic workflow                      
       * Copyright: HCL Technologies
       * Author: Himanshu jain
       * Modification Log: Created:2-Mar-2012
                                         Modified: 12-Mar-2012
**/

trigger IRM_SC_updateCaseInfoTrigger on Case (before insert, after insert,before update, after update) 
{
    static Boolean onInsert = false;
    List<Case> newCaseList = IRM_SC_SelectRecordType.getCaseList(Trigger.New);
    Map<Id, Case> oldCaseMap;
    static Boolean bErrorFound = false;
    if(Trigger.oldMap != null)
    {
        oldCaseMap = IRM_SC_SelectRecordType.getCaseMap(Trigger.oldMap);
    }
    if(!(newCaseList.isEmpty()))
    { 
        IRM_SC_AssignCaseToAccManager updateCase = new IRM_SC_AssignCaseToAccManager();
        IRM_SC_UpdateCaseInfoClass updateCaseInfo = new IRM_SC_UpdateCaseInfoClass();
        IRM_SC_fetchUpdateQueue fetchUpdateQueue = new IRM_SC_fetchUpdateQueue();
        IRM_SC_CaclulateSLAClass calculateSLA = new IRM_SC_CaclulateSLAClass();
        if(trigger.isBefore)
        {
            IRM_SC_CaseTriggerClass caseTrigger = new IRM_SC_CaseTriggerClass();
            caseTrigger.manualCutoff(newCaseList, oldCaseMap);
            caseTrigger.selectCountryFromOrigin(newCaseList, oldCaseMap);
            fetchUpdateQueue.UpdateQueueName(newCaseList, oldCaseMap, Trigger.isUpdate);
            caseTrigger.businessHourCutOffSLA(newCaseList, oldCaseMap, Trigger.isUpdate);
            caseTrigger.customerAccount(newCaseList);
            updateCaseInfo.populateUsers(newCaseList);
            calculateSLA.setSLA(newCaseList, oldCaseMap);
            updateCaseInfo.populateRequestType(newCaseList, oldCaseMap);
            if(Trigger.isInsert)
            {
                updateCaseInfo.populateContactForEmailToCase(newCaseList);
            }
            if(trigger.isUpdate)
            {
                List<Case> oldCaseList = IRM_SC_SelectRecordType.getCaseList(Trigger.Old);
                if(onInsert == false)
                {
                    updateCaseInfo.updateStatus(newCaseList, oldCaseMap);
                }
                IRM_SC_SendEmailOnOwnerChange.sendEmail(newCaseList, oldCaseMap);
               
            }
            updateCase.assignCaseToAccManager(newCaseList); 
        }
    }
    
    //for Generic Workflows
    if(Trigger.isBefore)
    {
        List<Case> caseList= new List<Case>();
        Map<Id,Case> oldCaseOwnerMap = new Map<Id,Case>();
        //Recordtype selection
        Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
        Set<Id> recordTypeIdSet = new Set<Id>();
        Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('IME SC Case').getRecordTypeId();
        recordTypeIdSet.add(imeCaseRecordTypeID);
        Id imeCaseResolvedRecordType = caseRecordTypeIdMap.get('IME SC Case Resolved').getRecordTypeId();
        recordTypeIdSet.add(imeCaseResolvedRecordType);
        for(Case newCase: Trigger.new)
        {
            if(recordTypeIdSet != null && !recordTypeIdSet.isEmpty())
            {
                if(recordTypeIdSet.contains(newCase.RecordTypeId))
                {
                    caseList.add(newCase);
                }
            }
        }
        
        if(Trigger.isUpdate)
        {
          for(Case oldCase: Trigger.old)
          {
            if(recordTypeIdSet != null && !recordTypeIdSet.isEmpty())
              {
                  if(recordTypeIdSet.contains(oldCase.RecordTypeId))
                  {
                      oldCaseOwnerMap.put(oldCase.Id,oldCase);
                  }
              }
          }
        }
        
        if(caseList!= null && !caseList.isEmpty())
        {
            IRM_SC_SendEmail.sendEmail(caseList, oldCaseOwnerMap);
        }
    }
    //End of Generic Workflows
}