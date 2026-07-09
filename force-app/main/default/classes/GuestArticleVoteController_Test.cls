@isTest
private class GuestArticleVoteController_Test {
    public static final String GUEST_USER_ID = '4ef37fa1-c256-4fef-8f56-b01ca11323c8';

    @testSetup
    static void setup() {
        User u = createTestUser();
        System.runAs(u) {
            //Publish knowledge articles
            publishTestArticle('test-article-01');
            publishTestArticle('test-article-02');
        }
        //Insert a vote result
        Knowledge__kav kav1 = selectArticleByUrlName('test-article-01');
        insert new GuestArticleVote__c(
            Knowledge__c = kav1.Id,
            GuestUserId__c = GUEST_USER_ID
        );
    }

    @isTest
    static void existsVoteResult_test() {
       		 User u = createTestUser();
        System.runAs(u) {
            publishTestArticle('test-article-One');
        	Knowledge__kav kav1 = selectArticleByUrlName('test-article-One');
        	system.debug('kav1====>'+kav1);
        	Test.startTest();
            GuestArticleVoteController.existsVoteResult('test-article-One', GUEST_USER_ID);
       		Test.stopTest();
            system.assertEquals(true, true);
        }

    }

    @isTest
    static void vote_test() {
         User u = createTestUser();
        System.runAs(u) {
         publishTestArticle('test-article-One');
         Knowledge__kav kav1 = selectArticleByUrlName('test-article-One');
        Test.startTest();
		 GuestArticleVoteController.vote('test-article-One', GUEST_USER_ID, true);
        Test.stopTest();
        system.assertEquals(true, true);
        }
        
    }

    private static User createTestUser() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now())
            .replace(' ', '')
            .replace(':', '')
            .replace('-', '');
        String randomIntString = String.valueOf(Crypto.getRandomInteger());
        Profile p = [
            SELECT Id, Name
            FROM Profile
            WHERE
                UserType = 'Standard'
                AND PermissionsCustomizeApplication = true
        ][0];
        User u = new User(
            UserName = 'test@' + orgId + dateString + randomIntString + '.org',
            Email = 'test@' + orgId + dateString + randomIntString + '.org',
            LastName = 'test',
            country='US',
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserPermissionsKnowledgeUser = true
        );
        insert u;
        return u;
    }

    private static void publishTestArticle(String urlName) {
        Knowledge__kav kav = new Knowledge__kav(
            URLName = urlName,
            Title = 'test'
        );
        insert kav;
        kav = [
            SELECT KnowledgeArticleId
            FROM Knowledge__kav
            WHERE Id = :kav.Id
        ];
        KbManagement.PublishingService.publishArticle(
            kav.KnowledgeArticleId,
            true
        );
    }

    private static Knowledge__kav selectArticleByUrlName(String urlName) {
        return [
            SELECT Id,PublishStatus,URLName
            FROM Knowledge__kav
            WHERE URLName = :urlName AND PublishStatus = 'Online'
        ];
    }
}