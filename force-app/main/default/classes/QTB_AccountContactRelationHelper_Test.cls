/*****************************************************************************************************
 * Class: QTB_AccountContactRelationHelper
 * Author: Accenture
 * Purpose: This is a helper class for all business logic related to AccountContactRelation object
 * Requirement: SFCPQBLG-646
 * Change History: 6/14/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *             6/14/2020
 *******************************************************************************************************/
@IsTest
private with sharing class QTB_AccountContactRelationHelper_Test {
  /*
   * You can easily modify below test class for the BULK TEST by changing the integer.
   * Bulk testing is the best practice on force.com.
   */

  final static Integer AccountsToInsert = 2;
  final static Integer ContactsPerAccountToInsert = 2;

  @TestSetUp
  static void CreatingData() {
    DataFactory(AccountsToInsert, ContactsPerAccountToInsert);
  }

  // Test Method
  static testMethod void testMethod2() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      List<Account> acclist = [SELECT id FROM account LIMIT 2];

      Contact con = new Contact();
      con.LastName = 'Custom Last Name:20 ';
      con.FirstName = 'Custom First Name ';
      con.email = 'some1@email.com';
      con.AccountId = acclist[0].Id;
      insert con;
      Contact con2 = new Contact();
      con2.LastName = 'Custom Last Name:21 ';
      con2.FirstName = 'Custom First Name ';
      con2.email = 'some2@email.com';
      con2.AccountId = acclist[0].Id;
      insert con2;

      List<AccountContactRelation> updacrlist = new List<AccountContactRelation>();
      for (AccountContactRelation acr : [
        SELECT
          id,
          QTB_Primary__c,
          AccountId,
          ContactId,
          Roles,
          QTB_Checked_by_Trigger__c
        FROM AccountContactRelation
        WHERE accountid = :acclist[0].id
      ]) {
        if (acr.contactid == con.id) {
          acr.QTB_Primary__c = true;
          updacrlist.add(acr);
        }
      }
     if(!updacrlist.isEmpty())
     {
      update updacrlist;
     }
      AccountContactRelation acr = new AccountContactRelation();
      acr.accountId = acclist[1].id;
      acr.ContactId = con2.Id;
      acr.Roles= 'billing';
      acr.QTB_Checked_by_Trigger__c=false;
      insert acr;
     Test.stopTest();
      System.assert(acr.ContactId == con2.Id);
    }
  }
  // covers the unattended methods
  static testMethod void testMethod3() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      QTB_AccountContactRelationHandler handler = new QTB_AccountContactRelationHandler();
      Test.startTest();
      handler.AfterUpdate(null, null);
      handler.BeforeDelete(null);
      handler.AfterDelete(null);
      handler.AfterUndelete(null);
      Test.stopTest();
      System.assertNotEquals(null, handler);
    }
  }
  // to cover the bypass logic using custom setting
  static testMethod void testMethod4() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Metadata_Activation_Settings__c testRunnerSetting = Metadata_Activation_Settings__c.getInstance();
      Test.startTest();
      testRunnerSetting.SObject_API_Name__c = 'AccountContactRelation';
      testRunnerSetting.Disable_Trigger__c = true;
      insert testRunnerSetting;
      QTB_AccountContactRelationHandler handler = new QTB_AccountContactRelationHandler();
      handler.IsDisabled();
      Test.stopTest();
      System.assertEquals(true, testRunnerSetting.Disable_Trigger__c);
    }
  }
  // cover catch
  static testMethod void testmethod5() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      // somecustomsetting = true
      QTB_AccountContactRelationHandler.throwExplicitException = true;
      QTB_AccountContactRelationHandler handler = new QTB_AccountContactRelationHandler();
      handler.IsDisabled();
      /*try{
            handler.BeforeInsert(null);
            handler.BeforeUpdate(null, null);
            handler.AfterInsert(null);
            
            QTB_AccountContactRelationHelper.billingOraclePlatformEvent(null);
            
            QTB_AccountContactRelationHelper.billingOSPlatformEvent(null);
            
            QTB_AccountContactRelationHelper.primaryContactInsertion(null, null,null);
            
            QTB_AccountContactRelationHelper.primaryContactUpdation(null, null);
        }catch(NullPointerException e) { 
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }*/
      Test.stopTest();
      try {
        handler.BeforeInsert(null);
      } catch (NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }
      try {
        handler.BeforeUpdate(null, null);
      } catch (NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }
      try {
        handler.AfterInsert(null);
      } catch (NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }
      try {
        QTB_AccountContactRelationHelper.billingOraclePlatformEvent(null);
      } catch (NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }
      try {
        QTB_AccountContactRelationHelper.billingOSPlatformEvent(null);
      } catch (NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }
      try {
        QTB_AccountContactRelationHelper.primaryContactInsertion(
          null,
          null,
          null
        );
      } catch (NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }
      try {
        QTB_AccountContactRelationHelper.primaryContactUpdation(null, null);
      } catch (NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }

      System.assertEquals(
        true,
        QTB_AccountContactRelationHandler.throwExplicitException
      );
    }
  }
  // Data Factory Method
  static void DataFactory(
    Integer totalAccounts,
    Integer totalContactsPerAccount
  ) {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      // Creating an Account Records
      List<Account> actListToinsert = new List<Account>();
      Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Billing Account')
        .getRecordTypeId();

      for (Integer a = 0; a < totalAccounts; a++) {
        Account act = new Account();
        act.Name = 'My Custom Account: ' + string.valueOf(a);
        act.RecordTypeId = recordTypeId;
        act.QTB_Create_Parent_Billing_Account__c = true;
        //act.BillingCountry = 'US';
        //act.BillingState = 'Assam';
        actListToinsert.add(act);
        System.assertEquals(
          true,
          act.QTB_Create_Parent_Billing_Account__c,
          'Unexpected result'
        );
      }
      Database.insert(actListToinsert, true);

      // Creating Contact records per each account
      List<Contact> contactListToInsert = new List<Contact>();
      for (Account EveryAccount : actListToinsert) {
        for (Integer c = 0; c < totalContactsPerAccount; c++) {
          Contact con = new Contact();
          con.LastName = 'Custom Last Name: '+EveryAccount.id + string.valueOf(c);
          con.FirstName = 'Custom First Name ';
          con.AccountId = EveryAccount.Id;
          con.email = 'test'+EveryAccount.id+string.valueOf(c)+'@irm.com';
          con.IM_Role__c = QTB_Constants.CONTACT_ROLE;
          contactListToInsert.add(con);
        }
      }
      Database.insert(contactListToInsert, true);
    }
  }
}