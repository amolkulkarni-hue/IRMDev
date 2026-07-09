trigger ProspectingEntryTrigger on Prospecting_Entry__c (after update) {
//Commenting code as part of #24270
	/* if(Trigger.isAfter && Trigger.isUpdate && ProspectingEntryService.afterUpdate != true){
		if(!Test.isRunningTest()) ProspectingEntryService.afterUpdate = true;
		ProspectingEntryService.splitEntriesOnLock(Trigger.newMap, Trigger.oldMap);
	} */

}