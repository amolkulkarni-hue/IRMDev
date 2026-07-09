/**
 * @author       : chayan.batabyal@neuraflash.com
 * @description  : Utility class to contain common use cases/methods
 * Modifications Log
 * Ver   Date         Author                           Modification
 * 1.0   11-02-2021   chayan.batabyal@neuraflash.com   Initial Version
**/
@SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity')
public without sharing class NF_Utility {
    /**
    * @description Retrieves the translated label of the custom fields.
    * @author chayan.batabyal@neuraflash.com | 11-02-2021
    * @param objNameToFields
    * @return TranslatedFieldResponse
    **/
    public static TranslatedFieldResponse getTranslatedFieldLabel(
        Map<String, List<String>> objNameToFields
    ){
        TranslatedFieldResponse responseToSend = new TranslatedFieldResponse();
        Map<String, Map<String, String>> objectToFieldsToLabels =
            new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> objectToFieldsToType =
            new Map<String, Map<String, String>>();

        Integer dotPosition;
        String referenceField;
        String objectName;
        String field;
        String type;
        String nextFieldAPIName;
        String textToReplace;
        String translatedLabel;

        for(String eachObject : objNameToFields.keySet()){
            List<Schema.DescribeSObjectResult> descResults =
                Schema.describeSObjects(new List<String>{eachObject});

            Map<String, String> fieldLabelMap = new Map<String, String>();
            Map<String, String> typeMap = new Map<String, String>();

            for(String eachField : objNameToFields.get(eachObject)){
                field = eachField;
                dotPosition = field.indexOf('.');

                if(dotPosition != -1){
                    while(dotPosition != -1){
                        referenceField = field.substring(0, dotPosition);

                        if(referenceField.endsWith('__r')){
                            objectName = referenceField.replace('__r', '__c');
                        }
                        else if(referenceField.endsWith('__#')){
                            objectName = referenceField.removeEnd('__#');
                        }
                        else{
                            objectName = referenceField;
                        }

                        List<Schema.DescribeSObjectResult> newDescribeResults;

                        try{
                            newDescribeResults = Schema.describeSObjects(new List<String>{objectName});
                        }
                        catch(Exception ex){
                            newDescribeResults = Schema.describeSObjects(new List<String>{
                                String.valueOf(descResults[0].fields.getMap()
                                .get(objectName).getDescribe().getReferenceTo()[0])
                            });
                        }

                        field = field.removeStart(referenceField + '.');
                        dotPosition = field.indexOf('.');

                        if(dotPosition == -1){
                            translatedLabel = newDescribeResults[0].fields.getMap()
                                .get(field).getDescribe().getLabel();
                            type = String.valueOf(newDescribeResults[0].fields.getMap().get(field).getDescribe().getType());
                        }
                        else{
                            nextFieldAPIName = field.substring(0, dotPosition);
                            textToReplace = nextFieldAPIName;
                            if(nextFieldAPIName.indexOf('__r') != -1){
                                nextFieldAPIName = nextFieldAPIName.replace('__r', '__c');
                            }
                            else{
                                nextFieldAPIName += 'Id';
                            }

                            objectName = String.valueOf(newDescribeResults[0].fields.getMap()
                                .get(nextFieldAPIName).getDescribe().getReferenceTo()[0]);
                            field = objectName + '__#.' + field.removeStart(textToReplace + '.');
                            dotPosition = field.indexOf('.');
                        }
                    }
                }
                else{
                    translatedLabel = descResults[0].fields.getMap()
                        .get(field).getDescribe().getLabel();
                    type = String.valueOf(descResults[0].fields.getMap().get(field).getDescribe().getType());
                }

                fieldLabelMap.put(eachField, translatedLabel);
                typeMap.put(eachField, type);
            }

            objectToFieldsToLabels.put(eachObject, fieldLabelMap);
            objectToFieldsToType.put(eachObject, typeMap);
        }

        responseToSend.objectToFieldsToLabels = objectToFieldsToLabels;
        responseToSend.objectToFieldsToType = objectToFieldsToType;

        return responseToSend;
    }

    public class TranslatedFieldResponse{
        public Map<String, Map<String, String>> objectToFieldsToLabels =
            new Map<String, Map<String, String>>();
        public Map<String, Map<String, String>> objectToFieldsToType =
            new Map<String, Map<String, String>>();
    }
}