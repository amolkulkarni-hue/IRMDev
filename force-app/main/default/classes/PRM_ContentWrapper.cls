public class PRM_ContentWrapper {
    
    @AuraEnabled
    public Boolean selected 		{get; set;}
    
    @AuraEnabled
    public String fileSize 			{get; set;}
    
    @AuraEnabled
    public List<String> libraries	{get; set;}
    
    @AuraEnabled
    public ContentVersion cv 		{get; set;}
    
    @AuraEnabled
    public Integer contentSize 		{get; set;}
    
    public PRM_ContentWrapper(ContentVersion currentCV){
		cv = currentCV;
        contentSize = cv.ContentSize;
		selected = false;
        setSize(); 
    }
    
    public void setSize(){
        Decimal size = 0;
        if (contentSize > 1000000000){
            size = contentSize / 1000000000;
			fileSize = size.setScale(1).toPlainString() + ' GB';
        } else if (contentSize > 1000000){
            size = contentSize /1000000;
			fileSize = size.setScale(1).toPlainString() + ' MB';
        } else if (contentSize > 1000){
            size = contentSize /1000;
			fileSize = size.setScale(1).toPlainString() + ' KB';
        } else {
            fileSize = String.valueOf(contentSize);
        }         
    }
    

    

}