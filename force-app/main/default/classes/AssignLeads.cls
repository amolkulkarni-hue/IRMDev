/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   AssignLeads (Class)
**
** PURPOSE
**   Associated with Trigger to Fire Lead Assignment Rules and make checkbox to TRUE & FALSE throgh APEX. 
**
** NOTES
**   Expected invocation format:
**      Trigger will fire the active lead assignment rules when a checkbox is checked manually and change the status based on given WF rule on a lead record. 
**      After the trigger fires and the lead is reassigned- the checkbox should automatically get unchecked.
**   Associated with:
**      Trigger       : reassignLeads
**      Description   : Trigger to Fire Lead Assignment Rules.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/03/14; Srinivasa Rao/Randstad; Trigger to Fire Lead Assignment Rules.  (Project 5008000000NqsYo Case # 01275808); Initial release
**
************************************************************************/
public with sharing class AssignLeads {
    public static Boolean assignAlreadyCalled=FALSE;
    public static integer counter=0;
    public static void assign(List<Id> lids){
        System.debug('--10---in assign method-----');
        assignAlreadyCalled = TRUE;
        System.debug('---12----assignAlreadyCalled:'+assignAlreadyCalled);
        List<Lead> leads=[SELECT Id,Reassign_Lead__c,IM_Lead_Stage__c,IM_Stage_2_Entered_Date__c FROM Lead WHERE Id IN: lids];
        System.debug('---14----leads:'+leads);
        List<Lead> lup = new List<Lead>();
        for(lead l:leads){  
                l.Reassign_Lead__c = FALSE;
            	if(l.IM_Lead_Stage__c == '2-Marketing Qual' 
                   && l.IM_Stage_2_Entered_Date__c == system.today()){
                      if(counter == 0){
                      	assignAlreadyCalled = FALSE;
                      }
                      counter++; 
                 }
                Database.DMLOptions dmo = new Database.DMLOptions();
                System.debug('--18-----dmo:'+dmo);
                dmo.assignmentRuleHeader.useDefaultRule = true;
                System.debug('--19-----dmo.assignmentRuleHeader.useDefaultRule:'+dmo.assignmentRuleHeader.useDefaultRule);
                l.setOptions(dmo);          
                lup.add(l);
        }
        
        System.debug('-26---lup.size():'+lup.size() +'\t lup:'+lup);
        if (lup.size() > 0){
           update lup;
            System.debug('-29---lup:'+lup);
        }
    }
}