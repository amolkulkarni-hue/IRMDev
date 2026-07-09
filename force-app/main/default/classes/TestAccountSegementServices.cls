@isTest
public with sharing class TestAccountSegementServices {
	public static String testAcctSegmentName = 'Commercial';
	static Map<Id, String> acctSegmentIdToName = new Map<Id, String>();

	static void setupAccountSegments(){
        //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
		/*UnitTest.addData(TestingUtils.createAccountSegments('test', 10, true)).tag('Account Segments');
		for(Account_Sub_Segment__c acctSegment : (List<Account_Sub_Segment__c>) UnitTest.get('Account Segments').getList()){
			acctSegmentIdToName.put(acctSegment.Id, acctSegment.Name);
		}*/
	}

	static testMethod void testFilterAccountsWithPopulatedAcctSegmentLookup(){
        //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
		//Account_Sub_Segment__c testAcctSegment = TestingUtils.createAccountSegments('test', 1, true)[0];
		List<Account> accounts = TestingUtils.createAccounts( 10, false );
        //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
		/*UnitTest.addData(accounts)
				.divide(2)
				.part('Accounts to pass')
				.part('Accounts to fail');
		
		UnitTest.get('Accounts to pass').property('Account_Segment_lookup__c').assign(testAcctSegment.Id);
		UnitTest.get(Account.SObjectType).dummyInsert();*/
		
		Test.startTest();
			List<Account> actualAccounts = AccountSegmentServices.filterAccountsWithChangedAcctSegmentLookup(accounts, null);
		Test.stopTest();
		//28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
		/*UnitTest.analyze('Accounts to pass').assertEquivalence(actualAccounts, 
						'accounts with the Account_Segment_lookup__c populated should be filtered');*/
	}

	static testMethod void testFilterAccountsWithChangedAcctSegmentLookup(){
        //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
		/*Account_Sub_Segment__c testAcctSegment = TestingUtils.createAccountSegments('test', 1, true)[0];
		List<Account> accounts = TestingUtils.createAccounts( 10, false );
		UnitTest.addData(accounts)
				.tag('Accounts')
				.divide(2)
				.part('Accounts to pass')
				.part('Accounts to fail');
		UnitTest.get(Account.SObjectType).dummyInsert();
		List<Account> oldAccounts = UnitTest.get('Accounts').getList().deepClone(true);

		UnitTest.get('Accounts to pass').property('Account_Segment_lookup__c').assign(testAcctSegment.Id);
		
		List<Account> newAccounts = UnitTest.get('Accounts').getList();*/
		
		Test.startTest();
        //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
			//List<Account> actualAccounts = AccountSegmentServices.filterAccountsWithChangedAcctSegmentLookup(newAccounts, new Map<Id, Account>(oldAccounts));*/
		Test.stopTest();
		//28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
		/*UnitTest.analyze('Accounts to pass').assertEquivalence(actualAccounts, 
						'accounts with the Account_Sub_Segment__c changed should be filtered');*/
	}
    
	//28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
	/*static testMethod void testGenerateAccountSubSegmentMap(){
		List<String> listOfTestSegments = new List<String>{'a','b','c','d','e'};
		UnitTest.addData(TestingUtils.createAccountSegments('test', 10, false))
				.tag('account segments');
		UnitTest.get('account segments').property('Account_Segment__c').assignFrom(listOfTestSegments);
		UnitTest.get('account segments').insertAll();
		UnitTest.addData(TestingUtils.createAccounts( 10, false )).tag('accounts')
				.property('Account_Segment_lookup__c')
				.assignFrom('account segments');
		UnitTest.get(Account.SObjectType).dummyInsert();

		Test.startTest();
		  	Map<Id, Account_Sub_Segment__c> actualMap = AccountSegmentServices.generateAccountSubSegmentMap(UnitTest.get('accounts').getList());
		Test.stopTest();
		Map<Id, Account_Sub_Segment__c> expectedMap = new Map<Id, Account_Sub_Segment__c>();
		for(Account_Sub_Segment__c acctSegment : (List<Account_Sub_Segment__c>) UnitTest.get('account segments').getList()){
			expectedMap.put(acctSegment.Id, acctSegment);
		}
		System.assertEquals(expectedMap.keySet(), actualMap.keySet(), 'The expected Account_Sub_Segment__c Ids were not returned');
		for(Id acctSegmentId : actualMap.keySet()) {
			System.assertNotEquals(null, expectedMap.get(acctSegmentId));
			System.assertNotEquals(null, actualMap.get(acctSegmentId));
			System.assertEquals(expectedMap.get(acctSegmentId).Name, actualMap.get(acctSegmentId).Name,
				'The incorrect name value was mapped to an Account Sub Segment Id');
			System.assertEquals(expectedMap.get(acctSegmentId).Account_Segment__c, actualMap.get(acctSegmentId).Account_Segment__c,
				'The incorrect name value was mapped to an Account Sub Segment Id');
		}
	}
	
	static testMethod void testAccountSegmentTriggerOnInsert(){
		setupAccountSegments();
		UnitTest.addData(TestingUtils.createAccounts( 10, false ))
				.tag('Accounts').divide(2)
				.part('accounts with account segment lookup prepopulated')
				.part('accounts without account segment lookup prepopulated');

		UnitTest.get('accounts with account segment lookup prepopulated')
				.property('Account_Segment_lookup__c').assignFrom('Account Segments');
		
		Test.startTest();
			UnitTest.get(Account.SObjectType).InsertAll();
		Test.stopTest();
		
		List<Account> actualAccounts = [SELECT Account_Sub_Segment__c, Account_Segment_lookup__c FROM Account];
						
		for(Account acct : actualAccounts){
			if(UnitTest.analyze('accounts with account segment lookup prepopulated').hasId(acct.Id)){
				System.assertEquals(acctSegmentIdToName.get(acct.Account_Segment_lookup__c), acct.Account_Sub_Segment__c, 
					'Account_Sub_Segment__c field on accounts should be populated with the accountSegment name associated to the correct account segment');
			}else if(UnitTest.analyze('accounts without account segment lookup prepopulated').hasId(acct.Id)){
				System.assertEquals(null, acct.Account_Sub_Segment__c, 
					'accounts that dont have the Account_Segment_lookup__c populated should have Account_Sub_Segment__c as blank');
			}
		}
    }

    static testMethod void testAccountSegmentTriggerOnUpdate(){
    	setupAccountSegments();
    	UnitTest.addData(TestingUtils.createAccounts( 10, false ))
				.tag('Accounts').divide(2)
				.part('Accounts to get updated')
				.part('Accounts not to get updated');
		insert UnitTest.get(Account.SObjectType).getList();

		List<Account> oldAccounts = UnitTest.get('Accounts').getList().deepClone(true);
					
		UnitTest.get('Accounts to get updated')
				.property('Account_Segment_lookup__c').assignFrom('Account Segments');

		List<Account> newAccounts = UnitTest.get('Accounts').getList();

		Test.startTest();
			update UnitTest.get(Account.SObjectType).getList();
		Test.stopTest();

		Set<String> accountSegmentNamesOnAccounts = Pluck.strings('Name', (List<Account_Sub_Segment__c>) UnitTest.get('Account Segments').getList());
		List<Account> actualAccounts = [SELECT Id, Account_Sub_Segment__c, Account_Segment_lookup__c FROM Account];

		for(Account acct : actualAccounts){
			if(UnitTest.analyze('Accounts to get updated').hasId(acct.Id)){
				System.assertEquals(acctSegmentIdToName.get(acct.Account_Segment_lookup__c), acct.Account_Sub_Segment__c, 
					'Account_Sub_Segment__c field on accounts should be populated with the accountSegment name associated to the correct account segment');
			}else if(UnitTest.analyze('Accounts not to get updated').hasId(acct.Id)){
				System.assertEquals(null, acct.Account_Sub_Segment__c, 
					'accounts that dont have the Account_Segment_lookup__c field changed should not get updated');
			}
		}
    }*/
}