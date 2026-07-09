/*****************************************************************************************************
 * Class: QTB_ExceptionLogger_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_ExceptionLogger
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture   5/9/2020
 *******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_ExceptionLogger_Test {
	private static QTB_ExceptionLogger logger;
	private static QTB_ExceptionLoggerTriggerHandler handler;
	@TestSetup
	static void prepareData() {
		logger = new QTB_ExceptionLogger();
		QTB_ExceptionLogger.disable();
	}
	static testMethod void testBasicCreateLog() {
		List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
		System.runAs(userList[0]) {
			Test.startTest();
			String classReference = 'QTB_InvoiceBatch';
			String errorMessage = ' Too many DML statements :151';
			String exceptionType = 'DMLException';
			Integer lineNumber = 25;
			String stackTrace = 'Sample stack trace';
			QTB_ExceptionLogger.enable();
			QTB_ExceptionLogger.createLog(
				lineNumber,
				stackTrace,
				errorMessage,
				exceptionType,
				classReference
			);
			Test.stopTest();
			system.assertEquals(
				'QTB_InvoiceBatch',
				classReference,
				'unexpected message'
			);
		}
	}
	@IsTest
	static void testCreateLogSmallVersion() {
		List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
		System.runAs(userList[0]) {
			try {
				throw new TypeException();
			} catch (TypeException e) {
				QTB_ExceptionLogger.enable();
				QTB_ExceptionLogger.createLog(e, 'Test Class');
				system.assertNotEquals('Test Class', e.getmessage());
			}
		}
	}
	@IsTest
	static void testCreateLogListVersion() {
		List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
		System.runAs(userList[0]) {
			logger = new QTB_ExceptionLogger();
			QTB_ExceptionLogger.enable();
			logger.log(
				new List<Exception>{
					new TypeException(),
					new SObjectException()
				},
				'Test Class'
			);
			system.Assert(userList.size() == 1);
		}
	}
	@IsTest
	static void testEventBasedLogging() {
		logger = new QTB_ExceptionLogger();
		QTB_ExceptionLogger.enable();
		QTB_Exception_Logger__e publisher = new QTB_Exception_Logger__e();
		publisher.QTB_Origin__c = 'QTB_ExceptionLogger_Test.testEventBasedLogging';
		publisher.QTB_Type__c = 'Test Event';
		publisher.QTB_Body__c = 'This is a test event from line number 51 QTB_ExceptionLogger_Test.testEventBasedLogging';
		Database.SaveResult publisherResult;
		List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
		System.runAs(userList[0]) {
			Test.startTest();
			publisherResult = EventBus.publish(publisher);
			Test.stopTest();
			System.assertEquals(
				true,
				publisherResult.isSuccess(),
				'Event did not publish. Error: ' + publisherResult.getErrors()
			);
			Integer availableLogs = [
				SELECT COUNT()
				FROM QTB_Exception_Log__c
				WHERE QTB_Exception_Type__c = 'Test Event'
			];
			System.assertNotEquals(0, availableLogs, 'Oops! Logs not created.');
		}
	}
}