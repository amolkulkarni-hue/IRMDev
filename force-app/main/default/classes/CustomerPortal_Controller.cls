public without sharing class CustomerPortal_Controller {
    
    
    @auraEnabled
    public static map<string,object> getCases(){
        
        map<string,object> mapResponse=new   map<string,object> ();
        
        user userRecord=[select id,accountid from user where id=:userinfo.getUserId()];
        
        List<case> lstOpenCase=[select id,casenumber,subject,status,CreatedDate from case where status in('Open','New') and accountid=:userRecord.accountid limit 50000];
        List<case> lstOpenClosed=[select id,casenumber,subject,status,CreatedDate from case where status='Closed' and accountid=:userRecord.accountid limit 50000];
        
        mapResponse.put('OpenCases',lstOpenCase);
        mapResponse.put('ClosedCases',lstOpenClosed);
        
        return mapResponse;
    }  
 
    
    /*
    @auraEnabled
    public static map<string,object> loadData(){
        
        Map<string,object> mpData=new Map<string,object>();
        List<ConnectApi.ManagedTopic> lstData=new List<ConnectApi.ManagedTopic>();
        set<id> topicId=new set<id>();
        for(ConnectApi.ManagedTopic mtopic : TopicController.getNavigationTopics().managedTopics){
            lstData.add(mtopic);
            system.debug('mtopic'+mtopic);
            topicId.add(mtopic.topic.id);
        }
        system.debug('lstData'+lstData);
        
        user userRecord=[select id,Name,LastName,UserType,contact.accountid from user where id=:userinfo.getUserId()];
        
        set<id> setIds=new  set<id> ();
      List<TopicAssignment> lstAssignment= [select EntityId from TopicAssignment where topicid in:topicId];
        for(TopicAssignment t:lstAssignment){
            setIds.add(t.EntityId);
        }           
        mpData.put('TopicsWiseList',lstData);
        
        mpData.put('Topics', [SELECT ArticleTotalViewCount ,Summary,id,KnowledgeArticleId, Title, UrlName,createddate  FROM KnowledgeArticleVersion WHERE Id in:setIds and PublishStatus='Online' ]);
        mpData.put('currentUser',userRecord);
        mpData.put('isGuestUser',userRecord.UserType=='Guest'?true:false);
        if(userRecord.UserType!='Guest')
            mpData.put('caseCount',[select id  from Case where Accountid=:userRecord.contact.accountid and status in('Open','New')  ].size());
        else 
            mpData.put('caseCount',0);
        
        return mpData;
    }
    
    @auraEnabled
    public static  LIST<Knowledge__kav> filterDataByTopic(List<string> topicList,string Filter){
        
        return new LIST<Knowledge__kav>();
    }
    
    @auraEnabled
    public static  map<string,object> searchTopics(string searchTopics,List<id> topicId,string Filter){
        set<id> setIds=new  set<id> ();
        map<string,object> mpreturn=new map<string,object>();
        
        List<AggregateResult> results = new List<AggregateResult>([select COUNT(ID) ct,Knowledge__c knId from GuestArticleVote__c where IsUpvoted__c =true  GROUP BY Knowledge__c ]);
        Map<String,Integer> mapCountLikes = new Map<String,Integer>();
        
        for(AggregateResult aggResult : results){
            mapCountLikes.put((String)aggResult.get('knId'), (Integer)aggResult.get('ct'));
        }
        
        mpreturn.put('countMap',mapCountLikes);
        if(searchTopics=='' && topicId.size()==0){
          mpreturn.put('articleList',new List<Knowledge__kav>());
            return mpreturn;
        }
            
        if(topicId.size()==0){
            for(ConnectApi.ManagedTopic mtopic : TopicController.getNavigationTopics().managedTopics){
                topicId.add(mtopic.topic.id);
            }
        }
        
        for(TopicAssignment t:[select EntityId from TopicAssignment where TopicId in:topicId]){
            setIds.add(t.EntityId);
        }
        
        
        String tempInput ='%' + searchTopics  + '%';
        system.debug('tempInput'+tempInput);
        system.debug('setIds'+setIds);
        
        LIST<Knowledge__kav> kavLIST=new LIST<Knowledge__kav>();
        
        List<Knowledge__kav> knList=[SELECT SUMMARY,ArticleTotalViewCount,Question__c,PublishStatus,id,KnowledgeArticleId,Title,Answer__c ,UrlName,CreatedDate  FROM Knowledge__kav where PublishStatus ='Online' and title like : tempInput and Id in:setIds];
        
        
        if(Filter=='Most Viewed'){
            mpreturn.put('articleList',[SELECT SUMMARY,ArticleTotalViewCount,Question__c,PublishStatus,id,KnowledgeArticleId,Title,Answer__c ,UrlName,CreatedDate  FROM Knowledge__kav where PublishStatus ='Online' and title like : tempInput and Id in:setIds order by ArticleTotalViewCount DESC]);

        }else if(Filter=='Most Recent'){
            SYSTEM.debug('DD'+[SELECT  SUMMARY,ArticleTotalViewCount,Question__c,PublishStatus,id,KnowledgeArticleId,Title,Answer__c ,UrlName,CreatedDate  FROM Knowledge__kav where PublishStatus ='Online' and title like : tempInput and Id in:setIds order by CreatedDate DESC]);
            mpreturn.put('articleList',[SELECT  SUMMARY,ArticleTotalViewCount,Question__c,PublishStatus,id,KnowledgeArticleId,Title,Answer__c ,UrlName,CreatedDate  FROM Knowledge__kav where PublishStatus ='Online' and title like : tempInput and Id in:setIds order by CreatedDate DESC]);
        }
        return mpreturn;
    }    
    
    @auraEnabled
    public static map<string,object>  geArticlesByTopics(List<id> topicId){
        
        set<id> setIds=new  set<id> ();
        
        if(topicId.size()==0){
            for(ConnectApi.ManagedTopic mtopic : TopicController.getNavigationTopics().managedTopics){
                topicId.add(mtopic.topic.id);
            }
        }
        for(TopicAssignment t:[select EntityId from TopicAssignment where TopicId in:topicId]){
            setIds.add(t.EntityId);
        }
        
       
        system.debug('setIds'+setIds);
        system.debug('setIds'+setIds.size());
        List<KnowledgeArticleVersion> lstArticles =[SELECT CreatedDate,ArticleTotalViewCount,summary,id,KnowledgeArticleId, Title, UrlName  FROM KnowledgeArticleVersion WHERE Id in:setIds and PublishStatus='Online' ];
       
        map<string,object> mp=new   map<string,object>();
            
        mp.put('lstArticles',lstArticles);
        mp.put('topicInfo',[select id,name from Topic where id=:topicId[0]].Name);
        
        List<AggregateResult> results = new List<AggregateResult>([select COUNT(ID) ct,Knowledge__c knId from GuestArticleVote__c where IsUpvoted__c =true  GROUP BY Knowledge__c ]);
        Map<String,Integer> mapCountLikes = new Map<String,Integer>();              
        for(AggregateResult aggResult : results){        
            mapCountLikes.put((String)aggResult.get('knId'), (Integer)aggResult.get('ct'));     
        }            
        mp.put('countMap',mapCountLikes);
        
        return mp;

    }
    
    @auraEnabled
    public static KnowledgeWrapper getArticleInformation(string articlelURL){
        
        Knowledge__kav kav=[SELECT id,KnowledgeArticleId,Title,Answer__c ,UrlName,CreatedDate  FROM Knowledge__kav WHERE UrlName=:articlelURL and PublishStatus='Online' limit 1];
        
        Knowledge__ka kv=   [SELECT id,TotalViewCount  FROM Knowledge__ka WHERE Id=:kav.KnowledgeArticleId limit 1 UPDATE VIEWSTAT];
        
        KnowledgeWrapper kw=new KnowledgeWrapper();
        kw.count=kv.TotalViewCount;
        kw.Likecount = [ SELECT COUNT() FROM GuestArticleVote__c WHERE Knowledge__c = :kav.id and IsUpvoted__c =true];
        kw.kav=kav;
        
        return kw;
    }
    
    public class KnowledgeWrapper{
        public @auraEnabled Integer count;
        public   @auraEnabled  Knowledge__kav kav;
        public @auraEnabled Integer likecount;
        
        
        public KnowledgeWrapper(){
            
        }
        
    }
    
  */  
}