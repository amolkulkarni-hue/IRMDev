/**  
       * Name            : Test_IRM_SC_UpdateCaseInfoClass
       * Description     : Test class for IRM_SC_UpdateCaseInfoClass related to 01814315
       * Developer       : Apurva Dutta
       * Modification Log: Created:08-OCT-2013 
**/

@istest
private class Test_IRM_SC_UpdateCaseInfoClass {
    public static List<Case> getListOfCases()
    {
        ID caseRecordType =  DataFactory.getRecordTypeId('Case','IME SC Case');
        //RecordType caseRecordType = [select id from RecordType where name='IME SC Case'];    
        List<Case> caseList = new List<Case>();
        List<IM_Customer_Account__c> custAccList = new List<IM_Customer_Account__c>();
        return caseList;
    } 
    
    static testMethod void testCaseOwnerAsUser() {
    
        Test.startTest();
        User Owner1 = DataFactory.createUsersLst(1)[0];
        /*Profile sysAdmin = [Select Id,Name from Profile where Name Like '%System Admin%' LIMIT 1 ];
        UserRole CSRuser = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
        RecordType caseRecordType = [select id from RecordType where name='IME SC Case'];
        
        User Owner1 = new User(FirstName = 'Test', LastName = 'Manager', ProfileId = sysAdmin.Id, 
                              LanguageLocaleKey = 'en_US', IsActive = true, TimeZoneSidKey = 'Europe/London',
                              Username = 'TestOwner@support.com', Email = 'testOwner@support.com',
                              Alias = 'tOwn', EmailEncodingKey = 'ISO-8859-1', CommunityNickname = 'tOwner',
                              LocaleSidKey = 'en_US', Country='Australia', UserRoleId = CSRuser.Id);*/
                            
        List<Case> caseList;
        System.runAs(Owner1)
        {
            caseList = getListOfCases();
            insert caseList;
        }
        Test.stopTest();
    }  
        
}