/****************************** 
   Developer Name    : Venkateshwarlu Avula
   
   Date              : 10/03/2014
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : This class will prevent users whose profile isn’t listed in the custom object DocsignAttachAccessProfileSettings from adding or delting attachments on the ‘Signatory Information’ object
   
   Test Class        :  Apex Class  : Test_ IME_DocusignRestrictAttachment
   
   Case Number       : 02905861
******************************/
trigger IME_DocusignRestrictAttachment on Attachment (before delete, before insert, before update) {
    
    Map<String,String> profileMap = new Map<String,String>();
    String customLabelValue = System.Label.Signature_information_Label;
    Profile objProfile = [select Id,Name from profile where id = :userinfo.getProfileId()];
    //List<DocsignProfileSettings__c> customsettings = DocsignProfileSettings__c.getall().values();
    List<DocsignAttachAccessProfileSettings__c> customsettings = DocsignAttachAccessProfileSettings__c.getall().values();
    
    for(DocsignAttachAccessProfileSettings__c objDoc : customsettings )
    {
        system.debug('objDoc-----'+objDoc);
        profileMap.put(objDoc.Profile_Id__c,objDoc.Name);
    }
    
    if(Trigger.isInsert)
    { 
        List<Attachment> attLst = new List<Attachment>();
        for(Attachment att:Trigger.New)
        {
            system.debug('att.ParentId-----'+att.ParentId);
            String parentObjId = att.ParentId;
            
                system.debug('parentObjId-----'+parentObjId);
                system.debug('objProfile-----'+objProfile.Id);
                system.debug('objProfile-----'+objProfile.Name);
                system.debug('profileMap-----'+profileMap.get(objProfile.Id));
                if(parentObjId.startsWith(customLabelValue) && objProfile.Name == profileMap.get(objProfile.Id))
                {
                system.debug('entering if insert');
                    attLst.add(att);
                }
                else if(parentObjId.startsWith(customLabelValue)&& profileMap.get(objProfile.Id) == null)
                {
                system.debug('entering else insert');
                    att.addError('Insufficient Privileges to insert file.');
                }
            
            
           /* if()
            {
                if(parentObjId.startsWith('a3x') && objProfile.Name != profileMap.get(objProfile.Id))
                {
                    att.addError('Insufficient Privileges to update file.');
                }
            }*/
        }
        
        //insert attLst;
    }
    if(Trigger.isUpdate)
    { 
        List<Attachment> attLst = new List<Attachment>();
        for(Attachment att:Trigger.New)
        {
            system.debug('att.ParentId-----'+att.ParentId);
            String parentObjId = att.ParentId;
            
                system.debug('parentObjId-----'+parentObjId);
                system.debug('objProfile-----'+objProfile.Id);
                system.debug('profileMap-----'+profileMap.get(objProfile.Id));
                if(parentObjId.startsWith(customLabelValue) && objProfile.Name == profileMap.get(objProfile.Id))
                {
                   system.debug('entering if update');
                    attLst.add(att);
                }
                else if(parentObjId.startsWith(customLabelValue)&& profileMap.get(objProfile.Id) == null)
                {
                system.debug('entering else update');
                    att.addError('Insufficient Privileges to update file.');
                }
            
            
           /* if()
            {
                if(parentObjId.startsWith('a3x') && objProfile.Name != profileMap.get(objProfile.Id))
                {
                    att.addError('Insufficient Privileges to update file.');
                }
            }*/
        }
        //update attLst;
    }
    if(Trigger.isDelete)
    {
        List<Attachment> attLst = new List<Attachment>();
        for(Attachment att:Trigger.Old)
        {
            system.debug('att.ParentId--d---'+att.ParentId);
            String parentObjId = att.ParentId;
            
                system.debug('parentObjId--d---'+parentObjId);
                system.debug('objProfile--d---'+objProfile.Id);
                system.debug('profileMap--d---'+profileMap.get(objProfile.Id));
                if(parentObjId.startsWith(customLabelValue) && objProfile.Name == profileMap.get(objProfile.Id))
                {
                system.debug('entering if delete');
                    attLst.add(att);
                }
                else if(parentObjId.startsWith(customLabelValue)&& profileMap.get(objProfile.Id) == null)
                {
                system.debug('entering else delete');
                    att.addError('Insufficient Privileges to delete file.');
                }
        }
        
        //delete attLst;
       QTB_AttachmentsEditDeleteController.processDeleteAttachment(trigger.old);
    }
    
}