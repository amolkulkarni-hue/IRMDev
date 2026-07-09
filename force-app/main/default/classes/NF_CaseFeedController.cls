/**
* Luis Rocha
* Custom Feed for cases, and Feed Tracking.
* This class manages Feed Tracking data to keep track of created Case Feed items
* and to associate created Chatter posts with corresponding Case records.
*/
public class NF_CaseFeedController {
    private static List<String> internalUserTypes = new List<String>{'Standard', 'CsnOnly'};

    @AuraEnabled 
    public static List<Case> queryCases(String Id) {
        String queryVal = 'SELECT Id,CaseNumber,Subject,Status FROM Case WHERE Id =: Id';
        return Database.query(queryVal);
    }

    @AuraEnabled
    public static Map<String, Boolean> getCaseFeedUserTypes(String Id) {
        Set<String> userIdSet = new Set<String>();
        Map<String, Boolean> caseFeedIdToUserTypeMap = new Map<String, Boolean>();
        Map<String, String> userIdToUserTypeMap = new Map<String, String>();
        String queryCaseFeed =
                'SELECT Body,CommentCount,CreatedById,createdBy.Name,CreatedDate,Id,IsDeleted,LastModifiedDate,LikeCount,ParentId,Title,Type FROM CaseFeed WHERE ParentId =: Id';
        List<CaseFeed> lstCaseFeed = Database.query(queryCaseFeed);
        for(CaseFeed c: lstCaseFeed){
            userIdSet.add(c.CreatedById);
        }
        List<User> users = [SELECT Id,UserType FROM User WHERE CreatedById IN: userIdSet];
        for(User user: users){
            userIdToUserTypeMap.put(user.Id, user.UserType);
        }
        for(CaseFeed c: lstCaseFeed){
            if(internalUserTypes.contains(userIdToUserTypeMap.get(c.CreatedById))){
                caseFeedIdToUserTypeMap.put(c.Id, true);
            }
            else{
                caseFeedIdToUserTypeMap.put(c.Id, false);
            }
        }
        return caseFeedIdToUserTypeMap;
    }

    @AuraEnabled
    public static Map<String, CaseFeed> getCaseChatter(String Id) {
        Set<String> userIdSet = new Set<String>();
        Map<String, CaseFeed> userTypeToCaseFeed = new Map<String, CaseFeed>();
        Map<String, String> userIdToUserTypeMap = new Map<String, String>();
        Map<String, CaseFeed> feedIdToFeedMap = new Map<String, CaseFeed>();
        String queryCaseFeed =
            'SELECT Body,CommentCount,CreatedById,createdBy.Name,CreatedDate,Id,IsDeleted,LastModifiedDate,LikeCount,ParentId,Title,Type FROM CaseFeed WHERE ParentId =: Id AND Type=\'TextPost\'';
        System.debug(queryCaseFeed);
        List<CaseFeed> lstCaseFeed = Database.query(queryCaseFeed);
        for(CaseFeed c: lstCaseFeed){
            userIdSet.add(c.CreatedById);
            feedIdToFeedMap.put(c.Id, c);
        }
        List<User> users = [SELECT Id,UserType FROM User WHERE CreatedById IN: userIdSet];
        for(User user: users){
            userIdToUserTypeMap.put(user.Id, user.UserType);
        }
        for(CaseFeed c: lstCaseFeed){
            userTypeToCaseFeed.put(userIdToUserTypeMap.get(c.CreatedById), c);
        }
        return feedIdToFeedMap;
    }

    @AuraEnabled
    public static Boolean submitCaseFeed(String jsonString) {
        Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        String cObjJson = JSON.serialize(cObjMap.get('records'));
        List<Object> objList = (List<Object>)JSON.deserializeUntyped(cObjJson);
        Map<String, Object> row = (Map<String, Object>)objList[0];
        System.debug('row: ' + row);
        FeedItem item = new FeedItem();
        item.Body = String.valueOf(row.get('Body'));
        item.ParentId = String.valueOf(row.get('ParentId'));
        item.IsRichText = Boolean.valueOf(row.get('IsRichText'));
        item.Type = String.valueOf(row.get('TextPost'));
        item.Visibility = 'AllUsers';
        try{
            insert item;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return true;
    }
}