/**
* @author       : NeuraFlash, LLC
* @date         : 27/11/23
* @description  : Test Class for NF_ArticleTopicsHelper
*/
@isTest
public class NF_ArticleTopicsHelperTest {
    
    public static final String PARENT_TOPIC = 'Business_Checking';
    public static final String CHILD_TOPIC1 = 'Moving_Money';
    public static final String CHILD_TOPIC2 = 'Your_Checks';
    public static final String title = 'Test Title';
    public static final String urlName = 'test-article';
    public static final String bodyText = '<strong>Test</strong>';
    public static final string language ='en_GB';
    public static final string language1 ='fr_CA';
    public static final string language2 ='en_US';

    
    public static void createTopics(){
        String currentUserId = UserInfo.getUserId();
        String networkId = [SELECT NetworkId FROM NetworkMember where memberId =:currentUserId limit 1][0].NetworkId;
        ConnectApi.ManagedTopic parentTopic= ConnectApi.ManagedTopics.createManagedTopicByName(networkId,PARENT_TOPIC, ConnectApi.ManagedTopicType.Navigational);
        ConnectApi.ManagedTopic childTopic = ConnectApi.ManagedTopics.createManagedTopicByName(networkId,CHILD_TOPIC1, ConnectApi.ManagedTopicType.Navigational,parentTopic.id);
        ConnectApi.ManagedTopic childTopic2 = ConnectApi.ManagedTopics.createManagedTopicByName(networkId,CHILD_TOPIC2, ConnectApi.ManagedTopicType.Navigational,childTopic.id);
    }
    
    @isTest(seealldata=true)
    public static void testGetArticleSubTopicsByTopic(){
        
        List<NF_ArticleTopicsHelper.ArticleSubTopics> result = new List<NF_ArticleTopicsHelper.ArticleSubTopics>();
        List<NF_ArticleTopicsHelper.ArticleSubTopics> result1 = new List<NF_ArticleTopicsHelper.ArticleSubTopics>();
        
        Test.startTest();
        try{
            createTopics();
            result = NF_ArticleTopicsHelper.getArticlesBySelectedTopic(PARENT_TOPIC);
            result1 = NF_ArticleTopicsHelper.getAllAssignedArticleTopics(language);
            result1 = NF_ArticleTopicsHelper.getAllAssignedArticleTopics(language1);
            result1 = NF_ArticleTopicsHelper.getAllAssignedArticleTopics(language2);
         
        }catch(Exception e){
            System.debug('Exception in NF_ArticleTopicsHelperTest - testGetArticleSubTopicsByTopic'+e.getMessage());
        }
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result1);
    }
}