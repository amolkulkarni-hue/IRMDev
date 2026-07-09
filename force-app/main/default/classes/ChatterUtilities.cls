/***************************************************************************************************
Class    :  ChatterUtilities.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :  June 17, 2013
Modified :  July 17, 2013
Objective:  This class provides methods to service ConnectApi classes. 

***************************************************************************************************/

global class ChatterUtilities
{
    //  global methods listed in alphabetical order
    global static ConnectApi.FeedItem postFeedItem ( String communityId     , ConnectApi.FeedType feedType
                                                   , String subjectId       , String message
                                                   , List <String> mentionedUserIds,String accountName
                                                   , String riskAssessmentId,String postUrlFlag )
    {
        //  variables declared in alphabetical order
        ConnectApi.FeedItem feedItem = null;
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput ();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput ();
        ConnectApi.MentionSegmentInput mentionSegment = null;
        ConnectApi.TextSegmentInput messageSegment = new ConnectApi.TextSegmentInput ();
        List <ConnectApi.MessageSegmentInput> messageSegments = new List <ConnectApi.MessageSegmentInput> ();

        messageSegment.text = message;

        messageSegments.add (messageSegment);

        if ( ! mentionedUserIds.isEmpty () )
        {
            for ( String mentionedUserId : mentionedUserIds )
            {
                mentionSegment = new ConnectApi.MentionSegmentInput ();

                mentionSegment.Id = mentionedUserId;

                messageSegments.add (mentionSegment);

            }   //  each mentioned user

        }   //  mentions exist

        messageBodyInput.messageSegments = messageSegments;

        feedItemInput.body = messageBodyInput;
        
        if(postUrlFlag == 'True'){
		    ConnectApi.LinkAttachmentInput linkIn = new ConnectApi.LinkAttachmentInput();
		    linkIn.urlName = accountName+' Risk Information';
		    linkIn.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + riskAssessmentId;
		    feedItemInput.attachment = linkIn;
        }        

        feedItem = ConnectApi.ChatterFeeds.postFeedItem
                   (communityId, feedType, subjectId, feedItemInput, null);

        return feedItem;

    }   //  postFeedItem ()

}