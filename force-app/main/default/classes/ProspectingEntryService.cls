public with sharing class ProspectingEntryService {

	public static Boolean afterUpdate;

	public static void splitEntriesOnLock(Map<Id, Prospecting_Entry__c> newScope, Map<Id, Prospecting_Entry__c> oldScope){

		// figure out which entries have just been locked
		Map<Id, Prospecting_Entry__c> lockedEntries = new Map<Id, Prospecting_Entry__c>();
		for(Prospecting_Entry__c e: newScope.values()){
			if(e.IsLocked__c == true){
				Prospecting_Entry__c old = oldScope.get(e.Id);
				if(old.IsLocked__c != true){
					lockedEntries.put(e.id, e);
				}
			}
		}

		// create activity records for each recently-locked entry
		Map<Id, List<Prospecting_Activity__c>> activities = new Map<Id, List<Prospecting_Activity__c>>();
		List<Prospecting_Activity__c> allActivites = new List<Prospecting_Activity__c>();
		for(Prospecting_Entry__c entry: lockedEntries.values()){
			List<Prospecting_Activity__c> theseActivities = splitEntry(entry);
			activities.put(entry.Id, theseActivities);
			allActivites.addAll(theseActivities);
		}

		upsert allActivites Unique_ID__c;
	}

	private static List<Prospecting_Activity__c> splitEntry(Prospecting_Entry__c entry){
		List<Prospecting_Activity__c> activities = new List<Prospecting_Activity__c>();
		List<Integer> hours = divide(Integer.valueOf(entry.of_hours_spent_prospecting_this_week__c), 5);
		List<Integer> meetings = divide(Integer.valueOf(entry.of_initial_meetings_set_up_this_week__c), 5);
		List<Integer> calls = divide(Integer.valueOf(entry.of_prospecting_calls_made_this_week__c), 5);
		List<Integer> emails = divide(Integer.valueOf(entry.of_prospecting_emails_sent_this_week__c), 5);
		String name = entry.name.split('-')[0].trim();
		for(Integer i = 0; i<5; i++){
			Date d = entry.Start_Date__c + i;
			String sd = String.valueOf(d);
			Prospecting_Activity__c act = new Prospecting_Activity__c(
				Name = name + ' - ' + sd,
				Date__c = d,
				Call_Count__c = calls[i],
				Email_Count__c = emails[i],
				Hour_Count__c = hours[i],
				Meeting_Count__c = meetings[i],
				Prospecting_Entry__c = entry.Id,
				Unique_ID__c = entry.Id + ':' + sd
			);
			activities.add(act);
		}
		return activities;
	}

	@testVisible private static List<Integer> divide(Integer numerator, Integer denominator){
		Integer base = Integer.valueOf( numerator / denominator );
		Integer remainder = Math.mod( numerator, denominator );
		List<Integer> ints = new List<Integer>();
		for(Integer i = denominator; i > 0; i--){
			Integer n = base;
			if(remainder > 0){
				n+=1;
				remainder--;
			} 
			ints.add(n);
		}
		return ints;
	}

	public static Integer batchCreateWeeklyEntryRecords(Date monday, List<User> scope){
		List<Prospecting_Entry__c> entries = new List<Prospecting_Entry__c>();
		for(User u: scope){
			entries.add(new Prospecting_Entry__c(
				Name = u.Name + ' - ' + String.valueOf(monday),
				OwnerId = u.Id,
				Start_Date__c = monday,
				End_Date__c = monday + 4,
				Status__c = 'Not Submitted',
				Batch_Created__c = true
			));
		}
		insert entries;
		return entries.size();
	}

}