/***********************************************************************
 * This is a test Class for the main Class: DeleteGlobalServiceCase
 * 
 * When testing ConnectApi the test class has to have SeeAllData=true
 * 
 * 
*************************************************************************/
@IsTest(SeeAllData=true)
private class TestDeleteGlobalServiceCase {
    static testmethod void testSuccess(){
        
        //Getting Custom Setting
        Case_Deletion_Config__c Cs = Case_Deletion_Config__c.getInstance('Greater than 270 days');
        Cs.Ageing_Days__c = -1;
        update Cs;
		system.debug('the customsettings: '+cs.Name);
        
        //Fetching Case and Customer RecordType
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Global Service Case').getRecordTypeId();
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
        system.debug('the record type id:'+CaseTypeRId);
        
        //Creating Account, Contact & Market
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, False);
        cnt.Email='Testcnt@email.com';
        cnt.Survey_Opt_Out__c = true;
        insert cnt;
        System.debug('Inside Test-Account Id= '+acct[0].id+'ContactId= '+cnt.id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        //Creating Customer Account
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        ca.RecordTypeId = CustomerTypeRId;
        SYSTEM.debug('Value IM account' + acct[0].Id);
        ca.IM_Oracle_ID__c = '12345';
        insert ca;
        
        //Creating Case
        list<Case> csList = new List<Case>();
        for (Integer i=0;i<2;i++){
            Case m = new Case();
            String usrId = UserInfo.getUserId();
            m.OwnerId = usrId;
            m.RecordTypeId = CaseTypeRId;
            m.AccountId = ca.IM_Account__c;
            m.Customer_ID__c = ca.Id;
            m.Origin = 'NAS_EM_Orders';
            m.Cut_Off__c='Rush';
            m.Order_team__C = 'Honeywell';     
            m.Subject = 'Test ' +i;
            m.Description = 'Test' +i;
            m.Priority = 'Low';
            m.NAS_Order_Number__c = '8990' + i;
            m.Status = 'cancelled';
            m.ContactId= cnt.Id;
            m.NAS_Service_Line_Associated_to_Ask__c='Data Management';
    	
            csList.add(m);
        }

        insert csList;

        TestCasesAndRelatedUtil.insertEM(csList);
        TestCasesAndRelatedUtil.insertAttAndContent(csList);
        TestCasesAndRelatedUtil.insertRelatedRecords(csList);
        TestCasesAndRelatedUtil.insertTask(csList);
        
        test.startTest();
        String cronExpr = '0 1 9 * * ? *';
        DeleteGlobalServiceCase DC =new DeleteGlobalServiceCase(false);
        String jobId = System.schedule('ScheduleDeleteGlobalServiceCaseSuc', cronExpr, DC);
        test.stopTest();
        
    }
    
    static testmethod void testFail(){
        
        //Getting Custom Setting
        Case_Deletion_Config__c Cs = Case_Deletion_Config__c.getInstance('Greater than 270 days');
        Cs.Ageing_Days__c = -1;
        update Cs;
		system.debug('the customsettings: '+cs.Name);
        
        //Fetching Case and Customer RecordType
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Global Service Case').getRecordTypeId();
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
        system.debug('the record type id:'+CaseTypeRId);
        
        //Creating Account, Contact & Market
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, False);
        cnt.Email='Testcnt@email.com';
        cnt.Survey_Opt_Out__c = true;
        insert cnt;
        System.debug('Inside Test-Account Id= '+acct[0].id+'ContactId= '+cnt.id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        //Creating Customer Account
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        ca.RecordTypeId = CustomerTypeRId;
        SYSTEM.debug('Value IM account' + acct[0].Id);
        ca.IM_Oracle_ID__c = '12345';
        insert ca;
        
        //Creating Case
        list<Case> csList = new List<Case>();
        for (Integer i=0;i<2;i++){
            Case m = new Case();
            String usrId = UserInfo.getUserId();
            m.OwnerId = usrId;
            m.RecordTypeId = CaseTypeRId;
            m.AccountId = ca.IM_Account__c;
            m.Customer_ID__c = ca.Id;
            m.Origin = 'NAS_EM_Orders';
            m.Cut_Off__c='Rush';
            m.Order_team__C = 'Honeywell';     
            m.Subject = 'Test ' +i;
            m.Description = 'Test' +i;
            m.Priority = 'Low';
            m.NAS_Order_Number__c = '8990' + i;
            m.Status = 'cancelled';
            m.ContactId= cnt.Id;
            m.NAS_Service_Line_Associated_to_Ask__c='Data Management';
    	
            csList.add(m);
            system.debug('Case list in fail: ' + csList);
        }

        insert csList;

        TestCasesAndRelatedUtil.insertEM(csList);
        TestCasesAndRelatedUtil.insertAttAndContent(csList);
        TestCasesAndRelatedUtil.insertRelatedRecords(csList);
        TestCasesAndRelatedUtil.insertTask(csList);
        
        test.startTest();
        String cronExpr1 = '0 0 18 ? * FRI 2023-2025';
        DeleteGlobalServiceCase DC1 =new DeleteGlobalServiceCase(true);
        String jobId1 = System.schedule('ScheduleDeleteGlobalServiceCaseFail', cronExpr1, DC1);
        //DC1.execute(null);
        test.stopTest();
    }
    
