/* UPDATE Case Action Owner and Case Status for case action record
   Created Date: June 09,2014
   Case # :- 02411596
   Author: Venkateswarlu Avula
   Description: 1)The purpose of this trigger is to update case owner based on Case Action Assigned To field.
                2) Also it will update the Case's Contract status field to "Resubmitted", once Case Action's status
                   changed to "Resubmitted". Also, it will update Case's Sales Resubmission Date, 2nd Sales Resubmission 
                   Date and Sales Resubmit Comments.
    ===========================================================================
    Modified by:
    ===========================================================================
    Sagar Nagvekar on 12th November 2025 - Gitlab #34121
    Added "before insert" in trigger and isInsert path.
    The isInsert part queries for the BusinessHours for NA NCSP
    and calculates values for the follow up dates for notifying the 
    Case Action owner that the corresponding case has been Rejected
    by changing the Contract Status on the case record to "Rejected".
    The flow "NCSP Case Action Auto Follow up" does the notifying work
    by sending Chatter post on the case record.
*/

trigger IMNA_updateCaseActionData on Case_Action__c (before insert, before update) 
{
    public String updateCaseowner = null;
    public String updateCaseData = null;
    public String assignFollowUpDates = null;
    
	// Gitlab #34121 Starts
	
    if(Trigger.isInsert && Trigger.isBefore)
    {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        for(Trigger_Activation_Settings__c cs : customsettings)
        {
            if(cs.Object__c == 'Case Action')
            {
                if(cs.Trigger__c == 'assignFollowUpDates') 
                {
                    assignFollowUpDates = cs.Value__c;  
                }              
            }
        }
        
        if(assignFollowUpDates == 'True')
        {
            String businessHoursIdStr = System.Label.BusinessHoursId;
            Id businessHoursId = Id.valueOf(businessHoursIdStr);
            
            String ncspRecordTypeIDs = System.Label.NCSPrecordTypeIDs;
            List<String> individualNcspRecordTypeIDs = new List<String>();
            individualNcspRecordTypeIDs = ncspRecordTypeIDs.split(',');
                    
            Set<Id> caseIdSet = new Set<Id>();
            for(Case_Action__c caseActionObj : trigger.new)
            {
                caseIdSet.add(caseActionObj.Case__c);
            }
            
            List<Case> caseList = [select id, caseNumber, recordTypeId, Country__c
                                        from case where id IN :caseIdSet];
            
            // Store Case ID, Case record in this map only if Country__c
            // on the case is USA or Canada
            Map<Id,Case> mapCaseIdCaseRecord = new Map<Id,Case>();
            
            // Store Case ID, Case recordTypeId in this map
            Map<Id,String> mapCaseIdRecordTypeId = new Map<Id,String>();
            for(Case caseObj : caseList)
            {
                mapCaseIdRecordTypeId.put(caseObj.Id, caseObj.recordTypeId);
                
                if(caseObj.Country__c == 'USA' || caseObj.Country__c == 'Canada')
                {
                    mapCaseIdCaseRecord.put(caseObj.Id, caseObj);
                }
            }
            
            for(Case_Action__c caseActionObj : trigger.new)
            {
                if(caseActionObj.Status__c == 'Rejected')
                {
                    //Proceed only if Country__c on the case is USA or Canada
                    if(mapCaseIdCaseRecord.containsKey(caseActionObj.Case__c))
                    {
                        if(mapCaseIdRecordTypeId.containsKey(caseActionObj.Case__c))
                        {
                            String retrievedRecordTypeId = mapCaseIdRecordTypeId.get(caseActionObj.Case__c);
                            
                            // Assign follow-up dates on Case Action only for NCSP record types
                            if(individualNcspRecordTypeIDs.contains(retrievedRecordTypeId))
                            {
                                caseActionObj.X1st_Follow_up_Date1__c =
                                    GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(businessHoursId, 1);
                                
                                caseActionObj.X2nd_Follow_up_Date1__c =
                                    GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(businessHoursId, 3);
                                
                                caseActionObj.X3rd_Follow_up_Date1__c =
                                    GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(businessHoursId, 6);
                                
                                caseActionObj.X4th_Follow_up_Date1__c =
                                    GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(businessHoursId, 7);
                                
                            }
                        }
                    }
                }
            }
        }
    } 
    
    // Gitlab #34121 Ends
    
    
    else if(Trigger.isUpdate)
    {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        for(Trigger_Activation_Settings__c cs : customsettings)
        {
          if(cs.Object__c=='Case Action')
            {
              if(cs.Trigger__c == 'updateCaseowner') 
              {
                updateCaseowner = cs.Value__c;  
              }
              if(cs.Trigger__c == 'updateCaseData') 
              {
                updateCaseData = cs.Value__c;  
              }
              
            }
        }
        /*********Update Case Action Owner********/
        /*************Start*******/ 
        if(updateCaseowner=='TRUE')
        {
            List<Case_Action__c> ownrId = new List<Case_Action__c>();
            for (Case_Action__c caston : trigger.new)
            {
                if(caston.ownerId != caston.Case_Action_Assigned_To__c)
                {
                    caston.ownerId = caston.Case_Action_Assigned_To__c;
                    ownrId.add(caston);
                }
            }
        }
        /**********End*****/
        
        /********Update Case Data********/
        /********Start********/
        if(updateCaseData == 'TRUE')
        {
            if(!Validator_cls.hasAlreadyDone())
            {
                Map<Id,Case_Action__c> casActonMap = new Map<Id,Case_Action__c>();
                casActonMap = Trigger.OldMap;
                Set<Id> casID = new Set<Id>();
                List<Case> casLst = new List<Case>();
                for(Case_Action__c casActon : trigger.new)
                {
                    casID.add(casActon.Case__c);
                }
                
                List<Case> casObjLst = [Select Id,Contract_Status__c,Sales_Resubmit_Comments__c,Sales_Resubmission_Date__c,X2nd_Sales_Resubmission_Date__c from Case where Id in : casID];
                
                for(Case_Action__c casActonObj : Trigger.new)
                {
                    Case_Action__c casActnOld = new Case_Action__c();
                    casActnOld = casActonMap.get(casActonObj.Id);
                    if(casActonObj.Status__c == 'Resubmitted' && casActnOld.Status__c != 'Resubmitted')
                    {  
                        for(case cas :casObjLst)
                        {
                            if(cas.Sales_Resubmission_Date__c == null)
                            {
                                System.debug('Checking if entering into the loop-------');
                                cas.Contract_Status__c = 'Resubmitted';
                                cas.Sales_Resubmit_Comments__c = casActonObj.Resubmit_Comments__c;
                                cas.Sales_Resubmission_Date__c = System.now();              
                                casLst.add(cas);
                            }
                            else if(cas.Sales_Resubmission_Date__c != null)
                            {
                               System.debug('Checking else entering into the loop----1---');
                               cas.Contract_Status__c = 'Resubmitted';
                               cas.Sales_Resubmit_Comments__c = casActonObj.Resubmit_Comments__c;
                               cas.X2nd_Sales_Resubmission_Date__c = System.now();
                               casLst.add(cas);
                            }  
                        }
                    }
                }
                update casLst;
                Validator_cls.setAlreadyDone();
            }
        }
    }
}