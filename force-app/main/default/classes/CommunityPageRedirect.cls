/**
* @File Name : CommunityPageRedirect.cls
* Test Class : CommunityPageRedirectTest
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
                        09/06/2024 - Roopesh Lakshmanan - initial development - Gitlab #26168

**/

public class CommunityPageRedirect {
	@AuraEnabled
	Public static String getFeedItemCaseID(String feedID){
		FeedItem fi =  [select ParentId from FeedItem where Id =:feedID LIMIT 1];
		return fi.ParentId;
	}
}