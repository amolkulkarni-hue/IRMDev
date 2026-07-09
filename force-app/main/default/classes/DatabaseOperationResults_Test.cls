@IsTest
private class DatabaseOperationResults_Test {

    @IsTest
    static void testSaveResultSuccess() {
        // Create a dummy list of accounts to simulate a successful save operation
        List<Account> accountsToInsert = new List<Account>();
        accountsToInsert.add(new Account(Name = 'Test Account Save 1'));
        accountsToInsert.add(new Account(Name = 'Test Account Save 2'));

        // Perform a DML operation and capture the SaveResult
        List<Database.SaveResult> saveResults = Database.insert(accountsToInsert, false); // false for partial success to allow testing errors if needed

        // Instantiate DatabaseOperationResults with SaveResult
        DatabaseOperationResults results = new DatabaseOperationResults(saveResults);

        // Assertions for SaveResult
        System.assertEquals(2, results.size(), 'Size should be 2 for SaveResult.');
        System.assert(results.isSuccess(0), 'First save should be successful.');
        System.assert(results.isSuccess(1), 'Second save should be successful.');
        System.assert(results.getErrors(0).isEmpty(), 'No errors expected for successful save.');
    }

    @IsTest
    static void testSaveResultPartialSuccessAndError() {
        // Create a dummy list of accounts, one with an invalid name to cause an error
        List<Account> accountsToInsert = new List<Account>();
        accountsToInsert.add(new Account(Name = 'Test Account Success'));
        accountsToInsert.add(new Account(Name = null)); // This will cause an error

        // Perform a DML operation with partial success allowed
        List<Database.SaveResult> saveResults = Database.insert(accountsToInsert, false);

        // Instantiate DatabaseOperationResults with SaveResult
        DatabaseOperationResults results = new DatabaseOperationResults(saveResults);

        // Assertions for SaveResult with error
        System.assertEquals(2, results.size(), 'Size should be 2 for SaveResult.');
        System.assert(results.isSuccess(0), 'First save should be successful.');
        System.assert(!results.isSuccess(1), 'Second save should fail due to null name.');
        System.assert(results.getErrors(0).isEmpty(), 'No errors expected for successful save.');
        System.assert(!results.getErrors(1).isEmpty(), 'Errors expected for failed save.');
		System.assertEquals(System.StatusCode.REQUIRED_FIELD_MISSING, results.getErrors(1)[0].getStatusCode(), 'Expected REQUIRED_FIELD_MISSING error.');
    }

    @IsTest
    static void testUpsertResultSuccess() {
        // Create a dummy list of accounts for upsert
        List<Account> accountsToUpsert = new List<Account>();
        accountsToUpsert.add(new Account(Name = 'Test Account Upsert 1', CountryParentIDText__c = 'EXT001')); // Assuming an external ID field
        accountsToUpsert.add(new Account(Name = 'Test Account Upsert 2', CountryParentIDText__c = 'EXT002'));

        // Perform an upsert operation
        List<Database.UpsertResult> upsertResults = Database.upsert(accountsToUpsert, Account.Fields.CountryParentIDText__c, false);

        // Instantiate DatabaseOperationResults with UpsertResult
        DatabaseOperationResults results = new DatabaseOperationResults(upsertResults);

        // Assertions for UpsertResult
        System.assertEquals(2, results.size(), 'Size should be 2 for UpsertResult.');
        System.assert(results.isSuccess(0), 'First upsert should be successful.');
        System.assert(results.isSuccess(1), 'Second upsert should be successful.');
        System.assert(results.getErrors(0).isEmpty(), 'No errors expected for successful upsert.');
    }

