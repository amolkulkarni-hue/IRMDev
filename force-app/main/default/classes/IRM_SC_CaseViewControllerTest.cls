/**  
       * Name       : IRM_SC_TestCaseViewController
       * Description   : To test CaseViewController,To test Mandate Comments trigger
       * Copyright      : HCL Technologies
       * Author       : Ninad Thaware
       * Modification Log: Himanshu Jain
        
**/


@isTest
public class IRM_SC_CaseViewControllerTest
{           
     public static testMethod void caseViewControllerTest() 
     {
           //Record Type 
           //RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
           ID recTypeId =  DataFactory.getRecordTypeId('Case','IME SC Case');
           //Profile sysAdmin1 = [Select Id, Name from Profile where Name LIKE '%System Admin%' LIMIT 1];
           //UserRole cSRuser1 = [Select Name, Id From UserRole where Name LIKE '%CSR%' LIMIT 1];
           
           //User creation    
           /*User owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin1.Id, 
           LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Australia/Adelaide',
           Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
           Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
           LocaleSidKey = 'en_US', Country='Australia', UserRoleId = CSRuser1.Id);*/
           
           User owner1 = DataFactory.createUsers(1)[0];
           
           // page reference creation for 'IME_SC_CaseViews' controller class
           PageReference pageRef = Page.IME_SC_CaseViews;
           Test.setCurrentPageReference(pageRef); 
           System.runAs(owner1)
           {
                // Case Record Creation
                Case cObj=new Case(); 
                //system.debug(caseRecordType +'Record Type');
                cObj.RecordtypeId=recTypeId;
                cObj.IME_SC_Closure_Reason__c='Completed';
                cObj.IME_SC_Case_Cause__c='Transport';
                cObj.IME_SC_Category__c='Authorized User Requests';
                cObj.IME_SC_Sub_Category__c='Add New Authorized Users';
                cObj.IME_SC_Request_Type__c='Non Order';
                cObj.IME_SC_Order_Id__c='123'; 
                cObj.IME_SC_Closure_Reason__c = 'Cancelled';
                cObj.Status='Closed';
                insert cObj;
                ApexPages.StandardController sc = new ApexPages.standardController(cObj);
                // create an instance of the controller
                IRM_SC_FetchNumberOfViews pageCon = new IRM_SC_FetchNumberOfViews(sc);
                pageCon.setLastView();
                pageCon.getOwnerType();
                string noOfViews= pageCon.getNumberOfViews();           
          }
     }
}