/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_CustomerAccountsCases (Apex Class)
**
** PURPOSE
**   To cover 'CustomerAccountsCases' Apex Class. 
**
** NOTES
**   Created test class with dummy data to get code coverage always.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/05/07; Srinivasa Rao/Randstad; Reviewing code coverage for all components/Case#01367998; Initial release
**
************************************************************************/
@isTest(SeeAllData=true)
private class Test_CustomerAccountsCases {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        ID caseRecordType =  DataFactory.getRecordTypeId('Case','Issue');
        ID accountRecordType =  DataFactory.getRecordTypeId('Account','IMGA Record Type'); 
        
        /*List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account'];        
        if(lstRecordType.size() > 0){            
            accountRecordType = lstRecordType[0].ID;            
        }
        
        List<RecordType> lstRecordType2 =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Case' and name = 'Issue'];        
        if(lstRecordType2.size() > 0){
            caseRecordType = lstRecordType2[0].ID;
        }*/
        
        Account acc = new Account(Name = 'eotuer'+system.now(),RecordTypeId =accountRecordType, BillingCountry='Canada');
        insert acc;
        
        Contact con = new Contact(AccountId=acc.id , LastName = 'test',Phone = '123456', Email='Testsrinu.mandalapu@randstad.com');
        insert con;
        
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test cust account';
        custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
        custAcc.IM_District_Branch_Id__c = '101';
        custAcc.IM_Source_System_Code__c = 'Test';
        custAcc.IM_Account__c = acc.id;
        custAcc.Source_System__c = 'SB NA';
        custAcc.CurrencyIsoCode='USD';
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
        newCase.Is_Cloned__c = true;
        newCase.Recurring_Case__c = false;
        newCase.SLA_Days__c =1;
        DateTime dtInitialTargetDate = DateTime.now();
        newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        newCase.SLA_Target_Date__c = dtInitialTargetDate;
        insert newCase;
        
        List<Case> lstCases=new List<Case>();
        lstCases.add(newCase);
        //Passing List of Cases to to numberOfCases method to return customer cases.
        CustomerAccountsCases.numberOfCases(lstCases);       
        
    }
}