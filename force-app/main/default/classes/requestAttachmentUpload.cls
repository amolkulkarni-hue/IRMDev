public without sharing class requestAttachmentUpload {
    public string recordId;
    public string recordName;
    private ApexPages.StandardController controller;
    public Corporate_Request__c request{get;set;}    
        
    public requestAttachmentUpload (ApexPages.StandardController stdController) {
        this.controller = stdController; 
        string recordId = ApexPages.currentPage().getParameters().get('id');
        this.request = [select id, Request_Number__c from Corporate_Request__c where id = :recordId];
        system.debug('request=='+request);
    } 
    
    
    public Attachment attachment {
        get {
            if (attachment == null)
                attachment = new Attachment();
            return attachment;
        }
        set;
    }
    
    public PageReference upload() {
        
        attachment.OwnerId = UserInfo.getUserId();
        attachment.ParentId = request.id; 
        attachment.IsPrivate = false;
        
        try {
            insert attachment;
        } catch (DMLException e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment'));
            return null;
        } finally {
            attachment = new Attachment(); 
        }
        
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
        return null;
    }
    
}