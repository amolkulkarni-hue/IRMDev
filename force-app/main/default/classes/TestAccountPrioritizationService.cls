/* Commenting the entire code as part of Gitlab #24448 */
@isTest
public with sharing class TestAccountPrioritizationService {
/*
	static RecordType fullRT;
	static RecordType briefRT;
	static Priority_Batch_Settings__c settings;
	static String ident;
	static List<Account> accounts;

	static {
		ident = String.valueOf(System.currentTimeMillis()).substring(9,13);

		// get 2 account plan record types to work with
		for(RecordType r:[SELECT Id, Name FROM RecordType WHERE sObjectType='SFDC_Acct_Plan__c' LIMIT 2]){
			if(fullRT==null) fullRT = r;
			else if(briefRT==null) briefRT = r;
		}
		settings = new Priority_Batch_Settings__c(
			Name = 'UT '+ident,
			Batch_Size__c = 400,
			Contract_Renewal_Threshhold__c = Date.today().addMonths(3),
			Start_Date__c = Date.today(),
			End_Date__c = Date.today().addMonths(3),
			IM_Volume_Threshhold__c = 100000,
			Non_IM_Volume_Threshhold__c = 200000,
			Sales_Rep_Type__c = 'Vertical',
			FULL_Record_Type_Name__c = fullRT.Name,
			BRIEF_Record_Type_Name__c = briefRT.Name
		);
		insert settings;
		accounts = TestingUtils.createAccounts(10,false);
		for(Account a:accounts){
			a.IMGA_Owner__c = UserInfo.getUserId();
		}
		insert accounts;
		Integer count = 0;
		List<Iron_Mountain_Storage_Profile__c> profiles = new List<Iron_Mountain_Storage_Profile__c>();
		for(Account a:accounts){
			count++;
			Iron_Mountain_Storage_Profile__c p = new Iron_Mountain_Storage_Profile__c(
				Account__c = a.Id,
				IM_Quantity_Cube__c = 25000 * count,
				Profiled_Quantity_Cube__c = 25000 * (10-count)
			);
			profiles.add(p);
		}
		insert profiles;
	}

	private static testMethod void testProcess(){
		List<User> users = new List<User>();
		users.add(new User(Id = UserInfo.getUserId()));
		AccountPrioritizationService svc = new AccountPrioritizationService(settings);
		svc.prioritizeForReps(users);
		List<Priority__c> priorities = [SELECT Id, Name, IMGA__c, IMGA__r.Name, Account_Plan__c, Account_Plan__r.Name, Account_Plan__r.RecordTypeId, OwnerId, IM_Volume__c, Non_IM_Volume__c, Plan_Type__c, Deadline__c, Risk_Profile__c FROM Priority__c];
		system.assertEquals(10,priorities.size());

		Integer briefCount = 0;
		for(Priority__c p:priorities){ 
			system.assert(p.Name==p.IMGA__r.Name+' Workbook');
			system.assert(p.Account_Plan__r.Name==p.IMGA__r.Name+' Plan');
			system.assertEquals(p.OwnerId, UserInfo.getUserId());
			system.assertEquals(p.Deadline__c, settings.End_Date__c);
			if(p.Plan_Type__c=='Brief'){
				briefCount++;
				system.assertEquals(p.Account_Plan__r.RecordTypeId, briefRT.Id);
			}else{
				system.assertEquals(p.Account_Plan__r.RecordTypeId, fullRT.Id);
			}
		}
		system.assertEquals(2,briefCount);
	}
*/
}