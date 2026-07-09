@isTest(seeAllData=true)
private class Test_UserObjectTrigger { 

    static testMethod void TestUserUtility() {
        
		
    	Test.startTest();
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'User') {
	        cs.Value__c='TRUE';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
        List<IMSUserEmailIds__c> usrEmailIds = [Select Admin_Email__c from IMSUserEmailIds__c];
        
        List<User> usLst = new List<User>();
        Set<String> usrIdSet = new Set<String>();
        
        /*Profile p = [Select id from profile where name = 'IME_Contracts'];
        
         User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = p.id, IsActive = true
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom');*/
        User u = TestingUtil.createUsers(1,true)[0];
        
        usLst.add(u);
        usrIdSet.add(u.Id);
        
        /*Profile p1 = [Select id from profile where name = 'IM_Custom Sys Admin'];                      
        User u1 = new User(alias = 'hrole', email='userrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Test', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = p1.id,IsActive = true
                              , timezonesidkey='America/Los_Angeles'
                              , username='userrole@testorg.com'
                              , Country = 'United Kingdom');*/
        User u1 = TestingUtil.createUsers(1,true)[0];
        usLst.add(u1);
        usrIdSet.add(u1.Id);
        //insert usLst;
        
        UserUtil objUUcls = new UserUtil();
        UserUtil.createCases(usrIdSet);
        
        u.ManagerId = u1.id;
        update u;
        
        Test.stopTest();
    }
}