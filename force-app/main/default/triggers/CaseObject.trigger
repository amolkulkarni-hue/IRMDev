/*COMBINATION OF ALL TRIGGERS ON CASE OBJECT 
**IN REFERNCE TO CASE 00501518
**AUTHOR: RAJ GOTTIPOLU/KETAN BENEGAL/SRINIVASA RAO MANDALAPU
**DATE: 06/05/2012
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/05/07; Srinivasa Rao/Randstad; Local Market Setup Opportunities/Case 01308481; Initial release
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/05/25; Srinivasa Rao/Randstad; NCSP Case TCM Date Validation/Case 01413555; Add the two new case fields to the NCSP Date Validation trigger.
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/06/11; Srinivasa Rao/Randstad; Email-to-Case emails not creating cases/Case 01414611; Preventing the trigger not to fire for 'IME SC Case' & 'IME SC Case Resolved' Record Types.

* Modified By: Vinutha Iyengar on 25-Nov-2015 
*        --To stop trigger being fired from Email Archive batch job

* Modified By: Vinutha Iyengar on 1-Aug-2016
*        -- Optimized for resolution of case # 05419029
-- Removed SOQLs to read record types and used Schema.RecordTypeInfo method

*Modified By: Keerthi Senthilnathan on 31-Oct-2018
*        -- For case # 08337470
-- Removed type "Enterprise Opportunity" and "Enterprise Child" from the condition @Line no:2730       

*Modified By: Vinutha Iyengar on 21-Nov-2018
*        -- For case # 08065813, Stage name typo corrected
*

*Modified By Gouthami Redlapalli for case 11124616 on 24.09.2019 (BCT Consulting) @ Line 1442
---To restrict ParentCaseClosureValidService class to run only in update condition

*Modified By: Gouthami for case #10709618 on 27th July 19 
--- To allow NCSP Backdated dates

*Modified By: Revathy Saminathan for case #08408424 on 19th Nov 19 
--- Remove the Recall Custom Label

*Modified By : Rajashekar kampally for story 8833 on 19th May 2022 ---
modified lines: Removed the reference of the fields x2nd_sales_resubmission_date__c,service_location_not_found__c,date_2nd_restricted_party_screening__c
date_2nd_order_fulfillment_sent__c,date_1st_restricted_party_screening__c

*Modified By : Git Story 10373 on 05th Sep 2022 ---
modified lines: Removed the reference of the fields Date_Cancelled__c

*Mofified By: Arjun Sankar for Story # 10469 and 10364
---To include validations for new retention record types , Retention RM and Retention SH
*Modified By: Arjun Sankar for Story #11233 and #11191 on 17th Oct 2022
---Comenting code to stop deleting Email Archival records from big object Archive_Email__b

* Modified By: Simranjit Kaur on 12-Sept-2024
---Commenting out the lines as the functionalities are transferred via ValidationRules. For reference, check user story #25718 on Gitlab.


* Modified By: Simranjit Kaur on 10-Oct-2024
---Commenting out the lines as the functionalities are transferred via ValidationRules. For reference, check user story #26355 on Gitlab.
* Modified By: Simranjit Kaur on 17-Oct-2024
---Commenting out the lines as the functionalities are transferred via ValidationRules. For reference, check user story #26943 on Gitlab.
* Modified By: Simranjit Kaur on 25-Oct-2024
---Commenting out the lines as the functionalities are transferred via Flows. For reference, check user story #27066 on Gitlab.
* Modified By: Simranjit Kaur on 4-Nov-2024
---Commenting out the lines as the functionalities are transferred via Flows. For reference, check user story #27072 on Gitlab.
* Modified By: Simranjit Kaur on 15-Nov-2024
---Commenting out the lines as methods are not in use and required to improve code coverage. For reference, check user story #27422 on Gitlab.
*/

