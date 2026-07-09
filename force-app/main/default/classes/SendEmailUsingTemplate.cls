/********************************************************************************************************
* @Description: This Apex Class is created to Send Email Notification for Global Service Case Record Type. This is getting used in Global Service Case Flow 'GSC_Case_After_Update_Flow' to send email to customer when Send Closure Email is checked and Status is either Resolved or Customer Unresponsive
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  04/21/2023(MM/DD/YYYY)
* @TestClass Name: SendEmailUsingTemplateTest
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/21/2023 - Simranjit Kaur - Initial Development - GitLab #14478
*
* 06/13/2023 (MM/DD/YYYY) - Simranjit Kaur - Updated for Reopened and Child Case Email Notifications to customer - GitLab #16275 and #16276
* 
* 10/30/2023 (MM/DD/YYYY) - Simranjit Kaur - Updated for all email notifications to send Notifications for Default scenarios. - GitLab #19174
*
* 12/04/2023 (MM/DD/YYYY) - Simranjit Kaur - Updated for all email notifications to skip Email Notifications for Case Origins mentioned as true in Disable Notification field in GSC Metadata. - GitLab #20010
* ===================================================
*
********************************************************************************************************/
global class SendEmailUsingTemplate {
    
   global class DataWrapper {

    @InvocableVariable(label='Record ID' required=true)
    public Id recordID;
    @InvocableVariable(label='To Address' required=true)
    public String toAddress;
   	@InvocableVariable(label='Contact Id' required=true)
    public Id contactId;
    @InvocableVariable(label='Country' required=true)
    public String country;
    @InvocableVariable(label='Origin' required=true)
    public String origin;
    @InvocableVariable(label='Notification Type' required=true)
    public String type;
    @InvocableVariable(label='Record Type Name')
    public String recordTypeName;   
}
    @invocableMethod(label='Send Email Using Template')
	public static void SendEmailTemplateWithTemplate(List<DataWrapper> passedData) {   
    for (DataWrapper dw: passedData) {
        
        GSC_Case_Country_Closure_Email__mdt[] closureEmail = new GSC_Case_Country_Closure_Email__mdt[]{};
        EmailTemplate[] et = new EmailTemplate[]{};
        if(dw.type=='Closed')
        {
            if(dw.recordTypeName=='Global Service Case'){
                closureEmail = [Select GSC_Case_Origin__c, GSC_Country__c, GSC_Email_Template_Name__c, GSC_From_Address__c,Disable_Notifications__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:dw.Origin and GSC_Email_Template_Name__c <> null LIMIT 1];
                if(closureEmail.size()>0 && closureEmail[0].Disable_Notifications__c == true)
                {	return;
                }
                else if(closureEmail.size()==0)
                {
                    closureEmail =  [Select GSC_Case_Origin__c, GSC_Country__c, GSC_Email_Template_Name__c, GSC_From_Address__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:dw.country and GSC_Email_Template_Name__c <> null and Default__c=:true LIMIT 1];
                }
                et = [SELECT Id FROM EmailTemplate WHERE Name =:closureEmail[0].GSC_Email_Template_Name__c LIMIT 1];
            }
            if(dw.recordTypeName=='Global Orders'){
                closureEmail = [Select GSC_Case_Origin__c, GSC_Country__c, GO_Closed_Email_Template_Name__c, GSC_From_Address__c,Disable_Notifications__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:dw.Origin and GO_Closed_Email_Template_Name__c <> null LIMIT 1];
                if(closureEmail.size()>0 && closureEmail[0].Disable_Notifications__c == true)
                {	return;
                }
                else if(closureEmail.size()==0)
                {
                    closureEmail =  [Select GSC_Case_Origin__c, GSC_Country__c, GO_Closed_Email_Template_Name__c, GSC_From_Address__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:dw.country and GO_Closed_Email_Template_Name__c <> null and Default__c=:true  LIMIT 1];
                }
                et = [SELECT Id FROM EmailTemplate WHERE Name =:closureEmail[0].GO_Closed_Email_Template_Name__c LIMIT 1];
            }
        }
        else if(dw.type=='Reopened')
        {
            closureEmail = [Select GSC_Case_Origin__c, GSC_Country__c, GSC_Reopened_Email_Template_Name__c, GSC_From_Address__c,Disable_Notifications__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:dw.Origin and GSC_Reopened_Email_Template_Name__c <> null LIMIT 1];
            if(closureEmail.size()>0 && closureEmail[0].Disable_Notifications__c == true)
                {	return;
                }
            else if(closureEmail.size()==0)
            {
                closureEmail =  [Select GSC_Case_Origin__c, GSC_Country__c, GSC_Reopened_Email_Template_Name__c, GSC_From_Address__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:dw.country and GSC_Reopened_Email_Template_Name__c <> null and Default__c=:true LIMIT 1];
            }
            et = [SELECT Id FROM EmailTemplate WHERE Name =:closureEmail[0].GSC_Reopened_Email_Template_Name__c LIMIT 1];
        }
        else if(dw.type=='New')
        {
            closureEmail = [Select GSC_Case_Origin__c, GSC_Country__c, GSC_New_Email_Template_Name__c, GSC_From_Address__c,Disable_Notifications__c from GSC_Case_Country_Closure_Email__mdt where GSC_Case_Origin__c =:dw.Origin and GSC_New_Email_Template_Name__c <> null LIMIT 1];
            if(closureEmail.size()>0 && closureEmail[0].Disable_Notifications__c == true)
                {	return;
                }
            else if(closureEmail.size()==0)
            {
                closureEmail =  [Select GSC_Case_Origin__c, GSC_Country__c, GSC_New_Email_Template_Name__c, GSC_From_Address__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:dw.country and GSC_New_Email_Template_Name__c <> null and Default__c=:true  LIMIT 1];
            }
            et = [SELECT Id FROM EmailTemplate WHERE Name =:closureEmail[0].GSC_New_Email_Template_Name__c LIMIT 1];
        }
            // String formattedToken = EmailMessages.getFormattedThreadingToken(dw.recordID); //  Use this method to get FormattedToken for Lightning Thread Token for mapping the emails back to Case
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            // Fetch Org Wide Email Address if sender is filled
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:closureEmail[0].GSC_From_Address__c];
            
            if(owea.size()>0){
            mail.setOrgWideEmailAddressId(owea[0].id);
            }
            else{
            mail.setReplyTo(closureEmail[0].GSC_From_Address__c);
            }
      
        //mail.setSenderDisplayName(closureEmail.GSC_From_Address__c);        mail.setReplyTo(closureEmail.GSC_From_Address__c);
        if(et.size()>0){
            mail.setTemplateId(et[0].Id);
            mail.setTargetObjectId(dw.contactId);
            mail.setTreatTargetObjectAsRecipient(true);
            mail.setWhatId(dw.recordID);
            System.debug(dw.recordID);
            mail.setToAddresses(new String[] { dw.toAddress});
            mail.setSaveAsActivity(true);
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            allmsg.add(mail);
            try {
                List<Messaging.SendEmailResult> sendResults = Messaging.sendEmail(allmsg);
                System.debug(sendResults);
                return;
            } 
            catch (Exception e) {
                System.debug(e.getMessage());
             } 
        }
        else{
           List<Exception_log__C> exceptionList = new List<Exception_log__C>();
           Exception_log__C newException = new Exception_log__C(Class_Reference__C = 'SendEmailUsingTemplate', Error_Message__C = 'No Email Template found', Exception_Type__C ='DML', Name = 'Email Notification Error', Originating_Org__C ='Core', Record_id__C= dw.recordID , Stack_Trace__c ='Global service Case/Global Orders - Email notification - error Occurred');
           exceptionList.add(newException);
           List<Database.saveResult> exceptionInsertedResult = Database.Insert(exceptionList);
        }          
    }
    }

}