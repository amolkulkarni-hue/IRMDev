/*****************************************************************************************************
* Test Class    : QTB_AttachmentsEditDeleteController_Test
* Author    : IRM/Virtusa
* Purpose    : This test class for to cover all sceanrio of QTB_AttachmentsEditDeleteController apex class
* Requirement  : 
* Change History:  12/08/2022
* Developer        Date             Description
* -------------------------------------------------------------------------------------------
* Suprabha      12/08/2022    Gitlab US #11539 unable to delete or change attachments
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_AttachmentsEditDeleteController_Test {
    static testMethod void testProcess() {
        
        // Creation of cunstom metadata AttachmentAccessProfile
        AttachmentAccessProfile__mdt AP = new AttachmentAccessProfile__mdt();
        AP.isExcluded__c = true;
        AP.Label = 'IM_Sales';        
        
        //Account creation
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1);
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
             
        //Create contentVersion data        
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'Test File',
            PathOnClient   = 'Test.txt',
            FirstPublishLocationId = oppList[0].id,
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        
       List<Attachment> at=new List<Attachment>();
       Attachment  at1=new Attachment();
       at1.Name='PriceSchedule';
       at1.ParentId=oppList[0].id;
       at1.Body=Blob.valueOf('Test document');
       at.add(at1);
       insert at;
        
        QTB_AttachmentsEditDeleteController.processDeleteAttachment(at);
       
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        delete documents;
    }   
}