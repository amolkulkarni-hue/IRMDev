@isTest(seeAllData=true)
public class Test_sendChatterPost {
     static TestMethod void doTest(){
       SendChatterPostUtil b1=new SendChatterPostUtil();
         Map<String, Id> UserId = new Map<String, id>();
         Map<String, String> CustIdMap = new Map<String, String>();
         ConnectApi.FeedItemPage testPage = new ConnectApi.FeedItemPage();
        ConnectApi.FeedItem feedItem = new ConnectApi.FeedItem();
        ConnectApi.Comment comment = new ConnectApi.Comment();

        List<ConnectApi.FeedItem> testItemList = new List<ConnectApi.FeedItem>();
        testItemList.add(feedItem);
        testPage.items = testItemList;
         
         ConnectApi.ChatterFeeds.setTestGetFeedItemsFromFeed(null, ConnectApi.FeedType.Record, '500S0000007R5S8', testPage);
         Test.startTest();
         String mssge = SendChatterPostUtil.sendChatterPost(UserId,CustIdMap,'500S0000007R5S8','ABC','a0880000008togU','ABC','ABC',UserInfo.getUserId());
         Test.stopTest();
    }
}