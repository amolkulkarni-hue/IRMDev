/**  
       * Name: IRM_SC_Attachmentdeletion
       * Description: To restrict user from deleting attachment from Emails associated with CS Cases with Record type of IME SC Case and IME SC Case Resolved record type 
       * Copyright: HCL Technologies
       * Author: Himanshu Jain
       * Modification Log: Created:16-August-2012
                           Modified: 16-Mar 2015 by Sandhya to add Custom Settings.
	   * Modified By: Vinutha Iyengar on 25-Nov-2015 
	   * 					--To allow Email deletion for Email Archiver Profiles
**/
trigger IRM_SC_Attachmentdeletion on Attachment (before delete) {
    Set<ID> emailId = new Set<ID>();
    Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
    Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('IME SC Case').getRecordTypeId();
    Id imeCaseResolvedRecordType = caseRecordTypeIdMap.get('IME SC Case Resolved').getRecordTypeId();
    boolean allowDeletion = false;
    
    public String deleteAttachment = null;
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings)
    {
      if(cs.Object__c=='Case')
        {
          if(cs.Trigger__c == 'IRM_SC_Attachmentdeletion') 
          {
              deleteAttachment = cs.Value__c;  
          }
        }
    }
    
    if(deleteAttachment == 'TRUE')
    {
        //Allow Email deletion for Email Archiver Profiles
        Id profileId=userinfo.getProfileId();
        List<String> ProfileList = Label.Email_Archive_Profiles.split(';');
        for(integer i = 0; i < ProfileList.size(); i++)
        {
            if(ProfileList[i] == profileId){
                allowDeletion = true;
                break;
            }
        }
        
    
    for( Attachment emailAttachment : trigger.old ) {
    // Check the parent ID - if it's 02s, this is for an email message
        if( emailAttachment.parentid == null )
            continue;
        String attachmentIDPrefix = string.valueof( emailAttachment.parentid );
        system.debug('+++++ email attachment parent id is ++++' + attachmentIDPrefix);
        
        if( attachmentIDPrefix.substring( 0, 3 ) == '02s' )
            //adding Parent ID if parent is Email Message record
            emailId.add(emailAttachment.parentid);      
    }
     List<EmailMessage> allNewCases = new List<EmailMessage>();
     allNewCases = [Select Status, ParentId, Id, Parent.RecordTypeID From EmailMessage where Id IN : emailId];
    for(Attachment emailAttachment : trigger.old)
    {
        if(allNewCases != NULL && allNewCases.size() > 0)
        {
            for(EmailMessage caseMessage : allNewCases)
            {
                if(!allowDeletion && caseMessage.id == emailAttachment.parentid && (caseMessage.Parent.RecordTypeID == imeCaseRecordTypeID ||caseMessage.Parent.RecordTypeID == imeCaseResolvedRecordType))
                {
                    emailAttachment.addError(System.Label.IME_SC_AttachmentDeletion);
                }
            }
        }
    }
    }
}