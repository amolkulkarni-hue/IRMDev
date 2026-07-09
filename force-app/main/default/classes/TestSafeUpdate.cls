@isTest
public class TestSafeUpdate {
	@TestVisible static Set<ID> preexistingGroups;
     
    static
    {
    	preexistingGroups = new Set<ID>();
	    for(Group g : [Select ID From Group]) 
	    {
	    	preexistingGroups.add(g.ID);
	    } 
    }
	
	public static testMethod void testValidationAndProcessing_IgnoreRepeatItems_UponFailure()
	{
		Integer howMany = 50;
		List<Group> groups = TestSafeDML.createGroups('First Group', howMany);
		insert groups;
		
		SafeUpdate groupsForDML = new SafeUpdate();
		TestSafeDML.KeepTrackOfFailedItems trackGroup = new TestSafeDML.KeepTrackOfFailedItems();
		
		TestSafeDML.setNameOfGroups(groups,null);
		
		groupsForDML.queue(groups, trackGroup);
		groupsForDML.queue(groups, trackGroup);
		
		Test.startTest();
			groupsForDML.doDML();
		Test.stopTest();
		
		System.assertEquals(howMany,trackGroup.howManyIdsValidated,'Every object should be validated. There is no validation if an object is already validated');
		System.assertEquals(howMany,trackGroup.howManyIdsForFailedObjects, 'Every failed object should be validated');
	}
	
	public static testMethod void testValidationAndProcessing_IgnoreRepeatItems_UponSucess()
	{
		Integer howMany = 50;
		List<Group> groups = TestSafeDML.createGroups('First Group', howMany);
		insert groups;
		
		SafeUpdate groupsForDML = new SafeUpdate();
		TestSafeDML.KeepTrackOfFailedItems trackGroup = new TestSafeDML.KeepTrackOfFailedItems();
		
		groupsForDML.queue(groups, trackGroup);
		String newName = 'New Name';
		TestSafeDML.setNameOfGroups(groups,newName);
		groupsForDML.queue(groups, trackGroup);
		
		Test.startTest();
			groupsForDML.doDML();
		Test.stopTest();
		
		System.assertEquals(50,groupsForDML.getQueueSize(),'We expect to get the right number of unique objects');
		System.assertEquals(howMany,trackGroup.howManyIdsValidated,'Every object should be validated. There is no validation if an object is already validated');
		System.assertEquals(0,trackGroup.howManyIdsForFailedObjects, 'There are no failed objects');
		
		List<Group> groupsQueried = [Select ID From Group Where Name=:newName AND ID NOT IN:preexistingGroups];
		System.assertEquals(howMany,groupsQueried.size(),'We expect the update function to work');
	}
	
	public static testMethod void testValidationAndProcessing_NoErrors()
	{
		Integer howManyFirstGroup = 55;
		Integer howManySecondGroup = 11;
		
		List<Group> firstGroup = TestSafeDML.createGroups('First Group', howManyFirstGroup);
		List<Group> secondGroup = TestSafeDML.createGroups('Second Group', howManySecondGroup);
		List<Group> allGroups = new List<Group>();
		allGroups.addAll(firstGroup);
		allGroups.addAll(secondGroup);
		insert allGroups;
		
		SafeUpdate groupsForDML = new SafeUpdate();
		TestSafeDML.KeepTrackOfFailedItems trackGroupOne = new TestSafeDML.KeepTrackOfFailedItems();
		TestSafeDML.KeepTrackOfFailedItems trackGroupTwo = new TestSafeDML.KeepTrackOfFailedItems();
		
		groupsForDML.queue(firstGroup, trackGroupOne);
		groupsForDML.queue(secondGroup, trackGroupTwo);
		System.assertEquals(allGroups.size(),groupsForDML.getQueueSize(),'We expect to get the right number of unique objects');
		
		Test.startTest();
			groupsForDML.doDML();
		Test.stopTest();
		
		System.assertEquals(howManyFirstGroup,trackGroupOne.howManyIdsValidated,'Every object should be validated');
		System.assertEquals(0,trackGroupOne.howManyIdsForFailedObjects, 'There are no objects that should fail to update');
		System.assertEquals(howManySecondGroup,trackGroupTwo.howManyIdsValidated, 'Every object should be validated');
		System.assertEquals(0,trackGroupTwo.howManyIdsForFailedObjects, 'There are no objects that should fail to update');
	}
	
