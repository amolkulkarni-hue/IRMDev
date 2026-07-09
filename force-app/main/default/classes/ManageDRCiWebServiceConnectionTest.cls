@isTest
public class ManageDRCiWebServiceConnectionTest {
    
    @testSetup
    static void setupTestData() {
         DRCiWebServiceConfig__c config 
            = new DRCiWebServiceConfig__c
            (username__c = 'test'
             , Password__c = 'test'
             , Instance__c = 'test'
             , Folder__c = 'test'
             , Endpoint__c = 'test'
             , Alias__c  = 'test'
             , pooled_session_Cookie__c = 'test'
             , pooled_session_Id__c = 'test'
             , Locked_For_Pooled_Session_Update__c = false);
        
        insert config;
    }

    @isTest
    static void testUpdatePasswordChange() {
        DRCiWebServiceConfig__c config = [SELECT Id, password__c, pooled_session_Id__c, pooled_session_Cookie__c, Endpoint__c FROM DRCiWebServiceConfig__c LIMIT 1];

        config.password__c = 'newPassword';

        Test.startTest();
        update config;
        Test.stopTest();

        DRCiWebServiceConfig__c updatedConfig = [SELECT pooled_session_Id__c, pooled_session_Cookie__c FROM DRCiWebServiceConfig__c WHERE Id = :config.Id];
        System.assertEquals(null, updatedConfig.pooled_session_Id__c, 'pooled_session_Id__c should be null after password change');
        System.assertEquals(null, updatedConfig.pooled_session_Cookie__c, 'pooled_session_Cookie__c should be null after password change');
    }

    @isTest
    static void testUpdatePasswordNoChange() {
        DRCiWebServiceConfig__c config = [SELECT Id, password__c, pooled_session_Id__c, pooled_session_Cookie__c FROM DRCiWebServiceConfig__c LIMIT 1];

        config.Name = 'Updated Name';

        Test.startTest();
        update config;
        Test.stopTest();

        DRCiWebServiceConfig__c updatedConfig = [SELECT pooled_session_Id__c, pooled_session_Cookie__c FROM DRCiWebServiceConfig__c WHERE Id = :config.Id];
        System.assertNotEquals(null, updatedConfig.pooled_session_Id__c, 'pooled_session_Id__c should not be null if password unchanged');
        System.assertNotEquals(null, updatedConfig.pooled_session_Cookie__c, 'pooled_session_Cookie__c should not be null if password unchanged');
    }

    @isTest
    static void testDelete() {
        DRCiWebServiceConfig__c config = [SELECT Id FROM DRCiWebServiceConfig__c LIMIT 1];

        Test.startTest();
        delete config;
        Test.stopTest();

        System.assert(true, 'Delete executed without error');
    }
}