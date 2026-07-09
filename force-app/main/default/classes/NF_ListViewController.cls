/**
 * @description       : Controller class for the nfListView LWC
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 06-07-2024
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
public with sharing class NF_ListViewController {
    /**
    * @description Queries the requested metadata record and gives back the required details.
    * @author chayan.batabyal@neuraflash.com | 04-21-2022
    * @param request
    * @return ListViewresponseToSend
    **/
    @AuraEnabled
    public static ListViewresponseToSend getListViewDetails(Object request){
        Object req = JSON.deserializeUntyped(String.valueOf(request));
        Map<String, Object> requestDetails = (Map<String, Object>)req;
        String requestedListView = String.valueOf(requestDetails.get('requestedListView'));
        Set<String> existingRecordIds = new Set<String>();

        if(requestDetails.get('existingRecordIds') != null){
            for(Object eachRecordId : (List<Object>)(requestDetails.get('existingRecordIds'))){
                existingRecordIds.add(String.valueOf(eachRecordId));
            }
        }
        existingRecordIds = !existingRecordIds.isEmpty() ? existingRecordIds : null;

        ListViewresponseToSend responseToSend = new ListViewresponseToSend();

        try{
            List_View_Config__mdt metaRecord = [
                SELECT
                    DeveloperName, Datatable_Height__c, Data_Table_Load_Type__c,
                    Empty_List_Message__c, Fields_to_Display__c, List_Icon__c,
                    List_Load_Error_Message__c, List_Title__c, Open_Record_Page_On_First_Column_Click__c,
                    Options_for_Records_Page__c, Order_By__c, Record_Limit__c, Record_Offset__c,
                    Search_Box_Placeholder__c, Show_Row_Number__c, Show_Search_Box__c, SObject_API_Name__c,
                    Static_Filter__c
                FROM
                    List_View_Config__mdt
                WHERE
                    DeveloperName =: requestedListView
                LIMIT 1
            ];

            responseToSend.metaRecord = metaRecord;
            metaRecord.Fields_to_Display__c = getFinalFields(metaRecord.Fields_to_Display__c.replaceAll('\\s', ''));

            if(String.isNotBlank(metaRecord.Options_for_Records_Page__c)){
                for(String eachNumber : metaRecord.Options_for_Records_Page__c.replaceAll('\\s', '').split(',')){
                    responseToSend.pageSizeOptions.add(Integer.valueOf(eachNumber));
                }
            }

            NF_Utility.TranslatedFieldResponse fieldDetails = NF_Utility.getTranslatedFieldLabel(
                new Map<String, List<String>>{metaRecord.SObject_API_Name__c => metaRecord.Fields_to_Display__c.split(',')}
            );

            Map<String, String> translatedFieldLabels = fieldDetails.objectToFieldsToLabels.get(metaRecord.SObject_API_Name__c);
            Map<String, String> fieldTypes = fieldDetails.objectToFieldsToType.get(metaRecord.SObject_API_Name__c);

            responseToSend.columnDetails = getColumnDetails(
                metaRecord.Fields_to_Display__c, translatedFieldLabels, fieldTypes
            );

            responseToSend.recordsToDisplay = getRecordsToDisplay(metaRecord, existingRecordIds);

            String countQuery = 'SELECT Count() FROM ' + metaRecord.SObject_API_Name__c;
            if(String.isNotBlank(metaRecord.Static_Filter__c)){
                countQuery += ' WHERE ' + metaRecord.Static_Filter__c;
            }

            responseToSend.totalCount = Database.countQuery(countQuery);
            responseToSend.isSuccess = true;
        }
        catch(Exception ex){
            String error = ex.getMessage();
            Integer ln = ex.getLineNumber();

            System.debug('Exception occured at :: ' + ln);
            System.debug('Exception occured :: ' + error);

            responseToSend.error = error + ' at ' + ln;
        }

        return responseToSend;
    }

    /**
    * @description Get Final list of fields to be queried
    * @author chayan.batabyal@neuraflash.com | 04-21-2022
    * @param fields
    * @return String
    **/
    private static String getFinalFields(String fields){
        String finalFields = '';
        Set<String> setOfFields = new Set<String>(fields.split(','));

        for(String eachField : setOfFields){
            finalFields += eachField + ',';
        }

        return finalFields.removeEnd(',');
    }

    /**
    * @description Returns the eachColumn structure for list view datatable
    * @author chayan.batabyal@neuraflash.com | 10-28-2021
    * @param fields
    * @param translatedFieldLabels
    * @param fieldTypes
    * @return List<ColumnDetails>
    **/
    private static List<ColumnDetails> getColumnDetails(
        String fields, Map<String, String> translatedFieldLabels, Map<String, String> fieldTypes
    ){
        Set<String> fieldsSet = new Set<String>(fields.split(','));
        List<ColumnDetails> details = new List<ColumnDetails>();
        String timeZone = UserInfo.getTimeZone().getID();

        for(String eachField : fieldsSet){
            String label = translatedFieldLabels.get(eachField);
            String type = fieldTypes.get(eachField);
            ColumnDetails eachColumn = new ColumnDetails(eachField, label);

            switch on type.toLowerCase() {
                when 'date'{
                    eachColumn.type = 'date-local';
                    TypeAttribute attributes = new TypeAttribute();
                    attributes.year = 'numeric';
                    attributes.month = '2-digit';
                    attributes.day = '2-digit';
                    eachColumn.typeAttributes = attributes;
                }
                when 'datetime'{
                    eachColumn.type = 'date';
                    TypeAttribute attributes = new TypeAttribute();
                    attributes.year = 'numeric';
                    attributes.month = '2-digit';
                    attributes.day = '2-digit';
                    attributes.hour = '2-digit';
                    attributes.minute = '2-digit';
                    attributes.timeZone = timeZone;
                    eachColumn.typeAttributes = attributes;
                }
                when 'integer', 'double', 'long', 'decimal' {
                    eachColumn.type = 'number';
                }
                when 'percent' {
                    eachColumn.type = 'percent';
                }
                when 'currency' {
                    eachColumn.type = 'currency';
                }
                when 'boolean' {
                    eachColumn.type = 'boolean';
                }
                when 'phone' {
                    eachColumn.type = 'phone';
                }
                when 'email' {
                    eachColumn.type = 'email';
                }
            }

            details.add(eachColumn);
        }

        return details;
    }

    /**
    * @description Returns the records to display
    * @author chayan.batabyal@neuraflash.com | 10-28-2021
    * @param metaRecord
    * @param existingRecordIds
    * @return List<SObject>
    **/
    private static List<SObject> getRecordsToDisplay(
        List_View_Config__mdt metaRecord, Set<String> existingRecordIds
    ){
        String query = 'SELECT ' + (metaRecord.Fields_to_Display__c.toLowerCase().indexOf('id,') == -1 ? 'Id,' : '');
        query += metaRecord.Fields_to_Display__c + ' FROM ' + metaRecord.SObject_API_Name__c;

        if(existingRecordIds != null){
            query += ' WHERE (NOT Id IN : existingRecordIds)';
        }

        if(String.isNotBlank(metaRecord.Static_Filter__c)){
            query += (query.indexOf(' WHERE ') != -1 ? ' AND ' : ' WHERE ') + metaRecord.Static_Filter__c;
        }

        if(String.isNotBlank(metaRecord.Order_By__c)){
            query += ' ORDER BY ' + metaRecord.Order_By__c;
        }

        query += (' LIMIT ' + (metaRecord.Record_Offset__c != null ?
            Integer.valueOf(metaRecord.Record_Offset__c) : Integer.valueOf(metaRecord.Record_Limit__c)));

        System.debug('query :: ' + query);

        return Database.query(query);
    }

    /**
    * @description Wrapper class for List view details
    * @author chayan.batabyal@neuraflash.com | 10-28-2021
    **/
    public class ListViewresponseToSend{
        @AuraEnabled public List<ColumnDetails> columnDetails;
        @AuraEnabled public List<SObject> recordsToDisplay;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Boolean isSuccess = false;
        @AuraEnabled public String error;
        @AuraEnabled public List_View_Config__mdt metaRecord;
        @AuraEnabled public List<Integer> pageSizeOptions = new List<Integer>();
    }

    /**
    * @description Wrapper class for each eachColumn
    * @author chayan.batabyal@neuraflash.com | 10-28-2021
    **/
    public class ColumnDetails{
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type = 'text';
        @AuraEnabled public Boolean hideDefaultActions;
        @AuraEnabled public Boolean sortable;
        @AuraEnabled public TypeAttribute typeAttributes;

        /**
        * @description Constructor for each column
        * @author chayan.batabyal@neuraflash.com | 10-28-2021
        * @param fieldName
        * @param label
        **/
        public ColumnDetails(String fieldName, String label){
            this.fieldName = fieldName;
            this.label = label;
            this.hideDefaultActions = true;
            this.sortable = true;
        }
    }

    public class TypeAttribute {
        @AuraEnabled public String year;
        @AuraEnabled public String month;
        @AuraEnabled public String day;
        @AuraEnabled public String hour;
        @AuraEnabled public String minute;
        @AuraEnabled public String timeZone;
    }
}