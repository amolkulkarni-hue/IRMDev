/**  
       * Name: IRM_SC_ClosedCaseEmail
       * Description: Creating a new case when email is coming with reference to existing closed case
                To restrict user from deleting Emails associated with CS Cases with Record type of IME SC Case and IME SC Case Resolved record type
       * Copyright: HCL Technologies
       * Author: Himanshu Jain
       * Modification Log: Created:6-Mar-2012
                            Modified 16-August-2012
                            Modified 16-Mar-2015 by Sandhya to add Custom Settings.

* Modified By: Vinutha Iyengar on 25-Nov-2015 
*                    --To allow Email deletion for Email Archiver Profiles
*                    --To check if Messsage sent date is older than 7 days before creating a case, so that while restoring it doesnot create anew case

* Modified By: Gopinandan Biswal on 23-Jun-2016
*                    --Reference case #05332425 
*                    --To check the size of Description field which is too large - Email to Case
*                    --To check if the description's character is more than 32000, truncate it up to 31900 
*                       & added a text '*** Character Limit reached on case description - review email message for full text ***'. 

* Modified By: Vinutha Iyengar on 23-Aug-2016
*                    -- Escape the string to unicode before trimmimg the description
.      *
       * Modified By: Simranjit Kaur on 15-June-2022 ************Functionality shifted to flow : Case Incoming Email Message - After Insert Flow****** Refer GitLab #16276
       *                    -- GitLab #8793
       *                    -- When Order cases are closed and we receive an new email related to this case we want:
       *                    -- The email to create a new case and not get associated to the old case
       *                    -- The incoming email (and any attachments) to be associated to the new case
       *                    -- The new case fields to be based on the original case
       *                    -- The new case to be linked to the original case as a 'child case' - so that there is a parent-child case relationship
       *
       * Modified by: Muni Yasaswini Papani on 10-Feb-2023
       *                    -- Gitlab #13413
       *                    -- When a case with 'NAS General Support Case' record type and Type 'Destruction' is closed and a new mail is received on the same case:
       *                    -- The email should create a new case and not get associated to the old case
       *                    -- The incoming email (and any attachments) to be associated to the new case
       *                    -- The new case fields to be based on the original case
       *                    -- The new case to be linked to the original case as a 'child case' - so that there is a parent-child case relationship
       * Modified By: Simranjit Kaur on 17-May-2023 Refer GitLab #17304
       *                    -- GitLab #15706
       *                    -- When Orders cases are closed and we receive a new email related to this case we want to create a new Global Service Case when the closed case was switched from Global Service Case to Global Orders
       *                    -- For Global Orders scenarios will be:
       *                    -- Check if there is no switch then create a Global Orders case.
       *                    -- Check if there is latest switch from Global Service Case then create a Global Service Case case.
       *                    -- Check if there is latest switch from other than Global Service Case then create a Global Orders case.
       * Modified By: Simranjit Kaur on 9-Sep-2023 Refer GitLab #17304
       *                    -- GitLab #17304
       *                    -- When Orders cases are closed and we receive a new email related to this case we want to create a new Global Service Case when the closed case was switched from Global Service Case to Global Orders
       *                    -- and when Global Service Case cases are closed and we receive a new email related to this case we want to create a new Global Service Case and also send new child case email notification 
       *                    -- For Global Orders scenarios will be:
       *                    -- Check if there is no switch then create a Global Orders case.
       *                    -- Check if there is latest switch from Global Service Case then create a Global Service Case case and send email notification.
       *                    -- Check if there is latest switch from other than Global Service Case then create a Global Orders case.
       *Modified By: Simranjit Kaur on 11-Sep-2023 Refer GitLab #18162
       *                    -- GitLab #18162
       *                    -- Added new child case Email Notifications for Global Orders Cases.
       *Modified By: Simranjit Kaur on 30-Oct-2023 Refer GitLab #19174
       *                    -- GitLab #19174
       *                    -- Child IME SC Case & NAS General Support Cases to Route to Indexing Queue for Case origin not used in Global service case
       * Modified By: Simranjit Kaur on 5-Dec-2023 Refer GitLab #20010
       *           -- Updated for New Child Case Email notifications to skip Email Notifications for Case Origins mentioned as true in Disable Notification field in GSC Metadata. - GitLab #20010
	   * Modified By: Simranjit Kaur on 21-Nov-2024 Refer GitLab #27569
       *           -- Updated for new record type "CAC Executive Escalations" to create new child case when case is closed for more than 14 days and send an email notification - GitLab #27569
       * Modified By: Simranjit Kaur on 27-Feb-2025 Refer GitLab #29454
       *            -- Created Custom Label for Case Reopen Window and utilizing that in trigger.
       * Modified By: Simranjit Kaur on 03-April-2025 Refer GitLab #29990
	   * 			-- Removed Case-reopened/child case functionality for Global Service Cases in "Cancelled" Status but create new case.
**/
trigger IRM_SC_ClosedCaseEmail on EmailMessage (before insert, before delete) { 
    Set<ID> emailId = new Set<ID>();
    List<case> allNewCases = new List<Case>();
    Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
    Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('IME SC Case').getRecordTypeId();
    Id imeCaseResolvedRecordType = caseRecordTypeIdMap.get('IME SC Case Resolved').getRecordTypeId();
    Id globalOrdersCaseRecordTypeID = caseRecordTypeIdMap.get('Global Orders').getRecordTypeId();
    Id globalServiceCaseRecordTypeID = caseRecordTypeIdMap.get('Global Service Case').getRecordTypeId();
    Id cacExecutiveEscalationsRecordTypeID = caseRecordTypeIdMap.get('CAC Executive Escalations').getRecordTypeId();
    Id nasGeneralSupportCaseRecordTypeID = caseRecordTypeIdMap.get('NAS General Support Case').getRecordTypeId();
    String NASGeneralCountryValue = System.Label.NAS_General_Country_Value;
    Integer CaseReopenWindowInDays = Integer.ValueOf(System.Label.Case_Reopen_Window_in_Days);
    AssignmentRule assignmentRule;
    boolean allowEmailDeletion = false;
    String GSCStatusCancelled = System.Label.GSC_Status_Cancelled;
    public String deleteEmail = null;
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings)
    {
      if(cs.Object__c=='Case')
        {
          if(cs.Trigger__c == 'IRM_SC_ClosedCaseEmail') 
          {
              deleteEmail= cs.Value__c;  
          }
        }
    }
    
    if(Trigger.IsInsert)
    { 
    
      for(EmailMessage emailParentId : Trigger.new)
        emailID.add(emailParentId.ParentID);
    // checking null value for fetched set of email message parent id
    List<case> emailCase;
    if(emailId != null)
    {
        // fetching all the cases which is related to email messages.
        emailCase = [select id, status, priority, RecordTypeId, Origin, Country__c,Order_Team__c,NAS_Order_Number__c, Cut_Off__c,IME_SC_Sub_Category__c, IME_SC_Category__c,
                                    contactID, IME_SC_Request_Type__c, IME_SC_Number_of_Line_Items__c,Type, ClosedDate, isClosed, accountID, IME_SC_Country__C from case where id IN :emailId]; 
    }
              // checking null value for fetched case record
        if(emailCase != NULL && emailCase.size() > 0)
        {
            //Iterating all the email messages
            for(EmailMessage emailParentId : Trigger.new)
            {         
                //Iterating all the parent case Record
                for(case caseRelatedToEmail : emailCase)
                {
                    // matching case id with email message parent Id
                    if(caseRelatedToEmail.id == emailParentId.parentID)
                    {
                        //Checking whether the case record have status close
                          if((caseRelatedToEmail.isClosed == true && emailParentId.status == '0' && emailParentId.incoming == true && (caseRelatedToEmail.RecordTypeId == imeCaseResolvedRecordType  || caseRelatedToEmail.RecordTypeId ==nasGeneralSupportCaseRecordTypeID || caseRelatedToEmail.RecordTypeId == imeCaseRecordTypeID))
                             ||(caseRelatedToEmail.isClosed == true && emailParentId.status == '0' && ((caseRelatedToEmail.RecordTypeId ==globalServiceCaseRecordTypeID && caseRelatedToEmail.status != GSCStatusCancelled) || caseRelatedToEmail.RecordTypeId == cacExecutiveEscalationsRecordTypeID )  && caseRelatedToEmail.closedDate<System.Today().addDays(-CaseReopenWindowInDays) && emailParentId.incoming == true )
                             ||(caseRelatedToEmail.isClosed == true && emailParentId.status == '0' && caseRelatedToEmail.RecordTypeId ==globalOrdersCaseRecordTypeID && emailParentId.incoming == true )
                             ||(caseRelatedToEmail.isClosed == true && caseRelatedToEmail.status == GSCStatusCancelled && caseRelatedToEmail.RecordTypeId ==globalServiceCaseRecordTypeID && emailParentId.status == '0' && emailParentId.incoming == true))                        
                          {
                            //Condition to check if Message is older than 7 days, which happens in Email Restore functioanlity
                            if(emailParentId.MessageDate > (System.today().addDays(-7)))
                            {
                                // Creating new case records if email message is associated with closed case
                                Case newCase = new Case();
                                newCase.status = 'New';
                                newcase.SuppliedEmail = emailParentId.fromAddress;
                                newcase.subject = emailParentId.Subject;
                                newCase.origin = caseRelatedToEmail.origin;
                                newcase.Priority = 'Medium';                        
                                //newcase.Description = emailParentID.TextBody;
                                //check length of String
                                system.debug('emailParentID.TextBody.length()=='+emailParentID.TextBody.length());
                                string emailBody = emailParentID.TextBody.escapeUnicode();
                                string caseDescription = emailBody.length() > 32000 ? emailBody.subString(0,31900)+'\r\n'+'*** Character Limit reached on case description - review email message for full text ***' : emailBody;
                                system.debug('caseDescription =='+caseDescription);
                                newcase.Description = caseDescription.unescapeUnicode();
                                if(caseRelatedToEmail.RecordTypeId ==globalServiceCaseRecordTypeID && caseRelatedToEmail.Status == GSCStatusCancelled)
                                { //Should not update Parent Id of case
                                }
                                else{
                                    newCase.ParentId = caseRelatedToEmail.ID;
                                }
                                newCase.origin = caseRelatedToEmail.Origin;
                                newCase.country__c = caseRelatedToEmail.Country__c;
                                newCase.contactID = caseRelatedToEmail.contactID;
                                if(caseRelatedToEmail.RecordTypeId ==globalOrdersCaseRecordTypeID)
                                {
                                        //Check the Case History of the Parent Case and see if there is latest switch from Global Service Case to Global Orders, then create a new Global Service Case else it should create new Global Orders cases only.
                                        CaseHistory[] parentCaseHistory = [select OldValue, newvalue from CaseHistory where caseid=:caseRelatedToEmail.ID and field ='RecordType' order by CreatedDate desc limit 1];
                                        if(parentCaseHistory.size()>0 && ((parentCaseHistory[0].OldValue=='Global Service Case' && parentCaseHistory[0].newValue=='Global Orders')||(parentCaseHistory[0].OldValue==globalServiceCaseRecordTypeID && parentCaseHistory[0].newValue==globalOrdersCaseRecordTypeID )) ) 
                                        {
                                            //fetch metadata for Global Service Cases
                                            GSC_Case_Country_Closure_Email__mdt[] metadataGSC = [select GSC_Indexing_Queue_Developer_Name__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:caseRelatedToEmail.origin LIMIT 1]; 
                                            //fetch group id
                                            if(metadataGSC.size()>0){
                                                Group[] groupGSC = [select id from group where DeveloperName =:metadataGSC[0].GSC_Indexing_Queue_Developer_Name__c ];
                                                  if(metadataGSC.size()>0 && groupGSC.size()>0)
                                                    {   newCase.ownerid = groupGSC[0].id;
                                                    }
                                            }
                                            else{
                                            metadataGSC = [select GSC_Indexing_Queue_Developer_Name__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__C =:caseRelatedToEmail.IME_SC_Country__C and Default__c=:true LIMIT 1]; 
                                                if(metadataGSC.size()>0){
                                                Group[] groupGSC = [select id from group where DeveloperName =:metadataGSC[0].GSC_Indexing_Queue_Developer_Name__c ];
                                                  if(metadataGSC.size()>0 && groupGSC.size()>0)
                                                    {   newCase.ownerid = groupGSC[0].id;
                                                    }
                                                }
                                            }
                                            newCase.recordTypeID = globalServiceCaseRecordTypeID;
                                            newCase.accountID = caseRelatedToEmail.accountID;
                                            newCase.IME_SC_Country__C = caseRelatedToEmail.IME_SC_Country__C;
                                        }
                                        else{
                                            newCase.recordTypeID = globalOrdersCaseRecordTypeID;
                                        }  
                                }
                                else if(caseRelatedToEmail.RecordTypeId ==globalServiceCaseRecordTypeID||caseRelatedToEmail.RecordTypeId==nasGeneralSupportCaseRecordTypeID||caseRelatedToEmail.RecordTypeId == imeCaseResolvedRecordType || caseRelatedToEmail.RecordTypeId == imeCaseRecordTypeID)
                                {           
                                            //fetch metadata for Global Service Cases
                                            GSC_Case_Country_Closure_Email__mdt[] metadataGSC = [select GSC_Indexing_Queue_Developer_Name__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:caseRelatedToEmail.origin LIMIT 1]; 
                                            //fetch group id
                                            if(metadataGSC.size()>0){
                                                Group[] groupGSC = [select id from group where DeveloperName =:metadataGSC[0].GSC_Indexing_Queue_Developer_Name__c ];
                                                  if(metadataGSC.size()>0 && groupGSC.size()>0)
                                                    {   newCase.ownerid = groupGSC[0].id;
                                                    }
                                            }
                                            else if(caseRelatedToEmail.RecordTypeId==nasGeneralSupportCaseRecordTypeID)
                                            {
                                                metadataGSC = [select GSC_Indexing_Queue_Developer_Name__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__C =:NASGeneralCountryValue and Default__c=:true LIMIT 1]; 
                                                if(metadataGSC.size()>0){
                                                Group[] groupGSC = [select id from group where DeveloperName =:metadataGSC[0].GSC_Indexing_Queue_Developer_Name__c ];
                                                  if(metadataGSC.size()>0 && groupGSC.size()>0)
                                                    {   newCase.ownerid = groupGSC[0].id;
                                                    }
                                                }                                                                                           
                                            }
                                            else{
                                            metadataGSC = [select GSC_Indexing_Queue_Developer_Name__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__C =:caseRelatedToEmail.IME_SC_Country__C and Default__c=:true LIMIT 1]; 
                                                if(metadataGSC.size()>0){
                                                Group[] groupGSC = [select id from group where DeveloperName =:metadataGSC[0].GSC_Indexing_Queue_Developer_Name__c ];
                                                  if(metadataGSC.size()>0 && groupGSC.size()>0)
                                                    {   newCase.ownerid = groupGSC[0].id;
                                                    }
                                                }
                                            }
                                            newCase.recordTypeID = globalServiceCaseRecordTypeID;
                                            newCase.accountID = caseRelatedToEmail.accountID;
                                            if(caseRelatedToEmail.RecordTypeId ==nasGeneralSupportCaseRecordTypeID){
                                                newCase.IME_SC_Country__C = NASGeneralCountryValue;}
                                            else
                                            {   newCase.IME_SC_Country__C = caseRelatedToEmail.IME_SC_Country__C;}
                                }
                                //Added functionality for record type "CAC Executive Escalations" start. For ref, #27569 on Gitlab
                                else if(caseRelatedToEmail.RecordTypeId ==cacExecutiveEscalationsRecordTypeID)
                                {
                                    newCase.ownerid = System.Label.CAC_Queue_Id;
                                    newCase.recordTypeID = cacExecutiveEscalationsRecordTypeID;
                                    newCase.accountID = caseRelatedToEmail.accountID;
                                    newCase.IME_SC_Country__C = caseRelatedToEmail.IME_SC_Country__C;
                                }
                                //Added functionality for record type "CAC Executive Escalations" end.
                                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                                //dmlOpts.assignmentRuleHeader.assignmentRuleId= assignmentRule.id;
                                dmlOpts.assignmentRuleHeader.useDefaultRule = true;        
                                dmlOpts.EmailHeader.triggerUserEmail = true;
                                newCase.setOptions(dmlOpts); 
                                allNewCases.add(newCase);
                            }
                        }
                        
                    }
                }   
            }
             // Inserting new case records for the email messages which are associated with closed case
            List<Database.saveResult> caseInsertedResult = Database.Insert(allNewCases);
            Set<ID> setInsertedCaseID = new Set<ID>();
            // taking all the inserted records id in a set
            for(Database.SaveResult caseID : caseInsertedResult)
            {
                setInsertedCaseID.add(caseID.getID());
                
            }
            List<case> caseInserted;
            // fetching all the inserted records
            if(setInsertedCaseID != null && !(setInsertedCaseID.isEmpty()))
                caseInserted = [Select Id, parentId,contactid, IME_SC_Country__C,Origin,Contact.email, RecordType_Name__C,RecordTypeId  from case where id In :setInsertedCaseID];
            // setting parent Id fields for all newly inserted records.
            if(caseInserted != NULL && caseInserted.size () > 0)
            {
                
                for(EmailMessage emailMessage : Trigger.new)
                {
                    
                    for(case caseRelatedToEmail : caseInserted)
                    {               
                        if(caseRelatedToEmail.parentId == emailMessage.ParentId || caseRelatedToEmail.parentId == null)
                        {
                            emailMessage.ParentId = caseRelatedToEmail.Id;
                                               
                        }
                        if(caseRelatedToEmail.RecordTypeId==globalServiceCaseRecordTypeID || caseRelatedToEmail.RecordTypeId==globalOrdersCaseRecordTypeID || caseRelatedToEmail.RecordTypeId==cacExecutiveEscalationsRecordTypeID )
                        {
                            System.debug('Email Notification Correct');
                            GSC_Case_Country_Closure_Email__mdt[] closureEmail = new GSC_Case_Country_Closure_Email__mdt[]{};
                            GSC_Case_Country_Closure_Email__mdt[] newCaseEmail = new GSC_Case_Country_Closure_Email__mdt[]{};
                            EmailTemplate[] et = new EmailTemplate[]{};
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            OrgWideEmailAddress[] owea = new OrgWideEmailAddress[]{};
                            //Added functionality for record type "CAC Executive Escalations" start. For ref, #27569 on Gitlab
                            if((caseRelatedToEmail.RecordTypeId==globalServiceCaseRecordTypeID || caseRelatedToEmail.RecordTypeId==globalOrdersCaseRecordTypeID) && caseRelatedToEmail.ParentId != null){
                                closureEmail = [Select GSC_Case_Origin__c, GSC_Country__c, GSC_New_Email_Template_Name__c, GSC_From_Address__c,Disable_Notifications__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:caseRelatedToEmail.Origin and GSC_New_Email_Template_Name__c <> null LIMIT 1];
                                if(closureEmail.size()>0 && closureEmail[0].Disable_Notifications__c == true)
                                {  return;
                                }
                                else if(closureEmail.size()==0)
                                {
                                    closureEmail =  [Select GSC_Case_Origin__c, GSC_Country__c, GSC_New_Email_Template_Name__c, GSC_From_Address__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:caseRelatedToEmail.IME_SC_Country__C and GSC_New_Email_Template_Name__c <> null and Default__c=:true LIMIT 1];
                                }
                                et = [SELECT Id FROM EmailTemplate WHERE Name =:closureEmail[0].GSC_New_Email_Template_Name__c LIMIT 1];
                                // Fetch Org Wide Email Address if sender is filled
                                    owea = [select Id from OrgWideEmailAddress where Address =:closureEmail[0].GSC_From_Address__c];
                                if(owea.size()>0){
                                mail.setOrgWideEmailAddressId(owea[0].id);
                                }
                                else{
                                mail.setReplyTo(closureEmail[0].GSC_From_Address__c);
                                }
                                if(et.size()>0){
                                    mail.setTemplateId(et[0].Id);
                                }
                                else{
                                        List<Exception_log__C> exceptionList = new List<Exception_log__C>();
                                        Exception_log__C newException = new Exception_log__C(Class_Reference__C = 'IRM_SC_ClosedCaseEmail', Error_Message__C = 'No Email Template found', Exception_Type__C ='DML', Name = 'Trigger Error while sending email', Originating_Org__C ='Core', Record_id__C=caseRelatedToEmail.id, Stack_Trace__c ='Global service Case/Global Orders/CAC Executive Escalations -New Child Case email notification - error Occurred');
                                        exceptionList.add(newException);
                                        List<Database.saveResult> exceptionInsertedResult = Database.Insert(exceptionList);
                                }
                            }
                            //Sending new email notification for new cases created from Cancelled Global Service Case
                            else if(caseRelatedToEmail.RecordTypeId==globalServiceCaseRecordTypeID && caseRelatedToEmail.ParentId == null){
                            	newCaseEmail = [Select GSC_Case_Origin__c, GSC_Country__c, GSC_New_Case_Email_Template_Name__c, GSC_From_Address__c,Disable_Notifications__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:caseRelatedToEmail.Origin and GSC_New_Case_Email_Template_Name__c <> null LIMIT 1];
                                if(newCaseEmail.size()>0 && newCaseEmail[0].Disable_Notifications__c == true)
                                {  return;
                                }
                                else if(newCaseEmail.size()==0)
                                {
                                    newCaseEmail =  [Select GSC_Case_Origin__c, GSC_Country__c, GSC_New_Case_Email_Template_Name__c, GSC_From_Address__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:caseRelatedToEmail.IME_SC_Country__C and GSC_New_Case_Email_Template_Name__c <> null and Default__c=:true LIMIT 1];
                                }
                                et = [SELECT Id FROM EmailTemplate WHERE Name =:newCaseEmail[0].GSC_New_Case_Email_Template_Name__c LIMIT 1];
                                // Fetch Org Wide Email Address if sender is filled
                                owea = [select Id from OrgWideEmailAddress where Address =:newCaseEmail[0].GSC_From_Address__c];
                                if(owea.size()>0){
                                	mail.setOrgWideEmailAddressId(owea[0].id);
                                }
                                else{
                                	mail.setReplyTo(newCaseEmail[0].GSC_From_Address__c);
                                }
                                if(et.size()>0){
                                    mail.setTemplateId(et[0].Id);
                                }
                                else{
                                        List<Exception_log__C> exceptionList = new List<Exception_log__C>();
                                        Exception_log__C newException = new Exception_log__C(Class_Reference__C = 'IRM_SC_ClosedCaseEmail', Error_Message__C = 'No Email Template found', Exception_Type__C ='DML', Name = 'Trigger Error while sending email for New case creation', Originating_Org__C ='Core', Record_id__C=caseRelatedToEmail.id, Stack_Trace__c ='Global service Case -New Case email notification - error Occurred');
                                        exceptionList.add(newException);
                                        List<Database.saveResult> exceptionInsertedResult = Database.Insert(exceptionList);
                                }
                            }
                            else if(caseRelatedToEmail.RecordTypeId==cacExecutiveEscalationsRecordTypeID ){
                                owea = [select Id from OrgWideEmailAddress where Address =:System.Label.CAC_From_Email_Address];
                                if(owea.size()>0){
                                    mail.setOrgWideEmailAddressId(owea[0].id);
                                }
                                else{
                                    mail.setReplyTo(System.Label.CAC_From_Email_Address);
                                }
                                mail.setTemplateId(System.Label.CAC_New_Child_Case_Email_Template_Id);
                            }
                            //Added functionality for record type "CAC Executive Escalations" end.
                            //mail.setSenderDisplayName(closureEmail.GSC_From_Address__c);        mail.setReplyTo(closureEmail.GSC_From_Address__c);
                                mail.setTargetObjectId(caseRelatedToEmail.contactId);
                                mail.setTreatTargetObjectAsRecipient(true);
                                mail.setWhatId(caseRelatedToEmail.id);
                                System.debug(caseRelatedToEmail.id);
                                mail.setToAddresses(new String[] { caseRelatedToEmail.Contact.email});
                                mail.setSaveAsActivity(true);
                                List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                                allmsg.add(mail);
                                try {
                                    List<Messaging.SendEmailResult> sendResults = Messaging.sendEmail(allmsg);
                                    System.debug(sendResults);
                                    return;
                                } catch (Exception e) {
                                    System.debug(e.getMessage());
                                }
                            }
                        }
                    }
                }
            }       

        } 
    if(Trigger.IsDelete)
    {
        //Allow Email deletion for Email Archiver Profiles
        Id profileId=userinfo.getProfileId();
        List<String> ProfileList = Label.Email_Archive_Profiles.split(';');
        for(integer i = 0; i < ProfileList.size(); i++)
        {
            if(ProfileList[i] == profileId){
                allowEmailDeletion = true;
                break;
            }
        }
        
       if(deleteEmail == 'TRUE'){
        for(EmailMessage emailParentId : Trigger.old)
            emailID.add(emailParentId.ParentID);
        // checking null value for fetched set of email message parent id
        List<case> emailCase;
        if(emailId != null)
        {
            // fetching all the cases which is related to email messages.
            emailCase = [select id, status, priority,RecordTypeId, Origin, Country__c,IME_SC_Sub_Category__c, IME_SC_Category__c,
                                contactID, IME_SC_Request_Type__c, IME_SC_Number_of_Line_Items__c from case where id IN :emailId];        
        }

          for(EmailMessage emailParentId : Trigger.old)
        {
             if(emailCase != NULL && emailCase.size() > 0)
             {   
                  //Iterating all the parent case Record
                  for(case caseRelatedToEmail : emailCase)
                  {
                      if(!allowEmailDeletion && emailParentId.ParentID == caseRelatedToEmail.ID && (caseRelatedToEmail.RecordTypeId == imeCaseRecordTypeID || caseRelatedToEmail.RecordTypeId == imeCaseResolvedRecordType))
                      {
                          emailParentId.adderror(System.Label.IME_SC_EmailMessage);
                      }
                  }
             }
         }  
         }  
    }
}