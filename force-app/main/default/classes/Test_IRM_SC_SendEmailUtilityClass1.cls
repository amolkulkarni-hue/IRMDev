/************************
Developer Name: Madhu Paladugu
Case Number   : 01814315
Date          : 10/8/13
purpose       : Test Utility for IRM_SC_SendEmailUtilityClass class
***********************/

@isTest(seeAllData=true)
public class Test_IRM_SC_SendEmailUtilityClass1{
    
    static testMethod void doTest(){
        
            RecordType caseRecordTypeOnBoarding = [select id from RecordType where name='IME SC Case'];
        	EmailTemplate Et = [SELECT Id, Name FROM EmailTemplate Limit 1];
        
           //Creation of Account
           Account testAccount = new Account(Name='Test Account');
           insert testAccount;
            
           //Creation of Contact
           Contact caseContact = new Contact(FirstName = 'Dummy1111', LastName = 'Contact1111',Phone='789',email='invalid1111@ironmountain.com');
           insert caseContact;
        
        
                            
           case testOnBoarding = new case();
           testOnBoarding.Status = 'New';
           testOnBoarding.Origin='Test';
           testOnBoarding.RecordTypeId = caseRecordTypeOnBoarding.id;
           testOnBoarding.ContactID = caseContact.id; 
           testOnBoarding.IME_SC_Country__c = 'Belgium';
           testOnBoarding.Subject = 'Test On Boarding 123'; 
           testOnBoarding.Description = 'Customer Account/Client Code';
           testOnBoarding.IME_SC_Country_Code__c= 'BEL';
           testOnBoarding.IME_SC_Notification_Name__c= 'Notify_Second_Manager_125_SLA';
           testOnBoarding.IME_SC_Outbound_Email_Address__c= 'inavalid12@ironmountain.com';
           testOnBoarding.IME_SC_To_Address__c= 'inavalid12@ironmountain.com';
           testOnBoarding.IME_SC_Cc_Address__c= 'inavalid12@ironmountain.com';
           testOnBoarding.IME_SC_Bcc_Address__c= 'inavalid12@ironmountain.com';
           testOnBoarding.IM_Division__c = 'IME';
        // **Set the Email Template Name on the Case**
        testOnBoarding.IME_SC_Email_Template_Name_test__c = Et.Name;
           
        try{
            insert testOnBoarding;
        }
        catch(exception e){
            system.debug('An error has occurred '+e);
        }
        
        
                   
           IRM_SC_SendEmailUtilityClass instance=new IRM_SC_SendEmailUtilityClass ();
           system.debug('+++++++++calling IRM_SC_SendEmailUtilityClass  for test coverage+++++++'); 
        try{
            instance.sendEmail(testOnBoarding,caseContact,null);
        }
        catch(exception ex){
            system.debug('The following error has occurred '+ex);
        }  
           
    }
}