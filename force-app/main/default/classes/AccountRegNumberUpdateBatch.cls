/*
This Batch class copies Account's - 'Registration Number' field to Contact, Opportunity, Customer Accounts 'Account Registration Number' field when 'Registration Number Updated' field on Account is true. 
Case #: 05119686 
Author: Vinutha Iyengar
Date: 06/Feb/2019
*/

Global class AccountRegNumberUpdateBatch  implements Database.Batchable<sObject>, Database.Stateful
{
    Integer recordsProcessed;
    Integer recordsUpdated;  
    String OppError ='';
    String ContError ='';
    String CustAcctError =''; 
    String AccountError ='';
    String emailBody ='';
    integer OppsUpdated = 0;
    integer ContactsUpdated = 0;
    integer CustAccountUpdated = 0;
    final Integer EMAIL_CHARACTERS_LIMIT = 30000;
    
    public AccountRegNumberUpdateBatch()
    {
        recordsProcessed = 0;
        recordsUpdated = 0;        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {        
        String query ='Select Id, Registration_Number__c from Account where Registration_Number_Updated__c = True';
        
        if(Test.isRunningTest()){           
            query = query + ' limit 2';
        } 
        
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        List<Account> accountsList = new List<Account>();
        
        //Get all Opportunities for Account        
        List<Opportunity> opptsToUpdate = new List<Opportunity>();
        List<Opportunity> OpptsList = ([select Accountid,id,Account_Registration_Number__c from Opportunity where Accountid in :scope]);
        
        //Get all Contact for Account        
        List<Contact> contsToUpdate = new List<Contact>();
        List<Contact> contsList = ([select Accountid,id,Account_Registration_Number__c from Contact where Accountid in :scope]);           
        
        //Get all CustomerAccount for Account       
        List<IM_Customer_Account__c> custAcctsToUpdate = new List<IM_Customer_Account__c>();
        List<IM_Customer_Account__c> custAcctsList = ([select IM_Account__c,id,Account_Registration_Number__c from IM_Customer_Account__c where IM_Account__c in :scope]);            
        
        system.debug('OpptsList=='+OpptsList);
        system.debug('contsList=='+contsList);
        system.debug('custAcctsList=='+custAcctsList);
        
        for(Account acct : scope)
        {            
            //update related Opportunites
            if(OpptsList.size()>0)
            {
                for(Opportunity opp : OpptsList)
                {
                    if(opp.Accountid==acct.id)
                    {
                        Opportunity newOpp = new Opportunity();
                        newOpp.id=opp.id;
                        newOpp.Account_Registration_Number__c = acct.Registration_Number__c;
                        opptsToUpdate.add(newOpp); 
                    }                        
                }                   
            }                       
            //update related Contact
            if(contsList.size()>0)
            {
                for(Contact con : contsList)
                {
                    if(con.Accountid==acct.id)
                    {
                        Contact newCont = new Contact();
                        newCont.id=con.id;
                        newCont.Account_Registration_Number__c = acct.Registration_Number__c;
                        contsToUpdate.add(newCont);                             
                    }
                }                                            
            }
            //update related Customer Account
            if(custAcctsList.size()>0)
            {       
                for(IM_Customer_Account__c custAcct : custAcctsList)
                {
                    if(custAcct.IM_Account__c ==acct.id)
                    {
                        IM_Customer_Account__c newCustAcct = new IM_Customer_Account__c();
                        newCustAcct.id=custAcct.id;
                        newCustAcct.Account_Registration_Number__c = acct.Registration_Number__c;
                        custAcctsToUpdate.add(newCustAcct);                       
                    }
                }                       
            }
            
            acct.Registration_Number_Updated__c = false;
            accountsList.add(acct);
        }
        
        system.debug('Oppts updated='+OpptsToUpdate.size());
        if(OpptsToUpdate.size()>0)
        {
            Database.SaveResult[] oppList = Database.update(OpptsToUpdate, false);            
            // Iterate through each returned result
            system.debug('oppList save result=='+oppList);
            for (Database.SaveResult opp : oppList) {
                if (!opp.isSuccess()) {           
                    for(Database.Error err : opp.getErrors()) {            
                        OppError = OppError + opp.getId() + ' - '+ err.getMessage();
                    }
                }
                else {OppsUpdated++;}
            }  
            system.debug('OppError=='+OppError);
        }
        
        
        system.debug('Conts updated='+contsToUpdate.size());
        if(contsToUpdate.size()>0)
        {
            Database.SaveResult[] contList = Database.update(contsToUpdate, false);            
            // Iterate through each returned result
            system.debug('contList save result=='+contList);
            for (Database.SaveResult cont : contList) {
                if (!cont.isSuccess()) {           
                    for(Database.Error err : cont.getErrors()) {            
                        ContError = ContError + cont.getId() + ' - '+ err.getMessage();
                    }
                }
                else {ContactsUpdated++;}
            } 
        }
        
        system.debug('Customer Accounts updated='+custAcctsToUpdate.size());
        if(custAcctsToUpdate.size()>0)
        {
            Database.SaveResult[] custAcctList = Database.update(custAcctsToUpdate, false);            
            // Iterate through each returned result
            system.debug('custAcctList save result=='+custAcctList);
            for (Database.SaveResult ca : custAcctList) {
                if (!ca.isSuccess()) {           
                    for(Database.Error err : ca.getErrors()) {            
                        CustAcctError = CustAcctError + ca.getId() + ' - '+ err.getMessage();
                    }
                }
                else {CustAccountUpdated++;}
            }  
        }
        
        recordsProcessed = recordsProcessed + scope.size();
        recordsUpdated = recordsUpdated + accountsList.size();    
        
        Database.SaveResult[] acctList = Database.update(accountsList, false);            
        // Iterate through each returned result
        for (Database.SaveResult acct : acctList) {
            if (!acct.isSuccess()) {           
                for(Database.Error err : acct.getErrors()) {            
                    AccountError= AccountError + acct.getId() + ' - '+ err.getMessage();
                    recordsUpdated--;
                }
            }
        }  
        
        
        emailBody='\n\nTotal Accounts processed: ' + recordsProcessed +
            '\nTotal Accounts updated: ' + recordsUpdated;
        	emailBody+='\n\nTotal Opportunities updated: '+OppsUpdated;
            emailBody+='\n\nTotal Contacts updated: '+ContactsUpdated;
            emailBody+='\n\nTotal Customer Accounts updated: '+CustAccountUpdated;
        
            if(AccountError!='')emailBody+='\n\nAccounts updates failed for: \n'+AccountError;
            if(OppError!='')emailBody+='\n\nOpportunities updates failed for: \n'+OppError;
            if(ContError!='')emailBody+='\n\nContacts updates failed for: \n'+ContError;
            if(CustAcctError!='')emailBody+='\n\nCustomer updates failed for: \n'+CustAcctError;
        
        emailBody= emailBody.length() >= EMAIL_CHARACTERS_LIMIT ? emailBody.substring(0,EMAIL_CHARACTERS_LIMIT) : emailBody;
    }
    
    global void finish(Database.BatchableContext BC)
    {        
        AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :BC.getJobId()];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {job.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Account Registration Number Apex Batch Job: ' + job.Status);
        mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
                              '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.' +
                             emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
}