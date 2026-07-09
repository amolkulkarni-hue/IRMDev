/**  
       * Name: IRM_SC_SendEmailOnOwnerChange
       * Description: User above in role hierarchy modifies a case assigned to some other user then email 
                  notification should be sent to the owner of the case.  
       * Copyright: HCL Technologies
       * Author: Himanshu Jain
       * Modification Log: Created:6-Mar-2012
**/

Public Class  IRM_SC_SendEmailOnOwnerChange
{
    
    private static Boolean firstRun = true;
    
    Public Static void  sendEmail(List<Case> caseNew,Map<id,Case>caseOld)
    {
        List<OrgWideEmailAddress> orgAddress = IRM_SC_UtilityClass.getOrgWideAddress(caseNew[0]);
        String templateName = 'IME_SC_'+caseNew[0].IME_SC_Country_Code__c+'_Notify_Owner_Modification';
        List<EmailTemplate> lstFellowUpTemplate = new List<EmailTemplate>();
        if(firstRun != false)
        {
            firstRun = false;
            lstFellowUpTemplate = [select Id,Name,Subject,body, IsActive from EmailTemplate where name = :templateName LIMIT 1];
        }
        
        if(lstFellowUpTemplate != NULL && lstFellowUpTemplate.size() > 0 && lstFellowUpTemplate[0].IsActive == true)
        {
            /* Case number:01239555 
               Description: added a condition to check email is invalid@ironmountain.com or not
             */
            EmailTemplate FellowUpTemplate = lstFellowUpTemplate[0];
            // ID oldCaseID;
            Case caseOldRec;
            if(caseOld != null && !caseOld.isEmpty())
                caseOldRec = caseOld.get(caseNew[0].id);   
            if ( caseOldRec != null && caseOldRec.OwnerId!= UserInfo.getUserId() && 
                 String.valueof(caseOldRec.OwnerID).StartsWith('005') && 
                 caseOldRec.IME_SC_Case_Owner_Email__c != null && caseNew[0].IME_SC_Case_Owner_Email__c!='invalid@ironmountain.com'
                ) 
            {
                
                try
                {
                    Contact tempContact = IRM_SC_UtilityClass.getContactInfo();
                    if(tempContact != NULL)
                    {
                    	tempContact.Email = caseOldRec.IME_SC_Case_Owner_Email__c;
                    	update tempContact;
                    }
                    If(tempContact != NULL && tempContact.email != null)
                    {
                        
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        if(orgAddress != null && !orgAddress.isEmpty() && orgAddress[0] != null)
                        {
                           mail.setOrgWideEmailAddressId(orgAddress[0].Id);
                        }
                        mail.saveAsActivity = false;                        
                        mail.settargetobjectID(tempContact.Id);
                        mail.setTemplateId(fellowUpTemplate.Id);
                        mail.setWhatId(caseOldRec.Id);
                        mail.setUseSignature(false);
                        mail.setSaveAsActivity(false);
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
                        tempContact.Email = null;
                        update tempContact;
                    }
                }
                catch(System.Queryexception QE)
                {
                     system.debug('In Catch Block');
                } 
                
            }  
        }
    }
}