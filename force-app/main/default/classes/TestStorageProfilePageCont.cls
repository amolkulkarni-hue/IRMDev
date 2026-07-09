@isTest
private class TestStorageProfilePageCont 
{
	static final Integer NUM_OF_IM_STORAGE_PROFILES = 2;
    	

    
    static Account IMGA_Account;
    static List<Iron_Mountain_Storage_Profile__c> testIMStorageProfiles;
    static List<Competitor__c> testCompetitors;
    static List<Storage_Profile__c> testStorageProfiles;
    
	static StorageProfilePageCont setupPage( Account testAccount )
	{
		ApexPages.StandardController sc = new ApexPages.StandardController ( testAccount );
		StorageProfilePageCont spCont = new StorageProfilePageCont();
		spCont.accountID = testAccount.id;
		spCont.returnID = testAccount.id;
    	return spCont;
	}
	
	static void setup()
	{
		setup(true);
	}
	
	static void setup( boolean createProfilesAndCompetitors )
	{
		IMGA_Account = Testingutils.createAccounts( 1, false )[0];
    	IMGA_Account.RecordTypeId = Testingutils.IMGA_ACCOUNT_RECORD_TYPE.Id;
    	IMGA_Account.IM_Hierarchy_Level__c = 'IM Group (IMGA)';	
    	insert IMGA_Account;
    	
    	if( createProfilesAndCompetitors )
    	{
	    	testIMStorageProfiles = TestingUtils.createIronMountainStorageProfiles( NUM_OF_IM_STORAGE_PROFILES, IMGA_Account.Id, 0, 0, 0,  true );
	    	testCompetitors = TestingUtils.createCompetitors( NUM_OF_IM_STORAGE_PROFILES, 'Test Comp', true );
	    	testStorageProfiles = new List<Storage_Profile__c>();
	    	
	    	for( Integer i = 0; i < NUM_OF_IM_STORAGE_PROFILES; i++ )
	    	{
	    		testStorageProfiles.add( TestingUtils.createStorageProfile( testIMStorageProfiles[i].Id, IMGA_Account.Id, testCompetitors[i].Id, 0, 0, 0, false ) );
	    	}
	    	insert testStorageProfiles;
    	}
	}
	
	static testMethod void testSaveNegativeTapeWhitespace()
	{
		final Integer SAMPLE_QUANTITY = 50;
		
		setup();
    	setupPage( IMGA_Account );
    	
		StorageProfilePageCont controller = setupPage( IMGA_Account );
		
    	for( Iron_Mountain_Storage_Profile__c aIMStorageProfile : controller.ironMountainStorageProfileMap.values() )
    	{
    		aIMStorageProfile.Profiled_Quantity_Tape__c = SAMPLE_QUANTITY;
    		aIMStorageProfile.IM_Quantity_Tape__c = SAMPLE_QUANTITY;
    		
    		Storage_Profile__c relatedStorageProfile = aIMStorageProfile.Storage_Profiles__r[0];
    		relatedStorageProfile.Quantity_Tape__c = 1;
    	}
    	
    	Test.startTest();
    		controller.save();
    	Test.stopTest();
    	
    	System.assert(ApexPages.hasMessages(),'There should be an error');
    	System.assert(TestingUtils.pageMessageContains(System.Label.Negative_Whitespace_Alert),'We expect to show a warning message when the whitespace calculates to less than 0');		
	}

	static testMethod void testViewPageWithEmptyProfile()
	{
		final boolean createProfileAndCompetitors = false;
		
		setup( createProfileAndCompetitors );
    	
    	Test.startTest();
    		StorageProfilePageCont controller = setupPage( IMGA_Account );
    	Test.stopTest();
    	
    	System.assert(!controller.atLeastOneIronMountainStorageProfile,'There should be no profiles');
    	System.assertEquals(IMGA_Account.ID, controller.emptyIronMountainStorageProfile[0].Account__c,'The blank profile should be tied to the correct account');
    	
    	String expectedPage = Page.StorageProfileNew.getUrl();
    	String expectedRetUrl = 'retURL=%2F' + IMGA_Account.Id;
    	String expectedAcctParam = StorageProfileContExt.ACCOUNT_ID_PARAM+'=' + IMGA_Account.Id;
    	
    	System.assertEquals(IMGA_Account.ID, controller.emptyIronMountainStorageProfile[0].Account__c,'The blank profile should be tied to the correct account');
    	System.assert(controller.createNewCompetitorProfile.contains( expectedPage ),'The correct page should be referenced');
    	System.assert(controller.createNewCompetitorProfile.contains( expectedRetUrl ),'The correct return id should be in the page reference');
    	System.assert(controller.createNewCompetitorProfile.contains( expectedAcctParam ),'The correct accountid should be in the page reference');
    	
	}

	static testMethod void testSaveNewProfilePageWithEmptyProfile()
	{
		testSaveProfilePage( true );
	}	
	
	static testMethod void testSaveProfilePageWithEmptyProfile()
	{
		testSaveProfilePage( false );
	}
		
	static void testSaveProfilePage( boolean saveNew )
	{
		final boolean createProfileAndCompetitors = false;
		
		setup( createProfileAndCompetitors );
    	
    	Test.startTest();
    		StorageProfilePageCont controller = setupPage( IMGA_Account );
    		
    		if( saveNew )
    			controller.saveNewProfile();
    		else
    			controller.save();
    			
    	Test.stopTest();
    	
    	List<Iron_Mountain_Storage_Profile__c>profilesCreated = [Select Id, Account__c from Iron_Mountain_Storage_Profile__c];
    	
    	System.assertEquals(1, profilesCreated.size(), 'The Empty profile should have been created' );
    	System.assertEquals(profilesCreated[0].Id, controller.ironProfileID, 'The Empty profile should have been created and saved in the controllers variable' );
	}
	
