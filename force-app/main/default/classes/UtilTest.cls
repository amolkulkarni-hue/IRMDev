/**
* Class: UtilTest
*
* Author: TCS
*
* Purpose: Test class for Util
*
* Requirement: GitLab * #5164  
*
* Change History:
*
* Developer  : Praneel Patalay                   Date : 13/Feb/2022                     
* Description : This test class is for Util
* Modification:
* Modification Date: 
* Modified By: 
* -------------------------------------------------------------------------------------------
* 
*/
@isTest
public class UtilTest {
    static testMethod void doTest(){
      user u=[select id from user where id=:userInfo.getUserId()];
      BusinessHours bh1=[select id from BusinessHours where name='CAC-Retention' limit 1];
      Integer sltime=1440;
      string businessType='Clock';
      string businessType1='Business';
       
      Util.getDueDateTime(businessType,sltime,bh1.id,u.id);
      Util.getDueDateTime(businessType1,sltime,bh1.id,u.id);
  }
    /* @isTest
    static void testLogErrorSuccess() {
        Test.startTest();
        // Create a dummy user to associate with the error log.
        User testUser = new User(
            Alias = 'duser',
            Email = 'duser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'duser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(), 
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'duser@example.com',
            Country = 'United States'
        );
        insert testUser;
        // Define test data for the error log
        String componentName = 'TestComponent';
        String methodName = 'testMethod';
        String QueryParams = 'X999-SKP NA';
        String errorMessage = 'This is a test error message.';
        String stackTrace = 'This is a test error stack trace message.';
        String userId = testUser.Id; // Use the ID of the created test user

        Util.logError(componentName, methodName, QueryParams, errorMessage, stackTrace, userId);

        Test.stopTest();
        List<Community_Error_Log__c> errorLogs = [SELECT Id, Component_Name__c, Method__c, Error_Message__c, Stack_Trace__c, User__c FROM Community_Error_Log__c WHERE Component_Name__c = :componentName];

        System.assertEquals(1, errorLogs.size(), 'Expected one error log record to be created.');

    } */
     @isTest
    static void testLogErrorSuccess() {
        // Call the future method
        Test.startTest();
        Util.logError('TestComponent', 'testLogErrorSuccess', '12345', 'success', null, UserInfo.getUserId());
        Test.stopTest(); // ensures @future runs

        // Verify the record was inserted
        Community_Error_Log__c log = [SELECT Id, Component_Name__c, Method__c, Customer_ID__c, User__c, Status__c 
                                      FROM Community_Error_Log__c 
                                      WHERE Component_Name__c = 'TestComponent' 
                                      LIMIT 1];
        System.assertEquals('TestComponent', log.Component_Name__c);
        System.assertEquals('testLogErrorSuccess', log.Method__c);
        System.assertEquals('12345', log.Customer_ID__c);
        System.assertEquals(UserInfo.getUserId(), log.User__c);
        System.assertEquals('Success', log.Status__c);
    }

    @isTest
    static void testLogErrorFailure() {
        // Call the future method with error
        Test.startTest();
        Util.logError('TestComponent2', 'testLogErrorFailure', '67890', 'Some error occurred', 'StackTraceSample', UserInfo.getUserId());
        Test.stopTest();

        // Verify the record was inserted
        Community_Error_Log__c log = [SELECT Id, Component_Name__c, Method__c, Customer_ID__c, User__c, 
                                             Status__c, Error_Message__c, Stack_Trace__c
                                      FROM Community_Error_Log__c 
                                      WHERE Component_Name__c = 'TestComponent2' 
                                      LIMIT 1];
        System.assertEquals('Fail', log.Status__c);
        System.assertEquals('Some error occurred', log.Error_Message__c);
        System.assertEquals('StackTraceSample', log.Stack_Trace__c);
    }
}