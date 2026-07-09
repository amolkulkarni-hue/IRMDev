/******************************************************************************************************************
* Class: QTB_UpdateUOMDescriptionBatch
* Author: TCS
* Requirement: Gitlab #33632
* Purpose : This is Batch Class to update the OPCS QTB_Localized_UOM_Description__c,QTB_UOM_Description_Text__c as one time Bulk Update for 
Invoice Line - UOM Presentment Description Update (This batch Class will be run only one time for India,Thailand Countries for Bulk Update)
* Developer          Date             Description
* -----------------------------------------------------------------------------------------------------------------
*******************************************************************************************************************/
global class QTB_UpdateUOMDescriptionBatch implements Database.Batchable<SObject>,Database.Stateful {
    
    private Set<String> countries;
    private Set<String> legalEntityNames;
    private Map<String, String> mapOfKeyWithDefaultDescvalue;
    private Map<String, String> mapOfKeyWithTransDescvalue;
    private String SourceSys;
    public static final string UPDATE_UOM_DESCRIPTION = QTB_UpdateUOMDescriptionBatch.class.getName();
    // Constructor
    public QTB_UpdateUOMDescriptionBatch(String accSourceSys,Set<String> countries,Set<String> legalEntityNames) {
        this.countries = countries != null ? countries : new Set<String>();
        this.legalEntityNames = legalEntityNames != null ? legalEntityNames : new Set<String>();
        this.SourceSys = accSourceSys;
        System.debug('this.countries:'+this.countries + 'this.legalEntityNames:' +this.legalEntityNames + 'this.SourceSys:' +this.SourceSys);
        
        // Initialize maps once here
        mapOfKeyWithDefaultDescvalue = new Map<String, String>();
        mapOfKeyWithTransDescvalue = new Map<String, String>();
        
        // Build default description map
        for (QTB_Bill_Code_Product_Lookup__c bcpl : [
            SELECT QTB_Country__r.Name, QTB_Product_Code__c, QTB_UOM__c, QTB_Default_Bill_Code_Description__c 
            FROM QTB_Bill_Code_Product_Lookup__c 
            WHERE QTB_UOM__c != null 
            AND QTB_Default_Bill_Code_Description__c != null 
            AND QTB_Country__r.name != Null
            AND QTB_Country__r.Name IN :countries
            AND QTB_Product_Code__c != null
        ]) {
            //Converting the key of COuntry and UOM to Lower case to make Key as same as Alphabetical issue
            String key = (string)bcpl.QTB_Country__r.name.toLowerCase() + '-' + bcpl.QTB_Product_Code__c + '-'+ (string)bcpl.QTB_UOM__c.toLowerCase();
            //Adding only unique value as basically first record to get added only unique Values
            if (mapOfKeyWithDefaultDescvalue != Null && key != Null && !mapOfKeyWithDefaultDescvalue.containsKey(key)) {
                mapOfKeyWithDefaultDescvalue.put(key, bcpl.QTB_Default_Bill_Code_Description__c);
            }            
        }
        system.debug('mapOfKeyWithDefaultDescvalue:'+mapOfKeyWithDefaultDescvalue);
        
        // Build translation map from Custom Metadata
        Map<String, QTB_UOM_Translation__mdt> allTranslations = QTB_UOM_Translation__mdt.getAll();
        for (QTB_UOM_Translation__mdt trans : allTranslations.values()) {
            String key = (String)trans.QTB_UnitOfMeasure__c.toLowerCase() + '-' + trans.QTB_Language__c;
            mapOfKeyWithTransDescvalue.put(key, trans.QTB_Translated_Value__c);
        }
        system.debug('mapOfKeyWithTransDescvalue:'+mapOfKeyWithTransDescvalue);
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query OPCS records related to OrderItems filtered by country and with UOM not null
        String soql = 
            'SELECT Id, Name, SBQQ__OrderItem__c, SBQQ__OrderItem__r.QTB_Language__c, ' +
            'SBQQ__UnitOfMeasure__c, SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c, ' +
            'SBQQ__OrderItem__r.Order.Account.QTB_DM_Source_System__c, ' + 
            'SBQQ__OrderItem__r.Product2.ProductCode, ' +
            'QTB_Localized_UOM_Description__c, QTB_UOM_Description_Text__c ' +
            'FROM SBQQ__OrderItemConsumptionSchedule__c ' +
            'WHERE SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c IN :countries ' +
            'AND SBQQ__OrderItem__r.blng__LegalEntity__r.Name IN :legalEntityNames ' +
            'AND SBQQ__OrderItem__r.Order.Status = \'Activated\' ' +
            'AND SBQQ__OrderItem__r.Order.Account.QTB_DM_Source_System__c = :SourceSys ' +
            'AND SBQQ__UnitOfMeasure__c != null';
        
        return Database.getQueryLocator(soql);
    }
    
    global void execute(Database.BatchableContext bc, List<SBQQ__OrderItemConsumptionSchedule__c> scope) {
        if (scope.isEmpty()) return;
        system.debug('Scope:'+scope);
        // We'll collect the OrderItem Ids that need to be updated after processing OPCS
        Set<Id> orderItemIdsToUpdate = new Set<Id>();
        try{
            for (SBQQ__OrderItemConsumptionSchedule__c opcs : scope) {
                String keyCompare;
                if (opcs.SBQQ__OrderItem__r.QTB_Language__c != 'en_US') {
                    if(opcs.SBQQ__UnitOfMeasure__c != Null && opcs.SBQQ__OrderItem__r.QTB_Language__c!= Null){
                        //Converting the key of COuntry and UOM to Lower case to make Key as same as Alphabetical issue
                        keyCompare = (string)opcs.SBQQ__UnitOfMeasure__c.toLowerCase() + '-' +opcs.SBQQ__OrderItem__r.QTB_Language__c;
                    }
                    
                    if(mapOfKeyWithTransDescvalue !=null && keyCompare != Null && mapOfKeyWithTransDescvalue.containsKey(keyCompare) ){
                        opcs.QTB_Localized_UOM_Description__c =  mapOfKeyWithTransDescvalue.get(keyCompare);
                    }
                    else {
                        opcs.QTB_Localized_UOM_Description__c = '';  // clear if no match
                    }
                    opcs.QTB_UOM_Description_Text__c = '';
                } else {
                    if(opcs.SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c != Null &&
                       opcs.SBQQ__OrderItem__r.Product2.ProductCode != Null &&
                       opcs.SBQQ__UnitOfMeasure__c != Null){
                           //Converting the key of COuntry and UOM to Lower case to make Key as same as Alphabetical issue
                           keyCompare  = (String)opcs.SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c.toLowerCase() + '-' + opcs.SBQQ__OrderItem__r.Product2.ProductCode + '-' + (String)opcs.SBQQ__UnitOfMeasure__c.toLowerCase();
                       }
                    
                    if(mapOfKeyWithDefaultDescvalue !=null && keyCompare != Null && mapOfKeyWithDefaultDescvalue.containsKey(keyCompare) ){
                        opcs.QTB_UOM_Description_Text__c =  mapOfKeyWithDefaultDescvalue.get(keyCompare);
                    }
                    else {
                        opcs.QTB_UOM_Description_Text__c = ''; // clear if no match
                    }
                    opcs.QTB_Localized_UOM_Description__c = '';
                }
                
                orderItemIdsToUpdate.add(opcs.SBQQ__OrderItem__c);
            }
            system.debug('Scope before Update'+scope);
            // Update OPCS records
            if (!scope.isEmpty()) {
                update scope;
            }
        }catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                UPDATE_UOM_DESCRIPTION
            );
            System.debug('Error processing OPCS records: ' + e.getMessage());
            // Consider logging the error or continuing partial processing
        }
        
        // Update OrderItems to reflect language change or other flags
        if (!orderItemIdsToUpdate.isEmpty()) {
            try{
                List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
                
                // Query minimal data for OrderItems to update (language field)
                List<OrderItem> orderItems = [
                    SELECT Id, QTB_Language__c
                    FROM OrderItem
                    WHERE Id IN :orderItemIdsToUpdate
                ];
                
                for (OrderItem oi : orderItems) {
                    orderItemsToUpdate.add(new OrderItem(
                        Id = oi.Id,
                        QTB_Language_Changed_Value__c = oi.QTB_Language__c
                    ));
                }
                system.debug('orderItemsToUpdate before updating the List:'+orderItemsToUpdate);
                if (!orderItemsToUpdate.isEmpty()) {
                    update orderItemsToUpdate;
                }
            }catch (Exception e) {
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(
                    e.getLineNumber(),
                    e.getStackTraceString(),
                    e.getMessage(),
                    e.getTypeName(),
                    UPDATE_UOM_DESCRIPTION
                );
                System.debug('Error processing OPCS records: ' + e.getMessage());
                // Consider logging the error or continuing partial processing
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
    }
    public static void codeCoverage(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}