    static testMethod void testSave()
    {
	    final Decimal PROFILE_TAPE_QUANTITY = 100;
	    final Decimal PROFILE_CUBE_QUANTITY = 200;
	    final Decimal PROFILE_DBnR_QUANTITY = 300;
	    final Decimal IM_TAPE_QUANTITY = 40;
	    final Decimal IM_CUBE_QUANTITY = 50;
	    final Decimal IM_DBnR_QUANTITY = 60;
	    	
	    final Decimal SP_QUANTITY = 60;
    
    	setup();
    	setupPage( IMGA_Account );
    	
		StorageProfilePageCont controller = setupPage( IMGA_Account );
		
    	for( Iron_Mountain_Storage_Profile__c aIMStorageProfile : controller.ironMountainStorageProfileMap.values() )
    	{
    		aIMStorageProfile.Profiled_Quantity_Tape__c = PROFILE_TAPE_QUANTITY;
    		aIMStorageProfile.Profiled_Quantity_Cube__c = PROFILE_CUBE_QUANTITY;
    		aIMStorageProfile.Profiled_Quantity_DB_R_Container__c = PROFILE_DBnR_QUANTITY;
    		aIMStorageProfile.IM_Quantity_Tape__c = IM_TAPE_QUANTITY;
    		aIMStorageProfile.IM_Quantity_Cube__c = IM_CUBE_QUANTITY;
    		aIMStorageProfile.IM_Quantity_DB_R_Container__c = IM_DBnR_QUANTITY;
    		
    		Storage_Profile__c relatedStorageProfile = aIMStorageProfile.Storage_Profiles__r[0];
    		relatedStorageProfile.Quantity__c = SP_QUANTITY;
    	}
    	 
    	Test.startTest();
			controller.save();
		Test.stopTest();
		
		System.assertEquals( testIMStorageProfiles.size(), controller.ironMountainStorageProfileMap.size(), 'The ironMountainStorageProfileMap in the controller should have all the imStorageProfiles related to the account' );
    	System.assert( controller.ironMountainStorageProfileMap.keySet().containsAll( Pluck.ids( testIMStorageProfiles ) ), 'All the expected im storage profiles should be included in the map' );
    	System.assert( Pluck.ids( testIMStorageProfiles ).containsAll( controller.ironMountainStorageProfileMap.keySet() ), 'Only the expected im storage profiles should be included in the map' );
    	
    	for( Iron_Mountain_Storage_Profile__c aIMStorageProfile : controller.ironMountainStorageProfileMap.values() )
    	{
			System.assertEquals( 1, aIMStorageProfile.Storage_Profiles__r.size(), 'The ironMountainStorageProfileMap in the controller should have exepcted number of StorageProfiles related to the imstorageProfile' );
    	}
    	
		Map<Id, Iron_Mountain_Storage_Profile__c> actualMap = new Map<Id, Iron_Mountain_Storage_Profile__c> ( 
													[ SELECT Whitespace_Tape__c, Whitespace_DB_R_Container__c, Whitespace_Cube__c, Profiled_Quantity_Tape__c, 
													Profiled_Quantity_DB_R_Container__c, Profiled_Quantity_Cube__c, Name, IM_Quantity_Tape__c, IM_Quantity_DB_R_Container__c, IM_Quantity_Cube__c, 
													( SELECT Name, Quantity__c FROM Storage_Profiles__r ) 
													FROM Iron_Mountain_Storage_Profile__c WHERE Id IN : testIMStorageProfiles ] );
													
		System.assertEquals( testIMStorageProfiles.size(), actualMap.size(), 'The actual map should have all the expected imStorageProfiles' );
		
		for( Iron_Mountain_Storage_Profile__c aIMStorageProfile : actualMap.values() )
		{
			System.assertEquals( PROFILE_TAPE_QUANTITY, aIMStorageProfile.Profiled_Quantity_Tape__c, 'All the fields modified on the page should get updated with their respective values' );
			System.assertEquals( PROFILE_CUBE_QUANTITY, aIMStorageProfile.Profiled_Quantity_Cube__c, 'All the fields modified on the page should get updated with their respective values' );
			System.assertEquals( PROFILE_DBnR_QUANTITY, aIMStorageProfile.Profiled_Quantity_DB_R_Container__c, 'All the fields modified on the page should get updated with their respective values' );
			System.assertEquals( IM_TAPE_QUANTITY, aIMStorageProfile.IM_Quantity_Tape__c, 'All the fields modified on the page should get updated with their respective values' );
			System.assertEquals( IM_CUBE_QUANTITY, aIMStorageProfile.IM_Quantity_Cube__c, 'All the fields modified on the page should get updated with their respective values' );
			System.assertEquals( IM_DBnR_QUANTITY, aIMStorageProfile.IM_Quantity_DB_R_Container__c, 'All the fields modified on the page should get updated with their respective values' );
			
			Storage_Profile__c actualStorageProfile = aIMStorageProfile.Storage_Profiles__r[0];
			System.assertEquals( SP_QUANTITY, actualStorageProfile.Quantity__c, 'All the fields modified on the page should get updated with their respective values' );
		}												
		
    }
    
}