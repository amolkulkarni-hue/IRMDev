@isTest
private class TestStorageProfileControllerExtension {

    static testMethod void PageCancelWithIM_Profile()
    {
    	
		Account IMGA_Account = Testingutils.createAccounts( 1, false )[0];
		IMGA_Account.RecordTypeId = Testingutils.IMGA_ACCOUNT_RECORD_TYPE.Id;
    	IMGA_Account.IM_Hierarchy_Level__c = 'IM Group (IMGA)';	
    	insert IMGA_Account;
    	
		Iron_Mountain_Storage_Profile__c testIMStorageProfile = TestingUtils.createIronMountainStorageProfiles( 1, IMGA_Account.Id, 0, 0, 0,  true )[0];
    	
    	Storage_Profile__c testStorageProfile =  new Storage_Profile__c(); 
    	
    	PageReference storageProfileCreationPage = Page.StorageProfileNew;
		storageProfileCreationPage.getParameters().put(StorageProfileContExt.ACCOUNT_ID_PARAM, IMGA_Account.Id);
		storageProfileCreationPage.getParameters().put(StorageProfileContExt.IM_PROFILE_ID_PARAM, testIMStorageProfile.Id);
		
    	Test.setCurrentPageReference( storageProfileCreationPage );
		
		ApexPages.StandardController sc = new ApexPages.StandardController ( testStorageProfile );
		
		Test.startTest();
			StorageProfileContExt spExt = new storageProfileContExt( sc );
			spExt.cancel();
		Test.stopTest();
		
		List<Iron_Mountain_Storage_Profile__c> testIMStorageProfiles = [Select id 
												 						from Iron_Mountain_Storage_Profile__c ];
		
		System.assertEquals(1, testIMStorageProfiles.size(), 'A storage profile should not have been deleted');
		
	}

	static testMethod void PageSaveWithOutIM_Profile()
    {
    	
		Account IMGA_Account = Testingutils.createAccounts( 1, false )[0];
		IMGA_Account.RecordTypeId = Testingutils.IMGA_ACCOUNT_RECORD_TYPE.Id;
    	IMGA_Account.IM_Hierarchy_Level__c = 'IM Group (IMGA)';	
    	insert IMGA_Account;
    	
    	Iron_Mountain_Storage_Profile__c testIMStorageProfile = TestingUtils.createIronMountainStorageProfiles( 1, IMGA_Account.Id, 0, 0, 0,  true )[0];
    	Storage_Profile__c testStorageProfile =  new Storage_Profile__c(); 
    	
    	PageReference storageProfileCreationPage = Page.StorageProfileNew;
		storageProfileCreationPage.getParameters().put(StorageProfileContExt.ACCOUNT_ID_PARAM, IMGA_Account.Id);
		storageProfileCreationPage.getParameters().put(StorageProfileContExt.IM_PROFILE_ID_PARAM, testIMStorageProfile.Id);
		storageProfileCreationPage.getParameters().put(StorageProfileContExt.NEW_IM_PROFILE_ID, 'true');
    	 
    	Test.setCurrentPageReference( storageProfileCreationPage );
		
		ApexPages.StandardController sc = new ApexPages.StandardController ( testStorageProfile );
		
		Test.startTest();
			StorageProfileContExt spExt = new storageProfileContExt( sc );
			spExt.cancel();
		Test.stopTest();
		
		List<Iron_Mountain_Storage_Profile__c> testIMStorageProfiles = [Select id
												 						from Iron_Mountain_Storage_Profile__c ];
		
		System.assertEquals(0, testIMStorageProfiles.size(), 'A storage profile should have been deleted');
		
	}

	static testMethod void PageSaveWithOutIM_ProfileERROR()
    {
    	
		Account IMGA_Account = Testingutils.createAccounts( 1, false )[0];
		IMGA_Account.RecordTypeId = Testingutils.IMGA_ACCOUNT_RECORD_TYPE.Id;
    	IMGA_Account.IM_Hierarchy_Level__c = 'IM Group (IMGA)';	
    	insert IMGA_Account;
    	
    	Iron_Mountain_Storage_Profile__c testIMStorageProfile = TestingUtils.createIronMountainStorageProfiles( 1, IMGA_Account.Id, 0, 0, 0,  true )[0];
    	Storage_Profile__c testStorageProfile =  new Storage_Profile__c(); 
    	
    	PageReference storageProfileCreationPage = Page.StorageProfileNew;
		storageProfileCreationPage.getParameters().put(StorageProfileContExt.ACCOUNT_ID_PARAM, IMGA_Account.Id);
		storageProfileCreationPage.getParameters().put(StorageProfileContExt.NEW_IM_PROFILE_ID, 'true');
    	 
    	Test.setCurrentPageReference( storageProfileCreationPage );
		
		ApexPages.StandardController sc = new ApexPages.StandardController ( testStorageProfile );
		
		Test.startTest();
			StorageProfileContExt spExt = new storageProfileContExt( sc );
			spExt.cancel();
		Test.stopTest();
		
		List<Iron_Mountain_Storage_Profile__c> testIMStorageProfiles = [Select id
												 						from Iron_Mountain_Storage_Profile__c ];
		
		System.assert(TestingUtils.pageMessageContains( StorageProfileContExt.ERROR ), 'If an error occurs, it should be displayed on the page');
		
	}
	
    
}