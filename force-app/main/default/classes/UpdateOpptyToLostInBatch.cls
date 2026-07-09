/**
 * Class: UpdateOpptyToLostInBatch
 *
 * Author: Akhila Veerabommala
 *
 * Date Created: 30.03.2022
 * 
 * Service Now ticket  #SCTASK0131605
 * 
 * Requirement :Continually update the Stage to 'Lost' for any Open Opportunities (in Stages 1 thru 4), owned by Role IMNA-US-SMB-RM-Inbound-BDA with a Close Date more than 30 days in the past.
 * 
 * This class is called from UpdateOpptyToLost and will update the records, send emails and notifications to the oppty owners which are sent through it
*/
global class UpdateOpptyToLostInBatch implements Database.Batchable<sObject>{
    public List <Opportunity> Oppty = new List<Opportunity>();
    global UpdateOpptyToLostInBatch(List<Opportunity> Oppty){
        this.Oppty = Oppty;  
        System.debug('Entered batch job');
    }
    
    global List<Opportunity> start(Database.BatchableContext BC){
        System.debug('entered start');
        return Oppty;
    }
    
    global void execute(Database.BatchableContext BC,List<Opportunity> scope){
             System.debug('Entered execute');
               
        //Updating the stagename, reason Lost and Lost comments
             for(Opportunity oppty : scope){
                 System.debug(oppty.id);
                   oppty.StageName = 'Lost';
                   oppty.IM_Reason_Lost__c='No Business Need';
                   oppty.IM_Lost_Comments__c='Inbound past due for many days';     
                       }
             System.debug(scope.size());
        
             List<Database.SaveResult> res=Database.update(scope,false);
      /*  for (Database.SaveResult sr : res) {
    if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successful' + sr.getId());
    }
    else {
        // Operation failed, so get all errors                
        for(Database.Error err : sr.getErrors()) {
            System.debug('The following error has occurred.'+err);                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Account fields that affected this error: ' + err.getFields());
        }
    }
        }*/
        for(Integer i=0; i < res.size(); i++) {
        if(res.get(i).isSuccess()) {
            System.debug('Records are updated Successfully');
        } 
        else if(!res.get(i).isSuccess()) {
            Database.Error errors =  res.get(i).getErrors().get(0);
            System.debug('Error Occurs While Processing The Record'+errors.getMessage()+res.get(i).Id);
            System.debug('Failure Record Ids While Updating'+res.get(i).Id);
        }
    }
        System.debug(res);
        //Fetching the records which are successfully updated 
             List<Opportunity> recordsAfterUpdate=[select id,name,CloseDate,Owner.id,Owner.name,Owner.email from Opportunity where id in: scope and stageName='Lost'];
        //if the recordsAfterUpdate is greater than zero send emails and notifications to the respective opportunity owner
        System.debug(recordsAfterUpdate.size());
        if(recordsAfterUpdate.size()>0)
             {
                   Messaging.Email[] messages = new Messaging.Email[0];
                   Messaging.CustomNotification[] nots = new Messaging.CustomNotification[0];
                                
                   CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Notify_Case_Owner'];
                 //Traversing through the  recordsAfterUpdate and sending mails and notifications
                 for(Opportunity oppty : recordsAfterUpdate)
                   {    
                         String OpptyName=oppty.name;
                         String Owner=oppty.Owner.name;
                         String closeDate=oppty.closeDate.format();
                         Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                         String[] mailAddresses=new String[1];
                         mailAddresses[0]=oppty.Owner.email;
                         message.toaddresses=mailAddresses;
                         message.setSenderDisplayName('IM Salesforce');
                         message.subject = 'ALERT..! Your opportunity '+OpptyName+' is moved to Lost stage';
                         message.setPlainTextBody('Hi '+Owner+','+'\n\n'+'Your opportunity, '+OpptyName+' with a closed date of '+ closeDate+' is moved to lost stage as it is due from many days. Please review.'+'\n\n'+'To view the Opportunity record click here:' +' '+URL.getSalesforceBaseUrl().toExternalForm()+'/' + oppty.id+'\n\n'+'Thank you.'); 
                         messages.add(message);
                                    
                                    
                         Messaging.CustomNotification n = new Messaging.CustomNotification();
                         n.setTitle('Your opportunity, '+opptyName+' is closed lost');
                         n.setBody('The opportunity has a close date which is due from many days ');
                         n.setNotificationTypeId(notificationType.Id);
                         n.setTargetId(oppty.id);
                                    
                         Set<String> addressee = new Set<String>();
                         addressee.add(oppty.id);
                         nots.add(n);         
                                }
                   sendEmail(messages);
                   sendNotification(nots,recordsAfterUpdate);
                            }
                        }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Successful');
    }
    public void sendEmail(Messaging.Email[] messages)
    {
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send');
        }
        
    }
    
    public void sendNotification(Messaging.CustomNotification[] nots,Opportunity[] AfterUpdate)
    {
        Integer i=0;
        try{
            for(Messaging.CustomNotification c:nots)
            {
                Set<String> addressee = new Set<String>();
                addressee.add(AfterUpdate[i].id);
                
                c.send(addressee);
                i++;
            }
        }
        
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'UpdateOpptyToLostInBatch');
        }
        
    }
}