    static testmethod void testException(){
        
        //Getting Custom Setting
        Case_Deletion_Config__c Cs = Case_Deletion_Config__c.getInstance('Greater than 270 days');
        Cs.Ageing_Days__c = -1;
        update Cs;
		system.debug('the customsettings: '+cs.Name);
        
        //Fetching Case and Customer RecordType
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Global Service Case').getRecordTypeId();
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
        system.debug('the record type id:'+CaseTypeRId);
        
        //Creating Account, Contact & Market
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, False);
        cnt.Email='Testcnt@email.com';
        cnt.Survey_Opt_Out__c = true;
        insert cnt;
        System.debug('Inside Test-Account Id= '+acct[0].id+'ContactId= '+cnt.id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        //Creating Customer Account
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        ca.RecordTypeId = CustomerTypeRId;
        SYSTEM.debug('Value IM account' + acct[0].Id);
        ca.IM_Oracle_ID__c = '12345';
        insert ca;
        
        //Creating Opportunity
		List<opportunity> oppList = QTB_TestDataFactory.createOpps(acct);
        
        //Creating Case
        list<Case> csList = new List<Case>();
        for (Integer i=0;i<2;i++){
            Case m = new Case();
            String usrId = UserInfo.getUserId();
            m.OwnerId = usrId;
            m.RecordTypeId = CaseTypeRId;
            m.AccountId = ca.IM_Account__c;
            m.Customer_ID__c = ca.Id;
            m.Origin = 'NAS_EM_Orders';
            m.Cut_Off__c='Rush';
            m.Order_team__C = 'Honeywell';     
            m.Subject = 'Test ' +i;
            m.Description = 'Test' +i;
            m.Priority = 'Low';
            m.NAS_Order_Number__c = '8990' + i;
            m.Status = 'cancelled';
            m.ContactId= cnt.Id;
            m.NAS_Service_Line_Associated_to_Ask__c='Data Management';
            //m.NCSP_Opportunity__c = oppList[0].id;
    		//system.debug('NCSP opp related to the case is ' + m.NCSP_Opportunity__r.id);   
            
            csList.add(m);
        }

        insert csList;
        system.debug('Case list in exception: ' + csList);

        TestCasesAndRelatedUtil.insertEM(csList);
        TestCasesAndRelatedUtil.insertRelatedRecords(csList);
        TestCasesAndRelatedUtil.insertTask(csList);
        
        integer j=0;
        list<Attachment> atslst=new list<Attachment>();
        list<ContentVersion> cvs=new list<ContentVersion>();
        list<ContentDocumentLink> cds=new list<ContentDocumentLink>();
        integer count=0;
        for(Case c: csList){
            ContentVersion cv = new ContentVersion();
                cv.Title = 'Some document'+(++j);
                cv.PathOnClient = 'some document.txt';
                cv.VersionData = Blob.valueOf('Unit Test content version...');
             cvs.add(cv);
            
        }
        insert cvs;
        for(ContentVersion cv: cvs){
        
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            system.debug('conDocId++++++++++++:'+conDocId);
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = conDocId;
            cdl.LinkedEntityId = csList.get(count).id;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'I';
            cdl.Visibility = 'AllUsers';
            cds.add(cdl);
            Attachment att = new Attachment();
            att.ParentId   = csList.get(count).id;
            Blob bodyBlob  = Blob.valueOf('Unit Test Attachment Body');
            att.body       = bodyBlob;
            att.Name       = 'attachHarry'+(++j);
            atslst.add(att);
            ++count;
        }
        
        insert cds;
        insert atslst;

        cvs[0].VersionData = Blob.valueOf('Unit Test1 content version...');
        //update cvs[0];
                    
        //Get Profile
        Profile pfr = [SELECT id FROM profile WHERE name = 'IM_Custom Sys Admin' LIMIT 1];
        
        //Creating the user
        List<User> usrLst = new List<User>();
    	for (Integer i = 0; i < 2; i++) {
          	User usr = new User();
          	usr.alias = 'standt' + i;
          	usr.email = 'u1' + i + '@email.com';
          	usr.emailencodingkey = 'UTF-8';
          	usr.firstname = 'Testing' + i;
          	usr.lastname = 'Invalid_1' + i;
          	usr.languagelocalekey = 'en_US';
          	usr.localesidkey = 'en_US';
          	usr.profileid = pfr.id;
          	usr.timezonesidkey = 'America/Los_Angeles';
          	usr.username = 'hello1.test1' + system.now().format('YYYYMMDDhhmm') + i + '@testorg.com';
          	usr.Country = 'USA';
          	usr.MobilePhone = '+1 9999999999';
          	usr.Phone = '9999999999';
          	usrLst.add(usr);
        }
        insert usrLst;
        
        VoiceCall Vc = new VoiceCall();
        //Vc.CallCenterId = '<Id of Contact Center>'; 
        Vc.VendorType = 'ContactCenter'; 
        Vc.CallType = 'Inbound';
        Vc.FromPhoneNumber = '+19999999999';
        Vc.ToPhoneNumber = '+19999999999';
        Vc.CallStartDateTime = System.now().addMinutes( - 3 );
        Vc.CallEndDateTime = System.now();
        Vc.CallDisposition = 'completed';
        Vc.NF_Case_Number__c = csList[0].id;
        insert Vc;

        insert new EngagementAttendee(
            EngagementId = Vc.id,
            InternalAttendeeId = usrLst[0].id,
            StartDateTime = System.now().addMinutes( - 3 ),
            EndDateTime = System.now()
        );
        
                        
        test.startTest();
        system.runas(usrLst[0]){
            
            String cronExpr = '0 1 9 * * ? *';
        	DeleteGlobalServiceCase DC =new DeleteGlobalServiceCase(false);
        	String jobId = System.schedule('ScheduleDeleteGlobalServiceCaseExc', cronExpr, DC);
        }
        test.stopTest();
        
    }
}