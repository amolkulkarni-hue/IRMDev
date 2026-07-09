/**
    Initial trigger development
    
    Developer  : Sandhya Ramesh/IMS
    Date       : 05/13/2015
    Case       : 03704707
    Description: Create a new case when a Walker record on CX Survey Details object satisfies required conditions
    
**/


trigger CreateWalkerCase on CX_Survey_Details__c (after insert, after update) {

/** variable declaration **/
Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('IME SC Case').getRecordTypeId();
List<Case> cases = new List<case>();  
Map<Id, CX_Survey_Details__c> oldCxList = new map<id, CX_Survey_Details__c >();


//Fetch previous value in case of update
if(Trigger.isUpdate)
{
    for(CX_Survey_Details__c cxOld : Trigger.old)
    {
        oldCxList.put(cxOld.id, cxOld);
    }
}


//Create case
    for(CX_Survey_Details__c cxRec : Trigger.new)
    {   
        CX_Survey_Details__c cxOld = oldCxList.get(cxRec.id);
       /* TO REMOVE : Commenting for changing field type Follow up reason 
           if((Trigger.isInsert && cxRec.FollowUp_Reason__c != null) || (Trigger.isUpdate && cxRec.FollowUp_Reason__c != null && cxOld.FollowUp_Reason__c == null) ) 
        { */
            Case c = new Case();
            c.RecordTypeId = imeCaseRecordTypeID;
			c.ContactId = cxRec.Contact__c;
            c.Subject = 'CX Survey: Red Flag';
            c.Status = 'Validated';
           // Commenting for changing field type Follow up reason data type from Text to Text Area :  
		   //c.Description = cxRec.FollowUp_Reason__c;
            c.Origin = 'IME_Survey';
            c.IME_SC_Category__c = 'Complaints';
            c.IME_SC_Sub_Category__c = 'Bad Survey Score';
            c.Respondent_ID__c = cxRec.Respondent_ID__c;
            c.SS_Template_ID__c = cxRec.SS_Template_ID__c;
            c.CX_Program__c = cxRec.Program__c;
            c.FollowUp_Type__c  = cxRec.FollowUp_Type__c;
            c.Survey_Type__c =cxRec.Survey_Type__c;
            c.IME_SC_Country__c=cxRec.Contact_Country__c;
            
            /*Adding below fields for Phase 3*/
            c.Source_Sys_Country_Code__c = cxRec.Source_Sys_Country_Code__c;
            c.Source_Sys_Customer_ID__c = cxRec.Source_Sys_Customer_ID__c;
            c.IME_SC_Case_Email__c = cxRec.Source_Sys_Email__c;
            c.Case_Contact_Name__c = cxRec.Source_Sys_Name__c;
            c.IME_SC_Order_Id__c = cxRec.Source_Sys_Order_Number__c;
            c.IME_SC_Case_Phone__c = cxRec.Source_Sys_Phone__c;
            c.Source_Sys_Customer_Name__c = cxRec.Source_Sys_Customer_Name__c;
            
            system.debug('++++ About to call Assignment rules +++++');
            //Pass through assignment rules
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;
            c.setOptions(dmlOpts); 
            system.debug('++++ Assignment rules call over +++++');
            
/*            AssignmentRule AR = new AssignmentRule(); 
            //Assignment Rule Query
            AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
            //Creating DML Options
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            if(AR != null){
           dmlOpts.assignmentRuleHeader.assignmentRuleID = AR.ID;
           c.setOptions(dmlOpts); 
            } */

            cases.add(c);
        // } Commenting for changing field type Follow up reason
    }
    
    insert cases;
    cases.clear();
}