/**
 * @author         Accenture
 * @modifiedBy     Accenture
 * @created        3/17/2020
 * @modified       3/30/2020
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * Description: Batch Apex Class to Create Renewal Opportunities Automatically
 * Story No: OM-5 (SPRINT-1),ALM defect 416,GITLAB #1991
 * Requirement : Auto Check Renewal Forecast
 *
 * ___________________________________________________________________________________________________
 */
global class QTB_RenewContractsBatch implements Database.Batchable<SObject>, Database.Stateful {
  private static final String CLASSNAME = QTB_RenewContractsBatch.class
    .getName();
  public static boolean throwExplicitException = false;
  Set<ID> contractIDset = new Set<ID>();
  String TERMINATION = QTB_Constants.TERMINATION;
  String RETENTION = QTB_Constants.RETENTION;
  String SPECIALPROJECT_RM = QTB_Constants.SPECIALPROJECT_RM;
  String SPECIALPROJECT_DM = QTB_Constants.SPECIALPROJECT_DM;
  String SPECIALPROJECT_International = QTB_Constants.SPECIALPROJECT_International;
  String CONTRACT_SALES_RECTYPEID = QTB_Utils.CONTRACT_SALES_RECTYPEID;
  String CONT_ACTIVATED_STATUS = QTB_Constants.CONT_ACTIVATED_STATUS;
  private static final List<Exception> ERRORLIST = new List<Exception>();
  public Id prevAccountId;
  public Id prevContractId;
  /*********************************************************************************************************
  Method Name: start
  Parameters: Database.BatchableContext
  Return Type: Database.QueryLocator
  Requirement: SFCPQBLG-9
  Description: Query required records
  **********************************************************************************************************/
  global Database.QueryLocator start(Database.BatchableContext bc) {
    // create renewal opportunity 12 months prior
    Date nextRenewalDate = Date.today()
      .addmonths(Integer.valueOf(System.label.QTB_Twelve_Months));
    // create renewal quote 60 days prior to renewal notice date --added for GITLAB# 1991
    Date quoteRenewalDate = Date.today()
      .addDays(Integer.valueOf(System.label.QTB_Renewal_Quote_Generation_Days));
    //ALM-513 start - enhancement to restrict contract renewal for configured countries
    String errorCountries = '';
    //Countries to be excluded from Renewal are stored in custom setting
    List<QTB_Exclude_Countries__c> countryCustSett = QTB_Exclude_Countries__c.getAll()
      .Values();
    List<String> excludeCountryList = new List<String>();
    Set<String> excludeCountrySet = new Set<String>();
    List<String> allCountriesList = new List<String>();

    //Check if custom setting has any entries
    if (countryCustSett.size() > 0) {
      for (IM_Country__c countr : [SELECT name FROM IM_Country__c]) {
        allCountriesList.add(countr.name);
      }
      //Collect all the availalable countries to a list
      for (QTB_Exclude_Countries__c custSett : countryCustSett) {
        if (String.isNotBlank(custSett.QTB_Country__c)) {
          excludeCountryList.addAll(custSett.QTB_Country__c.split(','));
        }
      }
      if (!excludeCountryList.isEmpty() && !allCountriesList.isEmpty()) {
        //next 3 lines are to eliminate duplicates from custom setting countries list
        excludeCountrySet.addAll(excludeCountryList);
        excludeCountryList.clear();
        excludeCountryList.addAll(excludeCountrySet);
        //iterate over custom setting countries and check if country entered is valid
        for (String countr : excludeCountryList) {
          if (!allCountriesList.contains(countr)) {
            errorCountries += ',' + countr;
          }
        }
      }
      system.debug('excludeCountryList-->' + excludeCountryList);
      //If incorrect country is entered in custom setting, capture it in Error Log object
      if (String.isNotBlank(errorCountries)) {
        errorCountries = 'Incorrect Countries::' + errorCountries;
        QTB_ExceptionLogger.createLog(
          1,
          'Incorrect Countries enter in custom Setting:QTB_Exclude_Countries__c',
          errorCountries,
          '',
          CLASSNAME
        );
      }
    }
    //ALM-513 enhancement end
    String query =
      'SELECT name,SBQQ__RenewalForecast__c, AccountId, ' +
      'SBQQ__RenewalQuoted__c, Id, EndDate,' +
      'SBQQ__Opportunity__r.Primary_Product_Line__c,' +
      'SBQQ__Quote__r.QTB_Customer_Care_Quote_Type__c,' +
      'SBQQ__Evergreen__c,' +
      'SBQQ__RenewalOpportunity__r.QTB_Renewal_Notice_Date__c FROM Contract';

    //This is where you input the conditions for the records which you wish to set renewal for
    List<String> conditions = new List<String>{
      'SBQQ__RenewalQuoted__c = False',
      'SBQQ__RenewalForecast__c = false',
      'SBQQ__Quote__r.QTB_Customer_Care_Quote_Type__c <>: TERMINATION',
      'SBQQ__Quote__r.QTB_Customer_Care_Quote_Type__c <>: RETENTION',
      'SBQQ__Opportunity__r.Primary_Product_Line__c <>: SPECIALPROJECT_RM',
      'SBQQ__Opportunity__r.Primary_Product_Line__c <>: SPECIALPROJECT_DM',
      'SBQQ__Opportunity__r.Primary_Product_Line__c <>: SPECIALPROJECT_International',
      'SBQQ__Evergreen__c = False',
      'EndDate <= :nextRenewalDate',
      'RecordTypeId = :CONTRACT_SALES_RECTYPEID',
      'Status =:CONT_ACTIVATED_STATUS',
      'Billing_Country__r.Name NOT IN :excludeCountryList '
    };

    //This is where you input the conditions for the records which you wish to set quote renewal for
    //query modified for GITLAB#1991 to add renew contract condition
    List<String> quoteConditions = new List<String>{
      'SBQQ__RenewalQuoted__c = False',
      'SBQQ__RenewalForecast__c = true',
      'SBQQ__Evergreen__c = False',
      'SBQQ__Quote__r.QTB_Customer_Care_Quote_Type__c <>: TERMINATION',
      'SBQQ__Quote__r.QTB_Customer_Care_Quote_Type__c <>: RETENTION',
      'SBQQ__Opportunity__r.Primary_Product_Line__c <>: SPECIALPROJECT_RM',
      'SBQQ__Opportunity__r.Primary_Product_Line__c <>: SPECIALPROJECT_DM',
      'SBQQ__Opportunity__r.Primary_Product_Line__c <>: SPECIALPROJECT_International',
      'SBQQ__RenewalOpportunity__r.QTB_Renewal_Notice_Date__c <= :quoteRenewalDate',
      'RecordTypeId = :CONTRACT_SALES_RECTYPEID',
      'Status =:CONT_ACTIVATED_STATUS',
      'Billing_Country__r.Name NOT IN :excludeCountryList '
    };

    // query modified for GITLAB #1991 to add renew quotes conditions
    query +=
      ' WHERE ( ' +
      String.join(conditions, ' AND ') +
      ') OR (' +
      String.join(quoteConditions, ' AND ') +
      ' )';

    System.debug('Query String:' + query);
    return Database.getQueryLocator(query);
  }
  /*********************************************************************************************************
  Method Name: execute
  Parameters: Database.BatchableContext,List<SBQQ__Quote__c>
  Return Type: void
  Requirement: SFCPQBLG-9 , SFCPQBLG-16
  Description: Sets the renewal forecast and renewal quoted to true
  **********************************************************************************************************/
  global void execute(Database.BatchableContext bc, List<Contract> scope) {
    //Scope size is 1
    try {
      String errorMessage = '';
      if (throwExplicitException) {
        wait(10);
        throw new NullPointerException();
      }
      Database.SaveResult[] results;
      List<SBQQ__RecordJob__c> recordsList = new List<SBQQ__RecordJob__c>();
      String recordStatus = QTB_Constants.RECORDJOB_COMPLETED;

      system.debug('Scope==>' + scope);
      for (Contract eachContract : scope) {
        if (eachContract.SBQQ__RenewalForecast__c == false) {
          //added the if condition to check the renew forecast value for GITLAB #1991
          eachContract.SBQQ__RenewalForecast__c = true;
        }
        //added to mark the renew quoted as true
        if (
          eachContract.SBQQ__RenewalForecast__c == true &&
          eachContract.SBQQ__RenewalOpportunity__r.QTB_Renewal_Notice_Date__c <=
          Date.today()
            .addDays(
              Integer.valueOf(System.label.QTB_Renewal_Quote_Generation_Days)
            )
        ) {
          eachContract.SBQQ__RenewalQuoted__c = true;
        }
      }
      system.debug(
        'Prior Account ID==>' +
        prevAccountId +
        ';;Current AccountID==>' +
        scope[0].AccountId +
        ';;Prev Contract Id==>' +
        prevContractId
      );
      //handle if current contract's account id is same as previous contract's account id
      if ((prevAccountId == scope[0].AccountId && prevContractId != null)) {
        string tempVar = '%' + prevContractId + '%';
        for (SBQQ__RecordJob__c recJob : [
          SELECT id, SBQQ__JobStatus__c, Createddate, LastModifiedDate
          FROM SBQQ__RecordJob__c
          WHERE SBQQ__RecordId__c LIKE :tempVar
          LIMIT 1
        ]) {
          if (
            (Date.newInstance(
              recJob.Createddate.year(),
              recJob.Createddate.month(),
              recJob.Createddate.day()
            ) == System.Today()) ||
            (Date.newInstance(
              recJob.LastModifiedDate.year(),
              recJob.LastModifiedDate.month(),
              recJob.LastModifiedDate.day()
            ) == System.Today())
          ) {
            //If previous contract is still processing, wait hold time of 25 sec and then process current record else simply update
            if (
              recJob.SBQQ__JobStatus__c == QTB_Constants.RECORDJOB_INPROGRESS ||
              recJob.SBQQ__JobStatus__c == null
            ) {
              wait(QTB_Constants.WAIT_TIME);
              results = Database.update(scope, false);
            } else if (
              recJob.SBQQ__JobStatus__c == QTB_Constants.RECORDJOB_FAILED ||
              recJob.SBQQ__JobStatus__c == QTB_Constants.RECORDJOB_COMPLETED
            ) {
              results = Database.update(scope, false);
            }
          }
        }
      } else if (prevAccountId != scope[0].AccountId) {
        results = Database.update(scope, false);
      }

      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          // Operation was successful, so get the ID of the record that was processed
          contractIDset.add(results[i].getId());
        } else {
          errorMessage +=
            ';;' +
            scope[i].name +
            ' with Id ' +
            scope[i].id +
            'Error is::' +
            results[i].getErrors()[0].getMessage();
        }
      }
      system.debug('errorMessage-->' + errorMessage);
      if (errormessage != '') {
        if (errormessage.length() > 100000)
          errormessage = errormessage.substring(0, 100000);
        QTB_ExceptionLogger.createLog(
          1,
          'Contract Renewal Failed',
          errormessage,
          '',
          CLASSNAME
        );
      }

      //save current contract's account id as previous id for next transaction
      prevAccountId = scope[0].AccountId;
      prevContractId = scope[0].id;
    } catch (Exception e) {
      QTB_ExceptionLogger.createLog(
        e.getLineNumber(),
        e.getStackTraceString(),
        e.getMessage(),
        e.getTypeName(),
        CLASSNAME
      );
    }
  }
  /*********************************************************************************************************
  Method Name: finish
  Parameters: Database.BatchableContext
  Return Type: void
  Requirement: SFCPQBLG-9
  Description: Calling Renewal Uplift Scheduler to trigger integration to PriceFx
  **********************************************************************************************************/
  global void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [
      SELECT
        Id,
        Status,
        NumberOfErrors,
        JobItemsProcessed,
        TotalJobItems,
        CreatedBy.Email
      FROM AsyncApexJob
      WHERE Id = :bc.getJobId()
    ];
    datetime dt = system.now().addminutes(59);
    String day = string.valueOf(dt.day());
    String month = string.valueOf(dt.month());
    String hour = string.valueOf(dt.hour());
    String minute = string.valueOf(dt.minute());
    String second = string.valueOf(dt.second());
    String year = string.valueOf(dt.year());
    String strSchedule =
      '0 ' +
      minute +
      ' ' +
      hour +
      ' ' +
      day +
      ' ' +
      month +
      ' ?' +
      ' ' +
      year;

    System.schedule(
      'Renewal Uplift Batch' + system.now(),
      strSchedule,
      new QTB_RenewalUpliftScheduler(contractIDset)
    );
  }
  //Sleep method to hold transaction
  public void wait(Integer millisec) {
    if (millisec == null || millisec < 0) {
      millisec = 0;
    }
    Long startTime = DateTime.now().getTime();
    Long finishTime = DateTime.now().getTime();
    while ((finishTime - startTime) < millisec) {
      finishTime = DateTime.now().getTime();
    }
  }
}