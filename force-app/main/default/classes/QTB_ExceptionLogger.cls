/*****************************************************************************************************
 * Class:          QTB_ExceptionLogger
 * Author:         Accenture
 * Purpose:        This is an independent class for handing logs
 * Requirement:    Logging exceptions in QTB process flow
 * Change History: 5/27/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture		5/27/2020
 * Accenture     7/3/2020		Added logic to use platform event for logging
 *******************************************************************************************************/
public without sharing class QTB_ExceptionLogger {
	private static final QTB_ExceptionLogger LOGGER = new QTB_ExceptionLogger();
	private static Boolean isLogsEnabled = false;
	private Metadata_Activation_Settings__c currentSetting;
	private QTB_Exception_Logger__e publisher;
	// get the activation settings for the current user each time an instance is created
	@TestVisible
	private QTB_ExceptionLogger() {
		this.refreshSettings();
	}
	private void refreshSettings() {
		this.currentSetting = Metadata_Activation_Settings__c.getInstance();
	}
	// is logging enabled
	/***********************************************************************************************************
	 * Method :      isLoggingEnabled
	 * Parameters:   void
	 * Return Type: 	boolean
	 * Description:  This method returns true if the logs are enabled for the current user, otherwise false
	 ************************************************************************************************************/
	private Boolean isLoggingEnabled() {
		return isLogsEnabled || this.currentSetting.Logs_Enabled__c;
	}
	// Enable logging
	/***********************************************************************************************************
	 * Method :      enable
	 * Parameters:   void
	 * Return Type: 	boolean
	 * Description:  This method turns the logs on for the current user
	 ************************************************************************************************************/
	public static void enable() {
		isLogsEnabled = true;
	}
	// Disable logging
	/***********************************************************************************************************
	 * Method :      disable
	 * Parameters:   void
	 * Return Type: 	boolean
	 * Description:  This method turns the logs off for the current user
	 ************************************************************************************************************/
	public static void disable() {
		isLogsEnabled = false;
	}
	// Log an Exception
	/***********************************************************************************************************
	 * Method :      log
	 * Parameters:   Exception, String
	 * Return Type: 	void
	 * Description:  This method publishes an platform event for the Exception passed
	 ************************************************************************************************************/
	@TestVisible
	private void log(Exception e, String origin) {
		if (isLoggingEnabled()) {
			this.publisher = new QTB_Exception_Logger__e();
			this.publisher.QTB_Origin__c = origin;
			this.publisher.QTB_Type__c = e.getTypeName();
			this.publisher.QTB_Body__c =
				e.getMessage() +
				' from line ' +
				e.getLineNumber() +
				'\n' +
				e.getStackTraceString();
			Eventbus.publish(this.publisher);
			// use a publisher once only
			this.publisher = null;
		}
	}
	// Log multiple Exceptions at a time
	/***********************************************************************************************************
	 * Method :      log
	 * Parameters:   List<Exception>, String
	 * Return Type: 	void
	 * Description:  This method publishes an platform event for each Exception passed
	 ************************************************************************************************************/
	@TestVisible
	private void log(List<Exception> exceptions, String origin) {
		if (isLoggingEnabled() && exceptions <> null && !exceptions.isEmpty()) {
			List<QTB_Exception_Logger__e> publishers = new List<QTB_Exception_Logger__e>();
			for (Exception eachException : exceptions) {
				QTB_Exception_Logger__e eachPublisher = new QTB_Exception_Logger__e();
				eachPublisher.QTB_Origin__c = origin;
				eachPublisher.QTB_Type__c = eachException.getTypeName();
				eachPublisher.QTB_Body__c =
					eachException.getMessage() +
					' from line ' +
					eachException.getLineNumber() +
					'\n' +
					eachException.getStackTraceString();
				publishers.add(eachPublisher);
			}
			Eventbus.publish(publishers);
		}
	}
	// static method to create log
	/***********************************************************************************************************
	 * Method :      createLog
	 * Parameters:   Exception, String
	 * Return Type: 	void
	 * Description:  This method calls log method to create an platform event for the exception
	 ************************************************************************************************************/
	public static void createLog(Exception e, String classReference) {
		LOGGER.log(e, classReference);
	}
	/***********************************************************************************************************
	 * Method :      createLog
	 * Parameters:   Integer, String, String, String, String
	 * Return Type: 	void
	 * Description:  This method publishes an platform event for the Exception passed
	 ************************************************************************************************************/
	public static void createLog(
		Integer lineNumber,
		String stackTrace,
		String errorMessage,
		String exType,
		String classReference
	) {
		try {
			//Ensure that we're well within the Governor Limits.
			//&& (Limits.getDMLRows() < Limits.getLimitDMLRows()) && (Limits.getDMLStatements() < Limits.getLimitDMLStatements())
			if (LOGGER.isLoggingEnabled()) {
				QTB_Exception_Logger__e eachPublisher = new QTB_Exception_Logger__e();
				eachPublisher.QTB_Origin__c = classReference;
				eachPublisher.QTB_Type__c = exType;
				eachPublisher.QTB_Body__c =
					errorMessage +
					' from line ' +
					lineNumber +
					'\n' +
					stackTrace;
				Eventbus.publish(eachPublisher);
			}
			/*else {
                System.debug('The Governor Limits have already been exhausted and hence failed to create a Log!');
            }*/
		} catch (Exception ex) {
			System.debug(
				'Something fatal has occurred and hence failed to create a Log! Error:' +
				ex.getMessage()
			);
		}
	}
}