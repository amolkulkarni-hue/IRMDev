@isTest
private class LightningUtilitiesTestClass {
static testMethod void getContact(){
    Account a = new Account(Name='UnitTestAccount');
    insert a;
    Contact con = new Contact(firstName='Unit',LastName='Test',AccountId=a.id,Email='TestDemo@test.com',special_handling__c='Entertainment services');
    insert con;
    LightningUtilities.getContact(con.Id);
    //contact c = [select Name,Email,AccountId,special_handling__c from contact where id =:con.Id];
}
}