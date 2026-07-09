public class FilterUtil {
	
	public static List<SelectOption> getObjectFields(String objectName){

		List<SelectOption> objectfields = new List<SelectOption>();
		objectfields.add(new SelectOption('','--None--'));

		Map<String, Schema.SObjectField> mapObjectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        // Map keeping label names as key and api names as values
        Map<String, String> sortedMap = new Map<String, String>();

        for(String field : mapObjectFields.keySet()){
        	Schema.SObjectField sField = mapObjectFields.get(field);
        	sortedMap.put(sField.getDescribe().getLabel(), field);
        }
        
        List<String> fieldNameList = new List<String>();
        fieldNameList.addAll(sortedMap.keySet());
        // sorted list of label names
        fieldNameList.sort();          
        for(String label : fieldNameList){
        	String field = sortedMap.get(label);
            Schema.SObjectField soField = mapObjectFields.get(field);
            if(soField.getDescribe().getType().name()!='TEXTAREA' && soField.getDescribe().getName()!= 'RecordTypeId' && 
            soField.getDescribe().getName()!='IsDeleted'&& soField.getDescribe().getName()!= 'SystemModstamp' && 
            soField.getDescribe().getName()!='LastModifiedById'&& soField.getDescribe().getName()!='LastModifiedDate' &&
            soField.getDescribe().getName()!= 'CreatedDate' && soField.getDescribe().getName()!= 'CreatedById'){
                objectfields.add(new SelectOption(field,soField.getDescribe().getLabel()));
            }
        }
        return objectfields;
   }
   
   public static List<SelectOption> getAllDataTyes(){
   		List<SelectOption> dataTypes = new List<SelectOption>();
   		dataTypes.add(new SelectOption('','--None--'));
   		dataTypes.add(new SelectOption('STRING','String'));
   		dataTypes.add(new SelectOption('CURRENCY','Currency'));
		dataTypes.add(new SelectOption('BOOLEAN','Boolean'));
		dataTypes.add(new SelectOption('DATE','Date'));
		dataTypes.add(new SelectOption('DATETIME','Date/Time'));
		dataTypes.add(new SelectOption('DOUBLE','Double'));
		dataTypes.add(new SelectOption('INTEGER','Integer'));
		dataTypes.add(new SelectOption('PICKLIST','Picklist'));
		dataTypes.add(new SelectOption('MULTIPICKLIST','Multi-Picklist'));
		dataTypes.add(new SelectOption('PERCENT','Percent'));
		dataTypes.add(new SelectOption('REFERENCE','Reference'));
   		return dataTypes;
   		
   }
   
   public static List<SelectOption> loadPickListValues(Schema.SObjectField field){
        List<SelectOption> pickListValues = new List<SelectOption>();
        for(Schema.PicklistEntry pickListValue : field.getDescribe().getPicklistValues()){
            pickListValues.add(new SelectOption(pickListValue.getValue(),pickListValue.getValue()));
        }
        return pickListValues;
   }
}