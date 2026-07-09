/**
* @author       : NeuraFlash, LLC
* @date         : 27/11/23
* @description  : Helper class for NF_KnowledgeSearchController
*/
public without sharing class NF_ArticleTopicsHelper {
    
    public static final String WHITESPACE_REGEX = '\\s+';
    public static final String TOPIC_REGEX = '[^a-zA-Z0-9_-]+';
    public static final String PUBLISH_STATUS = 'Online';
    public static String usrLanguage = '';
    
    /**
	* @date         : 27/11/23
	* @description  : This method is used to get all the articles based on the selected topic.
	*/
    
    @AuraEnabled
    public static List<ArticleSubTopics> getArticlesBySelectedTopic(String selectedTopic) {
        return getArticleTopics(selectedTopic);
    }
    
    /**
    * @date         : 27/11/23
    * @description  : This method is used to get all the articles for the topics.
	*/
    
    @AuraEnabled
    public static List<ArticleSubTopics> getAllAssignedArticleTopics(String language) {
        usrLanguage = language;
        return getArticleTopics('');
    }
    
    /**
    * @date         : 27/11/23
    * @description  : This private method is used to get all the articles for the topics.
	*/
    private static List<ArticleSubTopics> getArticleTopics(String selectedTopic) {
        List<ArticleSubTopics> articleSubTopicsList = new List<ArticleSubTopics>();
        List<Id> topicIdList = new List<Id>();
        
        try {
            String networkId = retrieveNetworkIdForUser();
                
            ConnectApi.ManagedTopicCollection managedTopics = ConnectAPI.ManagedTopics.getManagedTopics(
                networkId, ConnectApi.ManagedTopicType.Navigational, 3
            );
            
            for (ConnectApi.ManagedTopic parentTopic : managedTopics.managedTopics) {
                String topicApiName = formatTopicName(parentTopic.topic.name);
                
                ArticleSubTopics mainTopic = new ArticleSubTopics();
                mainTopic.topicName = parentTopic.topic.name;
                mainTopic.topicId = parentTopic.topic.id;
                topicIdList.add(mainTopic.topicId);
                              
                List<ArticleSubTopics> subTopicsList = collectSubTopics(parentTopic, topicApiName, selectedTopic, topicIdList);
                
                if (shouldAddMainTopic(topicApiName, selectedTopic)) {
                    mainTopic.subTopics = subTopicsList;
                    articleSubTopicsList.add(mainTopic);
                    if (topicApiName == selectedTopic) {
                        break;
                    }
                }
            }
            
            populateArticlesByTopics(topicIdList, articleSubTopicsList);
        } catch (Exception e) {
            System.debug('exception'+e.getMessage()+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        
        return articleSubTopicsList;
    }

    /**
    * @date         : 27/11/23
    * @description  : This private method is used to retrieve the network id of the user.
	*/
    private static String retrieveNetworkIdForUser() {
        if (Test.isRunningTest()) {
            String currentUserId = UserInfo.getUserId();
            return [SELECT NetworkId FROM NetworkMember WHERE MemberId = :currentUserId LIMIT 1].NetworkId;
        }
        return Network.getNetworkId();
    }

    /**
    * @date         : 27/11/23
    * @description  : This private method is used to check for the selected topic.
	*/
    private static Boolean shouldAddMainTopic(String topicApiName, String selectedTopic) {
        return String.isBlank(selectedTopic) || topicApiName == selectedTopic;
    }

    /**
    * @date         : 27/11/23
    * @description  : This private method is used to get all the subtopics.
	*/
    private static List<ArticleSubTopics> collectSubTopics(
        ConnectApi.ManagedTopic parentTopic, String topicApiName, String selectedTopic, List<Id> topicIdList
    ) {
        List<ArticleSubTopics> subTopicsList = new List<ArticleSubTopics>();
        
        for (ConnectApi.ManagedTopic childTopic : parentTopic.children) {
            ArticleSubTopics subTopic = new ArticleSubTopics();
            subTopic.topicName = childTopic.topic.name;
            subTopic.topicId = childTopic.topic.id;
            subTopic.categoryName = formatTopicName(childTopic.topic.name);
            subTopic.icon = formatIconName(childTopic.topic.name);
            topicIdList.add(childTopic.topic.id);
            
            subTopic.subTopics = collectChildSubTopics(childTopic, topicIdList);
            subTopicsList.add(subTopic);
        }
        
        return subTopicsList;
    }
    
    /**
    * @date         : 27/11/23
    * @description  : This private method is used to get all the child subtopics.
	*/
    private static List<ArticleSubTopics> collectChildSubTopics(ConnectApi.ManagedTopic childTopic, List<Id> topicIdList) {
        List<ArticleSubTopics> childSubTopicsList = new List<ArticleSubTopics>();
       
        for (ConnectApi.ManagedTopic grandchildTopic : childTopic.children) {
            ArticleSubTopics childSubTopic = new ArticleSubTopics();
            childSubTopic.topicName = grandchildTopic.topic.name;
            childSubTopic.topicId = grandchildTopic.topic.id;
            childSubTopic.categoryName = formatTopicName(grandchildTopic.topic.name);
            
            topicIdList.add(grandchildTopic.topic.id);
            
            childSubTopicsList.add(childSubTopic);
        }
        
        return childSubTopicsList;
    }

    /**
    * @date         : 27/11/23
    * @description  : This private method is used to format the topic name.
	*/
    private static String formatTopicName(String topicName) {
        return topicName.replaceAll(WHITESPACE_REGEX, '-').toLowerCase();
    }
    
    /**
    * @date         : 27/11/23
    * @description  : This private method is used to format the icon name.
	*/
    private static String formatIconName(String topicName) {
        return topicName.toLowerCase().replaceAll(TOPIC_REGEX, '-') + '.svg';
    }

    /**
    * @date         : 27/11/23
    * @description  : This private method is used to get all the articles specific to the topics.
	*/
    @TestVisible
    private static void populateArticlesByTopics(List<Id> topicIds, List<ArticleSubTopics> lstArticleSubTopics) {
      
        List<TopicAssignment> tcs = [SELECT EntityId,TopicId,TYPEOF Entity WHEN Knowledge__kav THEN UrlName, Title END FROM TopicAssignment WHERE TopicId IN :topicIds
            AND Entity.Type IN ('Knowledge__kav')
            AND EntityId IN (
                SELECT id
                FROM KnowledgeArticleVersion
                WHERE PublishStatus =:PUBLISH_STATUS
                AND (IsVisibleInPkb = TRUE
                     OR IsVisibleInCsp = TRUE
                     OR IsVisibleInPrm = TRUE     
                    ) AND Language =:usrLanguage
            )
        ];
        for (ArticleSubTopics eachArticleSubTopic : lstArticleSubTopics) {
            List<KnowledgeArticle> knowledgeArticlesForLevel1 = new List<KnowledgeArticle>();
            Map<Id, KnowledgeArticle> knowledgeArticleMap = new Map<Id, KnowledgeArticle>();
          
            for (TopicAssignment topicAssignment : tcs) {
                if (topicAssignment.TopicId == eachArticleSubTopic.topicId) {
                    KnowledgeArticle article = new KnowledgeArticle();
                    article.articleId = topicAssignment.EntityId;
                    Knowledge__kav articleEntity = topicAssignment.Entity;
                    article.articleTitle = articleEntity.Title;
                    article.articleUrlName = articleEntity.UrlName;
                    
                    if (!knowledgeArticleMap.containsKey(article.articleId)) {
                        knowledgeArticlesForLevel1.add(article);
                        knowledgeArticleMap.put(article.articleId, article);
                    }
                }
            }
            
            if (!knowledgeArticlesForLevel1.isEmpty()) {
                eachArticleSubTopic.knowledgeArticles = knowledgeArticlesForLevel1;
            }
            
            for (Integer i = 0; i < eachArticleSubTopic.subTopics.size(); i++) {
                ArticleSubTopics subTopic = eachArticleSubTopic.subTopics[i];
                List<KnowledgeArticle> knowledgeArticlesForLevel2 = processSubTopicArticles(subTopic, tcs, knowledgeArticleMap);
                
                if (!knowledgeArticlesForLevel2.isEmpty()) {
                    subTopic.knowledgeArticles = knowledgeArticlesForLevel2;
                    subTopic.categoryOrder = i + 1;
                    subTopic.categoryId = 'item-' + (i + 1);
                } else if (subTopic.subTopics.isEmpty()) {
                    eachArticleSubTopic.subTopics.remove(i);
                    i--;
                }

                for (Integer j = 0; j < subTopic.subTopics.size(); j++) {
                    ArticleSubTopics subTopicL3 = subTopic.subTopics[j];
                    List<KnowledgeArticle> knowledgeArticlesForLevel3 = processSubTopicArticles(subTopicL3, tcs, knowledgeArticleMap);
    
                    if (!knowledgeArticlesForLevel3.isEmpty()) {
                        subTopicL3.knowledgeArticles = knowledgeArticlesForLevel3;
                        subTopic.categoryOrder = j + 1;
                        subTopic.categoryId = 'item-' + (j + 1);
                    }
                }
            }
        }
    }
    
    /**
    * @date         : 27/11/23
    * @description  : This private method is used to process the articles for the subtopics.
	*/
    private static List<KnowledgeArticle> processSubTopicArticles(ArticleSubTopics subTopic, List<TopicAssignment> topicAssignments, Map<Id, KnowledgeArticle> knowledgeArticleMap) {
        List<KnowledgeArticle> knowledgeArticles = new List<KnowledgeArticle>();
        
        for (TopicAssignment topicAssignment : topicAssignments) {
            if (topicAssignment.TopicId == subTopic.topicId) {
                KnowledgeArticle article = new KnowledgeArticle();
                article.articleId = topicAssignment.EntityId;
                Knowledge__kav articleEntity = topicAssignment.Entity;
                article.articleTitle = articleEntity.Title;
                article.articleUrlName = articleEntity.UrlName;
                
                knowledgeArticles.add(article);
                knowledgeArticleMap.put(article.articleId, article);
            }
        }
        return knowledgeArticles;
    }
    
    public class ArticleSubTopics {
        @AuraEnabled
        public String topicName;
        @AuraEnabled
        public String topicId;
        @AuraEnabled
        public String categoryId;
        @AuraEnabled
        public Integer categoryOrder;
        @AuraEnabled
        public String categoryName;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String target;
        @AuraEnabled
        public List<ArticleSubTopics> subTopics;
        @AuraEnabled
        public List<KnowledgeArticle> knowledgeArticles;
    }
    
    public class KnowledgeArticle {
        @AuraEnabled
        public String articleId;
        @AuraEnabled
        public String articleUrlName;
        @AuraEnabled
        public String articleTitle;
    }
}