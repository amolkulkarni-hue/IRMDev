/**
 * 	Class:				SCV_SObjectControllerTest
 * 
 * 	Author:				NeuraFlash LLC
 * 
 * 	Purpose:			It's the test class for SCV_SObjectController apex class.
 * 
 * 	Requirements:		IMSLB-27
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@isTest
public with sharing class SCV_SObjectControllerTest {

    static testMethod void test() {
        Contact a1 = new Contact(FirstName='Test', LastName='Contact134');
        insert a1;
        Contact a2 = new Contact(FirstName='Test2', LastName='Contact143');
        insert a2;

        Contact[] accts = [Select Id, Name, OwnerId from Contact];
        String fieldnames = 'Name,Id,OwnerId,CreatedDate,LastActivityDate';
        String testResponse = SCV_SObjectController.getReturnResults(accts, fieldnames);
        System.assert(testResponse.contains('"noEditFieldList":['));
        System.assert(testResponse.contains('"lookupFieldList":["OwnerId"]'));
        
        Contact[] empty = [Select Id, Name, OwnerId from Contact Where Name='NotInContacts'];
        String testEmpty = SCV_SObjectController.getReturnResults(empty, fieldnames);
        System.assert(testEmpty.contains('"objectName":"EmptyCollection"'));
    }

}