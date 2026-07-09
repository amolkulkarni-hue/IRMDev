global class ContractAttachmentExtension {
@TestVisible   private static final string matchDocumentName = '%-00P%.pdf';
@TestVisible    private static final string matchVersionName = '%-068%.pdf';
    
@TestVisible    private Opportunity opp;
    public string returnUrl;
    
@TestVisible    private static Set<string> EXTENSIONS = new Set<string> {
        '.doc',
        '.dot',
        '.docx',
        '.dotx'
    };
    
@TestVisible    private static Set<string> MIME_TYPES = new Set<string> {
        'application/msword', // .doc, .dot
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // .docx
        'application/vnd.openxmlformats-officedocument.wordprocessingml.template' // .dotx
    };
    
    public contractAttachmentExtension(ApexPages.StandardController controller) {
        opp = [SELECT Id,Account.Id, (SELECT Id, Name, ContentType FROM Attachments ORDER BY LastModifiedDate DESC) FROM Opportunity WHERE Id = :controller.getId()];
    }
    
    public Id selectedDdpId { get; set; }
    public Id selectedContact { get; set; }
    
    public void changeDdp() {
        attachments = null;
    }
    
    public void changeContact() {
        signers = null;
    }
    
@TestVisible    private Map<Id, Loop__DDP__c> ddps {
        get {
            if (ddps == null) {
                ddps = new Map<Id, Loop__DDP__c>([SELECT Id, Name, (SELECT Id, Name FROM Attachments) FROM Loop__DDP__c WHERE Loop__Filter__c = 'FieldSales']);
            }
            return ddps;
        } set;
    }
    
    
    public List<SelectOption> contacts {
        get {
            if (contacts == null) {
                contacts = new List<SelectOption>();
                /*for (Contact c : [SELECT Name, Id FROM Contact WHERE Account.Id = :opp.AccountId]) {
                    contacts.add(new SelectOption(c.Id, c.Name));
                }*/
                for (OpportunityContactRole  c : [SELECT Contact.Name,ContactId FROM OpportunityContactRole Where OpportunityId =:opp.Id]) {
                    contacts.add(new SelectOption(c.ContactId, c.Contact.Name));
                }
                
                system.debug(contacts);
            }
            return contacts;
        } private set;
    }
    
    public List<SelectOption> contracts {
        get {
            if (contracts == null) {
                contracts = new List<SelectOption>();
                List<Loop__DDP__c> tmp = ddps.values();
                tmp.sort();
                for (Loop__DDP__c ddp : tmp) {
                    contracts.add(new SelectOption(ddp.Id, ddp.Name));
                }
            }
            return contracts;
        } private set;
    }
    
    public boolean showAttachments {
        get {
            return selectedDdpId != null && attachments != null && attachments.size() > 0;
        }
    }
    
@TestVisible    private boolean needsConversion(string fileName, string contentType) {
        List<string> parts = fileName.split('\\.');
        string extension = parts[parts.size() - 1];
        
        return EXTENSIONS.contains(extension.toLowerCase())
            || MIME_TYPES.contains((contentType != null ? contentType : '').toLowerCase());
    }
    
  @testvisible  public List<OrderedSelectOption> attachments {
        get {
            if (attachments == null) {
                opp = [SELECT Id, Account.Id, 
                    (SELECT Id, Name, ParentId, ContentType FROM Attachments WHERE NOT (Name LIKE :matchDocumentName OR Name LIKE :matchVersionName) ORDER BY LastModifiedDate DESC)
                    FROM Opportunity WHERE Id = :opp.Id];
                
                attachments = new List<OrderedSelectOption>();
                if (selectedDdpId != null && ddps.containsKey(selectedDdpId) && ddps.get(selectedDdpId).Attachments != null) {
                    for (Attachment a : ddps.get(selectedDdpId).Attachments) {
                    System.debug(LoggingLevel.Info,'Inside Normal Attachment ==='+a.Name);
                        if (a.Name.startsWith(ddps.get(selectedDdpId).Name)) {
                            attachments.add(new OrderedSelectOption(attachments.size(), a.Id, '', 'Contract', false,''));
                        } 
                        else { 
                            attachments.add(new OrderedSelectOption(attachments.size(), a.Id, '', a.Name, false,''));
                        }
                    }
                }
                if (opp.Attachments != null) {
                    for (Attachment a : opp.Attachments) {
                    System.debug(LoggingLevel.Info,'Inside Opp Attachment Attachment ==='+a.Name);                    
                        attachments.add(new OrderedSelectOption(attachments.size(), a.Id, '', a.Name, needsConversion(a.Name, a.ContentType),  string.valueOf(a.ParentId) ));
                    }
                }
                for (OpportunityFeed c : [SELECT Id, RelatedRecordId, ContentFileName, ContentType,ParentId FROM OpportunityFeed WHERE ParentId = :opp.Id] ) {
                    System.debug(LoggingLevel.Info,'Inside Opp Feed Attachment ==='+c.ContentFileName+'--Content Type==' + c.ContentType);                                    
                    if (c.RelatedRecordId != null) {
                        attachments.add(new OrderedSelectOption(attachments.size(), c.RelatedRecordId, string.valueOf(c.Id), c.ContentFileName, needsConversion(c.ContentFileName, c.ContentType), string.valueOf(c.ParentId)));
                    }
                }

                List<Quote> ql = [Select Id, AccountId From Quote Where OpportunityId = :opp.Id];
                if(ql != null && ql.size() > 0){
                Set<Id> quoteIds = Pluck.ids(ql);                
                    for(QuoteFeed qf : [SELECT Id, RelatedRecordId, ContentFileName, ContentType,Parent.Name,ParentId,LastModifiedDate  
                                            FROM QuoteFeed 
                                            WHERE ParentId in : quoteIds and type = 'ContentPost' ]) {
                        if (qf.RelatedRecordId != null) {
                            attachments.add(new OrderedSelectOption(attachments.size(), qf.RelatedRecordId,string.valueOf(qf.Id), qf.Parent.Name+' - '+qf.LastModifiedDate.format()  , needsConversion(qf.ContentFileName, qf.ContentType), string.valueOf(qf.ParentId)));
                        }                                           
                    }  
                    for(Attachment a : [SELECT id, Parent.Name,Name, ContentType,LastModifiedDate
                                        FROM Attachment 
                                        WHERE ParentId in : quoteIds ]) {
                       if (a.id != null) {                  
                        attachments.add(new OrderedSelectOption(attachments.size(), a.Id,'', a.Parent.Name+' - '+a.LastModifiedDate.format(), needsConversion(a.Name, a.ContentType),string.valueOf(a.ParentId)));
                       }
                    }                     
                  }              
            }
            return attachments;
        } private set;
    }
    
    public string signers {
        get { 
            if (signers == null) {
                if (selectedContact != null) {
                    List<Contact> cNameEmail = [SELECT Name, Email FROM Contact WHERE Id = :selectedContact];
                    signers = string.valueOf(cNameEmail[0].Name) + ' (' + string.valueOf(cNameEmail[0].Email) + ')';
                }
            }
            return signers;
        } private set;
    }
    
@TestVisible    private static string getKnownExtension(string filename) {
        List<string> parts = filename.split('\\.');
        
        return EXTENSIONS.contains('.' + parts[parts.size() - 1].toLowerCase())
            ? '.' + parts[parts.size() - 1]
            : '';
    }
    
    @RemoteAction
    global static Map<string, object> cleanTempAttachments(Id opportunityId) {
        if (opportunityId != null && Schema.SObjectType.Opportunity.isDeletable()) {
            List<Attachment> toDelete = [SELECT Id FROM Attachment WHERE ParentId = :opportunityId AND (Name LIKE :matchDocumentName OR Name LIKE :matchVersionName)];
            delete toDelete;
            
            return new Map<string, object> {
                'status' => 'success',
                'message' => 'Temporary attachments cleaned successfully. Total deleted: ' + toDelete.size()
            };
        } else {
            return new Map<string, object> {
                'status' => 'error',
                'message' => 'You do not have sufficient permission to clean Attachments on this record: ' + opportunityId
            };
        }
    }
    
    @RemoteAction
    global static Id convertAttachment(Id attachmentId, Id parentId) {
        Id recordId = null;
        if (attachmentId != null && parentId != null) {
            recordId = attachmentId;
            
            string title = '';
            string deleteOrig = 'false';
            
            if (attachmentId.getSObjectType() == ContentVersion.sObjectType) {
                ContentVersion version = [ SELECT Title, FileExtension FROM ContentVersion WHERE Id = :attachmentId LIMIT 1 ][0];
                
                title = version.Title;
                
                if (version.FileExtension == 'dot' || version.FileExtension == 'dotx') {
                    Attachment att = new Attachment(
                        Name = String.format('{0}.{1}', new List<string> { version.Title, version.FileExtension }),
                        ParentId = parentId,
                        Body = [ SELECT VersionData FROM ContentVersion WHERE Id = :attachmentId LIMIT 1 ][0].VersionData);
                    
                    insert att;
                    
                    recordId = att.Id;
                    deleteOrig = 'true';
                    system.debug('new attachment id'+recordId);
                }
            } else {
                title = [ SELECT Name FROM Attachment WHERE Id = :attachmentId LIMIT 1 ][0].Name;
            }
            
            string knownExtension = getKnownExtension(title);
            
            if (title.endsWIthIgnoreCase('.pdf')) {
                title = title.substring(0, title.length() - 4);
            } else if (!String.isBlank(knownExtension)) {
                title = title.substring(0, title.length() - knownExtension.length());
            }
            integer maxLength = 57; // append "-{id}.pdf"
            
            string fileName = String.format('{0}-{1}.pdf',
                new List<string> {
                    title.length() > maxLength ? title.substring(0, maxLength) : title,
                    String.valueOf(recordId) });
            
            Loop.DocumentService.convertAndMerge(
                new List<Id>{ recordId },
                parentId,
                fileName,
                new Map<string, string> {'trackActivity' => 'false', 'deleteOrig' => deleteOrig});
        }
        
        return recordId;
    }
    
    @RemoteAction
    global static Id convertpdfAttachment(Id attachmentId, Id parentId) {
        Id recordId = null;
        Id recordId1 = null;
        if (attachmentId != null && parentId != null) {
            recordId = attachmentId;
            
            string title = '';
            string deleteOrig = 'false';
            
            if (attachmentId.getSObjectType() == ContentVersion.sObjectType) {
                ContentVersion version = [ SELECT Title, FileExtension FROM ContentVersion WHERE Id = :attachmentId LIMIT 1 ][0];
                title = version.Title;
            } else {
                title = [ SELECT Name FROM Attachment WHERE Id = :attachmentId LIMIT 1 ][0].Name;
            }
            
            string knownExtension = getKnownExtension(title);
            
            if (title.endsWIthIgnoreCase('.pdf')) {
                title = title.substring(0, title.length() - 4);
            } else if (!String.isBlank(knownExtension)) {
                title = title.substring(0, title.length() - knownExtension.length());
            }
            integer maxLength = 57; // append "-{id}.pdf"
            
            string fileName = String.format('{0}-{1}.pdf',
                new List<string> {
                    title.length() > maxLength ? title.substring(0, maxLength) : title,
                    String.valueOf(recordId) });

           if (attachmentId.getSObjectType() == ContentVersion.sObjectType) {
             Attachment att = new Attachment(
                        Name = fileName,
                        ParentId = parentId,
                        Body = [ SELECT VersionData FROM ContentVersion WHERE Id = :attachmentId LIMIT 1 ][0].VersionData);
             insert att;
             recordId1 = att.Id;
             
             } else 
             {
             Attachment att = new Attachment(
                        Name = fileName,
                        ParentId = parentId,
                        Body = [ SELECT Body FROM Attachment WHERE Id = :attachmentId LIMIT 1 ][0].Body);
          insert att;
          recordId1 = att.Id;
          
        }      
   /*     Loop.DocumentService.convertAndMerge(
                new List<Id>{ recordId },
                parentId,
                fileName,
                new Map<string, string> {'trackActivity' => 'false', 'deleteOrig' => deleteOrig}); 
    */    
    }
    return recordId;
 }
    
    
    @RemoteAction
    global static string findAttachment(Id attachmentId, string parentId, Id originalId, string parentkey) {
        string searchTerm = '%-' + attachmentId + '.pdf';
        system.debug('searchTerm '+searchTerm );
        system.debug('originalId'+originalId);
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE Name LIKE :searchTerm AND ParentId = :parentId ORDER BY LastModifiedDate DESC LIMIT 1];
        if (attachments.size() > 0) {
            Attachment att = attachments[0];
            system.debug('att'+att );
            // For attachments, we delete the original and remove the id from the name, now that we no longer need it
            if(parentkey == '006'){
            if (attachmentId.getSObjectType() == Attachment.sObjectType) {
                delete [ SELECT Id FROM Attachment WHERE Id = :attachmentId LIMIT 1 ];
                
                if (attachmentId == originalId) {
                    att.Name = att.Name.substring(0, att.Name.length() - 23) + '.pdf';
                    update att;
                }
            }
         }  
            return JSON.serialize(new Map<string, string>{'oldId' => originalId, 'newId' => att.Id});
        }
        return null;
    }
    
 
    
    public string newAttachmentIdsInfo { get; set{ newAttachmentIdsInfo = value; system.debug(LoggingLevel.Info,'Value---'+value); } }
    