	public static testMethod void testUpdateAllowPartialSuccess()
	{
		Integer howManyFirstGroup = 55;
		Integer howManySecondGroup = 11;
		String oldNameForFirstGroup = 'First Group';
		String newName = 'New Name';
		
		List<Group> firstGroup = TestSafeDML.createGroups(oldNameForFirstGroup, howManyFirstGroup);
		List<Group> secondGroup = TestSafeDML.createGroups('Second Group', howManySecondGroup);
		
		List<Group> allGroups = new List<Group>();
		allGroups.addAll(firstGroup);
		allGroups.addAll(secondGroup);
		
		insert allGroups;
		
		SafeDML groupsForDML = new SafeUpdate();
		TestSafeDML.KeepTrackOfFailedItems trackGroupOne = new TestSafeDML.KeepTrackOfFailedItems();
		TestSafeDML.KeepTrackOfFailedItems trackGroupTwo = new TestSafeDML.KeepTrackOfFailedItems();
		
		TestSafeDML.setNameOfGroups(firstGroup,null);
		TestSafeDML.setNameOfGroups(secondGroup,newName);
		
		groupsForDML.queue(firstGroup, trackGroupOne);
		groupsForDML.queue(secondGroup, trackGroupTwo);
		
		Test.startTest();
			groupsForDML.doDML(false);
		Test.stopTest();
		
		secondGroup = [Select ID From Group Where ID NOT IN: preexistingGroups AND Name=:newName];
		System.assertEquals(howManySecondGroup,secondGroup.size(),'We expect to update all groups that do not have errors');
		
		firstGroup = [Select ID From Group Where ID NOT IN: preexistingGroups AND Name=:oldNameForFirstGroup];
		System.assertEquals(howManyFirstGroup, firstGroup.size(), 'We do not expect to update any groups that have errors');
		
		System.assertEquals(howManyFirstGroup,trackGroupOne.howManyIdsValidated,'Every object should be validated');
		System.assertEquals(howManyFirstGroup,trackGroupOne.howManyIdsForFailedObjects, 'Every failed object should be processed for error handling');
		System.assertEquals(howManySecondGroup,trackGroupTwo.howManyIdsValidated, 'Every object should be validated');
		System.assertEquals(0,trackGroupTwo.howManyIdsForFailedObjects, 'There are no objects in the second group that should fail to update');
	}
	
	public static testMethod void testValidationAndProcessing_Errors()
	{
		Integer howManyFirstGroup = 55;
		Integer howManySecondGroup = 11;
		
		List<Group> firstGroup = TestSafeDML.createGroups('First Group', howManyFirstGroup);
		List<Group> secondGroup = TestSafeDML.createGroups('Second Group', howManySecondGroup);
		List<Group> allGroups = new List<Group>();
		allGroups.addAll(firstGroup);
		allGroups.addAll(secondGroup);
		insert allGroups;
		
		SafeUpdate groupsForDML = new SafeUpdate();
		TestSafeDML.KeepTrackOfFailedItems trackGroupOne = new TestSafeDML.KeepTrackOfFailedItems();
		TestSafeDML.KeepTrackOfFailedItems trackGroupTwo = new TestSafeDML.KeepTrackOfFailedItems();
		
		TestSafeDML.setNameOfGroups(allGroups,null);
		
		groupsForDML.queue(firstGroup, trackGroupOne);
		groupsForDML.queue(secondGroup, trackGroupTwo);
		
		Test.startTest();
			groupsForDML.doDML();
		Test.stopTest();
		
		System.assertEquals(howManyFirstGroup,trackGroupOne.howManyIdsValidated,'Every object should be validated');
		System.assertEquals(howManyFirstGroup,trackGroupOne.howManyIdsForFailedObjects, 'Every failed object should be processed for error');
		System.assertEquals(howManySecondGroup,trackGroupTwo.howManyIdsValidated, 'Every object should be validated');
		System.assertEquals(howManySecondGroup,trackGroupTwo.howManyIdsForFailedObjects, 'Every failed object should be processed for error');
		
	}
	
	public static testMethod void testSingleQueueAndUpdate_ErrorHandled()
	{
		Integer howMany = 10;
		List<Group> testGroups =TestSafeDML.createGroups('Test Group', howMany);
		insert testGroups;
		
		Map<ID, Group> triggerNewMap = new Map<ID, Group>(testGroups);
		
		SafeUpdate groupsForDML = new SafeUpdate();
		groupsForDML.queue(testGroups, new ErrorHandling.AddErrorsToTriggerNew(triggerNewMap));
		
		TestSafeDML.setNameOfGroups(testGroups,null);
		Test.startTest();
			groupsForDML.doDML();
		Test.stopTest();
		
		System.assert(ApexPages.hasMessages(),'The error should have been gracefully caught');
	}
	public static testMethod void testSingleQueueAndUpdate_ErrorsButNoErrorHandling()
	{
		Integer howMany = 10;
		List<Group> testGroups =TestSafeDML.createGroups('Test Group', howMany);
		insert testGroups;
		
		SafeUpdate groupsForDML = new SafeUpdate();
		groupsForDML.queue(testGroups, null);
		
		TestSafeDML.setNameOfGroups(testGroups,null);
		
		Test.startTest();
			try
			{
				groupsForDML.doDML();
				System.assert(false,'When there are no error handling specifications, the DML exception will not be caught');
			}
			catch(DMLException e)
			{
				
			}
		Test.stopTest();
	}
	
	public static testMethod void testSingleQueueAndUpdate()
	{
		final Integer howMany = 10;
		final String newName = 'Group Updated';
		
		List<Group> testGroups = TestSafeDML.createGroups('Test Group', howMany);
		insert testGroups;
		
		SafeUpdate groupsForDML = new SafeUpdate();
		groupsForDML.queue(testGroups, null);
		
		TestSafeDML.setNameOfGroups(testGroups,newName);
		
		Test.startTest();
			groupsForDML.doDML();
		Test.stopTest();
		
		List<Group> groupsQueried = [Select ID From Group Where Name=:newName AND ID NOT IN:preexistingGroups];
		System.assertEquals(howMany,groupsQueried.size(),'We expect the update function to work');
	}
	
}