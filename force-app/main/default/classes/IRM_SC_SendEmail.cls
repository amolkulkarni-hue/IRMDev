/**  
       * Name: IRM_SC_SendEmail
       * Description: 1. Send email to the "To Address" field on Case if notification name is not null (send email through Generic Workflows)
                      2. Populate "Case Owner Email" field on case page by the email address of the case owner.
       * Copyright: HCL Technologies
       * Author: Himanshu Jain
       * Modification Log: Created :6-Mar-2012
                           Modified:16-Apr-2012
**/

public class  IRM_SC_SendEmail{

    public static Boolean alreadySent=FALSE;
    public static void  sendEmail(List<Case> newCaseList, Map<Id,Case> oldCaseMap)
    {
        User caseOwner;
        Group caseQueue;
        Contact tempContact;
        String[] toAddresses;
        String toAddress;
        
        //to get Case Owner's Email
        if(Trigger.isInsert || (Trigger.isUpdate && oldCaseMap != null && !oldCaseMap.isEmpty() && oldCaseMap.get(newCaseList[0].Id) != null &&
            (oldCaseMap.get(newCaseList[0].Id).OwnerId != newCaseList[0].OwnerId))||
            (Trigger.isUpdate && ((oldCaseMap == null)||( oldCaseMap != null && oldCaseMap.isEmpty()))))
        {
            if(String.valueOf(newCaseList[0].OwnerId).startsWith('005'))
            {
                caseOwner = [Select Id, Email From User where Id = :newCaseList[0].OwnerId];
                newCaseList[0].IME_SC_Case_Owner_Email__c = caseOwner.Email;
            }
            else            
            {
                caseQueue = [Select Id, Email from Group where Id = :newCaseList[0].OwnerId];
                newCaseList[0].IME_SC_Case_Owner_Email__c = caseQueue.Email;
            }
        }
        
        //to send email notification through generic workflows
         /* Case number:01239555 
           Description: added a condition to check email is invalid@ironmountain.com or not
         */
       if(newCaseList[0].IME_SC_Notification_Name__c != null && newCaseList[0].IME_SC_Case_Owner_Email__c!='invalid@ironmountain.com')
       {
            //to query the dummy Contact
            tempContact = IRM_SC_UtilityClass.getContactInfo();
            toAddress = newCaseList[0].IME_SC_To_Address__c;
            if(toAddress != null)
            {
                toAddresses = toAddress.split(',');
            }
            
            if(toAddresses != null && !toAddresses.isEmpty() && toAddresses[0] != null && tempContact != null)
            {
            
                tempContact.Email = toAddresses[0];
                update tempContact;
                 
            }
            //Email sent by calling the function
            IRM_SC_SendEmailUtilityClass sendOwnerEmail = new IRM_SC_SendEmailUtilityClass();
            if(tempContact != null && tempContact.Email != null)
            {
                sendOwnerEmail.sendEmail(newCaseList[0], tempContact,oldCaseMap);
            }
            newCaseList[0].IME_SC_Notification_Name__c = null;
            newCaseList[0].IME_SC_To_Address__c = null;
            newCaseList[0].IME_SC_Bcc_Address__c = null;
            newCaseList[0].IME_SC_Cc_Address__c = null;
            if(tempContact != null)
            {
                tempContact.Email = null;
                update tempContact;
            }
       }
    }
 }