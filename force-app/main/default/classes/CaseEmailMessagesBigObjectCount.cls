/*******************************************************************************************************
* Class: CaseEmailMessagesBigObjectCount
* Purpose: Batch class to populate the Case_Email_Count__c object for reporting
* Developer         Date             Description
* -------------------------------------------------------------------------------------------------------
* Praneel           03/Jul/2025      Batch class to populate Case_Email_Count__c data
*********************************************************************************************************/

global virtual without sharing class CaseEmailMessagesBigObjectCount implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private static final Map<Integer, String> MONTH_ABBREVIATIONS = new Map<Integer, String>{
        1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June',
        7 => 'July', 8 => 'August', 9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'
    };

    DateTime startDateTime;
    DateTime endDateTime;
    Date startDate;
    Date endDate;
    @Testvisible Map<String, Case_Email_Count__c> emailMessageCountByMonth = new Map<String, Case_Email_Count__c>();
	@testVisible private static Archive_Email__b archivedEmail;
    public CaseEmailMessagesBigObjectCount() {}

    public CaseEmailMessagesBigObjectCount(Date startDate, Date endDate) {
        if (startDate == null || endDate == null || startDate > endDate) {
            throw new IllegalArgumentException('Invalid date range');
        }
        this.startDate = startDate;
        this.endDate = endDate;
        this.startDateTime = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
        Date nextDay = endDate.addDays(1);
        this.endDateTime = DateTime.newInstance(nextDay.year(), nextDay.month(), nextDay.day(), 0, 0, 0);
        system.debug('startDateTime '+startDateTime);
        system.debug('endDateTime '+endDateTime);
    }
    
    /*********************************************************************************************************
    * Method Name: start
    * Parameters: Database.BatchableContext
    * Return Type: Database.QueryLocator
    * Requirement: 
    * Description: Start method to fetch the case records to get the data from case
    *********************************************************************************************************/
    

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, CreatedDate, IsClosed FROM Case WHERE IsClosed = true and Origin = \'NAS_EMAIL_English_Auto_Response_AskCS\'';
               query += ' AND DAY_ONLY(convertTimezone(CreatedDate)) >= :startDate AND DAY_ONLY(convertTimezone(CreatedDate)) <= :endDate';
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
    * Method Name: execute
    * Parameters: Database.BatchableContext, List<Case> caselst
    * Return Type: void
    * Requirement: 
    * Description: Execute method to construct map that contains the bigobject data 
    *********************************************************************************************************/

    global void execute(Database.BatchableContext bc, List<Case> caselst) {
        Integer year, month;
        String yearAndMonthKey;

        Set<Id> caseIds = new Set<Id>();
        for (Case c : caselst) {
            caseIds.add(c.Id);
        }
       
        

        for (Archive_Email__b archive : getArchiveEmails(caseIds)) {
            DateTime createdDate;
            String strFromAddress;
            if(test.isRunningTest()){
                createdDate = System.now();
                strFromAddress = '';
            }else{
                createdDate = archive.Case__r.CreatedDate;
                strFromAddress = archive.FromAddress__c;
            }
            if(!strFromAddress.contains('ironmountain.com')){
                year = createdDate.year();
                month = createdDate.month();
                yearAndMonthKey =  createdDate.format('MMMM') + ' ' + year;
                
                
                Case_Email_Count__c countRecord;
                if (!emailMessageCountByMonth.containsKey(yearAndMonthKey)) {
                    countRecord = new Case_Email_Count__c(Count__c = 1);
                } else {
                    countRecord = emailMessageCountByMonth.get(yearAndMonthKey);
                    countRecord.Count__c += 1;
                }
                
                countRecord.Name = yearAndMonthKey;
                countRecord.Year__c = year;
                countRecord.Month__c = month;
                countRecord.YearMonth__c = yearAndMonthKey;
                
                emailMessageCountByMonth.put(yearAndMonthKey, countRecord);
            }
        }
    }
    
    /*********************************************************************************************************
    * Method Name: finish
    * Parameters: Database.BatchableContext
    * Return Type: void
    * Requirement: 
    * Description: Finish method to insert data into Case_Email_Count__c object from constructed map
    *********************************************************************************************************/

    global void finish(Database.BatchableContext bc) {
        Integer year, month, emailCount;
        String yearAndMonthKey;

        for (AggregateResult result : [
            SELECT CALENDAR_YEAR(convertTimezone(Parent.CreatedDate)) year, CALENDAR_MONTH(convertTimezone(Parent.CreatedDate)) month, COUNT(Id) emailCount
            FROM EmailMessage
            WHERE ParentId IN (
                SELECT Id FROM Case
                WHERE Origin = 'NAS_EMAIL_English_Auto_Response_AskCS'
                AND DAY_ONLY(convertTimezone(CreatedDate)) >= :startDate AND DAY_ONLY(convertTimezone(CreatedDate)) <= :endDate
            )
            AND (NOT FromAddress LIKE '%@ironmountain.com%')
            GROUP BY CALENDAR_YEAR(convertTimezone(Parent.CreatedDate)), CALENDAR_MONTH(convertTimezone(Parent.CreatedDate))
        ]) {
            year = (Integer) result.get('year');
            month = (Integer) result.get('month');
            emailCount = (Integer) result.get('emailCount');
            yearAndMonthKey = MONTH_ABBREVIATIONS.get(month) + ' ' + year;

            Case_Email_Count__c countRecord;
            if (!emailMessageCountByMonth.containsKey(yearAndMonthKey)) {
                countRecord = new Case_Email_Count__c(Count__c = emailCount);
            } else {
                countRecord = emailMessageCountByMonth.get(yearAndMonthKey);
                countRecord.Count__c += emailCount;
            }

            countRecord.Name = yearAndMonthKey;
            countRecord.Year__c = year;
            countRecord.Month__c = month;
            countRecord.YearMonth__c = yearAndMonthKey;

            emailMessageCountByMonth.put(yearAndMonthKey, countRecord);
        }

        if (!emailMessageCountByMonth.isEmpty()) {
            upsert emailMessageCountByMonth.values() YearMonth__c;
        }
    }

    global void execute(SchedulableContext sc) {
        Integer currentYear = Date.today().year();
        Integer previousYear = currentYear - 1;
        Date previousYearJan1st = Date.newInstance(previousYear, 1, 1);
        Date currentYearDec31st = Date.newInstance(currentYear, 12, 31);

        CaseEmailMessagesBigObjectCount batch = new CaseEmailMessagesBigObjectCount(previousYearJan1st, currentYearDec31st);
        Database.executeBatch(batch);
    }
	
    private List<Archive_Email__b> getArchiveEmails(Set<Id> caseIds) {
        
         if(test.isRunningTest()){
            system.debug('running ......'+archivedEmail);
             List<Archive_Email__b> arcEmaLst= new List<Archive_Email__b>();
             arcEmaLst.add(archivedEmail);
             return arcEmaLst;
        }
        return [SELECT Id, Case__r.CreatedDate,FromAddress__c FROM Archive_Email__b WHERE Case__c IN :caseIds];
    }
   
}