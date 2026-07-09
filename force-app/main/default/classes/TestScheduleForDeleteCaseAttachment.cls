// Name:testScheduleforDeleteAttachment Class
// Description: This class contains unit tests for validating the behavior of ScheduleForDeleteCaseAttacment class
// Created By: Vinod Kumar
// Created date : 17 September 2010
// ************************Version Updates********************************************
//
// Updated Date     Updated By      Update Comments 
// Modified By     : TCS
//          2022/06/08; #8989 Delete 10 case field deletion :- Part 1;  
//          Part of the #8989 story commented cid_provided__c the field reference.
//  
// 
// ************************************************************************************ 

@isTest
private class TestScheduleForDeleteCaseAttachment {
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        // Make test data
        //ID CaseID=CreateCase();
        
        /*Added On 2-7-13 as part of Case # 01135248*/
        /*Start*/
        Test.startTest();
        Set<Id> recordTypeIds = new Set<Id>();
        case TestCase=new Case();
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();
        if(rtMapByName.containsKey('NCSP: DMS'))
            recordTypeIds.add(rtMapByName.get('NCSP: DMS').getRecordTypeId());          
        if(rtMapByName.containsKey('NCSP: New Customer Setup'))
            recordTypeIds.add(rtMapByName.get('NCSP: New Customer Setup').getRecordTypeId());           
        if(rtMapByName.containsKey('NCSP: SKP Department Add Only'))
            recordTypeIds.add(rtMapByName.get('NCSP: SKP Department Add Only').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP: SKP New Customer Setup'))
            recordTypeIds.add(rtMapByName.get('NCSP: SKP New Customer Setup').getRecordTypeId()); 
  /*      try{
            //Fetching Case record based on the given Reocord Type
            TestCase =[select Id from case where Status = 'Duplicate' and RecordTypeId IN:recordTypeIds limit 1];
        }
        catch(QueryException e){
            //If environment doesn't contains any records, it will create dummy data and proceed
            TestCase=CreateCase();
        }
        /*end*/
        
/*        string sBody ='Test';
        List<Attachment> lstAttachment = new List<Attachment>();
        Attachment a1 = new Attachment();
        a1.Name = 'Test1';
        a1.Body = Blob.valueof(sBody);
        a1.OwnerId = UserInfo.getUserId();
        //a1.ParentId = caseID;
        a1.ParentId = TestCase.ID;
       
        Attachment a2 = new Attachment();
        a2.Name = 'Test2';
        a2.OwnerId = UserInfo.getUserId();
        //a2.ParentId = caseID;
        //Added On 2-7-13 as part of Case # 01135248
        a2.ParentId = TestCase.ID;
        a2.Body = Blob.valueof(sBody);
        lstAttachment.add(a1);
        lstAttachment.add(a2);
        insert lstAttachment;*/
        //List<Attachment> lstA = [Select id from Attachment where ParentId=:caseID];
        //system.assertEquals(lstA.size(),2);
        //Create
        
         Datetime currentTime = Datetime.now(); 
         currentTime = currentTime.addDays(-7);
         List<Case> lstcase=[Select ID from case where RecordTypeId in: recordTypeIds and (Status = 'Closed' or Status = 'Cancelled' or Status = 'Duplicate') LIMIT 10 ];
        system.debug(lstcase);
          if( lstcase.size() > 0){
            List <EmailMessage> lstEmailMessage =[Select e.Id From EmailMessage e where e.ParentId in:lstcase];
            List<Attachment> lstAttachment = [Select ParentId, Id From Attachment where ParentId in:lstcase or ParentId in: lstEmailMessage];
          } 
        ScheduleForDeleteCaseAttachment sfDelete = new ScheduleForDeleteCaseAttachment();
        //sfDelete.execute(null);
        String jobId = System.schedule('TestScheduleForDeleteCaseAttachment','0 15 16 9 5 ? 2026',
                                        sfDelete);
  
        //List<Attachment> lstB= [Select id from Attachment where ParentId=:caseID];
        /*Added On 2-7-13 as part of Case # 01135248*/
        List<Attachment> lstB= [Select id from Attachment where ParentId=:TestCase.ID];
        Test.stopTest();        

    }
    
    
    //public static Id CreateCase(){
    /*Added On 2-7-13 as part of Case # 01135248*/
    @testsetup
    static void testsetup() {
        ID caseRecordType =  DataFactory.getRecordTypeId('Case','NCSP: DMS');
        ID accountRecordType = DataFactory.getRecordTypeId('Account','Standard Account'); 
        
        /*List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account'];        
        if(lstRecordType.size() > 0){            
            accountRecordType = lstRecordType[0].ID;            
        }*/
        
        /*List<RecordType> lstRecordType2 =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Case'  and name = 'NCSP: DMS'  ];        
        if(lstRecordType2.size() > 0){
            caseRecordType = lstRecordType2[0].ID;
        }*/
        
        Account acc = new Account(Name = 'testAccount1',RecordTypeId =accountRecordType);
        insert acc;  
        
        Market__c testMarket = new Market__c(name= 'test test')  ;
        insert testMarket;
        
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test name'+ String.valueOf(Math.random());
        custAcc.Owning_District_Id__c = testMarket.Id;
        custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
        custAcc.IM_District_Branch_Id__c = '101';
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = acc.Id;
        insert custAcc;     
        
        Contact con = new Contact(AccountId=acc.id , LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com');
        insert con;
       
        //Create 
        Case newCase = new Case();
      
        String usrId = UserInfo.getUserId();
        newCase.OwnerId = usrId;
        newCase.RecordTypeId = caseRecordType;
        newCase.AccountId = acc.Id;
        newCase.Customer_ID__c = custAcc.Id;
        newCase.ContactId = con.Id;
        newCase.Origin = 'Email';        
             
        newCase.Subject = 'Test';
        newCase.Description = 'Test';
        newCase.Priority = 'Normal';
        newCase.Status = 'New';
        newCase.Is_Cloned__c = true;
        newCase.Recurring_Case__c = false;
        newCase.SLA_Days__c =1;
        DateTime dtInitialTargetDate = DateTime.now();
        newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        newCase.SLA_Target_Date__c = dtInitialTargetDate;
        newCase.NCSP_Case_Closed_Date__c = DateTime.now().addDays(-2);
        newCase.Date_Reviewed_Ncsp__c = DateTime.now();
        //below changes are made after the validation rule for NCSP changed
        newCase.Contract_Status__c = 'Test';
        newcase.Contract_Type__c = 'TestType';
        //#8989 Delete 10 case field deletion :- Part 1
        //newcase.CID_Provided__c = 'TestCID';
        insert newCase;
        newCase.Project_Completion_Date__c = System.today();
        newCase.Status = 'Closed';
        update newCase;
        system.debug(newCase);
        //return newCase.id;
        /*Added On 2-7-13 as part of Case # 01135248*/
        //return newCase;
    }
  
}