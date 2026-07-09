@isTest
private class NF_GetKnowledgeLinkTest {
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
    
    static testMethod void testgetKnowledgeLink() {
        User u = createTestUser();
        system.runAs(u){
	     Knowledge__kav ka = new Knowledge__kav(  
            URLName = 'test-test',
            Title = 'test',
            Question__c ='test',
            Answer__c ='test article',
            language='en_US',
            IsVisibleInCsp =true,
            IsVisibleInPkb =true
                );
            NF_GetKnowledgeLink.Input input = new NF_GetKnowledgeLink.Input();
            input.objKnow = ka;
            List<NF_GetKnowledgeLink.Input> lst = new List<NF_GetKnowledgeLink.Input>{
                input
            };
        List<NF_GetKnowledgeLink.Output> out = NF_GetKnowledgeLink.getKnowledgeLink(lst);
        System.debug('out'+ out);
        Assert.areEqual('test', out[0].strKTitle, 'Record Title did not match');
        }
    }
}