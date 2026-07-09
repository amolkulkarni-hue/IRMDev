public with sharing class OpportunityAttachmentWrapper {
        public Id recordId {get; private set;}
        public String name {get; private set;}
        public String parentName {get; private set;}
        public String parentID {get;private set;}
        public String viewURL {get; private set;}
        public Boolean isAttachment {get; private set;}
        public Boolean isFeed {get; private set;}
        public String lastModifiedDate {get; private set;}
        public Id createdById {get; private set;}
        public String createdByName {get; private set;}
        public ID relatedRecordID {get; private set;}
        
        public OpportunityAttachmentWrapper( Attachment innerAttachment )
        {
            this.name = innerAttachment.name;
            this.recordId = innerAttachment.Id;
            this.parentName = innerAttachment.Parent.Name;
            this.parentID = innerAttachment.ParentID;
            this.isAttachment = true;
            this.isFeed = false;
            this.LastModifiedDate = innerAttachment.LastModifiedDate.format();
            this.CreatedById = innerAttachment.CreatedById;
            this.createdByName = innerAttachment.CreatedBy.Name;
            this.relatedRecordID = null;
            
        }
        
        public OpportunityAttachmentWrapper( Schedule_A__Feed innerFeedItem )
        {
            this.name = innerFeedItem.title;
            this.recordId = innerFeedItem.Id;
            this.parentName = innerFeedItem.Parent.Name;
            this.parentID = innerFeedItem.ParentID;
            this.isAttachment = false;
            this.isFeed = true;
            this.LastModifiedDate = innerFeedItem.LastModifiedDate.format();
            this.CreatedById = innerFeedItem.CreatedById;
            this.createdByName = innerFeedItem.CreatedBy.Name;
            this.relatedRecordId = innerFeedItem.relatedRecordId;
        }

        public OpportunityAttachmentWrapper( QuoteFeed innerFeedItem )
        {
            this.name = innerFeedItem.title;
            this.recordId = innerFeedItem.Id;
            this.parentName = innerFeedItem.Parent.Name;
            this.parentID = innerFeedItem.ParentID;
            this.isAttachment = false;
            this.isFeed = true;
            this.LastModifiedDate = innerFeedItem.LastModifiedDate.format();
            this.createdByName = innerFeedItem.CreatedBy.Name;
            this.CreatedById = innerFeedItem.CreatedById;
            this.relatedRecordId = innerFeedItem.relatedRecordId;
        }
    
}