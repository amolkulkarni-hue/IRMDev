public with sharing class AccountSegmentServices {
    public static List<Account> filterAccountsWithChangedAcctSegmentLookup(List<Account> accounts, Map<Id, Account> oldMap){
        
        List<Account> filteredAccts = new List<Account>();
        //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
       /* for(Account acct : accounts){
            if(oldMap != null){
                if(acct.Account_Segment_lookup__c != null && acct.Account_Segment_lookup__c != oldMap.get(acct.Id).Account_Segment_lookup__c){
                    filteredAccts.add(acct);
                }
            }else if(acct.Account_Segment_lookup__c != null){
                filteredAccts.add(acct);
            }
        }*/
        
        return filteredAccts;
    }
    //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
    /**
    * assumption: all accounts coming into this function have the Account_Segment_lookup__c populated or changed
    * @param: list of accounts that have the Account_Segment_lookup__c either populated or changed
    * @return: Map of Account_Sub_Segment__c Id to the corresponding Account_Sub_Segment__c name
    */
   /* public static Map<Id, Account_Sub_Segment__c> generateAccountSubSegmentMap(List<Account> accounts){
        Set<Id> accountSubSegmentIds = Pluck.ids('Account_Segment_lookup__c', accounts);
        Map<Id, Account_Sub_Segment__c> accountSubSegmentMap = new Map<Id, Account_Sub_Segment__c>();
        List<Account_Sub_Segment__c> accountSegments = [SELECT Id, Name, Account_Segment__c FROM Account_Sub_Segment__c WHERE Id IN: accountSubSegmentIds];

        for(Account_Sub_Segment__c acctSegment : accountSegments){
            accountSubSegmentMap.put(acctSegment.Id, acctSegment);
        }

        return accountSubSegmentMap;
    }*/
	//28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
   /* public static void processAccounts(List<Account> accounts, Map<Id, Account_Sub_Segment__c> accountSegmentMap){
        for(Account acct : accounts){
            if( accountSegmentMap.get(acct.Account_Segment_lookup__c) != null ) {
                acct.Account_Sub_Segment__c = accountSegmentMap.get(acct.Account_Segment_lookup__c).Name;
                acct.Account_Segment__c = accountSegmentMap.get(acct.Account_Segment_lookup__c).Account_Segment__c;
            }
        }
    }*/
}