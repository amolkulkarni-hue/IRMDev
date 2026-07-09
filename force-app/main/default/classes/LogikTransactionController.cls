public with sharing class LogikTransactionController {

    @AuraEnabled
    public static Id getAccountId(Id opportunityId) {
        Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        return opp.AccountId;
    }

    @AuraEnabled
    public static String getLgkId(Id transactionId) {
        LGK__Transaction__c tx = [
            SELECT LGK__Id__c 
            FROM LGK__Transaction__c 
            WHERE Id = :transactionId 
            LIMIT 1
        ];
        return tx.LGK__Id__c;
    }
}