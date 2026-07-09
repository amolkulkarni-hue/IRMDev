/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   IRM_SC_EmailToCaseController (Controller Class)
**
** PURPOSE
**   Email-to-Case Fix when locking error occurs. 
**
** NOTES
**   Expected invocation format:
**     whenever locking error gets upon case insertion from IRM_SC_ClosedCaseEmail Trigger on EmailMessage Object.
**     In 3rd Attempt from Batch class (IRM_SC_Email_to_CaseBatchJob).
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 07/18/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
************************************************************************/
public with sharing class IRM_SC_EmailToCaseController {
    EmailMessage EmailMessageOld=new EmailMessage();
    EmailMessage EmailMessageNew=new EmailMessage();
    public  string EmailId{get;set;}
    public  string CaseId{get;set;}
    public Boolean ShowSucessMessage{get;set;}
    
    //Method to create an Email with Attachment by passing EmailMessage Id from Visualforce Page.
    public PageReference doCreateEmail(){
        
        //Chacking EmailMessage Id is given by Admin or Not.
        if(EmailId== null || EmailId==''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Enter Email Id' );
            ApexPages.addMessage(myMsg);
        }
        else{
            try{
                //Retrieving EmailMessage Object details based on Submitted EmailMessage Id from VF Page.
                EmailMessageOld=[select id,BccAddress,CcAddress,FromAddress,FromName,ToAddress,TextBody,Subject,parentID,status,HasAttachment,MessageDate,Headers,HtmlBody from EmailMessage where Id=:EmailId];
            }
            catch(Exception e){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Make sure email Id system didn\'t find the matching email' );
                ApexPages.addMessage(myMsg);
                return null;
            }
	        try{
                //Creating a New EmailMessage with Old duplicate EMailMessage Information and attached to Newly created Case.
                EmailMessageNew.BccAddress=EmailMessageOld.BccAddress;
                EmailMessageNew.CcAddress=EmailMessageOld.CcAddress;
                EmailMessageNew.FromAddress=EmailMessageOld.FromAddress;
                EmailMessageNew.FromName=EmailMessageOld.FromName;
                EmailMessageNew.ToAddress=EmailMessageOld.ToAddress;
                EmailMessageNew.TextBody=EmailMessageOld.TextBody;
                EmailMessageNew.Subject=EmailMessageOld.Subject;
                EmailMessageNew.parentID = EmailMessageOld.parentID ;
                EmailMessageNew.MessageDate=EmailMessageOld.MessageDate;
                EmailMessageNew.Headers=EmailMessageOld.Headers;
                EmailMessageNew.status='0';
                system.debug('++++++++++++++email message on insert++++++++++++'+EmailMessageNew);
                
                IRM_SC_TransactionController.CalingFromControllerPage=true;
                insert EmailMessageNew;                
                
                List<Attachment> attchedlistOld=new List<Attachment>();
                List<Attachment> attchedlistNew=new List<Attachment>();
                attchedlistOld=[select id,ParentId,Name,Description,ContentType,BodyLength,Body from Attachment where parentId=:EmailId];
                system.debug('+++++++++++++email message attachment list++++++++++'+attchedlistOld);
                
                //Inserting EmailMessage Attachment.
                for(Attachment a:attchedlistOld){
                    Attachment temp=new Attachment();
                    temp.Body=a.Body;
                    temp.Name=a.Name;
                    temp.Description=a.Description;
                    temp.ParentId=EmailMessageNew.id;
                    attchedlistNew.add(temp);
                }
                insert attchedlistNew;
                               
                //By Passing Trigger Delete EmailMEssage code by passing a boolean variable from IRM_SC_TransactionController and delete the Duplicate EmailMessage from DB.
                IRM_SC_TransactionController.AllowDeleteFromBatchClass=true; 
                delete EmailMessageOld;
               
                //getting created case id 
                EmailMessage newMessage=[select id,ParentId from EmailMessage where id=:EmailMessageNew.id];
                CaseId=newMessage.ParentId ;
                ShowSucessMessage=true;
	         }
	         catch(DmlException e){
	             ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0) );
	             ApexPages.addMessage(myMsg);
	             return null;
	         }
        }
        return null; 

    }        
}