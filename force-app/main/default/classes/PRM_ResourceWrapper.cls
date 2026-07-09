public class PRM_ResourceWrapper {
    
    public PRM_ResourceWrapper(List<PRM_ContentWrapper> cvList) {
        this.contentList = cvList;
        this.searchText = '';
    }
    
    @AuraEnabled
    public String channel							{ get;set; }
    @AuraEnabled
    public List<PRM_Picklist> channels				{ get;set; }
    
    
    @AuraEnabled
    public String solution							{ get;set; }
    @AuraEnabled
    public List<PRM_Picklist> solutions				{ get;set; }
    
    
    @AuraEnabled
    public String productFamily						{ get;set; }
    @AuraEnabled
    public List<PRM_Picklist> productFamilies		{ get;set; }
    
    
    @AuraEnabled
    public String fileType							{ get;set; }
    @AuraEnabled
    public List<PRM_Picklist> fileTypes				{ get;set; }
    
    @AuraEnabled
    public String sortBy							{ get;set; }
    @AuraEnabled
    public List<PRM_Picklist> sortByList			{ get;set; }
    
    
    @AuraEnabled
    public String searchText						{ get;set; }
    
   	@AuraEnabled
    public List<PRM_ContentWrapper> contentList		{ get;set; }
    

}