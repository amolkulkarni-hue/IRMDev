/************************
Developer Name: Madhu Paladugu
Case Number   : 01814315
Date          : 10/8/13
purpose       : Test Utility for IRM_SC_UtilityClass  class
***********************/

@isTest(seeAllData=true)
public class Test_IRM_SC_UtilityClass {
    
    static testMethod void doTest(){
            
          Test.startTest();
          //RecordType caseRecordTypeOnBoarding = [select id from RecordType where name='IM Employees Support Case'];
          
          ID recTypeId =  DataFactory.getRecordTypeId('Case','IM Employees Support Case');
       
           //Creation of Account
           Account testAccount = new Account(Name='Test Account');
           insert testAccount;
            
           //Creation of Contact
           Contact caseContact = new Contact(FirstName = 'Test', LastName = 'User',email='invalid@ironmountain.com');
           insert caseContact;
                            
           case testOnBoarding = new case();
           testOnBoarding.Status = 'New';
           testOnBoarding.RecordTypeId = recTypeId;
           testOnBoarding.AccountID = testAccount.id;
           testOnBoarding.ContactID = caseContact.id; 
           testOnBoarding.IM_Employee_Contact__c = userInfo.getUserId();       
           testOnBoarding.IME_SC_Request_Type__c = 'Order';
           testOnBoarding.IME_SC_Country__c = 'Belgium';
           testOnBoarding.Subject = 'Test On Boarding 123'; 
           testOnBoarding.Related_To__c = 'Customer Account/Client Code';
           testOnBoarding.Issue__c = 'Account Set Up';
           testOnBoarding.IME_SC_Number_of_Line_Items__c = 1;
           testOnBoarding.ownerId=userInfo.getUserId(); 
           testOnBoarding.IM_Division__c = 'IME';
           testOnBoarding.IME_SC_Country_Code__c= 'BEL';
           testOnBoarding.IME_SC_Notification_Name__c= 'Notify_Second_Manager_125_SLA';
           
           insert testOnBoarding;
          
           IRM_SC_UtilityClass.getUserInfo();
           IRM_SC_UtilityClass.getContactInfo();
           IRM_SC_UtilityClass.getBusinessHours();
           IRM_SC_UtilityClass.getOrgWideAddress(testOnBoarding);
           IRM_SC_UtilityClass.getEmailTemplateList(testOnBoarding);
           
           Test.stopTest();
           
    }
}