trigger CaseObject on Case (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    //validate case before save on inserts
    /*if(trigger.isInsert){
ValidationRuleExtnUtil util = new ValidationRuleExtnUtil();
util.checkRecordsValidity(trigger.new);
}*/
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
            //if(!classIds.isEmpty() && classIds.size() > 0 ){
            List<AsyncapexJob> emailArchiveJob=[SELECT Id FROM AsyncapexJob WHERE ApexClassID in :classIds and Status = 'Processing'];
            system.debug('+++++++QChe++++++++CaseObject1');
            if(!emailArchiveJob.isEmpty() && emailArchiveJob.size() > 0)            
            {
                Validator_cls.setArchiveJobExecuting();
                IsEmailArchiveBatchJob=true;
            }
            //}
            Validator_cls.setArchiveBatchJobDone();
        }
    }
    system.debug(LoggingLevel.INFO,'Case Object - emailArchiveBatchJob value is  =='+IsEmailArchiveBatchJob);
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job  
    
    
    /****** Get all case recordtype Map *******************/
    Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds(); 
    
    /****Variable declaration for CheckMandatoryTaskForTheCase****/
    public String CheckMandatoryTaskForTheCase=null;
    List<Case> checklstCase = new List<case>();
    Set<Id> checkrecordTypeIds = new Set<Id>();
    
    /****Variable declaration for ValidateDateSentToClosure****/
    public String ValidateDateSentToClosure=null;
    List<Case> validatelstCase = new List<case>();    
    Set<Id> validaterecordTypeIds = new Set<Id>();
    
    /****Variable declaration for CloneCaseIfRecurringCaseChecked2****/
    public String CloneCaseIfRecurringCaseChecked2=null;
    List<Case> lstClone = new List<case>();    
    Set<Id> clonecaserecordTypeIds = new Set<Id>();
    
    /****Variable declaration for NCSP_OpportunityUpdate_Case****/
    public String NCSP_OpportunityUpdate_Case=null;
    
    /****Variable declaration for NCSPCaseClosedDateTime****/
    //public String NCSPCaseClosedDateTime=null;
    Set<Id> caseclosedrecordTypeIds = new Set<Id>();
    /* Variable declaration for onboard date query trigger*/
    //public String DateOnBoarderCSAAssignedQuery=null;
    //public boolean runDateOnBoarderCSAAssignedQuery=false;
    /****Variable declaration for CACDateValidationRules****/
    //public String CACDateValidationRules=null;
    //ID Retention_RecordType;
    ID CAC_SKP_RM_RecordType;
    ID CAC_SKP_Shred_RecordType;
    ID CAC_DP_Closure_RecordType;
    ID CAC_Case_DM_RecordType;
    ID Retention_RM_RecordType;// # 10469 and 10364
    ID Retention_SH_RecordType; // 10469 and 10364
    if(rtMapByName.containsKey('CAC_SKP_RM'))
        CAC_SKP_RM_RecordType = rtMapByName.get('CAC_SKP_RM').getRecordTypeId();
    if(rtMapByName.containsKey('Retention_RM'))
        Retention_RM_RecordType = rtMapByName.get('Retention_RM').getRecordTypeId(); 
    if(rtMapByName.containsKey('CAC_SKP_Shred'))
        CAC_SKP_Shred_RecordType = rtMapByName.get('CAC_SKP_Shred').getRecordTypeId();
    if(rtMapByName.containsKey('Retention_SH'))
        Retention_SH_RecordType = rtMapByName.get('Retention_SH').getRecordTypeId(); 
    if(rtMapByName.containsKey('CAC_DP_Closure'))
        CAC_DP_Closure_RecordType = rtMapByName.get('CAC_DP_Closure').getRecordTypeId(); 
    if(rtMapByName.containsKey('Case_DM'))
        CAC_Case_DM_RecordType = rtMapByName.get('Case_DM').getRecordTypeId();
    Date dtToday = Date.today();
    
    /****Variable declaration for SetOriginalfields****/
    //public String SetOriginalfields=null;
    //public Boolean runSetOrgfields=false;
    Set<Id> recordTypes = new Set<Id>();
    
    /****Variable declaration for NCSPDateValidationRulesTrigger****/
    //public String NCSPDateValidationRulesTrigger=null;
    //Developer Name:Madhu Paladugu
    //Case number:00593195
    //declared two new var for new record type changes
    Set<Id> NCSP_Upsell_RecordTypeIds=new Set<Id>();
    Set<Id> NCSP_New_Customer_RecordTypeIds=new Set<Id>();
    //public Boolean runNCSPValRuleTri=false;
    Set<Id> DP_RecTypeIds = new Set<Id>();
    Set<Id> SKP_DP_DMS_RecTypeIds = new Set<Id>(); 
    Set<Id> SKP_SKP_DMS_RecTypeIds = new Set<Id>();
    Set<Id> SKP_SKP_DP_RecTypeIds = new Set<Id>();
    Set<Id> SKP_SKP_DP_DMS_RecTypeIds = new Set<Id>();
    Set<Id> SKP_DEPT_ADD_RecTypeIds = new Set<Id>();
    Set<Id> NCSP_TECH_RecTypeIds = new Set<Id>();//NCSP: Tech Services New Customer Setup
    Set<ID>NCSP_SKP_DMS_Setup = new Set<Id>(); // NCSP: SKP New Customer Setup and NCSP: DMS
    /*Developer Name: Madhu Paladugu
Case Number   : 01159965
Description   : Added variable to hold recordtypes for INVOICE_REVIEW_DATE Validation
*/
    Set<ID> NCSP_INVOICE_DATE_RecTypeIds=new Set<Id>();
    /***Variable declaration for PopulateTheInvoiceMailingDate****/
    public String PopulateTheInvoiceMailingDate=null;
    public Boolean runPopulateTheInvoiceMailingDate=false;
    Set<Date> RM_MAILING_DATES=new Set<Date>();
    Set<Date> DB_R_MAILING_DATES=new Set<Date>();
    Set<ID> REC_IDS_MAILING_DATE=new Set<Id>();
    Map<Id,String> ONE_TIME_SHRED_MAP=new Map<Id,string>();
    Boolean insTrig = Trigger.isInsert;
    Date sysToday = System.today();
    
    /****Variable declaration for Issue_TaskRequire_CaseComment_FollowUpNote****/
    Set<ID>issuerecordTypeID = new Set<ID>();
    List<case> lstNewCase = new List<case>();
    public String Issue_TaskRequire_CaseComment_FollowUpNote=null;
    public Boolean runIssueTask=false;
    
    /****Variable declaration for NCSP_Prevent_ParentCase_Closure****/
    //public String NCSP_Prevent_ParentCase_Closure=null;
    //public Boolean runNCSPpreventparent=false;
    Set<Id> preventrecordTypeIds = new Set<Id>();  
    List<case> lstClosedCases = new List<case>();
    
    /****Variable declaration for UpdateAccountId****/
    //public String UpdateAccountId=null;
    //public Boolean runUpdateAccountId=false;
    Set<Id> updaterecordTypeIds = new Set<Id>();    
    Set <ID>CustomerID = new Set<ID>();
    
    /***Variable declaration for UpdateSlaDaysSlaTargetDateAndValidateInitialDuedate****/
    public String UpdateSlaDaysSlaTargetDateAndValidateInitialDuedate=null;
    public Boolean runUpdateSla=false;
    List<case> slalstNewCase = new List<Case>();
    List<Case> lstRecurringCase = new List<case>();
    List<Case> lstNonRecurringCase = new List<case>();
    List<Case> lstSlaDateCase = new List<case>();
    Set<Id> slarecordTypeIds = new Set<Id>();
    MAP<Id,String> mapCaseRecordType = new MAP<Id,String>(); 
    List<string> lstType = new List<string>();
    List<string> lstSubType = new List<string>();
    
    /***Variable declaration for updateInternalCaseTeam***/
    public String updateInternalCaseTeam=null;
    Id viewRole, editRole;
    
    /****Variable declaration for UpdateNCSPStatus****/
    Set<Id> NCSPRecordTypeIds = new Set<Id>();
    List<id> optyIdSet = new List<id>();
    public String UpdateNCSPStatus=null;
    public Boolean runUpdateNCSPStatus=false;
    
    /***Retrieving Custom Settings***/
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Case'){
            /*if(cs.Trigger__c == 'NCSPCaseClosedDateTime') {
                NCSPCaseClosedDateTime = cs.Value__c;
            }*/
            if(cs.Trigger__c == 'CheckMandatoryTaskForTheCase') {
                CheckMandatoryTaskForTheCase = cs.Value__c;    
            }
            /*if(cs.Trigger__c == 'CACDateValidationRules') {
CACDateValidationRules = cs.Value__c;  
}*/
            if(cs.Trigger__c == 'CloneCaseIfRecurringCaseChecked2') {
                CloneCaseIfRecurringCaseChecked2 = cs.Value__c;  
            }
            if(cs.Trigger__c == 'Issue_TaskRequire_CaseComment') {
                Issue_TaskRequire_CaseComment_FollowUpNote = cs.Value__c;  
            }
            /*if(cs.Trigger__c == 'NCSPDateValidationRulesTrigger') {
NCSPDateValidationRulesTrigger = cs.Value__c;  
}*/
            /*if(cs.Trigger__c == 'NCSP_Prevent_ParentCase_Closure') {
                NCSP_Prevent_ParentCase_Closure = cs.Value__c;  
            }*/
            if(cs.Trigger__c == 'NCSP_OpportunityUpdate_Case') {
                NCSP_OpportunityUpdate_Case = cs.Value__c;  
            }
            if(cs.Trigger__c == 'updateInternalCaseTeam') {
                updateInternalCaseTeam = cs.Value__c;  
            }
            /*if(cs.Trigger__c == 'SetOriginalfields') {
                SetOriginalfields = cs.Value__c;  
            }*/
            /*if(cs.Trigger__c == 'UpdateAccountId') {
                UpdateAccountId = cs.Value__c;  
            }*/
            if(cs.Trigger__c == 'UpdateSlaDaysSlaTargetDate') {
                UpdateSlaDaysSlaTargetDateAndValidateInitialDuedate = cs.Value__c;  
            }
            if(cs.Trigger__c == 'ValidateDateSentToClosure') {
                ValidateDateSentToClosure = cs.Value__c;  
            }
            /*if(cs.Trigger__c=='DateOnBoarderCSAAssignedQuery'){
                DateOnBoarderCSAAssignedQuery=cs.Value__c;
            }*/
            if(cs.Trigger__c=='PopulateTheInvoiceMailingDate'){
                PopulateTheInvoiceMailingDate =cs.Value__c;
            }
            if(cs.Trigger__c=='UpdateNCSPStatus'){
                UpdateNCSPStatus =cs.Value__c;
            }
        }
    }  
    
    //Email-to-Case
    /*Developer Name: Srinivasa Rao Mandalapu
Case Number   : 01414611
Description   : Preventing the trigger not to fire for 'IME SC Case' & 'IME SC Case Resolved' Record Types.
*/
    /*Start*/
    Set<Id> IMESCRecordTypeIds = new Set<Id>();
    IMESCCaseRecordTypes();
    Boolean ExecuteTrigger=false;
    if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUnDelete){
        for(Integer i=0;i<Trigger.new.size();i++){
            if(!IMESCRecordTypeIds.contains(Trigger.new[i].recordtypeId))
                ExecuteTrigger=true;
        }
    }
    if(Trigger.isDelete){
        for(Integer i=0;i<Trigger.old.size();i++){
            if(!IMESCRecordTypeIds.contains(Trigger.old[i].recordtypeId))
                ExecuteTrigger=true;
        }
    }
    /*End*/
    
    /*****************************************START TRIGGER*************************************************/
    // #11233 and #11191 starts - commenting code to stop deleting archival records while deleting case
    /* if(Trigger.isAfter) {
if(Trigger.isDelete) {
system.debug('we are in delete loop');
if (!System.isBatch()){ 
ArchiveEmailService bigObjectDeletionService = new ArchiveEmailService();
bigObjectDeletionService.clearArchiveEmailOnCaseDelete(Trigger.old);
}
}
}*/ 
    //#11233 and #11191 ends
    
    /*****************************************BEFORE INSERT AND UPDATE*************************************/
    System.debug('--217----ExecuteTrigger:'+ExecuteTrigger);
    if(ExecuteTrigger && !IsEmailArchiveBatchJob){
        System.debug('++++++++++++executing case object trigger+++++++++');
        if(Trigger.isBefore){
            
            /*if(NCSPCaseClosedDateTime=='True')    
                
                CaseclosedfillRecordTypeIds();*/
            
            if(Trigger.isUpdate){
                
                //madhu added logic on 12/14/12
                Boolean executeLogic=false;
                for(Integer i=0;i<Trigger.new.size();i++){
                    if(Trigger.old[i].Open_Tasks__c == Trigger.new[i].Open_Tasks__c){              
                        executeLogic=true;
                        break;
                    }
                }
                
                //madhu added logic on 12/14/12
                if(executeLogic){            
                    //runSetOrgfields=true;
                    //runNCSPValRuleTri=true;
                    //runNCSPpreventparent=true;
                    //runUpdateAccountId=true;
                    runUpdateSla=true;
                    /*if(DateOnBoarderCSAAssignedQuery=='True'){
                        runDateOnBoarderCSAAssignedQuery=true;
                    }*/
                    if(PopulateTheInvoiceMailingDate=='True'){
                        runPopulateTheInvoiceMailingDate=true;
                    }
                    
                    /****NCSP CASE CLOSED DATE TIME****/
                    /*---start---*/
                    
                    /* commented as part of user story #27066
                     if(NCSPCaseClosedDateTime=='True'){
                        
                        for(integer i=0;i<trigger.new.size();i++){
                            if( caseclosedrecordTypeIds.contains(trigger.new[i].RecordTypeId) && ( (trigger.new[i].Status == 'Closed') || (trigger.new[i].Status == 'Cancelled') || (trigger.new[i].Status == 'Duplicate') ) && ( (trigger.old[i].Status != 'Closed') && (trigger.old[i].Status != 'Cancelled') && (trigger.old[i].Status != 'Duplicate') ) ){
                                trigger.new[i].NCSP_Case_Closed_Date__c = datetime.now();
                            }
                        }
                    } commented as part of user story #27066 */
                    
                    /****NCSP CASE CLOSED DATE TIME****/
                    /*---end---*/       
                    
                    /****CHECK MANDATORY TASK FOR THE CASE****/
                    /*---start---*/
                    
                    // Name:CheckMandatoryTaskForTheCase
                    // Description: Check if there is open task or pending event on case or not
                    // Created By: Vinod Kumar
                    
                    /*if(CheckMandatoryTaskForTheCase=='True'){            
                        
                        CheckfillRecordTypeIds(); 
                        for(case c :Trigger.new){
                            if( c.Status == 'Closed' && checkrecordTypeIds.contains(c.RecordTypeId)){
                                checklstCase.add(c);
                            }
                        }
                        // Get all opened Task of selected case
                        if(checklstCase.size() > 0)
                        {
                            List<Case> caselist=[select id,(Select t.id, t.WhatId From Tasks t where t.Mandatory_Task__c = true and t.IsClosed = false),(Select e.WhatId, e.EndDateTime, e.Due_Date__c, e.Activity_Type__c From Events e where e.Mandatory_Task__c = true and e.EndDateTime >: DateTime.now()) from case where id in :checklstCase];
                            for(Case c: caselist)
                            { 
                                system.debug('@@size()@@'+c.tasks.size());
                                if(c.Tasks.size()>0 || c.Events.size()>0)
                                { 
                                    Case cs = Trigger.newMap.get(c.id);
                                    cs.addError('Cannot close a case with uncompleted tasks or events'); 
                                } 
                            }
                        }
                        
                    }*/
                    
                    /****CHECK MANDATORY TASK FOR THE CASE****/
                    /*---end---*/
                    
                    /****VALIDATE DATE SENT TO CLOSURE****/
                    /*---start---*/
                    
                    /*W-000616*/
                    /*if(ValidateDateSentToClosure=='True'){            

for(case c :Trigger.new){
if(validaterecordTypeIds.contains(c.RecordTypeId) && c.Date_Sent_To_Closures__c != Null && c.Retained__c == 'No'){
validatelstCase.add(c);
}
}
if(validatelstCase.size() > 0){
List<Task> lstTask = [Select t.id, t.WhatId From Task t where t.IsClosed = false and t.WhatId in: validatelstCase];
Map<ID,ID> mapTask= new Map<ID,ID>();
for(Task t : lstTask){
mapTask.put(t.WhatId,t.WhatId);
}
for( case c:validatelstCase){
if(mapTask.containsKey(c.id)){
c.addError('Date sent to Closure cannot be populated when there are open tasks. Please close all the open activities and then set the date sent to closure');
}
}
}           
} */
                    /*W-000616*/
                    
                    /****VALIDATE DATE SENT TO CLOSURE****/
                    /*---end---*/
                    
                    /****CAC DATE VALIDATION RULES****/
                    /*---start---*/
                    
                    // Name:CACDateValidationRules
                    // Description: To validate CAC Date
                    // Created By: Vinod Kumar
                    
                    /*if(CACDateValidationRules=='True'){
UtilCacDateValidation.validateCacDateOnUpdate( trigger.new, trigger.oldMap, CAC_SKP_RM_RecordType, CAC_SKP_Shred_RecordType, CAC_DP_Closure_RecordType, CAC_Case_DM_RecordType,Retention_RM_RecordType,Retention_SH_RecordType);// # 10469 and 10364 added Retention RM and SH
}*/
                    /****CAC DATE VALIDATION RULES****/
                    /*---end---*/
                }
            }
            
            if(Trigger.isInsert){
                
                //runSetOrgfields=true;
                //runNCSPValRuleTri=true;
                //runNCSPpreventparent=true;
                //runUpdateAccountId=true;
                runUpdateSla=true;
                /*if(DateOnBoarderCSAAssignedQuery=='True'){
                    runDateOnBoarderCSAAssignedQuery=true;
                }*/
                
                /****CAC DATE VALIDATION RULES****/
                /*---start---*/
                
                /*  if(CACDateValidationRules=='True'){

for(Case newCase :trigger.new){
// Date Validation ForRetention, CAC - DP Closure,CAC - SKP RM and CAC - SKP Shred Record type
//  # 10469 and 10364 added Retention RM and Retention SH to below condition
if(newCase.RecordTypeId == CAC_SKP_RM_RecordType || newCase.RecordTypeId == CAC_SKP_Shred_RecordType || newCase.RecordTypeId == CAC_DP_Closure_RecordType || newCase.RecordTypeId == Retention_RM_RecordType || newCase.RecordTypeId == Retention_SH_RecordType ){
system.debug('====1==='+ newCase.Customer_Request_Received_Date__c +'=='+ dtToday );
if(newCase.Customer_Request_Received_Date__c != null && newCase.Customer_Request_Received_Date__c.date() > dtToday ){
newCase.Customer_Request_Received_Date__c.addError('Customer Request Received Date must be current or past date.   It cannot be in the Future.');
} 
W-000616
if(newCase.Date_Owner_Established__c != null && newCase.Date_Owner_Established__c.date() > dtToday ){
newCase.Date_Owner_Established__c.addError('Date Owner Established must be current or past date.   It cannot be in the Future test.');
}

if(newCase.Date_Sent_To_Closures__c != null && newCase.Date_Sent_To_Closures__c.date() != dtToday ){
newCase.Date_Sent_To_Closures__c.addError('Date sent to Closures must be today\'s date. It cannot be in the Past or the Future.');
}
}

// Date Validation CAC - DP Closure,CAC - SKP RM and CAC - SKP Shred Record type
if(newCase.RecordTypeId == CAC_SKP_RM_RecordType || newCase.RecordTypeId == CAC_SKP_Shred_RecordType || newCase.RecordTypeId == CAC_DP_Closure_RecordType ){
W-000616
if(newCase.CAC_First_Customer_Contact_Date__c != null && newCase.CAC_First_Customer_Contact_Date__c.date() != dtToday ){
newCase.CAC_First_Customer_Contact_Date__c.addError('CAC First Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.CAC_Intro_Date__c != null && newCase.CAC_Intro_Date__c.date() != dtToday ){
newCase.CAC_Intro_Date__c.addError('CAC Intro Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.CAC_Inactivate_Request__c != null && newCase.CAC_Inactivate_Request__c.date() != dtToday ){     
newCase.CAC_Inactivate_Request__c.addError('CAC Inactivate Request must be today\'s date. It cannot be in the Past or the Future..');    
}
//95
if(newCase.CAC_Second_Customer_Contact_Date__c != null && newCase.CAC_Second_Customer_Contact_Date__c.date() != dtToday ){
newCase.CAC_Second_Customer_Contact_Date__c.addError('CAC Second Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.CAC_Third_Customer_Contact_Date__c != null && newCase.CAC_Third_Customer_Contact_Date__c.date() != dtToday ){
newCase.CAC_Third_Customer_Contact_Date__c.addError('CAC Third Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
}    
}

// Date Validation For CAC - SKP RM Record type
//  # 10469 and 10364 added Retention RM to below condition
if(  newCase.RecordTypeId == CAC_SKP_RM_RecordType ||newCase.RecordTypeId == Retention_RM_RecordType ){

if(newCase.Cost_Summary_Attempt_1__c != null && newCase.Cost_Summary_Attempt_1__c.date() != dtToday ){
newCase.Cost_Summary_Attempt_1__c.addError('Cost Summary Attempt 1 must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Cost_Summary_Attempt2__c != null && newCase.Cost_Summary_Attempt2__c.date() != dtToday ){
newCase.Cost_Summary_Attempt2__c.addError('Cost Summary Attempt 2 must be today\'s date. It cannot be in the Past or the Future.');
}
//35
if(newCase.Cost_Summary_Attempt3__c != null && newCase.Cost_Summary_Attempt3__c.date() != dtToday ){
newCase.Cost_Summary_Attempt3__c.addError('Cost Summary Attempt 3 must be today\'s date. It cannot be in the Past or the Future.');
}
W-000616
if(newCase.Customer_Update_Date__c != null && newCase.Customer_Update_Date__c.date() != dtToday ){
newCase.Customer_Update_Date__c.addError('Customer Update Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Account_Inactivated__c != null && newCase.Date_Account_Inactivated__c.date() > dtToday ){
newCase.Date_Account_Inactivated__c.addError('Date Account Inactivated must be current or past date.  It cannot be in the Future');
}
Begin - Case field deletion : 10373
if(newCase.Date_Cancelled__c != null && newCase.Date_Cancelled__c.date() != dtToday ){
newCase.Date_Cancelled__c.addError('Date Cancelled must be today\'s date. It cannot be in the Past or the Future.');
} 
End - Case field deletion : 10373 
if(newCase.Date_Customer_Approval_Received__c != null && newCase.Date_Customer_Approval_Received__c.date() > dtToday ){
newCase.Date_Customer_Approval_Received__c.addError('Date Customer Approval Received must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_Destruction_Order_Created__c != null && newCase.Date_Destruction_Order_Created__c.date() > dtToday ){
newCase.Date_Destruction_Order_Created__c.addError('Date Destruction Order Created must be current or past date.   It cannot be in the Future.');
}
W-000616
if(newCase.Date_Destruction_SR_Requested__c != null && newCase.Date_Destruction_SR_Requested__c.date() != dtToday ){
newCase.Date_Destruction_SR_Requested__c.addError('Date Destruction SR Requested must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Email_Sent_To_Contracts_Admin__c != null && newCase.Date_Email_Sent_To_Contracts_Admin__c.date() != dtToday ){
newCase.Date_Email_Sent_To_Contracts_Admin__c.addError('Date email sent to Contracts Admin must be today\'s date. It cannot be in the Past or the Future.');
}
W-000616
if(newCase.Date_Email_Sent_To_Local_Leadership__c != null && newCase.Date_Email_Sent_To_Local_Leadership__c.date() != dtToday ){
newCase.Date_Email_Sent_To_Local_Leadership__c.addError('Date email sent to Local Leadership must be today\'s date. It cannot be in the Past or the Future.');
}
// 45
if(newCase.Date_Followed_Up_W_Customer__c != null && newCase.Date_Followed_Up_W_Customer__c.date() != dtToday ){
newCase.Date_Followed_Up_W_Customer__c.addError('Date Followed Up W Customer must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Inventory_Status_Confirmed__c != null && newCase.Date_Inventory_Status_Confirmed__c.date() != dtToday ){
newCase.Date_Inventory_Status_Confirmed__c.addError('Date Inventory status confirmed must be today\'s date. It cannot be in the Past or the Future.');
}
W-000616
if(newCase.Date_Invoice_Created__c != null && newCase.Date_Invoice_Created__c.date() > dtToday ){
newCase.Date_Invoice_Created__c.addError('Date Invoice Created must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_Invoice_Details_Package_Sent__c != null && newCase.Date_Invoice_Details_Package_Sent__c.date() != dtToday ){
newCase.Date_Invoice_Details_Package_Sent__c.addError('Date Invoice details package sent must be today\'s date. It cannot be in the Past or the Future.');
} 
W-000616
if(newCase.Date_of_Invoice_Confirmation__c != null && newCase.Date_of_Invoice_Confirmation__c.date() != dtToday ){
newCase.Date_of_Invoice_Confirmation__c.addError('Date of Invoice confirmation must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Ops_Confirmed_For_Timeline__c != null && newCase.Date_Ops_Confirmed_For_Timeline__c.date() > dtToday ){
newCase.Date_Ops_Confirmed_For_Timeline__c.addError('Date Ops confirmed for timeline must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_Ops_emailed_for_timeline__c != null && newCase.Date_Ops_emailed_for_timeline__c.date() != dtToday ){
newCase.Date_Ops_emailed_for_timeline__c.addError('Date Ops emailed for timeline must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_PDL_Approval_Received__c != null && newCase.Date_PDL_Approval_Received__c.date() > dtToday ){
newCase.Date_PDL_Approval_Received__c.addError('Date PDL Approval Received must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_PDL_Sent_to_Customer__c != null && newCase.Date_PDL_Sent_to_Customer__c.date() != dtToday ){
newCase.Date_PDL_Sent_to_Customer__c.addError('Date PDL Sent to customer must be current. It cannot be in the Past or Future date');
} 
//55
if(newCase.Date_PW_Order_Created__c != null && newCase.Date_PW_Order_Created__c.date() > dtToday ){
newCase.Date_PW_Order_Created__c.addError('Date PW Order Created must be current or past date.   It cannot be in the Future.');
}  
W-000616
if(newCase.Date_PW_SR_Requested__c != null && newCase.Date_PW_SR_Requested__c.date() != dtToday ){
newCase.Date_PW_SR_Requested__c.addError('Date PW SR Requested must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Revised_Cost_Summary_Sent__c != null && newCase.Date_Revised_Cost_Summary_Sent__c.date() != dtToday ){
newCase.Date_Revised_Cost_Summary_Sent__c.addError('Date revised cost summary sent must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Worksheet_Created__c != null && newCase.Date_Worksheet_Created__c.date() > dtToday ){
newCase.Date_Worksheet_Created__c.addError('Date Worksheet Created must be current or past date.   It cannot be in the Future.');
}
if(newCase.Estimated_Pay_Date__c != null && newCase.Estimated_Pay_Date__c.date() < dtToday ){
newCase.Estimated_Pay_Date__c.addError('Estimated Pay Date must be current or future date. It cannot be in the Past');
} 
//60
if(newCase.Inactive_request_sent_to_Contracts_Admin__c != null && newCase.Inactive_request_sent_to_Contracts_Admin__c.date() != dtToday ){
newCase.Inactive_request_sent_to_Contracts_Admin__c.addError('Inactive request sent to Contracts Admin must be today\'s date. It cannot be in the Past or the Future.');
}
//61 not created
if(newCase.Invoice_Request_Date__c != null && newCase.Invoice_Request_Date__c.date() != dtToday ){
newCase.Invoice_Request_Date__c.addError('Invoice Request Date must be today\'s date. It cannot be in the Past or the Future.');
}
W-000616
if(newCase.Local_Leadership_response_date__c != null && newCase.Local_Leadership_response_date__c.date() > dtToday ){
newCase.Local_Leadership_response_date__c.addError('Local Leadership response date must be current or past date.   It cannot be in the Future.');
}
if(newCase.Notify_Collections__c != null && newCase.Notify_Collections__c.date() != dtToday ){
newCase.Notify_Collections__c.addError('Notify Collections must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Order_completion_date__c != null && newCase.Order_completion_date__c.date() > dtToday ){
newCase.Order_completion_date__c.addError('Order completion date must be current or past date.   It cannot be in the Future.');
} 
//65
if(newCase.Order_Scheduled_date__c != null && newCase.Order_Scheduled_date__c.date() < dtToday ){
newCase.Order_Scheduled_date__c.addError('Order Scheduled date must be current or future date. It cannot be in the Past');
}
if(newCase.Payment_Confirmation_Date__c != null && newCase.Payment_Confirmation_Date__c.date() > dtToday ){
newCase.Payment_Confirmation_Date__c.addError('Payment Confirmation Date must be current or past date.   It cannot be in the Future.');
}
if(newCase.Payment_Follow_Up__c != null && newCase.Payment_Follow_Up__c.date() != dtToday ){
newCase.Payment_Follow_Up__c.addError('Payment follow up must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.PDL_Follow_up_Date__c != null && newCase.PDL_Follow_up_Date__c.date() != dtToday ){
newCase.PDL_Follow_up_Date__c.addError('PDL Follow up Date must be today\'s date. It cannot be in the Past or the Future.');
}   
//69                        
}
// Date Validation For CAC - SKP Shred Record type
//  # 10469 and 10364 added Retention SH to below condition
system.debug('newCase.RecordTypeId '+newCase.RecordTypeId);
if(  newCase.RecordTypeId == CAC_SKP_Shred_RecordType || newCase.RecordTypeId == Retention_SH_RecordType ){
if(newCase.Date_Final_Order_Created_in_SKP__c != null && newCase.Date_Final_Order_Created_in_SKP__c.date() != dtToday ){
newCase.Date_Final_Order_Created_in_SKP__c.addError('Date Final Order created in SKP must be today\'s date. It cannot be in the Past or the Future.');
}
//70
W-000616
if(newCase.Date_Sent_To_Shared_services__c != null && newCase.Date_Sent_To_Shared_services__c.date() != dtToday ){
newCase.Date_Sent_To_Shared_services__c.addError('Date Sent to Shared Services must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Service_Confirmation__c != null && newCase.Date_Service_Confirmation__c.date() != dtToday ){
newCase.Date_Service_Confirmation__c.addError('Date Service confirmation must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Service_To_Be_Completed__c != null && newCase.Date_Service_To_Be_Completed__c.date() < dtToday ){
newCase.Date_Service_To_Be_Completed__c.addError('Date Service To Be Completed must be current or future date. It cannot be in the Past');
}
if(newCase.Date_Termination_Request_Sent_Contracts__c != null && newCase.Date_Termination_Request_Sent_Contracts__c.date() != dtToday ){
newCase.Date_Termination_Request_Sent_Contracts__c.addError('Date Termination Request Sent Contracts must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Visit_Profile_To_Be_Inactivated__c != null && newCase.Date_Visit_Profile_To_Be_Inactivated__c.date() < dtToday ){
newCase.Date_Visit_Profile_To_Be_Inactivated__c.addError('Date Visit Profile to be inactivated must be current or future date. It cannot be in the Past');
}
// new PR-06211
if(newCase.Rescheduled_Date__c != null && newCase.Rescheduled_Date__c.date() < dtToday ){
newCase.Rescheduled_Date__c.addError('Rescheduled Date must be current or future date. It cannot be in the Past');
}
if(newCase.Date_Confirmed_by_Contracts__c != null && newCase.Date_Confirmed_by_Contracts__c.date() > dtToday ){
newCase.Date_Confirmed_by_Contracts__c.addError('Date Confirmed by contracts must be current or Past date. It cannot be in the Future');
}
if(newCase.Final_Customer_Contact_Date__c != null && newCase.Final_Customer_Contact_Date__c.date() != dtToday ){
newCase.Final_Customer_Contact_Date__c.addError('Final Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
}

}
// Date Validation For CAC - DP Closure Record type
if(newCase.RecordTypeId == CAC_DP_Closure_RecordType){
if(newCase.Confirm_Final_Service__c != null && newCase.Confirm_Final_Service__c.date() > dtToday ){
newCase.Confirm_Final_Service__c.addError('Confirm Final Service must be current or past date.   It cannot be in the Future.');
} 
if(newCase.Date_Closure_Complete__c != null && newCase.Date_Closure_Complete__c.date() > dtToday ){
newCase.Date_Closure_Complete__c.addError('Date Closure Complete must be current or past date.   It cannot be in the Future.');
}
//W-000616
if(newCase.Date_Contracts_Respond__c != null && newCase.Date_Contracts_Respond__c.date() > dtToday ){
newCase.Date_Contracts_Respond__c.addError('Date Contracts Respond must be current or past date.   It cannot be in the Future.');
}
system.debug('newcae.Date_Final_Service_Order_Created__c'+newCase.Date_Final_Service_Order_Created__c);
if(newCase.Date_Final_Service_Order_Created__c != null && newCase.Date_Final_Service_Order_Created__c.date() != dtToday ){
newCase.Date_Final_Service_Order_Created__c.addError('Date Final Service Order Created must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Moved_on_Call__c != null && newCase.Date_Moved_on_Call__c.date() != dtToday ){
newCase.Date_Moved_on_Call__c.addError('Date Moved on Call must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Ops_Confirms_SB_Clean__c != null && newCase.Date_Ops_Confirms_SB_Clean__c.date() > dtToday ){
newCase.Date_Ops_Confirms_SB_Clean__c.addError('Date Ops confirms SB clean must be current or past date.   It cannot be in the Future.');
} 
//85
//W-000616
if(newCase.Date_Resubmitted_to_Contracts__c != null && newCase.Date_Resubmitted_to_Contracts__c.date() != dtToday ){
newCase.Date_Resubmitted_to_Contracts__c.addError('Date resubmitted to Contracts must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Sent_to_Contracts_US__c != null && newCase.Date_Sent_to_Contracts_US__c.date() != dtToday ){
newCase.Date_Sent_to_Contracts_US__c.addError('Date Sent to Contracts US must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Sent_to_Ops__c != null && newCase.Date_Sent_to_Ops__c.date() != dtToday ){
newCase.Date_Sent_to_Ops__c.addError('Date sent to Ops must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_to_be_Moved_on_Call__c != null && newCase.Date_to_be_Moved_on_Call__c.date() < dtToday ){
newCase.Date_to_be_Moved_on_Call__c.addError('Date to be Moved on Call must be current or future date. It cannot be in the Past');
}
// #8991 Delete 10 case field deletion :- Part 3 "OTO_Created_Date__c" 
if(newCase.OTO_Created_Date__c != null && newCase.OTO_Created_Date__c.date() != dtToday ){
newCase.OTO_Created_Date__c.addError('OTO Created Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Update_Sent_To_Operations__c != null && newCase.Update_Sent_To_Operations__c.date() != dtToday ){
newCase.Update_Sent_To_Operations__c.addError('Update Sent To Operations must be today\'s date. It cannot be in the Past or the Future.');
}
//92
}
}  
}  */ 
                
                /****CAC DATE VALIDATION RULES****/
                /*---end---*/
                
                /****NCSP CASE CLOSED DATE TIME****/
                /*---start---*/
                
                /* commented as part of user story #27066
                 if(NCSPCaseClosedDateTime=='True'){
                    
                    for (Case c : trigger.new){
                        
                        if ( caseclosedrecordTypeIds.contains(c.RecordTypeId) && ( (c.Status == 'Closed') || (c.Status == 'Cancelled') || (c.Status == 'Duplicate') ) ){
                            c.NCSP_Case_Closed_Date__c = datetime.now();
                        }
                    }
                } commented as part of user story #27066 */
                
                /****NCSP CASE CLOSED DATE TIME****/
                /*---end---*/
                
            }
        }
        /*************************************END OF BEFORE INSERT AND UPDATE***************************/
        //Developer Name:Madhu Paladugu
        //Case number:00593195
        /* Trigger:DateOnBoarderCSAAssignedQuery  start */
        /* Commented as part of user story #27066
         if(runDateOnBoarderCSAAssignedQuery==true){
            Set<Id> recordTypeIdForSKP_Department_Add_Only=new Set<Id>();
            Set<Id> recIdsForUpdateDateOnBoarderCSA=new Set<Id>();
            Map<String,Schema.RecordTypeInfo> DateOnBoarderMapByrecName = CaseRecordTypeSelection.getRecordTypeIds(); //d.getRecordTypeInfosByName();
            if(DateOnBoarderMapByrecName.containsKey('NCSP_SKP_Department_Add_Only')){
                recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_Upsell')){
                recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP_Upsell').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_New_Customer_Setup')){
                recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP_New_Customer_Setup').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_DP_Onboarding_team')){
                recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP_DP_Onboarding_team').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_SKP_New_customer_setup')){
                recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP_SKP_New_customer_setup').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_DMS')){
                recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP_DMS').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_Tech_Services_New_Customer_Setup')){
                recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_Upsell')){
                recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP_Upsell').getRecordTypeId());
            }
            if(DateOnBoarderMapByrecName.containsKey('NCSP_New_Customer_Setup')){
                recIdsForUpdateDateOnBoarderCSA.add(DateOnBoarderMapByrecName.get('NCSP_New_Customer_Setup').getRecordTypeId());
            }
            Set<Id> UserIdsFromCustomSettings=new Set<Id>();
            List<Date_On_Boarder_CSA_users__c> allowedusers=Date_On_Boarder_CSA_users__c.getAll().values();
            for(Date_On_Boarder_CSA_users__c d:allowedusers){
                UserIdsFromCustomSettings.add(d.UserId__c);
                
            }
            
            for(case c:trigger.new){
                system.debug('----insideforloop----');
                String currentUserId=c.ownerId;
                //String currentUserId=c.owner.type;  
                
                if(UserIdsFromCustomSettings.contains(c.OwnerId)){             
                    c.NCSP_Owner_new__c='NCSP CSA';             
                    if(c.Date_On_Boarder_CSA_Assigned__c==null){
                        
                        if((recIdsForUpdateDateOnBoarderCSA.contains(c.RecordTypeId)&&c.Date_Welcome_Call_Attempt_1__c==null&&c.ParentId==null&&c.IsClosed==false&&c.Date_On_Boarder_CSA_Assigned__c==null)
                           ||(recordTypeIdForSKP_Department_Add_Only.contains(c.RecordTypeId)&& c.Date_Welcome_Call_Attempt_1__c==null && c.Date_On_Boarder_CSA_Assigned__c==null &&c.IsClosed==false ) ){
                               
                               c.NCSP_Start_Date_Set__c=true;
                               c.Date_On_Boarder_CSA_Assigned__c=datetime.now();
                               
                               
                           }
                    }
                }
                /* else If(c.OwnerId=='00G800000022m9f'){

c.NCSP_Owner_new__c='Assignment Queue';

}

else if(currentUserId.startsWith('00G')&& c.ownerId!='00G800000022m9f'){
c.NCSP_Owner_new__c='Queue';

}*
                else if(currentUserId.startsWith('00G')){
                    c.NCSP_Owner_new__c='Queue';
                    
                }
                else{
                    c.NCSP_Owner_new__c='User';
                    
                }
                
                
                
            }
        } Commented as part of user story #27066 */
        /*Trigger:DateOnBoarderCSAAssignedQuery end*/ 
        /* Developer Name: Madhu Paladugu
Case Number   : 01159965
Description   : Added logic to populate the invoice mailimg date.
*/
        /*Trigger PopulateTheInvoiceMailingDate start*/   
        /*if(runPopulateTheInvoiceMailingDate){
            List<Case> CASE_DATA_TO_MAP=[select id,Customer_ID__r.Name,NCSP_Opportunity__r.Primary_Product_Line__c,Status from case where id IN:Trigger.newMap.keySet()];
            system.debug('+++++++QChe++++++++CaseObject4');
            for(Case C:CASE_DATA_TO_MAP){
                ONE_TIME_SHRED_MAP.put(C.Id,C.Customer_ID__r.Name);
            }
            
            List<Billing_Cut_Off_Schedule__c> GET_ALL_CUT_OF_DATES=[select Billing_Cut_Off_Date__c,Invoice_Mailing_Date__c,Service_Line__c from Billing_Cut_Off_Schedule__c where Billing_Cut_Off_Date__c>=:Date.Today() and Invoice_Mailing_Date__c>=:Date.Today() ];
            system.debug('+++++++QChe++++++++CaseObject5');
            for(Billing_Cut_Off_Schedule__c BT:GET_ALL_CUT_OF_DATES){
                if(BT.Service_Line__c=='DB&R'){
                    DB_R_MAILING_DATES.add(BT.Invoice_Mailing_Date__c);
                }
                else{
                    RM_MAILING_DATES.add(BT.Invoice_Mailing_Date__c);
                }
            }
            List<Date> RM_MAILING_DATES_LIST=new List<Date>(RM_MAILING_DATES);
            List<Date> DB_R_MAILING_DATES_LIST=new List<Date>(DB_R_MAILING_DATES);
            RM_MAILING_DATES_LIST.sort();        
            DB_R_MAILING_DATES_LIST.sort();        
            
            NCSPRecIds();
            for(Integer I=0;i<Trigger.new.size();i++){
                //Logic to override the Customer ID and Group ID for SITAD - Story #22442
                if(UserInfo.getUserId() != '0052H00000DWoGeQAL' && System.Label.QTB_iSCustomerOverrideEnabled.contains('true') && Trigger.new[i].Status == 'New' &&
                   Trigger.new[i].Contract_Status__c != 'Accepted'){
                    //Trigger.new[i].Customer_ID__c = null;
                    //Trigger.new[i].OwnerId = '00G80000002cxu3';
                }
                
                if(Trigger.new[i].Service_Completion_Date__c!=Trigger.old[i].Service_Completion_Date__c || Test.isRunningTest()){
                    
                    if(REC_IDS_MAILING_DATE.contains(Trigger.New[i].RecordtypeId)&&Trigger.New[i].Invoice_Review_date__c==null){
                        if(Trigger.New[i].NCSP_Service_line__c=='One Time Shred'&&(ONE_TIME_SHRED_MAP.get(Trigger.New[i].id)=='A5000' || ONE_TIME_SHRED_MAP.get(Trigger.New[i].id)=='A7000')){
                            
                        }
                        else{
                            if(Trigger.New[i].NCSP_Service_line__c=='DB&R'){
                                if(DB_R_MAILING_DATES_LIST.size()==0){
                                    Trigger.new[i].addError('There are no Billing Cut Off Schedule dates for DB&R Service Line Records');
                                }
                                else{
                                    if(Trigger.new[i].Service_Completion_Date__c!=null){
                                        Trigger.New[i].Invoice_Mailing_Date__c=DB_R_MAILING_DATES_LIST[0];
                                        
                                    }
                                    else{
                                        Trigger.New[i].Invoice_Mailing_Date__c=null;
                                    }
                                }
                            }
                            else{
                                if(RM_MAILING_DATES_LIST.size()==0){
                                    Trigger.new[i].addError('There are no Billing Cut Off Schedule dates for RM Service Line Records');
                                }
                                else{
                                    if(Trigger.new[i].Service_Completion_Date__c!=null){
                                        Trigger.New[i].Invoice_Mailing_Date__c=RM_MAILING_DATES_LIST[0];
                                    }
                                    else{
                                        Trigger.New[i].Invoice_Mailing_Date__c=null;   
                                    }
                                }
                            }    
                        }
                    }
                }
            }
        }*/
        /*Trigger PopulateTheInvoiceMailingDate emd*/   
        /****UPDATE SLA DAYS SLA TARGET DATE AND VALIDATION INITIAL DUE DATE****/
        /*---start---*/
        // Description: Trigger performs population of SLA & SLA Target Date Calculations
        // Updates 2/3 to include update to SLA  Target Date Calculation:
        // update Case SLA Calculation to be based off of Service Location related time zone
        // and if Service location is not populated then the Customer Account Market’s
        // time zone and if the market or service location has no time zone entered then
        // it will use CreatedBy User's time zone.
        // Trigger performs validation to ensure date/time fields that are entered – are entered with correct tense.  Past, Future, Current. 
        // Created By: Vinod Kumar (Appirio)
        // Last Modified: Feb 3, 2011
        
        if(UpdateSlaDaysSlaTargetDateAndValidateInitialDuedate=='True'){
            
            if(runUpdateSla==true){
                if(triggerFlowControl.triggerRunCount('UpdateSlaDaysSlaTargetDateAndValidateInitialDuedate') <= 1){
                    // Get record type id and name
                    slafillRecordTypeIds(); 
                    // Customer Account and holiday Schedule of new cases
                    UtilUpdateSladaysAndSlaTargetDate.GetCaseCustomerAccountAndHolidaySchedule(Trigger.new);
                    // Get Sla Matrix sla days of the Cases
                    for(case c : Trigger.new){
                        /*commented by Jyoti as part of #14409
if(slarecordTypeIds.contains(c.RecordTypeId) ){ 
if(trigger.isInsert){  // is insert
if(c.Recurring_Case__c )  {
if( c.Is_Cloned__c == false && c.Recurring_Frequency__c != null && c.Initial_Due_Date__c != null){
lstRecurringCase.add(c);
slalstNewCase.add(c);
}
}
else{
lstNonRecurringCase.add(c);
slalstNewCase.add(c);                
}                       
lstType.add(c.Type);
lstSubType.add(c.IM_Case_Sub_Type__c);
}
else{   // is update
Case oldC=Trigger.oldMap.get(c.Id);    
if(c.Recurring_Case__c ){ // if case is still recuring and manual update in initial due date
if(c.Recurring_Frequency__c != null && c.Initial_Due_Date__c != null && c.Initial_Due_Date__c != oldC.Initial_Due_Date__c ){
lstRecurringCase.add(c);
slalstNewCase.add(c);
lstType.add(c.Type);
lstSubType.add(c.IM_Case_Sub_Type__c);
}
}
else if ( !c.Recurring_Case__c && oldc.Recurring_Case__c){ // if case is recuring before update and now recuring is unchecked
if(c.Recurring_Frequency__c != null && c.Initial_Due_Date__c != null && c.Initial_Due_Date__c != oldC.Initial_Due_Date__c ){
// still initial duedate and frequency is there
lstRecurringCase.add(c);
slalstNewCase.add(c);
lstType.add(c.Type);
lstSubType.add(c.IM_Case_Sub_Type__c);
}
if( c.Recurring_Frequency__c == null && c.Initial_Due_Date__c == null ){
// case change from recuring to nonrecuring
lstType.add(c.Type);
lstSubType.add(c.IM_Case_Sub_Type__c);
lstNonRecurringCase.add(c);
slalstNewCase.add(c);
}  
}
else{ 
if( !c.Recurring_Case__c && c.Recurring_Frequency__c == null && c.Initial_Due_Date__c == null && ( c.Type != oldC.Type || c.IM_Case_Sub_Type__c != oldc.IM_Case_Sub_Type__c )){
// non recuring case update
lstType.add(c.Type);
lstSubType.add(c.IM_Case_Sub_Type__c);
lstNonRecurringCase.add(c);
slalstNewCase.add(c);
}  
}            
}
}  */      
                    }
                    /* if(slalstNewCase.size() >0){      
// Get Sla Matrix sla days of the Cases
List<SLA_Matrix__c> lstSLAMatrix=[Select s.Type__c, s.SLA_Days__c, s.Id, s.Case_Subtype__c,Record_type__C From SLA_Matrix__c s where s.Type__c in:lstType and Case_Subtype__c in:lstSubType];
// Check the Initial due date is valid or not for recuring case
System.debug('lstRecurringCase.size():'+lstRecurringCase.size());
if(lstRecurringCase.size() > 0){
for( Case recCase : lstRecurringCase){                      
if(UtilUpdateSladaysAndSlaTargetDate.isInitialDueDateOnHoliday(recCase)){
// initial due date falls on a market holiday schedule or weekend
recCase.addError('The initial due date you entered falls on a market holiday or on a weekend day - please update');
}
else
{// 
String caseRecordType='';
caseRecordType = mapCaseRecordType.get(recCase.RecordTypeId);
if(!lstSLAMatrix.isEmpty() &&lstSLAMatrix.size() > 0){
for(SLA_Matrix__c sla : lstSLAMatrix){
if(sla.Record_Type__c == caseRecordType && sla.Type__c == recCase.Type && sla.Case_Subtype__c == recCase.IM_Case_Sub_Type__c){
double  dbSladay = sla.SLA_Days__c;
DateTime createdDate = DateTime.now();
if(trigger.isUpdate)
createdDate = recCase.CreatedDate;
Date dtNowSlaDay = UtilUpdateSladaysAndSlaTargetDate.getSlaTargetDateForSingleCase(recCase,dbSladay,createdDate); 
if( dtNowSlaDay > recCase.Initial_Due_Date__c ){
recCase.addError('The SLA (Days) needed for this case type exceeds the Initial Due Date requested by the customer please enter an initial due date equal or past   <date(now) + SLA Days> to allow time for this case to be processed.');
continue;
}
}
}
}

}
}           
}
// Code to update case sla days         
for( case c : slalstNewcase){
String caseRecordType='';
// Code for update Sla Days
if(c.Recurring_Case__c  ){
Date initialdate = c.Initial_Due_Date__c;
Date dtCreatedDate = Date.today();
if(Trigger.isUpdate){
DateTime dt=c.CreatedDate;
dtCreatedDate =Date.newInstance(dt.year(), dt.month(), dt.Day());
}
c.SLA_Days__c = dtCreatedDate.daysBetween(initialdate);                
}
else {               
caseRecordType = mapCaseRecordType.get(c.RecordTypeId);
for(SLA_Matrix__c sla : lstSLAMatrix){
if(sla.Record_Type__c == caseRecordType && sla.Type__c == c.Type && sla.Case_Subtype__c == c.IM_Case_Sub_Type__c){
c.SLA_Days__c = sla.SLA_Days__c;                     
break;
}                            
}
}
}


}   */   
                    
                    // Code for update Sla target date    
                    //  updateslatargetdate();
                }
            } 
        }
        
        /****UPDATE SLA DAYS SLA TARGET DATE AND VALIDATION INITIAL DUE DATE****/
        /*---end---*/
        
        /****SET ORIGINAL FIELDS****/
        /*---start---*/
        /* commented as part of user story #27072
        if(SetOriginalfields=='True'){
            if(runSetOrgfields==true){            
                // Look up record type names
                for (Case c :trigger.new) {
                    if ((null != c.RecordTypeId) && !recordTypes.contains(c.recordTypeId)) {
                        recordTypes.add(c.RecordTypeId);
                    }
                }
                //if(!recordTypes.isEmpty() && recordTypes.size() > 0){
                map<Id, Schema.RecordTypeInfo> recordType_Map = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById();
                for(Case newCase :trigger.new){
                    if ((newCase.orig_record_type__c == null) && (newCase.IM_Case_Sub_type__c != null)) {
                        String recordTypeName = '';
                        if ((newCase.RecordTypeId != null) && recordType_Map.containsKey(newCase.RecordTypeId)) {
                            recordTypeName = recordType_Map.get(newcase.RecordTypeId).Name;
                        }
                        newCase.Orig_record_type__c = recordTypeName ;
                        newCase.Orig_case_subtype__c = newCase.IM_case_sub_type__c ;
                        newCase.Orig_assigned_team__c = newCase.Assigned_team__c ;
                        newCase.Orig_type__c = newCase.type ;
                    }
                }
                //}
            }
        }
        */ //commented as part of user story #27072
        /****SET ORIGINAL FIELDS****/
        /*---end---*/
        
        /****NCSP DATE VALIDATION RULES****/
        /*---start---*/
        // Name:NCSPDateValidationRulesTrigger
        // Description: Trigger to check key date/time fields for NCSP Cases. 
        // Trigger performs validation to ensure date/time fields that are entered – are entered with correct tense.  Past, Future, Current. 
        // Created By: Vinod Kumar (Appirio)
        // Last Modified: November 10, 2010
        /* if(NCSPDateValidationRulesTrigger=='True'){
if(runNCSPValRuleTri==true){
if(triggerFlowControl.triggerRunCount('NCSPDateValidationRulesTrigger') <= 1){
fillRecordTypeIds();
for(Case newCase : trigger.new) {
Case oldCase = null;
if( !insTrig ) {
oldCase = Trigger.oldMap.get(newCase.Id);
}
if ( SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #01
&& newCase.X2nd_Sales_Resubmission_Date__c != null 
&& getDate(newCase.X2nd_Sales_Resubmission_Date__c) > sysToday
&& (insTrig || newCase.X2nd_Sales_Resubmission_Date__c != oldCase.X2nd_Sales_Resubmission_Date__c )) {
newCase.X2nd_Sales_Resubmission_Date__c.addError('2nd Sales Resubmission Date cannot be a date in the Future.');
}        
// created the new rule as mention in PR-08567
if (  SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) //    
&& newCase.Date_Sent_to_Contracts_Admin__c != null 
&& getDate(newCase.Date_Sent_to_Contracts_Admin__c) != sysToday
&& (insTrig || newCase.Date_Sent_to_Contracts_Admin__c != oldCase.Date_Sent_to_Contracts_Admin__c )) {
newCase.Date_Sent_to_Contracts_Admin__c.addError('Date Sent to Contracts Admin must be a current date only (cannot be a past or future)');
}
// created the new rule as mention in PR-08567
if (  SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) //    
&& newCase.Date_Contract_Approved__c != null 
&& getDate(newCase.Date_Contract_Approved__c) != sysToday
&& (insTrig || newCase.Date_Contract_Approved__c != oldCase.Date_Contract_Approved__c )) {
newCase.Date_Contract_Approved__c.addError('Date Contract Approved must be a current date only (cannot be a past or future)');
} 
// End of changes made by vinod for PR-08567
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)||NCSP_New_Customer_RecordTypeIds.contains(newCase.RecordTypeId)) // #04
&& newCase.Date_On_Boarder_CSA_Assigned__c != null 
&& getDate(newCase.Date_On_Boarder_CSA_Assigned__c) < sysToday
&& (insTrig || newCase.Date_On_Boarder_CSA_Assigned__c != oldCase.Date_On_Boarder_CSA_Assigned__c )) {
newCase.Date_On_Boarder_CSA_Assigned__c.addError('Date On Boarder CSA Assigned cannot be a date in the Past.');
}        
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #05
&& newCase.Date_Welcome_Call_Attempt_1__c != null 
&& getDate(newCase.Date_Welcome_Call_Attempt_1__c) != sysToday
&& (insTrig || newCase.Date_Welcome_Call_Attempt_1__c != oldCase.Date_Welcome_Call_Attempt_1__c )) {
newCase.Date_Welcome_Call_Attempt_1__c.addError('Date Welcome Call Attempt 1 must be today\'s date. It cannot be in the Past or the Future.');
} 
//added 12/2/12
//Developer Name: Madhu Paladugu
//Case number:00593195
//added the logic to add two new record types
if (NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId) // #17
&& newCase.Shred_Date_Visit_Profile_Modified__c!= null 
&& getDate(newCase.Shred_Date_Visit_Profile_Modified__c) != sysToday
&& (insTrig || newCase.Shred_Date_Visit_Profile_Modified__c != oldCase.Shred_Date_Visit_Profile_Modified__c )) {
newCase.Shred_Date_Visit_Profile_Modified__c.addError('Shred - Date Visit Profile Modified  must be today\'s date. It cannot be in the Past or the Future.');
}    
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #06
&& newCase.Date_Welcome_Call_Attempt_2__c != null 
&& getDate(newCase.Date_Welcome_Call_Attempt_2__c) != sysToday
&& (insTrig || newCase.Date_Welcome_Call_Attempt_2__c != oldCase.Date_Welcome_Call_Attempt_2__c )) {
newCase.Date_Welcome_Call_Attempt_2__c.addError('Date Welcome Call Attempt 2 must be today\'s date. It cannot be in the Past or the Future.');
}        
if ( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #07
&& newCase.Date_Welcome_Call_Attempt_3__c != null 
&& getDate(newCase.Date_Welcome_Call_Attempt_3__c) != sysToday
&& (insTrig || newCase.Date_Welcome_Call_Attempt_3__c != oldCase.Date_Welcome_Call_Attempt_3__c )) {
newCase.Date_Welcome_Call_Attempt_3__c.addError('Date Welcome Call Attempt 3 must be today\'s date. It cannot be in the Past or the Future.');
}         
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if (( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId) )// #08
&& newCase.Date_welcome_call_completed__c != null 
&& getDate(newCase.Date_welcome_call_completed__c) != sysToday
&& (insTrig || newCase.Date_welcome_call_completed__c != oldCase.Date_welcome_call_completed__c )) {
newCase.Date_welcome_call_completed__c.addError('Date Welcome Call Completed must be today\'s date. It cannot be in the Past or the Future.');
}         
if ( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #09
&& newCase.IMC_Login_sent_to_customer__c != null 
&& getDate(newCase.IMC_Login_sent_to_customer__c) != sysToday
&& (insTrig || newCase.IMC_Login_sent_to_customer__c != oldCase.IMC_Login_sent_to_customer__c )) {
newCase.IMC_Login_sent_to_customer__c.addError('IMC Login Sent to Customer must be today\'s date. It cannot be in the Past or the Future.');
}        
if ( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #10
&& newCase.IMC_Setup_Date__c != null 
&& getDate(newCase.IMC_Setup_Date__c) != sysToday
&& (insTrig || newCase.IMC_Setup_Date__c != oldCase.IMC_Setup_Date__c )) {
newCase.IMC_Setup_Date__c.addError('IMC Setup Date has to be today\'s date. It cannot be in the Past or the Future.');
}        
// Below If condition is Commented by gouthami for case #10709618  on 27th July 19

//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if (( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #11
&& newCase.Initial_Supply_Order_Date__c != null 
&& getDate(newCase.Initial_Supply_Order_Date__c) != sysToday
&& (insTrig || newCase.Initial_Supply_Order_Date__c != oldCase.Initial_Supply_Order_Date__c )) {
newCase.Initial_Supply_Order_Date__c.addError('Initial Supply Order Date must be today\'s date. It cannot be in the Past or the Future.');
} 
*                         
if ( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #12
&& newCase.Rejected_Contract_Resubmission_Date__c != null 
&& getDate(newCase.Rejected_Contract_Resubmission_Date__c) != sysToday
&& (insTrig || newCase.Rejected_Contract_Resubmission_Date__c != oldCase.Rejected_Contract_Resubmission_Date__c )) {
newCase.Rejected_Contract_Resubmission_Date__c.addError('Rejected Contract Resubmission Date mst be today\'s date. It cannot be in the Past or the Future.');
}         
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId) )// #13
&& newCase.Service_Completion_Date__c != null 
&& getDate(newCase.Service_Completion_Date__c) > sysToday
&& (insTrig || newCase.Service_Completion_Date__c != oldCase.Service_Completion_Date__c )) {
newCase.Service_Completion_Date__c.addError('Service Completion Date cannot be a date in the Future.');
}        
// Below If condition is Commented by gouthami for case #10709618 on 27th July 19

//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #14
&& newCase.Service_Order_Date__c != null 
&& getDate(newCase.Service_Order_Date__c) != sysToday
&& (insTrig || newCase.Service_Order_Date__c != oldCase.Service_Order_Date__c )) {
newCase.Service_Order_Date__c.addError('Service Order Date must be today\'s date. It cannot be in the Past or the Future.');
} 


// Below If condition is Commented by gouthami for case #10709618  on 27th July 19

//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if (( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId) )// #15
&& newCase.Service_Schedule_Date__c != null 
&& ( getDate(newCase.Service_Schedule_Date__c) < sysToday )//||getDate(newCase.Service_Schedule_Date__c) == sysToday)
&& (insTrig || newCase.Service_Schedule_Date__c != oldCase.Service_Schedule_Date__c )) {
newCase.Service_Schedule_Date__c.addError('Service Schedule Date must be Today or a Future date. It cannot be in the Past.');
}  

if ( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #16
&& newCase.Date_Shred_Visit_Profile_Created__c != null 
&& getDate(newCase.Date_Shred_Visit_Profile_Created__c) != sysToday
&& (insTrig || newCase.Date_Shred_Visit_Profile_Created__c != oldCase.Date_Shred_Visit_Profile_Created__c )) {
newCase.Date_Shred_Visit_Profile_Created__c.addError('Shred - Date Visit Profile Created must be today\'s date. It cannot be in the Past or the Future.');
}    
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #17
&& newCase.Transition_Date__c != null 
&& getDate(newCase.Transition_Date__c) != sysToday
&& (insTrig || newCase.Transition_Date__c != oldCase.Transition_Date__c )) {
newCase.Transition_Date__c.addError('Transition Date must be today\'s date. It cannot be in the Past or the Future.');
}     
Developer Name: Madhu Paladugu
Case Number   : 01159965
Description   : Added variable to hold recordtypes for INVOICE_REVIEW_DATE Validation

if (NCSP_INVOICE_DATE_RecTypeIds.contains(newCase.RecordTypeId) 
&& newCase.Invoice_Review_date__c != null 
&& getDate(newCase.Invoice_Review_date__c) != sysToday
&& (insTrig || newCase.Invoice_Review_date__c != oldCase.Invoice_Review_date__c )) {
newCase.Invoice_Review_date__c.addError('Invoice Review date must be today\'s date. It cannot be in the Past or the Future.');
}      
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId) ||NCSP_New_Customer_RecordTypeIds.contains(newCase.RecordTypeId) )// #18
&& newCase.Welcome_Packet_Sent_Date__c != null 
&& getDate(newCase.Welcome_Packet_Sent_Date__c) != sysToday
&& (insTrig || newCase.Welcome_Packet_Sent_Date__c != oldCase.Welcome_Packet_Sent_Date__c )) {
newCase.Welcome_Packet_Sent_Date__c.addError('Welcome Packet Sent Date must be today\'s date. It cannot be in the Past or the Future.');
System.debug('-------1111 loop-----');
}
if ( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #20
&& newCase.Date_Contract_Signed__c != null 
&& getDate(newCase.Date_Contract_Signed__c) > sysToday
&& (insTrig || newCase.Date_Contract_Signed__c != oldCase.Date_Contract_Signed__c )) {
newCase.Date_Contract_Signed__c.addError('Date Contract Signed cannot be a date in the Future.');
}        
if ( SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #21
&& newCase.Date_Contracts_CSA_Assigned__c != null 
&& getDate(newCase.Date_Contracts_CSA_Assigned__c) < sysToday
&& (insTrig || newCase.Date_Contracts_CSA_Assigned__c != oldCase.Date_Contracts_CSA_Assigned__c )) {
newCase.Date_Contracts_CSA_Assigned__c.addError('Date Contracts CSA Assigned cannot be a date in the past.');
}       
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId) ||NCSP_New_Customer_RecordTypeIds.contains(newCase.RecordTypeId))// #22
&& newCase.Date_Contract_Signed__c != null && newCase.Date_Paperwork_Received__c != null
&& getDate(newCase.Date_Paperwork_Received__c) > sysToday
&& (insTrig || newCase.Date_Paperwork_Received__c != oldCase.Date_Paperwork_Received__c )) {
newCase.Date_Paperwork_Received__c.addError('Date Paperwork Received cannot be a date in the Future.');


}        
if ( SKP_DEPT_ADD_RecTypeIds.contains(newCase.RecordTypeId) // #22 Updated for Dept add only
&& newCase.Date_Paperwork_Received__c != null
&& getDate(newCase.Date_Paperwork_Received__c) > sysToday
&& (insTrig || newCase.Date_Paperwork_Received__c != oldCase.Date_Paperwork_Received__c )) {
newCase.Date_Paperwork_Received__c.addError('Date Paperwork Received cannot be a date in the Future.');

}     

if ( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #23
&& newCase.Date_Reviewed_Ncsp__c != null 
&& getDate(newCase.Date_Reviewed_Ncsp__c) != sysToday
&& (insTrig || newCase.Date_Reviewed_Ncsp__c != oldCase.Date_Reviewed_Ncsp__c )) {
newCase.Date_Reviewed_Ncsp__c.addError('Date Reviewed - NCSP must be today\'s date.  It cannot be in the Past or the Future.');
}        
if ( SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId) // #24
&& newCase.Sales_Resubmission_Date__c != null 
&& getDate(newCase.Sales_Resubmission_Date__c) > sysToday
&& (insTrig || newCase.Sales_Resubmission_Date__c != oldCase.Sales_Resubmission_Date__c )) {
newCase.Sales_Resubmission_Date__c.addError('Sales Resubmission Date cannot be a date in the Future.');
}        
if ( DP_RecTypeIds.contains(newCase.RecordTypeId) // #25
&& newCase.SecureSync_Setup_Date__c != null 
&& getDate(newCase.SecureSync_Setup_Date__c) > sysToday
&& (insTrig || newCase.SecureSync_Setup_Date__c != oldCase.SecureSync_Setup_Date__c )) {
newCase.SecureSync_Setup_Date__c.addError('SecureSync Setup Date must be today\'s or past date. It cannot be the Future.');
}       
if ( DP_RecTypeIds.contains(newCase.RecordTypeId) // #26
&& newCase.SecureSync_Training_Completed__c != null 
&& getDate(newCase.SecureSync_Training_Completed__c) > sysToday
&& (insTrig || newCase.SecureSync_Training_Completed__c != oldCase.SecureSync_Training_Completed__c )) {
newCase.SecureSync_Training_Completed__c.addError('SecureSync Training Completed must be today\'s date or past date. It cannot be the Future.');
}       
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if (( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #27
&& newCase.Service_Reschedule_Date__c != null 
&& getDate(newCase.Service_Reschedule_Date__c) < sysToday
&& (insTrig || newCase.Service_Reschedule_Date__c != oldCase.Service_Reschedule_Date__c )) {
newCase.Service_Reschedule_Date__c.addError('Service Reschedule date cannot be a date in the Past.');
}          
//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types
if ( (SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #28
&& newCase.Supplies_Delivered_Date__c != null 
&& getDate(newCase.Supplies_Delivered_Date__c) > sysToday
&& (insTrig || newCase.Supplies_Delivered_Date__c != oldCase.Supplies_Delivered_Date__c )) {
newCase.Supplies_Delivered_Date__c.addError('Supplies Delivered Date cannot be a date in the Future.');
} 
// Below If condition is Commented by gouthami for case #10709618  on 27th July 19

//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types          
if (( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId)) // #29    
&& newCase.Supplies_Scheduled_Date__c != null 
&& getDate(newCase.Supplies_Scheduled_Date__c) < sysToday
&& (insTrig || newCase.Supplies_Scheduled_Date__c != oldCase.Supplies_Scheduled_Date__c )) {
newCase.Supplies_Scheduled_Date__c.addError('Supplies Scheduled Date cannot be a date in the Past.');
}

//#8977 Delete 11 NCSP case field deletion (6/3/2022) :- Part 1 "Supply_Reschedule_Date__c" commented by Nandini Mishra to remove field dependency for this field

//Developer Name: Madhu Paladugu
//Case number:00593195
//Changed the logic to add two new record types        
if (( SKP_SKP_DP_DMS_RecTypeIds.contains(newCase.RecordTypeId)||NCSP_Upsell_RecordTypeIds.contains(newCase.RecordTypeId))// #30
&& newCase.Supply_Reschedule_Date__c != null 
&& getDate(newCase.Supply_Reschedule_Date__c) < sysToday
&& (insTrig || newCase.Supply_Reschedule_Date__c != oldCase.Supply_Reschedule_Date__c )) {
newCase.Supply_Reschedule_Date__c.addError('Supply Reschedule Date cannot be a date in the Past.');
} 


if ( NCSP_TECH_RecTypeIds.contains(newCase.RecordTypeId)){          
if(newCase.Date_On_Boarder_CSA_Assigned__c != null 
&& getDate(newCase.Date_On_Boarder_CSA_Assigned__c) < sysToday
&& (insTrig || newCase.Date_On_Boarder_CSA_Assigned__c != oldCase.Date_On_Boarder_CSA_Assigned__c )) {
newCase.Date_On_Boarder_CSA_Assigned__c.addError('Date On Boarder CSA Assigned cannot be a date in the Past.');
}       

if(newCase.X2nd_Sales_Resubmission_Date__c != null 
&& getDate(newCase.X2nd_Sales_Resubmission_Date__c) > sysToday
&& (insTrig || newCase.X2nd_Sales_Resubmission_Date__c != oldCase.X2nd_Sales_Resubmission_Date__c )) {
newCase.X2nd_Sales_Resubmission_Date__c.addError('2nd Sales Resubmission Date cannot be a date in the Future.');
} 
if(newCase.Date_Sent_to_Contracts_Admin__c != null 
&& getDate(newCase.Date_Sent_to_Contracts_Admin__c) != sysToday
&& (insTrig || newCase.Date_Sent_to_Contracts_Admin__c != oldCase.Date_Sent_to_Contracts_Admin__c )) {
newCase.Date_Sent_to_Contracts_Admin__c.addError('Date Sent to Contracts Admin must be a current date only (cannot be a past or future)');
}

if (newCase.Date_Contract_Approved__c != null 
&& getDate(newCase.Date_Contract_Approved__c) != sysToday
&& (insTrig || newCase.Date_Contract_Approved__c != oldCase.Date_Contract_Approved__c )) {
newCase.Date_Contract_Approved__c.addError('Date Contract Approved must be a current date only (cannot be a past or future)');
} 


if (newCase.Date_Welcome_Call_Attempt_1__c != null 
&& getDate(newCase.Date_Welcome_Call_Attempt_1__c) != sysToday
&& (insTrig || newCase.Date_Welcome_Call_Attempt_1__c != oldCase.Date_Welcome_Call_Attempt_1__c )) {
newCase.Date_Welcome_Call_Attempt_1__c.addError('Date Welcome Call Attempt 1 must be today\'s date. It cannot be in the Past or the Future.');
}        
if (newCase.Date_Welcome_Call_Attempt_2__c != null 
&& getDate(newCase.Date_Welcome_Call_Attempt_2__c) != sysToday
&& (insTrig || newCase.Date_Welcome_Call_Attempt_2__c != oldCase.Date_Welcome_Call_Attempt_2__c )) {
newCase.Date_Welcome_Call_Attempt_2__c.addError('Date Welcome Call Attempt 2 must be today\'s date. It cannot be in the Past or the Future.');
}  
if (newCase.Date_Welcome_Call_Attempt_3__c != null 
&& getDate(newCase.Date_Welcome_Call_Attempt_3__c) != sysToday
&& (insTrig || newCase.Date_Welcome_Call_Attempt_3__c != oldCase.Date_Welcome_Call_Attempt_3__c )) {
newCase.Date_Welcome_Call_Attempt_3__c.addError('Date Welcome Call Attempt 3 must be today\'s date. It cannot be in the Past or the Future.');
}        
if (newCase.Date_welcome_call_completed__c != null 
&& getDate(newCase.Date_welcome_call_completed__c) != sysToday
&& (insTrig || newCase.Date_welcome_call_completed__c != oldCase.Date_welcome_call_completed__c )) {
newCase.Date_welcome_call_completed__c.addError('Date Welcome Call Completed must be today\'s date. It cannot be in the Past or the Future.');
}      

if (newCase.Transition_Date__c != null 
&& getDate(newCase.Transition_Date__c) != sysToday
&& (insTrig || newCase.Transition_Date__c != oldCase.Transition_Date__c )) {
newCase.Transition_Date__c.addError('Transition Date must be today\'s date. It cannot be in the Past or the Future.');
}       
if (newCase.Welcome_Packet_Sent_Date__c != null 
&& getDate(newCase.Welcome_Packet_Sent_Date__c) != sysToday
&& (insTrig || newCase.Welcome_Packet_Sent_Date__c != oldCase.Welcome_Packet_Sent_Date__c )) {
newCase.Welcome_Packet_Sent_Date__c.addError('Welcome Packet Sent Date must be today\'s date. It cannot be in the Past or the Future.');
System.debug('---1260--loop--:');
}         

if (newCase.Date_Contract_Signed__c != null 
&& getDate(newCase.Date_Contract_Signed__c) > sysToday
&& (insTrig || newCase.Date_Contract_Signed__c != oldCase.Date_Contract_Signed__c )) {
newCase.Date_Contract_Signed__c.addError('Date Contract Signed cannot be a date in the Future.');
}       
if (newCase.Date_Contracts_CSA_Assigned__c != null 
&& getDate(newCase.Date_Contracts_CSA_Assigned__c) < sysToday
&& (insTrig || newCase.Date_Contracts_CSA_Assigned__c != oldCase.Date_Contracts_CSA_Assigned__c )) {
newCase.Date_Contracts_CSA_Assigned__c.addError('Date Contracts CSA Assigned cannot be a date in the past.');
}    
if (newCase.Date_Reviewed_Ncsp__c != null 
&& getDate(newCase.Date_Reviewed_Ncsp__c) != sysToday
&& (insTrig || newCase.Date_Reviewed_Ncsp__c != oldCase.Date_Reviewed_Ncsp__c )) {
newCase.Date_Reviewed_Ncsp__c.addError('Date Reviewed - NCSP must be today\'s date.  It cannot be in the Past or the Future.');
}    
if (newCase.Sales_Resubmission_Date__c != null 
&& getDate(newCase.Sales_Resubmission_Date__c) > sysToday
&& (insTrig || newCase.Sales_Resubmission_Date__c != oldCase.Sales_Resubmission_Date__c )) {
newCase.Sales_Resubmission_Date__c.addError('Sales Resubmission Date cannot be a date in the Future.');
}   
}       
if (newCase.Date_1st_Restricted_Party_Screening__c != null 
&& (newCase.Date_1st_Restricted_Party_Screening__c) > sysToday
&& (insTrig || newCase.Date_1st_Restricted_Party_Screening__c != oldCase.Date_1st_Restricted_Party_Screening__c )) {
newCase.Date_1st_Restricted_Party_Screening__c.addError('Date 1st Restricted Party Screening Date cannot be a date in the Future.');
}   

if (newCase.Date_2nd_Restricted_Party_Screening__c != null 
&& (newCase.Date_2nd_Restricted_Party_Screening__c) > sysToday
&& (insTrig || newCase.Date_2nd_Restricted_Party_Screening__c != oldCase.Date_2nd_Restricted_Party_Screening__c )) {
newCase.Date_2nd_Restricted_Party_Screening__c.addError('Date 2nd Restricted Party Screening Date cannot be a date in the Future.');
} 



if (newCase.Date_Order_Fulfillment_Sent__c != null 
&& ((newCase.Date_Order_Fulfillment_Sent__c) <> sysToday)
&& (insTrig || newCase.Date_Order_Fulfillment_Sent__c != oldCase.Date_Order_Fulfillment_Sent__c )) {

newCase.Date_Order_Fulfillment_Sent__c.addError('Date Order Fulfillment Sent Date cannot be a date in the Past or Future.');
}  

if ( newCase.Date_2nd_Order_Fulfillment_Sent__c != null 
&& (newCase.Date_2nd_Order_Fulfillment_Sent__c) > sysToday 
&& (insTrig || newCase.Date_2nd_Order_Fulfillment_Sent__c != oldCase.Date_2nd_Order_Fulfillment_Sent__c )) {
newCase.Date_2nd_Order_Fulfillment_Sent__c.addError('Date 2nd Order Fulfillment Sent Date cannot be a date in the Future.');
} 

if ( newCase.Date_Confirmation_Fulfillment_Received__c != null 
&& (newCase.Date_Confirmation_Fulfillment_Received__c) > sysToday 
&& (insTrig || newCase.Date_Confirmation_Fulfillment_Received__c != oldCase.Date_Confirmation_Fulfillment_Received__c )) {
newCase.Date_Confirmation_Fulfillment_Received__c.addError('Date Confirmation Fulfillment Received Date cannot be a date in the Future.');
}  
if ( newCase.Date_Paperwork_Received__c != null 
&& getDate(newCase.Date_Paperwork_Received__c) > sysToday 
&& (insTrig || newCase.Date_Paperwork_Received__c != oldCase.Date_Paperwork_Received__c )) {
newCase.Date_Paperwork_Received__c.addError('Date Paperwork Received cannot be a date in the Future.');
}
//Developer Name: Srinu Mandalapu
//Case # 01413555
//Description: NCSP Case TCM Date Validation
// System.debug('---------NCSP New Customer Setup RT Contains:'+NCSP_New_Customer_RecordTypeIds.contains(newCase.RecordTypeId));
if(NCSP_New_Customer_RecordTypeIds.contains(newCase.RecordTypeId) 
&& newCase.Date_TCM_User_Created__c != null 
&& getDate(newCase.Date_TCM_User_Created__c) > sysToday 
&& (insTrig || newCase.Date_TCM_User_Created__c != oldCase.Date_TCM_User_Created__c )) {
newCase.Date_TCM_User_Created__c.addError('Date TCM User Created cannot be a date in the Future.');
} 
if(NCSP_New_Customer_RecordTypeIds.contains(newCase.RecordTypeId) 
&& newCase.Date_TCM_Setup_Completed__c != null 
&& getDate(newCase.Date_TCM_Setup_Completed__c) != sysToday 
&& (insTrig || newCase.Date_TCM_Setup_Completed__c != oldCase.Date_TCM_Setup_Completed__c)){
newCase.Date_TCM_Setup_Completed__c.addError('Date TCM Setup Completed must be today\'s date. It cannot be in the Past or the Future.');
}       

}
}
}
}  */
        /****NCSP DATE VALIDATION RULES****/
        /*---end---*/
        
        /****NCSP PREVENT PARENT CASE CLOSURE****/
        /*---start---*/
        // Description: To restrict to close a Parent Cases that still have open child cases cannot be closed
        // Created By: Vinod Kumar
        
        // ************************Version Updates********************************************
        //
        // Updated Date     Updated By      Update Comments 
        //  
        // CUSTOMER HAS DECIDED AFTER DEMO THAT THEY NO LONGER NEED THIS 
        // 11/04/2010        Venkat Subramanian Bev clarified that we need this for NCSP. So changing the name from Issue_Task to NCSP and Modified the code to reflect NCSP Record types.
        // ************************************************************************************
        //commented as part of user story #27072
        /*if(NCSP_Prevent_ParentCase_Closure=='True'){
            // To restrict ParentCaseClosureValidService class to run only in update condition
            // Modified By gouthami for case 11124616 on 24.09.2019 (BCT Consulting)
            if(Trigger.isUpdate){
                if(runNCSPpreventparent==true){
                    ParentCaseClosureValidService parentClosureValidation = new ParentCaseClosureValidService(trigger.new, trigger.oldMap);
                    parentClosureValidation.validate();
                }
            }
        }*/
        //commented as part of user story #27072
        /****NCSP PREVENT PARENT CASE CLOSURE****/
        /*---end---*/
        
        /****UPDATE ACCOUNT ID****/
        /*---start---*/
        // Name:UpdateAccountId
        // Description: To update the case account 
        // Created By: Vinod Kumar
        /* commented as part of user story #27072
        if(UpdateAccountId=='True'){
            if(runUpdateAccountId==true){
                
                updatefillRecordTypeIds();
                for(Case c:Trigger.new){
                    if(c.Customer_ID__c != null && updaterecordTypeIds.contains(c.RecordTypeId)){
                        CustomerID.add(c.Customer_ID__c);       
                    }
                }
                if(CustomerID.size() > 0){
                    List<IM_Customer_Account__c> lstCustomerAccount = [Select Id, IM_Account__c From IM_Customer_Account__c where id in:CustomerID];
                    Map<ID,ID> mapCustomerAcount = new Map<ID,ID>();
                    for(IM_Customer_Account__c ca:lstCustomerAccount){
                        mapCustomerAcount.put(ca.id,ca.IM_Account__c);
                    }
                    for(Case c:Trigger.new){
                        if(c.Customer_ID__c != null && mapCustomerAcount.containsKey(c.Customer_ID__c) ){
                            c.AccountId = mapCustomerAcount.get(c.Customer_ID__c);   
                        }
                    }
                }
                
            }
        }*/ //commented as part of user story #27072
        /****UPDATE ACCOUNT ID****/
        /*---end---*/
        
        /*********************************************AFTER INSERT AND UPDATE***************************************/
        if(Trigger.isAfter){
            
            if(Trigger.isInsert){
                
                runIssueTask=true;
                
                if(UpdateNCSPStatus=='True')
                    runUpdateNCSPStatus=true;
                
                /****NCSP OPPORTUNITY UPDATE CASE****/
                /*---start---*/
                
                /**
*Author: NAGESH EARANTI
*Date: 07-11-2011

*Comments:
*updates NCSP Status on Opportunity if the case is created 
*from NCSP Opportunity 
*Developed as part of parent Case 00466019
*Additional code added as part of enhancements in reg to Cases 00434827 and 00401611
*Update related Opportunity when Contracrt Admin Status or Service_Schedule_Date 
*Service_Completion_Date changed.
*
*Modified: RAJ ROHIT GOTTIPOLU
*Date: 04-23-2012
*With reference to Case 00535006 and 00526183
**/
                //Developer Name:Madhu Paladugu
                //Modified the logic to update the Opportunity.
                /*commented as part of user story #27072 
                if(NCSP_OpportunityUpdate_Case=='True')
                {            
                    System.debug('NCSP Process CAse Owner Name>>>');
                    Id oppid = null;
                    List<Opportunity> oppToUpdate = new List<Opportunity>();
                    MaP<Id,Opportunity> oppMap=new MaP<Id,Opportunity>();
                    Group grp1 = [Select Type, Name, Id From Group where type='queue' and name = 'NCSP FIFO (First in First out)'];
                    Group grp2 = [Select Type, Name, Id From Group where type='queue' and name = 'Data Entry'];
                    Map<Id, Case> opptyMap = new Map<Id, Case>([select id, NCSP_Opportunity__r.Upsell_Customer_Id__c from Case where id in :Trigger.New]);
                    for (Case c : Trigger.new)
                    {
                        System.debug('CAse Owner Name>>>'+c.OwnerId);
                        
                        if(c.NCSP_Opportunity__c != null && (c.OwnerId==grp1.id || c.OwnerId==grp2.id))
                        {
                            System.debug('@@@@');
                            Opportunity o = new Opportunity(
                                id= c.NCSP_Opportunity__c,
                                NCSP_Status__c='Sent to NCSP');
                            
                            //oppToUpdate.add(o);
                            
                            if(!oppMap.containsKey(c.NCSP_Opportunity__c))  {
                                oppMap.put(c.NCSP_Opportunity__c,o);
                            } 
                        }                
                    }
                    /*if(!oppToUpdate.isEmpty()){

update oppToUpdate;
}*
                    if(!oppMap.isEmpty())
                    {
                        oppToUpdate.addAll(oppMap.values());
                    } 
                    /*Developer   :Madhu Paladugu
Case Number :01223756
Date        :3/11/13
Description :Adding opportunity validation errors.
*
                    try{
                        update oppToUpdate;
                    }
                    catch(DmlException ex){                  
                        Trigger.new[0].addError('The following error occurred while trying to update the associated opportunity record: '+'"'+ex.getMessage().substringAfterLast('FIELD_CUSTOM_VALIDATION_EXCEPTION, ').removeEnd(': []')+'"');
                    }
                }*/ //commented as part of user story #27072
                /****NCSP OPPORTUNITY UPDATE CASE****/
                /*---end---*/
            }
            
            if(Trigger.isUpdate){
                //madhu added logic on 12/14/12
                runIssueTask=true;
                
                if(UpdateNCSPStatus=='True')
                    runUpdateNCSPStatus=true;
                /****NCSP OPPORTUNITY UPDATE CASE****/
                /*---start---*/
                
                if(NCSP_OpportunityUpdate_Case=='True'){     
                    map<Id, Opportunity> OpportunityMap = new map<Id, Opportunity>();
                    List<Opportunity> updatedateopplist= new List<Opportunity>(); 
                    
                    //Developer Name: Madhu Paladugu
                    //Case number:00593195
                    //commented below query because var accountMap not been used any where
                    //Map<Id,Profile> accountMap = new Map<Id,Profile>([SELECT Id from Profile where Name in ('AS NCSP Coordinator','AS NCSP Management','AS NCSP CSA','Contract Admin NA', 'AS_Ops User','IM_Custom Sys Admin')]);
                    Id rec, dmsrec,NCSP_New_cust ;
                    List<Id> ncsprec = new list<Id>();
                    
                    map<Id, Schema.RecordTypeInfo> NCSPCaseRec_map = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById();
                    for(id recMapId : NCSPCaseRec_map.keyset()){
                        if(NCSPCaseRec_map.get(recMapId).Name  == 'NCSP: Tech Services New Customer Setup'){
                            rec = recMapId; 
                        }else{
                            if((NCSPCaseRec_map.get(recMapId).Name == 'NCSP: SKP New Customer Setup')|| (NCSPCaseRec_map.get(recMapId).Name == 'NCSP: SKP Department Add Only') || (NCSPCaseRec_map.get(recMapId).Name =='NCSP: DP New Customer Setup')){
                                ncsprec.add(recMapId);
                            }else{
                                if(NCSPCaseRec_map.get(recMapId).Name == 'NCSP: DMS'){
                                    dmsrec = recMapId;
                                }
                            }
                        }
                        if(NCSPCaseRec_map.get(recMapId).Name =='NCSP: New Customer Setup'){
                            NCSP_New_cust = recMapId;
                        }
                    }
                    List<Id>oppids = new List<Id>();
                    Id oppid=null;
                    List<Datetime> casedates = new List<Datetime>();
                    List<Opportunity>updateopplist = new List<Opportunity>();
                    for (Case c : Trigger.new)
                        oppids.add(c.NCSP_Opportunity__c);
                    
                    List<Case> caserecords =[SELECT id, Service_Completion_Date__c,Status, Service_Schedule_Date__c, Date_Order_Fulfillment_Sent__c, Date_Confirmation_Fulfillment_Received__c, Project_Start_Date__c, Project_Completion_Date__c, Contract_Status__c, NCSP_Opportunity__c, RecordTypeId,NCSP_Opportunity__r.NCSP_Status__c,NCSP_Opportunity__r.StageName FROM Case where NCSP_Opportunity__c !=null and IsDeleted != true and NCSP_Opportunity__c in :oppids order by CreatedDate ];
                    Map<Id, Opportunity> scheduledateopps = new Map<Id, Opportunity>([select Id,Service_Schedule_Date__c  from Opportunity where id in :oppids]);
                    system.debug('++++ scheduledateopps is +++ '+ scheduledateopps);
                    
                    Map<Id,Datetime> dates = new Map<Id, Datetime>();
                    List<Opportunity> oppToUpdate = new List<Opportunity>();
                    Integer i=0, j=0, k=0, m=0,losti=0;
                    //Developer Name: Madhu Paladugu
                    //Case number:00593195
                    //changed logic in trigger to update the stage of the opportunity based on the first associated case that satisfies the condition rather than the last case meeting the condition. 
                    for(Case c : Trigger.new){
                        Integer schseri=0,schecompi=0,contapri=0;
                        if(c.NCSP_Opportunity__c != null){
                            /*checking if the record type is any of NCSP: SKP New Customer Setup, NCSP: SKP Department Add Only or NCSP: DP New Customer Setup*/
                            if(c.RecordTypeId == ncsprec[0] || c.RecordTypeId == ncsprec[1] || c.RecordTypeId == ncsprec[2]){
                                for(Case caseAdmStadms: caserecords){
                                    if(caseAdmStadms.NCSP_Opportunity__c==c.NCSP_Opportunity__c && caseAdmStadms.RecordTypeId == ncsprec[0] || caseAdmStadms.RecordTypeId == ncsprec[1] || caseAdmStadms.RecordTypeId == ncsprec[2]){
                                        if(Trigger.oldMap.get(c.Id).Service_Completion_Date__c == null && c.Service_Completion_Date__c != null){
                                            
                                            for(Case caseConAdmSta: caserecords){ 
                                                if(caseConAdmSta.NCSP_Opportunity__c==c.NCSP_Opportunity__c){
                                                    if( caseConAdmSta.Service_Completion_Date__c != null ){
                                                        schecompi++;
                                                        break;           
                                                    }
                                                }
                                            }         
                                            /*if all the cases of this opportunity have service completion date*/
                                            if(schecompi!=0)
                                            {     
                                                Opportunity   o = new Opportunity(
                                                    id= c.NCSP_Opportunity__c,
                                                    StageName='7 - Closed',
                                                    IM_Reason_Lost__c=null,
                                                    Service_Completed_Entered_Date__c=null,
                                                    NCSP_Status__c='Service Completed'
                                                );
                                                
                                                if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                                    OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                                }
                                            }   
                                        }
                                    }
                                }
                            }
                            /*checking if the record type is NCSP: DMS*/
                            if(c.RecordTypeId == dmsrec)
                            {
                                for(Case caseConAdmStadms: caserecords)
                                {   
                                    if(caseConAdmStadms.NCSP_Opportunity__c==c.NCSP_Opportunity__c && caseConAdmStadms.RecordTypeId == dmsrec)
                                    {
                                        if(Trigger.oldMap.get(c.Id).Project_Start_Date__c == null && c.Project_Start_Date__c != null)// || (Trigger.oldMap.get(c.Id).Project_Completion_Date__c == null && c.Project_Completion_Date__c != null))
                                        {      
                                            for(Case caseConAdmStadatefull: caserecords)
                                            {      
                                                if(caseConAdmStadatefull.NCSP_Opportunity__c==c.NCSP_Opportunity__c)
                                                    
                                                    if( caseConAdmStadatefull.Project_Start_Date__c != null&&caseConAdmStadatefull.NCSP_Opportunity__r.NCSP_Status__c!='Service Scheduled')
                                                {
                                                    schseri++;
                                                    break;
                                                }
                                            }
                                            /*if all the cases of this opportunity have project start date*/
                                            if(schseri!=0)
                                            {
                                                Opportunity    o = new Opportunity(
                                                    id= c.NCSP_Opportunity__c,
                                                    StageName='7 - Closed',
                                                    IM_Reason_Lost__c=null,
                                                    Service_Completed_Entered_Date__c=null,
                                                    NCSP_Status__c='Service Scheduled'
                                                );
                                                
                                                if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                                    OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                                }
                                            }
                                        }
                                        if(Trigger.oldMap.get(c.Id).Project_Completion_Date__c == null && c.Project_Completion_Date__c != null)
                                        {      
                                            
                                            for(Case caseConAdmStadatefull: caserecords)
                                            {
                                                if(caseConAdmStadatefull.NCSP_Opportunity__c==c.NCSP_Opportunity__c){
                                                    
                                                    if( caseConAdmStadatefull.Project_Completion_Date__c != null )
                                                    {
                                                        schecompi++;
                                                        break;
                                                    }
                                                }
                                            }
                                            /*if all the cases of this opportunity have project completion date*/
                                            if(schecompi!=0)
                                            {
                                                Opportunity   o= new Opportunity(
                                                    id= c.NCSP_Opportunity__c,
                                                    StageName='7 - Closed',
                                                    IM_Reason_Lost__c=null,
                                                    Service_Completed_Entered_Date__c=null,
                                                    NCSP_Status__c='Service Completed'
                                                );
                                                if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                                    OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                                }
                                            }
                                            
                                        }
                                        
                                    }
                                }
                            }
                            if(c.RecordTypeId ==rec)
                            {
                                for(Case caseConAdmStanew: caserecords)
                                {  
                                    if(caseConAdmStanew.NCSP_Opportunity__c==c.NCSP_Opportunity__c && caseConAdmStanew.RecordTypeId == rec  )
                                    {
                                        if ((Trigger.oldMap.get(c.Id).Contract_Status__c != 'Accepted' && Trigger.oldMap.get(c.Id).Contract_Status__c != 'Accepted with Follow up' ) && (c.Contract_Status__c =='Accepted' || c.Contract_Status__c == 'Accepted with Follow up' ))
                                        {
                                            for(Case caseConAdmStacon : caserecords)
                                            {      
                                                if(caseConAdmStacon.NCSP_Opportunity__c == c.NCSP_Opportunity__c){
                                                    if( (caseConAdmStacon.Contract_Status__c == 'Accepted' || caseConAdmStacon.Contract_Status__c == 'Accepted with Follow up')  )
                                                    {
                                                        contapri++;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                        if(contapri!=0)
                                        {
                                            Opportunity   o = new Opportunity(
                                                id= c.NCSP_Opportunity__c,
                                                StageName='6 - Setup',
                                                IM_Reason_Lost__c=null,
                                                Service_Completed_Entered_Date__c=null,
                                                NCSP_Status__c='Contract Approved'
                                            );
                                            
                                            if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                                OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                            }
                                            
                                        }
                                        
                                        if ((Trigger.oldMap.get(c.Id).Contract_Status__c != 'Rejected' && Trigger.oldMap.get(c.Id).Contract_Status__c != 'Rejected with amendments') && (c.Contract_Status__c =='Rejected' || c.Contract_Status__c == 'Rejected with amendments'))
                                        {
                                            j=0;
                                            for(Case caseConAdmStaconre : caserecords)
                                            {
                                                if(caseConAdmStaconre.NCSP_Opportunity__c == c.NCSP_Opportunity__c && caseConAdmStaconre.Contract_Status__c != 'Rejected' && caseConAdmStaconre.Contract_Status__c != 'Rejected with amendments')
                                                {
                                                    j++;
                                                }
                                            }
                                            if(j==0)
                                            {
                                                Opportunity o = new Opportunity(
                                                    id= c.NCSP_Opportunity__c,
                                                    NCSP_Status__c='Rejected',
                                                    IM_Reason_Lost__c=null,
                                                    Service_Completed_Entered_Date__c=null,
                                                    StageName=null
                                                );
                                                if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                                    OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                                }
                                            }
                                        }
                                        if(Trigger.oldMap.get(c.Id).Date_Confirmation_Fulfillment_Received__c == null && c.Date_Confirmation_Fulfillment_Received__c != null)
                                        {      
                                            for(Case caseConAdmStadatefull : caserecords)
                                            {   
                                                if(caseConAdmStadatefull.NCSP_Opportunity__c == c.NCSP_Opportunity__c){
                                                    if( caseConAdmStadatefull.Date_Confirmation_Fulfillment_Received__c != null)
                                                    {
                                                        schecompi++;
                                                        break;
                                                    }
                                                }
                                            }
                                            if(schecompi!=0)
                                            {
                                                Opportunity   o = new Opportunity(
                                                    id= c.NCSP_Opportunity__c,
                                                    NCSP_Status__c='Service Completed',
                                                    StageName='7 - Closed',
                                                    IM_Reason_Lost__c=null,
                                                    Service_Completed_Entered_Date__c=Date.today() 
                                                );
                                                
                                                if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                                    OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                                }
                                            }
                                        }
                                        if(Trigger.oldMap.get(c.Id).Date_Order_Fulfillment_Sent__c== null && c.Date_Order_Fulfillment_Sent__c != null)
                                        {      
                                            for(Case caseConAdmStadateorder : caserecords)
                                            {  
                                                if(caseConAdmStadateorder.NCSP_Opportunity__c == c.NCSP_Opportunity__c){
                                                    if( caseConAdmStadateorder.Date_Order_Fulfillment_Sent__c != null&&caseConAdmStadateorder.NCSP_Opportunity__r.NCSP_Status__c!='Service Scheduled')
                                                    {
                                                        schseri++;
                                                        break;
                                                    }
                                                }
                                            }
                                            if(schseri!=0)
                                            {
                                                Opportunity   o = new Opportunity(
                                                    id= c.NCSP_Opportunity__c,
                                                    StageName='7 - Closed',
                                                    IM_Reason_Lost__c=null,
                                                    Service_Completed_Entered_Date__c=null,
                                                    NCSP_Status__c='Service Scheduled'
                                                );
                                                if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                                    OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                                }
                                            }
                                            
                                        }                                     
                                    }
                                }
                            }
                            if ((Trigger.oldMap.get(c.Id).Contract_Status__c != 'Accepted' && Trigger.oldMap.get(c.Id).Contract_Status__c != 'Accepted with Follow up'  ) && (c.Contract_Status__c =='Accepted' || c.Contract_Status__c == 'Accepted with Follow up' ))
                            { 
                                for(Case caseConAdmSta : caserecords)
                                { 
                                    if(caseConAdmSta.NCSP_Opportunity__c == c.NCSP_Opportunity__c){
                                        if( (caseConAdmSta.Contract_Status__c == 'Accepted' || caseConAdmSta.Contract_Status__c == 'Accepted with Follow up' ))
                                        {
                                            contapri++;
                                            break;
                                        }
                                    }
                                }
                                if(contapri!=0)
                                {
                                    Opportunity   o = new Opportunity(
                                        id= c.NCSP_Opportunity__c,
                                        StageName='6 - Setup',
                                        IM_Reason_Lost__c=null,
                                        Service_Completed_Entered_Date__c=null,
                                        NCSP_Status__c='Contract Approved'
                                    );
                                    if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                        OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                    }
                                }
                            }
                            if(Trigger.oldMap.get(c.Id).Contract_Status__c != 'Rejected' && c.Contract_Status__c =='Rejected')
                            {
                                for(Case caseConAdmSta : caserecords)
                                {
                                    if(caseConAdmSta.NCSP_Opportunity__c == c.NCSP_Opportunity__c && caseConAdmSta.Contract_Status__c != 'Rejected')
                                    {
                                        i++;
                                    }
                                }
                                if(i==0)
                                {
                                    Opportunity o = new Opportunity(
                                        id= c.NCSP_Opportunity__c,
                                        IM_Reason_Lost__c=null,
                                        Service_Completed_Entered_Date__c=null,
                                        stageName=null,
                                        NCSP_Status__c='Rejected'
                                    );
                                    if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                        OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                    }
                                }
                            }
                            /*only for cases that dont have record type NCSP: DMS*/
                            if(c.RecordTypeId !=dmsrec)
                            {
                                Opportunity opp = scheduledateopps.get(c.NCSP_Opportunity__c);
                                if((opp.Service_Schedule_Date__c < c.Service_Schedule_Date__c) || opp.Service_Schedule_Date__c ==null)
                                {
                                    if(!dates.containskey(c.NCSP_Opportunity__c))
                                        dates.put(c.NCSP_Opportunity__c, c.Service_Schedule_Date__c);
                                    else if(c.Service_Schedule_Date__c>dates.get(c.NCSP_Opportunity__c))
                                        dates.put(c.NCSP_Opportunity__c, c.Service_Schedule_Date__c);
                                    
                                }    
                                if(Trigger.oldMap.get(c.Id).Service_Schedule_Date__c == null && c.Service_Schedule_Date__c != null)
                                {
                                    for(Case caseConAdmSta : caserecords)
                                    {        
                                        if(caseConAdmSta.NCSP_Opportunity__c == c.NCSP_Opportunity__c ){
                                            if( caseConAdmSta.Service_Schedule_Date__c != null && caseConAdmSta.NCSP_Opportunity__r.NCSP_Status__c!='Service Scheduled')
                                            {
                                                schseri=1;
                                                break;
                                            }
                                        }
                                    }          
                                    if(schseri!=0)
                                    {
                                        Opportunity   o= new Opportunity(
                                            id= c.NCSP_Opportunity__c,
                                            StageName='7 - Closed',
                                            IM_Reason_Lost__c=null,
                                            Service_Completed_Entered_Date__c=null,
                                            NCSP_Status__c='Service Scheduled'
                                        );
                                        
                                        if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                            OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                        }
                                    }
                                }
                                if(Trigger.oldMap.get(c.Id).Service_Completion_Date__c == null && c.Service_Completion_Date__c != null)
                                {            
                                    for(Case caseConAdmSta : caserecords)
                                    { 
                                        
                                        if(caseConAdmSta.NCSP_Opportunity__c == c.NCSP_Opportunity__c){
                                            if( caseConAdmSta.Service_Completion_Date__c != null  )
                                            {
                                                schecompi++;
                                                break;
                                            }
                                        }
                                    }
                                    if(schecompi!=0)
                                    {
                                        Opportunity   o = new Opportunity(
                                            id= c.NCSP_Opportunity__c,
                                            StageName='7 - Closed',
                                            IM_Reason_Lost__c=null,
                                            NCSP_Status__c='Service Completed',
                                            Service_Completed_Entered_Date__c=Date.today() 
                                        );
                                        if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                            OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                        }
                                    }
                                }
                            }
                            
                            //Developer Name: Madhu Paladugu
                            //Case number:00593195          
                            // added the logic to update IM_Reason_Lost__c field on opportunity object
                            if(Trigger.oldMap.get(c.Id).Status !='Non Conversion' && c.Status =='Non Conversion'){
                                losti=0;                                    
                                for(Case caseforResontolost: caserecords){ 
                                    
                                    if(caseforResontolost.NCSP_Opportunity__c==c.NCSP_Opportunity__c &&caseforResontolost.Status !='Non Conversion'){
                                        losti++;           
                                    }
                                    
                                    if(caseforResontolost.NCSP_Opportunity__r.StageName=='0 - Pre-Qualification'||caseforResontolost.NCSP_Opportunity__r.StageName=='1 - Qualification'
                                       ||caseforResontolost.NCSP_Opportunity__r.StageName=='2 - Solution Developed'||caseforResontolost.NCSP_Opportunity__r.StageName=='3 - Solution Agreed'
                                       ||caseforResontolost.NCSP_Opportunity__r.StageName=='4 - Negotiate'  ||caseforResontolost.NCSP_Opportunity__r.StageName=='Dead'
                                       ||caseforResontolost.NCSP_Opportunity__r.StageName=='Postponed' ){
                                           
                                           losti++;
                                       }
                                }  
                                
                                /*if all the cases of this opportunity have status Non Conversion*/
                                if(losti==0 )
                                {
                                    
                                    Opportunity o = new Opportunity(
                                        id=c.NCSP_Opportunity__c,
                                        StageName='Lost',
                                        NCSP_Status__c='Escalated',
                                        Service_Completed_Entered_Date__c=null,
                                        IM_Reason_Lost__c='Non Conversion'
                                    );
                                    if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                        OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                    }
                                }   
                            }
                            /*end block */
                            //Developer Name: Madhu Paladugu
                            //Case number:00593195          
                            // added the logic for "Accutrac"
                            if(c.RecordTypeId==NCSP_New_cust &&c.NCSP_Service_line__c=='Accutrac' &&c.Customer_ID__c !=null ){
                                Opportunity o = new Opportunity(
                                    id= c.NCSP_Opportunity__c,
                                    StageName='6 - Setup',
                                    IM_Reason_Lost__c=null,
                                    Service_Completed_Entered_Date__c=null,
                                    NCSP_Status__c='Contract Approved'
                                );
                                if(!OpportunityMap.containskey(c.NCSP_Opportunity__c)){
                                    OpportunityMap.put(c.NCSP_Opportunity__c, o);
                                }
                            }
                        }
                    }
                    if(!dates.isEmpty())
                    {
                        for(Id id: dates.keySet())
                            //sorting all the dates so that most recent date can be assigned       
                        {
                            Opportunity opp = new Opportunity(
                                id= id,
                                Service_Schedule_Date__c=dates.get(id));  //assigning the last date in the list to opportunity schedule date
                            updatedateopplist.add(opp);
                            system.debug ('++++ added updated opp list +++' + updatedateopplist);
                        }
                        
                        /* Madhu added On 12/18/12 block of code to reduce the SOQL By doing update in future methods */
                        /* List<Id> OppIdToUpdate=new List<String>();
List<DateTime> Service_Schedule_Date=new List<DateTime>();
for(Integer i1=0;i1<updatedateopplist.size();i1++){
OppIdToUpdate.add(updatedateopplist[i1].Id);
Service_Schedule_Date.add(updatedateopplist[i1].Service_Schedule_Date__c);
}
if(OppIdToUpdate.size()>0)
CallingUpdateOppRecords.doUpdateOfDates(OppIdToUpdate,Service_Schedule_Date); */
                        /*  End of block */  
                        //Developer Name: Madhu Paladugu
                        //Case Number   : 01045376
                        //Discription   : Added logic to catch the Validation error on 1/7/13.
                        
                        if (FormController.executeUpdationInTrigger) {
                            try{
                                system.debug ('++++ updated opp list 1+++' + updatedateopplist);    
                                List<Opportunity> oppList = oppValidation(updatedateopplist);
                                system.debug ('++++ updated opp list +++' + updatedateopplist);
                                update oppList;
                            }
                            catch(DmlException exp){
                                Trigger.new[0].addError(exp.getMessage());
                                //Trigger.new[0].addError('The following error occurred while trying to update the associated opportunity record: "The Parent Account on the opportunity must be linked to the Upsell Customer ID in the Upsell Details section of the opportunity."');
                            }
                        }
                        
                    }
                    if(!OpportunityMap.isEmpty())
                    {
                        updateopplist.addAll(OpportunityMap.values());
                        
                        /* Madhu added On 12/18/12 block of code to reduce the SOQL By doing update in future methods */
                        List<String> lstOppIdThatChangeStage=new List<String>();
                        List<String> NCSP_StatusList=new List<String>();
                        List<String> StageNamelist=new List<String>();
                        List<Date> Service_Completed_Entered_DateList=new List<Date>();
                        List<String> IM_Reason_LostListl=new List<String>();
                        for(Integer i2=0;i2<updateopplist.size();i2++){
                            lstOppIdThatChangeStage.add(updateopplist[i2].Id);
                            NCSP_StatusList.add(updateopplist[i2].NCSP_Status__c);
                            StageNamelist.add(updateopplist[i2].StageName);
                            Service_Completed_Entered_DateList.add(updateopplist[i2].Service_Completed_Entered_Date__c);
                            IM_Reason_LostListl.add(updateopplist[i2].IM_Reason_Lost__c);
                        }
                        if(lstOppIdThatChangeStage.size()>0)
                            CallingUpdateOppRecords.doUpdate(lstOppIdThatChangeStage,NCSP_StatusList,StageNamelist,Service_Completed_Entered_DateList,IM_Reason_LostListl); 
                        /*  End of block */
                        //update updateopplist;
                    }
                }
                
                /****NCSP OPPORTUNITY UPDATE CASE****/
                /*---end---*/
                
                /****CLONE CASE IF RECURRING CASE CHECKED****/
                /*---start---*/
                // Name: CloneCaseIfRecurringCaseChecked2
                // Description: Trigger creates cloned case if case is flagged as recurring
                // Updates 2/3 to include update to SLA  Target Date Calculation:
                //      update Case SLA Calculation to be based off of Service Location related time zone
                //      and if Service location is not populated then the Customer Account Market’s
                //      time zone and if the market or service location has no time zone entered then
                //      it will use CreatedBy User's time zone.
                // Trigger performs validation to ensure date/time fields that are entered – are entered with correct tense.  Past, Future, Current. 
                // Created By: Vinod Kumar (Appirio)
                // Last Modified: Feb 3, 2011
                
                if(CloneCaseIfRecurringCaseChecked2=='True'){
                    
                    /* commented by Jyoti as part of #14409
if(triggerFlowControl.triggerRunCount('CloneCaseIfRecurringCaseChecked2') <= 1)
{    


clonecasefillRecordTypeIds(); 
Case newCase;
for(Case c: Trigger.new){           
if(clonecaserecordTypeIds.contains(c.RecordTypeId) && c.Status =='Closed' && c.Recurring_Case__c ){
newCase = new Case();
newCase.OwnerId = c.OwnerId;
newCase.AccountId = c.AccountId;
newCase.Customer_ID__c = c.Customer_ID__c;
newCase.ContactId = c.ContactId;
newCase.Origin = c.Origin;
newCase.Department_ID__c = c.Department_ID__c;
newCase.Division_ID__c = c.Division_ID__c;
newCase.Type = c.Type;
newCase.IM_Case_Sub_Type__c = c.IM_Case_Sub_Type__c;
newCase.Assigned_Team__c = c.Assigned_Team__c;
newCase.Subject = c.Subject;
newCase.Description = c.Description;
newCase.RecordTypeId = c.RecordTypeId;
newCase.Priority = 'Normal';
newCase.Status = 'New';
newCase.Service_Linenew__c = c.Service_Linenew__c;
newCase.Reason__c = '';
newCase.Is_Cloned__c = true;
newCase.Recurring_Case__c = c.Recurring_Case__c;
newCase.Recurring_Frequency__c = c.Recurring_Frequency__c;
// Service location
newCase.Service_Location__c = c.Service_Location__c;
//newCase.Service_Location_not_found__c = c.Service_Location_not_found__c; 
//              
DateTime dtInitialTargetDate = DateTime.newInstanceGmt( DateTime.now().year(), DateTime.now().month(), DateTime.now().day(), 17,0,0);

if(c.Initial_Due_Date__c != null){
Date initialDate = c.Initial_Due_Date__c;
// converting date to datetime with time 17pm..
dtInitialTargetDate = DateTime.newInstanceGmt( initialDate.year(), initialDate.month(), initialDate.day(), 17,0,0);
}

if(c.Recurring_Frequency__c == 'Daily'){
newCase.SLA_Target_Date__c = dtInitialTargetDate.addDays(1);

}
else if(c.Recurring_Frequency__c == 'Weekly'){
newCase.SLA_Target_Date__c = dtInitialTargetDate.addDays(7);    

}
else if(c.Recurring_Frequency__c == 'Every 2 Weeks'){
newCase.SLA_Target_Date__c = dtInitialTargetDate.addDays(14);   

}
else if(c.Recurring_Frequency__c == 'Monthly'){
newCase.SLA_Target_Date__c = dtInitialTargetDate.addDays(30);   

}
else if(c.Recurring_Frequency__c == 'Quarterly'){
newCase.SLA_Target_Date__c = dtInitialTargetDate.addDays(90);

}
else if(c.Recurring_Frequency__c == 'Every 6 Months'){
newCase.SLA_Target_Date__c = dtInitialTargetDate.addDays(180);  

}
else if(c.Recurring_Frequency__c == 'Yearly'){
newCase.SLA_Target_Date__c = dtInitialTargetDate.addDays(365);                                    
}
if(newCase.SLA_Target_Date__c != null){
// convert date according to matrix time
List<Integer>lstTimeZone  = UtilUpdateSladaysAndSlaTargetDate.getMarketOrServiceLocationTimeZoneHour(c);
integer intMarketLocationtimeZone = 0;
integer intTimeZoneMinutes = 0;
if(lstTimeZone != null && lstTimeZone.size() > 1){
intMarketLocationtimeZone = lstTimeZone[0];
intTimeZoneMinutes = lstTimeZone[1];
}   
newCase.SLA_Target_Date__c = newCase.SLA_Target_Date__c.addHours((-1*intMarketLocationtimeZone));
newCase.SLA_Target_Date__c = newCase.SLA_Target_Date__c.addMinutes((-1*intTimeZoneMinutes));
}                        
lstClone.add(newCase);      
}
}
if(lstClone.size() > 0){
// Update the Sla day and SlaTarget date
Date dtCreateddate = date.today();
List<Case> lstUpdatedClone = new List<Case>();
UtilUpdateSladaysAndSlaTargetDate.GetCaseCustomerAccountAndHolidaySchedule(lstClone);
for(case c : lstClone){
c.SLA_Target_Date__c = UtilUpdateSladaysAndSlaTargetDate.GetSlaTargetDateForClonedCase(c);              
// update initial due date
newCase.Initial_Due_Date__c = Date.newInstance(c.SLA_Target_Date__c.year(), c.SLA_Target_Date__c.month(),c.SLA_Target_Date__c.day());
// update Sla days
c.SLA_Days__c = dtCreateddate.daysBetween(c.SLA_Target_Date__c.date());
lstUpdatedClone.add(c);
}         
insert lstUpdatedClone;
}
CaseRecordTypeSelection.CloneCreated();
}    */
                } 
                
                /****CLONE CASE IF RECURRING CASE CHECKED****/
                /*---end---*/
                // }
            }
            
            /*******************************************END OF AFTER INSERT AND UPDATE*************************/
            
            /****ISSUE TASK REQUIRE CASE COMMENT FOLLOW UP NOTE****/
            /*---start---*/
            /*commented by Jyoti as part of #14409
If(Issue_TaskRequire_CaseComment_FollowUpNote=='True'){
if(runIssueTask==true){

issuefillRecordTypeIds();
for( case c : trigger.new){
if(issuerecordTypeID.contains(c.RecordTypeId) && c.Status == 'Closed' ){
lstNewCase.add(c);
}
}
if(lstNewCase.size() > 0){     
List<CaseComment> lstCaseComments = [Select id, ParentId,IsDeleted From CaseComment  where ParentId in :lstNewCase];
Set<Id> casehasComment = new set<id>();
for(CaseComment cc: lstCaseComments){
casehasComment.add(cc.ParentId);
}
for(Case c :lstNewCase){
if( ! casehasComment.contains(c.ID)){
c.addError('Internal Comments are required if Case Status is Closed');
}
}
}  
}       
} */
            /****ISSUE TASK REQUIRE CASE COMMENT FOLLOW UP NOTE****/
            /*---end---*/
            
            /****UPDATE INTERNAL CASE TEAM****/
            /*---start---*/
            //Created Date: Aug 24,2010
            //Auhtor      : Nagesh Ganji
            //Description : This trigger is defined for IM internal cases to provide case creator with read/write permission,
            //              and IM contact with Read permission.
            // Jyoti Nayak : Commenting code Start.#25946
            /* if(updateInternalCaseTeam=='True'){

if(triggerFlowControl.triggerRunCount('updateInternalCaseTeam') <= 1 ){    
//Get the ID for IM Employees Support Case record type
Id imRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Employees Support Case').getRecordTypeId();

//Get CaseTeamRoles for Read, Read/Write access level
//Id viewRole, editRole;
List<CaseTeamRole> ctrolst = [SELECT Id, Name FROM CaseTeamRole limit 1000];
for(CaseTeamRole ctr : ctrolst) {
if (ctr.Name.equalsIgnoreCase('Case View')) viewRole = ctr.Id;
else if (ctr.Name.equalsIgnoreCase('Case Create')) editRole = ctr.Id;
}

try{
if( Trigger.isAfter && Trigger.isInsert ) {
List<CaseTeamMember> lCTMember = new List<CaseTeamMember>();
for(Integer i=0; i<Trigger.new.size(); i++) {
system.debug('imRecTypeId----'+imRecTypeId);
if( (Trigger.new[i].RecordTypeId == imRecTypeId )) {
system.debug('Trigger.new[i].OwnerId----'+Trigger.new[i].OwnerId);
CaseTeamMember ctm1 = new CaseTeamMember();
ctm1.MemberId = Trigger.new[i].OwnerId;
ctm1.ParentId = Trigger.new[i].Id;
ctm1.TeamRoleId = editRole;
lCTMember.add(ctm1);

//Add IM Contact with Read access (if different from creator)
if( Trigger.new[i].IM_Employee_Contact__c != null && Trigger.new[i].OwnerId != Trigger.new[i].IM_Employee_Contact__c) {
CaseTeamMember ctm2 = new CaseTeamMember();
ctm2.MemberId = Trigger.new[i].IM_Employee_Contact__c;
ctm2.ParentId = Trigger.new[i].Id;
ctm2.TeamRoleId = viewRole;
lCTMember.add(ctm2);                    
}
}
}
if (lCTMember.size() > 0)
system.debug('lCTMember----'+lCTMember);
insert lCTMember;        
}
else if ( Trigger.isAfter && Trigger.isUpdate ) {
//We are not anticipating to bulk update on IM Contact, so processing only single record for now.

List<CaseTeamMember> lCTMember4Delete = new List<CaseTeamMember>();
List<CaseTeamMember> lCTMember4Insert = new List<CaseTeamMember>();
Set<Id> caseIdWithUpdatedContact = new Set<Id>();
Integer flag = 1;

if( (Trigger.new[0].RecordTypeId == imRecTypeId ) && 
Trigger.new[0].IM_Employee_Contact__c != Trigger.old[0].IM_Employee_Contact__c) {
caseIdWithUpdatedContact.add(Trigger.new[0].Id);

List<CaseTeamMember> lctm = [SELECT Id, MemberId, ParentId, TeamRoleId FROM CaseTeamMember WHERE ParentId in :caseIdWithUpdatedContact];

for (Integer i=0; i< lctm.size(); i++ ) {
if (Trigger.old[0].IM_Employee_Contact__c == lctm.get(i).MemberId && lctm.get(i).TeamRoleId == viewRole) {
lCTMember4Delete.add(lctm.get(i));
} else if (Trigger.new[0].IM_Employee_Contact__c == lctm.get(i).MemberId )
flag = 0;
}
if ( flag == 1 && Trigger.new[0].IM_Employee_Contact__c != null) {
CaseTeamMember c1 = new CaseTeamMember();
c1.MemberId = Trigger.new[0].IM_Employee_Contact__c;
c1.ParentId = Trigger.new[0].Id;
c1.TeamRoleId = viewRole;
lCTMember4Insert.add(c1);
}
if (lCTMember4Delete.size() > 0)
delete lCTMember4Delete ;

if (lCTMember4Insert.size() > 0)
insert lCTMember4Insert;
}    
}
}
catch (DMLException dmlex){
Trigger.new[0].addError('Failed to Update Case Team members'+dmlEx.getDmlId(0)+' Error: '+dmlex.getMessage());
}
catch(Exception ex){
Trigger.new[0].addError('Failed to Update Case Team members!'+ex.getMessage());          
} 
}
}   */  //Jyoti Nayak: Commenting code end.#25946
            
            /****UPDATE INTERNAL CASE TEAM****/
            /*---end---*/
            
            /****UpdateNCSPStatus ****/
            /*---start---*/ 
            //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Reason_No_Service__c" & Service_Order_Required__c- Commentlined this block as we have to remove dependency of the two fields
            /*  If(UpdateNCSPStatus=='True'){
if(runUpdateNCSPStatus==true){

updateNCSPStatsRecordTypeIds();
Map<Id,String> opp_map=new Map<id,String>();
//Checking for inserted or Update if NCSP Case meets condition or Not.
for(Integer i=0; i<Trigger.New.Size(); i++){

//#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Reason_No_Service__c"
if(Trigger.New[i].NCSP_Opportunity__c != null && NCSPRecordTypeIds.contains(Trigger.New[i].RecordTypeId) && ((Trigger.New[i].Service_Order_Required__c== 'No' && Trigger.New[i].Reason_No_Service__c == 'Local Market Handling') || (Trigger.New[i].Service_Order_Required__c== 'No' && Trigger.New[i].Reason_No_Service__c == 'Special Projects'))){
opp_map.put(Trigger.New[i].NCSP_Opportunity__c,Trigger.new[i].Reason_No_Service__c);


}
}

if(!opp_map.isEmpty()){
//Querying all NCSP Cases associated to an Oportunity
List<Case> ALL_CASES = [Select Id,NCSP_Opportunity__c,Service_Order_Required__c,Reason_No_Service__c From Case Where NCSP_Opportunity__c IN:opp_map.keySet()];
for(Integer i=0; i<Trigger.New.Size(); i++){
for(Case cas: ALL_CASES){
if(cas.id!=Trigger.New[i].id && Trigger.New[i].NCSP_Opportunity__c==cas.NCSP_Opportunity__c){
//All cases should meet conditions. Otherwise no 'NCSP Status' update on associated Opportunity. 
if((cas.Service_Order_Required__c != 'No' && cas.Reason_No_Service__c != 'Local Market Handling') || (cas.Service_Order_Required__c != 'No' && cas.Reason_No_Service__c != 'Special Projects')){
opp_map.remove(Trigger.New[i].NCSP_Opportunity__c);
break;

}
}
}
}
}
if(!opp_map.isEmpty()){
//Querying associated Opportunity and updated NCSP Status.
List<Opportunity> LST_OPPORTUNITY = [Select Id,NCSP_Status__c From Opportunity where Id IN:opp_map.keySet()];
List<Opportunity> opp_update=new List<Opportunity>();
for(Opportunity o:LST_OPPORTUNITY) {
o.NCSP_Status__c=opp_map.get(o.id);
opp_update.add(o);
}
update opp_update; 

}
}
} */
            /****UpdateNCSPStatus ****/
            /*---end---*/
            
        }
        /**************************************************END TRIGGER*********************************************/
        
    }
    System.debug('---2341----Trigger is not executing for IME SC Record Types---------');
    //Gitlab user Story #27422 start because this Method has not in use and required to improve code coverage
    /*private void CheckfillRecordTypeIds(){
        if(rtMapByName.containsKey('CAC_DP_Closure'))
            checkrecordTypeIds.add(rtMapByName.get('CAC_DP_Closure').getRecordTypeId());
        if(rtMapByName.containsKey('CAC_SKP_RM'))
            checkrecordTypeIds.add(rtMapByName.get('CAC_SKP_RM').getRecordTypeId());    
        if(rtMapByName.containsKey('CAC_SKP_Shred'))
            checkrecordTypeIds.add(rtMapByName.get('CAC_SKP_Shred').getRecordTypeId());
        //Gitlab user Story #12724 start
        /*if(rtMapByName.containsKey('Issue'))
checkrecordTypeIds.add(rtMapByName.get('Issue').getRecordTypeId());
if(rtMapByName.containsKey('Issues_Question'))
checkrecordTypeIds.add(rtMapByName.get('Issues_Question').getRecordTypeId());*/
        //Gitlab user Story #12724 End    
        //Gitlab user Story #12722 start
        /*if(rtMapByName.containsKey('Issue_Request'))
checkrecordTypeIds.add(rtMapByName.get('Issue_Request').getRecordTypeId());*
        //Gitlab user Story #12722 End
        if(rtMapByName.containsKey('NCSP_DMS'))
            checkrecordTypeIds.add(rtMapByName.get('NCSP_DMS').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_DP_Onboarding_team'))
            checkrecordTypeIds.add(rtMapByName.get('NCSP_DP_Onboarding_team').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_SKP_Department_Add_Only'))
            checkrecordTypeIds.add(rtMapByName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_SKP_New_customer_setup'))
            checkrecordTypeIds.add(rtMapByName.get('NCSP_SKP_New_customer_setup').getRecordTypeId());
        // if(rtMapByName.containsKey('Task'))--commented by Jyoti as part of #14409
        //     checkrecordTypeIds.add(rtMapByName.get('Task').getRecordTypeId()); --commented by Jyoti as part of #14409
        //Gitlab user Story #12724 start because this record type not exsist and required to improve code coverage
        /*if(rtMapByName.containsKey('Task_Question'))
checkrecordTypeIds.add(rtMapByName.get('Task_Question').getRecordTypeId());
if(rtMapByName.containsKey('Task_Request'))
checkrecordTypeIds.add(rtMapByName.get('Task_Request').getRecordTypeId());*
        //Gitlab user Story #12724 End
        if(rtMapByName.containsKey('NCSP_Tech_Services_New_Customer_Setup'))
            checkrecordTypeIds.add(rtMapByName.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId());
        //Developer Name: Madhu Paladugu
        //Case number:00593195 
        //updated logic to add two new record types
        if(rtMapByName.containsKey('NCSP_New_Customer_Setup'))
            checkrecordTypeIds.add(rtMapByName.get('NCSP_New_Customer_Setup').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_Upsell'))
            checkrecordTypeIds.add(rtMapByName.get('NCSP_Upsell').getRecordTypeId()); 
        // # 10469 and 10364 added Retention RM and Retention SH recordtypes
        if(rtMapByName.containsKey('Retention_RM'))
            checkrecordTypeIds.add(rtMapByName.get('Retention_RM').getRecordTypeId());
        if(rtMapByName.containsKey('Retention_SH'))
            checkrecordTypeIds.add(rtMapByName.get('Retention_SH').getRecordTypeId()); 
    }*/
    //Gitlab user Story #27422 end
    /* commented by Jyoti as part of #14409 
private void ClonecasefillRecordTypeIds(){
//Gitlab user Story #12724 start
/*if(rtMapByName.containsKey('Issue'))
clonecaserecordTypeIds.add(rtMapByName.get('Issue').getRecordTypeId());*/
    //Gitlab user Story #12724 End          
    // if(rtMapByName.containsKey('Task'))
    //    clonecaserecordTypeIds.add(rtMapByName.get('Task').getRecordTypeId());           
    //Gitlab user Story #12722 start
    /*if(rtMapByName.containsKey('Issue_Request'))
clonecaserecordTypeIds.add(rtMapByName.get('Issue_Request').getRecordTypeId());*/
    //Gitlab user Story #12722 End
    //Gitlab user Story #12724 start because this record type not exsist and required to improve code coverage
    /*if(rtMapByName.containsKey('Task_Request'))
clonecaserecordTypeIds.add(rtMapByName.get('Task_Request').getRecordTypeId());*/
    //Gitlab user Story #12724 End        
    // } 
    /* commented as part of user story #27066
     private void CaseclosedfillRecordTypeIds(){
        if(rtMapByName.containsKey('NCSP_DMS'))
            caseclosedrecordTypeIds.add(rtMapByName.get('NCSP_DMS').getRecordTypeId());          
        if(rtMapByName.containsKey('NCSP_DP_Onboarding_team'))
            caseclosedrecordTypeIds.add(rtMapByName.get('NCSP_DP_Onboarding_team').getRecordTypeId());           
        if(rtMapByName.containsKey('NCSP_SKP_Department_Add_Only'))
            caseclosedrecordTypeIds.add(rtMapByName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_SKP_New_customer_setup'))
            caseclosedrecordTypeIds.add(rtMapByName.get('NCSP_SKP_New_customer_setup').getRecordTypeId()); 
        if(rtMapByName.containsKey('NCSP_Tech_Services_New_Customer_Setup'))
            caseclosedrecordTypeIds.add(rtMapByName.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId());
        //Developer Name: Madhu Paladugu
        //Case number:00593195 
        //updated logic to add two new record types
        if(rtMapByName.containsKey('NCSP_New_Customer_Setup'))
            caseclosedrecordTypeIds.add(rtMapByName.get('NCSP_New_Customer_Setup').getRecordTypeId()); 
        if(rtMapByName.containsKey('NCSP_Upsell'))
            caseclosedrecordTypeIds.add(rtMapByName.get('NCSP_Upsell').getRecordTypeId());      
    }
    commented as part of user story #27066 */
    //Gitlab user Story #27422 start because this Method has not in use and required to improve code coverage
    /*private Date getDate(Datetime dt) {
        return dt.date();
    }*/
    //Gitlab user Story #27422 end
    /*private void fillRecordTypeIds() {

if(rtMapByName.containsKey('NCSP_Tech_Services_New_Customer_Setup')) {
Id pId = rtMapByName.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId();             
NCSP_TECH_RecTypeIds.add(pId);
}

if(rtMapByName.containsKey('NCSP_SKP_New_customer_setup')) {
Id pId = rtMapByName.get('NCSP_SKP_New_customer_setup').getRecordTypeId();             
SKP_DP_DMS_RecTypeIds.add(pId);
SKP_SKP_DMS_RecTypeIds.add(pId);
SKP_SKP_DP_RecTypeIds.add(pId);
SKP_SKP_DP_DMS_RecTypeIds.add(pId);
//madhu adeed for store recordtypes for invoice-date validation
NCSP_INVOICE_DATE_RecTypeIds.add(pId);
NCSP_SKP_DMS_Setup.add(pId);
}
if(rtMapByName.containsKey('NCSP_SKP_Department_Add_Only')) {
Id pId = rtMapByName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId(); 
SKP_SKP_DMS_RecTypeIds.add(pId);
SKP_SKP_DP_RecTypeIds.add(pId);
SKP_SKP_DP_DMS_RecTypeIds.add(pId);
SKP_DEPT_ADD_RecTypeIds.add(pId);
//madhu adeed for store recordtypes for invoice-date validation
NCSP_INVOICE_DATE_RecTypeIds.add(pId);

}
if(rtMapByName.containsKey('NCSP_DP_Onboarding_team')) {
Id pId = rtMapByName.get('NCSP_DP_Onboarding_team').getRecordTypeId();          
DP_RecTypeIds.add(pId);
SKP_DP_DMS_RecTypeIds.add(pId);
SKP_SKP_DP_RecTypeIds.add(pId);
SKP_SKP_DP_DMS_RecTypeIds.add(pId);
//madhu adeed for store recordtypes for invoice-date validation
NCSP_INVOICE_DATE_RecTypeIds.add(pId);
}
if(rtMapByName.containsKey('NCSP_DMS')) {
Id pId = rtMapByName.get('NCSP_DMS').getRecordTypeId();            
SKP_DP_DMS_RecTypeIds.add(pId);
SKP_SKP_DMS_RecTypeIds.add(pId);
SKP_SKP_DP_DMS_RecTypeIds.add(pId);
//
NCSP_SKP_DMS_Setup.add(pId);
}
//Developer Name: Madhu Paladugu
//Case number:00593195 
//updated logic to add two new record types
if(rtMapByName.containsKey('NCSP_Upsell')) {
Id pId = rtMapByName.get('NCSP_Upsell').getRecordTypeId(); 
NCSP_Upsell_RecordTypeIds.add(pId);

}
if(rtMapByName.containsKey('NCSP_New_Customer_Setup')) {
Id pId = rtMapByName.get('NCSP_New_Customer_Setup').getRecordTypeId(); 
NCSP_New_Customer_RecordTypeIds.add(pId);
SKP_SKP_DP_DMS_RecTypeIds.add(pId);
} 
}*/
    //madhu today
    //Gitlab user Story #27422 start because this Method has not in use and required to improve code coverage
    /*private void NCSPRecIds(){
        if(rtMapByName.containsKey('NCSP_SKP_New_customer_setup')){
            REC_IDS_MAILING_DATE.add(rtMapByName.get('NCSP_SKP_New_customer_setup').getRecordTypeId());
            
        }
        if(rtMapByName.containsKey('NCSP_DP_Onboarding_team')){
            REC_IDS_MAILING_DATE.add(rtMapByName.get('NCSP_DP_Onboarding_team').getRecordTypeId());
        }
        if(rtMapByName.containsKey('NCSP_SKP_Department_Add_Only')){
            REC_IDS_MAILING_DATE.add(rtMapByName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
            
        }
    }*/
    //Gitlab user Story #27422 end
    /* commented by Jyoti as part of #14409
private void issuefillRecordTypeIds(){   
/*  if(rtMapByName.containsKey('Task'))
issuerecordTypeID.add(rtMapByName.get('Task').getRecordTypeId()); 
//Gitlab user Story #12724 start
/*if(rtMapByName.containsKey('Issue'))
issuerecordTypeID.add(rtMapByName.get('Issue').getRecordTypeId());*/
    //Gitlab user Story #12724 End         
    //Gitlab user Story #12722 start
    /*if(rtMapByName.containsKey('Issue_Request'))
issuerecordTypeID.add(rtMapByName.get('Issue_Request').getRecordTypeId());*/
    //Gitlab user Story #12722 End
    //Gitlab user Story #12724 start because this record type not exsist and required to improve code coverage
    /*if(rtMapByName.containsKey('Task Request'))
issuerecordTypeID.add(rtMapByName.get('Task Request').getRecordTypeId());*/
    //Gitlab user Story #12724 End          
    // }
    // Gitlab user Story #27422 start because this Method has not in use and required to improve code coverage
    /*private void updateFillRecordTypeIds(){        
        if(rtMapByName.containsKey('CAC_SKP_RM'))
            updaterecordTypeIds.add(rtMapByName.get('CAC_SKP_RM').getRecordTypeId());
        if(rtMapByName.containsKey('CAC_SKP_Shred'))
            updaterecordTypeIds.add(rtMapByName.get('CAC_SKP_Shred').getRecordTypeId());
        if(rtMapByName.containsKey('CAC_DP_Closure'))
            updaterecordTypeIds.add(rtMapByName.get('CAC_DP_Closure').getRecordTypeId());
        //  # 10469 and 10364 adding retention RM ans SH record types to updaterecordTypeIds starts
        if(rtMapByName.containsKey('Retention_RM'))
            updaterecordTypeIds.add(rtMapByName.get('Retention_RM').getRecordTypeId());
        if(rtMapByName.containsKey('Retention_SH'))
            updaterecordTypeIds.add(rtMapByName.get('Retention_SH').getRecordTypeId()); 
        //  # 10469 and 10364 adding retention RM ans SH record types to updaterecordTypeIds ends
    }*/
    //Gitlab user Story #27422 end 
    private void slaFillRecordTypeIds(){
        //Gitlab user Story #12724 start
        /*if(rtMapByName.containsKey('Issue')){
slarecordTypeIds.add(rtMapByName.get('Issue').getRecordTypeId());
mapCaseRecordType.put(rtMapByName.get('Issue').getRecordTypeId(),'Issue');
}*/
        //Gitlab user Story #12724 End
        /* commented by Jyoti as part of #14409
if(rtMapByName.containsKey('Task')){
slarecordTypeIds.add(rtMapByName.get('Task').getRecordTypeId());
mapCaseRecordType.put(rtMapByName.get('Task').getRecordTypeId(),'Task');
} */
        //Gitlab user Story #12722 start
        /*if(rtMapByName.containsKey('Issue_Request')){
slarecordTypeIds.add(rtMapByName.get('Issue_Request').getRecordTypeId());
mapCaseRecordType.put(rtMapByName.get('Issue_Request').getRecordTypeId(),'Issue Request');
}*/
        //Gitlab user Story #12722 End
        //Gitlab user Story #12724 start because this record type not exsist and required to improve code coverage
        /*if(rtMapByName.containsKey('Task_Request')){
slarecordTypeIds.add(rtMapByName.get('Task_Request').getRecordTypeId());
mapCaseRecordType.put(rtMapByName.get('Task_Request').getRecordTypeId(),'Task Request');
}*/
        //Gitlab user Story #12724 End
    }
    /* commented by Jyoti as part of #14409
private void updateslatargetdate(){
Map<ID,DateTime> mapSlaTargetDates;
if(trigger.isUpdate)
mapSlaTargetDates = UtilUpdateSladaysAndSlaTargetDate.getSlaTargetDateForCases(lstNonRecurringCase,Trigger.isInsert);
List<Case> lstClonedCaseAfterSlaDate = new List<Case>();
for(case c : slalstNewCase){          
if( c.Recurring_Case__c){    // for recuring case                 
if( c.Is_Cloned__c == False){ 
Date initialDueDate = Date.today();
if(c.Initial_Due_Date__c != null )
initialDueDate = c.Initial_Due_Date__c;
DateTime dtSlaTarget = DateTime.newInstanceGmt( initialDueDate.year(), initialDueDate.month(), initialDueDate.day(), 17,0,0);
// convert date according to matrix time
List<Integer>lstTimeZone  = UtilUpdateSladaysAndSlaTargetDate.getMarketOrServiceLocationTimeZoneHour(c);
integer intMarketLocationtimeZone = 0;
integer intTimeZoneMinutes = 0;
if(lstTimeZone != null && lstTimeZone.size() > 1){
intMarketLocationtimeZone = lstTimeZone[0];
intTimeZoneMinutes = lstTimeZone[1];
}
dtSlaTarget = dtSlaTarget.addHours((-1*intMarketLocationtimeZone));
dtSlaTarget = dtSlaTarget.addMinutes((-1*intTimeZoneMinutes));
c.SLA_Target_Date__c = dtSlaTarget;
}
else if(trigger.isUpdate) {// for cloned case
DateTime dtInitialDate = DateTime.now(); 
Case oldC=Trigger.oldMap.get(c.Id);  
if(c.Recurring_Frequency__c != oldC.Recurring_Frequency__c) {                      
if(c.Initial_Due_Date__c != null){
Date initialDueDate = c.Initial_Due_Date__c;
dtInitialDate = DateTime.newInstance( initialDueDate.year(), initialDueDate.month(), initialDueDate.day(), 17,0,0);             
} 
// convert date according to matrix time
List<Integer>lstTimeZone  = UtilUpdateSladaysAndSlaTargetDate.getMarketOrServiceLocationTimeZoneHour(c);
integer intMarketLocationtimeZone = 0;
integer intTimeZoneMinutes = 0;
if(lstTimeZone != null && lstTimeZone.size() > 1){
intMarketLocationtimeZone = lstTimeZone[0];
intTimeZoneMinutes = lstTimeZone[1];
}   
dtInitialDate = dtInitialDate.addHours((-1*intMarketLocationtimeZone));
dtInitialDate = dtInitialDate.addMinutes((-1*intTimeZoneMinutes));
//*******                      
if(c.Recurring_Frequency__c == 'Daily'){
c.SLA_Target_Date__c = dtInitialDate.addDays(1);                
}
else if(c.Recurring_Frequency__c == 'Weekly'){
c.SLA_Target_Date__c = dtInitialDate.addDays(7);                
}
else if(c.Recurring_Frequency__c == 'Every 2 Weeks'){
c.SLA_Target_Date__c = dtInitialDate.addDays(14);               
}
else if(c.Recurring_Frequency__c == 'Monthly'){
c.SLA_Target_Date__c = dtInitialDate.addDays(30);                
}
else if(c.Recurring_Frequency__c == 'Quarterly'){
c.SLA_Target_Date__c = dtInitialDate.addDays(90);               
}
else if(c.Recurring_Frequency__c == 'Every 6 Months'){
c.SLA_Target_Date__c = dtInitialDate.addDays(180);               
}
else if(c.Recurring_Frequency__c == 'Yearly'){
c.SLA_Target_Date__c = dtInitialDate.addDays(365);                
}
lstClonedCaseAfterSlaDate.add(c);
}
}            
} 
else{        
// for non recuring case
if(trigger.isInsert) {                          
c.SLA_Target_Date__c =  UtilUpdateSladaysAndSlaTargetDate.getSlaTargetDateForSingleCase(c);           
}
else{         
if(mapSlaTargetDates.containsKey(c.Id)){       
c.SLA_Target_Date__c = mapSlaTargetDates.get(c.id);
} 
}  

}
}
// check if the cloned case sla target dae on a holiday or not and if on holiday then move it on next working day
if(lstClonedCaseAfterSlaDate.size() >0){
Map<DateTime,DAteTime> mapClonedSlatargetDate = UtilUpdateSladaysAndSlaTargetDate.GetSlaTargetDateForClonedCase(lstClonedCaseAfterSlaDate);
for(Case c : lstClonedCaseAfterSlaDate){
if(mapClonedSlatargetDate.containsKey(c.SLA_Target_Date__c)){
c.SLA_Target_Date__c = mapClonedSlatargetDate.get(c.SLA_Target_Date__c);
}
}
}

} */
    //Gitlab user Story #12724 start because this Method has not in use and required to improve code coverage
    /*
private void updateNCSPStatsRecordTypeIds(){

if(rtMapByName.containsKey('NCSP_Upsell'))
NCSPRecordTypeIds.add(rtMapByName.get('NCSP_Upsell').getRecordTypeId());
if(rtMapByName.containsKey('NCSP_DMS'))
NCSPRecordTypeIds.add(rtMapByName.get('NCSP_DMS').getRecordTypeId());
if(rtMapByName.containsKey('NCSP_DP_Onboarding_team'))
NCSPRecordTypeIds.add(rtMapByName.get('NCSP_DP_Onboarding_team').getRecordTypeId());
if(rtMapByName.containsKey('NCSP_SKP_Department_Add_Only'))
NCSPRecordTypeIds.add(rtMapByName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
if(rtMapByName.containsKey('NCSP_SKP_New_customer_setup'))
NCSPRecordTypeIds.add(rtMapByName.get('NCSP_SKP_New_customer_setup').getRecordTypeId());


}*/
    //Gitlab user Story #12724 End
    //Email-to-Case
    Private void IMESCCaseRecordTypes(){
        
        if(rtMapByName.ContainsKey('IME_SC_Case')){
            IMESCRecordTypeIds.add(rtMapByName.get('IME_SC_Case').getRecordTypeId());
        }
        if(rtMapByName.ContainsKey('IME_SC_CASE_RESOLVED'))
            IMESCRecordTypeIds.add(rtMapByName.get('IME_SC_CASE_RESOLVED').getRecordTypeId());
    }  
    
    public List<Opportunity> oppValidation(List<Opportunity> listOpp)
    {
        /*** for Opportunity Vended/Unvended validation rule ***/
        Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
        List<Opportunity> queryOppList = [select id, RecordTypeId, IME_Vended_Unvended__c, Type, StageName, IME_Number_of_Record_Management_Products__c  from Opportunity where id in :listOpp];
        system.debug('+++++++QChe++++++++CaseObject16');
        List<Opportunity> returnOppList = new List<Opportunity>();
        if(queryOppList.size() > 0)    {
            for(Opportunity opp : queryOppList)
            {
                String type = rtMap.get(opp.RecordTypeId).getName();
                if(!(opp.IME_Vended_Unvended__c=='Both'||opp.IME_Vended_Unvended__c=='Vended'||opp.IME_Vended_Unvended__c=='Unvended'||opp.IME_Vended_Unvended__c=='Unknown') &&(opp.Type=='New Deal'||opp.Type=='Up-Sell/Lift') && (opp.StageName=='2 - Solution Developed'||opp.StageName=='3 - Solution Agreed'||opp.StageName=='4 - Negotiate'||opp.StageName=='5 - Signed/PO in'||opp.StageName=='Lost'||opp.StageName=='Dead')&& opp.IME_Number_of_Record_Management_Products__c >0 && (type=='Standard Opportunity'))
                {
                    opp.IME_Vended_Unvended__c='Unknown';
                    returnOppList.add(opp);
                }
            }
        }
        
        /** end of validation rule criteria ***/
        system.debug('++++in validation method' + listOpp);
        return returnOppList;
    }
    System.debug('queries used case object: ' + Limits.getQueries());          
}