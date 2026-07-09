/**
       * Developer Name: Akhil Makam,Avanthi Gadamsetty
       * Description: Searching the articles from the Eienstein Bot.
       * Story Number:
       * Updated: 31/03/2022
**/
public with sharing class KnowledgeBaseSearch {
    
   public class FAQSearchInput{
      
      @InvocableVariable(required=true)
       public String sKeyword;
     
       @InvocableVariable(required=true)
       public String Lang;   
   }
    
  @InvocableMethod(label='Search FAQ')
  public static List<List<Knowledge__kav>> getKnowledgeBase(List<FAQSearchInput> searchkeyword) {
    
      String sKeyword = searchkeyword[0].sKeyword;
      String lan  = searchkeyword[0].Lang;
		
      String sQuery = 'FIND \'' + sKeyword + 
         '\' IN ALL FIELDS RETURNING Knowledge__kav(Id, Title, UrlName, Knowledge_community_url__c WHERE PublishStatus = \'Online\' AND Language =\'' + lan + '\' AND IsVisibleInPkb = true) LIMIT 5';
       
      List<List <sObject>> Searchquery = search.query(sQuery);
    // Get the list of Public and Customer knowledgeBase Artilces
      system.debug('Searchquery-----' + Searchquery);    
     
    return Searchquery;
  }
}