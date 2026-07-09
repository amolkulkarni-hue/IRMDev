/* Description: Test class for PRM_LightningSelfRegisterController, also cloned version of LightningSelfRegisterControllertest
                thats provided by Salesforce when community is enabled
 * Author: Sorna (perficient)
 * Date: 05/15/2018
 */

@IsTest
public with sharing class PRM_LightningSelfRegisterControllerTest {

 /* Verifies that IsValidPassword method with various password combinations. */
 @IsTest
 static void testIsValidPassword() {
  System.assert(PRM_LightningSelfRegisterController.isValidPassword('password?@12334', 'password?@12334') == true);
  System.assert(PRM_LightningSelfRegisterController.isValidPassword('password?@12334', 'dummyPassword') == false);
  System.assert(PRM_LightningSelfRegisterController.isValidPassword('password?@12334', null) == false);
  System.assert(PRM_LightningSelfRegisterController.isValidPassword(null, 'fakePwd') == false);
 }

 @IsTest
 static void testSiteAsContainerEnabled() {
  System.assertNotEquals(null, PRM_LightningSelfRegisterController.siteAsContainerEnabled('https://portaleu1-developer-edition.eu11.force.com'));
 }

 /* Verifies the selfRegistration method flow with various invalid inputs */
 @IsTest
 static void testSelfRegistration() {
  Map < String, String > paramsMap = initializeParams();
  System.assertNotEquals(null, paramsMap);
  System.assertEquals('Last Name is required', PRM_LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), '', paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true));
  System.assertEquals('Email is required', PRM_LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), '', paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true));
  System.assertEquals('First Name and Email are required', PRM_LightningSelfRegisterController.selfRegister(null, paramsMap.get('lastName'), '', null, paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true));
  System.assertEquals(Label.site.passwords_dont_match, PRM_LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true));
  System.assertNotEquals(null, PRM_LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), '', paramsMap.get('password'), paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false));
 }


 /* Verifies the selfRegistration flow for valid inputs */
 @IsTest
 static void testSelfRegisterWithProperCredentials() {
  Map < String, String > paramsMap = initializeParams();
  System.assertEquals(null, PRM_LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true));
 }

 /* Verifies SelfRegistration flow with an accounId that is created within the test */
 @IsTest
 static void testSelfRegisterWithCreatedAccount() {
  Account acc = new Account(name = 'test acc');
  insert acc;
  List < Account > accounts = [SELECT Id FROM Account LIMIT 1];
  System.assert(!accounts.isEmpty(), 'There must be at least one account in this environment!');
  String accountId = accounts[0].Id;
  Map < String, String > paramsMap = initializeParams();
  String result = PRM_LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), accountId, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false);
  System.assertEquals(null, result);
 }

 @IsTest
 static void testGetNullExtraFields() {
  System.assertNotEquals(null, PRM_LightningSelfRegisterController.getExtraFields(null));
 }

 @IsTest
 static void testGetNonEmptyExtraFields() {
  System.assertNotEquals(null, PRM_LightningSelfRegisterController.getExtraFields('field1'));
 }

 /* Verifies validation of extraFields within the Self Registration flow */
 @IsTest
 static void testGetExtraFieldsInSelfRegistration() {
  List < Map < String, Object >> fieldlist = new List < Map < String, Object >> ();
  Map < String, String > paramsMap = initializeParams();
  Map < String, Object > fieldMap = new Map < String, Object > ();
  fieldMap.put('value', 'Test Company Name');
  fieldMap.put('fieldPath', 'CompanyName');
  fieldMap.put('required', true);
  fieldlist.add(fieldMap);
  String extraFields = JSON.serialize(fieldlist);
  System.assertEquals(null, PRM_LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), extraFields, paramsMap.get('startUrl'), true));
 }

 @IsTest
 static void PRM_LightningSelfRegisterControllerInstantiation() {
  PRM_LightningSelfRegisterController controller = new PRM_LightningSelfRegisterController();
  System.assertNotEquals(controller, null);
 }

 @IsTest
 static void testOtherMethods() {
  PRM_LightningSelfRegisterController.setExperienceId('testId');
 }

 @IsTest
 static void negativeUseCase() {
  System.assertNotEquals(null, PRM_LightningSelfRegisterController.selfRegister(null, null, null, null, null, null, null, null, null, null));
 }

 /* Helper method to initialize the parameters required for SelfRegistration. */
 private static Map < String, String > initializeParams() {
  Map < String, String > paramsMap = new Map < String, String > ();
  String firstName = 'test';
  String lastName = 'User';
  String email = 'testUser@salesforce.com';
  String password = 'testuser123';
  String confirmPasswordCorrect = 'testuser123';
  String confirmPasswordWrong = 'wrongpassword';
  String accountId = 'testuser123';
  String regConfirmUrl = 'http://registration-confirm.com';
  String startUrl = 'http://my.company.salesforce.com';
  paramsMap.put('firstName', firstName);
  paramsMap.put('lastName', lastName);
  paramsMap.put('email', email);
  paramsMap.put('password', password);
  paramsMap.put('confirmPasswordCorrect', confirmPasswordCorrect);
  paramsMap.put('confirmPasswordWrong', confirmPasswordWrong);
  paramsMap.put('accountId', accountId);
  paramsMap.put('regConfirmUrl', regConfirmUrl);
  paramsMap.put('startUrl', startUrl);
  return paramsMap;
 }
}