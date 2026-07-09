/**
 * 	Class:				SCVGetCustomerIDsTest
 * 
 * 	Author:				Yashwant Verma (Neuraflash LLC)
 * 
 * 	Purpose:			This class is used for testing SCVGetCustomerIDsTest class.
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------*/
@IsTest
private class SCVGetCustomerIDsTest {
    @testSetup
    static void setup(){
        // This method is used for setting up the test data.
        
        // Create an account record
        Account account = new Account(Name = 'Test Account');
        insert account;

        //create a contact record
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = account.Id, Phone = '1234567890');
        insert contact;

        // Create a list of IM_Customer_Account__c records
        IM_Customer_Account__c customerAccounts = new IM_Customer_Account__c(IM_Account__c = account.Id, Name = '123456');
        insert customerAccounts;
    }

    @IsTest
    static void testGetCustomerIDs(){
        // This method is used for testing the GET method in SCVGoRestResource class.
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/getCustomerIDs';
        request.httpMethod = 'GET';
        request.addParameter('phoneNumber', '1234567890');
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        List<Id> fixedSearchResults= new List<Id>();
		for (Contact eachContact : [SELECT ID FROM Contact]){
            fixedSearchResults.add(eachContact.Id);
        }
       	Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
        SCVGetCustomerIDs.getCustomerIDs();
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
    }
}