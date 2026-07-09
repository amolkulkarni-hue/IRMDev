/*
    Updated Trigger to read the email address to from list custom setting instead of emails hardcoded
    Case # : 06807159 
    Author : Vinutha Iyengar
    Date : 8/14/2017
                                  
*/ 

trigger DocuSignStatusTrigger on dsfs__DocuSign_Status__c (before update, after update) {
    
    if(Trigger.isUpdate && Trigger.isBefore)
    {
        DocuSignStatusService.processDocuSignUpdates(Trigger.New , Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUpdate)
    {
            Set<Id> caseIds = new Set<Id>();
            Set<String> docusignSenderEmails = new Set<String>();
            
            for(DocuSign_SenderEmail_List__C senderEmail: DocuSign_SenderEmail_List__c.getall().values())
            {
                docusignSenderEmails.add(senderEmail.Sender_Email__c);
            }
          
            
            for(dsfs__DocuSign_Status__c docusign: Trigger.New)
                caseIds.add(docusign.dsfs__Case__c);
            
            system.debug('caseIds'+caseIds);
                Map<Id, Case> caseMap = new Map<Id,Case>([select Id,Owner.Email,OwnerId,CaseNumber from Case where Id in :caseIds]);
                system.debug('caseMap'+caseMap);
                if(!caseMap.isEmpty()){
                for(dsfs__DocuSign_Status__c docusign: Trigger.New)
                 {
            
                    system.debug('docusignSenderEmails.contains(target)=='+docusignSenderEmails.contains(docusign.dsfs__Sender_Email__c));
           
                     string email= caseMap.get(docusign.dsfs__Case__c).Owner.Email;
                     string casenumber=  caseMap.get(docusign.dsfs__Case__c).CaseNumber;
                     Id caseid= caseMap.get(docusign.dsfs__Case__c).Id;
                    
                    /* 
                    if(docusign.dsfs__Envelope_Status__c == 'Completed' && docusign.dsfs__Sender_Email__c == 'ukiinventoryservices@ironmountain.co.uk' &&
                       (Trigger.oldMap.get(docusign.Id).dsfs__Envelope_Status__c !=Trigger.newMap.get(docusign.Id).dsfs__Envelope_Status__c || Trigger.oldMap.get(docusign.Id).dsfs__Sender_Email__c !=Trigger.newMap.get(docusign.Id).dsfs__Sender_Email__c))                                         
                   
                    */  
                     
                    if(docusign.dsfs__Envelope_Status__c == 'Completed' && (docusignSenderEmails.contains(docusign.dsfs__Sender_Email__c)) &&
                       (Trigger.oldMap.get(docusign.Id).dsfs__Envelope_Status__c !=Trigger.newMap.get(docusign.Id).dsfs__Envelope_Status__c || Trigger.oldMap.get(docusign.Id).dsfs__Sender_Email__c !=Trigger.newMap.get(docusign.Id).dsfs__Sender_Email__c))
                    {
                         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                      //   String[] toAddresses = new String[] {email};
                      //   mail.setToAddresses(toAddresses);
                         mail.setTargetObjectId(caseMap.get(docusign.dsfs__Case__c).OwnerId);
                         mail.setsaveAsActivity(false);
                         mail.setSubject('DocuSign Document was completed');
                         string link= 'The Document sent with DocuSign on case #'+' '+ '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+caseid+'">'+casenumber+'</a>'+' '+'has been completed.';
                         mail.setHtmlBody(link);
                         Messaging.SendEmail(new Messaging.SingleEmailMessage[] {mail});
                     }
                    
                 }
               }  
        
    }
    
 
}