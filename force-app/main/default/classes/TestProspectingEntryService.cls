@isTest
public with sharing class TestProspectingEntryService {

    //Commenting code as part of #24270
	/* private static String ident;
	static {
		ident = String.valueOf(System.currentTimeMillis()).substring(9,13);
	}

	@isTest private static void testSplitEntriesOnLock_IgnoresNonLockedRecords(){
		List<Prospecting_Entry__c> entries = new List<Prospecting_Entry__c>();
		// create it locked.  should not get split later
		entries.add(TestingUtils.createProspectingEntry(UserInfo.getUserId(), true, false));
		entries[0].IsLocked__c = true;
		// create it unlocked.  lock later.  should get split.
		entries.add(TestingUtils.createProspectingEntry(UserInfo.getUserId(), true, false));
		// create it unlocked.  do not lock later.  should not get split.
		entries.add(TestingUtils.createProspectingEntry(UserInfo.getUserId(), true, false));
		insert entries;

		entries[1].IsLocked__c = true;
		Test.startTest();
		update entries;
		Test.stopTest();

		List<Prospecting_Activity__c> activities = [SELECT Id, Name, Date__c, Call_Count__c, Email_Count__c, Meeting_Count__c, Hour_Count__c, Prospecting_Entry__c, Unique_ID__c FROM Prospecting_Activity__c];
		system.assertEquals(5, activities.size());
		Date monday = ProspectingContExt.static_getThisMonday();
		Date friday = monday+4;
		for(Prospecting_Activity__c a:activities){
			String d = String.valueOf(a.Date__c);
			system.assertEquals(entries[1].Id, a.Prospecting_Entry__c);
			system.assert(a.Date__c>=monday && a.Date__c<=friday);
			system.assertEquals(UserInfo.getFirstName()+' '+UserInfo.getLastName()+' - '+d, a.Name);
			system.assertEquals(entries[1].Id+':'+d, a.Unique_ID__c);
			system.assertEquals(2, a.Call_Count__c);
			system.assertEquals(2, a.Email_Count__c);
			system.assertEquals(2, a.Hour_Count__c);
			system.assertEquals(2, a.Meeting_Count__c);
		}
	}

	@isTest private static void testDivide(){
		system.assertEquals(new Integer[]{3,3,2,2,2}, ProspectingEntryService.divide(12,5));
		system.assertEquals(new Integer[]{1,1,1,0,0}, ProspectingEntryService.divide(3,5));
	}

	@isTest private static void testBatchCreate(){
		User[] users = new User[]{};
		for(Integer i=0; i<5; i++){
			users.add(TestingUtils.createUser(ident+i,false));
		}
		insert users;
		Test.startTest();
		Integer entrySize = ProspectingEntryService.batchCreateWeeklyEntryRecords(ProspectingContExt.static_getThisMonday(), users);
		Test.stopTest();
		system.assertEquals(5,entrySize);
		system.assertEquals(entrySize, [SELECT Id FROM Prospecting_Entry__c].size());
	} */

}