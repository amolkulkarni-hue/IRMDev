/****************************** 
   Developer Name    : Venakteswarlu Avula
   
   Date              : 1/3/2014
   
   Company Name      : Iron Mountain India.
   
   Purpose           :  Common Trigger for all User functionality. 
         
   Test Class        : Test_commonUserTrigger
   
   Dependents        : Apex Trigger:commonUserTrigger
   
   Case Number       : 02069901
                                  
 ********************************/  
trigger commonUserTrigger on User (after insert, after update) {
    public String commonUserTriggerFlag = null; 
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='User'){
            if(cs.Trigger__c == 'commonUserTrigger') {
                commonUserTriggerFlag = cs.Value__c; 
                System.debug('----23------commonUserTriggerFlag:'+commonUserTriggerFlag);   
            }
        }
    }
    
    if(!Test.isRunningTest() && commonUserTriggerFlag == 'FALSE' || 
       (Test.isRunningTest() && commonUserTriggerFlag == 'TRUE')) {
    Set<string> userIds = new Set<string> ();
    List<IMSUserEmailIds__c> usrEmailIds;
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    List<String> strEmails = new List<String>();
    Map<Id, String> nameMap = new Map<Id, String>();
           
    List<User> usrlist= [Select u.Id, u.ManagerId, u.Manager.Name, u.LastName,u.Name from User u where u.Manager.ID <> null and u.Manager.IsActive = true limit 1000];
    RecordType rtype = new RecordType();
    rtype = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IME SC Case'];
    List<Case> casLst = new List<Case>();
    List<Case> casLstNew = new List<Case>();
    Map<id,id> mngr = new map<id,id>();
    
    for(User u:usrlist)
    {
        nameMap.put(u.ManagerId,u.Manager.Name);
        
    }
    
    if(Trigger.isInsert ){
            
            usrEmailIds = [Select Admin_Email__c from IMSUserEmailIds__c];
            
            if(!usrEmailIds.isEmpty())
            {
                for(IMSUserEmailIds__c strUEmail:usrEmailIds)
                {
                    strEmails.add(strUEmail.Admin_Email__c);
                }
           
            
                for(User objUser:Trigger.new)
                {  
                     mail.setToAddresses(strEmails);
                     mail.setSenderDisplayName('Iron Mountain');
                     mail.setSubject('New User Created in Iron Mountain');
                     mail.setPlainTextBody('Hi, \r\n' + '\r\n'+
                                            'A New user has been created in your organisation.\r\n' + '\r\n'+
                                            'First Name :-' + objUser.FirstName+ '\r\n' + 
                                            'Last Name :-' + objUser.LastName+ '\r\n' + 
                                            'Email id :-' + objUser.Email+ '\r\n' + 
                                            'Title (designation) :- ' + objUser.Title+'\n'+
                                            'Division :- ' + objUser.Division+ '\n'+
                                            'Country :- ' + objUser.Country+ '\n' + 
                                            'Reporting Manger :- ' + nameMap.get(objUser.ManagerId)+ '\r\n' + '\n'+
                                            'Please Update the new user with Federation Id, so that he can login and use the system.\r\n'+'\r\n'+
                                            'Regards,\r\n'+
                                            'IMS Admin Team');
                    emails.add(mail);
                   
                
                  }
                Messaging.sendEmail(emails);
                
                if(Trigger.isAfter)
                {
                    for (User us : [Select Id, IsActive,Hidden_Field__c from User where Id in :Trigger.newMap.keyset() and IsActive =: true]) { 
                        if(us.IsActive)
                        {
                            userIds.add(us.Id);
                        } 
                    }
                    UserUtil.createCases(userIds);
                }
           }
          
       }

/*

Developer Name    : Kavya Somashekar
   
   Date              : 18/8/2014
   
   Purpose           : For updating the "owner manager" field on cases on updating the Manager field on a user record. 
      
   Case Number       : 02666932

*/        

         if(Trigger.isUpdate && Trigger.isAfter ){
             String casLstSer = null;
             String casLstNewSer = null;
            System.debug('----118------commonUserTriggerFlag:'+commonUserTriggerFlag);  
             
             Set<Id> idSet = new Set<Id>();
             for(User objUser:Trigger.new){
                 idSet.add(objUser.id);
                 idSet.add(objuser.ManagerId);
             }
             
             List<User> Usr = [select id,Name,ManagerId from user where id in : idSet and ManagerId!=null ];// where id=: objuser.ManagerId];
             for(user u: usr)
             {
                    mngr.put(u.id,u.ManagerId);
             }
             
            for(User objUser:Trigger.new)
            {
                if(objUser.Division == 'IME')
                {
                system.debug('objUser.Division----'+objUser.Division);
                system.debug('usr---'+Usr);
                system.debug('mngr--'+mngr);
                User bfrUpdate = System.Trigger.oldMap.get(objUser.Id);
                system.debug('objUser.Manager----'+ objUser.ManagerId);
                system.debug('bfrUpdate.Manager----'+ bfrUpdate.ManagerId);
                if(objUser.ManagerId != bfrUpdate.ManagerId)
                {
                    system.debug('entering if loop');
                    system.debug('objUser.Id-----'+objUser.Id);
                    list<Case> caseLst= [select id from Case where OwnerId=:objUser.Id and Status != 'Closed' and RecordTypeId=: rtype.id];
                    list<Case> MgrLst= [select id from Case where IME_SC_Owner_Manager__c=:objUser.Id and Status != 'Closed' and RecordTypeId=: rtype.id]; 
                    system.debug('Final MgrLst=='+MgrLst) ;                   
                    for(Case c: caseLst)
                    {
                        system.debug('entering for loop');
                        case cas = new case();
                        cas.id = c.id;
                        system.debug('objUser.ManagerId-----'+objUser.ManagerId);
                        cas.IME_SC_Owner_Manager__c = objUser.ManagerId;                  
                        
                        system.debug('mngr.get(objUser.Id)------'+mngr.get(objUser.id));
                        cas.IME_SC_Manager_of_Manager_OwnerId__c = mngr.get(objUser.id);
                        casLst.add(cas);
                    }
                    for(Case c: MgrLst)
                    {
                        system.debug('entering for loop');
                        case cas = new case();
                        cas.id = c.id;
                        system.debug('mngr.get(objUser.ManagerId)------'+mngr.get(objUser.ManagerId));
                        cas.IME_SC_Manager_of_Manager_OwnerId__c = mngr.get(objUser.ManagerId);
                        casLstNew.add(cas);
                    }
                    
                    system.debug('casLst---'+casLst);
                  //  Update casLst;
                    system.debug('casLstNew---'+casLstNew);
                  //  Update casLstNew;
                 
                    if(casLst != null)
                   casLstSer = JSON.serialize(casLst) ; 
                  if(casLstNew != null)
                   casLstNewSer = JSON.serialize(casLstNew) ;  
                    
                  UserUtil.updateUserInfo(casLstSer,casLstNewSer) ; 
                  
                }
                } // Division IME if end
            }

        }
    }    
        
}