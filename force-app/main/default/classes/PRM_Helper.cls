public class PRM_Helper {
        
    public static List<PRM_Picklist> getPicklistValues(String typeName, String fieldName) { 
        
        Schema.DescribeSObjectResult[] descResults = Schema.describeSObjects(new String[]{typeName});
        Schema.DescribeSObjectResult describe = descResults.get(0);   

        List<Schema.PicklistEntry> ple =  describe.fields.getMap().get(fieldName).getDescribe().getPickListValues(); 
        List<PRM_Picklist> plValues = new List<PRM_Picklist>();
        for (Schema.PicklistEntry pe : ple){
            if (String.isBlank(pe.getLabel())){
                plValues.add(new PRM_Picklist(pe.getValue(),pe.getValue()));
            } else {
              	plValues.add(new PRM_Picklist(pe.getLabel(),pe.getValue()));  
            }
            
        }
        System.Debug('plValues:' + plValues);
        return plValues;
    }
  
    public static String getAllQueryString(String typeName) { 
       	Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(typeName).getDescribe().fields.getMap();
        String qry = 'select  Id';
        for(String f : objectFields.keySet()) {
            if (f != 'Id'){
   				qry += ' ,' + f ;
            }
		}
         
        qry += '      from ' + typeName + ' ';
         
        return qry;
         
       
    }
    
    public static String getFSQueryString(String typeName, String fsName, boolean isSOQL) { 
        Schema.DescribeSObjectResult[] descResults = Schema.describeSObjects(new String[]{typeName});
        Schema.DescribeSObjectResult describe = descResults.get(0);  
        Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();

        Schema.FieldSet fs = fsMap.get(fsName); 
        if (fs != null) {
            List<Schema.FieldSetMember> fieldSet = fs.getFields();
            String qry = 'select 	id ';
            if (!isSOQL){ 
                qry = typeName + '( Id ';
            }

            for (Schema.FieldSetMember f: fieldSet) {
                string p = f.fieldPath;
                if (p.endsWith('Id')){
                  qry += ',' + p + ',' + p.replace('Id', '.Name'); 
                } else if (f.type == Schema.DisplayType.Reference){
                  qry += ',' + p + ',' + p.replace('__c', '__r.Name');  
                } else {
                   qry += ',' + p; 
                }
            }
            
            if (isSOQL){
                qry += '      from ' + typeName + ' ';
            } else { 
                qry += ')';
            }
            
            return qry;
         
        } else {
            return null;
        }
    }
    
    
	public static Schema.DescribeFieldResult getFieldInfo(String typeName, String fName) {
        if (!fName.contains('.')){
           Schema.DescribeSObjectResult[] descResults = Schema.describeSObjects(new String[]{typeName});
           Schema.DescribeSObjectResult describe = descResults.get(0); 
    
           return describe.fields.getMap().get(fName).getDescribe(); 
        } else {
            return null;
        }
   	}

    public static String escapeSOSLTerm(String term){
        system.debug(term);
        term = term.replace('\'', '');
        system.debug(term);
        Pattern reservedPattern = pattern.compile('[\\?&\\|!{}\\[\\]\\(\\)\\^~\\*:\\\"\\+-]');
        Matcher myMatcher = reservedPattern.matcher(term);
        List<Integer> escapeIndexs = new List<Integer>();
        while(true){
            if(myMatcher.find()){
                escapeIndexs.add(myMatcher.start());
            }else{
                break;
            }
        }
        escapeIndexs.sort();
        System.debug('escapeIndexs' + escapeIndexs);
        for(Integer i = escapeIndexs.size()-1; i>=0; i--){
            Integer escapeIndex = escapeIndexs[i];
            System.debug('term.substring(escapeIndex)' + term.substring(escapeIndex));
            term = term.substring(0, escapeIndex) + '\\' + term.substring(escapeIndex);
             System.debug('term' + term);
            
        }
        return term; 
    }
    
    @AuraEnabled
    public static Account getAccountManager() {
        User u = [select AccountId from User where Id=: UserInfo.getUserId()];
        if (u.AccountId != null){
        	return [Select Id, IM_Partner_Manager__c, IM_Partner_Manager__r.Name from Account where Id=: u.AccountId];
        } else {
            return null;
        }
   	}
}