    @IsTest
    static void testUpsertResultWithError() {
        // Create a dummy list of accounts for upsert, one with an invalid external ID (if applicable) or other error
        List<Account> accountsToUpsert = new List<Account>();
        accountsToUpsert.add(new Account(Name = 'Test Account Upsert Success', CountryParentIDText__c = 'EXT003'));
        accountsToUpsert.add(new Account(Name = 'Test Account Upsert Error', CountryParentIDText__c = null)); // Assuming external ID is required or unique

        // Perform an upsert operation with partial success allowed
        List<Database.UpsertResult> upsertResults = Database.upsert(accountsToUpsert, Account.Fields.CountryParentIDText__c, false);

        // Instantiate DatabaseOperationResults with UpsertResult
        DatabaseOperationResults results = new DatabaseOperationResults(upsertResults);

        // Assertions for UpsertResult with error
        System.assertEquals(2, results.size(), 'Size should be 2 for UpsertResult.');
        System.assert(results.isSuccess(0), 'First upsert should be successful.');
        System.assert(!results.isSuccess(1), 'Second upsert should fail.');
        System.assert(results.getErrors(0).isEmpty(), 'No errors expected for successful upsert.');
        System.assert(!results.getErrors(1).isEmpty(), 'Errors expected for failed upsert.');
    }

    @IsTest
    static void testDeleteResultSuccess() {
        // Insert accounts to delete
        List<Account> accountsToDelete = new List<Account>();
        accountsToDelete.add(new Account(Name = 'Test Account Delete 1'));
        accountsToDelete.add(new Account(Name = 'Test Account Delete 2'));
        insert accountsToDelete;

        // Perform a delete operation
        List<Database.DeleteResult> deleteResults = Database.delete(accountsToDelete, false);

        // Instantiate DatabaseOperationResults with DeleteResult
        DatabaseOperationResults results = new DatabaseOperationResults(deleteResults);

        // Assertions for DeleteResult
        System.assertEquals(2, results.size(), 'Size should be 2 for DeleteResult.');
        System.assert(results.isSuccess(0), 'First delete should be successful.');
        System.assert(results.isSuccess(1), 'Second delete should be successful.');
        System.assert(results.getErrors(0).isEmpty(), 'No errors expected for successful delete.');
    }

    @IsTest
    static void testDeleteResultWithError() {
        // Insert an account to delete
        Account accToDelete = new Account(Name = 'Test Account Delete Error');
        insert accToDelete;

        // Create a dummy list, one valid ID and one invalid ID for delete (to simulate error)
        List<Id> idsToDelete = new List<Id>();
        idsToDelete.add(accToDelete.Id);
        idsToDelete.add('001000000000000AAA'); // Invalid ID

        // Perform a delete operation with partial success allowed
        List<Database.DeleteResult> deleteResults = Database.delete(idsToDelete, false);

        // Instantiate DatabaseOperationResults with DeleteResult
        DatabaseOperationResults results = new DatabaseOperationResults(deleteResults);

        // Assertions for DeleteResult with error
        System.assertEquals(2, results.size(), 'Size should be 2 for DeleteResult.');
        System.assert(results.isSuccess(0), 'First delete should be successful.');
        System.assert(!results.isSuccess(1), 'Second delete should fail due to invalid ID.');
        System.assert(results.getErrors(0).isEmpty(), 'No errors expected for successful delete.');
        System.assert(!results.getErrors(1).isEmpty(), 'Errors expected for failed delete.');
        System.assertEquals(System.StatusCode.INVALID_CROSS_REFERENCE_KEY, results.getErrors(1)[0].getStatusCode(), 'Expected INVALID_CROSS_REFERENCE_KEY error for non-existent ID.');
	}

    @IsTest
    static void testInvalidObjectConstructor() {
        // Test with an object that is not a recognized result type
        List<String> stringList = new List<String>{'a', 'b'};
        DatabaseOperationResults results = new DatabaseOperationResults(stringList);

        // Assert that the instanceType is not set, and methods return defaults
        System.assertEquals(-1, results.size(), 'Size should be -1 for invalid object type.');
        System.assert(!results.isSuccess(0), 'isSuccess should be false for invalid object type.');
        System.assert(results.getErrors(0) == null, 'getErrors should be null for invalid object type.');
    }
}