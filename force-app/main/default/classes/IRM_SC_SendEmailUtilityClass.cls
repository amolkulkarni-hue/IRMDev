/**  
       * Name: IRM_SC_SendEmailUtilityClass
       * Description: Utility Class to send an email.  
       * Copyright: HCL Technologies
       * Author: Sejal Shah
       * Modification Log: Created:16-Apr-2012
                           Modified By Himanshu Jain 
                           12-Sep-2012 Changed Code against the case no :00773324  
                                       To add Closure email to Email Message related list
**/
/**
       * Developer Name: Vijay Andrews
       * Description: Added  Condition to Check the Email Should not Trigger for Closed Cases after any Changes made.
       * Case Number:03363081
       * Updated: 2/10/2015
**/
public with sharing class IRM_SC_SendEmailUtilityClass {
    
    public void sendEmail(Case caseToSendEmail, Contact tempContact,Map<Id,Case> oldCaseMap1)
    {
        List<EmailTemplate> templateId = new List<EmailTemplate>();
        templateId = IRM_SC_UtilityClass.getEmailTemplateList(caseToSendEmail);
        List<OrgWideEmailAddress> orgAddress = IRM_SC_UtilityClass.getOrgWideAddress(caseToSendEmail);
        if(templateId != null && !templateId.isEmpty() && templateId[0] != null && templateId[0].IsActive == true)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Strings to hold the email addresses to which you are sending the email.
            String toAddress = caseToSendEmail.IME_SC_To_Address__c;
            String ccAddress = caseToSendEmail.IME_SC_Cc_Address__c;
            String bccAddress = caseToSendEmail.IME_SC_Bcc_Address__c;
            String[] toAddresses;
            String[] ccAddresses;
            String[] bccAddresses;
            if(toAddress != null)
                toAddresses = toAddress.split(',');
            if(ccAddress != null)
                ccAddresses = ccAddress.split(',');
            if(bccAddress != null)
                bccAddresses = bccAddress.split(',');
             // Assign the addresses for the To and CC lists to the mail object.
           // if(toAddresses != null)
           //     mail.setToAddresses(toAddresses);
            if(ccAddresses != null)
                mail.setCcAddresses(ccAddresses);
            if(bccAddresses != null)
                mail.setBccAddresses(bccAddresses);
            if(orgAddress != null && !orgAddress.isEmpty() && orgAddress[0] != null)
            {
                mail.setOrgWideEmailAddressId(orgAddress[0].Id);
            }
            mail.setTemplateID(templateId[0].Id);
            system.debug('+++++++++ template++++++++++++'+ templateId[0].Id);
            mail.setSaveAsActivity(false);
            mail.settargetobjectID(tempContact.Id);
            system.debug('+++++++++ toaddress++++++++++++'+ tempContact.Id);
            mail.setWhatId(caseToSendEmail.id);
            mail.setReplyTo(caseToSendEmail.IME_SC_Outbound_Email_Address__c);
            //Changed Code against the case no :00773324
            //To add Closure email to Email Message related list
            if(caseToSendEmail.status == 'Closed')
            {
                mail.setSaveAsActivity(true);
            }
         /** 
            Case Number:03363081
            Description: Added the condition to check the Current Case Status is Not equal to Prior Value for Closed Cases.
         **/
            if(caseToSendEmail.Status == 'Closed' && oldCaseMap1.get(caseToSendEmail.Id).Status!= caseToSendEmail.Status)
            {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            system.debug('+++++++++ mail1++++++++++++'+ mail);
            }
            else if(caseToSendEmail.Status != 'Closed')
            {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
             system.debug('+++++++++ mail2++++++++++++'+ mail);
            }
        }
    }
}