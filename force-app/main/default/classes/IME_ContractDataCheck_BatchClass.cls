/**
    Developer Name : Apurva Dutta
    Company Name   : Iron Mountain India.
    Description    : This Class will everyday check for contract renewal date if contract type is 'Evergeen'.
                     And,if the 'Contract Renewal date' is 'Today'(if we reach that date) 
                     Then  'Renewal date' = 'Today' + 'Renewal Term (months)'
    Date           : 02/03/2014 
    Case Number    : 01590130
    Test Class     : Test_IME_ContractDataCheck
**/

global class IME_ContractDataCheck_BatchClass implements Database.Batchable<sObject>, Database.Stateful{

    global Database.QueryLocator start(Database.BatchableContext BC){
    
        String query = 'Select Id, Name, IME_Contract_Term_Type__c,IME_Contract_Renewal_Date__c,IM_Renewal_Term__c from Contract where IME_Contract_Term_Type__c =\'Evergreen\'';
        system.debug('query'+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contract> scope)
    {
        List<Contract> objcontrct= new List<Contract>();
        for(Contract objcont : scope)
         {
            if(objcont.IME_Contract_Renewal_Date__c == System.Today()&& objcont.IME_Contract_Term_Type__c == 'Evergreen' && objcont.IM_Renewal_Term__c != null)
            {
                 System.debug('-----objcont----'+objcont);
                 objcont.IME_Contract_Renewal_Date__c = System.Today().addMonths(Integer.ValueOf(objcont.IM_Renewal_Term__c));
                 objcontrct.add(objcont);
            }
         }
        
        System.debug('------objcontrct----'+objcontrct);
        
        System.debug('------objcontrct--0--'+objcontrct.size());
        update objcontrct;
        
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
        mail.setSubject('IME_ContractDataCheck_BtachClass' + a.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}