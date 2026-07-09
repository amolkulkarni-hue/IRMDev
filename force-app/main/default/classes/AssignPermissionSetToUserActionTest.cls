/********************************************************************************************************
@Description: Test class of AssignPermissionSetToUserAction invocable class
@Copyright: Iron Mountain
@Created on:  03/18/2025(MM/DD/YYYY)
@ApexClass Name: AssignPermissionSetToUserAction
@GitLab : #29846
===================================================
********************************************************************************************************/

@isTest
public class AssignPermissionSetToUserActionTest {
    
    @testSetup
    static void setupTestData() {
        // Insert Account records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
        // Insert related Contact records
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id));
        }
        insert contacts;
    }
    @isTest
    public static void assignPermissionTest(){
        List<Contact> cons = [SELECT Id, FirstName, LastName FROM Contact];
        Profile pfr = [Select id from profile where name = 'Customer Community Plus Login Customer' LIMIT 1];
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_EMEA' LIMIT 1];
        User usr = new User();
        usr.alias = 'autTs';
        usr.email='authTestuser@im.com';
        usr.emailencodingkey='UTF-8';
        usr.firstname='authTestuser';
        usr.lastname='Invalid_1';
        usr.languagelocalekey='en_GB';
        usr.localesidkey='en_GB';
        usr.profileid = pfr.id;
        usr.timezonesidkey='Europe/London';
        usr.username='hello1.authTestuser@exp.com';
        usr.Country = 'United kingdom';
		usr.ContactId =  cons[0].id;      
        insert usr;
        AssignPermissionSetToUserAction.UserInput input = new AssignPermissionSetToUserAction.UserInput();
        input.userId = usr.Id;
        input.permissionSetId = permSet.Id;
        List<AssignPermissionSetToUserAction.UserInput> inputList = new List<AssignPermissionSetToUserAction.UserInput>{ input };
            Test.startTest();
        AssignPermissionSetToUserAction.assignPermissionSet(inputList);
        Test.stopTest();
    }
    
}