/*
Developer : Arun Rajendran
Date       : 05/13/2019
Case#      : 09797722
Description: Create a new case when a Qualtrics record on CX Survey Details object satisfies required conditions

Date       : 25-Aug-2019
Case       : 10060044 (Qualtrics Integration Wave 2)
Change     : Added new condition for NAS and handled new validation rules for both NAS and IME#

*/


trigger CreateQualtricsCase on CX_Survey_Details__c (after insert, after update) {

    
/** variable declaration **/
    
//Commenting code as part of #24270    
/*Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('IME SC Case').getRecordTypeId();
List<Case> cases = new List<case>();  
Map<Id, CX_Survey_Details__c> oldCxList = new map<id, CX_Survey_Details__c >();
id cxSurveyRecId =  Trigger.new.get(0).id;

//Fetch previous value in case of update
if(Trigger.isUpdate)
{
    for(CX_Survey_Details__c cxOld : Trigger.old)
    {
        oldCxList.put(cxOld.id, cxOld);
    }
}

 System.debug('Execution of triiger');
//Create case
    for(CX_Survey_Details__c cxRec : Trigger.new)
    {   
        SYSTEM.debug('oldCxList -->'+ oldCxList);
        CX_Survey_Details__c cxOld = oldCxList.get(cxRec.id);
        if(Trigger.isInsert || Trigger.isUpdate){
            if( (Null ==cxRec.Case__c) && (null != cxRec.country__c  && ((cxRec.country__c != 'USA' && cxRec.country__c != 'CAN' ) && (cxRec.country__c != 'United States' && cxRec.country__c != 'Canada' ))) && (cxRec.To_Be_Contacted__c == true || (Trigger.isUpdate && cxRec.To_Be_Contacted__c == true && cxOld.To_Be_Contacted__c == false)))
            {
            System.debug('Global Txn CC : Creating Global Case');
            Case c = new Case();
            c.RecordTypeId = imeCaseRecordTypeID;
            c.ContactId = cxRec.Contact__c;
            c.Subject = cxRec.Program__c;
            c.Status = 'Validated';
            c.Description = cxRec.FollowUp_Reason__c;
            c.Origin = 'IME_Survey';
            c.IME_SC_Category__c = 'Complaints';
            c.IME_SC_Sub_Category__c = 'Bad Survey Score';
            c.IME_SC_Country__c = cxRec.Country__c;
            c.IME_SC_Case_Email__c = cxRec.Respondent_Email__c;
            c.Case_Contact_Name__c = cxRec.Source_Sys_Name__c;
            c.IME_SC_Order_Id__c = cxRec.Source_Sys_Order_Number__c;
            c.IME_SC_Case_Phone__c = cxRec.Source_Sys_Phone__c;
            c.Source_Sys_Customer_Name__c = cxRec.Source_Sys_Customer_Name__c;
            c.IME_SC_Customer_AccountId__c = cxRec.Source_Sys_Customer_ID__c;
            c.Source_Sys_Country_Code__c = cxRec.Source_Sys_Country_Code__c;
            
            
           //Pass through assignment rules
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;
            c.setOptions(dmlOpts); 
           // system.debug('++++ Assignment rules call over +++++');
                                  
            cases.add(c);
            
            }  else if((Null ==cxRec.Case__c) &&( null != cxRec.country__c && (cxRec.country__c == 'USA' || cxRec.country__c == 'CAN' || cxRec.country__c == 'United States' || cxRec.country__c == 'Canada')) && ((cxRec.To_Be_Contacted__c == true) || (Trigger.isUpdate && cxRec.To_Be_Contacted__c == true && cxOld.To_Be_Contacted__c == false)))
                       {
                        System.debug('NAS Txn CC : NAS ');
                           List<Case> origCaseRec;
                           if(null != cxRec.Original_Case_Number__c){
                                origCaseRec = [SELECT NAS_Service_Market__c, NAS_Service_Line_Associated_to_Ask__c FROM CASE WHERE id =:cxRec.Original_Case_Number__c ]; 
                            }
                                                 
                        Case c = new Case();
                       // c.RecordTypeId = getRecordTypeId(cxRec.Country__c);
                        c.RecordTypeId = caseRecordTypeIdMap.get('NAS General Support Case').getRecordTypeId();
                        c.ContactId = cxRec.Contact__c;
                        c.Subject = cxRec.Program__c;
                        c.Status = 'New';
                        c.Description = cxRec.FollowUp_Reason__c;
                        c.Origin = 'IME_Survey';
                        c.Type = 'Survey Follow Up';
                        c.SuppliedEmail  = cxRec.Respondent_Email__c;
                    //  c.NAS_SKP_Country__c = cxRec.Country__c;
                        c.Customer_ID__c = cxRec.Source_Sys_Customer_ID__c;
                     // c.Division_ID__c = null != origCaseRec && origCaseRec.size() > 0  ?  origCaseRec[0].Division_ID__c : null;
                     // c.Department_ID__c = null != origCaseRec && origCaseRec.size() > 0  ?  origCaseRec[0].Department_ID__c : null;
                     // c.NAS_Service_Market__c = null != origCaseRec && origCaseRec.size() > 0  ?  origCaseRec[0].NAS_Service_Market__c : '';
                        c.NAS_Service_Line_Associated_to_Ask__c = null != origCaseRec && origCaseRec.size() > 0  ?  origCaseRec[0].NAS_Service_Line_Associated_to_Ask__c : '';
            
                        //Pass through assignment rules
                        Database.DMLOptions dmlOpts = new Database.DMLOptions();
                        dmlOpts.assignmentRuleHeader.useDefaultRule = true;
                        c.setOptions(dmlOpts); 
                    
                        cases.add(c);
                       }
        }
          
        }
    system.debug('Created Cases Size  :' + cases.size());
     if(null != cases && cases.size() > 0){
         CX_Survey_Details__c newCXSurRec = new CX_Survey_Details__c();
           try{
               system.debug('Case to create ' + cases);
               insert cases;
               system.debug('Created Case ID :' + cases.get(0).id);
               
               newCXSurRec.id = cxSurveyRecId;
               newCXSurRec.Case__c = cases.get(0).id;
               
               update   newCXSurRec;
               system.debug('Updated Survey record ID :' + newCXSurRec);
               cases.clear();
            }catch(Exception e){
            cases.clear();
            system.debug('Unable to create Case :' + e);
                Trigger.new[0].addError('Unable to create case. Please contact administrator :' + e);
              }
            } */
    }