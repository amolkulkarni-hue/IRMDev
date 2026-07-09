@isTest // (seeAllData=true)

private class Test_commonUserTrigger{
   static testMethod void myUnitTest() { 

       Insert (new Trigger_Activation_Settings__c(Name='commonUserTrigger',	Object__c='User', Trigger__c='commonUserTrigger', Value__c = 'FALSE'));
       
       List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
       List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
       for(Trigger_Activation_Settings__c cs : customsettings){
           if(cs.Object__c == 'User') {
               if(cs.Trigger__c == 'commonUserTrigger') {
               	cs.Value__c='TRUE';
               	updatesettings.add(cs);
               }
           }
       }
       
       update updatesettings;
       
       list<IMSUserEmailIds__c> usrEmailIds = [Select Admin_Email__c from IMSUserEmailIds__c];
       if (usrEmailIds.size()==0) Insert (new IMSUserEmailIds__c(Name = 'Admin_Email', Admin_Email__c = 'Test1234567ProdUnique@mail.com'));
       
     list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'System Administrator'];
      User u1 = new User();
            u1.FirstName = 'UniquelNamefName';
            u1.LastName = 'UniquelName';
            u1.Email = 'Test1234567ProdUnique@mail.com';
            u1.Username = 'Test1234567ProdUnique@mail.com';
            u1.Alias ='Test123';
            u1.CommunityNickname = 't123';
            u1.TimeZoneSidKey ='America/New_York';
            u1.LocaleSidKey = 'en_US';
            u1.EmailEncodingKey = 'UTF-8';
            u1.ProfileId = p1[0].id;
            u1.LanguageLocaleKey = 'en_US';
            u1.Country = 'United Kingdom';
       		u1.division = 'IME';
        insert u1;
        
        User u2 = new User();
            u2.FirstName = 'UniquelNamefName11';
            u2.LastName = 'UniquelName11';
            u2.Email = 'Test1234567ProdUnique11@mail.com';
            u2.Username = 'Test1234567ProdUnique11@mail.com';
            u2.Alias ='Test12';
            u2.CommunityNickname = 't12';
            u2.TimeZoneSidKey ='America/New_York';
            u2.LocaleSidKey = 'en_US';
            u2.EmailEncodingKey = 'UTF-8';
            u2.ProfileId = p1[0].id;
            u2.LanguageLocaleKey = 'en_US';
       		u2.division = 'IME';
            u2.Country = 'United Kingdom';
        insert u2;
        
		RecordType rtype = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IME SC Case' limit 1];
      	Insert (new case(OwnerId = u1.id, RecordTypeId=rtype.Id, Status='New', Subject='Test', Description='Test', Origin = 'ARG_PHONE'));
      	Insert (new case(RecordTypeId=rtype.Id, Status='New', Subject='Test', Description='Test', Origin = 'ARG_PHONE', IME_SC_Owner_Manager__c = u1.id)); 
       u1.ManagerId=u2.id;
       
        Update u1;
        
    }
}