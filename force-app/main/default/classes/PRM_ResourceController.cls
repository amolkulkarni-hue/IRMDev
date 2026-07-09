public class PRM_ResourceController {
    
    @AuraEnabled
    public static PRM_ResourceWrapper getFilters(){
        PRM_ResourceWrapper wrp = new PRM_ResourceWrapper(null);
        wrp.contentList = new List<PRM_ContentWrapper>();
        wrp.channels = PRM_Helper.getPicklistValues('ContentVersion', 'PRM_Channel__c');
        wrp.solutions = PRM_Helper.getPicklistValues('ContentVersion', 'PRM_Solution__c');
        wrp.productFamilies = PRM_Helper.getPicklistValues('ContentVersion', 'PRM_ProductFamily__c');
        wrp.fileTypes = PRM_Helper.getPicklistValues('ContentVersion', 'PRM_FileType__c');
        wrp.sortByList = new List<PRM_Picklist>();
        wrp.sortByList.add(new PRM_Picklist('Title', 'Title'));
        wrp.sortByList.add(new PRM_Picklist('Last Modified', 'LastModifiedDate'));
        wrp.sortByList.add(new PRM_Picklist('File Type', 'FileType'));
        wrp.sortBy = 'Title';
        return wrp; 
    }
    
    @AuraEnabled
    public static PRM_ResourceWrapper getResources(String wrpString, String fieldSet){
        
        PRM_SAVOSetting__mdt savoSetting = [SELECT 	PRM_ContentLibraries__c  
                                           	FROM	PRM_SAVOSetting__mdt 
                                           	WHERE 	DeveloperName = 'SAVO'];
        
        List<String> libNames = savoSetting.PRM_ContentLibraries__c.split(';');
        
        List<ContentWorkspaceDoc> docs = [select Id, ContentDocumentId 
                                          from ContentWorkspaceDoc 
                                          where ContentWorkspace.Name =: libNames];
        
        List<Id> docIds = new List<Id>();
        for (ContentWorkspaceDoc d : docs){
            docIds.add(d.ContentDocumentId);
        }

        PRM_ResourceWrapper wrp = (PRM_ResourceWrapper) JSON.deserialize(wrpString, PRM_ResourceWrapper.class);
        String sText = '*' + PRM_Helper.escapeSOSLTerm(wrp.searchText) +'*';
        String qry = 'FIND :sText IN ALL FIELDS RETURNING ';
        if (!String.isBlank(wrp.searchText)){
            qry += PRM_Helper.getFSQueryString('ContentVersion', fieldSet, false);
        } else {
            qry = PRM_Helper.getFSQueryString('ContentVersion', fieldSet, true);
        }
        
        qry =qry.replace(',ContentDocument.Name', '');
        String filter = ' where ContentDocumentId =: docIds';
       
        String channel = wrp.channel;
        if (!String.isBlank(channel)){
            filter += ' and PRM_Channel__c includes (:channel) ' ;
        }
        
        String solution = wrp.solution;
        if (!String.isBlank(solution)){
            filter += ' and PRM_Solution__c includes (:solution) ' ;
        }
        
        String productFamily = wrp.productFamily;
        if (!String.isBlank(productFamily)){
            filter += ' and PRM_ProductFamily__c includes (:productFamily)' ;
        }
        
        String fileType = wrp.fileType;
        if (!String.isBlank(fileType)){
            filter += ' and PRM_FileType__c includes (:fileType) ' ;
        }
  
        if (filter.length() > 0){
            if (!String.isBlank(wrp.searchText)){
            	qry = qry.left(qry.length()-1) + filter;
            } else {
                qry += filter;
            }
        }
		
        if (String.isNotBlank(wrp.sortBy)){
        	qry += ' ORDER BY ' + wrp.sortBy ;
        }
        
        if (!String.isBlank(wrp.searchText)){
        	qry += ')';
        }

        System.Debug('qry:' + qry);
        
        List<PRM_ContentWrapper> cList = new List<PRM_ContentWrapper>();
        if (!String.isBlank(wrp.searchText)){
        	List<List<ContentVersion>> res = search.query(qry);
            for (ContentVersion cv : res[0]){
                cList.add(new PRM_ContentWrapper(cv));
            }      
        } else {
            List<ContentVersion> res = Database.query(qry);
             for (ContentVersion cv : res){
                cList.add(new PRM_ContentWrapper(cv));
            }     
        }
        wrp.contentList = cList;

        return wrp;
    }

}