global class IM_NotificationAndFieldUpdateBatch implements Database.Batchable<sObject>{
  
   public String queryStr{get;set;} 

   global Database.QueryLocator Start(Database.BatchableContext BC)
   {
       String query = null; 
       if(Test.isRunningTest()){
           query = queryStr;
       }else{
            query =  'SELECT Id , '+
                      'Owner.Email , '+
                      'Email , '+
                      'IM_Lead_Stage__c , '+
                      'IM_Stage_3_Entered_Date__c , '+
                      'Most_Recent_Sales_Activity__c , '+
                      'StageComparisonDate__c, '+
                      'batch_Email_Formula__c, '+
                      'Batch_Field_Update__c, '+
                      'Send_Email_Alert__c, '+
                      'batch_field_check__c '+
                      'FROM Lead '+ 
                      'WHERE StageComparisonDate__c != null '+
                      'AND IM_Lead_Stage__c= '+'\'3-Sales Accepted\''+  
                      'AND IsConverted = false ';
                       }

       return Database.getQueryLocator(query);
   }
   global void execute(Database.BatchableContext BC, List<Lead> scope)
   {
       List<Lead> leadsToUpdate = new List<Lead>();
        List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
      
       for(Lead l:scope){  
            if(l.batch_Email_Formula__c == System.today() && !l.Send_Email_Alert__c)
        {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                 mail.setTargetObjectId(l.Owner.Id);
                 mail.setsaveAsActivity(false);
                 mail.setSubject('Your 3-Sales Accepted lead is scheduled to be downgraded in 3 days');
                 mail.setPlainTextBody('Three days from now your 3-Sales Accepted lead will be automatically downgraded unless you take one of the following actions.' +
                                        '\n\n 1) Create a new task on the lead ' +
                                         '\n 2) Convert the lead ' + 
                                         '\n 3) Set the lead to Nurture ' +
                                         '\n 4) Disqualify the lead ' +
                                          '\n\n To view Lead record click here:' +' '+EncodingUtil.urlDecode(URL.getSalesforceBaseUrl().toExternalForm() + '/' + l.id, 'UTF-8')); 
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                l.Send_Email_Alert__c  = true;
                leadsToUpdate.add(l);  
               
           }
           if(l.Batch_Field_Update__c == System.today())
           {
               l.IM_Lead_Stage__c = '1-Inquiry';
               l.Send_Email_Alert__c = false;
               leadsToUpdate.add(l);
           }
        
       }
             if(leadsToUpdate != null && leadsToUpdate.size() > 0){
             System.debug('leadsToUpdate.size()=='+leadsToUpdate.size());
             update leadsToUpdate;
        }
       
   }
    
   global void finish(Database.BatchableContext BC)
    {
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
        TotalJobItems, CreatedBy.Email
        FROM AsyncApexJob WHERE Id =
        :BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('IM_NotificationAndFieldUpdateBatch' + a.Status);
        mail.setPlainTextBody
        ('The IM_NotificationAndFieldUpdateBatch job processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
    }

}