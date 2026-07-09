/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   PopulateApprovalStatusOnAcctPlan (Apex trigger)
**
** PURPOSE
**   We need to be able to tie "Approved" Account Plans to BoB performance, but there is no easy way 	
**   to identify whether the Account Plan has a positive approval on it, or not.. 
**
** NOTES
**   Expected invocation format:
**     whenever MAPR insertion/updation on corresponding parent Account Plan Object.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 09/30/2013; Srinivasa Rao/Randstad; Stamp of "approval" on Account Plan (Case # 01758327); Initial release
**
************************************************************************/
trigger PopulateApprovalStatusOnAcctPlan on Management_Account_Plan_Review__c (after insert, after update) {
   
    //Commenting code as part of #24270 
   /* System.debug('+++++2++++++Executing PopulateApprovalStatusOnAcctPlan Trigger++++++++++++');
    List<SFDC_Acct_Plan__c> AcctPlanList = new List<SFDC_Acct_Plan__c>();
    List<SFDC_Acct_Plan__c> AcctPlanListToUpdate = new List<SFDC_Acct_Plan__c>();
    Set<Id> recordTypeIds = new Set<Id>();
    
    //get the AccountPlan Id.
    List<Id> ActPlnIds = new List<Id>();
    for(Management_Account_Plan_Review__c MngmtAP: Trigger.new){
        ActPlnIds.add(MngmtAP.Account_Plan__c);
        System.debug('++++8+++++ActPlnIds:'+ActPlnIds);
    }    
    
    //get the LastCreatedDate MAPR.
    fillRecordTypeIds();
    AcctPlanList = [Select Id,Approval_Status__c,RecordTypeId, (Select Id,Approval_Status_TEXT__c,CreatedDate From Management_Account_Plan_Reviews__r order by CreatedDate desc LIMIT 1) From SFDC_Acct_Plan__c Where Id IN:ActPlnIds AND RecordTypeId in:recordTypeIds];
    System.debug('+++++12++++AcctPlanList:'+AcctPlanList);
    
    //Iterating LastCreatedDate MAPR Record and assigning corresponding value to 'Status' on Account Plan Record. 
    for(SFDC_Acct_Plan__c AP: AcctPlanList){        
        for(Management_Account_Plan_Review__c MAPR: AP.Management_Account_Plan_Reviews__r){
            System.debug('++++15+++MAPR:'+MAPR);
            System.debug('++++16+++MAPR.Approval_Status_TEXT__c:'+MAPR.Approval_Status_TEXT__c);
            if(MAPR.Approval_Status_TEXT__c == 'Certified'){
                AP.Approval_Status__c='Approved';
                System.debug('+++++18++++AP.Approval_Status__c:'+AP.Approval_Status__c);
                AcctPlanListToUpdate.add(AP);                
            }
            else if(MAPR.Approval_Status_TEXT__c == 'Not Certified'){
                AP.Approval_Status__c='Not Approved';
                System.debug('+++++21++++AP.Approval_Status__c:'+AP.Approval_Status__c);
                AcctPlanListToUpdate.add(AP);               
            }
            
        }
        
    }
    System.debug('+++32++++AcctPlanListToUpdate.Size:'+AcctPlanListToUpdate.Size());
    //Updating Account Plan.
    if(AcctPlanListToUpdate.Size() > 0){    
        System.debug('++++34+++++AcctPlanListToUpdate:'+AcctPlanListToUpdate);
        try{
            update AcctPlanListToUpdate;
        }Catch(DMLException e){
            System.debug('+++++++++Custom Validation Error Message:'+e.getMessage());
            for(Management_Account_Plan_Review__c MAPR: Trigger.New){
                MAPR.addError('There was a problem updating the Account Plan. This Account Plan Must be Related to the COUNTRY PARENT Account');
            }
        }
    }
    
    //Method to fetch AccountPlan Record Type
    private void fillRecordTypeIds(){
      System.debug('---52---inside RT Method-----');
      Schema.DescribeSObjectResult d = Schema.SObjectType.SFDC_Acct_Plan__c; 
      Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
      if(rtMapByName.containsKey('IMNA Account Plan')){
          recordTypeIds.add(rtMapByName.get('IMNA Account Plan').getRecordTypeId());  
          System.debug('--57--recordTypeIds:'+recordTypeIds);
      }      
    } */
     
}