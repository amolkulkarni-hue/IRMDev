/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Controller
 * @description query record for ArchivedEmailDetail VF page
 */

public class ArchivedEmailDetailController {
    @testVisible private final String SPLIT_STRING = ' | System_Id_Only_:';
    private String caseId;
    private String emailId;
    @testVisible private Archive_Email__b archivedEmail;
    @testVisible private List<AttachmentWrapper> relatedAllAttachments;
    
    public ArchivedEmailDetailController(){
        this.caseId = Apexpages.currentPage().getParameters().get('caseId');
        this.emailId = Apexpages.currentPage().getParameters().get('emailId');
        List<Archive_Email__b> archivedEmailList = [
            SELECT Case__c,
                Email__c,
                BccAddress__c,
                CcAddress__c,
                FromAddress__c,
                FromName__c,
                Status__c,
                Subject__c,
                TextBody__c,
                ToAddress__c,
                MessageDate__c,
               ContentDocumentIDs__c
            FROM Archive_Email__b
            WHERE Case__c =: this.caseId AND Email__c =: this.emailId
           ];
        
        this.archivedEmail = archivedEmailList.isEmpty() ? null : archivedEmailList[0];
        system.debug('in constructor '+this.archivedEmail.ContentDocumentIDs__c);
    }

    public Archive_Email__b getArchivedEmail() {
        return this.archivedEmail;
    }
    
    public List<AttachmentWrapper> getAllAttachments(){
        if(this.relatedAllAttachments == null) {
            this.relatedAllAttachments = new List<AttachmentWrapper>();
            
            system.debug('archiedEmail code::::'+this.archivedEmail.Case__c);
            for(Attachment doc : [SELECT Id,Description, Name, BodyLength FROM Attachment WHERE ParentId =: this.archivedEmail.Case__c]) {
                system.debug('from attachment object '+doc.Description);
                AttachmentWrapper attWrapper = new AttachmentWrapper();
                
                if(String.isBlank(doc.Description)) {
                    continue;
                }
                if(doc.Description.substringAfter('System_Id_Only_:') == this.archivedEmail.Email__c) {
                    attWrapper.size = doc.BodyLength;
                    attWrapper.recordID = doc.Id;
                    attWrapper.name = doc.Name; 
                    attWrapper.isAttachmentObject = true;
                    this.relatedAllAttachments.add(attWrapper);
                }
            }
            if(this.archivedEmail.ContentDocumentIDs__c != null){
                List<String> lstString = this.archivedEmail.ContentDocumentIDs__c.split(',');
                for(ContentDocument conDoc : [SELECT Id, Division, Title, ParentId, FileType, FileExtension, Description,contentsize FROM ContentDocument where id in : lstString ]){
                   
                    system.debug('Title.....'+conDoc.Title);
                    AttachmentWrapper attWrapper = new AttachmentWrapper();
                    attWrapper.recordID = conDoc.Id;
                    attWrapper.name = conDoc.Title+'.'+conDoc.FileExtension;
                    attWrapper.size = conDoc.ContentSize;
                    this.relatedAllAttachments.add(attWrapper);
                }
            }
            
        }
        return relatedAllAttachments;
    } 
    
  
    public class AttachmentWrapper {
        public String name {get; set;}
        public Integer size {get; set;}
        public ID recordID {get; set;}
        public Boolean isAttachmentObject {get; set;}
    }

}