public with sharing class StorageProfileContExt {
	
	public static final String ACCOUNT_ID_PARAM = 'accountID';
	public static final String IM_PROFILE_ID_PARAM = 'improfID';
	public static final String NEW_IM_PROFILE_ID = 'createNew';
	public static final String ERROR = 'Error Occurred :';
	
	private Boolean justCreatedIMStorage = false;
	private Storage_Profile__c profile;
	 
	private ApexPages.StandardController controller;
	  
	public StorageProfileContExt(ApexPages.StandardController stdController) {
		controller = stdController;
		profile = (Storage_Profile__c)controller.getRecord();
		profile.customer__c = ApexPages.currentPage().getParameters().get(ACCOUNT_ID_PARAM);
		profile.Iron_Mountain_storage_profile__c = ApexPages.currentPage().getParameters().get(IM_PROFILE_ID_PARAM);
		justCreatedIMStorage = ApexPages.currentPage().getParameters().get(NEW_IM_PROFILE_ID) == 'true';
	}
	
	public PageReference cancel()
	{
		if( justCreatedIMStorage )
		{
			try{
				delete new Iron_Mountain_Storage_Profile__c( Id = profile.Iron_Mountain_storage_profile__c);
			}
			catch(Exception ex)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERROR + ex.getMessage()));
				return null;
			}
		}
		return controller.cancel();
	}
	
	
}