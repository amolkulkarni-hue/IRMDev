// Name:testCaseSolutionsController
// Description: This class contains unit tests for validating the behavior of CaseSolutionsController class
// Created By: Vinod Kumar
// Created date : 17 September 2010
// ************************Version Updates********************************************
//
// Updated Date     Updated By      Update Comments 
//  
// 
// ************************************************************************************ 
@isTest
private class testCaseSolutionsController {
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
             
        // Create test data
        
        ID caseRecordType;
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account' and r.name = 'Standard Account'];
        
        if(lstRecordType.size() > 0){
            
            accountRecordType = lstRecordType[0].ID;
            
        }
        List<RecordType> lstRecordType2 =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Case' ];
        
        if(lstRecordType2.size() > 0){
            caseRecordType = lstRecordType2[0].ID;
        }
        
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        
        Account acc = new Account(Name = 'testAccount1',RecordTypeId =accountRecordType,BillingCountry = 'United States');
        insert acc;        
        Contact con = new Contact(AccountId=acc.id ,MailingCountry='United States', firstname='1', LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com');
        insert con;
        
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test'+ string.valueOf(Math.random());
        custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
        custAcc.IM_District_Branch_Id__c = '101';
        custAcc.IM_Source_System_Code__c = 'Test';
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = acc.id;
        insert custAcc;   
        // Create 
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
       // newCase.Is_Cloned__c = true;
       // newCase.Recurring_Case__c = false;
        //newCase.Recurring_Frequency__c = c.Recurring_Frequency__c;
       // newCase.SLA_Days__c =1;
        //DateTime dtInitialTargetDate = DateTime.now();
       // newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        //newCase.SLA_Target_Date__c = dtInitialTargetDate;
        ApexPages.StandardController std = new ApexPages.StandardController(newCase);
        caseSolutionsController cSolution = new caseSolutionsController(std);
      
                      
    }
}