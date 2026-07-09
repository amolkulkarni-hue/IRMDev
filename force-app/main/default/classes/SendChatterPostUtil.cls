public class SendChatterPostUtil {
    
    public Static String sendChatterPost(Map<String, Id> UserId,
                                         Map<String, String> CustIdMap,
                                         Id caseid,
                                         String caseTerritoryGM,
                                         Id caseCustomerID,
                                         String caseCustomerName,
                                         String caseMarketName,
                                         String caseOwnerId
                                        )
    {
        String smsg = ': This is to notify you that a closure case has opened for '+CustIdMap.get(caseCustomerID)+' – '+caseCustomerName+' – in the '+caseMarketName+' market.  Please go to the below case link to study closure details.';  
        ConnectApi.FeedElement feedElement;        
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();  
        ConnectApi.BinaryInput feedBinary; 
        ConnectApi.FeedItemPage feed;
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();  
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();  
        
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();  
        mentionSegment.id = UserId.get(caseTerritoryGM);  
        messageInput.messageSegments.add(mentionSegment);   
        
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();  
        textSegment.text = smsg;  
        messageInput.messageSegments.add(textSegment);   
        input.body = messageInput;  
        
        if(!Test.isRunningTest())
        {
        	feed = ConnectApi.ChatterFeeds.getFeedItemsFromFeed(null, ConnectApi.feedType.Record, caseid); 
            if(feed.items.size() == 0){
                feedElement = ConnectApi.ChatterFeeds.postFeedItem(null, ConnectApi.FeedType.Record, caseid, input,null); 
            }  
        }  
        if(feedElement != null)	
            return feedElement.Id;
        else
            return 'No chat posted';     
    }    
}