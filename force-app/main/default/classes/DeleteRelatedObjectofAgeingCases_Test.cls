@isTest
public class DeleteRelatedObjectofAgeingCases_Test {
    
    public static list<Case> csList = new List<Case>();
    
    @testSetup
    static void setup(){
        Case_Deletion_Config__c cs=new Case_Deletion_Config__c();
        cs.Name = 'Greater than 3 years';
        cs.Record_types__c = 'NAS General Support Case,Customer Case Record Type,IM Employees Support Case,IM Employees Support Case Closed (locked),Sales Tools Project Case,Issue,Issue Request,Sales Tools Project Case Closed (Locked)';
        cs.Ageing_Days__c = -1095;
        cs.Status__c='Closed,Completed,Cancelled';
        cs.Send_Email_To__c='praneelkumar.patalay.prtnr@ironmountain.com,rajashekar.kampally.prtnr@ironmountain.com';
        cs.Batch_Size__c = 100;
        insert cs;
        
        system.debug('the customsettings:'+cs.Name);
        Id CaseTypeRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Employees Support Case').getRecordTypeId();
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
        
        system.debug('the record type id:'+CaseTypeRId);
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, false);
        Cnt.FirstName = 'FirstName007';
        insert cnt;
        System.debug('Inside Test-Account Id='+acct[0].id+'ContactId='+cnt.id);
        
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        ca.RecordTypeId = CustomerTypeRId;
        ca.IM_Oracle_ID__c = '12345';
        insert ca;
        
        
        for (Integer i=0;i<2;i++) {
            Case m = new Case();
            String usrId = UserInfo.getUserId();
            m.OwnerId = usrId;
            m.RecordTypeId = CaseTypeRId;
            m.AccountId = ca.IM_Account__c;
            m.Customer_ID__c = ca.Id;
            m.Origin = 'Meeting';
            m.Country__c='USA';
            m.Type = 'Billing';  
            m.IM_Case_Sub_Type__c = 'Credit Card';
            m.Subject = 'Test ' +i;
            m.Description = 'Test' +i;
            m.Priority = 'Low';
            m.Status = 'Closed';
            m.Assigned_Team__c = 'Self Managed';
            m.IME_SC_Closure_Reason__c='Invalid Case';
            m.NAS_Service_Line_Associated_to_Ask__c = 'Data Management';
            m.NAS_Service_market__c = 'Amsterdam';
            m.ContactId  = cnt.id;
            m.Service_Linenew__c = 'Digital';
            m.Reason__c = 'Completed';
            m.Comments = 'Internal comments';
            m.Related_To__c = 'Accounts';
            m.IM_Division__c = 'IMAP';
            // m.Contract_Contact_Email__c='test@gmail.com';
            //m.Contract_Contact_Name__c='testcontact';
            m.subject='Test class case';
            m.Issue__c = 'Error Message';
            m.Case_Sub_Category__c = 'Other';
            m.IM_Functional_Group__c = 'Finance';
            m.Sales_Tools_Ranking__c = '3.Low';
            
            csList.add(m);
        }
        insert csList;
       
    }
    
    static testmethod void testSuccess() {
        csList = [SELECT Id, RecordTypeId,RecordType.Name,createdDate,subject from Case];
        TestCasesAndRelatedUtil.insertEM(csList);
        TestCasesAndRelatedUtil.insertAttAndContent(csList);
        TestCasesAndRelatedUtil.insertRelatedRecords(csList);
        TestCasesAndRelatedUtil.insertTask(csList);
        test.startTest();
        DeleteRelatedObjectofAgeingCases dro =new DeleteRelatedObjectofAgeingCases();
        //database.executeBatch(dro);
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, dro);
        dro.execute(null);
        test.stopTest();
    }
    static testmethod void testFailues() {
        csList = [SELECT Id, RecordTypeId,RecordType.Name,subject,createdDate from Case];
        test.startTest();
        DeleteRelatedObjectofAgeingCases dro =new DeleteRelatedObjectofAgeingCases(true);
        //database.executeBatch(dro);
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, dro);
        dro.execute(null);
        test.stopTest();
    }
}