@TestVisible    private boolean selectionsAreValid() {
        List<string> selectedAttachmentIds = new List<string>();
        System.debug('attachements - Debug =='+attachments);        
        System.debug(LoggingLevel.Info,'attachements - Info =='+attachments);
        for (OrderedSelectOption oso : attachments) {
            if(oso.isSelected) {
                selectedAttachmentIds.add(oso.attachmentId);
            }
        }

        System.debug('selectedAttachmentIds- Debug =='+selectedAttachmentIds);        
        System.debug(LoggingLevel.Info,'selectedAttachmentIds - Info =='+selectedAttachmentIds);
                
        if(selectedAttachmentIds == null || selectedAttachmentIds.size() < 1 || selectedDdpId == null || selectedContact == null ) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please make your selections.'));
            return false;
        }
        
        return true;
    }
    
    public PageReference runDdp() {
        if (!selectionsAreValid()) {
            return null;
        }
        
        attachments.sort();
        
        Map<string, string> newAttachmentIds = new Map<string, string>();
        system.debug('newAttachmentIdsInfo Debug ==='+newAttachmentIdsInfo);
        system.debug(LoggingLevel.Info,'newAttachmentIdsInfo Info==='+newAttachmentIdsInfo);        
        if (!string.isBlank(newAttachmentIdsInfo)) {
            List<Map<string, string>> attachmentInfos = (List<Map<string, string>>)JSON.deserialize(newAttachmentIdsInfo, List<Map<string, string>>.class);
            for (Map<string, string> attachmentInfo : attachmentInfos) {
                newAttachmentIds.put(attachmentInfo.get('oldId'), attachmentInfo.get('newId'));
            }
        }
        system.debug('newAttachmentIds just debug===='+newAttachmentIds);
        system.debug(LoggingLevel.Info,'newAttachmentIds===='+newAttachmentIds);
        
        List<string> selectedAttachmentIds = new List<string>();
       system.debug(LoggingLevel.Info,'before for loop===='+attachments);                
        for (OrderedSelectOption oso : attachments) {
       system.debug(LoggingLevel.Info,'inside forloop oso.attachmentId===='+oso.attachmentId);                
       system.debug(LoggingLevel.Info,'inside forloop oso.needsConversion===='+oso.needsConversion);          
            if(oso.isSelected) {
                string attachmentId = oso.attachmentId;
                string parentId= oso.parentId;
                 system.debug('attachmentId '+attachmentId );
                 system.debug('parentId '+parentId );
                string keyPrefix = Schema.ContentVersion.sObjectType.getDescribe().getKeyPrefix();
                system.debug('keyPrefix'+keyPrefix);
                if (oso.needsConversion) {
                    system.debug(LoggingLevel.Info,'attachmentId Info with file URL='+attachmentId+'--'+oso.fileURL);
                    system.debug('attachmentId debug with file URL='+attachmentId+'--'+oso.fileURL);
                    if (newAttachmentIds.containsKey(attachmentId)) {
                 /*       if (attachmentId.startsWith(keyPrefix)) {
                            attachmentId = oso.oppFeedId + '-OpportunityFeed';
                        } else { */
                            attachmentId = newAttachmentIds.get(attachmentId);
                 //       }
                    } else {
                        ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.Error, 'One or more selected files was not properly converted. ('+oso.attachmentId+')'));
                        return null;
                    }
                } 
                else
                {
                 if (parentId != null && parentId.startsWith('006')) {
                         if (attachmentId.startsWith(keyPrefix)) {
                              attachmentId = oso.oppFeedId + '-OpportunityFeed';
                            }
                          system.debug('attachmentId4 debug with file URL='+attachmentId);
                 } else if(parentId != null && parentId.startsWith('0Q0')){
                        if (newAttachmentIds.containsKey(attachmentId)) {
                           attachmentId = newAttachmentIds.get(attachmentId);
                           }    
                        }
                 }
                
                selectedAttachmentIds.add(attachmentId);
            }
        }
        
        System.debug('selectedAttachmentIds debug=='+selectedAttachmentIds);
        System.debug('selectedAttachmentIds info=='+selectedAttachmentIds);        
        
        string url = string.format(
            '{0}?eid={1}&autorun=true&contactId={2}&parentIds={3}&ddpIds={3}&attachIds={4}&accountId={5}',
            new List<string>{
                Page.Loop__looplus.getUrl(),
                opp.Id,
                selectedContact,
                selectedDdpId,
                string.join(selectedAttachmentIds, ','),
                opp.AccountId
            }
        );
        
        system.debug('URL='+url);
        
        Contact contactName = [SELECT Name FROM Contact WHERE Id = :selectedContact];
        
        update new User(Id = UserInfo.getUserId(), Email_Contact__c = contactName.Name);
        System.debug(LoggingLevel.Info,'url==='+url);
        PageReference newPage = new PageReference(url);
        System.debug(LoggingLevel.Info,'newPage==='+newPage);
        newPage.setRedirect(false);
        System.debug(LoggingLevel.Info,'return newPage==='+newPage);
        return newPage;
      }
    
    public PageReference retUrl() {
        returnUrl = Url.getSalesforceBaseURL().toExternalForm() + '/' + opp.Id;
        return new PageReference(returnUrl);
    }
    
    public class OrderedSelectOption implements Comparable {
        public string sfdcBaseURL = Url.getSalesforceBaseURL().toExternalForm();
        public integer index { get; set; }
        public boolean isSelected { get; set; }
        public string attachmentId { get; set; }
        public string oppFeedId { get; set; }
        public string parentId { get; set; }
        public string label { get; private set; }
        public string fileURL { get; private set; }
        public boolean needsConversion { get; set; }
        
        public OrderedSelectOption(integer index, Id attachmentId, string oppFeedId, string label, boolean needsConversion,string parentId) {
            this.index = index;
            this.attachmentId = attachmentId;
            this.label = label;
            this.isSelected = false;
            this.oppFeedId = oppFeedId;
            this.parentId = parentId;
            this.fileURL = sfdcBaseURL 
                + (attachmentId.getSObjectType() == Attachment.SObjectType
                    ? '/servlet/servlet.FileDownload?file=' + attachmentId
                    : String.format('/sfc/servlet.shepherd/version/download/{0}?asPdf=false&operationContext=CHATTER',
                        new List<string> {String.valueOf(attachmentId)}));
            system.debug('attachmentId.getSObjectType()'+attachmentId.getSObjectType());
            system.debug('Attachment.SObjectType'+Attachment.SObjectType);
            system.debug('file URL='+fileURL);
            system.debug('attachmentId'+attachmentId);
            system.debug('oppFeedId'+oppFeedId);
            this.needsConversion = needsConversion;
        }
        
        public integer compareTo(object compareTo) {
            OrderedSelectOption oso = (OrderedSelectOption)compareTo;
            if (this.index == oso.index) return 0;
            if (this.index > oso.index) return 1;
            return -1;
        }
    }
}