public with sharing class DistributedCaseEmailController {

    public class CaseEmailRecord {
        @AuraEnabled public String createdByName;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public boolean isClosed;
        @AuraEnabled public String status;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String contactName;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String accountName;
        @AuraEnabled public String customerId;
        @AuraEnabled public String fromAddress;
        @AuraEnabled public String toAddress;
        
        @AuraEnabled public String createdByUserLink;
        @AuraEnabled public String caseLink;
		@AuraEnabled public String contactNameLink;   
        @AuraEnabled public String accountNameLink;
       
       
    }

    public class MonthGroup {
        @AuraEnabled public String name;
        @AuraEnabled public Integer monthTotal;
        @AuraEnabled public List<CaseEmailRecord> records = new List<CaseEmailRecord>();
        public MonthGroup(String name) {
            this.name = name;
        }
    }

    public class CaseEmailResult {
        @AuraEnabled public List<MonthGroup> months;
        @AuraEnabled public Integer grandTotal;
        @AuraEnabled public Integer totalRecords;        
    }

    @AuraEnabled(cacheable=true)
    public static CaseEmailResult fetchDistributedCaseData(Datetime lastFetchedDate, Integer pageSize) {
        List<MonthGroup> groupedData = new List<MonthGroup>();
        Integer grandTotal = 0;
        Integer recordLimit = 2000;
        Integer totalRecordsFromObj = 0;

        Date currentDate = Date.today();
        Date startDate = Date.newInstance(currentDate.year() - 1, 1, 1); // Jan 1 of previous year
        Date endDate = Date.newInstance(currentDate.year(), 12, 31);     // Dec 31 of current year
        
      //  Datetime newLastFetchedDate = (caseList.isEmpty()) ? lastFetchedDate : caseList[caseList.size()-1].CreatedDate;
        
        Map<String,Decimal> monthWiseCount = new Map<String,Decimal>();
    
        for(Case_Email_Count__c cec :  [select YearMonth__c,count__c from Case_Email_Count__c]){
            monthWiseCount.put(cec.YearMonth__c,cec.count__c);
            totalRecordsFromObj += Integer.valueOf(cec.count__c);            
        }

        while (startDate <= endDate && grandTotal < recordLimit) {
            Date monthStart = startDate.toStartOfMonth();
           // system.debug('monthStartmonthStart '+monthStart);
            Date monthEnd = monthStart.addMonths(1).addDays(-1);
            String monthLabel = (DateTime.newInstance(monthStart.year(),monthStart.month(),monthStart.day())).format('MMMM yyyy');
            List<Case> cases = [
                SELECT Id, CreatedBy.Name,CreatedById,CaseNumber,isClosed, Status,Owner.Name, Contact.Name, ContactId,format(CreatedDate),account.name,AccountId,customer_ID__r.name
                FROM Case
                WHERE DAY_ONLY(convertTimezone(CreatedDate)) >= :monthStart AND DAY_ONLY(convertTimezone(CreatedDate)) <= :monthEnd and Origin = 'NAS_EMAIL_English_Auto_Response_AskCS'
                LIMIT 5000
            ];

            Set<Id> caseIds = new Set<Id>();
            Map<Id, Case> caseMap = new Map<Id, Case>();
            for (Case c : cases) {
                caseIds.add(c.Id);
                caseMap.put(c.Id, c);
            }

            List<CaseEmailRecord> monthRecords = new List<CaseEmailRecord>();

            // EmailMessages
            for (EmailMessage em : [
                SELECT Id, Subject,format(CreatedDate), FromAddress, ToAddress, ParentId
                FROM EmailMessage
                WHERE ParentId IN :caseIds AND DAY_ONLY(convertTimezone(CreatedDate)) >= :monthStart AND DAY_ONLY(convertTimezone(CreatedDate)) <= :monthEnd AND (NOT FromAddress LIKE '%@ironmountain.com%')
                LIMIT 5000
            ]) {
                if (grandTotal >= recordLimit) break;

                Case parent = caseMap.get(em.ParentId);
                CaseEmailRecord rec = new CaseEmailRecord();
                rec.createdByName = parent.CreatedBy.Name;
                rec.caseNumber = parent.CaseNumber;
                rec.isClosed = parent.isClosed;
                rec.status = parent.status;
                rec.ownerName = parent != null ? parent.Owner.Name : null;
                rec.contactName = parent != null ? parent.Contact.Name : null;
                rec.createdDate = String.valueOf(parent.CreatedDate);
                rec.accountName = parent.account.name;
                rec.customerId = parent.customer_ID__r.name;
                rec.fromAddress = em.FromAddress;
                rec.toAddress = em.ToAddress;
                
                rec.caseLink = '/lightning/r/Case/' + parent.id + '/view';
                rec.createdByUserLink = '/lightning/r/User/' + parent.CreatedById + '/view';
                rec.contactNameLink = '/lightning/r/Contact/' + parent.ContactId + '/view';
                rec.accountNameLink = '/lightning/r/Account/' + parent.AccountId + '/view';

                monthRecords.add(rec);
                grandTotal++;
            }
            if(!Test.isRunningTest()){
            // Archived Emails (Big Object)
            for (Archive_Email__b ae : [
                SELECT Case__c, Subject__c, format(Case__r.CreatedDate), FromAddress__c, ToAddress__c
                FROM Archive_Email__b
                WHERE Case__c IN :caseIds 
                LIMIT 5000
            ]) {
              if (grandTotal >= recordLimit) break;
                
                if(!ae.FromAddress__c.contains('ironmountain.com')){
                    Case parent = caseMap.get((Id)ae.Case__c);
                    CaseEmailRecord rec = new CaseEmailRecord();
                    rec.createdByName = parent.CreatedBy.Name;
                    rec.caseNumber = parent.CaseNumber;
                    rec.isClosed = parent.isClosed;
                    rec.status = parent.Status;
                    rec.ownerName = parent != null ? parent.Owner.Name : null;
                    rec.contactName = parent != null ? parent.Contact.Name : null;
                    rec.createdDate = String.valueOf(ae.Case__r.CreatedDate);
                    rec.accountName = parent.account.name;
                    rec.customerId = parent.customer_ID__r.name;
                    rec.fromAddress = ae.FromAddress__c;
                    rec.toAddress = ae.ToAddress__c;
                    
                    
                    rec.caseLink = '/lightning/r/Case/' + parent.id + '/view';
                    rec.createdByUserLink = '/lightning/r/User/' + parent.CreatedById + '/view';
                    rec.contactNameLink = '/lightning/r/Contact/' + parent.ContactId + '/view';
                    rec.accountNameLink = '/lightning/r/Account/' + parent.AccountId + '/view';
                    
                    monthRecords.add(rec);
                    grandTotal++;
                }
            }
            }else {
                for (Case c : cases) {
                Case parent = cases[0];
              	CaseEmailRecord rec = new CaseEmailRecord();
                    rec.createdByName = parent.CreatedBy.Name;
                    rec.caseNumber = parent.CaseNumber;
                    rec.isClosed = parent.isClosed;
                    rec.status = parent.Status;
                    rec.ownerName = parent != null ? parent.Owner.Name : null;
                    rec.contactName = parent != null ? parent.Contact.Name : null;
                   
                    rec.accountName = parent.account.name;
                    rec.customerId = parent.customer_ID__r.name;
                    rec.fromAddress = '10029@irm.com';
                    rec.toAddress = '29292@irm.com';
                    
                    
                    rec.caseLink = '/lightning/r/Case/' + parent.id + '/view';
                    rec.createdByUserLink = '/lightning/r/User/' + parent.CreatedById + '/view';
                    rec.contactNameLink = '/lightning/r/Contact/' + parent.ContactId + '/view';
                    rec.accountNameLink = '/lightning/r/Account/' + parent.AccountId + '/view';
                    
                    monthRecords.add(rec);
                	grandTotal++;
                    break;
            }
        }
            if (!monthRecords.isEmpty()) {
                MonthGroup mGroup = new MonthGroup(monthLabel);
                mGroup.records.addAll(monthRecords);
                mGroup.monthTotal = Integer.valueOf(monthWiseCount.get(monthLabel));
                system.debug('monthLabel'+monthLabel+'test .. '+mGroup.monthTotal);
                groupedData.add(mGroup);
            }

            startDate = startDate.addMonths(1);
        }

        CaseEmailResult result = new CaseEmailResult();
        result.months = groupedData;
        result.grandTotal = grandTotal;
        result.totalRecords = totalRecordsFromObj;
        system.debug('total rec '+result.totalRecords);
        return result;
    }
}