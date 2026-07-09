public class TaskTriggerHelper{
   public static void createCaseWhenNeeded(List<Task> TaskLst){
   
  // List<QueueSobject> lstQueues = [SELECT Id,queue.Name, QueueId FROM QueueSobject WHERE SobjectType = 'Case' and queue.Name = 'IME UK Contact Data Integrity'];
     Group grp = [select Id,Name from Group where Name = 'IME UK Contact Data Integrity' and Type = 'Queue'];
    list<contact> conList = new List<contact>();
      ID recTypeIME = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Employees Support Case').getRecordTypeId();
 /*   Map<string,ID> IdCaseQueue = new Map<string,ID>();
   for(QueueSobject queueSobject : lstQueues){
   IdCaseQueue.put(queueSobject.queue.Name, queueSobject.QueueId);
   }*/
   
       List<Case> casesToCreate = new List<Case>();
       system.debug('TaskLst------'+TaskLst);
       for(Task tsk :TaskLst){
       if(tsk.Subject == 'Contact Validated')
       {
      conList = [SELECT Contact.Firstname, Contact.lastname, Email, Phone, MailingStreet, MailingCity, MailingPostalCode, MailingCountry FROM Contact where id=: tsk.whoId];
     string newLine = '\r\n';
     string NoAddress = '';
     string phone = conList[0].Phone;
     string MStreet = conList[0].MailingStreet;
     string MCity = conList[0].MailingCity;
     string MPostal = conList[0].MailingPostalCode;
     string MCountry = conList[0].MailingCountry;   
       system.debug('conList-------'+conlist);
           system.debug('case creation---');
           //system.debug('IdCaseQueue.get(IME UK Contact Data Integrity)---'+IdCaseQueue.get('IME UK Contact Data Integrity'));
               Case caseToAdd = new Case();
               //caseToAdd.OwnerId =  IdCaseQueue.get('IME UK Contact Data Integrity');
               caseToAdd.RecordTypeId = recTypeIME;
               caseToAdd.Related_To__c = 'Contacts';
               caseToAdd.Status = 'New';
               caseToAdd.Issue__c = 'Other';
               caseToAdd.Origin = 'Internal';
               caseToAdd.AccountId = tsk.whatId;
               caseToAdd.IM_Division__c = 'IME';
               caseToAdd.ContactId = tsk.whoId;
               caseToAdd.Priority = 'Medium';
              // caseToAdd.IM_Employee_Contact__c = '';
               //caseToAdd.Requested_Due_Date__c = null;
               caseToAdd.URL__c = '';
               caseToAdd.Subject = 'Validate Contact details in SKP/SecureBase';
              // if(conList[0].Phone == Null || conList[0].MailingStreet == NULL || conList[0].MailingCity == NULL || conList[0].MailingPostalCode == NULL || conList[0].MailingCountry == NULL)
             //  {
               if(conList[0].Phone == Null)
               {
               phone = NoAddress;
               }
               if(conList[0].MailingStreet == Null)
               {
               MStreet = NoAddress;
               }
               if(conList[0].MailingCity == Null)
               {
               MCity = NoAddress;
               }
               if(conList[0].MailingPostalCode == Null)
               {
               MPostal = NoAddress;
               }
               if(conList[0].MailingCountry == Null)
               {
               MCountry = NoAddress;
               }
               
              // }
              // else{
               caseToAdd.Description = 'This Contact has been validated in Salesforce. Please ensure that the following details are up-to-date in SKP/SecureBase'+newLine+''+newLine+'FirstName = '+conList[0].Firstname+''+newLine+'LastName = '+conList[0].Lastname+''+newLine+'Email = '+conList[0].Email+''+newLine+'Phone No. = '+Phone+''+newLine+'Address= '+MStreet+''+newLine+''+MCity+''+newLine+''+MPostal+''+newLine+''+MCountry+'.';
              // }
               system.debug('added to case list---');
               casesToCreate.add(caseToAdd);
               system.debug('caseToAdd.RecordTypeId------'+caseToAdd.RecordTypeId);
               }
           }
       system.debug('inserting cases-');
       system.debug('casesToCreate------'+casesToCreate);
       insert casesToCreate;
      
   }
  }