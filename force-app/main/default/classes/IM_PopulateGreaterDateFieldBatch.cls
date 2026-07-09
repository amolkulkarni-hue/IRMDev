global class IM_PopulateGreaterDateFieldBatch implements Database.Batchable<sObject>{
    
    String queryStr; 
    
    global Database.QueryLocator Start(Database.BatchableContext BC)
    {
        String query = null; 
        if(Test.isRunningTest()){
            query =   'SELECT Id , '+
                'IM_Stage_3_Entered_Date__c, '+
                'Most_Recent_Sales_Activity__c, '+
                'StageComparisonDate__c '+
                'FROM Lead '+ 
                'WHERE IM_Stage_3_Entered_Date__c != null '+
                'AND IsConverted = false LIMIT 10';
        }else{
            query =  'SELECT Id , '+
                'IM_Stage_3_Entered_Date__c , '+
                'Most_Recent_Sales_Activity__c , '+
                'StageComparisonDate__c '+
                'FROM Lead '+ 
                'WHERE IM_Stage_3_Entered_Date__c != null '+
                'AND IsConverted = false ';
            
        }
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Lead> scope)
    {
        List<String> erroredList = new List<String>();   
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for(Lead l:scope){  
            system.debug('scope-----');      
            system.debug('ids----');
            if(l.IM_Stage_3_Entered_Date__c  != null && l.Most_Recent_Sales_Activity__c != null) 
            { 
                system.debug('entering if-------');
                system.debug('l.IM_Stage_3_Entered_Date__c-----------'+l.IM_Stage_3_Entered_Date__c);
                system.debug('l.Most_Recent_Sales_Activity__c.date()-----------'+l.Most_Recent_Sales_Activity__c.date());
                if(l.IM_Stage_3_Entered_Date__c > l.Most_Recent_Sales_Activity__c.date() && l.StageComparisonDate__c !=  l.IM_Stage_3_Entered_Date__c)
                {
                    l.StageComparisonDate__c =  l.IM_Stage_3_Entered_Date__c;
                    system.debug('l.StageComparisonDate__c----------'+l.StageComparisonDate__c);
                }
                else if(l.IM_Stage_3_Entered_Date__c < l.Most_Recent_Sales_Activity__c.date() && l.StageComparisonDate__c !=  l.Most_Recent_Sales_Activity__c.date())
                {
                    l.StageComparisonDate__c =  l.Most_Recent_Sales_Activity__c.date();
                    system.debug('l.StageComparisonDate__c-------'+l.StageComparisonDate__c);
                }
                else if(l.IM_Stage_3_Entered_Date__c == l.Most_Recent_Sales_Activity__c.date() ) //&& (l.StageComparisonDate__c !=  l.IM_Stage_3_Entered_Date__c || l.StageComparisonDate__c !=  l.Most_Recent_Sales_Activity__c.date()))
                {
                    l.StageComparisonDate__c =  l.IM_Stage_3_Entered_Date__c;
                    system.debug('l.StageComparisonDate__c----------'+l.StageComparisonDate__c);
                }
            }
            else if(l.IM_Stage_3_Entered_Date__c  != null || l.Most_Recent_Sales_Activity__c != null)
            {
                
                if(l.IM_Stage_3_Entered_Date__c  == null && l.StageComparisonDate__c !=  l.Most_Recent_Sales_Activity__c.date())
                {
                    system.debug('entering --------');
                    l.StageComparisonDate__c = l.Most_Recent_Sales_Activity__c.date();
                    system.debug('l.StageComparisonDate__c--------'+l.StageComparisonDate__c);
                }
                else if(l.Most_Recent_Sales_Activity__c == null && l.StageComparisonDate__c !=  l.IM_Stage_3_Entered_Date__c)
                {
                    system.debug('not entering----------');
                    l.StageComparisonDate__c =  l.IM_Stage_3_Entered_Date__c; 
                    system.debug('l.StageComparisonDate__c---------'+l.StageComparisonDate__c);
                }
            }
            
            leadsToUpdate.add(l);
            
        }
        
        if(leadsToUpdate != null && leadsToUpdate.size() > 0){
            System.debug('leadsToUpdate.size()=='+leadsToUpdate.size());
            Database.SaveResult[] leadList = Database.update(leadsToUpdate,False);
            for (Integer i = 0; i < leadsToUpdate.size(); i++) {
                Database.SaveResult s = leadList[i];
                if (!s.isSuccess()) {
                    for(Database.Error err : s.getErrors()){
                        String msg = 'Record '+leadsToUpdate[i].Id+' '+err.getMessage()+' '+err.getStatusCode();
                        erroredList.add(msg);
                    }
                    
                } 
            }
        }  
        if(erroredList != null && erroredList.size() > 0){
            ExceptionLogger.createLogForFailedBatchRecords(erroredList,'IM_PopulateGreaterDateFieldBatch',81);
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
        mail.setSubject('IM_PopulateGreaterDateFieldBatch' + a.Status);
        mail.setPlainTextBody
            ('The IM_PopulateGreaterDateFieldBatch job processed ' + a.TotalJobItems +
             ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
    }
    
}