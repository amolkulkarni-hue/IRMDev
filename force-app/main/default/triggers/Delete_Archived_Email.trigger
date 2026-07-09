/**  
       * Name: Delete_Archived_Email
       * Description: To restrict users who do not have archiver profile from deleting attachment that are related to Email Archiving.
       * Author: Vinutha Iyengar
**/
trigger Delete_Archived_Email on Attachment (before delete) {

    boolean allowDeletion = false;
    Id CurrentUserprofileId=userinfo.getProfileId();
    List<Attachment> ArchiverAttachs = new List<Attachment>();
    List<Attachment> attachments = [select Id, CreatedBy.ProfileId from Attachment where id in :trigger.old];
     
    List<String> ProfileList = Label.Email_Archive_Profiles.split(';');
    for(integer i = 0; i < ProfileList.size(); i++)
    {
        if(ProfileList[i] == CurrentUserprofileId){
            allowDeletion = true;
            break;
        }
    }
            
    //Disable deletion of attachments created by archive tool  except for Archiver profiles
    // --- For Archived emails, Name of the attachment will start with "cumulusforce"
    List<Datetime> datelist = new List<Datetime>();
    List<Id> caseIds = new List<Id>();
    for(Attachment emailAsAttachment : trigger.old)
    {    
        if(!allowDeletion && emailAsAttachment.name.startswith('cumulusforce'))
        {
            emailAsAttachment.addError(System.Label.IME_SC_AttachmentDeletion);
        }     
        datelist.add(emailAsAttachment.CreatedDate);
        caseIds.add(emailAsAttachment.parentId);
    }
    
    datelist.sort();
	Datetime minDate=datelist.get(0);
	Datetime maxDate=datelist.get(datelist.size()-1);
    minDate=minDate.addMinutes(-5);
    maxDate=maxDate.addMinutes(5);
 
    List<Attachment> relatedAttach = [select Id,parentId from Attachment where name like 'cumulusforce%' and parentId in :caseIds and CreatedBy.ProfileId in :ProfileList and CreatedDate >= :minDate and CreatedDate <= :maxDate];
    
    //Disable deletion of attachments that were attached to the email except for Archiver profiles
    for(Attachment emailAsAttachment : trigger.old)
    {   
        for(Attachment relatedEmail : relatedAttach)
        {    
            if(!allowDeletion && emailAsAttachment.parentId==relatedEmail.parentId)  
            {   
                emailAsAttachment.addError(System.Label.IME_SC_AttachmentDeletion);
        	}
        }
    }
}