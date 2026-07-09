/* Commenting the entire code as part of Gitlab #24448 */
@isTest
public with sharing class TestProspectingEntryCreationBatch {
/*
	private static Prospecting_Batch__c setting;
	private static User[] users = new User[]{};
	private static String ident;

	static {
		ident = String.valueOf(System.currentTimeMillis()).substring(9,13);
		setting = new Prospecting_Batch__c(
			Batch_Size__c = 100,
			User_Filter__c = 'Email LIKE \'%'+ident+'%\''
		);
		insert setting;
		for(Integer i=0; i<5; i++){
			users.add(TestingUtils.createUser(ident+i,false));
		}
		insert users;
	}

	@isTest private static void testSchedulable(){
		Test.startTest();
		System.schedule('ProspectingEntryCreationBatch','0 0 13 * * ?', new ProspectingEntryCreationBatch());
		Test.stopTest();
	}

	@isTest private static void testBatchable(){
		Test.startTest();
		Database.executeBatch(new ProspectingEntryCreationBatch(), Integer.valueOf(setting.Batch_Size__c));
		Test.stopTest();
		system.assertEquals(5,[SELECT Id FROM Prospecting_Entry__c].size());
		setting = [SELECT Id, Last_Batch_Start__c, Last_Batch_End__c, Last_Batch_Status__c, Last_Run_Count__c FROM Prospecting_Batch__c ORDER BY LastModifiedDate DESC LIMIT 1];
		system.assertNotEquals(null,setting.Last_Batch_Start__c);
		system.assertNotEquals(null,setting.Last_Batch_End__c);
		system.assertEquals('Complete',setting.Last_Batch_Status__c);
		system.assertEquals(5, setting.Last_Run_Count__c);
	}

	@isTest private static void testBatchable_WhileAlreadyRunning(){
		setting.Last_Batch_Status__c = 'Started';
		update setting;
		try{
			Test.startTest();
			Database.executeBatch(new ProspectingEntryCreationBatch(), Integer.valueOf(setting.Batch_Size__c));
			Test.stopTest();
			system.assert(false,'should have thrown an exception');
		}catch(Exception e){
			system.debug(e);
			system.assert(e.getMessage().contains('already be in progress'));
		}
	}
*/
}