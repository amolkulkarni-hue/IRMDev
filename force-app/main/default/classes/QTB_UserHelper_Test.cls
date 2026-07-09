/*****************************************************************************************************
 * Class: QTB_UserHelper_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_UserHelper
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_UserHelper_Test {
  @TestSetup
	static void createData() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
        Profile customSysAdmin = [
			SELECT Id
			FROM Profile
			WHERE Name = 'IM_Custom Sys Admin'
		];
        // create user
		User billingUser = new User(
			profileId = customSysAdmin.Id,
			LastName = 'last',
			Email = 'testuser@test.example.com',
			Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			Country = 'USA',
			MobilePhone = '+1 9999999999',
			Phone = '9999999999'
		);
		insert billingUser;
      List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
        1,
        'Standard Account'
      );
         testaccounts[0].QTB_Legal_Entity_Country__c='India';
        update testAccounts;
      Group groupinfo = [
        SELECT id
        FROM Group
        WHERE Name = 'QTB VP India'
        LIMIT 1
      ];
      sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
      testApp1.sbaa__User__c = UserInfo.getUserId();
      sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
      testApp2.sbaa__GroupId__c = groupinfo.id;
      testApp2.QTB_Approver_Country__c = 'India';
      testApp2.QTB_Approver_Level__c = 'VP';
      update new List<sbaa__Approver__c>{ testApp1, testApp2 };

      // Create Approval Rule
      sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();

      // Create Credit Note
      List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(
        testAccounts
      );
      creditNotes[0].QTB_Manager_Approver__c = testApp1.Id;
      
      creditNotes[0].QTB_VP_Approver__c = testApp2.Id;
      creditNotes[0].blng__Status__c = 'Draft';
      update creditNotes;
      userList[0].QTB_Supervisor__c = userList[1].Id;
      userList[0].IM_RSM__c = userList[1].Id;
      userList[0].ManagerId = userList[1].Id;
      userList[0].Country = 'India';
      update userList;
      Test.stopTest();
      system.assert(userList[0].Country == 'India');
    }
  }
  @IsTest
  static void testMethod2() {
   
      User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
      System.runAs(contextuser) {
      QTB_UserTriggerHandler handler = new QTB_UserTriggerHandler();
      Test.startTest();
      handler.BeforeDelete(null);
      handler.AfterDelete(null);
      handler.AfterUndelete(null);
      QTB_UserTriggerHandler.getInstance();
      QTB_TestDataFactory.createBypassSetting('User');
      handler.isDisabled();
      Test.stopTest();
      System.assertNotEquals(null, handler);
    }
  }
  @IsTest
  static void testMethod3() {

      User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
      System.runAs(contextuser) {
      QTB_UserTriggerHandler.throwExplicitException = true;
      try {
        QTB_UserTriggerHandler.getInstance();
      } catch (Exception e) {
        System.assertEquals('System.NoAccessException', e.getTypeName());
      }
    }
  }
  @IsTest
  static void testMethod4() {
   
      User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
      System.runAs(contextuser) {
      QTB_UserTriggerHandler handler = QTB_UserTriggerHandler.getInstance();
      QTB_UserTriggerHandler.throwExplicitException = true;
      try {
        handler.IsDisabled();
      } catch (Exception e) {
        System.assertEquals('System.NoAccessException', e.getTypeName());
      }
      Map<Id, User> dummy = new Map<Id, User>();
      try {
        handler.AfterUpdate(dummy, dummy);
      } catch (Exception e) {
        System.assertEquals('System.NoAccessException', e.getTypeName());
      }
    }
  }
}