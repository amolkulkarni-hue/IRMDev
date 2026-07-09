@isTest
private class BadgeAwardsControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            Alias = 'demous',
            Email = 'demousr123@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'demousr123',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'demousr123@example.com',
            Country = 'United States'
        );
        insert testUser;
        
        // Create test badges and badge assignments
        Badge__c testBadge = new Badge__c(
            Name = 'Test Badge',
            Badge_Image_URL__c = 'http://example.com/badge.png',
            Description__c = 'Test Badge Description'
        );
        insert testBadge;

        Badge_Assignments__c badgeAssignment1 = new Badge_Assignments__c(
            User__c = testUser.Id,
            Badge__c = testBadge.Id,
            Confetti_Show__c = true
        );
        Badge_Assignments__c badgeAssignment2 = new Badge_Assignments__c(
            User__c = testUser.Id,
            Badge__c = testBadge.Id,
            Confetti_Show__c = true
        );
        insert badgeAssignment1;
        insert badgeAssignment2;
    }

    @isTest
    static void testGetBadgeAwardsForCurrentUser() {
        // Retrieve test user
        User testUser = [SELECT Id FROM User WHERE UserName = 'demousr123@example.com' LIMIT 1];
        
        // Test the getBadgeAwardsForCurrentUser method
        Test.startTest();
        List<Badge_Assignments__c> results = BadgeAwardsController.getBadgeAwardsForCurrentUser(testUser.Id);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(2, results.size(), 'Expected 1 active badge assignment');
        System.assertEquals('Test Badge', results[0].Badge__r.Name, 'Badge name should match');
        System.assertEquals('http://example.com/badge.png', results[0].Badge__r.Badge_Image_URL__c, 'Badge image URL should match');
        System.assertEquals('Test Badge Description', results[0].Badge__r.Description__c, 'Badge description should match');
        System.assertEquals(testUser.Id, results[0].User__c, 'User Id should match');
        System.assertEquals(true, results[0].Confetti_Show__c, 'Confetti_Show__c should match');
    }

    @isTest
    static void testUpdateConfettiShowField() {
        // Retrieve test user
        User testUser = [SELECT Id FROM User WHERE UserName = 'demousr123@example.com' LIMIT 1];
        
        // Test the updateConfettiShowField method
        Test.startTest();
        BadgeAwardsController.updateConfettiShowField(testUser.Id);
        Test.stopTest();
        
        // Verify that Confetti_Show__c is updated to false for active badges
        List<Badge_Assignments__c> updatedBadges = [SELECT Id, Confetti_Show__c 
                                                    FROM Badge_Assignments__c 
                                                    WHERE User__c = :testUser.Id
                                                    AND Badge_Expiry__c > TODAY];
        
        for (Badge_Assignments__c badge : updatedBadges) {
            System.assertEquals(false, badge.Confetti_Show__c, 'Confetti_Show__c should be false');
        }
    }
}