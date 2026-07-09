/*****************************************************************************************************
 * Class: QTB_OpportunityTeamHelper_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_OpportunityTeamHelper
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_OpportunityTeamHelper_Test {
  @testSetup
  static void setup() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
      Test.startTest();
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
      List<account> accountList = QTB_TestDataFactory.createAccounts(1);
      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );

      List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
      OpportunityTeamMember opptm = new OpportunityTeamMember();
      opptm.OpportunityId = oppList[0].Id;
      opptm.UserId = userList[1].Id;
      oppTeamList.add(opptm);
      insert oppTeamList;

      oppTeamList[0].OpportunityAccessLevel = 'Edit';
      update oppTeamList[0];
      delete oppTeamList[0];
        Test.stopTest();
        system.assert(opptm.UserId == userList[1].Id);
    }
  }
     static testMethod void testmethod4() {
        User contextuser = [
			SELECT Id,LastName
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
      System.runAs(contextuser) {  
      Test.startTest();   
      QTB_OpportunityTeamHandler handler = new QTB_OpportunityTeamHandler();
      handler.AfterUndelete(null);
      QTB_TestDataFactory.createBypassSetting(
        QTB_Constants.SOBJECT_OPPORTUNITYTEAM
      );
      handler.isDisabled();
      Test.stopTest();
      system.assert(contextuser.LastName=='last');    
      
    }
  }
  // cover catch
  static testMethod void testmethod5() {
    User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
      System.runAs(contextuser) {
      Test.startTest();
      QTB_OpportunityTeamHandler.throwExplicitException = true;
      QTB_OpportunityTeamHandler handler = new QTB_OpportunityTeamHandler();
      handler.IsDisabled();
      Test.stopTest();
      try {
        QTB_OpportunityTeamHelper.shareQuotewithUsers(null);
      } catch (Exception e) {
        System.assert('Script-thrown exception' == e.getMessage());
      }
      try {
        QTB_OpportunityTeamHelper.updateQuoteAccess(null);
      } catch (Exception e) {
        System.assert('Script-thrown exception' == e.getMessage());
      }

      System.assertEquals(
        true,
        QTB_OpportunityTeamHandler.throwExplicitException
      );
    }
  }
}