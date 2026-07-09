/**
 * A class that generates and runs dynamic queries.
 *
 * @author Joo Kang
 * @version 0.9, 5/27/2014
*/
global class QueryBuilder {
	private String query;
    private Schema.SObjectType objectType;
    private String objectTypeStr;
    private List<Id> ids = new List<Id>();
    private Set<String> directFields = new Set<String>{'Id'};
    private Map<String, Set<String>> obj2Fields = new Map<String, Set<String>>();
    private String orderByField = null;
    private Boolean isAscending;
    private Set<String> contactFields = new Set<String>();
    private Set<String> custProfFields = new Set<String>();

    public QueryBuilder(Schema.SObjectType obj, List<Id> ids) {
        this.objectTypeStr = obj.getDescribe().getName();
        this.objectType = obj;
        this.ids = ids;
    }

    private List<String> generateFieldList(String objName, Set<String> fields) {
        List<String> fieldList = new List<String>();
        String prefix = objName;
        if (prefix.contains('__c')) 
            prefix = prefix.replace('__c', '__r');
        for (String field : fields) 
            fieldList.add(prefix + '.' + field);
        return fieldList;
    }

    public List<SObject> runQuery() {
        String fieldsStr = String.join(new List<String>(directFields), ',');
        for (String related : obj2Fields.keySet()) {
            if (!obj2Fields.get(related).isEmpty())
                fieldsStr += ','+String.join(generateFieldList(related, obj2Fields.get(related)), ',');
        }
        if (this.ids.isEmpty()) 
            return new List<SObject>();
        query = 'SELECT ' + fieldsStr + ' FROM ' + objectTypeStr + ' WHERE Id IN ' + BluewolfDevUtils.flattenListForQuery(ids);
        if (orderByField != null) 
            query += ' ORDER BY ' + orderByField + ' ' + (isAscending?'ASC':'DESC');
        return Database.query(query);
    }

    public QueryBuilder addLookupObject(String fieldName) {
        if (obj2Fields.containsKey(fieldName)) 
            throw new queryBuilderException(fieldName + ' has already been added as a lookup object to this QueryBuild1er instance');
        else 
            obj2Fields.put(fieldName, new Set<String>());
        return this;
    }

    public QueryBuilder addFieldToObject(String objName, String field) {
        if (!obj2Fields.containsKey(objName))
            obj2Fields.put(objName, new Set<String>());
        obj2Fields.get(objName).add(field); 
        return this;
    }

    public QueryBuilder addFieldsToObject(String objName, Set<String> fields) {
        for (String field : fields)
            addFieldToObject(objName, field);
        return this;
    }

    public QueryBuilder addField(String field) {
        this.directFields.add(field);
        return this;
    }

    public QueryBuilder addFields(Set<String> fields) {
        this.directFields.addAll(fields);
        return this;
    }

    public QueryBuilder addFieldsUsingFieldPaths(List<String> fieldPaths) {
        for (String fieldPath : fieldPaths) {
            if (!fieldPath.contains('.')) // Case field
                addField(fieldPath);
            else { 
                String[] objAndField = fieldPath.split('\\.', 2);
                String objName = objAndField[0];
                String fieldName = objAndField[1];
                addFieldToObject(objName, fieldName);
            }
        }
        return this;
    }

    // This function does not check if the field is valid
    public QueryBuilder orderBy(String field, Boolean ascending) {
        this.orderByField = field;
        this.isAscending = ascending;
        return this;
    }

    public class queryBuilderException extends Exception {

    }
}