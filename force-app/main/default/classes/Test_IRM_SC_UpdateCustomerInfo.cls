/****************************** 
   Developer Name    : Apurva Dutta
   
   Date              : 12/02/13
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : This class is used as test class for updating the customer infomation on IME SC cases.
   
   Dependent Class   :  Apex Class  : IRM_SC_UpdateCustomerInfo
   
   Case Number       : 01941418
                                  
 ********************************/

@isTest(seealldata = true)

private class Test_IRM_SC_UpdateCustomerInfo
{
    static testMethod void InsertCaseInfo()
    {
        test.startTest();
       //creating a new account
       Account acct = new Account(name = 'Test Case Account');
       //inserting a new account
       insert acct;
       
       //creating a new account
       Account acct1 = new Account(name = 'Test Case Account1');
       //inserting a new account
       insert acct1;
       
       //creating a new customer account   
       IM_Customer_Account__c custAcct = new IM_Customer_Account__c(Name = 'Test Blah',
                                           IM_Account__c = acct.Id,
                                           Source_System__c = 'ESS',
                                           IM_District_Branch_Id__c = 'Blah');
       //inserting a new customer account
       insert custAcct;
       
       //creating a new customer account
       IM_Customer_Account__c custAcct1 = new IM_Customer_Account__c(Name = 'Test Blah1',
                                           IM_Account__c = acct1.Id,
                                           Source_System__c = 'Netsuite',
                                           IM_District_Branch_Id__c = 'Blah1');
       //inserting a new customer account
       insert custAcct1;

       //Getting the record types
       ID recTypeId =  DataFactory.getRecordTypeId('Case','IME SC Case');
       
       //Creating a new case
       Case cas = New Case(Origin = 'AUS_FAX_TAS', Status = 'New', Subject = 'Test', Description = 'Blah Blah', RecordTypeID = recTypeId,IME_SC_Customer_AccountId__c = custAcct.Id);
       //inserting a new case
       insert cas; 
       
       //Updating the old case
       Case cas1 = New Case(Id = cas.Id,IME_SC_Customer_AccountId__c = custAcct1.Id);
       update cas1;   
       
       //Updating the old case
       Case cas2 = New Case(Id = cas.Id,IME_SC_Customer_AccountId__c = null);
       update cas2;   
        
        test.stopTest();
    }

}