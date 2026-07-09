/**
 * @author       : NeuraFlash, LLC
 * @date         : 27/11/23
 * @description  : Controller for LWC component NF_KnowledgeTopicsDisplayComponent
 */
public class NF_KnowledgeSearchController {
    
    /**
     * @Gitlab  :   #26520
     * @date    : 04/10/2024
     * @modification : Modify this method to include a language parameter, allowing it to retrieve assigned article topics based on the Site language.
    */

    /**
     * @date         : 27/11/23
     * @description  : This method is used to get all the assigned article topics.
    */
    
    @AuraEnabled
    public static List<NF_ArticleTopicsHelper.ArticleSubTopics> getAllAssignedArticleTopics(String language) {
        List<NF_ArticleTopicsHelper.ArticleSubTopics> lstArticleSubTopics = NF_ArticleTopicsHelper.getAllAssignedArticleTopics(language);
        return lstArticleSubTopics;
    }
}