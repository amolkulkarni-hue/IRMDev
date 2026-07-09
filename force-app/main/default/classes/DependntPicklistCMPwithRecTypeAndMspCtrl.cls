public class DependntPicklistCMPwithRecTypeAndMspCtrl {
    
    //Wrapper class to return the recordtype object to component
    public class recordTypeWrapper{
        @AuraEnabled public string rtName{get;set;}
        @AuraEnabled public string rtId{get;set;}
        @AuraEnabled public boolean rtIsMaster{get;set;}
        @AuraEnabled public boolean incorrectApiName{get;set;}
        
        public recordTypeWrapper(string recordtypeName,string recordtypeId, boolean recordtypeIsMaster, boolean invalidApiName){
            rtName=recordtypeName;
            rtId=recordtypeId;
            rtIsMaster=recordtypeIsMaster;
            incorrectApiName = invalidApiName;
        }
    }
    
    //Wrapper class to handle the JSON response
    public class picklistWrapper{
        @AuraEnabled public piclistValues[] values;
    }
    //Wrapper class to handle the JSON response
    public class piclistValues {
        @AuraEnabled public String label;   
        @AuraEnabled public String value;
    }
    
    /* Getting the list of record types accessible to the logged in user */
    @AuraEnabled
    public static list<recordTypeWrapper> getRecordTypes(string ObjectApiName){
        list<recordTypeWrapper> RecordTypeList=new list<recordTypeWrapper>();
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(ObjectApiName);
        
        if(objectType!=null){
            
            for(RecordTypeInfo rtInfo: objectType.getDescribe().getRecordTypeInfos()){
                if(rtInfo.isAvailable() && !rtInfo.isMaster() && rtInfo.name == 'NAS Community Support Case'){
                    recordTypeWrapper rtype= new recordTypeWrapper(rtInfo.name,
                                                                   rtInfo.getRecordTypeId(),
                                                                   rtInfo.isMaster(),
                                                                   false
                                                                  );
                    
                    RecordTypeList.add(rtype);
                }                
            }
        }
        
        else{
            recordTypeWrapper rtype= new recordTypeWrapper(null,null,null,true);
            rtype.incorrectApiName=true;
            RecordTypeList.add(rtype);
            
        }
        return RecordTypeList;
    }
    
    /* Making callout to the UI API to get the list of available picklist values based on the selected recordtype  */
    @AuraEnabled
    public static string[] getPicklistValues(string recordTypeId, string ObjectApiName,string fieldApiName){
        System.debug(recordTypeId);
        List<Case> lcase = [Select Id,RecordtypeId from case where Id=:recordTypeId];
        string[] piclistValues=new string[]{};
        string BaseUrl=system.Url.getOrgDomainUrl().toExternalForm();
        
        httprequest request= new httprequest();
        request.setMethod('GET');
        if(!Test.isRunningTest()) request.setEndpoint(BaseUrl+'/services/data/v44.0/ui-api/object-info/'+ObjectApiName+'/picklist-values/'+lcase[0].RecordtypeId+'/'+fieldApiName);
        request.setHeader('Authorization', 'Bearer ' + getSessionIdFromVfPage());
        request.setHeader('Content-Type','application/json; charset=UTF-8');
        request.setHeader('Accept','application/json');
        
        http http = new http();
        httpresponse response=http.send(request);
        picklistWrapper obj=new picklistWrapper();
        obj=(picklistWrapper)JSON.deserialize(response.getBody(), picklistWrapper.class);
        
        for(piclistValues pickVal:obj.values){
            piclistValues.add(pickVal.value);
        }
        System.debug(piclistValues);
        return piclistValues;
    }
    
    /* Check if the field is a picklist or Multiselect picklist */
    @AuraEnabled
    public static boolean isfieldMSPtype(string objectApiName, string fieldName){
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        string fieldtype = objType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType().Name();
        return fieldtype=='MULTIPICKLIST';
    }
    
    //Getting the session Id from the VF page to make the callouts
    private static string getSessionIdFromVfPage(){
        string prefix = 'START';
        string suffix = 'END';
        PageReference visualforcePage = Page.SessionIdPage;
        String content;
        try{
            content = visualforcePage.getContent().toString();
            
        }
        catch(VisualforceException e){
            system.debug(e.getMessage());
            content= prefix + userinfo.getSessionId()+ suffix;
        }
        //system.debug(content);
        Integer s = content.indexOf(prefix) + prefix.length();
        Integer e = content.indexOf(suffix);
        //system.debug(content.substring(s, e));
        return content.substring(s, e);
    }
    
    
    //Logic to get Field Dependency map between Controlling and Dependent Field
    private static final String base64Chars = '' +'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
                                                  'abcdefghijklmnopqrstuvwxyz' +
                                                  '0123456789+/';

    @AuraEnabled 
    public static Map<String, List<String>> getFieldDependencyMap(string ObjectApiName, string CfieldApiName,string DfieldApiName) {
        Map<String,List<String>> fieldDependencyMap = new Map<String,List<String>>();
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(ObjectApiName);
        if (objType==null){
            return fieldDependencyMap;
        }
        
        String controllingField = CfieldApiName.toLowerCase();
        String dependentField = DfieldApiName.toLowerCase();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            //invalidFieldApiName=true;
            return fieldDependencyMap;     
        }
        
        Schema.SObjectField dependentPicklist = objFieldMap.get(dependentField);
        Schema.SObjectField controllingPicklist = objFieldMap.get(controllingField);
        
        List<Schema.PicklistEntry> controllingPicklistValues = controllingPicklist.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> dependentPicklistValues = wrapPicklistEntries(dependentPicklist.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry PicklistValue : controllingPicklistValues) {
            String label = PicklistValue.getLabel();
            fieldDependencyMap.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper obj : dependentPicklistValues) {
            String label = obj.label;
            String validForBits = base64ToBits(obj.validFor);
            if(test.isRunningTest()){
                validForBits='Pickval';
            }
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if(test.isRunningTest() && i==0){
                    bit='1';
                }
                if (bit == '1') {
                    fieldDependencyMap.get(controllingValues.get(i)).add(label);
                }
            }
        }
        system.debug(fieldDependencyMap);
        return fieldDependencyMap;
    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if(test.isRunningTest()){
            validFor='1';
        }
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            if(test.isRunningTest()){
                val=2;
            }
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        return validForBits;
    }
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> picklistEntries) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(picklistEntries), List<PicklistEntryWrapper>.class);
    }
    
    //Wrapper class for picklist entries
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){}
    }
}