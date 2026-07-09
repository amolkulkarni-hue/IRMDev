public without sharing class GuestArticleVoteController {
    @AuraEnabled
    public static Boolean existsVoteResult(String articleVersionId, String guestUserId){
        
        Knowledge__kav knObj=  [select Id,UrlName from Knowledge__kav where urlname=:articleVersionId limit 1];
            
        Integer voteCount = [
            SELECT COUNT()
            FROM GuestArticleVote__c
            WHERE Knowledge__c = :knObj.id AND GuestUserId__c = :guestUserId
        ];
        system.debug('voteCount'+voteCount);
        return (voteCount > 0);
    }

    @AuraEnabled
    public static void vote(String articleVersionId, String guestUserId, Boolean isUpvoted){
        Knowledge__kav knObj=  [select Id,UrlName from Knowledge__kav where urlname=:articleVersionId limit 1];
		System.debug('Kav List---'+knObj);
        insert new GuestArticleVote__c(
            Knowledge__c  = knObj.Id,
            GuestUserId__c = guestUserId,
            IsUpvoted__c = isUpvoted
        );
    }
}