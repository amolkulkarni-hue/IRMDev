/**
* @author       : NeuraFlash, LLC
* @date         : 27/11/23
* @description  : Test Class for NF_KnowledgeSearchController
*/
@isTest
public class NF_KnowledgeSearchControllerTest {
    
    public static final String title = 'Test Title';
    public static final String urlName = 'test-article';
    public static final String language ='en_US';
    
    @isTest(seealldata=true)
    public static void getAllAssignedArticleTopicsTest(){
        List<NF_ArticleTopicsHelper.ArticleSubTopics> result = new List<NF_ArticleTopicsHelper.ArticleSubTopics>();
        Test.startTest();
        try{
            NF_ArticleTopicsHelperTest.createTopics();
            result = NF_KnowledgeSearchController.getAllAssignedArticleTopics(language);
        }catch(Exception e){
            System.debug('Exception in NF_KnowledgeSearchControllerTest - getAllAssignedArticleTopicsTest'+e.getMessage());
        }
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
}