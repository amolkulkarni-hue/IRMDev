/**
 * 	Class:				NF_PhoneSearchAction
 * 
 * 	Author:				Yashwant Verma (NeuraFlash LLC)
 * 
 * 	Purpose:			Its the test class for NF_PhoneSearchApexAction
 * 
 * 	Requirements:		IMSLB-27
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@isTest
public class NF_PhoneSearchActionTest {
    @TestSetup
    static void makeData(){
        List<Contact> conList = new List<Contact>();
        Integer i;
        for(i=0; i<=10; i++){
            Contact newCon = new Contact();
            newCon.LastName = 'test'+i;
            newCon.Phone = '+17607058888';
            conList.add(newCon);
        }
        insert conList;
        system.debug('>>'+conList[0].Id);
        
    }
    @isTest
    public static void NF_PhoneSearchActionTest() {
        List<NF_PhoneSearchAction.Requests> requestList = new List<NF_PhoneSearchAction.Requests>();
		List<Id> fixedSearchResults= new List<Id>();
        NF_PhoneSearchAction.Requests inputRequest = new NF_PhoneSearchAction.Requests();

        inputRequest.objectAPIName = 'Contact';
        inputRequest.phoneNumber = '+17607058888';
        inputRequest.commaSeparatedFieldAPINames = 'Name, Phone';
        requestList.add(inputRequest);
        
        for (Contact eachContact : [SELECT ID FROM Contact]){
            fixedSearchResults.add(eachContact.Id);
        }

       	Test.setFixedSearchResults(fixedSearchResults);
        test.startTest();
        List<List<Contact>> outputResponse = NF_PhoneSearchAction.NF_PhoneSearchAction(requestList);
        test.stopTest();

        system.assertNotEquals(null, outputResponse);

    }
}