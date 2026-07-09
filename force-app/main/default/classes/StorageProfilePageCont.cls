public with sharing class StorageProfilePageCont 
{
	public static final String CUBE = 'Cube';
	public static final String DBnR_CONTAINER = 'DB&R Container';
	public static final String TAPE = 'Tape';
	public ID accountID {get;set;}
	public ID returnID {get;set;}
	public ID ironProfileID {get;set;}

	public StorageProfilePageCont(){
		
	}
	
	public Map<Id, Iron_Mountain_Storage_Profile__c> ironMountainStorageProfileMap
	{
		get
		{
			if( ironMountainStorageProfileMap == NULL )
			{
				ironMountainStorageProfileMap = new Map<Id, Iron_Mountain_Storage_Profile__c> ( 
													[ SELECT Whitespace_Tape__c, Whitespace_DB_R_Container__c, Whitespace_Cube__c, Profiled_Quantity_Tape__c, 
													Profiled_Quantity_DB_R_Container__c, Profiled_Quantity_Cube__c, Name, IM_Quantity_Tape__c, IM_Quantity_DB_R_Container__c, IM_Quantity_Cube__c, 
													( SELECT Name, Quantity_Tape__c, Quantity_DB_R_Container__c, Quantity_Cube__c, Vendor__r.name FROM Storage_Profiles__r order by Vendor__r.name ) 
													FROM Iron_Mountain_Storage_Profile__c WHERE Account__c = :accountID ] );
													
								
			}
			return ironMountainStorageProfileMap;
		}
		public set;
	}
	
	public Boolean atLeastOneIronMountainStorageProfile {
		get {
			return !ironMountainStorageProfileMap.isEmpty();
		}
		private set;
	}
	
	public List<Iron_Mountain_Storage_Profile__c> emptyIronMountainStorageProfile {
		get {
			if( emptyIronMountainStorageProfile == null )
			{
				Iron_Mountain_Storage_Profile__c empty = new Iron_Mountain_Storage_Profile__c(Account__c = accountID);
				emptyIronMountainStorageProfile = new List<Iron_Mountain_Storage_Profile__c>{empty};
			}
			return emptyIronMountainStorageProfile;
		}
		private set;
	}
	
	public list<Iron_Mountain_Storage_Profile__c> ironMountainStorageProfiles
	{
		get 
		{
			return  ironMountainStorageProfileMap.values();
		}
		set;
	}
	
	public String createNewCompetitorProfile
	{
		get 
		{
			if(String.isBlank( createNewCompetitorProfile ))
			{
				PageReference storageProfileCreationPage = Page.StorageProfileNew;
				storageProfileCreationPage.getParameters().put('retURL', '/' + returnID);
				storageProfileCreationPage.getParameters().put(StorageProfileContExt.ACCOUNT_ID_PARAM, accountID);
				
				createNewCompetitorProfile = URL.getSalesforceBaseUrl().toExternalForm() + storageProfileCreationPage.getUrl();
			}
			return  createNewCompetitorProfile;
		}
		set;
	}
	
	public pageReference saveNewProfile() {
		
		try{
			insert emptyIronMountainStorageProfile;	
			ironProfileID = emptyIronMountainStorageProfile[0].Id;
		}
		catch(Exception Ex)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An Error Occurred : ' + Ex.getMessage()));
		}
		
		return null;
	}
	
	public pagereference save() {
		
		if( !atLeastOneIronMountainStorageProfile )
		{
			saveNewProfile();
		}
		else
		{
			Savepoint sp = Database.setSavepoint();
			List<Storage_Profile__C> storageProfiles = new list<Storage_Profile__c>();
			for (Iron_Mountain_Storage_Profile__c imsp : ironMountainStorageProfiles )
				storageProfiles.addAll(imsp.Storage_Profiles__r);
			
			
			try{
				update storageProfiles;
				update ironMountainStorageProfiles;
				
				this.ironMountainStorageProfileMap = NULL;
				
				for (Iron_Mountain_Storage_Profile__c imsp : ironMountainStorageProfiles ){
					if (imsp.Whitespace_Cube__c < 0 || imsp.Whitespace_DB_R_Container__c < 0  || imsp.Whitespace_Tape__c < 0 ){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.Negative_Whitespace_Alert));
					}
				}
				
				
				
			} catch (Dmlexception ex) {
				ApexPages.addMessages(ex);
				Database.rollback(sp);
				
				this.ironMountainStorageProfileMap = NULL;
			}
		}	
		//Nulling this out to clear the values on page. 
		
		
		return null;
	}
	

	
	
}