@isTest
private class KnowledgeBaseSearch_Test {
    
    
       

 
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
    static testMethod void testSOSL() {
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
        insert ka; 
        Knowledge__kav kav = [SELECT KnowledgeArticleId,PublishStatus  FROM Knowledge__kav WHERE Id = :ka.Id ];
        KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId,true );   
        
        system.debug('ka  ' + kav.PublishStatus);
         Knowledge__kav kav1 = [SELECT Id,KnowledgeArticleId,PublishStatus  FROM Knowledge__kav WHERE Id = :kav.Id ];
          system.debug('ka  ' + kav1.PublishStatus);      
          
        
         KnowledgeBaseSearch.FAQSearchInput input = new KnowledgeBaseSearch.FAQSearchInput();
         input.sKeyword = 'test';
         input.Lang ='en_US';
             system.debug('input.sKeyword...............'+input.sKeyword);
         
       List <KnowledgeBaseSearch.FAQSearchInput> searchkeyword =   new list<KnowledgeBaseSearch.FAQSearchInput>();
       searchkeyword.add(input);
        
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = kav1.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List < List < Knowledge__kav > > searchResults = KnowledgeBaseSearch.getKnowledgeBase( searchkeyword ); 
         
        }
    }

}