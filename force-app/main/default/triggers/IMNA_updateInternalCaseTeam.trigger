/****UPDATE INTERNAL CASE TEAM For IMNA NA coverage case, NSCP Case, Create Case Action****/
//Created Date: May 28,2014
//Case # :- 02493695, 02411596
//Auhtor      : Apurva Dutta, Venkateswarlu Avula
//Description : The purpose of this trigger is to Update the Assigned to Data Entry Date field and Data Entry Owner
//                once the case owner is moved to Queue to User stored in Data Entry Date Members. + The purpose of this trigger is to create a new case action record, whenever the Case's contract status is 
//              changed to "Rejected". +This trigger is defined for NA Account Coverage Requests record type case to provide case creator with read/write permission,
//              and IM contact with Read permission. 

/**
* Modified By: Vinutha Iyengar on 25-Nov-2015 
*           --To stop trigger being fired from Email Archive batch job
**/
// Modified by Pratap Reddy on 10-Jan-2017
//           Added if(!Test.isRunningTest()) for not calling Validator_cls.setAlreadyDone();
//
/**
* Modified By: Keerthi Senthilnathan on 22-June-2017
*           -- Removed the reference to No_Longer_In_Jeopardy_Date__c for case # 05142766
**/   
// Jyoti Nayak 27/08/2024 Commenting out the entire trigger as all currently used functionalities have been implemented through the flows (NCSP_Update_Data_Entry_Owner,NCSP_Case_After_Update_Flow,Create_Case_Team_Member_Functionality) And Validation Rules(NCSP_Validate_Set_Up_Complete_Date,NCSP_Validate_Upload_to_DRCl_Date) and other functionalities are no longer used as part of user story #25723 and #25946.
trigger IMNA_updateInternalCaseTeam on Case (before update, before insert, after insert, after update) 
{
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    // #25723,#25946 Commenting Code Start.
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
    system.debug(LoggingLevel.INFO,'IMNA_updateInternalCaseTeam - emailArchiveBatchJob value is  =='+IsEmailArchiveBatchJob); 
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    
    
     //Variable declaration for NCSP DATE VALIDATION RULES
    public String NCSPDateValidationRulesTrigger=null;
    Boolean insTrig = Trigger.isInsert;
    Date sysToday = System.today();
    public String updateInternalCaseTeamIMNA=null;
    Id viewRoleimna, editRoleimna;
    public String createCaseAction = null;
    
    private Date getDate(Datetime dt) 
    {
        return dt.date();
    }
    
    //Variable declaration for onboard date query trigger
     public String DateOnDataEntryDateMembers = null;
    
    if(!IsEmailArchiveBatchJob)
    {
        
        //***Retrieving Custom Settings***
         List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        for(Trigger_Activation_Settings__c cs : customsettings)
        {
            if(cs.Object__c=='Case')
            {
                if(cs.Trigger__c=='DateOnDataEntryDateMembers')
                {
                    DateOnDataEntryDateMembers=cs.Value__c;
                }
                if(cs.Trigger__c == 'updateInternalCaseTeamIMNA') 
                {
                    updateInternalCaseTeamIMNA = cs.Value__c;  
                }
            }
            if(cs.Trigger__c == 'NCSPDateValidationRulesTrigger') 
            {
                NCSPDateValidationRulesTrigger = cs.Value__c;  
            }
            if(cs.Object__c=='Case')
            {
                if(cs.Trigger__c == 'createCaseAction') 
                {
                    createCaseAction = cs.Value__c;  
                }
            }
        }
        
        
        if(trigger.isAfter)
        { 
             if(trigger.isUpdate)   {
if(createCaseAction=='TRUE')
{    
System.debug('++++Entering create case action++++');
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
system.debug('cas.Contract_Status__c----'+cas.Contract_Status__c+'----'+cas.Id+'----'+casMap.get(cas.Id));

casOld = casMap.get(cas.Id);

system.debug('casOld-----'+casOld);
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
system.debug('casActonLst-----'+casActonLst);
Insert casActonLst;
if(!Test.isRunningTest()){
Validator_cls.setAlreadyDone();
}

}
}
}
            if(updateInternalCaseTeamIMNA=='True')
            {
                if(triggerFlowControl.triggerRunCount('updateInternalCaseTeamIMNA') <= 1 )
                {    
                    //Get the ID for IM Employees Support Case record type
                    //#22476 Replaced 'NA Account Coverage Request' with 'IM Customer Data Management (CDM)' 
                    Id imRecTypeIdIMNA = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Customer Data Management (CDM)').getRecordTypeId();
                    //Get CaseTeamRoles for Read, Read/Write access level
                    //Id viewRole, editRole;
                    
                    List<CaseTeamRole> ctRoleLst = [SELECT Id, Name FROM CaseTeamRole];
                    
                    for(CaseTeamRole ctrimna : ctRoleLst) 
                    {
                        if (ctrimna.Name.equalsIgnoreCase('Case View')) viewRoleimna = ctrimna.Id;
                        else if (ctrimna.Name.equalsIgnoreCase('Case Create')) editRoleimna = ctrimna.Id;
                    }
                    
                    try{
                        if( Trigger.isAfter && Trigger.isInsert ) 
                        {
                            List<CaseTeamMember> lCTMemberIMNA = new List<CaseTeamMember>();
                            System.debug('+++++CaseteamMember+++'+lCTMemberIMNA);
                            for(Integer i=0; i<Trigger.new.size(); i++) 
                            {
                                if( (Trigger.new[i].RecordTypeId == imRecTypeIdIMNA )) 
                                {
                                    CaseTeamMember ctmimna = new CaseTeamMember();
                                    ctmimna.MemberId = Trigger.new[i].OwnerId;
                                    ctmimna.ParentId = Trigger.new[i].Id;
                                    ctmimna.TeamRoleId = editRoleimna;
                                    lCTMemberIMNA.add(ctmimna);
                                    System.debug('+++++Trigger.new[i].IM_Employee_Contact__c+++'+Trigger.new[i].IM_Employee_Contact__c);
                                    System.debug('+++++Trigger.new[i].OwnerId+++'+Trigger.new[i].OwnerId);
                                    //Add IM Contact with Read access (if different from creator)
                                    if( Trigger.new[i].IM_Employee_Contact__c != null && Trigger.new[i].OwnerId != Trigger.new[i].IM_Employee_Contact__c) 
                                    {
                                        System.debug('+++++ctm2.MemberId+++'+Trigger.new[i].IM_Employee_Contact__c);
                                        System.debug('+++++ctm2.ParentId'+Trigger.new[i].Id);
                                        System.debug('+++++ctm2.TeamRoleId'+viewRoleimna);
                                        CaseTeamMember ctm1imna = new CaseTeamMember();
                                        ctm1imna.MemberId = Trigger.new[i].IM_Employee_Contact__c;
                                        ctm1imna.ParentId = Trigger.new[i].Id;
                                        ctm1imna.TeamRoleId = viewRoleimna;
                                        lCTMemberIMNA.add(ctm1imna);                    
                                    }
                                }
                            }
                            if (lCTMemberIMNA.size() > 0)
                                insert lCTMemberIMNA;        
                        }
                        else if ( Trigger.isAfter && Trigger.isUpdate ) 
                        {
                            List<CaseTeamMember> lCTMember4Deleteimna = new List<CaseTeamMember>();
                            List<CaseTeamMember> lCTMember4Insertimna = new List<CaseTeamMember>();
                            Set<Id> caseIdWithUpdatedContactimna = new Set<Id>();
                            Integer flag = 1;
                            
                            if( (Trigger.new[0].RecordTypeId == imRecTypeIdIMNA ) && 
                               Trigger.new[0].IM_Employee_Contact__c != Trigger.old[0].IM_Employee_Contact__c) 
                            {
                                caseIdWithUpdatedContactimna.add(Trigger.new[0].Id);
                                List<CaseTeamMember> lctmimna = [SELECT Id, MemberId, ParentId, TeamRoleId FROM CaseTeamMember WHERE ParentId in :caseIdWithUpdatedContactimna];
                                
                                for (Integer i=0; i< lctmimna.size(); i++ ) 
                                {
                                    if (Trigger.old[0].IM_Employee_Contact__c == lctmimna.get(i).MemberId && lctmimna.get(i).TeamRoleId == viewRoleimna) 
                                    {
                                        lCTMember4Deleteimna.add(lctmimna.get(i));
                                    } else if (Trigger.new[0].IM_Employee_Contact__c == lctmimna.get(i).MemberId )
                                        flag = 0;
                                }
                                if ( flag == 1 && Trigger.new[0].IM_Employee_Contact__c != null) 
                                {
                                    CaseTeamMember c1imna = new CaseTeamMember();
                                    c1imna.MemberId = Trigger.new[0].IM_Employee_Contact__c;
                                    c1imna.ParentId = Trigger.new[0].Id;
                                    c1imna.TeamRoleId = viewRoleimna;
                                    lCTMember4Insertimna.add(c1imna);
                                }
                                if (lCTMember4Deleteimna.size() > 0)
                                    delete lCTMember4Deleteimna ;
                                
                                if (lCTMember4Insertimna.size() > 0)
                                    insert lCTMember4Insertimna;
                            }    
                        }
                    }
                    catch (DMLException dmlex)
                    {
                        Trigger.new[0].addError('Failed to Update Case Team members'+dmlEx.getDmlId(0)+' Error: '+dmlex.getMessage());
                    }
                    catch(Exception ex)
                    {
                        Trigger.new[0].addError('Failed to Update Case Team members!'+ex.getMessage());          
                    } 
                }
            }
        }    
        
        if(trigger.isBefore)
{
if(trigger.isInsert || trigger.isUpdate)
{
if(DateOnDataEntryDateMembers == 'TRUE')
{    
system.debug('-----enterintoloop----');
Set<Id> recordTypeIdForSKP_Department_Add_Only=new Set<Id>();
Set<Id> recIdsForUpdateDateOnBoarderCSA=new Set<Id>();
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

Set<Id> UserIdsFromCustomSettingsnew = new Set<Id>();
List<Data_Entry_Date_Members__c> allowedusersnew=Data_Entry_Date_Members__c.getAll().values();
System.Debug('---allowedusersnew---'+allowedusersnew);
for(Data_Entry_Date_Members__c dedm:allowedusersnew)
{
UserIdsFromCustomSettingsnew.add(dedm.UserID__c);
}
for(case c:trigger.new)
{
String currentUserId=c.ownerId;
System.debug('currentUserId---'+currentUserId);
System.debug('c.ownerId---'+c.ownerId);
if(UserIdsFromCustomSettingsnew.contains(c.OwnerId))
{
if((recIdsForUpdateDateOnBoarderCSA.contains(c.RecordTypeId))||(recordTypeIdForSKP_Department_Add_Only.contains(c.RecordTypeId)))
{
if(c.Data_Entry_Owner__c == null)
{
//c.Assigned_To_Data_Entry_Date__c=datetime.now();
c.Data_Entry_Owner__c = c.ownerId;
System.debug('c.Data_Entry_Owner__c----'+c.Data_Entry_Owner__c);
}

}

}

}
}
}
}
       
       if(trigger.isBefore)
        {
            if(trigger.isUpdate)
            {
                if(NCSPDateValidationRulesTrigger=='True')
                {   
                    if(triggerFlowControl.triggerRunCount('NCSPDateValidationRulesTrigger') <= 1)
                    { 
                        Set<Id> recordTypeIdForSKP_Department_Add_Only=new Set<Id>();
                        Set<Id> recIdsForUpdateDateOnBoarderCSA=new Set<Id>();
                        Map<String,Schema.RecordTypeInfo> DateOnBoarderMapByrecName = RecordTypeSelection.getRecordTypeIds(); //d.getRecordTypeInfosByName();
                        if(DateOnBoarderMapByrecName.containsKey('NCSP: SKP Department Add Only'))
                        {
                            recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP: SKP Department Add Only').getRecordTypeId());
                        }
                        if(DateOnBoarderMapByrecName.containsKey('NCSP: Upsell'))
                        {
                            recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP: Upsell').getRecordTypeId());
                        }
                        if(DateOnBoarderMapByrecName.containsKey('NCSP: New Customer Setup'))
                        {
                            recordTypeIdForSKP_Department_Add_Only.add(DateOnBoarderMapByrecName.get('NCSP: New Customer Setup').getRecordTypeId());
                        }
                        if(DateOnBoarderMapByrecName.containsKey('NCSP: DP New Customer Setup'))
                        {
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
                        for(Case newCase : trigger.new)
                        {
                            Case oldCase = null;
                            if( !insTrig ) {
                                oldCase = Trigger.oldMap.get(newCase.Id);
                            }
                            
                            if(((recIdsForUpdateDateOnBoarderCSA.contains(newCase.RecordTypeId))||(recordTypeIdForSKP_Department_Add_Only.contains(newCase.RecordTypeId)))
                               && newCase.Setup_Complete_Date__c != null 
                               && (getDate(newCase.Setup_Complete_Date__c) < sysToday || getDate(newCase.Setup_Complete_Date__c) > sysToday)
                               && (insTrig || newCase.Setup_Complete_Date__c != oldCase.Setup_Complete_Date__c )) 
                            {
                                System.debug('Setup_Complete_Date__c-1----'+newCase.Setup_Complete_Date__c);
                                newCase.Setup_Complete_Date__c.addError('Setup Complete Date cannot be a date in the Past or Future.');
                            }
                            if(((recIdsForUpdateDateOnBoarderCSA.contains(newCase.RecordTypeId))||(recordTypeIdForSKP_Department_Add_Only.contains(newCase.RecordTypeId)))
                               && newCase.Upload_to_DRCI_Complete_Date__c != null 
                               && (getDate(newCase.Upload_to_DRCI_Complete_Date__c) < sysToday || getDate(newCase.Upload_to_DRCI_Complete_Date__c) > sysToday)
                               && (insTrig || newCase.Upload_to_DRCI_Complete_Date__c != oldCase.Upload_to_DRCI_Complete_Date__c )) 
                            {
                                System.debug('Upload_to_DRCI_Complete_Date__c-1-'+newCase.Upload_to_DRCI_Complete_Date__c);
                                newCase.Upload_to_DRCI_Complete_Date__c.addError('Upload to DRCI Complete Date cannot be a date in the Past or Future.');
                            }
                            // As per the case(no 05142766), No_Longer_In_Jeopardy_Date__c has been deleted 
                           if(((recIdsForUpdateDateOnBoarderCSA.contains(newCase.RecordTypeId))||(recordTypeIdForSKP_Department_Add_Only.contains(newCase.RecordTypeId)))
&& newCase.No_Longer_In_Jeopardy_Date__c != null 
&& (getDate(newCase.No_Longer_In_Jeopardy_Date__c) < sysToday || getDate(newCase.No_Longer_In_Jeopardy_Date__c) > sysToday)
&& (insTrig || newCase.No_Longer_In_Jeopardy_Date__c != oldCase.No_Longer_In_Jeopardy_Date__c )) 
{
System.debug('No_Longer_In_Jeopardy_Date__c-1-'+newCase.No_Longer_In_Jeopardy_Date__c);
newCase.No_Longer_In_Jeopardy_Date__c.addError('No Longer In Jeopardy Date cannot be a date in the Past or Future.');
}//Commented till here. // As per the case(no 05142766), No_Longer_In_Jeopardy_Date__c has been deleted 

                        }
                    }
                }
            }
        }
    }*/ // #25723,#25946 Commenting Code End.
}