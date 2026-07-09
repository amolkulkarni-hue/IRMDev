/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Test
 * @description The test class for LoggerMock 
 */

@IsTest
private class LoggerMockTest {
	@isTest
    static void correctLogging() {
        LoggerMock logger = new LoggerMock();
        Test.startTest();
        	logger.log('Test Message', LoggerMock.class);
        Test.stopTest();
        
        System.assert(!logger.loggedEvents.isEmpty(), 'Something should be log');
    }
    
    @isTest
    static void emitTest() {
        LoggerMock logger = new LoggerMock();
        Test.startTest();
        	logger.emit();
        Test.stopTest();
        
        System.assert(logger.didEmit, 'Email should be sent once the emit function is called');
    }
}