/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Email_to_CaseBatchJob (Batch Class)
**
** PURPOSE
**   Email-to-Case Fix when locking error occurs. 
**
** NOTES
**   Expected invocation format:
**     whenever locking error gets upon case insertion from IRM_SC_ClosedCaseEmail Trigger on EmailMessage Object.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 06/03/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
************************************************************************/
global class IRM_SC_Email_to_CaseBatchJob implements Database.Batchable<sObject>{
    
    String Query='select id,BccAddress,CcAddress,FromAddress,FromName,ToAddress,TextBody,Subject,parentID,status,HasAttachment,MessageDate,Headers,HtmlBody from EmailMessage where id IN ('; 
    Public set<id> emailID=new set<id>();
    global IRM_SC_Email_to_CaseBatchJob(Set<Id> emailIds){
        for(id eids:emailIds){
            Query=Query+'\''+eids+'\''+',';
        }
        Query= Query.substring (0,Query.length()-1)+')';        
    }
    
    // Start Method.
    Global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('--33--inside Start method----Query:'+Query);
        return Database.getQueryLocator(Query);
    }
    
    // Execute Logic.
    Global void execute(Database.BatchableContext BC, List<sObject> scope){
       
        System.debug('--39--inside execute method----');
      
        List<EmailMessage> emList=new List<EmailMessage>();
         List<EmailMessage> emListToDelete=new List<EmailMessage>();
        for(sObject s:scope){
            EmailMessage temp=(EmailMessage)s;
            EmailMessage temp1= new EmailMessage();
             temp1.BccAddress=temp.BccAddress;
             temp1.CcAddress=temp.CcAddress;
             temp1.FromAddress=temp.FromAddress;
             temp1.FromName=temp.FromName;
             temp1.ToAddress=temp.ToAddress;
             temp1.TextBody=temp.TextBody;
             temp1.Subject=temp.Subject;
             temp1.parentID = temp.parentID ;
             temp1.MessageDate=temp.MessageDate;
             temp1.Headers=temp.Headers;
             temp1.status='0';
             
             emList.add(temp1);
             
             emailID.add(temp.Id);
             emListToDelete.add(temp);
        }
        system.debug('---52---email list-------:'+emList);
        
       
        try{
            System.debug('------in try block in batch class----');
            
            //2nd retry attempt
            IRM_SC_TransactionController.CalingFromControllerPage=true;
            insert emList;
            Map<id,id> matchingEmails=new Map<id,id>();
            for(EmailMessage e:emList ){
            	for(EmailMessage e1:emListToDelete){
            		if(e.FromName==e1.FromName && e.MessageDate==e1.MessageDate && e1.Subject==e.Subject){
            			matchingEmails.put(e1.id,e.id);
            			break;
            		}
            		
            	}
            }
            List<Attachment> attchedlistOld=new List<Attachment>();
            List<Attachment> attchedlistNew=new List<Attachment>();
            attchedlistOld=[select id,ParentId,Name,Description,ContentType,BodyLength,Body from Attachment where parentId=:emailID];
            
            for(Attachment a:attchedlistOld){
            	Attachment temp=new Attachment();
            	temp.Body=a.Body;
            	temp.Name=a.Name;
            	temp.Description=a.Description;
            	temp.ParentId=matchingEmails.get(a.parentid);
            	attchedlistNew.add(temp);
            }
            insert attchedlistNew;
            //By Passing Trigger Delete EmailMEssage code by passing a boolean variable from IRM_SC_TransactionController and delete the Duplicate EmailMessage from DB.
            IRM_SC_TransactionController.AllowDeleteFromBatchClass=true; 
            delete emListToDelete;
            //Querying inserted case with Id and showing in chatter post.
            List<EmailMessage> newEmailMessage=[select id,parentId from EmailMessage where id IN:emList];
            //Chatter Group.
            CollaborationGroup CG = [Select c.Name, c.Id From CollaborationGroup c where c.Name='IME-Email2CaseSupport'];                    
            List<FeedItem> feedItemList=new List<FeedItem>();
            //Chatter post.            
            for(EmailMessage e:newEmailMessage){
	            FeedItem post = new FeedItem(); 
	            post.ParentId = CG.Id;
	            post.Body = 'IMESC_Email2Case: 2nd retry attempt-Case was created successfully. Here is the link to the new case.';
	            post.LinkUrl=URL.getSalesforceBaseUrl().toExternalForm() + '/' + e.parentId;
	            post.Title='Link to Email-to-Case';             
	            feedItemList.add(post);
            }
            insert feedItemList;
            
        }
        catch(Exception ex){         
           
            //Chatter Group to send an alert message incase of Emailtocase failed in general insert.
            CollaborationGroup CG = [Select c.Name, c.Id From CollaborationGroup c where c.Name='IME-Email2CaseSupport'];           
             
             List<FeedItem> feedItemList=new List<FeedItem>();
            //Chatter post.
            for(EmailMessage e:emListToDelete){
	            FeedItem post = new FeedItem(); 
	            post.ParentId = CG.Id;
	            post.Body = 'IMESC_Email2Case: 2nd retry attempt-Case was not created successfully. Please go to this below link and insert this Email Message id '+e.id+' into the page, to create a case manually.';
	            post.LinkUrl='/apex/IRM_SC_EmailToCaseController';	
	            post.Title='Link to Email-to-Case';            
	            feedItemList.add(post);
            }
            insert feedItemList;
        
        }
        
        
    }
    
    //finish method.
    Global void finish(Database.BatchableContext BC){       
                
        //Querying job Id
        AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :BC.getJobId()];
               
        //deleting last run batch
        try{
            System.abortJob(job.Id);
        }
        catch(exception e){
            system.debug('-------do nothing--------');
        }
    }
    
    
}