@isTest(SeeAllData=false)
public class CustomerPortal_Controller_Test {
    
    
    @isTest
    static void getCasesTest(){
    CustomerPortal_Controller.getCases();
    }

    /*
    @isTest
    static void loadDataTest(){
    CustomerPortal_Controller.loadData();
    }

     @isTest
    static void getArticleInformationTest(){
        
        Knowledge__kav akv=new Knowledge__kav();
        List<Knowledge__kav> kvlist=new List<Knowledge__kav>();
        akv.UrlName='testurl';
        akv.Title='Test akv';
        kvlist.add(akv);
        insert kvlist;
        
        Knowledge__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM Knowledge__kav WHERE id =: kvlist[0].id];
        
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        
        CustomerPortal_Controller.getArticleInformation('testurl');
    }
    
    @isTest
    static void geArticlesByTopicsTest(){
     TopicAssignment tAssignment= [select EntityId,topicId from TopicAssignment limit 1];
       
        CustomerPortal_Controller.geArticlesByTopics(new List<id>{tAssignment.topicId});
    }
    
    @isTest
    static void searchTopicsTest(){
         Topic[] topics = [select Id from Topic where Name = 'Paused'];
        System.assert(topics.isEmpty());
        insert new Topic(Name = 'Paused');
     TopicAssignment tAssignment= [select EntityId,topicId from TopicAssignment limit 1];
         TopicAssignment tAss= [select EntityId,topicId from TopicAssignment limit 1];
        CustomerPortal_Controller.searchTopics('Article',new List<id>{tAss.topicId},'topicId');
    }*/
}