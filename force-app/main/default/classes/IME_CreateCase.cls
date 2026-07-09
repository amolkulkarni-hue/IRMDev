global with sharing class IME_CreateCase
{
    webservice static string createAccountSetupCase(ID op_id)
    { 
         String casidnew;
         Case casnw = new Case();
         RecordType rtyp = new RecordType();
         
         //Querying the Case Record Type
         rtyp = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IM Employees Support Case']; 
         
         //Querying the Queue
         Group grp = [select Id,Name from Group where Name = 'IME UK Account Setup' and Type = 'Queue']; 
         
         //Getting the List of Users from Current User
         List<User> usrLstnew = [SELECT Name, Id, Division FROM User WHERE Id = : UserInfo.getUserId()];
         
         //Querying the opportunity 
         Opportunity opp = [Select id, Name, account.name,accountid from opportunity where id=: op_id];
         
         //List<Case> casLstnew = new List<Case>();
         //Creating a Case
          for(User usrnew: usrLstnew)
          {
              casnw.OwnerId = UserInfo.getUserId();
              casnw.Related_To__c = 'Customer Account/Client Code';
              casnw.Issue__c  = 'Account Set Up';
              casnw.RecordTypeId = rtyp.id;
              casnw.Status = 'New';
              casnw.Origin = 'Internal';
              casnw.IM_Division__c = usrnew.Division;
              casnw.Priority = 'Medium';
              casnw.Subject = 'Account Setup';
              casnw.Description = 'Please Setup Account for the following Opportunity:'+opp.Name+System.label.IME_ServerURL+opp.id;
              casnw.AccountId = opp.accountid; 
              casnw.IM_Employee_Contact__c = UserInfo.getUserId();
              casnw.URL__c = System.label.IME_ServerURL+opp.id;
              
              Database.DMLOptions dmo = new Database.DMLOptions();
              dmo.assignmentRuleHeader.useDefaultRule = true;
              dmo.EmailHeader.TriggerUserEmail = true;
              casnw.setOptions(dmo);
              
          }   
          Insert casnw;
          casidnew = casnw.Id;
          return casidnew; 
    }  
    
    webservice static string createContractCase(ID op_id)
    { 
         Case cas = new Case();
         String casidnew;
         RecordType rtype = new RecordType();
         
         //Querying the Case Record Type
         rtype = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IM Employees Support Case']; 
         
         //Querying the Queue
         Group grp = [select Id,Name from Group where Name = 'IME UK Account Setup' and Type = 'Queue']; 
         
         //Getting the List of Users from Current User
         List<User> usrLst = [SELECT Name, Id,Division FROM User WHERE Id = : UserInfo.getUserId()];
         
         //Querying the opportunity 
         Opportunity opp = [Select id, Name, account.name,accountid from opportunity where id=: op_id];
         
         //List<Case> casLst = new List<Case>();
         //Creating a Case
          for(User usr: usrLst)
          {
              
              cas.OwnerId = UserInfo.getUserId();
              cas.Related_To__c = 'Contracts';
              cas.Issue__c  = 'Request Contract';
              cas.RecordTypeId = rtype.id;
              cas.Status = 'New';
              cas.Origin = 'Internal';
              cas.IM_Division__c = usr.Division;
              cas.Priority = 'Medium';
              cas.Subject = 'Contract Request';
              cas.Description = 'Please Create Contract for the following Opportunity:'+opp.Name+System.label.IME_ServerURL+opp.id;
              cas.AccountId = opp.accountid; 
              cas.IM_Employee_Contact__c = UserInfo.getUserId();
              cas.URL__c = System.label.IME_ServerURL+opp.id;
              
              Database.DMLOptions dmo = new Database.DMLOptions();
              dmo.assignmentRuleHeader.useDefaultRule = true;
              cas.setOptions(dmo);
              
          }   
          Insert cas; 
          casidnew = cas.Id;
          return casidnew;     
    }   
}